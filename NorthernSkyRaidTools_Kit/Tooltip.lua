-- ============================================================
--  Tooltip.lua  -  the addon's own tooltip card
--
--  Used for widget help text (title + description). One frame for the whole addon,
--  built on first use, in pixel space with a 1px accent border. It never touches
--  GameTooltip, so spell and item tooltips (which need the real one) are unaffected.
--
--    Tooltip.Show(owner, spec, anchor)
--      spec    "text"  or  { title = "...", desc = "..." }   (run through NSI:Loc)
--      anchor  a GameTooltip owner anchor name: ANCHOR_TOP (default), ANCHOR_TOPLEFT,
--              ANCHOR_TOPRIGHT, ANCHOR_BOTTOM, ANCHOR_LEFT, ANCHOR_RIGHT
--    Tooltip.Hide()
--
--  Exported as NSI.UI.Tooltip. Loads after Pixel.lua; Style and fonts are resolved on
--  first Show, so it does not depend on load order beyond that.
-- ============================================================

local NSI = _G.NorthernSkyRaidTools
local Tooltip = {}
NSI.UI.Tooltip = Tooltip

local WHITE = [[Interface\Buttons\WHITE8X8]]
local MAX_W, PAD, GAP, OFFSET = 300, 8, 4, 4

-- tooltip point, owner point, x, y
local ANCHORS = {
    ANCHOR_TOP      = { "BOTTOM",      "TOP",      0,  OFFSET },
    ANCHOR_TOPLEFT  = { "BOTTOMLEFT",  "TOPLEFT",  0,  OFFSET },
    ANCHOR_TOPRIGHT = { "BOTTOMRIGHT", "TOPRIGHT", 0,  OFFSET },
    ANCHOR_BOTTOM   = { "TOP",         "BOTTOM",   0, -OFFSET },
    ANCHOR_LEFT     = { "RIGHT",       "LEFT",    -OFFSET, 0 },
    ANCHOR_RIGHT    = { "LEFT",        "RIGHT",    OFFSET, 0 },
}

local frame, title, body

local function Build()
    local STYLE = NSI.UI.Style
    frame = NSI.UI.Pixel.CreateBoxFrame("Frame", "NSRTTooltip", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(STYLE.surface_panel))
    STYLE.PaintAccent(frame, "SetBackdropBorderColor", 0.7)
    NSI.UI.Pixel.PixelSpace(frame, 1)

    title = frame:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, "label", "")
    STYLE.PaintAccent(title, "SetTextColor", 1)
    title:SetJustifyH("LEFT")
    title:SetJustifyV("TOP")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)

    body = frame:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(body, "small", "")
    body:SetTextColor(1, 1, 1, 1)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(2)
    frame:Hide()
end

local owner

function Tooltip.Hide()
    owner = nil
    if frame then frame:Hide() end
end

function Tooltip.Show(target, spec, anchor)
    if not spec or not target then return end
    if not frame then Build() end
    local t, d
    if type(spec) == "table" then
        t = spec.title and NSI:Loc(spec.title) or ""
        d = spec.desc and NSI:Loc(spec.desc) or ""
    else
        t, d = NSI:Loc(spec), ""
    end
    local hasTitle, hasBody = t ~= "", d ~= ""
    if not hasTitle and not hasBody then return end

    title:SetText(t)
    body:SetText(d)
    title:SetShown(hasTitle)
    body:SetShown(hasBody)

    -- Size to the longest unwrapped line (capped), then let the text wrap at that width.
    title:SetWidth(0)
    body:SetWidth(0)
    local w = math.min(MAX_W, math.max(hasTitle and title:GetStringWidth() or 0, hasBody and body:GetStringWidth() or 0))
    w = math.max(w, 40)
    title:SetWidth(w)
    body:SetWidth(w)

    body:ClearAllPoints()
    local h = PAD * 2
    if hasTitle then
        h = h + title:GetStringHeight()
        body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -GAP)
        if hasBody then h = h + GAP end
    else
        body:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    end
    if hasBody then h = h + body:GetStringHeight() end
    frame:SetSize(w + PAD * 2, h)

    local a = ANCHORS[anchor or "ANCHOR_TOP"] or ANCHORS.ANCHOR_TOP
    frame:ClearAllPoints()
    frame:SetPoint(a[1], target, a[2], a[3], a[4])
    owner = target
    if not target._nsrtTipHook then                    -- a hidden owner never fires OnLeave
        target._nsrtTipHook = true
        target:HookScript("OnHide", function(self)
            if owner == self then Tooltip.Hide() end
        end)
    end
    frame:Show()
end
