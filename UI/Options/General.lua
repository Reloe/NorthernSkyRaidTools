local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local LDBIcon = Core.LDBIcon
local build_media_options = Core.build_media_options

local function BuildGeneralOptions()
    local tts_text_preview = ""
    local client = IsWindowsClient()

    return {
        { type = "label", get = function() return "General Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Minimap Button",
            desc = "Hide the minimap button.",
            get = function() return NSRT.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                NSRT.Settings["Minimap"].hide = value
                LDBIcon:Refresh("NSRT", NSRT.Settings["Minimap"])
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Debug Logging",
            desc = "Enables Debug Logging, which prints a bunch of information and adds it to DevTool. This might Error if you do not have the DevTool Addon installed.",
            get = function() return NSRT.Settings["DebugLogs"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["DEBUGLOGS"] = true
                NSRT.Settings["DebugLogs"] = value
            end,
        },

        {
            type = "breakline"
        },
        { type = "label", get = function() return "TTS Options" end,     text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "range",
            name = "TTS Voice",
            desc = "Voice to use for TTS. Most users will only have ~2 different voices. These voices depend on your installed language packs.",
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
            name = "TTS Volume",
            desc = "Volume of the TTS",
            get = function() return NSRT.Settings["TTSVolume"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["TTSVolume"] = value
            end,
            min = 0,
            max = 100,
        },
        {
            type = "textentry",
            name = "TTS Preview",
            desc = [[Enter any text to preview TTS

Press 'Enter' to hear the TTS]],
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
            name = "Enable TTS",
            desc = "Enable TTS",
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
            name = "Export Settings",
            desc = "Exports your current settings to a string that can be shared with others.",
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
            name = "Import Settings",
            desc = "Imports settings from a string shared by others. Confirming the Import will force reload your UI for the changes to take effect.",
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
            name = "Move Text Display",
            desc = "This lets you move the generic text display used for example the ready check module or the assignments on pull.",
            func = function(self)
                if NSI.NSRTFrame.generic_display:IsMovable() then
                    NSI:ToggleMoveFrames(NSI.NSRTFrame.generic_display, false)
                else
                    NSI.NSRTFrame.generic_display.Text:SetText("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
                    NSI.NSRTFrame.generic_display:SetSize(NSI.NSRTFrame.generic_display.Text:GetStringWidth(), NSI.NSRTFrame.generic_display.Text:GetStringHeight())
                    NSI:ToggleMoveFrames(NSI.NSRTFrame.generic_display, true)
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Global Font",
            desc = "This changes the Font for everything that doesn't have a specific setting for that. Mainly useful for language compatibility.",
            get = function() return NSRT.Settings.GlobalFont end,
            values = function() return build_media_options(false, false, false, false, false, true) end,
            nocombat = true,
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
