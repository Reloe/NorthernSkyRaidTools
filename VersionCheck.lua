local _, NSI = ... -- Internal namespace

function NSI:RequestVersionNumber(type, name) -- type == "Addon" or "WA" or "Note"
    if (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        local unit, ver, duplicate, url = NSI:GetVersionNumber(type, name, unit)
        NSI:VersionResponse({name = UnitName("player"), version = "No Response", duplicate = false})
        NSI:Broadcast("NSI_VERSION_REQUEST", "RAID", type, name)
        for unit in NSI:IterateGroupMembers() do
            if UnitInRaid(unit) and not UnitIsUnit("player", unit) then
                local index = UnitInRaid(unit) 
                local response = select(8, GetRaidRosterInfo(index)) and "No Reponse" or "Offline"
                NSI:VersionResponse({name = UnitName(unit), version = response, duplicate = false})
            end
        end
        return {name = UnitName("player"), version = ver, duplicate = duplicate}, url
    end
end
function NSI:VersionResponse(data)
    NSI.NSUI.version_scrollbox:AddData(data)
end


function NSI:GetVersionNumber(type, name, unit)    
    if type == "Addon" then
        local ver = C_AddOns.GetAddOnMetadata(name, "Version") or "Addon Missing"
        if ver ~= "Addon Missing" then
            ver = C_AddOns.IsAddOnLoaded(name) and ver or "Addon not enabled"
        end
        return unit, ver, false, ""
    elseif type == "WA" then
        local waData = WeakAuras.GetData(name)
        local ver = "WA Missing"
        local url = ""
        local found = false
        if waData then
            ver = 0
            if waData["url"] then
                url = waData["url"]
                ver = tonumber(waData["url"]:match('.*/(%d+)$'))
            end
            found = true
        end
        local duplicate = false
        for i=2, 10 do -- check for duplicates of the Weakaura
            waData = WeakAuras.GetData(name.." "..i)
            if waData then
                local dupver = 0
                if waData["url"] then
                    url = waData["url"]
                    dupver = tonumber(waData["url"]:match('.*/(%d+)$'))
                end
                if ver == "WA Missing" or dupver > ver then
                    ver = dupver -- if the first one is missing, use the duplicate's version
                end
                duplicate = found -- by doing this duplicate is only set if the user actually has 2 Auras of this and not just when any aura with a number at the end is found
                found = true
                if duplicate then break end
            end
        end
        return unit, ver, duplicate, url
    elseif type == "Note" then
        local note = NSAPI:GetNote()
        local hashed
        if C_AddOns.IsAddOnLoaded("MRT") then
            hashed = NSAPI:GetHash(note) or "Note Missing"
        else
            hashed = C_AddOns.GetAddOnMetadata("MRT", "Version") and "MRT not enabled" or "MRT not installed"
        end
    
        return unit, hashed, false, ""
    end
end