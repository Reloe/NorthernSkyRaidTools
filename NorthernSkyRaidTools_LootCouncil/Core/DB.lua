-- ============================================================
--  Core/DB.lua - NSRTLootCouncilDB
--
--  Owns: defaults, merge by copy, strip at logout, repair by type and schema
--  migrations (best practices 2.3). Account-wide and NOT part of NSRT profiles.
--  Only the module switch lives in NSRT.LootCouncil (core reads it before this
--  addon loads).
--
--  Merge and Strip are pure and covered by tools/lc-tests.
--  Lists (any default table with a [1]) merge and strip whole, never per element.
-- ============================================================
local ADDON, LC = ...
local DB = {}
LC.DB = DB

local SV_NAME = "NSRTLootCouncilDB"
local SCHEMA = 1

local pairs, next, type, CopyTableLocal = pairs, next, type, nil

local function Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Copy(v) end
    return out
end
DB.Copy = Copy

DB.defaults = {
    schema = SCHEMA,
    global = {
        settings = {
            onLead = "ask",          -- "ask" | "always" | "never"
            autoPass = true,         -- auto-pass Blizzard rolls (your own setting, not the leader's)
            autoPassGuildOnly = true,-- ...but only in groups that are mostly your guild
            autoPassUnusable = true, -- answer Pass for items your class cannot use: armor, weapon type or main stat, class-locked (your own setting)
            showAutoPassed = true,   -- items answered Pass for you (cannot use) stay listed under "Already voted", so you can change them
            scale = 1,
            lootFramePos = nil,
            timerWarn = { 60, 30, 10 },  -- minutes
        },
        classes = {},                -- ["Name-Realm"] = class file, remembered so names keep their class colour
        characters = {},             -- ["Alt-Realm"] = { main = "Main-Realm", role = "bank"|"de" }
        priority = {},               -- [itemID] = { { scope = {difficulty, runType}, list = {...} } }
        sims = {},
        kills = {},
        history = {},                -- [seasonKey] = { entry, ... }
        historyClearedAt = 0,        -- server time of the last "Clear history"; awards made before it are not recorded again
    },
    chars = {},
}

-- Other files add defaults for their own keys at file scope: DB.RegisterDefaults("ruleset", {...}).
function DB.RegisterDefaults(key, tbl)
    DB.defaults.global[key] = tbl
end

local function IsList(t) return t[1] ~= nil end

local function Equal(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for k, v in pairs(a) do if not Equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
DB.Equal = Equal

-- Fill missing keys from src. Returns how many wrong-typed keys were repaired.
function DB.Merge(dst, src)
    local repaired = 0
    for k, v in pairs(src) do
        local cur = dst[k]
        if type(v) == "table" then
            if type(cur) ~= "table" then
                if cur ~= nil then repaired = repaired + 1 end
                dst[k] = Copy(v)
            elseif not IsList(v) then
                repaired = repaired + DB.Merge(cur, v)
            end
        elseif cur == nil then
            dst[k] = v
        elseif type(cur) ~= type(v) then
            dst[k] = v
            repaired = repaired + 1
        end
    end
    return repaired
end

-- Remove values equal to their default.
function DB.Strip(dst, src)
    for k, v in pairs(src) do
        local cur = dst[k]
        if type(v) == "table" and type(cur) == "table" then
            if IsList(v) then
                if Equal(cur, v) then dst[k] = nil end
            else
                DB.Strip(cur, v)
                if next(cur) == nil then dst[k] = nil end
            end
        elseif cur == v then
            dst[k] = nil
        end
    end
end

-- One function per schema step, run once, before anything reads the data.
DB.migrations = {
    -- [2] = function(sv) ... end,
}

function DB.Migrate(sv)
    local from = sv.schema or SCHEMA
    for v = from + 1, SCHEMA do
        local fn = DB.migrations[v]
        if fn then LC.SafeCall(fn, sv) end
    end
    sv.schema = SCHEMA
end

function DB.CharKey()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    return name .. "-" .. (realm or "")
end

function DB.Init()
    local sv = _G[SV_NAME]
    if type(sv) ~= "table" then sv = {}; _G[SV_NAME] = sv end
    DB.sv = sv
    DB.Migrate(sv)
    if type(sv.global) ~= "table" then sv.global = {} end
    if type(sv.chars) ~= "table" then sv.chars = {} end
    local repaired = DB.Merge(sv.global, DB.defaults.global)
    DB.charKey = DB.CharKey()
    if type(sv.chars[DB.charKey]) ~= "table" then sv.chars[DB.charKey] = {} end
    DB.Merge(sv.chars[DB.charKey], { lead = {}, trades = { owed = {} } })
    if repaired > 0 then
        C_Timer.After(5, function()
            LC.Print(LC.Loc("Some Loot Council settings were invalid and were reset to their defaults."))
        end)
    end
end

-- Always read through these; never cache the returned tables in file-scope locals.
function DB.G() return DB.sv.global end
function DB.Settings() return DB.sv.global.settings end
function DB.Char() return DB.sv.chars[DB.charKey] end

-- Season partition for history.
function DB.History(seasonKey)
    local h = DB.sv.global.history
    h[seasonKey] = h[seasonKey] or {}
    return h[seasonKey]
end

local logout = CreateFrame("Frame")
logout:RegisterEvent("PLAYER_LOGOUT")
logout:SetScript("OnEvent", function()
    local sv = DB.sv
    if not sv or LC.dead then return end
    -- Strip a copy and swap it in, so anything still reading during logout sees complete data.
    local copy = Copy(sv.global)
    DB.Strip(copy, DB.defaults.global)
    sv.global = copy
end)
