local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local L = DF.Language.GetLanguageTable(addonId)
local Core = NSI.UI.Core

local function T(key)
    return DF.Language.GetText(addonId, key, true) or L[key] or key
end

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
    for _, v in ipairs(dirs) do t[#t+1] = {label=T(v), value=v} end
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

local function CircleTextureValues()
    return {
        {label="2 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_2px.png]]},
        {label="5 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_5px.png]]},
        {label="8 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_8px.png]]},
        {label="10 px", value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_10px.png]]},
        {label="15 px", value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_15px.png]]},
    }
end

local function CircleTextPositionValues()
    return {
        {label=T("Top"), value="Top"},
        {label=T("Bottom"), value="Bottom"},
        {label=T("Center"), value="Center"},
        {label=T("Left"), value="Left"},
        {label=T("Right"), value="Right"},
    }
end

local function FontFlagValues()
    return Core.build_fontflag_options()
end

-- ---------------------------------------------------------------
--  Returns the ordered widget-definition table for each type.
--  All ranges and fields are aligned with Reminders.lua.
-- ---------------------------------------------------------------
local function GetWidgetDefs(settingsName)
    local S = NSRT.ReminderSettings[settingsName]

    local function R(key) return S[key] end
    local function RefreshFrames()
        if NSI.IsInPreview then NSI:SpawnPreviewReminders() end
        NSI:UpdateExistingFrames()
    end
    local function W(key,v)
        S[key] = v
        RefreshFrames()
    end
    local function WGrow(_, v)
        S.GrowDirection = v
        RefreshFrames()
    end

    -- Color helpers: storage is a {r,g,b,a} table; our ColorPicker needs 4 returns.
    -- BuildWidgets passes NSI as the first argument to all callbacks.
    local function GetColor()
        local c = S.textColors
        if not c then return 1, 1, 1, 1 end
        return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
    end
    local function GetBorderColor()
        local c = S.borderColors
        return c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1
    end
    local function SetColor(_, r, g, b, a) W("textColors", {r, g, b, a}) end
    local function SetBorderColor(_, r, g, b, a) W("borderColors", {r, g, b, a}) end
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
        return {Type="Dropdown", label=T("Grow Direction"),
                get=function() return R("GrowDirection") end,
                set=WGrow,
                values=GrowValues(withLR)}
    end

    if settingsName == "IconSettings" then
        return {
            DDGrow(true),
            Slider(T("Width"),              "Width",         20,   200),
            Slider(T("Height"),             "Height",        20,   200),
            Slider(T("Spacing"),            "Spacing",       -5,   20),
            Slider(T("Sticky Duration"),    "Sticky",        0,    30),
            DD    (T("Font"),               "Font",          MediaValuesFn()),
            DD    (T("Font Outline"),       "FontFlags",     FontFlagValues),
            Slider(T("Font Size"),          "FontSize",      5,    200),
            Slider(T("Timer Font Size"),    "TimerFontSize", 5,    200),
            Slider(T("Decimals Threshold"), "Decimals",      0,    10),
            Slider(T("Glow Threshold"),     "Glow",          0,    30),
            Slider(T("Zoom"),               "Zoom",          0,    100),
            Slider(T("Text X Offset"),      "xTextOffset",   -500, 500),
            Slider(T("Text Y Offset"),      "yTextOffset",   -500, 500),
            Slider(T("Timer X"),            "xTimer",        -100, 100),
            Slider(T("Timer Y"),            "yTimer",        -100, 100),
            {Type="Color", label=T("Text Color"), get=GetColor, set=SetColor},
            {Type="Color", label=T("Border Color"), get=GetBorderColor, set=SetBorderColor},
            Chk   (T("Right-Aligned Text"), "RightAlignedText"),
            Chk   (T("Hide Timer Text"),    "HideTimerText"),
            Chk   (T("Hide Swipe"),         "HideSwipe"),
        }

    elseif settingsName == "BarSettings" then
        local function GetBarFillColor()
            local c = S.barColors
            if not c then return 1, 0, 0, 1 end
            return c[1] or 1, c[2] or 0, c[3] or 0, c[4] or 1
        end
        local function GetBarBackgroundColor()
            local c = S.backgroundColors
            return c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0.8
        end
        local function SetBarFillColor(_, r, g, b, a) W("barColors", {r, g, b, a}) end
        local function SetBarBackgroundColor(_, r, g, b, a) W("backgroundColors", {r, g, b, a}) end
        return {
            DDGrow(false),
            Slider(T("Width"),              "Width",         80,   500),
            Slider(T("Height"),             "Height",        10,   100),
            Slider(T("Spacing"),            "Spacing",       -5,   20),
            Slider(T("Sticky Duration"),    "Sticky",        0,    30),
            DD    (T("Texture"),            "Texture",       MediaValuesFn(true)),
            DD    (T("Font"),               "Font",          MediaValuesFn()),
            DD    (T("Font Outline"),       "FontFlags",     FontFlagValues),
            Slider(T("Font Size"),          "FontSize",      5,    200),
            Slider(T("Timer Font Size"),    "TimerFontSize", 5,    200),
            Slider(T("Decimals Threshold"), "Decimals",      0,    10),
            {Type="Color", label=T("Bar Fill Color"),  get=GetBarFillColor, set=SetBarFillColor},
            {Type="Color", label=T("Bar Background Color"), get=GetBarBackgroundColor, set=SetBarBackgroundColor},
            {Type="Color", label=T("Bar Text Color"),  get=GetColor,        set=SetColor},
            {Type="Color", label=T("Border Color"), get=GetBorderColor, set=SetBorderColor},
            Slider(T("Icon X Offset"),      "xIcon",         -100, 100),
            Slider(T("Icon Y Offset"),      "yIcon",         -100, 100),
            Slider(T("Text X Offset"),      "xTextOffset",   -500, 500),
            Slider(T("Text Y Offset"),      "yTextOffset",   -500, 500),
            Slider(T("Timer X"),            "xTimer",        -100, 100),
            Slider(T("Timer Y"),            "yTimer",        -100, 100),
            Chk   (T("Hide Timer Text"),    "HideTimerText"),
        }

    elseif settingsName == "TextSettings" then
        return {
            DDGrow(false),
            DD    (T("Font"),               "Font",          MediaValuesFn()),
            DD    (T("Font Outline"),       "FontFlags",     FontFlagValues),
            Slider(T("Font Size"),          "FontSize",      5,  200),
            Slider(T("Decimals Threshold"), "Decimals",      0,    10),
            {Type="Color", label=T("Text Color"), get=GetColor, set=SetColor},
            Slider(T("Spacing"),            "Spacing",       -5, 20),
            Slider(T("Sticky Duration"),    "Sticky",        0,  30),
            Chk   (T("Center Aligned"),     "CenterAligned"),
            Chk   (T("Hide Timer Text"),    "HideTimerText"),
        }

    elseif settingsName == "CircleSettings" then
        local function GetRingColor()
            local c = S.ringColors
            if not c then return 1, 1, 1, 1 end
            return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
        end
        local function SetRingColor(_, r, g, b, a) W("ringColors", {r, g, b, a}) end
        return {
            DDGrow(true),
            Slider(T("Size"),               "Size",          40,  200),
            Slider(T("Spacing"),            "Spacing",       -50, 100),
            DD    (T("Texture"),            "Texture",       CircleTextureValues),
            DD    (T("Font"),               "Font",          MediaValuesFn()),
            DD    (T("Font Outline"),       "FontFlags",     FontFlagValues),
            Slider(T("Font Size"),          "FontSize",      5,   80),
            DD    (T("Text Position"),       "TextPosition",  CircleTextPositionValues),
            Slider(T("Text X Offset"),      "xTextOffset",   -500, 500),
            Slider(T("Text Y Offset"),      "yTextOffset",   -500, 500),
            Slider(T("Decimals Threshold"), "Decimals",      0,    10),
            Slider(T("Sticky Duration"),    "Sticky",        0,   30),
            {Type="Color", label=T("Text Color"),  get=GetColor,     set=SetColor},
            {Type="Color", label=T("Ring Color"),  get=GetRingColor, set=SetRingColor},
            Chk   (T("Show Background Ring"), "showBackground"),
            Chk   (T("Hide Timer Text"),    "HideTimerText"),
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
local anchorSettingsWindows = {}

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

local function RebuildWindowContent(win, settingsName, rowW)
    if win.Content then
        win.Content:Hide()
        win.Content:SetParent(nil)
    end

    if win.Title then
        win.Title:SetText(T(settingsName:gsub("Settings", " Settings")))
    end

    local content = CreateFrame("Frame", nil, win)
    content:SetPoint("TOPLEFT", win, "TOPLEFT", PAD_X, -PAD_TOP)
    content:SetWidth(rowW)

    local contentH = NSI.UI.Components.BuildWidgets(content, GetWidgetDefs(settingsName), rowW)
    content:SetHeight(contentH)
    win:SetHeight(PAD_TOP + contentH + 8)
    win.Content = content
    win.LanguageId = NSI:GetSelectedLanguage()
end

function NSI:RefreshAnchorSettingsWindows()
    for win in pairs(anchorSettingsWindows) do
        if win and win.SettingsName and win.RowWidth then
            RebuildWindowContent(win, win.SettingsName, win.RowWidth)
        end
    end
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
            win.RowWidth = win:GetWidth() - PAD_X * 2
            if win.LanguageId ~= NSI:GetSelectedLanguage() then
                RebuildWindowContent(win, settingsName, win.RowWidth)
            end
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
    NSI:SetUIFont(title, 11, "")
    title:SetTextColor(0, 1, 1, 0.85)
    title:SetText(T(settingsName:gsub("Settings", " Settings")))
    title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD_X, -7)
    win.Title = title

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

    win.SettingsName = settingsName
    win.RowWidth = rowW
    anchorSettingsWindows[win] = true
    RebuildWindowContent(win, settingsName, rowW)

    PositionSettingsWindow(win, moverFrame, settingsName)
    win:Show()
    moverFrame.SettingsWindow = win
end
