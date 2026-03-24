local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local function BuildEncounterAlertsOptions()
    return {
        {
            type = "label",
            get = function() return L["OPT_EA_INTRO"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true
        },
        {
            type = "label",
            get = function() return L["OPT_EA_IMPERATOR_AVERZIAN"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_IMPERATOR_AVERZIAN"],
            get = function() return NSRT.EncounterAlerts[3176] and NSRT.EncounterAlerts[3176].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3176] = NSRT.EncounterAlerts[3176] or {}
                NSRT.EncounterAlerts[3176].enabled = value
            end,
            nocombat = true,
            icontexture = 7448209,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["OPT_EA_VORASIUS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_VORASIUS"],
            get = function() return NSRT.EncounterAlerts[3177] and NSRT.EncounterAlerts[3177].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3177] = NSRT.EncounterAlerts[3177] or {}
                NSRT.EncounterAlerts[3177].enabled = value
            end,
            nocombat = true,
            icontexture = 7448210,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["OPT_EA_FALLEN_KING_SALHADAAR"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_FALLEN_KING_SALHADAAR"],
            get = function() return NSRT.EncounterAlerts[3179] and NSRT.EncounterAlerts[3179].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3179] = NSRT.EncounterAlerts[3179] or {}
                NSRT.EncounterAlerts[3179].enabled = value
            end,
            nocombat = true,
            icontexture = 7448212,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_CC_ADDS_DISPLAY"],
            desc = L["OPT_EA_DESC_CC_ADDS_DISPLAY"],
            get = function() return NSRT.EncounterAlerts[3179] and NSRT.EncounterAlerts[3179].CCAddsDisplay end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3179] = NSRT.EncounterAlerts[3179] or {}
                NSRT.EncounterAlerts[3179].CCAddsDisplay = value
            end,
            nocombat = true,
            icontexture = 7448212,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["OPT_EA_VAELGOR_EZZORAK"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_VAELGOR_EZZORAK"],
            get = function() return NSRT.EncounterAlerts[3178] and NSRT.EncounterAlerts[3178].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3178] = NSRT.EncounterAlerts[3178] or {}
                NSRT.EncounterAlerts[3178].enabled = value
            end,
            nocombat = true,
            icontexture = 7448207,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_HEALTH_DISPLAY"],
            desc = L["OPT_EA_DESC_HEALTH_DISPLAY"],
            get = function() return NSRT.EncounterAlerts[3178] and NSRT.EncounterAlerts[3178].HealthDisplay end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3178] = NSRT.EncounterAlerts[3178] or {}
                NSRT.EncounterAlerts[3178].HealthDisplay = value
            end,
            nocombat = true,
            icontexture = 7448207,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["OPT_EA_LIGHTBLINDED_VANGUARD"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_LIGHTBLINDED_VANGUARD"],
            get = function() return NSRT.EncounterAlerts[3180] and NSRT.EncounterAlerts[3180].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3180] = NSRT.EncounterAlerts[3180] or {}
                NSRT.EncounterAlerts[3180].enabled = value
            end,
            nocombat = true,
            icontexture = 7448211,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["OPT_EA_CROWN_OF_THE_COSMOS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_CROWN_OF_THE_COSMOS"],
            get = function() return NSRT.EncounterAlerts[3181] and NSRT.EncounterAlerts[3181].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3181] = NSRT.EncounterAlerts[3181] or {}
                NSRT.EncounterAlerts[3181].enabled = value
            end,
            nocombat = true,
            icontexture = 7448205,
            iconsize = {16, 16},
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return L["OPT_EA_CHIMAERUS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_CHIMAERUS"],
            get = function() return NSRT.EncounterAlerts[3306] and NSRT.EncounterAlerts[3306].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3306] = NSRT.EncounterAlerts[3306] or {}
                NSRT.EncounterAlerts[3306].enabled = value
            end,
            nocombat = true,
            icontexture = 7448202,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["OPT_EA_BELOREN"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_BELOREN"],
            get = function() return NSRT.EncounterAlerts[3182] and NSRT.EncounterAlerts[3182].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3182] = NSRT.EncounterAlerts[3182] or {}
                NSRT.EncounterAlerts[3182].enabled = value
            end,
            nocombat = true,
            icontexture = 7448203,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["OPT_EA_MIDNIGHT_FALLS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_EA_GENERIC_ALERTS"],
            desc = L["OPT_EA_DESC_MIDNIGHT_FALLS"],
            get = function() return NSRT.EncounterAlerts[3183] and NSRT.EncounterAlerts[3183].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183].enabled = value
            end,
            nocombat = true,
            icontexture = 7448204,
            iconsize = {16, 16},
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range",
            name = L["OPT_EA_ENCOUNTER_TEXT_FONT_SIZE"],
            desc = L["OPT_EA_DESC_ENCOUNTER_TEXT_FONT_SIZE"],
            get = function() return NSRT.Settings["GlobalEncounterFontSize"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["GlobalEncounterFontSize"] = value
                NSI.NSRTFrame.SecretDisplay.Text:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings.GlobalEncounterFontSize, "OUTLINE")
            end,
            min = 1,
            max = 100,
        },
    }
end

local function BuildEncounterAlertsCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.EncounterAlerts = {
    BuildOptions = BuildEncounterAlertsOptions,
    BuildCallback = BuildEncounterAlertsCallback,
}
