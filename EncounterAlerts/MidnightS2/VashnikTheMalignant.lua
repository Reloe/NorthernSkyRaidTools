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
            [15] = {10.0, 37.1, 59.0, 89.0, 121.1, 143.0, 173.0, 205.1, 227.0, 257.1, 289.1, 311.1, 341.1, 373.1, 395.1, 425.1, 457.1},
            [16] = {10.0, 37.1, 59.0, 89.0, 121.1, 143.0, 173.0, 205.1, 227.0, 257.1, 289.1, 311.1, 341.1, 373.1, 395.1, 425.1, 457.1},
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
            [15] = {10.5, 37.6, 59.5, 89.5, 121.6, 143.5, 173.5, 205.6, 227.5, 257.6, 289.6, 311.6, 341.6, 373.6, 395.6, 425.6, 457.6},
            [16] = {10.5, 37.6, 59.5, 89.5, 121.6, 143.5, 173.5, 205.6, 227.5, 257.6, 289.6, 311.6, 341.6, 373.6, 395.6, 425.6, 457.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Adds", name = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1284663,
        timers = {
            [15] = {24.0, 108.0, 192.1, 276.1, 360.1, 444.1},
            [16] = {24.0, 108.0, 192.1, 276.1, 360.1, 444.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Infection", name = "Infection", text = "Infection", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1282114,
        timers = {
            [15] = {47.5, 71.5, 101.5, 131.5, 155.5, 185.5, 215.5, 239.5, 269.5, 299.5, 323.5, 353.5, 383.5, 407.5, 437.5},
            [16] = {47.5, 71.5, 101.5, 131.5, 155.5, 185.5, 215.5, 239.5, 269.5, 299.5, 323.5, 353.5, 383.5, 407.5, 437.5},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "AoE", name = "AoE", text = "AoE+Soaks", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282516,
        timers = {
            [15] = {35.1, 79.0, 119.1, 163.1, 203.0, 247.0, 287.1, 331.0, 371.0, 415.0},
            [16] = {35.1, 79.0, 119.1, 163.1, 203.0, 247.0, 287.1, 331.0, 371.0, 415.0},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Waves", name = "Waves", text = "Waves", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1281908,
        timers = {
            [15] = {16.0, 46.0, 67.0, 98.1, 130.1, 151.1, 182.0, 214.1, 235.1, 266.1, 298.1, 319.1, 350.1, 382.1, 403.1},
            [16] = {16.0, 46.0, 67.0, 98.1, 130.1, 151.1, 182.0, 214.1, 235.1, 266.1, 298.1, 319.1, 350.1, 382.1, 403.1},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Vashnik", internalID = "WaveSpread", name = "Wave-Spread", text = "Pre-Spread", DisplayType = "Text", encID = encID, phase = 1, TTS = "Spread", dur = 6, spellID = 1281908,
        loadConditions = nontankConditions,
        timers = {
            [15] = {10.0, 40.0, 61.0, 92.1, 124.1, 145.1, 176.0, 208.1, 229.1, 260.1, 292.1, 313.1, 344.1, 376.1, 397.1},
            [16] = {10.0, 40.0, 61.0, 92.1, 124.1, 145.1, 176.0, 208.1, 229.1, 260.1, 292.1, 313.1, 344.1, 376.1, 397.1},
        },
    }
    self:AddEncounterAlert(data)
end
