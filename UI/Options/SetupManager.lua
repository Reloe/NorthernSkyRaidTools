local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local function BuildSetupManagerOptions()
    return {
        {
            type = "button",
            name = L["OPT_SETUP_DEFAULT_ARRANGEMENT"],
            desc = L["OPT_SETUP_DESC_DEFAULT_ARRANGEMENT"],
            func = function(self)
                NSI:SplitGroupInit(false, true, false)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "button",
            name = L["OPT_SETUP_SPLIT_GROUPS"],
            desc = L["OPT_SETUP_DESC_SPLIT_GROUPS"],
            func = function(self)
                NSI:SplitGroupInit(false, false, false)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "button",
            name = L["OPT_SETUP_SPLIT_EVENS_ODDS"],
            desc = L["OPT_SETUP_DESC_SPLIT_EVENS_ODDS"],
            func = function(self)
                NSI:SplitGroupInit(false, false, true)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "breakline"
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_SETUP_SHOW_MISSING_RAIDBUFFS"],
            desc = L["OPT_SETUP_DESC_SHOW_MISSING_RAIDBUFFS"],
            get = function() return NSRT.Settings.MissingRaidBuffs end,
            set = function(self, fixedparam, value)
                NSRT.Settings.MissingRaidBuffs = value
                NSI:UpdateRaidBuffFrame()
            end,
            nocombat = true,
        },
    }
end

local function BuildSetupManagerCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.SetupManager = {
    BuildOptions = BuildSetupManagerOptions,
    BuildCallback = BuildSetupManagerCallback,
}
