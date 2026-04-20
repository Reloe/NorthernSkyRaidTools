local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- MIDNIGHT FALLS (3183)
-- Multi-phase fight with Eclipsed/Total Eclipse intermissions
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Heaven's Lance", spellID = 1267049, category = "tankbuster", phase = 1, times = {20, 40, 60, 80, 101, 120, 140, 160}, duration = 0},
    {name = "Death's Dirge", spellID = 1249620, category = "event", phase = 1, times = {10, 80, 150}, duration = 9},
    {name = "Death's Dirge", spellID = 1249620, category = "raid damage", phase = 1, times = {28, 98, 168}, duration = 3},
    {name = "Heaven's Glaives", spellID = 1253915, category = "movement", phase = 1, times = {38, 108, 178}, duration = 0},
    {name = "Dark Quasar", spellID = 1282470, category = "movement", phase = 1, times = {40, 110}, duration = 10},
    {name = "Safeguard Prism", spellID = 1251386, category = "event", phase = 1, times = {59, 129}, duration = 8},
    {name = "Disintegration", spellID = 1251649, category = "raid damage", phase = 1, times = {67, 137}, duration = 0},
    {name = "Glimmering", spellID = 1253031, category = "debuffs", phase = 1, times = {79, 149}, duration = 0},
    {name = "Eclipsed", spellID = 1262055, category = "healing absorb", phase = 2, times = {7}, duration = 30},
    {name = "Into the Darkwell", spellID = 1282043, category = "phase change", phase = 2, times = {42}, duration = 6},
    {name = "Dark Quasar", spellID = 1282470, category = "movement", phase = 2, times = {10, 16, 22, 28, 35, 41}, duration = 0},
    {name = "Galvanize", spellID = 1284528, category = "raid damage", phase = 3, times = {18, 48, 78}, duration = 0},
    {name = "Heaven's Lance", spellID = 1267049, category = "tankbuster", phase = 3, times = {18, 38, 58, 78}, duration = 0},
    {name = "Core Harvest", spellID = 1282412, category = "raid damage", phase = 3, times = {34, 64, 94}, duration = 0},
    {name = "Dark Meltdown", spellID = 1281123, category = "raid damage, phase change", phase = 3, times = {103}, duration = 0},
    {name = "Heaven's Lance", spellID = 1267049, category = "tankbuster", phase = 4, times = {23, 43, 63, 83, 103, 123}, duration = 0},
    {name = "Dark Constellation", spellID = 1266344, category = "movement, raid damage", phase = 4, times = {37, 48, 75, 86, 113, 124}, duration = 0},
    {name = "Dawnlight Barrier", spellID = 1253104, category = "event", phase = 4, times = {19, 57, 95, 133}, duration = 6},
    {name = "The Dark Archangel", spellID = 1251331, category = "raid damage", phase = 4, times = {22, 60, 98, 136}, duration = 0},
    {name = "Light Siphon", spellID = 1266810, category = "group soak", phase = 4, times = {26, 64, 102, 140}, duration = 20},
    {name = "Glimmering", spellID = 1253031, category = "debuffs", phase = 4, times = {6}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 184},
    [3] = {start = 227},
    [4] = {start = 330},
    [5] = {start = 495},
}

local mythicAbilities = {
    {name = "Heaven's Lance", spellID = 1267049, category = "tankbuster", phase = 1, times = {20, 40, 60, 80, 100, 120, 140, 160}, duration = 0},
    {name = "Termination Prism", spellID = 1284931, category = "add spawn", phase = 1, times = {6, 68, 130}, duration = 0},
    {name = "Termination Prism", spellID = 1284931, category = "raid damage", phase = 1, times = {16, 78, 140}, duration = 10},
    {name = "Heaven's Glaives", spellID = 1253915, category = "movement", phase = 1, times = {26, 88, 150}, duration = 3},
    {name = "Dark Rune", spellID = 1249609, category = "debuffs", phase = 1, times = {40, 102, 164}, duration = 14},
    {name = "Grim Symphony", spellID = 1284980, category = "raid damage", phase = 1, times = {50, 112, 174}, duration = 4},
    {name = "Dark Quasar", spellID = 1279420, category = "raid aoe", phase = 1, times = {57, 119}, duration = 8},
    {name = "Total Eclipse", spellID = 1285563, category = "raid dot", phase = 2, times = {11}, duration = 30},
    {name = "Into the Darkwell", spellID = 1282043, category = "movement", phase = 3, times = {1}, duration = 6},
    {name = "Galvanize", spellID = 1284525, category = "raid damage", phase = 3, times = {13, 43, 73}, duration = 7},
    {name = "Core Harvest", spellID = 1282412, category = "raid damage", phase = 3, times = {33, 63, 93}, duration = 3},
    {name = "Dark Meltdown", spellID = 1281123, category = "raid damage", phase = 3, times = {97}, duration = 8},
    {name = "Heaven's Lance", spellID = 1267049, category = "tankbuster", phase = 3, times = {20, 40, 60, 80}, duration = 3},
    {name = "Severance", spellID = 1275057, category = "raid damage", phase = 4, times = {2.1}, duration = 10},
    {name = "Heaven's Lance", spellID = 1267049, category = "tankbuster", phase = 4, times = {40, 70, 100, 130, 160}, duration = 2},
    {name = "Light Siphon [Left]", spellID = 1266897, category = "group soak", phase = 4, times = {18, 93, 128}, duration = 18},
    {name = "Death's Requiem [Left]", spellID = 1286915, category = "debuffs", phase = 4, times = {43, 78, 153}, duration = 15},
    {name = "Dark Constellation [Left]", spellID = 1266388, category = "raid aoe", phase = 4, times = {20, 28, 36, 44, 52, 79, 87, 95, 103, 130, 144, 156}, duration = 3},
    {name = "Light Siphon [Right]", spellID = 1266810, category = "group soak", phase = 4, times = {38, 73, 148}, duration = 18},
    {name = "Death's Requiem [Right]", spellID = 1273375, category = "debuffs", phase = 4, times = {23, 98, 133}, duration = 15},
    {name = "Dark Constellation [Right]", spellID = 1266344, category = "raid aoe", phase = 4, times = {24, 32, 40, 48, 75, 83, 91, 99, 107, 137, 150, 162}, duration = 3},
    {name = "The Dark Archangel", spellID = 1251343, category = "raid damage", phase = 4, times = {57, 112, 167}, duration = 6},
    {name = "Black Tide", spellID = 1263253, category = "raid aoe", phase = 4, times = {63, 118, 173}, duration = 6},
    {name = "Starsplinter", spellID = 1285510, category = "spread", phase = 5, times = {13, 33, 53, 73, 93}, duration = 5},
    {name = "Heaven & Hell", spellID = 1276525, category = "raid damage", phase = 5, times = {24, 44, 64, 84}, duration = 5},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 180},
    [3] = {start = 225},
    [4] = {start = 330},
    [5] = {start = 522},
    [6] = {start = 624},
}

NSI.BossTimelines[3183] = {
    Heroic = {
        duration = 495,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 630,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
