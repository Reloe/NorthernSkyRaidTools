local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- IMPERATOR AVERZIAN (3176)
-- 4-phase fight, Void Fall marks intermissions
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Dark Upheaval", spellID = 1249251, category = "raid damage, movement", phase = 1, times = {7, 43, 79, 158, 194, 230, 269, 348, 384, 420, 499, 535, 571}, duration = 0},
    {name = "Shadow's Advance", spellID = 1262776, category = "add spawn", phase = 1, times = {15, 87, 166, 238, 317, 389, 468, 540}, duration = 0},
    {name = "Umbral Collapse", spellID = 1249266, category = "group soak", phase = 1, times = {26, 33, 98, 105, 177, 184, 249, 256, 328, 335, 400, 407, 479, 486, 551, 558}, duration = 6},
    {name = "Void Rupture", spellID = 1262036, category = "movement", phase = 1, times = {36, 108, 187, 259, 338, 410, 489, 561}, duration = 0},
    {name = "Cosmic Eruption", spellID = 1261249, category = "add spawn", phase = 1, times = {41, 113, 192, 264, 343, 415, 494, 566}, duration = 0},
    {name = "Void Fall", spellID = 1258880, category = "movement, knock", phase = 1, times = {131, 282, 433, 584}, duration = 20},
    {name = "Oblivion's Wrath", spellID = 1260712, category = "movement", phase = 1, times = {51, 69, 202, 220, 353, 371, 504, 522}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 550},
}

local mythicAbilities = {
    {name = "Dark Upheaval", spellID = 1249251, category = "raid damage, movement", phase = 1, times = {7, 55, 91, 193, 241, 277, 379, 427, 463, 565}, duration = 0},
    {name = "Shadow's Advance", spellID = 1262776, category = "add spawn", phase = 1, times = {17, 97, 203, 283, 389, 469, 575}, duration = 0},
    {name = "Void Marked", spellID = 1280015, category = "debuffs", phase = 1, times = {23, 103, 209, 289}, duration = 0},
    {name = "Umbral Collapse", spellID = 1249266, category = "group soak", phase = 1, times = {40, 47, 120, 127, 226, 233, 306, 313, 412, 419, 492, 499, 598, 605}, duration = 6},
    {name = "Void Rupture", spellID = 1262036, category = "movement", phase = 1, times = {53, 133, 239, 319, 425, 505}, duration = 0},
    {name = "Cosmic Eruption", spellID = 1261249, category = "add spawn", phase = 1, times = {58, 138, 244, 324, 430, 510}, duration = 0},
    {name = "Void Fall", spellID = 1258880, category = "movement, knock", phase = 1, times = {166, 352, 538}, duration = 20},
    {name = "Oblivion's Wrath", spellID = 1260712, category = "movement", phase = 1, times = {63, 81, 249, 267, 435, 453}, duration = 0},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 550},
}

NSI.BossTimelines[3176] = {
    Heroic = {
        duration = 555,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 555,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
