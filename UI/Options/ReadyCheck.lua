local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildReadyCheckOptions()
    return {
        {
            type = "label",
            get = function() return L["OPT_RC_GEAR_MISC_CHECKS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_MISSING_WRONG_ITEM_CHECK"],
            desc = L["OPT_RC_DESC_MISSING_WRONG_ITEM_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.MissingItemCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.MissingItemCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_ITEM_LEVEL_CHECK"],
            desc = L["OPT_RC_DESC_ITEM_LEVEL_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.ItemLevelCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.ItemLevelCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_EMBELLISHMENT_CHECK"],
            desc = L["OPT_RC_DESC_EMBELLISHMENT_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.CraftedCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.CraftedCheck = value
            end,
            nocombat = true,
            icontexture = 4549159,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_4PC_CHECK"],
            desc = L["OPT_RC_DESC_4PC_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.TierCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.TierCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_ENCHANT_CHECK"],
            desc = L["OPT_RC_DESC_ENCHANT_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.EnchantCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.EnchantCheck = value
            end,
            nocombat = true,
            icontexture = 4620672,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_GEM_CHECK"],
            desc = L["OPT_RC_DESC_GEM_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.GemCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.GemCheck = value
            end,
            nocombat = true,
            icontexture = 135998,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_REPAIR_CHECK"],
            desc = L["OPT_RC_DESC_REPAIR_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.RepairCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.RepairCheck = value
            end,
            nocombat = true,
            icontexture = 134520,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_GATEWAY_SHARD_CHECK"],
            desc = L["OPT_RC_DESC_GATEWAY_SHARD_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.GatewayShardCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.GatewayShardCheck = value
            end,
            nocombat = true,
            icontexture = 607513,
            iconsize = {16, 16},
        },

        {
            type = "label",
            get = function() return L["OPT_RC_EXCEPTIONS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_SKIP_GATEWAY_KEYBIND_CHECK"],
            desc = L["OPT_RC_DESC_SKIP_GATEWAY_KEYBIND_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.SkipGatewayKeybindCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.SkipGatewayKeybindCheck = value
            end,
            nocombat = true,
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return L["OPT_RC_BUFF_CHECKS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_RAID_BUFF_CHECK"],
            desc = L["OPT_RC_DESC_RAID_BUFF_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.RaidBuffCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.RaidBuffCheck = value
            end,
            nocombat = true,
            icontexture = 136078,
            iconsize = {16, 16},
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_HEALER_SOULSTONE_CHECK"],
            desc = L["OPT_RC_DESC_HEALER_SOULSTONE_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.SoulstoneCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.SoulstoneCheck = value
            end,
            nocombat = true,
            icontexture = 136210,
            iconsize = {16, 16},
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_SOURCE_OF_MAGIC_CHECK"],
            desc = L["OPT_RC_DESC_SOURCE_OF_MAGIC_CHECK"],
            get = function() return NSRT.ReadyCheckSettings.SourceOfMagicCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.SourceOfMagicCheck = value
            end,
            nocombat = true,
            icontexture = 4630412,
            iconsize = {16, 16},
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return L["OPT_RC_COOLDOWNS_OPTIONS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_ENABLE_COOLDOWN_CHECKING"],
            desc = L["OPT_RC_DESC_ENABLE_COOLDOWN_CHECKING"],
            get = function() return NSRT.Settings["CheckCooldowns"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["CHECK_COOLDOWNS"] = true
                NSRT.Settings["CheckCooldowns"] = value
            end,
            nocombat = true
        },
        {
            type = "range",
            name = L["OPT_RC_PULL_TIMER"],
            desc = L["OPT_RC_DESC_PULL_TIMER"],
            get = function() return NSRT.Settings["CooldownThreshold"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["CooldownThreshold"] = value
            end,
            min = 10,
            max = 60,
            step = 1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_UNREADY_ON_COOLDOWN"],
            desc = L["OPT_RC_DESC_UNREADY_ON_COOLDOWN"],
            get = function() return NSRT.Settings["UnreadyOnCooldown"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["UNREADY_ON_COOLDOWN"] = true
                NSRT.Settings["UnreadyOnCooldown"] = value
            end,
            nocombat = true
        },
        {
            type = "button",
            name = L["OPT_RC_EDIT_COOLDOWNS"],
            desc = L["OPT_RC_DESC_EDIT_COOLDOWNS"],
            func = function(self)
                if not NSUI.cooldowns_frame:IsShown() then
                    NSUI.cooldowns_frame:Show()
                end
            end,
            nocombat = true
        }
    }
end

local function BuildRaidBuffMenu()
    return {
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_RC_FLEX_RAID"],
            desc = L["OPT_RC_DESC_FLEX_RAID"],
            get = function() return NSRT.Settings.FlexRaid end,
            set = function(self, fixedparam, value)
                NSRT.Settings.FlexRaid = value
                NSI:UpdateRaidBuffFrame()
            end,
        },
        {
            type = "button",
            name = L["OPT_RC_DISABLE_THIS_FEATURE"],
            desc = L["OPT_RC_DESC_DISABLE_THIS_FEATURE"],
            func = function(self)
                NSRT.Settings.MissingRaidBuffs = false
                NSI:UpdateRaidBuffFrame()
            end,
        }
    }
end

local function BuildReadyCheckCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.ReadyCheck = {
    BuildOptions = BuildReadyCheckOptions,
    BuildRaidBuffMenu = BuildRaidBuffMenu,
    BuildCallback = BuildReadyCheckCallback,
}
