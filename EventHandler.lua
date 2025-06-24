local _, NSI = ... -- Internal namespace
local f = CreateFrame("Frame")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:EventHandler(e, true, false, ...)
end)

function NSI:EventHandler(e, wowevent, internal, ...) -- internal checks whether the event comes from addon comms. We don't want to allow blizzard events to be fired manually
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "NorthernSkyRaidTools" then
            if not NSRT then NSRT = {} end
            if not NSRT.NSUI then NSRT.NSUI = {scale = 1} end
            if not NSRT.NSUI.externals_anchor then NSRT.NSUI.externals_anchor = {} end
            -- if not NSRT.NSUI.main_frame then NSRT.NSUI.main_frame = {} end
            -- if not NSRT.NSUI.external_frame then NSRT.NSUI.external_frame = {} end
            if not NSRT.NickNames then NSRT.NickNames = {} end
            if not NSRT.Settings then NSRT.Settings = {} end
            NSRT.Settings["MyNickName"] = NSRT.Settings["MyNickName"] or nil
            NSRT.Settings["GlobalNickNames"] = NSRT.Settings["GlobalNickNames"] or false
            NSRT.Settings["Blizzard"] = NSRT.Settings["Blizzard"] or false
            NSRT.Settings["WA"] = NSRT.Settings["WA"] or false
            NSRT.Settings["MRT"] = NSRT.Settings["MRT"] or false
            NSRT.Settings["Cell"] = NSRT.Settings["Cell"] or false
            NSRT.Settings["Grid2"] = NSRT.Settings["Grid2"] or false
            NSRT.Settings["OmniCD"] = NSRT.Settings["OmniCD"] or false
            NSRT.Settings["ElvUI"] = NSRT.Settings["ElvUI"] or false
            NSRT.Settings["SuF"] = NSRT.Settings["SuF"] or false
            NSRT.Settings["Translit"] = NSRT.Settings["Translit"] or false
            NSRT.Settings["Unhalted"] = NSRT.Settings["Unhalted"] or false
            NSRT.Settings["ShareNickNames"] = NSRT.Settings["ShareNickNames"] or 4 -- none default
            NSRT.Settings["AcceptNickNames"] = NSRT.Settings["AcceptNickNames"] or 4 -- none default
            NSRT.Settings["NickNamesSyncAccept"] = NSRT.Settings["NickNamesSyncAccept"] or 2 -- guild default
            NSRT.Settings["NickNamesSyncSend"] = NSRT.Settings["NickNamesSyncSend"] or 3 -- guild default
            NSRT.Settings["WeakAurasImportAccept"] = NSRT.Settings["WeakAurasImportAccept"] or 1 -- guild default
            NSRT.Settings["PAExtraAction"] = NSRT.Settings["PAExtraAction"] or false
            NSRT.Settings["LIQUID_MACRO"] = NSRT.Settings["LIQUID_MACRO"] or false
            NSRT.Settings["PASelfPing"] = NSRT.Settings["PASelfPing"] or false
            NSRT.Settings["ExternalSelfPing"] = NSRT.Settings["ExternalSelfPing"] or false
            NSRT.Settings["MRTNoteComparison"] = NSRT.Settings["MRTNoteComparison"] or false
            NSRT.Settings["TTS"] = NSRT.Settings["TTS"] or true
            NSRT.Settings["TTSVolume"] = NSRT.Settings["TTSVolume"] or 50
            NSRT.Settings["TTSVoice"] = NSRT.Settings["TTSVoice"] or 2
            NSRT.Settings["Minimap"] = NSRT.Settings["Minimap"] or {hide = false}
            NSRT.Settings["VersionCheckRemoveResponse"] = NSRT.Settings["VersionCheckRemoveResponse"] or false
            NSRT.Settings["Debug"] = NSRT.Settings["Debug"] or false
            NSRT.Settings["DebugLogs"] = NSRT.Settings["DebugLogs"] or false
            NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or {}
            NSRT.NSUI.AutoComplete = NSRT.NSUI.AutoComplete or {}
            NSRT.NSUI.AutoComplete["WA"] = NSRT.NSUI.AutoComplete["WA"] or {}
            NSRT.NSUI.AutoComplete["Addon"] = NSRT.NSUI.AutoComplete["Addon"] or {}

            NSI.BlizzardNickNamesHook = false
            NSI.MRTNickNamesHook = false
            NSI.OmniCDNickNamesHook = false 
            NSI:InitNickNames()
        end
    elseif e == "PLAYER_LOGIN" and wowevent then
        local pafound = false
        local extfound = false
        local innervatefound = false
        local macrocount = 0    
        for i=1, 120 do
            local macroname = C_Macro.GetMacroName(i)
            if not macroname then break end
            macrocount = i
            if macroname == "NS PA Macro" then
                local macrotext = "/run NSAPI:PrivateAura();"
                if NSRT.Settings["PASelfPing"] then
                    macrotext = macrotext.."\n/ping [@player] Warning;"
                end
                if NSRT.Settings["PAExtraAction"] then
                    macrotext = macrotext.."\n/click ExtraActionButton1"
                end
                EditMacro(i, "NS PA Macro", 132288, macrotext, false)
                pafound = true
            elseif macroname == "NS Ext Macro" then
                local macrotext = NSRT.Settings["ExternalSelfPing"] and "/run NSAPI:ExternalRequest();\n/ping [@player] Assist;" or "/run NSAPI:ExternalRequest();"
                EditMacro(i, "NS Ext Macro", 135966, macrotext, false)
                extfound = true
            elseif macroname == "NS Innervate" then
                EditMacro(i, "NS Innervate", 136048, "/run NSAPI:InnervateRequest();", false)
                innervatefound = true
            end
            if pafound and extfound and innervatefound then break end
        end
        if macrocount >= 120 and not pafound then
            print("You reached the global Macro cap so the Private Aura Macro could not be created")
        elseif not pafound then
            macrocount = macrocount+1            
            local macrotext = "/run NSAPI:PrivateAura();"
            if NSRT.Settings["PASelfPing"] then
                macrotext = macrotext.."\n/ping [@player] Warning;"
            end
            if NSRT.Settings["PAExtraAction"] then
                macrotext = macrotext.."\n/click ExtraActionButton1"
            end
            if NSRT.Settings["LIQUID_MACRO"] then
                macrotext = macrotext.."\n/run WeakAuras.ScanEvents(\"LIQUID_PRIVATE_AURA_MACRO\", true)"
            end
            CreateMacro("NS PA Macro", 132288, macrotext, false)
        end
        if macrocount >= 120 and not extfound then 
            print("You reached the global Macro cap so the External Macro could not be created")
        elseif not extfound then
            macrocount = macrocount+1
            local macrotext = NSRT.Settings["ExternalSelfPing"] and "/run NSAPI:ExternalRequest();\n/ping [@player] Assist;" or "/run NSAPI:ExternalRequest();"
            CreateMacro("NS Ext Macro", 135966, macrotext, false)
        end
        if macrocount >= 120 and not inenrvatefound then
            print("You reached the global Macro cap so the Innervate Macro could not be created")
        elseif not innervatefound then
            macrocount = macrocount+1
            CreateMacro("NS Innervate", 136048, "/run NSAPI:InnervateRequest();", false)
        end
        if NSRT.Settings["MyNickName"] then NSI:SendNickName("Any") end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname
        if NSRT.Settings["GlobalNickNames"] then -- add own nickname if not already in database (for new characters)
            local name, realm = UnitName("player")
            if not realm then
                realm = GetNormalizedRealmName()
            end
            if (not NSRT.NickNames[name.."-"..realm]) or (NSRT.Settings["MyNickName"] ~= NSRT.NickNames[name.."-"..realm]) then
                NSI:NewNickName("player", NSRT.Settings["MyNickName"], name, realm)
            end
        end
        NSI.NSUI:Init()
        NSI:InitLDB()
        if WeakAuras.GetData("Northern Sky Externals") then
            print("lease uninstall the |cFF00FFFFPNorthern Sky Externals Weakaura|r to prevent conflicts with the Northern Sky Raid Tools Addon.")
        end
        if C_AddOns.IsAddOnLoaded("NorthernSkyMedia") then
            print("Please uninstall the |cFF00FFFFPNorthern Sky Media Addon|r as this new Addon takes over all its functionality")
        end
    elseif e == "READY_CHECK" and (wowevent or NSRT.Settings["Debug"]) then
        if WeakAuras.CurrentEncounter then return end
        if NSI:Difficultycheck() or NSRT.Settings["Debug"] then -- only care about note comparison in normal, heroic&mythic raid
            local hashed = C_AddOns.IsAddOnLoaded("MRT") and NSAPI:GetHash(NSAPI:GetNote()) or ""     
            NSI:Broadcast("MRT_NOTE", "RAID", hashed)   
        end
    elseif e == "GROUP_FORMED" and (wowevent or NSRT.Settings["Debug"]) then 
        if WeakAuras.CurrentEncounter then return end
        if NSRT.Settings["MyNickName"] then NSI:SendNickName("Any", true) end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname

    elseif e == "MRT_NOTE" and NSRT.Settings["MRTNoteComparison"] and (internal or NSRT.Settings["Debug"]) then
        if WeakAuras.CurrentEncounter then return end
        local _, hashed = ...     
        if hashed ~= "" then
            local note = C_AddOns.IsAddOnLoaded("MRT") and NSAPI:GetHash(NSAPI:GetNote()) or ""    
            if note ~= "" and note ~= hashed then
                NSAPI:DisplayText("MRT Note Mismatch detected", 5)
            end
        end
    elseif e == "UNIT_AURA" and (NSI.Externals and NSI.Externals.target) and ((UnitIsUnit(NSI.Externals.target, "player") and wowevent) or NSRT.Settings["Debug"]) then
        local unit, info = ...
        if not NSI.Externals.AllowedUnits[unit] then return end
        if info and info.addedAuras then
            for _, v in ipairs(info.addedAuras) do
                if NSI.Externals.Automated[v.spellId] then
                    local key = NSI.Externals.Automated[v.spellId]
                    local num = (key and NSI.Externals.Amount[key..v.spellId])
                    NSI:EventHandler("NS_EXTERNAL_REQ", false, true, unit, key, num, false, "skip", v.expirationTime)
                end
            end
        end
    elseif e == "NSI_VERSION_CHECK" and (internal or NSRT.Settings["Debug"]) then
        if WeakAuras.CurrentEncounter then return end
        local unit, ver, duplicate = ...        
        NSI:VersionResponse({name = UnitName(unit), version = ver, duplicate = duplicate})
    elseif e == "NSI_VERSION_REQUEST" and (internal or NSRT.Settings["Debug"]) then
        if WeakAuras.CurrentEncounter then return end
        local unit, type, name = ...        
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't send to yourself
        if UnitExists(unit) and (UnitIsGroupLeader(unit) or UnitIsGroupAssistant(unit)) then
            local u, ver, duplicate = NSI:GetVersionNumber(type, name, unit)
            NSI:Broadcast("NSI_VERSION_CHECK", "WHISPER", unit, ver, duplicate)
        end
    elseif e == "NSI_NICKNAMES_COMMS" and (internal or NSRT.Settings["Debug"]) then
        if WeakAuras.CurrentEncounter then return end
        local unit, nickname, name, realm, requestback, channel = ...
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't add new nickname if it's yourself because already adding it to the database when you edit it
        if requestback and (UnitInRaid(unit) or UnitInParty(unit)) then NSI:SendNickName(channel, false) end -- send nickname back to the person who requested it
        NSI:NewNickName(unit, nickname, name, realm, channel)

    elseif e == "PLAYER_REGEN_ENABLED" and (wowevent or NSRT.Settings["Debug"]) then
        C_Timer.After(1, function()
            if NSI.SyncNickNamesStore then
                NSI:EventHandler("NSI_NICKNAMES_SYNC", false, true, NSI.SyncNickNamesStore.unit, NSI.SyncNickNamesStore.nicknametable, NSI.SyncNickNamesStore.channel)
                NSI.SyncNickNamesStore = nil
            end
            if NSI.WAString and NSI.WAString.unit and NSI.WAString.string then
                NSI:EventHandler("NSI_WA_SYNC", false, true, NSI.WAString.unit, NSI.WAString.string)
                NSI.WAString = nil
            end
        end)
    elseif e == "NSI_NICKNAMES_SYNC" and (internal or NSRT.Settings["Debug"]) then
        local unit, nicknametable, channel = ...
        local setting = NSRT.Settings["NickNamesSyncAccept"]
        if (setting == 3 or (setting == 2 and channel == "GUILD") or (setting == 1 and channel == "RAID") and (not C_ChallengeMode.IsChallengeModeActive())) then 
            if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't accept sync requests from yourself
            if UnitAffectingCombat("player") or WeakAuras.CurrentEncounter then
                NSI.SyncNickNamesStore = {unit = unit, nicknametable = nicknametable, channel = channel}
            else
                NSI:NickNamesSyncPopup(unit, nicknametable)    
            end
        end
    elseif e == "NSI_WA_SYNC" and (internal or NSRT.Settings["Debug"]) then
        local unit, str = ...
        local setting = NSRT.Settings["WeakAurasImportAccept"]
        if setting == 3 then return end
        if UnitExists(unit) and not UnitIsUnit("player", unit) then
            if setting == 2 or (GetGuildInfo(unit) == GetGuildInfo("player")) then -- only accept this from same guild to prevent abuse
                if UnitAffectingCombat("player") or WeakAuras.CurrentEncounter then
                    NSI.WAString = {unit = unit, string = str}
                else
                    NSI:WAImportPopup(unit, str)
                end
            end
        end

    elseif e == "NSAPI_SPEC" then -- Should technically rename to "NSI_SPEC" but need to keep this open for the global broadcast to be compatible with the database WA
        local unit, spec = ...
        NSI.specs = NSI.specs or {}
        NSI.specs[unit] = tonumber(spec)
    elseif e == "NSAPI_SPEC_REQUEST" then
        local specid = GetSpecializationInfo(GetSpecialization())
        NSAPI:Broadcast("NSAPI_SPEC", "RAID", specid)    
    elseif e == "ENCOUNTER_START" and ((wowevent and NSI:Difficultycheck()) or NSRT.Settings["Debug"]) then -- allow sending fake encounter_start if in debug mode, only send spec info in mythic, heroic and normal raids
        NSI.specs = {}
        for u in NSI:IterateGroupMembers() do
            if UnitIsVisible(u) then
                NSI.specs[u] = WeakAuras.SpecForUnit(u)
            end
        end
        -- broadcast spec info
        local specid = GetSpecializationInfo(GetSpecialization())
        NSAPI:Broadcast("NSAPI_SPEC", "RAID", specid)
        C_Timer.After(0.5, function()
            WeakAuras.ScanEvents("NSAPI_ENCOUNTER_START", true)
        end)
        NSI.MacroPresses = {}
        NSI.Externals:Init()
    elseif e == "ENCOUNTER_END" and ((wowevent and NSI:Difficultycheck()) or NSRT.Settings["Debug"]) then
        local _, encounterName = ...
        if NSRT.Settings["DebugLogs"] then
            if NSI.MacroPresses and next(NSI.MacroPresses) then NSI:Print("Macro Data for Encounter: "..encounterName, NSI.MacroPresses) end
            if NSI.AssignedExternals and next(NSI.AssignedExternals) then NSI:Print("Assigned Externals for Encounter: "..encounterName, NSI.AssignedExternals) end
            NSI.AssignedExternals = {}
            NSI.MacroPresses = {}
        end        
        C_Timer.After(1, function()
            if NSI.SyncNickNamesStore then
                NSI:EventHandler("NSI_NICKNAMES_SYNC", false, true, NSI.SyncNickNamesStore.unit, NSI.SyncNickNamesStore.nicknametable, NSI.SyncNickNamesStore.channel)
                NSI.SyncNickNamesStore = nil
            end
            if NSI.WAString and NSI.WAString.unit and NSI.WAString.string then
                NSI:EventHandler("NSI_WA_SYNC", false, true, NSI.WAString.unit, NSI.WAString.string)
            end
        end)
    elseif e == "NS_EXTERNAL_REQ" and ... and UnitIsUnit(NSI.Externals.target, "player") then -- only accept scanevent if you are the "server"
        local unitID, key, num, req, range, expirationTime = ...
        local dead = NSAPI:DeathCheck(unitID)        
        NSI.MacroPresses = NSI.MacroPresses or {}
        NSI.MacroPresses["Externals"] = NSI.MacroPresses["Externals"] or {}
        local formattedrange = {}
        if type(range) == "table" then
            for k, v in pairs(range) do
                formattedrange[v.name] = v.range 
            end
        else
            formattedrange = range
        end
        table.insert(NSI.MacroPresses["Externals"], {unit = NSAPI:Shorten(unitID, 8), time = Round(GetTime()-NSI.Externals.pull), dead = dead, key = key, num = num, automated = not req, rangetable = formattedrange})
        if NSI:Difficultycheck(true) and not dead then -- block incoming requests from dead people
            NSI.Externals:Request(unitID, key, num, req, range, false, expirationTime)
        end
    elseif e == "NS_INNERVATE_REQ" and ... and UnitIsUnit(NSI.Externals.target, "player") then -- only accept scanevent if you are the "server"
        local unitID, key, num, req, range, expirationTime = ...
        local dead = NSAPI:DeathCheck(unitID)      
        NSI.MacroPresses = NSI.MacroPresses or {}
        NSI.MacroPresses["Innervate"] = NSI.MacroPresses["Innervate"] or {}
        local formattedrange = {}
        if type(range) == "table" then
            for k, v in pairs(range) do
                formattedrange[v.name] = v.range 
            end
        else
            formattedrange = range
        end
        table.insert(NSI.MacroPresses["Innervate"], {unit = NSAPI:Shorten(unitID, 8), time = Round(GetTime()-NSI.Externals.pull), dead = dead, key = key, num = num, rangetable = formattedrange})
        if NSI:Difficultycheck(true) and not dead then -- block incoming requests from dead people
            NSI.Externals:Request(unitID, "", 1, true, range, true, expirationTime)
        end
    elseif e == "NS_EXTERNAL_YES" and ... then
        local _, unit, spellID = ...
        NSI:DisplayExternal(spellID, unit)
    elseif e == "NS_EXTERNAL_NO" then        
        local unit, innervate = ...      
        if innervate == "Innervate" then
            NSI:DisplayExternal("NoInnervate")
        else
            NSI:DisplayExternal()
        end
    elseif e == "NS_EXTERNAL_GIVE" and ... then
        local _, unit, spellID = ...
        local hyperlink = C_Spell.GetSpellLink(spellID)
        WeakAuras.ScanEvents("CHAT_MSG_WHISPER", hyperlink, unit)
    elseif e == "NS_PAMACRO" and (internal or NSRT.Settings["Debug"]) then
        local unitID = ...
        if unitID and UnitExists(unitID) and NSRT.Settings["DebugLogs"] then
            NSI.MacroPresses = NSI.MacroPresses or {}
            NSI.MacroPresses["Private Aura"] = NSI.MacroPresses["Private Aura"] or {}
            table.insert(NSI.MacroPresses["Private Aura"], {name = NSAPI:Shorten(unitID, 8), time = Round(GetTime()-NSI.Externals.pull)})
        end
    end
end


--[[ add debug config
elseif e == "NSAPI_MACRO_RECEIVE" and aura_env.config.debug then
local unit = ...
local cname = NSAPI:Shorten(unit, 8)
print(cname, "pressed Macro")
DebugPrint(cname, "pressed Macro", GetTime())
-- WeakAuras.ScanEvents("NS_MACRO_RECEIVE", unit) add this to another aura    ]]

    --[[ add custom option for this
elseif e == "MRT_NOTE_UPDATE" then
    if aura_env.config.mrtcheck and ((not aura_env.last) or aura_env.last < GetTime()-1) and VMRT.Note.Text1 and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and not WeakAuras.CurrentEncounter then -- cap at max once per second because MRT sends this event multiple times on large notes. Also only check if you are group leader or assist
        local diff = select(3, GetInstanceInfo()) or 0
        if diff == 16 then -- Mythic only
            aura_env.last = GetTime()
            C_Timer.After(1, function() -- doing this delayed because the note is sent in multiple batches so need to wait until the entire note is there
                WeakAuras.ScanEvents("NSAPI_MRT_NOTE_CHECK", true)
            end)
        end
    end]]
    --[[
        elseif e == "NSAPI_MRT_NOTE_CHECK" and ... then
            local text = _G.VMRT.Note.Text1
            local list = false
            local startline = ""
            for line in text:gmatch('[^\r\n]+') do
                line = strtrim(line) --trim whitespace
                --check for start/end of the name list
                local charlist = {}
                local missing = {}
                local count = 0
                if string.match(line, "ns.*start") or line == "intstart" then -- match any string that starts with "ns" and ends with "start" as well as the interrupt WA
                    charlist = {}
                    missing = {}
                    count = 0
                    list = true
                    startline = line
                elseif string.match(line, "ns.*end") or line == "intend" then
                    list = false
                    local endline = line
                    if #missing >= 1 then
                        print("|cffff4040The following players between the lines |r|cff3ffc3f'"..startline.."'|r|cffff4040 and |r'|cff3ffc3f"..endline.."'|r |cffff4040are in the note but not in the raid:|r")
                        local s = ""
                        for _, v in ipairs(missing) do
                            s = s..v.." "
                        end
                        print(s)
                        local t = ""
                        for unit in WA_IterateGroupMembers() do
                            local i = UnitInRaid(unit)
                            if select(3, GetRaidRosterInfo(i)) <= 4 and not charlist[unit] then
                                if startline == "nsdispelstart" then -- only consider healers for the default dispel naming convention
                                    if UnitGroupRolesAssigned(unit) == "HEALER" then
                                        t = t..WA_ClassColorName(UnitName(unit)).." "
                                    end
                                else
                                    t = t..WA_ClassColorName(UnitName(unit)).." "
                                end
                            end
                        end
                        if t ~= "" then
                            print("|cff409fffThe following players are missing from this note:|r")
                            print(t)
                        end
                    end
                end
                if list then
                    line = line:gsub("{.-}", "") -- cleaning markers from line
                    for name in line:gmatch("%S+") do -- finding all remaining strings
                        local name2 = name:gsub("||r", "") -- clean colorcode
                        name2 = name2:gsub("||c%x%x%x%x%x%x%x%x", "") -- clean colorcode
                            name2 = NSAPI:GetChar(name2, true) -- first converts from character name to nickname and then back to a character name that's actually in the raid. This allows checking for any character of the player
                        local i = UnitInRaid(name2)
                        if i and select(3, GetRaidRosterInfo(i)) <= 4 then
                            charlist["raid"..i] = true
                        elseif name2 ~= name and not tIndexOf(missing, name2) then -- only check if string was color coded, this should ensure we're not counting things that aren't actually character names
                            name = name:gsub("||r", "") -- clean colorcode
                            name = name:gsub("||c%x%x%x%x%x%x%x%x", "") -- clean colorcode
                            table.insert(missing, name)
                        end
                    end
                end
            end
        end]]