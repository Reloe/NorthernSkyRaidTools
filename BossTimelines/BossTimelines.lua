local _, NSI = ... -- Internal namespace

--[[
    Boss Timeline Data

    Structure:
    NSI.BossTimelines[encounterID] = {
        difficulty = string,        -- (optional) "Mythic", "Heroic", "Normal", "LFR"
        duration = number,          -- Total fight duration in seconds
        phases = {
            [phaseNum] = {
                start = number,     -- Default phase start time in seconds
                name = string,      -- (optional) Phase display name
                color = {r, g, b},  -- (optional) RGB color for phase (0-1 range)
            },
        },
        abilities = {
            {
                name = string,          -- Ability name
                spellID = number,       -- WoW spell ID for icon lookup
                category = string,      -- Comma-separated keywords (see below)
                phase = number,         -- Phase number (1, 2, 3, etc.)
                times = {number, ...},  -- Array of cast times (seconds from phase start)
                duration = number,      -- Ability duration in seconds (0 if instant)
            },
        },
    }

    Category Keywords (comma-separated, e.g. "raid damage, debuffs"):
    - raid damage / damage: Raid-wide damage requiring healing cooldowns
    - tankbuster / tank: Tank-specific mechanics (busters, swaps)
    - frontal: Frontal cone attacks (often combined with tankbuster)
    - movement: Positioning/movement mechanics
    - soak / group soak: Soak mechanics requiring assignments
    - debuffs: Debuff application mechanics
    - healing absorb: Healing absorption effects
    - knock: Knockback mechanics
    - event: Special event or intermission
    - intermission: Phase transition abilities
]]

-- Initialize the BossTimelines table
NSI.BossTimelines = NSI.BossTimelines or {}

-- Category colors for timeline display
-- Maps category keywords to colors (supports compound categories like "raid damage, debuffs")
NSI.BossTimelineColors = {
    -- Damage categories (Red)
    damage = {0.9, 0.3, 0.3},
    ["raid damage"] = {0.9, 0.3, 0.3},

    -- Tank categories (Blue)
    tank = {0.3, 0.5, 0.9},
    tankbuster = {0.3, 0.5, 0.9},
    frontal = {0.3, 0.5, 0.9},

    -- Movement categories (Yellow/Orange)
    movement = {0.9, 0.7, 0.2},
    knock = {0.9, 0.7, 0.2},

    -- Soak categories (Green)
    soak = {0.5, 0.9, 0.5},
    ["group soak"] = {0.5, 0.9, 0.5},

    -- Debuff/Healing categories (Pink/Magenta)
    debuffs = {0.9, 0.5, 0.7},
    ["healing absorb"] = {0.9, 0.5, 0.7},

    -- Event/Intermission categories (Purple)
    intermission = {0.7, 0.4, 0.9},
    event = {0.7, 0.4, 0.9},
}

-- Category sort priority (lower = higher priority)
NSI.BossTimelineCategoryOrder = {
    -- Damage first
    damage = 1,
    ["raid damage"] = 1,
    -- Then soak
    soak = 2,
    ["group soak"] = 2,
    -- Then tank
    tank = 3,
    tankbuster = 3,
    frontal = 3,
    -- Then debuffs
    debuffs = 4,
    ["healing absorb"] = 4,
    -- Then movement
    movement = 5,
    knock = 5,
    -- Then events/intermission
    event = 6,
    intermission = 6,
}

-- Parse a compound category string and return color and sort order
-- e.g., "raid damage, debuffs" -> color for "raid damage", order 1
function NSI:ParseCategoryForDisplay(categoryStr)
    if not categoryStr or categoryStr == "" then
        return {0.7, 0.7, 0.7}, 99, "unknown" -- default gray
    end

    local color = nil
    local order = 99
    local primaryCategory = "unknown"

    -- Split by comma and check each keyword
    for keyword in categoryStr:gmatch("([^,]+)") do
        keyword = strtrim(keyword):lower()

        -- Check for color match (use first match found)
        if not color and self.BossTimelineColors[keyword] then
            color = self.BossTimelineColors[keyword]
            primaryCategory = keyword
        end

        -- Check for sort order (use lowest/highest priority found)
        local keywordOrder = self.BossTimelineCategoryOrder[keyword]
        if keywordOrder and keywordOrder < order then
            order = keywordOrder
            if not color then
                primaryCategory = keyword
            end
        end
    end

    return color or {0.7, 0.7, 0.7}, order, primaryCategory
end

-- Encounter name lookup
NSI.BossTimelineNames = {
    [3176] = "Imperator Averzian",
    [3177] = "Vorasius",
    [3178] = "Vaelgor & Ezzorak",
    [3179] = "Fallen King Salhadaar",
    [3180] = "Lightblinded Vanguard",
    [3181] = "Crown of the Cosmos",
    [3182] = "Belo'ren",
    [3183] = "Midnight Falls",
    [3306] = "Chimaerus",
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Get user-adjusted phase start time, or default if not set
function NSI:GetPhaseStart(encounterID, phaseNum)
    -- Phase 1 always starts at 0
    if phaseNum == 1 then return 0 end

    local timeline = self.BossTimelines[encounterID]
    if not timeline or not timeline.phases[phaseNum] then return 0 end

    -- Check for user adjustment
    if NSRT.PhaseTimings and NSRT.PhaseTimings[encounterID] and NSRT.PhaseTimings[encounterID][phaseNum] then
        return NSRT.PhaseTimings[encounterID][phaseNum]
    end

    return timeline.phases[phaseNum].start
end

-- Set user-adjusted phase start time
function NSI:SetPhaseStart(encounterID, phaseNum, time)
    -- Cannot adjust phase 1
    if phaseNum == 1 then return end

    if not NSRT.PhaseTimings then
        NSRT.PhaseTimings = {}
    end
    if not NSRT.PhaseTimings[encounterID] then
        NSRT.PhaseTimings[encounterID] = {}
    end

    NSRT.PhaseTimings[encounterID][phaseNum] = time
end

-- Reset phase timing to default
function NSI:ResetPhaseStart(encounterID, phaseNum)
    if NSRT.PhaseTimings and NSRT.PhaseTimings[encounterID] then
        NSRT.PhaseTimings[encounterID][phaseNum] = nil
    end
end

-- Get all abilities for an encounter with absolute times
function NSI:GetBossTimelineAbilities(encounterID)
    local timeline = self.BossTimelines[encounterID]
    if not timeline then return nil end

    local result = {}

    for i, ability in ipairs(timeline.abilities) do
        local phaseStart = self:GetPhaseStart(encounterID, ability.phase)
        local absoluteTimes = {}

        for _, time in ipairs(ability.times) do
            table.insert(absoluteTimes, phaseStart + time)
        end

        -- Parse compound category for color and sort order
        local color, sortOrder, primaryCategory = self:ParseCategoryForDisplay(ability.category)

        table.insert(result, {
            name = ability.name,
            spellID = ability.spellID,
            category = ability.category,           -- Keep original for tooltip display
            primaryCategory = primaryCategory,     -- Parsed primary category
            sortOrder = sortOrder,                 -- For sorting in timeline
            phase = ability.phase,
            times = absoluteTimes,
            duration = ability.duration,
            color = color,
        })
    end

    -- Build phases with adjusted times
    local phases = {}
    for phaseNum, phaseData in pairs(timeline.phases) do
        phases[phaseNum] = {
            name = phaseData.name,                                  -- May be nil
            start = self:GetPhaseStart(encounterID, phaseNum),
            color = phaseData.color,                                -- May be nil
        }
    end

    return result, timeline.duration, phases, timeline.difficulty
end

-- Get encounter name from ID
function NSI:GetEncounterName(encounterID)
    return self.BossTimelineNames[encounterID] or ("Encounter " .. encounterID)
end
