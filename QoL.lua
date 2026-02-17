local _, NSI = ... -- Internal namespace

local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, e, ...)
    NSI:QoLEvents(e, ...)
end)

local TextDisplays = {
    Gateway = "Gateway Useable",
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