local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- CHIMAERUS (3306)
-- 3-phase fight, Ravenous Dive marks transitions
--------------------------------------------------------------------------------

local abilities = {
        {name = "Rift Emergence", spellID = 1258610, category = "raid damage, add spawn", phase = 1, times = {9, 64}, duration = 0},
        {name = "Rift Sickness", spellID = 1250953, category = "healing absorb", phase = 1, times = {14, 68}, duration = 0},
        {name = "Alndust Upheaval", spellID = 1262289, category = "group soak", phase = 1, times = {19, 71, 139}, duration = 0},
        {name = "Caustic Phlegm", spellID = 1246621, category = "raid damage", phase = 1, times = {26, 53, 81, 103, 147}, duration = 0},
        {name = "Rift Madness", spellID = 1264756, category = "debuffs", phase = 1, times = {30, 85}, duration = 0},
        {name = "Colossal Strikes", spellID = 1262020, category = "tankbuster", phase = 1, times = {32, 86, 164}, duration = 0},
        {name = "Rending Tear", spellID = 1272726, category = "frontal", phase = 1, times = {36, 40, 89, 93}, duration = 0},
        {name = "Consume", spellID = 1245396, category = "raid damage", phase = 1, times = {123}, duration = 10},
        {name = "Corrupted Devastation", spellID = 1245452, category = "movement", phase = 1, times = {155, 179, 204}, duration = 0},
        {name = "Rift Emergence", spellID = 1258610, category = "raid damage, add spawn", phase = 2, times = {9, 64}, duration = 0},
        {name = "Rift Sickness", spellID = 1250953, category = "healing absorb", phase = 2, times = {14, 68}, duration = 0},
        {name = "Alndust Upheaval", spellID = 1262289, category = "group soak", phase = 2, times = {19, 71, 139}, duration = 0},
        {name = "Caustic Phlegm", spellID = 1246621, category = "raid damage", phase = 2, times = {26, 53, 81, 103, 147}, duration = 0},
        {name = "Rift Madness", spellID = 1264756, category = "debuffs", phase = 2, times = {30, 85}, duration = 0},
        {name = "Colossal Strikes", spellID = 1262020, category = "tankbuster", phase = 2, times = {32, 82, 102, 165, 184}, duration = 0},
        {name = "Rending Tear", spellID = 1272726, category = "frontal", phase = 2, times = {36, 40, 89, 93}, duration = 0},
        {name = "Consume", spellID = 1245396, category = "raid damage", phase = 2, times = {123}, duration = 0},
        {name = "Corrupted Devastation", spellID = 1245452, category = "movement", phase = 2, times = {155, 179, 204}, duration = 0},
        {name = "Ravenous Dive", spellID = 1245404, category = "raid damage, knock", phase = 2, times = {0}, duration = 0},
        {name = "Rift Emergence", spellID = 1258610, category = "raid damage, add spawn", phase = 3, times = {9, 64}, duration = 0},
        {name = "Rift Sickness", spellID = 1250953, category = "healing absorb", phase = 3, times = {14, 68}, duration = 0},
        {name = "Alndust Upheaval", spellID = 1262289, category = "group soak", phase = 3, times = {19, 71, 139}, duration = 0},
        {name = "Caustic Phlegm", spellID = 1246621, category = "raid damage", phase = 3, times = {26, 53, 81, 103, 147}, duration = 0},
        {name = "Rift Madness", spellID = 1264756, category = "debuffs", phase = 3, times = {30, 85}, duration = 0},
        {name = "Colossal Strikes", spellID = 1262020, category = "tankbuster", phase = 3, times = {32, 82, 102, 165, 184}, duration = 0},
        {name = "Rending Tear", spellID = 1272726, category = "frontal", phase = 3, times = {36, 40, 89, 93}, duration = 0},
        {name = "Consume", spellID = 1245396, category = "raid damage", phase = 3, times = {123}, duration = 0},
        {name = "Corrupted Devastation", spellID = 1245452, category = "movement", phase = 3, times = {155, 179, 204}, duration = 0},
        {name = "Ravenous Dive", spellID = 1245404, category = "raid damage, knock", phase = 3, times = {0}, duration = 0},
        {name = "Ravenous Dive", spellID = 1245404, category = "raid damage, knock", phase = 4, times = {0}, duration = 0},
    }

local phases = {
    [1] = {start = 0},
    [2] = {start = 227},
    [3] = {start = 454},
    [4] = {start = 681},
    [5] = {start = 681},
}

NSI.BossTimelines[3306] = {
    Mythic = {
        duration = 700,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 700,
        phases = phases,
        abilities = abilities,
    },
}
