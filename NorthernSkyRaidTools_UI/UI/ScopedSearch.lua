-- ============================================================
--  ScopedSearch.lua  -  per-tab settings search (header strip, right-aligned)
--
--  The box in the strip above a tab's content searches the settings of the entry that is
--  selected on that tab only (the alert, aura or glow being edited). Like the addon-wide
--  search it shows a ranked dropdown; choosing a result opens the right inner tab,
--  scrolls the setting into view and pulses it. The page is never filtered.
--
--  A tab supplies a collector: opts.collect(add), calling
--      add(label, crumb, tooltip, jump)
--  for every searchable setting of the current selection. jump() reveals it. The index is
--  rebuilt whenever the box gains focus, so it always describes the current selection.
--  Scoring, markup and the pulse are shared with Search.lua.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Pixel = NSI.UI.Pixel
local Components = NSI.UI.Components
local Search = NSI.UI.Search
local I = Search.Internals

local ipairs, pcall, tsort = ipairs, pcall, table.sort

local ScopedSearch = {}
NSI.UI.ScopedSearch = ScopedSearch

local WHITE     = [[Interface\Buttons\WHITE8X8]]
local BOX_W     = 220
local BOX_H     = 26
local POPUP_W   = 380
local ROW_H     = 38
local ROW_GAP   = 2
local POPUP_PAD = 6

-- Collector for master/detail tabs that publish SearchPanels / SearchReveal (Aura Tracking,
-- Aura Glows): every non-label definition of the selected entry's panels.
function ScopedSearch.PanelCollector(screen)
    return function(add)
        if not screen.SearchPanels then return end
        local ok, panels = pcall(screen.SearchPanels)
        if not ok or not panels then return end
        for _, panel in ipairs(panels) do
            local crumb = I.Localized(panel.title)
            for defIndex, def in ipairs(panel.defs) do
                local label = def.label or def.text
                if def.Type ~= "Label" and def.Type ~= "Breakline" and label then
                    add(label, crumb, def.tooltip, function()
                        local host, scroll = screen.SearchReveal(panel.id)
                        -- a page revealed this frame has no layout yet: measure on the next one
                        C_Timer.After(0, function()
                            if not screen:IsShown() then return end
                            local set = host and host.current
                            local item = set and set.byIndex[defIndex]
                            if item and item.frame:IsShown() then
                                if scroll then scroll:ScrollToFrame(item.frame) end
                                I.Pulse(item.frame)
                            end
                        end)
                    end)
                end
            end
        end
    end
end

-- opts: collect(add) (required), placeholder
function ScopedSearch.Create(tabFrame, name, opts)
    local index, rows, results = {}, {}, {}
    local selectedIndex = 1
    local popup, box, edit

    local function BuildIndex()
        for i = #index, 1, -1 do index[i] = nil end
        opts.collect(function(label, crumb, tooltip, jump)
            local e = I.MakeEntry("row", name, "", crumb, label, tooltip)
            if e then e.jump = jump; index[#index + 1] = e end
        end)
    end

    local function Query(text)
        for i = #results, 1, -1 do results[i] = nil end
        local q = strtrim((text or ""):lower())
        if q == "" then return results, q end
        local qFlat = I.Squash(q)
        for _, e in ipairs(index) do
            local s = I.Score(e, q, qFlat)
            if s then results[#results + 1] = { e = e, score = s } end
        end
        tsort(results, I.ByScore)
        for i = #results, I.MAX_RESULTS + 1, -1 do results[i] = nil end
        return results, q
    end

    local function Paint()
        for i, r in ipairs(rows) do
            r.hl:SetShown(i == selectedIndex and r:IsShown() and r.entry ~= nil)
        end
    end

    local function Jump(e)
        if not e or not e.jump then return end
        popup:Hide()
        box.Clear()
        e.jump()
    end

    local function GetRow(i)
        local r = rows[i]
        if r then return r end
        r = CreateFrame("Button", nil, popup)
        r:SetHeight(ROW_H)
        r:SetPoint("TOPLEFT", popup, "TOPLEFT", POPUP_PAD, -POPUP_PAD - (i - 1) * (ROW_H + ROW_GAP))
        r:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -POPUP_PAD, -POPUP_PAD - (i - 1) * (ROW_H + ROW_GAP))
        r.hl = r:CreateTexture(nil, "BACKGROUND")
        r.hl:SetAllPoints()
        STYLE.PaintAccent(r.hl, "SetColorTexture", 0.18)
        r.hl:Hide()
        r.title = r:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(r.title, "label")
        r.title:SetPoint("TOPLEFT", 10, -5)
        r.title:SetPoint("RIGHT", -10, 0)
        r.title:SetJustifyH("LEFT")
        r.title:SetWordWrap(false)
        r.sub = r:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(r.sub, "tiny", "")
        r.sub:SetTextColor(unpack(STYLE.text_muted))
        r.sub:SetPoint("BOTTOMLEFT", 10, 5)
        r.sub:SetPoint("RIGHT", -10, 0)
        r.sub:SetJustifyH("LEFT")
        r.sub:SetWordWrap(false)
        r.i = i
        r:SetScript("OnClick", function(self) Jump(self.entry) end)
        r:SetScript("OnEnter", function(self) selectedIndex = self.i; Paint() end)
        rows[i] = r
        return r
    end

    local function ShowResults()
        local text = edit:GetText()
        if text == "" then popup:Hide() return end
        local list, q = Query(text)
        for i, res in ipairs(list) do
            local r = GetRow(i)
            r.entry = res.e
            r.title:SetText(I.Mark(res.e.shown, q))
            r.sub:SetText(I.Esc(res.e.sectionTitle or ""))
            r:Show()
        end
        for i = #list + 1, #rows do rows[i]:Hide(); rows[i].entry = nil end
        if #list == 0 then
            local r = GetRow(1)
            r.entry = nil
            r.title:SetText(NSI:Loc("No matching settings"))
            r.sub:SetText(NSI:Loc("Try fewer or different words."))
            r:Show()
            popup:SetHeight(ROW_H + POPUP_PAD * 2)
        else
            popup:SetHeight(#list * (ROW_H + ROW_GAP) - ROW_GAP + POPUP_PAD * 2)
        end
        selectedIndex = 1
        Paint()
        popup:Show()
    end

    local function Move(delta)
        local n = 0
        for _, r in ipairs(rows) do if r:IsShown() and r.entry then n = n + 1 end end
        if n == 0 then return end
        selectedIndex = (selectedIndex - 1 + delta) % n + 1
        Paint()
    end

    box = Components.CreateSearchBox(tabFrame, BOX_W, BOX_H, name, ShowResults,
        opts.placeholder or NSI:Loc("Search module..."))
    -- centred on the Shared / Personal Notes buttons, right-aligned
    local core = NSI.UI.Core
    local stripH = (core and core.TAB_HEADER_HEIGHT) or 44
    box:SetPoint("TOPRIGHT", tabFrame, "TOPRIGHT", -10, (stripH + BOX_H) / 2)
    edit = box.editBox

    popup = Pixel.CreateBoxFrame("Frame", nil, tabFrame)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetWidth(POPUP_W)
    popup:SetPoint("TOPRIGHT", box.frame, "BOTTOMRIGHT", 0, -4)
    popup:EnableMouse(true)
    popup:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    popup:SetBackdropColor(unpack(STYLE.surface_panel))
    STYLE.PaintAccent(popup, "SetBackdropBorderColor", 0.7)
    popup:Hide()

    local watcher = CreateFrame("Frame")
    watcher:SetScript("OnEvent", function()
        if popup:IsMouseOver() or box.frame:IsMouseOver() then return end
        edit:ClearFocus()
        popup:Hide()
    end)
    popup:SetScript("OnShow", function() watcher:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
    popup:SetScript("OnHide", function() watcher:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
    tabFrame:HookScript("OnHide", function() popup:Hide() end)

    edit:HookScript("OnEditFocusGained", function() BuildIndex(); ShowResults() end)
    edit:HookScript("OnArrowPressed", function(_, key)
        if key == "DOWN" then Move(1) elseif key == "UP" then Move(-1) end
    end)
    edit:HookScript("OnTabPressed", function() Move(IsShiftKeyDown() and -1 or 1) end)
    edit:HookScript("OnEnterPressed", function()
        local r = rows[selectedIndex]
        if r and r.entry then Jump(r.entry) end
    end)
    edit:HookScript("OnEscapePressed", function() popup:Hide() end)
    return box
end
