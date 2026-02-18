local _, NSI = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

-- Window dimensions
local window_width = 1050
local window_height = 640

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
    { name = "QoL", text = "Quality of Life"},
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
local function build_media_options(typename, settingname, isTexture, isReminder, Personal, GlobalFont)
    local list = NSI.LSM:List(isTexture and "statusbar" or "font")
    local t = {}
    for i, font in ipairs(list) do
        tinsert(t, {
            label = font,
            value = i,
            onclick = function(_, _, value)
                if GlobalFont then
                    NSRT.Settings.GlobalFont = list[value]
                    return
                end
                NSRT.ReminderSettings[typename][settingname] = list[value]
                if isReminder then
                    NSI:UpdateReminderFrame(true)
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
                local swapped = false
                if SecondaryName == "GrowDirection" and
                (list[value] == NSRT[SettingName]["RowGrowDirection"] or
                (list[value] == "UP" and NSRT[SettingName]["RowGrowDirection"] == "DOWN") or (list[value] == "DOWN" and NSRT[SettingName]["RowGrowDirection"] == "UP") or
                (list[value] == "LEFT" and NSRT[SettingName]["RowGrowDirection"] == "RIGHT") or (list[value] == "RIGHT" and NSRT[SettingName]["RowGrowDirection"] == "LEFT")) then
                    NSRT[SettingName]["RowGrowDirection"] = NSRT[SettingName]["GrowDirection"]
                    swapped = true

                elseif SecondaryName == "RowGrowDirection" and
                (list[value] == NSRT[SettingName]["GrowDirection"] or
                (list[value] == "UP" and NSRT[SettingName]["GrowDirection"] == "DOWN") or (list[value] == "DOWN" and NSRT[SettingName]["GrowDirection"] == "UP") or
                (list[value] == "LEFT" and NSRT[SettingName]["GrowDirection"] == "RIGHT") or (list[value] == "RIGHT" and NSRT[SettingName]["GrowDirection"] == "LEFT")) then
                    NSRT[SettingName]["GrowDirection"] = NSRT[SettingName]["RowGrowDirection"]
                    swapped = true
                end
                NSRT[SettingName][SecondaryName] = list[value]
                NSI:UpdatePADisplay(SettingName == "PASettings", SettingName == "PATankSettings")

                if swapped then NSUI.MenuFrame:GetTabFrameByName("PrivateAura"):RefreshOptions() end
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

local soundlist = NSI.LSM:List("sound")
local function build_sound_dropdown()
    local t = {}
    for i, sound in ipairs(soundlist) do
        tinsert(t, {
            label = sound,
            value = i,
            onclick = function(_, _, value)
                local toplay = NSI.LSM:Fetch("sound", sound)
                PlaySoundFile(toplay, "Master")
                NSRT.ReminderSettings.DefaultSound = soundlist[value]
                return value
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
    build_sound_dropdown = build_sound_dropdown,
    LDBIcon = LDBIcon,
}

-- Make NSUI accessible globally through NSI
NSI.NSUI = NSUI
