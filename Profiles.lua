local _, NSI = ...

local function CopyAuraTrackingSetting(source, target, key)
    if source[key] ~= nil then
        target[key] = source[key]
    end
end

local function CopyPrivateAuraSettingsToAuraTracking(source, target)
    if not source or not target then return end
    for _, key in ipairs({
        "Spacing",
        "Limit",
        "GrowDirection",
        "enabled",
        "Width",
        "Height",
        "Anchor",
        "relativeTo",
        "xOffset",
        "yOffset",
        "HideTooltip",
        "HideDurationText",
    }) do
        CopyAuraTrackingSetting(source, target, key)
    end
    if source.HideBorder ~= nil then
        target.ShowDispelBorder = not source.HideBorder
    end

    if source.StackScale then
        local fontSize = math.max(6, math.floor((source.StackScale * 16) + 0.5))
        target.DurationFontSize = fontSize
        target.StackFontSize = fontSize
    end
end

function NSI:ConvertPrivateAuraSettingsToAuraTracking()
    if not self:IsMidnightS2() or NSRT.AuraTrackingSettingsConverted then return end
    NSRT.AuraTrackingSettings = NSRT.AuraTrackingSettings or {}
    NSRT.AuraTrackingSettings.Player = NSRT.AuraTrackingSettings.Player or {}
    NSRT.AuraTrackingSettings.Tank = NSRT.AuraTrackingSettings.Tank or {}

    CopyPrivateAuraSettingsToAuraTracking(NSRT.PASettings, NSRT.AuraTrackingSettings.Player)
    CopyPrivateAuraSettingsToAuraTracking(NSRT.PATankSettings, NSRT.AuraTrackingSettings.Tank)
    NSRT.AuraTrackingSettingsConverted = true
end

function NSI:RunProfileMigrations()
    local profileVersion = tonumber(NSRT.ProfileVersion) or 0
    if profileVersion < 1 then
        if not self:IsMidnightS2() then return end
        NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
        for _, encID in ipairs(self.Season2EncounterIDs) do
            NSRT.EncounterAlerts[encID] = nil
            if self.InitializeAlerts and self.InitializeAlerts[encID] then
                self.InitializeAlerts[encID](self)
            end
        end
        self:FireCallback("NSRT_ALERT_FULL_UPDATE")
        if NSRT.PaceComparison and NSRT.PaceComparison.Bosses then
            for _, encID in ipairs(self.Season2EncounterIDs) do
                NSRT.PaceComparison.Bosses[encID] = nil
            end
            self:ApplyDefaultPaceComparisonData()
        end
        NSRT.ProfileVersion = 1
    end
end


function NSI:AddMissingDefaults(skipProfileMigrations)
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
        StoredPersonalReminder = {},

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
            Language = "Auto",
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

        Alerts = {
            ReloeReminders = false,
            Groups = {},
        },

        -- Reminder Settings
        ReminderSettings = {
            enabled = true,
            PersNote = true,
            SpellTTS = true,
            TextTTS = true,
            TTSOverSoundfile = false,
            SpellDuration = 10,
            TextDuration = 10,
            SpellCountdown = 0,
            TextCountdown = 0,
            SpellDisplayType = "Icon",
            SpellName = true,
            SpellTTSTimer = 5,
            TextTTSTimer = 5,
            AutoShare = false,
            OnlyReceiveGuild = false,
            OverwriteSharedNoteOnImport = false,
            OverwritePersonalNoteOnImport = false,
            NoteCountdown = false,
            ClearOnKill = true,
            PersonalReminderFrame = {
                enabled = true,
                Width = 500,
                Height = 600,
                Anchor = "TOPLEFT",
                relativeTo = "TOPLEFT",
                xOffset = 500,
                yOffset = 0,
                Font = "Expressway",
                FontFlags = "OUTLINE",
                FontSize = 14,
                BGcolor = { 0, 0, 0, 0.3 },
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
                FontFlags = "OUTLINE",
                FontSize = 14,
                BGcolor = { 0, 0, 0, 0.3 },
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
                FontFlags = "OUTLINE",
                FontSize = 14,
                BGcolor = { 0, 0, 0, 0.3 },
            },
            IconSettings = {
                GrowDirection = "Down",
                Anchor = "CENTER",
                relativeTo = "CENTER",
                Sticky = 5,
                textColors = { 1, 1, 1, 1 },
                borderColors = { 0, 0, 0, 1 },
                xOffset = -500,
                yOffset = 400,
                xTextOffset = 0,
                yTextOffset = 0,
                xTimer = 0,
                yTimer = 0,
                Font = "Expressway",
                FontFlags = "OUTLINE",
                FontSize = 30,
                TimerFontSize = 40,
                Width = 80,
                Height = 80,
                Spacing = -1,
                Glow = 0,
                Zoom = 0,
                HideTimerText = false,
                HideSwipe = false,
                Decimals = 3,
            },
            BarSettings = {
                GrowDirection = "Up",
                Anchor = "CENTER",
                relativeTo = "CENTER",
                Sticky = 5,
                Width = 300,
                Height = 40,
                xIcon = 0,
                yIcon = 0,
                textColors = { 1, 1, 1, 1 },
                barColors = { 1, 0, 0, 1 },
                backgroundColors = { 0, 0, 0, 0.8 },
                borderColors = { 0, 0, 0, 1 },
                Texture = "Atrocity",
                xOffset = -400,
                yOffset = 0,
                xTextOffset = 2,
                yTextOffset = 0,
                xTimer = -2,
                yTimer = 0,
                Font = "Expressway",
                FontFlags = "OUTLINE",
                FontSize = 22,
                TimerFontSize = 22,
                Spacing = -1,
                HideTimerText = false,
                Decimals = 3,
            },
            TextSettings = {
                textColors = { 1, 1, 1, 1 },
                GrowDirection = "Up",
                Anchor = "CENTER",
                relativeTo = "CENTER",
                Sticky = 0,
                xOffset = 0,
                yOffset = 200,
                Font = "Expressway",
                FontFlags = "OUTLINE",
                FontSize = 50,
                Spacing = 1,
                HideTimerText = false,
                Decimals = 3,
            },
            CircleSettings = {
                GrowDirection = "Up",
                Anchor = "CENTER",
                relativeTo = "CENTER",
                Sticky = 0,
                xOffset = 0,
                yOffset = -200,
                textColors = { 1, 1, 1, 1 },
                ringColors = { 1, 1, 1, 1 },
                Size = 80,
                Texture = [[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_8px.png]],
                Font = "Expressway",
                FontFlags = "OUTLINE",
                FontSize = 18,
                TextPosition = "Top",
                xTextOffset = 0,
                yTextOffset = 4,
                Spacing = 5,
                showBackground = false,
                HideTimerText = false,
                Decimals = 3,
            },
            UnitIconSettings = {
                Position = "CENTER",
                xOffset = 0,
                yOffset = 0,
                Width = 25,
                Height = 25,
            },
            GlowSettings = {
                colors = { 0, 1, 0, 1 },
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
            DebuffTypeBorder = false,
            HideBorder = false,
            StackScale = 2,
            HideTooltip = false,
            HideDurationText = false,
        },
        PATankSettings = {
            Spacing = -1,
            Limit = 5,
            GrowDirection = "LEFT",
            enabled = false,
            Width = 100,
            Height = 100,
            Anchor = "CENTER",
            relativeTo = "CENTER",
            xOffset = -549,
            yOffset = -199,
            HideBorder = false,
            StackScale = 2,
            HideTooltip = false,
            HideDurationText = false,
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
        AuraTrackingSettings = {
            Player = self:CreateAuraTrackingSettingsDefaults({
                Name = "Player Debuffs",
                builtin = "Player",
                ShowWhitelistedPlayerBuffs = true,
            }),
            Tank = self:CreateAuraTrackingSettingsDefaults({
                Name = "Co-Tank Debuffs",
                builtin = "Tank",
                GrowDirection = "LEFT",
                xOffset = -549,
                yOffset = -199,
                NameEnabled = true,
            }),
            External = self:CreateAuraTrackingSettingsDefaults({
                Name = "External & Immunity",
                builtin = "External",
                Width = 120,
                Height = 120,
                GrowDirection = "UP",
                xOffset = 319,
                yOffset = 152,
                DurationFontSize = 50,
                StackFontSize = 50,
                HideStackText = true,
                HideTooltip = true,
                ShowDispelBorder = false,
                IncludeImmunities = true,
                NameEnabled = true,
                NamePosition = "LEFT",
                NameXOffset = 0,
                NameYOffset = 0,
            }),
            Custom = {},
            Groups = {
                ["Built-in"] = { collapsed = false },
            },
        },
        AuraTrackingSettingsConverted = false,
        AuraTrackingSelected = "Player",
        AuraTrackingStyleCopySource = "Player",
        PaceComparison = {
            SelectedBoss = 0,
            NewThreshold = {
                phase = 1,
                time = 0,
                unit = "boss1",
                expected = 100,
            },
            Display = {
                Anchor = "CENTER",
                relativeTo = "CENTER",
                xOffset = -400,
                yOffset = 400,
                Font = "Expressway",
                FontSize = 28,
                FontFlags = "OUTLINE",
                LineSpacing = 4,
                RefreshInterval = 1,
                AheadColor = {0, 1, 0, 1},
                CloseBehindColor = {1, 1, 0, 1},
                BehindColor = {1, 0.5, 0, 1},
                FarBehindColor = {1, 0, 0, 1},
            },
            Bosses = {},
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
            BlisteringScalesCheck = false,
            SymbioticRelationshipCheck = false,
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
                FontFlags = "OUTLINE",
            },
        },

        -- Encounter Alerts
        EncounterAlerts = {
            [3176] = {},
            [3177] = {},
            [3178] = {},
            [3179] = {},
            [3180] = {},
            [3181] = {},
            [3182] = {},
            [3183] = {},
            [3306] = {},
        },

        -- Interrupt Display
        InterruptSettings = {
            ShowBar = false,
            Anchor = "CENTER",
            relativeTo = "CENTER",
            xOffset = -600,
            yOffset = 400,
            Width = 100,
            Height = 100,
            NumberxOffset = 0,
            NumberyOffset = 0,
            NumberAnchor = "CENTER",
            NumberRelativeTo = "CENTER",
            NamexOffset = 0,
            NameyOffset = 10,
            NameAnchor = "BOTTOM",
            NameRelativeTo = "TOP",
            NumberFont = "Expressway",
            NumberFontFlags = "OUTLINE",
            NumberFontSize = 60,
            NameFont = "Expressway",
            NameFontFlags = "OUTLINE",
            NameFontSize = 30,
            InterruptSound = "|cFF4BAAC8Interrupt|r",
            InterruptNowColor = {0, 1, 0, 1},
            InterruptNowTextColor = {1, 0, 0, 1},
            InterruptNextColor = {1, 1, 0, 1},
            InterruptNextTextColor = {1, 0, 0, 1},
            InterruptDefaultColor = {1, 0, 0, 1},
            InterruptDefaultTextColor = {1, 1, 1, 1},
        },
        Profiles = {},
        ProfileKeys = {},
        CurrentProfile = "default",
        MainProfile = "default",
        ProfileVersion = 0,

        AutoLoadNote = {},
        HasNewAlertStructure = true,
    }
    if not NSRT then
        NSRT = {}
    end
    if not NSRT.HasNewAlertStructure then
        NSRT.HasNewAlertStructure = true
        NSRT.EncounterAlerts = {}
    end
    for k, v in pairs(NSRT.EncounterAlerts or {}) do
        if v.enabled ~= nil then
            v.enabled = nil
        end
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
    self:ConvertPrivateAuraSettingsToAuraTracking()
    self:ApplyDefaultPaceComparisonData()
    self:RunProfileMigrations()
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
    ["Profiles"]         = true,
    ["ProfileKeys"]      = true,
    ["CurrentProfile"]   = true,
    ["MainProfile"]      = true,
    ["EncounterAlerts"]  = true,
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
    if ProfileKey then
        NSRT.ProfileKeys[ProfileKey] = name
    end
    NSRT.CurrentProfile = name
    if not init and ProfileKey then self:SetReminder(NSRT.StoredPersonalReminder[ProfileKey], true) end
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
    local ProfileKey = self:GetProfileKey()
    if ProfileKey then
        NSRT.ProfileKeys[ProfileKey] = name
    end
    NSRT.CurrentProfile = name
    if not init and ProfileKey then self:SetReminder(NSRT.StoredPersonalReminder[ProfileKey], true) end
    self:AddMissingDefaults()
    self:SaveProfile()
    end
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

function NSAPI:ImportProfileString(importString, name) -- name is optional
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")
    if not importString or importString == "" then return nil end
    local decoded = LibDeflate:DecodeForPrint(importString)
    if not decoded then return nil end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil end
    local success, exportTable = LibSerialize:Deserialize(decompressed)
    if not success or type(exportTable) ~= "table" then return nil end
    local name = name or exportTable.profileName or "Imported"
    local function EnsureUniqueName(name)
        if NSRT.Profiles[name] then
            name = name .. " 2"
            return EnsureUniqueName(name)
        end
        return name
    end
    name = EnsureUniqueName(name)
    NSRT.Profiles[name] = type(exportTable.data) == "table" and CopyTable(exportTable.data) or {}
    NSI:LoadProfile(name)
    return name
end

function NSI:ExportAlertsString(encID, diffID)
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")
    local source = encID and NSRT.EncounterAlerts[encID] or NSRT.EncounterAlerts
    local encounterAlerts
    if diffID then
        encounterAlerts = {}
        if encID then
            local diffTable = source and source[diffID]
            if diffTable then
                encounterAlerts[encID] = { [diffID] = diffTable }
            end
        else
            for eid, encTable in pairs(source or {}) do
                if type(encTable) == "table" and encTable[diffID] then
                    encounterAlerts[eid] = { [diffID] = encTable[diffID] }
                end
            end
        end
    else
        encounterAlerts = source or {}
    end
    local exportTable = {
        version         = 1,
        type            = "alerts",
        encID           = encID,
        diffID          = diffID,
        encounterAlerts = encounterAlerts,
    }
    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    return LibDeflate:EncodeForPrint(compressed)
end

function NSI:ExportSingleAlertString(alertType, encID, diffID, alertKey, data)
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")
    local exportTable = {
        version   = 1,
        type      = "single_alert",
        alertType = alertType,
        encID     = encID,
        diffID    = diffID,
        alertKey  = alertKey,
        data      = data,
    }
    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    return LibDeflate:EncodeForPrint(compressed)
end

function NSI:ExportGroupString(encID, groupName, diffID)
    if not encID or not groupName then return nil end
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate   = LibStub("LibDeflate")
    local encounterAlerts = {}
    local encTable = encID and NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
    if not encTable then return nil end
    for did, diffTable in pairs(encTable) do
        if (not diffID) or did == diffID then
            for key, alert in pairs(diffTable or {}) do
                if alert.group and alert.group == groupName then
                    encounterAlerts[encID] = encounterAlerts[encID] or {}
                    encounterAlerts[encID][did] = encounterAlerts[encID][did] or {}
                    encounterAlerts[encID][did][key] = alert
                end
            end
        end
    end
    local gk = tostring(encID) .. "|" .. groupName
    local exportTable = {
        version         = 1,
        type            = "alert_group",
        groupName       = groupName,
        groupEncID      = encID,
        diffID          = diffID,
        groupMeta       = (NSRT.Alerts and NSRT.Alerts.Groups and NSRT.Alerts.Groups[gk]) or {},
        encounterAlerts = encounterAlerts,
    }
    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    return LibDeflate:EncodeForPrint(compressed)
end

function NSAPI:ImportAlertsString(importString)
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")
    if not importString or importString == "" then return nil end
    local decoded = LibDeflate:DecodeForPrint(importString)
    if not decoded then return nil end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil end
    local success, t = LibSerialize:Deserialize(decompressed)
    if not success or type(t) ~= "table" then return nil end

    if t.type == "alerts" then
        local count = 0
        NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
        if t.encID then
            if t.encounterAlerts then
                NSRT.EncounterAlerts[t.encID] = NSRT.EncounterAlerts[t.encID] or {}
                for diffID, diffData in pairs(t.encounterAlerts[t.encID] or t.encounterAlerts or {}) do
                    if (not t.diffID) or diffID == t.diffID then
                        NSRT.EncounterAlerts[t.encID][diffID] = NSRT.EncounterAlerts[t.encID][diffID] or {}
                        local destDiff = NSRT.EncounterAlerts[t.encID][diffID]
                        for k, a in pairs(destDiff) do
                            if type(a) == "table" and a.ReloeReminder then destDiff[k] = nil end
                        end
                        for alertKey, alert in pairs(diffData) do
                            if type(alert) == "table" then
                                if alert.ReloeReminder then
                                    destDiff[alertKey] = alert
                                else
                                    alert.ReloeReminder = nil
                                    local newKey = NSI:UniqueAlertID(destDiff, false)
                                    destDiff[newKey] = alert
                                end
                                count = count + 1
                            end
                        end
                    end
                end
            end
            NSI:FireCallback("NSRT_ALERT_ENCOUNTER_UPDATE", t.encID)
            return count
        end
        if t.encounterAlerts then
            local overwritecount = 0
            for encID, encData in pairs(t.encounterAlerts or {}) do
                NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
                for diffID, diffData in pairs(encData) do
                    if (not t.diffID) or diffID == t.diffID then
                        NSRT.EncounterAlerts[encID][diffID] = NSRT.EncounterAlerts[encID][diffID] or {}
                        local destDiff = NSRT.EncounterAlerts[encID][diffID]
                        for k, a in pairs(destDiff) do
                            if type(a) == "table" and a.ReloeReminder then destDiff[k] = nil end
                        end
                        for alertKey, alert in pairs(diffData) do
                            if type(alert) == "table" then
                                if alert.ReloeReminder then
                                    destDiff[alertKey] = alert
                                else
                                    alert.ReloeReminder = nil
                                    local newKey = NSI:UniqueAlertID(destDiff, false)
                                    destDiff[newKey] = alert
                                end
                                count = count + 1
                            end
                        end
                    end
                end
            end
            NSI:FireCallback("NSRT_ALERT_FULL_UPDATE")
            return count, overwritecount
        end
        NSI:FireCallback("NSRT_ALERT_FULL_UPDATE")
        return count
    elseif t.type == "single_alert" then
        NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
        if t.encID and t.diffID then
            NSRT.EncounterAlerts[t.encID] = NSRT.EncounterAlerts[t.encID] or {}
            NSRT.EncounterAlerts[t.encID][t.diffID] = NSRT.EncounterAlerts[t.encID][t.diffID] or {}
            local diffTable = NSRT.EncounterAlerts[t.encID][t.diffID]
            local importKey
            if t.alertKey then
                -- Keep the original key for both Reloe and user alerts so re-imports update in place
                importKey = t.alertKey
            else
                importKey = NSI:UniqueAlertID(diffTable, false)
            end
            if t.data then t.data.ReloeReminder = t.alertType == "encounter" and t.data.ReloeReminder or nil end
            diffTable[importKey] = t.data
            NSI:FireCallback("NSRT_ALERT_CHANGED", t.encID, t.diffID, importKey)
            return 1
        end
    elseif t.type == "alert_group" then
        local count = 0
        NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
        NSRT.Alerts = NSRT.Alerts or {}
        NSRT.Alerts.Groups = NSRT.Alerts.Groups or {}
        if t.groupName then
            NSRT.Alerts.Groups[t.groupName] = t.groupMeta or { collapsed = false }
        end
        local encID = t.groupEncID
        local encData = encID and t.encounterAlerts and t.encounterAlerts[encID]
        if encID and encData then
            NSRT.EncounterAlerts[encID] = NSRT.EncounterAlerts[encID] or {}
            for diffID, diffData in pairs(encData) do
                if (not t.diffID) or diffID == t.diffID then
                    NSRT.EncounterAlerts[encID][diffID] = NSRT.EncounterAlerts[encID][diffID] or {}
                    local destDiff = NSRT.EncounterAlerts[encID][diffID]
                    for alertKey, alert in pairs(diffData) do
                        if type(alert) == "table" then
                            if alert.ReloeReminder then
                                destDiff[alertKey] = alert
                            else
                                alert.ReloeReminder = nil
                                local importKey = alertKey or NSI:UniqueAlertID(destDiff, false)
                                destDiff[importKey] = alert
                            end
                            count = count + 1
                        end
                    end
                end
            end
            NSI:FireCallback("NSRT_ALERT_ENCOUNTER_UPDATE", encID)
        end
        return count
    end
    return nil
end

function NSI:LoadMyProfile()
    local ProfileKey = self:GetProfileKey()
    local ProfileToLoad = "default"
    NSRT = NSRT or {}
    if ProfileKey and NSRT.ProfileKeys and NSRT.ProfileKeys[ProfileKey] then
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
