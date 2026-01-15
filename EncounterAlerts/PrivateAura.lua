local _, NSI = ... -- Internal namespace

function NSI:AddPASound(spellID, sound)
    if not C_UnitAuras.AuraIsPrivate(spellID) then return end
    local soundPath = NSI.LSM:Fetch("sound", sound)
    C_UnitAuras.RemovePrivateAuraAppliedSound(spellID)
    if soundPath and soundPath ~= 1 then
        C_UnitAuras.AddPrivateAuraAppliedSound({
            unitToken = "player",
            spellID = spellID,
            soundFileName = 8959,
        --    soundFileName = soundPath,
            outputChannel = "Master",
        })
    end
end

function NSI:InitPA()
    
    if not self.PAFrame then
        self.PAFrame = CreateFrame("Frame", nil, UIParent)
        self.PAFrame:EnableMouse(false)
        self.PAFrame:SetMouseClickEnabled(false)
    end
    self.PAFrame:SetSize(1, 1)
    self.PAFrame:SetPoint(NSRT.PASettings.Anchor, UIParent, NSRT.PASettings.relativeTo, NSRT.PASettings.xOffset, NSRT.PASettings.yOffset)
    
    if not self.AddedPA then self.AddedPA = {} end    

    for i=1, 4 do
        local anchorID = "NSRT_PA"..i
        if self.AddedPA[anchorID] then
            C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
        end    
        if NSRT.PASettings.enabled then
            local privateAnchorArgs = {
                unitToken = "player",
                auraIndex = i,
                parent = self.PAFrame,
                showCountdownFrame = true,
                showCountdownNumbers = true,
                iconInfo = {
                    iconAnchor = {
                        point = "CENTER",
                        relativeTo = self.PAFrame,
                        relativePoint = "CENTER",
                        -- "Grid Formation like it was in Raid-Pack previously"
                        offsetX = (i == 1 or i == 3) and 0 or NSRT.PASettings.Width+1,
                        offsetY = (i == 1 or i == 2) and 0 or -(NSRT.PASettings.Height+1),
                    },
                iconWidth = NSRT.PASettings.Width,
                iconHeight = NSRT.PASettings.Height,
                }
            }        
            self.AddedPA[anchorID] = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
        end
    end
end

function NSI:InitRaidPA() -- still run this function if disabled to clean up old anchors
    if not self.PARaidFrames then self.PARaidFrames = {} end
    if not self.AddedPARaid then self.AddedPARaid = {} end
    for i=1, 40 do       
        local anchorID = "NSRT_PARaid"..i
        if self.AddedPARaid and self.AddedPARaid[anchorID] then
            for _, id in pairs(self.AddedPARaid[anchorID]) do
                C_UnitAuras.RemovePrivateAuraAnchor(anchorID..id)
            end
        end
        local u = "raid"..i
        if NSRT.PARaidSettings.enabled and UnitExists(u) and self.RaidFrames["raid"..i] then 
            if not self.PARaidFrames[i] then
                self.PARaidFrames[i] = CreateFrame("Frame", nil, UIParent)
                self.PARaidFrames[i]:EnableMouse(false)
                self.PARaidFrames[i]:SetMouseClickEnabled(false)
            end
            self.PARaidFrames[i]:SetSize(1, 1)
            self.PARaidFrames[i]:SetPoint(NSRT.PARaidSettings.Anchor, self.RaidFrames["raid"..i], NSRT.PARaidSettings.relativeTo, NSRT.PARaidSettings.xOffset, NSRT.PARaidSettings.yOffset)
            local xDirection = (NSRT.PARaidSettings.Grow == "RIGHT" and 1) or (NSRT.PARaidSettings.Grow == "LEFT" and -1) or 0
            local yDirection = (NSRT.PARaidSettings.Grow == "DOWN" and -1) or (NSRT.PARaidSettings.Grow == "UP" and 1) or 0
            self.AddedPARaid[anchorID] = {}
            for auraIndex = 1, 4 do
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
                            offsetX = 0 + (auraIndex-1) * (NSRT.PARaidSettings.Width+1) * xDirection,
                            offsetY = 0 + (auraIndex-1) * (NSRT.PARaidSettings.Height+1) * yDirection,
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