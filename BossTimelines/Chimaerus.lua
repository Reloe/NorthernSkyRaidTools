local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- CHIMAERUS (3306)
-- 3-phase fight, Ravenous Dive marks transitions
--------------------------------------------------------------------------------

local abilities = {
    -- Phase 1
    {name = "Rift Emergence", spellID = 1258610, category = "damage", phase = 1, times = {9, 64}, duration = 3},
    {name = "Rift Sickness", spellID = 1250953, category = "damage", phase = 1, times = {14, 68}, duration = 4},
    {name = "Alndust Upheaval", spellID = 1262289, category = "damage", phase = 1, times = {19, 71, 139}, duration = 3},
    {name = "Caustic Phlegm", spellID = 1246621, category = "damage", phase = 1, times = {26, 53, 81, 103, 147}, duration = 3},
    {name = "Rift Madness", spellID = 1264756, category = "soak", phase = 1, times = {30, 85}, duration = 8},
    {name = "Colossal Strikes", spellID = 1262020, category = "tank", phase = 1, times = {32, 86, 164}, duration = 2},
    {name = "Rending Tear", spellID = 1272726, category = "tank", phase = 1, times = {36, 40, 89, 93}, duration = 2},
    {name = "Consume", spellID = 1245396, category = "damage", phase = 1, times = {123}, duration = 5},
    {name = "Corrupted Devastation", spellID = 1245452, category = "damage", phase = 1, times = {155, 179, 204}, duration = 4},
    {name = "Ravenous Dive", spellID = 1245404, category = "intermission", phase = 1, times = {227}, duration = 9},
    -- Phase 2
    {name = "Rift Emergence", spellID = 1258610, category = "damage", phase = 2, times = {9, 64}, duration = 3},
    {name = "Rift Sickness", spellID = 1250953, category = "damage", phase = 2, times = {14, 68}, duration = 4},
    {name = "Alndust Upheaval", spellID = 1262289, category = "damage", phase = 2, times = {19, 71, 139}, duration = 3},
    {name = "Caustic Phlegm", spellID = 1246621, category = "damage", phase = 2, times = {26, 53, 81, 103, 147}, duration = 3},
    {name = "Rift Madness", spellID = 1264756, category = "soak", phase = 2, times = {30, 85}, duration = 8},
    {name = "Colossal Strikes", spellID = 1262020, category = "tank", phase = 2, times = {32, 82, 102, 165, 184}, duration = 2},
    {name = "Rending Tear", spellID = 1272726, category = "tank", phase = 2, times = {36, 40, 89, 93}, duration = 2},
    {name = "Consume", spellID = 1245396, category = "damage", phase = 2, times = {123}, duration = 5},
    {name = "Corrupted Devastation", spellID = 1245452, category = "damage", phase = 2, times = {155, 179, 204}, duration = 4},
    {name = "Ravenous Dive", spellID = 1245404, category = "intermission", phase = 2, times = {227}, duration = 9},
    -- Phase 3
    {name = "Rift Emergence", spellID = 1258610, category = "damage", phase = 3, times = {9, 64}, duration = 3},
    {name = "Rift Sickness", spellID = 1250953, category = "damage", phase = 3, times = {14, 68}, duration = 4},
    {name = "Alndust Upheaval", spellID = 1262289, category = "damage", phase = 3, times = {19, 71, 139}, duration = 3},
    {name = "Caustic Phlegm", spellID = 1246621, category = "damage", phase = 3, times = {26, 53, 81, 103, 147}, duration = 3},
    {name = "Rift Madness", spellID = 1264756, category = "soak", phase = 3, times = {30, 85}, duration = 8},
    {name = "Colossal Strikes", spellID = 1262020, category = "tank", phase = 3, times = {32, 82, 102, 165, 184}, duration = 2},
    {name = "Rending Tear", spellID = 1272726, category = "tank", phase = 3, times = {36, 40, 89, 93}, duration = 2},
    {name = "Consume", spellID = 1245396, category = "damage", phase = 3, times = {123}, duration = 5},
    {name = "Corrupted Devastation", spellID = 1245452, category = "damage", phase = 3, times = {155, 179, 204}, duration = 4},
    {name = "Ravenous Dive", spellID = 1245404, category = "intermission", phase = 3, times = {227}, duration = 0},
}

local phases = {
    [1] = {start = 0},
    [2] = {start = 227},
    [3] = {start = 454},
}

NSI.BossTimelines[3306] = {
    Mythic = {
        duration = 720,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 720,
        phases = phases,
        abilities = abilities,
    },
    Normal = {
        duration = 720,
        phases = phases,
        abilities = abilities,
    },
}
