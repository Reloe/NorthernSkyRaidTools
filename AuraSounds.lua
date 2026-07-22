local _, NSI = ... -- Internal namespace

-- Built-in aura sound entries accept:
-- {spellID = 12345, sound = "SoundName"}                         -- defaults to unit = "player", eventType = "applied"
-- {spellID = 12345, sound = "SoundName", unit = "target"}         -- unit can also be a player name, raid/party unit, bossN, focus, etc.
-- {spellID = 12345, sound = "SoundName", eventType = "removed"}   -- eventType can be "applied", "removed", or "stackGain"
NSI.AuraSoundCategories = {
    Raid = {
        {key = 3176, entries = { -- Imperator Averzian
            {spellID = 1260203, sound = "Soak"}, -- Umbral Collapse
            {spellID = 1249265, sound = "Soak"}, -- Umbral Collapse (one of them is 2nd cast I think?)
            {spellID = 1280023, sound = "Targeted"}, -- Void Marked
            {spellID = 1283069, sound = "Fixate"}, -- Weakened
        }},
        {key = 3177, entries = { -- Vorasius
            {spellID = 1254113, sound = "Fixate"}, -- Vorasius Fixate
        }},
        {key = 3179, entries = { -- Fallen-King Salhadaar
            {spellID = 1248697, sound = "Debuff"}, -- Despotic Command
            {spellID = 1268992, sound = "Targeted"}, -- Shattering Twilight
            {spellID = 1253024, sound = "Targeted"}, -- Shattering Twilight (Tank)
        }},
        {key = 3178, entries = { -- Vaelgor & Ezzorak
            {spellID = 1255612, sound = "Targeted"}, -- Dread Breath
            {spellID = 1270497, sound = "Spread"}, -- Shadowmark
        }},
        {key = 3180, entries = { -- Lightblinded Vanguard
            {spellID = 1248994, sound = "Targeted"}, -- Execution Sentence
            {spellID = 1248985, sound = "Targeted"}, -- Execution Sentence (not sure if this one is used)
            {spellID = 1246487, sound = "Spread"}, -- Avenger's Shield
            {spellID = 1248721, sound = "HealAbsorb"}, -- Tyr's Wrath
        }},
        {key = 3181, entries = { -- Crown of the Cosmos
            {spellID = 1232470, sound = "Obelisk"}, -- Grasp of Emptiness
            {spellID = 1260027, sound = "Obelisk"}, -- Grasp of Emptiness Mythic
            {spellID = 1239111, sound = "Break"}, -- Aspect of the End
            {spellID = 1233602, sound = "Targeted"}, -- Silverstrike Arrow
            {spellID = 1237623, sound = "Targeted"}, -- Ranger Captain's Mark
            {spellID = 1259861, sound = "Targeted"}, -- Ranger Captain's Mark Mythic
            {spellID = 1283236, sound = "DropPool"}, -- Void Expulsion
            {spellID = 1238708, sound = "Feather"}, -- Feather
        }},
        {key = 3306, entries = { -- Chimaerus
            {spellID = 1257087, sound = "Clear"}, -- Consuming Miasma
            {spellID = 1264756, sound = "Targeted"}, -- Rift Madness
        }},
        {key = 3182, entries = { -- Belo'ren
            {spellID = 1241339, sound = "Void"}, -- Void Dive
            {spellID = 1241292, sound = "Light"}, -- Light Dive
            {spellID = 1242091, sound = "Targeted"}, -- Void Quill
            {spellID = 1241992, sound = "Targeted"}, -- Light Quill
        }},
        {key = 3183, entries = { -- Midnight Falls
            {spellID = 1284527, sound = "Targeted"}, -- Galvanize
            {spellID = 1281184, sound = "Spread"}, -- Criticality
            {spellID = 1249609, sound = "Rune"}, -- Dark Rune
            {spellID = 1285510, sound = "Targeted"}, -- Starsplinter
            {spellID = 1279512, sound = "Targeted"}, -- Starsplinter
            {spellID = 1286294, sound = "Red"}, -- Blue Memory Game
            {spellID = 1284984, sound = "Blue"}, -- Red Memory Game
        }},
        {key = 3159, entries = { -- Rotmire
            {spellID = 1222088, sound = "Spread"}, -- Festering Vines
            {spellID = 1221639, sound = "Boss"}, -- Shroomling Fixate
            {spellID = 1299508, sound = "Ranged"}, -- Fungling Fixate
        }},
        {key = 3379, entries = { -- Nymrissa Wavecaller
            {spellID = 1258901, sound = "Targeted"}, -- Water Jet
            {spellID = 1257608, sound = "Targeted"}, -- Frost Barrage
        }},
        {key = 3470, entries = { -- Nek'zali the Soulcoiler
            {spellID = 1306666, sound = "Targeted"}, -- Hungering Pyre
            {spellID = 1294933, sound = "Clear"}, -- Slithering Flame
            {spellID = 1287434, sound = "Debuff"}, -- Essence Rend
        }},
        {key = 3445, entries = { -- Entombed Sentinels
            {spellID = 1288260, sound = "Targeted"}, -- Unstable Miasma
            {spellID = 1288297, sound = "DropPool"}, -- Clinging Murk
            {spellID = 1296880, sound = "Debuff"}, -- Shifting Protovenom
        }},
        {key = 3455, entries = { -- Vashnik the Malignant
            {spellID = 1295224, sound = "Suck"}, -- Siphoning Infection
            {spellID = 1295173, sound = "RunOut"}, -- Exploding Infection
            {spellID = 1294994, sound = "HealAbsorb"}, -- Stygian Infusion
            {spellID = 1281908, sound = "Targeted"}, -- Plague Froth
        }},
        {key = 3497, entries = { -- The Lost Explorers
            {spellID = 1295886, sound = "Fire"}, -- Frostfire Volley (Fire)
            {spellID = 1295935, sound = "Frost"}, -- Frostfire Volley (Frost)
            {spellID = 1297625, sound = "Targeted"}, -- Explosive Surprise
            {spellID = 1296092, sound = "Targeted"}, -- Mighty Thud
        }},
        {key = 3420, entries = { -- Sszorak
            {spellID = 1305963, sound = "Debuff"}, -- Venomous Surge
            {spellID = 1285453, sound = "North"}, -- Raging Crosswinds South Debuff (so we tell player to go North)
            {spellID = 1285425, sound = "South"}, -- Raging Crosswinds North Debuff (so we tell player to go South)
            {spellID = 1297096, sound = "West"}, -- Raging Crosswinds East Debuff (so we tell player to go West)
            {spellID = 1297111, sound = "East"}, -- Raging Crosswinds West Debuff (so we tell player to go East)
            {spellID = 1305621, sound = "Targeted"}, -- Serpent's Fury
            {spellID = 1297707, sound = "Spread"}, -- Virulence
            {spellID = 1299899, sound = "Spread"}, -- Virulence - both debuffs are real, similar to Starsplinters
        }},
        {key = 3421, entries = { -- The Twin Fangs
            {spellID = 1293979, sound = "Targeted"}, -- Corrosive Spit
            {spellID = 1290814, sound = "Spread"}, -- Coiling Ichor
        }},
        {key = 3429, entries = { -- The Coiled Altar
            {spellID = 1283485, sound = "Targeted"}, -- Guillotine
            {spellID = 1282419, sound = "Orb"}, -- Volatile Venom
            {spellID = 1310498, sound = "Spread"}, -- Mutagenic Venom
            {spellID = 1286901, sound = "Bomb"}, -- Gloombomb
            {spellID = 1297445, sound = "MindControl"}, -- Dreadmarch
            {spellID = 1285911, sound = "Fixate"}, -- Unnerving Fixation
        }},
        {key = 3492, entries = { -- Ula'tek
        }},
    },
    Dungeons = {
        {key = "altar_of_fangs", label = "Altar of Fangs", entries = {
        }},
        {key = "temple_of_sethraliss", label = "Temple of Sethraliss", entries = {
        }},
        {key = "ruby_life_pools", label = "Ruby Life Pools", entries = {
        }},
        {key = "kings_rest", label = "King's Rest", entries = {
        }},
        {key = "voidscar_arena", label = "Voidscar Arena", entries = {
        }},
        {key = "blinding_vale", label = "Blinding Vale", entries = {
            {spellID = 1237091, sound = "Fixate"}, -- Bloodthirsty Gaze
            {spellID = 1261276, sound = "Targeted"}, -- Thornblade
            {spellID = 1240222, sound = "Targeted"}, -- Pulverizing Strikes
        }},
        {key = "murder_row", label = "Murder Row", entries = {
            {spellID = 1214352, sound = "Spread"}, -- Fire Bomb
            {spellID = 474545, sound = "Targeted"}, -- Murder in a Row
        }},
        {key = "den_of_nalorakk", label = "Den of Nalorakk", entries = {
            {spellID = 1242869, sound = "Spread"}, -- Echoing Maul
        }},
        {key = "magisters_terrace", label = "Magister's Terrace", entries = {
            {spellID = 1225792, sound = "Debuff"}, -- Runic Mark
            {spellID = 1223958, sound = "Debuff"}, -- Cosmic Sting
            {spellID = 1215897, sound = "Targeted"}, -- Devouring Entropy
            {spellID = 1253709, sound = "Linked"}, -- Neural Link
            {spellID = 1224299, sound = "Targeted"}, -- Astral Grasp
        }},
        {key = "maisara_caverns", label = "Maisara Caverns", entries = {
            {spellID = 1260643, sound = "Targeted"}, -- Barrage
            {spellID = 1249478, sound = "Charge"}, -- Carrion Swoop
            {spellID = 1251775, sound = "Fixate"}, -- Final Pursuit
            {spellID = 1252675, sound = "Targeted"}, -- Crush Souls
        }},
        {key = "nexus_point", label = "Nexus Point", entries = {
            {spellID = 1251785, sound = "Targeted"}, -- Reflux Charge
            {spellID = 1282678, sound = "Fixate"}, -- Flailstorm
            {spellID = 1283506, sound = "Fixate"}, -- Fixate
            {spellID = 1225011, sound = "Debuff"}, -- Ethereal Shards
            {spellID = 1222098, sound = "Targeted"}, -- Nether Dash
        }},
        {key = "windrunners_spire", label = "Windrunner's Spire", entries = {
            {spellID = 466559, sound = "Targeted"}, -- Flaming Updraft
            {spellID = 474129, sound = "Spread"}, -- Splattering Spew
            {spellID = 472793, sound = "Targeted"}, -- Heaving Yank
            {spellID = 1253054, sound = "Stack"}, -- Intimidating Shout
            {spellID = 1283247, sound = "Targeted"}, -- Reckless Leap
            {spellID = 1282911, sound = "Targeted"}, -- Bolt Gale
            {spellID = 470966, sound = "Fixate"}, -- Bladestorm
            {spellID = 1253834, sound = "Fixate"}, -- Curse of Darkness
            {spellID = 1253979, sound = "Clear"}, -- Gust Shot
        }},
        {key = "pit_of_saron", label = "Pit of Saron", entries = {
            {spellID = 1261286, sound = "Targeted"}, -- Throw Saronite
            {spellID = 1264453, sound = "Fixate"}, -- Lumbering Fixation
            {spellID = 1262772, sound = "Targeted"}, -- Rime Blast
        }},
        {key = "seat_of_the_triumvirate", label = "Seat of the Triumvirate", entries = {
            {spellID = 1265426, sound = "Targeted"}, -- Discordant Beam
            {spellID = 1280064, sound = "Phase Dash"}, -- Targeted
        }},
        {key = "skyreach", label = "Skyreach", entries = {
            {spellID = 1252733, sound = "Targeted"}, -- Gale Surge
            {spellID = 1253511, sound = "Fixate"}, -- Burning Pursuit
            {spellID = 153954, sound = "Targeted"}, -- Cast Down
            {spellID = 1253531, sound = "Beam"}, -- Lens Flare
            {spellID = 1253541, sound = "Debuff"}, -- Scorching Ray
            {spellID = 1249020, sound = "Spread"}, -- Eclipsing Step
        }},
        {key = "algethar_academy", label = "Algethar Academy", entries = {
        }},
    },
    Custom = {
        {key = "custom", label = "Custom", entries = {}},
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

function NSI:GetAuraSoundKey(spellID, unit, eventType)
    spellID = tonumber(spellID)
    if not spellID then return end
    if not unit then unit = "player" end
    if not eventType or eventType == "" then eventType = "applied" end
    return tostring(spellID) .. ":" .. unit .. ":" .. eventType
end

function NSI:ResolveAuraSoundUnit(unit)
    if type(unit) ~= "string" or unit == "" then
        return "player"
    end

    unit = strtrim(unit)
    if unit == "" then
        return "player"
    end

    if unit == "player"
        or unit == "target"
        or unit == "targettarget"
        or unit == "focus"
        or unit == "focustarget"
        or unit:match("^raid%d+$")
        or unit:match("^party%d+$")
        or unit:match("^boss%d+$")
    then
        return unit
    end

    local inputName, inputRealm = strsplit("-", unit)
    if not inputName or inputName == "" then return end
    inputName = Ambiguate(inputName, "none")
    if inputRealm == "" then inputRealm = nil end
    local _, playerRealm = UnitFullName("player")

    for member in self:IterateGroupMembers() do
        local name, realm = UnitFullName(member)
        if name then
            realm = realm or playerRealm
            if (name == inputName or Ambiguate(name, "none") == inputName) and (not inputRealm or inputRealm == realm) then
                return member
            end
        end
    end
end

local function BuildAuraSoundDefaultList(categoryType)
    local list = {}
    for _, category in ipairs(NSI.AuraSoundCategories[categoryType] or {}) do
        for _, entry in ipairs(category.entries or {}) do
            if type(entry) == "table" and entry.spellID then
                local eventType = entry.eventType or "applied"
                local unit = entry.unit or "player"
                list[#list + 1] = {
                    key = entry.key or NSI:GetAuraSoundKey(entry.spellID, unit, eventType),
                    spellID = entry.spellID,
                    unit = unit,
                    eventType = eventType,
                    sound = entry.sound,
                }
            end
        end
    end
    return list
end

local SoundListRaid = BuildAuraSoundDefaultList("Raid")
local SoundListMPlus = BuildAuraSoundDefaultList("Dungeons")
local AuraSoundDefaultBySpellID = {}
for _, info in ipairs(SoundListRaid) do
    AuraSoundDefaultBySpellID[info.spellID] = info.sound
end
for _, info in ipairs(SoundListMPlus) do
    if AuraSoundDefaultBySpellID[info.spellID] == nil then
        AuraSoundDefaultBySpellID[info.spellID] = info.sound
    end
end

function NSI:GetAuraSoundDefault(spellID)
    spellID = tonumber(spellID)
    return spellID and AuraSoundDefaultBySpellID[spellID]
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

local UnitAuraSoundTrigger = Enum and Enum.UnitAuraSoundTrigger
local AuraSoundEventTriggers = {
    applied = UnitAuraSoundTrigger and UnitAuraSoundTrigger.OnAuraAdded or 0,
    stackGain = UnitAuraSoundTrigger and UnitAuraSoundTrigger.OnAuraApplicationGained or 1,
    removed = UnitAuraSoundTrigger and UnitAuraSoundTrigger.OnAuraRemoved or 2,
}

function NSI:ClearRegisteredAuraSounds()
    for _, soundID in pairs(self.AuraSoundIDs or {}) do
        C_UnitAuras.RemoveAuraSound(soundID)
    end
    self.AuraSoundIDs = {}
end

function NSI:RebuildAuraSounds(updateDefaults)
    if self:Restricted() then return end
    self:ClearRegisteredAuraSounds()
    if updateDefaults then
        self:ApplyDefaultAuraSounds(false, false, NSRT.AuraSounds.UseDefaultRaidAuraSounds)
        self:ApplyDefaultAuraSounds(false, true, NSRT.AuraSounds.UseDefaultDungeonAuraSounds)
    end
    for key, info in pairs(NSRT.AuraSounds) do
        if type(info) == "table" and info.sound then
            self:AddAuraSound(info.spellID, info.sound, key, info.unit, info.eventType)
        end
    end
end

function NSI:AddAuraSound(spellID, sound, entryKey, unit, eventType)
    spellID = tonumber(spellID)
    if not spellID then return end
    if self:Restricted() then return end
    unit = self:ResolveAuraSoundUnit(unit)
    if not eventType or eventType == "" then eventType = "applied" end

    if not self.AuraSoundIDs then self.AuraSoundIDs = {} end
    if entryKey and self.AuraSoundIDs[entryKey] then
        C_UnitAuras.RemoveAuraSound(self.AuraSoundIDs[entryKey])
        self.AuraSoundIDs[entryKey] = nil
    end
    if not unit then return end
    entryKey = entryKey or self:GetAuraSoundKey(spellID, unit, eventType)
    if not sound then return end -- essentially calling the function without a soundpath removes the sound (when user removes it in the UI)
    local soundPath = GetSoundPath(sound)
    if soundPath and soundPath ~= 1 then
        local trigger = AuraSoundEventTriggers[eventType] or AuraSoundEventTriggers.applied
        local soundInfo = {
            unitToken = unit,
            spellID = spellID,
            soundFileName = soundPath,
            outputChannel = "master",
        }
        local soundID = C_UnitAuras.AddAuraSound(trigger, soundInfo)
        self.AuraSoundIDs[entryKey] = soundID
    end
end

function NSI:ApplyDefaultAuraSounds(changed, mplus, enabled) -- only registers/unregisters sounds immediately if changed == true.
    local list = mplus and SoundListMPlus or SoundListRaid
    if enabled == nil then
        enabled = mplus and NSRT.AuraSounds.UseDefaultDungeonAuraSounds or NSRT.AuraSounds.UseDefaultRaidAuraSounds
    end
    for _, defaultInfo in ipairs(list) do
        local spellID = defaultInfo.spellID
        local sound = defaultInfo.sound
        local curSound = NSRT.AuraSounds[defaultInfo.key]
        if (not curSound) or (not curSound.edited) then -- only add default sound if user hasn't edited it prior
            if sound == "empty" then -- if sound is "empty" in the table I have marked it to be removed to clean up the table from old content
                NSRT.AuraSounds[defaultInfo.key] = nil
                if changed then self:AddAuraSound(spellID, nil, defaultInfo.key, defaultInfo.unit, defaultInfo.eventType) end
            elseif spellID then
                local appliedSound = enabled and ("|cFF4BAAC8"..sound.."|r") or nil
                NSRT.AuraSounds[defaultInfo.key] = {spellID = spellID, unit = defaultInfo.unit or "player", eventType = defaultInfo.eventType or "applied", sound = appliedSound, edited = false}
                if changed then self:AddAuraSound(spellID, appliedSound, defaultInfo.key, defaultInfo.unit, defaultInfo.eventType) end
            end
        end
    end
end

function NSI:SaveAuraSound(entryKey, spellID, sound, categoryType, categoryKey, unit, eventType)
    spellID = tonumber(spellID)
    if not entryKey or not spellID then return end
    local oldExisting = NSRT.AuraSounds[entryKey]
    unit = unit or (type(oldExisting) == "table" and oldExisting.unit) or "player"
    eventType = eventType or (type(oldExisting) == "table" and oldExisting.eventType) or "applied"
    local saveKey = self:GetAuraSoundKey(spellID, unit, eventType)
    local existing = NSRT.AuraSounds[saveKey] or oldExisting
    if entryKey ~= saveKey then
        NSRT.AuraSounds[entryKey] = nil
        self:AddAuraSound(spellID, nil, entryKey)
    end

    NSRT.AuraSounds[saveKey] = {
        spellID = spellID,
        unit = unit,
        eventType = eventType,
        sound = sound,
        edited = true,
        categoryType = categoryType or (type(existing) == "table" and existing.categoryType) or nil,
        categoryKey = categoryKey or (type(existing) == "table" and existing.categoryKey) or nil,
    }
    self:AddAuraSound(spellID, sound, saveKey, unit, eventType)
end

