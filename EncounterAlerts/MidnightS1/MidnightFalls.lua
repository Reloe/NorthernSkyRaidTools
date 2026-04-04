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
            [15] = {10, 80, 150}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Glaives", "Text", nil, 6, 1, encID)
        timers = {
            [15] = {38, 108, 178}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Interrupts", "Text", nil, 6, 1, encID)
        timers = {
            [15] = {59, 129}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 7, 3, encID)
        Alert.TTS = false
        timers = {
            [15] = {20, 50, 80}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Orbs", "Text", nil, 7, 3, encID)
        timers = {
            [15] = {35.5, 65.5, 95.5}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Crystal", "Text", nil, 5, 4, encID)
        timers = {
            [15] = {22, 60, 98}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 5, 4, encID)
        Alert.text = "Soaks"
        timers = {
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
            self.LuraBackground[num]:SetPoint(NSRT.Settings.LuraAnchor or "LEFT", self.NSRTFrame, NSRT.Settings.LuraRelativePoint or "LEFT", xOffset+offset, yOffset)
            self.LuraClicks[num]:SetAllPoints(self.LuraBackground[num])
            self.LuraClicks[num]:SetAttribute("type1", "macro")
            self.LuraClicks[num]:SetAttribute("macrotext1", "/raid "..num)
            self.LuraClicks[num]:SetAttribute("useOnKeyDown", false)
            self.LuraClicks[num]:RegisterForClicks("AnyUp", "AnyDown")
            self.LuraClicks[num]:SetScript("OnEnter", onButtonEnter)
            self.LuraClicks[num]:SetScript("OnLeave", onButtonLeave)
            self.LuraClicks[num]:Show()
        end
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
        end
    end
end