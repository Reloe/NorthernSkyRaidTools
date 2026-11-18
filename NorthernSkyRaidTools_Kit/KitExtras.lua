-- ============================================================
--  KitExtras.lua - kit tokens and small components (K-3)
--
--  Owns: STYLE tokens for response tiers, timer thresholds and progress bars, the colour
--  helpers STYLE.Hex / STYLE.Colorize, and the components CreateTag, CreateItemButton,
--  CreateTimerText and CreateProgressBar.
--  Loads after Components.lua and Window.lua. CreateDataTable is in DataTable.lua.
--
--  Rules: no colour literals outside the STYLE tables below; square shapes only
--  (house look, no rounded pills); item tooltips use GameTooltip, text-only
--  tooltips use NSI.UI.Tooltip.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Pixel = NSI.UI.Pixel
local Components = NSI.UI.Components

local floor, max, min = math.floor, math.max, math.min
local GetTime = GetTime

-- ============================================================
--  Tokens
-- ============================================================
-- Response tiers (stable ids are owned by the module; the kit only names the colours).
STYLE.tier = STYLE.tier or {
    best    = { 0.20, 0.90, 0.30, 1 },   -- BiS / top priority
    major   = { 0.25, 0.70, 1.00, 1 },   -- major upgrade
    minor   = { 0.75, 0.55, 1.00, 1 },   -- minor upgrade
    offspec = { 1.00, 0.65, 0.00, 1 },   -- offspec
    xmog    = { 0.85, 0.85, 0.40, 1 },   -- transmog
    pass    = { 0.50, 0.50, 0.50, 1 },   -- pass / no response
    alert   = { 0.90, 0.30, 0.30, 1 },   -- needs attention
}

-- Countdown thresholds in seconds: at or below `warn` the text turns warning, at or below `danger` danger.
STYLE.timer = STYLE.timer or { warn = 3600, danger = 600 }

-- Colour for a tier name or a raw colour table.
function STYLE.TierColor(token)
    if type(token) == "table" then return token end
    return STYLE.tier[token] or STYLE.text_muted
end

-- Progress bar: track colour and the fractions where the fill turns warning, then danger.
STYLE.progress = STYLE.progress or { track = { 0.12, 0.12, 0.14, 1 }, warnAt = 0.5, dangerAt = 0.2 }

-- Any colour a caller may name: a raw { r, g, b, a } table, a tier name ("best", "alert"...) or a STYLE
-- token name ("text_muted", "warning"...). Unknown names fall back to muted text.
function STYLE.ResolveColor(token)
    if type(token) == "table" then return token end
    return STYLE.tier[token] or STYLE[token] or STYLE.text_muted
end

-- "|cffRRGGBB" for a colour (name or table).
function STYLE.Hex(token)
    local c = STYLE.ResolveColor(token)
    local function byte(v) return math.max(0, math.min(255, math.floor((v or 1) * 255 + 0.5))) end
    return string.format("|cff%02x%02x%02x", byte(c[1]), byte(c[2]), byte(c[3]))
end

-- Wrap text in a colour: STYLE.Colorize("No response", "alert"). Does not escape "|" in the text.
function STYLE.Colorize(text, token)
    return STYLE.Hex(token) .. tostring(text) .. "|r"
end

local function SetFont(fs, size, flags)
    NSI:SetUIFont(fs, size, flags)
end

-- ============================================================
--  CreateTag(parent, text, colorToken)
--
--  A small labelled chip for responses and reasons: square, 1px border in the
--  tier colour, tinted fill, text in the tier colour.
--    tag.frame  tag:SetText(text)  tag:SetColor(colorToken)  tag:GetWidth()
-- ============================================================
local TAG_H, TAG_PAD = 16, 6

local function CreateTag(parent, text, colorToken)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(TAG_H)
    f.fill = f:CreateTexture(nil, "BACKGROUND")
    f.fill:SetAllPoints()
    f.fill:SetColorTexture(1, 1, 1, 1)
    f.border = Pixel.Border(f, { 1, 1, 1, 1 })
    f.text = f:CreateFontString(nil, "OVERLAY")
    SetFont(f.text, "tiny")
    f.text:SetPoint("CENTER", 0, 0)
    f.text:SetWordWrap(false)

    local tag = { frame = f }

    function tag:SetColor(token)
        local c = STYLE.TierColor(token)
        f.fill:SetVertexColor(c[1], c[2], c[3], 0.18)
        f.border:SetBorderColor(c[1], c[2], c[3], 0.9)
        f.text:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    end

    function tag:SetText(value)
        f.text:SetText(value or "")
        f:SetWidth(max(TAG_H, floor(f.text:GetUnboundedStringWidth() + TAG_PAD * 2 + 0.5)))
    end

    function tag:GetWidth() return f:GetWidth() end
    function tag:SetPoint(...) f:SetPoint(...) end
    function tag:Show() f:Show() end
    function tag:Hide() f:Hide() end

    tag:SetText(text)
    tag:SetColor(colorToken or "pass")
    return tag
end

-- ============================================================
--  CreateItemButton(parent, size)
--
--  Item icon with a quality border, an item-level overlay, a GameTooltip on hover
--  and shift-click to link.
--    btn.frame  btn:SetItem(linkOrID, ilvl)  btn:GetItem()  btn:Clear()
-- ============================================================
local function QualityColor(quality)
    local c = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if c then return c.r, c.g, c.b end
    return STYLE.border_subtle[1], STYLE.border_subtle[2], STYLE.border_subtle[3]
end

local function ItemButtonEnter(self)
    local link = self._link
    if not link then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end

local function ItemButtonLeave()
    GameTooltip:Hide()
end

local function ItemButtonClick(self)
    local link = self._link
    if link and IsModifiedClick("CHATLINK") then
        HandleModifiedItemClick(link)
    end
end

local function CreateItemButton(parent, size)
    size = size or 32
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 1, -1)
    b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.border = Pixel.Border(b, { 0.25, 0.25, 0.25, 1 })
    b.ilvl = b:CreateFontString(nil, "OVERLAY")
    SetFont(b.ilvl, "tiny", "OUTLINE")   -- over an icon, so outlined like in-world text
    b.ilvl:SetPoint("BOTTOMRIGHT", -2, 2)
    b:SetScript("OnEnter", ItemButtonEnter)
    b:SetScript("OnLeave", ItemButtonLeave)
    b:SetScript("OnClick", ItemButtonClick)

    local btn = { frame = b }

    function btn:SetItem(item, ilvl)
        if not item then return self:Clear() end
        local link = type(item) == "string" and item or nil
        local id = link and C_Item.GetItemInfoInstant(link) or (type(item) == "number" and item) or nil
        b._link = link or (id and select(2, C_Item.GetItemInfo(id))) or nil
        local icon = id and select(5, C_Item.GetItemInfoInstant(id))
        b.icon:SetTexture(icon or 134400)
        local quality = b._link and select(3, C_Item.GetItemInfo(b._link))
        local r, g, bl = QualityColor(quality)
        b.border:SetBorderColor(r, g, bl, 1)
        if not ilvl and b._link then ilvl = C_Item.GetDetailedItemLevelInfo(b._link) end
        b.ilvl:SetText(ilvl and tostring(ilvl) or "")
    end

    function btn:GetItem() return b._link end

    function btn:Clear()
        b._link = nil
        b.icon:SetTexture(nil)
        b.ilvl:SetText("")
        b.border:SetBorderColor(STYLE.border_subtle[1], STYLE.border_subtle[2], STYLE.border_subtle[3], 1)
    end

    function btn:SetPoint(...) b:SetPoint(...) end
    function btn:SetSize(w, h) b:SetSize(w, h or w) end
    function btn:Show() b:Show() end
    function btn:Hide() b:Hide() end

    btn:Clear()
    return btn
end

-- ============================================================
--  CreateTimerText(parent)
--
--  Countdown text with threshold colours. It ticks through a looping AnimationGroup
--  on its own frame, so it runs only while the frame is visible (best practices 2.4).
--    t.frame  t.text (FontString)
--    t:SetEndTime(serverTime)  t:SetSecondsLeft(n)  t:SetDoneText(text)  t:Stop()
--  Times are GetServerTime()-based so they match what other clients report.
-- ============================================================
local function FormatDuration(s)
    if s >= 3600 then
        return string.format("%dh %02dm", floor(s / 3600), floor((s % 3600) / 60))
    end
    return string.format("%d:%02d", floor(s / 60), s % 60)
end

local function CreateTimerText(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(60, 14)
    f.text = f:CreateFontString(nil, "OVERLAY")
    SetFont(f.text, "small")
    f.text:SetAllPoints()
    f.text:SetJustifyH("RIGHT")

    local t = { frame = f, text = f.text, doneText = "" }

    local function Paint()
        local left = t.endTime and (t.endTime - GetServerTime()) or nil
        if not left then f.text:SetText(""); return end
        if left <= 0 then
            local c = STYLE.danger
            f.text:SetTextColor(c[1], c[2], c[3], c[4])
            f.text:SetText(t.doneText)
            return false
        end
        local c = STYLE.text_color
        if left <= STYLE.timer.danger then c = STYLE.danger
        elseif left <= STYLE.timer.warn then c = STYLE.warning end
        f.text:SetTextColor(c[1], c[2], c[3], c[4])
        f.text:SetText(FormatDuration(left))
    end

    local group = f:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local anim = group:CreateAnimation("Animation")
    anim:SetDuration(1)
    group:SetScript("OnLoop", function()
        if Paint() == false then group:Stop() end
    end)
    f:HookScript("OnShow", function()
        if t.endTime then
            if Paint() ~= false then group:Play() end
        end
    end)
    f:HookScript("OnHide", function() group:Stop() end)

    function t:SetEndTime(endTime)
        self.endTime = endTime
        group:Stop()
        if not endTime then f.text:SetText(""); return end
        if Paint() ~= false and f:IsVisible() then group:Play() end
    end

    function t:SetSecondsLeft(n)
        self:SetEndTime(n and (GetServerTime() + n) or nil)
    end

    function t:SetDoneText(text) self.doneText = text or "" end
    function t:Stop() group:Stop(); self.endTime = nil; f.text:SetText("") end
    function t:SetPoint(...) f:SetPoint(...) end
    return t
end

-- ============================================================
--  CreateProgressBar(parent, width, height)
--
--  A flat bar: dark track, 1px border, coloured fill and centred text (e.g. a countdown).
--  The fill colour follows the fraction (good > warnAt > warn > dangerAt > danger, see
--  STYLE.progress) unless a colour is set.
--    bar.frame  bar.text (FontString)
--    bar:SetFraction(0..1 [, instant])  eases to the value (bar:SetSmooth(false) to snap)
--    bar:SetTimer(secondsLeft, total)   linear countdown that animates every frame by itself
--    bar:SetText(s)   bar:SetColor(nameOrTable | nil for automatic)
--    bar:SetPoint(...)  bar:SetSize(w, h)  bar:Show()  bar:Hide()  bar:GetFraction()
-- ============================================================
local function CreateProgressBar(parent, width, height)
    local f = CreateFrame("StatusBar", nil, parent)
    f:SetSize(width or 200, height or 12)
    f:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
    f:SetMinMaxValues(0, 1)
    f.track = f:CreateTexture(nil, "BACKGROUND")
    f.track:SetAllPoints()
    f.track:SetColorTexture(unpack(STYLE.progress.track))
    Pixel.Border(f, STYLE.border_subtle)
    f.text = f:CreateFontString(nil, "OVERLAY")
    SetFont(f.text, "small")
    -- Fill the bar and centre vertically; the font's baseline sits low, so nudge up one pixel.
    f.text:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 1)
    f.text:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 1)
    f.text:SetJustifyH("CENTER")
    f.text:SetJustifyV("MIDDLE")

    local bar, fraction, fixed = { frame = f, text = f.text }, 0, nil
    local shown, smooth = 0, true      -- shown: what the fill displays; fraction: where it is heading
    local endAt, total                 -- timer mode: counts down on its own from GetTime()

    local function Paint()
        local c
        if fixed then
            c = STYLE.ResolveColor(fixed)
        elseif shown > STYLE.progress.warnAt then
            c = STYLE.tier.best
        elseif shown > STYLE.progress.dangerAt then
            c = STYLE.warning
        else
            c = STYLE.tier.alert
        end
        f:SetStatusBarColor(c[1], c[2], c[3], 1)
    end

    local function Show(v)
        shown = v
        f:SetValue(v)
        Paint()
    end

    -- One OnUpdate drives both modes; it is only set while something is moving.
    local function OnUpdate(_, dt)
        if endAt then
            local left = endAt - GetTime()
            fraction = max(0, min(1, left / total))
            Show(fraction)
            if left <= 0 then endAt = nil; f:SetScript("OnUpdate", nil) end
        else
            local diff = fraction - shown
            if diff > -0.0005 and diff < 0.0005 then
                Show(fraction)
                f:SetScript("OnUpdate", nil)
            else
                Show(shown + diff * min(1, dt * 14))
            end
        end
    end

    -- Eased to the new value unless instant (or smoothing is off / the bar is hidden).
    function bar:SetFraction(v, instant)
        endAt = nil
        fraction = max(0, min(1, v or 0))
        if instant or not smooth or not f:IsVisible() then
            f:SetScript("OnUpdate", nil)
            Show(fraction)
        else
            f:SetScript("OnUpdate", OnUpdate)
        end
    end

    -- A countdown that moves every frame by itself: pass the seconds left and the full length. Call
    -- it as often as you like (e.g. once a second from a server-time source): it only re-anchors when
    -- it has drifted by more than 1.5s, so whole-second inputs do not make it stutter.
    function bar:SetTimer(secondsLeft, totalSeconds)
        total = math.max(totalSeconds or 1, 0.001)
        local newEnd = GetTime() + math.max(secondsLeft or 0, 0)
        if not endAt or math.abs(newEnd - endAt) > 1.5 then endAt = newEnd end
        f:SetScript("OnUpdate", OnUpdate)
    end

    function bar:SetSmooth(on) smooth = on ~= false end
    function bar:GetFraction() return fraction end
    function bar:SetColor(token) fixed = token; Paint() end
    function bar:SetText(s) f.text:SetText(s or "") end
    function bar:SetPoint(...) f:SetPoint(...) end
    function bar:SetSize(w, h) f:SetSize(w, h) end
    function bar:Show() f:Show() end
    function bar:Hide() f:Hide() end

    bar:SetFraction(0, true)
    return bar
end

Components.CreateTag        = CreateTag
Components.CreateItemButton = CreateItemButton
Components.CreateTimerText  = CreateTimerText
Components.FormatDuration   = FormatDuration
Components.CreateProgressBar = CreateProgressBar
Components.ColorText        = STYLE.Colorize
