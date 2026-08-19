local _, NSI = ... -- Internal namespace

-- The Coiled Altar (3429)

local encID = 3429
-- /run NSAPI:DebugEncounter(3429)

local p1SoakTimers = {
    [15] = {48, 133},
    [16] = {48, 133},
}

local p3SoakTimers = {
    [15] = {},
    [16] = {},
}

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local nonTankConditions = self:DefaultLoadConditions()
    nonTankConditions.Roles.DAMAGER = true
    nonTankConditions.Roles.HEALER = true

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Coiled Altar P1", internalID = "P1Frontal", name = "P1 Frontal", text = "Frontal", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8,
        textColors = {1, 0, 0, 1}, spellID = 1299684,
        isConditional = {
            text = "This Alert only shows if you are not a tank or have threat on boss1.",
            func = [[return function() if UnitGroupRolesAssigned("player") ~= "TANK" then return true end local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {23, 40.0, 60.0, 77.1, 108.1, 125, 145, 162.1},
            [16] = {23, 40.0, 60.0, 77.1, 108.1, 125, 145, 162.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar Tanks", internalID = "P1Taunt", name = "P1 Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 6, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {23.6, 40.5, 60.5, 77.6, 108.6, 125.5, 145.5, 162.6},
            [16] = {23.6, 40.5, 60.5, 77.6, 108.6, 125.5, 145.5, 162.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P1", internalID = "P1Soak", name = "P1 Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1283489,
        loadConditions = tankConditions,
        timers = {
            [15] = p1SoakTimers[15],
            [16] = p1SoakTimers[16],
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "MindControls", name = "Mind Controls", text = "Mind Controls", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6, spellID = 1285643,
        timers = {
            [15] = {8, 44, 93, 129, 178, 214},
            [16] = {8, 44.6, 93, 129.6, 178, 214.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Frontal", name = "P2 Frontal", text = "Frontal", DisplayType = "Text", encID = encID, phase = 2, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1286620,
        isConditional = {
            text = "This Alert only shows if you are not a tank or have threat on boss2.",
            func = [[return function() if UnitGroupRolesAssigned("player") ~= "TANK" then return true end local threat = UnitThreatSituation("player", "boss2") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {37.7, 68.7, 122.8, 153.8, 207.8, 238.8},
            [16] = {38, 69, 123, 154, 208, 239},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar Tanks", internalID = "P2Taunt", name = "P2 Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 2, TTS = true, TTSTimer = 0, dur = 6, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {38.2, 69.2, 123.3, 154.3, 208.3, 239.3},
            [16] = {38.5, 69.5, 123.5, 154.5, 208.5, 239.5},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Debuffs", name = "P2 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        loadConditions = nonTankConditions, spellID = 1286895,
        timers = {
            [15] = {24, 62, 109, 147, 194, 232},
            [16] = {20, 55, 105, 140, 190, 225},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Shield", name = "P2 Shield", text = "Shield", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        spellID = 1286918,
        timers = {
            [15] = {70, 155},
            [16] = {70, 155},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "InterruptAdds", name = "P2 Interrupt Adds", text = "Ghosts", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        spellID = 1286399,
        timers = {
            [15] = {18, 51, 103, 136, 188, 221},
            [16] = {18, 51, 103, 136, 188, 221},
        },
    }
    self:AddEncounterAlert(data)

    --[=[
    local data = {group = "Coiled Altar P3", internalID = "P3Frontal", name = "P3 Frontal", text = "Frontal", DisplayType = "Text", encID = encID, phase = 3, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1307292,
        isConditional = {
            text = "This Alert only shows if you are not a tank or have threat on boss1.",
            func = [[return function() if UnitGroupRolesAssigned("player") ~= "TANK" then return true end local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Soak", name = "P3 Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 3, TTS = true, dur = 8, spellID = 1299266,
        loadConditions = tankConditions,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Shield", name = "P3 Shield", text = "Shield", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        spellID = 1286918,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Debuffs", name = "P3 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        loadConditions = nonTankConditions, spellID = 1286895,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3InterruptAdds", name = "P3 Interrupt Adds", text = "Ghosts", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        spellID = 1286399,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3MindControls", name = "P3 Mind Controls", text = "Mind Controls", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6, spellID = 1285643,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar Tanks", internalID = "P3Taunt", name = "P3 Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 3, TTS = true, TTSTimer = 0, dur = 6, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)
    ]=]
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    local settings = self.Assignments and self.Assignments[encID]
    if not settings or UnitGroupRolesAssigned("player") == "TANK" then return end

    local diff = id or self:DifficultyCheck({15, 16})
    if not diff or not p1SoakTimers[diff] then return end

    local group
    if diff == 16 then
        if not settings.Mythic then return end
        group = self:GetSubGroup("player") <= 2 and 1 or 2
    else
        if not settings.Heroic then return end
        local _, first = self:GetSortedGroup(true, false, false)
        group = 2
        for _, member in ipairs(first) do
            if UnitIsUnit(member.unitid, "player") then
                group = 1
                break
            end
        end
    end
    for phase, timers in pairs({[1] = p1SoakTimers[diff], [3] = p3SoakTimers[diff]}) do
        if #timers > 0 then
            local alert = self:CreateDefaultAlert("", "Text", nil, nil, phase, encID)
            alert.dur = 8
            for index, timer in ipairs(timers) do
                local shouldSoak = (index == 1 and group == 1) or (index == 2 and group == 2)
                alert.time = timer
                alert.text = shouldSoak and NSI:EncounterAlertLoc("|cFF00FF00SOAK") or NSI:EncounterAlertLoc("|cFFFF0000DON'T SOAK")
                alert.TTS = shouldSoak and NSI:EncounterAlertLoc("Soak") or NSI:EncounterAlertLoc("Don't soak")
                self:AddToReminder(alert)
            end
        end
    end

    if NSRT.AssignmentSettings.OnPull then
        local side = group == 1 and "First" or "Second"
        self:DisplayText(string.format(NSI:EncounterAlertLoc("You are assigned to the |cFF00FF00%s|r Guillotine Soak"), NSI:EncounterAlertLoc(side)), 5)
    end
end

NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    self:EncounterRegister("CoiledAltarPhaseDetect", "UNIT_SPELLCAST_CHANNEL_START", true, "boss2")
    self:EncounterFunction("CoiledAltarPhaseDetect", function(_, e, unit)
        if e ~= "UNIT_SPELLCAST_CHANNEL_START" or self.Phase ~= 2 or self:GetActiveEncounterTimelineEventCount() ~= 0 then return end
        self.Phase = 2.5
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = GetTime()
    end)
end

local detectedDurations = {
    [14] = {
        [1] = { time = 70, phase = function() return 2 end },
    },
    [15] = {
        [1] = { time = 70, phase = function() return 2 end },
    },
    [16] = {
        [1] = { time = 70, phase = function() return 2 end },
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end

    local difficultyID = self:DifficultyCheck({14, 15, 16})
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end

    if self.Phase == 2.5 then
        table.insert(self.Timelines, now)

        local addedcount = 0
        for _, timestamp in ipairs(self.Timelines) do
            if now < timestamp + 0.3 then addedcount = addedcount + 1 end
        end
        if addedcount < 4 then return end

        self.Phase = 3
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = now
        return
    end

    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    if not phaseinfo then return end

    if ApproximatelyEqual(info.duration, phaseinfo.time, 0.2) then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase <= self.Phase then return end
        self.Phase = newphase
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = now
    end
end
