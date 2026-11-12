local _, UI = ...
local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

-- Window dimensions
local window_width  = 1200
local window_height = 700

-- Window shell: header (title bar + header buttons) and footer (version / author / Discord)
local header_height = 36
local footer_height = 20

-- Vertical tab sidebar layout constants
local sidebar_width    = 160
local content_x        = 162   -- sidebar + 2px separator gap
local content_width    = window_width - content_x - 2   -- 1036
local content_height   = window_height - header_height - footer_height   -- 584

-- Height of the strip above each tab content frame (holds the Shared/Personal Notes buttons)
-- (tab frames start at y = -(header_height + TAB_HEADER_HEIGHT) from NSUI TOPLEFT)
local TAB_HEADER_HEIGHT = 44
local tab_content_height = content_height - TAB_HEADER_HEIGHT  -- 540

local authorsString = "By Reloe & Rav"

-- Templates
local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

NSI.UIFontRegistry = NSI.UIFontRegistry or {}

-- Text inside windows is never outlined: outline is for text drawn over the game
-- world. The user's GlobalFontFlags still drive in-world displays untouched; windows
-- keep its other flags (SLUG, MONOCHROME) and drop OUTLINE / THICKOUTLINE.
function NSI:GetWindowFontFlags()
    local flags = NSRT and NSRT.Settings and NSRT.Settings.GlobalFontFlags or ""
    if flags == "" then return "" end
    local kept = {}
    for flag in flags:gmatch("[^,%s]+") do
        if flag ~= "OUTLINE" and flag ~= "THICKOUTLINE" then
            kept[#kept + 1] = flag
        end
    end
    return table.concat(kept, ", ")
end

-- size is a number or a type-scale name from STYLE.type ("title", "body", "label",
-- "small", "tiny"). flags: nil follows GetWindowFontFlags(); "" forces plain text.
function NSI:SetUIFont(object, size, flags)
    if not object or not object.SetFont then return end
    local explicitFlags = flags
    flags = flags or self:GetWindowFontFlags()
    local style = self.UI and self.UI.Style
    if type(size) == "string" then
        size = style and style.FontSize(size)
    end
    if not size and object.GetFont then
        local ok, _, currentSize = pcall(object.GetFont, object)
        if ok then size = currentSize end
    end
    size = size or 12
    local ok = pcall(object.SetFont, object, self:GetUIFontPath(), size, flags)
    if not ok then
        pcall(object.SetFont, object, self:GetFallbackUIFontPath(), size, flags)
    end
    -- Remember what the caller asked for (not the resolved default) so a later change
    -- of the global flags is followed on the next RefreshUIFonts.
    self.UIFontRegistry[object] = {size = size, flags = explicitFlags}
end

function NSI:RefreshUIFonts()
    for object, info in pairs(self.UIFontRegistry) do
        if object and object.SetFont then
            local flags = info.flags or self:GetWindowFontFlags()
            local ok = pcall(object.SetFont, object, self:GetUIFontPath(), info.size, flags)
            if not ok then
                pcall(object.SetFont, object, self:GetFallbackUIFontPath(), info.size, flags)
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

-- The main window itself is created in MainWindow.lua (see Window.lua).

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

local FONT_FLAG_OPTIONS = {
    "",
    "OUTLINE",
    "THICKOUTLINE",
    "MONOCHROME",
    "OUTLINE, MONOCHROME",
    "THICKOUTLINE, MONOCHROME",
    "SLUG",
    "SLUG, OUTLINE",
    "SLUG, THICKOUTLINE",
    "SLUG, MONOCHROME",
    "SLUG, OUTLINE, MONOCHROME",
    "SLUG, THICKOUTLINE, MONOCHROME",
}

local function build_fontflag_options()
    local t = {}
    for _, flags in ipairs(FONT_FLAG_OPTIONS) do
        t[#t + 1] = {
            label = flags == "" and "None" or flags,
            value = flags,
        }
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

function NSI:GetOrderedSoundList()
    local addonSounds = {}
    local otherSounds = {}
    for _, soundName in ipairs(NSI.LSM:List("sound")) do
        local soundPath = NSI.LSM:Fetch("sound", soundName)
        local soundList = soundPath and string.lower(soundPath):find("interface\\addons\\northernskyraidtools\\media\\sounds\\", 1, true) and addonSounds or otherSounds
        soundList[#soundList + 1] = soundName
    end
    table.sort(addonSounds)
    table.sort(otherSounds)
    for _, soundName in ipairs(otherSounds) do
        addonSounds[#addonSounds + 1] = soundName
    end
    return addonSounds
end

local soundlist = NSI:GetOrderedSoundList()
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
    -- NSUI (the main window) is added by MainWindow.lua
    window_width        = window_width,
    window_height       = window_height,
    header_height       = header_height,
    footer_height       = footer_height,
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
    build_fontflag_options = build_fontflag_options,
    build_raidframeicon_options = build_raidframeicon_options,
    build_sound_dropdown = build_sound_dropdown,
    LDBIcon = LDBIcon,
}
