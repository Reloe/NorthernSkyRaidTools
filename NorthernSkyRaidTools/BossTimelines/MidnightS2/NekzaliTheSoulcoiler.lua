local _, NSI = ... -- Internal namespace

-- NekzaliTheSoulcoiler (3470)

local heroicData = {
    duration = 530,
    phases = {
        [1] = {start = 0},
        [1.5] = {start = 147.03},
        [2] = {start = 320.18},
        [3] = {start = 530},
    },
    abilities = {
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 1, times = {3.02, 75.38, 147.74, 220.1}, duration = 44},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 1, times = {20.04, 59.99, 91.05, 131.05, 162.06, 202.11, 233.07}, duration = 15},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 1, times = {33.97, 70.01, 105.03, 141.01, 176.09, 212.01, 247.15}, duration = 3},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1, times = {52.59, 121.17, 189.75, 258.33}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1, times = {75.78}, duration = 184},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 1.5, times = {0}, duration = 0},
        {name = "Soul Transfer", spellID = 1289902, category = "event", phase = 1.5, times = {10.96}, duration = 0},
        {name = "Hungering Pyre", spellID = 1289855, category = "raid aoe", phase = 1.5, times = {36.4, 76.39, 120.21, 160.24, 200.27}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1.5, times = {58.11, 98.02, 141.87, 181.87}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1.5, times = {25.27}, duration = 195},
        {name = "Uncoiling", spellID = 1292315, category = "ramping rot, raid dot", phase = 2, times = {0}, duration = 220},
        {name = "Invoke", spellID = 1299673, category = "add spawn", phase = 2, times = {0, 48.01, 80.08, 127.99, 160.16, 207.97}, duration = 0},
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 2, times = {0, 48.01, 80.08, 127.99, 160.16, 207.97}, duration = 44},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 2, times = {32.95, 61, 113, 193.05}, duration = 3},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 2, times = {42, 122.03, 202.06}, duration = 15},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 2, times = {17.16, 57.13, 97.1, 137.22, 177.24, 217.26}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 2, times = {44.17}, duration = 176},
    },
}

local mythicData = {
    duration = 429,
    phases = {
        [1] = {start = 0},
        [1.5] = {start = 102},
        [2] = {start = 229},
        [3] = {start = 429},
    },
    abilities = {
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 1, times = {3.02, 75.08}, duration = 44},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 1, times = {20.06, 60.55, 91.05}, duration = 15},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 1, times = {34.02, 70.03}, duration = 3},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 1, times = {42.53}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1, times = {52.66}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1, times = {67.22}, duration = 93},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 1.5, times = {0}, duration = 0},
        {name = "Soul Transfer", spellID = 1289902, category = "event", phase = 1.5, times = {19.96}, duration = 0},
        {name = "Hungering Pyre", spellID = 1289855, category = "raid aoe", phase = 1.5, times = {42.47, 72.47, 102.51, 132.55, 162.55}, duration = 0},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 1.5, times = {41.5, 71.5, 101.5}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1.5, times = {46.97, 56.97, 76.97, 107.01, 117.01}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1.5, times = {59.07}, duration = 161},
        {name = "Uncoiling", spellID = 1292315, category = "ramping rot, raid dot", phase = 2, times = {0}, duration = 200},
        {name = "Invoke", spellID = 1299673, category = "add spawn", phase = 2, times = {0, 49.99, 80.01, 129.99, 160.01}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 2, times = {0}, duration = 200},
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 2, times = {0, 49.99, 80.01, 129.99, 160.01}, duration = 44},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 2, times = {35, 62.98, 115, 142.98}, duration = 3},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 2, times = {11.5, 51.5, 91.5, 131.5, 171.5}, duration = 0},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 2, times = {44.01, 124.03}, duration = 15},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 2, times = {19.15, 59.09, 99.04, 138.99, 178.94}, duration = 0},
    },
}

NSI.BossTimelines[3470] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
