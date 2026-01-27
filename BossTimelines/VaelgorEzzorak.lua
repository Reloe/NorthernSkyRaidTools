local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- VAELGOR & EZZORAK (3178)
-- Dual-boss fight, Shadowmark phase at ~2:13
--------------------------------------------------------------------------------

local abilities = {
        {name = "Vaelwing", spellID = 1265131, category = "tankbuster, knock", phase = 1, times = {6, 31, 62, 83, 107, 179, 204, 229}, duration = 0},
        {name = "Tail Lash", spellID = 1264467, category = "tankbuster, knock", phase = 1, times = {9, 34, 59, 90}, duration = 0},
        {name = "Rakfang", spellID = 1245645, category = "tankbuster", phase = 1, times = {12, 37, 62, 87, 112, 185, 213}, duration = 0},
        {name = "Impale", spellID = 1265152, category = "tankbuster", phase = 1, times = {140, 165, 190, 218}, duration = 0},
        {name = "Nullbeam", spellID = 1262623, category = "tankbuster", phase = 1, times = {18, 75, 140, 183}, duration = 0},
        {name = "Nullzone", spellID = 1244672, category = "movement, raid damage", phase = 1, times = {22, 79, 144, 187}, duration = 0},
        {name = "Gloom", spellID = 1245391, category = "group soak", phase = 1, times = {41, 91, 189}, duration = 0},
        {name = "Gloomfield", spellID = 1245420, category = "soak", phase = 1, times = {45, 95, 193}, duration = 0},
        {name = "Midnight Manifestation", spellID = 1258744, category = "raid dot", phase = 1, times = {28, 73, 119, 136, 211}, duration = 25},
        {name = "Dread Breath", spellID = 1244221, category = "movement, debuffs", phase = 1, times = {12, 56, 101, 148, 154, 194}, duration = 7},
        {name = "Void Howl", spellID = 1244917, category = "raid damage, movement", phase = 1, times = {28, 73, 119, 136, 211}, duration = 0},
        {name = "Midnight Flames", spellID = 1249748, category = "raid damage, raid dot", phase = 1, times = {133}, duration = 30},
        {name = "Shadowmark", spellID = 1270497, category = "debuffs", phase = 1, times = {133, 139, 145, 151, 157, 163, 169, 175}, duration = 0},
    }

local phases = {
        [1] = {start = 0},
        [2] = {start = 500},
    }

NSI.BossTimelines[3178] = {
    Mythic = {
        duration = 280,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 280,
        phases = phases,
        abilities = abilities,
    },
}
