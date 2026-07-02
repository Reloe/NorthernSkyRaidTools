local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local NSUI = Core.NSUI
local build_media_options = Core.build_media_options
local build_growdirection_options = Core.build_growdirection_options
local build_raidframeicon_options = Core.build_raidframeicon_options
local build_sound_dropdown = Core.build_sound_dropdown

local function BuildSpellDisplayOptions()
    local options = {}
    for _, displayType in ipairs({"Icon", "Bar", "Text", "Circle"}) do
        local value = displayType
        options[#options + 1] = {
            label = NSI:Loc(value),
            phraseId = value,
            value = value,
            onclick = function()
                NSRT.ReminderSettings.SpellDisplayType = value
                NSI:ProcessReminder()
            end,
        }
    end
    return options
end

local function BuildReminderOptions()
    return {
        {
            type = "label",
            get = function() return "Spell Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS",
            desc = "Whether a TTS sound should be played",
            get = function() return NSRT.ReminderSettings["SpellTTS"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellTTS"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "TTSTimer",
            desc = "At how much remaining Time the TTS should be played",
            get = function() return NSRT.ReminderSettings["SpellTTSTimer"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellTTSTimer"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = "Duration",
            desc = "How long a reminder should be shown for",
            get = function() return NSRT.ReminderSettings["SpellDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellDuration"] = value
                NSI:ProcessReminder()
            end,
            min = 5,
            max = 100,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return NSRT.ReminderSettings["SpellCountdown"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellCountdown"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Duration",
            desc = "When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'SpellName in 10'",
            get = function() return NSRT.ReminderSettings["AnnounceSpellDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["AnnounceSpellDuration"] = value
                NSI:ProcessReminder()

            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "SpellName",
            desc = "Display the SpellName if no text is provided",
            get = function() return NSRT.ReminderSettings["SpellName"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellName"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "SpellName TTS if empty",
            desc = "This will make it so that the SpellName is still played as TTS even if the text of the reminder remains empty (so even if you have 'SpellName' unticked).",
            get = function() return NSRT.ReminderSettings.SpellNameTTS end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.SpellNameTTS = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Default Spell Display",
            desc = "Default display type for reminders with a spell ID. Reminders without a spell ID use text unless their display type is set explicitly.",
            get = function() return NSRT.ReminderSettings.SpellDisplayType end,
            values = BuildSpellDisplayOptions,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Text Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS",
            desc = "Whether a TTS sound should be played",
            get = function() return NSRT.ReminderSettings["TextTTS"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextTTS"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "TTSTimer",
            desc = "At how much remaining Time the TTS should be played",
            get = function() return NSRT.ReminderSettings["TextTTSTimer"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextTTSTimer"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = "Duration",
            desc = "How long a reminder should be shown for",
            get = function() return NSRT.ReminderSettings["TextDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextDuration"] = value
                NSI:ProcessReminder()
            end,
            min = 5,
            max = 100,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return NSRT.ReminderSettings["TextCountdown"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextCountdown"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Duration",
            desc = "When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'Spread in 10'",
            get = function() return NSRT.ReminderSettings["AnnounceTextDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["AnnounceTextDuration"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Raidframe Icon Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range",
            name = "Icon-Width",
            desc = "Width of the Icon",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.Width = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Height",
            desc = "Height of the Icon",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.Height = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "select",
            name = "Position",
            desc = "position on the raidframe",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.Position end,
            values = function() return build_raidframeicon_options() end,
            nocombat = true,
        },
        {
            type = "range",
            name = "x-Offset",
            desc = "",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.xOffset= value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = "y-Offset",
            desc = "",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.yOffset = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "color",
            name = "Glow-Color",
            desc = "Color of Raidframe Glows",
            get = function() return NSRT.ReminderSettings.GlowSettings.colors end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.GlowSettings.colors = {r, g, b, a}
            end,
            hasAlpha = true,
            nocombat = true
        },
        {
            type = "label",
            get = function() return "Universal Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS Over Soundfile",
            desc = "Always use text-to-speech even if a soundfile with the same name is detected.",
            get = function() return NSRT.ReminderSettings.TTSOverSoundfile end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TTSOverSoundfile = value
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Play Sound instead of TTS",
            desc = "This will play the selected sound for all reminders instead of using TTS as long as the TTS&Sound fields are empty. The time the sound is played at still uses the TTSTimer value. This also means that any setting that converts the spellName into TTS for example also needs to be disabled for this to work.",
            get = function() return NSRT.ReminderSettings["PlayDefaultSound"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["PlayDefaultSound"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },

        {
            type = "select",
            name = "Sound",
            desc = "Sound",
            get = function() return NSRT.ReminderSettings.DefaultSound end,
            values = function() return build_sound_dropdown() end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Ignore 'everyone' tags",
            desc = "Ignores All Reminders that use the 'everyone' tag. For example if there are a lot of reminders shared from your raidlead that you don't want to see, you can filter out these 'everyone' reminders while still getting your personal assigned spells.",
            get = function() return NSRT.ReminderSettings.IgnoreEveryone end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IgnoreEveryone = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show ALL Reminders",
            desc = "This will show you ALL reminders from your notes, regardless of whether the tag matches you or not.",
            get = function() return NSRT.ReminderSettings.ShowAllReminders end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowAllReminders = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Hide Reminder Treshold",
            desc = "Treshold above which spells will not be hidden if pressed during the reminder. Some long ramp classes have multiple reminders up at the same time and thus don't want them hidden early",
            get = function() return NSRT.ReminderSettings.HideThreshold or 5 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.HideThreshold = value
            end,
            min = 0,
            max = 30,
            nocombat = true,
        },

        {
            type = "breakline",
        },

        {
            type = "label",
            get = function() return "Manage Reminders" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = "Preview Alerts",
            desc = "Preview Reminders and unlock their anchors to move them around",
            func = function(self)
                if NSI.IsInPreview then return end
                if NSI:IsUsingTLAlerts() or NSI:IsUsingTLReminders() then
                    print("|cFF00FFFFNSRT:|r " .. NSI:Loc("You are displaying notes and/or alerts through Timelinereminders so this preview makes little senses for you as it won't change what you're seeing. Either change your settings in Timelinereminders instead or disable the settings in there."))
                end
                NSI:TogglePreviewMode()
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Shared Reminders",
            desc = "Enables reminders set by the raidleader or shared by an assist",
            get = function() return NSRT.ReminderSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.enabled = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Use Personal Reminders",
            desc = "Enables reminders set into your personal reminder",
            get = function() return NSRT.ReminderSettings.PersNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersNote = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
                local charkey = NSI:GetProfileKey()
                if not value then
                    NSI.PersonalReminder = ""
                    NSI.LoadedPersonalReminder = nil
                    if charkey then
                        NSRT.StoredPersonalReminder[charkey] = nil
                        NSRT.ActivePersonalReminder[charkey] = {}
                    end
                end
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use MRT Note Reminders",
            desc = "Enables reminders entered into MRT note",
            get = function() return NSRT.ReminderSettings.MRTNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.MRTNote = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Share on Ready Check",
            desc = "Automatically share the current active reminder on ready check if you are the raidleader. If you want to share a note as assist you can do so in the Shared Reminders-list",
            get = function() return NSRT.ReminderSettings.AutoShare end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.AutoShare = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Clear Note on Boss-Kill",
            desc = "Automatically clear the Shared & Personal Note on a Boss-Kill.",
            get = function() return NSRT.ReminderSettings.ClearOnKill end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ClearOnKill = value
            end,
            nocombat = true,
        },{
            type = "toggle",
            boxfirst = true,
            name = "Only Receive Guild Reminders",
            desc = "Only receive Shared-reminders from guild members.",
            get = function() return NSRT.ReminderSettings.OnlyReceiveGuild end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.OnlyReceiveGuild = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Automatically Enable New Alerts",
            desc = "Automatically enables all future Alerts unless they are specifically marked as being default disabled.",
            get = function() return NSRT.Alerts.ReloeReminders end,
            set = function(self, fixedparam, value)
                local wasEnabled = NSRT.Alerts.ReloeReminders == true
                NSRT.Alerts.ReloeReminders = value
                if value and not wasEnabled then
                    NSI:PromptReloeReminderImport()
                end
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = "Test Active Reminder",
            desc = "Runs a test for the currently active reminder. This will only show phase 1 timers. Press again to cancel the test. This button does nothing if you are using TimelineReminders to display Reminders.",
            func = function(self)
                if not NSI.TestingReminder then
                    NSI.TestingReminder = true
                    NSI:StartReminders(1, true)
                else
                    NSI.TestingReminder = false
                    NSI:HideAllReminders()
                end
            end,
            nocombat = true,
            spacement = true
        },
    }
end

local function BuildReminderNoteOptions()
    return {
        {
            type = "label",
            get = function() return "This tab is purely for Settings to display Reminders as a Note on-screen. They have no effect on how the in-combat alerts work.\nThere are 3 types of displays. The first one shows all reminders, the second one shows only those that will activate for you. And the third shows all text that is not a reminder." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "All Reminders Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Unlock All Reminders",
            desc = "Locks/Unlocks the All Reminders Note to be moved around",
            func = function(self)
                if NSI.ReminderFrameMover and NSI.ReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(false, true)
                    NSI:MakeDraggable(NSI.ReminderFrameMover, NSRT.ReminderSettings.ReminderFrame, false, true)
                    NSI.ReminderFrameMover.Resizer:Hide()
                    NSI.ReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ReminderFrame.Moveable = false
                else
                    NSI:UpdateReminderFrame(false, true)
                    NSI:MakeDraggable(NSI.ReminderFrameMover, NSRT.ReminderSettings.ReminderFrame, true, true)
                    NSI.ReminderFrameMover.Resizer:Show()
                    NSI.ReminderFrameMover:SetResizable(true)
                    NSI.ReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.ReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show All Reminders Note",
            desc = "Whether you want to show the All Reminders Note on screen permanently",
            get = function() return NSRT.ReminderSettings.ReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ReminderFrame.enabled = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the All Reminders Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ReminderFrame.FontSize = value
                NSI:UpdateReminderFrame(false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the All Reminders Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.Font end,
            values = function()
                return build_media_options("ReminderFrame", "Font", false, true, false)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the All Reminders Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ReminderFrame.Width = value
                NSI:UpdateReminderFrame(false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the All Reminders Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ReminderFrame.Height = value
                NSI:UpdateReminderFrame(false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the All Reminders Note when unlocked",
            get = function() return NSRT.ReminderSettings.ReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.ReminderFrame.BGcolor = {r, g, b, a}
                NSI:UpdateReminderFrame(false, true)
            end,
            hasAlpha = true,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Text-Note in All Reminders Note",
            desc = "Display the Text-Note inside the All Reminders Note.",
            get = function() return NSRT.ReminderSettings.TextInSharedNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextInSharedNote = value
                NSI:UpdateReminderFrame(false, true)
            end,
        },
        {
            type = "label",
            get = function() return "Universal Settings - these apply to all 3 Notes" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Player-Names in Note",
            desc = "Hides the Player Names for Reminders in the Note.",
            get = function() return NSRT.ReminderSettings.HidePlayerNames end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.HidePlayerNames = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Only Spell-Reminders",
            desc = "With this enabled you will only see Spell-Reminders in your notes.",
            get = function() return NSRT.ReminderSettings.OnlySpellReminders end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.OnlySpellReminders = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Countdown and Hide Timers in Notes",
            desc = "With this enabled, Timers will count down during combat and completed timers will hide.",
            get = function() return NSRT.ReminderSettings.NoteCountdown end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.NoteCountdown = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Outside of Raid",
            desc = "With this enabled the Notes will still show outside of raid instances.",
            get = function() return NSRT.ReminderSettings.ShowOutsideOfRaid end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowOutsideOfRaid = value
                NSI:UpdateReminderFrame(true)
            end,
        },

        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Personal Reminder-Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Unlock Pers Reminder",
            desc = "Locks/Unlocks the Personal Reminders Note to be moved around",
            func = function(self)
                if NSI.PersonalReminderFrameMover and NSI.PersonalReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:MakeDraggable(NSI.PersonalReminderFrameMover, NSRT.ReminderSettings.PersonalReminderFrame, false, true)
                    NSI.PersonalReminderFrameMover.Resizer:Hide()
                    NSI.PersonalReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.PersonalReminderFrame.Moveable = false
                else
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:MakeDraggable(NSI.PersonalReminderFrameMover, NSRT.ReminderSettings.PersonalReminderFrame, true, true)
                    NSI.PersonalReminderFrameMover.Resizer:Show()
                    NSI.PersonalReminderFrameMover:SetResizable(true)
                    NSI.PersonalReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.PersonalReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Personal Reminder Note",
            desc = "Whether you want to display the Note for Reminders only relevant to you",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersonalReminderFrame.enabled = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the Personal Reminders Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersonalReminderFrame.FontSize = value
                NSI:UpdateReminderFrame(false, false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the Personal Reminders Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.Font end,
            values = function()
                return build_media_options("PersonalReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the Personal Reminders Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersonalReminderFrame.Width = value
                NSI:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Personal Reminders Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersonalReminderFrame.Height = value
                NSI:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the Personal Reminders Note when unlocked",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.PersonalReminderFrame.BGcolor = {r, g, b, a}
                NSI:UpdateReminderFrame(false, false, true)
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Text-Note in Personal Reminders Note",
            desc = "Display the Text-Note inside the Personal Reminders Note.",
            get = function() return NSRT.ReminderSettings.TextInPersonalNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextInPersonalNote = value
                NSI:UpdateReminderFrame(true)
            end,
        },

        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Text-Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Unlock Text Note",
            desc = "Locks/Unlocks the Text Note to be moved around. This Note shows anything from the reminders that it is not an actual reminder string. So you can put any text in there to be displayed.",
            func = function(self)
                if NSI.ExtraReminderFrameMover and NSI.ExtraReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(false, false, false, true)
                    NSI:MakeDraggable(NSI.ExtraReminderFrameMover, NSRT.ReminderSettings.ExtraReminderFrame, false, true)
                    NSI.ExtraReminderFrameMover.Resizer:Hide()
                    NSI.ExtraReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ExtraReminderFrame.Moveable = false
                else
                    NSI:UpdateReminderFrame(false, false, false, true)
                    NSI:MakeDraggable(NSI.ExtraReminderFrameMover, NSRT.ReminderSettings.ExtraReminderFrame, true, true)
                    NSI.ExtraReminderFrameMover.Resizer:Show()
                    NSI.ExtraReminderFrameMover:SetResizable(true)
                    NSI.ExtraReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.ExtraReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Text Note",
            desc = "Whether you want to display the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ExtraReminderFrame.enabled = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, false, false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ExtraReminderFrame.FontSize = value
                NSI:UpdateReminderFrame(false, false, false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.Font end,
            values = function()
                return build_media_options("ExtraReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ExtraReminderFrame.Width = value
                NSI:UpdateReminderFrame(false, false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ExtraReminderFrame.Height = value
                NSI:UpdateReminderFrame(false, false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the Text-Note when unlocked",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.ExtraReminderFrame.BGcolor = {r, g, b, a}
                NSI:UpdateReminderFrame(false, false, false, true)
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Timeline" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = "Open Timeline",
            desc = "Opens the Timeline window (Also opened by the `/ns tl` or `/ns timeline` slash command)",
            func = function(self)
                NSI:ToggleTimelineWindow()
            end,
            spacement = true,
            button_template = DF:GetTemplate("button", "details_forge_button_template"),

        }
    }
end

local function BuildReminderCallback()
    return function()
        -- No specific callback needed
    end
end

local function BuildReminderNoteCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.Reminders = {
    BuildOptions = BuildReminderOptions,
    BuildNoteOptions = BuildReminderNoteOptions,
    BuildCallback = BuildReminderCallback,
    BuildNoteCallback = BuildReminderNoteCallback,
}
