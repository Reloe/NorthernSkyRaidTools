local _, NSI = ... -- Internal namespace

local encID = 3182
-- /run NSAPI:DebugEncounter(3182)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local data = {internalID = "Gateway", text = "Gateway", DisplayType = "Bar", encID = encID, phase = 1, TTS = true, TTSTimer = 4, dur = 6.6, spellID = 311699,
    timers = {
            [15] = {{}, {6.6}, {6.6}},
            [16] = {{}, {6.6}, {6.6}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {internalID = "Next Hit", text = "Next Hit", DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 4, spellID = 1242792,
    timers = {
            [16] = {{}, {11.7, 15.2, 18.7, 22.2, 25.7, 29.2, 32.7, 36.2, 39.7, 43.2, 46.7, 50.2}, {11.7, 15.2, 18.7, 22.2, 25.7, 29.2, 32.7, 36.2, 39.7, 43.2, 46.7, 50.2}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {internalID = "Soaks", text = "Soaks", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = nil,
    timers = {
            [16] = {{18.8, 68.8}, {70.6, 120.6, 170.6}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {internalID = "Quills", text = "Quills", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = nil,
    timers = {
            [16] = {{27.4, 37.4, 47.4, 77.4, 87.4, 97.4}, {79.2, 89.2, 99.2, 129.2, 139.2, 149.2, 179.2}},
        },
    }
    self:AddEncounterAlert(data)
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
    if self.Phase >= 2 and ApproximatelyEqual(info.duration, 40, 0.2) then
        local diff = now - self.PhaseSwapTime
        local offset = diff - 7.1
        if diff <= 20 and offset > 0.3 then -- bird has delayed his landing so we extend all timers
            self:DelayAllReminders(offset)
        end
    end
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
