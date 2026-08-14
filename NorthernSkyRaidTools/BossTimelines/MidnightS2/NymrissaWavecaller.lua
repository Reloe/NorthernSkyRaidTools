local _, NSI = ... -- Internal namespace

-- NymrissaWavecaller (3379)

local heroicData = {
    duration = 420,
    phases = {
        [1] = {start = 0},
        [2] = {start = 420},
    },
    abilities = {
        {name = "Abyssal Rain", spellID = 1260837, category = "raid damage, raid dot", phase = 1, times = {5.01, 122.03, 239.04}, duration = 4},
        {name = "Water Flurry", spellID = 1282937, category = "tankbuster, tank debuff", phase = 1, times = {16.02, 46.01, 95.02, 133.02, 163.02, 212.02, 250.04, 280.02, 329.03}, duration = 6},
        {name = "Alluring Bubble", spellID = 1257717, category = "add spawn, event", phase = 1, times = {27.01, 144.03, 261.05}, duration = 50},
        {name = "Frost Barrage", spellID = 1257614, category = "raid damage, raid dot, movement", phase = 1, times = {39.02, 59.03, 110.03, 156.01, 176.02, 227.03, 273.03, 293.03, 344.04}, duration = 4},
        {name = "Tidepiercer's Rush", spellID = 1258673, category = "movement", phase = 1, times = {68.01, 185.02, 302.04}, duration = 0},
        {name = "Pop!", spellID = 1258150, category = "raid damage, knock", phase = 1, times = {77.02, 194.02, 311.05}, duration = 0},
        {name = "Unending Tides", spellID = 1295086, category = "raid damage, event", phase = 1, times = {360.05}, duration = 0},
    },
}

local mythicData = {
    duration = 420,
    phases = {
        [1] = {start = 0},
        [2] = {start = 420},
    },
    abilities = {
        {name = "Frost Barrage", spellID = 1257614, category = "raid damage, raid dot, movement", phase = 1, times = {9.02, 40.02, 64.02, 110.02, 126.04, 157.03, 181.04, 227.03, 243.06, 274.05, 298.04, 344.02}, duration = 4},
        {name = "Abyssal Rain", spellID = 1260837, category = "raid damage, raid dot", phase = 1, times = {11.02, 128.03, 245.05}, duration = 4},
        {name = "Water Jet", spellID = 1281951, category = "tankbuster, tank debuff", phase = 1, times = {20.02, 49.01, 89.02, 137.03, 166.04, 206.03, 254.06, 283.05, 323.03}, duration = 6},
        {name = "Alluring Bubble", spellID = 1257717, category = "add spawn, event", phase = 1, times = {27.02, 144.03, 261.04}, duration = 54},
        {name = "Tidepiercer's Rush", spellID = 1258673, category = "movement", phase = 1, times = {72.02, 189.03, 306.04}, duration = 0},
        {name = "Pop!", spellID = 1258150, category = "raid damage, knock", phase = 1, times = {81.07, 198.09, 315.12}, duration = 0},
        {name = "Unending Tides", spellID = 1295086, category = "raid damage, event", phase = 1, times = {360.05}, duration = 0},
    },
}

NSI.BossTimelines[3379] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
