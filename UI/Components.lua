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

local componentRegistry = {
    Slider    = {},
    Dropdown  = {},
    Color     = {},
    Checkbox  = {},
    TextEntry = {},
    Label     = {},
    Breakline = {},
}
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
local function CreateCheckButton(parent, label, getValue, setValue, width, height, name)
    local totalW = width  or 180
    local totalH = height or 22
    local BOX    = 14
    local GAP    = 8
    local baseLevel = parent:GetFrameLevel() + 1

    -- Container acts as the hit target
    local btn       = CreateFrame("Button", name, parent)
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

    componentRegistry.Checkbox[#componentRegistry.Checkbox + 1] = obj
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
                               width, height, numeric, minVal, maxVal, name)
    local totalW  = width  or 220
    local totalH  = height or 22
    local BOX_W   = 60
    local GAP     = 8
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
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

    componentRegistry.TextEntry[#componentRegistry.TextEntry + 1] = obj
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
local function CreateDropdown(parent, label, getItems, getSelected, width, height, name)
    local totalW   = width  or 220
    local totalH   = height or 22
    local ROW_H    = 20
    local MAX_ROWS = 10
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
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
    local arrowTexture = dropBtn:CreateTexture(nil, "OVERLAY")
    arrowTexture:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]])
    arrowTexture:SetSize(10, 10)
    arrowTexture:SetPoint("RIGHT", dropBtn, "RIGHT", -4, 0)

    dropBtn:SetScript("OnEnter", function()
        UIFrameFadeIn(dropHover, STYLE.hover_in, dropHover:GetAlpha(), 1)
    end)
    dropBtn:SetScript("OnLeave", function()
        UIFrameFadeOut(dropHover, STYLE.hover_out, dropHover:GetAlpha(), 0)
    end)

    -- ---- Popup (parented to UIParent so it floats above everything) ----
    local SB_W = 6   -- scrollbar width
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

    -- Scrollbar track (right strip inside popup)
    local sbTrack = popup:CreateTexture(nil, "BACKGROUND")
    sbTrack:SetColorTexture(0.10, 0.10, 0.10, 1)
    sbTrack:SetPoint("TOPRIGHT",    popup, "TOPRIGHT",    -2, -2)
    sbTrack:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -2,  2)
    sbTrack:SetWidth(SB_W)
    sbTrack:Hide()

    -- Scrollbar thumb
    local sbThumb = CreateFrame("Frame", nil, popup)
    sbThumb:SetWidth(SB_W)
    sbThumb:SetFrameLevel(popup:GetFrameLevel() + 5)
    local sbTex = sbThumb:CreateTexture(nil, "OVERLAY")
    sbTex:SetAllPoints(sbThumb)
    sbTex:SetColorTexture(0, 1, 1, 0.45)
    sbThumb:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, popup)
    scrollFrame:SetPoint("TOPLEFT",     popup, "TOPLEFT",     2,  -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -(2 + SB_W + 1), 2)
    scrollFrame:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(content)
    content._rows = {}

    -- Shared scroll helper: clamps and syncs thumb
    local function ScrollTo(offset)
        local maxScroll = math.max(0, content:GetHeight() - scrollFrame:GetHeight())
        local clamped   = math.max(0, math.min(maxScroll, offset))
        scrollFrame:SetVerticalScroll(clamped)
        -- Update thumb position
        if maxScroll > 0 then
            local trackH  = sbTrack:GetHeight()
            local thumbH  = math.max(8, trackH * (scrollFrame:GetHeight() / content:GetHeight()))
            sbThumb:SetHeight(thumbH)
            local thumbY  = (clamped / maxScroll) * (trackH - thumbH)
            sbThumb:ClearAllPoints()
            sbThumb:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -(2 + thumbY))
        end
    end

    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        ScrollTo(scrollFrame:GetVerticalScroll() - delta * ROW_H)
    end)

    -- Thumb dragging
    local sbDragging = false
    local sbDragStartY, sbDragStartScroll
    sbThumb:EnableMouse(true)
    sbThumb:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        sbDragging = true
        sbDragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        sbDragStartScroll = scrollFrame:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            if not sbDragging then return end
            local curY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local dy   = sbDragStartY - curY
            local maxScroll = math.max(0, content:GetHeight() - scrollFrame:GetHeight())
            local trackH    = sbTrack:GetHeight()
            local thumbH    = sbThumb:GetHeight()
            local ratio     = maxScroll / math.max(1, trackH - thumbH)
            ScrollTo(sbDragStartScroll + dy * ratio)
        end)
    end)
    sbThumb:SetScript("OnMouseUp", function(self)
        sbDragging = false
        self:SetScript("OnUpdate", nil)
    end)

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
        arrowTexture:SetText("\226\150\188") -- ▼
    end

    local function Open()
        local items    = getItems and getItems() or {}
        local rowCount = #items
        if rowCount == 0 then return end

        local needsScroll = rowCount > MAX_ROWS
        local popupH = math.min(rowCount * ROW_H, MAX_ROWS * ROW_H)
        popup:SetSize(dropW, popupH)
        local contentW = dropW - 4 - (needsScroll and SB_W + 1 or 0)
        content:SetSize(contentW, rowCount * ROW_H)
        if needsScroll then sbTrack:Show() sbThumb:Show() else sbTrack:Hide() sbThumb:Hide() end

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

        ScrollTo(0)

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
        arrowTexture:SetText("\226\150\186") -- ▲
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

    componentRegistry.Dropdown[#componentRegistry.Dropdown + 1] = obj
    return obj
end

-- ============================================================
--  CreateSlider
--
--  A label + thin horizontal track with a draggable cyan thumb.
--  The current value is displayed on the right. setValue fires
--  only on mouse release (not continuously during drag).
--
--  Params
--    parent   – WoW frame
--    label    – display string on the left
--    getValue – function() → number
--    setValue – function(number)   called on mouse release only
--    width    – number (default 220)
--    height   – number (default 22)
--    minVal   – number (default 0)
--    maxVal   – number (default 100)
--    step     – number | nil  (nil = smooth, floats shown to 2dp)
--
--  Returned object
--    .frame    container Frame
--    .label    FontString
--    .slider   WoW Slider widget
--    :SetValue(n)
--    :GetValue() → number
--    :SetPoint(…)
--    :SetSize(w, h)
-- ============================================================
local function CreateSlider(parent, label, getValue, setValue,
                            width, height, minVal, maxVal, step, name)
    local totalW  = width  or 220
    local totalH  = height or 22
    local LABEL_W = math.floor(totalW * 0.38)
    local VAL_W   = 38
    local TRACK_W = totalW - LABEL_W - VAL_W - 8
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    -- Label
    local lbl = MakeFontString(container, 13)
    lbl:SetText(label or "")
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetPoint("LEFT", container, "LEFT", 0, 0)
    lbl:SetWidth(LABEL_W)
    lbl:SetHeight(totalH)

    -- Track (visual only, behind the slider widget)
    local trackTex = container:CreateTexture(nil, "BACKGROUND")
    trackTex:SetColorTexture(0.10, 0.10, 0.10, 1)
    trackTex:SetHeight(3)
    trackTex:SetPoint("LEFT",  container, "LEFT", LABEL_W + 4, 0)
    trackTex:SetWidth(TRACK_W)

    -- Cyan fill that grows left → thumb position
    local fillTex = container:CreateTexture(nil, "ARTWORK")
    fillTex:SetColorTexture(0, 1, 1, 0.45)
    fillTex:SetHeight(3)
    fillTex:SetPoint("LEFT", container, "LEFT", LABEL_W + 4, 0)
    fillTex:SetWidth(1)

    -- Native Slider frame (handles all mouse + keyboard input)
    local slider = CreateFrame("Slider", nil, container)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("LEFT", container, "LEFT", LABEL_W + 4, 0)
    slider:SetSize(TRACK_W, totalH)
    slider:SetFrameLevel(baseLevel + 2)
    slider:SetMinMaxValues(minVal or 0, maxVal or 100)
    if step then
        slider:SetValueStep(step)
        if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    end
    slider:SetThumbTexture([[Interface\Buttons\WHITE8x8]])
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(8, 14)
    thumb:SetVertexColor(0, 1, 1, 1)

    -- Value text (right side)
    local valText = MakeFontString(container, 11)
    valText:SetTextColor(0.65, 0.65, 0.65, 1)
    valText:SetJustifyH("RIGHT")
    valText:SetJustifyV("MIDDLE")
    valText:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    valText:SetWidth(VAL_W)
    valText:SetHeight(totalH)

    local useFloat = (step and step < 1)
        or ((minVal or 0) ~= math.floor(minVal or 0))
        or ((maxVal or 0) ~= math.floor(maxVal or 0))

    local function Fmt(v)
        return useFloat and string.format("%.2f", v) or tostring(math.floor(v + 0.5))
    end

    local function UpdateVisual(value)
        valText:SetText(Fmt(value))
        local mn, mx = minVal or 0, maxVal or 100
        local pct = mx > mn and (value - mn) / (mx - mn) or 0
        fillTex:SetWidth(math.max(1, math.floor(pct * TRACK_W)))
    end

    -- Fire setValue only on mouse release, not during drag.
    -- Keyboard changes (arrow keys) are not dragging, so they fire immediately.
    local dragging    = false
    local initialized = false

    slider:SetScript("OnMouseDown", function() dragging = true end)
    slider:SetScript("OnMouseUp", function(self)
        dragging = false
        if setValue then setValue(self:GetValue()) end
    end)
    slider:SetScript("OnValueChanged", function(_, value)
        UpdateVisual(value)
        if initialized and not dragging and setValue then setValue(value) end
    end)
    slider:SetScript("OnEnter", function() thumb:SetVertexColor(0.5, 1, 1, 1) end)
    slider:SetScript("OnLeave", function() thumb:SetVertexColor(0,   1, 1, 1) end)

    local initVal = getValue and getValue() or (minVal or 0)
    slider:SetValue(initVal)
    UpdateVisual(initVal)
    initialized = true

    -- Right-click on value label → inline EditBox to type a number
    local valBtn = CreateFrame("Button", nil, container)
    valBtn:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    valBtn:SetSize(VAL_W, totalH)
    valBtn:SetFrameLevel(baseLevel + 4)
    valBtn:RegisterForClicks("RightButtonUp")

    local typeBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    typeBox:SetSize(VAL_W, totalH - 4)
    typeBox:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    typeBox:SetFrameLevel(baseLevel + 5)
    typeBox:SetAutoFocus(false)
    typeBox:SetNumeric(false)
    typeBox:SetMaxLetters(10)
    typeBox:SetFont(FALLBACK_FONT, 11, "")
    typeBox:SetTextColor(0, 1, 1, 1)
    typeBox:SetJustifyH("RIGHT")
    typeBox:SetBackdrop({bgFile=[[Interface\Buttons\WHITE8x8]], edgeFile=[[Interface\Buttons\WHITE8x8]], edgeSize=1})
    typeBox:SetBackdropColor(0.04, 0.04, 0.06, 1)
    typeBox:SetBackdropBorderColor(0, 1, 1, 0.8)
    typeBox:Hide()

    local function CommitTypeBox()
        local raw = typeBox:GetText()
        local n   = tonumber(raw)
        if n then
            local mn, mx = minVal or 0, maxVal or 100
            n = math.max(mn, math.min(mx, n))
            initialized = false
            slider:SetValue(n)
            UpdateVisual(n)
            initialized = true
            if setValue then setValue(n) end
        end
        typeBox:ClearFocus()
        typeBox:Hide()
        valText:Show()
    end

    valBtn:SetScript("OnClick", function()
        valText:Hide()
        typeBox:SetText(Fmt(slider:GetValue()))
        typeBox:Show()
        typeBox:SetFocus()
        typeBox:HighlightText()
    end)
    typeBox:SetScript("OnEnterPressed", CommitTypeBox)
    typeBox:SetScript("OnEscapePressed", function()
        typeBox:ClearFocus()
        typeBox:Hide()
        valText:Show()
    end)
    typeBox:SetScript("OnEditFocusLost", function()
        if typeBox:IsShown() then CommitTypeBox() end
    end)

    local obj = {frame = container, slider = slider, label = lbl}

    function obj:SetValue(v)
        initialized = false
        slider:SetValue(v)
        UpdateVisual(v)
        initialized = true
    end
    function obj:GetValue()    return slider:GetValue()       end
    function obj:SetPoint(...) self.frame:SetPoint(...)       end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)      end
    function obj:GetWidth()    return self.frame:GetWidth()   end

    componentRegistry.Slider[#componentRegistry.Slider + 1] = obj
    return obj
end

-- ============================================================
--  CreateColorPicker
--
--  A label + color swatch button. Clicking opens WoW's built-in
--  ColorPickerFrame with full alpha/opacity support. The swatch
--  previews live as the picker is moved and restores on cancel.
--
--  Params
--    parent   – WoW frame
--    label    – display string on the left
--    getValue – function() → r, g, b, a   (all 0–1)
--    setValue – function(r, g, b, a)
--    width    – number (default 220)
--    height   – number (default 22)
--
--  Returned object
--    .frame      container Frame
--    .label      FontString
--    :Refresh()  re-reads getValue and repaints the swatch
--    :SetPoint(…)
--    :SetSize(w, h)
-- ============================================================
local function CreateColorPicker(parent, label, getValue, setValue, width, height, name)
    local totalW   = width  or 220
    local totalH   = height or 22
    local SWATCH_W = 40
    local GAP      = 8
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    -- Label
    local lbl = MakeFontString(container, 13)
    lbl:SetText(label or "")
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetPoint("LEFT",  container, "LEFT",  0,                 0)
    lbl:SetPoint("RIGHT", container, "RIGHT", -(SWATCH_W + GAP), 0)
    lbl:SetHeight(totalH)

    -- Swatch button (same backdrop pattern as CreateButton)
    local swatchBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatchBtn:SetSize(SWATCH_W, totalH)
    swatchBtn:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    swatchBtn:SetFrameLevel(baseLevel + 1)
    MakeControlBackdrop(swatchBtn)

    local swatchHover = MakeHoverBg(swatchBtn, baseLevel + 2)

    -- Inset colour rectangle; alpha blends over the dark button background
    local colorTex = swatchBtn:CreateTexture(nil, "ARTWORK")
    colorTex:SetPoint("TOPLEFT",     swatchBtn, "TOPLEFT",     3, -3)
    colorTex:SetPoint("BOTTOMRIGHT", swatchBtn, "BOTTOMRIGHT", -3,  3)

    local function UpdateSwatch()
        local r, g, b, a = 1, 1, 1, 1
        if getValue then r, g, b, a = getValue() end
        colorTex:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    end
    UpdateSwatch()

    swatchBtn:SetScript("OnEnter", function()
        UIFrameFadeIn(swatchHover, STYLE.hover_in, swatchHover:GetAlpha(), 1)
    end)
    swatchBtn:SetScript("OnLeave", function()
        UIFrameFadeOut(swatchHover, STYLE.hover_out, swatchHover:GetAlpha(), 0)
    end)

    swatchBtn:SetScript("OnClick", function()
        local r, g, b, a = 1, 1, 1, 1
        if getValue then r, g, b, a = getValue() end
        r = r or 1; g = g or 1; b = b or 1; a = a or 1
        local prevR, prevG, prevB, prevA = r, g, b, a

        -- Works with both the modern (10.x) and legacy ColorPickerFrame APIs.
        local function ReadCurrent()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na
            if ColorPickerFrame.GetColorAlpha then
                na = 1 - ColorPickerFrame:GetColorAlpha()
            elseif OpacitySliderFrame then
                na = 1 - OpacitySliderFrame:GetValue()
            else
                na = 1
            end
            return nr, ng, nb, na
        end

        local function OnChange()
            local nr, ng, nb, na = ReadCurrent()
            colorTex:SetColorTexture(nr, ng, nb, na)
            if setValue then setValue(nr, ng, nb, na) end
        end

        local function OnCancel(prev)
            local cr, cg, cb, ca
            if prev and prev.r then
                cr = prev.r; cg = prev.g; cb = prev.b
                ca = prev.opacity ~= nil and (1 - prev.opacity) or prevA
            else
                cr, cg, cb, ca = prevR, prevG, prevB, prevA
            end
            colorTex:SetColorTexture(cr, cg, cb, ca)
            if setValue then setValue(cr, cg, cb, ca) end
        end

        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc  = OnChange,
                opacityFunc = OnChange,
                cancelFunc  = OnCancel,
                hasOpacity  = true,
                r = r, g = g, b = b,
                opacity = 1 - a,
            })
        else
            ColorPickerFrame.func        = OnChange
            ColorPickerFrame.opacityFunc = OnChange
            ColorPickerFrame.cancelFunc  = OnCancel
            ColorPickerFrame.hasOpacity  = true
            ColorPickerFrame:SetColorRGB(r, g, b)
            if OpacitySliderFrame then OpacitySliderFrame:SetValue(1 - a) end
            ColorPickerFrame:Show()
        end
    end)

    local obj = {frame = container, label = lbl, colorTex = colorTex}

    function obj:Refresh()     UpdateSwatch()               end
    function obj:SetPoint(...) self.frame:SetPoint(...)     end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)    end
    function obj:GetWidth()    return self.frame:GetWidth() end

    componentRegistry.Color[#componentRegistry.Color + 1] = obj
    return obj
end

-- ============================================================
--  CreateLabel
--
--  A read-only text row, useful as a section header above a
--  group of controls. Text is dimmed to distinguish it from
--  interactive control labels.
--
--  Params
--    parent  – WoW frame
--    text    – display string
--    width   – number (default 220)
--    height  – number (default 16)
--
--  Returned object
--    .frame   container Frame
--    .label   FontString
--    :SetText(s)
--    :SetPoint(…)
--    :SetSize(w, h)
-- ============================================================
local function CreateLabel(parent, text, width, height, name)
    local totalW = width  or 220
    local totalH = height or 16

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)

    local lbl = MakeFontString(container, 12)
    lbl:SetTextColor(0.55, 0.55, 0.55, 1)
    lbl:SetText(text or "")
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetAllPoints(container)

    local obj = {frame = container, label = lbl}

    function obj:SetText(s)    self.label:SetText(s)         end
    function obj:SetPoint(...) self.frame:SetPoint(...)      end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)     end
    function obj:GetWidth()    return self.frame:GetWidth()  end

    componentRegistry.Label[#componentRegistry.Label + 1] = obj
    return obj
end

-- ============================================================
--  CreateBreakline
--
--  A thin horizontal rule for separating groups of controls.
--
--  Params
--    parent  – WoW frame
--    width   – number (default 220)
--    height  – number (default 10)  line is centred vertically
--
--  Returned object
--    .frame
--    :SetPoint(…)
--    :SetSize(w, h)
-- ============================================================
local function CreateBreakline(parent, width, height, name)
    local totalW = width  or 220
    local totalH = height or 10

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)

    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0, 1, 1, 0.12)
    line:SetHeight(1)
    line:SetPoint("LEFT",  container, "LEFT",  0, 0)
    line:SetPoint("RIGHT", container, "RIGHT", 0, 0)

    local obj = {frame = container}

    function obj:SetPoint(...) self.frame:SetPoint(...)     end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)    end
    function obj:GetWidth()    return self.frame:GetWidth() end

    componentRegistry.Breakline[#componentRegistry.Breakline + 1] = obj
    return obj
end

-- ============================================================
--  CreateScrollBox
--
--  Creates a scrollable container.  Use .scrollChild as the
--  parent argument to BuildWidgets; call :UpdateScrollBar()
--  after setting the scroll child's height.
--
--  Params
--    parent – WoW frame
--    width  – outer scroll frame width
--    height – outer scroll frame height (visible area)
--
--  Returned object
--    .frame        outer ScrollFrame
--    .scrollChild  inner content Frame (pass to BuildWidgets)
--    :SetPoint(…)
--    :UpdateScrollBar()  syncs native scrollbar to child height
-- ============================================================
local scrollBoxCounter = 0
local SB_W = 16 -- native UIPanelScrollFrameTemplate scrollbar width

local function CreateScrollBox(parent, width, height)
    scrollBoxCounter = scrollBoxCounter + 1
    local boxName = "NSRTScrollBox" .. scrollBoxCounter

    local scrollFrame = CreateFrame("ScrollFrame", boxName, parent,
        "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(width, height)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local bar = _G[boxName .. "ScrollBar"]
        if bar then
            local cur    = bar:GetValue()
            local mn, mx = bar:GetMinMaxValues()
            bar:SetValue(math.max(mn, math.min(mx, cur - delta * 20)))
        end
    end)

    local child = CreateFrame("Frame", boxName .. "Child", scrollFrame)
    child:SetWidth(width - SB_W - 2)
    child:SetHeight(1)
    scrollFrame:SetScrollChild(child)
    DF:ReskinSlider(scrollFrame)

    local obj = { frame = scrollFrame, scrollChild = child }

    function obj:SetPoint(...) self.frame:SetPoint(...) end

    function obj:SetSize(w, h) self.frame:SetSize(w, h) end

    function obj:GetWidth() return self.frame:GetWidth() end

    function obj:UpdateScrollBar()
        local bar = _G[boxName .. "ScrollBar"]
        if not bar then return end
        local maxScroll = math.max(0, child:GetHeight() - scrollFrame:GetHeight())
        bar:SetMinMaxValues(0, maxScroll)
        if bar:GetValue() > maxScroll then bar:SetValue(0) end

    end
    return obj
end

-- ============================================================
--  BuildWidgets
--
--  Lays out an ordered list of component descriptors inside
--  a parent frame, stacking them top-to-bottom with a uniform
--  gap. Returns the total height consumed so the caller can
--  resize the container to fit.
--
--  definitions – array of descriptor tables, in display order:
--
--    {Type="Slider",    label=s, get=fn, set=fn, min=n, max=n, step=n}
--    {Type="Dropdown",  label=s, get=fn, set=fn, values=tbl|fn}
--       values entries: {label=s, value=any}
--       get() returns the currently selected value (looked up to find label)
--    {Type="Color",     label=s, get=fn, set=fn}
--       get() → r, g, b, a (0–1 each);  set(r, g, b, a)
--    {Type="Checkbox",  label=s, get=fn, set=fn}
--    {Type="TextEntry", label=s, get=fn, set=fn, numeric=bool, min=n, max=n}
--    {Type="Label",     text=s}
--    {Type="Breakline"}
--
--    "Scale" is accepted as an alias for "Slider".
--    Any descriptor may include height=n to override the default row height.
--    Pass namePrefix to give each created frame a unique global WoW name of
--    the form namePrefix .. "_" .. gen .. Type .. index (e.g. "NSRTOpt_1Slider1").
-- ============================================================
local WIDGET_H = {
    Slider    = 22, Scale     = 22,
    Dropdown  = 22, Color     = 22,
    Checkbox  = 22, TextEntry = 22,
    Label     = 16, Breakline = 10,
}
local WIDGET_GAP = 4
local buildGen = 0

local function BuildWidgets(parent, definitions, width, namePrefix)
    local C = NSI.UI.Components
    local y = 0
    local gen
    if namePrefix then
        buildGen = buildGen + 1
        gen = buildGen
    end
    local typeCounts = {}

    for _, def in ipairs(definitions) do
        local t    = def.Type
        local h    = def.height or WIDGET_H[t] or 22
        local ctrl

        local wName
        if namePrefix then
            typeCounts[t] = (typeCounts[t] or 0) + 1
            wName = namePrefix .. "_" .. gen .. t .. typeCounts[t]
        end
        if t == "Slider" or t == "Scale" then
            ctrl = C.CreateSlider(parent, def.label,
                def.get, def.set, width, h, def.min, def.max, def.step, wName)

        elseif t == "Dropdown" then
            local function getItems()
                local vals = type(def.values) == "function"
                    and def.values() or (def.values or {})
                local out = {}
                for _, v in ipairs(vals) do
                    out[#out + 1] = {
                        label   = v.label,
                        value   = v.value,
                        onclick = function(_, _, val)
                            if def.set then def.set(val) end
                        end,
                    }
                end
                return out
            end
            local function getSelected()
                local cur  = def.get and def.get()
                local vals = type(def.values) == "function"
                    and def.values() or (def.values or {})
                for _, v in ipairs(vals) do
                    if v.value == cur then return v.label end
                end
                return cur ~= nil and tostring(cur) or ""
            end
            ctrl = C.CreateDropdown(parent, def.label,
                getItems, getSelected, width, h, wName)

        elseif t == "Color" then
            ctrl = C.CreateColorPicker(parent, def.label,
                def.get, def.set, width, h, wName)

        elseif t == "Checkbox" then
            ctrl = C.CreateCheckButton(parent, def.label,
                def.get, def.set, width, h, wName)

        elseif t == "TextEntry" then
            ctrl = C.CreateTextEntry(parent, def.label,
                def.get, def.set, width, h, def.numeric, def.min, def.max, wName)

        elseif t == "Label" then
            ctrl = C.CreateLabel(parent, def.text, width, h, wName)

        elseif t == "Breakline" then
            ctrl = C.CreateBreakline(parent, width, h, wName)
        end

        if ctrl then
            ctrl:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
            y = y + h + WIDGET_GAP
        end
    end

    return y > 0 and (y - WIDGET_GAP) or 0
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
    CreateSlider        = CreateSlider,
    CreateColorPicker   = CreateColorPicker,
    CreateLabel         = CreateLabel,
    CreateBreakline     = CreateBreakline,
    CreateScrollBox   = CreateScrollBox,
    BuildWidgets        = BuildWidgets,
    RefreshFonts        = RefreshFonts,
    STYLE               = STYLE,
    registry          = componentRegistry,
}
