local NSI = _G.NorthernSkyRaidTools

-- Pure helpers for the Encounter Alerts screen (circle textures, phase/timer parsing).
-- No UI state lives here; exported on NSI.UI.EncounterAlertParts.Helpers.

local CIRCLE_TEXTURES = {
    {label="2 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_2px.png]]},
    {label="5 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_5px.png]]},
    {label="8 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_8px.png]]},
    {label="10 px", value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_10px.png]]},
    {label="15 px", value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_15px.png]]},
}

local function GetCircleTextureLabel(texture)
    for _, option in ipairs(CIRCLE_TEXTURES) do
        if option.value == texture then return option.label end
    end
    return texture and tostring(texture) or ""
end

local function GetDefaultCircleTextureLabel()
    local texture = NSRT.ReminderSettings and NSRT.ReminderSettings.CircleSettings
        and NSRT.ReminderSettings.CircleSettings.Texture
    return NSI:Loc("Default") .. " (" .. GetCircleTextureLabel(texture) .. ")"
end

local function FormatPhaseValue(phase)
    if type(phase) == "table" then
        local values = {}
        for _, value in ipairs(phase) do
            values[#values + 1] = tostring(value)
        end
        return table.concat(values, ",")
    end
    return tostring(phase or 1)
end

local function ParsePhaseValue(value)
    local phases = {}
    local seen = {}
    for token in tostring(value or ""):gmatch("[^,%s]+") do
        local phase = tonumber(token)
        if phase and phase >= 1 and not seen[phase] then
            seen[phase] = true
            phases[#phases + 1] = phase
        end
    end
    if #phases == 0 then
        return 1
    end
    if #phases == 1 then
        return phases[1]
    end
    table.sort(phases)
    return phases
end

local function GetPhaseList(phase)
    if type(phase) == "table" then
        return phase
    end
    return {tonumber(phase) or 1}
end

local function InsertSortedTimer(timers, value)
    timers = timers or {}
    local inserted = false
    for index, existing in ipairs(timers) do
        if value < existing then
            table.insert(timers, index, value)
            inserted = true
            break
        end
    end
    if not inserted then
        table.insert(timers, value)
    end
    return timers
end

local function FlattenPhaseTimers(phaseTimers)
    local timers = {}
    local seen = {}
    for _, phase in ipairs(NSI:GetSortedPhaseKeys(phaseTimers)) do
        for _, time in ipairs(phaseTimers[phase] or {}) do
            if not seen[time] then
                seen[time] = true
                timers = InsertSortedTimer(timers, time)
            end
        end
    end
    return timers
end

local function BuildPhaseTimersFromFlatTimers(timers, phases)
    local phaseTimers = {}
    for _, phase in ipairs(phases) do
        phaseTimers[phase] = {}
        for _, time in ipairs(timers or {}) do
            phaseTimers[phase] = InsertSortedTimer(phaseTimers[phase], time)
        end
    end
    return phaseTimers
end

NSI.UI = NSI.UI or {}
NSI.UI.EncounterAlertParts = NSI.UI.EncounterAlertParts or {}
NSI.UI.EncounterAlertParts.Helpers = {
    CIRCLE_TEXTURES = CIRCLE_TEXTURES,
    GetCircleTextureLabel = GetCircleTextureLabel,
    GetDefaultCircleTextureLabel = GetDefaultCircleTextureLabel,
    FormatPhaseValue = FormatPhaseValue,
    ParsePhaseValue = ParsePhaseValue,
    GetPhaseList = GetPhaseList,
    InsertSortedTimer = InsertSortedTimer,
    FlattenPhaseTimers = FlattenPhaseTimers,
    BuildPhaseTimersFromFlatTimers = BuildPhaseTimersFromFlatTimers,
}
