local _, NSI = ... -- Internal namespace

local encID = 3420
-- /run NSAPI:DebugEncounter(3420)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true
    local nontankConditions = self:DefaultLoadConditions()
    nontankConditions.Roles.HEALER = true
    nontankConditions.Roles.DAMAGER = true

    local data = {group = "Sszorak", internalID = "TankCombo", name = "Tank Combo", text = "Tank Combo", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1277002,
        textColors = {1, 0, 0, 1},
        timers = {
            [15] = {5.5, 55.7, 141.7, 195.9, 281.8, 334.1},
            [16] = {4.9, 52, 132, 179, 259, 306.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "DamageAmp", name = "Damage Amp", text = "Damage Amp", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1286033,
        timers = {
            [15] = {111.1, 249.3},
            [16] = {100, 227.1, 354.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "Bait", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1305959,
        loadConditions = tankConditions,
        timers = {
            [15] = {32.2, 84.4, 170.4, 222.6, 308.5, 360.8},
            [16] = {28.8, 76.8, 156, 203, 282.2, 330.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "WindDebuffs", text = "Wind-Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1285419,
        timers = {
            [15] = {43.4, 95.5, 181.5, 233.7, 319.7, 371.9},
            [16] = {39.7, 86.7, 166.8, 213.8, 293.9, 340.9},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Sszorak", internalID = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1305963,
        loadConditions = nontankConditions,
        timers = {
            [15] = {37.2, 89.5, 175.4, 227.6, 313.5, 365.8},
            [16] = {32, 79.8, 159, 206.8, 286, 333.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "SerpentsFury", name = "Serpent's Fury", text = "Stack Up", DisplayType = "Text", encID = encID, phase = 1, TTS = "Stack", dur = 6,
        loadConditions = nontankConditions,
        timers = {
            [16] = {25, 74, 153, 202, 281, 330},
        },
    }
    self:AddEncounterAlert(data)
end
