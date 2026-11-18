-- ============================================================
--  Frames/LootFrame.lua - the raider's response window (V-1)
--
--  Layout (one block per open drop):
--      [icon]  item name                                   equipped: [e1][e2]
--              ilvl / slot
--              [BiS] [Major] [Minor] ... [Pass]                           [note]
--  A progress bar across the top counts down the response time (ruleset timeout from when the
--  session opened). When it runs out, items you did not answer count as "No response" and the
--  buttons lock. The note icon on every row opens a small flyout to type a note; a response that
--  is marked "needs note" opens the same flyout and is sent with the note. The X only hides the
--  window (a small "Loot: N waiting" chip brings it back). Drag it anywhere; the position is saved.
--  Hidden on ENCOUNTER_START; nothing is lost, state lives in the session.
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local LootFrame = {}
LC.Frames.LootFrame = LootFrame

local frame, chip, chipFrame, bar, flyout
local rows = {}
local pendingNotes = {}        -- [dropID] = note typed before a response was chosen
local autoPassed = {}          -- [dropID] = true: answered Pass for me because I cannot use it (no row shown)
local expired = false
local votedOpen = false       -- the "Already voted" section is collapsed until opened
local votedCard
local ROW_H, BTN_W, BTN_GAP, MAX_BTN = 78, 76, 4, 7
local ICON, BAR_H, CARD_PAD, ROW_GAP = 44, 20, 10, 6
local CARD_H = ROW_H + CARD_PAD * 2      -- every item is a card, like the main window
local ICONS = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]
local NOTE_ICON = ICONS .. "notebook-pen.png"
local WIDTH = 8 + CARD_PAD + ICON + 8 + MAX_BTN * (BTN_W + BTN_GAP) + 30 + CARD_PAD + 8

local function Shell() return LC.Frames.Shell end

local function MyResponse(dropID)
    local state = LC.Session.state
    local r = state and state.responses[dropID] and state.responses[dropID][LC.Roster.MyKey()]
    return r
end

-- ---- timer -------------------------------------------------------------
local function TimeLeft()
    local rs = LC.Ruleset.Get()
    local state = LC.Session.state
    if not (rs and state) then return nil, 0 end
    return LC.Session.TimeLeft(state, rs.timeout, GetServerTime()), rs.timeout
end

local function UpdateBar()
    local left, total = TimeLeft()
    if not left then bar:SetFraction(0, true); bar:SetText(""); return end
    if LC.Preview and left <= 0 then
        -- Preview loops the timer so the bar can always be looked at.
        LC.Session.state.openTime = GetServerTime()
        left = total
    end
    local was = expired
    expired = left <= 0
    if expired then bar:SetFraction(0) else bar:SetTimer(left, total) end
    bar:SetText(expired and LC.Loc("Time is up") or string.format(LC.Loc("Time Left: %s"), NSI.UI.Components.ColorText(NSI.UI.Components.FormatDuration(math.ceil(left)), { 0, 1, 1 })))
    if expired ~= was then LootFrame.Refresh() end
end

-- ---- sending -----------------------------------------------------------
local function Send(dropID, responseID, note, auto)
    local state = LC.Session.state
    if not state or expired then return end
    local me = LC.Roster.MyKey()
    local drop = state.drops[dropID]
    local ev = { id = dropID, from = me, response = responseID, note = note, auto = auto and true or nil, seq = LC.Session.NextSeq() }
    if drop then
        local equipLoc = select(4, C_Item.GetItemInfoInstant(drop.itemID))
        local link = LC.Items.ToLink(drop.item)
        ev.ilvl = link and LC.Items.ItemLevel(link) or nil
        local gear = LC.Items.EquippedForEquipLoc(equipLoc)
        if #gear > 0 then ev.gear = gear end
        ev.tier = LC.Items.TierCount()
        ev.tg = LC.Items.TierGear()                    -- the five tier slots, for the council window
        local specIndex = GetSpecialization and GetSpecialization()
        ev.spec = specIndex and GetSpecializationInfo(specIndex) or nil
        local sim = LC.Sims.Get(me, drop.itemID)
        if sim then ev.sim, ev.simAge = sim.pct, sim.at end
    end
    LC.Comms.Send("RESPONSE", ev, "RAID")
    LC.Session.AddResponse(ev, me)
    pendingNotes[dropID] = nil
    LootFrame.Refresh()
end

-- ---- auto-pass for items your class cannot use (your own setting) ------------
local function PassResponse()
    local rs = LC.Ruleset.Get()
    for _, r in ipairs(rs and rs.responses or {}) do
        if r.id == "pass" or r.color == "pass" then return r end
    end
end

function LootFrame.AutoPass()
    if LC.Preview or LC.dead or not LC.DB.Settings().autoPassUnusable then return end
    local state = LC.Session.state
    if not (state and not state.closed and LC.Ruleset.IsActive()) then return end
    local pass = PassResponse()
    if not pass then return end
    local me = LC.Roster.MyKey()
    for _, id in ipairs(state.order) do
        local d = state.drops[id]
        local answered = state.responses[id] and state.responses[id][me]
        if d.state == "open" and not autoPassed[id] and not answered and not LC.Items.CanUse(d.item or d.itemID) then
            autoPassed[id] = true
            Send(id, pass.id, nil, true)           -- shown to the council as "Auto pass", not as a note
        end
    end
end

-- ---- note flyout -------------------------------------------------------
local function BuildFlyout()
    if flyout then return flyout end
    local C = NSI.UI.Components
    flyout = C.CreateFrame(UIParent, 300, 92)
    flyout:SetFrameStrata("DIALOG")
    flyout:Hide()
    flyout.title = flyout:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(flyout.title, 12)
    flyout.title:SetPoint("TOPLEFT", 8, -8)
    flyout.title:SetPoint("RIGHT", flyout, "RIGHT", -28, 0)
    flyout.title:SetJustifyH("LEFT")
    flyout.title:SetWordWrap(false)
    flyout.entry = C.CreateTextEntry(flyout, nil, nil, nil, 284, 24)
    flyout.entry:SetPoint("TOPLEFT", 8, -30)
    flyout.edit = flyout.entry.editBox
    flyout.edit:SetMaxLetters(120)
    flyout.edit:HookScript("OnEscapePressed", function() flyout:Hide() end)
    flyout.edit:HookScript("OnEnterPressed", function() flyout.send() end)
    flyout.sendBtn = C.CreateButton(flyout, LC.Loc("Send"), function() flyout.send() end, 90, 24)
    flyout.sendBtn:SetPoint("BOTTOMRIGHT", flyout, "BOTTOMRIGHT", -8, 8)
    flyout.cancelBtn = C.CreateButton(flyout, LC.Loc("Cancel"), function() flyout:Hide() end, 90, 24)
    flyout.cancelBtn:SetPoint("RIGHT", flyout.sendBtn.frame, "LEFT", -6, 0)
    return flyout
end

-- dropID: the row; pending: a response (ruleset entry) waiting for its required note, or nil.
local function OpenNote(row, dropID, pending)
    local f = BuildFlyout()
    local mine = MyResponse(dropID)
    f:ClearAllPoints()
    f:SetPoint("TOPRIGHT", row.note, "BOTTOMRIGHT", 0, -4)
    f.title:SetText(pending and string.format(LC.Loc("\"%s\" needs a note:"), LC.Loc(pending.text)) or LC.Loc("Note for the council:"))
    f.edit:SetText(pendingNotes[dropID] or (mine and mine.note) or "")
    f.send = function()
        local text = strtrim(f.edit:GetText() or "")
        if pending and text == "" then LC.Print(LC.Loc("A note is required for this response.")) return end
        f:Hide()
        if pending then
            Send(dropID, pending.id, text)
        elseif mine and mine.response then
            Send(dropID, mine.response, text ~= "" and text or nil)
        else
            pendingNotes[dropID] = text ~= "" and text or nil
            if text ~= "" then LC.Print(LC.Loc("Note saved. It is sent with the response you pick.")) end
            LootFrame.Refresh()
        end
    end
    f:Show()
    f.edit:SetFocus()
end

local function Respond(row, dropID, r)
    if expired then return end
    if r.needsNote and not pendingNotes[dropID] then OpenNote(row, dropID, r) return end
    Send(dropID, r.id, pendingNotes[dropID])
end

-- ---- build -------------------------------------------------------------
function LootFrame.Build()
    if frame or not (NSI.UI and NSI.UI.Window) then return end
    frame = Shell().Create({ name = "NSLCLootFrame", title = LC.Loc("Loot Council"), width = WIDTH, height = 120,
        point = { "TOP", 0, -140 }, growDown = true })
    frame:SetResizable(false)                       -- draggable only: no size grip
    if frame.resizeGrip then frame.resizeGrip:Hide(); frame.resizeGrip:EnableMouse(false) end
    bar = NSI.UI.Components.CreateProgressBar(frame, 100, BAR_H)
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, frame.contentTop - 2)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, frame.contentTop - 2)
    local acc = 0
    frame:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.2 then return end
        acc = 0
        UpdateBar()
    end)

    chip = NSI.UI.Components.CreateButton(UIParent, "", function() LootFrame.Reopen() end, 150, 24, "NSLCLootChip")
    chipFrame = chip.frame
    chipFrame:SetPoint("TOP", UIParent, "TOP", 0, -110)
    chipFrame:SetFrameStrata("HIGH")
    chipFrame:SetClampedToScreen(true)
    chipFrame:RegisterForDrag("RightButton")
    chipFrame:SetMovable(true)
    chipFrame:SetScript("OnDragStart", chipFrame.StartMoving)
    chipFrame:SetScript("OnDragStop", chipFrame.StopMovingOrSizing)
    -- The chip has no window OnUpdate to watch the clock while the window is hidden, so it ticks itself.
    local chipAcc = 0
    chipFrame:SetScript("OnUpdate", function(_, dt)
        chipAcc = chipAcc + dt
        if chipAcc < 0.5 then return end
        chipAcc = 0
        UpdateBar()
    end)
    chipFrame:Hide()
end

local function BuildRow(i)
    local C = NSI.UI.Components
    local card = Shell().Card(frame, nil)
    card:SetHeight(CARD_H)
    local row = card.content
    row.card = card
    row.item = C.CreateItemButton(row, ICON)
    row.item.frame:SetPoint("TOPLEFT", 0, 0)
    row.name = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.name, 14)
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", ICON + 8, -4)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.detail = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.detail, "small")
    row.detail:SetTextColor(0.65, 0.65, 0.65)
    row.detail:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -4)
    row.eqLabel = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.eqLabel, "small")
    row.eqLabel:SetTextColor(0.65, 0.65, 0.65)
    row.eqLabel:SetText(LC.Loc("Equipped:"))
    row.eq = {}
    for e = 2, 1, -1 do
        local b = C.CreateItemButton(row, 26)
        b.frame:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(e - 1) * 30, -2)
        b.frame:Hide()
        row.eq[e] = b
    end
    row.eqLabel:SetPoint("RIGHT", row.eq[2].frame, "LEFT", -6, 0)
    row.name:SetPoint("RIGHT", row.eqLabel, "LEFT", -8, 0)
    row.buttons = {}
    for b = 1, MAX_BTN do
        local btn
        btn = C.CreateButton(row, " ", function() if btn.action then btn.action() end end, BTN_W, 24)
        btn:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", ICON + 8 + (b - 1) * (BTN_W + BTN_GAP), 4)
        btn.frame:Hide()
        row.buttons[b] = btn
    end
    row.noteBtn = C.CreateButton(row, "", function() if row.dropID then OpenNote(row, row.dropID, nil) end end,
        30, 24, nil, NOTE_ICON)
    row.note = row.noteBtn.frame
    row.note:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 4)
    -- A bare icon like the header buttons of the main window: no box, accent colour on hover.
    C.StyleBareIconButton(row.noteBtn, 18)
    if row.note.SetBackdropBorderColor then row.note:SetBackdropBorderColor(0, 0, 0, 0) end
    -- With a note written the icon is tinted with the accent and hover shows the plain colour: the reverse
    -- of an empty note (like the shared / personal notes buttons of the main window). These hooks run
    -- after the kit's own hover hooks, so they have the last word.
    local STYLE = C.STYLE
    function row.PaintNote(hovered)
        local icon = row.note.icon
        if not icon then return end
        if row.hasNote ~= (hovered and true or false) then
            icon:SetVertexColor(STYLE.Accent(1))
        else
            icon:SetVertexColor(unpack(STYLE.text_color))
        end
    end
    row.note:HookScript("OnEnter", function() row.PaintNote(true) end)
    row.note:HookScript("OnLeave", function() row.PaintNote(false) end)
    row.note:HookScript("OnEnter", function(self)
        local text = row.dropID and (pendingNotes[row.dropID] or (MyResponse(row.dropID) or {}).note)
        NSI.UI.Tooltip.Show(self, { title = LC.Loc("Add a note for the council"), desc = (text and text ~= "") and text or nil }, "ANCHOR_LEFT")
    end)
    row.note:HookScript("OnLeave", function() NSI.UI.Tooltip.Hide() end)
    row.late = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.late, "small")
    row.late:SetTextColor(0.9, 0.3, 0.3)
    row.late:SetPoint("RIGHT", row.note, "LEFT", -8, 0)
    row.late:SetText(LC.Loc("No response"))
    return row
end

-- ---- refresh -----------------------------------------------------------
-- Once everything is answered the window closes itself. It comes back by itself when new loot needs an answer,
-- and on purpose through the session window's Loot button or /ns lc roll (reopened = stay open).
local autoClosed, reopened = false, false

function LootFrame.Refresh()
    if not (frame and chipFrame) or LC.dead then return end   -- chipFrame is the last thing Build makes
    local state = LC.Session.state
    if not (state and not state.closed and LC.Ruleset.IsActive()) then
        Shell().Hide(frame); chipFrame:Hide()
        return
    end
    local me = LC.Roster.MyKey()
    -- Items still needing an answer come first; answered ones go into the collapsible section below.
    local pending, voted = {}, {}
    for _, id in ipairs(state.order) do
        local drop = state.drops[id]
        if drop.state == "open" and not drop.allPassed and not autoPassed[id] then
            local mine = state.responses[id] and state.responses[id][me]
            if mine then voted[#voted + 1] = id else pending[#pending + 1] = id end
        end
    end
    local unanswered = #pending
    local total = #pending + #voted
    if total == 0 then Shell().Hide(frame); chipFrame:Hide() return end
    if expired then
        -- time is up: nothing can be answered any more, so the window closes for good, even a reopened one
        Shell().Hide(frame)
        autoClosed, frame.dismissed = true, true
        chipFrame:Hide()
        if flyout then flyout:Hide() end
        return
    end
    if unanswered > 0 then
        if not expired then reopened = false end
        if autoClosed and not expired then autoClosed = false; frame.dismissed = false end
    elseif not reopened then
        if not autoClosed then Shell().Hide(frame) end
        autoClosed, frame.dismissed = true, true
        chipFrame:Hide()
        return
    end

    local top = frame.contentTop - BAR_H - 10       -- y of the next block
    local function Place(id, i)
        local drop = state.drops[id]
        local row = rows[i] or BuildRow(i)
        rows[i] = row
        row.card:ClearAllPoints()
        row.card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, top)
        row.card:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
        top = top - (CARD_H + ROW_GAP)
        row.dropID = id
        local link = LC.Items.ToLink(drop.item)
        row.item:SetItem(link or drop.itemID)
        local name = link or C_Item.GetItemNameByID(drop.itemID) or tostring(drop.itemID)
        row.name:SetText(name)
        local _, _, _, equipLoc = C_Item.GetItemInfoInstant(drop.itemID)
        local ilvl = link and LC.Items.ItemLevel(link)
        local slot = equipLoc and equipLoc ~= "" and _G[equipLoc] or ""
        row.detail:SetText(table.concat({ ilvl and (LC.Loc("ilvl") .. " " .. ilvl) or "", slot }, "   "))
        local gear = LC.Preview and LC.Preview_.GearFor(me, equipLoc) or LC.Items.EquippedForEquipLoc(equipLoc)
        for e = 1, 2 do
            local g = gear[e]
            if g then row.eq[e]:SetItem(g.item, g.ilvl); row.eq[e].frame:Show() else row.eq[e]:Clear(); row.eq[e].frame:Hide() end
        end
        row.eqLabel:SetShown(#gear > 0)
        local list = LC.Ruleset.ResponsesFor(equipLoc)
        local mine = state.responses[id] and state.responses[id][me]
        for b = 1, MAX_BTN do
            local btn, r = row.buttons[b], list[b]
            if r then
                btn:SetText(LC.Loc(r.text) .. (r.needsNote and "*" or ""))
                btn.action = function() Respond(row, id, r) end
                local locked = expired and not mine
                btn.frame:SetAlpha(locked and 0.3 or ((mine and mine.response ~= r.id) and 0.5 or 1))
                btn.frame:Show()
            else
                btn.frame:Hide()
            end
        end
        local hasNote = pendingNotes[id] or (mine and mine.note and mine.note ~= "")
        row.hasNote = hasNote and true or false
        row.PaintNote(row.note:IsMouseOver())
        row.late:SetShown(expired and not mine)
        row.card:Show()
    end

    local shown = 0
    for _, id in ipairs(pending) do shown = shown + 1; Place(id, shown) end

    if not votedCard then
        votedCard = Shell().Card(frame, LC.Loc("Already voted"))
        votedCard:SetHeight(votedCard.headerH)
        -- The whole header row is the toggle: a transparent button over it, a hover wash, and a chevron.
        local STYLE = NSI.UI.Style
        local hb = CreateFrame("Button", nil, votedCard)
        hb:SetPoint("TOPLEFT", votedCard, "TOPLEFT", 1, -1)
        hb:SetPoint("TOPRIGHT", votedCard, "TOPRIGHT", -1, -1)
        hb:SetHeight(votedCard.headerH - 1)
        hb:SetFrameLevel(votedCard:GetFrameLevel() + 5)
        local wash = hb:CreateTexture(nil, "BACKGROUND")
        wash:SetAllPoints(); wash:Hide()
        STYLE.PaintAccent(wash, "SetColorTexture", STYLE.hover_color[4])   -- the Kit's accent hover fill
        local chev = hb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        chev:SetPoint("RIGHT", hb, "RIGHT", -12, 0)
        STYLE.PaintAccent(chev, "SetTextColor", 1)
        hb:SetScript("OnEnter", function() wash:Show() end)
        hb:SetScript("OnLeave", function() wash:Hide() end)
        hb:SetScript("OnClick", function() votedOpen = not votedOpen; LootFrame.Refresh() end)
        votedCard.headerToggle, votedCard.chevron = hb, chev
    end
    if #voted > 0 then
        votedCard.title:SetText(string.format(LC.Loc("Already voted (%d)"), #voted))
        votedCard.chevron:SetText(votedOpen and "-" or "+")
        votedCard:ClearAllPoints()
        votedCard:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, top)
        votedCard:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
        votedCard:Show()
        top = top - votedCard.headerH - ROW_GAP
        if votedOpen then
            for _, id in ipairs(voted) do shown = shown + 1; Place(id, shown) end
        end
    else
        votedCard:Hide()
    end
    for i = shown + 1, #rows do rows[i].card:Hide() end
    -- Grow downward: pin the top-left corner first, so a changed height never moves the top edge
    -- (a row answered away makes the next one slide up instead of the window re-centering).
    if frame:IsShown() and frame:GetLeft() and not (IsMouseButtonDown("LeftButton") and frame:IsMouseOver()) then
        local l, t = frame:GetLeft(), frame:GetTop()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
    end
    frame:SetHeight(-top + 4)
    if Shell().Show(frame) then
        chipFrame:Hide()
    else
        chip:SetText(string.format(LC.Loc("Loot: %d waiting"), unanswered))
        chipFrame:SetShown(unanswered > 0 and not expired)
    end
    UpdateBar()
end

function LootFrame.Reopen()
    if not (frame and chipFrame) or expired then return end    -- nothing to answer once the time is up
    chipFrame:Hide()
    autoClosed, reopened = false, true
    Shell().Reopen(frame)
    LootFrame.Refresh()
end

LC.On("NSRT_LC_SESSION_OPENED", function()
    expired, pendingNotes, autoPassed, votedOpen = false, {}, {}, false
    LC.BuildFrames()                               -- not built yet when the kit was not loaded at login
    autoClosed, reopened = false, false
    if frame then frame.dismissed = false end      -- a new session always shows the window once
    LootFrame.AutoPass()
    LootFrame.Refresh()
end)
for _, ev in ipairs({ "NSRT_LC_SESSION_UPDATED", "NSRT_LC_SESSION_CLOSED", "NSRT_LC_RULESET_CHANGED" }) do
    LC.On(ev, function() LootFrame.AutoPass(); LootFrame.Refresh() end)
end
LC.On("NSRT_LC_ENCOUNTER", function(starting)
    if starting then
        if frame then Shell().Hide(frame) end
        if chipFrame then chipFrame:Hide() end
        if flyout then flyout:Hide() end
    else
        LootFrame.Refresh()
    end
end)

function LootFrame.Shutdown()
    if frame then Shell().Hide(frame) end
    if chipFrame then chipFrame:Hide() end
    if flyout then flyout:Hide() end
end
LC.RegisterShutdown("LootFrame", LootFrame.Shutdown)
