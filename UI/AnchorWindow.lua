local _, NSI = ...

-- ============================================================
--  Per-anchor-type settings windows
--  Each mover frame gets a gear button that opens a popup
--  built from a widget definition table via BuildWidgets.
-- ============================================================

local TYPE_MAP = {
    IconSettings   = "Icons",
    BarSettings    = "Bars",
    TextSettings   = "Texts",
    CircleSettings = "Circles",
}

-- Returns {label, value} pairs for grow-direction dropdowns.
-- value == label so BuildWidgets' lookup works with the stored string.
local function GrowValues(withLR)
    local dirs = withLR and {"Up","Down","Left","Right"} or {"Up","Down"}
    local t = {}
    for _, v in ipairs(dirs) do t[#t+1] = {label=v, value=v} end
    return t
end

-- Returns a lazy function that builds {label, value} pairs from LSM.
local function MediaValuesFn(isTexture)
    return function()
        local list = NSI.LSM:List(isTexture and "statusbar" or "font")
        local t = {}
        for _, name in ipairs(list) do t[#t+1] = {label=name, value=name} end
        return t
    end
end

-- ---------------------------------------------------------------
--  Returns the ordered widget-definition table for each type.
--  All ranges and fields are aligned with Reminders.lua.
-- ---------------------------------------------------------------
local function GetWidgetDefs(settingsName)
    local S = NSRT.ReminderSettings[settingsName]

    local function R(key) return S[key] end
    local function W(key,v) S[key] = v ; NSI:UpdateExistingFrames() end
    local function WGrow(_, v)
        S.GrowDirection = v ; NSI:UpdateExistingFrames()
        NSI:ArrangeStates(TYPE_MAP[settingsName])
    end

    -- Color helpers: storage is a {r,g,b,a} table; our ColorPicker needs 4 returns.
    -- BuildWidgets passes NSI as the first argument to all callbacks.
    local function GetColor()
        local c = S.textColors
        if not c then return 1, 1, 1, 1 end
        return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
    end
    local function SetColor(_, r, g, b, a) W("textColors", {r, g, b, a}) end
    -- Shorthand constructors
    -- Note: BuildWidgets calls get(NSI) and set(NSI, value), so closures accept _ for NSI.
    local function Slider(label, key, mn, mx)
        return {Type="Slider", label=label,
                get=function()    return R(key) end,
                set=function(_, v) W(key, v) end,
                min=mn, max=mx}
    end
    local function Chk(label, key)
        return {Type="Checkbox", label=label,
                get=function()    return R(key) end,
                set=function(_, v) W(key, v) end}
    end
    local function DD(label, key, valsFn)
        return {Type="Dropdown", label=label,
                get=function()    return R(key) end,
                set=function(_, v) W(key, v) end,
                values=valsFn}
    end
    local function DDGrow(withLR)
        return {Type="Dropdown", label="Grow Direction",
                get=function() return R("GrowDirection") end,
                set=WGrow,
                values=GrowValues(withLR)}
    end

    if settingsName == "IconSettings" then
        return {
            DDGrow(true),
            Slider("Width",           "Width",         20,   200),
            Slider("Height",          "Height",        20,   200),
            Slider("Spacing",         "Spacing",       -5,   20),
            Slider("Sticky Duration", "Sticky",        0,    30),
            DD    ("Font",            "Font",          MediaValuesFn()),
            Slider("Font Size",       "FontSize",      5,    200),
            Slider("Timer Font Size", "TimerFontSize", 5,    200),
            Slider("Glow Threshold",  "Glow",          0,    30),
            Slider("Zoom",            "Zoom",          0,    100),
            Slider("Text X Offset",   "xTextOffset",   -500, 500),
            Slider("Text Y Offset",   "yTextOffset",   -500, 500),
            Slider("Timer X",         "xTimer",        -100, 100),
            Slider("Timer Y",         "yTimer",        -100, 100),
            {Type="Color", label="Text Color", get=GetColor, set=SetColor},
            Chk   ("Right-Aligned Text", "RightAlignedText"),
            Chk   ("Hide Timer Text", "HideTimerText"),
        }

    elseif settingsName == "BarSettings" then
        local function GetBarFillColor()
            local c = S.barColors
            if not c then return 1, 0, 0, 1 end
            return c[1] or 1, c[2] or 0, c[3] or 0, c[4] or 1
        end
        local function SetBarFillColor(_, r, g, b, a) W("barColors", {r, g, b, a}) end
        return {
            DDGrow(false),
            Slider("Width",           "Width",         80,   500),
            Slider("Height",          "Height",        10,   100),
            Slider("Spacing",         "Spacing",       -5,   20),
            Slider("Sticky Duration", "Sticky",        0,    30),
            DD    ("Texture",         "Texture",       MediaValuesFn(true)),
            DD    ("Font",            "Font",          MediaValuesFn()),
            Slider("Font Size",       "FontSize",      5,    200),
            Slider("Timer Font Size", "TimerFontSize", 5,    200),
            {Type="Color", label="Bar Fill Color",  get=GetBarFillColor, set=SetBarFillColor},
            {Type="Color", label="Bar Text Color",  get=GetColor,        set=SetColor},
            Slider("Icon X Offset",   "xIcon",         -100, 100),
            Slider("Icon Y Offset",   "yIcon",         -100, 100),
            Slider("Text X Offset",   "xTextOffset",   -500, 500),
            Slider("Text Y Offset",   "yTextOffset",   -500, 500),
            Slider("Timer X",         "xTimer",        -100, 100),
            Slider("Timer Y",         "yTimer",        -100, 100),
            Chk   ("Hide Timer Text", "HideTimerText"),
        }

    elseif settingsName == "TextSettings" then
        return {
            DDGrow(false),
            DD    ("Font",          "Font",          MediaValuesFn()),
            Slider("Font Size",     "FontSize",      5,  200),
            {Type="Color", label="Text Color", get=GetColor, set=SetColor},
            Slider("Spacing",       "Spacing",       -5, 20),
            Slider("Sticky Duration", "Sticky",      0,  30),
            Chk   ("Center Aligned","CenterAligned"),
            Chk   ("Hide Timer Text", "HideTimerText"),
        }

    elseif settingsName == "CircleSettings" then
        local function GetRingColor()
            local c = S.ringcolors
            if not c then return 1, 1, 1, 1 end
            return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
        end
        local function SetRingColor(_, r, g, b, a) W("ringcolors", {r, g, b, a}) end
        return {
            DDGrow(true),
            Slider("Size",      "Size",          40,  200),
            Slider("Spacing",   "Spacing",       -50, 100),
            DD    ("Font",      "Font",          MediaValuesFn()),
            Slider("Font Size", "FontSize",      5,   80),
            Slider("Sticky Duration", "Sticky",  0,   30),
            {Type="Color", label="Text Color",  get=GetColor,     set=SetColor},
            {Type="Color", label="Ring Color",  get=GetRingColor, set=SetRingColor},
            Chk   ("Show Background Ring", "showBackground"),
            Chk   ("Hide Timer Text", "HideTimerText"),
        }
    end

    return {}
end

-- ---------------------------------------------------------------
--  Window positioning
-- ---------------------------------------------------------------
local DRAG_BORDER_INSET = 8
local MIN_WIN_W         = 220
local PAD_X             = 8
local PAD_TOP           = 26   -- room for title + close button

local function PositionSettingsWindow(win, moverFrame, settingsName)
    local gd = NSRT.ReminderSettings[settingsName]
             and NSRT.ReminderSettings[settingsName].GrowDirection
    win:ClearAllPoints()
    if gd == "Down" then
        win:SetPoint("BOTTOMLEFT", moverFrame, "TOPLEFT",    -DRAG_BORDER_INSET,  DRAG_BORDER_INSET + 3)
    else
        win:SetPoint("TOPLEFT",    moverFrame, "BOTTOMLEFT", -DRAG_BORDER_INSET, -(DRAG_BORDER_INSET + 3))
    end
end

local function GetAnchorWindowWidth(moverFrame)
    return math.max(MIN_WIN_W, moverFrame:GetWidth() + DRAG_BORDER_INSET * 2)
end

-- ---------------------------------------------------------------
--  Creates (or shows/hides) the settings popup for a mover frame
-- ---------------------------------------------------------------
function NSI:CreateAnchorSettingsWindow(moverFrame, settingsName)
    if moverFrame.SettingsWindow then
        if moverFrame.SettingsWindow:IsShown() then
            moverFrame.SettingsWindow:Hide()
        else
            local win = moverFrame.SettingsWindow
            win:SetWidth(GetAnchorWindowWidth(moverFrame))
            PositionSettingsWindow(win, moverFrame, settingsName)
            win:Show()
        end
        return
    end

    local winWidth = GetAnchorWindowWidth(moverFrame)
    local rowW     = winWidth - PAD_X * 2

    local win = CreateFrame("Frame", "NSRTAnchorWin_" .. settingsName, moverFrame, "BackdropTemplate")
    win:SetSize(winWidth, 100)   -- height filled in below
    win:SetFrameStrata("DIALOG")
    win:SetFrameLevel(moverFrame:GetFrameLevel() + 10)
    win:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    win:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    win:SetBackdropBorderColor(0, 1, 1, 0.9)

    -- Title
    local title = win:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    title:SetTextColor(0, 1, 1, 0.85)
    title:SetText(settingsName:gsub("Settings", " Settings"))
    title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD_X, -7)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, win)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -3, -3)
    closeBtn:SetNormalFontObject("GameFontNormalSmall")
    closeBtn:SetText("×")
    closeBtn:GetFontString():SetTextColor(0.7, 0.7, 0.7)
    closeBtn:SetScript("OnEnter", function(self) self:GetFontString():SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function(self) self:GetFontString():SetTextColor(0.7, 0.7, 0.7) end)
    closeBtn:SetScript("OnClick", function() win:Hide() end)

    -- Content frame: shifted past the title so BuildWidgets starts from (0,0)
    local content = CreateFrame("Frame", nil, win)
    content:SetPoint("TOPLEFT", win, "TOPLEFT", PAD_X, -PAD_TOP)
    content:SetWidth(rowW)

    local contentH = NSI.UI.Components.BuildWidgets(content, GetWidgetDefs(settingsName), rowW)
    content:SetHeight(contentH)
    win:SetHeight(PAD_TOP + contentH + 8)

    PositionSettingsWindow(win, moverFrame, settingsName)
    win:Show()
    moverFrame.SettingsWindow = win
end
