local addonId, NSI = ...
-- ============================================================================
-- BossData
-- Shared boss icon and dropdown helpers used by multiple UI modules so that
-- the list of known encounters is maintained in one place.
-- ============================================================================

local BossIcons = {
    [3176] = 7448209, -- Imperator Averzian
    [3177] = 7448210, -- Vorasius
    [3179] = 7448212, -- Fallen King Salhadaar
    [3178] = 7448207, -- Vaelgor & Ezzorak
    [3180] = 7448211, -- Lightblinded Vanguard
    [3181] = 7448205, -- Crown of the Cosmos
    [3306] = 7448202, -- Chimaerus
    [3182] = 7448203, -- Belo'ren
    [3183] = 7448204, -- Midnight Falls
    [3159] = 7852823, -- Rotmire

    [3379] = 3012069, -- Nymrissa Wavecaller
    [3470] = 7966621, -- Nek'zali the Soulcoiler
    [3445] = 7966620, -- Entombed Sentinels
    [3455] = 7966618, -- Vashnik the Malignant
    [3497] = 7966622, -- The Lost Explorers
    [3420] = 7966619, -- Sszorak
    [3421] = 7966623, -- The Twin Fangs
    [3429] = 7966625, -- The Coiled Altar
    [3492] = 7966624, -- Ula'tek
}

local season1EncounterIDs = {
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

local season2EncounterIDs = {
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

NSI.Season2EncounterIDs = season2EncounterIDs

local isSeason2 = NSI:IsMidnightS2()
local orderedSeasons = isSeason2 and {season2EncounterIDs, season1EncounterIDs} or {season1EncounterIDs}

NSI.EncounterOrder = {}
local encounterOrder = 0
for _, season in ipairs(orderedSeasons) do
    for _, encID in ipairs(season) do
        encounterOrder = encounterOrder + 1
        NSI.EncounterOrder[encID] = encounterOrder
    end
end

NSI.CurrentEncounterIDs = {} -- Old-season Reloe alerts are deletable and are not imported automatically.
for _, encID in ipairs(isSeason2 and season2EncounterIDs or season1EncounterIDs) do
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

function NSI:CanDeleteEncounterAlert(alert, encID)
    if type(alert) ~= "table" then return true end
    if not alert.ReloeReminder then return true end
    return not self.CurrentEncounterIDs[encID]
end
-- Builds a DF dropdown options table sorted by encounter order.
--
-- onSelect(encID)  – called when an option is chosen; may be nil.
-- noBossLabel      – label string for the "no boss" first entry.
--                    Pass false to omit that entry entirely.
--                    Defaults to "No Boss".
local function BuildBossDropdownOptions(onSelect, noBossLabel)
    local options = {}

    if noBossLabel ~= false then
        table.insert(options, {
            label   = noBossLabel or NSI:Loc("No Boss"),
            value   = 0,
            onclick = function(_, _, _)
                if onSelect then onSelect(0) end
            end,
        })
    end

    local sorted = {}
    for encID, order in pairs(NSI.EncounterOrder) do
        table.insert(sorted, { encID = encID, order = order })
    end
    table.sort(sorted, function(a, b) return a.order < b.order end)

    for _, entry in ipairs(sorted) do
        local encID = entry.encID
        table.insert(options, {
            label    = NSI:Loc(NSI.BossNames[encID] or ("Encounter " .. encID)),
            value    = encID,
            icon     = BossIcons[encID],
            iconsize = { 16, 16 },
            texcoord = { 0.1, 0.90, 0.1, 0.90 },
            onclick  = function(_, _, v)
                if onSelect then onSelect(v) end
            end,
        })
    end

    return options
end

NSI.UI = NSI.UI or {}
NSI.UI.BossData = {
    BossIcons                = BossIcons,
    BuildBossDropdownOptions = BuildBossDropdownOptions,
}
