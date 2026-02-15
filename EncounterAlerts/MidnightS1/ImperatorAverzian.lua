local _, NSI = ... -- Internal namespace

local encID = 3176
-- /run NSAPI:DebugEncounter(3176)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Soak", "Text", nil, 5.5, 1, encID) -- Group Soaks

        local id = self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [16] = {37.5, 45, 117.5, 125, 223.5, 231, 303.5, 311, 407.5, 415}, -- Mythic only for now
        }
        for i, v in ipairs(timers[id]) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

    end
end