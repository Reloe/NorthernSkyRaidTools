local _, NSI = ... -- Internal namespace

NSI.EncounterOrder = {
    [3176] = 1, -- Imperator
    [3177] = 2, -- Vorasius
    [3179] = 3, -- Fallen-King
    [3178] = 4, -- Dragons
    [3180] = 5, -- Lightblinded Vanguard
    [3181] = 6, -- Crown of the Cosmos
    [3306] = 7, -- Chimaerus
    [3182] = 8, -- Belo'ren
    [3183] = 9, -- Midnight Falls
}

local symbols = {
    star = 1,
    circle = 2,
    diamond = 3,
    triangle = 4,
    moon = 5,
    square = 6,
    cross = 7,
    skull = 8,
}

function NSI:AddToReminder(info)
    self.ProcessedReminder = self.ProcessedReminder or {}
    self.ProcessedReminder[info.encID] = self.ProcessedReminder[info.encID] or {}
    info.spellID = info.spellID and tonumber(info.spellID)
    -- convert to booleans
    if info.TTS == "true" then info.TTS = true end
    if info.TTS == "false" then info.TTS = false end
    -- default to user settings if not overwritten by the reminders
    if info.TTS == nil then 
        if info.spellID then
            info.TTS = NSRT.ReminderSettings.SpellTTS
        else
            info.TTS = NSRT.ReminderSettings.TextTTS
        end
    end            
    if info.dur == nil then 
        if info.spellID then
             info.dur = NSRT.ReminderSettings.SpellDuration 
        else
            info.dur = NSRT.ReminderSettings.TextDuration 
        end
    end
    info.dur = tonumber(info.dur)
    info.time = tonumber(info.time)
    if info.dur > info.time then info.dur = info.time end -- force duration to be equal to time if an alert is set very early into the phase
    if info.countdown == nil then
        if info.spellID then
            info.countdown = NSRT.ReminderSettings.SpellCountdown
        else
            info.countdown = NSRT.ReminderSettings.TextCountdown
        end
        if info.countdown == 0 then info.countdown = false end
    end
    if info.TTSTimer == nil then
        if info.spellID then
            info.TTSTimer = NSRT.ReminderSettings.SpellTTSTimer
        else
            info.TTSTimer = NSRT.ReminderSettings.TextTTSTimer
        end
    end
    info.phase = info.phase and tonumber(info.phase)
    if not info.phase then info.phase = 1 end
    local rawtext = info.text
    if info.text then 
        info.text = info.text:gsub("{(%a+)}", function(name) -- convert {star} to {rt1}, {orange} to {rt2} etc.
            local id = symbols[name]
            if id then
                return "{rt" .. id .. "}"
            end
        end)
        info.text = info.text:gsub("{rt(%d)}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%1:0|t")  -- convert {rt1} to the actual icon for display
    end         
    if NSRT.ReminderSettings.SpellName and info.spellID then -- display spellname if text is empty, also make TTS that spellname
        local spell = C_Spell.GetSpellInfo(info.spellID) 
        if spell and not info.text then 
            info.text = spell.name or ""
            info.TTS = info.TTS and type(info.TTS) ~= "string" and spell.name
        end 
    end
    if info.TTS and info.text and type(info.TTS) == "boolean" then
        info.TTS = rawtext
    end
    if info.TTS and type(info.TTS) ~= "string" and info.spellID then -- TTS is enabled but it's still empty, which means text was empty so we should play the spellname TTS instead
        local spell = C_Spell.GetSpellInfo(info.spellID)
        info.TTS = spell and spell.name
    end
    if info.glowunit then
        local glowtable = {}
        for name in info.glowunit:gmatch("([^%s:]+)") do
            if name ~= "glowunit" then
                table.insert(glowtable, name)
            end
        end
        info.glowunit = glowtable
    end
    self.ProcessedReminder[info.encID][info.phase] = self.ProcessedReminder[info.encID][info.phase] or {}    
    table.insert(self.ProcessedReminder[info.encID][info.phase], 
    {
        notsticky = info.notsticky,
        BarOverwrite = info.BarOverwrite or info.Type == "Bar", 
        IconOverwrite = info.IconOverwrite or info.Type == "Icon", 
        TTSTimer = info.TTSTimer, 
        rawtext = info.rawtext, 
        phase = info.phase, 
        colors = info.colors,
        id = #self.ProcessedReminder[info.encID][info.phase]+1, 
        countdown = info.countdown and tonumber(info.countdown), 
        glowunit = info.glowunit, 
        sound = info.sound, 
        time = info.time, 
        text = info.text, 
        TTS = info.TTS, 
        spellID = info.spellID and tonumber(info.spellID), 
        dur = info.dur or 8,
        skipdur = info.skipdur, -- with this true there will be no cooldown edge shown for icons
    })      
end

function NSI:ProcessReminder()
    local str = ""
    self.ProcessedReminder = {}
    local remindertable = {}
    local addedreminders = {}
    local personalremindertable = {}
    local addedpersonalreminders = {}
    self.DisplayedReminder = ""
    self.DisplayedPersonalReminder = ""
    self.DisplayedExtraReminder = ""
    local pers = NSRT.ReminderSettings.ShowPersonalReminderFrame
    local shared = NSRT.ReminderSettings.ShowReminderFrame
    -- UseTimelineReminders makes it process the note but then stops the display at a later point. This allows still displaying the note.
    if (NSRT.ReminderSettings.enabled or NSRT.ReminderSettings.UseTimelineReminders) and self.Reminder then str = self.Reminder end
    if NSRT.ReminderSettings.MRTNote or NSRT.ReminderSettings.UseTimelineReminders then 
        local note = VMRT and VMRT.Note and VMRT.Note.Text1 or ""
        str = note and str ~= "" and str.."\n"..note or note or str
    end
    if NSRT.ReminderSettings.PersNote or NSRT.ReminderSettings.UseTimelineReminders then
        local note = self.PersonalReminder
        str = note and str ~= "" and str.."\n"..note or note or str
    end    
    if str ~= "" then
        local subgroup = self:GetSubGroup("player")    
        if not subgroup then subgroup = 1 end
        subgroup = "group"..subgroup
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        local pos = self.spectable[specid]
        local encID = 0
        local mynickname = strlower(NSAPI:GetName("player", "GlobalNickNames"))
        local myname = strlower(UnitName("player"))
        local myrole = strlower(UnitGroupRolesAssigned("player"))
        local myclass = strlower(select(2, UnitClass("player")))
        pos = (self.meleetable[specid] or myrole == "tank") and "melee" or "ranged"
        local extranote = ""
        if not str:match('\n$') then
            str = str..'\n'
        end
        for line in str:gmatch('([^\n]*)\n') do
            local firstline = false
            if line:find("EncounterID:") then
                encID = line:match("EncounterID:(%d+)")
                if encID then 
                    encID = tonumber(encID)
                    firstline = true
                end
            end
            local tag = line:match("tag:([^;]+)")
            local time = line:match("time:(%d*%.?%d+)")
            local text = line:match("text:([^;]+)")
            local spellID = line:match("spellid:(%d+)")   
            local phase = line:match("ph:(%d+)")
            local dur = line:match("dur:(%d+)")
            local TTS = line:match("TTS:([^;]+)")
            local countdown = line:match("countdown:(%d+)")
            local sound = line:match("sound:([^;]+)")
            local glowunit = line:match("glowunit:([^;]+)")
            local bossSpellID = line:match("bossSpell:(%d+)")
            if time and tag and (text or spellID) and encID and encID ~= 0 and not firstline then
                local displayLine = line
                phase = phase and tonumber(phase) or 1 
                local key = encID..phase..time..tag..(text or spellID)
                if (pers or shared) and (spellID or not NSRT.ReminderSettings.OnlySpellReminders) then -- only insert this if it's a spell or user wants to see text-reminders as well
                    -- display phase more readable
                    displayLine = displayLine:gsub("ph:"..phase, "P"..phase)
                    -- convert to MM:SS format
                    local timeNum = tonumber(time)
                    if timeNum then
                        local minutes = math.floor(timeNum / 60)
                        local seconds = math.floor(timeNum % 60)
                        local timeFormatted = string.format("%d:%02d", minutes, seconds)
                        displayLine = displayLine:gsub("time:"..time, timeFormatted)
                    end
                    if text then
                        displayLine = displayLine:gsub("text:"..text, text)
                    end
                    -- convert to icon
                    if spellID then
                        local iconID = C_Spell.GetSpellTexture(tonumber(spellID))
                        if iconID then
                            local iconString = "\124T"..iconID..":12:12:0:0:64:64:4:60:4:60\124t"
                            displayLine = displayLine:gsub("spellid:%d+", iconString)
                        end
                    end
                    if bossSpellID then
                        local iconID = C_Spell.GetSpellTexture(tonumber(bossSpellID))
                        if iconID then
                            local iconString = "\124T"..iconID..":12:12:0:0:64:64:4:60:4:60\124t"
                            displayLine = displayLine:gsub("bossSpell:%d+", iconString)
                        end
                    end
                    -- cleanup stuff we don't want to have displayed
                    if glowunit then
                        displayLine = displayLine:gsub("glowunit:"..glowunit, "")
                    end
                    if countdown then
                        displayLine = displayLine:gsub("countdown:"..countdown, "")
                    end
                    if TTS then
                        displayLine = displayLine:gsub("TTS:"..TTS, "")
                    end
                    if sound then
                        displayLine = displayLine:gsub("sound:"..sound, "")
                    end
                    if dur then
                        displayLine = displayLine:gsub("dur:"..dur, "")
                    end
                    -- convert names to nicknames and color code them
                    local tagNames = ""
                    for name in tag:gmatch("(%S+)") do
                        tagNames = tagNames..NSAPI:Shorten(strtrim(name), 12, false, "GlobalNickNames").." "
                    end
                    tagNames = strtrim(tagNames)
                    displayLine = displayLine:gsub("tag:([^;]+)", tagNames)
                    -- remove remaining semicolons
                    displayLine = displayLine:gsub(";", " ")
                    if shared and not addedreminders[key] then       
                        table.insert(remindertable, {str = displayLine, time = tonumber(time), phase = phase})  
                        addedreminders[key] = true  
                    end
                end
                tag = strlower(tag)
                if tag == "everyone" or 
                tag:match(myname) or 
                tag:match(mynickname) or 
                tag:match(myrole) or 
                tag:match(specid) or
                tag:match(myclass) or
                tag:match(subgroup) or 
                (pos and tag:match(pos))
                then       
                    if not addedpersonalreminders[key] then 
                        addedpersonalreminders[key] = true
                        if pers then
                            if (spellID or not NSRT.ReminderSettings.OnlySpellReminders) then -- only insert this if it's a spell or user wants to see text-reminders as well
                                table.insert(personalremindertable, {str = displayLine, time = tonumber(time), phase = phase})   
                            end
                        end
                        self:AddToReminder({text = text, phase = phase, countdown = countdown, glowunit = glowunit, sound = sound, time = time, spellID = spellID, dur = dur, TTS = TTS, encID = encID, Type = nil, notsticky = false})
                    end
                end
            else
                if (not firstline) and (not line:find("invitelist:")) then
                    if NSRT.Settings["GlobalNickNames"] then
                        local words = {}
                        for word in line:gmatch("[^%s]+") do
                            local shortened = NSAPI:Shorten(NSAPI:GetChar(word), 12, false, "GlobalNickNames")
                            table.insert(words, shortened)
                        end
                        extranote = extranote..table.concat(words, " ").."\n"
                    else
                        extranote = extranote..line.."\n"
                    end
                end
            end
        end

        if shared then
            table.sort(remindertable, function(a, b) 
                if a.phase == b.phase then
                    return a.time < b.time
                else
                    return a.phase < b.phase 
                end
            end)
            for _, data in ipairs(remindertable) do
                self.DisplayedReminder = self.DisplayedReminder..data.str.."\n"
            end
        end
        if pers then
            table.sort(personalremindertable, function(a, b) 
                if a.phase == b.phase then
                    return a.time < b.time
                else
                    return a.phase < b.phase 
                end
            end)
            for _, data in ipairs(personalremindertable) do
                self.DisplayedPersonalReminder = self.DisplayedPersonalReminder..data.str.."\n"
            end
        end
        extranote = extranote:gsub("^%s*\n+", "")
        self.DisplayedExtraReminder = extranote
    end
end

function NSI:UpdateExistingFrames() -- called when user changes settings to not require a reload
    local parent = self.ReminderText or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = NSRT.ReminderSettings.TextSettings
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
        end
    end
    self:ArrangeStates("Texts")
    self:MoveFrameSettings(self.TextMover, NSRT.ReminderSettings.TextSettings, true) 
    parent = self.ReminderIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = NSRT.ReminderSettings.IconSettings
            F:SetSize(s.Width, s.Height)
            F.Icon:SetAllPoints(F)
            F.Border:SetAllPoints(F)
            F.Text:SetPoint("LEFT", F, "RIGHT", s.xTextOffset, s.yTextOffset)
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            F.TimerText:SetPoint("CENTER", F.Swipe, "CENTER", s.xTimer, s.yTimer)
            F.TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
        end
    end
    self:ArrangeStates("Icons")
    self:MoveFrameSettings(self.IconMover, NSRT.ReminderSettings.IconSettings) 
    parent = self.UnitIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = NSRT.ReminderSettings.UnitIconSettings
            F:SetSize(s.Width, s.Height) -- not setting points in this one because this is repeated every time the frame is shown as it needs a new frame to anchor to anyway
        end
    end
    parent = self.ReminderBar or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = NSRT.ReminderSettings.BarSettings
            F:SetSize(s.Width, s.Height)
            F:SetStatusBarTexture(self.LSM:Fetch("statusbar", s.Texture))
            F:SetStatusBarColor(unpack(F.info.colors or s.colors))
            F.Icon:SetPoint("RIGHT", F, "LEFT", s.xIcon, s.yIcon)
            F.Icon:SetSize(s.Height, s.Height)
            F.Text:SetPoint("LEFT", F.Icon, "RIGHT", s.xTextOffset, s.yTextOffset)
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            F.TimerText:SetPoint("RIGHT", F, "RIGHT", s.xTimer, s.yTimer)
            F.TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
        end
    end
    self:ArrangeStates("Bars")
    self:MoveFrameSettings(self.BarMover, NSRT.ReminderSettings.BarSettings) 
end

function NSI:ArrangeStates(Type)
    local F = (Type == "Texts" and self.ReminderText) or (Type == "Icons" and self.ReminderIcon) or (Type == "Bars" and self.ReminderBar)
    if not F then return end
    local s = (Type == "Texts" and NSRT.ReminderSettings.TextSettings) or (Type == "Icons" and NSRT.ReminderSettings.IconSettings) or (Type == "Bars" and NSRT.ReminderSettings.BarSettings)
    local pos = {}
    for i=1, #F do
        if F[i] and F[i]:IsShown() then
            table.insert(pos, {Frame = F[i], id = F[i].info.id, expires = F[i].info.expires})
        end
    end
    table.sort(pos, function(a, b) 
        if a.expires == b.expires then
            return a.id < b.id
        else
            return a.expires < b.expires
        end
    end)
    for i, v in ipairs(pos) do
        local diff = Type == "Texts" and s.FontSize or s.Height
        local Spacing = s.Spacing or 0
        local yoffset = (s.GrowDirection == "Up" and (i-1) * s.Height) or (s.GrowDirection == "Down" and -(i-1) * s.Height) or 0
        local xoffset = Type == "Icons" and ((s.GrowDirection == "Right" and (i-1) * s.Width) or (s.GrowDirection == "Left" and -(i-1) * s.Width)) or 0
        v.Frame:ClearAllPoints()
        if Type == "Texts" then
            v.Frame:SetPoint("BOTTOMLEFT", "NSUIReminderTextMover", "BOTTOMLEFT", 0, 0 + yoffset)
            v.Frame:SetPoint("TOPRIGHT", "NSUIReminderTextMover", "TOPRIGHT", 0, 0 + yoffset)
        elseif Type == "Icons" then
            v.Frame:SetPoint("BOTTOMLEFT", "NSUIReminderIconMover", "BOTTOMLEFT", 0 + xoffset, 0 + yoffset)
            v.Frame:SetPoint("TOPRIGHT", "NSUIReminderIconMover", "TOPRIGHT", 0 + xoffset, 0 + yoffset)
        elseif Type == "Bars" then
            v.Frame:SetPoint("BOTTOMLEFT", "NSUIReminderBarMover", "BOTTOMLEFT", 0, 0 + yoffset)
            v.Frame:SetPoint("TOPRIGHT", "NSUIReminderBarMover", "TOPRIGHT", 0, 0 + yoffset)
        else
            print("RELOE PLS FIX (Reminder anchoring issue @ NSI:ArrangeStates)")
        end
    end
end

function NSI:SetProperties(F, info, skipsound, s)
    F:SetScript("OnUpdate", function()
        NSI:UpdateReminderDisplay(info, F, skipsound)
    end)
    F:SetScript("OnHide", function()        
        if info.glowunit then
            NSI:HideGlows(info.glowunit, "p"..info.phase.."id"..info.id)
        end
        NSI:ArrangeStates(F.Type)
    end)    
    F.info = info
    if not info.spellID then 
        F.Text:SetTextColor(unpack(info.colors or s.colors))
        return 
    end
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID    
    F.Icon:SetTexture(icon)
    if F.Swipe then 
        if info.skipdur then
            F.Swipe:SetCooldown(0, 0) 
            F.TimerText:Hide()
        else
            F.Swipe:SetCooldown(GetTime(), info.dur) 
            if NSRT.ReminderSettings.HideTimerText then 
                F.TimerText:Hide() 
            else
                F.TimerText:SetTextColor(1, 1, 0, 1)
            end
        end
    elseif F.TimerText then
        F.TimerText:SetTextColor(1, 1, 1, 1)
    end
    F:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    F:SetScript("OnEvent", function(self, e, ...)
        local unit, _, spellID = ...
        if (not issecretvalue(spellID)) and (not issecretvalue(info.spellID)) and spellID == info.spellID and UnitIsUnit("player", unit) and self:IsShown() then
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self:Hide()
        end
    end)
end

function NSI:CreateText(info)
    self.ReminderText = self.ReminderText or {}    
    local s = NSRT.ReminderSettings.TextSettings
    for i=1, #self.ReminderText+1 do
        if self.ReminderText[i] and not self.ReminderText[i]:IsShown() then 
            self:SetProperties(self.ReminderText[i], info, false, s)
            return self.ReminderText[i] 
        end
        if not self.ReminderText[i] then      
            self.ReminderText[i] = CreateFrame("Frame", 'NSUIReminderText' .. i, UIParent, "BackdropTemplate")
            local offset = s.GrowDirection == "Up" and (i-1) * s.FontSize or -(i-1) * s.FontSize
            self.ReminderText[i]:SetPoint("BOTTOMLEFT", "NSUIReminderTextMover", "BOTTOMLEFT", 0, 0 + offset)
            self.ReminderText[i]:SetPoint("TOPRIGHT", "NSUIReminderTextMover", "TOPRIGHT", 0, 0 + offset)            
            self.ReminderText[i]:SetFrameStrata("HIGH")
            self.ReminderText[i].Text = self.ReminderText[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderText[i].Text:SetPoint("LEFT", self.ReminderText[i], "LEFT", 0, 0)
            self.ReminderText[i].Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            self.ReminderText[i].Text:SetShadowColor(0, 0, 0, 1)
            self.ReminderText[i].Text:SetShadowOffset(0, 0)
            self.ReminderText[i].Text:SetTextColor(unpack(info.colors or s.colors))
            self:SetProperties(self.ReminderText[i], info, false, s)
            return self.ReminderText[i]
        end
    end
end

function NSI:CreateIcon(info)
    self.ReminderIcon = self.ReminderIcon or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    local s = NSRT.ReminderSettings.IconSettings
    for i=1, #self.ReminderIcon+1 do
        if self.ReminderIcon[i] and not self.ReminderIcon[i]:IsShown() then 
            self:SetProperties(self.ReminderIcon[i], info, false, s)
            return self.ReminderIcon[i] 
        end
        if not self.ReminderIcon[i] then
            self.ReminderIcon[i] = CreateFrame("Frame", 'NSUIReminderIcon' .. i, UIParent, "BackdropTemplate")
            local yoffset = (s.GrowDirection == "Up" and (i-1) * s.Height) or (s.GrowDirection == "Down" and -(i-1) * s.Height) or 0
            local xoffset = (s.GrowDirection == "Right" and (i-1) * s.Width) or (s.GrowDirection == "Left" and -(i-1) * s.Width) or 0
            self.ReminderIcon[i]:SetPoint("BOTTOMLEFT", "NSUIReminderIconMover", "BOTTOMLEFT", 0 + xoffset, 0 + yoffset)
            self.ReminderIcon[i]:SetPoint("TOPRIGHT", "NSUIReminderIconMover", "TOPRIGHT", 0 + xoffset, 0 + yoffset)
            self.ReminderIcon[i]:SetFrameStrata("HIGH")
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
            self.ReminderIcon[i].Swipe:SetDrawBling(false)
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



function NSI:CreateUnitFrameIcon(info, name)    
    self.UnitIcon = self.UnitIcon or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID    
    local unit = NSAPI:GetChar(name, true)
    local i = UnitInRaid(unit)
    if (not UnitExists(unit)) or (not i) then return end
    local F = self.LGF.GetUnitFrame("raid"..i)
    if not F then return end
    local s = NSRT.ReminderSettings.UnitIconSettings
    for i=1, #self.UnitIcon+1 do
        if self.UnitIcon[i] and not self.UnitIcon[i]:IsShown() then 
            self.UnitIcon[i]:ClearAllPoints()
            self.UnitIcon[i]:SetPoint(s.Position, F, s.Position, s.xOffset, s.yOffset)
            self:SetProperties(self.UnitIcon[i], info, true, s)
            return self.UnitIcon[i] 
        end
        if not self.UnitIcon[i] then            
            self.UnitIcon[i] = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            self.UnitIcon[i]:SetSize(s.Width, s.Height)
            self.UnitIcon[i]:SetPoint(s.Position, F, s.Position, s.xOffset, s.yOffset)
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
    for i=1, #self.ReminderBar+1 do
        if self.ReminderBar[i] and not self.ReminderBar[i]:IsShown() then                 
            self:SetProperties(self.ReminderBar[i], info, false, s)
            return self.ReminderBar[i] 
        end
        if not self.ReminderBar[i] then            
            self.ReminderBar[i] = CreateFrame("StatusBar", 'NSUIReminderBar' .. i, UIParent, "BackdropTemplate")
            self.ReminderBar[i]:SetBackdrop({ 
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            tileSize = 0,
            })
            self.ReminderBar[i]:SetStatusBarTexture(self.LSM:Fetch("statusbar", s.Texture))
            self.ReminderBar[i]:SetStatusBarColor(unpack(info.colors or s.colors))
            self.ReminderBar[i]:SetBackdropColor(0, 0, 0, 0.8)
            local offset = s.GrowDirection == "Up" and (i-1) * s.Height or -(i-1) * s.Height
            self.ReminderBar[i]:SetPoint("BOTTOMLEFT", "NSUIReminderBarMover", "BOTTOMLEFT", 0, 0 + offset)
            self.ReminderBar[i]:SetPoint("TOPRIGHT", "NSUIReminderBarMover", "TOPRIGHT", 0, 0 + offset)            
            self.ReminderBar[i]:SetFrameStrata("HIGH")
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
    local now = GetTime()
    local dur = info.dur or 8
    info.startTime = now
    info.dur = dur
    info.expires = now + dur
    local rem = info.dur - (now - info.startTime)
    if info.spellID and rem <= (0-NSRT.ReminderSettings.Sticky) or ((info.notsticky or not info.spellID) and rem <= 0) then
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
        if (NSRT.ReminderSettings.Bars or info.BarOverwrite) and not info.IconOverwrite then
            F = self:CreateBar(info)
            F:SetMinMaxValues(0, info.dur)
            F:SetValue(0)
            F:Show()
            self:ArrangeStates("Bars")
            F.Type = "Bars"
        else
            F = self:CreateIcon(info)
            F:Show()
            self:ArrangeStates("Icons")
            F.Type = "Icons"
        end
        F.Text:SetText(text)
        F.TimerText:SetText(remString)
    else
        F = self:CreateText(info)
        F.Type = "Texts"
        F.Text:SetText(text.." - ("..remString..")" or remString)
        F:Show()
        self:ArrangeStates("Texts")
    end    
    if info.glowunit then
        for i, name in ipairs(info.glowunit) do
            self:GlowFrame(name, "p"..info.phase.."id"..info.id)
            if info.spellID then
                local UnitIcon = self:CreateUnitFrameIcon(info, name) 
                if UnitIcon then UnitIcon:Show() end
            end
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
    if info.spellID and rem <= (0-NSRT.ReminderSettings.Sticky) or ((info.notsticky or not info.spellID) and rem <= 0) then
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
    local text = (info.skiptime and info.text) or (info.text and info.text ~= "" and info.text.." - ("..remString..")") or remString
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

function NSI:PlayReminderSound(info, default)
    if info.TTS and issecretvalue(info.TTS) then NSAPI:TTS(info.TTS) return end
    if default then -- so I can use this function outside of reminders basically
        info = {sound = default, TTS = default, rawtext = default}
    end
    local sound = info.sound and self.LSM:Fetch("sound", info.sound)
    if sound and sound ~= 1 then
        PlaySoundFile(sound, "Master")
        return      
    elseif info.TTS then
        local TTS = (type(info.TTS) == "string" and info.TTS) or (info.rawtext and info.rawtext ~= "" and info.rawtext) or ""
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
    if NSRT.ReminderSettings.UseTimelineReminders then return end
    self:HideAllReminders()
    self.AllGlows = {}
    self.ReminderTimer = {}    
    if not self.EncounterID then return end
    if not self.ProcessedReminder[self.EncounterID] then return end
    if not self.ProcessedReminder[self.EncounterID][phase] then return end
    for i, v in ipairs(self.ProcessedReminder[self.EncounterID][phase]) do
        local time = math.max(v.time-v.dur, 0)
        self.ReminderTimer[i] = C_Timer.NewTimer(time, function()
            if self:Restricted() or self.TestingReminder or NSRT.Settings["Debug"] then 
                self:DisplayReminder(v) 
            else
                self:HideAllReminders()
            end
        end)
    end
end

function NSI:HideAllReminders()
    self.PlayedSound = {}
    self.StartedCountdown = {}
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
    local parent = self.ReminderText or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:Hide() end
    end
    parent = self.ReminderIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
    end
    parent = self.ReminderBar or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
    end
    parent = self.UnitIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
    end
end

function NSI:GetAllReminderNames(personal)
    local list = {}
    local tocheck = personal and NSRT.PersonalReminders or NSRT.Reminders
    for k, v in pairs(tocheck) do
        local encID = v:match("EncounterID:(%d+)")
        if encID then
            local order = self.EncounterOrder[tonumber(encID)] or 1000
            table.insert(list, {name = k, order = order})
        end
    end
    table.sort(list, function(a, b) 
        if a.order == b.order then
            return a.name < b.name
        else
            return a.order < b.order 
        end
    end)
    return list
end

function NSI:SetReminder(name, personal)
    if personal then
        if name and NSRT.PersonalReminders[name] then
            self.PersonalReminder = NSRT.PersonalReminders[name]
            NSRT.ActivePersonalReminder = name
            self:ProcessReminder()
            self:UpdateReminderFrame(false, true)
        else
            self.PersonalReminder = ""
            NSRT.ActivePersonalReminder = nil
            self:ProcessReminder()
            self:UpdateReminderFrame(false, true)
        end
    elseif name and NSRT.Reminders[name] then
        self.Reminder = NSRT.Reminders[name]
        NSRT.ActiveReminder = name
        self:ProcessReminder()
        self:UpdateReminderFrame(false, true)
    else
        self.Reminder = ""
        NSRT.ActiveReminder = nil
        self:ProcessReminder()
        self:UpdateReminderFrame(false, true)
    end
    self:FireCallback("NSRT_REMINDER_CHANGED", self.Reminder, self.PersonalReminder)
end

function NSI:RemoveReminder(name, personal)
    if personal then
        if name and NSRT.PersonalReminders[name] then
            NSRT.PersonalReminders[name] = nil
            if NSRT.ActivePersonalReminder == name then
                self:SetReminder(nil, true)
            end
        end
    elseif name and NSRT.Reminders[name] then
        NSRT.Reminders[name] = nil
        NSRT.InviteList[name] = nil
        if NSRT.ActiveReminder == name then
            self:SetReminder(nil, false)
        end
    end
end

function NSI:ImportFullReminderString(str, personal, IsUpdate)
    local name = ""
    local values = ""
    if not str:match('\n$') then
        str = str..'\n'
    end
    for line in str:gmatch('([^\n]*)\n') do
        if line:find("EncounterID:") and line:find("Name:") then
            if values ~= "" then -- meaning we reached a new boss line as the previous one has values already
                self:ImportReminder(name, values, false, personal, IsUpdate)
                values = ""
            end
            name = line:match("Name:([^;]+)")
            values = line.."\n"
        elseif name ~= "" then
            values = values..line.."\n"
        end
    end
    if values ~= "" and name ~= "" then -- importing the last boss
        self:ImportReminder(name, values, false, personal, IsUpdate)
    end
end

function NSI:ImportReminder(name, values, activate, personal, IsUpdate)
    if not name then name = "Default Reminder" end
    local diff = values:match("Difficulty:([^;]+)")
    local newname = diff and name.." - "..diff or name
    if personal then
        if NSRT.PersonalReminders[newname] and not IsUpdate then -- if name already exists we add a 2 at the end and also update the string to reflect the new name.
            values = values:gsub("Name:[^\n]*", "Name:"..name.." 2")
            self:ImportReminder(name.." 2", values, activate, personal, IsUpdate)
            return
        end
        NSRT.PersonalReminders[newname] = values
        if activate then
            self:SetReminder(newname, true)
        end
        return
    end
    if NSRT.Reminders[newname] and not IsUpdate then -- if name already exists we add a 2 at the end and also update the string to reflect the new name.
        values = values:gsub("Name:[^\n]*", "Name:"..name.." 2")
        self:ImportReminder(name.." 2", values, activate, personal, IsUpdate)
        return
    end
    NSRT.Reminders[newname] = values
    NSRT.InviteList[newname] = self:InviteListFromReminder(values)
    if activate then
        self:SetReminder(newname)
    end
end

function NSI:InviteListFromReminder(str)
    local list = {}
    local found = false
    for line in str:gmatch('[^\r\n]+') do
        if line:find("invitelist:") then    
            found = true    
            for name in line:gmatch("([^%s,;:]+)") do
                if name ~= "invitelist" then
                    table.insert(list, name)
                end
            end
        end
    end
    return found and list or false
end

function NSI:GlowFrame(unit, id)
    local color = {0, 1, 0, 1}
    if not unit then return end
    unit = NSAPI:GetChar(unit, true)
    local i = UnitInRaid(unit)
    if (not UnitExists(unit)) or (not i) then return end
    id = unit..id
    local F = self.LGF.GetUnitFrame(unit)
    if not F then return end
    self.LCG.PixelGlow_Stop(F, id) -- hide any preivous glows first
    self.AllGlows[F] = id
    local s = NSRT.ReminderSettings.GlowSettings
    self.LCG.PixelGlow_Start(F, s.colors, s.Lines, s.Frequency, s.Length, s.Thickness, s.xOffset, s.yOffset, true, id)
end

function NSI:HideGlows(units, id)    
    if not units then return end
    for i, unit in ipairs(units) do
        unit = NSAPI:GetChar(unit, true)
        local i = UnitInRaid(unit)
        if (not UnitExists(unit)) or (not i) then return end
        local newid = unit..id
        local F = self.LGF.GetUnitFrame(unit)
        if not F then return end
        self.AllGlows[F] = nil
        self.LCG.PixelGlow_Stop(F, newid) 
    end
end

function NSI:CreateMoveFrames(Show)
    if not self.IconMover then
        self.IconMover = CreateFrame("Frame", 'NSUIReminderIconMover', UIParent, "BackdropTemplate")
        self:MoveFrameInit(self.IconMover, "IconSettings")
        self:MoveFrameSettings(self.IconMover, NSRT.ReminderSettings.IconSettings)
    else
        self:MoveFrameSettings(self.IconMover, NSRT.ReminderSettings.IconSettings)
    end
    if not self.BarMover then
        self.BarMover = CreateFrame("Frame", 'NSUIReminderBarMover', UIParent, "BackdropTemplate")
        self:MoveFrameInit(self.BarMover, "BarSettings")
        self:MoveFrameSettings(self.BarMover, NSRT.ReminderSettings.BarSettings)
    else
        self:MoveFrameSettings(self.BarMover, NSRT.ReminderSettings.BarSettings)
    end
     if not self.TextMover then
        self.TextMover = CreateFrame("Frame", 'NSUIReminderTextMover', UIParent, "BackdropTemplate")
        self.TextMover.Text = self.TextMover:CreateFontString('TextMoverText', "OVERLAY", "GameFontNormal")
        self.TextMover.Text:SetPoint("LEFT", self.TextMover, "LEFT", 0, 0)
        self.TextMover.Text:SetTextColor(1, 1, 1, 0)
        self:MoveFrameInit(self.TextMover, "TextSettings", true)   
        self:MoveFrameSettings(self.TextMover, NSRT.ReminderSettings.TextSettings, true)   
    else
        local s = NSRT.ReminderSettings.TextSettings 
        self.TextMover.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")      
        self:MoveFrameSettings(self.TextMover, s, true)
    end
    if not self.ReminderFrameMover then
        self.ReminderFrameMover = CreateFrame("Frame", 'NSUIReminderFrameMover', UIParent, "BackdropTemplate")
        self:MoveFrameInit(self.ReminderFrameMover, "ReminderFrame", false, NSRT.ReminderSettings.ReminderFrame.BGcolor)
        self:MoveFrameSettings(self.ReminderFrameMover, NSRT.ReminderSettings.ReminderFrame)
        if NSRT.ReminderSettings.ShowReminderFrame and NSRT.ReminderSettings.ReminderFrameMoveable then
            self:UpdateReminderFrame()
            self:ToggleMoveFrames(self.ReminderFrameMover, true)
            self.ReminderFrameMover.Resizer:Show()
            self.ReminderFrameMover:SetResizable(true)
            self.ReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
        end
    else
        self:MoveFrameSettings(self.ReminderFrameMover, NSRT.ReminderSettings.ReminderFrame)
    end  
    if not self.PersonalReminderFrameMover then
        self.PersonalReminderFrameMover = CreateFrame("Frame", 'NSUIPersonalReminderFrameMover', UIParent, "BackdropTemplate")
        self:MoveFrameInit(self.PersonalReminderFrameMover, "PersonalReminderFrame", false, NSRT.ReminderSettings.PersonalReminderFrame.BGcolor)
        self:MoveFrameSettings(self.PersonalReminderFrameMover, NSRT.ReminderSettings.PersonalReminderFrame)
        if NSRT.ReminderSettings.ShowPersonalReminderFrame and NSRT.ReminderSettings.PersonalReminderFrameMoveable then
            self:UpdateReminderFrame(true)
            self:ToggleMoveFrames(self.PersonalReminderFrameMover, true)
            self.PersonalReminderFrameMover.Resizer:Show()
            self.PersonalReminderFrameMover:SetResizable(true)
            self.PersonalReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
        end
    else
        self:MoveFrameSettings(self.PersonalReminderFrameMover, NSRT.ReminderSettings.PersonalReminderFrame)
    end
    if not self.ExtraReminderFrameMover then
        self.ExtraReminderFrameMover = CreateFrame("Frame", 'NSUIExtraReminderFrameMover', UIParent, "BackdropTemplate")
        self:MoveFrameInit(self.ExtraReminderFrameMover, "ExtraReminderFrame", false, NSRT.ReminderSettings.ExtraReminderFrame.BGcolor)
        self:MoveFrameSettings(self.ExtraReminderFrameMover, NSRT.ReminderSettings.ExtraReminderFrame)
        if NSRT.ReminderSettings.ShowExtraReminderFrame and NSRT.ReminderSettings.ExtraReminderFrameMoveable then
            self:UpdateReminderFrame(false, false, true)
            self:ToggleMoveFrames(self.ExtraReminderFrameMover, true)
            self.ExtraReminderFrameMover.Resizer:Show()
            self.ExtraReminderFrameMover:SetResizable(true)
            self.ExtraReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
        end
    else
        self:MoveFrameSettings(self.ExtraReminderFrameMover, NSRT.ReminderSettings.ExtraReminderFrame)
    end

    self.IconMover:Show()
    self.BarMover:Show()
    self.TextMover:Show()
    self.ReminderFrameMover:Show()
    self.PersonalReminderFrameMover:Show()
end        



function NSI:MoveFrameSettings(F, s, text)    
    if text then        
        F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
        F.Text:SetText("Personals - (10)")
        s.Width, s.Height = F.Text:GetStringWidth(), F.Text:GetStringHeight()   
    end
    F:SetSize(s.Width, s.Height)
    F:ClearAllPoints()
    F:SetPoint(s.Anchor, UIParent, s.relativeTo, s.xOffset, s.yOffset)
end

function NSI:MoveFrameInit(F, s, text, ReminderColor)
    if F then             
        F.Border = CreateFrame("Frame", nil, F, "BackdropTemplate") 
        local x = s == "BarSettings" and -6-NSRT.ReminderSettings[s].Height or -6 -- extra offset for bars to account for the icon
        F.Border:SetPoint("TOPLEFT", F, "TOPLEFT", x, 6)
        F.Border:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", 6, -6)
        F.Border:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                tileSize = 0,
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
        if ReminderColor then F.Border:SetBackdropBorderColor(1, 1, 1, 0) else F.Border:SetBackdropBorderColor(1, 1, 1, 1) end
        if ReminderColor then F.Border:SetBackdropColor(unpack(ReminderColor)) else F.Border:SetBackdropColor(0, 0, 0, 0) end
        F.Border:Hide()
        F:SetFrameStrata(ReminderColor and "BACKGROUND" or "DIALOG")
        F.Border:SetFrameStrata(ReminderColor and "BACKGROUND" or "DIALOG")
        F:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        F:SetScript("OnDragStop", function(Frame)
            Frame:StopMovingOrSizing()       
            local Anchor, _, relativeTo, xOffset, yOffset = Frame:GetPoint()
            xOffset = Round(xOffset)
            yOffset = Round(yOffset)
            NSRT.ReminderSettings[s].xOffset = xOffset     
            NSRT.ReminderSettings[s].yOffset = yOffset  
            NSRT.ReminderSettings[s].Anchor = Anchor    
            NSRT.ReminderSettings[s].relativeTo = relativeTo    
            self:UpdateExistingFrames() 
        end)
    end
end

function NSI:ToggleMoveFrames(F, Unlock)
    if Unlock then
        F:SetMovable(true)
        F:EnableMouse(true)
        F:RegisterForDrag("LeftButton")
        F:SetClampedToScreen(true)
        F.Border:Show()
    else
        F.Border:Hide()
        F:SetMovable(false)
        F:EnableMouse(false)
    end    
end

function NSAPI:DebugNextPhase(num)
    for i=1, num do
        NSI:EventHandler("ENCOUNTER_TIMELINE_EVENT_ADDED")
    end
end

function NSAPI:DebugEncounter(EncounterID)
    if NSRT.Settings["Debug"] then
        NSI.ProcessedReminder = nil
        NSI:EventHandler("ENCOUNTER_START", true, true, EncounterID)
    end
end

function NSI:CreateDefaultAlert(text, Type, spellID, dur, phase, encID)
    local id = self.DefaultAlertID
    self.DefaultAlertID = self.DefaultAlertID + 1
    local info = 
    {
        dur = dur,
        spellID = spellID,
        encID = encID,
        TTSTimer = 60, -- tts on show
        text = text, 
        TTS = text, 
        notsticky = true, 
        phase = phase or self.Phase,
        id = id,
        startTime = GetTime(),
    }
    if Type == "Bar" then info.BarOverwrite = true
    elseif Type == "Icon" then info.IconOverwrite = true
    end
    return info
end

function NSI:UpdateReminderFrame(personal, all, extra)    
    if personal or all then
        self:MoveFrameSettings(self.PersonalReminderFrameMover, NSRT.ReminderSettings.PersonalReminderFrame)
    end
    if all or ((not personal) and not extra) then
        self:MoveFrameSettings(self.ReminderFrameMover, NSRT.ReminderSettings.ReminderFrame) 
    end
    if all or extra then
        self:MoveFrameSettings(self.ExtraReminderFrameMover, NSRT.ReminderSettings.ExtraReminderFrame) 
    end

    if (personal or all) and not self.PersonalReminderFrame then
        self.PersonalReminderFrame = CreateFrame("Frame", 'NSUIPersonalReminderFrame', self.PersonalReminderFrameMover, "BackdropTemplate")    
        self.PersonalReminderFrame:SetClipsChildren(true)         
        self.PersonalReminderFrame:SetFrameStrata("MEDIUM")
        self.PersonalReminderFrame.Text = self.PersonalReminderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.PersonalReminderFrame.Text:SetPoint("TOPLEFT", self.PersonalReminderFrame, "TOPLEFT", 0, 0)       
        self.PersonalReminderFrame.Text:SetTextColor(1, 1, 1, 1)        
        self.PersonalReminderFrame.Text:SetJustifyH("LEFT")  
        self.PersonalReminderFrame.Text:SetJustifyV("TOP")
        self.PersonalReminderFrame.Text:SetWordWrap(true)
        self.PersonalReminderFrame.Text:SetNonSpaceWrap(true)
        self.PersonalReminderFrame.Text:SetDrawLayer("OVERLAY", 7)

        self.PersonalReminderFrameMover.Resizer = CreateFrame("Button", nil, self.PersonalReminderFrameMover)
        self.PersonalReminderFrameMover.Resizer:SetSize(20, 20)
        self.PersonalReminderFrameMover.Resizer:SetPoint("BOTTOMRIGHT", self.PersonalReminderFrameMover, "BOTTOMRIGHT", -2, 2)            
        self.PersonalReminderFrameMover.Resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        self.PersonalReminderFrameMover.Resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        self.PersonalReminderFrameMover.Resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        self.PersonalReminderFrameMover.Resizer:EnableMouse(true)
        self.PersonalReminderFrameMover.Resizer:RegisterForDrag("LeftButton")
        self.PersonalReminderFrameMover.Resizer:SetScript("OnMouseDown", function()
            self.PersonalReminderFrameMover:StartSizing("BOTTOMRIGHT")
        end)
        self.PersonalReminderFrameMover.Resizer:SetScript("OnMouseUp", function()            
            self.PersonalReminderFrameMover:StopMovingOrSizing()
            NSRT.ReminderSettings.PersonalReminderFrame.Width = self.PersonalReminderFrameMover:GetWidth()
            NSRT.ReminderSettings.PersonalReminderFrame.Height = self.PersonalReminderFrameMover:GetHeight()
        end)
        if not NSRT.ReminderSettings.PersonalReminderFrameMoveable then
            self.PersonalReminderFrameMover.Resizer:Hide()
        end
    end
    if (all or ((not personal) and not extra)) and (not self.ReminderFrame) then
        self.ReminderFrame = CreateFrame("Frame", 'NSUIReminderFrame', self.ReminderFrameMover, "BackdropTemplate")    
        self.ReminderFrame:SetClipsChildren(true)       
        self.ReminderFrame:SetFrameStrata("MEDIUM")  
        self.ReminderFrame.Text = self.ReminderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.ReminderFrame.Text:SetPoint("TOPLEFT", self.ReminderFrame, "TOPLEFT", 0, 0)       
        self.ReminderFrame.Text:SetTextColor(1, 1, 1, 1)        
        self.ReminderFrame.Text:SetJustifyH("LEFT")  
        self.ReminderFrame.Text:SetJustifyV("TOP")
        self.ReminderFrame.Text:SetWordWrap(true)
        self.ReminderFrame.Text:SetNonSpaceWrap(true)
        self.ReminderFrame.Text:SetDrawLayer("OVERLAY", 7)

        self.ReminderFrameMover.Resizer = CreateFrame("Button", nil, self.ReminderFrameMover)
        self.ReminderFrameMover.Resizer:SetSize(20, 20)
        self.ReminderFrameMover.Resizer:SetPoint("BOTTOMRIGHT", self.ReminderFrameMover, "BOTTOMRIGHT", -2, 2)            
        self.ReminderFrameMover.Resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        self.ReminderFrameMover.Resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        self.ReminderFrameMover.Resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        self.ReminderFrameMover.Resizer:EnableMouse(true)
        self.ReminderFrameMover.Resizer:RegisterForDrag("LeftButton")
        self.ReminderFrameMover.Resizer:SetScript("OnMouseDown", function()
            self.ReminderFrameMover:StartSizing("BOTTOMRIGHT")
        end)
        self.ReminderFrameMover.Resizer:SetScript("OnMouseUp", function()
            self.ReminderFrameMover:StopMovingOrSizing()
            NSRT.ReminderSettings.ReminderFrame.Width = self.ReminderFrameMover:GetWidth()
            NSRT.ReminderSettings.ReminderFrame.Height = self.ReminderFrameMover:GetHeight()
        end)
        if not NSRT.ReminderSettings.ReminderFrameMoveable then
            self.ReminderFrameMover.Resizer:Hide()
        end
    end
    if (extra or all) and (not self.ExtraReminderFrame) then
        self.ExtraReminderFrame = CreateFrame("Frame", 'NSUIExtraReminderFrame', self.ExtraReminderFrameMover, "BackdropTemplate")    
        self.ExtraReminderFrame:SetClipsChildren(true)         
        self.ExtraReminderFrame:SetFrameStrata("MEDIUM")
        self.ExtraReminderFrame.Text = self.ExtraReminderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.ExtraReminderFrame.Text:SetPoint("TOPLEFT", self.ExtraReminderFrame, "TOPLEFT", 0, 0)       
        self.ExtraReminderFrame.Text:SetTextColor(1, 1, 1, 1)        
        self.ExtraReminderFrame.Text:SetJustifyH("LEFT")  
        self.ExtraReminderFrame.Text:SetJustifyV("TOP")
        self.ExtraReminderFrame.Text:SetWordWrap(true)
        self.ExtraReminderFrame.Text:SetNonSpaceWrap(true)
        self.ExtraReminderFrame.Text:SetDrawLayer("OVERLAY", 7)

        self.ExtraReminderFrameMover.Resizer = CreateFrame("Button", nil, self.ExtraReminderFrameMover)
        self.ExtraReminderFrameMover.Resizer:SetSize(20, 20)
        self.ExtraReminderFrameMover.Resizer:SetPoint("BOTTOMRIGHT", self.ExtraReminderFrameMover, "BOTTOMRIGHT", -2, 2)            
        self.ExtraReminderFrameMover.Resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        self.ExtraReminderFrameMover.Resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        self.ExtraReminderFrameMover.Resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        self.ExtraReminderFrameMover.Resizer:EnableMouse(true)
        self.ExtraReminderFrameMover.Resizer:RegisterForDrag("LeftButton")
        self.ExtraReminderFrameMover.Resizer:SetScript("OnMouseDown", function()
            self.ExtraReminderFrameMover:StartSizing("BOTTOMRIGHT")
        end)
        self.ExtraReminderFrameMover.Resizer:SetScript("OnMouseUp", function()            
            self.ExtraReminderFrameMover:StopMovingOrSizing()
            NSRT.ReminderSettings.ExtraReminderFrame.Width = self.ExtraReminderFrameMover:GetWidth()
            NSRT.ReminderSettings.ExtraReminderFrame.Height = self.ExtraReminderFrameMover:GetHeight()
        end)
        if not NSRT.ReminderSettings.ExtraReminderFrameMoveable then
            self.ExtraReminderFrameMover.Resizer:Hide()
        end
    end
    if personal or all then 
        self.PersonalReminderFrame:SetAllPoints(self.PersonalReminderFrameMover)
        self.PersonalReminderFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.ReminderSettings.PersonalReminderFrame.Font), NSRT.ReminderSettings.PersonalReminderFrame.FontSize, "OUTLINE")   
        self.PersonalReminderFrame.Text:SetText(self.DisplayedPersonalReminder)
        self.PersonalReminderFrameMover.Border:SetBackdropColor(unpack(NSRT.ReminderSettings.PersonalReminderFrame.BGcolor))
        if NSRT.ReminderSettings.ShowPersonalReminderFrame then       
            self.PersonalReminderFrame:Show()
        elseif self.PersonalReminderFrame then
            self.PersonalReminderFrame:Hide()
        end
    end  
    if all or ((not personal) and not extra) then    
        self.ReminderFrame:SetAllPoints(self.ReminderFrameMover)
        self.ReminderFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.ReminderSettings.ReminderFrame.Font), NSRT.ReminderSettings.ReminderFrame.FontSize, "OUTLINE")   
        self.ReminderFrame.Text:SetText(self.DisplayedReminder)
        self.ReminderFrameMover.Border:SetBackdropColor(unpack(NSRT.ReminderSettings.ReminderFrame.BGcolor))
        if NSRT.ReminderSettings.ShowReminderFrame then  
            self.ReminderFrame:Show()
        elseif self.ReminderFrame then
            self.ReminderFrame:Hide()
        end
    end
    if all or extra then
        self.ExtraReminderFrame:SetAllPoints(self.ExtraReminderFrameMover)
        self.ExtraReminderFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.ReminderSettings.ExtraReminderFrame.Font), NSRT.ReminderSettings.ExtraReminderFrame.FontSize, "OUTLINE")   
        self.ExtraReminderFrame.Text:SetText(self.DisplayedExtraReminder)
        if NSRT.ReminderSettings.ShowExtraReminderFrame then  
            self.ExtraReminderFrame:Show()
        elseif self.ExtraReminderFrame then
            self.ExtraReminderFrame:Hide()
        end
    end
end

function NSAPI:GetReminderString()
    return NSI.PersonalReminder, NSI.Reminder
end