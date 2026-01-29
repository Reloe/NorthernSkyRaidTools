local _, NSI = ...
local DF = _G["DetailsFramework"]

local function BuildEncounterAlertsOptions()
    return {
        {
            type = "label",
            get = function() return "Midnight S1" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Imperator Averzian",
            desc = "Enables Alerts for Imperator Averzian.",
            get = function() return NSRT.EncounterAlerts[3176] and NSRT.EncounterAlerts[3176].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3176] = NSRT.EncounterAlerts[3176] or {}
                NSRT.EncounterAlerts[3176].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Vorasius",
            desc = "Enables Alerts for Vorasius.",
            get = function() return NSRT.EncounterAlerts[3177] and NSRT.EncounterAlerts[3177].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3177] = NSRT.EncounterAlerts[3177] or {}
                NSRT.EncounterAlerts[3177].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Fallen King Salhadaar",
            desc = "Enables Alerts for Fallen King Salhadaar.",
            get = function() return NSRT.EncounterAlerts[3179] and NSRT.EncounterAlerts[3179].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3179] = NSRT.EncounterAlerts[3179] or {}
                NSRT.EncounterAlerts[3179].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Vaelgor & Ezzorak",
            desc = "Enables Alerts for Vaelgor & Ezzorak.",
            get = function() return NSRT.EncounterAlerts[3178] and NSRT.EncounterAlerts[3178].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3178] = NSRT.EncounterAlerts[3178] or {}
                NSRT.EncounterAlerts[3178].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Lightblinded Vanguard",
            desc = "Enables Alerts for Lightblinded Vanguard.",
            get = function() return NSRT.EncounterAlerts[3180] and NSRT.EncounterAlerts[3180].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3180] = NSRT.EncounterAlerts[3180] or {}
                NSRT.EncounterAlerts[3180].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Crown of the Cosmos",
            desc = "Enables Alerts for Crown of the Cosmos.",
            get = function() return NSRT.EncounterAlerts[3181] and NSRT.EncounterAlerts[3181].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3181] = NSRT.EncounterAlerts[3181] or {}
                NSRT.EncounterAlerts[3181].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Chimaerus",
            desc = "Enables Alerts for Chimaerus.",
            get = function() return NSRT.EncounterAlerts[3306] and NSRT.EncounterAlerts[3306].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3306] = NSRT.EncounterAlerts[3306] or {}
                NSRT.EncounterAlerts[3306].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Beloren",
            desc = "Enables Alerts for Beloren.",
            get = function() return NSRT.EncounterAlerts[3182] and NSRT.EncounterAlerts[3182].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3182] = NSRT.EncounterAlerts[3182] or {}
                NSRT.EncounterAlerts[3182].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Midnight Falls",
            desc = "Enables Alerts for Midnight Falls.",
            get = function() return NSRT.EncounterAlerts[3183] and NSRT.EncounterAlerts[3183].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183].enabled = value
            end,
            nocombat = true,
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
