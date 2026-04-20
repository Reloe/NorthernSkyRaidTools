local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = LibStub("AceLocale-3.0"):GetLocale("NorthernSkyRaidTools")

local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildReadyCheckOptions()
    return {
        {
            type = "label",
            get = function() return L["Gear/Misc Checks"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["Missing/Wrong Item Check"],
            desc = L["Checks if any slots are empty or have an item with the wrong armor type equipped"],
            get = function() return NSRT.ReadyCheckSettings.MissingItemCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.MissingItemCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Item Level Check"],
            desc = L["Checks if you have any slot equipped below the minimum item level"],
            get = function() return NSRT.ReadyCheckSettings.ItemLevelCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.ItemLevelCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Embellishment Check"],
            desc = L["Checks if you have 2 Embellishments equipped"],
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
            name = L["4pc Check"],
            desc = L["Checks if you have 4pc of the current raid-tier equipped."],
            get = function() return NSRT.ReadyCheckSettings.TierCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.TierCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Enchant Check"],
            desc = L["Checks if you have all slots enchanted"],
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
            name = L["Gem Check"],
            desc = L["Checks if you have all slots gemmed. Checking for the unique epic gem currently only works on an english client."],
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
            name = L["Repair Check"],
            desc = L["Checks if any piece needs repair"],
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
            name = L["Gateway Control Shard Check"],
            desc = L["Checks if you have a Gateway Control Shard and whether or not it is located on your actionbars"],
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
            get = function() return L["Exceptions"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["Skip Gateway Keybind-Check"],
            desc = L["If enabled, the addon will not check if your Gateway Shard is bound as there might be addon-combinations where this is producing a false-positive. In those cases you can enable this setting to remove the redundant alert."],
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
            get = function() return L["Buff Checks"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["Raid-Buff Check"],
            desc = L["Checks if any relevant class needs your buff"],
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
            name = L["Healer Soulstone Check"],
            desc = L["Checks for Warlocks whether they have soulstoned a healer and it has at least 5m duration left. It will only check this if Soulstone is ready or has less than 30s CD left."],
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
            name = L["Source of Magic Check"],
            desc = L["Checks for Evokers whether they have Source of Magic on a healer and it has at least 5m duration left."],
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
            get = function() return L["Cooldowns Options"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Enable Cooldown Checking"],
            desc = L["Enable cooldown checking for your cooldowns on ready check. This is only active in Heroic and Mythic Raids."],
            get = function() return NSRT.Settings["CheckCooldowns"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["CHECK_COOLDOWNS"] = true
                NSRT.Settings["CheckCooldowns"] = value
            end,
            nocombat = true
        },
        {
            type = "range",
            name = L["Pull Timer"],
            desc = L["Pull timer used for cooldown checking."],
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
            name = L["Unready on Cooldown"],
            desc = L["Automatically unready if a tracked spell is on cooldown."],
            get = function() return NSRT.Settings["UnreadyOnCooldown"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["UNREADY_ON_COOLDOWN"] = true
                NSRT.Settings["UnreadyOnCooldown"] = value
            end,
            nocombat = true
        },
        {
            type = "button",
            name = L["Edit Cooldowns"],
            desc = L["Edit the cooldowns checked on the ready check."],
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
            name = L["Flex Raid"],
            desc = L["Check raid buffs up to Group 6 instead of only Group 4."],
            get = function() return NSRT.Settings.FlexRaid end,
            set = function(self, fixedparam, value)
                NSRT.Settings.FlexRaid = value
                NSI:UpdateRaidBuffFrame()
            end,
        },
        {
            type = "button",
            name = L["Disable this Feature"],
            desc = L["Disable the Missing Raid Buffs Feature. You can re-enable it in the Setup Manager Settings."],
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
