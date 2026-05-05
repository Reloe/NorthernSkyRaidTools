local _, NSI = ... -- Internal namespace

local SoundListRaid = {
    -- [spellID] = "SoundName", use false to remove a sound

    -- Midnight S1
    --[1279512] = "idk", -- Shatterglass - maybe adding this later
 --   [1262983] = "Light", -- Twilight Seal (Light) - maybe adding this later, not sure if this is used at all
 --   [1262972] = "Void", -- Twilight Seal (Void) - maybe adding this later, not sure if this is used at all

    [1260203] = "Soak", -- Umbral Collapse
    [1249265] = "Soak", -- Umbral Collapse (one of them is 2nd cast I think?)
    [1280023] = "Targeted", -- Void Marked
    [1283069] = "Fixate", -- Weakened

    [1254113] = "Fixate", -- Vorasius Fixate

    [1248697] = "Debuff", -- Despotic Command
    [1268992] = "Targeted", -- Shattering Twilight
    [1253024] = "Targeted", -- Shattering Twilight (Tank)

    [1255612] = "Targeted", -- Dread Breath
    [1270497] = "Spread", -- Shadowmark

    [1248994] = "Targeted", -- Execution Sentence
    [1248985] = "Targeted", -- Execution Sentence (not sure if this one is used)
    [1246487] = "Spread", -- Avenger's Shield
    [1248721] = "HealAbsorb", -- Tyr's Wrath

    [1232470] = "Obelisk", -- Grasp of Emptiness
    [1260027] = "Obelisk", -- Grasp of Emptiness Mythic
    [1239111] = "Break", -- Aspect of the End
    [1233602] = "Targeted", -- Silverstrike Arrow
    [1237623] = "Targeted", -- Ranger Captain's Mark
    [1259861] = "Targeted", -- Ranger Captain's Mark Mythic
    [1283236] = "DropPool", --Void Expulsion
    [1238708] = "Feather", -- Feather

    [1257087] = "Clear", -- Consuming Miasma
    [1264756] = "Targeted", -- Rift Madness

    [1241339] = "Void", -- Void Dive
    [1241292] = "Light", -- Light Dive
    [1242091] = "Targeted", -- Void Quill
    [1241992] = "Targeted", -- Light Quill

    [1284527] = "Targeted", -- Galvanize
    [1281184] = "Spread", -- Criticality
    [1249609] = "Rune", -- Dark Rune
    [1285510] = "Targeted", -- Starsplinter
    [1279512] = "Targeted", -- Starsplinter
    [1286294] = "Red", -- Blue Memory Game
    [1284984] = "Blue", -- Red Memory Game
}

local SoundListMPlus = {
    -- Magister's Terrace
    [1225792] = "Debuff", -- Runic Mark
    [1223958] = "Debuff", -- Cosmic Sting
    [1215897] = "Targeted", -- Devouring Entropy
    [1253709] = "Linked", -- Neural Link
    [1224299] = "Targeted", -- Astral Grasp
    -- Maisara Caverns
    [1260643] = "Targeted", -- Barrage
    [1249478] = "Charge", -- Carrion Swoop
    [1251775] = "Fixate", -- Final Pursuit
    [1252675] = "Targeted", -- Crush Souls
    -- Nexus Point
    [1251785] = "Targeted", -- Reflux Charge
    [1282678] = "Fixate", -- Flailstorm
    -- Windrunner's Spire
    [466559] = "Targeted", -- Flaming Updraft
    [474129] = "Spread", -- Splattering Spew
    [472793] = "Targeted", -- Heaving Yank
    [1253054] = "Stack", -- Intimidating Shout
    [1283247] = "Targeted", -- Reckless Leap
    [1282911] = "Targeted", -- Bolt Gale
    [470966] = "Fixate", -- Bladestorm
    [1253834] = "Fixate", -- Curse of Darkness
    [1253979] = "Clear", -- Gust Shot
    -- Nothing in Academy
    -- Pit of Saron
    [1261286] = "Targeted", -- Throw Saronite
    [1264453] = "Fixate", -- Lumbering Fixation
    [1262772] = "Targeted", -- Rime Blast
    -- Seat of the Triumvirate
    [1265426] = "Targeted", -- Discordant Beam
    [1280064] = "Phase Dash", -- Targeted
    -- Skyreach
    [1252733] = "Targeted", -- Gale Surge
    [1253511] = "Fixate", -- Burning Pursuit
    [153954] = "Targeted", -- Cast Down
    [1253531] = "Beam", -- Lens Flare
    [1253541] = "Debuff", -- Scorching Ray
    [1249020] = "Spread", -- Eclipsing Step
    -- Den of Nalorakk
    [1242869] = "Spread", -- Echoing Maul
    -- Murder Row
    [1214352] = "Spread", -- Fire Bomb
    [474545] = "Targeted", -- Murder in a Row
    -- Blinding Vale
    [1237091] = "Fixate", -- Bloodthirsty Gaze
    [1261276] = "Targeted", -- Thornblade
    [1240222] = "Targeted", -- Pulverizing Strikes
    -- Nexus Point
    [1283506] = "Fixate", -- Fixate
    [1225011] = "Debuff", -- Ethereal Shards
    [1222098] = "Targeted", -- Nether Dash
}

function NSI:AddPASound(spellID, sound, unit)
    if self:Restricted() then return end
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
    if self.IsBuilding then return end
    if not self.PATextMoverFrame then
        self.PATextMoverFrame = CreateFrame("Frame", nil, self.NSRTFrame)
        self.PATextMoverFrame:SetPoint(NSRT.PATextSettings.Anchor, self.NSRTFrame, NSRT.PATextSettings.relativeTo, NSRT.PATextSettings.xOffset, NSRT.PATextSettings.yOffset)

        self.PATextMoverFrame.Text = self.PATextMoverFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.PATextMoverFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.PATextSettings.Scale*20, "OUTLINE")
        self.PATextMoverFrame.Text:SetText("<secret value> targets you with the spell <secret value>")
        self.PATextMoverFrame:SetSize(self.PATextMoverFrame.Text:GetStringWidth()*1, self.PATextMoverFrame.Text:GetStringHeight()*1.5)
        self.PATextMoverFrame.Text:SetPoint("CENTER", self.PATextMoverFrame, "CENTER", 0, 0)
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

function NSI:InitPrivateAuraDisplay(unit, s)
    if self.IsBuilding then return end
    if not self.PAState then self.PAState = {} end
    if not self.PAState[s] then
        self.PAState[s] = { frames = {}, anchors = {} }
    end
    local state = self.PAState[s]

    state.anchors = {}
    if not s.enabled then return end
    local xDirection = (s.GrowDirection == "RIGHT" and 1) or (s.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (s.GrowDirection == "DOWN" and -1) or (s.GrowDirection == "UP" and 1) or 0
    local stackscale = s.StackScale
    if stackscale > 3 then stackscale = 3 end -- old settings allowed this to be higher
    local borderSize = s.HideBorder and -100 or s.Width/(16*stackscale)

    for auraIndex = 1, 10 do
        if (s.Limit >= auraIndex) or auraIndex == 1 then
            if not state.frames[auraIndex] then
                state.frames[auraIndex] = CreateFrame("Frame", nil, self.NSRTFrame)
                state.frames[auraIndex]:SetFrameStrata("HIGH")
            end
            local frame = state.frames[auraIndex]
            if s.HideTooltip then
                frame:SetSize(0.001, 0.001)
            else
                frame:SetSize(s.Width/stackscale, s.Height/stackscale)
            end
            frame:ClearAllPoints()
            frame:SetScale(stackscale)
            local xPoint = s.xOffset + (auraIndex-1) * (s.Width + s.Spacing) * xDirection
            local yPoint = s.yOffset + (auraIndex-1) * (s.Height + s.Spacing) * yDirection
            frame:SetPoint(s.Anchor, self.NSRTFrame, s.relativeTo, xPoint/stackscale, yPoint/stackscale)

            if s.enabled and unit then
                state.anchors[#state.anchors + 1] = C_UnitAuras.AddPrivateAuraAnchor({
                    unitToken = unit,
                    auraIndex = auraIndex,
                    parent = frame,
                    isContainer = false,
                    showCountdownFrame = true,
                    showCountdownNumbers = not s.HideDurationText,
                    iconInfo = {
                        iconAnchor = {
                            point = "CENTER",
                            relativeTo = frame,
                            relativePoint = "CENTER",
                            offsetX = 0,
                            offsetY = 0,
                        },
                        borderScale = borderSize,
                        iconWidth = s.Width/stackscale,
                        iconHeight = s.Height/stackscale,
                    },
                })
            end
        end
    end

    -- keep legacy references for preview functions
    if s == NSRT.PASettings then
        self.PAFrames = state.frames
    elseif s == NSRT.PATankSettings then
        self.PATankFrames = state.frames
    end
end

function NSI:InitRaidPA(firstcall)
    if self.IsBuilding then return end
    if not self.PARaidFrames then self.PARaidFrames = {} end
    if not self.AddedPARaid then self.AddedPARaid = {} end
    for _, anchor in ipairs(self.AddedPARaid) do
        C_UnitAuras.RemovePrivateAuraAnchor(anchor)
    end
    self.AddedPARaid = {}

    if not NSRT.PARaidSettings.enabled then return end

    local party = not UnitInRaid("player")
    local borderSize = NSRT.PARaidSettings.HideBorder and -100 or NSRT.PARaidSettings.Width/(16*NSRT.PARaidSettings.StackScale)
    local stackscale = NSRT.PARaidSettings.StackScale or 1
    local xDirection = (NSRT.PARaidSettings.GrowDirection == "RIGHT" and 1) or (NSRT.PARaidSettings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (NSRT.PARaidSettings.GrowDirection == "DOWN" and -1) or (NSRT.PARaidSettings.GrowDirection == "UP" and 1) or 0
    local xRowDirection = (NSRT.PARaidSettings.RowGrowDirection == "RIGHT" and 1) or (NSRT.PARaidSettings.RowGrowDirection == "LEFT" and -1) or 0
    local yRowDirection = (NSRT.PARaidSettings.RowGrowDirection == "DOWN" and -1) or (NSRT.PARaidSettings.RowGrowDirection == "UP" and 1) or 0

    for i = 1, party and 5 or 40 do
        local u = party and "party"..i or "raid"..i
        if party and i == 5 then u = "player" end
        if UnitExists(u) then
            local F = self.LGF.GetUnitFrame(u)
            if firstcall and not F then
                if self.InitRaidPATimer then self.InitRaidPATimer:Cancel() end
                self.InitRaidPATimer = C_Timer.After(5, function() self.InitRaidPATimer = nil; self:InitRaidPA(false) end)
                return
            end
            if F then
                if not self.PARaidFrames[i] then
                    self.PARaidFrames[i] = CreateFrame("Frame", nil, self.NSRTFrame)
                    self.PARaidFrames[i]:SetFrameStrata("HIGH")
                end
                local frame = self.PARaidFrames[i]
                frame:SetSize(NSRT.PARaidSettings.Width/stackscale, NSRT.PARaidSettings.Height/stackscale)
                frame:SetScale(stackscale)
                frame:ClearAllPoints()
                frame:SetPoint(NSRT.PARaidSettings.Anchor, F, NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset/stackscale, NSRT.PARaidSettings.yOffset/stackscale)

                for auraIndex = 1, NSRT.PARaidSettings.Limit do
                    local row = math.ceil(auraIndex/NSRT.PARaidSettings.PerRow)
                    local column = auraIndex - (row-1)*NSRT.PARaidSettings.PerRow
                    self.AddedPARaid[#self.AddedPARaid + 1] = C_UnitAuras.AddPrivateAuraAnchor({
                        unitToken = u,
                        auraIndex = auraIndex,
                        parent = frame,
                        isContainer = false,
                        showCountdownFrame = true,
                        showCountdownNumbers = not NSRT.PARaidSettings.HideDurationText,
                        iconInfo = {
                            iconAnchor = {
                                point = NSRT.PARaidSettings.Anchor,
                                relativeTo = frame,
                                relativePoint = NSRT.PARaidSettings.relativeTo,
                                offsetX = ((column-1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xDirection + (row-1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xRowDirection) / stackscale,
                                offsetY = ((column-1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yDirection + (row-1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yRowDirection) / stackscale,
                            },
                            borderScale = borderSize,
                            iconWidth = NSRT.PARaidSettings.Width/stackscale,
                            iconHeight = NSRT.PARaidSettings.Height/stackscale,
                        },
                    })
                end
            end
        end
    end
end

function NSI:UpdatePADisplay(Personal, Tank)
    if self.IsBuilding then return end
    if Personal then
        if self.IsPAPreview then
            self:PreviewPA(true)
        else
            self:PreviewPA(false)
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
        end
    end
    self:InitPrivateAuras()
end

function NSI:PreviewPA(Show)
    if self.IsBuilding then return end
    if not self.PATextMoverFrame then self:InitTextPA() end
    if not self.PAPreviewMover then
        self.PAPreviewMover = CreateFrame("Frame", nil, self.NSRTFrame)
        self.PAPreviewMover:SetFrameStrata("HIGH")
    end
    if not Show then
        self:MakeDraggable(self.PATextMoverFrame, NSRT.PATextSettings, false)
        self:MakeDraggable(self.PAPreviewMover, NSRT.PASettings, false)
        self.PATextMoverFrame:Hide()
        self.PAPreviewMover:Hide()
        if self.PAPreviewIcons then
            for _, icon in ipairs(self.PAPreviewIcons) do
                icon:Hide()
            end
        end
        self:InitPrivateAuras()
        self:InitTextPA()
        return
    end
    self.PAPreviewMover:SetSize(NSRT.PASettings.Width, NSRT.PASettings.Height)
    self.PAPreviewMover:SetScale(1)
    self.PAPreviewMover:ClearAllPoints()
    self.PAPreviewMover:SetPoint(NSRT.PASettings.Anchor, self.NSRTFrame, NSRT.PASettings.relativeTo, NSRT.PASettings.xOffset, NSRT.PASettings.yOffset)
    self.PAPreviewMover:Show()

    self:MakeDraggable(self.PATextMoverFrame, NSRT.PATextSettings, true)
    self:MakeDraggable(self.PAPreviewMover, NSRT.PASettings, true)
    self.PATextMoverFrame:Show()
    self.PATextMoverFrame.Text:Show()
    self.PATextMoverFrame.Text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.PATextSettings.Scale*20, "OUTLINE")
    self.PATextMoverFrame:SetSize(self.PATextMoverFrame.Text:GetStringWidth()*1, self.PATextMoverFrame.Text:GetStringHeight()*1.5)
    self.PAPreviewMover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.PAPreviewMover:SetScript("OnDragStop", function(Frame)
        self:StopFrameMove(Frame, NSRT.PASettings)
    end)

    if not self.PAPreviewIcons then
        self.PAPreviewIcons = {}
    end
    for i = 1, 10 do
        if not self.PAPreviewIcons[i] then
            self.PAPreviewIcons[i] = self.PAPreviewMover:CreateTexture(nil, "ARTWORK")
            self.PAPreviewIcons[i]:SetTexture(237555)
        end
        if NSRT.PASettings.Limit >= i then
            local xOffset = (NSRT.PASettings.GrowDirection == "RIGHT" and (i-1)*(NSRT.PASettings.Width+NSRT.PASettings.Spacing)) or (NSRT.PASettings.GrowDirection == "LEFT" and -(i-1)*(NSRT.PASettings.Width+NSRT.PASettings.Spacing)) or 0
            local yOffset = (NSRT.PASettings.GrowDirection == "UP" and (i-1)*(NSRT.PASettings.Height+NSRT.PASettings.Spacing)) or (NSRT.PASettings.GrowDirection == "DOWN" and -(i-1)*(NSRT.PASettings.Height+NSRT.PASettings.Spacing)) or 0
            self.PAPreviewIcons[i]:SetSize(NSRT.PASettings.Width, NSRT.PASettings.Height)
            self.PAPreviewIcons[i]:SetPoint("CENTER", self.PAPreviewMover, "CENTER", xOffset, yOffset)
            self.PAPreviewIcons[i]:Show()
        else
            self.PAPreviewIcons[i]:Hide()
        end
    end
end

function NSI:PreviewTankPA(Show)
    if self.IsBuilding then return end
    if not self.PATankPreviewMover then
        self.PATankPreviewMover = CreateFrame("Frame", nil, self.NSRTFrame)
        self.PATankPreviewMover:SetFrameStrata("HIGH")
    end
    if not Show then
        self:MakeDraggable(self.PATankPreviewMover, NSRT.PATankSettings, false)
        self.PATankPreviewMover:Hide()
        if self.PATankPreviewIcons then
            for _, icon in ipairs(self.PATankPreviewIcons) do
                icon:Hide()
            end
        end
        local tankUnit
        for u in self:IterateGroupMembers() do
            if UnitGroupRolesAssigned(u) == "TANK" and not UnitIsUnit("player", u) then
                tankUnit = u
                break
            end
        end
        self:InitPrivateAuras()
        return
    end
    self.PATankPreviewMover:SetSize(NSRT.PATankSettings.Width, NSRT.PATankSettings.Height)
    self.PATankPreviewMover:SetScale(1)
    self.PATankPreviewMover:ClearAllPoints()
    self.PATankPreviewMover:SetPoint(NSRT.PATankSettings.Anchor, self.NSRTFrame, NSRT.PATankSettings.relativeTo, NSRT.PATankSettings.xOffset, NSRT.PATankSettings.yOffset)
    self.PATankPreviewMover:Show()

    self:MakeDraggable(self.PATankPreviewMover, NSRT.PATankSettings, true)
    self.PATankPreviewMover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.PATankPreviewMover:SetScript("OnDragStop", function(Frame)
        self:StopFrameMove(Frame, NSRT.PATankSettings)
    end)

    if not self.PATankPreviewIcons then
        self.PATankPreviewIcons = {}
    end
    for i = 1, 10 do
        if not self.PATankPreviewIcons[i] then
            self.PATankPreviewIcons[i] = self.PATankPreviewMover:CreateTexture(nil, "ARTWORK")
            self.PATankPreviewIcons[i]:SetTexture(236318)
        end
        if NSRT.PATankSettings.Limit >= i then
            local xOffset = (NSRT.PATankSettings.GrowDirection == "RIGHT" and (i-1)*(NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing)) or (NSRT.PATankSettings.GrowDirection == "LEFT" and -(i-1)*(NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing)) or 0
            local yOffset = (NSRT.PATankSettings.GrowDirection == "UP" and (i-1)*(NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing)) or (NSRT.PATankSettings.GrowDirection == "DOWN" and -(i-1)*(NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing)) or 0
            self.PATankPreviewIcons[i]:SetSize(NSRT.PATankSettings.Width, NSRT.PATankSettings.Height)
            self.PATankPreviewIcons[i]:SetPoint("CENTER", self.PATankPreviewMover, "CENTER", xOffset, yOffset)
            self.PATankPreviewIcons[i]:Show()
        else
            self.PATankPreviewIcons[i]:Hide()
        end
    end
end

function NSI:PreviewRaidPA(Show, Init)
    if self.IsBuilding then return end
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

function NSI:RemoveAllPrivateAuraAnchors()
    if self.PAState then
        for _, state in pairs(self.PAState) do
            for _, anchor in ipairs(state.anchors) do
                C_UnitAuras.RemovePrivateAuraAnchor(anchor)
            end
            state.anchors = {}
        end
    end
    if self.AddedPARaid then
        for _, anchor in ipairs(self.AddedPARaid) do
            C_UnitAuras.RemovePrivateAuraAnchor(anchor)
        end
        self.AddedPARaid = {}
    end
end

function NSI:InitPrivateAuras(firstcall)
    if self.IsBuilding then return end
    self:RemoveAllPrivateAuraAnchors()
    self:InitTextPA()
    self:InitPrivateAuraDisplay("player", NSRT.PASettings)
    local diff = select(3, GetInstanceInfo()) or 0
    if diff <= 17 and diff >= 14 and UnitGroupRolesAssigned("player") == "TANK" then -- enabled in lfr, normal, heroic, mythic
        local tankUnit
        for u in self:IterateGroupMembers() do
            if UnitGroupRolesAssigned(u) == "TANK" and not UnitIsUnit("player", u) then
                tankUnit = u
                break
            end
        end
        self:InitPrivateAuraDisplay(tankUnit, NSRT.PATankSettings)
    end
    self:InitRaidPA(firstcall)
end