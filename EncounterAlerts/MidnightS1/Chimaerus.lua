local _, NSI = ... -- Internal namespace

local encID = 3306
-- /run NSAPI:DebugEncounter(3306)

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end -- Mythic only
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
end

local detectedDurations = {120} -- Devour

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    for k, v in ipairs(detectedDurations) do
        if info.duration > v then -- for now this should work until I know the exact number from heroic week           
            self.Phase = self.Phase+1                  
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            break
        end
    end
end