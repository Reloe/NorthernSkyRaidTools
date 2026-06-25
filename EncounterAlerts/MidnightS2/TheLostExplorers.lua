local _, NSI = ... -- Internal namespace

local encID = 3497
-- /run NSAPI:DebugEncounter(3497)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end

local detectedDurations = {
    [14] = { { time = 60, phase = function(num) return num + 1 end } },
    [15] = { { time = 60, phase = function(num) return num + 1 end } },
    [16] = { { time = 60, phase = function(num) return num + 1 end } },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = self:DifficultyCheck({14, 15, 16})
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][1]
    if phaseinfo and info.duration == phaseinfo.time then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
        end
    end
end
