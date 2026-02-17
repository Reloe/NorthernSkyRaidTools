local _, NSI = ... -- Internal namespace

local SoundListRaid = {
    -- [spellID] = "SoundName", use false to remove a sound

    -- Midnight S1
    [1284527] = "Targeted", -- Galvanize
    [1283236] = "Targeted", --Void Expulsion
    [1283069] = "Fixate", -- Weakened
    [1281184] = "Spread", -- Criticality
    [1280023] = "Targeted", -- Void Marked
    --[1279512] = "idk", -- Shatterglass - maybe adding this later
    [1249609] = "Rune", -- Dark Rune
    [1268992] = "Targeted", -- Shattering Twilight
    [1253024] = "Targeted", -- Shattering Twilight (Tank)
    [1270497] = "Spread", -- Shadowmark
    [1264756] = "Targeted", -- Rift Madness
    [1260027] = "Targeted", -- Grasp of Emptiness
    [1232470] = "Targeted", -- Grasp of Emptiness (idk which one is correct)
    [1260203] = "Soak", -- Umbral Collapse
    [1249265] = "Soak", -- Umbral Collapse (one of them is 2nd cast I think?)
    [1259861] = "Targeted", -- Ranger Captain's Mark
    [1237623] = "Targeted", -- Ranger Captain's Mark(idk which one is correct)
 --   [1262983] = "Light", -- Twilight Seal (Light) - maybe adding this later, not sure if this is used at all
 --   [1262972] = "Void", -- Twilight Seal (Void) - maybe adding this later, not sure if this is used at all
    [1257087] = "Clear", -- Consuming Miasma
    [1255612] = "Targeted", -- Dread Breath
    [1248697] = "Debuff", -- Despotic Command
    [1248994] = "Targeted", -- Execution Sentence
    [1248985] = "Targeted", -- Execution Sentence (not sure if this one is used)
    [1246487] = "Spread", -- Avenger's Shield
    [1242091] = "Targeted", -- Void Quill
    [1241992] = "Targeted", -- Light Quill
    [1241339] = "Void", -- Void Dive
    [1241292] = "Light", -- Light Dive
    [1239111] = "Break", -- Aspect of the End
    [1233887] = "Debuff", -- Null Corona
    [1254113] = "Fixate", -- Vorasius Fixate
}

local SoundListMPlus = {
    -- Magister's Terrace
    [1225792] = "Debuff", -- Runic Mark
    [1223958] = "Targeted", -- Cosmic Sting
    [1215897] = "Targeted", -- Devouring Entropy
    [1253709] = "Linked", -- Neural Link
    -- Maisara Caverns
    [1260643] = "Targeted", -- Barrage
    [1249478] = "Charge", -- Carrion Swoop
    [1251775] = "Fixate", -- Final Pursuit
    -- Nexus Point
    [1251785] = "Targeted", -- Reflux Charge
    -- Windrunner's Spire
    [466559] = "Targeted", -- Flaming Updraft
    [474129] = "Spread", -- Splattering Spew
    [472793] = "Targeted", -- Heaving Yank
    [1253054] = "Stack", -- Intimidating Shout
    [1283247] = "Targeted", -- Reckless Leap
    [1282911] = "Targeted", -- Bolt Gale
    -- Nothing in Academy
    -- Pit of Saron
    [1261286] = "Targeted", -- Throw Saronite
    [1264453] = "Fixate", -- Lumbering Fixation
    [1262772] = "Targeted", -- Rime Blast
    -- Seat of the Triumvirate
    [1265426] = "Targeted", -- Discordant Beam
    -- Skyreach
    [1252733] = "Targeted", -- Gale Surge
    [1253511] = "Fixate", -- Burning Pursuit
    [153954] = "Targeted", -- Cast Down
    [1253531] = "Beam", -- Lens Flare
}

function NSI:AddPASound(spellID, sound, unit)
    if (not spellID) or (not C_UnitAuras.AuraIsPrivate(spellID)) then return end
    if not unit then unit = "player" end
    if not self.PrivateAuraSoundIDs then self.PrivateAuraSoundIDs = {} end
    if not self.PrivateAuraSoundIDs[unit] then self.PrivateAuraSoundIDs[unit] = {} end
    if self.PrivateAuraSoundIDs[unit][spellID] then
        C_UnitAuras.RemovePrivateAuraAppliedSound(self.PrivateAuraSoundIDs[unit][spellID])
        self.PrivateAuraSoundIDs[unit][spellID] = nil
    end
    if not sound then return end -- essentially calling the function without a soundpath removes the sound (when user removes it in the UI)
    local soundPath = NSI.LSM:Fetch("sound", sound)
    if soundPath and soundPath ~= 1 then
        local soundID = C_UnitAuras.AddPrivateAuraAppliedSound({
            unitToken = unit,
            spellID = spellID,
            soundFileName = soundPath,
            outputChannel = "master",
        })
        self.PrivateAuraSoundIDs[unit][spellID] = soundID
    end
end

function NSI:ApplyDefaultPASounds(changed, mplus) -- only apply sound if changed == true, this happens when user changes the settings but not on login so we don't apply the sounds twice.
    local list = mplus and SoundListMPlus or SoundListRaid
    for spellID, sound in pairs(list) do
        local curSound = NSRT.PASounds[spellID]
        if (not curSound) or (not curSound.edited) then -- only add default sound if user hasn't edited it prior
            if sound == "empty" then -- if sound is "empty" in the table I have marked it to be removed to clean up the table from old content
                NSRT.PASounds[spellID] = nil
                if changed then self:AddPASound(spellID, nil) end
            elseif C_UnitAuras.AuraIsPrivate(spellID) then
                sound = "|cFF4BAAC8"..sound.."|r"
                NSRT.PASounds[spellID] = {sound = sound, edited = false}
                if changed then self:AddPASound(spellID, sound) end
            end
        end
    end
end

function NSI:SavePASound(spellID, sound)
    if (not spellID) then return end
    NSRT.PASounds[spellID] = {sound = sound, edited = true}
    self:AddPASound(spellID, sound)
    if not (C_UnitAuras.AuraIsPrivate(spellID)) then
        NSRT.PASounds[spellID] = nil
    end
end

function NSI:InitTextPA()
    if not self.PATextMoverFrame then
        self.PATextMoverFrame = CreateFrame("Frame", nil, self.NSRTFrame)
        self.PATextMoverFrame:SetPoint(NSRT.PATextSettings.Anchor, self.NSRTFrame, NSRT.PATextSettings.relativeTo, NSRT.PATextSettings.xOffset, NSRT.PATextSettings.yOffset)

        self.PATextMoverFrame.Text = self.PATextMoverFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.PATextMoverFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.PATextSettings.Scale*20, "OUTLINE")
        self.PATextMoverFrame.Text:SetText("<secret value> targets you with the spell <secret value>")
        self.PATextMoverFrame:SetSize(self.PATextMoverFrame.Text:GetStringWidth()*1, self.PATextMoverFrame.Text:GetStringHeight()*1.5)
        self.PATextMoverFrame.Text:SetPoint("CENTER", self.PATextMoverFrame, "CENTER", 0, 0)

        if not self.PATextMoverFrame.Border then
            self.PATextMoverFrame.Border = CreateFrame("Frame", nil, self.PATextMoverFrame, "BackdropTemplate")
            self.PATextMoverFrame.Border:SetPoint("TOPLEFT", self.PATextMoverFrame, "TOPLEFT", -6, 6)
            self.PATextMoverFrame.Border:SetPoint("BOTTOMRIGHT", self.PATextMoverFrame, "BOTTOMRIGHT", 6, -6)
            self.PATextMoverFrame.Border:SetBackdrop({
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 2,
                })
            self.PATextMoverFrame.Border:SetBackdropBorderColor(1, 1, 1, 1)
        end
        self:ToggleMoveFrames(self.PATextMoverFrame, true)
        self.PATextMoverFrame.Border:Hide()
        self.PATextMoverFrame:Hide()
        self.PATextMoverFrame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        self.PATextMoverFrame:SetScript("OnDragStop", function(Frame)
            self:StopFrameMove(Frame, NSRT.PATextSettings)
        end)
    end
    if NSRT.PATextSettings.enabled then
        if not self.PATextWarning then
            self.PATextWarning = CreateFrame("Frame", nil, self.NSRTFrame)
        end

        local height = self.PATextMoverFrame:GetHeight()
        -- I have absolutely no clue why this math works out but it does
        self.PATextWarning:SetPoint("TOPLEFT", self.PATextMoverFrame, "TOPLEFT", 0, -0.8*height/NSRT.PATextSettings.Scale)
        self.PATextWarning:SetPoint("BOTTOMRIGHT", self.PATextMoverFrame, "BOTTOMRIGHT", 0, -0.8*height/NSRT.PATextSettings.Scale)
        self.PATextWarning:SetScale(NSRT.PATextSettings.Scale)

        local textanchor =
        {
            point = "CENTER",
            relativeTo = self.PATextWarning,
            relativePoint = "CENTER",
            offsetX = 0,
            offsetY = 0
        }
        C_UnitAuras.SetPrivateWarningTextAnchor(self.PATextWarning, textanchor)
    end
end

function NSI:InitPA()

    if not self.PAFrames then self.PAFrames = {} end
    if not self.PADurFrames then self.PADurFrames = {} end
    if not self.PAAnchorFrames then self.PAAnchorFrames = {} end

    if not self.AddedPA then self.AddedPA = {} end
    if not self.AddedDurPA then self.AddedDurPA = {} end
    local xDirection = (NSRT.PASettings.GrowDirection == "RIGHT" and 1) or (NSRT.PASettings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (NSRT.PASettings.GrowDirection == "DOWN" and -1) or (NSRT.PASettings.GrowDirection == "UP" and 1) or 0
    local borderSize = NSRT.PASettings.HideBorder and -100 or NSRT.PASettings.Width/16
    local scale = NSRT.PASettings.StackScale or 4
    for auraIndex=1, 10 do
        local anchorID = "NSRT_PA"..auraIndex
        if self.AddedPA[anchorID] then
            C_UnitAuras.RemovePrivateAuraAnchor(self.AddedPA[anchorID])
            self.AddedPA[anchorID] = nil
        end
        if self.AddedDurPA[anchorID] then
            C_UnitAuras.RemovePrivateAuraAnchor(self.AddedDurPA[anchorID])
            self.AddedDurPA[anchorID] = nil
        end
        if NSRT.PASettings.enabled and NSRT.PASettings.Limit >= auraIndex or auraIndex == 1 then
            if not self.PAFrames[auraIndex] then
                self.PAFrames[auraIndex] = CreateFrame("Frame", nil, self.NSRTFrame)
                self.PAFrames[auraIndex]:SetFrameStrata("HIGH")
            end
            if not self.PADurFrames[auraIndex] then
                self.PADurFrames[auraIndex] = CreateFrame("Frame", nil, self.NSRTFrame)
                self.PADurFrames[auraIndex]:SetSize(0.001, 0.001)
                self.PADurFrames[auraIndex]:SetFrameStrata("DIALOG")
                self.PADurFrames[auraIndex]:SetPoint("CENTER", self.PAFrames[auraIndex], "CENTER", 0, 0)
            end
            if not self.PAAnchorFrames[auraIndex] then
                self.PAAnchorFrames[auraIndex] = CreateFrame("Frame", nil, self.NSRTFrame)
            end
            if NSRT.PASettings.HideTooltip then
                self.PAFrames[auraIndex]:SetSize(0.001, 0.001)
            else
                self.PAFrames[auraIndex]:SetSize(NSRT.PASettings.Width, NSRT.PASettings.Height)
            end
            self.PAAnchorFrames[auraIndex]:SetSize(NSRT.PASettings.Width, NSRT.PASettings.Height)
            self.PADurFrames[auraIndex]:SetScale(scale)
            self.PAFrames[auraIndex]:ClearAllPoints()
            self.PAAnchorFrames[auraIndex]:ClearAllPoints()
            self.PAAnchorFrames[auraIndex]:SetPoint(NSRT.PASettings.Anchor, self.NSRTFrame, NSRT.PASettings.relativeTo,
            NSRT.PASettings.xOffset+(auraIndex-1) * (NSRT.PASettings.Width+NSRT.PASettings.Spacing) * xDirection,
            NSRT.PASettings.yOffset+(auraIndex-1) * (NSRT.PASettings.Height+NSRT.PASettings.Spacing) * yDirection)
            self.PAFrames[auraIndex]:SetPoint(NSRT.PASettings.Anchor, self.NSRTFrame, NSRT.PASettings.relativeTo,
            NSRT.PASettings.xOffset+(auraIndex-1) * (NSRT.PASettings.Width+NSRT.PASettings.Spacing) * xDirection,
            NSRT.PASettings.yOffset+(auraIndex-1) * (NSRT.PASettings.Height+NSRT.PASettings.Spacing) * yDirection)
            if not NSRT.PASettings.enabled then return end
            local frame = self.PAFrames[auraIndex]
            local privateAnchorArgs = {
                unitToken = "player",
                auraIndex = auraIndex,
                parent = frame,
                showCountdownFrame = true,
                showCountdownNumbers = not NSRT.PASettings.UpscaleDuration,
                iconInfo = {
                    iconAnchor = {
                        point = "CENTER",
                        relativeTo = frame,
                        relativePoint = "CENTER",
                        offsetX = 0,
                        offsetY = 0,
                    },
                    borderScale = borderSize,
                    iconWidth = NSRT.PASettings.Width,
                    iconHeight = NSRT.PASettings.Height,
                },
            }
            self.AddedPA[anchorID] = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
            if scale ~= 1 then
                local durationArgs = {
                    unitToken = "player",
                    auraIndex = auraIndex,
                    parent = self.PADurFrames[auraIndex],
                    showCountdownFrame = false,
                    showCountdownNumbers = false,
                    iconInfo = {
                        iconAnchor = {
                            point = "BOTTOMRIGHT",
                            relativeTo = self.PAAnchorFrames[auraIndex],
                            relativePoint = "BOTTOMRIGHT",
                            offsetX = 2,
                            offsetY = -4,
                        },
                        borderScale = -100,
                        iconWidth = 0.001,
                        iconHeight = 0.001,
                    },
                }
                if NSRT.PASettings.UpscaleDuration then
                    durationArgs.durationAnchor = {
                        point = "CENTER",
                        relativeTo = self.PAFrames[auraIndex],
                        relativePoint = "CENTER",
                        offsetX = 0,
                        offsetY = 0,
                    }
                end
                self.AddedDurPA[anchorID] = C_UnitAuras.AddPrivateAuraAnchor(durationArgs)
            end
        end
    end
end

function NSI:InitRaidPA(party, firstcall) -- still run this function if disabled to clean up old anchors
    if not self.PARaidFrames then self.PARaidFrames = {} end
    if not self.PAStackFrames then self.PAStackFrames = {} end
    if not self.PARaidAnchorFrames then self.PARaidAnchorFrames = {} end
    if not self.AddedPARaid then self.AddedPARaid = {} end
    if not self.AddedPAStackRaid then self.AddedPAStackRaid = {} end
    local borderSize = NSRT.PARaidSettings.HideBorder and -100 or NSRT.PARaidSettings.Width/16
    local scale = NSRT.PARaidSettings.StackScale or 1
    for i=1, party and 5 or 40 do
        local anchorID = party and "NSRT_PAParty"..i or "NSRT_PARaid"..i
        if self.AddedPARaid and self.AddedPARaid[anchorID] then
            for auraIndex = 1, 10 do
                if self.AddedPARaid[anchorID][auraIndex] then
                    C_UnitAuras.RemovePrivateAuraAnchor(self.AddedPARaid[anchorID][auraIndex])
                    self.AddedPARaid[anchorID][auraIndex] = nil
                end
            end
        end
        if self.AddedPAStackRaid and self.AddedPAStackRaid[anchorID] then
            for auraIndex = 1, 10 do
                if self.AddedPAStackRaid[anchorID] and self.AddedPAStackRaid[anchorID][auraIndex] then
                    C_UnitAuras.RemovePrivateAuraAnchor(self.AddedPAStackRaid[anchorID][auraIndex])
                    self.AddedPAStackRaid[anchorID][auraIndex] = nil
                end
            end
        end
        local u = party and "party"..i or "raid"..i
        if party and i == 5 then u = "player" end
        if NSRT.PARaidSettings.enabled and UnitExists(u) then
            local F = self.LGF.GetUnitFrame(u)
            if firstcall and not F then
                C_Timer.After(5, function() self:InitRaidPA(party, false) end)
                return
            end
            if F then
                if not self.PARaidFrames[i] then
                    self.PARaidFrames[i] = CreateFrame("Frame", nil, self.NSRTFrame)
                    self.PARaidFrames[i]:SetFrameStrata("HIGH")
                end
                if not self.PARaidAnchorFrames[i] then
                    self.PARaidAnchorFrames[i] = CreateFrame("Frame", nil, self.NSRTFrame)
                end
                if not self.PAStackFrames[i] then
                    self.PAStackFrames[i] = CreateFrame("Frame", nil, self.NSRTFrame)
                    self.PAStackFrames[i]:SetSize(0.001, 0.001)
                    self.PAStackFrames[i]:SetFrameStrata("DIALOG")
                end

                self.PARaidAnchorFrames[i]:SetSize(NSRT.PARaidSettings.Width, NSRT.PARaidSettings.Height)
                self.PAStackFrames[i]:SetScale(scale)
                self.PARaidFrames[i]:ClearAllPoints()
                self.PARaidAnchorFrames[i]:ClearAllPoints()
                self.PARaidAnchorFrames[i]:SetPoint(NSRT.PARaidSettings.Anchor, F, NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset, NSRT.PARaidSettings.yOffset)
                self.PARaidFrames[i]:SetSize(0.001, 0.001)
                self.PARaidFrames[i]:SetPoint(NSRT.PARaidSettings.Anchor, F, NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset, NSRT.PARaidSettings.yOffset)
                local xDirection = (NSRT.PARaidSettings.GrowDirection == "RIGHT" and 1) or (NSRT.PARaidSettings.GrowDirection == "LEFT" and -1) or 0
                local yDirection = (NSRT.PARaidSettings.GrowDirection == "DOWN" and -1) or (NSRT.PARaidSettings.GrowDirection == "UP" and 1) or 0
                local xRowDirection = (NSRT.PARaidSettings.RowGrowDirection == "RIGHT" and 1) or (NSRT.PARaidSettings.RowGrowDirection == "LEFT" and -1) or 0
                local yRowDirection = (NSRT.PARaidSettings.RowGrowDirection == "DOWN" and -1) or (NSRT.PARaidSettings.RowGrowDirection == "UP" and 1) or 0
                self.AddedPARaid[anchorID] = {}
                self.AddedPAStackRaid[anchorID] = {}
                for auraIndex = 1, 10 do
                    if auraIndex > NSRT.PARaidSettings.Limit then break end
                    local row = math.ceil(auraIndex/NSRT.PARaidSettings.PerRow)
                    local column = auraIndex - (row-1)*NSRT.PARaidSettings.PerRow
                    local privateAnchorArgs = {
                        unitToken = u,
                        auraIndex = auraIndex,
                        parent = self.PARaidFrames[i],
                        showCountdownFrame = true,
                        showCountdownNumbers = not NSRT.PARaidSettings.HideDurationText,
                        iconInfo = {
                            iconAnchor = {
                                point = NSRT.PARaidSettings.Anchor,
                                relativeTo = self.PARaidFrames[i],
                                relativePoint = NSRT.PARaidSettings.relativeTo,
                                offsetX = (column - 1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xDirection + (row - 1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xRowDirection,
                                offsetY = (column - 1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yDirection + (row - 1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yRowDirection,
                            },
                            borderScale = borderSize,
                            iconWidth = NSRT.PARaidSettings.Width,
                            iconHeight = NSRT.PARaidSettings.Height,
                        }
                    }
                    self.AddedPARaid[anchorID][auraIndex] = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
                    if scale ~= 1 then
                        local stackArgs = {
                            unitToken = u,
                            auraIndex = auraIndex,
                            parent = self.PAStackFrames[i],
                            showCountdownFrame = false,
                            showCountdownNumbers = false,
                            iconInfo = {
                                iconAnchor = {
                                    point = "BOTTOMRIGHT",
                                    relativeTo = self.PARaidAnchorFrames[i],
                                    relativePoint = "BOTTOMRIGHT",
                                    offsetX = 4/scale + ((column - 1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xDirection)/scale + ((row - 1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xRowDirection)/scale,
                                    offsetY = -4/scale + ((column - 1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yDirection)/scale + ((row - 1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yRowDirection)/scale,
                                },
                                borderScale = -100,
                                iconWidth = 0.001,
                                iconHeight = 0.001,
                            },
                        }
                        self.AddedPAStackRaid[anchorID][auraIndex] = C_UnitAuras.AddPrivateAuraAnchor(stackArgs)
                    end
                end
            end
        end
    end
end

function NSI:RemoveTankPA()
    if not self.AddedTankPA then return end
    for i, anchortable in ipairs(self.AddedTankPA) do
        if self.AddedTankPA[i] then
            for anchorID, anchor in pairs(anchortable) do
                if self.AddedTankPA[i][anchorID] then
                    C_UnitAuras.RemovePrivateAuraAnchor(anchor)
                    self.AddedTankPA[i][anchorID] = nil
                end
                if self.AddedTankDurPA[i] and self.AddedTankDurPA[i][anchorID] then
                    C_UnitAuras.RemovePrivateAuraAnchor(self.AddedTankDurPA[i][anchorID])
                    self.AddedTankDurPA[i][anchorID] = nil
                end
            end
        end
    end
end

function NSI:InitTankPA()
    -- initiated on ENCOUNTER_START for tank players
    if not self.PATankFrames then self.PATankFrames = {} end
    if not self.PATankDurFrames then self.PATankDurFrames = {} end
    if not self.PATankAnchorFrames then self.PATankAnchorFrames = {} end
    if not self.AddedTankPA then self.AddedTankPA = {} end
    if not self.AddedTankDurPA then self.AddedTankDurPA = {} end
    local xDirection = (NSRT.PATankSettings.GrowDirection == "RIGHT" and 1) or (NSRT.PATankSettings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (NSRT.PATankSettings.GrowDirection == "DOWN" and -1) or (NSRT.PATankSettings.GrowDirection == "UP" and 1) or 0

    local multiTankx = (NSRT.PATankSettings.MultiTankGrowDirection == "RIGHT" and 1) or (NSRT.PATankSettings.MultiTankGrowDirection == "LEFT" and -1) or 0
    local multiTanky = (NSRT.PATankSettings.MultiTankGrowDirection == "DOWN" and -1) or (NSRT.PATankSettings.MultiTankGrowDirection == "UP" and 1) or 0
    local units = {}
    for unit in self:IterateGroupMembers() do
        if UnitGroupRolesAssigned(unit) == "TANK" and not (UnitIsUnit("player", unit)) then
            table.insert(units, unit)
        end
    end
    -- remove any previous anchor, also calling this on ENCOUNTER_END
    self:RemoveTankPA()
    local borderSize = NSRT.PATankSettings.HideBorder and -100 or NSRT.PATankSettings.Width/16
    local scale = NSRT.PATankSettings.StackScale or 4
    for i, unit in ipairs(units) do
        if not self.PATankFrames[i] then self.PATankFrames[i] = {} end
        if not self.PATankDurFrames[i] then self.PATankDurFrames[i] = {} end
        if not self.PATankAnchorFrames[i] then self.PATankAnchorFrames[i] = {} end
        self.AddedTankPA[i] = self.AddedTankPA[i] or {}
        self.AddedTankDurPA[i] = self.AddedTankDurPA[i] or {}
        for auraIndex = 1, 10 do
            local anchorID = "NSRT_TankPA"..auraIndex
            if self.AddedTankPA[i][anchorID] then
                C_UnitAuras.RemovePrivateAuraAnchor(self.AddedTankPA[i][anchorID])
                self.AddedTankPA[i][anchorID] = nil
            end
            if self.AddedTankDurPA[i][anchorID] then
                C_UnitAuras.RemovePrivateAuraAnchor(self.AddedTankDurPA[i][anchorID])
                self.AddedTankDurPA[i][anchorID] = nil
            end

            if NSRT.PATankSettings.enabled and NSRT.PATankSettings.Limit >= auraIndex then
                if not self.PATankFrames[i][auraIndex] then
                    self.PATankFrames[i][auraIndex] = CreateFrame("Frame", nil, self.NSRTFrame)
                    self.PATankFrames[i][auraIndex]:SetFrameStrata("HIGH")
                end
                if not self.PATankDurFrames[i][auraIndex] then
                    self.PATankDurFrames[i][auraIndex] = CreateFrame("Frame", nil, self.NSRTFrame)
                    self.PATankDurFrames[i][auraIndex]:SetSize(0.001, 0.001)
                    self.PATankDurFrames[i][auraIndex]:SetFrameStrata("DIALOG")
                end
                if not self.PATankAnchorFrames[i][auraIndex] then
                    self.PATankAnchorFrames[i][auraIndex] = CreateFrame("Frame", nil, self.NSRTFrame)
                    self.PATankAnchorFrames[i][auraIndex]:SetAllPoints(self.PATankFrames[i][auraIndex])
                end
                if NSRT.PATankSettings.HideTooltip then
                    self.PATankFrames[i][auraIndex]:SetSize(0.001, 0.001)
                else
                    self.PATankFrames[i][auraIndex]:SetSize(NSRT.PATankSettings.Width, NSRT.PATankSettings.Height)
                end

                self.PATankAnchorFrames[i][auraIndex]:SetSize(NSRT.PATankSettings.Width, NSRT.PATankSettings.Height)
                self.PATankDurFrames[i][auraIndex]:SetScale(scale)
                self.PATankDurFrames[i][auraIndex]:SetPoint("CENTER", self.PATankFrames[i][auraIndex], "CENTER", 0, 0)
                self.PATankFrames[i][auraIndex]:ClearAllPoints()
                self.PATankAnchorFrames[i][auraIndex]:ClearAllPoints()
                self.PATankAnchorFrames[i][auraIndex]:SetPoint(NSRT.PATankSettings.Anchor, self.NSRTFrame, NSRT.PATankSettings.relativeTo,
                NSRT.PATankSettings.xOffset+(auraIndex-1) * (NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing) * xDirection + (i-1) * (NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing) * multiTankx,
                NSRT.PATankSettings.yOffset+(auraIndex-1) * (NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing) * yDirection + (i-1) * (NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing) * multiTanky)
                self.PATankFrames[i][auraIndex]:SetPoint(NSRT.PATankSettings.Anchor, self.NSRTFrame, NSRT.PATankSettings.relativeTo,
                NSRT.PATankSettings.xOffset+(auraIndex-1) * (NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing) * xDirection + (i-1) * (NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing) * multiTankx,
                NSRT.PATankSettings.yOffset+(auraIndex-1) * (NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing) * yDirection + (i-1) * (NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing) * multiTanky)

                local privateAnchorArgs = {
                    unitToken = unit,
                    auraIndex = auraIndex,
                    parent = self.PATankFrames[i][auraIndex],
                    showCountdownFrame = true,
                    showCountdownNumbers = not NSRT.PATankSettings.UpscaleDuration,
                    iconInfo = {
                        iconAnchor = {
                            point = "CENTER",
                            relativeTo = self.PATankFrames[i][auraIndex],
                            relativePoint = "CENTER",
                            offsetX = 0,
                            offsetY = 0,
                        },
                        borderScale = borderSize,
                    iconWidth = NSRT.PATankSettings.Width,
                    iconHeight = NSRT.PATankSettings.Height,
                    }
                }
                self.AddedTankPA[i][anchorID] = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
                if scale ~= 1 then
                    local durationArgs = {
                        unitToken = unit,
                        auraIndex = auraIndex,
                        parent = self.PATankDurFrames[i][auraIndex],
                        showCountdownFrame = false,
                        showCountdownNumbers = false,
                        iconInfo = {
                            iconAnchor = {
                                point = "BOTTOMRIGHT",
                                relativeTo = self.PATankAnchorFrames[i][auraIndex],
                                relativePoint = "BOTTOMRIGHT",
                                offsetX = 2,
                                offsetY = -4,
                            },
                            borderScale = -100,
                            iconWidth = 0.001,
                            iconHeight = 0.001,
                        },
                    }
                    if NSRT.PATankSettings.UpscaleDurations then
                        durationArgs.durationAnchor = {
                            point = "CENTER",
                            relativeTo = self.PATankFrames[i][auraIndex],
                            relativePoint = "CENTER",
                            offsetX = 0,
                            offsetY = 0,
                        }
                    end
                    self.AddedTankDurPA[i][anchorID] = C_UnitAuras.AddPrivateAuraAnchor(durationArgs)
                end
            end
        end
    end
end

function NSI:UpdatePADisplay(Personal, Tank)
    if Personal then
        if self.IsPAPreview then
            self:PreviewPA(true)
        else
            self:PreviewPA(false)
            self:InitPA()
            self:InitTextPA()
        end
    elseif Tank then
        if self.IsTankPAPreview then
            self:PreviewTankPA(true)
        else
            self:PreviewTankPA(false)
        end
    else
        if self.IsRaidPAPreview then
            self:PreviewRaidPA(true, true)
        else
            self:PreviewRaidPA(false)
            self:InitRaidPA(not UnitInRaid("player"))
        end
    end
end

function NSI:PreviewPA(Show)
    if not self.PAFrames then self:InitPA() end
    if not Show then

        if self.PAFrames[1].Border then self.PAFrames[1].Border:Hide() end

        self:ToggleMoveFrames(self.PATextMoverFrame, false)
        self:ToggleMoveFrames(self.PAFrames[1], false)
        self.PATextMoverFrame:Hide()
        self.PAFrames[1]:SetSize(1, 1)
        self:InitPA()
        self:InitTextPA()
        if self.PAPreviewIcons then
            for _, icon in ipairs(self.PAPreviewIcons) do
                icon:Hide()
            end
        end
        return
    end
    if not self.PATextMoverFrame then
        self:InitTextPA()
    end
    self.PAFrames[1]:SetSize((NSRT.PASettings.Width), (NSRT.PASettings.Height))
    self.PAFrames[1]:SetPoint(NSRT.PASettings.Anchor, self.NSRTFrame, NSRT.PASettings.relativeTo, NSRT.PASettings.xOffset, NSRT.PASettings.yOffset)
    if not self.PAFrames[1].Border then
        self.PAFrames[1].Border = CreateFrame("Frame", nil, self.PAFrames[1], "BackdropTemplate")
        self.PAFrames[1].Border:SetPoint("TOPLEFT", self.PAFrames[1], "TOPLEFT", -6, 6)
        self.PAFrames[1].Border:SetPoint("BOTTOMRIGHT", self.PAFrames[1], "BOTTOMRIGHT", 6, -6)
        self.PAFrames[1].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
        self.PAFrames[1].Border:SetBackdropBorderColor(1, 1, 1, 1)
        self.PAFrames[1].Border:Hide()
    end

    self:ToggleMoveFrames(self.PATextMoverFrame, true)
    self:ToggleMoveFrames(self.PAFrames[1], true)
    self.PATextMoverFrame:Show()
    self.PATextMoverFrame.Border:Show()
    self.PATextMoverFrame.Text:Show()
    self.PATextMoverFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.PATextSettings.Scale*20, "OUTLINE")
    self.PATextMoverFrame:SetSize(self.PATextMoverFrame.Text:GetStringWidth()*1, self.PATextMoverFrame.Text:GetStringHeight()*1.5)
    self.PAFrames[1].Border:Show()
    self.PAFrames[1]:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.PAFrames[1]:SetScript("OnDragStop", function(Frame)
        self:StopFrameMove(Frame, NSRT.PASettings)
    end)

    if not self.PAPreviewIcons then
        self.PAPreviewIcons = {}
    end
    for i=1, 10 do
        if not self.PAPreviewIcons[i] then
            self.PAPreviewIcons[i] = self.PAFrames[1]:CreateTexture(nil, "ARTWORK")
            self.PAPreviewIcons[i]:SetTexture(237555)
        end
        if NSRT.PASettings.Limit >= i then
            local xOffset = (NSRT.PASettings.GrowDirection == "RIGHT" and (i-1)*(NSRT.PASettings.Width+NSRT.PASettings.Spacing)) or (NSRT.PASettings.GrowDirection == "LEFT" and -(i-1)*(NSRT.PASettings.Width+NSRT.PASettings.Spacing)) or 0
            local yOffset = (NSRT.PASettings.GrowDirection == "UP" and (i-1)*(NSRT.PASettings.Height+NSRT.PASettings.Spacing)) or (NSRT.PASettings.GrowDirection == "DOWN" and -(i-1)*(NSRT.PASettings.Height+NSRT.PASettings.Spacing)) or 0
            self.PAPreviewIcons[i]:SetSize(NSRT.PASettings.Width, NSRT.PASettings.Height)
            self.PAPreviewIcons[i]:SetPoint("CENTER", self.PAFrames[1], "CENTER", xOffset, yOffset)
            self.PAPreviewIcons[i]:Show()
        else
            self.PAPreviewIcons[i]:Hide()
        end
    end
end

function NSI:PreviewTankPA(Show)
    if not self.PATankFrames then self:InitTankPA() end
    if not self.PATankFrames[1] or not self.PATankFrames[1][1] then
        self.PATankFrames[1] = self.PATankFrames[1] or {}
        self.PATankFrames[1][1] = CreateFrame("Frame", nil, self.NSRTFrame)
        self.PATankFrames[1][1]:SetPoint(NSRT.PATankSettings.Anchor, self.NSRTFrame, NSRT.PATankSettings.relativeTo, NSRT.PATankSettings.xOffset, NSRT.PATankSettings.yOffset)
    end
    if not Show then
        if self.PATankFrames[1][1].Border then self.PATankFrames[1][1].Border:Hide() end
        self:ToggleMoveFrames(self.PATankFrames[1][1], false)
        self.PATankFrames[1][1]:SetSize(1, 1)
        if self.PATankPreviewIcons then
            for _, icon in ipairs(self.PATankPreviewIcons) do
                icon:Hide()
            end
        end
        self:RemoveTankPA()
        if UnitGroupRolesAssigned("player") == "TANK" or NSRT.Settings.Debug then
            self:InitTankPA()
        end
        return
    end
    self.PATankFrames[1][1]:SetSize((NSRT.PATankSettings.Width), (NSRT.PATankSettings.Height))
    self.PATankFrames[1][1]:SetPoint(NSRT.PATankSettings.Anchor, self.NSRTFrame, NSRT.PATankSettings.relativeTo, NSRT.PATankSettings.xOffset, NSRT.PATankSettings.yOffset)
    if not self.PATankFrames[1][1].Border then
        self.PATankFrames[1][1].Border = CreateFrame("Frame", nil, self.PATankFrames[1][1], "BackdropTemplate")
        self.PATankFrames[1][1].Border:SetPoint("TOPLEFT", self.PATankFrames[1][1], "TOPLEFT", -6, 6)
        self.PATankFrames[1][1].Border:SetPoint("BOTTOMRIGHT", self.PATankFrames[1][1], "BOTTOMRIGHT", 6, -6)
        self.PATankFrames[1][1].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
        self.PATankFrames[1][1].Border:SetBackdropBorderColor(1, 1, 1, 1)
        self.PATankFrames[1][1].Border:Hide()
    end

    self:ToggleMoveFrames(self.PATankFrames[1][1], true)
    self.PATankFrames[1][1]:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.PATankFrames[1][1]:SetScript("OnDragStop", function(Frame)
        self:StopFrameMove(Frame, NSRT.PATankSettings)
    end)

    if not self.PATankPreviewIcons then
        self.PATankPreviewIcons = {}
    end
    for i=1, 10 do
        if not self.PATankPreviewIcons[i] then
            self.PATankPreviewIcons[i] = self.PATankFrames[1][1]:CreateTexture(nil, "ARTWORK")
            self.PATankPreviewIcons[i]:SetTexture(236318)
        end
        if NSRT.PATankSettings.Limit >= i then
            local xOffset = (NSRT.PATankSettings.GrowDirection == "RIGHT" and (i-1)*(NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing)) or (NSRT.PATankSettings.GrowDirection == "LEFT" and -(i-1)*(NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing)) or 0
            local yOffset = (NSRT.PATankSettings.GrowDirection == "UP" and (i-1)*(NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing)) or (NSRT.PATankSettings.GrowDirection == "DOWN" and -(i-1)*(NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing)) or 0
            self.PATankPreviewIcons[i]:SetSize(NSRT.PATankSettings.Width, NSRT.PATankSettings.Height)
            self.PATankPreviewIcons[i]:SetPoint("CENTER", self.PATankFrames[1][1], "CENTER", xOffset, yOffset)
            self.PATankPreviewIcons[i]:Show()
        else
            self.PATankPreviewIcons[i]:Hide()
        end
    end
end

function NSI:PreviewRaidPA(Show, Init)
    if not Show then
        if self.PARaidPreviewFrame then self.PARaidPreviewFrame:Hide() end
        return
    end
    local MyFrame = self.LGF.GetUnitFrame("player")
    if not MyFrame then -- try again if no frame was found, as the first querry returns nil
        if Init then
            if self.RepeatRaidPAPreview then self.RepeatRaidPAPreview:Cancel() end
            self.RepeatRaidPAPreview = C_Timer.NewTimer(0.2, function() self:PreviewRaidPA(Show, false) end)
        else
            print("Couldn't find a matching raid frame for the player, aborting preview")
            self.IsRaidPAPreview = false
        end
        return
    end
    if not self.PARaidPreviewFrame then
        self.PARaidPreviewFrame = CreateFrame("Frame", nil, self.NSRTFrame)
        self.PARaidPreviewFrame:SetFrameStrata("DIALOG")
    end
    self.PARaidPreviewFrame:SetSize(NSRT.PARaidSettings.Width, NSRT.PARaidSettings.Height)
    self.PARaidPreviewFrame:SetPoint(NSRT.PARaidSettings.Anchor, MyFrame, NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset, NSRT.PARaidSettings.yOffset)
    self.PARaidPreviewFrame:Show()

    if not self.PARaidPreviewIcons then
        self.PARaidPreviewIcons = {}
    end

    local xDirection = (NSRT.PARaidSettings.GrowDirection == "RIGHT" and 1) or (NSRT.PARaidSettings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (NSRT.PARaidSettings.GrowDirection == "DOWN" and -1) or (NSRT.PARaidSettings.GrowDirection == "UP" and 1) or 0
    local xRowDirection = (NSRT.PARaidSettings.RowGrowDirection == "RIGHT" and 1) or (NSRT.PARaidSettings.RowGrowDirection == "LEFT" and -1) or 0
    local yRowDirection = (NSRT.PARaidSettings.RowGrowDirection == "DOWN" and -1) or (NSRT.PARaidSettings.RowGrowDirection == "UP" and 1) or 0
    for i=1, 10 do
        local row = math.ceil(i/NSRT.PARaidSettings.PerRow)
        local column = i - (row-1)*NSRT.PARaidSettings.PerRow
        if not self.PARaidPreviewIcons[i] then
            self.PARaidPreviewIcons[i] = self.PARaidPreviewFrame:CreateTexture(nil, "ARTWORK")
            self.PARaidPreviewIcons[i]:SetTexture(237555)
            self.PARaidPreviewIcons[i].Text = self.PARaidPreviewFrame:CreateFontString(nil, "OVERLAY")
            self.PARaidPreviewIcons[i].Text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), 16, "OUTLINE")
            self.PARaidPreviewIcons[i].Text:SetPoint("CENTER", self.PARaidPreviewIcons[i], "CENTER", 0, 0)
            self.PARaidPreviewIcons[i].Text:SetText(i)
            self.PARaidPreviewIcons[i].Text:SetTextColor(1, 0, 0, 1)
        end
        if NSRT.PARaidSettings.Limit >= i then
            local xOffset = (column - 1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xDirection + (row - 1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xRowDirection
            local yOffset = (column - 1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yDirection + (row- 1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yRowDirection
            self.PARaidPreviewIcons[i]:SetSize(NSRT.PARaidSettings.Width, NSRT.PARaidSettings.Height)
            self.PARaidPreviewIcons[i]:SetPoint("CENTER", self.PARaidPreviewFrame, "CENTER", xOffset, yOffset)
            self.PARaidPreviewIcons[i]:Show()
            self.PARaidPreviewIcons[i].Text:Show()
        else
            self.PARaidPreviewIcons[i]:Hide()
            self.PARaidPreviewIcons[i].Text:Hide()
        end
    end
end