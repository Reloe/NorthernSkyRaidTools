local _, NSI = ... -- Internal namespace

local SoundList = {
-- [spellID] = "SoundName",
}

function NSI:AddPASound(spellID, sound)
    if not C_UnitAuras.AuraIsPrivate(spellID) then return end
    local soundPath = NSI.LSM:Fetch("sound", sound)
    C_UnitAuras.RemovePrivateAuraAppliedSound(spellID)
    if soundPath and soundPath ~= 1 then
        C_UnitAuras.AddPrivateAuraAppliedSound({
            unitToken = "player",
            spellID = spellID,
            soundFileName = soundPath,
            outputChannel = "master",
        })
    end
end

function NSI:ApplyDefaultPASounds()
    for spellID, sound in pairs(SoundList) do
        NSRT.PASounds[spellID] = sound
        self:AddPASound(spellID, sound)
    end
end

function NSI:InitPA()
    
    if not self.PAFrame then
        self.PAFrame = CreateFrame("Frame", nil, UIParent)
    end
    self.PAFrame:SetSize(1, 1)
    self.PAFrame:SetPoint(NSRT.PASettings.Anchor, UIParent, NSRT.PASettings.relativeTo, NSRT.PASettings.xOffset, NSRT.PASettings.yOffset)
    
    if not self.AddedPA then self.AddedPA = {} end    
    local xDirection = (NSRT.PASettings.GrowDirection == "RIGHT" and 1) or (NSRT.PASettings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (NSRT.PASettings.GrowDirection == "DOWN" and -1) or (NSRT.PASettings.GrowDirection == "UP" and 1) or 0

    for auraIndex=1, 10 do
        local anchorID = "NSRT_PA"..auraIndex
        if self.AddedPA[anchorID] then
            C_UnitAuras.RemovePrivateAuraAnchor(self.AddedPA[anchorID])
            self.AddedPA[anchorID] = nil
        end    
        if NSRT.PASettings.enabled and NSRT.PASettings.Limit >= auraIndex then
            local privateAnchorArgs = {
                unitToken = "player",
                auraIndex = auraIndex,
                parent = self.PAFrame,
                showCountdownFrame = true,
                showCountdownNumbers = true,
                iconInfo = {
                    iconAnchor = {
                        point = "CENTER",
                        relativeTo = self.PAFrame,
                        relativePoint = "CENTER",
                        offsetX = 0 + (auraIndex-1) * (NSRT.PASettings.Width+NSRT.PASettings.Spacing) * xDirection,
                        offsetY = 0 + (auraIndex-1) * (NSRT.PASettings.Height+NSRT.PASettings.Spacing) * yDirection,
                    },
                iconWidth = NSRT.PASettings.Width,
                iconHeight = NSRT.PASettings.Height,
                }
            }        
            self.AddedPA[anchorID] = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
        end
    end
end

function NSI:InitRaidPA(party) -- still run this function if disabled to clean up old anchors
    if not self.PARaidFrames then self.PARaidFrames = {} end
    if not self.AddedPARaid then self.AddedPARaid = {} end
    for i=1, party and 5 or 40 do       
        local anchorID = party and "NSRT_PAParty"..i or "NSRT_PARaid"..i
        if self.AddedPARaid and self.AddedPARaid[anchorID] then
            for anchor, auraIndex in ipairs(self.AddedPARaid[anchorID]) do
                C_UnitAuras.RemovePrivateAuraAnchor(anchor[auraIndex])
                self.AddedPARaid[anchorID][auraIndex] = nil
            end
        end
        local u = party and "party"..i or "raid"..i
        if party and i == 5 then u = "player" end
        if NSRT.PARaidSettings.enabled and UnitExists(u) and self.RaidFrames[u] then 
            if not self.PARaidFrames[i] then
                self.PARaidFrames[i] = CreateFrame("Frame", nil, UIParent)
            end
            self.PARaidFrames[i]:SetSize(1, 1)
            self.PARaidFrames[i]:SetPoint(NSRT.PARaidSettings.Anchor, self.RaidFrames[u], NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset, NSRT.PARaidSettings.yOffset)
            local xDirection = (NSRT.PARaidSettings.GrowDirection == "RIGHT" and 1) or (NSRT.PARaidSettings.GrowDirection == "LEFT" and -1) or 0
            local yDirection = (NSRT.PARaidSettings.GrowDirection == "DOWN" and -1) or (NSRT.PARaidSettings.GrowDirection == "UP" and 1) or 0
            self.AddedPARaid[anchorID] = {}
            for auraIndex = 1, 10 do
                if auraIndex > NSRT.PARaidSettings.Limit then break end
                local privateAnchorArgs = {
                    unitToken = u,
                    auraIndex = auraIndex,
                    parent = self.PARaidFrames[i],
                    showCountdownFrame = true,
                    showCountdownNumbers = true,
                    iconInfo = {
                        iconAnchor = {
                            point = NSRT.PARaidSettings.Anchor,
                            relativeTo = self.PARaidFrames[i],
                            relativePoint = NSRT.PARaidSettings.relativeTo,
                            offsetX = 0 + (auraIndex-1) * (NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing) * xDirection,
                            offsetY = 0 + (auraIndex-1) * (NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing) * yDirection,
                        },
                        iconWidth = NSRT.PARaidSettings.Width,
                        iconHeight = NSRT.PARaidSettings.Height,
                    }
                }    
                self.AddedPARaid[anchorID][auraIndex] = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
            end
        end
    end
end

function NSI:UpdatePADisplay(Personal)
    if Personal then
        if self.IsPAPreview then
            self:PreviewPA(true)
        else
            self:PreviewPA(false)
            self:InitPA()
        end
    else
        if self.IsRaidPAPreview then
            self:PreviewRaidPA(true, true)
        else
            self:PreviewRaidPA(false)
            self:InitRaidPA(false)
        end
    end
end

function NSI:PreviewPA(Show)
    if not self.PAFrame then self:InitPA() end
    if not Show then
        if self.PAFrame.Border then self.PAFrame.Border:Hide() end
        self.PAFrame:SetMovable(false)
        self.PAFrame:EnableMouse(false)
        self.PAFrame:SetSize(1, 1)
        self:InitPA()
        if self.PAPreviewIcons then
            for _, icon in ipairs(self.PAPreviewIcons) do
                icon:Hide()
            end
        end
        return
    end
    self.PAFrame:SetSize((NSRT.PASettings.Width), (NSRT.PASettings.Height))
    self.PAFrame:SetPoint(NSRT.PASettings.Anchor, UIParent, NSRT.PASettings.relativeTo, NSRT.PASettings.xOffset, NSRT.PASettings.yOffset)
    if not self.PAFrame.Border then
        self.PAFrame.Border = CreateFrame("Frame", nil, self.PAFrame, "BackdropTemplate") 
        self.PAFrame.Border:SetAllPoints(self.PAFrame)
        self.PAFrame.Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
        self.PAFrame.Border:SetBackdropBorderColor(1, 1, 1, 1)
        self.PAFrame.Border:Hide()
    end
    
    self.PAFrame:SetMovable(true)
    self.PAFrame:EnableMouse(true)
    self.PAFrame:RegisterForDrag("LeftButton")
    self.PAFrame:SetClampedToScreen(true)
    self.PAFrame.Border:Show()
    self.PAFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.PAFrame:SetScript("OnDragStop", function(Frame)
        Frame:StopMovingOrSizing()       
        local Anchor, _, relativeTo, xOffset, yOffset = Frame:GetPoint()
        xOffset = Round(xOffset)
        yOffset = Round(yOffset)
        NSRT.PASettings.xOffset = xOffset     
        NSRT.PASettings.yOffset = yOffset  
        NSRT.PASettings.Anchor = Anchor    
        NSRT.PASettings.relativeTo = relativeTo    
    end)

    if not self.PAPreviewIcons then
        self.PAPreviewIcons = {}
    end
    for i=1, 10 do
        if not self.PAPreviewIcons[i] then
            self.PAPreviewIcons[i] = self.PAFrame:CreateTexture(nil, "ARTWORK")
            self.PAPreviewIcons[i]:SetTexture(237555)
        end
        if NSRT.PASettings.Limit >= i then
            local xOffset = (NSRT.PASettings.GrowDirection == "RIGHT" and (i-1)*(NSRT.PASettings.Width+NSRT.PASettings.Spacing)) or (NSRT.PASettings.GrowDirection == "LEFT" and -(i-1)*(NSRT.PASettings.Width+NSRT.PASettings.Spacing)) or 0
            local yOffset = (NSRT.PASettings.GrowDirection == "UP" and (i-1)*(NSRT.PASettings.Height+NSRT.PASettings.Spacing)) or (NSRT.PASettings.GrowDirection == "DOWN" and -(i-1)*(NSRT.PASettings.Height+NSRT.PASettings.Spacing)) or 0
            self.PAPreviewIcons[i]:SetSize(NSRT.PASettings.Width, NSRT.PASettings.Height)
            self.PAPreviewIcons[i]:SetPoint("CENTER", self.PAFrame, "CENTER", xOffset, yOffset)
            self.PAPreviewIcons[i]:Show()
        else
            self.PAPreviewIcons[i]:Hide()
        end
    end
end

function NSI:PreviewRaidPA(Show, Init)
    if self:Restricted() then 
        print("Secret value system is currently active so this feature is disabled.")
        return
    end
    if not Show then
        if self.PARaidPreviewFrame then self.PARaidPreviewFrame:Hide() end
        return
    end
    local MyFrame = self.LGF.GetUnitFrame("player")
    if not MyFrame then -- try again if no frame was found, as the first querry returns nil
        if Init then
            if self.RepeatRaidPAPreview then self.RepeatRaidPAPreview:Cancel() end
            self.RepeatRaidPAPreview = C_Timer.NewTimer(0.2, function() self:PreviewRaidPA(Show, false) end)
        else
            print("Couldn't find a matching raid frame for the player, aborting preview")
            self.IsRaidPAPreview = false
        end
        return
    end
    if not self.PARaidPreviewFrame then
        self.PARaidPreviewFrame = CreateFrame("Frame", nil, UIParent)
        self.PARaidPreviewFrame:EnableMouse(false)
        self.PARaidPreviewFrame:SetMouseClickEnabled(false)        
    end
    self.PARaidPreviewFrame:SetSize(NSRT.PARaidSettings.Width, NSRT.PARaidSettings.Height)
    self.PARaidPreviewFrame:SetPoint(NSRT.PARaidSettings.Anchor, MyFrame, NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset, NSRT.PARaidSettings.yOffset)

    if not self.PARaidPreviewIcons then
        self.PARaidPreviewIcons = {}
    end

    for i=1, 10 do
        if not self.PARaidPreviewIcons[i] then
            self.PARaidPreviewIcons[i] = self.PARaidPreviewFrame:CreateTexture(nil, "ARTWORK")
            self.PARaidPreviewIcons[i]:SetTexture(237555)
        end
        if NSRT.PARaidSettings.Limit >= i then
            local xOffset = (NSRT.PARaidSettings.GrowDirection == "RIGHT" and (i-1)*(NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing)) or (NSRT.PARaidSettings.GrowDirection == "LEFT" and -(i-1)*(NSRT.PARaidSettings.Width+NSRT.PARaidSettings.Spacing)) or 0
            local yOffset = (NSRT.PARaidSettings.GrowDirection == "UP" and (i-1)*(NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing)) or (NSRT.PARaidSettings.GrowDirection == "DOWN" and -(i-1)*(NSRT.PARaidSettings.Height+NSRT.PARaidSettings.Spacing)) or 0
            self.PARaidPreviewIcons[i]:SetSize(NSRT.PARaidSettings.Width, NSRT.PARaidSettings.Height)
            self.PARaidPreviewIcons[i]:SetPoint("CENTER", self.PARaidPreviewFrame, "CENTER", xOffset, yOffset)
            self.PARaidPreviewIcons[i]:Show()
        else
            self.PARaidPreviewIcons[i]:Hide()
        end
    end
end