local _, NSI = ... -- Internal namespace

local encID = 3445
-- /run NSAPI:DebugEncounter(3445)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end
