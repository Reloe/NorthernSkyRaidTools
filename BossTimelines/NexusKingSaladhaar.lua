local _, NSI = ... -- Internal namespace

--------------------------------------------------------------------------------
-- NEXUS KING SALADHAAR (3134)
--------------------------------------------------------------------------------

local abilities = {
    {name = "Decree: Oath-Bound", spellID = 1224731, category = "raid aoe", phase = 1, times = {3}, duration = 6},
    {name = "Vengeful Oath", spellID = 1239136, category = "event", phase = 1, times = {49, 89, 113}, duration = 3},
    {name = "Banishment", spellID = 1227529, category = "debuff", phase = 1, times = {32, 48, 72, 88}, duration = 6},
    {name = "Command: Behead", spellID = 1225010, category = "debuff", phase = 1, times = {34, 75}, duration = 0},
    {name = "Command: Besiege", spellID = 1225016, category = "movement", phase = 1, times = {51, 91}, duration = 24},
    {name = "Subjugation Rule", spellID = 1224776, category = "raid soak", phase = 1, times = {18, 55, 96}, duration = 12},
    {name = "Invoke the Oath", spellID = 1224906, category = "raid aoe", phase = 1, times = {117}, duration = 0},
    {name = "Coalesce Voidwing", spellID = 1227734, category = "movement", phase = 1, times = {126}, duration = 0},
    {name = "Netherbreaker", spellID = 1228113, category = "movement", phase = 1, times = {129, 222}, duration = 6},
    {name = "Cosmic Maw", spellID = 1234529, category = "tankbuster", phase = 1, times = {136, 236}, duration = 0},
    {name = "Dimension Breath", spellID = 1228163, category = "movement", phase = 1, times = {142, 148, 154, 242, 248, 254}, duration = 4},
    {name = "Dimension Glare", spellID = 1234539, category = "raid aoe", phase = 1, times = {148, 248}, duration = 0},
    {name = "Rally the Shadowguard", spellID = 1228065, category = "add spawn", phase = 1, times = {162}, duration = 0},
    {name = "Reap", spellID = 1228053, category = "debuff", phase = 1, times = {174, 186, 198, 211}, duration = 0},
    {name = "Twilight Massacre", spellID = 1237106, category = "movement", phase = 1, times = {176, 201}, duration = 5},
    {name = "Twilight Massacre", spellID = 1237106, category = "debuff", phase = 1, times = {181, 206}, duration = 0},
    {name = "King's Hunger", spellID = 1228317, category = "raid aoe", phase = 1, times = {266}, duration = 30},
    {name = "Galactic Smash", spellID = 1226648, category = "raid aoe", phase = 2, times = {17, 72, 127}, duration = 0},
    {name = "Galactic Smash", spellID = 1226648, category = "movement", phase = 2, times = {5, 60, 115}, duration = 12},
    {name = "Dark Star", spellID = 1225452, category = "raid dot", phase = 2, times = {17, 72, 127}, duration = 40},
    {name = "Dark Star", spellID = 1225452, category = "raid dot", phase = 2, times = {17, 72, 127}, duration = 24},
    {name = "Starkiller Swing", spellID = 1226347, category = "raid aoe", phase = 2, times = {42, 57, 97, 112, 152, 167}, duration = 0},
    {name = "Starkiller Swing", spellID = 1226347, category = "movement", phase = 2, times = {35, 50, 90, 105, 145, 160}, duration = 6},
    {name = "World in Twilight", spellID = 1225634, category = "event", phase = 2, times = {187}, duration = 0},
}

local phases = {
    [1] = {start = 0},
    [2] = {start = 296},
    [4] = {start = 500},
}

NSI.BossTimelines[3134] = {
    Mythic = {
        duration = 505,
        phases = phases,
        abilities = abilities,
    },
    Heroic = {
        duration = 505,
        phases = phases,
        abilities = abilities,
    },
}
