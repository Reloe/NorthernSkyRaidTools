-- ============================================================
--  DataTable.lua - Components.CreateDataTable (K-3)
--
--  A sortable, virtualised table: a fixed pool of row frames is recycled as the
--  user scrolls, so 500 rows cost the same as 20 (best practices 2.10). Rows use
--  Components.StyleRow with the row_stripe_* tokens; the selected row gets the
--  accent tint at STYLE.selected_row_alpha. Headers ellipsize and show their full
--  text in the house tooltip.
--
--  local tbl = Components.CreateDataTable(parent, columns, opts)
--
--  columns[i] = {
--      key        stable id, used for sorting and as the default value field
--      title      header text (run through NSI:Loc)
--      width      fixed px width, or nil with flex = n (share of the leftover width)
--      flex       number, default 1 when width is nil
--      align      "LEFT" (default), "CENTER", "RIGHT"
--      sortable   default true
--      sortValue  function(rowData) -> comparable value (default rowData[key])
--      text       function(rowData) -> string (default tostring(rowData[key]))
--      init       function(cellFrame) called once per pooled cell (custom children)
--      render     function(cellFrame, rowData, rowFrame) called every refresh;
--                 when set it replaces the default text rendering
--      tooltip    string shown on the header
--  }
--
--  opts = { rowHeight = 22, headerHeight = 22, selectable = true,
--           onSelect(rowData), onClick(rowData, button), onContext(rowData, rowFrame),
--           onEnter(rowData, rowFrame), onLeave(rowData, rowFrame) (row hover),
--           emptyText, defaultSort = { key, asc = true }, getRowColor(rowData) -> {r,g,b,a} }
--
--  tbl.frame  tbl:SetData(list)  tbl:GetData()  tbl:Refresh()  tbl:SetSelected(rowData)
--  tbl:GetSelected()  tbl:SortBy(key, asc)  tbl:SetSize(w, h)  tbl:ScrollToTop()
--  Data rows are the caller's own tables: the table never copies or mutates them.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Pixel = NSI.UI.Pixel
local Components = NSI.UI.Components

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local tsort = table.sort
local type, tostring, ipairs = type, tostring, ipairs

local ICON_PATH = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]
local SCROLL_W = 6        -- thin scrollbar
local WHEEL_ROWS = 3

local function SetFont(fs, size) NSI:SetUIFont(fs, size) end

local function CreateDataTable(parent, columns, opts)
    opts = opts or {}
    local rowH = opts.rowHeight or 22
    local headH = opts.headerHeight or 22
    local selectable = opts.selectable ~= false

    local self = {}
    local root = CreateFrame("Frame", nil, parent)
    root:SetSize(400, 300)
    self.frame = root

    local data, view = {}, {}       -- caller's list; sorted view (same row tables)
    local selected                  -- selected rowData
    local sortKey, sortAsc
    local offset = 0                -- scroll offset in px
    local pool = {}
    local widths = {}

    if opts.defaultSort then sortKey, sortAsc = opts.defaultSort.key, opts.defaultSort.asc ~= false end

    -- ---- header ------------------------------------------------
    local header = CreateFrame("Frame", nil, root)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(headH)
    local headBg = header:CreateTexture(nil, "BACKGROUND")
    headBg:SetAllPoints()
    headBg:SetColorTexture(unpack(STYLE.surface_inset))

    -- ---- viewport ----------------------------------------------
    local view_f = CreateFrame("Frame", nil, root)
    view_f:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1)
    view_f:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -(SCROLL_W + 2), 0)
    view_f:SetClipsChildren(true)
    view_f:EnableMouseWheel(true)

    local empty = view_f:CreateFontString(nil, "OVERLAY")
    SetFont(empty, "small")
    empty:SetTextColor(unpack(STYLE.text_muted))
    empty:SetPoint("CENTER")
    empty:SetText(opts.emptyText and NSI:Loc(opts.emptyText) or "")

    -- scrollbar (a thin track and thumb; the thumb drags while the button is held)
    local track = root:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(unpack(STYLE.surface_inset))
    track:SetWidth(SCROLL_W)
    track:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -1)
    track:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)
    local thumb = CreateFrame("Button", nil, root)
    thumb:SetWidth(SCROLL_W)
    thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
    thumb.tex:SetAllPoints()
    STYLE.PaintAccent(thumb.tex, "SetColorTexture", 0.6)
    thumb:Hide()

    -- ---- geometry ----------------------------------------------
    local function ViewHeight() return view_f:GetHeight() or 0 end
    local function MaxOffset() return max(0, #view * rowH - ViewHeight()) end

    local function UpdateThumb()
        local vh, total = ViewHeight(), #view * rowH
        if total <= vh or vh <= 0 then thumb:Hide(); return end
        local h = max(20, floor(vh * vh / total + 0.5))
        local y = floor((vh - h) * offset / (total - vh) + 0.5)
        thumb:SetHeight(h)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, -y)
        thumb:Show()
    end

    local function ColumnWidths(total)
        local fixed, flexTotal = 0, 0
        for i, c in ipairs(columns) do
            if c.width then fixed = fixed + c.width else flexTotal = flexTotal + (c.flex or 1) end
        end
        local left = max(0, total - fixed)
        for i, c in ipairs(columns) do
            widths[i] = c.width or floor(left * (c.flex or 1) / max(flexTotal, 1))
        end
    end

    -- ---- rows --------------------------------------------------
    local function RowEnter(row)
        Components.FadeTo(row.hover, 1, STYLE.hover_in)
        if opts.onEnter and row.data then opts.onEnter(row.data, row) end
    end
    local function RowLeave(row)
        Components.FadeTo(row.hover, 0, STYLE.hover_out)
        if opts.onLeave then opts.onLeave(row.data, row) end
    end
    local function RowClick(row, button)
        local d = row.data
        if not d then return end
        if button == "RightButton" then
            if opts.onContext then opts.onContext(d, row) end
            return
        end
        if selectable and selected ~= d then
            selected = d
            self:Refresh()
            if opts.onSelect then opts.onSelect(d) end
        end
        if opts.onClick then opts.onClick(d, button) end
    end

    local function BuildRow()
        local row = CreateFrame("Button", nil, view_f)
        row:SetHeight(rowH)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        Components.StyleRow(row, STYLE.row_stripe_dark)
        row.hover = row:CreateTexture(nil, "BACKGROUND", nil, -5)
        row.hover:SetAllPoints()
        STYLE.PaintAccent(row.hover, "SetColorTexture", STYLE.hover_color[4])
        row.hover:SetAlpha(0)
        row.sel = row:CreateTexture(nil, "BACKGROUND", nil, -4)
        row.sel:SetAllPoints()
        STYLE.PaintAccent(row.sel, "SetColorTexture", STYLE.selected_row_alpha)
        row.sel:Hide()
        row.cells = {}
        for i, c in ipairs(columns) do
            local cell = CreateFrame("Frame", nil, row)
            cell:SetHeight(rowH)
            if not c.render then
                cell.text = cell:CreateFontString(nil, "OVERLAY")
                SetFont(cell.text, "small")
                cell.text:SetPoint("LEFT", 4, 0)
                cell.text:SetPoint("RIGHT", -4, 0)
                cell.text:SetJustifyH(c.align or "LEFT")
                cell.text:SetWordWrap(false)
                cell.text:SetMaxLines(1)
            end
            if c.init then c.init(cell) end
            row.cells[i] = cell
        end
        row:SetScript("OnEnter", RowEnter)
        row:SetScript("OnLeave", RowLeave)
        row:SetScript("OnClick", RowClick)
        return row
    end

    local function LayoutRow(row)
        local x = 0
        for i, cell in ipairs(row.cells) do
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", row, "TOPLEFT", x, 0)
            cell:SetWidth(widths[i])
            x = x + widths[i]
        end
    end

    local function EnsurePool()
        local need = ceil(ViewHeight() / rowH) + 2
        for i = #pool + 1, need do
            local row = BuildRow()
            pool[i] = row
        end
    end

    -- ---- header buttons ----------------------------------------
    local heads = {}
    local function PaintHeaders()
        local x = 0
        for i, c in ipairs(columns) do
            local h = heads[i]
            if not h then
                h = CreateFrame("Button", nil, header)
                h:SetHeight(headH)
                h.text = h:CreateFontString(nil, "OVERLAY")
                SetFont(h.text, "small")
                h.text:SetTextColor(unpack(STYLE.text_soft))
                h.text:SetWordWrap(false)
                h.text:SetMaxLines(1)
                h.arrow = h:CreateTexture(nil, "OVERLAY")
                h.arrow:SetSize(10, 10)
                h.arrow:SetPoint("RIGHT", -3, 0)
                h.text:SetPoint("LEFT", 4, 0)
                h.text:SetPoint("RIGHT", h.arrow, "LEFT", -2, 0)
                h.text:SetJustifyH(c.align or "LEFT")
                h.text:SetText(NSI:Loc(c.title or c.key))
                h.index = i
                h:SetScript("OnClick", function(btn)
                    local col = columns[btn.index]
                    if col.sortable == false then return end
                    -- Not "x and not y or true": that is always true when y is true (the and/or trap).
                    local asc = true
                    if sortKey == col.key then asc = not sortAsc end
                    self:SortBy(col.key, asc)
                end)
                h:SetScript("OnEnter", function(btn)
                    local col = columns[btn.index]
                    local tip = col.tooltip or (btn.text:IsTruncated() and NSI:Loc(col.title or col.key))
                    if tip then NSI.UI.Tooltip.Show(btn, NSI:Loc(tip)) end
                end)
                h:SetScript("OnLeave", function() NSI.UI.Tooltip.Hide() end)
                heads[i] = h
            end
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", header, "TOPLEFT", x, 0)
            h:SetWidth(widths[i])
            if sortKey == c.key then
                h.arrow:SetTexture(ICON_PATH .. (sortAsc and "chevron-up.png" or "chevron-down.png"))
                STYLE.PaintAccent(h.arrow, "SetVertexColor", 1)
                h.arrow:Show()
            else
                h.arrow:Hide()
            end
            x = x + widths[i]
        end
    end

    -- ---- sorting -----------------------------------------------
    local function ColumnByKey(key)
        for _, c in ipairs(columns) do if c.key == key then return c end end
    end

    local function Resort()
        local n = #data
        for i = 1, #view do view[i] = nil end
        for i = 1, n do view[i] = data[i] end
        local col = sortKey and ColumnByKey(sortKey)
        if not col then return end
        -- decorate with the original index so the sort is stable
        local order = {}
        for i = 1, n do order[view[i]] = i end
        local get = col.sortValue or function(r) return r[col.key] end
        local asc = sortAsc
        tsort(view, function(a, b)
            local va, vb = get(a), get(b)
            if va == vb then return order[a] < order[b] end
            if va == nil then return false end
            if vb == nil then return true end
            if type(va) ~= type(vb) then va, vb = tostring(va), tostring(vb) end
            if asc then return va < vb end
            return va > vb
        end)
    end

    -- ---- refresh -----------------------------------------------
    function self:Refresh()
        if not root:IsVisible() then self._dirty = true; return end
        self._dirty = nil
        local vh = ViewHeight()
        if vh <= 0 then return end
        EnsurePool()
        offset = max(0, min(offset, MaxOffset()))
        local first = floor(offset / rowH)
        local shift = offset - first * rowH
        for i, row in ipairs(pool) do
            local idx = first + i
            local d = view[idx]
            if d and (i - 1) * rowH - shift < vh then
                row.data = d
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", view_f, "TOPLEFT", 0, -((i - 1) * rowH - shift))
                row:SetPoint("TOPRIGHT", view_f, "TOPRIGHT", 0, -((i - 1) * rowH - shift))
                local fill = opts.getRowColor and opts.getRowColor(d)
                    or (idx % 2 == 1 and STYLE.row_stripe_dark or STYLE.row_stripe_light)
                row.__background:SetVertexColor(fill[1], fill[2], fill[3])
                row.__background:SetAlpha(fill[4] or 1)
                row.sel:SetShown(selectable and d == selected)
                for ci, c in ipairs(columns) do
                    local cell = row.cells[ci]
                    if c.render then
                        c.render(cell, d, row)
                    else
                        cell.text:SetText(c.text and c.text(d) or tostring(d[c.key] == nil and "" or d[c.key]))
                    end
                end
                row:Show()
            else
                row.data = nil
                row:Hide()
            end
        end
        empty:SetShown(#view == 0)
        UpdateThumb()
    end

    local function Relayout()
        -- A hidden, anchor-only frame reports width 0 until it is laid out; fall back to the root's
        -- explicit size so flex columns are never squeezed to nothing.
        local w = view_f:GetWidth() or 0
        if w <= 0 then w = (root:GetWidth() or 0) - SCROLL_W - 2 end
        ColumnWidths(max(0, w))
        PaintHeaders()
        for _, row in ipairs(pool) do LayoutRow(row) end
        self:Refresh()
    end

    local function NewRowsNeedLayout()
        -- rows built after the last layout get their cell geometry here
        for _, row in ipairs(pool) do
            if not row._laidOut then LayoutRow(row); row._laidOut = true end
        end
    end
    local baseRefresh = self.Refresh
    self.Refresh = function(s)
        if root:IsVisible() and ViewHeight() > 0 then
            EnsurePool()
            NewRowsNeedLayout()
        end
        return baseRefresh(s)
    end

    -- ---- scrolling ---------------------------------------------
    local function SetOffset(v)
        v = max(0, min(MaxOffset(), v))
        if v == offset then return end
        offset = v
        self:Refresh()
    end

    view_f:SetScript("OnMouseWheel", function(_, delta)
        SetOffset(offset - delta * WHEEL_ROWS * rowH)
    end)

    local dragStartY, dragStartOffset
    thumb:SetScript("OnMouseDown", function(btn)
        dragStartY = select(2, GetCursorPosition()) / btn:GetEffectiveScale()
        dragStartOffset = offset
        btn:SetScript("OnUpdate", function(b)
            if not IsMouseButtonDown("LeftButton") then
                b:SetScript("OnUpdate", nil)
                return
            end
            local y = select(2, GetCursorPosition()) / b:GetEffectiveScale()
            local vh, total = ViewHeight(), #view * rowH
            local ratio = (total - vh) / max(1, vh - b:GetHeight())
            SetOffset(dragStartOffset + (dragStartY - y) * ratio)
        end)
    end)
    thumb:SetScript("OnMouseUp", function(btn) btn:SetScript("OnUpdate", nil) end)
    thumb:SetScript("OnHide", function(btn) btn:SetScript("OnUpdate", nil) end)

    root:SetScript("OnSizeChanged", function() Relayout() end)
    root:SetScript("OnShow", function() Relayout() end)

    -- ---- public ------------------------------------------------
    function self:SetData(list)
        data = list or {}
        if selected then
            local found = false
            for i = 1, #data do if data[i] == selected then found = true break end end
            if not found then selected = nil end
        end
        Resort()
        self:Refresh()
    end

    function self:GetData() return data end
    function self:GetSelected() return selected end

    function self:SetSelected(rowData)
        selected = rowData
        self:Refresh()
    end

    function self:SortBy(key, asc)
        sortKey, sortAsc = key, asc ~= false
        Resort()
        PaintHeaders()
        self:Refresh()
    end

    function self:ScrollToTop() offset = 0; self:Refresh() end

    function self:SetSize(w, h) root:SetSize(w, h) end
    function self:SetPoint(...) root:SetPoint(...) end

    ColumnWidths(400)
    PaintHeaders()
    return self
end

Components.CreateDataTable = CreateDataTable
