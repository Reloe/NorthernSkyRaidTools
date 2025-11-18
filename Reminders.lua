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
            local phase = line:match("ph:(%d+)")
            local time = line:match("time:(%d*%.?%d+)")
            local tag = line:match("tag:([^;]+)")
            local text = line:match("text:([^;]+)")
            local TTS = line:match("TTS:([^;]+)")
            local countdown = line:match("countdown:(%d+)")
            local spellID = line:match("spellid:(%d+)")
            local dur = line:match("dur:(%d+)")
            local sound = line:match("sound:([^;]+)")
            local glowunit = line:match("glowunit:([^;]+)")
            if time and tag and (text or spellID) then
                tag = strlower(tag)
                local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
                local pos = self.spectable[specid]
                pos = (pos <= 19 and pos >= 7 and "meleedps") or (pos <= 33 and pos >= 20 and "rangeddps")
                if tag == "everyone" or 
                tag:match(strlower(UnitName("player"))) or 
                tag:match(strlower(UnitGroupRolesAssigned("player"))) or 
                tag:match(strlower(NSAPI:GetName("player", "GlobalNickNames"))) or 
                tag:match(specid) or
                tag:match(strlower(select(2, UnitClass("player")))) or
                (pos and tag:match(pos))
                then     
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
                    if not phase then phase = 1 end
                    phase = tonumber(phase)
                    if text then text = text:gsub("{rt(%d)}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%1:0|t") end                    
                    if NSRT.ReminderSettings.SpellName and spellID then -- display spellname if text is empty, also make TTS that spellname
                        if (not text) and C_Spell.GetSpellInfo(spellID) then 
                            local spellName = C_Spell.GetSpellInfo(spellID).name
                            text = spellName or ""
                            TTS = TTS and type(TTS) ~= "string" and spellName
                        end 
                    end       
                    if countdown then countdown = tonumber(countdown) end
                    self.ProcessedAssigns[phase] = self.ProcessedAssigns[phase] or {}             
                    table.insert(self.ProcessedAssigns[phase], {phase = phase, id = #self.ProcessedAssigns[phase]+1, countdown = countdown, glowunit = glowunit, sound = sound, time = tonumber(time), text = text, TTS = TTS, spellID = spellID and tonumber(spellID), dur = dur or 8})
                end
            end
        end
    end
end

function NSI:CreateText(info)
    self.AssignText = self.AssignText or {}
    for i=1, 20 do
        if self.AssignText[i] and not self.AssignText[i]:IsShown() then 
            self:SetProperties(self.AssignText[i], info)
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
            self:SetProperties(self.AssignText[i], info)
            return self.AssignText[i]
        end
    end
end

function NSI:SetProperties(F, info, skipsound)
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
        F.TimerText:SetTextColor(1, 1, 0, 1)
    elseif F.TimerText then
        F.TimerText:SetTextColor(1, 1, 1, 1)
    end
    F:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    F:SetScript("OnEvent", function(self, e, ...)
        local unit, _, spellID = ...
        if (not issecretvalue(spellID)) and spellID == info.spellID and UnitIsUnit("player", unit) and self:IsShown() then
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self:Hide()
        end
    end)
end

function NSI:CreateIcon(info)
    self.AssignIcon = self.AssignIcon or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    for i=1, 20 do
        if self.AssignIcon[i] and not self.AssignIcon[i]:IsShown() then 
            self:SetProperties(self.AssignIcon[i], info)
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
            self.AssignIcon[i].Swipe:SetHideCountdownNumbers(true)
            self.AssignIcon[i].TimerText = self.AssignIcon[i].Swipe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.AssignIcon[i].TimerText:SetPoint("CENTER", self.AssignIcon[i].Swipe, "CENTER", xTimer, yTimer)
            self.AssignIcon[i].TimerText:SetFont(Font, TimerFontSize, "OUTLINE")
            self.AssignIcon[i].TimerText:SetShadowColor(0, 0, 0, 1)
            self.AssignIcon[i].TimerText:SetShadowOffset(0, 0)
            self.AssignIcon[i].TimerText:SetDrawLayer("OVERLAY", 7)            
            self:SetProperties(self.AssignIcon[i], info)
            return self.AssignIcon[i]
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
    for i=1, 20 do
        if self.UnitIcon[i] and not self.UnitIcon[i]:IsShown() then 
            self.UnitIcon[i]:SetPoint("CENTER", F, "CENTER", xOffset, yOffset)
            self:SetProperties(self.UnitIcon[i], info, true)
            return self.UnitIcon[i] 
        end
        if not self.UnitIcon[i] then
            local xOffset, yOffset = 0, 0
            local Size = 25
            self.UnitIcon[i] = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            self.UnitIcon[i]:SetSize(Size, Size)
            self.UnitIcon[i]:SetPoint("CENTER", F, "CENTER", xOffset, yOffset)
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
            self:SetProperties(self.UnitIcon[i], info, true)
            return self.UnitIcon[i]
        end
    end
end

function NSI:CreateBar(info)
    self.AssignBar = self.AssignBar or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    for i=1, 20 do
        if self.AssignBar[i] and not self.AssignBar[i]:IsShown() then                 
            self:SetProperties(self.AssignBar[i], info)
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
            self:SetProperties(self.AssignBar[i], info)
            return self.AssignBar[i]
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
    local SoundTimer = info.spellID and NSRT.ReminderSettings.SpellTTSTimer or NSRT.ReminderSettings.TextTTSTimer
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
    if not self.ProcessedAssigns[phase] then return end
    for i, v in ipairs(self.ProcessedAssigns[phase]) do
        local time = math.max(v.time-v.dur, 0)
        self.ReminderTimer[i] = C_Timer.NewTimer(time, function()
            self:DisplayReminder(v)
        end)
    end
end

function NSI:HideAllReminders()
    if self.ReminderTimer then
        for i, v in ipairs(self.ReminderTimer) do
            v:Cancel()
        end
    end
    for k, v in pairs(self.AllGlows) do
        self.LCG.PixelGlow_Stop(k, v)
    end
    for i=1, 20 do
        if self.AssignText then
            local F = self.AssignText[i]
            if F then F:Hide() end
        end
        if self.AssignIcon then
            local F = self.AssignIcon[i]
            if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
        end
        if self.AssignBar then            
            local F = self.AssignBar[i]
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
                    self:StartReminders(self.Phase)
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
        local text = "EncounterID:"..EncounterID.."\nph:1;time:10;tag:Relowindi;text:Stack on {rt7};sound:Stack;countdown:3;TTS:Stack on Red;dur:8;"
        text = text.."\n".."time:15;tag:monk;TTS:true;spellid:115203;"
        text = text.."\n".."ph:1;time:20;tag:everyone;text:Lust on Reloe;glowunit:Reloe;spellid:116841;TTS:true;"
        text = text.."\n".."ph:2;time:12;tag:Reloe;text:Spread;TTS:true;dur:10;"
        text = text.."\n".."ph:2;time:15;tag:268;text:Run out if Debuff;TTS:true;dur:10"
        text = text.."\n".."ph:2;time:20;tag:tank;text:Use Ring;TTS:true;spellid:116844;dur:10;"
        if not NSI.EncounterDetections[EncounterID] then
            NSI.EncounterDetections[EncounterID] = {0, 8, 8}
        end
        NSI.Assigns = text
        NSI:ProcessAssigns()
        if startnow then
            NSI:EventHandler("ENCOUNTER_START", true, true, EncounterID)
            C_Timer.After(20, function()
                NSAPI:DebugNextPhase(10)
            end)
        end
    end
end

function NSAPI:DebugNextPhase(num)
    for i=1, num do
        NSI:EventHandler("ENCOUNTER_TIMELINE_EVENT_ADDED")
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