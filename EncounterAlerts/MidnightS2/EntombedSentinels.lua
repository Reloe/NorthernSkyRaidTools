local _, NSI = ... -- Internal namespace

local encID = 3445
-- /run NSAPI:DebugEncounter(3445)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local data = {group = "Sentinels", internalID = "PoisonHits", name = "Poison Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1}, customIcon = 1284458,
        isConditional = {
            text = "This Alert only shows if you have threat on boss1.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] ={
                {6, 28},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
            },
            [16] ={
                {6, 28},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
                {6, 28, 49.9, 71.8},
            }
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Sentinels", internalID = "BloodHits", name = "Blood Tank-Hit", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {1, 0, 0, 1}, customIcon = 1284487,
        isConditional = {
            text = "This Alert only shows if you have threat on boss2.",
            func = [[return function() local threat = UnitThreatSituation("player", "boss2") return threat and threat >= 2 end]],
        },
        phaseTimers = {
            [15] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            },
            [16] ={
                {8.5, 30.4},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
                {8.5, 30.4, 52.3, 74.2},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "BloodSoak", name = "Blood Soak", text = "Blood-Soak", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 8,
        textColors = {1, 0.37, 0.25, 1}, customIcon = 1288232,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss2.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss2") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {26.25},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
            },
            [16] ={
                {26.25},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
                {26.25, 67.5},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "PoisonAdd", name = "Poison Add", text = "Poison Add", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6,
        textColors = {0.62, 1, 0.25, 1}, customIcon = 1284251,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss1.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss1") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {13.7},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
            },
            [16] ={
                {13.7},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
                {13.7, 67},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "OrbSpawn", name = "Orb Spawn", text = "Orbs", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6,
        customIcon = 1284434,
        isConditional = {
            text = "This Alert only shows if you are within 40y of boss1.",
            func = [[return function() local minRange = NSAPI and NSAPI:GetRange("boss1") return minRange and minRange < 40 end]],
        },
        phaseTimers = {
            [15] ={
                {17.1},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
            },
            [16] ={
                {17.1},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
                {17.1, 50},
            }
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sentinels", internalID = "TransitionDebuffs", name = "Transition Debuffs", text = "Number Game", DisplayType = "Text", encID = encID, phase = 1, TTS = "Spread", dur = 8,
        customIcon = 1284590,
        phaseTimers = {
            [15] ={
                {46.2},
                {91},
                {91},
                {91},
                {91},
            },
            [16] ={
                {46.2},
                {91},
                {91},
                {91},
                {91},
            }
        },
    }
    self:AddEncounterAlert(data)
end

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e ~= "ENCOUNTER_TIMELINE_EVENT_ADDED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end

    table.insert(self.Timelines, now)

    local addedcount = 0
    for _, timestamp in ipairs(self.Timelines) do
        if now < timestamp + 0.3 then addedcount = addedcount + 1 end
    end
    if addedcount >= 8 then
        self.Phase = self.Phase + 1
        self:StartReminders(self.Phase)
        self.Timelines = {}
        self.PhaseSwapTime = now
    end
end
