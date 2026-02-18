local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI

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
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Reset Boss Display",
            desc = "Shows a Text while out of combat when you have the lust debuff to remind you that the boss needs to be reset.",
            get = function() return NSRT.QoL.ResetBossDisplay end,
            set = function(self, fixedparam, value)
                NSRT.QoL.ResetBossDisplay = value
                local diff = NSI:DifficultyCheck(14)
                if diff or not value then NSI:UpdateQoLTextDisplay() end
                local turnon = value and diff and not NSI:Restricted()
                NSI:ToggleQoLEvent("UNIT_AURA", turnon)
                NSI:ToggleQoLEvent("ADDON_RESTRICTION_STATE_CHANGED", turnon)
            end,
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
                local turnon = value and NSI:DifficultyCheck(14)
                NSI:ToggleQoLEvent("ENCOUNTER_END", turnon)
                NSI:ToggleQoLEvent("LOOT_OPENED", turnon)
                NSI:ToggleQoLEvent("CHAT_MSG_MONEY", turnon)
                NSI:ToggleQoLEvent("ENCOUNTER_START", turnon)

            end,
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
            name = "Auto-Repair",
            desc = "Whether you want to automatically repair your equipment when visiting a vendor (prefers guild repairs).",
            get = function() return NSRT.QoL.AutoRepair end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoRepair = value
                NSI:ToggleQoLEvent("MERCHANT_SHOW", value)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Invite on Whisper",
            desc = "Whether you want to automatically invite Guild-Members when they whisper you with 'inv' or 'invite'.",
            get = function() return NSRT.QoL.AutoInvite end,
            set = function(self, fixedparam, value)
                NSRT.QoL.AutoInvite = value
                NSI:ToggleQoLEvent("CHAT_MSG_WHISPER", value)
                NSI:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", value)
            end,
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
