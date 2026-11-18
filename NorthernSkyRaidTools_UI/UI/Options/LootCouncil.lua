-- ============================================================
--  Options/LootCouncil.lua - the Loot Council tab
--
--  Owns: the tab's option tables. The first control is a quick on/off for taking part (it pauses
--  the loaded module; the addon itself is enabled only in the AddOns list, and the switch turns
--  itself back on at every login). Every other control reads and writes
--  the module's own saved data and does nothing visible while the module is off, so the tab
--  can be built once and works as soon as the switch is turned on.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}

local function LC()
    return NSI.Modules and NSI.Modules:IsLoaded("LootCouncil") and NSI.LootCouncil or nil
end

-- The module only when it is loaded and not paused (for anything that opens a window or acts).
local function Live()
    local lc = LC()
    return lc and not lc.dead and lc or nil
end

local function Ruleset()
    local lc = LC()
    return lc and lc.DB.G().ruleset or nil
end

local function NeedModule()
    print(NSI:Loc("|cFF00FFFFNSRT|r Loot Council is off. Turn on the switch at the top of this tab, or enable the addon in the AddOns list and /reload."))
end

local function Settings()
    local lc = LC()
    return lc and lc.DB.Settings() or nil
end

-- Push the leader's changed ruleset out when the leader edits it during a raid.
local function Changed()
    local lc = LC()
    if lc then lc.Ruleset.Reapply() end
end

local function List(values, getKey, setKey)
    local out = {}
    for _, v in ipairs(values) do
        out[#out + 1] = {
            label = NSI:Loc(v.label), phraseId = v.label, value = v.value,
            onclick = function() setKey(v.value) end,
        }
    end
    return out
end

local function RulesetToggle(key, name, desc)
    return {
        type = "toggle", boxfirst = true, name = name, desc = desc,
        get = function() local r = Ruleset(); return r and r[key] or false end,
        set = function(_, _, value) local r = Ruleset(); if r then r[key] = value; Changed() end end,
    }
end

-- Green / red dot: is the loot council running for the group you are in right now (armed = the raid leader said
-- yes and their ruleset is applied). The reason after a red dot says what is missing.
local DOT_ON, DOT_OFF = "|TInterface\\COMMON\\Indicator-Green:16|t", "|TInterface\\COMMON\\Indicator-Red:16|t"
local function CouncilStatusText()
    local lc = LC()
    if lc and not lc.dead and lc.State.IsArmed() then
        return DOT_ON .. " |cff33ff66" .. NSI:Loc("Loot council is active for this raid group") .. "|r"
    end
    local why
    if not lc or lc.dead then why = "the loot council is switched off"
    elseif not IsInRaid() then why = "you are not in a raid group"
    elseif lc.Roster.IsLeader(lc.Roster.MyKey()) then why = "use \"Use for this raid\" below"
    else why = "the raid leader has not turned it on" end
    return DOT_OFF .. " |cffff4040" .. NSI:Loc("Loot council is inactive for this raid group") .. "|r |cff999999(" .. NSI:Loc(why) .. ")|r"
end

-- The tab is built once, so keep the status line current while the tab is open.
local statusTicker
local function KeepStatusFresh()
    if statusTicker then return end
    statusTicker = C_Timer.NewTicker(0.5, function()
        local menu = NSI.UI and NSI.UI.Core and NSI.UI.Core.NSUI and NSI.UI.Core.NSUI.MenuFrame
        local frame = menu and menu.CurrentName and menu.AllFramesByName and menu.AllFramesByName[menu.CurrentName]
        if not (frame and frame.widget_list and frame:IsVisible()) then return end
        for _, w in ipairs(frame.widget_list) do
            if w._get == CouncilStatusText then w:SetText(CouncilStatusText()) end
        end
    end)
end

local function BuildOptions()
    local O = {}
    local function add(t) O[#O + 1] = t end

    add({ type = "label", get = CouncilStatusText })
    KeepStatusFresh()
    add({ type = "break" })

    add({ type = "label", get = function() return "Loot Council" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") })
    add({
        type = "toggle", boxfirst = true, name = "Enable Loot Council",
        desc = "Quickly stops or resumes your part in the loot council: while it is off you take no part (no windows, no messages). It does not change the addon's checkbox in the game's AddOns list, which is the only way to load or unload the module, and it switches itself back on at every login.",
        get = function() return NSI.Modules:IsActive("LootCouncil") end,
        set = function(_, _, value) NSI.Modules:SetActive("LootCouncil", value) end,
    })
    add({ type = "break" })
    add({
        type = "button", name = "Open Loot Council", desc = "Opens the council window.",
        func = function() NSI.Modules:HandleLootCommand("") end,
    })
    add({
        type = "button", name = "Trades", desc = "Items you hold that still have to be traded.",
        func = function() local lc = Live(); if not lc then NeedModule() elseif lc.EnsureUI() then lc.UI.TradesFrame.Open() end end,
    })
    add({
        type = "button", name = "History", desc = "Award history for the current season.",
        func = function() local lc = Live(); if not lc then NeedModule() elseif lc.EnsureUI() then lc.UI.HistoryFrame.Open() end end,
    })
    add({
        type = "button", name = "Priorities", desc = "Edit item priority lists.",
        func = function() local lc = Live(); if not lc then NeedModule() elseif lc.EnsureUI() then lc.UI.PriorityEditor.Open() end end,
    })
    add({
        type = "button", name = "Response Buttons", desc = "Choose the response buttons raiders see and which ones need a note.",
        func = function() local lc = Live(); if not lc then NeedModule() elseif lc.EnsureUI() then lc.UI.ResponseEditor.Open() end end,
    })
    add({
        type = "button", name = "Run Test Session", desc = "Opens a simulated session on your own, no group needed.",
        func = function() NSI.Modules:HandleLootCommand("test") end,
    })
    add({ type = "break" })

    add({ type = "label", get = function() return "When You Lead a Raid" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") })
    add({
        type = "select", name = "When I become raid leader",
        desc = "Ask shows a prompt once per raid. The answer is remembered until you leave the group or lose lead.",
        get = function() local s = Settings(); return s and s.onLead or "ask" end,
        set = function() end,
        values = function()
            return List({ { label = "Ask me", value = "ask" }, { label = "Always use it", value = "always" }, { label = "Never use it", value = "never" } },
                nil, function(v) local s = Settings(); if s then s.onLead = v end end)
        end,
    })
    add({
        type = "button", name = "Use for this raid", desc = "Turn the loot council on for the group you are leading.",
        func = function() local lc = Live(); if lc then lc.State.SetForThisRaid(true) end end,
    })
    add({
        type = "button", name = "Stop for this raid", desc = "Stand everyone down for the group you are leading.",
        func = function() local lc = Live(); if lc then lc.State.SetForThisRaid(false) end end,
    })
    add({ type = "break" })

    add({ type = "label", get = function() return "Ruleset (sent to the raid when you lead)" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") })
    add({
        type = "select", name = "Who sees votes and awards",
        desc = "Awards: everyone sees awards. Open: everyone sees candidates and awards. Council: only the council sees anything.",
        get = function() local r = Ruleset(); return r and r.sharing or "awards" end,
        set = function() end,
        values = function()
            return List({ { label = "Awards only", value = "awards" }, { label = "Open", value = "open" }, { label = "Council only", value = "council" } },
                nil, function(v) local r = Ruleset(); if r then r.sharing = v; Changed() end end)
        end,
    })
    add(RulesetToggle("anonymous", "Anonymous voting", "Hide who each council member voted for."))
    add(RulesetToggle("chatAnnounce", "Announce in raid chat", "A raid chat line when the council is turned on, for every award (item, winner and reason), and when an award is changed to another player."))
    add({
        type = "range", name = "Response time (seconds)", desc = "How long raiders have to answer.",
        get = function() local r = Ruleset(); return r and r.timeout or 60 end,
        set = function(_, _, value) local r = Ruleset(); if r then r.timeout = value; Changed() end end,
        min = 10, max = 300, step = 5,
    })
    add({
        type = "textentry", name = "Backup roller (name)", desc = "Rolls for items the raid leader cannot. Character name or nickname. Leave empty for the first assistant. Press Enter to apply.",
        get = function() local r = Ruleset(); return r and r.backupName or "" end,
        set = function(_, _, value) local r = Ruleset(); if r then r.backupName = value or ""; Changed() end end,
    })
    add({ type = "break" })

    add({ type = "label", get = function() return "Council (the raid leader is always on it)" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") })
    add({
        type = "toggle", boxfirst = true, name = "Raid assistants are on the council",
        get = function() local r = Ruleset(); return r and r.council.assistants or false end,
        set = function(_, _, value) local r = Ruleset(); if r then r.council.assistants = value; Changed() end end,
    })
    add({
        type = "select", name = "Guild rank added to the council",
        desc = "Members of your guild at this rank or higher (closer to Guild Master) are on the council automatically while they are in the raid.",
        get = function() local r = Ruleset(); return r and r.council.minRank or -1 end,
        set = function() end,
        values = function()
            local options = { { label = NSI:Loc("None"), phraseId = "None", value = -1,
                onclick = function() local r = Ruleset(); if r then r.council.minRank = -1; Changed() end end } }
            local ranks, seen = {}, {}
            if IsInGuild() then
                for i = 1, GetNumGuildMembers() do
                    local _, rankName, rankIndex = GetGuildRosterInfo(i)
                    if rankName and rankIndex and not seen[rankIndex] then
                        seen[rankIndex] = true
                        ranks[#ranks + 1] = { rankIndex = rankIndex, rankName = rankName }
                    end
                end
                table.sort(ranks, function(a, b) return a.rankIndex < b.rankIndex end)
            end
            for _, rank in ipairs(ranks) do
                options[#options + 1] = { label = rank.rankName, value = rank.rankIndex,
                    onclick = function() local r = Ruleset(); if r then r.council.minRank = rank.rankIndex; Changed() end end }
            end
            return options
        end,
    })
    add({
        type = "textentry", name = "Extra council members",
        desc = "Comma-separated character names or nicknames. Example: Rav, Reloe. Press Enter to apply.",
        get = function() local r = Ruleset(); return r and table.concat(r.council.names, ", ") or "" end,
        set = function(_, _, value)
            local r = Ruleset()
            if not r then return end
            local names = {}
            for n in tostring(value):gmatch("[^,]+") do
                n = strtrim(n)
                if n ~= "" then names[#names + 1] = n end
            end
            r.council.names = names
            Changed()
        end,
    })
    add({ type = "break" })

    add({ type = "label", get = function() return "Difficulties" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") })
    for _, d in ipairs({ { 14, "Normal" }, { 15, "Heroic" }, { 16, "Mythic" } }) do
        add({
            type = "toggle", boxfirst = true, name = d[2], desc = "Run the council on kills at this difficulty.",
            get = function() local r = Ruleset(); return r and r.difficulties[d[1]] or false end,
            set = function(_, _, value) local r = Ruleset(); if r then r.difficulties[d[1]] = value; Changed() end end,
        })
    end
    add({ type = "break" })

    add({ type = "label", get = function() return "Your Loot Settings (only affect you)" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") })
    add({
        type = "toggle", boxfirst = true, name = "Auto-pass Blizzard rolls",
        desc = "When a raid uses the loot council, pass on Blizzard's roll so the loot master can collect the item. Skipped when the loot master is offline or in another zone.",
        get = function() local s = Settings(); return s and s.autoPass or false end,
        set = function(_, _, value) local s = Settings(); if s then s.autoPass = value end end,
    })
    add({
        type = "toggle", boxfirst = true, name = "Only auto-pass in guild groups",
        desc = "Recommended. In a group that is mostly not your guild (a pug) you keep your normal rolls, so nobody can take loot from you.",
        get = function() local s = Settings(); return s and s.autoPassGuildOnly or false end,
        set = function(_, _, value) local s = Settings(); if s then s.autoPassGuildOnly = value end end,
    })
    add({
        type = "toggle", boxfirst = true, name = "Auto-pass items I cannot use",
        desc = "Answers Pass for you on armor your class cannot wear (for example plate on a cloth wearer), so you are not asked. Weapons and accessories are never auto-passed.",
        get = function() local s = Settings(); return s and s.autoPassUnusable or false end,
        set = function(_, _, value) local s = Settings(); if s then s.autoPassUnusable = value end end,
    })
    add({ type = "break" })

    add({ type = "label", get = function() return "Display" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") })
    add({
        type = "range", name = "Window scale", desc = "Scale of the loot council windows.",
        get = function() local s = Settings(); return s and s.scale or 1 end,
        set = function(_, _, value)
            local s = Settings()
            if s then s.scale = value; local lc = LC(); if lc then lc.Fire("NSRT_LC_SCALE_CHANGED", value) end end
        end,
        min = 0.6, max = 1.6, step = 0.05,
    })
    return O
end

NSI.UI.Options.LootCouncil = {
    BuildOptions = BuildOptions,
    BuildCallback = function() return function() end end,
}
