-- ============================================================
--  EditModeElements.lua  -  what the layout editor can move
--
--  One registration per display (see EditMode.lua for the spec). Every display keeps
--  its own stored position (Anchor / relativeTo / xOffset / yOffset); the adapters here
--  only read and write that format and start / stop the display's preview while the
--  editor is open. Aura Tracking anchors and encounter alert frames are not listed on
--  purpose: they keep their own anchoring.
-- ============================================================

local NSI = _G.NorthernSkyRaidTools
local EditMode = NSI.UI.EditMode

local GROUP_REMINDERS = "Reminder Anchors"
local GROUP_NOTES     = "Notes"
local GROUP_OTHER     = "Other Displays"

-- ---- shared helpers -----------------------------------------------------
-- Re-anchor a frame to whatever frame it is already anchored to (UIParent or the
-- addon's full-screen frame), so only the point and offsets change.
local function Reanchor(frame, point, rel, x, y)
    if not frame then return end
    local _, relFrame = frame:GetPoint(1)
    frame:ClearAllPoints()
    frame:SetPoint(point, relFrame or UIParent, rel, x, y)
end

local function ReadPos(s)
    return s.Anchor or "CENTER", s.relativeTo or s.Anchor or "CENTER", s.xOffset or 0, s.yOffset or 0
end

local function WritePos(s, point, rel, x, y)
    s.Anchor, s.relativeTo, s.xOffset, s.yOffset = point, rel, x, y
end

-- Settings-backed display: getSettings() -> table, getFrame() -> frame or nil.
local function Positioned(getSettings, getFrame)
    return {
        getPos = function() return ReadPos(getSettings()) end,
        setPos = function(point, rel, x, y)
            WritePos(getSettings(), point, rel, x, y)
            Reanchor(getFrame(), point, rel, x, y)
        end,
    }
end

local function Register(spec, positioned)
    spec.getPos, spec.setPos = positioned.getPos, positioned.setPos
    EditMode.Register(spec)
end

local function RS() return NSRT.ReminderSettings end

-- ---- reminder previews --------------------------------------------------
-- All five anchor types share one preview (SpawnPreviewReminders); a request to
-- refresh it is coalesced into one call per frame, because opening the editor enters
-- every type at once.
local respawnPending = false
local function Respawn()
    if respawnPending then return end
    respawnPending = true
    C_Timer.After(0, function()
        respawnPending = false
        if NSI.LayoutEditorActive and NSI.IsInPreview then NSI:SpawnPreviewReminders() end
    end)
end

EditMode.RegisterSession({
    onOpen = function()
        NSI:CreateMoveFrames()          -- anchors and notes exist even if never shown before
        NSI.IsInPreview = true
    end,
    onClose = function()
        if NSI.PreviewTicker then NSI.PreviewTicker:Cancel(); NSI.PreviewTicker = nil end
        NSI.IsInPreview = false
        NSI:HideAllReminders()
    end,
})

local ANCHORS = {
    { key = "reminder_icon",   label = "Icons",           mover = "IconMover",           settings = "IconSettings" },
    { key = "reminder_bar",    label = "Bars",            mover = "BarMover",            settings = "BarSettings" },
    { key = "reminder_text",   label = "Texts",           mover = "TextMover",           settings = "TextSettings" },
    { key = "reminder_circle", label = "Circles",         mover = "CircleMover",         settings = "CircleSettings" },
    { key = "reminder_debuff", label = "Debuff Overview", mover = "DebuffOverviewMover", settings = "DebuffOverviewSettings" },
}
local ANCHOR_MOVERS = { "IconMover", "BarMover", "TextMover", "CircleMover", "DebuffOverviewMover" }

for _, a in ipairs(ANCHORS) do
    local function settings() return RS()[a.settings] end
    local function frame() return NSI[a.mover] end
    Register({
        key = a.key, label = a.label, group = GROUP_REMINDERS,
        frame = frame,
        onEnter = function()
            NSI:MakeDraggable(frame(), settings(), true)       -- preview visuals only while editing
            Respawn()
        end,
        onExit = function()
            NSI:MakeDraggable(frame(), nil, false)
            Respawn()
        end,
        gear = function()
            for _, n in ipairs(ANCHOR_MOVERS) do
                local other = NSI[n]
                if other and other ~= frame() and other.SettingsWindow then other.SettingsWindow:Hide() end
            end
            if NSI.CreateAnchorSettingsWindow and frame() then
                NSI:CreateAnchorSettingsWindow(frame(), a.settings)
            end
        end,
    }, Positioned(settings, frame))
end

-- ---- the three notes ----------------------------------------------------
local NOTES = {
    { key = "note_shared",   label = "All Reminders Note",      name = "ReminderFrame",         shared = true },
    { key = "note_personal", label = "Personal Reminders Note", name = "PersonalReminderFrame", personal = true },
    { key = "note_extra",    label = "Text Note",               name = "ExtraReminderFrame",    extra = true },
}

for _, n in ipairs(NOTES) do
    local function settings() return RS()[n.name] end
    local function frame() return NSI[n.name .. "Mover"] end
    local pos = Positioned(settings, frame)
    local spec = {
        key = n.key, label = n.label, group = GROUP_NOTES,
        frame = frame,
        unavailable = function()
            local s = settings()
            if not (s and s.enabled) then return "disabled" end
        end,
        resize = {
            min = 100,
            get = function() local s = settings(); return s.Width or 200, s.Height or 100 end,
            set = function(w, h)
                local s = settings()
                s.Width, s.Height = w, h
                local mover = frame()
                if mover then mover:SetSize(w, h) end
                local note = NSI[n.name]
                if note and note.Text then note.Text:SetWidth(w) end
            end,
        },
        onEnter = function()
            local mover = frame()
            if mover then NSI:MakeDraggable(mover, settings(), true, true) end
        end,
        onExit = function()
            local mover = frame()
            if not mover then return end
            NSI:MakeDraggable(mover, settings(), false, true)
            NSI:UpdateReminderFrame(false, n.shared, n.personal, n.extra)   -- put the real text back
        end,
    }
    Register(spec, pos)
end

-- ---- other displays -----------------------------------------------------
-- Interrupt display: preview toggles, so only start it when it is not already shown.
Register({
    key = "interrupt", label = "Interrupt Display", group = GROUP_OTHER,
    frame = function() return NSI.InterruptDisplay end,
    onEnter = function()
        if not (NSI.InterruptDisplay and NSI.InterruptDisplay:IsShown()) then NSI:PreviewInterruptDisplay() end
    end,
    onExit = function()
        NSI:MakeDraggable(NSI.InterruptDisplay, nil, false)
        NSI:HideInterrupt()
    end,
}, Positioned(function() return NSRT.InterruptSettings end, function() return NSI.InterruptDisplay end))

-- Pace comparison: its own gear button is hidden while editing; the editor's gear
-- opens the same settings window.
Register({
    key = "pace", label = "Pace Comparison", group = GROUP_OTHER,
    frame = function() return NSI.PaceComparisonFrame end,
    onEnter = function()
        if not NSI.PaceComparisonPreview then NSI:PreviewPaceComparison() end
        local f = NSI.PaceComparisonFrame
        if f and f.GearButton then f.GearButton:Hide() end
    end,
    onExit = function()
        if NSI.PaceComparisonPreview then NSI:PreviewPaceComparison() end
    end,
    gear = function()
        local f = NSI.PaceComparisonFrame
        if f and NSI.TogglePaceComparisonSettingsWindow then NSI:TogglePaceComparisonSettingsWindow(f) end
    end,
}, Positioned(function() return NSRT.PaceComparison.Display end, function() return NSI.PaceComparisonFrame end))

Register({
    key = "break", label = "Break Timer", group = GROUP_OTHER,
    frame = function() return NSI.BreakTimerFrame end,
    onEnter = function() NSI:SetBreakTimerPreview(true) end,
    onExit = function() NSI:SetBreakTimerPreview(false) end,
}, Positioned(function() return NSRT.BreakTimer end, function() return NSI.BreakTimerFrame end))

-- Player stats can be anchored to another frame in Aura Tracking; offsets from another
-- frame cannot be edited as screen positions, so it stays there.
Register({
    key = "stats", label = "Player Stats", group = GROUP_OTHER,
    frame = function() return NSI.NSRTFrame and NSI.NSRTFrame.PlayerStatsDisplay end,
    unavailable = function()
        local name = NSRT.PlayerStatsDisplay and NSRT.PlayerStatsDisplay.CustomAnchorFrame
        if name and name ~= "" and name ~= "UIParent" then return "anchored to another frame" end
    end,
    onEnter = function() NSI:SetPlayerStatsPreview(true) end,
    onExit = function() NSI:SetPlayerStatsPreview(false) end,
}, Positioned(function() return NSRT.PlayerStatsDisplay end,
              function() return NSI.NSRTFrame and NSI.NSRTFrame.PlayerStatsDisplay end))

Register({
    key = "qol", label = "QoL Text", group = GROUP_OTHER,
    frame = function() return NSI.NSRTFrame and NSI.NSRTFrame.QoLText end,
    onEnter = function() NSI.IsQoLTextPreview = true; NSI:ToggleQoLTextPreview() end,
    onExit = function() NSI.IsQoLTextPreview = false; NSI:ToggleQoLTextPreview() end,
}, Positioned(function() return NSRT.QoL.TextDisplay end,
              function() return NSI.NSRTFrame and NSI.NSRTFrame.QoLText end))

-- The generic text display (ready check module, assignments on pull).
Register({
    key = "generic", label = "Generic Text Display", group = GROUP_OTHER,
    frame = function() return NSI.NSRTFrame and NSI.NSRTFrame.generic_display end,
    onEnter = function()
        local F = NSI.NSRTFrame and NSI.NSRTFrame.generic_display
        if not F then return end
        F.Text:SetText(NSI:Loc("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n"))
        F:SetSize(F.Text:GetStringWidth(), F.Text:GetStringHeight())
        NSI:MakeDraggable(F, NSRT.Settings.GenericDisplay, true)
    end,
    onExit = function()
        NSI:MakeDraggable(NSI.NSRTFrame and NSI.NSRTFrame.generic_display, nil, false)
    end,
}, Positioned(function() return NSRT.Settings.GenericDisplay end,
              function() return NSI.NSRTFrame and NSI.NSRTFrame.generic_display end))
