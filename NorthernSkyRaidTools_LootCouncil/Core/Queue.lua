-- ============================================================
--  Core/Queue.lua - items waiting for a session ("Award later")
--
--  When a boss dies the loot master sees the Session Setup window. Anything not started is kept
--  here (saved per character) and shows up again at the next kill or with /ns loot setup. An item
--  leaves the queue when a session starts with it, when it is excluded at start, when it is
--  cleared, or when it is older than Queue.TTL (3 hours from the kill).
--
--  A transient override list (preview and /ns loot test) is used instead of the saved queue so fake
--  items never reach saved data. Prune is pure and covered by tools/lc-tests.
-- ============================================================
local ADDON, LC = ...
local Queue = {}
LC.Queue = Queue

Queue.TTL = 3 * 3600
local override                 -- { items = {}, roster = {} } while previewing or testing

-- Pure: the entries still alive at `now`.
function Queue.Prune(list, now, ttl)
    local out = {}
    for _, it in ipairs(list or {}) do
        local expires = it.expires or ((it.kill or 0) + (ttl or Queue.TTL))
        if now < expires then out[#out + 1] = it end
    end
    return out
end

local function Store()
    if override then return override end
    local c = LC.DB.sv and LC.DB.Char()
    if not c then return { items = {}, roster = {} } end
    local q = c.queue
    if type(q) ~= "table" then q = { items = {}, roster = {} }; c.queue = q end
    q.items = type(q.items) == "table" and q.items or {}
    q.roster = type(q.roster) == "table" and q.roster or {}
    return q
end

function Queue.SetOverride(items, roster)
    local set = {}
    for _, key in ipairs(roster or {}) do set[key] = true end
    override = { items = items or {}, roster = set }
end
function Queue.ClearOverride() override = nil end
function Queue.HasOverride() return override ~= nil end

-- The live list (expired entries are dropped first).
function Queue.Items()
    local q = Store()
    local alive = Queue.Prune(q.items, GetServerTime(), Queue.TTL)
    if #alive ~= #q.items then
        q.items = alive
        if #alive == 0 then q.roster = {} end
    end
    return q.items
end

function Queue.Count() return #Queue.Items() end

-- Seconds until the soonest entry expires, nil when empty.
function Queue.SecondsLeft()
    local soonest
    for _, it in ipairs(Queue.Items()) do
        local left = (it.expires or ((it.kill or 0) + Queue.TTL)) - GetServerTime()
        if not soonest or left < soonest then soonest = left end
    end
    return soonest
end

-- batch = { encounterID, killTime, name, roster = { keys }, drops = { numbered drops } }. Returns how many were new.
function Queue.Add(batch)
    local q = Store()
    Queue.Items()
    local have, added = {}, 0
    for _, it in ipairs(q.items) do have[it.id] = true end
    for _, d in ipairs(batch.drops or {}) do
        if not have[d.id] then
            q.items[#q.items + 1] = {
                id = d.id, item = d.item, itemID = d.itemID, difficulty = d.difficulty, index = d.index,
                holder = d.holder, allPassed = d.allPassed, enc = batch.encounterID, kill = batch.killTime,
                boss = batch.name, expires = (batch.killTime or GetServerTime()) + Queue.TTL, excluded = false,
            }
            added = added + 1
        end
    end
    for _, key in ipairs(batch.roster or {}) do q.roster[key] = true end
    LC.Fire("NSRT_LC_QUEUE_CHANGED")
    return added
end

-- Add an item from the loot master's bags by hand: item = { item = "item:...", itemID, difficulty }.
-- It becomes a drop of its own (encounter 0, kill time = now) held by me, with everyone in the group on the roster.
function Queue.AddManual(item)
    local q = Store()
    Queue.Items()
    local have = {}
    for _, it in ipairs(q.items) do have[it.id] = true end
    local now = GetServerTime()
    local index = 1
    while have[LC.Items.DropID(0, now, item.itemID, index)] do index = index + 1 end
    local me = LC.Roster.MyKey()
    q.items[#q.items + 1] = {
        id = LC.Items.DropID(0, now, item.itemID, index), item = item.item, itemID = item.itemID, difficulty = item.difficulty,
        index = index, holder = me, enc = 0, kill = now, boss = LC.Loc("Added manually"), expires = now + Queue.TTL,
        excluded = false, manual = true,
    }
    q.roster[me] = true
    for _, key in ipairs(LC.Roster.SnapshotKillRoster()) do q.roster[key] = true end
    LC.Fire("NSRT_LC_QUEUE_CHANGED")
    return true
end

function Queue.SetExcluded(id, value)
    for _, it in ipairs(Queue.Items()) do
        if it.id == id then it.excluded = value and true or false end
    end
    LC.Fire("NSRT_LC_QUEUE_CHANGED")
end

function Queue.Clear()
    local q = Store()
    q.items, q.roster = {}, {}
    LC.Fire("NSRT_LC_QUEUE_CHANGED")
end

-- Starting a session: returns the included items and the combined kill roster, and empties the queue.
-- Excluded items are discarded with it.
function Queue.Take()
    local q = Store()
    local items, roster = {}, {}
    for _, it in ipairs(Queue.Items()) do
        if not it.excluded then items[#items + 1] = it end
    end
    for key in pairs(q.roster) do roster[#roster + 1] = key end
    table.sort(roster)
    q.items, q.roster = {}, {}
    LC.Fire("NSRT_LC_QUEUE_CHANGED")
    return items, roster
end

function Queue.Shutdown() override = nil end
LC.RegisterShutdown("Queue", Queue.Shutdown)
