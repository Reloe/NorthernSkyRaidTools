local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- IMPERATOR AVERZIAN (3176)
-- 4-phase fight, Void Fall marks intermissions
--------------------------------------------------------------------------------
NSI.BossTimelines[3176] = {
    duration = 650,
    phases = {
        [1] = {name = "Phase 1", start = 0, color = {0.23, 0.51, 0.96}},
        [2] = {name = "Phase 2", start = 193, color = {0.13, 0.77, 0.37}},
        [3] = {name = "Phase 3", start = 379, color = {0.96, 0.62, 0.04}},
        [4] = {name = "Phase 4 (Burn)", start = 565, color = {0.94, 0.27, 0.27}},
    },
    abilities = {
        -- Phase 1
        {name = "Dark Upheaval", spellID = 1249251, category = "damage", phase = 1, times = {7, 55, 91}, duration = 3.0, important = true},
        {name = "Shadow's Advance", spellID = 1262776, category = "movement", phase = 1, times = {17, 97}, duration = 4.0, important = false},
        {name = "Void Marked", spellID = 1280015, category = "soak", phase = 1, times = {23, 103}, duration = 5.0, important = true},
        {name = "Umbral Collapse", spellID = 1249266, category = "damage", phase = 1, times = {38, 45, 118, 125}, duration = 3.0, important = true},
        {name = "Void Rupture", spellID = 1262036, category = "movement", phase = 1, times = {53, 133}, duration = 4.0, important = false},
        {name = "Cosmic Eruption", spellID = 1261249, category = "damage", phase = 1, times = {58, 138}, duration = 2.0, important = true},
        {name = "Oblivion's Wrath", spellID = 1260712, category = "damage", phase = 1, times = {63, 81}, duration = 4.0, important = true},
        {name = "Void Fall", spellID = 1258880, category = "intermission", phase = 1, times = {166}, duration = 27.0, important = true},
        -- Phase 2
        {name = "Dark Upheaval", spellID = 1249251, category = "damage", phase = 2, times = {0, 48, 84}, duration = 3.0, important = true},
        {name = "Shadow's Advance", spellID = 1262776, category = "movement", phase = 2, times = {10, 90}, duration = 4.0, important = false},
        {name = "Void Marked", spellID = 1280015, category = "soak", phase = 2, times = {16, 96}, duration = 5.0, important = true},
        {name = "Umbral Collapse", spellID = 1249266, category = "damage", phase = 2, times = {31, 38, 111, 118}, duration = 3.0, important = true},
        {name = "Void Rupture", spellID = 1262036, category = "movement", phase = 2, times = {46, 126}, duration = 4.0, important = false},
        {name = "Cosmic Eruption", spellID = 1261249, category = "damage", phase = 2, times = {51, 131}, duration = 2.0, important = true},
        {name = "Oblivion's Wrath", spellID = 1260712, category = "damage", phase = 2, times = {56, 74}, duration = 4.0, important = true},
        {name = "Void Fall", spellID = 1258880, category = "intermission", phase = 2, times = {159}, duration = 27.0, important = true},
        -- Phase 3
        {name = "Dark Upheaval", spellID = 1249251, category = "damage", phase = 3, times = {0, 48, 84}, duration = 3.0, important = true},
        {name = "Shadow's Advance", spellID = 1262776, category = "movement", phase = 3, times = {10, 90}, duration = 4.0, important = false},
        {name = "Umbral Collapse", spellID = 1249266, category = "damage", phase = 3, times = {31, 38, 111, 118}, duration = 3.0, important = true},
        {name = "Void Rupture", spellID = 1262036, category = "movement", phase = 3, times = {46, 126}, duration = 4.0, important = false},
        {name = "Cosmic Eruption", spellID = 1261249, category = "damage", phase = 3, times = {51, 131}, duration = 2.0, important = true},
        {name = "Oblivion's Wrath", spellID = 1260712, category = "damage", phase = 3, times = {56, 74}, duration = 4.0, important = true},
        {name = "Void Fall", spellID = 1258880, category = "intermission", phase = 3, times = {159}, duration = 27.0, important = true},
        -- Phase 4 (Burn)
        {name = "Dark Upheaval", spellID = 1249251, category = "damage", phase = 4, times = {0}, duration = 3.0, important = true},
        {name = "Shadow's Advance", spellID = 1262776, category = "movement", phase = 4, times = {10}, duration = 4.0, important = false},
        {name = "Umbral Collapse", spellID = 1249266, category = "damage", phase = 4, times = {31, 38}, duration = 3.0, important = true},
    },
}
