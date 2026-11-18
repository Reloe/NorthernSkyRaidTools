-- ============================================================
--  Core/Priority.lua - priority lists and the resolver (P-1 to P-4)
--
--  Owns: the pure resolver and the data accessors. A list is an ordered list of character
--  keys, scoped by difficulty and run type. The resolver walks the list and skips anyone
--  who is absent from the kill roster, already holds or was awarded the item, or cannot use
--  it. It returns the first valid name plus why the others were skipped.
-- ============================================================
local ADDON, LC = ...
local Priority = {}
LC.Priority = Priority

-- ctx = { present(key)->bool, has(key)->bool, eligible(key)->bool|nil, main(key)->key }
-- Returns winner (or nil), skipped = { { key=, reason= }, ... }
function Priority.Resolve(list, ctx)
    local skipped = {}
    for _, key in ipairs(list or {}) do
        local reason
        if ctx.present and not ctx.present(key) then
            reason = "absent"
        elseif ctx.has and ctx.has(key) then
            reason = "has item"
        elseif ctx.eligible and ctx.eligible(key) == false then
            reason = "cannot use"
        end
        if reason then
            skipped[#skipped + 1] = { key = key, reason = reason }
        else
            return key, skipped
        end
    end
    return nil, skipped
end

-- Pick the entry of an item's priority data that matches the run scope.
function Priority.PickScope(entries, difficulty, runType)
    local fallback
    for _, e in ipairs(entries or {}) do
        local s = e.scope or {}
        local okDiff = (s.difficulty == nil) or (s.difficulty == difficulty)
        local okRun = (s.runType == nil) or (s.runType == runType)
        if okDiff and okRun then
            if s.difficulty and s.runType then return e end
            fallback = fallback or e
        end
    end
    return fallback
end

function Priority.Data()
    return LC.DB.G().priority
end

function Priority.ListFor(itemID, difficulty, runType)
    local entry = Priority.PickScope(Priority.Data()[itemID], difficulty, runType)
    return entry and entry.list or nil
end

function Priority.SetList(itemID, scope, list)
    local data = Priority.Data()
    local entries = data[itemID] or {}
    data[itemID] = entries
    for _, e in ipairs(entries) do
        local s = e.scope or {}
        if s.difficulty == scope.difficulty and s.runType == scope.runType then
            e.list = list
            return
        end
    end
    entries[#entries + 1] = { scope = scope, list = list }
end

-- Resolver wired to the live session: absent = not in kill roster, has = already awarded that item
-- this session or holds it (history rolled up to main).
function Priority.ResolveForDrop(session, drop)
    local list = Priority.ListFor(drop.itemID, drop.difficulty, session.runType)
    if not list then return nil end
    local awardedTo = {}
    for id, a in pairs(session.awards) do
        local d = session.drops[id]
        if d and d.itemID == drop.itemID and a.winner then awardedTo[a.winner] = true end
    end
    local info = LC.Items.Info(drop.item)
    return Priority.Resolve(list, {
        present = function(key) return session.killRoster[key] == true end,
        has = function(key) return awardedTo[key] == true end,
        eligible = function(key)
            local m = LC.Roster.Get(key)
            if not (m and info) then return nil end
            return LC.Items.UsableBy(m.class, drop.item or drop.itemID)
        end,
    })
end
