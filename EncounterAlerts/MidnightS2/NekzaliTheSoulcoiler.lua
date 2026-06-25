local _, NSI = ... -- Internal namespace

local encID = 3470
-- /run NSAPI:DebugEncounter(3470)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end

NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    self.NekzaliCastStartTime = nil
    self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED"}, true, "boss1")
    self:EncounterFunction("NekzaliPhaseDetect", function(_, e, unit)
        if self.Phase ~= 1 then return end
        local now = GetTime()
        if e == "UNIT_SPELLCAST_START" then
            self.NekzaliCastStartTime = now
        elseif e == "UNIT_SPELLCAST_SUCCEEDED" and self.NekzaliCastStartTime and ApproximatelyEqual(now - self.NekzaliCastStartTime, 1.5, 0.2) then
            self.NekzaliCastStartTime = nil
            self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED"}, false)
            self.Phase = 1.5
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
        end
    end)
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    self.NekzaliCastStartTime = nil
    self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED"}, false)
end

local detectedDurations = {
    [14] = { [1.5] = { time = 45, phase = function(num) return 2 end } },
    [15] = { [1.5] = { time = 45, phase = function(num) return 2 end } },
    [16] = { [1.5] = { time = 45, phase = function(num) return 2 end } },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if (not self.PhaseSwapTime) or (not self.EncounterID) or (not self.Phase) then return end

    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not (now > self.PhaseSwapTime + 5)) then return end
    local difficultyID = self:DifficultyCheck({14, 15, 16})
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    if phaseinfo and info.duration == phaseinfo.time then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase <= self.Phase then return end
        self.Phase = newphase
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = now
    end
end
