local _, NSI = ... -- Internal namespace

local encID = 3183
-- /run NSAPI:DebugEncounter(3183)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local function Add(diffID, name, alertDef)
        NSI:AddEncounterAlert(encID, diffID, name, alertDef)
    end

    local function TankOnly()
        local lc = NSI.DefaultLoadConditions()
        lc.Roles.TANK = true
        return lc
    end

    -- Phase 1
    Add(15, "Memory Game", NSI:MakeEncounterAlert("Memory Game", nil, 6, "Text", {
        [1] = { 10, 80, 150 },
    }))
    Add(16, "Memory Game", NSI:MakeEncounterAlert("Memory Game", nil, 4, "Text", {
        [1] = { 33, 95, 157 },
    }))

    for _, diff in ipairs({ 15, 16 }) do
        Add(diff, "Glaives", NSI:MakeEncounterAlert("Glaives", nil, 6, "Text", {
            [1] = diff == 15 and { 38, 108, 178 } or { 29, 91, 153 },
        }))
        Add(diff, "Interrupts", NSI:MakeEncounterAlert("Interrupts", nil, 6, "Text", {
            [1] = diff == 15 and { 59, 129 } or { 6.4, 68.4, 130.4 },
        }))
    end

    Add(16, "Beams", NSI:MakeEncounterAlert("Beams", nil, 5, "Text", {
        [1] = { 57, 119 },
        [2] = { 10.7, 15.7, 20.7, 25.7, 30.7 },
    }, { countdown = 3 }))

    Add(16, "Tank-Hit", NSI:MakeEncounterAlert("Tank-Hit", nil, 6, "Text", {
        [1] = { 21.5, 41.5, 61.5, 81.5, 101.5, 121.5, 141.5, 161.5 },
        [3] = { 21.5, 41.5, 61.5 },
    }, { TTS = false, loadConditions = TankOnly() }))

    -- Phase 2 (transition)
    Add(16, "Full Blaze", NSI:MakeEncounterAlert("Full Blaze", nil, 3, "Text", {
        [2] = { 37.7 },
    }, { TTS = false, colors = { 1, 0, 0, 1 } }))

    -- Phase 3
    Add(16, "Seed-Drop", NSI:MakeEncounterAlert("Seed-Drop", 1253031, 5, "Bar", {
        [3] = { 17.5, 25, 47.5, 55, 77.5, 85 },
    }, { countdown = 3, TTS = false }))

    Add(15, "Soaks", NSI:MakeEncounterAlert("Soaks", nil, 7, "Text", {
        [3] = { 20, 50, 80 },
        [4] = { 31, 69, 107 },
    }, { TTS = false }))
    Add(16, "Soaks", NSI:MakeEncounterAlert("Soaks", nil, 6, "Text", {
        [3] = { 19, 49, 79 },
    }, { TTS = false }))

    Add(16, "Spread", NSI:MakeEncounterAlert("Spread", nil, 5, "Text", {
        [3] = { 26.8, 56.8, 86.8 },
    }))

    Add(15, "Orbs", NSI:MakeEncounterAlert("Orbs", nil, 7, "Text", {
        [3] = { 35.5, 65.5, 95.5 },
    }))
    Add(16, "Orbs", NSI:MakeEncounterAlert("Orbs", nil, 5, "Text", {
        [3] = { 35.5, 65.5, 95.5 },
    }))

    -- Phase 4
    Add(15, "Crystal", NSI:MakeEncounterAlert("Crystal", nil, 5, "Text", {
        [4] = { 22, 60, 98 },
    }))
end

NSI.EncounterAlertStart[encID] = function(self, id, preview) -- on ENCOUNTER_START
    local realpull = not id
    id = id or self:DifficultyCheck(14) or 0
    if realpull and id == 16 then
        NSI.NSRTFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end

    if not preview then
        self:FireEncounterAlerts(encID, id)
    end

    local Alert = self:CreateDefaultAlert("Glaives", "Text", nil, 6, 1, encID)
    local timers = {
        [15] = { 38, 108, 178 },
        [16] = { 29, 91, 153 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Interrupts", "Text", nil, 6, 1, encID)
    local timers = {
        [15] = { 59, 129 },
        [16] = { 6.4, 68.4, 130.4 }
    }
    self:AddRemindersFromTable(Alert, timers[id])


    local Alert = self:CreateDefaultAlert("Beams", "Text", nil, 5, 1, encID)
    local timers = {
        [16] = { 57, 119 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    if UnitGroupRolesAssigned("player") == "TANK" then
        local Alert = self:CreateDefaultAlert("Tank-Hit", "Text", nil, 6, 1, encID)
        Alert.colors = { 1, 0, 0, 1 }
        Alert.TTS = false
        local timers = {
            [16] = { 21.5, 41.5, 61.5, 81.5, 101.5, 121.5, 141.5, 161.5 }
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Tank-Hit", "Text", nil, 6, 3, encID)
        Alert.colors = { 1, 0, 0, 1 }
        Alert.TTS = false
        local timers = {
            [16] = { 21.5, 41.5, 61.5, 81.5 }
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Tank-Hit", "Text", nil, 6, 4, encID)
        Alert.colors = { 1, 0, 0, 1 }
        Alert.TTS = false
        local timers = {
            [16] = { 41.5, 71.5, 101.5, 131.5, 161.5 }
        }
        self:AddRemindersFromTable(Alert, timers[id])
    end

    local Alert = self:CreateDefaultAlert("Beams", "Text", nil, 3, 2, encID) -- Transiton Beams
    Alert.TTS = false
    local timers = {
        [16] = { 10.7, 15.7, 20.7, 25.7, 30.7 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Full Blaze", "Text", nil, 3, 2, encID) -- Everyone Debuff
    Alert.TTS = false
    Alert.colors = { 1, 0, 0, 1 }
    local timers = {
        [16] = { 37.7 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 7, 3, encID)
    Alert.TTS = false
    if id == 16 then Alert.dur = 6 end
    local timers = {
        [15] = { 20, 50, 80 },
        [16] = { 19, 49, 79 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Spread", "Text", nil, 5, 3, encID)
    Alert.TTS = false
    local timers = {
        [16] = { 26.8, 56.8, 86.8, 105 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Orbs", "Text", nil, 7, 3, encID)
    if id == 16 then Alert.dur = 5 end
    local timers = {
        [15] = { 35.5, 65.5, 95.5 },
        [16] = { 35.5, 65.5, 95.5 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Crystal", "Text", nil, 5, 4, encID)
    local timers = {
        [15] = { 22, 60, 98 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 5, 4, encID)
    Alert.text = "Soaks"
    local timers = {
        [15] = { 31, 69, 107 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Blazes", "Text", nil, 5, 5, encID) -- Last Phase Blazes
    local timers = {
        [16] = { 12.7, 32.7, 52.7, 72.7 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local Alert = self:CreateDefaultAlert("Move", "Text", nil, 5, 5, encID) -- Heaven & Hell
    Alert.TTSTimer = 0
    local timers = {
        [16] = { 19.8, 39.8, 59.8 }
    }
    self:AddRemindersFromTable(Alert, timers[id])

    local side = NSRT.EncounterAlerts[encID].P3Side
    if side and (side == "LEFT" or side == "BOTH") then
        local Alert = self:CreateDefaultAlert("Memory Game", "Text", nil, 5, 4, encID)
        local timers = {
            [16] = { 40, 75, 150 },
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 5, 4, encID)
        Alert.TTSTimer = 2
        local timers = {
            [16] = { 18.2, 90.2, 128.2 },
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soak-Time", "Bar", 1266897, 20, 4, encID)
        Alert.TTS = false
        local timers = {
            [16] = { 38.7, 110.7, 148.7 },
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Stars", "Text", nil, 5, 4, encID)
        Alert.TTS = false
        local timers = {
            [16] = { 20.4, 28.4, 36.4, 44.4, 52.4, 79.4, 87.4, 95.4, 103.4 },
        }
        self:AddRemindersFromTable(Alert, timers[id])
    end
    if side and (side == "RIGHT" or side == "BOTH") then
        local Alert = self:CreateDefaultAlert("Memory Game", "Text", nil, 5, 4, encID)
        local timers = {
            [16] = { 20, 95, 130 },
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 5, 4, encID)
        Alert.TTSTimer = 2
        local timers = {
            [16] = { 38, 73, 148 },
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soak-Time", "Bar", 1266897, 20, 4, encID)
        Alert.TTS = false
        local timers = {
            [16] = { 58.5, 93.5, 168.5 },
        }
        self:AddRemindersFromTable(Alert, timers[id])


        local Alert = self:CreateDefaultAlert("Stars", "Text", nil, 5, 4, encID)
        Alert.TTS = false
        local timers = {
            [16] = { 24.2, 32.2, 40.2, 48.2, 75.2, 83.2, 91.2, 99.2, 107.2 },
        }
        self:AddRemindersFromTable(Alert, timers[id])
    end
    if NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID].RunesDisplay and (realpull or preview) then
        local isTank = UnitGroupRolesAssigned("player") == "TANK"
        local XOffset = { 50, 60, 0, -60, -50 }
        local YOffset = { 50, -25, -70, -25, 50 }
        local function DisplayRune(pos, text, isMythic)
            if not isMythic then
                pos = 1
                for i = 2, 5 do
                    if self.LuraRunesCompleted[i - 1] then
                        pos = i
                    else
                        break
                    end
                end
                self.LuraRunesCompleted[pos] = true
            end

            if not self.LuraRunesDisplay[pos] then
                self.LuraRunesDisplay[pos] = self.LuraRunesFrame:CreateFontString(nil, "OVERLAY")
                self.LuraRunesDisplay[pos]:SetFont("Fonts\\FRIZQT__.TTF", 15)
                self.LuraRunesDisplay[pos]:SetTextColor(1, 1, 1)

                self.LuraRunesNumbers[pos] = self.LuraRunesFrame:CreateFontString(nil, "OVERLAY")
                self.LuraRunesNumbers[pos]:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), 25, "OUTLINE")
                self.LuraRunesNumbers[pos]:SetTextColor(1, 1, 1)
                self.LuraRunesNumbers[pos]:SetShadowColor(0, 0, 0, 1)
            end
            self.LuraRunesDisplay[pos]:ClearAllPoints()
            self.LuraRunesNumbers[pos]:ClearAllPoints()
            if self.Phase == 4 then
                self.LuraRunesDisplay[pos]:SetPoint("LEFT", self.LuraRunesFrame, "LEFT", (pos - 1) * 60, 0)
                self.LuraRunesNumbers[pos]:SetPoint("LEFT", self.LuraRunesFrame, "LEFT", (pos - 1) * 60 + 22, 30)
            else
                local posX = isTank and XOffset[pos] * -1 or XOffset[pos]
                local posY = isTank and YOffset[pos] * -1 or YOffset[pos]
                self.LuraRunesDisplay[pos]:SetPoint("CENTER", self.LuraRunesFrame, "CENTER", posX, posY)
                self.LuraRunesNumbers[pos]:SetPoint("CENTER", self.LuraRunesFrame, "CENTER", posX, posY + 30)
            end
            self.LuraRunesDisplay[pos]:SetFormattedText("|T%s:48:48|t", text)
            self.LuraRunesDisplay[pos]:Show()

            local number = pos
            self.LuraRunesNumbers[pos]:SetText(number)
            self.LuraRunesNumbers[pos]:Show()
        end
        if preview then
            local iconIDs = { "134635", "340528", "351033", "7242384", "236903" }
            for i = 1, 5 do
                DisplayRune(i, iconIDs[i], false)
            end
        end
        local function HideAllRunes()
            for i = 1, 5 do
                if self.LuraRunesDisplay[i] then self.LuraRunesDisplay[i]:Hide() end
                if self.LuraRunesNumbers[i] then self.LuraRunesNumbers[i]:Hide() end
            end
            self.LuraRunesCompleted = {}
            if self.Phase ~= 4 then
                self.LuraRunesFrame:UnregisterEvent("CHAT_MSG_RAID")
                self.LuraRunesFrame:UnregisterEvent("CHAT_MSG_RAID_LEADER")
            end
            self.LuraRunesFrame:Hide()
        end

        if not self.LuraRunesFrame then
            self.LuraRunesFrame = CreateFrame("Frame", "nil", self.NSRTFrame, "BackdropTemplate")
        end
        self.LuraRunesFrame:SetScript("OnEvent", function(_, e, msg)
            if e == "CHAT_MSG_RAID" then
                self.LuraRunesFrame:Show()
                if self.HideTimer then
                    self.HideTimer:Cancel()
                end
                local hideduration = self.Phase == 4 and 13 or 15
                self.HideTimer = C_Timer.NewTimer(hideduration, function()
                    HideAllRunes()
                end)

                if id ~= 16 or self.Phase == 4 then
                    DisplayRune(pos, msg, false)
                    return
                end
                local pos = 2
                if self.LuraRunesCompleted[pos] then pos = 3 end
                if self.LuraRunesCompleted[pos] then pos = 5 end
                self.LuraRunesCompleted[pos] = true
                DisplayRune(pos, msg, true)
            elseif e == "CHAT_MSG_RAID_LEADER" then
                self.LuraRunesFrame:Show()
                if self.HideTimer then
                    self.HideTimer:Cancel()
                end
                local hideduration = self.Phase == 4 and 13 or 15
                self.HideTimer = C_Timer.NewTimer(hideduration, function()
                    HideAllRunes()
                end)

                if id ~= 16 or self.Phase == 4 then
                    DisplayRune(pos, msg, false)
                    return
                end
                local pos = 1
                if self.LuraRunesCompleted[pos] then pos = 4 end
                self.LuraRunesCompleted[pos] = true
                DisplayRune(pos, msg, true)
            end
        end)
        self.LuraRunesFrame:ClearAllPoints()
        self.LuraRunesFrame:SetPoint(NSRT.EncounterAlerts[encID].LuraDisplayAnchor or "TOPLEFT", self.NSRTFrame,
            NSRT.EncounterAlerts[encID].LuraDisplayRelativePoint or "TOPLEFT",
            NSRT.EncounterAlerts[encID].LuraDisplayOffsetX or 500, NSRT.EncounterAlerts[encID].LuraDisplayOffsetY or -300)
        self.LuraRunesFrame:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile =
        [[Interface\Buttons\WHITE8X8]], edgeSize = 1 })
        self.LuraRunesFrame:SetBackdropColor(unpack(NSRT.EncounterAlerts[encID].LuraDisplayColor or { 0.5, 0.5, 0.5, 0.9 }))
        self.LuraRunesFrame:SetBackdropBorderColor(unpack(NSRT.EncounterAlerts[encID].LuraDisplayColor or
        { 0.5, 0.5, 0.5, 0.9 }))
        self.LuraRunesFrame:SetWidth(200)
        self.LuraRunesFrame:SetHeight(200)

        self.LuraRunesCompleted = {}

        self.LuraRunesDisplay = self.LuraRunesDisplay or {}
        self.LuraRunesNumbers = self.LuraRunesNumbers or {}
        self.AlertTimers = self.AlertTimers or {}
        if preview then
            local iconIDs = { "134635", "340528", "351033", "7242384", "236903" }
            for i = 1, 5 do
                DisplayRune(i, iconIDs[i], false)
            end
        end
        local timers = {
            [14] = { 10, 80, 150 },
            [15] = { 10, 80, 150 },
            [16] = { 33, 95, 157 },
        }
        self.LuraRuneTimers = {}
        if preview then return end
        for i, time in ipairs(timers[id] or {}) do -- enable event register 2s before each memory game. then disable it again later
            self.LuraRuneTimers[i] = C_Timer.NewTimer(time - 2, function()
                self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID")
                self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
            end)
        end
        self.LuraRunesFrame:Hide()

        self.AlertTimers[1] = C_Timer.NewTimer(70, function()
            if not self.AlertTimers then return end
            HideAllRunes()
            self.AlertTimers[1] = nil
            self.LuraRunesCompleted = {}
        end)
        self.AlertTimers[2] = C_Timer.NewTimer(140, function()
            if not self.AlertTimers then return end
            HideAllRunes()
            self.AlertTimers[2] = nil
            self.LuraRunesCompleted = {}
        end)
    end
end

NSI.EncounterAlertStop[encID] = function(self, Alertcall) -- on ENCOUNTER_END
    if self.LuraRunesFrame and not Alertcall then
        self.LuraRunesFrame:UnregisterAllEvents()
        self.LuraRunesFrame:Hide()
        for i = 1, 5 do
            if self.LuraRunesDisplay[i] then
                self.LuraRunesDisplay[i]:Hide()
            end
            if self.LuraRunesNumbers[i] then
                self.LuraRunesNumbers[i]:Hide()
            end
        end
        self.LuraRunesCompleted = {}
        if self.AlertTimers then
            for i, v in ipairs(self.AlertTimers) do
                if v and v.Cancel then
                    v:Cancel()
                end
            end
            self.AlertTimers = nil
        end
        if self.LuraRuneTimers then
            for i, v in ipairs(self.LuraRuneTimers) do
                if v and v.Cancel then
                    v:Cancel()
                end
            end
            self.LuraRuneTimers = nil
        end
        NSI.NSRTFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
end

local detectedDurations = {
    [15] = {
        { time = 45,  phase = function(num) return 2 end },
        { time = 97,  phase = function(num) return 3 end },
        { time = 180, phase = function(num) return 4 end },
    },
    [16] = {
        { time = 45,  phase = function(num) return 2 end },
        { time = 97,  phase = function(num) return 3 end },
        { time = 180, phase = function(num) return 4 end },
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" and self.Phase == 4 then
        if (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 20)) then return end
        if not UnitExists("boss2") then
            self.Phase = 5
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = GetTime()
        end
        return
    end
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    if phaseinfo and ApproximatelyEqual(info.duration, phaseinfo.time, 0.2) then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            if self.Phase == 4 and difficultyID == 16 then
                if self.LuraRunesFrame then
                    self.LuraRunesFrame:SetWidth(300)
                    self.LuraRunesFrame:SetHeight(60)
                    self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID")
                    self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
                end
                local timers = { 20, 40, 75, 95, 130, 150 }
                if self.LuraRuneTimers then
                    for i, v in ipairs(self.LuraRuneTimers) do
                        if v and v.Cancel then
                            v:Cancel()
                        end
                    end
                end
                self.LuraRuneTimers = {}
                for i, time in ipairs(timers) do -- remove previous display 2s before memory game
                    self.LuraRuneTimers[i] = C_Timer.NewTimer(time - 2, function()
                        for num = 1, 5 do
                            if self.LuraRunesDisplay[num] then
                                self.LuraRunesDisplay[num]:Hide()
                            end
                            if self.LuraRunesNumbers[num] then
                                self.LuraRunesNumbers[num]:Hide()
                            end
                        end
                        self.LuraRunesCompleted = {}
                        self.LuraRunesFrame:Hide()
                    end)
                end
                return
            end
            if self.Phase ~= 2 and self.Phase ~= 5 then return end
            if self.LuraRunesFrame then
                self.LuraRunesFrame:UnregisterAllEvents()
                self.LuraRunesFrame:Hide()
            end
        end
    end
end
