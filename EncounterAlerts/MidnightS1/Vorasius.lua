local _, NSI = ... -- Internal namespace

local encID = 3177
-- /run NSAPI:DebugEncounter(3177)
NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local enc = NSRT.EncounterAlerts[encID]

    local function Add(key, alert, timers, durOverrides)
        NSI:AddEncounterAlert(encID, key, alert, timers, durOverrides, true, true)
    end

    -- Boss appears to have same timers on all difficulties
    local knockTimers = { [14] = { 12, 132, 252 }, [15] = { 12, 132, 252 }, [16] = { 12, 132, 252 } }
    Add("Knock1", NSI:CreateDefaultAlert("Knock", "Text", nil, 5, 1, encID), knockTimers)

    local breathTimers = { [14] = { 102, 223, 343 }, [15] = { 102, 223, 343 }, [16] = { 102, 223, 343 } }
    Add("Breath1", NSI:CreateDefaultAlert("Breath", "Text", nil, 5, 1, encID), breathTimers)
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)
end
