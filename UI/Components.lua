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

local function CreateButton(parent, text, onClick, width, height, name, icon)
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
    labelRegistry[#labelRegistry + 1] = {label = label, size = STYLE.text_size}

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
--  Export
-- ============================================================
NSI.UI = NSI.UI or {}
NSI.UI.Components = {
    CreateButton  = CreateButton,
    RefreshFonts  = RefreshFonts,
    STYLE         = STYLE,
}
