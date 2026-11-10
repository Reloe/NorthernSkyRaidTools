-- ============================================================
--  Search.lua  -  addon-wide settings search (header search box)
--
--  A search box at the far left of the window's title bar (the scale slider sits to
--  its right). Typing shows a ranked popup of settings from every options tab, each
--  with a "Tab  >  Section" breadcrumb. Choosing one opens the tab, scrolls the
--  setting into view and pulses it. The page is never filtered.
--
--  What is searched
--    * every sidebar tab name
--    * every section title and every setting (checkbox, slider, dropdown, colour,
--      text box, button) of the pages built with Components.BuildMenu
--    Data entries (individual bosses, auras, spells) are not searchable.
--
--  How the index works
--    BuildMenu leaves its menu on the tab frame (frame.menu). That menu is plain data:
--    stacks -> sections -> defs, each def with a label and tooltip. The index is made
--    by walking those tables, so it creates no frames and calls no get/set function.
--    It is rebuilt each time the box gains focus (a few hundred strings), so language
--    changes and dynamic section titles are always current. Every searchable form is
--    lowercased once at index time; a keystroke only compares strings.
--
--  Combat: everything here is our own non-secure frames and plain strings, so the box
--  works in combat. No game state (units, auras, cooldowns) is read.
-- ============================================================

local NSI = _G.NorthernSkyRaidTools
local STYLE  = NSI.UI.Style
local Pixel  = NSI.UI.Pixel
local Components = NSI.UI.Components
local Accent = STYLE.Accent

local floor, min, format = math.floor, math.min, string.format
local ipairs, pairs, type, tsort = ipairs, pairs, type, table.sort

local Search = {}
NSI.UI.Search = Search

local WHITE       = [[Interface\Buttons\WHITE8X8]]
local SEARCH_ICON = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\search.png]]

local BOX_W       = 220
local BOX_H       = 24
local BOX_X       = 8        -- from the title bar's left edge
local POPUP_W     = 420
local ROW_H       = 38
local ROW_GAP     = 2
local POPUP_PAD   = 6
local MAX_RESULTS = 8

local entryBox, edit, popup, placeholder
local rows = {}
local selectedIndex = 1
local tabSystem

-- --------------------------------------------------------------------------
--  Index
-- --------------------------------------------------------------------------
local index = {}

-- Colour codes and inline textures are display markup, not text to match.
local function StripEscapes(s)
    s = tostring(s or "")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
    return (strtrim(s))
end

-- Lowercase without spaces or punctuation: "castbar" finds "Cast Bar".
local function Squash(s) return (s:gsub("[%s%p]", "")) end

local function Localized(text)
    return StripEscapes(NSI:Loc(text))
end

-- kind: "page" | "section" | "row". ref carries what the jump needs.
local function MakeEntry(kind, tabName, tabTitle, sectionTitle, rawLabel, tooltip, section, defIndex)
    if type(rawLabel) ~= "string" or rawLabel == "" then return end
    local english = StripEscapes(rawLabel)
    local shown   = Localized(rawLabel)
    if shown == "" then return end
    local e = {
        kind = kind, tab = tabName, tabTitle = tabTitle, sectionTitle = sectionTitle,
        shown = shown, section = section, defIndex = defIndex,
        low = shown:lower(),
    }
    e.flat = Squash(e.low)
    if english ~= shown then e.english = english:lower() end   -- guides quote English names
    if type(tooltip) == "table" then tooltip = tooltip.desc end
    if type(tooltip) == "string" and tooltip ~= "" then e.tip = Localized(tooltip):lower() end
    return e
end

local function AddEntry(...)
    local e = MakeEntry(...)
    if e then index[#index + 1] = e end
end

local function BuildIndex()
    for i = #index, 1, -1 do index[i] = nil end
    for tabName, button in pairs(tabSystem.AllButtonsByName) do
        local tabTitle = button._textKey and Localized(button._textKey) or tabName
        AddEntry("page", tabName, tabTitle, nil, button._textKey)

        local frame = tabSystem.AllFramesByName[tabName]
        -- Master/detail screens (Aura Tracking, Aura Glows) have no menu; they publish the
        -- selected entry's definition lists instead. Indexed as they stand now.
        if frame and frame.SearchPanels then
            local ok, panels = pcall(frame.SearchPanels)
            for _, panel in ipairs(ok and panels or {}) do
                for defIndex, def in ipairs(panel.defs) do
                    if def.Type ~= "Label" and def.Type ~= "Breakline" and (def.label or def.text) then
                        AddEntry("row", tabName, tabTitle, Localized(panel.title), def.label or def.text, def.tooltip,
                            { panel = panel.id, screen = frame }, defIndex)
                    end
                end
            end
        end
        local menu = frame and frame.menu
        if menu then
            for _, sections in ipairs(menu.stacks) do
                for _, section in ipairs(sections) do
                    local title = section.getTitle and section.getTitle()
                    if type(title) == "string" and title ~= "" then
                        AddEntry("section", tabName, tabTitle, nil, title, nil, section)
                        title = Localized(title)
                    else
                        title = nil
                    end
                    for defIndex, def in ipairs(section.defs) do
                        if def.Type ~= "Label" and def.Type ~= "Breakline" then
                            AddEntry("row", tabName, tabTitle, title, def.label, def.tooltip, section, defIndex)
                        end
                    end
                end
            end
        end
    end
end

-- --------------------------------------------------------------------------
--  Scoring. Higher is better; the tiers never overlap.
--    3000+  label contains the query (word start above mid-word, earlier above later)
--    2500   label contains it ignoring spaces and punctuation
--    2400   English label contains it (non-English clients)
--    1500   tooltip contains it
--    1000+  the query's letters appear in order in the label, tightly (fuzzy)
--    +150   page and section entries, so typing a tab name lands on the tab first
-- --------------------------------------------------------------------------
local function Fuzzy(h, q)
    local pos, prev, first, score = 1, nil, nil, 0
    for i = 1, #q do
        local at = h:find(q:sub(i, i), pos, true)
        if not at then return nil end
        first = first or at
        score = score + ((prev and at == prev + 1) and 3 or 1)
        if at == 1 or h:byte(at - 1) == 32 then score = score + 2 end   -- word start
        prev, pos = at, at + 1
    end
    if prev - first + 1 > #q * 3 then return nil end   -- letters too scattered: noise
    return score
end

local function Score(e, q, qFlat)
    local s
    local at = e.low:find(q, 1, true)
    if at then
        local wordStart = at == 1 or e.low:byte(at - 1) == 32
        s = 3000 + (wordStart and 400 or 0) - min(at, 300)
    elseif #qFlat > 0 and e.flat:find(qFlat, 1, true) then
        s = 2500
    elseif e.english and e.english:find(q, 1, true) then
        s = 2400
    elseif e.tip and e.tip:find(q, 1, true) then
        s = 1500
    else
        local f = Fuzzy(e.low, q)
        if f then s = 1000 + f end
    end
    if s and e.kind ~= "row" then s = s + 150 end
    return s
end

local results = {}

local function ByScore(a, b)
    if a.score ~= b.score then return a.score > b.score end
    if a.e.shown ~= b.e.shown then return a.e.shown < b.e.shown end   -- stable between keystrokes
    return a.e.tabTitle < b.e.tabTitle
end

function Search.Query(text)
    for i = #results, 1, -1 do results[i] = nil end
    local q = strtrim((text or ""):lower())
    if q == "" then return results, q end
    local qFlat = Squash(q)
    for _, e in ipairs(index) do
        local s = Score(e, q, qFlat)
        if s then results[#results + 1] = { e = e, score = s } end
    end
    tsort(results, ByScore)
    for i = #results, MAX_RESULTS + 1, -1 do results[i] = nil end
    return results, q
end

-- --------------------------------------------------------------------------
--  Jump: open the tab, scroll the setting into view, pulse it. Never filters.
-- --------------------------------------------------------------------------
local pulse

local function Pulse(target)
    if not pulse then
        pulse = Pixel.CreateBoxFrame("Frame", nil, UIParent)
        pulse:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        pulse:EnableMouse(false)
        -- fade in, hold, fade out: one animation group, runs in C
        local g = pulse:CreateAnimationGroup()
        g:SetToFinalAlpha(true)
        local fadeIn = g:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.15); fadeIn:SetOrder(1)
        local fadeOut = g:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(0.6)
        fadeOut:SetStartDelay(1.4); fadeOut:SetOrder(2)
        g:SetScript("OnFinished", function() pulse:Hide() end)
        pulse.anim = g
    end
    pulse.anim:Stop()
    local parent = target:GetParent() or UIParent
    pulse:SetParent(parent)
    pulse:ClearAllPoints()
    pulse:SetPoint("TOPLEFT", target, "TOPLEFT", -2, 2)
    pulse:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 2, -2)
    pulse:SetFrameLevel(parent:GetFrameLevel() + 20)
    local r, g, b = Accent(1)
    pulse:SetBackdropColor(r, g, b, 0.10)
    pulse:SetBackdropBorderColor(r, g, b, 1)
    pulse:SetAlpha(0)
    pulse:Show()
    pulse.anim:Play()
end

local function Jump(e)
    if not e then return end
    popup:Hide()
    entryBox:SetValue("")
    edit:ClearFocus()
    tabSystem:SelectTabByName(e.tab)
    if e.kind == "page" then return end
    -- A tab shown this frame has no layout yet: measure on the next one.
    if e.section and e.section.screen then
        local screen, id = e.section.screen, e.section.panel
        C_Timer.After(0, function()
            if not screen:IsShown() or not screen.SearchReveal then return end
            local host, scroll = screen.SearchReveal(id)
            local set = host and host.current
            local item = set and set.byIndex[e.defIndex]
            if item and item.frame:IsShown() then
                if scroll then scroll:ScrollToFrame(item.frame) end
                Pulse(item.frame)
            end
        end)
        return
    end
    C_Timer.After(0, function()
        local frame = tabSystem.AllFramesByName[e.tab]
        local menu = frame and frame.menu
        if not (menu and frame:IsShown() and e.section) then return end
        local target = e.section.card
        local set = e.defIndex and e.section.host.current
        local item = set and set.byIndex[e.defIndex]
        if item and item.frame:IsShown() then target = item.frame end
        menu.scroll:ScrollToFrame(target)
        Pulse(target)
    end)
end

-- --------------------------------------------------------------------------
--  Popup
-- --------------------------------------------------------------------------
local function AccentHex()
    local r, g, b = Accent(1)
    return format("%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

-- "|" starts an escape sequence in font strings: double it.
local function Esc(s) return (s:gsub("|", "||")) end

local function Mark(shown, q)
    local s, e = shown:lower():find(q, 1, true)
    if not s then return Esc(shown) end
    return Esc(shown:sub(1, s - 1)) .. "|cff" .. AccentHex() .. Esc(shown:sub(s, e)) .. "|r" .. Esc(shown:sub(e + 1))
end

local function Crumb(e)
    if e.kind == "page" then return NSI:Loc("Page") end
    if e.kind == "row" and e.sectionTitle then return e.tabTitle .. "  >  " .. e.sectionTitle end
    return e.tabTitle
end

local function PaintSelection()
    for i, r in ipairs(rows) do
        r.hl:SetShown(i == selectedIndex and r:IsShown() and r.entry ~= nil)
    end
end

local function GetRow(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, popup)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", popup, "TOPLEFT", POPUP_PAD, -POPUP_PAD - (i - 1) * (ROW_H + ROW_GAP))
    r:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -POPUP_PAD, -POPUP_PAD - (i - 1) * (ROW_H + ROW_GAP))
    r.hl = r:CreateTexture(nil, "BACKGROUND")
    r.hl:SetAllPoints()
    r.hl:SetColorTexture(Accent(0.18))
    STYLE.PaintAccent(r.hl, "SetColorTexture", 0.18)
    r.hl:Hide()
    r.title = r:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(r.title, "label")
    r.title:SetPoint("TOPLEFT", 10, -5)
    r.title:SetPoint("RIGHT", -10, 0)
    r.title:SetJustifyH("LEFT")
    r.title:SetWordWrap(false)
    r.sub = r:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(r.sub, "tiny", "")
    r.sub:SetTextColor(unpack(STYLE.text_muted))
    r.sub:SetPoint("BOTTOMLEFT", 10, 5)
    r.sub:SetPoint("RIGHT", -10, 0)
    r.sub:SetJustifyH("LEFT")
    r.sub:SetWordWrap(false)
    r.i = i
    r:SetScript("OnClick", function(self) Jump(self.entry) end)
    r:SetScript("OnEnter", function(self) selectedIndex = self.i; PaintSelection() end)
    rows[i] = r
    return r
end

local function ShowResults()
    local text = edit:GetText()
    placeholder:SetShown(text == "" and not edit:HasFocus())
    if text == "" then popup:Hide() return end

    local list, q = Search.Query(text)
    for i, res in ipairs(list) do
        local r = GetRow(i)
        r.entry = res.e
        r.title:SetText(Mark(res.e.shown, q))
        r.sub:SetText(Crumb(res.e))
        r:Show()
    end
    for i = #list + 1, #rows do rows[i]:Hide(); rows[i].entry = nil end

    if #list == 0 then
        local r = GetRow(1)
        r.entry = nil
        r.title:SetText(NSI:Loc("No matching settings"))
        r.sub:SetText(NSI:Loc("Try fewer or different words."))
        r:Show()
        popup:SetHeight(ROW_H + POPUP_PAD * 2)
    else
        popup:SetHeight(#list * (ROW_H + ROW_GAP) - ROW_GAP + POPUP_PAD * 2)
    end
    selectedIndex = 1
    PaintSelection()
    popup:Show()
end

local function Move(delta)
    local n = 0
    for _, r in ipairs(rows) do if r:IsShown() and r.entry then n = n + 1 end end
    if n == 0 then return end
    selectedIndex = (selectedIndex - 1 + delta) % n + 1
    PaintSelection()
end

-- --------------------------------------------------------------------------
--  Create: build the box in the title bar and move the scale slider right of it
-- --------------------------------------------------------------------------
function Search.Create(window, tabs)
    if entryBox then return end
    tabSystem = tabs
    local titleBar = window.TitleBar

    entryBox = Components.CreateTextEntry(titleBar, nil, nil, nil, BOX_W, BOX_H, false, nil, nil,
        "NSUISearchBox", nil, nil, {
            OnTextChanged = function() ShowResults() end,
            OnArrowPressed = function(_, key)
                if key == "DOWN" then Move(1) elseif key == "UP" then Move(-1) end
            end,
            OnTabPressed = function() Move(IsShiftKeyDown() and -1 or 1) end,
            OnEnterPressed = function()
                local r = rows[selectedIndex]
                if r and r.entry then Jump(r.entry) end
            end,
            OnEditFocusGained = function()
                BuildIndex()
                placeholder:Hide()
                ShowResults()
            end,
            OnEditFocusLost = function()
                placeholder:SetShown(edit:GetText() == "")
                if popup and not popup:IsMouseOver() then popup:Hide() end   -- a click on a result still lands
            end,
        })
    entryBox:SetPoint("LEFT", titleBar, "LEFT", BOX_X, 0)
    edit = entryBox.editBox
    edit:SetTextInsets(22, 4, 0, 0)

    local icon = edit:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(SEARCH_ICON)
    icon:SetVertexColor(unpack(STYLE.text_muted))
    icon:SetSize(13, 13)
    icon:SetPoint("LEFT", edit, "LEFT", 4, 0)

    placeholder = edit:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(placeholder, "small", "")
    placeholder:SetTextColor(unpack(STYLE.text_hint))
    placeholder:SetPoint("LEFT", edit, "LEFT", 22, 0)
    placeholder:SetText(NSI:Loc("Search settings..."))

    popup = Pixel.CreateBoxFrame("Frame", "NSUISearchPopup", window)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetWidth(POPUP_W)
    popup:SetPoint("TOPLEFT", entryBox.frame, "BOTTOMLEFT", 0, -4)
    popup:EnableMouse(true)
    popup:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    popup:SetBackdropColor(unpack(STYLE.surface_panel))
    STYLE.PaintAccent(popup, "SetBackdropBorderColor", 0.7)
    popup:Hide()
    -- A click anywhere else closes the popup (an edit box keeps its focus when another
    -- frame is clicked). Listening only while the popup is up costs nothing otherwise.
    local watcher = CreateFrame("Frame")
    watcher:SetScript("OnEvent", function()
        if popup:IsMouseOver() or entryBox.frame:IsMouseOver() then return end
        edit:ClearFocus()
        popup:Hide()
    end)
    popup:SetScript("OnShow", function() watcher:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
    popup:SetScript("OnHide", function() watcher:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
    -- Closing the window while a query is showing must not leave the popup behind.
    window:HookScript("OnHide", function() popup:Hide() end)

    -- The scale slider keeps its place in the title bar, now to the right of the search.
    local scale = window.ScaleControl
    if scale then
        scale.frame:ClearAllPoints()
        scale.frame:SetPoint("LEFT", entryBox.frame, "RIGHT", 14, 0)
    end
end

-- Shared with ScopedSearch (per-tab search boxes): same scoring, markup and pulse.
Search.Internals = {
    MakeEntry = MakeEntry, Score = Score, Squash = Squash, ByScore = ByScore,
    Pulse = Pulse, Mark = Mark, Esc = Esc, Localized = Localized,
    MAX_RESULTS = MAX_RESULTS,
}
