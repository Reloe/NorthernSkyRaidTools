local _, NSI = ... -- Internal namespace

local encID = 3177
-- /run NSAPI:DebugEncounter(3177)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        
        -- Boss appears to have same timers on all difficulties
        local Alert = self:CreateDefaultAlert("Knock", "Text", nil, 5, 1, encID)
        for i, v in ipairs({12.2, 133.3, 253.7}) do -- Primordial Roar
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS = "Breath", "Breath"
        for i, v in ipairs({102.3, 223.3, 343.8}) do -- Void Breath
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS = "Dodge", "Dodge"
        for i, v in ipairs({81, 91, 202, 212, 322, 332}) do -- Dodge during adds
            Alert.time = v
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
        local Fixate = self:CreateDefaultAlert("Fixate", "Icon", 210099, 15) -- Fixated by Blistercreep. Hiding has to be timed as there is no event
        Fixate.skipdur = true
        self:DisplayReminder(Fixate)
    end
end

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
end

local detectedDurations = {}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    for k, v in ipairs(detectedDurations) do
        if info.duration == v then            
            self.Phase = self.Phase+1                  
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            break
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END   
    if NSRT.EncounterAlerts[encID].enabled then
        
    end
end


