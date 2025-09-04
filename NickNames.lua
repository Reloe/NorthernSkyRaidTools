local _, NSI = ... -- Internal namespace
local Grid2Status
local fullCharList = {}
local fullNameList = {}
local sortedCharList = {}
local CharList = {}
local LibTranslit = LibStub("LibTranslit-1.0")

function NSAPI:GetCharacters(str) -- Returns table of all Characters from Nickname or Character Name
    if not str then
        error("NSAPI:GetCharacters(str), str is nil")
        return
    end
    if not sortedCharList[str] then
        return CharList[str] and CopyTable(CharList[str])
    else
        return sortedCharList[str] and CopyTable(sortedCharList[str])
    end
end

function NSAPI:GetAllCharacters()
    return CopyTable(fullCharList)
end

function NSAPI:GetName(str, AddonName) -- Returns Nickname
    local unitname = UnitExists(str) and UnitName(str) or str
    -- check if setting for the requesting addon is enabled, if not return the original name.
    -- if no AddonName is given we assume it's from an old WeakAura as they never specified
    if ((not NSRT.Settings["GlobalNickNames"]) or (AddonName and not NSRT.Settings[AddonName])) and AddonName ~= "Note" then
        if NSRT.Settings["Translit"] then
            unitname = LibTranslit:Transliterate(unitname)
        end
        return unitname
    end

    if not str then
        error("NSAPI:GetName(str), str is nil")
        return
    end
    if UnitExists(str) then
        local name, realm = UnitFullName(str)
        if not realm then
            realm = GetNormalizedRealmName()
        end
        local nickname = name and realm and fullCharList[name.."-"..realm]
        if nickname and NSRT.Settings["Translit"] then
            nickname = LibTranslit:Transliterate(nickname)
        end
        if NSRT.Settings["Translit"] and not nickname then
            name = LibTranslit:Transliterate(name)
        end
        return nickname or name
    else
        local nickname = fullCharList[str]
        if not nickname then
            nickname = fullNameList[str]
        end
        if nickname and NSRT.Settings["Translit"] then
            nickname = LibTranslit:Transliterate(nickname)
        end
        return nickname or unitname
    end
end

function NSAPI:GetChar(name, nick, AddonName) -- Returns Char in Raid from Nickname or Character Name with nick = true
    name = nick and NSAPI:GetName(name, AddonName) or name
    if UnitExists(name) and UnitIsConnected(name) then return name end
    local chars = NSAPI:GetCharacters(name)
    if chars then
        for k, _ in pairs(chars) do
            local name, realm = strsplit("-", k)
            local i = UnitInRaid(k)
            if UnitIsVisible(name) or (i and select(3, GetRaidRosterInfo(i)) <= 4)  then
                return name, realm
            end
        end
    end
    return name -- Return input if nothing was found
end

-- Own NickName Change
function NSI:NickNameUpdated(nickname)
    local name, realm = UnitFullName("player")
    if not realm then
        realm = GetNormalizedRealmName()
    end
    local oldnick = NSRT.NickNames[name .. "-" .. realm]
    if (not oldnick) or oldnick ~= nickname then
        NSI:SendNickName("Any")
        NSI:NewNickName("player", nickname, name, realm)
    end
end

-- Grid2 Option Change
function NSI:Grid2NickNameUpdated(all, unit)
    if Grid2 then
        if all then
            for u in NSI:IterateGroupMembers() do
                Grid2Status:UpdateIndicators(u)
            end
        else
            for u in NSI:IterateGroupMembers() do -- if unit is in group refresh grid2 display, could be a guild message instead
                if unit then
                    if UnitExists(unit) and UnitIsUnit(u, unit) then
                        Grid2Status:UpdateIndicators(u)
                        break
                    end
                else
                    Grid2Status:UpdateIndicators(u)
                end    
            end
        end
     end
end

-- Wipe NickName Database
function NSI:WipeNickNames()
    NSI:WipeCellDB()
    NSRT.NickNames = {}
    fullCharList = {}
    fullNameList = {}
    sortedCharList = {}
    CharList = {}
    -- all addons that need a display update, which is basically all but WA
    NSI:UpdateNickNameDisplay(true)
end

function NSI:WipeCellDB()
    if CellDB then
        for name, nickname in pairs(NSRT.NickNames) do -- wipe cell database
            local i = tIndexOf(CellDB.nicknames.list, name..":"..nickname)
            if i then
                local charname = strsplit("-", name)
                Cell.Fire("UpdateNicknames", "list-update", name, charname)
                table.remove(CellDB.nicknames.list, i)
            end
        end
    end
end

function NSI:BlizzardNickNameUpdated()
    if C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames") and NSRT.Settings["Blizzard"] and not NSI.BlizzardNickNamesHook then
        NSI.BlizzardNickNamesHook = true
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            if frame:IsForbidden() or not frame.unit then
                return
            end
            frame.name:SetText(NSAPI:GetName(frame.unit, "Blizzard"))
        end)
    end
end

function NSI:MRTUpdateNoteDisplay(noteFrame)
    if 1 then return end -- disabling MRT Note nickname replacement for now as it is too laggy
    local note = noteFrame and noteFrame.text and noteFrame.text:GetText()
    if (not note) or (not NSRT.Settings["MRT"]) then return end
    if NSI.RawNoteFrame and note == NSI.RawNoteFrame and NSI.NewNoteFrame then -- don't recalculate nicknames if the note didn't change
        NSI.LastNoteUpdate = GetTime()
        noteFrame.text:SetText(NSI.NewNoteFrame)
        return
    end
    if NSI:EncounterCheck(true) then return end -- don't update note during encounters as this causes lag. This means it won't be functional if people are using Timers within the note but don't really have a great workaround for that
    NSI.RawNoteFrame = note
    local namelist = {}
    local colorlist = {}
    for name in note:gmatch("%S+") do -- finding all strings
        local charname = (UnitExists(name) or CharList[name] or fullNameList[name]) and NSAPI:Shorten(NSAPI:GetChar(name, true), false, false, "MRT") or name -- getting color coded nickname for this character
        if charname ~= name then
            namelist[name] = {name = charname, color = false}
        end
    end                
    for colorcode, name in note:gmatch(("|c(%x%x%x%x%x%x%x%x)(.-)|r")) do -- do the same for color coded strings again
        local charname = (UnitExists(name) and NSAPI:Shorten(NSAPI:GetChar(name, true), false, false, "MRT")) or name -- getting color coded nickname for this character
        if charname ~= name and not namelist[name] then
            namelist[name] = {name = charname, color = true}
        end
    end
    for notename, v in pairs(namelist) do
        note = note:gsub("(%f[%w])"..notename.."(%f[%W])", "%1"..v.name.."%2")
        if v.color then -- if initial name already had a colorcode, need to do different replacement
            note = note:gsub("|c%x%x%x%x%x%x%x%x"..notename.."|r", v.name)
        end
    end
    NSI.NewNoteFrame = note
    noteFrame.text:SetText(note)
end

function NSI:MRTNickNameUpdated(skipcheck)
    if C_AddOns.IsAddOnLoaded("MRT") then
        if skipcheck or NSRT.Settings["MRT"] then -- on init we only do this if the player has MRT Nicknames enabled, also whenever the setting changes we skip the setting check
            NSI:MRTUpdateNoteDisplay(MRTNote)
        end
        if NSRT.Settings["MRT"] and GMRT and GMRT.F and not NSI.MRTNickNamesHook then        
            NSI.MRTNickNamesHook = true
            GMRT.F:RegisterCallback(
                "RaidCooldowns_Bar_TextName",
                function(event, bar, data)
                    if data and data.name then
                        data.name = NSAPI:GetName(data.name, "MRT")
                    end
                end
            )
            GMRT.F:RegisterCallback(
                "Note_UpdateText", 
                function(event, noteFrame)
                    NSI:MRTUpdateNoteDisplay(noteFrame)
                end    
            )
        end
    end
end

function NSI:OmniCDNickNameUpdated()
    if NSRT.Settings["OmniCD"] and C_AddOns.IsAddOnLoaded("OmniCD") and not NSI.OmniCDNickNamesHook then
        NSI.OmniCDNickNamesHook = true
        -- Add OmniCD Hook
    end
end

-- Cell Option Change
function NSI:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname)
    if CellDB then
        if NSRT.Settings["Cell"] and NSRT.Settings["GlobalNickNames"] then
            if all then -- update all units
                for u in NSI:IterateGroupMembers() do
                    local name, realm = UnitFullName(u)
                    if not realm then
                        realm = GetNormalizedRealmName()
                    end
                    if NSRT.NickNames[name.."-"..realm] then
                        local nick = NSRT.NickNames[name.."-"..realm]
                        local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..nick)
                        if i then -- update nickame if it already exists
                            CellDB.nicknames.list[i] = name.."-"..realm..":"..nick
                            Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nick)
                        else -- insert if it doesn't exist yet
                            NSI:CellInsertName(name, realm, nick, true)
                        end
                    end
                end
                return
            elseif nickname == "" then -- newnick is an empty string so remove any old nick we still have
                if oldnick then -- if there is an oldnick, remove it 
                    local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..oldnick)
                    if i then
                        table.remove(CellDB.nicknames.list, i)
                        Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, name)
                    end
                end
            elseif unit then -- if the function was called for a sepcific unit
                local ingroup = false
                for u in NSI:IterateGroupMembers() do -- if unit is in group refresh cell display, could be a guild message instead
                    if UnitExists(unit) and UnitIsUnit(u, unit) then
                        ingroup = true
                        break
                    end
                end
                if oldnick then -- check if oldnick exists in database already and overwrite it if it does, otherwise insert
                    local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..oldnick)
                    if i then
                        CellDB.nicknames.list[i] = name.."-"..realm..":"..nickname
                        if ingroup then
                            Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nickname)
                        end
                    else
                        NSI:CellInsertName(name, realm, nickname, ingroup)
                    end
                else -- if no old nickname, just insert the new one
                    NSI:CellInsertName(name, realm, nickname, ingroup)
                end
            end
        else
            NSI:WipeCellDB()
        end
    end
end

function NSI:CellInsertName(name, realm, nickname, ingroup)
    if tInsertUnique(CellDB.nicknames.list, name.."-"..realm..":"..nickname) and ingroup then
        Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nickname)
    end
end



-- ElvUI Option Change
function NSI:ElvUINickNameUpdated()
    if ElvUF and ElvUF.Tags then
        ElvUF.Tags:RefreshMethods("NSNickName")
        for i=1, 12 do
            ElvUF.Tags:RefreshMethods("NSNickName:"..i)
        end
    end    
end

-- UUFG Option Change
function NSI:UnhaltedNickNameUpdated()
    if UUFG then
        UUFG:UpdateAllTags() 
    end    
end

function NSI:WeakAurasNickNameUpdated()
    if NSRT.Settings["WA"] and not C_AddOns.IsAddOnLoaded("CustomNames") then
        function WeakAuras.GetName(name)
            return NSAPI:GetName(name, "WA")
        end

        function WeakAuras.UnitName(unit)
            local _, realm = UnitName(unit)
            return NSAPI:GetName(unit, "WA"), realm
        end

        function WeakAuras.GetUnitName(unit, server)
            local name = NSAPI:GetName(unit, "WA")
            if server then
                local _, realm = UnitFullName(unit)
                if not realm then
                    realm = GetNormalizedRealmName()
                end
                name = name.."-"..realm
            end
            return name
        end

        function WeakAuras.UnitFullName(unit)
            local name, realm = UnitFullName(unit)
            return NSAPI:GetName(name, "WA"), realm
        end
    end
end

-- Global NickName Option Change
function NSI:GlobalNickNameUpdate()
    if NSRT.Settings["GlobalNickNames"] then
        for fullname, nickname in pairs(NSRT.NickNames) do
            local name, realm = strsplit("-", fullname)
            fullCharList[fullname] = nickname
            fullNameList[name] = nickname
            if not sortedCharList[nickname] then
                sortedCharList[nickname] = {}
            end
            sortedCharList[nickname][fullname] = true
            if not CharList[nickname] then
                CharList[nickname] = {}
            end
            CharList[nickname][name] = true
        end
        if NSRT.Settings["WA"] and not C_AddOns.IsAddOnLoaded("CustomNames") then
            function WeakAuras.GetName(name)
                return NSAPI:GetName(name, "WA")
            end

            function WeakAuras.UnitName(unit)
                local _, realm = UnitName(unit)
                return NSAPI:GetName(unit, "WA"), realm
            end

            function WeakAuras.GetUnitName(unit, server)
                local name = NSAPI:GetName(unit, "WA")
                if server then
                    local _, realm = UnitFullName(unit)
                    if not realm then
                        realm = GetNormalizedRealmName()
                    end
                    name = name.."-"..realm
                end
                return name
            end

            function WeakAuras.UnitFullName(unit)
                local name, realm = UnitFullName(unit)
                return NSAPI:GetName(name, "WA"), realm
            end
        end
    end
    
    -- instant display update for all addons
    NSI:UpdateNickNameDisplay(true)
end



function NSI:UpdateNickNameDisplay(all, unit, name, realm, oldnick, nickname)    
    NSI:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname) -- always have to do cell before doing any changes to the nickname database
    if nickname == ""  and NSRT.NickNames[name.."-"..realm] then
        NSRT.NickNames[name.."-"..realm] = nil
        fullCharList[name.."-"..realm] = nil
        fullNameList[name] = nil
        sortedCharList[nickname] = nil
        CharList[nickname] = nil
    end     
    NSI:Grid2NickNameUpdated(unit)
    NSI:ElvUINickNameUpdated()
    NSI:UnhaltedNickNameUpdated()
    NSI:BlizzardNickNameUpdated()
    NSI:MRTNickNameUpdated(true)
    NSI:OmniCDNickNameUpdated()
end

function NSI:InitNickNames()


    for fullname, nickname in pairs(NSRT.NickNames) do
        local name, realm = strsplit("-", fullname)
        fullCharList[fullname] = nickname
        fullNameList[name] = nickname
        if not sortedCharList[nickname] then
            sortedCharList[nickname] = {}
        end
        sortedCharList[nickname][fullname] = true
        if not CharList[nickname] then
            CharList[nickname] = {}
        end
        CharList[nickname][name] = true
    end

    if NSRT.Settings["GlobalNickNames"] then        

        if NSRT.Settings["WA"] and not C_AddOns.IsAddOnLoaded("CustomNames") then
            function WeakAuras.GetName(name)
                return NSAPI:GetName(name, "WA")
            end

            function WeakAuras.UnitName(unit)
                local _, realm = UnitName(unit)
                return NSAPI:GetName(unit, "WA"), realm
            end

            function WeakAuras.GetUnitName(unit, server)
                local name = NSAPI:GetName(unit, "WA")
                if server then
                    local _, realm = UnitFullName(unit)
                    if not realm then
                        realm = GetNormalizedRealmName()
                    end
                    name = name.."-"..realm
                end
                return name
            end

            function WeakAuras.UnitFullName(unit)
                local name, realm = UnitFullName(unit)
                return NSAPI:GetName(name, "WA"), realm
            end
        end

    	NSI:MRTNickNameUpdated(false)
    	NSI:BlizzardNickNameUpdated()
    	NSI:OmniCDNickNameUpdated()
    end

    if Grid2 then
        Grid2Status = Grid2.statusPrototype:new("NSNickName")

        Grid2Status.IsActive = Grid2.statusLibrary.IsActive

        function Grid2Status:UNIT_NAME_UPDATE(_, unit)
            self:UpdateIndicators(unit)
        end

        function Grid2Status:OnEnable()
            self:RegisterEvent("UNIT_NAME_UPDATE")
        end

        function Grid2Status:OnDisable()
            self:UnregisterEvent("UNIT_NAME_UPDATE")
        end

        function Grid2Status:GetText(unit)
            local name = UnitName(unit)
            return name and NSAPI and NSAPI:GetName(name, "Grid2") or name
        end

        local function Create(baseKey, dbx)
            Grid2:RegisterStatus(Grid2Status, {"text"}, baseKey, dbx)
            return Grid2Status
        end

        Grid2.setupFunc["NSNickName"] = Create

        Grid2:DbSetStatusDefaultValue( "NSNickName", {type = "NSNickName"})        
    end

    if ElvUF and ElvUF.Tags then
        ElvUF.Tags.Events['NSNickName'] = 'UNIT_NAME_UPDATE'
        ElvUF.Tags.Methods['NSNickName'] = function(unit)
            local name = UnitName(unit)
            return name and NSAPI and NSAPI:GetName(name, "ElvUI") or name
        end
        for i=1, 12 do
            ElvUF.Tags.Events['NSNickName:'..i] = 'UNIT_NAME_UPDATE'
            ElvUF.Tags.Methods['NSNickName:'..i] = function(unit)
                local name = UnitName(unit)
                name = name and NSAPI and NSAPI:GetName(name, "ElvUI") or name
                return WeakAuras.WA_Utf8Sub(name, i)
            end
        end
    end

    if CellDB and NSRT.Settings["Cell"] then
        for name, nickname in pairs(NSRT.NickNames) do
            if tInsertUnique(CellDB.nicknames.list, name..":"..nickname) then
                Cell.Fire("UpdateNicknames", "list-update", name, nickname)
            end
        end
    end
end

function NSI:SendNickName(channel, requestback)
    requestback = requestback or false
    local now = GetTime()
    if (NSI.LastNickNameSend and NSI.LastNickNameSend > now-0.25) or NSRT.Settings["ShareNickNames"] == 4 then return end -- don't let user spam nicknames
    if requestback and (NSI.LastNickNameSend and NSI.LastNickNameSend > now-2) or NSRT.Settings["ShareNickNames"] == 4 then return end -- don't overspam on forming raid
    NSI.LastNickNameSend = now
    local nickname = NSRT.Settings["MyNickName"]
    if (not nickname) or WeakAuras.CurrentEncounter then return end
    local name, realm = UnitFullName("player")
    if not realm then
        realm = GetNormalizedRealmName()
    end
    if nickname then
        if UnitInRaid("player") and (NSRT.Settings["ShareNickNames"] == 1 or NSRT.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "RAID") then
            NSI:Broadcast("NSI_NICKNAMES_COMMS", "RAID", nickname, name, realm, requestback, "RAID")
        end
        if (NSRT.Settings["ShareNickNames"] == 2 or NSRT.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "GUILD") then
            NSI:Broadcast("NSI_NICKNAMES_COMMS", "GUILD", nickname, name, realm, requestback, "GUILD") 
        end
    end
end

function NSI:NewNickName(unit, nickname, name, realm, channel)
    if WeakAuras.CurrentEncounter then return end
    if unit ~= "player" and NSRT.Settings["AcceptNickNames"] ~= 3 then
        if channel == "GUILD" and NSRT.Settings["AcceptNickNames"] ~= 2 then return end
        if channel == "RAID" and NSRT.Settings["AcceptNickNames"] ~= 1 then return end
    end
    if not nickname or not name or not realm then return end   
    local oldnick = NSRT.NickNames[name.."-"..realm]      
    if oldnick and oldnick == nickname then  return end -- stop early if we already have this exact nickname  
    if nickname == "" then
        NSI:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
        return
    end
    nickname = WeakAuras.WA_Utf8Sub(nickname, 12)
    NSRT.NickNames[name.."-"..realm] = nickname
    fullCharList[name.."-"..realm] = nickname
    fullNameList[name] = nickname
    if not sortedCharList[nickname] then
        sortedCharList[nickname] = {}
    end
    sortedCharList[nickname][name.."-"..realm] = true
    if not CharList[nickname] then
        CharList[nickname] = {}
    end
    CharList[nickname][name] = true
    if NSRT.Settings["GlobalNickNames"] then
        NSI:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
    end
end


function NSI:ImportNickNames(string) -- string format is charactername-realm:nickname;charactername-realm:nickname;...
    if string ~= "" then
        string = string.gsub(string, "%s+", "") -- remove all whitespaces
        for _, str in pairs({strsplit(";", string)}) do
            if str ~= "" then
                local namewithrealm, nickname = strsplit(":", str)
                if namewithrealm and nickname then
                    local name, realm = strsplit("-", namewithrealm)
                    local unit
                    if name and realm then
                        NSRT.NickNames[name.."-"..realm] = nickname
                    end
                else
                    error("Error parsing names: "..str, 1)
            
                end
            end
        end
        NSI:GlobalNickNameUpdate()
    end
end

function NSI:SyncNickNames()
    local now = GetTime()
    if (NSI.LastNickNameSync and NSI.LastNickNameSync > now-4) or (NSRT.Settings["NickNamesSyncSend"] == 3) then return end -- don't let user spam syncs / end early if set to none
    NSI.LastNickNameSync = now
    local channel = NSRT.Settings["NickNamesSyncSend"] == 1 and "RAID" or "GUILD"
    NSI:Broadcast("NSI_NICKNAMES_SYNC", channel, NSRT.NickNames, channel) -- channel is either GUILD or RAID
end

function NSI:SyncNickNamesAccept(nicknametable)
    for name, nickname in pairs(nicknametable) do
        NSRT.NickNames[name] = nickname
    end
    NSI:GlobalNickNameUpdate()
end

function NSI:AddNickName(name, realm, nickname) -- keeping the nickname empty acts as removing the nickname for that character
    if name and realm and nickname then
        local unit
        if UnitExists(name) then
            for u in NSI:IterateGroupMembers() do
                if UnitIsUnit(u, name) then
                    unit = u
                    break
                end
            end
        end
        NSI:NewNickName(unit, nickname, name, realm, channel)
    end
end