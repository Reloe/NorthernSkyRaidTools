local _, NSI = ... -- Internal namespace

--[[
    Boss Timeline Data

    Structure (nested by difficulty):
    NSI.BossTimelines[encounterID] = {
        Mythic = { ... },   -- Mythic difficulty timeline
        Heroic = { ... },   -- Heroic difficulty timeline
    }

    Each difficulty contains:
    {
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

    Category Keywords (comma-separated, e.g. "raid damage, debuff"):
    Priority order (highest to lowest):
    1.  raid damage      - Raid-wide damage requiring healing cooldowns
    2.  raid aoe         - Raid-wide AOE damage
    3.  raid soak        - Raid-wide soak mechanics
    4.  group soak       - Group soak mechanics requiring assignments
    5.  raid debuff      - Raid-wide debuff application
    6.  healing absorb   - Healing absorption effects
    7.  tankbuster       - Tank-specific burst damage
    8.  tank debuff      - Tank debuff mechanics
    9.  singletarget     - Single target mechanics
    10. debuffs          - Multiple debuff application
    11. debuff           - Single debuff application
    12. dispel           - Dispellable mechanics
    13. damage buff      - Damage increase buffs
    14. damage amp       - Damage amplification effects
    15. spread           - Spread/positioning mechanics
    16. frontal          - Frontal cone attacks
    17. knock            - Knockback mechanics
    18. soak             - General soak mechanics
    19. cc               - Crowd control mechanics
    20. interrupt        - Interruptible casts
    21. add spawn        - Add spawn events
    22. phase change     - Phase transition triggers
    23. event            - Special events
    24. boss immune      - Boss immunity phases
    25. intermission     - Intermission phases
]]

-- Initialize the BossTimelines table
NSI.BossTimelines = NSI.BossTimelines or {}

-- Category colors for timeline display
-- Maps category keywords to colors (supports compound categories like "raid damage, debuff")
-- Colors match wowutils colorMap
NSI.BossTimelineColors = {
    -- Raid damage categories (Red #B65552)
    ["raid damage"] = {0.71, 0.33, 0.32},
    ["raid aoe"] = {0.71, 0.33, 0.32},

    -- Soak categories
    ["raid soak"] = {0.75, 0.34, 0},        -- #bf5700 Orange
    ["group soak"] = {0.88, 0.47, 0.19},    -- #e07830 Light Orange
    ["soak"] = {0.50, 0, 0.50},             -- #800080 Purple Blue

    -- Debuff/Healing categories (Purple/Red)
    ["raid debuff"] = {0.61, 0.35, 0.71},   -- #9b59b6 Light Purple
    ["healing absorb"] = {0.91, 0.30, 0.24}, -- #e74c3c Bright Red
    ["debuffs"] = {0.50, 0, 0.50},          -- #800080 Purple
    ["debuff"] = {0.50, 0, 0.50},           -- #800080 Purple

    -- Tank categories (Brown)
    ["tankbuster"] = {0.43, 0.60, 0.74},    -- #6e98bd Medium Brown
    ["tank debuff"] = {0.43, 0.47, 0.74},   -- #6e78bd Deep Brown
    ["singletarget"] = {1, 0.45, 0.45},     -- #ff7373 Light Red
    ["frontal"] = {0.46, 0.74, 0.37},       -- #75bc5f Light Green

    -- Utility/Control categories
    ["dispel"] = {0, 0.48, 1},              -- #007bff Blue
    ["cc"] = {1, 1, 1},                     -- #FFFFFF White
    ["interrupt"] = {0, 0.75, 1},           -- #00bfff Light Sky Blue

    -- Buff categories (Gold)
    ["damage buff"] = {1, 0.84, 0},         -- #FFD700 Gold
    ["damage amp"] = {0.95, 0.77, 0.06},    -- #f1c40f Bright Gold

    -- Movement/Positioning categories
    ["spread"] = {0.10, 0.74, 0.61},        -- #1abc9c Teal
    ["knock"] = {0, 0.40, 0},               -- #006600 Forest Green

    -- Add spawn / Event / Phase categories (White)
    ["add spawn"] = {1, 1, 1},              -- #FFFFFF White
    ["phase change"] = {1, 1, 1},           -- #FFFFFF White
    ["event"] = {1, 1, 1},                  -- #FFFFFF White

    -- Boss immune / Intermission (Gray)
    ["boss immune"] = {0.58, 0.65, 0.65},   -- #95a5a6 Gray
    ["intermission"] = {0.50, 0.55, 0.55},  -- #7f8c8d Dark Gray
}

-- Category sort priority (lower = higher priority)
-- Matches BOSS_SPELL_TYPE_ORDER from wowutils
NSI.BossTimelineCategoryOrder = {
    ["raid damage"] = 1,
    ["raid aoe"] = 2,
    ["raid soak"] = 3,
    ["group soak"] = 4,
    ["raid debuff"] = 5,
    ["healing absorb"] = 6,
    ["tankbuster"] = 7,
    ["tank debuff"] = 8,
    ["singletarget"] = 9,
    ["debuffs"] = 10,
    ["debuff"] = 11,
    ["dispel"] = 12,
    ["damage buff"] = 13,
    ["damage amp"] = 14,
    ["spread"] = 15,
    ["frontal"] = 16,
    ["knock"] = 17,
    ["soak"] = 18,
    ["cc"] = 19,
    ["interrupt"] = 20,
    ["add spawn"] = 21,
    ["phase change"] = 22,
    ["event"] = 23,
    ["boss immune"] = 24,
    ["intermission"] = 25,
}

-- Categories considered "important" for healer filtering
-- These are mechanics that typically require healing CDs or raid coordination
NSI.BossTimelineImportantHealerCategories = {
    ["raid damage"] = true,
    ["raid aoe"] = true,
    ["raid soak"] = true,
    ["group soak"] = true,
    ["raid debuff"] = true,
    ["healing absorb"] = true,
    ["intermission"] = true,
}

-- Categories considered "important" for tank filtering
-- These are mechanics that typically require tank cooldowns or swaps
NSI.BossTimelineImportantTankCategories = {
    ["tankbuster"] = true,
    ["tank debuff"] = true,
    ["frontal"] = true,
}

-- Boss display modes for timeline
NSI.BossDisplayModes = {
    ["SHOW_ALL"] = "all",
    ["IMPORTANT_HEALER"] = "important_healer",
    ["IMPORTANT_TANK"] = "important_tank",
    ["COMBINED"] = "combined",
    ["COMBINED_IMPORTANT"] = "combined_important",
}

-- Check if an ability is considered "important" for healers based on its category
-- Returns true if any category keyword is in the healer important list, or if ability has important=true
function NSI:IsAbilityImportantForHealer(ability)
    -- Explicit important flag takes precedence
    if ability.important ~= nil then
        return ability.important
    end

    -- Check category keywords
    local categoryStr = ability.category
    if not categoryStr or categoryStr == "" then
        return false
    end

    for keyword in categoryStr:gmatch("([^,]+)") do
        keyword = strtrim(keyword):lower()
        if self.BossTimelineImportantHealerCategories[keyword] then
            return true
        end
    end

    return false
end

-- Check if an ability is considered "important" for tanks based on its category
-- Returns true if any category keyword is in the tank important list, or if ability has important=true
function NSI:IsAbilityImportantForTank(ability)
    -- Explicit important flag takes precedence
    if ability.important ~= nil then
        return ability.important
    end

    -- Check category keywords
    local categoryStr = ability.category
    if not categoryStr or categoryStr == "" then
        return false
    end

    for keyword in categoryStr:gmatch("([^,]+)") do
        keyword = strtrim(keyword):lower()
        if self.BossTimelineImportantTankCategories[keyword] then
            return true
        end
    end

    return false
end

-- Check if an ability is considered "important" for either healers or tanks
-- Returns true if any category keyword is in either important list, or if ability has important=true
function NSI:IsAbilityImportant(ability)
    return self:IsAbilityImportantForHealer(ability) or self:IsAbilityImportantForTank(ability)
end

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
    [3134] = "Nexus King Saladhaar",
    [3135] = "Dimensius the All Devouring",
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Difficulty ID to name mapping
NSI.DifficultyNames = {
    [15] = "Heroic",
    [16] = "Mythic",
}

-- Get current difficulty name, defaults to "Mythic" if unknown
function NSI:GetCurrentDifficultyName()
    local _, _, difficultyID = GetInstanceInfo()
    return self.DifficultyNames[difficultyID] or "Mythic"
end

-- Get the timeline data for a specific encounter and difficulty
-- Falls back to Mythic > Heroic > Normal if requested difficulty not available
function NSI:GetBossTimeline(encounterID, difficulty)
    local bossData = self.BossTimelines[encounterID]
    if not bossData then return nil end

    -- If difficulty specified, try that first
    if difficulty and bossData[difficulty] then
        return bossData[difficulty], difficulty
    end

    -- Auto-detect current difficulty
    local currentDiff = self:GetCurrentDifficultyName()
    if bossData[currentDiff] then
        return bossData[currentDiff], currentDiff
    end

    -- Fallback chain: Mythic > Heroic
    if bossData.Mythic then return bossData.Mythic, "Mythic" end
    if bossData.Heroic then return bossData.Heroic, "Heroic" end

    return nil
end

-- Get user-adjusted phase start time, or default if not set
function NSI:GetPhaseStart(encounterID, phaseNum, difficulty)
    -- Phase 1 always starts at 0
    if phaseNum == 1 then return 0 end

    local timeline = self:GetBossTimeline(encounterID, difficulty)
    if not timeline or not timeline.phases or not timeline.phases[phaseNum] then return 0 end

    -- Check for user adjustment
    if NSRT.PhaseTimings and NSRT.PhaseTimings[encounterID] and NSRT.PhaseTimings[encounterID][phaseNum] then
        return NSRT.PhaseTimings[encounterID][phaseNum]
    end

    return timeline.phases[phaseNum].start
end

-- Set user-adjusted phase start time
-- Also shifts all subsequent phases by the same delta
function NSI:SetPhaseStart(encounterID, phaseNum, time)
    -- Cannot adjust phase 1
    if phaseNum == 1 then return end

    -- Reject move if it would go before the previous phase
    local prevPhaseTime = self:GetPhaseStart(encounterID, phaseNum - 1)
    if time <= prevPhaseTime then
        return
    end

    if not NSRT.PhaseTimings then
        NSRT.PhaseTimings = {}
    end
    if not NSRT.PhaseTimings[encounterID] then
        NSRT.PhaseTimings[encounterID] = {}
    end

    -- Get the old time to calculate delta
    local oldTime = self:GetPhaseStart(encounterID, phaseNum)
    local delta = time - oldTime

    -- Set the moved phase's new time
    NSRT.PhaseTimings[encounterID][phaseNum] = time

    -- Shift all subsequent phases by the same delta
    if delta ~= 0 then
        local timeline = self:GetBossTimeline(encounterID)
        if timeline and timeline.phases then
            for otherPhaseNum, _ in pairs(timeline.phases) do
                if otherPhaseNum > phaseNum then
                    local otherOldTime = self:GetPhaseStart(encounterID, otherPhaseNum)
                    local newOtherTime = math.max(0, otherOldTime + delta)
                    NSRT.PhaseTimings[encounterID][otherPhaseNum] = newOtherTime
                end
            end
        end
    end
end

-- Reset phase timing to default
function NSI:ResetPhaseStart(encounterID, phaseNum)
    if NSRT.PhaseTimings and NSRT.PhaseTimings[encounterID] then
        NSRT.PhaseTimings[encounterID][phaseNum] = nil
    end
end

-- Get all abilities for an encounter with absolute times
function NSI:GetBossTimelineAbilities(encounterID, difficulty)
    local timeline, actualDifficulty = self:GetBossTimeline(encounterID, difficulty)
    if not timeline then return nil end

    -- Pre-calculate all phase start times for filtering
    local phaseStarts = {}
    local maxPhase = 0
    for phaseNum, _ in pairs(timeline.phases) do
        phaseStarts[phaseNum] = self:GetPhaseStart(encounterID, phaseNum, actualDifficulty)
        if phaseNum > maxPhase then
            maxPhase = phaseNum
        end
    end

    local result = {}

    for i, ability in ipairs(timeline.abilities) do
        local phaseStart = self:GetPhaseStart(encounterID, ability.phase, actualDifficulty)
        local absoluteTimes = {}

        -- Get the start time of the next phase (if it exists)
        -- Abilities from this phase should not extend past the next phase start
        local nextPhaseStart = nil
        if ability.phase < maxPhase then
            nextPhaseStart = phaseStarts[ability.phase + 1]
        end

        for _, time in ipairs(ability.times) do
            local absoluteTime = phaseStart + time
            -- Filter out abilities that occur after the next phase has started
            if not nextPhaseStart or absoluteTime < nextPhaseStart then
                table.insert(absoluteTimes, absoluteTime)
            end
        end

        -- Only add ability if it has any visible times
        if #absoluteTimes > 0 then
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
    end

    -- Build phases with adjusted times
    local phases = {}
    for phaseNum, phaseData in pairs(timeline.phases) do
        phases[phaseNum] = {
            name = phaseData.name,                                  -- May be nil
            start = self:GetPhaseStart(encounterID, phaseNum, actualDifficulty),
            color = phaseData.color,                                -- May be nil
        }
    end

    return result, timeline.duration, phases, actualDifficulty
end

-- Get encounter name from ID
function NSI:GetEncounterName(encounterID)
    return self.BossTimelineNames[encounterID] or ("Encounter " .. encounterID)
end
