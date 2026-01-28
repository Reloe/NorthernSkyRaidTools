local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- LIGHTBLINDED VANGUARD (3180)
-- Single phase, Tyr's Wrath bursts of 4
--------------------------------------------------------------------------------

local abilities = {
        {name = "Avenger's Shield", spellID = 1246497, category = "debuffs", phase = 1, times = {15, 69, 105, 123, 159, 177, 231, 267, 285, 305, 321, 339}, duration = 0},
        {name = "Judgment", spellID = 1251857, category = "tankbuster", phase = 1, times = {22, 26, 58, 62, 112, 116, 130, 134, 148, 152, 166, 170, 220, 224, 274, 292, 296, 310, 314, 328, 332}, duration = 0},
        {name = "Shield of the Righteous", spellID = 1251859, category = "tankbuster", phase = 1, times = {25, 61, 115, 133, 151, 169, 223, 277, 295, 313, 331}, duration = 0},
        {name = "Final Verdict", spellID = 1251812, category = "tankbuster", phase = 1, times = {29, 65, 119, 137, 155, 173, 227, 299, 317, 335}, duration = 0},
        {name = "Divine Storm", spellID = 1246765, category = "event", phase = 1, times = {15, 33, 51, 69, 123, 141, 159, 177, 195, 213, 231, 267, 285, 303, 321, 339, 357}, duration = 0},
        {name = "Light Infused", spellID = 1258659, category = "raid dot", phase = 1, times = {0, 26, 79, 134, 185, 238, 344}, duration = 0},
        {name = "Blinding Light", spellID = 1258514, category = "event", phase = 1, times = {40, 170, 214, 265, 326}, duration = 10},
        {name = "Divine Toll", spellID = 1248644, category = "movement", phase = 1, times = {34, 87, 193, 246, 352}, duration = 8},
        {name = "Aura of Devotion", spellID = 1246162, category = "movement, raid damage", phase = 1, times = {29, 35, 188, 193, 347}, duration = 20},
        {name = "Aura of Wrath", spellID = 1248449, category = "raid damage", phase = 1, times = {82, 241}, duration = 20},
        {name = "Aura of Peace", spellID = 1248451, category = "raid damage", phase = 1, times = {139}, duration = 20},
        {name = "Searing Radiance", spellID = 1255738, category = "raid damage", phase = 1, times = {12, 62, 114, 184, 236, 343}, duration = 15},
        {name = "Sacred Toll", spellID = 1246749, category = "raid damage", phase = 1, times = {23, 41, 59, 77, 113, 131, 167, 185, 203, 221, 275, 293, 311, 329, 347, 365}, duration = 0},
        {name = "Tyr's Wrath", spellID = 1248710, category = "healing absorb", phase = 1, times = {34, 37, 40, 43, 144, 147, 150, 153, 193, 196, 199, 202, 352, 355, 358, 361}, duration = 5},
        {name = "Execution Sentence", spellID = 1250839, category = "group soak", phase = 1, times = {92, 149}, duration = 0},
        {name = "Execution Sentence", spellID = 1250839, category = "debuffs, movement", phase = 1, times = {82, 139}, duration = 10},
    }

local phases = {
        [1] = {start = 0},
        [2] = {start = 480},
    }

NSI.BossTimelines[3180] = {
    Mythic = {
        duration = 500,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 500,
        phases = phases,
        abilities = abilities,
    },
}
