local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local build_media_options = Core.build_media_options
local build_growdirection_options = Core.build_growdirection_options
local build_raidframeicon_options = Core.build_raidframeicon_options
local build_sound_dropdown = Core.build_sound_dropdown

local function BuildReminderOptions()
    return {
        {
            type = "label",
            get = function() return L["OPT_REM_SPELL_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_COMMON_TTS"],
            desc = L["OPT_REM_DESC_TTS_PLAYED"],
            get = function() return NSRT.ReminderSettings["SpellTTS"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellTTS"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_TTS_TIMER"],
            desc = L["OPT_REM_DESC_TTS_TIMER"],
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
            name = L["OPT_COMMON_DURATION"],
            desc = L["OPT_REM_DESC_DURATION"],
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
            name = L["OPT_COMMON_COUNTDOWN"],
            desc = L["OPT_REM_DESC_COUNTDOWN"],
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
            name = L["OPT_REM_ANNOUNCE_DURATION"],
            desc = L["OPT_REM_DESC_ANNOUNCE_SPELL_DURATION"],
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
            name = L["OPT_REM_SPELLNAME"],
            desc = L["OPT_REM_DESC_SPELLNAME"],
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
            name = L["OPT_REM_SPELLNAME_TTS_IF_EMPTY"],
            desc = L["OPT_REM_DESC_SPELLNAME_TTS_IF_EMPTY"],
            get = function() return NSRT.ReminderSettings.SpellNameTTS end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.SpellNameTTS = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_BARS"],
            desc = L["OPT_REM_DESC_BARS"],
            get = function() return NSRT.ReminderSettings["Bars"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["Bars"] = value
            end,
            nocombat = true,
        },
        {
            type = "range",
            boxfirst = true,
            name = L["OPT_REM_STICKY"],
            desc = L["OPT_REM_DESC_STICKY"],
            get = function() return NSRT.ReminderSettings["Sticky"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["Sticky"] = value
            end,
            nocombat = true,
            min = 0,
            max = 10,
        },
        {
            type = "label",
            get = function() return L["OPT_REM_TEXT_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = L["OPT_COMMON_GROW_DIRECTION"],
            desc = L["OPT_COMMON_GROW_DIRECTION"],
            get = function() return NSRT.ReminderSettings.TextSettings.GrowDirection end,
            values = function() return build_growdirection_options("TextSettings") end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_COMMON_TTS"],
            desc = L["OPT_REM_DESC_TTS_PLAYED"],
            get = function() return NSRT.ReminderSettings["TextTTS"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextTTS"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_TTS_TIMER"],
            desc = L["OPT_REM_DESC_TTS_TIMER"],
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
            name = L["OPT_COMMON_DURATION"],
            desc = L["OPT_REM_DESC_DURATION"],
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
            name = L["OPT_COMMON_COUNTDOWN"],
            desc = L["OPT_REM_DESC_COUNTDOWN"],
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
            name = L["OPT_REM_ANNOUNCE_DURATION"],
            desc = L["OPT_REM_DESC_ANNOUNCE_TEXT_DURATION"],
            get = function() return NSRT.ReminderSettings["AnnounceTextDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["AnnounceTextDuration"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["OPT_COMMON_FONT"],
            desc = L["OPT_COMMON_FONT"],
            get = function() return NSRT.ReminderSettings.TextSettings.Font end,
            values = function() return build_media_options("TextSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_FONT_SIZE"],
            desc = L["OPT_REM_DESC_FONT_SIZE"],
            get = function() return NSRT.ReminderSettings.TextSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },

        {
            type = "color",
            name = L["OPT_REM_TEXT_COLOR"],
            desc = L["OPT_REM_DESC_TEXT_COLOR"],
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
            name = L["OPT_REM_SPACING"],
            desc = L["OPT_REM_DESC_TEXT_SPACING"],
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
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_CENTER_ALIGNED_TEXT"],
            desc = L["OPT_REM_DESC_CENTER_ALIGNED_TEXT"],
            get = function() return NSRT.ReminderSettings.TextSettings.CenterAligned end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextSettings.CenterAligned = value
                NSI:UpdateExistingFrames()
            end,
            nocombat = true,
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return L["OPT_REM_ICON_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = L["OPT_COMMON_GROW_DIRECTION"],
            desc = L["OPT_COMMON_GROW_DIRECTION"],
            get = function() return NSRT.ReminderSettings.IconSettings.GrowDirection end,
            values = function() return build_growdirection_options("IconSettings", true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_ICON_WIDTH"],
            desc = L["OPT_REM_DESC_ICON_WIDTH"],
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
            name = L["OPT_REM_ICON_HEIGHT"],
            desc = L["OPT_REM_DESC_ICON_HEIGHT"],
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
            name = L["OPT_COMMON_FONT"],
            desc = L["OPT_COMMON_FONT"],
            get = function() return NSRT.ReminderSettings.IconSettings.Font end,
            values = function() return build_media_options("IconSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_FONT_SIZE"],
            desc = L["OPT_REM_DESC_FONT_SIZE"],
            get = function() return NSRT.ReminderSettings.IconSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_TEXT_X_OFFSET"],
            desc = L["OPT_REM_DESC_ICON_TEXT_X_OFFSET"],
            get = function() return NSRT.ReminderSettings.IconSettings.xTextOffset end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.xTextOffset = value
                NSI:UpdateExistingFrames()
            end,
            min = -500,
            max = 500,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_TEXT_Y_OFFSET"],
            desc = L["OPT_REM_DESC_ICON_TEXT_Y_OFFSET"],
            get = function() return NSRT.ReminderSettings.IconSettings.yTextOffset end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.yTextOffset = value
                NSI:UpdateExistingFrames()
            end,
            min = -500,
            max = 500,
            nocombat = true,
        },
        {
            type = "toggle",
            name = L["OPT_REM_RIGHT_ALIGNED_TEXT"],
            desc = L["OPT_REM_DESC_RIGHT_ALIGNED_TEXT"],
            get = function() return NSRT.ReminderSettings.IconSettings.RightAlignedText end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.RightAlignedText = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_TIMER_TEXT_FONT_SIZE"],
            desc = L["OPT_REM_DESC_TIMER_FONT_SIZE"],
            get = function() return NSRT.ReminderSettings.IconSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.TimerFontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_SPACING"],
            desc = L["OPT_REM_DESC_ICON_SPACING"],
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
            name = L["OPT_REM_ICON_GLOW"],
            desc = L["OPT_REM_DESC_ICON_GLOW"],
            get = function() return NSRT.ReminderSettings.IconSettings["Glow"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings["Glow"] = value
                NSI:UpdateExistingFrames()
            end,
            min = 0,
            max = 30,
            nocombat = true,
        },

        {
            type = "label",
            get = function() return L["OPT_REM_BAR_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = L["OPT_COMMON_GROW_DIRECTION"],
            desc = L["OPT_COMMON_GROW_DIRECTION"],
            get = function() return NSRT.ReminderSettings.BarSettings.GrowDirection end,
            values = function() return build_growdirection_options("BarSettings") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_BAR_WIDTH"],
            desc = L["OPT_REM_DESC_BAR_WIDTH"],
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
            name = L["OPT_REM_BAR_HEIGHT"],
            desc = L["OPT_REM_DESC_BAR_HEIGHT"],
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
            name = L["OPT_REM_TEXTURE"],
            desc = L["OPT_REM_DESC_TEXTURE"],
            get = function() return NSRT.ReminderSettings.BarSettings.Texture end,
            values = function() return build_media_options("BarSettings", "Texture", true) end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["OPT_COMMON_FONT"],
            desc = L["OPT_COMMON_FONT"],
            get = function() return NSRT.ReminderSettings.BarSettings.Font end,
            values = function() return build_media_options("BarSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_FONT_SIZE"],
            desc = L["OPT_REM_DESC_FONT_SIZE"],
            get = function() return NSRT.ReminderSettings.BarSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_TIMER_TEXT_FONT_SIZE"],
            desc = L["OPT_REM_DESC_TIMER_FONT_SIZE"],
            get = function() return NSRT.ReminderSettings.BarSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.TimerFontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "color",
            name = L["OPT_REM_BAR_COLOR"],
            desc = L["OPT_REM_DESC_BAR_COLOR"],
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
            name = L["OPT_REM_SPACING"],
            desc = L["OPT_REM_DESC_BAR_SPACING"],
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
            get = function() return L["OPT_REM_RAIDFRAME_ICON_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range",
            name = L["OPT_REM_ICON_WIDTH"],
            desc = L["OPT_REM_DESC_ICON_WIDTH"],
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
            name = L["OPT_REM_ICON_HEIGHT"],
            desc = L["OPT_REM_DESC_ICON_HEIGHT"],
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
            name = L["OPT_REM_POSITION"],
            desc = L["OPT_REM_DESC_RAIDFRAME_POSITION"],
            get = function() return NSRT.ReminderSettings.UnitIconSettings.Position end,
            values = function() return build_raidframeicon_options() end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_REM_X_OFFSET"],
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
            name = L["OPT_REM_Y_OFFSET"],
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
            name = L["OPT_REM_GLOW_COLOR"],
            desc = L["OPT_REM_DESC_RAIDFRAME_GLOW_COLOR"],
            get = function() return NSRT.ReminderSettings.GlowSettings.colors end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.GlowSettings.colors = {r, g, b, a}
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "label",
            get = function() return L["OPT_REM_UNIVERSAL_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_HIDE_TIMER_TEXT"],
            desc = L["OPT_REM_DESC_HIDE_TIMER_TEXT"],
            get = function() return NSRT.ReminderSettings["HideTimerText"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["HideTimerText"] = value
                NSI:UpdateExistingFrames()
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_PLAY_SOUND_INSTEAD_OF_TTS"],
            desc = L["OPT_REM_DESC_PLAY_DEFAULT_SOUND"],
            get = function() return NSRT.ReminderSettings["PlayDefaultSound"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["PlayDefaultSound"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },

        {
            type = "select",
            name = L["OPT_REM_SOUND"],
            desc = L["OPT_REM_DESC_SOUND"],
            get = function() return NSRT.ReminderSettings.DefaultSound end,
            values = function() return build_sound_dropdown() end,
            nocombat = true,
        },

        {
            type = "breakline",
        },

        {
            type = "label",
            get = function() return L["OPT_REM_MANAGE_REMINDERS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = L["OPT_REM_PREVIEW_ALERTS"],
            desc = L["OPT_REM_DESC_PREVIEW_ALERTS"],
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
                NSI:UpdateExistingFrames()
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_USE_SHARED_REMINDERS"],
            desc = L["OPT_REM_DESC_USE_SHARED"],
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
            name = L["OPT_REM_USE_PERSONAL_REMINDERS"],
            desc = L["OPT_REM_DESC_USE_PERSONAL"],
            get = function() return NSRT.ReminderSettings.PersNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersNote = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_USE_MRT_NOTE_REMINDERS"],
            desc = L["OPT_REM_DESC_USE_MRT_NOTE"],
            get = function() return NSRT.ReminderSettings.MRTNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.MRTNote = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = L["OPT_REM_SHARED_REMINDERS"],
            desc = L["OPT_REM_DESC_SHARED_LIST"],
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
            name = L["OPT_REM_PERSONAL_REMINDERS"],
            desc = L["OPT_REM_DESC_PERSONAL_LIST"],
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
            name = L["OPT_REM_SHARE_ON_RC"],
            desc = L["OPT_REM_DESC_SHARE_ON_RC"],
            get = function() return NSRT.ReminderSettings.AutoShare end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.AutoShare = value
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = L["OPT_REM_TEST_ACTIVE"],
            desc = L["OPT_REM_DESC_TEST_ACTIVE"],
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
            get = function() return L["OPT_REM_NOTE_INTRO"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return L["OPT_REM_ALL_NOTE_TITLE"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = L["OPT_REM_TOGGLE_ALL_NOTE"],
            desc = L["OPT_REM_DESC_TOGGLE_ALL_NOTE"],
            func = function(self)
                if NSI.ReminderFrameMover and NSI.ReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(false, true)
                    NSI:ToggleMoveFrames(NSI.ReminderFrameMover, false)
                    NSI.ReminderFrameMover.Resizer:Hide()
                    NSI.ReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ReminderFrame.Moveable = false
                else
                    NSI:UpdateReminderFrame(false, true)
                    NSI:ToggleMoveFrames(NSI.ReminderFrameMover, true)
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
            name = L["OPT_REM_SHOW_ALL_NOTE"],
            desc = L["OPT_REM_DESC_SHOW_ALL_NOTE"],
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
            name = L["OPT_COMMON_FONT_SIZE"],
            desc = L["OPT_REM_DESC_ALL_NOTE_FONT_SIZE"],
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
            name = L["OPT_COMMON_FONT"],
            desc = L["OPT_REM_DESC_ALL_NOTE_FONT"],
            get = function() return NSRT.ReminderSettings.ReminderFrame.Font end,
            values = function()
                return build_media_options("ReminderFrame", "Font", false, true, false)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_WIDTH"],
            desc = L["OPT_REM_DESC_ALL_NOTE_WIDTH"],
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
            name = L["OPT_COMMON_HEIGHT"],
            desc = L["OPT_REM_DESC_ALL_NOTE_HEIGHT"],
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
            name = L["OPT_COMMON_BG_COLOR"],
            desc = L["OPT_REM_DESC_ALL_NOTE_BG"],
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
            name = L["OPT_REM_SHOW_TEXT_IN_ALL_NOTE"],
            desc = L["OPT_REM_DESC_TEXT_IN_ALL_NOTE"],
            get = function() return NSRT.ReminderSettings.TextInSharedNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextInSharedNote = value
                NSI:UpdateReminderFrame(false, true)
            end,
        },
        {
            type = "label",
            get = function() return L["OPT_REM_UNIVERSAL_NOTE_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_HIDE_PLAYER_NAMES_IN_NOTE"],
            desc = L["OPT_REM_DESC_HIDE_PLAYER_NAMES"],
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
            name = L["OPT_REM_SHOW_ONLY_SPELL_REMINDERS"],
            desc = L["OPT_REM_DESC_ONLY_SPELL_REMINDERS"],
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
            name = L["OPT_REM_COUNTDOWN_HIDE_TIMERS_IN_NOTES"],
            desc = L["OPT_REM_DESC_NOTE_COUNTDOWN"],
            get = function() return NSRT.ReminderSettings.NoteCountdown end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.NoteCountdown = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_REM_SHOW_OUTSIDE_OF_RAID"],
            desc = L["OPT_REM_DESC_SHOW_OUTSIDE_RAID"],
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
            get = function() return L["OPT_REM_PERSONAL_NOTE_TITLE"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = L["OPT_REM_TOGGLE_PERSONAL_NOTE"],
            desc = L["OPT_REM_DESC_TOGGLE_PERSONAL_NOTE"],
            func = function(self)
                if NSI.PersonalReminderFrameMover and NSI.PersonalReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:ToggleMoveFrames(NSI.PersonalReminderFrameMover, false)
                    NSI.PersonalReminderFrameMover.Resizer:Hide()
                    NSI.PersonalReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.PersonalReminderFrame.Moveable = false
                else
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:ToggleMoveFrames(NSI.PersonalReminderFrameMover, true)
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
            name = L["OPT_REM_SHOW_PERSONAL_NOTE"],
            desc = L["OPT_REM_DESC_SHOW_PERSONAL_NOTE"],
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
            name = L["OPT_COMMON_FONT_SIZE"],
            desc = L["OPT_REM_DESC_PERSONAL_NOTE_FONT_SIZE"],
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
            name = L["OPT_COMMON_FONT"],
            desc = L["OPT_REM_DESC_PERSONAL_NOTE_FONT"],
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.Font end,
            values = function()
                return build_media_options("PersonalReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_WIDTH"],
            desc = L["OPT_REM_DESC_PERSONAL_NOTE_WIDTH"],
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
            name = L["OPT_COMMON_HEIGHT"],
            desc = L["OPT_REM_DESC_PERSONAL_NOTE_HEIGHT"],
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
            name = L["OPT_COMMON_BG_COLOR"],
            desc = L["OPT_REM_DESC_PERSONAL_NOTE_BG"],
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
            name = L["OPT_REM_SHOW_TEXT_IN_PERSONAL_NOTE"],
            desc = L["OPT_REM_DESC_TEXT_IN_PERSONAL_NOTE"],
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
            get = function() return L["OPT_REM_TEXT_NOTE_TITLE"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = L["OPT_REM_TOGGLE_TEXT_NOTE"],
            desc = L["OPT_REM_DESC_TOGGLE_TEXT_NOTE"],
            func = function(self)
                if NSI.ExtraReminderFrameMover and NSI.ExtraReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(false, false, false, true)
                    NSI:ToggleMoveFrames(NSI.ExtraReminderFrameMover, false)
                    NSI.ExtraReminderFrameMover.Resizer:Hide()
                    NSI.ExtraReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ExtraReminderFrame.Moveable = false
                else
                    NSI:UpdateReminderFrame(false, false, false, true)
                    NSI:ToggleMoveFrames(NSI.ExtraReminderFrameMover, true)
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
            name = L["OPT_REM_SHOW_TEXT_NOTE"],
            desc = L["OPT_REM_DESC_SHOW_TEXT_NOTE"],
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
            name = L["OPT_COMMON_FONT_SIZE"],
            desc = L["OPT_REM_DESC_TEXT_NOTE_FONT_SIZE"],
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
            name = L["OPT_COMMON_FONT"],
            desc = L["OPT_REM_DESC_TEXT_NOTE_FONT"],
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.Font end,
            values = function()
                return build_media_options("ExtraReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["OPT_COMMON_WIDTH"],
            desc = L["OPT_REM_DESC_TEXT_NOTE_WIDTH"],
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
            name = L["OPT_COMMON_HEIGHT"],
            desc = L["OPT_REM_DESC_TEXT_NOTE_HEIGHT"],
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
            name = L["OPT_COMMON_BG_COLOR"],
            desc = L["OPT_REM_DESC_TEXT_NOTE_BG"],
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
            get = function() return L["OPT_REM_TIMELINE"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = L["OPT_REM_OPEN_TIMELINE"],
            desc = L["OPT_REM_DESC_OPEN_TIMELINE"],
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
