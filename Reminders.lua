local _, NSI = ... -- Internal namespace

function NSI:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
    self.ProcessedReminder = self.ProcessedReminder or {}
    self.ProcessedReminder[encID] = self.ProcessedReminder[encID] or {}
    spellID = spellID and tonumber(spellID)
    -- convert to booleans
    if TTS == "true" then TTS = true end
    if TTS == "false" then TTS = false end
    -- default to user settings if not overwritten by the reminders
    if TTS == nil then 
        if spellID then
            TTS = NSRT.ReminderSettings.SpellTTS
        else
            TTS = NSRT.ReminderSettings.TextTTS
        end
    end            
    if dur == nil then 
        if spellID then
             dur = NSRT.ReminderSettings.SpellDuration 
        else
            dur = NSRT.ReminderSettings.TextDuration 
        end
    end
    if countdown == nil then
        if spellID then
            countdown = NSRT.ReminderSettings.SpellCountdown
        else
            countdown = NSRT.ReminderSettings.TextCountdown
        end
        if countdown == 0 then countdown = false end
    end
    if TTSTimer == nil then
        if spellID then
            TTSTimer = NSRT.ReminderSettings.SpellTTSTimer
        else
            TTSTimer = NSRT.ReminderSettings.TextTTSTimer
        end
    end
    phase = phase and tonumber(phase)
    if not phase then phase = 1 end
    if text then text = text:gsub("{rt(%d)}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%1:0|t") end                    
    if NSRT.ReminderSettings.SpellName and spellID then -- display spellname if text is empty, also make TTS that spellname
        local spell = C_Spell.GetSpellInfo(spellID) 
        if spell and not text then 
            text = spell.name or ""
            TTS = TTS and type(TTS) ~= "string" and spell.name
        end 
    end
    if TTS and text and type(TTS) == "boolean" then
        TTS = text
    end
    if TTS and type(TTS) ~= "string" and spellID then -- TTS is enabled but it's still empty, which means text was empty so we should play the spellname TTS instead
        local spell = C_Spell.GetSpellInfo(spellID)
        TTS = spell and spell.name
    end
    self.ProcessedReminder[encID][phase] = self.ProcessedReminder[encID][phase] or {}    
    table.insert(self.ProcessedReminder[encID][phase], {TTSTimer = TTSTimer, phase = phase, id = #self.ProcessedReminder[encID][phase]+1, countdown = countdown and tonumber(countdown), glowunit = glowunit, sound = sound, time = tonumber(time), text = text, TTS = TTS, spellID = spellID and tonumber(spellID), dur = dur or 8})      
end

function NSI:ProcessReminder()
    self.ProcessedReminder = {}
    if self.Reminder and self.Reminder ~= "" then
        local subgroup = self:GetSubGroup("player")        
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        local pos = self.spectable[specid]
        local encID = 0
        pos = (pos <= 19 and pos >= 7 and "meleedps") or (pos <= 33 and pos >= 20 and "rangeddps")
        for line in self.Reminder:gmatch('[^\r\n]+') do
            if line:find("EncounterID:") then
                encID = line:match("EncounterID:(%d+)")
                if encID then encID = tonumber(encID) end
            end
            local tag = line:match("tag:([^;]+)")
            local time = line:match("time:(%d*%.?%d+)")
            local text = line:match("text:([^;]+)")
            local spellID = line:match("spellid:(%d+)")
            if time and tag and subgroup and (text or spellID) and encID and encID ~= 0 then
                tag = strlower(tag)
                if tag == "everyone" or 
                tag:match(strlower(UnitName("player"))) or 
                tag:match(strlower(NSAPI:GetName("player", "GlobalNickNames"))) or 
                tag:match(strlower(UnitGroupRolesAssigned("player"))) or 
                tag:match(specid) or
                tag:match(strlower(select(2, UnitClass("player")))) or
                tag:match("group"..subgroup) or 
                (pos and tag:match(pos))
                then                         
                    local phase = line:match("ph:(%d+)")
                    local TTS = line:match("TTS:([^;]+)")
                    local countdown = line:match("countdown:(%d+)")
                    local dur = line:match("dur:(%d+)")
                    local sound = line:match("sound:([^;]+)")
                    local glowunit = line:match("glowunit:([^;]+)")
                    self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID)
                end
            end
        end
    end
end

function NSI:UpdateExistingFrames() -- called when user changes settings to not require a reload
    for i=1, 20 do
        local F = self.ReminderText and self.ReminderText[i]
        if F then
            local s = NSRT.ReminderSettings.TextSettings
            F.Text:SetPoint("LEFT", UIParent, "CENTER", s.xOffset, s.yOffset + (i-1) * s.FontSize)
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
        end
        F = self.ReminderIcon and self.ReminderIcon[i]
        if F then
            local s = NSRT.ReminderSettings.IconSettings
            F:SetSize(s.Size, s.Size)
            F:SetPoint("CENTER", UIParent, "CENTER", s.xOffset, s.yOffset + (i-1) * s.Size)
            F.Icon:SetAllPoints(F)
            F.Border:SetAllPoints(F)
            F.Text:SetPoint("LEFT", F, "RIGHT", s.xTextOffset, s.yTextOffset)
            F.TimerText:SetPoint("CENTER", F.Swipe, "CENTER", s.xTimer, s.yTimer)
            F.TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
        end
        F = self.UnitIcon and self.UnitIcon[i]
        if F then
            local s = NSRT.ReminderSettings.UnitIconSettings
            F:SetSize(s.Size, s.Size) -- not setting points in this one because this is repeated every time the frame is shown as it needs a new frame to anchor to anyway
        end
        F = self.ReminderBar and self.ReminderBar[i]
        if F then
            local s = NSRT.ReminderSettings.BarSettings
            F:SetSize(s.Width, s.Height)
            F:SetStatusBarTexture(self.LSM:Fetch("statusbar", s.Texture))
            F:SetStatusBarColor(unpack(s.colors))
            F:SetPoint("CENTER", UIParent, "CENTER", s.xOffset, s.yOffset + (i-1) * s.Height)
            F.Border:SetAllPoints(F)
            F.Icon:SetPoint("RIGHT", F, "LEFT", s.xIcon, s.yIcon)
            F.Icon:SetSize(s.Height, s.Height)
            F.Text:SetPoint("LEFT", F.Icon, "RIGHT", s.xTextOffset, s.yTextOffset)
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            F.TimerText:SetPoint("RIGHT", F, "RIGHT", s.xTimer, s.yTimer)
            F.TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
        end
    end
end

function NSI:SetProperties(F, info, skipsound, s)
    F:SetScript("OnUpdate", function()
        NSI:UpdateReminderDisplay(info, F, skipsound)
    end)
    F:SetScript("OnHide", function()
        NSI:HideGlow(info.glowunit, "p"..info.phase.."id"..info.id)
    end)    
    if not info.spellID then return end
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID    
    F.Icon:SetTexture(icon)
    if F.Swipe then 
        F.Swipe:SetCooldown(GetTime(), info.dur) 
        if NSRT.ReminderSettings.HideTimerText then 
            F.TimerText:Hide() 
        else
            F.TimerText:SetTextColor(1, 1, 0, 1)
        end
    elseif F.TimerText then
        F.TimerText:SetTextColor(1, 1, 1, 1)
    end
    F:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    F:SetScript("OnEvent", function(self, e, ...)
        local unit, _, spellID = ...
        if (NSI:IsMidnight() and not issecretvalue(spellID)) and spellID == info.spellID and UnitIsUnit("player", unit) and self:IsShown() then
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self:Hide()
        end
    end)
end

function NSI:CreateText(info)
    self.ReminderText = self.ReminderText or {}
    local s = NSRT.ReminderSettings.TextSettings
    for i=1, 20 do
        if self.ReminderText[i] and not self.ReminderText[i]:IsShown() then 
            self:SetProperties(self.ReminderText[i], info, false, s)
            return self.ReminderText[i] 
        end
        if not self.ReminderText[i] then            
            self.ReminderText[i] = CreateFrame("Frame", nil, UIParent)
            self.ReminderText[i].Text = self.ReminderText[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderText[i].Text:SetPoint("LEFT", UIParent, "CENTER", s.xOffset, s.yOffset + (i-1) * s.FontSize)
            self.ReminderText[i].Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            self.ReminderText[i].Text:SetShadowColor(0, 0, 0, 1)
            self.ReminderText[i].Text:SetShadowOffset(0, 0)
            self.ReminderText[i].Text:SetTextColor(1, 1, 1, 1)
            self:SetProperties(self.ReminderText[i], info, false, s)
            return self.ReminderText[i]
        end
    end
end

function NSI:CreateIcon(info)
    self.ReminderIcon = self.ReminderIcon or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    local s = NSRT.ReminderSettings.IconSettings
    for i=1, 20 do
        if self.ReminderIcon[i] and not self.ReminderIcon[i]:IsShown() then 
            self:SetProperties(self.ReminderIcon[i], info, false, s)
            return self.ReminderIcon[i] 
        end
        if not self.ReminderIcon[i] then
            self.ReminderIcon[i] = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            self.ReminderIcon[i]:SetSize(s.Size, s.Size)
            self.ReminderIcon[i]:SetPoint("CENTER", UIParent, "CENTER", s.xOffset, s.yOffset + (i-1) * s.Size)
            self.ReminderIcon[i].Icon = self.ReminderIcon[i]:CreateTexture(nil, "ARTWORK")
            self.ReminderIcon[i].Icon:SetAllPoints(self.ReminderIcon[i])
            self.ReminderIcon[i].Border = CreateFrame("Frame", nil, self.ReminderIcon[i], "BackdropTemplate")
            self.ReminderIcon[i].Border:SetAllPoints(self.ReminderIcon[i])
            self.ReminderIcon[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.ReminderIcon[i].Border:SetBackdropBorderColor(0, 0, 0, 1)
            self.ReminderIcon[i].Text = self.ReminderIcon[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderIcon[i].Text:SetPoint("LEFT", self.ReminderIcon[i], "RIGHT", s.xTextOffset, s.yTextOffset)
            self.ReminderIcon[i].Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            self.ReminderIcon[i].Text:SetShadowColor(0, 0, 0, 1)
            self.ReminderIcon[i].Text:SetShadowOffset(0, 0)
            self.ReminderIcon[i].Text:SetTextColor(1, 1, 1, 1)
            self.ReminderIcon[i].Swipe = CreateFrame("Cooldown", nil, self.ReminderIcon[i], "CooldownFrameTemplate")
            self.ReminderIcon[i].Swipe:SetAllPoints()
            self.ReminderIcon[i].Swipe:SetDrawEdge(false)
            self.ReminderIcon[i].Swipe:SetReverse(true)
            self.ReminderIcon[i].Swipe:SetHideCountdownNumbers(true)
            self.ReminderIcon[i].TimerText = self.ReminderIcon[i].Swipe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderIcon[i].TimerText:SetPoint("CENTER", self.ReminderIcon[i].Swipe, "CENTER", s.xTimer, s.yTimer)
            self.ReminderIcon[i].TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
            self.ReminderIcon[i].TimerText:SetShadowColor(0, 0, 0, 1)
            self.ReminderIcon[i].TimerText:SetShadowOffset(0, 0)
            self.ReminderIcon[i].TimerText:SetDrawLayer("OVERLAY", 7)                        
            self:SetProperties(self.ReminderIcon[i], info, false, s)
            return self.ReminderIcon[i]
        end
    end
end



function NSI:CreateUnitFrameIcon(info)    
    self.UnitIcon = self.UnitIcon or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID    
    local unit = NSAPI:GetChar(info.glowunit, true)
    local i = UnitInRaid(unit)
    if (not UnitExists(unit)) or (not i) then return end
    local F = self.RaidFrames["raid"..i]
    if not F then return end
    local s = NSRT.ReminderSettings.UnitIconSettings
    for i=1, 20 do
        if self.UnitIcon[i] and not self.UnitIcon[i]:IsShown() then 
            self.UnitIcon[i]:SetPoint("CENTER", F, "CENTER", s.xOffset, s.yOffset)
            self:SetProperties(self.UnitIcon[i], info, true, s)
            return self.UnitIcon[i] 
        end
        if not self.UnitIcon[i] then            
            self.UnitIcon[i] = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            self.UnitIcon[i]:SetSize(s.Size, s.Size)
            self.UnitIcon[i]:SetPoint("CENTER", F, "CENTER", s.xOffset, s.yOffset)
            self.UnitIcon[i].Icon = self.UnitIcon[i]:CreateTexture(nil, "ARTWORK")
            self.UnitIcon[i].Icon:SetAllPoints(self.UnitIcon[i])
            self.UnitIcon[i].Icon:SetTexture(icon)
            self.UnitIcon[i].Border = CreateFrame("Frame", nil, self.UnitIcon[i], "BackdropTemplate")
            self.UnitIcon[i].Border:SetAllPoints(self.UnitIcon[i])
            self.UnitIcon[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.UnitIcon[i].Border:SetBackdropBorderColor(0, 0, 0, 1)       
            self:SetProperties(self.UnitIcon[i], info, true, s)
            return self.UnitIcon[i]
        end
    end
end

function NSI:CreateBar(info)
    self.ReminderBar = self.ReminderBar or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    local s = NSRT.ReminderSettings.BarSettings
    for i=1, 20 do
        if self.ReminderBar[i] and not self.ReminderBar[i]:IsShown() then                 
            self:SetProperties(self.ReminderBar[i], info, false, s)
            return self.ReminderBar[i] 
        end
        if not self.ReminderBar[i] then            
            self.ReminderBar[i] = CreateFrame("StatusBar", nil, UIParent, "BackdropTemplate")
            self.ReminderBar[i]:SetBackdrop({ 
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            tileSize = 0,
            }) 
            self.ReminderBar[i]:SetSize(s.Width, s.Height)
            self.ReminderBar[i]:SetStatusBarTexture(self.LSM:Fetch("statusbar", s.Texture))
            self.ReminderBar[i]:SetStatusBarColor(unpack(s.colors))
            self.ReminderBar[i]:SetBackdropColor(0, 0, 0, 0.5)
            self.ReminderBar[i]:SetPoint("CENTER", UIParent, "CENTER", s.xOffset, s.yOffset + (i-1) * s.Height)
            self.ReminderBar[i].Border = CreateFrame("Frame", nil, self.ReminderBar[i], "BackdropTemplate")
            self.ReminderBar[i].Border:SetAllPoints(self.ReminderBar[i])
            self.ReminderBar[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.ReminderBar[i].Border:SetBackdropBorderColor(0, 0, 0, 1)
            self.ReminderBar[i].Icon = self.ReminderBar[i]:CreateTexture(nil, "ARTWORK")
            self.ReminderBar[i].Icon:SetPoint("RIGHT", self.ReminderBar[i], "LEFT", s.xIcon, s.yIcon)
            self.ReminderBar[i].Icon:SetSize(s.Height, s.Height)
            self.ReminderBar[i].Text = self.ReminderBar[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderBar[i].Text:SetPoint("LEFT", self.ReminderBar[i].Icon, "RIGHT", s.xTextOffset, s.yTextOffset)
            self.ReminderBar[i].Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            self.ReminderBar[i].Text:SetShadowColor(0, 0, 0, 1)
            self.ReminderBar[i].Text:SetShadowOffset(0, 0)
            self.ReminderBar[i].Text:SetTextColor(1, 1, 1, 1)
            self.ReminderBar[i].TimerText = self.ReminderBar[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderBar[i].TimerText:SetPoint("RIGHT", self.ReminderBar[i], "RIGHT", s.xTimer, s.yTimer)
            self.ReminderBar[i].TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
            self.ReminderBar[i].TimerText:SetShadowColor(0, 0, 0, 1)
            self.ReminderBar[i].TimerText:SetShadowOffset(0, 0)            
            self:SetProperties(self.ReminderBar[i], info, false, s)
            return self.ReminderBar[i]
        end
    end
end

function NSI:DisplayReminder(info)
    local dur = info.dur or 8
    info.startTime = GetTime()
    info.dur = dur
    local rem = info.dur - (GetTime() - info.startTime)
    if info.spellID and rem <= (0-NSRT.ReminderSettings.Sticky) or (not info.spellID and rem <= 0) then
        return
    end
    local remString
    if rem < 3 then
        if rem < 0 then 
            remString = "" 
        else
            rem = math.floor(rem * 10 + 0.5) / 10
            remString = string.format("%.1f", rem)
        end
    else
        remString = tostring(math.ceil(rem))
    end
    local remString = (rem % 1 == 0) and string.format("%.1f", rem) or rem
    local text = info.text ~= "" and info.text or ""
    local F    
    if info.spellID then -- display icon if we have a spellID    
        if NSRT.ReminderSettings.Bars then
            F = self:CreateBar(info)
            F:SetMinMaxValues(0, info.dur)
            F:SetValue(0)
        else
            F = self:CreateIcon(info)
        end
        F.Text:SetText(text)
        F.TimerText:SetText(remString)
        F:Show()
    else
        F = self:CreateText(info)
        F.Text:SetText(text.." - ("..remString..")" or remString)
        F:Show()
    end    
    if info.glowunit then
        self:GlowFrame(info.glowunit, "p"..info.phase.."id"..info.id)  
        if info.spellID then
            local UnitIcon = self:CreateUnitFrameIcon(info) 
            if UnitIcon then UnitIcon:Show() end
        end
    end
end

function NSI:UpdateReminderDisplay(info, F, skipsound)
    local rem = info.dur - (GetTime() - info.startTime)
    local SoundTimer = info.TTSTimer or (info.spellID and NSRT.ReminderSettings.SpellTTSTimer or NSRT.ReminderSettings.TextTTSTimer)
    if rem <= SoundTimer and (not self.PlayedSound["ph"..info.phase.."id"..info.id]) and (not skipsound) then
        self:PlayReminderSound(info)
        self.PlayedSound["ph"..info.phase.."id"..info.id] = true
    end
    if info.countdown and rem <= info.countdown and (not self.StartedCountdown["ph"..info.phase.."id"..info.id]) and (not skipsound) then
        NSAPI:TTSCountdown(info.countdown)
        self.StartedCountdown["ph"..info.phase.."id"..info.id] = true
    end
    if info.spellID and rem <= (0-NSRT.ReminderSettings.Sticky) or (not info.spellID and rem <= 0) then
        F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        F:Hide()
        return
    end
    local remString
    if rem < 3 then
        if rem < 0 then 
            remString = "" 
        else
            rem = math.floor(rem * 10 + 0.5) / 10
            remString = string.format("%.1f", rem)
        end
    else
        remString = tostring(math.ceil(rem))
    end
    local text = info.text and info.text ~= "" and info.text.." - ("..remString..")" or remString
    if info.spellID and type(info.spellID) == "number" then
        if F:GetObjectType() == "StatusBar" then
            F:SetValue((GetTime()-info.startTime))
        else
            if rem <= 3 and F.TimerText then
                F.TimerText:SetTextColor(1, 0, 0, 1)
            end
        end
        if F.TimerText then F.TimerText:SetText(remString) end
    else
        F.Text:SetText(text)
    end    
end

function NSI:PlayReminderSound(info)
    local sound = info.sound and self.LSM:Fetch("sound", info.sound)
    if sound and sound ~= 1 then
        PlaySoundFile(sound, "Master")
        return      
    elseif info.TTS then
        local TTS = (type(info.TTS) == "string" and info.TTS) or (info.text and info.text ~= "" and info.text) or ""
        sound = self.LSM:Fetch("sound", TTS)
        if sound and sound ~= 1 then
            PlaySoundFile(sound, "Master")
            return
        else
            NSAPI:TTS(TTS)
        end
    end
end

function NSI:StartReminders(phase)
    self:HideAllReminders()
    self.AllGlows = {}
    self.ReminderTimer = {}
    local encID = self.EncounterID
    if not self.ProcessedReminder[encID] then return end
    if not self.ProcessedReminder[encID][phase] then return end
    for i, v in ipairs(self.ProcessedReminder[encID][phase]) do
        local time = math.max(v.time-v.dur, 0)
        self.ReminderTimer[i] = C_Timer.NewTimer(time, function()
            if self:Restricted() or NSRT.Settings["Debug"] then 
                self:DisplayReminder(v) 
            else
                self:HideAllReminders()
            end
        end)
    end
end

function NSI:HideAllReminders()
    if self.ReminderTimer then
        for i, v in ipairs(self.ReminderTimer) do
            v:Cancel()
        end
    end
    if self.AllGlows then
        for k, v in pairs(self.AllGlows) do
            self.LCG.PixelGlow_Stop(k, v)
        end
    end
    for i=1, 20 do
        if self.ReminderText then
            local F = self.ReminderText[i]
            if F then F:Hide() end
        end
        if self.ReminderIcon then
            local F = self.ReminderIcon[i]
            if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
        end
        if self.ReminderBar then            
            local F = self.ReminderBar[i]
            if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
        end
        if self.UnitIcon then
            local F = self.UnitIcon[i]
            if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
        end
    end
end

function NSI:SetReminder(name)
    if NSRT.Reminders[name] then
        self.Reminder = NSRT.Reminders[name]
        self:ProcessReminder()
    end
end

function NSI:ImportReminder(name, values)
    NSRT.Reminders[name] = values
    -- NSI:UpdateReminderList()
end

NSI.EncounterDetections = {
   [3182] = {0, 3, 3, 3, 3, 3, 3, 3}, -- starting new phase when at least 3 timers get removed which should only happen at the end of p1
}


function NSI:DetectPhaseChange(e)
    local now = GetTime()
    if NSRT.Settings["Debug"] and NSRT.Settings["DebugLogs"] and self.Phase then
        self.TimeLinesDebug = self.TimeLinesDebug or {}
        self.TimeLinesDebug.EncounterID= self.TimeLinesDebug.EncounterID or self.EncounterID
        self.TimeLinesDebug[self.Phase] = self.TimeLinesDebug[self.Phase] or {}
        self.TimeLinesDebug[self.Phase][e] = self.TimeLinesDebug[self.Phase][e] or {}
        table.insert(self.TimeLinesDebug[self.Phase][e], now)
    end
    if e == "ENCOUNTER_TIMELINE_EVENT_ADDED" and self.EncounterID == 3182 then return end -- starting new phase only on timer being removed for this boss
    local needed = self.Timelines and self.PhaseSwapTime and (now > self.PhaseSwapTime+5) and self.EncounterID and self.Phase and self.EncounterDetections[self.EncounterID] and self.EncounterDetections[self.EncounterID][self.Phase+1]
    if needed then
        table.insert(self.Timelines, now+1)
        local count = 0
        for i, v in ipairs(self.Timelines) do
            if v > now then
                count = count+1
                if count > needed then
                    self.Phase = self.Phase+1
                    self:StartReminders(self.Phase)
                    self.Timelines = {}
                    self.PhaseSwapTime = now
                    break
                end
            end           
        end
    end
end

function NSI:GlowFrame(unit, id)
    local color = {0, 1, 0, 1}
    if not unit then return end
    unit = NSAPI:GetChar(unit, true)
    local i = UnitInRaid(unit)
    if (not UnitExists(unit)) or (not i) then return end
    local F = self.RaidFrames["raid"..i]
    if not F then return end
    self.LCG.PixelGlow_Stop(F, id) -- hide any preivous glows first
    self.AllGlows[F] = id
    self.LCG.PixelGlow_Start(F, color, 10, 0.2, 10, 4, 0, 0, true, id)
end

function NSI:HideGlow(unit, id)    
    if not unit then return end
    unit = NSAPI:GetChar(unit, true)
    local i = UnitInRaid(unit)
    if (not UnitExists(unit)) or (not i) then return end
    local F = self.RaidFrames["raid"..i]
    if not F then return end
    self.AllGlows[F] = nil
    self.LCG.PixelGlow_Stop(F, id)
end

function NSI:StoreFrames(init)
    if self:Restricted() then return end
    self.RaidFrames = {}
    if init then
        local MyFrame = self.LGF.GetUnitFrame("player")
        C_Timer.After(1, function()
            NSI:StoreFrames(false)
        end)
        return
    end
    for unit in self:IterateGroupMembers() do
        local F = self.LGF.GetUnitFrame(unit)
        if F then
            self.RaidFrames[unit] = F
        end
    end
end

function NSAPI:DebugNextPhase(num)
    for i=1, num do
        NSI:EventHandler("ENCOUNTER_TIMELINE_EVENT_ADDED")
    end
end

function NSAPI:DebugReminder(EncounterID, startnow)
    if NSRT.Settings["Debug"] then
        local text = "EncounterID:"..EncounterID.."\nph:1;time:10;tag:Senfi Group1;text:Stack on {rt7};sound:Stack;countdown:3;TTS:Stack on Red;dur:8;"
        text = text.."\n".."time:15;tag:monk;TTS:true;spellid:115203;"
        text = text.."\n".."ph:1;time:25;tag:everyone;text:Lust on Reloe;glowunit:Reloe;spellid:116841;TTS:true;"
        text = text.."\n".."ph:2;time:10;tag:Reloe;text:Spread;TTS:true;dur:10;"
        text = text.."\n".."ph:2;time:15;tag:268;text:Run out if Debuff;TTS:true;dur:10"
        text = text.."\n".."ph:2;time:25;tag:tank;text:Use Ring;TTS:true;spellid:116844;dur:10;"
        if not NSI.EncounterDetections[EncounterID] then
            NSI.EncounterDetections[EncounterID] = {0, 8, 8, 8}
        end
        NSI.Reminder = text
        NSI:ProcessReminder()
        if startnow then
            NSI:EventHandler("ENCOUNTER_START", true, true, EncounterID)
            C_Timer.After(40, function()
                -- NSAPI:DebugNextPhase(10)
            end)
        end
    end
end

-- /run NSAPI:DebugReminder(3306)
-- /run NSAPI:DebugReminder(3176)
-- /run NSAPI:DebugReminder(3177)
-- /run NSAPI:DebugReminder(3179)
-- /run NSAPI:DebugReminder(3182)
-- /run NSAPI:DebugReminder(3178)
-- /run NSAPI:DebugReminder(3180)
-- /run NSAPI:DebugReminder(2900)
-- Debug has to be run before pulling. If player isn't raidlead it needs to be done after ready check.
-- /run NSAPI:DebugReminder(2900, true) to test outside of combat