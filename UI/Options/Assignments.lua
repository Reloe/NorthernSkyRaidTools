local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = LibStub("AceLocale-3.0"):GetLocale("NorthernSkyRaidTools")

local function BuildAssignmentsOptions()
    return {
        {
            type = "toggle",
            boxfirst = true,
            name = L["Show Assignment on Pull"],
            desc = L["Shows your Assignment on Pull"],
            get = function() return NSRT.AssignmentSettings.OnPull end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings.OnPull = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return L["For the following Boxes only the Settings of the Raidleader matter."] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "label",
            get = function() return L["Vaelgor & Ezzorak"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Gloom Soaks - Mythic Only"],
            desc = L["Assigns Group 1&2 to soak the first cast, Group 3&4 to soak the second cast. This is overkill as only 7 people are required. Alternatively you can create a custom Assignment through wowutils."],
            get = function() return NSRT.AssignmentSettings[3178] and NSRT.AssignmentSettings[3178].Soaks end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3178] = NSRT.AssignmentSettings[3178] or {}
                NSRT.AssignmentSettings[3178].Soaks = value
            end,
            nocombat = true,
            icontexture = 4914669,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["Lightblinded Vanguard"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Execution Sentence - Mythic Only"],
            desc = L["Automatically assigns players to Star, Orange, Triangle and Purple for Execution Sentence. Melee are preferred for Star/Orange, Ranged for Triangle/Purple. You should be putting down World Markers for this."],
            get = function() return NSRT.AssignmentSettings[3180] and NSRT.AssignmentSettings[3180].Soaks end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3180] = NSRT.AssignmentSettings[3180] or {}
                NSRT.AssignmentSettings[3180].Soaks = value
            end,
            nocombat = true,
            icontexture = 613954,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["Chimaerus"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Alndust Upheaval - Mythic"],
            desc = L["Automatically tells Groups 1&2 to soak the first Cast of Alndust Upheaval and Group 3&4 to soak the second cast"],
            get = function() return NSRT.AssignmentSettings[3306] and NSRT.AssignmentSettings[3306].Soaks end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3306] = NSRT.AssignmentSettings[3306] or {}
                NSRT.AssignmentSettings[3306].Soaks = value
            end,
            nocombat = true,
            icontexture = 5788297,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["Alndust Upheaval - Normal/Heroic"],
            desc = L["For Normal & Heroic the Addon automatically splits healers & dps in half. Tanks are ignored."],
            get = function() return NSRT.AssignmentSettings[3306] and NSRT.AssignmentSettings[3306].SplitSoaks end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3306] = NSRT.AssignmentSettings[3306] or {}
                NSRT.AssignmentSettings[3306].SplitSoaks = value
            end,
            nocombat = true,
            icontexture = 5788297,
            iconsize = {16, 16},
        },
    }
end

local function BuildAssignmentsCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.Assignments = {
    BuildOptions = BuildAssignmentsOptions,
    BuildCallback = BuildAssignmentsCallback,
}
