local _, NSI = ... -- Internal namespace

local encID = 3379
-- /run NSAPI:DebugEncounter(3379)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Nymrissa", internalID = "Adds", name = "Add-Spawn", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 208309,
        timers = {
            [15] = {26.2, 70.1, 137.1, 180.1, 246.3, 290, 356.2, 401.2},
            [16] = {18, 68, 128, 188, 248, 308, 368, 428},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "Waves", name = "Waves", text = "Waves", DisplayType = "Text", encID = encID, phase = 1, TTS = "Dodge", dur = 5, spellID = 1258673,
        timers = {
            [15] = {111, 221, 331, 441},
            [16] = {111, 221, 331, 441},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "Knockback", name = "Knockback", text = "Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1258150,
        timers = {
            [15] = {120, 230, 340, 450},
            [16] = {120, 230, 340, 450},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "ChillingFrost", name = "Chilling Frost", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1313393,
        timers = {
            [15] = {37, 81, 147, 191, 257, 301, 367, 411},
            [16] = {38.1, 82, 148.1, 192.1, 258.1, 302.1, 368.1, 412.1, 478.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nymrissa", internalID = "AbyssalRain", name = "Abyssal Rain", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1260837,
        timers = {
            [15] = {10, 43, 87, 153, 197, 263, 307, 373.1, 417},
            [16] = {10, 43, 87.1, 153, 197, 263, 307, 373, 417.1, 461.1},
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
            [16] = {30, 52, 74, 96, 140, 162, 184, 206, 250, 272, 294, 316, 360, 382, 404, 426},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {name = "Iceblade Flurry"}}, group = "Nymrissa", internalID = "WaterFlurry", name = "Iceblade Flurry", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1282937,
        textColors = {1, 0, 0, 1},
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [=[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]=],
        },
        timers = {
            [15] = {29, 51, 73, 95, 139, 161, 183, 205, 249, 271, 293, 315, 359, 381.1, 403, 425},
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
            [15] = {35, 57, 79, 101, 145, 167, 189, 211, 255, 277, 299, 321, 365, 387.1, 409, 431},
            [16] = {36.5, 58.5, 80.5, 102.5, 146.5, 168.5, 190.5, 212.5, 256.5, 278.5, 300.5, 322.5, 366.5, 388.5, 410.5, 432.5},
        },
    }
    self:AddEncounterAlert(data)
end
