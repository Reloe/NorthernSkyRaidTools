local _, NSI = ... -- Internal namespace

local encID = 3135
-- /run NSAPI:DebugEncounter(3135)

local phasedetections = {
    [3.157] = 2,
    [5.263] = 3,
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if self.Phase == 3 and e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        table.insert(self.Timelines, now)
        local count = 0
        for k, v in ipairs(self.Timelines) do
            if now < v+0.1 then
                count = count+1
                if count >= 3 then
                    self.Phase = 4                  
                    self:StartReminders(self.Phase)
                    self.PhaseSwapTime = now
                    return
                end
            end
        end
    end
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