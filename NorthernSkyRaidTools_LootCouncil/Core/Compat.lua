-- ============================================================
--  Core/Compat.lua - one wrapper per game API whose behaviour is not yet confirmed
--
--  Owns: every call listed "Wrapper: yes" in PRD 11.2. Each wrapper is defensive (pcall,
--  nil checks) and returns nil when the API is missing or behaves unexpectedly, so a
--  Blizzard change degrades one feature instead of breaking the module. When the
--  in-game probe (work package 0.1) confirms an API, its wrapper can be inlined.
-- ============================================================
local ADDON, LC = ...
local Compat = {}
LC.Compat = Compat

local pcall, type, select = pcall, type, select

-- GetLootRollItemInfo return positions are unverified: read by name where the client offers
-- a table form, otherwise by the long-standing positions (texture, name, count, quality,
-- bop, canNeed, canGreed, canDisenchant, ...).
function Compat.GetRollOptions(rollID)
    if C_LootHistory and C_LootHistory.GetItem then
        -- not a roll API; ignored on purpose
    end
    local ok, texture, name, count, quality, bop, canNeed, canGreed = pcall(GetLootRollItemInfo, rollID)
    if not ok then return nil end
    return canNeed and true or false, canGreed and true or false
end

-- Drops of one encounter, normalised to plain tables. Returns nil when the API is absent.
function Compat.GetDrops(encounterID)
    if not (C_LootHistory and C_LootHistory.GetSortedDropsForEncounter) then return nil end
    local ok, drops = pcall(C_LootHistory.GetSortedDropsForEncounter, encounterID)
    if not ok or type(drops) ~= "table" then return nil end
    local out = {}
    for i = 1, #drops do
        local d = drops[i]
        local w = d.winner
        out[#out + 1] = {
            lootListID = d.lootListID,
            link = d.itemHyperlink,
            allPassed = d.allPassed and true or false,
            winnerName = w and w.playerName or nil,
            winnerGUID = w and w.playerGUID or nil,
            winnerIsSelf = w and w.isSelf or false,
        }
    end
    return out
end

-- Loot-history update events. Names are unverified, so they are tried one by one.
Compat.LootHistoryEvents = {
    "LOOT_HISTORY_UPDATE_DROP",
    "LOOT_HISTORY_UPDATE_ENCOUNTER",
    "LOOT_HISTORY_ROLL_COMPLETE",
    "LOOT_HISTORY_ROLL_CHANGED",
    "LOOT_HISTORY_FULL_UPDATE",
}

-- Item context from a link; C_Item.GetItemCreationContext is documented but its return type is unconfirmed.
function Compat.GetItemContext(link)
    if C_Item and C_Item.GetItemCreationContext then
        local ok, ctx = pcall(C_Item.GetItemCreationContext, link)
        if ok and type(ctx) == "number" then return ctx end
    end
    return nil
end

-- Seconds of trade time left on a bag item, read from its tooltip line (BIND_TRADE_TIME_REMAINING).
-- nil when it cannot be read; callers fall back to kill time + 4 hours.
function Compat.GetBagTradeSecondsLeft(bag, slot)
    if not (C_TooltipInfo and C_TooltipInfo.GetBagItem and BIND_TRADE_TIME_REMAINING) then return nil end
    local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
    if not ok or type(data) ~= "table" or not data.lines then return nil end
    local pattern = BIND_TRADE_TIME_REMAINING:gsub("%%s", "(.+)")
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then
            local rest = text:match(pattern)
            if rest then
                local total = 0
                local h = rest:match("(%d+)%s*" .. (HOURS_ABBR and HOURS_ABBR:gsub("%%d", ""):gsub("%s", "") or "h"))
                local m = rest:match("(%d+)%s*" .. (MINUTES_ABBR and MINUTES_ABBR:gsub("%%d", ""):gsub("%s", "") or "m"))
                if h then total = total + tonumber(h) * 3600 end
                if m then total = total + tonumber(m) * 60 end
                if total > 0 then return total end
            end
        end
    end
    return nil
end

-- Bag access: C_Container is used by bird at Interface 120000; re-checked on 12.1.5 by the probe.
function Compat.NumBagSlots(bag)
    if not (C_Container and C_Container.GetContainerNumSlots) then return 0 end
    local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
    return ok and n or 0
end

function Compat.BagItem(bag, slot)
    if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if not ok or type(info) ~= "table" then return nil end
    return info.itemID, info.hyperlink, info.isLocked
end

-- The whole container info table (isBound, quality, hyperlink, ...) or nil.
function Compat.BagInfo(bag, slot)
    if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if not ok or type(info) ~= "table" then return nil end
    return info
end

-- Warband / Blizzard-account bound, or "warbound until equipped": cannot be traded to another player's
-- account. Checked three ways because each can be unavailable: the item's bind type, the item location API
-- and the bag tooltip text (the game's own localised strings).
local ACCOUNT_BIND_TYPES
local ACCOUNT_BIND_STRINGS = { "ITEM_ACCOUNTBOUND", "ITEM_BNETACCOUNTBOUND", "ITEM_ACCOUNTBOUND_UNTIL_EQUIP",
    "ITEM_BNETACCOUNTBOUND_UNTIL_EQUIP", "ITEM_BIND_TO_ACCOUNT", "ITEM_BIND_TO_BNETACCOUNT",
    "ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP", "ITEM_BIND_TO_BNETACCOUNT_UNTIL_EQUIP" }
function Compat.IsAccountBound(bag, slot, link)
    if not ACCOUNT_BIND_TYPES then
        ACCOUNT_BIND_TYPES = {}
        for _, name in ipairs({ "ToWoWAccount", "ToBnetAccount", "ToBnetAccountUntilEquipped" }) do
            local v = Enum and Enum.ItemBind and Enum.ItemBind[name]
            if v then ACCOUNT_BIND_TYPES[v] = true end
        end
    end
    local bindType = link and select(14, C_Item.GetItemInfo(link))
    if bindType and ACCOUNT_BIND_TYPES[bindType] then return true end
    if ItemLocation and ItemLocation.CreateFromBagAndSlot and C_Item then
        local ok, loc = pcall(ItemLocation.CreateFromBagAndSlot, ItemLocation, bag, slot)
        if ok and loc then
            if C_Item.IsBoundToAccountUntilEquip then
                local ok2, res = pcall(C_Item.IsBoundToAccountUntilEquip, loc)
                if ok2 and res then return true end
            end
        end
    end
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
        if ok and type(data) == "table" and data.lines then
            for _, line in ipairs(data.lines) do
                local text = line.leftText
                if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then
                    for _, g in ipairs(ACCOUNT_BIND_STRINGS) do
                        local str = _G[g]
                        if type(str) == "string" and str ~= "" and text == str then return true end
                    end
                end
            end
        end
    end
    return false
end

function Compat.PickupBagItem(bag, slot)
    ClearCursor()
    local ok = pcall(C_Container.PickupContainerItem, bag, slot)
    return ok
end

function Compat.ClickTradeSlot(slot)
    local ok = pcall(ClickTradeButton, slot)
    return ok
end

function Compat.TradeItemLink(index)
    if not GetTradePlayerItemLink then return nil end
    local ok, link = pcall(GetTradePlayerItemLink, index)
    if ok and type(link) == "string" and not (issecretvalue and issecretvalue(link)) then return link end
    return nil
end

-- Name of the trade partner at TRADE_SHOW. Guarded against secret values.
function Compat.TradePartner()
    local ok, name = pcall(UnitName, "NPC")
    if ok and type(name) == "string" and not (issecretvalue and issecretvalue(name)) then return name end
    return nil
end

function Compat.InTradeRange(unit)
    if InCombatLockdown() then return nil end      -- restricted in combat (C-5)
    local ok, r = pcall(CheckInteractDistance, unit, 2)
    if ok then return r and true or false end
    return nil
end

-- Trade distance (CheckInteractDistance index 2) without the combat guard of InTradeRange, so the trade window can
-- tell "close enough but in combat" from "too far". true / false, or nil when the game will not say.
function Compat.TradeRange(unit)
    if not unit then return nil end
    local ok, r = pcall(CheckInteractDistance, unit, 2)
    if ok and not (issecretvalue and issecretvalue(r)) then return r and true or false end
    return nil
end

function Compat.Initiate(unit)
    if InCombatLockdown() then return false end
    return pcall(InitiateTrade, unit)
end

-- Inspect is unverified for non-participants; best effort only.
function Compat.Inspect(unit)
    if not (NotifyInspect and CanInspect and CanInspect(unit)) then return false end
    return pcall(NotifyInspect, unit)
end

-- Raid Finder groups: no prompt, no auto-pass logic (PRD 5.3).
function Compat.IsLFRGroup()
    if IsInLFGDungeon and LE_PARTY_CATEGORY_INSTANCE and IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then return true end
    local _, _, diff = GetInstanceInfo()
    return diff == 17
end

function Compat.CanSendChat()
    return not (C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown())
end
