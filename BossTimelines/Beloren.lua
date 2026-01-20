local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- BELO'REN (3182)
-- Phoenix fight with ~110s cycles, intermissions at Death Drop
--------------------------------------------------------------------------------

local abilities = {
    {name = "Voidlight Convergence", spellID = 1242515, category = "damage", phase = 1, times = {1, 82, 192, 302, 412}, duration = 4},
    {name = "Light Dive", spellID = 1241291, category = "movement", phase = 1, times = {20, 101, 211, 321, 431}, duration = 3},
    {name = "Void Edict", spellID = 1261218, category = "soak", phase = 1, times = {21, 107, 137, 217, 247, 327, 357, 437, 467, 487}, duration = 3},
    {name = "Light Edict", spellID = 1261217, category = "soak", phase = 1, times = {26, 102, 132, 152, 212, 242, 262, 322, 352, 372, 432, 462, 482}, duration = 3},
    {name = "Holy Burn", spellID = 1244348, category = "damage", phase = 1, times = {27, 108, 126, 148, 218, 236, 258, 328, 346, 368, 438, 456, 478}, duration = 3},
    {name = "Death Drop", spellID = 1246709, category = "intermission", phase = 1, times = {40, 46, 150, 156, 260, 266, 370, 376}, duration = 3},
    {name = "Incubation of Flames", spellID = 1242792, category = "intermission", phase = 1, times = {47, 157, 267, 377}, duration = 8},
    {name = "Voidlight Edict", spellID = 1241640, category = "soak", phase = 1, times = {72, 112, 142, 222, 252, 332, 362}, duration = 3},
    {name = "Light Quill", spellID = 1241992, category = "damage", phase = 1, times = {122, 232, 342, 452, 472}, duration = 3},
    {name = "Guardian's Edict", spellID = 1260826, category = "soak", phase = 1, times = {128, 237, 347, 458}, duration = 4},
    {name = "Radiant Echoes", spellID = 1242981, category = "damage", phase = 1, times = {158, 268, 378, 442, 488}, duration = 4},
}

local phases = {
    [1] = {start = 0},
}

NSI.BossTimelines[3182] = {
    Mythic = {
        duration = 540,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 540,
        phases = phases,
        abilities = abilities,
    },
}
