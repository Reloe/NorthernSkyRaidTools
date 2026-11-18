-- ============================================================
--  Frames/Shell.lua - the one window shell every Loot Council window uses
--
--  Built on the kit window (title bar, close button, drag, pixel-perfect). Adds:
--    - X and right-click only HIDE: a hidden window keeps its state and the session keeps running
--    - drag anywhere, position remembered per window (settings.framePos[name])
--    - f.dismissed: true after the user hid it, so refreshes do not pop it back up. Code that wants it
--      open on purpose calls Shell.Reopen(f); code that hides it for its own reasons calls Shell.Hide(f)
--    - Escape does NOT close these windows (people fight with them mid-raid)
--  Content starts at f.contentTop (negative y offset below the title bar).
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Shell = {}
LC.Frames.Shell = Shell

local TOP = -32
local tracked = {}

local function Positions()
    local s = LC.DB.Settings()
    if type(s.framePos) ~= "table" then s.framePos = {} end
    return s.framePos
end

-- opts: name, title, width, height, point = { point, x, y } (default CENTER), strata, growDown (save the top-left corner)
function Shell.Create(opts)
    local Window = NSI.UI and NSI.UI.Window
    if not Window then return nil end
    local f = Window.Create({
        name = opts.name, width = opts.width, height = opts.height, title = opts.title,
        minWidth = opts.minWidth, minHeight = opts.minHeight,
        strata = opts.strata or "HIGH", headerHeight = 28, footerHeight = 1, closeOnEscape = false,
        userScale = function() return LC.DB.Settings().scale or 1 end,
    })
    if f.Footer then f.Footer:Hide() end
    f:SetClampedToScreen(true)
    f.contentTop = TOP
    f.defaultPoint = opts.point or { "CENTER", 0, 0 }

    function f:ApplyPosition()
        local pos = Positions()[opts.name]
        self:ClearAllPoints()
        if pos then
            self:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
        else
            local d = self.defaultPoint
            self:SetPoint(d[1], UIParent, d[1], d[2], d[3])
        end
    end
    f:ApplyPosition()

    f:HookScript("OnMouseUp", function(self)
        local p, _, rp, x, y = self:GetPoint(1)
        if opts.growDown and self:GetLeft() then
            -- windows that change height keep their top-left corner still, so they always grow downward
            p, rp, x, y = "TOPLEFT", "BOTTOMLEFT", self:GetLeft(), self:GetTop()
        end
        if p then Positions()[opts.name] = { p, rp, x, y } end
    end)
    f:HookScript("OnHide", function(self) if not self.silent then self.dismissed = true end end)
    f:Hide()
    f.dismissed = false          -- the Hide above is ours, not the user's
    tracked[#tracked + 1] = f
    return f
end

-- Hide because the code says so (not because the user closed it).
function Shell.Hide(f)
    if not f then return end
    f.silent = true
    f:Hide()
    f.silent = false
end

-- Show unless the user closed it. Returns true when shown.
function Shell.Show(f)
    if not f or f.dismissed then return false end
    f:Show()
    return true
end

-- Show on purpose (clears the user's earlier close).
function Shell.Reopen(f)
    if not f then return end
    f.dismissed = false
    f:Show()
end

-- A section card like the ones in the main window: dark inset, subtle border, and (with a title) an
-- accent title over an accent rule. Put children in card.content, which sits inside the padding;
-- card.inset is the height above the content, so Shell.CardHeight(card, contentHeight) is the card's
-- own height. headerButton = { label, func, tooltip } adds a button to the title row (card.headerButton).
function Shell.Card(parent, title, headerButton)
    local C = NSI.UI.Components
    local card = C.CreateSectionCard(parent, 100, title ~= nil, headerButton)
    local pad = tonumber(C.CardPad) or 10
    local headerH = tonumber(card.headerH) or (title and 38 or 0)
    card.pad, card.headerH, card.inset = pad, headerH, headerH + pad
    if title and card.title then card.title:SetText(title) end
    card.content:ClearAllPoints()
    card.content:SetPoint("TOPLEFT", card, "TOPLEFT", pad, -card.inset)
    card.content:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -pad, pad)
    return card
end

function Shell.CardHeight(card, contentHeight)
    return card.inset + contentHeight + card.pad
end

function Shell.ResetPositions()
    LC.DB.Settings().framePos = {}
end

LC.On("NSRT_LC_SCALE_CHANGED", function(v)
    for _, f in ipairs(tracked) do f:SetScale(v or 1) end
end)
