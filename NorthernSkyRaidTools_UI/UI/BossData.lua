local _, NSI = ...

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

function NSI:CanDeleteEncounterAlert(alert, encID)
    if type(alert) ~= "table" then return true end
    if not alert.ReloeReminder then return true end
    return not self.CurrentEncounterIDs[encID]
end

local function BuildBossDropdownOptions(onSelect, noBossLabel)
    local options = {}
    if noBossLabel ~= false then
        options[#options + 1] = {
            label = noBossLabel or NSI:Loc("No Boss"),
            value = 0,
            onclick = function() if onSelect then onSelect(0) end end,
        }
    end

    local sorted = {}
    for encID, order in pairs(NSI.EncounterOrder) do
        sorted[#sorted + 1] = { encID = encID, order = order }
    end
    table.sort(sorted, function(a, b) return a.order < b.order end)

    for _, entry in ipairs(sorted) do
        local encID = entry.encID
        options[#options + 1] = {
            label = NSI:Loc(NSI.BossNames[encID] or ("Encounter " .. encID)),
            value = encID,
            icon = BossIcons[encID],
            iconsize = {16, 16},
            texcoord = {0.1, 0.90, 0.1, 0.90},
            onclick = function(_, _, value) if onSelect then onSelect(value) end end,
        }
    end
    return options
end

NSI.UI = NSI.UI or {}
NSI.UI.BossData = {
    BossIcons = BossIcons,
    BuildBossDropdownOptions = BuildBossDropdownOptions,
}
