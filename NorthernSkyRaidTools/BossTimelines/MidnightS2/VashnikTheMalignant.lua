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
        {name = "Dripping Fangs", spellID = 1280935, category = "tankbuster, tank debuff", phase = 1, times = {10.03, 37.07, 59, 89, 121.08, 143.02, 173.03, 205.09, 227.04, 257.07, 289.14, 311.07, 341.06, 373.12, 395.13, 425.1, 457.13, 479.13, 509.11, 541.17, 563.11, 593.19, 625.21}, duration = 0},
        {name = "Imbibe", spellID = 1284663, category = "damage buff", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Hemo Expulsion", spellID = 1298582, category = "raid damage", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Conflagrating Expulsion", spellID = 1298587, category = "raid damage", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Gloom Expulsion", spellID = 1298583, category = "raid damage", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Burning Presence", spellID = 1305901, category = "raid dot", phase = 1, times = {27.03, 111.04, 195.08, 279.07, 363.1, 447.12, 531.11, 615.16}, duration = 30},
        {name = "Caustic Surge", spellID = 1285979, category = "raid damage, raid dot", phase = 1, times = {36.03, 45.03, 53.03, 120.04, 129.04, 137.04, 204.08, 213.08, 221.08, 288.07, 297.07, 305.07, 372.1, 381.1, 389.1, 456.12, 465.12, 473.12, 540.11, 549.11, 557.11, 624.16, 633.16, 641.16}, duration = 3},
        {name = "Malignant Catalyst", spellID = 1282516, category = "raid damage", phase = 1, times = {35.03, 79.03, 119.03, 163.03, 203.07, 247.04, 287.09, 331.06, 371.12, 415.1, 455.11, 499.12, 539.15, 583.15, 623.21}, duration = 0},
        {name = "Siphoning Infection", spellID = 1295224, category = "raid debuff", phase = 1, times = {48.52, 72.52, 102.53, 132.53, 156.53, 186.54, 216.58, 240.56, 270.53, 300.57, 324.55, 354.56, 384.6, 408.62, 438.63, 468.62, 492.64, 522.63, 552.62, 576.67, 606.66, 636.71}, duration = 15},
        {name = "Exploding Infection", spellID = 1295173, category = "raid debuff, spread", phase = 1, times = {48.52, 72.52, 102.53, 132.53, 156.53, 186.54, 216.58, 240.56, 270.53, 300.57, 324.55, 354.56, 384.6, 408.62, 438.63, 468.62, 492.64, 522.63, 552.62, 576.67, 606.66, 636.71}, duration = 10},
        {name = "Stygian Infection", spellID = 1294994, category = "raid debuff", phase = 1, times = {48.52, 72.52, 102.53, 132.53, 156.53, 186.54, 216.58, 240.56, 270.53, 300.57, 324.55, 354.56, 384.6, 408.62, 438.63, 468.62, 492.64, 522.63, 552.62, 576.67, 606.66, 636.71}, duration = 4.5},
        {name = "Plague Froth", spellID = 1281907, category = "raid debuff, movement", phase = 1, times = {10.07, 40.06, 61.05, 92.05, 124.07, 145.07, 176.1, 208.1, 229.1, 260.1, 292.12, 313.14, 344.12, 376.14, 397.15, 428.15, 460.18, 481.17, 512.16, 544.18, 565.17, 596.16, 628.18, 649.17}, duration = 6},
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
        {name = "Imbibe", spellID = 1284663, category = "damage buff", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Hemo Expulsion", spellID = 1298582, category = "raid damage", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Conflagrating Expulsion", spellID = 1298587, category = "raid damage", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Gloom Expulsion", spellID = 1298583, category = "raid damage", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Burning Presence", spellID = 1305901, category = "raid dot", phase = 1, times = {27.04, 111.05, 195.08, 279.08, 363.1, 447.11, 465.12, 476.02, 486.59}, duration = 30},
        {name = "Caustic Surge", spellID = 1285979, category = "raid damage, raid dot", phase = 1, times = {36.04, 45.04, 53.04, 120.05, 129.05, 137.05, 204.08, 213.08, 221.08, 288.08, 297.08, 305.08, 372.1, 381.1, 389.1, 456.11, 465.11, 473.11}, duration = 3},
        {name = "Malignant Catalyst", spellID = 1282516, category = "raid damage", phase = 1, times = {35.03, 74.04, 119.07, 158.07, 203.1, 242.09, 287.1, 326.1, 371.12, 410.12, 455.13, 494.12}, duration = 0},
        {name = "Siphoning Infection", spellID = 1295224, category = "raid debuff", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 15},
        {name = "Exploding Infection", spellID = 1295173, category = "raid debuff, spread", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 10},
        {name = "Stygian Infection", spellID = 1294994, category = "raid debuff", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 4.5},
        {name = "Plague Froth", spellID = 1281910, category = "raid debuff, movement", phase = 1, times = {13.03, 54.05, 90.05, 138.08, 174.08, 222.09, 258.08, 306.1, 342.1, 390.12, 426.11, 474.12}, duration = 8},
    },
}

NSI.BossTimelines[3455] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
