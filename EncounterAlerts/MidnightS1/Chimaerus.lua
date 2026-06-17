local _, NSI = ... -- Internal namespace

local encID = 3306
-- /run NSAPI:DebugEncounter(3306)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local loadConditions = self:DefaultLoadConditions()
    loadConditions.Roles.DAMAGER = true
    loadConditions.Roles.HEALER = true
    local data = {internalID = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = nil,
    isConditional = {
            text = "This Alert only shows if you are downstairs at the time",
            func = [[return function()
                for j = 1, 40 do
                    local u = "nameplate" .. j
                    if UnitExists(u) and UnitLevel(u) == 92 then
                        return true
                    end
                end
                return false
            end]],
        },
    loadConditions = loadConditions,
    timers = {
            [16] = {{39, 112}, {39, 112}},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if self.AlertTimers then
        for i, v in ipairs(self.AlertTimers) do
            if v and v.Cancel then v:Cancel() end
        end
        self.AlertTimers = nil
    end
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    local diff = id or self:DifficultyCheck({14, 15, 16})
    if not diff then return end
    if diff == 16 and self.Assignments[encID].Soaks then
        local subgroup = self:GetSubGroup("player")
        local Alert = self:CreateDefaultAlert("", "text", nil, nil, 1, encID)
        Alert.dur, Alert.TTSTimer = 10, 5
        for phase = 1, 3 do
            Alert.phase = phase
            Alert.time, Alert.text  = 18.7, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = subgroup <= 2 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
            Alert.time, Alert.text = 91.4, subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = subgroup >= 3 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
            Alert.time, Alert.text = 155.2, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = subgroup <= 2 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
        end
        if NSRT.AssignmentSettings.OnPull then
            local group = subgroup <= 2 and "First" or "Second"
            self:DisplayText("You are assigned to soak |cFF00FF00Alndust Upheaval|r in the |cFF00FF00" .. group .. "|r Group", 5)
        end
    elseif self.Assignments[encID].SplitSoaks and diff ~= 16 then
        if UnitGroupRolesAssigned("player") == "TANK" then return end
        local _, first = self:GetSortedGroup(true, false, false)
        local Alert = self:CreateDefaultAlert("", "text", nil, nil, 1, encID)
        local group = 2
        for i, v in ipairs(first) do
            if UnitIsUnit(v.unitid, "player") then group = 1; break end
        end
        Alert.dur, Alert.TTSTimer = 10, 5
        for phase = 1, 3 do
            Alert.phase = phase
            Alert.time, Alert.text  = 18.7, group <= 1 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = group <= 1 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
            Alert.time, Alert.text = 91.4, group >= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = group >= 2 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
        end
        if NSRT.AssignmentSettings.OnPull then
            local group = group <= 1 and "First" or "Second"
            self:DisplayText("You are assigned to soak |cFF00FF00Alndust Upheaval|r in the |cFF00FF00" .. group .. "|r Group", 5)
        end
    end
end

local detectedDurations = {
    [14] = { { time = 164.5, phase = function(num) return num + 1 end } },
    [15] = { { time = 151.36, phase = function(num) return num + 1 end } },
    [16] = { { time = 120, phase = function(num) return num + 1 end } },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = self:DifficultyCheck({14, 15, 16})
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][1]
    if phaseinfo and info.duration >= phaseinfo.time then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
        end
    end
end
