local _, NSI = ... -- Internal namespace
local L = NSI.L

local encID = 3177
-- /run NSAPI:DebugEncounter(3177)
NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert(L["ENCOUNTER_ALERT_KNOCK"], "Text", nil, 5, 1, encID)

        -- Boss appears to have same timers on all difficulties
        id = id or self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [14] = {12, 132, 252},
            [15] = {12, 132, 252},
            [16] = {12, 132, 252},
        }
        for i, v in ipairs(timers[id] or {}) do -- Primordial Roar
            Alert.time = v
            self:AddToReminder(Alert)
        end

        Alert.text, Alert.TTS = L["ENCOUNTER_ALERT_BREATH"], L["ENCOUNTER_ALERT_BREATH"]
        timers = {
            [0] = {},
            [14] = {102, 223, 343},
            [15] = {102, 223, 343},
            [16] = {102, 223, 343},
        }
        for i, v in ipairs(timers[id] or {}) do -- Void Breath
            Alert.time = v
            self:AddToReminder(Alert)
        end
    end
end