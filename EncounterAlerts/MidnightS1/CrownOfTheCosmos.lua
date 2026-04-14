local _, NSI = ... -- Internal namespace

local encID = 3181
-- /run NSAPI:DebugEncounter(3181)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local enc = NSRT.EncounterAlerts[encID]

    local function Add(key, alert, timers, durOverrides)
        NSI:AddEncounterAlert(encID, key, alert, timers, durOverrides, true, true)
    end

    -- Stop Cast: healers and ranged (role check handled at display time)
    local stopCast1 = NSI:CreateDefaultAlert("Stop Cast", "Text", nil, 5, 1, encID)
    stopCast1.role = "RANGED"
    Add("Stop Cast1", stopCast1, { [16] = {9.6, 30.4} })

    Add("Arrows1", NSI:CreateDefaultAlert("Arrows", "Text", nil, 5, 1, encID), {
        [16] = {20, 37.5, 56.8, 75.8, 93.5, 119.6},
    })

    local explosion1 = NSI:CreateDefaultAlert("Explosion", "Bar", 1233819, 12, 1, encID)
    explosion1.TTSTimer, explosion1.Ticks = 4, {6}
    Add("Explosion1", explosion1, { [0] = {}, [16] = {27, 67, 99.5, 126.6} })

    local explosion3 = NSI:CreateDefaultAlert("Explosion", "Bar", 1233819, 12, 3, encID)
    explosion3.TTSTimer, explosion3.Ticks = 4, {6}
    Add("Explosion3", explosion3, {
        [15] = {33, 53, 75, 95, 117, 137, 159, 179, 201, 221},
        [16] = {37, 62, 89, 114},
    })

    local explosion5 = NSI:CreateDefaultAlert("Explosion", "Bar", 1233819, 12, 5, encID)
    explosion5.TTSTimer, explosion5.Ticks = 4, {6}
    Add("Explosion5", explosion5, { [16] = {54, 114, 174} })

    local immune2 = NSI:CreateDefaultAlert("Immune", "Text", nil, 10, 2, encID)
    immune2.TTS = false
    -- fires on all difficulties; store a timer per diffID covering 14/15/16
    Add("Immune2", immune2, { [14] = {25}, [15] = {25}, [16] = {25} })

    Add("Tether5", NSI:CreateDefaultAlert("Tether", "Text", nil, 6, 5, encID), {
        [16] = {9.5, 50.5, 69.5, 110.5, 129.5, 170.5},
    })

    -- Bait: ranged only (role check handled at display time)
    local bait1 = NSI:CreateDefaultAlert("Bait", "Text", nil, 5, 1, encID)
    bait1.role = "RANGED"
    Add("Bait1", bait1, {
        [15] = {15, 63, 102},
        [16] = {13, 53, 85.6, 112.6},
    })

    local bait3 = NSI:CreateDefaultAlert("Bait", "Text", nil, 5, 3, encID)
    bait3.role = "RANGED"
    Add("Bait3", bait3, {
        [15] = {19, 39, 61, 81, 103, 123, 145, 165, 187, 207},
        [16] = {23, 48, 75, 100, 127},
    })

    local bait5 = NSI:CreateDefaultAlert("Bait", "Text", nil, 5, 5, encID)
    bait5.role = "RANGED"
    Add("Bait5", bait5, { [16] = {40, 100, 160} })
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)
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
    for k, v in ipairs(self.Timelines) do
        if now < v+0.3 then addedcount = addedcount+1 end
    end
    if self.Phase ~= 3 and RequiredTimers[self.Phase] and addedcount >= RequiredTimers[self.Phase] then
        self.Phase = self.Phase+1
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
