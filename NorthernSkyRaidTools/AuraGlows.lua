local _, NSI = ...
if NSI:IsForever() then
    NSI.AuraGlowBuiltins = {}
    function NSI:RegisterBuiltinAuraGlow() end
    function NSI:SetBuiltinAuraGlowActive() end
    function NSI:ActivateBuiltinAuraGlow() end
    function NSI:DeactivateBuiltinAuraGlow() end
    function NSI:UpdateAuraGlowVisibility() end
    function NSI:RebuildAuraGlows() end
    function NSI:InitAuraGlows() end
    function NSI:RefreshAuraGlows() end
    function NSI:RefreshAuraGlowsUI() end
    return
end

NSI.AuraGlowBuiltins = NSI.AuraGlowBuiltins or {}
NSI.AuraGlowDefaultSettingsKey = "DefaultSettings"

local AuraGlowDisplaySettingKeys = {
    "Size", "IconSize", "IconPosition", "IconOffsetX", "IconOffsetY",
    "NumberOfLines", "LineSize", "Frequency", "ShowBackground", "ShowIcon",
    "ShowDurationSwipe", "ShowDurationText", "DurationFont", "DurationFontSize", "DurationColor",
}

local AuraGlowDurationFormatter = C_StringUtil.CreateNumericRuleFormatter()
AuraGlowDurationFormatter:SetBreakpoints({
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

local function ParseAuraGlowSpellIDs(value)
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

local function GetAuraGlowSpellIDs(settings)
    return ParseAuraGlowSpellIDs(settings and settings.SpellIDs)
end

local function UsesAuraGlowSpellIDs(settings)
    return settings.AuraType == "Buffs" and (settings.BuffFiltering or "SpellIDs") == "SpellIDs"
end

local function BuildAuraGlowFilterString(settings)
    local parts = { settings.AuraType == "Buffs" and "HELPFUL" or "HARMFUL" }
    if UsesAuraGlowSpellIDs(settings) then return table.concat(parts, "|") end
    for _, filter in ipairs(NSI.AuraTrackingFilterDefinitions or {}) do
        if filter.key ~= "Helpful" and filter.key ~= "Harmful" then
            local state = settings.AuraFilters and settings.AuraFilters[filter.key]
            if state == "Enabled" then
                parts[#parts + 1] = filter.value
            elseif state == "Inverted" then
                parts[#parts + 1] = "!" .. filter.value
            end
        end
    end
    return table.concat(parts, "|")
end

local function BuildAuraGlowCandidateFilters(settings)
    local configured = settings.CandidateFilters or {}
    local filters = {}
    filters.excludeSpellIDs = NSI.AuraTrackingExcludedSpellIDs
    if UsesAuraGlowSpellIDs(settings) then
        filters.includeSpellIDs = {}
        for _, spellID in ipairs(GetAuraGlowSpellIDs(settings)) do
            filters.includeSpellIDs[spellID] = true
        end
        return filters
    end
    if type(configured.DispelTypes) == "table" then
        for _, dispelType in ipairs(NSI.AuraTrackingCandidateDispelTypes or {}) do
            local state = configured.DispelTypes[dispelType]
            if state == "Enabled" then
                filters.includeDispelTypes = filters.includeDispelTypes or {}
                filters.includeDispelTypes[dispelType] = true
            elseif state == "Inverted" then
                filters.excludeDispelTypes = filters.excludeDispelTypes or {}
                filters.excludeDispelTypes[dispelType] = true
            end
        end
    end
    if type(configured.MaxDuration) == "number" then filters.maxDuration = configured.MaxDuration end
    if configured.ProcessedAuraType and configured.ProcessedAuraType ~= "Disabled" then
        filters.processedAuraType = AuraUtil.AuraUpdateChangedType[configured.ProcessedAuraType]
    end
    for _, filter in ipairs(NSI.AuraTrackingCandidateFilterDefinitions or {}) do
        local state = configured[filter.key]
        if state == "Enabled" or state == true then
            filters[filter.key] = true
        elseif state == "Inverted" or state == false then
            filters[filter.key] = false
        end
    end
    return filters
end

function NSI:CreateAuraGlowSettingsDefaults(overrides)
    local settings = {
        Name = "Custom Aura Glow",
        enabled = false,
        Size = 3,
        IconSize = 20,
        Color = {1, 0.2, 0.2, 1},
        NumberOfLines = 8,
        LineSize = 0,
        Frequency = 0.25,
        ShowBackground = true,
        ShowIcon = false,
        IconPosition = "CENTER",
        IconOffsetX = 0,
        IconOffsetY = 0,
        ShowDurationSwipe = true,
        ShowDurationText = false,
        DurationFont = "Expressway",
        DurationFontSize = 10,
        DurationColor = {1, 1, 1, 1},
        AuraType = "Debuffs",
        BuffFiltering = "SpellIDs",
        SpellIDs = {},
        AuraFilters = {},
        CandidateFilters = {},
        loadConditions = { Roles = { HEALER = true }, Classes = {}, SpecIDs = {}, Names = {}, EncounterIDs = {}, Difficulties = {} },
    }
    for key, value in pairs(overrides or {}) do
        settings[key] = value
    end
    return settings
end

local function GetAuraGlowDefaultSettings(self)
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    local settings = NSRT.AuraGlows.DefaultSettings
    if not settings then
        settings = self:CreateAuraGlowSettingsDefaults({ Name = self:Loc("Default Glow Settings") })
        settings.Color = nil
        NSRT.AuraGlows.DefaultSettings = settings
    end
    return settings
end

local function CopyAuraGlowDisplaySettings(settings, source)
    for _, field in ipairs(AuraGlowDisplaySettingKeys) do
        settings[field] = source[field]
    end
end

function NSI:RegisterBuiltinAuraGlow(key, definition)
    assert(type(key) == "string" and key ~= "", "built-in aura glow key must be a non-empty string")
    assert(type(definition) == "table", "built-in aura glow requires a definition")
    self.AuraGlowBuiltins[key] = definition
end

local function CreateBuiltinAuraGlowSettings(self, key, useDefaultDisplaySettings)
    local definition = self.AuraGlowBuiltins[key]
    local encounterIDs = {}
    if definition.encounterID then encounterIDs[definition.encounterID] = true end
    local settings = self:CreateAuraGlowSettingsDefaults({
        Name = definition.name or key,
        enabled = NSRT.AuraGlows.UseBuiltinAuraGlows == true or definition.enabled == true,
        builtin = true,
        menuIcon = definition.menuIcon,
        Color = definition.color and CopyTable(definition.color) or nil,
        AuraFilters = CopyTable(definition.auraFilters or {}),
        CandidateFilters = CopyTable(definition.candidateFilters or {}),
        loadConditions = { Roles = CopyTable(definition.roles or {HEALER = true}), Classes = {}, SpecIDs = {}, Names = {}, EncounterIDs = encounterIDs, Difficulties = { [16] = true } },
    })
    if useDefaultDisplaySettings then
        CopyAuraGlowDisplaySettings(settings, GetAuraGlowDefaultSettings(self))
    end
    return settings
end

function NSI:GetAuraGlowSettings(key)
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    if key == self.AuraGlowDefaultSettingsKey then return GetAuraGlowDefaultSettings(self) end
    if self.AuraGlowBuiltins[key] then
        NSRT.AuraGlows.Builtins = NSRT.AuraGlows.Builtins or {}
        local settings = NSRT.AuraGlows.Builtins[key]
        if not settings then
            settings = CreateBuiltinAuraGlowSettings(self, key, true)
            NSRT.AuraGlows.Builtins[key] = settings
        else
            local definition = self.AuraGlowBuiltins[key]
            settings.Name = definition.name or key
            if not settings.enabledEdited then
                settings.enabled = NSRT.AuraGlows.UseBuiltinAuraGlows == true or definition.enabled == true
            end
            if definition.color and not (settings.builtinEdited and settings.builtinEdited.Color) then
                settings.Color = CopyTable(definition.color)
            end
            settings.menuIcon = definition.menuIcon
            settings.builtin = true
        end
        return settings
    end
    local index = tonumber(tostring(key):match("^Custom:(%d+)$"))
    return index and NSRT.AuraGlows.Custom and NSRT.AuraGlows.Custom[index]
end

function NSI:MarkBuiltinAuraGlowColorEdited(key)
    if not self.AuraGlowBuiltins[key] then return end
    local settings = self:GetAuraGlowSettings(key)
    settings.builtinEdited = settings.builtinEdited or {}
    settings.builtinEdited.Color = true
end

function NSI:ResetBuiltinAuraGlow(key)
    assert(self.AuraGlowBuiltins[key], "unknown built-in aura glow: " .. tostring(key))
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    NSRT.AuraGlows.Builtins = NSRT.AuraGlows.Builtins or {}
    NSRT.AuraGlows.Builtins[key] = CreateBuiltinAuraGlowSettings(self, key, true)
    self:RebuildAuraGlows(key)
    self:RefreshAuraGlowPreview(key)
end

function NSI:ApplyDefaultAuraGlowSettingsToAll()
    local defaults = GetAuraGlowDefaultSettings(self)
    for _, entry in ipairs(self:IterateAuraGlowEntries()) do
        CopyAuraGlowDisplaySettings(entry.settings, defaults)
    end
    self:RebuildAuraGlows()
end

function NSI:ResetDefaultAuraGlowSettings()
    local settings = GetAuraGlowDefaultSettings(self)
    local defaults = self:CreateAuraGlowSettingsDefaults()
    CopyAuraGlowDisplaySettings(settings, defaults)
    return settings
end

function NSI:SetUseBuiltinAuraGlows(enabled)
    NSRT.AuraGlows.UseBuiltinAuraGlows = enabled == true
    for key, definition in pairs(self.AuraGlowBuiltins) do
        local settings = self:GetAuraGlowSettings(key)
        if not settings.enabledEdited then
            settings.enabled = enabled == true or definition.enabled == true
        end
    end
    self:UpdateAuraGlowVisibility()
    self:RefreshAuraGlowsUI()
end

function NSI:IterateAuraGlowEntries()
    local entries = {}
    for key in pairs(self.AuraGlowBuiltins) do
        entries[#entries + 1] = { key = key, settings = self:GetAuraGlowSettings(key), builtin = true, group = self.AuraGlowBuiltins[key].group }
    end
    table.sort(entries, function(a, b) return a.settings.Name < b.settings.Name end)
    for index, settings in ipairs(NSRT.AuraGlows and NSRT.AuraGlows.Custom or {}) do
        entries[#entries + 1] = { key = "Custom:" .. index, settings = settings, builtin = false, group = settings.group }
    end
    return entries
end

function NSI:GetAuraGlowGroups()
    local groups, seen = {}, {}
    for _, settings in ipairs(NSRT.AuraGlows and NSRT.AuraGlows.Custom or {}) do
        if settings.group and settings.group ~= "" then seen[settings.group] = true end
    end
    for name in pairs(seen) do groups[#groups + 1] = name end
    table.sort(groups)
    return groups
end

function NSI:GetAuraGlowGroupCollapsed(group)
    local groups = NSRT.AuraGlows and NSRT.AuraGlows.Groups
    return groups and groups[group] and groups[group].collapsed or false
end

function NSI:SetAuraGlowGroupCollapsed(group, collapsed)
    NSRT.AuraGlows.Groups = NSRT.AuraGlows.Groups or {}
    NSRT.AuraGlows.Groups[group] = NSRT.AuraGlows.Groups[group] or {}
    NSRT.AuraGlows.Groups[group].collapsed = collapsed and true or false
end

function NSI:AddCustomAuraGlow(group)
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    NSRT.AuraGlows.Custom = NSRT.AuraGlows.Custom or {}
    local index = #NSRT.AuraGlows.Custom + 1
    group = group and strtrim(tostring(group)) or ""
    local settings = self:CreateAuraGlowSettingsDefaults({ Name = "Custom Aura Glow " .. index, group = group ~= "" and group or nil })
    CopyAuraGlowDisplaySettings(settings, GetAuraGlowDefaultSettings(self))
    NSRT.AuraGlows.Custom[index] = settings
    local key = "Custom:" .. index
    self:InitAuraGlows(key)
    return key
end

function NSI:SetAuraGlowEntryGroup(key, group)
    local settings = self:GetAuraGlowSettings(key)
    if not settings or settings.builtin then return end
    group = group and strtrim(tostring(group)) or ""
    settings.group = group ~= "" and group or nil
    self:RefreshAuraGlowsUI()
end

function NSI:DuplicateCustomAuraGlow(key)
    local settings = self:GetAuraGlowSettings(key)
    if not settings or settings.builtin then return end
    NSRT.AuraGlows.Custom = NSRT.AuraGlows.Custom or {}
    local copy = CopyTable(settings)
    copy.builtin = nil
    copy.Name = (copy.Name or "Custom Aura Glow") .. " Copy"
    NSRT.AuraGlows.Custom[#NSRT.AuraGlows.Custom + 1] = copy
    local newKey = "Custom:" .. #NSRT.AuraGlows.Custom
    self:InitAuraGlows(newKey)
    return newKey
end

function NSI:DeleteCustomAuraGlow(key)
    local index = tonumber(tostring(key):match("^Custom:(%d+)$"))
    if not index or not NSRT.AuraGlows.Custom[index] then return end
    self:HideAuraGlowPreview(false)
    table.remove(NSRT.AuraGlows.Custom, index)
    self:RebuildAuraGlows()
end

function NSI:GetAuraGlowSpellIDList(key)
    local settings = self:GetAuraGlowSettings(key)
    return settings and GetAuraGlowSpellIDs(settings) or {}
end

function NSI:AddAuraGlowSpellIDs(key, value)
    local settings = self:GetAuraGlowSettings(key)
    if not settings or settings.builtin then return end
    local newSpellIDs = ParseAuraGlowSpellIDs(value)
    if #newSpellIDs == 0 then return end
    settings.SpellIDs = settings.SpellIDs or {}
    local seen = {}
    for _, spellID in ipairs(settings.SpellIDs) do seen[spellID] = true end
    for _, spellID in ipairs(newSpellIDs) do
        if not seen[spellID] then
            settings.SpellIDs[#settings.SpellIDs + 1] = spellID
            seen[spellID] = true
        end
    end
    table.sort(settings.SpellIDs)
    self:RebuildAuraGlows(key)
    self:RefreshAuraGlowPreview(key)
end

function NSI:RemoveAuraGlowSpellID(key, spellID)
    local settings = self:GetAuraGlowSettings(key)
    if not settings or settings.builtin or not settings.SpellIDs then return end
    spellID = tonumber(spellID)
    for index, value in ipairs(settings.SpellIDs) do
        if tonumber(value) == spellID then
            table.remove(settings.SpellIDs, index)
            self:RebuildAuraGlows(key)
            self:RefreshAuraGlowPreview(key)
            return
        end
    end
end

function NSI:ExportAuraGlowEntry(key)
    local settings = self:GetAuraGlowSettings(key)
    if not settings then return "" end
    local entry = CopyTable(settings)
    if self.AuraGlowBuiltins[key] then entry.builtinKey = key end
    return self:EncodeExportData({ type = "NSRT_AURA_GLOW", version = 1, entries = { entry } }, "AuraGlow") or ""
end

function NSI:ExportAuraGlowGroup(group)
    local entries = {}
    for _, entry in ipairs(self:IterateAuraGlowEntries()) do
        if entry.group == group then
            local settings = CopyTable(entry.settings)
            if entry.builtin then settings.builtinKey = entry.key end
            entries[#entries + 1] = settings
        end
    end
    return #entries > 0 and (self:EncodeExportData({ type = "NSRT_AURA_GLOW", version = 1, group = group, entries = entries }, "AuraGlow") or "") or ""
end

function NSI:ImportAuraGlowString(text)
    local payload = self:DecodeExportData(text, "AuraGlow")
    if not payload or payload.type ~= "NSRT_AURA_GLOW" or type(payload.entries) ~= "table" then return false end
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    NSRT.AuraGlows.Custom = NSRT.AuraGlows.Custom or {}
    NSRT.AuraGlows.Builtins = NSRT.AuraGlows.Builtins or {}
    local group = payload.group and strtrim(tostring(payload.group)) or nil
    local imported = 0
    for _, entry in ipairs(payload.entries) do
        if type(entry) == "table" then
            local builtinKey = entry.builtinKey
            if not builtinKey and group then
                for key, definition in pairs(self.AuraGlowBuiltins) do
                    if definition.group == group and self:GetAuraGlowSettings(key).Name == entry.Name then
                        builtinKey = key
                        break
                    end
                end
            end
            entry.builtinKey = nil
            local settings = self:CreateAuraGlowSettingsDefaults(CopyTable(entry))
            settings.Name = settings.Name or "Imported Aura Glow"
            if builtinKey and self.AuraGlowBuiltins[builtinKey] then
                settings.builtin = true
                NSRT.AuraGlows.Builtins[builtinKey] = settings
            else
                settings.builtin = nil
                settings.group = group or settings.group
                local matchingIndex
                for index, existing in ipairs(NSRT.AuraGlows.Custom) do
                    if existing.group == settings.group and existing.Name == settings.Name then
                        matchingIndex = index
                        break
                    end
                end
                if matchingIndex then
                    NSRT.AuraGlows.Custom[matchingIndex] = settings
                else
                    NSRT.AuraGlows.Custom[#NSRT.AuraGlows.Custom + 1] = settings
                end
            end
            imported = imported + 1
        end
    end
    if imported == 0 then return false end
    self:RebuildAuraGlows()
    return true, imported
end

function NSI:SetBuiltinAuraGlowActive(key, active)
    assert(self.AuraGlowBuiltins[key], "unknown built-in aura glow: " .. tostring(key))
    self.AuraGlowManualState = self.AuraGlowManualState or {}
    if active == nil then
        self.AuraGlowManualState[key] = nil
    else
        self.AuraGlowManualState[key] = active == true
    end
    self:UpdateAuraGlowVisibility(key)
end

function NSI:ActivateBuiltinAuraGlow(key)
    self:SetBuiltinAuraGlowActive(key, true)
end

function NSI:DeactivateBuiltinAuraGlow(key)
    self:SetBuiltinAuraGlowActive(key, false)
end

local function CreateAuraGlowIcon(button, settings, texture)
    local icon = button:CreateTexture(nil, "ARTWORK")
    local iconSize = settings.IconSize or 20
    icon:SetSize(iconSize, iconSize)
    local iconPosition = settings.IconPosition or "CENTER"
    icon:SetPoint(iconPosition, button, iconPosition, settings.IconOffsetX or 0, settings.IconOffsetY or 0)
    icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
    icon:SetAlpha(settings.ShowIcon and 1 or 0)
    if texture then icon:SetTexture(texture) end
    if settings.ShowIcon then
        local iconBorder = {
            top = button:CreateTexture(nil, "OVERLAY"),
            bottom = button:CreateTexture(nil, "OVERLAY"),
            left = button:CreateTexture(nil, "OVERLAY"),
            right = button:CreateTexture(nil, "OVERLAY"),
        }
        for _, borderTexture in pairs(iconBorder) do
            borderTexture:ClearAllPoints()
            borderTexture:SetColorTexture(0, 0, 0, 1)
            borderTexture:Show()
        end
        iconBorder.top:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        iconBorder.top:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        iconBorder.top:SetHeight(1)
        iconBorder.bottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        iconBorder.bottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        iconBorder.bottom:SetHeight(1)
        iconBorder.left:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        iconBorder.left:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        iconBorder.left:SetWidth(1)
        iconBorder.right:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        iconBorder.right:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        iconBorder.right:SetWidth(1)
    end
    return icon
end

local function CreateAuraGlowBorder(button, settings, preview)
    local border = CreateFrame("Frame", nil, button)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0.05, 0.05)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0.05)
    border:SetFrameLevel(button:GetFrameLevel() + 8)

    local numberOfLines = settings.NumberOfLines
    local width, height = button:GetSize()
    local lineLength = settings.LineSize
    if lineLength == 0 then
        lineLength = math.max(1, math.floor((width + height) * (2 / numberOfLines - 0.1)))
    end
    lineLength = math.min(lineLength, math.min(width, height))
    local thickness = settings.Size or 1

    local borderMask = border:CreateMaskTexture()
    borderMask:SetTexture([[Interface\AdventureMap\BrokenIsles\AM_29]], "CLAMPTOWHITE", "CLAMPTOWHITE")
    borderMask:SetPoint("TOPLEFT", border, "TOPLEFT", thickness + 1, -thickness - 1)
    borderMask:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -thickness - 1, thickness + 1)
    borderMask:Show()

    if settings.ShowBackground then
        local background = border:CreateTexture(nil, "ARTWORK", nil, 6)
        background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        background:SetAllPoints(border)
        background:AddMaskTexture(borderMask)
        background:Show()
    end

    local perimeter = 2 * (width + height)
    local horizontalTravel = math.max(width - lineLength, 0)
    local verticalTravel = math.max(height - lineLength, 0)
    local sides = {
        { point = "TOPLEFT", width = lineLength, height = thickness, xTravel = horizontalTravel, yTravel = 0, horizontal = true, incomingOrigin = "LEFT", outgoingOrigin = "RIGHT" },
        { point = "TOPRIGHT", width = thickness, height = lineLength, xTravel = 0, yTravel = -verticalTravel, horizontal = false, incomingOrigin = "TOP", outgoingOrigin = "BOTTOM" },
        { point = "BOTTOMRIGHT", width = lineLength, height = thickness, xTravel = -horizontalTravel, yTravel = 0, horizontal = true, incomingOrigin = "RIGHT", outgoingOrigin = "LEFT" },
        { point = "BOTTOMLEFT", width = thickness, height = lineLength, xTravel = 0, yTravel = verticalTravel, horizontal = false, incomingOrigin = "BOTTOM", outgoingOrigin = "TOP" },
    }
    local cornerDuration = perimeter > 0 and lineLength / perimeter / settings.Frequency or 0.001
    for _, side in ipairs(sides) do
        side.duration = perimeter > 0 and math.max(math.abs(side.xTravel), math.abs(side.yTravel)) / perimeter / settings.Frequency or 0.001
    end

    local function CreatePixelGlowLine(side, progress)
        local line = border:CreateTexture(nil, "ARTWORK", nil, 7)
        line:SetTexture([[Interface\Buttons\WHITE8x8]])
        line:SetVertexColor(unpack(settings.Color))
        line:SetSize(side.width, side.height)
        line:SetPoint(side.point, border, side.point, side.xTravel * progress, side.yTravel * progress)
        line:SetAlpha(0)
        line:Show()
        return line
    end

    local function GetPixelGlowPathPosition(distance)
        distance = distance % perimeter
        for index, side in ipairs(sides) do
            local straightLength = math.max(math.abs(side.xTravel), math.abs(side.yTravel))
            if distance < straightLength then
                return index, "straight", straightLength > 0 and distance / straightLength or 0
            end
            distance = distance - straightLength
            if distance < lineLength then
                return index, "corner", distance / lineLength
            end
            distance = distance - lineLength
        end
        return 1, "straight", 0
    end

    local function AddPixelGlowRunner(startDistance)
        local animationGroup = border:CreateAnimationGroup()
        animationGroup:SetLooping("REPEAT")
        local order = 0

        local function AddStraightSegment(side, line, progress, show)
            order = order + 1
            if show then
                local reveal = animationGroup:CreateAnimation("Alpha")
                reveal:SetTarget(line)
                reveal:SetOrder(order)
                reveal:SetFromAlpha(0)
                reveal:SetToAlpha(1)
                reveal:SetDuration(0.001)
            end

            if progress > 0 then
                local translation = animationGroup:CreateAnimation("Translation")
                translation:SetTarget(line)
                translation:SetOrder(order)
                translation:SetOffset(side.xTravel * progress, side.yTravel * progress)
                translation:SetDuration(side.duration * progress)
            end
        end

        local function AddCornerSegment(outgoingSide, outgoingLine, incomingSide, startProgress, endProgress, showOutgoing)
            order = order + 1
            local progressRange = endProgress - startProgress
            if showOutgoing then
                local reveal = animationGroup:CreateAnimation("Alpha")
                reveal:SetTarget(outgoingLine)
                reveal:SetOrder(order)
                reveal:SetFromAlpha(0)
                reveal:SetToAlpha(1)
                reveal:SetDuration(0.001)
            end

            local shrink = animationGroup:CreateAnimation("Scale")
            shrink:SetTarget(outgoingLine)
            shrink:SetOrder(order)
            local outgoingStartScale = math.max(1 - startProgress, 0.001)
            local outgoingEndScale = math.max(1 - endProgress, 0.001)
            shrink:SetScaleFrom(outgoingSide.horizontal and outgoingStartScale or 1, outgoingSide.horizontal and 1 or outgoingStartScale)
            shrink:SetScaleTo(outgoingSide.horizontal and outgoingEndScale or 1, outgoingSide.horizontal and 1 or outgoingEndScale)
            shrink:SetOrigin(outgoingSide.outgoingOrigin, 0, 0)
            shrink:SetDuration(cornerDuration * progressRange)

            local incomingLine = CreatePixelGlowLine(incomingSide, 0)
            local reveal = animationGroup:CreateAnimation("Alpha")
            reveal:SetTarget(incomingLine)
            reveal:SetOrder(order)
            reveal:SetFromAlpha(0)
            reveal:SetToAlpha(1)
            reveal:SetDuration(0.001)

            local grow = animationGroup:CreateAnimation("Scale")
            grow:SetTarget(incomingLine)
            grow:SetOrder(order)
            local incomingStartScale = math.max(startProgress, 0.001)
            local incomingEndScale = math.max(endProgress, 0.001)
            grow:SetScaleFrom(incomingSide.horizontal and incomingStartScale or 1, incomingSide.horizontal and 1 or incomingStartScale)
            grow:SetScaleTo(incomingSide.horizontal and incomingEndScale or 1, incomingSide.horizontal and 1 or incomingEndScale)
            grow:SetOrigin(incomingSide.incomingOrigin, 0, 0)
            grow:SetDuration(cornerDuration * progressRange)
            return incomingLine
        end

        local startIndex, startKind, startProgress = GetPixelGlowPathPosition(startDistance)
        local side = sides[startIndex]
        if startKind == "straight" then
            local line = CreatePixelGlowLine(side, startProgress)
            AddStraightSegment(side, line, 1 - startProgress, true)

            for offset = 1, 4 do
                local nextIndex = startIndex % #sides + 1
                local nextSide = sides[nextIndex]
                line = AddCornerSegment(side, line, nextSide, 0, 1, false)
                side = nextSide
                startIndex = nextIndex
                if offset < 4 then
                    AddStraightSegment(side, line, 1, false)
                end
            end

            if startProgress > 0 then
                AddStraightSegment(side, line, startProgress, false)
            end
        else
            local nextIndex = startIndex % #sides + 1
            local line = CreatePixelGlowLine(side, 1)
            side = sides[nextIndex]
            line = AddCornerSegment(sides[startIndex], line, side, startProgress, 1, true)
            startIndex = nextIndex

            for offset = 1, 4 do
                AddStraightSegment(side, line, 1, false)
                local followingIndex = startIndex % #sides + 1
                local followingSide = sides[followingIndex]
                line = AddCornerSegment(side, line, followingSide, 0, offset < 4 and 1 or startProgress, false)
                side = followingSide
                startIndex = followingIndex
            end
        end
        if preview then
            animationGroup:Play()
        else
            button:AddAuraShownAnimation(animationGroup)
        end
    end

    for index = 0, numberOfLines - 1 do
        AddPixelGlowRunner(perimeter * index / numberOfLines)
    end
end

function NSI:IsAuraGlowPreviewActive(key)
    return self.AuraGlowPreviewActive and self.AuraGlowPreviewKey == key
end

function NSI:HideAuraGlowPreview(refreshUI)
    if self.AuraGlowPreviewTimer then
        self.AuraGlowPreviewTimer:Cancel()
        self.AuraGlowPreviewTimer = nil
    end
    if self.AuraGlowPreviewFrame then
        self.AuraGlowPreviewFrame:SetScript("OnUpdate", nil)
        self.AuraGlowPreviewFrame:Hide()
        self.AuraGlowPreviewFrame = nil
    end
    self.AuraGlowPreviewActive = false
    self.AuraGlowPreviewKey = nil
    if refreshUI ~= false then self:RefreshAuraGlowsUI() end
end

function NSI:ToggleAuraGlowPreview(key, refreshUI)
    if self:IsAuraGlowPreviewActive(key) then
        self:HideAuraGlowPreview(refreshUI)
        return false
    end
    if self.IsBuilding or self:Restricted() then return false end

    local settings = self:GetAuraGlowSettings(key)
    if not settings then return false end

    self:HideAuraGlowPreview(false)
    local targetFrame = self.UnitFrames and self.UnitFrames.player
    if not targetFrame then
        targetFrame = self.LGF.GetUnitFrame("player")
    end
    if not targetFrame then return false end
    local spellIDs = UsesAuraGlowSpellIDs(settings) and GetAuraGlowSpellIDs(settings) or {}
    local iconTexture = settings.menuIcon and C_Spell.GetSpellTexture(settings.menuIcon)
    if settings.customIcon then
        iconTexture = C_Spell.GetSpellTexture(settings.customIcon) or iconTexture
    end
    if not iconTexture and spellIDs[1] then
        iconTexture = C_Spell.GetSpellTexture(spellIDs[1])
    end
    local previewFrame = CreateFrame("Frame", nil, UIParent)
    previewFrame:SetAllPoints(targetFrame)
    previewFrame:SetFrameStrata("TOOLTIP")
    previewFrame:SetFrameLevel(targetFrame:GetFrameLevel() + 1)
    previewFrame:Show()
    local icon = CreateAuraGlowIcon(previewFrame, settings, iconTexture or 134400)
    if settings.ShowIcon and settings.ShowDurationSwipe ~= false then
        local cooldown = CreateFrame("Cooldown", nil, previewFrame, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetFrameLevel(previewFrame:GetFrameLevel() + 1)
        cooldown:SetDrawBling(false)
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(true)
        cooldown:SetReverse(true)
        cooldown:SetCooldown(GetTime(), 10)
        cooldown:Show()
    end
    if settings.ShowIcon and settings.ShowDurationText then
        local textOverlay = CreateFrame("Frame", nil, previewFrame)
        textOverlay:SetAllPoints(previewFrame)
        textOverlay:SetFrameLevel(previewFrame:GetFrameLevel() + 2)
        textOverlay:EnableMouse(false)
        local duration = textOverlay:CreateFontString(nil, "OVERLAY")
        duration:SetPoint("CENTER", icon, "CENTER")
        local fontPath = self.LSM:Fetch("font", settings.DurationFont or "Expressway")
        duration:SetFont(fontPath, settings.DurationFontSize or 10, "OUTLINE")
        duration:SetTextColor(unpack(settings.DurationColor or {1, 1, 1, 1}))
        local previewStartedAt = GetTime()
        previewFrame:SetScript("OnUpdate", function()
            duration:SetText(tostring(math.ceil(math.max(10 - (GetTime() - previewStartedAt), 0))))
        end)
        duration:SetText("10")
    end
    CreateAuraGlowBorder(previewFrame, settings, true)

    self.AuraGlowPreviewFrame = previewFrame
    self.AuraGlowPreviewKey = key
    self.AuraGlowPreviewActive = true
    local previewTimer
    previewTimer = C_Timer.NewTimer(10, function()
        if self.AuraGlowPreviewTimer == previewTimer and self:IsAuraGlowPreviewActive(key) then
            self.AuraGlowPreviewTimer = nil
            self:HideAuraGlowPreview()
        end
    end)
    self.AuraGlowPreviewTimer = previewTimer
    if refreshUI ~= false then self:RefreshAuraGlowsUI() end
    return true
end

function NSI:RefreshAuraGlowPreview(key)
    if not self:IsAuraGlowPreviewActive(key) then return false end
    self:HideAuraGlowPreview(false)
    return self:ToggleAuraGlowPreview(key, false)
end

local function IsAuraGlowActive(self, key, settings)
    if not settings.enabled then return false end
    local loadMatches
    if self.AuraGlowLoadCache then
        loadMatches = self.AuraGlowLoadCache[key]
        if loadMatches == nil then
            loadMatches = self:EvaluateLoad(settings)
            self.AuraGlowLoadCache[key] = loadMatches
        end
    else
        loadMatches = self:EvaluateLoad(settings)
    end
    if not loadMatches then return false end
    local manualState = self.AuraGlowManualState and self.AuraGlowManualState[key]
    return manualState == nil or manualState
end

function NSI:UpdateAuraGlowVisibility(onlyKey)
    for key, states in pairs(self.AuraGlowStates or {}) do
        if not onlyKey or key == onlyKey then
            local settings = self:GetAuraGlowSettings(key)
            local enabled = settings and IsAuraGlowActive(self, key, settings)
            for _, state in pairs(states) do
                state.container:SetEnabled(enabled)
                state.container:SetShown(enabled)
            end
        end
    end
end

function NSI:RebuildAuraGlows(key)
    local auraGlowStates = self.AuraGlowStates or {}
    local statesToRebuild = key and { [key] = auraGlowStates[key] } or auraGlowStates
    for _, states in pairs(statesToRebuild or {}) do
        for _, state in pairs(states) do
            state.container:Hide()
        end
    end
    if key then
        self.AuraGlowStates = auraGlowStates
        self.AuraGlowStates[key] = nil
        self:InitAuraGlows(key)
    else
        self.AuraGlowStates = {}
        self:InitAuraGlows()
    end
end

function NSI:InitAuraGlows(onlyKey)
    if self.IsBuilding then return end
    if self:Restricted() then
        self.PendingAuraGlowUpdate = true
        return
    end
    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end
    self.PendingAuraGlowUpdate = nil
    self.AuraGlowStates = self.AuraGlowStates or {}
    local activeKeys = {}
    for _, entry in ipairs(self:IterateAuraGlowEntries()) do
        local key, settings = entry.key, entry.settings
        local usesSpellIDs = UsesAuraGlowSpellIDs(settings)
        if (not onlyKey or key == onlyKey) and (not usesSpellIDs or #GetAuraGlowSpellIDs(settings) > 0) then
            activeKeys[key] = true
            self.AuraGlowStates[key] = self.AuraGlowStates[key] or {}
            local states = self.AuraGlowStates[key]
            for unit in self:IterateGroupMembers() do
                local targetFrame = self.UnitFrames and self.UnitFrames[unit]
                if targetFrame then
                    local state = states[unit]
                    if not state then
                        local container = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
                        local processedAuraType = not usesSpellIDs and settings.CandidateFilters and settings.CandidateFilters.ProcessedAuraType
                        local policy = processedAuraType and processedAuraType ~= "Disabled"
                            and CustomAuraContainerAuraProcessingPolicy.ProcessAura
                            or CustomAuraContainerAuraProcessingPolicy.None
                        container:SetAuraProcessingPolicy(policy)
                        container:SetUnit(unit)
                        container:SetAllPoints(targetFrame)
                        container:SetFrameStrata("TOOLTIP")
                        -- Each AuraContainer aura slot has one stable aura frame, so one slot caps this glow at one icon.
                        local slot = container:AddAuraSlot("Glow", BuildAuraGlowFilterString(settings), {
                            maxFrameCount = 1,
                            candidateFilters = BuildAuraGlowCandidateFilters(settings),
                            initializeFrame = function(button)
                                button:SetAllPoints(container)
                                button:SetMouseMotionEnabled(false)
                                local icon = CreateAuraGlowIcon(button, settings)
                                button:SetIcon(icon)
                                if settings.ShowIcon and settings.ShowDurationText then
                                    local textOverlay = CreateFrame("Frame", nil, button)
                                    textOverlay:SetAllPoints(button)
                                    textOverlay:SetFrameLevel(button:GetFrameLevel() + 3)
                                    textOverlay:EnableMouse(false)
                                    local duration = textOverlay:CreateFontString(nil, "OVERLAY")
                                    duration:SetPoint("CENTER", icon, "CENTER")
                                    local fontPath = self.LSM:Fetch("font", settings.DurationFont or "Expressway")
                                    duration:SetFont(fontPath, settings.DurationFontSize or 10, "OUTLINE")
                                    duration:SetTextColor(unpack(settings.DurationColor or {1, 1, 1, 1}))
                                    button:SetDurationText(duration, {textFormatter = AuraGlowDurationFormatter})
                                else
                                    button:ClearDurationText()
                                end
                                if settings.ShowIcon and settings.ShowDurationSwipe ~= false then
                                    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
                                    cooldown:SetAllPoints(icon)
                                    cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
                                    cooldown:SetDrawBling(false)
                                    cooldown:SetDrawEdge(false)
                                    cooldown:SetHideCountdownNumbers(true)
                                    cooldown:SetReverse(true)
                                    cooldown:Show()
                                    button:SetDurationCooldown(cooldown)
                                else
                                    button:ClearDurationCooldown()
                                end
                                CreateAuraGlowBorder(button, settings)
                            end,
                        })
                        state = { container = container, slot = slot }
                        states[unit] = state
                    end
                end
            end
        end
    end
    for key, states in pairs(self.AuraGlowStates) do
        if not onlyKey or key == onlyKey then
            for unit, state in pairs(states) do
                if not activeKeys[key] or not UnitExists(unit) then
                    state.container:Hide()
                end
            end
        end
    end
    self:UpdateAuraGlowVisibility(onlyKey)
end

function NSI:RefreshAuraGlows()
    self:RebuildAuraGlows()
end

function NSI:RefreshAuraGlowsUI()
    if self._RefreshAuraGlowsUI then
        self._RefreshAuraGlowsUI()
    end
end
