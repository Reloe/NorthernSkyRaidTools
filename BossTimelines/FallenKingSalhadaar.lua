local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- FALLEN KING SALHADAAR (3179)
-- Single phase, Cosmic Unraveling every ~122s
--------------------------------------------------------------------------------

local abilities = {
        {name = "Desperate Measures", spellID = 1243453, category = "add spawn", phase = 1, times = {14, 60, 135, 181, 258, 303, 381, 427, 502}, duration = 0},
        {name = "Twisting Obscurity", spellID = 1250686, category = "raid damage", phase = 1, times = {16, 62, 139, 185, 261, 307, 383, 429, 505}, duration = 23},
        {name = "Fractured Projection", spellID = 1254081, category = "event, interrupt", phase = 1, times = {18, 64, 141, 187, 263, 309, 385, 431, 508}, duration = 0},
        {name = "Galactic Miasma", spellID = 1250991, category = "raid damage", phase = 1, times = {26, 40, 77, 98, 162, 181, 202, 221, 289, 299, 332, 347, 397, 416, 449, 469}, duration = 8},
        {name = "Despotic Command", spellID = 1260823, category = "debuffs", phase = 1, times = {29, 76, 150, 197, 273, 319, 396, 442}, duration = 12},
        {name = "Shattering Twilight", spellID = 1253032, category = "debuffs, movement", phase = 1, times = {48, 94, 171, 217, 293, 338, 414, 459}, duration = 5},
        {name = "Twilight Spikes", spellID = 1251213, category = "movement", phase = 1, times = {53, 99, 101, 174, 225, 296, 340, 422, 462}, duration = 0},
        {name = "Cosmic Unraveling", spellID = 1246175, category = "raid damage, movement, damage amp", phase = 1, times = {102, 225, 347, 469}, duration = 20},
    }

local phases = {
    phases = {
        [1] = {start = 0},
        [2] = {start = 500},
    }
}

NSI.BossTimelines[3179] = {
    Mythic = {
        duration = 500,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 500,
        phases = phases,
        abilities = abilities,
    },
}
