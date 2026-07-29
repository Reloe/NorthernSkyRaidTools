local _, NSI = ... -- Internal namespace

-- VashnikTheMalignant (3455)

local heroicPhases = {
        [1] = {start = 0},
        [2] = {start = 650},
    }

local heroicAbilities = {
        {name = "Dripping Fangs", spellID = 1280935, category = "tankbuster, tank debuff", phase = 1, times = {10.03, 37.07, 59, 89, 121.08, 143.02, 173.03, 205.09, 227.04, 257.07, 289.14, 311.07, 341.06, 373.12, 395.13, 425.1, 457.13, 479.13, 509.11, 541.17, 563.11, 593.19, 625.21}, duration = 0},
        {name = "Imbibe", spellID = 1284663, category = "raid damage, damage buff", phase = 1, times = {24.03, 108.04, 192.08, 276.07, 360.1, 444.12, 528.11, 612.16}, duration = 0},
        {name = "Malignant Catalyst", spellID = 1282516, category = "raid damage", phase = 1, times = {35.03, 79.03, 119.03, 163.03, 203.07, 247.04, 287.09, 331.06, 371.12, 415.1, 455.11, 499.12, 539.15, 583.15, 623.21}, duration = 0},
        {name = "Siphoning Infection", spellID = 1295224, category = "raid debuff", phase = 1, times = {48.52, 72.52, 102.53, 132.53, 156.53, 186.54, 216.58, 240.56, 270.53, 300.57, 324.55, 354.56, 384.6, 408.62, 438.63, 468.62, 492.64, 522.63, 552.62, 576.67, 606.66, 636.71}, duration = 7},
        {name = "Exploding Infection", spellID = 1295173, category = "raid debuff, spread", phase = 1, times = {48.52, 72.52, 102.53, 132.53, 156.53, 186.54, 216.58, 240.56, 270.53, 300.57, 324.55, 354.56, 384.6, 408.62, 438.63, 468.62, 492.64, 522.63, 552.62, 576.67, 606.66, 636.71}, duration = 10},
        {name = "Stygian Infection", spellID = 1294994, category = "raid debuff", phase = 1, times = {48.52, 72.52, 102.53, 132.53, 156.53, 186.54, 216.58, 240.56, 270.53, 300.57, 324.55, 354.56, 384.6, 408.62, 438.63, 468.62, 492.64, 522.63, 552.62, 576.67, 606.66, 636.71}, duration = 4.5},
        {name = "Empowered Venom", spellID = 1293316, category = "raid damage", phase = 1, times = {46.03, 130.04, 214.08, 298.07, 382.1, 466.12, 550.11, 634.16}, duration = 12},
        {name = "Plague Froth", spellID = 1281907, category = "raid debuff, movement", phase = 1, times = {10.07, 40.06, 61.05, 92.05, 124.07, 145.07, 176.1, 208.1, 229.1, 260.1, 292.12, 313.14, 344.12, 376.14, 397.15, 428.15, 460.18, 481.17, 512.16, 544.18, 565.17, 596.16, 628.18, 649.17}, duration = 6},
    }

local mythicPhases = {
        [1] = {start = 0},
        [2] = {start = 500},
    }

local mythicAbilities = {
        {name = "Dripping Fangs", spellID = 1280935, category = "tankbuster, tank debuff", phase = 1, times = {10.04, 37.1, 62.04, 87.03, 121.1, 146.08, 171.06, 205.13, 230.09, 255.08, 289.14, 314.09, 339.09, 373.16, 398.12, 423.1, 457.16, 484.97}, duration = 0},
        {name = "Imbibe", spellID = 1284663, category = "raid damage, damage buff", phase = 1, times = {24.04, 108.05, 192.08, 276.08, 360.1, 444.11, 462.12, 473.02, 483.59}, duration = 0},
        {name = "Malignant Catalyst", spellID = 1282516, category = "raid damage", phase = 1, times = {35.03, 74.04, 119.07, 158.07, 203.1, 242.09, 287.1, 326.1, 371.12, 410.12, 455.13, 494.12}, duration = 0},
        {name = "Siphoning Infection", spellID = 1295224, category = "raid debuff", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 7},
        {name = "Exploding Infection", spellID = 1295173, category = "raid debuff, spread", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 10},
        {name = "Stygian Infection", spellID = 1294994, category = "raid debuff", phase = 1, times = {42.34, 101.25, 126.29, 185.23, 210.31, 269.46, 294.31, 353.27, 378.44, 437.26, 462.55}, duration = 4.5},
        {name = "Plague Froth", spellID = 1281910, category = "raid debuff, movement", phase = 1, times = {13.03, 54.05, 90.05, 138.08, 174.08, 222.09, 258.08, 306.1, 342.1, 390.12, 426.11, 474.12}, duration = 6},
    }

NSI.BossTimelines[3455] = {
    Heroic = {
        duration = 650,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 500,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
