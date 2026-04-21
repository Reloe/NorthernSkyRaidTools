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
    {name = "Aura of Devotion", spellID = 1246162, category = "movement", phase = 1, times = {43, 217, 386}, duration = 20},
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
    {name = "Light Infused", spellID = 1258659, category = "raid dot", phase = 1, times = {0, 26, 79, 134, 185, 238, 291, 344, 397, 451}, duration = 0},
    {name = "Avenger's Shield", spellID = 1246497, category = "dispel", phase = 1, times = {18, 96, 108, 126, 140, 146, 162, 180, 255, 270, 288, 299, 306, 326, 342, 414, 432, 450, 458}, duration = 0},
    {name = "Avenger's Shield", spellID = 1246497, category = "raid damage", phase = 1, times = {72, 234, 396}, duration = 0},
    {name = "Judgment", spellID = 1251857, category = "tankbuster", phase = 1, times = {22, 26, 58, 62, 112, 116, 148, 152, 166, 170, 220, 224, 274, 278, 310, 314, 328, 332, 382, 386, 436, 440}, duration = 0},
    {name = "Shield of the Righteous", spellID = 1251859, category = "tankbuster", phase = 1, times = {25, 61, 115, 151, 169, 223, 277, 313, 331, 385, 439}, duration = 0},
    {name = "Final Verdict", spellID = 1251812, category = "tankbuster", phase = 1, times = {29, 65, 119, 155, 173, 227, 281, 317, 335, 389, 443}, duration = 0},
    {name = "Elekk Charge", spellID = 1249130, category = "movement, event", phase = 1, times = {31, 90, 163, 207, 259, 322, 367, 419}, duration = 0},
    {name = "Divine Storm", spellID = 1246765, category = "raid damage", phase = 1, times = {123, 285, 447}, duration = 0},
    {name = "Divine Storm", spellID = 1246765, category = "event", phase = 1, times = {15, 33, 51, 69, 141, 159, 177, 195, 213, 231, 267, 303, 321, 339, 357, 375, 393, 429}, duration = 0},
    {name = "Blinding Light", spellID = 1258514, category = "event", phase = 1, times = {35, 96, 169, 213, 265, 329, 372, 424}, duration = 10},
    {name = "Divine Toll", spellID = 1248644, category = "movement", phase = 1, times = {34, 87, 193, 246, 352, 405}, duration = 8},
    {name = "Aura of Devotion", spellID = 1246162, category = "movement", phase = 1, times = {29, 34, 188, 193, 347, 352}, duration = 20},
    {name = "Aura of Wrath", spellID = 1248449, category = "raid damage", phase = 1, times = {82, 241, 400}, duration = 20},
    {name = "Aura of Peace", spellID = 1248451, category = "movement", phase = 1, times = {138, 297, 456}, duration = 20},
    {name = "Searing Radiance", spellID = 1255738, category = "raid damage", phase = 1, times = {11, 182, 341}, duration = 15},
    {name = "Searing Radiance", spellID = 1255738, category = "raid dot", phase = 1, times = {63, 115, 234, 394}, duration = 15},
    {name = "Sacred Toll", spellID = 1246749, category = "raid damage", phase = 1, times = {22, 40, 58, 76, 112, 130, 166, 184, 202, 220, 274, 292, 310, 328, 346, 364, 382, 436}, duration = 0},
    {name = "Tyr's Wrath", spellID = 1248710, category = "healing absorb", phase = 1, times = {39, 44, 49, 54, 148, 153, 158, 163, 198, 203, 208, 213, 307, 312, 317, 322, 357, 362, 367, 372, 466, 471, 476, 481}, duration = 5},
    {name = "Execution Sentence", spellID = 1250839, category = "group soak", phase = 1, times = {90, 146, 249, 305, 408, 464}, duration = 0},
    {name = "Execution Sentence", spellID = 1250839, category = "debuffs, movement", phase = 1, times = {82, 138, 241, 297, 400, 456}, duration = 10},
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
