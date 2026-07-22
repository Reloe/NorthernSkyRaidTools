local _, NSI = ...
local LibSerialize = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

local AuraTrackingFilters = {
    "HARMFUL|!PLAYER",
}

local AuraTrackingUnitRefreshFrame
local AuraTrackingUnitRefreshStates = {
    target = {},
    focus = {},
    mouseover = {},
    boss = {},
}

local function GetAuraTrackingFlowDirections(growDirection)
    local horizontal = AnchorUtil.FlowDirection.Right
    local vertical = AnchorUtil.FlowDirection.Down

    if growDirection == "LEFT" then
        horizontal = AnchorUtil.FlowDirection.Left
    elseif growDirection == "UP" then
        vertical = AnchorUtil.FlowDirection.Up
    end

    return horizontal, vertical
end

local function GetAuraTrackingRowWidth(settings)
    local width = settings.Width or 1
    if settings.GrowDirection == "UP" or settings.GrowDirection == "DOWN" then
        return width
    end

    local limit = settings.Limit or 1
    local spacing = settings.Spacing or 0
    return math.max(width, (width * limit) + (spacing * math.max(limit - 1, 0)))
end

local function GetAuraTrackingLayoutAnchorPoint(settings)
    local growDirection = settings and settings.GrowDirection or "RIGHT"
    if growDirection == "LEFT" then
        return "TOPRIGHT"
    elseif growDirection == "UP" then
        return "BOTTOMLEFT"
    end
    return "TOPLEFT"
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
        GrowDirection = "RIGHT",
        enabled = false,
        Width = 100,
        Height = 100,
        Zoom = 10,
        Anchor = "CENTER",
        relativeTo = "CENTER",
        CustomAnchorFrame = "UIParent",
        xOffset = -450,
        yOffset = -100,
        FrameStrata = "MEDIUM",
        BorderSize = 1,
        BorderColor = {0, 0, 0, 1},
        ShowDispelBorder = true,
        HideTooltip = false,
        HideDurationText = false,
        HideLongDurationAuras = false,
        ShowWhitelistedPlayerBuffs = false,
        HideStackText = false,
        EnableCooldownSwipe = true,
        InverseCooldownSwipe = true,
        DurationColor = {1, 1, 0.25, 1},
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
        SpellIDs = {},
        SpellIDsEdited = false,
        PreviewSpellID = nil,
        SortMode = "Default",
        Unit = "player",
        UnitType = "Automatic",
        loadConditions = { Roles = {}, Classes = {}, SpecIDs = {}, Names = {} },
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

local function GetAuraTrackingCustomFrameLimit(settings, unit)
    local limit = settings and settings.Limit or 0
    local wantedUnitType = ResolveAuraTrackingCustomUnitType(settings, unit)
    unit = unit and strtrim(tostring(unit)) or ""
    if unit ~= "" and UnitExists(unit) then
        local currentUnitType = UnitCanAssist("player", unit) and "Friendly" or "Enemy"
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

function NSI:SetAuraTrackingEntryGroup(settingsKey, groupName)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings or settings.builtin then return end
    groupName = groupName and strtrim(tostring(groupName)) or ""
    settings.group = (groupName ~= "" and groupName ~= NSI.AuraTrackingBuiltinGroup) and groupName or nil
    if settings.group then
        local root = NSRT.AuraTrackingSettings
        root.Groups = root.Groups or {}
        root.Groups[settings.group] = root.Groups[settings.group] or { collapsed = false }
    end
    self:RefreshAuraTrackingUI()
end

-- Delete a user group. Entries either become ungrouped (keepEntries) or are
-- removed (not keepEntries). The Built-in group cannot be deleted.
function NSI:DeleteAuraTrackingGroup(name, keepEntries)
    if not name or name == NSI.AuraTrackingBuiltinGroup then return end
    local root = NSRT.AuraTrackingSettings
    if not root then return end
    if keepEntries then
        for _, settings in ipairs(root.Custom or {}) do
            if settings.group == name then settings.group = nil end
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
    copy.Name = (settings.Name or "Aura") .. " " .. NSI:Loc("Copy")
    local index = #NSRT.AuraTrackingSettings.Custom + 1
    NSRT.AuraTrackingSettings.Custom[index] = copy
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
    return "Custom:" .. index
end

-- ── Section copy / paste ────────────────────────────────────────────────────
-- Trigger/Load are copied via a small explicit allowlist (their fields
-- are few and clearly scoped). "Display" is copied by EXCLUSION instead —
-- every field on the entry except identity/Trigger/Load fields — so
-- every current and future Display-tab setting (border, stack/duration text,
-- font, cooldown swipe, co-tank name, etc.) is captured automatically instead
-- of relying on a hand-maintained list that can silently fall out of sync.
local AuraTrackingSectionFields = {
    Trigger = { "SpellIDs", "SpellIDsEdited", "Unit", "UnitType", "PreviewSpellID" },
    Load    = { "loadConditions" },
}

local AuraTrackingNonDisplayFields = {
    Name = true, enabled = true, group = true, pinned = true, builtin = true,
    SpellIDs = true, SpellIDsEdited = true, Unit = true, UnitType = true, PreviewSpellID = true,
    loadConditions = true,
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
        for key, value in pairs(settings) do
            if not AuraTrackingNonDisplayFields[key] then
                data[key] = CopyAuraTrackingValue(value)
            end
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
    },
    Tank = {
        frameKey = "AuraTrackingTankPreviewMover",
        iconKey = "AuraTrackingTankPreviewIcons",
        timerKey = "AuraTrackingTankPreviewTimer",
        texture = 236318,
        unit = "player",
    },
    External = {
        frameKey = "AuraTrackingExternalPreviewMover",
        iconKey = "AuraTrackingExternalPreviewIcons",
        timerKey = "AuraTrackingExternalPreviewTimer",
        texture = C_Spell.GetSpellTexture(6940) or 135966,
        unit = "player",
    },
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

local AuraTrackingDurationFormatter
local function GetAuraTrackingDurationFormatter()
    if not AuraTrackingDurationFormatter then
        AuraTrackingDurationFormatter = C_StringUtil.CreateNumericRuleFormatter()
        AuraTrackingDurationFormatter:SetBreakpoints({
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
    return AuraTrackingDurationFormatter
end

local function FormatAuraTrackingDuration(seconds)
    seconds = tonumber(seconds) or 0
    if seconds >= 60 then
        return string.format("%dm", math.max(1, math.floor(seconds / 60)))
    end
    return tostring(math.ceil(seconds))
end

local function GetAuraTrackingSettingsKeyFromRuntimeKey(key)
    if key == "External" then return "External" end
    local customIndex = tostring(key or ""):match("^[Cc]ustom(%d+)$")
    if customIndex then return "Custom:" .. customIndex end
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
    return key ~= "External" and settings and settings.ShowDispelBorder
end

local function HideAuraTrackingDispelRegions(regions)
    if not regions then return end
    if regions.dispelOverlay then regions.dispelOverlay:Hide() end
    if regions.dispelBorder then regions.dispelBorder:Hide() end
    if regions.dispelSymbol then regions.dispelSymbol:Hide() end
end

local function HideAuraTrackingPreviewDispelRegions(frame)
    if not frame then return end
    if frame.DispelOverlay then frame.DispelOverlay:Hide() end
    if frame.DispelBorder then frame.DispelBorder:Hide() end
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

local AuraTrackingStyleKeys = {
    "Spacing",
    "Limit",
    "SortMode",
    "GrowDirection",
    "CustomAnchorFrame",
    "xOffset",
    "yOffset",
    "FrameStrata",
    "Width",
    "Height",
    "Zoom",
    "BorderSize",
    "BorderColor",
    "ShowDispelBorder",
    "HideTooltip",
    "HideDurationText",
    "HideLongDurationAuras",
    "HideStackText",
    "EnableCooldownSwipe",
    "InverseCooldownSwipe",
    "DurationColor",
    "StackColor",
    "DurationFontSize",
    "StackFontSize",
    "TextFont",
    "TextFontFlags",
    "DurationXOffset",
    "DurationYOffset",
    "StackXOffset",
    "StackYOffset",
}

function NSI:CopyAuraTrackingStyle(sourceKey, targetKey)
    local source = self:GetAuraTrackingSettings(sourceKey)
    local target = self:GetAuraTrackingSettings(targetKey)
    if not source or not target or source == target then return end

    for _, key in ipairs(AuraTrackingStyleKeys) do
        if type(source[key]) == "table" then
            target[key] = CopyTable(source[key])
        else
            target[key] = source[key]
        end
    end

    self:UpdateAuraTrackingDisplay(targetKey)
end

function NSI:AddCustomAuraTracking(group)
    NSRT.AuraTrackingSettings.Custom = NSRT.AuraTrackingSettings.Custom or {}
    local index = #NSRT.AuraTrackingSettings.Custom + 1
    group = group and strtrim(tostring(group)) or ""
    if group == "" or group == NSI.AuraTrackingBuiltinGroup then group = nil end
    NSRT.AuraTrackingSettings.Custom[index] = self:CreateAuraTrackingSettingsDefaults({
        Name = "Custom Aura Tracking " .. index,
        xOffset = 0,
        yOffset = 0,
        HideStackText = true,
        HideTooltip = true,
        ShowDispelBorder = false,
        SpellIDsEdited = true,
        group = group,
    })
    if group then
        NSRT.AuraTrackingSettings.Groups = NSRT.AuraTrackingSettings.Groups or {}
        NSRT.AuraTrackingSettings.Groups[group] = NSRT.AuraTrackingSettings.Groups[group] or { collapsed = false }
    end
    local settingsKey = "Custom:" .. index
    NSRT.AuraTrackingSelected = settingsKey
    self:RefreshAuraTrackingUI()
    return settingsKey
end

function NSI:StopAllAuraTrackingPreviews()
    for _, key in ipairs({"Player", "Tank", "External"}) do
        local previewData = GetAuraTrackingPreviewData(key)
        self["IsAuraTracking" .. key .. "Preview"] = false
        StopAuraTrackingPreviewTimer(self, key)
        if previewData and self[previewData.frameKey] then
            self[previewData.frameKey]:Hide()
        end
        if previewData and self[previewData.iconKey] then
            for _, icon in ipairs(self[previewData.iconKey]) do
                icon:Hide()
            end
        end
    end

    for index in ipairs((NSRT.AuraTrackingSettings and NSRT.AuraTrackingSettings.Custom) or {}) do
        local key = "Custom:" .. index
        local previewData = GetAuraTrackingPreviewData(key)
        self["IsAuraTrackingCustom" .. index .. "Preview"] = false
        StopAuraTrackingPreviewTimer(self, key)
        if previewData and self[previewData.frameKey] then
            self[previewData.frameKey]:Hide()
        end
        if previewData and self[previewData.iconKey] then
            for _, icon in ipairs(self[previewData.iconKey]) do
                icon:Hide()
            end
        end
    end

    self:InitAuraTracking()
end

function NSI:DeleteCustomAuraTracking(settingsKey)
    local customIndex = tonumber(tostring(settingsKey or ""):match("^Custom:(%d+)$"))
    if not customIndex or not NSRT.AuraTrackingSettings.Custom then return end
    table.remove(NSRT.AuraTrackingSettings.Custom, customIndex)
    NSRT.AuraTrackingSelected = "Player"
    self:InitAuraTracking()
    self:RefreshAuraTrackingUI()
end

local AuraTrackingBuiltinKeys = {
    Player = true,
    Tank = true,
    External = true,
}

local function EncodeAuraTrackingExport(payload)
    local serialized = LibSerialize:Serialize(payload)
    local compressed = serialized and LibDeflate:CompressDeflate(serialized)
    return compressed and LibDeflate:EncodeForPrint(compressed) or ""
end

local function DecodeAuraTrackingExport(text)
    local decoded = LibDeflate:DecodeForPrint(text or "")
    local decompressed = decoded and LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end
    local success, data = LibSerialize:Deserialize(decompressed)
    if success and type(data) == "table" then
        return data
    end
end

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
    return EncodeAuraTrackingExport({
        type = "NSRT_AURA_TRACKING",
        version = 1,
        entries = {
            {
                builtin = builtinKey,
                settings = CopyTable(settings),
            },
        },
    })
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
    return EncodeAuraTrackingExport({
        type = "NSRT_AURA_TRACKING",
        version = 1,
        group = groupName,
        entries = entries,
    })
end

function NSI:ImportAuraTrackingString(text)
    local payload = DecodeAuraTrackingExport(text)
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

local function SetAuraTrackingDispelBorderSize(border, relativeRegion, width, height)
    border:ClearAllPoints()
    border:SetPoint("CENTER", relativeRegion, "CENTER", 0, 0)
    border:SetSize(width * 1.25, height * 1.25)
end

local function ShouldShowAuraTrackingPreviewDispelBorder(settings, key, index)
    if not AuraTrackingWantsDispelBorder(settings, key) then return false end
    if index == 1 then return true end
    if index == 2 then return false end
    return random(2) == 1
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

local function GetAuraTrackingAnchorFrame(settings, fallback)
    local frameName = settings and settings.CustomAnchorFrame
    local frame = frameName and frameName ~= "" and _G[frameName]
    if type(frame) == "table" and frame.GetCenter and frame.IsShown then
        return frame
    end
    return fallback or UIParent
end

function NSI:IsValidAuraTrackingAnchorFrame(frameName)
    if not frameName or frameName == "" then return true end
    local frame = _G[frameName]
    return type(frame) == "table" and frame.GetCenter and frame.IsShown
end

local function SetAuraTrackingPoint(frame, settings, fallback)
    local relativeFrame = GetAuraTrackingAnchorFrame(settings, fallback)
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
    local relativeFrame = GetAuraTrackingAnchorFrame(settings, UIParent)
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

local function ClearAuraTracking(self)
    if not self.AuraTrackingState then return end
    for _, state in pairs(self.AuraTrackingState) do
        if state.container then
            state.container:SetEnabled(false)
            state.container:Hide()
        end
        if state.anchorFrame then
            state.anchorFrame:Hide()
        end
    end
end

local function AcquireAuraTrackingContainer(self, key)
    if not self.AuraTrackingState then self.AuraTrackingState = {} end
    if not self.AuraTrackingState[key] then self.AuraTrackingState[key] = {} end

    local state = self.AuraTrackingState[key]
    if not state.container then
        state.container = CreateFrame("AuraContainer", nil, self.NSRTFrame, "CustomAuraContainerTemplate")
        state.buttonRegions = {}
    end
    if not state.anchorFrame then
        state.anchorFrame = CreateFrame("Frame", nil, self.NSRTFrame)
    end
    return state
end

local function EnsureAuraTrackingFontString(regions, key)
    if not regions[key] then
        regions[key] = regions.textOverlay:CreateFontString(nil, "OVERLAY")
    end
    return regions[key]
end

local function ConfigureAuraTrackingButton(self, state, button, width, height, settings, unit, key)
    state.buttonRegions = state.buttonRegions or {}
    local fontPath = GetAuraTrackingFontPath(self, settings)

    if not state.buttonRegions[button] then
        local regions = {}

        regions.icon = button:CreateTexture(nil, "ARTWORK")
        regions.icon:SetAllPoints(button)
        button:SetIcon(regions.icon)

        regions.textOverlay = CreateFrame("Frame", nil, button)
        regions.textOverlay:SetAllPoints(button)
        regions.textOverlay:SetFrameLevel(button:GetFrameLevel() + 3)

        state.buttonRegions[button] = regions
    end

    local regions = state.buttonRegions[button]
    button:SetSize(width, height)
    local zoom = ((settings.Zoom or 0) * 0.5) / 100
    regions.icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    regions.textOverlay:SetFrameLevel(button:GetFrameLevel() + 3)
    if (settings.BorderSize or 0) > 0 and not regions.border then
        regions.border = CreateAuraTrackingBorder(button)
    end
    UpdateAuraTrackingBorder(regions.border, button, settings.BorderSize, settings.BorderColor)

    if AuraTrackingWantsDispelBorder(settings, key) then
        if not regions.dispelOverlay then
            regions.dispelOverlay = CreateFrame("Frame", nil, button)
            regions.dispelOverlay:SetAllPoints(regions.icon)
            regions.dispelOverlay:SetFrameLevel(button:GetFrameLevel() + 2)
        end
        if not regions.dispelBorder then
            regions.dispelBorder = regions.dispelOverlay:CreateTexture(nil, "OVERLAY")
        end
        regions.dispelOverlay:SetFrameLevel(button:GetFrameLevel() + 2)
        regions.dispelOverlay:ClearAllPoints()
        regions.dispelOverlay:SetAllPoints(regions.icon)
        regions.dispelOverlay:Show()
        SetAuraTrackingDispelBorderSize(regions.dispelBorder, regions.icon, width, height)
    end

    if AuraTrackingWantsDispelBorder(settings, key) then
        button:SetAuraBorder(regions.dispelBorder, {
            showIcon = true,
            showWhenHarmful = true,
            showWhenHelpful = false,
        })
    else
        HideAuraTrackingDispelRegions(regions)
        button:ClearAuraBorder()
    end

    if AuraTrackingWantsDispelBorder(settings, key) then
        if not regions.dispelSymbol then
            regions.dispelSymbol = regions.textOverlay:CreateFontString(nil, "OVERLAY")
            regions.dispelSymbol:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            regions.dispelSymbol:SetTextColor(1, 1, 1, 1)
        end
        regions.dispelSymbol:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
    end

    if AuraTrackingWantsDispelBorder(settings, key) then
        button:SetAuraSymbol(regions.dispelSymbol, {
            showWhenHarmful = true,
            showWhenHelpful = false,
        })
    else
        if regions.dispelSymbol then
            regions.dispelSymbol:Hide()
        end
        button:ClearAuraSymbol()
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
        duration:SetTextColor(unpack(settings.DurationColor))
        duration:Show()
        button:SetDurationText(duration, { formatter = GetAuraTrackingDurationFormatter() })
    end
    --[[
    local isCustom = tostring(key):match("^Custom") and true or false
    if (key == "External" or isCustom) and settings.NameEnabled then]]
    -- if blizzard adds this just need to support it here
    if key == "Tank" and settings.NameEnabled then
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
            regions.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
            regions.cooldown:SetDrawEdge(false)
            regions.cooldown:SetHideCountdownNumbers(true)
        end
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

local function SetAuraTrackingGroupMaxFrameCount(state, groupKey, maxFrameCount)
    if not state or not state.container or not groupKey then return end
    state.currentMaxFrameCountByGroup = state.currentMaxFrameCountByGroup or {}
    if state.currentMaxFrameCountByGroup[groupKey] == maxFrameCount then return end
    state.container:SetAuraGroupMaxFrameCount(groupKey, maxFrameCount)
    state.currentMaxFrameCountByGroup[groupKey] = maxFrameCount
end

-- Resolve an entry's configured Unit into a concrete unit token.
-- "cotank" is resolved to the other tank in the group (like the Tank built-in);
-- all other units ("player", "target", "focus", "boss1-5") are dynamic tokens
-- the AuraContainer follows directly.
local function ResolveAuraTrackingUnit(self, settings)
    local unit = settings.Unit and strtrim(tostring(settings.Unit)) or "player"
    if unit == "" then unit = "player" end
    if string.lower(unit) == "cotank" then
        for member in self:IterateGroupMembers() do
            if UnitGroupRolesAssigned(member) == "TANK" and not UnitIsUnit("player", member) then
                return member
            end
        end
        return nil
    end
    return unit
end

local function InitAuraTrackingContainer(self, unit, settings, key)
    if not unit or not settings or not settings.enabled then return end
    if not self:EvaluateLoad(settings) then return end
    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end
    local isCustom = tostring(key):match("^Custom") and true or false
    local isExternal = key == "External"
    local isSpellFiltered = isExternal or isCustom
    local spellIDMap = isSpellFiltered and GetAuraTrackingSpellIDMap(settings, GetAuraTrackingSettingsKeyFromRuntimeKey(key)) or nil
    if isSpellFiltered and not spellIDMap then return end

    local state = AcquireAuraTrackingContainer(self, key)
    local container = state.container
    local anchorFrame = state.anchorFrame
    local width = settings.Width
    local height = settings.Height
    local groupKeyPrefix = "NSRT_" .. key
    local layoutAnchorPoint = GetAuraTrackingLayoutAnchorPoint(settings)
    local frameStrata = GetAuraTrackingFrameStrata(settings)
    state.settings = settings
    state.unit = unit
    state.key = key
    state.width = width
    state.height = height
    state.currentMaxFrameCountByGroup = state.currentMaxFrameCountByGroup or {}

    container:SetEnabled(false)
    container:Hide()
    container:SetFrameStrata(frameStrata)
    anchorFrame:SetFrameStrata(frameStrata)
    anchorFrame:SetSize(width, height)
    SetAuraTrackingPoint(anchorFrame, settings, UIParent)
    anchorFrame:Show()

    container:ClearAllPoints()
    container:SetSize(width, height)
    container:SetPoint(layoutAnchorPoint, anchorFrame, layoutAnchorPoint, 0, 0)
    container:SetUnit(unit)
    container:SetAuraLayoutAnchorPoint(layoutAnchorPoint)
    container:SetAuraLayoutGrowthDirection(GetAuraTrackingFlowDirections(settings.GrowDirection))
    container:SetAuraLayoutRowWidth(GetAuraTrackingRowWidth(settings))

    local auraGroups = {}
    if isExternal then
        auraGroups[#auraGroups + 1] = {
            filter = "HELPFUL",
            spellIDMap = spellIDMap,
        }
    elseif isCustom then
        local unitType = ResolveAuraTrackingCustomUnitType(settings, unit)
        state.customAuraGroupKey = groupKeyPrefix .. "_" .. string.lower(unitType)
        auraGroups[#auraGroups + 1] = {
            filter = unitType == "Friendly" and "HELPFUL" or "HARMFUL",
            spellIDMap = spellIDMap,
            customGroup = true,
            maxFrameCount = GetAuraTrackingCustomFrameLimit(settings, unit),
        }
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
        end
        local candidateFilters
        if group.spellIDMap then
            candidateFilters = {
                includeSpellIDs = group.spellIDMap,
            }
        elseif group.useLongDurationFilter then
            candidateFilters = {}
            if settings.HideLongDurationAuras then
                candidateFilters.maxDuration = 180
            end
        end
        local maxFrameCount = group.maxFrameCount
        if maxFrameCount == nil then
            maxFrameCount = settings.Limit
        end
        local sortMode = settings.SortMode or "Default"
        local sortMethod = AuraContainerSortMethod.Default
        local sortDirection = AuraContainerSortDirection.Normal
        if sortMode == "LongDurationFirst" then
            sortMethod = AuraContainerSortMethod.ExpirationOnly
            sortDirection = AuraContainerSortDirection.Reverse
        elseif sortMode == "ShortDurationFirst" then
            sortMethod = AuraContainerSortMethod.ExpirationOnly
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
                elementSpacingX = settings.Spacing or 0,
                elementSpacingY = settings.Spacing or 0,
            },
        }

        if container:HasAuraGroup(groupKey) then
            SetAuraTrackingGroupMaxFrameCount(state, groupKey, options.maxFrameCount)
            container:SetAuraGroupCandidateFilters(groupKey, options.candidateFilters)
            container:SetAuraGroupLayout(groupKey, options.layout)
            container:SetAuraGroupSortMethod(groupKey, options.sortMethod, options.sortDirection)
        else
            container:AddAuraGroup(groupKey, group.filter, options)
            state.currentMaxFrameCountByGroup[groupKey] = options.maxFrameCount
        end
    end

    if not self:Restricted() and state.buttonRegions then
        for button in pairs(state.buttonRegions) do
            ConfigureAuraTrackingButton(self, state, button, width, height, settings, unit, key)
        end
    end

    container:Show()
    container:SetEnabled(true)
end

function NSI:InitAuraTracking(allowRestrictedCreate)
    if self.IsBuilding then return end
    if self:Restricted() and (not allowRestrictedCreate or self.AuraTrackingState) then
        self.PendingAuraTrackingUpdate = true
        return
    end

    ClearAuraTracking(self)

    InitAuraTrackingContainer(self, "player", NSRT.AuraTrackingSettings.Player, "Player")

    InitAuraTrackingContainer(self, "player", NSRT.AuraTrackingSettings.External, "External")

    for index, settings in ipairs(NSRT.AuraTrackingSettings.Custom or {}) do
        local unit = ResolveAuraTrackingUnit(self, settings)
        InitAuraTrackingContainer(self, unit, settings, "Custom" .. index)
    end

    if self:DifficultyCheck({14, 15, 16}) and UnitGroupRolesAssigned("player") == "TANK" then
        local tankUnit
        for unit in self:IterateGroupMembers() do
            if UnitGroupRolesAssigned(unit) == "TANK" and not UnitIsUnit("player", unit) then
                tankUnit = unit
                break
            end
        end
        InitAuraTrackingContainer(self, tankUnit, NSRT.AuraTrackingSettings.Tank, "Tank")
    end

    AuraTrackingUnitRefreshStates = {
        target = {},
        focus = {},
        mouseover = {},
        boss = {},
    }

    if self.AuraTrackingState then
        for _, state in pairs(self.AuraTrackingState) do
            if state.container and state.container:IsShown() and state.container:IsEnabled() and type(state.unit) == "string" then
                local unit = string.lower(state.unit)
                if unit == "target" or unit == "focus" or unit == "mouseover" then
                    AuraTrackingUnitRefreshStates[unit][#AuraTrackingUnitRefreshStates[unit] + 1] = state
                elseif unit == "boss1" or unit == "boss2" or unit == "boss3" or unit == "boss4" or unit == "boss5" then
                    AuraTrackingUnitRefreshStates.boss[#AuraTrackingUnitRefreshStates.boss + 1] = state
                end
            end
        end
    end

    if #AuraTrackingUnitRefreshStates.target > 0 or #AuraTrackingUnitRefreshStates.focus > 0 or #AuraTrackingUnitRefreshStates.mouseover > 0 or #AuraTrackingUnitRefreshStates.boss > 0 then
        if not AuraTrackingUnitRefreshFrame then
            AuraTrackingUnitRefreshFrame = CreateFrame("Frame")
            AuraTrackingUnitRefreshFrame:SetScript("OnEvent", function(_, event)
                if NSI.IsBuilding then return end
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
                    if state.container and state.container:IsShown() and state.container:IsEnabled() then
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
    elseif AuraTrackingUnitRefreshFrame then
        AuraTrackingUnitRefreshFrame:UnregisterAllEvents()
    end
end

function NSI:ApplyPendingAuraTracking()
    if not self.PendingAuraTrackingUpdate or self:Restricted() then return end
    self.PendingAuraTrackingUpdate = nil
    self:InitAuraTracking()
end

function NSI:InitAuraSystem(firstcall)
    if self:IsMidnightS2() then
        if firstcall then
            self.PendingInitialAuraTracking = true
            C_Timer.After(2, function()
                if not self.PendingInitialAuraTracking then return end
                self.PendingInitialAuraTracking = nil
                self:InitAuraTracking(true)
            end)
            return
        end
        self.PendingInitialAuraTracking = nil
        self:InitAuraTracking(true)
    else
        self:InitPrivateAuras(firstcall)
    end
end

local function BuildAuraTrackingPreviewEntries(settings, key, fallbackTexture)
    local entries = {}
    local limit = math.min(settings.Limit or 1, 20)
    local spellIDs = GetAuraTrackingSpellIDs(settings, key)
    for i = 1, limit do
        local texture = fallbackTexture
        if #spellIDs > 0 then
            texture = C_Spell.GetSpellTexture(spellIDs[math.random(1, #spellIDs)]) or fallbackTexture
        end
        entries[#entries + 1] = {
            index = i,
            duration = math.random(10, 120),
            texture = texture,
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
    local timerKey = previewData.timerKey
    self[timerKey] = C_Timer.NewTicker(0.05, function()
        local now = GetTime()
        local iconKey = previewData.iconKey
        if not self[iconKey] then return end

        for _, frame in ipairs(self[iconKey]) do
            if frame:IsShown() and frame.PreviewExpires and now >= frame.PreviewExpires then
                self:PreviewAuraTracking(key, true)
                return
            end
        end

        for _, frame in ipairs(self[iconKey]) do
            if frame:IsShown() and frame.Duration and frame.PreviewExpires then
                local remaining = math.max(0, frame.PreviewExpires - now)
                frame.Duration:SetText(FormatAuraTrackingDuration(remaining))
            end
        end
    end)
end

local function CreateAuraTrackingPreviewFrame(parent, settings)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetFrameStrata(GetAuraTrackingFrameStrata(settings))
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetAllPoints(frame)
    return frame
end

local function EnsureAuraTrackingPreviewFontString(frame, key)
    if frame.TextOverlay then
        frame.TextOverlay:SetFrameLevel(frame:GetFrameLevel() + 3)
    end
    if not frame[key] then
        if not frame.TextOverlay then
            frame.TextOverlay = CreateFrame("Frame", nil, frame)
            frame.TextOverlay:SetAllPoints(frame)
            frame.TextOverlay:SetFrameLevel(frame:GetFrameLevel() + 3)
        end
        frame[key] = frame.TextOverlay:CreateFontString(nil, "OVERLAY")
    end
    return frame[key]
end

local function UpdateAuraTrackingPreviewFrame(self, frame, settings, texture, index, key, duration)
    local fontPath = GetAuraTrackingFontPath(self, settings)
    local now = GetTime()
    duration = duration or 10
    frame.PreviewExpires = now + duration
    frame:SetSize(settings.Width, settings.Height)
    frame.Icon:SetTexture(texture)
    local zoom = ((settings.Zoom or 0) * 0.5) / 100
    frame.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)

    if (settings.BorderSize or 0) > 0 and not frame.Border then
        frame.Border = CreateAuraTrackingBorder(frame)
    end
    UpdateAuraTrackingBorder(frame.Border, frame, settings.BorderSize, settings.BorderColor)

    if ShouldShowAuraTrackingPreviewDispelBorder(settings, key, index) then
        if not frame.DispelOverlay then
            frame.DispelOverlay = CreateFrame("Frame", nil, frame)
            frame.DispelOverlay:SetAllPoints(frame.Icon)
            frame.DispelOverlay:SetFrameLevel(frame:GetFrameLevel() + 2)
        end
        frame.DispelOverlay:SetFrameLevel(frame:GetFrameLevel() + 2)
        if not frame.DispelBorder then
            frame.DispelBorder = frame.DispelOverlay:CreateTexture(nil, "OVERLAY")
        end
        frame.DispelOverlay:ClearAllPoints()
        frame.DispelOverlay:SetAllPoints(frame.Icon)
        SetAuraTrackingDispelBorderSize(frame.DispelBorder, frame.Icon, settings.Width, settings.Height)
        AuraUtil.SetAuraBorderAtlas(frame.DispelBorder, AuraTrackingPreviewDispelTypes[((index - 1) % #AuraTrackingPreviewDispelTypes) + 1], true)
        frame.DispelOverlay:Show()
        frame.DispelBorder:Show()
    else
        HideAuraTrackingPreviewDispelRegions(frame)
    end

    if settings.EnableCooldownSwipe then
        if not frame.Cooldown then
            frame.Cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
            frame.Cooldown:SetAllPoints(frame.Icon)
            frame.Cooldown:SetDrawEdge(false)
            frame.Cooldown:SetHideCountdownNumbers(true)
            frame.Cooldown:SetFrameLevel(frame:GetFrameLevel() + 1)
        end
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
        local stack = EnsureAuraTrackingPreviewFontString(frame, "Stack")
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
        local durationText = EnsureAuraTrackingPreviewFontString(frame, "Duration")
        durationText:ClearAllPoints()
        durationText:SetPoint("CENTER", frame, "CENTER", settings.DurationXOffset, settings.DurationYOffset)
        durationText:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)
        durationText:SetTextColor(unpack(settings.DurationColor))
        durationText:SetText(FormatAuraTrackingDuration(duration))
        durationText:Show()
    end

    local isCustom = tostring(key):match("^Custom") and true or false
    if (key == "External" or isCustom) and settings.NameEnabled then
        local unitName = EnsureAuraTrackingPreviewFontString(frame, "UnitName")
        PositionAuraTrackingUnitName(unitName, frame, settings)
        unitName:SetFont(fontPath, settings.NameFontSize or settings.StackFontSize, settings.TextFontFlags)
        local previewData = GetAuraTrackingPreviewData(key)
        unitName:SetText(NSAPI:Shorten(previewData and previewData.unit or "player", nil, false, "GlobalNickNames") or "")
        unitName:Show()
    elseif key == "Tank" and settings.NameEnabled then
        local unitName = EnsureAuraTrackingPreviewFontString(frame, "UnitName")
        PositionAuraTrackingUnitName(unitName, frame, settings)
        unitName:SetFont(fontPath, settings.NameFontSize or settings.StackFontSize, settings.TextFontFlags)
        local previewData = GetAuraTrackingPreviewData(key)
        unitName:SetText(NSAPI:Shorten(previewData and previewData.unit or "player", nil, false, "GlobalNickNames") or "")
        unitName:Show()
    elseif frame.UnitName then
        frame.UnitName:SetText("")
        frame.UnitName:Hide()
    end
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
    mover:SetFrameStrata(GetAuraTrackingFrameStrata(settings))
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
        self:InitAuraTracking()
        return
    end

    ClearAuraTracking(self)
    mover:SetSize(settings.Width, settings.Height)
    mover:SetScale(1)
    SetAuraTrackingPoint(mover, settings, UIParent)
    mover:Show()

    MakeAuraTrackingDraggable(self, mover, settings, true, key)

    if not self[iconKey] then self[iconKey] = {} end
    local xDirection = (settings.GrowDirection == "RIGHT" and 1) or (settings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (settings.GrowDirection == "DOWN" and -1) or (settings.GrowDirection == "UP" and 1) or 0
    local entries = BuildAuraTrackingPreviewEntries(settings, key, texture)
    for i = 1, 20 do
        if not self[iconKey][i] then
            self[iconKey][i] = CreateAuraTrackingPreviewFrame(mover, settings)
        end
        local icon = self[iconKey][i]
        icon:SetFrameStrata(GetAuraTrackingFrameStrata(settings))
        local entry = entries[i]
        if entry then
            local xOffset = (i - 1) * (settings.Width + settings.Spacing) * xDirection
            local yOffset = (i - 1) * (settings.Height + settings.Spacing) * yDirection
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", mover, "CENTER", xOffset, yOffset)
            UpdateAuraTrackingPreviewFrame(self, icon, settings, entry.texture or texture, i, key, entry.duration)
            icon:Show()
        else
            icon.PreviewExpires = nil
            icon:Hide()
        end
    end
    StartAuraTrackingPreviewTimer(self, key)
end

function NSI:UpdateAuraTrackingDisplay(key)
    if self.IsBuilding then return end
    local customPreviewKey = tostring(key or ""):gsub(":", "")
    if key == "Player" and self.IsAuraTrackingPlayerPreview then
        self:PreviewAuraTracking("Player", true)
    elseif key == "Tank" and self.IsAuraTrackingTankPreview then
        self:PreviewAuraTracking("Tank", true)
    elseif key == "External" and self.IsAuraTrackingExternalPreview then
        self:PreviewAuraTracking("External", true)
    elseif tostring(key or ""):match("^Custom:") and self["IsAuraTracking" .. customPreviewKey .. "Preview"] then
        self:PreviewAuraTracking(key, true)
    else
        self:InitAuraTracking()
    end
end
