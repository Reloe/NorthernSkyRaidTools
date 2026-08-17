local _, NSI = ... -- Internal namespace

-- NekzaliTheSoulcoiler (3470)

local heroicData = {
    duration = 640,
    phases = {
        [1] = {start = 0},
        [1.5] = {start = 248},
        [2] = {start = 437},
    },
    abilities = {
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 1, times = {3.03, 84.83, 166.68}, duration = 44},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 1, times = {18.26, 76.46, 100.11, 158.28, 181.96, 240.12}, duration = 15},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 1, times = {35.12, 64.2, 116.94, 146.03, 198.78, 227.86}, duration = 3},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1, times = {56.36, 87.46, 135.66, 169.25, 217.5}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1, times = {75.78}, duration = 184},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 1.5, times = {0}, duration = 0},
        {name = "Soul Transfer", spellID = 1289902, category = "event", phase = 1.5, times = {19.96}, duration = 0},
        {name = "Residual Toll", spellID = 1305993, category = "raid damage", phase = 1.5, times = {33.09, 55.13, 90.11, 100.05, 122.95, 144.85}, duration = 0},
        {name = "Hungering Pyre", spellID = 1305421, category = "raid aoe", phase = 1.5, times = {52.1, 74.09, 96.03, 141.88, 163.85}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1.5, times = {2.72}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1.5, times = {25.27}, duration = 98},
        {name = "Uncoiling", spellID = 1292315, category = "ramping rot, raid dot", phase = 2, times = {0}, duration = 220},
        {name = "Invoke", spellID = 1299673, category = "add spawn", phase = 2, times = {0, 27.99, 50.01, 78.03, 100.04, 128.02, 151.55, 178}, duration = 0},
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 2, times = {0, 27.99, 50.01, 78.03, 100.04, 128.02, 151.55, 178}, duration = 44},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 2, times = {34.05, 84.06, 134.05, 184.01}, duration = 3},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 2, times = {23.13, 73.14, 123.13, 173.08}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 2, times = {44.17}, duration = 176},
    },
}

local mythicData = {
    duration = 420,
    phases = {
        [1] = {start = 0},
        [1.5] = {start = 102},
        [2] = {start = 229},
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
