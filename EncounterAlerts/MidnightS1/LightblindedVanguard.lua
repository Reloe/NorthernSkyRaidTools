local _, NSI = ... -- Internal namespace

local encID = 3180
-- /run NSAPI:DebugEncounter(3180)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        -- Shield Break
        local Alert = self:CreateDefaultAlert("Break Shield", "Icon", 1248674, 8, 1, encID)
        for _, time in ipairs(self:DifficultyCheck(16) and {20.9, 78.1, 168.2, 220.5, 282.8} or {}) do -- Need to fix these timers for both difficulties
            Alert.time = time
            self:AddToReminder(Alert)
        end
        -- Aura of Peace
        Alert.text, Alert.TTS, Alert.countdown, Alert.Type, Alert.dur = "Peace Aura", false, 5, nil, 10
        for _, time in ipairs(self:DifficultyCheck(14) and {137.4, 313.3} or {}) do
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
    if not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
    -- Execution Sentence. Need to fix timers for Mythic. Consider different alert for a 5th healer, like "check missing color"
    local group = {}
    local healer = {}
    for unit in self:IterateGroupMembers() do
        local specID = NSAPI:GetSpecs(unit) or 0
        local prio = self.spectable[specID]
        local G = self.GUIDS[unit]
        if UnitGroupRolesAssigned(unit) == "HEALER" then
            table.insert(healer, {unit = unit, prio = prio, GUID = G})
        else
            table.insert(group, {unit = unit, prio = prio, GUID = G})
        end
    end
    self:SortTable(group)
    self:SortTable(healer)
    local mygroup
    local IsHealer = UnitGroupRolesAssigned("player") == "HEALER"
    if IsHealer then
        for i, v in ipairs(healer) do
            if UnitIsUnit("player", v.unit) then
                mygroup = i
                mygroup = math.min(4, mygroup) -- if there are more than 4 healers, put any extra healer in the 4th group                    
            end
        end
    else
        for i, v in ipairs(group) do
            if UnitIsUnit("player", v.unit) then
                mygroup = math.ceil(i/4)
                mygroup = math.min(4, mygroup) -- if there are less than 4healers dps would overflow so put any extra in 4th
                break
            end
        end
    end
    if not mygroup then return end
    local pos = (mygroup == 1 and "Star") or (mygroup == 2 and "Orange") or (mygroup == 3 and "Purple") or (mygroup == 4 and "Green") or ""
    local text = (IsHealer and "Go to {rt"..mygroup.."}") or "Soak {rt"..mygroup.."}"
    local TTS = (IsHealer and "Go to "..pos) or "Soak "..pos
    Alert.time, Alert.TTS, Alert.TTSTimer, Alert.text = 96.1, TTS, 10, text
    self:AddToReminder(Alert)
    Alert.time = 271.2
    self:AddToReminder(Alert)
    Alert.time = 446.3
    self:AddToReminder(Alert)

    if NSRT.AssignmentSettings.OnPull then
        local text = mygroup == 1 and "|cFFFFFF00Star|r" or mygroup == 2 and "|cFFFFA500Orange|r" or mygroup == 3 and "|cFF9400D3Purple|r" or mygroup == 4 and "|cFF00FF00Green|r" or ""
        self:DisplayText("You are assigned to soak |cFF00FF00Execution Sentence|r in the "..text.." Group", 5)
    end
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