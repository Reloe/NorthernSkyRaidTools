local _, NSI = ... -- Internal namespace

local encID = 3492
-- /run NSAPI:DebugEncounter(3492)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    --[[
    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Ula'tek Tanks", internalID = "HitKnock", name = {"P1 Hit+Knock", nil, "P3 Hit+Knock"}, text = "Hit+Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = "Knock", dur = 5, spellID = 1298367,
        textColors = {1, 0, 0, 1}, loadConditions = tankConditions,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [=[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]=],
        },
        timers = {
            [15] = {{}, {}, {}},
            [16] = {{}, {}, {}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek Tanks", internalID = "Taunt", name = {"P1 Taunt", nil, "P3 Taunt"}, text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = true, TTSTimer = 0, dur = 5, sticky = 3,
        textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
        isConditional = {
            text = "This Alert only shows if you do not have threat on boss1.",
            func = [=[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]=],
        },
        timers = {
            [15] = {{}, {}, {}},
            [16] = {{}, {}, {}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = {"Ula'tek P1", nil, "Ula'tek P3"}, internalID = "Waves", name = {"Waves", nil, "Waves"}, text = "Waves", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1292403,
        timers = {
            [15] = {{}, {}, {}},
            [16] = {{}, {}, {}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = {"Ula'tek P1", nil, "Ula'tek P3"}, internalID = "Adds", name = {"Adds", nil, "Adds"}, text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = 1304012,
        timers = {
            [15] = {{}, {}, {}},
            [16] = {{}, {}, {}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = {"Ula'tek P1", "Ula'tek P2", "Ula'tek P3"}, internalID = "DamageAmpIn", name = {"Dmg amp", "Dmg amp", "Dmg amp"}, text = "Dmg amp in", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = 1286860,
        timers = {
            [15] = {{}, {}, {}},
            [16] = {{}, {}, {}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = {"Ula'tek P1", "Ula'tek P2", "Ula'tek P3"}, internalID = "DamageAmp", name = {"Dmg amp Bar", "Dmg amp Bar", "Dmg amp Bar"}, text = "Dmg amp", DisplayType = "Bar", encID = encID, phase = 1, TTS = false, dur = 20, spellID = 1299526,
        barColors = {1, 0, 0, 1},
        timers = {
            [15] = {{}, {}, {}},
            [16] = {{}, {}, {}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek P3", internalID = "PlatformBreak", name = "Platform Break", text = "Platform Break + Knock", DisplayType = "Text", encID = encID, phase = 3, TTS = "Knock", dur = 5, spellID = 1301510,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Ula'tek P3", internalID = "Debuffs", name = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 5, spellID = 1293046,
        timers = {
            [15] = {},
            [16] = {},
        },
    }
    self:AddEncounterAlert(data)
    ]]
end
