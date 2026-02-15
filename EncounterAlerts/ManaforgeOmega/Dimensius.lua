local _, NSI = ... -- Internal namespace

local encID = 3135
-- /run NSAPI:DebugEncounter(3135)

local detectedDurations = {
    [14] = {
        {time = 3.157, phase = function(num) return 2 end},
        {time = 5.263, phase = function(num) return 3 end},
    },
    [15] = {
        {time = 3.157, phase = function(num) return 2 end},
        {time = 5.263, phase = function(num) return 3 end},
    },
    [16] = {
        {time = 3.157, phase = function(num) return 2 end},
        {time = 5.263, phase = function(num) return 3 end},
    },
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
