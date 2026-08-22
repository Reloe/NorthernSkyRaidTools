local _, NSI = ... -- Internal namespace

local encID = 3492
-- /run NSAPI:DebugEncounter(3492)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Ula'tek", internalID = "HitKnock", name = "Mother's Wrath", text = "Hit+Knock", DisplayType = "Text", encID = encID, TTS = "Knock", dur = 5, spellID = 1298367, phase = 1,
        textColors = {1, 0, 0, 1}, loadConditions = tankConditions,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [=[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]=],
        },
        timers = {
            [15] = {14.9, 81.9, 118.9, 377.1, 452.1, 528.1, 617.1, 732.1, 828.1},
            [16] = {14.9, 81.9, 118.9, 377.1, 452.1, 528.1, 617.1, 732.1, 828.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "Waves", name = "Caustic Wave", text = "Waves", DisplayType = "Text", encID = encID, TTS = "Waves", dur = 5, spellID = 1292403, phase = 1,
        timers = {
            [15] = {48, 100, 416.7, 471.7, 521.7, 566.7},
            [16] = {48, 100, 416.7, 471.7, 521.7, 566.7},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "DamageAmpIn", name = "Venomous Heart", text = "Dmg amp in", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1286860, phase = 1,
        timers = {
            [15] = {135.4, 284.5, 573.7},
            [16] = {135.4, 284.5, 573.7},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "DamageAmp", name = "Venomous Heart", text = "Dmg amp", DisplayType = "Bar", encID = encID, TTS = false, dur = 20, spellID = 1299526, phase = 1,
        barColors = {1, 0, 0, 1},
        timers = {
            [15] = {155.4, 304.5, 593.7},
            [16] = {155.4, 304.5, 593.7},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "PlatformBreak", name = "Circling Prey", text = "Platform Break", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1315341, phase = 1,
        timers = {
            [15] = {430.1, 481.2, 542.1},
            [16] = {430.1, 481.2, 542.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "Debuffs", name = "Serpent's Bite", text = "Debuffs", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1288879, phase = 1,
        timers = {
            [15] = {392.7, 463.7, 500.6, 555.7},
            [16] = {392.7, 463.7, 500.6, 555.7},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "Eggs", name = "Eggs", text = "Eggs", DisplayType = "Text", encID = encID, TTS = false, dur = 6, spellID = 1304012, phase = 1,
        timers = {
            [15] = {82, 319},
            [16] = {82, 319},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "Adds", name = "P3 Adds", text = "Adds", DisplayType = "Text", encID = encID, TTS = true, dur = 5, spellID = 1300751,  phase = 1,
        timers = {
            [15] = {373.2, 403.1, 448.1, 508.2},
            [16] = {373.2, 403.1, 448.1, 508.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "Sweep", name = "Sweep", text = "Sweep", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1296301, phase = 1,
        timers = {
            [15] = {38.9, 90.9},
            [16] = {38.9, 90.9},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "Soak", name = "Soak", text = "Soak", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1299010, phase = 1,
        timers = {
            [15] = {27.4, 30.3, 128.7, 131.5},
            [16] = {27.4, 30.3, 128.7, 131.5},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "TransitionSoakFirst", name = "First Soak", text = "First Soak", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1299010, phase = 1,
        textColors = {0, 1, 0, 1},
        timers = {
            [15] = {326.3, 334.5, 341.4},
            [16] = {326.3, 334.5, 341.4},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "TransitionSoakSecond", name = "Second Soak", text = "Second Soak", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1299010, phase = 1,
        textColors = {1, 0, 0, 1},
        timers = {
            [15] = {329.6, 337.3, 344.6},
            [16] = {329.6, 337.3, 344.6},
        },
    }
    self:AddEncounterAlert(data)

    local UlatekGraspingFangsPreview = [[return function(NSI) print(NSI:Loc("|cFF00FFFFNSRT:|r no preview available for this Alert. It uses the Debuff Overview anchor from the Reminder settings.")) end]]
    local data = {group = "Ula'tek", internalID = "GraspingFangsOverview", name = "Grasping Fangs Overview", text = nil, DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 40,
        spellID = 1311611, id = 0.2, difficulties = {15, 16}, enabled = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, Preview = UlatekGraspingFangsPreview, enabled = false,
        timers = {
            [15] = {189},
            [16] = {189},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id)
    id = id or self:DifficultyCheck({15, 16})
    local alert = id and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].GraspingFangsOverview
    if not alert or not alert.enabled or not self:EvaluateLoad(alert) then return end

    if self.UlatekGraspingFangsTimers then
        for _, timer in ipairs(self.UlatekGraspingFangsTimers) do timer:Cancel() end
        self.UlatekGraspingFangsTimers = nil
    end

    self:CreateDebuffOverviewContainers("HARMFUL|!PLAYER", {isBossOrRoleAura = true}, 1, 1, "UlatekGraspingFangsOverview")
    self.UlatekGraspingFangsTimers = {}
    for _, applyTime in ipairs(alert.timers or {}) do
        self.UlatekGraspingFangsTimers[#self.UlatekGraspingFangsTimers + 1] = C_Timer.NewTimer(applyTime, function()
            if self.EncounterID == encID then self:SetDebuffOverviewContainersShown(true, "UlatekGraspingFangsOverview") end
        end)
        self.UlatekGraspingFangsTimers[#self.UlatekGraspingFangsTimers + 1] = C_Timer.NewTimer(applyTime + (alert.dur or 40), function()
            if self.EncounterID == encID then self:SetDebuffOverviewContainersShown(false, "UlatekGraspingFangsOverview") end
        end)
    end
end

NSI.EncounterAlertStop[encID] = function(self)
    if self.UlatekGraspingFangsTimers then
        for _, timer in ipairs(self.UlatekGraspingFangsTimers) do timer:Cancel() end
        self.UlatekGraspingFangsTimers = nil
    end
    self:SetDebuffOverviewContainersShown(false, "UlatekGraspingFangsOverview")
end
