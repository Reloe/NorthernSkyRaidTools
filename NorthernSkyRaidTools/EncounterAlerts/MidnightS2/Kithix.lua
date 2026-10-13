local _, NSI = ... -- Internal namespace

local encID = 3513
-- /run NSAPI:DebugEncounter(3513)

NSI:RegisterBuiltinAuraGlow("KithixDispels", {
    name = NSI:Loc("Overwhelming Fear"),
    enabled = false,
    encounterID = encID,
    group = "Season 2",
    menuIcon = 1304046,
    roles = {HEALER = true},
    color = {64 / 255, 1, 1, 1},
    auraFilters = {RaidPlayerDispellable = "Enabled"},
    candidateFilters = {isFromPlayerOrPlayerPet = false},
})

NSI:RegisterBuiltinAuraGlow("KithixMindsting", {
    name = NSI:Loc("Mindsting"),
    encounterID = encID,
    group = "Season 2",
    menuIcon = 1304040,
    roles = {HEALER = true},
    color = {1, 0, 0, 1},
    auraFilters = {CrowdControl = "Enabled"},
    candidateFilters = {MaxDuration = 5},
})

NSI:RegisterBuiltinAuraGlow("KithixNullGate", {
    name = NSI:Loc("Null Gate"),
    encounterID = encID,
    group = "Season 2",
    menuIcon = 1308873,
    roles = {HEALER = true},
    color = {0, 1, 0, 1},
    candidateFilters = {isBossAura = true, MaxDuration = 5},
})

NSI:RegisterBuiltinAuraGlow("KithixUnspeakableHorrors", {
    name = NSI:Loc("Unspeakable Horrors"),
    encounterID = encID,
    group = "Season 2",
    roles = {HEALER = true},
    color = {0, 1, 0, 1},
    candidateFilters = {isBossAura = true, MaxDuration = 6},
})

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local darkDevastationTimers = {23, 43, 66, 132, 152, 175, 241, 261, 284, 350}
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
            [16] = {23.5, 43.5, 66.5, 132.5, 152.5, 175.5, 241.5, 261.5, 284.5, 350.5},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Kith'ix", internalID = "AoE", name = "AoE", text = "Get Orb", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 10, spellID = 1304424,
        timers = {
            [16] = {36, 78, 145, 187, 254, 296},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Kith'ix", internalID = "Darkness", name = "Darkness", text = "Darkness", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1302951,
        timers = {
            [16] = {57, 166, 275},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Kith'ix", internalID = "Adds", name = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1301511,
        timers = {
            [16] = {8, 117, 226, 335},
        },
    }
    self:AddEncounterAlert(data)
end
