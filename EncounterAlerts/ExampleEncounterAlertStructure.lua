NSRT.EncounterAlerts = {
    [3183] = {   -- encID
        [16] = { -- difficulty ID
            ["Soaks"] = {
                timers = {10, 20, 30},
                dur = 10,
                spellID = 370597,
                text = "Soak",
                phase = 1,
                name = "Debuffs",
                internalID = "Debuffs",
                encID = 3183,
                DisplayType = "Text", -- "Text"/"Bar"/"Icon/Circle"
                notsticky = true,      -- always true
                IsAlert = true,        -- always true
                countdown = nil,       -- nil/int
                TTSTimer = nil,        -- nil/int
                TTS = nil,             -- nil = defined by user settings but possible to be overwritten as false/true or string
                sound = nil,           -- nil/string
                HideTimer = nil,         -- nil or true
                HideSwipe = nil,         -- nil or true
                glowunit = nil,        -- nil/table
                textColors = nil,          -- nil/table
                barColors = nil,
                ringColors = nil,
                Ticks = nil,           -- nil/table
                ReloeReminder = true, -- bool (true when created in the code as a Reloe provided reminder)
                Version = {versionNumber = 2, [1] = {isTaunt = true}, [2] = {dur = 10}}, -- optional; only migration tables newer than the user's stored version overwrite existing saved values
                enabled = true,        -- bool
                loadConditions = {
                    ["Roles"] = {
                        ["TANK"] = nil,
                        ["HEALER"] = nil,
                        ["DAMAGER"] = nil,
                        ["MELEE"] = nil,
                        ["RANGED"] = nil,
                    },
                    ["Classes"] = {
                        ["WARRIOR"] = nil,
                        ["PALADIN"] = nil,
                        ["HUNTER"] = nil,
                        ["ROGUE"] = nil,
                        ["PRIEST"] = nil,
                        ["DEATHKNIGHT"] = nil,
                        ["SHAMAN"] = nil,
                        ["MAGE"] = nil,
                        ["WARLOCK"] = nil,
                        ["MONK"] = nil,
                        ["DRUID"] = nil,
                        ["DEMONHUNTER"] = nil,
                        ["EVOKER"] = nil,
                    },
                    ["SpecIDs"] = {
                        [250] = nil, -- Blood
                        [251] = nil, -- Frost DK
                        [252] = nil, -- Unholy
                        [577]  = nil, -- Havoc
                        [581]  = nil, -- Vengeance
                        [1480] = nil, -- Devourer
                        [102] = nil, -- Balance
                        [103] = nil, -- Feral
                        [104] = nil, -- Guardian
                        [105] = nil, -- Restoration Druiud
                        [1467] = nil, -- Devastation
                        [1468] = nil, -- Preservation
                        [1473] = nil, -- Augmentation
                        [253] = nil, -- Beast Mastery
                        [254] = nil, -- Marksmanship
                        [255] = nil, -- Survival
                        [62] = nil, -- Arcane
                        [63] = nil, -- Fire
                        [64] = nil, -- Frost Mage
                        [268] = nil, -- Brewmaster
                        [269] = nil, -- Windwalker
                        [270] = nil, -- Mistweaver
                        [65] = nil, -- Holy Paladin
                        [66] = nil, -- Protection Paladin
                        [70] = nil, -- Retribution
                        [256] = nil, -- Discipline
                        [257] = nil, -- Holy Priest
                        [258] = nil, -- Shadow
                        [259] = nil, -- Assassination
                        [260] = nil, -- Outlaw
                        [261] = nil, -- Subtlety
                        [262] = nil, -- Elemental
                        [263] = nil, -- Enhancement
                        [264] = nil, -- Restoration Shaman
                        [265] = nil, -- Affliction
                        [266] = nil, -- Demonology
                        [267] = nil, -- Destruction
                        [71] = nil, -- Arms
                        [72] = nil, -- Fury
                        [73] = nil, -- Protection Warrior
                    },
                    ["Names"] = {
                        ["example"] = true
                    }
                }
            }
        }
    }
}
