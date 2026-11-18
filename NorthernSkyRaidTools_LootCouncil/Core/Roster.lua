-- ============================================================
--  Core/Roster.lua - group cache, character keys, council resolution
--
--  Owns: the roster cache (rebuilt once per roster burst), "Name-Realm" keys (always with a
--  realm, fixing bird issue 7), alt -> main mapping, kill-roster snapshots and guild rank
--  lookup. Never stores "Unknown" names (12.0.5): retries on the next roster update.
-- ============================================================
local ADDON, LC = ...
local Roster = {}
LC.Roster = Roster

local members = {}          -- key -> { key, name, unit, class, rank, online, index, subgroup, zone }
local byName = {}           -- short name -> key (for chat/loot names without a realm)
local classOf = {}          -- key -> class file, remembered after the character was last seen
local leaderKey
local myKey

local function OwnRealm()
    return (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or ""):gsub("%s", "")
end

-- "Name" or "Name-Realm" -> "Name-Realm" with a normalised realm; nil for nil/secret input.
function Roster.Key(name)
    if type(name) ~= "string" or name == "" then return nil end
    if issecretvalue and issecretvalue(name) then return nil end
    if name == UNKNOWNOBJECT or name == "Unknown" then return nil end
    if name:find("-", 1, true) then
        local n, r = name:match("^(.-)%-(.+)$")
        return n .. "-" .. r:gsub("%s", "")
    end
    return name .. "-" .. OwnRealm()
end

function Roster.MyKey()
    myKey = myKey or Roster.Key(UnitName("player"))
    return myKey
end

function Roster.Realm(key) return key and key:match("%-(.+)$") end
function Roster.ShortName(key) return key and key:match("^(.-)%-") or key end

function Roster.IsCrossRealm(key)
    return Roster.Realm(key) ~= OwnRealm()
end

-- Rebuild the cache. Coalesced by the caller (State) to once per frame.
function Roster.Refresh()
    wipe(members)
    wipe(byName)
    leaderKey = nil
    myKey = nil
    if not IsInGroup() then return end
    local n = GetNumGroupMembers()
    local inRaid = IsInRaid()
    for i = 1, n do
        local unit = inRaid and ("raid" .. i) or (i == n and "player" or ("party" .. i))
        local name, rank, subgroup, _, _, classFile, zone, online
        if inRaid then
            name, rank, subgroup, _, _, classFile, zone, online = GetRaidRosterInfo(i)
        else
            name = UnitName(unit)
            classFile = select(2, UnitClass(unit))
            online = UnitIsConnected(unit)
            rank = UnitIsGroupLeader(unit) and 2 or 0
            subgroup = 1
        end
        local fullName = name
        if inRaid and name and not name:find("-", 1, true) then
            local _, realm = UnitFullName(unit)
            if realm and realm ~= "" then fullName = name .. "-" .. realm end
        end
        local key = Roster.Key(fullName)
        if key then
            if classFile then Roster.NoteClass(key, classFile) end
            members[key] = { key = key, name = name, unit = unit, class = classFile, rank = rank or 0,
                online = online and true or false, index = i, subgroup = subgroup, zone = zone }
            byName[Roster.ShortName(key)] = byName[Roster.ShortName(key)] or key
            if (rank or 0) == 2 then leaderKey = key end
        end
    end
end

function Roster.Get(key) return members[key] end
function Roster.All() return members end
function Roster.InGroup(key) return members[key] ~= nil end
function Roster.Leader() return leaderKey end
function Roster.KeyFromName(name)
    local direct = Roster.Key(name)
    if direct and members[direct] then return direct end
    return byName[name] or direct
end
function Roster.Unit(key) local m = members[key]; return m and m.unit end
function Roster.IsLeader(key) return key ~= nil and key == leaderKey end
function Roster.IsAssistant(key) local m = members[key]; return m ~= nil and m.rank == 1 end
function Roster.IsOnline(key) local m = members[key]; return m ~= nil and m.online end
function Roster.Count()
    local n = 0
    for _ in pairs(members) do n = n + 1 end
    return n
end

-- Guild rank of a character, from the guild roster (same source and index as NSRT's auto-promote).
-- The roster is read at most once every 30 s and only when something asks.
local rankCache, rankAt = {}, 0
function Roster.GuildRank(key)
    if not key or not IsInGuild() then return nil end
    local now = GetTime()
    if now - rankAt > 30 then
        rankAt = now
        wipe(rankCache)
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndex = GetGuildRosterInfo(i)
            if name and rankIndex then rankCache[Roster.Key(name) or name] = rankIndex end
        end
    end
    return rankCache[key]
end

-- Is this group mostly the player's guild? (auto-pass only runs in guild groups)
function Roster.IsGuildGroup()
    if not IsInGuild() then return false end
    local total, mine = 0, 0
    for _, m in pairs(members) do
        total = total + 1
        local ok, inGuild = pcall(UnitIsInMyGuild, m.unit)
        if ok and inGuild then mine = mine + 1 end
    end
    return total > 0 and mine / total >= 0.5
end

-- Plain character name (no realm, no colour, never a nickname).
function Roster.Plain(key)
    if not key then return "?" end
    return Roster.ShortName(key) or key
end

-- Remember a character's class so it can be coloured when they are not in the group (history, trade queue).
-- Saved between sessions unless `temporary` (the preview's made-up players).
function Roster.NoteClass(key, class, temporary)
    if not (key and class) or classOf[key] == class then return end
    classOf[key] = class
    if not temporary and LC.DB and LC.DB.sv then
        local g = LC.DB.G()
        g.classes = g.classes or {}
        g.classes[key] = class
    end
end

function Roster.ClassOf(key)
    if not key then return nil end
    local m = members[key]
    if m and m.class then return m.class end
    if classOf[key] then return classOf[key] end
    if key == myKey or key == Roster.MyKey() then            -- solo / test sessions: the roster is empty
        local _, file = UnitClass("player")
        if file then return file end
    end
    local saved = LC.DB and LC.DB.sv and LC.DB.G().classes
    return saved and saved[key] or nil
end

-- Display name used in every Loot Council window: the character name in class colour. Nicknames are
-- not shown. `class` is optional and wins when the roster does not know the character.
function Roster.Display(key, class)
    if not key then return "?" end
    local short = Roster.Plain(key)
    class = Roster.ClassOf(key) or class
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if not c then return short end
    return string.format("|cff%02x%02x%02x%s|r", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5),
        math.floor(c.b * 255 + 0.5), short)
end

-- Guild rank name ("Officer"), or the rank number when the name is not available; nil outside my guild.
function Roster.GuildRankName(key)
    local index = Roster.GuildRank(key)
    if index == nil then return nil end
    local name = GuildControlGetRankName and GuildControlGetRankName(index + 1)
    if type(name) == "string" and name ~= "" then return name end
    return tostring(index)
end

function Roster.ClassColor(key)
    local m = members[key]
    local c = m and m.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[m.class]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

-- Main of an alt (CH-1), from the characters table. Returns the key itself when unmapped.
function Roster.MainOf(key)
    local chars = LC.DB and LC.DB.sv and LC.DB.G().characters
    local entry = chars and chars[key]
    return (entry and entry.main) or key
end

-- Who was present for a kill: everyone in the group and online. Trade eligibility is
-- "present and eligible for loot" (PRD 8.1); this is the best a client can know.
function Roster.SnapshotKillRoster()
    local out = {}
    for key, m in pairs(members) do
        if m.online then out[#out + 1] = key end
    end
    table.sort(out)
    return out
end

function Roster.Shutdown()
    wipe(members)
    wipe(byName)
    leaderKey, myKey = nil, nil
end
LC.RegisterShutdown("Roster", Roster.Shutdown)
