local _, NSI = ... -- Internal namespace

local encID = 3463
-- /run NSAPI:DebugEncounter(3463)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled or encID == 3463 then -- text, Type, spellID, dur, phase, encID
        --[[
        local Soak = self:CreateDefaultAlert("Soak", "Bar", 1241291, 8, 1, encID)
        Soak.time = 10
        self:AddToReminder(Soak)
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
        --[[ Example
        local Fixate = self:CreateDefaultAlert("Fixate", "Icon", 210099, 15) -- text, type, spellID; dur
        Fixate.skipdur = true
        self:DisplayReminder(Fixate)
        ]]
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
end

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    self.Assignments[encID] = self.Assignments[3306]
    print("in func")
    if not (self.Assignments and self.Assignments[encID]) then return end
    print("past check")
    local diff = 14
    if diff < 14 or diff > 16 then return end
    print("past diff check", diff, self.Assignments[encID].Soaks, self.Assignments[encID].SplitSoaks)
    if diff == 16 and self.Assignments[encID].Soaks then -- For Mythic we use group 1/2 + 3/4
        print("in mythic soak check")
        local subgroup = self:GetSubGroup("player")
        local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
        Alert.dur, Alert.TTSTimer = 10, 5
        for phase = 1, 3 do
            Alert.phase = phase
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
    elseif self.Assignments[encID].SplitSoaks then -- For Normal & Heroic we auto split the group to speed up splits
        local _, first = NSI:GetSortedGroup(true, false, false)
        local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
        local group = 2
        for i, v in ipairs(first) do
            print(v.unitid)
            if UnitIsUnit(v.unitid, "player") and not (UnitGroupRolesAssigned("player") == "TANK") then
                group = 1
                break
            end
        end
        Alert.dur, Alert.TTSTimer = 10, 5
        for phase = 1, 3 do
            Alert.phase = phase
            Alert.time, Alert.text  = 18.7, group <= 1 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            self:AddToReminder(Alert)
            Alert.time, Alert.text = 71.4, group >= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            self:AddToReminder(Alert)
        end
        if NSRT.AssignmentSettings.OnPull then
            local group = group <= 1 and "First" or "Second"
            self:DisplayText("You are assigned to soak |cFF00FF00Alndust Upheaval|r in the |cFF00FF00"..group.."|r Group", 5)
        end
    end
end


local detectedDurations = {
    [16] = {
        {time = 31, phase = function(num) return 1 end},
        {time = 33, phase = function(num) return 1 end},
        {time = 34.5, phase = function(num) return num end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = 16 -- bypass for debug
    if not difficultyID or not detectedDurations[difficultyID] then return end
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        print("Checking duration:", info.duration, "against", phaseinfo.time)
        if info.duration == phaseinfo.time then               
            local newphase = phaseinfo.phase(self.Phase)
            print("Changing to phase:", newphase, "from", self.Phase)
            if newphase > self.Phase then         
                self.Phase = newphase               
                self:StartReminders(self.Phase)
                self.PhaseSwapTime = now
                break
            end
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END   
    if NSRT.EncounterAlerts[encID].enabled then
    end
end