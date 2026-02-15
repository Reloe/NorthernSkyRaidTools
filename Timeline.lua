local _, NSI = ... -- Internal namespace

local DF = _G["DetailsFramework"]

-- Setup timeline hooks for zoom-to-cursor and sticky ruler
-- Call this after creating a timeline with DF:CreateTimeLineFrame
function NSI:SetupTimelineHooks(timeline)
    if not timeline then return end

    local horizontalSlider = timeline.horizontalSlider
    local scaleSlider = timeline.scaleSlider
    local elapsedTimeFrame = timeline.elapsedTimeFrame

    -- Hook mousewheel for zoom-to-cursor behavior
    -- We need to capture state BEFORE the zoom, then adjust AFTER
    if scaleSlider and horizontalSlider then
        -- Storage for pre-zoom state
        timeline.preZoomState = {}

        timeline:HookScript("OnMouseWheel", function(self, delta)
            if IsControlKeyDown() then
                -- Capture state before zoom
                local pixelPerSecond = timeline.options.pixels_per_second or 15
                local currentScale = timeline.currentScale or 1

                -- Get mouse X position relative to the visible timeline frame
                local cursorX = GetCursorPosition()
                local uiScale = 1 / UIParent:GetEffectiveScale()
                cursorX = cursorX * uiScale
                local frameLeft = timeline:GetLeft() or 0
                local mouseXInFrame = cursorX - frameLeft

                -- Get current scroll position
                local scrollPosition = horizontalSlider:GetValue()

                -- Calculate time under mouse
                local timeUnderMouse = (scrollPosition + mouseXInFrame) / (pixelPerSecond * currentScale)

                -- Store for post-zoom adjustment
                timeline.preZoomState.timeUnderMouse = timeUnderMouse
                timeline.preZoomState.mouseXInFrame = mouseXInFrame
                timeline.preZoomState.pixelPerSecond = pixelPerSecond
            end
        end)

        -- Hook scale slider to adjust scroll after zoom
        scaleSlider:HookScript("OnValueChanged", function(self)
            local state = timeline.preZoomState
            if state and state.timeUnderMouse then
                local newScale = timeline.currentScale or 1

                -- Calculate where the time under mouse is now
                local timeInNewScale = state.timeUnderMouse * state.pixelPerSecond * newScale

                -- Set scroll so the time stays under the mouse
                local newScrollValue = max(0, timeInNewScale - state.mouseXInFrame)
                local _, maxScroll = horizontalSlider:GetMinMaxValues()
                horizontalSlider:SetValue(min(newScrollValue, maxScroll))

                -- Clear state
                timeline.preZoomState = {}
            end
        end)
    end

    -- Sticky ruler - keep elapsedTimeFrame fixed at top when scrolling vertically
    -- but scroll horizontally with content
    if elapsedTimeFrame and timeline.verticalSlider and horizontalSlider then
        local headerWidth = timeline.options.header_width or 0
        if timeline.options.header_detached then
            headerWidth = 0
        end

        -- Create a clipping container for the ruler
        local rulerContainer = CreateFrame("Frame", nil, timeline)
        rulerContainer:SetPoint("TOPLEFT", timeline, "TOPLEFT", 0, 0)
        rulerContainer:SetPoint("TOPRIGHT", timeline, "TOPRIGHT", 0, 0)
        rulerContainer:SetHeight(timeline.options.elapsed_timeline_height or 20)
        rulerContainer:SetClipsChildren(true)
        rulerContainer:SetFrameLevel(timeline.body:GetFrameLevel() + 10)

        -- Reparent elapsedTimeFrame to the clipping container
        elapsedTimeFrame:SetParent(rulerContainer)
        elapsedTimeFrame:SetFrameLevel(rulerContainer:GetFrameLevel() + 1)
        elapsedTimeFrame:EnableMouse(false)

        local function updateRulerPosition()
            local scrollX = horizontalSlider:GetValue() or 0
            local bodyWidth = timeline.body:GetWidth() or timeline:GetWidth()
            elapsedTimeFrame:ClearAllPoints()
            elapsedTimeFrame:SetPoint("TOPLEFT", rulerContainer, "TOPLEFT", -scrollX, 0)
            elapsedTimeFrame:SetWidth(bodyWidth)
            elapsedTimeFrame:SetHeight(timeline.options.elapsed_timeline_height or 20)
        end

        -- Hide original vertical time lines (we use gridOverlay instead for proper z-ordering)
        local function repositionLines()
            if elapsedTimeFrame.labels then
                for i, label in pairs(elapsedTimeFrame.labels) do
                    if label.line then
                        label.line:Hide()
                    end
                end
            end
        end

        updateRulerPosition()

        -- Update ruler position when scrolling horizontally
        horizontalSlider:HookScript("OnValueChanged", function()
            updateRulerPosition()
        end)

        hooksecurefunc(timeline, "SetData", function()
            C_Timer.After(0.01, function()
                updateRulerPosition()
                repositionLines()
            end)
        end)

        if scaleSlider then
            scaleSlider:HookScript("OnValueChanged", function()
                C_Timer.After(0.01, function()
                    updateRulerPosition()
                    repositionLines()
                end)
            end)
        end
    end
end

-- Get boss ability lines for the timeline
-- Returns array of timeline lines and max time
-- displayMode: "all" (default), "important" (important only), "combined" (one row)
function NSI:GetBossAbilityLines(encounterID, displayMode, requestedDifficulty)
    if not encounterID or not self.BossTimelines or not self.BossTimelines[encounterID] then
        return {}, 0
    end

    -- Default to "important_healer" if no mode specified (backwards compatible with old boolean param)
    if displayMode == nil or displayMode == false then
        displayMode = self.BossDisplayModes.IMPORTANT_HEALER
    elseif displayMode == true then
        -- Legacy: true meant filter important only
        displayMode = self.BossDisplayModes.IMPORTANT_HEALER
    end

    local abilities, duration, phases, difficulty = self:GetBossTimelineAbilities(encounterID, requestedDifficulty)
    if not abilities then return {}, 0 end

    local lines = {}
    local maxTime = duration or 0

    -- Filter abilities based on display mode
    local filteredAbilities = {}
    for _, ability in ipairs(abilities) do
        local include = true
        if displayMode == self.BossDisplayModes.IMPORTANT_HEALER then
            include = self:IsAbilityImportantForHealer(ability)
        elseif displayMode == self.BossDisplayModes.IMPORTANT_TANK then
            include = self:IsAbilityImportantForTank(ability)
        elseif displayMode == self.BossDisplayModes.COMBINED_IMPORTANT then
            include = self:IsAbilityImportant(ability)
        end
        -- SHOW_ALL and COMBINED include all abilities
        if include then
            table.insert(filteredAbilities, ability)
        end
    end

    -- Handle combined modes - put all abilities on one row
    if displayMode == self.BossDisplayModes.COMBINED or
       displayMode == self.BossDisplayModes.COMBINED_IMPORTANT then
        local combinedTimeline = {}
        local allTimes = {}

        for _, ability in ipairs(filteredAbilities) do
            for i, time in ipairs(ability.times) do
                table.insert(allTimes, {
                    time = time,
                    dur = ability.duration or 3,
                    spellID = ability.spellID,
                    name = ability.name,
                    category = ability.category,
                    color = ability.color,
                })
            end
        end

        -- Sort by time
        table.sort(allTimes, function(a, b) return a.time < b.time end)

        -- Create timeline blocks
        for _, entry in ipairs(allTimes) do
            table.insert(combinedTimeline, {
                entry.time,
                0,
                true,
                entry.dur,
                entry.spellID,
                payload = {
                    category = entry.category,
                    abilityName = entry.name,
                    isBossAbility = true,
                },
            })
        end

        table.insert(lines, {
            spellId = nil,
            icon = "Interface\\ICONS\\Achievement_Boss_KilJaeden",
            text = "|cffff8800Boss Abilities|r",
            timeline = combinedTimeline,
            isBossAbility = true,
            isCombined = true,
        })

        return lines, maxTime, phases, difficulty
    end

    -- Normal mode: group abilities by name (since same ability can appear in multiple phases)
    local abilityGroups = {}
    for _, ability in ipairs(filteredAbilities) do
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

        -- Check if ability is important for healer/tank roles
        local abilityForCheck = {category = abilityData.category}
        local isImportantHealer = self:IsAbilityImportantForHealer(abilityForCheck)
        local isImportantTank = self:IsAbilityImportantForTank(abilityForCheck)

        table.insert(lines, {
            spellId = abilityData.spellID,
            icon = nil, -- We'll use custom icons on the right instead
            text = coloredName,
            timeline = timeline,
            isBossAbility = true,
            category = abilityData.category,
            bossIcon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark",
            isImportantHealer = isImportantHealer,
            isImportantTank = isImportantTank,
        })
    end

    return lines, maxTime, phases, difficulty
end

-- Get timeline data from ProcessedReminder (player's own filtered reminders)
-- Returns data in DetailsFramework timeline format
-- bossDisplayMode: "all", "important", or "combined" (see BossDisplayModes)
function NSI:GetMyTimelineData(includeBossAbilities, bossDisplayMode)
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

    -- Pre-calculate all phase start times for converting phase-relative times to absolute times
    local phaseStarts = {}
    for phase, _ in pairs(self.ProcessedReminder[encID]) do
        phaseStarts[phase] = self:GetPhaseStart(encID, phase, reminderDifficulty) or 0
    end

    -- Iterate through all phases
    for phase, reminders in pairs(self.ProcessedReminder[encID]) do
        local phaseStart = phaseStarts[phase] or 0
        for _, reminder in ipairs(reminders) do
            local time = reminder.time
            local spellID = reminder.spellID
            -- Use settings default if dur not set in reminder
            local dur = reminder.dur or (spellID and NSRT.ReminderSettings.SpellDuration or NSRT.ReminderSettings.TextDuration)
            local text = reminder.text or reminder.rawtext
            local glowUnit = reminder.glowunit
            local glowUnitNames = ""
            if glowUnit and #glowUnit > 0 then
                for i, name in ipairs(glowUnit) do
                    glowUnitNames = glowUnitNames ..
                        NSAPI:Shorten(NSAPI:GetChar(name), 12, false, "GlobalNickNames") .. " "
                end
            else
                glowUnitNames = nil
            end


            if time then
                -- Convert phase-relative time to absolute time
                local absoluteTime = phaseStart + time

                -- Track max time for timeline length
                if absoluteTime + dur > maxTime then
                    maxTime = absoluteTime + dur
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
                    time = absoluteTime,
                    dur = dur,
                    phase = phase,
                    text = text,
                    glowUnit = glowUnitNames,
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
                payload = { phase = entry.phase, text = entry.text, glowUnit = entry.glowUnit },
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
            icon = nil, -- We'll use custom icons on the right instead
            text = lineName,
            timeline = timeline,
            isYourReminder = true,
            reminderSpellIcon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark",
        })
    end

    -- Add boss abilities if requested (at the top)
    local phases = nil
    local difficulty = nil
    local finalLines = {}
    if includeBossAbilities and encID then
        local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(encID, bossDisplayMode, reminderDifficulty)
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
-- bossDisplayMode: "all", "important", or "combined" (see BossDisplayModes)
function NSI:GetAllTimelineData(reminderName, personal, includeBossAbilities, bossDisplayMode)
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
    local discoveredPhases = {}

    for line in reminderStr:gmatch('[^\r\n]+') do
        local tag = line:match("tag:([^;]+)")
        local time = line:match("time:(%d*%.?%d+)")
        local spellID = line:match("spellid:(%d+)")
        local dur = line:match("dur:(%d+)")
        local text = line:match("text:([^;]+)")
        local phase = line:match("ph:(%d+)") or "1"
        local glowUnit = line:match("glowunit:([^;]+)")

        local glowUnitNames = ""
        if glowUnit then
            for name in glowUnit:gmatch("([^%s:]+)") do
                if name ~= "glowunit" then
                    glowUnitNames = glowUnitNames .. NSAPI:Shorten(NSAPI:GetChar(name), 12, false, "GlobalNickNames") .. " "
                end
            end
        else
            glowUnitNames = nil
        end

        if tag and time then
            time = tonumber(time)
            phase = tonumber(phase)
            spellID = spellID and tonumber(spellID)
            -- Use settings default if dur not specified in reminder string
            if dur then
                dur = tonumber(dur)
            else
                dur = spellID and NSRT.ReminderSettings.SpellDuration or NSRT.ReminderSettings.TextDuration
            end

            -- Track discovered phases for later phase start calculation
            discoveredPhases[phase] = true

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
                        glowUnit = glowUnitNames,
                    })
                end
            end
        end
    end

    -- Pre-calculate phase start times for converting phase-relative times to absolute times
    local phaseStarts = {}
    for phase, _ in pairs(discoveredPhases) do
        phaseStarts[phase] = encID and self:GetPhaseStart(encID, phase, reminderDifficulty) or 0
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

            -- Sort entries by phase-relative time for consistent ordering
            table.sort(abilityData.entries, function(a, b)
                if a.phase ~= b.phase then return a.phase < b.phase end
                return a.time < b.time
            end)

            -- Create timeline blocks with absolute times
            for _, entry in ipairs(abilityData.entries) do
                -- Convert phase-relative time to absolute time
                local phaseStart = phaseStarts[entry.phase] or 0
                local absoluteTime = phaseStart + entry.time

                -- Track max time for timeline length
                if absoluteTime + entry.dur > maxTime then
                    maxTime = absoluteTime + entry.dur
                end

                -- Format: {time, length, isAura, auraDuration, blockSpellId}
                table.insert(timeline, {
                    absoluteTime,   -- [1] time in seconds (absolute)
                    0,              -- [2] length (0 for icon-based display)
                    true,           -- [3] isAura (shows duration bar)
                    entry.dur,      -- [4] auraDuration
                    spellID,        -- [5] blockSpellId
                    payload = {phase = entry.phase, text = entry.text, glowUnit = entry.glowUnit}, -- use entry-specific text
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

            -- Get shortened player name
            local shortPlayer = NSAPI:Shorten(player, 12, false, "GlobalNickNames") or player

            -- Get class color for the player
            local classColorHex = nil
            local unitName = NSAPI:GetChar(player, true, "NorthernSkyRaidTools")
            if unitName and UnitExists(unitName) then
                local _, classFile = UnitClass(unitName)
                if classFile then
                    local color = GetClassColorObj(classFile)
                    if color then
                        classColorHex = color:GenerateHexColor()
                    end
                end
            end

            table.insert(lines, {
                spellId = lineSpellId,
                icon = nil, -- We'll use custom icons on the right instead
                text = lineName, -- Spell name left-anchored
                timeline = timeline,
                isPlayerAssignment = true,
                playerName = shortPlayer,
                playerClassColor = classColorHex,
                playerSpellIcon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark",
            })
        end
    end

    -- Add boss abilities if requested (at the top)
    local phases = nil
    local difficulty = nil
    local finalLines = {}
    if includeBossAbilities and encID then
        local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(encID, bossDisplayMode, reminderDifficulty)
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
                text = "|cff888888--- Player Reminders ---|r",
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
            UseScaleBar = true,
        },
        NSRT.NSUI.timeline_window)
    timelineWindow:SetPoint("CENTER")
    timelineWindow:SetFrameStrata("DIALOG")
    timelineWindow:EnableMouse(true)
    timelineWindow:SetMovable(true)
    timelineWindow:RegisterForDrag("LeftButton")
    timelineWindow:SetScript("OnDragStart", timelineWindow.StartMoving)
    timelineWindow:SetScript("OnDragStop", timelineWindow.StopMovingOrSizing)

    -- Create resize grip in bottom-right corner
    local resizeGrip = CreateFrame("Button", nil, timelineWindow)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", timelineWindow, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:EnableMouse(true)

    -- Custom resize logic to avoid the jump caused by StartSizing snapping to mouse position
    resizeGrip.isResizing = false
    resizeGrip:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.isResizing = true
            -- Store initial state when drag starts
            self.startWidth = timelineWindow:GetWidth()
            self.startHeight = timelineWindow:GetHeight()
            local scale = timelineWindow:GetEffectiveScale()
            local cursorX, cursorY = GetCursorPosition()
            self.startCursorX = cursorX / scale
            self.startCursorY = cursorY / scale

            -- Re-anchor to TOPLEFT so resize only affects bottom-right
            local left = timelineWindow:GetLeft()
            local top = timelineWindow:GetTop()
            timelineWindow:ClearAllPoints()
            timelineWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
    end)

    resizeGrip:SetScript("OnMouseUp", function(self, button)
        self.isResizing = false
    end)

    resizeGrip:SetScript("OnUpdate", function(self)
        if not self.isResizing then return end

        local scale = timelineWindow:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        cursorX = cursorX / scale
        cursorY = cursorY / scale

        -- Calculate delta from start position
        local deltaX = cursorX - self.startCursorX
        local deltaY = cursorY - self.startCursorY

        -- Calculate new size (bottom-right resize: width increases with +X, height increases with -Y)
        local newWidth = self.startWidth + deltaX
        local newHeight = self.startHeight - deltaY

        -- Clamp to bounds
        local minWidth, minHeight, maxWidth, maxHeight = 1100, 550, 2000, 1200
        newWidth = math.max(minWidth, math.min(maxWidth, newWidth))
        newHeight = math.max(minHeight, math.min(maxHeight, newHeight))

        timelineWindow:SetSize(newWidth, newHeight)
    end)
    timelineWindow.resizeGrip = resizeGrip
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
    timelineWindow.bossDisplayMode = NSI.BossDisplayModes.IMPORTANT_HEALER -- Default display mode

    local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")

    local bossAbilitiesToggle = DF:CreateSwitch(timelineWindow,
        function(self, _, value)
            timelineWindow.showBossAbilities = value
            -- Show/hide display mode dropdown based on toggle
            if value then
                timelineWindow.bossDisplayLabel:Show()
                timelineWindow.bossDisplayDropdown:Show()
            else
                timelineWindow.bossDisplayLabel:Hide()
                timelineWindow.bossDisplayDropdown:Hide()
            end
            NSI:RefreshTimelineForMode()
        end,
        true, 20, 20, nil, nil, nil, "BossAbilitiesToggle", nil, nil, nil, nil, options_switch_template)
    bossAbilitiesToggle:SetAsCheckBox()
    bossAbilitiesToggle:SetPoint("TOPRIGHT", timelineWindow, "TOPRIGHT", -15, -28)
    timelineWindow.bossAbilitiesToggle = bossAbilitiesToggle

    local bossAbilitiesLabel = DF:CreateLabel(timelineWindow, "Show Boss Abilities", 11, "white")
    bossAbilitiesLabel:SetPoint("RIGHT", bossAbilitiesToggle, "LEFT", -5, 0)

    -- Boss display mode dropdown
    local function BuildBossDisplayModeOptions()
        return {
            {
                label = "Important Healer",
                value = NSI.BossDisplayModes.IMPORTANT_HEALER,
                onclick = function(_, _, value)
                    timelineWindow.bossDisplayMode = value
                    NSI:RefreshTimelineForMode()
                end
            },
            {
                label = "Important Tank",
                value = NSI.BossDisplayModes.IMPORTANT_TANK,
                onclick = function(_, _, value)
                    timelineWindow.bossDisplayMode = value
                    NSI:RefreshTimelineForMode()
                end
            },
            {
                label = "Show All",
                value = NSI.BossDisplayModes.SHOW_ALL,
                onclick = function(_, _, value)
                    timelineWindow.bossDisplayMode = value
                    NSI:RefreshTimelineForMode()
                end
            },
            {
                label = "Combined",
                value = NSI.BossDisplayModes.COMBINED,
                onclick = function(_, _, value)
                    timelineWindow.bossDisplayMode = value
                    NSI:RefreshTimelineForMode()
                end
            },
            {
                label = "Combined Important",
                value = NSI.BossDisplayModes.COMBINED_IMPORTANT,
                onclick = function(_, _, value)
                    timelineWindow.bossDisplayMode = value
                    NSI:RefreshTimelineForMode()
                end
            },
        }
    end

    local bossDisplayDropdown = DF:CreateDropDown(timelineWindow, BuildBossDisplayModeOptions, NSI.BossDisplayModes.IMPORTANT_HEALER, 150)
    bossDisplayDropdown:SetTemplate(options_dropdown_template)
    bossDisplayDropdown:SetPoint("RIGHT", bossAbilitiesLabel, "LEFT", -20, 0)
    timelineWindow.bossDisplayDropdown = bossDisplayDropdown

    local bossDisplayLabel = DF:CreateLabel(timelineWindow, "Boss Display:", 11, "white")
    bossDisplayLabel:SetPoint("RIGHT", bossDisplayDropdown, "LEFT", -5, 0)
    timelineWindow.bossDisplayLabel = bossDisplayLabel

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
        line_height = 20,
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
            -- Separator rows stay black, don't highlight
            if line.lineData and line.lineData.isSeparator then
                return
            end
            line:SetBackdropColor(unpack(line.backdrop_color_highlight))
        end,
        on_leave = function(line)
            -- Separator rows always black
            if line.lineData and line.lineData.isSeparator then
                line:SetBackdropColor(0, 0, 0, 1)
                return
            end
            -- Restore alternating row color based on index
            local idx = line.dataIndex or 0
            if idx % 2 == 1 then
                line:SetBackdropColor(0, 0, 0, 0)
            else
                line:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            end
        end,

        -- Called when a line is refreshed with new data
        on_refresh_line = function(line)
            -- Set separator rows to black background
            if line.lineData and line.lineData.isSeparator then
                line:SetBackdropColor(0, 0, 0, 1)
            end

            -- Update custom right-side icons
            if line.lineHeader then
                local data = line.lineData

                -- Check line types
                local isPlayerAssignment = data and data.isPlayerAssignment
                local isYourReminder = data and data.isYourReminder
                local isBossAbility = data and data.isBossAbility

                -- Update custom header text (left-anchored)
                if line.lineHeader.headerText then
                    if data and data.text then
                        line.lineHeader.headerText:SetText(data.text)
                        -- Adjust text width based on line type
                        if isPlayerAssignment then
                            line.lineHeader.headerText:SetWidth(90) -- Narrower for player assignments (name + icon)
                        elseif isYourReminder then
                            line.lineHeader.headerText:SetWidth(140) -- Wider for your reminders (just icon on right)
                        else
                            line.lineHeader.headerText:SetWidth(120) -- Boss abilities (icons on right)
                        end
                        line.lineHeader.headerText:Show()
                    else
                        line.lineHeader.headerText:Hide()
                    end
                end

                -- Boss ability icons (only show for boss abilities)
                if line.lineHeader.bossIcon then
                    if isBossAbility and data.bossIcon then
                        line.lineHeader.bossIcon:SetTexture(data.bossIcon)
                        line.lineHeader.bossIcon:Show()
                    else
                        line.lineHeader.bossIcon:Hide()
                    end
                end

                -- Role icons (only for boss abilities)
                if line.lineHeader.tankIcon then
                    if isBossAbility and data.isImportantTank then
                        line.lineHeader.tankIcon:Show()
                    else
                        line.lineHeader.tankIcon:Hide()
                    end
                end

                if line.lineHeader.healerIcon then
                    if isBossAbility and data.isImportantHealer then
                        line.lineHeader.healerIcon:Show()
                    else
                        line.lineHeader.healerIcon:Hide()
                    end
                end

                -- Player/reminder spell icon (for player assignments and your reminders)
                if line.lineHeader.playerSpellIcon then
                    if isPlayerAssignment and data.playerSpellIcon then
                        line.lineHeader.playerSpellIcon:SetTexture(data.playerSpellIcon)
                        line.lineHeader.playerSpellIcon:Show()
                    elseif isYourReminder and data.reminderSpellIcon then
                        line.lineHeader.playerSpellIcon:SetTexture(data.reminderSpellIcon)
                        line.lineHeader.playerSpellIcon:Show()
                    else
                        line.lineHeader.playerSpellIcon:Hide()
                    end
                end

                -- Player name text (only for player assignments)
                if line.lineHeader.playerNameText then
                    if isPlayerAssignment and data.playerName then
                        local displayName = data.playerName
                        if data.playerClassColor then
                            displayName = "|c" .. data.playerClassColor .. data.playerName .. "|r"
                        end
                        line.lineHeader.playerNameText:SetText(displayName)
                        line.lineHeader.playerNameText:Show()
                    else
                        line.lineHeader.playerNameText:Hide()
                    end
                end
            end
        end,

        -- Called when a line is created - add tooltip to the header
        on_create_line = function(line)
            if line.lineHeader then
                line.lineHeader:EnableMouse(true)
                line.lineHeader:SetScript("OnEnter", function(self)
                    -- Separator rows stay black, don't highlight
                    if line.lineData and line.lineData.isSeparator then
                        return
                    end
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
                    -- Separator rows always black
                    if line.lineData and line.lineData.isSeparator then
                        line:SetBackdropColor(0, 0, 0, 1)
                        GameTooltip:Hide()
                        return
                    end
                    -- Restore alternating row color based on index
                    local idx = line.dataIndex or 0
                    if idx % 2 == 1 then
                        line:SetBackdropColor(0, 0, 0, 0)
                    else
                        line:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                    end
                    GameTooltip:Hide()
                end)

                -- Create boss spell icon (rightmost, right-anchored)
                local bossIcon = line.lineHeader:CreateTexture(nil, "OVERLAY")
                bossIcon:SetSize(18, 18)
                bossIcon:SetPoint("RIGHT", line.lineHeader, "RIGHT", -2, 0)
                bossIcon:Hide()
                line.lineHeader.bossIcon = bossIcon

                -- Create tank role icon (right next to boss icon)
                local tankIcon = line.lineHeader:CreateTexture(nil, "OVERLAY")
                tankIcon:SetSize(16, 16)
                tankIcon:SetPoint("RIGHT", bossIcon, "LEFT", 0, 0)
                tankIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                tankIcon:SetTexCoord(0/64, 19/64, 22/64, 41/64) -- Tank shield
                tankIcon:Hide()
                line.lineHeader.tankIcon = tankIcon

                -- Create healer role icon (right next to tank icon)
                local healerIcon = line.lineHeader:CreateTexture(nil, "OVERLAY")
                healerIcon:SetSize(16, 16)
                healerIcon:SetPoint("RIGHT", tankIcon, "LEFT", 0, 0)
                healerIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                healerIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64) -- Healer cross
                healerIcon:Hide()
                line.lineHeader.healerIcon = healerIcon

                -- Create player assignment spell icon (rightmost, right-anchored)
                local playerSpellIcon = line.lineHeader:CreateTexture(nil, "OVERLAY")
                playerSpellIcon:SetSize(18, 18)
                playerSpellIcon:SetPoint("RIGHT", line.lineHeader, "RIGHT", -2, 0)
                playerSpellIcon:Hide()
                line.lineHeader.playerSpellIcon = playerSpellIcon

                -- Create player name text (to the left of player spell icon)
                local playerNameText = line.lineHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                playerNameText:SetPoint("RIGHT", playerSpellIcon, "LEFT", -4, 0)
                playerNameText:SetJustifyH("RIGHT")
                playerNameText:Hide()
                line.lineHeader.playerNameText = playerNameText

                -- Create custom header text (left-anchored, like the icons)
                -- We don't use line.text because it's parented to the timeline body, not the header
                local headerText = line.lineHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                headerText:SetPoint("LEFT", line.lineHeader, "LEFT", 4, 0)
                headerText:SetJustifyH("LEFT")
                headerText:SetWordWrap(false)
                headerText:SetWidth(120) -- Default for boss abilities
                line.lineHeader.headerText = headerText
            end
            -- Hide the default line.text since it's parented to the timeline body and scrolls incorrectly
            if line.text then
                line.text:Hide()
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

                -- For combined mode, use the ability name from payload
                if block.blockData and block.blockData.payload and block.blockData.payload.abilityName then
                    spellName = block.blockData.payload.abilityName
                end

                GameTooltip:AddLine(spellName ~= "" and spellName or "Reminder", 1, 1, 1)
                GameTooltip:AddLine("Time: " .. timeStr, 0.7, 0.7, 0.7)
                -- Duration is stored at position [4] in the block data (auraDuration)
                local duration = block.blockData and tonumber(block.blockData[4]) or 0
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
                    if payload.glowUnit then
                        GameTooltip:AddLine("Glow Unit: " .. payload.glowUnit, 1, 1, 0)
                    end
                end
                GameTooltip:Show()
            end
        end,
        block_on_leave = function(block)
            GameTooltip:Hide()
        end,

        -- Called when block data is set - add category-colored border and duration bar
        block_on_set_data = function(block, data)
            if not block or not data then return end

            local payload = data.payload

            -- Hide category borders if this is not a boss ability (blocks are reused)
            if not payload or not payload.isBossAbility then
                if block.categoryBorderTop then
                    block.categoryBorderTop:Hide()
                    block.categoryBorderBottom:Hide()
                    block.categoryBorderLeft:Hide()
                    block.categoryBorderRight:Hide()
                end
                -- Reset icon size to default
                if block.icon then
                    block.icon:SetSize(20, 20)
                end
                return
            end

            -- Get category color from BossTimelineColors
            local category = payload.category
            local color = nil
            if category and NSI.BossTimelineColors then
                -- Parse first category keyword
                local firstCategory = category:match("([^,]+)")
                if firstCategory then
                    firstCategory = strtrim(firstCategory):lower()
                    color = NSI.BossTimelineColors[firstCategory]
                end
            end

            if not color then return end

            -- Scale down icon and create border around it (4 edge textures)
            if block.icon then
                local borderSize = 1
                local iconSize = 18  -- 20px row - 1px border top - 1px border bottom = 18px

                -- Scale down the icon to make room for border
                block.icon:SetSize(iconSize, iconSize)

                if not block.categoryBorderTop then
                    -- Top edge
                    block.categoryBorderTop = block:CreateTexture(nil, "ARTWORK")
                    block.categoryBorderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
                    block.categoryBorderTop:SetHeight(borderSize)
                    -- Bottom edge
                    block.categoryBorderBottom = block:CreateTexture(nil, "ARTWORK")
                    block.categoryBorderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
                    block.categoryBorderBottom:SetHeight(borderSize)
                    -- Left edge
                    block.categoryBorderLeft = block:CreateTexture(nil, "ARTWORK")
                    block.categoryBorderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
                    block.categoryBorderLeft:SetWidth(borderSize)
                    -- Right edge
                    block.categoryBorderRight = block:CreateTexture(nil, "ARTWORK")
                    block.categoryBorderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
                    block.categoryBorderRight:SetWidth(borderSize)
                end

                -- Position borders around the scaled icon
                block.categoryBorderTop:ClearAllPoints()
                block.categoryBorderTop:SetPoint("BOTTOMLEFT", block.icon, "TOPLEFT", -borderSize, 0)
                block.categoryBorderTop:SetPoint("BOTTOMRIGHT", block.icon, "TOPRIGHT", borderSize, 0)
                block.categoryBorderBottom:ClearAllPoints()
                block.categoryBorderBottom:SetPoint("TOPLEFT", block.icon, "BOTTOMLEFT", -borderSize, 0)
                block.categoryBorderBottom:SetPoint("TOPRIGHT", block.icon, "BOTTOMRIGHT", borderSize, 0)
                block.categoryBorderLeft:ClearAllPoints()
                block.categoryBorderLeft:SetPoint("TOPRIGHT", block.icon, "TOPLEFT", 0, borderSize)
                block.categoryBorderLeft:SetPoint("BOTTOMRIGHT", block.icon, "BOTTOMLEFT", 0, -borderSize)
                block.categoryBorderRight:ClearAllPoints()
                block.categoryBorderRight:SetPoint("TOPLEFT", block.icon, "TOPRIGHT", 0, borderSize)
                block.categoryBorderRight:SetPoint("BOTTOMLEFT", block.icon, "BOTTOMRIGHT", 0, -borderSize)

                block.categoryBorderTop:SetVertexColor(color[1], color[2], color[3], 1)
                block.categoryBorderBottom:SetVertexColor(color[1], color[2], color[3], 1)
                block.categoryBorderLeft:SetVertexColor(color[1], color[2], color[3], 1)
                block.categoryBorderRight:SetVertexColor(color[1], color[2], color[3], 1)
                block.categoryBorderTop:Show()
                block.categoryBorderBottom:Show()
                block.categoryBorderLeft:Show()
                block.categoryBorderRight:Show()
            end

            -- Color the duration bar if it exists
            if block.blockLength and block.blockLength.Texture then
                block.blockLength.Texture:SetVertexColor(color[1], color[2], color[3], 0.7)
            end
        end,
    }

    -- Elapsed time options for the ruler and vertical grid lines
    local elapsedTimeOptions = {
        draw_line_color = {0.6, 0.6, 0.6, 0.8}, -- Consistent grey lines on both light and dark backgrounds
    }

    local timelineFrame = DF:CreateTimeLineFrame(timelineWindow, "$parentTimeLine", timelineOptions, elapsedTimeOptions)
    timelineWindow.timeline = timelineFrame

    -- Create an overlay frame for grid lines that draws on top of rows
    local gridOverlay = CreateFrame("Frame", nil, timelineFrame.body)
    gridOverlay:SetAllPoints(timelineFrame.body)
    gridOverlay:SetFrameLevel(timelineFrame.body:GetFrameLevel() + 100)
    timelineFrame.gridOverlay = gridOverlay
    timelineFrame.gridLines = {}

    -- Hide the default elapsed time lines
    if timelineFrame.elapsedTimeFrame and timelineFrame.elapsedTimeFrame.options then
        timelineFrame.elapsedTimeFrame.options.draw_line = false
    end

    -- Override refresh to show labels every 30 seconds instead of pixel-distance-based
    if timelineFrame.elapsedTimeFrame then
        timelineFrame.elapsedTimeFrame.Refresh = function(self, elapsedTime, scale)
            if not elapsedTime then return end

            self:SetHeight(self.options.height)

            local pixelsPerSecond = timelineFrame.options.pixels_per_second or 15
            local currentScale = scale or 1
            local scaledPixelsPerSecond = pixelsPerSecond * currentScale

            -- Show a label every 30 seconds
            local intervalSeconds = 30
            local intervalPixels = intervalSeconds * scaledPixelsPerSecond

            -- Calculate how many 30-second marks fit in the timeline
            local amountSegments = math.ceil(elapsedTime / intervalSeconds) + 1

            for i = 1, amountSegments do
                local label = self:GetLabel(i)
                local timeSeconds = (i - 1) * intervalSeconds
                local xOffset = timeSeconds * scaledPixelsPerSecond

                label:ClearAllPoints()
                label:SetPoint("LEFT", self, "LEFT", xOffset, 0)

                -- Format as M:SS
                local minutes = math.floor(timeSeconds / 60)
                local seconds = timeSeconds % 60
                label:SetText(string.format("%d:%02d", minutes, seconds))

                -- Hide the default line (we use gridOverlay instead)
                if label.line then
                    label.line:Hide()
                end

                label:Show()

                -- Create/update grid line on overlay
                local gridLine = timelineFrame.gridLines[i]
                if not gridLine then
                    gridLine = gridOverlay:CreateTexture(nil, "OVERLAY")
                    gridLine:SetColorTexture(1, 1, 1, 0.15)
                    gridLine:SetWidth(1)
                    timelineFrame.gridLines[i] = gridLine
                end
                gridLine:ClearAllPoints()
                gridLine:SetPoint("TOP", label, "BOTTOM", 0, -2)
                gridLine:SetPoint("BOTTOM", gridOverlay, "BOTTOM", 0, 0)
                gridLine:Show()
            end

            -- Hide extra labels and lines
            for i = amountSegments + 1, #self.labels do
                self.labels[i]:Hide()
                if self.labels[i].line then
                    self.labels[i].line:Hide()
                end
            end
            for i = amountSegments + 1, #timelineFrame.gridLines do
                if timelineFrame.gridLines[i] then
                    timelineFrame.gridLines[i]:Hide()
                end
            end
        end
    end

    -- Create cursor line that follows mouse and shows time
    local cursorLine = CreateFrame("Frame", nil, timelineFrame.body, "BackdropTemplate")
    cursorLine:SetWidth(1)
    cursorLine:SetFrameLevel(timelineFrame.body:GetFrameLevel() + 150)
    cursorLine:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    cursorLine:SetBackdropColor(1, 1, 0, 0.8)  -- Yellow cursor line
    cursorLine:Hide()
    timelineFrame.cursorLine = cursorLine

    -- Time label for cursor
    local cursorTimeLabel = cursorLine:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cursorTimeLabel:SetPoint("BOTTOM", cursorLine, "TOP", 0, 2)
    cursorTimeLabel:SetTextColor(1, 1, 0.7, 1)
    timelineFrame.cursorTimeLabel = cursorTimeLabel

    -- Background for time label for better readability
    local cursorTimeBg = cursorLine:CreateTexture(nil, "BACKGROUND")
    cursorTimeBg:SetColorTexture(0, 0, 0, 0.7)
    cursorTimeBg:SetPoint("TOPLEFT", cursorTimeLabel, "TOPLEFT", -3, 2)
    cursorTimeBg:SetPoint("BOTTOMRIGHT", cursorTimeLabel, "BOTTOMRIGHT", 3, -1)
    timelineFrame.cursorTimeBg = cursorTimeBg

    -- Update cursor position based on mouse
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

        -- Check if cursor is within timeline body bounds
        if cursorX >= bodyLeft and cursorX <= bodyRight and cursorY >= bodyBottom and cursorY <= bodyTop then
            local mouseXInBody = cursorX - bodyLeft
            local scrollX = timelineFrame.horizontalSlider and timelineFrame.horizontalSlider:GetValue() or 0
            local pixelsPerSecond = timelineFrame.options.pixels_per_second or 15
            local currentScale = timelineFrame.currentScale or 1

            -- Calculate time at cursor position
            local timeAtCursor = (scrollX + mouseXInBody) / (pixelsPerSecond * currentScale)

            -- Format time as M:SS
            local minutes = math.floor(timeAtCursor / 60)
            local seconds = math.floor(timeAtCursor % 60)
            cursorTimeLabel:SetText(string.format("%d:%02d", minutes, seconds))

            -- Position cursor line
            local elapsedHeight = timelineFrame.options.elapsed_timeline_height or 20
            cursorLine:ClearAllPoints()
            cursorLine:SetPoint("TOP", timelineFrame.body, "TOPLEFT", mouseXInBody, -elapsedHeight)
            cursorLine:SetPoint("BOTTOM", timelineFrame.body, "BOTTOMLEFT", mouseXInBody, 0)
            cursorLine:Show()
        else
            cursorLine:Hide()
        end
    end

    -- Enable mouse tracking on the timeline body
    timelineFrame.body:EnableMouse(true)
    timelineFrame.body:SetScript("OnEnter", function()
        cursorLine:Show()
    end)
    timelineFrame.body:SetScript("OnLeave", function()
        cursorLine:Hide()
    end)

    -- Use OnUpdate for smooth cursor tracking
    local updateThrottle = 0
    timelineFrame.body:SetScript("OnUpdate", function(self, elapsed)
        updateThrottle = updateThrottle + elapsed
        if updateThrottle >= 0.016 then  -- ~60fps
            updateThrottle = 0
            if self:IsMouseOver() then
                updateCursorLine()
            end
        end
    end)

    -- Setup zoom-to-cursor and sticky ruler hooks
    self:SetupTimelineHooks(timelineFrame)

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

    -- Handle window resize to update timeline dimensions
    local resizeTimer = nil
    timelineWindow:SetScript("OnSizeChanged", function(self, width, height)
        local header_width = 180
        local newTimelineWidth = width - 40 - header_width
        local newTimelineHeight = height - 130

        -- Update timeline frame size
        if timelineFrame then
            timelineFrame:SetSize(newTimelineWidth, newTimelineHeight)
            if timelineFrame.body then
                timelineFrame.body:SetSize(newTimelineWidth, newTimelineHeight)
            end

            -- Update horizontal slider width (position slider)
            if timelineFrame.horizontalSlider then
                timelineFrame.horizontalSlider:SetWidth(newTimelineWidth + 20)
            end

            -- Update scale slider width (stacked below horizontal slider)
            if timelineFrame.scaleSlider then
                timelineFrame.scaleSlider:SetWidth(newTimelineWidth + 20)
            end

            -- Update vertical slider height
            if timelineFrame.verticalSlider then
                timelineFrame.verticalSlider:SetHeight(newTimelineHeight) -- Account for elapsed time header and bottom sliders
            end
        end

        -- Update header frame height
        if timelineFrame.headerFrame then
            timelineFrame.headerFrame:SetHeight(newTimelineHeight)
        end

        -- Debounce the refresh - only refresh after resizing stops
        if resizeTimer then
            resizeTimer:Cancel()
        end
        resizeTimer = C_Timer.NewTimer(0.1, function()
            NSI:RefreshTimelineForMode()
            resizeTimer = nil
        end)
    end)
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

-- Auto-fit timeline scale to show full duration (up to 600 seconds max)
function NSI:AutoFitTimelineScale(timeline, dataLength)
    if not timeline then return end

    local maxVisibleDuration = 600  -- 10 minutes max
    local targetDuration = math.min(dataLength or 300, maxVisibleDuration)

    local visibleWidth = timeline:GetWidth() or 880
    local pixelsPerSecond = timeline.options.pixels_per_second or 15
    local scaleMax = timeline.options.scale_max or 2.0

    -- Calculate scale needed to fit target duration in visible width
    local requiredScale = visibleWidth / (targetDuration * pixelsPerSecond)

    -- Dynamic scale_min: the scale needed to show the boss duration (or 600s max)
    local dynamicScaleMin = requiredScale

    -- Clamp to valid range
    requiredScale = math.max(dynamicScaleMin, math.min(scaleMax, requiredScale))

    -- Update the slider's min value so user can't zoom out further than needed
    if timeline.scaleSlider then
        timeline.scaleSlider:SetMinMaxValues(dynamicScaleMin, scaleMax)
        timeline.scaleSlider:SetValue(requiredScale)
    end

    -- Set the scale
    timeline.currentScale = requiredScale

    -- Reset horizontal scroll to start
    if timeline.horizontalSlider then
        timeline.horizontalSlider:SetValue(0)
    end
end

-- Refresh timeline with player's own processed reminders (My Reminders mode)
function NSI:RefreshMyRemindersTimeline()
    if not self.TimelineWindow or not self.TimelineWindow.timeline then return end

    local includeBossAbilities = self.TimelineWindow.showBossAbilities
    local bossDisplayMode = self.TimelineWindow.bossDisplayMode or self.BossDisplayModes.SHOW_ALL
    local data, encID, phases, difficulty = self:GetMyTimelineData(includeBossAbilities, bossDisplayMode)

    if data and data.lines and #data.lines > 0 then
        self.TimelineWindow.noDataLabel:Hide()
        self.TimelineWindow.timeline:Show()
        self.TimelineWindow.timeline:SetData(data)
        self:AutoFitTimelineScale(self.TimelineWindow.timeline, data.length)
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
                local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(bossEncID, bossDisplayMode, fallbackDifficulty)
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
                    self:AutoFitTimelineScale(self.TimelineWindow.timeline, bossData.length)
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
    local bossDisplayMode = self.TimelineWindow.bossDisplayMode or self.BossDisplayModes.SHOW_ALL
    local data, encID, phases, difficulty = self:GetAllTimelineData(reminderName, personal, includeBossAbilities, bossDisplayMode)

    if data and data.lines and #data.lines > 0 then
        self.TimelineWindow.noDataLabel:Hide()
        self.TimelineWindow.timeline:Show()
        self.TimelineWindow.timeline:SetData(data)
        self:AutoFitTimelineScale(self.TimelineWindow.timeline, data.length)
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
                marker:SetSize(2, body:GetHeight() - elapsedHeight)
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
            marker:SetBackdropColor(color[1], color[2], color[3], 0.5)

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
    local bossDisplayMode = tab.bossDisplayMode or self.BossDisplayModes.SHOW_ALL
    local data, encID, phases, difficulty = self:GetMyTimelineData(includeBossAbilities, bossDisplayMode)

    if data and data.lines and #data.lines > 0 then
        tab.noDataLabel:Hide()
        tab.timeline:Show()
        tab.timeline:SetData(data)
        self:AutoFitTimelineScale(tab.timeline, data.length)
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
                local bossLines, bossMaxTime, bossPhases, bossDifficulty = self:GetBossAbilityLines(bossEncID, bossDisplayMode, fallbackDifficulty)
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
                    self:AutoFitTimelineScale(tab.timeline, bossData.length)
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
    local bossDisplayMode = tab.bossDisplayMode or self.BossDisplayModes.SHOW_ALL
    local data, encID, phases, difficulty = self:GetAllTimelineData(reminderName, personal, includeBossAbilities, bossDisplayMode)

    if data and data.lines and #data.lines > 0 then
        tab.noDataLabel:Hide()
        tab.timeline:Show()
        tab.timeline:SetData(data)
        self:AutoFitTimelineScale(tab.timeline, data.length)
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
                marker:SetSize(2, body:GetHeight() - elapsedHeight)
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
            marker:SetBackdropColor(color[1], color[2], color[3], 0.5)

            marker:ClearAllPoints()
            marker:SetPoint("TOPLEFT", body, "TOPLEFT", xPos, -elapsedHeight)
            marker:SetHeight(body:GetHeight() - elapsedHeight)
            marker:SetFrameLevel(body:GetFrameLevel() + 10)
            marker:Show()

            marker.encID = encID
        end
    end
end
