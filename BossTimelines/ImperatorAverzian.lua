local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- IMPERATOR AVERZIAN (3176)
-- 4-phase fight, Void Fall marks intermissions
--------------------------------------------------------------------------------

local abilities = {
        {name = "Dark Upheaval", spellID = 1249251, category = "raid damage, movement", phase = 1, times = {7, 55, 91, 193, 241, 277, 379, 427, 463, 565}, duration = 0},
        {name = "Shadow's Advance", spellID = 1262776, category = "add spawn", phase = 1, times = {17, 97, 203, 283, 389, 469, 575}, duration = 0},
        {name = "Void Marked", spellID = 1280015, category = "debuffs", phase = 1, times = {23, 103, 209, 289}, duration = 0},
        {name = "Umbral Collapse", spellID = 1249266, category = "group soak", phase = 1, times = {38, 45, 118, 125, 224, 231, 304, 311, 410, 417, 490, 497, 596, 603}, duration = 6},
        {name = "Void Rupture", spellID = 1262036, category = "movement", phase = 1, times = {53, 133, 239, 319, 425, 505}, duration = 0},
        {name = "Cosmic Eruption", spellID = 1261249, category = "add spawn", phase = 1, times = {58, 138, 244, 324, 430, 510}, duration = 0},
        {name = "Void Fall", spellID = 1258880, category = "movement, knock", phase = 1, times = {166, 352, 538}, duration = 20},
        {name = "Oblivion's Wrath", spellID = 1260712, category = "movement", phase = 1, times = {63, 81, 249, 267, 435, 453}, duration = 0},
    }

local phases = {
        [1] = {start = 0},
        [2] = {start = 550},
    }

NSI.BossTimelines[3176] = {
    Mythic = {
        duration = 650,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 650,
        phases = phases,
        abilities = abilities,
    },
}
