local _, NSI = ... -- Internal namespace

-- figure out how to clean up Savedvariables for users on new expansions, probably just a one time cleanup
local SoundList = {
    -- [spellID] = "SoundName", use false to remove a sound

    -- Midnight S1
    [1284527] = "Targeted", -- Galvanize
    [1283236] = "Targeted", --Void Expulsion
    [1283069] = "Fixate", -- Weakened
    [1281184] = "Spread", -- Criticality
    [1280023] = "Targeted", -- Void Marked
    --[1279512] = "idk", -- Shatterglass - maybe adding this later
    [1249609] = "Rune", -- Dark Rune
    [1268992] = "Targeted", -- Shattering Twilight
    [1253024] = "Targeted", -- Shattering Twilight (Tank)
    [1270497] = "Spread", -- Shadowmark
    [1264756] = "Targeted", -- Rift Madness
    [1260027] = "Targeted", -- Grasp of Emptiness
    [1232470] = "Targeted", -- Gras of Emptiness (idk which one is correct)
    [1260203] = "Soak", -- Umbral Collapse
    [1249265] = "Soak", -- Umbral Collapse (one of them is 2nd cast I think?)
    [1259861] = "Targeted", -- Ranger Captain's Mark
    [1237623] = "Targeted", -- Ranger Captain's Mark(idk which one is correct)
 --   [1262983] = "Light", -- Twilight Seal (Light) - maybe adding this later, not sure if this is used at all
 --   [1262972] = "Void", -- Twilight Seal (Void) - maybe adding this later, not sure if this is used at all
    [1257087] = "Debuff", -- Consuming Miasma
    [1255612] = "Targeted", -- Dread Breath
    [1248697] = "Debuff", -- Despotic Command
    [1248994] = "Targeted", -- Execution Sentence
    [1248985] = "Targeted", -- Execution Sentence (not sure if this one is used)
    [1246487] = "Spread", -- Avenger's Shield
    [1242091] = "Targeted", -- Void Quill
    [1241992] = "Targeted", -- Light Quill
    [1241339] = "Void", -- Void Dive
    [1241292] = "Light", -- Light Dive
    [1239111] = "Break", -- Aspect of the End
    [1233887] = "Debuff", -- Null Corona
    [1254113] = "Fixate", -- Vorasius Fixate

    -- Manaforge
}

function NSI:AddPASound(spellID, sound)
    if (not spellID) or (not (C_UnitAuras.AuraIsPrivate(spellID))) then return end
    C_UnitAuras.RemovePrivateAuraAppliedSound(spellID)
    if not sound then return end -- essentially calling the function without a soundpath removes the sound (when user removes it in the UI)
    local soundPath = NSI.LSM:Fetch("sound", sound)
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
        local curSound = NSRT.PASounds[spellID]
        if (not curSound) or (not curSound.edited) then -- only add default sound if user hasn't edited it prior
            if not sound then -- if sound is false in the table I have marked it to be removed to clean up the table from old content
                NSRT.PASounds[spellID] = nil
                self:AddPASound(spellID, nil)
            else
                sound = "|cFF4BAAC8"..sound.."|r"
                NSRT.PASounds[spellID] = {sound = sound, edited = false}
                self:AddPASound(spellID, sound)
            end
        end
    end
end

function NSI:SavePASound(spellID, sound)
    if (not spellID) or (not (C_UnitAuras.AuraIsPrivate(spellID))) then return end
    NSRT.PASounds[spellID] = {sound = sound, edited = true}
    self:AddPASound(spellID, sound)
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

function NSI:RemoveTankPA()
    for i, anchortable in ipairs(self.AddedTankPA) do
        if self.AddedTankPA[i] then
            for anchorID, anchor in pairs(anchortable) do
                if self.AddedTankPA[i][anchorID] then
                    C_UnitAuras.RemovePrivateAuraAnchor(anchor)
                    self.AddedTankPA[i][anchorID] = nil
                end
            end
        end
    end
end

function NSI:InitTankPA()
    -- initiated on ENCOUNTER_START for tank players
    if not self.PATankFrame then
        self.PATankFrame = CreateFrame("Frame", nil, UIParent)
    end
    self.PATankFrame:SetSize(1, 1)
    self.PATankFrame:SetPoint(NSRT.PATankSettings.Anchor, UIParent, NSRT.PATankSettings.relativeTo, NSRT.PATankSettings.xOffset, NSRT.PATankSettings.yOffset)

    if not self.AddedTankPA then self.AddedTankPA = {} end
    local xDirection = (NSRT.PATankSettings.GrowDirection == "RIGHT" and 1) or (NSRT.PATankSettings.GrowDirection == "LEFT" and -1) or 0
    local yDirection = (NSRT.PATankSettings.GrowDirection == "DOWN" and -1) or (NSRT.PATankSettings.GrowDirection == "UP" and 1) or 0

    local multiTankx = (NSRT.PATankSettings.MultiTankGrowDirection == "RIGHT" and 1) or (NSRT.PATankSettings.MultiTankGrowDirection == "LEFT" and -1) or 0
    local multiTanky = (NSRT.PATankSettings.MultiTankGrowDirection == "DOWN" and -1) or (NSRT.PATankSettings.MultiTankGrowDirection == "UP" and 1) or 0
    local units = {}
    for unit in self:IterateGroupMembers() do
        if UnitGroupRolesAssigned(unit) == "TANK" and not (UnitIsUnit("player", unit)) then
            table.insert(units, unit)
        end
    end
    -- remove any previous anchor, also calling this on ENCOUNTER_END
    self:RemoveTankPA()
    for i, unit in ipairs(units) do
        self.AddedTankPA[i] = self.AddedTankPA[i] or {}
        for auraIndex = 1, 10 do
            local anchorID = "NSRT_TankPA"..auraIndex
            if self.AddedTankPA[i][anchorID] then
                C_UnitAuras.RemovePrivateAuraAnchor(self.AddedTankPA[i][anchorID])
                self.AddedTankPA[i][anchorID] = nil
            end
            if NSRT.PATankSettings.enabled and NSRT.PATankSettings.Limit >= auraIndex then
                local privateAnchorArgs = {
                    unitToken = unit,
                    auraIndex = auraIndex,
                    parent = self.PATankFrame,
                    showCountdownFrame = true,
                    showCountdownNumbers = true,
                    iconInfo = {
                        iconAnchor = {
                            point = "CENTER",
                            relativeTo = self.PATankFrame,
                            relativePoint = "CENTER",
                            offsetX = 0 + (auraIndex-1) * (NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing) * xDirection + (i-1) * (NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing) * multiTankx,
                            offsetY = 0 + (auraIndex-1) * (NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing) * yDirection + (i-1) * (NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing) * multiTanky,
                        },
                    iconWidth = NSRT.PATankSettings.Width,
                    iconHeight = NSRT.PATankSettings.Height,
                    }
                }        
                self.AddedTankPA[i][anchorID] = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
            end
        end
    end
end

function NSI:UpdatePADisplay(Personal, Tank)
    if Personal then
        if self.IsPAPreview then
            self:PreviewPA(true)
        else
            self:PreviewPA(false)
            self:InitPA()
        end
    elseif Tank then
        if self.IsTankPAPreview then
            self:PreviewTankPA(true)
        else
            self:PreviewTankPA(false)
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

function NSI:PreviewTankPA(Show)
    if not self.PATankFrame then self:InitTankPA() end
    if not Show then
        if self.PATankFrame.Border then self.PATankFrame.Border:Hide() end
        self.PATankFrame:SetMovable(false)
        self.PATankFrame:EnableMouse(false)
        self.PATankFrame:SetSize(1, 1)
        if self.PATankPreviewIcons then
            for _, icon in ipairs(self.PATankPreviewIcons) do
                icon:Hide()
            end
        end
        self:RemoveTankPA()
        return
    end
    self.PATankFrame:SetSize((NSRT.PATankSettings.Width), (NSRT.PATankSettings.Height))
    self.PATankFrame:SetPoint(NSRT.PATankSettings.Anchor, UIParent, NSRT.PATankSettings.relativeTo, NSRT.PATankSettings.xOffset, NSRT.PATankSettings.yOffset)
    if not self.PATankFrame.Border then
        self.PATankFrame.Border = CreateFrame("Frame", nil, self.PATankFrame, "BackdropTemplate") 
        self.PATankFrame.Border:SetAllPoints(self.PATankFrame)
        self.PATankFrame.Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
        self.PATankFrame.Border:SetBackdropBorderColor(1, 1, 1, 1)
        self.PATankFrame.Border:Hide()
    end

    self.PATankFrame:SetMovable(true)
    self.PATankFrame:EnableMouse(true)
    self.PATankFrame:RegisterForDrag("LeftButton")
    self.PATankFrame:SetClampedToScreen(true)
    self.PATankFrame.Border:Show()
    self.PATankFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.PATankFrame:SetScript("OnDragStop", function(Frame)
        Frame:StopMovingOrSizing()       
        local Anchor, _, relativeTo, xOffset, yOffset = Frame:GetPoint()
        xOffset = Round(xOffset)
        yOffset = Round(yOffset)
        NSRT.PATankSettings.xOffset = xOffset
        NSRT.PATankSettings.yOffset = yOffset
        NSRT.PATankSettings.Anchor = Anchor
        NSRT.PATankSettings.relativeTo = relativeTo
    end)

    if not self.PATankPreviewIcons then
        self.PATankPreviewIcons = {}
    end
    for i=1, 10 do
        if not self.PATankPreviewIcons[i] then
            self.PATankPreviewIcons[i] = self.PATankFrame:CreateTexture(nil, "ARTWORK")
            self.PATankPreviewIcons[i]:SetTexture(236318)
        end
        if NSRT.PATankSettings.Limit >= i then
            local xOffset = (NSRT.PATankSettings.GrowDirection == "RIGHT" and (i-1)*(NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing)) or (NSRT.PATankSettings.GrowDirection == "LEFT" and -(i-1)*(NSRT.PATankSettings.Width+NSRT.PATankSettings.Spacing)) or 0
            local yOffset = (NSRT.PATankSettings.GrowDirection == "UP" and (i-1)*(NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing)) or (NSRT.PATankSettings.GrowDirection == "DOWN" and -(i-1)*(NSRT.PATankSettings.Height+NSRT.PATankSettings.Spacing)) or 0
            self.PATankPreviewIcons[i]:SetSize(NSRT.PATankSettings.Width, NSRT.PATankSettings.Height)
            self.PATankPreviewIcons[i]:SetPoint("CENTER", self.PATankFrame, "CENTER", xOffset, yOffset)
            self.PATankPreviewIcons[i]:Show()
        else
            self.PATankPreviewIcons[i]:Hide()
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
    end
    self.PARaidPreviewFrame:SetSize(NSRT.PARaidSettings.Width, NSRT.PARaidSettings.Height)
    self.PARaidPreviewFrame:SetPoint(NSRT.PARaidSettings.Anchor, MyFrame, NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset, NSRT.PARaidSettings.yOffset)
    self.PARaidPreviewFrame:Show()

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