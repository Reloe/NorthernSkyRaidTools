local _, NSI = ... -- Internal namespace

NSI.EncounterDetections = {
   -- [123] = {0, 10, 15, 20} [EncounterID] = {P1, P2, P3, etc} First is always 0 because it is for P1 which we start in.
}

function NSI:ProcessAssigns()
    if self.Assigns and self.Assigns ~= "" then
        self.ProcessedAssigns = {}
        for line in self.Assigns:gmatch('[^\r\n]+') do
            if line:find("EncounterID:") then
                self.ProcessedAssigns.EncounterID = line:match("EncounterID:(%d+)")
            end
            local phase = line:match("phase:(%d+)")
            local time = line:match("time:(%d*%.?%d+)")
            local name = line:match("name:([^;]+)")
            local text = line:match("text:([^;]+)")
            local TTS = line:match("TTS:([^;]+)")
            local spellID = line:match("spellID:(%d+)")
            local dur = line:match("dur:(%d+)")
            local sound = line:match("sound:([^;]+)")
            if phase and time and name and (text or spellID) then
                if name == "everyone" or name:match(UnitName("player")) or name:match(UnitGroupRolesAssigned("player")) or name:match(NSAPI:GetName("player", "GlobalNickNames")) then     
                    phase = tonumber(phase)
                    text = text:gsub("{rt(%d)}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%1:0|t")
                    self.ProcessedAssigns[phase] = self.ProcessedAssigns[phase] or {}             
                    table.insert(self.ProcessedAssigns[phase], {phase = phase, id = #self.ProcessedAssigns[phase]+1, sound = sound, time = tonumber(time), text = text, TTS = TTS, spellID = spellID and tonumber(spellID), dur = dur or 8})
                end
            end
        end
    end
end

function NSI:CreateText(info)
    self.AssignText = self.AssignText or {}
    for i=1, 20 do
        if self.AssignText[i] and not self.AssignText[i]:IsShown() then 
            self.AssignText[i]:SetScript("OnUpdate", function()
                NSI:UpdateReminderDisplay(info, self.AssignText[i])
            end)
            return self.AssignText[i] 
        end
        if not self.AssignText[i] then
            local xOffset, yOffset = -200, 200
            local Font = self.LSM:Fetch("font", "PT Sans Narrow Bold")
            local FontSize = 50
            yOffset = yOffset + (i-1) * FontSize
            self.AssignText[i] = CreateFrame("Frame", nil, UIParent)
            self.AssignText[i].Text = self.AssignText[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.AssignText[i].Text:SetPoint("LEFT", UIParent, "CENTER", xOffset, yOffset)
            self.AssignText[i].Text:SetFont(Font, FontSize, "OUTLINE")
            self.AssignText[i].Text:SetShadowColor(0, 0, 0, 1)
            self.AssignText[i].Text:SetShadowOffset(0, 0)
            self.AssignText[i].Text:SetTextColor(1, 1, 1, 1)
            self.AssignText[i]:SetScript("OnUpdate", function()
                NSI:UpdateReminderDisplay(info, self.AssignText[i])
            end)
            return self.AssignText[i]
        end
    end
end

function NSI:CreateIcon(spellID, info)
    self.AssignIcon = self.AssignIcon or {}
    local icon = C_Spell.GetSpellInfo(spellID).iconID
    for i=1, 20 do
        if self.AssignIcon[i] and not self.AssignIcon[i]:IsShown() then 
            self.AssignIcon[i].Icon:SetTexture(icon)
            self.AssignIcon[i].TimerText:SetTextColor(1, 1, 0, 1)
            self.AssignIcon[i].Swipe:SetCooldown(GetTime(), info.dur)
            self.AssignIcon[i]:SetScript("OnUpdate", function()
                NSI:UpdateReminderDisplay(info, self.AssignIcon[i])
            end)
            return self.AssignIcon[i] 
        end
        if not self.AssignIcon[i] then
            local xOffset, yOffset = -400, 400
            local xTextOffset, yTextOffset = 0, 0
            local xTimer, yTimer = 0, 0
            local Font = self.LSM:Fetch("font", "PT Sans Narrow Bold")
            local Size = 80
            local FontSize = 22
            local TimerFontSize = 40
            yOffset = yOffset + (i-1) * Size
            self.AssignIcon[i] = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            self.AssignIcon[i]:SetSize(Size, Size)
            self.AssignIcon[i]:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
            self.AssignIcon[i].Icon = self.AssignIcon[i]:CreateTexture(nil, "ARTWORK")
            self.AssignIcon[i].Icon:SetAllPoints(self.AssignIcon[i])
            self.AssignIcon[i].Icon:SetTexture(icon)
            self.AssignIcon[i].Border = CreateFrame("Frame", nil, self.AssignIcon[i], "BackdropTemplate")
            self.AssignIcon[i].Border:SetAllPoints(self.AssignIcon[i])
            self.AssignIcon[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.AssignIcon[i].Border:SetBackdropBorderColor(0, 0, 0, 1)
            self.AssignIcon[i].Text = self.AssignIcon[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.AssignIcon[i].Text:SetPoint("LEFT", self.AssignIcon[i], "RIGHT", xTextOffset, yTextOffset)
            self.AssignIcon[i].Text:SetFont(Font, FontSize, "OUTLINE")
            self.AssignIcon[i].Text:SetShadowColor(0, 0, 0, 1)
            self.AssignIcon[i].Text:SetShadowOffset(0, 0)
            self.AssignIcon[i].Text:SetTextColor(1, 1, 1, 1)
            self.AssignIcon[i].Swipe = CreateFrame("Cooldown", nil, self.AssignIcon[i], "CooldownFrameTemplate")
            self.AssignIcon[i].Swipe:SetAllPoints()
            self.AssignIcon[i].Swipe:SetDrawEdge(false)
            self.AssignIcon[i].Swipe:SetReverse(true)
            self.AssignIcon[i].Swipe:SetCooldown(GetTime(), info.dur)
            self.AssignIcon[i].Swipe:SetHideCountdownNumbers(true)
            self.AssignIcon[i].TimerText = self.AssignIcon[i].Swipe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.AssignIcon[i].TimerText:SetPoint("CENTER", self.AssignIcon[i].Swipe, "CENTER", xTimer, yTimer)
            self.AssignIcon[i].TimerText:SetFont(Font, TimerFontSize, "OUTLINE")
            self.AssignIcon[i].TimerText:SetShadowColor(0, 0, 0, 1)
            self.AssignIcon[i].TimerText:SetShadowOffset(0, 0)
            self.AssignIcon[i].TimerText:SetTextColor(1, 1, 0, 1)
            self.AssignIcon[i].TimerText:SetDrawLayer("OVERLAY", 7)
            self.AssignIcon[i]:SetScript("OnUpdate", function()
                NSI:UpdateReminderDisplay(info, self.AssignIcon[i])
            end)
            return self.AssignIcon[i]
        end
    end
end

function NSI:CreateBar(spellID, info)
    self.AssignBar = self.AssignBar or {}
    local icon = C_Spell.GetSpellInfo(spellID).iconID
    for i=1, 20 do
        if self.AssignBar[i] and not self.AssignBar[i]:IsShown() then 
            self.AssignBar[i].Icon:SetTexture(icon)
            self.AssignBar[i]:SetScript("OnUpdate", function()
                NSI:UpdateReminderDisplay(info, self.AssignBar[i])
            end)
            return self.AssignBar[i] 
        end
        if not self.AssignBar[i] then
            local Width, Height = 240, 30
            local xOffset, yOffset = 400, 0
            local xIcon, yIcon = 0, 0
            local xTextOffset, yTextOffset = 2, 0
            local xTimer, yTimer = -2, 0
            local Font = self.LSM:Fetch("font", "PT Sans Narrow Bold")
            local Texture = "Atrocity"
            local Size = 80
            local FontSize = 22
            local colors = {1, 0, 0, 1}
            yOffset = yOffset + (i-1) * Height
            self.AssignBar[i] = CreateFrame("StatusBar", nil, UIParent, "BackdropTemplate")
            self.AssignBar[i]:SetBackdrop({ 
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            tileSize = 0,
            }) 
            self.AssignBar[i]:SetSize(Width, Height)
            self.AssignBar[i]:SetStatusBarTexture(self.LSM:Fetch("statusbar", Texture))
            self.AssignBar[i]:SetStatusBarColor(unpack(colors))
            self.AssignBar[i]:SetBackdropColor(0, 0, 0, 0.5)
            self.AssignBar[i]:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
            self.AssignBar[i].Border = CreateFrame("Frame", nil, self.AssignBar[i], "BackdropTemplate")
            self.AssignBar[i].Border:SetAllPoints(self.AssignBar[i])
            self.AssignBar[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.AssignBar[i].Border:SetBackdropBorderColor(0, 0, 0, 1)
            self.AssignBar[i].Icon = self.AssignBar[i]:CreateTexture(nil, "ARTWORK")
            self.AssignBar[i].Icon:SetPoint("RIGHT", self.AssignBar[i], "LEFT", xIcon, yIcon)
            self.AssignBar[i].Icon:SetSize(Height, Height)
            self.AssignBar[i].Icon:SetTexture(icon)
            self.AssignBar[i].Text = self.AssignBar[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.AssignBar[i].Text:SetPoint("LEFT", self.AssignBar[i].Icon, "RIGHT", xTextOffset, yTextOffset)
            self.AssignBar[i].Text:SetFont(Font, FontSize, "OUTLINE")
            self.AssignBar[i].Text:SetShadowColor(0, 0, 0, 1)
            self.AssignBar[i].Text:SetShadowOffset(0, 0)
            self.AssignBar[i].Text:SetTextColor(1, 1, 1, 1)
            self.AssignBar[i].TimerText = self.AssignBar[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.AssignBar[i].TimerText:SetPoint("RIGHT", self.AssignBar[i], "RIGHT", xTimer, yTimer)
            self.AssignBar[i].TimerText:SetFont(Font, FontSize, "OUTLINE")
            self.AssignBar[i].TimerText:SetShadowColor(0, 0, 0, 1)
            self.AssignBar[i].TimerText:SetShadowOffset(0, 0)
            self.AssignBar[i].TimerText:SetTextColor(1, 1, 1, 1)

            self.AssignBar[i]:SetScript("OnUpdate", function()
                NSI:UpdateReminderDisplay(info, self.AssignBar[i])
            end)
            return self.AssignBar[i]
        end
    end
end

function NSI:DisplayReminder(info)
    local dur = info.dur or 8
    info.startTime = GetTime()
    info.dur = dur
    local rem = info.dur - (GetTime() - info.startTime)
    if rem <= 0 then
        return
    end
    local remString
    if rem < 3 then
        rem = math.floor(rem * 10 + 0.5) / 10
        remString = string.format("%.1f", rem)
    else
        remString = tostring(math.ceil(rem))
    end
    local remString = (rem % 1 == 0) and string.format("%.1f", rem) or rem
    local text = info.text ~= "" and info.text or ""
    local F
    if info.spellID then -- display icon if we have a spellID    
        if NSRT.ReminderSettings.Bars then
            F = self:CreateBar(info.spellID, info)
            F:SetMinMaxValues(0, info.dur)
            F:SetValue(0)
        else
            F = self:CreateIcon(info.spellID, info)
        end
        F.Text:SetText(text)
        F.TimerText:SetText(remString)
        F:Show()
    else
        F = self:CreateText(info)
        F.Text:SetText(text.." - ("..remString..")" or remString)
        F:Show()
    end    
    local sound = info.sound and self.LSM:Fetch("sound", info.sound)
    if sound and sound ~= 1 then
        PlaySoundFile(sound, "Master")
        return      
    elseif info.TTS and info.TTS ~= "" and strlower(info.TTS) ~= "false" then
        local TTS = (strlower(info.TTS) == "true" and info.text) or (info.TTS == info.text and info.text) or info.TTS
        sound = self.LSM:Fetch("sound", TTS)
        if sound and sound ~= 1 then
            PlaySoundFile(sound, "Master")
            return
        else
            NSAPI:TTS(TTS)
        end
    end
end

function NSI:UpdateReminderDisplay(info, F)
    local rem = info.dur - (GetTime() - info.startTime)
    if rem <= 0 then
        F:Hide()
        return
    end
    local remString
    if rem < 3 then
        rem = math.floor(rem * 10 + 0.5) / 10
        remString = string.format("%.1f", rem)
    else
        remString = tostring(math.ceil(rem))
    end
    local text = info.text ~= "" and info.text.." - ("..remString..")" or remString
    if info.spellID and type(info.spellID) == "number" then
        if NSRT.ReminderSettings.Bars then
            F:SetValue((GetTime()-info.startTime))
        else
            if rem <= 3 then
                F.TimerText:SetTextColor(1, 0, 0, 1)
            end
        end
        F.TimerText:SetText(remString)
    else
        F.Text:SetText(text)
    end    
end

function NSI:StartReminders(phase)
    print("starting timers for phase:", phase)
    self:HideAllReminders()
    for i, v in ipairs(self.ProcessedAssigns[phase]) do
        self.ReminderTimer[i] = C_Timer.NewTimer(v.time, function()
            self:DisplayReminder(v)
        end)
    end
end

function NSI:HideAllReminders()
    for i, v in ipairs(self.ReminderTimer) do
        v:Cancel()
    end
    for i=1, 20 do
        if self.AssignText then
            local F = self.AssignText[i]
            if F then F:Hide() end
        end
        if self.AssignIcon then
            local F = self.AssignIcon[i]
            if F then F:Hide() end
        end
        if self.AssignBar then            
            local F = self.AssignBar[i]
            if F then F:Hide() end
        end
    end
end

function NSI:SetReminder(name)
    if NSRT.Reminders[name] then
        self.Assigns = NSRT.Reminders[name]
    end
end

function NSI:ImportReminder(name, values)
    NSRT.Reminders[name] = values
    -- NSI:UpdateReminderList()
end

function NSI:DetectPhaseChange()
    local now = GetTime()
    local needed = self.Timelines and self.PhaseSwapTime and (now > self.PhaseSwapTime+5) and self.EncounterID and self.Phase and self.EncounterDetections[self.EncounterID] and self.EncounterDetections[self.EncounterID][self.Phase+1]
    if needed then
        table.insert(self.Timelines, now+1)
        local count = 0
        for i, v in ipairs(self.Timelines) do
            if v > now then
                count = count+1
                if count > needed then
                    self.Phase = self.Phase+1
                    self:StartReminders(phase)
                    self.PhaseSwapTime = now
                    break
                end
            end           
        end
    end
end

-- /run NSAPI:DebugReminder(2400)
-- Debug has to be run before pulling. If player isn't raidlead it needs to be done after ready check.
-- or /run NSAPI:DebugReminder(2400, true) to test outside of combat
function NSAPI:DebugReminder(EncounterID, startnow)
    if NSRT.Settings["Debug"] then
        local text = "EncounterID:"..EncounterID.."\nphase:1;time:5;name:Relowindi;text:Stack on {rt7};sound:Stack;TTS:Stack on Red;dur:10;"
        text = text.."\n".."phase:1;time:9;name:Relowindi;text:Use Fort Brew;TTS:true;spellID:243435;dur:10;"
        text = text.."\n".."phase:1;time:17;name:Relowindi;text:Use Ring;TTS:true;spellID:116844;dur:10;"
        text = text.."\n".."phase:1;time:25;name:Relowindi;text:Spread;TTS:true;dur:10;"
        text = text.."\n".."phase:2;time:10;name:Relowindi;text:Check for Debuff;TTS:true;dur:10"
        if not NSI.EncounterDetections[EncounterID] then
            NSI.EncounterDetections[EncounterID] = {0, 8, 8}
        end
        NSI.Assigns = text
        NSI:ProcessAssigns()
        if startnow then
            NSI:EventHandler("ENCOUNTER_START", true, true, EncounterID)
        end
    end
end