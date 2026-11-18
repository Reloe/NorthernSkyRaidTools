-- ============================================================
--  Core/Restrict.lua - "may we send", "is this usable", keyed deferral
--
--  Owns: the one gate in front of every addon message and chat line, the secret-value
--  guard, and the keyed deferral queue (PRD 5.5). Together with Comms.lua this is the
--  only file that knows the restriction rules (C-2).
--
--  Three separate state machines, never used as proxies for each other:
--    combat lockdown  InCombatLockdown()                  PLAYER_REGEN_ENABLED
--    addon restriction  NSI:Restricted()                  ADDON_RESTRICTION_STATE_CHANGED
--    chat lockdown    C_ChatInfo.InChatMessagingLockdown  ADDON_RESTRICTION_STATE_CHANGED (Chat), ENCOUNTER_END
--
--  The event frame registers its events only while something waits (a deferred function
--  or a queued message), so an idle module has no cost here.
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Restrict = {}
LC.Restrict = Restrict

local frame = CreateFrame("Frame")
local pending, order = {}, {}       -- key -> fn, and keys in arrival order
local holds = {}                    -- owner -> true: others that need the unlock events (Comms queue)
local listeners = {}                -- called when a lockdown ends

Restrict.simChat = false            -- simulation: pretend chat is locked down

function Restrict.IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

-- Chat lockdown, from the client. A secret or errored answer means "unknown": we say locked.
function Restrict.ChatLocked()
    if Restrict.simChat then return true end
    if not (C_ChatInfo and C_ChatInfo.InChatMessagingLockdown) then return false end
    local ok, locked = pcall(C_ChatInfo.InChatMessagingLockdown)
    if not ok or Restrict.IsSecret(locked) then return true end
    return locked and true or false
end

-- The single send gate.
function Restrict.CanSend()
    if Restrict.ChatLocked() then return false end
    if IsEncounterInProgress and IsEncounterInProgress() then return false end
    return true
end

local function NeedEvents()
    return next(pending) ~= nil or next(holds) ~= nil
end

local function Sync()
    if NeedEvents() then
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("ENCOUNTER_END")
        pcall(frame.RegisterEvent, frame, "ADDON_RESTRICTION_STATE_CHANGED")
    else
        frame:UnregisterAllEvents()
    end
end

-- Another module (Comms) needs the unlock signals while it has a queue.
function Restrict.Hold(owner) holds[owner] = true; Sync() end
function Restrict.Release(owner) holds[owner] = nil; Sync() end
function Restrict.OnUnlock(fn) listeners[#listeners + 1] = fn end

-- Run fn once when work is allowed again. A pending key keeps its place and takes the
-- new fn. The fn must re-read live state: it may have changed while waiting.
function Restrict.Defer(key, fn)
    if pending[key] == nil then order[#order + 1] = key end
    pending[key] = fn
    Sync()
end

function Restrict.Cancel(key)
    if pending[key] ~= nil then
        pending[key] = nil
        for i = #order, 1, -1 do if order[i] == key then table.remove(order, i) end end
        Sync()
    end
end

-- Run now when combat and encounter allow it, otherwise defer under the key.
function Restrict.RunOrDefer(key, fn)
    if InCombatLockdown() or (IsEncounterInProgress and IsEncounterInProgress()) then
        Restrict.Defer(key, fn)
    else
        fn()
    end
end

local function Flush()
    if InCombatLockdown() then return end
    if IsEncounterInProgress and IsEncounterInProgress() then return end
    local keys, fns = order, pending
    order, pending = {}, {}
    for i = 1, #keys do LC.SafeCall(fns[keys[i]]) end
    Sync()
end

frame:SetScript("OnEvent", function(_, event)
    -- Events are hints (PRD 5.5 rule 4): flush what we can and let each fn re-validate.
    Flush()
    if Restrict.CanSend() then
        for i = 1, #listeners do LC.SafeCall(listeners[i]) end
    end
end)

function Restrict.Shutdown()
    wipe(pending)
    wipe(order)
    wipe(holds)
    wipe(listeners)
    frame:UnregisterAllEvents()
end
LC.RegisterShutdown("Restrict", Restrict.Shutdown)
