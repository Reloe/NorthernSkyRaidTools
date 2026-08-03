local _, NSI = ... -- Internal namespace

-- TheTwinFangs (3421)

local heroicData = {
    duration = 514,
    phases = {
        [1] = {start = 0},
        [2] = {start = 514},
    },
    abilities = {
        {name = "Caustic Deluge", spellID = 1289192, category = "tank debuff, spread", phase = 1, times = {9.9, 77.7, 179.41, 247.2, 348.88, 416.65}, duration = 5},
        {name = "Stone Breaker", spellID = 1288538, category = "knock, soak, raid damage", phase = 1, times = {26.52, 29.52, 32.53, 94.32, 97.32, 100.33, 195.99, 199.01, 202.01, 263.78, 266.78, 269.79, 365.49, 368.48, 371.49, 433.26, 436.25, 439.26}, duration = 0},
        {name = "Venomous Emergence", spellID = 1291404, category = "add spawn, raid damage", phase = 1, times = {39.69, 107.48, 209.17, 276.95, 378.67, 446.41}, duration = 0},
        {name = "Coiling Ichor", spellID = 1290809, category = "raid debuff, spread", phase = 1, times = {47.48, 115.25, 216.95, 284.72, 386.4, 454.18}, duration = 12},
        {name = "Stir the Depths", spellID = 1290956, category = "raid aoe", phase = 1, times = {52.24, 120.04, 221.76, 289.54, 391.21, 458.97}, duration = 6},
        {name = "Ravenous Feast", spellID = 1290516, category = "group soak", phase = 1, times = {67.86, 135.63, 237.36, 305.15, 406.81, 474.58}, duration = 0},
        {name = "Bloody Expulsion", spellID = 1302013, category = "raid damage", phase = 1, times = {70.86, 138.64, 240.38, 308.15, 409.8, 477.58}, duration = 0},
        {name = "Sanguine Storm", spellID = 1306872, category = "raid damage", phase = 1, times = {150.47, 319.95}, duration = 18},
        {name = "Vile Flood", spellID = 1294293, category = "raid damage", phase = 1, times = {154.48, 323.96}, duration = 14},
    },
}

local mythicData = {
    duration = 470,
    phases = {
        [1] = {start = 0},
        [2] = {start = 470},
    },
    abilities = {
        {name = "Caustic Deluge", spellID = 1289192, category = "tank debuff, spread", phase = 1, times = {9.01, 70.05, 164.06, 225.1, 319.11, 380.15}, duration = 5},
        {name = "Blood Torrent", spellID = 1303230, category = "tank debuff, healing absorb", phase = 1, times = {9.01, 70.05, 164.06, 225.1, 319.11, 380.15}, duration = 5},
        {name = "Stone Breaker", spellID = 1288538, category = "knock, soak, raid damage", phase = 1, times = {24.52, 27.52, 30.52, 85.53, 88.53, 91.53, 179.58, 182.57, 185.59, 240.6, 243.6, 246.6, 334.61, 337.61, 340.61, 395.65, 398.65, 401.65}, duration = 0},
        {name = "Venomous Emergence", spellID = 1291404, category = "add spawn, raid damage", phase = 1, times = {36.03, 97.02, 191.08, 252.1, 346.11, 407.15}, duration = 0},
        {name = "Coiling Ichor", spellID = 1290809, category = "raid debuff, spread", phase = 1, times = {43.03, 104.03, 198.06, 259.1, 353.11, 414.15}, duration = 12},
        {name = "Stir the Depths", spellID = 1290956, category = "raid aoe", phase = 1, times = {47.05, 108.03, 202.07, 263.11, 357.12, 418.16}, duration = 6},
        {name = "Ravenous Feast", spellID = 1290516, category = "group soak", phase = 1, times = {61.27, 122.28, 216.31, 277.35, 371.36, 432.4}, duration = 0},
        {name = "Tainted Blood", spellID = 1310099, category = "healing absorb, group soak", phase = 1, times = {63.25, 124.26, 218.29, 279.33, 373.34, 434.38}, duration = 8},
        {name = "Sanguine Storm", spellID = 1306872, category = "raid damage", phase = 1, times = {136.04, 291.09, 446.14}, duration = 18},
        {name = "Vile Flood", spellID = 1294293, category = "raid damage", phase = 1, times = {140.04, 295.09, 450.14}, duration = 14},
    },
}

NSI.BossTimelines[3421] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
