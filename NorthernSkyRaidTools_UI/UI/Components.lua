local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]

-- ============================================================
--  NSRT UI Components
--  Thin wrappers over raw WoW frames that enforce the Northern
--  Sky visual style without relying on DF templates.
--  Edit STYLE below to retheme the entire addon UI in one place.
-- ============================================================

local STYLE = {
    -- Brand accent (RGB). Change it only through STYLE.SetAccent so everything re-tints.
    accent = { 0, 1, 1 },

    -- Normal state
    bg_color       = { 0.3, 0.3, 0.3, 0.8 },
    -- Input control background (text entries, sliders, color pickers, checkboxes)
    input_bg_color = { 0.3, 0.3, 0.3, 0.9 },

    -- Hover overlay (fades in/out on mouse enter/leave); tinted by the accent
    hover_color     = {0,    1,    1,    0.13},

    -- Selected state (solid background); tinted by the accent
    selected_color  = {0,    1,    1,    0.20},

    -- Surfaces
    surface_panel      = { 0.05, 0.05, 0.08, 0.97 },  -- windows, popups, menus
    surface_inset      = { 0.04, 0.04, 0.04, 0.85 },  -- lists, edit areas
    surface_inset_soft = { 0.04, 0.04, 0.04, 0.60 },
    selected_fill      = { 0.05, 0.30, 0.40, 0.90 },  -- selected row / tab
    selected_row_alpha = 0.32,                        -- accent tint on a selected list row (keeps text and checkbox readable)
    row_stripe_dark    = { 0.08, 0.08, 0.08, 0.92 },  -- alternating rows in long lists
    row_stripe_light   = { 0.15, 0.15, 0.15, 0.92 },
    row_fill           = { 0.4, 0.4, 0.4, 0.5 },      -- list row
    row_dark           = { 0.02, 0.02, 0.02, 0.82 },  -- overlay / read-only cover
    row_plain          = { 0.1215, 0.1176, 0.1294, 0.8 },  -- editable row (inputs inside)
    border_subtle      = { 0.25, 0.25, 0.25, 1 },

    -- Text tiers
    text_color      = {1, 1, 1, 1},
    text_soft       = {0.8, 0.8, 0.8, 1},
    text_muted      = {0.6, 0.6, 0.6, 1},
    text_hint       = {0.5, 0.5, 0.5, 1},
    text_disabled   = {0.45, 0.45, 0.45, 0.70},
    text_gold       = {1, 0.82, 0, 1},
    text_danger     = {1, 0.35, 0.35, 1},
    danger          = {0.9, 0.3, 0.3, 1},
    success         = {0.2, 0.9, 0.3, 1},
    warning         = {1, 0.65, 0, 1},
    text_left_pad   = 10,

    -- Type scale in px. Use the names, not literal sizes: MakeFontString, CreateButton's
    -- textSize and NSI:SetUIFont all accept them, so one edit here retunes the whole UI.
    --   title  popup / section titles     body   control text (default)
    --   label  field labels, list rows    small  secondary text, inputs
    --   tiny   captions, hints, counts
    type = { title = 16, body = 14, label = 13, small = 12, tiny = 11 },

    -- Animation durations in seconds
    hover_in        = 0.12,
    hover_out       = 0.20,
    select_in       = 0.10,
    deselect_out    = 0.15,
}

-- ---- accent registry ---------------------------------------
--  Accent(a)                  r, g, b, a  using the current accent
--  PaintAccent(obj, "SetX", a) paints now and again whenever the accent changes
--  SetAccent(r, g, b)         retheme; OnAccentChanged(fn) for custom drawing
local accentPainted   = setmetatable({}, { __mode = "k" })
local accentListeners = {}

function STYLE.Accent(alpha)
    local c = STYLE.accent
    return c[1], c[2], c[3], alpha or 1
end

function STYLE.PaintAccent(obj, method, alpha)
    obj[method](obj, STYLE.Accent(alpha))
    local methods = accentPainted[obj]
    if not methods then methods = {}; accentPainted[obj] = methods end
    methods[method] = alpha
    return obj
end

-- A type-scale name ("small") or a number -> a size in px. nil stays nil.
function STYLE.FontSize(size)
    if type(size) == "string" then return STYLE.type[size] or STYLE.type.small end
    return size
end

function STYLE.OnAccentChanged(fn)
    accentListeners[#accentListeners + 1] = fn
end

function STYLE.SetAccent(r, g, b)
    local c = STYLE.accent
    c[1], c[2], c[3] = r, g, b
    for _, token in ipairs({ STYLE.hover_color, STYLE.selected_color }) do
        token[1], token[2], token[3] = r, g, b
    end
    for obj, methods in pairs(accentPainted) do
        for method, alpha in pairs(methods) do obj[method](obj, r, g, b, alpha or 1) end
    end
    for _, fn in ipairs(accentListeners) do fn(r, g, b) end
end

STYLE.text_size = STYLE.type.body   -- default control text

NSI.UI = NSI.UI or {}
NSI.UI.Style = STYLE
local Accent, PaintAccent = STYLE.Accent, STYLE.PaintAccent

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
-- All registries are weak-keyed so they never keep a dead widget's table alive:
-- label -> font size (plain number, so no value can reference its own key).
local WEAK_KEYS = { __mode = "k" }
local labelRegistry = setmetatable({}, WEAK_KEYS)
local localizedTextRegistry = setmetatable({}, WEAK_KEYS)

-- Component objects, one weak set per type: registry[Type][obj] = true.
local componentRegistry = {
    Slider    = setmetatable({}, WEAK_KEYS),
    Dropdown  = setmetatable({}, WEAK_KEYS),
    Color     = setmetatable({}, WEAK_KEYS),
    Checkbox  = setmetatable({}, WEAK_KEYS),
    TextEntry = setmetatable({}, WEAK_KEYS),
    Label     = setmetatable({}, WEAK_KEYS),
    Breakline = setmetatable({}, WEAK_KEYS),
}

local function ValidateFont(path)
    return NSI:ValidateFontPath(path)
end

local function RefreshFonts()
    local fontPath = ValidateFont(NSI:GetUIFontPath())
    local fontFlags = NSI:GetWindowFontFlags()
    for label, size in pairs(labelRegistry) do
        label:SetFont(fontPath, size, fontFlags)
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
    NSI.UI.Tooltip.Show(frame, tooltip, anchor)
end

local function HideTooltip(tooltip)
    if tooltip then NSI.UI.Tooltip.Hide() end
end

local function CreateButton(parent, text, onClick, width, height, name, icon, textSize, tooltip, condition)
    -- ---- base frame -------------------------------------------
    -- Width is resolved after measuring the label; start with a stub size.
    local btn = NSI.UI.Pixel.CreateBoxFrame("Button", name, parent)
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
    local labelSize = STYLE.FontSize(textSize) or STYLE.text_size
    label:SetFont(ValidateFont(NSI:GetUIFontPath()), labelSize, NSI:GetWindowFontFlags())
    label:SetTextColor(unpack(STYLE.text_color))
    label:SetText(text or "")
    label:SetJustifyV("MIDDLE")
    label:SetJustifyH("CENTER")
    label:SetAllPoints(labelFrame)
    labelRegistry[label] = labelSize

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
        iconTex:SetTexCoord(0.12, 0.88, 0.11, 0.89)
        iconTex:SetVertexColor(unpack(STYLE.text_color))
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
        self.label:SetFont(path, STYLE.FontSize(size) or STYLE.text_size, flags or "")
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
            self.frame.icon:SetVertexColor(unpack(STYLE.text_color))
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
    size = STYLE.FontSize(size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ValidateFont(NSI:GetUIFontPath()), size, NSI:GetWindowFontFlags())
    fs:SetTextColor(unpack(STYLE.text_color))
    labelRegistry[fs] = size
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
--    :Enable()
--    :Disable()       also dims label and box, blocks toggling
--    :IsEnabled() → bool
-- ============================================================
local function CreateCheckButton(parent, label, getValue, setValue, width, height, name, tooltip, icon, iconSize)
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
    local box = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, btn)
    box:SetSize(BOX, BOX)
    box:SetPoint("LEFT", btn, "LEFT", 0, 0)
    box:SetFrameLevel(baseLevel + 1)
    box:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    box:SetBackdropColor(unpack(STYLE.bg_color))
    box:SetBackdropBorderColor(unpack(STYLE.border_subtle))

    -- Cyan fill shown when checked
    local checkFill = box:CreateTexture(nil, "ARTWORK")
    checkFill:SetPoint("TOPLEFT",     box, "TOPLEFT",     2, -2)
    checkFill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -2,  2)
    PaintAccent(checkFill, "SetColorTexture", 0.85)
    checkFill:Hide()

    -- Hover overlay on the whole row (same fade pattern as CreateButton)
    local hoverBg = MakeHoverBg(btn, baseLevel + 1)

    -- Label
    local lbl = MakeFontString(btn, "label")
    lbl:SetText(label or "")
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetPoint("LEFT",  box, "RIGHT",   GAP, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT",   0,   0)
    lbl:SetHeight(totalH)

    -- Optional icon between the box and the label (a texture file ID or path)
    if icon then
        local size = iconSize or 16
        local iconTex = btn:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(size, size)
        iconTex:SetPoint("LEFT", box, "RIGHT", GAP, 0)
        iconTex:SetTexture(icon)
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        lbl:ClearAllPoints()
        lbl:SetPoint("LEFT",  iconTex, "RIGHT", GAP, 0)
        lbl:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
        lbl:SetHeight(totalH)
    end

    local isChecked  = getValue and getValue(NSI) or false
    local isDisabled = false

    local function Refresh()
        if isChecked then
            checkFill:Show()
            if isDisabled then
                checkFill:SetColorTexture(0.45, 0.45, 0.45, 0.6)
                box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            else
                checkFill:SetColorTexture(Accent(0.85))
                box:SetBackdropBorderColor(Accent(0.9))
            end
        else
            checkFill:Hide()
            box:SetBackdropBorderColor(unpack(STYLE.border_subtle))
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

    function obj:Enable()
        isDisabled = false
        btn:Enable()
        lbl:SetTextColor(unpack(STYLE.text_color))
        Refresh()
    end

    function obj:Disable()
        isDisabled = true
        btn:Disable()
        lbl:SetTextColor(unpack(STYLE.text_disabled))
        Refresh()
    end

    function obj:IsEnabled() return not isDisabled end

    componentRegistry.Checkbox[obj] = true
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
--    :Enable()
--    :Disable()   also dims label/text and blocks editing
--    :IsEnabled() → bool
-- ============================================================
local function CreateTextEntry(parent, label, getValue, setValue,
                               width, height, numeric, minVal, maxVal, name, tooltip, inputWidth, hooks, labelWidth)
    local totalW    = width or 220
    local totalH    = height or 22
    local BOX_W     = labelWidth and (totalW - 8 - labelWidth) or inputWidth or 60
    local GAP       = 8
    local MIN_BOX_W = 90
    local fitInput  = inputWidth ~= nil and not labelWidth   -- inputWidth is then a maximum, shrunk so the label fits
    local hasLabel  = label and label ~= ""
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    -- Label (only when provided; omitting it makes the input span the full width)
    local lbl
    if hasLabel then
        lbl = MakeFontString(container, "label")
        lbl:SetText(label)
        lbl:SetJustifyH("LEFT")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetPoint("LEFT", container, "LEFT", 0, 0)
        lbl:SetPoint("RIGHT", container, "RIGHT", -(BOX_W + GAP), 0)
        lbl:SetHeight(totalH)
    end

    local inputW = hasLabel and BOX_W or totalW

    -- Input frame (backdrop + EditBox stacked inside)
    local inputFrame = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, container)
    inputFrame:SetSize(inputW, totalH)
    if hasLabel then
        inputFrame:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    else
        inputFrame:SetPoint("LEFT", container, "LEFT", 0, 0)
        inputFrame:SetPoint("RIGHT", container, "RIGHT", 0, 0)   -- follows the container when it is resized
    end
    inputFrame:SetFrameLevel(baseLevel + 1)
    MakeControlBackdrop(inputFrame)

    -- Cyan-border overlay when focused (same layer trick as hoverBg)
    local focusBorder = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, inputFrame)
    focusBorder:SetAllPoints(inputFrame)
    focusBorder:SetFrameLevel(baseLevel + 2)
    focusBorder:EnableMouse(false)
    focusBorder:SetBackdrop({
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    focusBorder:SetBackdropBorderColor(Accent(0))   -- hidden until focused

    local edit = CreateFrame("EditBox", nil, inputFrame)
    edit:SetPoint("TOPLEFT",     inputFrame, "TOPLEFT",     4,  -2)
    edit:SetPoint("BOTTOMRIGHT", inputFrame, "BOTTOMRIGHT", -4,  2)
    edit:SetFont(ValidateFont(NSI:GetUIFontPath()), STYLE.type.small, NSI:GetWindowFontFlags())
    edit:SetTextColor(unpack(STYLE.text_color))
    labelRegistry[edit] = 12
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

    edit:SetScript("OnEnterPressed", function() edit:ClearFocus() end)
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
    -- Extra script hooks ({ OnEnterPressed = fn, ... }) run after the built-in handlers,
    -- so the value has already been committed when they fire.
    if hooks then
        for scriptName, fn in pairs(hooks) do edit:HookScript(scriptName, fn) end
    end

    local obj = {frame = container, editBox = edit, label = lbl}

    -- Give the label the room it needs and the input the rest (between MIN_BOX_W and
    -- the requested width), so neither is cut off inside the available row.
    local function FitInput()
        if not (hasLabel and fitInput) then return end
        local labelW = math.ceil(lbl:GetStringWidth() or 0) + 2
        local box = math.max(MIN_BOX_W, math.min(inputWidth, totalW - GAP - labelW))
        box = math.min(box, totalW - GAP - 40)
        BOX_W = box
        lbl:ClearAllPoints()
        lbl:SetPoint("LEFT",  container, "LEFT",  0, 0)
        lbl:SetPoint("RIGHT", container, "RIGHT", -(box + GAP), 0)
        lbl:SetHeight(totalH)
        inputFrame:SetWidth(box)
    end
    FitInput()

    function obj:SetValue(v)   edit:SetText(tostring(v))                                    end
    function obj:GetValue()    return numeric and tonumber(edit:GetText()) or edit:GetText() end
    function obj:SetPoint(...) self.frame:SetPoint(...)                                      end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)                                     end
    function obj:GetWidth()    return self.frame:GetWidth()                                  end
    function obj:SetLocaleKey(key)
        if self.label then RegisterLocalizedText(self.label, key) end
        FitInput()
    end

    function obj:Enable()
        self._disabled = false
        edit:SetEnabled(true)
        edit:EnableMouse(true)
        edit:SetTextColor(unpack(STYLE.text_color))
        if lbl then lbl:SetTextColor(unpack(STYLE.text_color)) end
        MakeControlBackdrop(inputFrame)
    end

    function obj:Disable()
        self._disabled = true
        edit:ClearFocus()
        edit:SetEnabled(false)
        edit:EnableMouse(false)
        edit:SetTextColor(unpack(STYLE.text_disabled))
        if lbl then lbl:SetTextColor(unpack(STYLE.text_disabled)) end
        inputFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
    end

    function obj:IsEnabled() return not self._disabled end

    componentRegistry.TextEntry[obj] = true
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
--    :Enable()
--    :Disable()   also dims label/value and closes the popup if open
--    :IsEnabled() → bool
-- ============================================================
local function CreateDropdown(parent, label, getItems, getSelected, width, height, name, tooltip, maxRows, highlighted, searchable, labelWidth)
    local totalW   = width  or 220
    local totalH   = height or 22
    local ROW_H    = 20
    local MAX_ROWS = maxRows or 11
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    local hasLabel = label and label ~= ""
    local labelW   = hasLabel and (labelWidth or math.floor(totalW * 0.5)) or 0
    local dropW    = totalW - labelW - (hasLabel and 8 or 0)

    -- Optional label
    local lbl
    if hasLabel then
        lbl = MakeFontString(container, highlighted and "body" or "label")
        if highlighted then
            lbl:SetTextColor(unpack(STYLE.text_gold))
        end
        lbl:SetText(label)
        lbl:SetJustifyH("LEFT")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetPoint("LEFT", container, "LEFT", 0, 0)
        lbl:SetWidth(labelW)
        lbl:SetHeight(totalH)
    end

    -- Dropdown button — same backdrop & hover pattern as CreateButton
    local dropBtn = NSI.UI.Pixel.CreateBoxFrame("Button", nil, container)
    dropBtn:SetSize(dropW, totalH)
    dropBtn:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    dropBtn:SetFrameLevel(baseLevel + 1)
    MakeControlBackdrop(dropBtn)

    local dropHover = MakeHoverBg(dropBtn, baseLevel + 2)

    -- Current-value text
    local valText = MakeFontString(dropBtn, "small")
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
    local popup = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("TOOLTIP")
    popup:Hide()
    popup:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    popup:SetBackdropColor(unpack(STYLE.surface_panel))
    PaintAccent(popup, "SetBackdropBorderColor", 0.7)

    -- Optional search box pinned to the top of the popup
    local SEARCH_H = 20
    local searchBox
    if searchable then
        searchBox = NSI.UI.Pixel.CreateBoxFrame("EditBox", nil, popup)
        searchBox:SetHeight(SEARCH_H)
        searchBox:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -2)
        searchBox:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -2)
        MakeControlBackdrop(searchBox)
        searchBox:SetAutoFocus(false)
        searchBox:SetFont(ValidateFont(NSI:GetUIFontPath()), STYLE.type.small, NSI:GetWindowFontFlags())
        searchBox:SetTextColor(unpack(STYLE.text_color))
        searchBox:SetTextInsets(6, 6, 0, 0)
        searchBox:SetMaxLetters(100)
        labelRegistry[searchBox] = 12
    end

    -- Scrollbar track (right strip inside popup)
    local sbTrack = popup:CreateTexture(nil, "BACKGROUND")
    sbTrack:SetColorTexture(0.10, 0.10, 0.10, 1)
    if searchable then
        sbTrack:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", 0, -1)
    else
        sbTrack:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -2)
    end
    sbTrack:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -2,  2)
    sbTrack:SetWidth(SB_W)
    sbTrack:Hide()

    -- Scrollbar thumb
    local sbThumb = CreateFrame("Frame", nil, popup)
    sbThumb:SetWidth(SB_W)
    sbThumb:SetFrameLevel(popup:GetFrameLevel() + 5)
    local sbTex = sbThumb:CreateTexture(nil, "OVERLAY")
    sbTex:SetAllPoints(sbThumb)
    PaintAccent(sbTex, "SetColorTexture", 0.45)
    sbThumb:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, popup)
    if searchable then
        scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -1)
    else
        scrollFrame:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -2)
    end
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

    local selectedFont = nil

    local function RefreshDisplay()
        if getSelected then
            local v = getSelected()
            valText:SetText(v ~= nil and tostring(v) or "")
            local _, size, flags = valText:GetFont()
            valText:SetFont(selectedFont or ValidateFont(NSI:GetUIFontPath()), size, flags)
        end
    end

    local function Close()
        popup:Hide()
        clickaway:Hide()
        if searchBox then
            searchBox:SetText("")
            searchBox:ClearFocus()
        end
    end

    local function GetOwningScrollFrame()
        local frame = container:GetParent()
        while frame do
            if frame.IsObjectType and frame:IsObjectType("ScrollFrame") then
                return frame
            end
            frame = frame:GetParent()
        end
    end

    popup:SetScript("OnUpdate", function()
        if not popup:IsShown() then return end
        local scrollFrame = GetOwningScrollFrame()
        if not scrollFrame then return end

        local buttonTop, buttonBottom = dropBtn:GetTop(), dropBtn:GetBottom()
        local viewportTop, viewportBottom = scrollFrame:GetTop(), scrollFrame:GetBottom()
        if not buttonTop or not buttonBottom or not viewportTop or not viewportBottom
            or buttonBottom >= viewportTop or buttonTop <= viewportBottom then
            Close()
        end
    end)

    container:SetScript("OnHide", Close)

    local allItems = {}

    local function FilterItems(list, query)
        if not query or query == "" then return list end
        local q = query:lower()
        local filtered = {}
        for _, item in ipairs(list) do
            local label = item.label and tostring(item.label):lower() or ""
            if label:find(q, 1, true) then
                filtered[#filtered + 1] = item
            end
        end
        return filtered
    end

    local noResultsLabel
    if searchable then
        noResultsLabel = MakeFontString(content, "small")
        noResultsLabel:SetText("No matches")
        noResultsLabel:SetTextColor(unpack(STYLE.text_muted))
        noResultsLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 6, 0)
        noResultsLabel:Hide()
    end

    local function Render(items)
        local rowCount = #items

        local needsScroll = rowCount > MAX_ROWS
        local popupH = math.min(math.max(rowCount, 1) * ROW_H, MAX_ROWS * ROW_H)
        if searchable then popupH = popupH + SEARCH_H + 1 end
        -- The popup is parented to UIParent while its selector may be inside
        -- a scaled NSUI frame, so convert the dropdown width to UIParent's
        -- coordinate scale before sizing the popup and its rows.
        local popupW = dropW * dropBtn:GetEffectiveScale() / UIParent:GetEffectiveScale()
        popup:SetSize(popupW, popupH)
        local contentW = popupW - 4 - (needsScroll and SB_W + 1 or 0)
        content:SetSize(contentW, math.max(rowCount, 1) * ROW_H)
        if needsScroll then sbTrack:Show() sbThumb:Show() else sbTrack:Hide() sbThumb:Hide() end
        if noResultsLabel then noResultsLabel:SetShown(rowCount == 0) end

        -- Grow the row pool as needed (frames are never destroyed)
        for i = #content._rows + 1, rowCount do
            local row = CreateFrame("Button", nil, content)
            row:SetSize(popupW - 4, ROW_H)

            local rowHover = MakeHoverBg(row, 2)

            local iconTex = row:CreateTexture(nil, "ARTWORK")

            iconTex:SetPoint("LEFT", row, "LEFT", 4, 0)
            iconTex:Hide()
            local rlbl = MakeFontString(row, "small")
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
            local _, size, flags = row.rlbl:GetFont()
            row.rlbl:SetFont(item.font or ValidateFont(NSI:GetUIFontPath()), size, flags)
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
                selectedFont = item.font
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
    end

    local function Open()
        allItems = getItems and getItems() or {}
        if #allItems == 0 then return end

        if searchBox then searchBox:SetText("") end
        Render(allItems)

        popup:Show()
        clickaway:Show()
        if searchBox then searchBox:SetFocus() end
    end

    if searchBox then
        searchBox:SetScript("OnTextChanged", function(self)
            Render(FilterItems(allItems, self:GetText()))
        end)
        searchBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            Close()
        end)
        searchBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
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

    function obj:Enable()
        self._disabled = false
        dropBtn:Enable()
        valText:SetTextColor(unpack(STYLE.text_color))
        arrowTexture:SetVertexColor(unpack(STYLE.text_color))
        if lbl then
            if highlighted then lbl:SetTextColor(unpack(STYLE.text_gold)) else lbl:SetTextColor(unpack(STYLE.text_color)) end
        end
    end

    function obj:Disable()
        self._disabled = true
        Close()
        dropBtn:Disable()
        valText:SetTextColor(unpack(STYLE.text_disabled))
        arrowTexture:SetVertexColor(unpack(STYLE.text_disabled))
        if lbl then lbl:SetTextColor(unpack(STYLE.text_disabled)) end
    end

    function obj:IsEnabled() return not self._disabled end

    componentRegistry.Dropdown[obj] = true
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
--    :Enable()
--    :Disable()   also dims label/track/thumb and blocks dragging
--    :IsEnabled() → bool
-- ============================================================
local function CreateSlider(parent, label, getValue, setValue,
                            width, height, minVal, maxVal, step, name, tooltip, liveDrag, decimals, useDecimals, labelWidth)
    local totalW  = width  or 220
    local totalH  = height or 22
    local LABEL_W = labelWidth or math.floor(totalW * 0.38)
    local VAL_W   = 38
    local TRACK_W = totalW - LABEL_W - VAL_W - 8
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    -- Label
    local lbl = MakeFontString(container, "label")
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
    PaintAccent(fillTex, "SetColorTexture", 0.45)
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
    PaintAccent(thumb, "SetVertexColor", 1)

    -- Value text (right side)
    local valText = MakeFontString(container, "tiny")
    valText:SetTextColor(unpack(STYLE.text_color))
    valText:SetJustifyH("CENTER")
    valText:SetJustifyV("MIDDLE")
    valText:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    valText:SetWidth(VAL_W)
    valText:SetHeight(totalH)

    local valueBorder = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, container)
    valueBorder:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    valueBorder:SetSize(VAL_W, totalH)
    valueBorder:SetFrameLevel(baseLevel + 1)
    valueBorder:SetBackdrop({ edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    PaintAccent(valueBorder, "SetBackdropBorderColor", 0.45)
    valueBorder:EnableMouse(false)

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
        thumb:SetVertexColor(Accent(1))
        HideTooltip(tooltip)
    end)
    local function RefreshThumb()
        C_Timer.After(0, function()
            slider:SetThumbTexture([[Interface\Buttons\WHITE8x8]])
            thumb = slider:GetThumbTexture()
            thumb:SetSize(8, 14)
            thumb:SetVertexColor(Accent(1))
        end)
    end
    slider:HookScript("OnShow", RefreshThumb)

    local initVal = (getValue and getValue(NSI)) or (minVal or 0)
    local mn, mx = minVal or 0, maxVal or 100
    if type(initVal) ~= "number" or initVal ~= initVal or initVal == math.huge or initVal == -math.huge then
        initVal = mn
    end
    initVal = math.max(mn, math.min(mx, initVal))
    slider:SetValue(initVal)
    RefreshThumb()
    UpdateVisual(initVal)
    initialized = true

    -- The displayed value is also the manual input affordance.
    local valBtn = CreateFrame("Button", nil, container)
    valBtn:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    valBtn:SetSize(VAL_W, totalH)
    valBtn:SetFrameLevel(baseLevel + 4)
    valBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    valBtn:SetScript("OnEnter", function()
        valueBorder:SetBackdropBorderColor(Accent(1))
    end)
    valBtn:SetScript("OnLeave", function()
        valueBorder:SetBackdropBorderColor(Accent(0.45))
    end)

    local typeBox = NSI.UI.Pixel.CreateBoxFrame("EditBox", nil, container)
    typeBox:SetSize(VAL_W, totalH - 4)
    typeBox:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    typeBox:SetFrameLevel(baseLevel + 5)
    typeBox:SetAutoFocus(false)
    typeBox:SetNumeric(false)
    typeBox:SetMaxLetters(10)
    typeBox:SetFont(ValidateFont(NSI:GetFallbackUIFontPath()), STYLE.type.tiny, "")
    PaintAccent(typeBox, "SetTextColor", 1)
    typeBox:SetJustifyH("CENTER")
    typeBox:SetBackdrop({bgFile=[[Interface\Buttons\WHITE8x8]], edgeFile=[[Interface\Buttons\WHITE8x8]], edgeSize=1})
    typeBox:SetBackdropColor(0.04, 0.04, 0.06, 1)
    PaintAccent(typeBox, "SetBackdropBorderColor", 0.8)
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

    function obj:Enable()
        self._disabled = false
        slider:Enable()
        slider:EnableMouse(true)
        valBtn:EnableMouse(true)
        lbl:SetTextColor(unpack(STYLE.text_color))
        valText:SetTextColor(unpack(STYLE.text_color))
        valueBorder:SetBackdropBorderColor(Accent(0.45))
        thumb:SetVertexColor(Accent(1))
        fillTex:SetColorTexture(Accent(0.45))
    end

    function obj:Disable()
        self._disabled = true
        slider:Disable()
        slider:EnableMouse(false)
        valBtn:EnableMouse(false)
        typeBox:ClearFocus()
        typeBox:Hide()
        valText:Show()
        lbl:SetTextColor(unpack(STYLE.text_disabled))
        valText:SetTextColor(unpack(STYLE.text_disabled))
        valueBorder:SetBackdropBorderColor(unpack(STYLE.text_disabled))
        thumb:SetVertexColor(unpack(STYLE.text_disabled))
        fillTex:SetColorTexture(unpack(STYLE.text_disabled))
    end

    function obj:IsEnabled() return not self._disabled end

    componentRegistry.Slider[obj] = true
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
--    :Enable()
--    :Disable()   also dims label/swatch and blocks opening the picker
--    :IsEnabled() → bool
-- ============================================================
local function CreateColorPicker(parent, label, getValue, setValue, width, height, name, tooltip, labelWidth)
    local totalW   = width  or 220
    local totalH   = height or 22
    local SWATCH_W = 40
    local GAP      = 8
    local baseLevel = parent:GetFrameLevel() + 1

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)
    container:SetFrameLevel(baseLevel)

    -- Label
    local lbl = MakeFontString(container, "label")
    lbl:SetText(label or "")
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetPoint("LEFT",  container, "LEFT",  0,                 0)
    lbl:SetPoint("RIGHT", container, "RIGHT", -(SWATCH_W + GAP), 0)
    lbl:SetHeight(totalH)

    -- Swatch button (same backdrop pattern as CreateButton)
    local swatchBtn = NSI.UI.Pixel.CreateBoxFrame("Button", nil, container)
    swatchBtn:SetSize(SWATCH_W, totalH)
    if labelWidth then
        -- Label takes the shared label column; the swatch stays right-aligned so its
        -- right edge lines up with the other inputs.
        lbl:ClearAllPoints()
        lbl:SetPoint("LEFT", container, "LEFT", 0, 0)
        lbl:SetWidth(labelWidth)
        lbl:SetHeight(totalH)
    end
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

    function obj:Enable()
        self._disabled = false
        swatchBtn:Enable()
        lbl:SetTextColor(unpack(STYLE.text_color))
        colorTex:SetVertexColor(unpack(STYLE.text_color))
        UpdateSwatch()
    end

    function obj:Disable()
        self._disabled = true
        swatchBtn:Disable()
        lbl:SetTextColor(unpack(STYLE.text_disabled))
        colorTex:SetVertexColor(unpack(STYLE.text_disabled))
    end

    function obj:IsEnabled() return not self._disabled end

    componentRegistry.Color[obj] = true
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
local function CreateLabel(parent, text, width, height, name, highlighted, textColor)
    local totalW = width  or 220
    local totalH = height or 16

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(totalW, totalH)

    local lbl = MakeFontString(container, highlighted and "body" or "small")
    if highlighted then
        lbl:SetTextColor(Accent(1))
    elseif textColor then
        lbl:SetTextColor(unpack(textColor))
    else
        lbl:SetTextColor(unpack(STYLE.text_muted))
    end
    lbl:SetText(text or "")
    lbl:SetWordWrap(true)
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

    componentRegistry.Label[obj] = true
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
    PaintAccent(line, "SetColorTexture", 0.12)
    line:SetHeight(1)
    line:SetPoint("LEFT",  container, "LEFT",  0, 0)
    line:SetPoint("RIGHT", container, "RIGHT", 0, 0)

    local obj = {frame = container}

    function obj:SetPoint(...) self.frame:SetPoint(...)     end
    function obj:SetSize(w,h)  self.frame:SetSize(w, h)    end
    function obj:GetWidth()    return self.frame:GetWidth() end

    componentRegistry.Breakline[obj] = true
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
    icon:SetVertexColor(unpack(STYLE.text_soft))

    btn:SetScript("OnEnter", function()
        UIFrameFadeIn(hoverBg, STYLE.hover_in, hoverBg:GetAlpha(), 1)
        icon:SetVertexColor(Accent(1))
    end)
    btn:SetScript("OnLeave", function()
        UIFrameFadeOut(hoverBg, STYLE.hover_out, hoverBg:GetAlpha(), 0)
        icon:SetVertexColor(unpack(STYLE.text_soft))
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
            thumb:SetColorTexture(Accent(0.45))
            thumb:SetWidth(6)
        end
    end

    -- Chevron arrow buttons
    StyleArrowButton(_G[name .. "ScrollBarScrollUpButton"], "chevron-up.png")
    StyleArrowButton(_G[name .. "ScrollBarScrollDownButton"], "chevron-down.png")
end
-- Eased mouse-wheel scrolling for any UIPanelScrollFrameTemplate frame (CreateScrollBox uses it,
-- and so do the hand-built list scrolls).
local function EnableSmoothScroll(scrollFrame)
    scrollFrame:EnableMouseWheel(true)
    -- Eased wheel scrolling: each notch moves a target, and the bar glides toward it.
    -- The OnUpdate only exists while the glide runs. If the bar was moved by anything
    -- else (dragging it, ScrollToFrame, a rebuild), the next notch starts from where
    -- it actually is.
    local function GetBar() return scrollFrame.ScrollBar or _G[(scrollFrame:GetName() or "") .. "ScrollBar"] end
    local WHEEL_STEP, EASE, SETTLE = 40, 18, 0.5
    local glideTarget, lastSet
    local function StopGlide()
        glideTarget, lastSet = nil, nil
        scrollFrame:SetScript("OnUpdate", nil)
    end
    local function Glide(_, elapsed)
        local bar = GetBar()
        if not bar or not glideTarget then return StopGlide() end
        local cur = bar:GetValue()
        if lastSet and math.abs(cur - lastSet) > 0.01 then return StopGlide() end   -- moved elsewhere
        local nextValue = cur + (glideTarget - cur) * math.min(1, elapsed * EASE)
        if math.abs(glideTarget - nextValue) <= SETTLE then
            bar:SetValue(glideTarget)
            return StopGlide()
        end
        bar:SetValue(nextValue)
        lastSet = bar:GetValue()
        if lastSet == cur then                      -- bar rounded the step away: finish
            bar:SetValue(glideTarget)
            return StopGlide()
        end
    end
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local bar = GetBar()
        if not bar then return end
        local mn, mx = bar:GetMinMaxValues()
        local cur = bar:GetValue()
        if not glideTarget or (lastSet and math.abs(cur - lastSet) > 0.01) then glideTarget = cur end
        glideTarget = math.max(mn, math.min(mx, glideTarget - delta * WHEEL_STEP))
        lastSet = cur
        scrollFrame:SetScript("OnUpdate", Glide)
    end)
    scrollFrame:HookScript("OnHide", StopGlide)
end

local scrollBoxCounter = 0
local SB_W = 16 -- native UIPanelScrollFrameTemplate scrollbar width

local function CreateScrollBox(parent, width, height)
    scrollBoxCounter = scrollBoxCounter + 1
    local boxName = "NSRTScrollBox" .. scrollBoxCounter

    local scrollFrame = CreateFrame("ScrollFrame", boxName, parent,
        "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(width, height)
    EnableSmoothScroll(scrollFrame)

    local child = CreateFrame("Frame", boxName .. "Child", scrollFrame)
    child:SetWidth(width - SB_W - 2)
    child:SetHeight(1)
    scrollFrame:SetScrollChild(child)
    local scrollBar = _G[boxName .. "ScrollBar"]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -16)
        scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 16)
    end
    ReskinScrollbar(scrollFrame)

    local obj = { frame = scrollFrame, scrollChild = child }

    function obj:SetPoint(...) self.frame:SetPoint(...) end

    function obj:SetSize(w, h) self.frame:SetSize(w, h) end

    function obj:GetWidth() return self.frame:GetWidth() end

    function obj:UpdateScrollBar()
        local bar = _G[boxName .. "ScrollBar"]
        if not bar then return end
        local maxScroll = math.max(0, self.scrollChild:GetHeight() - scrollFrame:GetHeight())
        bar:SetMinMaxValues(0, maxScroll)
        if bar:GetValue() > maxScroll then bar:SetValue(0) end

    end

    -- Scroll so `target` (any frame inside the scroll child) is in view, with a little
    -- room above it. Does nothing when it is already fully visible. Call it once the
    -- layout has resolved (a frame shown this very frame has no rectangle yet).
    function obj:ScrollToFrame(target, topMargin)
        local bar = _G[boxName .. "ScrollBar"]
        local top, bottom = target:GetTop(), target:GetBottom()
        local viewTop, viewBottom = scrollFrame:GetTop(), scrollFrame:GetBottom()
        local childTop = self.scrollChild:GetTop()
        if not (bar and top and bottom and viewTop and viewBottom and childTop) then return end
        if top <= viewTop and bottom >= viewBottom then return end
        local minV, maxV = bar:GetMinMaxValues()
        bar:SetValue(math.max(minV, math.min(maxV, childTop - top - (topMargin or 40))))
    end
    return obj
end

-- ============================================================
--  BuildWidgets / CreateWidgetHost
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
--    {Type="Custom",    build=fn, cacheId=s, refresh=fn}
--       build(parent, width) → frame, height
--       cacheId / refresh only matter to a WidgetHost, see below.
--
--    "Scale" is accepted as an alias for "Slider".
--    Any descriptor may include height=n to override the default row height.
--
--  BuildWidgets(parent, definitions, width) builds the widgets once
--  and returns the height. Use it for panels whose definitions never
--  change. (A trailing namePrefix argument is still accepted and
--  ignored: widgets no longer get generated global names.)
--
--  CreateWidgetHost(parent, width) is for panels whose definitions
--  change while the window is open (selecting another entry, switching
--  tabs, filtering). Frames are never freed in WoW, so rebuilding on
--  every change leaks. A host builds each distinct widget layout once,
--  caches it, and on every later Apply re-binds the cached widgets to
--  the new descriptors (callbacks, label text, dropdown values) and
--  refreshes their displayed values in place.
--
--    host = C.CreateWidgetHost(scrollChild, width)
--    height = host:Apply(definitions [, isVisible(def, index)])
--
--  Two descriptor lists share a cached layout when their widgets
--  have the same types and the same static fields (height, min, max,
--  step, decimals, tooltip, ...). Label text, get/set, dropdown values
--  and button functions may differ freely; they are re-bound.
--  isVisible hides descriptors without rebuilding (live search).
--
--  Custom descriptors are matched by cacheId, or by their build function
--  when there is none. A descriptor table that is created once and reused
--  (static content) therefore caches by itself. One that is created fresh
--  on every call (a new closure each time) MUST set cacheId or it is
--  rebuilt on every Apply, which leaks. On a cache hit the host calls
--  def.refresh(frame, width) from the NEW descriptor so the widget can
--  re-point itself at the new data; it returns the new height.
-- ============================================================
local WIDGET_H = {
    Slider    = 22, Scale     = 22,
    Dropdown  = 22, Color     = 22,
    Checkbox  = 22, TextEntry = 22,
    Label     = 16, Breakline = 10,
    Link      = 22,
}
local WIDGET_GAP = 4

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

-- ---- signature --------------------------------------------------
-- Everything that shapes a widget when it is created. Label text, callbacks,
-- dropdown values and button functions are not part of it: they are re-bound.
local function TooltipKey(tooltip)
    if type(tooltip) == "table" then
        return (tooltip.title or "") .. "\1" .. (tooltip.desc or "")
    end
    return tooltip or ""
end

local function HookKey(hooks)
    if not hooks then return "" end
    local names = {}
    for name in pairs(hooks) do names[#names + 1] = name end
    table.sort(names)
    return table.concat(names, ",")
end

local function DefSignature(def)
    local t = def.Type
    if t == "Custom" then
        -- Identified by cacheId, or by its build function: a descriptor table that is
        -- built once and reused (static content) hits the cache without any opt-in.
        return "Custom:" .. (def.cacheId or tostring(def.build))
    end
    local tc = def.textColor
    return table.concat({
        t, def.height or "", def.min or "", def.max or "", def.step or "", def.decimals or "",
        tostring(def.usedecimals or def.useDecimals or false), tostring(def.liveDrag or false),
        tostring(def.numeric or false), def.inputWidth or "", def.width or "",
        tostring(def.highlight or false), tostring(def.nocombat or false),
        tostring(def.icon or ""), def.iconSize or "", def.labelW or "", tostring(def.autoWidth or false), def.textSize or "", HookKey(def.hooks), def.getText and "t" or "",
        def.get and "g" or "", def.set and "s" or "", def.func and "f" or "",
        (def.label and def.label ~= "") and "L" or "",
        (t == "Button") and (def.label or "") or "",
        (t == "Link") and ((def.label or "") .. "\1" .. (def.url or "")) or "",
        TooltipKey(def.tooltip),
        tc and (tc[1] .. "," .. tc[2] .. "," .. tc[3] .. "," .. (tc[4] or 1)) or "",
    }, "|")
end

local sigBuffer = {}
local function LayoutSignature(definitions, width)
    local n = 0
    for _, def in ipairs(definitions) do
        n = n + 1
        sigBuffer[n] = DefSignature(def)
    end
    for i = n + 1, #sigBuffer do sigBuffer[i] = nil end
    return table.concat(sigBuffer, "\n", 1, n) .. "@" .. tostring(width)
end

-- ---- binding ----------------------------------------------------
-- A slot is the one place a widget's callbacks live. Widgets are created with
-- thin wrappers that read the slot, so a cached widget can be pointed at a
-- different entry by filling the slot again.
local function BindSlot(slot, def)
    slot.get    = ResolveCallback(def.get)
    slot.set    = ResolveCallback(def.set)
    slot.values = ResolveCallback(def.values)
    slot.func   = ResolveCallback(def.func)
    slot.hooks  = def.hooks
    slot.getText = def.getText
end

local function SlotCall(slot, field, present)
    if not present then return nil end
    return function(...)
        local fn = slot[field]
        if fn then return fn(...) end
    end
end

local function SlotValues(slot)
    local v = slot.values
    if type(v) == "function" then v = v(NSI) end
    return v or {}
end

-- Re-point a cached widget at a new descriptor and redraw its value.
local function RebindItem(item, def)
    local slot, ctrl, t = item.slot, item.ctrl, item.type
    BindSlot(slot, def)

    local key = def.label or def.text
    if key and ctrl.SetLocaleKey then ctrl:SetLocaleKey(key) end

    if t == "Slider" or t == "Scale" then
        local v = slot.get and slot.get(NSI)
        if type(v) == "number" then ctrl:SetValue(v) end
    elseif t == "Checkbox" then
        ctrl:SetValue(slot.get and slot.get(NSI) or false)
    elseif t == "TextEntry" then
        ctrl:SetValue(slot.get and slot.get(NSI) or "")
    elseif t == "Dropdown" or t == "Color" then
        ctrl:Refresh()
    elseif t == "Label" and slot.getText then
        ctrl:SetText(NSI:Loc(slot.getText() or ""))
    end
end

-- ---- combat lock ------------------------------------------------
-- Descriptors with nocombat = true are disabled while the player is in combat
-- (settings that rebuild frames or touch protected state).
local combatLocked = setmetatable({}, WEAK_KEYS)
local combatWatcher = CreateFrame("Frame")
combatWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
combatWatcher:SetScript("OnEvent", function(_, event)
    local entering = event == "PLAYER_REGEN_DISABLED"
    for ctrl in pairs(combatLocked) do
        if entering then ctrl:Disable() else ctrl:Enable() end
    end
end)

local function LockInCombat(ctrl)
    if not (ctrl.Enable and ctrl.Disable) then return end
    combatLocked[ctrl] = true
    if InCombatLockdown() then ctrl:Disable() end
end

-- ---- building ---------------------------------------------------
local function BuildSet(parent, definitions, width, gap)
    gap = gap or WIDGET_GAP
    local C = NSI.UI.Components
    local items, byIndex = {}, {}
    local y = 0

    for index, def in ipairs(definitions) do
        local t    = def.Type
        local h    = def.height or WIDGET_H[t] or 22
        local slot = {}
        local ctrl
        BindSlot(slot, def)

        if t == "Slider" or t == "Scale" then
            ctrl = C.CreateSlider(parent, def.label,
                SlotCall(slot, "get", def.get), SlotCall(slot, "set", def.set),
                width, h, def.min, def.max, def.step, nil, def.tooltip, def.liveDrag, def.decimals, def.usedecimals or def.useDecimals, def.labelW)

        elseif t == "Dropdown" then
            local function getItems()
                local out = {}
                for _, v in ipairs(SlotValues(slot)) do
                    out[#out + 1] = {
                        label   = v.label and NSI:Loc(v.label) or nil,
                        value   = v.value,
                        onclick = function(_, _, val)
                            local set = slot.set
                            if set then set(NSI, val) end
                        end,
                    }
                end
                return out
            end
            local function getSelected()
                local get = slot.get
                local cur = get and get(NSI)
                for _, v in ipairs(SlotValues(slot)) do
                    if v.value == cur then return v.label and NSI:Loc(v.label) or "" end
                end
                return cur ~= nil and tostring(cur) or ""
            end
            ctrl = C.CreateDropdown(parent, def.label,
                getItems, getSelected, width, h, nil, def.tooltip, nil, def.highlight, nil, def.labelW)

        elseif t == "Color" then
            ctrl = C.CreateColorPicker(parent, def.label,
                SlotCall(slot, "get", def.get), SlotCall(slot, "set", def.set), width, h, nil, def.tooltip, def.labelW)

        elseif t == "Checkbox" then
            ctrl = C.CreateCheckButton(parent, def.label,
                SlotCall(slot, "get", def.get), SlotCall(slot, "set", def.set), width, h, nil, def.tooltip,
                def.icon, def.iconSize)

        elseif t == "TextEntry" then
            local hooks
            if def.hooks then
                hooks = {}
                for hookName in pairs(def.hooks) do
                    hooks[hookName] = function(...)
                        local fn = slot.hooks and slot.hooks[hookName]
                        if fn then return fn(...) end
                    end
                end
            end
            ctrl = C.CreateTextEntry(parent, def.label,
                SlotCall(slot, "get", def.get), SlotCall(slot, "set", def.set),
                width, h, def.numeric, def.min, def.max, nil, def.tooltip, def.inputWidth, hooks, def.labelW)

        elseif t == "Label" then
            local text = def.text
            if def.getText then text = NSI:Loc(def.getText() or "") end
            ctrl = C.CreateLabel(parent, text, width, h, nil, def.highlight, def.textColor)

        elseif t == "Breakline" then
            ctrl = C.CreateBreakline(parent, width, h, nil)

        elseif t == "Link" then
            ctrl = C.CreateLink(parent, def.label, def.url, def.width or width, h, nil, def.tooltip)

        elseif t == "Button" then
            -- autoWidth sizes the button to its (localized) label instead of the row.
            local text = def.autoWidth and NSI:Loc(def.label or "") or def.label
            ctrl = C.CreateButton(parent, text, function()
                local func = slot.func
                if func then func(NSI) end
            end, (not def.autoWidth) and (def.width or width) or nil, h, nil, nil, def.textSize, def.tooltip)

        elseif t == "Custom" then
            local build = ResolveCallback(def.build)
            if build then
                local builtHeight
                ctrl, builtHeight = build(parent, width)
                h = builtHeight or h
            end
        end

        if ctrl then
            local key = def.label or def.text
            if key and ctrl.SetLocaleKey then ctrl:SetLocaleKey(key) end
            if def.nocombat then LockInCombat(ctrl) end
            local item = {
                ctrl = ctrl, frame = ctrl.frame or ctrl, type = t,
                slot = slot, h = h, index = index,
            }
            items[#items + 1] = item
            byIndex[index] = item
            ctrl:SetPoint("TOPLEFT", parent, "TOPLEFT", def.indent or 0, -y)
            y = y + h + gap
        end
    end

    return { items = items, byIndex = byIndex, height = y > 0 and (y - gap) or 0 }
end

local function BuildWidgets(parent, definitions, width)
    return BuildSet(parent, definitions, width).height
end

-- ---- widget host ------------------------------------------------
local WidgetHost = {}
WidgetHost.__index = WidgetHost

local function CreateWidgetHost(parent, width, gap)
    return setmetatable({ parent = parent, width = width, gap = gap or WIDGET_GAP, sets = {} }, WidgetHost)
end

function WidgetHost:Apply(definitions, isVisible)
    local parent = self.parent
    local width  = self.width or parent:GetWidth()
    local sig    = LayoutSignature(definitions, width)
    local set    = self.sets[sig]

    -- Hide what is showing first. A focused edit box commits when it hides, and
    -- that commit must reach the entry it was editing, before anything is re-bound.
    if self.current then self.current.container:Hide() end

    if not set then
        local container = CreateFrame("Frame", nil, parent)
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        container:SetSize(width, 1)
        container:Hide()
        set = BuildSet(container, definitions, width, self.gap)
        set.container = container
        self.sets[sig] = set
    else
        for _, item in ipairs(set.items) do
            local def = definitions[item.index]
            RebindItem(item, def)
            if item.type == "Custom" and def.refresh then
                local h = def.refresh(item.ctrl, width)
                if h then item.h = h end
            end
        end
    end

    local container = set.container
    local y = 0
    for index, def in ipairs(definitions) do
        local item = set.byIndex[index]
        if item then
            if not isVisible or isVisible(def, index) then
                item.frame:ClearAllPoints()
                item.frame:SetPoint("TOPLEFT", container, "TOPLEFT", def.indent or 0, -y)
                item.frame:Show()
                y = y + item.h + self.gap
            else
                item.frame:Hide()
            end
        end
    end
    local height = y > 0 and (y - self.gap) or 0
    container:SetHeight(math.max(height, 1))
    container:Show()
    self.current = set
    return height
end

-- Hide whatever the host is showing (e.g. when its tab is hidden by other means).
function WidgetHost:Hide()
    if self.current then self.current.container:Hide() end
end

-- ============================================================
--  BuildMenu
--
--  Builds a Details Framework BuildMenu-style option table with NSRT
--  components, so every options page looks and behaves the same.
--
--    menu = C.BuildMenu(tabFrame, optionTable [, onChange])
--
--  The page scrolls vertically and is built once; breaklines split it into columns. tabFrame.RefreshOptions()
--  re-reads every value in place (the tab system calls it when a tab is shown).
--  onChange(nil, nil, value) runs after any control commits a value.
--
--  Entry fields understood:
--    type      toggle | range | select | color | button | label | textentry
--              | breakline | blank
--    name, desc, get, set(self, fixedparam, value), nocombat (disabled in combat)
--    toggle    icontexture / iconsize
--    range     min, max, step, usedecimals
--    select    values (table or function) of { label, value, onclick }
--    color     get() -> r, g, b, a   set(self, r, g, b, a)
--    button    func(self)
--    label     get() -> text; a text_template marks it as a heading when short
--    textentry hooks = { OnEnterPressed = fn, OnEditFocusLost = fn }
--  spacement, boxfirst, phraseId and hasAlpha need no mapping.
-- ============================================================
local MENU_MIN_COL    = 340
local MENU_MAX_COL    = 480
local MENU_COL_GAP    = 28
local MENU_ROW_GAP    = 18
local MENU_PAD        = 14
local MENU_HEADING_MAX = 48
local MENU_BUTTON_H   = 20   -- option buttons are compact; tab buttons set their own size
local MENU_BUTTON_TEXT = "small"

local function MenuTooltip(o)
    if not o.desc then return nil end
    return { title = o.name, desc = o.desc }
end

local function MenuEntries(o)
    local v = o.values
    if type(v) == "function" then v = v(NSI) end
    return v or {}
end

local function ConvertMenuEntry(o, onChange, columnWidth)
    local t = o.type
    local function Changed(value)
        if onChange then onChange(nil, nil, value) end
    end

    if t == "toggle" then
        return {
            Type = "Checkbox", label = o.name or "", tooltip = MenuTooltip(o), nocombat = o.nocombat,
            icon = o.icontexture, iconSize = o.iconsize and o.iconsize[1],
            get = function() return o.get and o.get(NSI) end,
            set = function(_, value)
                if o.set then o.set(nil, nil, value) end
                Changed(value)
            end,
        }
    elseif t == "range" then
        return {
            Type = "Slider", label = o.name or "", tooltip = MenuTooltip(o), nocombat = o.nocombat,
            min = o.min, max = o.max, step = o.step, usedecimals = o.usedecimals,
            get = function() return o.get and o.get(NSI) end,
            set = function(_, value)
                if o.set then o.set(nil, nil, value) end
                Changed(value)
            end,
        }
    elseif t == "select" then
        return {
            Type = "Dropdown", label = o.name or "", tooltip = MenuTooltip(o), nocombat = o.nocombat,
            get = function() return o.get and o.get(NSI) end,
            values = function()
                local out = {}
                for _, v in ipairs(MenuEntries(o)) do
                    out[#out + 1] = { label = v.label, value = v.value, font = v.font }
                end
                return out
            end,
            set = function(_, value)
                for _, v in ipairs(MenuEntries(o)) do
                    if v.value == value then
                        if v.onclick then v.onclick(nil, nil, value)
                        elseif o.set then o.set(nil, nil, value) end
                        break
                    end
                end
                Changed(value)
            end,
        }
    elseif t == "color" then
        return {
            Type = "Color", label = o.name or "", tooltip = MenuTooltip(o), nocombat = o.nocombat,
            -- Getters return r, g, b, a or one { r, g, b, a } / { r =, g =, b =, a = } table.
            get = function()
                if not o.get then return 1, 1, 1, 1 end
                local r, g, b, a = o.get(NSI)
                if type(r) == "table" then
                    local c = r
                    return c[1] or c.r or 1, c[2] or c.g or 1, c[3] or c.b or 1, c[4] or c.a or 1
                end
                return r or 1, g or 1, b or 1, a or 1
            end,
            set = function(_, r, g, b, a)
                if o.set then o.set(nil, r, g, b, a) end
                Changed(r)
            end,
        }
    elseif t == "button" then
        return {
            Type = "Button", label = o.name or "", tooltip = MenuTooltip(o), nocombat = o.nocombat,
            autoWidth = true, height = MENU_BUTTON_H, textSize = MENU_BUTTON_TEXT,
            func = function()
                if o.func then o.func(nil) end
                Changed()
            end,
        }
    elseif t == "textentry" then
        return {
            Type = "TextEntry", label = o.name or "", tooltip = MenuTooltip(o), nocombat = o.nocombat,
            inputWidth = 200, hooks = o.hooks,
            get = function() return o.get and o.get(NSI) end,
            set = function(_, value)
                if o.set then o.set(nil, nil, value) end
                Changed(value)
            end,
        }
    elseif t == "label" then
        local text = NSI:Loc((o.get and o.get(NSI)) or "")
        if text == "" then return nil end   -- spacer labels carry no content
        local def = { Type = "Label", getText = function() return o.get and o.get(NSI) end }
        if o.headerButton then def.headerButton = ConvertMenuEntry(o.headerButton, onChange, columnWidth) end
        if o.text_template and #text <= MENU_HEADING_MAX then
            def.highlight = true
            def.height = 22
        elseif o.text_template then
            -- A long emphasised line is a note: wrap it and size the row to fit.
            def.textColor = { 0.8, 0.8, 0.8, 1 }
            def.height = math.max(1, math.ceil(#text * 6.4 / columnWidth)) * 15 + 1
        end
        return def
    elseif t == "breakline" then
        return { Type = "Breakline" }
    elseif t == "blank" then
        return { Type = "Label", text = "", height = 8 }
    end
end

local function ConvertMenu(options, onChange, columnWidth)
    local defs = {}
    for _, o in ipairs(options) do
        local def = ConvertMenuEntry(o, onChange, columnWidth)
        if def then defs[#defs + 1] = def end
    end
    return defs
end

-- Sections: a heading label (the orange ones in the old menus) opens a section that
-- runs to the next heading or breakline. Each section is drawn as a card, and its
-- sliders, dropdowns, text boxes and colour swatches share one label column and one
-- control column so they line up and have the same width.
local MENU_CARD_PAD    = 10
local MENU_HEADER_ROW  = 18                                 -- title/button row height
local MENU_HEADER_H    = MENU_HEADER_ROW + MENU_CARD_PAD * 2 -- equal padding above and below
local MENU_SECTION_GAP = 12
local MENU_LABEL_GAP   = 8
local MENU_ROW_SPACING = 9   -- vertical gap between rows inside a card
local MENU_LABELED     = { Slider = true, Scale = true, Dropdown = true, TextEntry = true, Color = true }

-- Split converted definitions into { title = getText|nil, defs = {...} } sections.
-- A heading label opens a section. A heading that comes straight after another one
-- (nothing in between) is a note belonging to that section, not a new heading, and a
-- section with no widgets at all is dropped.
local function SplitSections(defs, contentW)
    local sections, current = {}, { defs = {} }
    local function Close()
        if #current.defs > 0 then sections[#sections + 1] = current end
    end
    for _, def in ipairs(defs) do
        if def.Type == "Label" and def.highlight then
            if current.title and #current.defs == 0 then
                -- demote to a wrapped note under the section title
                local text = NSI:Loc(def.getText and def.getText() or def.text or "")
                def.highlight = nil
                def.textColor = { 0.8, 0.8, 0.8, 1 }
                def.height = math.max(1, math.ceil(#text * 6.4 / contentW)) * 15 + 1
                current.defs[#current.defs + 1] = def
            else
                Close()
                current = { title = def.getText or function() return def.text end, headerButton = def.headerButton, defs = {} }
            end
        else
            current.defs[#current.defs + 1] = def
        end
    end
    Close()
    return sections
end

-- Label gets the left half of the section, the input (box, slider, dropdown, swatch,
-- button) the right half.
local function AssignHalves(defs, contentW)
    local labelW = math.floor(contentW / 2) - MENU_LABEL_GAP
    local controlX = labelW + MENU_LABEL_GAP
    for _, def in ipairs(defs) do
        if MENU_LABELED[def.Type] then
            def.labelW = labelW
        elseif def.Type == "Button" then
            def.indent = controlX
            def.width  = contentW - controlX
            def.autoWidth = false
        end
    end
end

local function CreateSectionCard(parent, width, hasTitle, headerButton)
    local card = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, parent)
    card:SetWidth(width)
    card:SetBackdrop({
        bgFile   = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    card:SetBackdropColor(unpack(STYLE.surface_inset_soft))
    card:SetBackdropBorderColor(unpack(STYLE.border_subtle))

    local headerH = 0
    if hasTitle then
        headerH = MENU_HEADER_H
        local title = MakeFontString(card, "body")
        title:SetPoint("TOPLEFT", card, "TOPLEFT", MENU_CARD_PAD, -MENU_CARD_PAD)
        title:SetHeight(MENU_HEADER_ROW)
        if headerButton then
            -- Optional action button in the header row, right-aligned.
            local func = headerButton.func
            local button = CreateButton(card, NSI:Loc(headerButton.label or ""), function()
                if func then func(NSI) end
            end, nil, MENU_HEADER_ROW, nil, nil, MENU_BUTTON_TEXT, headerButton.tooltip)
            button:SetPoint("TOPRIGHT", card, "TOPRIGHT", -MENU_CARD_PAD, -MENU_CARD_PAD)
            if headerButton.nocombat then LockInCombat(button) end
            title:SetPoint("RIGHT", button.frame, "LEFT", -8, 0)
            card.headerButton = button
        else
            title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -MENU_CARD_PAD, -MENU_CARD_PAD)
        end
        title:SetJustifyH("LEFT")
        title:SetJustifyV("MIDDLE")
        PaintAccent(title, "SetTextColor", 1)
        card.title = title

        local rule = card:CreateTexture(nil, "ARTWORK")
        rule:SetHeight(1)
        rule:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -headerH)
        rule:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -headerH)
        PaintAccent(rule, "SetColorTexture", 0.20)
    end

    local content = CreateFrame("Frame", nil, card)
    content:SetPoint("TOPLEFT", card, "TOPLEFT", MENU_CARD_PAD, -(headerH + MENU_CARD_PAD))
    content:SetSize(width - MENU_CARD_PAD * 2, 1)
    card.content = content
    card.headerH = headerH
    return card
end

-- ============================================================
--  CardHost
--
--  A WidgetHost whose definition list is drawn as a stack of section cards, like the
--  General tab: a highlighted Label opens a card (its text is the card title), and the
--  widgets after it up to the next highlighted Label sit inside it on the shared
--  label/control columns. Same Apply(defs, isVisible) -> height contract as WidgetHost,
--  so a detail panel only swaps the constructor. Each distinct definition layout is
--  built once and re-bound afterwards. A card whose widgets are all hidden by
--  isVisible is hidden too.
--
--  host.current.byIndex[i] is the item for the i-th definition passed to Apply, which
--  is what the header search uses to scroll to and pulse a row.
-- ============================================================
local CardHost = {}
CardHost.__index = CardHost

local function CreateCardHost(parent, width)
    return setmetatable({ parent = parent, width = width, sets = {} }, CardHost)
end

function CardHost:Hide()
    local current = self.current
    if current then
        for _, entry in ipairs(current.cards) do entry.card:Hide() end
    end
end

function CardHost:Apply(defs, isVisible)
    local width    = self.width or self.parent:GetWidth()
    local contentW = width - MENU_CARD_PAD * 2
    for index, def in ipairs(defs) do def._cardIndex = index end

    local sections = SplitSections(defs, contentW)
    local sig = LayoutSignature(defs, width)
    local set = self.sets[sig]

    local previous = self.current
    if previous and previous ~= set then
        for _, entry in ipairs(previous.cards) do entry.card:Hide() end
    end
    if not set then
        set = { cards = {} }
        for i, section in ipairs(sections) do
            local card = CreateSectionCard(self.parent, width, section.title ~= nil, section.headerButton)
            card:Hide()
            set.cards[i] = { card = card, host = CreateWidgetHost(card.content, contentW, MENU_ROW_SPACING) }
        end
        self.sets[sig] = set
    end

    local byIndex, y = {}, 0
    for i, section in ipairs(sections) do
        local entry = set.cards[i]
        local card, host = entry.card, entry.host
        AssignHalves(section.defs, contentW)
        local height = host:Apply(section.defs, isVisible)
        if height > 0 then
            if card.title then card.title:SetText(NSI:Loc(section.title() or "")) end
            card.content:SetHeight(math.max(height, 1))
            card:SetHeight(card.headerH + MENU_CARD_PAD * 2 + height)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, -y)
            card:Show()
            y = y + card:GetHeight() + MENU_SECTION_GAP
            for k, def in ipairs(section.defs) do
                byIndex[def._cardIndex] = host.current and host.current.byIndex[k]
            end
        else
            card:Hide()
        end
    end
    set.byIndex = byIndex
    self.current = set
    return y > 0 and (y - MENU_SECTION_GAP) or 0
end

-- Columns: every breakline in the option table starts a new column, as it did in the
-- Details Framework menus. Columns share one width, chosen so that as many fit side by
-- side as the page allows (between MENU_MIN_COL and MENU_MAX_COL); extra columns wrap
-- onto a new row below.
local function BuildMenu(parent, options, onChange)
    local scroll = CreateScrollBox(parent, parent:GetWidth() - MENU_PAD, parent:GetHeight())
    scroll.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", MENU_PAD, 0)
    local child = scroll.scrollChild

    -- Split the raw entries at breaklines.
    local groups, current = {}, {}
    for _, o in ipairs(options) do
        if o.type == "breakline" then
            if #current > 0 then groups[#groups + 1] = current; current = {} end
        else
            current[#current + 1] = o
        end
    end
    if #current > 0 then groups[#groups + 1] = current end

    local avail   = child:GetWidth() - MENU_PAD * 2
    local fit     = math.max(1, math.floor((avail + MENU_COL_GAP) / (MENU_MIN_COL + MENU_COL_GAP)))
    local perRow  = math.max(1, math.min(#groups, fit))
    local colW    = math.min(MENU_MAX_COL, math.floor((avail - (perRow - 1) * MENU_COL_GAP) / perRow))
    local contentW = colW - MENU_CARD_PAD * 2

    -- Each breakline group is a stack of section cards. Groups are laid out on a grid of
    -- perRow columns: a group goes into the shortest column, so the gap between cards in
    -- a column is always MENU_SECTION_GAP and no column is left with a big empty block.
    local stacks = {}
    for index, group in ipairs(groups) do
        local sections = {}
        for _, section in ipairs(SplitSections(ConvertMenu(group, onChange, contentW), contentW)) do
            AssignHalves(section.defs, contentW)
            local card = CreateSectionCard(child, colW, section.title ~= nil, section.headerButton)
            sections[#sections + 1] = {
                card     = card,
                getTitle = section.title,
                defs     = section.defs,
                host     = CreateWidgetHost(card.content, contentW, MENU_ROW_SPACING),
            }
        end
        stacks[index] = sections
    end

    local menu = { scroll = scroll, stacks = stacks }

    function menu:Refresh()
        local heights = {}
        for c = 1, perRow do heights[c] = 0 end
        for _, sections in ipairs(stacks) do
            local column = 1
            for c = 2, perRow do
                if heights[c] < heights[column] then column = c end
            end
            local x = MENU_PAD + (column - 1) * (colW + MENU_COL_GAP)
            local y = heights[column]
            for _, section in ipairs(sections) do
                local card = section.card
                if card.title then card.title:SetText(NSI:Loc(section.getTitle() or "")) end
                local height = section.host:Apply(section.defs)
                card.content:SetHeight(math.max(height, 1))
                card:SetHeight(card.headerH + MENU_CARD_PAD * 2 + height)
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", child, "TOPLEFT", x, -(MENU_PAD + y))
                y = y + card:GetHeight() + MENU_SECTION_GAP
            end
            heights[column] = y
        end
        local tallest = 0
        for c = 1, perRow do tallest = math.max(tallest, heights[c]) end
        child:SetHeight(MENU_PAD * 2 + math.max(tallest - MENU_SECTION_GAP, 0))
        scroll:UpdateScrollBar()
    end

    parent.RefreshOptions = function() menu:Refresh() end
    parent.menu = menu   -- the global search indexes stacks -> sections -> defs from here
    menu:Refresh()
    return menu
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
    local f = NSI.UI.Pixel.CreateBoxFrame("Frame", frameName, UIParent)
    NSI.UI.Pixel.PixelSpace(f, 1)
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
    f:SetBackdropColor(unpack(STYLE.surface_panel))
    PaintAccent(f, "SetBackdropBorderColor", 0.7)

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

    local titleFS = MakeFontString(f, "body")
    titleFS:SetText(title or "")
    titleFS:SetJustifyH("LEFT")
    titleFS:SetJustifyV("MIDDLE")
    titleFS:SetPoint("LEFT",  titleBar, "LEFT",  DIALOG_PAD, 0)
    titleFS:SetPoint("RIGHT", titleBar, "RIGHT", -28, 0)
    titleFS:SetHeight(DIALOG_TITLE_H)
    f.titleFS = titleFS

    local titleSep = f:CreateTexture(nil, "ARTWORK")
    PaintAccent(titleSep, "SetColorTexture", 0.20)
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -(DIALOG_TITLE_H + 1))
    titleSep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(DIALOG_TITLE_H + 1))

    -- ── Close (×) button ────────────────────────────────────────
    local xBtn = CreateFrame("Button", nil, f)
    xBtn:SetSize(14, 14)
    xBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    xBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    xBtn:SetNormalTexture(ICON_PATH .. "x.png")
    xBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.text_muted))
    xBtn:SetScript("OnEnter", function() xBtn:GetNormalTexture():SetVertexColor(Accent(1)) end)
    xBtn:SetScript("OnLeave", function() xBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.text_muted)) end)
    xBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Body text ────────────────────────────────────────────────
    local bodyFS = MakeFontString(f, "label")
    bodyFS:SetText(body or "")
    bodyFS:SetJustifyH("LEFT")
    bodyFS:SetJustifyV("TOP")
    bodyFS:SetWordWrap(true)
    bodyFS:SetPoint("TOPLEFT",     f, "TOPLEFT",     DIALOG_PAD, -(DIALOG_TITLE_H + DIALOG_PAD))
    bodyFS:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -DIALOG_PAD, DIALOG_BTN_H + DIALOG_PAD * 2)
    f.bodyFS = bodyFS

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
--  CreateInputDialog
--
--  A dialog with a single text box, used instead of Blizzard's StaticPopup (which
--  runs through secure code paths and can taint). One frame is cached per name and
--  reused: every call sets the title, prompt, default text and callback again, so the
--  same dialog can serve different targets (for example "rename group X").
--
--  Params
--    name   - unique key
--    title  - title bar text
--    prompt - text above the box
--    opts   - optional table:
--               default    initial text (selected on open)
--               okText     accept button label (default "OK")
--               cancelText cancel button label (default "Cancel")
--               maxLetters limit for the text box (default 200)
--               onAccept   function(text): text is trimmed and may be "" (the
--                          callback decides whether an empty name is valid)
--
--  Accepted by the OK button or Enter; Cancel, Escape and the close button discard.
--  Returns the dialog frame.
-- ============================================================
local INPUT_DIALOG_H = 150
local INPUT_ENTRY_H  = 24

local function CreateInputDialog(name, title, prompt, opts)
    opts = opts or {}
    local key = "Input_" .. name
    local f = Dialogs[key]

    if not f then
        local entry
        local function Accept()
            if not f:IsShown() then return end
            local callback = f._onAccept
            local text = strtrim(entry:GetValue() or "")
            f:Hide()
            if callback then callback(text) end
        end

        f = CreateDialog(key, title, prompt,
            opts.cancelText or NSI:Loc("Cancel"), nil,
            opts.okText or NSI:Loc("OK"), Accept)
        f:SetHeight(INPUT_DIALOG_H)
        f.bodyFS:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -DIALOG_PAD,
            DIALOG_BTN_H + DIALOG_PAD * 2 + INPUT_ENTRY_H + 8)

        entry = CreateTextEntry(f, nil, nil, nil, DIALOG_W - DIALOG_PAD * 2, INPUT_ENTRY_H,
            false, nil, nil, nil, nil, nil, {
                OnEnterPressed  = Accept,
                OnEscapePressed = function() f:Hide() end,
            })
        entry:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", DIALOG_PAD, DIALOG_BTN_H + DIALOG_PAD * 2)
        f.entry = entry
    else
        f.titleFS:SetText(title or "")
        f.bodyFS:SetText(prompt or "")
    end

    f._onAccept = opts.onAccept
    f.entry.editBox:SetMaxLetters(opts.maxLetters or 200)
    f.entry:SetValue(opts.default or "")
    f:Show()
    C_Timer.After(0, function()
        if f:IsShown() then
            f.entry.editBox:SetFocus()
            f.entry.editBox:HighlightText()
        end
    end)
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
    local f = NSI.UI.Pixel.CreateBoxFrame("Frame", name, parent or UIParent)
    if (parent or UIParent) == UIParent then NSI.UI.Pixel.PixelSpace(f, 1) end
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
    f:SetBackdropColor(unpack(STYLE.surface_panel))
    PaintAccent(f, "SetBackdropBorderColor", 0.7)

    local xBtn = CreateFrame("Button", nil, f)
    xBtn:SetSize(14, 14)
    xBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    xBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    xBtn:SetNormalTexture(ICON_PATH .. "x.png")
    xBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.text_muted))
    xBtn:SetScript("OnEnter", function() xBtn:GetNormalTexture():SetVertexColor(Accent(1)) end)
    xBtn:SetScript("OnLeave", function() xBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.text_muted)) end)
    xBtn:SetScript("OnClick", function() f:Hide() end)

    if name then tinsert(UISpecialFrames, name) end

    return f
end

-- ============================================================
--  FadeTo(region, target, duration)
--
--  Native alpha fade for a frame or texture: one AnimationGroup per region, no
--  per-frame Lua, no garbage (UIFrameFade allocates a table per call and needs a
--  wrapper frame around a texture). A fade started mid-fade continues from the
--  current alpha at constant speed; a hidden region snaps. Only writes fields onto our
--  own regions.
-- ============================================================
local function FadeTo(region, target, duration)
    local g = region._fade
    if not g then
        g = region:CreateAnimationGroup()
        g:SetToFinalAlpha(true)
        g.anim = g:CreateAnimation("Alpha")
        region._fade = g
    end
    local cur = region:GetAlpha()
    if g:IsPlaying() then
        if region._fadeTarget == target then return end
        g:Stop()
        region:SetAlpha(cur)
    end
    region._fadeTarget = target
    if (duration or 0) <= 0 or cur == target or not region:IsVisible() then
        region:SetAlpha(target)
        return
    end
    g.anim:SetFromAlpha(cur)
    g.anim:SetToAlpha(target)
    g.anim:SetDuration(duration * math.abs(target - cur))
    g:Play()
end

-- ============================================================
--  StyleRow(frame, fill, alpha)
--
--  The list-row surface: a white texture on frame.__background (tinted with the fill
--  colour and alpha, so rows can recolour it with SetVertexColor / SetAlpha) and a 1px
--  black pixel-snapped border. Replaces DF:ApplyStandardBackdrop. Safe to call on any
--  frame; it only adds regions.
--    fill   {r, g, b[, a]}  default STYLE.row_fill      alpha  default fill[4] or 1
-- ============================================================
local function StyleRow(frame, fill, alpha)
    fill = fill or STYLE.row_fill
    local bg = frame.__background
    if not bg then
        bg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, 1)
        frame.__background = bg
        frame.__border = NSI.UI.Pixel.Border(frame, { 0, 0, 0, 1 })
    end
    bg:SetVertexColor(fill[1], fill[2], fill[3])
    bg:SetAlpha(alpha or fill[4] or 1)
    return frame
end

-- ============================================================
--  CreateTextBoxDialog(name, title, opts)
--
--  A movable dialog with a multi-line, scrolling text box: import and export strings,
--  or any block of text. One frame per name, built on first use and reused. Replaces
--  the Details Framework Lua editor popups.
--
--    opts: width / height   default 800 x 400
--          readOnly         the text can be selected and copied but not edited
--          okText           primary button label (default "Done")
--          cancelText       when set, a Cancel button is added left of the primary one
--          onOk             function(text, dialog): called by the primary button; return
--                           false to keep the dialog open (use dialog:SetStatus first)
--
--  dialog:Open(text, info, onOk)   show it with this text and an info line above the box
--  dialog:SetStatus(message, isError)
--  dialog:GetText()
--
--  A read-only box selects everything on open, so Ctrl+C copies it at once.
-- ============================================================
local TB_TITLE_H, TB_INFO_H, TB_PAD, TB_BTN_H, TB_BTN_W = 30, 22, 12, 26, 110

local function CreateTextBoxDialog(name, title, opts)
    opts = opts or {}
    local key = "TextBox_" .. name
    local f = Dialogs[key]
    if f then
        f.titleFS:SetText(title or "")
        return f
    end

    local W, H = opts.width or 800, opts.height or 400
    f = CreateStyledFrame(UIParent, W, H, "NSRTTextBox_" .. name)
    f:SetPoint("CENTER", UIParent, "CENTER")
    f:SetFrameStrata("DIALOG")
    Dialogs[key] = f

    f.titleFS = MakeFontString(f, "body")
    f.titleFS:SetText(title or "")
    f.titleFS:SetPoint("TOPLEFT", f, "TOPLEFT", TB_PAD, -8)

    local sep = f:CreateTexture(nil, "ARTWORK")
    PaintAccent(sep, "SetColorTexture", 0.20)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -(TB_TITLE_H + 1))
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(TB_TITLE_H + 1))

    f.info = MakeFontString(f, "label")
    f.info:SetTextColor(unpack(STYLE.text_soft))
    f.info:SetJustifyH("LEFT")
    f.info:SetPoint("TOPLEFT", f, "TOPLEFT", TB_PAD, -(TB_TITLE_H + 8))
    f.info:SetPoint("RIGHT", f, "RIGHT", -TB_PAD, 0)

    -- the text area: an inset surface holding a scroll box holding the edit box
    local areaTop = TB_TITLE_H + TB_INFO_H + 12
    local area = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, f)
    area:SetPoint("TOPLEFT", f, "TOPLEFT", TB_PAD, -areaTop)
    area:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -TB_PAD, TB_BTN_H + TB_PAD * 2)
    area:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    area:SetBackdropColor(unpack(STYLE.surface_inset))
    area:SetBackdropBorderColor(unpack(STYLE.border_subtle))

    local areaW, areaH = W - TB_PAD * 2 - 2, H - areaTop - TB_BTN_H - TB_PAD * 2 - 2
    local scroll = CreateScrollBox(area, areaW, areaH)
    scroll.frame:SetPoint("TOPLEFT", area, "TOPLEFT", 1, -1)
    local child = scroll.scrollChild

    local edit = CreateFrame("EditBox", nil, child)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetTextInsets(6, 6, 4, 4)
    edit:SetPoint("TOPLEFT", child, "TOPLEFT")
    edit:SetWidth(child:GetWidth())
    NSI:SetUIFont(edit, "label")
    edit:SetTextColor(unpack(STYLE.text_color))
    f.edit = edit

    local locked, pending = opts.readOnly and true or false, false
    local function FitHeight()
        pending = false
        child:SetHeight(math.max(edit:GetHeight(), scroll.frame:GetHeight()))
        scroll:UpdateScrollBar()
    end
    edit:SetScript("OnTextChanged", function(self, userInput)
        if locked and userInput then            -- read-only: put the text back
            self:SetText(f._text or "")
            self:HighlightText()
            return
        end
        if not pending then pending = true; C_Timer.After(0, FitHeight) end
    end)
    edit:SetScript("OnCursorChanged", function(_, _, y, _, h)   -- keep the caret in view
        y = -y
        local top, view = scroll.frame:GetVerticalScroll(), scroll.frame:GetHeight()
        if y < top then
            scroll.frame:SetVerticalScroll(y)
        elseif y + h > top + view then
            scroll.frame:SetVerticalScroll(y + h - view)
        end
    end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    child:EnableMouse(true)
    child:SetScript("OnMouseDown", function() edit:SetFocus() end)

    -- buttons
    local function Primary()
        local ok = true
        if f._onOk then ok = f._onOk(edit:GetText(), f) end
        if ok ~= false then f:Hide() end
    end
    local primary = CreateButton(f, opts.okText or NSI:Loc("Done"), Primary, TB_BTN_W, TB_BTN_H)
    primary:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -TB_PAD, TB_PAD)
    if opts.cancelText then
        local cancel = CreateButton(f, opts.cancelText, function() f:Hide() end, TB_BTN_W, TB_BTN_H)
        cancel:SetPoint("RIGHT", primary.frame, "LEFT", -8, 0)
    end

    function f:SetStatus(message, isError)
        f.info:SetText(message or "")
        if isError then f.info:SetTextColor(unpack(STYLE.text_danger))
        else f.info:SetTextColor(unpack(STYLE.text_soft)) end
    end
    function f:GetText() return edit:GetText() end
    function f:Open(text, info, onOk)
        f._text = text or ""
        f._onOk = onOk or opts.onOk
        f:SetStatus(info, false)
        edit:SetText(f._text)
        scroll.frame:SetVerticalScroll(0)
        f:Show()
        C_Timer.After(0, function()
            if not f:IsShown() then return end
            FitHeight()
            edit:SetFocus()
            if locked then edit:HighlightText() end
        end)
        return f
    end

    f:Hide()
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
--    { type="separator", label="…" }   -- label optional; centred in the line
--
--  width – optional fixed px width; nil = auto-sized to widest label
-- ============================================================
local CTX_ROW_H    = 20
local CTX_SEP_H    = 8
local CTX_SEP_LBL_H = 16
local CTX_LABEL_H  = 18
local CTX_PAD_H    = 8
local CTX_ICON_SZ  = 14
local CTX_ICON_GAP = 4
local CTX_ARROW_W  = 14

-- Menus taller than this many rows are clipped to that height and scrolled
-- with the mouse wheel instead of running off the screen.
local CTX_MAX_ROWS  = 10
local CTX_SCROLL_W  = 4
local CTX_SCROLL_MIN_THUMB = 12

local MAX_CTX_LEVELS = 5
local ctxFrames      = {}
local ctxClickaway   = nil
local contextMeasureFontString

local function CtxMeasureText(text)
    if not contextMeasureFontString then
        contextMeasureFontString = UIParent:CreateFontString(nil, "ARTWORK")
        contextMeasureFontString:Hide()
    end
    contextMeasureFontString:SetFont(
        ValidateFont(NSI:GetUIFontPath()),
        STYLE.type.label,
        NSI:GetWindowFontFlags())
    contextMeasureFontString:SetText(text or "")
    return contextMeasureFontString:GetStringWidth()
end

-- A labelled separator centres its text in the row and runs the divider line
-- out to both edges. Labels past CTX_SEP_LABEL_MAX chars are cut.
local CTX_SEP_LABEL_MAX = 26
local CTX_SEP_LBL_GAP   = 6    -- blank space between the text and each line
local CTX_SEP_LBL_MIN   = 10   -- shortest line stub worth drawing

local function CtxSepLabel(label)
    return string.sub(label, 1, CTX_SEP_LABEL_MAX)
end

local function ResolveCtxIcon(item)
    if item.spellIcon then
        return C_Spell.GetSpellTexture(item.spellIcon)
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
    local f = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, UIParent)
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
    f:SetBackdropColor(unpack(STYLE.surface_panel))
    PaintAccent(f, "SetBackdropBorderColor", 0.7)

    -- Rows live in this clipped child so a long menu can be scrolled as a
    -- block; its right edge is pulled in when the scrollbar is shown.
    local content = CreateFrame("Frame", nil, f)
    content:SetFrameLevel(f:GetFrameLevel() + 1)
    content:SetClipsChildren(true)
    f._content = content

    local track = f:CreateTexture(nil, "ARTWORK")
    track:SetColorTexture(1, 1, 1, 0.06)
    track:SetWidth(CTX_SCROLL_W)
    track:SetPoint("TOPRIGHT",    f, "TOPRIGHT",    -2, -2)
    track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2,  2)
    track:Hide()
    f._scrollTrack = track

    local thumb = f:CreateTexture(nil, "OVERLAY")
    PaintAccent(thumb, "SetColorTexture", 0.45)
    thumb:SetWidth(CTX_SCROLL_W)
    thumb:Hide()
    f._scrollThumb = thumb

    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta)
        if f._Scroll then f._Scroll(delta) end
    end)

    f._rows = {}
    ctxFrames[level] = f
    return f
end

local ShowContextAtLevel

ShowContextAtLevel = function(items, level, xNormal, xFlip, yTop, width, maxRows)
    HideCtxFromLevel(level + 1)
    EnsureCtxClickaway()

    local f         = GetOrCreateCtxFrame(level)
    local baseLevel = f:GetFrameLevel()

    -- ── Width ────────────────────────────────────────────────────
    local autoWidth = (width == nil)
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
            elseif t == "separator" and item.label then
                -- Leave room for the text plus a short line stub either side.
                local w = CtxMeasureText(CtxSepLabel(item.label))
                          + (CTX_SEP_LBL_GAP + CTX_SEP_LBL_MIN) * 2
                if w > maxW then maxW = w end
            end
        end
        local iconW  = hasIcon    and (CTX_ICON_SZ + CTX_ICON_GAP) or 0
        local arrowW = hasSubmenu and CTX_ARROW_W                   or 0
        width = math.max(math.ceil(maxW) + CTX_PAD_H * 2 + iconW + arrowW, 100)
    end

    -- ── Height ───────────────────────────────────────────────────
    local contentH = 0
    for _, item in ipairs(items) do
        if item.type == "separator" then
            contentH = contentH + (item.label and CTX_SEP_LBL_H or CTX_SEP_H)
        elseif item.type == "label" then contentH = contentH + CTX_LABEL_H
        else                             contentH = contentH + CTX_ROW_H
        end
    end

    -- Anything past the configured row limit is reachable by scrolling.
    local maxContentH = (maxRows or CTX_MAX_ROWS) * CTX_ROW_H
    local scrollable  = contentH > maxContentH
    local viewH       = scrollable and maxContentH or contentH
    local totalH      = viewH + 4   -- 2px inner padding top + bottom

    local scrollInset = scrollable and (CTX_SCROLL_W + 4) or 0
    -- Auto-sized menus grow to keep the label area intact once the scrollbar
    -- claims a strip on the right; fixed-width menus just give up the strip.
    if autoWidth then width = width + scrollInset end
    local contentW = width - scrollInset

    f:SetSize(width, totalH)

    local content = f._content
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT",     f, "TOPLEFT",      0, -2)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -scrollInset, 2)

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

        local row = CreateFrame("Button", nil, content)
        row:SetFrameLevel(baseLevel + 2)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        -- Rows swallow mouse input, so forward the wheel to the menu frame.
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta)
            if f._Scroll then f._Scroll(delta) end
        end)

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
        sepTex:SetColorTexture(Accent(0.15))
        sepTex:SetHeight(1)
        row.sepTex = sepTex

        -- Second stub, used only by labelled separators: sepTex runs from the
        -- left edge to the text, this one from the text to the right edge.
        local sepTex2 = row:CreateTexture(nil, "ARTWORK")
        sepTex2:SetColorTexture(Accent(0.15))
        sepTex2:SetHeight(1)
        row.sepTex2 = sepTex2

        local iconFrame = CreateFrame("Frame", nil, row)
        iconFrame:SetSize(CTX_ICON_SZ, CTX_ICON_SZ)
        iconFrame:SetFrameLevel(baseLevel + 4)
        iconFrame:EnableMouse(false)
        local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTex:SetTexCoord(0.1, 0.90, 0.1, 0.90)
        iconTex:SetAllPoints()
        row.iconFrame = iconFrame
        row.iconTex   = iconTex

        local labelFS = MakeFontString(row, "label")
        labelFS:SetJustifyH("LEFT")
        labelFS:SetJustifyV("MIDDLE")
        row.labelFS = labelFS

        local arrowTex = row:CreateTexture(nil, "ARTWORK")
        arrowTex:SetSize(8, 8)
        arrowTex:SetPoint("RIGHT", row, "RIGHT", -(CTX_PAD_H - 2), 0)
        arrowTex:SetTexture(ICON_PATH .. "chevron-right.png")
        arrowTex:SetVertexColor(unpack(STYLE.text_muted))
        row.arrowTex = arrowTex

        rowPool[i] = row
        return row
    end

    -- ── Build rows ───────────────────────────────────────────────
    -- Rows are configured here but positioned by ApplyScroll() below, so a
    -- scrolled menu can re-lay them out without rebuilding.
    local layout   = {}
    local curY     = 0
    local rowCount = 0

    for _, item in ipairs(items) do
        rowCount = rowCount + 1
        local row   = GetRow(rowCount)
        local itype = item.type

        row.hoverBg:SetAlpha(0)
        row.sepTex:Hide()
        row.sepTex2:Hide()
        row.iconFrame:Hide()
        row.arrowTex:Hide()
        row.labelFS:SetWordWrap(true)
        row.labelFS:SetJustifyH("LEFT")
        row.labelFS:SetText("")
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
        row:SetScript("OnClick", nil)
        row:EnableMouse(false)

        if itype == "separator" then
            local sepH = item.label and CTX_SEP_LBL_H or CTX_SEP_H
            row:SetSize(contentW, sepH)
            layout[rowCount] = {row = row, y = curY, h = sepH}
            if item.label then
                local text = CtxSepLabel(item.label)
                -- Anchored from the centre only, so the text keeps its natural
                -- width and the line stubs can butt up against it.
                row.labelFS:SetWordWrap(false)
                row.labelFS:SetJustifyH("CENTER")
                row.labelFS:SetTextColor(unpack(STYLE.text_muted))
                row.labelFS:SetText(text)
                row.labelFS:ClearAllPoints()
                row.labelFS:SetPoint("CENTER", row, "CENTER", 0, 0)
                row.labelFS:SetHeight(sepH)

                -- Hidden rather than drawn at a negative width when the text
                -- alone already fills the row.
                local halfGap = CtxMeasureText(text) / 2 + CTX_SEP_LBL_GAP
                if contentW / 2 - CTX_PAD_H - halfGap >= CTX_SEP_LBL_MIN then
                    row.sepTex:ClearAllPoints()
                    row.sepTex:SetPoint("LEFT",  row, "LEFT",   CTX_PAD_H, 0)
                    row.sepTex:SetPoint("RIGHT", row, "CENTER", -halfGap,  0)
                    row.sepTex:Show()

                    row.sepTex2:ClearAllPoints()
                    row.sepTex2:SetPoint("LEFT",  row, "CENTER", halfGap,   0)
                    row.sepTex2:SetPoint("RIGHT", row, "RIGHT",  -CTX_PAD_H, 0)
                    row.sepTex2:Show()
                end
            else
                row.sepTex:ClearAllPoints()
                row.sepTex:SetPoint("LEFT",  row, "LEFT",  CTX_PAD_H, 0)
                row.sepTex:SetPoint("RIGHT", row, "RIGHT", -CTX_PAD_H, 0)
                row.sepTex:Show()
            end
            curY = curY + sepH

        elseif itype == "label" then
            row:SetSize(contentW, CTX_LABEL_H)
            layout[rowCount] = {row = row, y = curY, h = CTX_LABEL_H}
            row.labelFS:SetTextColor(unpack(STYLE.text_muted))
            row.labelFS:SetText(item.text or "")
            row.labelFS:ClearAllPoints()
            row.labelFS:SetPoint("LEFT",  row, "LEFT",  CTX_PAD_H,  0)
            row.labelFS:SetPoint("RIGHT", row, "RIGHT", -CTX_PAD_H, 0)
            row.labelFS:SetHeight(CTX_LABEL_H)
            curY = curY + CTX_LABEL_H

        elseif itype == "button" or itype == "submenu" then
            row:SetSize(contentW, CTX_ROW_H)
            layout[rowCount] = {row = row, y = curY, h = CTX_ROW_H}
            row:EnableMouse(true)

            local tex   = ResolveCtxIcon(item)
            local leftX = CTX_PAD_H
            if tex then
                row.iconTex:SetTexture(tex)
                row.iconTex:SetTexCoord(0.1, 0.90, 0.1, 0.90)
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

            row.labelFS:SetTextColor(unpack(STYLE.text_color))
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
                if item.fnc or item.contextItems then
                    row:SetScript("OnClick", function(_, clickButton)
                        if clickButton == "RightButton" then
                            if item.contextItems then
                                -- x from the menu frame, not the row: rows are
                                -- narrowed when the scrollbar is shown.
                                local rRight = f:GetRight()
                                local rLeft  = f:GetLeft()
                                local rTop   = row:GetTop()
                                if rRight and rTop then
                                    ShowContextAtLevel(item.contextItems, level + 1, rRight + 2, rLeft - 2, rTop, item.contextWidth, maxRows)
                                end
                            end
                        elseif item.fnc then
                            HideCtxFromLevel(1)
                            item.fnc()
                        end
                    end)
                end
            else -- submenu
                local subItems = item.items or {}
                row:SetScript("OnEnter", function()
                    UIFrameFadeIn(row.hoverBg, STYLE.hover_in, row.hoverBg:GetAlpha(), 1)
                    row.arrowTex:SetVertexColor(Accent(1))
                    local rRight = f:GetRight()
                    local rLeft  = f:GetLeft()
                    local rTop   = row:GetTop()
                    if rRight and rTop then
                        ShowContextAtLevel(subItems, level + 1, rRight + 2, rLeft - 2, rTop, nil, maxRows)
                    end
                end)
                row:SetScript("OnLeave", function()
                    UIFrameFadeOut(row.hoverBg, STYLE.hover_out, row.hoverBg:GetAlpha(), 0)
                    row.arrowTex:SetVertexColor(unpack(STYLE.text_muted))
                end)
            end

            curY = curY + CTX_ROW_H
        end
    end

    for i = rowCount + 1, #rowPool do rowPool[i]:Hide() end

    -- ── Scroll ───────────────────────────────────────────────────
    local maxScroll = contentH - viewH   -- 0 when everything fits
    f._scroll = 0

    local function ApplyScroll()
        for _, e in ipairs(layout) do
            local top    = f._scroll - e.y
            local bottom = top - e.h
            e.row:ClearAllPoints()
            e.row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, top)
            -- Rows entirely outside the viewport are hidden: clipping only
            -- suppresses drawing, it does not stop them taking mouse input.
            if top > -viewH and bottom < 0 then
                e.row:Show()
            else
                e.row:Hide()
            end
        end

        if scrollable then
            local thumbH = math.max(CTX_SCROLL_MIN_THUMB, viewH * viewH / contentH)
            local travel = viewH - thumbH
            local frac   = maxScroll > 0 and (f._scroll / maxScroll) or 0
            f._scrollThumb:SetHeight(thumbH)
            f._scrollThumb:ClearAllPoints()
            f._scrollThumb:SetPoint("TOP", f._scrollTrack, "TOP", 0, -travel * frac)
            f._scrollTrack:Show()
            f._scrollThumb:Show()
        else
            f._scrollTrack:Hide()
            f._scrollThumb:Hide()
        end
    end

    f._Scroll = scrollable and function(delta)
        local newScroll = math.min(math.max(f._scroll - delta * CTX_ROW_H, 0), maxScroll)
        if newScroll == f._scroll then return end
        f._scroll = newScroll
        -- Any open child menu is anchored to a row that just moved.
        HideCtxFromLevel(level + 1)
        ApplyScroll()
    end or nil

    ApplyScroll()

    f:Show()
    if level == 1 then ctxClickaway:Show() end
end

local function ShowContextMenu(items, width, maxRows)
    EnsureCtxClickaway()
    local scale  = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    local uiX    = cx / scale
    local uiY    = cy / scale
    ShowContextAtLevel(items, 1, uiX, uiX, uiY, width, maxRows)
end

-- ============================================================
--  ShowContextMenuAtFrame
--
--  Same styled menu as ShowContextMenu, but opens anchored below
--  a frame (e.g. a menu-bar button) instead of at the cursor.
--  Left edge aligns to the anchor's left edge normally, flipping
--  to right-align against the anchor's right edge if it would
--  otherwise run off the edge of the screen.
-- ============================================================
local function ShowContextMenuAtFrame(items, anchor, width, maxRows)
    EnsureCtxClickaway()
    -- anchor's Get{Left,Right,Bottom} are expressed in ITS OWN effective-scale units,
    -- but the popup frame is parented straight to UIParent, so if anchor sits inside
    -- something with its own SetScale (e.g. a window's adjustable scale bar), the raw
    -- values drift relative to UIParent's space. Renormalize by the scale ratio.
    local scaleRatio = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local left   = (anchor:GetLeft() or 0) * scaleRatio
    local right  = (anchor:GetRight() or 0) * scaleRatio
    local bottom = (anchor:GetBottom() or 0) * scaleRatio
    ShowContextAtLevel(items, 1, left, right, bottom, width, maxRows)
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

    local f = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, UIParent)
    NSI.UI.Pixel.PixelSpace(f, 1)
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
    f:SetBackdropColor(unpack(STYLE.surface_panel))
    PaintAccent(f, "SetBackdropBorderColor", 0.7)

    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -LINK_PAD, -LINK_PAD)
    closeBtn:SetFrameLevel(f:GetFrameLevel() + 2)
    local closeText = MakeFontString(closeBtn, "small")
    closeText:SetText("x")
    closeText:SetTextColor(unpack(STYLE.text_soft))
    closeText:SetJustifyH("CENTER")
    closeText:SetJustifyV("MIDDLE")
    closeText:SetAllPoints(closeBtn)
    closeBtn:SetScript("OnEnter", function()
        closeText:SetTextColor(unpack(STYLE.text_color))
    end)
    closeBtn:SetScript("OnLeave", function()
        closeText:SetTextColor(unpack(STYLE.text_soft))
    end)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Hint label
    local hint = MakeFontString(f, "tiny")
    hint:SetTextColor(0.45, 0.45, 0.45, 1)
    hint:SetText("Press Ctrl+C to copy")
    hint:SetJustifyH("LEFT")
    hint:SetPoint("TOPLEFT", f, "TOPLEFT", LINK_PAD, -LINK_PAD)

    -- Input frame (same dark-box + focus-border pattern as CreateTextEntry)
    local inputFrame = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, f)
    inputFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     LINK_PAD,  -(LINK_PAD + 18 + 4))
    inputFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -LINK_PAD, LINK_PAD)
    inputFrame:SetFrameLevel(f:GetFrameLevel() + 1)
    MakeControlBackdrop(inputFrame)

    local focusBorder = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, inputFrame)
    focusBorder:SetAllPoints(inputFrame)
    focusBorder:SetFrameLevel(inputFrame:GetFrameLevel() + 1)
    focusBorder:EnableMouse(false)
    focusBorder:SetBackdrop({ edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    PaintAccent(focusBorder, "SetBackdropBorderColor", 0)

    local edit = CreateFrame("EditBox", nil, inputFrame)
    edit:SetPoint("TOPLEFT",     inputFrame, "TOPLEFT",     4, -2)
    edit:SetPoint("BOTTOMRIGHT", inputFrame, "BOTTOMRIGHT", -4,  2)
    edit:SetFont(ValidateFont(NSI:GetUIFontPath()), STYLE.type.small, NSI:GetWindowFontFlags())
    edit:SetTextColor(unpack(STYLE.text_color))
    labelRegistry[edit] = 12
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
--  CreateSpellIDList
--
--  A spell-ID picker: an add row (text entry + Add button) followed
--  by one row per spell (icon, name, remove button).  Rows are pooled,
--  so Refresh() re-dresses them for another key instead of building
--  new frames; pair it with a WidgetHost Custom descriptor.
--
--  Params
--    parent – WoW frame
--    width  – number
--    cfg    – table
--      getList(key)    → array of spell IDs
--      add(key, text)  add the IDs typed into the entry
--      remove(key, id) remove one spell ID
--      onChange()      called after an add/remove, so the owning panel refreshes
--      defaultIcon     texture for unknown spells (default 134400)
--
--  Returned object
--    .frame         container Frame
--    :Refresh(key) → height   show the list for `key`
-- ============================================================
local SPELL_ROW_H = 20

local function SpellRowHover(self)
    local row = self.spellRow or self
    if row:IsMouseOver() then row.highlight:Show() else row.highlight:Hide() end
end

local function SpellIconEnter(self)
    SpellRowHover(self)
    local spellID = self.spellRow.spellID
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(spellID)
    if GameTooltip:NumLines() == 0 then
        GameTooltip:SetText("Spell ID: " .. spellID)
    end
    GameTooltip:Show()
end

local function SpellIconLeave(self)
    SpellRowHover(self)
    GameTooltip:Hide()
end

local function CreateSpellIDList(parent, width, cfg)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width)

    local list = { frame = frame, rows = {} }
    local rows = list.rows
    local defaultIcon = cfg.defaultIcon or 134400

    local input = CreateTextEntry(frame, nil, nil, nil, width - 70, 22)
    input:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    local function AddFromInput()
        local text = strtrim(input.editBox:GetText() or "")
        if text == "" then return end
        cfg.add(list.key, text)
        input.editBox:SetText("")
        cfg.onChange()
    end
    input.editBox:SetScript("OnEnterPressed", function(self) AddFromInput(); self:ClearFocus() end)

    local addButton = CreateLocalizedSubButton(frame, "Add", AddFromInput, 54)
    addButton:SetPoint("LEFT", input.frame, "RIGHT", 6, 0)

    local function RemoveClicked(self)
        cfg.remove(list.key, self.spellRow.spellID)
        cfg.onChange()
    end

    local function NewRow()
        local row = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, frame)
        row:SetHeight(SPELL_ROW_H)
        row:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] })
        row:SetBackdropColor(unpack(STYLE.surface_inset_soft))
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(0.08, 0.32, 0.40, 0.45)
        row.highlight:Hide()
        row:EnableMouse(true)
        row:SetScript("OnEnter", SpellRowHover)
        row:SetScript("OnLeave", SpellRowHover)

        local iconFrame = CreateFrame("Frame", nil, row)
        iconFrame:SetSize(16, 16)
        iconFrame:SetPoint("LEFT", row, "LEFT", 3, 0)
        iconFrame:EnableMouse(true)
        iconFrame.spellRow = row
        iconFrame:SetScript("OnEnter", SpellIconEnter)
        iconFrame:SetScript("OnLeave", SpellIconLeave)
        row.icon = iconFrame:CreateTexture(nil, "ARTWORK")
        row.icon:SetAllPoints()
        row.icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)

        row.label = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.label, "small", "")
        row.label:SetPoint("LEFT", iconFrame, "RIGHT", 6, 0)
        row.label:SetPoint("RIGHT", row, "RIGHT", -24, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)

        local removeBtn = CreateFrame("Button", nil, row)
        removeBtn:SetSize(14, 14)
        removeBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        removeBtn:SetNormalTexture(ICON_PATH .. "x.png")
        removeBtn:SetHighlightTexture(ICON_PATH .. "x.png")
        removeBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.danger))
        removeBtn.spellRow = row
        removeBtn:SetScript("OnEnter", SpellRowHover)
        removeBtn:SetScript("OnLeave", SpellRowHover)
        removeBtn:SetScript("OnClick", RemoveClicked)
        return row
    end

    function list:Refresh(key)
        self.key = key
        local ids = cfg.getList(key) or {}
        local y = 30
        for i, spellID in ipairs(ids) do
            local row = rows[i]
            if not row then
                row = NewRow()
                rows[i] = row
            end
            row.spellID = spellID
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -y)
            row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -y)
            row.highlight:Hide()
            local spell = C_Spell.GetSpellInfo(spellID)
            if spell then
                row.icon:SetTexture(spell.iconID or defaultIcon)
                row.label:SetText(spell.name .. "  |cFF808080(" .. spellID .. ")|r")
            else
                row.icon:SetTexture(defaultIcon)
                row.label:SetText(NSI:Loc("|cFFFF4040Unknown spell|r") .. "  |cFF808080(" .. spellID .. ")|r")
            end
            row:Show()
            y = y + SPELL_ROW_H
        end
        for i = #ids + 1, #rows do rows[i]:Hide() end

        if #ids == 0 then
            if not self.empty then
                self.empty = frame:CreateFontString(nil, "OVERLAY")
                NSI:SetUIFont(self.empty, "small", "")
                self.empty:SetTextColor(unpack(STYLE.text_hint))
                RegisterLocalizedText(self.empty, "No spell IDs added yet.")
            end
            self.empty:ClearAllPoints()
            self.empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -y - 2)
            self.empty:Show()
            y = y + SPELL_ROW_H
        elseif self.empty then
            self.empty:Hide()
        end

        frame:SetHeight(y)
        return y
    end

    return list
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
    EnableSmoothScroll  = EnableSmoothScroll,
    CreateScrollBox     = CreateScrollBox,
    ReskinScrollbar     = ReskinScrollbar,
    BuildWidgets        = BuildWidgets,
    CreateWidgetHost    = CreateWidgetHost,
    CreateCardHost      = CreateCardHost,
    CreateSectionCard   = CreateSectionCard,
    CardPad             = MENU_CARD_PAD,
    CardGap             = MENU_SECTION_GAP,
    BuildMenu           = BuildMenu,
    CreateSpellIDList   = CreateSpellIDList,
    RefreshFonts        = RefreshFonts,
    CreateDialog        = CreateDialog,
    CreateInputDialog   = CreateInputDialog,
    CreateTextBoxDialog = CreateTextBoxDialog,
    FadeTo              = FadeTo,
    StyleRow            = StyleRow,
    CreateFrame         = CreateStyledFrame,
    ShowContextMenu     = ShowContextMenu,
    ShowContextMenuAtFrame = ShowContextMenuAtFrame,
    CreateLink          = CreateLink,
    Solid               = NSI.UI.Pixel.Solid,
    Border              = NSI.UI.Pixel.Border,
    STYLE               = STYLE,
    registry            = componentRegistry,
    Dialogs             = Dialogs,
}
