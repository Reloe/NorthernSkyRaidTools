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
    [1278929] = "FEAST", -- Hearty Rootland Celebration

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
function NSI:QoLEvents(e, ...)
    if e == "ACTIONBAR_UPDATE_USABLE" then -- only thing needed for Gateway
        if C_Item.IsUsableItem(188152) and NSRT.QoL.GatewayUseableDisplay then
            self.QoLTextDisplays.Gateway = {SettingsName = "GatewayUseableDisplay", text = TextDisplays.Gateway}
        else
            self.QoLTextDisplays.Gateway = nil
        end
        self:UpdateQoLTextDisplay()
    elseif e == "ADDON_RESTRICTION_STATE_CHANGED" then
        if not NSRT.QoL.ResetBossDisplay then -- shouldn't be possible but another safety check
            self.QoLTextDisplays.ResetBoss = nil
            self:UpdateQoLTextDisplay()
            self:ToggleQoLEvent("UNIT_AURA", false)
            return
        end
        if self:Restricted() then
            self.QoLTextDisplays.ResetBoss = nil
            self:ToggleQoLEvent("UNIT_AURA", false)
        else
            self:ToggleQoLEvent("UNIT_AURA", true)
            local debuffed = self:HasLustDebuff()
            if debuffed then
                self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
            else
                self.QoLTextDisplays.ResetBoss = nil
            end
        end
        if C_ChatInfo.InChatMessagingLockdown() then
            self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", false)
        else
            self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", true, "player")
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
        if self:DifficultyCheck(14) then
            if NSRT.QoL.ResetBossDisplay and not self:Restricted() then
                if self:HasLustDebuff() then
                    self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                    self:UpdateQoLTextDisplay()
                end
            end
        end
        self:QoLOnZoneSwap()
    elseif e == "ENCOUNTER_END" and self:DifficultyCheck(14) then
        if NSRT.QoL.LootBossReminder then
            local success = select(5, ...)
            if success == 1 then
                self.QoLTextDisplays.LootBoss = {SettingsName = "LootBossReminder", text = TextDisplays.LootBoss}
                self:UpdateQoLTextDisplay()
                self.LootReminderTimer = C_Timer.NewTimer(40, function() -- backup hide in case something goes wrong
                    self.QoLTextDisplays.LootBoss = nil
                    self:UpdateQoLTextDisplay()
                end)
            end
        end
    elseif self:DifficultyCheck(14) and (e == "LOOT_OPENED" or e == "CHAT_MSG_MONEY" or e == "ENCOUNTER_START") then
        if NSRT.QoL.LootBossReminder and self.QoLTextDisplays.LootBoss then
            self.QoLTextDisplays.LootBoss = nil
            self:UpdateQoLTextDisplay()
        end
    elseif e == "MERCHANT_SHOW" and NSRT.QoL.AutoRepair then
        RepairAllItems(true)
    elseif (e == "CHAT_MSG_WHISPER" or e == "CHAT_MSG_BN_WHISPER") and NSRT.QoL.AutoInvite then
        local msg, playerName = ...
        if issecretvalue(msg) or issecretvalue(playerName) then return end
        if msg == "inv" or msg == "invite" then
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
            for i=1, GetNumGuildMembers() do
                local name = GetGuildRosterInfo(i)
                if name == playerName then
                    C_PartyInfo.InviteUnit(playerName)
                    return
                end
            end
        end
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        -- registered only for 'player' so we don't need a unitTarget check or a secret check
        local spellId = select(3, ...)
        if (not C_ChatInfo.InChatMessagingLockdown()) and IsInGroup() and ConsumableSpells[spellId] then
            NSI:Broadcast("QoL_Comms", "RAID", ConsumableSpells[spellId])
        end
    elseif e == "QoL_Comms" then
        self:HandleQolComm(...)
    end
end

function NSI:InitQoL()
    self.QoLTextDisplays = {}
    self:ToggleQoLEvent("PLAYER_ENTERING_WORLD", true)
    -- Gateway Reminder specifically we don't care about being in raid or not as it's also useful in m+
    -- if there's other stuff in the future where this also applies we'll add it here instead of the zoneswap function
    if NSRT.QoL.GatewayUseableDisplay then self:ToggleQoLEvent("ACTIONBAR_UPDATE_USABLE", true) end
    if NSRT.QoL.AutoRepair then self:ToggleQoLEvent("MERCHANT_SHOW", true) end
    if NSRT.QoL.AutoInvite then
        self:ToggleQoLEvent("CHAT_MSG_WHISPER", true)
        self:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", true)
    end

    -- Need this enabled regardless of personal settings so that other people in our group get the comm.
    self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", true, "player")

    self:QoLOnZoneSwap()
end

function NSI:ToggleQoLEvent(event, enable, unit)
    if enable then
        -- TODO: can this just be f:RegisterUnitEvent(event, unit)?
        -- not sure if RegisterUnitEvent with a nil unit is identical to RegisterEvent
        if unit then
            f:RegisterUnitEvent(event, unit)
        else
            f:RegisterEvent(event)
        end
    else
        f:UnregisterEvent(event)
    end
end

function NSI:QoLOnZoneSwap() -- only register events while player is in raid
    local InRaid = self:DifficultyCheck(14)
    if NSRT.QoL.ResetBossDisplay then
        self:ToggleQoLEvent("ADDON_RESTRICTION_STATE_CHANGED", InRaid)
        if InRaid and not self:Restricted() then
            self:ToggleQoLEvent("UNIT_AURA", true)
        else
            self:ToggleQoLEvent("UNIT_AURA", false)
        end
    end
    if NSRT.QoL.LootBossReminder then
        self:ToggleQoLEvent("ENCOUNTER_END", InRaid)
        self:ToggleQoLEvent("LOOT_OPENED", InRaid)
        self:ToggleQoLEvent("CHAT_MSG_MONEY", InRaid)
        self:ToggleQoLEvent("ENCOUNTER_START", InRaid)
    end
    if not InRaid then
        self.QoLTextDisplays = {}
        self:UpdateQoLTextDisplay()
    end
end

function NSI:HasLustDebuff()
    for _, spellID in ipairs(LustDebuffs) do
        local debuff = self:UnitAura("player", spellID)
        if (not issecretvalue(debuff)) and debuff then
            return true
        end
    end
    return false
end

local VantusIds = {

}
function NSI:VantusRuneCheck()
    if self:Restricted() then print("Auras are currently secret so this is unvailable.") return end
    if not UnitInRaid("player") then return end
    local name = C_Spell.GetSpellInfo(1276691).name
    local prefix = name:match("^([^:]+)") -- get localized name of vantus runes
    local maxgroup = self:DifficultyCheck(16) and 4 or 6 -- if outside raidlead checks this always goes to 6 but guess that'S fine
    local text = ""
    for i=1, 40 do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name and subgroup and subgroup <= maxgroup then
            local unitid = UnitTokenFromGUID(UnitGUID(name))
            local found = false
            for j=1, 100 do
                local buff = C_UnitAuras.GetAuraDataByIndex(unitid, j, "HELPFUL")
                if not buff then break end
                if buff.name:find(prefix) then
                    found = true
                    break
                end
            end
            if not found then
                if text == "" then text = name else text = text..", "..name end
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

function NSI:HandleQolComm(unitName, type)
    -- We can get addon comms from anywhere, but only show notifs from players we can actually see.
    if not UnitIsVisible(unitName) then
        return
    end

    local displayTimerSeconds = NSRT.QoL.ConsumableNotificationDurationSeconds
    local displayName = WrapTextInColorCode(unitName, C_ClassColor.GetClassColor(select(2, UnitClass(unitName))):GenerateHexColor())
    if type == "FEAST" then
        -- can't check buff duration/presence in combat
        if InCombatLockdown()  then
            return
        end

        local wellFedBuff = C_UnitAuras.GetAuraDataBySpellName("player", "Well Fed")
        local okayBuffDurationSeconds = 10 * 60
        if wellFedBuff and (wellFedBuff.expirationTime - GetTime() > okayBuffDurationSeconds) then
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
