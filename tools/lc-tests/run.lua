-- Pure-logic specs for the Loot Council. Run from the repo root: runlua tools/lc-tests/run.lua
-- Lua 5.4 host: shims below stand in for the WoW globals the pure files touch at load time.
unpack = unpack or table.unpack
date = date or os.date
wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end
CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end, UnregisterAllEvents = function() end } end
C_Timer = { After = function() end, NewTimer = function() return { Cancel = function() end } end }
GetServerTime = function() return 1000 end
local LC = { PROTOCOL = 1, Frames = {}, UI = {}, RegisterShutdown = function() end, Fire = function() end,
    Loc = function(k) return k end, Debug = function() end, Print = function() end,
    SafeCall = function(f, ...) return pcall(f, ...) end }
local ROOT = "NorthernSkyRaidTools_LootCouncil/"
local function load(path) local f = assert(loadfile(ROOT .. path)); f("NSLC", LC) end
LC.Roster = { Key = function(n) return (n:find("-", 1, true)) and n or (n .. "-R") end, IsAssistant = function(k) return k == "Asst-R" end,
    GuildRank = function(k) return ({ ["Officer-R"] = 1, ["Raider-R"] = 4 })[k] end, MyKey = function() return "Lead-R" end }
for _, p in ipairs({ "Core/DB.lua", "Data/ItemRules.lua", "Core/Items.lua", "Core/Strings.lua", "Core/Session.lua", "Core/Queue.lua", "Core/Ruleset.lua", "Core/History.lua", "Core/BonusRoll.lua" }) do load(p) end

local pass, fail = 0, 0
local function eq(a, b, name)
    if a == b then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name .. ": got " .. tostring(a) .. " want " .. tostring(b)) end
end

-- Strings
local e, errs = LC.Strings.ParseTrade("212401/15:Bob-Realm;212402:Al;bad;212403/13:Cy;")
eq(#e, 3, "trade entries"); eq(#errs, 1, "trade errors"); eq(e[3].difficulty, 17, "13 reads as 17")
eq(LC.Strings.BuildLoot({ { itemID = 5, difficulty = 15 }, { itemID = 6 } }), "5/15;6;", "build loot")

-- Items
eq(LC.Items.TradeKey(5, 15), "5/15", "trade key"); eq(LC.Items.TradeKey(5), "5/0", "key any")
local id, d = LC.Items.ParseKey("5/15"); eq(id, 5, "parse id"); eq(d, 15, "parse diff")
eq(LC.Items.DropID(1, 2, 3, 4), "1:2:3:4", "drop id")
eq(LC.Items.ParseDropID("1:2:3:4").index, 4, "parse drop id")

-- DB merge/strip
local dst = { a = 1, n = { x = 1 } }
LC.DB.Merge(dst, { a = 9, b = 2, n = { x = 5, y = 6 } })
eq(dst.a, 1, "merge keeps"); eq(dst.b, 2, "merge adds"); eq(dst.n.y, 6, "merge nested")
LC.DB.Strip(dst, { a = 1, b = 2, n = { x = 1, y = 6 } })
eq(dst.a, nil, "strip default"); eq(dst.n, nil, "strip empties nested")

-- Queue expiry: three hours from the kill
local q = { { id = "a", kill = 1000 - 3600 }, { id = "b", kill = 1000 - 3 * 3600 }, { id = "c", kill = 1000 - 3 * 3600 - 1 },
    { id = "d", kill = 0, expires = 2000 } }
local alive = LC.Queue.Prune(q, 1000, LC.Queue.TTL)
eq(#alive, 2, "queue keeps a and d"); eq(alive[1].id, "a", "queue keeps young"); eq(alive[2].id, "d", "queue honours expires")
eq(LC.Queue.TTL, 10800, "queue ttl is 3h")

-- Session open carries per-drop kill info and the open time; TimeLeft uses them
local st = LC.Session.NewState()
LC.Session.Apply(st, { t = "open", rev = 1, guid = "g", time = 500, drops = { { id = "9:1:5:1", itemID = 5, enc = 9, kill = 1, boss = "B" } } })
eq(st.drops["9:1:5:1"].boss, "B", "drop keeps boss"); eq(st.openTime, 500, "open time stored")
eq(LC.Session.TimeLeft(st, 60, 530), 30, "time left"); eq(LC.Session.TimeLeft(st, 60, 600) < 0, true, "time left negative when over")
eq(LC.Session.TimeLeft(LC.Session.NewState(), 60, 600), nil, "no open time, no timer")

-- Bag copy choice: bonus IDs
local drop = "item:1:0:0:0:0:0:0:0:0:0:0:5:3:100:200:300"
eq(LC.Items.BonusScore("item:1:0:0:0:0:0:0:0:0:0:0:5:3:300:100:200", drop), 2, "same bonus ids in any order")
eq(LC.Items.BonusScore("item:1:0:0:0:0:0:0:0:0:0:0:5:2:100:200", drop) > 1, true, "partial match beats nothing")
eq(LC.Items.BonusScore("item:1:0:0:0:0:0:0:0:0:0:0:5:2:100:200", drop) < 2, true, "partial is not exact")
eq(LC.Items.BonusScore("item:1:0:0:0:0:0:0:0:0:0:0:5:4:100:200:300:999", drop) < 2, true, "extra bonus id is not exact")
eq(LC.Items.BonusScore("item:1:0:0:0:0:0:0:0:0:0:0:5:2:100:200", drop) > LC.Items.BonusScore("item:1:0:0:0:0:0:0:0:0:0:0:5:1:777", drop), true, "closer copy scores higher")
eq(LC.Items.BonusScore("item:1:0:0:0:0:0:0:0:0:0:0:5:0", "item:1:0:0:0:0:0:0:0:0:0:0:5:0"), 1, "nothing to compare scores 1")

-- Armor eligibility (used for the auto-pass on unusable drops)
eq(LC.Items.ArmorEligible("MAGE", "INVTYPE_CHEST", 4, 4), false, "mage cannot use plate")
eq(LC.Items.ArmorEligible("MAGE", "INVTYPE_CHEST", 4, 1), true, "mage uses cloth")
eq(LC.Items.ArmorEligible("WARRIOR", "INVTYPE_HEAD", 4, 4), true, "warrior uses plate")
eq(LC.Items.ArmorEligible("WARRIOR", "INVTYPE_HEAD", 4, 3), false, "warrior passes mail")
eq(LC.Items.ArmorEligible("MAGE", "INVTYPE_CLOAK", 4, 1), true, "cloak is anyone's")
eq(LC.Items.ArmorEligible("MAGE", "INVTYPE_FINGER", 4, 0), true, "ring is anyone's")
eq(LC.Items.ArmorEligible("MAGE", "INVTYPE_WEAPON", 2, 7), nil, "weapons are not judged")
eq(LC.Items.ArmorEligible("EVOKER", "INVTYPE_HAND", 4, 3), true, "evoker uses mail")
eq(LC.Items.ArmorEligible("MAGE", "INVTYPE_SHIELD", 4, 6), false, "mage has no shield")
eq(LC.Items.ArmorEligible("WARRIOR", "INVTYPE_SHIELD", 4, 6), true, "warrior carries a shield")
eq(LC.Items.ArmorEligible("DEATHKNIGHT", "INVTYPE_SHIELD", 4, 6), false, "death knight has no shield")

-- Weapon eligibility: weapon type first, then main stat (subclasses: 0 1h axe, 1 2h axe, 9 warglaive, 10 staff, 15 dagger, 16 thrown)
local STR, AGI, INT = { ITEM_MOD_STRENGTH_SHORT = 1 }, { ITEM_MOD_AGILITY_SHORT = 1 }, { ITEM_MOD_INTELLECT_SHORT = 1 }
eq(LC.Items.WeaponEligible("MAGE", 15, INT), true, "mage uses an int dagger")
eq(LC.Items.WeaponEligible("MAGE", 1, INT), false, "mage cannot wield a 2h axe")
eq(LC.Items.WeaponEligible("MAGE", 1, nil), false, "weapon type needs no item data")
eq(LC.Items.WeaponEligible("WARRIOR", 9, STR), false, "warrior cannot wield a warglaive")
eq(LC.Items.WeaponEligible("DEMONHUNTER", 9, AGI), true, "demon hunter uses an agi warglaive")
eq(LC.Items.WeaponEligible("PRIEST", 15, AGI), false, "priest does not want an agi dagger")
eq(LC.Items.WeaponEligible("PALADIN", 4, INT), true, "paladin takes int")
eq(LC.Items.WeaponEligible("PALADIN", 4, STR), true, "paladin takes str")
eq(LC.Items.WeaponEligible("PALADIN", 4, AGI), false, "paladin does not take agi")
eq(LC.Items.WeaponEligible("ROGUE", 7, {}), true, "no main stat is never judged by stat")
eq(LC.Items.WeaponEligible("WARRIOR", 10, nil), nil, "stats not loaded: cannot tell")
eq(LC.Items.WeaponEligible("WARRIOR", 16, STR), nil, "unlisted weapon type is not judged")
eq(LC.Items.WeaponEligible("NOTACLASS", 15, INT), nil, "unknown class is not judged")
LC.Season = { weaponStatOverrides = { [99] = { "ITEM_MOD_INTELLECT_SHORT" } } }
eq(LC.Items.WeaponEligible("PRIEST", 15, AGI, 99), true, "season override adds a main stat")
eq(LC.Items.WeaponEligible("PRIEST", 15, AGI, 98), false, "override is per item")
LC.Season = nil

-- "Classes:" tooltip line
local byName = { Mage = "MAGE", Warlock = "WARLOCK", Hunter = "HUNTER", ["Demon Hunter"] = "DEMONHUNTER" }
eq(LC.Items.MatchClassLine("Classes: Mage, Warlock", "Classes: %s"), "Mage, Warlock", "class line list")
eq(LC.Items.MatchClassLine("Requires Level 80", "Classes: %s"), nil, "other lines are not the class line")
eq(LC.Items.MatchClassLine("|cffffffffClasses: Mage|r", "Classes: %s"), "Mage", "colour codes are ignored")
eq(LC.Items.MatchClassLine("Klassen: Magier", "Klassen: %s"), "Magier", "template comes from the client")
local set = LC.Items.ParseClassList("Demon Hunter, Mage", byName)
eq(set.DEMONHUNTER, true, "demon hunter read"); eq(set.MAGE, true, "mage read"); eq(set.HUNTER, nil, "hunter is not demon hunter")
eq(LC.Items.ParseClassList("Hunter", byName).DEMONHUNTER, nil, "hunter alone is not demon hunter")
eq(LC.Items.ParseClassList("Nonsense", byName), nil, "unreadable line locks nobody out")

-- The rules combined
local lock = { MAGE = true }
eq(LC.Items.Judge("MAGE", { classID = 15, allowed = lock }), true, "class-locked token: listed class")
eq(LC.Items.Judge("WARRIOR", { classID = 15, allowed = lock }), false, "class-locked token: other class")
eq(LC.Items.Judge("MAGE", { classID = 15 }), nil, "nothing to judge")
eq(LC.Items.Judge("MAGE", { classID = 4, equipLoc = "INVTYPE_CHEST", subClassID = 4, allowed = lock }), false, "listed class still cannot wear plate")
eq(LC.Items.Judge("MAGE", { classID = 4, equipLoc = "INVTYPE_CHEST", subClassID = 1 }), true, "cloth for a mage")
eq(LC.Items.Judge("MAGE", { classID = 2, subClassID = 15, stats = AGI }), false, "mage and an agi dagger")
eq(LC.Items.Judge("MAGE", { classID = 2, subClassID = 15, stats = INT }), true, "mage and an int dagger")

-- Trinkets: asked of the game (C_Item.DoesItemContainSpec). Stubbed here; the real answers were checked in-game:
-- a Priest-usable Intellect trinket is true for class 5 and false for class 1, an all-class trinket is true for both.
local calls, loaded, requested = {}, true, {}
local answer = function(item, classID)
    local id = tonumber(item) or tonumber(tostring(item):match("item:(%d+)"))
    return id == 270169 and classID == 5 or id == 270164
end
C_Item = {
    DoesItemContainSpec = function(item, classID) calls[#calls + 1] = classID; return answer(item, classID) end,
    IsItemDataCachedByID = function() return loaded end,
    RequestLoadItemDataByID = function(id) requested[#requested + 1] = id end,
}
eq(LC.Items.TrinketUsable("PRIEST", 270169), true, "priest uses the int trinket")
eq(LC.Items.TrinketUsable("WARRIOR", 270169), false, "warrior does not")
eq(LC.Items.TrinketUsable("WARRIOR", 270164), true, "all-class trinket: warrior")
eq(LC.Items.TrinketUsable("EVOKER", 270164), true, "all-class trinket: evoker")
eq(calls[1], 5, "priest is class id 5"); eq(LC.Items.TrinketUsable("WARRIOR", "|cff1eff00|Hitem:270164::::::::80:::::|h[x]|h|r"), true, "link accepted")
eq(LC.Items.TrinketUsable("NOTACLASS", 270169), nil, "unknown class is not judged")
loaded = false
eq(LC.Items.TrinketUsable("WARRIOR", 270169), nil, "item data not loaded: cannot tell"); eq(requested[1], 270169, "...and its data is requested")
loaded = true
answer = function() return nil end
eq(LC.Items.TrinketUsable("WARRIOR", 270169), nil, "non-boolean answer is not trusted")
answer = function() error("boom") end
eq(LC.Items.TrinketUsable("WARRIOR", 270169), nil, "an erroring call is not trusted")
C_Item.DoesItemContainSpec = nil
eq(LC.Items.TrinketUsable("WARRIOR", 270169), nil, "missing call is not judged")
C_Item = nil
eq(LC.Items.Judge("WARRIOR", { classID = 4, equipLoc = "INVTYPE_TRINKET", subClassID = 0, trinketUsable = false }), false, "judge: unusable trinket")
eq(LC.Items.Judge("MAGE", { classID = 4, equipLoc = "INVTYPE_TRINKET", subClassID = 0, trinketUsable = true }), true, "judge: usable trinket")
eq(LC.Items.Judge("MAGE", { classID = 4, equipLoc = "INVTYPE_TRINKET", subClassID = 0 }), nil, "judge: unknown trinket is not judged")

-- Session reducer
local S = LC.Session
local st = S.NewState()
local open = { t = "open", rev = 1, guid = "g", ml = "M", epoch = 0, drops = { { id = "d1", itemID = 1 } } }
eq(S.Apply(st, open), true, "open"); eq(select(2, S.Apply(st, open)), "dup", "open dup")
eq(select(2, S.Apply(st, { t = "award", rev = 3, id = "d1", winner = "A" })), "gap", "gap")
eq(S.Apply(st, { t = "award", rev = 2, id = "d1", winner = "A" }), true, "award")
eq(st.drops.d1.state, "awarded", "awarded"); eq(select(2, S.Apply(st, { t = "award", rev = 2, id = "d1", winner = "A" })), "dup", "award dup")
S.Apply(st, { t = "undo", rev = 3, id = "d1" }); eq(st.drops.d1.state, "open", "undo")
eq(S.ApplyFree(st, { t = "response", id = "d1", from = "A", response = "bis", seq = 2 }), true, "resp")
eq(S.ApplyFree(st, { t = "response", id = "d1", from = "A", response = "pass", seq = 1 }), false, "stale resp")
-- snapshots: gear sent at session open, kept apart from responses so a silent player is not counted as responded
eq(S.ApplyFree(st, { t = "snapshot", id = "d1", from = "B", gear = { { item = "item:1", ilvl = 250 } }, tier = 2, seq = 1 }), true, "snapshot")
eq(st.snapshots.d1.B.tier, 2, "snapshot stored"); eq(st.responses.d1.B, nil, "snapshot is not a response")
eq(S.ApplyFree(st, { t = "snapshot", id = "d1", from = "B", tier = 1, seq = 1 }), false, "stale snapshot")
eq(S.ApplyFree(st, { t = "snapshot", id = "d9", from = "B", seq = 5 }), false, "snapshot for unknown drop")
local old = S.NewState(); old.snapshots = nil; old.drops.d1 = { id = "d1" }
eq(S.ApplyFree(old, { t = "snapshot", id = "d1", from = "C", seq = 1 }), true, "snapshot on a session saved without the table")
S.ApplyFree(st, { t = "vote", id = "d1", voter = "V", candidate = "A", seq = 1 }); eq(S.VoteCount(st, "d1", "A"), 1, "votes")
eq(select(2, S.Apply(st, { t = "authority", rev = 4, ml = "N", epoch = 0 })), "epoch", "authority epoch")
eq(S.Apply(st, { t = "authority", rev = 4, ml = "N", epoch = 1 }), true, "authority")
eq(select(2, S.Apply(st, { t = "undo", rev = 5, id = "d1", epoch = 0 })), "epoch", "old epoch rejected")

-- Player lookback
do
    local H, DAY = LC.History, 86400
    local now = 100 * DAY
    local list = {
        { id = "a", winner = "P-R", time = now - 1 * DAY, itemID = 1 },
        { id = "b", winner = "P-R", time = now - 9 * DAY, itemID = 2 },
        { id = "c", winner = "P-R", time = now - 31 * DAY, itemID = 3 },                 -- older than a month
        { id = "d", winner = "Q-R", time = now - 2 * DAY, itemID = 4 },                  -- someone else
        { id = "e", winner = "P-R", time = now - 3 * DAY, itemID = 5, void = { who = "x" } },   -- undone
        { id = "f", winner = "P-R", time = now - 8 * DAY, itemID = 6, source = "bonus" },
    }
    local got = H.ForPlayer(list, "P-R", now, 30)
    eq(#got, 3, "lookback count"); eq(got[1].id, "a", "newest first"); eq(got[2].id, "b", "then 9 days ago"); eq(got[3].id, "f", "then 8 days ago")
    -- ties on time: stable by id, newest first otherwise
    got = H.ForPlayer({ { id = "x1", winner = "P-R", time = now - DAY }, { id = "x2", winner = "P-R", time = now - DAY } }, "P-R", now)
    eq(#got, 2, "same-time entries kept")
    eq(H.WeeksAgo(now - 6 * DAY, now), 0, "6 days is this week"); eq(H.WeeksAgo(now - 7 * DAY, now), 1, "7 days is 1 week")
    eq(H.WeeksAgo(now + 5, now), 0, "future clamps to 0")
    eq(H.WeekLabel(0), "This week", "label 0"); eq(H.WeekLabel(1), "1 week ago", "label 1"); eq(H.WeekLabel(3), "3 weeks ago", "label 3")
    local groups = H.GroupByWeek({ { time = now - 1 * DAY }, { time = now - 2 * DAY }, { time = now - 9 * DAY }, { time = now - 10 * DAY }, { time = now - 25 * DAY } }, now)
    eq(#groups, 3, "week groups"); eq(#groups[1].items, 2, "group 1 size"); eq(groups[2].weeks, 1, "group 2 weeks"); eq(groups[3].weeks, 3, "group 3 weeks")
    eq(H.SlotsOverlap({ [11] = true, [12] = true }, { [12] = true }), true, "ring overlap")
    eq(H.SlotsOverlap({ [13] = true }, { [11] = true }), false, "trinket vs ring")
    eq(H.SlotsOverlap(nil, { [1] = true }), false, "unknown slot")
end

-- Tier tokens are judged by the armor type they stand for (Season.tokenArmor)
do
    local I = LC.Items
    local saved = LC.Season
    LC.Season = { tokenArmor = { [1] = 1, [2] = 2 } }
    eq(I.TokenArmorType(1), 1, "token armor type from season data"); eq(I.TokenArmorType(99), nil, "unlisted item has none")
    eq(I.Judge("PRIEST", { classID = 4, subClassID = 2, equipLoc = "" }), false, "priest cannot use a leather token")
    eq(I.Judge("ROGUE", { classID = 4, subClassID = 2, equipLoc = "" }), true, "rogue can use a leather token")
    LC.Season = saved
end

-- Bonus roll entries
do
    local B, H = LC.BonusRoll, LC.History
    local dec = { itemID = 212401, itemString = "item:212401::::::::::::1:3524", context = nil }
    local fresh = { encounterID = 3009, difficulty = 15, killTime = 900, name = "Boss" }
    local rec = B.Build("Raider-R", dec, fresh, 1000, "MAGE")
    eq(rec.source, "bonus", "bonus source"); eq(rec.winner, "Raider-R", "bonus winner"); eq(rec.difficulty, 15, "difficulty from the kill")
    eq(rec.boss, "Boss", "boss from the kill"); eq(rec.holder, "Raider-R", "bonus holder is the roller")
    eq(H.Sanitize(rec) ~= nil, true, "bonus entry survives sanitising"); eq(H.Sanitize(rec).source, "bonus", "source kept")
    eq(H.Status(rec, 1000), "self", "bonus roll is nothing to trade")
    local old = B.Build("Raider-R", dec, { encounterID = 1, difficulty = 16, killTime = 1, name = "Old" }, 1000000, nil)
    eq(old.boss, nil, "stale kill is not attached"); eq(old.kill, 1000000, "kill falls back to now")
    eq(B.Build(nil, dec, fresh, 1000), nil, "no player, no entry")
    eq(B.Build("Raider-R", dec, fresh, 1000, "MAGE", "Lead-R").lm, "Lead-R", "bonus roll records the loot master")
    eq(H.Sanitize(B.Build("Raider-R", dec, fresh, 1000, "MAGE", "Lead-R")).lm, "Lead-R", "loot master survives sanitising")
end

-- Ruleset
local R = LC.Ruleset
local clean = R.Sanitize({ timeout = 9999, junk = 1, council = { minRank = 2, names = { "Bob" } },
    responses = { { id = "a", text = "A", needsNote = true }, { id = "b", text = "B" } } })
eq(clean.junk, nil, "sanitize drops unknown"); eq(clean.timeout, 300, "timeout clamped")
eq(clean.responses[1].needsNote, true, "needsNote kept"); eq(clean.responses[2].needsNote, nil, "needsNote default off")
eq(R.Hash(clean), R.Hash(R.Sanitize(clean)), "hash stable"); eq(#R.Hash(clean), 8, "hash length")
eq(#R.Sanitize({ responses = {} }).responses, 6, "empty responses fall back")
R.current = { rs = R.Sanitize({ council = { assistants = true, minRank = 1, names = { "Extra" } } }), leader = "Lead-R", active = true }
eq(R.IsCouncil("Lead-R"), true, "leader on council"); eq(R.IsCouncil("Asst-R"), true, "assistant")
eq(R.IsCouncil("Officer-R"), true, "rank at or above"); eq(R.IsCouncil("Raider-R"), false, "rank below")
eq(R.IsCouncil("Extra-R"), true, "manual name"); eq(R.IsCouncil("Nobody-R"), false, "stranger")
eq(R.MLKey(), "Lead-R", "ml is leader")


-- History: entries follow the session (award, trade, reassign, undo) and group into day / difficulty / boss
LC.Preview = true                       -- History keeps its list in memory while previewing
local H = LC.History
local hs = S.NewState()
S.state = hs
local dropA, dropB, dropC = "9:100000:5:1", "9:100000:6:1", "8:90000:7:1"
local function bonus(ctx) return "item:5:0:0:0:0:0:0:0:0:0:0:" .. ctx .. ":1:100" end
S.Apply(hs, { t = "open", rev = 1, guid = "g", time = 500, encounterID = 9, killTime = 100000, ml = "Lead-R", drops = {
    { id = dropA, item = bonus(5), itemID = 5, difficulty = 15, enc = 9, kill = 100000, boss = "Boss", holder = "Lead-R" },
    { id = dropB, item = bonus(5), itemID = 6, difficulty = 15, enc = 9, kill = 100000, boss = "Boss", holder = "Lead-R" },
    { id = dropC, item = bonus(6), itemID = 7, difficulty = 16, enc = 8, kill = 90000, boss = "Other", holder = "Lead-R" } } })
S.Apply(hs, { t = "award", rev = 2, id = dropA, winner = "Bob-R", reason = "bis", by = "Lead-R", time = 100100, council = { ["Lead-R"] = "Bob-R", ["Asst-R"] = "Cy-R" } })
S.Apply(hs, { t = "award", rev = 3, id = dropB, winner = "Lead-R", reason = "major", by = "Lead-R", time = 100110 })
S.Apply(hs, { t = "award", rev = 4, id = dropC, winner = "Al-R", reason = "minor", by = "Lead-R", time = 90100 })
eq(H.Record(), true, "history records new awards"); eq(#H.Query(), 3, "three entries")
eq(H.Record(), false, "recording again changes nothing")
local ea = H.Get(dropA)
eq(ea.boss, "Boss", "entry keeps boss"); eq(ea.holder, "Lead-R", "entry keeps who held it"); eq(ea.votes["for"], 1, "votes for winner"); eq(ea.votes.total, 2, "votes total")
eq(ea.audit[1].action, "award", "audit has the award")
eq(H.Status(ea, 100200), "pending", "not traded yet"); eq(H.Status(ea, 100000 + 4 * 3600 + 1), "expired", "window closed")
eq(H.Status(H.Get(dropB), 100200), "self", "winner looted it themselves")
-- the trade that delivered it
eq(S.RecordTrade(hs, dropA, { to = "Bob-R", by = "Lead-R", at = 100300, item = bonus(5) }), true, "trade recorded")
H.Record(); ea = H.Get(dropA)
eq(ea.trade.to, "Bob-R", "entry has the trade"); eq(ea.upd, 100300, "update time follows the trade"); eq(H.Status(ea, 100400), "traded", "delivered to the winner")
-- a later holder report must not rewrite who held it
S.Apply(hs, { t = "holder", rev = 5, id = dropA, holder = "Bob-R" }); H.Record()
eq(H.Get(dropA).holder, "Lead-R", "holder frozen at the award")
-- reassigned after the trade: delivered to someone other than the winner
S.Apply(hs, { t = "edit", rev = 6, id = dropA, winner = "Cy-R", by = "Lead-R", time = 100500, why = "oops" }); H.Record(); ea = H.Get(dropA)
eq(ea.winner, "Cy-R", "entry follows the reassignment"); eq(H.Status(ea, 100600), "mismatch", "traded to someone else is flagged"); eq(#ea.audit, 2, "audit has both steps")
-- undone: stays in the history, marked void
S.Apply(hs, { t = "undo", rev = 7, id = dropC, by = "Lead-R", time = 90200, why = "wrong item" }); H.Record()
eq(#H.Query(), 3, "undo keeps the entry"); eq(H.Status(H.Get(dropC), 90300), "void", "undone is void"); eq(H.Get(dropC).void.why, "wrong item", "void keeps why")
S.Apply(hs, { t = "award", rev = 8, id = dropC, winner = "Dee-R", reason = "bis", by = "Lead-R", time = 90400 }); H.Record()
eq(H.Status(H.Get(dropC), 90500), "pending", "given again, no longer void"); eq(#H.Get(dropC).audit, 3, "audit keeps award, undo, award")
-- an older copy never overwrites a newer one
local old = LC.DB.Copy(H.Get(dropA)); old.upd = 1; old.winner = "Zed-R"
eq(H.Upsert(old), false, "older entry rejected"); eq(H.Get(dropA).winner, "Cy-R", "newer entry kept")
-- network entries are cleaned
eq(H.Sanitize({ id = "x", itemID = "abc" }), nil, "bad item id rejected"); eq(H.Sanitize({ id = 5, itemID = 1 }), nil, "bad id rejected")
eq(H.Sanitize({ id = "x", itemID = 1, item = "item:1|hevil" }).item, nil, "bad item string dropped")
eq(H.Sanitize({ id = "x", itemID = 1, winner = ("a"):rep(500) }).winner:len(), 80, "long names cut")
-- tree: newest day first, difficulties Mythic first, bosses in kill order, items in award order
-- (times are built in local time because the day key is a local date)
local function T(d, h) return os.time({ year = 2026, month = 11, day = d, hour = h, min = 0, sec = 0 }) end
local function entry(id, kill, diff, enc, boss, t) return { id = id, itemID = 1, kill = kill, time = t or kill, difficulty = diff, encounterID = enc, boss = boss } end
local tree = H.Tree({
    entry("a", T(17, 10), 15, 2, "Second"), entry("b", T(17, 9), 15, 1, "First"),
    entry("c", T(17, 11), 16, 3, "Mythic one"), entry("d", T(16, 10), 14, 1, "First"),
    entry("e", T(17, 9), 15, 1, "First", T(17, 9) + 5) }, T(17, 12))
eq(#tree, 2, "two days"); eq(tree[1].day > tree[2].day, true, "newest day first")
eq(tree[1].diffs[1].difficulty, 16, "mythic first"); eq(tree[1].diffs[2].difficulty, 15, "then heroic")
eq(tree[1].diffs[2].bosses[1].name, "First", "bosses in kill order"); eq(#tree[1].diffs[2].bosses[1].items, 2, "items under their boss")
eq(tree[1].diffs[2].bosses[1].items[1].id, "b", "items in award order"); eq(tree[1].counts.items, 4, "day counts")
eq(tree[1].counts.pending, 4, "pending counted up the tree")
eq(H.DayKey(T(17, 1)), H.DayKey(T(16, 22)), "a raid night past midnight stays one day")
eq(H.DayKey(T(17, 7)) ~= H.DayKey(T(16, 22)), true, "the morning after starts a new day")
-- exports
local csv = H.ToCSV({ ea }, 100600)
eq(csv:find("tradedTo", 1, true) ~= nil, true, "csv header"); eq(csv:find("mismatch", 1, true) ~= nil, true, "csv carries the status")
local json = H.ToJSON({ ea }, 100600)
eq(json:find('"status":"mismatch"', 1, true) ~= nil, true, "json carries the status"); eq(json:find('"trade":{', 1, true) ~= nil, true, "json carries the trade")
-- clearing: everything goes, and the awards of the open session do not come back
local realTime = GetServerTime
GetServerTime = function() return 200000 end
eq(H.Clear(), 3, "clear reports how many it removed"); eq(#H.Query(), 0, "history is empty after clear")
H.Record(); eq(#H.Query(), 0, "recording does not bring cleared awards back")
S.Apply(hs, { t = "undo", rev = 9, id = dropB, by = "Lead-R", time = 200050 })
S.Apply(hs, { t = "award", rev = 10, id = dropB, winner = "Bob-R", reason = "bis", by = "Lead-R", time = 200100 })
H.Record(); eq(#H.Query(), 1, "an award made after the clear is recorded")
GetServerTime = realTime
LC.Preview = false

print(string.format("%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
