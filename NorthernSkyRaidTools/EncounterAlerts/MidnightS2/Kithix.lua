local _, NSI = ... -- Internal namespace

local encID = 3513
-- /run NSAPI:DebugEncounter(3513)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end
