local _, NSI = ... -- Internal namespace

local encID = 3183
-- /run NSAPI:DebugEncounter(3183)
NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        id = id or self:DifficultyCheck(14) or 0
        local Alert = self:CreateDefaultAlert("Memory Game", "Text", nil, 6, 1, encID)
        local timers = {
            [15] = {10, 80, 150},
            [16] = {33, 95, 157},
        }
        if id == 16 then Alert.dur = 4 end -- bit shorter duration to not overlap with glaives
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Glaives", "Text", nil, 6, 1, encID)
        local timers = {
            [15] = {38, 108, 178},
            [16] = {29, 91, 153}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Interrupts", "Text", nil, 6, 1, encID)
        local timers = {
            [15] = {59, 129},
            [16] = {6.4, 68.4, 130.4}
        }
        self:AddRemindersFromTable(Alert, timers[id])


        local Alert = self:CreateDefaultAlert("Beams", "Text", nil, 5, 1, encID)
        local timers = {
            [16] = {57, 119}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        if UnitGroupRolesAssigned("player") == "TANK" then
            local Alert = self:CreateDefaultAlert("Tank-Hit", "Text", nil, 6, 1, encID)
            Alert.TTS = false
            local timers = {
                [16] = {21.5, 41.5, 61.5, 81.5, 101.5, 121.5, 141.5, 161.5}
            }
            self:AddRemindersFromTable(Alert, timers[id])

            local Alert = self:CreateDefaultAlert("Tank-Hit", "Text", nil, 6, 3, encID)
            Alert.TTS = false
            local timers = {
                [16] = {21.5, 41.5, 61.5}
            }
            self:AddRemindersFromTable(Alert, timers[id])
        end

        local Alert = self:CreateDefaultAlert("Beams", "Text", nil, 3, 2, encID) -- Transiton Beams
        Alert.TTS = false
        local timers = {
            [16] = {10.7, 15.7, 20.7, 25.7, 30.7}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Full Blaze", "Text", nil, 3, 2, encID) -- Everyone Debuff
        Alert.TTS = false
        Alert.colors = {1, 0, 0, 1}
        local timers = {
            [16] = {37.7}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 7, 3, encID)
        Alert.TTS = false
        if id == 16 then Alert.dur = 6 end
        local timers = {
            [15] = {20, 50, 80},
            [16] = {19, 49, 79}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Spread", "Text", nil, 5, 3, encID)
        local timers = {
            [16] = {26.8, 56.8, 86.8}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Orbs", "Text", nil, 7, 3, encID)
        if id == 16 then Alert.dur = 5 end
        local timers = {
            [15] = {35.5, 65.5, 95.5},
            [16] = {35.5, 65.5, 95.5}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Crystal", "Text", nil, 5, 4, encID)
        local timers = {
            [15] = {22, 60, 98}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 5, 4, encID)
        Alert.text = "Soaks"
        local timers = {
            [15] = {31, 69, 107}
        }
        self:AddRemindersFromTable(Alert, timers[id])
    end
    if NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID].ClickableRunes then
        self.LuraClicks = self.LuraClicks or {}
        self.LuraBackground = self.LuraBackground or {}
        local numbers = {2, 3, 4, 6, 7}

        local function createHighlightTexture(self)
            local texture = self:CreateTexture(nil, "OVERLAY")
            self.highlight = texture
            texture:SetTexture([[Interface\QuestFrame\UI-QuestLogTitleHighlight]])
            texture:SetBlendMode("ADD")
            texture:SetAllPoints(self)
            texture:SetAlpha(.4)
            return texture
        end

        local function onButtonEnter(self)
            if not self.highlight then
                createHighlightTexture(self)
            end
            self.highlight:Show()
            self:SetBackdropBorderColor(1, 1, 1)
        end
        local function onButtonLeave(self)
            if self.highlight then
                self.highlight:Hide()
            end
            self:SetBackdropBorderColor(0, 0, 0)
        end
        local count = 0
        local path = {
            [2] = [[Interface\AddOns\NorthernSkyRaidTools\Media\EncounterPics\Circle.blp]],
            [3] = [[Interface\AddOns\NorthernSkyRaidTools\Media\EncounterPics\Diamond.blp]],
            [4] = [[Interface\AddOns\NorthernSkyRaidTools\Media\EncounterPics\Triangle.blp]],
            [6] = [[Interface\AddOns\NorthernSkyRaidTools\Media\EncounterPics\T.blp]],
            [7] = [[Interface\AddOns\NorthernSkyRaidTools\Media\EncounterPics\Cross.blp]],
        }
        local chatmsgs = {
            [2] = "27:107:299:374",
            [3] = "22:98:377:507",
            [4] = "18:112:3:86",
            [6] = "23:105:86:201",
            [7] = "11:123:210:291",
        }
        for _, num in ipairs(numbers) do
            if not self.LuraBackground[num] then
                self.LuraBackground[num] = CreateFrame("Frame", nil, self.NSRTFrame, "BackdropTemplate")
                self.LuraBackground[num]:SetBackdrop({bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
                self.LuraBackground[num]:SetBackdropColor(0.5, 0.5, 0.5, 1)
                self.LuraBackground[num]:SetBackdropBorderColor(0, 0, 0, 0.5)
                self.LuraBackground[num].texture = self.LuraBackground[num]:CreateTexture(nil, "OVERLAY")
                self.LuraBackground[num].texture:SetTexture(path[num])
                self.LuraBackground[num].texture:SetAllPoints(self.LuraBackground[num])
            end
            if not self.LuraClicks[num] then
                self.LuraClicks[num] = CreateFrame("Button", "LuraRuneButton"..num, self.NSRTFrame, "SecureActionButtonTemplate,BackdropTemplate")
            end
            self.LuraBackground[num]:SetWidth(100)
            self.LuraBackground[num]:SetHeight(100)
            self.LuraBackground[num]:Show()
            local offset = count*105
            local xOffset = NSRT.Settings.LuraOffsetX or 300
            local yOffset = NSRT.Settings.LuraOffsetY or 0
            count = count+1
            self.LuraBackground[num]:ClearAllPoints()
            self.LuraBackground[num]:SetPoint(NSRT.Settings.LuraAnchor or "LEFT", self.NSRTFrame, NSRT.Settings.LuraRelativePoint or "LEFT", xOffset+offset, yOffset)
            self.LuraClicks[num]:SetAllPoints(self.LuraBackground[num])
            self.LuraClicks[num]:SetAttribute("type1", "macro")
            self.LuraClicks[num]:SetAttribute("macrotext1", "/raid "..chatmsgs[num])
            self.LuraClicks[num]:SetAttribute("useOnKeyDown", false)
            self.LuraClicks[num]:RegisterForClicks("AnyUp", "AnyDown")
            self.LuraClicks[num]:SetScript("OnEnter", onButtonEnter)
            self.LuraClicks[num]:SetScript("OnLeave", onButtonLeave)
            self.LuraClicks[num]:Show()
        end
    end
    if NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID].RunesDisplay then
        self.LuraRunesFrame = self.LuraRunesFrame or CreateFrame("Frame", "nil", self.NSRTFrame, "BackdropTemplate")
        self.LuraRunesFrame:ClearAllPoints()
        self.LuraRunesFrame:SetPoint(NSRT.Settings.LuraDisplayAnchor or "TOPLEFT", self.NSRTFrame, NSRT.Settings.LuraDisplayRelativePoint or "TOPLEFT", NSRT.Settings.LuraDisplayOffsetX or 300, NSRT.Settings.LuraDisplayOffsetY or -300)
        self.LuraRunesFrame:SetBackdrop({bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
        self.LuraRunesFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.5)
        self.LuraRunesFrame:SetBackdropBorderColor(0, 0, 0, 0.5)
        self.LuraRunesFrame:SetWidth(200)
        self.LuraRunesFrame:SetHeight(200)
        self.LuraRunesCompleted = {}
        self.LuraRunesInverted = false

        self.LuraRunesDisplay = self.LuraRunesDisplay or {}

        local XOffset = {50, 60, 0, -60, -50}
        local YOffset = {50, -25, -70, -25, 50}
        self.AlertTimers = self.AlertTimers or {}

        local function DisplayRune(pos, text)
            if not self.LuraRunesDisplay[pos] then
                self.LuraRunesDisplay[pos] = self.LuraRunesFrame:CreateFontString(nil, "OVERLAY")
                self.LuraRunesDisplay[pos]:SetFont("Fonts\\FRIZQT__.TTF", 15)
                self.LuraRunesDisplay[pos]:SetPoint("CENTER", self.LuraRunesFrame, "CENTER", XOffset[pos], YOffset[pos])
                self.LuraRunesDisplay[pos]:SetSize(200, 200)
                self.LuraRunesDisplay[pos]:SetTextColor(1, 1, 1)
            end
            self.LuraRunesDisplay[pos]:SetFormattedText("%s%s%s", "|T7412681:48:48:0:0:512:512:", text, "|t")
            self.LuraRunesDisplay[pos]:Show()
        end
        local function HideAllRunes()
            for i=1, 5 do
                if self.LuraRunesDisplay[i] then
                    self.LuraRunesDisplay[i]:Hide()
                end
            end
            self.LuraRunesCompleted = {}
            self.LuraRunesFrame:Hide()
        end
        self.LuraRunesFrame:SetScript("OnEvent", function(_, e, msg)
            if e == "CHAT_MSG_RAID" then
                local pos = 2
                if self.LuraRunesCompleted[pos] then pos = 3 end
                if self.LuraRunesCompleted[pos] then pos = 5 end
                self.LuraRunesCompleted[pos] = true
                if self.LuraRunesInverted then pos = 6-pos end
                DisplayRune(pos, msg)
                self.LuraRunesFrame:Show()
                if self.HideTimer then
                    self.HideTimer:Cancel()
                end
                self.HideTimer = C_Timer.NewTimer(20, function()
                    HideAllRunes()
                end)
            elseif e == "CHAT_MSG_RAID_LEADER" then
                local pos = 1
                if self.LuraRunesCompleted[pos] then pos = 4 end
                self.LuraRunesCompleted[pos] = true
                if self.LuraRunesInverted then pos = 6-pos end
                DisplayRune(pos, msg)
                self.LuraRunesFrame:Show()
                if self.HideTimer then
                    self.HideTimer:Cancel()
                end
                self.HideTimer = C_Timer.NewTimer(20, function()
                    HideAllRunes()
                end)
            end
        end)
        self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID")
        self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
        self.LuraRunesFrame:Hide()

        self.AlertTimers[1] = C_Timer.NewTimer(60, function()
            self.LuraRunesInverted = true
            self.AlertTimers[1] = nil
            self.LuraRunesCompleted = {}
        end)
        self.AlertTimers[2] = C_Timer.NewTimer(120, function()
            self.LuraRunesInverted = false
            self.AlertTimers[2] = nil
            self.LuraRunesCompleted = {}
        end)
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID].ClickableRunes then
        local numbers = {2, 3, 4, 6, 7}
        for _, num in ipairs(numbers) do
            if self.LuraClicks and self.LuraClicks[num] then
                self.LuraClicks[num]:Hide()
            end
            if self.LuraBackground and self.LuraBackground[num] then
                self.LuraBackground[num]:Hide()
            end
        end
    end
    if self.LuraRunesFrame then
        self.LuraRunesFrame:UnregisterAllEvents()
        self.LuraRunesFrame:Hide()
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

local detectedDurations = {
    [15] = {
        {time = 45, phase = function(num, diff) return 2 end},
        {time = 97, phase = function(num) return 3 end},
        {time = 180, phase = function(num) return 4 end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    local diff = now -self.PhaseSwapTime
    if phaseinfo and info.duration == phaseinfo.time then
        local newphase = phaseinfo.phase(self.Phase, diff)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            if self.Phase ~= 2 then return end
            local numbers = {2, 3, 4, 6, 7}
            for _, num in ipairs(numbers) do
                if self.LuraClicks and self.LuraClicks[num] then
                    self.LuraClicks[num]:Hide()
                end
                if self.LuraBackground and self.LuraBackground[num] then
                    self.LuraBackground[num]:Hide()
                end
            end
            if self.LuraRunesFrame then
                self.LuraRunesFrame:UnregisterAllEvents()
                self.LuraRunesFrame:Hide()
            end
        end
    end
end