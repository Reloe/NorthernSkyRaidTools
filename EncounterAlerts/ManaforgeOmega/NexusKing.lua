local _, NSI = ... -- Internal namespace

local encID = 3134
-- /run NSAPI:DebugEncounter(3134)

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    for k, v in pairs(phasedetections) do
        if info.duration and info.duration == k then
            self.Phase = v                  
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            return
        end
    end
end
