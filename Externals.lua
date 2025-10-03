local _, NSI = ... -- Internal namespace
-- Todo
-- Add self cd's to allspells to possibly check those being available before externals are automatically assigned


local lib = LibStub:GetLibrary("LibOpenRaid-1.0")
NSI.Externals = {}
NSI.Externals.ready = {}
NSI.Externals.known = {}
NSI.Externals.pull = 0
NSI.Externals.requested = {}
NSI.Externals.Automated = {}
NSI.Externals.Amount = {}
NSI.Externals.target = ""
NSI.Externals.customprio = {}
NSI.Externals.customspellprio = {}
NSI.Externals.Cooldown = {}
NSI.AssignedExternals = {}
NSI.Externals.AllowedUnits = {}
for i=1, 40 do
    NSI.Externals.AllowedUnits["raid"..i] = true
end
local Sac = 6940
local Bop = 1022
local Spellbop = 204018
local Painsup = 33206
local GS1 = 47788
local GS2 = 255312
local Bark = 102342
local Cocoon = 116849
local TD = 357170
local LoH = 633
local Bubble = 642
local Block = 45438
local Turtle = 186265
local Netherwalk = 196555
local Cloak = 31224
local Icebound = 48792
local Innervate = 29166
local Dispersion = 47585

NSI.Externals.NameToID = {
    ["Sac"]        = 6940,
    ["Bop"]        = 1022,
    ["Spellbop"]   = 204018,
    ["Painsup"]    = 33206,
    ["GS1"]        = 47788,
    ["GS2"]        = 255312,
    ["Bark"]       = 102342,
    ["Cocoon"]     = 116849,
    ["TD"]         = 357170,
    ["LoH"]        = 633,
    ["Bubble"]     = 642,
    ["Block"]      = 45438,
    ["Turtle"]     = 186265,
    ["Netherwalk"] = 196555,
    ["Cloak"]      = 31224,
    ["Icebound"]   = 48792,
    ["Innervate"]  = 29166,
    ["Dispersion"]  = 47585,
}

NSI.Externals.prio = {
    -- Life Cocoon, Time Dilation, Pain Suppression, Ironbark, Sac, Guardian  Spiritx2, Lay on Hands
    ["default"] = {Cocoon, TD, Painsup, Bark, Sac, GS1, GS2, LoH},
    ["DoubleWhammy"] = {Cocoon, TD, Painsup, Bark, GS1, GS2, Sac}, -- Life Cocoon first as it's a one-time dmg event
    ["MugzeeFrontal"] = {Sac, Bark, TD, Painsup, GS1, GS2, LoH, Cocoon}, -- sac first as there is likely a prot pally. Life Cocoon last to not waste it
}

NSI.Externals.AllSpells = { -- 1 = if a mechanic requests multiple externals this bypasses that and stops after finding just this one, has to be in priority list before every other external.
    [Sac] = true, -- Sac
    [Bop] = 1, -- Bop
    [Spellbop] = 1, -- Spellbop
    [Painsup] = true, -- Pain Suppression
    [GS1] = true, -- Guardian Spirit
    [GS2] = true, -- Guardian Spirit 2
    [Bark] = true, -- Ironbark
    [Cocoon] = true, -- Life Cocoon
    [TD] = true, -- Time Dilation
    [LoH] = true, -- Lay on Hands
    [Bubble] = true, -- Divine Shield
    [Block] = true, -- Ice Block
    [Turtle] = true, -- Turtle
    [Netherwalk] = true, -- Netherwalk
    [Cloak] = true, -- Cloak
    [Icebound] = true, -- Icebound Fortitude
    [Innervate] = true, -- Innervate
    [Dispersion] = true, -- Dispersion
}

NSI.Externals.Immunes = {
    [Bubble] = true, -- Divine Shield
    [Block] = true, -- Ice Block
    [Turtle] = true, -- Turtle
    [Netherwalk] = true, -- Netherwalk
    [Cloak] = true, -- Cloak
}


local callbacks = {
    CooldownListUpdate = function(...) NSI.Externals:UpdateSpell(...) end,
    CooldownListWipe = function(...) NSI.Externals:UpdateExternals() end,
    CooldownUpdate = function(...) NSI.Externals:UpdateSpell(...) end,
    CooldownAdded = function(...) NSI.Externals:UpdateSpell(...) end,
}

lib.RegisterCallback(callbacks, "CooldownListUpdate", "CooldownListUpdate")
lib.RegisterCallback(callbacks, "CooldownListWipe", "CooldownListWipe")
lib.RegisterCallback(callbacks, "CooldownUpdate", "CooldownUpdate")
lib.RegisterCallback(callbacks, "CooldownAdded", "CooldownAdded")


NSI.Externals.check = { -- check if ready before assigning external
    -- ["Condemnation"] = {31224, 196555, 186265, 45438, 642}, -- spell immunities

    -- example: ["NymueBeam"] = {45438, 642, 48792},
}

NSI.Externals.block = { -- block specific spells from specific players from being used
    ["default"] = {
        -- [633] = {["Shirup"] = true,}
    },

    ["MugzeeFrontal"] = {
        [Sac] = {["Domideus"] = true}
        -- [633] = {["Shirup"] = true,}
    }
}

NSI.Externals.stacks = {
    [Painsup] = true, -- Pain Suppression
    [Bark] = true, -- Ironbark
    [TD] = true, -- Time Dilation
    [Cocoon] = true, -- Life Cocoon

}



NSI.Externals.range = { 
    [Sac] = 40, -- Sac
    [Bop] = 40, -- Bop
    [Spellbop] = 40, -- Spellbop
    [Painsup] = 40, -- Pain Suppression
    [GS1] = 40, -- Guardian Spirit
    [GS2] = 40, -- Guardian Spirit 2
    [Bark] = 45, -- Ironbark
    [Cocoon] = 40, -- Life Cocoon
    [TD] = 30, -- Time Dilation
    [LoH] = 40, -- Lay on Hands
    [Innervate] = 45, -- Innervate
}

function NSAPI:AddExternal(spellID, range, immune, stacks, addtoprio, UpdateAll, name) -- allows adding spells to be tracked. For example on soul hunters when you'd want to check for Dispersion.
    if type(spellID) == "string" then spellID = tonumber(spellID) end
    if type(spellID) == "number" then
        NSI.Externals.AllSpells[spellID] = true
        NSI.Externals.range[spellID] = range or 40
        NSI.Externals.Immunes[spellID] = immune
        NSI.Externals.stacks[spellID] = stacks
        if name then NSI.Externals.NameToID[name] = spellID end
        if addtoprio then
            if type(addtoprio) == "string" and NSI.Externals.prio[addtoprio] then
                table.insert(NSI.Externals.prio[addtoprio], spellID)
            else
                table.insert(NSI.Externals.prio["default"], spellID)
            end
        end
        if UpdateAll then
            NSI.Externals.UpdateExternals()
        end
    end
end

function NSAPI:SpellReadyCheck(unit, Immunes, spellID, duration)
    local i = UnitInRaid(unit)
    if not i then return false end
    local now = GetTime()
    local ready = false
    if spellID then
        if type(spellID) == "string" then
            spellID = NSI.Externals.NameToID[spellID]
        end
        if spellID and type(spellID == "number") then
            local key = UnitGUID(unit)..spellID
            ready = NSI.Externals.ready[key] or (duration and NSI.Externals.Cooldown[key] and now+duration > NSI.Externals.Cooldown[key])
        end
    end
    if Immunes and not ready then
        for k, v in pairs(NSI.Externals.Immunes) do
            if v then
                local key = UnitGUID(unit)..k            
                ready = NSI.Externals.ready[key] or (duration and NSI.Externals.Cooldown[key] and now+duration > NSI.Externals.Cooldown[key])
                if ready then break end
            end
        end
    end
    return ready
end

function NSI.Externals:getprio(unit) -- encounter/phase based priority list
    local enc = WeakAuras.CurrentEncounter and WeakAuras.CurrentEncounter.id
    if enc == 2920 then
        return "Kyveza"
    else
        return "default"
    end
end

function NSI.Externals:extracheck(unit, unitID, key, spellID) -- additional check if the person can actually give the external, like checking if they are in range / on the same side / stunned
    -- unit = giver, unitID = receiver, key = prioname
    local enc = WeakAuras.CurrentEncounter and WeakAuras.CurrentEncounter.id
    if key == "Kyveza" and spellID == Bop and NSAPI:UnitAura(unitID, 437343) then -- do not assign BoP if the person already has queensbane because at that point it was requested too late
        return false
    elseif key == "Condemnation" and spellID == sac and NSAPI:UnitAura(unitID, 438974) then -- do not assign sac if that pally also has the mechanic
        return false
    else
        return true -- need to return false if it should not be assigned
        --[[ example
    if key == "NymueBeam" then -- no self assign on nymue since player is stunned
        return not (UnitIsUnit(unit, unitID))
    end]]
    end
    return true
end




function NSI.Externals:UpdateSpell(unit, spellID, cooldownInfo)
    if not (WeakAuras.CurrentEncounter or NSRT.Settings["Debug"] or C_ChallengeMode.IsChallengeModeActive()) then return end
    if unit and UnitExists(unit) and spellID and cooldownInfo and (NSI.Externals.AllSpells[spellID] or type(spellID) == "table") then
        if UnitInRaid(unit) then
            unit = "raid"..UnitInRaid(unit)
        end
        local G = UnitGUID(unit)
        if type(spellID) == "table" then
            for id, info in pairs(spellID) do
                if NSI.Externals.AllSpells[id] then
                    NSI.Externals.known[id] = NSI.Externals.known[id] or {}
                    NSI.Externals.known[id][G] = true
                    local k = G..id
                    local ready, _, timeleft, charges, _, expires = lib.GetCooldownStatusFromCooldownInfo(info)
                    NSI.Externals.Cooldown[k] = expires
                    NSI.Externals.ready[k] = ready or charges >= 1
                end
            end
        else
            NSI.Externals.known[spellID] = NSI.Externals.known[spellID] or {}
            NSI.Externals.known[spellID][G] = true
            local k = G..spellID
            local ready, _, timeleft, charges, _, expires = lib.GetCooldownStatusFromCooldownInfo(cooldownInfo)
            NSI.Externals.Cooldown[k] = expires
            NSI.Externals.ready[k] = ready or charges >= 1
            return true
        end
    end
end

function NSI.Externals:UpdateExternals()
    if not (WeakAuras.CurrentEncounter or NSRT.Settings["Debug"] or C_ChallengeMode.IsChallengeModeActive()) then return end
    local allUnitsCooldown = lib.GetAllUnitsCooldown()
    NSI.Externals.known = {}
    NSI.Externals.ready = {}
    NSI.Externals.requested = {}
    NSI.Externals.Cooldown = {}
    if allUnitsCooldown then
        for unit, unitCooldowns in pairs(allUnitsCooldown) do
            for spellID, cooldownInfo in pairs(unitCooldowns) do
                if NSI.Externals.AllSpells[spellID] then
                    NSI.Externals:UpdateSpell(unit, spellID, cooldownInfo)
                end
            end
        end
    end
end

-- /run NSAPI:ExternalRequest()
function NSAPI:ExternalRequest(key, num) -- optional arguments
    local now = GetTime()
    if (C_ChallengeMode.IsChallengeModeActive() or NSI:EncounterCheck()) and ((not NSI.Externals.lastrequest) or (NSI.Externals.lastrequest < now - 4)) and not NSAPI:DeathCheck("player") then -- spam, encounter and death protection
        NSI.Externals.lastrequest = now
        key = key or "default"
        num = num or 1
        local range = {}

        for u in NSI:IterateGroupMembers() do
            local r = select(2, WeakAuras.GetRange(u)) or 60
            range[UnitGUID(u)] = {range = r, name = NSAPI:Shorten(u, 12)}            
            if (NSI.Externals.target == "") and (UnitIsVisible(u) and (UnitIsGroupLeader(u) or UnitIsGroupAssistant(u))) then -- should fix reload/dc issues
                NSI.Externals.target = u
            end
        end
        NSI:Broadcast("NS_EXTERNAL_REQ", "WHISPER", UnitName(NSI.Externals.target), key, num, true, range, 0)    -- request external
    end
end

-- /run NSAPI:Innervate:Request()
function NSAPI:InnervateRequest()    
    local now = GetTime()
    if (C_ChallengeMode.IsChallengeModeActive() or NSI:EncounterCheck()) and ((not NSI.Externals.lastrequest2) or (NSI.Externals.lastrequest2 < now - 4)) and not NSAPI:DeathCheck("player") then -- spam, encounter and death protection
        NSI.Externals.lastrequest2 = now
        local range = {}
        for u in NSI:IterateGroupMembers() do
            local r = select(2, WeakAuras.GetRange(u)) or 25 -- function fails for a few classes while in combat
            range[UnitGUID(u)] = {range = r, name = NSAPI:Shorten(u, 12)}
            if (NSI.Externals.target == "") and (UnitIsVisible(u) and (UnitIsGroupLeader(u) or UnitIsGroupAssistant(u))) then -- should fix reload/dc issues
                NSI.Externals.target = u
            end
        end
        NSI:Broadcast("NS_INNERVATE_REQ", "WHISPER", UnitName(NSI.Externals.target), key, num, true, range, 0) -- request external
    end
end

function NSI.Externals:Request(unitID, key, num, req, range, innervate, expirationTime)
    -- unitID = player that requested
    -- unit = player that shall give the external
    num = num or 1
    local now = GetTime()
    local name, realm = UnitName(unitID)
    local sender = realm and name.."-"..realm or name
    local found = 0
    local count = 0
    local duration = (NSI.Externals.OnlyReady and NSI.Externals.OnlyReady[key] and 0) or expirationTime-now-1
    NSI.Externals.assigned = {}
    if innervate then
        for G, _ in pairs(NSI.Externals.known[Innervate]) do
            local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, G, Innervate, sender, 0, 0)
            if assigned then count = count+1 end
            if count >= 1 then return end
        end        
        
        -- go through everything again if no innervate was found yet but this time we allow innervates that are still on cd for less than 15 seconds
        for G, _ in pairs(NSI.Externals.known[Innervate]) do
            local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, G, Innervate, sender, 15, 0)
            if assigned then count = count+1 end
            if count >= 1 then return end
        end      
        -- going through it a 3rd time, this time allowing up to 60y range
        for G, _ in pairs(NSI.Externals.known[Innervate]) do
            local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, G, Innervate, sender, 15, 20)
            if assigned then count = count+1 end
            if count >= 1 then return end
        end        
        NSI:Broadcast("NS_EXTERNAL_NO", "WHISPER", UnitName(unitID), "Innervate")   
        return
    end
    if key == "default" then
        key = NSI.Externals:getprio(unitID)
    end
    if NSI.Externals.check[key] then -- see if an immunity or other assigned self cd's are available first
        for i, spellID in ipairs(NSI.Externals.check[key]) do
            if (spellID ~= 1022 and spellID ~= 204018 and spellID ~= 633 and spellID ~= 204018) or not NSAPI:UnitAura(unitID, 25771) then -- check forebearance
                local check = unitID..spellID
                if NSI.Externals.ready[check] then return end
            end
        end
    end
    -- check specific player prio first
    if NSI.Externals.customprio[key] then
        for i, v in ipairs(NSI.Externals.customprio[key]) do
            local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, v[1], v[2], sender, duration, 0)
            if assigned then count = count+1 end
            if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
        end
        for i, v in ipairs(NSI.Externals.customprio[key]) do
            local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, v[1], v[2], sender, duration, 20)
            if assigned then count = count+1 end
            if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
        end
        for i, v in ipairs(NSI.Externals.customprio[key]) do
            local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, v[1], v[2], sender, duration ~= 0 and duration or 2, 20)
            if assigned then count = count+1 end
            if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
        end
    end

    -- check generic spell prio next
    if NSI.Externals.customspellprio[key] then
        for i, spellID in ipairs(NSI.Externals.customspellprio[key]) do -- go through spellid's in prio order
            if NSI.Externals.known[spellID] then
                for G, _ in pairs(NSI.Externals.known[spellID]) do -- check each person who knows that spell if it's available and not already requested
                    local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, G, spellID, sender, duration, 0)
                    if assigned then count = count+1 end
                    if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
                end
            end
        end                
        for i, spellID in ipairs(NSI.Externals.customspellprio[key]) do -- go through spellid's in prio order
            if NSI.Externals.known[spellID] then
                for G, _ in pairs(NSI.Externals.known[spellID]) do -- check each person who knows that spell if it's available and not already requested
                    local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, G, spellID, sender, duration, 20)
                    if assigned then count = count+1 end
                    if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
                end
            end
        end
        for i, spellID in ipairs(NSI.Externals.customspellprio[key]) do -- go through spellid's in prio order
            if NSI.Externals.known[spellID] then
                for G, _ in pairs(NSI.Externals.known[spellID]) do -- check each person who knows that spell if it's available and not already requested
                    local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, G, spellID, sender, duration ~= 0 and duration or 2, 20)
                    if assigned then count = count+1 end
                    if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
                end
            end
        end
    end

    -- continue with default prio if nothing was found yet
    if not NSI.Externals.prio[key] then key = "default" end -- if no specific prio was found, use default prio
    if NSI.Externals.SkipDefault and NSI.Externals.SkipDefault[key] then
        NSI:Broadcast("NS_EXTERNAL_NO", "WHISPER", UnitName(unitID), "nilcheck")      
        return
    end
    for i, spellID in ipairs(NSI.Externals.prio[key]) do -- go through spellid's in prio order
        if NSI.Externals.known[spellID] then
            for unit, _ in pairs(NSI.Externals.known[spellID]) do -- check each person who knows that spell if it's available and not already requested
                local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, unit, spellID, sender, duration, 0)
                if assigned then count = count+1 end
                if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
            end
        end
    end
    for i, spellID in ipairs(NSI.Externals.prio[key]) do -- go through spellid's in prio order
        if NSI.Externals.known[spellID] then
            for unit, _ in pairs(NSI.Externals.known[spellID]) do -- check each person who knows that spell if it's available and not already reques
                local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, unit, spellID, sender, duration, 20)
                if assigned then count = count+1 end
                if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
            end
        end
    end
    for i, spellID in ipairs(NSI.Externals.prio[key]) do -- go through spellid's in prio order
        if NSI.Externals.known[spellID] then
            for unit, _ in pairs(NSI.Externals.known[spellID]) do -- check each person who knows that spell if it's available and not already reques
                local assigned = NSI.Externals:AssignExternal(unitID, key, num, req, range, unit, spellID, sender, duration ~= 0 and duration or 2, 20)
                if assigned then count = count+1 end
                if count >= num or NSI.Externals.AllSpells[assigned] == 1 then return end -- end loop if we found enough externals or found an immunity
            end
        end
    end
    -- No External Left
    NSI:Broadcast("NS_EXTERNAL_NO", "WHISPER", UnitName(unitID), "nilcheck")   
end

function NSI.Externals:AssignExternal(unitID, key, num, req, range, G, spellID, sender, allowCD, RangeToAdd) -- unitID = requester, unit = unit that shall give the external
    if spellID == Innervate then
        if UnitGroupRolesAssigned(unitID) ~= "HEALER" or UnitGroupRolesAssigned(unit) == "HEALER" then -- don't assign Innervate if requester is not a healer or the person we are checking is a healer
            return false
        end        
    end
    local now = GetTime()
    local unit = UnitTokenFromGUID(G)
    local k = G..spellID
    local rangecheck = range == "skip" or (range and type(range) == "table" and range[G] and NSI.Externals.range[spellID]+RangeToAdd >= range[G].range)
    local giver, realm = UnitName(unit)
    local blocked = NSI.Externals.block[key] and NSI.Externals.block[key][spellID] and NSI.Externals.block[key][spellID][giver]
    local yourself = UnitIsUnit(unit, unitID)
    local ready = NSI.Externals.ready[k] or (allowCD > 0 and NSI.Externals.Cooldown[k] and now+allowCD > NSI.Externals.Cooldown[k]) -- allow precalling spells that are still on CD
    if
    UnitIsVisible(unit) -- in same instance
            and ready -- spell is ready
            and NSI.Externals:extracheck(unit, unitID, key, spellID) -- special case checks, hardcoded into the addon
            and rangecheck
            and ((not NSI.Externals.requested[k]) or now > NSI.Externals.requested[k]+10) -- spell isn't already requested and the request hasn't timed out
            and not (spellID == Sac and yourself) -- no self sac
            and not (UnitIsDead(unit)) -- only doing normal death check instead of also checking for angel form because angel form can still give the external
            and not (yourself and req) -- don't assign own external if it was specifically requested, only on automation
            and not (NSAPI:UnitAura(unitID, 25771) and (spellID == Bop or spellID == Spellbop or spellID == LoH)) --Forebearance check
            and not blocked -- spell isn't specifically blocked for this key
            and not NSI.Externals.assigned[spellID] -- same spellid isn't already assigned unless it stacks
    then
        table.insert(NSI.AssignedExternals, {automated = not req, receiver = NSAPI:Shorten(unitID), giver = NSAPI:Shorten(u), spellID = spellID, key = key, time = Round(now-NSI.Externals.pull)}) -- for debug printing later
        NSI.Externals.requested[k] = now -- set spell to requested
        
        NSI:Broadcast("NS_EXTERNAL_LIST", "RAID", unit, sender, spellID) -- send List Data  
        NSI:Broadcast("NS_EXTERNAL_GIVE", "WHISPER", UnitName(unit), sender, spellID) -- send External Alert
        NSI:Broadcast("NS_EXTERNAL_YES", "WHISPER", UnitName(unitID), giver, spellID) -- send Confirmation
        if not NSI.Externals.stacks[spellID] then
            NSI.Externals.assigned[spellID] = true
        end
        return spellID
    else
        return false
    end
end

function NSI.Externals:Init(group)
    if not group then NSI.Externals.target = "raid1" end
    NSI.Externals.pull = GetTime()
    for u in NSI:IterateGroupMembers() do
        if UnitIsVisible(u) and (UnitIsGroupLeader(u) or UnitIsGroupAssistant(u)) then
            NSI.Externals.target = u
            break
        end
    end
    NSAPI.Leader = NSI.Externals.target -- expose "leader" to public API so it can be used to send assignments
    NSI.Externals:UpdateExternals()
    if UnitIsUnit("player", NSI.Externals.target) then        
        local note = NSAPI:GetNote()
        local list = false
        local key = ""
        local spell = 0
        NSI.Externals.customprio = {}
        NSI.Externals.customspellprio = {}
        NSI.Externals.Automated = {}
        NSI.Externals.Amount = {}
        NSI.AssignedExternals = {}
        NSI.Externals.block = {}
        NSI.Externals.SkipDefault = {}
        NSI.Externals.OnlyReady = {}
        NSI.Externals.assigned = {}
        if note == "" then return end
        for line in note:gmatch('[^\r\n]+') do
            --check for start/end of the name list
            if strlower(line) == "nsexternalstart" then
                list = true 
                key = ""
            elseif strlower(line) == "nsexternalend" then
                list = false
                key = ""
            end
            if list then
                for k in line:gmatch("key:(%S+)") do
                    NSI.Externals.customprio[k] = NSI.Externals.customprio[k] or {}
                    NSI.Externals.customspellprio[k] = NSI.Externals.customspellprio[k] or {}
                    key = k
                    NSI.Externals.block[key] = {}
                end
                if key ~= "" then
                    for spellID in line:gmatch("automated:(%d+)") do -- automated assigning external for that spell
                        spell = tonumber(spellID)
                        NSI.Externals.Automated[spell] = key
                        NSI.Externals.Amount[key..spell] = NSI.Externals.Amount[key..spell] or 1
                    end
                    if spell ~= 0 then
                        for num in line:gmatch("amount:(%d+)") do -- amount of externals for this spell
                            NSI.Externals.Amount[key..spell] = tonumber(num)
                        end
                    end
                    for name, spellID in line:gmatch("block:(%S+):(%d+)") do -- block certain spells from someone to be assigned
                        if UnitInRaid(name) and spellID then
                            spellID = tonumber(spellID)
                            NSI.Externals.block[key][spellID] = NSI.Externals.block[key][spellID] or {}
                            NSI.Externals.block[key][spellID][name] = true
                        end
                    end
                    for spellID in line:gmatch("check:(%d+)") do -- add a check whether a certain ability is ready before assigning an external - for example if an immunity should be used before the user gets an external
                        NSI.Externals.check[key] = NSI.Externals.check[key] or {}
                        table.insert(NSI.Externals.check[key], tonumber(spellID))        
                        if not NSI.Externals.AllSpells[spellID] then NSI.Externals.AllSpells[spellID] = true end -- add spells where cooldowns needs to be checked to the equivalent table                 
                    end                        
                    for name, id in line:gmatch("(%S+):(%d+)") do
                        if UnitInRaid(name) and name ~= "spell" then
                            NSI.Externals.customprio[key] = NSI.Externals.customprio[key] or {}
                            table.insert(NSI.Externals.customprio[key], {UnitGUID(name), tonumber(id)})
                        end
                    end    
                    for spellID in line:gmatch("spell:(%d+)") do
                        NSI.Externals.customspellprio[key] = NSI.Externals.customspellprio[key] or {}
                        table.insert(NSI.Externals.customspellprio[key], tonumber(spellID))
                    end     
                    if line == "skipdefault" then
                        NSI.Externals.SkipDefault[key] = true
                    end
                    if line == "onlyready" then
                        NSI.Externals.OnlyReady[key] = true
                    end
                end      
            end
        end
    end
end