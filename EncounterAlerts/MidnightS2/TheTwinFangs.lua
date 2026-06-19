local _, NSI = ... -- Internal namespace

local encID = 3421
-- /run NSAPI:DebugEncounter(3421)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end
