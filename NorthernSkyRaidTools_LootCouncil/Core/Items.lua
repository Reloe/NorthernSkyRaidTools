-- ============================================================
--  Core/Items.lua - link decoding, difficulty mapping, trade keys, eligibility
--
--  Owns: item-link decode, ItemContext -> DifficultyID, trade keys, slot lookup, class
--  armor eligibility and the equipped-gear snapshot. Decode, keys and mapping are pure
--  (specs in tools/lc-tests). Identity is never a link string (PRD 5.4 rule 4): awards are
--  matched by Drop ID, bag items by trade key.
--
--  The field bird calls "instanceDifficultyID" is the ItemContext (Enum.ItemCreationContext),
--  not a DifficultyID. The two scales are never compared directly (C-6).
-- ============================================================
local ADDON, LC = ...
local Items = {}
LC.Items = Items

local tonumber, tostring, type = tonumber, tostring, type

-- Enum.ItemCreationContext (documented): 3 RaidNormal, 4 RaidFinder, 5 RaidHeroic, 6 RaidMythic.
Items.ContextToDifficulty = { [3] = 14, [4] = 17, [5] = 15, [6] = 16 }
Items.DifficultyName = { [14] = "Normal", [15] = "Heroic", [16] = "Mythic", [17] = "LFR" }
Items.RaidDifficulties = { [14] = true, [15] = true, [16] = true, [17] = true }

-- "item:ID:ench:g1:g2:g3:g4:suffix:unique:linkLevel:spec:modMask:context:numBonus:bonus..."
-- accepts a full hyperlink or a bare item string. Returns nil for anything else.
function Items.Decode(link)
    if type(link) ~= "string" then return nil end
    local str = link:match("|Hitem:([^|]+)|h") or link:match("^item:([^|]+)$") or link:match("^(%d[%d:]*)$")
    if not str then return nil end
    local f = {}
    local i = 1
    for field in (str .. ":"):gmatch("([^:]*):") do
        f[i] = field
        i = i + 1
    end
    local itemID = tonumber(f[1])
    if not itemID then return nil end
    local numBonus = tonumber(f[13]) or 0
    local bonus = {}
    for b = 1, numBonus do
        local v = tonumber(f[13 + b])
        if v then bonus[#bonus + 1] = v end
    end
    return {
        itemID = itemID,
        context = tonumber(f[12]),
        modifiersMask = tonumber(f[11]),
        specID = tonumber(f[10]),
        bonusIDs = bonus,
        itemString = "item:" .. str,
    }
end

-- How well a bag item's bonus IDs match the dropped item's (pure). 2 = same set, between 1 and 2 = some
-- bonus IDs in common (1 + shared / union), 1 = nothing to compare (the drop carried no bonus IDs, or a
-- link could not be read). Used only to choose between bag items that already match item ID and difficulty.
function Items.BonusScore(bagLink, wantItem)
    local want = Items.Decode(wantItem)
    if not want or #want.bonusIDs == 0 then return 1 end
    local have = Items.Decode(bagLink)
    if not have then return 1 end
    local wanted, seen = {}, {}
    local shared, union = 0, 0
    for _, b in ipairs(want.bonusIDs) do
        if not wanted[b] then wanted[b] = true; union = union + 1 end
    end
    local wantCount = union
    for _, b in ipairs(have.bonusIDs) do
        if not seen[b] then
            seen[b] = true
            if wanted[b] then shared = shared + 1 else union = union + 1 end
        end
    end
    if shared == wantCount and union == wantCount then return 2 end
    return 1 + shared / union
end

function Items.IDFromLink(link)
    local d = Items.Decode(link)
    return d and d.itemID or nil
end

-- Raid DifficultyID of a link (14/15/16/17), or nil when the context is not a raid one.
function Items.DifficultyFromLink(link)
    local d = Items.Decode(link)
    return d and Items.ContextToDifficulty[d.context] or nil
end

-- "itemID/difficulty"; difficulty nil or 0 means any difficulty.
function Items.TradeKey(itemID, difficulty)
    return tostring(itemID) .. "/" .. tostring((difficulty and difficulty > 0) and difficulty or 0)
end

function Items.KeyFromLink(link)
    local d = Items.Decode(link)
    if not d then return nil end
    return Items.TradeKey(d.itemID, Items.ContextToDifficulty[d.context])
end

function Items.ParseKey(key)
    local id, diff = tostring(key):match("^(%d+)/(%d+)$")
    id, diff = tonumber(id), tonumber(diff)
    if not id then return nil end
    return id, (diff and diff > 0) and diff or nil
end

-- Does a bag item satisfy "itemID at difficulty" (nil difficulty = any)?
-- With a difficulty given, a bag item whose context is not a raid one never matches:
-- placing nothing beats placing the wrong thing (T-2).
function Items.BagMatches(bagLink, itemID, difficulty)
    local d = Items.Decode(bagLink)
    if not d or d.itemID ~= itemID then return false end
    if not difficulty then return true end
    return Items.ContextToDifficulty[d.context] == difficulty
end

-- Drop ID: encounterID:killTime:itemID:index (PRD 6.1). Assigned by the ML only.
function Items.DropID(encounterID, killTime, itemID, index)
    return table.concat({ encounterID or 0, killTime or 0, itemID or 0, index or 1 }, ":")
end

function Items.ParseDropID(id)
    local e, k, i, n = tostring(id):match("^(%d+):(%d+):(%d+):(%d+)$")
    if not e then return nil end
    return { encounterID = tonumber(e), killTime = tonumber(k), itemID = tonumber(i), index = tonumber(n) }
end

-- ---- equip slots ---------------------------------------------
-- INVTYPE -> inventory slot ids (two for finger/trinket/one-hand weapons).
Items.EquipSlots = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 16 }, INVTYPE_RANGEDRIGHT = { 16 },
}

-- Armor class per class token (Enum.ItemArmorSubclass: 1 cloth, 2 leather, 3 mail, 4 plate).
Items.ClassArmor = {
    WARRIOR = 4, PALADIN = 4, DEATHKNIGHT = 4,
    HUNTER = 3, SHAMAN = 3, EVOKER = 3,
    ROGUE = 2, DRUID = 2, MONK = 2, DEMONHUNTER = 2,
    PRIEST = 1, MAGE = 1, WARLOCK = 1,
}

-- Slots that take any armor type.
local ANY_ARMOR = { INVTYPE_CLOAK = true, INVTYPE_FINGER = true, INVTYPE_NECK = true, INVTYPE_TRINKET = true }

-- true / false / nil (unknown). Armor items only; weapons and unknowns return nil so the
-- council decides. classID 4 = armor.
function Items.ArmorEligible(classToken, equipLoc, classID, subClassID)
    if classID ~= 4 then return nil end
    if ANY_ARMOR[equipLoc] then return true end
    if subClassID == 0 or subClassID == nil then return true end   -- generic armor (e.g. tokens)
    local want = Items.ClassArmor[classToken]
    if not want then return nil end
    if subClassID == 6 then return nil end                          -- shield: spec dependent
    return subClassID == want
end

-- Can my class use this drop? Only the armor-type rule is checked (ArmorEligible); weapons, rings, cloaks,
-- tokens and unknown items count as usable, so this can wrongly keep a roll window open but never passes
-- on something you could have used.
function Items.CanUse(itemID)
    local _, _, _, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
    if not classID then return true end
    local token = select(2, UnitClass("player"))
    return Items.ArmorEligible(token, equipLoc, classID, subClassID) ~= false
end

-- ---- game-API side --------------------------------------------
function Items.Info(link)
    if not (C_Item and C_Item.GetItemInfoInstant) then return nil end
    local itemID, _, _, equipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(link)
    if not itemID then return nil end
    return { itemID = itemID, equipLoc = equipLoc, icon = icon, classID = classID, subClassID = subClassID }
end

function Items.ItemLevel(link)
    if not link then return nil end
    local ilvl = C_Item.GetDetailedItemLevelInfo(link)
    return ilvl
end

-- Display link for an item string: the real hyperlink when item data is cached.
function Items.ToLink(itemString)
    if not itemString then return nil end
    local link = select(2, C_Item.GetItemInfo(itemString))
    return link
end

-- Calls fn(link) when item data is available (immediately if cached). Item:ContinueOnItemLoad is
-- event-driven, so nothing polls.
function Items.WhenLoaded(itemString, fn)
    local id = Items.IDFromLink(itemString)
    if not id then return end
    local link = Items.ToLink(itemString)
    if link then fn(link) return end
    if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    if Item and Item.CreateFromItemID then
        Item:CreateFromItemID(id):ContinueOnItemLoad(function() fn(Items.ToLink(itemString)) end)
    end
end

-- Item strings of what the player has equipped in the slots an item can go to.
-- Returns { { item = "item:...", ilvl = n }, ... } (at most two).
function Items.EquippedForEquipLoc(equipLoc)
    local out = {}
    local slots = Items.EquipSlots[equipLoc]
    if not slots then return out end
    for _, slot in ipairs(slots) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local d = Items.Decode(link)
            out[#out + 1] = { item = d and d.itemString or link, ilvl = C_Item.GetDetailedItemLevelInfo(link) }
        end
    end
    return out
end

-- ---- tier gear -------------------------------------------------------------------------------------
-- The five tier slots, in display order: key, inventory slot, equip locations that go in it.
Items.TierSlots = {
    { key = "HEAD",     slot = 1,  label = "Head",     locs = { INVTYPE_HEAD = true } },
    { key = "SHOULDER", slot = 3,  label = "Shoulder", locs = { INVTYPE_SHOULDER = true } },
    { key = "CHEST",    slot = 5,  label = "Chest",    locs = { INVTYPE_CHEST = true, INVTYPE_ROBE = true } },
    { key = "HANDS",    slot = 10, label = "Hands",    locs = { INVTYPE_HAND = true } },
    { key = "LEGS",     slot = 7,  label = "Legs",     locs = { INVTYPE_LEGS = true } },
}
local TIER_SLOT_OF_LOC = {}
for _, t in ipairs(Items.TierSlots) do
    for loc in pairs(t.locs) do TIER_SLOT_OF_LOC[loc] = t.key end
end

Items.DifficultyShort = { [17] = "LFR", [14] = "N", [15] = "H", [16] = "M" }

-- Short difficulty label of an item string or link (LFR / N / H / M), nil when it cannot be told.
function Items.DifficultyLabel(item)
    local d = Items.Decode(item)
    local diff = d and Items.ContextToDifficulty[d.context]
    return diff and Items.DifficultyShort[diff] or nil
end

-- Is this equippable item a piece of a class tier set? With Season.tierSetIDs filled in, only those sets
-- count; while it is empty, any item set piece in a tier slot does.
function Items.IsTier(item)
    if not item then return false end
    local _, _, _, loc = C_Item.GetItemInfoInstant(item)
    if not (loc and TIER_SLOT_OF_LOC[loc]) then return false end
    local setID = select(16, C_Item.GetItemInfo(item))
    if not setID or setID == 0 then return false end
    local ids = LC.Season and LC.Season.tierSetIDs
    if ids and next(ids) then return ids[setID] == true end
    return true
end

-- Which tier slot does a dropped item belong to? "HEAD".. "LEGS", "ANY" for an omni token, nil for anything
-- else. Handles tier pieces, exact tokens from Season.tierTokens, and tokens recognised by the boss that
-- dropped them (a non-equippable miscellaneous item) using Season.tokenSlotByBoss / omniTokenBosses.
function Items.TierSlotOfDrop(dropID, item, itemID)
    local season = LC.Season or {}
    itemID = itemID or Items.IDFromLink(item)
    local exact = itemID and season.tierTokens and season.tierTokens[itemID]
    if exact then return exact end
    local _, _, _, loc, _, classID = C_Item.GetItemInfoInstant(item or itemID)
    if loc and loc ~= "" then
        if TIER_SLOT_OF_LOC[loc] and Items.IsTier(item) then return TIER_SLOT_OF_LOC[loc] end
        return nil
    end
    if classID ~= 15 then return nil end                      -- tokens are miscellaneous items
    local enc = tonumber(tostring(dropID or ""):match("^(%d+):"))
    if not enc then return nil end
    if season.omniTokenBosses and season.omniTokenBosses[enc] then return "ANY" end
    return season.tokenSlotByBoss and season.tokenSlotByBoss[enc] or nil
end

-- What the player has in the five tier slots: { HEAD = "item:...", ... } (empty slots left out). Sent with the
-- response so the council always sees tier progress, whatever item is being rolled on.
function Items.TierGear()
    local out, any = {}, false
    for _, t in ipairs(Items.TierSlots) do
        local link = GetInventoryItemLink("player", t.slot)
        if link then
            local d = Items.Decode(link)
            out[t.key] = d and d.itemString or link
            any = true
        end
    end
    return any and out or nil
end

-- Number of equipped tier pieces (nil when no tier set can be recognised yet).
function Items.TierCount()
    local n = 0
    for _, t in ipairs(Items.TierSlots) do
        local link = GetInventoryItemLink("player", t.slot)
        if link and Items.IsTier(link) then n = n + 1 end
    end
    return n
end

-- ilvl and (when Season data exists) track-adjusted upgrade over the best equipped item.
-- Returns { ilvlDelta, trackDelta } with nils where unknown.
function Items.UpgradeInfo(itemLevel, equipped)
    local best
    for _, e in ipairs(equipped or {}) do
        if e.ilvl and (not best or e.ilvl < best) then best = e.ilvl end   -- compare to the weaker slot
    end
    local out = {}
    if itemLevel and best then out.ilvlDelta = itemLevel - best end
    return out
end
