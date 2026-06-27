local _, NSI = ... -- Internal namespace

local encID = 3420
-- /run NSAPI:DebugEncounter(3420)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Sszorak", internalID = "TankCombo", name = "Tank Combo", text = "Tank Combo", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1},
        timers = {
            [15] = {5.5, 55.7, 141.7, 195.9, 281.8, 334.1},
            [16] = {5.5, 55.7, 141.7, 195.9, 281.8, 334.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "DamageAmp", name = "Damage Amp", text = "Damage Amp", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        timers = {
            [15] = {111.1, 249.3},
            [16] = {111.1, 249.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "Bait", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8,
        loadConditions = tankConditions,
        timers = {
            [15] = {32.2, 84.4, 170.4, 222.6, 308.5, 360.8},
            [16] = {32.2, 84.4, 170.4, 222.6, 308.5, 360.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        timers = {
            [15] = {43.4, 95.5, 181.5, 233.7, 319.7, 371.9},
            [16] = {43.4, 95.5, 181.5, 233.7, 319.7, 371.9},
        },
    }
    self:AddEncounterAlert(data)
end
