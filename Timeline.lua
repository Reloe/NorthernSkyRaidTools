local _, NSI = ... -- Internal namespace

local DF = _G["DetailsFramework"]
local expressway = [[Interface\AddOns\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]

-- Get boss ability lines for the timeline
-- Returns array of timeline lines and max time
function NSI:GetBossAbilityLines(encounterID, filterImportantOnly, requestedDifficulty)
    if not encounterID or not self.BossTimelines or not self.BossTimelines[encounterID] then
        return {}, 0
    end

    local abilities, duration, phases, difficulty = self:GetBossTimelineAbilities(encounterID, requestedDifficulty)
    if not abilities then return {}, 0 end

    local lines = {}
    local maxTime = duration or 0

    -- Group abilities by name (since same ability can appear in multiple phases)
    local abilityGroups = {}
    for _, ability in ipairs(abilities) do
        local key = ability.name
        if not abilityGroups[key] then
            abilityGroups[key] = {
                name = ability.name,
                spellID = ability.spellID,
                category = ability.category,
                color = ability.color,
                sortOrder = ability.sortOrder,
                times = {},
                durations = {},
            }
        end
        -- Add all times from this ability
        for i, time in ipairs(ability.times) do
            table.insert(abilityGroups[key].times, time)
            table.insert(abilityGroups[key].durations, ability.duration)
        end
    end

    -- Convert to timeline lines, sorted by category then name
    local sortedAbilities = {}
    for _, data in pairs(abilityGroups) do
        table.insert(sortedAbilities, data)
    end
    table.sort(sortedAbilities, function(a, b)
        -- Sort by pre-computed sort order from ParseCategoryForDisplay
        local aOrder = a.sortOrder or 99
        local bOrder = b.sortOrder or 99
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
        return a.name < b.name
    end)

    for _, abilityData in ipairs(sortedAbilities) do
        local timeline = {}

        -- Sort times
        local sortedTimes = {}
        for i, time in ipairs(abilityData.times) do
            table.insert(sortedTimes, {time = time, dur = abilityData.durations[i] or 3})
        end
        table.sort(sortedTimes, function(a, b) return a.time < b.time end)

        -- Create timeline blocks
        for _, entry in ipairs(sortedTimes) do
            table.insert(timeline, {
                entry.time,
                0,
                true,
                entry.dur,
                abilityData.spellID,
                payload = {
                    category = abilityData.category,
                    important = abilityData.important,
                    isBossAbility = true,
                },
            })
        end

        -- Get icon
        local lineIcon = nil
        if abilityData.spellID then
            local spellInfo = C_Spell.GetSpellInfo(abilityData.spellID)
            if spellInfo then
                lineIcon = spellInfo.iconID
            end
        end

        -- Color-code the name by category
        local color = abilityData.color or {0.7, 0.7, 0.7}
        local coloredName = string.format("|cff%02x%02x%02x%s|r",
            math.floor(color[1] * 255),
            math.floor(color[2] * 255),
            math.floor(color[3] * 255),
            abilityData.name)

        table.insert(lines, {
            spellId = abilityData.spellID,
            icon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark",
            text = coloredName,
            timeline = timeline,
            isBossAbility = true,
            category = abilityData.category,
        })
    end

    return lines, maxTime, phases, difficulty
end

-- Get timeline data from ProcessedReminder (player's own filtered reminders)
-- Returns data in DetailsFramework timeline format
function NSI:GetMyTimelineData(includeBossAbilities)
    if not self.ProcessedReminder then return nil end

    -- Find which encounter has data
    local encID = self.EncounterID
    if not encID then
        -- Try to find any encounter with data
        for id, _ in pairs(self.ProcessedReminder) do
            encID = id
            break
        end
    end

    if not encID or not self.ProcessedReminder[encID] then return nil end

    -- Get difficulty from active reminder (default to Mythic)
    local reminderDifficulty = "Mythic"
    local activeReminder = NSRT.ActiveReminder
    local reminderSource = NSRT.Reminders
    if not activeReminder or activeReminder == "" then
        activeReminder = NSRT.ActivePersonalReminder
        reminderSource = NSRT.PersonalReminders
    end
    if activeReminder and activeReminder ~= "" and reminderSource[activeReminder] then
        local diff = reminderSource[activeReminder]:match("Difficulty:([^;\n]+)")
        if diff then
            reminderDifficulty = strtrim(diff)
        end
    end

    -- Data structure: playerReminders[playerName][spellKey] = {entries}
    local playerReminders = {}
    local maxTime = 0

    -- Iterate through all phases
    for phase, reminders in pairs(self.ProcessedReminder[encID]) do
        for _, reminder in ipairs(reminders) do
            local time = reminder.time
            local dur = reminder.dur or 8
            local spellID = reminder.spellID
            local text = reminder.text or reminder.rawtext

            if time then
                -- Track max time for timeline length
                if time + dur > maxTime then
                    maxTime = time + dur
                end

                -- For processed reminders, we don't have tag info
                -- Use "You" as the player name since these are your reminders
                local player = "You"

                -- Determine the key for this ability
                local abilityKey = spellID and tostring(spellID) or "text"

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
                    text = text,
                })
            end
        end
    end

    -- Convert to timeline format
    local lines = {}

    -- Sort abilities by spellID then text
    local sortedAbilities = {}
    if playerReminders["You"] then
        for abilityKey, data in pairs(playerReminders["You"]) do
            table.insert(sortedAbilities, {key = abilityKey, data = data})
        end
    end
    table.sort(sortedAbilities, function(a, b)
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

    -- Create lines
    for _, ability in ipairs(sortedAbilities) do
        local abilityData = ability.data
        local spellID = abilityData.spellID
        local timeline = {}

        -- Sort entries by time
        table.sort(abilityData.entries, function(a, b) return a.time < b.time end)

        -- Create timeline blocks
        for _, entry in ipairs(abilityData.entries) do
            table.insert(timeline, {
                entry.time,
                0,
                true,
                entry.dur,
                spellID,
                payload = {phase = entry.phase, text = entry.text},
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
            lineName = "Notes"
            lineIcon = "Interface\\ICONS\\INV_Misc_Note_01"
        end

        table.insert(lines, {
            spellId = lineSpellId,
            icon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark",
            text = lineName,
            timeline = timeline,
        })
    end

    -- Add boss abilities if requested (at the top)
    local phases = nil
    local difficulty = nil
    local finalLines = {}
    if includeBossAbilities and encID then
        local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(encID, false, reminderDifficulty)
        phases = bossPhases
        difficulty = bossDifficulty

        -- Add boss ability lines first
        for _, line in ipairs(bossLines) do
            table.insert(finalLines, line)
        end

        -- Add separator line if we have both player and boss abilities
        if #lines > 0 and #bossLines > 0 then
            table.insert(finalLines, {
                spellId = nil,
                icon = "Interface\\ICONS\\INV_Misc_Gear_01",
                text = "|cff888888--- Your Reminders ---|r",
                timeline = {},
                isSeparator = true,
            })
        end

        -- Use boss timeline length if longer
        if bossMaxTime > maxTime then
            maxTime = bossMaxTime
        end
    end

    -- Append player reminder lines
    for _, line in ipairs(lines) do
        table.insert(finalLines, line)
    end

    local timelineLength = math.max(60, math.ceil(maxTime / 30) * 30)

    return {
        length = timelineLength,
        defaultColor = {1, 1, 1, 1},
        useIconOnBlocks = true,
        lines = finalLines,
    }, encID, phases, difficulty
end

-- Get timeline data from a reminder set (ALL reminders, for raid leaders)
-- Returns data in DetailsFramework timeline format
function NSI:GetAllTimelineData(reminderName, personal, includeBossAbilities)
    local source = personal and NSRT.PersonalReminders or NSRT.Reminders
    local reminderStr = source[reminderName]
    if not reminderStr then return nil end

    -- Extract encounter ID from the reminder string
    local encID = reminderStr:match("EncounterID:(%d+)")
    encID = encID and tonumber(encID)

    -- Extract difficulty from the reminder string (default to Mythic)
    local reminderDifficulty = reminderStr:match("Difficulty:([^;\n]+)")
    reminderDifficulty = reminderDifficulty and strtrim(reminderDifficulty) or "Mythic"

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

            -- Parse player names from tag (use [^,]+ to support UTF-8/accented characters)
            for player in tag:gmatch("([^,]+)") do
                player = strtrim(player)
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

    -- Add boss abilities if requested (at the top)
    local phases = nil
    local difficulty = nil
    local finalLines = {}
    if includeBossAbilities and encID then
        local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(encID, false, reminderDifficulty)
        phases = bossPhases
        difficulty = bossDifficulty

        -- Add boss ability lines first
        for _, line in ipairs(bossLines) do
            table.insert(finalLines, line)
        end

        -- Add separator line if we have both player and boss abilities
        if #lines > 0 and #bossLines > 0 then
            table.insert(finalLines, {
                spellId = nil,
                icon = "Interface\\ICONS\\INV_Misc_Gear_01",
                text = "|cff888888--- Player Assignments ---|r",
                timeline = {},
                isSeparator = true,
            })
        end

        -- Use boss timeline length if longer
        if bossMaxTime > maxTime then
            maxTime = bossMaxTime
        end
    end

    -- Append player reminder lines
    for _, line in ipairs(lines) do
        table.insert(finalLines, line)
    end

    -- Round up max time to nearest 30 seconds, minimum 60 seconds
    local timelineLength = math.max(60, math.ceil(maxTime / 30) * 30)

    return {
        length = timelineLength,
        defaultColor = {1, 1, 1, 1},
        useIconOnBlocks = true,
        lines = finalLines,
    }, encID, phases, difficulty
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

    -- Mode: "my" = My Reminders (from ProcessedReminder), "all" = All Reminders (from raw strings)
    timelineWindow.mode = "my"

    -- Mode toggle dropdown
    local function BuildModeDropdownOptions()
        return {
            {
                label = "My Reminders",
                value = "my",
                onclick = function(_, _, value)
                    timelineWindow.mode = value
                    timelineWindow.reminderLabel:Hide()
                    timelineWindow.reminderDropdown:Hide()
                    self:RefreshTimelineForMode()
                end
            },
            {
                label = "All Reminders (Raid Leader)",
                value = "all",
                onclick = function(_, _, value)
                    timelineWindow.mode = value
                    timelineWindow.reminderLabel:Show()
                    timelineWindow.reminderDropdown:Show()
                    self:RefreshTimelineForMode()
                end
            },
        }
    end

    local modeLabel = DF:CreateLabel(timelineWindow, "View:", 11, "white")
    modeLabel:SetPoint("TOPLEFT", timelineWindow, "TOPLEFT", 10, -30)

    local modeDropdown = DF:CreateDropDown(timelineWindow, BuildModeDropdownOptions, "my", 200)
    modeDropdown:SetTemplate(options_dropdown_template)
    modeDropdown:SetPoint("LEFT", modeLabel, "RIGHT", 10, 0)
    timelineWindow.modeDropdown = modeDropdown

    -- Build reminder dropdown options function (for "All Reminders" mode)
    local function BuildReminderDropdownOptions()
        local options = {}

        -- Add shared reminders
        local sharedList = self:GetAllReminderNames(false)
        for _, data in ipairs(sharedList) do
            table.insert(options, {
                label = data.name,
                value = {name = data.name, personal = false},
                onclick = function(_, _, value)
                    self:RefreshAllRemindersTimeline(value.name, value.personal)
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
                        self:RefreshAllRemindersTimeline(value.name, value.personal)
                        timelineWindow.currentReminder = value
                    end
                })
            end
        end

        return options
    end

    -- Reminder selection dropdown (only shown in "All Reminders" mode)
    local reminderLabel = DF:CreateLabel(timelineWindow, "Reminder Set:", 11, "white")
    reminderLabel:SetPoint("LEFT", modeDropdown, "RIGHT", 20, 0)
    timelineWindow.reminderLabel = reminderLabel
    reminderLabel:Hide() -- Hidden by default (My Reminders mode)

    local reminderDropdown = DF:CreateDropDown(timelineWindow, BuildReminderDropdownOptions, nil, 300)
    reminderDropdown:SetTemplate(options_dropdown_template)
    reminderDropdown:SetPoint("LEFT", reminderLabel, "RIGHT", 10, 0)
    timelineWindow.reminderDropdown = reminderDropdown
    reminderDropdown:Hide() -- Hidden by default (My Reminders mode)

    -- Boss abilities toggle
    timelineWindow.showBossAbilities = true -- Default to showing boss abilities

    local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")

    local bossAbilitiesToggle = DF:CreateSwitch(timelineWindow,
        function(self, _, value)
            timelineWindow.showBossAbilities = value
            NSI:RefreshTimelineForMode()
        end,
        true, 20, 20, nil, nil, nil, "BossAbilitiesToggle", nil, nil, nil, nil, options_switch_template)
    bossAbilitiesToggle:SetAsCheckBox()
    bossAbilitiesToggle:SetPoint("TOPRIGHT", timelineWindow, "TOPRIGHT", -15, -28)
    timelineWindow.bossAbilitiesToggle = bossAbilitiesToggle

    local bossAbilitiesLabel = DF:CreateLabel(timelineWindow, "Show Boss Abilities", 11, "white")
    bossAbilitiesLabel:SetPoint("RIGHT", bossAbilitiesToggle, "LEFT", -5, 0)

    -- No data label (shown when no reminders)
    local noDataLabel = DF:CreateLabel(timelineWindow, "No reminders to display. Load a reminder set first with /ns", 14, "gray")
    noDataLabel:SetPoint("CENTER", timelineWindow, "CENTER", 0, 0)
    timelineWindow.noDataLabel = noDataLabel
    noDataLabel:Hide()

    -- Create timeline component
    -- Height calculation: window_height - top_offset(60) - sliders(45) - help_text(25) = 420
    local header_width = 180
    local timelineOptions = {
        width = window_width - 40 - header_width,  -- Subtract header width when detached
        height = window_height - 130,
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

        -- Line hover callback
        on_enter = function(line)
            line:SetBackdropColor(unpack(line.backdrop_color_highlight))
        end,
        on_leave = function(line)
            line:SetBackdropColor(unpack(line.backdrop_color))
        end,

        -- Called when a line is created - add tooltip to the header
        on_create_line = function(line)
            if line.lineHeader then
                line.lineHeader:EnableMouse(true)
                line.lineHeader:SetScript("OnEnter", function(self)
                    -- Highlight the line
                    line:SetBackdropColor(unpack(line.backdrop_color_highlight))
                    -- Show spell tooltip
                    if line.lineData and line.lineData.spellId then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetSpellByID(line.lineData.spellId)
                        GameTooltip:Show()
                    end
                end)
                line.lineHeader:SetScript("OnLeave", function(self)
                    line:SetBackdropColor(unpack(line.backdrop_color))
                    GameTooltip:Hide()
                end)
            end
            -- Constrain text width to prevent overflow
            if line.text then
                line.text:SetWordWrap(false)
                line.text:SetWidth(150) -- header_width (180) - icon (22) - padding (8)
            end
        end,

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
                local duration = tonumber(block.info.duration) or 0
                if duration > 0 then
                    GameTooltip:AddLine("Duration: " .. duration .. "s", 0.7, 0.7, 0.7)
                end

                -- Show category for boss abilities
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

    local timelineFrame = DF:CreateTimeLineFrame(timelineWindow, "$parentTimeLine", timelineOptions)
    timelineWindow.timeline = timelineFrame

    -- Position the detached header (sticky first column) and timeline
    if timelineFrame.headerFrame then
        timelineFrame.headerFrame:SetPoint("TOPLEFT", timelineWindow, "TOPLEFT", 10, -60)
        timelineFrame.headerFrame:SetHeight(timelineOptions.height)
        timelineFrame:SetPoint("TOPLEFT", timelineFrame.headerFrame, "TOPRIGHT", 0, 0)
    else
        timelineFrame:SetPoint("TOPLEFT", timelineWindow, "TOPLEFT", 10, -60)
    end

    -- Hook scale slider to update phase markers when zooming
    if timelineFrame.scaleSlider then
        timelineFrame.scaleSlider:HookScript("OnValueChanged", function()
            NSI:UpdatePhaseMarkers()
        end)
    end

    -- Help text (positioned at bottom, below the sliders)
    local helpLabel = DF:CreateLabel(timelineWindow, "Scroll: Navigate | Ctrl+Scroll: Zoom | Shift+Scroll: Vertical", 10, "gray")
    helpLabel:SetPoint("BOTTOMLEFT", timelineWindow, "BOTTOMLEFT", 10, 5)

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
        -- Default to "My Reminders" mode
        self:RefreshTimelineForMode()
    end
end

-- Refresh timeline based on current mode
function NSI:RefreshTimelineForMode()
    if not self.TimelineWindow then return end

    if self.TimelineWindow.mode == "my" then
        self:RefreshMyRemindersTimeline()
    else
        -- "all" mode - need to select a reminder set
        local currentReminder = self.TimelineWindow.currentReminder
        if currentReminder then
            self:RefreshAllRemindersTimeline(currentReminder.name, currentReminder.personal)
        else
            -- Try to select active reminder
            local activeReminder = NSRT.ActiveReminder
            local isPersonal = false
            if not activeReminder or activeReminder == "" then
                activeReminder = NSRT.ActivePersonalReminder
                isPersonal = true
            end
            if activeReminder and activeReminder ~= "" then
                self:RefreshAllRemindersTimeline(activeReminder, isPersonal)
                self.TimelineWindow.currentReminder = {name = activeReminder, personal = isPersonal}
                self.TimelineWindow.reminderDropdown:Select({name = activeReminder, personal = isPersonal})
            else
                self.TimelineWindow.noDataLabel:SetText("Select a reminder set from the dropdown.")
                self.TimelineWindow.noDataLabel:Show()
                self.TimelineWindow.timeline:Hide()
            end
        end
    end
end

-- Refresh timeline with player's own processed reminders (My Reminders mode)
function NSI:RefreshMyRemindersTimeline()
    if not self.TimelineWindow or not self.TimelineWindow.timeline then return end

    local includeBossAbilities = self.TimelineWindow.showBossAbilities
    local data, encID, phases, difficulty = self:GetMyTimelineData(includeBossAbilities)

    if data and data.lines and #data.lines > 0 then
        self.TimelineWindow.noDataLabel:Hide()
        self.TimelineWindow.timeline:Show()
        self.TimelineWindow.timeline:SetData(data)
        self.TimelineWindow.currentEncounterID = encID
        self.TimelineWindow.currentPhases = phases
        self.TimelineWindow.currentDifficulty = difficulty
        self:UpdatePhaseMarkers()
        self:UpdateTimelineTitle()
    else
        -- If no player reminders but boss abilities enabled, show just boss abilities
        if includeBossAbilities then
            -- Get encounter ID and difficulty from active reminder
            local bossEncID = self.EncounterID
            local fallbackDifficulty = "Mythic"
            local activeReminder = NSRT.ActiveReminder
            local reminderSource = NSRT.Reminders
            if not activeReminder or activeReminder == "" then
                activeReminder = NSRT.ActivePersonalReminder
                reminderSource = NSRT.PersonalReminders
            end
            if activeReminder and activeReminder ~= "" and reminderSource[activeReminder] then
                local reminderStr = reminderSource[activeReminder]
                -- Get encounter ID from reminder if not in encounter
                if not bossEncID then
                    local encIDStr = reminderStr:match("EncounterID:(%d+)")
                    bossEncID = encIDStr and tonumber(encIDStr)
                end
                -- Get difficulty
                local diff = reminderStr:match("Difficulty:([^;\n]+)")
                if diff then
                    fallbackDifficulty = strtrim(diff)
                end
            end

            if bossEncID and self.BossTimelines and self.BossTimelines[bossEncID] then
                local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(bossEncID, false, fallbackDifficulty)
                if #bossLines > 0 then
                    local bossData = {
                        length = math.max(60, math.ceil(bossMaxTime / 30) * 30),
                        defaultColor = {1, 1, 1, 1},
                        useIconOnBlocks = true,
                        lines = bossLines,
                    }
                    self.TimelineWindow.noDataLabel:Hide()
                    self.TimelineWindow.timeline:Show()
                    self.TimelineWindow.timeline:SetData(bossData)
                    self.TimelineWindow.currentEncounterID = bossEncID
                    self.TimelineWindow.currentPhases = bossPhases
                    self.TimelineWindow.currentDifficulty = bossDifficulty
                    self:UpdatePhaseMarkers()
                    self:UpdateTimelineTitle()
                    return
                end
            end
        end

        self.TimelineWindow.noDataLabel:SetText("No reminders loaded for you.\nLoad a reminder set with /ns and ensure it contains assignments for you.")
        self.TimelineWindow.noDataLabel:Show()
        self.TimelineWindow.timeline:SetData({
            length = 300,
            defaultColor = {1, 1, 1, 1},
            useIconOnBlocks = true,
            lines = {},
        })
        self.TimelineWindow.currentEncounterID = nil
        self.TimelineWindow.currentPhases = nil
        self.TimelineWindow.currentDifficulty = nil
        self:UpdatePhaseMarkers()
        self:UpdateTimelineTitle()
    end
end

-- Refresh timeline with all reminders from a reminder set (All Reminders mode)
function NSI:RefreshAllRemindersTimeline(reminderName, personal)
    if not self.TimelineWindow or not self.TimelineWindow.timeline then return end

    local includeBossAbilities = self.TimelineWindow.showBossAbilities
    local data, encID, phases, difficulty = self:GetAllTimelineData(reminderName, personal, includeBossAbilities)

    if data and data.lines and #data.lines > 0 then
        self.TimelineWindow.noDataLabel:Hide()
        self.TimelineWindow.timeline:Show()
        self.TimelineWindow.timeline:SetData(data)
        self.TimelineWindow.currentEncounterID = encID
        self.TimelineWindow.currentPhases = phases
        self.TimelineWindow.currentDifficulty = difficulty
        self:UpdatePhaseMarkers()
        self:UpdateTimelineTitle()
    else
        self.TimelineWindow.noDataLabel:SetText("No player-specific reminders found in this reminder set.\n(Only showing named player assignments, not role/group tags)")
        self.TimelineWindow.noDataLabel:Show()
        self.TimelineWindow.timeline:SetData({
            length = 300,
            defaultColor = {1, 1, 1, 1},
            useIconOnBlocks = true,
            lines = {},
        })
        self.TimelineWindow.currentEncounterID = nil
        self.TimelineWindow.currentPhases = nil
        self.TimelineWindow.currentDifficulty = nil
        self:UpdatePhaseMarkers()
        self:UpdateTimelineTitle()
    end
end

-- Update timeline window title with boss name and difficulty
function NSI:UpdateTimelineTitle()
    local window = self.TimelineWindow
    if not window then return end

    local title = "|cFF00FFFFNorthern Sky|r Timeline"

    local encID = window.currentEncounterID
    if encID then
        local bossName = self:GetEncounterName(encID)
        local difficulty = window.currentDifficulty

        if difficulty then
            title = string.format("|cFF00FFFFNorthern Sky|r Timeline - %s (%s)", bossName, difficulty)
        else
            title = string.format("|cFF00FFFFNorthern Sky|r Timeline - %s", bossName)
        end
    end

    -- Update the title text
    if window.TitleBar and window.TitleBar.Text then
        window.TitleBar.Text:SetText(title)
    elseif window.Title then
        window.Title:SetText(title)
    end
end

-- Update phase markers on the timeline
function NSI:UpdatePhaseMarkers()
    local window = self.TimelineWindow
    if not window then return end

    -- Create phase markers container if needed
    if not window.phaseMarkers then
        window.phaseMarkers = {}
    end

    -- Hide all existing markers
    for _, marker in pairs(window.phaseMarkers) do
        marker:Hide()
    end

    local phases = window.currentPhases
    local encID = window.currentEncounterID
    if not phases or not encID then return end

    local timeline = window.timeline
    if not timeline then return end

    -- Get timeline scroll frame info for positioning
    local body = timeline.body
    if not body then return end

    local basePixelsPerSecond = timeline.options.pixels_per_second or 15
    local currentScale = timeline.currentScale or 1
    local pixelsPerSecond = basePixelsPerSecond * currentScale
    local headerWidth = timeline.options.header_width or 180
    local elapsedHeight = timeline.options.elapsed_timeline_height or 20

    -- Create/update phase markers
    for phaseNum, phaseData in pairs(phases) do
        -- Skip phase 1 (always at 0)
        if phaseNum > 1 then
            local marker = window.phaseMarkers[phaseNum]
            if not marker then
                -- Create new marker
                marker = CreateFrame("Frame", nil, body, "BackdropTemplate")
                marker:SetSize(4, body:GetHeight() - elapsedHeight)
                marker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})

                -- Make it draggable
                marker:EnableMouse(true)
                marker:SetMovable(true)
                marker:RegisterForDrag("LeftButton")

                marker.phaseNum = phaseNum
                marker.encID = encID

                marker:SetScript("OnDragStart", function(self)
                    self.isDragging = true
                    self:StartMoving()
                end)

                marker:SetScript("OnDragStop", function(self)
                    self:StopMovingOrSizing()
                    self.isDragging = false

                    -- Calculate new time based on position (use current scale)
                    local currentPPS = (timeline.options.pixels_per_second or 15) * (timeline.currentScale or 1)
                    local bodyLeft = body:GetLeft() or 0
                    local markerLeft = self:GetLeft() or 0
                    local xOffset = markerLeft - bodyLeft

                    local newTime = math.max(0, xOffset / currentPPS)
                    newTime = math.floor(newTime) -- Round to nearest second

                    -- Save the new phase timing
                    NSI:SetPhaseStart(self.encID, self.phaseNum, newTime)

                    -- Refresh the timeline
                    NSI:RefreshTimelineForMode()
                end)

                -- Tooltip
                marker:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local phaseName = phases[self.phaseNum] and phases[self.phaseNum].name or ("Phase " .. self.phaseNum)
                    local time = NSI:GetPhaseStart(self.encID, self.phaseNum)
                    local minutes = math.floor(time / 60)
                    local seconds = math.floor(time % 60)
                    GameTooltip:AddLine(phaseName, 1, 1, 1)
                    GameTooltip:AddLine(string.format("Start: %d:%02d", minutes, seconds), 0.7, 0.7, 0.7)
                    GameTooltip:AddLine("|cff00ff00Drag to adjust timing|r", 0, 1, 0)
                    GameTooltip:AddLine("|cffff9900Right-click to reset|r", 1, 0.6, 0)
                    GameTooltip:Show()
                end)

                marker:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                -- Right-click to reset
                marker:SetScript("OnMouseDown", function(self, button)
                    if button == "RightButton" then
                        NSI:ResetPhaseStart(self.encID, self.phaseNum)
                        NSI:RefreshTimelineForMode()
                    end
                end)

                window.phaseMarkers[phaseNum] = marker
            end

            -- Position the marker
            local phaseStart = self:GetPhaseStart(encID, phaseNum)
            local xPos = phaseStart * pixelsPerSecond

            -- Set color from phase data (default to red for visibility)
            local color = phaseData.color or {0.8, 0.2, 0.2}
            marker:SetBackdropColor(color[1], color[2], color[3], 0.8)

            marker:ClearAllPoints()
            marker:SetPoint("TOPLEFT", body, "TOPLEFT", xPos, -elapsedHeight)
            marker:SetHeight(body:GetHeight() - elapsedHeight)
            marker:SetFrameLevel(body:GetFrameLevel() + 10)
            marker:Show()

            -- Update stored data
            marker.encID = encID
        end
    end
end

--------------------------------------------------------------------------------
-- EMBEDDED TIMELINE FUNCTIONS (for NSUI tab)
--------------------------------------------------------------------------------

-- Refresh the embedded timeline based on current mode
function NSI:RefreshEmbeddedTimeline(tab)
    if not tab or not tab.timeline then return end

    if tab.timelineMode == "my" then
        self:RefreshEmbeddedMyReminders(tab)
    else
        local currentReminder = tab.currentReminder
        if currentReminder then
            self:RefreshEmbeddedAllReminders(tab, currentReminder.name, currentReminder.personal)
        else
            -- Try to select active reminder
            local activeReminder = NSRT.ActiveReminder
            local isPersonal = false
            if not activeReminder or activeReminder == "" then
                activeReminder = NSRT.ActivePersonalReminder
                isPersonal = true
            end
            if activeReminder and activeReminder ~= "" then
                self:RefreshEmbeddedAllReminders(tab, activeReminder, isPersonal)
                tab.currentReminder = {name = activeReminder, personal = isPersonal}
                tab.reminderDropdown:Select({name = activeReminder, personal = isPersonal})
            else
                tab.noDataLabel:SetText("Select a reminder set from the dropdown.")
                tab.noDataLabel:Show()
                tab.timeline:Hide()
            end
        end
    end
end

-- Refresh embedded timeline with player's own processed reminders
function NSI:RefreshEmbeddedMyReminders(tab)
    if not tab or not tab.timeline then return end

    local includeBossAbilities = tab.showBossAbilities
    local data, encID, phases, difficulty = self:GetMyTimelineData(includeBossAbilities)

    if data and data.lines and #data.lines > 0 then
        tab.noDataLabel:Hide()
        tab.timeline:Show()
        tab.timeline:SetData(data)
        tab.currentEncounterID = encID
        tab.currentPhases = phases
        tab.currentDifficulty = difficulty
        self:UpdateEmbeddedPhaseMarkers(tab)
        self:UpdateEmbeddedTimelineTitle(tab)
    else
        -- If no player reminders but boss abilities enabled, show just boss abilities
        if includeBossAbilities then
            -- Get encounter ID and difficulty from active reminder
            local bossEncID = self.EncounterID
            local fallbackDifficulty = "Mythic"
            local activeReminder = NSRT.ActiveReminder
            local reminderSource = NSRT.Reminders
            if not activeReminder or activeReminder == "" then
                activeReminder = NSRT.ActivePersonalReminder
                reminderSource = NSRT.PersonalReminders
            end
            if activeReminder and activeReminder ~= "" and reminderSource[activeReminder] then
                local reminderStr = reminderSource[activeReminder]
                -- Get encounter ID from reminder if not in encounter
                if not bossEncID then
                    local encIDStr = reminderStr:match("EncounterID:(%d+)")
                    bossEncID = encIDStr and tonumber(encIDStr)
                end
                -- Get difficulty
                local diff = reminderStr:match("Difficulty:([^;\n]+)")
                if diff then
                    fallbackDifficulty = strtrim(diff)
                end
            end

            if bossEncID and self.BossTimelines and self.BossTimelines[bossEncID] then
                local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(bossEncID, false, fallbackDifficulty)
                if #bossLines > 0 then
                    local bossData = {
                        length = math.max(60, math.ceil(bossMaxTime / 30) * 30),
                        defaultColor = {1, 1, 1, 1},
                        useIconOnBlocks = true,
                        lines = bossLines,
                    }
                    tab.noDataLabel:Hide()
                    tab.timeline:Show()
                    tab.timeline:SetData(bossData)
                    tab.currentEncounterID = bossEncID
                    tab.currentPhases = bossPhases
                    tab.currentDifficulty = bossDifficulty
                    self:UpdateEmbeddedPhaseMarkers(tab)
                    self:UpdateEmbeddedTimelineTitle(tab)
                    return
                end
            end
        end

        tab.noDataLabel:SetText("No reminders loaded for you.\nLoad a reminder set with /ns and ensure it contains assignments for you.")
        tab.noDataLabel:Show()
        tab.timeline:SetData({
            length = 300,
            defaultColor = {1, 1, 1, 1},
            useIconOnBlocks = true,
            lines = {},
        })
        tab.currentEncounterID = nil
        tab.currentPhases = nil
        tab.currentDifficulty = nil
        self:UpdateEmbeddedPhaseMarkers(tab)
        self:UpdateEmbeddedTimelineTitle(tab)
    end
end

-- Refresh embedded timeline with all reminders from a reminder set
function NSI:RefreshEmbeddedAllReminders(tab, reminderName, personal)
    if not tab or not tab.timeline then return end

    local includeBossAbilities = tab.showBossAbilities
    local data, encID, phases, difficulty = self:GetAllTimelineData(reminderName, personal, includeBossAbilities)

    if data and data.lines and #data.lines > 0 then
        tab.noDataLabel:Hide()
        tab.timeline:Show()
        tab.timeline:SetData(data)
        tab.currentEncounterID = encID
        tab.currentPhases = phases
        tab.currentDifficulty = difficulty
        self:UpdateEmbeddedPhaseMarkers(tab)
        self:UpdateEmbeddedTimelineTitle(tab)
    else
        tab.noDataLabel:SetText("No player-specific reminders found in this reminder set.\n(Only showing named player assignments, not role/group tags)")
        tab.noDataLabel:Show()
        tab.timeline:SetData({
            length = 300,
            defaultColor = {1, 1, 1, 1},
            useIconOnBlocks = true,
            lines = {},
        })
        tab.currentEncounterID = nil
        tab.currentPhases = nil
        tab.currentDifficulty = nil
        self:UpdateEmbeddedPhaseMarkers(tab)
        self:UpdateEmbeddedTimelineTitle(tab)
    end
end

-- Update embedded timeline title with boss name and difficulty
function NSI:UpdateEmbeddedTimelineTitle(tab)
    if not tab or not tab.titleLabel then return end

    local title = ""
    local encID = tab.currentEncounterID
    if encID then
        local bossName = self:GetEncounterName(encID)
        local difficulty = tab.currentDifficulty
        if difficulty then
            title = string.format("%s (%s)", bossName, difficulty)
        else
            title = bossName
        end
    end

    tab.titleLabel:SetText(title)
end

-- Update phase markers on the embedded timeline
function NSI:UpdateEmbeddedPhaseMarkers(tab)
    if not tab then return end

    -- Create phase markers container if needed
    if not tab.phaseMarkers then
        tab.phaseMarkers = {}
    end

    -- Hide all existing markers
    for _, marker in pairs(tab.phaseMarkers) do
        marker:Hide()
    end

    local phases = tab.currentPhases
    local encID = tab.currentEncounterID
    if not phases or not encID then return end

    local timeline = tab.timeline
    if not timeline then return end

    local body = timeline.body
    if not body then return end

    local basePixelsPerSecond = timeline.options.pixels_per_second or 15
    local currentScale = timeline.currentScale or 1
    local pixelsPerSecond = basePixelsPerSecond * currentScale
    local elapsedHeight = timeline.options.elapsed_timeline_height or 20

    for phaseNum, phaseData in pairs(phases) do
        if phaseNum > 1 then
            local marker = tab.phaseMarkers[phaseNum]
            if not marker then
                marker = CreateFrame("Frame", nil, body, "BackdropTemplate")
                marker:SetSize(4, body:GetHeight() - elapsedHeight)
                marker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})

                marker:EnableMouse(true)
                marker:SetMovable(true)
                marker:RegisterForDrag("LeftButton")

                marker.phaseNum = phaseNum
                marker.encID = encID
                marker.parentTab = tab

                marker:SetScript("OnDragStart", function(self)
                    self.isDragging = true
                    self:StartMoving()
                end)

                marker:SetScript("OnDragStop", function(self)
                    self:StopMovingOrSizing()
                    self.isDragging = false

                    local currentPPS = (timeline.options.pixels_per_second or 15) * (timeline.currentScale or 1)
                    local bodyLeft = body:GetLeft() or 0
                    local markerLeft = self:GetLeft() or 0
                    local xOffset = markerLeft - bodyLeft

                    local newTime = math.max(0, xOffset / currentPPS)
                    newTime = math.floor(newTime)

                    NSI:SetPhaseStart(self.encID, self.phaseNum, newTime)
                    NSI:RefreshEmbeddedTimeline(self.parentTab)
                end)

                marker:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local phaseName = phases[self.phaseNum] and phases[self.phaseNum].name or ("Phase " .. self.phaseNum)
                    local time = NSI:GetPhaseStart(self.encID, self.phaseNum)
                    local minutes = math.floor(time / 60)
                    local seconds = math.floor(time % 60)
                    GameTooltip:AddLine(phaseName, 1, 1, 1)
                    GameTooltip:AddLine(string.format("Start: %d:%02d", minutes, seconds), 0.7, 0.7, 0.7)
                    GameTooltip:AddLine("|cff00ff00Drag to adjust timing|r", 0, 1, 0)
                    GameTooltip:AddLine("|cffff9900Right-click to reset|r", 1, 0.6, 0)
                    GameTooltip:Show()
                end)

                marker:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                marker:SetScript("OnMouseDown", function(self, button)
                    if button == "RightButton" then
                        NSI:ResetPhaseStart(self.encID, self.phaseNum)
                        NSI:RefreshEmbeddedTimeline(self.parentTab)
                    end
                end)

                tab.phaseMarkers[phaseNum] = marker
            end

            local phaseStart = self:GetPhaseStart(encID, phaseNum)
            local xPos = phaseStart * pixelsPerSecond

            local color = phaseData.color or {0.8, 0.2, 0.2}
            marker:SetBackdropColor(color[1], color[2], color[3], 0.8)

            marker:ClearAllPoints()
            marker:SetPoint("TOPLEFT", body, "TOPLEFT", xPos, -elapsedHeight)
            marker:SetHeight(body:GetHeight() - elapsedHeight)
            marker:SetFrameLevel(body:GetFrameLevel() + 10)
            marker:Show()

            marker.encID = encID
        end
    end
end
