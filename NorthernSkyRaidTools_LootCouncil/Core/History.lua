-- ============================================================
--  Core/History.lua - award history: store, audit trail, tree, export, import, sync (H-1..H-5)
--
--  Partitioned by season key. Every client records the awards it sees, keyed by Drop ID, and keeps the
--  entry up to date as the session changes: a reassignment, an undo, and the trade that actually delivered
--  the item all update the same entry. Nothing is ever dropped silently: an undone award stays in the
--  history, marked void, with who undid it and when.
--
--  Entry (v2):
--    id, itemID, item (item string with bonus IDs), difficulty, encounterID, boss, kill (kill time), time (awarded)
--    winner, reason, response, source, by (who awarded), council (votes at the award), votes = { for, total }
--    lm      bonus rolls only: the loot master (raid leader) of the session it was rolled in; awards use `by`
--    holder  who held the item when it was awarded (the one who has to trade it)
--    trade   { to, by, at, item } the trade that delivered it: who received it, who traded it, when, and the
--            exact item string that left the trade window. nil until it is traded.
--    audit   { { who, when, action = "award"|"undo"|"reassign", from, to, why }, ... }
--    void    { who, when, why } set when the award was undone and not given again
--    upd     time of the last change; the newer entry wins when two clients disagree
--
--  Query, Tree, Status and the exports are pure (specs in tools/lc-tests).
-- ============================================================
local ADDON, LC = ...
local History = {}
LC.History = History

local EXPORT_PREFIX = "!NSRT:LCHistory:"
local TRADE_WINDOW = 4 * 3600          -- raid drops can be traded for 4 hours after the kill
History.DAY_START_HOUR = 6             -- a raid night that runs past midnight stays under one day

local type, pairs, ipairs, tonumber, tostring = type, pairs, ipairs, tonumber, tostring

function History.SeasonKey()
    return (LC.Season and LC.Season.key) or "current"
end

local function List()
    if LC.Preview then
        History.previewList = History.previewList or {}
        return History.previewList
    end
    return LC.DB.History(History.SeasonKey())
end

-- id -> position, rebuilt when the list changed size behind our back (a removal clears it explicitly).
local indexes = setmetatable({}, { __mode = "k" })
local function Find(list, id)
    local ix = indexes[list]
    if not ix or ix.n ~= #list then
        ix = { n = #list, map = {} }
        for i, e in ipairs(list) do ix.map[e.id] = i end
        indexes[list] = ix
    end
    return ix.map[id], ix
end

-- ---- sanitising (anything from the network or a pasted string is untrusted) -------------------
local function Str(v, max)
    if type(v) == "string" and #v > 0 then return v:sub(1, max or 80) end
end
local function Num(v)
    v = tonumber(v)
    if v and v == v and v > -1e12 and v < 1e12 then return v end
end
local function ItemString(v)
    if type(v) == "string" and #v <= 300 and v:match("^item:[%d:%-]*$") then return v end
end

function History.Sanitize(e)
    if type(e) ~= "table" or type(e.id) ~= "string" or #e.id == 0 or #e.id > 60 then return nil end
    local itemID = Num(e.itemID)
    if not itemID or itemID <= 0 then return nil end
    local out = {
        id = e.id, itemID = itemID, item = ItemString(e.item), difficulty = Num(e.difficulty), encounterID = Num(e.encounterID),
        boss = Str(e.boss, 60), kill = Num(e.kill), time = Num(e.time), winner = Str(e.winner), reason = Str(e.reason, 40),
        response = Str(e.response, 40), source = Str(e.source, 20), by = Str(e.by), holder = Str(e.holder), upd = Num(e.upd),
        class = Str(e.class, 20), reasonText = Str(e.reasonText, 40), lm = Str(e.lm),
    }
    if type(e.trade) == "table" then
        out.trade = { to = Str(e.trade.to), by = Str(e.trade.by), at = Num(e.trade.at), item = ItemString(e.trade.item) }
    end
    if type(e.void) == "table" then
        out.void = { who = Str(e.void.who), when = Num(e.void.when), why = Str(e.void.why, 120) }
    end
    if type(e.audit) == "table" then
        local audit = {}
        for i, x in ipairs(e.audit) do
            if i > 20 then break end
            if type(x) == "table" and (x.action == "award" or x.action == "undo" or x.action == "reassign") then
                audit[#audit + 1] = { who = Str(x.who), when = Num(x.when), action = x.action, from = Str(x.from), to = Str(x.to), why = Str(x.why, 120) }
            end
        end
        if #audit > 0 then out.audit = audit end
    end
    if type(e.council) == "table" then
        local c, n = {}, 0
        for voter, cand in pairs(e.council) do
            if n >= 40 then break end
            if type(voter) == "string" and type(cand) == "string" then c[voter:sub(1, 80)] = cand:sub(1, 80); n = n + 1 end
        end
        out.council = c
    end
    if type(e.votes) == "table" then out.votes = { ["for"] = Num(e.votes["for"]) or 0, total = Num(e.votes.total) or 0 } end
    return out
end

-- ---- store ----------------------------------------------------------------------------------
-- Insert or update by id. The entry with the newer `upd` wins; an identical entry is not a change.
-- Returns changed (boolean), "added" | "updated".
function History.Upsert(rec)
    local list = List()
    local pos, ix = Find(list, rec.id)
    if pos then
        local cur = list[pos]
        if (rec.upd or rec.time or 0) < (cur.upd or cur.time or 0) then return false end
        if LC.DB.Equal(cur, rec) then return false end
        list[pos] = rec
        return true, "updated"
    end
    list[#list + 1] = rec
    ix.n, ix.map[rec.id] = #list, #list
    return true, "added"
end

-- Kept for callers that only add: true when something changed.
function History.Add(entry) return (History.Upsert(entry)) end

function History.Get(id)
    local list = List()
    local pos = Find(list, id)
    return pos and list[pos] or nil
end

-- "Clear history": removes every entry of the season and remembers when, so the awards of a session that is still
-- open (or entries a peer sends) are not recorded again. Entries awarded after this moment are recorded normally.
local previewCleared = 0
local function ClearedAt()
    if LC.Preview then return previewCleared end
    return LC.DB.G().historyClearedAt or 0
end

function History.Clear()
    local list = List()
    local n = #list
    wipe(list)
    indexes[list] = nil
    local now = GetServerTime()
    if LC.Preview then previewCleared = now else LC.DB.G().historyClearedAt = now end
    LC.Fire("NSRT_LC_HISTORY_CHANGED")
    return n
end

function History.Remove(id)
    local list = List()
    for i = #list, 1, -1 do
        if list[i].id == id then table.remove(list, i); indexes[list] = nil; return true end
    end
end

function History.Query(filter)
    local out = {}
    for _, e in ipairs(List()) do
        local ok = true
        if filter then
            if filter.player and e.winner ~= filter.player then ok = false end
            if filter.itemID and e.itemID ~= filter.itemID then ok = false end
            if filter.encounterID and e.encounterID ~= filter.encounterID then ok = false end
        end
        if ok then out[#out + 1] = e end
    end
    return out
end

-- ---- per-player lookback (pure) --------------------------------------------------------------
-- What the council sees next to a candidate: everything a player was given in the last `days` days, newest
-- first. Undone awards are left out. Bonus rolls are ordinary entries (source = "bonus").
function History.ForPlayer(list, key, now, days)
    local since = (now or 0) - (days or 30) * 86400
    local out = {}
    for _, e in ipairs(list or {}) do
        if e.winner == key and not e.void and (e.time or 0) >= since then out[#out + 1] = e end
    end
    table.sort(out, function(a, b)
        if (a.time or 0) ~= (b.time or 0) then return (a.time or 0) > (b.time or 0) end
        return tostring(a.id) > tostring(b.id)
    end)
    return out
end

-- Whole weeks between t and now (0 = the last seven days). Never negative.
function History.WeeksAgo(t, now)
    return math.max(0, math.floor(((now or 0) - (t or 0)) / (7 * 86400)))
end

function History.WeekLabel(weeks)
    if weeks <= 0 then return "This week" end
    if weeks == 1 then return "1 week ago" end
    return weeks .. " weeks ago"
end

-- Newest-first entries -> { { weeks, label, items = { e, ... } }, ... }, one group per week.
function History.GroupByWeek(entries, now)
    local groups = {}
    for _, e in ipairs(entries) do
        local w = History.WeeksAgo(e.time, now)
        local g = groups[#groups]
        if not g or g.weeks ~= w then
            g = { weeks = w, label = History.WeekLabel(w), items = {} }
            groups[#groups + 1] = g
        end
        g.items[#g.items + 1] = e
    end
    return groups
end

-- Do two sets of inventory slots ({ [slot] = true }) share a slot? Either one nil = unknown = false.
function History.SlotsOverlap(a, b)
    if not a or not b then return false end
    for slot in pairs(a) do if b[slot] then return true end end
    return false
end

-- ---- building entries from the session ------------------------------------------------------
local function CopyAudit(list)
    if type(list) ~= "table" or #list == 0 then return nil end
    local out = {}
    for i, x in ipairs(list) do
        out[i] = { who = x.who, when = x.when, action = x.action, from = x.from, to = x.to, why = x.why }
    end
    return out
end

local function Votes(council, winner)
    local n, total = 0, 0
    for _, cand in pairs(council or {}) do
        total = total + 1
        if cand == winner then n = n + 1 end
    end
    return { ["for"] = n, total = total }
end

-- Build a record from the session state for one awarded drop.
function History.FromSession(state, id)
    local a, d = state.awards[id], state.drops[id]
    if not (a and d) then return nil end
    local audit = CopyAudit(state.audit and state.audit[id])
    local upd = a.time or 0
    for _, x in ipairs(audit or {}) do if (x.when or 0) > upd then upd = x.when end end
    local trade
    if a.trade then
        trade = { to = a.trade.to, by = a.trade.by, at = a.trade.at, item = a.trade.item }
        if (trade.at or 0) > upd then upd = trade.at end
    end
    -- The winner's class and the label of the reason at the time: both can change or be unknown later.
    local member = LC.Roster.Get and LC.Roster.Get(a.winner)
    local resp = a.reason and LC.Ruleset.ResponseById and LC.Ruleset.ResponseById(a.reason)
    return { id = id, itemID = d.itemID, item = d.item, difficulty = d.difficulty,
        class = member and member.class or nil, reasonText = resp and resp.text and LC.Loc(resp.text) or nil,
        encounterID = d.enc or state.encounterID, boss = d.boss, kill = d.kill or state.killTime,
        time = a.time or d.kill or state.killTime, winner = a.winner, reason = a.reason, response = a.response,
        source = a.source, by = a.by, council = a.council, votes = Votes(a.council, a.winner),
        holder = a.holder or d.holder, trade = trade, audit = audit, upd = upd }
end

-- Record every award the session shows, and mark undone ones. Idempotent. Fires NSRT_LC_HISTORY_CHANGED
-- when anything changed.
function History.Record()
    local state = LC.Session.state
    if not state then return end
    local changed = false
    local cleared = ClearedAt()
    for id in pairs(state.awards) do
        local rec = History.FromSession(state, id)
        if rec and (rec.time or 0) > cleared and History.Upsert(rec) then changed = true end
    end
    -- An award that was undone and not given again stays in the history, marked void.
    for id, audit in pairs(state.audit or {}) do
        if not state.awards[id] and state.drops[id] then
            local last = audit[#audit]
            local cur = History.Get(id)
            if last and last.action == "undo" and cur and not (cur.void and cur.void.when == last.when) then
                local rec = LC.DB.Copy(cur)
                rec.void = { who = last.who, when = last.when, why = last.why }
                rec.audit = CopyAudit(audit)
                rec.upd = math.max(cur.upd or 0, last.when or 0)
                if History.Upsert(rec) then changed = true end
            end
        end
    end
    if changed then LC.Fire("NSRT_LC_HISTORY_CHANGED") end
    return changed
end

-- ---- status, day key and the tree (pure) ----------------------------------------------------
-- "void" undone | "traded" delivered to the winner | "mismatch" delivered to someone other than the winner |
-- "self" the winner looted it themselves, nothing to trade | "pending" waiting for a trade |
-- "expired" the 4 hour window closed without a recorded trade.
function History.Status(e, now)
    if e.void then return "void" end
    local t = e.trade
    if t then
        if e.winner and t.to and t.to ~= e.winner then return "mismatch" end
        return "traded"
    end
    if e.winner and e.holder and e.winner == e.holder then return "self" end
    if now and now > (e.kill or e.time or 0) + TRADE_WINDOW then return "expired" end
    return "pending"
end

function History.DayKey(t)
    return date("%Y-%m-%d", (t or 0) - History.DAY_START_HOUR * 3600)
end

function History.BossName(encounterID, name)
    if type(name) == "string" and name ~= "" then return name end
    local NSI = LC.NSI
    local season = LC.Season and LC.Season.encounters and encounterID and LC.Season.encounters[encounterID]
    if season then return season end
    local known = NSI and NSI.BossNames and encounterID and NSI.BossNames[encounterID]
    if known then return known end
    if encounterID and encounterID > 0 then return "Encounter " .. encounterID end
    return "Unknown boss"
end

local DIFF_ORDER = { [16] = 1, [15] = 2, [14] = 3, [17] = 4 }

local function NewCounts() return { items = 0, undone = 0, pending = 0, issues = 0 } end
local function Count(c, status)
    if status == "void" then c.undone = c.undone + 1 return end
    c.items = c.items + 1
    if status == "pending" then c.pending = c.pending + 1
    elseif status == "mismatch" or status == "expired" then c.issues = c.issues + 1 end
end

-- days (newest first) -> difficulties (Mythic first) -> bosses (kill order) -> items (award order).
-- Every node has key (unique in the tree), counts = { items, undone, pending, issues }.
function History.Tree(list, now)
    local days, byDay = {}, {}
    for _, e in ipairs(list) do
        local kill = e.kill or e.time or 0
        local dk = History.DayKey(kill)
        local day = byDay[dk]
        if not day then
            day = { key = "d:" .. dk, day = dk, stamp = kill, diffs = {}, byDiff = {}, counts = NewCounts() }
            byDay[dk] = day
            days[#days + 1] = day
        end
        if kill < day.stamp then day.stamp = kill end
        local dn = e.difficulty or 0
        local diff = day.byDiff[dn]
        if not diff then
            diff = { key = day.key .. "|" .. dn, difficulty = dn, bosses = {}, byBoss = {}, counts = NewCounts() }
            day.byDiff[dn] = diff
            day.diffs[#day.diffs + 1] = diff
        end
        local bk = (e.encounterID and e.encounterID > 0) and e.encounterID or ("n:" .. tostring(e.boss or "?"))
        local boss = diff.byBoss[bk]
        if not boss then
            boss = { key = diff.key .. "|" .. tostring(bk), encounterID = e.encounterID, name = History.BossName(e.encounterID, e.boss),
                firstKill = kill, kills = {}, items = {}, counts = NewCounts() }
            diff.byBoss[bk] = boss
            diff.bosses[#diff.bosses + 1] = boss
        end
        if e.boss and boss.name:find("^Encounter ") then boss.name = e.boss end
        if kill < boss.firstKill then boss.firstKill = kill end
        if not boss.kills[kill] then boss.kills[kill] = true; boss.killCount = (boss.killCount or 0) + 1 end
        boss.items[#boss.items + 1] = e
        local status = History.Status(e, now)
        for _, node in ipairs({ day.counts, diff.counts, boss.counts }) do Count(node, status) end
    end
    table.sort(days, function(a, b) return a.day > b.day end)
    for _, day in ipairs(days) do
        table.sort(day.diffs, function(a, b)
            local oa, ob = DIFF_ORDER[a.difficulty] or 9, DIFF_ORDER[b.difficulty] or 9
            if oa ~= ob then return oa < ob end
            return a.difficulty > b.difficulty
        end)
        for _, diff in ipairs(day.diffs) do
            table.sort(diff.bosses, function(a, b)
                if a.firstKill ~= b.firstKill then return a.firstKill < b.firstKill end
                return a.name < b.name
            end)
            for _, boss in ipairs(diff.bosses) do
                table.sort(boss.items, function(a, b)
                    local ta, tb = a.time or 0, b.time or 0
                    if ta ~= tb then return ta < tb end
                    return a.id < b.id
                end)
            end
        end
    end
    return days
end

-- ---- export ----------------------------------------------------------------------------------
local function CSVField(v)
    v = tostring(v == nil and "" or v)
    if v:find('[",\n]') then v = '"' .. v:gsub('"', '""') .. '"' end
    return v
end

local function ISO(t)
    return t and date("!%Y-%m-%dT%H:%M:%SZ", t) or ""
end

local CSV_COLUMNS = { "raidDay", "difficulty", "boss", "item", "itemID", "itemString", "awardedTo", "reason", "response", "lootedBy",
    "tradedTo", "tradedBy", "tradedAtUTC", "tradedItemString", "status", "awardedAtUTC", "awardedBy", "dropID" }

function History.ToCSV(list, now)
    local rows = { table.concat(CSV_COLUMNS, ",") }
    local names = LC.Items and LC.Items.DifficultyName or {}
    for _, e in ipairs(list) do
        local t = e.trade or {}
        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(e.itemID) or nil
        rows[#rows + 1] = table.concat({
            CSVField(History.DayKey(e.kill or e.time)), CSVField(names[e.difficulty] or e.difficulty),
            CSVField(History.BossName(e.encounterID, e.boss)), CSVField(name), CSVField(e.itemID), CSVField(e.item),
            CSVField(e.winner), CSVField(e.reason), CSVField(e.response), CSVField(e.holder),
            CSVField(t.to), CSVField(t.by), CSVField(ISO(t.at)), CSVField(t.item), CSVField(History.Status(e, now)),
            CSVField(ISO(e.time)), CSVField(e.by), CSVField(e.id),
        }, ",")
    end
    return table.concat(rows, "\n")
end

local function JSONString(s)
    return '"' .. tostring(s):gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' elseif c == "\\" then return "\\\\" end
        return string.format("\\u%04x", c:byte())
    end) .. '"'
end

local function JSONValue(v)
    local t = type(v)
    if t == "string" then return JSONString(v) end
    if t == "number" then return string.format("%d", math.floor(v)) end
    if t == "boolean" then return v and "true" or "false" end
    if t == "table" then
        if #v > 0 then
            local parts = {}
            for i, x in ipairs(v) do parts[i] = JSONValue(x) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = JSONString(k) .. ":" .. JSONValue(v[k]) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

-- One object per entry, with the trade and the audit trail. Votes are counts only (who voted stays out).
function History.ToJSON(list, now)
    local parts = {}
    for _, e in ipairs(list) do
        local o = { id = e.id, raidDay = History.DayKey(e.kill or e.time), difficulty = e.difficulty or 0, encounterID = e.encounterID or 0,
            boss = History.BossName(e.encounterID, e.boss), itemID = e.itemID, item = e.item, awardedTo = e.winner, reason = e.reason,
            response = e.response, awardedBy = e.by, awardedAt = e.time, kill = e.kill, lootedBy = e.holder,
            status = History.Status(e, now), trade = e.trade, audit = e.audit, undone = e.void, votes = e.votes }
        parts[#parts + 1] = JSONValue(o)
    end
    return "[" .. table.concat(parts, ",") .. "]"
end

function History.ToString(list)
    local text = LC.Comms.Codec.encode({ v = 2, list = list })
    return text and (EXPORT_PREFIX .. text)
end

-- Returns number added or updated, or nil, reason.
function History.FromString(text)
    if type(text) ~= "string" or text:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then return nil, "not a history string" end
    local ok, data = pcall(LC.Comms.Codec.decode, text:sub(#EXPORT_PREFIX + 1))
    if not ok or type(data) ~= "table" or type(data.list) ~= "table" then return nil, "unreadable" end
    local n = 0
    for _, e in ipairs(data.list) do
        local clean = History.Sanitize(e)
        if clean and History.Upsert(clean) then n = n + 1 end
    end
    if n > 0 then LC.Fire("NSRT_LC_HISTORY_CHANGED") end
    return n
end

-- ---- peer sync (H-3) ---------------------------------------------------------------------------
-- A council member asks, a council member answers with entries changed since a time.
function History.ReceiveRequest(d, sender)
    if not LC.Ruleset.IsCouncil(sender) or not LC.Ruleset.IAmCouncil() then return end
    local since = type(d) == "table" and tonumber(d.since) or 0
    local list = {}
    for _, e in ipairs(History.Query()) do if (e.upd or e.time or 0) > since then list[#list + 1] = e end end
    if #list > 0 then LC.Comms.Send("HISTORY", { list = list }, "RAID", sender, "bulk") end
end

function History.ReceiveEntries(d, sender)
    if type(d) ~= "table" or type(d.list) ~= "table" then return end
    local changed = false
    local cleared = ClearedAt()
    for _, e in ipairs(d.list) do
        local clean = History.Sanitize(e)
        if clean and (clean.time or 0) > cleared and History.Upsert(clean) then changed = true end
    end
    if changed then LC.Fire("NSRT_LC_HISTORY_CHANGED") end
end
