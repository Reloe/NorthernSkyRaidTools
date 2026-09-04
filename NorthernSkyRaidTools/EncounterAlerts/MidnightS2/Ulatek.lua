local _, NSI = ... -- Internal namespace

local encID = 3492
-- /run NSAPI:DebugEncounter(3492)

local GRASPING_FANGS_LEFT = "UlatekGraspingFangsLeftSide"
local GRASPING_FANGS_RIGHT = "UlatekGraspingFangsRightSide"
local ulatekWaveLineTimes = {}
local ulatekWaveLineDuration = 10
local transitionSoakTimes = {337, 339, 343, 345, 349, 351, 353, 355}
local transitionPatterns = {
    CHAT_MSG_YELL = {7, 3, 4, 2, 8, 6, 1, 5},
    CHAT_MSG_RAID = {1, 3, 6, 8, 4, 2, 7, 5},
    CHAT_MSG_RAID_LEADER = {1, 3, 6, 8, 4, 2, 7, 5},
    CHAT_MSG_RAID_WARNING = {4, 2, 7, 5, 1, 3, 6, 8},
}
local transitionGroupMarkers = {
    CHAT_MSG_YELL = {{7, 2, 1}, {3, 8, 5}, {4, 6}},
    CHAT_MSG_RAID = {{1, 2, 8}, {4, 3, 5}, {7, 6}},
    CHAT_MSG_RAID_LEADER = {{1, 2, 8}, {4, 3, 5}, {7, 6}},
    CHAT_MSG_RAID_WARNING = {{1, 2, 8}, {4, 3, 5}, {7, 6}},
}
local transitionMarkerAngles = {[2] = math.pi / 8, [8] = math.pi * 0.375, [5] = math.pi * 0.625, [3] = math.pi * 0.875, [4] = math.pi * 1.125, [6] = math.pi * 1.375, [7] = math.pi * 1.625, [1] = math.pi * 1.875}
local transitionMarkerTexCoords = {}
for marker, angle in pairs(transitionMarkerAngles) do
    local cosine = math.cos(angle)
    local sine = math.sin(angle)
    local upperLeftX, upperLeftY = 0.5 - (0.5 * cosine) + (0.5 * sine), 0.5 - (0.5 * sine) - (0.5 * cosine)
    local lowerLeftX, lowerLeftY = 0.5 - (0.5 * cosine) - (0.5 * sine), 0.5 - (0.5 * sine) + (0.5 * cosine)
    local upperRightX, upperRightY = 0.5 + (0.5 * cosine) + (0.5 * sine), 0.5 + (0.5 * sine) - (0.5 * cosine)
    local lowerRightX, lowerRightY = 0.5 + (0.5 * cosine) - (0.5 * sine), 0.5 + (0.5 * sine) + (0.5 * cosine)
    transitionMarkerTexCoords[marker] = {upperLeftX, upperLeftY, lowerLeftX, lowerLeftY, upperRightX, upperRightY, lowerRightX, lowerRightY}
end

function NSI:PreviewUlatekWaveLines()
    if self.UlatekWaveLinesIsPreview then
        NSI.EncounterAlertStop[encID](self)
        return
    end
    NSI.EncounterAlertStart[encID](self, 16, true)
end

local function GetGraspingFangsAlert()
    local diffData = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][16]
    return diffData and diffData.GraspingFangsOverview
end

-- Each side gets its own subgroup string like "1,2"/"3,4" or "1,3,5,7"/"2,4,6,8"
local function ParseGroupList(text)
    local subgroups = {}
    for value in tostring(text or ""):gmatch("%d+") do
        subgroups[#subgroups + 1] = tonumber(value)
    end
    return subgroups
end

local function StopUlatekWaveDirection(self)
    self:EncounterRegister("UlatekWaveDirection", {"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER"}, false)
    self.UlatekWaveDirectionListening = false
    if self.UlatekWaveDirectionTimers then
        for _, timer in ipairs(self.UlatekWaveDirectionTimers) do
            timer:Cancel()
        end
        self.UlatekWaveDirectionTimers = nil
    end
end

local function StopUlatekWaveLines(self)
    self.UlatekWaveLinesIsPreview = false
    if self.UlatekWaveLinesTimers then
        for _, timer in ipairs(self.UlatekWaveLinesTimers) do
            timer:Cancel()
        end
        self.UlatekWaveLinesTimers = nil
    end
    if self.UlatekWaveLinesFrame then
        self.UlatekWaveLinesFrame:Hide()
    end
    if self.UlatekWaveLinesPreviousRotateMinimap then
        C_CVar.SetCVar("rotateMinimap", self.UlatekWaveLinesPreviousRotateMinimap)
        MinimapCluster:SetRotateMinimap(self.UlatekWaveLinesPreviousRotateMinimap == "1")
        self.UlatekWaveLinesPreviousRotateMinimap = nil
    end
end

local function StartUlatekWaveLines(self, alert, isPreview)
    isPreview = isPreview == true
    StopUlatekWaveLines(self)
    if not alert or (not isPreview and (not alert.enabled or not self:EvaluateLoad(alert))) then return end

    self.UlatekWaveLinesIsPreview = isPreview
    if isPreview then
        self.UlatekWaveLinesPreviewToken = (self.UlatekWaveLinesPreviewToken or 0) + 1
    end
    self.UlatekWaveLinesTimers = {}

    if not self.UlatekWaveLinesFrame then
        local frame = CreateFrame("Frame", nil, self.NSRTFrame)
        frame:SetAllPoints(self.NSRTFrame)
        frame:SetFrameStrata("HIGH")
        frame:Hide()
        local texture = frame:CreateTexture(nil, "OVERLAY")
        texture:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\UlatekWaveLines.png]])
        texture:SetPoint("CENTER")
        local lineLength = math.sqrt(UIParent:GetWidth() ^ 2 + UIParent:GetHeight() ^ 2)
        texture:SetSize(lineLength, lineLength)
        local rotationUpdateElapsed = 0
        frame:SetScript("OnUpdate", function(_, elapsed)
            rotationUpdateElapsed = rotationUpdateElapsed + elapsed
            if rotationUpdateElapsed < (1 / 60) then return end
            rotationUpdateElapsed = 0
            texture:SetRotation(MinimapCompassTexture:GetRotation())
        end)
        self.UlatekWaveLinesFrame = frame
    end

    local function hideWaveLines()
        self.UlatekWaveLinesFrame:Hide()
        if self.UlatekWaveLinesPreviousRotateMinimap then
            C_CVar.SetCVar("rotateMinimap", self.UlatekWaveLinesPreviousRotateMinimap)
            MinimapCluster:SetRotateMinimap(self.UlatekWaveLinesPreviousRotateMinimap == "1")
            self.UlatekWaveLinesPreviousRotateMinimap = nil
        end
    end

    local function showWaveLines()
        if not self.UlatekWaveLinesPreviousRotateMinimap then
            self.UlatekWaveLinesPreviousRotateMinimap = GetCVar("rotateMinimap")
        end
        C_CVar.SetCVar("rotateMinimap", "1")
        MinimapCluster:SetRotateMinimap(true)
        local previewToken = self.UlatekWaveLinesPreviewToken
        C_Timer.After(0, function()
            if (not isPreview or (self.UlatekWaveLinesIsPreview and self.UlatekWaveLinesPreviewToken == previewToken))
                and (isPreview or self.EncounterID == encID) then
                self.UlatekWaveLinesFrame:Show()
            end
        end)
    end

    if isPreview then
        showWaveLines()
        local previewToken = self.UlatekWaveLinesPreviewToken
        self.UlatekWaveLinesTimers[#self.UlatekWaveLinesTimers + 1] = C_Timer.NewTimer(ulatekWaveLineDuration, function()
            if self.UlatekWaveLinesIsPreview and self.UlatekWaveLinesPreviewToken == previewToken then
                StopUlatekWaveLines(self)
            end
        end)
        return
    end

    for _, waveTime in ipairs(ulatekWaveLineTimes) do
        self.UlatekWaveLinesTimers[#self.UlatekWaveLinesTimers + 1] = C_Timer.NewTimer(math.max(0, waveTime - ulatekWaveLineDuration), function()
            if self.EncounterID == encID then showWaveLines() end
        end)
        self.UlatekWaveLinesTimers[#self.UlatekWaveLinesTimers + 1] = C_Timer.NewTimer(waveTime, function()
            if self.EncounterID == encID then hideWaveLines() end
        end)
    end
end

local function RestoreUlatekTransitionMinimapRotation(self)
    local previousRotation = self.UlatekTransitionPreviousRotateMinimap
    if not previousRotation then return end
    C_CVar.SetCVar("rotateMinimap", previousRotation)
    MinimapCluster:SetRotateMinimap(previousRotation == "1")
    self.UlatekTransitionPreviousRotateMinimap = nil
end

local function StopUlatekTransition(self)
    self:EncounterRegister("UlatekTransitionPattern", {"CHAT_MSG_YELL", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING"}, false)
    self.UlatekTransitionListening = false
    if self.UlatekTransitionTimers then
        for _, timer in ipairs(self.UlatekTransitionTimers) do
            timer:Cancel()
        end
        self.UlatekTransitionTimers = nil
    end
    if self.UlatekTransitionArrowFrame then
        if self.UlatekTransitionArrowFrame.IsPreview then self:MakeDraggable(self.UlatekTransitionArrowFrame, nil, false) end
        self.UlatekTransitionArrowFrame.IsPreview = false
        self.UlatekTransitionArrowFrame.PreviewToken = (self.UlatekTransitionArrowFrame.PreviewToken or 0) + 1
        self.UlatekTransitionArrowFrame:Hide()
    end
    RestoreUlatekTransitionMinimapRotation(self)
end

local function EnableUlatekTransitionMinimapRotation(self)
    if not self.UlatekTransitionPreviousRotateMinimap then
        self.UlatekTransitionPreviousRotateMinimap = GetCVar("rotateMinimap")
    end
    if GetCVar("rotateMinimap") ~= "1" then
        C_CVar.SetCVar("rotateMinimap", "1")
    end
    MinimapCluster:SetRotateMinimap(true)
end

local function GetUlatekTransitionAssignments()
    local personal, shared = NSAPI:GetReminderString()
    local mrtNote = C_AddOns.IsAddOnLoaded("MRT") and _G.VMRT.Note.Text1 or ""
    local note = (shared or "").."\n"..(personal or "").."\n"..mrtNote
    local assignments = {}
    local inTransition = false
    local group = 0
    note = note:gsub("||r", ""):gsub("||c%x%x%x%x%x%x%x%x", "")
    for rawLine in note:gmatch("[^\r\n]+") do
        local line = strtrim(rawLine)
        if strlower(line) == "transitionstart" then
            inTransition = true
        elseif strlower(line) == "transitionend" then
            break
        elseif inTransition and line ~= "" then
            group = group + 1
            if group > 3 then break end
            for name in line:gmatch("%S+") do
                local unit = NSAPI:GetChar(name, true, "GlobalNickNames")
                if unit and UnitIsUnit(unit, "player") then
                    assignments[group] = true
                    break
                end
            end
        end
    end
    return assignments
end

local function CreateUlatekTransitionArrow(self)
    if self.UlatekTransitionArrowFrame then return self.UlatekTransitionArrowFrame end
    local frame = CreateFrame("Frame", nil, self.NSRTFrame)
    frame:SetSize(220, 220)
    frame:SetPoint("CENTER", self.NSRTFrame)
    frame:SetFrameStrata("HIGH")
    frame:Hide()
    frame.ArrowOutline = frame:CreateTexture(nil, "OVERLAY")
    frame.ArrowOutline:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\arrow-up.png]])
    frame.ArrowOutline:SetSize(180, 180)
    frame.ArrowOutline:SetVertexColor(0, 0, 0, 0.8)
    frame.ArrowOutline:SetPoint("CENTER")
    frame.Arrow = frame:CreateTexture(nil, "OVERLAY")
    frame.Arrow:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\arrow-up.png]])
    frame.Arrow:SetSize(160, 160)
    frame.Arrow:SetVertexColor(0.1, 0.9, 1, 1)
    frame.Arrow:SetPoint("CENTER")
    frame:SetScript("OnUpdate", function(_, elapsed)
        frame.UpdateElapsed = (frame.UpdateElapsed or 0) + elapsed
        if frame.UpdateElapsed < 1 / 60 then return end
        frame.UpdateElapsed = 0
        local rotation = MinimapCompassTexture:GetRotation()
        frame.ArrowOutline:SetRotation(rotation)
        frame.Arrow:SetRotation(rotation)
    end)
    self.UlatekTransitionArrowFrame = frame
    return frame
end

local function PositionUlatekTransitionArrow(self, frame, alert)
    frame:ClearAllPoints()
    frame:SetPoint(alert.Anchor or "CENTER", self.NSRTFrame, alert.relativeTo or "CENTER", alert.xOffset or 0, alert.yOffset or 0)
end

local function SetUlatekTransitionArrowMarker(frame, marker)
    frame.Marker = marker
    local texCoords = transitionMarkerTexCoords[marker]
    frame.ArrowOutline:SetTexCoord(unpack(texCoords))
    frame.Arrow:SetTexCoord(unpack(texCoords))
end

function NSI:PreviewUlatekTransitionArrow()
    local frame = CreateUlatekTransitionArrow(self)
    local alert = NSRT.EncounterAlerts[encID][16].TransitionPatternArrow
    if frame.IsPreview then
        frame.IsPreview = false
        frame.PreviewToken = (frame.PreviewToken or 0) + 1
        self:MakeDraggable(frame, nil, false)
        frame:Hide()
        RestoreUlatekTransitionMinimapRotation(self)
        return
    end

    EnableUlatekTransitionMinimapRotation(self)
    PositionUlatekTransitionArrow(self, frame, alert)
    SetUlatekTransitionArrowMarker(frame, math.random(1, 8))
    local rotation = MinimapCompassTexture:GetRotation()
    frame.ArrowOutline:SetRotation(rotation)
    frame.Arrow:SetRotation(rotation)
    frame.IsPreview = true
    self:MakeDraggable(frame, alert, true)
    frame.PreviewToken = (frame.PreviewToken or 0) + 1
    local previewToken = frame.PreviewToken
    frame:Show()
    C_Timer.After(15, function()
        if not frame.IsPreview or frame.PreviewToken ~= previewToken then return end
        frame.IsPreview = false
        self:MakeDraggable(frame, nil, false)
        frame:Hide()
        RestoreUlatekTransitionMinimapRotation(self)
    end)
end

function NSI:PreviewUlatekTransitionSoak()
    local marker = math.random(1, 8)
    local info = self:CreateReminder({
        text = NSI:EncounterAlertLoc("Soak").." {rt"..marker.."}",
        DisplayType = "Text",
        dur = 8,
        time = 8,
        encID = encID,
        phase = 1,
        TTS = false,
        IsAlert = false,
        ReloeReminder = true,
    }, true)
    if info then self:DisplayReminder(info, true) end
end

local function BuildGraspingFangsOverrides(alert, isLeftSide)
    local rightGroups = ParseGroupList(alert.RightGroups)
    local previewColumns = {{backgroundColors = alert.LeftBackgroundColor, inactiveColors = alert.LeftInactiveColor}}
    if #rightGroups > 0 then previewColumns[2] = {backgroundColors = alert.RightBackgroundColor, inactiveColors = alert.RightInactiveColor} end
    return {
        backgroundColors = isLeftSide and alert.LeftBackgroundColor or alert.RightBackgroundColor,
        inactiveColors = isLeftSide and alert.LeftInactiveColor or alert.RightInactiveColor,
        showInactive = alert.ShowAllPlayers ~= false,
        height = alert.BarHeight,
        subgroups = isLeftSide and ParseGroupList(alert.LeftGroups) or rightGroups,
        sortByRole = alert.SortByRole == true,
        backgroundOnly = true,
        hideValue = true,
        previewColumns = previewColumns,
    }
end

function NSI:UpdateUlatekGraspingFangsOverviews(alert)
    alert = alert or GetGraspingFangsAlert()
    if not alert then return end
    self:CreateDebuffOverviewContainers("HARMFUL|!PLAYER|!DISPELLABLE", {isBossAura = true}, 1, 1, GRASPING_FANGS_LEFT, false, true, false, 1, BuildGraspingFangsOverrides(alert, true))
    self:CreateDebuffOverviewContainers("HARMFUL|!PLAYER|!DISPELLABLE", {isBossAura = true}, 1, 1, GRASPING_FANGS_RIGHT, false, true, false, 1, BuildGraspingFangsOverrides(alert, false))
end

function NSI:SetUlatekGraspingFangsOverviewsShown(shown)
    self:SetDebuffOverviewContainersShown(shown, GRASPING_FANGS_LEFT)
    self:SetDebuffOverviewContainersShown(shown, GRASPING_FANGS_RIGHT)
end

function NSI:PreviewUlatekGraspingFangsOverviews()
    local alert = GetGraspingFangsAlert()
    if not alert then return end
    self:UpdateUlatekGraspingFangsOverviews(alert)
    self:PreviewDebuffOverviewContainers(nil, nil, nil, nil, GRASPING_FANGS_LEFT, false, true, false, 1, 6, BuildGraspingFangsOverrides(alert, true))
end

local function GetUlatekInterruptNames(self)
    return self.Interrupts and self.Interrupts.myTable or {}
end

local function GetUlatekInterruptFocusedBossUnit()
    for bossIndex = 2, 5 do
        local bossUnit = "boss"..bossIndex
        local isBoss = UnitIsUnit("focus", bossUnit)
        if issecretvalue(isBoss) then return end
        if isBoss then return bossUnit end
    end
end

local function HideUlatekInterruptDisplay(self)
    if self.UlatekInterruptNameplateBox then
        self.UlatekInterruptNameplateBox:Hide()
    end
end

function NSI:UpdateUlatekInterruptDisplay()
    local alert = self.UlatekInterruptAlert
    if not alert then return end
    if not GetUlatekInterruptFocusedBossUnit() then
        HideUlatekInterruptDisplay(self)
        return
    end
    if not self.Interrupts or self.Interrupts.disabled or self.Interrupts.myTrackedID == 0 then
        HideUlatekInterruptDisplay(self)
        return
    end

    local interruptNames = GetUlatekInterruptNames(self)
    local castCount = self.Interrupts and self.Interrupts.castCount or 1
    local currentName = #interruptNames > 0 and interruptNames[castCount] or nil
    local nextName = #interruptNames > 0 and interruptNames[castCount % #interruptNames + 1] or nil
    local interruptSettings = NSRT.InterruptSettings
    local boxSize = alert.BoxSize or 30
    local fontScale = boxSize / 30
    local numberFontSize = alert.NumberFontSize or interruptSettings.NumberFontSize
    local nameFontSize = alert.NameFontSize or interruptSettings.NameFontSize
    local boxColor = interruptSettings.InterruptDefaultColor
    local textColor = interruptSettings.InterruptDefaultTextColor
    if currentName and UnitIsUnit(currentName, "player") then
        boxColor = interruptSettings.InterruptNowColor
        textColor = interruptSettings.InterruptNowTextColor
    elseif nextName and UnitIsUnit(nextName, "player") then
        boxColor = interruptSettings.InterruptNextColor
        textColor = interruptSettings.InterruptNextTextColor
    end
    local displayName = currentName and NSAPI:Shorten(currentName, 12, false, "GlobalNickNames", true, false) or ""
    local boxAnchor, plateAnchor = "BOTTOM", "TOP"
    if alert.NameplateAnchor == "CENTER" then
        boxAnchor, plateAnchor = "CENTER", "CENTER"
    elseif alert.NameplateAnchor == "LEFT" then
        boxAnchor, plateAnchor = "RIGHT", "LEFT"
    elseif alert.NameplateAnchor == "RIGHT" then
        boxAnchor, plateAnchor = "LEFT", "RIGHT"
    elseif alert.NameplateAnchor == "BOTTOM" then
        boxAnchor, plateAnchor = "TOP", "BOTTOM"
    end

    local displays = {}
    local plate = C_NamePlate.GetNamePlateForUnit("focus")
    if plate and not alert.HideNameplateBox then
        if not self.UlatekInterruptNameplateBox then
            self.UlatekInterruptNameplateBox = self:CreateInterruptAssignmentDisplay(UIParent)
            self.UlatekInterruptNameplateBox:SetFrameStrata("HIGH")
            self.UlatekInterruptNameplateBox:SetFrameLevel(1)
        end
        local nameplateBox = self.UlatekInterruptNameplateBox
        nameplateBox:ClearAllPoints()
        nameplateBox:SetPoint(boxAnchor, plate, plateAnchor, alert.NameplateXOffset or 0, alert.NameplateYOffset or 0)
        nameplateBox:SetScale(self:GetInterruptNameplateScale(plate))
        displays[#displays + 1] = nameplateBox
    elseif self.UlatekInterruptNameplateBox then
        self.UlatekInterruptNameplateBox:Hide()
    end

    for _, box in ipairs(displays) do
        box.Background:SetColorTexture(unpack(boxColor))
        box.Number:SetTextColor(unpack(textColor))
        box.Number:SetText(castCount)
        box.Name:SetText(displayName)
        box:SetSize(boxSize, boxSize)
        box.Number:ClearAllPoints()
        box.Number:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
        box.Number:SetFont(self.LSM:Fetch("font", interruptSettings.NumberFont), numberFontSize * fontScale, interruptSettings.NumberFontFlags)
        box.Name:ClearAllPoints()
        box.Name:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
        box.Name:SetFont(self.LSM:Fetch("font", interruptSettings.NameFont), nameFontSize * fontScale, interruptSettings.NameFontFlags)
        box:Show()
    end
end

function NSI:PreviewUlatekInterruptDisplay()
    local alert = self.UlatekInterruptAlert or (NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][16] and NSRT.EncounterAlerts[encID][16].InterruptAssignments)
    if not alert then return false end

    self:ReadInterruptNote(1)
    local interruptNames = GetUlatekInterruptNames(self)
    local currentName = interruptNames[1]
    local nextName = interruptNames[2]
    local interruptSettings = NSRT.InterruptSettings
    local boxColor = interruptSettings.InterruptDefaultColor
    local textColor = interruptSettings.InterruptDefaultTextColor
    if currentName and UnitIsUnit(currentName, "player") then
        boxColor = interruptSettings.InterruptNowColor
        textColor = interruptSettings.InterruptNowTextColor
    elseif nextName and UnitIsUnit(nextName, "player") then
        boxColor = interruptSettings.InterruptNextColor
        textColor = interruptSettings.InterruptNextTextColor
    end
    local displayName = currentName and NSAPI:Shorten(currentName, 12, false, "GlobalNickNames", true, false) or NSAPI:Shorten("player", 12, false, "GlobalNickNames", true, false)

    return self:PreviewInterruptDisplay(1, displayName, boxColor, textColor)
end

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    for i = 14, 16 do
        self:RemoveEncounterAlert(encID, i, "TankDrag")
    end

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {Version = {versionNumber = 1, [1] = {dur = 10}}, group = "Ula'tek", internalID = "HitKnock", name = "Mother's Wrath", text = "Hit+Knock", DisplayType = "Text", encID = encID, TTS = "Knock", dur = 10, spellID = 1298367, phase = 1,
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

    local UlatekDamageAmpTimers = {
        [15] = {135.4, 284.5, 573.5},
        [16] = {135.4, 284.5, 573.5},
    }
    local data = {Version = {versionNumber = 2, [1] = {dur = 15}, [2] = {customIcon = 1299526}}, group = "Ula'tek", internalID = "DamageAmpIn", name = "Venomous Heart", text = "Dmg amp in", customIcon = 1299526, DisplayType = "Text", encID = encID, TTS = false, dur = 15, spellID = 1286860, phase = 1,
        timers = UlatekDamageAmpTimers,
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {customIcon = 1299526}}, group = "Ula'tek", internalID = "DamageAmp", name = "Venomous Heart", text = "Dmg amp", customIcon = 1299526, DisplayType = "Bar", encID = encID, TTS = false, dur = 20, spellID = 1299526, phase = 1,
        barColors = {1, 0, 0, 1},
        [15] = {155.4, 304.5, 597},
        [16] = {155.4, 304.5, 597},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "WrongTarget", name = "Wrong Target", text = "WRONG TARGET", DisplayType = "Text", encID = encID, TTS = false, dur = 20, sticky = 20, phase = 1,
        textColors = {1, 0, 0, 1}, HideTimer = true, isSpecialDisplay = true, BlockCopy = true,
        timers = UlatekDamageAmpTimers,
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {dur = 10}}, group = "Ula'tek", internalID = "PlatformBreak", name = "Circling Prey", text = "Platform Break", DisplayType = "Text", encID = encID, TTS = false, dur = 10, spellID = 1315341, phase = 1,
        timers = {
            [15] = {430.1, 481.2, 542.1},
            [16] = {430.1, 481.2, 542.1},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {dur = 8}}, group = "Ula'tek", internalID = "Debuffs", name = "Serpent's Bite", text = "Debuffs", DisplayType = "Text", encID = encID, TTS = false, dur = 8, spellID = 1288879, phase = 1,
        timers = {
            [15] = {392.7, 463.7, 500.6, 560.7},
            [16] = {392.7, 463.7, 500.6, 560.7},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {dur = 8}}, group = "Ula'tek", internalID = "Eggs", name = "Eggs", text = "Eggs", DisplayType = "Text", encID = encID, TTS = false, dur = 8, spellID = 1304012, phase = 1,
        timers = {
            [15] = {82, 319},
            [16] = {82, 319},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {dur = 8}}, group = "Ula'tek", internalID = "Adds", name = "P3 Adds", text = "Adds", DisplayType = "Text", encID = encID, TTS = true, dur = 8, spellID = 1300751,  phase = 1,
        timers = {
            [15] = {372.2, 402.1, 447.1, 507.2},
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

    local data = {Version = {versionNumber = 1, [1] = {dur = 8}}, group = "Ula'tek", internalID = "Soak", name = "Soak", text = "Soak", DisplayType = "Text", encID = encID, TTS = false, dur = 8, spellID = 1299010, phase = 1,
        timers = {
            [15] = {28, 30.4, 122.8, 125.6},
            [16] = {28, 30.4, 122.8, 125.6},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "TransitionSoakFirst", name = "First Soak", text = "First Soak", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1299010, phase = 1,
        textColors = {0, 1, 0, 1},
        difficulties = {15},
        timers = {
            [15] = {326.3, 334.5, 341.4},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "TransitionSoakSecond", name = "Second Soak", text = "Second Soak", DisplayType = "Text", encID = encID, TTS = false, dur = 5, spellID = 1299010, phase = 1,
        textColors = {1, 0, 0, 1},
        difficulties = {15},
        timers = {
            [15] = {329.6, 337.3, 344.6},
        },
    }
    self:AddEncounterAlert(data)

    function NSI:PreviewUlatekWaveDirection()
        local message = math.random(2) == 1 and secretwrap(NSI:Loc("< Left")) or secretwrap(NSI:Loc("Right >"))
        local info = self:CreateReminder({
            text = "",
            DisplayType = "Text",
            dur = 8,
            time = 8,
            encID = encID,
            phase = 1,
            HideTimer = true,
            TTS = false,
            IsAlert = false,
            ReloeReminder = true,
        }, true)
        info.text = message
        self:DisplayReminder(info, true)
    end

    local waveDirectionOptions = {
        {Type = "Label", text = NSI:Loc('During the Waves in P1, any raid chat msg will be displayed as a text. The button below provide you with a "< Left" and a "Right >" macro'), height = 50},
        {Type = "Button", label = NSI:Loc("Create Macros"), width = 180,
            func = [[return function(NSI)
                local macros = {
                    {name = NSI:Loc("Ula'tek Left"), icon = 450906, message = "/raid " .. NSI:Loc("< Left")},
                    {name = NSI:Loc("Ula'tek Right"), icon = 450908, message = "/raid " .. NSI:Loc("Right >")},
                }
                for _, macro in ipairs(macros) do
                    if GetMacroInfo(macro.name) then
                        EditMacro(macro.name, macro.name, macro.icon, macro.message)
                    else
                        CreateMacro(macro.name, macro.icon, macro.message)
                    end
                end
            end]],
            tooltip = {title = NSI:Loc("Create Macros"), desc = NSI:Loc("Creates one raid macro for each wave direction and updates them if they already exist.")}},
    }
    local data = {group = "Ula'tek", internalID = "WaveDirection", name = "Wave Direction Input", text = "", DisplayType = "Text", encID = encID, TTS = false, dur = 8,
        HideTimer = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, Preview = [[return function(self) self:PreviewUlatekWaveDirection() end]],
        extraOptions = waveDirectionOptions,
        timers = {
            [16] = {48, 100},
        },
    }
    self:AddEncounterAlert(data)

    local UlatekGraspingFangsPreview = [[return function(self) self:PreviewUlatekGraspingFangsOverviews() end]]
    local graspingFangsOverviewOptions = {
        {Type = "Color", label = "Left Side Background Color",
            get = [[return function() local a = NSRT.EncounterAlerts[3492][16].GraspingFangsOverview local c = a.LeftBackgroundColor or {1, 0, 0, 1} return c[1], c[2], c[3], c[4] end]],
            set = [[return function(NSI, r, g, b, a) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.LeftBackgroundColor = {r, g, b, a} end NSI:UpdateUlatekGraspingFangsOverviews() end]],},
        {Type = "Color", label = "Right Side Background Color",
            get = [[return function() local a = NSRT.EncounterAlerts[3492][16].GraspingFangsOverview local c = a.RightBackgroundColor or {0, 0.45, 1, 1} return c[1], c[2], c[3], c[4] end]],
            set = [[return function(NSI, r, g, b, a) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.RightBackgroundColor = {r, g, b, a} end NSI:UpdateUlatekGraspingFangsOverviews() end]],},
        {Type = "Color", label = "Left Side Inactive Color",
            get = [[return function() local a = NSRT.EncounterAlerts[3492][16].GraspingFangsOverview local c = a.LeftInactiveColor or {0.32, 0.02, 0.02, 0.85} return c[1], c[2], c[3], c[4] end]],
            set = [[return function(NSI, r, g, b, a) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.LeftInactiveColor = {r, g, b, a} end NSI:UpdateUlatekGraspingFangsOverviews() end]],
            tooltip = {title = "Left Side Inactive Color", desc = "Color of the left side's rows while that player does not have the debuff."}},
        {Type = "Color", label = "Right Side Inactive Color",
            get = [[return function() local a = NSRT.EncounterAlerts[3492][16].GraspingFangsOverview local c = a.RightInactiveColor or {0.02, 0.155, 0.32, 0.85} return c[1], c[2], c[3], c[4] end]],
            set = [[return function(NSI, r, g, b, a) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.RightInactiveColor = {r, g, b, a} end NSI:UpdateUlatekGraspingFangsOverviews() end]],
            tooltip = {title = "Right Side Inactive Color", desc = "Color of the right side's rows while that player does not have the debuff."}},
        {Type = "Checkbox", label = "Show All Players",
            get = [[return function() local a = NSRT.EncounterAlerts[3492][16].GraspingFangsOverview return a.ShowAllPlayers ~= false end]],
            set = [[return function(NSI, value) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.ShowAllPlayers = value and true or false end NSI:UpdateUlatekGraspingFangsOverviews() end]],
            tooltip = {title = "Show All Players", desc = "Keeps a row up for every player on that side, in the inactive color, and switches it to the regular color while they have the debuff. Turn off to only show players who currently have the debuff."}},
        {Type = "TextEntry", label = "Left Side Groups", inputWidth = 120,
            get = [[return function() return NSRT.EncounterAlerts[3492][16].GraspingFangsOverview.LeftGroups or "1,2,3,4,5,6,7,8" end]],
            set = [[return function(NSI, value) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.LeftGroups = value end NSI:UpdateUlatekGraspingFangsOverviews() end]],
            tooltip = {title = "Left Side Groups", desc = "Raid subgroups shown on the left side, comma separated. Use 1,2 and 3,4 to split by halves, or 1,3,5,7 and 2,4,6,8 for odds and evens."}},
        {Type = "TextEntry", label = "Right Side Groups", inputWidth = 120,
            get = [[return function() return NSRT.EncounterAlerts[3492][16].GraspingFangsOverview.RightGroups or "" end]],
            set = [[return function(NSI, value) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.RightGroups = value end NSI:UpdateUlatekGraspingFangsOverviews() end]],
            tooltip = {title = "Right Side Groups", desc = "Raid subgroups shown on the right side, comma separated. Empty by default, so only the left side is shown. A group left out of both sides is not tracked."}},
        {Type = "Checkbox", label = "Sort by Role",
            get = [[return function() local a = NSRT.EncounterAlerts[3492][16].GraspingFangsOverview return a.SortByRole == true end]],
            set = [[return function(NSI, value) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.SortByRole = value and true or false end NSI:UpdateUlatekGraspingFangsOverviews() end]],},
        {Type = "Slider", label = "Bar Height", min = 10, max = 100, step = 1,
            get = [[return function() local a = NSRT.EncounterAlerts[3492][16].GraspingFangsOverview return a.BarHeight or NSRT.ReminderSettings.DebuffOverviewSettings.Height end]],
            set = [[return function(NSI, value) for i = 15, 16 do NSRT.EncounterAlerts[3492][i].GraspingFangsOverview.BarHeight = value end NSI:UpdateUlatekGraspingFangsOverviews() end]],},
    }
    local data = {group = "Ula'tek", internalID = "GraspingFangsOverview", name = "Grasping Fangs Overview", text = nil, DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 40,
        Version = {versionNumber = 1, [1] = {LeftBackgroundColor = {1, 0, 0, 1}, RightBackgroundColor = {0, 0.45, 1, 1},
            LeftInactiveColor = {0.32, 0.02, 0.02, 0.85}, RightInactiveColor = {0.02, 0.155, 0.32, 0.85},
            LeftGroups = "1,2", RightGroups = "3,4", SortByRole = true, ShowAllPlayers = true}},
        spellID = 1311611, id = 0.2, difficulties = {15, 16}, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, Preview = UlatekGraspingFangsPreview, enabled = false,
        LeftBackgroundColor = {1, 0, 0, 1}, RightBackgroundColor = {0, 0.45, 1, 1}, LeftGroups = "1,2", RightGroups = "3,4", SortByRole = true, extraOptions = graspingFangsOverviewOptions,
        LeftInactiveColor = {0.32, 0.02, 0.02, 0.85}, RightInactiveColor = {0.02, 0.155, 0.32, 0.85}, ShowAllPlayers = true,
        timers = {
            [15] = {180},
            [16] = {180},
        },
    }
    self:AddEncounterAlert(data)

    local nameplateAnchorOptions = {
        {label = NSI:Loc("Top"), value = "TOP"},
        {label = NSI:Loc("Center"), value = "CENTER"},
        {label = NSI:Loc("Left"), value = "LEFT"},
        {label = NSI:Loc("Right"), value = "RIGHT"},
        {label = NSI:Loc("Bottom"), value = "BOTTOM"},
    }
    local data = {Version = {versionNumber = 1, [1] = {group = "Ula'tek"}}, group = "Ula'tek", internalID = "InterruptAssignments", name = "Interrupt Assignments", text = "Interrupts", customIcon = 6552, DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 1, Preview = [[return function(NSI)
        if NSI:PreviewUlatekInterruptDisplay() then
            print(NSI:Loc("|cFF00FFFFNSRT:|r the live display uses the global Interrupt Display settings during this encounter."))
        end
    end]],
        difficulties = {16}, enabled = true, pinned = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, BoxSize = 30, NumberFontSize = 12, NameFontSize = 12,
        NameplateAnchor = "TOP", NameplateXOffset = 0, NameplateYOffset = 0, HideNameplateBox = false,
        extraOptions = {
            {Type = "Label", text = NSI:Loc("The Interrupt display will be displayed for the add that you focused. The order of lines in the interrupt note does not matter since it's not assigned to an actual boss unit but just to whatever you focus. Use raidmarker to ensure that people are focusing the same add."), height = 60},
            {Type = "Slider", label = NSI:Loc("Number Font Size"), min = 8, max = 40, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NumberFontSize or 12 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NumberFontSize = value NSI:UpdateUlatekInterruptDisplay() end]],
            },
            {Type = "Slider", label = NSI:Loc("Name Font Size"), min = 8, max = 40, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameFontSize or 12 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameFontSize = value NSI:UpdateUlatekInterruptDisplay() end]],
            },
            {Type = "Slider", label = NSI:Loc("Box Size"), min = 30, max = 150, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.BoxSize or 30 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.BoxSize = value NSI:UpdateUlatekInterruptDisplay() end]],
            },
            {Type = "Dropdown", label = NSI:Loc("Nameplate Anchor"),
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateAnchor or "TOP" end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateAnchor = value NSI:UpdateUlatekInterruptDisplay() end]],
                values = nameplateAnchorOptions,
            },
            {Type = "Slider", label = NSI:Loc("Nameplate X Offset"), min = -200, max = 200, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateXOffset or 0 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateXOffset = value NSI:UpdateUlatekInterruptDisplay() end]],
            },
            {Type = "Slider", label = NSI:Loc("Nameplate Y Offset"), min = -200, max = 200, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateYOffset or 0 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateYOffset = value NSI:UpdateUlatekInterruptDisplay() end]],
            },
            {Type = "Checkbox", label = NSI:Loc("Hide nameplate box"),
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.HideNameplateBox or false end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.HideNameplateBox = value NSI:UpdateUlatekInterruptDisplay() end]],
                tooltip = {title = NSI:Loc("Hide nameplate box"), desc = NSI:Loc("Hide the nameplate box while keeping the static box visible.")},
            },
        },
    }
    self:AddEncounterAlert(data)

    self:RemoveEncounterAlert(encID, 16, "TransitionSoakFirst")
    self:RemoveEncounterAlert(encID, 16, "TransitionSoakSecond")

    local data = {group = "Ula'tek", internalID = "WaveLines", name = "P3 Wave lines", text = "", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = ulatekWaveLineDuration, spellID = 1316356,
        difficulties = {16}, enabled = false, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, Preview = [[return function(NSI) NSI:PreviewUlatekWaveLines() end]],
        timers = {
            [16] = ulatekWaveLineTimes,
        },
    }
    self:AddEncounterAlert(data)

    local transitionSoakDescription = [[Use the following note format to assign players to one of the 3 soaking groups:
transitionStart
Reloe Senfi Ponky
Impy Liebre Gladrien
Hori Shiru Robin
transitionEnd
There are 3 possible patterns. To determine the correct pattern, one player (who must either be raidleader or have assist) creates the 3 macros at the bottom and presses the corresponding macro for the first appearing Slam. From there on assignments will happen automatically.
From the following screenshot Group1 is soaking the 3 orange-marked positions, Group2 the purple-marked positions, and Group3 the red-marked positions.
For one of the patterns all assigned soaks are shifted counter-clockwise by 1]]
    local transitionSoakOptions = {
        {Type = "Custom", build = function(parent, width, name)
            local label = NSI.UI.Components.CreateLabel(parent, NSI:Loc(transitionSoakDescription), width, 1, name)
            label:SetLocaleKey(transitionSoakDescription)
            label.label:ClearAllPoints()
            label.label:SetPoint("TOPLEFT", label.frame)
            label.label:SetPoint("TOPRIGHT", label.frame)
            label.label:SetJustifyV("TOP")
            local height = 245
            label:SetSize(width, height)
            return label, height
        end},
        {Type = "Link", label = NSI:Loc("Copy Group Assignment Image Link"), url = "https://i.imgur.com/hTLmIYt.png", width = 250,
            tooltip = {title = NSI:Loc("Copy Group Assignment Image Link"), desc = "https://i.imgur.com/hTLmIYt.png"}},
        {Type = "Button", label = NSI:Loc("Create Macros"), width = 180,
            func = [[return function(NSI)
                local macros = {
                    {name = NSI:Loc("Ula'tek Pattern Yell"), icon = 137007, message = NSI:Loc("/yell X")},
                    {name = NSI:Loc("Ula'tek Pattern Raid"), icon = 137001, message = NSI:Loc("/raid Star")},
                    {name = NSI:Loc("Ula'tek Pattern Warning"), icon = 137004, message = NSI:Loc("/rw Triangle")},
                }
                for _, macro in ipairs(macros) do
                    if GetMacroInfo(macro.name) then
                        EditMacro(macro.name, macro.name, macro.icon, macro.message)
                    else
                        CreateMacro(macro.name, macro.icon, macro.message)
                    end
                end
            end]],
            tooltip = {title = NSI:Loc("Create Macros"), desc = NSI:Loc("Creates the three chat macros used to select Ula'tek's transition pattern.")}},
    }
    local data = {group = "Ula'tek", internalID = "TransitionPatternSoaks", name = "Transition Soaks", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = 1299010,
        difficulties = {16}, enabled = true, pinned = true, isSpecialDisplay = true, BlockCopy = true, Preview = [[return function(NSI) NSI:PreviewUlatekTransitionSoak() end]], extraOptions = transitionSoakOptions,
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek", internalID = "TransitionPatternArrow", name = "Transition Arrow", text = "", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        difficulties = {16}, enabled = true, pinned = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, Preview = [[return function(NSI) NSI:PreviewUlatekTransitionArrow() end]],
        Anchor = "CENTER", relativeTo = "CENTER", xOffset = 0, yOffset = 0,
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id, isPreview)
    id = id or self:DifficultyCheck({15, 16})
    local diffData = id and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id]
    local overviewAlert = diffData and diffData.GraspingFangsOverview
    local wrongTargetAlert = diffData and diffData.WrongTarget
    local waveDirectionAlert = diffData and diffData.WaveDirection
    local wavesAlert = diffData and diffData.Waves
    local waveLinesAlert = diffData and diffData.WaveLines
    local transitionSoakAlert = diffData and diffData.TransitionPatternSoaks
    local transitionArrowAlert = diffData and diffData.TransitionPatternArrow

    StopUlatekTransition(self)
    StartUlatekWaveLines(self, waveLinesAlert, isPreview)
    if isPreview then return end
    if (transitionSoakAlert and transitionSoakAlert.enabled and self:EvaluateLoad(transitionSoakAlert))
        or (transitionArrowAlert and transitionArrowAlert.enabled and self:EvaluateLoad(transitionArrowAlert)) then
        self.UlatekTransitionStartTime = GetTime()
        self.UlatekTransitionTimers = {}
        self:EncounterFunction("UlatekTransitionPattern", function(_, event)
            if not self.UlatekTransitionListening then return end
            local pattern = transitionPatterns[event]
            if not pattern then return end

            self.UlatekTransitionListening = false
            self:EncounterRegister("UlatekTransitionPattern", {"CHAT_MSG_YELL", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING"}, false)
            local assignedGroups = GetUlatekTransitionAssignments()
            local assignments = {}
            for group, markers in ipairs(transitionGroupMarkers[event]) do
                if assignedGroups[group] then
                    for _, marker in ipairs(markers) do
                        assignments[marker] = true
                    end
                end
            end
            local now = GetTime()
            local assignedSoaks = {}
            for index, marker in ipairs(pattern) do
                if assignments[marker] then
                    local remaining = transitionSoakTimes[index] - (now - self.UlatekTransitionStartTime)
                    if remaining > 0 then
                        assignedSoaks[#assignedSoaks + 1] = {marker = marker, remaining = remaining}
                        if transitionSoakAlert.enabled and self:EvaluateLoad(transitionSoakAlert) then
                            local reminderMarker = marker
                            local reminderRemaining = remaining
                            self.UlatekTransitionTimers[#self.UlatekTransitionTimers + 1] = C_Timer.NewTimer(math.max(0, reminderRemaining - 8), function()
                                if self.EncounterID ~= encID or not transitionSoakAlert.enabled or not self:EvaluateLoad(transitionSoakAlert) then return end
                                local duration = math.min(8, reminderRemaining)
                                local info = self:CreateReminder({
                                    text = transitionSoakAlert.text.." {rt"..reminderMarker.."}",
                                    DisplayType = transitionSoakAlert.DisplayType,
                                    textColors = transitionSoakAlert.textColors,
                                    barColors = transitionSoakAlert.barColors,
                                    ringColors = transitionSoakAlert.ringColors,
                                    dur = duration,
                                    time = duration,
                                    encID = encID,
                                    phase = self.Phase,
                                    TTS = transitionSoakAlert.TTS,
                                    TTSTimer = transitionSoakAlert.TTSTimer,
                                    IsAlert = false,
                                    ReloeReminder = true,
                                })
                                if info then self:DisplayReminder(info) end
                            end)
                        end
                    end
                end
            end
            if #assignedSoaks == 0 or not transitionArrowAlert.enabled or not self:EvaluateLoad(transitionArrowAlert) then return end

            local frame = CreateUlatekTransitionArrow(self)
            EnableUlatekTransitionMinimapRotation(self)
            frame.IsPreview = false
            frame.PreviewToken = (frame.PreviewToken or 0) + 1
            PositionUlatekTransitionArrow(self, frame, transitionArrowAlert)
            SetUlatekTransitionArrowMarker(frame, assignedSoaks[1].marker)
            frame:Show()
            for soakIndex = 1, #assignedSoaks - 1 do
                local nextSoak = assignedSoaks[soakIndex + 1]
                self.UlatekTransitionTimers[#self.UlatekTransitionTimers + 1] = C_Timer.NewTimer(assignedSoaks[soakIndex].remaining, function()
                    if self.EncounterID == encID and transitionArrowAlert.enabled and self:EvaluateLoad(transitionArrowAlert) then
                        SetUlatekTransitionArrowMarker(frame, nextSoak.marker)
                    else
                        frame:Hide()
                    end
                end)
            end
            self.UlatekTransitionTimers[#self.UlatekTransitionTimers + 1] = C_Timer.NewTimer(assignedSoaks[#assignedSoaks].remaining, function()
                frame:Hide()
                RestoreUlatekTransitionMinimapRotation(self)
            end)
        end)
        self.UlatekTransitionTimers[#self.UlatekTransitionTimers + 1] = C_Timer.NewTimer(325, function()
            if self.EncounterID ~= encID then return end
            self.UlatekTransitionListening = true
            self:EncounterRegister("UlatekTransitionPattern", {"CHAT_MSG_YELL", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING"}, true)
        end)
        self.UlatekTransitionTimers[#self.UlatekTransitionTimers + 1] = C_Timer.NewTimer(340, function()
            if self.EncounterID ~= encID then return end
            self.UlatekTransitionListening = false
            self:EncounterRegister("UlatekTransitionPattern", {"CHAT_MSG_YELL", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING"}, false)
        end)
    end

    if self.UlatekGraspingFangsTimers then
        for _, timer in ipairs(self.UlatekGraspingFangsTimers) do timer:Cancel() end
        self.UlatekGraspingFangsTimers = nil
    end

    if overviewAlert and overviewAlert.enabled and self:EvaluateLoad(overviewAlert) then
        self:UpdateUlatekGraspingFangsOverviews(overviewAlert)
        self.UlatekGraspingFangsTimers = {}
        for _, applyTime in ipairs(overviewAlert.timers or {}) do
            self.UlatekGraspingFangsTimers[#self.UlatekGraspingFangsTimers + 1] = C_Timer.NewTimer(applyTime, function()
                if self.EncounterID == encID then self:SetUlatekGraspingFangsOverviewsShown(true) end
            end)
            self.UlatekGraspingFangsTimers[#self.UlatekGraspingFangsTimers + 1] = C_Timer.NewTimer(applyTime + (overviewAlert.dur or 40), function()
                if self.EncounterID == encID then self:SetUlatekGraspingFangsOverviewsShown(false) end
            end)
        end
    else
        self:SetUlatekGraspingFangsOverviewsShown(false)
    end

    StopUlatekWaveDirection(self)
    if waveDirectionAlert and waveDirectionAlert.enabled and self:EvaluateLoad(waveDirectionAlert) and wavesAlert then
        self:EncounterFunction("UlatekWaveDirection", function(_, event, message)
            if not self.UlatekWaveDirectionListening then return end
            local info = self:CreateReminder({
                text = "",
                DisplayType = "Text",
                textColors = waveDirectionAlert.textColors,
                dur = 8,
                time = 8,
                encID = encID,
                phase = self.Phase,
                HideTimer = true,
                TTS = false,
                IsAlert = false,
                ReloeReminder = true,
            })
            if not info then return end
            info.text = message
            self:DisplayReminder(info)
        end)
        self.UlatekWaveDirectionTimers = {}
        for _, waveTime in ipairs(wavesAlert.timers or {}) do
            if waveTime < 180 then
                local listenStart = math.max(0, waveTime - 6)
                self.UlatekWaveDirectionTimers[#self.UlatekWaveDirectionTimers + 1] = C_Timer.NewTimer(listenStart, function()
                    if self.EncounterID ~= encID then return end
                    self.UlatekWaveDirectionListening = true
                    self:EncounterRegister("UlatekWaveDirection", {"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER"}, true)
                end)
                self.UlatekWaveDirectionTimers[#self.UlatekWaveDirectionTimers + 1] = C_Timer.NewTimer(waveTime + 2, function()
                    if self.EncounterID ~= encID then return end
                    self.UlatekWaveDirectionListening = false
                    self:EncounterRegister("UlatekWaveDirection", {"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER"}, false)
                end)
            end
        end
    end

    local interruptAlert = diffData and diffData.InterruptAssignments
    local interruptAlertActive = interruptAlert and interruptAlert.enabled and self:EvaluateLoad(interruptAlert)
    self.UlatekInterruptAlert = interruptAlert
    if self.UlatekInterruptResetTimer then
        self.UlatekInterruptResetTimer:Cancel()
        self.UlatekInterruptResetTimer = nil
    end
    if interruptAlertActive then
        self:ReadInterruptNote(1)
        self:ResetInterrupts()
        self.UlatekInterruptBossCounts = {boss2 = 1, boss3 = 1, boss4 = 1, boss5 = 1}
        self.UlatekInterruptFocusedBossUnit = nil
        self.UlatekInterruptTrackingEnabled = false
        self:EncounterRegister("UlatekInterruptFocus", "PLAYER_FOCUS_CHANGED", true)
        self:EncounterRegister("UlatekInterruptFocus", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, true, "focus")
        self:EncounterRegister("UlatekInterruptBossCounts", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, true, {"boss2", "boss3", "boss4", "boss5"})
        self:EncounterFunction("UlatekInterruptFocus", function(_, event, unit)
            if not self.UlatekInterruptTrackingEnabled then return end
            if event == "PLAYER_FOCUS_CHANGED" then
                self.UlatekInterruptFocusedBossUnit = GetUlatekInterruptFocusedBossUnit()
                self:ResetInterrupts()
                if self.UlatekInterruptFocusedBossUnit then
                    self.Interrupts.castCount = self.UlatekInterruptBossCounts[self.UlatekInterruptFocusedBossUnit]
                    self:DisplayInterrupt()
                end
                self:UpdateUlatekInterruptDisplay()
            elseif event == "UNIT_SPELLCAST_START" and unit == "focus" then
                if self.UlatekInterruptFocusedBossUnit then
                    self:InterruptOnCastStart({dur = 3}, unit)
                    self:UpdateUlatekInterruptDisplay()
                end
            elseif event == "UNIT_SPELLCAST_INTERRUPTED" and unit == "focus" and self.UlatekInterruptFocusedBossUnit then
                self:OnInterrupt(true)
                self:UpdateUlatekInterruptDisplay()
            elseif event == "UNIT_SPELLCAST_STOP" and unit == "focus" and self.UlatekInterruptFocusedBossUnit then
                self:OnCastStop(false)
                self.UlatekInterruptBossCounts[self.UlatekInterruptFocusedBossUnit] = self.Interrupts.castCount
                self:UpdateUlatekInterruptDisplay()
            end
        end)
        self:EncounterFunction("UlatekInterruptBossCounts", function(_, event, unit)
            if not self.UlatekInterruptTrackingEnabled or event ~= "UNIT_SPELLCAST_STOP" or unit == self.UlatekInterruptFocusedBossUnit then return end
            local castCount = self.UlatekInterruptBossCounts[unit] + 1
            if castCount > self.Interrupts.max then
                castCount = 1
            end
            self.UlatekInterruptBossCounts[unit] = castCount
        end)
        self.UlatekInterruptResetTimer = C_Timer.NewTimer(240, function()
            if self.EncounterID ~= encID then return end
            self.UlatekInterruptBossCounts = {boss2 = 1, boss3 = 1, boss4 = 1, boss5 = 1}
            self.UlatekInterruptTrackingEnabled = true
            self:ResetInterrupts()
            self.UlatekInterruptFocusedBossUnit = GetUlatekInterruptFocusedBossUnit()
            HideUlatekInterruptDisplay(self)
        end)
        self:UpdateUlatekInterruptDisplay()
    else
        self:EncounterRegister("UlatekInterruptFocus", "PLAYER_FOCUS_CHANGED", false)
        self:EncounterRegister("UlatekInterruptFocus", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false)
        self:EncounterRegister("UlatekInterruptBossCounts", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false)
        HideUlatekInterruptDisplay(self)
    end

    if not wrongTargetAlert or not wrongTargetAlert.enabled or not self:EvaluateLoad(wrongTargetAlert) then return end

    if self.UlatekWrongTargetTimers then
        for _, timer in ipairs(self.UlatekWrongTargetTimers) do timer:Cancel() end
        self.UlatekWrongTargetTimers = nil
    end
    self.UlatekWrongTargetEndTime = nil
    self:EncounterRegister("UlatekWrongTarget", "PLAYER_TARGET_CHANGED", false)

    local UpdateWrongTarget = function()
        if not self.UlatekWrongTargetEndTime or GetTime() >= self.UlatekWrongTargetEndTime then
            if self.UlatekWrongTargetFrame then
                self.UlatekWrongTargetFrame:Hide()
                self.UlatekWrongTargetFrame = nil
            end
            return
        end

        local targetExists = UnitExists("target")
        if issecretvalue(targetExists) or not targetExists then
            if self.UlatekWrongTargetFrame then
                self.UlatekWrongTargetFrame:Hide()
                self.UlatekWrongTargetFrame = nil
            end
            return
        end

        local isBossTarget = UnitIsUnit("target", "boss2")
        if issecretvalue(isBossTarget) then return end
        if isBossTarget then
            if self.UlatekWrongTargetFrame then
                self.UlatekWrongTargetFrame:Hide()
                self.UlatekWrongTargetFrame = nil
            end
            return
        end

        if self.UlatekWrongTargetFrame and self.UlatekWrongTargetFrame:IsShown() then return end
        local remainingDuration = self.UlatekWrongTargetEndTime - GetTime()
        local info = self:CreateReminder({
            text = wrongTargetAlert.text,
            DisplayType = wrongTargetAlert.DisplayType,
            textColors = wrongTargetAlert.textColors,
            dur = remainingDuration,
            time = remainingDuration,
            encID = encID,
            phase = self.Phase,
            HideTimer = true,
            sticky = wrongTargetAlert.sticky,
            TTS = false,
            IsAlert = false,
            ReloeReminder = true,
        })
        self.UlatekWrongTargetFrame = info and self:DisplayReminder(info)
    end

    self:EncounterFunction("UlatekWrongTarget", UpdateWrongTarget)
    self:EncounterRegister("UlatekWrongTarget", "PLAYER_TARGET_CHANGED", true)
    self.UlatekWrongTargetTimers = {}
    for _, ampTime in ipairs(wrongTargetAlert.timers or {}) do
        self.UlatekWrongTargetTimers[#self.UlatekWrongTargetTimers + 1] = C_Timer.NewTimer(ampTime, function()
            if self.EncounterID ~= encID then return end
            self.UlatekWrongTargetEndTime = GetTime() + (wrongTargetAlert.dur or 20)
            if self.UlatekWrongTargetFrame then
                self.UlatekWrongTargetFrame:Hide()
                self.UlatekWrongTargetFrame = nil
            end
            UpdateWrongTarget()
        end)
        self.UlatekWrongTargetTimers[#self.UlatekWrongTargetTimers + 1] = C_Timer.NewTimer(ampTime + (wrongTargetAlert.dur or 20), function()
            if self.EncounterID ~= encID then return end
            self.UlatekWrongTargetEndTime = nil
            UpdateWrongTarget()
        end)
    end
end

NSI.EncounterAlertStop[encID] = function(self)
    StopUlatekWaveLines(self)
    StopUlatekWaveDirection(self)
    StopUlatekTransition(self)
    self.UlatekInterruptAlert = nil
    self.UlatekInterruptTrackingEnabled = false
    self.UlatekInterruptFocusedBossUnit = nil
    self.UlatekInterruptBossCounts = nil
    if self.UlatekInterruptResetTimer then
        self.UlatekInterruptResetTimer:Cancel()
        self.UlatekInterruptResetTimer = nil
    end
    self:EncounterRegister("UlatekInterruptFocus", "PLAYER_FOCUS_CHANGED", false)
    self:EncounterRegister("UlatekInterruptFocus", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false)
    self:EncounterRegister("UlatekInterruptBossCounts", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false)
    if self.Interrupts then
        self:ResetInterrupts()
    end
    HideUlatekInterruptDisplay(self)
    if self.UlatekGraspingFangsTimers then
        for _, timer in ipairs(self.UlatekGraspingFangsTimers) do timer:Cancel() end
        self.UlatekGraspingFangsTimers = nil
    end
    self:SetUlatekGraspingFangsOverviewsShown(false)
    if self.UlatekWrongTargetTimers then
        for _, timer in ipairs(self.UlatekWrongTargetTimers) do timer:Cancel() end
        self.UlatekWrongTargetTimers = nil
    end
    self:EncounterRegister("UlatekWrongTarget", "PLAYER_TARGET_CHANGED", false)
    self.UlatekWrongTargetEndTime = nil
    if self.UlatekWrongTargetFrame then
        self.UlatekWrongTargetFrame:Hide()
        self.UlatekWrongTargetFrame = nil
    end
end
