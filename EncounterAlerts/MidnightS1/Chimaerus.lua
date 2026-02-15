local _, NSI = ... -- Internal namespace

local encID = 3306
-- /run NSAPI:DebugEncounter(3306)

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    local diff = select(3, GetInstanceInfo())
    if diff < 14 or diff > 16 then return end
    if diff == 16 and self.Assignments[encID].Soaks then -- For Mythic we use group 1/2 + 3/4
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
        if UnitGroupRolesAssigned("player") == "TANK" then return end -- just end early for tanks
        local _, first = NSI:GetSortedGroup(true, false, false)
        local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
        local group = 2
        for i, v in ipairs(first) do
            if UnitIsUnit(v.unitid, "player") then
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

local detectedDurations = { -- Devour = ~120.9
    [14] = {
        {time = 120, phase = function(num) return num+1 end},
    },
    [15] = {
        {time = 120, phase = function(num) return num+1 end},
    },
    [16] = {
        {time = 120, phase = function(num) return num+1 end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if not difficultyID or not detectedDurations[difficultyID] then return end
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        if info.duration > phaseinfo.time then -- for now this should work until I know the exact number from heroic week
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