-- ============================================================
--  Core/Init.lua - Loot Council module table, lifecycle, shared helpers
--
--  Owns: the module table (shared through the addon's private table and
--  published as NSI.LootCouncil), Shutdown(), callbacks, localisation and
--  print helpers, and the boot frame that starts the module once its saved
--  data exists. Loads first.
--
--  Layering: Core/ never calls into Frames/ or the UI folder. It fires
--  callbacks on NSRT's CallbackHandler; frames listen (PRD 5.2).
-- ============================================================
local ADDON, LC = ...
local NSI = _G.NorthernSkyRaidTools

LC.NSI = NSI
LC.name = ADDON
LC.PROTOCOL = 1            -- bump on a breaking comm change; additive changes stay within a major version
LC.Frames = LC.Frames or {}
LC.UI = LC.UI or {}
LC.dead = false            -- true after Shutdown(): code is loaded but inert
LC.started = false

if NSI then NSI.LootCouncil = LC end

local xpcall, geterrorhandler, type, tostring = xpcall, geterrorhandler, type, tostring
local function OnError(err) return geterrorhandler()(err) end

-- Error isolation: one failing handler must not break its caller.
function LC.SafeCall(fn, ...)
    if type(fn) == "function" then return xpcall(fn, OnError, ...) end
end

-- English text is the key (agent guide 10).
function LC.Loc(key)
    if NSI and NSI.Loc then return NSI:Loc(key) end
    return key
end

function LC.Print(msg)
    print("|cFF00FFFFNSRT|r " .. tostring(msg))
end

function LC.Debug(...)
    if NSRT and NSRT.Settings and NSRT.Settings.Debug then
        print("|cFF00FFFFNSLC|r", ...)
    end
end

-- Internal listeners: frames subscribe here; the same events also go out on NSRT's callbacks.
local listeners = {}
function LC.On(event, fn)
    local l = listeners[event]
    if not l then l = {}; listeners[event] = l end
    l[#l + 1] = fn
end

function LC.Fire(event, ...)
    local l = listeners[event]
    if l then for i = 1, #l do LC.SafeCall(l[i], ...) end end
    if NSI and NSI.FireCallback then NSI:FireCallback(event, ...) end
end

-- Modules with a Shutdown() are registered here, in the order they should stop.
local shutdownList = {}
function LC.RegisterShutdown(name, fn) shutdownList[#shutdownList + 1] = { name = name, fn = fn } end

-- Free everything that can be freed. Code stays in memory (a client limit); from now on
-- the module registers no events, no comm prefixes, runs no timers and shows nothing.
function LC.Shutdown()
    if LC.dead then return end
    LC.dead = true
    for i = #shutdownList, 1, -1 do
        LC.SafeCall(shutdownList[i].fn)
    end
    LC.Fire("NSRT_LC_STATE_CHANGED", "off")
end

-- Bring a shut-down module back (switch turned on again in the same session).
function LC.Restart()
    if not LC.dead then return end
    LC.dead = false
    if LC.started and LC.State then LC.State.Start() end
end

-- The kit is needed only once a frame is about to be built.
function LC.EnsureKit()
    if NSI and NSI.LoadKit then return NSI:LoadKit() end
end

-- Council clients and the options tab need the heavier UI folder. Says why when it cannot load.
function LC.EnsureUI()
    if LC.UI.Loaded then return true end
    if not LC.EnsureKit() then
        LC.Print(LC.Loc("The shared UI kit (NorthernSkyRaidTools_Kit) could not be loaded. Check that the folder is in your AddOns directory and enabled."))
        return false
    end
    local ok, reason = C_AddOns.LoadAddOn("NorthernSkyRaidTools_LootCouncil_UI")
    if not ok then
        LC.Print(string.format(LC.Loc("The Loot Council windows could not be loaded (%s). Check that NorthernSkyRaidTools_LootCouncil_UI is in your AddOns directory and enabled, then /reload."), tostring(reason)))
        return false
    end
    if not LC.UI.Loaded then
        LC.Print(LC.Loc("The Loot Council windows loaded with errors. Please send the Lua error text."))
        return false
    end
    return true
end

-- Build every window once (each Build is a no-op after the first). Needs the kit; says nothing if it is missing.
function LC.BuildFrames()
    if not LC.EnsureKit() then return false end
    for _, frame in pairs(LC.Frames) do
        if type(frame) == "table" and frame.Build then LC.SafeCall(frame.Build) end
    end
    return true
end

-- Saved data exists from ADDON_LOADED for this addon: start the module then.
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    LC.SafeCall(LC.DB.Init)
    LC.started = true
    LC.SafeCall(LC.State.Start)
end)
