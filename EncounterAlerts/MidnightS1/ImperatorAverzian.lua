local _, NSI = ... -- Internal namespace

local encID = 3176
-- /run NSAPI:DebugEncounter(3176)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local enc = NSRT.EncounterAlerts[encID]

    local function Add(key, alert, timers, durOverrides)
        NSI:AddEncounterAlert(encID, key, alert, timers, durOverrides, true, true)
    end

    Add("Soak1", NSI:CreateDefaultAlert("Soak", "Text", nil, 5.5, 1, encID), {
        [0]  = {},
        [14] = {25.5, 33, 97.5, 105, 176.5, 184, 248.5, 256, 325.5, 333},
        [15] = {25.5, 33, 97.5, 105, 176.5, 184, 248.5, 256, 325.5, 333},
        [16] = {37.5, 45, 117.5, 125, 223.5, 231, 303.5, 311, 407.5, 415},
    })
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)
end
