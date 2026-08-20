local _, NSI = ... -- Internal namespace

-- Ulatek (3492)

local heroicData = {
    duration = 625,
    phases = {
        [1] = {start = 0},
        [2] = {start = 625},
    },
    abilities = {
        {name = "Mother's Wrath", spellID = 1298367, category = "tankbuster, knock", phase = 1, times = {15.01, 82.01, 119.02, 377.23, 452.26, 528.23}, duration = 0},
        {name = "Spectral Coils", spellID = 1299010, category = "raid damage, group soak", phase = 1, times = {27.5, 30.53, 128.88, 131.72, 326.6, 329.63, 334.09, 337.57, 341.85, 344.65}, duration = 0},
        {name = "Mephitic Thrash", spellID = 1296301, category = "raid damage, knock", phase = 1, times = {39.01, 91}, duration = 0},
        {name = "Caustic Waves", spellID = 1292403, category = "movement", phase = 1, times = {48.01, 56.98, 100.01, 109.02, 416.74, 418.06, 471.76, 473.08, 521.75, 523.3}, duration = 0},
        {name = "Call of the Serpent", spellID = 1304012, category = "add spawn", phase = 1, times = {76.03, 313.05}, duration = 0},
        {name = "Malignant Shell", spellID = 1295360, category = "debuffs", phase = 1, times = {82}, duration = 48},
        {name = "Rage of the Shackled", spellID = 1286860, category = "raid aoe, raid dot", phase = 1, times = {135.51, 284.57}, duration = 20},
        {name = "Venomous Heart", spellID = 1299526, category = "damage amp", phase = 1, times = {135.52, 284.57}, duration = 20},
        {name = "Hatching Doom", spellID = 1306862, category = "add spawn", phase = 1, times = {164.17}, duration = 0},
        {name = "Malice", spellID = 1290779, category = "raid aoe, interrupt", phase = 1, times = {175.05, 202.58}, duration = 0},
        {name = "Grasping Fangs", spellID = 1301117, category = "debuffs, movement", phase = 1, times = {190.1, 199.6, 209.1, 218.6, 228.1, 237.6, 247.1, 256.6}, duration = 4},
        {name = "Blight Vein", spellID = 1311609, category = "raid damage", phase = 1, times = {194.1, 203.6, 213.1, 222.6, 232.1, 241.6, 251.1, 260.6}, duration = 6},
        {name = "Malignant Shell", spellID = 1295360, category = "movement", phase = 1, times = {220}, duration = 10},
        {name = "Call of the Serpent", spellID = 1300751, category = "add spawn", phase = 1, times = {371.23, 401.23, 446.24, 506.26}, duration = 0},
        {name = "Writhing Gestation", spellID = 1290990, category = "add spawn", phase = 1, times = {372.26, 402.25, 447.25, 507.26}, duration = 0},
        {name = "Serpent's Bite", spellID = 1295905, category = "group soak, debuffs", phase = 1, times = {392.21, 463.24, 500.25}, duration = 15},
        {name = "Circling Prey", spellID = 1315341, category = "raid damage, knock", phase = 1, times = {430.24, 481.25, 542.26, 613.28}, duration = 0},
    },
}

local mythicData = {
    duration = 600,
    phases = {
        [1] = {start = 0},
        [2] = {start = 600},
    },
    abilities = {
    },
}

NSI.BossTimelines[3492] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
