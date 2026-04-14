local _, NSI = ... -- Internal namespace

local encID = 3182
-- /run NSAPI:DebugEncounter(3182)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local enc = NSRT.EncounterAlerts[encID]

    local function Add(key, alert, timers, durOverrides)
        NSI:AddEncounterAlert(encID, key, alert, timers, durOverrides, true, true)
    end

    -- Gateway: single-fire bar alert per phase (fires at 6.6s)
    for _, phase in ipairs({2, 3}) do
        local a = NSI:CreateDefaultAlert("Gateway", "Bar", 311699, 6.6, phase, encID)
        a.TTSTimer = 4
        Add("Gateway"..phase, a, { [15] = {6.6}, [16] = {6.6} })
    end

    -- Next Hit: heroic dur=4, mythic dur=3.5
    for _, phase in ipairs({2, 3}) do
        local a = NSI:CreateDefaultAlert("Next Hit", "Bar", 1242792, 4, phase, encID)
        a.TTS = false
        Add("Next Hit"..phase, a, {
            [15] = {12.2, 16.2, 20.2, 24.2, 28.2, 32.2, 36.2, 40.2},
            [16] = {11.7, 15.2, 18.7, 22.2, 25.7, 29.2, 32.7, 36.2, 39.7},
        }, { [16] = 3.5 })
    end

    -- Soaks (mythic only)
    local soaks1 = NSI:CreateDefaultAlert("Soaks", "Text", nil, 8, 1, encID)
    soaks1.TTS = false
    Add("Soaks1", soaks1, { [16] = {18.8, 68.8} })

    local soaks2 = NSI:CreateDefaultAlert("Soaks", "Text", nil, 8, 2, encID)
    soaks2.TTS = false
    Add("Soaks2", soaks2, { [16] = {60.6, 110.6, 160.6} })

    -- Quills (mythic only)
    local quills1 = NSI:CreateDefaultAlert("Quills", "Text", nil, 6, 1, encID)
    quills1.TTS = false
    Add("Quills1", quills1, { [16] = {27.4, 37.4, 47.4, 77.4, 87.4, 97.4} })

    local quills2 = NSI:CreateDefaultAlert("Quills", "Text", nil, 6, 2, encID)
    quills2.TTS = false
    Add("Quills2", quills2, { [16] = {69.2, 79.2, 89.2, 119.2, 129.2, 139.2, 169.2} })
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)
end

local detectedDurations = { -- Death Drop
    [14] = { {time = 6, phase = function(num) return num+1 end} },
    [15] = { {time = 6, phase = function(num) return num+1 end} },
    [16] = { {time = 6, phase = function(num) return num+1 end} },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if not difficultyID or not detectedDurations[difficultyID] then return end
    table.insert(self.Timelines, now)
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        if info.duration == phaseinfo.time then
            local count = 0
            for i, v in ipairs(self.Timelines) do
                if now < v+0.1 then count = count+1 end
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
