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
            [15] = {10, 37, 62, 87, 121.1, 146.1, 171, 205.1, 230.1, 255.1, 289.2, 314.1, 339.1, 373.1, 398.2, 423.1, 457.2, 485.1},
            [16] = {10, 37, 62, 87, 121.1, 146.1, 171, 205.1, 230.1, 255.1, 289.2, 314.1, 339.1, 373.1, 398.2, 423.1, 457.2, 485.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Taunts", name = "Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 6,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {10.5, 37.5, 62.5, 87.5, 121.6, 146.6, 171.5, 205.6, 230.6, 255.6, 289.7, 314.6, 339.6, 373.6, 398.7, 423.6, 457.7, 485.6},
            [16] = {10.5, 37.5, 62.5, 87.5, 121.6, 146.6, 171.5, 205.6, 230.6, 255.6, 289.7, 314.6, 339.6, 373.6, 398.7, 423.6, 457.7, 485.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Adds", name = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1284663,
        timers = {
            [15] = {24.1, 108.1, 192, 276.1, 360.1, 444.1, 462.1, 473, 483.1},
            [16] = {24.1, 108.1, 192, 276.1, 360.1, 444.1, 462.1, 473, 483.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Infection", name = "Infection", text = "Infection", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1282114,
        timers = {
            [15] = {42.3, 101.8, 126.1, 185.8, 210.3, 269.5, 294.6, 353.2, 378.1, 437.2, 462.3},
            [16] = {42.3, 101.8, 126.1, 185.8, 210.3, 269.5, 294.6, 353.2, 378.1, 437.2, 462.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "AoE", name = "AoE", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282516,
        timers = {
            [15] = {35, 74, 119.1, 158, 203.1, 242.1, 287.1, 326.1, 371.1, 410.2, 455.2},
            [16] = {35, 74, 119.1, 158, 203.1, 242.1, 287.1, 326.1, 371.1, 410.2, 455.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Soaks", name = "Soaks", text = "Soaks", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282602,
        timers = {
            [15] = {42, 81, 126.1, 165, 210.1, 249.1, 294.1, 333.1, 378.1, 417.2, 462.2},
            [16] = {42, 81, 126.1, 165, 210.1, 249.1, 294.1, 333.1, 378.1, 417.2, 462.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Waves", name = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1281908,
        timers = {
            [15] = {21.1, 62.1, 98.1, 146.1, 182.1, 230.1, 266.1, 314.1, 350.1, 398.1, 434.2, 482},
            [16] = {21.1, 62.1, 98.1, 146.1, 182.1, 230.1, 266.1, 314.1, 350.1, 398.1, 434.2, 482},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Vashnik", internalID = "WaveSpread", name = "Wave-Spread", text = "Pre-Spread", DisplayType = "Text", encID = encID, phase = 1, TTS = "Spread", dur = 6, spellID = 1281908,
        loadConditions = nontankConditions,
        timers = {
            [15] = {13.1, 54.1, 90, 138, 174.1, 222.1, 258.1, 306.1, 342.1, 390.1, 426.2, 474.2},
            [16] = {13.1, 54.1, 90, 138, 174.1, 222.1, 258.1, 306.1, 342.1, 390.1, 426.2, 474.2},
        },
    }
    self:AddEncounterAlert(data)
end
