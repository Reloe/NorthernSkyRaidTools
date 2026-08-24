local _, NSI = ... -- Internal namespace

-- NekzaliTheSoulcoiler (3470)

local heroicData = {
    duration = 496.53,
    phases = {
        [1] = {start = 0},
        [1.5] = {start = 133.95},
        [1.75] = {start = 214.21},
        [2] = {start = 276.53},
        [3] = {start = 496.53},
    },
    abilities = {
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 1, times = {3.02, 75.83, 147.75}, duration = 44},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 1, times = {20.04, 60.04, 91.05, 131.05, 162.07}, duration = 15},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 1, times = {35.62, 71.61, 106.63, 142.63, 177.66}, duration = 3},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1, times = {52.64, 121.22}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1, times = {67.02, 133.34}, duration = 26},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 1.5, times = {0}, duration = 134},
        {name = "Soul Transfer", spellID = 1292248, category = "event", phase = 1.5, times = {25.46}, duration = 0},
        {name = "Hungering Pyre", spellID = 1289855, category = "raid aoe", phase = 1.5, times = {35.97, 76}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1.5, times = {57.65}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1.5, times = {66.83}, duration = 32},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 1.75, times = {0}, duration = 72},
        {name = "Soul Transfer", spellID = 1292248, category = "phase change", phase = 1.75, times = {15}, duration = 0},
        {name = "Hungering Pyre", spellID = 1289855, category = "raid aoe", phase = 1.75, times = {25.53, 65.53}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1.75, times = {47.14}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1.75, times = {61.5}, duration = 30},
        {name = "Uncoiling", spellID = 1292315, category = "ramping rot, raid dot", phase = 2, times = {0}, duration = 220},
        {name = "Invoke", spellID = 1299673, category = "add spawn", phase = 2, times = {18.04, 66.03, 98.06, 146.05, 178.05}, duration = 0},
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 2, times = {18.04, 66.03, 98.06, 146.05, 178.05}, duration = 44},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 2, times = {52.62, 80.63, 132.64, 160.65}, duration = 3},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 2, times = {60.32, 140.22}, duration = 15},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 2, times = {35.14, 75.17, 115.19, 155.18}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 2, times = {54.22, 94.02, 138.53, 176.51}, duration = 21},
        {name = "Uncoiled Rage", spellID = 1284034, category = "event", phase = 2, times = {183.8}, duration = 0},
    },
}

local mythicData = {
    duration = 588.28,
    phases = {
        [1] = {start = 0},
        [1.5] = {start = 197.89},
        [1.75] = {start = 281.9},
        [2] = {start = 368.28},
        [3] = {start = 588.28},
    },
    abilities = {
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 1, times = {2.99, 77.04, 148.16}, duration = 44},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 1, times = {20.01, 60.03, 91.04, 131.02, 162.02}, duration = 15},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 1, times = {36.22, 72.22, 107.22, 143.24, 178.27}, duration = 3},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 1, times = {42.51, 113.52, 184.54}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1, times = {52.67, 121.18, 192.19}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1, times = {68.08, 134.64}, duration = 27},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 1.5, times = {0}, duration = 84},
        {name = "Soul Transfer", spellID = 1292248, category = "event", phase = 1.5, times = {25.45}, duration = 0},
        {name = "Hungering Pyre", spellID = 1289855, category = "raid aoe", phase = 1.5, times = {35.95, 70.97}, duration = 0},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 1.5, times = {44.96, 79.98}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1.5, times = {52.58}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1.5, times = {6, 67.26}, duration = 23},
        {name = "Ritual of Awakening", spellID = 1295124, category = "phase change", phase = 1.75, times = {0}, duration = 89},
        {name = "Soul Transfer", spellID = 1292248, category = "phase change", phase = 1.75, times = {15}, duration = 0},
        {name = "Hungering Pyre", spellID = 1289855, category = "raid aoe", phase = 1.75, times = {25.53, 60.53}, duration = 0},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 1.75, times = {34.53, 69.54}, duration = 0},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 1.75, times = {3.95, 42.14, 77.17}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 1.75, times = {32.05, 66.35}, duration = 23},
        {name = "Uncoiling", spellID = 1292315, category = "ramping rot, raid dot", phase = 2, times = {0}, duration = 220},
        {name = "Invoke", spellID = 1299673, category = "add spawn", phase = 2, times = {18.04, 66.03, 98.05, 146.05, 178.08}, duration = 0},
        {name = "Corpse Blight", spellID = 1307939, category = "raid damage, raid dot", phase = 2, times = {0, 50.76, 95.25, 133.72, 178.4}, duration = 21},
        {name = "Soulcoil Rite", spellID = 1288772, category = "raid aoe, raid dot", phase = 2, times = {18.04, 66.03, 98.05, 146.05, 178.08}, duration = 44},
        {name = "Possession Barrage", spellID = 1284103, category = "raid damage, frontal", phase = 2, times = {53.26, 81.27, 133.28, 161.27}, duration = 3},
        {name = "Soulcoil Well", spellID = 1285623, category = "event", phase = 2, times = {27.53, 67.54, 107.56, 147.57, 187.55}, duration = 0},
        {name = "Essence Rend", spellID = 1287434, category = "debuffs, movement", phase = 2, times = {60.04, 140.2}, duration = 15},
        {name = "Restless Amani", spellID = 1289919, category = "add spawn", phase = 2, times = {35.13, 75.16, 115.27, 155.23, 195.27}, duration = 0},
        {name = "Uncoiled Rage", spellID = 1284034, category = "event", phase = 2, times = {184.08}, duration = 0},
    },
}

NSI.BossTimelines[3470] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
