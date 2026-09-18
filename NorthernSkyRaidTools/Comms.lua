local _, NSI = ... -- Internal namespace
local AceComm = LibStub("AceComm-3.0")
local allowedcomms = {
    ["NSI_NICKNAMES_COMMS"] = true,
}

function NSI:Broadcast(event, channel, ...) -- using internal broadcast function for anything inside the addon to prevent users to send stuff they shouldn't be sending
    local argTable = {n = select("#", ...), ...}
    local unitID = UnitInRaid("player") and "raid"..UnitInRaid("player") or UnitName("player")
    for index = argTable.n, 1, -1 do
        argTable[index + 1] = argTable[index]
    end
    argTable[1] = unitID
    argTable.n = argTable.n + 1
    local serialized = C_EncodingUtil.SerializeCBOR({event = event, args = argTable})
    local compressed = C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.OptimizeForSize)
    local message = C_EncodingUtil.EncodeBase64(compressed, Enum.Base64Variant.StandardUrlSafe)
    if channel == "WHISPER" then -- create "fake" whisper addon msg that actually just uses RAID instead and will be checked on receive
        AceComm:SendCommMessage("NSI_WHISPER", message, "RAID")
    else
        AceComm:SendCommMessage("NSI_MSG", message, channel)
    end
end

local function ReceiveComm(text, chan, sender, whisper, internal)
    local decoded = C_EncodingUtil.DecodeBase64(text, Enum.Base64Variant.StandardUrlSafe)
    local decompressed = decoded and C_EncodingUtil.DecompressString(decoded, Enum.CompressionMethod.Deflate)
    local payload = decompressed and C_EncodingUtil.DeserializeCBOR(decompressed)
    if type(payload) ~= "table" or type(payload.event) ~= "string" or type(payload.args) ~= "table" then return end

    local event = payload.event
    if (UnitExists(sender) and (UnitInRaid(sender) or UnitInParty(sender))) or (chan == "GUILD" and allowedcomms[event]) then -- block addon msg's from outside the raid, only exception being the guild nickname comms.
        local argTable = payload.args
        if type(argTable.n) ~= "number" or argTable.n < 1 or argTable.n > 16 or argTable.n ~= math.floor(argTable.n) then return end
        if whisper then
            local target = argTable[2]
            if type(target) ~= "string" or not UnitIsUnit("player", target) then
                return
            end
            for index = 2, argTable.n - 1 do
                argTable[index] = argTable[index + 1]
            end
            argTable[argTable.n] = nil
            argTable.n = argTable.n - 1
        end
        NSI:EventHandler(event, false, internal, unpack(argTable, 1, argTable.n))
        if WeakAuras then WeakAuras.ScanEvents(event, unpack(argTable, 1, argTable.n)) end
    end
end
AceComm:RegisterComm("NSI_MSG", function(_, text, chan, sender) ReceiveComm(text, chan, sender, false, true) end)
AceComm:RegisterComm("NSI_WHISPER", function(_, text, chan, sender) ReceiveComm(text, chan, sender, true, true) end)
