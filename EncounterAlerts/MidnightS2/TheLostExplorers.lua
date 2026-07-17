local _, NSI = ... -- Internal namespace

local encID = 3497
-- /run NSAPI:DebugEncounter(3497)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local TraderConditional = {
        text = "This Alert only shows if Trader Gebbo was empowered",
        func = [[return function() return NSAPI and NSAPI.ActiveBoss and NSAPI.ActiveBoss == "boss1" end]]
    }
    local FirstMateConditional = {
        text = "This Alert only shows if First Mate Nama was empowered",
        func = [[return function() return NSAPI and NSAPI.ActiveBoss and NSAPI.ActiveBoss == "boss3" end]]
    }
    local ScrollsageConditional = {
        text = "This Alert only shows if Scrollsage Iku was empowered",
        func = [[return function() return NSAPI and NSAPI.ActiveBoss and NSAPI.ActiveBoss == "boss4" end]]
    }
    local meleeNonTankConditions = self:DefaultLoadConditions()
    meleeNonTankConditions.SpecIDs = {
        [263] = true, -- Shaman: Enhancement
        [255] = true, -- Hunter: Survival
        [259] = true, -- Rogue: Assassination
        [260] = true, -- Rogue: Outlaw
        [261] = true, -- Rogue: Subtlety
        [103] = true, -- Druid: Feral
        [71] = true, -- Warrior: Arms
        [72] = true, -- Warrior: Fury
        [251] = true, -- Death Knight: Frost
        [252] = true, -- Death Knight: Unholy
        [577] = true, -- Demon Hunter: Havoc
        [70] = true, -- Paladin: Retribution
        [65] = true, -- Paladin: Holy
        [269] = true, -- Monk: Windwalker
        [270] = true, -- Monk: Mistweaver
    }
    local rangedConditions = self:DefaultLoadConditions()
    rangedConditions.Roles.RANGED = true

    local data = {group = "Scrollsage Abilities", internalID = "ShreddingShards", name = "Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1295854,
        textColors = {1, 0, 0, 1},
        isConditional = {
            text = "This Alert only shows if you have threat on boss4.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss4") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] = {
                {30},
                {30.5, 90.5},
                {30.5, 90.5},
                {30.5, 90.5},
            },
            [16] = {
                {30},
                {30.5, 90.5},
                {30.5, 90.5},
                {30.5, 90.5},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Scrollsage Abilities", internalID = "BlinkNova", name = "Blink Nova", text = "Blink Nova", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 9,
        spellID = 1296021,
        phaseTimers = {
            [15] = {
                {17, 48},
                {77, 108},
                {77, 108},
                {77, 108},
            },
            [16] = {
                {17, 48},
                {77, 108},
                {77, 108},
                {77, 108},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Scrollsage Abilities", internalID = "FrostfireVolley", name = "Frostfire Volley", text = "Frostfire Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        isConditional = ScrollsageConditional, spellID = 1295891,
        phaseTimers = {
            [15] = {
                {},
                {8, 35},
                {8, 35},
                {8, 35},
            },
            [16] = {
                {},
                {8, 35},
                {8, 35},
                {8, 35},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "First Mate Abilities", internalID = "ShellSpinNormal", name = "Shell Spin Normal", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        spellID = 1296062,
        loadConditions = meleeNonTankConditions,
        phaseTimers = {
            [15] = {
                {18, 34, 49},
                {78, 94, 109},
                {78, 94, 109},
                {78, 94, 109},
            },
            [16] = {
                {18, 34, 49},
                {78, 94, 109},
                {78, 94, 109},
                {78, 94, 109},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "First Mate Abilities", internalID = "ShellSpinScroll", name = "Shell Spin - Scroll Empowered", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        isConditional = ScrollsageConditional, spellID = 1296062,
        loadConditions = meleeNonTankConditions,
        phaseTimers = {
            [15] = {
                {},
                {17, 44},
                {17, 44},
                {17, 44},
            },
            [16] = {
                {},
                {17, 44},
                {17, 44},
                {17, 44},
            }
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "First Mate Abilities", internalID = "ShellSpinTrader", name = "Shell Spin - Trader Empowered", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        isConditional = TraderConditional, spellID = 1296062,
        loadConditions = meleeNonTankConditions,
        phaseTimers = {
            [15] = {
                {},
                {7, 39},
                {7, 39},
                {7, 39},
            },
            [16] = {
                {},
                {7, 39},
                {7, 39},
                {7, 39},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "First Mate Abilities", internalID = "MightyThud", name = "Soaks", text = "Soaks", DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 15.5,
        isConditional = FirstMateConditional, spellID = 1296133, Ticks = {11.5, 13.5},
        phaseTimers = {
            [15] = {
                {},
                {17.6, 47.6},
                {17.6, 47.6},
                {17.6, 47.6},
            },
            [16] = {
                {},
                {17.6, 47.6},
                {17.6, 47.6},
                {17.6, 47.6},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "Fish-Spawn", name = "Fish Spawn", text = "Fish Spawn", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1295817,
        phaseTimers = {
            [15] = {
                {34},
                {94},
                {94},
                {94},
            },
            [16] = {
                {34},
                {94},
                {94},
                {94},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "MushroomBait", name = "Mushroom Bait", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 7,
        isConditional = TraderConditional, spellID = 1292105,
        loadConditions = rangedConditions,
        phaseTimers = {
            [15] = {
                {},
                {10, 42},
                {10, 42},
                {10, 42},
            },
            [16] = {
                {},
                {10, 42},
                {10, 42},
                {10, 42},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "ExplosiveSurprise", name = "Bomb Debuff", text = "Bomb inc", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        isConditional = TraderConditional, spellID = 1296249,
        phaseTimers = {
            [15] = {
                {},
                {13, 45.5},
                {13, 45.5},
                {13, 45.5},
            },
            [16] = {
                {},
                {13, 45.5},
                {13, 45.5},
                {13, 45.5},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "MushroomJump", name = "Mushroom Jump", text = "Jump", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        isConditional = TraderConditional, spellID = 1299855,
        phaseTimers = {
            [15] = {
                {},
                {36, 67},
                {36, 67},
                {36, 67},
            },
            [16] = {
                {},
                {36, 67},
                {36, 67},
                {36, 67},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "TimeToThrow", name = "Time to throw Fish", text = "Time to Throw", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 7,
        spellID = 1295817,
        isConditional = {
            text = "This Alert only shows if you are holding the fish at the time.",
            func = [[return function() return C_ActionBar.HasExtraActionBar() end]],
        },
        phaseTimers = {
            [15] = {
                {61},
                {121},
                {121},
            },
            [16] = {
                {61},
                {121},
                {121},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "TimeToThrowNonConditional", name = "non-conditional Time to throw Fish", text = "Time to Throw", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 7,
        spellID = 1295817, enabled = false,
        phaseTimers = {
            [15] = {
                {61},
                {121},
                {121},
            },
            [16] = {
                {61},
                {121},
                {121},
            }
        },
    }
    self:AddEncounterAlert(data)
end


NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    NSAPI.ActiveBoss = nil
    self.ActiveBossResetTimer = nil
    self:EncounterRegister("ExplorersBossDetect", "UNIT_FACTION", true, {"boss1", "boss3", "boss4"}) -- boss2 is the empower casting boss
    self:EncounterFunction("ExplorersBossDetect", function(_, e, unit)
        if not UnitIsEnemy("player", unit) then
            NSAPI.ActiveBoss = unit
            if self.ActiveBossResetTimer then self.ActiveBossResetTimer:Cancel() end
            self.ActiveBossResetTimer = C_Timer.NewTimer(80, function()
                NSAPI.ActiveBoss = nil
            end)
        end
    end)
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if self.ActiveBossResetTimer then self.ActiveBossResetTimer:Cancel() end
    NSAPI.ActiveBoss = nil
end

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    local requiredDiff = self.Phase == 1 and 30 or 90
    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + requiredDiff)) or (not self.EncounterID) or (not self.Phase) then return end

    table.insert(self.Timelines, {timestamp = now, duration = info.duration})

    local addedcount = 0
    local hasRequiredDuration = false
    for _, timelineInfo in ipairs(self.Timelines) do
        if now < timelineInfo.timestamp + 0.3 then
            addedcount = addedcount + 1
            if ApproximatelyEqual(timelineInfo.duration, 17, 0.2) or ApproximatelyEqual(timelineInfo.duration, 11, 0.2) or ApproximatelyEqual(timelineInfo.duration, 13, 0.2) then
                hasRequiredDuration = true
            end
        end
    end
    if addedcount >= 4 and hasRequiredDuration then
        self.Phase = self.Phase + 1
        self:StartReminders(self.Phase)
        self.Timelines = {}
        self.PhaseSwapTime = now
    end
end
