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
    {name = "Vaelwing", spellID = 1265131, category = "tankbuster, knock", phase = 2, times = {159, 190, 222, 253, 284, 315, 347}, duration = 0},
    {name = "Rakfang", spellID = 1245645, category = "tankbuster", phase = 2, times = {28, 53, 78, 103, 167, 198, 235, 260, 292, 323, 354}, duration = 0},
    {name = "Impale", spellID = 1265152, category = "tankbuster", phase = 2, times = {30, 55, 80, 105, 169, 200, 237, 262, 294, 325, 356}, duration = 0},
    {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 2, times = {75, 168, 231, 293, 356}, duration = 0},
    {name = "Nullzone", spellID = 1244672, category = "tankbuster", phase = 2, times = {79, 172, 235, 297, 360}, duration = 0},
    {name = "Dread Breath", spellID = 1244221, category = "movement, dispel", phase = 2, times = {46, 97, 213, 299}, duration = 8},
    {name = "Gloom", spellID = 1245391, category = "tankbuster", phase = 2, times = {36, 86, 207, 269, 332}, duration = 0},
    {name = "Gloomfield", spellID = 1245420, category = "group soak", phase = 2, times = {46, 96, 216, 278, 341}, duration = 0},
    {name = "Midnight Flames", spellID = 1249748, category = "raid damage", phase = 2, times = {8, 140, 390}, duration = 10},
    {name = "Void Howl", spellID = 1244917, category = "raid damage, add spawn", phase = 2, times = {40, 64, 90, 114, 179, 230, 282, 338}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 106},
    [3] = {start = 500},
}

local mythicAbilities = {
    {name = "Vaelwing", spellID = 1265131, category = "tankbuster, knock", phase = 1, times = {12, 39, 56, 89, 106, 187, 204, 237, 255, 287, 352, 385, 402, 441, 452}, duration = 2},
    {name = "Tail Lash", spellID = 1264467, category = "tankbuster, knock", phase = 1, times = {14, 41, 58, 91, 108, 189, 206, 239, 257, 289, 354, 387, 404, 443, 454}, duration = 0},
    {name = "Rakfang", spellID = 1245645, category = "tankbuster", phase = 1, times = {16, 41, 66, 87, 116, 185, 215, 235, 264, 289, 362, 383, 412, 433}, duration = 2},
    {name = "Impale", spellID = 1265152, category = "tankbuster", phase = 1, times = {18, 43, 68, 89, 118, 187, 217, 237, 266, 291, 364, 385, 414, 435}, duration = 0},
    {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 1, times = {30, 80, 140, 178, 228, 278, 376, 426, 469}, duration = 4},
    {name = "Shadowmark", spellID = 1270497, category = "debuffs", phase = 1, times = {132, 139, 147, 154, 161, 169, 303, 310, 318, 326, 333, 341, 468, 475, 483, 490, 497, 505}, duration = 0},
    {name = "Midnight Manifestation", spellID = 1258744, category = "raid dot", phase = 1, times = {7, 187, 343}, duration = 120},
    {name = "Dread Breath", spellID = 1244221, category = "movement", phase = 1, times = {7, 72, 136, 148, 193, 250, 319, 363, 437, 483}, duration = 4},
    {name = "Dread Breath", spellID = 1244221, category = "dispel", phase = 1, times = {11, 76, 140, 152, 197, 254, 323, 367, 441, 487}, duration = 0},
    {name = "Gloom", spellID = 1245391, category = "group soak", phase = 1, times = {14, 64, 114, 213, 262, 315, 360, 410, 479}, duration = 0},
    {name = "Gloom", spellID = 1245391, category = "raid damage", phase = 1, times = {27, 73, 128, 222, 273, 329, 371, 417, 490}, duration = 0},
    {name = "Nullzone", spellID = 1244672, category = "movement", phase = 1, times = {40, 90, 149, 188, 238, 288, 385, 435}, duration = 0},
    {name = "Void Howl", spellID = 1244917, category = "raid damage, movement, adds", phase = 1, times = {38, 78, 171, 206, 246, 286, 308, 374, 419, 454}, duration = 0},
    {name = "Midnight Flames", spellID = 1249748, category = "raid damage, raid dot", phase = 1, times = {133, 304, 469}, duration = 25},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 540},
}

NSI.BossTimelines[3178] = {
    Heroic = {
        duration = 500,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 540,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
