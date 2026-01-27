local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- VORASIUS (3177)
-- Single phase fight with repeating ~2 minute cycles
--------------------------------------------------------------------------------

local abilities = {
        {name = "Primordial Roar", spellID = 1260052, category = "raid damage, knock", phase = 1, times = {12, 132, 253}, duration = 0},
        {name = "Smashing Frenzy", spellID = 1241836, category = "tankbuster", phase = 1, times = {17, 27, 36, 46, 68, 78, 137, 147, 157, 166, 191, 201, 258, 267, 277, 287, 314, 323}, duration = 0},
        {name = "Smashing Frenzy", spellID = 1241836, category = "raid damage, soak", phase = 1, times = {22, 32, 41, 51, 73, 83, 142, 152, 162, 171, 196, 205, 263, 272, 282, 292, 319, 328}, duration = 0},
        {name = "Parasite Expulsion", spellID = 1254199, category = "add spawn, movement", phase = 1, times = {60, 182, 305}, duration = 6},
        {name = "Fixate", spellID = 1254113, category = "debuffs", phase = 1, times = {67, 189, 313}, duration = 5},
        {name = "Blisterburst", spellID = 1259186, category = "raid damage", phase = 1, times = {77, 199, 323}, duration = 12},
        {name = "Void Breath", spellID = 1256855, category = "raid damage, movement", phase = 1, times = {101, 222, 343}, duration = 15},
    }

local phases = {
        [1] = {start = 0},
        [2] = {start = 373},
    }

NSI.BossTimelines[3177] = {
    Mythic = {
        duration = 380,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 380,
        phases = phases,
        abilities = abilities,
    },
}
