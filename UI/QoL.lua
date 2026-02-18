local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI

function NSI:UpdateQoLTextDisplay()
    if self.IsQoLTextPreview then
        self:ToggleQoLTextPreview()
        return
    end
    self:CreateQoLTextDisplay()
    local F = self.NSRTFrame.QoLText
    F:ClearAllPoints()
    F:SetPoint(NSRT.QoL.TextDisplay.Anchor, self.NSRTFrame, NSRT.QoL.TextDisplay.relativeTo, NSRT.QoL.TextDisplay.xOffset, NSRT.QoL.TextDisplay.yOffset)
    F.text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.QoL.TextDisplay.FontSize, "OUTLINE")
    local text = ""
    local now = GetTime()
    for _, v in pairs(self.QoLTextDisplays or {}) do -- table structure: {SettingsName = string, text = string}
        if NSRT.QoL[v.SettingsName] then
            text = text..v.text.."\n"
        end
    end
    F.text:SetText(text)
    F:SetSize(F.text:GetStringWidth(), F.text:GetStringHeight())
end

function NSI:CreateQoLTextDisplay()
    if self.NSRTFrame.QoLText then return end
    self.NSRTFrame.QoLText = CreateFrame("Frame", nil, self.NSRTFrame, "BackdropTemplate")
    self.NSRTFrame.QoLText.text = self.NSRTFrame.QoLText:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local F = self.NSRTFrame.QoLText
    F:SetPoint(NSRT.QoL.TextDisplay.Anchor, self.NSRTFrame, NSRT.QoL.TextDisplay.relativeTo, NSRT.QoL.TextDisplay.xOffset, NSRT.QoL.TextDisplay.yOffset)
    F:SetFrameStrata("DIALOG")
    F.text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.QoL.TextDisplay.FontSize, "OUTLINE")
    F.text:SetPoint("TOP", F, "TOP", 0, 0)
    F.text:SetTextColor(1, 1, 1, 1)
    F.Border = CreateFrame("Frame", nil, F, "BackdropTemplate")
    F.Border:SetPoint("TOPLEFT", F, "TOPLEFT", -6, 6)
    F.Border:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", 6, -6)
    F.Border:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tileSize = 0,
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
    F.Border:SetBackdropBorderColor(1, 1, 1, 1)
    F.Border:SetBackdropColor(0, 0, 0, 0)
    F.Border:Hide()
    F.Border:SetFrameStrata("DIALOG")
    F:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    F:SetScript("OnDragStop", function(Frame)
        self:StopFrameMove(Frame, NSRT.QoL.TextDisplay)
    end)
end

function NSI:ToggleQoLTextPreview()
    if self.IsQoLTextPreview then
        self:CreateQoLTextDisplay()
        local GatewayIcon = "\124T"..C_Spell.GetSpellTexture(111771)..":12:12:0:0:64:64:4:60:4:60\124t"
        local ResetBossIcon = "\124T"..C_Spell.GetSpellTexture(57724)..":12:12:0:0:64:64:4:60:4:60\124t"
        local CrestIcon = "\124T"..C_CurrencyInfo.GetCurrencyInfo(3347).iconFileID..":12:12:0:0:64:64:4:60:4:60\124t"
        local PrevieWTexts = {
            "This is a preview of the QoL Text Display.",
            NSRT.QoL.GatewayUseableDisplay and GatewayIcon.."Gateway Useable"..GatewayIcon or "",
            NSRT.QoL.ResetBossDisplay and ResetBossIcon.."Reset Boss"..ResetBossIcon or "",
            NSRT.QoL.LootBossReminder and CrestIcon.."Loot Boss"..CrestIcon or "",
            "All enabled Text Displays will show here.",
        }
        local text = ""
        for _, v in ipairs(PrevieWTexts) do -- table structure: {enabled = bool, text = string}
            if v ~= "" then
                text = text..v.."\n"
            end
        end
        local F = self.NSRTFrame.QoLText
        F.text:SetText(text)
        F.text:SetFont(self.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.QoL.TextDisplay.FontSize, "OUTLINE")
        F:SetSize(F.text:GetStringWidth(), F.text:GetStringHeight())
        self:ToggleMoveFrames(F, true)
    else
        self:ToggleMoveFrames(self.NSRTFrame.QoLText)
        self:UpdateQoLTextDisplay()
    end
end




-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.QoL = {
}
