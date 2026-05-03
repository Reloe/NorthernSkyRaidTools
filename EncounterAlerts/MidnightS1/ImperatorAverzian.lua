local _, NSI = ... -- Internal namespace

local encID = 3176
-- /run NSAPI:DebugEncounter(3176)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local data = {name = "Soak", text = "Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 5.5, spellID = nil,
    overrides = {},
    timers = {
            [14] = {25.5, 33, 97.5, 105, 176.5, 184, 248.5, 256, 325.5, 333},
            [15] = {25.5, 33, 97.5, 105, 176.5, 184, 248.5, 256, 325.5, 333},
            [16] = {37.5, 45, 117.5, 125, 223.5, 231, 303.5, 311, 407.5, 415},
        },
    }
    self:AddEncounterAlert(data)
end