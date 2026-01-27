local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- DIMENSIUS THE ALL DEVOURING (3135)
--------------------------------------------------------------------------------

local abilities = {
    {name = "Devour", spellID = 1229038, category = "raid aoe", phase = 1, times = {13, 97, 180}, duration = 5},
    {name = "Massive Smash", spellID = 1230087, category = "raid aoe", phase = 1, times = {25, 67, 109, 151}, duration = 0},
    {name = "Living Mass", spellID = 1230087, category = "add spawn", phase = 1, times = {1, 26, 68, 110, 152}, duration = 0},
    {name = "Fission", spellID = 1231005, category = "raid dot", phase = 1, times = {1, 29, 71, 112, 154}, duration = 15},
    {name = "Dark Matter", spellID = 1230979, category = "raid aoe", phase = 1, times = {34, 73, 118, 157}, duration = 7},
    {name = "Shattered Space", spellID = 1243702, category = "raid aoe", phase = 1, times = {40, 80, 124, 163}, duration = 0},
    {name = "Antimatter", spellID = 1243702, category = "raid soak", phase = 1, times = {41, 81, 125, 164}, duration = 8},
    {name = "Reverse Gravity", spellID = 1243577, category = "debuff", phase = 1, times = {43, 85, 127}, duration = 6},
    {name = "Take Off", spellID = 1243349, category = "event", phase = 2, times = {5}, duration = 30},
    {name = "Conqueror's Cross", spellID = 1239262, category = "add spawn", phase = 3, times = {13, 44}, duration = 0},
    {name = "Null Binding", spellID = 1246541, category = "add spawn", phase = 3, times = {13, 44}, duration = 0},
    {name = "Mass Destruction", spellID = 1249423, category = "debuff", phase = 3, times = {19, 34, 50}, duration = 0},
    {name = "Extinction", spellID = 1238765, category = "movement", phase = 3, times = {21, 53}, duration = 5},
    {name = "Inverse Gravity", spellID = 1234244, category = "raid soak", phase = 3, times = {28, 60}, duration = 0},
    {name = "Gamma Burst", spellID = 1237325, category = "raid aoe", phase = 3, times = {35, 67}, duration = 4},
    {name = "Take Off", spellID = 1243349, category = "event", phase = 4, times = {5}, duration = 25},
    {name = "Conqueror's Cross", spellID = 1239262, category = "add spawn", phase = 5, times = {19, 51}, duration = 0},
    {name = "Null Binding", spellID = 1246541, category = "add spawn", phase = 5, times = {19, 51}, duration = 0},
    {name = "Starshard Nova", spellID = 1251619, category = "debuff", phase = 5, times = {23, 55}, duration = 0},
    {name = "Extinction", spellID = 1238765, category = "movement", phase = 5, times = {28, 59}, duration = 5},
    {name = "Inverse Gravity", spellID = 1234244, category = "raid soak", phase = 5, times = {35, 66}, duration = 0},
    {name = "Gamma Burst", spellID = 1237325, category = "raid aoe", phase = 5, times = {42, 74}, duration = 4},
    {name = "Cosmic Collapse", spellID = 1234263, category = "tankbuster", phase = 6, times = {77, 107, 137, 167, 197}, duration = 0},
    {name = "Destabilised", spellID = 1229038, category = "dps buff", phase = 6, times = {16}, duration = 15},
    {name = "Extinguish The Stars", spellID = 1231716, category = "raid aoe", phase = 6, times = {32}, duration = 8},
    {name = "Devour", spellID = 1229038, category = "raid aoe", phase = 6, times = {65, 145, 225}, duration = 5},
    {name = "Supernova", spellID = 1232986, category = "raid aoe", phase = 6, times = {77, 157}, duration = 0},
    {name = "Inverse Gravity", spellID = 1234244, category = "movement", phase = 6, times = {75, 101, 133, 159, 191}, duration = 5},
    {name = "Inverse Gravity", spellID = 1234244, category = "raid soak", phase = 6, times = {80, 106, 138, 164, 196}, duration = 0},
    {name = "Darkened Sky", spellID = 1234044, category = "movement", phase = 6, times = {45, 87, 117, 167, 197}, duration = 16},
    {name = "Shadowquake", spellID = 1234054, category = "raid aoe", phase = 6, times = {52, 56, 60, 94, 98, 102, 124, 128, 132, 174, 178, 182, 204, 208, 212}, duration = 0},
}

local phases = {
    [1] = {start = 0},
    [2] = {start = 175},
    [3] = {start = 211},
    [4] = {start = 271},
    [5] = {start = 301},
    [6] = {start = 394},
    [7] = {start = 606},
}

NSI.BossTimelines[3135] = {
    Mythic = {
        duration = 610,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 610,
        phases = phases,
        abilities = abilities,
    },
}
