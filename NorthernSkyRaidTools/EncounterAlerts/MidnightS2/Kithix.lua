local _, NSI = ... -- Internal namespace

local encID = 3513
-- /run NSAPI:DebugEncounter(3513)

NSI:RegisterBuiltinAuraGlow("KithixDispels", {
    name = NSI:Loc("Kith'ix Dispels"),
    enabled = false,
    encounterID = encID,
    roles = {HEALER = true},
    color = {0, 0.8, 0.8, 1},
    auraFilters = {RaidPlayerDispellable = "Enabled"},
    candidateFilters = {isFromPlayerOrPlayerPet = false},
})

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local darkDevastationTimers = {23.028, 43.028, 65.996, 132.007, 152.011, 175.003, 241.005, 261.010, 283.996, 350.028}
    local data = {group = "Kith'ix", internalID = "DarkDevastation", name = "Dark Devastation", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1304930,
        textColors = {1, 0, 0, 1}, loadConditions = tankConditions,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [16] = darkDevastationTimers,
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Kith'ix", internalID = "Taunt", name = "Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 8, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [16] = {23.528, 43.528, 66.496, 132.507, 152.511, 175.503, 241.505, 261.510, 284.496, 350.528},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Kith'ix", internalID = "AoE", name = "AoE", text = "Get Orb", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 10, spellID = 1304424,
        timers = {
            [16] = {37.034, 79.032, 146.038, 188.002, 255.032, 297.032},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Kith'ix", internalID = "Darkness", name = "Darkness", text = "Darkness", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1302951,
        timers = {
            [16] = {57.024, 166.037, 275.050},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Kith'ix", internalID = "Adds", name = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1301511,
        timers = {
            [16] = {8.030, 117.022, 226.012, 335.002},
        },
    }
    self:AddEncounterAlert(data)
end
