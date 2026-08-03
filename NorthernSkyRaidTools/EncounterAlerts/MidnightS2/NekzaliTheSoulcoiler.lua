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
                {35.1, 64.2, 116.9, 146, 198.8, 227.9},
                {56.1, 106.1, 156.1, 205.1}
            },
            [16] ={
                {34, 70},
                {50, 78}
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "Debuffs", name = "Essence Rend", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        loadConditions = nonTankConditions, spellID = 1287434,
        phaseTimers = {
            [15] = {
                {18.3, 76.5, 100.1, 158.3, 181.9},
            },
            [16] = {
                {20, 60.5, 91},
                {54},
            },
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "SoulcoilIgnition", name = "Soulcoil Ignition", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        loadConditions = nonTankConditions, spellID = 1293664,
        timers = {
            [15] = {85.5, 167.35, 249.2},
            [16] = {75.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "HungeringPyre", name = "Hungering Pyre", text = "Soak", DisplayType = "Text", encID = encID, phase = 1.5, TTS = true, dur = 7.5, spellID = 1289855,
        timers = {
            [15] = {58.7, 102.7},
            [16] = {41, 72},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "RestlessAmani", name = "Add-Spawn", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1295397,
        phaseTimers = {
            [15] = {
                [1] = {43, 113},
                [1.5] = {38, 68},
                [2] = {23, 63},
            },
            [16] = {
                [1] = {43, 113},
                [1.5] = {38, 68},
                [2] = {28, 68},
            },
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "Invoke", name = "Invoke", text = "Dodge", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 8, spellID = 1299673,
        timers = {
            [15] = {22, 50, 72, 100, 122, 150, 172, 200, 222},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Nek'zali", internalID = "InvokeMythic", name = "Invoke", text = "Stop Cast", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 8, spellID = 1299673,
        timers = {
            [16] = {15, 65, 95},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    self.NekzaliBoss1SpellcastSucceededTimes = {}
    self:EncounterRegister("NekzaliPhaseDetect", {"UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_SUCCEEDED"}, true, "boss1")
    self:EncounterFunction("NekzaliPhaseDetect", function(_, e, unit)
        local now = GetTime()
        if e == "UNIT_SPELLCAST_SUCCEEDED" then
            table.insert(self.NekzaliBoss1SpellcastSucceededTimes, now)
            for i = #self.NekzaliBoss1SpellcastSucceededTimes, 1, -1 do
                if now - self.NekzaliBoss1SpellcastSucceededTimes[i] > 2 then
                    table.remove(self.NekzaliBoss1SpellcastSucceededTimes, i)
                end
            end
            return
        end
        if e ~= "UNIT_SPELLCAST_CHANNEL_START" or self:GetActiveEncounterTimelineEventCount() ~= 0 then return end
        local newPhase
        if self.Phase == 1 then
            local hasSucceededInWindow = false
            for _, timestamp in ipairs(self.NekzaliBoss1SpellcastSucceededTimes) do
                local timeSinceSucceeded = now - timestamp
                if timeSinceSucceeded >= 0.2 and timeSinceSucceeded <= 2 then
                    hasSucceededInWindow = true
                    break
                end
            end
            if not hasSucceededInWindow then return end
            newPhase = 1.5
        elseif self.Phase == 1.5 then
            newPhase = 2
        end
        if not newPhase then return end
        self.Phase = newPhase
        if newPhase == 1.5 then
            self:EncounterRegister("NekzaliPhaseDetect", "UNIT_SPELLCAST_SUCCEEDED", false)
        end
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = GetTime()
    end)
end
