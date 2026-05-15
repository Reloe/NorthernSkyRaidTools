local _, NSI = ... -- Internal namespace

local encID = 3159
-- /run NSAPI:DebugEncounter(3159)
NSI.InitializeAlerts[encID] = function(self)
    local data = {internalID = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = nil,
        timers = {
            [16] = {23, 72, 159, 208, 295, 344, 431, 480},
        },
    }
    self:AddEncounterAlert(data)
    local data = {internalID = "Shrooms", text = "Shrooms", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = nil,
        timers = {
            [16] = {120, 256, 392, 528},
        },
    }
    self:AddEncounterAlert(data)
end
