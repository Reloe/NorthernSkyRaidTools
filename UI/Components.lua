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
    bg_color       = { 0.3, 0.3, 0.3, 0.8 },
    -- Input control background (text entries, sliders, color pickers, checkboxes)
    input_bg_color = { 0.3, 0.3, 0.3, 0.9 },

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
--    parent    – WoW frame
--    text      – display string (nil or "" for icon-only buttons)
--    onClick   – function(buttonObj) called on click; may be nil
--    width     – number (nil: text pixel width + 20px padding, icon included in content)
--    height    – number (default 26)
--    name      – optional global frame name string
--    icon      – optional lib icon name or full texture path
--    textSize  – optional font size override
--    tooltip   – optional tooltip: string (title only) or table {title=s, desc=s}
--    condition – optional function() → bool; button is enabled while true,
--                disabled while false. Re-evaluated every ~0.5 s via OnUpdate.
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
--    :Disable()       also dims label and icon
--    :RefreshCondition()  manually re-evaluates condition
-- ============================================================
-- Registry of every label created by this module so RefreshFonts() can
-- update them all in one call when the player changes the addon language.
-- Stored as {label = FontString, size = number} plain entries — buttons are
-- never destroyed mid-session so no weak table needed.
local labelRegistry = {}
local localizedTextRegistry = {}

local componentRegistry = {
    Slider    = {},
    Dropdown  = {},
    Color     = {},
    Checkbox  = {},
    TextEntry = {},
    Label     = {},
    Breakline = {},
}

local function ValidateFont(path)
    return NSI:ValidateFontPath(path)
end

local function RefreshFonts()
    local fontPath = ValidateFont(NSI:GetUIFontPath())
    local fontFlags = NSI:GetUIFontFlags()
    for _, entry in ipairs(labelRegistry) do
        entry.label:SetFont(fontPath, entry.size, fontFlags)
    end
end

local function RefreshLocalizedTexts()
    for object, info in pairs(localizedTextRegistry) do
        if object and object.SetText then
            local text = info.formatter and info.formatter() or NSI:Loc(info.key)
            object:SetText(text)
        else
            localizedTextRegistry[object] = nil
        end
    end
end

local function RegisterLocalizedText(object, key, formatter)
    if not object or not object.SetText then return end
    localizedTextRegistry[object] = {key = key, formatter = formatter}
    object:SetText(formatter and formatter() or NSI:Loc(key))
end

local function ShowTooltip(frame, tooltip, anchor)
    if not tooltip then return end
    GameTooltip:SetOwner(frame, anchor or "ANCHOR_TOP")
    if type(tooltip) == "table" then
        GameTooltip:SetText(tooltip.title and NSI:Loc(tooltip.title) or "")
        if tooltip.desc then
            GameTooltip:AddLine(NSI:Loc(tooltip.desc), 1, 1, 1, true)
        end
    else
        GameTooltip:SetText(NSI:Loc(tooltip))
    end
    GameTooltip:Show()
end

local function HideTooltip(tooltip)
    if tooltip then GameTooltip:Hide() end
end

local function CreateButton(parent, text, onClick, width, height, name, icon, textSize, tooltip, condition)
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
    local labelSize = textSize or STYLE.text_size
    label:SetFont(ValidateFont(NSI:GetUIFontPath()), labelSize, NSI:GetUIFontFlags())
    label:SetTextColor(unpack(STYLE.text_color))
    label:SetText(text or "")
    label:SetJustifyV("MIDDLE")
    label:SetJustifyH("CENTER")
    label:SetAllPoints(labelFrame)
    labelRegistry[#labelRegistry + 1] = {label = label, size = labelSize}

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
        -- Support both direct texture paths and LibSharedMedia names
        if icon:find("\\") or icon:find("/") then
            iconTex:SetTexture(icon)
        else
            local texture_info = NSI.LSM:Fetch("statusbar", icon)
            iconTex:SetTexture(texture_info .. ".png")
        end
        iconTex:SetTexCoord(0.1, 0.9, 0.09, 0.91)
        iconTex:SetVertexColor(1, 1, 1)
        btn.icon = iconTex
        btn.iconFrame = iconFrame

        -- Centre [icon  gap  text] as a group inside the button.
        local groupLeft = (btnWidth - contentW) / 2
        iconFrame:SetPoint("LEFT", btn, "LEFT", groupLeft, 0)

        -- For icon-only buttons (no text), just center the icon
        if textWidth <= 1 then
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint("CENTER", btn, "CENTER", 0, 0)
            labelFrame:Hide()
        else
            labelFrame:SetSize(textWidth, btnHeight)
            labelFrame:SetPoint("LEFT", iconFrame, "RIGHT", iconGap, 0)
        end
    else
        -- Fixed-width buttons can change font or label text after creation.
        -- Keep their label sized to the button instead of the initial text width.
        labelFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", padH, 0)
        labelFrame:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -padH, 0)
    end
    -- ---- mouse scripts ----------------------------------------
    btn:SetScript("OnEnter", function(self)
        UIFrameFadeIn(hoverBg, STYLE.hover_in, hoverBg:GetAlpha(), 1)
        ShowTooltip(self, tooltip)
    end)
    btn:SetScript("OnLeave", function()
        UIFrameFadeOut(hoverBg, STYLE.hover_out, hoverBg:GetAlpha(), 0)
        HideTooltip(tooltip)
    end)

    -- ---- public object ----------------------------------------
    local buttonObj = {
        frame      = btn,
        label      = label,
        labelFrame = labelFrame,
        iconFrame  = btn.iconFrame,
        hoverBg    = hoverBg,
        selectedBg = selectedBg,
        _selected  = false,
        _iconSize  = iconSize,
        _iconGap   = iconGap,
        _padH      = padH,
    }

    -- Wire click after buttonObj exists so the callback receives it
    btn:SetScript("OnClick", function()
        if onClick then onClick(buttonObj) end
    end)

    function buttonObj:SetText(s)
        self.label:SetText(s)
        if self.iconFrame then
            local textWidth = math.max(self.label:GetStringWidth(), 1)
            if textWidth <= 1 then
                self.iconFrame:ClearAllPoints()
                self.iconFrame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
                self.labelFrame:Hide()
                return
            end

            self.labelFrame:Show()
            local buttonWidth = self.frame:GetWidth()
            local contentW = self._iconSize + self._iconGap + textWidth
            local groupLeft = math.max(self._padH, math.floor((buttonWidth - contentW) / 2))
            self.iconFrame:ClearAllPoints()
            self.iconFrame:SetPoint("LEFT", self.frame, "LEFT", groupLeft, 0)
            self.labelFrame:ClearAllPoints()
            self.labelFrame:SetPoint("LEFT", self.iconFrame, "RIGHT", self._iconGap, 0)
            self.labelFrame:SetPoint("RIGHT", self.frame, "RIGHT", -self._padH, 0)
            self.labelFrame:SetHeight(self.frame:GetHeight())
        end
    end

    function buttonObj:SetLocaleKey(key, formatter)
        RegisterLocalizedText(self, key, formatter)
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
        if self.frame.icon then
            self.frame.icon:SetVertexColor(1, 1, 1, 1)
        end
    end

    function buttonObj:Disable()
        self.frame:Disable()
        self.label:SetTextColor(unpack(STYLE.text_disabled))
        if self.frame.icon then
            self.frame.icon:SetVertexColor(unpack(STYLE.text_disabled))
        end
    end

    function buttonObj:RefreshCondition()
        if condition then
            if condition() then self:Enable() else self:Disable() end
        end
    end

    if condition then
        buttonObj:RefreshCondition()
        local elapsed = 0
        btn:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + dt
            if elapsed >= 0.5 then
                elapsed = 0
                buttonObj:RefreshCondition()
            end
        end)
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
local function CreateSubButton(parent, text, onClick, width, name, tooltip)
    return CreateButton(parent, text, onClick, width, 18, name, nil, 12, tooltip)
end

local function CreateLocalizedButton(parent, key, onClick, width, height, name, icon, textSize, tooltip)
    local btn = CreateButton(parent, NSI:Loc(key), onClick, width, height, name, icon, textSize, tooltip)
    btn:SetLocaleKey(key)
    return btn
end

local function CreateLocalizedSubButton(parent, key, onClick, width, name, tooltip)
    return CreateLocalizedButton(parent, key, onClick, width, 18, name, nil, 12, tooltip)
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
    frame:SetBackdropColor(unpack(STYLE.input_bg_color))
end

local function MakeFontString(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ValidateFont(NSI:GetUIFontPath()), size, NSI:GetUIFontFlags())
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
local function CreateCheckButton(parent, label, getValue, setValue, width, height, name, tooltip)
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

    local isChecked = getValue and getValue(NSI) or false

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

    local cb = { fn = setValue }
    btn:SetScript("OnClick", function()
        isChecked = not isChecked
        Refresh()
        if cb.fn then cb.fn(NSI, isChecked) end
    end)
    btn:SetScript("OnEnter", function()
        UIFrameFadeIn(hoverBg, STYLE.hover_in, hoverBg:GetAlpha(), 1)
        ShowTooltip(btn, tooltip, "ANCHOR_TOPLEFT")
    end)
    btn:SetScript("OnLeave", function()
        UIFrameFadeOut(hoverBg, STYLE.hover_out, hoverBg:GetAlpha(), 0)
        HideTooltip(tooltip)
    end)

    local obj = {frame = btn, label = lbl}

    function obj:SetValue(v)
        isChecked = not not v; Refresh()
    end

    function obj:GetValue() return isChecked end

    function obj:SetOnChange(fn) cb.fn = fn end

    function obj:SetPoint(...) self.frame:SetPoint(...) end

    function obj:SetSize(w, h) self.frame:SetSize(w, h) end

    function obj:GetWidth() return self.frame:GetWidth() end

    function obj:SetLocaleKey(key)
        RegisterLocalizedText(self.label, key)
    end

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
                               width, height, numeric, minVal, maxVal, name, tooltip)
    local totalW    = width or 220
    local totalH    = height or 22
    local BOX_W     = 60
    local GAP       = 8
    local hasLabel  = label and label ~= ""
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    -- Label (only when provided; omitting it makes the input span the full width)
    local lbl
    if hasLabel then
        lbl = MakeFontString(container, 13)
        lbl:SetText(label)
        lbl:SetJustifyH("LEFT")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetPoint("LEFT", container, "LEFT", 0, 0)
        lbl:SetPoint("RIGHT", container, "RIGHT", -(BOX_W + GAP), 0)
        lbl:SetHeight(totalH)
    end

    local inputW = hasLabel and BOX_W or totalW

    -- Input frame (backdrop + EditBox stacked inside)
    local inputFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    inputFrame:SetSize(inputW, totalH)
    if hasLabel then
        inputFrame:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    else
        inputFrame:SetPoint("LEFT", container, "LEFT", 0, 0)
    end
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
    edit:SetFont(ValidateFont(NSI:GetUIFontPath()), 12, NSI:GetUIFontFlags())
    edit:SetTextColor(1, 1, 1, 1)
    labelRegistry[#labelRegistry + 1] = {label = edit, size = 12}
    edit:SetAutoFocus(false)
    edit:SetMultiLine(false)
    edit:SetMaxLetters(numeric and 8 or 200)
    edit:SetText(tostring(getValue and getValue(NSI) or ""))

    local function Commit()
        local raw = edit:GetText()
        if numeric then
            local n = tonumber(raw)
            if not n then
                edit:SetText(tostring(getValue and getValue(NSI) or 0))
                return
            end
            if minVal then n = math.max(n, minVal) end
            if maxVal then n = math.min(n, maxVal) end
            edit:SetText(tostring(n))
            if setValue then setValue(NSI, n) end
        else
            if setValue then setValue(NSI, raw) end
        end
    end

    edit:SetScript("OnEnterPressed", function() Commit() ; edit:ClearFocus() end)
    edit:SetScript("OnEscapePressed", function()
        edit:SetText(tostring(getValue and getValue(NSI) or ""))
        edit:ClearFocus()
    end)
    edit:SetScript("OnEditFocusGained", function()
        UIFrameFadeIn(focusBorder, STYLE.select_in, focusBorder:GetAlpha(), 1)
    end)
    edit:SetScript("OnEditFocusLost", function()
        UIFrameFadeOut(focusBorder, STYLE.deselect_out, focusBorder:GetAlpha(), 0)
        Commit()
    end)
    edit:SetScript("OnEnter", function(self)
        ShowTooltip(self, tooltip)
    end)
    edit:SetScript("OnLeave", function()
        HideTooltip(tooltip)
    end)

    local obj = {frame = container, editBox = edit, label = lbl}

    function obj:SetValue(v)   edit:SetText(tostring(v))                                    end
    function obj:GetValue()    return numeric and tonumber(edit:GetText()) or edit:GetText() end
    function obj:SetPoint(...) self.frame:SetPoint(...)                                      end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)                                     end
    function obj:GetWidth()    return self.frame:GetWidth()                                  end
    function obj:SetLocaleKey(key)
        if self.label then RegisterLocalizedText(self.label, key) end
    end

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
local function CreateDropdown(parent, label, getItems, getSelected, width, height, name, tooltip)
    local totalW   = width  or 220
    local totalH   = height or 22
    local ROW_H    = 20
    local MAX_ROWS = 11
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
        ShowTooltip(dropBtn, tooltip, "ANCHOR_TOPLEFT")
    end)
    dropBtn:SetScript("OnLeave", function()
        UIFrameFadeOut(dropHover, STYLE.hover_out, dropHover:GetAlpha(), 0)
        HideTooltip(tooltip)
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

            local iconTex = row:CreateTexture(nil, "ARTWORK")
            iconTex:SetPoint("LEFT", row, "LEFT", 4, 0)
            iconTex:Hide()
            local rlbl = MakeFontString(row, 12)
            rlbl:SetJustifyH("LEFT")
            rlbl:SetJustifyV("MIDDLE")
            rlbl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            rlbl:SetHeight(ROW_H)

            row.iconTex      = iconTex
            row.rlbl      = rlbl
            row.rowHover  = rowHover
            content._rows[i] = row
        end

        -- Update visible rows with current item data
        for i, item in ipairs(items) do
            local row = content._rows[i]
            row.rlbl:SetText(item.label or "")
            -- Icon
            if item.icon then
                local sz = item.iconsize or { ROW_H - 6, ROW_H - 6 }
                row.iconTex:SetSize(sz[1], sz[2])
                row.iconTex:SetTexture(item.icon)
                if item.texcoord then
                    row.iconTex:SetTexCoord(unpack(item.texcoord))
                else
                    row.iconTex:SetTexCoord(0, 1, 0, 1)
                end
                row.iconTex:Show()
                row.rlbl:ClearAllPoints()
                row.rlbl:SetPoint("LEFT", row.iconTex, "RIGHT", 4, 0)
                row.rlbl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                row.rlbl:SetHeight(ROW_H)
            else
                row.iconTex:Hide()
                row.rlbl:ClearAllPoints()
                row.rlbl:SetPoint("LEFT", row, "LEFT", 6, 0)
                row.rlbl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                row.rlbl:SetHeight(ROW_H)
            end
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
    function obj:SetLocaleKey(key)
        if self.label then RegisterLocalizedText(self.label, key) end
    end

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
                            width, height, minVal, maxVal, step, name, tooltip, liveDrag, decimals, useDecimals)
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

    local function GetDecimalPlaces(v)
        local text = tostring(v or "")
        local fractional = text:match("%.(%d+)")
        return fractional and #fractional or 0
    end

    local configuredDecimals = tonumber(decimals)
    local stepDecimals = step and step < 1 and math.max(1, GetDecimalPlaces(step)) or nil
    local minDecimals = minVal and minVal ~= math.floor(minVal) and GetDecimalPlaces(minVal) or 0
    local maxDecimals = maxVal and maxVal ~= math.floor(maxVal) and GetDecimalPlaces(maxVal) or 0

    local function Fmt(v)
        if type(v) ~= "number" then return "" end

        local precision = configuredDecimals
        if precision == nil then
            if stepDecimals then
                precision = stepDecimals
            elseif useDecimals then
                precision = 2
            else
                local rangeDecimals = math.max(minDecimals, maxDecimals)
                if rangeDecimals > 0 then
                    precision = rangeDecimals
                elseif v ~= math.floor(v) then
                    precision = 2
                else
                    precision = 0
                end
            end
        end

        if precision > 0 then
            local text = string.format("%." .. precision .. "f", v)
            text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
            return text
        end

        return tostring(math.floor(v + 0.5))
    end

    local function UpdateVisual(value)
        valText:SetText(Fmt(value))
        local mn, mx = minVal or 0, maxVal or 100
        local pct = mx > mn and (value - mn) / (mx - mn) or 0
        fillTex:SetWidth(math.max(1, math.floor(pct * TRACK_W)))
    end

    -- Fire setValue only on mouse release, not during drag, unless liveDrag
    -- is requested (e.g. a position slider paired with a live preview).
    -- Keyboard changes (arrow keys) are not dragging, so they fire immediately.
    local dragging    = false
    local initialized = false

    slider:SetScript("OnMouseDown", function() dragging = true end)
    slider:SetScript("OnMouseUp", function(self)
        dragging = false
        if setValue then setValue(NSI, self:GetValue()) end
    end)
    slider:SetScript("OnValueChanged", function(_, value)
        UpdateVisual(value)
        if initialized and setValue and (liveDrag or not dragging) then setValue(NSI, value) end
    end)
    slider:SetScript("OnEnter", function(self)
        thumb:SetVertexColor(0.5, 1, 1, 1)
        ShowTooltip(self, tooltip)
    end)
    slider:SetScript("OnLeave", function()
        thumb:SetVertexColor(0,   1, 1, 1)
        HideTooltip(tooltip)
    end)

    local initVal = (getValue and getValue(NSI)) or (minVal or 0)
    local mn, mx = minVal or 0, maxVal or 100
    if type(initVal) ~= "number" or initVal ~= initVal or initVal == math.huge or initVal == -math.huge then
        initVal = mn
    end
    initVal = math.max(mn, math.min(mx, initVal))
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
    typeBox:SetFont(ValidateFont(NSI:GetFallbackUIFontPath()), 11, "")
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
            if setValue then setValue(NSI, n) end
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
    function obj:SetLocaleKey(key)
        RegisterLocalizedText(self.label, key)
    end

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
local function CreateColorPicker(parent, label, getValue, setValue, width, height, name, tooltip)
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
        if getValue then r, g, b, a = getValue(NSI) end
        colorTex:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    end
    UpdateSwatch()

    swatchBtn:SetScript("OnEnter", function()
        UIFrameFadeIn(swatchHover, STYLE.hover_in, swatchHover:GetAlpha(), 1)
        ShowTooltip(swatchBtn, tooltip)
    end)
    swatchBtn:SetScript("OnLeave", function()
        UIFrameFadeOut(swatchHover, STYLE.hover_out, swatchHover:GetAlpha(), 0)
        HideTooltip(tooltip)
    end)

    swatchBtn:SetScript("OnClick", function()
        local r, g, b, a = 1, 1, 1, 1
        if getValue then r, g, b, a = getValue(NSI) end
        r = r or 1; g = g or 1; b = b or 1; a = a or 1
        local prevR, prevG, prevB, prevA = r, g, b, a

        -- Works with both the modern (10.x) and legacy ColorPickerFrame APIs.
        local function ReadCurrent()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na
            if ColorPickerFrame.GetColorAlpha then
                na = ColorPickerFrame:GetColorAlpha()
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
            if setValue then setValue(NSI, nr, ng, nb, na) end
        end

        local function OnCancel(prev)
            local cr, cg, cb, ca
            if prev and prev.r then
                cr = prev.r; cg = prev.g; cb = prev.b
                ca = prev.opacity ~= nil and prev.opacity or prevA
            else
                cr, cg, cb, ca = prevR, prevG, prevB, prevA
            end
            colorTex:SetColorTexture(cr, cg, cb, ca)
            if setValue then setValue(NSI, cr, cg, cb, ca) end
        end

        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc  = OnChange,
                opacityFunc = OnChange,
                cancelFunc  = OnCancel,
                hasOpacity  = true,
                r = r, g = g, b = b,
                opacity = a,
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
    function obj:SetLocaleKey(key)
        RegisterLocalizedText(self.label, key)
    end

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
    function obj:SetLocaleKey(key)
        RegisterLocalizedText(self.label, key)
    end

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
-- ============================================================
--  ReskinScrollbar
--
--  Applies the Northern Sky style to a native
--  UIPanelScrollFrameTemplate scrollbar: dark track,
--  thin cyan thumb, and custom chevron arrow buttons.
--
--  Params
--    scrollFrame – a named ScrollFrame created with
--                  UIPanelScrollFrameTemplate
-- ============================================================
local ICON_PATH = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]

local function StyleArrowButton(btn, iconFile)
    if not btn then return end

    -- Clear all default Blizzard textures
    if btn.SetNormalTexture then btn:SetNormalTexture("") end
    if btn.SetPushedTexture then btn:SetPushedTexture("") end
    if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
    if btn.SetDisabledTexture then btn:SetDisabledTexture("") end

    -- Dark box background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetColorTexture(0.07, 0.07, 0.07, 1)

    -- Cyan hover overlay (fades in/out)
    local hoverBg = CreateFrame("Frame", nil, btn)
    hoverBg:SetAllPoints(btn)
    hoverBg:SetFrameLevel(btn:GetFrameLevel() + 1)
    hoverBg:EnableMouse(false)
    local hoverTex = hoverBg:CreateTexture(nil, "BACKGROUND")
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(unpack(STYLE.hover_color))
    hoverBg:SetAlpha(0)

    -- Chevron icon centred inside the box
    local iconFrame = CreateFrame("Frame", nil, btn)
    iconFrame:SetSize(8, 8)
    iconFrame:SetAllPoints(btn)
    iconFrame:SetFrameLevel(btn:GetFrameLevel() + 2)
    iconFrame:EnableMouse(false)
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(ICON_PATH .. iconFile)
    icon:SetVertexColor(0.7, 0.7, 0.7, 1)

    btn:SetScript("OnEnter", function()
        UIFrameFadeIn(hoverBg, STYLE.hover_in, hoverBg:GetAlpha(), 1)
        icon:SetVertexColor(0, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        UIFrameFadeOut(hoverBg, STYLE.hover_out, hoverBg:GetAlpha(), 0)
        icon:SetVertexColor(0.7, 0.7, 0.7, 1)
    end)
end

local function ReskinScrollbar(scrollFrame)
    local name = scrollFrame:GetName()
    if not name then return end
    local bar = _G[name .. "ScrollBar"]
    if not bar then return end

    -- Dark track behind the thumb
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(bar)
    track:SetColorTexture(0.07, 0.07, 0.07, 1)

    -- Thin cyan thumb
    if bar.GetThumbTexture then
        local thumb = bar:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(0, 1, 1, 0.45)
            thumb:SetWidth(6)
        end
    end

    -- Chevron arrow buttons
    StyleArrowButton(_G[name .. "ScrollBarScrollUpButton"], "chevron-up.png")
    StyleArrowButton(_G[name .. "ScrollBarScrollDownButton"], "chevron-down.png")
end
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
    ReskinScrollbar(scrollFrame)

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
--    {Type="Custom",    build=fn}
--       build(parent, width, wName) → frame, height
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
    Link      = 22,
}
local WIDGET_GAP = 4
local buildGen = 0

-- Accepts a function or a loadstring-compatible string ("return function(...) end").
-- Returns a callable, or nil if the input is nil.
local function ResolveCallback(v)
    if type(v) == "string" then
        local fn, err = loadstring(v)
        if not fn then
            print("|cFFFF0000NSRT BuildWidgets:|r failed to compile callback:", err)
            return nil
        end
        return fn()   -- the string must evaluate to a function
    end
    return v          -- already a function (or nil)
end

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
                ResolveCallback(def.get), ResolveCallback(def.set),
                width, h, def.min, def.max, def.step, wName, def.tooltip, def.liveDrag, def.decimals, def.usedecimals or def.useDecimals)

        elseif t == "Dropdown" then
            local resolvedGet    = ResolveCallback(def.get)
            local resolvedSet    = ResolveCallback(def.set)
            local resolvedValues = ResolveCallback(def.values)
            local function getItems()
                local vals = type(resolvedValues) == "function"
                    and resolvedValues(NSI) or (resolvedValues or {})
                local out = {}
                for _, v in ipairs(vals) do
                    out[#out + 1] = {
                        label   = v.label and NSI:Loc(v.label) or nil,
                        value   = v.value,
                        onclick = function(_, _, val)
                            if resolvedSet then resolvedSet(NSI, val) end
                        end,
                    }
                end
                return out
            end
            local function getSelected()
                local cur  = resolvedGet and resolvedGet(NSI)
                local vals = type(resolvedValues) == "function"
                    and resolvedValues(NSI) or (resolvedValues or {})
                for _, v in ipairs(vals) do
                    if v.value == cur then return v.label and NSI:Loc(v.label) or "" end
                end
                return cur ~= nil and tostring(cur) or ""
            end
            ctrl = C.CreateDropdown(parent, def.label,
                getItems, getSelected, width, h, wName, def.tooltip)

        elseif t == "Color" then
            ctrl = C.CreateColorPicker(parent, def.label,
                ResolveCallback(def.get), ResolveCallback(def.set), width, h, wName, def.tooltip)

        elseif t == "Checkbox" then
            ctrl = C.CreateCheckButton(parent, def.label,
                ResolveCallback(def.get), ResolveCallback(def.set), width, h, wName, def.tooltip)

        elseif t == "TextEntry" then
            ctrl = C.CreateTextEntry(parent, def.label,
                ResolveCallback(def.get), ResolveCallback(def.set),
                width, h, def.numeric, def.min, def.max, wName, def.tooltip)

        elseif t == "Label" then
            ctrl = C.CreateLabel(parent, def.text, width, h, wName)

        elseif t == "Breakline" then
            ctrl = C.CreateBreakline(parent, width, h, wName)

        elseif t == "Link" then
            ctrl = C.CreateLink(parent, def.label, def.url, def.width or width, h, wName, def.tooltip)

        elseif t == "Button" then
            local resolvedFunc = ResolveCallback(def.func)
            ctrl = C.CreateButton(parent, def.label, function()
                if resolvedFunc then resolvedFunc(NSI) end
            end, def.width or width, h, wName, nil, nil, def.tooltip)

        elseif t == "Custom" then
            local resolvedBuild = ResolveCallback(def.build)
            if resolvedBuild then
                local builtHeight
                ctrl, builtHeight = resolvedBuild(parent, width, wName)
                h = builtHeight or h
            end
        end

        if ctrl then
            if def.label and ctrl.SetLocaleKey then
                ctrl:SetLocaleKey(def.label)
            elseif def.text and ctrl.SetLocaleKey then
                ctrl:SetLocaleKey(def.text)
            end
            ctrl:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
            y = y + h + WIDGET_GAP
        end
    end

    return y > 0 and (y - WIDGET_GAP) or 0
end

-- ============================================================
--  CreateDialog
--
--  Creates (or re-shows) a named dialog.  Each unique name maps
--  to one frame cached in NSI.UI.Components.Dialogs; subsequent
--  calls with the same name just re-show the cached frame.
--
--  Params
--    name     – unique key; also forms the global WoW frame name
--    title    – title bar text
--    body     – body / content text (word-wrapped)
--    btn1Text – primary button label
--    btn1Fn   – function() called then dialog hides; may be nil
--    btn2Text – secondary button label (nil → single centered button)
--    btn2Fn   – function() called then dialog hides; may be nil
--
--  Returns the WoW frame.
-- ============================================================
local DIALOG_W       = 380
local DIALOG_H       = 190
local DIALOG_TITLE_H = 30
local DIALOG_BTN_H   = 26
local DIALOG_BTN_W   = 110
local DIALOG_PAD     = 12

local Dialogs = {}

local function CreateDialog(name, title, body, btn1Text, btn1Fn, btn2Text, btn2Fn)
    if Dialogs[name] then
        Dialogs[name]:Show()
        return Dialogs[name]
    end

    local frameName = "NSRTDialog_" .. name
    local f = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    f:SetSize(DIALOG_W, DIALOG_H)
    f:SetPoint("CENTER", UIParent, "CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
        tile     = true,
        tileSize = 64,
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    f:SetBackdropBorderColor(0, 1, 1, 0.7)

    -- ── Title bar (drag handle) ──────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -1)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(DIALOG_TITLE_H)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then f:StartMoving() end
    end)
    titleBar:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    local titleFS = MakeFontString(f, 14)
    titleFS:SetText(title or "")
    titleFS:SetJustifyH("LEFT")
    titleFS:SetJustifyV("MIDDLE")
    titleFS:SetPoint("LEFT",  titleBar, "LEFT",  DIALOG_PAD, 0)
    titleFS:SetPoint("RIGHT", titleBar, "RIGHT", -28, 0)
    titleFS:SetHeight(DIALOG_TITLE_H)

    local titleSep = f:CreateTexture(nil, "ARTWORK")
    titleSep:SetColorTexture(0, 1, 1, 0.20)
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -(DIALOG_TITLE_H + 1))
    titleSep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(DIALOG_TITLE_H + 1))

    -- ── Close (×) button ────────────────────────────────────────
    local xBtn = CreateFrame("Button", nil, f)
    xBtn:SetSize(14, 14)
    xBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    xBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    xBtn:SetNormalTexture(ICON_PATH .. "x.png")
    xBtn:GetNormalTexture():SetVertexColor(0.55, 0.55, 0.55, 1)
    xBtn:SetScript("OnEnter", function() xBtn:GetNormalTexture():SetVertexColor(0, 1, 1, 1) end)
    xBtn:SetScript("OnLeave", function() xBtn:GetNormalTexture():SetVertexColor(0.55, 0.55, 0.55, 1) end)
    xBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Body text ────────────────────────────────────────────────
    local bodyFS = MakeFontString(f, 13)
    bodyFS:SetText(body or "")
    bodyFS:SetJustifyH("LEFT")
    bodyFS:SetJustifyV("TOP")
    bodyFS:SetWordWrap(true)
    bodyFS:SetPoint("TOPLEFT",     f, "TOPLEFT",     DIALOG_PAD, -(DIALOG_TITLE_H + DIALOG_PAD))
    bodyFS:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -DIALOG_PAD, DIALOG_BTN_H + DIALOG_PAD * 2)

    -- ── Buttons ──────────────────────────────────────────────────
    local btn1 = CreateButton(f, btn1Text or "OK", function()
        if btn1Fn then btn1Fn() end
        f:Hide()
    end, DIALOG_BTN_W, DIALOG_BTN_H)

    if btn2Text then
        btn1:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -6, DIALOG_PAD)
        local btn2 = CreateButton(f, btn2Text, function()
            if btn2Fn then btn2Fn() end
            f:Hide()
        end, DIALOG_BTN_W, DIALOG_BTN_H)
        btn2:SetPoint("BOTTOMLEFT", f, "BOTTOM", 6, DIALOG_PAD)
    else
        btn1:SetPoint("BOTTOM", f, "BOTTOM", 0, DIALOG_PAD)
    end

    -- Escape key support via UISpecialFrames
    tinsert(UISpecialFrames, frameName)

    Dialogs[name] = f
    f:Show()
    return f
end

-- ============================================================
--  CreateStyledFrame
--
--  A general-purpose container frame styled with the Northern
--  Sky visual style: dark background, cyan border, and an ×
--  close button top-right. Draggable and clamped to screen.
--
--  Params
--    parent – WoW frame (nil defaults to UIParent)
--    width  – number
--    height – number
--    name   – optional global frame name (also registers Escape key support)
--
--  Returns the WoW Frame directly; use it as a parent for child
--  widgets. Call :Hide() / :Show() to toggle visibility.
-- ============================================================
local function CreateStyledFrame(parent, width, height, name)
    local f = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    f:SetSize(width or 400, height or 300)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)

    f:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
        tile     = true,
        tileSize = 64,
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    f:SetBackdropBorderColor(0, 1, 1, 0.7)

    local xBtn = CreateFrame("Button", nil, f)
    xBtn:SetSize(14, 14)
    xBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    xBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    xBtn:SetNormalTexture(ICON_PATH .. "x.png")
    xBtn:GetNormalTexture():SetVertexColor(0.55, 0.55, 0.55, 1)
    xBtn:SetScript("OnEnter", function() xBtn:GetNormalTexture():SetVertexColor(0, 1, 1, 1) end)
    xBtn:SetScript("OnLeave", function() xBtn:GetNormalTexture():SetVertexColor(0.55, 0.55, 0.55, 1) end)
    xBtn:SetScript("OnClick", function() f:Hide() end)

    if name then tinsert(UISpecialFrames, name) end

    return f
end

-- ============================================================
--  ShowContextMenu
--
--  Opens a styled context menu at the cursor position.
--  Nested submenus open on hover; all menus share the NSRT
--  visual style (dark bg, cyan border, hover fades).
--
--  items – array of descriptor tables:
--    { type="button",  label="…", fnc=fn,    icon=texOrID, spellIcon=spellID }
--    { type="submenu", label="…", items={…}, icon=texOrID, spellIcon=spellID }
--    { type="label",   text="…" }
--    { type="separator" }
--
--  width – optional fixed px width; nil = auto-sized to widest label
-- ============================================================
local CTX_ROW_H    = 20
local CTX_SEP_H    = 8
local CTX_LABEL_H  = 18
local CTX_PAD_H    = 8
local CTX_ICON_SZ  = 14
local CTX_ICON_GAP = 4
local CTX_ARROW_W  = 14

local MAX_CTX_LEVELS = 5
local ctxFrames      = {}
local ctxClickaway   = nil
local _ctxMeasureFS

local function CtxMeasureText(text)
    if not _ctxMeasureFS then
        _ctxMeasureFS = UIParent:CreateFontString(nil, "ARTWORK")
        _ctxMeasureFS:Hide()
    end
    _ctxMeasureFS:SetFont(
        ValidateFont(NSI:GetUIFontPath()),
        13,
        NSI:GetUIFontFlags())
    _ctxMeasureFS:SetText(text or "")
    return _ctxMeasureFS:GetStringWidth()
end

local function ResolveCtxIcon(item)
    if item.spellIcon then
        if C_Spell and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(item.spellIcon)
        elseif GetSpellTexture then
            return GetSpellTexture(item.spellIcon)
        end
    end
    return item.icon or nil
end

local function HideCtxFromLevel(level)
    for i = level, MAX_CTX_LEVELS do
        if ctxFrames[i] then ctxFrames[i]:Hide() end
    end
    if level <= 1 and ctxClickaway then ctxClickaway:Hide() end
end

local function EnsureCtxClickaway()
    if ctxClickaway then return end
    ctxClickaway = CreateFrame("Frame", nil, UIParent)
    ctxClickaway:SetAllPoints(UIParent)
    ctxClickaway:SetFrameStrata("FULLSCREEN")
    ctxClickaway:EnableMouse(true)
    ctxClickaway:Hide()
    ctxClickaway:SetScript("OnMouseDown", function() HideCtxFromLevel(1) end)
end

local function GetOrCreateCtxFrame(level)
    if ctxFrames[level] then return ctxFrames[level] end
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(200 + level * 5)
    f:Hide()
    f:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
        tile     = true,
        tileSize = 64,
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    f:SetBackdropBorderColor(0, 1, 1, 0.7)
    f._rows = {}
    ctxFrames[level] = f
    return f
end

local ShowContextAtLevel

ShowContextAtLevel = function(items, level, xNormal, xFlip, yTop, width)
    HideCtxFromLevel(level + 1)
    EnsureCtxClickaway()

    local f         = GetOrCreateCtxFrame(level)
    local baseLevel = f:GetFrameLevel()

    -- ── Width ────────────────────────────────────────────────────
    if not width then
        local hasIcon, hasSubmenu = false, false
        local maxW = 0
        for _, item in ipairs(items) do
            local t = item.type
            if t == "button" or t == "submenu" then
                local w = CtxMeasureText(item.label or "")
                if w > maxW then maxW = w end
                if ResolveCtxIcon(item) then hasIcon = true end
                if t == "submenu" then hasSubmenu = true end
            elseif t == "label" then
                local w = CtxMeasureText(item.text or "")
                if w > maxW then maxW = w end
            end
        end
        local iconW  = hasIcon    and (CTX_ICON_SZ + CTX_ICON_GAP) or 0
        local arrowW = hasSubmenu and CTX_ARROW_W                   or 0
        width = math.max(math.ceil(maxW) + CTX_PAD_H * 2 + iconW + arrowW, 100)
    end

    -- ── Height ───────────────────────────────────────────────────
    local totalH = 4   -- 2px inner padding top + bottom
    for _, item in ipairs(items) do
        if     item.type == "separator" then totalH = totalH + CTX_SEP_H
        elseif item.type == "label"     then totalH = totalH + CTX_LABEL_H
        else                                 totalH = totalH + CTX_ROW_H
        end
    end

    f:SetSize(width, totalH)

    -- ── Position with four-way edge-flip ─────────────────────────
    local screenW = GetScreenWidth()
    local flipX   = xNormal + width  > screenW
    local flipY   = yTop    - totalH < 0
    local anchorX = flipX and xFlip or xNormal
    local framePt = (flipY and "BOTTOM" or "TOP") .. (flipX and "RIGHT" or "LEFT")
    f:ClearAllPoints()
    f:SetPoint(framePt, UIParent, "BOTTOMLEFT", anchorX, yTop)

    -- ── Row pool helper ──────────────────────────────────────────
    local rowPool = f._rows
    local function GetRow(i)
        if rowPool[i] then return rowPool[i] end

        local row = CreateFrame("Button", nil, f)
        row:SetFrameLevel(baseLevel + 2)

        local hoverBg = CreateFrame("Frame", nil, row)
        hoverBg:SetAllPoints(row)
        hoverBg:SetFrameLevel(baseLevel + 3)
        hoverBg:EnableMouse(false)
        local ht = hoverBg:CreateTexture(nil, "BACKGROUND")
        ht:SetAllPoints()
        ht:SetColorTexture(unpack(STYLE.hover_color))
        hoverBg:SetAlpha(0)
        row.hoverBg = hoverBg

        local sepTex = row:CreateTexture(nil, "ARTWORK")
        sepTex:SetColorTexture(0, 1, 1, 0.15)
        sepTex:SetHeight(1)
        row.sepTex = sepTex

        local iconFrame = CreateFrame("Frame", nil, row)
        iconFrame:SetSize(CTX_ICON_SZ, CTX_ICON_SZ)
        iconFrame:SetFrameLevel(baseLevel + 4)
        iconFrame:EnableMouse(false)
        local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTex:SetAllPoints()
        row.iconFrame = iconFrame
        row.iconTex   = iconTex

        local labelFS = MakeFontString(row, 13)
        labelFS:SetJustifyH("LEFT")
        labelFS:SetJustifyV("MIDDLE")
        row.labelFS = labelFS

        local arrowTex = row:CreateTexture(nil, "ARTWORK")
        arrowTex:SetSize(8, 8)
        arrowTex:SetPoint("RIGHT", row, "RIGHT", -(CTX_PAD_H - 2), 0)
        arrowTex:SetTexture(ICON_PATH .. "chevron-right.png")
        arrowTex:SetVertexColor(0.6, 0.6, 0.6, 1)
        row.arrowTex = arrowTex

        rowPool[i] = row
        return row
    end

    -- ── Build rows ───────────────────────────────────────────────
    local curY     = -2
    local rowCount = 0

    for _, item in ipairs(items) do
        rowCount = rowCount + 1
        local row   = GetRow(rowCount)
        local itype = item.type

        row.hoverBg:SetAlpha(0)
        row.sepTex:Hide()
        row.iconFrame:Hide()
        row.arrowTex:Hide()
        row.labelFS:SetText("")
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
        row:SetScript("OnClick", nil)
        row:EnableMouse(false)

        if itype == "separator" then
            row:SetSize(width, CTX_SEP_H)
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 0, curY)
            row.sepTex:ClearAllPoints()
            row.sepTex:SetPoint("LEFT",  row, "LEFT",  CTX_PAD_H, 0)
            row.sepTex:SetPoint("RIGHT", row, "RIGHT", -CTX_PAD_H, 0)
            row.sepTex:Show()
            curY = curY - CTX_SEP_H

        elseif itype == "label" then
            row:SetSize(width, CTX_LABEL_H)
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 0, curY)
            row.labelFS:SetTextColor(0.55, 0.55, 0.55, 1)
            row.labelFS:SetText(item.text or "")
            row.labelFS:ClearAllPoints()
            row.labelFS:SetPoint("LEFT",  row, "LEFT",  CTX_PAD_H,  0)
            row.labelFS:SetPoint("RIGHT", row, "RIGHT", -CTX_PAD_H, 0)
            row.labelFS:SetHeight(CTX_LABEL_H)
            curY = curY - CTX_LABEL_H

        elseif itype == "button" or itype == "submenu" then
            row:SetSize(width, CTX_ROW_H)
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 0, curY)
            row:EnableMouse(true)

            local tex   = ResolveCtxIcon(item)
            local leftX = CTX_PAD_H
            if tex then
                row.iconTex:SetTexture(tex)
                row.iconFrame:ClearAllPoints()
                row.iconFrame:SetPoint("LEFT", row, "LEFT", CTX_PAD_H, 0)
                row.iconFrame:Show()
                leftX = CTX_PAD_H + CTX_ICON_SZ + CTX_ICON_GAP
            end

            local rightX = -CTX_PAD_H
            if itype == "submenu" then
                row.arrowTex:Show()
                rightX = -(CTX_PAD_H + CTX_ARROW_W - 4)
            end

            row.labelFS:SetTextColor(1, 1, 1, 1)
            row.labelFS:SetText(item.label or "")
            row.labelFS:ClearAllPoints()
            row.labelFS:SetPoint("LEFT",  row, "LEFT",  leftX,  0)
            row.labelFS:SetPoint("RIGHT", row, "RIGHT", rightX, 0)
            row.labelFS:SetHeight(CTX_ROW_H)

            if itype == "button" then
                row:SetScript("OnEnter", function()
                    HideCtxFromLevel(level + 1)
                    UIFrameFadeIn(row.hoverBg, STYLE.hover_in, row.hoverBg:GetAlpha(), 1)
                end)
                row:SetScript("OnLeave", function()
                    UIFrameFadeOut(row.hoverBg, STYLE.hover_out, row.hoverBg:GetAlpha(), 0)
                end)
                if item.fnc then
                    row:SetScript("OnClick", function()
                        HideCtxFromLevel(1)
                        item.fnc()
                    end)
                end
            else -- submenu
                local subItems = item.items or {}
                row:SetScript("OnEnter", function()
                    UIFrameFadeIn(row.hoverBg, STYLE.hover_in, row.hoverBg:GetAlpha(), 1)
                    row.arrowTex:SetVertexColor(0, 1, 1, 1)
                    local rRight = row:GetRight()
                    local rLeft  = row:GetLeft()
                    local rTop   = row:GetTop()
                    if rRight and rTop then
                        ShowContextAtLevel(subItems, level + 1, rRight + 2, rLeft - 2, rTop, nil)
                    end
                end)
                row:SetScript("OnLeave", function()
                    UIFrameFadeOut(row.hoverBg, STYLE.hover_out, row.hoverBg:GetAlpha(), 0)
                    row.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 1)
                end)
            end

            curY = curY - CTX_ROW_H
        end

        row:Show()
    end

    for i = rowCount + 1, #rowPool do rowPool[i]:Hide() end

    f:Show()
    if level == 1 then ctxClickaway:Show() end
end

local function ShowContextMenu(items, width)
    EnsureCtxClickaway()
    local scale  = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    local uiX    = cx / scale
    local uiY    = cy / scale
    ShowContextAtLevel(items, 1, uiX, uiX, uiY, width)
end

-- ============================================================
--  CreateLink
--
--  A button that opens a small copy-popup when clicked.
--  The popup contains the url pre-selected in a focused
--  EditBox; pressing Ctrl+C copies and closes the popup.
--  Escape or clicking outside also closes it.
--
--  Params
--    parent – WoW frame
--    label  – button display text
--    url    – text placed in the copy box
--    width  – number (nil = auto from label)
--    height – number (default 22)
--    name   – optional global frame name
--
--  Returned object – same interface as CreateButton
-- ============================================================
local LINK_POPUP_W = 300
local LINK_POPUP_H = 64
local LINK_PAD     = 8

local linkPopup

local function EnsureLinkPopup()
    if linkPopup then return end

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(LINK_POPUP_W, LINK_POPUP_H)
    f:SetFrameStrata("TOOLTIP")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    f:Hide()
    f:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
        tile     = true,
        tileSize = 64,
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    f:SetBackdropBorderColor(0, 1, 1, 0.7)

    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -LINK_PAD, -LINK_PAD)
    closeBtn:SetFrameLevel(f:GetFrameLevel() + 2)
    local closeText = MakeFontString(closeBtn, 12)
    closeText:SetText("x")
    closeText:SetTextColor(0.75, 0.75, 0.75, 1)
    closeText:SetJustifyH("CENTER")
    closeText:SetJustifyV("MIDDLE")
    closeText:SetAllPoints(closeBtn)
    closeBtn:SetScript("OnEnter", function()
        closeText:SetTextColor(1, 1, 1, 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeText:SetTextColor(0.75, 0.75, 0.75, 1)
    end)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Hint label
    local hint = MakeFontString(f, 11)
    hint:SetTextColor(0.45, 0.45, 0.45, 1)
    hint:SetText("Press Ctrl+C to copy")
    hint:SetJustifyH("LEFT")
    hint:SetPoint("TOPLEFT", f, "TOPLEFT", LINK_PAD, -LINK_PAD)

    -- Input frame (same dark-box + focus-border pattern as CreateTextEntry)
    local inputFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    inputFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     LINK_PAD,  -(LINK_PAD + 18 + 4))
    inputFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -LINK_PAD, LINK_PAD)
    inputFrame:SetFrameLevel(f:GetFrameLevel() + 1)
    MakeControlBackdrop(inputFrame)

    local focusBorder = CreateFrame("Frame", nil, inputFrame, "BackdropTemplate")
    focusBorder:SetAllPoints(inputFrame)
    focusBorder:SetFrameLevel(inputFrame:GetFrameLevel() + 1)
    focusBorder:EnableMouse(false)
    focusBorder:SetBackdrop({ edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    focusBorder:SetBackdropBorderColor(0, 1, 1, 0)

    local edit = CreateFrame("EditBox", nil, inputFrame)
    edit:SetPoint("TOPLEFT",     inputFrame, "TOPLEFT",     4, -2)
    edit:SetPoint("BOTTOMRIGHT", inputFrame, "BOTTOMRIGHT", -4,  2)
    edit:SetFont(ValidateFont(NSI:GetUIFontPath()), 12, NSI:GetUIFontFlags())
    edit:SetTextColor(1, 1, 1, 1)
    labelRegistry[#labelRegistry + 1] = {label = edit, size = 12}
    edit:SetAutoFocus(false)
    edit:SetMultiLine(false)
    edit:SetJustifyH("CENTER")
    edit:SetJustifyV("MIDDLE")
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(f._linkUrl or "")
            self:HighlightText()
        end
    end)

    edit:SetScript("OnEditFocusGained", function()
        edit:HighlightText()
        UIFrameFadeIn(focusBorder, STYLE.select_in, focusBorder:GetAlpha(), 1)
    end)
    edit:SetScript("OnEditFocusLost", function()
        UIFrameFadeOut(focusBorder, STYLE.deselect_out, focusBorder:GetAlpha(), 0)
        C_Timer.After(0, function()
            if f:IsShown() then
                edit:SetFocus()
                edit:HighlightText()
            end
        end)
    end)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    edit:SetScript("OnKeyDown", function(_, key)
        if key == "C" and IsControlKeyDown() then
            C_Timer.After(0, function() f:Hide() end)
        end
    end)

    linkPopup = { frame = f, edit = edit }
end

local function ShowLinkPopup(url, anchorFrame)
    EnsureLinkPopup()

    local f = linkPopup.frame
    f._linkUrl = url or ""
    linkPopup.edit:SetText(f._linkUrl)

    local anchor = (NSI.UI.Core and NSI.UI.Core.NSUI) or UIParent
    f:ClearAllPoints()
    f:SetPoint("CENTER", anchor, "CENTER")

    f:Show()
    linkPopup.edit:SetFocus()
    linkPopup.edit:HighlightText()
end

local function CreateLink(parent, label, url, width, height, name, tooltip)
    local btn
    btn = CreateButton(parent, label, function()
        ShowLinkPopup(url, btn.frame)
    end, width, height, name, nil, nil, tooltip)
    return btn
end

-- ============================================================
--  Export
-- ============================================================
NSI.UI = NSI.UI or {}
NSI.UI.Components = {
    CreateButton        = CreateButton,
    CreateSubButton     = CreateSubButton,
    CreateLocalizedButton = CreateLocalizedButton,
    CreateLocalizedSubButton = CreateLocalizedSubButton,
    RefreshLocalizedTexts = RefreshLocalizedTexts,
    RegisterLocalizedText = RegisterLocalizedText,
    CreateCheckButton   = CreateCheckButton,
    CreateTextEntry     = CreateTextEntry,
    CreateDropdown      = CreateDropdown,
    CreateSlider        = CreateSlider,
    CreateColorPicker   = CreateColorPicker,
    CreateLabel         = CreateLabel,
    CreateBreakline     = CreateBreakline,
    CreateScrollBox     = CreateScrollBox,
    ReskinScrollbar     = ReskinScrollbar,
    BuildWidgets        = BuildWidgets,
    RefreshFonts        = RefreshFonts,
    CreateDialog        = CreateDialog,
    CreateFrame         = CreateStyledFrame,
    ShowContextMenu     = ShowContextMenu,
    CreateLink          = CreateLink,
    STYLE               = STYLE,
    registry            = componentRegistry,
    Dialogs             = Dialogs,
}
