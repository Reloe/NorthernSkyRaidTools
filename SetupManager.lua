local _, NSI = ... -- Internal namespace
local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function(self, e, ...)
    NSI:ArrangeGroups()
end)
NSI.Groups = {}
NSI.Groups.Processing = false

local meleetable = { -- ignoring tanks for this
    [263]  = true, -- Shaman: Enhancement
    [255]  = true, -- Hunter: Survival
    [259]  = true, -- Rogue: Assassination  
    [260]  = true, -- Rogue: Outlaw  
    [261]  = true, -- Rogue: Subtlety
    [71]   = true, -- Warrior: Arms  
    [72]   = true, -- Warrior: Fury 
    [251]  = true, -- Death Knight: Frost
    [252]  = true, -- Death Knight: Unholy
    [103]  = true, -- Druid: Feral 
    [70]   = true, -- Paladin: Retribution
    [269]  = true, -- Monk: Windwalker
    [577]  = true, -- Demon Hunter: Havoc
    [65]   = true, -- Paladin: Holy
    [270]  = true, -- Monk: Mistweaver
}

local lusttable = {
    [263]  = true, -- Shaman: Enhancement
    [255]  = true, -- Hunter: Survival
    [1473] = true, -- Evoker: Augmentation
    [1467] = true, -- Evoker: Devastation
    [253]  = true, -- Hunter: Beast Mastery
    [254]  = true, -- Hunter: Marksmanship
    [262]  = true, -- Shaman: Elemental 
    [64]   = true, -- Mage: Frost
    [62]   = true, -- Mage: Arcane
    [63]   = true, -- Mage: Fire
    [1468] = true, -- Evoker: Preservation
    [264]  = true, -- Shaman: Restoration
}

local resstable = {    
    [66]   =  true, -- Prot Pally
    [104]  =  true, -- Guardian Druid
    [250]  =  true, -- Blood DK
    [251]  = true, -- Death Knight: Frost
    [252]  = true, -- Death Knight: Unholy
    [103]  = true, -- Druid: Feral 
    [70]   = true, -- Paladin: Retribution
    [102]  = true, -- Druid: Balance
    [265]  = true, -- Warlock: Affliction 
    [266]  = true, -- Warlock: Demonology  
    [267]  = true, -- Warlock: Destruction    
    [65]   = true, -- Paladin: Holy
    [105]  = true, -- Druid: Restoration
}

local spectable = {    
    -- Tanks
    [0] = 100, -- probably offline/no data, we put them last
    [268]  =  1, -- Brewmaster
    [66]   =  2, -- Prot Pally
    [104]  =  3, -- Guardian Druid
    [73]   =  4, -- Prot Warrior
    [581]  =  5, -- Veng DH
    [250]  =  6, -- Blood DK

    -- Melee
    [263]  = 7, -- Shaman: Enhancement
    [255]  = 8, -- Hunter: Survival
    [259]  = 9, -- Rogue: Assassination  
    [260]  = 10, -- Rogue: Outlaw  
    [261]  = 11, -- Rogue: Subtlety
    [71]   = 12, -- Warrior: Arms  
    [72]   = 13, -- Warrior: Fury 
    [251]  = 14, -- Death Knight: Frost
    [252]  = 15, -- Death Knight: Unholy
    [103]  = 16, -- Druid: Feral 
    [70]   = 17, -- Paladin: Retribution
    [269]  = 18, -- Monk: Windwalker
    [577]  = 19, -- Demon Hunter: Havoc

    -- Ranged
    [1473] = 20, -- Evoker: Augmentation
    [1467] = 21, -- Evoker: Devastation
    [253]  = 22, -- Hunter: Beast Mastery
    [254]  = 23, -- Hunter: Marksmanship
    [262]  = 24, -- Shaman: Elemental 
    [258]  = 25, -- Priest: Shadow
    [102]  = 26, -- Druid: Balance
    [64]   = 27, -- Mage: Frost
    [62]   = 28, -- Mage: Arcane
    [63]   = 29, -- Mage: Fire
    [265]  = 30, -- Warlock: Affliction 
    [266]  = 31, -- Warlock: Demonology  
    [267]  = 32, -- Warlock: Destruction    
    
    -- Healers
    [65]   = 33, -- Paladin: Holy
    [270]  = 34, -- Monk: Mistweaver
    [1468] = 35, -- Evoker: Preservation
    [105]  = 36, -- Druid: Restoration
    [264]  = 37, -- Shaman: Restoration
    [256]  = 38, -- Priest: Discipline 
    [257]  = 39, -- Priest: Holy
}


function NSI:SortGroup(Flex, default, odds) -- default == tank, melee, ranged, healer
    local units = {}
    local lastgroup = Flex and 6 or 4
    local total = {["ALL"] = 0, ["TANK"] = 0, ["HEALER"] = 0, ["DAMAGER"] = 0}
    local poscount = {0, 0, 0, 0, 0}
    local groupSize = {}
    for i=1, 40 do
        local subgroup = select(3, GetRaidRosterInfo(i))
        local unit = "raid"..i
        if not UnitExists(unit) then break end
        local specid = NSAPI:GetSpecs(unit) or 0
        local class = select(3, UnitClass(unit))
        local role = UnitGroupRolesAssigned(unit)
        if subgroup <= lastgroup then
            total[role] = total[role]+1
            total["ALL"] = total["ALL"]+1
            local melee = meleetable[specid]
            local pos = 0
            pos = (role == "TANK" and 5) or (melee and (role == "DAMAGER" and 1 or 2)) or (role == "DAMAGER" and 3) or 4 -- different counting for melee dps and melee healers
            poscount[pos] = poscount[pos]+1
            table.insert(units, {name = UnitName(unit), processed = false, unitid = unit, specid = specid, index = i, role = role, class = class, pos = pos, canlust = lusttable[class], canress = resstable[class], GUID = UnitGUID(unit)})
        end
    end    
    table.sort(units, -- default sorting with tanks - melee - ranged - healer
    function(a, b)
        if a.specid == b.specid then
            return a.GUID < b.GUID
        else
            return spectable[a.specid] < spectable[b.specid]
        end
    end) -- a < b low first, a > b high first
    NSI.Groups.total = total["ALL"]
    if default then
        for i=1, 40 do
            local v = units[i]
            if v and UnitIsGroupLeader(v.unitid) then
                local num = math.floor((i - 1) / 5) * 5 + 1
                if units[num] then units[i] = units[num] end 
                units[num] = v 
                break
            end 
        end
        NSI.Groups.units = units
        NSI:ArrangeGroups(true)
    else
        local sides = {["left"] = {}, ["right"] = {}}
        local classes = {["left"] = {}, ["right"] = {}}
        local specs = {["left"] = {}, ["right"] = {}}
        local pos = {["left"] = {0, 0, 0, 0, 0}, ["right"] = {0, 0, 0, 0, 0}}
        local roles = {["left"] = {}, ["right"] = {}}
        local lust = {["left"] = false, ["right"] = false}
        local bress = {["left"] = 0, ["right"] = 0}
        for i=1, 3 do
            local role = (i == 1 and "TANK") or (i == 2 and "HEALER") or (i == 3 and "DAMAGER")
            roles["left"].role = 0
            roles["right"].role = 0
            for _, v in ipairs(units) do
                if v.role == role then
                    local side = ""
                    if role == "TANK" then side = roles["left"].role <= roles["right"].role and "left" or "right" -- for tanks doing a simple left/right split not caring about specs
                    elseif #sides["left"] >= total["ALL"]/2 then side = "right" -- if left side is already filled, everyone else goes to the right side
                    elseif #sides["right"] >= total["ALL"]/2 then side = "left" -- if right side is already filled, everyone else goes to the left side
                    elseif roles["left"].role >= total[role]/2 then side = "right" -- if left side already has half of the total players of that role, rest goes to right side
                    elseif roles["right"].role >= total[role]/2 then side = "left" -- if right side already has half of the total players of that role, rest goes to left side
                    elseif pos["left"][v.pos] >= poscount[v.pos]/2 then side = "right" -- if one side already has enough melee, insert to the other side
                    elseif pos["right"][v.pos]  >= poscount[v.pos]/2 then side = "left" -- same as last               
                    elseif classes["right"][v.class] and not classes["left"][v.class] then side = "left" -- if one side has this class already but the other doesn't
                    elseif classes["left"][v.class] and not classes["right"][v.class] then side = "right" -- if one side has this class already but the other doesn't
                    elseif (not classes["left"][v.class]) and (not classes["right"][v.class]) then -- if neither side has this class yet
                        side = (pos["left"][v.pos] > pos["right"][v.pos] and "right") or "left" -- insert right if left has more of this positoin than right, if those are also equal insert left
                    elseif v.canress and (bress["left"] <= 1 or bress["right"] <= 1) then side = (bress["left"] <= 1 and bress["left"] <= bress["right"] and "left") or "right" -- give each side up to 2 bresses
                    elseif v.canlust and ((not lust["left"]) or (not lust["right"])) then side = ((not lust["left"]) and "left") or "right" -- give each side a lust
                    elseif specs["left"][v.specid] and not specs["right"][v.specid] then side = "right" -- if one side has this spec already but the other doesn't
                    elseif specs["right"][v.specid] and not specs["left"][v.specid] then side = "left" -- if one side has this spec already but the other doesn't
                    elseif (not specs["left"][v.specid]) and (not specs["right"][v.specid]) then -- if neither side has this spec yet
                        side = (pos["left"][v.pos] > pos["right"][v.pos] and "right") or "left" -- insert right if left has more of this positoin than right, if those are also equal insert left
                    else side = (#sides["left"] > #sides["right"] and "right") or "left" -- should never come to this I think
                    end

                    if side ~= "" then
                        table.insert(sides[side], v)
                        classes[side][v.class] = true
                        pos[side][v.pos] = pos[side][v.pos]+1
                        if v.canlust then lust[side] = true end
                        if v.canress then bress[side] = bress[side]+1 end
                        specs[side][v.specid] = (specs[side][v.specid] and specs[side][v.specid]+1) or 1
                        roles[side].role = (roles[side].role and roles[side].role+1) or 1
                    end
                end
            end
        end       
        table.sort(sides["left"], -- sort again within each table with tanks - melee - ranged - healer
        function(a, b)
            if a.specid == b.specid then
                return a.GUID < b.GUID
            else
                return spectable[a.specid] < spectable[b.specid]
            end
        end) -- a < b low first, a > b high first        
        table.sort(sides["right"], -- sort again within each table with tanks - melee - ranged - healer
        function(a, b)
            if a.specid == b.specid then
                return a.GUID < b.GUID
            else
                return spectable[a.specid] < spectable[b.specid]
            end
        end) -- a < b low first, a > b high first
        if NSI.Groups.Odds then
            units = {}
            local count = 1
            for i, v in ipairs(sides["left"]) do
                if UnitIsGroupLeader(v.unitid) then -- if this person is the raid leader he needs to be put in the first position of each subgroup
                    local num = math.floor((count - 1) / 5) * 5 + 1 -- this will result in 1, 6, 11 etc. Basically first position of a subgroup
                    if units[num] then units[count] = units[num] end -- put whoever was already in the first position of the subgroup into the current position
                    units[num] = v -- put the leader in the first position of the subgroup
                else
                    units[count] = v      
                end
                count = count+1
                if count > 5 then count = 11 end
                if count > 15 then count = 21 end
            end
            count = 6            
            for i, v in ipairs(sides["right"]) do
                if UnitIsGroupLeader(v.unitid) then 
                    local num = math.floor((count - 1) / 5) * 5 + 1 
                    if units[num] then units[count] = units[num] end 
                    units[num] = v 
                else
                    units[count] = v      
                end
                count = count+1
                if count > 10 then count = 16 end
                if count > 20 then count = 26 end
            end
            NSI.Groups.units = units
            NSI:ArrangeGroups(true)
        else         
            units = {}
            local count = 1
            for i, v in ipairs(sides["left"]) do
                if UnitIsGroupLeader(v.unitid) then 
                    local num = math.floor((count - 1) / 5) * 5 + 1 
                    if units[num] then units[count] = units[num] end 
                    units[num] = v 
                else
                    units[count] = v      
                end
                count = count+1
            end
            if total["ALL"] > 20 then count = 16 
            elseif total["ALL"] > 10 then count = 11
            else count = 6
            end
            for i, v in ipairs(sides["right"]) do
                if UnitIsGroupLeader(v.unitid) then 
                    local num = math.floor((count - 1) / 5) * 5 + 1 
                    if units[num] then units[count] = units[num] end 
                    units[num] = v 
                else
                    units[count] = v      
                end
                count = count+1
            end
            NSI.Groups.units = units
            NSI:ArrangeGroups(true)
        end
    end    
end

function NSI:ArrangeGroups(firstcall, finalcheck)
    if not firstcall and not NSI.Groups.Processing then return end
    local now = GetTime()
    if firstcall then 
        NSI:Print("Split Table Data:", NSI.Groups.units)
        NSI.Groups.Processing = true 
        NSI.Groups.Processed = 0 
        NSI.Groups.ProcessStart = now 
        for i=1, 40 do
            local group = math.ceil(i/5)
            local subgrouppos = i % 5 == 0 and 5 or i % 5
            if NSI.Groups.units[i] then
                NSI.Groups.units[i].group = group
                NSI.Groups.units[i].subgrouppos = subgrouppos
                NSI.Groups.units[i].pos= ((group-1)*5)+subgrouppos
            end
        end
    end
    if NSI.Groups.ProcessStart and now > NSI.Groups.ProcessStart+15 then NSI.Groups.Processing = false return end -- backup stop if it takes super long we're probably in a loop somehow
    local groupSize = {0, 0, 0, 0, 0, 0, 0, 0}
    local postoindex = {}
    local indexlink = {}
    for i=1, 40 do indexlink[i] = {} end 
    for i=1, 40 do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if not name then break end
        groupSize[subgroup] = groupSize[subgroup]+1
        postoindex[((subgroup-1)*5)+groupSize[subgroup]] = i 
        indexlink[i] = {subgroup = subgroup, pos = ((subgroup-1)*5)+groupSize[subgroup]}
    end

    if NSI.Groups.Processed >= NSI.Groups.total then 
        if finalcheck then
            local allprocessed = true
            for i=1, 40 do
                local v = NSI.Groups.units[i]
                if v then 
                    local index = UnitInRaid(v.name)
                    if postoindex[v.pos] ~= index then
                        v.processed = false
                        allprocessed = false
                        NSI.Groups.Processed = NSI.Groups.Processed-1
                    end
                end
            end
            if allprocessed then
                NSI.Groups.Processing = false
                return
            end
        else
            NSI:ArrangeGroups(false, true)
            return
        end
    end

    for i=1, 40 do -- position in table is where the player should end up in
        local v = NSI.Groups.units[i]    
        if v and (not v.processed) and (not UnitAffectingCombat(v.name)) then 
            local index = UnitInRaid(v.name)
            local indexgoal = postoindex[v.pos]
            if indexgoal ~= index then -- check if player is already in correct spot
                if groupSize[v.group] < v.subgrouppos and indexlink[index].subgroup ~= v.group then
                    if groupSize[v.group]+1 == v.subgrouppos then -- next free spot is in the correct position. It's not guranteed to end up in the correct position anyway so need to check on next call
                        SetRaidSubgroup(index, v.group)
                        break
                    else -- if not enough players are in the group to move this player to the desired spot we need to put someone who is not in the correct position yet there.
                        for j=1, 40 do
                            if i ~= j then
                                local u = NSI.Groups.units[j]  
                                if u and (not u.processed) and v.group ~= indextosubgroup[UnitInRaid(u.name)] then
                                    SetRaidSubgroup(UnitInRaid(u.name), v.group)
                                    break
                                end
                            end
                        end
                        break
                    end
                elseif indexgoal and indexlink[index].subgroup and indexlink[indexgoal].subgroup and indexlink[index].subgroup ~= indexlink[indexgoal].subgroup and UnitExists("raid"..indexgoal) and (not UnitAffectingCombat("raid"..indexgoal)) then -- check if the player we need to swap with is in a different subgroup
                    SwapRaidSubgroup(indexgoal, index)
                    v.processed = true
                    NSI.Groups.Processed = NSI.Groups.Processed+1
                    break
                else -- the 2 players to swap are in the same group so we instead swap with someone else
                    local found = false
                    local u = NSI.Groups.units[indexlink[index].pos] -- first try to swap with the person who is meant to be in the position this player is in
                    if u and (not UnitAffectingCombat(u.name)) and (not UnitIsUnit(v.name, u.name)) and u.pos == indexlink[index].pos and indexlink[index].subgroup ~= indexlink[UnitInRaid(u.name)].subgroup then
                        SwapRaidSubgroup(UnitInRaid(u.name), index)
                        found = true
                    end
                    if not found then -- next try to swap with someone who is not in the correct position yet
                        for j=1, 40 do
                            local u = NSI.Groups.units[j]
                            if u and (not u.processed) and (not UnitAffectingCombat(u.name)) and (not UnitIsUnit(v.name, u.name)) and indexlink[index].subgroup ~= indexlink[UnitInRaid(u.name)].subgroup then
                                SwapRaidSubgroup(UnitInRaid(u.name), index)
                                found = true
                                break
                            end
                        end     
                    end        
                    if not found then -- if we were somehow unable to find anyone we can swap this person with, swap them with someone who was already processed but not the raid leader  
                        for j=1, 40 do
                            local u = NSI.Groups.units[j]
                            if u and (not UnitIsGroupLeader(u.name)) and (not UnitAffectingCombat(u.name)) and (not UnitIsUnit(v.name, u.name)) and indexlink[index].subgroup ~= indexlink[UnitInRaid(u.name)].subgroup then
                                SwapRaidSubgroup(UnitInRaid(u.name), index)
                                found = true
                                break
                            end
                        end   
                    end  
                    break
                end
            else -- character is already in the correct position
                v.processed = true
                NSI.Groups.Processed = NSI.Groups.Processed+1
                NSI:ArrangeGroups(false, finalcheck)
                break
            end
        end        
    end
end

function NSI:SplitGroupInit(Flex, default, odds)
    if UnitIsGroupAssistant("player") or UnitIsGroupLeader("player") and UnitInRaid("player") then
        local now = GetTime()
        if NSI.Groups.Processing and NSI.Groups.ProcessStart and now < NSI.Groups.ProcessStart + 15 then print("there is still a group process going on, please wait") return end 
        if not NSI.LastGroupSort or NSI.LastGroupSort < now - 5 then
            NSI.LastGroupSort = GetTime()
            NSI:Broadcast("NSAPI_SPEC_REQUEST", "RAID", "nilcheck")
            local difficultyID = select(3, GetInstanceInfo()) or 0
            if difficultyID == 16 then Flex = false else Flex = true end
            C_Timer.After(2, function() NSI:SortGroup(Flex, default, odds) end)
        else
            print("You hit the spam protection for sorting groups, please wait at least 5 seconds between pressing the button.")
        end
    end
end