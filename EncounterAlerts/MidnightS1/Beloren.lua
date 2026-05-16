local _, NSI = ... -- Internal namespace

local encID = 3182
-- /run NSAPI:DebugEncounter(3182)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local data = {group = {nil, "Beloren P1", "Beloren P2"}, internalID = "Gateway", text = "Gateway", DisplayType = "Bar", encID = encID, phase = 1, TTS = true, TTSTimer = 4, dur = 6.6, spellID = 311699,
    timers = {
            [15] = {{}, {6.6}, {6.6}},
            [16] = {{}, {6.6}, {6.6}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = {nil, "Beloren P1", "Beloren P2"}, internalID = "Next Hit", text = "Next Hit", DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 3.5, spellID = 1242792,
    timers = {
            [16] = {{}, {11.7, 15.2, 18.7, 22.2, 25.7, 29.2, 32.7, 36.2, 39.7, 43.2, 46.7}, {11.7, 15.2, 18.7, 22.2, 25.7, 29.2, 32.7, 36.2, 39.7, 43.2, 46.7}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = {"Beloren P1", "Beloren P2"}, internalID = "Soaks", text = "Soaks", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8, spellID = nil,
    timers = {
            [16] = {{18.8, 68.8}, {70.6, 120.6, 170.6}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = {"Beloren P1", "Beloren P2"}, internalID = "Quills", text = "Quills", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = nil,
    timers = {
            [16] = {{27.4, 37.4, 47.4, 77.4, 87.4, 97.4}, {79.2, 89.2, 99.2, 129.2, 139.2, 149.2, 179.2}},
        },
    }
    self:AddEncounterAlert(data)

    local FeatherColorIconPreview = [[
        return function(self, update)
            if self.FeatherColorIconPreview then
                self.EncounterAlertStop[3182](self, "Feather Color")
                self.FeatherColorIconPreview = false
            else
                self.EncounterAlertStart[3182](self, 16, "Feather Color")
                self.FeatherColorIconPreview = true
            end
        end
    ]]
    local data = {
        internalID = "Feather Color",
        text = nil,
        DisplayType = "Icon",
        encID = encID,
        phase = nil,
        TTS = false,
        dur = 5,
        id = 0,
        spellID = nil,
        difficulties = {14, 15, 16},
        customIcon = 1241162,
        timers = nil,
        overrides = {pinned = true, BlockCopy = true, Size = 100, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 300, yOffset = -300},
        Preview = FeatherColorIconPreview,
        extraOptions = {
            {
                Type = "Label",
                text = "Feather Color Icon"
            },
            {
                Type = "Slider",
                label = "Size",
                min = 50,
                max = 200,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3182][16]["Feather Color"].Size or 100 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3182][i]["Feather Color"].Size = v end NSI.EncounterAlertStop[3182](NSI, true) NSI.EncounterAlertStart[3182](NSI, 16, true) end]]
            },
        },
    }
    self:AddEncounterAlert(data)

    local ColorSwapPreview = [[
        return function(self, update)
            self.EncounterAlertStart[3182](self, 16, "Color Swap")
        end
    ]]
    local data = {
        internalID = "Color Swap",
        text = "SWAPPED",
        DisplayType = "Text",
        encID = encID,
        phase = nil,
        TTS = false,
        dur = 3,
        id = 0.1,
        spellID = nil,
        customIcon = 1242792,
        difficulties = {14, 15, 16},
        timers = nil,
        overrides = {pinned = true, BlockCopy = true},
        HideTimer = true,
        Preview = ColorSwapPreview,
    }
    self:AddEncounterAlert(data)
end

local detectedDurations = { -- Death Drop
    [14] = { { time = 6, phase = function(num) return num + 1 end } },
    [15] = { { time = 6, phase = function(num) return num + 1 end } },
    [16] = { { time = 6, phase = function(num) return num + 1 end } },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if not difficultyID or not detectedDurations[difficultyID] then return end
    table.insert(self.Timelines, now)
    if self.Phase >= 2 and ApproximatelyEqual(info.duration, 40, 0.2) then
        local diff = now - self.PhaseSwapTime
        local offset = diff - 7.1
        if diff <= 20 and offset > 0.3 then -- bird has delayed his landing so we extend all timers
            self:DelayAllReminders(offset)
        end
    end
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        if info.duration == phaseinfo.time then
            local count = 0
            for i, v in ipairs(self.Timelines) do
                if now < v + 0.1 then count = count + 1 end
            end
            local newphase = phaseinfo.phase(self.Phase)
            if newphase > self.Phase and count <= 1 then
                self.Phase = newphase
                self:StartReminders(self.Phase)
                self.PhaseSwapTime = now
                break
            end
        end
    end
end

NSI.EncounterAlertStart[encID] = function(self, id, preview) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    local featherColor = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id]["Feather Color"]
    local colorSwap = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id]["Color Swap"]

    if featherColor and ((featherColor.enabled and self:EvaluateLoad(featherColor) and not preview) or (preview and preview == "Feather Color")) then
        local s = NSRT.EncounterAlerts[encID][id]["Feather Color"]

        if not self.FeatherColorIconFrame then
            self.FeatherColorIconFrame = CreateFrame("Frame", "NSRTFeatherColorIconFrame", self.NSRTFrame)
            self.FeatherColorIconFrame.texture = self.FeatherColorIconFrame:CreateTexture("NSRTFeatherColorIconFrameTexture", "BACKGROUND")
            self.FeatherColorIconFrame.texture:SetAllPoints()
        end

        self.FeatherColorIconFrame:ClearAllPoints()
        self.FeatherColorIconFrame:SetPoint(s.Anchor or "CENTER", self.NSRTFrame, s.relativeTo or "CENTER", s.xOffset or 0, s.yOffset or 0)
        self.FeatherColorIconFrame:SetWidth(s.Size or 100)
        self.FeatherColorIconFrame:SetHeight(s.Size or 100)

        if preview then
            local light = math.random(1, 2) == 1
            self.FeatherColorIconFrame.texture:SetTexture(light and 7636520 or 7636525)
            self:MakeDraggable(self.FeatherColorIconFrame, s, true)
            return
        end

        self.FeatherColorIconFrame:RegisterUnitEvent("UNIT_AURA", "player")
        self.FeatherColorIconFrame:SetScript("OnEvent", function(_, e, ...)
            local unit, info = ...
            if not info.addedAuras then return end

            self.FeatherColorIconFrame:Hide()

            -- all debuff aura instance IDs on us that we applied ourselves
            local playerCastAuraInstanceIDsTest = {}
            local playerCastAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs("player", "HARMFUL|PLAYER")
            for _, auraInstanceID in ipairs(playerCastAuraInstanceIDs) do
                playerCastAuraInstanceIDsTest[auraInstanceID] = true
            end

            -- all debuff aura instance IDs on us, sorted by duration (infinite duration first)
            local auras = C_UnitAuras.GetUnitAuras("player", "HARMFUL", 10, Enum.UnitAuraSortRule.ExpirationOnly, Enum.UnitAuraSortDirection.Reverse)
            for _, aura in ipairs(auras) do
                -- first debuff we see that we didn't apply ourselves is probably the feather
                if not playerCastAuraInstanceIDsTest[aura.auraInstanceID] then
                    self.FeatherColorIconFrame.texture:SetTexture(aura.icon)
                    self.FeatherColorIconFrame:Show()
                    return
                end
            end
        end)
    end

    if colorSwap and ((colorSwap.enabled and self:EvaluateLoad(colorSwap) and not preview) or (preview and preview == "Color Swap")) then
        local s = NSRT.EncounterAlerts[encID][id]["Color Swap"]

        self.channeling = false

        self:EncounterRegister("UNIT_SPELLCAST_CHANNEL_START", true, "boss1")
        self:EncounterRegister("UNIT_SPELLCAST_CHANNEL_STOP", true, "boss1")
        self:EncounterRegister("ENCOUNTER_WARNING", true)
        self.EncounterFrame:SetScript("OnEvent", function(_, e, ...)
            if e == "UNIT_SPELLCAST_CHANNEL_START" then
                self.channeling = true
            elseif e == "UNIT_SPELLCAST_CHANNEL_STOP" then
                self.channeling = false
            elseif e == "ENCOUNTER_WARNING" then
                if not self.channeling then
                    return
                end
                local encounterWarningInfo = ...
                local icon = "\124T"..encounterWarningInfo.iconFileID..":12:12:0:0:64:64:4:60:4:60\124t"
                local text = string.format("%s %s %s", icon, s.text, icon)

                local info = self:CreateReminder(CopyTable(s), true)
                info.text = text

                self:DisplayReminder(info)
            end
        end)

        if preview then
            local light = math.random(1, 2) == 1
            local iconFileID = light and secretwrap(7636520) or secretwrap(7636525)
            local icon = "\124T"..iconFileID..":12:12:0:0:64:64:4:60:4:60\124t"
            local text = string.format("%s %s %s", icon, s.text, icon)

            local info = self:CreateReminder(CopyTable(s), true)
            info.text = text

            self:DisplayReminder(info)
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self, preview) -- on ENCOUNTER_END
    if self.FeatherColorIconFrame then
        if preview and preview == "Feather Color" then
            self:MakeDraggable(self.FeatherColorIconFrame, nil, false)
        end
        self.FeatherColorIconFrame:Hide()
        self.FeatherColorIconFrame:UnregisterAllEvents()
    end
end
