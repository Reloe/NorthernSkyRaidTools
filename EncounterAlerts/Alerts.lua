local _, NSI = ... -- Internal namespace

local ID_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"
local function GenerateAlertID()
    local id = ""
    for _ = 1, 5 do
        local i = math.random(1, #ID_CHARS)
        id = id .. ID_CHARS:sub(i, i)
    end
    return id
end

NSI.DefaultLoadConditions = function()
    return {
        Roles   = { TANK = false, HEALER = false, DAMAGER = false, MELEE = false, RANGED = false },
        Classes = {
            WARRIOR = false, PALADIN = false, HUNTER = false, ROGUE = false,
            PRIEST = false, DEATHKNIGHT = false, SHAMAN = false, MAGE = false,
            WARLOCK = false, MONK = false, DRUID = false, DEMONHUNTER = false, EVOKER = false,
        },
        SpecIDs = {
            [250] = false, [251] = false, [252] = false,
            [102] = false, [103] = false, [104] = false, [105] = false,
            [62]  = false, [63]  = false, [64]  = false,
            [253] = false, [254] = false, [255] = false,
            [259] = false, [260] = false, [261] = false,
            [256] = false, [257] = false, [258] = false,
            [577] = false, [581] = false,
            [1480] = false, [1467] = false, [1468] = false, [1473] = false,
        },
        Names = {},
    }
end

-- Builds a flat alert definition for use with AddEncounterAlert.
-- displayType: "Text", "Bar", "Icon", or "Circle"
-- timers: { [phase] = {times...} }
-- overrides: optional table of field overrides
function NSI:MakeEncounterAlert(text, spellID, dur, displayType, timers, overrides)
    local a = {
        name           = text,
        text           = text,
        spellID        = spellID,
        dur            = dur,
        timers         = timers or {},
        notsticky      = true,
        IsAlert        = true,
        reloeReminder  = true,
        enabled        = true,
        loadConditions = NSI.DefaultLoadConditions(),
    }
    if displayType == "Bar" then
        a.BarOverwrite = true
    elseif displayType == "Icon" then
        a.IconOverwrite = true
    elseif displayType == "Circle" then
        a.CircleOverwrite = true
    end
    if overrides then
        for k, v in pairs(overrides) do a[k] = v end
    end
    return a
end

local function UniqueAlertID(diffTable)
    local id
    repeat id = GenerateAlertID() until not diffTable[id]
    return id
end

-- Adds or updates an alert entry keyed by a short unique ID at NSRT.EncounterAlerts[encId][diffID].
-- `name` is the human-readable display name stored in alertDef.name and used for lookup.
-- If an existing reloeReminder with matching name is found, only its timers are updated
-- to preserve user-modified settings (enabled, TTS overrides, etc.).
function NSI:AddEncounterAlert(encId, diffID, name, alertDef)
    NSRT.EncounterAlerts[encId]         = NSRT.EncounterAlerts[encId] or {}
    NSRT.EncounterAlerts[encId][diffID] = NSRT.EncounterAlerts[encId][diffID] or {}
    alertDef.name = name
    local diffTable = NSRT.EncounterAlerts[encId][diffID]
    -- Migrate any legacy string-keyed entry with this name to a unique ID key
    if diffTable[name] and type(diffTable[name]) == "table" then
        local legacy = diffTable[name]
        legacy.name = name
        diffTable[UniqueAlertID(diffTable)] = legacy
        diffTable[name] = nil
    end
    -- Search for an existing entry with matching name
    for _, existing in pairs(diffTable) do
        if type(existing) == "table" and existing.reloeReminder and existing.name == name then
            existing.timers = alertDef.timers
            return
        end
    end
    diffTable[UniqueAlertID(diffTable)] = alertDef
end

-- Returns the alert entry for the given encId/diffID whose name matches, or nil.
function NSI:GetEncounterAlertByName(encId, diffID, name)
    local diffTable = NSRT.EncounterAlerts[encId] and NSRT.EncounterAlerts[encId][diffID]
    if not diffTable then return nil end
    for _, entry in pairs(diffTable) do
        if type(entry) == "table" and entry.name == name then return entry end
    end
end

function NSI:RemoveEncounterAlert(encId, diffID, name)
    local enc = NSRT.EncounterAlerts[encId]
    if not enc or not enc[diffID] then return end
    for k, entry in pairs(enc[diffID]) do
        if type(entry) == "table" and entry.name == name then
            enc[diffID][k] = nil
            return
        end
    end
end
