local _, NSI = ... -- Internal namespace

NSI.EncounterAlerts = NSI.EncounterAlerts or {}

local ID_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"
function NSI.EncounterAlerts:GenerateAlertID()
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

local function IsPhaseTimerTable(timerData)
    for _, value in pairs(timerData or {}) do
        if type(value) == "table" then
            return true
        end
    end
    return false
end

-- Builds a flat alert definition for use with AddEncounterAlert.
-- displayType: "Text", "Bar", "Icon", or "Circle"
-- timers: { [phase] = {times...} }
function NSI:MakeEncounterAlert(data, timers)
    local a = {}
    for k, v in pairs(data) do
        a[k] = v
    end

    a.phase = data.phases or data.phase
    if not a.phase and data.phaseTimers then
        a.phase = self:GetSortedPhaseKeys(data.phaseTimers)
    end
    a.phases = nil
    local primaryPhase = self:GetPrimaryPhase(a.phase)
    local group = data.group
    if group and type(group) == "table" then
        group = primaryPhase and group[primaryPhase]
    end
    local name = data.name
    if name and type(name) == "table" then
        name = primaryPhase and name[primaryPhase]
    elseif data.phaseNames and primaryPhase and type(a.phase) ~= "table" then
        name = "P"..primaryPhase.." "..name
    end
    local isEnabled
    if data.enabled ~= nil then
        isEnabled = data.enabled
    end
    local defaultEnabled = isEnabled ~= false
    if isEnabled == nil then
        isEnabled = NSRT.Alerts.ReloeReminders
    end
    a.name = name or data.internalID
    a.group = group
    a.TTSTimer = data.TTSTimer or data.dur
    a.timers = timers or data.timers or {}
    if data.loadConditions then
        a.loadConditions = CopyTable(data.loadConditions)
    end
    a.IsAlert = true
    a.ReloeReminder = true
    a.enabled = isEnabled
    a.DefaultEnabled = defaultEnabled
    a.sticky = data.sticky or 0
    return a
end

function NSI:UniqueAlertID(diffTable, ReloeReminder, internalID)
    local id = internalID
    if ReloeReminder and not id then
        print("No internalID found for Reloe reminder alert. Aborting")
        return
    elseif not id then
        repeat id = NSI.EncounterAlerts:GenerateAlertID() until not diffTable[id]
    end
    return id
end

local function GetAlertVersionNumber(version)
    return version and type(version) == "table" and version.versionNumber or version
end

local function GetVersionUpdateSteps(version)
    if type(version) ~= "table" then return end
    local steps
    for versionNumber, updates in pairs(version) do
        if type(versionNumber) == "number" and type(updates) == "table" then
            steps = steps or {}
            steps[#steps + 1] = versionNumber
        end
    end
    if steps then table.sort(steps) end
    return steps
end

local function ShouldApplyVersionUpdate(existing, alertDef)
    local newVersion = GetAlertVersionNumber(alertDef and alertDef.Version)
    if not newVersion then return false end

    local oldVersion = GetAlertVersionNumber(existing and existing.Version)
    return not oldVersion or newVersion > oldVersion
end

local function ApplyVersionFields(target, updates)
    if type(updates) ~= "table" then return end
    for key, value in pairs(updates) do
        target[key] = value
    end
end

local function ApplyLegacyVersionFields(target, version)
    if type(version) ~= "table" then return end

    for key, value in pairs(version) do
        if key ~= "versionNumber" and type(key) ~= "number" then
            target[key] = value
        end
    end
end

local function ApplyVersionFieldUpdates(existing, alertDef)
    local version = alertDef and alertDef.Version
    local steps = GetVersionUpdateSteps(version)
    if steps then
        local oldVersion = GetAlertVersionNumber(existing and existing.Version) or 0
        local newVersion = GetAlertVersionNumber(version)
        for _, versionNumber in ipairs(steps) do
            if versionNumber > oldVersion and (not newVersion or versionNumber <= newVersion) then
                ApplyVersionFields(existing, version[versionNumber])
            end
        end
        return
    end

    ApplyLegacyVersionFields(existing, version)
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
        for _, diff in ipairs(data.difficulties) do
            local alertDef = self:MakeEncounterAlert(data)
            alertDef.id = data.id or self:GetEncounterAlertID(data.encID)
            self:InsertEncounterAlert(data.encID, diff, alertDef, true)
        end
        return
    end
    if data.phaseTimers then
        for diffID, phaseTimers in pairs(data.phaseTimers or {}) do
            if IsPhaseTimerTable(phaseTimers) then
                local phaseDataCopy = {}
                for k, v in pairs(data) do
                    phaseDataCopy[k] = v
                end
                phaseDataCopy.phase = data.phases or (type(data.phase) == "table" and data.phase) or self:GetSortedPhaseKeys(phaseTimers)
                phaseDataCopy.phases = nil
                phaseDataCopy.phaseTimers = phaseTimers
                phaseDataCopy.timers = nil
                local alertDef = self:MakeEncounterAlert(phaseDataCopy)
                alertDef.id = data.id or self:GetEncounterAlertID(data.encID)
                self:InsertEncounterAlert(data.encID, diffID, alertDef, true)
            end
        end
        return
    end
    for diffID, phaseData in pairs(data.timers or {}) do
        if IsPhaseTimerTable(phaseData) then -- different timers were provided for multiple phases
            for _, phase in ipairs(self:GetSortedPhaseKeys(phaseData)) do
                local timers = phaseData[phase]
                if next(timers) then
                    local phaseDataCopy = {}
                    for k, v in pairs(data) do
                        phaseDataCopy[k] = v
                    end
                    phaseDataCopy.phase = phase
                    phaseDataCopy.phases = nil
                    local alertDef = self:MakeEncounterAlert(phaseDataCopy, timers)
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
    local existing = diffTable[alertDef.internalID]
    local FullOverwrite = existing and existing.Reset
    local applyDefaultEnabled = self._ApplyReloeAutoEnable or (NSRT.Alerts and NSRT.Alerts.ReloeReminders)
    if FullOverwrite then
        if applyDefaultEnabled and not existing.UserModifiedEnabled then
            alertDef.enabled = alertDef.DefaultEnabled ~= false
        else
            alertDef.enabled = existing.enabled
        end
        alertDef.UserModifiedEnabled = existing.UserModifiedEnabled
        diffTable[self:UniqueAlertID(diffTable, ReloeReminder, alertDef.internalID)] = alertDef
        return
    elseif existing then
        existing.name = alertDef.name
        existing.timers = alertDef.timers
        existing.phaseTimers = alertDef.phaseTimers
        existing.id = alertDef.id
        existing.isConditional = alertDef.isConditional
        existing.extraOptions = alertDef.extraOptions
        existing.Preview = alertDef.Preview
        existing.phase = alertDef.phase
        existing.isSpecialDisplay = alertDef.isSpecialDisplay
        existing.DefaultEnabled = alertDef.DefaultEnabled
        existing.BlockCopy = alertDef.BlockCopy
        if applyDefaultEnabled and not existing.UserModifiedEnabled then
            existing.enabled = alertDef.DefaultEnabled ~= false
        end
        if ShouldApplyVersionUpdate(existing, alertDef) then
            ApplyVersionFieldUpdates(existing, alertDef)
        end
        existing.Version = alertDef.Version
        return
    end
    diffTable[self:UniqueAlertID(diffTable, ReloeReminder, alertDef.internalID)] = alertDef
end

-- Returns the alert entry for the given encId/diffID whose name matches, or nil.
function NSI:GetEncounterAlertByName(encId, diffID, name)
    local diffTable = NSRT.EncounterAlerts[encId] and NSRT.EncounterAlerts[encId][diffID]
    if not diffTable then return nil end
    for _, entry in pairs(diffTable) do
        if type(entry) == "table" and entry.name == name then return entry end
    end
end

function NSI:RemoveEncounterAlert(encID, diffID, internalID)
    if NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][diffID] then
        NSRT.EncounterAlerts[encID][diffID][internalID] = nil
    end
end
