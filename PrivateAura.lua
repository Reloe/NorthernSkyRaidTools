local _, NSI = ... -- Internal namespace

NSI.AuraSoundCategories = {
    Raid = {
        { key = 3176, entries = { -- Imperator Averzian
            { spellID = 1260203, sound = "Soak" }, -- Umbral Collapse
            { spellID = 1249265, sound = "Soak" }, -- Umbral Collapse (one of them is 2nd cast I think?)
            { spellID = 1280023, sound = "Targeted" }, -- Void Marked
            { spellID = 1283069, sound = "Fixate" }, -- Weakened
        } },
        { key = 3177, entries = { -- Vorasius
            { spellID = 1254113, sound = "Fixate" }, -- Vorasius Fixate
        } },
        { key = 3179, entries = { -- Fallen-King Salhadaar
            { spellID = 1248697, sound = "Debuff" }, -- Despotic Command
            { spellID = 1268992, sound = "Targeted" }, -- Shattering Twilight
            { spellID = 1253024, sound = "Targeted" }, -- Shattering Twilight (Tank)
        } },
        { key = 3178, entries = { -- Vaelgor & Ezzorak
            { spellID = 1255612, sound = "Targeted" }, -- Dread Breath
            { spellID = 1270497, sound = "Spread" }, -- Shadowmark
        } },
        { key = 3180, entries = { -- Lightblinded Vanguard
            { spellID = 1248994, sound = "Targeted" }, -- Execution Sentence
            { spellID = 1248985, sound = "Targeted" }, -- Execution Sentence (not sure if this one is used)
            { spellID = 1246487, sound = "Spread" }, -- Avenger's Shield
            { spellID = 1248721, sound = "HealAbsorb" }, -- Tyr's Wrath
        } },
        { key = 3181, entries = { -- Crown of the Cosmos
            { spellID = 1232470, sound = "Obelisk" }, -- Grasp of Emptiness
            { spellID = 1260027, sound = "Obelisk" }, -- Grasp of Emptiness Mythic
            { spellID = 1239111, sound = "Break" }, -- Aspect of the End
            { spellID = 1233602, sound = "Targeted" }, -- Silverstrike Arrow
            { spellID = 1237623, sound = "Targeted" }, -- Ranger Captain's Mark
            { spellID = 1259861, sound = "Targeted" }, -- Ranger Captain's Mark Mythic
            { spellID = 1283236, sound = "DropPool" }, -- Void Expulsion
            { spellID = 1238708, sound = "Feather" }, -- Feather
        } },
        { key = 3306, entries = { -- Chimaerus
            { spellID = 1257087, sound = "Clear" }, -- Consuming Miasma
            { spellID = 1264756, sound = "Targeted" }, -- Rift Madness
        } },
        { key = 3182, entries = { -- Belo'ren
            { spellID = 1241339, sound = "Void" }, -- Void Dive
            { spellID = 1241292, sound = "Light" }, -- Light Dive
            { spellID = 1242091, sound = "Targeted" }, -- Void Quill
            { spellID = 1241992, sound = "Targeted" }, -- Light Quill
        } },
        { key = 3183, entries = { -- Midnight Falls
            { spellID = 1284527, sound = "Targeted" }, -- Galvanize
            { spellID = 1281184, sound = "Spread" }, -- Criticality
            { spellID = 1249609, sound = "Rune" }, -- Dark Rune
            { spellID = 1285510, sound = "Targeted" }, -- Starsplinter
            { spellID = 1279512, sound = "Targeted" }, -- Starsplinter
            { spellID = 1286294, sound = "Red" }, -- Blue Memory Game
            { spellID = 1284984, sound = "Blue" }, -- Red Memory Game
        } },
        { key = 3159, entries = { -- Rotmire
            { spellID = 1222088, sound = "Spread" }, -- Festering Vines
            { spellID = 1221639, sound = "Boss" }, -- Shroomling Fixate
            { spellID = 1299508, sound = "Ranged" }, -- Fungling Fixate
        } },
        { key = 3379, entries = { -- Nymrissa Wavecaller
        } },
        { key = 3470, entries = { -- Nek'zali the Soulcoiler
            { spellID = 1306666, sound = "Targeted" }, -- Hungering Pyre
            { spellID = 1294933, sound = "Clear" }, -- Slithering Flame
            { spellID = 1287434, sound = "Debuff" }, -- Essence Rend
        } },
        { key = 3445, entries = { -- Entombed Sentinels
            { spellID = 1288260, sound = "Targeted" }, -- Unstable Miasma
            { spellID = 1288297, sound = "DropPool" }, -- Clinging Murk
            { spellID = 1296880, sound = "Debuff" }, -- Shifting Protovenom
        } },
        { key = 3455, entries = { -- Vashnik the Malignant
            { spellID = 1295224, sound = "Suck" }, -- Siphoning Infection
            { spellID = 1295173, sound = "RunOut" }, -- Exploding Infection
            { spellID = 1294994, sound = "HealAbsorb" }, -- Stygian Infusion
            { spellID = 1281908, sound = "Targeted" }, -- Plague Froth
        } },
        { key = 3497, entries = { -- The Lost Explorers
            { spellID = 1295886, sound = "Fire" }, -- Frostfire Volley (Fire)
            { spellID = 1295935, sound = "Frost" }, -- Frostfire Volley (Frost)
            { spellID = 1297625, sound = "Targeted" }, -- Explosive Surprise
            { spellID = 1296092, sound = "Targeted" }, -- Mighty Thud
        } },
        { key = 3420, entries = { -- Sszorak
            { spellID = 1305963, sound = "Debuff" }, -- Venomous Surge
            { spellID = 1285453, sound = "North" }, -- Raging Crosswinds South Debuff (so we tell player to go North)
            { spellID = 1285425, sound = "South" }, -- Raging Crosswinds North Debuff (so we tell player to go South)
            { spellID = 1297096, sound = "West" }, -- Raging Crosswinds South Debuff (so we tell player to go East)
            { spellID = 1297111, sound = "East" }, -- Raging Crosswinds North Debuff (so we tell player to go West)
            { spellID = 1305621, sound = "Targeted" }, -- Serpent's Fury
            { spellID = 1297707, sound = "DropPool" }, -- Virulence
            { spellID = 1299899, sound = "DropPool" }, -- Virulence - both debuffs are real, similar to Starsplinters
        } },
        { key = 3421, entries = { -- The Twin Fangs
            { spellID = 1293979, sound = "Targeted" }, -- Corrosive Spit
            { spellID = 1290814, sound = "Spread" }, -- Coiling Ichor
        } },
        { key = 3429, entries = { -- The Coiled Altar
            { spellID = 1283485, sound = "Targeted" }, -- Guillotine
            { spellID = 1282419, sound = "Orb" }, -- Volatile Venom
            { spellID = 1310498, sound = "Spread" }, -- Mutagenic Venom
            { spellID = 1286901, sound = "Bomb" }, -- Gloombomb
            { spellID = 1297445, sound = "MindControl" }, -- Dreadmarch
            { spellID = 1285911, sound = "Fixate" }, -- Unnerving Fixation
        } },
        { key = 3492, entries = { -- Ula'tek
        } },
    },
    Dungeons = {
        { key = "altar_of_fangs", label = "Altar of Fangs", entries = {
        } },
        { key = "temple_of_sethraliss", label = "Temple of Sethraliss", entries = {
        } },
        { key = "ruby_life_pools", label = "Ruby Life Pools", entries = {
        } },
        { key = "kings_rest", label = "King's Rest", entries = {
        } },
        { key = "voidscar_arena", label = "Voidscar Arena", entries = {
        } },
        { key = "blinding_vale", label = "Blinding Vale", entries = {
            { spellID = 1237091, sound = "Fixate" }, -- Bloodthirsty Gaze
            { spellID = 1261276, sound = "Targeted" }, -- Thornblade
            { spellID = 1240222, sound = "Targeted" }, -- Pulverizing Strikes
        } },
        { key = "murder_row", label = "Murder Row", entries = {
            { spellID = 1214352, sound = "Spread" }, -- Fire Bomb
            { spellID = 474545, sound = "Targeted" }, -- Murder in a Row
        } },
        { key = "den_of_nalorakk", label = "Den of Nalorakk", entries = {
            { spellID = 1242869, sound = "Spread" }, -- Echoing Maul
        } },
        { key = "magisters_terrace", label = "Magister's Terrace", entries = {
            { spellID = 1225792, sound = "Debuff" }, -- Runic Mark
            { spellID = 1223958, sound = "Debuff" }, -- Cosmic Sting
            { spellID = 1215897, sound = "Targeted" }, -- Devouring Entropy
            { spellID = 1253709, sound = "Linked" }, -- Neural Link
            { spellID = 1224299, sound = "Targeted" }, -- Astral Grasp
        } },
        { key = "maisara_caverns", label = "Maisara Caverns", entries = {
            { spellID = 1260643, sound = "Targeted" }, -- Barrage
            { spellID = 1249478, sound = "Charge" }, -- Carrion Swoop
            { spellID = 1251775, sound = "Fixate" }, -- Final Pursuit
            { spellID = 1252675, sound = "Targeted" }, -- Crush Souls
        } },
        { key = "nexus_point", label = "Nexus Point", entries = {
            { spellID = 1251785, sound = "Targeted" }, -- Reflux Charge
            { spellID = 1282678, sound = "Fixate" }, -- Flailstorm
            { spellID = 1283506, sound = "Fixate" }, -- Fixate
            { spellID = 1225011, sound = "Debuff" }, -- Ethereal Shards
            { spellID = 1222098, sound = "Targeted" }, -- Nether Dash
        } },
        { key = "windrunners_spire", label = "Windrunner's Spire", entries = {
            { spellID = 466559, sound = "Targeted" }, -- Flaming Updraft
            { spellID = 474129, sound = "Spread" }, -- Splattering Spew
            { spellID = 472793, sound = "Targeted" }, -- Heaving Yank
            { spellID = 1253054, sound = "Stack" }, -- Intimidating Shout
            { spellID = 1283247, sound = "Targeted" }, -- Reckless Leap
            { spellID = 1282911, sound = "Targeted" }, -- Bolt Gale
            { spellID = 470966, sound = "Fixate" }, -- Bladestorm
            { spellID = 1253834, sound = "Fixate" }, -- Curse of Darkness
            { spellID = 1253979, sound = "Clear" }, -- Gust Shot
        } },
        { key = "pit_of_saron", label = "Pit of Saron", entries = {
            { spellID = 1261286, sound = "Targeted" }, -- Throw Saronite
            { spellID = 1264453, sound = "Fixate" }, -- Lumbering Fixation
            { spellID = 1262772, sound = "Targeted" }, -- Rime Blast
        } },
        { key = "seat_of_the_triumvirate", label = "Seat of the Triumvirate", entries = {
            { spellID = 1265426, sound = "Targeted" }, -- Discordant Beam
            { spellID = 1280064, sound = "Phase Dash" }, -- Targeted
        } },
        { key = "skyreach", label = "Skyreach", entries = {
            { spellID = 1252733, sound = "Targeted" }, -- Gale Surge
            { spellID = 1253511, sound = "Fixate" }, -- Burning Pursuit
            { spellID = 153954, sound = "Targeted" }, -- Cast Down
            { spellID = 1253531, sound = "Beam" }, -- Lens Flare
            { spellID = 1253541, sound = "Debuff" }, -- Scorching Ray
            { spellID = 1249020, sound = "Spread" }, -- Eclipsing Step
        } },
        { key = "algethar_academy", label = "Algethar Academy", entries = {
        } },
    },
    Custom = {
        { key = "custom", label = "Custom", entries = {} },
    },
}

NSI.AuraSoundDungeonIcons = {
    altar_of_fangs = 7956175,
    temple_of_sethraliss = 2011143,
    ruby_life_pools = 4578416,
    kings_rest = 2011123,
    voidscar_arena = 7439626,
    blinding_vale = 7354408,
    murder_row = 7266213,
    den_of_nalorakk = 7266214,
    magisters_terrace = 7439625,
    maisara_caverns = 7322719,
    nexus_point = 7553062,
    windrunners_spire = 7266215,
    pit_of_saron = 343641,
    seat_of_the_triumvirate = 1711340,
    skyreach = 1002596,
    algethar_academy = 4578414,
}

local function BuildAuraSoundDefaultList(categoryType)
    local list = {}
    for _, category in ipairs(NSI.AuraSoundCategories[categoryType] or {}) do
        for _, entry in ipairs(category.entries or {}) do
            if type(entry) == "table" and entry.spellID then
                list[entry.spellID] = entry.sound
            end
        end
    end
    return list
end

local SoundListRaid = BuildAuraSoundDefaultList("Raid")
local SoundListMPlus = BuildAuraSoundDefaultList("Dungeons")

function NSI:GetAuraSoundDefault(spellID)
    return SoundListRaid[spellID] or SoundListMPlus[spellID]
end

local function StripSoundColor(sound)
    if type(sound) ~= "string" then return sound end
    return sound:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function GetSoundPath(sound)
    if not NSI.LSM or not sound then return end
    local cleanSound = StripSoundColor(sound)
    local soundPath = NSI.LSM:Fetch("sound", sound, true) or NSI.LSM:Fetch("sound", cleanSound, true)
    if soundPath then return soundPath end

    if not NSI.LSMSoundCache and NSI.CacheSounds then
        NSI:CacheSounds()
    end

    local lsmKey = NSI.LSMSoundCache and (NSI.LSMSoundCache[cleanSound] or NSI.LSMSoundCache[strlower(cleanSound)])
    return lsmKey and NSI.LSM:Fetch("sound", lsmKey, true)
end

function NSI:IsValidPASoundSpell(spellID)
    if not spellID then return false end
    if self:IsMidnightS2() then return true end
    return C_UnitAuras.AuraIsPrivate and C_UnitAuras.AuraIsPrivate(spellID)
end

function NSI:GetAuraAppliedSoundAPI()
    if self:IsMidnightS2() and C_UnitAuras.AddAuraAppliedSound and C_UnitAuras.RemoveAuraAppliedSound then
        return C_UnitAuras.AddAuraAppliedSound, C_UnitAuras.RemoveAuraAppliedSound
    end
    return C_UnitAuras.AddPrivateAuraAppliedSound, C_UnitAuras.RemovePrivateAuraAppliedSound
end

function NSI:AddPASound(spellID, sound, unit)
    if self:Restricted() then return end
    if not self:IsValidPASoundSpell(spellID) then return end
    if not unit then unit = "player" end
    local addAuraSound, removeAuraSound = self:GetAuraAppliedSoundAPI()
    if not addAuraSound or not removeAuraSound then return end

    if not self.PrivateAuraSoundIDs then self.PrivateAuraSoundIDs = {} end
    if not self.PrivateAuraSoundIDs[unit] then self.PrivateAuraSoundIDs[unit] = {} end
    if self.PrivateAuraSoundIDs[unit][spellID] then
        removeAuraSound(self.PrivateAuraSoundIDs[unit][spellID])
        self.PrivateAuraSoundIDs[unit][spellID] = nil
    end
    if not sound then return end -- essentially calling the function without a soundpath removes the sound (when user removes it in the UI)
    local soundPath = GetSoundPath(sound)
    if soundPath and soundPath ~= 1 then
        local soundID = addAuraSound({
            unitToken = unit,
            spellID = spellID,
            soundFileName = soundPath,
            outputChannel = "master",
        })
        self.PrivateAuraSoundIDs[unit][spellID] = soundID
    end
end

function NSI:ApplyDefaultPASounds(changed, mplus, enabled) -- only registers/unregisters sounds immediately if changed == true.
    local list = mplus and SoundListMPlus or SoundListRaid
    if enabled == nil then
        enabled = mplus and NSRT.PASounds.UseDefaultMPlusPASounds or NSRT.PASounds.UseDefaultPASounds
    end
    for spellID, sound in pairs(list) do
        local curSound = NSRT.PASounds[spellID]
        if (not curSound) or (not curSound.edited) then -- only add default sound if user hasn't edited it prior
            if sound == "empty" then -- if sound is "empty" in the table I have marked it to be removed to clean up the table from old content
                NSRT.PASounds[spellID] = nil
                if changed then self:AddPASound(spellID, nil) end
            elseif self:IsValidPASoundSpell(spellID) then
                local appliedSound = enabled and ("|cFF4BAAC8"..sound.."|r") or nil
                NSRT.PASounds[spellID] = {sound = appliedSound, edited = false}
                if changed then self:AddPASound(spellID, appliedSound) end
            end
        end
    end
end

function NSI:SavePASound(spellID, sound, categoryType, categoryKey)
    if (not spellID) then return end
    local existing = NSRT.PASounds[spellID]
    NSRT.PASounds[spellID] = {
        sound = sound,
        edited = true,
        categoryType = categoryType or (type(existing) == "table" and existing.categoryType) or nil,
        categoryKey = categoryKey or (type(existing) == "table" and existing.categoryKey) or nil,
    }
    self:AddPASound(spellID, sound)
    if not self:IsValidPASoundSpell(spellID) then
        NSRT.PASounds[spellID] = nil
    end
end

function NSI:InitTextPA()
    if self.IsBuilding then return end
    if not self.PATextMoverFrame then
        self.PATextMoverFrame = CreateFrame("Frame", nil, self.NSRTFrame)
        self.PATextMoverFrame:SetPoint(NSRT.PATextSettings.Anchor, self.NSRTFrame, NSRT.PATextSettings.relativeTo, NSRT.PATextSettings.xOffset, NSRT.PATextSettings.yOffset)

        self.PATextMoverFrame.Text = self.PATextMoverFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.PATextMoverFrame.Text:SetFont(self:GetGlobalFontPath(), NSRT.PATextSettings.Scale*20, "OUTLINE")
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
    self.PATextMoverFrame.Text:SetFont(self:GetGlobalFontPath(), NSRT.PATextSettings.Scale*20, "OUTLINE")
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
    self.PARaidPreviewFrame:ClearAllPoints()
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
            self.PARaidPreviewIcons[i].Text:SetFont(self:GetGlobalFontPath(), 16, "OUTLINE")
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
    if self:DifficultyCheck({14, 15, 16}) and UnitGroupRolesAssigned("player") == "TANK" then -- enabled in normal, heroic, mythic
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
