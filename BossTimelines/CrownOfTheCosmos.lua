local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- CROWN OF THE COSMOS (3181)
-- Multi-phase fight with Silversunder Catastrophe intermissions
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Null Corona", spellID = 1233865, category = "healing absorb", phase = 1, times = {4, 48, 96, 123}, duration = 0},
    {name = "Dark Hand", spellID = 1233787, category = "tankbuster", phase = 1, times = {7, 33}, duration = 0},
    {name = "Interrupting Tremor", spellID = 1243743, category = "event", phase = 1, times = {10, 31, 51, 71, 91}, duration = 0},
    {name = "Grasp of Emptiness", spellID = 1232467, category = "debuffs", phase = 1, times = {7, 35, 67, 99, 127}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "raid damage", phase = 1, times = {23, 28, 71, 76, 110, 115, 143, 148}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "movement", phase = 1, times = {12, 60, 99, 132}, duration = 0},
    {name = "Silverstrike Arrow", spellID = 1233602, category = "debuffs", phase = 1, times = {24, 45, 68, 91, 112}, duration = 6},
    {name = "Silversunder Catastrophe", spellID = 1234546, category = "raid damage", phase = 2, times = {7, 12, 15, 21, 24}, duration = 0},
    {name = "Null Corona", spellID = 1233865, category = "healing absorb", phase = 3, times = {17, 59, 101, 143, 185}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "raid damage", phase = 3, times = {28, 33, 49, 54, 70, 75, 90, 95, 112, 117, 132, 137, 154, 159, 174, 179, 196, 201}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "movement", phase = 3, times = {17, 37, 59, 79, 101, 121, 143, 163, 185}, duration = 0},
    {name = "Voidstalker Sting", spellID = 1237035, category = "raid dot", phase = 3, times = {9, 51, 93, 135, 177}, duration = 30},
    {name = "Rift Slash", spellID = 1246461, category = "add spawn", phase = 3, times = {11, 23, 35, 47, 59, 72, 84, 96, 108, 120, 132, 145, 157, 169, 181, 193}, duration = 0},
    {name = "Call of the Void", spellID = 1237837, category = "add spawn", phase = 3, times = {15, 57, 99, 141, 183}, duration = 0},
    {name = "Ranger Captain's Mark", spellID = 1237614, category = "raid damage", phase = 3, times = {24, 43, 66, 85, 108, 127, 150, 169, 192}, duration = 0},
    {name = "Cosmic Barrier", spellID = 1246918, category = "raid damage", phase = 3, times = {28, 70, 112, 154}, duration = 25},
    {name = "Silversunder Catastrophe", spellID = 1234546, category = "raid damage", phase = 4, times = {6, 16, 19}, duration = 0},
    {name = "Null Corona", spellID = 1233865, category = "healing absorb", phase = 5, times = {33, 93, 153}, duration = 0},
    {name = "Grasp of Emptiness", spellID = 1232467, category = "debuffs", phase = 5, times = {10, 17, 37, 54, 70, 77, 97, 114, 130, 137, 157, 174, 190, 199}, duration = 0},
    {name = "Voidstalker Sting", spellID = 1237035, category = "raid dot", phase = 5, times = {16, 34, 46, 60, 76, 94, 106, 120, 136, 154, 166, 180}, duration = 0},
    {name = "Aspect of the End", spellID = 1239080, category = "raid damage", phase = 5, times = {13, 52, 73, 112, 133, 172}, duration = 8},
    {name = "Devouring Cosmos", spellID = 1238843, category = "movement", phase = 5, times = {65, 125, 185}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 129},
    [3] = {start = 161},
    [4] = {start = 371},
    [5] = {start = 394},
    [6] = {start = 589},
}

local mythicAbilities = {
    {name = "Null Corona", spellID = 1233865, category = "healing absorb", phase = 1, times = {3, 40, 80}, duration = 0},
    {name = "Grasp of Emptiness", spellID = 1232467, category = "debuffs", phase = 1, times = {5, 28, 55, 81}, duration = 0},
    {name = "Interrupting Tremor", spellID = 1243743, category = "event", phase = 1, times = {10, 30, 50}, duration = 0},
    {name = "Dark Hand", spellID = 1233787, category = "tankbuster", phase = 1, times = {7, 48, 75, 102}, duration = 0},
    {name = "Silverstrike Arrow", spellID = 1233602, category = "debuffs", phase = 1, times = {20, 38, 57, 76, 93, 120}, duration = 6},
    {name = "Void Expulsion", spellID = 1233819, category = "raid damage", phase = 1, times = {21, 27, 61, 67, 94, 100, 121, 127}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "movement", phase = 1, times = {13, 53, 86, 113}, duration = 0},
    {name = "Silversunder Catastrophe", spellID = 1234546, category = "raid damage", phase = 2, times = {6, 12, 18, 24}, duration = 0},
    {name = "Call of the Void", spellID = 1237837, category = "add spawn", phase = 3, times = {9, 61, 113}, duration = 0},
    {name = "Rift Slash", spellID = 1246461, category = "tankbuster", phase = 3, times = {9, 19, 31, 43, 59, 71, 83, 95, 111}, duration = 0},
    {name = "Voidstalker Sting", spellID = 1237035, category = "raid dot", phase = 3, times = {13, 38, 65, 90, 116}, duration = 30},
    {name = "Void Expulsion", spellID = 1233819, category = "raid damage", phase = 3, times = {32, 38, 57, 63, 84, 90, 109, 115, 136, 142}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "movement", phase = 3, times = {24, 49, 76, 101, 128}, duration = 0},
    {name = "Grasp of Emptiness", spellID = 1232467, category = "debuffs", phase = 3, times = {14, 39, 66, 91, 118}, duration = 0},
    {name = "Ranger Captain's Mark", spellID = 1237614, category = "debuffs", phase = 3, times = {28, 53, 80, 105}, duration = 6},
    {name = "Ranger Captain's Mark", spellID = 1237614, category = "raid damage", phase = 3, times = {34, 59, 86, 111}, duration = 0},
    {name = "Cosmic Barrier", spellID = 1246918, category = "raid damage", phase = 3, times = {3}, duration = 20},
    {name = "Aspect of the End", spellID = 1239080, category = "raid damage", phase = 5, times = {9, 50, 69, 110, 129, 170, 189}, duration = 8},
    {name = "Devouring Cosmos", spellID = 1238843, category = "movement", phase = 5, times = {64, 124, 184}, duration = 0},
    {name = "Null Corona", spellID = 1233865, category = "healing absorb", phase = 5, times = {31, 91, 151}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "raid damage", phase = 5, times = {48, 54, 108, 114, 168, 174}, duration = 0},
    {name = "Void Expulsion", spellID = 1233819, category = "movement", phase = 5, times = {40, 100, 160}, duration = 0},
    {name = "Grasp of Emptiness", spellID = 1232467, category = "debuffs", phase = 5, times = {10, 20, 55, 71, 80, 115, 131, 140, 175, 191, 200}, duration = 0},
    {name = "Voidstalker Sting", spellID = 1237035, category = "raid dot", phase = 5, times = {16, 33, 45, 59, 76, 93, 105, 119, 136, 153, 165, 179, 196}, duration = 0},
    {name = "Cosmic Barrier", spellID = 1246918, category = "raid damage", phase = 5, times = {13, 73, 133, 193}, duration = 25},
    {name = "Interrupting Tremor", spellID = 1243743, category = "event", phase = 5, times = {90, 107}, duration = 0},
    {name = "Dark Hand", spellID = 1233787, category = "tankbuster", phase = 5, times = {159, 176}, duration = 0},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 138},
    [3] = {start = 171},
    [4] = {start = 310},
    [5] = {start = 325},
    [6] = {start = 552},
}

NSI.BossTimelines[3181] = {
    Heroic = {
        duration = 600,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 557,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
