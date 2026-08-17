local _, NSI = ... -- Internal namespace

-- TheCoiledAltar (3429)

local heroicData = {
    duration = 607,
    phases = {
        [1] = {start = 0},
        [2] = {start = 164},
        [2.5] = {start = 392},
        [3] = {start = 427},
        [4] = {start = 607},
    },
    abilities = {
        {name = "Coalesced Venom", spellID = 1282408, category = "raid damage, raid dot", phase = 1, times = {7.09}, duration = 233},
        {name = "Fangs of the Crucible", spellID = 1282487, category = "raid damage", phase = 1, times = {0.06, 80.05, 160.05}, duration = 8},
        {name = "Toxic Deluge", spellID = 1299960, category = "movement", phase = 1, times = {5.05, 48.05, 85.06, 128.09, 165.09, 208.08}, duration = 0},
        {name = "Axegrinder", spellID = 1283832, category = "event", phase = 1, times = {14.03, 94.02, 174.06}, duration = 0},
        {name = "Sever", spellID = 1299684, category = "raid damage, tank debuff, frontal", phase = 1, times = {23.01, 40.01, 60, 77.03, 103.06, 120.07, 140.04, 157.06, 183.08, 200.08, 220.06, 237.08}, duration = 0},
        {name = "Venomfang", spellID = 1282287, category = "raid debuff", phase = 1, times = {30.03, 65, 110.02, 145.02, 190.08, 225.04}, duration = 0},
        {name = "Guillotine", spellID = 1283489, category = "group soak", phase = 1, times = {46.48, 126.54, 206.55}, duration = 0},
        {name = "Dreadful Presence", spellID = 1288635, category = "raid dot", phase = 2, times = {2}, duration = 318},
        {name = "Dreadful Presence", spellID = 1288624, category = "phase change", phase = 2, times = {0}, duration = 0},
        {name = "Dreadmarch", spellID = 1285643, category = "cc, add spawn", phase = 2, times = {7.55, 43.62, 92.55, 128.58, 177.6, 213.63}, duration = 0},
        {name = "Spiritcackle", spellID = 1286441, category = "add spawn", phase = 2, times = {13.03, 46.01, 98.05, 131.08, 183.07, 216.08}, duration = 0},
        {name = "Gloombomb", spellID = 1286895, category = "spread", phase = 2, times = {24.04, 62.01, 109.07, 147.08, 194.1, 232.09}, duration = 5},
        {name = "Soul Sever", spellID = 1286620, category = "tank debuff, frontal", phase = 2, times = {38.04, 69.01, 123.07, 154.05, 208.1, 239.1}, duration = 0},
        {name = "Retaliatory Malice", spellID = 1308311, category = "raid damage", phase = 2, times = {17.57, 50.55, 102.57, 135.57, 187.6, 220.6}, duration = 0},
        {name = "Spirit Erasure", spellID = 1287722, category = "raid damage", phase = 2.5, times = {0}, duration = 35},
        {name = "Ghastly Regeneration", spellID = 1304033, category = "damage buff", phase = 2.5, times = {0.17}, duration = 0},
        {name = "Coalesced Venom", spellID = 1282408, category = "raid damage, raid dot", phase = 3, times = {9.99}, duration = 170},
        {name = "Defilement of the Coiled Altar", spellID = 1298381, category = "raid damage", phase = 3, times = {2.62, 96.47}, duration = 0},
        {name = "Toxic Deluge", spellID = 1299960, category = "movement", phase = 3, times = {8.07, 49.83, 100.69, 137.67}, duration = 0},
        {name = "Grim Guillotine", spellID = 1299266, category = "group soak", phase = 3, times = {17.95, 76.49, 135.34}, duration = 0},
        {name = "Gloombomb", spellID = 1286895, category = "spread", phase = 3, times = {26.85, 85.54, 144.34}, duration = 5},
        {name = "Blighted Sever", spellID = 1307292, category = "raid damage, tank debuff, frontal", phase = 3, times = {34.97, 64.19, 94.77, 127.94, 157.42}, duration = 0},
        {name = "Eternal Nightfall", spellID = 1286918, category = "event", phase = 3, times = {37.91, 126.13}, duration = 0},
        {name = "Dreadmarch", spellID = 1285643, category = "cc, add spawn", phase = 3, times = {70.22, 149.33}, duration = 0},
    },
}

local mythicData = {
    duration = 571,
    phases = {
        [1] = {start = 0},
        [2] = {start = 186},
        [2.5] = {start = 356},
        [3] = {start = 391},
        [4] = {start = 571},
    },
    abilities = {
        {name = "Coalesced Venom", spellID = 1282408, category = "raid damage, raid dot", phase = 1, times = {7.05}, duration = 248},
        {name = "Fangs of the Crucible", spellID = 1282487, category = "raid damage", phase = 1, times = {0.05, 85.03, 170.06}, duration = 8},
        {name = "Toxic Deluge", spellID = 1299960, category = "movement", phase = 1, times = {5.12, 48.09, 90.07, 133.1, 175.11, 218.1}, duration = 0},
        {name = "Axegrinder", spellID = 1283832, category = "event", phase = 1, times = {14.04, 99.04, 184.06}, duration = 0},
        {name = "Sever", spellID = 1299684, category = "raid damage, tank debuff, frontal", phase = 1, times = {23.04, 40.04, 60.03, 77.03, 108.05, 125.04, 145.05, 162.04, 193.07, 210.07, 230.07, 247.06}, duration = 0},
        {name = "Venomfang", spellID = 1282287, category = "raid debuff", phase = 1, times = {30.03, 65.02, 115.04, 150.04, 200.06, 235.06}, duration = 0},
        {name = "Guillotine", spellID = 1283489, category = "group soak", phase = 1, times = {46.53, 131.53, 216.55}, duration = 0},
        {name = "Dreadful Presence", spellID = 1288635, category = "raid dot", phase = 2, times = {2}, duration = 318},
        {name = "Dreadful Presence", spellID = 1288624, category = "phase change", phase = 2, times = {0}, duration = 0},
        {name = "Dreadmarch", spellID = 1285643, category = "cc, add spawn", phase = 2, times = {7.52, 44.09, 92.52, 129.09}, duration = 0},
        {name = "Spiritcackle", spellID = 1286441, category = "add spawn", phase = 2, times = {13.02, 46.01, 98.02, 131.01}, duration = 0},
        {name = "Retaliatory Malice", spellID = 1308311, category = "raid damage", phase = 2, times = {17.55, 50.55, 102.55, 135.55}, duration = 0},
        {name = "Gloombomb", spellID = 1286895, category = "spread", phase = 2, times = {20.03, 58, 105.03, 143}, duration = 5},
        {name = "Soul Sever", spellID = 1286620, category = "tank debuff, frontal", phase = 2, times = {38.03, 69, 123.03, 154}, duration = 0},
        {name = "Spirit Erasure", spellID = 1287722, category = "raid damage", phase = 2.5, times = {0}, duration = 35},
        {name = "Ghastly Regeneration", spellID = 1304033, category = "damage buff", phase = 2.5, times = {0.17}, duration = 0},
        {name = "Defilement of the Coiled Altar", spellID = 1298381, category = "raid damage", phase = 3, times = {2.62, 96.47}, duration = 0},
        {name = "Toxic Deluge", spellID = 1299960, category = "movement", phase = 3, times = {8.07, 49.83, 100.69, 137.67}, duration = 0},
        {name = "Grim Guillotine", spellID = 1299266, category = "group soak", phase = 3, times = {17.95, 76.49, 135.34}, duration = 0},
        {name = "Gloombomb", spellID = 1286895, category = "spread", phase = 3, times = {26.85, 85.54, 144.34}, duration = 5},
        {name = "Blighted Sever", spellID = 1307292, category = "raid damage, tank debuff, frontal", phase = 3, times = {34.97, 64.19, 94.77, 127.94, 157.42}, duration = 0},
        {name = "Eternal Nightfall", spellID = 1286918, category = "event", phase = 3, times = {37.91, 126.13}, duration = 0},
        {name = "Dreadmarch", spellID = 1285643, category = "cc, add spawn", phase = 3, times = {70.22, 149.33}, duration = 0},
    },
}

NSI.BossTimelines[3429] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
