-- ============================================================
--  Core/Sims.lua - sim import (P-3): paste a per-player upgrade table, keep it with an age.
--  Format, one player per line: Name-Realm: itemID=percent itemID=percent
-- ============================================================
local ADDON, LC = ...
local Sims = {}
LC.Sims = Sims

function Sims.Import(text)
    local sims = LC.DB.G().sims
    local n = 0
    for line in tostring(text):gmatch("[^\n]+") do
        local player, rest = line:match("^%s*([^:]+):%s*(.+)$")
        if player then
            local key = LC.Roster.Key((player:gsub("%s+$", "")))
            sims[key] = sims[key] or {}
            for id, pct in rest:gmatch("(%d+)=([%d%.%-]+)") do
                sims[key][tonumber(id)] = { pct = tonumber(pct), at = GetServerTime() }
                n = n + 1
            end
        end
    end
    return n
end

function Sims.Get(key, itemID)
    local s = LC.DB.G().sims[key]
    return s and s[itemID] or nil
end
