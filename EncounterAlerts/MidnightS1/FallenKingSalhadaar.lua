local _, NSI = ... -- Internal namespace

local encID = 3179
-- /run NSAPI:DebugEncounter(3179)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Beams", "Text", nil, 8, 1, encID)


        -- using same timers for all difficulties atm
        local id = self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [14] = {102.6, 224.2, 346, 467.7},
            [15] = {102.6, 224.2, 346, 467.7},
            [16] = {102.6, 224.2, 346, 467.7},
        }
        for i, v in ipairs(timers[id]) do -- Entropic Unraveling
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS, Alert.dur = "Adds", "Adds ", 5
        timers = {
            [0] = {},
            [14] = {17.1, 62.1, 140, 185.7, 261.5, 306.6, 384.1, 429.5, 505},
            [15] = {17.1, 62.1, 140, 185.7, 261.5, 306.6, 384.1, 429.5, 505},
            [16] = {17.1, 62.1, 140, 185.7, 261.5, 306.6, 384.1, 429.5, 505},
        }
        for i, v in ipairs(timers[id]) do -- Void Convergence (Adds)
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS = "CC Adds", "CC Adds"
        timers = {
            [0] = {},
            [14] = {26.6, 72, 149.8, 195.9, 271.4, 316.5, 393.2, 439},
            [15] = {26.6, 72, 149.8, 195.9, 271.4, 316.5, 393.2, 439},
            [16] = {26.6, 72, 149.8, 195.9, 271.4, 316.5, 393.2, 439},
        }
        for i, v in ipairs(timers[id]) do -- Fractured Projection (CC Adds)
            Alert.time = v
            self:AddToReminder(Alert)
        end


        if id ~= 16 then return end -- Shield Mechanic is mythic only
        self.platetexts = self.platetexts or {}
        local plateref = {}
        local function DisplayNameplateText(aura1, aura2, u)
            local plate = C_NamePlate.GetNamePlateForUnit(u)
            if plate then
                for i=1, #self.platetexts+1 do
                    if self.platetexts[i] and not self.platetexts[i]:IsShown() then
                        if aura2 then
                            self.platetexts[i]:SetText("WAIT")
                            self.platetexts[i].bgTexture:SetColorTexture(1, 0, 0, 0.8)
                        else
                            self.platetexts[i]:SetText("CC")
                            self.platetexts[i].bgTexture:SetColorTexture(0, 1, 0, 0.8)
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
                        self.platetexts[i]:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), 18, "OUTLINE")
                        self.platetexts[i]:SetPoint("BOTTOM", plate, "TOP", 0, 0)
                        self.platetexts[i]:SetShadowColor(0, 0, 0, 1)
                        self.platetexts[i]:SetTextColor(1, 1, 1, 1)

                        self.platetexts[i].bgFrame = CreateFrame("Frame", nil, self.plateframe)
                        self.platetexts[i].bgFrame:SetFrameStrata("BACKGROUND")
                        self.platetexts[i].bgTexture = self.platetexts[i].bgFrame:CreateTexture(nil, "BACKGROUND")
                        self.platetexts[i].bgTexture:SetColorTexture(1, 1, 1, 0.8)
                        self.platetexts[i].bgTexture:SetAllPoints(self.platetexts[i].bgFrame)
                        self.platetexts[i].bgFrame:SetSize(25, 25)
                        self.platetexts[i].bgFrame:SetPoint("CENTER", self.platetexts[i], "CENTER", 0, 0)

                        if aura2 then
                            self.platetexts[i]:SetText("WAIT")
                            self.platetexts[i].bgTexture:SetColorTexture(1, 0, 0, 0.8)
                        else
                            self.platetexts[i]:SetText("CC")
                            self.platetexts[i].bgTexture:SetColorTexture(0, 1, 0, 0.8)
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
                if UnitLevel(u) ~= -1 then
                    local aura1 = C_UnitAuras.GetAuraDataByIndex(u, 1, "HELPFUL")
                    if aura1 then
                        local aura2 = C_UnitAuras.GetAuraDataByIndex(u, 2, "HELPFUL")
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