local _, NSI = ... -- Internal namespace

local encID = 3183
-- /run NSAPI:DebugEncounter(3183)
NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        id = id or self:DifficultyCheck(14) or 0

        local Alert = self:CreateDefaultAlert("Memory Game", "Text", nil, 8, 1, encID) -- Memory Game
        local timers = {
            [15] = {10, 80, 150}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text = "Glaives"
        timers = {
            [15] = {37.3, 107, 177.3}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text = "Beams"
        timers = {
            [15] = {41, 111.5}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text = "Interrupts"
        timers = {
            [15] = {58, 129}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.phase = 3
        Alert.text = "Soaks"
        timers = {
            [15] = {21, 50.5, 81}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text = "Orbs"
        timers = {
            [15] = {36.5, 66, 96.5}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

        -- Phase start at 329.5
        Alert.phase = 4

        Alert.text = "Crystal"
        timers = {
            [15] = {22, 60, 98}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text = "Soaks"
        timers = {
            [15] = {30.5, 68.5, 106.5}
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end
    end
end

local detectedDurations = {
    [15] = {
        {time = 45, phase = function(num) return 2 end},
        {time = 96, phase = function(num) return 3 end},
        {time = 180, phase = function(num) return 4 end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][1]
    if phaseinfo and info.duration >= phaseinfo.time then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            RiftMadnessTimers()
        end
    end
end