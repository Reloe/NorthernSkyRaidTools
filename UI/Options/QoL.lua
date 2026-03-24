local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildQoLOptions()
    return {
        {
            type = "label",
            get = function() return L["OPT_QOL_TEXT_DISPLAY_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = L["OPT_QOL_PREVIEW_UNLOCK"],
            desc = L["OPT_QOL_DESC_PREVIEW_UNLOCK"],
            func = function(self)
                NSI.IsQoLTextPreview = not NSI.IsQoLTextPreview
                NSI:ToggleQoLTextPreview()
            end,
            spacement = true
        },
        {
            type = "range",
            name = L["OPT_QOL_FONT_SIZE"],
            desc = L["OPT_QOL_DESC_FONT_SIZE"],
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
            name = L["OPT_QOL_GATEWAY_USEABLE_DISPLAY"],
            desc = L["OPT_QOL_DESC_GATEWAY_USEABLE_DISPLAY"],
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
            name = L["OPT_QOL_RESET_BOSS_DISPLAY"],
            desc = L["OPT_QOL_DESC_RESET_BOSS_DISPLAY"],
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
            name = L["OPT_QOL_LOOT_BOSS_REMINDER"],
            desc = L["OPT_QOL_DESC_LOOT_BOSS_REMINDER"],
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
            get = function() return L["OPT_QOL_CONSUMABLE_NOTIFICATIONS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_QOL_SOULWELL"],
            desc = L["OPT_QOL_DESC_SOULWELL"],
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
            name = L["OPT_QOL_FEAST"],
            desc = L["OPT_QOL_DESC_FEAST"],
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
            name = L["OPT_QOL_CAULDRON"],
            desc = L["OPT_QOL_DESC_CAULDRON"],
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
            name = L["OPT_QOL_REPAIR"],
            desc = L["OPT_QOL_DESC_REPAIR"],
            get = function() return NSRT.QoL.RepairDropped end,
            set = function(self, fixedparam, value)
                NSRT.QoL.RepairDropped = value
            end,
            icontexture = 1405803,
            iconsize = {16, 16},
        },
        {
            type = "range",
            name = L["OPT_QOL_DURATION_SECONDS"],
            desc = L["OPT_QOL_DESC_DURATION_SECONDS"],
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
            get = function() return L["OPT_QOL_OTHER_QOL_THINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = L["OPT_QOL_CHECK_VANTUS_RUNE"],
            desc = L["OPT_QOL_DESC_CHECK_VANTUS_RUNE"],
            func = function(self)
                NSI:VantusRuneCheck()
            end,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_QOL_AUTO_REPAIR"],
            desc = L["OPT_QOL_DESC_AUTO_REPAIR"],
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
            name = L["OPT_QOL_AUTO_INVITE_WHISPER"],
            desc = L["OPT_QOL_DESC_AUTO_INVITE_WHISPER"],
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
