local _, NSI = ...
local DF = _G["DetailsFramework"]

-- ============================================================
--  Per-anchor-type settings windows
--  Each mover frame (Icons/Bars/Texts/Circles) gets a gear
--  button that opens an inline popup built with DF:BuildMenu.
-- ============================================================

local function MakeMediaOptions(settingsName, key, isTexture)
    local list = NSI.LSM:List(isTexture and "statusbar" or "font")
    local t = {}
    for i, name in ipairs(list) do
        tinsert(t, {
            label = name, value = i,
            onclick = function(_, _, value)
                NSRT.ReminderSettings[settingsName][key] = list[value]
                NSI:UpdateExistingFrames()
            end,
        })
    end
    return t
end

local function MakeGrowOptions(settingsName, withLR)
    local list = withLR and {"Up","Down","Left","Right"} or {"Up","Down"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v, value = i,
            onclick = function(_, _, value)
                NSRT.ReminderSettings[settingsName].GrowDirection = list[value]
                NSI:UpdateExistingFrames()
                NSI:ArrangeStates(
                    settingsName == "IconSettings"   and "Icons"   or
                    settingsName == "BarSettings"    and "Bars"    or
                    settingsName == "TextSettings"   and "Texts"   or
                    settingsName == "CircleSettings" and "Circles" or nil
                )
            end,
        })
    end
    return t
end

-- ---------------------------------------------------------------
--  Returns the DF:BuildMenu-compatible options table for each type
-- ---------------------------------------------------------------
local function GetOptionsTable(settingsName)
    local function R(key) return NSRT.ReminderSettings[settingsName][key] end
    local function W(key, v) NSRT.ReminderSettings[settingsName][key] = v NSI:UpdateExistingFrames() end
    local function S(key, min, max, name, desc)
        return {type="range", name=name or key, desc=desc or name or key,
                get=function() return R(key) end,
                set=function(_,_,v) W(key,v) end, min=min, max=max}
    end
    local function B(key, name)
        return {type="toggle", boxfirst=true, name=name or key, desc=name or key,
                get=function() return R(key) end,
                set=function(_,_,v) W(key,v) end}
    end

    if settingsName == "IconSettings" then
        return {
            {type="select", name="Grow Direction", desc="Grow Direction",
             get=function() return R("GrowDirection") end,
             values=function() return MakeGrowOptions("IconSettings", true) end},
            S("Width",  20, 200, "Width"),
            S("Height", 20, 200, "Height"),
            S("Spacing", -50, 100, "Spacing"),
            {type="select", name="Font", desc="Font",
             get=function() return R("Font") end,
             values=function() return MakeMediaOptions("IconSettings","Font") end},
            S("FontSize",      5, 150, "Font Size"),
            S("TimerFontSize", 5, 150, "Timer Font Size"),
            S("Glow", 0, 30, "Glow Threshold"),
            S("xTextOffset", -500, 500, "Text X Offset"),
            S("yTextOffset", -500, 500, "Text Y Offset"),
            S("xTimer", -100, 100, "Timer X"),
            S("yTimer", -100, 100, "Timer Y"),
            B("RightAlignedText", "Right-Aligned Text"),
        }
    elseif settingsName == "BarSettings" then
        return {
            {type="select", name="Grow Direction", desc="Grow Direction",
             get=function() return R("GrowDirection") end,
             values=function() return MakeGrowOptions("BarSettings", false) end},
            S("Width",  100, 600, "Width"),
            S("Height",  10, 100, "Height"),
            S("Spacing", -50, 100, "Spacing"),
            {type="select", name="Texture", desc="Bar Texture",
             get=function() return R("Texture") end,
             values=function() return MakeMediaOptions("BarSettings","Texture", true) end},
            {type="select", name="Font", desc="Font",
             get=function() return R("Font") end,
             values=function() return MakeMediaOptions("BarSettings","Font") end},
            S("FontSize",      5, 150, "Font Size"),
            S("TimerFontSize", 5, 150, "Timer Font Size"),
            S("xIcon", -100, 100, "Icon X Offset"),
            S("yIcon", -100, 100, "Icon Y Offset"),
            S("xTextOffset", -500, 500, "Text X Offset"),
            S("yTextOffset", -500, 500, "Text Y Offset"),
            S("xTimer", -100, 100, "Timer X"),
            S("yTimer", -100, 100, "Timer Y"),
        }
    elseif settingsName == "TextSettings" then
        return {
            {type="select", name="Grow Direction", desc="Grow Direction",
             get=function() return R("GrowDirection") end,
             values=function() return MakeGrowOptions("TextSettings", false) end},
            {type="select", name="Font", desc="Font",
             get=function() return R("Font") end,
             values=function() return MakeMediaOptions("TextSettings","Font") end},
            S("FontSize",  5, 150, "Font Size"),
            S("Spacing", -50, 100, "Spacing"),
            B("CenterAligned", "Center Aligned"),
        }
    elseif settingsName == "CircleSettings" then
        return {
            {type="select", name="Grow Direction", desc="Grow Direction",
             get=function() return R("GrowDirection") end,
             values=function() return MakeGrowOptions("CircleSettings", true) end},
            S("Size",      40, 200, "Size"),
            S("Thickness",  2,  50, "Thickness"),
            S("Spacing",  -50, 100, "Spacing"),
            {type="select", name="Font", desc="Font",
             get=function() return R("Font") end,
             values=function() return MakeMediaOptions("CircleSettings","Font") end},
            S("FontSize", 5, 80, "Font Size"),
            B("showBackground", "Show Background Ring"),
        }
    end
    return {}
end

-- ---------------------------------------------------------------
--  Positions the settings window above or below the mover
--  depending on the current GrowDirection for that anchor type
-- ---------------------------------------------------------------
local function PositionSettingsWindow(win, moverFrame, settingsName)
    local gd = NSRT.ReminderSettings[settingsName] and NSRT.ReminderSettings[settingsName].GrowDirection
    win:ClearAllPoints()
    if gd == "Down" then
        win:SetPoint("BOTTOMLEFT", moverFrame, "TOPLEFT",    0,  3)
    else
        win:SetPoint("TOPLEFT",    moverFrame, "BOTTOMLEFT", 0, -3)
    end
end

-- ---------------------------------------------------------------
--  Creates (or shows) the settings popup for a given mover frame
-- ---------------------------------------------------------------
function NSI:CreateAnchorSettingsWindow(moverFrame, settingsName)
    if moverFrame.SettingsWindow then
        if moverFrame.SettingsWindow:IsShown() then
            moverFrame.SettingsWindow:Hide()
        else
            PositionSettingsWindow(moverFrame.SettingsWindow, moverFrame, settingsName)
            moverFrame.SettingsWindow:Show()
        end
        return
    end

    local optTable  = GetOptionsTable(settingsName)
    local winHeight = 400
    local winWidth  = moverFrame:GetWidth()

    local win = CreateFrame("Frame", "NSRTAnchorWin_" .. settingsName, moverFrame, "BackdropTemplate")
    win:SetSize(winWidth, winHeight)
    win:SetFrameStrata("DIALOG")
    win:SetFrameLevel(moverFrame:GetFrameLevel() + 10)
    win:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    win:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    win:SetBackdropBorderColor(0, 1, 1, 0.9)

    PositionSettingsWindow(win, moverFrame, settingsName)

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

    -- Build the options menu inside the window
    local txt_tmpl = DF:GetTemplate("font",     "OPTIONS_FONT_TEMPLATE")
    local dd_tmpl  = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
    local sw_tmpl  = DF:GetTemplate("switch",   "OPTIONS_CHECKBOX_TEMPLATE")
    local sl_tmpl  = DF:GetTemplate("slider",   "OPTIONS_SLIDER_TEMPLATE")
    local bt_tmpl  = DF:GetTemplate("button",   "OPTIONS_BUTTON_TEMPLATE")

    DF:BuildMenu(win, optTable, 5, -5, winHeight - 10, false,
        txt_tmpl, dd_tmpl, sw_tmpl, false, sl_tmpl, bt_tmpl, nil)

    win:Show()
    moverFrame.SettingsWindow = win
end
