local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local LDBIcon = Core.LDBIcon
local build_media_options = Core.build_media_options

local function BuildGeneralOptions()
    local tts_text_preview = ""
    local client = IsWindowsClient()

    return {
        { type = "label", get = function() return L["OPT_GEN_TITLE"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_GEN_DISABLE_MINIMAP"],
            desc = L["OPT_GEN_DISABLE_MINIMAP_DESC"],
            get = function() return NSRT.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                NSRT.Settings["Minimap"].hide = value
                LDBIcon:Refresh("NSRT", NSRT.Settings["Minimap"])
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_GEN_ENABLE_DEBUG_LOG"],
            desc = L["OPT_GEN_ENABLE_DEBUG_LOG_DESC"],
            get = function() return NSRT.Settings["DebugLogs"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["DEBUGLOGS"] = true
                NSRT.Settings["DebugLogs"] = value
            end,
        },

        {
            type = "breakline"
        },
        { type = "label", get = function() return L["OPT_GEN_TTS_TITLE"] end,     text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "range",
            name = L["OPT_GEN_TTS_VOICE"],
            desc = L["OPT_GEN_TTS_VOICE_DESC"],
            get = function() return NSRT.Settings["TTSVoice"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["TTS_VOICE"] = true
                NSRT.Settings["TTSVoice"] = value
            end,
            min = 1,
            max = client and 20 or 100,
        },
        {
            type = "range",
            name = L["OPT_GEN_TTS_VOLUME"],
            desc = L["OPT_GEN_TTS_VOLUME_DESC"],
            get = function() return NSRT.Settings["TTSVolume"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["TTSVolume"] = value
            end,
            min = 0,
            max = 100,
        },
        {
            type = "textentry",
            name = L["OPT_GEN_TTS_PREVIEW"],
            desc = L["OPT_GEN_TTS_PREVIEW_DESC"],
            get = function() return tts_text_preview end,
            set = function(self, fixedparam, value)
                tts_text_preview = value
            end,
            hooks = {
                OnEnterPressed = function(self)
                    NSAPI:TTS(tts_text_preview, NSRT.Settings["TTSVoice"])
                end
            }
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_GEN_ENABLE_TTS"],
            desc = L["OPT_GEN_ENABLE_TTS_DESC"],
            get = function() return NSRT.Settings["TTS"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["TTS_ENABLED"] = true
                NSRT.Settings["TTS"] = value
            end,
        },
        {
            type = "breakline",
        },
        {
            type = "button",
            name = L["OPT_GEN_EXPORT_SETTINGS"],
            desc = L["OPT_GEN_EXPORT_SETTINGS_DESC"],
            func = function(self)
                if NSUI.export_string_popup:IsShown() then
                    NSUI.export_string_popup:Hide()
                else
                    NSUI.export_string_popup:Show()
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = L["OPT_GEN_IMPORT_SETTINGS"],
            desc = L["OPT_GEN_IMPORT_SETTINGS_DESC"],
            func = function(self)
                if NSUI.import_string_popup:IsShown() then
                    NSUI.import_string_popup:Hide()
                else
                    NSUI.import_string_popup:Show()
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "breakline",
        },

        {
            type = "button",
            name = L["OPT_GEN_MOVE_TEXT_DISPLAY"],
            desc = L["OPT_GEN_MOVE_TEXT_DISPLAY_DESC"],
            func = function(self)
                if NSI.NSRTFrame.generic_display:IsMovable() then
                    NSI:ToggleMoveFrames(NSI.NSRTFrame.generic_display, false)
                else
                    NSI.NSRTFrame.generic_display.Text:SetText(L["GENERIC_DISPLAY_PREVIEW_TEXT"])
                    NSI.NSRTFrame.generic_display:SetSize(NSI.NSRTFrame.generic_display.Text:GetStringWidth(), NSI.NSRTFrame.generic_display.Text:GetStringHeight())
                    NSI:ToggleMoveFrames(NSI.NSRTFrame.generic_display, true)
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = L["OPT_GEN_GLOBAL_FONT"],
            desc = L["OPT_GEN_GLOBAL_FONT_DESC"],
            get = function() return NSRT.Settings.GlobalFont end,
            values = function() return build_media_options(false, false, false, false, false, true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_GEN_GLOBAL_FONT_SIZE"],
            desc = L["OPT_GEN_GLOBAL_FONT_SIZE_DESC"],
            get = function() return NSRT.Settings["GlobalFontSize"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["GlobalFontSize"] = value
                NSI.NSRTFrame.generic_display.Text:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings.GlobalFontSize, "OUTLINE")
            end,
            min = 0,
            max = 100,
        },
    }
end

local function BuildGeneralCallback()
    return function()
        wipe(NSUI.OptionsChanged["general"])
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.General = {
    BuildOptions = BuildGeneralOptions,
    BuildCallback = BuildGeneralCallback,
}
