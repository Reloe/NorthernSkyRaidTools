local _, NSI = ... -- Internal namespace

local encID = 3180
-- /run NSAPI:DebugEncounter(3180)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local data = {internalID = "Sacred Toll", text = "Sacred Toll", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = nil,
    overrides = {},
    timers = {
            [16] = {22, 40, 58, 76, 112, 130, 166, 184, 202, 220, 274, 292, 310, 328, 346, 364, 382},
        },
    }
    self:AddEncounterAlert(data)

    local data = {internalID = "Heal Absorb Ticks", text = "", DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 20, spellID = 1248721,
    overrides = {barColors = {0,1,0,1}, Ticks = {5, 10, 15}},
    timers = {
            [16] = {54.4, 162.6, 212.5, 322, 372, 481.5},
        },
    }
    self:AddEncounterAlert(data)

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true
    local data = {group = "Auras", internalID = "Peace Aura", text = "Peace Aura", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = nil,
    overrides = {loadConditions = tankConditions},
    timers = {
            [16] = {132, 291, 450},
        },
    }
    self:AddEncounterAlert(data)
    data.internalID, data.text = "Devotion Aura", "Devotion Aura"
    data.timers = {
        [16] = {26, 184.7, 343.5},
    }
    self:AddEncounterAlert(data)
    data.internalID, data.text = "Aura of Wrath", "Aura of Wrath"
    data.timers = {
        [16] = {78.5, 237.5, 396.5},
    }
    self:AddEncounterAlert(data)

    local data = {internalID = "TauntAlerts", text = "Taunt", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 3, spellID = nil, id = 0, customIcon = 355,
    overrides = {isSpecialDisplay = true, loadConditions = tankConditions, Font = "Expressway", FontSize = 50, Anchor = "TOP", relativeTo = "BOTTOM", xOffset = 0, yOffset = 0, BlockCopy = true},
    Preview = [[return function()
        print("|cFF00FFFFNSRT:|r no preview available for this Alert. It is anchored to the enemy nameplate")
    end]],
    timers = {
            [15] = {29, 71, 113, 127, 151, 191, 243, 303, 323, 346, 33, 75, 115, 131, 155, 175, 195, 247, 307, 327, 350},
            [16] = {61, 65, 115, 119, 151, 155, 169, 173, 223, 227, 277, 281, 313, 317, 331, 335, 385, 389, 439, 443},
    },
    extraOptions = {
        { Type = "Dropdown", label = "Font",
            get = [[return function(NSI) return NSRT.EncounterAlerts[3180][16].TauntAlerts.Font or "Expressway" end]],
            set = [[return function(NSI, v) for i=15, 16 do NSRT.EncounterAlerts[3180][i].TauntAlerts.Font = v end end]],
            values = [[ return function(NSI)
                local t = {}
                for _, name in ipairs(NSI.LSM:List("font")) do
                    t[#t + 1] = { label = name, value = name }
                end
                return t
            end ]]},
        { Type = "Slider", label = "FontSize", min = 10, max = 100,
            get = [[return function(NSI) return NSRT.EncounterAlerts[3180][16].TauntAlerts.FontSize or 50 end]],
            set = [[return function(NSI, v) for i=15, 16 do NSRT.EncounterAlerts[3180][i].TauntAlerts.FontSize = v end end]] },
        { Type = "Dropdown", label = "Anchor",
            get = [[return function(NSI) return NSRT.EncounterAlerts[3180][16].TauntAlerts.Anchor or "TOP" end]],
            set = [[return function(NSI, v) for i=15, 16 do NSRT.EncounterAlerts[3180][i].TauntAlerts.Anchor = v end end]],
            values = [[ return function(NSI)
                local anchors = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
                local t = {}
                for _, a in ipairs(anchors) do t[#t + 1] = { label = a, value = a } end
                return t
            end ]]},
        { Type = "Dropdown", label = "relativeTo",
            get = [[return function(NSI) return NSRT.EncounterAlerts[3180][16].TauntAlerts.relativeTo or "BOTTOM" end]],
            set = [[return function(NSI, v) for i=15, 16 do NSRT.EncounterAlerts[3180][i].TauntAlerts.relativeTo = v end end]],
            values = [[ return function(NSI)
                local anchors = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
                local t = {}
                for _, a in ipairs(anchors) do t[#t + 1] = { label = a, value = a } end
                return t
            end ]]},
        { Type = "Slider", label = "xOffset", min = -100, max = 100,
            get = [[return function(NSI) return NSRT.EncounterAlerts[3180][16].TauntAlerts.xOffset or 0 end]],
            set = [[return function(NSI, v) for i=15, 16 do NSRT.EncounterAlerts[3180][i].TauntAlerts.xOffset = v end end]] },
        { Type = "Slider", label = "yOffset", min = -100, max = 100,
            get = [[return function(NSI) return NSRT.EncounterAlerts[3180][16].TauntAlerts.yOffset or 0 end]],
            set = [[return function(NSI, v) for i=15, 16 do NSRT.EncounterAlerts[3180][i].TauntAlerts.yOffset = v end end]] },
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id)
    id = id or self:DifficultyCheck(14) or 0
    local info = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].TauntAlerts
    if info and info.enabled and self:EvaluateLoad(info) then
        if not self.TauntFrame then
            self.TauntFrame = CreateFrame("Frame", nil, NSI.NSRTFrame, "BackdropTemplate")
            self.TauntFrame:SetSize(100, 30)
            self.TauntFrame.Text = self.TauntFrame.Text or self.TauntFrame:CreateFontString(nil, "OVERLAY")
            self.TauntFrame.Text:SetFont(self.LSM:Fetch("font", info.Font), info.FontSize, "OUTLINE")
            self.TauntFrame.Text:SetText(info.text)
            self.TauntFrame.Text:SetPoint("CENTER")
            self.TauntFrame.Text:Hide()
        end
        local Taunts = {
            [115546] = true, [56222] = true, [185245] = true, [2649] = true,
            [6795]   = true, [355]   = true, [62124]  = true, [49576] = true,
        }
        local blacklist = {}
        self:EncounterRegister("UNIT_SPELLCAST_SUCCEEDED", true, "player")
        self.EncounterFrame:SetScript("OnEvent", function(_, e, u, _, spellID)
            if e == "UNIT_SPELLCAST_START" then
                if not u:find("^nameplate%d") then return end
                if not UnitIsEnemy("player", u) then return end
                local plate = C_NamePlate.GetNamePlateForUnit(u)
                if not plate then return end
                if blacklist[u] then return end
                blacklist[u] = true
                local threatLevel = UnitThreatSituation("player", u)
                local isTanking = threatLevel and threatLevel >= 2
                if isTanking then return end
                self.TauntFrame:ClearAllPoints()
                self.TauntFrame:SetPoint(info.Anchor, plate, info.relativeTo, info.xOffset, info.yOffset)
                self.TauntFrame.Text:Show()
                NSAPI:TTS(info.text)
                self.TauntTimersCancel = C_Timer.NewTimer(3, function()
                    self.TauntFrame.Text:Hide()
                    self.TauntTimersCancel = nil
                end)
                self:EncounterRegister("UNIT_SPELLCAST_START", false)
            elseif e == "UNIT_SPELLCAST_SUCCEEDED" and Taunts[spellID] then
                if self.TauntTimersCancel then
                    self.TauntTimersCancel:Cancel()
                    self.TauntTimersCancel = nil
                end
            end
        end)
        self.TauntTimers = self.TauntTimers or {}
        for i, time in ipairs(info.timers) do
            self.TauntTimers[#self.TauntTimers+1] = C_Timer.NewTimer(time-3.2, function()
                self:EncounterRegister("UNIT_SPELLCAST_START", true)
                C_Timer.After(0.4, function()
                    self:EncounterRegister("UNIT_SPELLCAST_START", false)
                end)
                C_Timer.After(7, function() blacklist = {} end)
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
        self.TauntFrame:Hide()
    end
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID] and self.Assignments[encID].Soaks) then return end
    if (not (id and id == 16)) and not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", "text", nil, 8, 1, encID) -- text, Type, spellID, dur, phase, encID
    local group = {}
    local healer = {}
    for unit in self:IterateGroupMembers() do
        local specID = NSI:GetSpecs(unit) or 0
        local prio = self.spectable[specID]
        local G = self.GUIDS and self.GUIDS[unit] or ""
        if UnitGroupRolesAssigned(unit) == "HEALER" then
            table.insert(healer, { unit = unit, prio = prio, GUID = G })
        else
            table.insert(group, { unit = unit, prio = prio, GUID = G })
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
                mygroup = math.ceil(i / 4)
                mygroup = math.min(4, mygroup)
                break
            end
        end
    end
    if not mygroup then return end
    local pos = (mygroup == 1 and "Star") or (mygroup == 2 and "Orange") or (mygroup == 3 and "Purple") or (mygroup == 4 and "Green") or "Flex Spot"
    local text = (IsHealer and "Go to {rt" .. mygroup .. "}") or "Soak {rt" .. mygroup .. "}"
    local TTS = (IsHealer and "Go to " .. pos) or "Soak " .. pos
    Alert.TTS, Alert.text = TTS, text

    local timers = { 90.5, 145.9, 249.4, 305.4 }
    self:AddRemindersFromTable(Alert, timers)

    if NSRT.AssignmentSettings.OnPull then
        local text = mygroup == 1 and "|cFFFFFF00Star|r" or mygroup == 2 and "|cFFFFA500Orange|r" or mygroup == 3 and "|cFF9400D3Purple|r" or mygroup == 4 and "|cFF00FF00Green|r" or ""
        self:DisplayText("You are assigned to soak |cFF00FF00Execution Sentence|r in the " .. text .. " Group", 5)
    end
end
