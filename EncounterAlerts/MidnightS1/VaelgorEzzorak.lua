local _, NSI = ... -- Internal namespace

local encID = 3178
-- /run NSAPI:DebugEncounter(3178)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    if (not self:DifficultyCheck(16)) then
        if not self.VaelgorPhaseFrame then
            self.VaelgorPhaseFrame = CreateFrame("Frame", nil, NSI.NSRTFrame, "BackdropTemplate")
            self.VaelgorPhaseFrame:SetScript("OnEvent", function(_, e, u)
                if e == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" and self.Phase and self.Phase == 1 and UnitExists("boss3") then
                    self.Phase = 2
                    self:StartReminders(self.Phase)
                end
            end)
        end
        self.VaelgorPhaseFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        if not NSRT.EncounterAlerts[encID] then
            NSRT.EncounterAlerts[encID] = {enabled = false}
        end
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
        for _, time in ipairs(timers[id] or {}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end
    end
    if NSRT.EncounterAlerts[encID].HealthDisplay then
        if not self.VaelgorEzzorakFrame then
            self.VaelgorEzzorakFrame = CreateFrame("Frame", nil, NSI.NSRTFrame, "BackdropTemplate")
            self.VaelgorEzzorakFrame:SetScript("OnEvent", function(_, e, u)
                if e == "UNIT_HEALTH" then
                    local text = ""
                    local name1 = UnitName("boss1") or ""
                    local name2 = UnitName("boss2") or ""
                    local health1 = name1 and C_StringUtil.RoundToNearestString(UnitHealthPercent("boss1", true, CurveConstants.ScaleTo100)) or ""
                    local health2 = name2 and C_StringUtil.RoundToNearestString(UnitHealthPercent("boss2", true, CurveConstants.ScaleTo100)) or ""
                    self:DisplaySecretText("%s %s\n%s %s", false, {health1, name1, health2, name2})
                end
            end)
        end
        local name1 = UnitName("boss1") or ""
        local name2 = UnitName("boss2") or ""
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
    if self.VaelgorPhaseFrame then
        self.VaelgorPhaseFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
end

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end -- Mythic only
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