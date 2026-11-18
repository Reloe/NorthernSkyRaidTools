-- ============================================================
--  Core/BonusRoll.lua - bonus roll results go into the loot history
--
--  A player's own client sees their bonus roll result (BONUS_ROLL_RESULT). While the loot council is active
--  for the raid it records the item as a history entry (source = "bonus", reason = "bonus") and sends it to
--  the group, so the council clients record it too. The council then sees it next to awarded loot when it
--  looks back at what a player has received.
--
--  Only the owner may report their own roll: a receiver ignores an entry whose winner is not the sender.
--  The event is tried through TryGroup, so a client without it just records nothing.
-- ============================================================
local ADDON, LC = ...
local BonusRoll = {}
LC.BonusRoll = BonusRoll

local type = type
local KILL_WINDOW = 30 * 60        -- a bonus roll belongs to the kill that happened in the last half hour

-- Pure: the history entry for one bonus roll. dec = Items.Decode(link), cur = Loot.Current() or nil.
function BonusRoll.Build(me, dec, cur, now, class)
    if not (me and dec and dec.itemID) then return nil end
    local fresh = cur and cur.killTime and (now - cur.killTime) <= KILL_WINDOW
    return {
        id = "b:" .. me:sub(1, 30) .. ":" .. now .. ":" .. dec.itemID,
        itemID = dec.itemID, item = dec.itemString,
        difficulty = (LC.Items.ContextToDifficulty and LC.Items.ContextToDifficulty[dec.context]) or (fresh and cur.difficulty) or nil,
        encounterID = fresh and cur.encounterID or nil, boss = fresh and cur.name or nil,
        kill = fresh and cur.killTime or now, time = now,
        winner = me, holder = me, class = class, reason = "bonus", reasonText = LC.Loc("Bonus roll"),
        source = "bonus", upd = now,
    }
end

local function Store(rec)
    local clean = LC.History.Sanitize(rec)
    if not clean then return false end
    if LC.History.Upsert(clean) then LC.Fire("NSRT_LC_HISTORY_CHANGED") end
    return true
end

-- BONUS_ROLL_RESULT: typeIdentifier, itemLink, quantity, specID, sex, personalLootToast, currencyID, ...
local function OnResult(_, typeIdentifier, itemLink)
    if typeIdentifier ~= "item" or type(itemLink) ~= "string" then return end     -- gold and currency are not loot
    if not (LC.Ruleset.IsActive() and IsInRaid()) then return end
    local me = LC.Roster.MyKey()
    local dec = me and LC.Items.Decode(itemLink)
    local rec = dec and BonusRoll.Build(me, dec, LC.Loot.Current(), GetServerTime(), LC.Roster.ClassOf(me))
    if not rec then return end
    if Store(rec) then LC.Comms.Send("BONUS", rec, "RAID") end
end

function BonusRoll.Handlers()
    return { BONUS_ROLL_RESULT = OnResult }
end

-- A bonus roll arrived from `sender`. Council is active here, the entry is the sender's own, and it says so.
function BonusRoll.Receive(d, sender)
    if not LC.Ruleset.IsActive() then return end
    local rec = LC.History.Sanitize(d)
    if not rec or rec.source ~= "bonus" or rec.winner ~= sender then return end
    rec.reason, rec.holder, rec.by, rec.audit, rec.council, rec.trade, rec.void = "bonus", sender, nil, nil, nil, nil, nil
    Store(rec)
end
