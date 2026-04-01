local _, NSI = ... -- Internal namespace

local encID = 3183
-- /run NSAPI:DebugEncounter(3183)
NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        id = id or self:DifficultyCheck(14) or 0

        local Alert = self:CreateDefaultAlert("Memory Game", "Text", nil, 5, 1, encID)
        local timers = {
            [15] = {10, 80, 150}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Glaives", "Text", nil, 5, 1, encID)
        timers = {
            [15] = {37.3, 107, 177.3}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Interrupts", "Text", nil, 5, 1, encID)
        timers = {
            [15] = {58, 129}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Soaks", "Text", nil, 5, 3, encID)
        Alert.TTS = false
        timers = {
            [15] = {21, 50.5, 81}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Orbs", "Text", nil, 5, 3, encID)
        timers = {
            [15] = {36.5, 66, 96.5}
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
            [15] = {30.5, 68.5, 106.5}
        }
        self:AddRemindersFromTable(Alert, timers[id])
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
        end
    end
end