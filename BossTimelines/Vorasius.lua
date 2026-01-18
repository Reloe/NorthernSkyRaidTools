local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- VORASIUS (3177)
-- Single phase fight with repeating ~2 minute cycles
--------------------------------------------------------------------------------

local abilities = {
    {name = "Primordial Roar", spellID = 1260052, category = "damage", phase = 1, times = {12, 132, 253}, duration = 3},
    {name = "Smashing Frenzy", spellID = 1241836, category = "tank", phase = 1, times = {17, 22, 27, 32, 36, 41, 46, 51, 68, 73, 78, 83, 137, 142, 147, 152, 157, 162, 166, 171, 191, 196, 201, 205, 258, 263, 267, 272, 277, 282, 287, 292, 314, 319, 328}, duration = 2},
    {name = "Parasite Expulsion", spellID = 1254199, category = "movement", phase = 1, times = {60, 182, 305}, duration = 4},
    {name = "Fixate", spellID = 1254113, category = "movement", phase = 1, times = {67, 189, 313}, duration = 10},
    {name = "Blisterburst", spellID = 1259186, category = "damage", phase = 1, times = {77, 199, 323}, duration = 2},
    {name = "Void Breath", spellID = 1256855, category = "damage", phase = 1, times = {101, 222, 343}, duration = 5},
}

local phases = {
    [1] = {start = 0},
}

NSI.BossTimelines[3177] = {
    Mythic = {
        duration = 400,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 400,
        phases = phases,
        abilities = abilities,
    },
    Normal = {
        duration = 400,
        phases = phases,
        abilities = abilities,
    },
}
