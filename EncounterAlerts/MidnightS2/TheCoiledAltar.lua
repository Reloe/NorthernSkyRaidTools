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
        textColors = {1, 0, 0, 1},
        isConditional = {
            text = "This Alert only shows if you are not a tank or if you have threat on boss1.",
            func = [[return function()
                if UnitGroupRolesAssigned("player") ~= "TANK" then return true end
                local threat = UnitThreatSituation("player", "boss1")
                return threat and threat >= 2
            end]],
        },
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
            [15] = {21.6, 38.5, 58.5, 75.6, 101.6, 118.5, 138.5, 155.6},
            [16] = {21.6, 38.5, 58.5, 75.6, 101.6, 118.5, 138.5, 155.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P1", internalID = "P1Soak", name = "P1 Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8,
        timers = {
            [15] = {48.0, 128.0},
            [16] = {48.0, 128.0},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "MindControls", name = "Mind Controls", text = "Mind Controls", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        timers = {
            [15] = {7.2, 43.3, 92.3, 128.3, 177.3, 213.3},
            [16] = {7.2, 43.3, 92.3, 128.3, 177.3, 213.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Frontal", name = "P2 Frontal", text = "Frontal", DisplayType = "Text", encID = encID, phase = 2, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1},
        isConditional = {
            text = "This Alert only shows if you are not a tank or if you have threat on boss2.",
            func = [[return function()
                if UnitGroupRolesAssigned("player") ~= "TANK" then return true end
                local threat = UnitThreatSituation("player", "boss2")
                return threat and threat >= 2
            end]],
        },
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
            [15] = {35.7, 66.7, 120.8, 151.8, 205.8, 236.8},
            [16] = {35.7, 66.7, 120.8, 151.8, 205.8, 236.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Debuffs", name = "P2 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        loadConditions = nonTankConditions,
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
        if e ~= "UNIT_SPELLCAST_CHANNEL_START" or self.Phase ~= 2 then return end
        C_Timer.After(3.5, function()
            if self.EncounterID ~= encID or self.Phase ~= 2 then return end
            if not UnitChannelInfo("boss2") then return end
            self.Phase = 2.5
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = GetTime()
        end)
    end)
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    self:EncounterRegister("CoiledAltarPhaseDetect", "UNIT_SPELLCAST_CHANNEL_START", false)
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
