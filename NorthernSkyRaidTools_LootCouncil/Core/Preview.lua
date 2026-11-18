-- ============================================================
--  Core/Preview.lua - hidden `/ns loot preview` for looking at every window with fake data
--
--  Owns: a throw-away session, ruleset, trade queue and history filled with placeholder players,
--  so the UI can be styled and debugged alone. While LC.Preview is true nothing is sent, nothing is
--  saved (no session, no history, no trades) and the group state machine is paused. Clicking around
--  works locally: respond, vote, award, undo. `preview stop` puts everything back.
--
--  /ns loot preview            raider window, session bar, trade prompt and the council window
--  /ns loot preview <what>     setup | council | loot | trades | history | responses | lead
--  /ns loot preview stop       leave preview mode
-- ============================================================
local ADDON, LC = ...
local Preview = {}
LC.Preview_ = Preview          -- LC.Preview itself is the on/off flag read by the rest of the module

local FRAMES = { "NSLCLootFrame", "NSLCSessionBar", "NSLCTradePrompt", "NSLCVotingFrame", "NSLCTradesFrame",
    "NSLCHistoryFrame", "NSLCResponseEditor", "NSLCSetupFrame", "NSLCLootChip", "NSLCNoteFlyout" }

-- Real item ids so tooltips resolve.
local DROPS = { 271092, 268239, 19019, 19364, 17182 }   -- 271092 is an item Arkin can roll on; 268239 is for testing the auto-pass
local GEAR = { 19350, 18816, 19379, 18808 }
local PLAYERS = { "Aelarya", "Brightmantle", "Cindrel", "Dunmar", "Evelynn", "Faolan" }
local NOTES = { Cindrel = "Tank swap, need for progress", Dunmar = "" }

local fakeGear = {}
local function Gear(i)
    local a, b = GEAR[(i % #GEAR) + 1], GEAR[((i + 1) % #GEAR) + 1]
    return { { item = "item:" .. a, ilvl = 250 + i * 3 }, { item = "item:" .. b, ilvl = 240 + i * 2 } }
end

-- Made-up tier slots: some pieces in every difficulty, some empty. Item ids are real armour so icons resolve.
local TIER_ITEMS = { HEAD = 19019, SHOULDER = 19364, CHEST = 18816, HANDS = 19379, LEGS = 18808 }
local CONTEXTS = { 5, 6, 3, 4 }            -- Heroic, Mythic, Normal, LFR bonus contexts
local SPECS = { 62, 71, 257, 259, 102, 253 }
function Preview.TierGear(i)
    local out = {}
    for n, key in ipairs({ "HEAD", "SHOULDER", "CHEST", "HANDS", "LEGS" }) do
        if (i + n) % 4 ~= 0 then
            out[key] = string.format("item:%d::::::::80:::%d:1:%d", TIER_ITEMS[key], CONTEXTS[(i + n) % #CONTEXTS + 1], 1000 + n)
        end
    end
    return out
end

-- Used by the raider window for "what you have equipped" while previewing.
function Preview.GearFor() return Gear(1) end

local function Key(n) return n .. "-Preview" end

-- Placeholder queue for the Session Setup window (also used by /ns loot test): three items from a
-- fresh kill and one saved from an earlier kill, so the "accumulated" look is visible.
function Preview.FakeQueue(me)
    local now = GetServerTime()
    local items = {}
    for i, id in ipairs(DROPS) do
        items[i] = { id = LC.Items.DropID(9999, now, id, 1), item = "item:" .. id, itemID = id, difficulty = 15, index = 1,
            holder = (i == 1) and me or Key(PLAYERS[i]), enc = 9999, kill = now, boss = "Preview Boss",
            expires = now + LC.Queue.TTL, excluded = false }
    end
    local old = now - 3600
    items[#items + 1] = { id = LC.Items.DropID(9998, old, GEAR[1], 1), item = "item:" .. GEAR[1], itemID = GEAR[1], difficulty = 15,
        index = 1, holder = Key(PLAYERS[2]), enc = 9998, kill = old, boss = "Earlier Boss", expires = old + LC.Queue.TTL, excluded = false }
    return items, { me, Key(PLAYERS[1]), Key(PLAYERS[2]) }
end

-- History across three raid days, two difficulties and three bosses, with every status the window can show:
-- traded, pending, kept by the winner, traded to the wrong player, never traded, undone, and a traded copy with
-- different bonus IDs than the drop.
local CLASSES = { "MAGE", "WARRIOR", "PRIEST", "ROGUE", "DRUID", "HUNTER" }
local BOSSES = { { 3176, "Imperator Averzian" }, { 3177, "Vorasius" }, { 3179, "Fallen-King Salhadaar" } }
local CONTEXT = { [16] = 6, [15] = 5, [14] = 3, [17] = 4 }

function Preview.FillHistory(me, reasons, now)
    local list, n = {}, 0
    local function add(ago, diff, boss, itemIdx, who, mode, bonus)
        n = n + 1
        local itemID = DROPS[itemIdx]
        local kill = now - ago
        local at = kill + 240 + n * 20
        local winner, holder = Key(PLAYERS[who]), me
        local str = string.format("item:%d:0:0:0:0:0:0:0:0:0:0:%d:2:%d:%d", itemID, CONTEXT[diff], bonus or 10355, 10356)
        local e = { id = "pv" .. n, itemID = itemID, item = str, difficulty = diff, encounterID = BOSSES[boss][1], boss = BOSSES[boss][2],
            kill = kill, time = at, winner = winner, reason = reasons[(n % 5) + 1], source = "council", by = me, holder = holder,
            class = CLASSES[who], upd = at, votes = { ["for"] = 2 + n % 2, total = 4 },
            audit = { { who = me, when = at, action = "award", to = winner } } }
        if mode == "traded" or mode == "badcopy" then
            e.trade = { to = winner, by = me, at = at + 90, item = mode == "badcopy" and str:gsub(":10355:", ":10399:") or str }
            e.upd = at + 90
        elseif mode == "mismatch" then
            e.trade = { to = Key(PLAYERS[(who % #PLAYERS) + 1]), by = me, at = at + 90, item = str }
            e.upd = at + 90
        elseif mode == "self" then
            e.winner, e.holder, e.class = me, me, "SHAMAN"
        elseif mode == "void" then
            e.void = { who = me, when = at + 60, why = "Awarded to the wrong character" }
            e.audit[2] = { who = me, when = at + 60, action = "undo", from = winner, why = "Awarded to the wrong character" }
            e.upd = at + 60
        end
        list[#list + 1] = e
    end
    local day = 86400
    -- today
    add(2400, 16, 1, 1, 1, "traded");  add(2400, 16, 1, 2, 2, "pending"); add(2400, 16, 1, 3, 3, "self")
    add(1500, 16, 2, 4, 4, "traded");  add(1500, 16, 2, 5, 5, "void");    add(1500, 16, 2, 1, 6, "badcopy")
    add(900, 15, 1, 2, 1, "traded");   add(900, 15, 1, 3, 2, "mismatch")
    -- yesterday
    add(day + 7200, 15, 1, 1, 3, "traded"); add(day + 7200, 15, 2, 2, 4, "expired"); add(day + 5400, 15, 3, 5, 5, "traded")
    -- three days ago
    add(3 * day + 3600, 14, 1, 4, 6, "traded"); add(3 * day + 3600, 14, 1, 5, 1, "traded")
    LC.History.previewList = list
end

local function Hide()
    for _, name in ipairs(FRAMES) do local f = _G[name]; if f then f:Hide() end end
end

function Preview.Stop()
    if not LC.Preview then return end
    LC.Preview = false
    Hide()
    LC.Trade.Clear()
    LC.Queue.ClearOverride()
    LC.History.previewList = nil
    LC.Session.state, LC.Session.log = nil, nil
    LC.Ruleset.current = nil
    LC.Session.Restore()
    LC.Fire("NSRT_LC_SESSION_CLOSED")
    LC.Fire("NSRT_LC_RULESET_CHANGED", false)
    LC.State.Schedule(0)
    LC.Print(LC.Loc("Preview stopped."))
end

local function Start()
    if LC.Preview then return end
    LC.Preview = true
    local me = LC.Roster.MyKey()
    local rs = LC.Ruleset.Build()
    rs.timeout = 120                              -- the preview loops its response timer
    rs.responses[3].needsNote = true            -- show a "needs note" button
    LC.Ruleset.current = { rs = rs, hash = "preview", leader = me, active = true }
    LC.Session.state, LC.Session.log = LC.Session.NewState(), {}

    local now = GetServerTime()
    local drops = {}
    for i, id in ipairs(DROPS) do
        drops[i] = { id = LC.Items.DropID(9999, now, id, 1), item = "item:" .. id, itemID = id, difficulty = 15, index = 1,
            holder = (i == 1) and me or Key(PLAYERS[i]) }
    end
    LC.Session.Emit({ t = "open", guid = "preview", encounterID = 9999, difficulty = 15, killTime = now, ml = me,
        drops = drops, killRoster = { me }, rulesetHash = "preview", runType = "main" })

    local st, ids = LC.Session.state, { "bis", "major", "minor", "offspec", "xmog", "pass" }
    for di, d in ipairs(drops) do
        for pi, name in ipairs(PLAYERS) do
            local g = Gear(pi)
            LC.Roster.NoteClass(Key(name), CLASSES[(pi - 1) % #CLASSES + 1], true)
            LC.Session.ApplyFree(st, { t = "response", id = d.id, from = Key(name), response = ids[((pi + di) % 5) + 1],
                note = NOTES[name], gear = g, ilvl = 270 + di * 3, tier = pi % 5, sim = (pi * 1.7 + di) % 9, seq = pi,
                tg = Preview.TierGear(pi), spec = SPECS[(pi - 1) % #SPECS + 1] })
        end
        LC.Session.ApplyFree(st, { t = "vote", id = d.id, voter = me, candidate = Key(PLAYERS[1]), seq = 1 })
        LC.Session.ApplyFree(st, { t = "vote", id = d.id, voter = Key("Council2"), candidate = Key(PLAYERS[1]), seq = 1 })
        LC.Session.ApplyFree(st, { t = "vote", id = d.id, voter = Key("Council3"), candidate = Key(PLAYERS[2]), seq = 1 })
    end
    -- One drop already awarded so the Award / Reassign states and history have something to show.
    LC.Session.Emit({ t = "award", id = drops[3].id, winner = Key(PLAYERS[3]), reason = "major", by = me,
        response = "major", council = { [me] = Key(PLAYERS[3]) } })

    -- Trades and history.
    LC.Trade.Add(DROPS[1], 15, Key(PLAYERS[1]))
    LC.Trade.Add(DROPS[2], 15, Key(PLAYERS[2]))
    LC.Trade.Add(DROPS[3], 16, Key(PLAYERS[4]))
    LC.Trade.queue[2].state = "placed"
    LC.Trade.queue[3].state = "failed"
    Preview.FillHistory(me, ids, now)
    LC.Fire("NSRT_LC_TRADES_CHANGED")
end

local function Frames()
    if not LC.EnsureKit() then LC.Print(LC.Loc("The UI kit could not be loaded.")) return false end
    for _, name in ipairs({ "LootFrame", "SessionBar", "TradePrompt", "SetupFrame" }) do
        local f = LC.Frames[name]
        if f and f.Build then f.Build() end
    end
    return LC.EnsureUI()
end

function Preview.Run(arg)
    arg = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if arg == "stop" then Preview.Stop() return end
    if LC.Session.IsOpen() and not LC.Preview then
        LC.Print(LC.Loc("A real session is open. Finish it before using the preview."))
        return
    end
    if LC.Sim.loopback then
        LC.Print(LC.Loc("A test session is running. Use /ns loot stop first."))
        return
    end
    Start()
    local me = LC.Roster.MyKey()
    LC.Queue.SetOverride(Preview.FakeQueue(me))
    if not Frames() then return end
    LC.Fire("NSRT_LC_SESSION_OPENED")
    LC.Fire("NSRT_LC_SESSION_UPDATED", {})
    if arg == "setup" then LC.Frames.SetupFrame.Open()
    elseif arg == "council" then LC.UI.VotingFrame.Open()
    elseif arg == "loot" then LC.Frames.LootFrame.Refresh()
    elseif arg == "trades" then LC.UI.TradesFrame.Open()
    elseif arg == "history" then LC.UI.HistoryFrame.Open()
    elseif arg == "responses" then LC.UI.ResponseEditor.Open()
    elseif arg == "lead" then
        LC.Frames.LeadPrompt.Show(function() LC.Print("Lead prompt: Yes (preview, nothing changed)") end,
            function() LC.Print("Lead prompt: No (preview, nothing changed)") end)
    else
        LC.Frames.LootFrame.Reopen()
        LC.Frames.SessionBar.Refresh()
        LC.Frames.TradePrompt.Refresh()
        LC.Frames.SetupFrame.Open()
        LC.UI.VotingFrame.Open()
        LC.Print(LC.Loc("Preview on. Also try: /ns loot preview setup | council | loot | trades | history | responses | lead | stop"))
    end
end

LC.RegisterShutdown("Preview", function() if LC.Preview then Preview.Stop() end end)
