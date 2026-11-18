-- ============================================================
--  Core/Sim.lua - /ns lc test (PRD 0.8): drive the whole pipeline alone, no group needed.
--  Loopback delivers our own messages back through the receive path.
-- ============================================================
local ADDON, LC = ...
local Sim = {}
LC.Sim = Sim
Sim.loopback = false

function Sim.Deliver(msg)
    local env = LC.Comms.Unpack(msg.text)
    if env then LC.Comms.Deliver(env, LC.Roster.MyKey()) end
end

function Sim.Run()
    if LC.Preview then LC.Print(LC.Loc("The preview is running. Use /ns lc stop first.")) return end
    if Sim.loopback then LC.Print(LC.Loc("A test is already running. /ns lc stop ends it, /ns lc start reopens the setup window.")) return end
    if LC.Session.IsOpen() then LC.Print(LC.Loc("A session is already open.")) return end
    if not LC.EnsureUI() then return end
    LC.BuildFrames()          -- a test is not 'armed', so nothing else has built the windows yet
    Sim.loopback = true
    LC.Ruleset.current = { rs = LC.Ruleset.Build(), hash = "", leader = LC.Roster.MyKey(), active = true }
    LC.Ruleset.current.hash = LC.Ruleset.Hash(LC.Ruleset.current.rs)
    local me = LC.Roster.MyKey()
    LC.Queue.SetOverride(LC.Preview_.FakeQueue(me))
    LC.Print(LC.Loc("Test started: the Session Setup window shows first. /ns lc stop ends the test, /ns lc status shows what is running."))
    LC.Fire("NSRT_LC_SETUP")
end

function Sim.Stop()
    local wasRunning = Sim.loopback
    Sim.loopback = false
    LC.Queue.ClearOverride()
    if LC.Frames.SetupFrame then LC.Frames.SetupFrame.Close() end
    LC.Session.Clear()
    LC.Ruleset.Clear()
    if wasRunning then LC.Print(LC.Loc("Test session stopped.")) end
end

-- What /ns lc stop does: end whichever fake thing is running. Real sessions use /ns lc end.
function Sim.StopAny()
    if LC.Preview then LC.Preview_.Stop() return end
    if Sim.loopback then Sim.Stop() return end
    if LC.Session.IsOpen() then
        LC.Print(LC.Loc("A real session is open. Use /ns lc end to end it."))
    else
        LC.Print(LC.Loc("Nothing to stop."))
    end
end

-- /ns lc status
function Sim.Status()
    local S = LC.Session.state
    local function yn(v) return v and "yes" or "no" end
    LC.Print(string.format("Queue: %d waiting", LC.Queue.Count()))
    LC.Print(LC.Loot.WhyNotML and ("Loot master check: " .. LC.Loot.WhyNotML()) or "")
    LC.Print(string.format("State %s | preview %s | test %s | kit %s | windows %s | ruleset %s",
        LC.State.Name(), yn(LC.Preview), yn(Sim.loopback), yn(C_AddOns.IsAddOnLoaded("NorthernSkyRaidTools_Kit")),
        yn(LC.UI.Loaded), yn(LC.Ruleset.IsActive())))
    if S and S.guid then
        local total, done = 0, 0
        for _, id in ipairs(S.order) do total = total + 1; if S.awards[id] then done = done + 1 end end
        LC.Print(string.format("Session %s: %s, %d of %d awarded, loot master %s", tostring(S.guid), S.closed and "closed" or "open",
            done, total, LC.Roster.Display(S.ml)))
    else
        LC.Print(LC.Loc("No session."))
    end
end
LC.RegisterShutdown("Sim", Sim.Stop)
