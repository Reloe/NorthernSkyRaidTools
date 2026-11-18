-- ============================================================
--  Core/Comms.lua - the only file that sends or receives the module's addon messages (C-2)
--
--  Owns: prefixes NSLC (session traffic) and NSLCB (bulk), the envelope, per-message
--  delivery tracking, the held-while-locked queue, receive validation and chat lines.
--
--  Envelope: { v = protocol, t = type, s = sessionGUID, r = rev, to = target, a = audience, d = payload }
--  encoded CBOR -> Deflate -> URL-safe Base64 (the codec NSRT uses). AceComm splits into
--  255-byte chunks and ChatThrottleLib paces them. ChatThrottleLib v32 re-queues a chunk
--  only on AddonMessageThrottle; any other failure (including AddOnMessageLockdown) discards
--  it and reports didSend = false. So every logical message is tracked until all its chunks
--  report success, and a failure re-queues the WHOLE message (PRD 7.1). Receivers already
--  discard incomplete multi-part messages and every reducer is idempotent, so a resend is
--  applied exactly once.
-- ============================================================
local ADDON, LC = ...
local Comms = {}
LC.Comms = Comms

local type, pairs, ipairs, tostring = type, pairs, ipairs, tostring

Comms.PREFIX = "NSLC"
Comms.PREFIX_BULK = "NSLCB"
local MAX_ATTEMPTS = 5

-- Which prefix carries which type. Everything not listed is session traffic.
local BULK = { HISTORY = true, DETAIL = true, SNAPSHOT = true }

-- Who may send which type. function(senderKey, payload) -> bool
local ALLOWED = {
    RULESET      = function(s) return LC.Roster.IsLeader(s) end,
    HELLO        = function() return true end,
    HELLO_ACK    = function() return true end,
    SESSION_OPEN = function(s) return LC.Ruleset.IsML(s) or LC.Roster.IsLeader(s) end,
    RESPONSE     = function() return true end,
    BONUS        = function() return true end,           -- one bonus roll result from its owner; checked in BonusRoll.Receive
    SNAPSHOT     = function() return true end,           -- own gear at session open; checked in Session.AddSnapshot
    VOTE         = function(s) return LC.Ruleset.IsCouncil(s) end,
    AWARD        = function(s) return LC.Ruleset.IsML(s) end,
    AWARD_UNDO   = function(s) return LC.Ruleset.IsML(s) end,
    AWARD_EDIT   = function(s) return LC.Ruleset.IsML(s) end,
    HOLDER       = function() return true end,           -- the holder reports their own; checked in Loot
    TRADE_DONE   = function() return true end,
    SYNC_REQ     = function() return true end,
    SYNC         = function(s) return LC.Ruleset.IsCouncil(s) or LC.Ruleset.IsML(s) end,
    DETAIL       = function(s) return LC.Ruleset.IsCouncil(s) or LC.Ruleset.IsML(s) end,
    AUTH_CLAIM   = function(s) return LC.Ruleset.IsCouncil(s) end,
    SESSION_CLOSE = function(s) return LC.Ruleset.IsML(s) end,
    HISTORY_REQ  = function() return true end,
    HISTORY      = function(s) return LC.Ruleset.IsCouncil(s) end,
}

local LOG_TYPE = { open = "SESSION_OPEN", holder = "HOLDER", award = "AWARD", undo = "AWARD_UNDO",
    edit = "AWARD_EDIT", authority = "AUTH_CLAIM", close = "SESSION_CLOSE" }
local LOG_FROM_TYPE = {}
for k, v in pairs(LOG_TYPE) do LOG_FROM_TYPE[v] = k end

-- ---- codec (replaceable for tests) -----------------------------
Comms.Codec = {
    encode = function(tbl)
        local serialized = C_EncodingUtil.SerializeCBOR(tbl)
        local compressed = C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate,
            Enum.CompressionLevel.OptimizeForSize)
        return compressed and C_EncodingUtil.EncodeBase64(compressed, Enum.Base64Variant.StandardUrlSafe)
    end,
    decode = function(text)
        local decoded = C_EncodingUtil.DecodeBase64(text, Enum.Base64Variant.StandardUrlSafe)
        local inflated = decoded and C_EncodingUtil.DecompressString(decoded, Enum.CompressionMethod.Deflate)
        return inflated and C_EncodingUtil.DeserializeCBOR(inflated)
    end,
}

-- ---- state -----------------------------------------------------
local handlers = {}          -- type -> fn(payload, senderKey, envelope)
local queue = {}             -- messages waiting for the lock to end (in order)
local nextId = 0
local enabled = false
local versionNoted = {}
local AceComm = LibStub and LibStub("AceComm-3.0", true)
local embedded = {}
if AceComm then AceComm:Embed(embedded) end

Comms.sent, Comms.received, Comms.resent = 0, 0, 0    -- counters for the probe / measurements
Comms.sizes = {}                                       -- type -> last encoded size (work package 0.7)

function Comms.On(msgType, fn) handlers[msgType] = fn end

-- ---- envelope (pure given a codec) ------------------------------
function Comms.Pack(msgType, payload, extra)
    local env = { v = LC.PROTOCOL, t = msgType, d = payload }
    if extra then for k, v in pairs(extra) do env[k] = v end end
    return Comms.Codec.encode(env)
end

function Comms.Unpack(text)
    local ok, env = pcall(Comms.Codec.decode, text)
    if not ok or type(env) ~= "table" or type(env.t) ~= "string" then return nil end
    return env
end

-- ---- send ---------------------------------------------------------
local function IsFailure(result)
    if result == false then return true end
    if type(result) == "number" and Enum and Enum.SendAddonMessageResult then
        return result ~= Enum.SendAddonMessageResult.Success
    end
    return false
end

local function Dispatch(msg)
    local prefix = BULK[msg.t] and Comms.PREFIX_BULK or Comms.PREFIX
    local prio = (msg.prio == "bulk" or BULK[msg.t]) and "BULK" or "NORMAL"
    if LC.Sim and LC.Sim.loopback then
        LC.Sim.Deliver(msg)
        return
    end
    if not embedded.SendCommMessage then return end
    msg.pending = true
    embedded:SendCommMessage(prefix, msg.text, msg.channel, nil, prio, function(_, sent, total, result)
        if msg.done then return end
        if IsFailure(result) then
            msg.done = true
            Comms.Requeue(msg)
        elseif sent and total and sent >= total then
            msg.done = true
            Comms.sent = Comms.sent + 1
        end
    end)
end

function Comms.Requeue(msg)
    msg.attempts = (msg.attempts or 0) + 1
    if msg.attempts > MAX_ATTEMPTS then
        LC.Debug("dropping message after retries", msg.t)
        return
    end
    Comms.resent = Comms.resent + 1
    local m = { t = msg.t, text = msg.text, channel = msg.channel, prio = msg.prio, attempts = msg.attempts, id = msg.id }
    queue[#queue + 1] = m
    LC.Restrict.Hold("comms")
end

-- msgType, payload; channel "RAID" (default) or "PARTY"; target = Name-Realm key or nil.
-- Targeted messages go out on the group channel and are dropped by other receivers (as NSRT does).
function Comms.Send(msgType, payload, channel, target, prio, extra)
    if LC.dead or LC.Preview then return false end
    local env = { to = target }
    if extra then for k, v in pairs(extra) do env[k] = v end end
    local text = Comms.Pack(msgType, payload, env)
    if not text then return false end
    Comms.sizes[msgType] = #text
    nextId = nextId + 1
    local msg = { t = msgType, text = text, channel = channel or (IsInRaid() and "RAID" or "PARTY"),
        prio = prio, attempts = 0, id = nextId }
    if not LC.Restrict.CanSend() then
        queue[#queue + 1] = msg
        LC.Restrict.Hold("comms")
        return true
    end
    Dispatch(msg)
    return true
end

-- ML broadcast of one log event.
function Comms.SendLogEvent(ev)
    local msgType = LOG_TYPE[ev.t]
    if not msgType then return false end
    return Comms.Send(msgType, ev, "RAID")
end

-- Everything queued goes out, in order, once nothing blocks it.
function Comms.Flush()
    if #queue == 0 then
        LC.Restrict.Release("comms")
        return
    end
    if not LC.Restrict.CanSend() then return end
    local list = queue
    queue = {}
    for i = 1, #list do Dispatch(list[i]) end
    if #queue == 0 then LC.Restrict.Release("comms") end
end
LC.Restrict.OnUnlock(Comms.Flush)

function Comms.QueueLength() return #queue end

-- Chat announcement through the same gate. Never touches Blizzard's chat edit box.
function Comms.Chat(text)
    local function Send()
        if not LC.Restrict.CanSend() then return false end
        if C_ChatInfo and C_ChatInfo.SendChatMessage then
            pcall(C_ChatInfo.SendChatMessage, text, IsInRaid() and "RAID" or "PARTY")
        end
        return true
    end
    if not Send() then
        LC.Restrict.Defer("comms.chat." .. text, function() Send() end)
    end
end

-- ---- receive -------------------------------------------------------
local function NoteVersion(senderKey, v)
    if versionNoted[senderKey] then return end
    versionNoted[senderKey] = true
    LC.Print(string.format(LC.Loc("%s is on a different Loot Council version."), LC.Roster.Display(senderKey)))
end

-- Validate and route one decoded envelope from senderKey.
function Comms.Deliver(env, senderKey)
    if type(env) ~= "table" or type(env.t) ~= "string" then return end
    if env.v ~= LC.PROTOCOL then
        if type(env.v) == "number" then NoteVersion(senderKey, env.v) end
        return
    end
    local me = LC.Roster.MyKey()
    if env.to and env.to ~= me then return end
    local allowed = ALLOWED[env.t]
    if not allowed then return end
    local ok, pass = pcall(allowed, senderKey, env.d)
    if not ok or not pass then return end
    if env.a == "c" and not LC.Ruleset.IAmCouncil() then return end
    local handler = handlers[env.t]
    if not handler then return end
    Comms.received = Comms.received + 1
    LC.SafeCall(handler, env.d, senderKey, env)
end

local function OnComm(prefix, text, channel, sender)
    if LC.dead then return end
    if type(text) ~= "string" or LC.Restrict.IsSecret(text) or LC.Restrict.IsSecret(sender) then return end
    local key = LC.Roster.Key(sender)
    if not key or key == LC.Roster.MyKey() then return end
    if not LC.Roster.InGroup(key) then return end
    local env = Comms.Unpack(text)
    if env then Comms.Deliver(env, key) end
end

function Comms.Enable()
    if enabled or not embedded.RegisterComm then return end
    enabled = true
    embedded:RegisterComm(Comms.PREFIX, OnComm)
    embedded:RegisterComm(Comms.PREFIX_BULK, OnComm)
end

function Comms.Disable()
    if not enabled then return end
    enabled = false
    embedded:UnregisterComm(Comms.PREFIX)
    embedded:UnregisterComm(Comms.PREFIX_BULK)
end

function Comms.IsEnabled() return enabled end

function Comms.Shutdown()
    Comms.Disable()
    wipe(queue)
    wipe(versionNoted)
end
LC.RegisterShutdown("Comms", Comms.Shutdown)

-- ---- handlers wired here so the message map stays in one file ----
function Comms.Wire()
    handlers.RULESET = function(d, s) LC.Ruleset.Receive(d, s) end
    handlers.HELLO = function(d, s)
        LC.Comms.Send("HELLO_ACK", { c = LC.Ruleset.IAmCouncil() }, "RAID", s)
        if LC.Roster.IsLeader(LC.Roster.MyKey()) and LC.Ruleset.IsActive() then LC.Ruleset.Broadcast(s) end
    end
    handlers.HELLO_ACK = function(d, s) LC.State.NoteParticipant(s, d) end
    for msgType in pairs(LOG_FROM_TYPE) do
        handlers[msgType] = function(d, s) LC.Session.ReceiveLog(d, s) end
    end
    handlers.RESPONSE = function(d, s) LC.Session.AddResponse(d, s) end
    handlers.SNAPSHOT = function(d, s) LC.Session.AddSnapshot(d, s) end
    handlers.BONUS = function(d, s) LC.BonusRoll.Receive(d, s) end
    handlers.VOTE = function(d, s) LC.Session.AddVote(d, s) end
    -- HOLDER is both an ML log event (has a revision) and a free report from a holder.
    handlers.HOLDER = function(d, s)
        if type(d) == "table" and d.rev then LC.Session.ReceiveLog(d, s) else LC.Loot.ReceiveHolder(d, s) end
    end
    handlers.TRADE_DONE = function(d, s) LC.Trade.ReceiveDone(d, s) end
    handlers.SYNC_REQ = function(d, s) LC.Session.ReceiveSyncRequest(d, s) end
    handlers.SYNC = function(d, s) LC.Session.ReceiveSync(d, s) end
    handlers.DETAIL = function(d, s) LC.Session.ReceiveDetail(d, s) end
    handlers.HISTORY_REQ = function(d, s) LC.History.ReceiveRequest(d, s) end
    handlers.HISTORY = function(d, s) LC.History.ReceiveEntries(d, s) end
end
