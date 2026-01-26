local _, NSI = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

-- Window dimensions
local window_width = 1050
local window_height = 600

-- Fonts
local expressway = [[Interface\AddOns\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]

-- Tabs configuration
local TABS_LIST = {
    { name = "General",   text = "General" },
    { name = "Nicknames", text = "Nicknames" },
    { name = "Versions",  text = "Versions" },
    { name = "SetupManager", text = "Setup Manager"},
    { name = "ReadyCheck", text = "Ready Check"},
    { name = "Reminders", text = "Reminders"},
    { name = "Reminders-Note", text = "Reminders-Note"},
    { name = "Assignments", text = "Assignments"},
    { name = "EncounterAlerts", text = "Encounter Alerts"},
    { name = "PrivateAura", text = "Private Auras"},
    { name = "Timeline", text = "Timeline"},
}

local authorsString = "By Reloe & Rav"

-- Templates
local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

-- Create main panel
local NSUI_panel_options = {
    UseStatusBar = true
}
local NSUI = DF:CreateSimplePanel(UIParent, window_width, window_height, "|cFF00FFFFNorthern Sky|r Raid Tools", "NSUI",
    NSUI_panel_options)
NSUI:SetPoint("CENTER")
NSUI:SetFrameStrata("HIGH")
DF:BuildStatusbarAuthorInfo(NSUI.StatusBar, _, "x |cFF00FFFFbird|r")
NSUI.StatusBar.discordTextEntry:SetText("https://discord.gg/3B6QHURmBy")

NSUI.OptionsChanged = {
    ["general"] = {},
    ["nicknames"] = {},
    ["versions"] = {},
}

-- Shared helper functions
local function build_media_options(typename, settingname, isTexture, isReminder, Personal)
    local list = NSI.LSM:List(isTexture and "statusbar" or "font")
    local t = {}
    for i, font in ipairs(list) do
        tinsert(t, {
            label = font,
            value = i,
            onclick = function(_, _, value)
                NSRT.ReminderSettings[typename][settingname] = list[value]
                if isReminder then
                    NSI:UpdateReminderFrame(false, true)
                else
                    NSI:UpdateExistingFrames()
                end
            end
        })
    end
    return t
end

local function build_growdirection_options(SettingName, Icons)
    local list = Icons and {"Up", "Down", "Left", "Right"} or {"Up", "Down"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                NSRT.ReminderSettings[SettingName]["GrowDirection"] = list[value]
                NSI:UpdateExistingFrames()
            end
        })
    end
    return t
end

local function build_PAgrowdirection_options(SettingName, SecondaryName)
    local list = {"LEFT", "RIGHT", "UP", "DOWN"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                NSRT[SettingName][SecondaryName] = list[value]
                NSI:UpdatePADisplay(SettingName == "PASettings", SettingName == "PATankSettings")
            end
        })
    end
    return t
end

local function build_raidframeicon_options()
    local list = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                NSRT.ReminderSettings.UnitIconSettings.Position = list[value]
                NSI:UpdateExistingFrames()
            end
        })
    end
    return t
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Core = {
    NSUI = NSUI,
    window_width = window_width,
    window_height = window_height,
    expressway = expressway,
    TABS_LIST = TABS_LIST,
    authorsString = authorsString,
    options_text_template = options_text_template,
    options_dropdown_template = options_dropdown_template,
    options_switch_template = options_switch_template,
    options_slider_template = options_slider_template,
    options_button_template = options_button_template,
    build_media_options = build_media_options,
    build_growdirection_options = build_growdirection_options,
    build_PAgrowdirection_options = build_PAgrowdirection_options,
    build_raidframeicon_options = build_raidframeicon_options,
    LDBIcon = LDBIcon,
}

-- Make NSUI accessible globally through NSI
NSI.NSUI = NSUI
