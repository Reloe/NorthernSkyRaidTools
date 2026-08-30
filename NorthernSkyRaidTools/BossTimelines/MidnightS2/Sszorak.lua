local _, NSI = ... -- Internal namespace

-- Sszorak (3420)

local heroicData = {
    duration = 450,
    phases = {
        [1] = {start = 0},
        [2] = {start = 450},
    },
    abilities = {
        {name = "Mutilate", spellID = 1277027, category = "group soak, frontal", phase = 1, times = {8.59, 60.8, 146.72, 198.95, 284.85, 337.1, 423}, duration = 16.5},
        {name = "Ravage", spellID = 1277002, category = "tank debuff, frontal", phase = 1, times = {8.59, 60.8, 146.72, 198.95, 284.85, 337.1, 423}, duration = 16.5},
        {name = "Tempest", spellID = 1287072, category = "raid debuff, movement", phase = 1, times = {13.09, 65.3, 151.22, 203.45, 289.35, 341.6, 427.5}, duration = 8},
        {name = "Venomous Surge", spellID = 1305959, category = "raid debuff, spread", phase = 1, times = {32.22, 84.44, 170.39, 222.64, 308.53, 360.72, 446.65}, duration = 10},
        {name = "Raging Crosswinds", spellID = 1285453, category = "raid dot, knock", phase = 1, times = {44.12, 96.3, 182.26, 234.49, 320.39, 372.62}, duration = 8},
        {name = "Dig In", spellID = 1286033, category = "damage amp", phase = 1, times = {111.17, 249.27, 387.42}, duration = 25},
    },
}

local mythicData = {
    duration = 392,
    phases = {
        [1] = {start = 0},
        [2] = {start = 392},
    },
    abilities = {
        {name = "Mutilate", spellID = 1277027, category = "group soak, frontal", phase = 1, times = {8.03, 55.01, 135.03, 182.01, 262.03, 309.01, 389.03}, duration = 16.5},
        {name = "Ravage", spellID = 1277002, category = "tank debuff, frontal", phase = 1, times = {8.03, 55.01, 135.03, 182.01, 262.03, 309.01, 389.03}, duration = 16.5},
        {name = "Tempest", spellID = 1287072, category = "raid debuff, movement", phase = 1, times = {12.53, 59.51, 139.53, 186.51, 266.53, 313.51}, duration = 8},
        {name = "Venomous Surge", spellID = 1305959, category = "raid debuff, spread", phase = 1, times = {29, 77, 156, 203, 283, 330}, duration = 10},
        {name = "Virulence", spellID = 1297707, category = "raid damage, raid dot", phase = 1, times = {27, 76, 152, 202, 279, 329}, duration = 5},
        {name = "Raging Crosswinds", spellID = 1285453, category = "raid dot, knock", phase = 1, times = {39.77, 86.75, 166.8, 213.75, 293.77, 340.75}, duration = 8},
        {name = "Dig In", spellID = 1286033, category = "damage amp", phase = 1, times = {100.02, 227.02, 354.02}, duration = 25},
    },
}

NSI.BossTimelines[3420] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
