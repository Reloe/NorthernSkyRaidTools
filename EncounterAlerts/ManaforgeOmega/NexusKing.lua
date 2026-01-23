local _, NSI = ... -- Internal namespace

local encID = 3134
-- /run NSAPI:DebugEncounter(3134)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        if not self:DifficultyCheck(16) then return end -- Mythic only
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

        local Ghosts = self:CreateDefaultAlert("Spirits", "Text", nil, 7, 1, encID) -- Phase 1 Spirit Reminders + Line
        self.SpiritTimers = {}
        for _, time in ipairs({44.3, 84.7, 109.7}) do
            Ghosts.time = time
            self:AddToReminder(Ghosts)            
            self.SpiritTimers[time] = C_Timer.NewTimer(time, function() DisplayLine() end)
        end

        local Markers = self:CreateDefaultAlert("Markers", "Text", nil, 10, 3, encID) -- Phase 3 Galactic Smash Reminders
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        for i, time in ipairs({17, 72, 127}) do
            Markers.time = time
            local isMelee = self.meleetable[specid]
            local mark = (i == 1 and (isMelee and 7 or 1)) or (i == 2 and (isMelee and 2 or 1)) or (isMelee and 4 or 8)
            Markers.text = "{rt"..mark.."}SMASH{rt"..mark.."}"
            self:AddToReminder(Markers)
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

local phasedetections = {3, 3, 3, 3} -- old detection method based on number of events happening. Might very well fail on NK

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    self.Timelines = self.Timelines or {}
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
        if not self:DifficultyCheck(16) then return end -- Mythic only
        for i, v in ipairs(self.SpiritTimers) do
            v:Cancel()
        end
        self.SpiritTimers = {}
        self.LineFrame:Hide()
        self.LineTexture:Hide()
    end
end