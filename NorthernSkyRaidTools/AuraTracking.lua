local _, NSI = ...
local AuraTrackingSerializer = LibStub("AceSerializer-3.0")

local AuraTrackingFilters = {
    "HARMFUL",
}

local AuraTrackingExcludedSpellIDs = {
    [57723] = true, -- Exhaustion
    [390435] = true, -- Exhaustion
    [57724] = true, -- Sated
    [71041] = true, -- Dungeon Deserter
    [206151] = true, -- Challenger's Burden
    [264689] = true, -- Fatigued
    [80354] = true, -- Time Warp
    [95809] = true, -- Insanity
    [160455] = true, -- Fatigued
}
NSI.AuraTrackingFilterDefinitions = {
    { key = "Helpful", value = "HELPFUL" },
    { key = "Harmful", value = "HARMFUL" },
    { key = "Player", value = "PLAYER" },
    { key = "Raid", value = "RAID" },
    { key = "Cancelable", value = "CANCELABLE" },
    { key = "IncludeNameplateOnly", value = "INCLUDE_NAME_PLATE_ONLY" },
    { key = "Maw", value = "MAW" },
    { key = "ExternalDefensive", value = "EXTERNAL_DEFENSIVE" },
    { key = "CrowdControl", value = "CROWD_CONTROL" },
    { key = "RaidInCombat", value = "RAID_IN_COMBAT" },
    { key = "RaidPlayerDispellable", value = "RAID_PLAYER_DISPELLABLE" },
    { key = "BigDefensive", value = "BIG_DEFENSIVE" },
    { key = "Important", value = "IMPORTANT" },
    { key = "Dispellable", value = "DISPELLABLE" },
}

NSI.AuraTrackingCandidateFilterDefinitions = {
    { key = "isFromPlayerOrPlayerPet", label = "From Player or Pet" },
    { key = "isRoleAura", label = "Role Aura" },
    { key = "isPriorityAura", label = "Priority Aura" },
    { key = "isStealable", label = "Stealable" },
    { key = "nameplateShowAll", label = "Nameplate: Show All" },
    { key = "nameplateShowPersonal", label = "Nameplate: Personal" },
    { key = "canApplyAura", label = "Can Apply Aura" },
    { key = "isBossAura", label = "Boss Aura" },
    { key = "isBossOrRoleAura", label = "Boss or Role Aura" },
}

NSI.AuraTrackingCandidateDispelTypes = {
    "Magic",
    "Curse",
    "Disease",
    "Poison",
    "Enrage",
    "Bleed",
}

local AuraTrackingUnitRefreshFrame
local AuraTrackingVehicleStateTimer
local AuraTrackingUnitRefreshStates = {
    target = {},
    focus = {},
    mouseover = {},
    boss = {},
    roster = {},
}

local function GetAuraTrackingFlowDirections(growDirection, gridGrowDirection)
    local horizontal = AnchorUtil.FlowDirection.Right
    local vertical = AnchorUtil.FlowDirection.Down

    if growDirection == "LEFT" then
        horizontal = AnchorUtil.FlowDirection.Left
    elseif growDirection == "UP" then
        vertical = AnchorUtil.FlowDirection.Up
    end

    if gridGrowDirection == "LEFT" then
        horizontal = AnchorUtil.FlowDirection.Left
    elseif gridGrowDirection == "RIGHT" then
        horizontal = AnchorUtil.FlowDirection.Right
    elseif gridGrowDirection == "UP" then
        vertical = AnchorUtil.FlowDirection.Up
    elseif gridGrowDirection == "DOWN" then
        vertical = AnchorUtil.FlowDirection.Down
    end

    return horizontal, vertical
end

local function GetAuraTrackingRowWidth(settings)
    local width = settings.Width or 1
    if settings.GrowDirection == "UP" or settings.GrowDirection == "DOWN" or settings.GrowDirection == "CENTER_VERTICAL" then
        local height = settings.Height or 1
        local limit = settings.AurasPerRowColumn or 20
        local spacing = settings.Spacing or 0
        return math.max(height, (height * limit) + (spacing * math.max(limit - 1, 0)))
    end

    local limit = settings.AurasPerRowColumn or 20
    local spacing = settings.Spacing or 0
    return math.max(width, (width * limit) + (spacing * math.max(limit - 1, 0)))
end

local function GetAuraTrackingLayoutAnchorPoint(settings)
    local growDirection = settings and settings.GrowDirection or "RIGHT"
    if growDirection == "LEFT" then
        return "TOPRIGHT"
    elseif growDirection == "UP" then
        return "BOTTOMLEFT"
    elseif growDirection == "CENTER_HORIZONTAL" then
        return "LEFT"
    elseif growDirection == "CENTER_VERTICAL" then
        return "TOP"
    end
    return "TOPLEFT"
end

local function GetAuraTrackingContainerAnchorPoint(settings)
    local growDirection = settings and settings.GrowDirection
    if growDirection == "CENTER_HORIZONTAL" or growDirection == "CENTER_VERTICAL" then
        return "CENTER"
    end
    return GetAuraTrackingLayoutAnchorPoint(settings)
end

local function GetAuraTrackingLayoutAxis(settings)
    local growDirection = settings and settings.GrowDirection or "RIGHT"
    if growDirection == "UP" or growDirection == "DOWN" or growDirection == "CENTER_VERTICAL" then
        return AnchorUtil.FlowLayoutAxis.Vertical
    end
    return AnchorUtil.FlowLayoutAxis.Horizontal
end

local function GetAuraTrackingFrameStrata(settings)
    local strata = settings and settings.FrameStrata
    if strata == "BACKGROUND" or strata == "LOW" or strata == "MEDIUM" or strata == "HIGH" or strata == "DIALOG" or strata == "FULLSCREEN" or strata == "FULLSCREEN_DIALOG" or strata == "TOOLTIP" then
        return strata
    end
    return "MEDIUM"
end

NSI.DefaultExternalAuraTrackingSpellIDs = {
    6940, -- Blessing of Sacrifice
    47788, -- Guardian Spirit 1
    255312, -- Guardian Spirit 2
    102342, -- Ironbark
    116849, -- Life Cocoon
    357170, -- Time Dilation
    53480, -- Roar of Sacrifice
    33206, -- Pain Suppression
}

NSI.DefaultExternalAuraTrackingImmunitySpellIDs = {
    1022, -- Blessing of Protection
    204018, -- Blessing of Spellwarding
    642, -- Divine Shield
    186265, -- Turtle
    196555, -- Netherwalk
    31224, -- Cloak of Shadows
    45438, -- Ice Block
}

NSI.DefaultPlayerAuraTrackingSpellIDs = {}

function NSI:CreateAuraTrackingSettingsDefaults(overrides)
    local settings = {
        Spacing = -1,
        Limit = 10,
        AurasPerRowColumn = 20,
        GridGrowDirection = "UP",
        GridSpacing = -1,
        GrowDirection = "RIGHT",
        enabled = false,
        Width = 100,
        Height = 100,
        Zoom = 25,
        Anchor = "CENTER",
        relativeTo = "CENTER",
        CustomAnchorFrame = "UIParent",
        xOffset = -238,
        yOffset = 314,
        FrameStrata = "MEDIUM",
        BorderSize = 1,
        BorderColor = {0, 0, 0, 1},
        BorderSwipeMode = "Static",
        DispelBorderMode = "ColoredWithIcon",
        DispelBorderSize = 3,
        HideTooltip = false,
        HideDurationText = false,
        ShowWhitelistedPlayerBuffs = false,
        HideStackText = false,
        EnableCooldownSwipe = true,
        InverseCooldownSwipe = true,
        DurationColor = {1, 1, 0.25, 1},
        ShowDecimalSeconds = false,
        DecimalThreshold = 3,
        ColorDurationUnderThreshold = false,
        ColorDurationThreshold = 3,
        DurationThresholdColor = {1, 0, 0, 1},
        StackColor = {1, 1, 1, 1},
        DurationFontSize = 32,
        StackFontSize = 32,
        TextFont = "Expressway",
        TextFontFlags = "OUTLINE",
        DurationXOffset = 0,
        DurationYOffset = 0,
        StackXOffset = -1,
        StackYOffset = 1,
        NameEnabled = false,
        NamePosition = "TOP",
        NameXOffset = 0,
        NameYOffset = 4,
        NameFontSize = 30,
        TrackingMode = "SpellIDs",
        SpellIDPlayerFilter = "Disabled",
        SpellIDs = {},
        SpellIDsEdited = false,
        AuraFilters = {},
        CandidateFilters = {},
        PreviewSpellID = nil,
        SortMode = "AuraInstanceID",
        Unit = "player",
        UnitType = "Automatic",
        OnlyShowFirstTank = false,
        MultiTankGrow = "Same",
        loadConditions = { Roles = {}, Classes = {}, SpecIDs = {}, Names = {}, EncounterIDs = {} },
    }
    for key, value in pairs(overrides or {}) do
        settings[key] = value
    end
    return settings
end

-- Reserved, always-present group that holds the locked built-in displays.
NSI.AuraTrackingBuiltinGroup = "Built-in"

-- Metadata for the three locked built-in displays. Order drives list display.
NSI.AuraTrackingBuiltins = {
    { key = "Player",   name = "Player Debuffs" },
    { key = "Tank",     name = "Co-Tank Debuffs" },
    { key = "External", name = "External & Immunity" },
}

local function ResolveAuraTrackingCustomUnitType(settings, unit)
    local unitType = settings and settings.UnitType or "Automatic"
    if unitType == "Friendly" or unitType == "Enemy" then
        return unitType
    end

    unit = unit and strtrim(tostring(unit)) or "player"
    if unit == "" then unit = "player" end
    local lower = string.lower(unit)
    if lower == "player" or lower == "pet" or lower == "cotank" or lower:match("^party%d*$") or lower:match("^raid%d*$") then
        return "Friendly"
    end
    return "Enemy"
end

local function GetAuraTrackingUnitCanAssist(unit, requiresAssist)
    if requiresAssist and UnitIsPlayerControlledOrGroupMember(unit) then
        return true
    end
    return UnitCanAssist("player", unit, true, true)
end

local function IsAuraTrackingStaticUnit(unit)
    unit = unit and strtrim(tostring(unit)) or ""
    if unit == "" then return true end
    local lower = string.lower(unit)
    return lower == "player"
        or lower == "pet"
        or lower == "target"
        or lower == "targettarget"
        or lower == "focus"
        or lower == "focustarget"
        or lower == "mouseover"
        or lower == "cotank"
        or lower:match("^raid%d+$")
        or lower:match("^party%d+$")
        or lower:match("^boss%d+$")
end

local function ResolveAuraTrackingUnit(self, settings)
    local unit = settings and settings.Unit and strtrim(tostring(settings.Unit)) or "player"
    if unit == "" then unit = "player" end
    local lower = string.lower(unit)

    if lower == "cotank" then
        return self:GetCoTankUnits()[1], true
    end

    if IsAuraTrackingStaticUnit(unit) then
        return lower, false
    end

    return self:ResolveGroupMemberUnit(unit), true
end

local function GetAuraTrackingCustomFrameLimit(settings, unit)
    local limit = settings and settings.Limit or 0
    local wantedUnitType = ResolveAuraTrackingCustomUnitType(settings, unit)
    unit = unit and strtrim(tostring(unit)) or ""
    if unit ~= "" and UnitExists(unit) then
        local currentUnitType = GetAuraTrackingUnitCanAssist(unit, wantedUnitType == "Friendly") and "Friendly" or "Enemy"
        if currentUnitType ~= wantedUnitType then
            return 0
        end
    end
    return limit
end

-- Canonical UI refresh hook. The Aura Tracking UI wires _RefreshAuraTrackingUI
-- when it is built; before that (or outside Midnight) this is a safe no-op.
function NSI:RefreshAuraTrackingUI()
    if self._RefreshAuraTrackingUI then
        self._RefreshAuraTrackingUI()
    end
end

-- Ordered list of every tracking entry: built-ins first (in defined order),
-- then custom entries. Each item: { settingsKey, settings, builtin, group }.
function NSI:IterateAuraTrackingEntries()
    local list = {}
    local root = NSRT.AuraTrackingSettings
    if not root then return list end
    for _, info in ipairs(NSI.AuraTrackingBuiltins) do
        local settings = root[info.key]
        if settings then
            list[#list + 1] = {
                settingsKey = info.key,
                settings = settings,
                builtin = info.key,
                group = NSI.AuraTrackingBuiltinGroup,
            }
        end
    end
    for index, settings in ipairs(root.Custom or {}) do
        list[#list + 1] = {
            settingsKey = "Custom:" .. index,
            settings = settings,
            builtin = nil,
            group = settings.group,
        }
    end
    return list
end

function NSI:GetAuraTrackingGroupCollapsed(name)
    local groups = NSRT.AuraTrackingSettings and NSRT.AuraTrackingSettings.Groups
    return (groups and groups[name] and groups[name].collapsed) or false
end

function NSI:SetAuraTrackingGroupCollapsed(name, collapsed)
    local root = NSRT.AuraTrackingSettings
    if not root then return end
    root.Groups = root.Groups or {}
    root.Groups[name] = root.Groups[name] or {}
    root.Groups[name].collapsed = collapsed and true or false
end

-- Sorted user group names (excludes the reserved Built-in group).
function NSI:GetAuraTrackingGroups()
    local names = {}
    local root = NSRT.AuraTrackingSettings
    if not root then return names end
    local seen = {}
    for name in pairs(root.Groups or {}) do
        if name ~= NSI.AuraTrackingBuiltinGroup then seen[name] = true end
    end
    for _, settings in ipairs(root.Custom or {}) do
        if settings.group and settings.group ~= "" then seen[settings.group] = true end
    end
    for name in pairs(seen) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function NSI:AddAuraTrackingGroup(name)
    name = strtrim(tostring(name or ""))
    if name == "" or name == NSI.AuraTrackingBuiltinGroup then return end
    local root = NSRT.AuraTrackingSettings
    if not root then return end
    root.Groups = root.Groups or {}
    root.Groups[name] = root.Groups[name] or { collapsed = false }
    self:RefreshAuraTrackingUI()
    return name
end

function NSI:RenameAuraTrackingGroup(oldName, newName)
    if not oldName or oldName == self.AuraTrackingBuiltinGroup then return end
    local root = NSRT.AuraTrackingSettings
    if not root then return end
    newName = strtrim(tostring(newName or ""))
    if newName == "" or newName == self.AuraTrackingBuiltinGroup or newName == oldName then return end
    if root.Groups and root.Groups[newName] then return end
    for _, settings in ipairs(root.Custom or {}) do
        if settings.group == newName then return end
    end

    root.Groups = root.Groups or {}
    root.Groups[newName] = root.Groups[oldName] or { collapsed = false }
    root.Groups[oldName] = nil
    for _, settings in ipairs(root.Custom or {}) do
        if settings.group == oldName then
            settings.group = newName
        end
    end
    self:RefreshAuraTrackingUI()
end

function NSI:SetAuraTrackingEntryGroup(settingsKey, groupName)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings or settings.builtin then return end
    groupName = groupName and strtrim(tostring(groupName)) or ""
    settings.group = (groupName ~= "" and groupName ~= NSI.AuraTrackingBuiltinGroup) and groupName or nil
    settings.GroupOrder = nil
    if settings.group then
        local root = NSRT.AuraTrackingSettings
        root.Groups = root.Groups or {}
        root.Groups[settings.group] = root.Groups[settings.group] or { collapsed = false }
    end
    self:RefreshAuraTrackingUI()
end

local function GetOrderedAuraTrackingGroupEntries(groupName)
    local entries = {}
    for index, settings in ipairs((NSRT.AuraTrackingSettings and NSRT.AuraTrackingSettings.Custom) or {}) do
        if settings.group == groupName then
            entries[#entries + 1] = { settings = settings, index = index }
        end
    end
    table.sort(entries, function(a, b)
        local aOrder = a.settings.GroupOrder or math.huge
        local bOrder = b.settings.GroupOrder or math.huge
        if aOrder ~= bOrder then return aOrder < bOrder end
        return a.index < b.index
    end)
    return entries
end

function NSI:MoveAuraTrackingEntry(settingsKey, direction)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings or not settings.group or settings.builtin then return end

    local entries = GetOrderedAuraTrackingGroupEntries(settings.group)
    local currentIndex
    for index, entry in ipairs(entries) do
        if entry.settings == settings then
            currentIndex = index
            break
        end
    end
    if not currentIndex then return end

    local targetIndex = currentIndex + (direction == "up" and -1 or 1)
    if targetIndex < 1 or targetIndex > #entries then return end
    entries[currentIndex], entries[targetIndex] = entries[targetIndex], entries[currentIndex]
    for index, entry in ipairs(entries) do
        entry.settings.GroupOrder = index
    end
    self:RefreshAuraTrackingUI()
end

function NSI:DuplicateAuraTrackingGroup(groupName)
    if not groupName then return end
    local root = NSRT.AuraTrackingSettings
    root.Custom = root.Custom or {}
    root.Groups = root.Groups or {}

    local newName = groupName .. NSI:Loc("DUPLICATE_SUFFIX")
    local suffix = 2
    local function GroupNameExists(name)
        if root.Groups[name] then return true end
        for _, settings in ipairs(root.Custom) do
            if settings.group == name then return true end
        end
        return false
    end
    while GroupNameExists(newName) do
        newName = groupName .. NSI:Loc("DUPLICATE_SUFFIX") .. " " .. suffix
        suffix = suffix + 1
    end

    root.Groups[newName] = { collapsed = false }
    for order, entry in ipairs(GetOrderedAuraTrackingGroupEntries(groupName)) do
        local settings = CopyTable(entry.settings)
        settings.builtin = nil
        settings.pinned = nil
        settings.group = newName
        settings.GroupOrder = order
        root.Custom[#root.Custom + 1] = settings
    end
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
    return newName
end

-- Delete a user group. Entries either become ungrouped (keepEntries) or are
-- removed (not keepEntries). The Built-in group cannot be deleted.
function NSI:DeleteAuraTrackingGroup(name, keepEntries)
    if not name or name == NSI.AuraTrackingBuiltinGroup then return end
    local root = NSRT.AuraTrackingSettings
    if not root then return end
    if keepEntries then
        for _, settings in ipairs(root.Custom or {}) do
            if settings.group == name then
                settings.group = nil
                settings.GroupOrder = nil
            end
        end
    else
        for index = #(root.Custom or {}), 1, -1 do
            if root.Custom[index].group == name then
                table.remove(root.Custom, index)
            end
        end
    end
    if root.Groups then root.Groups[name] = nil end
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
end

-- Enable/disable every entry in a group (Built-in group toggles the built-ins).
function NSI:SetAuraTrackingGroupEnabled(name, enabled)
    for _, item in ipairs(self:IterateAuraTrackingEntries()) do
        if item.group == name then
            item.settings.enabled = enabled and true or false
        end
    end
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
end

function NSI:SetAuraTrackingPinned(settingsKey, pinned)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    settings.pinned = pinned and true or nil
    self:RefreshAuraTrackingUI()
end

-- Duplicate any entry into a new custom entry (deep copy, fresh name).
function NSI:DuplicateCustomAuraTracking(settingsKey)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    NSRT.AuraTrackingSettings.Custom = NSRT.AuraTrackingSettings.Custom or {}
    local copy = CopyTable(settings)
    copy.builtin = nil
    copy.pinned = nil
    copy.GroupOrder = nil
    copy.Name = (settings.Name or "Aura") .. NSI:Loc("DUPLICATE_SUFFIX")
    local index = #NSRT.AuraTrackingSettings.Custom + 1
    NSRT.AuraTrackingSettings.Custom[index] = copy
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
    return "Custom:" .. index
end

-- ── Section copy / paste ────────────────────────────────────────────────────
-- Trigger/Load and Display use explicit field lists so identity and activation
-- state are never copied accidentally. Display fields are listed below
-- alongside the settings defaults.
local AuraTrackingSectionFields = {
    Trigger = { "TrackingMode", "SpellIDPlayerFilter", "SpellIDs", "SpellIDsEdited", "AuraFilters", "CandidateFilters", "Unit", "UnitType", "PreviewSpellID" },
    Load    = { "loadConditions" },
}

local AuraTrackingDisplayFields = {
    "Spacing", "Limit", "AurasPerRowColumn", "GridGrowDirection", "GridSpacing", "GrowDirection", "Width", "Height", "Zoom",
    "Anchor", "relativeTo", "CustomAnchorFrame", "xOffset", "yOffset",
    "FrameStrata", "BorderSize", "BorderColor", "BorderSwipeMode", "DispelBorderMode", "DispelBorderSize",
    "HideTooltip", "HideDurationText", "HideLongDurationAuras", "ShowWhitelistedPlayerBuffs", "IncludeImmunities", "HideStackText",
    "EnableCooldownSwipe", "InverseCooldownSwipe", "SortMode",
    "DurationColor", "ShowDecimalSeconds", "DecimalThreshold", "ColorDurationUnderThreshold", "ColorDurationThreshold", "DurationThresholdColor",
    "StackColor", "DurationFontSize", "StackFontSize",
    "TextFont", "TextFontFlags", "DurationXOffset", "DurationYOffset", "StackXOffset", "StackYOffset",
    "NameEnabled", "NamePosition", "NameXOffset", "NameYOffset", "NameFontSize",
    "OnlyShowFirstTank",
    "MultiTankGrow", "MultiTankXOffset", "MultiTankYOffset",
}

local function CopyAuraTrackingValue(v)
    if type(v) == "table" then return CopyTable(v) end
    return v
end

function NSI:CopyAuraTrackingSection(settingsKey, section)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    local data = {}
    if section == "Display" then
        for _, key in ipairs(AuraTrackingDisplayFields) do
            data[key] = CopyAuraTrackingValue(settings[key])
        end
    else
        local fields = AuraTrackingSectionFields[section]
        if not fields then return end
        for _, key in ipairs(fields) do
            data[key] = CopyAuraTrackingValue(settings[key])
        end
    end
    self._AuraTrackingSectionClipboard = { section = section, data = data }
end

function NSI:CanPasteAuraTrackingSection(section)
    local clip = self._AuraTrackingSectionClipboard
    return clip ~= nil and clip.section == section
end

function NSI:PasteAuraTrackingSection(settingsKey, section)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    local clip = self._AuraTrackingSectionClipboard
    if not settings or not clip or clip.section ~= section then return end
    for key, value in pairs(clip.data) do
        settings[key] = CopyAuraTrackingValue(value)
    end
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
end

local AuraTrackingPreviewData = {
    Player = {
        frameKey = "AuraTrackingPlayerPreviewMover",
        iconKey = "AuraTrackingPlayerPreviewIcons",
        timerKey = "AuraTrackingPlayerPreviewTimer",
        texture = 237555,
        unit = "player",
        previewSpellIDs = {1241058, 474545, 1308113, 1300503, 397077, 1238247, 1238084, 373692, 1216571, 1222103, 1246957},
    },
    Tank = {
        frameKey = "AuraTrackingTankPreviewMover",
        iconKey = "AuraTrackingTankPreviewIcons",
        timerKey = "AuraTrackingTankPreviewTimer",
        secondFrameKey = "AuraTrackingTankPreviewMover2",
        secondIconKey = "AuraTrackingTankPreviewIcons2",
        texture = 236318,
        unit = "player",
        previewSpellIDs = {1291929, 1295858, 1280934, 1303230, 1282873, 1277051},
    },
    External = {
        frameKey = "AuraTrackingExternalPreviewMover",
        iconKey = "AuraTrackingExternalPreviewIcons",
        timerKey = "AuraTrackingExternalPreviewTimer",
        texture = C_Spell.GetSpellTexture(6940) or 135966,
        unit = "player",
    },
}

local AuraTrackingPreviewNonMagicDispelTypes = {
    "Curse",
    "Disease",
    "Poison",
    "Bleed",
}

local AuraTrackingPreviewDispelTypes = {
    "Magic",
    "Curse",
    "Disease",
    "Poison",
    "Bleed",
}

local function GetAuraTrackingPreviewData(key)
    if AuraTrackingPreviewData[key] then
        return AuraTrackingPreviewData[key]
    end

    local customIndex = tostring(key or ""):match("^Custom:(%d+)$")
    if customIndex then
        return {
            frameKey = "AuraTrackingCustom" .. customIndex .. "PreviewMover",
            iconKey = "AuraTrackingCustom" .. customIndex .. "PreviewIcons",
            timerKey = "AuraTrackingCustom" .. customIndex .. "PreviewTimer",
            secondFrameKey = "AuraTrackingCustom" .. customIndex .. "PreviewMover2",
            secondIconKey = "AuraTrackingCustom" .. customIndex .. "PreviewIcons2",
            texture = 136076,
            unit = "player",
        }
    end
end

local function StopAuraTrackingPreviewTimer(self, key)
    local previewData = GetAuraTrackingPreviewData(key)
    if not previewData then return end
    local timerKey = previewData.timerKey
    if self[timerKey] then
        self[timerKey]:Cancel()
        self[timerKey] = nil
    end
end

function NSI:GetAuraTrackingSettings(settingsKey)
    if not NSRT.AuraTrackingSettings then return end
    local customIndex = tostring(settingsKey or ""):match("^Custom:(%d+)$")
    if customIndex then
        return NSRT.AuraTrackingSettings.Custom and NSRT.AuraTrackingSettings.Custom[tonumber(customIndex)]
    end
    return NSRT.AuraTrackingSettings[settingsKey]
end

local AuraTrackingDurationFormatterCache = setmetatable({}, {__mode = "k"})

local function GetAuraTrackingDurationFormatter(settings)
    local decimalEnabled = settings.ShowDecimalSeconds == true
    local decimalThreshold = decimalEnabled and math.min(math.max(tonumber(settings.DecimalThreshold) or 3, 0.1), 59.9) or 0
    local cache = AuraTrackingDurationFormatterCache[settings]
    if cache and cache.decimalEnabled == decimalEnabled and cache.decimalThreshold == decimalThreshold then
        return cache.formatter
    end

    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    if decimalEnabled then
        formatter:SetBreakpoints({
            {
                threshold = 60,
                rounding = Enum.NumericRuleFormatRounding.Down,
                format = "%dm",
                components = {
                    {
                        div = 60,
                        step = 1,
                        rounding = Enum.NumericRuleFormatRounding.Down,
                    },
                },
            },
            {
                threshold = decimalThreshold,
                step = 1,
                rounding = Enum.NumericRuleFormatRounding.Up,
                format = "%d",
            },
            {
                threshold = 0,
                step = 0.1,
                rounding = Enum.NumericRuleFormatRounding.Up,
                format = "%.1f",
            },
        })
    else
        formatter:SetBreakpoints({
            {
                threshold = 60,
                rounding = Enum.NumericRuleFormatRounding.Down,
                format = "%dm",
                components = {
                    {
                        div = 60,
                        step = 1,
                        rounding = Enum.NumericRuleFormatRounding.Down,
                    },
                },
            },
            {
                threshold = 0,
                step = 1,
                rounding = Enum.NumericRuleFormatRounding.Up,
                format = "%d",
            },
        })
    end
    AuraTrackingDurationFormatterCache[settings] = {
        decimalEnabled = decimalEnabled,
        decimalThreshold = decimalThreshold,
        formatter = formatter,
    }
    return formatter
end

local function GetAuraTrackingDurationTextColor(settings)
    if not settings.ColorDurationUnderThreshold then return end
    local threshold = math.min(math.max(tonumber(settings.ColorDurationThreshold) or 3, 0.1), 59.9)
    local cache = AuraTrackingDurationFormatterCache[settings]
    local normalColor = settings.DurationColor or {1, 1, 0.25, 1}
    local thresholdColor = settings.DurationThresholdColor or {1, 0, 0, 1}
    if cache and cache.colorThreshold == threshold
        and cache.normalColor == normalColor and cache.thresholdColor == thresholdColor then
        return cache.textColor
    end

    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    curve:AddPoint(0, CreateColor(thresholdColor[1], thresholdColor[2], thresholdColor[3], thresholdColor[4] or 1))
    curve:AddPoint(threshold, CreateColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4] or 1))
    local textColor = {
        curve = curve,
        property = Enum.DurationTextBindingProperty.RemainingDuration,
    }
    cache = cache or { formatter = GetAuraTrackingDurationFormatter(settings) }
    cache.colorThreshold = threshold
    cache.normalColor = normalColor
    cache.thresholdColor = thresholdColor
    cache.textColor = textColor
    AuraTrackingDurationFormatterCache[settings] = cache
    return textColor
end

local function FormatAuraTrackingDuration(seconds, settings)
    seconds = tonumber(seconds) or 0
    if settings.ShowDecimalSeconds and seconds < math.max(tonumber(settings.DecimalThreshold) or 3, 0.1) then
        return string.format("%.1f", seconds)
    end
    if seconds >= 60 then
        return string.format("%dm", math.max(1, math.floor(seconds / 60)))
    end
    return tostring(math.ceil(seconds))
end

local function ParseAuraTrackingSpellIDs(value)
    local spellIDs = {}
    local seen = {}
    if type(value) == "table" then
        for _, spellID in ipairs(value) do
            spellID = tonumber(spellID)
            if spellID and not seen[spellID] then
                spellIDs[#spellIDs + 1] = spellID
                seen[spellID] = true
            end
        end
    else
        for token in tostring(value or ""):gmatch("%d+") do
            local spellID = tonumber(token)
            if spellID and not seen[spellID] then
                spellIDs[#spellIDs + 1] = spellID
                seen[spellID] = true
            end
        end
    end
    table.sort(spellIDs)
    return spellIDs
end

local function GetAuraTrackingSpellIDs(settings, settingsKey)
    if tostring(settingsKey or ""):match("^Custom:") then
        return ParseAuraTrackingSpellIDs(settings and settings.SpellIDs)
    end
    if settingsKey == "External" then
        local spellIDs = ParseAuraTrackingSpellIDs(NSI.DefaultExternalAuraTrackingSpellIDs)
        if not settings or settings.IncludeImmunities then
            local seen = {}
            for _, spellID in ipairs(spellIDs) do
                seen[spellID] = true
            end
            for _, spellID in ipairs(ParseAuraTrackingSpellIDs(NSI.DefaultExternalAuraTrackingImmunitySpellIDs)) do
                if not seen[spellID] then
                    spellIDs[#spellIDs + 1] = spellID
                    seen[spellID] = true
                end
            end
            table.sort(spellIDs)
        end
        return spellIDs
    end
    if settingsKey == "PlayerBuffWhitelist" then
        return ParseAuraTrackingSpellIDs(NSI.DefaultPlayerAuraTrackingSpellIDs)
    end
    return {}
end

local function AuraTrackingWantsDispelBorder(settings, key)
    return key ~= "External" and settings and settings.DispelBorderMode ~= "None"
end

local function AuraTrackingUsesCustomDispelBorder(settings)
    return settings.DispelBorderMode == "Colored" or settings.DispelBorderMode == "ColoredWithIcon"
end

local function AuraTrackingUsesCustomDispelIcon(settings)
    return settings.DispelBorderMode == "ColoredWithIcon" or settings.DispelBorderMode == "IconOnly"
end

local AuraTrackingDispelBorderColors
local function GetAuraTrackingDispelBorderColors()
    if not AuraTrackingDispelBorderColors then
        AuraTrackingDispelBorderColors = {}
        for _, dispelType in ipairs(NSI.AuraTrackingCandidateDispelTypes) do
            AuraTrackingDispelBorderColors[dispelType] = AuraUtil.GetAuraBorderColor(dispelType)
        end
    end
    return AuraTrackingDispelBorderColors
end

local function HideAuraTrackingDispelRegions(regions)
    if not regions then return end
    if regions.dispelOverlay then regions.dispelOverlay:Hide() end
    if regions.customDispelBorder then
        for _, texture in pairs(regions.customDispelBorder) do texture:Hide() end
    end
    if regions.customDispelIcon then regions.customDispelIcon:Hide() end
    if regions.dispelSymbol then regions.dispelSymbol:Hide() end
end

local function HideAuraTrackingPreviewDispelRegions(frame)
    if not frame then return end
    if frame.DispelOverlay then frame.DispelOverlay:Hide() end
    if frame.CustomDispelBorder then
        for _, texture in pairs(frame.CustomDispelBorder) do texture:Hide() end
    end
    if frame.CustomDispelIcon then frame.CustomDispelIcon:Hide() end
end

local function GetAuraTrackingSpellIDMap(settings, settingsKey)
    local spellIDs = GetAuraTrackingSpellIDs(settings, settingsKey)
    if #spellIDs == 0 then return end

    local map = {}
    for _, spellID in ipairs(spellIDs) do
        map[spellID] = true
    end
    return map
end

local function BuildAuraTrackingCustomFilterString(settings)
    local filters = settings and settings.AuraFilters
    if type(filters) ~= "table" then return end

    local parts = {}
    for _, filter in ipairs(NSI.AuraTrackingFilterDefinitions) do
        local state = filters[filter.key]
        if state == nil then
            state = filters[filter.value]
        end
        if type(state) == "string" then
            state = strtrim(state)
            local lower = string.lower(state)
            if lower == "enabled" then
                state = "Enabled"
            elseif lower == "inverted" or lower == "negated" or lower == "inverse" then
                state = "Inverted"
            end
        end
        if state == "Enabled" or state == true then
            parts[#parts + 1] = filter.value
        elseif state == "Inverted" then
            parts[#parts + 1] = "!" .. filter.value
        end
    end

    if #parts == 0 then return end
    return table.concat(parts, "|")
end

local function BuildAuraTrackingCandidateFilters(settings)
    local configured = settings and settings.CandidateFilters
    local candidateFilters = {}

    if type(configured) == "table" then
        local spellIDs = ParseAuraTrackingSpellIDs(configured.ExcludeSpellIDs)
        if #spellIDs > 0 then
            candidateFilters.excludeSpellIDs = {}
            for _, spellID in ipairs(spellIDs) do
                candidateFilters.excludeSpellIDs[spellID] = true
            end
        end

        local dispelTypes = configured.DispelTypes
        if type(dispelTypes) == "table" then
            for _, dispelType in ipairs(NSI.AuraTrackingCandidateDispelTypes) do
                if dispelTypes[dispelType] == "Enabled" then
                    candidateFilters.includeDispelTypes = candidateFilters.includeDispelTypes or {}
                    candidateFilters.includeDispelTypes[dispelType] = true
                elseif dispelTypes[dispelType] == "Inverted" then
                    candidateFilters.excludeDispelTypes = candidateFilters.excludeDispelTypes or {}
                    candidateFilters.excludeDispelTypes[dispelType] = true
                end
            end
        end

        if type(configured.MaxDuration) == "number" then
            candidateFilters.maxDuration = configured.MaxDuration
        end

        if configured.ProcessedAuraType and configured.ProcessedAuraType ~= "Disabled" then
            candidateFilters.processedAuraType = AuraUtil.AuraUpdateChangedType[configured.ProcessedAuraType]
        end

        for _, filter in ipairs(NSI.AuraTrackingCandidateFilterDefinitions) do
            local state = configured[filter.key]
            if state == "Enabled" or state == true then
                candidateFilters[filter.key] = true
            elseif state == "Inverted" or state == false then
                candidateFilters[filter.key] = false
            end
        end
    end

    return candidateFilters
end

function NSI:GetAuraTrackingSpellIDList(settingsKey)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    return GetAuraTrackingSpellIDs(settings, settingsKey)
end

-- Accepts a single spell ID or a comma/space separated list of spell IDs and
-- merges any newly-valid ones into the entry's existing SpellIDs.
function NSI:AddAuraTrackingSpellIDs(settingsKey, value)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    local newIDs = ParseAuraTrackingSpellIDs(value)
    if #newIDs == 0 then return end
    settings.SpellIDs = settings.SpellIDs or {}
    local seen = {}
    for _, id in ipairs(settings.SpellIDs) do seen[id] = true end
    for _, id in ipairs(newIDs) do
        if not seen[id] then
            settings.SpellIDs[#settings.SpellIDs + 1] = id
            seen[id] = true
        end
    end
    table.sort(settings.SpellIDs)
    settings.SpellIDsEdited = true
    self:UpdateAuraTrackingDisplay(settingsKey)
end

function NSI:RemoveAuraTrackingSpellID(settingsKey, spellID)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings or not settings.SpellIDs then return end
    spellID = tonumber(spellID)
    for i, id in ipairs(settings.SpellIDs) do
        if id == spellID then
            table.remove(settings.SpellIDs, i)
            break
        end
    end
    settings.SpellIDsEdited = true
    self:UpdateAuraTrackingDisplay(settingsKey)
end

function NSI:SetAuraTrackingPreviewSpellID(settingsKey, value)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    settings.PreviewSpellID = tonumber(value) or nil
    self:RefreshAuraTrackingUI()
end

function NSI:SetAuraTrackingCustomName(settingsKey, value)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    value = strtrim(tostring(value or ""))
    settings.Name = value ~= "" and value or nil
    self:RefreshAuraTrackingUI()
end

function NSI:AddCustomAuraTracking(group)
    NSRT.AuraTrackingSettings.Custom = NSRT.AuraTrackingSettings.Custom or {}
    local index = #NSRT.AuraTrackingSettings.Custom + 1
    group = group and strtrim(tostring(group)) or ""
    if group == "" or group == NSI.AuraTrackingBuiltinGroup then group = nil end
    NSRT.AuraTrackingSettings.Custom[index] = self:CreateAuraTrackingSettingsDefaults({
        Name = NSI:Loc("Custom Aura Tracking") .. " " .. index,
        xOffset = 0,
        yOffset = 0,
        HideTooltip = true,
        DispelBorderMode = "ColoredWithIcon",
        SpellIDsEdited = true,
        group = group,
    })
    if group then
        NSRT.AuraTrackingSettings.Groups = NSRT.AuraTrackingSettings.Groups or {}
        NSRT.AuraTrackingSettings.Groups[group] = NSRT.AuraTrackingSettings.Groups[group] or { collapsed = false }
    end
    local settingsKey = "Custom:" .. index
    NSRT.AuraTrackingSettings.UI = NSRT.AuraTrackingSettings.UI or {}
    NSRT.AuraTrackingSettings.UI.Selected = settingsKey
    self:RefreshAuraTrackingUI()
    return settingsKey
end

function NSI:StopAllAuraTrackingPreviews()
    local previewKeys = {
        Player = true,
        Tank = true,
        External = true,
    }
    for index in ipairs((NSRT.AuraTrackingSettings and NSRT.AuraTrackingSettings.Custom) or {}) do
        previewKeys["Custom:" .. index] = true
    end
    for fieldName in pairs(self) do
        local suffix = fieldName:match("^IsAuraTracking(.+)Preview$")
        local customIndex = suffix and suffix:match("^Custom(%d+)$")
        if customIndex then
            previewKeys["Custom:" .. customIndex] = true
        end
    end

    for key in pairs(previewKeys) do
        local previewData = GetAuraTrackingPreviewData(key)
        local previewFlag = "IsAuraTracking" .. tostring(key):gsub(":", "") .. "Preview"
        self[previewFlag] = false
        StopAuraTrackingPreviewTimer(self, key)
        if previewData and self[previewData.frameKey] then
            self[previewData.frameKey]:Hide()
        end
        if previewData and self[previewData.iconKey] then
            for _, icon in ipairs(self[previewData.iconKey]) do
                icon:Hide()
            end
        end
        if previewData and previewData.secondFrameKey and self[previewData.secondFrameKey] then
            self[previewData.secondFrameKey]:Hide()
        end
        if previewData and previewData.secondIconKey and self[previewData.secondIconKey] then
            for _, icon in ipairs(self[previewData.secondIconKey]) do
                icon:Hide()
            end
        end
    end

    self:InitAuraTracking()
end

function NSI:DeleteCustomAuraTracking(settingsKey)
    local customIndex = tonumber(tostring(settingsKey or ""):match("^Custom:(%d+)$"))
    if not customIndex or not NSRT.AuraTrackingSettings.Custom then return end
    self:PreviewAuraTracking(settingsKey, false)
    table.remove(NSRT.AuraTrackingSettings.Custom, customIndex)
    NSRT.AuraTrackingSettings.UI = NSRT.AuraTrackingSettings.UI or {}
    NSRT.AuraTrackingSettings.UI.Selected = "Player"
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
end

local AuraTrackingBuiltinKeys = {
    Player = true,
    Tank = true,
    External = true,
}

local function NormalizeAuraTrackingImport(settings, builtinKey, groupName)
    if type(settings) ~= "table" then return end
    local data = CopyTable(settings)
    data.builtin = builtinKey or nil
    data.group = builtinKey and nil or groupName or data.group
    if builtinKey then
        for _, info in ipairs(NSI.AuraTrackingBuiltins) do
            if info.key == builtinKey then
                data.Name = data.Name or info.name
                break
            end
        end
    else
        data.Name = data.Name or "Imported Aura Tracking"
    end
    return NSI:CreateAuraTrackingSettingsDefaults(data)
end

function NSI:ExportAuraTrackingEntry(settingsKey)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return "" end
    local builtinKey = AuraTrackingBuiltinKeys[settingsKey] and settingsKey or nil
    return self:EncodeExportData({
        type = "NSRT_AURA_TRACKING",
        version = 1,
        entries = {
            {
                builtin = builtinKey,
                settings = CopyTable(settings),
            },
        },
    }, AuraTrackingSerializer) or ""
end

function NSI:ExportAuraTrackingGroup(groupName)
    if not groupName then return "" end
    local entries = {}
    for _, item in ipairs(self:IterateAuraTrackingEntries()) do
        if item.group == groupName then
            entries[#entries + 1] = {
                builtin = item.builtin,
                settings = CopyTable(item.settings),
            }
        end
    end
    if #entries == 0 then return "" end
    return self:EncodeExportData({
        type = "NSRT_AURA_TRACKING",
        version = 1,
        group = groupName,
        entries = entries,
    }, AuraTrackingSerializer) or ""
end

function NSI:ImportAuraTrackingString(text)
    local payload = self:DecodeExportData(text, AuraTrackingSerializer)
    if not payload or payload.type ~= "NSRT_AURA_TRACKING" or type(payload.entries) ~= "table" then
        return false
    end

    NSRT.AuraTrackingSettings = NSRT.AuraTrackingSettings or {}
    local root = NSRT.AuraTrackingSettings
    root.Custom = root.Custom or {}
    root.Groups = root.Groups or {}

    self:StopAllAuraTrackingPreviews()

    local groupName = payload.group and strtrim(tostring(payload.group)) or nil
    if groupName == "" or groupName == NSI.AuraTrackingBuiltinGroup then
        groupName = nil
    end

    if groupName then
        root.Groups[groupName] = root.Groups[groupName] or { collapsed = false }
    end

    local imported = 0
    for _, entry in ipairs(payload.entries) do
        local builtinKey = AuraTrackingBuiltinKeys[entry.builtin] and entry.builtin or nil
        local settings = NormalizeAuraTrackingImport(entry.settings, builtinKey, groupName)
        if settings then
            if builtinKey then
                root[builtinKey] = settings
            else
                root.Custom[#root.Custom + 1] = settings
            end
            imported = imported + 1
        end
    end

    if imported == 0 then return false end
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
    return true, imported
end

local function CreateAuraTrackingBorder(parent)
    local border = {
        top = parent:CreateTexture(nil, "OVERLAY"),
        bottom = parent:CreateTexture(nil, "OVERLAY"),
        left = parent:CreateTexture(nil, "OVERLAY"),
        right = parent:CreateTexture(nil, "OVERLAY"),
    }
    return border
end

local function IsAuraTrackingBorderFollowingSwipe(settings)
    return settings.BorderSwipeMode == "FollowSwipe"
end

local function UpdateAuraTrackingBorder(border, parent, size, color)
    if not border then return end
    size = size or 1
    color = color or {0, 0, 0, 1}
    local hidden = size <= 0
    for _, texture in pairs(border) do
        texture:ClearAllPoints()
        texture:SetColorTexture(unpack(color))
        texture:SetShown(not hidden)
    end
    if hidden then return end

    border.top:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    border.top:SetHeight(size)

    border.bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    border.bottom:SetHeight(size)

    border.left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    border.left:SetWidth(size)

    border.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    border.right:SetWidth(size)
end

local function UpdateAuraTrackingBorderLayer(frame, frameLevel, border, borderParent, size, color)
    frame:SetFrameLevel(frameLevel)
    if (size or 1) <= 0 then
        if border then
            for _, texture in pairs(border) do texture:Hide() end
        end
        return border, borderParent
    end
    if borderParent ~= frame then
        if border then
            for _, texture in pairs(border) do texture:Hide() end
        end
        border = CreateAuraTrackingBorder(frame)
    end
    UpdateAuraTrackingBorder(border, frame, size, color)
    return border, frame
end

local function AddAuraTrackingCustomDispelBorder(button, border)
    local options = {
        style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
        customDispelColorMap = GetAuraTrackingDispelBorderColors(),
        showWhenHarmful = true,
        showWhenHelpful = false,
    }
    for _, texture in pairs(border) do
        button:AddDispelTypeTexture(texture, options)
    end
end

local function PositionAuraTrackingUnitName(fontString, parent, settings)
    if not fontString then return end
    local position = settings.NamePosition or "TOP"
    local xOffset = settings.NameXOffset or 0
    local yOffset = settings.NameYOffset or 0

    fontString:ClearAllPoints()
    if position == "BOTTOM" then
        fontString:SetPoint("TOP", parent, "BOTTOM", xOffset, yOffset)
        fontString:SetJustifyH("CENTER")
    elseif position == "LEFT" then
        fontString:SetPoint("RIGHT", parent, "LEFT", xOffset, yOffset)
        fontString:SetJustifyH("RIGHT")
    elseif position == "RIGHT" then
        fontString:SetPoint("LEFT", parent, "RIGHT", xOffset, yOffset)
        fontString:SetJustifyH("LEFT")
    else
        fontString:SetPoint("BOTTOM", parent, "TOP", xOffset, yOffset)
        fontString:SetJustifyH("CENTER")
    end
    fontString:SetJustifyV("MIDDLE")
end

local AURA_TRACKING_FRAME_ANCHOR_PREFIX = "NSRT:AuraFrame:"

local function GetAuraTrackingNamedAnchor(self, frameName, excludedFrame)
    if type(frameName) ~= "string" or frameName:sub(1, #AURA_TRACKING_FRAME_ANCHOR_PREFIX) ~= AURA_TRACKING_FRAME_ANCHOR_PREFIX then
        return
    end

    local auraName = frameName:sub(#AURA_TRACKING_FRAME_ANCHOR_PREFIX + 1)
    if auraName == "" then return end

    for _, key in ipairs(self.AuraTrackingStateOrder or {}) do
        local state = self.AuraTrackingState and self.AuraTrackingState[key]
        if state and state.active and state.settings and state.settings.Name == auraName and state.anchorFrame and state.anchorFrame ~= excludedFrame then
            return state.anchorFrame
        end
    end
end

local function AuraTrackingNameExists(name)
    local settings = NSRT.AuraTrackingSettings
    if settings.Player and settings.Player.Name == name then return true end
    if settings.External and settings.External.Name == name then return true end
    if settings.Tank and settings.Tank.Name == name then return true end
    for _, entry in ipairs(settings.Custom or {}) do
        if entry.Name == name then return true end
    end
end

local function GetAuraTrackingAnchorFrame(self, settings, fallback, excludedFrame)
    local frameName = settings and settings.CustomAnchorFrame
    local auraFrame = GetAuraTrackingNamedAnchor(self, frameName, excludedFrame)
    if auraFrame then return auraFrame end
    local frame = frameName and frameName ~= "" and _G[frameName]
    if type(frame) == "table" and frame.GetCenter and frame.IsShown then
        return frame
    end
    return fallback or UIParent
end

function NSI:IsValidAuraTrackingAnchorFrame(frameName)
    if not frameName or frameName == "" then return true end
    if frameName:sub(1, #AURA_TRACKING_FRAME_ANCHOR_PREFIX) == AURA_TRACKING_FRAME_ANCHOR_PREFIX then
        return AuraTrackingNameExists(frameName:sub(#AURA_TRACKING_FRAME_ANCHOR_PREFIX + 1))
    end
    local frame = _G[frameName]
    return type(frame) == "table" and frame.GetCenter and frame.IsShown
end

local function SetAuraTrackingPoint(frame, settings, fallback)
    local relativeFrame = GetAuraTrackingAnchorFrame(NSI, settings, fallback, frame)
    frame:ClearAllPoints()
    frame:SetPoint(settings.Anchor or "CENTER", relativeFrame or fallback, settings.relativeTo or "CENTER", settings.xOffset or 0, settings.yOffset or 0)
end

-- Lightweight, position-only refresh of an active preview mover. Used while
-- live-scrubbing the X/Y-Offset sliders so the mover tracks every tick
-- without going through the full PreviewAuraTracking rebuild (which would
-- reset the preview icons' randomized durations/timer and cause flicker).
function NSI:RepositionAuraTrackingPreview(key)
    local previewData = GetAuraTrackingPreviewData(key)
    local settings = self:GetAuraTrackingSettings(key)
    if not previewData or not settings then return end
    local mover = self[previewData.frameKey]
    if not mover or not mover:IsShown() then return end
    SetAuraTrackingPoint(mover, settings, UIParent)
end

local function GetPointCoordinate(frame, point)
    if not frame or not point then return end
    local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not left or not right or not top or not bottom then return end

    local x
    if point:find("LEFT", 1, true) then
        x = left
    elseif point:find("RIGHT", 1, true) then
        x = right
    else
        x = (left + right) / 2
    end

    local y
    if point:find("TOP", 1, true) then
        y = top
    elseif point:find("BOTTOM", 1, true) then
        y = bottom
    else
        y = (top + bottom) / 2
    end

    return x, y
end

local function SaveAuraTrackingFramePosition(self, frame, settings)
    if not frame or not settings then return end
    local relativeFrame = GetAuraTrackingAnchorFrame(self, settings, UIParent, frame)
    local point = settings.Anchor or "CENTER"
    local relativePoint = settings.relativeTo or "CENTER"
    local frameX, frameY = GetPointCoordinate(frame, point)
    local relativeX, relativeY = GetPointCoordinate(relativeFrame, relativePoint)
    if not frameX or not relativeX then
        self:SaveFramePosition(frame, settings)
        return
    end

    settings.Anchor = point
    settings.relativeTo = relativePoint
    settings.xOffset = Round(frameX - relativeX)
    settings.yOffset = Round(frameY - relativeY)
end

-- Fires the UI's live-refresh hook (if the Aura Tracking window has one
-- registered) so the Display tab's Anchor/X-Offset/Y-Offset controls reflect
-- a drag in progress instead of only updating after the mouse is released.
local function NotifyAuraTrackingPreviewDragged(self, settingsKey)
    if self._OnAuraTrackingPreviewDragged then
        self._OnAuraTrackingPreviewDragged(settingsKey)
    end
end

local function MakeAuraTrackingDraggable(self, frame, settings, enable, settingsKey)
    if not frame then return end
    if not enable then
        self:MakeDraggable(frame, settings, false)
        return
    end

    self:MakeDraggable(frame, nil, true)
    frame:SetFrameStrata(GetAuraTrackingFrameStrata(settings))
    if frame.dragBorder then
        frame.dragBorder:SetFrameStrata(GetAuraTrackingFrameStrata(settings))
    end
    frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
        f._nsrtAuraTrackingDragElapsed = 0
        f._nsrtAuraTrackingUIElapsed = 0
        f:SetScript("OnUpdate", function(updateFrame, elapsed)
            updateFrame._nsrtAuraTrackingDragElapsed = (updateFrame._nsrtAuraTrackingDragElapsed or 0) + elapsed
            updateFrame._nsrtAuraTrackingUIElapsed = (updateFrame._nsrtAuraTrackingUIElapsed or 0) + elapsed
            if updateFrame._nsrtAuraTrackingDragElapsed >= 0.05 then
                updateFrame._nsrtAuraTrackingDragElapsed = 0
                SaveAuraTrackingFramePosition(self, updateFrame, settings)
            end
            -- Throttled slower than the position save itself so the Display
            -- tab isn't rebuilt from scratch 20x/sec while dragging.
            if updateFrame._nsrtAuraTrackingUIElapsed >= 0.15 then
                updateFrame._nsrtAuraTrackingUIElapsed = 0
                NotifyAuraTrackingPreviewDragged(self, settingsKey)
            end
        end)
    end)
    frame:SetScript("OnDragStop", function(f)
        f:SetScript("OnUpdate", nil)
        f._nsrtAuraTrackingDragElapsed = nil
        f._nsrtAuraTrackingUIElapsed = nil
        f:StopMovingOrSizing()
        SaveAuraTrackingFramePosition(self, f, settings)
        self.PendingAuraTrackingUpdate = true
        NotifyAuraTrackingPreviewDragged(self, settingsKey)
    end)
end

local function GetAuraTrackingFontPath(self, settings)
    local fontName = settings.TextFont or "Expressway"
    if self.LSM then
        return self.LSM:Fetch("font", fontName, true) or [[Interface\Addons\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]
    end
    return [[Interface\Addons\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]
end

local function EnsureAuraTrackingFontString(owner, key)
    local overlay = owner.textOverlay or owner.TextOverlay
    if not overlay then
        overlay = CreateFrame("Frame", nil, owner)
        overlay:SetAllPoints(owner)
        owner.TextOverlay = overlay
    end
    if owner.GetFrameLevel then
        overlay:SetFrameLevel(owner:GetFrameLevel() + 3)
    end
    if not owner[key] then
        owner[key] = overlay:CreateFontString(nil, "OVERLAY")
    end
    return owner[key]
end

local function ConfigureAuraTrackingButton(self, state, button, width, height, settings, unit, key)
    state.buttonRegions = state.buttonRegions or {}
    local durationColor = settings.DurationColor or {1, 1, 0.25, 1}
    local fontPath = GetAuraTrackingFontPath(self, settings)
    local buttonLevel = button:GetFrameLevel()

    if not state.buttonRegions[button] then
        local regions = {}

        regions.icon = button:CreateTexture(nil, "ARTWORK")
        regions.icon:SetAllPoints(button)
        button:SetIcon(regions.icon)

        regions.textOverlay = CreateFrame("Frame", nil, button)
        regions.textOverlay:SetAllPoints(button)
        regions.textOverlay:SetFrameLevel(buttonLevel + 3)

        state.buttonRegions[button] = regions
    end

    local regions = state.buttonRegions[button]
    button:SetSize(width, height)
    local zoom = ((settings.Zoom or 0) * 0.25) / 100
    regions.icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    regions.textOverlay:SetFrameLevel(buttonLevel + 3)
    if not regions.borderOverlay then
        regions.borderOverlay = CreateFrame("Frame", nil, button)
        regions.borderOverlay:SetAllPoints(button)
        regions.borderOverlay:EnableMouse(false)
    end
    local followSwipe = IsAuraTrackingBorderFollowingSwipe(settings)
    local borderLevel = buttonLevel + (followSwipe and 0 or 2)
    regions.border, regions.borderParent = UpdateAuraTrackingBorderLayer(
        regions.borderOverlay, borderLevel, regions.border, regions.borderParent,
        settings.BorderSize, settings.BorderColor
    )

    if AuraTrackingWantsDispelBorder(settings, key) then
        if not regions.dispelOverlay then
            regions.dispelOverlay = CreateFrame("Frame", nil, button)
            regions.dispelOverlay:SetAllPoints(regions.icon)
        end
        regions.dispelOverlay:SetFrameLevel(buttonLevel + (followSwipe and 1 or 3))
        regions.dispelOverlay:ClearAllPoints()
        regions.dispelOverlay:SetAllPoints(regions.icon)
        regions.dispelOverlay:Show()
        button:ClearDispelTypeTextures()
        if AuraTrackingUsesCustomDispelBorder(settings) then
            if not regions.customDispelBorder then
                regions.customDispelBorder = CreateAuraTrackingBorder(regions.dispelOverlay)
            end
            local customBorderSize = settings.DispelBorderSize
            UpdateAuraTrackingBorder(regions.customDispelBorder, regions.dispelOverlay, customBorderSize, {1, 1, 1, 1})
            if customBorderSize > 0 then
                AddAuraTrackingCustomDispelBorder(button, regions.customDispelBorder)
            end
        elseif regions.customDispelBorder then
            for _, texture in pairs(regions.customDispelBorder) do texture:Hide() end
        end
        if AuraTrackingUsesCustomDispelIcon(settings) then
            if not regions.dispelIconOverlay then
                regions.dispelIconOverlay = CreateFrame("Frame", nil, button)
                regions.dispelIconOverlay:SetAllPoints(regions.icon)
            end
            regions.dispelIconOverlay:SetFrameLevel(buttonLevel + (followSwipe and 3 or 4))
            if not regions.customDispelIcon then
                regions.customDispelIcon = regions.dispelIconOverlay:CreateTexture(nil, "OVERLAY")
            end
            local iconSize = math.min(width, height) * 0.35
            regions.customDispelIcon:ClearAllPoints()
            regions.customDispelIcon:SetPoint("TOPRIGHT", regions.dispelIconOverlay, "TOPRIGHT", -2, -2)
            regions.customDispelIcon:SetSize(iconSize, iconSize)
            button:AddDispelTypeTexture(regions.customDispelIcon, {
                style = Enum.CustomAuraButtonDispelTypeTextureStyle.Icon,
                showWhenHarmful = true,
                showWhenHelpful = false,
            })
        elseif regions.customDispelIcon then
            regions.customDispelIcon:Hide()
        end
        if not regions.dispelSymbol then
            regions.dispelSymbol = regions.textOverlay:CreateFontString(nil, "OVERLAY")
            regions.dispelSymbol:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            regions.dispelSymbol:SetTextColor(1, 1, 1, 1)
        end
        regions.dispelSymbol:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
        button:SetDispelTypeText(regions.dispelSymbol, {
            showWhenHarmful = true,
            showWhenHelpful = false,
        })
    else
        HideAuraTrackingDispelRegions(regions)
        button:ClearDispelTypeTextures()
        if regions.dispelSymbol then
            regions.dispelSymbol:Hide()
        end
        button:ClearDispelTypeText()
    end

    if settings.HideStackText then
        button:ClearApplicationCount()
        if regions.count then
            regions.count:SetText("")
            regions.count:Hide()
        end
    else
        local count = EnsureAuraTrackingFontString(regions, "count")
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", settings.StackXOffset, settings.StackYOffset)
        count:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
        count:SetTextColor(unpack(settings.StackColor))
        count:Show()
        button:SetApplicationCount(count, {})
    end

    if settings.HideDurationText then
        button:ClearDurationText()
        if regions.duration then
            regions.duration:SetText("")
            regions.duration:Hide()
        end
    else
        local duration = EnsureAuraTrackingFontString(regions, "duration")
        duration:ClearAllPoints()
        duration:SetPoint("CENTER", button, "CENTER", settings.DurationXOffset, settings.DurationYOffset)
        duration:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)
        duration:SetTextColor(unpack(durationColor))
        duration:Show()
        button:SetDurationText(duration, {
            textFormatter = GetAuraTrackingDurationFormatter(settings),
            textColor = GetAuraTrackingDurationTextColor(settings),
        })
    end
    --[[
    local isCustom = tostring(key):match("^Custom") and true or false
    if (key == "External" or isCustom) and settings.NameEnabled then]]
    -- if blizzard adds this just need to support it here
    local isCotankTracking = settings.Unit and string.lower(strtrim(settings.Unit)) == "cotank"
    if (tostring(key or ""):match("^Tank") or isCotankTracking) and settings.NameEnabled then
        local unitName = EnsureAuraTrackingFontString(regions, "unitName")
        PositionAuraTrackingUnitName(unitName, button, settings)
        unitName:SetFont(fontPath, settings.NameFontSize or settings.StackFontSize, settings.TextFontFlags)
        unitName:SetText(NSAPI:Shorten(unit, nil, false, "GlobalNickNames") or "")
        unitName:Show()
    elseif regions.unitName then
        regions.unitName:SetText("")
        regions.unitName:Hide()
    end

    button:SetMouseMotionEnabled(not settings.HideTooltip)
    if settings.EnableCooldownSwipe then
        if not regions.cooldown then
            regions.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            regions.cooldown:SetAllPoints(regions.icon)
            regions.cooldown:SetDrawEdge(false)
            regions.cooldown:SetHideCountdownNumbers(true)
        end
        regions.cooldown:SetFrameLevel(buttonLevel + (followSwipe and 2 or 1))
        regions.cooldown:SetReverse(settings.InverseCooldownSwipe)
        regions.cooldown:Show()
        button:SetDurationCooldown(regions.cooldown)
    else
        button:ClearDurationCooldown()
        if regions.cooldown then
            regions.cooldown:Hide()
        end
    end
    return button
end

local function ConfigureDebuffOverviewButton(self, state, button, unit)
    local settings = NSRT.ReminderSettings.DebuffOverviewSettings
    local width = settings.Width
    local height = settings.Height
    local buttonWidth = width + height
    local fontPath = self.LSM:Fetch("font", settings.Font)
    local buttonLevel = button:GetFrameLevel()

    if not state.buttonRegions[button] then
        local regions = {}
        regions.bar = CreateFrame("StatusBar", nil, button, "BackdropTemplate")
        regions.bar:SetFrameLevel(buttonLevel)
        regions.bar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        regions.background = button:CreateTexture(nil, "BACKGROUND")
        regions.icon = button:CreateTexture(nil, "ARTWORK")
        regions.icon:SetSize(height, height)
        button:SetIcon(regions.icon)

        regions.border = CreateFrame("Frame", nil, button, "BackdropTemplate")
        regions.border:SetAllPoints(button)
        regions.border:SetFrameLevel(buttonLevel + 1)
        regions.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })

        regions.textLayer = CreateFrame("Frame", nil, button)
        regions.textLayer:SetAllPoints(button)
        regions.textLayer:SetFrameLevel(buttonLevel + 2)
        regions.name = regions.textLayer:CreateFontString(nil, "OVERLAY")
        regions.duration = regions.textLayer:CreateFontString(nil, "OVERLAY")
        state.buttonRegions[button] = regions
    end

    local regions = state.buttonRegions[button]
    button:SetSize(buttonWidth, height)
    regions.bar:SetFrameLevel(button:GetFrameLevel())
    regions.border:SetFrameLevel(button:GetFrameLevel() + 1)
    regions.textLayer:SetFrameLevel(button:GetFrameLevel() + 2)
    regions.bar:SetSize(width, height)
    regions.bar:ClearAllPoints()
    regions.icon:ClearAllPoints()
    if settings.IconPosition == "Right" then
        regions.bar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        regions.icon:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    else
        regions.bar:SetPoint("TOPLEFT", button, "TOPLEFT", height, 0)
        regions.icon:SetPoint("LEFT", button, "LEFT", 0, 0)
    end
    local barTexture = self.LSM:Fetch("statusbar", settings.Texture)
    regions.bar:SetStatusBarTexture(barTexture)
    regions.bar:SetStatusBarColor(unpack(settings.barColors))
    if state.useBarColorAsBackground then
        regions.background:SetAllPoints(regions.bar)
        regions.background:SetTexture(barTexture)
        regions.background:SetVertexColor(unpack(settings.barColors))
        regions.background:Show()
    else
        regions.background:Hide()
    end
    local backgroundColors = settings.backgroundColors
    regions.bar:SetBackdropColor(unpack(backgroundColors))
    regions.border:SetBackdropBorderColor(unpack(settings.borderColors))
    regions.textLayer:SetFrameLevel(button:GetFrameLevel() + 2)

    regions.name:ClearAllPoints()
    regions.name:SetPoint("LEFT", regions.bar, "LEFT", settings.xTextOffset, settings.yTextOffset)
    regions.name:SetFont(fontPath, settings.FontSize, settings.FontFlags)
    regions.name:SetTextColor(unpack(settings.textColors))
    regions.name:SetText(state.displayName)
    regions.name:Show()

    regions.duration:ClearAllPoints()
    regions.duration:SetPoint("RIGHT", regions.bar, "RIGHT", settings.xTimer, settings.yTimer)
    regions.duration:SetFont(fontPath, settings.TimerFontSize, settings.FontFlags)
    regions.duration:SetTextColor(unpack(settings.textColors))
    regions.duration:Show()
    button:SetDurationText(regions.duration, {
        textFormatter = GetAuraTrackingDurationFormatter(settings),
        textColor = GetAuraTrackingDurationTextColor(settings),
    })
        button:SetDurationBar(regions.bar, {
            direction = state.invertFill and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime,
        })
end

function NSI:CreateDebuffOverviewContainers(regularFilter, candidateFilters, containersPerUnit, maxFrameCount, containerName, invertFill, useBarColorAsBackground)
    containerName = containerName or "Default"
    self.DebuffOverviewContainerSetsByName = self.DebuffOverviewContainerSetsByName or {}
    local existingSet = self.DebuffOverviewContainerSetsByName[containerName]
    if existingSet then
        self.DebuffOverviewContainerSets = existingSet
        return existingSet
    end
    if regularFilter == nil and candidateFilters == nil then
        return self.DebuffOverviewContainerSetsByName[containerName]
    end
    assert(type(regularFilter) == "string" and AuraUtil.IsValidFilterString(regularFilter), "regularFilter must be a valid aura filter string")
    assert(candidateFilters == nil or type(candidateFilters) == "table", "candidateFilters must be a table or nil")
    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end

    local settings = NSRT.ReminderSettings.DebuffOverviewSettings
    local anchor = self.DebuffOverviewMover
    local copies = math.max(1, math.floor(containersPerUnit or 1))
    local frameCount = maxFrameCount or 1
    local growDirection = settings.GrowDirection or "Up"
    local flowHorizontal = AnchorUtil.FlowDirection.Right
    local flowVertical = AnchorUtil.FlowDirection.Down
    local flowAxis = AnchorUtil.FlowLayoutAxis.Horizontal
    local flowAnchor = "TOPLEFT"
    if growDirection == "Up" then
        flowAxis = AnchorUtil.FlowLayoutAxis.Vertical
        flowVertical = AnchorUtil.FlowDirection.Up
        flowAnchor = "BOTTOMLEFT"
    elseif growDirection == "Down" then
        flowAxis = AnchorUtil.FlowLayoutAxis.Vertical
    elseif growDirection == "Left" then
        flowHorizontal = AnchorUtil.FlowDirection.Left
        flowAnchor = "TOPRIGHT"
    elseif growDirection == "Right" then
        flowHorizontal = AnchorUtil.FlowDirection.Right
        flowAnchor = "TOPLEFT"
    end
    local previousContainer
    local containerStates = {}

    for raidIndex = 1, 30 do
        local unit = "raid" .. raidIndex
        local displayName = NSAPI:Shorten(unit, nil, false, "GlobalNickNames", true, true) or UnitName(unit) or unit
        for copyIndex = 1, copies do
            local state = {
                unit = unit,
                displayName = displayName,
                invertFill = invertFill == true,
                useBarColorAsBackground = useBarColorAsBackground == true,
                buttonRegions = {},
            }
            local container = CreateFrame(
                "AuraContainer",
                nil,
                self.NSRTFrame,
                "CustomAuraContainerTemplate, DisableUntrustedLayoutScriptsTemplate"
            )
            state.container = container
            container:SetFrameStrata("HIGH")
            container:SetSize(settings.Width + settings.Height, settings.Height)
            container:SetUnit(unit)
            container:SetFlowLayoutAxis(flowAxis)
            container:SetFlowLayoutAnchorPoint(flowAnchor)
            container:SetFlowLayoutGrowthDirection(flowHorizontal, flowVertical)
            if previousContainer then
                if growDirection == "Up" then
                    container:SetPoint("BOTTOMLEFT", previousContainer, "TOPLEFT", 0, settings.Spacing or 0)
                elseif growDirection == "Down" then
                    container:SetPoint("TOPLEFT", previousContainer, "BOTTOMLEFT", 0, -(settings.Spacing or 0))
                elseif growDirection == "Left" then
                    container:SetPoint("TOPRIGHT", previousContainer, "TOPLEFT", -(settings.Spacing or 0), 0)
                else
                    container:SetPoint("TOPLEFT", previousContainer, "TOPRIGHT", settings.Spacing or 0, 0)
                end
            else
                if growDirection == "Up" then
                    container:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 8)
                elseif growDirection == "Down" then
                    container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
                elseif growDirection == "Left" then
                    container:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -8, 0)
                else
                    container:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
                end
            end
            container:AddAuraGroup("DebuffOverview", regularFilter, {
                maxFrameCount = frameCount,
                candidateFilters = candidateFilters or {},
                initializeFrame = function(button)
                    ConfigureDebuffOverviewButton(self, state, button, unit)
                end,
                layout = {
                    elementWidth = settings.Width + settings.Height,
                    elementHeight = settings.Height,
                    elementSpacing = 0,
                    lineSpacing = 0,
                },
            })
            container:Hide()
            container:SetEnabled(false)
            containerStates[#containerStates + 1] = state
            previousContainer = container
        end
    end
    self.DebuffOverviewContainerSetsByName[containerName] = containerStates
    self.DebuffOverviewContainerSets = containerStates
    return containerStates
end

function NSI:SetDebuffOverviewContainersShown(shown, containerName)
    local sets = self.DebuffOverviewContainerSetsByName or {}
    if not containerName then
        if self.DebuffOverviewContainerSets then sets.Default = self.DebuffOverviewContainerSets end
        containerName = "Default"
    end
    local states = sets[containerName]
    if not states then return end
    self.DebuffOverviewShownSets = self.DebuffOverviewShownSets or {}
    self.DebuffOverviewShownSets[containerName] = shown
    if self.DebuffOverviewMover then
        local anyShown = false
        for _, isShown in pairs(self.DebuffOverviewShownSets) do
            if isShown then anyShown = true break end
        end
        self.DebuffOverviewMover:SetShown(anyShown)
    end
    for _, state in ipairs(states) do
        local displayName = NSAPI:Shorten(state.unit, nil, false, "GlobalNickNames", true, true) or UnitName(state.unit) or state.unit
        if state.displayName ~= displayName and not self:Restricted() then
            state.displayName = displayName
            for button, regions in pairs(state.buttonRegions) do
                if regions.name then
                    regions.name:SetText(displayName)
                end
            end
        end
        local visible = shown and UnitIsVisible(state.unit)
        state.container:SetShown(visible)
        state.container:SetEnabled(visible)
    end
end

function NSI:PreviewDebuffOverviewContainers(regularFilter, candidateFilters, containersPerUnit, maxFrameCount, containerName, invertFill)
    if self.DebuffOverviewContainerPreviewActive then
        self.DebuffOverviewContainerPreviewActive = false
        self:SetDebuffOverviewContainersShown(false)
        return
    end
    if regularFilter ~= nil or candidateFilters ~= nil then
        self:CreateDebuffOverviewContainers(regularFilter, candidateFilters, containersPerUnit, maxFrameCount, containerName, invertFill)
    end
    self.DebuffOverviewContainerPreviewActive = true
    self:SetDebuffOverviewContainersShown(true, containerName)
end

local function SetAuraTrackingGroupMaxFrameCount(state, groupKey, maxFrameCount)
    if not state or not state.container or not groupKey then return end
    state.currentMaxFrameCountByGroup = state.currentMaxFrameCountByGroup or {}
    if state.currentMaxFrameCountByGroup[groupKey] == maxFrameCount then return end
    state.container:SetAuraGroupMaxFrameCount(groupKey, maxFrameCount)
    state.currentMaxFrameCountByGroup[groupKey] = maxFrameCount
end

local function InitAuraTrackingContainer(self, unit, settings, key, reconfigureButtons)
    if not unit or not settings or not settings.enabled then return end
    local loadMatches = self:EvaluateLoad(settings)
    local encounterConditions = settings.loadConditions and settings.loadConditions.EncounterIDs
    local hasEncounterConditions = encounterConditions and next(encounterConditions) ~= nil
    if not loadMatches and not hasEncounterConditions then return end
    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end
    local isCustom = tostring(key):match("^Custom") and true or false
    local isExternal = key == "External"
    local customUsesFilters = isCustom and settings.TrackingMode == "Filters"
    local isSpellFiltered = isExternal or (isCustom and not customUsesFilters)
    local spellIDMap
    if isExternal then
        spellIDMap = GetAuraTrackingSpellIDMap(settings, "External")
    elseif isCustom then
        local customIndex = tostring(key):match("^Custom(%d+)")
        if customIndex then
            spellIDMap = GetAuraTrackingSpellIDMap(settings, "Custom:" .. customIndex)
        end
    end
    if isSpellFiltered and not spellIDMap then return end
    local customFilterString = customUsesFilters and BuildAuraTrackingCustomFilterString(settings) or nil
    if customUsesFilters and not customFilterString then return end

    self.AuraTrackingState = self.AuraTrackingState or {}
    self.AuraTrackingState[key] = self.AuraTrackingState[key] or {}
    local state = self.AuraTrackingState[key]
    if not state.container then
        state.container = CreateFrame("AuraContainer", nil, self.NSRTFrame, "CustomAuraContainerTemplate")
        state.buttonRegions = {}
    end
    state.buttonRegions = state.buttonRegions or {}
    if not state.anchorFrame then
        state.anchorFrame = CreateFrame("Frame", nil, self.NSRTFrame)
    end
    local width = settings.Width
    local height = settings.Height
    local container = state.container
    local anchorFrame = state.anchorFrame
    local groupKeyPrefix = "NSRT_" .. key
    local layoutAnchorPoint = GetAuraTrackingLayoutAnchorPoint(settings)
    local frameStrata = GetAuraTrackingFrameStrata(settings)
    state.settings = settings
    state.unit = unit
    state.key = key
    if isSpellFiltered and (key == "External" or tostring(key):match("^Custom")) then
        state.requiresAssist = ResolveAuraTrackingCustomUnitType(settings, unit) == "Friendly"
    else
        state.requiresAssist = nil
    end
    state.unitCanAssist = state.requiresAssist ~= nil and GetAuraTrackingUnitCanAssist(unit, state.requiresAssist) or nil
    state.encounterConditioned = hasEncounterConditions
    state.width = width
    state.height = height
    state.currentMaxFrameCountByGroup = state.currentMaxFrameCountByGroup or {}
    state.active = true
    self.AuraTrackingStateOrder[#self.AuraTrackingStateOrder + 1] = key

    if isCustom then
        -- Blizzard only populates processedAuraType while this policy is active.
        local processedAuraType = customUsesFilters and settings.CandidateFilters and settings.CandidateFilters.ProcessedAuraType
        local policy = processedAuraType and processedAuraType ~= "Disabled"
            and CustomAuraContainerAuraProcessingPolicy.ProcessAura
            or CustomAuraContainerAuraProcessingPolicy.None
        container:SetAuraProcessingPolicy(policy)
    end

    container:Hide()
    container:SetFrameStrata(frameStrata)
    anchorFrame:SetFrameStrata(frameStrata)
    anchorFrame:SetSize(width, height)
    SetAuraTrackingPoint(anchorFrame, settings, UIParent)
    anchorFrame:Show()

    container:ClearAllPoints()
    container:SetSize(width, height)
    local containerAnchorPoint = GetAuraTrackingContainerAnchorPoint(settings)
    container:SetPoint(containerAnchorPoint, anchorFrame, containerAnchorPoint, 0, 0)
    container:SetUnit(unit)
    local horizontalGrowthDirection, verticalGrowthDirection = GetAuraTrackingFlowDirections(settings.GrowDirection, settings.GridGrowDirection or "UP")
    local rowWidth = GetAuraTrackingRowWidth(settings)
    container:SetFlowLayoutAxis(GetAuraTrackingLayoutAxis(settings))
    container:SetFlowLayoutAnchorPoint(layoutAnchorPoint)
    container:SetFlowLayoutGrowthDirection(horizontalGrowthDirection, verticalGrowthDirection)
    container:SetFlowLayoutMaximumLineSize(rowWidth)

    local auraGroups = {}
    if isExternal then
        auraGroups[#auraGroups + 1] = {
            filter = "HELPFUL",
            spellIDMap = spellIDMap,
        }
    elseif isCustom then
        if customUsesFilters then
            state.customAuraGroupKey = groupKeyPrefix .. "_filters"
            auraGroups[#auraGroups + 1] = {
                filter = customFilterString,
                customGroup = true,
            }
        else
            local unitType = ResolveAuraTrackingCustomUnitType(settings, unit)
            state.customAuraGroupKey = groupKeyPrefix .. "_" .. string.lower(unitType)
            local filter = unitType == "Friendly" and "HELPFUL" or "HARMFUL"
            if settings.SpellIDPlayerFilter == "Enabled" then
                filter = filter .. "|PLAYER"
            elseif settings.SpellIDPlayerFilter == "Inverted" then
                filter = filter .. "|!PLAYER"
            end
            auraGroups[#auraGroups + 1] = {
                filter = filter,
                spellIDMap = spellIDMap,
                customGroup = true,
                maxFrameCount = GetAuraTrackingCustomFrameLimit(settings, unit),
            }
        end
    else
        for _, filter in ipairs(AuraTrackingFilters) do
            auraGroups[#auraGroups + 1] = {
                filter = filter,
                useLongDurationFilter = true,
            }
        end
        if key == "Player" and settings.ShowWhitelistedPlayerBuffs then
            local playerBuffSpellIDMap = GetAuraTrackingSpellIDMap(settings, "PlayerBuffWhitelist")
            if playerBuffSpellIDMap then
                auraGroups[#auraGroups + 1] = {
                    filter = "HELPFUL",
                    spellIDMap = playerBuffSpellIDMap,
                }
            end
        end
    end
    for index, group in ipairs(auraGroups) do
        local groupKey = group.customGroup and state.customAuraGroupKey or (groupKeyPrefix .. index)
        if isCustom and group.customGroup then
            if container:HasAuraGroup(groupKeyPrefix .. "1") then
                SetAuraTrackingGroupMaxFrameCount(state, groupKeyPrefix .. "1", 0)
            end
            if container:HasAuraGroup(groupKeyPrefix .. "_helpful") then
                SetAuraTrackingGroupMaxFrameCount(state, groupKeyPrefix .. "_helpful", 0)
            end
            if container:HasAuraGroup(groupKeyPrefix .. "_harmful") then
                SetAuraTrackingGroupMaxFrameCount(state, groupKeyPrefix .. "_harmful", 0)
            end
            if container:HasAuraGroup(groupKeyPrefix .. "_filters") then
                SetAuraTrackingGroupMaxFrameCount(state, groupKeyPrefix .. "_filters", 0)
            end
        end
        local candidateFilters
        if isCustom and customUsesFilters then
            candidateFilters = BuildAuraTrackingCandidateFilters(settings)
        elseif isCustom then
            candidateFilters = { includeSpellIDs = group.spellIDMap }
        elseif group.spellIDMap then
            candidateFilters = { includeSpellIDs = group.spellIDMap }
        elseif group.useLongDurationFilter then
            candidateFilters = {
                isFromPlayerOrPlayerPet = false,
            }
            if settings.HideLongDurationAuras then
                candidateFilters.maxDuration = 300
            end
        end
        candidateFilters = candidateFilters or {}
        if candidateFilters.excludeSpellIDs then
            for spellID in pairs(AuraTrackingExcludedSpellIDs) do
                candidateFilters.excludeSpellIDs[spellID] = true
            end
        else
            candidateFilters.excludeSpellIDs = AuraTrackingExcludedSpellIDs
        end
        local maxFrameCount = group.maxFrameCount
        if maxFrameCount == nil then
            maxFrameCount = settings.Limit
        end
        local sortMode = settings.SortMode or "AuraInstanceID"
        local sortMethod = AuraContainerSortMethod.Default
        local sortDirection = AuraContainerSortDirection.Normal
        if sortMode == "LongDurationFirst" then
            sortMethod = AuraContainerSortMethod.ExpirationOnly
            sortDirection = AuraContainerSortDirection.Reverse
        elseif sortMode == "ShortDurationFirst" then
            sortMethod = AuraContainerSortMethod.ExpirationOnly
            sortDirection = AuraContainerSortDirection.Normal
        elseif sortMode == "AuraInstanceID" then
            sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly
            sortDirection = AuraContainerSortDirection.Normal
        end

        local options = {
            maxFrameCount = maxFrameCount,
            sortMethod = sortMethod,
            sortDirection = sortDirection,
            initializeFrame = function(button)
                ConfigureAuraTrackingButton(self, state, button, state.width, state.height, state.settings, state.unit, state.key)
            end,
            candidateFilters = candidateFilters,
            layout = {
                elementWidth = width,
                elementHeight = height,
                elementSpacing = settings.Spacing or 0,
                lineSpacing = settings.GridSpacing ~= nil and settings.GridSpacing or settings.Spacing or 0,
            },
        }

        if container:HasAuraGroup(groupKey) then
            SetAuraTrackingGroupMaxFrameCount(state, groupKey, options.maxFrameCount)
            container:SetAuraGroupFilterString(groupKey, group.filter)
            container:SetAuraGroupCandidateFilters(groupKey, options.candidateFilters)
            container:SetAuraGroupLayout(groupKey, options.layout)
            container:SetAuraGroupSortMethod(groupKey, options.sortMethod, options.sortDirection)
        else
            container:AddAuraGroup(groupKey, group.filter, options)
            state.currentMaxFrameCountByGroup[groupKey] = options.maxFrameCount
        end
    end

    local playerVehicleDisabled = unit == "player" and (self.AuraTrackingPlayerVehicleDisabled or UnitHasVehicleUI("player"))
    local shouldShow = loadMatches and not playerVehicleDisabled
    if state.requiresAssist ~= nil and state.unitCanAssist ~= state.requiresAssist then
        shouldShow = false
    end
    container:SetShown(shouldShow)
    container:SetEnabled(shouldShow)
    anchorFrame:SetShown(shouldShow)
    if reconfigureButtons then
        for button in pairs(state.buttonRegions or {}) do
            ConfigureAuraTrackingButton(self, state, button, state.width, state.height, state.settings, state.unit, state.key)
        end
    end
    return state
end

function NSI:UpdateAuraTrackingEncounterVisibility()
    local playerVehicleDisabled = self.AuraTrackingPlayerVehicleDisabled or UnitHasVehicleUI("player")
    for _, state in pairs(self.AuraTrackingState or {}) do
        if state.encounterConditioned and state.container then
            local shouldShow = self:EvaluateLoad(state.settings)
            if state.unit == "player" and playerVehicleDisabled then
                shouldShow = false
            end
            if state.requiresAssist ~= nil then
                state.unitCanAssist = GetAuraTrackingUnitCanAssist(state.unit, state.requiresAssist)
                shouldShow = shouldShow and state.unitCanAssist == state.requiresAssist
            end
            state.container:SetEnabled(shouldShow)
            state.container:SetShown(shouldShow)
            state.anchorFrame:SetShown(shouldShow)
        end
    end
end

local function InitAuraTrackingTankSet(self, settings, firstKey, reconfigureButtons)
    local firstTankState
    for index, tankUnit in ipairs(self:GetCoTankUnits()) do
        if index > 2 or (settings.OnlyShowFirstTank and index > 1) then
            break
        end
        local tankKey = index == 1 and firstKey or (firstKey .. "Tank2")
        local containerSettings = settings
        if index == 2 then
            containerSettings = CopyTable(settings)
            local multiTankGrow = settings.MultiTankGrow or "Same"
            containerSettings.GrowDirection = multiTankGrow == "Same" and settings.GrowDirection or multiTankGrow
            containerSettings.CustomAnchorFrame = nil
        end
        local tankState = InitAuraTrackingContainer(self, tankUnit, containerSettings, tankKey, reconfigureButtons)
        if tankState then
            if not firstTankState then
                firstTankState = tankState
            elseif firstTankState.anchorFrame then
                local frame = tankState.anchorFrame
                local xOffset = settings.MultiTankXOffset
                local yOffset = settings.MultiTankYOffset
                if xOffset == nil then xOffset = settings.Width end
                if yOffset == nil then yOffset = settings.Height end
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", firstTankState.anchorFrame, "CENTER", xOffset, yOffset)
            end
        end
    end
end

local function SetAuraTrackingPlayerVehicleState(self, disabled)
    for _, state in pairs(self.AuraTrackingState or {}) do
        if state.active and state.unit == "player" then
            local shouldShow = not disabled and state.settings.enabled and self:EvaluateLoad(state.settings)
            if state.requiresAssist ~= nil then
                state.unitCanAssist = GetAuraTrackingUnitCanAssist(state.unit, state.requiresAssist)
                shouldShow = shouldShow and state.unitCanAssist == state.requiresAssist
            end
            state.container:SetEnabled(shouldShow)
            state.container:SetShown(shouldShow)
            state.anchorFrame:SetShown(shouldShow)
        end
    end
end

function NSI:InitAuraTracking(allowRestrictedCreate, reconfigureButtons)
    if self.IsBuilding then return end
    if self:Restricted() and (not allowRestrictedCreate or self.AuraTrackingState) then
        self.PendingAuraTrackingUpdate = true
        self.PendingAuraTrackingReconfigure = self.PendingAuraTrackingReconfigure or reconfigureButtons
        return
    end

    self.PendingAuraTrackingUpdate = nil
    self.PendingAuraTrackingReconfigure = nil
    self.AuraTrackingStateOrder = {}
    local playerControlLost = self.AuraTrackingPlayerVehicleDisabled or UnitHasVehicleUI("player")

    for _, state in pairs(self.AuraTrackingState or {}) do
        state.active = false
    end

    InitAuraTrackingContainer(self, "player", NSRT.AuraTrackingSettings.Player, "Player", reconfigureButtons)
    InitAuraTrackingContainer(self, "player", NSRT.AuraTrackingSettings.External, "External", reconfigureButtons)

    local rosterRefreshStates = {}
    for index, settings in ipairs(NSRT.AuraTrackingSettings.Custom or {}) do
        local key = "Custom" .. index
        local unit, needsRosterUpdate = ResolveAuraTrackingUnit(self, settings)
        local isCustomCotank = type(settings.Unit) == "string" and string.lower(strtrim(settings.Unit)) == "cotank"
        if needsRosterUpdate then
            rosterRefreshStates[#rosterRefreshStates + 1] = {
                key = key,
                settings = settings,
                multiTank = isCustomCotank,
            }
        end
        if isCustomCotank then
            InitAuraTrackingTankSet(self, settings, key, reconfigureButtons)
        else
            InitAuraTrackingContainer(self, unit, settings, key, reconfigureButtons)
        end
    end

    if self:DifficultyCheck({14, 15, 16}) and UnitGroupRolesAssigned("player") == "TANK" then
        InitAuraTrackingTankSet(self, NSRT.AuraTrackingSettings.Tank, "Tank", reconfigureButtons)
    end

    if playerControlLost then
        SetAuraTrackingPlayerVehicleState(self, true)
    end

    for _, key in ipairs(self.AuraTrackingStateOrder) do
        local state = self.AuraTrackingState[key]
        local settings = state and state.settings
        if state and state.active and settings and settings.CustomAnchorFrame and settings.CustomAnchorFrame:sub(1, #AURA_TRACKING_FRAME_ANCHOR_PREFIX) == AURA_TRACKING_FRAME_ANCHOR_PREFIX then
            local anchorFrame = GetAuraTrackingAnchorFrame(self, settings, UIParent, state.anchorFrame)
            state.anchorFrame:ClearAllPoints()
            state.anchorFrame:SetPoint(settings.Anchor or "CENTER", anchorFrame, settings.relativeTo or "CENTER", settings.xOffset or 0, settings.yOffset or 0)
            local layoutAnchorPoint = GetAuraTrackingLayoutAnchorPoint(settings)
            state.container:ClearAllPoints()
            local containerAnchorPoint = GetAuraTrackingContainerAnchorPoint(settings)
            state.container:SetPoint(containerAnchorPoint, state.anchorFrame, containerAnchorPoint, 0, 0)
        end
    end

    for _, state in pairs(self.AuraTrackingState or {}) do
        if not state.active then
            if state.container then
                state.container:SetEnabled(false)
                state.container:Hide()
                state.buttonRegions = nil
            end
            if state.anchorFrame then
                state.anchorFrame:Hide()
            end
        end
    end

    AuraTrackingUnitRefreshStates = {
        target = {},
        focus = {},
        mouseover = {},
        boss = {},
        roster = rosterRefreshStates,
        playerControl = false,
        faction = {},
    }

    if (NSRT.AuraTrackingSettings.Player and NSRT.AuraTrackingSettings.Player.enabled)
        or (NSRT.AuraTrackingSettings.External and NSRT.AuraTrackingSettings.External.enabled) then
        AuraTrackingUnitRefreshStates.playerControl = true
    end

    if self.AuraTrackingState then
        for _, state in pairs(self.AuraTrackingState) do
            if state.container and state.active and type(state.unit) == "string" then
                local unit = string.lower(state.unit)
                if unit == "target" or unit == "focus" or unit == "mouseover" then
                    AuraTrackingUnitRefreshStates[unit][#AuraTrackingUnitRefreshStates[unit] + 1] = state
                elseif unit == "boss1" or unit == "boss2" or unit == "boss3" or unit == "boss4" or unit == "boss5" then
                    AuraTrackingUnitRefreshStates.boss[#AuraTrackingUnitRefreshStates.boss + 1] = state
                end
                if state.requiresAssist ~= nil then
                    AuraTrackingUnitRefreshStates.faction[unit] = true
                end
            end
        end
    end

    for _, settings in ipairs(NSRT.AuraTrackingSettings.Custom or {}) do
        local unit = settings.enabled and ResolveAuraTrackingUnit(self, settings)
        if unit == "player" then
            AuraTrackingUnitRefreshStates.playerControl = true
            break
        end
    end

    if #AuraTrackingUnitRefreshStates.target > 0 or #AuraTrackingUnitRefreshStates.focus > 0 or #AuraTrackingUnitRefreshStates.mouseover > 0 or #AuraTrackingUnitRefreshStates.boss > 0 or #AuraTrackingUnitRefreshStates.roster > 0 or next(AuraTrackingUnitRefreshStates.faction) or AuraTrackingUnitRefreshStates.playerControl then
        if not AuraTrackingUnitRefreshFrame then
            AuraTrackingUnitRefreshFrame = CreateFrame("Frame")
            AuraTrackingUnitRefreshFrame:SetScript("OnEvent", function(_, event, unit)
                if NSI.IsBuilding then return end
                if event == "UNIT_ENTERED_VEHICLE" then
                    if AuraTrackingVehicleStateTimer then
                        AuraTrackingVehicleStateTimer:Cancel()
                        AuraTrackingVehicleStateTimer = nil
                    end
                    NSI.AuraTrackingPlayerVehicleDisabled = true
                    SetAuraTrackingPlayerVehicleState(NSI, true)
                    return
                elseif event == "UNIT_FACTION" then
                    local unitCanAssist = GetAuraTrackingUnitCanAssist(unit, true)
                    for _, state in pairs(NSI.AuraTrackingState or {}) do
                        if state.active and state.unit == unit and state.requiresAssist ~= nil then
                            state.unitCanAssist = unitCanAssist
                            local shouldShow = state.settings.enabled and NSI:EvaluateLoad(state.settings)
                            if unit == "player" then
                                shouldShow = shouldShow and not (NSI.AuraTrackingPlayerVehicleDisabled or UnitHasVehicleUI("player"))
                            end
                            shouldShow = shouldShow and unitCanAssist == state.requiresAssist
                            if state.container:IsShown() ~= shouldShow or state.container:IsEnabled() ~= shouldShow then
                                state.container:SetEnabled(shouldShow)
                                state.container:SetShown(shouldShow)
                                state.anchorFrame:SetShown(shouldShow)
                            end
                        end
                    end
                    return
                elseif event == "UNIT_EXITED_VEHICLE" or event == "PLAYER_ENTERING_WORLD" then
                    if AuraTrackingVehicleStateTimer then
                        AuraTrackingVehicleStateTimer:Cancel()
                    end
                    local checks = 0
                    AuraTrackingVehicleStateTimer = C_Timer.NewTicker(0.1, function(timer)
                        checks = checks + 1
                        if checks < 5 or UnitHasVehicleUI("player") then
                            if checks >= 20 then
                                timer:Cancel()
                                AuraTrackingVehicleStateTimer = nil
                            end
                            return
                        end
                        timer:Cancel()
                        AuraTrackingVehicleStateTimer = nil
                        NSI.AuraTrackingPlayerVehicleDisabled = nil
                        SetAuraTrackingPlayerVehicleState(NSI, false)
                    end)
                    return
                end
                if event == "GROUP_ROSTER_UPDATE" then
                    if NSI:Restricted() then
                        NSI.PendingAuraTrackingUpdate = true
                        return
                    end
                    for _, entry in ipairs(AuraTrackingUnitRefreshStates.roster) do
                        if entry.multiTank then
                            NSI:InitAuraTracking(false, true)
                            return
                        end
                        local unit = ResolveAuraTrackingUnit(NSI, entry.settings)
                        if unit then
                            InitAuraTrackingContainer(NSI, unit, entry.settings, entry.key)
                        else
                            local state = NSI.AuraTrackingState and NSI.AuraTrackingState[entry.key]
                            if state and state.container then
                                state.container:SetEnabled(false)
                                state.container:Hide()
                                state.buttonRegions = nil
                                if state.anchorFrame then
                                    state.anchorFrame:Hide()
                                end
                                state.unit = nil
                            end
                        end
                    end
                    return
                end

                local states
                if event == "PLAYER_TARGET_CHANGED" then
                    states = AuraTrackingUnitRefreshStates.target
                elseif event == "PLAYER_FOCUS_CHANGED" then
                    states = AuraTrackingUnitRefreshStates.focus
                elseif event == "UPDATE_MOUSEOVER_UNIT" then
                    states = AuraTrackingUnitRefreshStates.mouseover
                elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
                    states = AuraTrackingUnitRefreshStates.boss
                end
                if not states then return end

                for _, state in ipairs(states) do
                    if state.container and state.active and state.requiresAssist ~= nil then
                        local unitCanAssist = GetAuraTrackingUnitCanAssist(state.unit, state.requiresAssist)
                        if state.unitCanAssist ~= unitCanAssist then
                            state.unitCanAssist = unitCanAssist
                            local shouldShow = state.settings.enabled and NSI:EvaluateLoad(state.settings)
                            shouldShow = shouldShow and unitCanAssist == state.requiresAssist
                            state.container:SetEnabled(shouldShow)
                            state.container:SetShown(shouldShow)
                            state.anchorFrame:SetShown(shouldShow)
                        end
                    end
                    if state.container and state.active and state.container:IsShown() and state.container:IsEnabled() then
                        if state.customAuraGroupKey then
                            SetAuraTrackingGroupMaxFrameCount(state, state.customAuraGroupKey, GetAuraTrackingCustomFrameLimit(state.settings, state.unit))
                        end
                        state.container:UpdateAllAuras()
                    end
                end
            end)
        end
        AuraTrackingUnitRefreshFrame:UnregisterAllEvents()
        if #AuraTrackingUnitRefreshStates.target > 0 then
            AuraTrackingUnitRefreshFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        end
        if #AuraTrackingUnitRefreshStates.focus > 0 then
            AuraTrackingUnitRefreshFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
        end
        if #AuraTrackingUnitRefreshStates.mouseover > 0 then
            AuraTrackingUnitRefreshFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        end
        if #AuraTrackingUnitRefreshStates.boss > 0 then
            AuraTrackingUnitRefreshFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        end
        if #AuraTrackingUnitRefreshStates.roster > 0 then
            AuraTrackingUnitRefreshFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        end
        if AuraTrackingUnitRefreshStates.playerControl then
            AuraTrackingUnitRefreshFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
            AuraTrackingUnitRefreshFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
            AuraTrackingUnitRefreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        end
        for unit in pairs(AuraTrackingUnitRefreshStates.faction) do
            AuraTrackingUnitRefreshFrame:RegisterUnitEvent("UNIT_FACTION", unit)
        end
    elseif AuraTrackingUnitRefreshFrame then
        AuraTrackingUnitRefreshFrame:UnregisterAllEvents()
    end
end

function NSI:InitAuraSystem(firstcall, reconfigureButtons)
    if firstcall then
        self.PendingInitialAuraTracking = true
        C_Timer.After(2, function()
            if not self.PendingInitialAuraTracking then return end
            self.PendingInitialAuraTracking = nil
            self:InitAuraTracking(true, reconfigureButtons)
        end)
        return
    end
    self.PendingInitialAuraTracking = nil
    self:InitAuraTracking(true, reconfigureButtons)
end

local function BuildAuraTrackingPreviewEntries(settings, key, fallbackTexture)
    local entries = {}
    local limit = math.min(settings.Limit or 1, 20)
    local previewData = GetAuraTrackingPreviewData(key)
    local spellIDs = previewData and previewData.previewSpellIDs or GetAuraTrackingSpellIDs(settings, key)
    local shuffledSpellIDs = {}
    for i, spellID in ipairs(spellIDs) do
        shuffledSpellIDs[i] = spellID
    end
    for i = #shuffledSpellIDs, 2, -1 do
        local j = math.random(i)
        shuffledSpellIDs[i], shuffledSpellIDs[j] = shuffledSpellIDs[j], shuffledSpellIDs[i]
    end
    for i = 1, limit do
        local texture = fallbackTexture
        if #shuffledSpellIDs > 0 then
            local spellID = shuffledSpellIDs[((i - 1) % #shuffledSpellIDs) + 1]
            texture = C_Spell.GetSpellTexture(spellID) or fallbackTexture
        end
        local dispelType
        if i == 1 then
            dispelType = AuraTrackingPreviewNonMagicDispelTypes[math.random(#AuraTrackingPreviewNonMagicDispelTypes)]
        elseif i > 2 and math.random(#AuraTrackingPreviewDispelTypes + 1) > 1 then
            dispelType = AuraTrackingPreviewDispelTypes[math.random(#AuraTrackingPreviewDispelTypes)]
        end
        entries[#entries + 1] = {
            index = i,
            duration = math.random(10, 120),
            texture = texture,
            dispelType = dispelType,
        }
    end

    if settings.SortMode == "LongDurationFirst" then
        table.sort(entries, function(a, b)
            if a.duration == b.duration then return a.index < b.index end
            return a.duration > b.duration
        end)
    elseif settings.SortMode == "ShortDurationFirst" then
        table.sort(entries, function(a, b)
            if a.duration == b.duration then return a.index < b.index end
            return a.duration < b.duration
        end)
    end

    return entries
end

local function StartAuraTrackingPreviewTimer(self, key)
    StopAuraTrackingPreviewTimer(self, key)
    local previewData = GetAuraTrackingPreviewData(key)
    if not previewData then return end
    local settings = NSI:GetAuraTrackingSettings(key)
    local durationColor = settings.DurationColor or {1, 1, 0.25, 1}
    local thresholdColor = settings.DurationThresholdColor or {1, 0, 0, 1}
    local colorUnderThreshold = settings.ColorDurationUnderThreshold
    local durationThreshold = math.max(tonumber(settings.ColorDurationThreshold) or 3, 0.1)
    local timerKey = previewData.timerKey
    self[timerKey] = C_Timer.NewTicker(0.05, function()
        local now = GetTime()
        local iconKey = previewData.iconKey
        local secondIconKey = previewData.secondIconKey
        for listIndex = 1, 2 do
            local icons = self[listIndex == 1 and iconKey or secondIconKey]
            if icons then
                for _, frame in ipairs(icons) do
                    if frame:IsShown() and frame.PreviewExpires then
                        local remaining = math.max(0, frame.PreviewExpires - now)
                        if remaining <= 0 then
                            self:PreviewAuraTracking(key, true)
                            return
                        end
                        if frame.Duration then
                            frame.Duration:SetText(FormatAuraTrackingDuration(remaining, settings))
                            if colorUnderThreshold and remaining < durationThreshold then
                                frame.Duration:SetTextColor(unpack(thresholdColor))
                            else
                                frame.Duration:SetTextColor(unpack(durationColor))
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function UpdateAuraTrackingPreviewFrame(self, frame, settings, texture, key, index, duration, dispelType, fontPath, previewData, previewUnitName)
    local durationColor = settings.DurationColor or {1, 1, 0.25, 1}
    local thresholdColor = settings.DurationThresholdColor or {1, 0, 0, 1}
    fontPath = fontPath or GetAuraTrackingFontPath(self, settings)
    local now = GetTime()
    duration = duration or 10
    frame.PreviewExpires = now + duration
    frame:SetSize(settings.Width, settings.Height)
    frame.Icon:SetTexture(texture)
    local zoom = ((settings.Zoom or 0) * 0.25) / 100
    frame.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)

    if not frame.BorderOverlay then
        frame.BorderOverlay = CreateFrame("Frame", nil, frame)
        frame.BorderOverlay:SetAllPoints(frame)
        frame.BorderOverlay:EnableMouse(false)
    end
    local followSwipe = IsAuraTrackingBorderFollowingSwipe(settings)
    local borderLevel = frame:GetFrameLevel() + (followSwipe and 0 or 2)
    frame.Border, frame.BorderParent = UpdateAuraTrackingBorderLayer(
        frame.BorderOverlay, borderLevel, frame.Border, frame.BorderParent,
        settings.BorderSize, settings.BorderColor
    )

    if AuraTrackingWantsDispelBorder(settings, key) and dispelType then
        if not frame.DispelOverlay then
            frame.DispelOverlay = CreateFrame("Frame", nil, frame)
            frame.DispelOverlay:SetAllPoints(frame.Icon)
        end
        frame.DispelOverlay:SetFrameLevel(frame:GetFrameLevel() + (followSwipe and 1 or 3))
        frame.DispelOverlay:ClearAllPoints()
        frame.DispelOverlay:SetAllPoints(frame.Icon)
        frame.DispelOverlay:Show()
        if AuraTrackingUsesCustomDispelBorder(settings) then
            if not frame.CustomDispelBorder then
                frame.CustomDispelBorder = CreateAuraTrackingBorder(frame.DispelOverlay)
            end
            UpdateAuraTrackingBorder(frame.CustomDispelBorder, frame.DispelOverlay, settings.DispelBorderSize, {1, 1, 1, 1})
            local color = GetAuraTrackingDispelBorderColors()[dispelType]
            for _, texture in pairs(frame.CustomDispelBorder) do
                texture:SetVertexColor(color:GetRGBA())
            end
        elseif frame.CustomDispelBorder then
            for _, texture in pairs(frame.CustomDispelBorder) do texture:Hide() end
        end
        if AuraTrackingUsesCustomDispelIcon(settings) then
            if not frame.DispelIconOverlay then
                frame.DispelIconOverlay = CreateFrame("Frame", nil, frame)
                frame.DispelIconOverlay:SetAllPoints(frame.Icon)
            end
            frame.DispelIconOverlay:SetFrameLevel(frame:GetFrameLevel() + (followSwipe and 3 or 4))
            if not frame.CustomDispelIcon then
                frame.CustomDispelIcon = frame.DispelIconOverlay:CreateTexture(nil, "OVERLAY")
            end
            local iconSize = math.min(settings.Width, settings.Height) * 0.35
            frame.CustomDispelIcon:ClearAllPoints()
            frame.CustomDispelIcon:SetPoint("TOPRIGHT", frame.DispelIconOverlay, "TOPRIGHT", -2, -2)
            frame.CustomDispelIcon:SetSize(iconSize, iconSize)
            AuraUtil.SetAuraDispelTypeIcon(frame.CustomDispelIcon, dispelType)
            frame.CustomDispelIcon:Show()
        elseif frame.CustomDispelIcon then
            frame.CustomDispelIcon:Hide()
        end
    else
        HideAuraTrackingPreviewDispelRegions(frame)
    end

    if settings.EnableCooldownSwipe then
        if not frame.Cooldown then
            frame.Cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
            frame.Cooldown:SetAllPoints(frame.Icon)
            frame.Cooldown:SetDrawEdge(false)
            frame.Cooldown:SetHideCountdownNumbers(true)
        end
        frame.Cooldown:SetFrameLevel(frame:GetFrameLevel() + (followSwipe and 2 or 1))
        frame.Cooldown:SetCooldown(now, duration)
        frame.Cooldown:SetReverse(settings.InverseCooldownSwipe)
        frame.Cooldown:Show()
    elseif frame.Cooldown then
        frame.Cooldown:Hide()
    end

    if settings.HideStackText then
        if frame.Stack then
            frame.Stack:SetText("")
            frame.Stack:Hide()
        end
    else
        local stack = EnsureAuraTrackingFontString(frame, "Stack")
        stack:ClearAllPoints()
        stack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", settings.StackXOffset, settings.StackYOffset)
        stack:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
        stack:SetTextColor(unpack(settings.StackColor))
        stack:SetText(index)
        stack:Show()
    end

    if settings.HideDurationText then
        if frame.Duration then
            frame.Duration:SetText("")
            frame.Duration:Hide()
        end
    else
        local durationText = EnsureAuraTrackingFontString(frame, "Duration")
        durationText:ClearAllPoints()
        durationText:SetPoint("CENTER", frame, "CENTER", settings.DurationXOffset, settings.DurationYOffset)
        durationText:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)
        durationText:SetTextColor(unpack(durationColor))
        durationText:SetText(FormatAuraTrackingDuration(duration, settings))
        if settings.ColorDurationUnderThreshold and duration < math.max(tonumber(settings.ColorDurationThreshold) or 3, 0.1) then
            durationText:SetTextColor(unpack(thresholdColor))
        else
            durationText:SetTextColor(unpack(durationColor))
        end
        durationText:Show()
    end

    local isCustom = tostring(key):match("^Custom") and true or false
    if (key == "External" or isCustom or key == "Tank") and settings.NameEnabled then
        local unitName = EnsureAuraTrackingFontString(frame, "UnitName")
        PositionAuraTrackingUnitName(unitName, frame, settings)
        unitName:SetFont(fontPath, settings.NameFontSize or settings.StackFontSize, settings.TextFontFlags)
        unitName:SetText(previewUnitName or NSAPI:Shorten(previewData and previewData.unit or "player", nil, false, "GlobalNickNames") or "")
        unitName:Show()
    elseif frame.UnitName then
        frame.UnitName:SetText("")
        frame.UnitName:Hide()
    end
end

local function GetAuraTrackingPreviewOffset(settings, growDirection, index, entryCount)
    local perLine = settings.AurasPerRowColumn or 20
    local indexInLine = (index - 1) % perLine
    local lineIndex = math.floor((index - 1) / perLine)
    local width = settings.Width
    local height = settings.Height
    local spacing = settings.Spacing or 0
    local gridSpacing = settings.GridSpacing ~= nil and settings.GridSpacing or spacing
    local xOffset = 0
    local yOffset = 0

    if growDirection == "RIGHT" or growDirection == "LEFT" or growDirection == "CENTER_HORIZONTAL" then
        if growDirection == "CENTER_HORIZONTAL" then
            local lineStart = lineIndex * perLine + 1
            local lineCount = math.min(perLine, entryCount - lineStart + 1)
            xOffset = (indexInLine - (lineCount - 1) / 2) * (width + spacing)
        else
            local direction = growDirection == "RIGHT" and 1 or -1
            xOffset = indexInLine * (width + spacing) * direction
        end
    elseif growDirection == "CENTER_VERTICAL" then
        local lineStart = lineIndex * perLine + 1
        local lineCount = math.min(perLine, entryCount - lineStart + 1)
        yOffset = -(indexInLine - (lineCount - 1) / 2) * (height + spacing)
    else
        local direction = growDirection == "UP" and 1 or -1
        yOffset = indexInLine * (height + spacing) * direction
    end

    local gridGrowDirection = settings.GridGrowDirection or "UP"
    if gridGrowDirection == "LEFT" then
        xOffset = xOffset - lineIndex * (width + gridSpacing)
    elseif gridGrowDirection == "RIGHT" then
        xOffset = xOffset + lineIndex * (width + gridSpacing)
    elseif gridGrowDirection == "UP" then
        yOffset = yOffset + lineIndex * (height + gridSpacing)
    elseif gridGrowDirection == "DOWN" then
        yOffset = yOffset - lineIndex * (height + gridSpacing)
    end

    return xOffset, yOffset
end

function NSI:PreviewAuraTracking(key, show)
    if self.IsBuilding then return end
    local settings = self:GetAuraTrackingSettings(key)
    local previewData = GetAuraTrackingPreviewData(key)
    if not settings or not previewData then return end
    local frameKey = previewData.frameKey
    local iconKey = previewData.iconKey
    local texture = previewData.texture

    if not self[frameKey] then
        self[frameKey] = CreateFrame("Frame", nil, self.NSRTFrame)
    end

    local mover = self[frameKey]
    local frameStrata = GetAuraTrackingFrameStrata(settings)
    mover:SetFrameStrata(frameStrata)
    if not show then
        StopAuraTrackingPreviewTimer(self, key)
        MakeAuraTrackingDraggable(self, mover, settings, false)
        mover:Hide()
        if self[iconKey] then
            for _, icon in ipairs(self[iconKey]) do
                icon.PreviewExpires = nil
                icon:Hide()
            end
        end
        if previewData.secondIconKey then
            local secondIconKey = previewData.secondIconKey
            local secondFrameKey = previewData.secondFrameKey
            if self[secondIconKey] then
                for _, icon in ipairs(self[secondIconKey]) do
                    icon.PreviewExpires = nil
                    icon:Hide()
                end
            end
            if self[secondFrameKey] then
                self[secondFrameKey]:Hide()
            end
        end
        self:InitAuraTracking()
        return
    end

    mover:SetSize(settings.Width, settings.Height)
    mover:SetScale(1)
    SetAuraTrackingPoint(mover, settings, UIParent)
    mover:Show()

    local secondMover
    local secondIconKey
    local isCotankTracking = key == "Tank" or (settings.Unit and string.lower(strtrim(settings.Unit)) == "cotank")
    if previewData.secondFrameKey and settings.OnlyShowFirstTank then
        if self[previewData.secondFrameKey] then
            self[previewData.secondFrameKey]:Hide()
        end
        if self[previewData.secondIconKey] then
            for _, icon in ipairs(self[previewData.secondIconKey]) do
                icon.PreviewExpires = nil
                icon:Hide()
            end
        end
    end
    if isCotankTracking and previewData.secondFrameKey and not settings.OnlyShowFirstTank then
        secondIconKey = previewData.secondIconKey
        secondMover = self[previewData.secondFrameKey]
        if not secondMover then
            secondMover = CreateFrame("Frame", nil, self.NSRTFrame)
            self[previewData.secondFrameKey] = secondMover
        end
        secondMover:SetFrameStrata(frameStrata)
        secondMover:SetSize(settings.Width, settings.Height)
        secondMover:ClearAllPoints()
        local grow = settings.MultiTankGrow or "Same"
        local secondGrow = grow == "Same" and settings.GrowDirection or grow
        local xOffset = settings.MultiTankXOffset
        local yOffset = settings.MultiTankYOffset
        if xOffset == nil then xOffset = settings.Width end
        if yOffset == nil then yOffset = settings.Height end
        secondMover:SetPoint("CENTER", mover, "CENTER", xOffset, yOffset)
        secondMover:Show()
        if not self[secondIconKey] then self[secondIconKey] = {} end
        secondMover.GrowDirection = secondGrow
    end

    MakeAuraTrackingDraggable(self, mover, settings, true, key)

    if not self[iconKey] then self[iconKey] = {} end
    local fontPath = GetAuraTrackingFontPath(self, settings)
    local previewUnit = previewData and previewData.unit or "player"
    local previewPlayerName = UnitName(previewUnit) or previewUnit
    local previewClass = select(2, UnitClass(previewUnit))
    local previewColor = GetClassColorObj(previewClass)
    local firstPreviewName = previewPlayerName
    local secondPreviewName
    local firstPreviewSuffix
    local secondPreviewSuffix
    if isCotankTracking then
        local cotankPreviewName = NSAPI:GetName(previewPlayerName, "GlobalNickNames") or previewPlayerName
        firstPreviewName = cotankPreviewName
        secondPreviewName = cotankPreviewName
        firstPreviewSuffix = " 1"
        secondPreviewSuffix = " 2"
    end
    if previewColor then
        firstPreviewName = previewColor:WrapTextInColorCode(firstPreviewName)
        if secondPreviewName then
            secondPreviewName = previewColor:WrapTextInColorCode(secondPreviewName)
        end
    end
    firstPreviewName = firstPreviewName .. (firstPreviewSuffix or "")
    secondPreviewName = secondPreviewName and (secondPreviewName .. secondPreviewSuffix) or nil
    local entries = BuildAuraTrackingPreviewEntries(settings, key, texture)
    for i = 1, 20 do
        if not self[iconKey][i] then
            local frame = CreateFrame("Frame", nil, mover)
            frame:SetFrameStrata(frameStrata)
            frame.Icon = frame:CreateTexture(nil, "ARTWORK")
            frame.Icon:SetAllPoints(frame)
            self[iconKey][i] = frame
        end
        local icon = self[iconKey][i]
        icon:SetFrameStrata(frameStrata)
        local entry = entries[i]
        if entry then
            local xOffset, yOffset = GetAuraTrackingPreviewOffset(settings, settings.GrowDirection, i, #entries)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", mover, "CENTER", xOffset, yOffset)
            UpdateAuraTrackingPreviewFrame(self, icon, settings, entry.texture or texture, key, i, entry.duration, entry.dispelType, fontPath, previewData, firstPreviewName)
            icon:Show()
        else
            icon.PreviewExpires = nil
            icon:Hide()
        end
    end
    if secondMover then
        for i = 1, 20 do
            if not self[secondIconKey][i] then
                local frame = CreateFrame("Frame", nil, secondMover)
                frame:SetFrameStrata(frameStrata)
                frame.Icon = frame:CreateTexture(nil, "ARTWORK")
                frame.Icon:SetAllPoints(frame)
                self[secondIconKey][i] = frame
            end
            local icon = self[secondIconKey][i]
            icon:SetFrameStrata(frameStrata)
            local entry = entries[i]
            if entry then
                local xOffset, yOffset = GetAuraTrackingPreviewOffset(settings, secondMover.GrowDirection, i, #entries)
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", secondMover, "CENTER", xOffset, yOffset)
                UpdateAuraTrackingPreviewFrame(self, icon, settings, entry.texture or texture, key, i, entry.duration, entry.dispelType, fontPath, previewData, secondPreviewName)
                icon:Show()
            else
                icon.PreviewExpires = nil
                icon:Hide()
            end
        end
    end
    StartAuraTrackingPreviewTimer(self, key)
end

function NSI:UpdateAuraTrackingDisplay(key)
    if self.IsBuilding then return end
    if self:Restricted() then
        self.PendingAuraTrackingUpdate = true
        self.PendingAuraTrackingReconfigure = true
        return
    end

    local customPreviewKey = tostring(key or ""):gsub(":", "")
    if key == "Player" and self.IsAuraTrackingPlayerPreview then
        self:PreviewAuraTracking("Player", true)
    elseif key == "Tank" and self.IsAuraTrackingTankPreview then
        self:PreviewAuraTracking("Tank", true)
    elseif key == "External" and self.IsAuraTrackingExternalPreview then
        self:PreviewAuraTracking("External", true)
    elseif tostring(key or ""):match("^Custom:") and self["IsAuraTracking" .. customPreviewKey .. "Preview"] then
        self:PreviewAuraTracking(key, true)
    end

    self:InitAuraTracking(false, true)
end
