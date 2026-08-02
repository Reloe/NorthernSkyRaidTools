local _, NSI = ... -- Internal namespace

-- VaelgorEzzorak (3178)

local heroicData = {
    duration = 500,
    phases = {
        [1] = {start = 0},
        [2] = {start = 106},
        [3] = {start = 500},
    },
    abilities = {
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
    },
}

local mythicData = {
    duration = 540,
    phases = {
        [1] = {start = 0},
        [2] = {start = 540},
    },
    abilities = {
        {name = "Vaelwing", spellID = 1265131, category = "tankbuster, knock", phase = 1, times = {13.5, 40.5, 57.5, 90.5, 107.5, 188.5, 205.5, 238.5, 256.5, 288.5, 353.5, 386.5, 403.5, 442.5, 453.5}, duration = 2},
        {name = "Tail Lash", spellID = 1264467, category = "tankbuster, knock", phase = 1, times = {14, 41, 58, 91, 108, 189, 206, 239, 257, 289, 354, 387, 404, 443, 454}, duration = 0},
        {name = "Rakfang", spellID = 1245645, category = "tankbuster", phase = 1, times = {17.5, 42.5, 67.5, 88.5, 117.5, 186.5, 216.5, 236.5, 265.5, 290.5, 363.5, 384.5, 413.5, 434.5}, duration = 2},
        {name = "Impale", spellID = 1265152, category = "tankbuster", phase = 1, times = {18, 43, 68, 89, 118, 187, 217, 237, 266, 291, 364, 385, 414, 435}, duration = 0},
        {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 1, times = {34, 84, 144, 182, 232, 282, 380, 430, 473}, duration = 4},
        {name = "Shadowmark", spellID = 1270497, category = "debuffs", phase = 1, times = {133, 140, 148, 155, 162, 170, 304, 311, 319, 327, 334, 342, 469, 476, 484, 491, 498, 506}, duration = 0},
        {name = "Midnight Manifestation", spellID = 1258744, category = "raid dot", phase = 1, times = {7, 187, 343}, duration = 120},
        {name = "Dread Breath", spellID = 1244221, category = "movement", phase = 1, times = {7, 72, 136, 148, 193, 250, 319, 363, 437, 483}, duration = 4},
        {name = "Dread Breath", spellID = 1244221, category = "dispel", phase = 1, times = {11, 76, 140, 152, 197, 254, 323, 367, 441, 487}, duration = 0},
        {name = "Gloom", spellID = 1245391, category = "group soak", phase = 1, times = {14, 64, 114, 213, 262, 315, 360, 410, 479}, duration = 0},
        {name = "Gloom", spellID = 1245391, category = "raid damage", phase = 1, times = {27, 73, 128, 222, 273, 329, 371, 417, 490}, duration = 0},
        {name = "Nullzone", spellID = 1244672, category = "movement", phase = 1, times = {40, 90, 149, 188, 238, 288, 385, 435}, duration = 0},
        {name = "Void Howl", spellID = 1244917, category = "raid damage, movement, adds", phase = 1, times = {38, 78, 171, 206, 246, 286, 308, 374, 419, 454}, duration = 0},
        {name = "Midnight Flames", spellID = 1249748, category = "raid damage, raid dot", phase = 1, times = {133, 304, 469}, duration = 25},
    },
}

NSI.BossTimelines[3178] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
