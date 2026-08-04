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
        loadConditions = nonTankConditions, spellID = 1290956,
        timers = {
            [15] = {52.3, 120, 221.7, 289.5, 391.2, 458.9},
            [16] = {46.9, 107.9, 202, 263.1, 357.1, 418},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Soak", text = "Soak", DisplayType = "Bar", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1290516,
    Ticks = {4.5, 6.5}, barColors = {1, 0, 0, 1},
        timers = {
            [15] = {67.9, 135.6, 237.3, 305.1, 406.8, 474.6},
            [16] = {64.7, 125.7, 216.1, 277.1, 371.1, 432.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "PreSpread", name = "Pre-Spread", text = "Pre-Spread", DisplayType = "Text", encID = encID, phase = 1, TTS = "Spread", dur = 6,
        loadConditions = nonTankConditions, spellID = 1290809,
        timers = {
            [15] = {48.5, 116.2, 218, 285.7, 387.4, 455.1},
            [16] = {43.8, 104.8, 198.7, 259.6, 353.7, 414.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "WatchSide", name = "Watch Side", text = "Watch Side", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1294293,
        timers = {
            [15] = {150.5, 319.9},
            [16] = {136, 290.9},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1291404,
        timers = {
            [15] = {39.7, 107.5, 209.2, 276.9, 378.6, 446.4},
            [16] = {35.8, 96.8, 190.8, 251.7, 345.7, 406.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Orbs", text = "Orbs", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1289994,
        timers = {
            [15] = {12.9, 80.7, 182.4, 250.2, 351.8, 419.6},
            [16] = {11.9, 72.9, 166.7, 227.7, 321.6, 382.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "TankSoak", name = "Tank Soak", text = "Soak", DisplayType = "Bar", encID = encID, phase = 1, TTS = true, TTSTimer = 12, dur = 12, spellID = 1288538,
        loadConditions = tankConditions,
        Ticks = {6, 9},
        isConditional = {
            text = "This Alert only shows if you have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {32.5, 100.3, 202, 269.8, 371.4, 439.2},
            [16] = {30.3, 91.3, 184.3, 245.3, 339.3, 400.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Knock", text = "Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1289192,
        textColors = {1, 0, 0, 1},
        loadConditions = tankConditions,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {9.9, 77.7, 179.4, 247.2, 348.8, 416.6},
            [16] = {9, 70, 164, 225, 318.9, 379.9},
        },
    }
    self:AddEncounterAlert(data)
end
