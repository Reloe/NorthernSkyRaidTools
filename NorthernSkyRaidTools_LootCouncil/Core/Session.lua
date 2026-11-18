-- ============================================================
--  Core/Session.lua - the session: reducer, persistence, sync, handoff
--
--  The session is a log (PRD 5.4 rule 2). Two kinds of events:
--    ordered log events, numbered by the loot master (rev 1, 2, 3...):
--        open, holder, award, undo, edit, authority, close
--    free events, last-write-wins per key with a sender sequence:
--        response (per drop and candidate), vote (per drop and voter)
--  Responses and votes are not sequenced by the ML: they would be 100+ messages through
--  one throttle (PRD 7.1 budget). Because they are keyed and last-write-wins they are
--  idempotent and order independent.
--
--  Session.Apply / ApplyFree are pure reducers (specs in tools/lc-tests). The rest of the
--  file is the game side: emit, receive, persist (the live state table IS the saved table,
--  so persisting costs nothing), resync and takeover.
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Session = {}
LC.Session = Session

local pairs, ipairs, type = pairs, ipairs, type

-- ============================================================
--  Pure reducer
-- ============================================================
function Session.NewState()
    return {
        guid = nil, encounterID = 0, difficulty = 0, killTime = 0, openTime = 0, runType = "main",
        ml = nil, epoch = 0, rev = 0, closed = false, rulesetHash = "",
        drops = {}, order = {}, responses = {}, snapshots = {}, votes = {}, awards = {}, audit = {},
        killRoster = {}, seq = {},
    }
end

local function Audit(state, id, action, ev, from, to)
    local list = state.audit[id]
    if not list then list = {}; state.audit[id] = list end
    list[#list + 1] = { who = ev.by, when = ev.time, action = action, from = from, to = to, why = ev.why }
end

-- Apply an ordered log event. Returns ok, reason:
--   true            applied
--   true, "dup"     already applied (idempotent: exactly once)
--   false, "gap"    a revision is missing: ask for a resync
--   false, "epoch"  from a superseded authority
--   false, "bad"    malformed
function Session.Apply(state, ev)
    if type(ev) ~= "table" or type(ev.t) ~= "string" or type(ev.rev) ~= "number" then return false, "bad" end
    if ev.t == "open" then
        if state.guid and state.guid == ev.guid then return true, "dup" end
    else
        if ev.rev <= state.rev then return true, "dup" end
        if ev.rev > state.rev + 1 then return false, "gap" end
    end
    local epoch = ev.epoch or 0
    if ev.t ~= "open" and ev.t ~= "authority" and epoch < state.epoch then return false, "epoch" end
    if ev.t == "authority" and epoch <= state.epoch then return false, "epoch" end

    local t = ev.t
    if t == "open" then
        if type(ev.drops) ~= "table" then return false, "bad" end
        local fresh = Session.NewState()
        for k, v in pairs(fresh) do state[k] = v end
        state.guid, state.encounterID, state.difficulty = ev.guid, ev.encounterID or 0, ev.difficulty or 0
        state.killTime, state.ml, state.epoch = ev.killTime or 0, ev.ml, ev.epoch or 0
        state.runType, state.rulesetHash = ev.runType or "main", ev.rulesetHash or ""
        state.openTime = tonumber(ev.time) or 0
        for _, d in ipairs(ev.drops) do
            if type(d) == "table" and d.id then
                state.drops[d.id] = { id = d.id, item = d.item, itemID = d.itemID, difficulty = d.difficulty,
                    holder = d.holder, state = "open", allPassed = d.allPassed, index = d.index,
                    enc = d.enc, kill = d.kill, boss = d.boss }
                state.order[#state.order + 1] = d.id
            end
        end
        for _, key in ipairs(ev.killRoster or {}) do state.killRoster[key] = true end
    elseif t == "holder" then
        local d = state.drops[ev.id]
        if d then
            d.holder = ev.holder
            d.expires = ev.expires or d.expires
            -- The award remembers who held the item when it was awarded (the one who has to trade it); a
            -- later holder report (the winner after the trade) must not overwrite that.
            local a = state.awards[ev.id]
            if a and not a.holder then a.holder = ev.holder end
        end
    elseif t == "award" then
        local d = state.drops[ev.id]
        if d then
            state.awards[ev.id] = { winner = ev.winner, reason = ev.reason, response = ev.response, source = ev.source,
                by = ev.by, time = ev.time, upgrade = ev.upgrade, council = ev.council, holder = d.holder }
            d.state = "awarded"
            Audit(state, ev.id, "award", ev, nil, ev.winner)
        end
    elseif t == "undo" then
        local a = state.awards[ev.id]
        if a then
            Audit(state, ev.id, "undo", ev, a.winner, nil)
            state.awards[ev.id] = nil
            state.drops[ev.id].state = "open"
        end
    elseif t == "edit" then
        local a = state.awards[ev.id]
        if a then
            Audit(state, ev.id, "reassign", ev, a.winner, ev.winner or a.winner)
            a.winner = ev.winner or a.winner
            a.reason = ev.reason or a.reason
            if ev.winner then
                -- the new winner's own response, and the votes at this moment, replace the old ones
                a.response, a.source, a.upgrade = ev.response, ev.source or a.source, ev.upgrade
                a.council = ev.council or a.council
            end
        end
    elseif t == "authority" then
        state.ml, state.epoch = ev.ml, epoch
    elseif t == "close" then
        state.closed = true
    else
        return false, "bad"
    end
    state.rev = ev.rev
    return true
end

-- Free events: last-write-wins by sender sequence. Returns true when the state changed.
function Session.ApplyFree(state, ev)
    if type(ev) ~= "table" or not ev.id or not state.drops[ev.id] then return false end
    if ev.t == "response" then
        if type(ev.from) ~= "string" then return false end
        local map = state.responses[ev.id]
        if not map then map = {}; state.responses[ev.id] = map end
        local cur = map[ev.from]
        if cur and (cur.seq or 0) >= (ev.seq or 0) then return false end
        map[ev.from] = { response = ev.response, note = ev.note, gear = ev.gear, tier = ev.tier, tg = ev.tg, spec = ev.spec, auto = ev.auto,
            sim = ev.sim, simAge = ev.simAge, ilvl = ev.ilvl, seq = ev.seq or 0, onBehalf = ev.onBehalf }
        return true
    elseif ev.t == "snapshot" then
        if type(ev.from) ~= "string" then return false end
        state.snapshots = state.snapshots or {}              -- sessions saved before snapshots existed
        local map = state.snapshots[ev.id]
        if not map then map = {}; state.snapshots[ev.id] = map end
        local cur = map[ev.from]
        if cur and (cur.seq or 0) >= (ev.seq or 0) then return false end
        map[ev.from] = { gear = ev.gear, tier = ev.tier, tg = ev.tg, spec = ev.spec, sim = ev.sim, simAge = ev.simAge, seq = ev.seq or 0 }
        return true
    elseif ev.t == "vote" then
        if type(ev.voter) ~= "string" then return false end
        local map = state.votes[ev.id]
        if not map then map = {}; state.votes[ev.id] = map end
        local cur = map[ev.voter]
        if cur and (cur.seq or 0) >= (ev.seq or 0) then return false end
        map[ev.voter] = { c = ev.candidate, seq = ev.seq or 0, reason = ev.reason }
        return true
    end
    return false
end

-- Record the trade that delivered an awarded drop: tr = { to, by, at, item }. Pure. The award keeps it
-- (it is saved with the session); History copies it into the entry.
function Session.RecordTrade(state, id, tr)
    local a = state.awards[id]
    if not a or type(tr) ~= "table" then return false end
    a.trade = { to = tr.to, by = tr.by, at = tr.at, item = tr.item }
    a.delivered = true
    return true
end

-- Events strictly after `rev`, from a stored log (used to answer SYNC_REQ).
function Session.EventsSince(log, rev)
    local out = {}
    for _, ev in ipairs(log or {}) do
        if ev.rev > rev then out[#out + 1] = ev end
    end
    return out
end

-- Seconds left to respond (pure): the session's open time plus the ruleset timeout.
function Session.TimeLeft(state, timeout, now)
    if not state or not state.openTime or state.openTime == 0 then return nil end
    return state.openTime + (timeout or 60) - now
end

-- Vote count for a candidate on a drop.
function Session.VoteCount(state, id, candidate)
    local n = 0
    for _, v in pairs(state.votes[id] or {}) do
        if v.c == candidate then n = n + 1 end
    end
    return n
end

-- ============================================================
--  Game side
-- ============================================================
Session.state = nil     -- the live state (also char.session)
Session.log = nil       -- ordered events, kept for answering SYNC_REQ (char.sessionLog)
local mySeq = 0
local takeoverTimer

local function Char() return LC.DB.Char() end

function Session.Get() return Session.state end
function Session.IsOpen() return Session.state ~= nil and Session.state.guid ~= nil and not Session.state.closed end

local function Install(state, log)
    Session.state, Session.log = state, log
    local c = Char()
    c.session, c.sessionLog = state, log
end

-- Restore after /reload or login (R-3).
function Session.Restore()
    local c = Char()
    if type(c.session) == "table" and c.session.guid then
        Session.state = c.session
        Session.log = type(c.sessionLog) == "table" and c.sessionLog or {}
        return true
    end
    return false
end

function Session.Clear()
    Session.state, Session.log = nil, nil
    local c = LC.DB.sv and Char()
    if c then c.session, c.sessionLog = nil, nil end
    LC.Fire("NSRT_LC_SESSION_CLOSED")
end

local function FireUpdated(changed)
    LC.History.Record()
    LC.Trade.Refresh()
    LC.Fire("NSRT_LC_SESSION_UPDATED", changed)
end

-- ML only: stamp and apply a log event, then broadcast it.
function Session.Emit(ev)
    if LC.Preview then
        -- Preview: apply locally, never broadcast or save.
        local st = Session.state
        if not st then return false end
        ev.rev, ev.epoch, ev.time = st.rev + 1, st.epoch, ev.time or GetServerTime()
        if not Session.Apply(st, ev) then return false end
        Session.log[#Session.log + 1] = ev
        FireUpdated({ ev.id })
        if ev.t == "close" then LC.Fire("NSRT_LC_SESSION_CLOSED") end
        return true
    end
    local state = Session.state
    if ev.t == "open" then
        state = Session.NewState()
        Install(state, {})
        ev.rev = 1
        ev.epoch = 0
    else
        if not state then return false end
        ev.rev = state.rev + 1
        ev.epoch = state.epoch
    end
    ev.time = ev.time or GetServerTime()
    local ok, reason = Session.Apply(state, ev)
    if not ok then LC.Debug("emit failed", ev.t, reason) return false end
    Session.log[#Session.log + 1] = ev
    LC.Comms.SendLogEvent(ev)
    if ev.t == "open" then LC.Fire("NSRT_LC_SESSION_OPENED") else FireUpdated({ ev.id }) end
    if ev.t == "close" then LC.Fire("NSRT_LC_SESSION_CLOSED") end
    return true
end

-- Any client: a log event arrived from `sender`.
function Session.ReceiveLog(ev, sender)
    local state = Session.state
    if ev.t ~= "authority" and ev.t ~= "open" and state and state.ml and sender ~= state.ml then return end
    if ev.t == "open" then
        if not LC.Ruleset.IsActive() then return end
        if sender ~= LC.Ruleset.MLKey() and sender ~= LC.Ruleset.Leader() then return end
        if state and state.guid == ev.guid then return end
        state = Session.NewState()
        Install(state, {})
    elseif not state then
        LC.Comms.Send("SYNC_REQ", { r = 0 }, "RAID", sender)
        return
    end
    local ok, reason = Session.Apply(state, ev)
    if ok then
        if reason ~= "dup" then
            Session.log[#Session.log + 1] = ev
            if ev.t == "open" then LC.Fire("NSRT_LC_SESSION_OPENED") else FireUpdated({ ev.id }) end
            if ev.t == "close" then LC.Fire("NSRT_LC_SESSION_CLOSED") end
        end
    elseif reason == "gap" then
        Session.RequestSync(sender)
    end
end

function Session.RequestSync(target)
    local state = Session.state
    local to = target or (state and state.ml) or LC.Ruleset.MLKey()
    if not to then return end
    LC.Comms.Send("SYNC_REQ", { g = state and state.guid, r = state and state.rev or 0 }, "RAID", to)
end

-- Answer a SYNC_REQ: log events first on NSLC, candidate detail per drop on NSLCB.
function Session.ReceiveSyncRequest(msg, sender)
    local state = Session.state
    if not state or type(msg) ~= "table" then return end
    if not (LC.Ruleset.IAmCouncil() or LC.Ruleset.IAmML()) then return end
    if msg.g and msg.g ~= state.guid then msg.r = 0 end
    local events = Session.EventsSince(Session.log, tonumber(msg.r) or 0)
    LC.Comms.Send("SYNC", { g = state.guid, ev = events }, "RAID", sender)
    -- candidate detail, open drops first, only to council clients
    if LC.Ruleset.IsCouncil(sender) then
        for _, id in ipairs(state.order) do
            local detail = { id = id, r = state.responses[id], s = state.snapshots and state.snapshots[id], v = state.votes[id] }
            if detail.r or detail.s or detail.v then
                LC.Comms.Send("DETAIL", { g = state.guid, d = detail }, "RAID", sender, "bulk")
            end
        end
    end
end

function Session.ReceiveSync(msg, sender)
    if type(msg) ~= "table" or type(msg.ev) ~= "table" then return end
    for _, ev in ipairs(msg.ev) do Session.ReceiveLog(ev, sender) end
end

function Session.ReceiveDetail(msg, sender)
    local state = Session.state
    if type(msg) ~= "table" or not state or msg.g ~= state.guid or type(msg.d) ~= "table" then return end
    local d = msg.d
    for from, r in pairs(d.r or {}) do
        Session.ApplyFree(state, { t = "response", id = d.id, from = from, response = r.response, note = r.note,
            gear = r.gear, tier = r.tier, tg = r.tg, spec = r.spec, auto = r.auto, sim = r.sim, simAge = r.simAge, ilvl = r.ilvl, seq = r.seq })
    end
    for from, r in pairs(d.s or {}) do
        Session.ApplyFree(state, { t = "snapshot", id = d.id, from = from, gear = r.gear, tier = r.tier, tg = r.tg,
            spec = r.spec, sim = r.sim, simAge = r.simAge, seq = r.seq })
    end
    for voter, v in pairs(d.v or {}) do
        Session.ApplyFree(state, { t = "vote", id = d.id, voter = voter, candidate = v.c, seq = v.seq, reason = v.reason })
    end
    FireUpdated({ d.id })
end

-- A response from a raider (or entered by the council on their behalf).
function Session.AddResponse(ev, sender)
    local state = Session.state
    if not state or state.closed then return end
    ev.t = "response"
    if sender ~= ev.from and not LC.Ruleset.IsCouncil(sender) then return end   -- only council may answer for others
    if Session.ApplyFree(state, ev) then FireUpdated({ ev.id }) end
end

-- A participant's snapshot of every drop in the session: { g = guid, from, spec, tier, tg, seq, items = { [dropID] = { gear, sim, simAge } } }.
-- Anyone may send their own; only the council may send for someone else.
function Session.AddSnapshot(msg, sender)
    local state = Session.state
    if not state or state.closed or type(msg) ~= "table" or type(msg.items) ~= "table" then return end
    if msg.g ~= state.guid or type(msg.from) ~= "string" then return end
    if sender ~= msg.from and not LC.Ruleset.IsCouncil(sender) then return end
    local changed = {}
    for id, it in pairs(msg.items) do
        if type(it) == "table" and Session.ApplyFree(state, { t = "snapshot", id = id, from = msg.from, gear = it.gear, tier = msg.tier,
            tg = msg.tg, spec = msg.spec, sim = it.sim, simAge = it.simAge, seq = msg.seq }) then
            changed[#changed + 1] = id
        end
    end
    if #changed > 0 then FireUpdated(changed) end
end

-- Build my own snapshot of the open session: spec, tier slots, and what I have equipped for each drop.
-- Pure of the network, so the preview and specs can use it.
function Session.BuildSnapshot(state, me)
    local specIndex = GetSpecialization and GetSpecialization()
    local msg = { g = state.guid, from = me, seq = Session.NextSeq(), items = {},
        spec = specIndex and GetSpecializationInfo(specIndex) or nil,
        tier = LC.Items.TierCount(), tg = LC.Items.TierGear() }
    local gearByLoc = {}                                  -- one slot lookup per equip location, not per drop
    for _, id in ipairs(state.order) do
        local drop = state.drops[id]
        if drop then
            local equipLoc = select(4, C_Item.GetItemInfoInstant(drop.itemID))
            local gear
            if equipLoc and equipLoc ~= "" then
                gear = gearByLoc[equipLoc]
                if not gear then gear = LC.Items.EquippedForEquipLoc(equipLoc); gearByLoc[equipLoc] = gear end
            end
            local sim = LC.Sims.Get(me, drop.itemID)
            msg.items[id] = { gear = (gear and #gear > 0) and gear or nil, sim = sim and sim.pct or nil, simAge = sim and sim.at or nil }
        end
    end
    return msg
end

-- On session open every client sends its own snapshot, whether or not it ever answers an item.
function Session.SendSnapshot()
    local state = Session.state
    if not state or state.closed or LC.Preview or LC.dead then return end
    local me = LC.Roster.MyKey()
    if not me then return end
    local msg = Session.BuildSnapshot(state, me)
    LC.Comms.Send("SNAPSHOT", msg, "RAID", nil, "bulk")
    Session.AddSnapshot(msg, me)
end

function Session.AddVote(ev, sender)
    local state = Session.state
    if not state or state.closed then return end
    if not LC.Ruleset.IsCouncil(sender) or sender ~= ev.voter then return end
    ev.t = "vote"
    if Session.ApplyFree(state, ev) then FireUpdated({ ev.id }) end
end

function Session.NextSeq()
    mySeq = math.max(mySeq + 1, GetServerTime() * 10)
    return mySeq
end

-- ---- authority handoff (R-4) ----------------------------------
-- The next council member in a deterministic order sees a "Take over" prompt after 10 s;
-- any council member can claim at once.
local function Candidates()
    local list = {}
    local leader = LC.Ruleset.Leader()
    if leader then list[#list + 1] = leader end
    local assistants = {}
    for key, m in pairs(LC.Roster.All()) do if m.rank == 1 then assistants[#assistants + 1] = m end end
    table.sort(assistants, function(a, b) return a.index < b.index end)
    for _, m in ipairs(assistants) do list[#list + 1] = m.key end
    local council = {}
    for key, m in pairs(LC.Roster.All()) do
        if LC.Ruleset.IsCouncil(key) then council[#council + 1] = m end
    end
    table.sort(council, function(a, b) return a.index < b.index end)
    for _, m in ipairs(council) do list[#list + 1] = m.key end
    return list
end

function Session.CheckAuthority()
    local state = Session.state
    if not state or state.closed or not state.ml then return end
    if LC.Roster.IsOnline(state.ml) and LC.Roster.InGroup(state.ml) then
        if takeoverTimer then takeoverTimer:Cancel(); takeoverTimer = nil end
        return
    end
    if takeoverTimer then return end
    takeoverTimer = C_Timer.NewTimer(10, function()
        takeoverTimer = nil
        local s = Session.state
        if not s or s.closed then return end
        if LC.Roster.IsOnline(s.ml) then return end
        local me = LC.Roster.MyKey()
        for _, key in ipairs(Candidates()) do
            if LC.Roster.IsOnline(key) and key ~= s.ml then
                if key == me then LC.Fire("NSRT_LC_TAKEOVER_AVAILABLE") end
                break
            end
        end
    end)
end

function Session.Claim()
    local state = Session.state
    if not state or not LC.Ruleset.IAmCouncil() then return false end
    local ev = { t = "authority", ml = LC.Roster.MyKey(), rev = state.rev + 1, epoch = state.epoch + 1,
        time = GetServerTime() }
    local ok = Session.Apply(state, ev)
    if not ok then return false end
    Session.log[#Session.log + 1] = ev
    LC.Comms.SendLogEvent(ev)
    FireUpdated({})
    return true
end

-- Close the session when the ML says so (or leave it for the next kill, which replaces it).
-- Who may close: the loot master, whoever opened this session (it records its loot master, so this still
-- holds after a /reload when no group ruleset is active), or anyone holding a session they cannot be part
-- of any more (not in a group): that one is only closed locally.
function Session.CanClose()
    local st = Session.state
    if not (st and st.guid and not st.closed) then return false end
    return LC.Ruleset.IAmML() or st.ml == LC.Roster.MyKey() or not LC.Ruleset.IsActive()
end

function Session.Close()
    if not Session.IsOpen() or not Session.CanClose() then return end
    if LC.Ruleset.IAmML() or LC.Preview or Session.state.ml == LC.Roster.MyKey() then
        Session.Emit({ t = "close" })
    end
    if Session.state and not LC.Ruleset.IsActive() then Session.Clear() end   -- nobody left to tell
end

-- A test (/ns lc test) or the hidden preview is running: ending the session also ends it, like /ns lc stop.
local function FakeRunning() return LC.Preview or (LC.Sim and LC.Sim.loopback) end

-- Loot master: ask first, then end the session for everyone, end the test if one is running (what /ns lc stop
-- does) and close the council window. Used by the council window button and /ns lc end.
local function ConfirmedEnd()
    local fake = FakeRunning()
    Session.Close()
    if fake then LC.Sim.StopAny() end
    local vf = LC.UI and LC.UI.VotingFrame
    if vf and vf.Close then vf.Close() end
end

function Session.RequestClose()
    if not Session.IsOpen() then
        -- a finished test session can still be running its fake group: ending it is the same as /ns lc stop
        if FakeRunning() then LC.Sim.StopAny() return end
        LC.Print(LC.Loc("No session is open."))
        return
    end
    if not Session.CanClose() then LC.Print(LC.Loc("Only the loot master can end the session.")) return end
    local C = LC.EnsureKit() and NSI.UI and NSI.UI.Components
    if C and C.CreateDialog and not LC.Preview then
        -- The dialog is cached by name, so its action is set once; the wording is set again on every open.
        local dlg = C.CreateDialog("NSLCEndSession", LC.Loc("End session"),
            LC.Loc("End the session for everyone? Items not yet awarded stay with their holders."),
            LC.Loc("End session"), ConfirmedEnd, LC.Loc("Cancel"), nil)
        if dlg and dlg.bodyFS then
            dlg.bodyFS:SetText(FakeRunning() and LC.Loc("End the test session? The test items and setup are cleared.")
                or LC.Loc("End the session for everyone? Items not yet awarded stay with their holders."))
        end
    else
        ConfirmedEnd()
    end
end

-- Messages for this player only (never sent to chat): a session started, every item awarded, a session ended.
local announced, allDoneGuid
LC.On("NSRT_LC_SESSION_OPENED", function()
    local st = Session.state
    announced, allDoneGuid = st and st.guid or nil, nil
    LC.Print(LC.Loc("Loot session started."))
end)
LC.On("NSRT_LC_SESSION_UPDATED", function()
    local st = Session.state
    if st and st.guid and not st.closed then announced = announced or st.guid end   -- restored after /reload
    if not (st and st.guid and not st.closed and #st.order > 0) or allDoneGuid == st.guid then return end
    for _, id in ipairs(st.order) do
        if not st.awards[id] then return end
    end
    allDoneGuid = st.guid
    LC.Print(LC.Loc("All items awarded."))
    -- The loot master's client ends the session for everyone a moment later (not in the preview, which stays open to play with).
    if LC.Preview or not Session.CanClose() then return end
    local guid = st.guid
    C_Timer.After(1, function()
        local cur = Session.state
        if not (cur and cur.guid == guid and not cur.closed and Session.CanClose()) then return end
        for _, id in ipairs(cur.order) do
            if not cur.awards[id] then return end       -- an award was changed back in the meantime
        end
        ConfirmedEnd()
    end)
end)
LC.On("NSRT_LC_SESSION_CLOSED", function()
    if not announced then return end        -- once per session: Clear fires this again after Close
    announced, allDoneGuid = nil, nil
    LC.Print(LC.Loc("Loot session ended."))
end)

LC.On("NSRT_LC_SESSION_OPENED", function() Session.SendSnapshot() end)

function Session.Shutdown()
    if takeoverTimer then takeoverTimer:Cancel(); takeoverTimer = nil end
    Session.state, Session.log = nil, nil   -- the saved copy on disk stays untouched
end
LC.RegisterShutdown("Session", Session.Shutdown)
