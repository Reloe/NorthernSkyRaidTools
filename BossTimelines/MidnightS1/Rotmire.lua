local _, NSI = ... -- Internal namespace

-- Rotmire (3159)

local heroicData = {
    duration = 600,
    phases = {
        [1] = {start = 0},
        [2] = {start = 600},
    },
    abilities = {
        {name = "Awaken Fungi", spellID = 1221622, category = "add spawn", phase = 1, times = {15, 64, 151, 200, 287, 336, 423, 472, 559}, duration = 0},
        {name = "Shroomling", spellID = 1221639, category = "add spawn", phase = 1, times = {25, 74, 161, 210, 297, 346, 433, 482, 569}, duration = 15},
        {name = "Putrid Fist", spellID = 1221781, category = "tankbuster", phase = 1, times = {26, 38, 50, 62, 75, 87, 99, 111, 162, 174, 186, 198, 211, 223, 235, 247, 298, 310, 322, 334, 347, 359, 371, 383, 434, 446, 458, 470, 483, 495, 507, 519, 570, 582, 594}, duration = 0},
        {name = "Festering Vines", spellID = 1222088, category = "movement", phase = 1, times = {43, 92, 179, 228, 315, 364, 451, 500, 587}, duration = 0},
        {name = "Bursting Pustules", spellID = 1221787, category = "raid aoe", phase = 1, times = {10, 31, 80, 146, 167, 216, 282, 303, 352, 418, 439, 488, 554, 575}, duration = 0},
        {name = "Fungal Bloom", spellID = 1221637, category = "raid aoe", phase = 1, times = {120, 256, 392, 528}, duration = 16},
        {name = "Bursting Shroom", spellID = 1221965, category = "raid aoe", phase = 1, times = {136, 272, 408, 544}, duration = 0},
    },
}

local mythicData = {
    duration = 600,
    phases = {
        [1] = {start = 0},
        [2] = {start = 600},
    },
    abilities = {
        {name = "Awaken Fungi", spellID = 1221622, category = "add spawn", phase = 1, times = {15, 64, 151, 200, 287, 336, 423, 472, 559}, duration = 0},
        {name = "Shroomling", spellID = 1221639, category = "add spawn", phase = 1, times = {25, 74, 161, 210, 297, 346, 433, 482, 569}, duration = 15},
        {name = "Putrid Fist", spellID = 1221781, category = "tankbuster", phase = 1, times = {26, 38, 50, 62, 75, 87, 99, 111, 162, 174, 186, 198, 211, 223, 235, 247, 298, 310, 322, 334, 347, 359, 371, 383, 434, 446, 458, 470, 483, 495, 507, 519, 570, 582, 594}, duration = 0},
        {name = "Festering Vines", spellID = 1222088, category = "movement", phase = 1, times = {43, 92, 179, 228, 315, 364, 451, 500, 587}, duration = 0},
        {name = "Bursting Pustules", spellID = 1221787, category = "raid aoe", phase = 1, times = {10, 31, 80, 146, 167, 216, 282, 303, 352, 418, 439, 488, 554, 575}, duration = 0},
        {name = "Fungal Bloom", spellID = 1221637, category = "raid aoe", phase = 1, times = {120, 256, 392, 528}, duration = 16},
        {name = "Bursting Shroom", spellID = 1221965, category = "raid aoe", phase = 1, times = {136, 272, 408, 544}, duration = 0},
    },
}

NSI.BossTimelines[3159] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
