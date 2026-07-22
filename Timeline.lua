local _, NSI = ... -- Internal namespace

local DF = _G["DetailsFramework"]

-- Setup timeline hooks for zoom-to-cursor and sticky ruler
-- Call this after creating a timeline with DF:CreateTimeLineFrame
function NSI:SetupTimelineHooks(timeline)
    if not timeline then return end

    local horizontalSlider = timeline.horizontalSlider
    local scaleSlider = timeline.scaleSlider
    local elapsedTimeFrame = timeline.elapsedTimeFrame

    -- Override mousewheel: scroll = zoom-to-cursor, shift+scroll = vertical pan
    if scaleSlider and horizontalSlider then
        -- Storage for pre-zoom state
        timeline.preZoomState = {}

        timeline:SetScript("OnMouseWheel", function(self, delta)
            if IsControlKeyDown() then
                -- Vertical scroll. verticalSlider's units are raw content pixels
                -- (SetMinMaxValues(0, bodyHeight - visibleHeight) in the DF timeline
                -- lib), so scroll by whole rows rather than a flat pixel count or it
                -- feels far slower than a normal list/scrollframe.
                if timeline.verticalSlider then
                    local rowHeight = (timeline.options.line_height or 20) + (timeline.options.line_padding or 0)
                    local cur = timeline.verticalSlider:GetValue()
                    local vMin, vMax = timeline.verticalSlider:GetMinMaxValues()
                    timeline.verticalSlider:SetValue(math.max(vMin, math.min(vMax, cur - delta * rowHeight * 3)))
                end
                return
            end

            -- Zoom to cursor (always, no modifier needed)
            local pixelPerSecond = timeline.options.pixels_per_second or 15
            local currentScale = timeline.currentScale or 1

            local cursorX = GetCursorPosition()
            -- Use this timeline frame's own effective scale, not UIParent's — the
            -- timeline window has an adjustable scale bar, so the two can differ.
            local uiScale = 1 / timeline:GetEffectiveScale()
            cursorX = cursorX * uiScale
            local frameLeft = timeline:GetLeft() or 0
            local mouseXInFrame = cursorX - frameLeft
            local scrollPosition = horizontalSlider:GetValue()
            local timeUnderMouse = (scrollPosition + mouseXInFrame) / (pixelPerSecond * currentScale)

            timeline.preZoomState.timeUnderMouse = timeUnderMouse
            timeline.preZoomState.mouseXInFrame = mouseXInFrame
            timeline.preZoomState.pixelPerSecond = pixelPerSecond

            local sMin, sMax = scaleSlider:GetMinMaxValues()
            local newScale = math.max(sMin, math.min(sMax, currentScale * (delta > 0 and 1.15 or (1 / 1.15))))
            scaleSlider:SetValue(newScale)
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

-- Return the phase number and its absolute start time for a given absolute time.
-- Picks the greatest phase start <= absoluteTime.
function NSI:PhaseFromTime(encID, absoluteTime, difficulty)
    local bestPhase = 1
    local bestStart = 0
    if encID then
        local timeline = self:GetBossTimeline(encID, difficulty)
        if timeline and timeline.phases then
            for ph, _ in pairs(timeline.phases) do
                local phStart = self:GetPhaseStart(encID, ph, difficulty)
                if phStart <= absoluteTime and phStart >= bestStart then
                    bestStart = phStart
                    bestPhase = ph
                end
            end
        end
    end
    return bestPhase, bestStart
end

-- Replace a single raw line in a reminder string (personal or shared) by its 1-based index.
-- Falls back to searching by srcRaw content if the line has shifted.
function NSI:RewriteNoteLine(name, personal, srcLineIndex, srcRaw, newRaw)
    local source = personal and NSRT.PersonalReminders or NSRT.Reminders
    local str = source[name]
    if not str then return end
    local lines = {}
    for line in str:gmatch('[^\r\n]+') do
        table.insert(lines, line)
    end
    -- Verify index; fall back to content search
    if lines[srcLineIndex] ~= srcRaw then
        for i, l in ipairs(lines) do
            if l == srcRaw then
                srcLineIndex = i
                break
            end
        end
    end
    if lines[srcLineIndex] ~= srcRaw then return end  -- not found
    lines[srcLineIndex] = newRaw
    local newStr = table.concat(lines, "\n") .. "\n"
    self:ImportReminder(name, newStr, false, personal, true)
end

-- Remove a raw line from a reminder string by its 1-based index.
function NSI:DeleteNoteLine(name, personal, srcLineIndex, srcRaw)
    local source = personal and NSRT.PersonalReminders or NSRT.Reminders
    local str = source[name]
    if not str then return end
    local lines = {}
    for line in str:gmatch('[^\r\n]+') do table.insert(lines, line) end
    if lines[srcLineIndex] ~= srcRaw then
        for i, l in ipairs(lines) do
            if l == srcRaw then srcLineIndex = i; break end
        end
    end
    if lines[srcLineIndex] ~= srcRaw then return end
    table.remove(lines, srcLineIndex)
    local newStr = #lines > 0 and (table.concat(lines, "\n") .. "\n") or ""
    self:ImportReminder(name, newStr, false, personal, true)
end

-- Append a new raw line to a reminder string.
function NSI:AppendNoteLine(name, personal, newLine)
    local source = personal and NSRT.PersonalReminders or NSRT.Reminders
    local str = source[name]
    if not str then return end
    if not str:match('\n$') then str = str .. '\n' end
    self:ImportReminder(name, str .. newLine .. "\n", false, personal, true)
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

    local srcLineIndex = 0
    for line in reminderStr:gmatch('[^\r\n]+') do
        srcLineIndex = srcLineIndex + 1
        local tag = line:match("tag:([^;]+)")
        local time = line:match("time:(%d*%.?%d+)")
        local spellID = line:match("spellid:(%d+)")
        local dur = line:match("dur:(%d+)")
        local text = line:match("text:([^;]+)")
        local phase = line:match("ph:(%d*%.?%d+)") or "1"
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
                        srcLineIndex = srcLineIndex,
                        srcRaw = line,
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
                    payload = {
                        phase = entry.phase, text = entry.text, glowUnit = entry.glowUnit,
                        srcLineIndex = entry.srcLineIndex, srcRaw = entry.srcRaw,
                    },
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
                    timelineWindow.editNoteLabel:Show()
                    timelineWindow.editNoteButton.frame:Show()
                    if timelineWindow.playButton then timelineWindow.playButton:Show() end
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
                    timelineWindow.editNoteLabel:Hide()
                    timelineWindow.editNoteButton.frame:Hide()
                    timelineWindow.editable = false
                    timelineWindow.editNote = nil
                    if timelineWindow.playButton then
                            -- Stop preview and hide play button in "All Reminders" mode
                        if timelineWindow.previewActive then
                            timelineWindow.previewActive = false
                            timelineWindow.previewStartTime = nil
                            if timelineWindow.timeline and timelineWindow.timeline.previewLine then
                                timelineWindow.timeline.previewLine:Hide()
                            end
                            NSI:HideAllReminders()
                            timelineWindow.playButton.text = "Play Preview"
                            timelineWindow.playButton:SetIcon(NSI.LSM:Fetch("statusbar", "play_icon"), 14, 14, "OVERLAY", nil, {0, 1, 0, 1})
                        end
                        timelineWindow.playButton:Hide()
                    end
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

    -- Edit mode state: which personal note is being edited
    timelineWindow.editable = false
    timelineWindow.editNote = nil  -- {name, personal=true}

    local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")
    local playColor = { 20 / 255, 245 / 255, 87 / 255, 1 } -- {r,g,b,a}
    local stopColor = { 247 / 255, 32 / 255, 61 / 255, 1 } -- {r,g,b,a}
    local playButton = DF:CreateButton(timelineWindow, function()
        if timelineWindow.previewActive then
            timelineWindow.previewActive = false
            timelineWindow.previewStartTime = nil
            if timelineWindow.timeline and timelineWindow.timeline.previewLine then
                timelineWindow.timeline.previewLine:Hide()
            end
            NSI:HideAllReminders()
            timelineWindow.playButton.text = "Play Preview"
            timelineWindow.playButton:SetIcon("Interface\\AddOns\\NorthernSkyRaidTools\\Media\\Icons\\play_icon.png", 14,
                14, "OVERLAY", { 0.1, 0.9, 0.09, 0.91 }, playColor)
        else
            if not NSI.ProcessedReminder then NSI:ProcessReminder() end
            if not NSI.ProcessedReminder then return end
            timelineWindow.previewActive = true
            timelineWindow.previewStartTime = GetTime()
            NSI:StartReminders(1, true)
            timelineWindow.playButton.text = "Stop Preview"
            timelineWindow.playButton:SetIcon("Interface\\AddOns\\NorthernSkyRaidTools\\Media\\Icons\\stop_icon.png", 14,
                14, "OVERLAY", { 0.12, 0.88, 0.12, 0.88 }, stopColor)
        end
    end, 32, 22, "Play Preview")
    playButton:SetTemplate(options_button_template)
    playButton:SetIcon("Interface\\AddOns\\NorthernSkyRaidTools\\Media\\Icons\\play_icon.png", 14,
        14, "OVERLAY", { 0.1, 0.9, 0.09, 0.91 }, playColor)
    playButton:SetPoint("LEFT", modeDropdown, "RIGHT", 15, 0)
    timelineWindow.playButton = playButton

    -- "Edit Note" menu button - anchored right of the play button (created here so
    -- the anchor reference is valid; was previously created before playButton).
    local editNoteLabel = DF:CreateLabel(timelineWindow, "Edit Note:", 11, "white")
    editNoteLabel:SetPoint("LEFT", playButton, "RIGHT", 20, 0)
    timelineWindow.editNoteLabel = editNoteLabel
    editNoteLabel:Show()

    -- Menu-bar style picker: top level is "None (Read Only)" plus one entry per
    -- boss (every boss, not just ones that already have personal notes); hovering
    -- a boss opens its notes as a submenu (same nested-menu component used by the
    -- right-click context menus), with "+ New Note" always last in that submenu.
    local function BuildEditNoteMenuItems()
        local items = {}
        table.insert(items, {
            type = "button",
            label = "None (Read Only)",
            fnc = function()
                timelineWindow.editNote = nil
                timelineWindow.editable = false
                self:UpdateEditNoteButtonLabel(timelineWindow)
                self:RefreshTimelineForMode()
            end,
        })

        -- Group existing personal notes by boss (EncounterID tag), preserving
        -- encounter order; notes without an EncounterID are grouped under "Other".
        local personalList = self:GetAllReminderNames(true)
        local groups, groupOrder = {}, {}
        for _, data in ipairs(personalList) do
            local encID = data.hasencID and tonumber(data.hasencID) or nil
            local key = encID or "other"
            if not groups[key] then
                groups[key] = {
                    name = encID and (NSI.BossNames[encID] or ("Boss " .. encID)) or "Other",
                    order = data.order,
                    encID = encID,
                    notes = {},
                }
                table.insert(groupOrder, key)
            end
            table.insert(groups[key].notes, data)
        end

        -- Ensure every boss has a group (even with zero existing notes) so a note
        -- can always be created for it, in encounter order.
        for eid, order in pairs(NSI.EncounterOrder) do
            if not groups[eid] then
                groups[eid] = {
                    name = NSI.BossNames[eid] or ("Boss " .. eid),
                    order = order,
                    encID = eid,
                    notes = {},
                }
                table.insert(groupOrder, eid)
            end
        end

        table.sort(groupOrder, function(a, b) return groups[a].order < groups[b].order end)

        if #groupOrder > 0 then

            for _, key in ipairs(groupOrder) do
                local group = groups[key]
                local subItems = {}
                for _, data in ipairs(group.notes) do
                    table.insert(subItems, {
                        type = "button",
                        label = data.name,
                        fnc = function()
                            local value = {name = data.name, personal = true}
                            timelineWindow.editNote = value
                            timelineWindow.editable = true
                            self:SetReminder(value.name, true, true)
                            self:UpdateEditNoteButtonLabel(timelineWindow)
                            self:RefreshTimelineForMode()
                        end,
                        -- Right-click → Rename/Delete this note, without disturbing the
                        -- outer boss list (opens as its own nested level anchored to the row).
                        contextItems = {
                            {type = "button", label = "Rename", fnc = function()
                                NSI:ShowRenameNoteDialog(timelineWindow, data.name)
                            end},
                            {type = "button", label = "Delete", fnc = function()
                                NSI:ShowDeleteNoteConfirm(timelineWindow, data.name)
                            end},
                        },
                    })
                end
                if group.encID then
                    if #subItems > 0 then
                        table.insert(subItems, {type = "separator"})
                    end
                    table.insert(subItems, {
                        type = "button",
                        label = "+ New Note",
                        fnc = function()
                            local value = self:CreateNewPersonalBossNote(group.encID)
                            timelineWindow.editNote = value
                            timelineWindow.editable = true
                            self:UpdateEditNoteButtonLabel(timelineWindow)
                            self:RefreshTimelineForMode()
                        end,
                    })
                end

                if group.encID == 3176 then
                    items[#items + 1] = {
                        type  = "separator",
                        label = "Season 1 (Midnight) ",
                    }
                elseif group.encID == 3379 then
                    items[#items + 1] = {
                        type  = "separator",
                        label = "Season 2 (Midnight) ",
                    }
                end

                table.insert(items, {
                    type = "submenu",
                    label = group.name,
                    items = subItems,
                    icon = group.encID and NSI.UI.BossData.BossIcons and NSI.UI.BossData.BossIcons[group.encID],
                })
            end
        end

        return items
    end

    -- Styled with the shared UI component (same cyan hover-fade as CreateDropdown)
    -- instead of the DF button template, so it visually reads as a dropdown trigger.
    local editNoteButton = NSI.UI.Components.CreateButton(
        timelineWindow, "None (Read Only)",
        function(self)
            NSI.UI.Components.ShowContextMenuAtFrame(BuildEditNoteMenuItems(), self.frame, 250)
        end,
        250, 22, "NSUITimelineEditNoteBtn"
    )
    -- editNoteLabel is a DF wrapper table, not a raw frame; anchor to its .widget
    -- (the underlying FontString) since the component button's SetPoint calls the
    -- native frame API directly and can't unwrap DF objects like DF's own SetPoint does.
    editNoteButton:SetPoint("LEFT", editNoteLabel.widget, "RIGHT", 5, 0)
    timelineWindow.editNoteButton = editNoteButton

    -- Small chevron on the right edge signals this button opens a dropdown-style menu.
    local editNoteArrow = editNoteButton.frame:CreateTexture(nil, "OVERLAY")
    editNoteArrow:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]])
    editNoteArrow:SetSize(10, 10)
    editNoteArrow:SetPoint("RIGHT", editNoteButton.frame, "RIGHT", -6, 0)
    timelineWindow.editNoteArrow = editNoteArrow

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
            if timelineWindow.draggingBlock then return end  -- suppress during drag
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

            -- Wire up drag-to-retime and right-click-add for personal-note blocks.
            -- Guard: install once per block (blocks are pooled and reused).
            if payload and payload.srcLineIndex and not block._dragHooksInstalled then
                block._dragHooksInstalled = true
                block:EnableMouse(true)

                block:HookScript("OnMouseDown", function(self, button)
                    if button == "LeftButton" then
                        self._clickStartX, self._clickStartY = GetCursorPosition()
                        if timelineWindow.editNote then
                            timelineWindow.draggingBlock = self
                        end
                    elseif button == "RightButton" then
                        timelineWindow.blockRightClickRawX, timelineWindow.blockRightClickRawY = GetCursorPosition()
                    end
                end)

                block:HookScript("OnMouseUp", function(self, button)
                    if button == "LeftButton" then
                        local wasDragging = timelineWindow.draggingBlock == self
                        -- Detect click vs drag by movement distance
                        local isClick = false
                        if self._clickStartX then
                            local curX, curY = GetCursorPosition()
                            local ddx = curX - self._clickStartX
                            local ddy = curY - self._clickStartY
                            isClick = math.sqrt(ddx * ddx + ddy * ddy) < 4
                            self._clickStartX = nil
                        end

                        if wasDragging then
                            timelineWindow.draggingBlock = nil
                            local tl = timelineWindow.timeline
                            if tl and tl.dragGhostLine then tl.dragGhostLine:Hide() end
                            if tl and tl.dragGhostIcon then tl.dragGhostIcon:Hide() end
                            if isClick then
                                -- Minimal movement → open edit dialog instead of retiming
                                local bd = self.blockData
                                if bd and bd.payload and bd.payload.srcLineIndex then
                                    NSI:ShowReminderDialog(timelineWindow, nil, self)
                                end
                            else
                                -- Recalculate snapped time live at release so any zoom/scroll changes
                                -- during the drag are reflected — using _lastSnappedTime risks stale pps/scrollX.
                                timelineWindow._lastSnappedTime = nil
                                local uiScale = 1 / timelineWindow:GetEffectiveScale()
                                local cursorX = GetCursorPosition() * uiScale
                                local bodyLeft = tl and (tl.body:GetLeft() or 0) or 0
                                -- tl.body is the scroll CHILD, not the viewport — its GetLeft() already
                                -- shifts with scroll, so scrollX must NOT be added again here.
                                local pps = tl and ((tl.options.pixels_per_second or 15) * (tl.currentScale or 1)) or 15
                                local newAbsoluteTime = math.max(0, math.floor((cursorX - bodyLeft) / pps + 0.5))
                                local encID = timelineWindow.currentEncounterID
                                local difficulty = timelineWindow.currentDifficulty
                                local phase, phaseStart = NSI:PhaseFromTime(encID, newAbsoluteTime, difficulty)
                                local newRelTime = math.max(0, newAbsoluteTime - phaseStart)
                                local bd = self.blockData
                                if bd and bd.payload and bd.payload.srcLineIndex and timelineWindow.editNote then
                                    local p = bd.payload
                                    local newRaw = p.srcRaw:gsub("time:[%d%.]+", "time:" .. newRelTime)
                                    newRaw = newRaw:gsub("ph:%d+", "ph:" .. phase)
                                    NSI:RewriteNoteLine(timelineWindow.editNote.name, true, p.srcLineIndex, p.srcRaw, newRaw)
                                    -- Must be set BEFORE SetReminder: with skipupdate=false, SetReminder
                                    -- calls ProcessReminder(), which itself refreshes the timeline
                                    -- immediately if it's shown — so the flag has to already be in
                                    -- place or that first refresh resets the zoom before we get here.
                                    timelineWindow.preserveZoom = true
                                    NSI:SetReminder(timelineWindow.editNote.name, true, false)
                                end
                            end
                        elseif isClick then
                            -- Not in edit mode but clicked a reminder block → open edit/view dialog
                            local bd = self.blockData
                            if bd and bd.payload and bd.payload.srcLineIndex then
                                NSI:ShowReminderDialog(timelineWindow, nil, self)
                            end
                        end
                    elseif button == "RightButton" and timelineWindow.blockRightClickRawX then
                        local curRawX, curRawY = GetCursorPosition()
                        local dx = curRawX - timelineWindow.blockRightClickRawX
                        local dy = curRawY - timelineWindow.blockRightClickRawY
                        timelineWindow.blockRightClickRawX = nil
                        if math.sqrt(dx * dx + dy * dy) < 4 then
                            local bd = self.blockData
                            local p = bd and bd.payload
                            NSI.UI.Components.ShowContextMenu({
                                {type = "button", label = "Edit Reminder", fnc = function()
                                    if p and p.srcLineIndex then
                                        NSI:ShowReminderDialog(timelineWindow, nil, self)
                                    end
                                end},
                                {type = "separator"},
                                {type = "button", label = "Delete Reminder", fnc = function()
                                    if p and p.srcLineIndex and timelineWindow.editNote then
                                        NSI:DeleteNoteLine(timelineWindow.editNote.name, true, p.srcLineIndex, p.srcRaw)
                                        -- Set before SetReminder — see the drag-retime comment above.
                                        timelineWindow.preserveZoom = true
                                        NSI:SetReminder(timelineWindow.editNote.name, true, false)
                                    end
                                end},
                            })
                        end
                    end
                end)
            end

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
    cursorTimeLabel:SetPoint("BOTTOM", cursorLine, "TOP", 0, -10)
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
        -- timelineWindow's own effective scale (its scale bar), not UIParent's.
        local uiScale = timelineWindow:GetEffectiveScale()
        cursorX = cursorX / uiScale
        cursorY = cursorY / uiScale

        local bodyLeft = timelineFrame.body:GetLeft() or 0
        local bodyRight = timelineFrame.body:GetRight() or 0
        local bodyTop = timelineFrame.body:GetTop() or 0
        local bodyBottom = timelineFrame.body:GetBottom() or 0

        -- Check if cursor is within timeline body bounds
        if cursorX >= bodyLeft and cursorX <= bodyRight and cursorY >= bodyBottom and cursorY <= bodyTop then
            -- body is the scroll CHILD, not the viewport — its GetLeft() already shifts with
            -- scroll, so mouseXInBody is already a scroll-independent content-space offset.
            local mouseXInBody = cursorX - bodyLeft
            local pixelsPerSecond = timelineFrame.options.pixels_per_second or 15
            local currentScale = timelineFrame.currentScale or 1

            -- Calculate time at cursor position
            local timeAtCursor = mouseXInBody / (pixelsPerSecond * currentScale)

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

    -- Preview line (green, animated during play preview)
    local previewLine = CreateFrame("Frame", nil, timelineFrame.body, "BackdropTemplate")
    previewLine:SetWidth(2)
    previewLine:SetFrameLevel(timelineFrame.body:GetFrameLevel() + 200)
    previewLine:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    previewLine:SetBackdropColor(0, 0.85, 0, 0.9)
    previewLine:Hide()
    timelineFrame.previewLine = previewLine

    local previewTimeLabel = previewLine:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewTimeLabel:SetPoint("TOP", previewLine, "BOTTOM", 0, -2)
    previewTimeLabel:SetTextColor(0.3, 1, 0.3, 1)

    local previewTimeBg = previewLine:CreateTexture(nil, "BACKGROUND")
    previewTimeBg:SetColorTexture(0, 0, 0, 0.7)
    previewTimeBg:SetPoint("TOPLEFT", previewTimeLabel, "TOPLEFT", -3, 2)
    previewTimeBg:SetPoint("BOTTOMRIGHT", previewTimeLabel, "BOTTOMRIGHT", 3, -1)

    -- Right-click drag panning state (both axes — behaves like grabbing the
    -- canvas: content tracks the cursor on X and Y simultaneously)
    local isDraggingTimeline = false
    local dragStartMouseX = 0
    local dragStartMouseY = 0
    local dragStartScroll = 0
    local dragStartVerticalScroll = 0
    local rightClickStartRawX = 0
    local rightClickStartRawY = 0

    local function startRightDrag()
        isDraggingTimeline = true
        local uiScale = 1 / timelineWindow:GetEffectiveScale()
        local rawX, rawY = GetCursorPosition()
        dragStartMouseX = rawX * uiScale
        dragStartMouseY = rawY * uiScale
        dragStartScroll = timelineFrame.horizontalSlider and timelineFrame.horizontalSlider:GetValue() or 0
        dragStartVerticalScroll = timelineFrame.verticalSlider and timelineFrame.verticalSlider:GetValue() or 0
        rightClickStartRawX, rightClickStartRawY = rawX, rawY
    end

    local function stopRightDrag()
        isDraggingTimeline = false
        local curRawX, curRawY = GetCursorPosition()
        local dx = curRawX - rightClickStartRawX
        local dy = curRawY - rightClickStartRawY
        if math.sqrt(dx * dx + dy * dy) < 4 then
            local uiScale = 1 / timelineWindow:GetEffectiveScale()
            local cursorX = curRawX * uiScale
            local bodyLeft = timelineFrame.body:GetLeft() or 0
            -- body is the scroll CHILD, not the viewport — its GetLeft() already shifts with
            -- scroll, so mouseXInBody is already a scroll-independent content-space offset.
            local mouseXInBody = cursorX - bodyLeft
            local pps = (timelineFrame.options.pixels_per_second or 15) * (timelineFrame.currentScale or 1)
            local absoluteTime = math.max(0, mouseXInBody / pps)
            NSI.UI.Components.ShowContextMenu({
                {type = "button", label = "Add Reminder", fnc = function()
                    NSI:ShowReminderDialog(timelineWindow, absoluteTime)
                end},
            })
        end
    end

    timelineFrame:EnableMouse(true)
    timelineFrame:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then startRightDrag() end
    end)
    timelineFrame:HookScript("OnMouseUp", function(self, button)
        if button == "RightButton" then stopRightDrag() end
    end)

    timelineFrame.body:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then startRightDrag() end
    end)
    timelineFrame.body:HookScript("OnMouseUp", function(self, button)
        if button == "RightButton" then stopRightDrag() end
    end)

    -- Ghost line + icon for block drag (snaps to whole seconds)
    local dragGhostLine = CreateFrame("Frame", nil, timelineFrame.body, "BackdropTemplate")
    dragGhostLine:SetWidth(2)
    dragGhostLine:SetFrameLevel(timelineFrame.body:GetFrameLevel() + 180)
    dragGhostLine:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    dragGhostLine:SetBackdropColor(0.3, 1, 0.3, 0.9)
    dragGhostLine:Hide()
    -- Snap time label on the ghost line
    local dragSnapLabel = dragGhostLine:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dragSnapLabel:SetPoint("BOTTOM", dragGhostLine, "TOP", 0, 2)
    dragSnapLabel:SetTextColor(0.4, 1, 0.4, 1)
    dragGhostLine.snapLabel = dragSnapLabel
    timelineFrame.dragGhostLine = dragGhostLine

    -- Ghost icon that floats at the block's row when dragging
    local dragGhostIcon = timelineFrame.body:CreateTexture(nil, "OVERLAY")
    dragGhostIcon:SetSize(20, 20)
    dragGhostIcon:SetAlpha(0.9)
    dragGhostIcon:Hide()
    timelineFrame.dragGhostIcon = dragGhostIcon

    -- Use OnUpdate for smooth cursor tracking and preview line animation
    local updateThrottle = 0
    timelineFrame.body:SetScript("OnUpdate", function(self, elapsed)
        updateThrottle = updateThrottle + elapsed
        if updateThrottle >= 0.016 then  -- ~60fps
            updateThrottle = 0
            if isDraggingTimeline then
                local uiScale = 1 / timelineWindow:GetEffectiveScale()
                local currentMouseX, currentMouseY = GetCursorPosition()
                currentMouseX = currentMouseX * uiScale
                currentMouseY = currentMouseY * uiScale
                if timelineFrame.horizontalSlider then
                    local delta = dragStartMouseX - currentMouseX
                    local hMin, hMax = timelineFrame.horizontalSlider:GetMinMaxValues()
                    timelineFrame.horizontalSlider:SetValue(math.max(hMin, math.min(hMax, dragStartScroll + delta)))
                end
                if timelineFrame.verticalSlider then
                    -- Content-follows-cursor on Y too, mirroring the horizontal pan above:
                    -- dragging up reveals lower rows (scroll value increases), dragging down
                    -- reveals rows above (scroll value decreases) — standard drag-to-scroll feel.
                    local deltaY = currentMouseY - dragStartMouseY
                    local vMin, vMax = timelineFrame.verticalSlider:GetMinMaxValues()
                    timelineFrame.verticalSlider:SetValue(math.max(vMin, math.min(vMax, dragStartVerticalScroll + deltaY)))
                end
            end
            if self:IsMouseOver() then
                updateCursorLine()
            end
            -- If the left button was released while the block moved away during a zoom refresh,
            -- OnMouseUp on the block never fired. Detect and finalize the orphaned drag here.
            if timelineWindow.draggingBlock and not IsMouseButtonDown("LeftButton") then
                local block = timelineWindow.draggingBlock
                timelineWindow.draggingBlock = nil
                dragGhostLine:Hide()
                dragGhostIcon:Hide()
                timelineWindow._lastSnappedTime = nil
                local isClick = false
                if block._clickStartX then
                    local curX, curY = GetCursorPosition()
                    local ddx = curX - block._clickStartX
                    local ddy = curY - block._clickStartY
                    isClick = math.sqrt(ddx * ddx + ddy * ddy) < 4
                    block._clickStartX = nil
                end
                if isClick then
                    local bd = block.blockData
                    if bd and bd.payload and bd.payload.srcLineIndex then
                        NSI:ShowReminderDialog(timelineWindow, nil, block)
                    end
                else
                    local uiScale = 1 / timelineWindow:GetEffectiveScale()
                    local cursorX = GetCursorPosition() * uiScale
                    local bodyLeft = timelineFrame.body:GetLeft() or 0
                    -- body is the scroll CHILD, not the viewport — its GetLeft() already shifts
                    -- with scroll, so scrollX must NOT be added again here.
                    local pps = (timelineFrame.options.pixels_per_second or 15) * (timelineFrame.currentScale or 1)
                    local newAbsoluteTime = math.max(0, math.floor((cursorX - bodyLeft) / pps + 0.5))
                    local encID = timelineWindow.currentEncounterID
                    local difficulty = timelineWindow.currentDifficulty
                    local phase, phaseStart = NSI:PhaseFromTime(encID, newAbsoluteTime, difficulty)
                    local newRelTime = math.max(0, newAbsoluteTime - phaseStart)
                    local bd = block.blockData
                    if bd and bd.payload and bd.payload.srcLineIndex and timelineWindow.editNote then
                        local p = bd.payload
                        local newRaw = p.srcRaw:gsub("time:[%d%.]+", "time:" .. newRelTime)
                        newRaw = newRaw:gsub("ph:%d+", "ph:" .. phase)
                        NSI:RewriteNoteLine(timelineWindow.editNote.name, true, p.srcLineIndex, p.srcRaw, newRaw)
                        -- Set before SetReminder — see the drag-retime comment above.
                        timelineWindow.preserveZoom = true
                        NSI:SetReminder(timelineWindow.editNote.name, true, false)
                    end
                end
            end
            -- Snapped ghost line + icon while dragging a block
            if timelineWindow.draggingBlock then
                local uiScale = 1 / timelineWindow:GetEffectiveScale()
                local cursorX = GetCursorPosition() * uiScale
                local bodyLeft = timelineFrame.body:GetLeft() or 0
                -- body is the scroll CHILD, not the viewport — its GetLeft() already shifts with
                -- scroll, so mouseXInBody is already a scroll-independent content-space offset.
                local mouseXInBody = cursorX - bodyLeft
                local pps = (timelineFrame.options.pixels_per_second or 15) * (timelineFrame.currentScale or 1)
                local elapsedHeight = timelineFrame.options.elapsed_timeline_height or 20

                -- Snap to whole seconds.
                local rawTime = mouseXInBody / pps
                local snappedTime = math.max(0, math.floor(rawTime + 0.5))
                local snappedX = snappedTime * pps

                local mins = math.floor(snappedTime / 60)
                local secs = snappedTime % 60
                dragGhostLine.snapLabel:SetText(string.format("%d:%02d", mins, secs))

                dragGhostLine:ClearAllPoints()
                dragGhostLine:SetPoint("TOP", timelineFrame.body, "TOPLEFT", snappedX, -elapsedHeight)
                dragGhostLine:SetPoint("BOTTOM", timelineFrame.body, "BOTTOMLEFT", snappedX, 0)
                dragGhostLine:Show()

                -- Ghost icon: anchored to the block's line frame so it tracks that row
                -- correctly through any zoom or vertical scroll that happens during the drag.
                local block = timelineWindow.draggingBlock
                local lineFrame = block:GetParent()
                if lineFrame then
                    dragGhostIcon:ClearAllPoints()
                    dragGhostIcon:SetPoint("LEFT", lineFrame, "LEFT", snappedX, 0)
                    if block.blockData and block.blockData[5] then
                        local info = C_Spell.GetSpellInfo(block.blockData[5])
                        if info and info.iconID then
                            dragGhostIcon:SetTexture(info.iconID)
                            dragGhostIcon:Show()
                        else
                            dragGhostIcon:Hide()
                        end
                    else
                        dragGhostIcon:Hide()
                    end
                end
            else
                dragGhostLine:Hide()
                dragGhostIcon:Hide()
            end
            if timelineWindow.previewActive and timelineWindow.previewStartTime then
                local previewElapsed = GetTime() - timelineWindow.previewStartTime
                local pixelsPerSecond = timelineFrame.options.pixels_per_second or 15
                local currentScale = timelineFrame.currentScale or 1
                local elapsedHeight = timelineFrame.options.elapsed_timeline_height or 20
                -- Anchored to body (the scroll child), which already shifts with scroll —
                -- do not also subtract scrollX here.
                local previewX = previewElapsed * pixelsPerSecond * currentScale
                local bodyWidth = timelineFrame.body:GetWidth() or 0

                if previewX >= 0 and previewX <= bodyWidth then
                    previewLine:ClearAllPoints()
                    previewLine:SetPoint("TOP", timelineFrame.body, "TOPLEFT", previewX, -elapsedHeight)
                    previewLine:SetPoint("BOTTOM", timelineFrame.body, "BOTTOMLEFT", previewX, 0)
                    local minutes = math.floor(previewElapsed / 60)
                    local seconds = math.floor(previewElapsed % 60)
                    previewTimeLabel:SetText(string.format("%d:%02d", minutes, seconds))
                    previewLine:Show()
                else
                    previewLine:Hide()
                end

                local timelineLength = (timelineFrame.data and timelineFrame.data.length) or 300
                if previewElapsed >= timelineLength then
                    timelineWindow.previewActive = false
                    timelineWindow.previewStartTime = nil
                    previewLine:Hide()
                    NSI:HideAllReminders()
                    if timelineWindow.playButton then
                        timelineWindow.playButton.text = "Play Preview"
                        timelineWindow.playButton:SetIcon(NSI.LSM:Fetch("statusbar", "play_icon"), 14, 14, "OVERLAY", nil, {0, 1, 0, 1})
                    end
                end
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
    local helpLabel = DF:CreateLabel(timelineWindow, "Scroll: Zoom | Right-drag: Navigate | Ctrl+Scroll: Vertical | Edit mode: Right-click add, Left-drag retime", 10, "gray")
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
        if not self.ProcessedReminder then
            self:ProcessReminder() -- also calls RefreshTimelineForMode at its end
        else
            self:RefreshTimelineForMode()
        end
    end
end

-- Opens the Timeline window (creating/showing it if needed) and points it at a
-- specific note by name — used by the "View in Timeline" button on the note
-- editor screens. Personal notes go through "My Reminders" mode with this note
-- set as the Edit Note target (same chrome/result as picking it from the Edit
-- Note menu). Shared notes have no Edit Note entry, so they use "All Reminders"
-- mode instead, which is the only view that can show an arbitrary shared note.
function NSI:ViewNoteInTimeline(name, personal)
    if not name or name == "" then return end
    if not self.TimelineWindow then
        self.TimelineWindow = self:CreateTimelineWindow()
    end
    local window = self.TimelineWindow
    if not window:IsShown() then
        window:Show()
    end

    local value = {name = name, personal = personal}
    window.currentReminder = value

    if personal then
        window.mode = "my"
        if window.modeDropdown then window.modeDropdown:Select("my") end
        window.reminderLabel:Hide()
        window.reminderDropdown:Hide()
        window.editNoteLabel:Show()
        window.editNoteButton.frame:Show()
        if window.playButton then window.playButton:Show() end

        window.editNote = value
        window.editable = true
        self:SetReminder(name, true, true)
        self:UpdateEditNoteButtonLabel(window)
    else
        window.mode = "all"
        if window.modeDropdown then window.modeDropdown:Select("all") end
        window.reminderLabel:Show()
        window.reminderDropdown:Show()
        window.editNoteLabel:Hide()
        window.editNoteButton.frame:Hide()
        window.editable = false
        window.editNote = nil
        if window.playButton then
            if window.previewActive then
                window.previewActive = false
                window.previewStartTime = nil
                if window.timeline and window.timeline.previewLine then
                    window.timeline.previewLine:Hide()
                end
                self:HideAllReminders()
                window.playButton.text = "Play Preview"
                window.playButton:SetIcon(self.LSM:Fetch("statusbar", "play_icon"), 14, 14, "OVERLAY", nil, {0, 1, 0, 1})
            end
            window.playButton:Hide()
        end
        -- Select() matches against option.label/.value with ==, which is table
        -- identity — a freshly-built {name=,personal=} table never equals the
        -- option table already inside the dropdown's own list, so passing `value`
        -- silently fails to update the visible selection. Shared entries' label
        -- is just the note name, so matching on that string works correctly.
        if window.reminderDropdown then window.reminderDropdown:Select(name) end
    end

    self:RefreshTimelineForMode()
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
                -- Select() matches option.label with == (a string compare here, not
                -- table identity), so pass the label text — personal entries carry
                -- the " (Personal)" suffix BuildReminderDropdownOptions labels them with.
                local label = isPersonal and (activeReminder .. " (Personal)") or activeReminder
                self.TimelineWindow.reminderDropdown:Select(label)
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
    -- Skip auto-fit when user has just dragged a block (preserves their zoom level)
    if self.TimelineWindow and self.TimelineWindow.preserveZoom then
        self.TimelineWindow.preserveZoom = nil
        -- Still update the scale min so zoom-out limit stays correct
        local visibleWidth = timeline:GetWidth() or 880
        local pps = timeline.options.pixels_per_second or 15
        local dur = math.min(dataLength or 300, 600)
        local dynamicScaleMin = visibleWidth / (dur * pps)
        if timeline.scaleSlider then
            local _, scaleMax = timeline.scaleSlider:GetMinMaxValues()
            timeline.scaleSlider:SetMinMaxValues(dynamicScaleMin, scaleMax or 2.0)
        end
        return
    end

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

-- Reflects window.editNote onto the "Edit Note" menu-bar button's label.
function NSI:UpdateEditNoteButtonLabel(window)
    if not window or not window.editNoteButton then return end
    local editNote = window.editNote
    window.editNoteButton:SetText(editNote and (editNote.name .. " (Personal)") or "None (Read Only)")
end

-- Returns (creating if necessary) THE personal note for a boss, reusing one that
-- already exists. Used by the Add Reminder popup's boss-picker path, where filing
-- a stray reminder under an existing note is the more useful default.
function NSI:GetOrCreatePersonalBossNote(eid)
    local bossName   = NSI.BossNames[eid] or ("Boss" .. eid)
    local actualName = bossName .. " - Mythic"
    if not NSRT.PersonalReminders[actualName] then
        NSRT.PersonalReminders[actualName] = string.format(
            "EncounterID:%d;Name:%s;Difficulty:Mythic\n", eid, bossName)
    end
    self:SetReminder(actualName, true, true)
    return {name = actualName, personal = true}
end

-- Always creates a brand-new personal note for a boss, uniquely named
-- ("<Boss> - Mythic", "<Boss> - Mythic 2", ...) — mirrors the "+ Create Note"
-- naming convention in the Personal Notes tab. Unlike GetOrCreatePersonalBossNote,
-- this never reuses an existing note; used by the Edit Note menu's "+ New Note".
function NSI:CreateNewPersonalBossNote(eid)
    local bossName  = NSI.BossNames[eid] or ("Boss" .. eid)
    local baseName  = bossName .. " - Mythic"
    local actualName = baseName
    local n = 2
    while NSRT.PersonalReminders[actualName] do
        actualName = baseName .. " " .. n
        n = n + 1
    end
    NSRT.PersonalReminders[actualName] = string.format(
        "EncounterID:%d;Name:%s;Difficulty:Mythic\n", eid, bossName)
    self:SetReminder(actualName, true, true)
    return {name = actualName, personal = true}
end

-- Refresh timeline with player's own processed reminders (My Reminders mode)
function NSI:RefreshMyRemindersTimeline()
    if not self.TimelineWindow or not self.TimelineWindow.timeline then return end

    -- Auto-select the currently loaded personal note as the edit target when none is set.
    if not self.TimelineWindow.editNote and self.LoadedPersonalReminder
       and NSRT.PersonalReminders[self.LoadedPersonalReminder] then
        local autoNote = {name = self.LoadedPersonalReminder, personal = true}
        self.TimelineWindow.editNote = autoNote
        self.TimelineWindow.editable = true
        self:UpdateEditNoteButtonLabel(self.TimelineWindow)
    end

    -- When an edit note is active, use GetAllTimelineData so every block carries
    -- srcLineIndex/srcRaw and can be dragged/right-click-added.
    local editNote = self.TimelineWindow.editNote
    if editNote then
        self:RefreshAllRemindersTimeline(editNote.name, true)
        return
    end

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

--------------------------------------------------------------------------------
-- ADD / EDIT REMINDER DIALOG
--------------------------------------------------------------------------------

function NSI:ShowReminderDialog(window, absoluteTime, block)
    local C = NSI.UI.Components
    local isEdit = block ~= nil
    local bd     = isEdit and block.blockData or nil
    local payload = bd and bd.payload or nil
    local srcRaw  = payload and payload.srcRaw or ""

    -- Parse existing field values from the raw reminder line when editing
    local existingSpellID  = (bd and bd[5]) and tostring(bd[5]) or ""
    local existingText     = srcRaw:match("text:([^;]+)") or ""
    local existingDur      = srcRaw:match("dur:(%d+)") or tostring(NSRT.ReminderSettings.SpellDuration or 5)
    local existingGlowUnit = srcRaw:match("glowunit:([^;]+)") or ""

    -- Derive absolute time from the block's stored phase/time when not supplied
    if isEdit and not absoluteTime then
        local phase   = tonumber(srcRaw:match("ph:(%d+)") or "1") or 1
        local relTime = tonumber(srcRaw:match("time:(%d*%.?%d+)") or "0") or 0
        local phStart = NSI:GetPhaseStart(window.currentEncounterID, phase, window.currentDifficulty) or 0
        absoluteTime  = phStart + relTime
    end
    absoluteTime = absoluteTime or 0

    -- ── Build popup (created once, reused) ──────────────────────────────────
    if not self.ReminderDialogPopup then
        local W = 380
        local popup = C.CreateFrame(UIParent, W, 270, "NSRTReminderDialogPopup")
        popup:SetFrameStrata("TOOLTIP")

        -- Title font string (CreateStyledFrame doesn't add one)
        local titleFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -10)
        popup.titleFS = titleFS

        -- Thin cyan separator below the title
        local sep = popup:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(0, 1, 1, 0.20)
        sep:SetHeight(1)
        sep:SetPoint("TOPLEFT",  popup, "TOPLEFT",  1, -28)
        sep:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -1, -28)

        -- Phase / Time-in-phase (editable — map directly to the raw "ph:"/"time:" fields)
        local phaseEntry = C.CreateTextEntry(popup, "Phase",
            function() return "" end, function() end,
            110, 22, true, 1, nil, "NSRTReminderPhase")
        phaseEntry:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -36)
        popup.phaseEntry = phaseEntry

        local timeEntry = C.CreateTextEntry(popup, "Time (s)",
            function() return "" end, function() end,
            160, 22, true, 0, nil, "NSRTReminderTime")
        timeEntry:SetPoint("LEFT", phaseEntry.frame, "RIGHT", 14, 0)
        popup.timeEntry = timeEntry

        -- ── Spell ID row ────────────────────────────────────────────────────
        -- Entry uses built-in label; 160px container keeps the 60px input
        -- right-aligned with room for the icon + Pick button beside it.
        local spellEntry = C.CreateTextEntry(popup, "Spell ID",
            function() return "" end, function() end,
            160, 22, false, nil, nil, "NSRTReminderSpellID")
        spellEntry:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -60)
        popup.spellEntry = spellEntry

        -- Spell icon preview (right of the editBox)
        local spellIcon = popup:CreateTexture(nil, "OVERLAY")
        spellIcon:SetSize(20, 20)
        spellIcon:SetPoint("LEFT", spellEntry.editBox, "RIGHT", 6, 0)
        spellIcon:Hide()
        popup.spellIcon = spellIcon

        -- Pick Spell button (right of icon)
        local pickBtn = C.CreateButton(popup, "Pick Spell", function()
            NSI:ShowSpellbookPicker(popup)
        end, 88, 20)
        pickBtn:SetPoint("LEFT", spellIcon, "RIGHT", 6, 0)
        popup.pickBtn = pickBtn

        -- Live icon preview while typing a spell ID
        spellEntry.editBox:HookScript("OnTextChanged", function(self)
            local id = tonumber(self:GetText())
            if id then
                local info = C_Spell.GetSpellInfo(id)
                if info and info.iconID then
                    popup.spellIcon:SetTexture(info.iconID)
                    popup.spellIcon:Show()
                    return
                end
            end
            popup.spellIcon:Hide()
        end)

        -- ── Text row ────────────────────────────────────────────────────────
        local textLabel = C.CreateLabel(popup, "Text", W - 24, 14)
        textLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -90)
        local textEntry = C.CreateTextEntry(popup, nil,
            function() return "" end, function() end,
            W - 24, 22, false, nil, nil, "NSRTReminderText")
        textEntry:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -106)
        popup.textEntry = textEntry

        -- ── Duration row ────────────────────────────────────────────────────
        local durEntry = C.CreateTextEntry(popup, "Duration (s)",
            function() return "5" end, function() end,
            200, 22, false, nil, nil, "NSRTReminderDur")
        durEntry:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -136)
        popup.durEntry = durEntry

        -- ── Glow Unit row ───────────────────────────────────────────────────
        local glowLabel = C.CreateLabel(popup, "Glow Unit  (space-separated names)", W - 24, 14)
        glowLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -166)
        local glowEntry = C.CreateTextEntry(popup, nil,
            function() return "" end, function() end,
            W - 24, 22, false, nil, nil, "NSRTReminderGlow")
        glowEntry:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -182)
        popup.glowEntry = glowEntry

        -- ── Boss row (shown only when there is no boss context or edit note) ─
        local bossRowLabel = C.CreateLabel(popup, "Boss", 60, 18)
        bossRowLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -214)
        popup.bossRowLabel = bossRowLabel

        local selectedBossLabel = C.CreateLabel(popup, "None selected", W - 170, 18)
        selectedBossLabel:SetPoint("LEFT", bossRowLabel.frame, "RIGHT", 6, 0)
        popup.selectedBossLabel = selectedBossLabel

        local function buildBossMenuItems()
            local sorted = {}
            for eid, order in pairs(NSI.EncounterOrder) do
                table.insert(sorted, {encID = eid, order = order})
            end
            table.sort(sorted, function(a, b) return a.order < b.order end)
            local items = {}
            for _, entry in ipairs(sorted) do
                local eid = entry.encID
                items[#items + 1] = {
                    type  = "button",
                    label = NSI.BossNames[eid] or ("Encounter " .. eid),
                    icon  = NSI.UI.BossData.BossIcons and NSI.UI.BossData.BossIcons[eid],
                    fnc   = function()
                        popup._pendingEncID = eid
                        popup.selectedBossLabel.label:SetText(NSI.BossNames[eid] or ("Encounter " .. eid))
                        popup.selectedBossLabel.label:SetTextColor(1, 1, 1, 1)
                    end,
                }
            end
            return items
        end

        local selectBossBtn = C.CreateButton(popup, "Pick Boss", function()
            C.ShowContextMenu(buildBossMenuItems())
        end, 88, 20)
        selectBossBtn:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
        selectBossBtn.frame:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -12, -210)
        popup.selectBossBtn = selectBossBtn

        -- ── Bottom buttons ───────────────────────────────────────────────────
        local confirmBtn = C.CreateButton(popup, "Add", function()
            if popup._confirmAction then popup._confirmAction() end
        end, 100, 24)
        confirmBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 10)
        popup.confirmBtn = confirmBtn

        local cancelBtn = C.CreateButton(popup, "Cancel", function()
            popup:Hide()
        end, 80, 24)
        cancelBtn:SetPoint("RIGHT", confirmBtn.frame, "LEFT", -6, 0)
        popup.cancelBtn = cancelBtn

        local deleteBtn = C.CreateButton(popup, "Delete", function()
            if popup._deleteAction then popup._deleteAction() end
        end, 80, 24)
        deleteBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 12, 10)
        popup.deleteBtn = deleteBtn

        popup:Hide()
        self.ReminderDialogPopup = popup
    end

    -- ── Populate / refresh the popup ────────────────────────────────────────
    local popup = self.ReminderDialogPopup
    popup._window = window
    popup._block  = block

    -- Title
    popup.titleFS:SetText(isEdit and "|cFF00FFFFEdit Reminder|r" or "|cFF00FFFFAdd Reminder|r")

    -- Time info
    local encID    = window.currentEncounterID
    local difficulty = window.currentDifficulty
    local phase, phaseStart = self:PhaseFromTime(encID, absoluteTime, difficulty)
    local relTime  = math.max(0, math.floor(absoluteTime - phaseStart))
    popup._phase   = phase
    popup._relTime = relTime
    popup._pendingEncID = encID

    -- Pre-fill fields
    popup.phaseEntry:SetValue(phase)
    popup.timeEntry:SetValue(relTime)
    popup.spellEntry:SetValue(existingSpellID)
    popup.textEntry:SetValue(existingText)
    popup.durEntry:SetValue(existingDur)
    popup.glowEntry:SetValue(existingGlowUnit)

    -- Spell icon initial state
    popup.spellIcon:Hide()
    if existingSpellID ~= "" then
        local sid = tonumber(existingSpellID)
        if sid then
            local info = C_Spell.GetSpellInfo(sid)
            if info and info.iconID then
                popup.spellIcon:SetTexture(info.iconID)
                popup.spellIcon:Show()
            end
        end
    end

    -- Boss row visibility
    local hasBossContext = encID ~= nil
    local hasEditNote    = window.editNote ~= nil
    local showBossRow    = not hasEditNote and not hasBossContext
    popup.bossRowLabel.frame:SetShown(showBossRow)
    popup.selectedBossLabel.frame:SetShown(showBossRow)
    popup.selectBossBtn.frame:SetShown(showBossRow)
    if showBossRow then
        popup.selectedBossLabel.label:SetText("None selected")
        popup.selectedBossLabel.label:SetTextColor(0.5, 0.5, 0.5, 1)
        if not hasBossContext then popup._pendingEncID = nil end
    end
    popup:SetHeight(showBossRow and 300 or 260)

    -- Delete button only in edit mode
    popup.deleteBtn.frame:SetShown(isEdit)

    -- Confirm button label
    popup.confirmBtn:SetText(isEdit and "Save" or "Add")

    -- ── Confirm action (add or save) ─────────────────────────────────────────
    popup._confirmAction = function()
        local editNote = popup._window and popup._window.editNote
        if not editNote then
            local eid = popup._pendingEncID
            if not eid then
                print("|cffff4444NSRT:|r Select a boss first, or open a note from the Edit Note menu.")
                return
            end
            editNote = NSI:GetOrCreatePersonalBossNote(eid)
            if popup._window then
                popup._window.editNote   = editNote
                popup._window.editable   = true
                NSI:UpdateEditNoteButtonLabel(popup._window)
            end
        end

        local spellID  = tonumber(popup.spellEntry:GetValue())
        local text     = popup.textEntry:GetValue()
        local dur      = tonumber(popup.durEntry:GetValue()) or NSRT.ReminderSettings.SpellDuration or 5
        local glowUnit = popup.glowEntry:GetValue()

        -- Phase / time-in-phase: manual override from the editable fields, falling
        -- back to the cursor/block-derived defaults if left blank or invalid.
        local newPhase = math.max(1, math.floor(tonumber(popup.phaseEntry:GetValue()) or phase))
        local newRelTime = math.max(0, tonumber(popup.timeEntry:GetValue()) or relTime)

        if isEdit and payload and payload.srcLineIndex then
            -- Rebuild the line, preserving tag; updating time/ph/spell/text/dur/glowunit
            local newRaw = srcRaw
            newRaw = newRaw:gsub("time:[%d%.]+", "time:" .. newRelTime)
            if newRaw:find("ph:%d+") then
                newRaw = newRaw:gsub("ph:%d+", "ph:" .. newPhase)
            else
                newRaw = newRaw .. ";ph:" .. newPhase
            end
            -- Insert a new "key:value" chunk before ";ph:" when present; otherwise append
            -- it to the end. Lines without an explicit ph (defaults to phase 1) have no
            -- ";ph:" anchor, so a plain gsub(";ph:", ...) would silently no-op on them.
            local function insertField(raw, chunk)
                if raw:find(";ph:") then
                    return (raw:gsub(";ph:", ";" .. chunk .. ";ph:", 1))
                else
                    return raw .. ";" .. chunk
                end
            end
            -- spellid
            if spellID then
                if newRaw:find("spellid:%d+") then
                    newRaw = newRaw:gsub("spellid:%d+", "spellid:" .. spellID)
                else
                    newRaw = insertField(newRaw, "spellid:" .. spellID)
                end
            else
                newRaw = newRaw:gsub(";spellid:%d+", "")
            end
            -- text
            if text ~= "" then
                if newRaw:find("text:[^;]+") then
                    newRaw = newRaw:gsub("text:[^;]+", "text:" .. text)
                else
                    newRaw = insertField(newRaw, "text:" .. text)
                end
            else
                newRaw = newRaw:gsub(";text:[^;]+", "")
            end
            -- dur
            if newRaw:find("dur:%d+") then
                newRaw = newRaw:gsub("dur:%d+", "dur:" .. dur)
            else
                newRaw = newRaw .. ";dur:" .. dur
            end
            -- glowunit
            if glowUnit ~= "" then
                if newRaw:find("glowunit:[^;]+") then
                    newRaw = newRaw:gsub("glowunit:[^;]+", "glowunit:" .. glowUnit)
                else
                    newRaw = insertField(newRaw, "glowunit:" .. glowUnit)
                end
            else
                newRaw = newRaw:gsub(";glowunit:[^;]+", "")
            end
            -- Tidy double semicolons introduced by removals
            newRaw = newRaw:gsub(";;+", ";")
            NSI:RewriteNoteLine(editNote.name, true, payload.srcLineIndex, srcRaw, newRaw)
        else
            -- Build a new line
            local playerName = UnitName("player") or "Player"
            local line = "tag:" .. playerName .. ";time:" .. newRelTime .. ";"
            if spellID  then line = line .. "spellid:" .. spellID .. ";"  end
            if text ~= ""     then line = line .. "text:" .. text .. ";"          end
            if glowUnit ~= "" then line = line .. "glowunit:" .. glowUnit .. ";"  end
            line = line .. "ph:" .. newPhase .. ";dur:" .. dur
            NSI:AppendNoteLine(editNote.name, true, line)
        end

        -- Set before SetReminder: with skipupdate=false it calls ProcessReminder(),
        -- which refreshes the timeline itself if shown — the flag must already be
        -- set or that refresh resets the zoom before the explicit one below runs.
        window.preserveZoom = true
        NSI:SetReminder(editNote.name, true, false)
        popup:Hide()
    end

    -- ── Delete action ────────────────────────────────────────────────────────
    popup._deleteAction = function()
        local editNote = popup._window and popup._window.editNote
        if editNote and payload and payload.srcLineIndex then
            NSI:DeleteNoteLine(editNote.name, true, payload.srcLineIndex, srcRaw)
            window.preserveZoom = true
            NSI:SetReminder(editNote.name, true, false)
            popup:Hide()
        end
    end

    popup:SetPoint("CENTER", UIParent, "CENTER")
    popup:Show()
    popup.spellEntry.editBox:SetFocus()
end

--------------------------------------------------------------------------------
-- SPELLBOOK PICKER
--------------------------------------------------------------------------------

-- TWW removed the classic spellbook globals in favor of C_SpellBook; shim them
-- the same way LibDFramework does (see Libs/LibDFramework-1.0/fw.lua) so this
-- keeps working on both API generations.
local GetNumSpellTabs = GetNumSpellTabs or C_SpellBook.GetNumSpellBookSkillLines
local GetSpellTabInfo = GetSpellTabInfo or function(tabLine)
    local skillLine = C_SpellBook.GetSpellBookSkillLineInfo(tabLine)
    if skillLine then
        return skillLine.name, skillLine.iconID, skillLine.itemIndexOffset, skillLine.numSpellBookItems,
            skillLine.isGuild, skillLine.offSpecID
    end
end
local SpellBookItemTypeMap = Enum.SpellBookItemType and {
    [Enum.SpellBookItemType.Spell] = "SPELL",
    [Enum.SpellBookItemType.None] = "NONE",
    [Enum.SpellBookItemType.Flyout] = "FLYOUT",
    [Enum.SpellBookItemType.FutureSpell] = "FUTURESPELL",
    [Enum.SpellBookItemType.PetAction] = "PETACTION",
} or {}
local GetSpellBookItemInfo = GetSpellBookItemInfo or function(...)
    local si = C_SpellBook.GetSpellBookItemInfo(...)
    if si then
        return SpellBookItemTypeMap[si.itemType] or "NONE",
            (si.itemType == Enum.SpellBookItemType.Flyout or si.itemType == Enum.SpellBookItemType.PetAction) and si.actionID or si.spellID or si.actionID,
            si
    end
end
local BOOKTYPE_SPELL = BOOKTYPE_SPELL or (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or "player"

function NSI:ShowSpellbookPicker(targetPopup)
    if not self.SpellbookPickerPopup then
        local picker = CreateFrame("Frame", "NSRTSpellbookPicker", UIParent, "BackdropTemplate")
        picker:SetSize(300, 400)
        picker:SetFrameStrata("TOOLTIP")
        picker:SetMovable(true)
        picker:SetClampedToScreen(true)
        picker:EnableMouse(true)
        picker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        picker:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
        picker:SetBackdropBorderColor(0, 1, 1, 0.7)

        -- Title bar / drag handle
        local titleBar = CreateFrame("Frame", nil, picker)
        titleBar:SetHeight(22)
        titleBar:SetPoint("TOPLEFT", picker, "TOPLEFT", 1, -1)
        titleBar:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -1, -1)
        titleBar:EnableMouse(true)
        titleBar:SetScript("OnMouseDown", function(_, b) if b == "LeftButton" then picker:StartMoving() end end)
        titleBar:SetScript("OnMouseUp", function() picker:StopMovingOrSizing() end)
        local titleFS = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFS:SetText("|cFF00FFFFPick Spell|r")
        titleFS:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
        local xBtn = CreateFrame("Button", nil, picker)
        xBtn:SetSize(16, 16)
        xBtn:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -4, -4)
        xBtn:SetFrameLevel(picker:GetFrameLevel() + 3)
        xBtn:SetNormalFontObject("GameFontNormal")
        xBtn:SetText("×")
        xBtn:SetScript("OnClick", function() picker:Hide() end)

        -- Filter box
        local filterBox = DF:CreateTextEntry(picker, function() end, 250, 20, nil, "NSRTSpellPickerFilter")
        filterBox:SetPoint("TOPLEFT", picker, "TOPLEFT", 10, -30)
        picker.filterBox = filterBox

        -- Scroll frame for spell list.
        -- Anchored to picker with a fixed offset rather than to filterBox (a DF wrapper
        -- table) because native SetPoint only accepts real WoW frame objects.
        -- filterBox top = -30, height = 20, so its bottom is at y=-50; add 4px gap → -54.
        local scrollFrame = CreateFrame("ScrollFrame", "NSRTSpellPickerScroll", picker, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", picker, "TOPLEFT", 10, -54)
        scrollFrame:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -26, 10)
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(260)
        scrollChild:SetHeight(1)
        scrollFrame:SetScrollChild(scrollChild)
        picker.scrollChild = scrollChild
        picker.scrollFrame = scrollFrame

        -- Pool of row buttons (created lazily)
        picker.rowPool = {}
        picker.rows = {}

        local function refreshList()
            local filter = strlower(filterBox:GetText() or filterBox.editbox:GetText() or "")
            -- Gather spells
            local spells = {}
            local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
            for t = 1, numTabs do
                local _, _, offset, numSlots = GetSpellTabInfo(t)
                for s = offset + 1, offset + numSlots do
                    local sType, id = GetSpellBookItemInfo(s, BOOKTYPE_SPELL)
                    if sType == "SPELL" and id then
                        local info = C_Spell.GetSpellInfo(id)
                        if info and info.name then
                            if filter == "" or info.name:lower():find(filter, 1, true) then
                                table.insert(spells, {name = info.name, id = id, icon = info.iconID})
                            end
                        end
                    end
                end
            end
            table.sort(spells, function(a, b) return a.name < b.name end)

            -- Recycle rows
            for _, row in ipairs(picker.rows) do row:Hide() end
            picker.rows = {}

            local rowHeight = 24
            local y = 0
            for i, spell in ipairs(spells) do
                local row = picker.rowPool[i]
                if not row then
                    row = CreateFrame("Button", nil, scrollChild)
                    row:SetHeight(rowHeight)
                    row:EnableMouse(true)
                    row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
                    -- Icon
                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(18, 18)
                    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
                    row.icon = icon
                    -- Name
                    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nameFS:SetPoint("LEFT", icon, "RIGHT", 4, 0)
                    nameFS:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                    nameFS:SetJustifyH("LEFT")
                    row.nameFS = nameFS
                    picker.rowPool[i] = row
                end
                row:SetWidth(scrollChild:GetWidth())
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
                row.icon:SetTexture(spell.icon)
                row.nameFS:SetText(string.format("|cffaaaaaa[%d]|r %s", spell.id, spell.name))
                local spellID = spell.id
                row:SetScript("OnClick", function()
                    if picker._target then
                        local target = picker._target
                        -- Support Components textentry (.spellEntry / .editBox)
                        -- and legacy DF textentry (.spellIDBox / .editbox)
                        local entry = target.spellEntry or target.spellIDBox
                        if entry then
                            if entry.SetValue then
                                entry:SetValue(tostring(spellID))
                            elseif entry.SetText then
                                entry:SetText(tostring(spellID))
                            end
                            local eb = entry.editBox or entry.editbox
                            if eb then
                                local fn = eb:GetScript("OnTextChanged")
                                if fn then fn(eb) end
                            end
                        end
                    end
                    picker:Hide()
                end)
                row:Show()
                table.insert(picker.rows, row)
                y = y + rowHeight
            end
            scrollChild:SetHeight(math.max(1, y))
        end

        filterBox.editbox:SetScript("OnTextChanged", function() refreshList() end)
        picker.refreshList = refreshList

        picker:Hide()
        self.SpellbookPickerPopup = picker
    end

    local picker = self.SpellbookPickerPopup
    picker._target = targetPopup
    picker.filterBox:SetText("")
    picker.refreshList()
    picker:SetPoint("LEFT", targetPopup, "RIGHT", 4, 0)
    picker:Show()
    picker.filterBox.editbox:SetFocus()
end

--------------------------------------------------------------------------------
-- RENAME / DELETE NOTE DIALOGS (right-click on a note in the Edit Note menu)
--------------------------------------------------------------------------------

-- Clears any Timeline window state pointing at `name`, since it either no
-- longer exists (delete) or has moved to a new key (rename, pass newName).
local function ClearWindowNoteReferences(window, name, newName)
    if not window then return end
    if window.editNote and window.editNote.name == name then
        if newName then
            window.editNote.name = newName
        else
            window.editNote = nil
            window.editable = false
        end
        NSI:UpdateEditNoteButtonLabel(window)
    end
    if window.currentReminder and window.currentReminder.personal and window.currentReminder.name == name then
        window.currentReminder = newName and {name = newName, personal = true} or nil
    end
end

function NSI:ShowRenameNoteDialog(window, oldName)
    local C = NSI.UI.Components
    if not self.RenameNotePopup then
        local W = 300
        local popup = C.CreateFrame(UIParent, W, 96, "NSRTRenameNotePopup")
        popup:SetFrameStrata("TOOLTIP")

        local titleFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFS:SetText("|cFF00FFFFRename Note|r")
        titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -10)

        local nameEntry = C.CreateTextEntry(popup, nil,
            function() return "" end, function() end,
            W - 24, 22, false, nil, nil, "NSRTRenameNoteEntry")
        nameEntry:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -34)
        popup.nameEntry = nameEntry

        local errorFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        errorFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -60)
        errorFS:SetTextColor(1, 0.35, 0.35, 1)
        popup.errorFS = errorFS

        local confirmBtn = C.CreateButton(popup, "Rename", function()
            if popup._confirmAction then popup._confirmAction() end
        end, 90, 24)
        confirmBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 10)

        local cancelBtn = C.CreateButton(popup, "Cancel", function()
            popup:Hide()
        end, 80, 24)
        cancelBtn:SetPoint("RIGHT", confirmBtn.frame, "LEFT", -6, 0)

        nameEntry.editBox:SetScript("OnEnterPressed", function()
            if popup._confirmAction then popup._confirmAction() end
        end)

        popup:Hide()
        self.RenameNotePopup = popup
    end

    local popup = self.RenameNotePopup
    popup.nameEntry:SetValue(oldName)
    popup.errorFS:SetText("")

    popup._confirmAction = function()
        local newName = popup.nameEntry:GetValue()
        local ok, resultOrErr = NSI:RenamePersonalNote(oldName, newName)
        if not ok then
            local messages = {
                empty   = "Enter a different name.",
                exists  = "A note with that name already exists.",
                missing = "Note no longer exists.",
            }
            popup.errorFS:SetText(messages[resultOrErr] or "Rename failed.")
            return
        end
        ClearWindowNoteReferences(window, oldName, resultOrErr)
        if window then NSI:RefreshTimelineForMode() end
        popup:Hide()
    end

    popup:SetPoint("CENTER", UIParent, "CENTER")
    popup:Show()
    popup.nameEntry.editBox:SetFocus()
    popup.nameEntry.editBox:HighlightText()
end

function NSI:ShowDeleteNoteConfirm(window, name)
    local C = NSI.UI.Components
    if not self.DeleteNotePopup then
        local W = 320
        local popup = C.CreateFrame(UIParent, W, 110, "NSRTDeleteNotePopup")
        popup:SetFrameStrata("TOOLTIP")

        local titleFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFS:SetText("|cFFff4444Delete Note|r")
        titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -10)

        local msgFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        msgFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -34)
        msgFS:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -12, -34)
        msgFS:SetJustifyH("LEFT")
        msgFS:SetJustifyV("TOP")
        popup.msgFS = msgFS

        local confirmBtn = C.CreateButton(popup, "Delete", function()
            if popup._confirmAction then popup._confirmAction() end
        end, 90, 24)
        confirmBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 10)

        local cancelBtn = C.CreateButton(popup, "Cancel", function()
            popup:Hide()
        end, 80, 24)
        cancelBtn:SetPoint("RIGHT", confirmBtn.frame, "LEFT", -6, 0)

        popup:Hide()
        self.DeleteNotePopup = popup
    end

    local popup = self.DeleteNotePopup
    popup.msgFS:SetText(string.format("|cffffffffDelete \"%s\"?|r\nThis cannot be undone.", name))

    popup._confirmAction = function()
        NSI:RemoveReminder(name, true)
        ClearWindowNoteReferences(window, name, nil)
        if window then NSI:RefreshTimelineForMode() end
        popup:Hide()
    end

    popup:SetPoint("CENTER", UIParent, "CENTER")
    popup:Show()
end
