local _, NSI = ... -- Internal namespace
local AceComm = LibStub("AceComm-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local allowedcomms = {
    ["NSI_NICKNAMES_COMMS"] = true,
    ["NSI_NICKNAMES_SYNC"] = true,
}

local del = ":"
function NSAPI:Broadcast(event, channel, ...) -- only used for weakauras, everything in the addon uses the internal NSI function instead.
    local message = event
    local argTable = {...}
    local target = ""
    local argCount = #argTable
    -- Always send unitID as second argument after event
    local unitID = UnitInRaid("player") and "raid"..UnitInRaid("player") or UnitName("player")
    message = string.format("%s"..del.."%s(%s)", message, unitID, "string")


    for i = 1, argCount do
        local functionArg = argTable[i]
        local argType = type(functionArg)

        if argType == "table" then
            functionArg = LibSerialize:Serialize(functionArg)
            functionArg = LibDeflate:CompressDeflate(functionArg)
            functionArg = LibDeflate:EncodeForWoWAddonChannel(functionArg)
            message = string.format("%s"..del.."%s(%s)", message, tostring(functionArg), argType)
        else
            if argType ~= "string" and argType ~= "number" and argType ~= "boolean" then
                functionArg = ""
                argType = "string"
            end
            message = string.format("%s"..del.."%s(%s)", message, tostring(functionArg), argType)
        end
    end
    if channel == "WHISPER" then -- create "fake" whisper addon msg that actually just uses RAID instead and will be checked on receive
        AceComm:SendCommMessage("NSWA_MSG2", message, "RAID")
    else
        AceComm:SendCommMessage("NSWA_MSG", message, channel)
    end
end

function NSI:Broadcast(event, channel, ...) -- using internal broadcast function for anything inside the addon to prevent users to send stuff they shouldn't be sending
    local message = event
    local argTable = {...}
    local target = ""

    local argCount = #argTable
    -- Always send unitID as second argument after event
    local unitID = UnitInRaid("player") and "raid"..UnitInRaid("player") or UnitName("player")
    message = string.format("%s"..del.."%s(%s)", message, unitID, "string")


    for i = 1, argCount do
        local functionArg = argTable[i]
        local argType = type(functionArg)

        if argType == "table" then
            functionArg = LibSerialize:Serialize(functionArg)
            functionArg = LibDeflate:CompressDeflate(functionArg)
            functionArg = LibDeflate:EncodeForWoWAddonChannel(functionArg)
            message = string.format("%s"..del.."%s(%s)", message, tostring(functionArg), argType)
        else
            if argType ~= "string" and argType ~= "number" and argType ~= "boolean" then
                functionArg = ""
                argType = "string"
            end
            message = string.format("%s"..del.."%s(%s)", message, tostring(functionArg), argType)
        end
    end
    if channel == "WHISPER" then -- create "fake" whisper addon msg that actually just uses RAID instead and will be checked on receive
        AceComm:SendCommMessage("NSI_WHISPER", message, "RAID")
    else
        AceComm:SendCommMessage("NSI_MSG", message, channel)
    end
end

local function ReceiveComm(text, chan, sender, whisper, internal)
    local argTable = {strsplit(del, text)}
    local event = argTable[1]
    if (UnitExists(sender) and (UnitInRaid(sender) or UnitInParty(sender))) or (chan == "GUILD" and allowedcomms[event]) then -- block addon msg's from outside the raid, only exception being the guild nickname comms. 
        local formattedArgTable = {}
        table.remove(argTable, 1)
        if whisper then
            local target, argType = argTable[2]:match("(.*)%((%a+)%)") -- initially first entry is event, 2nd the unitid of the sender and 3rd the whisper target but we already removed first table entry
            if not (UnitIsUnit("player", target)) then
                return
            end
            table.remove(argTable, 2)
        end

        local tonext
        for i, functionArg in ipairs(argTable) do
            local argValue, argType = functionArg:match("(.*)%((%a+)%)")
            if tonext and argValue then argValue = tonext..argValue end
            if argType == "number" then
                argValue = tonumber(argValue)
                tonext = nil
            elseif argType == "boolean" then
                argValue = argValue == "true" or false
                tonext = nil
            elseif argType == "table" then
                argValue = LibDeflate:DecodeForWoWAddonChannel(argValue)
                argValue = LibDeflate:DecompressDeflate(argValue)
                local success, t = LibSerialize:Deserialize(argValue)
                if success then
                    argValue = t
                else
                    argValue = ""
                end
                tonext = nil
            end
            if (argValue or argValue == false) and argType then
                if argValue == "" then
                    table.insert(formattedArgTable, false)
                else
                    table.insert(formattedArgTable, argValue)
                end
                tonext = nil
            end
            if not argType then
                tonext = tonext or ""
                tonext = tonext..functionArg..del -- if argtype wasn't given then this is part of a table that was falsely split by the delimeter so we're stitching it back together
            end
        end
        NSI:EventHandler(event, false, internal, unpack(formattedArgTable))
        WeakAuras.ScanEvents(event, unpack(formattedArgTable))
    end
end


AceComm:RegisterComm("NSWA_MSG", function(_, text, chan, sender) ReceiveComm(text, chan, sender, false, false) end)
AceComm:RegisterComm("NSWA_MSG2", function(_, text, chan, sender) ReceiveComm(text, chan, sender, true, false) end)
AceComm:RegisterComm("NSI_MSG", function(_, text, chan, sender) ReceiveComm(text, chan, sender, false, true) end)
AceComm:RegisterComm("NSI_WHISPER", function(_, text, chan, sender) ReceiveComm(text, chan, sender, true, true) end)


-- NSAPI:Broadcast("NS_EVENTNAME", channel, targetunitID if whisper, arg1, arg2, arg3)