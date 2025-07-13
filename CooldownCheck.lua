local _, NSI = ... -- Internal namespace

function NSI:CheckCooldowns()
    local spec = GetSpecializationInfo(GetSpecialization())
    if NSRT.CooldownList and NSRT.CooldownList[spec] then
        local now = GetTime()
        for k, v in pairs(NSRT.CooldownList[spec]) do
            if v.type == "spell" then
                local cooldown = C_Spell.GetSpellCooldown(v.id)
                local timeRemaining = cooldown and cooldown.duration ~= 0 and cooldown.duration + cooldown.startTime - now
                if timeRemaining and timeRemaining > NSRT.Settings["CooldownThreshold"] then
                    if NSRT.Settings["UnreadyOnCooldown"] then ReadyCheckFrameNoButton:Click() end
                    SendChatMessage("My "..v.name.." is on cooldown for "..Round(timeRemaining).." seconds.", "RAID")
                end
            elseif v.type == "item" then
                local startTime, duration = C_Item.GetItemCooldown(v.id)
                local timeRemaining = duration and duration ~= 0 and duration + startTime - now
                if timeRemaining and timeRemaining > NSRT.Settings["CooldownThreshold"] then
                    if NSRT.Settings["UnreadyOnCooldown"] then ReadyCheckFrameNoButton:Click() end
                    SendChatMessage("My "..v.name.." is on cooldown for "..Round(timeRemaining).." seconds.", "RAID")
                end
            end
        end        
    end
end