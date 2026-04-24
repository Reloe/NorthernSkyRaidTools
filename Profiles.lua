local _, NSI = ...


function NSI:AddMissingDefaults()
    local defaults = {
        -- Saved data tables (user-populated, empty by default)
        NickNames = {},
        Reminders = {},
        PersonalReminders = {},
        InviteList = {},
        AssignmentSettings = {},
        CooldownList = {},
        PASounds = {
            UseDefaultPASounds = false,
            UseDefaultMPlusPASounds = false,
        },
        PhaseTimings = {},

        -- Active reminder persistence
        ActiveReminder = nil,
        ActivePersonalReminder = {},
        StoredSharedReminder = nil,
        StoredPersonalReminder = nil,

        -- NSUI / timeline window
        NSUI = {
            scale = 1,
            timeline_window = {
                scale = 1,
            },
            AutoComplete = {
                Addon = {},
            },
            reminders_frame = {},
        },

        -- General Settings
        Settings = {
            GlobalFont = "Expressway",
            GlobalFontSize = 20,
            GlobalEncounterFontSize = 20,
            GlobalFontFlags = "OUTLINE",
            MyNickName = nil,
            ShareNickNames = 4,
            AcceptNickNames = 4,
            NickNamesSyncAccept = 2,
            NickNamesSyncSend = 3,
            GlobalNickNames = false,
            TTS = true,
            TTSVolume = 50,
            TTSVoice = 1,
            TTSOverlap = true,
            Minimap = {hide = false},
            VersionCheckPresets = {},
            CooldownThreshold = 20,
            MissingRaidBuffs = true,
            CheckCooldowns = false,
            UnreadyOnCooldown = false,
            Debug = false,
            GenericDisplay = {
                Anchor = "CENTER",
                relativeTo = "CENTER",
                xOffset = -200,
                yOffset = 400,
            },
        },

        -- Reminder Settings
        ReminderSettings = {
            enabled = true,
            PersNote = true,
            Sticky = 5,
            SpellTTS = true,
            TextTTS = true,
            SpellDuration = 10,
            TextDuration = 10,
            SpellCountdown = 0,
            TextCountdown = 0,
            SpellName = true,
            SpellTTSTimer = 5,
            TextTTSTimer = 5,
            AutoShare = true,
            NoteCountdown = false,
            HideTimerText = false,
            HideTextTimerText = false,
            PersonalReminderFrame = {
                enabled = true,
                Width = 500,
                Height = 600,
                Anchor = "TOPLEFT",
                relativeTo = "TOPLEFT",
                xOffset = 500,
                yOffset = 0,
                Font = "Expressway",
                FontSize = 14,
                BGcolor = {0, 0, 0, 0.3},
            },
            ReminderFrame = {
                enabled = false,
                Width = 500,
                Height = 600,
                Anchor = "TOPLEFT",
                relativeTo = "TOPLEFT",
                xOffset = 0,
                yOffset = 0,
                Font = "Expressway",
                FontSize = 14,
                BGcolor = {0, 0, 0, 0.3},
            },
            ExtraReminderFrame = {
                enabled = false,
                Width = 500,
                Height = 600,
                Anchor = "TOPLEFT",
                relativeTo = "TOPLEFT",
                xOffset = 0,
                yOffset = 0,
                Font = "Expressway",
                FontSize = 14,
                BGcolor = {0, 0, 0, 0.3},
            },
            IconSettings = {
                GrowDirection = "Down",
                Anchor = "CENTER",
                relativeTo = "CENTER",
                colors = {1, 1, 1, 1},
                xOffset = -500,
                yOffset = 400,
                xTextOffset = 0,
                yTextOffset = 0,
                xTimer = 0,
                yTimer = 0,
                Font = "Expressway",
                FontSize = 30,
                TimerFontSize = 40,
                Width = 80,
                Height = 80,
                Spacing = -1,
                Glow = 0,
            },
            BarSettings = {
                GrowDirection = "Up",
                Anchor = "CENTER",
                relativeTo = "CENTER",
                Width = 300,
                Height = 40,
                xIcon = 0,
                yIcon = 0,
                colors = {1, 0, 0, 1},
                Texture = "Atrocity",
                xOffset = -400,
                yOffset = 0,
                xTextOffset = 2,
                yTextOffset = 0,
                xTimer = -2,
                yTimer = 0,
                Font = "Expressway",
                FontSize = 22,
                TimerFontSize = 22,
                Spacing = -1,
            },
            TextSettings = {
                colors = {1, 1, 1, 1},
                GrowDirection = "Up",
                Anchor = "CENTER",
                relativeTo = "CENTER",
                xOffset = 0,
                yOffset = 200,
                Font = "Expressway",
                FontSize = 50,
                Spacing = 1,
            },
            UnitIconSettings = {
                Position = "CENTER",
                xOffset = 0,
                yOffset = 0,
                Width = 25,
                Height = 25,
            },
            GlowSettings = {
                colors = {0, 1, 0, 1},
                Lines = 10,
                Frequency = 0.2,
                Length = 10,
                Thickness = 4,
                xOffset = 0,
                yOffset = 0,
            },
        },

        SharedNotes = {

        },

        PersonalNotes = {

        },

        -- Private Aura Settings
        PASettings = {
            Spacing = -1,
            Limit = 5,
            GrowDirection = "RIGHT",
            enabled = false,
            Width = 100,
            Height = 100,
            Anchor = "CENTER",
            relativeTo = "CENTER",
            xOffset = -450,
            yOffset = -100,
            PerRow = 10,
            RowGrowDirection = "UP",
            DebuffTypeBorder = false,
            HideBorder = false,
            StackScale = 4,
            AlternateDisplay = false,
            HideTooltip = false,
            UpscaleDuration = false,
        },
        PATankSettings = {
            Spacing = -1,
            Limit = 5,
            MultiTankGrowDirection = "UP",
            GrowDirection = "LEFT",
            enabled = false,
            Width = 100,
            Height = 100,
            Anchor = "CENTER",
            relativeTo = "CENTER",
            xOffset = -549,
            yOffset = -199,
            HideBorder = false,
            StackScale = 4,
            AlternateDisplay = false,
            HideTooltip = false,
            UpscaleDuration = false,
        },
        PARaidSettings = {
            PerRow = 3,
            RowGrowDirection = "UP",
            Spacing = -1,
            Limit = 5,
            GrowDirection = "RIGHT",
            enabled = false,
            Width = 25,
            Height = 25,
            Anchor = "BOTTOMLEFT",
            relativeTo = "BOTTOMLEFT",
            xOffset = 0,
            yOffset = 0,
            HideBorder = false,
            StackScale = 1,
            HideDurationText = false,
        },
        PATextSettings = {
            Scale = 2.5,
            xOffset = 0,
            yOffset = -200,
            enabled = false,
            Anchor = "TOP",
            relativeTo = "TOP",
        },

        -- Ready Check Settings
        ReadyCheckSettings = {
            RaidBuffCheck = false,
            SoulstoneCheck = false,
            CraftedCheck = false,
            EnchantCheck = false,
            GemCheck = false,
            ItemLevelCheck = false,
            RepairCheck = false,
            TierCheck = false,
            MissingItemCheck = false,
            GatewayShardCheck = false,
            SkipGatewayKeybindCheck = false,
            SourceOfMagicCheck = false,
        },

        -- QoL Settings
        QoL = {
            GatewayUseableDisplay = false,
            ResetBossDisplay = false,
            LootBossReminder = false,
            AutoRepair = false,
            AutoInvite = false,
            ConsumableNotificationDurationSeconds = 5,
            TextDisplay = {
                Anchor = "CENTER",
                relativeTo = "CENTER",
                xOffset = 0,
                yOffset = 0,
                FontSize = 30,
            },
            IconDisplay = {
                Anchor = "TOP",
                relativeTo = "TOP",
                GrowDirection = "DOWN",
                Scpaing = 5,
                xOffset = 0,
                yOffset = -350,
                Width = 40,
                Height = 40,
            },
            TradeableItems = {
                Anchor = "TOP",
                relativeTo = "TOP",
                GrowDirection = "DOWN",
                Spacing = 5,
                xOffset = 0,
                yOffset = -400,
                FontSize = 18,
                Width = 30,
                Height = 30,
            },
        },

        -- Encounter Alerts
        EncounterAlerts = {
            [3176] = {enabled = false},
            [3177] = {enabled = false},
            [3178] = {enabled = false, HealthDisplay = false},
            [3179] = {enabled = false, CCAddsDisplay = false},
            [3180] = {enabled = false, TauntAlerts = false, HealAbsorbTicks = false},
            [3181] = {enabled = false},
            [3182] = {enabled = false},
            [3183] = {
                enabled = false,
                P3Side = "OFF",
                RunesDisplay = false,
                LuraDisplayAnchor = NSRT and NSRT.Settings and NSRT.Settings.LuraDisplayAnchor or "TOPLEFT",
                LuraDisplayRelativePoint = NSRT and NSRT.Settings and NSRT.Settings.LuraDisplayRelativePoint or "TOPLEFT",
                LuraDisplayOffsetX = NSRT and NSRT.Settings and NSRT.Settings.LuraDisplayOffsetX or 300,
                LuraDisplayOffsetY = NSRT and NSRT.Settings and NSRT.Settings.LuraDisplayOffsetY or -300,
                LuraDisplayColor = NSRT and NSRT.Settings and NSRT.Settings.LuraDisplayColor or {0.5, 0.5, 0.5, 0.9},
            },
            [3306] = {enabled = false},
        },

        Profiles = {},
        ProfileKeys = {},
        CurrentProfile = "default",
        MainProfile = "default",

        AutoLoadNote = {},
    }
    if not NSRT then
        NSRT = {}
    end
    for k, v in pairs(defaults) do
        if NSRT[k] == nil then
            NSRT[k] = v
        elseif type(v) == "table" then
            if type(NSRT[k]) == "table" then
                self:AddMissingTableDefaults(NSRT[k], v)
            else
                NSRT[k] = v
            end
        end
    end
end

function NSI:AddMissingTableDefaults(NSRTTable, defaultsTable)
    for k, v in pairs(defaultsTable) do
        if NSRTTable[k] == nil then
            NSRTTable[k] = v
        elseif type(v) == "table" then
            if type(NSRTTable[k]) == "table" then
                self:AddMissingTableDefaults(NSRTTable[k], v)
            else
                NSRTTable[k] = v
            end
        end
    end
end

local ignored = {
    ["Profiles"] = true,
    ["ProfileKeys"] = true,
    ["CurrentProfile"] = true,
    ["MainProfile"] = true,
}

function NSI:GetProfileKey()
    local CharName, Realm = UnitFullName("player")
    if not Realm then
        Realm = GetNormalizedRealmName()
    end
    return Realm and CharName.."-"..Realm
end

function NSI:SetMainProfile(name)
    if NSRT.Profiles[name] then
        NSRT.MainProfile = name
    end
end

function NSI:CreateProfile(name, init)
    if not name then
        name = "default"
    end
    NSRT.Profiles = NSRT.Profiles or {}
    NSRT.ProfileKeys = NSRT.ProfileKeys or {}
    if NSRT.Profiles[name] then
        self:LoadProfile(name)
        return
    end
    NSRT.Profiles[name] = {}
    self:SaveProfile()
    if not name == "default" then
        for k, v in pairs(NSRT) do
            if not ignored[k] then
                NSRT[k] = nil
            end
        end
    end
    self:AddMissingDefaults()
    local ProfileKey = self:GetProfileKey()
    NSRT.ProfileKeys[ProfileKey] = name
    NSRT.CurrentProfile = name
    if not init then self:SetReminder(NSRT.StoredPersonalReminder, true) end
    self:SaveProfile()
end

function NSI:LoadProfile(name, skipsave, init)
    if not skipsave then self:SaveProfile() end
    if NSRT.Profiles[name] then
        for k, v in pairs(NSRT.Profiles[name]) do
            if not ignored[k] then
                NSRT[k] = type(v) == "table" and CopyTable(v) or v
            end
        end
    end
    local ProfileKey = self:GetProfileKey()
    NSRT.ProfileKeys[ProfileKey] = name
    NSRT.CurrentProfile = name
    if not init then self:SetReminder(NSRT.StoredPersonalReminder, true) end
    self:AddMissingDefaults()
    self:SaveProfile()
end

function NSI:SaveProfile()
    if NSRT.CurrentProfile then
        NSRT.Profiles[NSRT.CurrentProfile] = {}
        for k, v in pairs(NSRT) do
            if not ignored[k] then
                NSRT.Profiles[NSRT.CurrentProfile][k] = type(v) == "table" and CopyTable(v) or v
            end
        end
    end
end

function NSI:DeleteProfile(name, allowdefault)
    if name == "default" and not allowdefault then return end
    if NSRT.Profiles[name] then
        print("|cFF00FFFFNSRT:|r deleting profile", name)
        NSRT.Profiles[name] = nil
    end
    for k, profileName in pairs(NSRT.ProfileKeys) do
        if profileName == name then
            NSRT.ProfileKeys[k] = nil
        end
    end
    if name == NSRT.CurrentProfile then
        NSRT.CurrentProfile = nil
        self:LoadMyProfile()
    end
end

function NSI:ResetProfile(name)
    self:DeleteProfile(name, true)
    self:CreateProfile(name)
end

function NSI:CopyFromProfile(name)
    if not NSRT.CurrentProfile then return end
    if NSRT.Profiles[name] then
        NSRT.Profiles[NSRT.CurrentProfile] = CopyTable(NSRT.Profiles[name])
        self:LoadProfile(NSRT.CurrentProfile, true)
    end
end

function NSI:ExportProfileString()
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")
    local profileData = NSRT.Profiles[NSRT.CurrentProfile]
    if not profileData then return nil end
    local exportTable = {
        profileName = NSRT.CurrentProfile,
        data = profileData,
    }
    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return encoded
end

function NSI:ImportProfileString(importString)
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")
    if not importString or importString == "" then return nil end
    local decoded = LibDeflate:DecodeForPrint(importString)
    if not decoded then return nil end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil end
    local success, exportTable = LibSerialize:Deserialize(decompressed)
    if not success or type(exportTable) ~= "table" then return nil end
    local name = exportTable.profileName or "Imported"
    local function EnsureUniqueName(name)
        if NSRT.Profiles[name] then
            name = name.." 2"
            return EnsureUniqueName(name)
        end
        return name
    end
    name = EnsureUniqueName(name)
    NSRT.Profiles[name] = type(exportTable.data) == "table" and CopyTable(exportTable.data) or {}
    self:LoadProfile(name)
    return name
end

function NSI:LoadMyProfile()
    local ProfileKey = self:GetProfileKey()
    local ProfileToLoad = "default"
    self:AddMissingDefaults()
    if NSRT.ProfileKeys and NSRT.ProfileKeys[ProfileKey] then
        ProfileToLoad = NSRT.ProfileKeys[ProfileKey]
    elseif NSRT.MainProfile then
        ProfileToLoad = NSRT.MainProfile
    elseif NSRT.CurrentProfile then
        ProfileToLoad = NSRT.CurrentProfile
    end
    if NSRT.Profiles and NSRT.Profiles[ProfileToLoad] then
        self:LoadProfile(ProfileToLoad, true, true)
    else
        self:CreateProfile("default", true)
    end
end