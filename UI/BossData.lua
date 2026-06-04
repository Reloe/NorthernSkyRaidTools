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
    [3159] = 1019378, -- Rotmire (Brackenspore Placeholder icon before .7 drops, real one is 7852823)
}

NSI.EncounterOrder = { -- list of encounters for sorting in alerts
    [3176] = 1, -- Imperator
    [3177] = 2, -- Vorasius
    [3179] = 3, -- Fallen-King
    [3178] = 4, -- Dragons
    [3180] = 5, -- Lightblinded Vanguard
    [3181] = 6, -- Crown of the Cosmos
    [3306] = 7, -- Chimaerus
    [3182] = 8, -- Belo'ren
    [3183] = 9, -- Midnight Falls
    [3159] = 10, -- Rotmire
}

NSI.CurrentEncounterIDs = { -- All Encounter ID's from the current season. ID's not in this list are deletable and will not auto import.
    [3176] = true,
    [3177] = true,
    [3179] = true,
    [3178] = true,
    [3180] = true,
    [3181] = true,
    [3306] = true,
    [3182] = true,
    [3183] = true,
    [3159] = true,
}

NSI.BossNames = {
    [3176] = "Imperator Averzian",
    [3177] = "Vorasius",
    [3179] = "Fallen King Salhadaar",
    [3178] = "Vaelgor & Ezzorak",
    [3180] = "Lightblinded Vanguard",
    [3181] = "Crown of the Cosmos",
    [3306] = "Chimaerus",
    [3182] = "Belo'ren",
    [3183] = "Midnight Falls",
    [3159] = "Rotmire",
}

function NSI:IsCurrentSeasonEncounter(encID)
    encID = tonumber(encID)
    if not encID then return false end
    return self.CurrentEncounterIDs[encID]
end

function NSI:CanDeleteEncounterAlert(alert, encID)
    if type(alert) ~= "table" then return true end
    if not alert.ReloeReminder then return true end
    return not self:IsCurrentSeasonEncounter(encID)
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
