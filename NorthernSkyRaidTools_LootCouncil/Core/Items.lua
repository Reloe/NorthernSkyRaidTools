-- ============================================================
--  Core/Items.lua - link decoding, difficulty mapping, trade keys, eligibility
--
--  Owns: item-link decode, ItemContext -> DifficultyID, trade keys, slot lookup, class
--  eligibility (armor type, weapon type and main stat, "Classes:" lines; tables in Data/ItemRules.lua)
--  and the equipped-gear snapshot. Decode, keys, mapping and the eligibility rules are pure
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

-- ---- can this class use it? -------------------------------------------------------------------------
-- Four independent rules, each answering true (usable), false (never usable by this class) or nil (not judged / cannot
-- tell). The tables behind them live in Data/ItemRules.lua. A drop counts as unusable only when a rule says false, so a
-- missing table, an unloaded item or an unknown subclass can keep a roll window open but never passes on a usable item.
--   1. the "Classes: ..." line printed on the item (class-locked gear and tier tokens)   Items.AllowedClasses
--   2. armor type (cloth / leather / mail / plate, and shields)                           Items.ArmorEligible
--   3. weapon type (axe, dagger, staff, ...)                                              Items.WeaponEligible
--   4. weapon main stat (an agility dagger is no use to a priest)                         Items.WeaponEligible
--   5. trinkets (does any spec of the class use it? asked of the game, no data kept)       Items.TrinketUsable

-- Slots that take any armor type.
local ANY_ARMOR = { INVTYPE_CLOAK = true, INVTYPE_FINGER = true, INVTYPE_NECK = true, INVTYPE_TRINKET = true }

local MAIN_STATS = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_INTELLECT_SHORT" }

local function Rules()
    return LC.ItemRules or {}
end

local function KnownClass(classToken)
    local stats = Rules().weaponMainStats
    return stats ~= nil and stats[classToken] ~= nil
end

-- Armor items only (classID 4). Weapons and everything else return nil so the other rules decide.
function Items.ArmorEligible(classToken, equipLoc, classID, subClassID)
    if classID ~= 4 then return nil end
    if ANY_ARMOR[equipLoc] then return true end
    if subClassID == 0 or subClassID == nil then return true end   -- generic armor (e.g. tokens)
    local users = Rules().armorUsers and Rules().armorUsers[subClassID]
    if not users or not KnownClass(classToken) then return nil end
    return users[classToken] == true
end

-- Does a weapon carry a main stat this class wants? stats is C_Item.GetItemStats' table (nil = not loaded).
-- true = it has a stat the class wants, or no main stat at all; false = main stats, none of them wanted; nil = unknown.
local function WantsMainStat(classToken, stats, itemID)
    local wanted = Rules().weaponMainStats and Rules().weaponMainStats[classToken]
    if not wanted or type(stats) ~= "table" then return nil end
    local hasMain = false
    for _, stat in ipairs(MAIN_STATS) do
        if stats[stat] then hasMain = true break end
    end
    if not hasMain then return true end
    for _, stat in ipairs(wanted) do
        if stats[stat] then return true end
    end
    -- a few weapons can be converted to another main stat (Season.weaponStatOverrides: [itemID] = { stat, ... })
    local extra = LC.Season and LC.Season.weaponStatOverrides and itemID and LC.Season.weaponStatOverrides[itemID]
    for _, stat in ipairs(extra or {}) do
        for _, w in ipairs(wanted) do
            if stat == w then return true end
        end
    end
    return false
end

-- Weapons only (classID 2). The weapon type decides first and needs no item data; the main stat is only looked at
-- for a type the class can wield. Weapon types that are not listed (thrown, fishing pole, ...) are not judged.
function Items.WeaponEligible(classToken, subClassID, stats, itemID)
    local users = Rules().weaponUsers and Rules().weaponUsers[subClassID]
    if not users or not KnownClass(classToken) then return nil end
    if not users[classToken] then return false end
    return WantsMainStat(classToken, stats, itemID)
end

-- Trinkets: asks the game whether any spec of the class can use it (the same loot rules the Encounter Journal
-- shows), so nothing has to be listed each season. true / false / nil. nil whenever the answer is not trustworthy:
-- the item data is not loaded yet (a request is sent, so a later pass can judge it), the call is missing, errors or
-- returns a secret or non-boolean value. Works for any class token, not only the player's.
function Items.TrinketUsable(classToken, item)
    local classID = Rules().classIDs and Rules().classIDs[classToken]
    if not (classID and item and C_Item and C_Item.DoesItemContainSpec) then return nil end
    local itemID = tonumber(item) or Items.IDFromLink(item)
    if C_Item.IsItemDataCachedByID and itemID and not C_Item.IsItemDataCachedByID(itemID) then
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
        return nil
    end
    local ok, result = pcall(C_Item.DoesItemContainSpec, item, classID)
    if not ok or type(result) ~= "boolean" then return nil end
    if LC.Restrict and LC.Restrict.IsSecret(result) then return nil end
    return result
end

-- Pure combination of the rules. facts = { itemID, equipLoc, classID, subClassID, stats, trinketUsable, allowed } where
-- allowed is the set from the item's "Classes:" line (nil = no such line, or not readable) and trinketUsable is the
-- answer of Items.TrinketUsable. Returns true / false / nil.
function Items.Judge(classToken, facts)
    local judged = false
    if facts.allowed then
        if not facts.allowed[classToken] then return false end
        judged = true
    end
    local verdict
    if facts.equipLoc == "INVTYPE_TRINKET" then
        verdict = facts.trinketUsable
    elseif facts.classID == 4 then
        verdict = Items.ArmorEligible(classToken, facts.equipLoc, facts.classID, facts.subClassID)
    elseif facts.classID == 2 then
        verdict = Items.WeaponEligible(classToken, facts.subClassID, facts.stats, facts.itemID)
    end
    if verdict == false then return false end
    if verdict == true or judged then return true end
    return nil
end

-- ---- the "Classes:" line --------------------------------------------------------------------------------
-- Pure: "Mage, Warlock" -> { MAGE = true, WARLOCK = true }, given classByName = { ["Mage"] = "MAGE", ... }. Returns
-- nil when no name can be read, so an unreadable line never locks anybody out.
function Items.ParseClassList(text, classByName)
    if type(text) ~= "string" or not classByName then return nil end
    local set, any = {}, false
    for name in (text .. ", "):gmatch("(.-), ") do
        name = name:match("^%s*(.-)%s*$")
        local token = classByName[name]
        if token then set[token] = true; any = true end
    end
    return any and set or nil
end

-- Pure: the list part of a tooltip line, or nil when the line is not the "Classes:" line. template is the client's
-- ITEM_CLASSES_ALLOWED ("Classes: %s" in English), which is why this works in every language.
function Items.MatchClassLine(text, template)
    if type(text) ~= "string" or type(template) ~= "string" then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local escaped = template:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
    local pattern = "^" .. escaped:gsub("%%%%s", "(.+)") .. "$"
    return text:match(pattern)
end

local classByName
local function ClassByName()
    if classByName then return classByName end
    classByName = {}
    for _, names in ipairs({ _G.LOCALIZED_CLASS_NAMES_MALE or {}, _G.LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
        for token, name in pairs(names) do classByName[name] = token end
    end
    return classByName
end

local allowedCache = {}      -- [itemID] = set, or false when the item has no class line (only filled once the tooltip had text)

-- The set of class tokens the item is restricted to, or nil when it has no restriction or the tooltip cannot be read
-- yet. Read from the tooltip (the same line the game prints), so new class-locked items need no data from us.
function Items.AllowedClasses(item)
    local itemID = tonumber(item) or Items.IDFromLink(item)
    if not itemID then return nil end
    local cached = allowedCache[itemID]
    if cached ~= nil then return cached or nil end
    if not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then return nil end
    local ok, info = pcall(C_TooltipInfo.GetHyperlink, "item:" .. itemID)
    if not ok or type(info) ~= "table" or type(info.lines) ~= "table" or #info.lines == 0 then return nil end
    local template = _G.ITEM_CLASSES_ALLOWED
    local result = false
    for _, line in ipairs(info.lines) do
        local text = line.leftText
        if type(text) == "string" and not (LC.Restrict and LC.Restrict.IsSecret(text)) then
            local list = Items.MatchClassLine(text, template)
            if list then
                result = Items.ParseClassList(list, ClassByName()) or false
                break
            end
        end
    end
    allowedCache[itemID] = result
    return result or nil
end

-- ---- game-API side of the rules -------------------------------------------------------------------------
-- A tier token is a Miscellaneous item with no armor type of its own; Season.tokenArmor says which armor it stands for
-- (1 cloth .. 4 plate). nil for anything else, omni tokens included.
function Items.TokenArmorType(itemID)
    local list = LC.Season and LC.Season.tokenArmor
    return itemID and list and list[itemID] or nil
end

-- Can this class use the drop? item is an item ID, a link or an item string. true / false / nil (cannot tell).
function Items.UsableBy(classToken, item)
    if not (classToken and item) then return nil end
    local itemID, _, _, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(item)
    if not itemID then return nil end
    local tokenType = Items.TokenArmorType(itemID)
    if tokenType then classID, subClassID = 4, tokenType end      -- a token is judged like the armor it turns into
    local stats
    if classID == 2 and C_Item.GetItemStats then
        local ok, got = pcall(C_Item.GetItemStats, type(item) == "number" and ("item:" .. item) or item)
        stats = ok and type(got) == "table" and got or nil
    end
    local trinketUsable                       -- not "cond and x or nil": that would turn false into nil
    if equipLoc == "INVTYPE_TRINKET" then trinketUsable = Items.TrinketUsable(classToken, item) end
    return Items.Judge(classToken, {
        itemID = itemID, equipLoc = equipLoc, classID = classID, subClassID = subClassID,
        stats = stats, allowed = Items.AllowedClasses(item),
        trinketUsable = trinketUsable,
    })
end

-- Can my class use this drop? Anything the rules cannot tell counts as usable, so this can wrongly keep a roll window
-- open but never passes on something you could have used.
function Items.CanUse(item)
    local token = select(2, UnitClass("player"))
    return Items.UsableBy(token, item) ~= false
end

-- ---- item info ------------------------------------------------
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
    if not diff and d then
        -- not a raid drop (Catalyst, upgraded, crafted): read it from the bonus IDs, upgrade track first
        local season = LC.Season or {}
        for _, map in ipairs({ season.trackBonus or {}, season.difficultyTagBonus or {} }) do
            for _, b in ipairs(d.bonusIDs) do
                if map[b] then diff = map[b] break end
            end
            if diff then break end
        end
    end
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
