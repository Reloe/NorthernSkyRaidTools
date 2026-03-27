local _, NSI = ... -- Internal namespace

local encID = 3306
-- /run NSAPI:DebugEncounter(3306)

local function RiftMadnessTimers(id)
    local diff = id or select(3, GetInstanceInfo()) or 0
    if diff == 16 and NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        if UnitGroupRolesAssigned("player") == "TANK" then return end
        local dur = 6
        local Alert = NSI:CreateDefaultAlert("Debuffs", "Text", nil, dur, 1, encID) -- Group Soaks
        Alert.TTS = false
        local timers = {39, 112}
        if NSI.AlertTimers then
            for i, v in ipairs(NSI.AlertTimers) do
                if v and v.Cancel then
                    v:Cancel()
                end
            end
            NSI.AlertTimers = {}
        end
        NSI.AlertTimers = {}
        for i, v in ipairs(timers or {}) do
            NSI.AlertTimers[i] = C_Timer.NewTimer(v-dur, function()
                for i=1, 40 do
                    local u = "nameplate"..i
                    if UnitExists(u) and UnitLevel(u) == 92 then
                        NSI:DisplayReminder(Alert)
                        break
                    end
                end
            end)
        end
        if NSI:IsUsingTLAlerts() then
            Alert.isConditional = true
            for i=1, 2 do
                Alert.phase = i
                for _, time in ipairs(timers or {}) do
                    Alert.time = time
                    NSI:AddToReminder(Alert)
                end
            end
        end
    end
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then
        RiftMadnessTimers(id)
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if self.AlertTimers then
        for i, v in ipairs(self.AlertTimers) do
            if v and v.Cancel then
                v:Cancel()
            end
        end
        self.AlertTimers = nil
    end
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    local diff = id or select(3, GetInstanceInfo())
    if diff < 14 or diff > 16 then return end
    if diff == 16 and self.Assignments[encID].Soaks then -- For Mythic we use group 1/2 + 3/4
        local subgroup = self:GetSubGroup("player")
        local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
        Alert.dur, Alert.TTSTimer = 10, 5
        for phase = 1, 3 do
            Alert.phase = phase
            Alert.time, Alert.text  = 18.7, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = subgroup <= 2 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
            Alert.time, Alert.text = 91.4, subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = subgroup >= 3 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
            Alert.time, Alert.text = 158.7, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = subgroup <= 2 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
        end
        if NSRT.AssignmentSettings.OnPull then
            local group = subgroup <= 2 and "First" or "Second"
            self:DisplayText("You are assigned to soak |cFF00FF00Alndust Upheaval|r in the |cFF00FF00"..group.."|r Group", 5)
        end
    elseif self.Assignments[encID].SplitSoaks and diff ~= 16 then -- For Normal & Heroic we auto split the group to speed up splits
        if UnitGroupRolesAssigned("player") == "TANK" then return end -- just end early for tanks
        local _, first = self:GetSortedGroup(true, false, false)
        local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID, true) -- text, Type, spellID, dur, phase, encID
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
            Alert.TTS = group <= 1 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
            Alert.time, Alert.text = 91.4, group >= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
            Alert.TTS = group >= 2 and "Soak" or "Don't soak"
            self:AddToReminder(Alert)
        end
        if NSRT.AssignmentSettings.OnPull then
            local group = group <= 1 and "First" or "Second"
            self:DisplayText("You are assigned to soak |cFF00FF00Alndust Upheaval|r in the |cFF00FF00"..group.."|r Group", 5)
        end
    end
end

local detectedDurations = {
    [14] = {
        {time = 164.5, phase = function(num) return num+1 end},
    },
    [15] = {
        {time = 151.36, phase = function(num) return num+1 end},
    },
    [16] = {
        {time = 120, phase = function(num) return num+1 end}, -- dunno about mythic timer yet but this should work for now
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][1]
    if phaseinfo and info.duration >= phaseinfo.time then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            RiftMadnessTimers()
        end
    end
end