local _, NSI = ... -- Internal namespace

local encID = 3470
-- /run NSAPI:DebugEncounter(3470)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local nonTankConditions = self:DefaultLoadConditions()
    nonTankConditions.Roles.DAMAGER = true
    nonTankConditions.Roles.HEALER = true

    local data = {group = "Nek'zali", internalID = "Barrage", name = "Barrage", text = "Frontal", DisplayType = "Text", encID = encID, phase = {1, 2}, TTS = false, dur = 8,
        textColors = {1, 0, 0, 1}, customIcon = 1284103,
        phaseTimers = {
            [15] ={
                {35.1, 64.2, 116.9, 146, 198.8, 227.9},
                {51.1, 101.1, 151.1, 200.1}
            },
            [16] ={
                {35.1, 64.2, 116.9, 146, 198.8, 227.9},
                {51.1, 101.1, 151.1, 200.1}
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "Debuffs", name = "Essence Rend", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        loadConditions = nonTankConditions, customIcon = 1287434,
        timers = {
            [15] = {18.3, 76.5, 100.1, 158.3, 181.9},
            [16] = {18.3, 76.5, 100.1, 158.3, 181.9},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "SoulcoilIgnition", name = "Soulcoil Ignition", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        loadConditions = nonTankConditions, customIcon = 1293664,
        timers = {
            [15] = {85.5, 167.35, 249.2},
            [16] = {85.5, 167.35, 249.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "RestlessAmani", name = "Add-Spawn", text = "Adds", DisplayType = "Text", encID = encID, phase = {1, 2}, TTS = false, dur = 8, customIcon = 1295397,
        phaseTimers = {
            [15] = {
                {45, 81.6, 118.3, 154.9, 191.5, 228.2},
                {32, 82, 132, 182},
            },
            [16] = {
                {45, 81.6, 118.3, 154.9, 191.5, 228.2},
                {32, 82, 132, 182},
            },
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "Invoke", name = "Invoke", text = "Dodge", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 8, customIcon = 1299673,
        timers = {
            [15] = {17, 45, 67, 95, 117, 145, 167, 195, 217},
            [16] = {17, 45, 67, 95, 117, 145, 167, 195, 217},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    self.NekzaliCastStartTime = nil
    self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED"}, true, "boss1")
    self:EncounterFunction("NekzaliPhaseDetect", function(_, e, unit)
        if self.Phase ~= 1 then return end
        local now = GetTime()
        if e == "UNIT_SPELLCAST_START" then
            self.NekzaliCastStartTime = now
        elseif e == "UNIT_SPELLCAST_SUCCEEDED" and self.NekzaliCastStartTime and ApproximatelyEqual(now - self.NekzaliCastStartTime, 1.5, 0.2) then
            self.NekzaliCastStartTime = nil
            self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED"}, false)
            self.Phase = 1.5
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
        end
    end)
end

local detectedDurations = {
    [14] = { [1.5] = { time = 45, phase = function(num) return 2 end } },
    [15] = { [1.5] = { time = 45, phase = function(num) return 2 end } },
    [16] = { [1.5] = { time = 45, phase = function(num) return 2 end } },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if (not self.PhaseSwapTime) or (not self.EncounterID) or (not self.Phase) then return end

    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not (now > self.PhaseSwapTime + 5)) then return end
    local difficultyID = self:DifficultyCheck({14, 15, 16})
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    if phaseinfo and ApproximatelyEqual(info.duration, phaseinfo.time, 0.2) then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase <= self.Phase then return end
        self.Phase = newphase
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = now
    end
end
