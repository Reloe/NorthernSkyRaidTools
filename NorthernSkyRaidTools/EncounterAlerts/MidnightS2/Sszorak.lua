local _, NSI = ... -- Internal namespace

local encID = 3420
-- /run NSAPI:DebugEncounter(3420)

local tankComboTimers = {
    [14] = {5.5, 57.7, 143.7, 196, 282, 334},
    [15] = {5.5, 57.7, 143.7, 196, 282, 334},
    [16] = {4.9, 52, 132, 179, 259, 306.1},
}

local damageAmpTimers = {
    [14] = {125, 277.1, 429.2},
    [15] = {111.1, 249.3, 387.5},
    [16] = {100, 227.1, 354.2},
}

local venomousSurgeCastTimers = {
    [14] = {36.25, 95, 188.3, 247, 340.3},
    [15] = {32.2, 84.4, 170.3, 222.6, 308.5, 360.8},
    [16] = {29, 76, 156, 203, 283, 330},
}

-- boss1target briefly changes to each bomb target during the bomb cast.
-- cast start -> target cleared -> bomb 1 (~+1.6s, held 0.4-1.2s) -> cleared -> bomb 2 (~+3.6s, held ~0.4s) -> cleared -> back to active tank.
-- We use boss1 UNIT_TARGET events to determine the bomb targets.
local venomousSurgeBombsPerCast = 2
local bombDuration = 10

local markerMapDefaultOrder = {3, 8, 4, 5, 6, 7, 1, 2}
local markerMapDirections = {"North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"}
local markerMapCircleTexture = [[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_filled.png]]
local markerMapRotationDegrees = 7

NSI.InitializeAlerts[encID] = function(self)
    NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}

    local tankConditions = self:DefaultLoadConditions()
    tankConditions.Roles.TANK = true
    local nontankConditions = self:DefaultLoadConditions()
    nontankConditions.Roles.HEALER = true
    nontankConditions.Roles.DAMAGER = true

    local data = {group = "Sszorak", internalID = "TankCombo", name = "Tank Combo", text = "Tank Combo", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1277002,
        loadConditions = tankConditions,
        textColors = {1, 0, 0, 1},
        timers = {
            [15] = tankComboTimers[15],
            [16] = tankComboTimers[16],
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "DamageAmp", name = "Damage Amp", text = "Damage Amp", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1286033,
        timers = {
            [15] = damageAmpTimers[15],
            [16] = damageAmpTimers[16],
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "SetMarkers", name = "Mark Reminder", text = "Set Markers", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 5,
        difficulties = {16}, enabled = false,
        timers = {
            [16] = {9.9, 137, 264},
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "Bait", text = "Bait", DisplayType = "Text", encID = encID, phase = 1, TTS = true, dur = 8, spellID = 1305959,
        loadConditions = tankConditions,
        timers = {
            [15] = venomousSurgeCastTimers[15],
            [16] = venomousSurgeCastTimers[16],
        },
    }
    self:AddEncounterAlert(data)

    local data = {group = "Sszorak", internalID = "WindDebuffs", text = "Wind-Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1285419,
        timers = {
            [15] = {44, 96, 182, 234, 320, 372},
            [16] = {39.7, 86.7, 166.8, 213.8, 293.9, 340.9},
        },
    }
    self:AddEncounterAlert(data)
    local data = {group = "Sszorak", internalID = "Debuffs", text = "Debuffs", DisplayType = "Text", encID = encID, phase = 1, TTS = false, dur = 6, spellID = 1305963,
        loadConditions = nontankConditions,
        timers = {
            [15] = {37.2, 89.5, 175.4, 227.6, 313.5, 365.8},
            [16] = {32, 79.8, 159, 206.8, 286, 333.8},
        },
    }
    self:AddEncounterAlert(data)

    local data = {Version = {versionNumber = 1, [1] = {loadConditions = {}}}, group = "Sszorak", internalID = "SerpentsFury", name = "Serpent's Fury", text = "Stack Up", DisplayType = "Text", encID = encID, phase = 1, TTS = "Stack", dur = 6,
        loadConditions = {},
        timers = {
            [16] = {25.5, 75.5, 152.5, 202.5, 279.5, 326.6},
        },
    }
    self:AddEncounterAlert(data)

    local WindsPreview = [[
        return function(self, update)
            if self.IsSszorakWindsPreview then
                self.EncounterAlertStop[3420](self, true)
                self.IsSszorakWindsPreview = false
            else
                self.EncounterAlertStart[3420](self, 16, "Winds Helper")
                self.IsSszorakWindsPreview = true
            end
        end
    ]]

    local data = {group = "Sszorak", internalID = "WindsHelper", name = "Winds Helper", text = nil, DisplayType = "Text", encID = encID, phase = nil, TTS = false, dur = 5,
        spellID = nil, id = 0, difficulties = {14, 15, 16}, enabled = true, isSpecialDisplay = true, BlockCopy = true, Preview = WindsPreview,
        Scale = 1, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -500, yOffset = 400, BackgroundColor = {0.2, 0.2, 0.2, 1}, ShowSenderNames = false,
        customIcon = 1285732,
        extraOptions = {
            { Type = "Label", text = "Winds Helper" },
            { Type = "Slider", label = "Scale", min = 0.5, max = 2,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.Scale or 1 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.Scale    = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Slider",   label = "xOffset",        min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.xOffset  or 200 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.xOffset  = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Slider",   label = "yOffset",        min = -2000, max = 2000,
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.yOffset  or -300 end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.yOffset  = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Color",    label = "BackgroundColor",
                get = [[return function(NSI) local c = NSRT.EncounterAlerts[3420][16].WindsHelper.BackgroundColor or {0.2,0.2,0.2,1} return c[1],c[2],c[3],c[4] end]],
                set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.BackgroundColor = {r,g,b,a} end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]]},
            { Type = "Checkbox", label = "ShowSenderNames",
                get = [[return function(NSI) return NSRT.EncounterAlerts[3420][16].WindsHelper.ShowSenderNames  or false  end]],
                set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].WindsHelper.ShowSenderNames  = v end NSI.EncounterAlertStop[3420](NSI, true) NSI.EncounterAlertStart[3420](NSI, 16, "Winds Helper") end]],
                tooltip = {title = "ShowSenderNames", desc = "Shows the sender next to each entered number."}},
            { Type = "Button", label = "Create Macros", width = 150,
                func = [[return function()
                    local iconIDs = {"137001", "137002", "137003", "137004", "137005", "137006", "137007", "137008"}
                    for i=1, 8 do
                        local macroName = "NSRT_SSZORAK_" .. i
                        if not GetMacroInfo(macroName) then
                            CreateMacro(macroName, iconIDs[i], "/raid " .. i)
                        else
                            EditMacro(macroName, macroName, iconIDs[i], "/raid " .. i)
                        end
                    end
                end]],
                tooltip = {title = "Create Macros", desc = "Creates macros that post numbers 1 through 8 with the matching raid-marker icons and will trigger the display mid-fight. All you have to do is press the macro's in the order you want the Knocks to be triggered during the Dmg-Amp. If new messages come in after 3 have already filled it will simply start from the beginning, that way you can fix mistakes."}},
        },
    }
    self:AddEncounterAlert(data)

    local BombPreview = [[
        return function(self, update)
            if self.IsSszorakBombPreview then
                self.EncounterAlertStop[3420](self, true)
                self.IsSszorakBombPreview = false
            else
                self.EncounterAlertStart[3420](self, 16, "Debuff Targets")
                self.IsSszorakBombPreview = true
            end
        end
    ]]

    local data = {group = "Sszorak", internalID = "VenomousSurgeTargets", name = "Debuff Targets", text = nil, DisplayType = "Bar", encID = encID, phase = nil, TTS = false, dur = bombDuration,
        spellID = 1305959, id = 0.1, difficulties = {14, 15, 16}, enabled = false, isSpecialDisplay = true, BlockCopy = true, Preview = BombPreview,
        customIcon = 1305959,
    }
    self:AddEncounterAlert(data)

    local AssignmentPreview = [[
        return function(self)
            self.EncounterAlertStart[3420](self, 16, "Drop Assignment")
        end
    ]]

    local data = {group = "Sszorak", internalID = "VenomousSurgeAssignment", name = "Drop Assignment", text = "Drop on", DisplayType = "Text", encID = encID,
        phase = 1, TTS = false, dur = 11, spellID = 1305959, difficulties = {16}, enabled = false, isSpecialDisplay = true, BlockCopy = true,
        Preview = AssignmentPreview,
    }
    self:AddEncounterAlert(data)

    local MarkerMapPreview = [[
        return function(self)
            if self.IsSszorakMarkerMapPreview then
                self.EncounterAlertStop[3420](self)
            else
                self.EncounterAlertStart[3420](self, 16, "Marker Map")
            end
        end
    ]]

    local markerDropdownValues = [[return function()
        local names = {"Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull"}
        local values = {{label = "None", value = 0}}
        for markerID, name in ipairs(names) do
            values[#values + 1] = {
                label = string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:18:18|t %s", markerID, name),
                value = markerID,
            }
        end
        return values
    end]]

    local markerMapOptions = {
        { Type = "Label", text = "Rotating Marker Map" },
        { Type = "Slider", label = "Scale", min = 0.5, max = 2, step = 0.05, decimals = 2, usedecimals = true,
            get = [[return function() return NSRT.EncounterAlerts[3420][16].MarkerMap.Scale or 1 end]],
            set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.Scale = v end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Slider", label = "MapSize", min = 140, max = 500, step = 10,
            get = [[return function() return NSRT.EncounterAlerts[3420][16].MarkerMap.MapSize or 240 end]],
            set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.MapSize = v end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Slider", label = "MarkerSize", min = 16, max = 80, step = 1,
            get = [[return function() return NSRT.EncounterAlerts[3420][16].MarkerMap.MarkerSize or 34 end]],
            set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.MarkerSize = v end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Slider", label = "xOffset", min = -2000, max = 2000,
            get = [[return function() return NSRT.EncounterAlerts[3420][16].MarkerMap.xOffset or 0 end]],
            set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.xOffset = v end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Slider", label = "yOffset", min = -2000, max = 2000,
            get = [[return function() return NSRT.EncounterAlerts[3420][16].MarkerMap.yOffset or 150 end]],
            set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.yOffset = v end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Slider", label = "UpdateInterval", min = 0.01, max = 0.2, step = 0.01, decimals = 2, usedecimals = true,
            get = [[return function() return NSRT.EncounterAlerts[3420][16].MarkerMap.UpdateInterval or 0.03 end]],
            set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.UpdateInterval = v end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Color", label = "BackgroundColor",
            get = [[return function() local c = NSRT.EncounterAlerts[3420][16].MarkerMap.BackgroundColor or {0.03,0.03,0.03,0.82} return c[1],c[2],c[3],c[4] end]],
            set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.BackgroundColor = {r,g,b,a} end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Color", label = "BorderColor",
            get = [[return function() local c = NSRT.EncounterAlerts[3420][16].MarkerMap.BorderColor or {0.15,0.85,1,1} return c[1],c[2],c[3],c[4] end]],
            set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.BorderColor = {r,g,b,a} end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Color", label = "PlayerColor",
            get = [[return function() local c = NSRT.EncounterAlerts[3420][16].MarkerMap.PlayerColor or {1,1,1,1} return c[1],c[2],c[3],c[4] end]],
            set = [[return function(NSI, r,g,b,a) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.PlayerColor = {r,g,b,a} end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]]},
        { Type = "Checkbox", label = "ShowPlayerArrow",
            get = [[return function() return NSRT.EncounterAlerts[3420][16].MarkerMap.ShowPlayerArrow ~= false end]],
            set = [[return function(NSI, v) for i=14, 16 do NSRT.EncounterAlerts[3420][i].MarkerMap.ShowPlayerArrow = v end NSI.EncounterAlertStop[3420](NSI) NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map") end]],
            tooltip = {title = "ShowPlayerArrow", desc = "Shows the player at the center, facing toward the top of the map."}},
        { Type = "Label", text = "World marker positions" },
    }

    for slot, direction in ipairs(markerMapDirections) do
        markerMapOptions[#markerMapOptions + 1] = {
            Type = "Dropdown",
            label = direction,
            values = markerDropdownValues,
            get = string.format([[return function()
                local order = NSRT.EncounterAlerts[3420][16].MarkerMap.MarkerOrder
                return order and order[%d] or %d
            end]], slot, slot),
            set = string.format([[return function(NSI, value)
                value = tonumber(value)
                if value == nil or value < 0 or value > 8 then return end
                for difficultyID = 14, 16 do
                    local settings = NSRT.EncounterAlerts[3420][difficultyID].MarkerMap
                    settings.MarkerOrder = settings.MarkerOrder or {3,8,4,5,6,7,1,2}
                    settings.MarkerOrder[%d] = value
                end
                NSI.EncounterAlertStop[3420](NSI)
                NSI.EncounterAlertStart[3420](NSI, 16, "Marker Map")
            end]], slot),
        }
    end

    local data = {Version = {versionNumber = 5}, group = "Sszorak", internalID = "MarkerMap", name = "Marker Map", text = nil, DisplayType = "Text", encID = encID,
        phase = nil, TTS = false, dur = 5, spellID = nil, id = 0.2, difficulties = {14, 15, 16}, enabled = false, isSpecialDisplay = true, BlockCopy = true,
        Preview = MarkerMapPreview, customIcon = 137001, Scale = 1, MapSize = 240, MarkerSize = 34, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -400, yOffset = 150,
        UpdateInterval = 0.03, BackgroundColor = {0.03, 0.03, 0.03, 0.82}, BorderColor = {0.15, 0.85, 1, 1}, PlayerColor = {1, 1, 1, 1},
        ShowPlayerArrow = true, MarkerOrder = {3, 8, 4, 5, 6, 7, 1, 2}, extraOptions = markerMapOptions,
    }
    self:AddEncounterAlert(data)
end

local function GetValidMarkerOrder(settings)
    local configured = settings.MarkerOrder or markerMapDefaultOrder
    local order = {}
    for slot = 1, 8 do
        local markerID = tonumber(configured[slot])
        if markerID == nil or markerID < 0 or markerID > 8 then
            markerID = markerMapDefaultOrder[slot]
        end
        order[slot] = markerID
    end
    return order
end

-- Places a small icon inside a full-map texture by sampling beyond the icon's
-- transparent edge. The whole texture can then use the protected compass angle
-- as a SetRotation input without exposing that angle to Lua arithmetic.
local function SetPaddedMarkerTexCoords(texture, centerX, centerY, iconSize, mapSize)
    local fraction = math.max(0.01, math.min(0.9, iconSize / mapSize))
    local left = 0.5 - (centerX / fraction)
    local right = 0.5 + ((1 - centerX) / fraction)
    local top = 0.5 - (centerY / fraction)
    local bottom = 0.5 + ((1 - centerY) / fraction)
    texture:SetTexCoord(left, right, top, bottom)
end

local function ShowCompassTextureThroughHooks()
    if not MinimapCompassTexture then return end
    local metatable = getmetatable(MinimapCompassTexture)
    local methods = metatable and metatable.__index
    local realShow = type(methods) == "table" and methods.Show
    if type(realShow) == "function" then
        realShow(MinimapCompassTexture)
    else
        MinimapCompassTexture:Show()
    end
end

local function LendSszorakMarkerMapCompass(self)
    if not MinimapCompassTexture then return end
    if not self.SszorakMarkerMapCompassState then
        self.SszorakMarkerMapCompassState = {
            shown = MinimapCompassTexture:IsShown(),
            alpha = MinimapCompassTexture:GetAlpha(),
        }
    end
    if not self.SszorakMarkerMapCompassState.shown then
        MinimapCompassTexture:SetAlpha(0)
    end
    ShowCompassTextureThroughHooks()
end

local function ReturnSszorakMarkerMapCompass(self)
    local state = self.SszorakMarkerMapCompassState
    if not state or not MinimapCompassTexture then return end
    if not state.shown then
        MinimapCompassTexture:Hide()
    end
    MinimapCompassTexture:SetAlpha(state.alpha or 1)
    self.SszorakMarkerMapCompassState = nil
end

local function CreateSszorakMarkerMap(self)
    if self.SszorakMarkerMapFrame then return self.SszorakMarkerMapFrame end

    local F = CreateFrame("Frame", "NSRTSszorakMarkerMap", self.NSRTFrame)
    F:SetFrameStrata("MEDIUM")
    F:SetClipsChildren(false)
    F:Hide()

    F.Background = F:CreateTexture(nil, "BACKGROUND")
    F.Background:SetTexture(markerMapCircleTexture)
    F.Background:SetPoint("CENTER")

    F.Edges = {}
    for index = 1, 8 do
        local edge = F:CreateLine(nil, "ARTWORK")
        edge:SetThickness(2)
        F.Edges[index] = edge
    end

    F.Markers = {}
    for slot = 1, 8 do
        local marker = F:CreateTexture(nil, "OVERLAY")
        marker:SetAllPoints(F)
        F.Markers[slot] = marker
    end

    F.Player = F:CreateTexture(nil, "OVERLAY")
    F.Player:SetPoint("CENTER", F, "CENTER", 0, 0)
    F.Player:SetTexture([[Interface\Minimap\MinimapArrow]])

    F.MarkerMapOnUpdate = function(frame, elapsed)
        frame.UpdateElapsed = (frame.UpdateElapsed or 0) + elapsed
        if frame.UpdateElapsed < (frame.UpdateInterval or 0.03) then return end
        frame.UpdateElapsed = 0
        if not MinimapCompassTexture then return end
        local owner = frame.Owner
        if owner then
            if GetCVar("rotateMinimap") ~= "1" then
                C_CVar.SetCVar("rotateMinimap", "1")
                MinimapCluster:SetRotateMinimap(true)
            end
            LendSszorakMarkerMapCompass(owner)
        end
        local ok, rotation = pcall(MinimapCompassTexture.GetRotation, MinimapCompassTexture)
        if not ok then return end
        for _, marker in ipairs(frame.Markers) do
            pcall(marker.SetRotation, marker, rotation)
        end
    end
    F:SetScript("OnUpdate", F.MarkerMapOnUpdate)

    F.Owner = self
    self.SszorakMarkerMapFrame = F
    return F
end

local function ApplySszorakMarkerMapSettings(self, F, settings)
    local mapSize = settings.MapSize or 240
    local markerSize = settings.MarkerSize or 34
    local outlineRadius = mapSize * 0.43
    local markerRadius = outlineRadius * math.cos(math.pi / 8)
    local borderColor = settings.BorderColor or {0.15, 0.85, 1, 1}
    local order = GetValidMarkerOrder(settings)

    F:SetSize(mapSize, mapSize)
    F:SetScale(settings.Scale or 1)
    F:ClearAllPoints()
    F:SetPoint(settings.Anchor or "CENTER", self.NSRTFrame, settings.relativeTo or "CENTER", settings.xOffset or 0, settings.yOffset or 150)
    F.UpdateInterval = settings.UpdateInterval or 0.03
    F.UpdateElapsed = 0
    F:SetScript("OnUpdate", F.MarkerMapOnUpdate)

    F.Background:SetSize(outlineRadius * 2, outlineRadius * 2)
    F.Background:SetVertexColor(unpack(settings.BackgroundColor or {0.03, 0.03, 0.03, 0.82}))

    local vertices = {}
    for index = 1, 8 do
        local angle = math.rad(22.5 + ((index - 1) * 45) + markerMapRotationDegrees)
        vertices[index] = {math.sin(angle) * outlineRadius, math.cos(angle) * outlineRadius}
    end
    for index, edge in ipairs(F.Edges) do
        local nextIndex = index == 8 and 1 or index + 1
        edge:SetStartPoint("CENTER", F, "CENTER", vertices[index][1], vertices[index][2])
        edge:SetEndPoint("CENTER", F, "CENTER", vertices[nextIndex][1], vertices[nextIndex][2])
        edge:SetColorTexture(unpack(borderColor))
    end

    for slot, marker in ipairs(F.Markers) do
        local angle = math.rad(((slot - 1) * 45) + markerMapRotationDegrees)
        local centerX = 0.5 + ((math.sin(angle) * markerRadius) / mapSize)
        local centerY = 0.5 - ((math.cos(angle) * markerRadius) / mapSize)
        if order[slot] == 0 then
            marker:Hide()
        else
            marker:SetTexture(string.format("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d", order[slot]), "CLAMP", "CLAMP")
            SetPaddedMarkerTexCoords(marker, centerX, centerY, markerSize, mapSize)
            marker:SetRotation(0)
            marker:Show()
        end
    end

    F.Player:SetSize(math.max(18, markerSize * 0.85), math.max(18, markerSize * 0.85))
    F.Player:SetVertexColor(unpack(settings.PlayerColor or {1, 1, 1, 1}))
    F.Player:SetShown(settings.ShowPlayerArrow ~= false)
end

NSI.EncounterAlertStart[encID] = function(self, id, preview)
    local realpull = not id
    id = id or self:DifficultyCheck({14, 15, 16}) or 0
    local markerMap = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].MarkerMap
    if markerMap and ((markerMap.enabled and self:EvaluateLoad(markerMap) and realpull) or preview == "Marker Map") then
        local F = CreateSszorakMarkerMap(self)
        ApplySszorakMarkerMapSettings(self, F, markerMap)
        if self.SszorakMarkerMapTimers then
            for _, timer in ipairs(self.SszorakMarkerMapTimers) do
                timer:Cancel()
            end
        end
        self.SszorakMarkerMapTimers = {}
        F:Hide()

        local hideMarkerMap = function()
            self.SszorakMarkerMapShowToken = (self.SszorakMarkerMapShowToken or 0) + 1
            F:Hide()
            if self.SszorakMarkerMapPreviousRotateMinimap ~= nil then
                local rotateMinimap = self.SszorakMarkerMapPreviousRotateMinimap
                C_CVar.SetCVar("rotateMinimap", rotateMinimap)
                MinimapCluster:SetRotateMinimap(rotateMinimap == "1")
                self.SszorakMarkerMapPreviousRotateMinimap = nil
            end
            ReturnSszorakMarkerMapCompass(self)
        end

        local showMarkerMap = function()
            if self.SszorakMarkerMapPreviousRotateMinimap == nil then
                self.SszorakMarkerMapPreviousRotateMinimap = GetCVar("rotateMinimap")
            end
            C_CVar.SetCVar("rotateMinimap", "1")
            MinimapCluster:SetRotateMinimap(true)
            F:Hide()
            self.SszorakMarkerMapShowToken = (self.SszorakMarkerMapShowToken or 0) + 1
            local showToken = self.SszorakMarkerMapShowToken
            C_Timer.After(0, function()
                if self.SszorakMarkerMapShowToken ~= showToken then return end
                if self.IsSszorakMarkerMapPreview or self.EncounterID == encID then
                    LendSszorakMarkerMapCompass(self)
                    F:Show()
                end
            end)
        end

        if preview == "Marker Map" then
            self.IsSszorakMarkerMapPreview = true
            self:MakeDraggable(F, markerMap, true, false, function(_, settings)
                for difficultyID = 14, 16 do
                    local difficultySettings = NSRT.EncounterAlerts[encID][difficultyID].MarkerMap
                    difficultySettings.xOffset = settings.xOffset
                    difficultySettings.yOffset = settings.yOffset
                    difficultySettings.Anchor = settings.Anchor
                    difficultySettings.relativeTo = settings.relativeTo
                end
            end)
            local dragStart = F:GetScript("OnDragStart")
            local dragStop = F:GetScript("OnDragStop")
            F:SetScript("OnDragStart", function(frame, ...)
                frame.MarkerMapDragging = true
                if dragStart then dragStart(frame, ...) end
            end)
            F:SetScript("OnDragStop", function(frame, ...)
                if dragStop then dragStop(frame, ...) end
                frame.MarkerMapDragging = false
                frame.UpdateElapsed = 0
                frame:SetScript("OnUpdate", frame.MarkerMapOnUpdate)
            end)
            showMarkerMap()
        else
            local debuffAlert = NSRT.EncounterAlerts[encID][id].Debuffs
            if id == 14 and (not debuffAlert or not debuffAlert.timers or #debuffAlert.timers == 0) then
                showMarkerMap()
            elseif debuffAlert and debuffAlert.timers then
                for _, debuffTime in ipairs(debuffAlert.timers) do
                    self.SszorakMarkerMapTimers[#self.SszorakMarkerMapTimers + 1] = C_Timer.NewTimer(math.max(0, debuffTime - 5), showMarkerMap)
                    self.SszorakMarkerMapTimers[#self.SszorakMarkerMapTimers + 1] = C_Timer.NewTimer(debuffTime + 15, hideMarkerMap)
                end
            end
        end
    end

    local winds = NSRT.EncounterAlerts[encID][id] and NSRT.EncounterAlerts[encID][id].WindsHelper
    if winds and ((winds.enabled and self:EvaluateLoad(winds) and realpull) or (preview and preview == "Winds Helper")) then
        local s = winds
        if not self.WindsFrame then
            self.WindsFrame = CreateFrame("Frame", nil, self.NSRTFrame, "BackdropTemplate")
            self.WindsFrame:SetSize(240, 80)
            self.WindsFrame:SetFrameStrata("MEDIUM")
            self.WindsDisplay = {}
            self.WindsNumbers = {}
            self.WindsSenderNames = {}
            for index = 1, 4 do
                local icon = self.WindsFrame:CreateFontString(nil, "ARTWORK")
                icon:SetFont(self:GetGlobalFontPath(), 15)
                icon:SetPoint("BOTTOMLEFT", self.WindsFrame, "BOTTOMLEFT", (index - 1) * 60, 0)
                self.WindsDisplay[index] = icon

                local number = self.WindsFrame:CreateFontString(nil, "OVERLAY")
                number:SetFont(self:GetGlobalFontPath(), 22, "OUTLINE")
                number:SetPoint("BOTTOM", icon, "TOP", 0, 2)
                number:SetTextColor(1, 1, 1, 1)
                self.WindsNumbers[index] = number

                local senderName = self.WindsFrame:CreateFontString(nil, "OVERLAY")
                senderName:SetFont(self:GetGlobalFontPath(), 16, "OUTLINE")
                senderName:SetPoint("TOP", icon, "BOTTOM", 0, -2)
                senderName:SetTextColor(1, 1, 1, 1)
                self.WindsSenderNames[index] = senderName
            end
        end

        local function HideAllWinds()
            self.WindsFrame:Hide()
            for index = 1, 4 do
                self.WindsDisplay[index]:Hide()
                self.WindsNumbers[index]:Hide()
                self.WindsSenderNames[index]:Hide()
            end
            self.WindsCount = 0
            self.WindsOrder = {}
            self.WindsOrderCount = 0
            self.BombCount = 0
        end

        local function DisplayWind(pos, text, sender, senderGUID, senderDisplayName)
            if not pos then
                self.WindsCount = (self.WindsCount or 0) + 1
                if self.WindsCount > 4 then
                    HideAllWinds()
                    self.WindsCount = 1
                end
                pos = self.WindsCount
            end

            self.WindsOrder = self.WindsOrder or {}
            self.WindsOrder[pos] = text
            self.WindsOrderCount = math.max(self.WindsOrderCount or 0, pos)

            self.WindsFrame:Show()
            self.WindsDisplay[pos]:SetFormattedText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%s:48:48|t", text)
            self.WindsDisplay[pos]:Show()
            self.WindsNumbers[pos]:SetText(pos)
            self.WindsNumbers[pos]:Show()
            if s.ShowSenderNames then
                local classFilename = senderGUID and select(2, UnitClassFromGUID(senderGUID))
                local classColor = classFilename and C_ClassColor.GetClassColor(classFilename)
                local senderNameClassColored = senderDisplayName or (classColor and C_ColorUtil.WrapTextInColor(sender, classColor) or sender)
                self.WindsSenderNames[pos]:SetFormattedText("%s", senderNameClassColored)
                self.WindsSenderNames[pos]:Show()
            else
                self.WindsSenderNames[pos]:Hide()
            end
        end
        self.WindsFrame:ClearAllPoints()
        self.WindsFrame:SetScale(s.Scale)
        self.WindsFrame:SetPoint(s.Anchor, self.NSRTFrame, s.relativeTo, s.xOffset, s.yOffset)
        self.WindsFrame:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8X8]],
            edgeFile = [[Interface\Buttons\WHITE8X8]],
            edgeSize = 1,
        })
        self.WindsFrame:SetBackdropColor(unpack(s.BackgroundColor))
        self.WindsFrame:SetBackdropBorderColor(unpack(s.BackgroundColor))
        HideAllWinds()

        if preview then
            self.IsSszorakWindsPreview = true
            self:MakeDraggable(self.WindsFrame, s, true, false, function(_, settings)
                for difficultyID = 14, 16 do
                    local difficultySettings = NSRT.EncounterAlerts[encID][difficultyID].WindsHelper
                    difficultySettings.xOffset = settings.xOffset
                    difficultySettings.yOffset = settings.yOffset
                    difficultySettings.Anchor = settings.Anchor
                    difficultySettings.relativeTo = settings.relativeTo
                end
            end)
            local previewNumbers = {1, 2, 3, 4, 5, 6, 7, 8}
            for index = 8, 2, -1 do
                local swapIndex = math.random(index)
                previewNumbers[index], previewNumbers[swapIndex] = previewNumbers[swapIndex], previewNumbers[index]
            end
            for index = 1, 4 do
                DisplayWind(index, secretwrap(previewNumbers[index]), secretwrap(UnitName("player")), secretwrap(UnitGUID("player")))
            end
            return
        end

        self:EncounterRegister("SszorakWinds", {"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER"}, true)
        self:EncounterFunction("SszorakWinds", function(_, event, message, sender, ...)
            local senderGUID = select(10, ...)
            local senderDisplayName = event == "CHAT_MSG_RAID_LEADER" and UnitExists("raid1") and NSAPI:Shorten("raid1", 12, false, "GlobalNickNames") or nil
            DisplayWind(nil, message, sender, senderGUID, senderDisplayName)
        end)

        local diffData = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][id]
        local damageAmp = diffData and diffData.DamageAmp
        local resetTimes = damageAmp and damageAmp.timers or damageAmpTimers[id]
        self.WindsResetTimers = {}
        for _, time in ipairs(resetTimes or {}) do
            self.WindsResetTimers[#self.WindsResetTimers + 1] = C_Timer.NewTimer(time + 20, function()
                HideAllWinds()
            end)
        end
    end

    local diffData = NSRT.EncounterAlerts[encID][id]
    local bombs = diffData and diffData.VenomousSurgeTargets
    local assignment = diffData and diffData.VenomousSurgeAssignment
    local bombsActive = bombs and ((bombs.enabled and self:EvaluateLoad(bombs) and realpull) or (preview and preview == "Debuff Targets"))
    local assignmentPreview = preview and preview == "Drop Assignment"
    local assignmentActive = assignment and ((assignment.enabled and self:EvaluateLoad(assignment) and realpull) or assignmentPreview)
    if bombsActive or assignmentActive then
        local windsActive = (winds and winds.enabled and self:EvaluateLoad(winds)) and true or false
        local function DisplayBomb(unit)
            if not UnitExists(unit) then return end
            self.BombCount = (self.BombCount or 0) + 1
            local pos = self.BombCount
            local unitName = preview and secretwrap(UnitName(unit)) or UnitName(unit)
            local classFilename = select(2, UnitClass(unit))
            local classColor = C_ClassColor.GetClassColor(classFilename)
            unitName = C_ColorUtil.WrapTextInColor(unitName, classColor)
            local info = self:CreateReminder({
                text = "",
                DisplayType = "Bar",
                spellID = 1305959,
                dur = bombDuration,
                encID = encID,
                phase = self.Phase,
                TTS = false,
                sticky = 0,
                IsAlert = true,
            }, true)
            if not info then return end
            info.text = unitName
            local F = self:DisplayReminder(info)
            if not F then return end
            if preview then
                self.SszorakBombPreviewFrames = self.SszorakBombPreviewFrames or {}
                self.SszorakBombPreviewFrames[#self.SszorakBombPreviewFrames + 1] = F
            end

            if not windsActive then -- Just show names (no markers) if winds helper is disabled.
                if F.SszorakBombMarker then F.SszorakBombMarker:Hide() end
                return
            end
            if not F.SszorakBombMarker then
                F.SszorakBombMarker = F:CreateFontString(nil, "OVERLAY")
                F.SszorakBombMarker:SetFont(self:GetGlobalFontPath(), NSRT.ReminderSettings.BarSettings.FontSize, "OUTLINE")
                F.SszorakBombMarker:SetPoint("RIGHT", F.Icon, "LEFT", -4, 0)
                F:HookScript("OnHide", function() F.SszorakBombMarker:Hide() end)
            end

            if pos <= (self.WindsOrderCount or 0) then
                F.SszorakBombMarker:SetFormattedText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%s:0|t", self.WindsOrder[pos])
            else
                F.SszorakBombMarker:SetText(NSI:EncounterAlertLoc("Backup"))
            end
            F.SszorakBombMarker:Show()
        end
        self.BombCount = 0

        if assignmentPreview then
            local previewMarker = secretwrap(math.random(1, 4))
            local info = self:CreateReminder({
                text = "",
                DisplayType = "Text",
                spellID = assignment.spellID,
                dur = assignment.dur,
                encID = encID,
                phase = self.Phase,
                TTS = false,
                sticky = 0,
                IsAlert = true,
            }, true)
            if info then
                info.SecretDisplayText = string.format("%s |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%s:0|t", assignment.text or "Drop on", previewMarker)
                local frame = self:DisplayReminder(info)
                if frame then
                    self.SszorakAssignmentPreviewFrames = {frame}
                end
            end
            return
        end

        if preview then
            self.IsSszorakBombPreview = true
            self.SszorakBombPreviewFrames = {}
            if windsActive and (self.WindsOrderCount or 0) < 4 then
                self.WindsOrder = {}
                for index = 1, 4 do
                    self.WindsOrder[index] = secretwrap(index)
                end
                self.WindsOrderCount = 4
            end
            for _ = 1, 4 do -- 2 sets of bombs so we can see the "backup" text.
                DisplayBomb("player")
            end
            return
        end

        self:EncounterFunction("SszorakBombTargets", function()
            local exists = UnitExists("boss1target")
            if issecretvalue(exists) or not exists then return end -- the boss drops its target between each bomb
            self.BombWindowCaptures = (self.BombWindowCaptures or 0) + 1
            if bombsActive then
                DisplayBomb("boss1target")
            end
            if assignmentActive then
                self.AssignmentWindowCaptures = (self.AssignmentWindowCaptures or 0) + 1
                local isPlayerTarget = UnitIsUnit("boss1target", "player")
                if not issecretvalue(isPlayerTarget) and isPlayerTarget then
                    local displayText
                    if self.AssignmentWindowCaptures <= (self.WindsOrderCount or 0) then
                        displayText = string.format("%s |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%s:0|t", assignment.text or "Drop on", self.WindsOrder[self.AssignmentWindowCaptures])
                    else
                        displayText = string.format("%s %s", assignment.text or "Drop on", NSI:EncounterAlertLoc("Backup"))
                    end

                    local info = self:CreateReminder({
                        text = "",
                        DisplayType = "Text",
                        spellID = assignment.spellID,
                        dur = assignment.dur,
                        encID = encID,
                        phase = self.Phase,
                        TTS = false,
                        sticky = 0,
                        IsAlert = true,
                    }, true)
                    if info then
                        if self.AssignmentWindowCaptures <= (self.WindsOrderCount or 0) then
                            info.SecretDisplayText = displayText
                        else
                            info.text = displayText
                        end
                        self:DisplayReminder(info)
                    end
                end
            end
            if self.BombWindowCaptures >= venomousSurgeBombsPerCast then
                self:EncounterRegister("SszorakBombTargets", "UNIT_TARGET", false, "boss1")
            end
        end)

        self.BombWindowCaptures = 0
        self.AssignmentCastCount = 0
        self.AssignmentWindowCaptures = 0
        self.BombWindowTimers = {}
        for _, castTime in ipairs(venomousSurgeCastTimers[id] or {}) do
            self.BombWindowTimers[#self.BombWindowTimers + 1] = C_Timer.NewTimer(castTime, function()
                self.BombWindowCaptures = 0
                self.AssignmentCastCount = (self.AssignmentCastCount or 0) + 1
                if self.AssignmentCastCount > 2 then
                    self.AssignmentCastCount = 1
                    self.AssignmentWindowCaptures = 0
                end
                self:EncounterRegister("SszorakBombTargets", "UNIT_TARGET", true, "boss1")
            end)
        end
    end
end

NSI.EncounterAlertStop[encID] = function(self)
    if self.SszorakMarkerMapTimers then
        for _, timer in ipairs(self.SszorakMarkerMapTimers) do
            timer:Cancel()
        end
        self.SszorakMarkerMapTimers = nil
    end
    self.SszorakMarkerMapShowToken = (self.SszorakMarkerMapShowToken or 0) + 1
    if self.IsSszorakMarkerMapPreview and self.SszorakMarkerMapFrame then
        self:MakeDraggable(self.SszorakMarkerMapFrame, nil, false)
    end
    self.IsSszorakMarkerMapPreview = false
    if self.SszorakMarkerMapFrame then
        self.SszorakMarkerMapFrame:Hide()
    end
    if self.SszorakMarkerMapPreviousRotateMinimap ~= nil then
        local rotateMinimap = self.SszorakMarkerMapPreviousRotateMinimap
        C_CVar.SetCVar("rotateMinimap", rotateMinimap)
        MinimapCluster:SetRotateMinimap(rotateMinimap == "1")
        self.SszorakMarkerMapPreviousRotateMinimap = nil
    end
    ReturnSszorakMarkerMapCompass(self)

    self:EncounterRegister("SszorakWinds", {"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER"}, false)
    if self.IsSszorakWindsPreview and self.WindsFrame then
        self:MakeDraggable(self.WindsFrame, nil, false)
    end
    self.IsSszorakWindsPreview = false
    if self.WindsResetTimers then
        for _, timer in ipairs(self.WindsResetTimers) do
            timer:Cancel()
        end
        self.WindsResetTimers = nil
    end
    if self.WindsFrame then
        self.WindsFrame:Hide()
        for index = 1, 4 do
            self.WindsDisplay[index]:Hide()
            self.WindsNumbers[index]:Hide()
            self.WindsSenderNames[index]:Hide()
        end
        self.WindsCount = 0
    end
    self.WindsOrder = {}
    self.WindsOrderCount = 0

    self.IsSszorakBombPreview = false
    if self.SszorakBombPreviewFrames then
        for _, frame in ipairs(self.SszorakBombPreviewFrames) do
            frame:Hide()
        end
        self.SszorakBombPreviewFrames = nil
    end
    if self.SszorakAssignmentPreviewFrames then
        for _, frame in ipairs(self.SszorakAssignmentPreviewFrames) do
            frame:Hide()
        end
        self.SszorakAssignmentPreviewFrames = nil
    end
    self:EncounterRegister("SszorakBombTargets", "UNIT_TARGET", false, "boss1")
    self.BombWindowCaptures = 0
    self.AssignmentCastCount = 0
    self.AssignmentWindowCaptures = 0
    if self.BombWindowTimers then
        for _, timer in ipairs(self.BombWindowTimers) do
            timer:Cancel()
        end
        self.BombWindowTimers = nil
    end
    self.BombCount = 0
end

NSI.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    local settings = self.Assignments and self.Assignments[encID]
    if not settings then return end

    local diff = id or self:DifficultyCheck({14, 15, 16})
    if not diff or not tankComboTimers[diff] then return end
    if UnitGroupRolesAssigned("player") == "TANK" then return end

    local group
    if diff == 16 then
        if not settings.Mythic then return end
        group = self:GetSubGroup("player") <= 2 and 1 or 2
    else
        if not settings.NormalHeroic then return end
        local _, first = self:GetSortedGroup(true, false, false)
        group = 2
        for _, member in ipairs(first) do
            if UnitIsUnit(member.unitid, "player") then
                group = 1
                break
            end
        end
    end

    local alert = self:CreateDefaultAlert("", "Text", nil, nil, 1, encID, true)
    alert.dur = 6
    alert.TTSTimer = 0
    for _, timer in ipairs(tankComboTimers[diff]) do
        alert.time = timer
        alert.text = group == 1 and NSI:EncounterAlertLoc("|cFF00FF00Soak Left") or NSI:EncounterAlertLoc("|cFF00FF00Soak Right")
        alert.TTS = group == 1 and NSI:EncounterAlertLoc("Soak Left") or NSI:EncounterAlertLoc("Soak Right")
        self:AddToReminder(alert)
    end

    if NSRT.AssignmentSettings.OnPull then
        local side = group == 1 and "Left" or "Right"
        self:DisplayText(string.format(NSI:EncounterAlertLoc("You are assigned to soak |cFF00FF00%s|r"), NSI:EncounterAlertLoc(side)), 5)
    end
end
