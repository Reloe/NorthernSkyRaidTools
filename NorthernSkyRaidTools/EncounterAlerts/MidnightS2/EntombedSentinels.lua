local _, NSI = ... -- Internal namespace

local encID = 3445
-- /run NSAPI:DebugEncounter(3445)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local healerConditions = self:DefaultLoadConditions()
    healerConditions.Roles.HEALER = true

    local data = {group = "Sentinels", internalID = "PoisonHits", name = "Poison Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        textColors = {1, 0, 0, 1}, spellID = 1284458,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] ={
                {6.4, 28.3},
                {6.4, 28.3, 51.4, 73.3},
                {6.4, 28.3, 51.4, 73.3},
                {6.4, 28.3, 51.4, 73.3},
                {6.4, 28.3, 51.4, 73.3},
            },
            [16] ={
                {6.4, 28.3},
                {6.4, 28.3, 51.4, 73.3},
                {6.4, 28.3, 51.4, 73.3},
                {6.4, 28.3, 51.4, 73.3},
                {6.4, 28.3, 51.4, 73.3},
            }
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Sentinels", internalID = "BloodHits", name = "Blood Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1}, spellID = 1284487,
        isConditional = {
            text = "This Alert only shows if you have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] ={
                {7.6, 29.5},
                {7.6, 29.5, 51.4, 73.3},
                {7.6, 29.5, 51.4, 73.3},
                {7.6, 29.5, 51.4, 73.3},
                {7.6, 29.5, 51.4, 73.3},
            },
            [16] ={
                {7.6, 29.5},
                {7.6, 29.5, 51.4, 73.3},
                {7.6, 29.5, 51.4, 73.3},
                {7.6, 29.5, 51.4, 73.3},
                {7.6, 29.5, 51.4, 73.3},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "BloodDropPool", name = "Tank Drop Pool", text = "Drop-Pool", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1284487, isSpecialDisplay = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return (threat and threat < 2) or not threat end]],
        },
        phaseTimers = {
            [15] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            },
            [16] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "BloodSoak", name = "Blood Soak", text = "Blood-Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        textColors = {1, 0.37, 0.25, 1}, spellID = 1288232,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss2.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss2") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {26.6},
                {26.6, 68.8},
                {26.6, 68.8},
                {26.6, 68.8},
                {26.6, 68.8},
            },
            [16] ={
                {26.6},
                {26.6, 68.8},
                {26.6, 68.8},
                {26.6, 68.8},
                {26.6, 68.8},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {dur = 6}}, group = "Sentinels", internalID = "BloodSoakPool", name = "Soak-Pool", text = "Drop Pool", DisplayType = "Circle", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0.37, 0.25, 1}, spellID = 1288232,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss2.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss2") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {32.6},
                {32.6, 74.8},
                {32.6, 74.8},
                {32.6, 74.8},
                {32.6, 74.8},
            },
            [16] ={
                {32.6},
                {32.6, 74.8},
                {32.6, 74.8},
                {32.6, 74.8},
                {32.6, 74.8},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "BloodDispels", name = "Blood Dispels", text = "Dispels", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        spellID = 1284471, loadConditions = healerConditions,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss2.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss2") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {45},
                {45},
                {45},
                {45},
                {45},
            },
            [16] ={
                {45},
                {45},
                {45},
                {45},
                {45},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "PoisonAdd", name = "Poison Add", text = "Poison Add", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {0.62, 1, 0.25, 1}, spellID = 1284251,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss1.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss1") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {15.7},
                {15.7, 68},
                {15.7, 68},
                {15.7, 68},
                {15.7, 68},
            },
            [16] ={
                {13.7},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {text = "Orbs", dur = 8}}, group = "Sentinels", internalID = "OrbSpawn", name = "Orb Spawn", text = "Bait Orbs", DisplayType = "Text", encID = encID, phase = 1, TTS = "Bait", dur = 6,
        spellID = 1284434,
        phaseTimers = {
            [15] ={
                {17.2},
                {17.2, 50},
                {17.2, 50},
                {17.2, 50},
                {17.2, 50},
            },
            [16] ={
                {17.2},
                {17.2, 47, 79.4},
                {17.2, 47, 79.4},
                {17.2, 47, 79.4},
                {17.2, 47, 79.4},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "ShiftingProtovenom", name = "Shifting Protovenom", text = "Spread", DisplayType = "Circle", encID = encID, phase = 1, TTS = "Spread", dur = 6,
        spellID = 1296878,
        phaseTimers = {
            [16] ={
                {37.2},
                {42, 82},
                {42, 82},
                {42, 82},
                {42, 82},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "TransitionDebuffs", name = "Transition Debuffs", text = "Number Game", DisplayType = "Circle", encID = encID, phase = 1, TTS = "Spread", dur = 8,
        spellID = 1284590,
        phaseTimers = {
            [15] ={
                {46.2},
                {91},
                {91},
                {91},
                {91},
            },
            [16] ={
                {46.2},
                {91},
                {91},
                {91},
                {91},
            }
        },
    }
    self:AddEncounterAlert(data)

    local RadarPreview = [[
        return function(self)
            if self.SentinelsRadarPreview then
                self.EncounterAlertStop[3445](self)
            else
                self.EncounterAlertStart[3445](self, 16, "Radar")
            end
        end
    ]]

    local data = {group = "Sentinels", internalID = "Radar", name = "Radar", text = nil, DisplayType = "Text", encID = encID, phase = nil, TTS = false, dur = 5,
        spellID = nil, id = 0, difficulties = {14, 15, 16}, enabled = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, Preview = RadarPreview,
        customIcon = 1284500,
        Scale = 1, Anchor = "CENTER", relativeTo = "CENTER", xOffset = 0, yOffset = 250, FontSize = 20, SafeDistance = 40, UpdateInterval = 0.1,
        BackgroundColor = {0.06, 0.06, 0.06, 0.9}, BorderColor = {0, 0, 0, 1}, TickColor = {0.13, 0.85, 0.13, 1},
        FarColor = {0.13, 1, 0.13, 1}, NearColor = {1, 0.1, 0.1, 1},
        extraOptions = {
            { Type = "Label", text = "Radar" },
            { Type = "Slider", label = "Scale", min = 0.5, max = 3, step = 0.05, decimals = 2, usedecimals = true,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3445][16].Radar.Scale or 1 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.Scale = v end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Slider", label = "xOffset", min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3445][16].Radar.xOffset or 0 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.xOffset = v end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Slider", label = "yOffset", min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3445][16].Radar.yOffset or 250 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.yOffset = v end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Slider", label = "FontSize", min = 8, max = 60,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3445][16].Radar.FontSize or 20 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.FontSize = v end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Slider", label = "SafeDistance", min = 5, max = 45, step = 1,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3445][16].Radar.SafeDistance or 40 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.SafeDistance = v end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]],
                tooltip = {title = "SafeDistance", desc = "Distance in yards at which a boss' number turns from the close color to the far color."}},
            { Type = "Slider", label = "UpdateInterval", min = 0.05, max = 1, step = 0.05, decimals = 2, usedecimals = true,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3445][16].Radar.UpdateInterval or 0.1 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.UpdateInterval = v end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]],
                tooltip = {title = "UpdateInterval", desc = "Seconds between distance refreshes. Lower is smoother but costs more CPU."}},
            { Type = "Color", label = "TickColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3445][16].Radar.TickColor or {0.13,0.85,0.13,1} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.TickColor = {r,g,b,a} end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Color", label = "FarColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3445][16].Radar.FarColor or {0.13,1,0.13,1} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.FarColor = {r,g,b,a} end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Color", label = "NearColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3445][16].Radar.NearColor or {1,0.1,0.1,1} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.NearColor = {r,g,b,a} end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Color", label = "BackgroundColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3445][16].Radar.BackgroundColor or {0.06,0.06,0.06,0.9} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.BackgroundColor = {r,g,b,a} end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
            { Type = "Color", label = "BorderColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3445][16].Radar.BorderColor or {0,0,0,1} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3445][i].Radar.BorderColor = {r,g,b,a} end NSI.EncounterAlertStop[3445](NSI) NSI.EncounterAlertStart[3445](NSI, 16, "Radar") end]]},
        },
    }
    self:AddEncounterAlert(data)
end

local function GetIntermissionTime(self, id)
    local diffTable = NSRT.EncounterAlerts[encID] and (NSRT.EncounterAlerts[encID][id] or NSRT.EncounterAlerts[encID][15])
    local alert = diffTable and diffTable.TransitionDebuffs
    local timers = alert and alert.phaseTimers and alert.phaseTimers[self.Phase or 1]
    return timers and timers[1]
end

local function CreateRadarFrame(self)
    if self.SentinelsRadarFrame then return self.SentinelsRadarFrame end
    local F = CreateFrame("Frame", "NSRTSentinelsRadar", self.NSRTFrame, "BackdropTemplate")
    F:SetSize(96, 124)
    F:SetFrameStrata("MEDIUM")
    F:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8X8]],
        edgeFile = [[Interface\Buttons\WHITE8X8]],
        edgeSize = 1,
    })

    local radarCircleTexture = [[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_filled.png]]

    F.Ring = F:CreateTexture(nil, "ARTWORK")
    F.Ring:SetTexture(radarCircleTexture)
    F.Ring:SetSize(84, 84)
    F.Ring:SetPoint("TOP", F, "TOP", 0, -6)
    F.Ring:SetVertexColor(0, 0, 0, 0.85)

    F.Swipe = CreateFrame("Cooldown", nil, F, "CooldownFrameTemplate")
    F.Swipe:SetAllPoints(F.Ring)
    F.Swipe:SetDrawBling(false)
    F.Swipe:SetDrawEdge(false)
    F.Swipe:SetReverse(false)
    F.Swipe:SetHideCountdownNumbers(true)
    F.Swipe:SetSwipeTexture(radarCircleTexture)

    F.Boss1 = F:CreateFontString(nil, "OVERLAY")
    F.Boss1:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 6, 5)
    F.Boss1:SetJustifyH("LEFT")

    F.Boss2 = F:CreateFontString(nil, "OVERLAY")
    F.Boss2:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -6, 5)
    F.Boss2:SetJustifyH("RIGHT")

    self.SentinelsRadarFrame = F
    return F
end

local function ApplyRadarSettings(self, F, s)
    F:ClearAllPoints()
    F:SetFrameStrata("MEDIUM")
    F:SetScale(s.Scale or 1)
    F:SetPoint(s.Anchor or "CENTER", self.NSRTFrame, s.relativeTo or "CENTER", s.xOffset or 0, s.yOffset or 250)
    F:SetBackdropColor(unpack(s.BackgroundColor or {0.06, 0.06, 0.06, 0.9}))
    F:SetBackdropBorderColor(unpack(s.BorderColor or {0, 0, 0, 1}))
    F.Swipe:SetSwipeColor(unpack(s.TickColor or {0.13, 0.85, 0.13, 1}))
    local font = self:GetGlobalFontPath()
    F.Boss1:SetFont(font, s.FontSize or 20, "OUTLINE")
    F.Boss2:SetFont(font, s.FontSize or 20, "OUTLINE")
end

local function UpdateRadarText(self, fontString, unit, s)
    local minRange, maxRange
    if self.SentinelsRadarPreview then
        minRange = unit == "boss1" and 15 or 40
    else
        minRange, maxRange = NSAPI:GetRange(unit)
    end
    if not minRange then
        if not maxRange then
            fontString:SetText("--")
            fontString:SetTextColor(0.6, 0.6, 0.6, 1)
            return
        end
        minRange = 0
    end
    fontString:SetText(math.floor(minRange))
    if minRange >= (s.SafeDistance or 40) then
        fontString:SetTextColor(unpack(s.FarColor or {0.13, 1, 0.13, 1}))
    else
        fontString:SetTextColor(unpack(s.NearColor or {1, 0.1, 0.1, 1}))
    end
end

local function StopRadar(self)
    if self.SentinelsRadarTicker then
        self.SentinelsRadarTicker:Cancel()
        self.SentinelsRadarTicker = nil
    end
    if self.SentinelsRadarHideTimer then
        self.SentinelsRadarHideTimer:Cancel()
        self.SentinelsRadarHideTimer = nil
    end
    if self.SentinelsRadarFrame then
        self.SentinelsRadarFrame:SetScript("OnUpdate", nil)
        self.SentinelsRadarFrame:Hide()
    end
end

local function StartRadar(self, id, preview)
    if not preview and self.SentinelsRadarPreview then return end
    local diffTable = id and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id]
    local s = diffTable and diffTable.Radar
    if not s then return end
    if not preview and not (s.enabled and self:EvaluateLoad(s)) then return end
    StopRadar(self)

    local F = CreateRadarFrame(self)
    ApplyRadarSettings(self, F, s)
    UpdateRadarText(self, F.Boss1, "boss1", s)
    UpdateRadarText(self, F.Boss2, "boss2", s)
    F.RadarElapsed = 0
    local updateInterval = s.UpdateInterval or 0.1
    F:SetScript("OnUpdate", function(frame, elapsed)
        frame.RadarElapsed = frame.RadarElapsed + elapsed
        if frame.RadarElapsed < updateInterval then return end
        frame.RadarElapsed = 0
        UpdateRadarText(self, frame.Boss1, "boss1", s)
        UpdateRadarText(self, frame.Boss2, "boss2", s)
    end)
    F:Show()

    local radarTickDurationSeconds = 5
    F.Swipe:SetCooldown(GetTime(), radarTickDurationSeconds)
    self.SentinelsRadarTicker = C_Timer.NewTicker(radarTickDurationSeconds, function()
        F.Swipe:SetCooldown(GetTime(), radarTickDurationSeconds)
    end)

    if not preview then
        local hideAt = GetIntermissionTime(self, id)
        if hideAt then
            self.SentinelsRadarHideTimer = C_Timer.NewTimer(hideAt, function() StopRadar(self) end)
        end
    end
    return s
end

local function StartRadarPreview(self, id)
    self.SentinelsRadarPreview = true
    local s = StartRadar(self, id, true)
    if s then self:MakeDraggable(self.SentinelsRadarFrame, s, true) end
end

local function StopRadarPreview(self)
    if not self.SentinelsRadarPreview then return end
    self.SentinelsRadarPreview = false
    if self.SentinelsRadarFrame then
        self:MakeDraggable(self.SentinelsRadarFrame, nil, false)
    end
end

local function ScheduleBloodHitThreatCheck(self)
    if self.BloodHitThreatTimer then self.BloodHitThreatTimer:Cancel() end

    local difficultyID = self:DifficultyCheck({15, 16})
    local alert = difficultyID and NSRT.EncounterAlerts[encID][difficultyID] and NSRT.EncounterAlerts[encID][difficultyID].BloodDropPool
    local timers = alert and alert.phaseTimers and alert.phaseTimers[self.Phase or 1]
    local timetocheck = timers and timers[#timers] -- only check last timer
    if not timetocheck then return end

    self.BloodHitThreatTimer = C_Timer.NewTimer(timetocheck, function()
        local threat = UnitThreatSituation("player", "boss2")
        if threat and threat >= 2 then
            self.BloodHitTimer = GetTime()
            self.BloodHitPhase = self.Phase
            if self.BloodHitPoolTimer then self.BloodHitPoolTimer:Cancel() end
            self.BloodHitPoolTimer = C_Timer.NewTimer(40, function()
                if self.EncounterID ~= encID or self.Phase ~= self.BloodHitPhase then return end
                alert = CopyTable(alert)
                alert.phase = self.Phase
                alert.phaseTimers = nil
                alert.isSpecialDisplay = nil
                self:DisplayReminder(alert)
                self.BloodHitTimer = nil
                self.BloodHitPhase = nil
            end)
        else
            self.BloodHitTimer = nil
            self.BloodHitPhase = nil
        end
    end)
end

local function AddBloodHitPoolTimer(self, now)
    if self.BloodHitPoolTimer then
        self.BloodHitPoolTimer:Cancel()
        self.BloodHitPoolTimer = nil
    end
    local bloodHitTimer = self.BloodHitTimer
    self.BloodHitTimer = nil
    self.BloodHitPhase = nil

    local difficultyID = self:DifficultyCheck({15, 16})
    local alert = difficultyID and NSRT.EncounterAlerts[encID][difficultyID] and NSRT.EncounterAlerts[encID][difficultyID].BloodDropPool
    if not alert or not alert.enabled or not self:EvaluateLoad(alert) then return end

    if bloodHitTimer then
        local diff = 40 - (now - bloodHitTimer)
        if diff > 0 then
            alert = CopyTable(alert)
            alert.phase = self.Phase
            alert.time = diff
            alert.phaseTimers = nil
            alert.isSpecialDisplay = nil
            self:AddToReminder(alert) -- add alert for the new phase
        end
    end
end

NSI.EncounterAlertStart[encID] = function(self, previewID, preview)
    if previewID and preview == "Radar" then
        StartRadarPreview(self, previewID)
        return
    end

    self.BloodHitTimer = nil
    self.BloodHitPhase = nil
    if self.BloodHitPoolTimer then
        self.BloodHitPoolTimer:Cancel()
        self.BloodHitPoolTimer = nil
    end
    local id = self:DifficultyCheck({15, 16})
    local DropPool = id and NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].BloodDropPool
    if DropPool and DropPool.enabled and self:EvaluateLoad(DropPool) then
        ScheduleBloodHitThreatCheck(self)
    end

    StopRadarPreview(self)
    StartRadar(self, self:DifficultyCheck({14, 15, 16}))
end

NSI.EncounterAlertStop[encID] = function(self)
    if self.BloodHitThreatTimer then self.BloodHitThreatTimer:Cancel() end
    if self.BloodHitPoolTimer then self.BloodHitPoolTimer:Cancel() end
    self.BloodHitTimer = nil
    self.BloodHitPhase = nil
    self.BloodHitPoolTimer = nil

    StopRadarPreview(self)
    StopRadar(self)
end

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end

    table.insert(self.Timelines, now)

    local addedcount = 0
    for _, timestamp in ipairs(self.Timelines) do
        if now < timestamp + 0.3 then addedcount = addedcount + 1 end
    end
    if addedcount >= 8 then
        self.Phase = self.Phase + 1
        AddBloodHitPoolTimer(self, now)
        self:StartReminders(self.Phase)
        ScheduleBloodHitThreatCheck(self)
        StartRadar(self, self:DifficultyCheck({14, 15, 16}))
        self.Timelines = {}
        self.PhaseSwapTime = now
    end
end
