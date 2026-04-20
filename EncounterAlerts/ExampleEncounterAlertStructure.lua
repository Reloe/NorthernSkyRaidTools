NSRT.EncounterAlerts = {
    [3183] = {   -- encID
        [16] = { -- difficulty ID
            ["Soaks"] = {
                timers = {
                    [1] = { 10, 20, 30 }, -- timers for phase 1
                    [2] = { 20, 30, 40 }, -- timers for phase 2
                },
                dur = 10,
                spellID = 370597,
                text = "Soak",
                notsticky = true,      -- always true
                IsAlert = true,        -- always true
                countdown = nil,       -- nil/int
                TTSTimer = nil,        -- nil/int
                TTS = nil,             -- nil = defined by user settings but possible to be overwritten as false/true or string
                sound = nil,           -- nil/string
                skipdur = nil,         -- nil or true
                glowunit = nil,        -- nil/table
                colors = nil,          -- nil/table
                Ticks = nil,           -- nil/table
                IconOverwrite = nil,   -- nil or true
                BarOverwrite = nil,    -- nil or true
                CircleOverwrite = nil, -- nil or true
                reloeReminder = false, -- bool (true when created in the code as a Reloe provided reminder)
                enabled = true,        -- bool
                loadConditions = {
                    ["Roles"] = {
                        ["TANK"] = false,
                        ["HEALER"] = false,
                        ["DAMAGER"] = false,
                        ["MELEE"] = false,
                        ["RANGED"] = false,
                    },
                    ["Classes"] = {
                        ["WARRIOR"] = false,
                        ["PALADIN"] = false,
                        ["HUNTER"] = false,
                        ["ROGUE"] = false,
                        ["PRIEST"] = false,
                        ["DEATHKNIGHT"] = false,
                        ["SHAMAN"] = false,
                        ["MAGE"] = false,
                        ["WARLOCK"] = false,
                        ["MONK"] = false,
                        ["DRUID"] = false,
                        ["DEMONHUNTER"] = false,
                        ["EVOKER"] = false,
                    },
                    ["SpecIDs"] = {
                        [250] = false,  -- Blood
                        [251] = false,  -- Frost
                        [252] = false,  -- Unholy
                        [102] = false,  -- Balance
                        [103] = false,  -- Feral
                        [104] = false,  -- Guardian
                        [105] = false,  -- Restoration
                        [62] = false,   -- Arcane
                        [63] = false,   -- Fire
                        [64] = false,   -- Frost
                        [253] = false,  -- Beast Mastery
                        [254] = false,  -- Marksmanship
                        [255] = false,  -- Survival
                        [259] = false,  -- Assassination
                        [260] = false,  -- Outlaw
                        [261] = false,  -- Subtlety
                        [256] = false,  -- Discipline
                        [257] = false,  -- Holy
                        [258] = false,  -- Shadow
                        [577] = false,  -- Havoc
                        [581] = false,  -- Vengeance
                        [1480] = false, -- Devourer
                        [1467] = false, -- Devastation
                        [1468] = false, -- Preservation
                        [1473] = false, -- Augmentation
                    },
                    ["Names"] = {
                        ["example"] = true
                    }
                }
            }
        }
    }
}
