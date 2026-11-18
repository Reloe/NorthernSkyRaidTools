-- ============================================================
--  Core/Strings.lua - paste-string grammar (bird compatible)
--
--  Owns: trade-string parsing and loot-string building. Pure. Grammar (PRD, bird doc):
--    trade string  (itemID["/"diff] ":" Player ";")*     diff in 14,15,16,17 (13 is read as 17)
--    loot string   (itemID["/"diff] ";")+                diff in 14,15,16,17
--  A malformed entry is reported, never silently dropped and never a crash (bird bug B).
-- ============================================================
local ADDON, LC = ...
local Strings = {}
LC.Strings = Strings

local tonumber = tonumber

local VALID = { [14] = true, [15] = true, [16] = true, [17] = true }

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Returns entries, errors. entries[i] = { itemID, difficulty (nil = any), player }
function Strings.ParseTrade(text)
    local entries, errors = {}, {}
    if type(text) ~= "string" then return entries, errors end
    for raw in text:gmatch("[^;\n]+") do
        local entry = trim(raw)
        if entry ~= "" then
            local spec, player = entry:match("^([^:]+):(.+)$")
            if not spec then
                errors[#errors + 1] = { entry = entry, reason = "missing player" }
            else
                local id, diff = spec:match("^(%d+)/(%d+)$")
                if not id then id = spec:match("^(%d+)$") end
                if not id then
                    errors[#errors + 1] = { entry = entry, reason = "bad item" }
                else
                    id = tonumber(id)
                    diff = tonumber(diff)
                    if diff == 13 then diff = 17 end            -- legacy LFR code (T-7)
                    if diff and not VALID[diff] then
                        errors[#errors + 1] = { entry = entry, reason = "unsupported difficulty" }
                    else
                        entries[#entries + 1] = { itemID = id, difficulty = diff, player = trim(player) }
                    end
                end
            end
        end
    end
    return entries, errors
end

-- list of { itemID, difficulty } -> "id/diff;id;"
function Strings.BuildLoot(list)
    local out = {}
    for i, e in ipairs(list) do
        out[i] = tostring(e.itemID) .. ((e.difficulty and VALID[e.difficulty]) and ("/" .. e.difficulty) or "") .. ";"
    end
    return table.concat(out)
end

-- Loot string back to entries (accepts the legacy /13).
function Strings.ParseLoot(text)
    local entries = {}
    if type(text) ~= "string" then return entries end
    for raw in text:gmatch("[^;\n]+") do
        local id, diff = trim(raw):match("^(%d+)/?(%d*)$")
        if id then
            diff = tonumber(diff)
            if diff == 13 then diff = 17 end
            entries[#entries + 1] = { itemID = tonumber(id), difficulty = VALID[diff] and diff or nil }
        end
    end
    return entries
end

-- Re-assemble skipped entries as a ready-to-paste trade string.
function Strings.BuildTrade(entries)
    local out = {}
    for i, e in ipairs(entries) do
        out[i] = tostring(e.itemID) .. (e.difficulty and ("/" .. e.difficulty) or "") .. ":" .. e.player .. ";"
    end
    return table.concat(out)
end
