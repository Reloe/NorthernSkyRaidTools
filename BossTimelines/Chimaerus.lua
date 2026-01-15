local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- CHIMAERUS (3306)
-- 3-phase fight, Ravenous Dive marks transitions
--------------------------------------------------------------------------------
NSI.BossTimelines[3306] = {
    duration = 720,
    phases = {
        [1] = {name = "Phase 1", start = 0, color = {0.23, 0.51, 0.96}},
        [2] = {name = "Phase 2", start = 227, color = {0.13, 0.77, 0.37}},
        [3] = {name = "Phase 3", start = 454, color = {0.94, 0.27, 0.27}},
    },
    abilities = {
        -- Phase 1
        {name = "Rift Emergence", spellID = 1258610, category = "damage", phase = 1, times = {9, 64}, duration = 3.0, important = true},
        {name = "Rift Sickness", spellID = 1250953, category = "damage", phase = 1, times = {14, 68}, duration = 4.0, important = true},
        {name = "Alndust Upheaval", spellID = 1262289, category = "damage", phase = 1, times = {19, 71, 139}, duration = 3.0, important = true},
        {name = "Caustic Phlegm", spellID = 1246621, category = "damage", phase = 1, times = {26, 53, 81, 103, 147}, duration = 3.0, important = false},
        {name = "Rift Madness", spellID = 1264756, category = "soak", phase = 1, times = {30, 85}, duration = 8.0, important = true},
        {name = "Colossal Strikes", spellID = 1262020, category = "tank", phase = 1, times = {32, 86, 164}, duration = 2.0, important = true},
        {name = "Rending Tear", spellID = 1272726, category = "tank", phase = 1, times = {36, 40, 89, 93}, duration = 2.0, important = true},
        {name = "Consume", spellID = 1245396, category = "damage", phase = 1, times = {123}, duration = 5.0, important = true},
        {name = "Corrupted Devastation", spellID = 1245452, category = "damage", phase = 1, times = {155, 179, 204}, duration = 4.0, important = true},
        {name = "Ravenous Dive", spellID = 1245404, category = "intermission", phase = 1, times = {227}, duration = 9.0, important = true},
        -- Phase 2
        {name = "Rift Emergence", spellID = 1258610, category = "damage", phase = 2, times = {9, 64}, duration = 3.0, important = true},
        {name = "Rift Sickness", spellID = 1250953, category = "damage", phase = 2, times = {14, 68}, duration = 4.0, important = true},
        {name = "Alndust Upheaval", spellID = 1262289, category = "damage", phase = 2, times = {19, 71, 139}, duration = 3.0, important = true},
        {name = "Caustic Phlegm", spellID = 1246621, category = "damage", phase = 2, times = {26, 53, 81, 103, 147}, duration = 3.0, important = false},
        {name = "Rift Madness", spellID = 1264756, category = "soak", phase = 2, times = {30, 85}, duration = 8.0, important = true},
        {name = "Colossal Strikes", spellID = 1262020, category = "tank", phase = 2, times = {32, 82, 102, 165, 184}, duration = 2.0, important = true},
        {name = "Rending Tear", spellID = 1272726, category = "tank", phase = 2, times = {36, 40, 89, 93}, duration = 2.0, important = true},
        {name = "Consume", spellID = 1245396, category = "damage", phase = 2, times = {123}, duration = 5.0, important = true},
        {name = "Corrupted Devastation", spellID = 1245452, category = "damage", phase = 2, times = {155, 179, 204}, duration = 4.0, important = true},
        {name = "Ravenous Dive", spellID = 1245404, category = "intermission", phase = 2, times = {227}, duration = 9.0, important = true},
        -- Phase 3
        {name = "Rift Emergence", spellID = 1258610, category = "damage", phase = 3, times = {9, 64}, duration = 3.0, important = true},
        {name = "Rift Sickness", spellID = 1250953, category = "damage", phase = 3, times = {14, 68}, duration = 4.0, important = true},
        {name = "Alndust Upheaval", spellID = 1262289, category = "damage", phase = 3, times = {19, 71, 139}, duration = 3.0, important = true},
        {name = "Caustic Phlegm", spellID = 1246621, category = "damage", phase = 3, times = {26, 53, 81, 103, 147}, duration = 3.0, important = false},
        {name = "Rift Madness", spellID = 1264756, category = "soak", phase = 3, times = {30, 85}, duration = 8.0, important = true},
        {name = "Colossal Strikes", spellID = 1262020, category = "tank", phase = 3, times = {32, 82, 102, 165, 184}, duration = 2.0, important = true},
        {name = "Rending Tear", spellID = 1272726, category = "tank", phase = 3, times = {36, 40, 89, 93}, duration = 2.0, important = true},
        {name = "Consume", spellID = 1245396, category = "damage", phase = 3, times = {123}, duration = 5.0, important = true},
        {name = "Corrupted Devastation", spellID = 1245452, category = "damage", phase = 3, times = {155, 179, 204}, duration = 4.0, important = true},
        {name = "Ravenous Dive", spellID = 1245404, category = "intermission", phase = 3, times = {227}, duration = 0.0, important = true},
    },
}
