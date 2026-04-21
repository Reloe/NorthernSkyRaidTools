local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- BELO'REN (3182)
-- Phoenix fight with ~110s cycles, intermissions at Death Drop
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 1, times = {1, 51, 101, 151}, duration = 6},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 1, times = {36}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 1, times = {20, 71, 122, 173}, duration = 0},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 1, times = {21, 39, 71, 89, 121, 139, 171}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 1, times = {25, 43, 75, 93, 125, 143, 175}, duration = 0},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 2, times = {77}, duration = 0},
    {name = "Incubation of Flames", spellID = 1242792, category = "raid damage, event", phase = 2, times = {8}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 2, times = {62, 80, 112, 131, 162, 180}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 2, times = {66, 84, 116, 135, 166, 184}, duration = 0},
    {name = "Voidlight Edict", spellID = 1241678, category = "tankbuster, frontal", phase = 2, times = {70, 88, 120, 139, 170}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 2, times = {83}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 2, times = {62, 112, 162}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 2, times = {42, 92, 142, 192}, duration = 6},
    {name = "Death Drop", spellID = 1246709, category = "raid damage", phase = 2, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 2, times = {0}, duration = 0},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 3, times = {77}, duration = 0},
    {name = "Incubation of Flames", spellID = 1242792, category = "raid damage, event", phase = 3, times = {8}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 3, times = {62, 80, 112, 131, 162, 180}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 3, times = {66, 84, 116, 135, 166, 184}, duration = 0},
    {name = "Voidlight Edict", spellID = 1241678, category = "tankbuster, frontal", phase = 3, times = {70, 88, 120, 139, 170}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 3, times = {83}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 3, times = {62, 112, 162}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 3, times = {42, 92, 142, 192}, duration = 6},
    {name = "Death Drop", spellID = 1246709, category = "raid damage", phase = 3, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 3, times = {0}, duration = 0},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 4, times = {77}, duration = 0},
    {name = "Incubation of Flames", spellID = 1242792, category = "raid damage, event", phase = 4, times = {8}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 4, times = {62, 80, 112, 131, 162, 180}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 4, times = {66, 84, 116, 135, 166, 184}, duration = 0},
    {name = "Voidlight Edict", spellID = 1241678, category = "tankbuster, frontal", phase = 4, times = {70, 88, 120, 139, 170}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 4, times = {83}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 4, times = {62, 112, 162}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 4, times = {42, 92, 142, 192}, duration = 6},
    {name = "Death Drop", spellID = 1246709, category = "raid damage", phase = 4, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 4, times = {0}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 91},
    [3] = {start = 241},
    [4] = {start = 391},
    [5] = {start = 520},
}

local mythicAbilities = {
    {name = "Radiant Echoes", spellID = 1242981, category = "event", phase = 1, times = {7, 57, 107, 157}, duration = 0},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 1, times = {40, 90, 140, 190}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 1, times = {20, 70, 120, 170}, duration = 0},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 1, times = {32, 82, 132}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 1, times = {19, 69, 119, 169}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 1, times = {1, 51, 101, 151}, duration = 6},
    {name = "Radiant Echoes", spellID = 1242981, category = "event", phase = 2, times = {48, 98, 148, 198}, duration = 0},
    {name = "Incubation of Flames", spellID = 1242792, category = "raid damage, event", phase = 2, times = {8}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 2, times = {62, 82, 112, 132, 162}, duration = 0},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 2, times = {77, 127}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 2, times = {66, 86, 116, 136, 166}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 2, times = {83}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "raid damage", phase = 2, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 2, times = {0}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 2, times = {62, 112, 162}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 2, times = {42, 92, 142, 192}, duration = 6},
    {name = "Radiant Echoes", spellID = 1242981, category = "event", phase = 3, times = {48, 98, 148, 198}, duration = 0},
    {name = "Incubation of Flames", spellID = 1242792, category = "raid damage, event", phase = 3, times = {8}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 3, times = {62, 82, 112, 132, 162}, duration = 0},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 3, times = {77, 127}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 3, times = {66, 86, 116, 136, 166}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 3, times = {83}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "raid damage", phase = 3, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 3, times = {0}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 3, times = {62, 112, 162}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 3, times = {42, 92, 142, 192}, duration = 6},
    {name = "Radiant Echoes", spellID = 1242981, category = "event", phase = 4, times = {48, 98, 148, 198}, duration = 0},
    {name = "Incubation of Flames", spellID = 1242792, category = "raid damage, event", phase = 4, times = {8}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 4, times = {62, 82, 112, 132, 162}, duration = 0},
    {name = "Light Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 4, times = {77, 127}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 4, times = {66, 86, 116, 136, 166}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 4, times = {83}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "raid damage", phase = 4, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 4, times = {0}, duration = 0},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 4, times = {62, 112, 162}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 4, times = {42, 92, 142, 192}, duration = 6},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 110},
    [3] = {start = 276},
    [4] = {start = 442},
    [5] = {start = 480},
}

NSI.BossTimelines[3182] = {
    Heroic = {
        duration = 525,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 480,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
