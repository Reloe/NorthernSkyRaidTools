local _, NSI = ... -- Internal namespace

-- The Coiled Altar (3429)

local encID = 3429
-- /run NSAPI:DebugEncounter(3429)

local eternalNightfallDuration = 15
local eternalNightfallPreviewAbsorb = 5200000
local p1SoakTimers = {
    [15] = {48, 133},
    [16] = {48, 133},
}

local p3SoakTimers = {
    [15] = {22.3, 191.3},
    [16] = {22.3, 191.3},
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
            [15] = {23, 40, 60, 77.1, 108.1, 125, 145, 162.1},
            [16] = {23, 40, 60, 77.1, 108.1, 125, 145, 162.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P1", internalID = "P1OrbDeadline", name = "Orb deadline", text = "Orb deadline", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        timers = {
            [15] = {17, 34, 54, 71.1, 102.1, 119, 139, 156.1},
            [16] = {17, 34, 54, 71.1, 102.1, 119, 139, 156.1},
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
            [15] = {23.5, 40.5, 60.5, 77.6, 108.6, 125.5, 145.5, 162.6},
            [16] = {23.5, 40.5, 60.5, 77.6, 108.6, 125.5, 145.5, 162.6},
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
            [15] = {8.1, 44.7, 93.1, 129},
            [16] = {8.1, 44.7, 93.1, 129, 177.4},
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
            [15] = {38, 69, 123, 154},
            [16] = {38, 69, 123, 154, 208},
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
            [15] = {38.6, 69.5, 123.6, 154.5},
            [16] = {38.6, 69.5, 123.6, 154.5, 208.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Debuffs", name = "P2 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        loadConditions = nonTankConditions, spellID = 1286895,
        timers = {
            [15] = {24.1, 62.1, 109, 147},
            [16] = {20, 57, 105, 142, 190},
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

    local eternalNightfallPreview = [[return function(NSI)
        NSI:PreviewCoiledAltarEternalNightfall()
    end]]
    local eternalNightfallOptions = {
        {Type = "Color", label = "Bar Color",
            get = [[return function() local alert = NSRT.EncounterAlerts[3429][16].EternalNightfallAbsorb local c = alert.BarColor or NSRT.ReminderSettings.BarSettings.barColors return c[1], c[2], c[3], c[4] end]],
            set = [[return function(NSI, r, g, b, a) for difficultyID = 15, 16 do NSRT.EncounterAlerts[3429][difficultyID].EternalNightfallAbsorb.BarColor = {r, g, b, a} end NSI:UpdateCoiledAltarEternalNightfall() end]],
        },
        {Type = "Slider", label = "Bar Width", min = 50, max = 600, step = 1,
            get = [[return function() local alert = NSRT.EncounterAlerts[3429][16].EternalNightfallAbsorb return alert.BarWidth or NSRT.ReminderSettings.BarSettings.Width end]],
            set = [[return function(NSI, value) for difficultyID = 15, 16 do NSRT.EncounterAlerts[3429][difficultyID].EternalNightfallAbsorb.BarWidth = value end NSI:UpdateCoiledAltarEternalNightfall() end]],
        },
        {Type = "Slider", label = "Bar Height", min = 10, max = 100, step = 1,
            get = [[return function() local alert = NSRT.EncounterAlerts[3429][16].EternalNightfallAbsorb return alert.BarHeight or NSRT.ReminderSettings.BarSettings.Height end]],
            set = [[return function(NSI, value) for difficultyID = 15, 16 do NSRT.EncounterAlerts[3429][difficultyID].EternalNightfallAbsorb.BarHeight = value end NSI:UpdateCoiledAltarEternalNightfall() end]],
        },
    }
    local data = {group = "Coiled Altar P2", internalID = "EternalNightfallAbsorb", name = "Eternal Nightfall Absorb", text = "", DisplayType = "Bar", encID = encID,
        phase = nil, TTS = false, dur = eternalNightfallDuration, enabled = true, isSpecialDisplay = true, BlockCopy = true,
        BarColor = {0.6235, 0.2510, 1, 1}, BarWidth = 300, BarHeight = 40, Anchor = "TOP", relativeTo = "TOP", xOffset = 0, yOffset = -300,
        Preview = eternalNightfallPreview, extraOptions = eternalNightfallOptions, difficulties = {15, 16}, NoEdit = true,
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "InterruptAdds", name = "P2 Interrupt Adds", text = "Ghosts", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        spellID = 1286399,
        timers = {
            [15] = {13, 46.1, 98},
            [16] = {13, 46, 98, 131, 183},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Frontal", name = "P3 Frontal", text = "Frontal", DisplayType = "Text", encID = encID, phase = 3, TTS = true, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1307292,
        isConditional = {
            text = "This Alert only shows if you are not a tank or have threat on boss1.",
            func = [[return function() if UnitGroupRolesAssigned("player") ~= "TANK" then return true end local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {36.3, 68.5, 103, 140.9, 173.1},
            [16] = {35.5, 66.5, 99.9, 136.5, 167.6, 199.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3OrbDeadline", name = "P3 Orb deadline", text = "Orb deadline", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 5,
        timers = {
            [16] = {29.5, 60.5, 93.9, 130.5, 161.6, 193.8},
        },
        difficulties = {16},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Soak", name = "P3 Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 3, TTS = true, dur = 8, spellID = 1299266,
        loadConditions = tankConditions,
        timers = {
            [15] = {22.3, 191.3},
            [16] = {21.8, 86.3, 186.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Shield", name = "P3 Shield", text = "Shield", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        spellID = 1310752,
        timers = {
            [15] = {41.9, 141.8},
            [16] = {38, 134.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Debuffs", name = "P3 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        loadConditions = nonTankConditions, spellID = 1310881,
        timers = {
            [15] = {31.2, 81.8, 115.1, 181.8},
            [16] = {26.8, 71.1, 109, 172.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3InterruptAdds", name = "P3 Interrupt Adds", text = "Ghosts", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        spellID = 1286399,
        timers = {
            [16] = {62.2, 159.2},
        },
        difficulties = {16},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3MindControls", name = "P3 Mind Controls", text = "Mind Controls", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6, spellID = 1297445,
        timers = {
            [15] = {66.3, 167.5},
            [16] = {57.8, 154.1, 201.9},
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
            [15] = {39.6, 71.8, 106.3, 144.2, 176.4},
            [16] = {36, 67, 100.4, 137, 168.1, 200.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P2_5WrongTarget", name = "Wrong Target", text = "WRONG TARGET", DisplayType = "Text", encID = encID, phase = 2.5, TTS = false, dur = 50, sticky = 50,
        timers = {
            [14] = {0},
            [15] = {0},
            [16] = {0},
        },
        enabled = true, textColors = {1, 0, 0, 1}, HideTimer = true, isSpecialDisplay = true, BlockCopy = true,
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "InterruptAssignments", name = "Interrupt Assignments", text = "Interrupts", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 35,
        difficulties = {16}, enabled = true, pinned = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, NumberFontSize = 12, NameFontSize = 12, BoxSize = 30,
        NameplateAnchor = "TOP", NameplateXOffset = 0, NameplateYOffset = 0, ShowAll = false, DisplayStaticBox = false,
        Anchor = "CENTER", relativeTo = "CENTER", xOffset = 0, yOffset = 0,
        Version = {versionNumber = 2, [1] = {BoxSize = 30}, [2] = {NumberFontSize = 12, NameFontSize = 12}},
        extraOptions = {
            { Type = "Label", text = NSI:Loc("The first interrupt line will be assigned to the add with no raidmarker. The second interrupt line will be assigned to the add with any raidmarker. The usual strat is that you have one person instantly putting a raidmarker on the ranged add. That way only one of the boxes should show up and count up correctly."), height = 80 },
            { Type = "Slider", label = "Number Font Size", min = 8, max = 40, step = 1,
                get = [[return function(NSI) local alert = NSRT.EncounterAlerts[3429][16].InterruptAssignments return alert.NumberFontSize or alert.FontSize or 12 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NumberFontSize = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
            },
            { Type = "Slider", label = "Name Font Size", min = 8, max = 40, step = 1,
                get = [[return function(NSI) local alert = NSRT.EncounterAlerts[3429][16].InterruptAssignments return alert.NameFontSize or alert.FontSize or 12 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameFontSize = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
            },
            { Type = "Slider", label = "Box Size", min = 30, max = 150, step = 1,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.BoxSize or 30 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.BoxSize = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
            },
            { Type = "Dropdown", label = "Nameplate Anchor",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateAnchor or "TOP" end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateAnchor = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
                values = [[return function()
                    return {
                        {label = "Top", value = "TOP"},
                        {label = "Center", value = "CENTER"},
                        {label = "Left", value = "LEFT"},
                        {label = "Right", value = "RIGHT"},
                        {label = "Bottom", value = "BOTTOM"},
                    }
                end]],
            },
            { Type = "Slider", label = "Nameplate X Offset", min = -200, max = 200, step = 1,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateXOffset or 0 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateXOffset = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
            },
            { Type = "Slider", label = "Nameplate Y Offset", min = -200, max = 200, step = 1,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateYOffset or 0 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateYOffset = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
            },
            { Type = "Checkbox", label = "Show All",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.ShowAll or false end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.ShowAll = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
                tooltip = {title = "Show All", desc = "Show the assignment boxes for both interrupt lines."},
            },
            { Type = "Checkbox", label = NSI:Loc("Display static box"),
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.DisplayStaticBox or false end]],
                set = [[return function(NSI, value) local alert = NSRT.EncounterAlerts[3429][16].InterruptAssignments alert.DisplayStaticBox = value NSI:UpdateCoiledAltarInterruptDisplay() NSI:UpdateCoiledAltarInterruptPreview() end]],
                tooltip = {title = "Display static box", desc = "Show the interrupt box at a saved static position instead of on the add nameplate. You must focus the ghost for this mode to work."},
            },
        },
        Preview = [[return function(NSI)
            if NSI:PreviewCoiledAltarInterruptDisplay() then
                local alert = NSRT.EncounterAlerts[3429][16].InterruptAssignments
                local message = alert.DisplayStaticBox and "|cFF00FFFFNSRT:|r the live display is shown at the saved static position during phases 2 and 3." or "|cFF00FFFFNSRT:|r the live display is shown on add nameplates during phases 2 and 3."
                print(NSI:Loc(message))
            end
        end]],
    }
    self:AddEncounterAlert(data)
end

local function HideCoiledAltarWrongTarget(self)
    self:EncounterRegister("CoiledAltarWrongTarget", "PLAYER_TARGET_CHANGED", false)
    self.CoiledAltarWrongTargetEndTime = nil
    if self.CoiledAltarWrongTargetTimer then
        self.CoiledAltarWrongTargetTimer:Cancel()
        self.CoiledAltarWrongTargetTimer = nil
    end
    if self.CoiledAltarWrongTargetFrame then
        self.CoiledAltarWrongTargetFrame:Hide()
        self.CoiledAltarWrongTargetFrame = nil
    end
end

local function UpdateCoiledAltarWrongTarget(self)
    if self.Phase ~= 2.5 or not self.CoiledAltarWrongTargetEndTime or GetTime() >= self.CoiledAltarWrongTargetEndTime then
        HideCoiledAltarWrongTarget(self)
        return
    end

    local targetExists = UnitExists("target")
    if issecretvalue(targetExists) or not targetExists then
        if self.CoiledAltarWrongTargetFrame then
            self.CoiledAltarWrongTargetFrame:Hide()
            self.CoiledAltarWrongTargetFrame = nil
        end
        return
    end

    local isBossTarget = UnitIsUnit("target", "boss1")
    if issecretvalue(isBossTarget) then return end
    if isBossTarget then
        if self.CoiledAltarWrongTargetFrame then
            self.CoiledAltarWrongTargetFrame:Hide()
            self.CoiledAltarWrongTargetFrame = nil
        end
        return
    end

    if self.CoiledAltarWrongTargetFrame and self.CoiledAltarWrongTargetFrame:IsShown() then return end
    local remainingDuration = self.CoiledAltarWrongTargetEndTime - GetTime()
    local alert = self.CoiledAltarWrongTargetAlert
    local info = self:CreateReminder({
        text = alert.text,
        DisplayType = alert.DisplayType,
        textColors = alert.textColors,
        dur = remainingDuration,
        time = remainingDuration,
        encID = encID,
        phase = self.Phase,
        HideTimer = true,
        sticky = alert.sticky,
        TTS = false,
        IsAlert = false,
        ReloeReminder = true,
    })
    self.CoiledAltarWrongTargetFrame = info and self:DisplayReminder(info)
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
            local alert = self:CreateDefaultAlert("", "Text", nil, nil, phase, encID, true)
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

local function ResetCoiledAltarInterruptDisplay(self)
    if self.CoiledAltarInterruptFrame then
        self.CoiledAltarInterruptFrame:Hide()
    end
    if self.CoiledAltarInterruptStaticFrame then
        self.CoiledAltarInterruptStaticFrame:Hide()
    end
    for timerIndex, timer in ipairs(self.CoiledAltarInterruptResetTimers or {}) do
        timer:Cancel()
    end
    self.CoiledAltarInterruptResetTimers = nil
    self.CoiledAltarInterruptAssignedBoss = nil
    self.CoiledAltarInterruptActive = false
    self.CoiledAltarInterruptBoss3Available = false
    self.CoiledAltarInterruptCastCounts = {boss3 = 1, boss4 = 1}
    self.CoiledAltarInterruptCasting = {}
    for displayKey, display in pairs(self.CoiledAltarInterruptNameplates or {}) do
        for boxIndex, box in ipairs(display.boxes) do
            box:Hide()
        end
        for lineIndex, line in ipairs(display.lines) do
            for fontIndex, fontString in ipairs(line) do
                fontString:SetAlpha(0)
            end
        end
    end
end

function NSI:UpdateCoiledAltarInterruptPreview()
    local preview = self.CoiledAltarInterruptPreviewFrame
    if not preview then return end

    local alert = self.CoiledAltarInterruptAlert or (NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][16] and NSRT.EncounterAlerts[encID][16].InterruptAssignments)
    local interruptSettings = NSRT.InterruptSettings
    local assignmentTable = self.Interrupts and self.Interrupts.assignTable or {}
    local boxSize = alert and alert.BoxSize or 30
    local fontScale = boxSize / 30
    local numberFontSize = alert and (alert.NumberFontSize or alert.FontSize) or 12
    local nameFontSize = alert and (alert.NameFontSize or alert.FontSize) or 12
    local nameFontPath = self.LSM:Fetch("font", interruptSettings.NameFont)
    local numberFontPath = self.LSM:Fetch("font", interruptSettings.NumberFont)

    local staticPreview = alert and alert.DisplayStaticBox
    self:MakeDraggable(preview, staticPreview and alert or nil, staticPreview or false, false)
    preview:SetSize(staticPreview and boxSize or boxSize * 2 + 20, staticPreview and boxSize or boxSize + 20)
    if staticPreview then
        preview:ClearAllPoints()
        preview:SetPoint(alert.Anchor or "CENTER", UIParent, alert.relativeTo or "CENTER", alert.xOffset or 0, alert.yOffset or 0)
    else
        preview:ClearAllPoints()
        preview:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    for boxIndex, box in ipairs(preview.boxes) do
        box:Hide()
        local previewLine = self.Interrupts and self.Interrupts.myID == 3 and 2 or 1
        if (staticPreview and boxIndex == 1) or (not staticPreview and boxIndex == previewLine) then
            local displayLine = staticPreview and previewLine or boxIndex
            local lineNames = assignmentTable[displayLine + 1] or {}
            local currentName = lineNames[1]
            local nextName = lineNames[2]
            local boxColor = interruptSettings.InterruptDefaultColor
            local textColor = interruptSettings.InterruptDefaultTextColor
            if currentName and UnitIsUnit(currentName, "player") then
                boxColor = interruptSettings.InterruptNowColor
                textColor = interruptSettings.InterruptNowTextColor
            elseif nextName and UnitIsUnit(nextName, "player") then
                boxColor = interruptSettings.InterruptNextColor
                textColor = interruptSettings.InterruptNextTextColor
            end

            box:ClearAllPoints()
            if staticPreview then
                box:SetPoint("CENTER", preview, "CENTER")
            else
                box:SetPoint("CENTER", preview, "CENTER", boxIndex == 1 and -(boxSize + 10) / 2 or (boxSize + 10) / 2, 0)
            end
            box:SetSize(boxSize, boxSize)
            box.Background:SetColorTexture(unpack(boxColor))

            local number = preview.numbers[boxIndex]
            number:ClearAllPoints()
            number:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
            number:SetFont(numberFontPath, numberFontSize * fontScale, interruptSettings.NumberFontFlags)
            number:SetTextColor(unpack(textColor))
            number:SetText(1)

            local name = preview.names[boxIndex]
            name:ClearAllPoints()
            name:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
            name:SetFont(nameFontPath, nameFontSize * fontScale, interruptSettings.NameFontFlags)
            name:SetText(currentName and NSAPI:Shorten(currentName, 12, false, "GlobalNickNames", true, false) or NSAPI:Shorten("player", 12, false, "GlobalNickNames", true, false))
            box:Show()
        end
    end
end

function NSI:PreviewCoiledAltarInterruptDisplay()
    if self.CoiledAltarInterruptPreviewFrame and self.CoiledAltarInterruptPreviewFrame:IsShown() then
        self.CoiledAltarInterruptPreviewFrame:Hide()
        return false
    end
    if not self.CoiledAltarInterruptPreviewFrame then
        local preview = CreateFrame("Frame", "NSRTCoiledAltarInterruptPreview", UIParent)
        preview:SetFrameStrata("DIALOG")
        preview:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        preview:SetFrameLevel(10)
        preview.boxes = {}
        preview.numbers = {}
        preview.names = {}
        for boxIndex = 1, 2 do
            local box = NSI:CreateInterruptAssignmentDisplay(preview)
            box:SetFrameLevel(1)
            box:Show()
            preview.boxes[boxIndex] = box
            preview.numbers[boxIndex] = box.Number
            preview.names[boxIndex] = box.Name
        end
        self.CoiledAltarInterruptPreviewFrame = preview
    end
    self:ReadInterruptNote(1)
    self:UpdateCoiledAltarInterruptPreview()
    self.CoiledAltarInterruptPreviewFrame:Show()
    return true
end

function NSI:UpdateCoiledAltarInterruptDisplay()
    local alert = self.CoiledAltarInterruptAlert
    local interrupts = self.Interrupts
    local assignmentTable = interrupts and interrupts.assignTable
    local phaseAllowed = self.Phase == 2 or self.Phase == 3
    local alertLoad = alert and self:EvaluateLoad(alert)
    local active = self.CoiledAltarInterruptActive and self.CoiledAltarInterruptBoss3Available ~= false and phaseAllowed and alert and alert.enabled and alertLoad
    if not active or not assignmentTable or not assignmentTable[2] or not assignmentTable[3] then
        for displayKey, display in pairs(self.CoiledAltarInterruptNameplates or {}) do
            for boxIndex, box in ipairs(display.boxes) do
                box:Hide()
            end
            for lineIndex, line in ipairs(display.lines) do
                for fontIndex, fontString in ipairs(line) do
                    fontString:SetAlpha(0)
                end
            end
        end
        if self.CoiledAltarInterruptStaticFrame then
            self.CoiledAltarInterruptStaticFrame:Hide()
        end
        return
    end

    local boxSize = alert.BoxSize or 100
    local numberFontSize = alert.NumberFontSize or alert.FontSize or 12
    local nameFontSize = alert.NameFontSize or alert.FontSize or 12
    local nameplateAnchor = alert.NameplateAnchor or "TOP"
    local boxAnchor, plateAnchor = "BOTTOM", "TOP"
    if nameplateAnchor == "CENTER" then
        boxAnchor, plateAnchor = "CENTER", "CENTER"
    elseif nameplateAnchor == "LEFT" then
        boxAnchor, plateAnchor = "RIGHT", "LEFT"
    elseif nameplateAnchor == "RIGHT" then
        boxAnchor, plateAnchor = "LEFT", "RIGHT"
    elseif nameplateAnchor == "BOTTOM" then
        boxAnchor, plateAnchor = "TOP", "BOTTOM"
    end
    local nameplateXOffset = alert.NameplateXOffset or 0
    local nameplateYOffset = alert.NameplateYOffset or 0
    local assignedBoss = self.CoiledAltarInterruptAssignedBoss
    local assignedLine = self.Interrupts.myID == 2 and 1 or self.Interrupts.myID == 3 and 2
    local interruptSettings = NSRT.InterruptSettings
    local nameFontPath = self.LSM:Fetch("font", interruptSettings.NameFont)
    local numberFontPath = self.LSM:Fetch("font", interruptSettings.NumberFont)
    local fontScale = boxSize / 30

    if alert.DisplayStaticBox and UnitExists("focus") then
        for displayKey, display in pairs(self.CoiledAltarInterruptNameplates or {}) do
            for boxIndex, box in ipairs(display.boxes) do
                box:Hide()
            end
        end

        local staticFrame = self.CoiledAltarInterruptStaticFrame
        if not staticFrame then
            staticFrame = CreateFrame("Frame", "NSRTCoiledAltarInterruptStatic", self.NSRTFrame)
            staticFrame.box = self:CreateInterruptAssignmentDisplay(staticFrame)
            self.CoiledAltarInterruptStaticFrame = staticFrame
        end
        staticFrame:ClearAllPoints()
        staticFrame:SetPoint(alert.Anchor or "CENTER", UIParent, alert.relativeTo or "CENTER", alert.xOffset or 0, alert.yOffset or 0)
        staticFrame:SetSize(boxSize, boxSize)

        local focusExists = UnitExists("focus")
        local focusIsGhost = focusExists and UnitLevel("focus") == 92
        local focusMarker = focusIsGhost and GetRaidTargetIndex("focus")
        local focusHasMarker = focusIsGhost and issecretvalue(focusMarker)
        local displayLine = focusHasMarker and 2 or 1
        local markedBoss = assignedBoss
        local unmarkedBoss = markedBoss == "boss3" and "boss4" or markedBoss == "boss4" and "boss3"
        local countUnit = displayLine == 2 and markedBoss or unmarkedBoss
        local boxVisible = focusIsGhost and countUnit and (alert.ShowAll or assignedLine == displayLine)
        local box = staticFrame.box
        box:Hide()
        if boxVisible then
            local lineNames = assignmentTable[displayLine + 1]
            local castCount = self.CoiledAltarInterruptCastCounts[countUnit] or 1
            local currentName = #lineNames > 0 and lineNames[((castCount - 1) % #lineNames) + 1]
            local nextName = #lineNames > 0 and lineNames[(castCount % #lineNames) + 1]
            local boxColor = interruptSettings.InterruptDefaultColor
            local textColor = interruptSettings.InterruptDefaultTextColor
            if currentName and UnitIsUnit(currentName, "player") then
                boxColor = interruptSettings.InterruptNowColor
                textColor = interruptSettings.InterruptNowTextColor
            elseif nextName and UnitIsUnit(nextName, "player") then
                boxColor = interruptSettings.InterruptNextColor
                textColor = interruptSettings.InterruptNextTextColor
            end
            box:ClearAllPoints()
            box:SetPoint("CENTER", staticFrame, "CENTER")
            box:SetSize(boxSize, boxSize)
            box.Background:SetColorTexture(unpack(boxColor))
            box.Number:ClearAllPoints()
            box.Number:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
            box.Number:SetFont(numberFontPath, numberFontSize * fontScale, interruptSettings.NumberFontFlags)
            box.Number:SetTextColor(unpack(textColor))
            box.Number:SetText(castCount)
            box.Name:ClearAllPoints()
            box.Name:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
            box.Name:SetFont(nameFontPath, nameFontSize * fontScale, interruptSettings.NameFontFlags)
            box.Name:SetText(currentName and NSAPI:Shorten(currentName, 12, false, "GlobalNickNames", true, false) or "")
            box:Show()
            staticFrame:Show()
        else
            staticFrame:Hide()
        end
        return
    elseif self.CoiledAltarInterruptStaticFrame then
        self.CoiledAltarInterruptStaticFrame:Hide()
    end

    for unit, display in pairs(self.CoiledAltarInterruptNameplates or {}) do
        if display.plate then
            local raidMarker = GetRaidTargetIndex(unit)
            local hasRaidMarker = issecretvalue(raidMarker)
            for boxIndex, box in ipairs(display.boxes) do
                box:SetAlpha(0)
                box:Hide()
            end
            for bossIndex, box in ipairs(display.boxes) do
                local bossUnit = bossIndex == 1 and "boss3" or "boss4"
                local displayLine = bossIndex == 2 and 2 or 1
                local lineNames = assignmentTable[displayLine + 1]
                local countUnit = bossUnit
                local castCount = self.CoiledAltarInterruptCastCounts[countUnit] or 1
                local currentName = #lineNames > 0 and lineNames[((castCount - 1) % #lineNames) + 1]
                local nextName = #lineNames > 0 and lineNames[(castCount % #lineNames) + 1]
                local boxColor = interruptSettings.InterruptDefaultColor
                local textColor = interruptSettings.InterruptDefaultTextColor
                if currentName and UnitIsUnit(currentName, "player") then
                    boxColor = interruptSettings.InterruptNowColor
                    textColor = interruptSettings.InterruptNowTextColor
                elseif nextName and UnitIsUnit(nextName, "player") then
                    boxColor = interruptSettings.InterruptNextColor
                    textColor = interruptSettings.InterruptNextTextColor
                end
                box:ClearAllPoints()
                box:SetPoint(boxAnchor, display.plate, plateAnchor, nameplateXOffset, nameplateYOffset)
                box:SetSize(boxSize, boxSize)
                box.Background:SetColorTexture(unpack(boxColor))
                local boxVisible = (alert.ShowAll or assignedLine == displayLine) and ((bossIndex == 2) == hasRaidMarker)
        if boxVisible and countUnit then
                    box:SetAlpha(1)
                    box:Show()
                end
                local number = display.numbers[bossIndex]
                local name = display.names[bossIndex]
                local displayName = currentName and UnitExists(currentName) and NSAPI:Shorten(currentName, 12, false, "GlobalNickNames", true, false) or ""
                number:ClearAllPoints()
                number:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
                number:SetFont(numberFontPath, numberFontSize * fontScale, interruptSettings.NumberFontFlags)
                number:SetTextColor(unpack(textColor))
                number:SetText(castCount)
                number:SetAlpha(1)
                name:ClearAllPoints()
                name:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
                name:SetFont(nameFontPath, nameFontSize * fontScale, interruptSettings.NameFontFlags)
                name:SetText(displayName)
                name:SetAlpha(1)
            end
            for lineIndex, line in ipairs(display.lines) do
                for bossIndex, fontString in ipairs(line) do
                    fontString:SetAlpha(0)
                end
            end
        end
    end
end

local function AddCoiledAltarInterruptNameplate(self, unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local interruptSettings = NSRT.InterruptSettings
    self.CoiledAltarInterruptNameplates = self.CoiledAltarInterruptNameplates or {}
    if not plate or UnitLevel(unit) ~= 92 then
        local oldDisplay = self.CoiledAltarInterruptNameplates[unit]
        if oldDisplay then
            for boxIndex, box in ipairs(oldDisplay.boxes) do
                box:Hide()
            end
            oldDisplay.plate = nil
        end
        return
    end
    local display = self.CoiledAltarInterruptNameplates[unit]
    if not display then
        display = {plate = plate, lines = {}, numbers = {}, names = {}, boxes = {}}
        self.CoiledAltarInterruptNameplates[unit] = display
        for bossIndex = 1, 2 do
            local box = NSI:CreateInterruptAssignmentDisplay(self.CoiledAltarInterruptFrame)
            display.boxes[bossIndex] = box
            box:SetFrameLevel(1)
            box:SetSize(self.CoiledAltarInterruptAlert.BoxSize or 100, self.CoiledAltarInterruptAlert.BoxSize or 100)
            box:SetPoint("BOTTOM", plate, "TOP", 0, 0)
            display.numbers[bossIndex] = box.Number
            display.numbers[bossIndex]:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
            display.names[bossIndex] = box.Name
            display.names[bossIndex]:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
        end
    elseif not display.numbers then
        display.numbers = {}
        display.names = {}
        for bossIndex, box in ipairs(display.boxes) do
            display.numbers[bossIndex] = box.Number
            display.numbers[bossIndex]:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
            display.names[bossIndex] = box.Name
            display.names[bossIndex]:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
        end
        for lineIndex = 1, 2 do
            display.lines[lineIndex] = {}
            for bossIndex, box in ipairs(display.boxes) do
                local fontString = box:CreateFontString(nil, "OVERLAY")
                fontString:SetJustifyH("CENTER")
                fontString:SetPoint("CENTER", box, "CENTER", 0, (2 - lineIndex) * 12)
                display.lines[lineIndex][bossIndex] = fontString
            end
        end
    elseif display.plate ~= plate then
        for boxIndex, box in ipairs(display.boxes) do
            box:ClearAllPoints()
            box:SetPoint("BOTTOM", plate, "TOP", 0, 0)
        end
        display.plate = plate
    end
    NSI:UpdateCoiledAltarInterruptDisplay()
end

local function RefreshCoiledAltarInterruptNameplates(self)
    local activeUnits = {}
    for plateIndex, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = plate.namePlateUnitToken
        if unit then
            activeUnits[unit] = true
            AddCoiledAltarInterruptNameplate(self, unit)
        end
    end
    for unit, display in pairs(self.CoiledAltarInterruptNameplates or {}) do
        if not activeUnits[unit] then
            for boxIndex, box in ipairs(display.boxes) do
                box:Hide()
            end
            display.plate = nil
        end
    end
end

local function RemoveCoiledAltarInterruptNameplate(self, unit)
    local display = self.CoiledAltarInterruptNameplates and self.CoiledAltarInterruptNameplates[unit]
    if not display then return end
    for boxIndex, box in ipairs(display.boxes) do
        box:Hide()
    end
    display.plate = nil
end

local function UpdateCoiledAltarInterruptMarker(self)
    local assignedBoss = self.CoiledAltarInterruptAssignedBoss
    local migratedBoss
    if assignedBoss == "boss4" and not UnitExists("boss4") and UnitExists("boss3") then
        migratedBoss = "boss3"
    end
    if migratedBoss then
        local counts = self.CoiledAltarInterruptCastCounts or {}
        counts[migratedBoss] = math.max(counts[migratedBoss] or 1, counts[assignedBoss] or 1)
        self.CoiledAltarInterruptCastCounts = counts
        if self.CoiledAltarInterruptCasting and self.CoiledAltarInterruptCasting[assignedBoss] then
            self.CoiledAltarInterruptCasting[migratedBoss] = true
        end
        if self.CoiledAltarInterruptCasting then
            self.CoiledAltarInterruptCasting[assignedBoss] = nil
        end
        self.CoiledAltarInterruptAssignedBoss = migratedBoss
    end
    if self.CoiledAltarInterruptAssignedBoss or not self.CoiledAltarInterruptActive then
        NSI:UpdateCoiledAltarInterruptDisplay()
        return
    end
    local boss3Marker = GetRaidTargetIndex("boss3")
    local boss4Marker = GetRaidTargetIndex("boss4")
    if issecretvalue(boss3Marker) then
        self.CoiledAltarInterruptAssignedBoss = "boss3"
    elseif issecretvalue(boss4Marker) then
        self.CoiledAltarInterruptAssignedBoss = "boss4"
    end
    NSI:UpdateCoiledAltarInterruptDisplay()
end

local function ArmCoiledAltarInterruptResetTimers(self, phase)
    for timerIndex, timer in ipairs(self.CoiledAltarInterruptResetTimers or {}) do
        timer:Cancel()
    end
    self.CoiledAltarInterruptResetTimers = {}

    local difficultyID = self:DifficultyCheck({16})
    local alertID = phase == 2 and "InterruptAdds" or phase == 3 and "P3InterruptAdds"
    local diffData = difficultyID and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][difficultyID]
    local ghostAlert = diffData and alertID and diffData[alertID]
    local timers = ghostAlert and ghostAlert.timers
    if not timers then return end

    local phaseStart = self.PhaseSwapTime or GetTime()
    for timerIndex, timer in ipairs(timers) do
        local delay = timer - (GetTime() - phaseStart)
        self.CoiledAltarInterruptResetTimers[#self.CoiledAltarInterruptResetTimers + 1] = C_Timer.NewTimer(math.max(delay, 0), function()
            if self.EncounterID ~= encID or self.Phase ~= phase then return end
            self.CoiledAltarInterruptAssignedBoss = nil
            self.CoiledAltarInterruptCastCounts = {boss3 = 1, boss4 = 1}
            self.CoiledAltarInterruptCasting = {}
            NSI:UpdateCoiledAltarInterruptDisplay()
        end)
    end
end

local function IsCoiledAltarInterruptUnit(self, unit)
    return unit == "boss3" or unit == "boss4"
end

local function SetCoiledAltarInterruptPhase(self, active)
    local alert = self.CoiledAltarInterruptAlert
    local alertLoad = alert and self:EvaluateLoad(alert)
    if active and (not alert or not alert.enabled or not alertLoad) then
        active = false
    end
    self.CoiledAltarInterruptActive = active
    self.CoiledAltarInterruptBoss3Available = active
    self.CoiledAltarInterruptAssignedBoss = nil
    self.CoiledAltarInterruptCastCounts = {boss3 = 1, boss4 = 1}
    self.CoiledAltarInterruptCasting = {}
    if active then
        self.CoiledAltarInterruptFrame:Show()
        self:ReadInterruptNote(1)
        RefreshCoiledAltarInterruptNameplates(self)
        UpdateCoiledAltarInterruptMarker(self)
        ArmCoiledAltarInterruptResetTimers(self, self.Phase)
    end
    NSI:UpdateCoiledAltarInterruptDisplay()
end

local function ApplyCoiledAltarEternalNightfallSettings(self, frame, alert)
    local barSettings = NSRT.ReminderSettings.BarSettings
    frame:SetSize(alert.BarWidth or barSettings.Width, alert.BarHeight or barSettings.Height)
    frame:SetScale(1)
    frame:ClearAllPoints()
    frame:SetPoint(alert.Anchor or barSettings.Anchor, self.NSRTFrame, alert.relativeTo or barSettings.relativeTo, alert.xOffset or barSettings.xOffset, alert.yOffset or barSettings.yOffset)
    frame:SetStatusBarTexture(self.LSM:Fetch("statusbar", barSettings.Texture))
    frame:SetStatusBarColor(unpack(alert.BarColor or barSettings.barColors))
    frame:SetBackdropColor(unpack(barSettings.backgroundColors))
    frame.Border:SetBackdropBorderColor(unpack(barSettings.borderColors))
    frame.AbsorbText:SetFont(self.LSM:Fetch("font", barSettings.Font), barSettings.TimerFontSize, "OUTLINE")
    frame.AbsorbText:SetTextColor(unpack(barSettings.textColors))
    frame.TimerText:SetFont(self.LSM:Fetch("font", barSettings.Font), barSettings.TimerFontSize, "OUTLINE")
    frame.TimerText:SetTextColor(unpack(barSettings.textColors))
    frame.Tick:SetSize(2, frame:GetHeight())
end

local function HideCoiledAltarEternalNightfall(self)
    local frame = self.CoiledAltarEternalNightfallFrame
    if frame then
        frame:Hide()
        frame.EternalNightfallStart = nil
        frame.EternalNightfallEnd = nil
        frame.EternalNightfallMaxAbsorb = nil
    end
end

local function ShowCoiledAltarEternalNightfall(self, preview, maxAbsorb)
    local frame = self.CoiledAltarEternalNightfallFrame
    local alert = self.CoiledAltarEternalNightfallAlert
    if not frame or not alert then return end
    ApplyCoiledAltarEternalNightfallSettings(self, frame, alert)
    maxAbsorb = maxAbsorb or (preview and secretwrap(eternalNightfallPreviewAbsorb) or UnitGetTotalAbsorbs("boss2"))
    frame:SetMinMaxValues(0, maxAbsorb)
    frame:SetValue(maxAbsorb)
    frame.EternalNightfallStart = frame.EternalNightfallStart or GetTime()
    frame.EternalNightfallEnd = frame.EternalNightfallStart + eternalNightfallDuration
    frame.EternalNightfallMaxAbsorb = maxAbsorb
    frame.AbsorbText:SetText(AbbreviateNumbers(maxAbsorb))
    frame.TimerText:SetText(string.format("%.1f", eternalNightfallDuration))
    frame:Show()
end

function NSI:UpdateCoiledAltarEternalNightfall()
    local frame = self.CoiledAltarEternalNightfallFrame
    local alert = self.CoiledAltarEternalNightfallAlert
    if not frame or not alert then return end
    ApplyCoiledAltarEternalNightfallSettings(self, frame, alert)
    if frame:IsShown() then
        frame:SetMinMaxValues(0, frame.EternalNightfallMaxAbsorb or secretwrap(eternalNightfallPreviewAbsorb))
    end
end

function NSI:PreviewCoiledAltarEternalNightfall()
    if self.CoiledAltarEternalNightfallPreview then
        self.CoiledAltarEternalNightfallPreview = false
        HideCoiledAltarEternalNightfall(self)
        self:MakeDraggable(self.CoiledAltarEternalNightfallFrame, nil, false)
        return false
    end
    self.CoiledAltarEternalNightfallPreview = true
    self.CoiledAltarEternalNightfallAlert = NSRT.EncounterAlerts[encID][16].EternalNightfallAbsorb
    local frame = self.CoiledAltarEternalNightfallFrame
    if not frame then
        frame = CreateFrame("StatusBar", "NSRTCoiledAltarEternalNightfall", self.NSRTFrame, "BackdropTemplate")
        frame:SetFrameStrata("HIGH")
        frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", tileSize = 0})
        frame.Border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.Border:SetAllPoints(frame)
        frame.Border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        frame.AbsorbText = frame:CreateFontString(nil, "OVERLAY")
        frame.AbsorbText:SetPoint("LEFT", frame, "LEFT", 4, 0)
        frame.TimerText = frame:CreateFontString(nil, "OVERLAY")
        frame.TimerText:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
        frame.Tick = frame:CreateTexture(nil, "OVERLAY")
        frame.Tick:SetColorTexture(1, 1, 1, 1)
        frame:SetScript("OnUpdate", function(display)
            if not display.EternalNightfallStart then return end
            local elapsed = GetTime() - display.EternalNightfallStart
            if elapsed >= eternalNightfallDuration then
                HideCoiledAltarEternalNightfall(self)
                return
            end
            local previewProgress = math.min(1, elapsed / eternalNightfallDuration * 1.05)
            local absorb = self.CoiledAltarEternalNightfallPreview and secretwrap(eternalNightfallPreviewAbsorb * (1 - previewProgress)) or UnitGetTotalAbsorbs("boss2")
            display:SetValue(absorb)
            display.AbsorbText:SetText(AbbreviateNumbers(absorb))
            display.Tick:ClearAllPoints()
            display.Tick:SetPoint("CENTER", display, "LEFT", display:GetWidth() * (1 - elapsed / eternalNightfallDuration), 0)
            display.TimerText:SetText(string.format("%.1f", eternalNightfallDuration - elapsed))
        end)
        self.CoiledAltarEternalNightfallFrame = frame
    end
    ApplyCoiledAltarEternalNightfallSettings(self, frame, self.CoiledAltarEternalNightfallAlert)
    self:MakeDraggable(frame, self.CoiledAltarEternalNightfallAlert, true, false)
    ShowCoiledAltarEternalNightfall(self, true)
    return true
end

local function StopCoiledAltarEternalNightfallListening(self)
    for timerIndex, timer in ipairs(self.CoiledAltarEternalNightfallListenTimers or {}) do
        timer:Cancel()
    end
    self.CoiledAltarEternalNightfallListenTimers = nil
    if self.CoiledAltarEternalNightfallListenStopTimer then
        self.CoiledAltarEternalNightfallListenStopTimer:Cancel()
        self.CoiledAltarEternalNightfallListenStopTimer = nil
    end
    self:EncounterRegister("CoiledAltarEternalNightfall", {"UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_SPELLCAST_STOP"}, false, "boss2")
end

local function ArmCoiledAltarEternalNightfall(self, phase)
    StopCoiledAltarEternalNightfallListening(self)
    local alert = self.CoiledAltarEternalNightfallAlert
    local difficultyID = self:DifficultyCheck({15, 16})
    local diffData = difficultyID and NSRT.EncounterAlerts[encID][difficultyID]
    local shieldAlert = diffData and diffData[phase == 3 and "P3Shield" or "P2Shield"]
    local shieldTimers = shieldAlert and shieldAlert.timers
    if not alert or not alert.enabled or not self:EvaluateLoad(alert) or not shieldTimers then return end

    self.CoiledAltarEternalNightfallListenTimers = {}
    for shieldIndex, shieldTime in ipairs(shieldTimers) do
        local listenDelay = shieldTime - 2
        if listenDelay >= 0 then
            self.CoiledAltarEternalNightfallListenTimers[#self.CoiledAltarEternalNightfallListenTimers + 1] = C_Timer.NewTimer(listenDelay, function()
                if self.EncounterID ~= encID or self.Phase ~= phase then return end
                self:EncounterRegister("CoiledAltarEternalNightfall", {"UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_SPELLCAST_STOP"}, true, "boss2")
                self.CoiledAltarEternalNightfallListenStopTimer = C_Timer.NewTimer(eternalNightfallDuration + 2, function()
                    StopCoiledAltarEternalNightfallListening(self)
                end)
            end)
        end
    end
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck({15, 16})
    local diffData = id and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id]
    self.CoiledAltarInterruptAlert = diffData and diffData.InterruptAssignments
    self.CoiledAltarEternalNightfallAlert = diffData and diffData.EternalNightfallAbsorb
    self.CoiledAltarEternalNightfallPreview = false
    StopCoiledAltarEternalNightfallListening(self)
    local eternalNightfallActive = self.CoiledAltarEternalNightfallAlert and self.CoiledAltarEternalNightfallAlert.enabled and self:EvaluateLoad(self.CoiledAltarEternalNightfallAlert)
    if eternalNightfallActive then
        local frame = self.CoiledAltarEternalNightfallFrame
        if not frame then
            self:PreviewCoiledAltarEternalNightfall()
            self.CoiledAltarEternalNightfallPreview = false
            self:MakeDraggable(self.CoiledAltarEternalNightfallFrame, nil, false)
            HideCoiledAltarEternalNightfall(self)
        end
        self:EncounterFunction("CoiledAltarEternalNightfall", function(eventFrame, event)
            local frame = self.CoiledAltarEternalNightfallFrame
            if event == "UNIT_ABSORB_AMOUNT_CHANGED" and frame then
                local absorb = UnitGetTotalAbsorbs("boss2")
                if frame.EternalNightfallMaxAbsorb == nil then
                    ShowCoiledAltarEternalNightfall(self, false, absorb)
                else
                    frame:SetValue(absorb)
                    frame.AbsorbText:SetText(AbbreviateNumbers(absorb))
                end
            elseif event == "UNIT_SPELLCAST_STOP" then
                HideCoiledAltarEternalNightfall(self)
            end
        end)
        if self.Phase == 2 then ArmCoiledAltarEternalNightfall(self, 2) end
    end
    local interruptAlertActive = self.CoiledAltarInterruptAlert and self.CoiledAltarInterruptAlert.enabled and self:EvaluateLoad(self.CoiledAltarInterruptAlert)
    if interruptAlertActive then
        self.CoiledAltarInterruptFrame = self.CoiledAltarInterruptFrame or CreateFrame("Frame")
        self:EncounterRegister("CoiledAltarInterruptAssignments", {"NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "RAID_TARGET_UPDATE", "PLAYER_FOCUS_CHANGED", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"}, true)
        self:EncounterRegister("CoiledAltarInterruptAssignments", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, true, {"boss3", "boss4"})
        self:EncounterFunction("CoiledAltarInterruptAssignments", function(_, event, unit)
            if event == "NAME_PLATE_UNIT_ADDED" then
                AddCoiledAltarInterruptNameplate(self, unit)
            elseif event == "NAME_PLATE_UNIT_REMOVED" then
                RemoveCoiledAltarInterruptNameplate(self, unit)
            elseif event == "RAID_TARGET_UPDATE" then
                UpdateCoiledAltarInterruptMarker(self)
            elseif event == "PLAYER_FOCUS_CHANGED" then
                NSI:UpdateCoiledAltarInterruptDisplay()
            elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
                local boss3Exists = UnitExists("boss3")
                if not boss3Exists then
                    self.CoiledAltarInterruptBoss3Available = false
                    self.CoiledAltarInterruptAssignedBoss = nil
                    self.CoiledAltarInterruptCastCounts = {boss3 = 1, boss4 = 1}
                    self.CoiledAltarInterruptCasting = {}
                    NSI:UpdateCoiledAltarInterruptDisplay()
                    return
                end
                self.CoiledAltarInterruptBoss3Available = true
                UpdateCoiledAltarInterruptMarker(self)
            elseif event == "UNIT_SPELLCAST_START" then
                UpdateCoiledAltarInterruptMarker(self)
                if self.CoiledAltarInterruptActive and IsCoiledAltarInterruptUnit(self, unit) and UnitIsEnemy(unit, "player") then
                    self.CoiledAltarInterruptCasting[unit] = true
                    NSI:UpdateCoiledAltarInterruptDisplay()
                end
            elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
                UpdateCoiledAltarInterruptMarker(self)
                if self.CoiledAltarInterruptActive and IsCoiledAltarInterruptUnit(self, unit) and self.CoiledAltarInterruptCasting[unit] then
                    self.CoiledAltarInterruptCasting[unit] = nil
                    self.CoiledAltarInterruptCastCounts[unit] = (self.CoiledAltarInterruptCastCounts[unit] or 1) + 1
                end
                NSI:UpdateCoiledAltarInterruptDisplay()
            elseif event == "UNIT_SPELLCAST_STOP" then
                UpdateCoiledAltarInterruptMarker(self)
                if self.CoiledAltarInterruptActive and IsCoiledAltarInterruptUnit(self, unit) and self.CoiledAltarInterruptCasting[unit] then
                    self.CoiledAltarInterruptCasting[unit] = nil
                    self.CoiledAltarInterruptCastCounts[unit] = self.CoiledAltarInterruptCastCounts[unit] + 1
                    NSI:UpdateCoiledAltarInterruptDisplay()
                end
            end
        end)
        SetCoiledAltarInterruptPhase(self, false)
    else
        self:EncounterRegister("CoiledAltarInterruptAssignments", {"NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "RAID_TARGET_UPDATE", "PLAYER_FOCUS_CHANGED", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"}, false)
        self:EncounterRegister("CoiledAltarInterruptAssignments", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false, {"boss3", "boss4"})
        ResetCoiledAltarInterruptDisplay(self)
    end
    self.CoiledAltarWrongTargetAlert = diffData and diffData.P2_5WrongTarget
    HideCoiledAltarWrongTarget(self)
    local wrongTargetLoad = self.CoiledAltarWrongTargetAlert and self:EvaluateLoad(self.CoiledAltarWrongTargetAlert)
    self:EncounterFunction("CoiledAltarWrongTarget", function()
        UpdateCoiledAltarWrongTarget(self)
    end)
    self:EncounterRegister("CoiledAltarPhaseDetect", "UNIT_SPELLCAST_CHANNEL_START", true, "boss2")
    self:EncounterFunction("CoiledAltarPhaseDetect", function(_, e, unit)
        local activeTimelineCount = self:GetActiveEncounterTimelineEventCount()
        if e ~= "UNIT_SPELLCAST_CHANNEL_START" or self.Phase ~= 2 or activeTimelineCount ~= 0 then
            return
        end
        self.Phase = 2.5
        self:StartReminders(self.Phase)
        self.PhaseSwapTime = GetTime()
        SetCoiledAltarInterruptPhase(self, false)
        local alert = self.CoiledAltarWrongTargetAlert
        if alert and alert.enabled and self:EvaluateLoad(alert) then
            self.CoiledAltarWrongTargetEndTime = GetTime() + (alert.dur or 50)
            self:EncounterRegister("CoiledAltarWrongTarget", "PLAYER_TARGET_CHANGED", true)
            self.CoiledAltarWrongTargetTimer = C_Timer.NewTimer(alert.dur or 50, function()
                HideCoiledAltarWrongTarget(self)
            end)
            UpdateCoiledAltarWrongTarget(self)
        end
    end)
end

NSI.EncounterAlertStop[encID] = function(self)
    HideCoiledAltarWrongTarget(self)
    StopCoiledAltarEternalNightfallListening(self)
    self.CoiledAltarEternalNightfallPreview = false
    HideCoiledAltarEternalNightfall(self)
    self:EncounterRegister("CoiledAltarInterruptAssignments", {"NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "RAID_TARGET_UPDATE", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"}, false)
    self:EncounterRegister("CoiledAltarInterruptAssignments", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false, {"boss3", "boss4"})
    ResetCoiledAltarInterruptDisplay(self)
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
        StopCoiledAltarEternalNightfallListening(self)
        SetCoiledAltarInterruptPhase(self, true)
        HideCoiledAltarWrongTarget(self)
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
        if newphase == 2 or newphase == 3 then
            ArmCoiledAltarEternalNightfall(self, newphase)
        end
        SetCoiledAltarInterruptPhase(self, newphase == 2 or newphase == 3)
    end
end
