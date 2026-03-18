local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- LIGHTBLINDED VANGUARD (3180)
-- Single phase, Tyr's Wrath bursts of 4
--------------------------------------------------------------------------------

local heroicAbilities = {
    {name = "Avenger's Shield", spellID = 1246497, category = "debuffs", phase = 1, times = {20, 85, 110, 122, 142, 162, 182, 202, 255, 277, 294, 319, 334, 356, 376, 430, 470}, duration = 0},
    {name = "Judgment", spellID = 1251857, category = "tankbuster", phase = 1, times = {29, 33, 71, 75, 113, 115, 127, 131, 151, 155, 171, 175, 191, 195, 243, 247, 303, 307, 323, 327, 350, 367}, duration = 0},
    {name = "Shield of the Righteous", spellID = 1251859, category = "tankbuster", phase = 1, times = {30, 72, 114, 128, 152, 172, 192, 244, 304, 324, 347, 364}, duration = 0},
    {name = "Final Verdict", spellID = 1251812, category = "tankbuster", phase = 1, times = {34, 76, 116, 132, 156, 176, 196, 248, 308, 328, 351, 368}, duration = 0},
    {name = "Divine Storm", spellID = 1246765, category = "event", phase = 1, times = {18, 38, 58, 77, 120, 165, 180, 200, 220, 242, 292, 312, 332, 352, 372, 392, 412, 468}, duration = 0},
    {name = "Light Infused", spellID = 1258659, category = "raid dot", phase = 1, times = {0, 35, 83, 132, 209, 258, 309}, duration = 0},
    {name = "Blinding Light", spellID = 1258514, category = "event", phase = 1, times = {22, 82, 170, 222, 285, 346, 400, 449, 474}, duration = 10},
    {name = "Divine Toll", spellID = 1248644, category = "movement", phase = 1, times = {43, 217, 391, 493}, duration = 8},
    {name = "Aura of Devotion", spellID = 1246162, category = "movement, raid damage", phase = 1, times = {43, 217, 386}, duration = 20},
    {name = "Aura of Wrath", spellID = 1248449, category = "raid damage", phase = 1, times = {86, 261, 433}, duration = 20},
    {name = "Aura of Peace", spellID = 1248451, category = "movement", phase = 1, times = {137, 314}, duration = 20},
    {name = "Sacred Toll", spellID = 1246749, category = "raid damage", phase = 1, times = {13, 26, 46, 66, 125, 148, 163, 208, 228, 300, 321, 359, 379, 399, 419, 462}, duration = 0},
    {name = "Searing Radiance", spellID = 1255738, category = "raid damage", phase = 1, times = {50, 102, 184, 239, 372}, duration = 15},
    {name = "Tyr's Wrath", spellID = 1248710, category = "healing absorb", phase = 1, times = {142, 147, 152, 157, 319, 324, 329, 334}, duration = 5},
    {name = "Execution Sentence", spellID = 1250839, category = "debuffs, movement", phase = 1, times = {86, 261, 433}, duration = 10},
    {name = "Execution Sentence", spellID = 1250839, category = "group soak", phase = 1, times = {96, 271, 443}, duration = 0},
}

local heroicPhases = {
    [1] = {start = 0},
    [2] = {start = 480},
}

local mythicAbilities = {
    {name = "Light Infused", spellID = 1258659, category = "raid dot", phase = 1, times = {0, 26, 79, 134, 185, 238, 291, 344}, duration = 0},
    {name = "Avenger's Shield", spellID = 1246497, category = "dispel", phase = 1, times = {15, 105, 123, 159, 177, 267, 285, 305, 321, 339}, duration = 0},
    {name = "Avenger's Shield", spellID = 1246497, category = "raid damage", phase = 1, times = {69, 231}, duration = 0},
    {name = "Judgment", spellID = 1251857, category = "tankbuster", phase = 1, times = {22, 26, 58, 62, 112, 116, 130, 134, 148, 152, 166, 170, 220, 224, 274, 292, 296, 310, 314, 328, 332}, duration = 0},
    {name = "Shield of the Righteous", spellID = 1251859, category = "tankbuster", phase = 1, times = {25, 61, 115, 133, 151, 169, 223, 277, 295, 313, 331}, duration = 0},
    {name = "Final Verdict", spellID = 1251812, category = "tankbuster", phase = 1, times = {29, 65, 119, 137, 155, 173, 227, 299, 317, 335}, duration = 0},
    {name = "Divine Storm", spellID = 1246765, category = "raid damage", phase = 1, times = {123, 285}, duration = 0},
    {name = "Divine Storm", spellID = 1246765, category = "event", phase = 1, times = {15, 33, 51, 69, 141, 159, 177, 195, 213, 231, 267, 303, 321, 339, 357}, duration = 0},
    {name = "Blinding Light", spellID = 1258514, category = "event", phase = 1, times = {40, 170, 214, 265, 326}, duration = 10},
    {name = "Divine Toll", spellID = 1248644, category = "movement", phase = 1, times = {34, 87, 193, 246, 352}, duration = 8},
    {name = "Aura of Devotion", spellID = 1246162, category = "movement, raid damage", phase = 1, times = {29, 35, 188, 193, 347}, duration = 20},
    {name = "Aura of Wrath", spellID = 1248449, category = "raid damage", phase = 1, times = {82, 241}, duration = 20},
    {name = "Aura of Peace", spellID = 1248451, category = "movement", phase = 1, times = {139}, duration = 20},
    {name = "Searing Radiance", spellID = 1255738, category = "raid damage", phase = 1, times = {12, 184, 343}, duration = 15},
    {name = "Searing Radiance", spellID = 1255738, category = "raid dot", phase = 1, times = {62, 114, 236}, duration = 15},
    {name = "Sacred Toll", spellID = 1246749, category = "raid damage", phase = 1, times = {23, 41, 59, 77, 113, 131, 167, 185, 203, 221, 275, 293, 311, 329, 347, 365}, duration = 0},
    {name = "Tyr's Wrath", spellID = 1248710, category = "healing absorb", phase = 1, times = {34, 37, 40, 43, 144, 147, 150, 153, 193, 196, 199, 202, 352, 355, 358, 361}, duration = 5},
    {name = "Execution Sentence", spellID = 1250839, category = "group soak", phase = 1, times = {92, 149, 251, 307}, duration = 0},
    {name = "Execution Sentence", spellID = 1250839, category = "debuffs, movement", phase = 1, times = {82, 139, 241, 297}, duration = 10},
}

local mythicPhases = {
    [1] = {start = 0},
    [2] = {start = 480},
}

NSI.BossTimelines[3180] = {
    Heroic = {
        duration = 500,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 500,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
