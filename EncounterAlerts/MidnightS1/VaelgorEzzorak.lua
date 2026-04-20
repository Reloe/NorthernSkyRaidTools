local _, NSI = ... -- Internal namespace

local encID = 3178
-- /run NSAPI:DebugEncounter(3178)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local enc = NSRT.EncounterAlerts[encID]

    local function Add(key, alert, timers, durOverrides)
        NSI:AddEncounterAlert(encID, key, alert, timers, durOverrides, true, true)
    end

    Add("Spread1", NSI:CreateDefaultAlert("Spread", "Text", nil, 5, 1, encID), {
        [0]  = {},
        [16] = {37.7, 77.7, 170.5, 205.5, 245.5, 285.5, 307.1, 373.2, 418.2, 450.2},
    })

    Add("Tether1", NSI:CreateDefaultAlert("Tether", "Text", nil, 5, 1, encID), {
        [0]  = {},
        [16] = {39.8, 89.8, 149.4, 187.5, 237.5, 287.5, 441.7},
    })

    Add("Breath1", NSI:CreateDefaultAlert("Breath", "Text", nil, 5, 1, encID), {
        [0]  = {},
        [16] = {5.3, 70.3, 133.8, 145.9, 191, 248, 316.6, 360.7, 420.7},
    })

    -- HealthDisplay: boss HP overlay — special feature, off by default
    local healthDisplay = NSI:CreateDefaultAlert("Health Display", "Text", nil, 0, 1, encID)
    if not enc["HealthDisplay1"] then
        enc["HealthDisplay1"] = { alert = healthDisplay, timers = {}, reloeCreated = true, enabled = false }
    end
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    local id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)

    if NSRT.EncounterAlerts[encID]
    and NSRT.EncounterAlerts[encID]["HealthDisplay1"]
    and NSRT.EncounterAlerts[encID]["HealthDisplay1"].enabled then
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
    local hdEntry = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID]["HealthDisplay1"]
    if hdEntry and hdEntry.enabled then
        if self.VaelgorEzzorakFrame then
            self.VaelgorEzzorakFrame:UnregisterEvent("UNIT_HEALTH")
            self.VaelgorEzzorakFrame:Hide()
        end
        self:DisplaySecretText(false, true)
    end
    if self.VaelgorPhaseTimer then
        self.VaelgorPhaseTimer:Cancel()
        self.VaelgorPhaseTimer = nil
    end
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID] and self.Assignments[encID].Soaks) then return end
    if (not (id and id == 16)) and not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    if not subgroup then return end
    local Soak = self:CreateDefaultAlert("", "Text", nil, 8, 1, encID)
    local timers = {14.2, 114.2, 262, 359.6, 479.2}
    for i, v in ipairs(timers) do
        Soak.time = v
        Soak.text = subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
        Soak.TTS = subgroup <= 2 and "Soak" or "Don't soak"
        self:AddToReminder(Soak)
    end
    timers = {64.2, 213, 314.6, 409.7}
    for i, v in ipairs(timers) do
        Soak.time = v
        Soak.text = subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
        Soak.TTS = subgroup >= 3 and "Soak" or "Don't soak"
        self:AddToReminder(Soak)
    end

    if NSRT.AssignmentSettings.OnPull then
        local group = (subgroup <= 2 and "First") or (subgroup >= 3 and "Second")
        self:DisplayText("You are assigned to soak |cFF00FF00Gloom|r in the |cFF00FF00"..group.."|r Group", 5)
    end
end

local detectedDurations = {
    [14] = { {time = 8, phase = function(num) return 2 end} },
    [15] = { {time = 8, phase = function(num) return 2 end} },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    local phaseinfo = detectedDurations[difficultyID] and detectedDurations[difficultyID][self.Phase]
    if phaseinfo and info.duration == phaseinfo.time then
        self.VaelgorPhaseTimer = nil
        self.VaelgorPhaseTimer = C_Timer.NewTimer(8, function()
            if not self.EncounterID then return end
            local newphase = phaseinfo.phase(self.Phase)
            if newphase > self.Phase then
                self.Phase = newphase
                self:StartReminders(self.Phase)
                self.PhaseSwapTime = now
            end
        end)
    end
end
