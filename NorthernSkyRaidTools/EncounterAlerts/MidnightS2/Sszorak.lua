local _, NSI = ... -- Internal namespace

local encID = 3420
-- /run NSAPI:DebugEncounter(3420)

local tankComboTimers = {
    [14] = {5.5, 55.7, 141.7, 195.9, 281.8, 334.1},
    [15] = {5.5, 55.7, 141.7, 195.9, 281.8, 334.1},
    [16] = {4.9, 52, 132, 179, 259, 306.1},
}

local damageAmpTimers = {
    [14] = {111.1, 249.3},
    [15] = {111.1, 249.3},
    [16] = {100, 227.1, 354.2},
}

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true
    local nontankConditions = self:DefaultLoadConditions()
    nontankConditions.Roles.HEALER = true
    nontankConditions.Roles.DAMAGER = true

    local data = {group = "Sszorak", internalID = "TankCombo", name = "Tank Combo", text = "Tank Combo", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1277002,
        loadConditions = tankConditions,
        textColors = {1, 0, 0, 1},
        timers = tankComboTimers,
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "DamageAmp", name = "Damage Amp", text = "Damage Amp", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1286033,
        timers = {
            [14] = damageAmpTimers[14],
            [15] = damageAmpTimers[15],
            [16] = damageAmpTimers[16],
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "Bait", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1305959,
        loadConditions = tankConditions,
        timers = {
            [15] = {32.2, 84.4, 170.4, 222.6, 308.5, 360.8},
            [16] = {28.8, 76.8, 156, 203, 282.2, 330.2},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "WindDebuffs", text = "Wind-Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1285419,
        timers = {
            [15] = {43.4, 95.5, 181.5, 233.7, 319.7, 371.9},
            [16] = {39.7, 86.7, 166.8, 213.8, 293.9, 340.9},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Sszorak", internalID = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1305963,
        loadConditions = nontankConditions,
        timers = {
            [15] = {37.2, 89.5, 175.4, 227.6, 313.5, 365.8},
            [16] = {32, 79.8, 159, 206.8, 286, 333.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "SerpentsFury", name = "Serpent's Fury", text = "Stack Up", DisplayType = "Text", encID = encID, phase = 1, TTS = "Stack", dur = 6,
        loadConditions = nontankConditions,
        timers = {
            [16] = {25, 74, 153, 202, 281, 330},
        },
    }
    self:AddEncounterAlert(data)

    local WindsPreview = [[
        return function(self, update)
            if self.IsSszorakWindsPreview then
                self.EncounterAlertStop[3420](self, true)
                self.IsSszorakWindsPreview = false
            else
                self.EncounterAlertStart[3420](self, 16, "Winds Helper")
                self.IsSszorakWindsPreview = true
            end
        end
    ]]

    local data = {group = "Sszorak", internalID = "WindsHelper", name = "Winds Helper", text = nil, DisplayType = "Text", encID = encID, phase = nil, TTS = false, dur = 5,
        spellID = nil, id = 0, difficulties = {14, 15, 16}, enabled = true, isSpecialDisplay = true, BlockCopy = true, Preview = WindsPreview,
        Scale = 1, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -500, yOffset = 400, BackgroundColor = {0.2, 0.2, 0.2, 1}, ShowSenderNames = false,
        customIcon = 1285732,
        extraOptions = {
            { Type = "Label", text = "Winds Helper" },
            { Type = "Slider", label = "Scale", min = 0.5, max = 2,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.Scale or 1 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.Scale    = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Slider",   label = "xOffset",        min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.xOffset  or 200 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.xOffset  = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Slider",   label = "yOffset",        min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.yOffset  or -300 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.yOffset  = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Color",    label = "BackgroundColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3420][16].WindsHelper.BackgroundColor or {0.2,0.2,0.2,1} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.BackgroundColor = {r,g,b,a} end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Checkbox", label = "ShowSenderNames",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.ShowSenderNames  or false  end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.ShowSenderNames  = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]],
                tooltip = {title = "ShowSenderNames", desc = "Shows the sender next to each entered number."}},
            { Type = "Button", label = "Create Macros", width = 150,
                func = [[return function()
                    local iconIDs = {"137001", "137002", "137003", "137004", "137005", "137006", "137007", "137008"}
                    for i=1, 8 do
                        local macroName = "NSRT_SSZORAK_" .. i
                        if not GetMacroInfo(macroName) then
                            CreateMacro(macroName, iconIDs[i], "/raid " .. i)
                        else
                            EditMacro(macroName, macroName, iconIDs[i], "/raid " .. i)
                        end
                    end
                end]],
                tooltip = {title = "Create Macros", desc = "Creates macros that post numbers 1 through 8 with the matching raid-marker icons and will trigger the display mid-fight. All you have to do is press the macro's in the order you want the Knocks to be triggered during the Dmg-Amp. If new messages come in after 3 have already filled it will simply start from the beginning, that way you can fix mistakes."}},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id, preview)
    local realpull = not id
    id = id or self:DifficultyCheck({14, 15, 16}) or 0
    local winds = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].WindsHelper
    if winds and ((winds.enabled and self:EvaluateLoad(winds) and realpull) or (preview and preview == "Winds Helper")) then
        local s = winds
        if not self.WindsFrame then
            self.WindsFrame = CreateFrame("Frame", nil, self.NSRTFrame, "BackdropTemplate")
            self.WindsFrame:SetSize(180, 80)
            self.WindsFrame:SetFrameStrata("MEDIUM")
            self.WindsDisplay = {}
            self.WindsNumbers = {}
            self.WindsSenderNames = {}
            for index = 1, 3 do
                local icon = self.WindsFrame:CreateFontString(nil, "ARTWORK")
                icon:SetFont(self:GetGlobalFontPath(), 15)
                icon:SetPoint("BOTTOMLEFT", self.WindsFrame, "BOTTOMLEFT", (index - 1) * 60, 0)
                self.WindsDisplay[index] = icon

                local number = self.WindsFrame:CreateFontString(nil, "OVERLAY")
                number:SetFont(self:GetGlobalFontPath(), 22, "OUTLINE")
                number:SetPoint("BOTTOM", icon, "TOP", 0, 2)
                number:SetTextColor(1, 1, 1, 1)
                self.WindsNumbers[index] = number

                local senderName = self.WindsFrame:CreateFontString(nil, "OVERLAY")
                senderName:SetFont(self:GetGlobalFontPath(), 16, "OUTLINE")
                senderName:SetPoint("TOP", icon, "BOTTOM", 0, -2)
                senderName:SetTextColor(1, 1, 1, 1)
                self.WindsSenderNames[index] = senderName
            end
        end

        local function HideAllWinds()
            self.WindsFrame:Hide()
            for index = 1, 3 do
                self.WindsDisplay[index]:Hide()
                self.WindsNumbers[index]:Hide()
                self.WindsSenderNames[index]:Hide()
            end
            self.WindsCount = 0
        end

        local function DisplayWind(pos, text, sender, senderGUID, senderDisplayName)
            if not pos then
                self.WindsCount = (self.WindsCount or 0) + 1
                if self.WindsCount > 3 then
                    HideAllWinds()
                    self.WindsCount = 1
                end
                pos = self.WindsCount
            end

            self.WindsFrame:Show()
            self.WindsDisplay[pos]:SetFormattedText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%s:48:48|t", text)
            self.WindsDisplay[pos]:Show()
            self.WindsNumbers[pos]:SetText(pos)
            self.WindsNumbers[pos]:Show()
            if s.ShowSenderNames then
                local classFilename = senderGUID and select(2, UnitClassFromGUID(senderGUID))
                local classColor = classFilename and C_ClassColor.GetClassColor(classFilename)
                local senderNameClassColored = senderDisplayName or (classColor and C_ColorUtil.WrapTextInColor(sender, classColor) or sender)
                self.WindsSenderNames[pos]:SetFormattedText("%s", senderNameClassColored)
                self.WindsSenderNames[pos]:Show()
            else
                self.WindsSenderNames[pos]:Hide()
            end
        end
        self.WindsFrame:ClearAllPoints()
        self.WindsFrame:SetScale(s.Scale)
        self.WindsFrame:SetPoint(s.Anchor, self.NSRTFrame, s.relativeTo, s.xOffset, s.yOffset)
        self.WindsFrame:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8X8]],
            edgeFile = [[Interface\Buttons\WHITE8X8]],
            edgeSize = 1,
        })
        self.WindsFrame:SetBackdropColor(unpack(s.BackgroundColor))
        self.WindsFrame:SetBackdropBorderColor(unpack(s.BackgroundColor))
        HideAllWinds()

        if preview then
            self.IsSszorakWindsPreview = true
            self:MakeDraggable(self.WindsFrame, s, true)
            local previewNumbers = {1, 2, 3, 4, 5, 6, 7, 8}
            for index = 8, 2, -1 do
                local swapIndex = math.random(index)
                previewNumbers[index], previewNumbers[swapIndex] = previewNumbers[swapIndex], previewNumbers[index]
            end
            for index = 1, 3 do
                DisplayWind(index, secretwrap(previewNumbers[index]), secretwrap(UnitName("player")), secretwrap(UnitGUID("player")))
            end
            return
        end

        self:EncounterRegister("SszorakWinds", {"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER"}, true)
        self:EncounterFunction("SszorakWinds", function(_, event, message, sender, ...)
            local senderGUID = select(10, ...)
            local senderDisplayName = event == "CHAT_MSG_RAID_LEADER" and UnitExists("raid1") and NSAPI:Shorten("raid1", 12, false, "GlobalNickNames") or nil
            DisplayWind(nil, message, sender, senderGUID, senderDisplayName)
        end)

        local diffData = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id]
        local damageAmp = diffData and diffData.DamageAmp
        local resetTimes = damageAmp and damageAmp.timers or damageAmpTimers[id]
        self.WindsResetTimers = {}
        for _, time in ipairs(resetTimes or {}) do
            self.WindsResetTimers[#self.WindsResetTimers + 1] = C_Timer.NewTimer(time + 20, function()
                HideAllWinds()
            end)
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self)
    self:EncounterRegister("SszorakWinds", {"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER"}, false)
    if self.IsSszorakWindsPreview and self.WindsFrame then
        self:MakeDraggable(self.WindsFrame, nil, false)
    end
    self.IsSszorakWindsPreview = false
    if self.WindsResetTimers then
        for _, timer in ipairs(self.WindsResetTimers) do
            timer:Cancel()
        end
        self.WindsResetTimers = nil
    end
    if self.WindsFrame then
        self.WindsFrame:Hide()
        for index = 1, 3 do
            self.WindsDisplay[index]:Hide()
            self.WindsNumbers[index]:Hide()
            self.WindsSenderNames[index]:Hide()
        end
        self.WindsCount = 0
    end
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    local settings = self.Assignments and self.Assignments[encID]
    if not settings then return end

    local diff = id or self:DifficultyCheck({14, 15, 16})
    if not diff or not tankComboTimers[diff] then return end
    if UnitGroupRolesAssigned("player") == "TANK" then return end

    local group
    if diff == 16 then
        if not settings.Mythic then return end
        group = self:GetSubGroup("player") <= 2 and 1 or 2
    else
        if not settings.NormalHeroic then return end
        local _, first = self:GetSortedGroup(true, false, false)
        group = 2
        for _, member in ipairs(first) do
            if UnitIsUnit(member.unitid, "player") then
                group = 1
                break
            end
        end
    end

    local alert = self:CreateDefaultAlert("", "Text", nil, nil, 1, encID)
    alert.dur = 6
    alert.TTSTimer = 0
    for _, timer in ipairs(tankComboTimers[diff]) do
        alert.time = timer
        alert.text = group == 1 and "|cFF00FF00Soak Left" or "|cFF00FF00Soak Right"
        alert.TTS = group == 1 and "Soak Left" or "Soak Right"
        self:AddToReminder(alert)
    end

    if NSRT.AssignmentSettings.OnPull then
        local side = group == 1 and "Left" or "Right"
        self:DisplayText("You are assigned to soak |cFF00FF00" .. side .. "|r", 5)
    end
end
