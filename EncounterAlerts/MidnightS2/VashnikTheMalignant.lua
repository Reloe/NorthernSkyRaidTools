local _, NSI = ... -- Internal namespace

local encID = 3455
-- /run NSAPI:DebugEncounter(3455)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Vashnik Tanks", internalID = "TankHits", name = "Tank-Hits", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1}, loadConditions = tankConditions,
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

    local data = {group = "Vashnik Tanks", internalID = "Taunts", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 6,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {9.0, 36.1, 58.0, 88.0, 120.1, 142.0, 172.0, 204.1, 226.0, 256.1, 288.1, 310.1, 340.1, 372.1, 394.1, 424.1, 456.1},
            [16] = {9.0, 36.1, 58.0, 88.0, 120.1, 142.0, 172.0, 204.1, 226.0, 256.1, 288.1, 310.1, 340.1, 372.1, 394.1, 424.1, 456.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        timers = {
            [15] = {24.0, 108.0, 192.1, 276.1, 360.1, 444.1},
            [16] = {24.0, 108.0, 192.1, 276.1, 360.1, 444.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Infection", text = "Infection", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        timers = {
            [15] = {48.5, 72.5, 102.5, 132.6, 156.6, 186.6, 216.6, 240.6, 270.5, 300.6, 324.6, 354.6, 384.6, 408.6, 438.6},
            [16] = {48.5, 72.5, 102.5, 132.6, 156.6, 186.6, 216.6, 240.6, 270.5, 300.6, 324.6, 354.6, 384.6, 408.6, 438.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "AoE", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        timers = {
            [15] = {35.1, 79.0, 119.1, 163.1, 203.0, 247.0, 287.1, 331.0, 371.0, 415.0},
            [16] = {35.1, 79.0, 119.1, 163.1, 203.0, 247.0, 287.1, 331.0, 371.0, 415.0},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Waves", text = "Waves", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        timers = {
            [15] = {16.0, 46.0, 67.0, 98.1, 130.1, 151.1, 182.0, 214.1, 235.1, 266.1, 298.1, 319.1, 350.1, 382.1, 403.1},
            [16] = {16.0, 46.0, 67.0, 98.1, 130.1, 151.1, 182.0, 214.1, 235.1, 266.1, 298.1, 319.1, 350.1, 382.1, 403.1},
        },
    }
    self:AddEncounterAlert(data)
end
