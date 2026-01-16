local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- LIGHTBLINDED VANGUARD (3180)
-- Single phase, Tyr's Wrath bursts of 4
--------------------------------------------------------------------------------
NSI.BossTimelines[3180] = {
    duration = 400,
    phases = {
        [1] = {start = 0},
    },
    abilities = {
        {name = "Light Infused", spellID = 1258659, category = "damage", phase = 1, times = {0, 26, 79, 134, 238, 344}, duration = 0},
        {name = "Searing Radiance", spellID = 1255738, category = "damage", phase = 1, times = {12, 62, 114, 184, 236, 343}, duration = 3},
        {name = "Divine Storm", spellID = 1246765, category = "damage", phase = 1, times = {15, 33, 51, 69, 123, 141, 159, 177, 195, 213, 231, 267, 285, 303, 321, 339, 357}, duration = 2},
        {name = "Sacred Toll", spellID = 1246749, category = "damage", phase = 1, times = {23, 41, 59, 77, 113, 131, 149, 167, 185, 203, 221, 239, 257, 275, 293, 311, 329, 347, 365}, duration = 2},
        {name = "Judgment", spellID = 1251857, category = "tank", phase = 1, times = {22, 58, 112, 116, 130, 166, 168, 220, 224, 232, 274, 278, 292, 296, 310, 314, 328, 332}, duration = 2},
        {name = "Shield of the Righteous", spellID = 1251859, category = "tank", phase = 1, times = {25, 61, 115, 133, 151, 169, 187, 205, 223, 243, 277, 295, 313, 331}, duration = 2},
        {name = "Aura of Devotion", spellID = 1246162, category = "movement", phase = 1, times = {29, 35, 188}, duration = 6},
        {name = "Tyr's Wrath", spellID = 1248710, category = "damage", phase = 1, times = {34, 37, 40, 43, 144, 147, 150, 153, 193, 196, 199, 202, 352, 355, 358, 361}, duration = 3},
        {name = "Final Verdict", spellID = 1251812, category = "tank", phase = 1, times = {65, 119, 137, 155, 173, 191, 209, 227, 245, 263, 281, 299, 317, 335}, duration = 2},
        {name = "Execution Sentence", spellID = 1250839, category = "soak", phase = 1, times = {82, 92, 139, 149}, duration = 10},
        {name = "Divine Toll", spellID = 1248644, category = "damage", phase = 1, times = {87, 246}, duration = 4},
        {name = "Avenger's Shield", spellID = 1246497, category = "tank", phase = 1, times = {105, 305}, duration = 2},
        {name = "Blinding Light", spellID = 1258514, category = "movement", phase = 1, times = {170, 214, 265, 326}, duration = 3},
        {name = "Aura of Wrath", spellID = 1248449, category = "intermission", phase = 1, times = {241}, duration = 120},
    },
}
