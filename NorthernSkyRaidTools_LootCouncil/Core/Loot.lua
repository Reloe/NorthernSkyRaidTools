-- ============================================================
--  Core/Loot.lua - drop detection, rolls, holder tracking (R-1, R-2, CH-3, T-1, D-5)
--
--  Collection model (D-5): participants auto-pass the Blizzard rolls; the loot master and the
--  backup roller roll. Items that land on someone else are traded by their holder to the
--  winner. This file calls RollOnLoot; it never clicks or hides Blizzard's roll frames.
--
--  Why a backup roller: if the only roller is absent, disconnected or loot-locked and everyone
--  else passes, the item is gone. Two rollers plus the safety check below close that hole.
--  Nothing here runs during an encounter except hiding windows (ENCOUNTER_START).
-- ============================================================
local ADDON, LC = ...
local Loot = {}
LC.Loot = Loot

local floor = math.floor

local rescanTimers = {}
local attempt = 0
local current          -- { encounterID, difficulty, killTime, name }
local passWarned = false

local function CancelTimers()
    for i = #rescanTimers, 1, -1 do rescanTimers[i]:Cancel(); rescanTimers[i] = nil end
end

-- ---- safety check before auto-passing -----------------------------------
-- Your own setting (not the leader's). Only passes in guild groups by default, so a pug using the
-- council can never talk you out of a roll you would otherwise win. Also needs the loot master able
-- to collect: online and in the same zone. Otherwise the normal Blizzard roll stays.
function Loot.SafeToPass()
    local s = LC.DB.Settings()
    if not s.autoPass then return false, "auto-pass is off" end
    if s.autoPassGuildOnly and not LC.Roster.IsGuildGroup() then return false, "this is not a guild group" end
    local ml = LC.Ruleset.MLKey()
    if not ml then return false, "no loot master" end
    local m = LC.Roster.Get(ml)
    if not m or not m.online then return false, "the loot master is offline" end
    local me = LC.Roster.Get(LC.Roster.MyKey())
    if me and me.zone and m.zone and me.zone ~= m.zone then return false, "the loot master is in another zone" end
    return true
end

local function OnRoll(event, rollID)
    if not LC.Ruleset.IsActive() then return end
    local me = LC.Roster.MyKey()
    if LC.Ruleset.IsML(me) or LC.Ruleset.IsBackup(me) then
        local canNeed, canGreed = LC.Compat.GetRollOptions(rollID)
        local rollType = canNeed and 1 or (canGreed and 2 or 0)
        pcall(RollOnLoot, rollID, rollType)
        return
    end
    local safe, reason = Loot.SafeToPass()
    if safe then
        pcall(RollOnLoot, rollID, 0)
    elseif not passWarned then
        passWarned = true
        LC.Print(string.format(LC.Loc("Not auto-passing: %s. Roll as usual."), LC.Loc(reason)))
    end
end

-- ---- kill handling -----------------------------------------------------
local function RecordKill(encounterID, difficulty, killTime)
    local kills = LC.DB.G().kills
    kills[#kills + 1] = { encounterID = encounterID, difficulty = difficulty, time = killTime, roster = LC.Roster.SnapshotKillRoster() }
    while #kills > 500 do table.remove(kills, 1) end
    return kills[#kills]
end

local function OnEncounterStart()
    CancelTimers()
    LC.Fire("NSRT_LC_ENCOUNTER", true)    -- frames hide; nothing is sent during the fight (C-1)
end

local function OnEncounterEnd(event, encounterID, encounterName, difficultyID, groupSize, success)
    LC.Fire("NSRT_LC_ENCOUNTER", false)
    passWarned = false
    if success ~= 1 then return end
    local rs = LC.Ruleset.Get()
    if not rs then return end
    local diff = difficultyID
    if diff == 233 then diff = 16 end
    if not rs.difficulties[diff] then return end
    local killTime = GetServerTime()
    RecordKill(encounterID, diff, killTime)
    current = { encounterID = encounterID, difficulty = diff, killTime = killTime, name = encounterName }
    if LC.Ruleset.IAmML() then
        attempt = 0
        Loot.TryOpen()
    end
end

-- ---- building the session (ML only) -----------------------------------
-- Maps the encounter's drop list onto Drop IDs. The index is the nth copy of that item in the
-- kill (PRD 6.1), so the id is the same however Blizzard numbers lootListID.
function Loot.NumberDrops(drops, encounterID, killTime, fallbackDifficulty)
    local counts, out = {}, {}
    for _, d in ipairs(drops) do
        local dec = LC.Items.Decode(d.link)
        if dec then
            counts[dec.itemID] = (counts[dec.itemID] or 0) + 1
            local diff = LC.Items.ContextToDifficulty[dec.context] or fallbackDifficulty
            out[#out + 1] = {
                id = LC.Items.DropID(encounterID, killTime, dec.itemID, counts[dec.itemID]),
                item = dec.itemString, itemID = dec.itemID, difficulty = diff, index = counts[dec.itemID],
                holder = d.winnerName and LC.Roster.KeyFromName(d.winnerName) or nil,
                allPassed = d.allPassed or nil,
            }
        end
    end
    return out
end

function Loot.TryOpen()
    local k = current
    if not k or LC.dead then return end
    local drops = LC.Compat.GetDrops(k.encounterID)
    if drops and #drops > 0 then
        Loot.Stage(drops)
        return
    end
    attempt = attempt + 1
    if attempt < 8 then
        rescanTimers[#rescanTimers + 1] = C_Timer.NewTimer(math.min(1 + attempt, 4), Loot.TryOpen)
    else
        LC.Print(LC.Loc("No loot was found for this kill."))
    end
end

-- A kill's drops go into the queue and the Session Setup window asks what to do with them. If a
-- session is already running they just wait (a session is one list of drops, started once).
function Loot.Stage(drops)
    local k = current
    local list = Loot.NumberDrops(drops, k.encounterID, k.killTime, k.difficulty)
    if #list == 0 then return end
    local added = LC.Queue.Add({ encounterID = k.encounterID, killTime = k.killTime, name = k.name,
        roster = LC.Roster.SnapshotKillRoster(), drops = list })
    local allPassed = 0
    for _, d in ipairs(list) do if d.allPassed then allPassed = allPassed + 1 end end
    if allPassed > 0 then LC.Fire("NSRT_LC_ALLPASSED", allPassed) end
    -- Rolls resolve over the next seconds: pick up winners as holders.
    for _, delay in ipairs({ 3, 8, 20 }) do
        rescanTimers[#rescanTimers + 1] = C_Timer.NewTimer(delay, Loot.RescanQueue)
    end
    if LC.Session.IsOpen() then
        LC.Print(string.format(LC.Loc("%d new items are waiting. Close the current session to start a new one (/ns loot setup)."), added))
    else
        LC.Fire("NSRT_LC_SETUP")
    end
end

-- Start a session from the queue (Session Setup "Start"). Excluded items are dropped.
function Loot.StartSession()
    if not (LC.Ruleset.IsActive() and LC.Ruleset.IAmML()) then
        LC.Print(LC.Loc("Only the loot master can start a session."))
        return false
    end
    if LC.Session.IsOpen() and not LC.Preview then
        LC.Print(LC.Loc("A session is already open. Close it first."))
        return false
    end
    local items, roster = LC.Queue.Take()
    if #items == 0 then LC.Print(LC.Loc("Nothing to start: no items are selected.")) return false end
    local me = LC.Roster.MyKey()
    local drops, latest = {}, items[1]
    for i, it in ipairs(items) do
        drops[i] = { id = it.id, item = it.item, itemID = it.itemID, difficulty = it.difficulty, index = it.index,
            holder = it.holder, allPassed = it.allPassed, enc = it.enc, kill = it.kill, boss = it.boss }
        if (it.kill or 0) > (latest.kill or 0) then latest = it end
    end
    local guid = string.format("%d-%d-%s", latest.enc or 0, latest.kill or 0, (UnitGUID("player") or "x"):sub(-6))
    if LC.Queue.HasOverride() then guid = "test-" .. guid end
    local ok = LC.Session.Emit({
        t = "open", guid = guid, encounterID = latest.enc or 0, difficulty = latest.difficulty or 0, killTime = latest.kill or 0,
        ml = me, drops = drops, killRoster = roster, rulesetHash = LC.Ruleset.current.hash, runType = "main",
    })
    if ok then
        for _, delay in ipairs({ 3, 8, 20 }) do
            rescanTimers[#rescanTimers + 1] = C_Timer.NewTimer(delay, Loot.Rescan)
        end
    end
    return ok
end

-- Distinct kills among a list of entries that carry enc/kill (queue items or session drops).
local function Kills(list, getter)
    local seen, out = {}, {}
    for _, e in ipairs(list) do
        local d = getter(e)
        if d and d.enc and d.kill and not seen[d.enc .. ":" .. d.kill] then
            seen[d.enc .. ":" .. d.kill] = true
            out[#out + 1] = { enc = d.enc, kill = d.kill }
        end
    end
    return out
end

-- Update holders on the queued items from the live loot history.
function Loot.RescanQueue()
    if LC.Queue.HasOverride() or not LC.Ruleset.IAmML() then return end
    local items = LC.Queue.Items()
    local changed = false
    for _, kk in ipairs(Kills(items, function(it) return it end)) do
        local drops = LC.Compat.GetDrops(kk.enc)
        if drops then
            local byID = {}
            for _, d in ipairs(Loot.NumberDrops(drops, kk.enc, kk.kill, 0)) do byID[d.id] = d end
            for _, it in ipairs(items) do
                local d = byID[it.id]
                if d and d.holder and it.holder ~= d.holder then it.holder, changed = d.holder, true end
                if d and d.allPassed and not it.allPassed then it.allPassed, changed = true, true end
            end
        end
    end
    if changed then LC.Fire("NSRT_LC_QUEUE_CHANGED") end
end

-- Update holders from the live drop list.
function Loot.Rescan()
    local state = LC.Session.state
    if not (state and not state.closed and LC.Ruleset.IAmML()) then return end
    local ids = {}
    for _, id in ipairs(state.order) do ids[#ids + 1] = state.drops[id] end
    for _, kk in ipairs(Kills(ids, function(d) return d end)) do
        local drops = LC.Compat.GetDrops(kk.enc)
        if drops then
            for _, d in ipairs(Loot.NumberDrops(drops, kk.enc, kk.kill, state.difficulty)) do
                local sd = state.drops[d.id]
                if sd and d.holder and sd.holder ~= d.holder then
                    LC.Session.Emit({ t = "holder", id = d.id, holder = d.holder, expires = kk.kill + 4 * 3600 })
                end
                if sd and d.allPassed and not sd.allPassed then
                    sd.allPassed = true
                    LC.Fire("NSRT_LC_ALLPASSED", 1)
                end
            end
        end
    end
end

-- A holder reports they now hold an item (after a trade, or a roll the ML could not see).
function Loot.ReceiveHolder(d, sender)
    if type(d) ~= "table" or not LC.Ruleset.IAmML() then return end
    local state = LC.Session.state
    if not (state and state.drops[d.id]) then return end
    if d.holder ~= sender then return end          -- a holder may only report themselves
    if state.drops[d.id].holder ~= sender then
        LC.Session.Emit({ t = "holder", id = d.id, holder = sender, expires = d.expires })
    end
end

-- The kill being looted right now ({ encounterID, difficulty, killTime, name }) or nil.
function Loot.Current() return current end

function Loot.ReportHolder(dropID)
    LC.Comms.Send("HOLDER", { id = dropID, holder = LC.Roster.MyKey() }, "RAID")
end

-- ---- handlers ----------------------------------------------------------------
Loot.Handlers = {
    ENCOUNTER_START = OnEncounterStart,
    ENCOUNTER_END = OnEncounterEnd,
    START_LOOT_ROLL = OnRoll,
}

-- Update events are unverified names (PRD 11.1 row 2c): each is tried, unknown ones skipped.
function Loot.HistoryHandlers()
    local h = {}
    for _, event in ipairs(LC.Compat.LootHistoryEvents) do
        h[event] = function() if LC.Ruleset.IAmML() then Loot.Rescan() end end
    end
    return h
end

function Loot.Shutdown()
    CancelTimers()
    current = nil
end
LC.RegisterShutdown("Loot", Loot.Shutdown)
