local _, NSI = ... -- Internal namespace

local encID = 3178
-- /run NSAPI:DebugEncounter(3178)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Breath", "Bar", 1244221, 4, 1, encID)
        for _, time in ipairs({17.3, 51.3, 86.3, 174.3, 220.2}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end
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
    -- Gloom Soaks. Need to rework this to assign 8 players
    local Soak = self:CreateDefaultAlert(subgroup == 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK", nil, nil, 10, 1, encID)
    Alert.time, Alert.text, Alert.TTSTimer = 54.4, subgroup == 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK", 4
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 156.1, subgroup == 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 201.2, subgroup == 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 246.1, subgroup == 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)
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