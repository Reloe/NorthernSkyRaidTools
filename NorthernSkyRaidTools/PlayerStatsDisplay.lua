local _, NSI = ...

local DEFAULT_FONT_PATH = [[Interface\Addons\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]

-- Order also drives the checkbox list in the Aura Tracking options panel
-- (Display > Player Stats > Stats to Display).
local STAT_DEFS = {
    { key = "Crit",      abbrev = "C", label = "Critical Strike", rating = CR_CRIT_MELEE,             sample = 1234 },
    { key = "Haste",     abbrev = "H", label = "Haste",           rating = CR_HASTE_MELEE,             sample = 987 },
    { key = "Mastery",   abbrev = "M", label = "Mastery",         rating = CR_MASTERY,                 sample = 2500 },
    { key = "Vers",      abbrev = "V", label = "Versatility",     rating = CR_VERSATILITY_DAMAGE_DONE, sample = 800 },
    { key = "Avoidance", abbrev = "A", label = "Avoidance",       rating = CR_AVOIDANCE,                sample = 450 },
    { key = "Leech",     abbrev = "L", label = "Leech",           rating = CR_LIFESTEAL,                sample = 300 },
    { key = "Speed",     abbrev = "S", label = "Speed",           rating = CR_SPEED,                    sample = 650 },
}
NSI.PlayerStatsDisplayStatDefs = STAT_DEFS

local DEFAULT_ENABLED_STATS = { Crit = true, Haste = true, Mastery = true }

-- Old saved variables (and the profile default) may predate the Stats/
-- TextColor fields, so fill them in on first access rather than requiring a
-- profile reset.
function NSI:EnsurePlayerStatsDisplaySettings()
    local settings = NSRT and NSRT.PlayerStatsDisplay
    if not settings then return nil end
    settings.Stats = settings.Stats or {}
    for _, def in ipairs(STAT_DEFS) do
        if settings.Stats[def.key] == nil then
            settings.Stats[def.key] = DEFAULT_ENABLED_STATS[def.key] or false
        end
    end
    settings.TextColor = settings.TextColor or { 1, 1, 1, 1 }
    return settings
end

local function CountEnabledStats(settings)
    local n = 0
    for _, def in ipairs(STAT_DEFS) do
        if settings.Stats and settings.Stats[def.key] then n = n + 1 end
    end
    return n
end

local function BuildPlayerStatsText(settings)
    -- GetCombatRating values can be secret (e.g. in combat), and secret
    -- values can't be concatenated once formatted into strings. So rather
    -- than building each "Label: 123" line separately and joining them with
    -- table.concat/.., the whole multi-line string is produced by a single
    -- string.format call - the per-line "%s: %d" template pieces joined by
    -- "\n" are plain literals, never secret, so concatenating *those* is
    -- safe; only the final formatted result may carry a secret taint, and it
    -- never needs to be concatenated with anything else.
    local formatParts, args = {}, {}
    for _, def in ipairs(STAT_DEFS) do
        if settings.Stats[def.key] then
            formatParts[#formatParts + 1] = "%s: %d"
            args[#args + 1] = def.abbrev
            -- GetCombatRating can report 0/nil for a moment right after login
            -- before the game finishes loading player stats, so fall back to
            -- 0 rather than let string.format error on a nil and silently
            -- abort before F:Show().
            args[#args + 1] = GetCombatRating(def.rating) or 0
        end
    end
    return string.format(table.concat(formatParts, "\n"), unpack(args))
end

local function BuildPlayerStatsPreviewText(settings)
    local lines = {}
    for _, def in ipairs(STAT_DEFS) do
        if settings.Stats[def.key] then
            lines[#lines + 1] = string.format("%s: %d", def.abbrev, def.sample)
        end
    end
    return table.concat(lines, "\n")
end

-- Mirrors AuraTracking's GetAuraTrackingAnchorFrame, minus the ability to
-- anchor to another Aura Tracking display (not meaningful for this display).
local function ResolvePlayerStatsAnchorFrame(self, settings)
    local frameName = settings and settings.CustomAnchorFrame
    local frame = frameName and frameName ~= "" and _G[frameName]
    if type(frame) == "table" and frame.GetCenter and frame.IsShown then
        return frame
    end
    return self.NSRTFrame
end

function NSI:CreatePlayerStatsDisplay()
    if self.NSRTFrame.PlayerStatsDisplay then return self.NSRTFrame.PlayerStatsDisplay end
    local F = CreateFrame("Frame", "NSRTPlayerStatsDisplay", self.NSRTFrame)
    F.text = F:CreateFontString(nil, "OVERLAY")
    F.text:SetPoint("CENTER")
    F.text:SetJustifyH("CENTER")
    F:SetScript("OnDragStart", function(f) f:StartMoving() end)
    F:SetScript("OnDragStop", function(f) self:StopFrameMove(f, NSRT.PlayerStatsDisplay) end)
    self.NSRTFrame.PlayerStatsDisplay = F
    return F
end

local STATS_DISPLAY_WIDTH = 50

-- Applies Anchor/relativeTo/CustomAnchorFrame/xOffset/yOffset/FrameStrata/
-- Width/Height. Split out from UpdatePlayerStatsDisplay so the options panel
-- can reposition the live preview frame without touching its (sample) text.
--
-- Width is a fixed constant; height scales with the number of enabled stat
-- lines. Neither is computed from the rendered text itself: the text can be
-- built from a secret combat rating (e.g. in combat), and
-- GetStringWidth/GetStringHeight return secret values in that case, which
-- SetSize rejects outright. Stat count and font size are plain saved-variable
-- numbers, never secret, so sizing from those is always safe.
function NSI:ApplyPlayerStatsDisplayPosition()
    local settings = NSRT.PlayerStatsDisplay
    local F = self:CreatePlayerStatsDisplay()
    local anchorFrame = ResolvePlayerStatsAnchorFrame(self, settings)
    F:ClearAllPoints()
    F:SetPoint(settings.Anchor or "CENTER", anchorFrame, settings.relativeTo or "CENTER", settings.xOffset or 0,
        settings.yOffset or 0)
    F:SetFrameStrata(settings.FrameStrata or "MEDIUM")
    local lineHeight = (settings.FontSize or 14)
    local numLines = math.max(CountEnabledStats(settings), 1)
    F:SetSize(STATS_DISPLAY_WIDTH, lineHeight * numLines)
end

function NSI:ApplyPlayerStatsDisplayFont()
    local settings = self:EnsurePlayerStatsDisplaySettings()
    local F = self:CreatePlayerStatsDisplay()
    local fontPath = self.LSM:Fetch("font", settings.TextFont, true) or DEFAULT_FONT_PATH
    F.text:SetFont(fontPath, settings.FontSize or 14, settings.TextFontFlags or "OUTLINE")
    F.text:SetJustifyH(settings.TextAlign or "CENTER")
    local color = settings.TextColor
    F.text:SetTextColor(color[1], color[2], color[3], color[4])
end

-- Recomputes and shows/hides the display based on the current settings. Safe
-- to call any time (login, gear/buff changes, options edits).
function NSI:UpdatePlayerStatsDisplay()
    local settings = self:EnsurePlayerStatsDisplaySettings()
    if self.IsPlayerStatsPreview then return end
    if not settings or not settings.enabled then
        if self.NSRTFrame.PlayerStatsDisplay then self.NSRTFrame.PlayerStatsDisplay:Hide() end
        return
    end
    self:ApplyPlayerStatsDisplayPosition()
    self:ApplyPlayerStatsDisplayFont()
    local F = self.NSRTFrame.PlayerStatsDisplay
    F.text:SetText(BuildPlayerStatsText(settings))
    F:Show()
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function()
    NSI:UpdatePlayerStatsDisplay()
end)

function NSI:InitPlayerStatsDisplay()
    if NSRT.PlayerStatsDisplay and NSRT.PlayerStatsDisplay.enabled then
        eventFrame:RegisterEvent("COMBAT_RATING_UPDATE")
    else
        eventFrame:UnregisterAllEvents()
    end

    self:UpdatePlayerStatsDisplay()
end

-- Toggles the draggable preview shown from the Aura Tracking options panel.
-- Mirrors NSI:ToggleQoLTextPreview.
function NSI:SetPlayerStatsPreview(active)
    active = active and true or false
    if self.IsPlayerStatsPreview == active then return end
    self.IsPlayerStatsPreview = active
    local F = self:CreatePlayerStatsDisplay()
    if active then
        local settings = self:EnsurePlayerStatsDisplaySettings()
        self:ApplyPlayerStatsDisplayPosition()
        self:ApplyPlayerStatsDisplayFont()
        F.text:SetText(BuildPlayerStatsPreviewText(settings))
        self:MakeDraggable(F, NSRT.PlayerStatsDisplay, true)
    else
        self:MakeDraggable(F, NSRT.PlayerStatsDisplay, false)
        self:UpdatePlayerStatsDisplay()
    end
end

function NSI:TogglePlayerStatsPreview()
    self:SetPlayerStatsPreview(not self.IsPlayerStatsPreview)
end

-- While previewing, options-panel edits (Anchor/Offsets/Font/...) should move
-- the live preview frame immediately instead of waiting for preview to end.
function NSI:RefreshPlayerStatsDisplayLive()
    if self.IsPlayerStatsPreview then
        local settings = self:EnsurePlayerStatsDisplaySettings()
        self:ApplyPlayerStatsDisplayPosition()
        self:ApplyPlayerStatsDisplayFont()
        local F = self.NSRTFrame.PlayerStatsDisplay
        F.text:SetText(BuildPlayerStatsPreviewText(settings))
    else
        self:UpdatePlayerStatsDisplay()
    end
end

function NSI:ResetPlayerStatsDisplayPosition()
    local settings = NSRT.PlayerStatsDisplay
    settings.Anchor = "CENTER"
    settings.relativeTo = "CENTER"
    settings.CustomAnchorFrame = "UIParent"
    settings.xOffset = 0
    settings.yOffset = 250
    settings.FrameStrata = "MEDIUM"
    self:RefreshPlayerStatsDisplayLive()
end
