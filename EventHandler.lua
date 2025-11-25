local _, NSI = ... -- Internal namespace
local f = CreateFrame("Frame")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
if not NSI:IsMidnight() then
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("CHALLENGE_MODE_START")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
end
if NSI:IsMidnight() then
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
    f:RegisterEvent("MINIMAP_PING")
end

f:SetScript("OnEvent", function(self, e, ...)
    NSI:EventHandler(e, true, false, ...)
end)

function NSI:EventHandler(e, wowevent, internal, ...) -- internal checks whether the event comes from addon comms. We don't want to allow blizzard events to be fired manually
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "NorthernSkyRaidTools" then
            if not NSRT then NSRT = {} end
            if not NSRT.NSUI then NSRT.NSUI = {scale = 1} end
            if not NSRT.NSUI.externals_anchor then NSRT.NSUI.externals_anchor = {} end
            -- if not NSRT.NSUI.main_frame then NSRT.NSUI.main_frame = {} end
            -- if not NSRT.NSUI.external_frame then NSRT.NSUI.external_frame = {} end
            if not NSRT.NickNames then NSRT.NickNames = {} end
            if not NSRT.Settings then NSRT.Settings = {} end
            NSRT.Reminders = NSRT.Reminders or {}
            NSRT.ReminderSettings = NSRT.ReminderSettings or {}
            NSRT.ReminderSettings.Sticky = NSRT.ReminderSettings.Sticky or 5
            NSRT.ReminderSettings.Bars = NSRT.ReminderSettings.Bars or false
            if NSRT.ReminderSettings.SpellTTS == nil then NSRT.ReminderSettings.SpellTTS = true end
            if NSRT.ReminderSettings.TextTTS == nil then NSRT.ReminderSettings.TextTTS = true end
            NSRT.ReminderSettings.SpellDuration = NSRT.ReminderSettings.SpellDuration or 10
            NSRT.ReminderSettings.TextDuration = NSRT.ReminderSettings.TextDuration or 10
            NSRT.ReminderSettings.SpellCountdown = NSRT.ReminderSettings.SpellCountdown or 0
            NSRT.ReminderSettings.TextCountdown = NSRT.ReminderSettings.TextCountdown or 0
            NSRT.ReminderSettings.SpellName = NSRT.ReminderSettings.SpellName or false
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
                NSRT.ReminderSettings.TextSettings =  {GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", xOffset = -200, yOffset = 200, Font = "PT Sans Narrow Bold", FontSize = 50}
            end
            if (not NSRT.ReminderSettings.UnitIconSettings) or (not NSRT.ReminderSettings.UnitIconSettings.Position) then
                NSRT.ReminderSettings.UnitIconSettings = {Position = "CENTER", xOffset = 0, yOffset = 0, Width = 25, Height = 25}
            end
            NSRT.Settings["MyNickName"] = NSRT.Settings["MyNickName"] or nil
            NSRT.Settings["GlobalNickNames"] = NSRT.Settings["GlobalNickNames"] or false
            NSRT.Settings["Blizzard"] = NSRT.Settings["Blizzard"] or false
            NSRT.Settings["WA"] = NSRT.Settings["WA"] or false
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
            NSRT.Settings["WeakAurasImportAccept"] = NSRT.Settings["WeakAurasImportAccept"] or 1 -- guild default
            NSRT.Settings["PAExtraAction"] = NSRT.Settings["PAExtraAction"] or false
            NSRT.Settings["LIQUID_MACRO"] = NSRT.Settings["LIQUID_MACRO"] or false
            NSRT.Settings["PASelfPing"] = NSRT.Settings["PASelfPing"] or false
            NSRT.Settings["ExternalSelfPing"] = NSRT.Settings["ExternalSelfPing"] or false
            NSRT.Settings["MRTNoteComparison"] = NSRT.Settings["MRTNoteComparison"] or false
            if NSRT.Settings["TTS"] == nil then NSRT.Settings["TTS"] = true end
            NSRT.Settings["TTSVolume"] = NSRT.Settings["TTSVolume"] or 50
            NSRT.Settings["TTSVoice"] = NSRT.Settings["TTSVoice"] or 2
            NSRT.Settings["Minimap"] = NSRT.Settings["Minimap"] or {hide = false}
            NSRT.Settings["AutoUpdateWA"] = NSRT.Settings["AutoUpdateWA"] or false
            NSRT.Settings["AutoUpdateRaidWA"] = NSRT.Settings["AutoUpdateRaidWA"] or false
            NSRT.Settings["UpdateWhitelist"] = NSRT.Settings["UpdateWhitelist"] or {}
            NSRT.Settings["VersionCheckRemoveResponse"] = NSRT.Settings["VersionCheckRemoveResponse"] or false
            NSRT.Settings["Debug"] = NSRT.Settings["Debug"] or false
            NSRT.Settings["DebugLogs"] = NSRT.Settings["DebugLogs"] or false
            NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or {}
            NSRT.Settings["CheckCooldowns"] = NSRT.Settings["CheckCooldowns"] or false
            NSRT.Settings["CooldownThreshold"] = NSRT.Settings["CooldownThreshold"] or 20
            NSRT.Settings["UnreadyOnCooldown"] = NSRT.Settings["UnreadyOnCooldown"] or false
            NSRT.Settings["RebuffCheck"] = NSRT.Settings["RebuffCheck"] or false
            NSRT.CooldownList = NSRT.CooldownList or {}
            NSRT.NSUI.AutoComplete = NSRT.NSUI.AutoComplete or {}
            NSRT.NSUI.AutoComplete["WA"] = NSRT.NSUI.AutoComplete["WA"] or {}
            NSRT.NSUI.AutoComplete["Addon"] = NSRT.NSUI.AutoComplete["Addon"] or {}

            self.BlizzardNickNamesHook = false
            self.MRTNickNamesHook = false
            self.Reminder = ""
            self.ReminderTimer = {}
            self.PlayedSound = {}
            self.StartedCountdown = {}
            self:InitNickNames()
        end
    elseif e == "PLAYER_ENTERING_WORLD" and wowevent then
        C_AddOns.LoadAddOn("WeakAuras")
        if self:IsMidnight() or not WeakAuras then return end
        self:AutoImport()
        self.Externals:Init(C_ChallengeMode.IsChallengeModeActive())
    elseif e == "PLAYER_LOGIN" and wowevent then
        local pafound = false
        local extfound = false
        local innervatefound = false
        local macrocount = 0    
        self.NSUI:Init()
        self:InitLDB()
        if NSRT.Settings["Debug"] then
            print("|cFF00FFFFNSRT|r Debug mode is currently enabled. Please disable it with '/ns debug' unless you are specifically testing something.")
        end
        if WeakAuras and WeakAuras.GetData("Northern Sky Externals") then
            print("Please uninstall the |cFF00FFFFNorthern Sky Externals Weakaura|r to prevent conflicts with the Northern Sky Raid Tools Addon.")
        end
        if C_AddOns.IsAddOnLoaded("NorthernSkyMedia") then
            print("Please uninstall the |cFF00FFFFNorthern Sky Media Addon|r as this new Addon takes over all its functionality")
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
        if C_AddOns.IsAddOnLoaded("MegaMacro") then return end -- don't mess with macros if user has MegaMacro as it will spam create macros
        for i=1, 120 do
            local macroname = C_Macro.GetMacroName(i)
            if not macroname then break end
            macrocount = i
            if macroname == "NS PA Macro" then
                local macrotext = "/run NSAPI:PrivateAura();"
                if NSRT.Settings["PASelfPing"] then
                    macrotext = macrotext.."\n/ping [@player] Warning;"
                end
                if NSRT.Settings["PAExtraAction"] then
                    macrotext = macrotext.."\n/click ExtraActionButton1"
                end
                EditMacro(i, "NS PA Macro", 132288, macrotext, false)
                pafound = true
            elseif macroname == "NS Ext Macro" then
                local macrotext = NSRT.Settings["ExternalSelfPing"] and "/run NSAPI:ExternalRequest();\n/ping [@player] Assist;" or "/run NSAPI:ExternalRequest();"
                EditMacro(i, "NS Ext Macro", 135966, macrotext, false)
                extfound = true
            elseif macroname == "NS Innervate" then
                EditMacro(i, "NS Innervate", 136048, "/run NSAPI:InnervateRequest();", false)
                innervatefound = true
            end
            if pafound and extfound and innervatefound then break end
        end
        if macrocount >= 120 and not pafound then
            print("You reached the global Macro cap so the Private Aura Macro could not be created")
        elseif not pafound then
            macrocount = macrocount+1            
            local macrotext = "/run NSAPI:PrivateAura();"
            if NSRT.Settings["PASelfPing"] then
                macrotext = macrotext.."\n/ping [@player] Warning;"
            end
            if NSRT.Settings["PAExtraAction"] then
                macrotext = macrotext.."\n/click ExtraActionButton1"
            end
            if NSRT.Settings["LIQUID_MACRO"] then
                macrotext = macrotext.."\n/run WeakAuras.ScanEvents(\"LIQUID_PRIVATE_AURA_MACRO\", true)"
            end
            CreateMacro("NS PA Macro", 132288, macrotext, false)
        end
        if macrocount >= 120 and not extfound then 
            print("You reached the global Macro cap so the External Macro could not be created")
        elseif not extfound then
            macrocount = macrocount+1
            local macrotext = NSRT.Settings["ExternalSelfPing"] and "/run NSAPI:ExternalRequest();\n/ping [@player] Assist;" or "/run NSAPI:ExternalRequest();"
            CreateMacro("NS Ext Macro", 135966, macrotext, false)
        end
        if macrocount >= 120 and not inenrvatefound then
            print("You reached the global Macro cap so the Innervate Macro could not be created")
        elseif not innervatefound then
            macrocount = macrocount+1
            CreateMacro("NS Innervate", 136048, "/run NSAPI:InnervateRequest();", false)
        end
    elseif e == "READY_CHECK" and (wowevent or NSRT.Settings["Debug"]) then
        if self:Restricted() then return end
        if self:DifficultyCheck(false, 14) then -- only care about note comparison in normal, heroic&mythic raid
            local note = NSAPI:GetNote()
            if note ~= "empty" then
                local hashed = NSAPI:GetHash(note) or ""     
                self:Broadcast("MRT_NOTE", "RAID", hashed)   
            end
        end
        if (self:IsMidnight() and self:DifficultyCheck(false, 14)) or NSRT.Settings["Debug"] then
            if UnitIsGroupLeader("player") then
                self:Broadcast("NS_REM_SHARE", "RAID", self.Reminder)
            end
            self.Difference = {}
            self:StoreFrames(true)
            C_Timer.After(1, function()
                self:EventHandler("NS_COMPARE_REMINDER", false, true)
            end)
        end
        if NSRT.Settings["CheckCooldowns"] and self:DifficultyCheck(false, 15) and UnitInRaid("player") then
            self:CheckCooldowns()
        end
        self.specs = {}
        self.GUIDS = {}
        NSAPI.HasNSRT = {}
        for u in self:IterateGroupMembers() do
            if UnitIsVisible(u) then
                NSAPI.HasNSRT[u] = false
                self.specs[u] = false
                local G = UnitGUID(u)
                self.GUIDS[u] = (issecretvalue(G) and "") or G
            end
        end
        -- broadcast spec info
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        NSAPI:Broadcast("NSAPI_SPEC", "RAID", specid)
        C_Timer.After(1, function()
            self:EventHandler("NSAPI_READY_CHECK", false, true)
        end)
    elseif e == "NSAPI_READY_CHECK" and internal then
        if self:Restricted() then return end
        if NSRT.Settings["RebuffCheck"] then
            self:BuffCheck()
        end        
    elseif e == "GROUP_FORMED" and (wowevent or NSRT.Settings["Debug"]) then 
        if self:Restricted() then return end
        if NSRT.Settings["MyNickName"] then self:SendNickName("Any", true) end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname

    elseif e == "MRT_NOTE" and NSRT.Settings["MRTNoteComparison"] and (internal or NSRT.Settings["Debug"]) then
        if self:Restricted() then return end
        local _, hashed = ...     
        if hashed ~= "" then
            local note = C_AddOns.IsAddOnLoaded("MRT") and NSAPI:GetHash(NSAPI:GetNote()) or ""    
            if note ~= "" and note ~= hashed then
                NSAPI:DisplayText("MRT Note Mismatch detected", 5)
            end
        end
    elseif e == "UNIT_AURA" and (self.Externals and self.Externals.target) and ((UnitIsUnit(self.Externals.target, "player") and wowevent) or NSRT.Settings["Debug"]) then
        if self:IsMidnight() then return end
        local unit, info = ...
        if not self.Externals.AllowedUnits[unit] then return end
        if info and info.addedAuras then
            for _, v in ipairs(info.addedAuras) do
                if self.Externals.Automated[v.spellId] then
                    local key = self.Externals.Automated[v.spellId]
                    local num = (key and self.Externals.Amount[key..v.spellId])
                    self:EventHandler("NS_EXTERNAL_REQ", false, true, unit, key, num, false, "skip", v.expirationTime)
                end
            end
        end
    elseif e == "NSI_VERSION_CHECK" and (internal or NSRT.Settings["Debug"]) then
        if self:Restricted() then return end
        local unit, ver, duplicate, ignoreCheck = ...        
        self:VersionResponse({name = UnitName(unit), version = ver, duplicate = duplicate, ignoreCheck = ignoreCheck})
    elseif e == "NSI_VERSION_REQUEST" and (internal or NSRT.Settings["Debug"]) then
        if self:Restricted() then return end
        local unit, type, name = ...        
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't send to yourself
        if UnitExists(unit) then
            local u, ver, duplicate, _, ignoreCheck = self:GetVersionNumber(type, name, unit)
            self:Broadcast("NSI_VERSION_CHECK", "WHISPER", unit, ver, duplicate, ignoreCheck)
        end
    elseif e == "NSI_NICKNAMES_COMMS" and (internal or NSRT.Settings["Debug"]) then
        if self:Restricted() then return end
        local unit, nickname, name, realm, requestback, channel = ...
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't add new nickname if it's yourself because already adding it to the database when you edit it
        if requestback and (UnitInRaid(unit) or UnitInParty(unit)) then self:SendNickName(channel, false) end -- send nickname back to the person who requested it
        self:NewNickName(unit, nickname, name, realm, channel)

    elseif e == "PLAYER_REGEN_ENABLED" and (wowevent or NSRT.Settings["Debug"]) then
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
    elseif e == "NSI_NICKNAMES_SYNC" and (internal or NSRT.Settings["Debug"]) then
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
    elseif e == "NSI_WA_SYNC" and (internal or NSRT.Settings["Debug"]) then
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

    elseif e == "NSAPI_SPEC" then -- Should technically rename to "NSI_SPEC" but need to keep this open for the global broadcast to be compatible with the database WA
        local unit, spec = ...
        self.specs = self.specs or {}
        local G = UnitGUID(unit)
        G = issecretvalue(G) and "" or G
        self.specs[unit] = tonumber(spec)
        NSAPI.HasNSRT = NSAPI.HasNSRT or {}
        NSAPI.HasNSRT[unit] = true
    elseif e == "NSAPI_SPEC_REQUEST" then
        if self:Restricted() then return end
        local specid = GetSpecializationInfo(GetSpecialization())
        NSAPI:Broadcast("NSAPI_SPEC", "RAID", specid)            
    elseif e == "CHALLENGE_MODE_START" and (wowevent or NSRT.Settings["Debug"]) then
        if self:IsMidnight() then return end
        self.Externals:Init(true)
    elseif e == "GROUP_ROSTER_UPDATE" and (wowevent or NSRT.Settings["Debug"])then
        if self:Restricted() or not self:DifficultyCheck(false, 14) then return end
        self:StoreFrames(false)
    elseif e == "ENCOUNTER_START" and ((wowevent and self:DifficultyCheck(false, 14)) or NSRT.Settings["Debug"]) then -- allow sending fake encounter_start if in debug mode, only send spec info in mythic, heroic and normal raids
        if self:IsMidnight() or NSRT.Settings["Debug"] then 
            if not self.ProcessedReminder then -- should only happen if there was never a ready check, good to have this fallback though in case the user connected/zoned in after a ready check or they never did a ready check
                self:ProcessReminder()
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
            self.Timelines = {}
            self.TimeLinesDebug = {}
            self:AddAssignments(self.EncounterID)
            self:StartReminders(self.Phase)
            return 
        end
        self.specs = {}
        NSAPI.HasNSRT = {}
        for u in self:IterateGroupMembers() do
            if UnitIsVisible(u) then
                NSAPI.HasNSRT[u] = false
                self.specs[u] = WeakAuras and WeakAuras.SpecForUnit(u) or 0
            end
        end
        -- broadcast spec info
        local specid = GetSpecializationInfo(GetSpecialization())
        NSAPI:Broadcast("NSAPI_SPEC", "RAID", specid)
        C_Timer.After(1, function()
            WeakAuras.ScanEvents("NSAPI_ENCOUNTER_START", true)
        end)
        self.MacroPresses = {}
        self.Externals:Init()
    elseif e == "ENCOUNTER_END" and ((wowevent and self:DifficultyCheck(false, 14)) or NSRT.Settings["Debug"]) then
        local _, encounterName = ...
        if self:IsMidnight() then
            if NSRT.Settings["Debug"] and NSRT.Settings["DebugLogs"] then
                DevTool:AddData(self.TimeLinesDebug)
                NSRT.TimeLinesDebug = NSRT.TimeLinesDebug or {}
                table.insert(NSRT.TimeLinesDebug, self.TimeLinesDebug)
            end
            NSI:HideAllReminders()
            self.Timelines = {}
            self.ReminderTimer = {}
            self.AllGlows = {}            
        end
        C_Timer.After(1, function()
            if self:Restricted() then return end
            if self.SyncNickNamesStore then
                self:EventHandler("NSI_NICKNAMES_SYNC", false, true, self.SyncNickNamesStore.unit, self.SyncNickNamesStore.nicknametable, self.SyncNickNamesStore.channel)
                self.SyncNickNamesStore = nil
            end
            if self.WAString and self.WAString.unit and self.WAString.string then
                self:EventHandler("NSI_WA_SYNC", false, true, self.WAString.unit, self.WAString.string)
            end
        end)
        if self:IsMidnight() then return end
        if NSRT.Settings["DebugLogs"] then
            if self.MacroPresses and next(self.MacroPresses) then self:Print("Macro Data for Encounter: "..encounterName, self.MacroPresses) end
            if self.AssignedExternals and next(self.AssignedExternals) then self:Print("Assigned Externals for Encounter: "..encounterName, self.AssignedExternals) end
            self.AssignedExternals = {}
            self.MacroPresses = {}
        end      
    elseif (e == "ENCOUNTER_TIMELINE_EVENT_ADDED" or e == "ENCOUNTER_TIMELINE_EVENT_REMOVED") and (wowevent or NSRT.Settings["Debug"]) then  
        if not self:DifficultyCheck(false, 14) then return end -- only care about timelines in raid
        if self:Restricted() or NSRT.Settings["Debug"] then self:DetectPhaseChange(e) end
    elseif e == "NS_EXTERNAL_REQ" and ... and UnitIsUnit(self.Externals.target, "player") then -- only accept scanevent if you are the "server"
        if self:IsMidnight() then return end
        local unitID, key, num, req, range, expirationTime = ...
        local dead = NSAPI:DeathCheck(unitID)        
        self.MacroPresses = self.MacroPresses or {}
        self.MacroPresses["Externals"] = self.MacroPresses["Externals"] or {}
        local formattedrange = {}
        if type(range) == "table" then
            for k, v in pairs(range) do
                formattedrange[v.name] = v.range 
            end
        else
            formattedrange = range
        end
        table.insert(self.MacroPresses["Externals"], {unit = NSAPI:Shorten(unitID, 8), time = Round(GetTime()-self.Externals.pull), dead = dead, key = key, num = num, automated = not req, rangetable = formattedrange})
        if (C_ChallengeMode.IsChallengeModeActive() or self:DifficultyCheck(true, 14)) and not dead then -- block incoming requests from dead people
            self.Externals:Request(unitID, key, num, req, range, false, expirationTime)
        end
    elseif e == "NS_INNERVATE_REQ" and ... and UnitIsUnit(self.Externals.target, "player") then -- only accept scanevent if you are the "server"
        if self:IsMidnight() then return end
        local unitID, key, num, req, range, expirationTime = ...
        local dead = NSAPI:DeathCheck(unitID)      
        self.MacroPresses = self.MacroPresses or {}
        self.MacroPresses["Innervate"] = self.MacroPresses["Innervate"] or {}
        local formattedrange = {}
        if type(range) == "table" then
            for k, v in pairs(range) do
                formattedrange[v.name] = v.range 
            end
        else
            formattedrange = range
        end
        table.insert(self.MacroPresses["Innervate"], {unit = NSAPI:Shorten(unitID, 8), time = Round(GetTime()-self.Externals.pull), dead = dead, key = key, num = num, rangetable = formattedrange})
        if (C_ChallengeMode.IsChallengeModeActive() or self:DifficultyCheck(true, 14)) and not dead then -- block incoming requests from dead people
            self.Externals:Request(unitID, "", 1, true, range, true, expirationTime)
        end
    elseif e == "NS_EXTERNAL_YES" and ... then
        if self:IsMidnight() then return end
        local _, unit, spellID = ...
        self:DisplayExternal(spellID, unit)
    elseif e == "NS_EXTERNAL_NO" then   
        if self:IsMidnight() then return end     
        local unit, innervate = ...      
        if innervate == "Innervate" then
            self:DisplayExternal("NoInnervate")
        else
            self:DisplayExternal()
        end
    elseif e == "NS_EXTERNAL_GIVE" and ... then
        if self:IsMidnight() then return end
        local _, unit, spellID = ...
        local hyperlink = C_Spell.GetSpellLink(spellID)
        WeakAuras.ScanEvents("CHAT_MSG_WHISPER", hyperlink, unit)
    elseif ((e == "NS_PAMACRO" and not self:IsMidnight()) or (self:IsMidnight() and e == "MINIMAP_PING")) and (internal or NSRT.Settings["Debug"]) then
        local unitID = ...        
        if unitID and UnitExists(unitID) then
            local i = UnitInRaid(unitID)
            unitID = i and "raid"..i
            if not unitID then return end
            self.LastPress = self.LastPress or {}
            local now = GetTime()
            if self.LastPress[unitID] and self.LastPress[unitID] > now+5 then return end
            self.LastPress[unitID] = now
            -- do assignement stuff
            if not NSRT.Settings["DebugLogs"] then return end            
            local time = self.Externals and self.Externals.pull or now
            self.MacroPresses = self.MacroPresses or {}
            self.MacroPresses["Private Aura"] = self.MacroPresses["Private Aura"] or {}
            table.insert(self.MacroPresses["Private Aura"], {name = NSAPI:Shorten(unitID, 8), time = Round(now-time)})
        end
    elseif e == "NS_COMPARE_REMINDER" and (internal or NSRT.Settings["Debug"]) then   
        if self:Restricted() then return end    
        C_Timer.After(1, function()
            self:EventHandler("NS_REM_COMPARE_RESULT", false, true)
        end)
        self:Broadcast("NS_REM_COMPARE", "RAID", self.Reminder)    
    elseif e == "NS_REM_SHARE" and (internal or NSRT.Settings["Debug"]) then
        local unit, assigntable = ...
        if UnitIsGroupLeader(unit) then
            self.Reminder = assigntable
            self:ProcessReminder()
        end
    elseif e == "NS_REM_COMPARE" and (internal or NSRT.Settings["Debug"]) then
        local unit, remindertable = ...
        if UnitIsVisible(unit) then
            self.Difference = self.Difference or {}
            if remindertable and not self.Reminder then
                local name = UnitName("player")
                table.insert(self.Difference, name)
            elseif (self.Reminder and not remindertable) or self.Reminder ~= remindertable then
                local name = UnitName(unit)
                table.insert(self.Difference, name)
            end
        end
    elseif e == "NS_CREM_COMPARE_RESULT" and (internal or NSRT.Settings["Debug"]) then
        if self.Difference and next(self.Difference) ~= nil then
            local displaytext = ""
            for k, v in ipairs(self.Difference) do
                local name, specicon, roleicon = NSAPI:Shorten(v, 8, true, "GlobalNickNames", false, true)
                displaytext = displaytext..specicon..roleicon..name
            end
            -- missing display function for now            
        end
    elseif e == "NSAPI_REM_DEBUG" and NSRT.Settings["Debug"] then
        local unit, encID = ...
        NSI:DebugAssignments(encID)
    end
end