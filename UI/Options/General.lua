local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = LibStub("AceLocale-3.0"):GetLocale("NorthernSkyRaidTools")

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local LDBIcon = Core.LDBIcon
local build_media_options = Core.build_media_options

local function BuildGeneralOptions()
    local tts_text_preview = ""

    return {
        { type = "label", get = function() return L["General Options"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Disable Minimap Button"],
            desc = L["Hide the minimap button."],
            get = function() return NSRT.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                NSRT.Settings["Minimap"].hide = value
                LDBIcon:Refresh("NSRT", NSRT.Settings["Minimap"])
            end,
        },
        {
            type = "select",
            name = L["Global Font"],
            desc = L["This changes the Font for everything that doesn't have a specific setting for that. Mainly useful for language compatibility."],
            get = function() return NSRT.Settings.GlobalFont end,
            set = function(self, fixedparam, value)
                NSRT.Settings.GlobalFont = value
                NSI.UI.Components.RefreshFonts()
            end,
            values = function() return build_media_options(false, false, false, false, false, true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["Global Font-Size"],
            desc = L["Size of the global font"],
            get = function() return NSRT.Settings["GlobalFontSize"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["GlobalFontSize"] = value
                NSI.NSRTFrame.generic_display.Text:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings.GlobalFontSize, NSRT.Settings.GlobalFontFlags)
            end,
            min = 10,
            max = 100,
        },
        {
            type = "select",
            name = L["Global Font Outline"],
            desc = L["Font outline flags applied to all addon text."],
            get = function() return NSRT.Settings.GlobalFontFlags end,
            set = function(self, fixedparam, value)
                NSRT.Settings.GlobalFontFlags = value
                NSI.UI.Components.RefreshFonts()
            end,
            values = function()
                local flags = {
                    "",
                    "OUTLINE",
                    "THICKOUTLINE",
                    "MONOCHROME",
                    "OUTLINE, MONOCHROME",
                    "THICKOUTLINE, MONOCHROME",
                }
                local t = {}
                for _, v in ipairs(flags) do
                    local label = v == "" and L["None"] or v
                    tinsert(t, {
                        label = label,
                        value = v,
                        onclick = function()
                            NSRT.Settings.GlobalFontFlags = v
                            NSI.UI.Components.RefreshFonts()
                        end,
                    })
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = L["Move Text Display"],
            desc = L["This lets you move the generic text display used for example the ready check module or the assignments on pull."],
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
        { type = "label", get = function() return L["Setup Manager"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "button",
            name = L["Default Arrangement"],
            desc = L["Sorts groups into a default order (tanks - melee - ranged - healer)"],
            func = function(self)
                NSI:SplitGroupInit(false, true, false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = L["Split Groups"],
            desc = L["Splits the group evenly into 2 groups. It will even out tanks, melee, ranged and healers, as well as trying to balance the groups by class and specs"],
            func = function(self)
                NSI:SplitGroupInit(false, false, false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = L["Split Evens/Odds"],
            desc = L["Same as the button above but using groups 1/3/5 and 2/4/6."],
            func = function(self)
                NSI:SplitGroupInit(false, false, true)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Show Missing Raidbuffs in Raid-Tab"],
            desc = L["Show a list of missing raidbuffs in your comp in the raid tab. In there you can swap between Mythic and Flex, which will then only consider players up to group 4/6 respectively."],
            get = function() return NSRT.Settings.MissingRaidBuffs end,
            set = function(self, fixedparam, value)
                NSRT.Settings.MissingRaidBuffs = value
                NSI:UpdateRaidBuffFrame()
            end,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        { type = "label", get = function() return L["TTS Options"] end,     text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "select",
            name = L["TTS Voice"],
            desc = L["Voice to use for TTS. Most users will only have ~2 different voices. These voices depend on your installed language packs."],
            get = function() return NSRT.Settings["TTSVoice"] end,
            values = function()
                local t = {}
                local voices = C_VoiceChat.GetTtsVoices()
                if voices then
                    for _, v in ipairs(voices) do
                        tinsert(t, {
                            label = v.name,
                            value = v.voiceID,
                            onclick = function()
                                NSUI.OptionsChanged.general["TTS_VOICE"] = true
                                NSRT.Settings["TTSVoice"] = v.voiceID
                            end,
                        })
                    end
                end
                return t
            end,
        },
        {
            type = "range",
            name = L["TTS Volume"],
            desc = L["Volume of the TTS"],
            get = function() return NSRT.Settings["TTSVolume"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["TTSVolume"] = value
            end,
            min = 0,
            max = 100,
        },
        {
            type = "textentry",
            name = L["TTS Preview"],
            desc = L["Enter any text to preview TTS\n\nPress 'Enter' to hear the TTS"],
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
            name = L["Enable TTS"],
            desc = L["Enable TTS"],
            get = function() return NSRT.Settings["TTS"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["TTS_ENABLED"] = true
                NSRT.Settings["TTS"] = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Mute All Sound Effects"],
            desc = L["Mutes all Sound Effects played by the game. This way you can use the sound effect channel for TTS without hearing the default sound effects. Pressing the button again unmutes them.\nYou will still hear sound effects on starting the game and some very specific sound effects cannot be muted(like Fyrakk mount)"],
            get = function() return NSRT.Settings.SFXMuted end,
            set = function(self, fixedparam, value)
                NSRT.Settings.SFXMuted = value
                NSI:MuteSFX(value)
            end,
        },
        {
            type = "breakline",
        },
        { type = "label", get = function() return L["Profile Management"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        { type = "label", get = function() return format(L["Current Profile: |cFF00FFFF%s|r"], NSRT.CurrentProfile or "default") end },

        {
            type = "textentry",
            name = L["New Profile Name"],
            desc = L["Enter a name and press Enter to create a new profile."],
            get = function() return "" end,
            set = function(self, fixedparam, value) end,
            hooks = {
                OnEnterPressed = function(self)
                    local name = self:GetText()
                    if name and name ~= "" then
                        NSI:CreateProfile(name)
                        print("|cFF00FFFFNSRT:|r " .. format(L["Created and switched to profile '|cFFFFFFFF%s|r'."], name))
                    end
                end,
            },
        },
        {
            type = "select",
            name = L["Load Profile"],
            desc = L["Select a profile to load."],
            get = function() return NSRT.CurrentProfile or "default" end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    tinsert(t, {
                        label = name,
                        value = name,
                        onclick = function()
                            NSI:LoadProfile(name)
                            print("|cFF00FFFFNSRT:|r " .. format(L["Loaded profile '|cFFFFFFFF%s|r'."], name))
                        end,
                    })
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["Copy Profile Into Current"],
            desc = L["Select a profile to copy its settings into your current profile."],
            get = function() return L["Select..."] end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    if name ~= NSRT.CurrentProfile then
                        tinsert(t, {
                            label = name,
                            value = name,
                            onclick = function()
                                NSI:CopyFromProfile(name)
                                print("|cFF00FFFFNSRT:|r " .. format(L["Copied profile '|cFFFFFFFF%s|r' into '|cFFFFFFFF%s|r'."], name, NSRT.CurrentProfile))
                            end,
                        })
                    end
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["Reset Profile"],
            desc = L["Select a profile to reset to defaults."],
            get = function() return L["Select..."] end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    tinsert(t, {
                        label = name,
                        value = name,
                        onclick = function()
                            NSI:ResetProfile(name)
                            print("|cFF00FFFFNSRT:|r " .. format(L["Reset profile '|cFFFFFFFF%s|r'."], name))
                        end,
                    })
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["Delete Profile"],
            desc = L["Select a profile to delete. Cannot delete the currently active profile if it is the only one."],
            get = function() return L["Select..."] end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    if name ~= "default" then
                        tinsert(t, {
                            label = name,
                            value = name,
                            onclick = function()
                                NSI:DeleteProfile(name)
                                print("|cFF00FFFFNSRT:|r " .. format(L["Deleted profile '|cFFFFFFFF%s|r'."], name))
                            end,
                        })
                    end
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["Main Profile"],
            desc = L["Set the main profile. This profile will automatically be loaded on any new character you log into."],
            get = function() return NSRT.MainProfile or "default" end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    tinsert(t, {
                        label = name,
                        value = name,
                        onclick = function()
                            NSI:SetMainProfile(name)
                            print("|cFF00FFFFNSRT:|r " .. format(L["Main profile set to '|cFFFFFFFF%s|r'."], name))
                        end,
                    })
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = L["Export Profile"],
            desc = L["Exports your currently active profile to a string that can be shared with others."],
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
            name = L["Import Profile"],
            desc = L["Imports a profile from a string shared by another player. It will be saved as a new profile you can then load."],
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
