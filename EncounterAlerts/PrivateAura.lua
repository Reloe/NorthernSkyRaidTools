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