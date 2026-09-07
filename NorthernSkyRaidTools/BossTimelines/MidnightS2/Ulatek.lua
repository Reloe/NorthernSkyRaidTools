local _, NSI = ... -- Internal namespace

-- Ulatek (3492)

local heroicData = {
    duration = 625,
    phases = {
        [1] = {start = 0},
        [2] = {start = 625},
    },
    abilities = {
        {name = "Mother's Wrath", spellID = 1298367, category = "tankbuster, knock", phase = 1, times = {15.01, 82.01, 119.02, 377.14, 452.12, 528.13}, duration = 0},
        {name = "Spectral Coils", spellID = 1299010, category = "raid damage, group soak", phase = 1, times = {27.53, 30.5, 122.46, 125.65, 326.36, 329.7, 334.25, 336.98, 341.72, 344.56}, duration = 0},
        {name = "Mephitic Thrash", spellID = 1296301, category = "raid damage, knock", phase = 1, times = {39.01, 91}, duration = 10},
        {name = "Caustic Waves", spellID = 1292403, category = "movement", phase = 1, times = {48.01, 56.75, 100.01, 108.81, 416.65, 417.83, 471.66, 473.13, 521.65, 522.84, 565.63, 566.54}, duration = 0},
        {name = "Call of the Serpent", spellID = 1304012, category = "add spawn", phase = 1, times = {76.03, 313.05}, duration = 0},
        {name = "Malignant Shell", spellID = 1295360, category = "debuffs", phase = 1, times = {82}, duration = 48},
        {name = "Rage of the Shackled", spellID = 1286860, category = "raid aoe", phase = 1, times = {135.51, 284.57, 573.66}, duration = 20},
        {name = "Venomous Heart", spellID = 1299526, category = "damage amp", phase = 1, times = {135.52, 284.57, 573.66}, duration = 20},
        {name = "Grasping Fangs", spellID = 1301117, category = "debuffs, movement", phase = 1, times = {190.43}, duration = 4},
        {name = "Blight Vein", spellID = 1311609, category = "raid damage", phase = 1, times = {193.99, 197.9, 201.81, 205.73, 209.64, 213.55}, duration = 6},
        {name = "Malignant Shell", spellID = 1295360, category = "movement", phase = 1, times = {220}, duration = 10},
        {name = "Call of the Serpent", spellID = 1300751, category = "add spawn", phase = 1, times = {371.17, 401.14, 446.13, 506.15}, duration = 0},
        {name = "Writhing Gestation", spellID = 1290990, category = "add spawn", phase = 1, times = {198.71, 372.16, 402.15, 447.14, 507.18}, duration = 0},
        {name = "Serpent's Bite", spellID = 1295905, category = "group soak, debuffs", phase = 1, times = {392.14, 463.13, 500.13, 560.13}, duration = 15},
        {name = "Volatile Purge", spellID = 1305878, category = "raid damage, raid dot", phase = 1, times = {412.69, 483.65, 520.65, 580.68}, duration = 15},
        {name = "Acidic Expulsion", spellID = 1313531, category = "raid dot, movement", phase = 1, times = {457.16, 490.78, 517.26, 550.07, 585.7}, duration = 35},
        {name = "Circling Prey", spellID = 1315341, category = "raid damage, knock", phase = 1, times = {430.13, 481.16, 542.15, 613.28}, duration = 0},
    },
}

local mythicData = {
    duration = 615,
    phases = {
        [1] = {start = 0},
        [2] = {start = 615},
    },
    abilities = {
        {name = "Necrotic Vapors", spellID = 1286834, category = "raid dot, ramping rot", phase = 1, times = {0.99, 170.05}, duration = 0},
        {name = "Call of the Serpent", spellID = 1304012, category = "add spawn", phase = 1, times = {0.99, 71}, duration = 0},
        {name = "Toxic Incubation", spellID = 1299759, category = "raid damage, raid dot", phase = 1, times = {7.1, 76.12, 435.29}, duration = 16},
        {name = "Mother's Wrath", spellID = 1298367, category = "tankbuster, knock", phase = 1, times = {21.98, 91.98, 382.19, 467.18, 535.18}, duration = 0},
        {name = "Spectral Coils", spellID = 1299010, category = "raid damage, group soak", phase = 1, times = {40.34, 43.59, 134.33, 137.98, 336.96, 338.99, 343.06, 345.11, 348.7, 350.35, 352.77, 354.79}, duration = 0},
        {name = "Mephitic Thrash", spellID = 1296301, category = "raid damage, knock", phase = 1, times = {44.97, 102.01}, duration = 10},
        {name = "Caustic Waves", spellID = 1292403, category = "movement", phase = 1, times = {49.99, 106.98, 422.18, 477.19, 527.22, 571.21}, duration = 0},
        {name = "Submerge", spellID = 1301512, category = "event", phase = 1, times = {77, 440.23, 492.21, 552.25}, duration = 0},
        {name = "Rage of the Shackled", spellID = 1286860, category = "raid aoe", phase = 1, times = {139.03, 288.06, 577.18}, duration = 20},
        {name = "Venomous Heart", spellID = 1299526, category = "damage amp", phase = 1, times = {145.52, 294.57, 583.7}, duration = 20},
        {name = "Shadow Molt", spellID = 1301213, category = "add spawn", phase = 1, times = {176.32, 177.77}, duration = 0},
        {name = "Writhing Gestation", spellID = 1290990, category = "add spawn", phase = 1, times = {184.32, 252.43}, duration = 0},
        {name = "Grasping Fangs", spellID = 1301117, category = "debuffs, movement", phase = 1, times = {195.52, 196.73}, duration = 4},
        {name = "Blight Vein", spellID = 1311609, category = "raid damage", phase = 1, times = {205.82, 207.8, 209.8, 211.8, 213.78, 215.78, 217.76, 219.75, 221.75}, duration = 6},
        {name = "Doomscale Shell", spellID = 1300314, category = "debuffs, movement", phase = 1, times = {252.7}, duration = 19},
        {name = "Call of the Serpent", spellID = 1315541, category = "add spawn", phase = 1, times = {319.04}, duration = 0},
        {name = "Call of the Serpent", spellID = 1300751, category = "add spawn", phase = 1, times = {377.21, 407.19, 505.18}, duration = 0},
        {name = "Slithering Gestation", spellID = 1313754, category = "add spawn", phase = 1, times = {382.22, 412.19, 510.22}, duration = 0},
        {name = "Serpent's Bite", spellID = 1295905, category = "group soak, debuffs", phase = 1, times = {397.2, 461.18, 565.17}, duration = 15},
        {name = "Volatile Purge", spellID = 1305878, category = "raid damage, raid dot", phase = 1, times = {421.72, 486.7, 589.73}, duration = 15},
        {name = "Circling Prey", spellID = 1315341, category = "raid damage, knock", phase = 1, times = {432.19, 483.19, 544.2, 599}, duration = 0},
        {name = "Acidic Expulsion", spellID = 1313531, category = "raid dot, movement", phase = 1, times = {516.17, 518.21}, duration = 35},
    },
}

NSI.BossTimelines[3492] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
