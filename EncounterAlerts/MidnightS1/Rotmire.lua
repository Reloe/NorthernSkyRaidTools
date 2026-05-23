local _, NSI = ... -- Internal namespace

local encID = 3159
-- /run NSAPI:DebugEncounter(3159)

NSI.InitializeMandatoryAlerts[encID] = function(self)
    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
    local data = {text = nil, internalID = "InterruptDisplay", name = "Interrupt Display", DisplayType = "Text", encID = encID, phase = nil, TTS = false, dur = 5, spellID = nil, MandatoryAlert = true,
    customIcon = 6552, id = 0.1, timers = nil, difficulties = {16},
    overrides = {BlockCopy = true},
    Preview = [[return function()
        print("|cFF00FFFFNSRT:|r no preview available for this Alert. You can change Interrupt settings in the Interrupt Display menu.")
    end]],
    }
    self:AddEncounterAlert(data)

end

NSI.InitializeAlerts[encID] = function(self)
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
