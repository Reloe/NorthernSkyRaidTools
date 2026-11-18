-- ============================================================
--  Frames/SessionBar.lua - slim session strip (S-1)
--
--      [timer bar]                                   council members and the loot master only
--      (o) Live      3 of 7 items awarded      [Loot] [Council] X
--
--  Two states while a session is open:
--    Live    green dot: raiders are still answering. The bar above counts down the response time.
--    Voting  orange dot: the time to answer is up and the council is voting. The bar is empty.
--  The countdown bar only exists for the council and the loot master; a raider has the response window for that
--  and does not need it here. Loot reopens your response window (greyed once the time is up), Council opens the
--  council window (council and loot master only).
--  Before a session starts, the loot master sees "N items waiting for a session" and Setup. "Take over" shows when
--  the loot master has dropped. Draggable; the X hides it (it returns with the next session).
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Bar = {}
LC.Frames.SessionBar = Bar
local frame, strip, dot, state_label, text, bar, closeBtn
local takeover, open, setup, loot
local BAR_H, STRIP_H, PAD, GAP = 4, 26, 2, 2
local WIDTH = 520
local LIVE_COLOR, VOTING_COLOR, IDLE_COLOR = { 0.2, 1, 0.4 }, { 1, 0.5, 0.1 }, { 0.65, 0.65, 0.65 }
local voting = false              -- the state shown last, so the strip flips by itself when the timer runs out
local showBar = false

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
    if not (bar and showBar) then return end
    local left, total = TimeLeft()
    if not left or left <= 0 then bar:SetFraction(0, true) return end
    bar:SetTimer(left, total)
end

local function Shell() return LC.Frames.Shell end

-- Same top-left pinning as the response window: a changed height never moves the top edge.
local function SetHeight(h)
    if frame:IsShown() and frame:GetLeft() and not (IsMouseButtonDown("LeftButton") and frame:IsMouseOver()) then
        local l, t = frame:GetLeft(), frame:GetTop()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
    end
    frame:SetHeight(h)
end

local function SetColor(c)
    dot:SetVertexColor(c[1], c[2], c[3])
    state_label:SetTextColor(c[1], c[2], c[3])
end

-- Taller with the countdown bar on top (council / loot master in a live session).
local function SetMode(withBar)
    showBar = withBar
    bar.frame:SetShown(withBar)
    strip:ClearAllPoints()
    strip:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
    strip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    strip:SetHeight(STRIP_H)
    SetHeight(PAD * 2 + STRIP_H + (withBar and (BAR_H + GAP) or 0))
end

function Bar.Build()
    if frame or not (NSI.UI and NSI.UI.Window) then return end
    local C = NSI.UI.Components
    frame = Shell().Create({ name = "NSLCSessionBar", title = "", width = WIDTH, height = PAD * 2 + STRIP_H,
        point = { "TOP", 0, -60 }, growDown = true })
    frame:SetResizable(false)                       -- draggable only: no size grip
    if frame.resizeGrip then frame.resizeGrip:Hide(); frame.resizeGrip:EnableMouse(false) end
    if frame.TitleBar then frame.TitleBar:Hide() end    -- no title bar: the strip is the whole window

    bar = C.CreateProgressBar(frame, 100, BAR_H)
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD)
    bar:SetText("")

    strip = CreateFrame("Frame", nil, frame)
    local bg = strip:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.95)

    -- a round status dot: a flat square cut by the portrait mask
    dot = strip:CreateTexture(nil, "ARTWORK")
    dot:SetSize(12, 12)
    dot:SetPoint("LEFT", strip, "LEFT", 8, 0)
    dot:SetTexture([[Interface\Buttons\WHITE8X8]])
    local mask = strip:CreateMaskTexture()
    mask:SetTexture([[Interface\CHARACTERFRAME\TempPortraitAlphaMask]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(dot)
    dot:AddMaskTexture(mask)
    state_label = strip:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(state_label, 12)
    state_label:SetPoint("LEFT", dot, "RIGHT", 6, 0)
    text = strip:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(text, 12)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)

    -- X: hides the strip (the shell remembers it was closed by hand). The same bare x icon as the window headers.
    local closeObj = C.CreateButton(strip, "", function() frame:Hide() end, 22, STRIP_H - 4, nil,
        [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
    C.StyleBareIconButton(closeObj, 14)
    closeBtn = closeObj.frame
    closeBtn:SetPoint("RIGHT", strip, "RIGHT", -4, 0)

    local BW, BH = 64, 20
    open = C.CreateButton(strip, LC.Loc("Council"), function()
        if LC.EnsureUI() then LC.UI.Open() end
    end, BW, BH)
    setup = C.CreateButton(strip, LC.Loc("Setup"), function() LC.Frames.SetupFrame.Open() end, BW, BH)
    -- Greyed out once the time to answer is up: nobody can change a response any more.
    loot = C.CreateButton(strip, LC.Loc("Loot"), function() LC.Frames.LootFrame.Reopen() end, BW, BH,
        nil, nil, nil, nil, function() return not Expired() end)
    takeover = C.CreateButton(strip, LC.Loc("Take over"), function() LC.Session.Claim() end, 76, BH)
    takeover.frame:Hide()

    SetMode(false)
    local acc = 0
    frame:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.2 then return end
        acc = 0
        -- the strip flips from Live to Voting by itself when the response time runs out
        if LC.Session.state and not LC.Session.state.closed and Expired() ~= voting then Bar.Refresh() return end
        UpdateBar()
    end)
end

-- Buttons sit in a row from the right edge, left of the X; the text fills what is left of them.
local function Layout(list)
    local prev
    for _, b in ipairs(list) do
        b.frame:ClearAllPoints()
        if prev then b.frame:SetPoint("RIGHT", prev.frame, "LEFT", -4, 0)
        else b.frame:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0) end
        prev = b
    end
    text:ClearAllPoints()
    text:SetPoint("LEFT", state_label, "RIGHT", 10, 0)
    text:SetPoint("RIGHT", prev and prev.frame or closeBtn, "LEFT", -10, 0)
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
        voting = Expired()
        if voting then
            SetColor(VOTING_COLOR); state_label:SetText(LC.Loc("Voting"))
        else
            SetColor(LIVE_COLOR); state_label:SetText(LC.Loc("Live"))
        end
        text:SetText(string.format(LC.Loc("%d of %d items awarded"), done, total))
        local council = LC.Ruleset.IAmCouncil() or isML or LC.Session.CanClose()
        SetMode(council)                              -- the countdown bar is for the council only
        UpdateBar()
        if loot.RefreshCondition then loot:RefreshCondition() end
        open.frame:SetShown(council); setup.frame:Hide(); loot.frame:Show()
        local row = {}
        if council then row[#row + 1] = open end
        row[#row + 1] = loot
        if takeover.frame:IsShown() then row[#row + 1] = takeover end
        Layout(row)
        LC.Frames.Shell.Show(frame)
        return
    end
    voting = false
    local waiting = isML and LC.Ruleset.IsActive() and LC.Queue.Count() or 0
    if waiting > 0 and not (state and not state.closed) then
        SetMode(false)
        SetColor(IDLE_COLOR); state_label:SetText(LC.Loc("Ready"))
        text:SetText(string.format(LC.Loc("%d items waiting for a session"), waiting))
        open.frame:Hide(); loot.frame:Hide(); setup.frame:Show(); takeover.frame:Hide()
        Layout({ setup })
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
