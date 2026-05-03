local _, NSI = ... -- Internal namespace

local encID = 3177
-- /run NSAPI:DebugEncounter(3177)
NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local data = {name = "Knock", text = "Knock", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5, spellID = nil,
    overrides = {},
    timers = {
            [14] = {12, 132, 252},
            [15] = {12, 132, 252},
            [16] = {12, 132, 252},
        },
    }
    self:AddEncounterAlert(data)
    data.name, data.text = "Breath", "Breath"
    data.timers = {
        [14] = {102, 223, 343},
        [15] = {102, 223, 343},
        [16] = {102, 223, 343},
    }
    self:AddEncounterAlert(data)
end
