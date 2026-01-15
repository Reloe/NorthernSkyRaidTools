local _, NSI = ... -- Internal namespace

local DF = _G["DetailsFramework"]
local expressway = [[Interface\AddOns\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]

-- Get timeline data from a reminder set
-- Returns data in DetailsFramework timeline format
function NSI:GetTimelineData(reminderName, personal)
    local source = personal and NSRT.PersonalReminders or NSRT.Reminders
    local reminderStr = source[reminderName]
    if not reminderStr then return nil end

    -- Data structure: playerReminders[playerName][spellKey] = {entries}
    -- where spellKey is spellID or text (if no spellID)
    local playerReminders = {}
    local maxTime = 0

    for line in reminderStr:gmatch('[^\r\n]+') do
        local tag = line:match("tag:([^;]+)")
        local time = line:match("time:(%d*%.?%d+)")
        local spellID = line:match("spellid:(%d+)")
        local dur = line:match("dur:(%d+)") or "8"
        local text = line:match("text:([^;]+)")
        local phase = line:match("ph:(%d+)") or "1"

        if tag and time then
            time = tonumber(time)
            dur = tonumber(dur)
            phase = tonumber(phase)
            spellID = spellID and tonumber(spellID)

            -- Track max time for timeline length
            if time + dur > maxTime then
                maxTime = time + dur
            end

            -- Determine the key for this ability
            -- For spells: use spellID so each spell gets its own lane
            -- For text-only: use "text" so all text reminders for a player are on one lane
            local abilityKey = spellID and tostring(spellID) or "text"

            -- Parse player names from tag
            for player in tag:gmatch("([%w%-]+)") do
                local lowerPlayer = strlower(player)

                -- Convert "everyone" and "all" to a unified "Everyone" lane
                if lowerPlayer == "everyone" or lowerPlayer == "all" then
                    player = "Everyone"
                -- Skip role/group tags
                elseif lowerPlayer == "healer" or
                       lowerPlayer == "tank" or
                       lowerPlayer == "dps" or
                       lowerPlayer == "melee" or
                       lowerPlayer == "ranged" or
                       lowerPlayer:match("^group%d+$") or
                       lowerPlayer:match("^%d+$") then -- skip spec IDs
                    player = nil
                end

                if player then
                    playerReminders[player] = playerReminders[player] or {}
                    playerReminders[player][abilityKey] = playerReminders[player][abilityKey] or {
                        spellID = spellID,
                        text = text,
                        entries = {}
                    }

                    table.insert(playerReminders[player][abilityKey].entries, {
                        time = time,
                        dur = dur,
                        phase = phase,
                        text = text, -- store text per entry for tooltips
                    })
                end
            end
        end
    end

    -- Convert to timeline format
    local lines = {}

    -- First, get sorted list of players (Everyone first, then alphabetical)
    local sortedPlayers = {}
    for player in pairs(playerReminders) do
        table.insert(sortedPlayers, player)
    end
    table.sort(sortedPlayers, function(a, b)
        if a == "Everyone" then return true end
        if b == "Everyone" then return false end
        return a < b
    end)

    -- For each player, add all their abilities as separate lines
    for _, player in ipairs(sortedPlayers) do
        local abilities = playerReminders[player]

        -- Sort abilities by spellID (numeric) or text (alphabetic)
        local sortedAbilities = {}
        for abilityKey, data in pairs(abilities) do
            table.insert(sortedAbilities, {key = abilityKey, data = data})
        end
        table.sort(sortedAbilities, function(a, b)
            -- Numeric keys (spellIDs) come before text keys
            local aNum = tonumber(a.key)
            local bNum = tonumber(b.key)
            if aNum and bNum then
                return aNum < bNum
            elseif aNum then
                return true
            elseif bNum then
                return false
            else
                return a.key < b.key
            end
        end)

        -- Create a line for each ability
        for _, ability in ipairs(sortedAbilities) do
            local abilityData = ability.data
            local spellID = abilityData.spellID
            local timeline = {}

            -- Sort entries by time
            table.sort(abilityData.entries, function(a, b) return a.time < b.time end)

            -- Create timeline blocks
            for _, entry in ipairs(abilityData.entries) do
                -- Format: {time, length, isAura, auraDuration, blockSpellId}
                table.insert(timeline, {
                    entry.time,     -- [1] time in seconds
                    0,              -- [2] length (0 for icon-based display)
                    true,           -- [3] isAura (shows duration bar)
                    entry.dur,      -- [4] auraDuration
                    spellID,        -- [5] blockSpellId
                    payload = {phase = entry.phase, text = entry.text}, -- use entry-specific text
                })
            end

            -- Get display info
            local lineIcon = nil
            local lineName = ""
            local lineSpellId = spellID

            if spellID then
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                if spellInfo then
                    lineIcon = spellInfo.iconID
                    lineName = spellInfo.name or ""
                end
            else
                -- Text-only reminders: label the lane as "Notes"
                lineName = "Notes"
                lineIcon = "Interface\\ICONS\\INV_Misc_Note_01"
            end

            -- Get shortened player name with color
            local shortPlayer = NSAPI:Shorten(player, 12, false, "GlobalNickNames") or player

            table.insert(lines, {
                spellId = lineSpellId,
                icon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark",
                text = shortPlayer .. " - " .. lineName,
                timeline = timeline,
            })
        end
    end

    -- Round up max time to nearest 30 seconds, minimum 60 seconds
    local timelineLength = math.max(60, math.ceil(maxTime / 30) * 30)

    return {
        length = timelineLength,
        defaultColor = {1, 1, 1, 1},
        useIconOnBlocks = true,
        lines = lines,
    }
end

-- Create the timeline window
function NSI:CreateTimelineWindow()
    local window_width = 1100
    local window_height = 550

    local timelineWindow = DF:CreateSimplePanel(UIParent, window_width, window_height,
        "|cFF00FFFFNorthern Sky|r Timeline", "NSUITimelineWindow", {
        DontRightClickClose = true,
        UseStatusBar = false,
    })
    timelineWindow:SetPoint("CENTER")
    timelineWindow:SetFrameStrata("HIGH")
    timelineWindow:EnableMouse(true)
    timelineWindow:SetMovable(true)
    timelineWindow:RegisterForDrag("LeftButton")
    timelineWindow:SetScript("OnDragStart", timelineWindow.StartMoving)
    timelineWindow:SetScript("OnDragStop", timelineWindow.StopMovingOrSizing)

    local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

    -- Build dropdown options function
    local function BuildReminderDropdownOptions()
        local options = {}

        -- Add shared reminders
        local sharedList = self:GetAllReminderNames(false)
        for _, data in ipairs(sharedList) do
            table.insert(options, {
                label = data.name,
                value = {name = data.name, personal = false},
                onclick = function(_, _, value)
                    self:RefreshTimeline(value.name, value.personal)
                    timelineWindow.currentReminder = value
                end
            })
        end

        -- Add personal reminders with separator
        local personalList = self:GetAllReminderNames(true)
        if #personalList > 0 then
            table.insert(options, {
                label = "--- Personal ---",
                value = nil,
            })
            for _, data in ipairs(personalList) do
                table.insert(options, {
                    label = data.name .. " (Personal)",
                    value = {name = data.name, personal = true},
                    onclick = function(_, _, value)
                        self:RefreshTimeline(value.name, value.personal)
                        timelineWindow.currentReminder = value
                    end
                })
            end
        end

        return options
    end

    -- Reminder selection dropdown
    local reminderLabel = DF:CreateLabel(timelineWindow, "Reminder Set:", 11, "white")
    reminderLabel:SetPoint("TOPLEFT", timelineWindow, "TOPLEFT", 10, -30)

    local reminderDropdown = DF:CreateDropDown(timelineWindow, BuildReminderDropdownOptions, nil, 300)
    reminderDropdown:SetTemplate(options_dropdown_template)
    reminderDropdown:SetPoint("LEFT", reminderLabel, "RIGHT", 10, 0)
    timelineWindow.reminderDropdown = reminderDropdown

    -- No data label (shown when no reminders)
    local noDataLabel = DF:CreateLabel(timelineWindow, "No reminder set loaded. Select a reminder from the dropdown above.", 14, "gray")
    noDataLabel:SetPoint("CENTER", timelineWindow, "CENTER", 0, 0)
    timelineWindow.noDataLabel = noDataLabel
    noDataLabel:Hide()

    -- Create timeline component
    local timelineOptions = {
        width = window_width - 40,
        height = window_height - 90,
        header_width = 180,
        header_detached = false,
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

        -- Block hover tooltip
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
                if block.info.duration and block.info.duration > 0 then
                    GameTooltip:AddLine("Duration: " .. block.info.duration .. "s", 0.7, 0.7, 0.7)
                end
                if block.blockData and block.blockData.payload and block.blockData.payload.phase then
                    GameTooltip:AddLine("Phase: " .. block.blockData.payload.phase, 0.7, 0.7, 0.7)
                end
                if block.blockData and block.blockData.payload and block.blockData.payload.text then
                    GameTooltip:AddLine("Text: " .. block.blockData.payload.text, 0.5, 0.8, 0.5)
                end
                GameTooltip:Show()
            end
        end,
        block_on_leave = function(block)
            GameTooltip:Hide()
        end,
    }

    local timelineFrame = DF:CreateTimeLineFrame(timelineWindow, "$parentTimeLine", timelineOptions)
    timelineFrame:SetPoint("TOPLEFT", timelineWindow, "TOPLEFT", 10, -60)
    timelineWindow.timeline = timelineFrame

    -- Help text
    local helpLabel = DF:CreateLabel(timelineWindow, "Scroll: Navigate | Ctrl+Scroll: Zoom | Shift+Scroll: Vertical", 10, "gray")
    helpLabel:SetPoint("BOTTOMLEFT", timelineWindow, "BOTTOMLEFT", 10, 8)

    timelineWindow:Hide()
    return timelineWindow
end

-- Toggle the timeline window
function NSI:ToggleTimelineWindow()
    if not self.TimelineWindow then
        self.TimelineWindow = self:CreateTimelineWindow()
    end

    if self.TimelineWindow:IsShown() then
        self.TimelineWindow:Hide()
    else
        self.TimelineWindow:Show()

        -- Load active reminder by default
        local activeReminder = NSRT.ActiveReminder
        local isPersonal = false

        if not activeReminder or activeReminder == "" then
            activeReminder = NSRT.ActivePersonalReminder
            isPersonal = true
        end

        if activeReminder and activeReminder ~= "" then
            self:RefreshTimeline(activeReminder, isPersonal)
            self.TimelineWindow.currentReminder = {name = activeReminder, personal = isPersonal}
            -- Update dropdown selection
            self.TimelineWindow.reminderDropdown:Select({name = activeReminder, personal = isPersonal})
        else
            -- Show no data message
            self.TimelineWindow.noDataLabel:Show()
            self.TimelineWindow.timeline:Hide()
        end
    end
end

-- Refresh the timeline with new data
function NSI:RefreshTimeline(reminderName, personal)
    if not self.TimelineWindow or not self.TimelineWindow.timeline then return end

    local data = self:GetTimelineData(reminderName, personal)

    if data and data.lines and #data.lines > 0 then
        self.TimelineWindow.noDataLabel:Hide()
        self.TimelineWindow.timeline:Show()
        self.TimelineWindow.timeline:SetData(data)
    else
        -- Show empty state message
        self.TimelineWindow.noDataLabel:SetText("No player-specific reminders found in this reminder set.\n(Only showing named player assignments, not role/group tags)")
        self.TimelineWindow.noDataLabel:Show()
        -- Still show timeline but with empty data
        self.TimelineWindow.timeline:SetData({
            length = 300,
            defaultColor = {1, 1, 1, 1},
            useIconOnBlocks = true,
            lines = {},
        })
    end
end
