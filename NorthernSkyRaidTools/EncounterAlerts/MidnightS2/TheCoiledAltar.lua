local _, NSI = ... -- Internal namespace

-- The Coiled Altar (3429)

local encID = 3429
-- /run NSAPI:DebugEncounter(3429)

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
            [16] = {8.1, 44.7, 93.1, 129},
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
            [15] = {38.1, 69, 123.1, 154},
            [16] = {38.1, 69, 123.1, 154},
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
            [16] = {38.6, 69.5, 123.6, 154.5},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P2", internalID = "P2Debuffs", name = "P2 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 6,
        loadConditions = nonTankConditions, spellID = 1286895,
        timers = {
            [15] = {24.1, 62.1, 109, 147},
            [16] = {24.1, 62.1, 109, 147},
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
            [15] = {13, 46.1, 98},
            [16] = {13, 46.1, 98},
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
            [16] = {36.3, 68.5, 103, 140.9, 173.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Soak", name = "P3 Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 3, TTS = true, dur = 8, spellID = 1299266,
        loadConditions = tankConditions,
        timers = {
            [15] = {22.3, 191.3},
            [16] = {22.3, 191.3},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Shield", name = "P3 Shield", text = "Shield", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        spellID = 1310752,
        timers = {
            [15] = {41.9, 141.8},
            [16] = {41.9, 141.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Coiled Altar P3", internalID = "P3Debuffs", name = "P3 Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        loadConditions = nonTankConditions, spellID = 1310881,
        timers = {
            [15] = {31.2, 81.8, 115.1, 181.8},
            [16] = {31.2, 81.8, 115.1, 181.8},
        },
    }
    self:AddEncounterAlert(data)

    --[=[
    local data = {group = "Coiled Altar P3", internalID = "P3InterruptAdds", name = "P3 Interrupt Adds", text = "Ghosts", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6,
        spellID = 1286399,
        timers = {
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)
    ]=]

    local data = {group = "Coiled Altar P3", internalID = "P3MindControls", name = "P3 Mind Controls", text = "Mind Controls", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 6, spellID = 1297445,
        timers = {
            [15] = {66.3, 167.5},
            [16] = {66.3, 167.5},
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
            [16] = {39.6, 71.8, 106.3, 144.2, 176.4},
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
        difficulties = {16}, enabled = true, pinned = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, FontSize = 12, BoxSize = 30,
        NameplateAnchor = "TOP", NameplateXOffset = 0, NameplateYOffset = 0, ShowAll = false,
        Version = {versionNumber = 1, [1] = {BoxSize = 30}},
        extraOptions = {
            { Type = "Slider", label = "Font Size", min = 8, max = 40, step = 1,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.FontSize or 12 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.FontSize = value NSI:UpdateCoiledAltarInterruptDisplay() end]],
            },
            { Type = "Slider", label = "Box Size", min = 30, max = 150, step = 1,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.BoxSize or 30 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.BoxSize = value NSI:UpdateCoiledAltarInterruptDisplay() end]],
            },
            { Type = "Dropdown", label = "Nameplate Anchor",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateAnchor or "TOP" end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateAnchor = value NSI:UpdateCoiledAltarInterruptDisplay() end]],
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
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateXOffset = value NSI:UpdateCoiledAltarInterruptDisplay() end]],
            },
            { Type = "Slider", label = "Nameplate Y Offset", min = -200, max = 200, step = 1,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateYOffset or 0 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.NameplateYOffset = value NSI:UpdateCoiledAltarInterruptDisplay() end]],
            },
            { Type = "Checkbox", label = "Show All",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3429][16].InterruptAssignments.ShowAll or false end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3429][16].InterruptAssignments.ShowAll = value NSI:UpdateCoiledAltarInterruptDisplay() end]],
                tooltip = {title = "Show All", desc = "Show the assignment boxes for both interrupt lines."},
            },
        },
        Preview = [[return function(NSI) print(NSI:Loc("|cFF00FFFFNSRT:|r no preview available for this Alert. It is displayed on the add nameplates during phases 2 and 3.")) end]],
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
    self.CoiledAltarInterruptAssignedBoss = nil
    self.CoiledAltarInterruptActive = false
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

function NSI:UpdateCoiledAltarInterruptDisplay()
    local alert = self.CoiledAltarInterruptAlert
    local interrupts = self.Interrupts
    local assignmentTable = interrupts and interrupts.assignTable
    local phaseAllowed = self.Phase == 2 or self.Phase == 3
    local alertLoad = alert and self:EvaluateLoad(alert)
    local active = self.CoiledAltarInterruptActive and phaseAllowed and alert and alert.enabled and alertLoad
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
        return
    end

    local boxSize = alert.BoxSize or 100
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
    local regularDisplayHeight = interruptSettings.Height or 100
    local fontScale = boxSize / regularDisplayHeight * 1.15
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
                local countUnit = assignedBoss or bossUnit
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
                if boxVisible then
                    box:SetAlpha(1)
                    box:Show()
                end
                local number = display.numbers[bossIndex]
                local name = display.names[bossIndex]
                local displayName = currentName and UnitExists(currentName) and NSAPI:Shorten(currentName, 12, false, "GlobalNickNames", true, false) or ""
                number:ClearAllPoints()
                number:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
                number:SetFont(numberFontPath, interruptSettings.NumberFontSize * fontScale, interruptSettings.NumberFontFlags)
                number:SetTextColor(unpack(textColor))
                number:SetText(castCount)
                number:SetAlpha(1)
                name:ClearAllPoints()
                name:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
                name:SetFont(nameFontPath, interruptSettings.NameFontSize * fontScale, interruptSettings.NameFontFlags)
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
    if not plate or UnitLevel(unit) == 92 then
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
            local box = CreateFrame("Frame", nil, self.CoiledAltarInterruptFrame)
            display.boxes[bossIndex] = box
            box:SetFrameLevel(1)
            box:SetSize(self.CoiledAltarInterruptAlert.BoxSize or 100, self.CoiledAltarInterruptAlert.BoxSize or 100)
            box:SetPoint("BOTTOM", plate, "TOP", 0, 0)
            box.Background = box:CreateTexture(nil, "ARTWORK")
            box.Background:SetAllPoints()
            box.Border = box:CreateTexture(nil, "BACKGROUND")
            box.Border:SetColorTexture(0, 0, 0, 1)
            box.Border:SetPoint("TOPLEFT", box, "TOPLEFT", -1, 1)
            box.Border:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 1, -1)
            display.numbers[bossIndex] = box:CreateFontString(nil, "OVERLAY")
            display.numbers[bossIndex]:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
            display.names[bossIndex] = box:CreateFontString(nil, "OVERLAY")
            display.names[bossIndex]:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
        end
    elseif not display.numbers then
        display.numbers = {}
        display.names = {}
        for bossIndex, box in ipairs(display.boxes) do
            display.numbers[bossIndex] = box:CreateFontString(nil, "OVERLAY")
            display.numbers[bossIndex]:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
            display.names[bossIndex] = box:CreateFontString(nil, "OVERLAY")
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

local function IsCoiledAltarInterruptUnit(self, unit)
    if unit ~= "boss3" and unit ~= "boss4" then return false end
    if not self.CoiledAltarInterruptAssignedBoss then return true end
    return unit == self.CoiledAltarInterruptAssignedBoss
end

local function SetCoiledAltarInterruptPhase(self, active)
    local alert = self.CoiledAltarInterruptAlert
    local alertLoad = alert and self:EvaluateLoad(alert)
    if active and (not alert or not alert.enabled or not alertLoad) then
        active = false
    end
    self.CoiledAltarInterruptActive = active
    self.CoiledAltarInterruptAssignedBoss = nil
    self.CoiledAltarInterruptCastCounts = {boss3 = 1, boss4 = 1}
    self.CoiledAltarInterruptCasting = {}
    if active then
        self.CoiledAltarInterruptFrame:Show()
        self:ReadInterruptNote(1)
        RefreshCoiledAltarInterruptNameplates(self)
        UpdateCoiledAltarInterruptMarker(self)
    end
    NSI:UpdateCoiledAltarInterruptDisplay()
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck({14, 15, 16})
    local diffData = id and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id]
    self.CoiledAltarInterruptAlert = diffData and diffData.InterruptAssignments
    local interruptAlertActive = self.CoiledAltarInterruptAlert and self.CoiledAltarInterruptAlert.enabled and self:EvaluateLoad(self.CoiledAltarInterruptAlert)
    if interruptAlertActive then
        self.CoiledAltarInterruptFrame = self.CoiledAltarInterruptFrame or CreateFrame("Frame")
        self:EncounterRegister("CoiledAltarInterruptAssignments", {"NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "RAID_TARGET_UPDATE", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"}, true)
        self:EncounterRegister("CoiledAltarInterruptAssignments", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, true, {"boss3", "boss4"})
        self:EncounterFunction("CoiledAltarInterruptAssignments", function(_, event, unit)
            if event == "NAME_PLATE_UNIT_ADDED" then
                AddCoiledAltarInterruptNameplate(self, unit)
            elseif event == "NAME_PLATE_UNIT_REMOVED" then
                RemoveCoiledAltarInterruptNameplate(self, unit)
            elseif event == "RAID_TARGET_UPDATE" then
                UpdateCoiledAltarInterruptMarker(self)
            elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
                if not UnitExists("boss3") then
                    SetCoiledAltarInterruptPhase(self, false)
                    return
                end
                UpdateCoiledAltarInterruptMarker(self)
            elseif event == "UNIT_SPELLCAST_START" then
                UpdateCoiledAltarInterruptMarker(self)
                if self.CoiledAltarInterruptActive and IsCoiledAltarInterruptUnit(self, unit) and UnitIsEnemy(unit, "player") then
                    self.CoiledAltarInterruptCasting[unit] = true
                    NSI:UpdateCoiledAltarInterruptDisplay()
                end
            elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
                UpdateCoiledAltarInterruptMarker(self)
                if self.CoiledAltarInterruptActive then
                    self.CoiledAltarInterruptCasting[unit] = nil
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
        self:EncounterRegister("CoiledAltarInterruptAssignments", {"NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "RAID_TARGET_UPDATE", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"}, false)
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
        SetCoiledAltarInterruptPhase(self, newphase == 2 or newphase == 3)
    end
end
