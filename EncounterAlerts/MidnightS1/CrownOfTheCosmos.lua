local _, NSI = ... -- Internal namespace

local encID = 3181
-- /run NSAPI:DebugEncounter(3181)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        --[[
        local Alert = self:CreateDefaultAlert("Soak", "Bar", 1241291, 8, 1, encID)
        Alert.time = 10
        self:AddToReminder(Alert)
        ]]
    end
end

NSI.ShowWarningAlert[encID] = function(self, encID, phase, time, info) -- on ENCOUNTER_WARNING
    if NSRT.EncounterAlerts[encID].enabled then        
        local severity, dur = info.severity, info.duration
        if severity == 0 then
        elseif severity == 1 then    
        elseif severity == 2 then
        end
    end
end

NSI.ShowBossWhisperAlert[encID] = function(self, encID, phase, time, text, name, dur) -- on RAID_BOSS_WHISPER
    if NSRT.EncounterAlerts[encID].enabled then

    end
end

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
end

local phasedetections = {0, 0, 0, 0, 0, 0, 0}

NSI.DetectPhaseChange[encID] = function(self, e) -- on ENCOUNTER_TIMELINE_EVENT_ADDED/REMOVED
    local now = GetTime()
    local needed = self.Timelines and self.PhaseSwapTime and (now > self.PhaseSwapTime+5) and self.EncounterID and self.Phase and phasedetections[self.Phase]
    if needed and needed > 0 then
        table.insert(self.Timelines, now+0.2)
        local count = 0
        for i, v in ipairs(self.Timelines) do
            if v > now then
                count = count+1
                if count >= needed then
                    self.Phase = self.Phase+1                  
                    self:StartReminders(self.Phase)
                    self.Timelines = {}
                    self.PhaseSwapTime = now
                    break
                end
            end           
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END   
    if NSRT.EncounterAlerts[encID].enabled then
        
    end
end