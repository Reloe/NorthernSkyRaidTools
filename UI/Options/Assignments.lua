local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local function BuildAssignmentsOptions()
    return {
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_ASSIGN_SHOW_ON_PULL"],
            desc = L["OPT_ASSIGN_DESC_SHOW_ON_PULL"],
            get = function() return NSRT.AssignmentSettings.OnPull end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings.OnPull = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return L["OPT_ASSIGN_RAIDLEADER_ONLY"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "label",
            get = function() return L["OPT_ASSIGN_VAELGOR_EZZORAK"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_ASSIGN_GLOOM_SOAKS_MYTHIC"],
            desc = L["OPT_ASSIGN_DESC_GLOOM_SOAKS_MYTHIC"],
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
            get = function() return L["OPT_ASSIGN_LIGHTBLINDED_VANGUARD"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_ASSIGN_EXECUTION_SENTENCE_MYTHIC"],
            desc = L["OPT_ASSIGN_DESC_EXECUTION_SENTENCE_MYTHIC"],
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
            get = function() return L["OPT_ASSIGN_CHIMAERUS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_ASSIGN_ALNDUST_MYTHIC"],
            desc = L["OPT_ASSIGN_DESC_ALNDUST_MYTHIC"],
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
            name = L["OPT_ASSIGN_ALNDUST_NORMAL_HEROIC"],
            desc = L["OPT_ASSIGN_DESC_ALNDUST_NORMAL_HEROIC"],
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
