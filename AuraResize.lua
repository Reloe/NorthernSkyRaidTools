local _, NSI = ... -- Internal namespace
NSI.groupData = {}
NSI.auraData = {}
NSI.AuraSizeData = {}
local SharedMedia = LibStub("LibSharedMedia-3.0")
NSI.auranames = {
    ["Icons"] = "NS Icon Anchor",  
    ["Bars"] = "NS Bar Anchor",  
    ["Overview"] = "NS Overview Anchor",  
    ["Tank Icons"] = "NS Tank Debuff Anchor",
    ["CoTank Icons"] = "NS CoTank Debuff Anchor",
    ["Texts"] = "NS Text Anchor",  
    ["TankTexts"] = "NS Tank Text Anchor",
    ["Assignment"] = "NS Assignment Anchor",  
    ["Circle"] = "NS Circle Anchor",  
    ["Big Icons"] = "NS Big Icon Anchor",  
    ["Big Bars"] = "NS Big Bar Anchor",
    ["Tank Bars"] = "NS Tank Bar Anchor",
}

function NSAPI:AnchorSettings(type) -- call this when someone edits anchors to fix options preview    
    local auraname = NSI.auranames[type]
    local groupname = auraname.." Group"
    local groupData = WeakAuras.GetData(groupname)
    local auraData = WeakAuras.GetData(auraname)
    NSI.groupData[groupname] = groupData
    NSI.auraData[auraname] = auraData
end


function NSAPI:AuraPosition(type, pos, reg) 
    local auraname = NSI.auranames[type].." Group"
    local anchorData = NSI.groupData[auraname] or WeakAuras.GetData(auraname)
    if anchorData then
        if type ~= "Circle" then
            local directionX = (anchorData.grow == "RIGHT" and 1) or (anchorData.grow == "LEFT" and -1) or 0
            local directionY = (anchorData.grow == "UP" and 1) or (anchorData.grow == "DOWN" and -1) or 0
            local space = anchorData.space
            local Xoffset = 0
            local Yoffset = 0
            -- old code that doesn't seem to be neccesary anymore after changing anchors to individual aura instead of the group but keeping it here just in case
           --[[ if WeakAuras.IsOptionsOpen() then
                local height = reg[1].region.height
                if reg[1].region.regionType == "text" then
                    height = NSI.AuraSizeData[type] or height
                end
                Xoffset = -reg[1].region.width*directionX
                Yoffset = height*directionY*-1
            end     ]]                   
            local max = anchorData.limit            
            max = #reg <= max and #reg or max
            for i =1, max do
                local height
                if reg[i].region.regionType == "text" then
                    height = NSI.AuraSizeData[type]+space or reg[i].region.height+space                    
                else
                    height = reg[i].region.height+space
                end
                local width = reg[i].region.width+space
                pos[i] = {
                    Xoffset,
                    Yoffset,
                }
                Xoffset = Xoffset+((width)*directionX)
                Yoffset = Yoffset+((height)*directionY)
            end
        elseif type == "Circle" then            
            for i, region in ipairs(reg) do
                pos[i] = {0, 0}
            end          
        end
    end
    return pos
end


function NSAPI:AuraResize(type, positions, regions)
    local auraname = NSI.auranames[type]
    local groupname = auraname.." Group"
    local groupData = NSI.groupData[groupname] or WeakAuras.GetData(groupname)
    local auraData = NSI.auraData[auraname] or WeakAuras.GetData(auraname)
    NSI.groupData[groupname] = groupData
    NSI.auraData[auraname] = auraData
    if not auraData then return end
    for _, regionData in ipairs(regions) do   
        local region = regionData.region
        if region.regionType == "icon"  then     
            region:SetRegionWidth(auraData.width)
            region:SetRegionHeight(auraData.height)
            region:SetZoom(auraData.zoom)
            for i, subRegion in ipairs(region.subRegions) do       
                if subRegion.type == "subborder" then
                    local data = auraData.subRegions[i]
                    if data.type == "subborder" then
                        local backdrop = subRegion:GetBackdrop()
                        local colors = data.border_color
                        if backdrop then
                            backdrop.edgeSize = data.border_size
                            -- local offset = data.border_offset
                            subRegion:SetBackdrop(backdrop)
                        end
                        if colors then
                            subRegion:SetBorderColor(unpack(colors))
                        end
                        subRegion:SetVisible(data.border_visible)
                    end
                end
                if subRegion.type == "subtext" then
                    local data = auraData.subRegions[i]
                    if not data then break end 
                    if data.type == "subtext" then
                        subRegion:SetXOffset(data.text_anchorXOffset)
                        subRegion:SetYOffset(data.text_anchorYOffset)
                        subRegion.text:SetFont(SharedMedia:Fetch("font", data.text_font), data.text_fontSize, data.text_fontType)
                        subRegion.text:SetShadowColor(unpack(data.text_shadowColor))
                        subRegion.text:SetShadowOffset(data.text_shadowXOffset, data.text_shadowYOffset)
                    end
                end
            end
            
        elseif region.regionType == "aurabar" then
            region:SetRegionWidth(auraData.width)
            region:SetRegionHeight(auraData.height)
            region.texture = auraData.texture
            region.textureInput = auraData.textureInput
            region.textureSource = auraData.textureSource
            region:UpdateStatusBarTexture()
            for i, subRegion in ipairs(region.subRegions) do
                if subRegion.type == "subborder" then
                    local data = auraData.subRegions[i]
                    if data.type == "subborder" then
                        local backdrop = subRegion:GetBackdrop()
                        local colors = data.border_color
                        if backdrop then
                            backdrop.edgeSize = data.border_size
                            -- local offset = data.border_offset
                            subRegion:SetBackdrop(backdrop)
                        end
                        if colors then
                            subRegion:SetBorderColor(unpack(colors))
                        end
                        subRegion:SetVisible(data.border_visible)
                    end
                end
                if subRegion.type == "subtext" then
                    local data = auraData.subRegions[i]
                    if not data then break end
                    if data.type == "subtext" then
                        subRegion:SetXOffset(data.text_anchorXOffset)
                        subRegion:SetYOffset(data.text_anchorYOffset)
                        subRegion.text:SetFont(SharedMedia:Fetch("font", data.text_font), data.text_fontSize, data.text_fontType)
                        subRegion.text:SetShadowColor(unpack(data.text_shadowColor))
                        subRegion.text:SetShadowOffset(data.text_shadowXOffset, data.text_shadowYOffset)
                    end
                elseif subRegion.type == "subtick" then
                    subRegion:SetAutomaticLength(false)
                    subRegion:SetTickLength(auraData.height)
                end
            end
            
        elseif region.regionType == "text" then
            local data = auraData
            region.text:SetFont(SharedMedia:Fetch("font", data.font), data.fontSize, data.outline)
            region.text:SetShadowColor(unpack(data.shadowColor))
            region.text:SetShadowOffset(data.shadowXOffset, data.shadowYOffset)            
            NSI.AuraSizeData[type] = data.fontSize -- somehow even when setting the height it doesn't update to that value so I'm storing it here instead
            region:SetHeight(data.fontSize)
            region:SetWidth(region.text:GetWidth())
            
            
        elseif region.regionType == "texture" or region.regionType == "progresstexture" then
            region:SetRegionWidth(auraData.width)
            region:SetRegionHeight(auraData.height)
            for i, subRegion in ipairs(region.subRegions) do
                if subRegion.type == "subtext" then
                    local data = auraData.subRegions[i]
                    if not data then break end 
                    if data.type == "subtext" then
                        subRegion:SetXOffset(data.text_anchorXOffset)
                        subRegion:SetYOffset(data.text_anchorYOffset)
                        subRegion.text:SetFont(SharedMedia:Fetch("font", data.text_font), data.text_fontSize, data.text_fontType)
                        subRegion.text:SetShadowColor(unpack(data.text_shadowColor))
                        subRegion.text:SetShadowOffset(data.text_shadowXOffset, data.text_shadowYOffset)
                    end
                end
            end
        end
    end    
end