local _, NSI = ... -- Internal namespace

function NSI:RequestVersionNumber(type, name) -- type == "Addon" or "WA" or "Note"
    if (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or NSRT.Settings["Debug"]) then
        local unit, ver, duplicate, url, ignore = self:GetVersionNumber(type, name, "player")
        self:VersionResponse({name = UnitName("player"), version = "No Response", duplicate = duplicate, ignoreCheck = ignore})
        self:Broadcast("NSI_VERSION_REQUEST", "RAID", type, name)
        for unit in self:IterateGroupMembers() do
            if UnitInRaid(unit) and not UnitIsUnit("player", unit) then
                local index = UnitInRaid(unit) 
                local response = select(8, GetRaidRosterInfo(index)) and "No Response" or "Offline"
                self:VersionResponse({name = UnitName(unit), version = response, duplicate = false, ignoreCheck = false})
            end
        end
        return {name = UnitName("player"), version = ver, duplicate = duplicate, ignoreCheck = ignore}, url
    end
end
function NSI:VersionResponse(data)
    self.NSUI.version_scrollbox:AddData(data)
end


function NSI:GetVersionNumber(type, name, unit)
    local ignoreCheck = false
    for u in self:IterateGroupMembers() do
       if C_FriendList.IsIgnored(u) then
            ignoreCheck = true
            break
       end 
    end
    if type == "Addon" then
        local ver = C_AddOns.GetAddOnMetadata(name, "Version") or "Addon Missing"
        if ver ~= "Addon Missing" then
            ver = C_AddOns.IsAddOnLoaded(name) and ver or "Addon not enabled"
        end
        return unit, ver, false, "", ignoreCheck
    elseif type == "Note" then
        local note = self:GetNote()
        local hashed
        if C_AddOns.IsAddOnLoaded("MRT") then
            hashed = self:GetHash(note) or "Note Missing"
        else
            hashed = C_AddOns.GetAddOnMetadata("MRT", "Version") and "MRT not enabled" or "MRT not installed"
        end
    
        return unit, hashed, false, "", ignoreCheck
    elseif type == "Reminder" then
        local reminder = self.Reminder and self.Reminder ~= "" and self:GetHash(self.Reminder) or "Reminder Missing"
        return unit, reminder, false, "", ignoreCheck
    end
end