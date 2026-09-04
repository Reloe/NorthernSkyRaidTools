local _, NSI = ... -- Internal namespace

local encID = 3492
-- /run NSAPI:DebugEncounter(3492)

local GRASPING_FANGS_LEFT = "UlatekGraspingFangsLeftSide"
local GRASPING_FANGS_RIGHT = "UlatekGraspingFangsRightSide"

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
    local assignmentTable = self.Interrupts and self.Interrupts.assignTable
    if assignmentTable then
        for lineIndex = 2, #assignmentTable do
            local interruptNames = assignmentTable[lineIndex]
            if #interruptNames > 0 then return interruptNames end
        end
    end
    return {}
end

local function GetUlatekInterruptCount(self, castBarID, nextCast)
    local interruptNames = GetUlatekInterruptNames(self)
    if #interruptNames == 0 then return 1 end
    local castCount = math.max(1, castBarID - 1)
    if nextCast then castCount = castCount + 1 end
    return (castCount - 1) % #interruptNames + 1
end

local function IsUlatekInterruptFocus()
    for bossIndex = 2, 5 do
        local isBoss = UnitIsUnit("focus", "boss"..bossIndex)
        if issecretvalue(isBoss) then return false end
        if isBoss then return true end
    end
    return false
end

local function HideUlatekInterruptDisplay(self)
    if self.UlatekInterruptNameplateBox then
        self.UlatekInterruptNameplateBox:Hide()
    end
    if self.UlatekInterruptStaticShown then
        self:HideInterrupt()
        self.UlatekInterruptStaticShown = false
    end
end

function NSI:UpdateUlatekInterruptDisplay()
    local alert = self.UlatekInterruptAlert
    if not alert then return end
    if not IsUlatekInterruptFocus() then
        HideUlatekInterruptDisplay(self)
        return
    end

    local interruptNames = GetUlatekInterruptNames(self)
    local castCount = self.UlatekInterruptCastCount or 1
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

    if alert.DisplayStaticBox then
        self:DisplayInterruptAssignment(castCount, displayName, boxColor, textColor)
        self.UlatekInterruptStaticShown = true
    elseif self.UlatekInterruptStaticShown then
        self:HideInterrupt()
        self.UlatekInterruptStaticShown = false
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

function NSI:UpdateUlatekInterruptPreview()
    local preview = self.UlatekInterruptPreviewFrame
    if not preview then return end

    local alert = self.UlatekInterruptAlert or (NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][16] and NSRT.EncounterAlerts[encID][16].InterruptAssignments)
    if not alert or alert.DisplayStaticBox then
        preview:Hide()
        return
    end

    local interruptNames = GetUlatekInterruptNames(self)
    local currentName = interruptNames[1]
    local nextName = interruptNames[2]
    local interruptSettings = NSRT.InterruptSettings
    local boxSize = alert.BoxSize or 30
    local fontScale = boxSize / 30
    local boxColor = interruptSettings.InterruptDefaultColor
    local textColor = interruptSettings.InterruptDefaultTextColor
    if currentName and UnitIsUnit(currentName, "player") then
        boxColor = interruptSettings.InterruptNowColor
        textColor = interruptSettings.InterruptNowTextColor
    elseif nextName and UnitIsUnit(nextName, "player") then
        boxColor = interruptSettings.InterruptNextColor
        textColor = interruptSettings.InterruptNextTextColor
    end

    preview:SetScale(self:GetInterruptNameplateScale(C_NamePlate.GetNamePlateForUnit("focus")))
    preview:SetSize(boxSize + 20, boxSize + 20)
    preview:ClearAllPoints()
    preview:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local box = preview.box
    box:SetSize(boxSize, boxSize)
    box:ClearAllPoints()
    box:SetPoint("CENTER", preview, "CENTER")
    box.Background:SetColorTexture(unpack(boxColor))
    box.Number:ClearAllPoints()
    box.Number:SetPoint(interruptSettings.NumberAnchor, box, interruptSettings.NumberRelativeTo, interruptSettings.NumberxOffset, interruptSettings.NumberyOffset)
    box.Number:SetFont(self.LSM:Fetch("font", interruptSettings.NumberFont), (alert.NumberFontSize or interruptSettings.NumberFontSize) * fontScale, interruptSettings.NumberFontFlags)
    box.Number:SetTextColor(unpack(textColor))
    box.Number:SetText(1)
    box.Name:ClearAllPoints()
    box.Name:SetPoint(interruptSettings.NameAnchor, box, interruptSettings.NameRelativeTo, interruptSettings.NamexOffset, interruptSettings.NameyOffset)
    box.Name:SetFont(self.LSM:Fetch("font", interruptSettings.NameFont), (alert.NameFontSize or interruptSettings.NameFontSize) * fontScale, interruptSettings.NameFontFlags)
    box.Name:SetText(currentName and NSAPI:Shorten(currentName, 12, false, "GlobalNickNames", true, false) or NSAPI:Shorten("player", 12, false, "GlobalNickNames", true, false))
    box:Show()
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

    if alert.DisplayStaticBox then
        if self.UlatekInterruptPreviewFrame then
            self.UlatekInterruptPreviewFrame:Hide()
        end
        return self:PreviewInterruptDisplay(1, displayName, boxColor, textColor)
    end

    if self.UlatekInterruptPreviewFrame and self.UlatekInterruptPreviewFrame:IsShown() then
        self.UlatekInterruptPreviewFrame:Hide()
        return false
    end
    if not self.UlatekInterruptPreviewFrame then
        local preview = CreateFrame("Frame", "NSRTUlatekInterruptPreview", UIParent)
        preview:SetFrameStrata("DIALOG")
        preview:SetFrameLevel(10)
        preview.box = self:CreateInterruptAssignmentDisplay(preview)
        preview.box:SetFrameLevel(1)
        self.UlatekInterruptPreviewFrame = preview
    end
    self:UpdateUlatekInterruptPreview()
    self.UlatekInterruptPreviewFrame:Show()
    return true
end

local function SyncUlatekInterruptCount(self)
    local castBarID = select(10, UnitCastingInfo("focus"))
    if castBarID and not issecretvalue(castBarID) then
        self.UlatekInterruptCastCount = GetUlatekInterruptCount(self, castBarID)
    end
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
    local data = {Version = {versionNumber = 1, [1] = {group = "Ula'tek"}}, group = "Ula'tek", internalID = "InterruptAssignments", name = "Interrupt Assignments", text = "Interrupts", customIcon = 6552, DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 1, Preview = [[return function(NSI) NSI:PreviewUlatekInterruptDisplay() end]],
        difficulties = {16}, enabled = true, pinned = true, isSpecialDisplay = true, BlockCopy = true, NoEdit = true, BoxSize = 30, NumberFontSize = 12, NameFontSize = 12,
        NameplateAnchor = "TOP", NameplateXOffset = 0, NameplateYOffset = 0, DisplayStaticBox = false, HideNameplateBox = false,
        extraOptions = {
            {Type = "Label", text = NSI:Loc("The Interrupt display will be displayed for the add that you focused. The order of lines in the interrupt note does not matter since it's not assigned to an actual boss unit but just to whatever you focus. Use raidmarker to ensure that people are focusing the same add."), height = 60},
            {Type = "Slider", label = NSI:Loc("Number Font Size"), min = 8, max = 40, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NumberFontSize or 12 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NumberFontSize = value NSI:UpdateUlatekInterruptDisplay() NSI:UpdateUlatekInterruptPreview() end]],
            },
            {Type = "Slider", label = NSI:Loc("Name Font Size"), min = 8, max = 40, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameFontSize or 12 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameFontSize = value NSI:UpdateUlatekInterruptDisplay() NSI:UpdateUlatekInterruptPreview() end]],
            },
            {Type = "Slider", label = NSI:Loc("Box Size"), min = 30, max = 150, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.BoxSize or 30 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.BoxSize = value NSI:UpdateUlatekInterruptDisplay() NSI:UpdateUlatekInterruptPreview() end]],
            },
            {Type = "Dropdown", label = NSI:Loc("Nameplate Anchor"),
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateAnchor or "TOP" end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateAnchor = value NSI:UpdateUlatekInterruptDisplay() end]],
                values = nameplateAnchorOptions,
            },
            {Type = "Slider", label = NSI:Loc("Nameplate X Offset"), min = -200, max = 200, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateXOffset or 0 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateXOffset = value NSI:UpdateUlatekInterruptDisplay() NSI:UpdateUlatekInterruptPreview() end]],
            },
            {Type = "Slider", label = NSI:Loc("Nameplate Y Offset"), min = -200, max = 200, step = 1,
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateYOffset or 0 end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.NameplateYOffset = value NSI:UpdateUlatekInterruptDisplay() NSI:UpdateUlatekInterruptPreview() end]],
            },
            {Type = "Checkbox", label = NSI:Loc("Display static box"),
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.DisplayStaticBox or false end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.DisplayStaticBox = value NSI:UpdateUlatekInterruptDisplay() NSI:UpdateUlatekInterruptPreview() end]],
                tooltip = {title = NSI:Loc("Display static box"), desc = NSI:Loc("Use the global Interrupt Display settings for the static box.")},
            },
            {Type = "Checkbox", label = NSI:Loc("Hide nameplate box"),
                get = [[return function() return NSRT.EncounterAlerts[3492][16].InterruptAssignments.HideNameplateBox or false end]],
                set = [[return function(NSI, value) NSRT.EncounterAlerts[3492][16].InterruptAssignments.HideNameplateBox = value NSI:UpdateUlatekInterruptDisplay() NSI:UpdateUlatekInterruptPreview() end]],
                tooltip = {title = NSI:Loc("Hide nameplate box"), desc = NSI:Loc("Hide the nameplate box while keeping the static box visible.")},
            },
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id)
    id = id or self:DifficultyCheck({15, 16})
    local diffData = id and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id]
    local overviewAlert = diffData and diffData.GraspingFangsOverview
    local wrongTargetAlert = diffData and diffData.WrongTarget
    local waveDirectionAlert = diffData and diffData.WaveDirection
    local wavesAlert = diffData and diffData.Waves

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
    self.UlatekInterruptCastCount = nil
    self.UlatekInterruptStaticShown = false
    if interruptAlertActive then
        self:ReadInterruptNote(1)
        self:EncounterRegister("UlatekInterruptAssignments", "PLAYER_FOCUS_CHANGED", true)
        self:EncounterRegister("UlatekInterruptAssignments", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, true, "focus")
        self:EncounterFunction("UlatekInterruptAssignments", function(_, event, unit, _, _, arg4, arg5)
            if event == "PLAYER_FOCUS_CHANGED" then
                self.UlatekInterruptCastCount = nil
                SyncUlatekInterruptCount(self)
                self:UpdateUlatekInterruptDisplay()
            elseif event == "UNIT_SPELLCAST_START" and unit == "focus" then
                C_Timer.After(0, function()
                    if self.EncounterID ~= encID or not self.UlatekInterruptAlert then return end
                    SyncUlatekInterruptCount(self)
                    self:UpdateUlatekInterruptDisplay()
                end)
            elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_STOP") and unit == "focus" then
                local castBarID = event == "UNIT_SPELLCAST_INTERRUPTED" and arg5 or arg4
                if not castBarID or issecretvalue(castBarID) then return end
                self.UlatekInterruptCastCount = GetUlatekInterruptCount(self, castBarID, true)
                self:UpdateUlatekInterruptDisplay()
            end
        end)
        SyncUlatekInterruptCount(self)
        self:UpdateUlatekInterruptDisplay()
    else
        self:EncounterRegister("UlatekInterruptAssignments", "PLAYER_FOCUS_CHANGED", false)
        self:EncounterRegister("UlatekInterruptAssignments", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false)
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
    StopUlatekWaveDirection(self)
    self.UlatekInterruptAlert = nil
    self.UlatekInterruptCastCount = nil
    self:EncounterRegister("UlatekInterruptAssignments", "PLAYER_FOCUS_CHANGED", false)
    self:EncounterRegister("UlatekInterruptAssignments", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, false)
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
