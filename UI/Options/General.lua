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
            type = "select",
            name = "Global Font",
            desc = "This changes the Font for everything that doesn't have a specific setting for that. Mainly useful for language compatibility.",
            get = function() return NSRT.Settings.GlobalFont end,
            values = function() return build_media_options(false, false, false, false, false, true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Global Font-Size",
            desc = "Size of the global font",
            get = function() return NSRT.Settings["GlobalFontSize"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["GlobalFontSize"] = value
                NSI.NSRTFrame.generic_display.Text:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings.GlobalFontSize, "OUTLINE")
            end,
            min = 10,
            max = 100,
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
        { type = "label", get = function() return "Setup Manager" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "button",
            name = "Default Arrangement",
            desc = "Sorts groups into a default order (tanks - melee - ranged - healer)",
            func = function(self)
                NSI:SplitGroupInit(false, true, false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = "Split Groups",
            desc = "Splits the group evenly into 2 groups. It will even out tanks, melee, ranged and healers, as well as trying to balance the groups by class and specs",
            func = function(self)
                NSI:SplitGroupInit(false, false, false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = "Split Evens/Odds",
            desc = "Same as the button above but using groups 1/3/5 and 2/4/6.",
            func = function(self)
                NSI:SplitGroupInit(false, false, true)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Missing Raidbuffs in Raid-Tab",
            desc = "Show a list of missing raidbuffs in your comp in the raid tab. In there you can swap between Mythic and Flex, which will then only consider players up to group 4/6 respectively.",
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
            name = "Export Profile",
            desc = "Exports your currently active profile to a string that can be shared with others.",
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
            name = "Import Profile",
            desc = "Imports a profile from a string shared by another player. It will be saved as a new profile you can then load.",
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
        { type = "label", get = function() return "Profile Management" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        { type = "label", get = function() return "Current Profile: |cFF00FFFF" .. (NSRT.CurrentProfile or "default") .. "|r" end },

        {
            type = "textentry",
            name = "New Profile Name",
            desc = "Enter a name and press Enter to create a new profile.",
            get = function() return "" end,
            set = function(self, fixedparam, value) end,
            hooks = {
                OnEnterPressed = function(self)
                    local name = self:GetText()
                    if name and name ~= "" then
                        NSI:CreateProfile(name)
                        print("|cFF00FFFFNSRT:|r Created and switched to profile '|cFFFFFFFF" .. name .. "|r'.")
                    end
                end,
            },
        },
        {
            type = "select",
            name = "Load Profile",
            desc = "Select a profile to load.",
            get = function() return NSRT.CurrentProfile or "default" end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    tinsert(t, {
                        label = name,
                        value = name,
                        onclick = function()
                            NSI:LoadProfile(name)
                            print("|cFF00FFFFNSRT:|r Loaded profile '|cFFFFFFFF" .. name .. "|r'.")
                        end,
                    })
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Copy Profile Into Current",
            desc = "Select a profile to copy its settings into your current profile.",
            get = function() return "Select..." end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    if name ~= NSRT.CurrentProfile then
                        tinsert(t, {
                            label = name,
                            value = name,
                            onclick = function()
                                NSI:CopyFromProfile(name)
                                print("|cFF00FFFFNSRT:|r Copied profile '|cFFFFFFFF" .. name .. "|r' into '|cFFFFFFFF" .. NSRT.CurrentProfile .. "|r'.")
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
            name = "Reset Profile",
            desc = "Select a profile to reset to defaults.",
            get = function() return "Select..." end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    tinsert(t, {
                        label = name,
                        value = name,
                        onclick = function()
                            NSI:ResetProfile(name)
                            print("|cFF00FFFFNSRT:|r Reset profile '|cFFFFFFFF" .. name .. "|r'.")
                        end,
                    })
                end
                return t
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Delete Profile",
            desc = "Select a profile to delete. Cannot delete the currently active profile if it is the only one.",
            get = function() return "Select..." end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    if name ~= "default" then
                        tinsert(t, {
                            label = name,
                            value = name,
                            onclick = function()
                                NSI:DeleteProfile(name)
                                print("|cFF00FFFFNSRT:|r Deleted profile '|cFFFFFFFF" .. name .. "|r'.")
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
            name = "Main Profile",
            desc = "Set the main profile. This profile will automatically be loaded on any new character you log into.",
            get = function() return NSRT.MainProfile or "default" end,
            values = function()
                local t = {}
                for name, _ in pairs(NSRT.Profiles or {}) do
                    tinsert(t, {
                        label = name,
                        value = name,
                        onclick = function()
                            NSI:SetMainProfile(name)
                            print("|cFF00FFFFNSRT:|r Main profile set to '|cFFFFFFFF" .. name .. "|r'.")
                        end,
                    })
                end
                return t
            end,
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
