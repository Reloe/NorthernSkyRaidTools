local _, NSI = ...
NSI.AuraGlowBuiltins = NSI.AuraGlowBuiltins or {}
NSI.AuraGlowBuiltinGroup = "Built-in"

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
        AuraType = "Debuffs",
        BuffFiltering = "SpellIDs",
        SpellIDs = {},
        AuraFilters = {},
        CandidateFilters = {},
        loadConditions = { Roles = {}, Classes = {}, SpecIDs = {}, Names = {}, EncounterIDs = {} },
    }
    for key, value in pairs(overrides or {}) do
        settings[key] = value
    end
    return settings
end

function NSI:RegisterBuiltinAuraGlow(key, definition)
    assert(type(key) == "string" and key ~= "", "built-in aura glow key must be a non-empty string")
    assert(type(definition) == "table", "built-in aura glow requires a definition")
    self.AuraGlowBuiltins[key] = definition
end

local function CreateBuiltinAuraGlowSettings(self, key)
    local definition = self.AuraGlowBuiltins[key]
    local encounterIDs = {}
    if definition.encounterID then encounterIDs[definition.encounterID] = true end
    return self:CreateAuraGlowSettingsDefaults({
        Name = definition.name or key,
        enabled = NSRT.AuraGlows.UseBuiltinAuraGlows == true or definition.enabled == true,
        builtin = true,
        Color = definition.color and CopyTable(definition.color) or nil,
        AuraFilters = CopyTable(definition.auraFilters or {}),
        CandidateFilters = CopyTable(definition.candidateFilters or {}),
        loadConditions = { Roles = CopyTable(definition.roles or {}), Classes = {}, SpecIDs = {}, Names = {}, EncounterIDs = encounterIDs },
    })
end

function NSI:GetAuraGlowSettings(key)
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    if self.AuraGlowBuiltins[key] then
        NSRT.AuraGlows.Builtins = NSRT.AuraGlows.Builtins or {}
        local settings = NSRT.AuraGlows.Builtins[key]
        if not settings then
            settings = CreateBuiltinAuraGlowSettings(self, key)
            NSRT.AuraGlows.Builtins[key] = settings
        end
        return settings
    end
    local index = tonumber(tostring(key):match("^Custom:(%d+)$"))
    return index and NSRT.AuraGlows.Custom and NSRT.AuraGlows.Custom[index]
end

function NSI:ResetBuiltinAuraGlow(key)
    assert(self.AuraGlowBuiltins[key], "unknown built-in aura glow: " .. tostring(key))
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    NSRT.AuraGlows.Builtins = NSRT.AuraGlows.Builtins or {}
    NSRT.AuraGlows.Builtins[key] = CreateBuiltinAuraGlowSettings(self, key)
    self:RebuildAuraGlows()
    self:RefreshAuraGlowPreview(key)
end

function NSI:SetUseBuiltinAuraGlows(enabled)
    NSRT.AuraGlows.UseBuiltinAuraGlows = enabled == true
    for key, definition in pairs(self.AuraGlowBuiltins) do
        local settings = self:GetAuraGlowSettings(key)
        if not settings.enabledEdited then
            settings.enabled = enabled == true or definition.enabled == true
        end
    end
    self:RebuildAuraGlows()
    self:RefreshAuraGlowsUI()
end

function NSI:IterateAuraGlowEntries()
    local entries = {}
    for key in pairs(self.AuraGlowBuiltins) do
        entries[#entries + 1] = { key = key, settings = self:GetAuraGlowSettings(key), builtin = true, group = self.AuraGlowBuiltinGroup }
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
    NSRT.AuraGlows.Custom[index] = self:CreateAuraGlowSettingsDefaults({ Name = "Custom Aura Glow " .. index, group = group ~= "" and group or nil })
    self:InitAuraGlows()
    return "Custom:" .. index
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
    self:RebuildAuraGlows()
    return "Custom:" .. #NSRT.AuraGlows.Custom
end

function NSI:DeleteCustomAuraGlow(key)
    local index = tonumber(tostring(key):match("^Custom:(%d+)$"))
    if not index or not NSRT.AuraGlows.Custom[index] then return end
    self:HideAuraGlowPreview(false)
    table.remove(NSRT.AuraGlows.Custom, index)
    self:InitAuraGlows()
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
    self:RebuildAuraGlows()
    self:RefreshAuraGlowPreview(key)
end

function NSI:RemoveAuraGlowSpellID(key, spellID)
    local settings = self:GetAuraGlowSettings(key)
    if not settings or settings.builtin or not settings.SpellIDs then return end
    spellID = tonumber(spellID)
    for index, value in ipairs(settings.SpellIDs) do
        if tonumber(value) == spellID then
            table.remove(settings.SpellIDs, index)
            self:RebuildAuraGlows()
            self:RefreshAuraGlowPreview(key)
            return
        end
    end
end

function NSI:ExportAuraGlowEntry(key)
    local settings = self:GetAuraGlowSettings(key)
    if not settings then return "" end
    return self:EncodeExportData({ type = "NSRT_AURA_GLOW", version = 1, entries = { CopyTable(settings) } }, "AuraGlow") or ""
end

function NSI:ExportAuraGlowGroup(group)
    local entries = {}
    for _, entry in ipairs(self:IterateAuraGlowEntries()) do
        if not entry.builtin and entry.group == group then entries[#entries + 1] = CopyTable(entry.settings) end
    end
    return #entries > 0 and (self:EncodeExportData({ type = "NSRT_AURA_GLOW", version = 1, group = group, entries = entries }, "AuraGlow") or "") or ""
end

function NSI:ImportAuraGlowString(text)
    local payload = self:DecodeExportData(text, "AuraGlow")
    if not payload or payload.type ~= "NSRT_AURA_GLOW" or type(payload.entries) ~= "table" then return false end
    NSRT.AuraGlows = NSRT.AuraGlows or { Custom = {}, Builtins = {}, UI = {} }
    NSRT.AuraGlows.Custom = NSRT.AuraGlows.Custom or {}
    local group = payload.group and strtrim(tostring(payload.group)) or nil
    local imported = 0
    for _, entry in ipairs(payload.entries) do
        if type(entry) == "table" then
            local settings = self:CreateAuraGlowSettingsDefaults(CopyTable(entry))
            settings.builtin = nil
            settings.group = group or settings.group
            settings.Name = settings.Name or "Imported Aura Glow"
            NSRT.AuraGlows.Custom[#NSRT.AuraGlows.Custom + 1] = settings
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
    self.AuraGlowManualState[key] = active == nil and nil or active == true
    self:UpdateAuraGlowVisibility()
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
    icon:SetPoint("CENTER", button, "CENTER")
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
        lineLength = math.floor((width + height) * (2 / numberOfLines - 0.1))
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
    if not targetFrame then return false end
    local spellIDs = UsesAuraGlowSpellIDs(settings) and GetAuraGlowSpellIDs(settings) or {}
    local spellID = spellIDs[1] or 1286895
    local previewFrame = CreateFrame("Frame", nil, UIParent)
    previewFrame:SetAllPoints(targetFrame)
    previewFrame:SetFrameStrata("HIGH")
    previewFrame:Show()
    CreateAuraGlowIcon(previewFrame, settings, C_Spell.GetSpellTexture(spellID) or 134400)
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
    if not settings.enabled or not self:EvaluateLoad(settings) then return false end
    local manualState = self.AuraGlowManualState and self.AuraGlowManualState[key]
    return manualState == nil or manualState
end

function NSI:UpdateAuraGlowVisibility()
    for key, states in pairs(self.AuraGlowStates or {}) do
        local settings = self:GetAuraGlowSettings(key)
        local enabled = settings and IsAuraGlowActive(self, key, settings)
        for _, state in pairs(states) do
            state.container:SetEnabled(enabled)
            state.container:SetShown(enabled)
        end
    end
end

function NSI:RebuildAuraGlows()
    for _, states in pairs(self.AuraGlowStates or {}) do
        for _, state in pairs(states) do
            state.container:Hide()
        end
    end
    self.AuraGlowStates = {}
    self:InitAuraGlows()
end

function NSI:InitAuraGlows()
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
        if not usesSpellIDs or #GetAuraGlowSpellIDs(settings) > 0 then
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
                        container:SetFrameStrata("HIGH")
                        local slot = container:AddAuraSlot("Glow", BuildAuraGlowFilterString(settings), {
                            candidateFilters = BuildAuraGlowCandidateFilters(settings),
                            initializeFrame = function(button)
                                button:SetAllPoints(container)
                                button:SetMouseMotionEnabled(false)
                                local icon = CreateAuraGlowIcon(button, settings)
                                button:SetIcon(icon)
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
        for unit, state in pairs(states) do
            if not activeKeys[key] or not UnitExists(unit) then
                state.container:Hide()
            end
        end
    end
    self:UpdateAuraGlowVisibility()
end

function NSI:RefreshAuraGlows()
    self:RebuildAuraGlows()
end

function NSI:RefreshAuraGlowsUI()
    if self._RefreshAuraGlowsUI then
        self._RefreshAuraGlowsUI()
    end
end
