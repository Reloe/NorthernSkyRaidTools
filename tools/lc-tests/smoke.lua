-- Smoke harness: loads the whole logic folder against a universal stub of the WoW API and drives the
-- slash-command paths. It cannot prove the UI looks right, but it catches nil globals and call errors.
unpack = unpack or table.unpack
local Dummy = {}
Dummy.__index = function(t, k) return Dummy.obj end
Dummy.__call = function() return Dummy.obj end
Dummy.__add = function() return 0 end; Dummy.__sub = Dummy.__add; Dummy.__mul = Dummy.__add; Dummy.__div = Dummy.__add
Dummy.__concat = function(a, b) return "x" end
Dummy.obj = setmetatable({}, Dummy)
Dummy.fn = function() return Dummy.obj end
local D = Dummy.obj
local function stub(...) return D end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
tinsert, tremove = table.insert, table.remove
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
date = os.date
_G.UIParent = D; _G.GameTooltip = D; _G.UISpecialFrames = {}
CreateFrame = function() return D end
C_Timer = { After = function(_, f) end, NewTimer = function() return { Cancel = function() end } end, NewTicker = function() return { Cancel = function() end } end }
GetServerTime = function() return os.time() end
GetTime = function() return os.clock() end
UnitName = function() return "Tester" end
GetNormalizedRealmName = function() return "Realm" end
GetRealmName = function() return "Realm" end
UnitGUID = function() return "Player-1-ABCDEF" end
IsInRaid = function() return false end
IsInGroup = function() return false end
IsInGuild = function() return false end
GetNumGroupMembers = function() return 0 end
UnitIsGroupLeader = function() return false end
UnitIsGroupAssistant = function() return false end
UnitExists = function() return false end
UnitIsConnected = function() return true end
UnitIsInMyGuild = function() return false end
InCombatLockdown = function() return false end
geterrorhandler = function() return function(e) print("ERROR HANDLER:", e) end end
issecretvalue = function() return false end
C_ChatInfo = { InChatMessagingLockdown = function() return false end }
C_Item = { GetItemInfoInstant = function(id) return id, nil, nil, "INVTYPE_TRINKET" end, GetItemNameByID = function() return "Item" end,
    GetItemInfo = function() return "Item", "|cff0070dd|Hitem:1|h[Item]|h|r" end, GetDetailedItemLevelInfo = function() return 250 end }
GetInventoryItemLink = function() return nil end
Enum = { SendAddonMessageResult = { Success = 0 }, CompressionMethod = { Deflate = 1 }, CompressionLevel = { OptimizeForSize = 1 }, Base64Variant = { StandardUrlSafe = 1 } }
C_EncodingUtil = { SerializeCBOR = function(t) return t end, CompressString = function(s) return s end, EncodeBase64 = function(s) return s end,
    DecodeBase64 = function(s) return s end, DecompressString = function(s) return s end, DeserializeCBOR = function(s) return s end }
LibStub = function() return nil end

local loaded = {}
C_AddOns = { IsAddOnLoaded = function(n) return loaded[n] or false end, LoadAddOn = function(n) loaded[n] = true return true end,
    GetAddOnEnableState = function() return 2 end, EnableAddOn = stub, DisableAddOn = stub, SaveAddOns = stub }
local NSI = { Loc = function(_, k) return k end, FireCallback = function() end, LoadKit = function() return true end, SetUIFont = stub,
    UI = { Components = setmetatable({ STYLE = { Accent = function() return 0, 1, 1, 1 end, text_color = { 1, 1, 1, 1 } } }, { __index = function() return function() return D end end }), Window = D, Style = D, Pixel = D, Tooltip = D },
    Modules = {} }
_G.NorthernSkyRaidTools = NSI
NSRT = { Settings = {} }
NSAPI = nil
local LC
local function loadfolder(dir, tocfile, ...)
    for line in io.lines(dir .. "/" .. tocfile) do
        line = line:gsub("\r", "")
        if line ~= "" and not line:match("^#") then
            local path = dir .. "/" .. line:gsub("\\", "/")
            local fn, err = loadfile(path)
            if not fn then error(err) end
            local ok, e = xpcall(function() fn("NorthernSkyRaidTools_LootCouncil", LC) end, debug.traceback)
            if not ok then print("LOAD ERROR in " .. path .. "\n" .. e) end
        end
    end
end
LC = {}
loadfolder("NorthernSkyRaidTools_LootCouncil", "NorthernSkyRaidTools_LootCouncil.toc")
LC = NSI.LootCouncil
assert(LC, "LC not published")

local function try(name, f)
    local ok, e = xpcall(f, debug.traceback)
    print((ok and "ok    " or "FAIL  ") .. name .. (ok and "" or ("\n" .. e)))
end
try("DB.Init", LC.DB.Init)
try("State.Start", LC.State.Start)
LC.UI.Loaded = false
loaded.NorthernSkyRaidTools_LootCouncil_UI = nil
C_AddOns.LoadAddOn = function(n)
    loaded[n] = true
    if n:find("_UI$") then loadfolder("NorthernSkyRaidTools_LootCouncil_UI", "NorthernSkyRaidTools_LootCouncil_UI.toc") end
    return true
end
try("Sim.Run #1", LC.Sim.Run)
print("IsOpen after run (setup shows first, so false):", LC.Session.IsOpen(), "queue:", LC.Queue.Count())
try("Setup open", LC.Frames.SetupFrame.Open)
try("Loot.StartSession", function() assert(LC.Loot.StartSession(), "start failed") end)
print("IsOpen after start:", LC.Session.IsOpen(), "queue:", LC.Queue.Count())
try("LootFrame.Refresh", LC.Frames.LootFrame.Refresh)
try("VotingFrame.Open", LC.UI.VotingFrame.Open)
try("Sim.Run while running", LC.Sim.Run)
try("Sim.Run #2", LC.Sim.Run)
try("Sim.Stop", LC.Sim.Stop)
print("IsOpen after stop:", LC.Session.IsOpen())
try("Preview.Run", function() LC.Preview_.Run("") end)
print("EnsureUI/Loaded:", LC.UI.Loaded)
for _, sub in ipairs({ "setup", "loot", "trades", "history", "responses", "lead", "council" }) do try("Preview " .. sub, function() LC.Preview_.Run(sub) end) end
try("Preview stop", function() LC.Preview_.Run("stop") end)
try("status", LC.Sim.Status)
try("Trade.Report", LC.Trade.Report)
try("stopany idle", LC.Sim.StopAny)
try("Sim.Run again", LC.Sim.Run)
try("close (ml)", LC.Session.RequestClose)
try("status after close", LC.Sim.Status)
try("stopany", LC.Sim.StopAny)
