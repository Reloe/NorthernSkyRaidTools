local _, NSI = ... -- Internal namespace

local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:QoLEvents(e, ...)
end)

local GatewayIcon = "\124T"..C_Spell.GetSpellTexture(111771)..":12:12:0:0:64:64:4:60:4:60\124t"
local ResetBossIcon = "\124T"..C_Spell.GetSpellTexture(57724)..":12:12:0:0:64:64:4:60:4:60\124t"
local TextDisplays = {
    Gateway = GatewayIcon.."Gateway Useable"..GatewayIcon,
    ResetBoss = ResetBossIcon.."Reset Boss"..ResetBossIcon,
}

local LustDebuffs = {
    57723, -- Exhaustion
    57724, -- Sated
    80354, -- Time Warp
    264689, -- Fatigued
    390435, -- Exhaustion
    65081,
}
function NSI:QoLEvents(e, ...)
    if e == "ACTIONBAR_UPDATE_USABLE" then
        if C_Item.IsUsableItem(188152) then
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
                        if auraData.spellId == spellID then
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
        if self:DifficultyCheck(14) and NSRT.QoL.ResetBossDisplay and not self:Restricted() then
            f:RegisterEvent("UNIT_AURA")
        else
            f:UnregisterEvent("UNIT_AURA")
        end
    end
end

function NSI:InitQoL()
    self.QoLTextDisplays = {}
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    if NSRT.QoL.GatewayUseableDisplay then
        f:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    end
    if NSRT.QoL.ResetBossDisplay then
        f:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
        if self:DifficultyCheck(14) and not self:Restricted() then
            f:RegisterEvent("UNIT_AURA")
        else
            f:UnregisterEvent("UNIT_AURA")
        end
    end
end

function NSI:ToggleQoLEvent(event, enable)
    if enable then
        f:RegisterEvent(event)
    else
        f:UnregisterEvent(event)
    end
end


function NSI:HasLustDebuff()
    for _, spellID in ipairs(LustDebuffs) do
        local debuff = self:UnitAura("player", spellID)
        if debuff then
            return debuff
        end
    end
    return false
end