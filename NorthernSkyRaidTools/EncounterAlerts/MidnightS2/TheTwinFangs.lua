local _, NSI = ... -- Internal namespace

local encID = 3421
-- /run NSAPI:DebugEncounter(3421)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local nonTankConditions = self:DefaultLoadConditions()
    nonTankConditions.Roles.DAMAGER = true
    nonTankConditions.Roles.HEALER = true

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local meleeConditions = self:DefaultLoadConditions()
    meleeConditions.Roles.MELEE = true

    local DebuffOverviewPreview = [[
        return function(self)
            local alert = NSRT.EncounterAlerts[3421][16].DebuffOverview
            local overviewSettings = NSRT.ReminderSettings.DebuffOverviewSettings
            self:PreviewDebuffOverviewContainers("HARMFUL", {isFromPlayerOrPlayerPet = false, isBossOrRoleAura = false}, 1, 1, "TwinFangsDebuffOverview", false, false, true, 9, 20, {
                barColors = alert.BarColor or overviewSettings.barColors,
                backgroundColors = overviewSettings.backgroundColors,
                height = alert.BarHeight or overviewSettings.Height,
            }, true)
        end
    ]]

    local debuffOverviewOptions = {
        {Type = "Color", label = "Bar Color",
            get = [[return function() local a = NSRT.EncounterAlerts[3421][16].DebuffOverview local c = a.BarColor or NSRT.ReminderSettings.DebuffOverviewSettings.barColors return c[1], c[2], c[3], c[4] end]],
            set = [[return function(NSI, r, g, b, a) for i = 14, 16 do NSRT.EncounterAlerts[3421][i].DebuffOverview.BarColor = {r, g, b, a} end NSI:CreateDebuffOverviewContainers("HARMFUL", {isFromPlayerOrPlayerPet = false, isBossOrRoleAura = false}, 1, 1, "TwinFangsDebuffOverview", false, false, true, 9, {barColors = {r, g, b, a}}, true) end]],},
        {Type = "Slider", label = "Bar Height", min = 10, max = 100, step = 1,
            get = [[return function() local a = NSRT.EncounterAlerts[3421][16].DebuffOverview return a.BarHeight or NSRT.ReminderSettings.DebuffOverviewSettings.Height end]],
            set = [[return function(NSI, value) for i = 14, 16 do NSRT.EncounterAlerts[3421][i].DebuffOverview.BarHeight = value end NSI:CreateDebuffOverviewContainers("HARMFUL", {isFromPlayerOrPlayerPet = false, isBossOrRoleAura = false}, 1, 1, "TwinFangsDebuffOverview", false, false, true, 9, {height = value}, true) end]],},
    }

    local data = {group = "Twin Fangs", internalID = "DebuffOverview", name = "Eternal Venom Overview", text = "Eternal Venom Overview", DisplayType = "Bar", encID = encID,
        phase = 1, TTS = false, dur = 5, spellID = nil, difficulties = {14, 15, 16}, enabled = false, isSpecialDisplay = true, BlockCopy = true, NoEdit = true,
        Preview = DebuffOverviewPreview, id = 0.3, BarHeight = 25, extraOptions = debuffOverviewOptions,
    }
    self:AddEncounterAlert(data)

    local soakTimers = {
        [15] = {71.4, 139.1, 240.8, 308.6, 410.3, 478.1},
        [16] = {64.7, 125.7, 219.8, 280.8, 374.9, 435.9},
    }
    local soak1Timers = {}
    local soak2Timers = {}
    local soak3Timers = {}
    -- Align each new eight-second alert's expiration with the existing soak bar's ticks.
    for difficulty, timers in pairs(soakTimers) do
        soak1Timers[difficulty] = {}
        soak2Timers[difficulty] = {}
        soak3Timers[difficulty] = {}
        for index, time in ipairs(timers) do
            soak1Timers[difficulty][index] = time - 3.5
            soak2Timers[difficulty][index] = time - 1.5
            soak3Timers[difficulty][index] = time
        end
    end

    local data = {group = "Twin Fangs", internalID = "Defensives", text = "Defensives", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        loadConditions = nonTankConditions, spellID = 1290956,
        timers = {
            [15] = {52.3, 120, 221.7, 289.5, 391.2, 458.9},
            [16] = {46.9, 107.9, 202, 263.1, 357.1, 418},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Soak", text = "Soak", DisplayType = "Bar", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1290516,
    Ticks = {4.5, 6.5}, barColors = {1, 0, 0, 1},
        timers = soakTimers,
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Soak1", name = "Soak 1", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1290516,
        enabled = false, timers = {[16] = soak1Timers[16]},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Soak2", name = "Soak 2", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1290516,
        enabled = false, timers = {[16] = soak2Timers[16]},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Soak3", name = "Soak 3", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1290516,
        enabled = false, timers = {[16] = soak3Timers[16]},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "PreSpread", name = "Pre-Spread", text = "Pre-Spread", DisplayType = "Circle", encID = encID, phase = 1, TTS = "Spread", dur = 6,
        loadConditions = nonTankConditions, spellID = 1290809,
        timers = {
            [15] = {48.5, 116.2, 218, 285.7, 387.4, 455.1},
            [16] = {43.8, 104.8, 198.7, 259.6, 353.7, 414.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "WatchSide", name = "Watch Side", text = "Watch Side", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1294293,
        timers = {
            [15] = {150.5, 319.9},
            [16] = {136, 290.9},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1291404,
        timers = {
            [15] = {39.7, 107.5, 209.2, 276.9, 378.6, 446.4},
            [16] = {35, 96, 190, 251, 345, 406},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Orbs", text = "Orbs", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1289994,
        timers = {
            [15] = {12.9, 80.7, 182.4, 250.2, 351.8, 419.6},
            [16] = {11.9, 72.9, 166.7, 227.7, 321.6, 382.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "TankSoak", name = "Tank Soak", text = "Soak", DisplayType = "Bar", encID = encID, phase = 1, TTS = true, TTSTimer = 12, dur = 12, spellID = 1288538,
        loadConditions = tankConditions,
        Ticks = {6, 9},
        isConditional = {
            text = "This Alert only shows if you have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {32.5, 100.3, 202, 269.8, 371.4, 439.2},
            [16] = {30.3, 91.3, 184.3, 245.3, 339.3, 400.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {name = "Push", text = "Push", loadConditions = meleeConditions}}, group = "Twin Fangs", internalID = "WatchSpawns", name = "Push", text = "Push", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1288538,
        loadConditions = meleeConditions,
        timers = {
            [15] = {20.5, 88.3, 190, 257.8, 359.4, 427.2},
            [16] = {18.3, 79.3, 172.3, 233.3, 327.3, 388.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Twin Fangs", internalID = "Knock", text = "Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1289192,
        textColors = {1, 0, 0, 1},
        loadConditions = tankConditions,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {9.9, 77.7, 179.4, 247.2, 348.8, 416.6},
            [16] = {9, 70, 164, 225, 318.9, 379.9},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id)
    local diffData = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id or self:DifficultyCheck({14, 15, 16})]
    local alert = diffData and diffData.DebuffOverview
    if alert and alert.enabled and self:EvaluateLoad(alert) then
        local overviewSettings = NSRT.ReminderSettings.DebuffOverviewSettings
        self:CreateDebuffOverviewContainers("HARMFUL", {isFromPlayerOrPlayerPet = false, isBossOrRoleAura = false}, 1, 1, "TwinFangsDebuffOverview", false, false, true, 9, {
            height = alert.BarHeight or overviewSettings.Height,
            barColors = alert.BarColor or overviewSettings.barColors,
        }, true)
        self:SetDebuffOverviewContainersShown(true, "TwinFangsDebuffOverview")
    else
        self:SetDebuffOverviewContainersShown(false, "TwinFangsDebuffOverview")
    end
end

NSI.EncounterAlertStop[encID] = function(self)
    self:SetDebuffOverviewContainersShown(false, "TwinFangsDebuffOverview")
end
