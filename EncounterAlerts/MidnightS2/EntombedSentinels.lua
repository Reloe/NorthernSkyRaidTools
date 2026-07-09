local _, NSI = ... -- Internal namespace

local encID = 3445
-- /run NSAPI:DebugEncounter(3445)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local data = {group = "Sentinels", internalID = "PoisonHits", name = "Poison Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1284458,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] ={
                {6, 28},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
            },
            [16] ={
                {6, 28},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
            }
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Sentinels", internalID = "BloodHits", name = "Blood Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1284487,
        isConditional = {
            text = "This Alert only shows if you have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            },
            [16] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "BloodDropPool", name = "Blood Drop Pool", text = "Drop-Pool", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1284487, isSpecialDisplay = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on Boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return (threat and threat < 2) or not threat end]],
        },
        phaseTimers = {
            [15] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            },
            [16] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "BloodSoak", name = "Blood Soak", text = "Blood-Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        textColors = {1, 0.37, 0.25, 1}, spellID = 1288232,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss2.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss2") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {26.25},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
            },
            [16] ={
                {26.25},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "PoisonAdd", name = "Poison Add", text = "Poison Add", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {0.62, 1, 0.25, 1}, spellID = 1284251,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss1.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss1") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {13.7},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
            },
            [16] ={
                {13.7},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "OrbSpawn", name = "Orb Spawn", text = "Orbs", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        spellID = 1284434,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss1.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss1") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {17.1},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
            },
            [16] ={
                {17.1},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "TransitionDebuffs", name = "Transition Debuffs", text = "Number Game", DisplayType = "Text", encID = encID, phase = 1, TTS = "Spread", dur = 8,
        spellID = 1284590,
        phaseTimers = {
            [15] ={
                {46.2},
                {91},
                {91},
                {91},
                {91},
            },
            [16] ={
                {46.2},
                {91},
                {91},
                {91},
                {91},
            }
        },
    }
    self:AddEncounterAlert(data)
end

local function ScheduleBloodHitThreatCheck(self)
    if self.BloodHitThreatTimer then self.BloodHitThreatTimer:Cancel() end

    local difficultyID = self:DifficultyCheck({15, 16})
    local alert = difficultyID and NSRT.EncounterAlerts[encID][difficultyID] and NSRT.EncounterAlerts[encID][difficultyID].BloodDropPool
    local timers = alert and alert.phaseTimers and alert.phaseTimers[self.Phase or 1]
    local timetocheck = timers and timers[#timers] -- only check last timer
    if not timetocheck then return end

    self.BloodHitThreatTimer = C_Timer.NewTimer(timetocheck, function()
        local threat = UnitThreatSituation("player", "boss2")
        if threat and threat >= 2 then
            self.BloodHitTimer = GetTime()
            self.BloodHitPhase = self.Phase
            if self.BloodHitPoolTimer then self.BloodHitPoolTimer:Cancel() end
            self.BloodHitPoolTimer = C_Timer.NewTimer(40, function()
                if self.EncounterID ~= encID or self.Phase ~= self.BloodHitPhase then return end
                alert = CopyTable(alert)
                alert.phase = self.Phase
                alert.phaseTimers = nil
                alert.isSpecialDisplay = nil
                self:DisplayReminder(alert)
                self.BloodHitTimer = nil
                self.BloodHitPhase = nil
            end)
        else
            self.BloodHitTimer = nil
            self.BloodHitPhase = nil
        end
    end)
end

local function AddBloodHitPoolTimer(self, now)
    if self.BloodHitPoolTimer then
        self.BloodHitPoolTimer:Cancel()
        self.BloodHitPoolTimer = nil
    end
    local bloodHitTimer = self.BloodHitTimer
    self.BloodHitTimer = nil
    self.BloodHitPhase = nil

    local difficultyID = self:DifficultyCheck({15, 16})
    local alert = difficultyID and NSRT.EncounterAlerts[encID][difficultyID] and NSRT.EncounterAlerts[encID][difficultyID].BloodDropPool
    if not alert or not alert.enabled or not self:EvaluateLoad(alert) then return end

    if bloodHitTimer then
        local diff = 40 - (now - bloodHitTimer)
        if diff > 0 then
            alert = CopyTable(alert)
            alert.phase = self.Phase
            alert.time = diff
            alert.phaseTimers = nil
            alert.isSpecialDisplay = nil
            self:AddToReminder(alert) -- add alert for the new phase
        end
    end
end

NSI.EncounterAlertStart[encID] = function(self)
    self.BloodHitTimer = nil
    self.BloodHitPhase = nil
    if self.BloodHitPoolTimer then
        self.BloodHitPoolTimer:Cancel()
        self.BloodHitPoolTimer = nil
    end
    local id = self:DifficultyCheck({15, 16})
    local DropPool = id and NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].BloodDropPool
    if DropPool and DropPool.enabled and self:EvaluateLoad(DropPool) then
        ScheduleBloodHitThreatCheck(self)
    end
end

NSI.EncounterAlertStop[encID] = function(self)
    if self.BloodHitThreatTimer then self.BloodHitThreatTimer:Cancel() end
    if self.BloodHitPoolTimer then self.BloodHitPoolTimer:Cancel() end
    self.BloodHitTimer = nil
    self.BloodHitPhase = nil
    self.BloodHitPoolTimer = nil
end

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end

    table.insert(self.Timelines, now)

    local addedcount = 0
    for _, timestamp in ipairs(self.Timelines) do
        if now < timestamp + 0.3 then addedcount = addedcount + 1 end
    end
    if addedcount >= 8 then
        self.Phase = self.Phase + 1
        AddBloodHitPoolTimer(self, now)
        self:StartReminders(self.Phase)
        ScheduleBloodHitThreatCheck(self)
        self.Timelines = {}
        self.PhaseSwapTime = now
    end
end
