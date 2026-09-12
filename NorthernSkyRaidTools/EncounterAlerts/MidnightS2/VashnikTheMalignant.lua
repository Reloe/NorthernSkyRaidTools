local _, NSI = ... -- Internal namespace

local encID = 3455
-- /run NSAPI:DebugEncounter(3455)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true
    local nontankConditions = self:DefaultLoadConditions()
    nontankConditions.Roles.HEALER = true
    nontankConditions.Roles.DAMAGER = true

    local data = {group = "Vashnik", internalID = "TankHits", name = "Tank-Hits", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1}, loadConditions = tankConditions, spellID = 1280935,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {10.1, 39.1, 66.1, 94.1, 123.1, 150.1, 178.1, 207.1, 234.1, 262.1, 291.1, 318.1, 346.1, 375.1, 402.1, 430.1, 459.1},
            [16] = {10, 39, 66, 94, 123.1, 150.1, 178.1, 207.1, 234.1, 262.1, 291.1, 318.1, 346.1, 375.1, 402.1, 430.1, 459.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Taunts", name = "Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 6, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {10.6, 39.6, 66.6, 94.6, 123.6, 150.6, 178.6, 207.6, 234.6, 262.6, 291.6, 318.6, 346.6, 375.6, 402.6, 430.6, 459.6},
            [16] = {10.5, 39.5, 66.5, 94.5, 123.6, 150.6, 178.6, 207.6, 234.6, 262.6, 291.6, 318.6, 346.6, 375.6, 402.6, 430.6, 459.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Adds", name = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1284663,
        timers = {
            [16] = {24, 108, 192, 276.1, 360.1, 444.1, 462.1, 473, 483.1},
            [16] = {24, 108, 192, 276.1, 360.1, 444.1, 462.1, 473, 483.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Infection", name = "Infection", text = "Infection", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282114,
        timers = {
            [15] = {42.3, 95, 126, 171, 210.3, 263, 294.6, 347, 378.1, 431, 462.3},
            [16] = {42.4, 94.3, 126.3, 178.3, 210.4, 262.6, 294.4, 346.5, 378.6, 430.6, 462.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "AoE", name = "AoE", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282516,
        timers = {
            [15] = {35, 74, 119.1, 158, 203.1, 242.1, 287.1, 326.1, 371.1, 410.2, 455.2},
            [16] = {35, 74, 119, 158.1, 203.1, 242.1, 287.1, 326.1, 371.1, 410.2, 455.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Soaks", name = "Soaks", text = "Soaks", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282602,
        timers = {
            [15] = {42, 81, 126.1, 165, 210.1, 249.1, 294.1, 333.1, 378.1, 417.2, 462.2},
            [16] = {42, 81, 126, 165.1, 210.1, 249.1, 294.1, 333.1, 378.1, 417.2, 462.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Waves", name = "Waves", text = "Waves", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1281908,
        timers = {
            [15] = {21, 62, 95, 146, 179, 230, 263, 314, 347, 398, 431, 482},
            [16] = {19, 60.1, 93.1, 144.1, 177.1, 228.1, 261.1, 312.1, 345.1, 396.1, 429.1, 480.1},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Vashnik", internalID = "WaveSpread", name = "Wave-Spread", text = "Pre-Spread", DisplayType = "Circle", encID = encID, phase = 1, TTS = "Spread", dur = 6, spellID = 1281908,
        loadConditions = nontankConditions,
        timers = {
            [15] = {13, 54, 87, 138, 171, 222, 255, 306, 339, 390, 423, 474},
            [16] = {13, 54.1, 87.1, 138.1, 171.1, 222.1, 255.1, 306.1, 339.1, 390.1, 423.1, 474.1},
        },
    }
    self:AddEncounterAlert(data)

    self:RemoveEncounterAlert(encID, 16, "WavesLine")
end
