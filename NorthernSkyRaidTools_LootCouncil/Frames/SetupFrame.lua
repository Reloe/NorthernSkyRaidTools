-- ============================================================
--  Frames/SetupFrame.lua - Session Setup: the first window the loot master sees after a kill (S-0)
--
--  Lists everything waiting (this kill plus anything saved from earlier kills, up to 3 hours old).
--  Each row has an include toggle (red = left out; left-out items are dropped when the session
--  starts). Start opens one session with every included item. "Award later?" turns Start into
--  "Save for later": the window closes and the items stay queued for the next kill or /ns loot setup.
--  Cancel just closes; nothing is lost. The window sizes itself to the list (up to MAX_ROWS entries, then the
--  list scrolls) and cannot be resized. The + box under the list opens a picker of the tradable items in the
--  loot master's bags that are not already in the list.
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Setup = {}
LC.Frames.SetupFrame = Setup

local frame, card, rows, info, empty, startBtn, later, clearBtn, scroll, addBtn
local awardLater, wasShown = false, false
local ROW_H, MAX_ROWS, W, INFO_H, FOOT_H, ADD_H = 40, 7, 420, 20, 52, 44
local ICONS = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]

local function Waiting()
    local n = 0
    for _, it in ipairs(LC.Queue.Items()) do if not it.excluded then n = n + 1 end end
    return n
end

local function BuildRow(i)
    local C = NSI.UI.Components
    local parent = scroll.scrollChild
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * ROW_H)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    row.check = C.CreateCheckButton(row, "", function() return not row.excluded end,
        function(_, v) if row.id then LC.Queue.SetExcluded(row.id, not v) end end, 22, 22, nil,
        LC.Loc("Include this item in the session"))
    row.check:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon = C.CreateItemButton(row, 32)
    row.icon.frame:SetPoint("LEFT", 30, 0)
    row.ilvl = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.ilvl, 12)
    row.ilvl:SetPoint("LEFT", 68, 0)
    row.ilvl:SetWidth(28)
    row.name = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.name, 12)
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 100, -4)
    row.name:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.sub = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.sub, "small")
    row.sub:SetTextColor(0.6, 0.6, 0.6)
    row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.sub:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetWordWrap(false)
    row.hit = CreateFrame("Frame", nil, row)
    row.hit:SetAllPoints(row.name)
    row.hit:EnableMouse(true)
    row.hit:SetScript("OnEnter", function(self)
        if not row.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(row.link)
        GameTooltip:Show()
    end)
    row.hit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

function Setup.Refresh(tries)
    if not frame or not frame:IsShown() then return end
    local items = LC.Queue.Items()
    local total = #items
    local unresolved = false
    for i = 1, total do
        local it = items[i]
        local row = rows[i] or BuildRow(i)
        rows[i] = row
        row.id, row.excluded = it.id, it.excluded
        row.link = LC.Items.ToLink(it.item) or nil
        row.icon:SetItem(row.link or it.itemID)
        local name = row.link or C_Item.GetItemNameByID(it.itemID)
        if not name then unresolved = true; C_Item.RequestLoadItemDataByID(it.itemID) end
        row.name:SetText(name or string.format(LC.Loc("Item %d"), it.itemID))
        local ilvl = row.link and LC.Items.ItemLevel(row.link)
        row.ilvl:SetText(ilvl and tostring(ilvl) or "")
        local parts = {}
        if it.boss then parts[#parts + 1] = it.boss end
        if it.holder then parts[#parts + 1] = string.format(LC.Loc("held by %s"), LC.Roster.Display(it.holder) or it.holder) end
        if it.allPassed then parts[#parts + 1] = LC.Loc("everyone passed") end
        row.sub:SetText(table.concat(parts, "  -  "))
        row.check:SetValue(not it.excluded)
        row.name:SetAlpha(it.excluded and 0.45 or 1)
        row.icon.frame:SetAlpha(it.excluded and 0.45 or 1)
        row:Show()
    end
    for i = total + 1, #rows do rows[i].id = nil; rows[i]:Hide() end
    -- the list is as tall as its entries, up to MAX_ROWS; after that it scrolls
    local viewH = math.min(math.max(total, 1), MAX_ROWS) * ROW_H
    scroll.frame:SetHeight(viewH)
    scroll.scrollChild:SetHeight(math.max(1, total * ROW_H))
    scroll:UpdateScrollBar()
    empty:ClearAllPoints()
    empty:SetPoint("TOP", card.content, "TOP", 0, -12)
    empty:SetShown(total == 0)
    addBtn.frame:ClearAllPoints()
    addBtn.frame:SetPoint("TOPLEFT", card.content, "TOPLEFT", 30, -(viewH + 6))
    card:SetHeight(LC.Frames.Shell.CardHeight(card, viewH + ADD_H + INFO_H))
    frame:SetHeight(-frame.contentTop + 6 + card:GetHeight() + 8 + FOOT_H)
    local left = LC.Queue.SecondsLeft()
    info:SetText(total == 0 and "" or string.format(LC.Loc("%d waiting. Oldest expires in %s."), total,
        left and NSI.UI.Components.FormatDuration(math.max(left, 0)) or "?"))
    startBtn:SetText(awardLater and LC.Loc("Save for later") or LC.Loc("Start"))
    if clearBtn then clearBtn.frame:SetShown(total > 0) end
    if unresolved and (tries or 0) < 5 then C_Timer.After(1, function() Setup.Refresh((tries or 0) + 1) end) end
end

-- ---- the bag picker (the + box) -----------------------------------------------------------------------
local picker, catcher, pickScroll, pickBtns, pickEmpty
local PICK_COLS, PICK_BTN, PICK_GAP, PICK_ROWS = 6, 38, 4, 5

-- Tradable gear in my bags that is not in the list yet: unbound epics, or bound items still inside their
-- trade window. Returns { { link, item, itemID, difficulty, bag, slot }, ... }.
function Setup.BagItems()
    local used = {}
    for _, it in ipairs(LC.Queue.Items()) do
        local key = LC.Items.TradeKey(it.itemID, it.difficulty)
        used[key] = (used[key] or 0) + 1
    end
    local out = {}
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, LC.Compat.NumBagSlots(bag) do
            local info = LC.Compat.BagInfo(bag, slot)
            local link = info and info.hyperlink
            if link then
                local _, _, _, loc, _, classID = C_Item.GetItemInfoInstant(link)
                local gear = (loc and loc ~= "") or classID == 15          -- equippable, or a token
                -- Warband / account bound items (including "until equipped") cannot go to other players' accounts.
                local bindType = select(14, C_Item.GetItemInfo(link))
                if gear and LC.Compat.IsAccountBound(bag, slot, link) then gear = false end
                local tradable
                if info.isBound then tradable = LC.Compat.GetBagTradeSecondsLeft(bag, slot) ~= nil
                else
                    -- unbound: every bind-on-equip piece (whatever its quality), or anything epic
                    local boe = bindType == (Enum and Enum.ItemBind and Enum.ItemBind.OnEquip or 2)
                    tradable = boe or (info.quality or 0) >= 4
                end
                if gear and tradable then
                    local d = LC.Items.Decode(link)
                    local key = LC.Items.KeyFromLink(link)
                    if used[key] and used[key] > 0 then
                        used[key] = used[key] - 1                          -- already in the list
                    elseif d then
                        out[#out + 1] = { link = link, item = d.itemString, itemID = d.itemID,
                            difficulty = LC.Items.ContextToDifficulty[d.context], bag = bag, slot = slot }
                    end
                end
            end
        end
    end
    return out
end

local function RefreshPicker()
    if not (picker and picker:IsShown()) then return end
    local list = Setup.BagItems()
    local rowsNeeded = math.max(1, math.ceil(#list / PICK_COLS))
    for i, entry in ipairs(list) do
        local b = pickBtns[i]
        if not b then
            b = NSI.UI.Components.CreateItemButton(pickScroll.scrollChild, PICK_BTN)
            local col, row = (i - 1) % PICK_COLS, math.floor((i - 1) / PICK_COLS)
            b.frame:SetPoint("TOPLEFT", pickScroll.scrollChild, "TOPLEFT", col * (PICK_BTN + PICK_GAP), -row * (PICK_BTN + PICK_GAP))
            b.frame:HookScript("OnClick", function(self)
                if IsShiftKeyDown() or not self.entry then return end       -- shift-click only links the item
                LC.Queue.AddManual(self.entry)
            end)
            pickBtns[i] = b
        end
        b.frame.entry = entry                       -- on the frame: that is what the click handler receives
        b:SetItem(entry.link)
        b.frame:Show()
    end
    for i = #list + 1, #pickBtns do pickBtns[i].frame.entry = nil; pickBtns[i].frame:Hide() end
    pickEmpty:SetShown(#list == 0)
    local viewRows = math.min(rowsNeeded, PICK_ROWS)
    local viewH = viewRows * (PICK_BTN + PICK_GAP) - PICK_GAP
    pickScroll.frame:SetHeight(viewH)
    pickScroll.scrollChild:SetHeight(math.max(1, rowsNeeded * (PICK_BTN + PICK_GAP)))
    pickScroll:UpdateScrollBar()
    picker:SetHeight(viewH + 44)
end

LC.On("NSRT_LC_QUEUE_CHANGED", function() RefreshPicker() end)     -- an added item leaves the picker

function Setup.ClosePicker()
    if picker then picker:Hide() end
    if catcher then catcher:Hide() end
end

function Setup.OpenPicker()
    local C = NSI.UI.Components
    if not picker then
        local w = PICK_COLS * (PICK_BTN + PICK_GAP) - PICK_GAP + 16 + 18 + 4
        picker = C.CreateFrame(UIParent, w, 120)
        picker:SetFrameStrata("DIALOG")
        picker:SetFrameLevel(50)
        picker:SetClampedToScreen(true)
        picker:Hide()
        local title = picker:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(title, "small")
        title:SetTextColor(0.7, 0.7, 0.7)
        title:SetPoint("TOPLEFT", 8, -8)
        title:SetText(LC.Loc("Add an item from your bags"))
        pickScroll = C.CreateScrollBox(picker, w - 16, 40)
        pickScroll.frame:SetPoint("TOPLEFT", picker, "TOPLEFT", 8, -28)
        pickBtns = {}
        pickEmpty = picker:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(pickEmpty, 12)
        pickEmpty:SetPoint("TOPLEFT", 12, -36)
        pickEmpty:SetText(LC.Loc("Nothing in your bags can be added."))
        -- a click anywhere else closes the picker
        catcher = CreateFrame("Button", nil, UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("DIALOG")
        catcher:SetFrameLevel(40)
        catcher:RegisterForClicks("AnyUp")
        catcher:SetScript("OnClick", Setup.ClosePicker)
        catcher:Hide()
        picker:HookScript("OnHide", function() catcher:Hide() end)
        picker:SetScript("OnEvent", function() RefreshPicker() end)
        picker:RegisterEvent("BAG_UPDATE_DELAYED")
    end
    picker:ClearAllPoints()
    picker:SetPoint("TOPLEFT", addBtn.frame, "TOPRIGHT", 8, 0)
    catcher:Show()
    picker:Show()
    RefreshPicker()
end

function Setup.Build()
    if frame or not (NSI.UI and NSI.UI.Window) then return end
    local C = NSI.UI.Components
    frame = LC.Frames.Shell.Create({ name = "NSLCSetupFrame", title = LC.Loc("Loot Session Setup"), width = W, height = 200,
        point = { "CENTER", 0, 60 } })
    rows = {}
    frame:SetResizable(false)                          -- sizes itself to the list
    if frame.resizeGrip then frame.resizeGrip:Hide(); frame.resizeGrip:EnableMouse(false) end
    -- The waiting items sit in a section card, like the main window's settings cards.
    card = LC.Frames.Shell.Card(frame, LC.Loc("Items waiting"), { label = LC.Loc("Clear all"), func = function() LC.Queue.Clear() end })
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, frame.contentTop - 6)
    card:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    clearBtn = card.headerButton
    scroll = C.CreateScrollBox(card.content, 100, ROW_H)
    scroll.frame:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, 0)
    scroll.frame:SetPoint("TOPRIGHT", card.content, "TOPRIGHT", 0, 0)
    addBtn = C.CreateButton(card.content, "", function()
        if picker and picker:IsShown() then Setup.ClosePicker() else Setup.OpenPicker() end
    end, 32, 32, nil, ICONS .. "plus.png", nil, LC.Loc("Add an item from your bags"))
    empty = card.content:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(empty, 12)
    empty:SetPoint("TOP", card.content, "TOP", 0, -8)
    empty:SetText(LC.Loc("No items are waiting."))
    info = card.content:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(info, "small")
    info:SetTextColor(0.6, 0.6, 0.6)
    info:SetPoint("BOTTOMLEFT", card.content, "BOTTOMLEFT", 0, 0)
    local actions = LC.Frames.Shell.Card(frame, nil)
    actions:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    actions:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    actions:SetHeight(LC.Frames.Shell.CardHeight(actions, 24))
    actions = actions.content
    later = C.CreateCheckButton(actions, LC.Loc("Award later?"), function() return awardLater end,
        function(_, v) awardLater = v and true or false; Setup.Refresh() end, 140, 22)
    later.frame:SetPoint("LEFT", actions, "LEFT", 0, 0)
    startBtn = C.CreateButton(actions, LC.Loc("Start"), function()
        if awardLater then
            Setup.Close()
            LC.Print(string.format(LC.Loc("%d items saved for later. /ns loot setup opens this window again."), Waiting()))
        elseif LC.Loot.StartSession() then
            LC.Frames.Shell.Hide(frame)
        end
    end, 110, 24)
    startBtn:SetPoint("RIGHT", actions, "RIGHT", -118, 0)
    local cancel = C.CreateButton(actions, LC.Loc("Cancel"), function()
        Setup.Close()
        if Waiting() > 0 then LC.Print(string.format(LC.Loc("%d items are still waiting. /ns loot setup opens this window again."), Waiting())) end
    end, 110, 24)
    cancel:SetPoint("RIGHT", actions, "RIGHT", 0, 0)
    frame:SetScript("OnShow", function() Setup.Refresh() end)
end

function Setup.Close()
    Setup.ClosePicker()
    if frame then LC.Frames.Shell.Hide(frame) end
end

-- Open on purpose (new kill, /ns loot setup, preview).
function Setup.Open(quiet)
    if LC.dead or not LC.EnsureKit() then return end
    Setup.Build()
    if not frame then return end
    if LC.Session.IsOpen() and not LC.Preview then
        LC.Print(LC.Loc("A session is already open. End it first (/ns loot end)."))
        return
    end
    if LC.Queue.Count() == 0 and not quiet then LC.Print(LC.Loc("No items are waiting.")) end
    LC.Frames.Shell.Reopen(frame)
    Setup.Refresh()
end

LC.On("NSRT_LC_SETUP", function() if LC.Ruleset.IAmML() then Setup.Open() end end)
LC.On("NSRT_LC_QUEUE_CHANGED", function() Setup.Refresh() end)
LC.On("NSRT_LC_SESSION_OPENED", function() Setup.ClosePicker(); if frame then LC.Frames.Shell.Hide(frame) end end)
LC.On("NSRT_LC_ENCOUNTER", function(starting)
    if not frame then return end
    if starting then
        wasShown = frame:IsShown()
        LC.Frames.Shell.Hide(frame)
    elseif wasShown and not LC.Session.IsOpen() and LC.Queue.Count() > 0 then
        wasShown = false
        LC.Frames.Shell.Reopen(frame)
    end
end)
function Setup.Shutdown() if frame then LC.Frames.Shell.Hide(frame) end end
LC.RegisterShutdown("SetupFrame", Setup.Shutdown)
