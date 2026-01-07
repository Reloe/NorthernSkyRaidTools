local _, NSI = ... -- Internal namespace

local encID = 3135
-- /run NSAPI:DebugEncounter(3135)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Knock = self:CreateDefaultAlert("Knock", "Text", nil, 5, 1, encID) -- Phase 1 Knocks
        for _, time in ipairs({25, 67.1, 109.2, 151.3}) do
            Knock.time = time
            self:AddToReminder(Knock)            
        end

        local P1Devour = self:CreateDefaultAlert("Devour", "Text", nil, 7, 4, encID) -- Phase 1 Devour
        for _, time in ipairs({12.5, 96.7}) do
            P1Devour.time = time
            self:AddToReminder(P1Devour)            
        end

        local P2Rockspawn = self:CreateDefaultAlert("Rock-Spawn", "Text", nil, 6, 2, encID) -- 1st Platform Rockspawn
        P2Rockspawn.TTS = "Move"
        P2Rockspawn.TTSTimer = 0
        for i, time in ipairs({19, 61}) do
            P2Rockspawn.time = time
            if i == 2 then
                P2Rockspawn.TTS = "Gateway"
            end
            self:AddToReminder(P2Rockspawn)            
        end

        local P3Rockspawn = self:CreateDefaultAlert("Rock-Spawn", "Text", nil, 6, 3, encID) -- 2nd Platform Rockspawn
        P3Rockspawn.TTS = "Move"
        P3Rockspawn.TTSTimer = 0
        for i, time in ipairs({22, 53}) do
            P3Rockspawn.time = time
            if i == 2 then
                P3Rockspawn.TTS = "Gateway"
            end
            self:AddToReminder(P3Rockspawn)            
        end

        local P3Bait = self:CreateDefaultAlert("Bait", "Text", nil, 6, 3, encID) -- 2nd Platform Bait
        for _, time in ipairs({14, 46}) do
            P3Bait.time = time
            self:AddToReminder(P3Bait)            
        end

        local P2Gravity = self:CreateDefaultAlert("Gravity", "Text", nil, 5, 2, encID) -- 1st Platform Gravity
        for _, time in ipairs({26}) do
            P2Gravity.time = time
            self:AddToReminder(P2Gravity)            
        end

        local P3Gravity = self:CreateDefaultAlert("Gravity", "Text", nil, 5, 3, encID) -- 2nd Platform Gravity
        for _, time in ipairs({29, 60}) do
            P3Gravity.time = time
                self:AddToReminder(P3Gravity)            
            end

        local P2Pushback = self:CreateDefaultAlert("Pushback", "Text", nil, 8, 2, encID) -- 1st Platform Pushback
        for _, time in ipairs({34}) do
            P2Pushback.time = time
            self:AddToReminder(P2Pushback)            
        end

        local P3Pushback = self:CreateDefaultAlert("Pushback", "Text", nil, 8, 3, encID) -- 2nd Platform Pushback
        for _, time in ipairs({36, 68}) do
            P3Pushback.time = time
            self:AddToReminder(P3Pushback)            
        end

        local P4Gravity = self:CreateDefaultAlert("Gravity", "Text", nil, 8, 4, encID) -- Phase "4" Gravity
        for _, time in ipairs({64.5, 90.5, 122.5, 148.5 ,180.5}) do
            P4Gravity.time = time
            self:AddToReminder(P4Gravity)            
        end

        local P3Devour = self:CreateDefaultAlert("Devour", "Text", nil, 7, 4, encID) -- Phase "4"(really just p3) Reminder to move into Planet
        for _, time in ipairs({54.5, 134.5}) do
            P3Devour.time = time
            self:AddToReminder(P3Devour)            
        end

        local Rings = self:CreateDefaultAlert("Ring", "Text", nil, 5, 4, encID) -- Ring-Spawns
        for _, time in ipairs({74.5, 114.5, 164.5, 194.5}) do
            Rings.time = time
            self:AddToReminder(Rings)            
        end

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

local phasedetections = {3, 3, 3, 3} -- old detection method based on number of events happening

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
        
    end
end