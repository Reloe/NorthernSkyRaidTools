local _, NSI = ... -- Internal namespace

-- Ulatek (3492)

local heroicData = {
    duration = 600,
    phases = {
        [1] = {start = 0},
        [2] = {start = 600},
    },
    abilities = {
    },
}

local mythicData = {
    duration = 600,
    phases = {
        [1] = {start = 0},
        [2] = {start = 600},
    },
    abilities = {
    },
}

NSI.BossTimelines[3492] = {
    Heroic = heroicData,
    Mythic = mythicData,
}
