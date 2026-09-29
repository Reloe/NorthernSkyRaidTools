local _, NSI = ...

-- Encounter metadata used by runtime reminder and alert import logic.

local oldEncounterIDs = {
    3176, -- Imperator Averzian
    3177, -- Vorasius
    3179, -- Fallen-King Salhadaar
    3178, -- Vaelgor & Ezzorak
    3180, -- Lightblinded Vanguard
    3181, -- Crown of the Cosmos
    3306, -- Chimaerus
    3182, -- Belo'ren
    3183, -- Midnight Falls
    3159, -- Rotmire
}

local currentEncounterIDs = {
    3379, -- Nymrissa Wavecaller
    3470, -- Nek'zali the Soulcoiler
    3445, -- Entombed Sentinels
    3455, -- Vashnik the Malignant
    3497, -- The Lost Explorers
    3420, -- Sszorak
    3421, -- The Twin Fangs
    3429, -- The Coiled Altar
    3492, -- Ula'tek
}

NSI.CurrentEncounterIDList = currentEncounterIDs

local orderedEncounterGroups = {currentEncounterIDs, oldEncounterIDs}

NSI.EncounterOrder = {}
local encounterOrder = 0
for _, encounterGroup in ipairs(orderedEncounterGroups) do
    for _, encID in ipairs(encounterGroup) do
        encounterOrder = encounterOrder + 1
        NSI.EncounterOrder[encID] = encounterOrder
    end
end

NSI.CurrentEncounterIDs = {} -- Old-season Reloe alerts are deletable and are not imported automatically.
for _, encID in ipairs(currentEncounterIDs) do
    NSI.CurrentEncounterIDs[encID] = true
end

NSI.BossNames = {
    [3176] = "Imperator Averzian",
    [3177] = "Vorasius",
    [3179] = "Fallen-King Salhadaar",
    [3178] = "Vaelgor & Ezzorak",
    [3180] = "Lightblinded Vanguard",
    [3181] = "Crown of the Cosmos",
    [3306] = "Chimaerus",
    [3182] = "Belo'ren",
    [3183] = "Midnight Falls",
    [3159] = "Rotmire",

    [3379] = "Nymrissa Wavecaller",
    [3470] = "Nek'zali the Soulcoiler",
    [3445] = "Entombed Sentinels",
    [3455] = "Vashnik the Malignant",
    [3497] = "The Lost Explorers",
    [3420] = "Sszorak",
    [3421] = "The Twin Fangs",
    [3429] = "The Coiled Altar",
    [3492] = "Ula'tek",
}

NSI.PrePullEncounterZones = {
    -- Add [zoneID] = encounterID entries as zone IDs are confirmed:
    -- [zoneID] = 3176, -- Imperator Averzian
    -- [zoneID] = 3177, -- Vorasius
    -- [zoneID] = 3179, -- Fallen-King Salhadaar
    -- [zoneID] = 3178, -- Vaelgor & Ezzorak
    -- [zoneID] = 3180, -- Lightblinded Vanguard
    -- [zoneID] = 3181, -- Crown of the Cosmos
    -- [zoneID] = 3306, -- Chimaerus
    -- [zoneID] = 3182, -- Belo'ren
    -- [zoneID] = 3183, -- Midnight Falls
    -- [zoneID] = 3159, -- Rotmire
    -- [zoneID] = 3379, -- Nymrissa Wavecaller
    [17680] = 3470, -- Nek'zali the Soulcoiler
    -- [zoneID] = 3445, -- Entombed Sentinels
    -- [zoneID] = 3455, -- Vashnik the Malignant
    -- [zoneID] = 3497, -- The Lost Explorers
    -- [zoneID] = 3420, -- Sszorak
    -- [zoneID] = 3421, -- The Twin Fangs
    [17701] = 3429, -- The Coiled Altar
    [17702] = 3492, -- Ula'tek
}

-- UI-only deletion policy remains with the UI boss-data module.
