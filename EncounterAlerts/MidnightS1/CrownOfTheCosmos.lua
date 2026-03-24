local _, NSI = ... -- Internal namespace

local encID = 3181
-- /run NSAPI:DebugEncounter(3181)

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        id = id or self:DifficultyCheck(14) or 0
        local ExplosionTimers = {
            [15] = {33, 53, 75, 95, 117, 137, 159, 179, 201, 221}
        }
        local Explosion = self:CreateDefaultAlert("Explosion", "Bar", 1233819, 5, 3, encID) -- Void Expulsion Dmg Event
        for i, v in ipairs(ExplosionTimers[id] or {}) do
            Explosion.time = v
            self:AddToReminder(Explosion)
        end

        if self:IsMelee("player") then return end -- Bait is only for ranged

        local Alert = self:CreateDefaultAlert("Bait", "Text", nil, 5, 1, encID) -- Void Expulsion Bait
        local timers = {
            [15] = {15, 63, 102}, -- don't care about normal, adding mythic later
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end
        Alert.phase = 3
        timers = {
            [15] = {19, 39, 61, 81, 103, 123, 145, 165, 187, 207}, -- don't care about normal, adding mythic later
        }
        for i, v in ipairs(timers[id] or {}) do
            Alert.time = v
            self:AddToReminder(Alert)
        end
    end
end

local detectedDurations = { -- Devour = ~120.9
    [14] = {
        {time = 1.5, phase = function(num) return 2 end},
        {time = 24, phase = function(num) return 3 end},
        {time = 1.5, phase = function(num) return 4 end},
        {time = 60, phase = function(num) return 5 end},
    },
    [15] = {
        {time = 1.5, phase = function(num) return 2 end},
        {time = 24, phase = function(num) return 3 end},
        {time = 1.5, phase = function(num) return 4 end},
        {time = 60, phase = function(num) return 5 end},
    },
    [16] = {
        {time = 1.5, phase = function(num) return 2 end},
        {time = 24, phase = function(num) return 3 end},
        {time = 1.5, phase = function(num) return 4 end},
        {time = 60, phase = function(num) return 5 end},
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    if phaseinfo and info.duration == phaseinfo.time then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
        end
    end
end