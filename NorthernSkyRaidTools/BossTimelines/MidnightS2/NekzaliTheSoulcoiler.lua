local _, NSI = ... -- Internal namespace

-- NekzaliTheSoulcoiler (3470)

local heroicData = {
    duration = 640,
    phases = {
        [1] = {start = 0},
        [2] = {start = 248},
        [3] = {start = 437},
    },
    abilities = {
        {name = "Soulcoil Ignition", spellID = 1293664, category = "raid aoe", phase = 1, times = {3.03, 84.83, 166.68}, duration = 0},
        {name = "Possession Barrage", spellID = 1284103, category = "frontal", phase = 1, times = {35.12, 64.2, 116.94, 146.03, 198.78, 227.86}, duration = 0},
        {name = "Gravebound Advance", spellID = 1287533, category = "add spawn", phase = 1, times = {56.38, 87.47, 135.7, 169.26, 217.54}, duration = 0},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 2, times = {0}, duration = 0},
        {name = "Soul Transfer", spellID = 1289902, category = "event", phase = 2, times = {19.96}, duration = 0},
        {name = "Residual Toll", spellID = 1305993, category = "raid damage", phase = 2, times = {33.09, 55.13, 90.11, 100.05, 122.95, 144.85}, duration = 0},
        {name = "Hungering Pyre", spellID = 1305421, category = "raid aoe", phase = 2, times = {52.1, 74.09, 96.03, 141.88, 163.85}, duration = 0},
        {name = "Invoke", spellID = 1299673, category = "add spawn", phase = 3, times = {0, 27.99, 50.01, 78.03, 100.04, 128.02, 151.55, 178}, duration = 0},
        {name = "Possession Barrage", spellID = 1284103, category = "frontal", phase = 3, times = {34.05, 84.06, 134.05, 184.01}, duration = 0},
    },
}

local mythicData = {
    duration = 420,
    phases = {
        [1] = {start = 0},
        [2] = {start = 102},
        [3] = {start = 229},
    },
    abilities = {
        {name = "Soulcoil Ignition", spellID = 1293664, category = "raid aoe", phase = 1, times = {3.02, 75.08}, duration = 0},
        {name = "Possession Barrage", spellID = 1284103, category = "frontal", phase = 1, times = {34.02, 70.03}, duration = 0},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 1, times = {42.53}, duration = 0},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 2, times = {0}, duration = 0},
        {name = "Soul Transfer", spellID = 1289902, category = "event", phase = 2, times = {19.96}, duration = 0},
        {name = "Residual Toll", spellID = 1298698, category = "raid damage", phase = 2, times = {48.95, 78.97, 109.01}, duration = 12},
        {name = "Hungering Pyre", spellID = 1289855, category = "raid aoe", phase = 2, times = {42.47, 72.47, 102.51}, duration = 0},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 2, times = {41.5, 71.5, 101.5}, duration = 0},
        {name = "Invoke", spellID = 1299673, category = "add spawn", phase = 3, times = {0, 49.99, 80.01, 129.99, 160.01}, duration = 0},
        {name = "Possession Barrage", spellID = 1284103, category = "frontal", phase = 3, times = {35, 62.98, 115, 142.98}, duration = 0},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 3, times = {11.5, 51.5, 91.5, 131.5, 171.5}, duration = 0},
    },
}

NSI.BossTimelines[3470] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
