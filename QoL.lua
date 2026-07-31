local _, NSI = ... -- Internal namespace

local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:QoLEvents(e, ...)
end)

local GatewayIcon = "\124T"..C_Spell.GetSpellTexture(111771)..":12:12:0:0:64:64:4:60:4:60\124t"
local ResetBossIcon = "\124T"..C_Spell.GetSpellTexture(57724)..":12:12:0:0:64:64:4:60:4:60\124t"
local CrestIcon = "\124T"..C_CurrencyInfo.GetCurrencyInfo(3347).iconFileID..":12:12:0:0:64:64:4:60:4:60\124t"
local FeastIcon = "\124T"..C_Spell.GetSpellTexture(19705)..":12:12:0:0:64:64:4:60:4:60\124t"
local CauldronIcon = "\124T"..C_Spell.GetSpellTexture(448001)..":12:12:0:0:64:64:4:60:4:60\124t"
local SoulwellIcon = "\124T"..C_Spell.GetSpellTexture(6262)..":12:12:0:0:64:64:4:60:4:60\124t"
local RepairIcon = "\124T"..C_Spell.GetSpellTexture(126462)..":12:12:0:0:64:64:4:60:4:60\124t"
local TextDisplays = {
    Gateway = GatewayIcon.."Gateway Useable"..GatewayIcon,
    ResetBoss = ResetBossIcon.."Reset Boss"..ResetBossIcon,
    LootBoss = CrestIcon.."Loot Boss"..CrestIcon,
    SoulwellDropped = SoulwellIcon.."%s Dropped a Soulwell"..SoulwellIcon,
    FeastDropped = FeastIcon.."%s Dropped a Feast"..FeastIcon,
    RepairDropped = RepairIcon.."%s Dropped a Repair"..RepairIcon,
    CauldronDropped = CauldronIcon.."%s Dropped a Cauldron"..CauldronIcon,
}

local ConsumableSpells = {
    [1259657] = "FEAST", -- Quel'dorei Medley
    [1278915] = "FEAST", -- Hearty Quel'dorei Medley

    [1259658] = "FEAST", -- Harandar Celebration
    [1278929] = "FEAST", -- Hearty Harandar Celebration

    [1237104] = "FEAST", -- Blooming Feast
    [1278909] = "FEAST", -- Hearty Blooming Feast

    [1259659] = "FEAST", -- Silvermoon Parade
    [1278895] = "FEAST", -- Hearty Silvermoon Parade

    [1240267] = "CAULDRON", -- Voidlight Potion Cauldron
    [1240195] = "CAULDRON", -- Voidlight of Sin'dorei Flasks

    [29893] = "SOULWELL",

    [199109] = "REPAIR", -- Auto-Hammer
    [67826] = "REPAIR", -- Jeeves
}

local LustDebuffs = {
    57723, -- Exhaustion
    57724, -- Sated
    80354, -- Time Warp
    264689, -- Fatigued
    390435, -- Exhaustion
}

local function ParseCommaList(str)
    local set = {}
    if not str then return set end
    for word in str:gmatch("[^,]+") do
        word = strtrim(word):lower()
        if word ~= "" then
            set[word] = true
        end
    end
    return set
end

local CachedInviteKeywords, CachedInviteKeywordsSource

function NSI:MatchesInviteKeyword(msg)
    if issecretvalue(msg) then return false end
    local source = NSRT.QoL.AutoInviteKeywords
    if source ~= CachedInviteKeywordsSource then
        CachedInviteKeywords = ParseCommaList(source)
        CachedInviteKeywordsSource = source
    end
    if not next(CachedInviteKeywords) then return false end
    return CachedInviteKeywords[strtrim(msg):lower()] or false
end

function NSI:InvalidateInviteKeywordCache()
    CachedInviteKeywordsSource = nil
end

function NSI:QoLEvents(e, ...)
    if self.IsBuilding then return end
    if e == "ACTIONBAR_UPDATE_USABLE" then -- only thing needed for Gateway
        if NSRT.QoL.GatewayUseableDisplay and C_Item.IsUsableItem(188152) then
            self.QoLTextDisplays.Gateway = {SettingsName = "GatewayUseableDisplay", text = TextDisplays.Gateway}
        else
            self.QoLTextDisplays.Gateway = nil
        end
        self:UpdateQoLTextDisplay()
    elseif e == "ADDON_RESTRICTION_STATE_CHANGED" then
        C_Timer.After(0, function()
            if C_ChatInfo.InChatMessagingLockdown() then
                self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", false)
            else
                self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", true, "player")
            end
            if not NSRT.QoL.ResetBossDisplay then -- shouldn't be possible but another safety check
                self.QoLTextDisplays.ResetBoss = nil
                self:UpdateQoLTextDisplay()
                self:ToggleQoLEvent("UNIT_AURA", false)
                return
            elseif self:Restricted() then
                self.QoLTextDisplays.ResetBoss = nil
                self:ToggleQoLEvent("UNIT_AURA", false)
            else
                local inRaid = self:DifficultyCheck({14, 15, 16})
                if not inRaid then return end
                self:ToggleQoLEvent("UNIT_AURA", inRaid, "player")
                local debuffed = self:HasLustDebuff()
                if debuffed then
                    self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                else
                    self.QoLTextDisplays.ResetBoss = nil
                end
            end
            self:UpdateQoLTextDisplay()
        end)
    elseif e == "PLAYER_REGEN_DISABLED" and NSRT.QoL.ResetBossDisplay then
        self.QoLTextDisplays.ResetBoss = nil
        self:UpdateQoLTextDisplay()
    elseif e == "PLAYER_REGEN_ENABLED" and NSRT.QoL.ResetBossDisplay then
        if self:HasLustDebuff() then
            self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
        else
            self.QoLTextDisplays.ResetBoss = nil
        end
        self:UpdateQoLTextDisplay()
    elseif e == "UNIT_AURA" then
        if self:Restricted() then return end -- shouldn't happen because we unregister but just a safety check
        local unit, updateInfo = ...
        if NSRT.QoL.ResetBossDisplay and unit == "player" then
            if updateInfo.isFullUpdate then
                local debuff = self:HasLustDebuff()
                if debuff then
                    self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                else
                    self.QoLTextDisplays.ResetBoss = nil
                end
                self:UpdateQoLTextDisplay()
            elseif updateInfo.addedAuras then
                for _, auraData in ipairs(updateInfo.addedAuras) do
                    for _, spellID in ipairs(LustDebuffs) do
                        -- idk how this can ever be secret because I'm checking that at the very start but it can
                        if (not issecretvalue(auraData.spellId)) and auraData.spellId == spellID then
                            self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                            self:UpdateQoLTextDisplay()
                            return
                        end
                    end
                end
            elseif updateInfo.removedAuraInstanceIDs and self.QoLTextDisplays.ResetBoss then
                if self:HasLustDebuff() then
                    self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                else
                    self.QoLTextDisplays.ResetBoss = nil
                end
                self:UpdateQoLTextDisplay()
            end
        end
    elseif e == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.01, function()
            if self:DifficultyCheck({14, 15, 16}) and NSRT.QoL.ResetBossDisplay and not self:Restricted() then
                if self:HasLustDebuff() then
                    self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                    self:UpdateQoLTextDisplay()
                end
            end
            self:QoLOnZoneSwap()
        end)
    elseif e == "ENCOUNTER_END" and self:DifficultyCheck({14, 15, 16}) then
        if NSRT.QoL.LootBossReminder then
            local success = select(5, ...)
            if success == 1 then
                self.QoLTextDisplays.LootBoss = {SettingsName = "LootBossReminder", text = TextDisplays.LootBoss}
                self:UpdateQoLTextDisplay()
                self.LootReminderTimer = C_Timer.NewTimer(40, function() -- backup hide in case something goes wrong
                    if self.QoLTextDisplays.LootBoss then
                        self.QoLTextDisplays.LootBoss = nil
                        self:UpdateQoLTextDisplay()
                    end
                end)
            end
        end
    elseif e == "ENCOUNTER_START" and self:DifficultyCheck({14, 15, 16}) then
        self.QoLTextDisplays = {}
        self:UpdateQoLTextDisplay()
    elseif self:DifficultyCheck({14, 15, 16}) and (e == "LOOT_OPENED" or e == "CHAT_MSG_MONEY" or e == "ENCOUNTER_START") then
        if NSRT.QoL.LootBossReminder and self.QoLTextDisplays.LootBoss then
            self.QoLTextDisplays.LootBoss = nil
            self:UpdateQoLTextDisplay()
        end
    elseif e == "MERCHANT_SHOW" and NSRT.QoL.AutoRepair then
        RepairAllItems(CanGuildBankRepair())
    elseif (e == "CHAT_MSG_WHISPER" or e == "CHAT_MSG_BN_WHISPER") and NSRT.QoL.AutoInvite then
        local msg, playerName = ...
        if issecretvalue(msg) or issecretvalue(playerName) then return end
        if self:MatchesInviteKeyword(msg) then
            if e == "CHAT_MSG_BN_WHISPER" then
                local bnSenderID = select(13, ...)
                for i = 1, BNGetNumFriends() do
                    local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                    if bnSenderID == accountInfo.bnetAccountID then
                        for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
                            local gameInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
                            if gameInfo then
                                local char = gameInfo.characterName
                                local realm = gameInfo.realmName
                                if char and realm then
                                    playerName = char.."-"..realm
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
            -- unfortunately have to check guild roster because C_GuildInfo.MemberExistsByName is a security risk as it can't check the realm
            if NSRT.QoL.AutoInviteGuildOnly and not self:IsInSameGuild(nil, playerName) then return end
            if UnitInRaid(playerName) or UnitInParty(playerName) then return end
            if IsInGroup() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then return end
            local now = GetTime()
            self.AutoInviteCooldown = self.AutoInviteCooldown or {}
            local key = playerName:lower()
            if self.AutoInviteCooldown[key] and self.AutoInviteCooldown[key] > now - 10 then return end
            self.AutoInviteCooldown[key] = now
            C_PartyInfo.InviteUnit(playerName)
        end
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        -- registered only for 'player' so we don't need a unitTarget check or a secret check
        local spellId = select(3, ...)
        if IsInGroup() and ConsumableSpells[spellId] then
            self:Broadcast("QoL_Comms", "RAID", ConsumableSpells[spellId])
        end
    elseif e == "QoL_Comms" then
        self:HandleQoLComm(...)
    elseif (e == "GROUP_ROSTER_UPDATE" or e == "PARTY_LEADER_CHANGED") and NSRT.QoL.AutoPromote then
        self:ScheduleAutoPromotePass()
    end
end

function NSI:InitQoL()
    self.QoLTextDisplays = {}
    if NSRT.QoL.AddSpellIDToTooltips then
        C_CVar.SetCVar("tooltipShowAuraSpellIDs", "1")
    end
    -- stuff in here is ALWAYS enabled.
    self:ToggleQoLEvent("PLAYER_ENTERING_WORLD", true)
    self:ToggleQoLEvent("ENCOUNTER_START", true)
    if NSRT.QoL.AutoRepair then self:ToggleQoLEvent("MERCHANT_SHOW", true) end
    if NSRT.QoL.AutoInvite then
        self:ToggleQoLEvent("CHAT_MSG_WHISPER", true)
        self:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", true)
    end
    if NSRT.QoL.AutoPromote then
        self:UpdateAutoPromoteEvents(true)
    end
end

function NSI:ToggleQoLEvent(event, enable, unit)
    if self.IsBuilding then return end
    if enable then
        f:RegisterUnitEvent(event, unit)
    else
        f:UnregisterEvent(event)
    end
end

function NSI:QoLOnZoneSwap() -- only register events while player is in raid
    local InRaid = self:DifficultyCheck({14, 15, 16})
    local InInstance = select(2, GetInstanceInfo()) == "party"
    if NSRT.QoL.ResetBossDisplay then
        self:ToggleQoLEvent("PLAYER_REGEN_ENABLED", true)
        self:ToggleQoLEvent("PLAYER_REGEN_DISABLED", true)
        if InRaid and not self:Restricted() then
            self:ToggleQoLEvent("UNIT_AURA", true, "player")
        else
            self:ToggleQoLEvent("UNIT_AURA", false)
        end
    end

    if NSRT.QoL.LootBossReminder then -- Loot Reminder is active in raid and any non-m+ dungeon
        self:ToggleQoLEvent("ENCOUNTER_END", InRaid)
        self:ToggleQoLEvent("LOOT_OPENED", InRaid)
        self:ToggleQoLEvent("CHAT_MSG_MONEY", InRaid)
        self:ToggleQoLEvent("ENCOUNTER_START", InRaid)
    end

    if NSRT.QoL.GatewayUseableDisplay then self:ToggleQoLEvent("ACTIONBAR_UPDATE_USABLE", InRaid or InInstance) end

    -- always keeping these enabled when in a raid or instance as they are required for addon comms to work and addon restriction is used for multiple checks.
    self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", InRaid or InInstance, "player")
    self:ToggleQoLEvent("ADDON_RESTRICTION_STATE_CHANGED", InRaid or InInstance)

    if (not InRaid) and (not InInstance) then -- if zoning outside of raid&dungeon -> remove all displays
        self.QoLTextDisplays = {}
        self:UpdateQoLTextDisplay()
    end
end

function NSI:HasLustDebuff()
    if self:Restricted() then return false end
    if not self:DifficultyCheck({14, 15, 16}) then return false end
    for _, spellID in ipairs(LustDebuffs) do
        local debuff = self:UnitAura("player", spellID)
        if (not issecretvalue(debuff)) and debuff then
            return true
        end
    end
    return false
end

function NSI:VantusRuneCheck()
    if self:Restricted() then print("Auras are currently secret so this is unvailable.") return end
    if not UnitInRaid("player") then return end
    local name = C_Spell.GetSpellInfo(1276691).name
    local prefix = name:match("^([^:]+)") -- get localized name of vantus runes
    if issecretvalue(prefix) then return end
    local maxgroup = self:DifficultyCheck({16}) and 4 or 6 -- if outside raidlead checks this always goes to 6 but guess that's fine
    local text = ""
    for i=1, 40 do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name and subgroup and subgroup <= maxgroup then
            local index = UnitInRaid(name)
            local unitid = index and "raid"..index
            if unitid then
                local found = false
                for j=1, 100 do
                    local buff = C_UnitAuras.GetAuraDataByIndex(unitid, j, "HELPFUL")
                    if not buff then break end
                    if (not issecretvalue(buff.name)) and buff.name:find(prefix) then
                        found = true
                        break
                    end
                end
                if not found then
                    if text == "" then text = name else text = text..", "..name end
                end
            end
        end
    end
    if text ~= "" then
        text = "Missing Vantus Runes: "..text
        print(text)
    else
        print("Everyone has a Vantus Rune!")
    end
end

function NSI:HandleQoLComm(unitName, type)
    -- We can get addon comms from anywhere, but only show notifs from players we can actually see.
    if C_InstanceEncounter.IsEncounterInProgress() then return end -- don't popup anything while in boss combat
    if not UnitIsVisible(unitName) then
        return
    end

    if UnitIsUnit(unitName, "player") then
        return
    end

    local displayTimerSeconds = NSRT.QoL.ConsumableNotificationDurationSeconds or 5
    local displayName = NSAPI:Shorten(unitName, 8, false, "GlobalNickNames")
    if type == "FEAST" then
        -- can't check buff duration/presence in combat
        if self:Restricted() then
            return
        end

        local wellFedBuff = self:UnitAura("player", "Well Fed")
        local okayBuffDurationSeconds = 10 * 60
        if wellFedBuff and wellFedBuff.expirationTime and (wellFedBuff.expirationTime - GetTime() > okayBuffDurationSeconds) then
            return
        end

        self.QoLTextDisplays.FeastDropped = {SettingsName = "FeastDropped", text = string.format(TextDisplays.FeastDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.FeastDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    elseif type == "CAULDRON" then
        -- TODO: check flask buff duration and number of potions in inventory?
        self.QoLTextDisplays.CauldronDropped = {SettingsName = "CauldronDropped", text = string.format(TextDisplays.CauldronDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.CauldronDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    elseif type == "SOULWELL" then
        local healthstoneCharges = C_Item.GetItemCount(5512, false, true)
        if healthstoneCharges == 3 then
            return
        end
        self.QoLTextDisplays.SoulwellDropped = {SettingsName = "SoulwellDropped", text = string.format(TextDisplays.SoulwellDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.SoulwellDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    elseif type == "REPAIR" then
        -- no repair notifications above this threshold
        local durabilityCutoff = 0.9

        local minDurability = 1
        for i=1, 18 do
            local currentDurability, maxDurability = GetInventoryItemDurability(i)
            if currentDurability ~= nil then
                minDurability = min(minDurability, currentDurability / maxDurability)
            end
        end
        if minDurability >= durabilityCutoff then
            return
        end

        self.QoLTextDisplays.RepairDropped = {SettingsName = "RepairDropped", text = string.format(TextDisplays.RepairDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.RepairDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    end
end

function NSI:ParseAutoPromoteNames() -- original casing preserved, since nicknames are stored case-sensitively
    local list = {}
    local str = NSRT.QoL.AutoPromoteNames
    if str then
        for word in str:gmatch("[^,]+") do
            word = strtrim(word)
            if word ~= "" then
                list[#list + 1] = word
            end
        end
    end
    return list
end

function NSI:UpdateAutoPromoteEvents(enable)
    self:ToggleQoLEvent("GROUP_ROSTER_UPDATE", enable)
    self:ToggleQoLEvent("PARTY_LEADER_CHANGED", enable)
    if enable then
        self:ScheduleAutoPromotePass()
    elseif self.AutoPromoteTimer then
        self.AutoPromoteTimer:Cancel()
        self.AutoPromoteTimer = nil
    end
end

function NSI:ScheduleAutoPromotePass()
    if self.AutoPromoteTimer then
        self.AutoPromoteTimer:Cancel()
    end
    self.AutoPromoteTimer = C_Timer.NewTimer(1.5, function()
        self.AutoPromoteTimer = nil
        self:AutoPromotePass()
    end)
end

-- Guild rank permission flags (C_GuildInfo.GuildControlGetRankFlags) are believed to require
-- guild-master access to read reliably, so we can't safely auto-detect "officer" ranks from
-- permissions. Instead the user picks a rank from their guild's real rank list (rankIndex is
-- 0-based, lower = higher rank, matching GetGuildRosterInfo) and everyone at or above it promotes.
function NSI:AutoPromotePass(force)
    if not force and not NSRT.QoL.AutoPromote then return end
    if not (UnitInRaid("player") and UnitIsGroupLeader("player")) then return end
    if InCombatLockdown() or C_InstanceEncounter.IsEncounterInProgress() then return end
    if self:Restricted() then return end

    local guildRankByName
    if NSRT.QoL.AutoPromoteOfficers and IsInGuild() then
        local numMembers = GetNumGuildMembers()
        if not numMembers or numMembers == 0 then
            C_Timer.After(2, function() self:AutoPromotePass(force) end)
            return
        end
        guildRankByName = {}
        for i = 1, numMembers do
            local name, _, rankIndex = GetGuildRosterInfo(i)
            if name and rankIndex then
                guildRankByName[name] = rankIndex
            end
        end
    end

    local nameList = self:ParseAutoPromoteNames()
    local rankThreshold = NSRT.QoL.AutoPromoteRankIndex or 1
    local realm = GetNormalizedRealmName()

    -- Index eligible (not already leader/assistant) raid members every way we might need to look them up.
    local byUnit, byFullName, byBareNameLower, byFullNameLower = {}, {}, {}, {}
    for i = 1, 40 do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if not name then break end
        local unit = "raid"..i
        if not (UnitIsUnit(unit, "player") or UnitIsGroupAssistant(unit) or UnitIsGroupLeader(unit)) then
            local bareName = (strsplit("-", name))
            local fullName = name:find("-", 1, true) and name or (name.."-"..realm)
            local entry = { unit = unit, fullName = fullName }
            byUnit[unit] = entry
            byFullName[fullName] = entry
            byFullNameLower[fullName:lower()] = entry
            local bareLower = bareName:lower()
            byBareNameLower[bareLower] = byBareNameLower[bareLower] or {}
            tinsert(byBareNameLower[bareLower], entry)
        end
    end

    local toPromote, queued = {}, {}
    local function Queue(entry)
        if not entry or queued[entry.unit] then return end
        queued[entry.unit] = true
        tinsert(toPromote, entry.unit)
    end

    if guildRankByName then
        for _, entry in pairs(byUnit) do
            local rankIndex = guildRankByName[entry.fullName]
            if rankIndex and rankIndex <= rankThreshold then
                Queue(entry)
            end
        end
    end

    for _, keyword in ipairs(nameList) do
        -- Nicknames first: promote every raid member who shares this nickname, not just one.
        local characters = NSAPI:GetCharacters(keyword)
        if characters then
            for key in pairs(characters) do
                if key:find("-", 1, true) then
                    Queue(byFullName[key])
                else
                    for _, entry in ipairs(byBareNameLower[key:lower()] or {}) do
                        Queue(entry)
                    end
                end
            end
        end
        -- Then literal character names, in case the entry is actually someone's character name rather than a nickname.
        local lower = keyword:lower()
        Queue(byFullNameLower[lower])
        for _, entry in ipairs(byBareNameLower[lower] or {}) do
            Queue(entry)
        end
    end

    for idx, unit in ipairs(toPromote) do
        C_Timer.After((idx - 1) * 0.1, function()
            if not UnitExists(unit) then return end
            if UnitIsGroupAssistant(unit) or UnitIsGroupLeader(unit) then return end
            if C_PartyInfo and C_PartyInfo.PromoteToAssistant then
                C_PartyInfo.PromoteToAssistant(unit)
            elseif PromoteToAssistant then
                PromoteToAssistant(unit)
            end
        end)
    end
end
