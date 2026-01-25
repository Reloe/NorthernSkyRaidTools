local _, NSI = ... -- Internal namespace

local minlvl = 200

local buffs = {
    [1] = 6673, -- Battle Shout
    [5] = 21562, -- Stamina
    [7] = 462854, -- Skyfury
    [8] = 1459, -- Intellect
    [9] = 20707, -- Soulstone
    [11] = 1126, -- Mark of the Wild
    [13] = {381741, 381757, 381756, 381732, 381752, 381748, 381750, 381749, 381746, 381751, 381753, 381754, 381758}, -- Evoker Buff, every class has a different buffid for some annoying reason.
}

local buffrequired = {
    [1] = {1, 2, 3, 4, 6, 7, 10, 11, 12, 250, 251, 252, 577, 581, 103, 104, 253, 254, 255, 268, 269, 66, 70, 259, 260, 261, 263, 71, 72, 73}, -- Battle Shout
    [8] = {2, 5, 7, 8, 9, 10, 11, 12, 13, 1480, 102, 105, 1467, 1468, 1473, 62, 63, 64, 270, 65, 256, 257, 258, 262, 264, 265, 266, 267}, -- Intellect
}

function NSI:SoulstoneCheck()
    if self:Restricted() then return end
    local class = select(3, UnitClass("player"))
    if class ~= 9 then return end
    local cooldown = C_Spell.GetSpellCooldown(20707)
    local timeRemaining = cooldown and cooldown.duration ~= 0 and cooldown.duration + cooldown.startTime - GetTime()
    if timeRemaining and timeRemaining > 30 then return false end -- only check if soulstone is ready or about to be ready
    local buffed = false
    local refresh = false
    for unit in self:IterateGroupMembers() do
        if UnitGroupRolesAssigned(unit) == "HEALER" and UnitIsVisible(unit) then
            local aura = self:UnitAura(unit, buffs[class])
            if aura then
                local source = aura.sourceUnit
                if UnitExists(source) and UnitIsUnit("player", source) then
                    local expires = aura.expirationTime
                    if expires - GetTime() > 300 then
                        buffed = true
                        return false
                    else
                        refresh = true
                    end
                end
            end
        end
    end
    NSAPI:TTS("Soulstone")
    return refresh and "Refresh Soulstone" or "|cFFFF0000Soulstone Missing|r"
end

function NSI:BuffCheck()
    if self:Restricted() then return end
    local class = select(3, UnitClass("player"))
    local spellID = buffs[class]    
    if spellID then
        for unit in self:IterateGroupMembers() do
            local specID = self.specs and self.specs[unit] or select(3, UnitClass(unit)) -- if specdata exists we use that, otherwise class which means maybe some useless buffs are being done.
            if specID and (class == 5 or class == 13 or class == 11 or class == 7 or tContains(buffrequired[class], specID)) then
                local buffed
                if type(spellID) == "table" then -- for Evoker Buff
                    for i=1, #spellID do
                        buffed = self:UnitAura(unit, spellID[i])
                        if buffed then break end
                    end
                else
                    buffed = self:UnitAura(unit, spellID)
                end
                if buffed then
                    local source = buffed.sourceUnit
                    if (not (UnitExists(source)) and (UnitIsVisible(source))) and not (UnitIsUnit("player", source)) then
                        -- this means someone has the buff but it's from another player that is no longer in the raid so the buff would disappear on pull.
                        local name = C_Spell.GetSpellInfo(spellID).name
                        NSAPI:TTS("Rebuff "..name)
                        return "|cFFFF0000Rebuff:|r |cFF00FF00"..name.."|r"
                    end
                elseif buffed ~= "" then
                    if type(spellID) == "table" then
                        spellID = spellID[1] -- use first entry as they all have the same name anyway
                    end
                    local spellInfo = C_Spell.GetSpellInfo(spellID)
                    local name = spellInfo and spellInfo.name or ""
                    NSAPI:TTS("Rebuff "..name)
                    return "|cFFFF0000Rebuff:|r |cFF00FF00"..name.."|r"
                end     
            end       
        end
    end
    return false
end

local SlotName = {
    "Head",      --  1
    "Neck",      --  2
    "Shoulder",  --  3
    "Shirt",     --  4
    "Chest",     --  5
    "Waist",     --  6
    "Legs",      --  7
    "Feet",      --  8
    "Wrist",     --  9
    "Hands",     -- 10
    "Finger 1",  -- 11
    "Finger 2",  -- 12 
    "Trinket 1", -- 13
    "Trinket 2", -- 14
    "Back",      -- 15
    "Main Hand", -- 16
    "Off Hand"   -- 17
}

function NSI:GemCheck(slot, itemString)    
    local gemsMissing = 0
    if slot == 2 or slot == 11 or slot == 12 then
        gemsMissing = 1
    end
    if itemString then
        for key, num in pairs(C_Item.GetItemStats(itemString)) do
            if (string.find(key, "EMPTY_SOCKET_")) then
                for i = 1, num do
                    local gem = C_Item.GetItemGem(itemString,i)
                    if gem then
                        if string.find(gem, "Eversong Diamond") then -- Midnight Primary Stat Gem
                            self.MainstatGem = true
                        end
                        gemsMissing = gemsMissing -1
                    end
                    if not gem then
                        gemsMissing = gemsMissing + 1
                    end
                end
            end
        end
        return gemsMissing > 0
    else
        return false
    end
end

function NSI:EnchantCheck(slot, itemString)
    local enchantedSlots = {3, 5, 7, 8, 11, 12, 16, 17}    
    if tContains(enchantedSlots, slot) and itemString then 
        if slot == 17 and select(12, C_Item.GetItemInfo(itemString)) == 4 then return false end -- skip shield/offhand
        local link = select(2, C_Item.GetItemInfo(itemString))
        local _, enchant = link:match("item:(%d+):(%d+)")
        if enchant then return false else return true end        
    else
        return false
    end
end

function NSI:GearCheck()          
    local missing = {}
    local crafted = 0
    local tier = 0
    local repair = false
    local spec = GetSpecializationInfo(GetSpecialization())
    local ilvl = UnitLevel("player") >= 90 and minlvl or 100
    self.MainstatGem = false
    for slot = 1, #SlotName do
        local itemString = GetInventoryItemLink("player", slot)            
        if itemString then
            if NSRT.ReadyCheckSettings.CraftedCheck and string.find(itemString, "8960") then
                crafted = crafted+1
            end
            if NSRT.ReadyCheckSettings.EnchantCheck and UnitLevel("player") >= 90 and self:EnchantCheck(slot,itemString) then
                table.insert(missing, "Missing Enchant on: |cFF00FF00"..SlotName[slot].."|r")        
            end                
            if NSRT.ReadyCheckSettings.GemCheck and UnitLevel("player") >= 90 and self:GemCheck(slot, itemString) then
                table.insert(missing, "Missing Gem in: |cFF00FF00"..SlotName[slot].."|r")
            end                
            if NSRT.ReadyCheckSettings.ItemLevelCheck and slot ~= 4 and select(4, C_Item.GetItemInfo(itemString)) < ilvl then
                table.insert(missing, "Low Itemlvl equipped on: |cFF00FF00"..SlotName[slot].."|r")
            end
            if NSRT.ReadyCheckSettings.RepairCheck and not repair then
                local min, max = GetInventoryItemDurability(slot)
                if min and min/max <= 0.2 then
                    repair = true
                end
            end   
            if NSRT.ReadyCheckSettings.TierCheck then
                if self:TierCheck(slot) then
                    tier = tier+1
                end
            end
        elseif NSRT.ReadyCheckSettings.MissingItemCheck and slot ~= 4 then  
            if slot == 17 then
                itemString = GetInventoryItemLink("player", 16)
                local type = itemString and select(13, C_Item.GetItemInfo(itemString)) or ""
                local onehand = {0, 4, 7, 9, 11, 12, 13, 15, 19}
                if tContains(onehand, type) or spec == 72 then -- only check offhand if mainhand is a onehand or player is a fury warrior
                    table.insert(missing, "|cFFFF0000Not equipped:|r |cFF00FF00"..SlotName[slot].."|r")                        
                end
            else
                table.insert(missing, "|cFFFF0000Not equipped:|r |cFF00FF00"..SlotName[slot].."|r")
            end
        end
    end
    -- Gateway Control Shard
    if NSRT.ReadyCheckSettings.GatewayShardCheck then
        local Gateway = self:GatewayControlCheck()
        if Gateway then table.insert(missing, Gateway) end
    end
    if UnitLevel("player") >= 90 and NSRT.ReadyCheckSettings.GemCheck and not self.MainstatGem then
        table.insert(missing, "Missing |cFF00FF00Mainstat Gem|r")
    end
    if repair then
        table.insert(missing, "Item needs |cFF00FF00Repair|r")
    end
    if NSRT.ReadyCheckSettings.CraftedCheck and crafted < 2 then
        table.insert(missing, "Missing |cFF00FF00Embellishment|r")
    end
    if NSRT.ReadyCheckSettings.TierCheck and tier < 4 then
        if tier < 2 then
            table.insert(missing, "|cFFFF0000No Set Bonus equipped|r")
        else
            table.insert(missing, "|cFFFF0000Only 2pc equipped|r")
        end
    end
    local text = ""
    for i=1, #missing do
        text = text..missing[i].."\n"
    end  
    return text
end

function NSI:GatewayControlCheck()
    for bagID = 0, NUM_BAG_SLOTS do
        for invID = 1, C_Container.GetContainerNumSlots(bagID) do
            local itemID = C_Container.GetContainerItemID(bagID, invID)
            if itemID and itemID == 188152 then -- Gateway Shard found
                local bound = false
                local onbar = false
                for Slot = 1, 120 do
                    local actionType, ID = GetActionInfo(Slot)
                    if actionType == "item" and ID == itemID then -- found on actionbar
                        onbar = true
                        bound = self:CheckGateWayKeybind(Slot)
                        if bound then break end
                    end
                end
                if bound then
                    return false
                elseif onbar then
                    return "|cFF00FF00Gateway Control Shard|r Not Bound"
                else
                    return "|cFF00FF00Gateway Control Shard|r Not on Actionbar"
                end
            end
        end
    end
    return "|cFF00FF00Gateway Control Shard|r Missing"
end

function NSI:CheckGateWayKeybind(Slot)    
    if Slot <= 12 then -- First bar has different name
        return GetBindingKey("ACTIONBUTTON"..Slot)
    else
        -- Define correct slot on bar
        local bar = math.ceil((Slot) / 12)
        local mod = Slot % 12 == 0 and 12 or Slot % 12
        return GetBindingKey("MULTIACTIONBAR"..bar.."BUTTON"..mod)
    end
end

local validsets = { 
    -- Manaforge Sets
    [1921] = true, -- Druid
    [1923] = true, -- Hunter
    [1924] = true, -- Mage
    [1926] = true, -- Paladin
    [1927] = true, -- Priest
    [1928] = true, -- Rogue
    [1929] = true, -- Shaman
    [1930] = true, -- Warlock
    [1931] = true, -- Warrior
    [1919] = true, -- Death Knight
    [1920] = true, -- Demon Hunter
    [1925] = true, -- Monk
    [1922] = true, -- Evoker
    
    -- Midnight S1
    [1980] = true, -- Druid
    [1982] = true, -- Hunter
    [1983] = true, -- Mage
    [1985] = true, -- Paladin
    [1986] = true, -- Priest
    [1987] = true, -- Rogue
    [1988] = true, -- Shaman
    [1989] = true, -- Warlock
    [1990] = true, -- Warrior
    [1978] = true, -- Death Knight
    [1979] = true, -- Demon Hunter
    [1984] = true, -- Monk
    [1981] = true, -- Evoker
}

function NSI:TierCheck(Slot)
    local tier = 0
    local itemLink = GetInventoryItemLink("player", Slot)
    if itemLink then
        local setID = select(16, C_Item.GetItemInfo(itemLink))
        if setID and validsets[setID] then
            return true
        end
    end
end