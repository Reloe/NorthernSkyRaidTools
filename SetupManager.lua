local _, NSI = ... -- Internal namespace

NSI.Groups = {}
NSI.Groups.Processing = false

NSI.meleetable = { -- ignoring tanks for this
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

NSI.lusttable = {
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

NSI.resstable = {
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

NSI.spectable = {
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
    [251]  = 9, -- Death Knight: Frost
    [252]  = 10, -- Death Knight: Unholy
    [259]  = 11, -- Rogue: Assassination
    [260]  = 12, -- Rogue: Outlaw
    [261]  = 13, -- Rogue: Subtlety
    [71]   = 14, -- Warrior: Arms
    [72]   = 15, -- Warrior: Fury
    [103]  = 16, -- Druid: Feral
    [70]   = 17, -- Paladin: Retribution
    [269]  = 18, -- Monk: Windwalker
    [577]  = 19, -- Demon Hunter: Havoc

    -- Ranged
    [1480] = 20, -- Demon Hunter: Devourer
    [1473] = 21, -- Evoker: Augmentation
    [1467] = 22, -- Evoker: Devastation
    [262]  = 23, -- Shaman: Elemental
    [258]  = 24, -- Priest: Shadow
    [102]  = 25, -- Druid: Balance
    [265]  = 26, -- Warlock: Affliction
    [266]  = 27, -- Warlock: Demonology
    [267]  = 28, -- Warlock: Destruction
    [64]   = 29, -- Mage: Frost
    [62]   = 30, -- Mage: Arcane
    [63]   = 31, -- Mage: Fire
    [253]  = 32, -- Hunter: Beast Mastery
    [254]  = 33, -- Hunter: Marksmanship

    -- Healers
    [65]   = 34, -- Paladin: Holy
    [270]  = 35, -- Monk: Mistweaver
    [1468] = 36, -- Evoker: Preservation
    [105]  = 37, -- Druid: Restoration
    [264]  = 38, -- Shaman: Restoration
    [256]  = 39, -- Priest: Discipline
    [257]  = 40, -- Priest: Holy
}

function NSI:GetSortedGroup(Flex, default, odds)
    local units = {}
    local lastgroup = Flex and 6 or 4
    local total = {["ALL"] = 0, ["TANK"] = 0, ["HEALER"] = 0, ["DAMAGER"] = 0}
    local poscount = {0, 0, 0, 0, 0}
    local groupSize = {}
    for i=1, 40 do
        local subgroup = select(3, GetRaidRosterInfo(i))
        local unit = "raid"..i
        if not UnitExists(unit) then break end
        local specid = self:GetSpecs(unit) or 0
        local class = select(3, UnitClass(unit))
        local role = UnitGroupRolesAssigned(unit)
        if subgroup <= lastgroup then
            total[role] = total[role]+1
            total["ALL"] = total["ALL"]+1
            local melee = self.meleetable[specid]
            local pos = 0
            pos = (role == "TANK" and 5) or (melee and (role == "DAMAGER" and 1 or 2)) or (role == "DAMAGER" and 3) or 4 -- different counting for melee dps and melee healers
            poscount[pos] = poscount[pos]+1
            table.insert(units, {name = UnitName(unit), processed = false, unitid = unit, specid = specid, index = i, role = role, class = class, pos = pos, canlust = self.lusttable[class], canress = self.resstable[class], GUID = UnitGUID(unit)})
        end
    end
    table.sort(units, -- default sorting with tanks - melee - ranged - healer
    function(a, b)
        if a.specid == b.specid then
            return a.GUID < b.GUID
        else
            return self.spectable[a.specid] < self.spectable[b.specid]
        end
    end) -- a < b low first, a > b high first
    self.Groups.total = total["ALL"]
    if default then
        units = self:ShiftLeader(units)
        return units
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
                return self.spectable[a.specid] < self.spectable[b.specid]
            end
        end) -- a < b low first, a > b high first
        table.sort(sides["right"], -- sort again within each table with tanks - melee - ranged - healer
        function(a, b)
            if a.specid == b.specid then
                return a.GUID < b.GUID
            else
                return self.spectable[a.specid] < self.spectable[b.specid]
            end
        end) -- a < b low first, a > b high first
        sides["left"] = self:ShiftLeader(sides["left"])
        sides["right"] = self:ShiftLeader(sides["right"])
        if odds then
            units = {}
            for i, v in ipairs(sides["left"]) do
                if i > 10 then i = i+10
                elseif i > 5 then i = i+5 end
                units[i] = v
            end
            for i, v in ipairs(sides["right"]) do
                if i > 10 then i = i +15
                elseif i > 5 then i = i+10
                else i = i+5 end
                units[i] = v
            end
            return units, sides["left"], sides["right"]
        else
            units = {}
            for i, v in ipairs(sides["left"]) do
                units[i] = v
            end
            local offset = 0
            if total["ALL"] > 20 then offset = 15
            elseif total["ALL"] > 10 then offset = 10
            else offset = 5
            end
            for i, v in ipairs(sides["right"]) do
                units[i+offset] = v
            end
            return units, sides["left"], sides["right"]
        end
    end
end


function NSI:SortGroup(Flex, default, odds) -- default == tank, melee, ranged, healer
    self.Groups.units = self:GetSortedGroup(Flex, default, odds)
    self:ArrangeGroups(true)
end

function NSI:ShiftLeader(group)
    if not group then return end
    local currentpos = 0
    local goalpos = 0
    for i, v in ipairs(group) do
        if UnitIsGroupLeader(v.unitid) then
            currentpos = i
            -- for tanks put them first in their current group, for others put them first in not the first group so they don't appear above the tanks unless there are less than 6 players available.
            goalpos = (v.role == "TANK" and math.floor((i - 1) / 5) * 5 + 1) or (i > 5 and math.floor((i - 1) / 5) * 5 + 1) or (#group > 5 and 6) or 1
        end
    end
    if goalpos ~= 0 and currentpos ~= goalpos then
        local leaderunit = group[currentpos]
        if currentpos > goalpos then -- leader is currently after the goal position
            for i=currentpos, goalpos+1, -1 do
                group[i] = group[i-1] -- move everyone one position back
            end
        else -- leader is currently before the goal position
            for i=currentpos, goalpos-1 do
                group[i] = group[i+1] -- move everyone one position forward
            end
        end
        group[goalpos] = leaderunit
    end
    return group
end

function NSI:ArrangeGroups(firstcall, finalcheck)
    if not firstcall and not self.Groups.Processing then return end
    local now = GetTime()
    if firstcall then
        self:Print("Split Table Data:", self.Groups.units)
        self.Groups.Processing = true
        self.Groups.Processed = 0
        self.Groups.ProcessStart = now
        for i=1, 40 do
            local group = math.ceil(i/5)
            local subgrouppos = i % 5 == 0 and 5 or i % 5
            if self.Groups.units[i] then
                self.Groups.units[i].group = group
                self.Groups.units[i].subgrouppos = subgrouppos
                self.Groups.units[i].pos= ((group-1)*5)+subgrouppos
            end
        end
    end
    if self.Groups.ProcessStart and now > self.Groups.ProcessStart+15 then self.Groups.Processing = false return end -- backup stop if it takes super long we're probably in a loop somehow
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

    if self.Groups.Processed >= self.Groups.total then
        if finalcheck then
            local allprocessed = true
            for i=1, 40 do
                local v = self.Groups.units[i]
                if v then
                    local index = UnitInRaid(v.name)
                    if postoindex[v.pos] ~= index then
                        v.processed = false
                        allprocessed = false
                        self.Groups.Processed = self.Groups.Processed-1
                    end
                end
            end
            if allprocessed then
                self.Groups.Processing = false
                return
            end
        else
            self:ArrangeGroups(false, true)
            return
        end
    end

    for i=1, 40 do -- position in table is where the player should end up in
        local v = self.Groups.units[i]
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
                                local u = self.Groups.units[j]
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
                    self.Groups.Processed = self.Groups.Processed+1
                    break
                else -- the 2 players to swap are in the same group so we instead swap with someone else
                    local found = false
                    local u = self.Groups.units[indexlink[index].pos] -- first try to swap with the person who is meant to be in the position this player is in
                    if u and (not UnitAffectingCombat(u.name)) and (not UnitIsUnit(v.name, u.name)) and u.pos == indexlink[index].pos and indexlink[index].subgroup ~= indexlink[UnitInRaid(u.name)].subgroup then
                        SwapRaidSubgroup(UnitInRaid(u.name), index)
                        found = true
                    end
                    if not found then -- next try to swap with someone who is not in the correct position yet
                        for j=1, 40 do
                            local u = self.Groups.units[j]
                            if u and (not u.processed) and (not UnitAffectingCombat(u.name)) and (not UnitIsUnit(v.name, u.name)) and indexlink[index].subgroup ~= indexlink[UnitInRaid(u.name)].subgroup then
                                SwapRaidSubgroup(UnitInRaid(u.name), index)
                                found = true
                                break
                            end
                        end
                    end
                    if not found then -- if we were somehow unable to find anyone we can swap this person with, swap them with someone who was already processed but not the raid leader
                        for j=1, 40 do
                            local u = self.Groups.units[j]
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
                self.Groups.Processed = self.Groups.Processed+1
                self:ArrangeGroups(false, finalcheck)
                break
            end
        end
    end
end

function NSI:SplitGroupInit(Flex, default, odds)
    if C_ChatInfo.InChatMessagingLockdown() then print("Addon Messages are currently restricted and thus this action cannot be performed") return end
    if UnitIsGroupAssistant("player") or UnitIsGroupLeader("player") and UnitInRaid("player") then
        local now = GetTime()
        if self.Groups.Processing and self.Groups.ProcessStart and now < self.Groups.ProcessStart + 15 then print("there is still a group process going on, please wait") return end
        if not self.LastGroupSort or self.LastGroupSort < now - 5 then
            self.LastGroupSort = GetTime()
            self.specs = {}
            NSI:Broadcast("NSI_SPEC_REQUEST", "RAID", "nilcheck")
            local difficultyID = select(3, GetInstanceInfo()) or 0
            if difficultyID == 16 then Flex = false else Flex = true end
            C_Timer.After(2, function() self:SortGroup(Flex, default, odds) end)
        else
            print("You hit the spam protection for sorting groups, please wait at least 5 seconds between pressing the button.")
        end
    end
end

local DF = _G["DetailsFramework"]
NSI.RaidBuffCheck = DF:CreateSimplePanel(UIParent, 300, 300, "[NSRT] Missing Raid Buffs",
        "NSIRaidBuffFrame", {
        })
NSI.RaidBuffCheck:Hide()
local MissingBuffLabel = DF:CreateLabel(NSI.RaidBuffCheck, "", 14)
MissingBuffLabel:SetPoint("TOPLEFT", NSI.RaidBuffCheck, "TOPLEFT", 2, -60)


local className = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER"}
local MissingTexts = {"Battle Shout", "Devotion Aura", "Hunter's Mark", "Rogue Poison", "Stamina", "Grip/AS Slow", "Skyfury", "Intellect", "Warlock", "Phys Debuff", "Mark of the Wild", "Magic Debuff", "Evoker"}
function NSI:UpdateRaidBuffFrame()
    if not NSRT.Settings.MissingRaidBuffs or not UnitInRaid("player") or not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or NSRT.Settings.Debug) then
        self.RaidBuffCheck:Hide()
        return
    end
    local RaidFrame = FriendsFrame:IsShown() and FriendsFrameTab3:IsShown() and PanelTemplates_GetSelectedTab(FriendsFrame) == 3
    if PVEFrame:IsShown() and PanelTemplates_GetSelectedTab(PVEFrame) == nil then -- first time opening PVE frame, tab info is not yet available
        C_Timer.After(0.1, function() NSI:UpdateRaidBuffFrame() end)
        return
    end
    local LFGFrame = PVEFrame:IsShown() and PanelTemplates_GetSelectedTab(PVEFrame) == 1
    local parent = (LFGFrame and PVEFrame) or (RaidFrame and PVEFrame:IsShown() and PVEFrame) or (RaidFrame and FriendsFrame) or nil
    if parent then
        self.RaidBuffCheck:ClearAllPoints()
        self.RaidBuffCheck:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, -1)
        self.RaidBuffCheck:SetHeight(parent:GetHeight()*parent:GetScale()-4)
        self.RaidBuffCheck:Show()
        local count = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        -- Automatically detect difficulty if player is zoned in a Raid, otherwise use the setting
        local maxgroup = NSRT.Settings.FlexRaid and 6 or 4
        for unit in self:IterateGroupMembers() do
            local group = self:GetSubGroup(unit)
            if group <= maxgroup then
                local class = select(3, UnitClass(unit))
                count[class] = count[class] + 1
            end
        end
        local text = ""
        local resscount = 0
        local lustcount = 0
        for i=1, #count do
            if i == 2 or i == 6 or i == 9 or i == 11 then
                resscount = resscount + count[i]
            end
            if i == 3 or i == 7 or i == 8 or i == 13 then
                lustcount = lustcount + count[i]
            end
            if count[i] == 0 then
                text = text..GetClassColorObj(className[i]):WrapTextInColorCode("Missing "..MissingTexts[i].."\n")
            end
        end
        if resscount > 0 then
            text = text.."Available Resses: "..resscount.."\n"
        else
            text = text.."|cFFFF0000No Resses Available\n|r"
        end
        if lustcount > 0 then
            text = text.."Available Lusts: "..lustcount.."\n"
        else
            text = text.."|cFFFF0000No Lusts Available\n|r"
        end
        if count[4] == 1 then
            text = text..GetClassColorObj(className[4]):WrapTextInColorCode("Only 1 Rogue Poison\n")
        end
        if count[13] > 0 then
            text = text..GetClassColorObj(className[13]):WrapTextInColorCode("Time Spirals: "..count[13].."\n")
        end
        if count[9] > 0 then
            text = text..GetClassColorObj(className[9]):WrapTextInColorCode("Gateways: "..count[9].."\n")
        end
        MissingBuffLabel:SetText(text)
    else
        self.RaidBuffCheck:Hide()
    end
end

FriendsFrame:HookScript("OnShow", function() NSI:UpdateRaidBuffFrame() end)
FriendsFrame:HookScript("OnHide", function() NSI:UpdateRaidBuffFrame() end)
PVEFrame:HookScript("OnShow", function() NSI:UpdateRaidBuffFrame() end)
PVEFrame:HookScript("OnHide", function() NSI:UpdateRaidBuffFrame() end)
PVEFrameTab1:HookScript("OnClick", function() NSI:UpdateRaidBuffFrame() end)
PVEFrameTab2:HookScript("OnClick", function() NSI:UpdateRaidBuffFrame() end)
PVEFrameTab3:HookScript("OnClick", function() NSI:UpdateRaidBuffFrame() end)
FriendsFrameTab1:HookScript("OnClick", function() NSI:UpdateRaidBuffFrame() end)
FriendsFrameTab2:HookScript("OnClick", function() NSI:UpdateRaidBuffFrame() end)
FriendsFrameTab3:HookScript("OnClick", function() NSI:UpdateRaidBuffFrame() end)
FriendsFrameTab4:HookScript("OnClick", function() NSI:UpdateRaidBuffFrame() end)

function NSI:InviteFromReminder(str, init)
    local list = NSRT.InviteList[str]
    if list and not self:Restricted() then
        self.CurrentInviteList = list
        self.InviteInProgress = true
        self:InviteList(list)
        if self.InviteTimer then
            self.InviteTimer:Cancel()
            self.InviteTimer = nil
        end
        self.InviteTimer = C_Timer.NewTimer(10, function()
            self.InviteInProgress = nil
        end)
    end
end

function NSI:InviteList(list)
    if not list then return end
    local myrealm = GetRealmName()
    for _, name in ipairs(list) do
        local fullname = ""
        local name, realm = strsplit("-", name)
        if realm == nil or realm == "" or realm == myrealm then
            fullname = name
        else
            fullname = name.."-"..realm
        end
        if (not UnitIsUnit("player", fullname)) and (not UnitInRaid(fullname)) then
            C_PartyInfo.InviteUnit(fullname)
        end
    end
end

function NSI:ArrangeFromReminder(str)
    if self.Groups and self.Groups.Processing and self.Groups.ProcessStart and now < self.Groups.ProcessStart + 15 then print("there is still a group process going on, please wait") return end
    local now = GetTime()
    if self.LastGroupSort and self.LastGroupSort > now - 5 then
        print("You hit the spam protection for sorting groups, please wait at least 5 seconds between pressing the button.")
        return
    end
    self.LastGroupSort = now
    local list = NSRT.InviteList[str]
    self.Groups = {}
    self.Groups.Processing = false
    self.Groups.units = {}
    self.Groups.total = 0
    if self:Restricted() then print("You are currently in combat, cannot sort groups right now.") return end
    if not list then print("No invite list found.") return end
    for i, name in ipairs(list) do
        self.Groups.units[i] = {name = name}
        self.Groups.total = self.Groups.total + 1
    end
    self:ShiftLeader(self.Groups.units)
    self:ArrangeGroups(true)
end