local _, NSI = ... -- Internal namespace

local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:QoLEvents(e, ...)
end)

local GatewayIcon = "\124T"..C_Spell.GetSpellTexture(111771)..":12:12:0:0:64:64:4:60:4:60\124t"
local TextDisplays = {
    Gateway = GatewayIcon.."Gateway Useable"..GatewayIcon,
}

function NSI:QoLEvents(e, ...)
    if e == "ACTIONBAR_UPDATE_USABLE" then
        if C_Item.IsUsableItem(188152) then
            self.QoLTextDisplays.Gateway = {SettingsName = "GatewayUseableDisplay", text = TextDisplays.Gateway}
        else
            self.QoLTextDisplays.Gateway = nil
        end
        self:UpdateQoLTextDisplay()
    end
end

function NSI:InitQoL()
    self.QoLTextDisplays = {}
    if NSRT.QoL.GatewayUseableDisplay then
        f:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    end
end

function NSI:ToggleQoLEvent(event, enable)
    if enable then
        f:RegisterEvent(event)
    else
        f:UnregisterEvent(event)
    end
end