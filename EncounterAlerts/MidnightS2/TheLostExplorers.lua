local _, NSI = ... -- Internal namespace

local encID = 3497
-- /run NSAPI:DebugEncounter(3497)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end
