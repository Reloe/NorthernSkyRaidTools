local _, NSI = ... -- Internal namespace
--[[
local lib = LibStub("CallbackHandler-1.0")
NSI.callbacks = {
    lib:New(NSI, "RegisterCallback", "UnregisterCallback", "UnregisterAllCallbacks")
}
NSI:RegisterCallback("NS_WA_UPDATED", ON_WA_UPDATE)]]
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
    return 16
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

function NSAPI:Shorten(unit, num, role, AddonName, combined) -- Returns color coded Name/Nickname
    local classFile = unit and select(2, UnitClass(unit))
    if role then -- create role icon if requested
        local specid = 0
        if unit then specid = NSAPI:GetSpecs(unit) or WeakAuras.SpecForUnit(unit) or 0 end
        local icon = select(4, GetSpecializationInfoByID(specid))
        if icon then -- if we didn't get the specid can at least try to return the role icon     
            role = "\124T"..icon..":12:12:0:0:64:64:4:60:4:60\124t"
        else  
            role = UnitGroupRolesAssigned(unit)
            if role ~= "NONE" then
                role = CreateAtlasMarkup(GetIconForRole(role), 0, 0)
            else
                role = ""
            end
        end
    end
    if classFile then -- basically "if unit found"
        local name = UnitName(unit)
        local color = GetClassColorObj(classFile)
        name = num and WeakAuras.WA_Utf8Sub(NSAPI:GetName(name, AddonName), num) or NSAPI:GetName(name, AddonName) -- shorten name before wrapping in color
        if color then -- should always be true anyway?
            return combined and role..color:WrapTextInColorCode(name) or color:WrapTextInColorCode(name), combined and "" or role
        else
            return combined and role..name or name, combined and "" or role
        end
    else
        return unit, "" -- return input if nothing was found
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
            if line == "nsdisable" then
                NSI.persnotedisable = true
                NSAPI.disable = true
                if disablecheck then return "" end
                break
            end
        end
    end
    local note = _G.VMRT.Note.Text1 or ""    
    if (not NSI.RawNote) or NSI.RawNote ~= note or (NSAPI.disable and not disable) then -- only do this if the note has changed or not been checked at all this session
        NSI.RawNote = note
        NSI.notedisable = false
        local newnote = ""
        local list = false
        note = strtrim(note)
        for line in note:gmatch('[^\r\n]+') do
            if line == "nsdisable" then -- global disable all NS Auras for everyone in the raid
                NSAPI.disable = true
                NSI.notedisable = true
                if disablecheck then return "" end -- end early if we found the only thing we care about
                -- would like to just return "" in all cases here but then interrupt aura stops working with nsdisable.
            end
            --check for start/end of the name list
            if string.match(line, "ns.*start") or line == "intstart" then -- match any string that starts with "ns" and ends with "start" as well as the interrupt WA
                list = true
            elseif string.match(line, "ns.*end") or line == "intend" then
                list = false
                newnote = newnote..line.."\n"
            end
            if list then
                newnote = newnote..line.."\n"
            end
        end
        if disablecheck then return "" end -- if all we care about is checking if assignments are disabled then just return an empty string early.
        note = newnote
        note = note:gsub("||r", "") -- clean colorcode
        note = note:gsub("||c%x%x%x%x%x%x%x%x", "") -- clean colorcode
        local namelist = {}
        for name in note:gmatch("%S+") do -- finding all strings
            local charname = (UnitIsVisible(name) and name) or NSAPI:GetChar(name, true)
            if name ~= charname and not namelist[name] then
                namelist[name] = charname
            end
        end
        for nickname, charname in pairs(namelist) do
            note = note:gsub("(%f[%w])"..nickname.."(%f[%W])", "%1"..charname.."%2")
        end
        NSI.Note = note
    end
    NSAPI.disable = NSI.notedisable or NSI.persnotedisable
    NSI.Note = NSI.Note or ""
    return NSI.Note
end

function NSI:UnitAura(unit, spellID) -- simplify aura checking for myself
    if unit and UnitExists(unit) and spellID then
        local spell = C_Spell.GetSpellInfo(spellID)
        return spell and C_UnitAuras.GetAuraDataBySpellName(unit, spell.name)
    end
end

function NSI:Difficultycheck(encountercheck, num) -- check if current difficulty is a Normal/Heroic/Mythic raid and also allow checking if we are currently in an encounter
    local difficultyID = select(3, GetInstanceInfo()) or 0
    return NSRT.Settings["Debug"] or ((difficultyID <= 16 and difficultyID >= num) and ((not encountercheck) or NSI:EncounterCheck()))
end

function NSI:EncounterCheck(skipdebug)
    return WeakAuras.CurrentEncounter or (NSRT.Settings["Debug"] and not skipdebug)
end

-- this one is public as I want to use it in WeakAuras as well
function NSAPI:DeathCheck(unit)
    if unit and UnitExists(unit) then
        return (UnitIsDead(unit) and not UnitIsFeignDeath(unit)) or NSI:UnitAura(unit, 27827)
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


function NSAPI:TTS(sound, voice) -- NSAPI:TTS("Bait Frontal", NSRT.TTSVoice)
  if NSRT.Settings["TTS"] then
      local num = voice or NSRT.Settings["TTSVoice"]
        C_VoiceChat.SpeakText(
                num,
                sound,
                Enum.VoiceTtsDestination.LocalPlayback,
                C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0,
                NSRT.Settings["TTSVolume"]
        )
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
        NSI:Broadcast("NSI_WA_SYNC", "RAID", str)
    end
end

function NSI:SpecToName(specid)
    local _, specName, _, icon, _, classFile = GetSpecializationInfoByID(specid)
    if not specName then return "" end
    local color = GetClassColorObj(classFile)
    return "\124T" .. icon .. ":10:10:0:0:64:64:4:60:4:60\124t" .. " " .. color:WrapTextInColorCode(specName)
end

local function ON_WA_UPDATE(updated, name, arg2)
    table.remove(NSI.importtable, 1)    
    if #NSI.importtable > 0 then
        WeakAuras.Import(NSI.importtable[1], nil, ON_WA_UPDATE)
    end
end

function NSI:AutoImport()
    NSI.importtable = {}
    if NSRT.Settings["AutoUpdateRaidWA"] then
        local waData = WeakAuras.GetData(NSI.RaidWAData.name)
        local version = waData and waData.url and waData.url:match("%d+$") or 0
        version = version and tonumber(version) or 0
        if (NSI.RaidWAData.version > version or not version) and NSI.RaidWAData.string then
            table.insert(NSI.importtable, NSI.RaidWAData.string)
        end
    end
    if NSRT.Settings["AutoUpdateWA"] and WagoAppCompanionData then
        for k, v in pairs(WagoAppCompanionData["slugs"]) do
            if NSRT.Settings["UpdateWhitelist"][k] or NSRT.Settings["Debug"] then
                local data = WagoAppCompanionData["slugs"][k]
                if data and data.wagoVersion then
                    local waData = WeakAuras.GetData(data.name)
                    local version = waData and waData.url and waData.url:match("%d+$") or 0
                    version = version and tonumber(version) or 0
                    if version ~= 0 and tonumber(data.wagoVersion) > version then
                        table.insert(NSI.importtable, WagoAppCompanionData["slugs"][k].encoded)
                    end
                end
            end
        end
    end    
    if #NSI.importtable > 0 then
        WeakAuras.Import(NSI.importtable[1], nil, ON_WA_UPDATE)
    end
end
