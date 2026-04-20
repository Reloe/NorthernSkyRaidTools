local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- FALLEN KING SALHADAAR (3179)
-- Single phase, Cosmic Unraveling every ~122s
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Void Convergence", spellID = 1243453, category = "add spawn", phase = 1, times = {14, 60, 135, 181, 258, 303, 381, 427, 502}, duration = 0},
    {name = "Twisting Obscurity", spellID = 1250686, category = "raid damage", phase = 1, times = {16, 62, 139, 185, 261, 307, 383, 429, 505}, duration = 23},
    {name = "Fractured Projection", spellID = 1254081, category = "event", phase = 1, times = {18, 64, 141, 187, 263, 309, 385, 431, 508}, duration = 0},
    {name = "Dark Radiation", spellID = 1285211, category = "raid damage", phase = 1, times = {26, 41, 72, 87, 149, 164, 195, 210, 271, 286, 317, 332, 393, 408, 439, 454}, duration = 8},
    {name = "Despotic Command", spellID = 1260823, category = "debuffs", phase = 1, times = {29, 76, 150, 197, 273, 319, 396, 442}, duration = 12},
    {name = "Shattering Twilight", spellID = 1253032, category = "debuffs, movement", phase = 1, times = {48, 94, 171, 217, 293, 338, 414, 459}, duration = 5},
    {name = "Twilight Spikes", spellID = 1251213, category = "movement", phase = 1, times = {53, 99, 101, 174, 225, 296, 340, 422, 462}, duration = 0},
    {name = "Entropic Unraveling", spellID = 1246175, category = "raid damage, movement, damage amp", phase = 1, times = {102, 225, 347, 469}, duration = 20},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 500},
}

local mythicAbilities = {
    {name = "Void Convergence", spellID = 1243453, category = "add spawn", phase = 1, times = {13, 59, 135, 181, 258, 303, 380, 425, 502}, duration = 0},
    {name = "Twisting Obscurity", spellID = 1250686, category = "raid damage", phase = 1, times = {16, 61, 138, 183, 260, 305, 382, 427, 504}, duration = 36},
    {name = "Fractured Projection", spellID = 1254081, category = "event, interrupt", phase = 1, times = {28, 73, 150, 195, 272, 317, 394, 439}, duration = 0},
    {name = "Dark Radiation", spellID = 1285211, category = "raid damage", phase = 1, times = {28, 46, 85, 97, 158, 175, 202, 215, 284, 298, 327, 342, 404, 419, 449, 464}, duration = 8},
    {name = "Despotic Command", spellID = 1260823, category = "debuffs", phase = 1, times = {24, 69, 146, 191, 268, 313, 390, 435}, duration = 12},
    {name = "Shattering Twilight", spellID = 1253032, category = "debuffs, movement", phase = 1, times = {50, 95, 172, 217, 294, 339, 416, 461}, duration = 5},
    {name = "Entropic Unraveling", spellID = 1246175, category = "raid damage, movement, damage amp", phase = 1, times = {103, 225, 347, 469}, duration = 20},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 500},
}

NSI.BossTimelines[3179] = {
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
