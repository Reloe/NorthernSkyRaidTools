local _, NSI = ... -- Internal namespace
local f = NSI.NSRTFrame
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED")
f:RegisterEvent("START_PLAYER_COUNTDOWN")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:EventHandler(e, true, false, ...)
end)

function NSI:EventHandler(e, wowevent, internal, ...) -- internal checks whether the event comes from addon comms. We don't want to allow blizzard events to be fired manually
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "NorthernSkyRaidTools" then
            self.Reminder = ""
            self.PersonalReminder = ""
            self.DisplayedReminder = ""
            self.DisplayedPersonalReminder = ""
            self.DisplayedExtraReminder = ""
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
        self:LoadMyProfile()
        self.NSUI:Init()
        self:InitLDB()
        self:InitQoL()
        self.NSRTFrame:SetAllPoints(UIParent)
        local MyFrame = self.LGF.GetUnitFrame("player") -- need to call this once to init the library properly I think
        self:InitPrivateAuras()
        if NSRT.PASounds.UseDefaultPASounds then self:ApplyDefaultPASounds() end
        if NSRT.PASounds.UseDefaultMPlusPASounds then self:ApplyDefaultPASounds(false, true) end
        for spellID, info in pairs(NSRT.PASounds) do
            if type(info) == "table" and info.sound then -- prevents user settings
                self:AddPASound(spellID, info.sound)
            end
        end
        -- only running this on login if enabled. It will only run with false when actively disabling the setting. Doing it this way should prevent conflicts with other addons.
        if NSRT.PASettings.DebuffTypeBorder then C_UnitAuras.TriggerPrivateAuraShowDispelType(true) end
        if NSRT.StoredSharedReminder then
            self.Reminder = NSRT.StoredSharedReminder
        else
            self:SetReminder(NSRT.ActiveReminder, false, true) -- loading active reminder from last session
        end
        self:SetReminder(NSRT.StoredPersonalReminder, true, true) -- loading active personal reminder from last session
        self:ProcessReminder()
        self:UpdateReminderFrame(true)
        if NSRT.Settings["Debug"] then
            print("|cFF00FFFFNSRT|r Debug mode is currently enabled. Please disable it with '/ns debug' unless you are specifically testing something.")
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
        if NSRT.Alerts.ReloeReminders then
            for key, encID in ipairs(NSI.CurrentEncounterIDs) do
                if self.InitializeAlerts[encID] then
                    self.InitializeAlerts[encID](self)
                end
            end
        end
    elseif e == "PLAYER_ENTERING_WORLD" then
        local IsLogin, IsReload = ...
        C_Timer.After(0.01, function()
            local diff = select(3, GetInstanceInfo()) or 0
            local ForceHide = diff > 17 or diff < 14
            if ForceHide then self:HideAllReminders(true) end
            self:UpdateNoteFrame("ReminderFrame", NSRT.ReminderSettings.ReminderFrame, "skip")
            self:UpdateNoteFrame("PersonalReminderFrame", NSRT.ReminderSettings.PersonalReminderFrame, "skip")
            self:UpdateNoteFrame("ExtraReminderFrame", NSRT.ReminderSettings.ExtraReminderFrame, "skip")
        end)
    elseif e == "ENCOUNTER_START" and wowevent then -- allow sending fake encounter_start if in debug mode, only send spec info in mythic, heroic and normal raids
        local diff = select(3, GetInstanceInfo()) or 0
        if (diff < 14 or diff > 17) and diff ~= 220 and not NSRT.Settings["Debug"] then return end -- everything else is enabled in lfr, normal, heroic, mythic and story mode because people like to test in there.
        self.NSRTFrame.generic_display:Hide()
        self.EncounterID = ...
        self:LoadPersReminder(self.EncounterID)
        if not self.ProcessedReminder then -- should only happen if there was never a ready check, good to have this fallback though in case the user connected/zoned in after a ready check or they never did a ready check
            self:ProcessReminder()
        end
        self.TestingReminder = false
        self.IsInPreview = false
        for _, v in ipairs({"IconMover", "BarMover", "TextMover", "CircleMover"}) do
            self:ToggleMoveFrames(self[v], false)
        end
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
        self.RemovedTimelines = {}
        self.CustomEvents = self.CustomEvents or {}
        self.DefaultAlertID = 10000
        self.TLAlerts = {}
        if self.AddAssignments[self.EncounterID] then self.AddAssignments[self.EncounterID](self) end
        if self.EncounterAlertStart[self.EncounterID] then self.EncounterAlertStart[self.EncounterID](self) end
        self:LoadCustomBossAlerts(self.EncounterID)
        self:StartReminders(self.Phase)
        if NSRT.ReminderSettings.NoteCountdown then
            local frames = {"ReminderFrame", "PersonalReminderFrame"}
            for i, name in ipairs(frames) do
                if self[name] then
                    if self[name].UpdateTimer then
                        self[name].UpdateTimer:Cancel()
                        self[name].UpdateTimer = nil
                    end
                    if self[name]:IsShown() then
                        self[name].UpdateTimer = C_Timer.NewTicker(1, function()
                            self:CountdownNoteFrame(self[name])
                        end)
                    end
                end
            end
        end
        self:FireCallback("NSRT_ALERT_ADDED", self.TLAlerts)
    elseif e == "ENCOUNTER_END" and wowevent then
        local encID, encounterName, _, _, kill = ...
        local diff = select(3, GetInstanceInfo()) or 0
        self.CustomEvents = {}
        if (diff < 14 or diff > 17) and diff ~= 220 then return end
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
        if NSRT.ReminderSettings.NoteCountdown then
            self:UpdateReminderFrame(true) -- need to recalculate reminders if the user has countdown enabled
            local frames = {"ReminderFrame", "PersonalReminderFrame"}
            for i, name in ipairs(frames) do
                if self[name] and self[name].UpdateTimer then
                    self[name].UpdateTimer:Cancel()
                    self[name].UpdateTimer = nil
                end
            end
        end
        if kill then
            local NoteName = NSRT.AutoLoadNote and NSRT.AutoLoadNote[encID]
            if NoteName and NSRT.Reminders[NoteName] then
                C_Timer.After(2, function()
                    if self:Restricted() then return end
                    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
                        self:Broadcast("NSI_REM_SHARE", "RAID", NSRT.Reminders[NoteName], nil, true)
                    end
                end)
            end
        end
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
        self:InitPrivateAuras()
    elseif e == "READY_CHECK" and wowevent then
        self.ProcessDone = false
        local diff= select(3, GetInstanceInfo()) or 0
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
            if (NSRT.ReminderSettings.enabled or self:IsUsingTLReminders()) and reminderstring and type(reminderstring) == "string" and reminderstring ~= "" then
                self.Reminder = reminderstring
                NSRT.StoredSharedReminder = reminderstring
                self.ReminderReceivedTime = GetTime()
                self:FireCallback("NSRT_REMINDER_CHANGED", self.PersonalReminder, self.Reminder)
            end
            self:ProcessReminder()
            self:UpdateReminderFrame(true)
            self.ProcessDone = true
            if skipcheck then self:FlashNoteBackgrounds() end -- only show animation if reminder was manually shared
            if assigntable then self.Assignments = assigntable end
        end
    elseif e == "NSI_READY_CHECK" and internal then
        if not self.ProcessDone then -- fallback do this here if no addon comms were received because the setting is disabled
            self:ProcessReminder()
            self:UpdateReminderFrame(true)
        end
        local diff = select(3, GetInstanceInfo()) or 0
        self:InitPrivateAuras()
        local text = ""
        if UnitLevel("player") < 90 then return end
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
        if NSRT.ReadyCheckSettings.SourceOfMagicCheck and not self:Restricted() then
            local SourceOfMagic = self:SourceOfMagicCheck()
            if SourceOfMagic and SourceOfMagic ~= "" then
                if text == "" then
                    text = SourceOfMagic
                else
                    text = text.."\n"..SourceOfMagic
                end
            end
        end
        local Gear = self:GearCheck()
        if Gear and Gear ~= "" then
            if text == "" then
                text = Gear
            else
                text = text.."\n"..Gear
            end
        end
        if text ~= "" then
            self:DisplayText(text)
        end
    elseif e == "GROUP_FORMED" and wowevent then
        if self:Restricted() then return end
        if NSRT.Settings["MyNickName"] then self:SendNickName("Any", true) end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname
        if NSRT.NSUI and NSRT.NSUI.reminders_frame then NSUI.reminders_frame.UpdateButtonAccess() end
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
        if self.GroupUpdateTimer then self.GroupUpdateTimer:Cancel() end
        self.GroupUpdateTimer = C_Timer.After(2, function()
            self.GroupUpdateTimer = nil
            self:InitPrivateAuras()
            self:UpdateRaidBuffFrame()
        end)
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
    elseif e == "ENCOUNTER_TIMELINE_EVENT_ADDED" and wowevent then
        if not self:DifficultyCheck(14) then return end
        local info = ...
        if info.source ~= Enum.EncounterTimelineEventSource.Encounter then
            self.CustomEvents = self.CustomEvents or {}
            self.CustomEvents[info.id] = true
            return
        end
        if self:Restricted() and self.EncounterID and self.DetectPhaseChange[self.EncounterID] then self.DetectPhaseChange[self.EncounterID](self, e, info) end
    elseif e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" and wowevent then
        if not self:DifficultyCheck(14) then return end
        local eventID = ...
        if self.CustomEvents and self.CustomEvents[eventID] then
            return
        end
        if self:Restricted() and self.EncounterID and self.DetectPhaseChange[self.EncounterID] then self.DetectPhaseChange[self.EncounterID](self, e, info) end
    elseif e == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" and wowevent then
        local eventID = ...
        if not self:DifficultyCheck(14) then return end
        if self.CustomEvents and self.CustomEvents[eventID] then
            return
        end
        local state = C_EncounterTimeline.GetEventState(eventID)
        if state == Enum.EncounterTimelineEventState.Canceled then
            self:EventHandler("ENCOUNTER_TIMELINE_EVENT_REMOVED", true, false, eventID)
        end
    elseif e == "QoL_Comms" and internal then
        self:QoLEvents(e, ...)
    elseif e == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        if self:Restricted() and self.EncounterID and self.DetectPhaseChange[self.EncounterID] then self.DetectPhaseChange[self.EncounterID](self, e) end
    elseif e == "PLAYER_LOGOUT" and wowevent then
        self:SaveProfile()
    end
end
