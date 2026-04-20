local _, NSI = ... -- Internal namespace

local encID = 3177
-- /run NSAPI:DebugEncounter(3177)
NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local function Add(diffID, name, alertDef)
        NSI:AddEncounterAlert(encID, diffID, name, alertDef)
    end

    -- Boss has the same timers on all difficulties
    local knockTimers  = { [1] = { 12, 132, 252 } }
    local breathTimers = { [1] = { 102, 223, 343 } }
    for _, diff in ipairs({ 14, 15, 16 }) do
        Add(diff, "Knock",  NSI:MakeEncounterAlert("Knock",  nil, 5, "Text", knockTimers))
        Add(diff, "Breath", NSI:MakeEncounterAlert("Breath", nil, 5, "Text", breathTimers))
    end
end

NSI.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    id = id or self:DifficultyCheck(14) or 0
    self:FireEncounterAlerts(encID, id)
end
