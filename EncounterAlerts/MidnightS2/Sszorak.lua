local _, NSI = ... -- Internal namespace

local encID = 3420
-- /run NSAPI:DebugEncounter(3420)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
end
