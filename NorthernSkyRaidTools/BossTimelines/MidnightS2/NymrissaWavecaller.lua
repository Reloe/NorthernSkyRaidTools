local _, NSI = ... -- Internal namespace

-- NymrissaWavecaller (3379)

local heroicData = {
    duration = 550,
    phases = {
        [1] = {start = 0},
        [2] = {start = 550},
    },
    abilities = {
        {name = "Abyssal Rain", spellID = 1260837, category = "raid damage, raid dot", phase = 1, times = {10, 43, 87, 153, 197, 263.03, 307.02, 373.03, 417.04, 483.05, 527.06}, duration = 4},
        {name = "Iceblade Flurry", spellID = 1282937, category = "tankbuster, tank debuff", phase = 1, times = {29.01, 51, 72.99, 94.99, 139, 161, 183, 205.01, 249.03, 271.03, 293.04, 315.03, 359.04, 381.04, 403.05, 425.03, 469.06, 491.06, 513.07, 535.05}, duration = 5},
        {name = "Chilling Frost", spellID = 1313393, category = "raid damage, raid dot, movement", phase = 1, times = {37.01, 81, 146.99, 191, 257.03, 301.03, 367.03, 411.01, 477.05, 521.03}, duration = 6},
        {name = "Frost Orb", spellID = 1313448, category = "raid damage, soak, raid dot", phase = 1, times = {43, 87, 153, 197, 263.03, 307.02, 373.03, 417.04, 483.05, 527.06}, duration = 20},
        {name = "Swirling Whirlpools", spellID = 1258673, category = "movement", phase = 1, times = {110.96, 221, 331.02, 441.03}, duration = 0},
        {name = "Pop!", spellID = 1258150, category = "raid damage, knock", phase = 1, times = {119.96, 230.01, 340.03, 450.05}, duration = 0},
    },
}

local mythicData = {
    duration = 550,
    phases = {
        [1] = {start = 0},
        [2] = {start = 550},
    },
    abilities = {
        {name = "Abyssal Rain", spellID = 1260837, category = "raid damage, raid dot", phase = 1, times = {10, 43, 87, 153, 197, 263.03, 307.02, 373.03, 417.04, 483.05, 527.06}, duration = 4},
        {name = "Water Jet", spellID = 1281951, category = "tankbuster, tank debuff", phase = 1, times = {30.01, 52, 73.99, 95.99, 140, 162, 184, 206.01, 250.03, 272.03, 294.04, 316.03, 360.04, 382.04, 404.05, 426.03, 470.06, 492.06, 514.07, 536.05}, duration = 6},
        {name = "Chilling Frost", spellID = 1313393, category = "raid damage, raid dot, movement", phase = 1, times = {38.07, 82.06, 148.05, 192.06, 258.09, 302.09, 368.09, 412.07, 478.11, 522.09}, duration = 6},
        {name = "Frost Orb", spellID = 1313448, category = "raid damage, soak, raid dot", phase = 1, times = {44.07, 88.06, 154.05, 198.06, 264.09, 308.09, 374.09, 418.07, 484.11, 528.09}, duration = 20},
        {name = "Swirling Whirlpools", spellID = 1258673, category = "movement", phase = 1, times = {110.96, 221, 331.02, 441.03}, duration = 0},
        {name = "Pop!", spellID = 1258150, category = "raid damage, knock", phase = 1, times = {119.96, 230.01, 340.03, 450.05}, duration = 0},
    },
}

NSI.BossTimelines[3379] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
