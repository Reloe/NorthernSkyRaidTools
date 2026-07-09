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

    local data = {group = "Scrollsage Abilities", internalID = "ShreddingShards", name = "Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1295854,
        textColors = {1, 0, 0, 1},
        isConditional = {
            text = "This Alert only shows if you have threat on boss4.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss4") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] = {
                {32},
                {32, 102},
                {32, 102},
                {32, 102}
            },
            [16] = {
                {32},
                {32, 102},
                {32, 102},
                {32, 102}
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Scrollsage Abilities", internalID = "BlinkNova", name = "Blink Nova", text = "Blink Nova", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1296021,
        phaseTimers = {
            [15] = {
                {19, 50},
                {79, 110},
                {79, 110},
                {79, 110},
            },
            [16] = {
                {19, 50},
                {79, 110},
                {79, 110},
                {79, 110},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Scrollsage Abilities", internalID = "FrostfireVolley", name = "Frostfire Volley", text = "Frostfire Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        isConditional = ScrollsageConditional, spellID = 1295891,
        phaseTimers = {
            [15] = {
                {},
                {5, 23, 38},
                {5, 23, 38},
                {5, 23, 38},
            },
            [16] = {
                {},
                {5, 23, 38},
                {5, 23, 38},
                {5, 23, 38},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "First Mate Abilities", internalID = "ShellSpinNormal", name = "Shell Spin Normal", text = "Shells", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1296062,
        phaseTimers = {
            [15] = {
                {22, 38, 53},
                {82, 98, 113},
                {82, 98, 113},
                {82, 98, 113},
            },
            [16] = {
                {32},
                {82, 98, 113},
                {82, 98, 113},
                {82, 98, 113},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "First Mate Abilities", internalID = "ShellSpinScroll", name = "Shell Spin - Scroll Empowered", text = "Shells", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        isConditional = ScrollsageConditional, spellID = 1296062,
        phaseTimers = {
            [15] = {
                {},
                {17, 35, 52},
                {17, 35, 52},
                {17, 35, 52},
            },
            [16] = {
                {},
                {17, 35, 52},
                {17, 35, 52},
                {17, 35, 52},
            }
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "First Mate Abilities", internalID = "ShellSpinTrader", name = "Shell Spin - Trader Empowered", text = "Shells", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        isConditional = TraderConditional, spellID = 1296062,
        phaseTimers = {
            [15] = {
                {},
                {15, 31, 46},
                {15, 31, 46},
                {15, 31, 46},
            },
            [16] = {
                {},
                {15, 31, 46},
                {15, 31, 46},
                {15, 31, 46},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "First Mate Abilities", internalID = "MightyThud", name = "Soaks", text = "Soaks", DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 10,
        isConditional = FirstMateConditional, spellID = 1296133, Ticks = {6, 8},
        phaseTimers = {
            [15] = {
                {},
                {17.6, 37.6, 56.6},
                {17.6, 37.6, 56.6},
                {17.6, 37.6, 56.6},
            },
            [16] = {
                {},
                {17.6, 37.6, 56.6},
                {17.6, 37.6, 56.6},
                {17.6, 37.6, 56.6},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "Fish-Spawn", name = "Fish Spawn", text = "Fish Spawn", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1295817,
        phaseTimers = {
            [15] = {
                {32},
                {92},
                {92},
                {92},
            },
            [16] = {
                {32},
                {92},
                {92},
                {92},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "MushroomBait", name = "Mushroom Bait", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        isConditional = TraderConditional, spellID = 1292105,
        phaseTimers = {
            [15] = {
                {},
                {11, 43},
                {11, 43},
                {11, 43},
            },
            [16] = {
                {},
                {11, 43},
                {11, 43},
                {11, 43},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "ExplosiveSurprise", name = "Bomb Debuff", text = "Bomb inc", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        isConditional = TraderConditional, spellID = 1296249,
        phaseTimers = {
            [15] = {
                {},
                {13, 45},
                {13, 45},
                {13, 45},
            },
            [16] = {
                {},
                {13, 45},
                {13, 45},
                {13, 45},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "MushroomJump", name = "Mushroom Jump", text = "Jump", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        isConditional = TraderConditional, spellID = 1299855,
        phaseTimers = {
            [15] = {
                {},
                {35, 67},
                {35, 67},
                {35, 67},
            },
            [16] = {
                {},
                {35, 67},
                {35, 67},
                {35, 67},
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
                {57},
                {117},
                {117},
                {117},
            },
            [16] = {
                {57},
                {117},
                {117},
                {117},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Trader Abilities", internalID = "TimeToThrowNonConditional", name = "non-conditional Time to throw Fish", text = "Time to Throw", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 7,
        spellID = 1295817, enabled = false,
        phaseTimers = {
            [15] = {
                {57},
                {117},
                {117},
                {117},
            },
            [16] = {
                {57},
                {117},
                {117},
                {117},
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
            local previousActiveBoss = NSAPI.ActiveBoss
            NSAPI.ActiveBoss = unit
            if NSRT.Settings.DebugLogs and previousActiveBoss ~= NSAPI.ActiveBoss then
                print(string.format("|cFF00FFFFNSRT Debug:|r Lost Explorers active boss changed to %s (%s)", UnitName(unit) or "unknown", unit))
            end
            if self.ActiveBossResetTimer then self.ActiveBossResetTimer:Cancel() end
            self.ActiveBossResetTimer = C_Timer.NewTimer(60, function()
                if NSRT.Settings.DebugLogs and NSAPI.ActiveBoss then
                    print("|cFF00FFFFNSRT Debug:|r Lost Explorers active boss cleared")
                end
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
            if ApproximatelyEqual(timelineInfo.duration, 11, 0.2) or ApproximatelyEqual(timelineInfo.duration, 13, 0.2) then
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
