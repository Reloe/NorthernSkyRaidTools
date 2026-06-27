local _, NSI = ... -- Internal namespace

-- Function from WeakAuras, thanks rivers
function NSI:IterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
    local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
    return function()
        local ret
        if i == 0 and unit == 'party' then
            ret = 'player'
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end
        i = i + (reversed and -1 or 1)
        return ret
    end
end

function NSI:IsMidnightS2()
    local build = select(4, GetBuildInfo())
    return build >= 120100
end

function NSI:Restricted()
    return C_Secrets.ShouldAurasBeSecret()
end

function NSI:SortTable(t, reversed)
    table.sort(t,
        function(a, b)
            if a.prio == b.prio then -- sort by GUID if same spec
                return (reversed and b.GUID > a.GUID) or a.GUID < b.GUID
            else
                return (reversed and a.prio > b.prio) or a.prio < b.prio
            end
    end) -- a < b low first, a > b high first
    return t
end

function NSAPI:Shorten(unit, num, specicon, AddonName, combined, roleicon) -- Returns color coded Name/Nickname
    if issecretvalue(unit) or not unit then return unit, "", "" end
    local name = UnitName(unit)
    if issecretvalue(name) then return unit, "", "" end
    local classFile = select(2, UnitClass(unit))
    if specicon then
        local specid = 0
        if unit then specid = NSI:GetSpecs(unit) or 0 end
        local icon = select(4, GetSpecializationInfoByID(specid))
        if icon then
            specicon = "\124T"..icon..":12:12:0:0:64:64:4:60:4:60\124t"
        elseif not roleicon then -- if we didn't get the specid can at least try to return the role icon unless that one was specifically requested as well
            specicon = UnitGroupRolesAssigned(unit)
            if specicon ~= "NONE" then
                specicon = CreateAtlasMarkup(GetIconForRole(specicon), 0, 0)
            else
                specicon = ""
            end
        else
            specicon = ""
        end
    else
        specicon = ""
    end
    if roleicon then
        roleicon = UnitGroupRolesAssigned(unit)
        if roleicon ~= "NONE" then
            roleicon = CreateAtlasMarkup(GetIconForRole(roleicon), 0, 0)
        else
            roleicon = ""
        end
    else
        roleicon = ""
    end
    if classFile then -- basically "if unit found"
        local color = classFile == "PRIEST" and CreateColor(200/255, 200/255, 200/255) or GetClassColorObj(classFile)
        local newname = num and NSI:Utf8Sub(NSAPI:GetName(name, AddonName), 1, num) or NSAPI:GetName(name, AddonName) -- shorten name before wrapping in color
        if color then -- should always be true anyway?
            return combined and specicon..roleicon..color:WrapTextInColorCode(newname) or color:WrapTextInColorCode(newname), combined and "" or specicon, combined and "" or roleicon
        else
            return combined and specicon..roleicon..newname or newname, combined and "" or specicon, combined and "" or roleicon
        end
    else
        return unit, "", "" -- return input if nothing was found
    end
end

function NSI:GetSpecs(unit)
    if unit then
        local G = UnitGUID(unit)
        if issecretvalue(G) then return false end
        return self.specs[G] or false -- return false if no information available for that unit so it goes to the next fallback
    else
        return self.specs -- if no unit is given then entire table is requested
    end
end

-- Registers or unregisters the LibSpecialization group callback depending on
-- whether the player is currently in a raid. Called on login and GROUP_ROSTER_UPDATE.
function NSI:UpdateLibSpecRegistration()
    self.LS = self.LS or LibStub("LibSpecialization", true)
    if not self.LS then return end
    if not self._libSpecRegistered then
        self._libSpecRegistered = true
        local _, myrealm = UnitFullName("player")
        self.LS.RegisterGroup(self, function(specId, role, position, playerName)
            self.specs = self.specs or {}
            local name, realm = strsplit("-", playerName)
            if (not realm) or (realm == "") then realm = myrealm end
            local u
            for unit in self:IterateGroupMembers() do
                local uname, urealm = UnitFullName(unit)
                if not urealm then urealm = myrealm end
                if uname and uname == name and urealm and urealm == realm then
                    u = unit
                    break
                end
            end
            if u then
                local G = UnitGUID(u) or ""
                self.specs[G] = specId
                NSAPI.specs = self.specs
            end
        end)
    end
end

function NSI:GetNote() -- simply for note comparison now
    if not C_AddOns.IsAddOnLoaded("MRT") then
        return "empty"
    end
    if not VMRT.Note.Text1 then
        return "empty"
    end
    return _G.VMRT.Note.Text1 or ""
end

function NSI:DifficultyCheck(diffs) -- check if current difficulty is a Normal/Heroic/Mythic raid and also allow checking if we are currently in an encounter
    local diff = select(3, GetInstanceInfo()) or 0
    if diff == 233 then diff = 16 end -- Just treat Flex myth as normal myth
    return (tContains(diffs, diff) and diff) or (NSRT.Settings.Debug and 16)
end

function NSI:GetHash(text)
    local counter = 1
    local len = string.len(text)
    for i = 1, len, 3 do
        counter = math.fmod(counter*8161, 4294967279) +  -- 2^32 - 17: Prime!
                (string.byte(text,i)*16776193) +
                ((string.byte(text,i+1) or (len-i+256))*8372226) +
                ((string.byte(text,i+2) or (len-i+256))*3932164)
    end
    return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

-- keeping these two in global as I might want to use them elsewhere still
function NSAPI:TTSCountdown(num)
    for i= num, 1, -1 do
        if i == num then
            NSAPI:TTS(i)
        else
            C_Timer.After(num-i, function() NSAPI:TTS(i) end)
        end
    end
end

local path = "Interface\\AddOns\\NorthernSkyRaidTools\\Media\\Sounds\\"
local function GetTTSSoundFile(sound)
    if not NSI.LSM or not sound then return end

    sound = strtrim(tostring(sound))
    local soundPath = NSI.LSM:Fetch("sound", sound, true)
    if soundPath then return soundPath end

    if not NSI.LSMSoundCache and NSI.CacheSounds then
        NSI:CacheSounds()
    end

    local numeric = tonumber(sound)
    local function GetCachedKey()
        local key = NSI.LSMSoundCache and (NSI.LSMSoundCache[sound] or NSI.LSMSoundCache[strlower(sound)])
        if not key and numeric then
            key = NSI.LSMSoundCache and NSI.LSMSoundCache[tostring(numeric)]
        end
        return key
    end

    local lsmKey = GetCachedKey()
    if not lsmKey and NSI.CacheSounds then
        NSI:CacheSounds()
        lsmKey = GetCachedKey()
    end
    return lsmKey and NSI.LSM:Fetch("sound", lsmKey, true)
end

function NSAPI:TTS(sound, voice) -- NSAPI:TTS("Bait Frontal")
    if NSRT.Settings["TTS"] then
        local secret = issecretvalue(sound)
        local forceTTS = NSRT.ReminderSettings and NSRT.ReminderSettings.TTSOverSoundfile
        local soundFile = (not forceTTS and not secret) and (GetTTSSoundFile(sound) or path..sound..".ogg")
        local handle = soundFile and select(2, PlaySoundFile(soundFile, "Master"))
        if handle then
            return
        else
            sound = tostring(sound)
            local num = voice or NSRT.Settings["TTSVoice"]
            local voices = C_VoiceChat.GetTtsVoices()
            local validVoice = false
            if voices then
                for i, v in ipairs(voices) do
                    if v.voiceID == num then
                        validVoice = true
                        break
                    end
                end
            end
            if not validVoice then num = 0 end
            C_VoiceChat.SpeakText(
                num,
                sound,
                C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0,
                NSRT.Settings.TTSVolume,
                NSRT.Settings.TTSOverlap
            )
        end
    end
end

function NSI:GetSubGroup(unit)
    for i=1, 40 do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name and UnitIsUnit(name, unit) then
            return subgroup
        end
    end
    return 1 -- fallback to 1 if not in raid
end

function NSI:SpecToName(specid)
    if specid == 1 then return "\124T" .. 135724 .. ":10:10:0:0:64:64:4:60:4:60\124t" .. " " .. "All Specs" end
    local _, specName, _, icon, _, classFile = GetSpecializationInfoByID(specid)
    if not specName then return "" end
    local color = GetClassColorObj(classFile)
    return "\124T" .. icon .. ":10:10:0:0:64:64:4:60:4:60\124t" .. " " .. color:WrapTextInColorCode(specName)
end

function NSI:Utf8Sub(str, startChar, endChar)
    if issecretvalue(str) or not str then return str end
    local startIndex, endIndex = 1, #str
    local currentIndex, currentChar = 1, 0

    while currentIndex <= #str do
        currentChar = currentChar + 1

        if currentChar == startChar then
            startIndex = currentIndex
        end
        if endChar and currentChar > endChar then
            endIndex = currentIndex - 1
            break
        end

        local c = string.byte(str, currentIndex)
        if c < 0x80 then
            currentIndex = currentIndex + 1
        elseif c < 0xE0 then
            currentIndex = currentIndex + 2
        elseif c < 0xF0 then
            currentIndex = currentIndex + 3
        else
            currentIndex = currentIndex + 4
        end
    end

    return string.sub(str, startIndex, endIndex)
end

function NSI:UnitAura(unit, spell) -- simplify aura checking for myself
    if self:Restricted() then return "" end
    if unit and UnitExists(unit) and spell then
        if type(spell) == "string" or not C_UnitAuras.GetUnitAuraBySpellID then
            local spelltable = C_Spell.GetSpellInfo(spell)
            return spelltable and C_UnitAuras.GetAuraDataBySpellName(unit, spelltable.name)
        elseif type(spell) == "number" then
            return C_UnitAuras.GetUnitAuraBySpellID(unit, spell)
        else
            return false
        end
    end
end

NSI.Callbacks = NSI.Callbacks or LibStub("CallbackHandler-1.0"):New(NSI)

function NSI:FireCallback(event, ...)
    self.Callbacks:Fire(event, ...)
end

function NSAPI.RegisterCallback(target, event, callback, owner)
    return NSI.RegisterCallback(target, event, callback, owner)
end

function NSAPI.UnregisterCallback(target, event)
    return NSI.UnregisterCallback(target, event)
end

function NSAPI.UnregisterAllCallbacks(target)
    return NSI.UnregisterAllCallbacks(target)
end

local Serialize = LibStub("AceSerializer-3.0")
local Compress = LibStub("LibDeflate")

-- Snapshot of the original locale strings before any override is applied.
local _localeSnapshot = nil

function NSI:CreateExportString(SettingsTable) -- {"ReminderSettings", "PASettings", ...}
    local str = ""
    local ExportTable = {}
    for k, Settings in pairs(SettingsTable) do
        if Settings.enabled then
            ExportTable[k] = Settings
        end
    end
    local serialized = Serialize:Serialize(ExportTable)
    local compressed = serialized and Compress:CompressDeflate(serialized)
    local encoded = compressed and Compress:EncodeForPrint(compressed)
    return encoded or ""
end

function NSI:ImportFromTable(ImportTable)
    local changed = false
    for k, v in pairs(ImportTable) do
        if v.enabled then
            changed = true
            NSRT[k] = v.data
        end
    end
    if changed then
        ReloadUI()
    end
end

function NSI:ImportSettingsFromString(string)
    local decoded = Compress:DecodeForPrint(string)
    local decompressed = decoded and Compress:DecompressDeflate(decoded)
    if not decompressed then return nil end
    local success, data = Serialize:Deserialize(decompressed)
    if success and data then
        return data
    else return nil end
end

function NSI:SaveFramePosition(F, SettingsTable)
    if not F or not SettingsTable then return end
    local Anchor, _, relativeTo, xOffset, yOffset = F:GetPoint()
    xOffset = Round(xOffset)
    yOffset = Round(yOffset)
    SettingsTable.xOffset = xOffset
    SettingsTable.yOffset = yOffset
    SettingsTable.Anchor = Anchor
    SettingsTable.relativeTo = relativeTo
end

function NSI:StopFrameMove(F, SettingsTable)
    if not F then return end
    F:StopMovingOrSizing()
    self:SaveFramePosition(F, SettingsTable)
end

function NSI:MakeDraggable(F, settingsTable, enable, isNote)
    if not F then return end

    if enable then
        if (not F.dragBorder) and (not isNote) then
            F.dragBorder = CreateFrame("Frame", nil, F, "BackdropTemplate")
            F.dragBorder:SetPoint("TOPLEFT",     F, "TOPLEFT",     -8,  8)
            F.dragBorder:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT",  8, -8)
            F.dragBorder:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8", tileSize = 0,
                edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 4,
            })
            F.dragBorder:SetBackdropColor(0, 0, 0, 0)
            F.dragBorder:SetBackdropBorderColor(0.3, 0.67, 0.78, 1)
        end
        F:SetMovable(true)
        F:EnableMouse(true)
        F:RegisterForDrag("LeftButton")
        F:SetClampedToScreen(true)
        if not isNote then F:SetFrameStrata("DIALOG") end
        F:Show()
        if F.Border and isNote then F.Border:Show() end
        if F.dragBorder then F.dragBorder:Show() end
        if F.Text then F.Text:Show() end
        if F.TitleLabel then F.TitleLabel:Show() end
        if F.GearButton then F.GearButton:Show() end

        F:SetScript("OnDragStart", function(f)
            f:StartMoving()
            if settingsTable and not isNote then
                f._nsrtDragSaveElapsed = 0
                f._nsrtLiveSaveDrag = true
                f:SetScript("OnUpdate", function(frame, elapsed)
                    frame._nsrtDragSaveElapsed = (frame._nsrtDragSaveElapsed or 0) + elapsed
                    if frame._nsrtDragSaveElapsed < 0.05 then return end
                    frame._nsrtDragSaveElapsed = 0
                    self:SaveFramePosition(frame, settingsTable)
                end)
            end
        end)
        F:SetScript("OnDragStop", function(f)
            if f._nsrtLiveSaveDrag then
                f:SetScript("OnUpdate", nil)
                f._nsrtLiveSaveDrag = nil
                f._nsrtDragSaveElapsed = nil
            end
            self:StopFrameMove(f, settingsTable)
        end)
    else
        if F.Border and isNote then F.Border:Hide() end
        if F.dragBorder then F.dragBorder:Hide() end
        if F.Text then F.Text:Hide() end
        if F.TitleLabel then F.TitleLabel:Hide() end
        if F.GearButton then F.GearButton:Hide() end
        if F.SettingsWindow then F.SettingsWindow:Hide() end

        F:SetMovable(false)
        F:EnableMouse(false)
        if F._nsrtLiveSaveDrag then
            F:SetScript("OnUpdate", nil)
            F._nsrtLiveSaveDrag = nil
            F._nsrtDragSaveElapsed = nil
        end
        F:SetScript("OnDragStart", nil)
        F:SetScript("OnDragStop",  nil)
    end
end

function NSI:LogTimeline(e, ...)
    if not NSRT.Settings.DebugLogs then return end
    local id = self:DifficultyCheck({14, 15, 16})
    if not id then return end
    if e == "ENCOUNTER_START" then
        local encID, encName, difficultyID, groupSize = ...
        local now = GetTime()
        local date = C_DateAndTime.GetCurrentCalendarTime()
        self.CurrentEncounterData = {
            Name = encName,
            encID = encID,
            difficulty = difficultyID == 16 and "Mythic" or difficultyID == 15 and "Heroic" or difficultyID == 14 and "Normal",
            pullTime = now,
            startTime = string.format("%02d:%02d", date.hour, date.minute),
            success = false,
            length = 0,
            events = {},
        }
    elseif e == "ENCOUNTER_END" then
        local success = select(5, ...)
        local now = GetTime()
        if self.CurrentEncounterData then
            self.CurrentEncounterData.success = success == 1
            local elapsed = now - self.CurrentEncounterData.pullTime
            if elapsed >= 30 then
                self.CurrentEncounterData.pullTime = nil
                self.CurrentEncounterData.length = string.format("%02d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
                table.insert(NSRTTimelineData, self.CurrentEncounterData)
            end
        end
        self.CurrentEncounterData = nil
    elseif e == "NSRT_PHASE" then
        local phase = ...
        if self.CurrentEncounterData then
            local now = GetTime()
            tinsert(self.CurrentEncounterData.events, string.format("[%7.2f]  Phase Detected: %s", now - self.CurrentEncounterData.pullTime, phase))
        end
    elseif self.CurrentEncounterData then
        local info = ...
        local data = {}
        local now = GetTime()
        local stateNames = { [0] = "Active", [1] = "Paused", [2] = "Finished", [3] = "Canceled" }
        if e == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
            data.dur = info.duration
            data.id = info.id
            data.Queue = info.maxQueueDuration
        elseif e == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then
            data.id = info
            local stateVal = C_EncounterTimeline.GetEventState(info)
            data.state = stateNames[stateVal] or tostring(stateVal)
        elseif e == "ENCOUNTER_WARNING" then
            data.id = "nil"
            data.dur = info.duration
            data.severity = info.severity
        else
            data.id = info
        end
        data.time = now - self.CurrentEncounterData.pullTime
        tinsert(self.CurrentEncounterData.events, string.format("[%6.2f]  %-45s  id: %-10s%s%s%s%s",
            data.time,
            e,
            tostring(data.id or "nil"),
            data.dur and string.format("  dur: %-10.4f", data.dur) or "",
            data.Queue and string.format("  queue: %.4f", data.Queue) or "",
            data.state and string.format("  state: %s", data.state) or "",
            data.severity and string.format("  severity: %s", data.severity) or ""
        ))
    end
end

function NSI:GetMySpecID()
    return C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization()) or 0
end

function NSI:EncounterRegister(frameName, event, enable, units, all)
    if not self.EncounterFrames then
        self.EncounterFrames = {}
    end
    if all then
        for k, v in pairs(self.EncounterFrames or {}) do
            v:UnregisterAllEvents()
        end
        return
    end
    if not frameName then return end
    if event and not self.EncounterFrames[frameName] then
        self.EncounterFrames[frameName] = CreateFrame("Frame", nil, self.NSRTFrame)
    end
    if event and type(event) == "table" then
        for _, e in ipairs(event) do
            self:EncounterRegister(frameName, e, enable, units)
        end
        return
    end
    if enable then
        if units then
            if type(units) == "table" then
                self.EncounterFrames[frameName]:RegisterUnitEvent(event, units[1], units[2], units[3], units[4])
            else
                self.EncounterFrames[frameName]:RegisterUnitEvent(event, units)
            end
        else
            self.EncounterFrames[frameName]:RegisterEvent(event)
        end
    elseif event then
        self.EncounterFrames[frameName]:UnregisterEvent(event)
    end
end

function NSI:EncounterFunction(frameName, func)
    if not frameName then return end
    self.EncounterFrames = self.EncounterFrames or {}
    if not self.EncounterFrames[frameName] then
        self.EncounterFrames[frameName] = CreateFrame("Frame", nil, self.NSRTFrame)
    end
    self.EncounterFrames[frameName]:SetScript("OnEvent", func)
end

function NSI:IsInSameGuild(unit, playerName)
    if not playerName then
        local name, realm = UnitName(unit)
        if not realm then
            realm = select(2, UnitFullName("player"))
        end
        if not name then return false end
        playerName = name.."-"..realm
    end
    for i=1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name == playerName then
            return true
        end
    end
    return false
end

function NSAPI:IsInSameGuild(unit, playerName)
    return NSI:IsInSameGuild(unit, playerName)
end
