-- ============================================================
--  NSRT UI Pixel
--
--  Owns: physical-pixel math (PP), pixel-snapped primitives
--  (Solid, Border), the BackdropTemplate replacement
--  (AddBackdrop / CreateBoxFrame) and pixel-space scaling for
--  windows and popups (PixelSpace / CreateSimplePanel).
--
--  Loads before Core.lua and Components.lua and depends on
--  neither.  Exported as NSI.UI.Pixel (and NSI.UI.PP).
--
--  Background
--    One physical pixel is 768 / physicalScreenHeight units at
--    effective scale 1, so inside any region it measures
--    768 / physicalHeight / region:GetEffectiveScale() units.
--    Anything thin (borders, dividers) is sized with that
--    formula and drawn with texel snapping turned off, which
--    keeps 1px lines visible on all four sides at every UI
--    scale.  Windows additionally get a "pixel space" scale so
--    that one frame unit is exactly one physical pixel and every
--    integer offset lands on a pixel boundary.
-- ============================================================

local NSI = _G.NorthernSkyRaidTools
local DF  = _G["DetailsFramework"]

local floor, abs = math.floor, math.abs
local type, pairs, getmetatable, setmetatable = type, pairs, getmetatable, setmetatable
local GetPhysicalScreenSize = GetPhysicalScreenSize

local PP    = {}
local Pixel = { PP = PP }

-- ------------------------------------------------------------
--  Pixel math
-- ------------------------------------------------------------
local physH = 1080

function PP.UpdateScreen()
    local _, h = GetPhysicalScreenSize()
    if h and h > 0 then physH = h end   -- 0 mid display-mode change: keep the last good value
end
PP.UpdateScreen()

-- Textures and font strings have no effective scale of their own: measure their parent.
local function ScaleOf(region)
    if not region then return UIParent:GetEffectiveScale() end
    if not region.GetEffectiveScale then region = region:GetParent() end
    local s = region and region:GetEffectiveScale()
    return (s and s > 0) and s or 1
end

-- One physical pixel, in `region`'s coordinate units.
function PP.Pixel(region)
    return 768 / physH / ScaleOf(region)
end

-- Epsilon-guarded round: a value sitting on a half pixel rounds the same way on
-- every reload instead of flipping with float dust.
local function Round(x) return floor(x + 0.5 + 1e-4) end
PP.Round = Round

function PP.Snap(v, region)
    if v == 0 then return 0 end
    local px = PP.Pixel(region)
    return Round(v / px) * px
end

-- n physical pixels, never fewer than one (borders, dividers).
function PP.Pixels(n, region)
    if not n or n < 1 then n = 1 end
    return Round(n) * PP.Pixel(region)
end

function PP.Size(region, w, h)
    region:SetSize(PP.Snap(w, region), PP.Snap(h or w, region))
end

function PP.Point(region, point, rel, relPoint, x, y)
    region:SetPoint(point, rel, relPoint, PP.Snap(x or 0, region), PP.Snap(y or 0, region))
end

-- Snap a CENTER coordinate so both edges of a `dim`-wide frame land on pixels:
-- even pixel widths need a whole-pixel center, odd widths a half-pixel center.
function PP.SnapCenter(value, dim, region)
    local px = PP.Pixel(region)
    local v = value / px
    if Round(dim / px) % 2 == 1 then
        return (floor(v) + 0.5) * px
    end
    return Round(v) * px
end

-- For textures whose size is already pixel-snapped: stop the engine re-rounding
-- them, which makes 1px strips vanish per side at some scales.
function PP.NoSnap(tex)
    if tex.SetSnapToPixelGrid then
        tex:SetSnapToPixelGrid(false)
        tex:SetTexelSnappingBias(0)
    end
end

-- Scale for a child of `parent` (default UIParent) that makes one of its units one
-- physical pixel, times the user's window scale.
function PP.PixelSpaceScale(userScale, parent)
    local ps = (parent or UIParent):GetEffectiveScale()
    if not ps or ps <= 0 then ps = 1 end
    return 768 / physH / ps * (userScale or 1)
end

-- ------------------------------------------------------------
--  Primitives: Solid, Border
-- ------------------------------------------------------------
function Pixel.Solid(parent, layer, color, sublevel)
    local tex = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    tex:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    PP.NoSnap(tex)
    return tex
end

-- Borders are four strips, each a whole number of physical pixels thick, drawn on
-- the frame itself.  Backdrop edges blur at fractional scales and lose a side.
-- The returned object is a plain table (not a frame); the registry is weak.
local borders = setmetatable({}, { __mode = "k" })

local Border = {}
Border.__index = Border

function Border:Layout()
    local t = PP.Pixels(self.thickness, self.frame)
    self.top:SetHeight(t)
    self.bottom:SetHeight(t)
    self.left:SetWidth(t)
    self.right:SetWidth(t)
end

function Border:SetBorderColor(r, g, b, a)
    a = a or 1
    self.top:SetColorTexture(r, g, b, a)
    self.bottom:SetColorTexture(r, g, b, a)
    self.left:SetColorTexture(r, g, b, a)
    self.right:SetColorTexture(r, g, b, a)
end

function Border:SetThickness(n)
    if self.thickness == n then return end
    self.thickness = n
    self:Layout()
end

function Border:SetShown(shown)
    self.top:SetShown(shown)
    self.bottom:SetShown(shown)
    self.left:SetShown(shown)
    self.right:SetShown(shown)
end
function Border:Show() self:SetShown(true)  end
function Border:Hide() self:SetShown(false) end

local function Edge(frame)
    local tex = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    PP.NoSnap(tex)
    return tex
end

-- color: {r, g, b[, a]};  thickness: physical pixels (default 1)
function Pixel.Border(frame, color, thickness)
    local top, bottom, left, right = Edge(frame), Edge(frame), Edge(frame), Edge(frame)
    top:SetPoint("TOPLEFT",  frame, "TOPLEFT")
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    bottom:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    -- Sides stop at the top and bottom strips so translucent corners are drawn once.
    left:SetPoint("TOPLEFT",    top,    "BOTTOMLEFT")
    left:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT")
    right:SetPoint("TOPRIGHT",    top,    "BOTTOMRIGHT")
    right:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT")

    local b = setmetatable({
        frame = frame, thickness = thickness or 1,
        top = top, bottom = bottom, left = left, right = right,
    }, Border)
    local c = color or { 1, 1, 1, 1 }
    b:SetBorderColor(c[1], c[2], c[3], c[4])
    b:Layout()
    borders[b] = true
    return b
end

function Pixel.RefreshBorders()
    for b in pairs(borders) do b:Layout() end
end

-- ------------------------------------------------------------
--  Backdrop replacement
--
--  AddBackdrop(frame) gives a plain frame the three BackdropTemplate calls this
--  addon uses -- SetBackdrop / SetBackdropColor / SetBackdropBorderColor -- but
--  draws a solid texture plus a pixel-snapped border instead.  bgFile makes the
--  fill (tiled tooltip textures become a plain solid colour), edgeFile makes the
--  border and edgeSize is its thickness in physical pixels.
-- ------------------------------------------------------------
local boxes = setmetatable({}, { __mode = "k" })

local function BoxState(frame)
    local s = boxes[frame]
    if not s then
        s = { bgColor = { 1, 1, 1, 1 }, borderColor = { 1, 1, 1, 1 } }
        boxes[frame] = s
    end
    return s
end

local function PaintBg(s)
    if s.bg then
        local c = s.bgColor
        s.bg:SetColorTexture(c[1], c[2], c[3], c[4])
    end
end

local function PaintEdge(s)
    if s.border then
        local c = s.borderColor
        s.border:SetBorderColor(c[1], c[2], c[3], c[4])
    end
end

local function BoxSetBackdrop(frame, info)
    local s = BoxState(frame)
    if not info then
        if s.bg then s.bg:Hide() end
        if s.border then s.border:Hide() end
        return
    end
    if info.bgFile then
        if not s.bg then
            s.bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
            PP.NoSnap(s.bg)
            s.bg:SetAllPoints(frame)
        end
        s.bg:Show()
        PaintBg(s)
    elseif s.bg then
        s.bg:Hide()
    end
    if info.edgeFile then
        local thickness = info.edgeSize or 1
        if not s.border then
            s.border = Pixel.Border(frame, s.borderColor, thickness)
        else
            s.border:SetThickness(thickness)
            s.border:Show()
        end
        PaintEdge(s)
    elseif s.border then
        s.border:Hide()
    end
end

local function BoxSetBackdropColor(frame, r, g, b, a)
    local c = BoxState(frame).bgColor
    c[1], c[2], c[3], c[4] = r, g, b, a or 1
    PaintBg(boxes[frame])
end

local function BoxSetBackdropBorderColor(frame, r, g, b, a)
    local c = BoxState(frame).borderColor
    c[1], c[2], c[3], c[4] = r, g, b, a or 1
    PaintEdge(boxes[frame])
end

local function BoxGetBackdropColor(frame)
    local c = BoxState(frame).bgColor
    return c[1], c[2], c[3], c[4]
end

local function BoxGetBackdropBorderColor(frame)
    local c = BoxState(frame).borderColor
    return c[1], c[2], c[3], c[4]
end

function Pixel.AddBackdrop(frame)
    if boxes[frame] then return frame end
    BoxState(frame)
    frame.SetBackdrop            = BoxSetBackdrop
    frame.SetBackdropColor       = BoxSetBackdropColor
    frame.SetBackdropBorderColor = BoxSetBackdropBorderColor
    frame.GetBackdropColor       = BoxGetBackdropColor
    frame.GetBackdropBorderColor = BoxGetBackdropBorderColor
    return frame
end

-- CreateFrame + AddBackdrop.  Replaces CreateFrame(type, name, parent, "BackdropTemplate").
function Pixel.CreateBoxFrame(frameType, name, parent, template)
    return Pixel.AddBackdrop(CreateFrame(frameType, name, parent, template))
end

-- ------------------------------------------------------------
--  Pixel-space scaling
--
--  PixelSpace(frame, userScale) scales `frame` so one of its units is one physical
--  pixel, multiplied by the user's own window scale.  `userScale` is a number, a
--  function returning one, or nil (keep the scale the frame already has).
--  frame:SetScale(v) is redirected on that frame so that anything that sets a
--  user scale (Details Framework's scale bar, our own code) keeps working.
--  Re-applied on show and whenever the UI scale or resolution changes.
-- ------------------------------------------------------------
local scaled = setmetatable({}, { __mode = "k" })   -- frame -> number | function

local function RawSetScale(frame, s)
    getmetatable(frame).__index.SetScale(frame, s)
end

local function UserScaleOf(frame)
    local u = scaled[frame]
    if type(u) == "function" then u = u() end
    return (type(u) == "number" and u > 0) and u or 1
end

local function ApplyScale(frame)
    local s = PP.PixelSpaceScale(UserScaleOf(frame), frame:GetParent())
    if abs((frame:GetScale() or 0) - s) < 1e-6 then return false end
    RawSetScale(frame, s)
    return true
end

local function ShimSetScale(frame, value)
    scaled[frame] = value
    if ApplyScale(frame) then Pixel.RefreshBorders() end
end

local function OnShowApply(frame)
    if ApplyScale(frame) then Pixel.RefreshBorders() end
end

function Pixel.PixelSpace(frame, userScale)
    if userScale == nil then userScale = frame:GetScale() end
    local first = scaled[frame] == nil
    scaled[frame] = userScale
    if first then
        frame.SetScale = ShimSetScale
        frame:HookScript("OnShow", OnShowApply)
    end
    if ApplyScale(frame) then Pixel.RefreshBorders() end
    return frame
end

function Pixel.GetUserScale(frame)
    return UserScaleOf(frame)
end

-- Drop-in for DF:CreateSimplePanel.  Panels parented to UIParent (popups) are put in
-- pixel space and keep whatever user scale they were created with.
function Pixel.CreateSimplePanel(parent, ...)
    local panel = DF:CreateSimplePanel(parent, ...)
    if panel and parent == UIParent then Pixel.PixelSpace(panel) end
    return panel
end

-- ------------------------------------------------------------
--  Rescale notifications.  UIParent:SetScale from code does not fire
--  UI_SCALE_CHANGED, so call PP.NotifyRescale() after changing it.
-- ------------------------------------------------------------
local listeners = {}
function PP.OnRescale(fn) listeners[#listeners + 1] = fn end

function PP.NotifyRescale()
    PP.UpdateScreen()
    for frame in pairs(scaled) do ApplyScale(frame) end
    Pixel.RefreshBorders()
    for i = 1, #listeners do listeners[i]() end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UI_SCALE_CHANGED")
watcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
watcher:SetScript("OnEvent", PP.NotifyRescale)

-- ------------------------------------------------------------
--  Export
-- ------------------------------------------------------------
NSI.UI = NSI.UI or {}
NSI.UI.Pixel = Pixel
NSI.UI.PP    = PP
