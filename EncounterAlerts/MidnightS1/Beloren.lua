local _, NSI = ... -- Internal namespace

local encID = 3182
-- /run NSAPI:DebugEncounter(3182)

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        id = id or self:DifficultyCheck(14) or 0
        local timer = {
            [15] = 6.6,
            [16] = 6.6,
        }
        for phase=2, 4 do
            local Alert = self:CreateDefaultAlert("Gateway", "Bar", 311699, timer[id], phase, encID)
            Alert.time = 6.6
            self:AddToReminder(Alert)

            local timers = {
                [15] = {12.2, 16.2, 20.2, 24.2, 28.2, 32.2, 36.2},
                [16] = {12.2, 16.2, 20.2, 24.2, 28.2, 32.2, 36.2},
            }
            local Alert = self:CreateDefaultAlert("Next Hit", "Text", 1242792, 4, phase, encID) -- Death Drop
            Alert.TTS = false
            self:AddRemindersFromTable(Alert, timers[id])
        end
    end
end

local detectedDurations = { -- Death Drop
    [14] = {
        {time = 6, phase = function(num) return num+1 end},
    },
    [15] = {
        {time = 6, phase = function(num) return num+1 end},
    },
    [16] = {
        {time = 6, phase = function(num) return num+1 end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if not difficultyID or not detectedDurations[difficultyID] then return end
    table.insert(self.Timelines, now)
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        if info.duration == phaseinfo.time then
            local count = 0
            for i, v in ipairs(self.Timelines) do
                if now < v+0.1 then
                    count = count+1
                end
            end
            local newphase = phaseinfo.phase(self.Phase)
            if newphase > self.Phase and count <= 1 then
                self.Phase = newphase
                self:StartReminders(self.Phase)
                self.PhaseSwapTime = now
                break
            end
        end
    end
end