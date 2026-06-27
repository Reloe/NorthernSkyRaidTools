local _, NSI = ... -- Internal namespace

-- The Coiled Altar (3429)

local encID = 3429
-- /run NSAPI:DebugEncounter(3429)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
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
