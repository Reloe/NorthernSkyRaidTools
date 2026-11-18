-- ============================================================
--  Core/Events.lua - grouped event registration
--
--  Owns: the module's one event frame (created here, at file scope, so its CPU is
--  billed to this addon) and a direct dispatch table. Handlers are registered in
--  named groups, one group per activation state, so leaving a state unregisters
--  exactly what it added (PRD 5.3). Unknown events are tolerated: an event name the
--  client does not know would raise an error, so unverified ones go through TryGroup.
-- ============================================================
local ADDON, LC = ...
local Events = {}
LC.Events = Events

local frame = CreateFrame("Frame")
local byEvent = {}      -- event -> { {group, fn}, ... }
local groups = {}       -- group -> { event = true }

local function Dispatch(_, event, ...)
    local list = byEvent[event]
    if not list then return end
    for i = 1, #list do
        local entry = list[i]
        LC.SafeCall(entry.fn, event, ...)
    end
end
frame:SetScript("OnEvent", Dispatch)

local function AddHandler(group, event, fn, unit)
    local list = byEvent[event]
    if not list then list = {}; byEvent[event] = list end
    list[#list + 1] = { group = group, fn = fn }
    groups[group] = groups[group] or {}
    groups[group][event] = true
    if #list == 1 then
        if unit then frame:RegisterUnitEvent(event, unit) else frame:RegisterEvent(event) end
    end
end

-- handlers: { EVENT_NAME = function(event, ...) }. Replaces the group's previous registration.
function Events.SetGroup(group, handlers)
    Events.ClearGroup(group)
    for event, fn in pairs(handlers) do AddHandler(group, event, fn) end
end

-- Same, but an event the client rejects is skipped (and reported through LC.Debug).
function Events.TryGroup(group, handlers)
    Events.ClearGroup(group)
    for event, fn in pairs(handlers) do
        local ok = pcall(AddHandler, group, event, fn)
        if not ok then
            LC.Debug("event not available:", event)
            groups[group][event] = nil
            local list = byEvent[event]
            if list then
                for i = #list, 1, -1 do if list[i].group == group then table.remove(list, i) end end
                if #list == 0 then byEvent[event] = nil end
            end
        end
    end
end

function Events.ClearGroup(group)
    local registered = groups[group]
    if not registered then return end
    for event in pairs(registered) do
        local list = byEvent[event]
        if list then
            for i = #list, 1, -1 do
                if list[i].group == group then table.remove(list, i) end
            end
            if #list == 0 then
                byEvent[event] = nil
                frame:UnregisterEvent(event)
            end
        end
    end
    groups[group] = nil
end

function Events.HasGroup(group) return groups[group] ~= nil end

function Events.ClearAll()
    for group in pairs(groups) do Events.ClearGroup(group) end
    frame:UnregisterAllEvents()
end

function Events.Count()
    local n = 0
    for _ in pairs(byEvent) do n = n + 1 end
    return n
end

LC.RegisterShutdown("Events", Events.ClearAll)
