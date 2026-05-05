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

function NSI:DefaultLoadConditions()
    return {
        Roles   = {},
        Classes = {},
        SpecIDs = {},
        Names = {},
    }
end

-- Builds a flat alert definition for use with AddEncounterAlert.
-- displayType: "Text", "Bar", "Icon", or "Circle"
-- timers: { [phase] = {times...} }
-- overrides: optional table of field overrides
function NSI:MakeEncounterAlert(data, timers)
    local a = {
        internalID     = data.internalID,
        name           = data.name or data.internalID,
        text           = data.text,
        spellID        = data.spellID,
        TTS            = data.TTS,
        TTSTimer       = data.TTSTimer or data.dur,
        dur            = data.dur,
        timers         = timers or data.timers or {},
        phase          = data.phase,
        DisplayType    = data.DisplayType,
        notsticky      = true,
        IsAlert        = true,
        ReloeReminder  = true,
        enabled        = true,
        loadConditions = NSI.DefaultLoadConditions(),
        extraOptions   = data.extraOptions,
        Preview        = data.Preview,
    }
    if data.overrides then
        for k, v in pairs(data.overrides) do a[k] = v end
    end
    return a
end

local function UniqueAlertID(diffTable, ReloeReminder, internalID)
    local id = internalID
    if ReloeReminder and not id then
        print("No internalID found for Reloe reminder alert. Aborting")
        return
    elseif not id then
        repeat id = GenerateAlertID() until not diffTable[id]
    end
    return id
end

function NSI:GetEncounterAlertID(encID)
    self.EncounterAlertID = self.EncounterAlertID or {}
    if not self.EncounterAlertID[encID] then
        self.EncounterAlertID[encID] = 0
    end
    self.EncounterAlertID[encID] = self.EncounterAlertID[encID] + 1
    return self.EncounterAlertID[encID]
end

function NSI:AddEncounterAlert(data)
    self.EncounterAlertID = self.EncounterAlertID or {}
    if data.difficulties and not data.timers then -- special case for alerts that don't use the actual reminder system but have their own display
        local alertDef = self:MakeEncounterAlert(data)
        for _, diff in ipairs(data.difficulties) do
            alertDef.id = data.id or self:GetEncounterAlertID(data.encID)
            self:InsertEncounterAlert(data.encID, diff, alertDef, true)
        end
        return
    end
    for diffID, phaseData in pairs(data.timers) do
        if phaseData[1] and type(phaseData[1]) == "table" then -- multiple phases were provided
            for phase, timers in ipairs(phaseData) do
                if next(timers) then
                    local alertDef = self:MakeEncounterAlert(data, timers)
                    alertDef.phase = phase
                    alertDef.internalID = data.internalID.."_P"..phase
                    alertDef.id = data.id or self:GetEncounterAlertID(data.encID)
                    self:InsertEncounterAlert(data.encID, diffID, alertDef, true)
                end
            end
        else
            local timers = phaseData
            local alertDef = self:MakeEncounterAlert(data, timers)
            alertDef.id = data.id or self:GetEncounterAlertID(data.encID)
            self:InsertEncounterAlert(data.encID, diffID, alertDef, true)
        end
    end
end

-- Adds or updates an alert entry keyed by a short unique ID at NSRT.EncounterAlerts[encId][diffID].
-- `name` is the human-readable display name stored in alertDef.name and used for lookup.
-- to preserve user-modified settings (enabled, TTS overrides, etc.).
function NSI:InsertEncounterAlert(encId, diffID, alertDef, ReloeReminder)
    NSRT.EncounterAlerts[encId]         = NSRT.EncounterAlerts[encId] or {}
    NSRT.EncounterAlerts[encId][diffID] = NSRT.EncounterAlerts[encId][diffID] or {}
    local diffTable = NSRT.EncounterAlerts[encId][diffID]
    -- Migrate any legacy string-keyed entry with this name to a unique ID key
    if diffTable[name] and type(diffTable[name]) == "table" then
        local legacy = diffTable[name]
        legacy.name = name
        diffTable[UniqueAlertID(diffTable, ReloeReminder, alertDef.internalID)] = legacy
        diffTable[name] = nil
    end
    if ReloeReminder and diffTable[alertDef.internalID] then -- overwrite timers and some other data as they are defined by me
        local existing = diffTable[alertDef.internalID]
        existing.timers = alertDef.timers
        existing.id = alertDef.id
        existing.customIcon = alertDef.customIcon
        existing.isConditional = alertDef.isConditional
        existing.name = alertDef.name
        existing.extraOptions = alertDef.extraOptions
        existing.Preview = alertDef.Preview
        return
    end
    diffTable[UniqueAlertID(diffTable, ReloeReminder, alertDef.internalID)] = alertDef
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
