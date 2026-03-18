local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- BELO'REN (3182)
-- Phoenix fight with ~110s cycles, intermissions at Death Drop
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 1, times = {1}, duration = 6},
    {name = "Holy Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 1, times = {27, 45, 67}, duration = 0},
    {name = "Infused Quills", spellID = 1242260, category = "debuffs", phase = 1, times = {21, 31, 41, 51, 61}, duration = 6},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 1, times = {20}, duration = 8},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 1, times = {21, 46}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 1, times = {26, 51}, duration = 0},
    {name = "Voidlight Edict", spellID = 1241640, category = "tankbuster, frontal", phase = 1, times = {31, 56}, duration = 0},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 2, times = {42}, duration = 6},
    {name = "Incubation of Flames", spellID = 1242792, category = "event", phase = 2, times = {7}, duration = 30},
    {name = "Holy Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 2, times = {68, 86, 108}, duration = 0},
    {name = "Infused Quills", spellID = 1242260, category = "debuffs", phase = 2, times = {62, 72, 82, 92, 102, 112}, duration = 6},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 2, times = {61}, duration = 8},
    {name = "Radiant Echoes", spellID = 1242981, category = "soak, movement", phase = 2, times = {72, 118}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 2, times = {62, 92, 112}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 2, times = {67, 97, 117}, duration = 0},
    {name = "Voidlight Edict", spellID = 1241640, category = "tankbuster, frontal", phase = 2, times = {72, 102}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 2, times = {88}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "raid damage, knock, movement", phase = 2, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 2, times = {0}, duration = 6},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 3, times = {42}, duration = 6},
    {name = "Incubation of Flames", spellID = 1242792, category = "event", phase = 3, times = {7}, duration = 30},
    {name = "Holy Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 3, times = {68, 86, 108}, duration = 0},
    {name = "Infused Quills", spellID = 1242260, category = "debuffs", phase = 3, times = {62, 72, 82, 92, 102, 112}, duration = 6},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 3, times = {61}, duration = 8},
    {name = "Radiant Echoes", spellID = 1242981, category = "soak, movement", phase = 3, times = {72, 118}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 3, times = {62, 92, 112}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 3, times = {67, 97, 117}, duration = 0},
    {name = "Voidlight Edict", spellID = 1241640, category = "tankbuster, frontal", phase = 3, times = {72, 102}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 3, times = {87}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "raid damage, knock, movement", phase = 3, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 3, times = {0}, duration = 6},
    {name = "Voidlight Convergence", spellID = 1242515, category = "raid damage", phase = 4, times = {42}, duration = 6},
    {name = "Incubation of Flames", spellID = 1242792, category = "event", phase = 4, times = {7}, duration = 30},
    {name = "Holy Burn", spellID = 1244348, category = "debuffs, healing absorb", phase = 4, times = {68, 86, 108}, duration = 0},
    {name = "Infused Quills", spellID = 1242260, category = "debuffs", phase = 4, times = {62, 72, 82, 92, 102, 112}, duration = 6},
    {name = "Light Dive", spellID = 1241291, category = "group soak", phase = 4, times = {61}, duration = 8},
    {name = "Radiant Echoes", spellID = 1242981, category = "soak, movement", phase = 4, times = {72, 118}, duration = 30},
    {name = "Light Edict", spellID = 1261217, category = "tankbuster, frontal", phase = 4, times = {62, 92, 112}, duration = 0},
    {name = "Void Edict", spellID = 1261218, category = "tankbuster, frontal", phase = 4, times = {67, 97, 117}, duration = 0},
    {name = "Voidlight Edict", spellID = 1241640, category = "tankbuster, frontal", phase = 4, times = {72, 102}, duration = 0},
    {name = "Guardian's Edict", spellID = 1260826, category = "tankbuster, frontal", phase = 4, times = {87}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "raid damage, knock, movement", phase = 4, times = {6}, duration = 0},
    {name = "Death Drop", spellID = 1246709, category = "movement", phase = 4, times = {0}, duration = 6},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 90},
    [3] = {start = 240},
    [4] = {start = 390},
    [5] = {start = 520},
}

-- Mythic data is identical to Heroic for this encounter
local mythicAbilities = heroicAbilities
local mythicPhases = heroicPhases

NSI.BossTimelines[3182] = {
    Heroic = {
        duration = 525,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 525,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
