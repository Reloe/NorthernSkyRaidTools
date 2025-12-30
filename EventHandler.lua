local _, NSI = ... -- Internal namespace
local f = CreateFrame("Frame")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
f:RegisterEvent("MINIMAP_PING")
f:RegisterEvent("START_PLAYER_COUNTDOWN")
f:RegisterEvent("ENCOUNTER_WARNING")
f:RegisterEvent("RAID_BOSS_WHISPER")
f:RegisterEvent("GROUP_ROSTER_UPDATE")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:EventHandler(e, true, false, ...)
end)

function NSI:EventHandler(e, wowevent, internal, ...) -- internal checks whether the event comes from addon comms. We don't want to allow blizzard events to be fired manually
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "NorthernSkyRaidTools" then
            if not NSRT then NSRT = {} end
            if not NSRT.NSUI then NSRT.NSUI = {scale = 1} end
            -- if not NSRT.NSUI.main_frame then NSRT.NSUI.main_frame = {} end
            -- if not NSRT.NSUI.external_frame then NSRT.NSUI.external_frame = {} end
            if not NSRT.NickNames then NSRT.NickNames = {} end
            if not NSRT.Settings then NSRT.Settings = {} end
            NSRT.Reminders = NSRT.Reminders or {}
            NSRT.ActiveReminder = NSRT.ActiveReminder or nil
            self.Reminder = ""
            self:SetReminder(NSRT.ActiveReminder) -- loading active reminder from last session
            NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
            NSRT.AssignmentSettings = NSRT.AssignmentSettings or {}
            NSRT.ReminderSettings = NSRT.ReminderSettings or {}
            if NSRT.ReminderSettings.enabled == nil then NSRT.ReminderSettings.enabled = true end -- enable for note from raidleader
            NSRT.ReminderSettings.Sticky = NSRT.ReminderSettings.Sticky or 5
            NSRT.ReminderSettings.Bars = NSRT.ReminderSettings.Bars or false
            if NSRT.ReminderSettings.SpellTTS == nil then NSRT.ReminderSettings.SpellTTS = true end
            if NSRT.ReminderSettings.TextTTS == nil then NSRT.ReminderSettings.TextTTS = true end
            NSRT.ReminderSettings.SpellDuration = NSRT.ReminderSettings.SpellDuration or 10
            NSRT.ReminderSettings.TextDuration = NSRT.ReminderSettings.TextDuration or 10
            NSRT.ReminderSettings.SpellCountdown = NSRT.ReminderSettings.SpellCountdown or 0
            NSRT.ReminderSettings.TextCountdown = NSRT.ReminderSettings.TextCountdown or 0
            NSRT.ReminderSettings.SpellName = NSRT.ReminderSettings.SpellName or true
            NSRT.ReminderSettings.SpellTTSTimer = NSRT.ReminderSettings.SpellTTSTimer or 5
            NSRT.ReminderSettings.TextTTSTimer = NSRT.ReminderSettings.TextTTSTimer or 5
            NSRT.ReminderSettings.HideTimerText = NSRT.ReminderSettings.HideTimerText or false
            if (not NSRT.ReminderSettings.IconSettings) or (not NSRT.ReminderSettings.IconSettings.GrowDirection) then 
                NSRT.ReminderSettings.IconSettings = {GrowDirection = "Down", Anchor = "CENTER", relativeTo = "CENTER", xOffset = -400, yOffset = 400, xTextOffset = 0, yTextOffset = 0, xTimer = 0, yTimer = 0, Font = "PT Sans Narrow Bold", FontSize = 30, TimerFontSize = 40, Width = 80, Height = 80}
            end
            if (not NSRT.ReminderSettings.BarSettings) or (not NSRT.ReminderSettings.BarSettings.GrowDirection) then
                NSRT.ReminderSettings.BarSettings = {GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", Width = 240, Height = 30, xIcon = 0, yIcon = 0, colors = {1, 0, 0, 1}, Texture = "Atrocity", xOffset = 400, yOffset = 0, xTextOffset = 2, yTextOffset = 0, xTimer = -2, yTimer = 0, Font = "PT Sans Narrow Bold", FontSize = 22, TimerFontSize = 22}
            end
            if (not NSRT.ReminderSettings.TextSettings) or (not NSRT.ReminderSettings.TextSettings.GrowDirection) then
                NSRT.ReminderSettings.TextSettings =  {colors = {1, 1, 1, 1}, GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", xOffset = -200, yOffset = 200, Font = "PT Sans Narrow Bold", FontSize = 50}
            end
            if not NSRT.ReminderSettings.TextSettings.colors then NSRT.ReminderSettings.TextSettings.colors = {1, 1, 1, 1} end
            if (not NSRT.ReminderSettings.UnitIconSettings) or (not NSRT.ReminderSettings.UnitIconSettings.Position) then
                NSRT.ReminderSettings.UnitIconSettings = {Position = "CENTER", xOffset = 0, yOffset = 0, Width = 25, Height = 25}
            end
            if not NSRT.ReminderSettings.GlowSettings then 
                NSRT.ReminderSettings.GlowSettings = {colors = {0, 1, 0, 1}, Lines = 10, Frequency = 0.2, Length = 10, Thickness = 4, xOffset = 0, yOffset = 0} 
            end
            NSRT.Settings["MyNickName"] = NSRT.Settings["MyNickName"] or nil
            NSRT.Settings["GlobalNickNames"] = NSRT.Settings["GlobalNickNames"] or false
            NSRT.Settings["Blizzard"] = NSRT.Settings["Blizzard"] or false
            NSRT.Settings["MRT"] = NSRT.Settings["MRT"] or false
            NSRT.Settings["Cell"] = NSRT.Settings["Cell"] or false
            NSRT.Settings["Grid2"] = NSRT.Settings["Grid2"] or false
            NSRT.Settings["ElvUI"] = NSRT.Settings["ElvUI"] or false
            NSRT.Settings["SuF"] = NSRT.Settings["SuF"] or false
            NSRT.Settings["Translit"] = NSRT.Settings["Translit"] or false
            NSRT.Settings["Unhalted"] = NSRT.Settings["Unhalted"] or false
            NSRT.Settings["ShareNickNames"] = NSRT.Settings["ShareNickNames"] or 4 -- none default
            NSRT.Settings["AcceptNickNames"] = NSRT.Settings["AcceptNickNames"] or 4 -- none default
            NSRT.Settings["NickNamesSyncAccept"] = NSRT.Settings["NickNamesSyncAccept"] or 2 -- guild default
            NSRT.Settings["NickNamesSyncSend"] = NSRT.Settings["NickNamesSyncSend"] or 3 -- guild default
            NSRT.Settings["MRTNoteComparison"] = NSRT.Settings["MRTNoteComparison"] or false
            if NSRT.Settings["TTS"] == nil then NSRT.Settings["TTS"] = true end
            NSRT.Settings["TTSVolume"] = NSRT.Settings["TTSVolume"] or 50
            NSRT.Settings["TTSVoice"] = NSRT.Settings["TTSVoice"] or 1
            NSRT.Settings["Minimap"] = NSRT.Settings["Minimap"] or {hide = false}
            NSRT.Settings["VersionCheckRemoveResponse"] = NSRT.Settings["VersionCheckRemoveResponse"] or false
            NSRT.Settings["Debug"] = NSRT.Settings["Debug"] or false
            NSRT.Settings["DebugLogs"] = NSRT.Settings["DebugLogs"] or false
            NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or {}
            NSRT.Settings["CheckCooldowns"] = NSRT.Settings["CheckCooldowns"] or false
            NSRT.Settings["CooldownThreshold"] = NSRT.Settings["CooldownThreshold"] or 20
            NSRT.Settings["UnreadyOnCooldown"] = NSRT.Settings["UnreadyOnCooldown"] or false
            NSRT.Settings.MissingRaidBuffs = NSRT.Settings.MissingRaidBuffs or true
            if not NSRT.ReadyCheckSettings then
                NSRT.ReadyCheckSettings = {MissingItemCheck = false, EnchantCheck = false, GemCheck = false, ItemLevelCheck = false, CraftedCheck = false, RepairCheck = false, RaidBuffCheck = false, SoulstoneCheck = false, GatewayShardCheck = false}
            end
            NSRT.CooldownList = NSRT.CooldownList or {}
            NSRT.NSUI.AutoComplete = NSRT.NSUI.AutoComplete or {}
            NSRT.NSUI.AutoComplete["Addon"] = NSRT.NSUI.AutoComplete["Addon"] or {}

            self.BlizzardNickNamesHook = false
            self.MRTNickNamesHook = false
            self.ReminderTimer = {}
            self.PlayedSound = {}
            self.StartedCountdown = {}
            self:InitNickNames()            
            self:CreateMoveFrames()
        end
    elseif e == "PLAYER_LOGIN" and wowevent then
        self.NSUI:Init()
        self:InitLDB()
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
        
    elseif e == "ENCOUNTER_START" and wowevent and self:DifficultyCheck(14) then -- allow sending fake encounter_start if in debug mode, only send spec info in mythic, heroic and normal raids
        NSUI.generic_display:Hide()
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
        self.RaidFrames = self.RaidFrames or {}
        self.AllGlows = self.AllGlows or {}
        self.PlayedSound = {}
        self.StartedCountdown = {}
        if self.AddAssignments[self.EncounterID] then
            self.AddAssignments[self.EncounterID](self)
            self.EncounterAlertStart[self.EncounterID](self)
        end
        self:StartReminders(self.Phase)
    elseif e == "ENCOUNTER_END" and wowevent and self:DifficultyCheck(14) then
        local encID, encounterName = ...
        self:HideAllReminders()
        self.EncounterID = nil
        self.TestingReminder = false
        self.ReminderTimer = {}
        self.AllGlows = {}          
        self.ProcessedReminder = nil
        if self.EncounterAlertStop[encID] then
            self.EncounterAlertStop[encID](self)
        end
        C_Timer.After(1, function()
            if self:Restricted() then return end
            if self.SyncNickNamesStore then
                self:EventHandler("NSI_NICKNAMES_SYNC", false, true, self.SyncNickNamesStore.unit, self.SyncNickNamesStore.nicknametable, self.SyncNickNamesStore.channel)
                self.SyncNickNamesStore = nil
            end
        end) 
    elseif e == "START_PLAYER_COUNTDOWN" and wowevent then -- do basically the same thing as ready check in case one of them is skipped
        if self:Restricted() or not self:DifficultyCheck(14) then return end
        if self.LastBroadcast and self.LastBroadcast > GetTime() - 30 then return end -- only do this if there was no recent ready check basically
        self:StoreFrames(true)
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        self:Broadcast("NSI_SPEC", "RAID", specid)
        if UnitIsGroupLeader("player") then
            self:Broadcast("NSI_REM_SHARE", "RAID", self.Reminder, NSRT.AssignmentSettings)
            self.Assignments = NSRT.AssignmentSettings
        end
    elseif e == "READY_CHECK" and wowevent then
        if self:Restricted() then return end
        self.LastBroadcast = GetTime()        
        if UnitIsGroupLeader("player") then
            -- always doing this, even outside of raid to allow outside raidleading to work. The difficulty check will instead happen client-side
            self:Broadcast("NSI_REM_SHARE", "RAID", self.Reminder, NSRT.AssignmentSettings)
            self.Assignments = NSRT.AssignmentSettings
        end
            if self:DifficultyCheck(14) then
                self:StoreFrames(true)
                C_Timer.After(1, function()
                    self:EventHandler("NSI_READY_CHECK", false, true)
                end)     
            end
        if NSRT.Settings["CheckCooldowns"] and self:DifficultyCheck(15) and UnitInRaid("player") then -- only heroic& mythic because in normal you just wanna go fast and don't care about someone having a cd
            self:CheckCooldowns()
        end
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
        -- broadcast spec info
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        self:Broadcast("NSI_SPEC", "RAID", specid)
    elseif e == "NSI_REM_SHARE"  and internal then
        local unit, remindertable, assigntable = ...
        if UnitIsGroupLeader(unit) and self:DifficultyCheck(14) then
            if NSRT.ReminderSettings.enabled then
                self.Reminder = remindertable
                self:ProcessReminder()
            end
            self.Assignments = assigntable
        end
    elseif e == "NSI_READY_CHECK" and internal then
        if self:Restricted() then return end
        local text = ""
        if NSRT.ReadyCheckSettings.RaidBuffCheck then
            local buff = self:BuffCheck()
            if buff and buff ~= "" then text = buff end
        end     
        if NSRT.ReadyCheckSettings.SoulstoneCheck then
            local Soulstone = self:SoulstoneCheck()
            if Soulstone and Soulstone ~= "" then
                if text == "" then
                    text = Soulstone
                else
                    text = text.."\n"..Soulstone
                end
            end
        end   
        if UnitLevel("player") >= 90 then
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
        if self:Restricted() then return end
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
        if self:Restricted() then return end
        local specid = GetSpecializationInfo(GetSpecialization())
        self:Broadcast("NSI_SPEC", "RAID", specid)      
    elseif e == "GROUP_ROSTER_UPDATE" and wowevent then
        if self:Restricted() then return end
        self:UpdateRaidBuffFrame()
        if not self:DifficultyCheck(14) then return end
        self:StoreFrames(false)
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