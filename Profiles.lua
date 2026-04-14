local _, NSI = ...

local defaults = {
    -- Saved data tables (user-populated, empty by default)
    NickNames = {},
    Reminders = {},
    PersonalReminders = {},
    InviteList = {},
    AssignmentSettings = {},
    CooldownList = {},
    CustomBossAlerts = {},
    PASounds = {
        UseDefaultPASounds = false,
        UseDefaultMPlusPASounds = false,
    },
    PhaseTimings = {},

    -- Active reminder persistence
    ActiveReminder = nil,
    ActivePersonalReminder = nil,
    StoredSharedReminder = nil,

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
        MyNickName = nil,
        ShareNickNames = 4,
        AcceptNickNames = 4,
        NickNamesSyncAccept = 2,
        NickNamesSyncSend = 3,
        GlobalNickNames = false,
        TTS = true,
        TTSVolume = 50,
        TTSVoice = 1,
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
        -- Encounter alert display settings (Lura / encounter 3183)
        LuraDisplayAnchor = "TOPLEFT",
        LuraDisplayRelativePoint = "TOPLEFT",
        LuraDisplayOffsetX = 300,
        LuraDisplayOffsetY = -300,
        LuraDisplayColor = {0.5, 0.5, 0.5, 0.9},
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
        [3183] = {enabled = false, P3Side = "OFF", RunesDisplay = false},
        [3306] = {enabled = false},
    },
}

function NSI:AddMissingDefaults()
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