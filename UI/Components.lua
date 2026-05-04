local _, NSI = ...
local DF = _G["DetailsFramework"]

-- ============================================================
--  NSRT UI Components
--  Thin wrappers over raw WoW frames that enforce the Northern
--  Sky visual style without relying on DF templates.
--  Edit STYLE below to retheme the entire addon UI in one place.
-- ============================================================

local STYLE = {
    -- Normal state
    bg_color       = { 0.06, 0.06, 0.06, 0.8 },

    -- Hover overlay (fades in/out on mouse enter/leave)
    hover_color     = {0,    1,    1,    0.13},

    -- Selected state (solid background)
    selected_color  = {0,    1,    1,    0.20},

    -- Text defaults
    text_color      = {1, 1, 1, 1},
    text_disabled   = {0.45, 0.45, 0.45, 0.70},
    text_size       = 14,
    text_left_pad   = 10,

    -- Animation durations in seconds
    hover_in        = 0.12,
    hover_out       = 0.20,
    select_in       = 0.10,
    deselect_out    = 0.15,
}

-- ============================================================
--  CreateButton
--
--  Returns a button object. Every method delegates to the
--  underlying WoW frame or FontString so nothing is hidden.
--
--  Params
--    parent  – WoW frame
--    text    – display string
--    onClick – function(buttonObj) called on click; may be nil
--    width   – number (nil: text pixel width + 20px padding, icon included in content)
--    height  – number (default 26)
--    name    – optional global frame name string
--     icon    – optional lib icon name
--
--  Returned object fields & methods
--    .frame           WoW Button frame (anchor, reparent, etc.)
--    .label           FontString (SetText, SetFont, SetTextColor…)
--    :SetText(s)
--    :GetText() → string
--    :SetFont(path, size, flags)
--    :SetTextColor(r, g, b [,a])
--    :SetPoint(…)     delegates to .frame
--    :SetSize(w, h)   delegates to .frame
--    :GetWidth()      delegates to .frame
--    :GetHeight()     delegates to .frame
--    :Select()        activates selected background (fades in)
--    :Deselect()      clears selected background (fades out)
--    :IsSelected() → bool
--    :Enable()
--    :Disable()       also dims label
-- ============================================================
-- Registry of every label created by this module so RefreshFonts() can
-- update them all in one call when the player changes the Global Font setting.
-- Stored as {label = FontString, size = number} plain entries — buttons are
-- never destroyed mid-session so no weak table needed.
local labelRegistry = {}

local FALLBACK_FONT = "Fonts\\FRIZQT__.TTF"

local function ValidateFont(path)
    if not path or path == "" then return FALLBACK_FONT end
    NSI.TestString = NSI.TestString or UIParent:CreateFontString(nil, "ARTWORK")
    local ok = NSI.TestString:SetFont(path, 12, "")
    NSI.TestString:Hide()
    return ok and path or FALLBACK_FONT
end

local function RefreshFonts()
    local rawPath = NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont)
    local fontPath = ValidateFont(rawPath)
    for _, entry in ipairs(labelRegistry) do
        entry.label:SetFont(fontPath, entry.size, NSRT.Settings.GlobalFontFlags)
    end
end

local function CreateButton(parent, text, onClick, width, height, name, icon, textSize)
    -- ---- base frame -------------------------------------------
    -- Width is resolved after measuring the label; start with a stub size.
    local btn = CreateFrame("Button", name, parent, "BackdropTemplate")
    local btnHeight = height or 26
    btn:SetSize(1, btnHeight)
    btn:EnableMouse(true)
    btn:SetFrameLevel(parent:GetFrameLevel() + 1)

    btn:SetBackdrop({
        bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile     = true,
        tileSize = 64,
    })
    btn:SetBackdropColor(unpack(STYLE.bg_color))

    -- ---- hover background (fades in/out) ----------------------
    -- Wrapping the texture in its own frame lets UIFrameFade work on it.
    local hoverBg = CreateFrame("Frame", nil, btn)
    hoverBg:SetAllPoints(btn)
    hoverBg:SetFrameLevel(btn:GetFrameLevel() + 1)
    hoverBg:EnableMouse(false)
    local hoverTex = hoverBg:CreateTexture(nil, "background")
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(unpack(STYLE.hover_color))
    hoverBg:SetAlpha(0)

    -- ---- selected background (fades in when tab is active) ----
    local selectedBg = CreateFrame("Frame", nil, btn)
    selectedBg:SetAllPoints(btn)
    selectedBg:SetFrameLevel(btn:GetFrameLevel() + 1)
    selectedBg:EnableMouse(false)
    local selectedTex = selectedBg:CreateTexture(nil, "background")
    selectedTex:SetAllPoints()
    selectedTex:SetColorTexture(unpack(STYLE.selected_color))
    selectedBg:SetAlpha(0)

    -- ---- label ------------------------------------------------
    -- Lives on its own frame above hoverBg/selectedBg (N+2) so the cyan
    -- overlay never dims the text — it stays pure white at all times.
    local labelFrame = CreateFrame("Frame", nil, btn)
    labelFrame:SetFrameLevel(btn:GetFrameLevel() + 2)
    labelFrame:EnableMouse(false)

    local label = labelFrame:CreateFontString(nil, "OVERLAY")
    label:SetFont(ValidateFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont)), STYLE.text_size, NSRT.Settings.GlobalFontFlags)
    label:SetTextColor(unpack(STYLE.text_color))
    label:SetText(text or "")
    label:SetJustifyV("MIDDLE")
    label:SetJustifyH("CENTER")
    label:SetAllPoints(labelFrame)
    labelRegistry[#labelRegistry + 1] = {label = label, size = fontSize}

    -- ---- compute final button width & lay out content ---------
    local iconSize  = 14
    local iconGap   = 6   -- gap between icon and text
    local padH      = 10  -- padding on each side

    local textWidth = math.max(label:GetStringWidth(), 1)
    local contentW  = icon and (iconSize + iconGap + textWidth) or textWidth
    local btnWidth  = width or (contentW + padH * 2)
    btn:SetSize(btnWidth, btnHeight)

    if icon then
        -- Icon lives on a frame at N+2 so it renders above the hover/selected
        -- overlays (which sit at N+1) and is never obscured by them.
        local iconFrame = CreateFrame("Frame", nil, btn)
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:SetFrameLevel(btn:GetFrameLevel() + 2)
        iconFrame:EnableMouse(false)

        local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTex:SetAllPoints()
        local texture_info = NSI.LSM:Fetch("statusbar", icon)
        iconTex:SetTexture(texture_info .. ".png")
        iconTex:SetTexCoord(0.1, 0.9, 0.09, 0.91)
        iconTex:SetVertexColor(1, 1, 1)
        btn.icon = iconTex

        -- Centre [icon  gap  text] as a group inside the button.
        local groupLeft = (btnWidth - contentW) / 2
        iconFrame:SetPoint("LEFT", btn, "LEFT", groupLeft, 0)

        labelFrame:SetSize(textWidth, btnHeight)
        labelFrame:SetPoint("LEFT", iconFrame, "RIGHT", iconGap, 0)
    else
        labelFrame:SetSize(textWidth, btnHeight)
        labelFrame:SetPoint("CENTER", btn, "CENTER", 0, 0)
    end
    -- ---- mouse scripts ----------------------------------------
    btn:SetScript("OnEnter", function()
        UIFrameFadeIn(hoverBg, STYLE.hover_in, hoverBg:GetAlpha(), 1)
    end)
    btn:SetScript("OnLeave", function()
        UIFrameFadeOut(hoverBg, STYLE.hover_out, hoverBg:GetAlpha(), 0)
    end)

    -- ---- public object ----------------------------------------
    local buttonObj = {
        frame      = btn,
        label      = label,
        labelFrame = labelFrame,
        hoverBg    = hoverBg,
        selectedBg = selectedBg,
        _selected  = false,
    }

    -- Wire click after buttonObj exists so the callback receives it
    btn:SetScript("OnClick", function()
        if onClick then onClick(buttonObj) end
    end)

    function buttonObj:SetText(s)
        self.label:SetText(s)
    end

    function buttonObj:GetText()
        return self.label:GetText()
    end

    function buttonObj:SetFont(path, size, flags)
        self.label:SetFont(path, size or STYLE.text_size, flags or "")
    end

    function buttonObj:SetTextColor(r, g, b, a)
        self.label:SetTextColor(r, g, b, a or 1)
    end

    function buttonObj:SetPoint(...)
        self.frame:SetPoint(...)
    end

    function buttonObj:SetSize(w, h)
        self.frame:SetSize(w, h)
    end

    function buttonObj:GetWidth()
        return self.frame:GetWidth()
    end

    function buttonObj:GetHeight()
        return self.frame:GetHeight()
    end

    function buttonObj:Select()
        self._selected = true
        UIFrameFadeIn(self.selectedBg, STYLE.select_in, self.selectedBg:GetAlpha(), 1)
    end

    function buttonObj:Deselect()
        self._selected = false
        UIFrameFadeOut(self.selectedBg, STYLE.deselect_out, self.selectedBg:GetAlpha(), 0)
    end

    function buttonObj:IsSelected()
        return self._selected
    end

    function buttonObj:Enable()
        self.frame:Enable()
        self.label:SetTextColor(unpack(STYLE.text_color))
    end

    function buttonObj:Disable()
        self.frame:Disable()
        self.label:SetTextColor(unpack(STYLE.text_disabled))
    end

    return buttonObj
end

-- ============================================================
--  CreateSubButton
--
--  Lighter-weight variant of CreateButton for secondary UI
--  controls (inner tab bars, type selectors, etc.).
--  Defaults: height=18, font size=12, no icon support.
-- ============================================================
local function CreateSubButton(parent, text, onClick, width, name)
    return CreateButton(parent, text, onClick, width, 18, name, nil, 12)
end

-- ============================================================
--  Local helpers shared by the three form controls below
-- ============================================================
local function MakeHoverBg(parent, level)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints(parent)
    f:SetFrameLevel(level)
    f:EnableMouse(false)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints()
    t:SetColorTexture(unpack(STYLE.hover_color))
    f:SetAlpha(0)
    return f
end

local function MakeControlBackdrop(frame)
    frame:SetBackdrop({
        bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile     = true,
        tileSize = 64,
    })
    frame:SetBackdropColor(unpack(STYLE.bg_color))
end

local function MakeFontString(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ValidateFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont)), size, NSRT.Settings.GlobalFontFlags)
    fs:SetTextColor(unpack(STYLE.text_color))
    labelRegistry[#labelRegistry + 1] = {label = fs, size = size}
    return fs
end

-- ============================================================
--  CreateCheckButton
--
--  A styled checkbox row.  Clicking anywhere on the widget
--  toggles it and fires setValue(bool).
--
--  Params
--    parent   – WoW frame
--    label    – display string to the right of the box
--    getValue – function() → bool
--    setValue – function(bool)
--    width    – number (default 180)
--    height   – number (default 22)
--
--  Returned object
--    .frame          container Frame
--    .label          FontString
--    :SetValue(bool)
--    :GetValue() → bool
--    :SetPoint(…)
--    :SetSize(w, h)
-- ============================================================
local function CreateCheckButton(parent, label, getValue, setValue, width, height)
    local totalW = width  or 180
    local totalH = height or 22
    local BOX    = 14
    local GAP    = 8
    local baseLevel = parent:GetFrameLevel() + 1

    -- Container acts as the hit target
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(totalW, totalH)
    btn:SetFrameLevel(baseLevel)

    -- Checkbox square background
    local box = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    box:SetSize(BOX, BOX)
    box:SetPoint("LEFT", btn, "LEFT", 0, 0)
    box:SetFrameLevel(baseLevel + 1)
    box:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    box:SetBackdropColor(unpack(STYLE.bg_color))
    box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

    -- Cyan fill shown when checked
    local checkFill = box:CreateTexture(nil, "ARTWORK")
    checkFill:SetPoint("TOPLEFT",     box, "TOPLEFT",     2, -2)
    checkFill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -2,  2)
    checkFill:SetColorTexture(0, 1, 1, 0.85)
    checkFill:Hide()

    -- Hover overlay on the whole row (same fade pattern as CreateButton)
    local hoverBg = MakeHoverBg(btn, baseLevel + 1)

    -- Label
    local lbl = MakeFontString(btn, 13)
    lbl:SetText(label or "")
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetPoint("LEFT",  box, "RIGHT",   GAP, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT",   0,   0)
    lbl:SetHeight(totalH)

    local isChecked = getValue and getValue() or false

    local function Refresh()
        if isChecked then
            checkFill:Show()
            box:SetBackdropBorderColor(0, 1, 1, 0.9)
        else
            checkFill:Hide()
            box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end
    Refresh()

    btn:SetScript("OnClick", function()
        isChecked = not isChecked
        Refresh()
        if setValue then setValue(isChecked) end
    end)
    btn:SetScript("OnEnter", function()
        UIFrameFadeIn(hoverBg, STYLE.hover_in, hoverBg:GetAlpha(), 1)
    end)
    btn:SetScript("OnLeave", function()
        UIFrameFadeOut(hoverBg, STYLE.hover_out, hoverBg:GetAlpha(), 0)
    end)

    local obj = {frame = btn, label = lbl}

    function obj:SetValue(v)
        isChecked = not not v
        Refresh()
    end
    function obj:GetValue()    return isChecked               end
    function obj:SetPoint(...) self.frame:SetPoint(...)       end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)      end
    function obj:GetWidth()    return self.frame:GetWidth()   end

    return obj
end

-- ============================================================
--  CreateTextEntry
--
--  A label + styled EditBox for single-line input.
--  Committing on Enter or focus-lost calls setValue.
--
--  Params
--    parent   – WoW frame
--    label    – display string on the left
--    getValue – function() → string|number
--    setValue – function(value)
--    width    – number (default 220)
--    height   – number (default 22)
--    numeric  – bool (default false); clamps to [minVal, maxVal] if set
--    minVal   – number | nil
--    maxVal   – number | nil
--
--  Returned object
--    .frame       container Frame
--    .label       FontString
--    .editBox     WoW EditBox
--    :SetValue(v)
--    :GetValue() → string|number
--    :SetPoint(…)
--    :SetSize(w, h)
-- ============================================================
local function CreateTextEntry(parent, label, getValue, setValue,
                               width, height, numeric, minVal, maxVal)
    local totalW  = width  or 220
    local totalH  = height or 22
    local BOX_W   = 60
    local GAP     = 8
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    -- Label
    local lbl = MakeFontString(container, 13)
    lbl:SetText(label or "")
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetPoint("LEFT",  container, "LEFT",  0,              0)
    lbl:SetPoint("RIGHT", container, "RIGHT", -(BOX_W + GAP), 0)
    lbl:SetHeight(totalH)

    -- Input frame (backdrop + EditBox stacked inside)
    local inputFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    inputFrame:SetSize(BOX_W, totalH)
    inputFrame:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    inputFrame:SetFrameLevel(baseLevel + 1)
    MakeControlBackdrop(inputFrame)

    -- Cyan-border overlay when focused (same layer trick as hoverBg)
    local focusBorder = CreateFrame("Frame", nil, inputFrame, "BackdropTemplate")
    focusBorder:SetAllPoints(inputFrame)
    focusBorder:SetFrameLevel(baseLevel + 2)
    focusBorder:EnableMouse(false)
    focusBorder:SetBackdrop({
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    focusBorder:SetBackdropBorderColor(0, 1, 1, 0)   -- hidden until focused

    local edit = CreateFrame("EditBox", nil, inputFrame)
    edit:SetPoint("TOPLEFT",     inputFrame, "TOPLEFT",     4,  -2)
    edit:SetPoint("BOTTOMRIGHT", inputFrame, "BOTTOMRIGHT", -4,  2)
    edit:SetFont(ValidateFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont)), 12, NSRT.Settings.GlobalFontFlags)
    edit:SetTextColor(1, 1, 1, 1)
    edit:SetAutoFocus(false)
    edit:SetMultiLine(false)
    edit:SetMaxLetters(numeric and 8 or 200)
    edit:SetText(tostring(getValue and getValue() or ""))

    local function Commit()
        local raw = edit:GetText()
        if numeric then
            local n = tonumber(raw)
            if not n then
                edit:SetText(tostring(getValue and getValue() or 0))
                return
            end
            if minVal then n = math.max(n, minVal) end
            if maxVal then n = math.min(n, maxVal) end
            edit:SetText(tostring(n))
            if setValue then setValue(n) end
        else
            if setValue then setValue(raw) end
        end
    end

    edit:SetScript("OnEnterPressed", function() Commit() ; edit:ClearFocus() end)
    edit:SetScript("OnEscapePressed", function()
        edit:SetText(tostring(getValue and getValue() or ""))
        edit:ClearFocus()
    end)
    edit:SetScript("OnEditFocusGained", function()
        UIFrameFadeIn(focusBorder, STYLE.select_in, focusBorder:GetAlpha(), 1)
    end)
    edit:SetScript("OnEditFocusLost", function()
        UIFrameFadeOut(focusBorder, STYLE.deselect_out, focusBorder:GetAlpha(), 0)
        Commit()
    end)

    local obj = {frame = container, editBox = edit, label = lbl}

    function obj:SetValue(v)   edit:SetText(tostring(v))                                    end
    function obj:GetValue()    return numeric and tonumber(edit:GetText()) or edit:GetText() end
    function obj:SetPoint(...) self.frame:SetPoint(...)                                      end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)                                     end
    function obj:GetWidth()    return self.frame:GetWidth()                                  end

    return obj
end

-- ============================================================
--  CreateDropdown
--
--  A label + dropdown button that opens a scrollable popup.
--  The button matches CreateButton's exact visual style.
--
--  Params
--    parent      – WoW frame
--    label       – string shown on the left (nil/"" = full-width button)
--    getItems    – function() → { {label, value, onclick}, … }
--    getSelected – function() → string  (current display text)
--    width       – number (default 220)
--    height      – number (default 22)
--
--  Returned object
--    .frame    container Frame
--    .label    FontString (may be nil if no label)
--    :Refresh()          re-reads getSelected and updates display
--    :Close()
--    :SetPoint(…)
--    :SetSize(w, h)
-- ============================================================
local function CreateDropdown(parent, label, getItems, getSelected, width, height)
    local totalW   = width  or 220
    local totalH   = height or 22
    local ROW_H    = 20
    local MAX_ROWS = 10
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    local hasLabel = label and label ~= ""
    local labelW   = hasLabel and math.floor(totalW * 0.5) or 0
    local dropW    = totalW - labelW - (hasLabel and 8 or 0)

    -- Optional label
    local lbl
    if hasLabel then
        lbl = MakeFontString(container, 13)
        lbl:SetText(label)
        lbl:SetJustifyH("LEFT")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetPoint("LEFT", container, "LEFT", 0, 0)
        lbl:SetWidth(labelW)
        lbl:SetHeight(totalH)
    end

    -- Dropdown button — same backdrop & hover pattern as CreateButton
    local dropBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropBtn:SetSize(dropW, totalH)
    dropBtn:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    dropBtn:SetFrameLevel(baseLevel + 1)
    MakeControlBackdrop(dropBtn)

    local dropHover = MakeHoverBg(dropBtn, baseLevel + 2)

    -- Current-value text
    local valText = MakeFontString(dropBtn, 12)
    valText:SetJustifyH("LEFT")
    valText:SetJustifyV("MIDDLE")
    valText:SetPoint("LEFT",  dropBtn, "LEFT",  5,   0)
    valText:SetPoint("RIGHT", dropBtn, "RIGHT", -14, 0)
    valText:SetHeight(totalH)

    -- Arrow glyph
    local arrowLbl = dropBtn:CreateFontString(nil, "OVERLAY")
    arrowLbl:SetFont(FALLBACK_FONT, 9, "")
    arrowLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    arrowLbl:SetText("\226\150\188")   -- ▼
    arrowLbl:SetPoint("RIGHT", dropBtn, "RIGHT", -4, 0)

    dropBtn:SetScript("OnEnter", function()
        UIFrameFadeIn(dropHover, STYLE.hover_in, dropHover:GetAlpha(), 1)
    end)
    dropBtn:SetScript("OnLeave", function()
        UIFrameFadeOut(dropHover, STYLE.hover_out, dropHover:GetAlpha(), 0)
    end)

    -- ---- Popup (parented to UIParent so it floats above everything) ----
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("TOOLTIP")
    popup:Hide()
    popup:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    popup:SetBackdropBorderColor(0, 1, 1, 0.7)

    local scrollFrame = CreateFrame("ScrollFrame", nil, popup)
    scrollFrame:SetPoint("TOPLEFT",     popup, "TOPLEFT",     2,  -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -2,  2)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollFrame:GetVerticalScroll()
        scrollFrame:SetVerticalScroll(math.max(0, cur - delta * ROW_H))
    end)

    local content = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(content)
    content._rows = {}

    -- Click-away: FULLSCREEN strata sits above DIALOG (settings win) but below TOOLTIP (popup)
    local clickaway = CreateFrame("Frame", nil, UIParent)
    clickaway:SetAllPoints(UIParent)
    clickaway:SetFrameStrata("FULLSCREEN")
    clickaway:EnableMouse(true)
    clickaway:Hide()

    local function RefreshDisplay()
        if getSelected then
            local v = getSelected()
            valText:SetText(v ~= nil and tostring(v) or "")
        end
    end

    local function Close()
        popup:Hide()
        clickaway:Hide()
        arrowLbl:SetText("\226\150\188")   -- ▼
    end

    local function Open()
        local items    = getItems and getItems() or {}
        local rowCount = #items
        if rowCount == 0 then return end

        local popupH = math.min(rowCount * ROW_H, MAX_ROWS * ROW_H)
        popup:SetSize(dropW, popupH)
        content:SetSize(dropW - 4, rowCount * ROW_H)

        -- Grow the row pool as needed (frames are never destroyed)
        for i = #content._rows + 1, rowCount do
            local row = CreateFrame("Button", nil, content)
            row:SetSize(dropW - 4, ROW_H)

            local rowHover = MakeHoverBg(row, 2)

            local rlbl = MakeFontString(row, 12)
            rlbl:SetJustifyH("LEFT")
            rlbl:SetJustifyV("MIDDLE")
            rlbl:SetPoint("LEFT",  row, "LEFT",  6, 0)
            rlbl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            rlbl:SetHeight(ROW_H)

            row.rlbl      = rlbl
            row.rowHover  = rowHover
            content._rows[i] = row
        end

        -- Update visible rows with current item data
        for i, item in ipairs(items) do
            local row = content._rows[i]
            row.rlbl:SetText(item.label or "")
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_H)
            row:SetScript("OnEnter", function()
                UIFrameFadeIn(row.rowHover, STYLE.hover_in, row.rowHover:GetAlpha(), 1)
            end)
            row:SetScript("OnLeave", function()
                UIFrameFadeOut(row.rowHover, STYLE.hover_out, row.rowHover:GetAlpha(), 0)
            end)
            row:SetScript("OnClick", function()
                if item.onclick then item.onclick(nil, nil, item.value) end
                RefreshDisplay()
                Close()
            end)
            row:Show()
        end
        for i = rowCount + 1, #content._rows do
            content._rows[i]:Hide()
        end

        scrollFrame:SetVerticalScroll(0)

        -- Position below the button; flip above if too close to screen bottom
        popup:ClearAllPoints()
        local btnBottom = dropBtn:GetBottom()
        if btnBottom and btnBottom > popupH + 4 then
            popup:SetPoint("TOPRIGHT", dropBtn, "BOTTOMRIGHT", 0, -1)
        else
            popup:SetPoint("BOTTOMRIGHT", dropBtn, "TOPRIGHT", 0, 1)
        end

        popup:Show()
        clickaway:Show()
        arrowLbl:SetText("\226\150\186")   -- ▲
    end

    clickaway:SetScript("OnMouseDown", Close)
    dropBtn:SetScript("OnClick", function()
        if popup:IsShown() then Close() else Open() end
    end)

    RefreshDisplay()

    local obj = {frame = container, label = lbl, dropBtn = dropBtn}

    function obj:Refresh()     RefreshDisplay()              end
    function obj:Close()       Close()                       end
    function obj:SetPoint(...) self.frame:SetPoint(...)      end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)     end
    function obj:GetWidth()    return self.frame:GetWidth()  end

    return obj
end

-- ============================================================
--  Export
-- ============================================================
NSI.UI = NSI.UI or {}
NSI.UI.Components = {
    CreateButton        = CreateButton,
    CreateSubButton     = CreateSubButton,
    CreateCheckButton   = CreateCheckButton,
    CreateTextEntry     = CreateTextEntry,
    CreateDropdown      = CreateDropdown,
    RefreshFonts        = RefreshFonts,
    STYLE               = STYLE,
}
