local _, NSI = ...

local AuraTrackingFilters = {
    "RAID",
    "RAID_IN_COMBAT",
    "RAID_PLAYER_DISPELLABLE",
}

local DebugShowAllAuraTrackingBuffs = false

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

local function AddAuraTrackingFilters(container, limit)
    container:ClearAuraFilters()
    if DebugShowAllAuraTrackingBuffs then
        container:AddAuraFilter("HELPFUL", { maxFrameCount = limit })
        return
    end
    for _, filter in ipairs(AuraTrackingFilters) do
        container:AddAuraFilter(filter, { maxFrameCount = limit })
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

function NSI:UseAuraTrackingContainers()
    if not self:IsMidnightS2() then return false end
    if self.AuraTrackingContainersAvailable ~= nil then return self.AuraTrackingContainersAvailable end
    if C_AddOns and C_AddOns.LoadAddOn and C_AddOns.IsAddOnLoaded then
        if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
            local loaded = C_AddOns.LoadAddOn("Blizzard_AuraContainer")
            if not loaded then
                self.AuraTrackingContainersAvailable = false
                return false
            end
        end
    elseif LoadAddOn and IsAddOnLoaded and not IsAddOnLoaded("Blizzard_AuraContainer") then
        local loaded = LoadAddOn("Blizzard_AuraContainer")
        if not loaded then
            self.AuraTrackingContainersAvailable = false
            return false
        end
    end

    local containerOk, container = pcall(CreateFrame, "AuraContainer", nil, self.NSRTFrame, "CustomAuraContainerTemplate")
    if not containerOk or not container then
        self.AuraTrackingContainersAvailable = false
        return false
    end

    local buttonOk, button = pcall(CreateFrame, "AuraButton", nil, container, "CustomAuraButtonTemplate")
    if not buttonOk or not button then
        self.AuraTrackingContainersAvailable = false
        return false
    end

    self.AuraTrackingContainerProbe = container
    self.AuraTrackingButtonProbe = button
    self.AuraTrackingContainersAvailable = true
    return self.AuraTrackingContainersAvailable
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
            state.container:ClearAuraFilters()
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
        state.buttons = {}
        state.buttonRegions = {}
    end
    return state
end

function NSI:AcquireAuraTrackingButton(state, index, width, height, settings)
    state.buttons = state.buttons or {}
    state.buttonRegions = state.buttonRegions or {}
    local fontPath = self:GetAuraTrackingFontPath(settings)

    if not state.buttons[index] or not state.buttonRegions[index] then
        local button = CreateFrame("AuraButton", nil, state.container, "CustomAuraButtonTemplate")
        local regions = {}

        regions.icon = button:CreateTexture(nil, "ARTWORK")
        regions.icon:SetAllPoints(button)
        button:SetIcon(regions.icon)

        regions.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        regions.cooldown:SetAllPoints(regions.icon)
        regions.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
        regions.cooldown:SetReverse(true)
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

        state.buttons[index] = button
        state.buttonRegions[index] = regions
    end

    local button = state.buttons[index]
    local regions = state.buttonRegions[index]
    button:SetSize(width, height)
    local zoom = ((settings.Zoom or 0) * 0.5) / 100
    regions.icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    UpdateAuraTrackingBorder(regions.border, button, settings.HideBorder, settings.BorderSize)

    regions.count:ClearAllPoints()
    regions.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", settings.StackXOffset, settings.StackYOffset)
    regions.count:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
    regions.count:SetTextColor(unpack(settings.StackColor))
    button:SetApplicationCount(regions.count, {})

    regions.duration:ClearAllPoints()
    regions.duration:SetPoint("CENTER", button, "CENTER", settings.DurationXOffset, settings.DurationYOffset)
    regions.duration:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)
    regions.duration:SetTextColor(unpack(settings.DurationColor))

    button:SetMouseMotionEnabled(not settings.HideTooltip)
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

    local state = self:AcquireAuraTrackingContainer(key)
    local container = state.container
    local width = settings.Width
    local height = settings.Height
    local xDirection = (settings.GrowDirection == "RIGHT" and 1) or (settings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (settings.GrowDirection == "DOWN" and -1) or (settings.GrowDirection == "UP" and 1) or 0

    container:SetEnabled(false)
    container:RemoveAllAuraFrames()
    container:ClearAllPoints()
    container:SetSize(width, height)
    container:SetPoint(settings.Anchor, self.NSRTFrame, settings.relativeTo, settings.xOffset, settings.yOffset)
    container:SetUnit(unit)

    AddAuraTrackingFilters(container, settings.Limit)
    for i = 1, settings.Limit do
        local button = self:AcquireAuraTrackingButton(state, i, width, height, settings)
        button:ClearAllPoints()
        local xOffset = (i - 1) * (settings.Width + settings.Spacing) * xDirection
        local yOffset = (i - 1) * (settings.Height + settings.Spacing) * yDirection
        button:SetPoint("CENTER", button:GetParent(), "CENTER", xOffset, yOffset)
        container:AddAuraFrame(button)
    end

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
    local timerKey = key == "Player" and "AuraTrackingPlayerPreviewTimer" or "AuraTrackingTankPreviewTimer"
    if self[timerKey] then
        self[timerKey]:Cancel()
        self[timerKey] = nil
    end
end

function NSI:StartAuraTrackingPreviewTimer(key)
    self:StopAuraTrackingPreviewTimer(key)
    local timerKey = key == "Player" and "AuraTrackingPlayerPreviewTimer" or "AuraTrackingTankPreviewTimer"
    local startedAt = GetTime()
    self[timerKey] = C_Timer.NewTicker(0.05, function()
        local elapsed = GetTime() - startedAt
        if elapsed >= AURA_TRACKING_PREVIEW_DURATION then
            self:PreviewAuraTracking(key, true)
            return
        end

        local iconKey = key == "Player" and "AuraTrackingPlayerPreviewIcons" or "AuraTrackingTankPreviewIcons"
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
    return frame
end

function NSI:UpdateAuraTrackingPreviewFrame(frame, settings, texture, index)
    local fontPath = self:GetAuraTrackingFontPath(settings)
    frame:SetSize(settings.Width, settings.Height)
    frame.Icon:SetTexture(texture)
    local zoom = ((settings.Zoom or 0) * 0.5) / 100
    frame.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    UpdateAuraTrackingBorder(frame.Border, frame, settings.HideBorder, settings.BorderSize)

    frame.Cooldown:SetCooldown(GetTime(), AURA_TRACKING_PREVIEW_DURATION)
    frame.Cooldown:SetReverse(true)
    frame.Cooldown:SetDrawEdge(false)
    frame.Cooldown:SetHideCountdownNumbers(true)

    frame.Stack:ClearAllPoints()
    frame.Stack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", settings.StackXOffset, settings.StackYOffset)
    frame.Stack:SetFont(fontPath, settings.StackFontSize, settings.TextFontFlags)
    frame.Stack:SetTextColor(unpack(settings.StackColor))
    frame.Stack:SetText(index)

    frame.Duration:ClearAllPoints()
    frame.Duration:SetPoint("CENTER", frame, "CENTER", settings.DurationXOffset, settings.DurationYOffset)
    frame.Duration:SetFont(fontPath, settings.DurationFontSize, settings.TextFontFlags)
    frame.Duration:SetTextColor(unpack(settings.DurationColor))
    frame.Duration:SetText(AURA_TRACKING_PREVIEW_DURATION)
    frame.Duration:SetShown(not settings.HideDurationText)
end

function NSI:PreviewAuraTracking(key, show)
    if self.IsBuilding then return end
    local settings = NSRT.AuraTrackingSettings[key]
    local frameKey = key == "Player" and "AuraTrackingPlayerPreviewMover" or "AuraTrackingTankPreviewMover"
    local iconKey = key == "Player" and "AuraTrackingPlayerPreviewIcons" or "AuraTrackingTankPreviewIcons"
    local texture = key == "Player" and 237555 or 236318

    if not self[frameKey] then
        self[frameKey] = CreateFrame("Frame", nil, self.NSRTFrame)
        self[frameKey]:SetFrameStrata("HIGH")
    end

    local mover = self[frameKey]
    if not show then
        self:StopAuraTrackingPreviewTimer(key)
        self:MakeDraggable(mover, settings, false)
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
    mover:ClearAllPoints()
    mover:SetPoint(settings.Anchor, self.NSRTFrame, settings.relativeTo, settings.xOffset, settings.yOffset)
    mover:Show()

    self:MakeDraggable(mover, settings, true)
    mover:SetScript("OnDragStop", function(frame)
        self:StopFrameMove(frame, settings)
        self.PendingAuraTrackingUpdate = true
    end)

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
            self:UpdateAuraTrackingPreviewFrame(icon, settings, texture, i)
            icon:Show()
        else
            icon:Hide()
        end
    end
    self:StartAuraTrackingPreviewTimer(key)
end

function NSI:UpdateAuraTrackingDisplay(key)
    if self.IsBuilding then return end
    if key == "Player" and self.IsAuraTrackingPlayerPreview then
        self:PreviewAuraTracking("Player", true)
    elseif key == "Tank" and self.IsAuraTrackingTankPreview then
        self:PreviewAuraTracking("Tank", true)
    else
        self:InitAuraTracking()
    end
end
