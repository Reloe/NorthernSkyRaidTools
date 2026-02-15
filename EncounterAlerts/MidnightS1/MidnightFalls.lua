local _, NSI = ... -- Internal namespace

local encID = 3183
-- /run NSAPI:DebugEncounter(3183)
NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
        table.insert(self.Timelines, now)
        local count = 0
        for k, v in ipairs(self.Timelines) do
            if now < v+0.1 then
                count = count+1
                if count >= 3 then
                    self.Phase = self.Phase+1
                    self:StartReminders(self.Phase)
                    self.PhaseSwapTime = now
                    return
                end
            end
        end
    end
end