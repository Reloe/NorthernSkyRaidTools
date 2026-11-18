-- ============================================================
--  Modules.lua - optional addon modules and the AddOns-menu switch
--
--  Owns: the list of optional modules, whether each is enabled in WoW's AddOns list, loading
--  it, and the in-game participation switch. Two separate things:
--    * Loaded: decided only by the AddOns menu. A module that is unticked there is never
--      loaded, so it costs no memory and no CPU. The addon never changes that setting itself.
--    * Active: a quick session-only pause (NSI.Modules:SetActive) used by the options tab and
--      /ns loot on|off. A paused module stays loaded but inert. It is not saved, so it is
--      active again on every login (and reload) when the addon is loaded.
--  Also owns: NSI:LoadKit() (the shared UI kit folder) and the /ns loot command.
-- ============================================================
local _, NSI = ...
NSI = _G.NorthernSkyRaidTools or NSI

NSI.Modules = NSI.Modules or {}
local Modules = NSI.Modules

local KIT = "NorthernSkyRaidTools_Kit"

local registry = {
    LootCouncil = { addon = "NorthernSkyRaidTools_LootCouncil", label = "Loot Council" },
}

local function Guid() return UnitGUID("player") end

function Modules:IsEnabled(key)
    local m = registry[key]
    if not m then return false end
    return C_AddOns.GetAddOnEnableState(m.addon, Guid()) == 2
end

function Modules:IsLoaded(key)
    local m = registry[key]
    return m ~= nil and C_AddOns.IsAddOnLoaded(m.addon)
end

-- Load a module that is enabled in the AddOns list. Returns true when it is loaded.
function Modules:Load(key)
    local m = registry[key]
    if not m or not self:IsEnabled(key) then return false end
    if C_AddOns.IsAddOnLoaded(m.addon) then return true end
    local ok = C_AddOns.LoadAddOn(m.addon)
    return ok and true or false
end

-- Loaded and not paused: the module is taking part.
function Modules:IsActive(key)
    if not self:IsLoaded(key) then return false end
    local mod = NSI[key]
    return not (mod and mod.dead)
end

-- The quick switch. Only pauses or resumes a module that is already loaded; turning the addon itself
-- on or off is done in the game's AddOns list. Returns false when the addon is not loaded.
function Modules:SetActive(key, on)
    local m = registry[key]
    if not m then return false end
    if not self:IsLoaded(key) then
        print(NSI:Loc("|cFF00FFFFNSRT|r Loot Council is not loaded. Enable the addon in the game's AddOns list, then /reload."))
        return false
    end
    local mod = NSI[key]
    if on then
        if mod and mod.Restart then mod.Restart() end
        print(NSI:Loc("|cFF00FFFFNSRT|r Loot Council is on."))
    else
        if mod and mod.Shutdown then mod.Shutdown() end
        print(NSI:Loc("|cFF00FFFFNSRT|r Loot Council is paused: you will not take part until you turn it back on (it turns itself on at every login)."))
    end
    return true
end

-- Shared UI kit, loaded on demand by anything that builds a frame.
function NSI:LoadKit()
    if C_AddOns.IsAddOnLoaded(KIT) then return true end
    local ok, reason = C_AddOns.LoadAddOn(KIT)
    if not ok then print("|cFF00FFFFNSRT|r Could not load " .. KIT .. ": " .. tostring(reason)) end
    return ok and true or false
end

-- Load enabled modules once the character is in the world.
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    for key in pairs(registry) do
        if Modules:IsEnabled(key) then Modules:Load(key) end
    end
end)

-- /ns loot [on|off|end|close|stop|status|test]
function Modules:HandleLootCommand(arg)
    arg = (arg or ""):lower()
    if arg == "on" then self:SetActive("LootCouncil", true) return end
    if arg == "off" then self:SetActive("LootCouncil", false) return end
    if not self:IsEnabled("LootCouncil") then
        print(NSI:Loc("|cFF00FFFFNSRT|r Loot Council is turned off. Enable the addon in the game's AddOns list, then /reload."))
        return
    end
    if not self:Load("LootCouncil") then return end
    local LC = NSI.LootCouncil
    if LC.dead then
        print(NSI:Loc("|cFF00FFFFNSRT|r Loot Council is paused. Turn it on with |cFF00FFFF/ns loot on|r or the switch in the Loot Council options."))
        return
    end
    local preview = arg:match("^preview%s*(.*)$")      -- hidden: look at every window with fake data
    if preview then LC.Preview_.Run(preview) return end
    if arg == "close" or arg == "end" then LC.Session.RequestClose()
    elseif arg == "test" then LC.Sim.Run()
    elseif arg == "stop" then LC.Sim.StopAny()
    elseif arg == "status" then LC.Sim.Status()
    elseif arg == "bags" then LC.Trade.Report()
    elseif arg == "setup" then
        if LC.EnsureKit() then LC.Frames.SetupFrame.Open() end
    elseif arg == "respond" then
        if LC.EnsureKit() then LC.Frames.LootFrame.Reopen() end
    else
        if LC.UI.Open then LC.UI.Open() elseif LC.EnsureUI() and LC.UI.Open then LC.UI.Open() end
    end
end
