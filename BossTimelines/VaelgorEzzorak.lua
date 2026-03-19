local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- VAELGOR & EZZORAK (3178)
-- Dual-boss fight, Shadowmark phase at ~2:13
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Vaelwing", spellID = 1265131, category = "", phase = 1, times = {6, 32, 56, 81}, duration = 0},
    {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 1, times = {14, 64}, duration = 0},
    {name = "Nullzone", spellID = 1244672, category = "tankbuster", phase = 1, times = {18, 68}, duration = 0},
    {name = "Dread Breath", spellID = 1244221, category = "movement, dispel", phase = 1, times = {24, 52, 68, 84, 104}, duration = 8},
    {name = "Gloom", spellID = 1245391, category = "tankbuster", phase = 1, times = {55}, duration = 0},
    {name = "Gloomfield", spellID = 1245420, category = "group soak", phase = 1, times = {64}, duration = 0},
    {name = "Void Howl", spellID = 1244917, category = "raid damage, add spawn", phase = 1, times = {33, 78}, duration = 0},
    {name = "Vaelwing", spellID = 1265131, category = "tankbuster, knock", phase = 2, times = {157, 188, 220, 251, 282, 313, 345}, duration = 0},
    {name = "Rakfang", spellID = 1245645, category = "tankbuster", phase = 2, times = {26, 51, 76, 101, 165, 196, 233, 258, 290, 321, 352}, duration = 0},
    {name = "Impale", spellID = 1265152, category = "tankbuster", phase = 2, times = {28, 53, 78, 103, 167, 198, 235, 260, 292, 323, 354}, duration = 0},
    {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 2, times = {73, 166, 229, 291, 354}, duration = 0},
    {name = "Nullzone", spellID = 1244672, category = "tankbuster", phase = 2, times = {77, 170, 233, 295, 358}, duration = 0},
    {name = "Dread Breath", spellID = 1244221, category = "movement, dispel", phase = 2, times = {44, 95, 211, 297}, duration = 8},
    {name = "Gloom", spellID = 1245391, category = "tankbuster", phase = 2, times = {34, 84, 205, 267, 330}, duration = 0},
    {name = "Gloomfield", spellID = 1245420, category = "group soak", phase = 2, times = {44, 94, 214, 276, 339}, duration = 0},
    {name = "Midnight Flames", spellID = 1249748, category = "raid damage", phase = 2, times = {6, 138, 388}, duration = 10},
    {name = "Void Howl", spellID = 1244917, category = "raid damage, add spawn", phase = 2, times = {38, 62, 88, 112, 177, 228, 280, 336}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 113},
    [3] = {start = 500},
}

local mythicAbilities = {
    {name = "Vaelwing", spellID = 1265131, category = "tankbuster, knock", phase = 1, times = {6, 31, 62, 83, 107, 179, 204, 229}, duration = 0},
    {name = "Tail Lash", spellID = 1264467, category = "tankbuster, knock", phase = 1, times = {9, 34, 59, 90}, duration = 0},
    {name = "Rakfang", spellID = 1245645, category = "tankbuster", phase = 1, times = {12, 37, 62, 87, 112, 185, 213}, duration = 0},
    {name = "Impale", spellID = 1265152, category = "tankbuster", phase = 1, times = {140, 165, 190, 218}, duration = 0},
    {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 1, times = {18, 75, 140, 183}, duration = 0},
    {name = "Nullzone", spellID = 1244672, category = "movement, raid damage", phase = 1, times = {22, 79, 144, 187}, duration = 0},
    {name = "Gloom", spellID = 1245391, category = "group soak", phase = 1, times = {41, 91, 189}, duration = 0},
    {name = "Gloomfield", spellID = 1245420, category = "soak", phase = 1, times = {45, 95, 193}, duration = 0},
    {name = "Midnight Manifestation", spellID = 1258744, category = "raid dot", phase = 1, times = {28, 73, 119, 136, 211}, duration = 25},
    {name = "Dread Breath", spellID = 1244221, category = "movement, debuffs", phase = 1, times = {12, 56, 101, 148, 154, 194}, duration = 7},
    {name = "Void Howl", spellID = 1244917, category = "raid damage, movement", phase = 1, times = {28, 73, 119, 136, 211}, duration = 0},
    {name = "Midnight Flames", spellID = 1249748, category = "raid damage, raid dot", phase = 1, times = {133}, duration = 25},
    {name = "Shadowmark", spellID = 1270497, category = "debuffs", phase = 1, times = {133, 139, 145, 151, 157, 163, 169, 175}, duration = 0},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 500},
}

NSI.BossTimelines[3178] = {
    Heroic = {
        duration = 500,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 500,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
