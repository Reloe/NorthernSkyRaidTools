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
    local classFile = unit and select(2, UnitClass(unit))
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
        local name = UnitName(unit)
        local color = GetClassColorObj(classFile)
        name = num and NSI:Utf8Sub(NSAPI:GetName(name, AddonName), 1, num) or NSAPI:GetName(name, AddonName) -- shorten name before wrapping in color
        if color then -- should always be true anyway?
            return combined and specicon..roleicon..color:WrapTextInColorCode(name) or color:WrapTextInColorCode(name), combined and "" or specicon, combined and "" or roleicon
        else
            return combined and specicon..roleicon..name or name, combined and "" or specicon, combined and "" or roleicon
        end
    else
        return unit, "", "" -- return input if nothing was found
    end
end

function NSI:GetSpecs(unit)
    if unit then
        return NSI.specs[unit] or false -- return false if no information available for that unit so it goes to the next fallback
    else
        return NSI.specs -- if no unit is given then entire table is requested
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

function NSI:DifficultyCheck(num) -- check if current difficulty is a Normal/Heroic/Mythic raid and also allow checking if we are currently in an encounter
    local difficultyID = select(3, GetInstanceInfo()) or 0
    return ((difficultyID >= num and difficultyID <= 16 and difficultyID)) or (NSRT.Settings["Debug"] and 16)
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
function NSAPI:TTS(sound, voice, overlap) -- NSAPI:TTS("Bait Frontal")
    if NSRT.Settings["TTS"] then
        local secret = issecretvalue(sound)
        local handle = (not secret) and select(2, PlaySoundFile(path..sound..".ogg", "Master"))
        if handle then
            PlaySoundFile(path..sound..".ogg", "Master")
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
                NSRT.Settings["TTSVolume"],
                overlap
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

function NSAPI:RegisterCallback(event, callback, owner)
    return NSI:RegisterCallback(event, callback, owner)
end

function NSAPI:UnregisterCallback(event, callback, owner)
    return NSI:UnregisterCallback(event, callback, owner)
end

function NSAPI:UnregisterAllCallbacks(owner)
    return NSI:UnregisterAllCallbacks(owner)
end

local Serialize = LibStub("AceSerializer-3.0")
local Compress = LibStub("LibDeflate")

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

function NSI:StopFrameMove(F, SettingsTable)
    if not F then return end
    F:StopMovingOrSizing()
    local Anchor, _, relativeTo, xOffset, yOffset = F:GetPoint()
    xOffset = Round(xOffset)
    yOffset = Round(yOffset)
    SettingsTable.xOffset = xOffset
    SettingsTable.yOffset = yOffset
    SettingsTable.Anchor = Anchor
    SettingsTable.relativeTo = relativeTo
end

function NSI:ToggleMoveFrames(F, Unlock)
    if not F then return end
    if Unlock then
        F:SetMovable(true)
        F:EnableMouse(true)
        F:RegisterForDrag("LeftButton")
        F:SetClampedToScreen(true)
        F.Border:Show()
        F:Show()
        if F.Border then F.Border:Show() end
        if F.Text then F.Text:Show() end
    else
        if F.Border then F.Border:Hide() end
        if F.Text then F.Text:Hide() end
        F:SetMovable(false)
        F:EnableMouse(false)
    end
end

function NSI:IsMelee(unit)
    local role = UnitGroupRolesAssigned(unit)
    if unit == "player" then
        local spec = GetSpecializationInfo(GetSpecialization())
        local melee = false
        if self.meleetable[spec] or role == "TANK" then
            melee = true
        end
        return melee
    else
        local spec = NSI:GetSpecs(unit) or 0
        if spec and spec ~= 0 then
            local melee = false
            if self.meleetable[spec] or role == "TANK" then
                melee = true
            end
            return melee
        else
            return role == "TANK"
        end
    end
end

function NSI:MuteSFX(mute)
    if mute then
        for i=1, 10000000 do
            MuteSoundFile(i)
        end
    else
        for i=1, 10000000 do
            UnmuteSoundFile(i)
        end
    end
end

function NSI:LogTimeline(e, ...)
    if not NSRT.Settings.DebugLogs then return end
    local id = select(3, GetInstanceInfo())
    if id > 16 or id < 14 then return end
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
            self.CurrentEncounterData.pullTime = nil
            self.CurrentEncounterData.length = string.format("%02d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
            table.insert(NSRTTimelineData, self.CurrentEncounterData)
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
            data.dur = info.time
            data.id = info.id
            data.Queue = info.maxQueueDuration
        elseif e == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then
            data.id = info
            local stateVal = C_EncounterTimeline.GetEventState(info)
            data.state = stateNames[stateVal] or tostring(stateVal)
        else
            data.id = info
        end
        data.time = now - self.CurrentEncounterData.pullTime
        tinsert(self.CurrentEncounterData.events, string.format("[%7.2f]  %-45s  id: %-10s%s%s%s",
            data.time,
            e,
            tostring(data.id or "nil"),
            data.dur and string.format("  dur: %-10.4f", data.dur) or "",
            data.Queue and string.format("  queue: %.4f", data.Queue) or "",
            data.state and string.format("  state: %s", data.state) or ""
        ))
    end
end