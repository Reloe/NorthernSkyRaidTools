local _, NSI = ... -- Internal namespace

local encID = 3180
-- /run NSAPI:DebugEncounter(3180)
NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    id = id or self:DifficultyCheck(14) or 0
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Divine Toll", "Text", nil, 5, 1, encID)

        local timers = {
            [0] = {},
            [16] = {22, 40, 58, 76, 112, 130, 166, 184, 202, 220, 274, 292, 310, 328, 346, 364, 382},
        }
        for _, time in ipairs(timers[id] or {}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end

        if UnitGroupRolesAssigned("player") ~= "TANK" then return end
        -- same timer on all difficulties for now
        Alert.TTS = false
        Alert.dur = 8
        Alert.text = "Peace Aura"
        local timers = {
            [0] = {},
            [16] = {132, 291, 450},
        }
        for _, time in ipairs(timers[id] or {}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end

        Alert.text = "Devotion Aura"
        local timers = {
            [0] = {},
            [16] = {26, 184.7, 343.5},
        }
        for _, time in ipairs(timers[id] or {}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end

        Alert.text = "Aura of Wrath"
        local timers = {
            [0] = {},
            [16] = {78.5, 237.5, 396.5},
        }
        for _, time in ipairs(timers[id] or {}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end
    end
    if NSRT.EncounterAlerts[encID].HealAbsorbTicks then
        local timers = {
            [0] = {},
            [15] = {147.3, 324.4},
            [16] = {34.4, 142.6, 192.5, 302, 352, 461.5},
        }
        self.AlertTimers = self.AlertTimers or {}
        local dur = id == 16 and 20 or 15
        local Alert = self:CreateDefaultAlert("", "Bar", 1248721, dur, 1, encID) -- text, Type, spellID, dur, phase, encID, isAssignment
        Alert.TTS = false
        Alert.colors = {0, 1, 0, 1}
        Alert.Ticks = id == 16 and {5, 10, 15} or {5, 10}
        if self:IsUsingTLAlerts() then
            for _, time in ipairs(timers[id] or {}) do
                Alert.time = time+dur
                self:AddToReminder(Alert)
            end
        else
            for i, v in ipairs(timers[id] or {}) do
                self.AlertTimers[i] = C_Timer.NewTimer(v, function()
                    local F = self:DisplayReminder(Alert)
                    if F then
                        if id == 16 then
                            self:AddTickToBar(F, 0.25)
                            self:AddTickToBar(F, 0.5)
                            self:AddTickToBar(F, 0.75)
                        else
                            self:AddTickToBar(F, 0.333)
                            self:AddTickToBar(F, 0.666)
                        end
                    end
                end)
            end
        end
    end
    if NSRT.EncounterAlerts[encID].TauntAlerts and UnitGroupRolesAssigned("player") == "TANK" then
        self.TauntFrame = self.TauntFrame or CreateFrame("Frame", nil, NSI.NSRTFrame, "BackdropTemplate")
        self.TauntFrame:SetSize(100, 30)
        self.TauntFrame.Text = self.TauntFrame.Text or self.TauntFrame:CreateFontString(nil, "OVERLAY")
        self.TauntFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings["GlobalEncounterFontSize"] or 50, "OUTLINE")
        self.TauntFrame.Text:SetText("Taunt")
        self.TauntFrame.Text:SetPoint("CENTER")
        self.TauntFrame.Text:Hide()
        local Taunts = {
            [115546] = true,
            [56222] = true,
            [185245] = true,
            [2649] = true,
            [6795] = true,
            [355] = true,
            [62124] = true,
            [49576] = true,
        }
        local timers = {
            [0] = {},
            [15] = {29, 71, 113, 127, 151, 191, 243, 303, 323, 346, 33, 75, 115, 131, 155, 175, 195, 247, 307, 327, 350}, -- cast success timers from wcl
            [16] = {25, 29, 61, 65, 115, 119, 151, 155, 169, 173, 223, 227, 277, 281, 313, 317, 331, 335, 385, 389, 439, 443}, -- cast success timers from wcl}
        }
        local blacklist = {}
        self.TauntFrame:SetScript("OnEvent", function(_, e, u, _, spellID)
            if e == "UNIT_SPELLCAST_START" then
                if not u:find("^nameplate%d") then return end
                local plate = C_NamePlate.GetNamePlateForUnit(u)
                if not plate then return end
                if blacklist[u] then return end -- meaning this unit has already casted in this timespan
                blacklist[u] = true
                -- threat check
                local threatLevel = UnitThreatSituation("player", u)
                local isTanking = threatLevel and threatLevel >= 2
                if isTanking then return end -- only alert if the mob is not
                self.TauntFrame:ClearAllPoints()
                self.TauntFrame:SetPoint("TOP", plate, "BOTTOM", 0, 0)
                self.TauntFrame.Text:Show()
                NSAPI:TTS("Taunt")
                self.TauntTimersCancel = C_Timer.NewTimer(3, function()
                    self.TauntFrame.Text:Hide()
                    self.TauntTimersCancel = nil
                end)
                self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_START") -- unregister on first detection to help reduce false positives
            elseif e == "UNIT_SPELLCAST_SUCCEEDED" and Taunts[spellID] then
                if self.TauntTimersCancel then
                    self.TauntTimersCancel:Cancel()
                    self.TauntTimersCancel = nil
                end
                self.TauntFrame.Text:Hide()
            end
        end)
        self.TauntFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        for i, time in ipairs(timers[id] or {}) do
            time = time-3.5
            self.TauntTimers = self.TauntTimers or {}
            self.TauntTimers[i] = C_Timer.NewTimer(time, function()
                self.TauntFrame:RegisterEvent("UNIT_SPELLCAST_START")
                C_Timer.After(1, function()
                    self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_START")
                end)
                C_Timer.After(7, function()
                    blacklist = {}
                end)
            end)
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if self.TauntTimers then
        for i, timer in pairs(self.TauntTimers) do
            timer:Cancel()
            self.TauntTimers[i] = nil
        end
    end
    if self.TauntFrame then
        self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_START")
        self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self.TauntFrame.Text:Hide()
    end
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
    if not (self.Assignments and self.Assignments[encID] and self.Assignments[encID].Soaks) then return end
    if (not (id and id == 16)) and not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID, true) -- text, Type, spellID, dur, phase, encID
    local group = {}
    local healer = {}
    for unit in self:IterateGroupMembers() do
        local specID = NSI:GetSpecs(unit) or 0
        local prio = self.spectable[specID]
        local G = self.GUIDS and self.GUIDS[unit] or ""
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
                mygroup = math.min(4, mygroup)
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
    local pos = (mygroup == 1 and "Star") or (mygroup == 2 and "Orange") or (mygroup == 3 and "Purple") or (mygroup == 4 and "Green") or "Flex Spot"
    local text = (IsHealer and "Go to {rt"..mygroup.."}") or "Soak {rt"..mygroup.."}"
    local TTS = (IsHealer and "Go to "..pos) or "Soak "..pos
    Alert.TTS, Alert.TTSTimer, Alert.text = TTS, 10, text
    local phaselength = 162.7 -- guess based on Zealous Spirit in logs

    for phase = 0, 2 do
        Alert.time = 92 + (phase * phaselength)
        self:AddToReminder(Alert)
        if self:DifficultyCheck(16) then -- second cast is mythic only in case I want to support Heroic as well
            Alert.time = 149.2 + (phase * phaselength)
            self:AddToReminder(Alert)
        end
    end

    if NSRT.AssignmentSettings.OnPull then
        local text = mygroup == 1 and "|cFFFFFF00Star|r" or mygroup == 2 and "|cFFFFA500Orange|r" or mygroup == 3 and "|cFF9400D3Purple|r" or mygroup == 4 and "|cFF00FF00Green|r" or ""
        self:DisplayText("You are assigned to soak |cFF00FF00Execution Sentence|r in the "..text.." Group", 5)
    end
end