local _, NSI = ... -- Internal namespace

--[[
    Boss Timeline Data

    Structure:
    NSI.BossTimelines[encounterID] = {
        duration = number,          -- Total fight duration in seconds
        phases = {
            [phaseNum] = {
                name = string,      -- Phase display name
                start = number,     -- Default phase start time in seconds
                color = {r, g, b},  -- RGB color for phase (0-1 range)
            },
        },
        abilities = {
            {
                name = string,          -- Ability name
                spellID = number,       -- WoW spell ID for icon lookup
                category = string,      -- "damage", "tank", "movement", "soak", "intermission"
                phase = number,         -- Phase number (1, 2, 3, etc.)
                times = {number, ...},  -- Array of cast times (seconds from phase start)
                duration = number,      -- Ability duration in seconds
                important = boolean,    -- Whether this is a major CD event
            },
        },
    }

    Categories:
    - damage: Raid-wide damage requiring healing cooldowns
    - tank: Tank-specific mechanics (busters, swaps)
    - movement: Positioning/movement mechanics
    - soak: Soak mechanics requiring assignments
    - intermission: Phase transition abilities
]]

-- Initialize the BossTimelines table
NSI.BossTimelines = NSI.BossTimelines or {}

-- Category colors for timeline display
NSI.BossTimelineColors = {
    damage = {0.9, 0.3, 0.3},       -- Red
    tank = {0.3, 0.5, 0.9},         -- Blue
    movement = {0.9, 0.7, 0.2},     -- Yellow/Orange
    soak = {0.5, 0.9, 0.5},         -- Green
    intermission = {0.7, 0.4, 0.9}, -- Purple
}

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

        table.insert(result, {
            name = ability.name,
            spellID = ability.spellID,
            category = ability.category,
            phase = ability.phase,
            times = absoluteTimes,
            duration = ability.duration,
            important = ability.important,
            color = self.BossTimelineColors[ability.category],
        })
    end

    -- Build phases with adjusted times
    local phases = {}
    for phaseNum, phaseData in pairs(timeline.phases) do
        phases[phaseNum] = {
            name = phaseData.name,
            start = self:GetPhaseStart(encounterID, phaseNum),
            color = phaseData.color,
        }
    end

    return result, timeline.duration, phases
end

-- Get encounter name from ID
function NSI:GetEncounterName(encounterID)
    return self.BossTimelineNames[encounterID] or ("Encounter " .. encounterID)
end
