-- ============================================================
--  Core/State.lua - activation states and the lead prompt (D-13)
--
--  States (PRD 5.3): dormant (module on, not in a raid group), standby (in a raid group, no
--  leader has said yes), armed (the current leader answered yes and their ruleset is applied).
--  "off" is the module not being loaded at all; this file does not exist then.
--  Session and trading are orthogonal and owned by Session.lua and Trade.lua.
--
--  Each state registers only what it needs. Roster bursts are coalesced to one refresh on the
--  next frame. Nothing is built at login: frames are built when the module first arms.
-- ============================================================
local ADDON, LC = ...
local State = {}
LC.State = State

local name = "off"
local scheduled = false
local promptShown = false
local participants = {}
local helloSent = false

function State.Name() return name end
function State.IsArmed() return name == "armed" end

local function SetState(new)
    if new == name then return end
    name = new
    LC.Fire("NSRT_LC_STATE_CHANGED", new)
end

-- ---- scheduling ---------------------------------------------------
function State.Schedule(delay)
    if scheduled or LC.dead then return end
    scheduled = true
    C_Timer.After(delay or 0, function()
        scheduled = false
        if not LC.dead then State.Refresh() end
    end)
end

local BASE_EVENTS = {
    GROUP_ROSTER_UPDATE = function() State.Schedule(0) end,
    PARTY_LEADER_CHANGED = function() State.Schedule(0) end,
    PLAYER_ENTERING_WORLD = function() State.Schedule(1) end,
}

-- ---- lead prompt ----------------------------------------------------
local function Char() return LC.DB.Char() end

function State.LeadAnswer()
    local lead = Char().lead
    return lead and lead.answer
end

function State.Answer(yes)
    local c = Char()
    c.lead = { answer = yes and true or false, at = GetServerTime() }
    promptShown = false
    if yes then LC.Ruleset.Activate() else LC.Ruleset.Deactivate() end
    State.Refresh()
end

-- /ns lc loot and the options tab: change the answer for this raid.
-- Always says what happened, so a click is never silent.
function State.SetForThisRaid(yes)
    if LC.dead then return false end
    if LC.Preview then
        LC.Print(LC.Loc("A preview is running. Stop it first."))
        return false
    end
    if not (IsInRaid() and not LC.Compat.IsLFRGroup()) then
        LC.Print(LC.Loc("You need to be in a raid group to turn the loot council on or off for it."))
        return false
    end
    LC.Roster.Refresh()                                   -- the leader may have changed since the last refresh
    local me = LC.Roster.MyKey()
    if not LC.Roster.IsLeader(me) then
        LC.Print(LC.Loc("Only the raid leader can turn the loot council on or off for a raid."))
        return false
    end
    State.Answer(yes)
    if not yes then
        LC.Print(LC.Loc("Loot council is off for this raid."))
    elseif name == "armed" then
        LC.Print(LC.Loc("Loot council is on for this raid."))
    else
        LC.Print(string.format(LC.Loc("Loot council could not start. The raid leader is %s and you are %s."),
            tostring(LC.Roster.Leader()), tostring(me)))
    end
    return true
end

local function ShowPrompt()
    if promptShown then return end
    promptShown = true
    LC.Restrict.RunOrDefer("lc.leadprompt", function()
        local me = LC.Roster.MyKey()
        if LC.dead or not LC.Roster.IsLeader(me) or State.LeadAnswer() ~= nil then promptShown = false return end
        if not LC.EnsureKit() or not (LC.Frames.LeadPrompt and LC.Frames.LeadPrompt.Show) then promptShown = false return end
        LC.Frames.LeadPrompt.Show(function() State.Answer(true) end, function() State.Answer(false) end)
    end)
end

local function CheckLead(inRaid)
    local me = LC.Roster.MyKey()
    local c = Char()
    if not inRaid or not LC.Roster.IsLeader(me) then
        -- Losing lead or leaving the group clears the answer (PRD 5.3).
        if IsInGroup() and not inRaid then return end
        if c.lead and c.lead.answer ~= nil and IsInGroup() and not LC.Roster.IsLeader(me) then c.lead = {} end
        if not IsInGroup() then c.lead = {} end
        promptShown = false
        return
    end
    local answer = c.lead and c.lead.answer
    if answer ~= nil then
        -- /reload as leader: restore without asking again and without announcing again.
        local cur = LC.Ruleset.current
        if not (cur and cur.leader == me) then
            if answer then LC.Ruleset.Activate(true) else LC.Ruleset.Deactivate() end
        end
        return
    end
    local pref = LC.DB.Settings().onLead
    if pref == "always" then State.Answer(true)
    elseif pref == "never" then State.Answer(false)
    else ShowPrompt() end
end

-- ---- armed -----------------------------------------------------------
local function Arm()
    LC.Events.SetGroup("armed", LC.Loot.Handlers)
    LC.Trade.Enable()
    LC.Events.TryGroup("armed.loothistory", LC.Loot.HistoryHandlers())
    LC.Events.TryGroup("armed.bonusroll", LC.BonusRoll.Handlers())
    -- Build frames once, out of combat, on a later frame (best practices 2.9).
    LC.Restrict.RunOrDefer("lc.buildframes", function()
        if LC.dead or name ~= "armed" then return end
        C_Timer.After(0, function()
            if LC.dead or name ~= "armed" then return end
            LC.BuildFrames()
            if LC.Ruleset.IAmCouncil() then LC.EnsureUI() end
        end)
    end)
end

local function Disarm()
    LC.Events.ClearGroup("trade")
    LC.Events.ClearGroup("armed")
    LC.Events.ClearGroup("armed.loothistory")
    LC.Events.ClearGroup("armed.bonusroll")
end

local function SendHello()
    if helloSent then return end
    helloSent = true
    LC.Comms.Send("HELLO", { v = LC.PROTOCOL }, "RAID")
end

function State.NoteParticipant(key, data)
    participants[key] = { council = data and data.c or false, at = GetServerTime() }
    LC.Fire("NSRT_LC_STATE_CHANGED", name)
end

function State.Participants() return participants end

-- ---- the one refresh ----------------------------------------------------
function State.Refresh()
    if LC.dead or LC.Preview then return end
    LC.Roster.Refresh()
    local inRaid = IsInRaid() and not LC.Compat.IsLFRGroup()
    if not inRaid then
        LC.Comms.Disable()
        helloSent = false
        wipe(participants)
        if not (LC.Session.IsOpen() and IsInGroup()) then LC.Ruleset.Clear() end
        CheckLead(false)
        Disarm()
        SetState("dormant")
        return
    end

    LC.Comms.Enable()
    CheckLead(true)

    -- A ruleset belongs to the current leader. When lead moves, the open session finishes under
    -- its own snapshot; nothing new starts until the new leader answers (PRD 5.3).
    local cur = LC.Ruleset.current
    local leader = LC.Roster.Leader()
    if cur and leader and cur.leader ~= leader then
        if LC.Session.IsOpen() then
            LC.Session.pendingStandDown = true
        else
            LC.Ruleset.Clear()
            cur = nil
        end
    end

    local active = LC.Ruleset.IsActive() and LC.Ruleset.Leader() == leader
    if active or (LC.Session.IsOpen() and LC.Ruleset.IsActive()) then
        if name ~= "armed" then
            SetState("armed")
            Arm()
            LC.Session.CheckAuthority()
            if LC.Session.state == nil then LC.Session.Restore() end
        else
            LC.Session.CheckAuthority()
        end
    else
        if name == "armed" then Disarm() end
        SetState("standby")
        SendHello()
        if not LC.Session.IsOpen() and LC.Ruleset.current and not LC.Ruleset.current.active then
            LC.Fire("NSRT_LC_RULESET_CHANGED", false)
        end
    end
    LC.Trade.Refresh()
end

function State.Start()
    LC.Comms.Wire()
    LC.Events.SetGroup("base", BASE_EVENTS)
    LC.Session.Restore()
    State.Schedule(0)
end

function State.Shutdown()
    LC.Events.ClearGroup("base")
    LC.Events.ClearGroup("armed")
    LC.Events.ClearGroup("armed.loothistory")
    LC.Events.ClearGroup("armed.bonusroll")
    wipe(participants)
    promptShown, scheduled, helloSent = false, false, false
    SetState("off")
end
LC.RegisterShutdown("State", State.Shutdown)
