local _, NSI = ...

function NSI:CreateGenericDisplays()
    if self.NSRTFrame.generic_display then return end

    local genericDisplay = CreateFrame("Frame", nil, self.NSRTFrame, "BackdropTemplate")
    genericDisplay:Hide()
    genericDisplay:SetPoint(NSRT.Settings.GenericDisplay.Anchor, self.NSRTFrame, NSRT.Settings.GenericDisplay.relativeTo, NSRT.Settings.GenericDisplay.xOffset, NSRT.Settings.GenericDisplay.yOffset)
    genericDisplay.Text = genericDisplay:CreateFontString(nil, "OVERLAY")
    genericDisplay.Text:SetFont(self:GetGlobalFontPath(), NSRT.Settings.GlobalFontSize, "OUTLINE")
    genericDisplay.Text:SetPoint("TOPLEFT", genericDisplay, "TOPLEFT", 0, 0)
    genericDisplay.Text:SetJustifyH("LEFT")
    genericDisplay.Text:SetText(self:Loc("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n"))
    genericDisplay:SetSize(genericDisplay.Text:GetStringWidth(), genericDisplay.Text:GetStringHeight())
    self.NSRTFrame.generic_display = genericDisplay

    local secretDisplay = CreateFrame("Frame", nil, self.NSRTFrame, "BackdropTemplate")
    secretDisplay:Hide()
    secretDisplay:SetPoint(NSRT.Settings.GenericDisplay.Anchor, self.NSRTFrame, NSRT.Settings.GenericDisplay.relativeTo, NSRT.Settings.GenericDisplay.xOffset, NSRT.Settings.GenericDisplay.yOffset)
    secretDisplay.Text = secretDisplay:CreateFontString(nil, "OVERLAY")
    secretDisplay.Text:SetFont(self:GetGlobalFontPath(), NSRT.Settings.GlobalEncounterFontSize, "OUTLINE")
    secretDisplay.Text:SetPoint("TOPLEFT", genericDisplay, "TOPLEFT", 0, 0)
    secretDisplay.Text:SetJustifyH("LEFT")
    secretDisplay.Text:SetText("")
    secretDisplay:SetSize(2000, 2000)
    self.NSRTFrame.SecretDisplay = secretDisplay
end

function NSI:DisplayText(text, duration)
    if self:Restricted() then return end
    self:CreateGenericDisplays()
    local display = self.NSRTFrame.generic_display
    display.Text:SetText(text)
    display:Show()
    display.Text:Show()
    if self.TextHideTimer then
        self.TextHideTimer:Cancel()
        self.TextHideTimer = nil
    end
    self.TextHideTimer = C_Timer.NewTimer(duration or 10, function() display:Hide() end)
end

function NSI:DisplaySecretText(formatString, hide, args)
    self:CreateGenericDisplays()
    local display = self.NSRTFrame.SecretDisplay
    if hide then
        display:Hide()
        display.Text:Hide()
        return
    end
    display.Text:SetFormattedText(formatString or "%s", unpack(args or {}))
    display:Show()
    display.Text:Show()
end
