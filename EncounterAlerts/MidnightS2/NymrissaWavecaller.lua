local _, NSI = ... -- Internal namespace

local encID = 3379
-- /run NSAPI:DebugEncounter(3379)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end
