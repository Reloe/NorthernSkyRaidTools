local _, NSI = ... -- Internal namespace

local encID = 3178
-- /run NSAPI:DebugEncounter(3178)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Breath", "Bar", 1244221, 4, 1, encID)
        -- same timer on all difficultes for now, timers behaved a bit weirdly on beta
        local id = self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [14] = {17.3, 51.3, 86.3, 174.3, 220.2},
            [15] = {17.3, 51.3, 86.3, 174.3, 220.2},
            [16] = {17.3, 51.3, 86.3, 174.3, 220.2},
        }
        for _, time in ipairs(timers[id]) do
            Alert.time = time
            self:AddToReminder(Alert)
        end
    end
end

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
    -- Assigning Group 1&2 on first soak, Group 3&4 on second soak
    local Soak = self:CreateDefaultAlert(subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK", nil, nil, 10, 1, encID)
    Alert.time, Alert.text, Alert.TTSTimer = 54.4, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK", 4
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 156.1, subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 201.2, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 246.1, subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)


    if NSRT.AssignmentSettings.OnPull then
        local group = subgroup <= 2 and "First" or "Second"
        self:DisplayText("You are assigned to soak |cFF00FF00Gloom|r in the |cFF00FF00"..group.."|r Group", 5)
    end
end