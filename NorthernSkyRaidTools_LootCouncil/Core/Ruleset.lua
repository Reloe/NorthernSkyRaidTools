-- ============================================================
--  Core/Ruleset.lua - leader settings: build, sanitise, broadcast, apply (D-3, D-4)
--
--  Owns: the ruleset defaults, validation of an incoming ruleset (never trust the wire),
--  the hash that identifies a ruleset, activation by the leader, application on every
--  other client and the council / loot master / backup roller resolution.
--
--  The current group leader's ruleset governs the session. Local settings matter only
--  when you lead. A ruleset carries `active`: false stands participants down.
-- ============================================================
local ADDON, LC = ...
local Ruleset = {}
LC.Ruleset = Ruleset

local type, tostring, tonumber, pairs, ipairs = type, tostring, tonumber, pairs, ipairs

-- Response ids, reason ids and sharing modes are permanent once released (PRD 5.4 rule 8).
Ruleset.defaults = {
    announce = true,            -- one raid chat line when the loot council is turned on
    backupName = "",            -- "" = first assistant. The loot master is always the raid leader.
    council = { assistants = true, minRank = -1, names = {} },   -- the leader is always on the council
    responses = {
        { id = "bis",     text = "BiS",           color = "best" },
        { id = "major",   text = "Major upgrade", color = "major" },
        { id = "minor",   text = "Minor upgrade", color = "minor" },
        { id = "offspec", text = "Offspec",       color = "offspec" },
        { id = "xmog",    text = "Transmog",      color = "xmog" },
        { id = "pass",    text = "Pass",          color = "pass" },
    },
    bySlot = {},                -- [equipLoc] = list like responses (V-4)
    sharing = "awards",         -- "awards" | "open" | "council"
    anonymous = false,
    chatAnnounce = true,
    timeout = 60,
    difficulties = { [14] = true, [15] = true, [16] = true },
    bank = {},                  -- ["Name-Realm"] = "bank" | "de"
}
LC.DB.RegisterDefaults("ruleset", Ruleset.defaults)

local SHARING = { awards = true, open = true, council = true }

local function Str(v, max, default)
    if type(v) ~= "string" then return default end
    return v:sub(1, max)
end

local function Bool(v, default)
    if type(v) == "boolean" then return v end
    return default
end

local function CleanResponses(list, limit)
    if type(list) ~= "table" then return nil end
    local out = {}
    for i = 1, math.min(#list, limit or 12) do
        local r = list[i]
        if type(r) == "table" and type(r.id) == "string" and r.id ~= "" then
            out[#out + 1] = { id = r.id:sub(1, 16), text = Str(r.text, 24, r.id), color = Str(r.color, 12, "pass"),
                needsNote = r.needsNote == true or nil }
        end
    end
    return out
end

-- Whitelist copy. Unknown keys are dropped, types and bounds enforced, lists capped.
function Ruleset.Sanitize(rs)
    local d = Ruleset.defaults
    local out = {}
    if type(rs) ~= "table" then rs = {} end
    out.announce = Bool(rs.announce, d.announce)
    out.backupName = Str(rs.backupName, 64, "")
    out.sharing = SHARING[rs.sharing] and rs.sharing or d.sharing
    out.anonymous = Bool(rs.anonymous, d.anonymous)
    out.chatAnnounce = Bool(rs.chatAnnounce, d.chatAnnounce)
    local t = tonumber(rs.timeout) or d.timeout
    out.timeout = math.max(10, math.min(300, t))

    local c = type(rs.council) == "table" and rs.council or {}
    out.council = { assistants = Bool(c.assistants, true), names = {}, minRank = -1 }
    local mr = tonumber(c.minRank)
    if mr and mr >= -1 and mr <= 20 then out.council.minRank = math.floor(mr) end
    if type(c.names) == "table" then
        for i = 1, math.min(#c.names, 40) do
            if type(c.names[i]) == "string" then out.council.names[#out.council.names + 1] = c.names[i]:sub(1, 64) end
        end
    end

    out.responses = CleanResponses(rs.responses, 7)
    if not out.responses or #out.responses == 0 then out.responses = CleanResponses(d.responses) end
    out.bySlot = {}
    if type(rs.bySlot) == "table" then
        local n = 0
        for slot, list in pairs(rs.bySlot) do
            if type(slot) == "string" and n < 12 then
                local cl = CleanResponses(list, 7)
                if cl and #cl > 0 then out.bySlot[slot:sub(1, 24)] = cl; n = n + 1 end
            end
        end
    end
    out.difficulties = {}
    if type(rs.difficulties) == "table" then
        for diff in pairs({ [14] = 1, [15] = 1, [16] = 1 }) do
            out.difficulties[diff] = rs.difficulties[diff] == true
        end
    else
        for k, v in pairs(d.difficulties) do out.difficulties[k] = v end
    end
    out.bank = {}
    if type(rs.bank) == "table" then
        local n = 0
        for key, role in pairs(rs.bank) do
            if type(key) == "string" and (role == "bank" or role == "de") and n < 20 then
                out.bank[key:sub(1, 64)] = role
                n = n + 1
            end
        end
    end
    return out
end

-- Deterministic serialisation (sorted keys) -> 32-bit hash as hex.
local function Canon(v, out)
    local t = type(v)
    if t == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end
            return a < b
        end)
        out[#out + 1] = "{"
        for _, k in ipairs(keys) do
            out[#out + 1] = tostring(k)
            out[#out + 1] = "="
            Canon(v[k], out)
            out[#out + 1] = ";"
        end
        out[#out + 1] = "}"
    else
        out[#out + 1] = t .. ":" .. tostring(v)
    end
end

function Ruleset.Hash(rs)
    local buf = {}
    Canon(rs, buf)
    local s = table.concat(buf)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return string.format("%08x", h)
end

-- ---- live state -----------------------------------------------
Ruleset.current = nil   -- { rs, hash, leader, active }

function Ruleset.IsActive() return Ruleset.current ~= nil and Ruleset.current.active == true end
function Ruleset.Get() return Ruleset.current and Ruleset.current.rs or nil end
function Ruleset.Leader() return Ruleset.current and Ruleset.current.leader or nil end

-- Build from this account's saved ruleset (what it broadcasts when it leads and says yes).
function Ruleset.Build()
    return Ruleset.Sanitize(LC.DB.G().ruleset)
end

function Ruleset.Broadcast(to)
    local cur = Ruleset.current
    if not cur or cur.leader ~= LC.Roster.MyKey() then return end
    LC.Comms.Send("RULESET", { a = cur.active, h = cur.hash, rs = cur.active and cur.rs or nil }, "RAID", to)
end

function Ruleset.Activate(silent)
    local rs = Ruleset.Build()
    Ruleset.current = { rs = rs, hash = Ruleset.Hash(rs), leader = LC.Roster.MyKey(), active = true }
    Ruleset.Broadcast()
    LC.Fire("NSRT_LC_RULESET_CHANGED", true)
    if not silent and rs.announce and rs.chatAnnounce then Ruleset.AnnounceToRaid() end
end

-- Re-send the ruleset after the leader edits it. Does nothing unless you are leading with the council on.
function Ruleset.Reapply()
    local cur = Ruleset.current
    if cur and cur.active and cur.leader == LC.Roster.MyKey() then Ruleset.Activate(true) end
end

function Ruleset.Deactivate()
    Ruleset.current = { rs = nil, hash = "", leader = LC.Roster.MyKey(), active = false }
    Ruleset.Broadcast()
    LC.Fire("NSRT_LC_RULESET_CHANGED", false)
end

function Ruleset.AnnounceToRaid()
    LC.Comms.Chat(LC.Loc("Loot council is in use for this raid. Turn it on in /ns under Loot Council to take part."))
end

-- A RULESET message from `sender`. Only the current group leader may set it.
function Ruleset.Receive(msg, sender)
    if type(msg) ~= "table" then return end
    if not LC.Roster.IsLeader(sender) then return end
    if sender == LC.Roster.MyKey() then return end
    if msg.a then
        local rs = Ruleset.Sanitize(msg.rs)
        local hash = Ruleset.Hash(rs)
        if msg.h and msg.h ~= hash then return end        -- corrupted or hand-edited in transit
        Ruleset.current = { rs = rs, hash = hash, leader = sender, active = true }
    else
        Ruleset.current = { rs = nil, hash = "", leader = sender, active = false }
    end
    LC.Fire("NSRT_LC_RULESET_CHANGED", msg.a and true or false)
    LC.State.Refresh()
end

function Ruleset.Clear()
    if Ruleset.current then
        Ruleset.current = nil
        LC.Fire("NSRT_LC_RULESET_CHANGED", false)
    end
end

-- ---- roles ----------------------------------------------------
-- The loot master is always the raid leader.
function Ruleset.MLKey()
    local cur = Ruleset.current
    if not (cur and cur.active) then return nil end
    return cur.leader
end

function Ruleset.IsML(key) return key ~= nil and key == Ruleset.MLKey() end

function Ruleset.BackupKey()
    local cur = Ruleset.current
    if not (cur and cur.active) then return nil end
    local name = cur.rs.backupName
    if name and name ~= "" then
        for key in pairs(LC.Roster.All()) do
            if key ~= Ruleset.MLKey() and Ruleset.NameMatches(name, key) then return key end
        end
    end
    local best, bestIndex
    for key, m in pairs(LC.Roster.All()) do
        if m.rank == 1 and key ~= Ruleset.MLKey() and (not bestIndex or m.index < bestIndex) then
            best, bestIndex = key, m.index
        end
    end
    return best
end

function Ruleset.IsBackup(key) return key ~= nil and key == Ruleset.BackupKey() end

-- Does the council's name list name this character? Entries may be character names or NSRT nicknames.
local function NameMatches(entry, key)
    if LC.Roster.Key(entry) == key then return true end
    if NSAPI and NSAPI.GetCharacters then
        local ok, chars = pcall(NSAPI.GetCharacters, NSAPI, entry)
        if ok and type(chars) == "table" then
            for full in pairs(chars) do
                if LC.Roster.Key(full) == key then return true end
            end
        end
    end
    return false
end
Ruleset.NameMatches = NameMatches

function Ruleset.IsCouncil(key)
    local cur = Ruleset.current
    if not (cur and cur.active and key) then return false end
    local rs = cur.rs
    if key == cur.leader then return true end
    if rs.council.assistants and LC.Roster.IsAssistant(key) then return true end
    for _, n in ipairs(rs.council.names) do
        if NameMatches(n, key) then return true end
    end
    if rs.council.minRank >= 0 then
        local rank = LC.Roster.GuildRank(key)
        if rank and rank <= rs.council.minRank then return true end
    end
    return false
end

function Ruleset.IAmCouncil() return Ruleset.IsCouncil(LC.Roster.MyKey()) end
function Ruleset.IAmML() return Ruleset.IsML(LC.Roster.MyKey()) end

-- Response buttons for an item slot (per-slot sets override the global set, V-4).
function Ruleset.ResponsesFor(equipLoc)
    local rs = Ruleset.Get()
    if not rs then return Ruleset.defaults.responses end
    return (equipLoc and rs.bySlot[equipLoc]) or rs.responses
end

function Ruleset.ResponseById(id, equipLoc)
    for _, r in ipairs(Ruleset.ResponsesFor(equipLoc)) do if r.id == id then return r end end
    local rs = Ruleset.Get()
    for _, r in ipairs(rs and rs.responses or Ruleset.defaults.responses) do if r.id == id then return r end end
end

function Ruleset.Shutdown() Ruleset.current = nil end
LC.RegisterShutdown("Ruleset", Ruleset.Shutdown)
