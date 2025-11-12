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

function NSAPI:Version() -- function for version check WA
    return 18
end

function NSI:IsMidnight()
  return select(4, GetBuildInfo()) >= 120000
end

function NSI:Print(...)
    if NSRT.Settings["DebugLogs"] then
        if DevTool then
            local t = {...}
            local name = t[1]
            print("added", name, "to DevTool Logs")
            table.remove(t, 1)
            DevTool:AddData(t, name)
        else
            print(...)
        end
    end
end

function NSI:Restricted()
    return (self:IsMidnight() and GetRestrictedActionStatus(0)) or (WeakAuras and WeakAuras.CurrentEncounter)
end

function NSAPI:Shorten(unit, num, specicon, AddonName, combined, roleicon) -- Returns color coded Name/Nickname
    local classFile = unit and select(2, UnitClass(unit))
    if specicon then
        local specid = 0
        if unit then specid = NSAPI:GetSpecs(unit) or 0 end
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
        name = num and WeakAuras.WA_Utf8Sub(NSAPI:GetName(name, AddonName), num) or NSAPI:GetName(name, AddonName) -- shorten name before wrapping in color
        if color then -- should always be true anyway?
            return combined and specicon..roleicon..color:WrapTextInColorCode(name) or color:WrapTextInColorCode(name), combined and "" or specicon, combined and "" or roleicon
        else
            return combined and specicon..roleicon..name or name, combined and "" or specicon, combined and "" or roleicon
        end
    else
        return unit, "", "" -- return input if nothing was found
    end
end

function NSAPI:GetSpecs(unit)
    if unit then
        return NSI.specs[unit] or false -- return false if no information available for that unit so it goes to the next fallback
    else
        return NSI.specs -- if no unit is given then entire table is requested
    end
end


function NSAPI:GetNote(disablecheck) -- Get rid of extra spaces and color coding. Also converts nicknames
    if not C_AddOns.IsAddOnLoaded("MRT") then
        print("Addon MRT is disabled, can't read the note")
        return "empty"
    end
    if not VMRT.Note.Text1 then
        print("No MRT Note found")
        return "empty"
    end
    local persnote = _G.VMRT.Note.SelfText or ""
    persnote =  strtrim(persnote)
    NSI.persnotedisable = false
    if persnote and persnote ~= "" then
        for line in persnote:gmatch('[^\r\n]+') do
            line = strtrim(line)
            if line == "nsdisable" then
                NSI.persnotedisable = true
                NSAPI.disable = true
                if disablecheck then return "" end
                break
            end
        end
    end
    local note = _G.VMRT.Note.Text1 or ""
    local now = GetTime()
    if (not NSI.RawNote) or NSI.RawNote ~= note or NSAPI.disable or ((not NSI.LastNote) or now > NSI.LastNote+2) then
        NSI.LastNote = now
        NSAPI.UseLiquid = false
        NSI.notedisable = false
        local newnote = ""
        local list = false
        note = strtrim(note)
        note = note:gsub("||r", "") -- clean colorcode
        note = note:gsub("||c%x%x%x%x%x%x%x%x", "") -- clean colorcode        
        for line in note:gmatch('[^\r\n]+') do
            line = strtrim(line)
            if strlower(line) == "nsuseliquid" then
                NSAPI.UseLiquid = true
            elseif strlower(line) == "nsdisable" then -- global disable all NS Assign Auras for everyone in the raid
                NSAPI.disable = true
                NSI.notedisable = true
                if disablecheck then return "" end -- end early if we found the only thing we care about would like to just return "" in all cases here but then interrupt aura stops working with nsdisable.      
            --check for start/end of the name list
            elseif string.match(line, "ns.*start") or strlower(line) == "intstart" then -- match any string that starts with "ns" and ends with "start" as well as the interrupt WA
                list = true
            elseif string.match(line, "ns.*end") or strlower(line) == "intend" then
                list = false
                newnote = newnote..line.."\n"
            end
            if list then
                newnote = newnote..line.."\n"
            end
        end
        if disablecheck then return "" end -- if all we care about is checking if assignments are disabled then just return an empty string early.
        note = newnote
        local namelist = {}
        local groupsdone = {}
        for group in note:gmatch("[gG]roup(%d+)") do
            local num = tonumber(group)
            local names = ""
            if num and num >=1 and num <= 8 and not groupsdone[num] then
                groupsdone[num] = true
                for i=1, 40 do
                    local name, _, subgroup = GetRaidRosterInfo(i)
                    if name and subgroup == num then
                        if names == "" then
                            names = name
                        else
                            names = names.." "..name
                        end
                    end
                end
            end
            if names ~= "" then
                note = note:gsub("[gG]roup"..group, names)
            end
        end
        for name in note:gmatch("%S+") do -- finding all strings
            local charname = (UnitIsVisible(name) and name) or NSAPI:GetChar(name, true, "Note")
            if name ~= charname and UnitExists(charname) and not namelist[name] then
                namelist[name] = charname
            end
        end
        for nickname, charname in pairs(namelist) do
            note = note:gsub("(%f[%w])"..nickname.."(%f[%W])", "%1"..charname.."%2")
        end        
        NSI.Note = note
    end    
    NSI.RawNote = _G.VMRT.Note.Text1 or ""
    NSAPI.disable = NSI.notedisable or NSI.persnotedisable
    NSI.Note = NSI.Note or ""
    return NSI.Note
end

function NSAPI:UnitAura(unit, spell) -- simplify aura checking for myself
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

function NSAPI:TTSCountdown(num)
    for i= num, 1, -1 do
        if i == num then 
            NSAPI:TTS(i)
        else
            C_Timer.After(num-i, function() NSAPI:TTS(i) end)
        end
    end
end

function NSI:Difficultycheck(encountercheck, num) -- check if current difficulty is a Normal/Heroic/Mythic raid and also allow checking if we are currently in an encounter
    local difficultyID = select(3, GetInstanceInfo()) or 0
    return NSRT.Settings["Debug"] or ((difficultyID <= 16 and difficultyID >= num) and ((not encountercheck) or self:EncounterCheck()))
end

function NSI:EncounterCheck(skipdebug)
    return WeakAuras.CurrentEncounter or (NSRT.Settings["Debug"] and not skipdebug)
end

-- this one is public as I want to use it in WeakAuras as well
function NSAPI:DeathCheck(unit)
    if unit and UnitExists(unit) then
        return (UnitIsDead(unit) and not UnitIsFeignDeath(unit)) or NSAPI:UnitAura(unit, 27827)
    end
end

-- technically don't need this to be public but it's good for backwards compatibility for a while
function NSAPI:GetHash(text)
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

local path = "Interface\\AddOns\\NorthernSkyRaidTools\\Media\\Sounds\\"
function NSAPI:TTS(sound, voice, overlap) -- NSAPI:TTS("Bait Frontal")
    if NSRT.Settings["TTS"] then
        sound = tostring(sound)
        local handle = select(2, PlaySoundFile(path..sound..".ogg", "Master"))  
        if handle then
            PlaySoundFile(path..sound..".ogg", "Master")
        else
            local num = voice or NSRT.Settings["TTSVoice"]
            if NSI:IsMidnight() then
                C_VoiceChat.SpeakText(
                    num,
                    sound,
                    C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0,
                    NSRT.Settings["TTSVolume"],
                    overlap
                )
            else
                C_VoiceChat.SpeakText(
                    num,
                    sound,
                    Enum.VoiceTtsDestination.LocalPlayback,
                    C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0,
                    NSRT.Settings["TTSVolume"]
                )
            end
        end
    end    
end

function NSAPI:PrivateAura()
    local now = GetTime()
    if (not NSAPI.LastPAMacro) or NSAPI.LastPAMacro < now-4 then -- putting this into global NSAPI namespace to allow auras to reset it if ever required
        NSAPI.LastPAMacro = now
        WeakAuras.ScanEvents("NS_PA_MACRO", true) -- this is for backwards compatibility
        NSI:Broadcast("NS_PAMACRO", "RAID", "nilcheck") -- this will be used going forward, slightly different wording to prevent issues with old auras
    end
end

function NSI:SendWAString(str)
    if str and str ~= "" and type(str) == "string" then
        self:Broadcast("NSI_WA_SYNC", "RAID", str)
    end
end

function NSI:SpecToName(specid)
    if specid == 1 then return "\124T" .. 135724 .. ":10:10:0:0:64:64:4:60:4:60\124t" .. " " .. "All Specs" end
    local _, specName, _, icon, _, classFile = GetSpecializationInfoByID(specid)
    if not specName then return "" end
    local color = GetClassColorObj(classFile)
    return "\124T" .. icon .. ":10:10:0:0:64:64:4:60:4:60\124t" .. " " .. color:WrapTextInColorCode(specName)
end

local function ON_WA_UPDATE()
    table.remove(NSI.importtable, 1)
    if #NSI.importtable > 0 then
        WeakAuras.Import(NSI.importtable[1], nil, ON_WA_UPDATE)
    end
end
function NSAPI:GUIDInfo(unit)
    if UnitExists(unit) then
        local G = UnitGUID(unit)
        local unitType, _, _, _, _, npcID, spawnUID = strsplit("-", G)
        if unitType == "Creature" or unitType == "Vehicle" then
            local spawnEpoch = GetServerTime() - (GetServerTime() % 2^23)
            local spawnEpochOffset = bit.band(tonumber(string.sub(spawnUID, 5), 16), 0x7fffff)
            local spawnIndex = bit.rshift(bit.band(tonumber(string.sub(spawnUID, 1, 5), 16), 0xffff8), 3)

            return npcID, spawnIndex
        end
    end
end

function NSI:AutoImport()
    self.importtable = {}
    self.imports = {}
    if NSRT.Settings["AutoUpdateRaidWA"] then        
        if WeakAurasCompanionData then
            local WeakAurasData = {
                slugs = {
                    ["NSManaforge"] = {
                        name = self.RaidWAData.name,
                        author = "Reloe",
                        wagoVersion = tostring(self.RaidWAData.version),
                        wagoSemver = self.RaidWAData.wagoVersion,
                        source = "Northern Sky Raid Tools",
                        versionNote = self.RaidWAData.versionNote,
                        logo = "Interface\\AddOns\\NorthernSkyRaidTools\\Media\\NSLogo.blp",
                        refreshLogo = "Interface\\AddOns\\NorthernSkyRaidTools\\Media\\NSLogo.blp",
                        encoded = self.RaidWAData.string
                    }
                }
            }
            WeakAuras.AddCompanionData(WeakAurasData)
        end
        local waData = WeakAuras.GetData(self.RaidWAData.name)
        local version = waData and waData.url and waData.url:match("%d+$") or 0
        version = version and tonumber(version) or 0
        if (self.RaidWAData.version > version or not version) and self.RaidWAData.string then
            table.insert(self.importtable, self.RaidWAData.string)
        end
    end
    if NSRT.Settings["AutoUpdateWA"] then
        local WAdata = WeakAurasCompanionData and WeakAurasCompanionData.WeakAuras and WeakAurasCompanionData.WeakAuras.slugs
        local WagoData = WagoAppCompanionData 
        if WAdata then
            for k, v in pairs(WAdata) do
                if NSRT.Settings["UpdateWhitelist"][k] then
                    local url = ""
                    for a, b in pairs(WeakAurasSaved.displays) do
                        if b.url then
                            if (b.url:match("^%w+$") or b.url:match("wago%.io/([%w_]+)")) == k then 
                                url = b.url
                                break
                            end
                        end
                    end
                    local version = url and url ~= "" and url:match("%d+$") or 0
                    version = version and tonumber(version) or 0
                    if version ~= 0 and tonumber(v.wagoVersion) > version and not self.imports[url] then
                        self.imports[url] = true
                        table.insert(self.importtable, v.encoded)
                    end
                end
            end
        end
        
        if wagoData then
            for k, v in pairs(WagoAppCompanionData["ids"]) do
                if NSRT.Settings["UpdateWhitelist"][v] or NSRT.Settings["Debug"] then
                    local data = WagoAppCompanionData["slugs"][v]
                    if data and data.wagoVersion then
                        local url = ""
                        for a, b in pairs(WeakAurasSaved.displays) do
                            if b.wagoID == k then
                                url = b.url
                                break
                            end
                        end
                        local version = url and url ~= "" and url:match("%d+$") or 0
                        version = version and tonumber(version) or 0
                        if version ~= 0 and tonumber(data.wagoVersion) > version and not self.imports[url] then
                            self.imports[url] = true
                            table.insert(self.importtable, WagoAppCompanionData["slugs"][v].encoded)
                        end
                    end
                end
            end
        end
    end
    if #self.importtable > 0 then
        WeakAuras.Import(self.importtable[1], nil, ON_WA_UPDATE)
    end
end


function NSI:AddWhitelistURL(url, name)
    local id = url:match("^%w+$") or url:match("wago%.io/([%w_]+)")
    if id and url and name then NSRT.Settings["UpdateWhitelist"][id] = {name = name, url = url} end
end


function NSI:RemoveWhitelistURL(url, name)
    local id = ""
    if url:match("^%w+$") then
        id = url
    else
        id = url:match("wago%.io/([%w_]+)")
    end
    if NSRT.Settings["UpdateWhitelist"][id] then
        NSRT.Settings["UpdateWhitelist"][id] = nil
    end
end

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
            if phase and time and name and (text or spellID) then
                if name == "everyone" or name:match(UnitName("player")) or name:match(UnitGroupRolesAssigned("player")) or name:match(NSAPI:GetName("player", "GlobalNickNames")) then     
                    phase = tonumber(phase)
                    self.ProcessedAssigns[phase] = self.ProcessedAssigns[phase] or {}             
                    table.insert(self.ProcessedAssigns[phase], {phase = phase, id = #self.ProcessedAssigns[phase]+1, time = tonumber(time), text = text, TTS = (TTS == "yes" and text) or TTS, spellID = spellID and tonumber(spellID), dur = dur or 8})
                end
            end
        end
    end
end
-- /run NSAPI:Broadcast("NS_ASSIGN_SHARE", "RAID", "EncounterID:2400\n1|20|everyone|xdtext|123\n2|20|TANK\n3|30|Reloe\n4|40|Relowindi")

function NSI:CreateText()
    self.AssignText = self.AssignText or {}
    for i=1, 100 do
        if self.AssignText[i] and not self.AssignText[i]:IsShown() then 
            return self.AssignText[i] 
        end
        if not self.AssignText[i] then
            local xOffset, yOffset = -200, 200
            local Font = self.LSM:Fetch("font", "PT Sans Narrow Bold")
            local FontSize = 50
            yOffset = yOffset + (i-1) * FontSize
            self.AssignText[i] = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.AssignText[i]:SetPoint("LEFT", UIParent, "CENTER", xOffset, yOffset)
            self.AssignText[i]:SetFont(Font, FontSize, "OUTLINE")
            self.AssignText[i]:SetShadowColor(0, 0, 0, 1)
            self.AssignText[i]:SetShadowOffset(0, 0)
            self.AssignText[i]:SetTextColor(1, 1, 1, 1)
            return self.AssignText[i]
        end
    end
end

function NSI:CreateIcon(spellID)
    self.AssignIcon = self.AssignIcon or {}
    local icon = C_Spell.GetSpellInfo(spellID).iconID
    for i=1, 100 do
        if self.AssignIcon[i] and not self.AssignIcon[i]:IsShown() then 
            self.AssignIcon[i].Icon:SetTexture(icon)
            return self.AssignIcon[i] 
        end
        if not self.AssignIcon[i] then
            local xOffset, yOffset = -400, 400
            local xTextOffset, yTextOffset = 0, 0
            local Font = self.LSM:Fetch("font", "PT Sans Narrow Bold")
            local Size = 80
            local FontSize = 22
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
            return self.AssignIcon[i]
        end
    end
end

function NSI:DisplayReminder(info)
    local dur = info.dur or 8
    info.startTime = GetTime()
    info.dur = dur
    local rem = math.ceil((dur - (GetTime()-info.startTime))*10)/10 -- Round to 1 Decimal
    if rem <= 0 then
        return
    end
    rem = (rem % 1 == 0) and string.format("%.1f", rem) or rem
    local text = info.text ~= "" and info.text.." - ("..rem..")" or rem
    text = text:gsub("{rt(%d)}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%1:0|t")
    local id = info.id
    local phase = info.phase
    local spellID = info.spellID
    local F
    if spellID and spellID ~= "false" then -- display icon if we have a spellID    
        F = self:CreateIcon(spellID)
        F.Text:SetText(text)
        F:Show()
    else
        F = self:CreateText()
        F:SetText(text)
        F:Show()
    end    
    if info.TTS and info.TTS ~= "" and info.TTS ~= "false" then
        local TTS = (info.TTS == "true" and info.text) or (info.TTS == info.text and info.text) or info.TTS
        NSAPI:TTS(TTS)
    end
    self.UpdateTimer = self.UpdateTimer or {}
    self.UpdateTimer[id] = C_Timer.NewTimer(0.05, function()
        self.UpdateTimer[id] = nil
        self:UpdateReminderDisplay(info, F)
    end)
end

function NSI:UpdateReminderDisplay(info, F)
    local rem = math.ceil((info.dur - (GetTime()-info.startTime))*10)/10 -- Round to 1 Decimal
    if rem <= 0 then
        F:Hide()
        return
    end
    rem = (rem % 1 == 0) and string.format("%.1f", rem) or rem
    local text = info.text ~= "" and info.text.." - ("..rem..")" or rem
    text = text:gsub("{rt(%d)}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%1:0|t")
    local phase = info.phase
    local id = info.id
    if info.spellID and info.spellID ~= "false" then
        F.Text:SetText(text)
    else
        F:SetText(text)
    end    
    self.UpdateTimer[id] = C_Timer.NewTimer(0.05, function()
        self.UpdateTimer[id] = nil
        self:UpdateReminderDisplay(info, F)
    end)
end

function NSI:StartReminders(phase)
    self:HideAllReminders()
    self.ReminderTimer = {}
    self.UpdateTimer = {}
    for i, v in ipairs(self.ProcessedAssigns[phase]) do
        self.ReminderTimer[i] = C_Timer.NewTimer(v.time, function()
            self.ReminderTimer[i] = nil
            self:DisplayReminder(v)
        end)
    end
end

function NSI:HideAllReminders()
    for i=1, 100 do
        local F1 = self.AssignText[i]
        local F2 = self.AssignIcon[i]
        if F1 then F1:Hide() end
        if F2 then F2:Hide() end
    end
end

function NSAPI:TestDisplay()
    if NSRT.Settings["Debug"] then
        local now = GetTime()
        local info1 = {text = "Use Defensive", TTS = "false", phase = 1, id = 1, dur = 5, startTime = now}
        local info2 = {text = "This is the Icon display", TTS = "false", phase = 1, id = 2, spellID = 774, startTime = now}
        local info3 = {text = "Stack at {rt7}", TTS = "Stack on X", phase = 2, id = 1, dur = 8, startTime = now}
        local info4 = {text = "This is another Icon display", TTS = "", phase = 2, id = 2, dur = 10, spellID = 8936, startTime = now}
        NSI:DisplayReminder(info1)
        NSI:DisplayReminder(info2)
        NSI:DisplayReminder(info3)
        NSI:DisplayReminder(info4)
    end
end