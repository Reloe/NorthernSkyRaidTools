local _, NSI = ... -- Internal namespace

local encID = 3181
-- /run NSAPI:DebugEncounter(3181)

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        id = id or self:DifficultyCheck(14) or 0

        local role = UnitGroupRolesAssigned("player")
        if (role == "HEALER" or not self:IsMelee("player")) and select(3, UnitClass("player")) ~= 3 then
            local Alert = self:CreateDefaultAlert("Stop Cast", "Text", nil, 5, 1, encID)
            local timers = {
                [16] = {9.6, 30.4}
            }
            self:AddRemindersFromTable(Alert, timers[id])
        end

        local Alert = self:CreateDefaultAlert("Arrows", "Text", nil, 5, 1, encID)
        local timers = {
            [16] = {20, 37.5, 56.8, 75.8, 93.5, 119.6}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local timers = {
            [0] = {},
            [16] = {27, 67, 99.5, 126.6},
        }
        local Boom = self:CreateDefaultAlert("Explosion", "Bar", 1233819, 12, 1, encID)
        Boom.TTSTimer = 4
        Boom.Ticks = {6}
        self:AddRemindersFromTable(Boom, timers[id])

        local Boom = self:CreateDefaultAlert("Explosion", "Bar", 1233819, 12, 3, encID)
        Boom.TTSTimer = 4
        Boom.Ticks = {6}
        local timers = {
            [15] = {33, 53, 75, 95, 117, 137, 159, 179, 201, 221},
            [16] = {37, 62, 89, 114},
        }
        self:AddRemindersFromTable(Boom, timers[id])

        local Boom = self:CreateDefaultAlert("Explosion", "Bar", 1233819, 12, 5, encID)
        Boom.TTSTimer = 4
        Boom.Ticks = {6}
        timers = {
            [16] = {54, 114, 174},
        }
        self:AddRemindersFromTable(Boom, timers[id])


        local Alert = self:CreateDefaultAlert("Immune", "Text", nil, 10, 2, encID) -- Arrows
        Alert.time = 25
        Alert.TTS = false
        self:AddToReminder(Alert) -- P2 Immune timer

        local Alert = self:CreateDefaultAlert("Tether", "Text", nil, 6, 5, encID) -- Tether
        timers = {
            [16] = {9.5, 50.5, 69.5, 110.5, 129.5, 170.5},
        }
        self:AddRemindersFromTable(Alert, timers[id])


        if self:IsMelee("player") then return end -- Bait is only for ranged

        local Alert = self:CreateDefaultAlert("Bait", "Text", nil, 5, 1, encID) -- Baits
        local timers = {
            [15] = {15, 63, 102},
            [16] = {13, 53, 85.6, 112.6}
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Bait", "Text", nil, 5, 3, encID) -- Baits
        local timers = {
            [15] = {19, 39, 61, 81, 103, 123, 145, 165, 187, 207},
            [16] = {23, 48, 75, 100, 127},
        }
        self:AddRemindersFromTable(Alert, timers[id])

        local Alert = self:CreateDefaultAlert("Bait", "Text", nil, 5, 5, encID) -- Baits
        timers = {
            [16] = {40, 100, 160},
        }
        self:AddRemindersFromTable(Alert, timers[id])
    end
end

local detectedDurations = {
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
}

local RequiredTimers = {2, 4, false, 4}

local function MythicPhaseDetect(self, e, info)
    local now = GetTime()
    if (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) then return end
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        table.insert(self.RemovedTimelines, now)
    else
        if self.Phase >= 2 or (self.Phase == 1 and (info.duration == 1.5 or info.duration == 25 or info.duration == 6)) then
            table.insert(self.Timelines, now)
        end
    end
    local addedcount = 0
    local removedcount = 0
    for k, v in ipairs(self.Timelines) do
        if now < v+0.3 then
            addedcount = addedcount+1
        end
    end
    if self.Phase == 3 and e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        for k, v in ipairs(self.RemovedTimelines) do
            if now < v+0.3 then
                removedcount = removedcount+1
            end
        end
        if removedcount >= 4 and addedcount < 4 then
            self.Phase = 4
            self:StartReminders(self.Phase)
            self.Timelines = {}
            self.RemovedTimelines = {}
            self.PhaseSwapTime = now
            return
        end
    elseif RequiredTimers[self.Phase] and addedcount >= RequiredTimers[self.Phase] then
        self.Phase = self.Phase+1
        self:StartReminders(self.Phase)
        self.Timelines = {}
        self.RemovedTimelines = {}
        self.PhaseSwapTime = now
        return
    end
    if self.Phase == 3 and (addedcount >= 8 or (e == "ENCOUNTER_TIMELINE_EVENT_ADDED" and info.duration == 60)) then -- fallback if p4 failed
        self.Phase = 5
        self:StartReminders(self.Phase)
        self.Timelines = {}
        self.RemovedTimelines = {}
        self.PhaseSwapTime = now
        return
    end
end

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if difficultyID == 16 then
        MythicPhaseDetect(self, e, info)
        return
    end
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
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
