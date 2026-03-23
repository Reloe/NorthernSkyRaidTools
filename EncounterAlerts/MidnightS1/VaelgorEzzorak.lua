local _, NSI = ... -- Internal namespace

local encID = 3178
-- /run NSAPI:DebugEncounter(3178)
NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        -- local Alert = self:CreateDefaultAlert("Breath", "Bar", 1244221, 4, 1, encID)
        -- same timer on all difficultes for now, timers behaved a bit weirdly on beta
    end
    if NSRT.EncounterAlerts[encID].HealthDisplay then
        if not self.VaelgorEzzorakFrame then
            self.VaelgorEzzorakFrame = CreateFrame("Frame", nil, NSI.NSRTFrame, "BackdropTemplate")
            self.VaelgorEzzorakFrame:SetScript("OnEvent", function(_, e, u)
                if e == "UNIT_HEALTH" then
                    local text = ""
                    local name1 = UnitExists("boss1") and UnitName("boss1") or ""
                    local name2 = UnitExists("boss2") and UnitName("boss2") or ""
                    local health1 = name1 and C_StringUtil.RoundToNearestString(UnitHealthPercent("boss1", true, CurveConstants.ScaleTo100)) or ""
                    local health2 = name2 and C_StringUtil.RoundToNearestString(UnitHealthPercent("boss2", true, CurveConstants.ScaleTo100)) or ""
                    self:DisplaySecretText("%s %s\n%s %s", false, {health1, name1, health2, name2})
                end
            end)
        end
        local name1 = UnitExists("boss1") and UnitName("boss1") or ""
        local name2 = UnitExists("boss2") and UnitName("boss2") or ""
        self:DisplaySecretText("%s %s\n%s %s", false, {"100", name1, "100", name2})
        self.VaelgorEzzorakFrame:RegisterUnitEvent("UNIT_HEALTH", "boss1", "boss2")
        self.VaelgorEzzorakFrame:Show()
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if NSRT.EncounterAlerts[encID].HealthDisplay then
        if self.VaelgorEzzorakFrame then self.VaelgorEzzorakFrame:UnregisterEvent("UNIT_HEALTH") end
        self.VaelgorEzzorakFrame:Hide()
        self:DisplaySecretText(false, true)
    end
    if self.VaelgorPhaseTimer then
        self.VaelgorPhaseTimer:Cancel()
        self.VaelgorPhaseTimer = nil
    end
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if (not (id and id == 16)) and not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player") or 0
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
    -- Assigning Group 1&2 on first soak, Group 3&4 on second soak. This is overkill as only 7 people are required but not sure how the strat is gonna be yet
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

local detectedDurations = {
    [14] = {
        {time = 8, phase = function(num) return 2 end},
    },
    [15] = {
        {time = 8, phase = function(num) return 2 end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    local phaseinfo = detectedDurations[difficultyID] and detectedDurations[difficultyID][self.Phase]
    if phaseinfo and info.duration == phaseinfo.time then
        self.VaelgorPhaseTimer = nil
        self.VaelgorPhaseTimer = C_Timer.NewTimer(8, function()
            if not self.EncounterID then return end -- if wipe happened during these 8s
            local newphase = phaseinfo.phase(self.Phase)
            if newphase > self.Phase then
                self.Phase = newphase
                self:StartReminders(self.Phase)
                self.PhaseSwapTime = now
            end
        end)
    end
end