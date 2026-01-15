local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- VAELGOR & EZZORAK (3178)
-- Dual-boss fight, Shadowmark phase at ~2:13
--------------------------------------------------------------------------------
NSI.BossTimelines[3178] = {
    duration = 280,
    phases = {
        [1] = {name = "Phase 1: Dual Bosses", start = 0, color = {0.23, 0.51, 0.96}},
        [2] = {name = "Phase 2: Shadowmark", start = 133, color = {0.94, 0.27, 0.27}},
    },
    abilities = {
        -- Phase 1 - Dragon (Vaelgor)
        {name = "Vaelwing", spellID = 1265131, category = "movement", phase = 1, times = {6, 31, 83, 107}, duration = 3.0, important = false},
        {name = "Tail Lash", spellID = 1264467, category = "tank", phase = 1, times = {9, 34, 59, 90}, duration = 2.0, important = true},
        {name = "Dread Breath", spellID = 1244221, category = "damage", phase = 1, times = {12, 56, 101}, duration = 4.0, important = true},
        {name = "Nullbeam", spellID = 1262623, category = "tank", phase = 1, times = {18, 75}, duration = 3.0, important = true},
        {name = "Nullzone", spellID = 1244672, category = "movement", phase = 1, times = {22, 79}, duration = 30.0, important = false},
        -- Phase 1 - Hound (Ezzorak)
        {name = "Void Howl", spellID = 1244917, category = "damage", phase = 1, times = {28, 73, 119}, duration = 3.0, important = true},
        {name = "Rakfang", spellID = 1245645, category = "tank", phase = 1, times = {37, 62, 87, 112}, duration = 2.0, important = true},
        {name = "Gloom", spellID = 1245391, category = "damage", phase = 1, times = {41, 91}, duration = 3.0, important = true},
        {name = "Gloomfield", spellID = 1245420, category = "movement", phase = 1, times = {45, 95}, duration = 20.0, important = false},
        -- Phase 2
        {name = "Shadowmark", spellID = 1270497, category = "soak", phase = 2, times = {0, 6, 12, 18, 24, 30, 36, 42}, duration = 5.0, important = true},
        {name = "Vaelwing", spellID = 1265131, category = "movement", phase = 2, times = {46, 71, 96}, duration = 3.0, important = false},
        {name = "Nullbeam", spellID = 1262623, category = "tank", phase = 2, times = {7, 50}, duration = 3.0, important = true},
        {name = "Nullzone", spellID = 1244672, category = "movement", phase = 2, times = {11, 54}, duration = 30.0, important = false},
        {name = "Dread Breath", spellID = 1244221, category = "damage", phase = 2, times = {15, 21, 61}, duration = 4.0, important = true},
        {name = "Void Howl", spellID = 1244917, category = "damage", phase = 2, times = {3, 78}, duration = 3.0, important = true},
        {name = "Impale", spellID = 1265152, category = "tank", phase = 2, times = {32, 57, 85}, duration = 2.0, important = true},
        {name = "Rakfang", spellID = 1245645, category = "tank", phase = 2, times = {52, 80}, duration = 2.0, important = true},
        {name = "Gloom", spellID = 1245391, category = "damage", phase = 2, times = {56}, duration = 3.0, important = true},
        {name = "Gloomfield", spellID = 1245420, category = "movement", phase = 2, times = {60}, duration = 20.0, important = false},
    },
}
