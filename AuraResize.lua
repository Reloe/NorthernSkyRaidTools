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
    local directionX = 0
    local directionY = 0
    local space = 0
    local Xoffset = 0
    local Yoffset = 0
    local max = 0
    if anchorData then
        directionX = (anchorData.grow == "RIGHT" and 1) or (anchorData.grow == "LEFT" and -1) or 0
        directionY = (anchorData.grow == "UP" and 1) or (anchorData.grow == "DOWN" and -1) or 0
        space = anchorData.space
        Xoffset = -reg[1].parent.xOffset     
        Yoffset = -reg[1].parent.yOffset
        max = anchorData.limit    

    else  -- use default settings if anchors aren't installed        
        directionX = (type == "Icons" or type == "Big Icons" or type == "Tank Icons" or type == "CoTank Icons") and 1 or 0
        directionY = (type == "Bars" or type == "Texts" or type == "Assignment" or type == "Overview" or type == "Tank Bars" or type == "Big Bars") and 1 or 0
        space = -1
        Xoffset = 0
        Yoffset = 0
        max = 3
    end
    if type ~= "Circle" then
            -- old code that doesn't seem to be neccesary anymore after changing anchors to individual aura instead of the group but keeping it here just in case I ever need it
           --[[ if WeakAuras.IsOptionsOpen() then
                local height = reg[1].region.height
                if reg[1].region.regionType == "text" then
                    height = NSI.AuraSizeData[type] or height
                end
                Xoffset = -reg[1].region.width*directionX
                Yoffset = height*directionY*-1
            end     ]]                           
        max = #reg <= max and #reg or max
        for i =1, max do
            if reg[i].region.state.ignorepos then -- if there are scenarios I don't want a state to be moved, specifically when using Sparks
                pos[i] = {Xoffset, Yoffset}
            else
                local height
                if reg[i].region.regionType == "text" then
                    if not anchorData then
                        height = reg[i].region.height
                    else
                        height = NSI.AuraSizeData[type] and NSI.AuraSizeData[type]+space or reg[i].region.height+space    
                    end           
                else
                    height = reg[i].region.height+space
                end
                local width = reg[i].region.width+space
                pos[i] = {
                    Xoffset-reg[i].data.xOffset,
                    Yoffset-reg[i].data.yOffset,
                }
                Xoffset = Xoffset+((width)*directionX)
                Yoffset = Yoffset+((height)*directionY)
            end
        end
    elseif type == "Circle" then            
        for i, region in ipairs(reg) do
            pos[i] = {0, 0}
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
            region:SetRegionAlpha(auraData.alpha)
            region:SetHideCountdownNumbers(auraData.cooldownTextDisabled)
            for i, subRegion in ipairs(region.subRegions) do       
                if subRegion.type == "subborder" then
                    local data = auraData.subRegions[i]
                    if not data then break end 
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
                elseif subRegion.type == "subtext" then
                    local data = auraData.subRegions[i]
                    if not data then break end 
                    if subRegion.text_text == "%p" then
                        subRegion:SetVisible(data.text_visible)
                    end     
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
            region:SetSparkHeight(auraData.height)
            region.texture = auraData.texture
            region.textureInput = auraData.textureInput
            region.textureSource = auraData.textureSource
            region:UpdateStatusBarTexture()
            region:SetRegionAlpha(auraData.alpha)
            for i, subRegion in ipairs(region.subRegions) do
                if subRegion.type == "subborder" then
                    local data = auraData.subRegions[i]
                    if not data then break end 
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
                elseif subRegion.type == "subtext" then
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
                    subRegion:SetTickPlacement(subRegion.tick_placements[1])        
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
            region:Color(region.color_r, region.color_g, region.color_b, data.color[4])
            
            
        elseif region.regionType == "texture" or region.regionType == "progresstexture" then
            region:SetRegionWidth(auraData.width)
            region:SetRegionHeight(auraData.height)
            region:SetRegionAlpha(auraData.alpha)
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