-- ============================================================
--  Core/Awards.lua - awarding, undoing, reassigning, bank/DE (A-1..A-4)
--  The ML emits log events; every client records history from the award events it sees.
-- ============================================================
local ADDON, LC = ...
local Awards = {}
LC.Awards = Awards

-- Award a drop. A drop that is already awarded is reassigned instead: the award changes to the new winner, the
-- history entry follows (winner, reason, response, votes, audit trail), a trade waiting for the old winner is
-- redirected, and the loot master's raid chat gets the change and the new award line.
function Awards.Award(dropID, winner, reason, opts)
    if not LC.Ruleset.IAmML() then return false, "not the loot master" end
    local state = LC.Session.state
    if not state or state.closed or not state.drops[dropID] then return false, "no such drop" end
    if state.awards[dropID] then return Awards.Reassign(dropID, winner, reason, opts and opts.why, opts) end
    opts = opts or {}
    local resp = state.responses[dropID] and state.responses[dropID][winner]
    -- A reason is always required. Plain Award uses the response the player submitted.
    reason = reason or (resp and resp.response)
    if not reason or reason == "" then return false, "reason required" end
    local ok = LC.Session.Emit({
        t = "award", id = dropID, winner = winner, reason = reason, by = LC.Roster.MyKey(),
        response = resp and resp.response, source = opts.source or "council", upgrade = opts.upgrade,
        council = LC.Awards.CouncilSnapshot(dropID),
    })
    return ok
end

-- Give an awarded drop to someone else (or change its reason). Loot master only.
function Awards.Reassign(dropID, winner, reason, why, opts)
    if not LC.Ruleset.IAmML() then return false, "not the loot master" end
    local state = LC.Session.state
    local cur = state and not state.closed and state.awards[dropID]
    if not cur then return false, "not awarded" end
    opts = opts or {}
    local resp = state.responses[dropID] and state.responses[dropID][winner]
    reason = reason or (resp and resp.response)
    if not reason or reason == "" then return false, "reason required" end
    if cur.winner == winner and cur.reason == reason then return false, "already awarded to that player" end
    local old, oldTrade = cur.winner, cur.trade
    local ok = LC.Session.Emit({
        t = "edit", id = dropID, winner = winner, reason = reason, by = LC.Roster.MyKey(), why = why,
        response = resp and resp.response, source = opts.source or "council", upgrade = opts.upgrade,
        council = LC.Awards.CouncilSnapshot(dropID),
    })
    if ok and old ~= winner then
        Awards.AnnounceChange(dropID, old)
        if oldTrade and oldTrade.to then
            LC.Print(string.format(LC.Loc("%s was already traded to %s. Ask them to trade it on to %s."),
                Awards.ItemText(dropID), LC.Roster.ShortName(oldTrade.to), LC.Roster.ShortName(winner)))
        end
    end
    return ok
end

-- The item as a chat link when its data is cached, else its name or id.
function Awards.ItemText(dropID)
    local state = LC.Session.state
    local d = state and state.drops[dropID]
    if not d then return "?" end
    return (d.item and LC.Items.ToLink(d.item)) or select(2, C_Item.GetItemInfo(d.itemID)) or C_Item.GetItemNameByID(d.itemID) or ("item " .. d.itemID)
end

-- "<item> -> Player (Reason)": the award line.
function Awards.Line(dropID)
    local state = LC.Session.state
    local a = state and state.awards[dropID]
    if not a then return nil end
    local r = a.reason and LC.Ruleset.ResponseById(a.reason)
    return string.format("%s -> %s (%s)", Awards.ItemText(dropID), LC.Roster.ShortName(a.winner), r and LC.Loc(r.text) or a.reason or "?")
end

-- Tell the raid an award changed, then the new award line. Raid chat follows the ruleset's chat announce setting;
-- a test or the preview prints to your own chat instead of the group's.
function Awards.AnnounceChange(dropID, oldWinner)
    local state = LC.Session.state
    local a = state and state.awards[dropID]
    local line = Awards.Line(dropID)
    if not (a and line) then return end
    local head = string.format(LC.Loc("Loot Council: award changed. %s was awarded to %s, now going to %s."),
        Awards.ItemText(dropID), LC.Roster.ShortName(oldWinner), LC.Roster.ShortName(a.winner))
    if LC.Preview or (LC.Sim and LC.Sim.loopback) then
        LC.Print(head)
        LC.Print(line)
        return
    end
    local rs = LC.Ruleset.Get()
    if rs and rs.chatAnnounce == false then return end
    LC.Comms.Chat(head)
    LC.Comms.Chat(line)
end

-- Reasons are the ruleset's response buttons (the same list the raider picked from).
function Awards.Reasons()
    local rs = LC.Ruleset.Get()
    return rs and rs.responses or LC.Ruleset.defaults.responses
end

-- Votes at the moment of the award, kept in the record (H-1).
function Awards.CouncilSnapshot(dropID)
    local state = LC.Session.state
    local out = {}
    for voter, v in pairs(state and state.votes[dropID] or {}) do out[voter] = v.c end
    return out
end

function Awards.Undo(dropID, why)
    if not LC.Ruleset.IAmML() then return false end
    return LC.Session.Emit({ t = "undo", id = dropID, by = LC.Roster.MyKey(), why = why })
end

-- Bank / disenchant target from the ruleset.
function Awards.BankTarget(role)
    local rs = LC.Ruleset.Get()
    if not rs then return nil end
    for key, r in pairs(rs.bank) do if r == role then return key end end
end

-- Everything awarded to `key` that a holder still has to trade.
function Awards.PendingFor(key)
    local state = LC.Session.state
    local out = {}
    if not state then return out end
    for id, a in pairs(state.awards) do
        if a.winner == key and not a.delivered then out[#out + 1] = id end
    end
    return out
end
