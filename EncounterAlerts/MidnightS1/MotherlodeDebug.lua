local _, NSI = ... -- Internal namespace

local encID = 3463
-- /run NSAPI:DebugEncounter(3463)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local function DisplayLine()
            if not self.LineTexture then
                self.LineTexture = self.LineFrame:CreateTexture(nil, "BACKGROUND")
                self.LineTexture:SetColorTexture(0, 1, 0, 1)
                self.LineFrame:SetSize(1, 3000)
                self.LineFrame:SetPoint("BOTTOM", UIParent, "CENTER", 0, 0)  
                self.LineTexture:SetAllPoints(self.LineFrame)               
            end                     
            self.LineFrame:Show()
            self.LineTexture:Show()
            C_Timer.After(6.5, function() 
                self.LineTexture:Hide()
                self.LineFrame:Hide()
            end)
        end
        if not self.LineFrame then
            self.LineFrame = CreateFrame("Frame")
        end
        self.LineFrame:Show()

        local Ghosts = self:CreateDefaultAlert("Spirits", "Text", nil, 7, 1, encID)
        self.SpiritTimers = {}
        for _, time in ipairs({10.3, 84.7, 109.7}) do
            Ghosts.time = time
            self:AddToReminder(Ghosts)            
            self.SpiritTimers[time] = C_Timer.NewTimer(time, function() DisplayLine() end)
        end
        --[[
        local Soak = self:CreateDefaultAlert("Soak", "Bar", 1241291, 8, 1, encID)
        Soak.time = 10
        self:AddToReminder(Soak)
        ]]
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

local detectedDurations = {} -- Add smth here after seeing fight in pre-patch. Probably one thing for dmg amp phase and then one for last phase to account for guilds hardpushing at 10%.

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    for k, v in ipairs(detectedDurations) do
        if info.duration == v then            
            self.Phase = self.Phase+1                  
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            for i, v in ipairs(self.SpiritTimers) do
                v:Cancel()
            end
            break
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END   
    if NSRT.EncounterAlerts[encID].enabled then
        for i, v in ipairs(self.SpiritTimers) do
            v:Cancel()
        end
        self.SpiritTimers = {}
        self.LineFrame:Hide()
        self.LineTexture:Hide()
    end
end