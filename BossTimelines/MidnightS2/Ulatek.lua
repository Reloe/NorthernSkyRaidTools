local _, NSI = ... -- Internal namespace

-- Ulatek (3492)

local heroicPhases = {
        [1] = {start = 0},
        [2] = {start = 600},
    }

local heroicAbilities = {
    }

local mythicPhases = {
        [1] = {start = 0},
        [2] = {start = 600},
    }

local mythicAbilities = {
    }

NSI.BossTimelines[3492] = {
    Heroic = {
        duration = 600,
        phases = heroicPhases,
        abilities = heroicAbilities,
    },
    Mythic = {
        duration = 600,
        phases = mythicPhases,
        abilities = mythicAbilities,
    },
}
