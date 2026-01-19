local _, NSI = ... -- Internal namespace

local encID = 3177
-- /run NSAPI:DebugEncounter(3177)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START   
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Knock", "Text", nil, 5, 1, encID)
        
        -- Boss appears to have same timers on all difficulties
        local id = self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [14] = {12.2, 133.3, 253.7},
            [15] = {12.2, 133.3, 253.7},
            [16] = {12.2, 133.3, 253.7},
        }
        for i, v in ipairs(timers[id]) do -- Primordial Roar
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS = "Breath", "Breath"
        timers = {
            [0] = {},
            [14] = {102.3, 223.3, 343.8},
            [15] = {102.3, 223.3, 343.8},
            [16] = {102.3, 223.3, 343.8},
        }
        for i, v in ipairs(timers[id]) do -- Void Breath
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS = "Dodge", "Dodge"
        timers = {
            [0] = {},
            [14] = {81, 91, 202, 212, 322, 332},
            [15] = {81, 91, 202, 212, 322, 332},
            [16] = {81, 91, 202, 212, 322, 332},
        }
        for i, v in ipairs(timers[id]) do -- Dodge during adds
            Alert.time = v
            self:AddToReminder(Alert)
        end
    end
end