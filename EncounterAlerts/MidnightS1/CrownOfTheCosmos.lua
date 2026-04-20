local _, NSI = ... -- Internal namespace

local encID = 3181
-- /run NSAPI:DebugEncounter(3181)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local function Add(diffID, name, alertDef)
        NSI:AddEncounterAlert(encID, diffID, name, alertDef)
    end

    local function RangedOnly()
        local lc = NSI.DefaultLoadConditions()
        lc.Roles.RANGED = true
        return lc
    end

    -- Stop Cast: ranged only, phase 1, mythic only
    Add(16, "Stop Cast", NSI:MakeEncounterAlert("Stop Cast", nil, 5, "Text", {
        [1] = { 9.6, 30.4 },
    }, { loadConditions = RangedOnly() }))

    -- Arrows: mythic only, phase 1
    Add(16, "Arrows", NSI:MakeEncounterAlert("Arrows", nil, 5, "Text", {
        [1] = { 20, 37.5, 56.8, 75.8, 93.5, 119.6 },
    }))

    -- Explosion: bar with ticks
    Add(16, "Explosion", NSI:MakeEncounterAlert("Explosion", 1233819, 12, "Bar", {
        [1] = { 27, 67, 99.5, 126.6 },
        [3] = { 37, 62, 89, 114 },
        [5] = { 54, 114, 174 },
    }, { TTSTimer = 4, Ticks = { 6 } }))
    Add(15, "Explosion", NSI:MakeEncounterAlert("Explosion", 1233819, 12, "Bar", {
        [3] = { 33, 53, 75, 95, 117, 137, 159, 179, 201, 221 },
    }, { TTSTimer = 4, Ticks = { 6 } }))

    -- Immune: all difficulties, phase 2
    for _, diff in ipairs({ 14, 15, 16 }) do
        Add(diff, "Immune", NSI:MakeEncounterAlert("Immune", nil, 10, "Text", {
            [2] = { 25 },
        }, { TTS = false }))
    end

    -- Tether: mythic only, phase 5
    Add(16, "Tether", NSI:MakeEncounterAlert("Tether", nil, 6, "Text", {
        [5] = { 9.5, 50.5, 69.5, 110.5, 129.5, 170.5 },
    }))

    -- Bait: ranged only
    Add(15, "Bait", NSI:MakeEncounterAlert("Bait", nil, 5, "Text", {
        [1] = { 15, 63, 102 },
        [3] = { 19, 39, 61, 81, 103, 123, 145, 165, 187, 207 },
    }, { loadConditions = RangedOnly() }))
    Add(16, "Bait", NSI:MakeEncounterAlert("Bait", nil, 5, "Text", {
        [1] = { 13, 53, 85.6, 112.6 },
        [3] = { 23, 48, 75, 100, 127 },
        [5] = { 40, 100, 160 },
    }, { loadConditions = RangedOnly() }))
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)
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
