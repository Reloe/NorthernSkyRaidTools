local _, NSI = ... -- Internal namespace

local encID = 3420
-- /run NSAPI:DebugEncounter(3420)

local tankComboTimers = {
    [14] = {5.5, 55.7, 141.7, 195.9, 281.8, 334.1},
    [15] = {5.5, 55.7, 141.7, 195.9, 281.8, 334.1},
    [16] = {4.9, 52, 132, 179, 259, 306.1},
}

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true
    local nontankConditions = self:DefaultLoadConditions()
    nontankConditions.Roles.HEALER = true
    nontankConditions.Roles.DAMAGER = true

    local data = {group = "Sszorak", internalID = "TankCombo", name = "Tank Combo", text = "Tank Combo", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1277002,
        loadConditions = tankConditions,
        textColors = {1, 0, 0, 1},
        timers = tankComboTimers,
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "DamageAmp", name = "Damage Amp", text = "Damage Amp", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1286033,
        timers = {
            [15] = {111.1, 249.3},
            [16] = {100, 227.1, 354.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "Bait", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1305959,
        loadConditions = tankConditions,
        timers = {
            [15] = {32.2, 84.4, 170.4, 222.6, 308.5, 360.8},
            [16] = {28.8, 76.8, 156, 203, 282.2, 330.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "WindDebuffs", text = "Wind-Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1285419,
        timers = {
            [15] = {43.4, 95.5, 181.5, 233.7, 319.7, 371.9},
            [16] = {39.7, 86.7, 166.8, 213.8, 293.9, 340.9},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Sszorak", internalID = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1305963,
        loadConditions = nontankConditions,
        timers = {
            [15] = {37.2, 89.5, 175.4, 227.6, 313.5, 365.8},
            [16] = {32, 79.8, 159, 206.8, 286, 333.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "SerpentsFury", name = "Serpent's Fury", text = "Stack Up", DisplayType = "Text", encID = encID, phase = 1, TTS = "Stack", dur = 6,
        loadConditions = nontankConditions,
        timers = {
            [16] = {25, 74, 153, 202, 281, 330},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    local settings = self.Assignments and self.Assignments[encID]
    if not settings then return end

    local diff = id or self:DifficultyCheck({14, 15, 16})
    if not diff or not tankComboTimers[diff] then return end
    if UnitGroupRolesAssigned("player") == "TANK" then return end

    local group
    if diff == 16 then
        if not settings.Mythic then return end
        group = self:GetSubGroup("player") <= 2 and 1 or 2
    else
        if not settings.NormalHeroic then return end
        local _, first = self:GetSortedGroup(true, false, false)
        group = 2
        for _, member in ipairs(first) do
            if UnitIsUnit(member.unitid, "player") then
                group = 1
                break
            end
        end
    end

    local alert = self:CreateDefaultAlert("", "Text", nil, nil, 1, encID)
    alert.dur = 6
    alert.TTSTimer = 0
    for _, timer in ipairs(tankComboTimers[diff]) do
        alert.time = timer
        alert.text = group == 1 and "|cFF00FF00Soak Left" or "|cFF00FF00Soak Right"
        alert.TTS = group == 1 and "Soak Left" or "Soak Right"
        self:AddToReminder(alert)
    end

    if NSRT.AssignmentSettings.OnPull then
        local side = group == 1 and "Left" or "Right"
        self:DisplayText("You are assigned to soak |cFF00FF00" .. side .. "|r", 5)
    end
end
