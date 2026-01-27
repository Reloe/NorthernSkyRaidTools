local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local build_media_options = Core.build_media_options
local build_growdirection_options = Core.build_growdirection_options
local build_raidframeicon_options = Core.build_raidframeicon_options

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
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return NSRT.ReminderSettings["SpellCountdown"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellCountdown"] = value
            end,
            min = 0,
            max = 5,
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
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Bars",
            desc = "Show Progress Bars instead of icons",
            get = function() return NSRT.ReminderSettings["Bars"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["Bars"] = value
            end,
            nocombat = true,
        },
        {
            type = "range",
            boxfirst = true,
            name = "Sticky",
            desc = "Keep Reminders shown for X seconds if the spell hasn't been pressed yet",
            get = function() return NSRT.ReminderSettings["Sticky"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["Sticky"] = value
            end,
            nocombat = true,
            min = 0,
            max = 10,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Timer Text",
            desc = "Hides the Timer Text shown on the Icon",
            get = function() return NSRT.ReminderSettings["HideTimerText"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["HideTimerText"] = value
                NSI:UpdateExistingFrames()
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Text Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.ReminderSettings.TextSettings.GrowDirection end,
            values = function() return build_growdirection_options("TextSettings") end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS",
            desc = "Whether a TTS sound should be played",
            get = function() return NSRT.ReminderSettings["TextTTS"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextTTS"] = value
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
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return NSRT.ReminderSettings["TextCountdown"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextCountdown"] = value
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return NSRT.ReminderSettings.TextSettings.Font end,
            values = function() return build_media_options("TextSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return NSRT.ReminderSettings.TextSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },

        {
            type = "color",
            name = "Text-Color",
            desc = "Color of Text-Reminders",
            get = function() return NSRT.ReminderSettings.TextSettings.colors end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.TextSettings.colors = {r, g, b, a}
                NSI:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Text reminders",
            get = function() return NSRT.ReminderSettings.TextSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextSettings["Spacing"] = value
                NSI:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Icon Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.ReminderSettings.IconSettings.GrowDirection end,
            values = function() return build_growdirection_options("IconSettings", true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Width",
            desc = "Width of the Icon",
            get = function() return NSRT.ReminderSettings.IconSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.Width = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Height",
            desc = "Height of the Icon",
            get = function() return NSRT.ReminderSettings.IconSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.Height = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },

        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return NSRT.ReminderSettings.IconSettings.Font end,
            values = function() return build_media_options("IconSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return NSRT.ReminderSettings.IconSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Timer-Text Font-Size",
            desc = "Font Size of the Timer-Text",
            get = function() return NSRT.ReminderSettings.IconSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.TimerFontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Icon reminders",
            get = function() return NSRT.ReminderSettings.IconSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings["Spacing"] = value
                NSI:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Glow",
            desc = "At how many seconds you want the Icon to start glowing. 0 = disabled",
            get = function() return NSRT.ReminderSettings.IconSettings["Glow"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings["Glow"] = value
                NSI:UpdateExistingFrames()
            end,
            min = 0,
            max = 10,
            nocombat = true,
        },

        {
            type = "label",
            get = function() return "Bar Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.ReminderSettings.BarSettings.GrowDirection end,
            values = function() return build_growdirection_options("BarSettings") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Bar-Width",
            desc = "Width of the Bar",
            get = function() return NSRT.ReminderSettings.BarSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.Width = value
                NSI:UpdateExistingFrames()
            end,
            min = 80,
            max = 500,
            nocombat = true,
        },
        {
            type = "range",
            name = "Bar-Height",
            desc = "Height of the Bar",
            get = function() return NSRT.ReminderSettings.BarSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.Height = value
                NSI:UpdateExistingFrames()
            end,
            min = 10,
            max = 100,
            nocombat = true,
        },
        {
            type = "select",
            name = "Texture",
            desc = "Texture",
            get = function() return NSRT.ReminderSettings.BarSettings.Texture end,
            values = function() return build_media_options("BarSettings", "Texture", true) end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return NSRT.ReminderSettings.BarSettings.Font end,
            values = function() return build_media_options("BarSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return NSRT.ReminderSettings.BarSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 15,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Timer-Text Font-Size",
            desc = "Font Size of the Timer-Text",
            get = function() return NSRT.ReminderSettings.BarSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.TimerFontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 15,
            max = 200,
            nocombat = true,
        },
        {
            type = "color",
            name = "Bar-Color",
            desc = "Color of the Bars",
            get = function() return NSRT.ReminderSettings.BarSettings.colors end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.BarSettings.colors = {r, g, b, a}
                NSI:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Bar reminders",
            get = function() return NSRT.ReminderSettings.BarSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings["Spacing"] = value
                NSI:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
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
            type = "breakline"
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
                if NSI.PreviewTimer then
                    NSI.PreviewTimer:Cancel()
                    NSI.PreviewTimer = nil
                end
                if NSI.IsInPreview then
                    NSI.IsInPreview = false
                    NSI:HideAllReminders()
                    for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                        if NSI[v] then
                            NSI[v]:StopMovingOrSizing()
                        end
                        NSI:ToggleMoveFrames(NSI[v], false)
                    end
                    return
                end
                NSI.PreviewTimer = C_Timer.NewTimer(12, function()
                    if NSI.IsInPreview then
                        NSI.IsInPreview = false
                        NSI:HideAllReminders()
                        for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                            if NSI[v] then
                                NSI[v]:StopMovingOrSizing()
                            end
                            NSI:ToggleMoveFrames(NSI[v], false)
                        end
                    end
                end)
                NSI.IsInPreview = true
                for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                    NSI:ToggleMoveFrames(NSI[v], true)
                end
                NSI:UpdateExistingFrames()
                NSI.AllGlows = NSI.AllGlows or {}
                local MyFrame = NSI.LGF.GetUnitFrame("player")
                NSI.PlayedSound = {}
                NSI.StartedCountdown = {}
                NSI.GlowStarted = {}
                local info1 = {
                    text = "Personals",
                    phase = 1,
                    id = 1,
                    TTS = NSRT.ReminderSettings.TextTTS and "Personals",
                    TTSTimer = NSRT.ReminderSettings.TextTTSTimer,
                    countdown = NSRT.ReminderSettings.TextCountdown,
                    dur = NSRT.ReminderSettings.TextDuration,
                }
                NSI:DisplayReminder(info1)
                local info2 = {
                    text = "Stack on |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
                    phase = 1,
                    id = 2,
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.TextTTSTimer,
                    countdown = false,
                    dur = NSRT.ReminderSettings.TextDuration,
                }
                NSI:DisplayReminder(info2)
                local info3 = {
                    text = "Give Ironbark",
                    IconOverwrite = true,
                    spellID = 102342,
                    phase = 1,
                    id = 3,
                    TTS = NSRT.ReminderSettings.SpellTTS and "Give Ironbark",
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer,
                    countdown = NSRT.ReminderSettings.SpellCountdown,
                    dur = NSRT.ReminderSettings.SpellDuration,
                    glowunit = {"player"},
                }
                NSI:DisplayReminder(info3)
                local info4 = {
                    text = NSRT.ReminderSettings.SpellName and C_Spell.GetSpellInfo(115203).name,
                    IconOverwrite = true,
                    spellID = 115203,
                    phase = 1,
                    id = 4,
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer,
                    countdown = false,
                    dur = NSRT.ReminderSettings.SpellDuration,
                }
                NSI:DisplayReminder(info4)
                local info5 = {
                    text = "Breath",
                    BarOverwrite = true,
                    spellID = 1256855,
                    phase = 1,
                    id = 5,
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer,
                    countdown = false,
                    dur = NSRT.ReminderSettings.SpellDuration,
                    glowunit = {"player"},
                }
                NSI:DisplayReminder(info5)
                local info6 = {
                    text = "Dodge",
                    BarOverwrite = true,
                    spellID = 193171,
                    phase = 1,
                    id = 6,
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer,
                    countdown = false,
                    dur = NSRT.ReminderSettings.SpellDuration,
                }
                NSI:DisplayReminder(info6)
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
                NSI:UpdateReminderFrame(false, true)
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
                NSI:UpdateReminderFrame(false, true)
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
                NSI:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = "Shared Reminders",
            desc = "Shows a list of all Reminders",
            func = function(self)
                if not NSUI.reminders_frame:IsShown() then
                    NSUI.reminders_frame:Show()
                else
                    NSUI.reminders_frame:Hide()
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = "Personal Reminders",
            desc = "Shows a list of all Personal Reminders",
            func = function(self)
                if not NSUI.personal_reminders_frame:IsShown() then
                    NSUI.personal_reminders_frame:Show()
                else
                    NSUI.personal_reminders_frame:Hide()
                end
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Share on Ready Check",
            desc = "Automatically share the current active reminder on ready check if you are the raidleader.",
            get = function() return NSRT.ReminderSettings.AutoShare end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.AutoShare = value
            end,
            nocombat = true,
        },
        
        {
            type = "toggle",
            boxfirst = true,
            name = "Use TimelineReminders",
            desc = "Toggling this on will make NSRT not display any reminders, but still allow TimelineReminders to read any shared or personal reminder you have and also allow the Note-Display to work.",
            get = function() return NSRT.ReminderSettings.UseTimelineReminders end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UseTimelineReminders = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
                NSI:FireCallback("NSRT_REMINDER_CHANGED", NSI.PersonalReminder, NSI.Reminder)
            end,
            nocombat = true,
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
            name = "Unlock All Reminders Note",
            desc = "Locks/Unlocks the All Reminders Note to be moved around",
            func = function(self)
                if NSI.ReminderFrameMover and NSI.ReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame()
                    NSI:ToggleMoveFrames(NSI.ReminderFrameMover, false)
                    NSI.ReminderFrameMover.Resizer:Hide()
                    NSI.ReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ReminderFrameMoveable = false
                else
                    NSI:UpdateReminderFrame()
                    NSI:ToggleMoveFrames(NSI.ReminderFrameMover, true)
                    NSI.ReminderFrameMover.Resizer:Show()
                    NSI.ReminderFrameMover:SetResizable(true)
                    NSI.ReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.ReminderFrameMoveable = true
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
            get = function() return NSRT.ReminderSettings.ShowReminderFrame end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowReminderFrame = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame()
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
                NSI:UpdateReminderFrame()
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
                NSI:UpdateReminderFrame()
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
                NSI:UpdateReminderFrame()
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
                NSI:UpdateReminderFrame()
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
            type = "toggle",
            boxfirst = true,
            name = "Show Only Spell-Reminders",
            desc = "With this enabled you will only see Spell-Reminders in your notes.",
            get = function() return NSRT.ReminderSettings.OnlySpellReminders end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.OnlySpellReminders = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
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
                    NSI:UpdateReminderFrame(true)
                    NSI:ToggleMoveFrames(NSI.PersonalReminderFrameMover, false)
                    NSI.PersonalReminderFrameMover.Resizer:Hide()
                    NSI.PersonalReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.PersonalReminderFrameMoveable = false
                else
                    NSI:UpdateReminderFrame(true)
                    NSI:ToggleMoveFrames(NSI.PersonalReminderFrameMover, true)
                    NSI.PersonalReminderFrameMover.Resizer:Show()
                    NSI.PersonalReminderFrameMover:SetResizable(true)
                    NSI.PersonalReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.PersonalReminderFrameMoveable = true
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
            get = function() return NSRT.ReminderSettings.ShowPersonalReminderFrame end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowPersonalReminderFrame = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
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
                NSI:UpdateReminderFrame(true)
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
                NSI:UpdateReminderFrame(true)
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
                NSI:UpdateReminderFrame(true)
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
                NSI:UpdateReminderFrame(true)
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
                NSI:UpdateReminderFrame(false, true)
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
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:ToggleMoveFrames(NSI.ExtraReminderFrameMover, false)
                    NSI.ExtraReminderFrameMover.Resizer:Hide()
                    NSI.ExtraReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ExtraReminderFrameMoveable = false
                else
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:ToggleMoveFrames(NSI.ExtraReminderFrameMover, true)
                    NSI.ExtraReminderFrameMover.Resizer:Show()
                    NSI.ExtraReminderFrameMover:SetResizable(true)
                    NSI.ExtraReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.ExtraReminderFrameMoveable = true
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
            get = function() return NSRT.ReminderSettings.ShowExtraReminderFrame end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowExtraReminderFrame = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, false, true)
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
                NSI:UpdateReminderFrame(false, false, true)
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
                NSI:UpdateReminderFrame(false, false, true)
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
                NSI:UpdateReminderFrame(false, false, true)
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
                NSI:UpdateReminderFrame(false, false, true)
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
