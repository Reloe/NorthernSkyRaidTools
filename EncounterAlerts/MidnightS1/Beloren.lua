local _, NSI = ... -- Internal namespace

local encID = 3182
-- /run NSAPI:DebugEncounter(3182)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local function Add(diffID, name, alertDef)
        NSI:AddEncounterAlert(encID, diffID, name, alertDef)
    end

    -- Gateway: single-fire bar alert, phases 2 and 3
    for _, diff in ipairs({ 15, 16 }) do
        Add(diff, "Gateway", NSI:MakeEncounterAlert("Gateway", 311699, 6.6, "Bar", {
            [2] = { 6.6 }, [3] = { 6.6 },
        }, { TTSTimer = 4 }))
    end

    -- Next Hit: phases 2 and 3, heroic dur=4, mythic dur=3.5
    Add(15, "Next Hit", NSI:MakeEncounterAlert("Next Hit", 1242792, 4, "Bar", {
        [2] = { 12.2, 16.2, 20.2, 24.2, 28.2, 32.2, 36.2, 40.2 },
        [3] = { 12.2, 16.2, 20.2, 24.2, 28.2, 32.2, 36.2, 40.2 },
    }, { TTS = false }))
    Add(16, "Next Hit", NSI:MakeEncounterAlert("Next Hit", 1242792, 3.5, "Bar", {
        [2] = { 11.7, 15.2, 18.7, 22.2, 25.7, 29.2, 32.7, 36.2, 39.7 },
        [3] = { 11.7, 15.2, 18.7, 22.2, 25.7, 29.2, 32.7, 36.2, 39.7 },
    }, { TTS = false }))

    -- Soaks: mythic only, phases 1 and 2
    Add(16, "Soaks", NSI:MakeEncounterAlert("Soaks", nil, 8, "Text", {
        [1] = { 18.8, 68.8 },
        [2] = { 60.6, 110.6, 160.6 },
    }, { TTS = false }))

    -- Quills: mythic only, phases 1 and 2
    Add(16, "Quills", NSI:MakeEncounterAlert("Quills", nil, 6, "Text", {
        [1] = { 27.4, 37.4, 47.4, 77.4, 87.4, 97.4 },
        [2] = { 69.2, 79.2, 89.2, 119.2, 129.2, 139.2, 169.2 },
    }, { TTS = false }))
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)
end

local detectedDurations = { -- Death Drop
    [14] = { { time = 6, phase = function(num) return num + 1 end } },
    [15] = { { time = 6, phase = function(num) return num + 1 end } },
    [16] = { { time = 6, phase = function(num) return num + 1 end } },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if not difficultyID or not detectedDurations[difficultyID] then return end
    table.insert(self.Timelines, now)
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        if info.duration == phaseinfo.time then
            local count = 0
            for i, v in ipairs(self.Timelines) do
                if now < v + 0.1 then count = count + 1 end
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
