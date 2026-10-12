local _, NSI = ... -- Internal namespace

-- Kith'ix (3513)

local heroicData = {
    duration = 360,
    phases = {
        [1] = {start = 0},
        [2] = {start = 210},
        [3] = {start = 360},
    },
    abilities = {
        {name = "Voidswarm", spellID = 1301511, category = "raid aoe, add spawn", phase = 1, times = {5, 114, 223, 332}, duration = 6},
        {name = "Voidweave", spellID = 1302333, category = "raid dot", phase = 1, times = {12.5, 121.5, 230.5, 339.5}, duration = 24},
        {name = "Digestive Juices", spellID = 1302319, category = "raid dot", phase = 1, times = {13.27, 122.27, 231.27, 340.27}, duration = 20},
        {name = "Venom Roar", spellID = 1302884, category = "frontal", phase = 1, times = {19.55, 35.3, 128.55, 144.3, 237.55, 253.3, 346.55, 362.3}, duration = 0},
        {name = "Dark Devastation", spellID = 1304930, category = "tankbuster", phase = 1, times = {26, 46, 66, 135, 155, 175, 244, 264, 284, 353, 373, 393}, duration = 0},
        {name = "Extinguish", spellID = 1304424, category = "raid aoe", phase = 1, times = {37.01, 94.01, 146.01, 203.01, 255.01, 312.01, 364.01, 421.01}, duration = 0},
        {name = "Unspeakable Horrors", spellID = 1304045, category = "raid damage, dispel", phase = 1, times = {43, 76, 152, 185, 261, 294, 370, 403}, duration = 6},
        {name = "Nightfall", spellID = 1302705, category = "raid aoe, raid dot", phase = 1, times = {42.2, 151.2, 260.2, 369.2}, duration = 8},
        {name = "Suffocating Darkness", spellID = 1302951, category = "raid aoe, raid dot", phase = 1, times = {57, 166, 275, 384}, duration = 44},
        {name = "Abyssal Grasp", spellID = 1303406, category = "healing absorb", phase = 1, times = {62.01, 89, 171.01, 198, 280.01, 307, 389.01, 416}, duration = 8},
        {name = "Divine Radiance", spellID = 1303169, category = "event", phase = 1, times = {101.01, 210.01, 319.01, 428.01}, duration = 0},
        {name = "Last Light", spellID = 1305427, category = "damage buff", phase = 2, times = {0}, duration = 0},
        {name = "Eightfold Eclipse", spellID = 1301479, category = "phase change", phase = 2, times = {1}, duration = 0},
        {name = "Eightfold Eclipse", spellID = 1301479, category = "raid aoe", phase = 2, times = {2.06, 10.7, 19.32, 27.95, 36.6, 45.26, 53.88, 62.55, 71.19, 79.83, 88.47, 97.11, 105.75, 114.39, 123.03, 131.67, 140.31, 148.95}, duration = 0},
        {name = "Null Gate", spellID = 1308873, category = "debuffs, movement", phase = 2, times = {4.01, 12.01, 20.01, 28.01, 36.01, 44.01, 52.01, 60.01, 68.01, 76.01, 84.01, 92.01, 100.01, 108.01, 116.01, 124.01, 132.01, 140.01, 148.01}, duration = 5},
        {name = "Negation", spellID = 1318467, category = "tank debuff", phase = 2, times = {13.02, 28.02, 43.02, 58.02, 73.02, 88.02, 103.02, 118.02, 133.02, 148.02}, duration = 8},
    },
}

local mythicData = {
    duration = 420,
    phases = {
        [1] = {start = 0},
        [2] = {start = 300},
        [3] = {start = 420},
    },
    abilities = {
        {name = "Voidswarm", spellID = 1301511, category = "raid aoe, add spawn", phase = 1, times = {5, 114, 223, 332}, duration = 6},
        {name = "Voidweave", spellID = 1302333, category = "raid dot", phase = 1, times = {12.5, 121.5, 230.5, 339.5}, duration = 24},
        {name = "Digestive Juices", spellID = 1302319, category = "raid dot", phase = 1, times = {13.27, 122.27, 231.27, 340.27}, duration = 20},
        {name = "Venom Roar", spellID = 1302884, category = "frontal", phase = 1, times = {19.55, 35.3, 51.8, 68.1, 128.55, 144.3, 160.8, 177.1, 237.55, 253.3, 269.8, 286.1, 346.55, 362.3, 378.8, 395.1}, duration = 0},
        {name = "Dark Devastation", spellID = 1304930, category = "tankbuster", phase = 1, times = {23, 43, 66, 132, 152, 175, 241, 261, 284, 350, 370, 393}, duration = 0},
        {name = "Extinguish", spellID = 1304424, category = "raid aoe", phase = 1, times = {37.01, 79.01, 146.01, 188.01, 255.01, 297.01, 364.01, 406.01}, duration = 0},
        {name = "Unspeakable Horrors", spellID = 1304045, category = "raid damage, dispel", phase = 1, times = {43, 90, 152, 199, 261, 308, 370, 417}, duration = 6},
        {name = "Nightfall", spellID = 1302705, category = "raid aoe, raid dot", phase = 1, times = {42.2, 151.2, 260.2, 369.2}, duration = 8},
        {name = "Suffocating Darkness", spellID = 1302951, category = "raid aoe, raid dot", phase = 1, times = {57, 166, 275, 384}, duration = 44},
        {name = "Abyssal Grasp", spellID = 1303406, category = "healing absorb", phase = 1, times = {62.01, 89, 171.01, 198, 280.01, 307, 389.01, 416}, duration = 8},
        {name = "Divine Radiance", spellID = 1303169, category = "event", phase = 1, times = {101.01, 210.01, 319.01, 428.01}, duration = 0},
        {name = "Last Light", spellID = 1305427, category = "damage buff", phase = 2, times = {0}, duration = 0},
        {name = "Eightfold Eclipse", spellID = 1301479, category = "phase change", phase = 2, times = {1}, duration = 0},
        {name = "Eightfold Eclipse", spellID = 1301479, category = "raid aoe", phase = 2, times = {2.06, 10.7, 19.32, 27.95, 36.6, 45.26, 53.88, 62.55, 71.19, 79.83, 88.47, 97.11, 105.75, 114.39, 123.03, 131.67, 140.31, 148.95}, duration = 0},
        {name = "Null Gate", spellID = 1308873, category = "debuffs, movement", phase = 2, times = {4.01, 12.01, 20.01, 28.01, 36.01, 44.01, 52.01, 60.01, 68.01, 76.01, 84.01, 92.01, 100.01, 108.01, 116.01, 124.01, 132.01, 140.01, 148.01}, duration = 5},
        {name = "Negation", spellID = 1318467, category = "tank debuff", phase = 2, times = {13.02, 28.02, 43.02, 58.02, 73.02, 88.02, 103.02, 118.02, 133.02, 148.02}, duration = 12},
    },
}

NSI.BossTimelines[3513] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
