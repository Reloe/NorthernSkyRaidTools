local _, NSI = ... -- Internal namespace

local encID = 3179
-- /run NSAPI:DebugEncounter(3179)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID

        local Alert = self:CreateDefaultAlert("Beams", "Text", nil, 8, 1, encID)
        for i, v in ipairs(self:DifficultyCheck(14) and {102.6, 224.6} or {}) do -- Cosmic Unraveling
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS, Alert.dur = "Adds", "Adds ", 5
        for i, v in ipairs(self:DifficultyCheck(14) and {13.4, 58.6, 135.6, 180.7, 257.4} or {}) do -- Desperate Measures
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS = "CC Adds", "CC Adds"
        for i, v in ipairs(self:DifficultyCheck(14) and {26.7, 71.8, 148.7, 193.8} or {}) do -- Fractured Projection (CC Adds)
            Alert.time = v
            self:AddToReminder(Alert)
        end


        if not self:DifficultyCheck(16) then return end -- Shield Mechanic is mythic only
        self.platetexts = self.platetexts or {}
        local plateref = {}
        local function DisplayNameplateText(aura1, aura2, u)
            local plate = C_NamePlate.GetNamePlateForUnit(u)
            if plate then
                for i=1, #self.platetexts+1 do
                    if self.platetexts[i] and not self.platetexts[i]:IsShown() then
                        if aura2 then
                            self.platetexts[i]:SetTextColor(1, 0, 0, 1)
                            self.platetexts[i]:SetText(aura1.applications)
                        else

                            self.platetexts[i]:SetTextColor(0, 1, 0, 1)
                            self.platetexts[i]:SetText("CC")
                        end
                        self.platetexts[i]:ClearAllPoints()
                        self.platetexts[i]:SetPoint("BOTTOM", plate, "TOP", 0, 0)
                        
                        self.platetexts[i]:Show()
                        self.platetexts[i].bgFrame:Show()
                        self.platetexts[i].unit = u
                        plateref[u] = i
                        return
                    elseif not self.platetexts[i] then

                        self.platetexts[i] = self.plateframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        self.platetexts[i]:SetFont(self.LSM:Fetch("font", "Expressway"), 18, "OUTLINE")
                        self.platetexts[i]:SetPoint("BOTTOM", plate, "TOP", 0, 0)
                        self.platetexts[i]:SetShadowColor(0, 0, 0, 1)

                        self.platetexts[i].bgFrame = CreateFrame("Frame", nil, self.plateframe)
                        self.platetexts[i].bgFrame:SetFrameStrata("BACKGROUND")
                        self.platetexts[i].bgTexture = self.platetexts[i].bgFrame:CreateTexture(nil, "BACKGROUND")
                        self.platetexts[i].bgTexture:SetColorTexture(1, 1, 1, 0.8)
                        self.platetexts[i].bgTexture:SetAllPoints(self.platetexts[i].bgFrame)
                        self.platetexts[i].bgFrame:SetSize(25, 25)
                        self.platetexts[i].bgFrame:SetPoint("CENTER", self.platetexts[i], "CENTER", 0, 0)
                        
                        if aura2 then
                            self.platetexts[i]:SetTextColor(1, 0, 0, 1)
                            self.platetexts[i]:SetText(aura1.applications)
                        else
                            self.platetexts[i]:SetTextColor(0, 1, 0, 1)
                            self.platetexts[i]:SetText("CC")
                        end
                        
                        self.platetexts[i]:Show()
                        self.platetexts[i].bgFrame:Show()
                        self.platetexts[i].unit = u
                        plateref[u] = i
                        return
                    end
                end
            end
        end
        local function UpdateNameplateTexts(e, u)
            if e == "NAME_PLATE_UNIT_REMOVED" then
                if plateref[u] then
                    if self.platetexts[plateref[u]] then
                        self.platetexts[plateref[u]]:Hide()
                        self.platetexts[plateref[u]].bgFrame:Hide()
                        self.platetexts[plateref[u]].unit = nil
                        plateref[u] = nil
                        return
                    end
                end
                -- fallback if plateref somehow doesn't exist
                for i, v in ipairs(self.platetexts) do
                    if v.unit == u then
                        v:Hide()
                        v.bgFrame:Hide()
                        v.unit = nil
                    end
                end
                return
            elseif e == "NAME_PLATE_UNIT_ADDED" or e == "UNIT_AURA" then
                local found = e == "NAME_PLATE_UNIT_ADDED"
                for i=1, 40 do
                    if found then break end
                    local unit = "nameplate"..i
                    if unit == u then found = true break end
                end
                if not found then return end -- only allow nameplate units for UNIT_AURA
                local class = UnitClassification(u)
                if class and class ~= "" and UnitLevel(u) ~= -1 then
                    local aura1 = C_UnitAuras.GetAuraDataByIndex(u, 1, "HELPFUL")
                    local aura2 = C_UnitAuras.GetAuraDataByIndex(u, 2, "HELPFUL")
                    if aura1 then
                        if plateref[u] then
                            if self.platetexts[plateref[u]] then
                                self.platetexts[plateref[u]]:Hide()
                                self.platetexts[plateref[u]].bgFrame:Hide()
                                self.platetexts[plateref[u]].unit = nil
                                plateref[u] = nil
                            end
                        end
                        DisplayNameplateText(aura1, aura2, u)
                    end
                end
            end
        end
        
        if not self.plateframe then
            self.plateframe = CreateFrame("Frame")
            self.plateframe:SetScript("OnEvent", function(_, e, u)
                if e == "NAME_PLATE_UNIT_ADDED" then
                    UpdateNameplateTexts(e, u)
                elseif e == "NAME_PLATE_UNIT_REMOVED" then
                    UpdateNameplateTexts(e, u)
                elseif e == "UNIT_AURA" then
                    UpdateNameplateTexts(e, u)
                end
            end)
        end
        self.plateframe:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self.plateframe:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        self.plateframe:RegisterEvent("UNIT_AURA")
        self.plateframe:Show()
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
end

local phasedetections = {0, 0, 0, 0, 0, 0, 0}

NSI.DetectPhaseChange[encID] = function(self, e) -- on ENCOUNTER_TIMELINE_EVENT_ADDED/REMOVED
    local now = GetTime()
    local needed = self.Timelines and self.PhaseSwapTime and (now > self.PhaseSwapTime+5) and self.EncounterID and self.Phase and phasedetections[self.Phase]
    if needed and needed > 0 then
        table.insert(self.Timelines, now+0.2)
        local count = 0
        for i, v in ipairs(self.Timelines) do
            if v > now then
                count = count+1
                if count >= needed then
                    self.Phase = self.Phase+1                  
                    self:StartReminders(self.Phase)
                    self.Timelines = {}
                    self.PhaseSwapTime = now
                    break
                end
            end           
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END   
    if NSRT.EncounterAlerts[encID].enabled then
        if self.plateframe then            
            for i, v in ipairs(self.platetexts) do
                v:Hide()
                v.bgFrame:Hide()
            end
            self.plateframe:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
            self.plateframe:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
            self.plateframe:UnregisterEvent("UNIT_AURA")
            self.plateframe:Hide()
        end
    end
end




