local _, NSI = ...

local AuraTrackingFilters = {
    "HARMFUL|!PLAYER",
}

NSI.DefaultExternalAuraTrackingSpellIDs = {
    6940, -- Blessing of Sacrifice
    1022, -- Blessing of Protection
    204018, -- Blessing of Spellwarding
    47788, -- Guardian Spirit 1
    255312, -- Guardian Spirit 2
    102342, -- Ironbark
    116849, -- Life Cocoon
    357170, -- Time Dilation
    642, -- Divine Shield
    186265, -- Turtle
    196555, -- Netherwalk
    31224, -- Cloak of Shadows
    45438, -- Ice Block
}

function NSI:CreateAuraTrackingSettingsDefaults(overrides)
    local settings = {
        Spacing = -1,
        Limit = 5,
        GrowDirection = "RIGHT",
        enabled = false,
        Width = 100,
        Height = 100,
        Zoom = 0,
        Anchor = "CENTER",
        relativeTo = "CENTER",
        CustomAnchorFrame = "",
        xOffset = -450,
        yOffset = -100,
        HideBorder = false,
        BorderSize = 1,
        HideTooltip = false,
        HideDurationText = false,
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
        NamePosition = "TOP",
        NameXOffset = 0,
        NameYOffset = 4,
        NameFontSize = 30,
        SpellIDs = {},
        SpellIDsEdited = false,
        PreviewSpellID = nil,
    }
    for key, value in pairs(overrides or {}) do
        settings[key] = value
    end
    return settings
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
                threshold = 0,
                step = 1,
                rounding = Enum.NumericRuleFormatRounding.Up,
                format = "%d",
            },
        })
    end
    return AuraTrackingDurationFormatter
end

local function AuraTrackingUpdateLocked()
    return UnitAffectingCombat("player") or InCombatLockdown()
end

local function GetAuraTrackingFilters()
    return AuraTrackingFilters
end

local function GetAuraTrackingSettingsKeyFromRuntimeKey(key)
    if key == "external" then return "External" end
    local customIndex = tostring(key or ""):match("^custom(%d+)$")
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
    return ParseAuraTrackingSpellIDs(NSI.DefaultExternalAuraTrackingSpellIDs)
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

function NSI:GetAuraTrackingSpellIDString(settingsKey)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    return table.concat(GetAuraTrackingSpellIDs(settings, settingsKey), ", ")
end

function NSI:SetAuraTrackingSpellIDString(settingsKey, value)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    settings.SpellIDs = ParseAuraTrackingSpellIDs(value)
    settings.SpellIDsEdited = true
    self:UpdateAuraTrackingDisplay(settingsKey)
end

function NSI:SetAuraTrackingPreviewSpellID(settingsKey, value)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    settings.PreviewSpellID = tonumber(value) or nil
    self:UpdateAuraTrackingDisplay(settingsKey)
    if self.RebuildAuraTrackingOptionsMenu then
        C_Timer.After(0, function()
            self:RebuildAuraTrackingOptionsMenu()
        end)
    end
end

function NSI:SetAuraTrackingCustomName(settingsKey, value)
    local settings = self:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    value = strtrim(tostring(value or ""))
    settings.Name = value ~= "" and value or nil
    if self.RebuildAuraTrackingOptionsMenu then
        C_Timer.After(0, function()
            self:RebuildAuraTrackingOptionsMenu()
        end)
    end
end

local AuraTrackingStyleKeys = {
    "Spacing",
    "Limit",
    "GrowDirection",
    "CustomAnchorFrame",
    "xOffset",
    "yOffset",
    "Width",
    "Height",
    "Zoom",
    "HideBorder",
    "BorderSize",
    "HideTooltip",
    "HideDurationText",
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

function NSI:AddCustomAuraTracking()
    NSRT.AuraTrackingSettings.Custom = NSRT.AuraTrackingSettings.Custom or {}
    local index = #NSRT.AuraTrackingSettings.Custom + 1
    NSRT.AuraTrackingSettings.Custom[index] = self:CreateAuraTrackingSettingsDefaults({
        Name = "Custom Aura Tracking " .. index,
        xOffset = 0,
        yOffset = 0,
        HideStackText = true,
        HideTooltip = true,
        SpellIDsEdited = true,
    })
    NSRT.AuraTrackingSelected = "Custom:" .. index
    if self.RebuildAuraTrackingOptionsMenu then
        C_Timer.After(0, function()
            self:RebuildAuraTrackingOptionsMenu()
        end)
    end
end

function NSI:StopAllAuraTrackingPreviews()
    for _, key in ipairs({"Player", "Tank", "External"}) do
        local previewData = GetAuraTrackingPreviewData(key)
        self["IsAuraTracking" .. key .. "Preview"] = false
        self:StopAuraTrackingPreviewTimer(key)
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
        self:StopAuraTrackingPreviewTimer(key)
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
    if self.RebuildAuraTrackingOptionsMenu then
        C_Timer.After(0, function()
            self:RebuildAuraTrackingOptionsMenu()
        end)
    end
end

local function CreateAuraTrackingBorder(parent)
    local border = {
        top = parent:CreateTexture(nil, "OVERLAY"),
        bottom = parent:CreateTexture(nil, "OVERLAY"),
        left = parent:CreateTexture(nil, "OVERLAY"),
        right = parent:CreateTexture(nil, "OVERLAY"),
    }
    for _, texture in pairs(border) do
        texture:SetColorTexture(0, 0, 0, 1)
    end
    return border
end

local function UpdateAuraTrackingBorder(border, parent, hidden, size)
    if not border then return end
    size = size or 1
    for _, texture in pairs(border) do
        texture:ClearAllPoints()
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

local function GetAuraTrackingUnitName(unit)
    if not unit then return "" end
    return NSAPI:Shorten(unit, nil, false, "GlobalNickNames") or ""
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
    return fallback
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

function NSI:UseAuraTrackingContainers()
    if not self:IsMidnightS2() then return false end
    if self.AuraTrackingContainersAvailable ~= nil then return self.AuraTrackingContainersAvailable end

    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        C_AddOns.LoadAddOn("Blizzard_AuraContainer")
    end

    local container = CreateFrame("AuraContainer", nil, self.NSRTFrame, "CustomAuraContainerTemplate")
    self.AuraTrackingContainerProbe = container
    self.AuraTrackingContainersAvailable = true
    return self.AuraTrackingContainersAvailable
end

function NSI:SaveAuraTrackingFramePosition(frame, settings)
    if not frame or not settings then return end
    local relativeFrame = GetAuraTrackingAnchorFrame(settings, self.NSRTFrame)
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

function NSI:MakeAuraTrackingDraggable(frame, settings, enable)
    if not frame then return end
    if not enable then
        self:MakeDraggable(frame, settings, false)
        return
    end

    self:MakeDraggable(frame, nil, true)
    frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
        f._nsrtAuraTrackingDragElapsed = 0
        f:SetScript("OnUpdate", function(updateFrame, elapsed)
            updateFrame._nsrtAuraTrackingDragElapsed = (updateFrame._nsrtAuraTrackingDragElapsed or 0) + elapsed
            if updateFrame._nsrtAuraTrackingDragElapsed < 0.05 then return end
            updateFrame._nsrtAuraTrackingDragElapsed = 0
            self:SaveAuraTrackingFramePosition(updateFrame, settings)
        end)
    end)
    frame:SetScript("OnDragStop", function(f)
        f:SetScript("OnUpdate", nil)
        f._nsrtAuraTrackingDragElapsed = nil
        f:StopMovingOrSizing()
        self:SaveAuraTrackingFramePosition(f, settings)
        self.PendingAuraTrackingUpdate = true
    end)
end

function NSI:GetAuraTrackingFontPath(settings)
    local fontName = settings.TextFont or "Expressway"
    if self.LSM then
        return self.LSM:Fetch("font", fontName, true) or [[Interface\Addons\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]
    end
    return [[Interface\Addons\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]
end

function NSI:ClearAuraTracking()
    if not self.AuraTrackingState then return end
    for _, state in pairs(self.AuraTrackingState) do
        if state.container then
            state.container:SetEnabled(false)
            state.container:Hide()
            state.container:ClearAuraGroups()
        end
    end
end

function NSI:AcquireAuraTrackingContainer(key)
    if not self.AuraTrackingState then self.AuraTrackingState = {} end
    if not self.AuraTrackingState[key] then self.AuraTrackingState[key] = {} end

    local state = self.AuraTrackingState[key]
    if not state.container then
        state.container = CreateFrame("AuraContainer", nil, self.NSRTFrame, "CustomAuraContainerTemplate")
        state.container:SetFrameStrata("HIGH")
        state.buttonRegions = {}
    end
    return state
end

function NSI:ConfigureAuraTrackingButton(state, button, width, height, settings, unit, key)
    state.buttonRegions = state.buttonRegions or {}
    local fontPath = self:GetAuraTrackingFontPath(settings)

    if not state.buttonRegions[button] then
        local regions = {}

        regions.icon = button:CreateTexture(nil, "ARTWORK")
        regions.icon:SetAllPoints(button)
        button:SetIcon(regions.icon)

        regions.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        regions.cooldown:SetAllPoints(regions.icon)
        regions.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        regions.cooldown:SetReverse(settings.InverseCooldownSwipe)
        regions.cooldown:SetDrawEdge(false)
        regions.cooldown:SetHideCountdownNumbers(true)
        button:SetDurationCooldown(regions.cooldown)

        regions.border = CreateAuraTrackingBorder(button)

        regions.textOverlay = CreateFrame("Frame", nil, button)
        regions.textOverlay:SetAllPoints(button)
        regions.textOverlay:SetFrameLevel(button:GetFrameLevel() + 2)

        regions.count = regions.textOverlay:CreateFontString(nil, "OVERLAY")
        regions.count:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
        button:SetApplicationCount(regions.count, {})

        regions.duration = regions.textOverlay:CreateFontString(nil, "OVERLAY")
        regions.duration:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)

        regions.unitName = regions.textOverlay:CreateFontString(nil, "OVERLAY")
        regions.unitName:SetFont(fontPath, settings.NameFontSize or settings.StackFontSize, settings.TextFontFlags)

        state.buttonRegions[button] = regions
    end

    local regions = state.buttonRegions[button]
    button:SetSize(width, height)
    local zoom = ((settings.Zoom or 0) * 0.5) / 100
    regions.icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    UpdateAuraTrackingBorder(regions.border, button, settings.HideBorder, settings.BorderSize)

    regions.count:ClearAllPoints()
    regions.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", settings.StackXOffset, settings.StackYOffset)
    regions.count:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
    regions.count:SetTextColor(unpack(settings.StackColor))
    button:SetApplicationCount(regions.count, {})
    regions.count:SetAlpha(settings.HideStackText and 0 or 1)
    regions.count:SetShown(not settings.HideStackText)

    regions.duration:ClearAllPoints()
    regions.duration:SetPoint("CENTER", button, "CENTER", settings.DurationXOffset, settings.DurationYOffset)
    regions.duration:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)
    regions.duration:SetTextColor(unpack(settings.DurationColor))

    PositionAuraTrackingUnitName(regions.unitName, button, settings)
    regions.unitName:SetFont(fontPath, settings.NameFontSize or settings.StackFontSize, settings.TextFontFlags)
    regions.unitName:SetText(GetAuraTrackingUnitName(unit))
    regions.unitName:SetShown(key == "tank" and settings.NameEnabled)

    button:SetMouseMotionEnabled(not settings.HideTooltip)
    regions.cooldown:SetReverse(settings.InverseCooldownSwipe)
    regions.cooldown:SetShown(settings.EnableCooldownSwipe)
    if settings.HideDurationText then
        button:ClearDurationText()
    else
        button:SetDurationText(regions.duration, { formatter = GetAuraTrackingDurationFormatter() })
    end

    return button
end

function NSI:InitAuraTrackingContainer(unit, settings, key)
    if not self:UseAuraTrackingContainers() then return end
    if not unit or not settings.enabled then return end
    local isExternal = key == "external" or tostring(key):match("^custom")
    local spellIDMap = isExternal and GetAuraTrackingSpellIDMap(settings, GetAuraTrackingSettingsKeyFromRuntimeKey(key)) or nil
    if isExternal and not spellIDMap then return end

    local state = self:AcquireAuraTrackingContainer(key)
    local container = state.container
    local width = settings.Width
    local height = settings.Height
    local xDirection = (settings.GrowDirection == "RIGHT" and 1) or (settings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (settings.GrowDirection == "DOWN" and -1) or (settings.GrowDirection == "UP" and 1) or 0
    local groupKeyPrefix = "NSRT_" .. key

    container:SetEnabled(false)
    container:Hide()
    container:ClearAuraGroups()
    container:SetSize(width, height)
    SetAuraTrackingPoint(container, settings, self.NSRTFrame)
    container:SetUnit(unit)

    local filters = isExternal and {"HELPFUL|!PLAYER"} or GetAuraTrackingFilters()
    for index, filter in ipairs(filters) do
        local groupKey = groupKeyPrefix .. index
        local candidateFilters = {
            isFromPlayerOrPlayerPet = false,
        }
        if spellIDMap then
            candidateFilters.spellIDs = spellIDMap
        end
        local options = {
            maxFrameCount = settings.Limit,
            initializeFrame = function(button)
                self:ConfigureAuraTrackingButton(state, button, width, height, settings, unit, key)
            end,
            candidateFilters = candidateFilters,
        }

        container:AddAuraGroup(groupKey, filter, options)
        container:SetAuraGroupLayout(groupKey, {
            point = "CENTER",
            relativePoint = "CENTER",
            offsetX = 0,
            offsetY = 0,
            xOffset = (settings.Width + settings.Spacing) * xDirection,
            yOffset = (settings.Height + settings.Spacing) * yDirection,
            wrapAfter = settings.Limit,
        })
    end

    container:Show()
    container:SetEnabled(true)
end

function NSI:InitAuraTracking()
    if self.IsBuilding or not self:IsMidnightS2() then return end
    if AuraTrackingUpdateLocked() then
        self.PendingAuraTrackingUpdate = true
        return
    end

    self:ClearAuraTracking()
    self:InitAuraTrackingContainer("player", NSRT.AuraTrackingSettings.Player, "player")
    self:InitAuraTrackingContainer("player", NSRT.AuraTrackingSettings.External, "external")
    for index, settings in ipairs(NSRT.AuraTrackingSettings.Custom or {}) do
        self:InitAuraTrackingContainer("player", settings, "custom" .. index)
    end
    if self:DifficultyCheck({14, 15, 16}) and UnitGroupRolesAssigned("player") == "TANK" then
        local tankUnit
        for unit in self:IterateGroupMembers() do
            if UnitGroupRolesAssigned(unit) == "TANK" and not UnitIsUnit("player", unit) then
                tankUnit = unit
                break
            end
        end
        self:InitAuraTrackingContainer(tankUnit, NSRT.AuraTrackingSettings.Tank, "tank")
    end
end

function NSI:ApplyPendingAuraTracking()
    if not self.PendingAuraTrackingUpdate or AuraTrackingUpdateLocked() then return end
    self.PendingAuraTrackingUpdate = nil
    self:InitAuraTracking()
end

function NSI:InitAuraSystem(firstcall)
    if self:IsMidnightS2() then
        self:InitAuraTracking()
    else
        self:InitPrivateAuras(firstcall)
    end
end

local AURA_TRACKING_PREVIEW_DURATION = 10

function NSI:StopAuraTrackingPreviewTimer(key)
    local previewData = GetAuraTrackingPreviewData(key)
    if not previewData then return end
    local timerKey = previewData.timerKey
    if self[timerKey] then
        self[timerKey]:Cancel()
        self[timerKey] = nil
    end
end

function NSI:StartAuraTrackingPreviewTimer(key)
    self:StopAuraTrackingPreviewTimer(key)
    local previewData = GetAuraTrackingPreviewData(key)
    if not previewData then return end
    local timerKey = previewData.timerKey
    local startedAt = GetTime()
    self[timerKey] = C_Timer.NewTicker(0.05, function()
        local elapsed = GetTime() - startedAt
        if elapsed >= AURA_TRACKING_PREVIEW_DURATION then
            self:PreviewAuraTracking(key, true)
            return
        end

        local iconKey = previewData.iconKey
        if not self[iconKey] then return end
        local remaining = math.ceil(AURA_TRACKING_PREVIEW_DURATION - elapsed)
        for _, frame in ipairs(self[iconKey]) do
            if frame:IsShown() and frame.Duration then
                frame.Duration:SetText(remaining)
            end
        end
    end)
end

function NSI:CreateAuraTrackingPreviewFrame(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetFrameStrata("HIGH")
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetAllPoints(frame)

    frame.Cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.Cooldown:SetAllPoints(frame.Icon)
    frame.Cooldown:SetReverse(true)
    frame.Cooldown:SetDrawEdge(false)
    frame.Cooldown:SetHideCountdownNumbers(true)
    frame.Cooldown:SetFrameLevel(frame:GetFrameLevel() + 1)

    frame.Border = CreateAuraTrackingBorder(frame)

    frame.TextOverlay = CreateFrame("Frame", nil, frame)
    frame.TextOverlay:SetAllPoints(frame)
    frame.TextOverlay:SetFrameLevel(frame:GetFrameLevel() + 2)

    frame.Stack = frame.TextOverlay:CreateFontString(nil, "OVERLAY")
    frame.Duration = frame.TextOverlay:CreateFontString(nil, "OVERLAY")
    frame.UnitName = frame.TextOverlay:CreateFontString(nil, "OVERLAY")
    return frame
end

function NSI:UpdateAuraTrackingPreviewFrame(frame, settings, texture, index, key)
    local fontPath = self:GetAuraTrackingFontPath(settings)
    frame:SetSize(settings.Width, settings.Height)
    frame.Icon:SetTexture(texture)
    local zoom = ((settings.Zoom or 0) * 0.5) / 100
    frame.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    UpdateAuraTrackingBorder(frame.Border, frame, settings.HideBorder, settings.BorderSize)

    frame.Cooldown:SetCooldown(GetTime(), AURA_TRACKING_PREVIEW_DURATION)
    frame.Cooldown:SetReverse(settings.InverseCooldownSwipe)
    frame.Cooldown:SetDrawEdge(false)
    frame.Cooldown:SetHideCountdownNumbers(true)
    frame.Cooldown:SetShown(settings.EnableCooldownSwipe)

    frame.Stack:ClearAllPoints()
    frame.Stack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", settings.StackXOffset, settings.StackYOffset)
    frame.Stack:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
    frame.Stack:SetTextColor(unpack(settings.StackColor))
    frame.Stack:SetText(index)
    frame.Stack:SetShown(not settings.HideStackText)

    frame.Duration:ClearAllPoints()
    frame.Duration:SetPoint("CENTER", frame, "CENTER", settings.DurationXOffset, settings.DurationYOffset)
    frame.Duration:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)
    frame.Duration:SetTextColor(unpack(settings.DurationColor))
    frame.Duration:SetText(AURA_TRACKING_PREVIEW_DURATION)
    frame.Duration:SetShown(not settings.HideDurationText)

    PositionAuraTrackingUnitName(frame.UnitName, frame, settings)
    frame.UnitName:SetFont(fontPath, settings.NameFontSize or settings.StackFontSize, settings.TextFontFlags)
    local previewData = GetAuraTrackingPreviewData(key)
    frame.UnitName:SetText(GetAuraTrackingUnitName(previewData and previewData.unit or "player"))
    frame.UnitName:SetShown(key == "Tank" and settings.NameEnabled)
end

function NSI:PreviewAuraTracking(key, show)
    if self.IsBuilding then return end
    local settings = self:GetAuraTrackingSettings(key)
    local previewData = GetAuraTrackingPreviewData(key)
    if not settings or not previewData then return end
    local frameKey = previewData.frameKey
    local iconKey = previewData.iconKey
    local texture = previewData.texture
    if settings.PreviewSpellID then
        texture = C_Spell.GetSpellTexture(settings.PreviewSpellID) or texture
    end

    if not self[frameKey] then
        self[frameKey] = CreateFrame("Frame", nil, self.NSRTFrame)
        self[frameKey]:SetFrameStrata("HIGH")
    end

    local mover = self[frameKey]
    if not show then
        self:StopAuraTrackingPreviewTimer(key)
        self:MakeAuraTrackingDraggable(mover, settings, false)
        mover:Hide()
        if self[iconKey] then
            for _, icon in ipairs(self[iconKey]) do
                icon:Hide()
            end
        end
        self:InitAuraTracking()
        return
    end

    self:ClearAuraTracking()
    mover:SetSize(settings.Width, settings.Height)
    mover:SetScale(1)
    SetAuraTrackingPoint(mover, settings, self.NSRTFrame)
    mover:Show()

    self:MakeAuraTrackingDraggable(mover, settings, true)

    if not self[iconKey] then self[iconKey] = {} end
    local xDirection = (settings.GrowDirection == "RIGHT" and 1) or (settings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (settings.GrowDirection == "DOWN" and -1) or (settings.GrowDirection == "UP" and 1) or 0
    for i = 1, 10 do
        if not self[iconKey][i] then
            self[iconKey][i] = self:CreateAuraTrackingPreviewFrame(mover)
        end
        local icon = self[iconKey][i]
        if settings.Limit >= i then
            local xOffset = (i - 1) * (settings.Width + settings.Spacing) * xDirection
            local yOffset = (i - 1) * (settings.Height + settings.Spacing) * yDirection
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", mover, "CENTER", xOffset, yOffset)
            self:UpdateAuraTrackingPreviewFrame(icon, settings, texture, i, key)
            icon:Show()
        else
            icon:Hide()
        end
    end
    self:StartAuraTrackingPreviewTimer(key)
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
