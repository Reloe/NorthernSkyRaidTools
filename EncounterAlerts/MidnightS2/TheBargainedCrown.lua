local _, NSI = ... -- Internal namespace

local encID = 3429
-- /run NSAPI:DebugEncounter(3429)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end
