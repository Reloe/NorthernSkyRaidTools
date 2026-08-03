local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local function BuildAssignmentsOptions()
    return {
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Show Assignment on Pull"),
            desc = NSI:Loc("Shows your Assignment on Pull"),
            get = function() return NSRT.AssignmentSettings.OnPull end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings.OnPull = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return NSI:Loc("For the following Boxes only the Settings of the Raidleader matter.") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "label",
            get = function() return NSI:Loc("Season 2") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "label",
            get = function() return NSI:Loc("Sszorak") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Tank Combo Soaks - Mythic"),
            desc = NSI:Loc("Splits Groups 1&2 and Groups 3&4. The first group is assigned to soak left and the second group to soak right. Tanks are ignored."),
            get = function() return NSRT.AssignmentSettings[3420] and NSRT.AssignmentSettings[3420].Mythic end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3420] = NSRT.AssignmentSettings[3420] or {}
                NSRT.AssignmentSettings[3420].Mythic = value
            end,
            nocombat = true,
            icontexture = 7966619,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Tank Combo Soaks - Normal/Heroic"),
            desc = NSI:Loc("Automatically splits players into two role-balanced groups and assigns them to soak left or right. Tanks are ignored."),
            get = function() return NSRT.AssignmentSettings[3420] and NSRT.AssignmentSettings[3420].NormalHeroic end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3420] = NSRT.AssignmentSettings[3420] or {}
                NSRT.AssignmentSettings[3420].NormalHeroic = value
            end,
            nocombat = true,
            icontexture = 7966619,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return NSI:Loc("The Coiled Altar") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Coiled Altar Soaks - Mythic"),
            desc = NSI:Loc("Splits Groups 1&2 and Groups 3&4. Each group is told to soak only on its assigned cast and not soak on the other cast. Tanks are ignored."),
            get = function() return NSRT.AssignmentSettings[3429] and NSRT.AssignmentSettings[3429].Mythic end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3429] = NSRT.AssignmentSettings[3429] or {}
                NSRT.AssignmentSettings[3429].Mythic = value
            end,
            nocombat = true,
            icontexture = 7966625,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Coiled Altar Soaks - Heroic"),
            desc = NSI:Loc("Automatically splits players into two role-balanced groups and tells them to soak or not soak on each cast. Tanks are ignored. There is no Normal-mode assignment."),
            get = function() return NSRT.AssignmentSettings[3429] and NSRT.AssignmentSettings[3429].Heroic end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3429] = NSRT.AssignmentSettings[3429] or {}
                NSRT.AssignmentSettings[3429].Heroic = value
            end,
            nocombat = true,
            icontexture = 7966625,
            iconsize = {16, 16},
        },
        {
            type = "breakline",
        },
        { type = "blank" },
        { type = "blank" },
        {
            type = "label",
            get = function() return NSI:Loc("Season 1") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "label",
            get = function() return NSI:Loc("Vaelgor & Ezzorak") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Gloom Soaks - Mythic Only"),
            desc = NSI:Loc("Assigns Group 1&2 to soak the first cast, Group 3&4 to soak the second cast. This is overkill as only 7 people are required. Alternatively you can create a custom Assignment through wowutils."),
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
            get = function() return NSI:Loc("Lightblinded Vanguard") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Execution Sentence - Mythic Only"),
            desc = NSI:Loc("Automatically assigns players to Front Left/Right and Back Left/Right. Melee are preferred for Front Left/Right, Ranged for Back Left/Right. Healers are evenly split, if you are more than 4healers than some healers will be told to have a 'Flex Spot'"),
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
            get = function() return NSI:Loc("Chimaerus") end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = NSI:Loc("Alndust Upheaval - Mythic"),
            desc = NSI:Loc("Automatically tells Groups 1&2 to soak the first Cast of Alndust Upheaval and Group 3&4 to soak the second cast"),
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
            name = NSI:Loc("Alndust Upheaval - Normal/Heroic"),
            desc = NSI:Loc("For Normal & Heroic the Addon automatically splits healers & dps in half. Tanks are ignored."),
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
