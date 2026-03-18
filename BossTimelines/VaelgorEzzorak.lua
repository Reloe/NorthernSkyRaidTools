local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- VAELGOR & EZZORAK (3178)
-- Dual-boss fight, Shadowmark phase at ~2:13
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Vaelwing", spellID = 1265131, category = "tankbuster, knock", phase = 1, times = {6, 31, 56, 88, 145, 171, 196, 220, 271, 304, 346, 371, 406}, duration = 0},
    {name = "Tail Lash", spellID = 1264467, category = "tankbuster, knock", phase = 1, times = {9, 34, 59, 90, 273, 307, 349, 373, 409}, duration = 0},
    {name = "Rakfang", spellID = 1245645, category = "tankbuster", phase = 1, times = {13, 37, 63, 88, 138, 163, 188, 216, 279, 312, 346, 379, 412}, duration = 0},
    {name = "Impale", spellID = 1265152, category = "tankbuster", phase = 1, times = {140, 165, 190, 218, 281, 314, 348, 381, 414}, duration = 0},
    {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 1, times = {19, 60, 183, 288, 363}, duration = 0},
    {name = "Nullzone", spellID = 1244672, category = "movement, raid damage", phase = 1, times = {23, 64, 187, 292, 367}, duration = 0},
    {name = "Gloom", spellID = 1245391, category = "tankbuster", phase = 1, times = {51, 147, 192, 237, 318, 384}, duration = 0},
    {name = "Gloomfield", spellID = 1245420, category = "soak", phase = 1, times = {55, 151, 196, 241, 322, 388}, duration = 0},
    {name = "Midnight Manifestation", spellID = 1258744, category = "raid dot", phase = 1, times = {9, 29, 49, 141, 161, 181, 274, 301, 327, 354, 381}, duration = 25},
    {name = "Dread Breath", spellID = 1244221, category = "movement", phase = 1, times = {10, 44, 79, 163, 207, 276, 335, 395}, duration = 7},
    {name = "Dread Breath", spellID = 1244221, category = "event", phase = 1, times = {17, 51, 86, 170, 214, 283, 342, 402}, duration = 0},
    {name = "Void Howl", spellID = 1244917, category = "raid damage, movement", phase = 1, times = {28, 73, 145, 179, 214, 299, 359, 420}, duration = 0},
    {name = "Midnight Flames", spellID = 1249748, category = "raid damage, raid dot", phase = 1, times = {118, 251}, duration = 25},
    {name = "Shadowmark", spellID = 1270497, category = "debuffs", phase = 1, times = {117, 123, 129, 136, 142, 148, 155, 161, 248, 254, 260, 266, 272, 278, 285, 291}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 500},
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
