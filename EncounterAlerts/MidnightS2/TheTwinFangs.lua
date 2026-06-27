local _, NSI = ... -- Internal namespace

local encID = 3421
-- /run NSAPI:DebugEncounter(3421)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local nonTankConditions = self:DefaultLoadConditions()
    nonTankConditions.Roles.DAMAGER = true
    nonTankConditions.Roles.HEALER = true

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Twin Fangs", internalID = "Defensives", text = "Defensives", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        loadConditions = nonTankConditions,
        timers = {
            [15] = {52.3, 120.0, 221.7, 289.5, 391.2, 458.9},
            [16] = {52.3, 120.0, 221.7, 289.5, 391.2, 458.9},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        timers = {
            [15] = {67.9, 135.6, 237.3, 305.1, 406.8, 474.6},
            [16] = {67.9, 135.6, 237.3, 305.1, 406.8, 474.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "PreSpread", name = "Pre-Spread", text = "Pre-Spread", DisplayType = "Text", encID = encID, phase = 1, TTS = "Spread", dur = 6,
        loadConditions = nonTankConditions,
        timers = {
            [15] = {48.5, 116.2, 218.0, 285.7, 387.4, 455.1},
            [16] = {48.5, 116.2, 218.0, 285.7, 387.4, 455.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "WatchSide", name = "Watch Side", text = "Watch Side", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        timers = {
            [15] = {150.5, 319.9},
            [16] = {150.5, 319.9},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5,
        loadConditions = nonTankConditions,
        timers = {
            [15] = {39.7, 107.5, 209.2, 276.9, 378.6, 446.4},
            [16] = {39.7, 107.5, 209.2, 276.9, 378.6, 446.4},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Orbs", text = "Orbs", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5,
        timers = {
            [15] = {12.9, 80.7, 182.4, 250.2, 351.8, 419.6},
            [16] = {12.9, 80.7, 182.4, 250.2, 351.8, 419.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "TankSoak", name = "Tank Soak", text = "Soak", DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 12, spellID = 1288538,
        loadConditions = tankConditions,
        Ticks = {6, 9},
        isConditional = {
            text = "This Alert only shows if you have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {32.5, 100.3, 202.0, 269.8, 371.4, 439.2},
            [16] = {32.5, 100.3, 202.0, 269.8, 371.4, 439.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Knock", text = "Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1},
        loadConditions = tankConditions,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {9.9, 77.7, 179.4, 247.2, 348.8, 416.6},
            [16] = {9.9, 77.7, 179.4, 247.2, 348.8, 416.6},
        },
    }
    self:AddEncounterAlert(data)
end
