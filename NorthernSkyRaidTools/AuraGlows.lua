local _, NSI = ...
local auraGlowBuildFrame

NSI.AuraGlowBuiltins = NSI.AuraGlowBuiltins or {}
NSI.AuraGlowDefaultSettingsKey = "DefaultSettings"

local AuraGlowDisplaySettingKeys = {
    "Size", "IconSize", "IconPosition", "IconOffsetX", "IconOffsetY",
    "NumberOfLines", "LineSize", "Frequency", "ShowBackground", "ShowIcon",
    "ShowDurationSwipe", "ShowDurationText", "DurationFont", "DurationFontSize", "DurationColor",
}

local AuraGlowSides = {
    { point = "TOPLEFT", x = 1, y = 0, horizontal = true },
    { point = "TOPRIGHT", x = 0, y = -1 },
    { point = "BOTTOMRIGHT", x = -1, y = 0, horizontal = true },
    { point = "BOTTOMLEFT", x = 0, y = 1 },
}

local AuraGlowPatternSize = 1024
local AuraGlowPatternTexture = [[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\AuraGlowPattern.png]]

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

local function BuildAuraGlowCandidateFilters(settings, spellIDs)
    local configured = settings.CandidateFilters or {}
    local filters = {}
    filters.excludeSpellIDs = NSI.AuraTrackingExcludedSpellIDs
    if UsesAuraGlowSpellIDs(settings) then
        filters.includeSpellIDs = {}
        for _, spellID in ipairs(spellIDs or GetAuraGlowSpellIDs(settings)) do
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

function NSI:ResetAuraGlow(key)
    if self.AuraGlowBuiltins[key] then
        NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
        NSRT.AuraGlows.Builtins = NSRT.AuraGlows.Builtins or {}
        NSRT.AuraGlows.Builtins[key] = CreateBuiltinAuraGlowSettings(self, key, true)
    else
        local settings = self:GetAuraGlowSettings(key)
        if not settings or key == self.AuraGlowDefaultSettingsKey then return end
        CopyAuraGlowDisplaySettings(settings, GetAuraGlowDefaultSettings(self))
    end
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
    self:InitAuraGlows()
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
    local settings = self:CreateAuraGlowSettingsDefaults({ Name = self:Loc("Custom Aura Glow") .. " " .. index, group = group ~= "" and group or nil })
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
    copy.Name = (copy.Name or "Custom Aura Glow") .. NSI:Loc("DUPLICATE_SUFFIX")
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
    if active == false then
        self:UpdateAuraGlowVisibility(key)
    else
        self:InitAuraGlows(key)
    end
end

function NSI:ActivateBuiltinAuraGlow(key)
    self:SetBuiltinAuraGlowActive(key, true)
end

function NSI:DeactivateBuiltinAuraGlow(key)
    self:SetBuiltinAuraGlowActive(key, false)
end

local function ConfigureAuraGlowBorder(button, settings, display, preview, width, height)
    local border = display.border
    if not border then
        border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", button, "TOPLEFT", 0.05, 0.05)
        border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0.05)
        display.border = border
        display.runners = {}
        display.patternEdges = {}
        display.edgeClips = {}
        for index = 1, 4 do
            local clipTexture = border:CreateMaskTexture()
            clipTexture:SetTexture([[Interface\Buttons\WHITE8x8]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            display.edgeClips[index] = clipTexture
        end
    end
    border:SetFrameLevel(button:GetFrameLevel() + 8)

    local numberOfLines = settings.NumberOfLines
    local lineLength = settings.LineSize
    if lineLength == 0 then
        lineLength = math.max(1, math.floor((width + height) * (2 / numberOfLines - 0.1)))
    end
    lineLength = math.min(lineLength, math.min(width, height))
    local thickness = settings.Size or 1
    if settings.ShowBackground and not display.background then
        local clipTexture = border:CreateMaskTexture()
        clipTexture:SetTexture([[Interface\AdventureMap\BrokenIsles\AM_29]], "CLAMPTOWHITE", "CLAMPTOWHITE")
        local background = border:CreateTexture(nil, "ARTWORK", nil, 6)
        background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        background:SetAllPoints(border)
        background:AddMaskTexture(clipTexture)
        display.backgroundMask = clipTexture
        display.background = background
    end
    if display.background then
        display.backgroundMask:ClearAllPoints()
        display.backgroundMask:SetPoint("TOPLEFT", border, "TOPLEFT", thickness + 1, -thickness - 1)
        display.backgroundMask:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -thickness - 1, thickness + 1)
        display.background:SetShown(settings.ShowBackground)
    end
    for index, side in ipairs(AuraGlowSides) do
        local clipTexture = display.edgeClips[index]
        clipTexture:ClearAllPoints()
        clipTexture:SetPoint(side.point, border, side.point)
        clipTexture:SetSize(side.horizontal and width or thickness, side.horizontal and thickness or height)
    end

    local outlineLength = 2 * (width + height)
    local lineSpacing = outlineLength / numberOfLines
    local completeLines = math.floor(lineLength / lineSpacing)
    local remainder = lineLength - completeLines * lineSpacing
    local patternRow = math.floor(remainder / lineSpacing * AuraGlowPatternSize + 0.5)
    local red, green, blue, alpha = unpack(settings.Color)
    local overlapAlpha = 1 - (1 - alpha) ^ completeLines
    local hasPattern = remainder > 0 and overlapAlpha < 1 and alpha > 0
    -- Cap raster rounding at 1/8 UI pixel; very small gaps use exact geometry instead.
    local usePattern = not hasPattern or (lineSpacing <= AuraGlowPatternSize / 4 and patternRow > 0 and patternRow < AuraGlowPatternSize)
    if usePattern then
        for _, runner in ipairs(display.runners) do
            runner.animationGroup:Stop()
            if runner.registered then
                button:RemoveAuraShownAnimation(runner.animationGroup)
                runner.registered = nil
            end
            for _, edge in ipairs(runner.edges) do edge.line:Hide() end
        end
        local edgeDistance = 0
        for index, side in ipairs(AuraGlowSides) do
            local edge = display.patternEdges[index]
            if not edge then
                edge = {}
                display.patternEdges[index] = edge
            end
            if edge.animationGroup then edge.animationGroup:Stop() end
            if overlapAlpha > 0 and not edge.overlapTexture then
                edge.overlapTexture = border:CreateTexture(nil, "ARTWORK", nil, 7)
                edge.overlapTexture:SetTexture([[Interface\Buttons\WHITE8x8]])
            end
            if edge.overlapTexture then
                edge.overlapTexture:ClearAllPoints()
                edge.overlapTexture:SetPoint(side.point, border, side.point)
                edge.overlapTexture:SetSize(side.horizontal and width or thickness, side.horizontal and thickness or height)
                -- Full overlaps contribute a constant layer; the remaining partial dash adds one more.
                edge.overlapTexture:SetVertexColor(red, green, blue, overlapAlpha)
                edge.overlapTexture:SetShown(overlapAlpha > 0)
            end
            if hasPattern then
                if not edge.line then
                    local line = border:CreateTexture(nil, "ARTWORK", nil, 7)
                    line:SetTexture(AuraGlowPatternTexture, "REPEAT", "CLAMPTOBLACKADDITIVE", "NEAREST")
                    line:AddMaskTexture(display.edgeClips[index])
                    local animationGroup = line:CreateAnimationGroup()
                    animationGroup:SetLooping("REPEAT")
                    local travelAnimation = animationGroup:CreateAnimation("Translation")
                    travelAnimation:SetOrder(1)
                    travelAnimation:SetSmoothing("NONE")
                    edge.line, edge.animationGroup, edge.travelAnimation = line, animationGroup, travelAnimation
                end
                local sideLength = side.horizontal and width or height
                local textureStart = (edgeDistance / lineSpacing) % 1 - 1
                local textureEnd = textureStart + (sideLength + lineSpacing) / lineSpacing
                local textureRow = (patternRow + 0.5) / AuraGlowPatternSize
                local line = edge.line
                line:ClearAllPoints()
                line:SetPoint(side.point, border, side.point, -lineSpacing * side.x, -lineSpacing * side.y)
                line:SetSize(side.horizontal and (width + lineSpacing) or thickness, side.horizontal and thickness or (height + lineSpacing))
                line:SetVertexColor(red, green, blue, alpha)
                if index == 1 then
                    line:SetTexCoord(textureStart, textureEnd, textureRow, textureRow)
                elseif index == 2 then
                    line:SetTexCoord(textureStart, textureRow, textureEnd, textureRow, textureStart, textureRow, textureEnd, textureRow)
                elseif index == 3 then
                    line:SetTexCoord(textureEnd, textureStart, textureRow, textureRow)
                else
                    line:SetTexCoord(textureEnd, textureRow, textureStart, textureRow, textureEnd, textureRow, textureStart, textureRow)
                end
                line:Show()
                edge.travelAnimation:SetOffset(lineSpacing * side.x, lineSpacing * side.y)
                edge.travelAnimation:SetDuration(1 / (numberOfLines * settings.Frequency))
                if preview then
                    edge.animationGroup:Play()
                elseif not edge.registered then
                    button:AddAuraShownAnimation(edge.animationGroup)
                    edge.registered = true
                end
            else
                if edge.registered then
                    button:RemoveAuraShownAnimation(edge.animationGroup)
                    edge.registered = nil
                end
                if edge.line then edge.line:Hide() end
            end
            edgeDistance = edgeDistance + (side.horizontal and width or height)
        end
        return
    end
    for _, edge in ipairs(display.patternEdges) do
        if edge.animationGroup then edge.animationGroup:Stop() end
        if edge.registered then
            button:RemoveAuraShownAnimation(edge.animationGroup)
            edge.registered = nil
        end
        if edge.line then edge.line:Hide() end
        if edge.overlapTexture then edge.overlapTexture:Hide() end
    end
    local speed = outlineLength * settings.Frequency
    for index = 1, math.max(numberOfLines, #display.runners) do
        local runner = display.runners[index]
        if runner then runner.animationGroup:Stop() end
        if index <= numberOfLines then
            if not runner then
                local animationGroup = border:CreateAnimationGroup()
                animationGroup:SetLooping("REPEAT")
                runner = { animationGroup = animationGroup, edges = {} }
                display.runners[index] = runner
                for sideIndex = 1, 4 do
                    local line = border:CreateTexture(nil, "ARTWORK", nil, 7)
                    line:SetTexture([[Interface\Buttons\WHITE8x8]])
                    line:AddMaskTexture(display.edgeClips[sideIndex])
                    local edge = { line = line, translations = {} }
                    for animationIndex = 1, 2 do
                        local translation = animationGroup:CreateAnimation("Translation")
                        translation:SetTarget(line)
                        translation:SetOrder(1)
                        translation:SetSmoothing("NONE")
                        edge.translations[animationIndex] = translation
                    end
                    runner.edges[sideIndex] = edge
                end
            end
            local startDistance = outlineLength * (index - 1) / numberOfLines
            local edgeDistance = 0
            for sideIndex, side in ipairs(AuraGlowSides) do
                local edge = runner.edges[sideIndex]
                local sideLength = side.horizontal and width or height
                local position = (startDistance - edgeDistance) % outlineLength
                if position >= sideLength then position = position - outlineLength end
                local travel = sideLength - position
                local duration = travel / speed
                local line = edge.line
                line:ClearAllPoints()
                line:SetPoint(side.point, border, side.point, position * side.x, position * side.y)
                line:SetSize(side.horizontal and lineLength or thickness, side.horizontal and thickness or lineLength)
                line:SetVertexColor(unpack(settings.Color))
                line:Show()

                -- Clipping a moving line to each edge preserves the shrinking/growing corner split.
                -- Reset it instantly only after it has completely left that edge's mask.
                local travelAnimation, reset = unpack(edge.translations)
                travelAnimation:SetOffset(outlineLength * side.x, outlineLength * side.y)
                travelAnimation:SetDuration(1 / settings.Frequency)
                reset:SetOffset(-outlineLength * side.x, -outlineLength * side.y)
                reset:SetStartDelay(duration)
                reset:SetDuration(0)
                edgeDistance = edgeDistance + sideLength
            end
            if preview then
                runner.animationGroup:Play()
            elseif not runner.registered then
                -- Blizzard forbids adding animations or changing their targets after registration.
                button:AddAuraShownAnimation(runner.animationGroup)
                runner.registered = true
            end
        elseif runner then
            if runner.registered then
                button:RemoveAuraShownAnimation(runner.animationGroup)
                runner.registered = nil
            end
            for _, edge in ipairs(runner.edges) do edge.line:Hide() end
        end
    end
end

local function ConfigureAuraGlowDisplay(self, button, settings, display, targetFrame, previewTexture)
    local preview = previewTexture ~= nil
    local icon = display.icon
    local refresh = icon ~= nil
    if not icon then
        icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
        display.icon = icon
    end
    icon:ClearAllPoints()
    icon:SetSize(settings.IconSize or 20, settings.IconSize or 20)
    local iconPosition = settings.IconPosition or "CENTER"
    icon:SetPoint(iconPosition, button, iconPosition, settings.IconOffsetX or 0, settings.IconOffsetY or 0)
    icon:SetAlpha(settings.ShowIcon and 1 or 0)
    if preview then icon:SetTexture(previewTexture) end
    if settings.ShowIcon and not display.iconBorder then
        display.iconBorder = {}
        for index, side in ipairs(AuraGlowSides) do
            local texture = button:CreateTexture(nil, "OVERLAY")
            texture:SetColorTexture(0, 0, 0, 1)
            texture:SetPoint(side.point, icon, side.point)
            texture:SetPoint(AuraGlowSides[index % 4 + 1].point, icon, AuraGlowSides[index % 4 + 1].point)
            if side.horizontal then texture:SetHeight(1) else texture:SetWidth(1) end
            display.iconBorder[index] = texture
        end
    end
    if display.iconBorder then
        for _, texture in ipairs(display.iconBorder) do texture:SetShown(settings.ShowIcon) end
    end
    if settings.ShowIcon and settings.ShowDurationText and not display.duration then
        local overlay = CreateFrame("Frame", nil, button)
        overlay:SetAllPoints(button)
        overlay:EnableMouse(false)
        local duration = overlay:CreateFontString(nil, "OVERLAY")
        duration:SetPoint("CENTER", icon, "CENTER")
        display.duration = duration
        display.textOverlay = overlay
    end
    if display.duration then
        display.textOverlay:SetFrameLevel(button:GetFrameLevel() + (preview and 2 or 3))
        local fontPath = self.LSM:Fetch("font", settings.DurationFont or "Expressway")
        display.duration:SetFont(fontPath, settings.DurationFontSize or 10, "OUTLINE")
        display.duration:SetTextColor(unpack(settings.DurationColor or {1, 1, 1, 1}))
        display.duration:SetShown(settings.ShowIcon and settings.ShowDurationText)
    end
    if settings.ShowIcon and settings.ShowDurationSwipe ~= false and not display.cooldown then
        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetDrawBling(false)
        cooldown:SetDrawEdge(false)
        cooldown:SetHideCountdownNumbers(true)
        cooldown:SetReverse(true)
        display.cooldown = cooldown
    end
    if display.cooldown then
        display.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        display.cooldown:SetShown(settings.ShowIcon and settings.ShowDurationSwipe ~= false)
    end
    -- Existing aura buttons return secret dimensions even outside aura restrictions.
    local width, height = targetFrame:GetSize()
    ConfigureAuraGlowBorder(button, settings, display, preview, width, height)
    if not preview then
        if settings.ShowIcon and settings.ShowDurationText then
            button:SetDurationText(display.duration, {textFormatter = AuraGlowDurationFormatter})
        else
            button:ClearDurationText()
        end
        if settings.ShowIcon and settings.ShowDurationSwipe ~= false then
            button:SetDurationCooldown(display.cooldown)
        else
            button:ClearDurationCooldown()
        end
        if refresh then
            -- A visible aura will not trigger a new show transition after its animations were stopped.
            for _, edge in ipairs(display.patternEdges) do
                if edge.registered then edge.animationGroup:Play() end
            end
            for _, runner in ipairs(display.runners) do
                if runner.registered then runner.animationGroup:Play() end
            end
        end
        -- Reapply aura visibility so empty slots stay stopped after a settings refresh.
        button:SetIcon(icon)
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
        for _, runner in ipairs(self.AuraGlowPreviewDisplay.runners) do runner.animationGroup:Stop() end
        for _, edge in ipairs(self.AuraGlowPreviewDisplay.patternEdges) do
            if edge.animationGroup then edge.animationGroup:Stop() end
        end
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
    local previewFrame = self.AuraGlowPreviewFrame
    if not previewFrame then
        previewFrame = CreateFrame("Frame", nil, UIParent)
        self.AuraGlowPreviewFrame = previewFrame
        self.AuraGlowPreviewDisplay = {}
    end
    previewFrame:ClearAllPoints()
    previewFrame:SetAllPoints(targetFrame)
    previewFrame:SetFrameStrata("TOOLTIP")
    previewFrame:SetFrameLevel(targetFrame:GetFrameLevel() + 1)
    previewFrame:Show()
    local display = self.AuraGlowPreviewDisplay
    ConfigureAuraGlowDisplay(self, previewFrame, settings, display, targetFrame, iconTexture or 134400)
    if settings.ShowIcon and settings.ShowDurationSwipe ~= false then
        display.cooldown:SetCooldown(GetTime(), 10)
    end
    if settings.ShowIcon and settings.ShowDurationText then
        local duration = display.duration
        local previewStartedAt = GetTime()
        previewFrame:SetScript("OnUpdate", function()
            duration:SetText(tostring(math.ceil(math.max(10 - (GetTime() - previewStartedAt), 0))))
        end)
        duration:SetText("10")
    end
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
            local active = settings and IsAuraGlowActive(self, key, settings)
            for unit, state in pairs(states) do
                local enabled = active == true and state.available == true and UnitExists(unit)
                    and self.UnitFrames and self.UnitFrames[unit] ~= nil or false
                if state.enabled ~= enabled then
                    state.container:SetEnabled(enabled)
                    state.container:SetShown(enabled)
                    state.enabled = enabled
                end
            end
        end
    end
end

local function ConfigureAuraGlowState(self, state, work)
    local settings = work.settings
    local container = state and state.container
    if not container then
        container = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
        state = { container = container, display = {} }
        container:SetUnit(work.unit)
        container:SetFrameStrata("TOOLTIP")
        container:SetEnabled(false)
    end
    if state.targetFrame ~= work.targetFrame then
        container:ClearAllPoints()
        container:SetAllPoints(work.targetFrame)
        state.targetFrame = work.targetFrame
    end
    local processedAuraType = not work.usesSpellIDs and settings.CandidateFilters and settings.CandidateFilters.ProcessedAuraType
    local policy = processedAuraType and processedAuraType ~= "Disabled"
        and CustomAuraContainerAuraProcessingPolicy.ProcessAura
        or CustomAuraContainerAuraProcessingPolicy.None
    if state.policy ~= policy then
        container:SetAuraProcessingPolicy(policy)
        state.policy = policy
    end
    if not state.slot then
        state.slot = container:AddAuraSlot("Glow", work.filterString, {
            maxFrameCount = 1,
            candidateFilters = work.candidateFilters,
            initializeFrame = function(button)
                button:SetAllPoints(container)
                button:SetMouseMotionEnabled(false)
                ConfigureAuraGlowDisplay(self, button, settings, state.display, work.targetFrame)
            end,
        })
    else
        if state.filterString ~= work.filterString then
            container:SetAuraSlotFilterString("Glow", work.filterString)
        end
        if state.filterSignature ~= work.filterSignature then
            container:SetAuraSlotCandidateFilters("Glow", work.candidateFilters)
        end
        ConfigureAuraGlowDisplay(self, state.slot, settings, state.display, work.targetFrame)
    end
    state.filterString = work.filterString
    state.filterSignature = work.filterSignature
    state.settings = settings
    state.width, state.height = work.targetFrame:GetSize()
    state.available = work.hasCandidates
    state.dirty = nil
    local enabled = work.hasCandidates and IsAuraGlowActive(self, work.key, settings)
    container:SetEnabled(enabled)
    container:SetShown(enabled)
    state.enabled = enabled
    return state
end

function NSI:RebuildAuraGlows(key)
    for stateKey, states in pairs(self.AuraGlowStates or {}) do
        if not key or key == stateKey then
            for _, state in pairs(states) do state.dirty = true end
        end
    end
    if self:Restricted() then
        self.PendingAuraGlowUpdate = true
        self.PendingAuraGlowRebuild = true
        return
    end
    self.PendingAuraGlowRebuild = nil
    self:InitAuraGlows(key)
end

function NSI:InitAuraGlows(onlyKey)
    if self.IsBuilding then return end
    self.AuraGlowBuildGeneration = (self.AuraGlowBuildGeneration or 0) + 1
    local generation = self.AuraGlowBuildGeneration
    local queue = {}
    if auraGlowBuildFrame then
        -- A targeted refresh must keep unfinished work for the other entries.
        if onlyKey and auraGlowBuildFrame.queue then
            for index = auraGlowBuildFrame.nextIndex, #auraGlowBuildFrame.queue do
                local work = auraGlowBuildFrame.queue[index]
                if work.key ~= onlyKey then queue[#queue + 1] = work end
            end
        end
        auraGlowBuildFrame:Hide()
        auraGlowBuildFrame.queue = nil
    end
    self.AuraGlowBuildPending = false
    self.PendingAuraGlowUpdate = nil
    self.AuraGlowStates = self.AuraGlowStates or {}
    self.UnitFrames = self.UnitFrames or {}
    local entries = self:IterateAuraGlowEntries()
    local restricted = self:Restricted()
    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        for _, entry in ipairs(entries) do
            if entry.settings.enabled then
                if restricted then
                    self.PendingAuraGlowUpdate = true
                    return
                end
                C_AddOns.LoadAddOn("Blizzard_AuraContainer")
                break
            end
        end
    end
    local activeKeys = {}
    for _, entry in ipairs(entries) do
        local key, settings = entry.key, entry.settings
        if not onlyKey or onlyKey == key then
            local usesSpellIDs = UsesAuraGlowSpellIDs(settings)
            local spellIDs = usesSpellIDs and GetAuraGlowSpellIDs(settings) or nil
            local hasCandidates = not usesSpellIDs or #spellIDs > 0
            activeKeys[key] = true
            self.AuraGlowStates[key] = self.AuraGlowStates[key] or {}
            local states = self.AuraGlowStates[key]
            local shouldCreate = hasCandidates and IsAuraGlowActive(self, key, settings)
            local filterString, candidateFilters, filterSignature
            for unit in self:IterateGroupMembers() do
                local targetFrame = self.UnitFrames and self.UnitFrames[unit]
                local state = states[unit]
                if state then state.available = hasCandidates end
                if not targetFrame and (state or shouldCreate) then
                    targetFrame = self.LGF.GetUnitFrame(unit)
                    self.UnitFrames[unit] = targetFrame
                end
                if targetFrame then
                    local width, height = targetFrame:GetSize()
                    local needsConfigure = state and (state.dirty or state.settings ~= settings
                        or state.targetFrame ~= targetFrame or state.width ~= width or state.height ~= height)
                    if needsConfigure and restricted then
                        state.dirty = true
                        self.PendingAuraGlowRebuild = true
                    elseif needsConfigure or (not state and shouldCreate) then
                        if not filterString then
                            filterString = BuildAuraGlowFilterString(settings)
                            candidateFilters = BuildAuraGlowCandidateFilters(settings, spellIDs)
                            local signature = {}
                            for filter, value in pairs(candidateFilters) do
                                if type(value) == "table" then
                                    for candidate, enabled in pairs(value) do
                                        signature[#signature + 1] = filter .. ":" .. tostring(candidate) .. "=" .. tostring(enabled)
                                    end
                                else
                                    signature[#signature + 1] = filter .. "=" .. tostring(value)
                                end
                            end
                            table.sort(signature)
                            filterSignature = table.concat(signature, "|")
                        end
                        queue[#queue + 1] = {
                            key = key, settings = settings, unit = unit, state = state,
                            targetFrame = targetFrame, filterString = filterString,
                            candidateFilters = candidateFilters, filterSignature = filterSignature,
                            usesSpellIDs = usesSpellIDs, hasCandidates = hasCandidates,
                        }
                    end
                end
            end
        end
    end
    for key, states in pairs(self.AuraGlowStates) do
        if (not onlyKey or key == onlyKey) and not activeKeys[key] then
            for _, state in pairs(states) do state.available = false end
        end
    end
    self:UpdateAuraGlowVisibility(onlyKey)
    if #queue == 0 then return end
    self.AuraGlowBuildPending = true
    if not auraGlowBuildFrame then
        auraGlowBuildFrame = CreateFrame("Frame")
        auraGlowBuildFrame:SetScript("OnUpdate", function(frame)
            if frame.generation ~= self.AuraGlowBuildGeneration then
                frame:Hide()
                frame.queue = nil
                return
            end
            if self.IsBuilding then return end
            local remaining = 3
            while remaining > 0 and frame.nextIndex <= #frame.queue do
                local work = frame.queue[frame.nextIndex]
                frame.nextIndex = frame.nextIndex + 1
                remaining = remaining - 1
                local states = self.AuraGlowStates[work.key]
                if self:GetAuraGlowSettings(work.key) == work.settings and states and states[work.unit] == work.state
                    and (work.state or IsAuraGlowActive(self, work.key, work.settings)) then
                    local targetFrame = self.UnitFrames and self.UnitFrames[work.unit]
                    if targetFrame and UnitExists(work.unit) then
                        if work.state and self:Restricted() then
                            work.state.dirty = true
                            self.PendingAuraGlowRebuild = true
                        else
                            work.targetFrame = targetFrame
                            states[work.unit] = ConfigureAuraGlowState(self, work.state, work)
                        end
                    end
                end
            end
            if frame.nextIndex > #frame.queue then
                self.AuraGlowBuildPending = false
                frame:Hide()
                frame.queue = nil
                self:UpdateAuraGlowVisibility()
            end
        end)
    end
    auraGlowBuildFrame.queue = queue
    auraGlowBuildFrame.nextIndex = 1
    auraGlowBuildFrame.generation = generation
    auraGlowBuildFrame:Show()
end

function NSI:RefreshAuraGlows()
    self:InitAuraGlows()
end

function NSI:RefreshAuraGlowsUI()
    if self._RefreshAuraGlowsUI then
        self._RefreshAuraGlowsUI()
    end
end
