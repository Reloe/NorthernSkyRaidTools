local _, NSI = ... -- Internal namespace

-- The Coiled Altar (3429)

local encID = 3429
-- /run NSAPI:DebugEncounter(3429)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local nonTankConditions = self:DefaultLoadConditions()
    nonTankConditions.Roles.DAMAGER = true
    nonTankConditions.Roles.HEALER = true

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Coiled Altar P1", internalID = "P1Frontal", name = "P1 Frontal", text = "Frontal", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1299684,
        timers = {
            [15] = {23.1, 40.0, 60.0, 77.1, 103.1, 120.0, 140.0, 157.1},
            [16] = {23.1, 40.0, 60.0, 77.1, 103.1, 120.0, 140.0, 157.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar Tanks", internalID = "P1Taunt", name = "P1 Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 6,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {23.6, 40.5, 60.5, 77.6, 103.6, 120.5, 140.5, 157.6},
            [16] = {23.6, 40.5, 60.5, 77.6, 103.6, 120.5, 140.5, 157.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P1", internalID = "P1Soak", name = "P1 Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1283489,
        timers = {
            [15] = {48.0, 128.0},
            [16] = {48.0, 128.0},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "MindControls", name = "Mind Controls", text = "Mind Controls", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6, spellID = 1285643,
        timers = {
            [15] = {7.2, 43.3, 92.3, 128.3, 177.3, 213.3},
            [16] = {7.2, 43.3, 92.3, 128.3, 177.3, 213.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Frontal", name = "P2 Frontal", text = "Frontal", DisplayType = "Text", encID = encID, phase = 2, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1286620,
        timers = {
            [15] = {37.7, 68.7, 122.8, 153.8, 207.8, 238.8},
            [16] = {37.7, 68.7, 122.8, 153.8, 207.8, 238.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar Tanks", internalID = "P2Taunt", name = "P2 Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 2, TTS = true, TTSTimer = 0, dur = 6,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {38.2, 69.2, 123.3, 154.3, 208.3, 239.3},
            [16] = {38.2, 69.2, 123.3, 154.3, 208.3, 239.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Debuffs", name = "P2 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        loadConditions = nonTankConditions, spellID = 1286895,
        timers = {
            [15] = {23.7, 61.7, 108.8, 146.8, 193.8, 231.8},
            [16] = {23.7, 61.7, 108.8, 146.8, 193.8, 231.8},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    self:EncounterRegister("CoiledAltarPhaseDetect", "UNIT_SPELLCAST_CHANNEL_START", true, "boss2")
    self:EncounterFunction("CoiledAltarPhaseDetect", function(_, e, unit)
        if e ~= "UNIT_SPELLCAST_CHANNEL_START" or self.Phase ~= 2 or self:GetActiveEncounterTimelineEventCount() ~= 0 then return end
        self.Phase = 2.5
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = GetTime()
    end)
end

local detectedDurations = {
    [14] = {
        [1] = { time = 70, phase = function() return 2 end },
        [2.5] = { time = 94.1, phase = function() return 3 end },
    },
    [15] = {
        [1] = { time = 70, phase = function() return 2 end },
        [2.5] = { time = 94.1, phase = function() return 3 end },
    },
    [16] = {
        [1] = { time = 70, phase = function() return 2 end },
        [2.5] = { time = 94.1, phase = function() return 3 end },
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end

    local difficultyID = self:DifficultyCheck({14, 15, 16})
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    if not phaseinfo then return end

    if ApproximatelyEqual(info.duration, phaseinfo.time, 0.2) then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase <= self.Phase then return end
        self.Phase = newphase
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = now
    end
end
