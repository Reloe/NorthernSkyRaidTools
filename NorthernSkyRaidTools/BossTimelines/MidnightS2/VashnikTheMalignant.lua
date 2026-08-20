local _, NSI = ... -- Internal namespace

-- VashnikTheMalignant (3455)

local heroicData = {
    duration = 650,
    phases = {
        [1] = {start = 0},
        [2] = {start = 650},
    },
    abilities = {
        {name = "Toxic Vapor", spellID = 1284561, category = "ramping rot, raid dot", phase = 1, times = {2}, duration = 648},
        {name = "Dripping Fangs", spellID = 1280935, category = "tankbuster, tank debuff", phase = 1, times = {10.01, 39.04, 66.03, 94.05, 123.05, 150.03, 178.02, 207.05, 234.02, 262.03, 291.08, 318.07, 346.08, 375.11, 402.1, 430.11, 459.13, 486.12, 514.13, 543.12, 570.11, 598.12, 627.17}, duration = 0},
        {name = "Imbibe", spellID = 1284663, category = "event", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Hemo Expulsion", spellID = 1298582, category = "raid damage", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Conflagrating Expulsion", spellID = 1298587, category = "raid damage", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Gloom Expulsion", spellID = 1298583, category = "raid damage", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Burning Presence", spellID = 1305901, category = "raid dot", phase = 1, times = {27.03, 111.04, 195.08, 279.07, 363.1, 447.12, 531.11, 615.16}, duration = 30},
        {name = "Caustic Surge", spellID = 1285979, category = "raid damage, raid dot", phase = 1, times = {46.72, 60.52, 130.73, 144.53, 214.77, 228.57, 298.76, 312.56, 382.79, 396.59, 466.81, 480.61, 550.8, 564.6, 634.85, 648.65}, duration = 3},
        {name = "Malignant Catalyst", spellID = 1282516, category = "raid damage", phase = 1, times = {35.03, 74.04, 119.04, 158.01, 203.03, 242.02, 287.07, 326.07, 371.1, 410.1, 455.12, 494.12, 539.11, 578.11, 623.16}, duration = 0},
        {name = "Siphoning Infection", spellID = 1295224, category = "group soak", phase = 1, times = {42.34, 94.36, 126.43, 178.42, 210.44, 262.44, 294.44, 346.43, 378.47, 430.46, 462.49, 514.48, 546.48, 598.47, 630.53}, duration = 15},
        {name = "Exploding Infection", spellID = 1295173, category = "raid debuff, spread", phase = 1, times = {42.34, 94.36, 126.43, 178.42, 210.44, 262.44, 294.44, 346.43, 378.47, 430.46, 462.49, 514.48, 546.48, 598.47, 630.53}, duration = 0},
        {name = "Caustic Explosion", spellID = 1295209, category = "raid damage", phase = 1, times = {42.34, 94.36, 126.43, 178.42, 210.44, 262.44, 294.44, 346.43, 378.47, 430.46, 462.49, 514.48, 546.48, 598.47, 630.53}, duration = 25},
        {name = "Stygian Infection", spellID = 1294994, category = "raid debuff", phase = 1, times = {42.34, 94.36, 126.43, 178.42, 210.44, 262.44, 294.44, 346.43, 378.47, 430.46, 462.49, 514.48, 546.48, 598.47, 630.53}, duration = 4.5},
        {name = "Plague Froth", spellID = 1281910, category = "raid debuff, movement", phase = 1, times = {13.03, 54.05, 87.05, 138.05, 171, 222.1, 255.07, 306.08, 339.06, 390.11, 423.09, 474.13, 507.11, 558.12, 591.1, 642.17}, duration = 6},
    },
}

local mythicData = {
    duration = 500,
    phases = {
        [1] = {start = 0},
        [2] = {start = 500},
    },
    abilities = {
        {name = "Toxic Vapor", spellID = 1284561, category = "ramping rot, raid dot", phase = 1, times = {2.01}, duration = 498},
        {name = "Dripping Fangs", spellID = 1280935, category = "tankbuster, tank debuff", phase = 1, times = {10.04, 37.1, 62.04, 87.03, 121.1, 146.08, 171.06, 205.13, 230.09, 255.08, 289.14, 314.09, 339.09, 373.16, 398.12, 423.1, 457.16, 484.97}, duration = 0},
        {name = "Imbibe", spellID = 1284663, category = "event", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Hemo Expulsion", spellID = 1298582, category = "raid damage", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Conflagrating Expulsion", spellID = 1298587, category = "raid damage", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Gloom Expulsion", spellID = 1298583, category = "raid damage", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Burning Presence", spellID = 1305901, category = "raid dot", phase = 1, times = {27.04, 111.05, 195.08, 279.08, 363.1, 447.11, 465.12, 476.02, 486.59}, duration = 30},
        {name = "Caustic Surge", spellID = 1285979, category = "raid damage, raid dot", phase = 1, times = {36.04, 45.04, 53.04, 120.05, 129.05, 137.05, 204.08, 213.08, 221.08, 288.08, 297.08, 305.08, 372.1, 381.1, 389.1, 456.11, 465.11, 473.11}, duration = 3},
        {name = "Malignant Catalyst", spellID = 1282516, category = "raid damage", phase = 1, times = {35.03, 74.04, 119.07, 158.07, 203.1, 242.09, 287.1, 326.1, 371.12, 410.12, 455.13, 494.12}, duration = 0},
        {name = "Siphoning Infection", spellID = 1295224, category = "group soak", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 15},
        {name = "Exploding Infection", spellID = 1295173, category = "raid debuff, spread", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 0},
        {name = "Caustic Explosion", spellID = 1295209, category = "raid damage", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 25},
        {name = "Stygian Infection", spellID = 1294994, category = "raid debuff", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 4.5},
        {name = "Plague Froth", spellID = 1281910, category = "raid debuff, movement", phase = 1, times = {13.03, 54.05, 90.05, 138.08, 174.08, 222.09, 258.08, 306.1, 342.1, 390.12, 426.11, 474.12}, duration = 8},
    },
}

NSI.BossTimelines[3455] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
