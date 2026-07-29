local _, NSI = ... -- Internal namespace

-- NymrissaWavecaller (3379)

local heroicPhases = {
        [1] = {start = 0},
        [2] = {start = 420},
    }

local heroicAbilities = {
        {name = "Abyssal Rain", spellID = 1260837, category = "raid damage, raid dot", phase = 1, times = {5.01, 122.03, 239.04}, duration = 4},
        {name = "Water Flurry", spellID = 1282937, category = "tankbuster, tank debuff", phase = 1, times = {16.02, 46.01, 95.02, 133.02, 163.02, 212.02, 250.04, 280.02, 329.03}, duration = 6},
        {name = "Alluring Bubble", spellID = 1257717, category = "add spawn, event", phase = 1, times = {27.01, 144.03, 261.05}, duration = 50},
        {name = "Frost Barrage", spellID = 1257614, category = "raid damage, raid dot, movement", phase = 1, times = {35.02, 55.03, 106.03, 152.01, 172.02, 223.03, 269.03, 289.03, 340.04}, duration = 4},
        {name = "Tidepiercer's Rush", spellID = 1258673, category = "movement, raid damage", phase = 1, times = {68.01, 185.02, 302.04}, duration = 0},
        {name = "Pop!", spellID = 1258150, category = "raid damage, knock", phase = 1, times = {77.02, 194.02, 311.05}, duration = 0},
        {name = "Unending Tides", spellID = 1295086, category = "event, raid damage", phase = 1, times = {360.05}, duration = 0},
    }

local mythicPhases = {
        [1] = {start = 0},
        [2] = {start = 420},
    }

local mythicAbilities = {
        {name = "Frost Barrage", spellID = 1257614, category = "raid damage, raid dot, movement", phase = 1, times = {5.02, 36.02, 60.02, 106.02, 122.04, 153.03, 177.04, 223.03, 239.06, 270.05, 294.04, 340.02}, duration = 4},
        {name = "Abyssal Rain", spellID = 1260837, category = "raid damage, raid dot", phase = 1, times = {11.02, 128.03, 245.05}, duration = 4},
        {name = "Water Jet", spellID = 1281951, category = "tankbuster, tank debuff", phase = 1, times = {20.02, 49.01, 89.02, 137.03, 166.04, 206.03, 254.06, 283.05, 323.03}, duration = 6},
        {name = "Alluring Bubble", spellID = 1257717, category = "add spawn, event", phase = 1, times = {27.02, 144.03, 261.04}, duration = 54},
        {name = "Tidepiercer's Rush", spellID = 1258673, category = "movement, raid damage", phase = 1, times = {72.02, 189.03, 306.04}, duration = 0},
        {name = "Pop!", spellID = 1258150, category = "raid damage, knock", phase = 1, times = {81.07, 198.09, 315.12}, duration = 0},
        {name = "Unending Tides", spellID = 1295086, category = "event, raid damage", phase = 1, times = {360.05}, duration = 0},
    }

NSI.BossTimelines[3379] = {
    Heroic = {
        duration = 420,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 420,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
