local _, NSI = ... -- Internal namespace

local encID = 3179
-- /run NSAPI:DebugEncounter(3179)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local enc = NSRT.EncounterAlerts[encID]

    local function Add(key, alert, timers, durOverrides)
        NSI:AddEncounterAlert(encID, key, alert, timers, durOverrides)
    end

    Add("Beams1", NSI:CreateDefaultAlert("Beams", "Text", nil, 8, 1, encID), {
        [0]  = {},
        [14] = {102.6, 224.2, 346},
        [15] = {102.6, 224.2, 346},
        [16] = {102.6, 224.2, 346},
    })

    Add("Orbs1", NSI:CreateDefaultAlert("Orbs", "Text", nil, 5, 1, encID), {
        [0]  = {},
        [14] = {14.1, 59.1, 135, 180.7, 256.5, 301.6},
        [15] = {14.1, 59.1, 135, 180.7, 256.5, 301.6},
        [16] = {18.1, 63.1, 141, 186.7, 262.5, 307.6},
    })

    Add("CC Adds1", NSI:CreateDefaultAlert("CC Adds", "CC Adds", nil, 5, 1, encID), {
        [0]  = {},
        [14] = {20, 65, 141, 187, 263, 308},
        [15] = {20, 65, 141, 187, 263, 308},
        [16] = {27.6, 73, 150.8, 196.9, 272.4, 317.5},
    })

    -- CCAddsDisplay: nameplate CC indicator — special feature, off by default
    local ccDisplay = NSI:CreateDefaultAlert("CC Display", "Text", nil, 0, 1, encID)
    if not enc["CCAddsDisplay1"] then
        enc["CCAddsDisplay1"] = { alert = ccDisplay, timers = {}, reloeCreated = true, enabled = false }
    end
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)

    if NSRT.EncounterAlerts[encID]
    and NSRT.EncounterAlerts[encID]["CCAddsDisplay1"]
    and NSRT.EncounterAlerts[encID]["CCAddsDisplay1"].enabled
    and id == 16 then
        self.platetexts = self.platetexts or {}
        local plateref = {}
        local function DisplayNameplateText(u)
            local plate = C_NamePlate.GetNamePlateForUnit(u)
            if plate then
                local interruptible = select(8, UnitCastingInfo(u))
                for i=1, #self.platetexts+1 do
                    if self.platetexts[i] and not self.platetexts[i]:IsShown() then
                        self.platetexts[i]:SetText("CC")
                        self.platetexts[i].bgTexture:SetColorTexture(0, 1, 0, 0.8)
                        self.platetexts[i]:ClearAllPoints()
                        self.platetexts[i]:SetPoint("BOTTOM", plate, "TOP", 0, 0)
                        self.platetexts[i]:Show()
                        self.platetexts[i].bgFrame:Show()
                        self.platetexts[i].unit = u
                        plateref[u] = i
                        if issecretvalue(interruptible) then
                            self.platetexts[i]:SetAlphaFromBoolean(interruptible, 0, 1)
                            self.platetexts[i].bgFrame:SetAlphaFromBoolean(interruptible, 0, 1)
                        end
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
                        self.platetexts[i].bgTexture:SetColorTexture(0, 1, 0, 0.8)
                        self.platetexts[i].bgTexture:SetAllPoints(self.platetexts[i].bgFrame)
                        self.platetexts[i].bgFrame:SetSize(25, 25)
                        self.platetexts[i].bgFrame:SetPoint("CENTER", self.platetexts[i], "CENTER", 0, 0)
                        self.platetexts[i]:SetText("CC")
                        self.platetexts[i]:Show()
                        self.platetexts[i].bgFrame:Show()
                        self.platetexts[i].unit = u
                        plateref[u] = i
                        if issecretvalue(interruptible) then
                            self.platetexts[i]:SetAlphaFromBoolean(interruptible, 0, 1)
                            self.platetexts[i].bgFrame:SetAlphaFromBoolean(interruptible, 0, 1)
                        end
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
                for i, v in ipairs(self.platetexts) do
                    if v.unit == u then
                        v:Hide()
                        v.bgFrame:Hide()
                        v.unit = nil
                    end
                end
                return
            elseif e == "NAME_PLATE_UNIT_ADDED" or e == "UNIT_AURA" or e == "UNIT_SPELLCAST_START" then
                if (e == "UNIT_AURA" or e == "UNIT_SPELLCAST_START") and not u:find("^nameplate%d") then return end
                if UnitLevel(u) ~= -1 then
                    local aura1 = C_UnitAuras.GetAuraDataByIndex(u, 1, "HELPFUL")
                    if aura1 then
                        if plateref[u] then
                            if self.platetexts[plateref[u]] then
                                self.platetexts[plateref[u]]:Hide()
                                self.platetexts[plateref[u]].bgFrame:Hide()
                                self.platetexts[plateref[u]].unit = nil
                                plateref[u] = nil
                            end
                        end
                        DisplayNameplateText(u)
                    end
                end
            end
        end

        if not self.plateframe then
            self.plateframe = CreateFrame("Frame")
            self.plateframe:SetScript("OnEvent", function(_, e, u)
                UpdateNameplateTexts(e, u)
            end)
        end
        self.plateframe:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self.plateframe:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        self.plateframe:RegisterEvent("UNIT_AURA")
        self.plateframe:RegisterEvent("UNIT_SPELLCAST_START")
        self.plateframe:Show()
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    local ccEntry = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID]["CCAddsDisplay1"]
    if ccEntry and ccEntry.enabled then
        if self.plateframe then
            for i, v in ipairs(self.platetexts) do
                v:Hide()
                v.bgFrame:Hide()
            end
            self.plateframe:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
            self.plateframe:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
            self.plateframe:UnregisterEvent("UNIT_AURA")
            self.plateframe:UnregisterEvent("UNIT_SPELLCAST_START")
            self.plateframe:Hide()
        end
    end
end
