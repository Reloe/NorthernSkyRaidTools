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
    if (not str) or issecretvalue(str) then return str end
    local unitname = UnitExists(str) and UnitName(str) or str
    if issecretvalue(unitname) then return unitname end
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
        if (issecretvalue(name) or issecretvalue(realm)) then return name end
        local nickname = name and realm and fullCharList[name.."-"..realm]
        if nickname and NSRT.Settings["Translit"] then
            nickname = LibTranslit:Transliterate(nickname)
        end
        if NSRT.Settings["Translit"] and not nickname then
            name = issecretvalue(name) and name or LibTranslit:Transliterate(name)
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
    if UnitExists(name) and UnitIsConnected(name) then return name end
    name = nick and NSAPI:GetName(name, AddonName) or name
    if UnitExists(name) and UnitIsConnected(name) then return name end
    local chars = NSAPI:GetCharacters(name)
    local newname, newrealm = nil
    if chars then
        for k, _ in pairs(chars) do
            local name, realm = strsplit("-", k)
            local i = UnitInRaid(k)
            if UnitIsVisible(name) or (i and select(3, GetRaidRosterInfo(i)) <= 4)  then
                newname, newrealm = name, realm
                if UnitIsUnit(name, "player") then
                    return name, realm
                end
            end
        end
        if newname and newrealm then
            return newname, newrealm
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
        self:SendNickName("Any")
        self:NewNickName("player", nickname, name, realm)
    end
end

-- Grid2 Option Change
function NSI:Grid2NickNameUpdated(all, unit)
    if Grid2 then
        if all then
            for u in self:IterateGroupMembers() do
                Grid2Status:UpdateIndicators(u)
            end
        else
            for u in self:IterateGroupMembers() do -- if unit is in group refresh grid2 display, could be a guild message instead
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

function NSI:DandersFramesNickNameUpdated(all, unit)
    if DandersFrames then
        if all then
            DandersFrames:IterateCompactFrames(function(frame)
                DandersFrames:UpdateNameText(frame)
            end)
        elseif unit then
            local frame = DandersFrames:GetFrameForUnit(unit)
            if frame then
                DandersFrames:UpdateNameText(frame)
            end
        end
    end
end

-- Wipe NickName Database
function NSI:WipeNickNames()
    self:WipeCellDB()
    NSRT.NickNames = {}
    fullCharList = {}
    fullNameList = {}
    sortedCharList = {}
    CharList = {}
    -- all addons that need a display update, which is basically all but
    self:UpdateNickNameDisplay(true)
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

function NSI:VuhDoNickNameUpdated()
    if C_AddOns.IsAddOnLoaded("VuhDo") and NSRT.Settings["VuhDo"] and not self.VuhDoNickNamesHook then
        self.VuhDoNickNamesHook = true
        local hookedFrames = {}
        hooksecurefunc('VUHDO_getBarText', function(aBar)
            local bar = aBar:GetName() .. 'TxPnlUnN'
            if bar then
                if not hookedFrames[bar] then
                    hookedFrames[bar] = true
                    hooksecurefunc(_G[bar], 'SetText', function(self,txt)
                        if txt then
                            local name = txt:match('%w+$')
                            if name then
                                local preStr = txt:gsub(name, '')
                                self:SetFormattedText('%s%s',preStr,NSAPI:GetName(name, "VuhDo") or "")
                            end
                        end
                    end)
                end
            end
        end)
    end

end

function NSI:BlizzardNickNameUpdated()
    C_Timer.After(0.1, function() -- delay everything to always do it after other reskin addons
        if C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames") and NSRT.Settings["Blizzard"] and not self.BlizzardNickNamesHook then
            self.BlizzardNickNamesHook = true
            hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
                if frame:IsForbidden() or not frame.unit then
                    return
                end
                frame.name:SetText(NSAPI:GetName(frame.unit, "Blizzard"))
            end)
        end
        local inRaid = UnitInRaid("player")
        if inRaid then
            for group = 1, 8 do
                for member = 1, 5 do
                    local frame = _G["CompactRaidGroup"..group.."Member"..member]
                    if frame and not frame:IsForbidden() and frame.unit then
                        frame.name:SetText(NSAPI:GetName(frame.unit, "Blizzard"))
                    end
                end
            end
        else
            for member = 1, 5 do
                local frame = _G["CompactPartyFrameMember"..member]
                if frame and not frame:IsForbidden() and frame.unit then
                    frame.name:SetText(NSAPI:GetName(frame.unit, "Blizzard"))
                end
            end
        end
    end)
end

-- Cell Option Change
function NSI:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname)
    if CellDB then
        if NSRT.Settings["Cell"] and NSRT.Settings["GlobalNickNames"] then
            if all then -- update all units
                for u in self:IterateGroupMembers() do
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
                            self:CellInsertName(name, realm, nick, true)
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
                for u in self:IterateGroupMembers() do -- if unit is in group refresh cell display, could be a guild message instead
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
                        self:CellInsertName(name, realm, nickname, ingroup)
                    end
                else -- if no old nickname, just insert the new one
                    self:CellInsertName(name, realm, nickname, ingroup)
                end
            end
        else
            self:WipeCellDB()
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
    if UUFG and UUFG.UpdateAllTags then
        UUFG:UpdateAllTags()
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
    end

    -- instant display update for all addons
    self:UpdateNickNameDisplay(true)
end



function NSI:UpdateNickNameDisplay(all, unit, name, realm, oldnick, nickname)
    self:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname) -- always have to do cell before doing any changes to the nickname database
    if nickname == ""  and NSRT.NickNames[name.."-"..realm] then
        NSRT.NickNames[name.."-"..realm] = nil
        fullCharList[name.."-"..realm] = nil
        fullNameList[name] = nil
        sortedCharList[nickname] = nil
        CharList[nickname] = nil
    end
    self:Grid2NickNameUpdated(unit)
    self:ElvUINickNameUpdated()
    self:UnhaltedNickNameUpdated()
    self:BlizzardNickNameUpdated()
    self:DandersFramesNickNameUpdated(all, unit)
    self:VuhDoNickNameUpdated()
    self.Callbacks:Fire("NSRT_NICKNAME_UPDATED", all, unit, name, realm, oldnick, nickname)
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

    if NSRT.Settings["GlobalNickNames"] and NSRT.Settings["Blizzard"] then
    	self:BlizzardNickNameUpdated()
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
            return name and NSAPI:GetName(name, "Grid2") or name
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
            return name and NSAPI:GetName(name, "ElvUI") or name
        end
        for i=1, 12 do
            ElvUF.Tags.Events['NSNickName:'..i] = 'UNIT_NAME_UPDATE'
            ElvUF.Tags.Methods['NSNickName:'..i] = function(unit)
                local name = UnitName(unit)
                name = name and NSAPI:GetName(name, "ElvUI") or name
                return NSI:Utf8Sub(name, 1, i)
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

    if DandersFrames then
        function DandersFrames:GetUnitName(unit)
            local name = UnitName(unit)
            return name and NSAPI:GetName(name, "DandersFrames") or name
        end
    end

    C_AddOns.LoadAddOn("UnhaltedUnitFrames")
    if UUFG then
        UUFG:AddTag("NSNickName", "UNIT_NAME_UPDATE", function(unit)
            local name = UnitName(unit)
            return name and NSAPI:GetName(name, "Unhalted") or name
        end, "Name", "[NSRT] NickName")
    end

    C_AddOns.LoadAddOn("VuhDo")
    self:VuhDoNickNameUpdated()
end

function NSI:SendNickName(channel, requestback)
    requestback = requestback or false
    local now = GetTime()
    if (self.LastNickNameSend and self.LastNickNameSend > now-0.25) or NSRT.Settings["ShareNickNames"] == 4 then return end -- don't let user spam nicknames
    if requestback and (self.LastNickNameSend and self.LastNickNameSend > now-2) or NSRT.Settings["ShareNickNames"] == 4 then return end -- don't overspam on forming raid
    self.LastNickNameSend = now
    local nickname = NSRT.Settings["MyNickName"]
    if (not nickname) or self:Restricted() then return end
    local name, realm = UnitFullName("player")
    if not realm then
        realm = GetNormalizedRealmName()
    end
    if nickname then
        if UnitInRaid("player") and (NSRT.Settings["ShareNickNames"] == 1 or NSRT.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "RAID") then
            self:Broadcast("NSI_NICKNAMES_COMMS", "RAID", nickname, name, realm, requestback, "RAID")
        end
        if (NSRT.Settings["ShareNickNames"] == 2 or NSRT.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "GUILD") then
            self:Broadcast("NSI_NICKNAMES_COMMS", "GUILD", nickname, name, realm, requestback, "GUILD")
        end
    end
end

function NSI:NewNickName(unit, nickname, name, realm, channel)
    if self:Restricted() then return end
    if unit ~= "player" and NSRT.Settings["AcceptNickNames"] ~= 3 then
        if channel == "GUILD" and NSRT.Settings["AcceptNickNames"] ~= 2 then return end
        if channel == "RAID" and NSRT.Settings["AcceptNickNames"] ~= 1 then return end
    end
    if not nickname or not name or not realm then return end
    local oldnick = NSRT.NickNames[name.."-"..realm]
    if oldnick and oldnick == nickname then  return end -- stop early if we already have this exact nickname
    if nickname == "" then
        self:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
        return
    end
    nickname = self:Utf8Sub(nickname, 1, 12)
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
        self:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
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
        self:GlobalNickNameUpdate()
    end
end

function NSI:SyncNickNames()
    local now = GetTime()
    if (self.LastNickNameSync and self.LastNickNameSync > now-4) or (NSRT.Settings["NickNamesSyncSend"] == 3) then return end -- don't let user spam syncs / end early if set to none
    self.LastNickNameSync = now
    local channel = NSRT.Settings["NickNamesSyncSend"] == 1 and "RAID" or "GUILD"
    self:Broadcast("NSI_NICKNAMES_SYNC", channel, NSRT.NickNames, channel) -- channel is either GUILD or RAID
end

function NSI:SyncNickNamesAccept(nicknametable)
    for name, nickname in pairs(nicknametable) do
        NSRT.NickNames[name] = nickname
    end
    self:GlobalNickNameUpdate()
end

function NSI:AddNickName(name, realm, nickname) -- keeping the nickname empty acts as removing the nickname for that character
    if name and realm and nickname then
        local unit
        if UnitExists(name) then
            for u in self:IterateGroupMembers() do
                if UnitIsUnit(u, name) then
                    unit = u
                    break
                end
            end
        end
        self:NewNickName(unit, nickname, name, realm, channel)
    end
end
