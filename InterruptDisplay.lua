local _, NSI = ... -- Internal namespace

function NSI:CreateInterruptDisplay()
    if not self.InterruptDisplay then
        self.InterruptDisplay = CreateFrame("Frame", "NSIInterruptDisplay", NSI.NSRTFrame)
        self.InterruptDisplay.Box = self.InterruptDisplay:CreateTexture(nil, "ARTWORK")
        self.InterruptDisplay.Box:SetColorTexture(0, 0, 0, 1)
        self.InterruptDisplay.Box:SetAllPoints()
        self.InterruptDisplay.Border = self.InterruptDisplay:CreateTexture(nil, "BACKGROUND")
        self.InterruptDisplay.Border:SetColorTexture(0, 0, 0, 1)
        self.InterruptDisplay.Border:SetPoint("TOPLEFT", self.InterruptDisplay, "TOPLEFT", -1, 1)
        self.InterruptDisplay.Border:SetPoint("BOTTOMRIGHT", self.InterruptDisplay, "BOTTOMRIGHT", 1, -1)
        self.InterruptDisplay.Number = self.InterruptDisplay:CreateFontString(nil, "OVERLAY")
        self.InterruptDisplay.Number:SetTextColor(1, 0, 0, 1)
        self.InterruptDisplay.Name = self.InterruptDisplay:CreateFontString(nil, "OVERLAY")
        self.InterruptDisplay.Name:SetTextColor(1, 1, 1, 1)
    end
    self.InterruptDisplay:ClearAllPoints()
    self.InterruptDisplay:SetSize(NSRT.InterruptSettings.Width, NSRT.InterruptSettings.Height)
    self.InterruptDisplay:SetPoint(NSRT.InterruptSettings.Anchor, NSI.NSRTFrame, NSRT.InterruptSettings.relativeTo, NSRT.InterruptSettings.xOffset, NSRT.InterruptSettings.yOffset)
    self.InterruptDisplay.Number:ClearAllPoints()
    self.InterruptDisplay.Number:SetPoint(NSRT.InterruptSettings.NumberAnchor, self.InterruptDisplay, NSRT.InterruptSettings.NumberRelativeTo, NSRT.InterruptSettings.NumberxOffset, NSRT.InterruptSettings.NumberyOffset)
    self.InterruptDisplay.Number:SetFont(self.LSM:Fetch("font", NSRT.InterruptSettings.NumberFont), NSRT.InterruptSettings.NumberFontSize, NSRT.InterruptSettings.NumberFontFlags)
    self.InterruptDisplay.Name:ClearAllPoints()
    self.InterruptDisplay.Name:SetPoint(NSRT.InterruptSettings.NameAnchor, self.InterruptDisplay, NSRT.InterruptSettings.NameRelativeTo, NSRT.InterruptSettings.NamexOffset, NSRT.InterruptSettings.NameyOffset)
    self.InterruptDisplay.Name:SetFont(self.LSM:Fetch("font", NSRT.InterruptSettings.NameFont), NSRT.InterruptSettings.NameFontSize, NSRT.InterruptSettings.NameFontFlags)
end

function NSI:DisplayInterrupt(isCastStart)
    local myKick = self.Interrupts.myKick
    local castCount = self.Interrupts.castCount
    local unit = self.Interrupts.myTable[castCount]
    local name = unit and UnitExists(unit) and NSAPI:Shorten(unit, 12, false, "GlobalNickNames", false, false) or ""
    self:CreateInterruptDisplay()
    self.InterruptDisplay.Number:SetText(castCount or "")
    self.InterruptDisplay.Name:SetText(name)
    if castCount == myKick then
        if isCastStart then -- player interrupts now
            self.InterruptDisplay.Box:SetColorTexture(0, 1, 0, 1)
            self.InterruptDisplay.Number:SetTextColor(1, 0, 0, 1)
        else -- player interrupts next
            self.InterruptDisplay.Box:SetColorTexture(1, 1, 0, 1)
            self.InterruptDisplay.Number:SetTextColor(1, 0, 0, 1)
        end
    elseif (castCount+1 == myKick) or (myKick == 1 and castCount == self.Interrupts.max) then
        self.InterruptDisplay.Box:SetColorTexture(1, 1, 0, 1)
        self.InterruptDisplay.Number:SetTextColor(1, 0, 0, 1)
    else
        self.InterruptDisplay.Number:SetTextColor(1, 1, 1, 1)
        self.InterruptDisplay.Box:SetColorTexture(1, 0, 0, 1)
    end
    self.InterruptDisplay:Show()
end

function NSI:PlayInterruptSound()
    local sound = NSRT.InterruptSettings.InterruptSound
    if sound then
        PlaySoundFile(NSI.LSM:Fetch("sound", sound), "Master")
    end
end

function NSI:HideInterrupt()
    if self.InterruptDisplay then
        self.InterruptDisplay:Hide()
    end
end

function NSI:ResetInterrupts()
    self.Interrupts.castCount = 1
    self.Interrupts.myTrackedID = self.Interrupts.myID
    self:HideInterrupt()
end

function NSI:InterruptOnCastStart()
    if not self.Interrupts or self.Interrupts.disabled then return end
    if self.Interrupts.myTrackedID == 0 then return end
    self:DisplayInterrupt(true)
    if self.Interrupts.castCount == self.Interrupts.myKick then
        self:PlayInterruptSound()
    end
end

function NSI:OnInterrupt()
    if not self.Interrupts or self.Interrupts.disabled then return end
    if self.Interrupts.myTrackedID == 0 then return end
    self:DisplayInterrupt()
end

function NSI:OnCastStop()
    if not self.Interrupts or self.Interrupts.disabled then return end
    if self.Interrupts.myTrackedID == 0 then return end
    self.Interrupts.castCount = self.Interrupts.castCount + 1
    if self.Interrupts.castCount > self.Interrupts.max then
        self.Interrupts.castCount = 1
    end
    self:DisplayInterrupt()
end

function NSI:ReadInterruptNote(StartNumber)
    local pers, shared = NSAPI:GetReminderString()
    if not pers then pers = "" end
    if not shared then shared = "" end
    local MRT = C_AddOns.IsAddOnLoaded("MRT") and _G.VMRT.Note.Text1 or ""
    local str = shared..pers..MRT
    local count = StartNumber or 0
    self.Interrupts = self.Interrupts or {}
    self.Interrupts.assignTable = {}
    self.Interrupts.myID = 0
    self.Interrupts.myKick = 0
    self.Interrupts.myTrackedID = 0
    self.Interrupts.castCount = 1
    self.Interrupts.disabled = false
    self.Interrupts.max = 0
    self.Interrupts.myTable = {}
    local assign = false
    for line in string.gmatch(str,'[^\r\n]+') do
        line = strtrim(line)
        if strlower(line) == "intend" then
            assign = false
            self.Interrupts.myTrackedID = self.Interrupts.myID
            self.Interrupts.myTable = self.Interrupts.assignTable[self.Interrupts.myID] or {}
            break
        elseif strlower(line) == "intstart" then
            assign = true
        elseif assign then
            local num = 0
            count = count+1
            self.Interrupts.assignTable[count] = self.Interrupts.assignTable[count] or {}
            for name in line:gmatch("%S+") do
                if UnitInRaid(name) then
                    num = num+1
                    table.insert(self.Interrupts.assignTable[count], name)
                    if UnitIsUnit(name, "player") then
                        self.Interrupts.myID = count
                        self.Interrupts.myKick = num
                    end
                    if count == self.Interrupts.myID then
                        self.Interrupts.max = #self.Interrupts.assignTable[count]
                    end
                end
            end
        end
    end
end