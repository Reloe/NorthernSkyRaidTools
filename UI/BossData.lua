local _, NSI = ...

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
}

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
            label   = noBossLabel or "No Boss",
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
            label    = NSI.BossTimelineNames[encID] or ("Encounter " .. encID),
            value    = encID,
            icon     = BossIcons[encID],
            iconsize = { 16, 16 },
            texcoord = { 0.05, 0.95, 0.05, 0.95 },
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
