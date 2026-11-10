-- ============================================================
--  EditMode.lua  -  the layout editor
--
--  One place to position every screen-anchored display: reminder anchors, the three
--  notes, Interrupt Display, Pace Comparison, Break Timer, Player Stats and the QoL
--  text. A dimmed pixel grid, a draggable overlay ("mover") over each display,
--  snapping to the grid and to other displays with alignment guides, arrow-key
--  nudging, a resize grip where a display has a size, and a session the player can
--  Save or Cancel. The panel also lists every display with a checkbox to show or hide
--  it while editing (an editing aid only; it never enables or disables a module).
--
--  Not covered on purpose: Aura Tracking anchors and encounter alert frames keep
--  their own anchoring.
--
--  Displays are registered in EditModeElements.lua:
--    EditMode.Register{
--      key, label, group,
--      frame()            -> the frame to cover, or nil when it does not exist
--      unavailable()      -> optional: a reason string when it cannot be moved now
--      getPos()           -> point, relativePoint, x, y   (as stored)
--      setPos(point, relativePoint, x, y)                 store and apply live
--      resize             optional { get() -> w, h, set(w, h), min = n }
--      gear()             optional: opens the display's own settings window
--      onEnter(), onExit()  show / hide the display's preview while editing
--    }
--    EditMode.RegisterSession{ onOpen = fn, onClose = fn }   once per session
--
--  Rules it follows: nothing is built until the first open; mouse scripts never go on
--  the real frames (overlays sit on top and are anchored to them); it refuses to open
--  in combat and cancels the session if combat starts; the geometry is all in UIParent units and
--  stored offsets are pixel-snapped; Cancel and Escape restore the exact layout.
--  Positions keep the stored format (Anchor / relativeTo / xOffset / yOffset); a saved
--  position is converted to the nearest of nine screen regions the first time the
--  display is moved.
-- ============================================================

local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local PP = NSI.UI.PP
local Pixel = NSI.UI.Pixel
local Components = NSI.UI.Components
local Accent = STYLE.Accent

local floor, abs, min, max = math.floor, math.abs, math.min, math.max
local pairs, ipairs, type = pairs, ipairs, type
local GetCursorPosition, IsShiftKeyDown, InCombatLockdown = GetCursorPosition, IsShiftKeyDown, InCombatLockdown

local EditMode = {}
NSI.UI.EditMode = EditMode

local WHITE     = [[Interface\Buttons\WHITE8X8]]
local GEAR_ICON = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\settings.png]]
local GRIP_ICON = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]]

local GRID_PX   = 32     -- grid spacing, physical pixels
local SNAP_PX   = 8      -- snap distance, physical pixels
local DRAG_PX   = 3      -- cursor travel before a press becomes a drag
local NUDGE_BIG = 10     -- Shift + arrow, physical pixels
local HUD_W     = 520

-- Saved with the window settings (not the profile): grid and snap switches and which
-- displays the player has hidden from the editor.
local function Prefs()
    NSRT.NSUI = NSRT.NSUI or {}
    local p = NSRT.NSUI.editMode
    if type(p) ~= "table" then p = {}; NSRT.NSUI.editMode = p end
    if p.grid == nil then p.grid = true end
    if p.snap == nil then p.snap = true end
    if type(p.hidden) ~= "table" then p.hidden = {} end
    return p
end

-- --------------------------------------------------------------------------
--  Registry
-- --------------------------------------------------------------------------
local specs, order, sessions = {}, {}, {}

function EditMode.Register(spec)
    if not specs[spec.key] then order[#order + 1] = spec end
    specs[spec.key] = spec
end

function EditMode.RegisterSession(hook)
    sessions[#sessions + 1] = hook
end

-- --------------------------------------------------------------------------
--  Geometry, all in UIParent units
-- --------------------------------------------------------------------------
local function Ratio(frame)
    return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

-- Centre x, centre y, half width, half height of a frame in UIParent units.
local function RectOf(frame)
    local cx, cy = frame:GetCenter()
    if not cx then return nil end
    local k = Ratio(frame)
    return cx * k, cy * k, frame:GetWidth() * k / 2, frame:GetHeight() * k / 2
end

local function CursorUI()
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    return x / s, y / s
end

-- Nine-region anchoring: the offset is measured from the nearest screen edge (or the
-- centre on a centred axis), so a layout survives a resolution or UI scale change.
local function ToAnchor(cx, cy, hw, hh)
    local W, H = UIParent:GetWidth(), UIParent:GetHeight()
    local h = (cx < W / 3 and "LEFT") or (cx > W * 2 / 3 and "RIGHT") or ""
    local v = (cy > H * 2 / 3 and "TOP") or (cy < H / 3 and "BOTTOM") or ""
    local point = v .. h
    if point == "" then point = "CENTER" end
    local x, y
    if h == "LEFT" then x = PP.Snap(cx - hw, UIParent)
    elseif h == "RIGHT" then x = PP.Snap(cx + hw - W, UIParent)
    else x = PP.SnapCenter(cx, hw * 2, UIParent) - PP.SnapCenter(W / 2, 0, UIParent) end
    if v == "TOP" then y = PP.Snap(cy + hh - H, UIParent)
    elseif v == "BOTTOM" then y = PP.Snap(cy - hh, UIParent)
    else y = PP.SnapCenter(cy, hh * 2, UIParent) - PP.SnapCenter(H / 2, 0, UIParent) end
    return point, x, y
end

-- --------------------------------------------------------------------------
--  Session state
-- --------------------------------------------------------------------------
local root, hud, grid, keys, guideV, guideH
local movers = {}          -- key -> mover frame
local snapshot = {}        -- key -> { point, rel, x, y, w, h } at open
local active = false
local selected, dragging
local reopenOptions = false
local checks, checkHeadings = {}, {}
local gridButton, snapButton, listFrame, checklistBuilt

local function Loc(text) return NSI:Loc(text) end

-- --------------------------------------------------------------------------
--  Grid: one frame behind the game UI with 1px lines laid out from the screen centre
--  outward, so the two centre lines always exist. Lines are pooled.
-- --------------------------------------------------------------------------
local lines, lineCount = {}, 0

local function Line(isVertical, pos, alpha)
    lineCount = lineCount + 1
    local tex = lines[lineCount]
    if not tex then
        tex = grid:CreateTexture(nil, "BACKGROUND", nil, 1)
        PP.NoSnap(tex)
        lines[lineCount] = tex
    end
    tex:SetColorTexture(Accent(alpha))
    tex:ClearAllPoints()
    local one = PP.Pixels(1, UIParent)
    if isVertical then
        tex:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos, UIParent:GetHeight())
        tex:SetSize(one, UIParent:GetHeight())
    else
        tex:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, pos)
        tex:SetSize(UIParent:GetWidth(), one)
    end
    tex:Show()
end

local function LayoutGrid()
    if not grid then return end
    lineCount = 0
    local W, H = UIParent:GetWidth(), UIParent:GetHeight()
    local step = GRID_PX * PP.Pixel(UIParent)
    local cx, cy = PP.Snap(W / 2, UIParent), PP.Snap(H / 2, UIParent)
    local k = 1
    while cx - k * step > 0 or cx + k * step < W do
        if cx - k * step > 0 then Line(true, PP.Snap(cx - k * step, UIParent), 0.10) end
        if cx + k * step < W then Line(true, PP.Snap(cx + k * step, UIParent), 0.10) end
        k = k + 1
    end
    k = 1
    while cy - k * step > 0 or cy + k * step < H do
        if cy - k * step > 0 then Line(false, PP.Snap(cy - k * step, UIParent), 0.10) end
        if cy + k * step < H then Line(false, PP.Snap(cy + k * step, UIParent), 0.10) end
        k = k + 1
    end
    Line(true, cx, 0.45)       -- centre lines read stronger
    Line(false, cy, 0.45)
    for i = lineCount + 1, #lines do lines[i]:Hide() end
end

local function BuildGrid()
    grid = CreateFrame("Frame", nil, UIParent)
    grid:SetFrameStrata("BACKGROUND")      -- behind the real UI: the world dims, the displays do not
    grid:SetFrameLevel(0)
    grid:SetAllPoints(UIParent)
    local scrim = grid:CreateTexture(nil, "BACKGROUND", nil, -8)
    scrim:SetAllPoints()
    scrim:SetColorTexture(0, 0, 0, 0.35)
    grid:Hide()
end

-- --------------------------------------------------------------------------
--  Snapping: compare the dragged rect's left/centre/right (and bottom/centre/top)
--  with every other visible mover's, keep the closest pair per axis within SNAP_PX,
--  then fall back to the nearest grid line.
-- --------------------------------------------------------------------------
local dragEdges, targetEdges = { 0, 0, 0 }, { 0, 0, 0 }   -- reused: no garbage per frame

local function BestAxis(a1, a2, a3, b1, b2, b3, best, bestD, line)
    dragEdges[1], dragEdges[2], dragEdges[3] = a1, a2, a3
    targetEdges[1], targetEdges[2], targetEdges[3] = b1, b2, b3
    for i = 1, 3 do
        for j = 1, 3 do
            local d = targetEdges[j] - dragEdges[i]
            if abs(d) < bestD then best, bestD, line = d, abs(d), targetEdges[j] end
        end
    end
    return best, bestD, line
end

local function NearestGrid(v, center, step)
    return center + floor((v - center) / step + 0.5) * step
end

local function Snap(key, cx, cy, hw, hh)
    local prefs = Prefs()
    if not prefs.snap or IsShiftKeyDown() then return cx, cy end
    local limit = SNAP_PX * PP.Pixel(UIParent)
    local dx, dX, lineX = 0, limit, nil
    local dy, dY, lineY = 0, limit, nil
    for otherKey, m in pairs(movers) do
        if otherKey ~= key and m:IsShown() then
            local l, r, t, b = m:GetLeft(), m:GetRight(), m:GetTop(), m:GetBottom()
            if l then
                dx, dX, lineX = BestAxis(cx - hw, cx, cx + hw, l, (l + r) / 2, r, dx, dX, lineX)
                dy, dY, lineY = BestAxis(cy - hh, cy, cy + hh, b, (b + t) / 2, t, dy, dY, lineY)
            end
        end
    end
    local guideX, guideY
    if lineX then cx = cx + dx; guideX = lineX end
    if lineY then cy = cy + dy; guideY = lineY end
    if prefs.grid then
        local step = GRID_PX * PP.Pixel(UIParent)
        local gx, gy = UIParent:GetWidth() / 2, UIParent:GetHeight() / 2
        if not guideX then
            local d = NearestGrid(cx - hw, gx, step) - (cx - hw)
            if abs(d) < limit then cx = cx + d end
        end
        if not guideY then
            local d = NearestGrid(cy - hh, gy, step) - (cy - hh)
            if abs(d) < limit then cy = cy + d end
        end
    end
    return cx, cy, guideX, guideY
end

local function ShowGuides(gx, gy)
    local one = PP.Pixels(1, UIParent)
    if gx then
        guideV:ClearAllPoints()
        guideV:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", gx, 0)
        guideV:SetSize(one, UIParent:GetHeight())
        guideV:Show()
    else
        guideV:Hide()
    end
    if gy then
        guideH:ClearAllPoints()
        guideH:SetPoint("LEFT", UIParent, "BOTTOMLEFT", 0, gy)
        guideH:SetSize(UIParent:GetWidth(), one)
        guideH:Show()
    else
        guideH:Hide()
    end
end

-- --------------------------------------------------------------------------
--  Movers
-- --------------------------------------------------------------------------
local function PaintMover(m)
    local alpha = (m == selected and 0.35) or (m:IsMouseOver() and 0.28) or 0.18
    m.fill:SetColorTexture(Accent(alpha))
    m.border:SetBorderColor(Accent((m == selected) and 1 or 0.6))
end

local function Select(m)
    local old = selected
    selected = m
    if old and old ~= m then PaintMover(old) end
    if m then PaintMover(m) end
    if keys then keys:SetShown(m ~= nil) end
end

local function Apply(m, cx, cy, hw, hh)
    local point, x, y = ToAnchor(cx, cy, hw, hh)
    specs[m.key].setPos(point, point, x, y)
end

local function DragUpdate(m)
    local x, y = CursorUI()
    local px = PP.Pixel(UIParent)
    if not dragging then
        if abs(x - m.downX) < DRAG_PX * px and abs(y - m.downY) < DRAG_PX * px then
            return                                              -- still a click
        end
        dragging = m
        m.axis = nil
    end
    local cx = m.startX + (x - m.downX)
    local cy = m.startY + (y - m.downY)
    if IsShiftKeyDown() then                                    -- Shift: lock to the first axis moved
        m.axis = m.axis or ((abs(x - m.downX) >= abs(y - m.downY)) and "X" or "Y")
        if m.axis == "X" then cy = m.startY else cx = m.startX end
    else
        m.axis = nil
    end
    local hw, hh = m.hw, m.hh
    local gx, gy
    cx, cy, gx, gy = Snap(m.key, cx, cy, hw, hh)
    cx = max(hw, min(UIParent:GetWidth() - hw, cx))             -- keep it on screen
    cy = max(hh, min(UIParent:GetHeight() - hh, cy))
    ShowGuides(gx, gy)
    Apply(m, cx, cy, hw, hh)
end

local function MoverDown(m, button)
    if button ~= "LeftButton" or InCombatLockdown() then return end
    local frame = specs[m.key].frame()
    if not frame then return end
    Select(m)
    local cx, cy, hw, hh = RectOf(frame)
    if not cx then return end
    m.startX, m.startY, m.hw, m.hh = cx, cy, hw, hh
    m.downX, m.downY = CursorUI()
    m:SetScript("OnUpdate", DragUpdate)                         -- only while the button is held
end

local function MoverUp(m)
    m:SetScript("OnUpdate", nil)
    dragging = nil
    guideV:Hide()
    guideH:Hide()
end

local function MoverEnter(m)
    PaintMover(m)
    GameTooltip:SetOwner(m, "ANCHOR_TOP")
    GameTooltip:SetText(Loc(specs[m.key].label))
    GameTooltip:AddLine(Loc("Drag to move. Shift locks an axis and skips snapping. Arrow keys nudge."), 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end

local function MoverLeave(m)
    PaintMover(m)
    GameTooltip:Hide()
end

local function MoverHide(m)
    if m:GetScript("OnUpdate") then MoverUp(m) end
end

-- Resize grip (displays that have a size, like the notes). The top-left corner stays
-- put; the position is re-stored from the new rectangle.
local function GripUpdate(grip)
    local m = grip.mover
    local rs, spec = m.rs, specs[m.key]
    if not rs then return end
    local x, y = CursorUI()
    local minSize = spec.resize.min or 40
    local w = max(minSize, floor(rs.w + (x - rs.x0) / rs.k + 0.5))
    local h = max(minSize, floor(rs.h - (y - rs.y0) / rs.k + 0.5))
    spec.resize.set(w, h)
    local hw, hh = w * rs.k / 2, h * rs.k / 2
    Apply(m, rs.left + hw, rs.top - hh, hw, hh)
end

local function GripDown(grip, button)
    if button ~= "LeftButton" or InCombatLockdown() then return end
    local m = grip.mover
    local spec = specs[m.key]
    local frame = spec.frame()
    if not frame then return end
    Select(m)
    local cx, cy, hw, hh = RectOf(frame)
    if not cx then return end
    local w, h = spec.resize.get()
    local x0, y0 = CursorUI()
    m.rs = { left = cx - hw, top = cy + hh, w = w, h = h, k = Ratio(frame), x0 = x0, y0 = y0 }
    grip:SetScript("OnUpdate", GripUpdate)
end

local function GripUp(grip)
    grip:SetScript("OnUpdate", nil)
    grip.mover.rs = nil
end

local function GetMover(spec)
    local m = movers[spec.key]
    if m then
        m.grip:SetShown(spec.resize ~= nil)
        m.gear:SetShown(spec.gear ~= nil)
        return m
    end
    m = CreateFrame("Button", nil, root)
    m.key = spec.key
    m:SetFrameStrata("FULLSCREEN")
    m:RegisterForClicks("AnyUp")
    m.fill = m:CreateTexture(nil, "BACKGROUND")
    m.fill:SetAllPoints()
    m.border = Pixel.Border(m, { Accent(0.6) })
    m.label = m:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(m.label, "small", "")
    m.label:SetTextColor(1, 1, 1, 1)
    m.label:SetPoint("CENTER")
    m.label:SetText(Loc(spec.label))
    m:SetScript("OnMouseDown", MoverDown)
    m:SetScript("OnMouseUp", MoverUp)
    m:SetScript("OnEnter", MoverEnter)
    m:SetScript("OnLeave", MoverLeave)
    m:SetScript("OnHide", MoverHide)

    local grip = CreateFrame("Button", nil, m)
    grip:SetSize(14, 14)
    grip:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -1, 1)
    grip:SetNormalTexture(GRIP_ICON)
    grip:SetFrameLevel(m:GetFrameLevel() + 2)
    grip.mover = m
    grip:SetScript("OnMouseDown", GripDown)
    grip:SetScript("OnMouseUp", GripUp)
    grip:SetScript("OnHide", GripUp)
    m.grip = grip

    local gear = CreateFrame("Button", nil, m)
    gear:SetSize(16, 16)
    gear:SetPoint("TOPRIGHT", m, "TOPRIGHT", -2, -2)
    gear:SetFrameLevel(m:GetFrameLevel() + 2)
    local tex = gear:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture(GEAR_ICON)
    tex:SetVertexColor(0.8, 0.8, 0.8, 1)
    gear:SetScript("OnEnter", function() tex:SetVertexColor(Accent(1)) end)
    gear:SetScript("OnLeave", function() tex:SetVertexColor(0.8, 0.8, 0.8, 1) end)
    gear:SetScript("OnClick", function()
        local s = specs[m.key]
        if s.gear and not InCombatLockdown() then s.gear() end
    end)
    m.gear = gear

    grip:SetShown(spec.resize ~= nil)
    gear:SetShown(spec.gear ~= nil)
    movers[spec.key] = m
    return m
end

local function IsAvailable(spec)
    if spec.unavailable then return spec.unavailable() == nil end
    return true
end

-- Cover each display that exists, is available and is not hidden; the mover follows
-- its frame by anchors.
local function PlaceMovers()
    for _, m in pairs(movers) do m:Hide() end
    local hidden = Prefs().hidden
    for _, spec in ipairs(order) do
        local frame = (not hidden[spec.key]) and IsAvailable(spec) and spec.frame()
        if frame and frame:GetCenter() then
            local m = GetMover(spec)
            m:ClearAllPoints()
            m:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
            m:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
            m:Show()
            PaintMover(m)
        end
    end
    if selected and not selected:IsShown() then Select(nil) end
end

-- --------------------------------------------------------------------------
--  Keyboard nudge: the capture frame passes every key through except arrows while a
--  display is selected. Keyboard flags are protected in combat; the session is
--  cancelled when combat starts.
-- --------------------------------------------------------------------------
local ARROWS = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

local function KeyDown(self, key)
    if InCombatLockdown() then return end
    local dir = ARROWS[key]
    if not dir or not selected then
        self:SetPropagateKeyboardInput(true)
        return
    end
    self:SetPropagateKeyboardInput(false)
    local frame = specs[selected.key].frame()
    local cx, cy, hw, hh
    if frame then cx, cy, hw, hh = RectOf(frame) end
    if not cx then return end
    local step = (IsShiftKeyDown() and NUDGE_BIG or 1) * PP.Pixel(UIParent)
    Apply(selected, cx + dir[1] * step, cy + dir[2] * step, hw, hh)
end

-- --------------------------------------------------------------------------
--  Show / hide a display while editing (a checkbox in the panel)
-- --------------------------------------------------------------------------
local function SetShownInEditor(spec, shown)
    local hidden = Prefs().hidden
    if (not hidden[spec.key]) == shown then return end
    hidden[spec.key] = (not shown) or nil
    if active and IsAvailable(spec) then
        if shown then
            if spec.onEnter then pcall(spec.onEnter) end
        else
            if spec.onExit then pcall(spec.onExit) end
        end
        PlaceMovers()
    end
end

local function RefreshChecklist()
    local hidden = Prefs().hidden
    for _, spec in ipairs(order) do
        local c = checks[spec.key]
        if c then
            local reason = spec.unavailable and spec.unavailable()
            c:SetValue(not hidden[spec.key])
            if reason then
                c:Disable()
                c.label:SetText(Loc(spec.label) .. "  |cff808080(" .. Loc(reason) .. ")|r")
            else
                c:Enable()
                c.label:SetText(Loc(spec.label))
            end
        end
    end
    if gridButton then gridButton:SetText(Loc("Grid") .. ": " .. (Prefs().grid and Loc("On") or Loc("Off"))) end
    if snapButton then snapButton:SetText(Loc("Snap") .. ": " .. (Prefs().snap and Loc("On") or Loc("Off"))) end
end

-- --------------------------------------------------------------------------
--  Panel: title, Grid / Snap, Cancel / Save, and the show/hide checklist
-- --------------------------------------------------------------------------
local HEADER_H   = 92
local COL_W      = 244
local ROW_H      = 24
local HEAD_H     = 22

local function BuildChecklist()
    checklistBuilt = true
    local x, y, col = 0, 0, 0
    local lastGroup
    for _, spec in ipairs(order) do
        if spec.group ~= lastGroup then
            if col ~= 0 then y = y + ROW_H; col = 0 end
            lastGroup = spec.group
            local head = listFrame:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(head, "small", "")
            STYLE.PaintAccent(head, "SetTextColor", 1)
            head:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -(y + 4))
            head:SetText(Loc(spec.group or ""))
            checkHeadings[#checkHeadings + 1] = { fs = head, key = spec.group }
            y = y + HEAD_H
        end
        local c = Components.CreateCheckButton(listFrame, Loc(spec.label),
            function() return not Prefs().hidden[spec.key] end,
            function(_, value) SetShownInEditor(spec, value and true or false) end,
            COL_W - 8, 22)
        c:SetPoint("TOPLEFT", listFrame, "TOPLEFT", col * COL_W, -y)
        checks[spec.key] = c
        col = col + 1
        if col == 2 then col = 0; y = y + ROW_H end
    end
    if col ~= 0 then y = y + ROW_H end
    listFrame:SetHeight(max(y, 1))
    hud:SetHeight(HEADER_H + y + 14)
end

local function BuildHUD()
    hud = Pixel.CreateBoxFrame("Frame", "NSRTEditModeHUD", UIParent)
    hud:SetFrameStrata("FULLSCREEN_DIALOG")
    hud:SetSize(HUD_W, 200)
    hud:SetPoint("TOP", UIParent, "TOP", 0, -60)
    hud:SetClampedToScreen(true)
    hud:SetMovable(true)
    hud:EnableMouse(true)
    hud:RegisterForDrag("LeftButton")
    hud:SetScript("OnDragStart", hud.StartMoving)
    hud:SetScript("OnDragStop", hud.StopMovingOrSizing)
    hud:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    hud:SetBackdropColor(unpack(STYLE.surface_panel))
    STYLE.PaintAccent(hud, "SetBackdropBorderColor", 0.7)
    Pixel.PixelSpace(hud, 1)

    local title = hud:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, "title")
    STYLE.PaintAccent(title, "SetTextColor", 1)
    title:SetPoint("TOPLEFT", 12, -16)
    title:SetText(Loc("Edit Layout"))

    local hint = hud:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(hint, "tiny", "")
    hint:SetTextColor(unpack(STYLE.text_muted))
    hint:SetPoint("TOPLEFT", 12, -46)
    hint:SetText(Loc("Drag to move. Shift locks an axis and skips snapping. Arrow keys nudge (Shift = 10px). Drag the corner grip to resize."))
    hint:SetWidth(HUD_W - 24)
    hint:SetJustifyH("LEFT")

    local save = Components.CreateButton(hud, Loc("Save"), function() EditMode.Close(true) end, 80, 26)
    save:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -12, -12)
    local cancel = Components.CreateButton(hud, Loc("Cancel"), function() EditMode.Close(false) end, 80, 26)
    cancel:SetPoint("RIGHT", save.frame, "LEFT", -6, 0)
    snapButton = Components.CreateButton(hud, "", function()
        local p = Prefs(); p.snap = not p.snap; RefreshChecklist()
    end, 80, 26)
    snapButton:SetPoint("RIGHT", cancel.frame, "LEFT", -14, 0)
    gridButton = Components.CreateButton(hud, "", function()
        local p = Prefs(); p.grid = not p.grid; grid:SetShown(p.grid); if p.grid then LayoutGrid() end; RefreshChecklist()
    end, 80, 26)
    gridButton:SetPoint("RIGHT", snapButton.frame, "LEFT", -6, 0)

    local divider = hud:CreateTexture(nil, "ARTWORK")
    STYLE.PaintAccent(divider, "SetColorTexture", 0.20)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", hud, "TOPLEFT", 1, -(HEADER_H - 12))
    divider:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -1, -(HEADER_H - 12))

    local showHide = hud:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(showHide, "tiny", "")
    showHide:SetTextColor(unpack(STYLE.text_muted))
    showHide:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -(HEADER_H - 2))
    showHide:SetText(Loc("Show while editing:"))

    local showAll = Components.CreateButton(hud, Loc("Show all"), function()
        for _, spec in ipairs(order) do SetShownInEditor(spec, true) end
        RefreshChecklist()
    end, 84, 20)
    local hideAll = Components.CreateButton(hud, Loc("Hide all"), function()
        for _, spec in ipairs(order) do SetShownInEditor(spec, false) end
        RefreshChecklist()
    end, 84, 20)
    hideAll:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -12, -(HEADER_H - 6))
    showAll:SetPoint("RIGHT", hideAll.frame, "LEFT", -6, 0)

    listFrame = CreateFrame("Frame", nil, hud)
    listFrame:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -(HEADER_H + 20))
    listFrame:SetWidth(HUD_W - 24)
    -- the list sits below the "Show while editing" line
    BuildChecklist()
    hud:SetHeight(hud:GetHeight() + 20)

    -- Escape hides the panel: treat that as Cancel.
    tinsert(UISpecialFrames, "NSRTEditModeHUD")
    hud:SetScript("OnHide", function()
        if active then EditMode.Close(false) end
    end)
    hud:Hide()
end

local function Build()
    root = CreateFrame("Frame", nil, UIParent)
    root:SetAllPoints(UIParent)
    root:SetFrameStrata("FULLSCREEN")
    root:Hide()
    BuildGrid()
    guideV = root:CreateTexture(nil, "OVERLAY")
    guideH = root:CreateTexture(nil, "OVERLAY")
    for _, g in ipairs({ guideV, guideH }) do
        PP.NoSnap(g)
        g:SetColorTexture(Accent(0.9))
        g:Hide()
    end
    keys = CreateFrame("Frame", nil, root)
    keys:EnableKeyboard(true)
    keys:SetPropagateKeyboardInput(true)
    keys:SetScript("OnKeyDown", KeyDown)
    keys:Hide()
    BuildHUD()
    -- Combat: the layout cannot be changed safely, so the session is cancelled. Registered
    -- only while a session is open.
    root:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            print("|cff00ffffNSRT|r " .. Loc("Layout editing was cancelled because combat started."))
            EditMode.Close(false)
        elseif grid and grid:IsShown() then          -- UI scale / resolution changed
            C_Timer.After(0, LayoutGrid)
        end
    end)
end

-- --------------------------------------------------------------------------
--  Open / close
-- --------------------------------------------------------------------------
function EditMode.IsActive() return active end

function EditMode.Open()
    if active then return end
    if InCombatLockdown() then
        print("|cff00ffffNSRT|r " .. Loc("The layout cannot be edited in combat."))
        return
    end
    if not root then Build() end
    active = true
    NSI.LayoutEditorActive = true

    local NSUI = NSI.NSUI
    reopenOptions = NSUI and NSUI:IsShown() or false
    if NSUI then NSUI:Hide() end

    for _, hook in ipairs(sessions) do          -- before the displays: create frames, start previews
        if hook.onOpen then pcall(hook.onOpen) end
    end
    wipe(snapshot)
    local hidden = Prefs().hidden
    for _, spec in ipairs(order) do
        local point, rel, x, y = spec.getPos()
        local w, h
        if spec.resize then w, h = spec.resize.get() end
        snapshot[spec.key] = { point, rel, x, y, w, h }
        if not hidden[spec.key] and IsAvailable(spec) and spec.onEnter then pcall(spec.onEnter) end
    end

    root:RegisterEvent("PLAYER_REGEN_DISABLED")
    root:RegisterEvent("UI_SCALE_CHANGED")
    root:RegisterEvent("DISPLAY_SIZE_CHANGED")
    root:Show()
    RefreshChecklist()
    hud:Show()
    if Prefs().grid then LayoutGrid(); grid:Show() end
    PlaceMovers()
end

-- save: keep the new positions; otherwise put every display back exactly as it was.
function EditMode.Close(save)
    if not active then return end
    active = false
    NSI.LayoutEditorActive = false
    Select(nil)
    root:UnregisterAllEvents()
    for _, m in pairs(movers) do m:Hide() end
    root:Hide()
    grid:Hide()
    hud:Hide()

    if not save then
        for _, spec in ipairs(order) do
            local s = snapshot[spec.key]
            if s then
                if spec.resize and s[5] then spec.resize.set(s[5], s[6]) end
                spec.setPos(s[1], s[2], s[3], s[4])
            end
        end
    end
    for _, hook in ipairs(sessions) do
        if hook.onClose then pcall(hook.onClose) end
    end
    local hidden = Prefs().hidden
    for _, spec in ipairs(order) do
        if not hidden[spec.key] and IsAvailable(spec) and spec.onExit then pcall(spec.onExit) end
    end

    local NSUI = NSI.NSUI
    if reopenOptions and NSUI then NSUI:Show() end
end

function EditMode.Toggle()
    if active then EditMode.Close(true) else EditMode.Open() end
end
