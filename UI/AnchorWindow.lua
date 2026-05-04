local _, NSI = ...

-- ============================================================
--  Per-anchor-type settings windows
--  Each mover frame (Icons/Bars/Texts/Circles) gets a gear
--  button that opens a popup built with NSRT UI components.
-- ============================================================

local TYPE_MAP = {
    IconSettings   = "Icons",
    BarSettings    = "Bars",
    TextSettings   = "Texts",
    CircleSettings = "Circles",
}

local function GrowItems(settingsName, withLR)
    local dirs = withLR and {"Up","Down","Left","Right"} or {"Up","Down"}
    local t = {}
    for i, v in ipairs(dirs) do
        t[i] = {label=v, value=i, onclick=function(_,_,val)
            NSRT.ReminderSettings[settingsName].GrowDirection = dirs[val]
            NSI:UpdateExistingFrames()
            NSI:ArrangeStates(TYPE_MAP[settingsName])
        end}
    end
    return t
end

local function MediaItems(settingsName, key, isTexture)
    local list = NSI.LSM:List(isTexture and "statusbar" or "font")
    local t = {}
    for i, name in ipairs(list) do
        t[i] = {label=name, value=i, onclick=function(_,_,val)
            NSRT.ReminderSettings[settingsName][key] = list[val]
            NSI:UpdateExistingFrames()
        end}
    end
    return t
end

-- ---------------------------------------------------------------
--  Layout constants
-- ---------------------------------------------------------------
local PAD_X   = 8
local PAD_TOP = 26   -- room for title + close button
local ROW_H   = 22
local ROW_GAP = 4

-- Creates all controls inside win and returns the required window height.
local function BuildControls(win, settingsName, rowW)
    local C = NSI.UI.Components
    local function R(key) return NSRT.ReminderSettings[settingsName][key] end
    local function W(key, v) NSRT.ReminderSettings[settingsName][key] = v; NSI:UpdateExistingFrames() end

    local y = -PAD_TOP

    local function Place(ctrl)
        ctrl:SetPoint("TOPLEFT", win, "TOPLEFT", PAD_X, y)
        y = y - (ROW_H + ROW_GAP)
    end

    local function DD(label, key, getItems)
        Place(C.CreateDropdown(win, label, getItems, function() return R(key) end, rowW, ROW_H))
    end
    local function Num(label, key, min, max)
        Place(C.CreateTextEntry(win, label,
            function() return R(key) end,
            function(v) W(key, v) end,
            rowW, ROW_H, true, min, max))
    end
    local function Chk(label, key)
        Place(C.CreateCheckButton(win, label,
            function() return R(key) end,
            function(v) W(key, v) end,
            rowW, ROW_H))
    end

    if settingsName == "IconSettings" then
        DD ("Grow Direction",    "GrowDirection", function() return GrowItems("IconSettings", true) end)
        Num("Width",             "Width",          20, 200)
        Num("Height",            "Height",         20, 200)
        Num("Spacing",           "Spacing",       -50, 100)
        DD ("Font",              "Font",           function() return MediaItems("IconSettings", "Font") end)
        Num("Font Size",         "FontSize",         5, 150)
        Num("Timer Font Size",   "TimerFontSize",    5, 150)
        Num("Glow Threshold",    "Glow",             0,  30)
        Num("Text X Offset",     "xTextOffset",   -500, 500)
        Num("Text Y Offset",     "yTextOffset",   -500, 500)
        Num("Timer X",           "xTimer",        -100, 100)
        Num("Timer Y",           "yTimer",        -100, 100)
        Chk("Right-Aligned Text","RightAlignedText")
    elseif settingsName == "BarSettings" then
        DD ("Grow Direction",    "GrowDirection", function() return GrowItems("BarSettings", false) end)
        Num("Width",             "Width",         100, 600)
        Num("Height",            "Height",         10, 100)
        Num("Spacing",           "Spacing",       -50, 100)
        DD ("Texture",           "Texture",        function() return MediaItems("BarSettings", "Texture", true) end)
        DD ("Font",              "Font",           function() return MediaItems("BarSettings", "Font") end)
        Num("Font Size",         "FontSize",         5, 150)
        Num("Timer Font Size",   "TimerFontSize",    5, 150)
        Num("Icon X Offset",     "xIcon",         -100, 100)
        Num("Icon Y Offset",     "yIcon",         -100, 100)
        Num("Text X Offset",     "xTextOffset",   -500, 500)
        Num("Text Y Offset",     "yTextOffset",   -500, 500)
        Num("Timer X",           "xTimer",        -100, 100)
        Num("Timer Y",           "yTimer",        -100, 100)
    elseif settingsName == "TextSettings" then
        DD ("Grow Direction",    "GrowDirection", function() return GrowItems("TextSettings", false) end)
        DD ("Font",              "Font",           function() return MediaItems("TextSettings", "Font") end)
        Num("Font Size",         "FontSize",         5, 150)
        Num("Spacing",           "Spacing",        -50, 100)
        Chk("Center Aligned",    "CenterAligned")
    elseif settingsName == "CircleSettings" then
        DD ("Grow Direction",    "GrowDirection", function() return GrowItems("CircleSettings", true) end)
        Num("Size",              "Size",            40, 200)
        Num("Thickness",         "Thickness",        2,  50)
        Num("Spacing",           "Spacing",        -50, 100)
        DD ("Font",              "Font",           function() return MediaItems("CircleSettings", "Font") end)
        Num("Font Size",         "FontSize",         5,  80)
        Chk("Show Background Ring", "showBackground")
    end

    -- y is negative; subtract the trailing gap, add bottom padding
    return math.abs(y) - ROW_GAP + 8
end

-- ---------------------------------------------------------------
--  Window positioning
-- ---------------------------------------------------------------
local DRAG_BORDER_INSET = 8

local function PositionSettingsWindow(win, moverFrame, settingsName)
    local gd = NSRT.ReminderSettings[settingsName] and NSRT.ReminderSettings[settingsName].GrowDirection
    win:ClearAllPoints()
    if gd == "Down" then
        win:SetPoint("BOTTOMLEFT", moverFrame, "TOPLEFT",    -DRAG_BORDER_INSET,  DRAG_BORDER_INSET + 3)
    else
        win:SetPoint("TOPLEFT",    moverFrame, "BOTTOMLEFT", -DRAG_BORDER_INSET, -(DRAG_BORDER_INSET + 3))
    end
end

local function GetAnchorWindowWidth(moverFrame)
    return moverFrame:GetWidth() + DRAG_BORDER_INSET * 2
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

    win:SetHeight(BuildControls(win, settingsName, rowW))

    PositionSettingsWindow(win, moverFrame, settingsName)
    win:Show()
    moverFrame.SettingsWindow = win
end
