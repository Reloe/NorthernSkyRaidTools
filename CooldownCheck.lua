local _, NSI = ... -- Internal namespace

function NSI:CheckCooldowns()
    local spec = GetSpecializationInfo(GetSpecialization())
    if NSRT.CooldownList and NSRT.CooldownList[spec] then
        local now = GetTime()
        if NSRT.CooldownList[spec]["spell"] then
            for k, v in pairs(NSRT.CooldownList[spec]["spell"]) do
                local cooldown = C_Spell.GetSpellCooldown(k)
                local timeRemaining = cooldown and cooldown.duration ~= 0 and cooldown.duration + cooldown.startTime - now
                if timeRemaining and timeRemaining+v.offset > NSRT.Settings["CooldownThreshold"] then
                    if NSRT.Settings["UnreadyOnCooldown"] then ReadyCheckFrameNoButton:Click() end
                    SendChatMessage("My "..v.name.." is on cooldown for "..Round(timeRemaining).." seconds.", "RAID")
                end
            end
        end
        if NSRT.CooldownList[spec]["item"] then    
            for k, v in pairs(NSRT.CooldownList[spec]["item"]) do
                local startTime, duration = C_Item.GetItemCooldown(k)
                local timeRemaining = duration and duration ~= 0 and duration + startTime - now
                if timeRemaining and timeRemaining+v.offset > NSRT.Settings["CooldownThreshold"] then
                    if NSRT.Settings["UnreadyOnCooldown"] then ReadyCheckFrameNoButton:Click() end
                    SendChatMessage("My "..v.name.." is on cooldown for "..Round(timeRemaining).." seconds.", "RAID")
                end
            end
        end        
    end
end

function NSI:AddTrackedCooldown(spec, id, type, offset)
    NSRT.CooldownList[spec] = NSRT.CooldownList[spec] or {}
    NSRT.CooldownList[spec][type] = NSRT.CooldownList[spec][type] or {}
    NSRT.CooldownList[spec][type][id] = {offset = offset, name = (type == "spell" and C_Spell.GetSpellName(id)) or C_Item.GetItemName(id) or ""}
end


function NSI:RemoveTrackedCooldown(spec, id, type)
    if NSRT.CooldownList[spec] and NSRT.CooldownList[spec][type] and NSRT.CooldownList[spec][type][id] then
        NSRT.CooldownList[spec][type][id] = nil
    end
end