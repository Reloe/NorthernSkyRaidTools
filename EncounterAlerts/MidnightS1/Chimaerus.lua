local _, NSI = ... -- Internal namespace

local encID = 3306
-- /run NSAPI:DebugEncounter(3306)
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
        if not self:DifficultyCheck(16) then return end -- Mythic only
        local DebuffTimes = {30, 84.6} -- time at which the debuffs happen so we automatically ignore all other alerts
        local now = GetTime()
        for i, time in ipairs(DebuffTimes) do
            if self.PhaseSwapTime < time+now+3 and self.PhaseSwapTime > time+now-3 then                
                local Debuff = self:CreateDefaultAlert("Debuff", "Icon", 1264756, 5) -- Rift Madness Debuff
                Debuff.TTS = "Targeted"
                self:DisplayReminder(Debuff)
            end
        end
    end
end

NSI.ShowBossWhisperAlert[encID] = function(self, encID, phase, time, text, name, dur) -- on RAID_BOSS_WHISPER
    if NSRT.EncounterAlerts[encID].enabled then

    end
end

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
    Alert.dur, Alert.TTSTimer = 10, 5
    for phase = 1, 3 do
        Alert.Phase = phase
        Alert.time, Alert.text  = 18.7, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
        self:AddToReminder(Alert)
        Alert.time, Alert.text = 71.4, subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
        self:AddToReminder(Alert)
        Alert.time, Alert.text = 138.7, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
        self:AddToReminder(Alert)
    end

    if NSRT.AssignmentSettings.OnPull then
        local group = subgroup <= 2 and "First" or "Second"
        self:DisplayText("You are assigned to soak |cFF00FF00Alndust Upheaval|r in the |cFF00FF00"..group.."|r Group", 5)
    end
end

local detectedDurations = {120.9} -- Devour

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