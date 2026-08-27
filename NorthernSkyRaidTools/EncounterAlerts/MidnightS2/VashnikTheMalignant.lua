local _, NSI = ... -- Internal namespace

local encID = 3455
-- /run NSAPI:DebugEncounter(3455)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true
    local nontankConditions = self:DefaultLoadConditions()
    nontankConditions.Roles.HEALER = true
    nontankConditions.Roles.DAMAGER = true

    local data = {group = "Vashnik", internalID = "TankHits", name = "Tank-Hits", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1}, loadConditions = tankConditions, spellID = 1280935,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        timers = {
            [15] = {10.1, 39.1, 66.1, 94.1, 123.1, 150.1, 178.1, 207.1, 234.1, 262.1, 291.1, 318.1, 346.1, 375.1, 402.1, 430.1, 459.1},
            [16] = {10, 39, 66, 94, 123.1, 150.1, 178.1, 207.1, 234.1, 262.1, 291.1, 318.1, 346.1, 375.1, 402.1, 430.1, 459.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Taunts", name = "Taunt", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 6, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
        },
        timers = {
            [15] = {10.6, 39.6, 66.6, 94.6, 123.6, 150.6, 178.6, 207.6, 234.6, 262.6, 291.6, 318.6, 346.6, 375.6, 402.6, 430.6, 459.6},
            [16] = {10.5, 39.5, 66.5, 94.5, 123.6, 150.6, 178.6, 207.6, 234.6, 262.6, 291.6, 318.6, 346.6, 375.6, 402.6, 430.6, 459.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Adds", name = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = 1284663,
        timers = {
            [16] = {24, 108, 192, 276.1, 360.1, 444.1, 462.1, 473, 483.1},
            [16] = {24, 108, 192, 276.1, 360.1, 444.1, 462.1, 473, 483.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Infection", name = "Infection", text = "Infection", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282114,
        timers = {
            [15] = {42.3, 95, 126, 171, 210.3, 263, 294.6, 347, 378.1, 431, 462.3},
            [16] = {42.4, 94.3, 126.3, 178.3, 210.4, 262.6, 294.4, 346.5, 378.6, 430.6, 462.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "AoE", name = "AoE", text = "AoE", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282516,
        timers = {
            [15] = {35, 74, 119.1, 158, 203.1, 242.1, 287.1, 326.1, 371.1, 410.2, 455.2},
            [16] = {35, 74, 119, 158.1, 203.1, 242.1, 287.1, 326.1, 371.1, 410.2, 455.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Soaks", name = "Soaks", text = "Soaks", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1282602,
        timers = {
            [15] = {42, 81, 126.1, 165, 210.1, 249.1, 294.1, 333.1, 378.1, 417.2, 462.2},
            [16] = {42, 81, 126, 165.1, 210.1, 249.1, 294.1, 333.1, 378.1, 417.2, 462.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Vashnik", internalID = "Waves", name = "Waves", text = "Waves", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1281908,
        timers = {
            [15] = {21, 62, 95, 146, 179, 230, 263, 314, 347, 398, 431, 482},
            [16] = {19, 60.1, 93.1, 144.1, 177.1, 228.1, 261.1, 312.1, 345.1, 396.1, 429.1, 480.1},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Vashnik", internalID = "WaveSpread", name = "Wave-Spread", text = "Pre-Spread", DisplayType = "Circle", encID = encID, phase = 1, TTS = "Spread", dur = 6, spellID = 1281908,
        loadConditions = nontankConditions,
        timers = {
            [15] = {13, 54, 87, 138, 171, 222, 255, 306, 339, 390, 423, 474},
            [16] = {13, 54.1, 87.1, 138.1, 171.1, 222.1, 255.1, 306.1, 339.1, 390.1, 423.1, 474.1},
        },
    }
    self:AddEncounterAlert(data)

    local VashnikWavesLinePreview = [[return function(NSI)
        print(NSI:Loc("|cFF00FFFFNSRT:|r this alert has no preview. It is timer-driven and displays a rotating-minimap-aligned cross during the Vashnik wave windows."))
    end]]
    local data = {Version = {versionNumber = 1, [1] = {difficulties = {16}, loadConditions = nontankConditions, enabled = false}}, group = "Vashnik", internalID = "WavesLine", name = "Waves Line", text = "", DisplayType = "Text", encID = encID,
        difficulties = {16}, enabled = false, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, Preview = VashnikWavesLinePreview, loadConditions = nontankConditions,
        ShowEntireFight = false,
        extraOptions = {
            { Type = "Checkbox", label = "Show Entire Fight",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3455][16].WavesLine.ShowEntireFight end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3455][16].WavesLine.ShowEntireFight = value NSI.EncounterAlertStop[3455](NSI) NSI.EncounterAlertStart[3455](NSI, 16, "Waves Line") end]],
            },
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id)
    id = id or self:DifficultyCheck({16})
    local alert = id and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].WavesLine
    local spreadAlert = id and NSRT.EncounterAlerts[encID][id].WaveSpread
    local wavesAlert = id and NSRT.EncounterAlerts[encID][id].Waves
    if not alert or not alert.enabled or not self:EvaluateLoad(alert) then return end
    if not alert.ShowEntireFight and (not spreadAlert or not wavesAlert) then return end

    if self.VashnikWavesLineTimers then
        for _, timer in ipairs(self.VashnikWavesLineTimers) do timer:Cancel() end
    end
    self.VashnikWavesLineTimers = {}

    if not self.VashnikWavesLineFrame then
        self.VashnikWavesLineFrame = CreateFrame("Frame", nil, self.NSRTFrame)
        self.VashnikWavesLineFrame:Hide()
        self.VashnikWavesLineFrame:SetAllPoints(self.NSRTFrame)
        self.VashnikWavesLineFrame:SetFrameStrata("HIGH")
        local rotationUpdateElapsed = 0
        self.VashnikWavesLineFrame:SetScript("OnUpdate", function(_, elapsed)
            rotationUpdateElapsed = rotationUpdateElapsed + elapsed
            if rotationUpdateElapsed < (1 / 60) then return end
            rotationUpdateElapsed = 0
            local rotation = MinimapCompassTexture:GetRotation()
            self.VashnikWavesLineHorizontal:SetRotation(rotation)
            self.VashnikWavesLineVertical:SetRotation(rotation)
        end)

        local lineLength = math.sqrt(UIParent:GetWidth() ^ 2 + UIParent:GetHeight() ^ 2)
        self.VashnikWavesLineHorizontal = self.VashnikWavesLineFrame:CreateTexture(nil, "OVERLAY")
        self.VashnikWavesLineHorizontal:SetColorTexture(0, 1, 0, 1)
        self.VashnikWavesLineHorizontal:SetPoint("CENTER")
        self.VashnikWavesLineHorizontal:SetSize(lineLength, 2)

        self.VashnikWavesLineVertical = self.VashnikWavesLineFrame:CreateTexture(nil, "OVERLAY")
        self.VashnikWavesLineVertical:SetColorTexture(0, 1, 0, 1)
        self.VashnikWavesLineVertical:SetPoint("CENTER")
        self.VashnikWavesLineVertical:SetSize(2, lineLength)
    end

    local function hideWavesLine()
        self.VashnikWavesLineFrame:Hide()
        if self.VashnikWavesLinePreviousRotateMinimap then
            MinimapCluster:SetRotateMinimap(self.VashnikWavesLinePreviousRotateMinimap == "1")
            self.VashnikWavesLinePreviousRotateMinimap = nil
        end
    end

    local function showWavesLine()
        if not self.VashnikWavesLinePreviousRotateMinimap then
            self.VashnikWavesLinePreviousRotateMinimap = GetCVar("rotateMinimap")
        end
        MinimapCluster:SetRotateMinimap(true)
        C_Timer.After(0, function()
            if self.EncounterID == encID then
                self.VashnikWavesLineFrame:Show()
            end
        end)
    end

    hideWavesLine()

    if alert.ShowEntireFight then
        showWavesLine()
        return
    end

    for index, spreadTime in ipairs(spreadAlert.timers or {}) do
        local waveTime = wavesAlert.timers and wavesAlert.timers[index]
        if waveTime then
            self.VashnikWavesLineTimers[#self.VashnikWavesLineTimers + 1] = C_Timer.NewTimer(math.max(0, spreadTime - 8), function()
                if self.EncounterID == encID then showWavesLine() end
            end)
            self.VashnikWavesLineTimers[#self.VashnikWavesLineTimers + 1] = C_Timer.NewTimer(waveTime, function()
                if self.EncounterID == encID then hideWavesLine() end
            end)
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self)
    if self.VashnikWavesLineTimers then
        for _, timer in ipairs(self.VashnikWavesLineTimers) do timer:Cancel() end
        self.VashnikWavesLineTimers = nil
    end
    if self.VashnikWavesLineFrame then
        self.VashnikWavesLineFrame:Hide()
    end
    if self.VashnikWavesLinePreviousRotateMinimap then
        MinimapCluster:SetRotateMinimap(self.VashnikWavesLinePreviousRotateMinimap == "1")
        self.VashnikWavesLinePreviousRotateMinimap = nil
    end
end
