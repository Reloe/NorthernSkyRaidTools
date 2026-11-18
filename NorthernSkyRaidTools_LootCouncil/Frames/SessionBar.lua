-- ============================================================
--  Frames/SessionBar.lua - small bar for the loot master / council (S-1)
--  While a session is open, for everyone in it: "Session in progress" with x of y awarded, a Loot
--  button that reopens your rolling window, and Council (council members and the loot master only).
--  Before one starts, if items are waiting in the queue and you are the loot master: "N items waiting"
--  plus Setup. "Take over" shows when the loot master has dropped. Draggable; the X hides it (it
--  returns with the next session).
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Bar = {}
LC.Frames.SessionBar = Bar
local frame, card, text, takeover, open, setup, loot, bar
local BAR_H = 14

-- Seconds left to answer, and the total; nil without a session. The preview never runs out.
local function TimeLeft()
    local rs, state = LC.Ruleset.Get(), LC.Session.state
    if not (rs and state and rs.timeout) then return nil, 0 end
    local left = LC.Session.TimeLeft(state, rs.timeout, GetServerTime())
    if LC.Preview and left and left <= 0 then left = rs.timeout end
    return left, rs.timeout
end
local function Expired()
    local left = TimeLeft()
    return left ~= nil and left <= 0
end

local function UpdateBar()
    if not (bar and bar.frame:IsShown()) then return end
    local left, total = TimeLeft()
    if not left then bar:SetFraction(0, true); bar:SetText("") return end
    local C = NSI.UI.Components
    if left <= 0 then bar:SetFraction(0); bar:SetText(LC.Loc("Time is up"))
    else
        bar:SetTimer(left, total)
        bar:SetText(string.format(LC.Loc("Time Left: %s"), C.ColorText(C.FormatDuration(math.ceil(left)), { 0, 1, 1 })))
    end
end

-- Taller card while a session is live (text and buttons, then the bar).
local function SetMode(live)
    card:SetHeight(LC.Frames.Shell.CardHeight(card, live and (24 + 6 + BAR_H) or 24))
    frame:SetHeight(-frame.contentTop + 6 + card:GetHeight() + 8)
    bar.frame:SetShown(live)
end

local function Shell() return LC.Frames.Shell end

function Bar.Build()
    if frame or not (NSI.UI and NSI.UI.Window) then return end
    local C = NSI.UI.Components
    frame = Shell().Create({ name = "NSLCSessionBar", title = LC.Loc("Loot"), width = 420, height = 90,
        point = { "TOP", 0, -60 } })
    frame:SetResizable(false)                       -- draggable only: no size grip
    if frame.resizeGrip then frame.resizeGrip:Hide(); frame.resizeGrip:EnableMouse(false) end
    card = Shell().Card(frame, nil)
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, frame.contentTop - 6)
    card:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    local body = card.content
    text = body:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(text, 12)
    text:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    text:SetHeight(24)
    text:SetJustifyV("MIDDLE")
    bar = C.CreateProgressBar(body, 100, BAR_H)
    bar:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    SetMode(false)
    local acc = 0
    frame:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.2 then return end
        acc = 0
        UpdateBar()
    end)
    open = C.CreateButton(body, LC.Loc("Council"), function()
        if LC.EnsureUI() then LC.UI.Open() end
    end, 76, 24)
    open:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    setup = C.CreateButton(body, LC.Loc("Setup"), function() LC.Frames.SetupFrame.Open() end, 76, 24)
    setup:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    -- Greyed out once the time to answer is up: nobody can change a response any more.
    loot = C.CreateButton(body, LC.Loc("Loot"), function() LC.Frames.LootFrame.Reopen() end, 76, 24,
        nil, nil, nil, nil, function() return not Expired() end)
    takeover = C.CreateButton(body, LC.Loc("Take over"), function() LC.Session.Claim() end, 80, 24)
    takeover.frame:Hide()
    text:SetPoint("RIGHT", body, "RIGHT", -168, 0)
    text:SetWordWrap(false)
    text:SetJustifyH("LEFT")
end

-- Buttons sit in a row from the right edge: Council, Loot, Take over (only the ones shown).
local function Layout(list)
    local prev
    for _, b in ipairs(list) do
        b.frame:ClearAllPoints()
        if prev then b.frame:SetPoint("TOPRIGHT", prev.frame, "TOPLEFT", -4, 0)
        else b.frame:SetPoint("TOPRIGHT", b.frame:GetParent(), "TOPRIGHT", 0, 0) end
        prev = b
    end
end

function Bar.Refresh()
    if not frame or LC.dead then return end
    local state = LC.Session.state
    local isML = LC.Ruleset.IAmML()
    if state and state.guid and not state.closed then
        local total, done = 0, 0
        for _, id in ipairs(state.order) do
            total = total + 1
            if state.awards[id] then done = done + 1 end
        end
        frame:SetTitle("|cff33ff66" .. LC.Loc("Session is Live") .. "|r")
        text:SetText(string.format(LC.Loc("%d of %d items awarded"), done, total))
        SetMode(true)
        UpdateBar()
        if loot.RefreshCondition then loot:RefreshCondition() end
        local council = LC.Ruleset.IAmCouncil() or isML or LC.Session.CanClose()
        open.frame:SetShown(council); setup.frame:Hide(); loot.frame:Show()
        local row = { }
        if council then row[#row + 1] = open end
        row[#row + 1] = loot
        if takeover.frame:IsShown() then row[#row + 1] = takeover end
        Layout(row)
        LC.Frames.Shell.Show(frame)
        return
    end
    local waiting = isML and LC.Ruleset.IsActive() and LC.Queue.Count() or 0
    if waiting > 0 and not (state and not state.closed) then
        SetMode(false)
        frame:SetTitle(LC.Loc("Loot"))
        text:SetText(string.format(LC.Loc("%d items waiting for a session"), waiting))
        open.frame:Hide(); loot.frame:Hide(); setup.frame:Show(); takeover.frame:Hide()
        LC.Frames.Shell.Show(frame)
        return
    end
    Shell().Hide(frame)
end

LC.On("NSRT_LC_TAKEOVER_AVAILABLE", function() if takeover then takeover.frame:Show() end end)
LC.On("NSRT_LC_SESSION_OPENED", function() if frame then frame.dismissed = false end end)
for _, ev in ipairs({ "NSRT_LC_SESSION_UPDATED", "NSRT_LC_SESSION_OPENED", "NSRT_LC_SESSION_CLOSED", "NSRT_LC_RULESET_CHANGED", "NSRT_LC_QUEUE_CHANGED" }) do
    LC.On(ev, function()
        if takeover and LC.Session.state and LC.Roster.IsOnline(LC.Session.state.ml) then takeover.frame:Hide() end
        Bar.Refresh()
    end)
end
LC.On("NSRT_LC_ENCOUNTER", function(starting) if starting and frame then Shell().Hide(frame) else Bar.Refresh() end end)
function Bar.Shutdown() if frame then Shell().Hide(frame) end end
LC.RegisterShutdown("SessionBar", Bar.Shutdown)
