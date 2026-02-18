local _, NSI = ... -- Internal namespace
local f = NSI.NSRTFrame
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
f:RegisterEvent("START_PLAYER_COUNTDOWN")
f:RegisterEvent("ENCOUNTER_WARNING")
f:RegisterEvent("RAID_BOSS_WHISPER")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:EventHandler(e, true, false, ...)
end)

function NSI:EventHandler(e, wowevent, internal, ...) -- internal checks whether the event comes from addon comms. We don't want to allow blizzard events to be fired manually
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "NorthernSkyRaidTools" then
            if not NSRT then NSRT = {} end
            if not NSRT.NSUI then NSRT.NSUI = {scale = 1} end
            if not NSRT.NSUI.timeline_window then NSRT.NSUI.timeline_window = { scale = 1 } end
            -- if not NSRT.NSUI.main_frame then NSRT.NSUI.main_frame = {} end
            -- if not NSRT.NSUI.external_frame then NSRT.NSUI.external_frame = {} end
            if not NSRT.NickNames then NSRT.NickNames = {} end
            if not NSRT.Settings then NSRT.Settings = {} end
            NSRT.Reminders = NSRT.Reminders or {}
            NSRT.PersonalReminders = NSRT.PersonalReminders or {}
            NSRT.InviteList = NSRT.InviteList or {}
            NSRT.ActiveReminder = NSRT.ActiveReminder or nil
            NSRT.ActivePersonalReminder = NSRT.ActivePersonalReminder or nil
            if not NSRT.Settings.GlobalFont then NSRT.Settings.GlobalFont = "Expressway" end
            self.Reminder = ""
            self.PersonalReminder = ""
            self.DisplayedReminder = ""
            self.DisplayedPersonalReminder = ""
            self.DisplayedExtraReminder = ""
            NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
            NSRT.AssignmentSettings = NSRT.AssignmentSettings or {}
            NSRT.ReminderSettings = NSRT.ReminderSettings or {}
            if NSRT.ReminderSettings.enabled == nil then NSRT.ReminderSettings.enabled = true end -- enable for note from raidleader
            NSRT.ReminderSettings.Sticky = NSRT.ReminderSettings.Sticky or 5
            if NSRT.ReminderSettings.SpellTTS == nil then NSRT.ReminderSettings.SpellTTS = true end
            if NSRT.ReminderSettings.TextTTS == nil then NSRT.ReminderSettings.TextTTS = true end
            NSRT.ReminderSettings.SpellDuration = NSRT.ReminderSettings.SpellDuration or 10
            NSRT.ReminderSettings.TextDuration = NSRT.ReminderSettings.TextDuration or 10
            NSRT.ReminderSettings.SpellCountdown = NSRT.ReminderSettings.SpellCountdown or 0
            NSRT.ReminderSettings.TextCountdown = NSRT.ReminderSettings.TextCountdown or 0
            if NSRT.ReminderSettings.SpellName == nil then NSRT.ReminderSettings.SpellName = true end -- Keep SpellName enable on first installation, then load from config
            NSRT.ReminderSettings.SpellTTSTimer = NSRT.ReminderSettings.SpellTTSTimer or 5
            NSRT.ReminderSettings.TextTTSTimer = NSRT.ReminderSettings.TextTTSTimer or 5
            if NSRT.ReminderSettings.AutoShare == nil then NSRT.ReminderSettings.AutoShare = true end
            if not NSRT.ReminderSettings.PersonalReminderFrame then
                NSRT.ReminderSettings.PersonalReminderFrame = {enabled = true, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 500, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if not NSRT.ReminderSettings.ReminderFrame then
                NSRT.ReminderSettings.ReminderFrame = {enabled = false, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 0, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if not NSRT.ReminderSettings.ExtraReminderFrame then
                NSRT.ReminderSettings.ExtraReminderFrame = {enabled = false, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 0, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if (not NSRT.ReminderSettings.IconSettings) or (not NSRT.ReminderSettings.IconSettings.GrowDirection) then
                NSRT.ReminderSettings.IconSettings = {GrowDirection = "Down", Anchor = "CENTER", relativeTo = "CENTER", colors = {1, 1, 1, 1}, xOffset = -500, yOffset = 400, xTextOffset = 0, yTextOffset = 0, xTimer = 0, yTimer = 0, Font = "Expressway", FontSize = 30, TimerFontSize = 40, Width = 80, Height = 80, Spacing = -1}
            end
            if not NSRT.ReminderSettings.IconSettings.colors then NSRT.ReminderSettings.IconSettings.colors = {1, 1, 1, 1} end
            if not NSRT.ReminderSettings.IconSettings.Glow then NSRT.ReminderSettings.IconSettings.Glow = 0 end
            if (not NSRT.ReminderSettings.BarSettings) or (not NSRT.ReminderSettings.BarSettings.GrowDirection) then
                NSRT.ReminderSettings.BarSettings = {GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", Width = 300, Height = 40, xIcon = 0, yIcon = 0, colors = {1, 0, 0, 1}, Texture = "Atrocity", xOffset = -400, yOffset = 0, xTextOffset = 2, yTextOffset = 0, xTimer = -2, yTimer = 0, Font = "Expressway", FontSize = 22, TimerFontSize = 22, Spacing = -1}
            end
            if (not NSRT.ReminderSettings.TextSettings) or (not NSRT.ReminderSettings.TextSettings.GrowDirection) then
                NSRT.ReminderSettings.TextSettings =  {colors = {1, 1, 1, 1}, GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", xOffset = 0, yOffset = 200, Font = "Expressway", FontSize = 50, Spacing = 1}
            end
            if not NSRT.ReminderSettings.TextSettings.colors then NSRT.ReminderSettings.TextSettings.colors = {1, 1, 1, 1} end
            if (not NSRT.ReminderSettings.UnitIconSettings) or (not NSRT.ReminderSettings.UnitIconSettings.Position) then
                NSRT.ReminderSettings.UnitIconSettings = {Position = "CENTER", xOffset = 0, yOffset = 0, Width = 25, Height = 25}
            end
            if not NSRT.ReminderSettings.GlowSettings then
                NSRT.ReminderSettings.GlowSettings = {colors = {0, 1, 0, 1}, Lines = 10, Frequency = 0.2, Length = 10, Thickness = 4, xOffset = 0, yOffset = 0}
            end
            if not NSRT.PASettings then
                NSRT.PASettings = {Spacing = -1, Limit = 5, GrowDirection = "RIGHT", enabled = false, Width = 100, Height = 100, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -450, yOffset = -100}
            end
            NSRT.PASettings.Spacing = NSRT.PASettings.Spacing or -1
            NSRT.PASettings.Limit = NSRT.PASettings.Limit or 5
            if not NSRT.PATankSettings then
                NSRT.PATankSettings = {Spacing = -1, Limit = 5, MultiTankGrowDirection = "UP", GrowDirection = "LEFT", enabled = false, Width = 100, Height = 100, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -549, yOffset = -199}
            end
            NSRT.PATankSettings.Spacing = NSRT.PATankSettings.Spacing or -1
            NSRT.PATankSettings.Limit = NSRT.PATankSettings.Limit or 5
            if not NSRT.PARaidSettings then
                NSRT.PARaidSettings = {PerRow = 3, RowGrowDirection = "UP", Spacing = -1, Limit = 5, GrowDirection = "RIGHT", enabled = false, Width = 25, Height = 25, Anchor = "BOTTOMLEFT", relativeTo = "BOTTOMLEFT", xOffset = 0, yOffset = 0}
            end
            if not NSRT.PARaidSettings.PerRow then
                NSRT.PARaidSettings.PerRow = 3
                NSRT.PARaidSettings.RowGrowDirection = "UP"
                NSRT.PASettings.PerRow = 10
                NSRT.PASettings.RowGrowDirection = "UP"
            end
            if not NSRT.PATextSettings then
                NSRT.PATextSettings = {Scale = 2.5, xOffset = 0, yOffset = -200, enabled = false, Anchor = "TOP", relativeTo = "TOP"}
            end
            NSRT.PARaidSettings.Spacing = NSRT.PARaidSettings.Spacing or -1
            NSRT.PARaidSettings.Limit = NSRT.PARaidSettings.Limit or 5
            if not NSRT.PASounds then NSRT.PASounds = {} end
            NSRT.Settings["MyNickName"] = NSRT.Settings["MyNickName"] or nil
            NSRT.Settings["ShareNickNames"] = NSRT.Settings["ShareNickNames"] or 4 -- none default
            NSRT.Settings["AcceptNickNames"] = NSRT.Settings["AcceptNickNames"] or 4 -- none default
            NSRT.Settings["NickNamesSyncAccept"] = NSRT.Settings["NickNamesSyncAccept"] or 2 -- guild default
            NSRT.Settings["NickNamesSyncSend"] = NSRT.Settings["NickNamesSyncSend"] or 3 -- guild default
            if NSRT.Settings["TTS"] == nil then NSRT.Settings["TTS"] = true end
            NSRT.Settings["TTSVolume"] = NSRT.Settings["TTSVolume"] or 50
            NSRT.Settings["TTSVoice"] = NSRT.Settings["TTSVoice"] or 1
            NSRT.Settings["Minimap"] = NSRT.Settings["Minimap"] or {hide = false}
            NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or {}
            NSRT.Settings["CooldownThreshold"] = NSRT.Settings["CooldownThreshold"] or 20
            if NSRT.Settings["MissingRaidBuffs"] == nil then NSRT.Settings["MissingRaidBuffs"] = true end
            if not NSRT.ReadyCheckSettings then NSRT.ReadyCheckSettings = {} end
            NSRT.CooldownList = NSRT.CooldownList or {}
            NSRT.NSUI.AutoComplete = NSRT.NSUI.AutoComplete or {}
            NSRT.NSUI.AutoComplete["Addon"] = NSRT.NSUI.AutoComplete["Addon"] or {}

            if NSRT.ReminderSettings.ReminderFrame.enabled == nil then -- convert to different format
                NSRT.ReminderSettings.ReminderFrame.enabled = NSRT.ReminderSettings.ShowReminderFrame
                NSRT.ReminderSettings.PersonalReminderFrame.enabled = NSRT.ReminderSettings.ShowPersonalReminderFrame
                NSRT.ReminderSettings.ExtraReminderFrame.enabled = NSRT.ReminderSettings.ShowExtraReminderFrame
            end
            if NSRT.UseDefaultPASounds then NSRT.PASounds.UseDefaultPASounds = true end -- migrate old setting
            if not NSRT.Settings.GenericDisplay then
                NSRT.Settings.GenericDisplay = {Anchor = "CENTER", relativeTo = "CENTER", xOffset = -200, yOffset = 400}
            end
            if not NSRT.QoL then
                NSRT.QoL = {
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
                }
            end

            self.BlizzardNickNamesHook = false
            self.MRTNickNamesHook = false
            self.ReminderTimer = {}
            self.PlayedSound = {}
            self.StartedCountdown = {}
            self.GlowStarted = {}
            self:CreateMoveFrames()
            self:InitNickNames()
        end
    elseif e == "PLAYER_LOGIN" and wowevent then
        self.NSUI:Init()
        self:InitLDB()
        self:InitQoL()
        self.NSRTFrame:SetAllPoints(UIParent)
        local MyFrame = self.LGF.GetUnitFrame("player") -- need to call this once to init the library properly I think
        if NSRT.PASettings.enabled then self:InitPA() end
        self:InitTextPA()
        if NSRT.PARaidSettings.enabled then C_Timer.After(5, function() self:InitRaidPA(not UnitInRaid("player"), true) end) end
        if NSRT.PASounds.UseDefaultPASounds then self:ApplyDefaultPASounds() end
        if NSRT.PASounds.UseDefaultMPlusPASounds then self:ApplyDefaultPASounds(false, true) end
        for spellID, info in pairs(NSRT.PASounds) do
            if type(info) == "table" and info.sound then -- prevents user settings
                self:AddPASound(spellID, info.sound)
            end
        end
        -- only running this on login if enabled. It will only run with false when actively disabling the setting. Doing it this way should prevent conflicts with other addons.
        if NSRT.PASettings.DebuffTypeBorder then C_UnitAuras.TriggerPrivateAuraShowDispelType(true) end
        self:SetReminder(NSRT.ActiveReminder, false, true) -- loading active reminder from last session
        self:SetReminder(NSRT.ActivePersonalReminder, true, true) -- loading active personal reminder from last session
        self:FireCallback("NSRT_REMINDER_CHANGED", self.PersonalReminder, self.Reminder)
        if self.Reminder == "" then -- if user doesn't have their own active Reminder, load shared one from last session. This should cover disconnects/relogs
            self.Reminder = NSRT.StoredSharedReminder or ""
        end
        self:UpdateReminderFrame(true)
        if NSRT.Settings["Debug"] then
            print("|cFF00FFFFNSRT|r Debug mode is currently enabled. Please disable it with '/ns debug' unless you are specifically testing something.")
        end
        if NSRT.HasLoggedIntoMidnight == nil then -- delete old macros on first login after update
            NSRT.HasLoggedIntoMidnight = true
            local todelete = {}
            for i=1, 120 do
                local macroname = C_Macro.GetMacroName(i)
                if not macroname then break end
                if macroname == "NS PA Macro" or macroname == "NS Ext Macro" or macroname == "NS Innervate" then
                    table.insert(todelete, i)
                end
            end
            if #todelete > 0 then
                print("deleting", #todelete, "old NSRT macros as they are no longer beinng used.")
                for i=#todelete, 1, -1 do
                    DeleteMacro(todelete[i])
                end
            end
        end
        if self:Restricted() then return end
        if NSRT.Settings["MyNickName"] then self:SendNickName("Any") end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname
        if NSRT.Settings["GlobalNickNames"] then -- add own nickname if not already in database (for new characters)
            local name, realm = UnitName("player")
            if not realm then
                realm = GetNormalizedRealmName()
            end
            if (not NSRT.NickNames[name.."-"..realm]) or (NSRT.Settings["MyNickName"] ~= NSRT.NickNames[name.."-"..realm]) then
                self:NewNickName("player", NSRT.Settings["MyNickName"], name, realm)
            end
        end
    elseif e == "PLAYER_ENTERING_WORLD" then
        if not self:DifficultyCheck(14) then self:HideAllReminders(true) end
        local IsLogin, IsReload = ...
        if NSRT.PARaidSettings.enabled and not (IsLogin or IsReload) then
            C_Timer.After(5, function() self:InitRaidPA(not UnitInRaid("player"), true) end)
        end
    elseif e == "ENCOUNTER_START" and wowevent then -- allow sending fake encounter_start if in debug mode, only send spec info in mythic, heroic and normal raids
        local diff = select(3, GetInstanceInfo()) or 0
        if  NSRT.PATankSettings.enabled and diff <= 17 and diff >= 14 and UnitGroupRolesAssigned("player") == "TANK" then -- enabled in lfr, normal, heroic, mythic
            self:InitTankPA()
        end
        if diff < 14 and diff > 17 and diff ~= 220 then return end -- everything else is enabled in lfr, normal, heroic, mythic and story mode because people like to test in there.
        self.NSRTFrame.generic_display:Hide()
        if NSRT.PARaidSettings.enabled then self:InitRaidPA(false) end
        if not self.ProcessedReminder then -- should only happen if there was never a ready check, good to have this fallback though in case the user connected/zoned in after a ready check or they never did a ready check
            self:ProcessReminder()
        end
        self.TestingReminder = false
        self.IsInPreview = false
        for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
            self:ToggleMoveFrames(self[v], false)
        end
        self.EncounterID = ...
        self.Phase = 1
        self.PhaseSwapTime = GetTime()
        self.ReminderText = self.ReminderText or {}
        self.ReminderIcon = self.ReminderIcon or {}
        self.ReminderBar = self.ReminderBar or {}
        self.ReminderTimer = self.ReminderTimer or {}
        self.AllGlows = self.AllGlows or {}
        self.PlayedSound = {}
        self.StartedCountdown = {}
        self.GlowStarted = {}
        self.Timelines = {}
        self.DefaultAlertID = 10000
        if self.AddAssignments[self.EncounterID] then self.AddAssignments[self.EncounterID](self) end
        if self.EncounterAlertStart[self.EncounterID] then self.EncounterAlertStart[self.EncounterID](self) end
        self:StartReminders(self.Phase)
    elseif e == "ENCOUNTER_END" and wowevent and self:DifficultyCheck(14) then
        local encID, encounterName = ...
        if NSRT.PATankSettings.enabled and UnitGroupRolesAssigned("player") == "TANK" then
            self:RemoveTankPA()
        end
        self:HideAllReminders(true)
        C_Timer.After(1, function()
            if self:Restricted() then return end
            if self.SyncNickNamesStore then
                self:EventHandler("NSI_NICKNAMES_SYNC", false, true, self.SyncNickNamesStore.unit, self.SyncNickNamesStore.nicknametable, self.SyncNickNamesStore.channel)
                self.SyncNickNamesStore = nil
            end
        end)
    elseif e == "START_PLAYER_COUNTDOWN" and wowevent then -- do basically the same thing as ready check in case one of them is skipped
        if self.LastBroadcast and self.LastBroadcast > GetTime() - 30 then return end -- only do this if there was no recent ready check basically
        self.LastBroadcast = GetTime()
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        self:Broadcast("NSI_SPEC", "RAID", specid)
        if UnitIsGroupLeader("player") and UnitInRaid("player") then
            local tosend = false
            if NSRT.ReminderSettings.AutoShare then
                tosend = self.Reminder
            end
            self:Broadcast("NSI_REM_SHARE", "RAID", tosend, NSRT.AssignmentSettings, false)
            self.Assignments = NSRT.AssignmentSettings
        end
    elseif e == "READY_CHECK" and wowevent then
        if self:DifficultyCheck(14) or diff == 23 then
            C_Timer.After(1, function()
                self:EventHandler("NSI_READY_CHECK", false, true)
            end)
        end
        if UnitIsGroupLeader("player") and UnitInRaid("player") then
            -- always doing this, even outside of raid to allow outside raidleading to work. The difficulty check will instead happen client-side
            local tosend = false
            if NSRT.ReminderSettings.AutoShare then
                tosend = self.Reminder
            end
            self:Broadcast("NSI_REM_SHARE", "RAID", tosend, NSRT.AssignmentSettings, false)
            self.Assignments = NSRT.AssignmentSettings
        end
        -- broadcast spec info
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        self:Broadcast("NSI_SPEC", "RAID", specid)
        if C_ChatInfo.InChatMessagingLockdown() then return end
        self.LastBroadcast = GetTime()
        local diff= select(3, GetInstanceInfo()) or 0
        self.specs = {}
        self.GUIDS = {}
        self.HasNSRT = {}
        for u in self:IterateGroupMembers() do
            if UnitIsVisible(u) then
                self.HasNSRT[u] = false
                self.specs[u] = false
                local G = UnitGUID(u)
                self.GUIDS[u] = issecretvalue(G) and "" or G
            end
        end
        if self:Restricted() then return end
        if NSRT.Settings["CheckCooldowns"] and self:DifficultyCheck(15) and UnitInRaid("player") then -- only heroic& mythic because in normal you just wanna go fast and don't care about someone having a cd
            self:CheckCooldowns()
        end
    elseif e == "NSI_REM_SHARE"  and internal then
        local unit, reminderstring, assigntable, skipcheck = ...
        if (UnitIsGroupLeader(unit) or (UnitIsGroupAssistant(unit) and skipcheck)) and (self:DifficultyCheck(14) or skipcheck) then -- skipcheck allows manually sent reminders to bypass difficulty checks
            if (NSRT.ReminderSettings.enabled or NSRT.ReminderSettings.UseTimelineReminders) and reminderstring and type(reminderstring) == "string" and reminderstring ~= "" then
                NSRT.StoredSharedReminder = self.Reminder -- store in SV to reload on next login
                self.Reminder = reminderstring
                self:ProcessReminder()
                self:UpdateReminderFrame(true)
                if skipcheck then self:FlashNoteBackgrounds() end -- only show animation if reminder was manually shared
                self:FireCallback("NSRT_REMINDER_CHANGED", self.PersonalReminder, self.Reminder)
            end
            if assigntable then self.Assignments = assigntable end
        end
    elseif e == "NSI_READY_CHECK" and internal then
        local text = ""
        if UnitLevel("player") < 80 then return end
        if NSRT.ReadyCheckSettings.RaidBuffCheck and not self:Restricted() then
            local buff = self:BuffCheck()
            if buff and buff ~= "" then text = buff end
        end
        if NSRT.ReadyCheckSettings.SoulstoneCheck and not self:Restricted() then
            local Soulstone = self:SoulstoneCheck()
            if Soulstone and Soulstone ~= "" then
                if text == "" then
                    text = Soulstone
                else
                    text = text.."\n"..Soulstone
                end
            end
        end
        if UnitLevel("player") >= 80 then
            local Gear = self:GearCheck()
            if Gear and Gear ~= "" then
                if text == "" then
                    text = Gear
                else
                    text = text.."\n"..Gear
                end
            end
        end
        if text ~= "" then
            self:DisplayText(text)
        end
    elseif e == "GROUP_FORMED" and wowevent then
        if self:Restricted() then return end
        if NSRT.Settings["MyNickName"] then self:SendNickName("Any", true) end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname
    elseif e == "NSI_VERSION_CHECK" and internal then
        if self:Restricted() then return end
        local unit, ver, ignoreCheck = ...
        self:VersionResponse({name = UnitName(unit), version = ver, ignoreCheck = ignoreCheck})
    elseif e == "NSI_VERSION_REQUEST" and internal then
        local unit, type, name = ...
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't send to yourself
        if UnitExists(unit) then
            local u, ver, _, ignoreCheck = self:GetVersionNumber(type, name, unit)
            self:Broadcast("NSI_VERSION_CHECK", "WHISPER", unit, ver, ignoreCheck)
        end
    elseif e == "NSI_NICKNAMES_COMMS" and internal then
        if self:Restricted() then return end
        local unit, nickname, name, realm, requestback, channel = ...
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't add new nickname if it's yourself because already adding it to the database when you edit it
        if requestback and (UnitInRaid(unit) or UnitInParty(unit)) then self:SendNickName(channel, false) end -- send nickname back to the person who requested it
        self:NewNickName(unit, nickname, name, realm, channel)

    elseif e == "PLAYER_REGEN_ENABLED" and wowevent then
        C_Timer.After(1, function()
            if self:Restricted() then return end
            if self.SyncNickNamesStore then
                self:EventHandler("NSI_NICKNAMES_SYNC", false, true, self.SyncNickNamesStore.unit, self.SyncNickNamesStore.nicknametable, self.SyncNickNamesStore.channel)
                self.SyncNickNamesStore = nil
            end
            if self.WAString and self.WAString.unit and self.WAString.string then
                self:EventHandler("NSI_WA_SYNC", false, true, self.WAString.unit, self.WAString.string)
                self.WAString = nil
            end
        end)
    elseif e == "NSI_NICKNAMES_SYNC" and internal then
        local unit, nicknametable, channel = ...
        local setting = NSRT.Settings["NickNamesSyncAccept"]
        if (setting == 3 or (setting == 2 and channel == "GUILD") or (setting == 1 and channel == "RAID") and (not C_ChallengeMode.IsChallengeModeActive())) then
            if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't accept sync requests from yourself
            if self:Restricted() or UnitAffectingCombat("player") then
                self.SyncNickNamesStore = {unit = unit, nicknametable = nicknametable, channel = channel}
            else
                self:NickNamesSyncPopup(unit, nicknametable)
            end
        end
    elseif e == "NSI_WA_SYNC" and internal then
        local unit, str = ...
        local setting = NSRT.Settings["WeakAurasImportAccept"]
        if setting == 3 then return end
        if UnitExists(unit) and not UnitIsUnit("player", unit) then
            if setting == 2 or (GetGuildInfo(unit) == GetGuildInfo("player")) then -- only accept this from same guild to prevent abuse
                if self:Restricted() or UnitAffectingCombat("player") then
                    self.WAString = {unit = unit, string = str}
                else
                    self:WAImportPopup(unit, str)
                end
            end
        end

    elseif e == "NSI_SPEC" and internal then -- renamed for Midnight
        local unit, spec = ...
        self.specs = self.specs or {}
        local G = UnitGUID(unit)
        G = issecretvalue(G) and "" or G
        self.specs[unit] = tonumber(spec)
        self.HasNSRT = self.HasNSRT or {}
        self.HasNSRT[unit] = true
        if G ~= "" then
            self.GUIDS = self.GUIDS or {}
            self.GUIDS[unit] = G
        end
    elseif e == "NSI_SPEC_REQUEST" then
        local specid = GetSpecializationInfo(GetSpecialization())
        self:Broadcast("NSI_SPEC", "RAID", specid)
    elseif e == "GROUP_ROSTER_UPDATE" and wowevent then
        self:ArrangeGroups()
        if NSRT.PARaidSettings.enabled then
            C_Timer.After(5, function() self:InitRaidPA(not UnitInRaid("player"), true) end)
        end

        self:UpdateRaidBuffFrame()
        if self:Restricted() then return end

        if self.InviteInProgress then
            if not UnitInRaid("player") then
                C_PartyInfo.ConvertToRaid()
                C_Timer.After(1, function() -- send invites again if player is now in a raid
                    if UnitInRaid("player") then
                        self:InviteList(self.CurrentInviteList)
                        self.InviteInProgress = nil
                    end
                end)
            end
        end

        if not self:DifficultyCheck(14) then return end
    elseif (e == "ENCOUNTER_TIMELINE_EVENT_ADDED" or e == "ENCOUNTER_TIMELINE_EVENT_REMOVED") and wowevent then
        if not self:DifficultyCheck(14) then return end
        local info = ...
        if self:Restricted() and self.EncounterID and self.DetectPhaseChange[self.EncounterID] then self.DetectPhaseChange[self.EncounterID](self, e, info) end
    elseif e == "ENCOUNTER_WARNING" and wowevent then
        local info = ...
        if not self:DifficultyCheck(14) then return end
        if self.ShowWarningAlert[self.EncounterID] then self.ShowWarningAlert[self.EncounterID](self, self.EncounterID, self.Phase, self.PhaseSwapTime, info) end
    elseif e == "RAID_BOSS_WHISPER" and wowevent then
        local text, name, dur = ...
        if not self:DifficultyCheck(14) then return end
        if self.ShowBossWhisperAlert[self.EncounterID] then self.ShowBossWhisperAlert[self.EncounterID](self, self.EncounterID, self.Phase, self.PhaseSwapTime, text, name, dur) end
    end
end