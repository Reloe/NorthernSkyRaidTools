local _, NSI = ... -- Internal namespace

local encID = 3182
-- /run NSAPI:DebugEncounter(3182)

local detectedDurations = { -- Death Drop
    [14] = {
        {time = 6, phase = function(num) return num+1 end},
    },
    [15] = {
        {time = 6, phase = function(num) return num+1 end},
    },
    [16] = {
        {time = 6, phase = function(num) return num+1 end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if not difficultyID or not detectedDurations[difficultyID] then return end
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        if info.duration == phaseinfo.time then
            local newphase = phaseinfo.phase(self.Phase)
            if newphase > self.Phase then
                self.Phase = newphase
                self:StartReminders(self.Phase)
                self.PhaseSwapTime = now
                break
            end
        end
    end
end