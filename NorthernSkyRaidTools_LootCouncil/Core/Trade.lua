-- ============================================================
--  Core/Trade.lua - trade engine (T-1..T-8, port of bird per bird-loot-and-trade Appendix A)
--
--  Two jobs: (1) the manual /ns lc trade queue and trade-string import (bird compatible),
--  (2) trades driven by awards. The addon places items; the player clicks Accept (AcceptTrade
--  needs a hardware event). Rules carried from the bird audit:
--    - an item with a stated difficulty never matches a bag item of another difficulty;
--    - a failed placement leaves the queue entry in place and says so;
--    - the 4-hour window is read from the bag tooltip, expired items are flagged, not offered.
-- ============================================================
local ADDON, LC = ...
local Trade = {}
LC.Trade = Trade

Trade.queue = {}       -- { key, itemID, difficulty, player, dropID, state = "waiting"|"placed"|"done"|"failed" }
local open = false
local partner

local function Items() return LC.Items end

-- item: the dropped item's item string (carries the bonus IDs) when known; used to pick the right bag copy.
function Trade.Add(itemID, difficulty, player, dropID, item)
    Trade.queue[#Trade.queue + 1] = { itemID = itemID, difficulty = difficulty, player = player,
        key = Items().TradeKey(itemID, difficulty), dropID = dropID, item = item, state = "waiting" }
    LC.Fire("NSRT_LC_TRADES_CHANGED")
end

function Trade.Clear() wipe(Trade.queue); LC.Fire("NSRT_LC_TRADES_CHANGED") end

-- Import a trade string. Returns number added, errors.
function Trade.Import(text)
    local entries, errors = LC.Strings.ParseTrade(text)
    for _, e in ipairs(entries) do Trade.Add(e.itemID, e.difficulty, LC.Roster.Key(e.player) or e.player) end
    LC.Fire("NSRT_LC_TRADES_CHANGED")
    return #entries, errors
end

-- Awards I hold the item for become queue entries automatically.
function Trade.Refresh()
    local state = LC.Session.state
    if not state then return end
    local me = LC.Roster.MyKey()
    -- Queue entries of this session follow their award: a reassignment redirects the trade to the new winner; an
    -- undo, or an award to me, removes it. Entries already in the trade window or done are left alone.
    local changed = false
    for i = #Trade.queue, 1, -1 do
        local q = Trade.queue[i]
        if q.dropID and state.drops[q.dropID] and q.state ~= "done" and q.state ~= "placed" then
            local a = state.awards[q.dropID]
            if not a or a.winner == me then
                table.remove(Trade.queue, i)
                changed = true
            elseif a.winner ~= q.player then
                q.player, q.state = a.winner, "waiting"
                changed = true
            end
        end
    end
    if changed then LC.Fire("NSRT_LC_TRADES_CHANGED") end
    local have = {}
    for _, q in ipairs(Trade.queue) do if q.dropID then have[q.dropID] = true end end
    for id, a in pairs(state.awards) do
        local d = state.drops[id]
        if d and d.holder == me and not have[id] and not a.delivered and a.winner ~= me then
            Trade.Add(d.itemID, d.difficulty, a.winner, id, d.item)
        end
    end
end

-- ---- opening a trade from the Trades window ---------------------------------------------------------
-- State of the "Trade" link for a queue entry: "ready" (in range, can open the window), "combat" (in range but
-- you are in combat, so the game will not open a trade), "far" (out of range, offline, or not in your group).
-- The reason text is for the tooltip / chat.
function Trade.RangeState(q)
    local key = q and q.player
    local unit = key and LC.Roster.Unit(key)
    if not unit or not LC.Roster.IsOnline(key) then return "far", "not in your group or offline" end
    if LC.Compat.TradeRange(unit) ~= true then return "far", "out of trade range" end
    if InCombatLockdown() then return "combat", "you cannot open a trade in combat" end
    return "ready"
end

-- Open the trade window with the entry's player. The items are placed by OnTradeShow once the window opens.
-- Returns true when the request went out, otherwise false and the reason.
function Trade.Open(q)
    local state, why = Trade.RangeState(q)
    if state ~= "ready" then return false, why end
    local ok = LC.Compat.Initiate(LC.Roster.Unit(q.player))
    if not ok then return false, "the trade could not be opened" end
    return true
end

-- Find the bag slot for itemID at difficulty. Among copies that match those two, the one whose bonus IDs
-- best match wantItem (the drop's item string) wins; with no wantItem the first copy is used. `skip` is a
-- set of "bag:slot" already picked in this pass. Returns bag, slot, secondsLeft, score (2 = same bonus IDs,
-- 1..2 = partly, 1 = nothing to compare), link.
function Trade.FindInBags(itemID, difficulty, wantItem, skip)
    local bb, bs, bleft, bscore, blink
    for bag = 0, 5 do
        for slot = 1, LC.Compat.NumBagSlots(bag) do
            local _, link = LC.Compat.BagItem(bag, slot)     -- (itemID, hyperlink, isLocked)
            if link and not (skip and skip[bag .. ":" .. slot]) and Items().BagMatches(link, itemID, difficulty) then
                local left = LC.Compat.GetBagTradeSecondsLeft(bag, slot)
                if left == nil or left > 0 then
                    local score = wantItem and Items().BonusScore(link, wantItem) or 1
                    if not bscore or score > bscore then bb, bs, bleft, bscore, blink = bag, slot, left, score, link end
                    if score >= 2 then return bb, bs, bleft, bscore, blink end
                end
            end
        end
    end
    return bb, bs, bleft, bscore, blink
end

-- /ns lc bags: what each queued trade would pick from your bags, and why.
function Trade.Report()
    if #Trade.queue == 0 then LC.Print(LC.Loc("The trade queue is empty.")) return end
    local skip = {}
    for _, q in ipairs(Trade.queue) do
        local name = C_Item.GetItemNameByID(q.itemID) or tostring(q.itemID)
        local bag, slot, _, score, link = Trade.FindInBags(q.itemID, q.difficulty, q.item, skip)
        local how
        if not bag then
            how = LC.Loc("not found in your bags")
        else
            skip[bag .. ":" .. slot] = true
            local d = Items().Decode(link)
            local ids = d and table.concat(d.bonusIDs, ",") or "?"
            how = string.format("bag %d slot %d, %s (bonus IDs %s)", bag, slot,
                score >= 2 and LC.Loc("same bonus IDs") or (score > 1 and LC.Loc("closest match") or LC.Loc("matched on item and difficulty")), ids)
        end
        LC.Print(string.format("%s (%s) -> %s: %s", name, q.difficulty and (Items().DifficultyName[q.difficulty] or q.difficulty) or "any",
            LC.Roster.Display(q.player) or tostring(q.player), how))
    end
end

-- ---- what really happened in the trade window (history) -------------------------------------------
-- The window's item slots are snapshotted whenever they change or someone accepts; the last snapshot
-- before TRADE_CLOSED is what left (when both sides had accepted). Items stay in the bags, locked, until
-- the trade executes, so a bag count taken at TRADE_SHOW and again after the close confirms it.
local offered, bothAccepted, bagsBefore = {}, false, {}

local function Snapshot()
    for i = 1, 6 do offered[i] = LC.Compat.TradeItemLink(i) end
end

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

local function OnAcceptUpdate(_, playerAccepted, targetAccepted)
    if IsSecret(playerAccepted) or IsSecret(targetAccepted) then return end
    Snapshot()
    bothAccepted = (playerAccepted == 1 or playerAccepted == true) and (targetAccepted == 1 or targetAccepted == true) or false
end

local function OnItemChanged()
    Snapshot()
    bothAccepted = false
end

-- itemID -> number of copies in my bags.
function Trade.CountByItem()
    local out = {}
    for bag = 0, 5 do
        for slot = 1, LC.Compat.NumBagSlots(bag) do
            local id = LC.Compat.BagItem(bag, slot)
            if id then out[id] = (out[id] or 0) + 1 end
        end
    end
    return out
end

-- The best awarded drop I hold that matches an item that left in a trade: same item and difficulty, closest
-- bonus IDs; a drop awarded to the trade partner wins over one awarded to somebody else. nil when none.
function Trade.MatchDrop(link, partnerKey)
    local state = LC.Session.state
    local want = Items().Decode(link)
    if not (state and want) then return nil end
    local diff = Items().ContextToDifficulty[want.context]
    local me = LC.Roster.MyKey()
    local best, bestScore
    for id, d in pairs(state.drops) do
        local a = state.awards[id]
        if a and not a.trade and d.itemID == want.itemID and (d.holder == me or a.holder == me)
            and (not diff or not d.difficulty or d.difficulty == diff) then
            local score = Items().BonusScore(link, d.item)
            score = score + (a.winner == partnerKey and 10 or 0)
            if not bestScore or score > bestScore then best, bestScore = id, score end
        end
    end
    return best
end

-- An awarded drop was delivered: record who received it, who traded it, when and the exact item that left,
-- tell the raid, and update the history. `link` is the item that was in the window (bonus IDs and all).
function Trade.Complete(dropID, to, link)
    local state = LC.Session.state
    local a = state and state.awards[dropID]
    if not a then return false end
    local dec = link and Items().Decode(link)
    local tr = { to = to, by = LC.Roster.MyKey(), at = GetServerTime(), item = dec and dec.itemString or nil }
    LC.Session.RecordTrade(state, dropID, tr)
    LC.Comms.Send("TRADE_DONE", { id = dropID, to = to, at = tr.at, item = tr.item }, "RAID")
    LC.History.Record()
    return true
end

-- Seconds between items put into the trade window. Picking up and clicking a slot in the same frame, six
-- times over, leaves items stuck on the cursor; the client needs a moment to finish each placement.
local PLACE_DELAY = 0.5
local placeGen = 0

local function OnTradeShow()
    open = true
    local pname = LC.Compat.TradePartner()
    partner = pname and LC.Roster.KeyFromName(pname) or nil
    wipe(offered)
    bothAccepted = false
    bagsBefore = Trade.CountByItem()
    placeGen = placeGen + 1
    local gen = placeGen
    local slot, used, todo = 1, {}, {}
    for _, q in ipairs(Trade.queue) do
        if q.state == "waiting" and q.player == partner and slot <= 6 then
            local bag, bslot, _, _, link = Trade.FindInBags(q.itemID, q.difficulty, q.item, used)
            if bag then
                used[bag .. ":" .. bslot] = true
                todo[#todo + 1] = { q = q, bag = bag, bslot = bslot, slot = slot, link = link }
                q.state, q.slot = "placed", slot
                q.from = { bag = bag, slot = bslot, link = link }
                slot = slot + 1
            else
                q.state = "failed"
                LC.Print(string.format(LC.Loc("Could not find %s in your bags."), tostring(q.itemID)))
            end
        end
    end
    -- Place one item every PLACE_DELAY seconds (the first straight away). A trade that closed, or a newer
    -- trade window, cancels the rest; whatever was not placed is put back to waiting.
    for i, t in ipairs(todo) do
        local function place()
            if LC.dead or gen ~= placeGen or not open then
                if t.q.state == "placed" then t.q.state, t.q.slot, t.q.from = "waiting", nil, nil end
                return
            end
            LC.Compat.PickupBagItem(t.bag, t.bslot)
            LC.Compat.ClickTradeSlot(t.slot)
            if i == #todo then ClearCursor() end
        end
        if i == 1 then place() else C_Timer.After((i - 1) * PLACE_DELAY, place) end
    end
    LC.Fire("NSRT_LC_TRADES_CHANGED")
end

local function OnTradeClosed()
    open = false
    -- What the window held and whether both sides accepted, captured now: the check below runs a second later.
    local snap, both, who, before = {}, bothAccepted, partner, bagsBefore
    for i = 1, 6 do snap[i] = offered[i] end
    -- Whatever was placed and has left the bags is done; the rest goes back to waiting.
    C_Timer.After(1, function()
        if LC.dead then return end
        local recorded = {}
        for _, q in ipairs(Trade.queue) do
            if q.state == "placed" then
                -- Done when the slot we took it from no longer holds that item; without a recorded slot,
                -- fall back to looking for the item anywhere in the bags.
                local stillThere
                if q.from then
                    local _, now = LC.Compat.BagItem(q.from.bag, q.from.slot)
                    stillThere = now ~= nil and now == q.from.link
                else
                    stillThere = Trade.FindInBags(q.itemID, q.difficulty, q.item) ~= nil
                end
                if stillThere then
                    q.state = "waiting"
                else
                    q.state = "done"
                    if q.slot then recorded[q.slot] = true end
                    local sent = snap[q.slot or 0] or (q.from and q.from.link)
                    -- A queue entry made by hand (import) has no drop: find the awarded drop it delivered, so the
                    -- history records the trade too.
                    if not q.dropID and sent and LC.Session.state then q.dropID = Trade.MatchDrop(sent, q.player) end
                    if q.dropID and LC.Session.state then
                        Trade.Complete(q.dropID, q.player, sent)
                    end
                end
            end
        end
        -- Items that went out of the window without the queue placing them (a trade done by hand): match each
        -- to the awarded drop it most likely was, once the bags confirm that many copies left.
        if both and who and LC.Session.state then
            local after, sent = Trade.CountByItem(), {}
            for slot = 1, 6 do
                local link = snap[slot]
                local dec = link and Items().Decode(link)
                if dec then sent[dec.itemID] = (sent[dec.itemID] or 0) + 1 end
            end
            for slot = 1, 6 do
                local link = snap[slot]
                local dec = link and not recorded[slot] and Items().Decode(link)
                if dec and (before[dec.itemID] or 0) - (after[dec.itemID] or 0) >= sent[dec.itemID] then
                    local id = Trade.MatchDrop(link, who)
                    if id then Trade.Complete(id, who, link) end
                end
            end
        end
        LC.Fire("NSRT_LC_TRADES_CHANGED")
    end)
end

function Trade.ReceiveDone(d, sender)
    local state = LC.Session.state
    if type(d) ~= "table" or not state then return end
    local a, drop = state.awards[d.id], state.drops[d.id]
    -- Only the one who held the item can say it was traded (the drop's holder may already read as the winner).
    if a and drop and (drop.holder == sender or a.holder == sender) then
        local item = type(d.item) == "string" and #d.item <= 300 and d.item:match("^item:[%d:%-]*$") and d.item or nil
        LC.Session.RecordTrade(state, d.id, { to = type(d.to) == "string" and d.to:sub(1, 80) or nil, by = sender,
            at = tonumber(d.at) or GetServerTime(), item = item })
        LC.History.Record()
    end
    LC.Fire("NSRT_LC_TRADES_CHANGED")
end

-- When a session ends and I still hold items to hand out, open the Trades window (the one place trades are listed).
local lastAutoOpen = 0
LC.On("NSRT_LC_SESSION_CLOSED", function()
    if LC.Preview or (LC.Sim and LC.Sim.loopback) then return end
    local waiting = false
    for _, q in ipairs(Trade.queue) do if q.state == "waiting" then waiting = true break end end
    if not waiting then return end
    local now = GetTime()
    if now - lastAutoOpen < 2 then return end          -- Clear fires this event again right after Close
    lastAutoOpen = now
    if LC.EnsureUI() and LC.UI.TradesFrame then LC.UI.TradesFrame.Open() end
end)

function Trade.Enable()
    LC.Events.SetGroup("trade", { TRADE_SHOW = OnTradeShow, TRADE_CLOSED = OnTradeClosed,
        TRADE_ACCEPT_UPDATE = OnAcceptUpdate, TRADE_PLAYER_ITEM_CHANGED = OnItemChanged })
end

function Trade.Shutdown()
    LC.Events.ClearGroup("trade")
    wipe(Trade.queue)
    open, partner, bothAccepted = false, nil, false
    wipe(offered); wipe(bagsBefore)
end
LC.RegisterShutdown("Trade", Trade.Shutdown)
