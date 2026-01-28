local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local window_width = Core.window_width
local window_height = Core.window_height
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template = Core.options_switch_template

local function BuildTimelineTabUI(parent)
    local header_width = 180
    local timeline_width = window_width - 40 - header_width
    local timeline_height = window_height - 250
    local top_offset = -100

    parent.timelineMode = "my"
    parent.showBossAbilities = true
    parent.bossDisplayMode = NSI.BossDisplayModes.IMPORTANT_HEALER

    local function BuildModeDropdownOptions()
        return {
            {
                label = "My Reminders",
                value = "my",
                onclick = function(_, _, value)
                    parent.timelineMode = value
                    parent.reminderLabel:Hide()
                    parent.reminderDropdown:Hide()
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
            {
                label = "All Reminders (Raid Leader)",
                value = "all",
                onclick = function(_, _, value)
                    parent.timelineMode = value
                    parent.reminderLabel:Show()
                    parent.reminderDropdown:Show()
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
        }
    end

    local modeLabel = DF:CreateLabel(parent, "View:", 11, "white")
    modeLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, top_offset)

    local modeDropdown = DF:CreateDropDown(parent, BuildModeDropdownOptions, "my", 200)
    modeDropdown:SetTemplate(options_dropdown_template)
    modeDropdown:SetPoint("LEFT", modeLabel, "RIGHT", 10, 0)
    parent.modeDropdown = modeDropdown

    local function BuildReminderDropdownOptions()
        local options = {}
        local sharedList = NSI:GetAllReminderNames(false)
        for _, data in ipairs(sharedList) do
            table.insert(options, {
                label = data.name,
                value = {name = data.name, personal = false},
                onclick = function(_, _, value)
                    parent.currentReminder = value
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            })
        end
        local personalList = NSI:GetAllReminderNames(true)
        if #personalList > 0 then
            table.insert(options, { label = "--- Personal ---", value = nil })
            for _, data in ipairs(personalList) do
                table.insert(options, {
                    label = data.name .. " (Personal)",
                    value = {name = data.name, personal = true},
                    onclick = function(_, _, value)
                        parent.currentReminder = value
                        NSI:RefreshEmbeddedTimeline(parent)
                    end
                })
            end
        end
        return options
    end

    local reminderLabel = DF:CreateLabel(parent, "Reminder Set:", 11, "white")
    reminderLabel:SetPoint("LEFT", modeDropdown, "RIGHT", 20, 0)
    parent.reminderLabel = reminderLabel
    reminderLabel:Hide()

    local reminderDropdown = DF:CreateDropDown(parent, BuildReminderDropdownOptions, nil, 300)
    reminderDropdown:SetTemplate(options_dropdown_template)
    reminderDropdown:SetPoint("LEFT", reminderLabel, "RIGHT", 10, 0)
    parent.reminderDropdown = reminderDropdown
    reminderDropdown:Hide()

    local bossAbilitiesToggle = DF:CreateSwitch(parent,
        function(self, _, value)
            parent.showBossAbilities = value
            if value then
                parent.bossDisplayLabel:Show()
                parent.bossDisplayDropdown:Show()
            else
                parent.bossDisplayLabel:Hide()
                parent.bossDisplayDropdown:Hide()
            end
            NSI:RefreshEmbeddedTimeline(parent)
        end,
        true, 20, 20, nil, nil, nil, "TimelineBossAbilitiesToggle", nil, nil, nil, nil, options_switch_template)
    bossAbilitiesToggle:SetAsCheckBox()
    bossAbilitiesToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, top_offset + 2)
    parent.bossAbilitiesToggle = bossAbilitiesToggle

    local bossAbilitiesLabel = DF:CreateLabel(parent, "Show Boss Abilities", 11, "white")
    bossAbilitiesLabel:SetPoint("RIGHT", bossAbilitiesToggle, "LEFT", -5, 0)

    local function BuildBossDisplayModeOptions()
        return {
            {
                label = "Important Healer",
                value = NSI.BossDisplayModes.IMPORTANT_HEALER,
                onclick = function(_, _, value)
                    parent.bossDisplayMode = value
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
            {
                label = "Important Tank",
                value = NSI.BossDisplayModes.IMPORTANT_TANK,
                onclick = function(_, _, value)
                    parent.bossDisplayMode = value
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
            {
                label = "Show All",
                value = NSI.BossDisplayModes.SHOW_ALL,
                onclick = function(_, _, value)
                    parent.bossDisplayMode = value
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
            {
                label = "Combined",
                value = NSI.BossDisplayModes.COMBINED,
                onclick = function(_, _, value)
                    parent.bossDisplayMode = value
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
            {
                label = "Combined Important",
                value = NSI.BossDisplayModes.COMBINED_IMPORTANT,
                onclick = function(_, _, value)
                    parent.bossDisplayMode = value
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
        }
    end

    local bossDisplayLabel = DF:CreateLabel(parent, "Boss Display:", 11, "white")
    bossDisplayLabel:SetPoint("RIGHT", bossAbilitiesLabel, "LEFT", -20, 0)
    parent.bossDisplayLabel = bossDisplayLabel

    local bossDisplayDropdown = DF:CreateDropDown(parent, BuildBossDisplayModeOptions, NSI.BossDisplayModes.IMPORTANT_HEALER, 150)
    bossDisplayDropdown:SetTemplate(options_dropdown_template)
    bossDisplayDropdown:SetPoint("RIGHT", bossDisplayLabel, "LEFT", -5, 0)
    parent.bossDisplayDropdown = bossDisplayDropdown

    local noDataLabel = DF:CreateLabel(parent, "No reminders to display. Load a reminder set first with /ns", 14, "gray")
    noDataLabel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    parent.noDataLabel = noDataLabel
    noDataLabel:Hide()

    local titleLabel = DF:CreateLabel(parent, "", 12, "white")
    titleLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, top_offset - 25)
    parent.titleLabel = titleLabel

    local timelineOptions = {
        width = timeline_width,
        height = timeline_height,
        header_width = header_width,
        header_detached = true,
        line_height = 22,
        line_padding = 1,
        pixels_per_second = 15,
        scale_min = 0.1,
        scale_max = 2.0,
        show_elapsed_timeline = true,
        elapsed_timeline_height = 20,
        can_resize = false,
        use_perpixel_buttons = false,
        backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
        backdrop_color = {0.1, 0.1, 0.1, 0.8},
        backdrop_color_highlight = {0.2, 0.2, 0.3, 0.9},
        backdrop_border_color = {0.1, 0.1, 0.1, 0.3},

        on_enter = function(line)
            line:SetBackdropColor(unpack(line.backdrop_color_highlight))
        end,
        on_leave = function(line)
            local idx = line.dataIndex or 0
            if idx % 2 == 1 then
                line:SetBackdropColor(0, 0, 0, 0)
            else
                line:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            end
        end,

        on_create_line = function(line)
            if line.lineHeader then
                line.lineHeader:EnableMouse(true)
                line.lineHeader:SetScript("OnEnter", function(self)
                    line:SetBackdropColor(unpack(line.backdrop_color_highlight))
                    if line.lineData and line.lineData.spellId then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetSpellByID(line.lineData.spellId)
                        GameTooltip:Show()
                    end
                end)
                line.lineHeader:SetScript("OnLeave", function(self)
                    local idx = line.dataIndex or 0
                    if idx % 2 == 1 then
                        line:SetBackdropColor(0, 0, 0, 0)
                    else
                        line:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                    end
                    GameTooltip:Hide()
                end)
            end
            if line.text then
                line.text:SetWordWrap(false)
                line.text:SetWidth(150)
            end
        end,

        block_on_enter = function(block)
            if block.info and block.info.time then
                GameTooltip:SetOwner(block, "ANCHOR_RIGHT")
                local minutes = math.floor(block.info.time / 60)
                local seconds = math.floor(block.info.time % 60)
                local timeStr = string.format("%d:%02d", minutes, seconds)

                local spellName = ""
                if block.info.spellId then
                    local spellInfo = C_Spell.GetSpellInfo(block.info.spellId)
                    if spellInfo then
                        spellName = spellInfo.name or ""
                    end
                end

                GameTooltip:AddLine(spellName ~= "" and spellName or "Reminder", 1, 1, 1)
                GameTooltip:AddLine("Time: " .. timeStr, 0.7, 0.7, 0.7)
                local duration = tonumber(block.info.duration) or 0
                if duration > 0 then
                    GameTooltip:AddLine("Duration: " .. duration .. "s", 0.7, 0.7, 0.7)
                end

                if block.blockData and block.blockData.payload then
                    local payload = block.blockData.payload
                    if payload.isBossAbility and payload.category then
                        local categoryColors = {
                            damage = "|cffe64c4c",
                            tank = "|cff4c80e6",
                            movement = "|cffe6b333",
                            soak = "|cff80e680",
                            intermission = "|cffb366e6",
                        }
                        local colorCode = categoryColors[payload.category] or "|cffb3b3b3"
                        GameTooltip:AddLine("Category: " .. colorCode .. payload.category .. "|r", 0.7, 0.7, 0.7)
                        if payload.important then
                            GameTooltip:AddLine("|cffff9900Use Healing CDs!|r", 1, 0.6, 0)
                        end
                    elseif payload.phase then
                        GameTooltip:AddLine("Phase: " .. payload.phase, 0.7, 0.7, 0.7)
                    end
                    if payload.text then
                        GameTooltip:AddLine("Text: " .. payload.text, 0.5, 0.8, 0.5)
                    end
                end
                GameTooltip:Show()
            end
        end,
        block_on_leave = function(block)
            GameTooltip:Hide()
        end,
    }

    local elapsedTimeOptions = {
        draw_line_color = {0.5, 0.5, 0.5, 1},
    }

    local timelineFrame = DF:CreateTimeLineFrame(parent, "$parentTimeLine", timelineOptions, elapsedTimeOptions)
    parent.timeline = timelineFrame

    local gridOverlay = CreateFrame("Frame", nil, timelineFrame.body)
    gridOverlay:SetAllPoints(timelineFrame.body)
    gridOverlay:SetFrameLevel(timelineFrame.body:GetFrameLevel() + 100)
    timelineFrame.gridOverlay = gridOverlay
    timelineFrame.gridLines = {}

    if timelineFrame.elapsedTimeFrame and timelineFrame.elapsedTimeFrame.options then
        timelineFrame.elapsedTimeFrame.options.draw_line = false
    end

    if timelineFrame.elapsedTimeFrame then
        local originalRefresh = timelineFrame.elapsedTimeFrame.Refresh
        timelineFrame.elapsedTimeFrame.Refresh = function(self, ...)
            originalRefresh(self, ...)
            if self.labels then
                for i, label in ipairs(self.labels) do
                    if label:IsShown() then
                        local gridLine = timelineFrame.gridLines[i]
                        if not gridLine then
                            gridLine = gridOverlay:CreateTexture(nil, "OVERLAY")
                            gridLine:SetColorTexture(0.5, 0.5, 0.5, 1)
                            gridLine:SetWidth(1)
                            timelineFrame.gridLines[i] = gridLine
                        end
                        gridLine:ClearAllPoints()
                        gridLine:SetPoint("TOP", label, "BOTTOM", 0, -2)
                        gridLine:SetPoint("BOTTOM", gridOverlay, "BOTTOM", 0, 0)
                        gridLine:Show()
                    else
                        if timelineFrame.gridLines[i] then
                            timelineFrame.gridLines[i]:Hide()
                        end
                    end
                end
                for i = #self.labels + 1, #timelineFrame.gridLines do
                    if timelineFrame.gridLines[i] then
                        timelineFrame.gridLines[i]:Hide()
                    end
                end
            end
        end
    end

    local cursorLine = CreateFrame("Frame", nil, timelineFrame.body, "BackdropTemplate")
    cursorLine:SetWidth(1)
    cursorLine:SetFrameLevel(timelineFrame.body:GetFrameLevel() + 150)
    cursorLine:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    cursorLine:SetBackdropColor(1, 1, 0, 0.8)
    cursorLine:Hide()
    timelineFrame.cursorLine = cursorLine

    local cursorTimeLabel = cursorLine:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cursorTimeLabel:SetPoint("BOTTOM", cursorLine, "TOP", 0, 2)
    cursorTimeLabel:SetTextColor(1, 1, 0.7, 1)
    timelineFrame.cursorTimeLabel = cursorTimeLabel

    local cursorTimeBg = cursorLine:CreateTexture(nil, "BACKGROUND")
    cursorTimeBg:SetColorTexture(0, 0, 0, 0.7)
    cursorTimeBg:SetPoint("TOPLEFT", cursorTimeLabel, "TOPLEFT", -3, 2)
    cursorTimeBg:SetPoint("BOTTOMRIGHT", cursorTimeLabel, "BOTTOMRIGHT", 3, -1)
    timelineFrame.cursorTimeBg = cursorTimeBg

    local function updateCursorLine()
        if not timelineFrame.body:IsVisible() then
            cursorLine:Hide()
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        cursorX = cursorX / uiScale
        cursorY = cursorY / uiScale

        local bodyLeft = timelineFrame.body:GetLeft() or 0
        local bodyRight = timelineFrame.body:GetRight() or 0
        local bodyTop = timelineFrame.body:GetTop() or 0
        local bodyBottom = timelineFrame.body:GetBottom() or 0

        if cursorX >= bodyLeft and cursorX <= bodyRight and cursorY >= bodyBottom and cursorY <= bodyTop then
            local mouseXInBody = cursorX - bodyLeft
            local scrollX = timelineFrame.horizontalSlider and timelineFrame.horizontalSlider:GetValue() or 0
            local pixelsPerSecond = timelineFrame.options.pixels_per_second or 15
            local currentScale = timelineFrame.currentScale or 1

            local timeAtCursor = (scrollX + mouseXInBody) / (pixelsPerSecond * currentScale)

            local minutes = math.floor(timeAtCursor / 60)
            local seconds = math.floor(timeAtCursor % 60)
            cursorTimeLabel:SetText(string.format("%d:%02d", minutes, seconds))

            local elapsedHeight = timelineFrame.options.elapsed_timeline_height or 20
            cursorLine:ClearAllPoints()
            cursorLine:SetPoint("TOP", timelineFrame.body, "TOPLEFT", mouseXInBody, -elapsedHeight)
            cursorLine:SetPoint("BOTTOM", timelineFrame.body, "BOTTOMLEFT", mouseXInBody, 0)
            cursorLine:Show()
        else
            cursorLine:Hide()
        end
    end

    timelineFrame.body:EnableMouse(true)
    timelineFrame.body:SetScript("OnEnter", function()
        cursorLine:Show()
    end)
    timelineFrame.body:SetScript("OnLeave", function()
        cursorLine:Hide()
    end)

    local updateThrottle = 0
    timelineFrame.body:SetScript("OnUpdate", function(self, elapsed)
        updateThrottle = updateThrottle + elapsed
        if updateThrottle >= 0.016 then
            updateThrottle = 0
            if self:IsMouseOver() then
                updateCursorLine()
            end
        end
    end)

    NSI:SetupTimelineHooks(timelineFrame)

    local timeline_top = top_offset - 45
    if timelineFrame.headerFrame then
        timelineFrame.headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, timeline_top)
        timelineFrame.headerFrame:SetHeight(timeline_height)
        timelineFrame:SetPoint("TOPLEFT", timelineFrame.headerFrame, "TOPRIGHT", 0, 0)
    else
        timelineFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, timeline_top)
    end

    if timelineFrame.scaleSlider then
        timelineFrame.scaleSlider:HookScript("OnValueChanged", function()
            NSI:UpdateEmbeddedPhaseMarkers(parent)
        end)

        local helpLabel = DF:CreateLabel(parent, "Scroll: Navigate | Ctrl+Scroll: Zoom | Shift+Scroll: Vertical", 10, "gray")
        helpLabel:SetPoint("TOPLEFT", timelineFrame.scaleSlider, "BOTTOMLEFT", 0, -5)
    end

    parent.phaseMarkers = {}

    parent:SetScript("OnShow", function(self)
        NSI:RefreshEmbeddedTimeline(self)
    end)

    return parent
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Timeline = {
    BuildTimelineTabUI = BuildTimelineTabUI,
}
