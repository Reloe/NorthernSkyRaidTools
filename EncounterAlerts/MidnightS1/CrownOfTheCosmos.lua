local _, NSI = ... -- Internal namespace

local encID = 3181
-- /run NSAPI:DebugEncounter(3181)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local rangedConditions = self:DefaultLoadConditions()
    rangedConditions.Roles.RANGED = true
    local data = {name = "Stop Cast", text = "Stop Cast", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = nil,
    overrides = {loadConditions = rangedConditions},
    timers = {
            [16] = {9.6, 30.4},
        },
    }
    self:AddEncounterAlert(data)
    data.name, data.text = "Bait", "Bait"
    data.timers = {
        [15] = {{15, 63, 102}, {}, {19, 39, 61, 81, 103, 123, 145, 165, 187, 207}},
        [16] = {{9.6, 30.4}, {}, {23, 48, 75, 100, 127}, {}, {40, 100, 160}},
    },
    self:AddEncounterAlert(data)

    local data = {name = "Arrows", text = "Arrows", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = nil,
    timers = {
            [16] = {20, 37.5, 56.8, 75.8, 93.5, 119.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {name = "Explosion", text = "Explosion", DisplayType = "Bar", encID = encID, phase = 1, TTS = true, TTSTimer = 4, dur = 12, spellID = 1233819,
    overrides = {Ticks = {6}},
    timers = {
            [16] = {{27, 67, 99.5, 126.6}, {}, {37, 62, 89, 114}, {}, {54, 114, 174}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {name = "Boss-Immune", text = "Immune", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 10, spellID = nil,
    timers = {
            [14] = {25},
            [15] = {25},
            [16] = {25},
        },
    }
    self:AddEncounterAlert(data)

    local data = {name = "Tether", text = "Tether", DisplayType = "Text", encID = encID, phase = 5, TTS = false, dur = 6, spellID = nil,
    timers = {
            [16] = {9.5, 50.5, 69.5, 110.5, 129.5, 170.5},
        },
    }
    self:AddEncounterAlert(data)
end

local detectedDurations = {
    [14] = {
        { time = 1.5, phase = function(num) return 2 end },
        { time = 24,  phase = function(num) return 3 end },
        { time = 1.5, phase = function(num) return 4 end },
        { time = 60,  phase = function(num) return 5 end },
    },
    [15] = {
        { time = 1.5, phase = function(num) return 2 end },
        { time = 24,  phase = function(num) return 3 end },
        { time = 1.5, phase = function(num) return 4 end },
        { time = 60,  phase = function(num) return 5 end },
    },
}

local RequiredTimers = { 2, 4, false, 4 }

local function MythicPhaseDetect(self, e, info)
    local now = GetTime()
    if (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) then return end
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        table.insert(self.RemovedTimelines, now)
    else
        if self.Phase >= 2 or (self.Phase == 1 and (info.duration == 1.5 or info.duration == 25 or info.duration == 6)) then
            table.insert(self.Timelines, now)
        end
    end
    local addedcount = 0
    for k, v in ipairs(self.Timelines) do
        if now < v + 0.3 then addedcount = addedcount + 1 end
    end
    if self.Phase ~= 3 and RequiredTimers[self.Phase] and addedcount >= RequiredTimers[self.Phase] then
        self.Phase = self.Phase + 1
        self:StartReminders(self.Phase)
        self.Timelines = {}
        self.RemovedTimelines = {}
        self.PhaseSwapTime = now
        return
    end
    if self.Phase == 3 and (addedcount >= 8 or (e == "ENCOUNTER_TIMELINE_EVENT_ADDED" and info.duration == 60)) then
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
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end
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
