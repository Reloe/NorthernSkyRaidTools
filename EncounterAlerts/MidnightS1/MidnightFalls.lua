local _, NSI = ... -- Internal namespace

local encID = 3183
-- /run NSAPI:DebugEncounter(3183)

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true

    local data = {group = "Lura P1", internalID = "MemoryGame", text = "Memory Game", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 4, spellID = nil,
    timers = {
            [15] = {10, 80, 150},
            [16] = {33, 95, 157},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P1", internalID = "Glaives", text = "Glaives", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = nil,
    timers = {
            [15] = {38, 108, 178},
            [16] = {29, 91, 153},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P1", internalID = "Interrupts", text = "Interrupts", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 6, spellID = nil,
    timers = {
            [15] = {59, 129},
            [16] = {6.4, 68.4, 130.4},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P1", internalID = "Beams", text = "Beams", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5, spellID = nil,
    timers = {
            [16] = {57, 119},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P1 Transition", internalID = "Transition Beams", name = "Beams", text = "Beams", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 3, spellID = nil,
    timers = {
            [16] = {10.7, 15.7, 20.7, 25.7, 30.7, 35.7},
        },
    }
    self:AddEncounterAlert(data)

    local oldTankAlertIDs = {
        "P1 Tank-Hit First",
        "P1 Tank-Hit Second",
        "P2 Tank-Hit First",
        "P2 Tank-Hit Second",
        "P3 Tank-Hit",
        "P1 Taunt First",
        "P1 Taunt Second",
        "P2 Taunts First",
        "P2 Taunts Second",
    }
    for _, internalID in ipairs(oldTankAlertIDs) do
        self:RemoveEncounterAlert(encID, 16, internalID)
    end

    local data = {group = {"Lura Tanks", nil, "Lura Tanks"}, internalID = "Lura Tank-Hits", name = {"P1 Tank-Hits", nil, "P2 Tank-Hits"}, text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = nil,
    overrides =
        {textColors = {1, 0, 0, 1}, loadConditions = tankConditions,
            isConditional = {
                text = "This Alert only shows if you have threat on the Boss.",
                func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat >= 2 end]],
            },
        },
    timers = {
            [16] = {
                {21.5, 41.5, 61.5, 81.5, 101.5, 121.5, 141.5, 161.5},
                {},
                {21.5, 41.5, 61.5, 81.5},
            },
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura Tanks", internalID = "Lura Tank-Hits_P4", name = "P3 Tank-Hits", text = "Tank-Hit", DisplayType = "Text", encID = encID, phase = 4, TTS = false, dur = 6, spellID = nil,
    overrides = {textColors = {1, 0, 0, 1}, loadConditions = tankConditions},
    timers = {
            [16] = {41.5, 71.5, 101.5, 131.5, 161.5},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, isTaunt = true}, group = {"Lura Tanks", nil, "Lura Tanks"}, internalID = "Lura Taunts", name = {"P1 Taunts", nil, "P2 Taunts"}, text = "Taunt", DisplayType = "Text", encID = encID, phase = 1, TTSTimer = 0, TTS = true, dur = 6, spellID = nil,
    overrides =
        {textColors = {0, 1, 0, 1}, loadConditions = tankConditions, isTaunt = true,
            isConditional = {
                text = "This Alert only shows if you do not have threat on the Boss.",
                func = [[return function() local threat = UnitThreatSituation("player", "boss1") return threat and threat < 2 end]],
            },
        },
    timers = {
            [16] = {
                {25, 45, 65, 85, 105, 125, 145, 165},
                {},
                {25, 45, 65, 85},
            },
        },
    }
    self:AddEncounterAlert(data)


    local data = {group = "Lura P1 Transition", internalID = "Full Blaze", text = "Full Blaze", DisplayType = "Text", encID = encID, phase = 2, TTS = false, dur = 3, spellID = nil,
    overrides = {textColors = {1, 0, 0, 1}},
    timers = {
            [16] = {37.7},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, dur = 3}, group = "Lura P2", name = "Seed-Drop", internalID = "Seed-Drop", text = "Seed-Drop", DisplayType = "Bar", encID = encID, phase = 3, TTS = false, dur = 3, spellID = 1253031,
    overrides = {countdown = 3, barColors = {0, 1, 0, 1},
        isConditional = {
            text = "This Alert only shows if you are holding a crystal at that time.",
            func = [[return function() return C_ActionBar.HasExtraActionBar() end]],
        },
    enabled = true},
    timers = {
            [16] = {17.5, 25, 47.5, 55, 77.5, 85},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1}, group = "Lura P2", name = "non-conditional Seed-Drop", internalID = "Old-Seed-Drop", text = "Seed-Drop", DisplayType = "Bar", encID = encID, phase = 3, TTS = false, dur = 5, spellID = 1253031,
    overrides = {countdown = 3, barColors = {0, 1, 0, 1}, enabled = false},
    timers = {
            [16] = {17.5, 25, 47.5, 55, 77.5, 85},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P2 Soaks", internalID = "Galvanize", name = "Generic Soak", text = "Soaks", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 7, spellID = nil,
    timers = {
            [15] = {20, 50, 80},
            [16] = {19, 49, 79},
        },
    }
    self:AddEncounterAlert(data)

    local markers = {"Star", "Orange", "Skull", "Cross"}
    local numbers = {1, 2, 8, 7}
    for i=1, 4 do
        local data = {group = "Lura P2 Soaks", internalID = "Soak "..markers[i], name = markers[i].." Soak", text = "Soak {rt"..numbers[i].."}",
        DisplayType = "Text", encID = encID, phase = 3, TTS = "Soak "..markers[i], dur = 7, spellID = nil,
        overrides = {enabled = false},
        timers = {
                [16] = {19, 49, 79},
            },
        }
        self:AddEncounterAlert(data)
    end

    local data = {group = "Lura P2", internalID = "Spread", text = "Spread", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 5, spellID = nil,
    timers = {
            [16] = {27.8, 57.8, 87.8, 105},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P2", internalID = "Orbs", text = "Orbs", DisplayType = "Text", encID = encID, phase = 3, TTS = false, dur = 5, spellID = nil,
    timers = {
            [15] = {35.5, 65.5, 95.5},
            [16] = {35.5, 65.5, 95.5},
        },
    }
    self:AddEncounterAlert(data)
    self:RemoveEncounterAlert(encID, 16, "Crystal Use")

    local data = {group = "Lura P3", internalID = "HC Soaks", text = "Soaks", DisplayType = "Text", encID = encID, phase = 4, TTS = true, dur = 5, spellID = nil,
    timers = {
            [15] = {31, 69, 107},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P3", internalID = "Move", text = "Move", DisplayType = "Text", encID = encID, phase = 4, TTS = true, TTSTimer = 0, dur = 5, spellID = nil,
    timers = {
            [15] = {65, 120},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P3 Left", internalID = "Left Memory Game", text = "Memory Game", DisplayType = "Text", encID = encID, phase = 4, TTS = true, dur = 5, spellID = nil,
    overrides = {enabled = false},
    timers = {
            [16] = {40, 75, 150},
        },
    }
    self:AddEncounterAlert(data)
    data.internalID = "Right Memory Game"
    data.group = "Lura P3 Right"
    data.timers = {
        [16] = {20, 95, 130},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P3 Left", internalID = "Left Soaks", text = "Soaks", DisplayType = "Text", encID = encID, phase = 4, TTS = true, TTSTimer = 2, dur = 5, spellID = nil,
    overrides = {enabled = false},
    timers = {
            [16] = {18.2, 90.2, 128.2},
        },
    }
    self:AddEncounterAlert(data)
    data.internalID = "Right Soaks"
    data.group = "Lura P3 Right"
    data.timers = {
        [16] = {38, 73, 148},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P3 Left", internalID = "Left Soak-Time", text = "Soak-Time", DisplayType = "Bar", encID = encID, phase = 4, TTS = false, dur = 20, spellID = 1266897,
    overrides = {enabled = false},
    timers = {
            [16] = {38.7, 110.7, 148.7},
        },
    }
    self:AddEncounterAlert(data)
    data.internalID = "Right Soak-Time"
    data.group = "Lura P3 Right"
    data.timers = {
        [16] = {58.5, 93.5, 168.5},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P3 Left", internalID = "Left Stars", text = "Stars", DisplayType = "Text", encID = encID, phase = 4, TTS = false, dur = 4, spellID = nil,
    overrides = {enabled = false},
    timers = {
            [16] = {20.4, 28.4, 36.4, 44.4, 52.4, 79.4, 87.4, 95.4, 103.4},
        },
    }
    self:AddEncounterAlert(data)
    data.internalID = "Right Stars"
    data.group = "Lura P3 Right"
    data.timers = {
        [16] = {24.2, 32.2, 40.2, 48.2, 75.2, 83.2, 91.2, 99.2, 107.2},
    }
    self:AddEncounterAlert(data)
    data.internalID = "Final Slice Stars"
    data.group = "Lura P3"
    data.overrides = {}
    data.timers = {
        [16] = {130.4, 137.2, 144.4, 150.2, 157.4, 164.2},
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P4", internalID = "Blazes", text = "Blazes", DisplayType = "Text", encID = encID, phase = 5, TTS = true, dur = 5, spellID = nil,
    timers = {
            [16] = {12.7, 32.7, 52.7, 72.7},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Lura P4", internalID = "P4 Move", name = "Move", text = "Move", DisplayType = "Text", encID = encID, phase = 5, TTS = true, TTSTimer = 0, dur = 5, spellID = nil,
    timers = {
            [16] = {19.8, 39.8, 59.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {
        internalID = "CrystalDropTimer",
        name = "Time to Pick Crystal",
        text = "PICK UP",
        DisplayType = "Bar",
        encID = encID,
        phase = nil,
        TTS = false,
        dur = 5,
        id = 0.2,
        spellID = 1253050,
        customIcon = nil,
        difficulties = {14, 15, 16},
        timers = nil,
        overrides = {BlockCopy = true, enabled = false},
        HideTimer = false,
        Version = {versionNumber = 1, dur = 6},
    }
    self:AddEncounterAlert(data)

    local LuraPreview = [[
        return function(self, update)
            if self.IsLuraPreview then
                self.EncounterAlertStop[3183](self, true)
                self.IsLuraPreview = false
            else
                self.EncounterAlertStart[3183](self, 16, "Runes Display")
                self.IsLuraPreview = true
            end
        end
    ]]

    local data = {internalID = "RunesDisplay", text = nil, DisplayType = "Text", encID = encID, phase = nil, TTS = false, dur = 5, spellID = nil, id = 0, internalID = "RunesDisplay",
    overrides = {enabled = true, pinned = true, BlockCopy = true, Scale = 1, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 300, yOffset = -300, BackgroundColor = {0.2, 0.2, 0.2, 1}}, ShowSenderNames = false,
    timers = nil, Preview = LuraPreview, customIcon = 1284980,
    difficulties = {14, 15, 16},
    extraOptions = {
            { Type = "Label",    text = "Runes Display" },
            { Type = "Slider",   label = "Scale",          min = 0.5,   max = 2,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3183][16].RunesDisplay.Scale   or 1    end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3183][i].RunesDisplay.Scale    = v end NSI.EncounterAlertStop[3183](NSI, true) NSI.EncounterAlertStart[3183](NSI, 16, "Runes Display") end]]},
            { Type = "Slider",   label = "xOffset",        min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3183][16].RunesDisplay.xOffset  or 300  end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3183][i].RunesDisplay.xOffset  = v end NSI.EncounterAlertStop[3183](NSI, true) NSI.EncounterAlertStart[3183](NSI, 16, "Runes Display") end]]},
            { Type = "Slider",   label = "yOffset",        min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3183][16].RunesDisplay.yOffset  or -300 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3183][i].RunesDisplay.yOffset  = v end NSI.EncounterAlertStop[3183](NSI, true) NSI.EncounterAlertStart[3183](NSI, 16, "Runes Display") end]]},
            { Type = "Color",    label = "BackgroundColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3183][16].RunesDisplay.BackgroundColor or {0.2,0.2,0.2,1} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3183][i].RunesDisplay.BackgroundColor = {r,g,b,a} end NSI.EncounterAlertStop[3183](NSI, true) NSI.EncounterAlertStart[3183](NSI, 16, "Runes Display") end]]},
            { Type = "Checkbox", label = "ShowSenderNames",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3183][16].RunesDisplay.ShowSenderNames  or false  end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3183][i].RunesDisplay.ShowSenderNames  = v end NSI.EncounterAlertStop[3183](NSI, true) NSI.EncounterAlertStart[3183](NSI, 16, "Runes Display") end]],
                tooltip = {title = "ShowSenderNames", desc = "Will show the Name of the sender to help you debug any possible issues or wrong macro presses"}},
            { Type = "Breakline" },
            { Type = "Link",     label = "Runes Guide",     url = "https://www.youtube.com/watch?v=yXNASNKxasQ", width = 150,},
            { Type = "Link",     label = "Texture Files",   url = "https://github.com/Reloe/LuraMemoryFiles", width = 150,
                tooltip = {title = "Texture Files", desc = "The Texture files are no longer required for most users. They are only required if you want to see these Icons in your Macros."}},
            { Type = "Button",   label = "Create Macros", width = 150,
            func = [[return function(NSI)
                local iconIDs = {"7242384", "134635", "340528", "351033", "236903"}
                local names = {"T", "Circle", "Diamond", "Triangle", "Cross"}
                for i=1, 5 do
                    local macroName = "NSRT_LURA_RUNE_"..i
                    if not GetMacroInfo(macroName) then
                        CreateMacro(macroName, iconIDs[i], "/raid "..names[i])
                    else
                        EditMacro(macroName, macroName, iconIDs[i], "/raid "..names[i])
                    end
                end
            end]],
            tooltip = {title = "Create Macros", desc = "Will automatically create the correct macros for the memory game. You will only see the correct icons if you downloaded the texture files"}},
        },
    }
    self:AddEncounterAlert(data)

    local data = {text = nil, internalID = "InterruptDisplay", name = "Interrupt Display", DisplayType = "Text", encID = encID, phase = nil, TTS = false, dur = 5, spellID = nil,
    customIcon = 6552, id = 0.1, timers = nil, difficulties = {16},
    overrides = {pinned = true, BlockCopy = true, enabled = true},
    Preview = [[return function()
        print("|cFF00FFFFNSRT:|r no preview available for this Alert. You can change Interrupt settings in the Interrupt Display menu.")
    end]],
    }
    self:AddEncounterAlert(data)
end

NSI.EncounterAlertStart[encID] = function(self, id, preview) -- on ENCOUNTER_START
    local realpull = not id
    id = id or self:DifficultyCheck(14) or 0
    if realpull and id == 16 then
        NSI.NSRTFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
    local interrupts = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].InterruptDisplay
    if interrupts and interrupts.enabled and self:EvaluateLoad(interrupts) and realpull and id == 16 then
        self:EncounterRegister("InterruptDisplay", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP"}, true, {"boss2", "boss3", "boss4"})
        self:EncounterRegister("InterruptDisplay", "INSTANCE_ENCOUNTER_ENGAGE_UNIT", true)
        self:ReadInterruptNote(1)
        self:EncounterFunction("InterruptDisplay", function(_, e, unit, ...)
            if e == "UNIT_SPELLCAST_START" then
                if self.Interrupts.myTrackedID and unit == "boss"..self.Interrupts.myTrackedID and UnitIsEnemy(unit, "player") then
                    local info = {spellID = 1284934, dur = 2}
                    self:InterruptOnCastStart(info)
                    if self.ResetTimer then
                        self.ResetTimer:Cancel()
                    end
                    self.ResetTimer = C_Timer.NewTimer(15, function()
                        self:ResetInterrupts()
                    end)
                end
            elseif e == "UNIT_SPELLCAST_INTERRUPTED" then
                if self.Interrupts.myTrackedID and unit == "boss"..self.Interrupts.myTrackedID and UnitIsEnemy(unit, "player") then
                    self:OnInterrupt()
                end
            elseif e == "UNIT_SPELLCAST_STOP" then
                if self.Interrupts.myTrackedID and unit == "boss"..self.Interrupts.myTrackedID and UnitIsEnemy(unit, "player") then
                    self:OnCastStop()
                end
            elseif e == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
                if UnitExists("boss2") and UnitIsEnemy("boss2", "player") then
                    if self.Interrupts.myTrackedID == 4 then
                        if not (UnitExists("boss4")) then
                            if UnitExists("boss3") then
                                self.Interrupts.myTrackedID = 3
                            else
                                self.Interrupts.myTrackedID = 2
                            end
                        end
                    elseif self.Interrupts.myTrackedID == 3 then
                        if not (UnitExists("boss3")) then
                            self.Interrupts.myTrackedID = 2
                        end
                    end
                    return
                end
                if (not UnitExists("boss2")) or (not (UnitIsEnemy("boss2", "player"))) then
                    self:ResetInterrupts()
                end
            end
        end)
    end
    local runes = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].RunesDisplay
    if runes and ((runes.enabled and self:EvaluateLoad(runes) and realpull) or (preview and preview == "Runes Display")) then
        local s = NSRT.EncounterAlerts[encID][id].RunesDisplay
        local isTank = UnitGroupRolesAssigned("player") == "TANK"
        local XOffset = { 50, 60, 0, -60, -50 }
        local YOffset = { 50, -25, -70, -25, 50 }
        local function DisplayRune(pos, text, isMythic, sender, senderGUID, senderDisplayName)
            if not isMythic then
                pos = 1
                for i = 2, 5 do
                    if self.LuraRunesCompleted[i-1] then
                        pos = i
                    else
                        break
                    end
                end
                self.LuraRunesCompleted[pos] = true
            end

            if not self.LuraRunesDisplay[pos] then
                self.LuraRunesDisplay[pos] = self.LuraRunesFrame:CreateFontString(nil, "OVERLAY")
                self.LuraRunesDisplay[pos]:SetFont("Fonts\\FRIZQT__.TTF", 15)
                self.LuraRunesDisplay[pos]:SetTextColor(1, 1, 1)

                self.LuraRunesNumbers[pos] = self.LuraRunesFrame:CreateFontString(nil, "OVERLAY")
                self.LuraRunesNumbers[pos]:SetTextColor(1, 1, 1)
                self.LuraRunesNumbers[pos]:SetWidth(90)
                self.LuraRunesNumbers[pos]:SetWordWrap(false)
                self.LuraRunesNumbers[pos]:SetShadowColor(0, 0, 0, 1)
            end
            self.LuraRunesNumbers[pos]:SetFont(self:GetGlobalFontPath(), runes.ShowSenderNames and 16 or 25, "OUTLINE")
            self.LuraRunesDisplay[pos]:ClearAllPoints()
            self.LuraRunesNumbers[pos]:ClearAllPoints()
            if self.Phase == 4 then
                self.LuraRunesDisplay[pos]:SetPoint("LEFT", self.LuraRunesFrame, "LEFT", (pos - 1) * 60, 0)
                self.LuraRunesNumbers[pos]:SetPoint("CENTER", self.LuraRunesFrame, "LEFT", (pos - 1) * 60 + 28, 30)
            else
                local posX = isTank and XOffset[pos] * -1 or XOffset[pos]
                local posY = isTank and YOffset[pos] * -1 or YOffset[pos]
                self.LuraRunesDisplay[pos]:SetPoint("CENTER", self.LuraRunesFrame, "CENTER", posX, posY)
                self.LuraRunesNumbers[pos]:SetPoint("CENTER", self.LuraRunesFrame, "CENTER", posX, posY + 30)
            end
            if runes.UseOldSystem then
                self.LuraRunesDisplay[pos]:SetFormattedText("|T%s:48:48|t", text)
            else
                self.LuraRunesDisplay[pos]:SetFormattedText("|TInterface\\AddOns\\NorthernSkyRaidTools\\Media\\EncounterPics\\%s:48:48|t", text)
            end
            self.LuraRunesDisplay[pos]:Show()

            if runes.ShowSenderNames and self.Phase ~= 4 and (senderDisplayName or (sender and senderGUID)) then
                -- UnitClassFromGUID accepts secret arguments, but UnitClass and UnitClassBase do not.
                local classFilename = senderGUID and select(2, UnitClassFromGUID(senderGUID))
                local classColor = classFilename and C_ClassColor.GetClassColor(classFilename)
                local senderNameClassColored = senderDisplayName or (classColor and C_ColorUtil.WrapTextInColor(sender, classColor) or sender)
                self.LuraRunesNumbers[pos]:SetText(string.format("%d: %s", pos, senderNameClassColored))
            else
                self.LuraRunesNumbers[pos]:SetText(pos)
            end
            self.LuraRunesNumbers[pos]:Show()
        end
        local function HideAllRunes()
            for i = 1, 5 do
                if self.LuraRunesDisplay[i] then self.LuraRunesDisplay[i]:Hide() end
                if self.LuraRunesNumbers[i] then self.LuraRunesNumbers[i]:Hide() end
            end
            self.LuraRunesCompleted = {}
            if self.Phase ~= 4 then
                self.LuraRunesFrame:UnregisterEvent("CHAT_MSG_RAID")
                self.LuraRunesFrame:UnregisterEvent("CHAT_MSG_RAID_LEADER")
            end
            self.LuraRunesFrame:Hide()
        end

        if not self.LuraRunesFrame then
            self.LuraRunesFrame = CreateFrame("Frame", "nil", self.NSRTFrame, "BackdropTemplate")
        end
        self.LuraRunesFrame:SetScript("OnEvent", function(_, e, msg, ...)
            if e == "CHAT_MSG_RAID" then
                local sender = select(1, ...)
                local senderGUID = select(11, ...)
                self.LuraRunesFrame:Show()
                if self.HideTimer then
                    self.HideTimer:Cancel()
                end
                local hideduration = self.Phase == 4 and 13 or 15
                self.HideTimer = C_Timer.NewTimer(hideduration, function()
                    HideAllRunes()
                end)

                if id ~= 16 or self.Phase == 4 then
                    DisplayRune(pos, msg, false, sender, senderGUID)
                    return
                end
                local pos = 2
                if self.LuraRunesCompleted[pos] then pos = 3 end
                if self.LuraRunesCompleted[pos] then pos = 5 end
                self.LuraRunesCompleted[pos] = true
                DisplayRune(pos, msg, true, sender, senderGUID)
            elseif e == "CHAT_MSG_RAID_LEADER" then
                local sender = select(1, ...)
                local senderGUID = select(11, ...)
                local senderDisplayName = UnitExists("raid1") and NSAPI:Shorten("raid1", 12, false, "GlobalNickNames") or nil
                self.LuraRunesFrame:Show()
                if self.HideTimer then
                    self.HideTimer:Cancel()
                end
                local hideduration = self.Phase == 4 and 13 or 15
                self.HideTimer = C_Timer.NewTimer(hideduration, function()
                    HideAllRunes()
                end)
                if id ~= 16 or self.Phase == 4 then
                    DisplayRune(pos, msg, false, sender, senderGUID, senderDisplayName)
                    return
                end
                local pos = 1
                if self.LuraRunesCompleted[pos] then pos = 4 end
                self.LuraRunesCompleted[pos] = true
                DisplayRune(pos, msg, true, sender, senderGUID, senderDisplayName)
            end
        end)
        self.LuraRunesFrame:ClearAllPoints()
        self.LuraRunesFrame:SetScale(s.Scale or 1)
        self.LuraRunesFrame:SetPoint(s.Anchor, self.NSRTFrame, s.relativeTo, s.xOffset, s.yOffset)
        self.LuraRunesFrame:SetBackdrop({bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
        self.LuraRunesFrame:SetBackdropColor(unpack(s.BackgroundColor))
        self.LuraRunesFrame:SetBackdropBorderColor(unpack(s.BackgroundColor))
        self.LuraRunesFrame:SetWidth(200)
        self.LuraRunesFrame:SetHeight(200)

        self.LuraRunesCompleted = {}

        self.LuraRunesDisplay = self.LuraRunesDisplay or {}
        self.LuraRunesNumbers = self.LuraRunesNumbers or {}
        self.AlertTimers = self.AlertTimers or {}
        if preview then
            self.IsLuraPreview = true
            self:MakeDraggable(self.LuraRunesFrame, s, true)
            self.LuraRunesFrame:Show()
            local names = {"T", "Circle", "Diamond", "Triangle", "Cross"}
            for i = 1, 5 do
                DisplayRune(i, secretwrap(names[i]), false, secretwrap(UnitName("player")), secretwrap(UnitGUID("player")))
            end
        end
        local timers = {
            [14] = { 10, 80, 150 },
            [15] = { 10, 80, 150 },
            [16] = { 33, 95, 157 },
        }
        self.LuraRuneTimers = {}
        if preview then return end
        for i, time in ipairs(timers[id] or {}) do -- enable event register 2s before each memory game. then disable it again later
            self.LuraRuneTimers[i] = C_Timer.NewTimer(time - 2, function()
                self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID")
                self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
            end)
        end
        self.LuraRunesFrame:Hide()

        self.AlertTimers[1] = C_Timer.NewTimer(70, function()
            if not self.AlertTimers then return end
            HideAllRunes()
            self.LuraRunesCompleted = {}
        end)
        self.AlertTimers[2] = C_Timer.NewTimer(140, function()
            if not self.AlertTimers then return end
            HideAllRunes()
            self.LuraRunesCompleted = {}
        end)
    end

    local crystalDropTimer = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].CrystalDropTimer
    if crystalDropTimer and crystalDropTimer.enabled and self:EvaluateLoad(crystalDropTimer) and not preview then
        local s = NSRT.EncounterAlerts[encID][id].CrystalDropTimer
        local info = self:CreateReminder(CopyTable(s), true)
        self:EncounterRegister("CrystalDropTimer", "UNIT_SPELLCAST_SUCCEEDED", true, "player")
        self:EncounterRegister("CrystalDropTimer", "UPDATE_EXTRA_ACTIONBAR", true)
        self:EncounterFunction("CrystalDropTimer", function(_, e, unit, ...)
            if e == "UPDATE_EXTRA_ACTIONBAR" then
                if C_ActionBar.HasExtraActionBar() and self.CrystalDropTimer and self.CrystalDropTimer:IsShown() then
                    self.CrystalDropTimer:Hide()
                    self:ArrangeStates(self.CrystalDropTimer.DisplayType)
                    self.CrystalDropTimer = nil
                end
            else
                local castGUID, spellID, castBarID = ...
                -- Dawn Crystal
                if spellID == 1253050 then
                    self.CrystalDropTimer = self:DisplayReminder(info)
                end
            end
        end)
    end
end

NSI.EncounterAlertStop[encID] = function(self, preview) -- on ENCOUNTER_END
    if preview then
        self:MakeDraggable(self.LuraRunesFrame, nil, false)
        NSRT.EncounterAlerts[encID][15].RunesDisplay = NSRT.EncounterAlerts[encID][16].RunesDisplay
        NSRT.EncounterAlerts[encID][14].RunesDisplay = NSRT.EncounterAlerts[encID][16].RunesDisplay
    end
    if self.LuraRunesFrame then
        self.LuraRunesFrame:UnregisterAllEvents()
        self.LuraRunesFrame:Hide()
        for i = 1, 5 do
            if self.LuraRunesDisplay[i] then
                self.LuraRunesDisplay[i]:Hide()
            end
            if self.LuraRunesNumbers[i] then
                self.LuraRunesNumbers[i]:Hide()
            end
        end
        self.LuraRunesCompleted = {}
        if self.AlertTimers then
            for i, v in pairs(self.AlertTimers) do
                if v and v.Cancel then
                    v:Cancel()
                end
            end
            self.AlertTimers = nil
        end
        if self.LuraRuneTimers then
            for i, v in pairs(self.LuraRuneTimers) do
                if v and v.Cancel then
                    v:Cancel()
                end
            end
            self.LuraRuneTimers = nil
        end
        self.NSRTFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
    self:HideInterrupt()
end

local detectedDurations = {
    [15] = {
        { time = 45,  phase = function(num) return 2 end },
        { time = 97,  phase = function(num) return 3 end },
        { time = 180, phase = function(num) return 4 end },
    },
    [16] = {
        { time = 45,  phase = function(num) return 2 end },
        { time = 97,  phase = function(num) return 3 end },
        { time = 180, phase = function(num) return 4 end },
    },
}

NSI.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    if e == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" and self.Phase == 4 then
        if (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 20)) then return end
        if not UnitExists("boss2") then
            self.Phase = 5
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = GetTime()
        end
        return
    end
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime + 5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = select(3, GetInstanceInfo()) or 0
    if (not difficultyID) or (not detectedDurations[difficultyID]) then return end
    local phaseinfo = detectedDurations[difficultyID][self.Phase]
    if phaseinfo and ApproximatelyEqual(info.duration, phaseinfo.time, 0.2) then
        local newphase = phaseinfo.phase(self.Phase)
        if newphase > self.Phase then
            self.Phase = newphase
            self:StartReminders(self.Phase)
            self.PhaseSwapTime = now
            if self.Phase == 2 and difficultyID == 16 then
                self:HideInterrupt()
                self:EncounterRegister("InterruptDisplay", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"}, false)
                if self.Interrupts then self.Interrupts.disabled = true end
            end
            if self.Phase == 4 and difficultyID == 16 then
                if self.LuraRunesFrame then
                    self.LuraRunesFrame:SetWidth(300)
                    self.LuraRunesFrame:SetHeight(60)
                    self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID")
                    self.LuraRunesFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
                end
                local timers = { 20, 40, 75, 95, 130, 150 }
                if self.LuraRuneTimers then
                    for i, v in ipairs(self.LuraRuneTimers) do
                        if v and v.Cancel then
                            v:Cancel()
                        end
                    end
                end
                self.LuraRuneTimers = {}
                for i, time in ipairs(timers) do -- remove previous display 2s before memory game
                    self.LuraRuneTimers[i] = C_Timer.NewTimer(time - 2, function()
                        for num = 1, 5 do
                            if self.LuraRunesDisplay[num] then
                                self.LuraRunesDisplay[num]:Hide()
                            end
                            if self.LuraRunesNumbers[num] then
                                self.LuraRunesNumbers[num]:Hide()
                            end
                        end
                        self.LuraRunesCompleted = {}
                        self.LuraRunesFrame:Hide()
                    end)
                end
                return
            end
            if self.Phase ~= 2 and self.Phase ~= 5 then return end
            if self.LuraRunesFrame then
                self.LuraRunesFrame:UnregisterAllEvents()
                self.LuraRunesFrame:Hide()
            end
        end
    end
end
