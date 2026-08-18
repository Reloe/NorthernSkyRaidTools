local _, NSI = ... -- Internal namespace

local encID = 3379
-- /run NSAPI:DebugEncounter(3379)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Nymrissa", internalID = "Adds", name = "Add-Spawn", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 208309,
        timers = {
            [15] = {32, 149, 266, 383, 500},
            [16] = {32, 149, 266, 383, 500},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "Waves", name = "Waves", text = "Waves", DisplayType = "Text", encID = encID, phase = 1, TTS = "Dodge", dur = 5, spellID = 1258673,
        timers = {
            [15] = {68, 185, 302, 419, 536},
            [16] = {72, 189, 306, 423, 540},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "Knockback", name = "Knockback", text = "Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1258150,
        timers = {
            [15] = {77, 194, 311, 428, 545},
            [16] = {81, 198, 315, 432, 549},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "ChillingFrost", name = "Chilling Frost", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1313393,
        timers = {
            [15] = {33, 53, 104, 150, 170, 220, 267, 287, 338, 384, 404, 454, 501, 521, 572},
            [16] = {3, 34, 58, 104, 120, 151, 175, 221, 237, 268, 292, 338, 354, 385, 409, 455, 471, 502, 526},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "AbyssalRain", name = "Abyssal Rain", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1260837,
        timers = {
            [15] = {5, 122, 239, 356, 473, 590},
            [16] = {11, 128, 245, 362, 479, 596},
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
            [16] = {20, 49, 89, 137, 166, 206, 254, 283, 323, 371, 400, 440, 488, 517, 557},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "WaterFlurry", name = "Iceblade Flurry", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1282937,
        textColors = {1, 0, 0, 1},
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [=[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]=],
        },
        timers = {
            [15] = {16, 46, 95, 133, 163, 212, 250, 280, 329, 367, 397, 446, 484, 514, 563},
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
            [15] = {23, 53, 102, 140, 170, 219, 257, 287, 336, 374, 404, 453, 491, 521, 570},
            [16] = {27, 56, 96, 144, 173, 213, 261, 290, 330, 378, 407, 447, 495, 524, 564},
        },
    }
    self:AddEncounterAlert(data)
end
