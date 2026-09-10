local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildQoLFontFlagOptions()
    local options = {}
    for _, option in ipairs(Core.build_fontflag_options()) do
        local value = option.value
        options[#options + 1] = {
            label = option.label == "None" and NSI:Loc("None") or option.label,
            value = value,
            onclick = function()
                NSRT.QoL.TextDisplay.FontFlags = value
                NSI:UpdateQoLTextDisplay()
            end,
        }
    end
    return options
end

local function BuildGuildRankOptions(settingKey)
    local ranks, seen = {}, {}
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local _, rankName, rankIndex = GetGuildRosterInfo(i)
            if rankName and rankIndex and not seen[rankIndex] then
                seen[rankIndex] = true
                ranks[#ranks + 1] = { rankIndex = rankIndex, rankName = rankName }
            end
        end
        table.sort(ranks, function(a, b) return a.rankIndex < b.rankIndex end)
    end
    local options = {}
    for _, rank in ipairs(ranks) do
        options[#options + 1] = {
            label = rank.rankName,
            value = rank.rankIndex,
            onclick = function(_, _, value)
                NSRT.QoL[settingKey] = value
            end,
        }
    end
    if #options == 0 then
        options[1] = {
            label = NSI:Loc("Not in a Guild"),
            value = NSRT.QoL[settingKey],
            onclick = function() end,
        }
    end
    return options
end

local function BuildBreakTimerTextureOptions()
    local options = {}
    for _, texture in ipairs(NSI.LSM:List("statusbar")) do
        options[#options + 1] = {
            label = texture,
            value = texture,
            onclick = function(_, _, value)
                NSRT.BreakTimer.Texture = value
                NSI:RefreshBreakTimerDisplay()
            end,
        }
    end
    return options
end

local function BuildBreakTimerSoundOptions()
    local options = {}
    for _, name in ipairs(NSI:GetOrderedSoundList()) do
        options[#options + 1] = {
            label = name,
            value = name,
            onclick = function()
                NSRT.BreakTimer.Sound = name
                PlaySoundFile(NSI.LSM:Fetch("sound", name), "Master")
            end,
        }
    end
    return options
end

local function BuildQoLOptions()
    return {
        {
            type = "label",
            get = function() return "Text Display Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview and Move the Text Display.",
            func = function(self)
                NSI.IsQoLTextPreview = not NSI.IsQoLTextPreview
                NSI:ToggleQoLTextPreview()
            end,
            spacement = true
        },
        {
            type = "range",
            name = "Font Size",
            desc = "Font Size for Text Display. The Font itself is controlled by the Global Font found in General Settings.",
            get = function() return NSRT.QoL.TextDisplay.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.QoL.TextDisplay.FontSize = value
                NSI:UpdateQoLTextDisplay()
            end,
            min = 5,
            max = 70,
        },
        {
            type = "select",
            name = "Font Outline",
            desc = "Font outline flags for the QoL Text Display.",
            values = BuildQoLFontFlagOptions,
            get = function() return NSRT.QoL.TextDisplay.FontFlags end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Gateway Useable Display",
            desc = "Whether you want to see a display when you are able to use the gateway.",
            get = function() return NSRT.QoL.GatewayUseableDisplay end,
            set = function(self, fixedparam, value)
                NSRT.QoL.GatewayUseableDisplay = value
                NSI:QoLEvents("ACTIONBAR_UPDATE_USABLE")
                NSI:ToggleQoLEvent("ACTIONBAR_UPDATE_USABLE", value)
            end,
            icontexture = 607512,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Reset Boss Display",
            desc = "Shows a Text while out of combat when you have the lust debuff to remind you that the boss needs to be reset.",
            get = function() return NSRT.QoL.ResetBossDisplay end,
            set = function(self, fixedparam, value)
                NSRT.QoL.ResetBossDisplay = value
                local diff = NSI:DifficultyCheck({14, 15, 16})
                if diff or not value then NSI:UpdateQoLTextDisplay() end
                local turnon = value and diff and not NSI:Restricted()
                NSI:ToggleQoLEvent("UNIT_AURA", turnon)
                NSI:ToggleQoLEvent("PLAYER_REGEN_ENABLED", value)
                NSI:ToggleQoLEvent("PLAYER_REGEN_DISABLED", value)
            end,
            icontexture = 136090,
            iconsize = {16, 16},
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Loot Boss Reminder",
            desc = "Shows a Text after killing a Raid-Boss to remind you to loot the boss for your crests.",
            get = function() return NSRT.QoL.LootBossReminder end,
            set = function(self, fixedparam, value)
                NSRT.QoL.LootBossReminder = value
                NSI:UpdateQoLTextDisplay()
                local turnon = value and NSI:DifficultyCheck({14, 15, 16})
                NSI:ToggleQoLEvent("ENCOUNTER_END", turnon)
                NSI:ToggleQoLEvent("LOOT_OPENED", turnon)
                NSI:ToggleQoLEvent("CHAT_MSG_MONEY", turnon)
                NSI:ToggleQoLEvent("ENCOUNTER_START", turnon)
            end,
            icontexture = 7639523,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Consumable Notifications\nrequires others to have NSRT" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Soulwell",
            desc = "Shows a Text when a Soulwell has been dropped and you have less than 3 Healthstones.",
            get = function() return NSRT.QoL.SoulwellDropped end,
            set = function(self, fixedparam, value)
                NSRT.QoL.SoulwellDropped = value
            end,
            icontexture = 538745,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Feast",
            desc = "Shows a Text when a Feast has been dropped and your Well Fed buff is missing or has less than 10 minutes left.",
            get = function() return NSRT.QoL.FeastDropped end,
            set = function(self, fixedparam, value)
                NSRT.QoL.FeastDropped = value
            end,
            icontexture = 5793729,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Cauldron",
            desc = "Shows a Text when a Cauldron has been dropped.",
            get = function() return NSRT.QoL.CauldronDropped end,
            set = function(self, fixedparam, value)
                NSRT.QoL.CauldronDropped = value
            end,
            icontexture = 1385153,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Repair",
            desc = "Shows a Text when a Repair Bot/Anvil has been dropped and your durability is less than 90%.",
            get = function() return NSRT.QoL.RepairDropped end,
            set = function(self, fixedparam, value)
                NSRT.QoL.RepairDropped = value
            end,
            icontexture = 1405803,
            iconsize = {16, 16},
        },
        {
            type = "range",
            name = "Duration Seconds",
            desc = "Show dropped consumable notifications for the selected number of seconds.",
            get = function() return NSRT.QoL.ConsumableNotificationDurationSeconds or 5 end,
            set = function(self, fixedparam, value)
                NSRT.QoL.ConsumableNotificationDurationSeconds = value
            end,
            min = 1,
            max = 20,
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "Other QoL Things" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Check Vantus-Rune",
            desc = "Check the Vantus Rune status for all raid members.",
            func = function(self)
                NSI:VantusRuneCheck()
            end,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Add SpellID to Tooltips",
            desc = "Automatically enables the cvar to display spellids in tooltips on every reload/login.",
            get = function() return NSRT.QoL.AddSpellIDToTooltips end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AddSpellIDToTooltips = value
                C_CVar.SetCVar("tooltipShowAuraSpellIDs", value and "1" or "0")
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Repair",
            desc = "Whether you want to automatically repair your equipment when visiting a vendor (prefers guild repairs).",
            get = function() return NSRT.QoL.AutoRepair end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoRepair = value
                NSI:ToggleQoLEvent("MERCHANT_SHOW", value)
            end,
            icontexture = 134520,
            iconsize = {16, 16},
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "Break Timer" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "label",
            get = function() return "Started with /ns break <minutes> by the raid leader or an assistant.\nEveryone in the group running NSRT gets the same timer." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Break Timer",
            desc = "Whether you want to see the break timer bar when someone starts a break.",
            get = function() return NSRT.BreakTimer.enabled end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.enabled = value
                if not value then NSI:StopBreakTimer() end
            end,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview and Move the Break Timer bar.",
            func = function(self)
                NSI:ToggleBreakTimerPreview()
            end,
            spacement = true
        },
        {
            type = "button",
            name = "Reset Position",
            desc = "Move the Break Timer bar back to its default position.",
            func = function(self)
                NSI:ResetBreakTimerPosition()
            end,
            spacement = true
        },
        {
            type = "range",
            name = "Bar Width",
            desc = "Width of the break timer bar.",
            get = function() return NSRT.BreakTimer.Width end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.Width = value
                NSI:RefreshBreakTimerDisplay()
            end,
            min = 100,
            max = 600,
        },
        {
            type = "range",
            name = "Bar Height",
            desc = "Height of the break timer bar.",
            get = function() return NSRT.BreakTimer.Height end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.Height = value
                NSI:RefreshBreakTimerDisplay()
            end,
            min = 10,
            max = 80,
        },
        {
            type = "select",
            name = "Break Timer Font",
            desc = "Font for the break timer bar.",
            get = function() return NSRT.BreakTimer.Font or "Expressway" end,
            set = function() end,
            values = function()
                local options = {}
                for _, name in ipairs(NSI.LSM:List("font")) do
                    options[#options + 1] = {
                        label = name,
                        value = name,
                        onclick = function()
                            NSRT.BreakTimer.Font = name
                            NSI:RefreshBreakTimerDisplay()
                        end,
                    }
                end
                return options
            end,
        },
        {
            type = "range",
            name = "Break Timer Font Size",
            desc = "Font size for the break timer bar.",
            get = function() return NSRT.BreakTimer.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.FontSize = value
                NSI:RefreshBreakTimerDisplay()
            end,
            min = 5,
            max = 70,
        },
        {
            type = "select",
            name = "Bar Texture",
            desc = "Texture of the break timer bar.",
            get = function() return NSRT.BreakTimer.Texture end,
            set = function() end,
            values = BuildBreakTimerTextureOptions,
        },
        {
            type = "color",
            name = "Bar Color",
            desc = "Color of the break timer bar.",
            get = function() return unpack(NSRT.BreakTimer.barColors) end,
            set = function(_, r, g, b, a)
                NSRT.BreakTimer.barColors = {r, g, b, a}
                NSI:RefreshBreakTimerDisplay()
            end,
            hasAlpha = true,
        },
        {
            type = "color",
            name = "Break Timer Text Color",
            desc = "Color of the text on the break timer bar.",
            get = function() return unpack(NSRT.BreakTimer.textColors) end,
            set = function(_, r, g, b, a)
                NSRT.BreakTimer.textColors = {r, g, b, a}
                NSI:RefreshBreakTimerDisplay()
            end,
            hasAlpha = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Break Meme",
            desc = "Shows a random meme above the break timer bar.",
            get = function() return NSRT.BreakTimer.ShowMeme end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.ShowMeme = value
                NSI:RefreshBreakTimerDisplay()
            end,
        },
        {
            type = "range",
            name = "Meme Size",
            desc = "Size of the meme shown above the break timer bar.",
            get = function() return NSRT.BreakTimer.MemeSize end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.MemeSize = value
                NSI:RefreshBreakTimerDisplay()
            end,
            min = 32,
            max = 256,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Break Timer Sound",
            desc = "Plays a sound when the break starts, during the last minute and when it is over.",
            get = function() return NSRT.BreakTimer.PlaySound end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.PlaySound = value
            end,
        },
        {
            type = "select",
            name = "Break Sound",
            desc = "Sound played by the break timer.",
            get = function() return NSRT.BreakTimer.Sound end,
            set = function() end,
            values = BuildBreakTimerSoundOptions,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Break in Chat",
            desc = "Sends a raid warning when you start a break, one minute before it ends and when it is over, so people without NSRT know about it too. Only applies to breaks you start yourself.",
            get = function() return NSRT.BreakTimer.SendRaidWarning end,
            set = function(self, fixedparam, value)
                NSRT.BreakTimer.SendRaidWarning = value
            end,
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "Raid Group Tools" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Invite on Whisper",
            desc = "Whether you want to automatically invite players when they whisper you with one of your configured keywords.",
            get = function() return NSRT.QoL.AutoInvite end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoInvite = value
                NSI:ToggleQoLEvent("CHAT_MSG_WHISPER", value)
                NSI:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", value)
            end,
            icontexture = 133460,
            iconsize = {16, 16},
        },
        {
            type = "textentry",
            name = "Invite Keywords",
            desc = "Comma-separated list of whisper keywords that trigger an auto-invite (case-insensitive). Example: inv, invite",
            get = function() return NSRT.QoL.AutoInviteKeywords or "" end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoInviteKeywords = value
                NSI:InvalidateInviteKeywordCache()
            end,
            hooks = {
                OnEnterPressed = function(self) return end
            },
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Guild Members Only",
            desc = "Only auto-invite players who are in your guild. Disable to allow anyone who whispers your keyword to be invited.",
            get = function() return NSRT.QoL.AutoInviteGuildOnly end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoInviteGuildOnly = value
            end,
        },
        {
            type = "select",
            name = "Guild Invite Rank",
            desc =
            "The guild rank threshold used for Invite Online Guild Members. Members at this rank or higher (closer to Guild Master) are invited.",
            values = function() return BuildGuildRankOptions("AutoInviteGuildRankIndex") end,
            get = function() return NSRT.QoL.AutoInviteGuildRankIndex end,
        },
        {
            type = "button",
            name = "Invite Guild Members",
            desc =
            "Invite all online guild members at or above the selected Guild Invite Rank who aren't already in your group.",
            func = function(self)
                NSI:InviteOnlineGuildMembers()
            end,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Accept Guild Invites",
            desc = "Automatically accept group/raid invites sent by members of your guild.",
            get = function() return NSRT.QoL.AutoAcceptGuildInvite end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoAcceptGuildInvite = value
                NSI:ToggleQoLEvent("PARTY_INVITE_REQUEST", value)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Promote Assistants",
            desc = "While you are the raid leader, automatically promote matching raid members to Raid Assistant.",
            get = function() return NSRT.QoL.AutoPromote end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoPromote = value
                NSI:UpdateAutoPromoteEvents(value)
            end,
            icontexture = 132165,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Promote Guild Officers",
            desc = "Automatically promote guild members at or above the selected guild rank.",
            get = function() return NSRT.QoL.AutoPromoteOfficers end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoPromoteOfficers = value
            end,
        },
        {
            type = "select",
            name = "Officer Rank",
            desc = "The guild rank threshold used for Promote Guild Officers. Members at this rank or higher (closer to Guild Master) are promoted.",
            values = function() return BuildGuildRankOptions("AutoPromoteRankIndex") end,
            get = function() return NSRT.QoL.AutoPromoteRankIndex end,
        },
        {
            type = "textentry",
            name = "Always Promote",
            desc = "Comma-separated list of character names or nicknames to always promote to Raid Assistant, regardless of guild rank. Example: Rav, Reloe",
            get = function() return NSRT.QoL.AutoPromoteNames or "" end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoPromoteNames = value
            end,
            hooks = {
                OnEnterPressed = function(self) return end
            },
        },
        {
            type = "button",
            name = "Promote Now",
            desc = "Immediately run an Auto-Promote pass without waiting for a roster change.",
            func = function(self)
                NSI:AutoPromotePass(true)
            end,
            spacement = true
        },
        { type = "label", get = function() return "Setup Manager" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "button",
            name = "Default Arrangement",
            desc = "Sorts groups into a default order (tanks - melee - ranged - healer)",
            func = function(self)
                NSI:SplitGroupInit(false, true, false, false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = "Split Groups",
            desc = "Splits the group evenly into 2 groups. It will even out tanks, melee, ranged and healers, as well as trying to balance the groups by class and specs",
            func = function(self)
                NSI:SplitGroupInit(false, false, false, false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = "Split Evens/Odds",
            desc = "Same as the button above but using groups 1/3/5 and 2/4/6.",
            func = function(self)
                NSI:SplitGroupInit(false, false, true, false)
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
    }
end

local function BuildQoLCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.QoL = {
    BuildOptions = BuildQoLOptions,
    BuildCallback = BuildQoLCallback,
}
