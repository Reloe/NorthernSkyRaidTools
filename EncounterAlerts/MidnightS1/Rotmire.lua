local _, NSI = ... -- Internal namespace

local encID = 3159
-- /run NSAPI:DebugEncounter(3159)


NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {internalID = "Adds", text = "Adds", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = nil,
        timers = {
            [16] = {23, 72, 159, 208, 295, 344, 431, 480},
        },
    }
    self:AddEncounterAlert(data)
    local data = {internalID = "Shrooms", text = "Shrooms", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = nil,
        timers = {
            [16] = {120, 256, 392, 528},
        },
    }
    self:AddEncounterAlert(data)
    local data = {text = nil, internalID = "InterruptDisplay", name = "Interrupt Display", DisplayType = "Text", encID = encID, phase = nil, TTS = false, dur = 5, spellID = nil,
    customIcon = 6552, id = 0.1, timers = nil, difficulties = {16},
    overrides = {BlockCopy = true, enabled = true},
    Preview = [[return function()
        print("|cFF00FFFFNSRT:|r no preview available for this Alert. You can change Interrupt settings in the Interrupt Display menu.")
    end]],
    }
    self:AddEncounterAlert(data)
    local data = {Version = {versionNumber = 2, [1] = {isTaunt = true}, [2] = {sticky = 3}}, group = "Rotmire Tanks", internalID = "Taunts", text = "Taunt", customIcon = 355, DisplayType = "Text", encID = encID, phase = 1, TTS = "Taunt", TTSTimer = 0, dur = 5, sticky = 3, spellID = nil,
    overrides =
        {textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
            isConditional = {
                text = "This Alert only shows if you do not have threat on the Boss.",
                func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
            },
        },
        timers = {
            [16] = {24.5, 36.5, 48.5, 60.5, 73.5, 85.5, 97.5, 109.5,
                    160.6, 172.6, 184.6, 196.6, 209.6, 221.6, 233.6, 245.6,
                    296.6, 308.6, 320.6, 332.6, 345.6, 357.6, 369.6, 381.6,
                    432.6, 444.6, 456.6, 468.6, 481.6, 493.6, 505.6, 507.6},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Rotmire Tanks", internalID = "Tankhits", text = "Tank-Hit", customIcon = 134201, DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = nil,
    overrides =
        {textColors = {1, 0, 0, 1}, loadConditions = tankConditions,
            isConditional = {
                text = "This Alert only shows if you have threat on the Boss.",
                func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
            },
        },
        timers = {
            [16] = {26, 38, 50, 62, 75, 87, 99, 111,
                    162.1, 174.1, 186.1, 198.1, 211.1, 223.1, 235.1, 247.1,
                    298.1, 310.1, 322.1, 334.1, 347.1, 359.1, 371.1, 383.1,
                    434.1, 446.1, 458.1, 470.1, 483.1, 495.1, 507.1, 509.1},
        },
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    local id = self:DifficultyCheck(16) or 0
    local interrupts = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].InterruptDisplay
    if interrupts and interrupts.enabled and self:EvaluateLoad(interrupts) and id == 16 then
        self:ReadInterruptNote(1)
        if (not self.Interrupts.myTrackedID) or (not self.Interrupts.myTrackedID == 2) then return end
        self:EncounterRegister("InterruptDisplay", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"}, true, "boss2")
        self:EncounterFunction("InterruptDisplay", function(_, e, unit, ...)
            if e == "UNIT_SPELLCAST_START" then
                if UnitIsEnemy(unit, "player") then
                    local info = {spellID = 1221714, dur = 6}
                    self:InterruptOnCastStart(info)
                    if self.ResetTimer then
                        self.ResetTimer:Cancel()
                    end
                    self.ResetTimer = C_Timer.NewTimer(10, function()
                        self:ResetInterrupts()
                    end)
                end
            elseif e == "UNIT_SPELLCAST_INTERRUPTED" then
                if UnitIsEnemy(unit, "player") then
                    self:OnInterrupt()
                end
            elseif e == "UNIT_SPELLCAST_STOP" then
                if UnitIsEnemy(unit, "player") then
                    self:OnCastStop()
                end
            elseif e == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
                if UnitExists("boss2") and UnitIsEnemy("boss2", "player") then
                    self:DisplayInterrupt()
                end
                if not UnitExists("boss2") then
                    self:ResetInterrupts()
                end
            end
        end)
    end
end

NSI.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    self:HideInterrupt()
end
