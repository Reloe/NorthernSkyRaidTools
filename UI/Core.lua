local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

-- Window dimensions
local window_width  = 1200
local window_height = 640

-- Vertical tab sidebar layout constants
local sidebar_width    = 160
local content_x        = 162   -- sidebar + 2px separator gap
local content_width    = window_width - content_x - 2   -- 1036
local content_height   = window_height - 45              -- 595 (25 titlebar + 20 statusbar)

-- Height of the shared header strip above each tab content frame
-- (tab frames start at y = -(25 + TAB_HEADER_HEIGHT) from NSUI TOPLEFT)
local TAB_HEADER_HEIGHT = 55
local tab_content_height = content_height - TAB_HEADER_HEIGHT  -- 540

local authorsString = "By Reloe & Rav"

-- Templates
local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

local supportedLanguages = {
    enUS = true,
    koKR = true,
    ruRU = true,
    zhCN = true,
    zhTW = true,
}

local fontTestString

function NSI:GetFallbackUIFontPath()
    local gameFont = GameFontNormal and select(1, GameFontNormal:GetFont())
    return gameFont or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

function NSI:ValidateFontPath(path)
    local fallback = self:GetFallbackUIFontPath()
    if not path or path == "" then return fallback end

    NSI.fontTestString = NSI.fontTestString or UIParent:CreateFontString(nil, "ARTWORK")
    local ok, success = pcall(NSI.fontTestString.SetFont, NSI.fontTestString, path, 12, "")
    NSI.fontTestString:Hide()
    if ok and success then return path end

    ok, success = pcall(NSI.fontTestString.SetFont, NSI.fontTestString, fallback, 12, "")
    return (ok and success) and fallback or "Fonts\\FRIZQT__.TTF"
end

function NSI:GetSelectedLanguage()
    local languageId = NSRT and NSRT.Settings and NSRT.Settings.Language
    if not languageId or languageId == "Auto" then
        languageId = GetLocale()
    end
    if languageId == "enGB" then
        languageId = "enUS"
    end
    if not supportedLanguages[languageId] then
        languageId = "enUS"
    end
    return languageId
end

function NSI:GetUIFontPath()
    local languageId = self:GetSelectedLanguage()
    local fontPath
    if languageId == "enUS" then
        fontPath = NSRT.Settings.GlobalFont
    elseif languageId and DF.Language.GetFontForLanguageID then
        fontPath = DF.Language.GetFontForLanguageID(languageId, addonId)
    else
        fontPath = DF:GetBestFontForLanguage()
    end

    if self.LSM then
        local lsmFont = self.LSM:Fetch("font", fontPath, true)
        if lsmFont then
            return self:ValidateFontPath(lsmFont)
        end
    end
    return self:ValidateFontPath(fontPath)
end

function NSI:GetUIFontFlags()
    return ""
end

function NSI:GetGlobalFontPath()
    local fontPath = NSRT and NSRT.Settings and NSRT.Settings.GlobalFont
    if self.LSM then
        fontPath = self.LSM:Fetch("font", fontPath, true) or fontPath
    end
    return self:ValidateFontPath(fontPath)
end

function NSI:Loc(key)
    local languageId = self:GetSelectedLanguage()
    local ok, languageTable = pcall(DF.Language.GetLanguageTable, addonId, languageId)
    local text = ok and languageTable and languageTable[key]
    if text == true then
        return key
    elseif text then
        return text
    end

    return DF.Language.GetText(addonId, key, true) or key
end

NSI.UIFontRegistry = NSI.UIFontRegistry or {}

function NSI:SetUIFont(object, size, flags)
    if not object or not object.SetFont then return end
    flags = flags or self:GetUIFontFlags()
    if not size and object.GetFont then
        local ok, _, currentSize = pcall(object.GetFont, object)
        if ok then size = currentSize end
    end
    size = size or 12
    local ok = pcall(object.SetFont, object, self:GetUIFontPath(), size, flags)
    if not ok then
        pcall(object.SetFont, object, self:GetFallbackUIFontPath(), size, flags)
    end
    self.UIFontRegistry[object] = {size = size, flags = flags}
end

function NSI:RefreshUIFonts()
    for object, info in pairs(self.UIFontRegistry) do
        if object and object.SetFont then
            local ok = pcall(object.SetFont, object, self:GetUIFontPath(), info.size, info.flags or self:GetUIFontFlags())
            if not ok then
                pcall(object.SetFont, object, self:GetFallbackUIFontPath(), info.size, info.flags or self:GetUIFontFlags())
            end
        else
            self.UIFontRegistry[object] = nil
        end
    end
end

function NSI:ApplySelectedLanguage(skip)
    local languageId = self:GetSelectedLanguage()
    if not skip then DF.Language.SetCurrentLanguage(addonId, languageId) end

    if self.UI and self.UI.Components and self.UI.Components.RefreshFonts then
        self.UI.Components.RefreshFonts()
    end
    if self.UI and self.UI.Components and self.UI.Components.RefreshLocalizedTexts then
        self.UI.Components.RefreshLocalizedTexts()
    end
    self:RefreshUIFonts()
    if self.RefreshAnchorSettingsWindows then
        self:RefreshAnchorSettingsWindows()
    end
    local menu = NSI.UI and NSI.UI.Core and NSI.UI.Core.NSUI and NSI.UI.Core.NSUI.MenuFrame
    if menu and menu.RefreshTabLabels then
        menu:RefreshTabLabels()
    end
    if menu and menu.CurrentName and menu.AllFramesByName then
        local frame = menu.AllFramesByName[menu.CurrentName]
        if frame and frame.RefreshOptions then
            frame:RefreshOptions()
        end
    end
end

-- Create main panel
local NSUI_panel_options = {
    UseStatusBar = true
}
local NSUI = DF:CreateSimplePanel(UIParent, window_width, window_height, "|cFF00FFFFNorthern Sky|r Raid Tools", "NSUI",
    NSUI_panel_options)
NSUI:SetPoint("CENTER")
NSUI:SetFrameStrata("HIGH")
NSUI:SetFrameLevel(1)
DF:BuildStatusbarAuthorInfo(NSUI.StatusBar, addonId, "x |cFF00FFFFbird|r")
NSUI.StatusBar.discordTextEntry:SetText("https://discord.gg/3B6QHURmBy")

-- Title bar icons
local northernSkyIconFrame = CreateFrame("Frame", "NSUINorthernSkyTitleIconFrame", NSUI)
northernSkyIconFrame:SetSize(20, 20)
northernSkyIconFrame:SetPoint("RIGHT", _G["NSUITitle"], "LEFT", -4, 0)
northernSkyIconFrame:SetFrameLevel(3)

local velocityIconFrame = CreateFrame("Frame", "NSUIVelocityTitleIconFrame", NSUI)
velocityIconFrame:SetSize(16, 16)
velocityIconFrame:SetPoint("LEFT", _G["NSUITitle"], "RIGHT", 4, 0)
velocityIconFrame:SetFrameLevel(3)

local northernSkyIcon = northernSkyIconFrame:CreateTexture(nil, "OVERLAY")
northernSkyIcon:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\NSLogo]])
northernSkyIcon:SetSize(20, 20)
northernSkyIcon:SetPoint("CENTER")

local velocityIcon = velocityIconFrame:CreateTexture(nil, "OVERLAY")
velocityIcon:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\VelocityLogo.png]])
velocityIcon:SetSize(16, 16)
velocityIcon:SetPoint("CENTER")

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
                    NSI:ApplySelectedLanguage()
                    NSI.NSRTFrame.generic_display.Text:SetFont(NSI:GetGlobalFontPath(), NSRT.Settings.GlobalFontSize, NSRT.Settings.GlobalFontFlags)
                    NSI.NSRTFrame.SecretDisplay.Text:SetFont(NSI:GetGlobalFontPath(), NSRT.Settings.GlobalEncounterFontSize, "OUTLINE")
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
            label = NSI:Loc(v),
            phraseId = v,
            value = v,
            onclick = function(_, _, value)
                NSRT.ReminderSettings[SettingName]["GrowDirection"] = value
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
            label = NSI:Loc(v),
            phraseId = v,
            value = v,
            onclick = function(_, _, value)
                NSRT[SettingName][SecondaryName] = value
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
            label = NSI:Loc(v),
            phraseId = v,
            value = v,
            onclick = function(_, _, value)
                NSRT.ReminderSettings.UnitIconSettings.Position = value
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
    window_width        = window_width,
    window_height       = window_height,
    sidebar_width       = sidebar_width,
    content_x           = content_x,
    content_width       = content_width,
    content_height      = content_height,
    TAB_HEADER_HEIGHT   = TAB_HEADER_HEIGHT,
    tab_content_height  = tab_content_height,
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
