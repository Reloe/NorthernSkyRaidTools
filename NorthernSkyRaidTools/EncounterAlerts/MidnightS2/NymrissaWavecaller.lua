local _, NSI = ... -- Internal namespace

local encID = 3379
-- /run NSAPI:DebugEncounter(3379)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    --[[
    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Nymrissa", internalID = "Adds", name = "Add-Spawn", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 208309,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "Knockback", name = "Knockback", text = "Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1258150,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "ChillingFrost", name = "Chilling Frost", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1313393,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "AbyssalRain", name = "Abyssal Rain", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1260837,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "WaterJet", name = "Water Jet", text = "Frontal", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1258901,
        textColors = {1, 0, 0, 1},
        isConditional = {
            text = "This Alert only shows if you are not a tank or have threat on boss1.",
            func = [=[return function() if UnitGroupRolesAssigned("player") ~= "TANK" then return true end local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]=],
        },
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "Taunt", name = "Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 5, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [=[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]=],
        },
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)
    ]]
end
