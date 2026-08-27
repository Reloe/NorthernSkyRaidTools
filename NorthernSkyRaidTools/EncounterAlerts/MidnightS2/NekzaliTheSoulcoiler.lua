local _, NSI = ... -- Internal namespace

local encID = 3470
-- /run NSAPI:DebugEncounter(3470)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local nonTankConditions = self:DefaultLoadConditions()
    nonTankConditions.Roles.DAMAGER = true
    nonTankConditions.Roles.HEALER = true

    local data = {group = "Nek'zali", internalID = "Barrage", name = "Barrage", text = "Frontal", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        textColors = {1, 0, 0, 1}, spellID = 1284103,
        phaseTimers = {
            [15] ={
                {34, 70, 105, 141, 176, 212},
                {51, 79},
            },
            [16] ={
                {34, 70, 105, 141, 176, 212},
                {51, 79},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "Debuffs", name = "Essence Rend", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        loadConditions = nonTankConditions, spellID = 1287434,
        phaseTimers = {
            [15] = {
                {14.5, 54.5, 85.5, 125.5},
                {54.6},
            },
            [16] = {
                {14.5, 54.5, 85.5, 125.5},
                {54.6},
            },
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "SoulcoilIgnition", name = "Soulcoil Ignition", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        loadConditions = nonTankConditions, spellID = 1293664,
        timers = {
            [15] = {76.8},
            [16] = {76.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "HungeringPyre", name = "Hungering Pyre", text = "Soak", DisplayType = "Text", encID = encID, phase = 1.5, TTS = true, dur = 7.5, spellID = 1289855,
        phaseTimers = {
            [15] = {
                [1.5] =  {27},
                [1.75] =  {27},
            },
            [16] = {
                [1.5] =  {27},
                [1.75] =  {27},
            },
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "RestlessAmani", name = "Add-Spawn", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1295397,
        phaseTimers = {
            [15] = {
                [1] = {54, 121},
                [1.5] = {56.6},
                [1.75] = {56.6},
                [2] = {35, 75, 115},
            },
            [16] = {
                [1] = {54, 121},
                [1.5] = {56.6},
                [1.75] = {56.6},
                [2] = {35, 75, 115},
            },
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "Invoke", name = "Invoke", text = "Dodge", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 8, spellID = 1299673,
        timers = {
            [15] = {18, 66, 98},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "InvokeMythic", name = "Invoke", text = "Stop Cast", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 8, spellID = 1299673,
        timers = {
            [16] = {18, 66, 98},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    self.NekzaliBoss1SpellcastStartTimes = {}
    self.NekzaliBoss1ValidCastSequence = false
    self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED"}, true, "boss1")
    self:EncounterFunction("NekzaliPhaseDetect", function(_, e, unit)
        local now = GetTime()
        if e == "UNIT_SPELLCAST_START" and self.Phase == 1 then
            self.NekzaliBoss1SpellcastStartTimes[#self.NekzaliBoss1SpellcastStartTimes + 1] = now
            return
        end
        if e == "UNIT_SPELLCAST_SUCCEEDED" then
            for _, startTime in ipairs(self.NekzaliBoss1SpellcastStartTimes) do
                if ApproximatelyEqual(now - startTime, 1.5, 0.2) then
                    self.NekzaliBoss1ValidCastSequence = true
                    break
                end
            end
            return
        end
        local newPhase
        if e == "UNIT_SPELLCAST_CHANNEL_START" then
            if self.Phase == 1 then
                if not self.NekzaliBoss1ValidCastSequence then return end
                newPhase = 1.5
            elseif self.Phase == 1.75 then
                newPhase = 2
            end
        elseif e == "UNIT_SPELLCAST_START" and self.Phase == 1.5 then
            if GetTime() - self.PhaseSwapTime < 25 then return end
            if self:GetActiveEncounterTimelineEventCount() ~= 0 then return end
            newPhase = 1.75
        else
            return
        end
        if not newPhase then return end
        self.Phase = newPhase
        if newPhase == 1.5 then
            self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED"}, false)
            self:EncounterRegister("NekzaliPhaseDetect", "UNIT_SPELLCAST_START", true, "boss2")
        elseif newPhase == 1.75 then
            self:EncounterRegister("NekzaliPhaseDetect", "UNIT_SPELLCAST_START", false)
        end
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = GetTime()
    end)
end
