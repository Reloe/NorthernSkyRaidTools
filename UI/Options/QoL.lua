local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = LibStub("AceLocale-3.0"):GetLocale("NorthernSkyRaidTools")

local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildQoLOptions()
    return {
        {
            type = "label",
            get = function() return L["Text Display Settings"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = L["Preview/Unlock"],
            desc = L["Preview and Move the Text Display."],
            func = function(self)
                NSI.IsQoLTextPreview = not NSI.IsQoLTextPreview
                NSI:ToggleQoLTextPreview()
            end,
            spacement = true
        },
        {
            type = "range",
            name = L["Font Size"],
            desc = L["Font Size for Text Display. The Font itself is controlled by the Global Font found in General Settings."],
            get = function() return NSRT.QoL.TextDisplay.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.QoL.TextDisplay.FontSize = value
                NSI:UpdateQoLTextDisplay()
            end,
            min = 5,
            max = 70,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Gateway Useable Display"],
            desc = L["Whether you want to see a display when you are able to use the gateway."],
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
            name = L["Reset Boss Display"],
            desc = L["Shows a Text while out of combat when you have the lust debuff to remind you that the boss needs to be reset."],
            get = function() return NSRT.QoL.ResetBossDisplay end,
            set = function(self, fixedparam, value)
                NSRT.QoL.ResetBossDisplay = value
                local diff = NSI:DifficultyCheck(14)
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
            name = L["Loot Boss Reminder"],
            desc = L["Shows a Text after killing a Raid-Boss to remind you to loot the boss for your crests."],
            get = function() return NSRT.QoL.LootBossReminder end,
            set = function(self, fixedparam, value)
                NSRT.QoL.LootBossReminder = value
                NSI:UpdateQoLTextDisplay()
                local turnon = value and NSI:DifficultyCheck(14)
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
            get = function() return L["Consumable Notifications\nrequires others to have NSRT"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Soulwell"],
            desc = L["Shows a Text when a Soulwell has been dropped and you have less than 3 Healthstones."],
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
            name = L["Feast"],
            desc = L["Shows a Text when a Feast has been dropped and your Well Fed buff is missing or has less than 10 minutes left."],
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
            name = L["Cauldron"],
            desc = L["Shows a Text when a Cauldron has been dropped."],
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
            name = L["Repair"],
            desc = L["Shows a Text when a Repair Bot/Anvil has been dropped and your durability is less than 90%."],
            get = function() return NSRT.QoL.RepairDropped end,
            set = function(self, fixedparam, value)
                NSRT.QoL.RepairDropped = value
            end,
            icontexture = 1405803,
            iconsize = {16, 16},
        },
        {
            type = "range",
            name = L["Duration Seconds"],
            desc = L["Show dropped consumable notifications for the selected number of seconds."],
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
            get = function() return L["Other QoL Things"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = L["Check Vantus-Rune"],
            desc = L["Check the Vantus Rune status for all raid members."],
            func = function(self)
                NSI:VantusRuneCheck()
            end,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Auto-Repair"],
            desc = L["Whether you want to automatically repair your equipment when visiting a vendor (prefers guild repairs)."],
            get = function() return NSRT.QoL.AutoRepair end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoRepair = value
                NSI:ToggleQoLEvent("MERCHANT_SHOW", value)
            end,
            icontexture = 134520,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Auto-Invite on Whisper"],
            desc = L["Whether you want to automatically invite Guild-Members when they whisper you with 'inv' or 'invite'."],
            get = function() return NSRT.QoL.AutoInvite end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoInvite = value
                NSI:ToggleQoLEvent("CHAT_MSG_WHISPER", value)
                NSI:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", value)
            end,
            icontexture = 133460,
            iconsize = {16, 16},
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
