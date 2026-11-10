local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]

local function T(key)
    if key == nil then return nil end
    return NSI:Loc(key)
end

-- Every colour ({r, g, b, a}), size and alpha the timeline window draws with.
local STYLE = {
    panel = {0.051, 0.055, 0.078, 0.97},
    panelBorder = {0.11, 0.435, 0.463, 1},
    titleBar = {0.078, 0.082, 0.106, 1},
    titleSize = 13,
    canvas = {0.122, 0.122, 0.133, 1},
    canvasBorder = {1, 1, 1, 0.06},
    text = {0.925, 0.925, 0.925, 1},
    textDim = {0.561, 0.576, 0.6, 1},
    labelText = {0.812, 0.824, 0.839, 1},
    accent = {0.09, 0.878, 0.91, 1},
    danger = {0.878, 0.337, 0.31, 1},
    warning = {0.98, 0.71, 0.26, 1},
    warningHover = {1, 0.82, 0.47, 1},
    warningText = {0.1, 0.06, 0.01, 1},
    success = {0.45, 0.9, 0.55, 1},
    statusInfo = {0.843, 0.969, 0.976, 1},
    helpText = {0.561, 0.576, 0.6, 0.8},
    neutralCategory = {0.7, 0.7, 0.7},

    windowPad = 10,
    topBarY = -30,
    controlHeight = 22,
    controlGap = 6,
    groupGap = 14,
    barLabelSize = 11,
    controlTextSize = 12,
    noteMenuRows = 20,
    bossPickerTextSize = 11,
    barIconSize = 14,
    sharedWidth = 96,
    previewWidth = 114,
    loadNoteFill = {0.09, 0.878, 0.91, 1},
    loadNoteHover = {0.5, 0.96, 0.98, 1},
    loadNoteText = {0.03, 0.06, 0.08, 1},
    titleButtonTextSize = 11,
    -- The Personal dropdown shrinks toward min when the bar is short (LayoutTopBar).
    personalWidth = {min = 140, max = 300},
    menuWidth = 240,
    viewOnlyText = {0.561, 0.576, 0.6, 1},
    canvasTop = 60,
    canvasBottom = 34,
    minWidth = 900,
    minHeight = 420,
    maxWidth = 2000,
    maxHeight = 1200,

    headerWidth = 200,
    headerBg = {0.09, 0.094, 0.11, 1},
    rowHeight = 20,
    stripe = {1, 1, 1, 0.04},
    hover = {0, 1, 1, 0.13},
    sectionHeight = 16,
    sectionText = {0.561, 0.576, 0.6, 1},
    sectionTextSize = 9,
    sectionRule = {0.09, 0.878, 0.91, 0.25},
    -- Class-coloured player lanes: a tint over body and header rows, and a strip down the header's left edge.
    laneTintAlpha = 0.10,
    laneTintHeaderAlpha = 0.18,
    laneStripWidth = 2,
    -- The row between boss and player rows that holds the [All | Mine] and [Rows | Compact] pairs.
    filterRowHeight = 22,
    filterRowBg = {0, 0, 0, 1},
    filterButtonHeight = 16,
    filterButtonTextSize = 10,
    filterRowPad = 4,
    filterSegmentPad = 7,
    filterSegmentDivider = 1, -- the black row shows through as the divider
    filterPairGap = 10,
    groupDivider = {1, 1, 1, 0.14},
    mineDivider = {0.09, 0.878, 0.91, 0.18}, -- under this character's own rows
    mineDividerHeight = 1,
    headerIconSize = 16,
    headerIconX = 8,
    headerLabelX = 30,
    playerNameX = 8, -- from the left edge; player rows end like boss rows (label, then icon)
    playerNameWidth = 60, -- names that don't fit truncate; the lane tooltip shows them in full
    playerNameGap = 6,
    labelTextSize = 11,
    roleIconSize = 12,
    roleIconGap = 2,
    headerCheckSize = 14,
    headerCheckGap = 4,
    checkBg = {0.051, 0.055, 0.078, 1},
    checkBorder = {1, 1, 1, 0.22},
    checkBorderHover = {0.09, 0.878, 0.91, 0.8},
    checkFill = {0.09, 0.878, 0.91, 0.7},
    checkMark = "Interface\\Buttons\\UI-CheckBox-Check",
    abilityMenuWidth = 270,

    blockIconSize = 20,
    personalEdge = 1, -- accent frame on reminders from the personal note
    maxBlockStack = 100, -- reminder stacking levels; stays under the canvas lines (body + 150)
    tickWidth = 3,
    tickHitWidth = 7,
    bossBarAlpha = 0.28,
    castLineThickness = 2, -- the cast line and its end cap
    readOnlyAlpha = 0.75, -- the loaded shared note's reminders
    viewOnlyAlpha = 0.55, -- a shared note picked for viewing only
    prePullAlpha = 0.5,
    invalidAlpha = 0.35,
    minLuminance = 0.42,

    rulerHeight = 20,
    rulerLevel = 300, -- over the body's cursor, drag and now lines
    legendStrata = "FULLSCREEN_DIALOG", -- one above the window's DIALOG, so over the ruler and every canvas overlay
    minZoom = 0.05, -- lets Fit show the longest boss timeline in the narrowest window
    ruler = {0.09, 0.094, 0.11, 1},
    rulerText = {0.741, 0.741, 0.741, 1},
    rulerTextSize = 10,
    rulerMinLabelGap = 56,
    rulerMinMinorGap = 6,
    majorTick = {1, 1, 1, 0.45},
    majorTickHeight = 7,
    minorTick = {1, 1, 1, 0.3},
    minorTickHeight = 4,
    gridLine = {1, 1, 1, 0.06},

    phaseLaneHeight = 12, -- the DF timeline leaves 12 px between its ruler and the first row
    phaseLane = {1, 1, 1, 0.03},
    phaseLaneBorder = {1, 1, 1, 0.07},
    chipHeight = 11,
    chipTextSize = 9,
    phaseChip = {0.169, 0.239, 0.251, 1},
    phaseChipText = {0.749, 0.933, 0.945, 1},
    phaseChipDrag = {0.09, 0.878, 0.91, 0.45},
    endChip = {0.2, 0.204, 0.227, 1},
    endChipText = {0.663, 0.678, 0.702, 1},
    phaseLine = {1, 1, 1, 0.5},
    endLine = {1, 1, 1, 0.22},
    phaseGrabWidth = 9,
    scrollToMargin = 40,
    nowLineIdle = 4,

    cursorLine = {1, 1, 1, 0.65},
    cursorChip = {0.055, 0.06, 0.075, 1},
    cursorChipText = {0.914, 0.914, 0.914, 1},
    rulerChipHeight = 17,
    rulerChipTextSize = 12,
    dragIconAlpha = 0.9,
    previewLine = {0.3, 0.85, 0.4, 0.9},
    previewChip = {0.03, 0.09, 0.04, 1},
    previewChipText = {0.3, 0.85, 0.4, 1},

    scrollBarSize = 8,
    scrollBarGap = 2,
    scrollTrack = {0.082, 0.086, 0.102, 1},
    scrollThumb = {0.09, 0.878, 0.91, 0.45},
    scrollThumbMin = 24,

    emptyTextSize = 13,
    emptyBg = {0.051, 0.055, 0.078, 0.85},
    emptyWidth = 420,
    footerY = 8,
    footerButtonHeight = 18,
    helpTextSize = 10,
    statusTextSize = 11,

    dialogWidth = 400,
    dialogHeight = 392,
    dialogLabelX = 12,
    dialogLabelWidth = 70,
    dialogFieldX = 88,
    dialogForWidth = 150,
    -- Rows with two fields: Duration and TTS timer, Display type and Color.
    dialogShortFieldWidth = 70,
    dialogColumn2LabelX = 172,
    dialogColumn2FieldX = 240,
    dialogSwatchWidth = 40,
    dialogPhaseButtonGap = 4,
    dialogPhaseButtonMinWidth = 24,
    dialogFirstRowY = -40,
    dialogRowPitch = 28,
    dialogTitleSize = 13,
    dialogLabelSize = 12,
    dialogHintSize = 11,
    dialogRule = {0.09, 0.878, 0.91, 0.2},
}

local function Paint(texture, c, alpha)
    texture:SetColorTexture(c[1], c[2], c[3], alpha or c[4] or 1)
end

local function Tint(fontString, c, alpha)
    fontString:SetTextColor(c[1], c[2], c[3], alpha or c[4] or 1)
end

local function SetUIFont(fontString, size)
    fontString:SetFont(NSI:ValidateFontPath(NSI:GetUIFontPath()), size, NSI:GetUIFontFlags())
end

local function Colored(text, c)
    return string.format("|cff%02x%02x%02x%s|r", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5),
        math.floor(c[3] * 255 + 0.5), text)
end

-- Every timeline tooltip: title, then the time line, then details.
local function TooltipTitle(owner, title, r, g, b)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if not r then r, g, b = STYLE.text[1], STYLE.text[2], STYLE.text[3] end
    GameTooltip:AddLine(title or "", r, g, b)
end

local function TooltipLine(text, c)
    c = c or STYLE.labelText
    GameTooltip:AddLine(text, c[1], c[2], c[3], true)
end

local function NewFontString(parent, size, color, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    SetUIFont(fs, size)
    Tint(fs, color or STYLE.text)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

--------------------------------------------------------------------------------
-- NOTE LINE CODEC
-- Pure helpers for the "key:value;" reminder line format parsed by ProcessReminder.
--------------------------------------------------------------------------------

-- Splits on "\n" like ProcessReminder, so line indices match the runtime's.
-- seps[i] is the terminator that followed lines[i] ("\n", "\r\n", or "" for an
-- unterminated last line); NoteJoinLines(NoteSplitLines(s)) == s.
function NSI:NoteSplitLines(str)
    local lines, seps = {}, {}
    if not str or str == "" then return lines, seps end
    local pos, len = 1, #str
    while pos <= len do
        local nl = str:find("\n", pos, true)
        if nl then
            local lineEnd, sep = nl - 1, "\n"
            if lineEnd >= pos and str:byte(lineEnd) == 13 then
                lineEnd, sep = lineEnd - 1, "\r\n"
            end
            lines[#lines + 1] = str:sub(pos, lineEnd)
            seps[#seps + 1] = sep
            pos = nl + 1
        else
            lines[#lines + 1] = str:sub(pos)
            seps[#seps + 1] = ""
            pos = len + 1
        end
    end
    return lines, seps
end

-- Without seps every line is terminated by "\n".
function NSI:NoteJoinLines(lines, seps)
    local parts = {}
    for i = 1, #lines do
        parts[#parts + 1] = lines[i]
        parts[#parts + 1] = seps and seps[i] or "\n"
    end
    return table.concat(parts)
end

local function EscapePattern(s)
    return (s:gsub("(%W)", "%%%1"))
end

-- Returns valueStart, valueEnd, fieldStart, closingSemicolon (nil when the field is last
-- without a trailing ";"). Only matches at a field boundary, never inside another value.
local function FindNoteField(line, key)
    local k = EscapePattern(key)
    local fieldStart = 1
    local _, e = line:find("^%s*" .. k .. ":")
    if not e then
        local s
        s, e = line:find(";%s*" .. k .. ":")
        if not s then return nil end
        fieldStart = s + 1
    end
    local semi = line:find(";", e + 1, true)
    return e + 1, (semi or (#line + 1)) - 1, fieldStart, semi
end

function NSI:NoteSanitizeValue(value)
    value = tostring(value or ""):gsub(";", ","):gsub("[\r\n]", "")
    return value
end

-- Raw value of the first `key:` field, or nil. Values are strings ("" for "key:;").
function NSI:NoteGetField(line, key)
    if not line then return nil end
    local vs, ve = FindNoteField(line, key)
    if not vs then return nil end
    return line:sub(vs, ve)
end

-- Leading number of a field the way ProcessReminder reads it (time may be negative).
function NSI:NoteGetNumber(line, key, allowNegative)
    local value = self:NoteGetField(line, key)
    if not value then return nil end
    return tonumber(value:match(allowNegative and "^%-?%d*%.?%d+" or "^%d*%.?%d+"))
end

function NSI:NoteSetField(line, key, value)
    line = line or ""
    value = self:NoteSanitizeValue(value)
    local vs, ve = FindNoteField(line, key)
    if vs then
        return line:sub(1, vs - 1) .. value .. line:sub(ve + 1)
    end
    if line:match("^%s*$") then
        return key .. ":" .. value
    end
    if line:find(";%s*$") then
        return line .. key .. ":" .. value .. ";"
    end
    return line .. ";" .. key .. ":" .. value
end

-- Removes every occurrence of the field together with one adjacent separator.
function NSI:NoteRemoveField(line, key)
    if not line then return line end
    while true do
        local vs, _, fieldStart, semi = FindNoteField(line, key)
        if not vs then break end
        if semi then
            line = line:sub(1, fieldStart - 1) .. line:sub(semi + 1)
        elseif fieldStart > 1 then
            line = line:sub(1, fieldStart - 2)
        else
            line = ""
        end
    end
    return line
end

-- Same tokenising as TagMatchesPlayer in Reminders.lua; matching there is case-insensitive.
function NSI:NoteTagTokens(tagValue)
    local tokens = {}
    if tagValue then
        for token in tagValue:gmatch("%S+") do
            tokens[#tokens + 1] = token
        end
    end
    return tokens
end

--------------------------------------------------------------------------------
-- DRAWING RULES
-- Pure helpers behind the timeline visuals; pps is pixels per second after zoom.
--------------------------------------------------------------------------------

local RULER_STEPS = {
    {5, 1}, {10, 5}, {15, 5}, {30, 10}, {60, 15}, {120, 30},
}

-- Smallest label step whose labels sit at least minGap px apart; minor is nil when too dense.
function NSI:TimelineRulerStep(pps, minGap)
    minGap = minGap or STYLE.rulerMinLabelGap
    local step = RULER_STEPS[#RULER_STEPS]
    if pps and pps > 0 then
        for i = 1, #RULER_STEPS do
            if RULER_STEPS[i][1] * pps >= minGap then
                step = RULER_STEPS[i]
                break
            end
        end
    end
    local minor = step[2]
    if not pps or pps <= 0 or minor * pps < STYLE.rulerMinMinorGap then
        minor = nil
    end
    return step[1], minor
end

-- Lifts dark colours toward white until their relative luminance reaches minLum.
function NSI:BrightenTimelineColor(r, g, b, minLum)
    minLum = minLum or STYLE.minLuminance
    r, g, b = r or 0, g or 0, b or 0
    local lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    if lum >= minLum or lum >= 1 then return r, g, b end
    local t = (minLum - lum) / (1 - lum)
    return r + (1 - r) * t, g + (1 - g) * t, b + (1 - b) * t
end

-- Marks the first row of each player/tag lane group (groupStart) and the divider above it.
function NSI:MarkTimelineLaneGroups(lines)
    local prevKey, prevWasLane
    for _, line in ipairs(lines) do
        if line.isPlayerAssignment then
            local key = line.laneKey or line.playerName or line.text
            line.groupStart = key ~= prevKey or not prevWasLane
            line.groupDivider = line.groupStart and prevWasLane or false
            prevKey, prevWasLane = key, true
        else
            line.groupStart, line.groupDivider = nil, nil
            prevKey, prevWasLane = nil, false
        end
    end
    return lines
end

function NSI:TimelineSectionLine(title)
    return {text = title, timeline = {}, isSection = true, disabled = true, lineHeight = STYLE.sectionHeight}
end

-- The "Players" section as the window draws it: a black band that carries the row filters.
function NSI:TimelineFilterLine()
    local line = self:TimelineSectionLine(T("Players"))
    line.isFilterRow = true
    line.lineHeight = STYLE.filterRowHeight
    return line
end

-- Greedy first-fit rows for icons width seconds wide starting at times (in walk order): each goes into the first
-- row whose last icon ends by its start, else a new row. Returns the row index per time and the row count.
function NSI:PackTimelineRows(times, width)
    local rowEnds, rows = {}, {}
    for i, t in ipairs(times) do
        local row
        for r = 1, #rowEnds do
            if rowEnds[r] <= t + 1e-6 then
                row = r
                break
            end
        end
        row = row or #rowEnds + 1
        rowEnds[row] = t + width
        rows[i] = row
    end
    return rows, #rowEnds
end

-- The "Boss abilities" section row, for timeline data built without the window's filter row.
function NSI:BossAbilitySectionLine()
    local line = self:TimelineSectionLine(T("Boss abilities"))
    line.isBossSection = true
    return line
end

-- "ffRRGGBB" (or "RRGGBB") to 0-1 components; nil when the string isn't hex.
local function HexToColor(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:match("^%x%x(%x%x%x%x%x%x)$") or hex:match("^(%x%x%x%x%x%x)$")
    if not hex then return nil end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end
NSI.TimelineHexToColor = HexToColor

-- The one colour resolver for rows, ticks, bars, strips and tooltips.
local function ResolveColor(c)
    c = c or STYLE.neutralCategory
    return NSI:BrightenTimelineColor(c[1], c[2], c[3])
end

local function BlockColor(payload, lineData)
    if payload and payload.color then return ResolveColor(payload.color) end
    if payload and payload.isBossAbility then return ResolveColor(lineData and lineData.color) end
    local a = STYLE.accent
    return a[1], a[2], a[3]
end

local function SetChipText(chip, text)
    chip.text:SetText(text)
    chip:SetWidth(chip.text:GetStringWidth() + 8)
end

-- Phase whose start is the latest at or before absTime, from the arrays UpdatePhaseMarkers caches.
local function CachedPhaseAt(window, absTime)
    local keys, starts = window.phaseKeys, window.phaseStartTimes
    local phase, start = 1, 0
    if keys then
        for i = 1, #keys do
            if starts[i] <= absTime and starts[i] >= start then
                phase, start = keys[i], starts[i]
            end
        end
    end
    return phase, start
end

-- The boss on screen, taken when a menu opens or a press starts so a refresh before the click can't retarget a write.
local function ShownBoss(window)
    return {encID = window.currentEncounterID, difficulty = window.currentDifficulty}
end

-- Setup timeline hooks for zoom-to-cursor and sticky ruler
-- Call this after creating a timeline with DF:CreateTimeLineFrame
function NSI:SetupTimelineHooks(timeline)
    if not timeline then return end

    local horizontalSlider = timeline.horizontalSlider
    local scaleSlider = timeline.scaleSlider
    local elapsedTimeFrame = timeline.elapsedTimeFrame

    -- Override mousewheel: scroll = zoom-to-cursor, shift+scroll = vertical pan
    if scaleSlider and horizontalSlider then
        -- Storage for pre-zoom state
        timeline.preZoomState = {}

        timeline:SetScript("OnMouseWheel", function(self, delta)
            if IsControlKeyDown() then
                -- Vertical scroll. verticalSlider's units are raw content pixels
                -- (SetMinMaxValues(0, bodyHeight - visibleHeight) in the DF timeline
                -- lib), so scroll by whole rows rather than a flat pixel count or it
                -- feels far slower than a normal list/scrollframe.
                if timeline.verticalSlider then
                    local rowHeight = (timeline.options.line_height or 20) + (timeline.options.line_padding or 0)
                    local cur = timeline.verticalSlider:GetValue()
                    local vMin, vMax = timeline.verticalSlider:GetMinMaxValues()
                    timeline.verticalSlider:SetValue(math.max(vMin, math.min(vMax, cur - delta * rowHeight * 3)))
                end
                return
            end

            -- Zoom to cursor (always, no modifier needed)
            local pixelPerSecond = timeline.options.pixels_per_second or 15
            local currentScale = timeline.currentScale or 1

            local cursorX = GetCursorPosition()
            -- Use this timeline frame's own effective scale, not UIParent's — the
            -- timeline window has an adjustable scale bar, so the two can differ.
            local uiScale = 1 / timeline:GetEffectiveScale()
            cursorX = cursorX * uiScale
            local frameLeft = timeline:GetLeft() or 0
            local mouseXInFrame = cursorX - frameLeft
            local scrollPosition = horizontalSlider:GetValue()
            local timeUnderMouse = (scrollPosition + mouseXInFrame) / (pixelPerSecond * currentScale)

            timeline.preZoomState.timeUnderMouse = timeUnderMouse
            timeline.preZoomState.mouseXInFrame = mouseXInFrame
            timeline.preZoomState.pixelPerSecond = pixelPerSecond

            local sMin, sMax = scaleSlider:GetMinMaxValues()
            local newScale = math.max(sMin, math.min(sMax, currentScale * (delta > 0 and 1.15 or (1 / 1.15))))
            scaleSlider:SetValue(newScale)
        end)

        -- Hook scale slider to adjust scroll after zoom
        scaleSlider:HookScript("OnValueChanged", function(self)
            local state = timeline.preZoomState
            if state and state.timeUnderMouse then
                local newScale = timeline.currentScale or 1

                -- Calculate where the time under mouse is now
                local timeInNewScale = state.timeUnderMouse * state.pixelPerSecond * newScale

                -- Set scroll so the time stays under the mouse
                local newScrollValue = max(0, timeInNewScale - state.mouseXInFrame)
                local _, maxScroll = horizontalSlider:GetMinMaxValues()
                horizontalSlider:SetValue(min(newScrollValue, maxScroll))

                -- Clear state
                timeline.preZoomState = {}
            end
        end)
    end

    -- Sticky ruler and phase lane: fixed while rows scroll vertically, moving with the content horizontally.
    if elapsedTimeFrame and timeline.verticalSlider and horizontalSlider then
        -- Sits above the cursor and drag lines so the chips on it stay readable.
        local stickyHeight = STYLE.rulerHeight + STYLE.phaseLaneHeight
        local rulerContainer = CreateFrame("Frame", nil, timeline)
        rulerContainer:SetPoint("TOPLEFT", timeline, "TOPLEFT", 0, 0)
        rulerContainer:SetPoint("TOPRIGHT", timeline, "TOPRIGHT", 0, 0)
        rulerContainer:SetHeight(stickyHeight)
        rulerContainer:SetClipsChildren(true)
        rulerContainer:SetFrameLevel(timeline.body:GetFrameLevel() + STYLE.rulerLevel)
        timeline.rulerContainer = rulerContainer

        local rulerBase = rulerContainer:CreateTexture(nil, "BACKGROUND")
        rulerBase:SetPoint("TOPLEFT", rulerContainer, "TOPLEFT", 0, 0)
        rulerBase:SetPoint("TOPRIGHT", rulerContainer, "TOPRIGHT", 0, 0)
        rulerBase:SetHeight(STYLE.rulerHeight)
        Paint(rulerBase, STYLE.ruler)
        local laneBase = rulerContainer:CreateTexture(nil, "BACKGROUND")
        laneBase:SetPoint("BOTTOMLEFT", rulerContainer, "BOTTOMLEFT", 0, 0)
        laneBase:SetPoint("BOTTOMRIGHT", rulerContainer, "BOTTOMRIGHT", 0, 0)
        laneBase:SetHeight(STYLE.phaseLaneHeight)
        Paint(laneBase, STYLE.canvas)
        local laneTint = rulerContainer:CreateTexture(nil, "BORDER")
        laneTint:SetAllPoints(laneBase)
        Paint(laneTint, STYLE.phaseLane)
        local laneRule = rulerContainer:CreateTexture(nil, "BORDER")
        laneRule:SetPoint("BOTTOMLEFT", laneBase, "BOTTOMLEFT", 0, 0)
        laneRule:SetPoint("BOTTOMRIGHT", laneBase, "BOTTOMRIGHT", 0, 0)
        laneRule:SetHeight(1)
        Paint(laneRule, STYLE.phaseLaneBorder)

        local rulerStrip = CreateFrame("Frame", nil, rulerContainer)
        rulerStrip:SetHeight(stickyHeight)
        rulerStrip:SetFrameLevel(rulerContainer:GetFrameLevel() + 1)
        timeline.rulerStrip = rulerStrip

        elapsedTimeFrame:SetParent(rulerStrip)
        elapsedTimeFrame:SetHeight(STYLE.rulerHeight)
        elapsedTimeFrame:SetFrameLevel(rulerStrip:GetFrameLevel() + 1)
        elapsedTimeFrame:EnableMouse(false)

        -- RefreshTimeLine anchors the ruler back onto the body, so this runs after every refresh too.
        local function updateRulerPosition()
            rulerStrip:ClearAllPoints()
            rulerStrip:SetPoint("TOPLEFT", rulerContainer, "TOPLEFT", -(horizontalSlider:GetValue() or 0), 0)
            rulerStrip:SetWidth(timeline.body:GetWidth() or timeline:GetWidth())
            elapsedTimeFrame:ClearAllPoints()
            elapsedTimeFrame:SetPoint("TOPLEFT", rulerStrip, "TOPLEFT", 0, 0)
            elapsedTimeFrame:SetPoint("TOPRIGHT", rulerStrip, "TOPRIGHT", 0, 0)
        end
        timeline.updateRulerPosition = updateRulerPosition
        updateRulerPosition()
        hooksecurefunc(timeline, "RefreshTimeLine", updateRulerPosition)

        horizontalSlider:HookScript("OnValueChanged", updateRulerPosition)
        hooksecurefunc(timeline, "SetData", function()
            C_Timer.After(0.01, updateRulerPosition)
        end)
        if scaleSlider then
            scaleSlider:HookScript("OnValueChanged", function()
                C_Timer.After(0.01, updateRulerPosition)
            end)
        end
    end
end

-- Ability lines without those whose abilityKey is in hidden, and how many were left out.
function NSI:FilterHiddenBossAbilities(lines, hidden)
    local visible, hiddenCount = {}, 0
    for _, line in ipairs(lines or {}) do
        if type(hidden) == "table" and line.abilityKey ~= nil and hidden[line.abilityKey] == true then
            hiddenCount = hiddenCount + 1
        else
            visible[#visible + 1] = line
        end
    end
    return visible, hiddenCount
end

-- Get boss ability lines for the timeline
-- Returns lines, max time, phases, difficulty and the ability filter ({encounterID, choices, hiddenCount};
-- choices are every ability of the mode in row order, hidden or not).
-- displayMode: "all" (default), "important" (important only), "combined" (one row)
function NSI:GetBossAbilityLines(encounterID, displayMode, requestedDifficulty)
    if not encounterID or not self.BossTimelines or not self.BossTimelines[encounterID] then
        return {}, 0
    end

    -- Default to "important_healer" if no mode specified (backwards compatible with old boolean param)
    if displayMode == nil or displayMode == false then
        displayMode = self.BossDisplayModes.IMPORTANT_HEALER
    elseif displayMode == true then
        -- Legacy: true meant filter important only
        displayMode = self.BossDisplayModes.IMPORTANT_HEALER
    end

    local abilities, duration, phases, difficulty = self:GetBossTimelineAbilities(encounterID, requestedDifficulty)
    if not abilities then return {}, 0 end

    local lines = {}
    local maxTime = duration or 0

    -- Filter abilities based on display mode
    local filteredAbilities = {}
    for _, ability in ipairs(abilities) do
        local include = true
        if displayMode == self.BossDisplayModes.IMPORTANT_HEALER then
            include = self:IsAbilityImportantForHealer(ability)
        elseif displayMode == self.BossDisplayModes.IMPORTANT_TANK then
            include = self:IsAbilityImportantForTank(ability)
        elseif displayMode == self.BossDisplayModes.COMBINED_IMPORTANT then
            include = self:IsAbilityImportant(ability)
        end
        -- SHOW_ALL and COMBINED include all abilities
        if include then
            table.insert(filteredAbilities, ability)
        end
    end

    -- Normal mode: group abilities by name (since same ability can appear in multiple phases)
    local abilityGroups = {}
    for _, ability in ipairs(filteredAbilities) do
        local key = ability.name
        if not abilityGroups[key] then
            -- Get name
            local lineName = ability.name
            local spellInfo = ability.spellID and C_Spell.GetSpellInfo(ability.spellID)
            if (GetLocale() ~= "enUS") then
                if spellInfo then
                    lineName = spellInfo.name
                end
            end

            abilityGroups[key] = {
                key = key,
                name = lineName,
                spellID = spellInfo and ability.spellID or nil,
                category = ability.category,
                primaryCategory = ability.primaryCategory,
                color = ability.color,
                sortOrder = ability.sortOrder,
                times = {},
                durations = {},
                castTimes = {},
            }
        end
        -- Add all times from this ability
        for i, time in ipairs(ability.times) do
            table.insert(abilityGroups[key].times, time)
            table.insert(abilityGroups[key].durations, ability.duration)
            abilityGroups[key].castTimes[#abilityGroups[key].times] = ability.castTime
        end
    end

    -- Convert to timeline lines, sorted by category then name
    local sortedAbilities = {}
    for _, data in pairs(abilityGroups) do
        table.insert(sortedAbilities, data)
    end
    table.sort(sortedAbilities, function(a, b)
        -- Sort by pre-computed sort order from ParseCategoryForDisplay
        local aOrder = a.sortOrder or 99
        local bOrder = b.sortOrder or 99
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
        return a.name < b.name
    end)

    for _, abilityData in ipairs(sortedAbilities) do
        local timeline = {}

        -- Check if ability is important for healer/tank roles
        local abilityForCheck = {category = abilityData.category}
        local isImportantHealer = self:IsAbilityImportantForHealer(abilityForCheck)
        local isImportantTank = self:IsAbilityImportantForTank(abilityForCheck)

        -- Sort times
        local sortedTimes = {}
        for i, time in ipairs(abilityData.times) do
            table.insert(sortedTimes, {time = time, dur = abilityData.durations[i] or 3, castTime = abilityData.castTimes[i]})
        end
        table.sort(sortedTimes, function(a, b) return a.time < b.time end)

        -- Create timeline blocks
        for _, entry in ipairs(sortedTimes) do
            table.insert(timeline, {
                entry.time,
                0,
                true,
                entry.dur,
                abilityData.spellID,
                payload = {
                    category = abilityData.category,
                    primaryCategory = abilityData.primaryCategory,
                    important = isImportantHealer,
                    abilityName = abilityData.name,
                    castTime = entry.castTime,
                    isBossAbility = true,
                },
            })
        end

        local spellInfo = abilityData.spellID and C_Spell.GetSpellInfo(abilityData.spellID)
        local lineIcon = spellInfo and spellInfo.iconID

        table.insert(lines, {
            spellId = abilityData.spellID,
            icon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark",
            text = abilityData.name,
            abilityKey = abilityData.key,
            timeline = timeline,
            isBossAbility = true,
            category = abilityData.category,
            primaryCategory = abilityData.primaryCategory,
            color = abilityData.color,
            isImportantHealer = isImportantHealer,
            isImportantTank = isImportantTank,
        })
    end

    local choices = {}
    for _, line in ipairs(lines) do
        choices[#choices + 1] = {key = line.abilityKey, name = line.text, icon = line.icon}
    end
    local visible, hiddenCount = self:FilterHiddenBossAbilities(lines,
        self:ReadHiddenBossAbilities(NSRT.TimelineWindowState, encounterID))
    local filter = {encounterID = encounterID, choices = choices, hiddenCount = hiddenCount}

    -- Handle combined modes - put all abilities on one row
    if displayMode == self.BossDisplayModes.COMBINED or
       displayMode == self.BossDisplayModes.COMBINED_IMPORTANT then
        local combinedTimeline = {}
        local allTimes = {}
        local shown = {}
        for _, line in ipairs(visible) do shown[line.abilityKey] = true end

        for _, ability in ipairs(filteredAbilities) do
            for i, time in ipairs(shown[ability.name] and ability.times or {}) do
                table.insert(allTimes, {
                    time = time,
                    dur = ability.duration or 3,
                    spellID = ability.spellID and C_Spell.GetSpellInfo(ability.spellID) and ability.spellID or nil,
                    name = ability.name,
                    category = ability.category,
                    primaryCategory = ability.primaryCategory,
                    color = ability.color,
                    castTime = ability.castTime,
                })
            end
        end

        -- Sort by time
        table.sort(allTimes, function(a, b) return a.time < b.time end)

        -- Create timeline blocks
        for _, entry in ipairs(allTimes) do
            table.insert(combinedTimeline, {
                entry.time,
                0,
                true,
                entry.dur,
                entry.spellID,
                payload = {
                    category = entry.category,
                    primaryCategory = entry.primaryCategory,
                    color = entry.color,
                    abilityName = entry.name,
                    castTime = entry.castTime,
                    isBossAbility = true,
                },
            })
        end

        -- Every ability hidden leaves no row; only the section header remains.
        local combinedLines = {}
        if #visible > 0 or hiddenCount == 0 then
            combinedLines[1] = {
                spellId = nil,
                icon = "Interface\\ICONS\\Achievement_Boss_KilJaeden",
                text = T("All abilities"),
                timeline = combinedTimeline,
                isBossAbility = true,
                isCombined = true,
            }
        end

        return combinedLines, maxTime, phases, difficulty, filter
    end

    return visible, maxTime, phases, difficulty, filter
end

-- Value of a header field (EncounterID, Difficulty, ...) from the first line that has it.
local function NoteHeaderValue(str, key)
    local value = str and str:match(key .. ":([^;\r\n]+)")
    return value and strtrim(value)
end

-- Whole 30 s steps, padded so an icon at maxTime (anchored by its left edge) stays inside the canvas.
local function TimelineLength(maxTime)
    return math.max(60, math.ceil((maxTime + 15) / 30) * 30)
end

local BROWSE_DIFFICULTIES = {"Mythic", "Heroic"}

-- Bosses with timeline data in raid order, each {encID, label, difficulties}.
function NSI:BrowsableBosses()
    local bosses = {}
    for encID, byDifficulty in pairs(self.BossTimelines or {}) do
        local difficulties = {}
        for _, difficulty in ipairs(BROWSE_DIFFICULTIES) do
            if type(byDifficulty) == "table" and byDifficulty[difficulty] then
                difficulties[#difficulties + 1] = difficulty
            end
        end
        if #difficulties > 0 then
            bosses[#bosses + 1] = {
                encID = encID,
                label = self:GetTimelineEncounterLabel(encID),
                difficulties = difficulties,
                order = self.EncounterOrder and self.EncounterOrder[encID] or math.huge,
            }
        end
    end
    table.sort(bosses, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.encID < b.encID
    end)
    return bosses
end

-- NSRT.TimelineWindowState with anything missing, malformed or gone dropped, so the caller keeps its defaults.
-- notes: {personal = {[name] = text}, shared = {...}}; bosses: NSI.BossTimelines.
function NSI:ReadTimelineWindowState(state, notes, bosses)
    local out = {zoom = {}, lastPersonal = {}}
    if type(state) ~= "table" then return out end
    local function Number(value, low, high)
        if type(value) == "number" and value == value and value >= low and value <= high then return value end
    end
    out.width = Number(state.width, STYLE.minWidth, STYLE.maxWidth)
    out.height = Number(state.height, STYLE.minHeight, STYLE.maxHeight)
    local left, top = Number(state.left, -10000, 10000), Number(state.top, -10000, 10000)
    if left and top then out.left, out.top = left, top end
    if type(state.bossEncID) == "number" and type(state.bossDifficulty) == "string" then
        local boss = bosses and bosses[state.bossEncID]
        if type(boss) == "table" and boss[state.bossDifficulty] then
            out.boss = {encID = state.bossEncID, difficulty = state.bossDifficulty}
        end
    end
    local personal = notes and notes.personal
    if type(state.lastPersonal) == "table" and type(personal) == "table" then
        for encID, name in pairs(state.lastPersonal) do
            if type(encID) == "number" and type(name) == "string" and personal[name] then out.lastPersonal[encID] = name end
        end
    end
    if type(state.showMine) == "boolean" then out.showMine = state.showMine end
    if type(state.compactRows) == "boolean" then out.compactRows = state.compactRows end
    if type(state.showBossIcons) == "boolean" then out.showBossIcons = state.showBossIcons end
    if state.bossMode == "off" then
        out.bossMode = false
    elseif type(state.bossMode) == "string" then
        for _, mode in pairs(self.BossDisplayModes or {}) do
            if mode == state.bossMode then out.bossMode = mode end
        end
    end
    if type(state.zoom) == "table" then
        for key, scale in pairs(state.zoom) do
            if type(key) == "string" and Number(scale, 0.01, 10) then out.zoom[key] = scale end
        end
    end
    return out
end

-- Fight time on the timeline from the addon's own phase stamps: the phase's start plus the time since it began.
-- Returns time and the phase start, or nil when the phase isn't on this boss's timeline.
function NSI:LiveTimelineTime(encID, phase, difficulty, sincePhase)
    if not encID or type(phase) ~= "number" or type(sincePhase) ~= "number" then return nil end
    if phase ~= 1 then
        local timeline = self:GetBossTimeline(encID, difficulty)
        if not (timeline and timeline.phases and timeline.phases[phase]) then return nil end
    end
    local start = self:GetPhaseStart(encID, phase, difficulty) or 0
    return start + math.max(0, sincePhase), start
end

-- Scroll value that brings canvas x back into view with room ahead of it, or nil when it is in view.
function NSI:NowLineScrollTarget(x, scroll, viewWidth, margin)
    if viewWidth <= 2 * margin then return nil end
    if x >= scroll + margin and x <= scroll + viewWidth - margin then return nil end
    return math.max(0, x - viewWidth * 0.25)
end

-- Boss ability colours for the legend: those on the given rows, or every known one when there are none.
-- Each is {name, color}, in category order.
function NSI:TimelineLegendCategories(lines)
    local seen, out = {}, {}
    local function Add(name, color)
        if name and not seen[name] then
            seen[name] = true
            out[#out + 1] = {name = name, color = color or STYLE.neutralCategory}
        end
    end
    for _, line in ipairs(lines or {}) do
        if line.isBossAbility then
            Add(line.primaryCategory, line.color)
            for _, block in ipairs(line.timeline or {}) do
                local payload = block.payload
                if payload then Add(payload.primaryCategory, payload.color) end
            end
        end
    end
    if #out == 0 then
        for name, color in pairs(self.BossTimelineColors or {}) do Add(name, color) end
    end
    local order = self.BossTimelineCategoryOrder or {}
    table.sort(out, function(a, b)
        local ao, bo = order[a.name] or 99, order[b.name] or 99
        if ao ~= bo then return ao < bo end
        return a.name < b.name
    end)
    return out
end

-- Phase active at absoluteTime and its absolute start. Ties go to the later phase (the
-- earlier one has zero length); the End-of-Fight sentinel phase is never returned.
function NSI:PhaseFromTime(encID, absoluteTime, difficulty)
    local bestPhase = 1
    local bestStart = 0
    local timeline = encID and self:GetBossTimeline(encID, difficulty)
    if timeline and timeline.phases then
        local endPhase = self:GetEndOfFightPhase(timeline)
        for _, ph in ipairs(self:SortedPhaseKeys(timeline.phases)) do
            if ph ~= endPhase then
                local phStart = self:GetPhaseStart(encID, ph, difficulty) or 0
                if phStart <= absoluteTime and phStart >= bestStart then
                    bestStart = phStart
                    bestPhase = ph
                end
            end
        end
    end
    return bestPhase, bestStart
end

-- At most one decimal and no trailing ".0", the way moved times are written.
function NSI:FormatNoteNumber(n)
    local s = string.format("%.1f", tonumber(n) or 0):gsub("%.0$", "")
    if s == "-0" then s = "0" end
    return s
end

-- "M:SS", with tenths when fractional; negative times get a leading "-".
function NSI:FormatTimelineClock(seconds)
    seconds = tonumber(seconds) or 0
    local tenths = math.floor(math.abs(seconds) * 10 + 0.5)
    local whole, frac = math.floor(tenths / 10), tenths % 10
    local text = string.format("%s%d:%02d", seconds < 0 and tenths > 0 and "-" or "", math.floor(whole / 60), whole % 60)
    if frac ~= 0 then text = text .. "." .. frac end
    return text
end

-- A phase key as written in notes: 1.75 stays "1.75", 2 is "2".
function NSI:FormatPhaseNumber(phase)
    local n = tonumber(phase)
    if not n then return tostring(phase) end
    return (string.format("%.6f", n):gsub("0+$", ""):gsub("%.$", ""))
end

-- "P2 +1:06 (7:14)": phase, time into the phase, time into the fight.
function NSI:FormatMoveLabel(phase, relTime, absTime)
    local rel, abs = self:FormatTimelineClock(relTime), self:FormatTimelineClock(absTime)
    if rel == abs then return string.format(T("P%s %s"), self:FormatPhaseNumber(phase), abs) end
    return string.format(T("P%s +%s (%s)"), self:FormatPhaseNumber(phase), rel, abs)
end

-- Phase a line moved to absTime lands in, that phase's start, and whether the line keeps its own ph.
-- A ph the boss data doesn't know is kept: the runtime still fires the line in that phase.
function NSI:MovedLinePhase(srcRaw, encID, difficulty, absTime)
    local own = self:NoteGetNumber(srcRaw, "ph")
    local timeline = encID and self:GetBossTimeline(encID, difficulty)
    if own and not (timeline and timeline.phases and timeline.phases[own]) then
        return own, encID and self:GetPhaseStart(encID, own, difficulty) or 0, true
    end
    local phase, phaseStart = self:PhaseFromTime(encID, absTime, difficulty)
    return phase, phaseStart, false
end

-- Rewrites time and ph of a reminder line moved to newAbsTime. Returns newRaw, phase, relTime.
-- A line without ph that lands in phase 1 keeps having no ph.
function NSI:ComputeMovedLine(srcRaw, encID, difficulty, newAbsTime)
    newAbsTime = math.max(0, tonumber(newAbsTime) or 0)
    local phase, phaseStart, kept = self:MovedLinePhase(srcRaw, encID, difficulty, newAbsTime)
    local relTime = tonumber(self:FormatNoteNumber(math.max(0, newAbsTime - phaseStart)))
    local newRaw = self:NoteSetField(srcRaw, "time", self:FormatNoteNumber(relTime))
    if not kept and (phase ~= 1 or self:NoteGetField(srcRaw, "ph")) then
        newRaw = self:NoteSetField(newRaw, "ph", self:FormatPhaseNumber(phase))
    end
    return newRaw, phase, relTime
end

local DUPLICATE_OFFSET = 5

-- A copy of a reminder line 5 s later in the same phase. A pre-pull line stays before the pull.
function NSI:DuplicateReminderLine(srcRaw)
    local time = self:NoteGetNumber(srcRaw, "time", true) or 0
    local shifted = time + DUPLICATE_OFFSET
    if time < 0 and shifted >= 0 then shifted = time - DUPLICATE_OFFSET end
    return self:NoteSetField(srcRaw, "time", self:FormatNoteNumber(shifted))
end

-- The boss cast on a row whose bar covers time t (the latest to start), or nil.
function NSI:BossCastAt(blocks, t)
    local best
    for _, block in ipairs(blocks or {}) do
        local start = tonumber(block[1])
        if start and start <= t and t <= start + (tonumber(block[4]) or 0)
            and (not best or start > best[1]) then
            best = block
        end
    end
    return best
end

local EDIT_FIELD_ORDER = {"tag", "time", "ph", "spellid", "text", "dur", "TTSTimer", "DisplayType", "colors", "glowunit"}

-- DisplayType values ProcessReminder (Reminders.lua) honours; anything else falls back to its default.
local REMINDER_DISPLAY_TYPES = {"Text", "Icon", "Bar", "Circle"}

-- The stored DisplayType when ProcessReminder honours it, else nil.
function NSI:ReminderDisplayType(value)
    for _, displayType in ipairs(REMINDER_DISPLAY_TYPES) do
        if value == displayType then return displayType end
    end
end

-- r, g, b (0 to 1) of a colors field value: 3 or 4 numbers split by spaces or colons. nil when it isn't one.
function NSI:ParseReminderColor(value)
    if type(value) ~= "string" then return nil end
    local numbers = {}
    for part in value:gmatch("[^%s:]+") do
        local n = tonumber(part)
        if not n or n < 0 or n > 1 then return nil end
        numbers[#numbers + 1] = n
    end
    if #numbers ~= 3 and #numbers ~= 4 then return nil end
    return numbers[1], numbers[2], numbers[3]
end

-- The colors field value for r, g, b: "r:g:b:1", each rounded to two decimals.
function NSI:FormatReminderColor(r, g, b)
    local parts = {}
    for i, n in ipairs({r, g, b}) do
        local s = string.format("%.2f", math.max(0, math.min(1, tonumber(n) or 0))):gsub("0+$", ""):gsub("%.$", "")
        parts[i] = s
    end
    parts[4] = "1"
    return table.concat(parts, ":")
end

-- Applies only the fields present in edits (false removes the field); everything else stays byte-for-byte.
function NSI:ApplyReminderEdits(srcRaw, edits)
    local line = srcRaw or ""
    for _, key in ipairs(EDIT_FIELD_ORDER) do
        local value = edits[key]
        if value == false then
            line = self:NoteRemoveField(line, key)
        elseif value ~= nil then
            line = self:NoteSetField(line, key, value)
        end
    end
    return line
end

-- Keys ProcessReminder (Reminders.lua) finds anywhere in a line, so a text or glow value must not contain them.
local RUNTIME_LINE_KEYS = {"assign", "EncounterID", "tag", "DisplayType", "time", "text", "spellid", "ph", "dur",
    "TTS", "TTSTimer", "countdown", "sound", "glowunit", "bossSpell", "colors", "invitelist"}

-- Error text for the reminder dialog, or nil. fields hold trimmed strings (text is untrimmed).
-- Numbers use ProcessReminder's patterns, so whatever passes here is read back the same way.
function NSI:ValidateReminderFields(fields, encID, difficulty)
    local phase = fields.ph:match("^%d*%.?%d+$") and tonumber(fields.ph)
    if not phase or phase <= 0 then
        return T("Phase must be a positive number.")
    end
    if phase ~= 1 then
        local timeline = encID and self:GetBossTimeline(encID, difficulty)
        if timeline and timeline.phases and next(timeline.phases) then
            if not timeline.phases[phase] or phase == self:GetEndOfFightPhase(timeline) then
                return string.format(T("This boss has no phase %s."), fields.ph)
            end
        end
    end
    if not fields.time:match("^%-?%d*%.?%d+$") then
        return T("Time must be a number of seconds.")
    end
    if fields.spellid ~= "" and not fields.spellid:match("^%d+$") then
        return T("Spell ID must be a number.")
    end
    if fields.dur ~= "" and not fields.dur:match("^%d*%.?%d+$") then
        return T("Duration must be a number of seconds.")
    end
    if fields.TTSTimer and fields.TTSTimer ~= "" and not fields.TTSTimer:match("^%d*%.?%d+$") then
        return T("TTS timer must be a number of seconds.")
    end
    if fields.spellid == "" and strtrim(fields.text) == "" then
        return T("Add a spell ID or some text.")
    end
    for _, field in ipairs({"text", "glowunit"}) do
        local value = fields[field] or ""
        for _, key in ipairs(RUNTIME_LINE_KEYS) do
            if value:find(key .. ":", 1, true) then
                return string.format(T("Text and Glow can't contain \"%s\". The reminder would read it as a setting."), key .. ":")
            end
        end
    end
    -- tag is only checked when the dialog changes it, so an untagged line can still be edited.
    if fields.tag ~= nil then
        if fields.tag == "" then
            return T("Choose who the reminder is for.")
        end
        if self:NoteSanitizeValue(fields.tag) ~= fields.tag then
            return T("For can't contain \";\" or line breaks.")
        end
        for _, key in ipairs(RUNTIME_LINE_KEYS) do
            if fields.tag:find(key .. ":", 1, true) then
                return string.format(T("For can't contain \"%s\". The reminder would read it as a setting."), key .. ":")
            end
        end
    end
end

-- The For field's choices, each a tag TagMatchesPlayer (Reminders.lua) understands.
-- classes: {{id, name, classFile}}; members: {{name, classFile}}.
function NSI:ReminderTagChoices(classes, members)
    local choices = {
        {kind = "everyone", tag = "everyone", label = T("Everyone")},
        {kind = "role", tag = "tank", label = T("Tanks")},
        {kind = "role", tag = "healer", label = T("Healers")},
        {kind = "role", tag = "damager", label = T("Damage dealers")},
        {kind = "position", tag = "melee", label = T("Melee")},
        {kind = "position", tag = "ranged", label = T("Ranged")},
    }
    for _, class in ipairs(classes or {}) do
        choices[#choices + 1] = {kind = "class", tag = tostring(class.id), label = class.name, classFile = class.classFile}
    end
    for group = 1, 8 do
        choices[#choices + 1] = {kind = "group", tag = "group" .. group, label = string.format(T("Group %d"), group)}
    end
    for _, member in ipairs(members or {}) do
        choices[#choices + 1] = {kind = "player", tag = member.name, label = member.name, classFile = member.classFile}
    end
    return choices
end

-- The choice a tag selects, or nil when only Custom fits. Case-insensitive, as at runtime.
function NSI:FindReminderTagChoice(choices, tag)
    local key = strlower(strtrim(tag or ""))
    if key == "" then return nil end
    for _, choice in ipairs(choices) do
        if strlower(choice.tag) == key then return choice end
    end
end

-- Mirrors TagMatchesPlayer (Reminders.lua) against an explicit player context.
function NSI:TagMatchesContext(tagText, ctx, requireTag)
    if not tagText or tagText == "" then return not requireTag end
    tagText = strlower(tagText)
    local tags = {}
    for token in tagText:gmatch("%S+") do
        tags[token] = true
    end
    return not not ((tagText == "everyone" and not ctx.ignoreEveryone)
        or tags[ctx.name] or tags[ctx.nickname] or tags[ctx.role] or tags[ctx.spec]
        or tags[ctx.class] or tags[ctx.group] or (ctx.position and tags[ctx.position]))
end

-- Whether one tag lane survives "Mine". "everyone" only counts when it is the whole tag, as at runtime.
function NSI:TagTokenMatchesContext(token, tagText, ctx)
    if strlower(token) == "everyone" then
        return strlower(tagText or "") == "everyone" and not ctx.ignoreEveryone
    end
    return self:TagMatchesContext(token, ctx, true)
end

-- The values TagMatchesPlayer compares tags against, for the current character.
function NSI:GetPlayerTagContext()
    local specID = self:GetMySpecID()
    local role = strlower(UnitGroupRolesAssigned("player") or "none")
    local classID = select(3, UnitClass("player"))
    return {
        name = strlower(UnitName("player") or ""),
        nickname = strlower(NSAPI:GetName("player", "GlobalNickNames") or ""),
        role = role,
        spec = specID and tostring(specID),
        class = classID and tostring(classID),
        group = "group" .. (self:GetSubGroup("player") or 1),
        position = ((specID and self.meleetable and self.meleetable[specID]) or role == "tank") and "melee" or "ranged",
        ignoreEveryone = NSRT.ReminderSettings.IgnoreEveryone and true or false,
    }
end

--------------------------------------------------------------------------------
-- NOTE WRITE-BACK + UNDO
--------------------------------------------------------------------------------

local TIMELINE_UNDO_LIMIT = 30
NSI.TimelineUndoStack = NSI.TimelineUndoStack or {}

-- Timeline writes only ever target personal notes; shared notes are edited in the options.
local function WritableNoteText(name, personal)
    return personal and name and NSRT.PersonalReminders[name] or nil
end

-- Saves a whole personal note the same way every timeline edit does, recording the old text for undo.
local function WriteNoteText(name, oldText, newText)
    local stack = NSI.TimelineUndoStack
    stack[#stack + 1] = {name = name, personal = true, text = oldText, after = newText}
    while #stack > TIMELINE_UNDO_LIMIT do
        table.remove(stack, 1)
    end
    NSI:ImportReminder(name, newText, false, true, true)
end

-- Index of srcRaw: srcLineIndex if that line still holds it, else its first occurrence. With encID only lines
-- in that boss's sections count, where lines above the first header belong to the first section (as in CollectNoteLanes).
local function LocateNoteLine(lines, srcLineIndex, srcRaw, encID)
    if not srcRaw then return nil end
    local sections = {}
    if encID then
        local current
        for i, line in ipairs(lines) do
            local id = line:find("EncounterID:", 1, true) and line:match("EncounterID:(%d+)")
            if id then
                if not current then
                    for j = 1, i - 1 do sections[j] = tonumber(id) end
                end
                current = tonumber(id)
            end
            sections[i] = current
        end
    end
    local function Holds(i)
        return lines[i] == srcRaw and (not encID or sections[i] == encID)
    end
    if srcLineIndex and Holds(srcLineIndex) then return srcLineIndex end
    for i = 1, #lines do
        if Holds(i) then return i end
    end
end

local function StripLineBreaks(s)
    return (tostring(s or ""):gsub("[\r\n]", ""))
end

-- Replaces one line of a personal note. Returns false when the note or the line is gone, or the note is shared.
-- encID: the boss the line was shown for (see LocateNoteLine).
function NSI:RewriteNoteLine(name, personal, srcLineIndex, srcRaw, newRaw, encID)
    local str = WritableNoteText(name, personal)
    if not str then return false end
    local lines, seps = self:NoteSplitLines(str)
    local index = LocateNoteLine(lines, srcLineIndex, srcRaw, encID)
    if not index or newRaw == nil then return false end
    newRaw = StripLineBreaks(newRaw)
    if lines[index] == newRaw then return true end
    lines[index] = newRaw
    WriteNoteText(name, str, self:NoteJoinLines(lines, seps))
    return true
end

-- Removes one line of a personal note. Returns false when the note or the line is gone.
function NSI:DeleteNoteLine(name, personal, srcLineIndex, srcRaw, encID)
    local str = WritableNoteText(name, personal)
    if not str then return false end
    local lines, seps = self:NoteSplitLines(str)
    local index = LocateNoteLine(lines, srcLineIndex, srcRaw, encID)
    if not index then return false end
    -- Keep an unterminated note unterminated when its last line goes.
    if index == #lines and seps[index] == "" and index > 1 then
        seps[index - 1] = ""
    end
    table.remove(lines, index)
    table.remove(seps, index)
    WriteNoteText(name, str, self:NoteJoinLines(lines, seps))
    return true
end

-- Appends a line to a personal note, using the note's own line ending. Returns false when the note is gone.
function NSI:AppendNoteLine(name, personal, newLine)
    local str = WritableNoteText(name, personal)
    if not str then return false end
    local lines, seps = self:NoteSplitLines(str)
    local eol = str:find("\r\n", 1, true) and "\r\n" or "\n"
    local n = #lines
    if n > 0 and seps[n] == "" then seps[n] = eol end
    lines[n + 1] = StripLineBreaks(newLine)
    seps[n + 1] = eol
    WriteNoteText(name, str, self:NoteJoinLines(lines, seps))
    return true
end

-- Inserts a line into a personal note after srcRaw (located like RewriteNoteLine), or after line srcLineIndex
-- when srcRaw is nil (0 inserts at the top). Returns false when the note or the line is gone.
function NSI:InsertNoteLine(name, personal, srcLineIndex, srcRaw, newLine, encID)
    local str = WritableNoteText(name, personal)
    if not str then return false end
    local lines, seps = self:NoteSplitLines(str)
    local index = srcLineIndex
    if srcRaw then index = LocateNoteLine(lines, srcLineIndex, srcRaw, encID) end
    if not index or index < 0 or index > #lines then return false end
    local eol = str:find("\r\n", 1, true) and "\r\n" or "\n"
    if index > 0 and seps[index] == "" then seps[index] = eol end
    table.insert(lines, index + 1, StripLineBreaks(newLine))
    table.insert(seps, index + 1, eol)
    WriteNoteText(name, str, self:NoteJoinLines(lines, seps))
    return true
end

-- Last non-blank line of a boss section (the first one, or the first for encID), or nil when no other
-- boss section follows it.
function NSI:FirstBossSectionEnd(str, encID)
    local lines = self:NoteSplitLines(str)
    local first, nextHeader
    for i, line in ipairs(lines) do
        local enc = line:find("EncounterID:", 1, true) and line:match("EncounterID:(%d+)")
        if enc then
            if first then
                nextHeader = i
                break
            end
            if not encID or tonumber(enc) == encID then first = i end
        end
    end
    if not nextHeader then return nil end
    local last = nextHeader - 1
    while last > first and not lines[last]:find("%S") do
        last = last - 1
    end
    return last
end

-- Adds a reminder line at the end of a personal note's section for encID (its first section when nil).
function NSI:AddTimelineNoteLine(name, personal, newLine, encID)
    local str = WritableNoteText(name, personal)
    if not str then return false end
    local last = self:FirstBossSectionEnd(str, encID)
    if last then return self:InsertNoteLine(name, personal, last, nil, newLine) end
    return self:AppendNoteLine(name, personal, newLine)
end

-- Newest undo entry whose note still exists, left on the stack; entries of deleted notes are dropped.
function NSI:TimelineUndoPeek()
    local stack = self.TimelineUndoStack
    while #stack > 0 do
        local entry = stack[#stack]
        if entry.personal and NSRT.PersonalReminders[entry.name] then return entry end
        table.remove(stack)
    end
    return nil
end

-- Restores the newest undo entry. Returns {name, personal, previousText}, or {name, personal, stale = true}
-- when the note was changed outside the timeline (its history is then dropped), or nil.
-- The caller reloads the note (SetReminder) if it is the loaded one.
function NSI:TimelineUndo()
    local entry = self:TimelineUndoPeek()
    if not entry then return nil end
    local previousText = NSRT.PersonalReminders[entry.name]
    if previousText ~= entry.after then
        self:TimelineUndoForget(entry.name, true)
        return {name = entry.name, personal = true, stale = true}
    end
    table.remove(self.TimelineUndoStack)
    self:ImportReminder(entry.name, entry.text, false, true, true)
    return {name = entry.name, personal = true, previousText = previousText}
end

-- Drops undo entries for a note that was renamed or deleted.
function NSI:TimelineUndoForget(name, personal)
    local stack = self.TimelineUndoStack
    personal = personal and true or false
    for i = #stack, 1, -1 do
        if stack[i].name == name and stack[i].personal == personal then
            table.remove(stack, i)
        end
    end
end

-- The Reminders options screen that edits notes of this kind, once it has been built.
local function NoteEditorScreen(personal)
    local nsui = NSI.NSUI
    return nsui and (personal and nsui.personal_reminders_frame or nsui.reminders_frame) or nil
end

-- Line endings and trailing blanks don't count as edits.
local function EditorTextKey(text)
    return (tostring(text or ""):gsub("\r", ""):gsub("%s+$", ""))
end

-- Whether the options screen holds edits to note that a timeline write would discard.
function NSI:NoteHasUnsavedEditorText(note)
    local screen = NoteEditorScreen(note.personal)
    if not screen or not screen.editor or screen.selectedName ~= note.name then return false end
    local saved = (note.personal and NSRT.PersonalReminders or NSRT.Reminders)[note.name]
    return EditorTextKey(screen.editor:GetText()) ~= EditorTextKey(saved)
end

-- Error text when a timeline write to note must not happen, else nil. reloads: it would reprocess the loaded note.
function NSI:TimelineWriteBlocked(note, reloads)
    if reloads and self:RemindersOwnedByPull() then
        return T("Can't change the loaded note during an encounter.")
    end
    if self:NoteHasUnsavedEditorText(note) then
        return T("This note has unsaved changes in the note editor. Save or discard them there first.")
    end
end

-- Brings the options screen in line after the timeline changed note: selectName is what the screen should
-- now show if it showed note (its new name, or nil once deleted).
function NSI:SyncNoteEditor(note, selectName, listChanged)
    local sidebar = listChanged and self.NSUI and self.NSUI.Sidebar
    if sidebar and sidebar.UpdateIcons then sidebar:UpdateIcons() end
    local screen = NoteEditorScreen(note.personal)
    if not screen then return end
    if screen.selectedName == note.name and screen.SelectReminder then
        local source = note.personal and NSRT.PersonalReminders or NSRT.Reminders
        screen.SelectReminder(selectName and source[selectName] and selectName or nil)
    end
    if listChanged and screen.scrollbox then screen.scrollbox:MasterRefresh() end
end

--------------------------------------------------------------------------------
-- TAG LANES
--------------------------------------------------------------------------------

local TAG_KIND_ORDER = {everyone = 1, role = 2, position = 3, group = 4, class = 5, spec = 6, player = 7}
local ROLE_ORDER = {tank = 1, healer = 2, damager = 3}
local POSITION_ORDER = {melee = 1, ranged = 2}
-- Lowest specialization ID (Arcane Mage); class IDs sit below it.
local MIN_SPEC_ID = 62
-- Class and spec lookups take a 32-bit int and error past it; longer digit tags can only be names.
local MAX_TAG_ID = 2 ^ 31 - 1

-- Classifies a tag token the way TagMatchesPlayer (Reminders.lua) matches it.
-- Returns kind, laneKey (lowercased token), sortValue.
function NSI:ClassifyNoteTag(token)
    local lower = strlower(token)
    if lower == "everyone" then return "everyone", lower, 0 end
    if ROLE_ORDER[lower] then return "role", lower, ROLE_ORDER[lower] end
    if POSITION_ORDER[lower] then return "position", lower, POSITION_ORDER[lower] end
    local groupNum = lower:match("^group(%d+)$")
    if groupNum then return "group", lower, tonumber(groupNum) end
    local id = lower:match("^%d+$") and tonumber(lower)
    if id and id <= MAX_TAG_ID then
        if id < MIN_SPEC_ID then return "class", lower, id end
        return "spec", lower, id
    end
    return "player", lower, lower
end

-- Display label and class file (for colouring) of a non-player lane.
local function TagLaneLabel(kind, token, sortValue)
    if kind == "everyone" then
        return T("Everyone")
    elseif kind == "role" then
        return (sortValue == 1 and T("Tanks")) or (sortValue == 2 and T("Healers")) or T("DPS")
    elseif kind == "position" then
        return sortValue == 1 and T("Melee") or T("Ranged")
    elseif kind == "group" then
        return string.format(T("Group %d"), sortValue)
    elseif kind == "class" then
        local info = C_CreatureInfo.GetClassInfo(sortValue)
        return info and info.className or token, info and info.classFile
    elseif kind == "spec" then
        local _, specName, _, _, _, classFile = GetSpecializationInfoByID(sortValue)
        return specName or token, classFile
    end
    return token
end

local function ClassFileColorHex(classFile)
    local color = classFile and GetClassColorObj(classFile)
    return color and color:GenerateHexColor() or nil
end

-- ownName: the own character's lower-case name (GetPlayerTagContext), so its lane is coloured outside a group too.
local function PlayerLaneLabel(player, ownName)
    local shortPlayer = NSAPI:Shorten(player, 12, false, "GlobalNickNames") or player
    local classColorHex = nil
    local unitName = NSAPI:GetChar(player, true, "NorthernSkyRaidTools")
    -- Outside a group only the own character resolves; nothing else maps a name to a class without a unit.
    local bareName = strlower((unitName or player):match("^[^%-]+") or "")
    if ownName and bareName ~= "" and bareName == ownName then unitName = "player" end
    if unitName and UnitExists(unitName) then
        local _, classFile = UnitClass(unitName)
        classColorHex = ClassFileColorHex(classFile)
    end
    return shortPlayer, classColorHex
end

-- Adds one note text's reminders for encID to lanes: its section for that boss, plus the lines above its
-- first header when that header is encID (flagged, since they never fire). source: {note, layer, readOnly}
-- copied onto every block. Returns the latest absolute time and how many reminders other sections hold.
local function CollectNoteLanes(self, lanes, reminderStr, encID, srcDifficulty, mineContext, source, ownContext)
    local maxTime = 0
    local phaseStarts = {}
    local spellDuration = NSRT.ReminderSettings.SpellDuration
    local textDuration = NSRT.ReminderSettings.TextDuration
    local firstHeader = tonumber(reminderStr:match("EncounterID:(%d+)") or "")

    local noteLines = self:NoteSplitLines(reminderStr)
    local sectionEncID
    local omittedLines = 0
    for srcLineIndex, line in ipairs(noteLines) do
        -- ProcessReminder skips header and assign lines and files each later section under its own boss.
        local headerID = line:find("EncounterID:", 1, true) and line:match("EncounterID:(%d+)")
        if headerID then sectionEncID = tonumber(headerID) end
        local runs = not headerID and not line:match("assign:[^;]")
        local tag = runs and self:NoteGetField(line, "tag")
        local time = runs and self:NoteGetNumber(line, "time", true)

        if tag and time and sectionEncID and sectionEncID ~= encID then
            omittedLines = omittedLines + 1
        elseif tag and time and not sectionEncID and firstHeader ~= encID then
            omittedLines = omittedLines + 1
        elseif tag and time then
            local spellValue = self:NoteGetField(line, "spellid")
            local spellID = spellValue and tonumber(spellValue:match("^%d+"))
            local text = self:NoteGetField(line, "text")
            if text == "" then text = nil end
            local invalid = encID and not sectionEncID and T("It is above the note's header line, so it never fires.")
                or not text and not spellID and T("It has no text or spell ID, so it never fires.") or nil
            local glowUnit = self:NoteGetField(line, "glowunit")
            local prePull = time < 0
            -- ProcessReminder forces pre-pull lines into phase 1.
            local phase = prePull and 1 or (self:NoteGetNumber(line, "ph") or 1)
            local dur = self:NoteGetNumber(line, "dur") or (spellID and spellDuration or textDuration)

            local glowUnitNames = nil
            if glowUnit then
                glowUnitNames = ""
                for name in glowUnit:gmatch("([^%s:]+)") do
                    if name ~= "glowunit" then
                        glowUnitNames = glowUnitNames .. NSAPI:Shorten(NSAPI:GetChar(name), 12, false, "GlobalNickNames") .. " "
                    end
                end
            end

            if not phaseStarts[phase] then
                phaseStarts[phase] = encID and self:GetPhaseStart(encID, phase, srcDifficulty) or 0
            end
            local absoluteTime = prePull and 0 or (phaseStarts[phase] + time)
            if absoluteTime > maxTime then
                maxTime = absoluteTime
            end

            -- For spells: one lane per spellID; text-only reminders share one lane per tag
            local abilityKey = spellID and tostring(spellID) or "text"
            local seen = {}
            for _, token in ipairs(self:NoteTagTokens(tag)) do
                local kind, laneKey, sortValue = self:ClassifyNoteTag(token)
                if not seen[laneKey] and (not mineContext or self:TagTokenMatchesContext(token, tag, mineContext)) then
                    seen[laneKey] = true
                    local lane = lanes[laneKey]
                    if not lane then
                        lane = {kind = kind, key = laneKey, token = token, sortValue = sortValue, abilities = {}}
                        lanes[laneKey] = lane
                    end
                    if ownContext and not lane.mine and self:TagTokenMatchesContext(token, tag, ownContext) then
                        lane.mine = true
                    end
                    lane.abilities[abilityKey] = lane.abilities[abilityKey] or {spellID = spellID, entries = {}}
                    table.insert(lane.abilities[abilityKey].entries, {
                        absoluteTime = absoluteTime,
                        time = time,
                        dur = dur,
                        phase = phase,
                        text = text,
                        glowUnit = glowUnitNames,
                        srcLineIndex = srcLineIndex,
                        srcRaw = line,
                        prePull = prePull or nil,
                        invalid = invalid,
                        source = source,
                    })
                end
            end
        end
    end
    return maxTime, omittedLines
end

-- Field values the edit dialog shows for a reminder it can't edit.
local function ReadOnlyFields(self, raw, phase, time, text)
    local tagValue = self:NoteGetField(raw, "tag")
    return {
        ph = self:FormatPhaseNumber(phase), time = self:FormatNoteNumber(time),
        spellid = self:NoteGetField(raw, "spellid") or "", text = text or "",
        dur = self:NoteGetField(raw, "dur") or "", glowunit = self:NoteGetField(raw, "glowunit") or "",
        tag = tagValue,
        TTSTimer = self:NoteGetField(raw, "TTSTimer"), DisplayType = self:NoteGetField(raw, "DisplayType"),
        colors = self:NoteGetField(raw, "colors"),
    }
end

-- Seconds one reminder icon covers at the timeline's zoom: the DF timeline sizes it to the row height, plus a 1 px gap.
local function CompactIconSeconds(timeline)
    local options = timeline.options
    return ((options.line_height or STYLE.rowHeight) + 1) / ((options.pixels_per_second or 15) * (timeline.currentScale or 1))
end

-- Compact rows: one per lane, plus a row below it for each reminder that would overlap the ones before it.
-- compactLanes come from LanesToLines; width from CompactIconSeconds. Returns lines and a packing signature.
local function CompactLaneLines(self, compactLanes, width)
    local lines, signature, mineEnd = {}, {}, nil
    for band, lane in ipairs(compactLanes) do
        local times = {}
        for i, block in ipairs(lane.blocks) do times[i] = block[1] end
        local rows, count = self:PackTimelineRows(times, width)
        local first, info = #lines + 1, lane.info
        for r = 1, math.max(count, 1) do
            lines[#lines + 1] = {
                text = "", timeline = {}, isPlayerAssignment = true, isCompact = true, laneRow = r, laneBand = band,
                laneCount = #lane.blocks, isGroupTag = info.isGroupTag, laneKind = info.laneKind, laneKey = info.laneKey,
                playerName = info.playerName, playerClassColor = info.playerClassColor,
            }
        end
        for i, block in ipairs(lane.blocks) do
            local row = lines[first + rows[i] - 1].timeline
            row[#row + 1] = block
        end
        signature[#signature + 1] = table.concat(rows, ",")
        if lane.mine then mineEnd = #lines end
    end
    if mineEnd and mineEnd < #lines then lines[mineEnd].dividerBelow = true end
    return lines, table.concat(signature, ";")
end

-- Timeline rows for collected lanes, one per lane and spell, in lane order. With compactWidth (CompactIconSeconds)
-- the rows are compact (CompactLaneLines) and the second return is {lanes, signature, width} to re-pack them.
local function LanesToLines(self, lanes, srcDifficulty, compactWidth, ownName)
    local sortedLanes = {}
    for _, lane in pairs(lanes) do
        table.insert(sortedLanes, lane)
    end
    table.sort(sortedLanes, function(a, b)
        if (a.mine or false) ~= (b.mine or false) then return a.mine or false end
        local aOrder, bOrder = TAG_KIND_ORDER[a.kind], TAG_KIND_ORDER[b.kind]
        if aOrder ~= bOrder then return aOrder < bOrder end
        if a.sortValue ~= b.sortValue then return a.sortValue < b.sortValue end
        return a.key < b.key
    end)

    local lines, mineEnd = {}, nil
    local compactLanes = compactWidth and {} or nil
    for _, lane in ipairs(sortedLanes) do
        local laneBlocks = {}
        local isGroupTag = lane.kind ~= "player"
        local laneLabel, laneColor
        if isGroupTag then
            local label, classFile = TagLaneLabel(lane.kind, lane.token, lane.sortValue)
            laneLabel, laneColor = label, ClassFileColorHex(classFile)
        else
            laneLabel, laneColor = PlayerLaneLabel(lane.token, ownName)
        end

        -- Sort abilities by spellID (numeric) or text (alphabetic)
        local sortedAbilities = {}
        for abilityKey, data in pairs(lane.abilities) do
            table.insert(sortedAbilities, {key = abilityKey, data = data})
        end
        table.sort(sortedAbilities, function(a, b)
            -- Numeric keys (spellIDs) come before text keys
            local aNum = tonumber(a.key)
            local bNum = tonumber(b.key)
            if aNum and bNum then
                return aNum < bNum
            elseif aNum then
                return true
            elseif bNum then
                return false
            else
                return a.key < b.key
            end
        end)

        for _, ability in ipairs(sortedAbilities) do
            local abilityData = ability.data
            local spellID = abilityData.spellID
            local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)
            -- The DF timeline indexes GetSpellInfo(blockSpellId) unguarded, so unresolved IDs stay nil.
            local displaySpellID = spellInfo and spellID or nil
            local timeline = {}

            -- Later blocks stack on top (StyleBlock), so personal reminders sort after equal-timed shared ones.
            table.sort(abilityData.entries, function(a, b)
                if a.phase ~= b.phase then return a.phase < b.phase end
                if a.time ~= b.time then return a.time < b.time end
                local aPersonal, bPersonal = a.source.layer == "personal", b.source.layer == "personal"
                if aPersonal ~= bPersonal then return bPersonal end
                return a.srcLineIndex < b.srcLineIndex
            end)

            local lineIcon = spellInfo and spellInfo.iconID
            local lineName = ""
            if spellID then
                if spellInfo then
                    lineName = spellInfo.name or ""
                end
            else
                -- Text-only reminders: label the lane as "Notes"
                lineName = T("Notes")
                lineIcon = "Interface\\ICONS\\INV_Misc_Note_01"
            end
            lineIcon = lineIcon or "Interface\\ICONS\\INV_Misc_QuestionMark"

            for _, entry in ipairs(abilityData.entries) do
                local source = entry.source
                -- Format: {time, length, isAura, auraDuration, blockSpellId}
                local block = {
                    entry.absoluteTime, -- [1] time in seconds (absolute; pre-pull lines sit at 0)
                    0,                  -- [2] length (0 for icon-based display)
                    true,               -- [3] isAura (shows duration bar)
                    entry.dur,          -- [4] auraDuration
                    displaySpellID,     -- [5] blockSpellId
                    payload = {
                        phase = entry.phase, text = entry.text, glowUnit = entry.glowUnit,
                        srcLineIndex = entry.srcLineIndex, srcRaw = entry.srcRaw,
                        srcNote = source.note, srcDifficulty = srcDifficulty, layer = source.layer,
                        relTime = entry.time, prePull = entry.prePull, invalid = entry.invalid,
                        readOnly = source.readOnly and ReadOnlyFields(self, entry.srcRaw, entry.phase, entry.time, entry.text) or nil,
                    },
                }
                if compactLanes then
                    -- A compact row mixes spells, so the DF timeline takes each block's icon from customIcon.
                    block.customIcon = lineIcon
                    laneBlocks[#laneBlocks + 1] = block
                else
                    table.insert(timeline, block)
                end
            end

            if not compactLanes then
                table.insert(lines, {
                    spellId = displaySpellID,
                    icon = lineIcon,
                    text = lineName, -- Spell name left-anchored
                    timeline = timeline,
                    isPlayerAssignment = true,
                    isGroupTag = isGroupTag or nil,
                    laneKind = lane.kind,
                    laneKey = lane.key,
                    playerName = laneLabel,
                    playerClassColor = laneColor,
                    playerSpellIcon = lineIcon,
                })
            end
        end
        if compactLanes then
            table.sort(laneBlocks, function(a, b)
                if a[1] ~= b[1] then return a[1] < b[1] end
                local aPersonal, bPersonal = a.payload.layer == "personal", b.payload.layer == "personal"
                if aPersonal ~= bPersonal then return bPersonal end
                return a.payload.srcLineIndex < b.payload.srcLineIndex
            end)
            compactLanes[#compactLanes + 1] = {
                blocks = laneBlocks, mine = lane.mine,
                info = {isGroupTag = isGroupTag or nil, laneKind = lane.kind, laneKey = lane.key,
                    playerName = laneLabel, playerClassColor = laneColor},
            }
        elseif lane.mine then
            mineEnd = #lines
        end
    end
    if compactLanes then
        local compactLines, signature = CompactLaneLines(self, compactLanes, compactWidth)
        return compactLines, {lanes = compactLanes, signature = signature, width = compactWidth}
    end
    if mineEnd and mineEnd < #lines then lines[mineEnd].dividerBelow = true end
    return lines
end

-- Timeline data from reminder rows: boss rows on top when asked for, then the reminder rows.
-- options.filterRow: the window's filter row (TimelineFilterLine) always sits between the two, in place of the
-- "Players" section. options.filterRow also leaves out the "Boss abilities" section row: data.bossHeading
-- (true) asks the window to show that heading instead. options.compact: LanesToLines' second return.
-- Returns data, phases, bossDifficulty.
local function AssembleTimelineData(self, lines, maxTime, encID, difficulty, includeBossAbilities, bossDisplayMode, options)
    local phases, bossDifficulty, bossFilter, bossHeading = nil, nil, nil, false
    local finalLines = {}
    local filterRow = options and options.filterRow
    if includeBossAbilities and encID then
        local bossLines, bossMaxTime, bossPhases, resolved, filter = self:GetBossAbilityLines(encID, bossDisplayMode, difficulty)
        phases, bossDifficulty, bossFilter = bossPhases, resolved, filter

        local bossSection = #bossLines > 0 or (filter and filter.hiddenCount > 0)
        if bossSection and filterRow then
            bossHeading = true
        elseif bossSection then
            table.insert(finalLines, self:BossAbilitySectionLine())
        end
        for _, line in ipairs(bossLines) do
            table.insert(finalLines, line)
        end
        if #lines > 0 and bossSection and not filterRow then
            table.insert(finalLines, self:TimelineSectionLine(T("Players")))
        end
        if bossMaxTime > maxTime then
            maxTime = bossMaxTime
        end
    end
    if filterRow then
        table.insert(finalLines, self:TimelineFilterLine())
    end

    self:MarkTimelineLaneGroups(lines)
    for _, line in ipairs(lines) do
        table.insert(finalLines, line)
    end

    return {
        length = TimelineLength(maxTime),
        defaultColor = {1, 1, 1, 1},
        useIconOnBlocks = true,
        lines = finalLines,
        reminderLines = #lines,
        bossFilter = bossFilter,
        bossHeading = bossHeading,
        compact = options and options.compact,
    }, phases, bossDifficulty
end

-- Get timeline data from one stored note, for the boss of its first section.
-- Returns data in DetailsFramework timeline format, encID, phases, bossDifficulty, noteDifficulty.
-- One lane per tag token and spell; a line tagged "A B healer" draws a block in each lane,
-- all pointing at the same source line. mineContext (GetPlayerTagContext) keeps only lanes matching it.
-- bossDisplayMode: "all", "important", or "combined" (see BossDisplayModes)
function NSI:GetAllTimelineData(reminderName, personal, includeBossAbilities, bossDisplayMode, mineContext)
    local store = personal and NSRT.PersonalReminders or NSRT.Reminders
    local reminderStr = store[reminderName]
    if not reminderStr then return nil end

    local encID = tonumber(reminderStr:match("EncounterID:(%d+)") or "")

    -- Difficulty from the note header, resolved once so absolute times, boss rows and srcDifficulty agree.
    local reminderDifficulty = NoteHeaderValue(reminderStr, "Difficulty")
    local srcDifficulty = reminderDifficulty
    if encID and self.BossTimelines and self.BossTimelines[encID] then
        local _, resolved = self:GetBossTimeline(encID, reminderDifficulty)
        srcDifficulty = resolved or reminderDifficulty
    end
    local source = {note = {name = reminderName, personal = personal and true or false}}

    local lanes = {}
    local maxTime, omittedLines = CollectNoteLanes(self, lanes, reminderStr, encID, srcDifficulty, mineContext, source)
    local lines = LanesToLines(self, lanes, srcDifficulty)
    local data, phases, difficulty = AssembleTimelineData(self, lines, maxTime, encID, srcDifficulty, includeBossAbilities, bossDisplayMode)
    data.omittedLines = omittedLines
    return data, encID, phases, difficulty, srcDifficulty
end

-- Timeline data for one boss from note texts layered on top of each other. layers: list of
-- {text, layer = "shared" | "view" | "personal", note = {name, personal} for the editable layer}.
-- Shared and view layers are read-only. Lanes matching ownContext list first. Returns data, phases, bossDifficulty.
-- options: {filterRow, compactWidth} for the window (see AssembleTimelineData and LanesToLines).
function NSI:GetLayeredTimelineData(encID, difficulty, layers, includeBossAbilities, bossDisplayMode, mineContext, ownContext, options)
    local lanes = {}
    local maxTime = 0
    for _, layer in ipairs(layers) do
        if layer.text then
            local source = {layer = layer.layer, note = layer.note, readOnly = layer.layer ~= "personal" or nil}
            local layerMax = CollectNoteLanes(self, lanes, layer.text, encID, difficulty, mineContext, source, ownContext)
            if layerMax > maxTime then maxTime = layerMax end
        end
    end
    local lines, compact = LanesToLines(self, lanes, difficulty, options and options.compactWidth,
        ownContext and ownContext.name ~= "" and ownContext.name or nil)
    local assembly = {filterRow = options and options.filterRow, compact = compact}
    if includeBossAbilities then
        return AssembleTimelineData(self, lines, maxTime, encID, difficulty, true, bossDisplayMode, assembly)
    end
    local timeline, resolved = self:GetBossTimeline(encID, difficulty)
    maxTime = math.max(maxTime, timeline and timeline.duration or 0)
    local data = AssembleTimelineData(self, lines, maxTime, encID, difficulty, false, nil, assembly)
    return data, timeline and timeline.phases, resolved
end

-- Canvas size for a window size: header column on the left, scroll bar on the right.
local function TimelineCanvasSize(width, height)
    return width - 2 * STYLE.windowPad - STYLE.headerWidth - STYLE.scrollBarGap - STYLE.scrollBarSize,
        height - STYLE.canvasTop - STYLE.canvasBottom
end

-- A small labelled box on the ruler (cursor time, drag target, preview time).
local function CreateRulerChip(parent, bgColor, textColor, height, textSize)
    local chip = CreateFrame("Frame", nil, parent)
    chip:SetHeight(height)
    chip:SetFrameLevel(parent:GetFrameLevel() + 6)
    chip:EnableMouse(false)
    -- Dark fill, light text: the UI font's outline turns dark text on a light chip into a blob.
    chip.border = chip:CreateTexture(nil, "BACKGROUND", nil, -1)
    chip.border:SetAllPoints()
    Paint(chip.border, textColor)
    chip.bg = chip:CreateTexture(nil, "BACKGROUND")
    chip.bg:SetPoint("TOPLEFT", 1, -1)
    chip.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    Paint(chip.bg, bgColor)
    chip.text = NewFontString(chip, textSize, textColor)
    chip.text:SetPoint("CENTER", chip, "CENTER", 0, 0)
    chip:Hide()
    return chip
end

local function CreateCanvasLine(body, levelOffset, color, width)
    local frame = CreateFrame("Frame", nil, body)
    frame:SetWidth(width)
    frame:SetFrameLevel(body:GetFrameLevel() + levelOffset)
    frame:EnableMouse(false)
    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    NSI.UI.PP.NoSnap(texture)
    Paint(texture, color)
    frame:Hide()
    return frame
end

local function PlaceCanvasLine(frame, body, x)
    local top = -(STYLE.rulerHeight + STYLE.phaseLaneHeight)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", body, "TOPLEFT", x, top)
    frame:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", x, 0)
end

-- Clamped so the whole chip stays inside the clipped ruler container.
local function PlaceRulerChip(chip, strip, x)
    local container = strip:GetParent()
    local stripLeft, containerLeft = strip:GetLeft(), container and container:GetLeft()
    if stripLeft and containerLeft then
        local offset = stripLeft - containerLeft
        local half, viewWidth = chip:GetWidth() / 2, container:GetWidth()
        if viewWidth > half * 2 then
            x = math.max(half, math.min(viewWidth - half, x + offset)) - offset
        end
    end
    chip:ClearAllPoints()
    chip:SetPoint("CENTER", strip, "TOPLEFT", x, -STYLE.rulerHeight / 2)
end

-- Stripe, hover and section looks of a row and its header.
local function PaintRow(line, hovered)
    local data = line.lineData
    local bg = line.lineHeader and line.lineHeader.nsBg
    -- All rows of a compact lane share one stripe, so the lane reads as one band.
    local index = data and data.laneBand or line.dataIndex or 0
    local c
    if data and data.isFilterRow then
        c = STYLE.filterRowBg
    elseif data and data.isSection then
        c = nil
    elseif hovered then
        c = STYLE.hover
    elseif index % 2 == 0 then
        c = STYLE.stripe
    end
    if c then
        line:SetBackdropColor(c[1], c[2], c[3], c[4])
        if bg then Paint(bg, c) end
    else
        line:SetBackdropColor(0, 0, 0, 0)
        if bg then bg:SetColorTexture(0, 0, 0, 0) end
    end
end

local function LaneTooltip(header, line)
    local data = line.lineData
    if not data or data.isSection then return end
    local count = data.timeline and #data.timeline or 0
    if data.isCompact then
        local r, g, b = HexToColor(data.playerClassColor)
        if r then r, g, b = NSI:BrightenTimelineColor(r, g, b) end
        TooltipTitle(header, data.playerName, r, g, b)
        TooltipLine(string.format(T("%d reminders"), data.laneCount or count), STYLE.textDim)
        GameTooltip:Show()
        return
    end
    TooltipTitle(header, data.isCombined and T("Boss abilities") or data.text)
    if data.isBossAbility then
        TooltipLine(string.format(T("%d casts"), count), STYLE.textDim)
        local category = data.primaryCategory or data.category
        if category and not data.isCombined then
            local r, g, b = ResolveColor(data.color)
            GameTooltip:AddLine(category, r, g, b)
        end
    else
        TooltipLine(string.format(T("%d reminders"), count), STYLE.textDim)
        if data.isPlayerAssignment and data.playerName then
            local r, g, b = HexToColor(data.playerClassColor)
            if r then r, g, b = NSI:BrightenTimelineColor(r, g, b) end
            GameTooltip:AddLine(data.playerName, r or STYLE.labelText[1], g or STYLE.labelText[2], b or STYLE.labelText[3])
        end
    end
    GameTooltip:Show()
end

local function CreateHeaderParts(line)
    local header = line.lineHeader
    if line.icon then line.icon:Hide() end
    if line.text then line.text:Hide() end
    if header.HighlightTexture then header.HighlightTexture:SetAlpha(0) end

    header.nsBg = header:CreateTexture(nil, "BACKGROUND")
    header.nsBg:SetAllPoints()
    header.nsClassTint = header:CreateTexture(nil, "BACKGROUND", nil, 1)
    header.nsClassTint:SetAllPoints()
    header.nsClassTint:Hide()
    line.nsClassTint = line:CreateTexture(nil, "BACKGROUND", nil, 1)
    line.nsClassTint:SetAllPoints()
    line.nsClassTint:Hide()

    header.nsStrip = header:CreateTexture(nil, "ARTWORK")
    header.nsStrip:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    -- Reaches over the 1 px gap below the row, so a lane's strip runs unbroken.
    header.nsStrip:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, -1)
    header.nsStrip:SetWidth(STYLE.laneStripWidth)
    header.nsStrip:Hide()

    header.nsIcon = header:CreateTexture(nil, "ARTWORK")
    header.nsIcon:SetSize(STYLE.headerIconSize, STYLE.headerIconSize)
    header.nsIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    header.nsName = NewFontString(header, STYLE.labelTextSize)
    header.nsName:SetPoint("LEFT", header, "LEFT", STYLE.playerNameX, 0)
    header.nsName:SetWidth(STYLE.playerNameWidth)
    header.nsName:SetJustifyH("LEFT")

    header.nsLabel = NewFontString(header, STYLE.labelTextSize, STYLE.labelText)
    header.nsLabel:SetJustifyH("RIGHT")

    local check = CreateFrame("Button", nil, header)
    check:SetSize(STYLE.headerCheckSize, STYLE.headerCheckSize)
    check:SetPoint("LEFT", header, "LEFT", STYLE.headerCheckGap, 0)
    check.border = check:CreateTexture(nil, "BACKGROUND")
    check.border:SetAllPoints()
    Paint(check.border, STYLE.checkBorder)
    check.bg = check:CreateTexture(nil, "BORDER")
    check.bg:SetPoint("TOPLEFT", 1, -1)
    check.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    Paint(check.bg, STYLE.checkBg)
    check.fill = check:CreateTexture(nil, "ARTWORK")
    check.fill:SetPoint("TOPLEFT", 2, -2)
    check.fill:SetPoint("BOTTOMRIGHT", -2, 2)
    Paint(check.fill, STYLE.checkFill)
    check:SetScript("OnEnter", function(self)
        Paint(self.border, STYLE.checkBorderHover)
        PaintRow(line, true)
        TooltipTitle(self, T("Hide this ability"))
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", function(self)
        Paint(self.border, STYLE.checkBorder)
        PaintRow(line, false)
        GameTooltip:Hide()
    end)
    check:SetScript("OnClick", function()
        local data = line.lineData
        local filter = NSI.TimelineWindow and NSI.TimelineWindow.bossFilter
        if not (data and data.abilityKey ~= nil and filter) then return end
        GameTooltip:Hide()
        NSI:SetBossAbilitiesHidden(filter.encounterID, {data.abilityKey}, true)
        NSI:RefreshTimelineForMode()
    end)
    check:Hide()
    header.nsCheck = check

    header.nsDivider = header:CreateTexture(nil, "OVERLAY")
    header.nsDivider:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    header.nsDivider:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
    header.nsDivider:SetHeight(1)
    Paint(header.nsDivider, STYLE.groupDivider)

    header.nsSection = NewFontString(header, STYLE.sectionTextSize, STYLE.sectionText)
    header.nsSection:SetPoint("LEFT", header, "LEFT", STYLE.headerIconX, 0)
    header.nsSectionRule = header:CreateTexture(nil, "OVERLAY")
    header.nsSectionRule:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    header.nsSectionRule:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    header.nsSectionRule:SetHeight(1)
    Paint(header.nsSectionRule, STYLE.sectionRule)

    local roleTexture = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
    header.nsTank = header:CreateTexture(nil, "ARTWORK")
    header.nsTank:SetSize(STYLE.roleIconSize, STYLE.roleIconSize)
    header.nsTank:SetTexture(roleTexture)
    header.nsTank:SetTexCoord(0 / 64, 19 / 64, 22 / 64, 41 / 64)
    header.nsHealer = header:CreateTexture(nil, "ARTWORK")
    header.nsHealer:SetSize(STYLE.roleIconSize, STYLE.roleIconSize)
    header.nsHealer:SetTexture(roleTexture)
    header.nsHealer:SetTexCoord(20 / 64, 39 / 64, 1 / 64, 20 / 64)

    line.nsRule = line:CreateTexture(nil, "ARTWORK")
    line.nsRule:SetPoint("BOTTOMLEFT", line, "BOTTOMLEFT", 0, 0)
    line.nsRule:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 0, 0)
    line.nsRule:SetHeight(1)
    Paint(line.nsRule, STYLE.sectionRule)
    line.nsDivider = line:CreateTexture(nil, "ARTWORK")
    line.nsDivider:SetPoint("TOPLEFT", line, "TOPLEFT", 0, 0)
    line.nsDivider:SetPoint("TOPRIGHT", line, "TOPRIGHT", 0, 0)
    line.nsDivider:SetHeight(1)
    Paint(line.nsDivider, STYLE.groupDivider)
    for _, frame in ipairs({header, line}) do
        local rule = frame:CreateTexture(nil, frame == header and "OVERLAY" or "ARTWORK")
        rule:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        rule:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        rule:SetHeight(STYLE.mineDividerHeight)
        Paint(rule, STYLE.mineDivider)
        rule:Hide()
        frame.nsMineRule = rule
    end

    header:SetScript("OnEnter", function(self)
        PaintRow(line, true)
        LaneTooltip(self, line)
    end)
    header:SetScript("OnLeave", function()
        PaintRow(line, false)
        GameTooltip:Hide()
    end)
end

local function RefreshHeaderParts(line, bossDisplayMode)
    local header = line.lineHeader
    local data = line.lineData
    if not header or not header.nsBg or not data then return end
    local isSection = data.isSection and true or false
    local sectionRule = isSection and not data.isFilterRow
    -- The filter row's header holds only the row filters.
    header.nsSection:SetShown(isSection and not data.isFilterRow)
    header.nsSectionRule:SetShown(sectionRule)
    line.nsRule:SetShown(sectionRule)
    header.nsSection:ClearAllPoints()
    header.nsSection:SetPoint("LEFT", header, "LEFT", STYLE.headerIconX, 0)
    local mineRule = not isSection and data.dividerBelow and true or false
    header.nsMineRule:SetShown(mineRule)
    line.nsMineRule:SetShown(mineRule)
    -- Rows are pooled, so the class tint and strip are set or cleared on every refresh.
    local laneR, laneG, laneB
    if data.isPlayerAssignment then
        laneR, laneG, laneB = HexToColor(data.playerClassColor)
        if laneR then laneR, laneG, laneB = NSI:BrightenTimelineColor(laneR, laneG, laneB) end
    end
    header.nsClassTint:SetShown(laneR ~= nil)
    line.nsClassTint:SetShown(laneR ~= nil)
    header.nsStrip:SetShown(laneR ~= nil)
    if laneR then
        header.nsClassTint:SetColorTexture(laneR, laneG, laneB, STYLE.laneTintHeaderAlpha)
        line.nsClassTint:SetColorTexture(laneR, laneG, laneB, STYLE.laneTintAlpha)
        header.nsStrip:SetColorTexture(laneR, laneG, laneB, 1)
    end
    if isSection then
        header.nsSection:SetText((data.text or ""):upper())
        header.nsCheck:Hide()
        header.nsIcon:Hide()
        header.nsName:Hide()
        header.nsLabel:Hide()
        header.nsDivider:Hide()
        header.nsTank:Hide()
        header.nsHealer:Hide()
        line.nsDivider:Hide()
        PaintRow(line, false)
        return
    end

    local divider = data.groupDivider and true or false
    header.nsDivider:SetShown(divider)
    line.nsDivider:SetShown(divider)

    if data.isPlayerAssignment then
        if data.groupStart then
            local r, g, b = HexToColor(data.playerClassColor)
            if r then
                r, g, b = NSI:BrightenTimelineColor(r, g, b)
            else
                r, g, b = STYLE.text[1], STYLE.text[2], STYLE.text[3]
            end
            header.nsName:SetTextColor(r, g, b, 1)
            header.nsName:SetText(data.playerName or "")
            header.nsName:Show()
        else
            header.nsName:Hide()
        end
    else
        header.nsName:Hide()
    end

    header.nsIcon:ClearAllPoints()
    header.nsIcon:SetPoint("RIGHT", header, "RIGHT", -STYLE.headerIconX, 0)
    header.nsIcon:SetTexture(data.icon)
    header.nsIcon:SetShown(data.icon ~= nil)

    local isBoss = data.isBossAbility and not data.isCombined
    local showCheck = isBoss and data.abilityKey ~= nil
    header.nsCheck:SetShown(showCheck and true or false)
    local showTank = isBoss and data.isImportantTank and bossDisplayMode ~= NSI.BossDisplayModes.IMPORTANT_TANK
    local showHealer = isBoss and data.isImportantHealer and bossDisplayMode ~= NSI.BossDisplayModes.IMPORTANT_HEALER
    local left = showCheck and (2 * STYLE.headerCheckGap + STYLE.headerCheckSize) or 6
    header.nsHealer:ClearAllPoints()
    header.nsTank:ClearAllPoints()
    if showHealer then
        header.nsHealer:SetPoint("LEFT", header, "LEFT", left, 0)
        left = left + STYLE.roleIconSize + STYLE.roleIconGap
    end
    if showTank then
        header.nsTank:SetPoint("LEFT", header, "LEFT", left, 0)
        left = left + STYLE.roleIconSize + STYLE.roleIconGap
    end
    header.nsHealer:SetShown(showHealer and true or false)
    header.nsTank:SetShown(showTank and true or false)

    if data.isPlayerAssignment then
        left = STYLE.playerNameX + STYLE.playerNameWidth + STYLE.playerNameGap - 2
    end
    header.nsLabel:ClearAllPoints()
    header.nsLabel:SetPoint("LEFT", header, "LEFT", left + 2, 0)
    header.nsLabel:SetPoint("RIGHT", header, "RIGHT", -STYLE.headerLabelX, 0)
    header.nsLabel:SetText(data.isCombined and T("All abilities") or data.text or "")
    header.nsLabel:Show()

    PaintRow(line, false)
end

-- A boss cast ends at the block's time: a line from the cast start (never before the pull) to the block's left
-- edge, with an end cap at the start. Drawn on the block's BORDER layer, under the icon or tick.
local function StyleCastLine(block, line, castTime, time, pps, r, g, b)
    local seconds = tonumber(castTime) or 0
    local width = seconds > 0 and math.min(seconds, math.max(time, 0)) * pps or 0
    local cast = block.nsCast
    if width < 1 then
        if cast then
            cast:Hide()
            block.nsCastCap:Hide()
        end
        return
    end
    if not cast then
        cast = block:CreateTexture(nil, "BORDER")
        cast:SetHeight(STYLE.castLineThickness)
        local cap = block:CreateTexture(nil, "BORDER")
        cap:SetWidth(STYLE.castLineThickness)
        cap:SetPoint("LEFT", cast, "LEFT", 0, 0)
        block.nsCast, block.nsCastCap = cast, cap
    end
    local cap = block.nsCastCap
    cast:ClearAllPoints()
    cast:SetPoint("RIGHT", block, "LEFT", 0, 0)
    cast:SetWidth(width)
    cast:SetColorTexture(r, g, b, 1)
    cap:SetHeight(math.max(STYLE.castLineThickness, math.floor((line and line:GetHeight() or 0) / 2 + 0.5)))
    cap:SetColorTexture(r, g, b, 1)
    cast:Show()
    cap:Show()
end

local function StyleBlock(block, data)
    local payload = data.payload
    local timeline = block.timeline
    local pps = (timeline.pixelPerSecond or 15) * (timeline.currentScale or 1)
    local line = block:GetParent()
    local r, g, b = BlockColor(payload, line and line.lineData)
    local time = tonumber(data[1]) or 0
    local dur = tonumber(data[4]) or 0
    local isBoss = payload and payload.isBossAbility

    local window = NSI.TimelineWindow
    local bossIcons = not (window and window.showBossIcons == false)
    if not isBoss or bossIcons then
        block.icon:Show()
        block.backgroundBorder:Show()
        if block.nsTick then block.nsTick:Hide() end
    else
        block.icon:Hide()
        block.backgroundBorder:Hide()
        local tick = block.nsTick
        if not tick then
            tick = block:CreateTexture(nil, "ARTWORK")
            tick:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
            tick:SetPoint("BOTTOMLEFT", block, "BOTTOMLEFT", 0, 0)
            tick:SetWidth(STYLE.tickWidth)
            block.nsTick = tick
        end
        tick:SetColorTexture(r, g, b, 1)
        tick:Show()
        block:SetWidth(STYLE.tickHitWidth)
    end

    if not isBoss then
        -- Equal frame levels draw in no fixed order; later reminders stack on top of earlier ones.
        if not block.nsIndex and line and line.blocks then
            for i, other in ipairs(line.blocks) do
                if other == block then block.nsIndex = i break end
            end
        end
        block:SetFrameLevel(block:GetFrameLevel() + math.min(block.nsIndex or 0, STYLE.maxBlockStack))
    end

    local prePull = payload and payload.prePull
    block.icon:SetDesaturated(prePull and true or false)
    if payload and payload.invalid then
        block:SetAlpha(STYLE.invalidAlpha)
    elseif prePull then
        block:SetAlpha(STYLE.prePullAlpha)
    elseif payload and payload.layer == "view" then
        block:SetAlpha(STYLE.viewOnlyAlpha)
    elseif payload and payload.readOnly then
        block:SetAlpha(STYLE.readOnlyAlpha)
    else
        block:SetAlpha(1)
    end

    local personal = not isBoss and payload and payload.srcNote ~= nil
    local edges = block.nsEdges
    if personal and not edges then
        local icon, width = block.icon, STYLE.personalEdge
        edges = {}
        for i, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
            local edge = block:CreateTexture(nil, "OVERLAY")
            Paint(edge, STYLE.accent)
            local horizontal = i <= 2
            edge:SetPoint(horizontal and side .. "LEFT" or "TOP" .. side, icon, horizontal and side .. "LEFT" or "TOP" .. side, 0, 0)
            edge:SetPoint(horizontal and side .. "RIGHT" or "BOTTOM" .. side, icon, horizontal and side .. "RIGHT" or "BOTTOM" .. side, 0, 0)
            if horizontal then edge:SetHeight(width) else edge:SetWidth(width) end
            edges[i] = edge
        end
        block.nsEdges = edges
    end
    if edges then
        for _, edge in ipairs(edges) do edge:SetShown(personal and true or false) end
    end

    StyleCastLine(block, line, isBoss and payload.castTime, time, pps, r, g, b)

    local bar = block.blockLength
    if not bar then return end
    bar:EnableMouse(false)
    bar:ClearAllPoints()
    if bar.RightIcon then bar.RightIcon:Hide() end
    bar.Texture:SetVertexColor(1, 1, 1, 1)
    bar.Texture:Show()
    local width = 0
    if isBoss then
        local fightLength = timeline.data and timeline.data.length or (time + dur)
        width = math.max(0, math.min(dur, fightLength - time)) * pps
        if width >= 1 then
            bar:SetPoint("LEFT", block, "LEFT", 0, 0)
            bar:SetSize(width, line:GetHeight())
            bar.Texture:SetColorTexture(r, g, b, STYLE.bossBarAlpha)
        end
    end
    bar:SetShown(width >= 1)
end

-- The settings table and colour key BuildReminder (Reminders.lua) falls back to per display type.
local DISPLAY_COLOR_SOURCE = {
    Text = {"TextSettings", "textColors"}, Icon = {"IconSettings", "textColors"},
    Bar = {"BarSettings", "barColors"}, Circle = {"CircleSettings", "ringColors"},
}

-- Display type and r, g, b of a parsed reminder line, resolved the way BuildReminder resolves them.
local function ReminderLook(self, fields)
    local settings = type(NSRT.ReminderSettings) == "table" and NSRT.ReminderSettings or {}
    local displayType = self:ReminderDisplayType(fields.DisplayType)
        or fields.spellID and self:ReminderDisplayType(settings.SpellDisplayType) or "Text"
    local r, g, b = self:ParseReminderColor(fields.colors)
    if not r then
        local source = DISPLAY_COLOR_SOURCE[displayType]
        local group = type(settings[source[1]]) == "table" and settings[source[1]]
        local color = group and group[source[2]]
        if type(color) == "table" and tonumber(color[1]) and tonumber(color[2]) and tonumber(color[3]) then
            r, g, b = tonumber(color[1]), tonumber(color[2]), tonumber(color[3])
        end
    end
    return displayType, r, g, b
end

-- A square of the colour; a dark one also gets its hex code, since the square vanishes on the tooltip.
local function ColorSwatch(r, g, b)
    local R, G, B = math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
    local swatch = string.format("|TInterface\\Buttons\\WHITE8X8:12:12:0:0:8:8:0:8:0:8:%d:%d:%d|t", R, G, B)
    if 0.299 * r + 0.587 * g + 0.114 * b < 0.2 then
        swatch = swatch .. string.format(" #%02X%02X%02X", R, G, B)
    end
    return swatch
end

-- One line per sound setting the reminder line sets itself.
local function ReminderSoundLines(fields)
    local lines = {}
    if fields.TTS == "true" then
        lines[#lines + 1] = T("TTS on")
    elseif fields.TTS == "false" then
        lines[#lines + 1] = T("TTS off")
    elseif fields.TTS then
        lines[#lines + 1] = string.format(T("TTS: %s"), fields.TTS)
    end
    if fields.TTSTimer then
        lines[#lines + 1] = string.format(T("TTS %ss before"), NSI:FormatNoteNumber(fields.TTSTimer))
    end
    if fields.countdown then
        lines[#lines + 1] = string.format(T("Countdown from %s"), fields.countdown)
    end
    if fields.sound then
        lines[#lines + 1] = string.format(T("Sound: %s"), fields.sound)
    end
    return lines
end

local function BlockTooltip(window, block)
    local data = block.blockData
    if not data or not block.info or not block.info.time then return end
    local payload = data.payload or {}
    local line = block:GetParent()
    local lineData = line and line.lineData
    local spellID = block.info.spellId
    local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)
    local absTime = tonumber(data[1]) or 0
    local dur = tonumber(data[4]) or 0

    if payload.isBossAbility then
        local r, g, b = BlockColor(payload, lineData)
        TooltipTitle(block, payload.abilityName or (spellInfo and spellInfo.name) or (lineData and lineData.text) or T("Boss ability"))
        local phase, start = NSI:PhaseFromTime(window.currentEncounterID, absTime, window.currentDifficulty)
        TooltipLine(NSI:FormatMoveLabel(phase, absTime - start, absTime), STYLE.textDim)
        local castTime = tonumber(payload.castTime) or 0
        if castTime > 0 then
            TooltipLine(string.format(T("Cast time: %ss"), NSI:FormatNoteNumber(castTime)))
        end
        if dur > 0 then
            TooltipLine(string.format(T("Lasts %ss"), NSI:FormatNoteNumber(dur)))
        end
        local category = payload.primaryCategory or payload.category
        if category then
            GameTooltip:AddLine(category, r, g, b)
        end
        GameTooltip:Show()
        return
    end

    local text = payload.text
    local fields = payload.srcRaw and NSI:ParseReminderLine(payload.srcRaw) or {}
    local displayType, r, g, b = ReminderLook(NSI, fields)
    -- Text and Icon take the colour on their text; Bar and Circle on the bar or ring, which the swatch shows.
    local textColor = r and (displayType == "Text" or displayType == "Icon") and {r, g, b} or nil
    if spellInfo then
        TooltipTitle(block, spellInfo.name)
    else
        local c = textColor or STYLE.text
        TooltipTitle(block, text or T("Reminder"), c[1], c[2], c[3])
    end
    if payload.prePull then
        TooltipLine(string.format(T("%s before the pull"), NSI:FormatTimelineClock(-(payload.relTime or 0))), STYLE.textDim)
    else
        TooltipLine(NSI:FormatMoveLabel(payload.phase or 1, payload.relTime or absTime, absTime), STYLE.textDim)
    end
    if payload.invalid then
        TooltipLine(payload.invalid, STYLE.danger)
    end
    if text and spellInfo then
        TooltipLine(text, textColor)
    end
    local shows = string.format(T("Shows as %s"), T(displayType))
    TooltipLine(r and (shows .. " " .. ColorSwatch(r, g, b)) or shows)
    if dur > 0 then
        TooltipLine(string.format(T("Shown %ss before"), NSI:FormatNoteNumber(dur)))
    end
    for _, soundLine in ipairs(ReminderSoundLines(fields)) do
        TooltipLine(soundLine)
    end
    local glow = payload.glowUnit and payload.glowUnit:match("^%s*(.-)%s*$")
    if glow and glow ~= "" then
        TooltipLine(string.format(T("Glows: %s"), glow))
    end
    local editable = payload.srcRaw and payload.srcNote
    if payload.readOnly then
        TooltipLine(T("Click to view it. Right-click to copy it into your personal note."), STYLE.textDim)
        TooltipLine(payload.layer == "view" and T("From a shared note you are viewing. It is not loaded.")
            or T("From the shared note. Edit it from the Shared Notes tab."), STYLE.textDim)
    elseif payload.prePull then
        TooltipLine(T("Pre-pull reminders sit at 0:00 and can't be dragged."), STYLE.textDim)
        if editable then TooltipLine(T("Click to edit. Right-click for more."), STYLE.textDim) end
    elseif editable then
        TooltipLine(T("Click to edit. Drag to move. Right-click for more."), STYLE.textDim)
    end
    GameTooltip:Show()
end

-- Thumb length follows how much of the content is on screen.
local function UpdateScrollThumbs(timeline)
    local hs, vs, body = timeline.horizontalSlider, timeline.verticalSlider, timeline.body
    local viewW, viewH = timeline:GetWidth() or 1, timeline:GetHeight() or 1
    if body:GetHeight() < viewH then
        body:SetHeight(viewH)
    end
    local bodyW, bodyH = math.max(body:GetWidth() or 1, 1), math.max(body:GetHeight() or 1, 1)
    if hs and hs.thumb then
        hs.thumb:SetSize(math.max(STYLE.scrollThumbMin, viewW * math.min(1, viewW / bodyW)), STYLE.scrollBarSize)
    end
    if vs and vs.thumb then
        vs.thumb:SetSize(STYLE.scrollBarSize, math.max(STYLE.scrollThumbMin, viewH * math.min(1, viewH / bodyH)))
    end
end

local function StyleScrollBar(slider, tooltip)
    if not slider then return end
    if slider.SetBackdrop then slider:SetBackdrop(nil) end
    if slider.bg then Paint(slider.bg, STYLE.scrollTrack) end
    if slider.thumb then
        slider.thumb:SetVertexColor(1, 1, 1, 1)
        Paint(slider.thumb, STYLE.scrollThumb)
    end
    slider:HookScript("OnEnter", function(self)
        TooltipTitle(self, tooltip)
        GameTooltip:Show()
    end)
    slider:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Left-aligned label with room for a chevron, for buttons that open a menu.
local function MakeMenuButton(button)
    button.labelFrame:ClearAllPoints()
    button.labelFrame:SetPoint("TOPLEFT", button.frame, "TOPLEFT", 8, 0)
    button.labelFrame:SetPoint("BOTTOMRIGHT", button.frame, "BOTTOMRIGHT", -20, 0)
    button.label:SetJustifyH("LEFT")
    button.label:SetWordWrap(false)
    local arrow = button.frame:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]])
    arrow:SetSize(10, 10)
    arrow:SetPoint("RIGHT", button.frame, "RIGHT", -6, 0)
    button.menuArrow = arrow
end

-- A solid fill between the backdrop and the label, for buttons that must stand out (the component's hover
-- overlay would grey it out), with dark text.
local function SolidFill(button, fill, hover, textColor)
    local fillFrame = CreateFrame("Frame", nil, button.frame)
    fillFrame:SetAllPoints(button.frame)
    fillFrame:SetFrameLevel(button.hoverBg:GetFrameLevel())
    fillFrame:EnableMouse(false)
    local texture = fillFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(unpack(fill))
    for _, region in ipairs({button.hoverBg:GetRegions()}) do region:Hide() end
    button.frame:HookScript("OnEnter", function() texture:SetColorTexture(unpack(hover)) end)
    button.frame:HookScript("OnLeave", function() texture:SetColorTexture(unpack(fill)) end)
    button.frame:HookScript("OnShow", function() texture:SetColorTexture(unpack(fill)) end)
    -- Dark text on the bright fill is only readable without the UI font's outline and shadow.
    local setText = button.SetText
    function button:SetText(text)
        setText(self, text)
        self.label:SetFont(NSI:ValidateFontPath(NSI:GetUIFontPath()), STYLE.controlTextSize, "")
        self.label:SetShadowColor(0, 0, 0, 0)
    end
    -- The component's Enable resets the label to the default text colour.
    local enable = button.Enable
    function button:Enable()
        enable(self)
        self:SetTextColor(unpack(textColor))
    end
    button:SetText(button:GetText())
    button:SetTextColor(unpack(textColor))
end

-- Create the timeline window
local function ClampToSlider(slider, value)
    local low, high = slider:GetMinMaxValues()
    return math.max(low, math.min(high, value))
end

-- Rows are pooled, so after every refresh the row filters move to whichever row is the filter row, and hide
-- when none is.
local function PlaceRowFilters(timeline, filters)
    local host
    local count = timeline.data and timeline.data.lines and #timeline.data.lines or 0
    for i = 1, count do
        local line = timeline.lines[i]
        if line and line.lineData and line.lineData.isFilterRow then
            host = line
            break
        end
    end
    filters:ClearAllPoints()
    if not host then
        filters:Hide()
        return
    end
    local header = host.lineHeader
    filters:SetPoint("LEFT", header, "LEFT", STYLE.filterRowPad, 0)
    filters:Show()
end

-- Re-packs compact rows for the zoom on screen. The zoom and horizontal scroll are untouched; RefreshTimeLine
-- resets the vertical scroll, so that is put back.
local function RepackCompactRows(self, window)
    local timeline = window.timeline
    local data = timeline and timeline.data
    local compact = data and data.compact
    if not compact or not window.compactRows then return end
    local width = CompactIconSeconds(timeline)
    if width == compact.width then return end
    compact.width = width
    local lines, signature = CompactLaneLines(self, compact.lanes, width)
    if signature == compact.signature then return end
    compact.signature = signature
    self:MarkTimelineLaneGroups(lines)
    local all = data.lines
    local first = #all - (data.reminderLines or 0)
    for i = #all, first + 1, -1 do all[i] = nil end
    for i, line in ipairs(lines) do all[first + i] = line end
    data.reminderLines = #lines
    local hs, vs = timeline.horizontalSlider, timeline.verticalSlider
    local h, v = hs and hs:GetValue(), vs and vs:GetValue()
    timeline:RefreshTimeLine()
    if hs and hs:GetValue() ~= h then hs:SetValue(ClampToSlider(hs, h)) end
    if vs then vs:SetValue(ClampToSlider(vs, v)) end
end

local LEGEND_READING = {
    "Icons are reminders and boss casts. With Show icons off, boss casts are thin ticks.",
    "The line before a boss cast is its cast time. The bar after it shows how long it lasts.",
    "A blue frame marks reminders from your personal note. Reminders from the shared note have no frame.",
    "Faded icons are pre-pull, read-only or never fire. Hover one to see why.",
    "Vertical lines with a P chip mark where each phase starts.",
    "The timeline shows the loaded shared note and your personal note for the boss on screen.",
    "Shared note reminders are read-only. Everything you add goes to your personal note.",
}
local LEGEND_MOUSE = {
    "Scroll: zoom in and out.",
    "Ctrl+scroll: scroll the rows.",
    "Right-drag: pan.",
    "Right-click empty space: add a reminder.",
    "Right-click a boss cast: add a reminder at that cast.",
    "Click a reminder: edit it.",
    "Drag a reminder: move it to the time under the mouse.",
    "Right-click a reminder: duplicate or delete it.",
    "Click a phase chip: scroll to it. Drag it: move the phase. Right-click it: reset options.",
}
local LEGEND_WIDTH, LEGEND_TEXT_WIDTH, LEGEND_SWATCH_WIDTH, LEGEND_ROW = 600, 330, 115, 14

-- Built with the window so opening it never creates frames.
local function CreateTimelineLegend(window, toggle)
    local legend = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, window)
    legend:SetWidth(LEGEND_WIDTH)
    legend:SetPoint("TOPRIGHT", window, "TOPRIGHT", -6, -24)
    legend:SetFrameStrata(STYLE.legendStrata)
    legend:SetFrameLevel(window:GetFrameLevel() + 60)
    legend:EnableMouse(true)
    legend:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    legend:SetBackdropColor(unpack(STYLE.panel))
    legend:SetBackdropBorderColor(unpack(STYLE.panelBorder))
    legend:Hide()

    local title = NewFontString(legend, STYLE.dialogTitleSize, STYLE.accent)
    title:SetPoint("TOPLEFT", legend, "TOPLEFT", 10, -8)
    title:SetText(T("Legend"))
    local close = CreateFrame("Button", nil, legend)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", legend, "TOPRIGHT", -4, -4)
    close:SetNormalFontObject("GameFontNormal")
    close:SetText("×")
    close:SetScript("OnClick", function() legend:Hide() end)

    local texts = {}
    local function Section(heading, lines)
        local fs = NewFontString(legend, STYLE.helpTextSize + 1, STYLE.text)
        fs:SetText(T(heading))
        texts[#texts + 1] = {fs = fs, gap = #texts > 0 and 8 or 0}
        for _, key in ipairs(lines) do
            local line = NewFontString(legend, STYLE.helpTextSize + 1, STYLE.textDim)
            line:SetWidth(LEGEND_TEXT_WIDTH)
            line:SetJustifyH("LEFT")
            line:SetWordWrap(true)
            line:SetText(T(key))
            texts[#texts + 1] = {fs = line, gap = 2}
        end
    end
    Section("Reading the timeline", LEGEND_READING)
    Section("Mouse", LEGEND_MOUSE)

    local colorsTitle = NewFontString(legend, STYLE.helpTextSize + 1, STYLE.text)
    colorsTitle:SetText(T("Colours"))
    colorsTitle:SetPoint("TOPLEFT", legend, "TOPLEFT", 20 + LEGEND_TEXT_WIDTH, -30)
    local swatches = {}
    local count = 2
    for _ in pairs(NSI.BossTimelineColors or {}) do count = count + 1 end
    for i = 1, count do
        local row = CreateFrame("Frame", nil, legend)
        row:SetSize(LEGEND_SWATCH_WIDTH, LEGEND_ROW)
        local column, index = (i - 1) % 2, math.floor((i - 1) / 2)
        row:SetPoint("TOPLEFT", colorsTitle, "BOTTOMLEFT", column * (LEGEND_SWATCH_WIDTH + 6), -4 - index * LEGEND_ROW)
        row.swatch = row:CreateTexture(nil, "ARTWORK")
        row.swatch:SetSize(10, 10)
        row.swatch:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.label = NewFontString(row, STYLE.helpTextSize, STYLE.textDim)
        row.label:SetPoint("LEFT", row.swatch, "RIGHT", 4, 0)
        row.label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        swatches[i] = row
    end

    function legend:Layout()
        local y = -30
        for _, entry in ipairs(texts) do
            y = y - entry.gap
            entry.fs:ClearAllPoints()
            entry.fs:SetPoint("TOPLEFT", legend, "TOPLEFT", 10, y)
            y = y - entry.fs:GetStringHeight()
        end
        local timeline = window.timeline
        local categories = NSI:TimelineLegendCategories(timeline and timeline.data and timeline.data.lines)
        local a = STYLE.accent
        table.insert(categories, 1, {label = T("Reminders"), color = {a[1], a[2], a[3]}, exact = true})
        local shown = 0
        for i, row in ipairs(swatches) do
            local category = categories[i]
            if category then
                local r, g, b
                if category.exact then
                    r, g, b = category.color[1], category.color[2], category.color[3]
                else
                    r, g, b = ResolveColor(category.color)
                end
                row.swatch:SetColorTexture(r, g, b, 1)
                local label = category.label or (category.name == "unknown" and T("Other"))
                    or category.name:gsub("^%l", string.upper)
                row.label:SetText(label)
                shown = i
            end
            row:SetShown(category ~= nil)
        end
        local colorsBottom = 30 + 18 + math.ceil(shown / 2) * LEGEND_ROW
        legend:SetHeight(math.max(-y, colorsBottom) + 10)
    end

    legend:SetScript("OnShow", function(self)
        self:Layout()
        self:RegisterEvent("GLOBAL_MOUSE_DOWN")
    end)
    legend:SetScript("OnHide", function(self) self:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
    legend:SetScript("OnEvent", function(self)
        if not self:IsMouseOver() and not toggle:IsMouseOver() then self:Hide() end
    end)
    return legend
end

function NSI:CreateTimelineWindow()
    if not NSI.UI.Components then return end
    local C = NSI.UI.Components
    local window_width = 1100
    local window_height = 550

    local timelineWindow = NSI.UI.Pixel.CreateSimplePanel(UIParent, window_width, window_height,
        Colored("Northern Sky", STYLE.accent) .. " " .. T("Timeline"), "NSUITimelineWindow", {
        DontRightClickClose = true,
        UseStatusBar = false,
            UseScaleBar = true,
        },
        NSRT.NSUI.timeline_window)
    timelineWindow:SetPoint("CENTER")
    timelineWindow:SetFrameStrata("DIALOG")
    timelineWindow:EnableMouse(true)
    timelineWindow:SetMovable(true)
    timelineWindow:SetClampedToScreen(true)
    timelineWindow:RegisterForDrag("LeftButton")
    timelineWindow:SetScript("OnDragStart", timelineWindow.StartMoving)
    timelineWindow:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        NSI:SaveTimelineWindowState()
    end)
    -- The DF panel also moves itself on mouse down/up (the title bar passes clicks through to it).
    timelineWindow:HookScript("OnMouseDown", function(frame)
        frame.titleMoveStarted = frame.IsMoving
    end)
    timelineWindow:HookScript("OnMouseUp", function(frame)
        if frame.titleMoveStarted then
            frame.titleMoveStarted = nil
            NSI:SaveTimelineWindowState()
        end
    end)
    timelineWindow:SetBackdropColor(unpack(STYLE.panel))
    timelineWindow:SetBackdropBorderColor(unpack(STYLE.panelBorder))
    if timelineWindow.TitleBar then
        if timelineWindow.TitleBar.SetBackdropColor then
            timelineWindow.TitleBar:SetBackdropColor(unpack(STYLE.titleBar))
            timelineWindow.TitleBar:SetBackdropBorderColor(0, 0, 0, 0)
        end
    end
    if timelineWindow.Title then
        SetUIFont(timelineWindow.Title, STYLE.titleSize)
        Tint(timelineWindow.Title, STYLE.text)
    end
    local closeButton = timelineWindow.Close
    if closeButton then
        local closeIcon = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]]
        closeButton:SetSize(14, 14)
        closeButton:SetAlpha(1)
        closeButton:SetNormalTexture(closeIcon)
        closeButton:SetPushedTexture(closeIcon)
        closeButton:SetHighlightTexture(closeIcon)
        closeButton:GetHighlightTexture():SetAlpha(0)
        local closeTexture = closeButton:GetNormalTexture()
        closeTexture:SetDesaturated(false)
        closeTexture:SetVertexColor(unpack(STYLE.textDim))
        closeButton:GetPushedTexture():SetDesaturated(false)
        closeButton:HookScript("OnEnter", function() closeTexture:SetVertexColor(unpack(STYLE.accent)) end)
        closeButton:HookScript("OnLeave", function() closeTexture:SetVertexColor(unpack(STYLE.textDim)) end)
    end

    local legendButton = CreateFrame("Button", nil, timelineWindow.TitleBar or timelineWindow)
    legendButton:SetSize(16, 16)
    if closeButton then
        legendButton:SetPoint("RIGHT", closeButton, "LEFT", -6, 0)
    else
        legendButton:SetPoint("TOPRIGHT", timelineWindow, "TOPRIGHT", -26, -3)
    end
    local legendGlyph = NewFontString(legendButton, STYLE.titleSize, STYLE.textDim)
    legendGlyph:SetPoint("CENTER")
    legendGlyph:SetText("?")
    local legend = CreateTimelineLegend(timelineWindow, legendButton)
    timelineWindow.legend = legend
    legendButton:SetScript("OnClick", function() legend:SetShown(not legend:IsShown()) end)
    legendButton:SetScript("OnEnter", function(self)
        Tint(legendGlyph, STYLE.accent)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(T("Legend and mouse help"))
        GameTooltip:Show()
    end)
    legendButton:SetScript("OnLeave", function()
        Tint(legendGlyph, STYLE.textDim)
        GameTooltip:Hide()
    end)

    local optionsButton = CreateFrame("Button", nil, timelineWindow.TitleBar or timelineWindow)
    local optionsGlyph = NewFontString(optionsButton, STYLE.titleButtonTextSize, STYLE.textDim)
    optionsGlyph:SetPoint("CENTER")
    optionsGlyph:SetText(T("NSRT"))
    optionsButton:SetSize(math.ceil(optionsGlyph:GetStringWidth()) + 6, 16)
    optionsButton:SetPoint("RIGHT", legendButton, "LEFT", -6, 0)
    -- What "/ns" with no arguments runs (SlashCommands.lua).
    optionsButton:SetScript("OnClick", function()
        if self:LoadUI(true) then
            self.NSUI:ToggleOptions()
        else
            self:ShowUIDisabledMessage()
        end
    end)
    optionsButton:SetScript("OnEnter", function(button)
        Tint(optionsGlyph, STYLE.accent)
        GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
        GameTooltip:SetText(T("Open the Northern Sky Raid Tools options."))
        GameTooltip:Show()
    end)
    optionsButton:SetScript("OnLeave", function()
        Tint(optionsGlyph, STYLE.textDim)
        GameTooltip:Hide()
    end)

    -- Create resize grip in bottom-right corner
    local resizeGrip = CreateFrame("Button", nil, timelineWindow)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", timelineWindow, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:EnableMouse(true)

    -- Custom resize logic to avoid the jump caused by StartSizing snapping to mouse position
    resizeGrip.isResizing = false
    resizeGrip:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.isResizing = true
            -- Store initial state when drag starts
            self.startWidth = timelineWindow:GetWidth()
            self.startHeight = timelineWindow:GetHeight()
            local scale = timelineWindow:GetEffectiveScale()
            local cursorX, cursorY = GetCursorPosition()
            self.startCursorX = cursorX / scale
            self.startCursorY = cursorY / scale

            -- Re-anchor to TOPLEFT so resize only affects bottom-right
            local left = timelineWindow:GetLeft()
            local top = timelineWindow:GetTop()
            timelineWindow:ClearAllPoints()
            timelineWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
    end)

    resizeGrip:SetScript("OnMouseUp", function(self, button)
        if self.isResizing then NSI:SaveTimelineWindowState() end
        self.isResizing = false
    end)

    resizeGrip:SetScript("OnUpdate", function(self)
        if not self.isResizing then return end

        local scale = timelineWindow:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        cursorX = cursorX / scale
        cursorY = cursorY / scale

        -- Calculate delta from start position
        local deltaX = cursorX - self.startCursorX
        local deltaY = cursorY - self.startCursorY

        -- Calculate new size (bottom-right resize: width increases with +X, height increases with -Y)
        local newWidth = self.startWidth + deltaX
        local newHeight = self.startHeight - deltaY

        newWidth = math.max(STYLE.minWidth, math.min(STYLE.maxWidth, newWidth))
        newHeight = math.max(STYLE.minHeight, math.min(STYLE.maxHeight, newHeight))

        timelineWindow:SetSize(newWidth, newHeight)
    end)
    timelineWindow.resizeGrip = resizeGrip

    timelineWindow.showMine = false
    timelineWindow.viewStates = {}
    -- boss: {encID, difficulty} on screen. sharedView: a stored shared note shown in place of the loaded one,
    -- view only. lastPersonal: [encID] = personal note last loaded for that boss here.
    timelineWindow.boss = nil
    timelineWindow.sharedView = nil
    timelineWindow.lastPersonal = {}

    local defaultBossMode = self.BossDisplayModes.IMPORTANT_HEALER

    local barY = STYLE.topBarY - STYLE.controlHeight / 2

    local function BarLabel(text)
        local fs = NewFontString(timelineWindow, STYLE.barLabelSize, STYLE.textDim)
        fs:SetText(text)
        return fs
    end

    local function BarButton(text, onClick, width, name, icon, tooltip)
        return C.CreateButton(timelineWindow, text, onClick, width, STYLE.controlHeight, name, icon, STYLE.controlTextSize, tooltip)
    end

    -- Positions and widths of the bar's controls come from LayoutTopBar.
    -- sharedInfo = {name, hint, viewing, mismatch, action}, set by UpdateTimelineControls; action only on the warning.
    local function ShowSharedTooltip(frame, withAction)
        local info = timelineWindow.sharedInfo
        if not info then return end
        TooltipTitle(frame, T("Shared note"))
        if info.name then TooltipLine(info.name, STYLE.text) end
        TooltipLine(info.hint, STYLE.textDim)
        if info.viewing then TooltipLine(info.viewing, STYLE.viewOnlyText) end
        if info.mismatch then TooltipLine(info.mismatch, STYLE.warning) end
        if withAction == true and info.action then TooltipLine(info.action, STYLE.accent) end
        GameTooltip:Show()
    end
    local function HideTooltip() GameTooltip:Hide() end

    local sharedTitle = BarLabel(T("Shared"))
    -- The loaded shared note; a menu only while it offers "Show <boss>" or "Stop viewing".
    local sharedMenu = BarButton("", function(btn)
        local items = self:TimelineSharedMenuItems()
        if #items > 0 then C.ShowContextMenuAtFrame(items, btn.frame, STYLE.menuWidth, STYLE.noteMenuRows) end
    end, STYLE.sharedWidth)
    MakeMenuButton(sharedMenu)
    sharedMenu.frame:HookScript("OnEnter", ShowSharedTooltip)
    sharedMenu.frame:HookScript("OnLeave", HideTooltip)
    timelineWindow.sharedMenu = sharedMenu

    local previewButton = BarButton(T("Shared notes"), function(btn)
        C.ShowContextMenuAtFrame(self:TimelinePreviewMenuItems(), btn.frame, STYLE.menuWidth, STYLE.noteMenuRows)
    end, STYLE.previewWidth, nil, nil, {title = T("Shared notes"),
        desc = T("Preview a stored shared note on the timeline without loading it. The raid leader and assists can also load and send one from here.")})
    MakeMenuButton(previewButton)
    timelineWindow.previewButton = previewButton

    -- The view-only pick, right of the Preview button, when it is the only thing to say.
    local sharedNotice = CreateFrame("Frame", nil, timelineWindow)
    sharedNotice:SetSize(1, STYLE.controlHeight)
    sharedNotice.text = NewFontString(sharedNotice, STYLE.barLabelSize, STYLE.viewOnlyText)
    sharedNotice.text:SetPoint("LEFT", sharedNotice, "LEFT", 0, 0)
    sharedNotice:EnableMouse(true)
    sharedNotice:SetScript("OnEnter", ShowSharedTooltip)
    sharedNotice:SetScript("OnLeave", HideTooltip)
    sharedNotice:Hide()

    -- In place of the notice when the shared note on screen and the personal note are for different bosses.
    local sharedWarning = BarButton("", function() self:FollowSharedWarning() end)
    SolidFill(sharedWarning, STYLE.warning, STYLE.warningHover, STYLE.warningText)
    sharedWarning.frame:HookScript("OnEnter", function(frame) ShowSharedTooltip(frame, true) end)
    sharedWarning.frame:HookScript("OnLeave", HideTooltip)
    sharedWarning.frame:Hide()

    local function MeasureNotice(text)
        sharedNotice.text:SetText(text)
        local width = math.ceil(sharedNotice.text:GetStringWidth())
        sharedNotice:SetWidth(math.max(1, width))
        return width
    end
    local function MeasureWarning(text)
        sharedWarning:SetText(text)
        local width = math.ceil(sharedWarning.label:GetStringWidth()) + 20
        sharedWarning:SetSize(width, STYLE.controlHeight)
        return width
    end
    -- texts: longest first; LayoutTopBar shows the first that fits. urgent picks the warning over the notice.
    function timelineWindow:SetSharedNotice(texts, urgent)
        sharedNotice:SetShown(texts ~= nil and not urgent)
        sharedWarning.frame:SetShown(texts ~= nil and urgent == true)
        local key = texts and ((urgent and "!" or "") .. table.concat(texts, "\n")) or nil
        if key == self.sharedNoticeKey then return end
        self.sharedNoticeKey = key
        self.sharedNoticeState = texts and {texts = texts, urgent = urgent,
            frame = urgent and sharedWarning.frame or sharedNotice, measure = urgent and MeasureWarning or MeasureNotice}
        self:LayoutTopBar()
    end

    local personalLabel = BarLabel(T("Personal"))
    -- Title and desc set by UpdateTimelineControls.
    local personalTooltip = {title = ""}
    local personalPicker = BarButton("", function(btn)
        C.ShowContextMenuAtFrame(self:TimelinePersonalMenuItems(), btn.frame, STYLE.menuWidth, STYLE.noteMenuRows)
    end, STYLE.personalWidth.max, "NSUITimelineEditNoteBtn", nil, personalTooltip)
    MakeMenuButton(personalPicker)
    personalPicker.tooltip = personalTooltip
    -- An icon, not a "<" glyph: a text-only button insets its label 10 px a side, which leaves no room at this size.
    local arrowIcon = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-right.png]]
    local prevBoss = BarButton("", function() self:StepTimelineBoss(-1) end, STYLE.controlHeight, nil, arrowIcon, T("Previous boss"))
    prevBoss.frame.icon:SetTexCoord(0.88, 0.12, 0.11, 0.89)
    local nextBoss = BarButton("", function() self:StepTimelineBoss(1) end, STYLE.controlHeight, nil, arrowIcon, T("Next boss"))
    timelineWindow.prevBoss = prevBoss
    timelineWindow.personalPicker = personalPicker
    timelineWindow.nextBoss = nextBoss

    -- Shown by UpdateTimelineControls while no personal note covering the boss on screen is loaded: it loads one
    -- of the boss's notes, or creates one when it has none. Sized to the wider label so the bar doesn't shift.
    local loadNoteTooltip = {title = T("Load my personal note")}
    local loadNoteButton = BarButton(T("Create my personal note"), function()
        local boss = timelineWindow.boss
        if not boss then return end
        local name = self:PreferredPersonalNote(boss.encID, timelineWindow.lastPersonal)
        if name then
            self:LoadTimelinePersonalNote(name, boss.encID)
        else
            self:CreateTimelinePersonalNote(boss.encID, boss.difficulty, true)
        end
    end, nil, nil, nil, loadNoteTooltip)
    SolidFill(loadNoteButton, STYLE.loadNoteFill, STYLE.loadNoteHover, STYLE.loadNoteText)
    local loadNoteWidth = loadNoteButton.label:GetStringWidth()
    loadNoteButton:SetText(T("Load my personal note"))
    loadNoteWidth = math.max(loadNoteWidth, loadNoteButton.label:GetStringWidth())
    loadNoteButton:SetSize(math.ceil(loadNoteWidth) + 20, STYLE.controlHeight)
    loadNoteButton.tooltip = loadNoteTooltip
    loadNoteButton.frame:Hide()
    timelineWindow.loadNoteButton = loadNoteButton

    local playIcon = "Interface\\AddOns\\NorthernSkyRaidTools\\Media\\Icons\\play_icon.png"
    local stopIcon = "Interface\\AddOns\\NorthernSkyRaidTools\\Media\\Icons\\stop_icon.png"
    local playColor = { 20 / 255, 245 / 255, 87 / 255, 1 }
    local stopColor = { 247 / 255, 32 / 255, 61 / 255, 1 }
    local playTooltip = {title = T("Play preview of what is on screen")}
    local playButton = BarButton(nil, function()
        if timelineWindow.previewActive then
            self:StopTimelinePreview()
        else
            self:StartTimelinePreview()
        end
    end, 26, nil, playIcon, playTooltip)
    playButton:SetPoint("RIGHT", timelineWindow, "TOPRIGHT", -STYLE.windowPad, barY)
    timelineWindow.playButton = playButton

    -- Keeps its slot while hidden, so Undo stays put when a preview starts.
    local skipButton = BarButton(T("+10s"), function()
        self:SkipTimelinePreview(10)
    end, nil, nil, nil, T("Skip 10 seconds ahead"))
    skipButton:SetPoint("RIGHT", playButton.frame, "LEFT", -STYLE.controlGap, 0)
    skipButton.frame:Hide()
    timelineWindow.skipButton = skipButton

    -- Also repaints after Enable/Disable, which reset the icon's colour.
    function timelineWindow:SetPreviewButtonState(playing)
        local icon = playButton.frame.icon
        if not icon then return end
        icon:SetTexture(playing and stopIcon or playIcon)
        playTooltip.title = playing and T("Stop preview") or T("Play preview of what is on screen")
        local c = playButton.frame:IsEnabled() and (playing and stopColor or playColor) or STYLE.textDim
        icon:SetVertexColor(c[1], c[2], c[3], 1)
        skipButton.frame:SetShown(playing and true or false)
    end
    timelineWindow:SetPreviewButtonState(false)

    local undoButton = BarButton(T("Undo"), function()
        self:UndoTimelineEdit()
    end)
    undoButton:SetPoint("RIGHT", skipButton.frame, "LEFT", -STYLE.controlGap, 0)
    undoButton:Disable()
    timelineWindow.undoButton = undoButton

    timelineWindow.showBossAbilities = true
    timelineWindow.bossDisplayMode = defaultBossMode

    timelineWindow.showBossIcons = true

    local modes = NSI.BossDisplayModes
    local function BossModeLabel(mode)
        if not mode then return T("No abilities") end
        if mode == modes.IMPORTANT_TANK then return T("Important for tanks") end
        if mode == modes.SHOW_ALL then return T("All abilities") end
        if mode == modes.COMBINED then return T("All in one row") end
        if mode == modes.COMBINED_IMPORTANT then return T("Important in one row") end
        return T("Important for healers")
    end
    -- Show all (SHOW_ALL) and Hide all (off) sit above these in the menu.
    local BOSS_MODE_ORDER = {modes.IMPORTANT_HEALER, modes.IMPORTANT_TANK, modes.COMBINED, modes.COMBINED_IMPORTANT}

    -- Built with the header column's corner, further down.
    local bossPicker
    local BossMenuItems
    -- keepOpen items redraw the menu from a fresh item list, so check marks follow the change.
    local function Refreshed()
        self:RefreshTimelineForMode()
        return BossMenuItems()
    end
    local function AbilityItems(items)
        local filter = self:BossAbilityFilter()
        if not filter or #filter.choices == 0 then return end
        local encID = filter.encounterID
        local hidden = self:ReadHiddenBossAbilities(NSRT.TimelineWindowState, encID)
        local off = not timelineWindow.showBossAbilities
        items[#items + 1] = {type = "separator", label = T("Abilities")}
        for _, choice in ipairs(filter.choices) do
            local shown = not off and hidden[choice.key] ~= true
            local label = string.format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", tostring(choice.icon or "Interface\\ICONS\\INV_Misc_QuestionMark"),
                shown and choice.name or Colored(choice.name, STYLE.textDim))
            -- The empty texture keeps unchecked labels in line with checked ones.
            items[#items + 1] = {type = "button", label = label, icon = shown and STYLE.checkMark or "", keepOpen = true,
                fnc = function()
                    if off then
                        -- Ticking one ability while all are hidden turns abilities on with only that one.
                        local others = {}
                        for _, other in ipairs(filter.choices) do
                            if other.key ~= choice.key then others[#others + 1] = other.key end
                        end
                        self:SetBossAbilitiesHidden(encID, others, true)
                        self:SetBossAbilitiesHidden(encID, {choice.key}, false)
                        timelineWindow:SetBossMode(timelineWindow.bossDisplayMode)
                    else
                        self:SetBossAbilitiesHidden(encID, {choice.key}, shown)
                    end
                    return Refreshed()
                end}
        end
    end
    -- The check mark on the row of the mode in use; Hide all stands for abilities off.
    local function ModeMark(mode)
        local current = timelineWindow.showBossAbilities and timelineWindow.bossDisplayMode or false
        return current == mode and STYLE.checkMark or ""
    end
    -- Every choice in this menu keeps it open; only a click outside closes it.
    BossMenuItems = function()
        local items = {
            {type = "button", label = T("Show all"), icon = ModeMark(modes.SHOW_ALL), keepOpen = true, fnc = function()
                local filter = self:BossAbilityFilter()
                if filter then
                    local keys = {}
                    for key in pairs(self:ReadHiddenBossAbilities(NSRT.TimelineWindowState, filter.encounterID)) do
                        keys[#keys + 1] = key
                    end
                    self:SetBossAbilitiesHidden(filter.encounterID, keys, false)
                end
                timelineWindow:SetBossMode(modes.SHOW_ALL)
                return Refreshed()
            end},
            {type = "button", label = T("Hide all"), icon = ModeMark(false), keepOpen = true, fnc = function()
                timelineWindow:SetBossMode(false)
                return Refreshed()
            end},
            {type = "separator"},
        }
        for _, mode in ipairs(BOSS_MODE_ORDER) do
            items[#items + 1] = {type = "button", label = BossModeLabel(mode), icon = ModeMark(mode), keepOpen = true,
                fnc = function()
                    timelineWindow:SetBossMode(mode)
                    return Refreshed()
                end}
        end
        items[#items + 1] = {type = "separator"}
        items[#items + 1] = {type = "button", label = T("Show icons"), keepOpen = true,
            icon = timelineWindow.showBossIcons and STYLE.checkMark or "", fnc = function()
                timelineWindow.showBossIcons = not timelineWindow.showBossIcons
                return Refreshed()
            end}
        AbilityItems(items)
        return items
    end
    local function ShowBossModeMenu(btn)
        -- Opens beside the dropdown so the boss row headers stay visible while filtering.
        C.ShowContextMenuAtFrame(BossMenuItems(), btn.frame, STYLE.abilityMenuWidth, STYLE.noteMenuRows, nil, true)
    end

    -- The category, then "(N hidden)" while abilities are hidden; a long category is shortened, never the count.
    function timelineWindow:UpdateBossPickerText()
        if not bossPicker then return end
        local name = BossModeLabel(self.showBossAbilities and self.bossDisplayMode)
        local hidden = self.showBossAbilities and self.bossFilter and self.bossFilter.hiddenCount or 0
        if hidden == 0 then
            bossPicker:SetText(name)
            return
        end
        local suffix = string.format(T("(%d hidden)"), hidden)
        bossPicker:SetText(name .. " " .. suffix)
        -- MakeMenuButton insets the label 8 px left and 20 px right.
        local room = bossPicker.frame:GetWidth() - 28
        local cut = #name
        while bossPicker.label:GetStringWidth() > room and cut > 1 do
            cut = cut - 1
            -- Back off to a character boundary so a multibyte letter is never split.
            while cut > 1 and (name:byte(cut + 1) or 0) >= 128 and (name:byte(cut + 1) or 0) < 192 do cut = cut - 1 end
            bossPicker:SetText(name:sub(1, cut):gsub("%s+$", "") .. "... " .. suffix)
        end
    end

    -- mode false turns boss abilities off and keeps the last display mode.
    function timelineWindow:SetBossMode(mode)
        self.showBossAbilities = mode and true or false
        if mode then self.bossDisplayMode = mode end
        self:UpdateBossPickerText()
    end

    -- The Personal group (label, dropdown, arrows) is centred on the window, with the Load button hanging off its
    -- right end, clamped between the Shared controls (with their notice) and the right group (Undo, +10s, Play;
    -- anchored to the right edge at creation). When the bar is short the notice takes a shorter text, the
    -- Personal dropdown shrinks toward its minimum, then its label drops out. Only the warning may squeeze the
    -- Personal group for its longer texts.
    function timelineWindow:LayoutTopBar()
        local gap, group = STYLE.controlGap, STYLE.groupGap
        local personal = STYLE.personalWidth
        local width = self:GetWidth()
        local loadWidth = loadNoteButton.frame:IsShown() and gap + loadNoteButton:GetWidth() or 0
        local rightWidth = undoButton:GetWidth() + skipButton:GetWidth() + playButton:GetWidth() + 2 * gap
        local rightStart = width - STYLE.windowPad - rightWidth - group - loadWidth
        local arrowsWidth = 2 * (gap + STYLE.controlHeight)
        local labelWidth = personalLabel:GetStringWidth() + gap
        local leftEnd = STYLE.windowPad + sharedTitle:GetStringWidth() + gap + STYLE.sharedWidth + gap + STYLE.previewWidth
        local notice = self.sharedNoticeState
        local noticeWidth = 0
        if notice then
            local groupWidth = notice.urgent and personal.min + arrowsWidth or labelWidth + personal.max + arrowsWidth
            local limit = rightStart - groupWidth
            if not notice.urgent then limit = math.min(limit, (width - groupWidth) / 2) end
            for _, text in ipairs(notice.texts) do
                noticeWidth = notice.measure(text)
                if leftEnd + gap + noticeWidth + group <= limit then break end
            end
            leftEnd = leftEnd + gap + noticeWidth
        end
        leftEnd = leftEnd + group
        local available = rightStart - leftEnd - arrowsWidth
        personalLabel:SetShown(available - labelWidth >= personal.min)
        if not personalLabel:IsShown() then labelWidth = 0 end
        local personalWidth = math.floor(math.max(personal.min, math.min(personal.max, available - labelWidth)))

        local x = STYLE.windowPad
        local function Place(region, regionWidth, after)
            region:ClearAllPoints()
            region:SetPoint("LEFT", self, "TOPLEFT", x, barY)
            x = x + regionWidth + after
        end
        local function PlaceLabel(label)
            if label:IsShown() then Place(label, label:GetStringWidth(), gap) end
        end
        Place(sharedTitle, sharedTitle:GetStringWidth(), gap)
        Place(sharedMenu.frame, STYLE.sharedWidth, gap)
        Place(previewButton.frame, STYLE.previewWidth, notice and gap or group)
        if notice then Place(notice.frame, noticeWidth, group) end

        local groupWidth = labelWidth + personalWidth + arrowsWidth
        local latest = rightStart - groupWidth
        x = math.floor(math.max(x, math.min((width - groupWidth) / 2, latest)))
        PlaceLabel(personalLabel)
        personalPicker.frame:SetWidth(personalWidth)
        Place(personalPicker.frame, personalWidth, gap)
        Place(prevBoss.frame, STYLE.controlHeight, gap)
        Place(nextBoss.frame, STYLE.controlHeight, gap)
        Place(loadNoteButton.frame, loadNoteButton:GetWidth(), 0)
    end

    local canvasWidth, canvasHeight = TimelineCanvasSize(window_width, window_height)
    local timelineOptions = {
        width = canvasWidth,
        height = canvasHeight,
        header_width = STYLE.headerWidth,
        header_detached = true,
        line_height = STYLE.rowHeight,
        line_padding = 1,
        pixels_per_second = 15,
        scale_min = STYLE.minZoom,
        scale_max = 2.0,
        show_elapsed_timeline = true,
        elapsed_timeline_height = STYLE.rulerHeight,
        can_resize = false,
        use_perpixel_buttons = false,
        backdrop = {bgFile = [[Interface\Buttons\WHITE8X8]]},
        backdrop_color = STYLE.stripe,
        backdrop_color_highlight = STYLE.hover,
        backdrop_border_color = {0, 0, 0, 0},

        on_enter = function(line) PaintRow(line, true) end,
        on_leave = function(line) PaintRow(line, false) end,
        on_refresh_line = function(line) RefreshHeaderParts(line, timelineWindow.bossDisplayMode) end,
        on_create_line = CreateHeaderParts,

        block_on_enter = function(block)
            if timelineWindow.phaseDrag or (timelineWindow.press and timelineWindow.press.moved) then return end
            BlockTooltip(timelineWindow, block)
        end,
        block_on_leave = function()
            GameTooltip:Hide()
        end,

        block_on_set_data = function(block, data)
            if not block or not data then return end

            -- Blocks are pooled, so the hooks go on once and read the block's data at event time.
            if not block._timelineHooksInstalled then
                block._timelineHooksInstalled = true
                block:EnableMouse(true)
                block:HookScript("OnMouseDown", function(self, button)
                    NSI:TimelineBlockMouseDown(self, button)
                end)
                block:HookScript("OnMouseUp", function(self, button)
                    NSI:TimelineBlockMouseUp(self, button)
                end)
            end
            StyleBlock(block, data)
        end,
    }

    local elapsedTimeOptions = {
        backdrop = {bgFile = [[Interface\Buttons\WHITE8X8]]},
        backdrop_color = STYLE.ruler,
        text_color = STYLE.rulerText,
        text_size = STYLE.rulerTextSize,
        draw_line = false,
    }

    local timelineFrame = DF:CreateTimeLineFrame(timelineWindow, "$parentTimeLine", timelineOptions, elapsedTimeOptions)
    timelineWindow.timeline = timelineFrame
    timelineFrame:SetBackdropColor(unpack(STYLE.canvas))
    timelineFrame:SetBackdropBorderColor(unpack(STYLE.canvasBorder))
    local body = timelineFrame.body
    timelineFrame.gridLines = {}

    local elapsedTimeFrame = timelineFrame.elapsedTimeFrame
    if elapsedTimeFrame then
        elapsedTimeFrame.majorTicks = {}
        elapsedTimeFrame.minorTicks = {}
        local function Tick(pool, index, color, height)
            local tick = pool[index]
            if not tick then
                tick = elapsedTimeFrame:CreateTexture(nil, "ARTWORK")
                tick:SetWidth(1)
                pool[index] = tick
            end
            Paint(tick, color)
            tick:SetHeight(height)
            return tick
        end
        local function HideFrom(pool, first)
            for i = first, #pool do
                pool[i]:Hide()
            end
        end

        elapsedTimeFrame.Refresh = function(ruler, elapsedTime, scale)
            if not elapsedTime then return end
            ruler:SetHeight(STYLE.rulerHeight)
            local pps = (timelineFrame.options.pixels_per_second or 15) * (scale or 1)
            local major, minor = NSI:TimelineRulerStep(pps)
            local top = -(STYLE.rulerHeight + STYLE.phaseLaneHeight)

            local count = math.floor(elapsedTime / major) + 1
            for i = 1, count do
                local seconds = (i - 1) * major
                local x = seconds * pps
                local label = ruler:GetLabel(i)
                label:ClearAllPoints()
                label:SetPoint("LEFT", ruler, "LEFT", x + 3, 1)
                label:SetText(NSI:FormatTimelineClock(seconds))
                label:Show()

                local tick = Tick(ruler.majorTicks, i, STYLE.majorTick, STYLE.majorTickHeight)
                tick:ClearAllPoints()
                tick:SetPoint("BOTTOMLEFT", ruler, "BOTTOMLEFT", x, 0)
                tick:Show()

                local grid = timelineFrame.gridLines[i]
                if not grid then
                    grid = body:CreateTexture(nil, "BORDER")
                    grid:SetWidth(1)
                    timelineFrame.gridLines[i] = grid
                end
                Paint(grid, STYLE.gridLine)
                grid:ClearAllPoints()
                grid:SetPoint("TOPLEFT", body, "TOPLEFT", x, top)
                grid:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", x, 0)
                grid:Show()
            end
            for i = count + 1, #ruler.labels do
                ruler.labels[i]:Hide()
            end
            HideFrom(ruler.majorTicks, count + 1)
            HideFrom(timelineFrame.gridLines, count + 1)

            local minorCount = 0
            if minor then
                for i = 1, math.floor(elapsedTime / minor) do
                    local seconds = i * minor
                    if seconds % major ~= 0 then
                        minorCount = minorCount + 1
                        local tick = Tick(ruler.minorTicks, minorCount, STYLE.minorTick, STYLE.minorTickHeight)
                        tick:ClearAllPoints()
                        tick:SetPoint("BOTTOMLEFT", ruler, "BOTTOMLEFT", seconds * pps, 0)
                        tick:Show()
                    end
                end
            end
            HideFrom(ruler.minorTicks, minorCount + 1)
        end
    end

    -- Hover line on the canvas with its time on the ruler.
    local cursorLine = CreateCanvasLine(body, 150, STYLE.cursorLine, 1)
    timelineFrame.cursorLine = cursorLine

    local lastCursorSecond, lastPhaseStamp
    local function updateCursorLine()
        local strip = timelineFrame.rulerStrip
        local cursorChip = timelineFrame.cursorChip
        if not body:IsVisible() or not strip then
            cursorLine:Hide()
            if cursorChip then cursorChip:Hide() end
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        -- timelineWindow's own effective scale (its scale bar), not UIParent's.
        local uiScale = timelineWindow:GetEffectiveScale()
        cursorX = cursorX / uiScale
        cursorY = cursorY / uiScale

        local left, right = timelineFrame:GetLeft() or 0, timelineFrame:GetRight() or 0
        local top, bottom = timelineFrame:GetTop() or 0, timelineFrame:GetBottom() or 0
        if cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top then
            -- body is the scroll child, so its left edge already moves with the scroll.
            local x = cursorX - (body:GetLeft() or 0)
            local pps = (timelineFrame.options.pixels_per_second or 15) * (timelineFrame.currentScale or 1)
            local second = math.max(0, math.floor(x / pps))
            local press = timelineWindow.press
            local dropLabel = press and press.moved and press.dropLabel
            if dropLabel then
                -- A drop rounds to the nearest second, so a drag shows the landing time, not the floored one.
                if dropLabel ~= lastCursorSecond then
                    lastCursorSecond = dropLabel
                    SetChipText(cursorChip, dropLabel)
                end
            elseif second ~= lastCursorSecond or lastPhaseStamp ~= timelineWindow.phaseStamp then
                lastCursorSecond, lastPhaseStamp = second, timelineWindow.phaseStamp
                local phase, start = CachedPhaseAt(timelineWindow, second)
                SetChipText(cursorChip, NSI:FormatMoveLabel(phase, second - start, second))
            end
            PlaceCanvasLine(cursorLine, body, x)
            PlaceRulerChip(cursorChip, strip, x)
            cursorLine:Show()
            cursorChip:Show()
        else
            cursorLine:Hide()
            cursorChip:Hide()
        end
    end

    timelineFrame.body:EnableMouse(true)
    timelineFrame.body:SetScript("OnLeave", function()
        cursorLine:Hide()
        if timelineFrame.cursorChip then timelineFrame.cursorChip:Hide() end
        lastCursorSecond = nil
    end)

    local previewLine = CreateCanvasLine(body, 200, STYLE.previewLine, 2)
    timelineFrame.previewLine = previewLine

    -- Right-click drag pans both axes, like grabbing the canvas.
    local isDraggingTimeline = false
    local dragStartMouseX = 0
    local dragStartMouseY = 0
    local dragStartScroll = 0
    local dragStartVerticalScroll = 0
    local rightClickStartRawX = 0
    local rightClickStartRawY = 0

    local function startRightDrag()
        -- A right-click while the left button is held cancels a move instead of panning.
        if timelineWindow.press or IsMouseButtonDown("LeftButton") then
            NSI:CancelTimelineDrag()
            return
        end
        isDraggingTimeline = true
        local uiScale = 1 / timelineWindow:GetEffectiveScale()
        local rawX, rawY = GetCursorPosition()
        dragStartMouseX = rawX * uiScale
        dragStartMouseY = rawY * uiScale
        dragStartScroll = timelineFrame.horizontalSlider and timelineFrame.horizontalSlider:GetValue() or 0
        dragStartVerticalScroll = timelineFrame.verticalSlider and timelineFrame.verticalSlider:GetValue() or 0
        rightClickStartRawX, rightClickStartRawY = rawX, rawY
    end

    local function stopRightDrag()
        if not isDraggingTimeline then return end
        isDraggingTimeline = false
        local curRawX, curRawY = GetCursorPosition()
        local dx = curRawX - rightClickStartRawX
        local dy = curRawY - rightClickStartRawY
        rightClickStartRawX, rightClickStartRawY = 0, 0
        if math.sqrt(dx * dx + dy * dy) < 4 then
            local uiScale = 1 / timelineWindow:GetEffectiveScale()
            local cursorX = curRawX * uiScale
            -- body is the scroll child, so its left edge already moves with the scroll.
            local mouseXInBody = cursorX - (timelineFrame.body:GetLeft() or 0)
            local pps = (timelineFrame.options.pixels_per_second or 15) * (timelineFrame.currentScale or 1)
            local absoluteTime = math.max(0, mouseXInBody / pps)
            local items = {}
            local lineData
            local overRuler = timelineFrame.rulerContainer and timelineFrame.rulerContainer:IsMouseOver()
            for _, lineFrame in ipairs(not overRuler and timelineFrame:GetAllLines() or {}) do
                if lineFrame:IsShown() and lineFrame:IsMouseOver() then
                    lineData = lineFrame.lineData
                    break
                end
            end
            local cast = lineData and lineData.isBossAbility and NSI:BossCastAt(lineData.timeline, absoluteTime)
            local boss = ShownBoss(timelineWindow)
            if cast then
                items[1] = NSI:BossCastMenuItem(cast, lineData, boss)
            end
            items[#items + 1] = {type = "button", label = T("Add Reminder"), fnc = function()
                NSI:ShowReminderDialog(timelineWindow, absoluteTime, nil, nil, boss)
            end}
            NSI.UI.Components.ShowContextMenu(items)
        end
    end

    timelineFrame:EnableMouse(true)
    timelineFrame:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then startRightDrag() end
    end)
    timelineFrame:HookScript("OnMouseUp", function(self, button)
        if button == "RightButton" then stopRightDrag() end
    end)

    timelineFrame.body:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then startRightDrag() end
    end)
    timelineFrame.body:HookScript("OnMouseUp", function(self, button)
        if button == "RightButton" then stopRightDrag() end
    end)
    -- Phase lines sit over the canvas but only take the left button; they hand right presses here.
    timelineWindow.CanvasRightDown = startRightDrag
    timelineWindow.CanvasRightUp = stopRightDrag

    -- Ghost icon while moving a reminder; the cursor line and chip show where it lands.
    local dragGhostIcon = body:CreateTexture(nil, "OVERLAY")
    dragGhostIcon:SetSize(STYLE.blockIconSize, STYLE.blockIconSize)
    dragGhostIcon:SetAlpha(STYLE.dragIconAlpha)
    dragGhostIcon:Hide()
    timelineFrame.dragGhostIcon = dragGhostIcon

    -- Use OnUpdate for smooth cursor tracking and preview line animation
    local lastNowSecond, lastNowPhase, nowLineBroken, autoScrolling, UpdateNowLine
    local function HideNowLine()
        if previewLine:IsShown() then previewLine:Hide() end
        local chip = timelineFrame.previewChip
        if chip and chip:IsShown() then chip:Hide() end
        lastNowSecond, lastNowPhase = nil, nil
    end

    local function KeepNowLineInView(x)
        local slider = timelineFrame.horizontalSlider
        if not slider then return end
        -- The canvas must not move under a held reminder or phase marker; the idle time starts at the release.
        if timelineWindow.press or timelineWindow.phaseDrag then
            timelineWindow.lastManualScroll = GetTime()
            return
        end
        if GetTime() - (timelineWindow.lastManualScroll or 0) < STYLE.nowLineIdle then return end
        local target = NSI:NowLineScrollTarget(x, slider:GetValue(), timelineFrame:GetWidth() or 0, STYLE.scrollToMargin)
        if not target then return end
        autoScrolling = true
        slider:SetValue(ClampToSlider(slider, target))
        autoScrolling = false
    end

    -- One line and ruler chip for the fight clock during a pull and for the preview.
    UpdateNowLine = function()
        local time, phase, phaseStart
        local encID = NSI.EncounterID
        if encID then
            if encID == timelineWindow.currentEncounterID and NSI.PhaseSwapTime then
                phase = NSI.Phase
                time, phaseStart = NSI:LiveTimelineTime(encID, phase, timelineWindow.currentDifficulty, GetTime() - NSI.PhaseSwapTime)
            end
        elseif timelineWindow.previewActive and timelineWindow.previewStartTime then
            time = GetTime() - timelineWindow.previewStartTime
            if time >= ((timelineFrame.data and timelineFrame.data.length) or 300) then
                NSI:StopTimelinePreview()
                time = nil
            end
        end
        if not time then
            HideNowLine()
            return
        end
        local x = time * (timelineFrame.options.pixels_per_second or 15) * (timelineFrame.currentScale or 1)
        if x > (body:GetWidth() or 0) then
            HideNowLine()
            return
        end
        PlaceCanvasLine(previewLine, body, x)
        previewLine:Show()
        local chip = timelineFrame.previewChip
        if chip then
            local second = math.floor(time)
            if second ~= lastNowSecond or phase ~= lastNowPhase then
                lastNowSecond, lastNowPhase = second, phase
                SetChipText(chip, phase and NSI:FormatMoveLabel(phase, math.floor(time - phaseStart), second)
                    or NSI:FormatTimelineClock(second))
            end
            PlaceRulerChip(chip, timelineFrame.rulerStrip, x)
            chip:Show()
        end
        KeepNowLineInView(x)
    end

    local updateThrottle = 0
    local lastOwnedByPull
    timelineFrame.body:SetScript("OnUpdate", function(self, elapsed)
        -- Zoom steps set this; re-packing here runs once per frame however many steps came in.
        if timelineWindow.compactRepack and not timelineWindow.press then
            timelineWindow.compactRepack = nil
            xpcall(RepackCompactRows, geterrorhandler(), NSI, timelineWindow)
        end
        updateThrottle = updateThrottle + elapsed
        if updateThrottle >= 0.016 then  -- ~60fps
            updateThrottle = 0
            -- The release can land on another frame, or none, so OnMouseUp may never come.
            if isDraggingTimeline and not IsMouseButtonDown("RightButton") then
                isDraggingTimeline = false
            end
            if isDraggingTimeline then
                local uiScale = 1 / timelineWindow:GetEffectiveScale()
                local currentMouseX, currentMouseY = GetCursorPosition()
                currentMouseX = currentMouseX * uiScale
                currentMouseY = currentMouseY * uiScale
                if timelineFrame.horizontalSlider then
                    local delta = dragStartMouseX - currentMouseX
                    local hMin, hMax = timelineFrame.horizontalSlider:GetMinMaxValues()
                    timelineFrame.horizontalSlider:SetValue(math.max(hMin, math.min(hMax, dragStartScroll + delta)))
                end
                if timelineFrame.verticalSlider then
                    -- Content follows the cursor: dragging up reveals lower rows.
                    local deltaY = currentMouseY - dragStartMouseY
                    local vMin, vMax = timelineFrame.verticalSlider:GetMinMaxValues()
                    timelineFrame.verticalSlider:SetValue(math.max(vMin, math.min(vMax, dragStartVerticalScroll + deltaY)))
                end
            end
            if self:IsMouseOver() or timelineFrame.cursorChip and timelineFrame.cursorChip:IsShown() then
                updateCursorLine()
            end
            NSI:UpdateTimelineDrag()
            NSI:UpdatePhaseDrag()
            local ownedByPull = NSI:RemindersOwnedByPull()
            if timelineWindow.previewActive and ownedByPull then
                -- The pull owns the reminder frames now; only drop the preview state.
                NSI:StopTimelinePreview(true)
            end
            -- The play button greys out while a pull owns the reminder frames.
            if ownedByPull ~= lastOwnedByPull then
                lastOwnedByPull = ownedByPull
                xpcall(function() NSI:UpdateTimelineControls() end, geterrorhandler())
            end
            if not nowLineBroken and not xpcall(UpdateNowLine, geterrorhandler()) then
                nowLineBroken = true
                HideNowLine()
            end
        end
    end)

    -- Setup zoom-to-cursor and sticky ruler hooks
    self:SetupTimelineHooks(timelineFrame)
    -- The sticky ruler blocks rows scrolled under it; the wheel is left unhandled so it still reaches the zoom.
    local rulerContainer = timelineFrame.rulerContainer
    if rulerContainer then
        rulerContainer:EnableMouse(true)
        rulerContainer:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" then startRightDrag() end
        end)
        rulerContainer:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" then stopRightDrag() end
        end)
    end
    if timelineFrame.horizontalSlider then
        timelineFrame.horizontalSlider:HookScript("OnValueChanged", function()
            if not autoScrolling then timelineWindow.lastManualScroll = GetTime() end
        end)
    end
    timelineWindow:HookScript("OnShow", function()
        nowLineBroken = nil
        timelineWindow.lastManualScroll = nil
    end)
    timelineWindow:HookScript("OnHide", HideNowLine)

    local strip = timelineFrame.rulerStrip
    if strip then
        timelineFrame.cursorChip = CreateRulerChip(strip, STYLE.cursorChip, STYLE.cursorChipText, STYLE.rulerChipHeight, STYLE.rulerChipTextSize)
        timelineFrame.previewChip = CreateRulerChip(strip, STYLE.previewChip, STYLE.previewChipText, STYLE.rulerChipHeight, STYLE.rulerChipTextSize)
    end

    -- Position the detached header (sticky first column) and timeline
    local headerFrame = timelineFrame.headerFrame
    local corner
    if headerFrame then
        headerFrame:SetPoint("TOPLEFT", timelineWindow, "TOPLEFT", STYLE.windowPad, -STYLE.canvasTop)
        headerFrame:SetHeight(canvasHeight)
        timelineFrame:SetPoint("TOPLEFT", headerFrame, "TOPRIGHT", 0, 0)

        local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
        headerBg:SetAllPoints()
        Paint(headerBg, STYLE.headerBg)

        -- Covers the header rows that scroll up behind the ruler and phase lane.
        corner = CreateFrame("Frame", nil, headerFrame)
        corner:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
        corner:SetPoint("TOPRIGHT", headerFrame, "TOPRIGHT", 0, 0)
        corner:SetHeight(STYLE.rulerHeight + STYLE.phaseLaneHeight)
        corner:SetFrameLevel((timelineFrame.headerBody or headerFrame):GetFrameLevel() + 50)
        corner:EnableMouse(true)
        local cornerRuler = corner:CreateTexture(nil, "BACKGROUND")
        cornerRuler:SetPoint("TOPLEFT", corner, "TOPLEFT", 0, 0)
        cornerRuler:SetPoint("TOPRIGHT", corner, "TOPRIGHT", 0, 0)
        cornerRuler:SetHeight(STYLE.rulerHeight)
        Paint(cornerRuler, STYLE.ruler)
        local cornerLane = corner:CreateTexture(nil, "BACKGROUND")
        cornerLane:SetPoint("BOTTOMLEFT", corner, "BOTTOMLEFT", 0, 0)
        cornerLane:SetPoint("BOTTOMRIGHT", corner, "BOTTOMRIGHT", 0, 0)
        cornerLane:SetHeight(STYLE.phaseLaneHeight)
        Paint(cornerLane, STYLE.headerBg)
        local cornerRule = corner:CreateTexture(nil, "BORDER")
        cornerRule:SetPoint("BOTTOMLEFT", corner, "BOTTOMLEFT", 0, 0)
        cornerRule:SetPoint("BOTTOMRIGHT", corner, "BOTTOMRIGHT", 0, 0)
        cornerRule:SetHeight(1)
        Paint(cornerRule, STYLE.phaseLaneBorder)

        -- The "Boss abilities" heading, in the phase lane's header cell.
        local bossHeading = NewFontString(corner, STYLE.sectionTextSize, STYLE.sectionText)
        bossHeading:SetPoint("LEFT", corner, "BOTTOMLEFT", STYLE.headerIconX, STYLE.phaseLaneHeight / 2)
        bossHeading:SetText(T("Boss abilities"):upper())
        bossHeading:Hide()
        function timelineWindow:SetBossHeading(shown)
            bossHeading:SetShown(shown and true or false)
        end
    else
        timelineFrame:SetPoint("TOPLEFT", timelineWindow, "TOPLEFT", STYLE.windowPad, -STYLE.canvasTop)
    end

    -- Over the header column's ruler-height corner, which stays put while the rows scroll.
    local pickerParent = corner or timelineFrame
    bossPicker = C.CreateButton(pickerParent, BossModeLabel(defaultBossMode), ShowBossModeMenu, STYLE.headerWidth,
        STYLE.rulerHeight, nil, nil, STYLE.bossPickerTextSize)
    bossPicker:SetPoint("TOPLEFT", pickerParent, "TOPLEFT", 0, 0)
    MakeMenuButton(bossPicker)
    timelineWindow.bossPicker = bossPicker

    -- Placed on the filter row by PlaceRowFilters; above the row headers' own mouse handlers.
    local filterParent = timelineFrame.headerBody or headerFrame or timelineFrame
    local rowFilters = CreateFrame("Frame", nil, filterParent)
    rowFilters:SetFrameLevel(filterParent:GetFrameLevel() + 20)
    rowFilters:SetHeight(STYLE.filterButtonHeight)
    rowFilters:Hide()
    local function Segment(text, onClick, tooltip)
        return C.CreateButton(rowFilters, text, onClick, nil, STYLE.filterButtonHeight, nil, nil,
            STYLE.filterButtonTextSize, tooltip)
    end
    local function SetShowMine(mine)
        if (timelineWindow.showMine and true or false) == mine then return end
        timelineWindow.showMine = mine
        self:RefreshTimelineForMode()
    end
    local function SetCompactRows(compact)
        if (timelineWindow.compactRows and true or false) == compact then return end
        timelineWindow.compactRows = compact
        self:RefreshTimelineForMode()
    end
    local showEveryone = Segment(T("All"), function() SetShowMine(false) end)
    local showMine = Segment(T("Mine"), function() SetShowMine(true) end, T("Only reminders that fire for you"))
    local rowsButton = Segment(T("Rows"), function() SetCompactRows(false) end,
        {title = T("Rows"), desc = T("One row per player and spell.")})
    local compactButton = Segment(T("Compact"), function() SetCompactRows(true) end,
        {title = T("Compact rows"), desc = T("One row per player. Reminders that would overlap move to an extra row.")})
    local segments = {showEveryone, showMine, rowsButton, compactButton}
    local textWidths, totalText = {}, 0
    for i, segment in ipairs(segments) do
        textWidths[i] = math.ceil(segment.label:GetStringWidth())
        totalText = totalText + textWidths[i]
    end
    -- Both pairs fit the header column; the side padding shrinks for longer translations.
    local available = STYLE.headerWidth - 2 * STYLE.filterRowPad - STYLE.filterPairGap - 2 * STYLE.filterSegmentDivider
    local pad = math.max(2, math.min(STYLE.filterSegmentPad, math.floor((available - totalText) / (2 * #segments))))
    local x = 0
    for i, segment in ipairs(segments) do
        if i > 1 then x = x + (i == 3 and STYLE.filterPairGap or STYLE.filterSegmentDivider) end
        segment:SetSize(textWidths[i] + 2 * pad, STYLE.filterButtonHeight)
        segment.labelFrame:ClearAllPoints()
        segment.labelFrame:SetPoint("TOPLEFT", segment.frame, "TOPLEFT", pad, 0)
        segment.labelFrame:SetPoint("BOTTOMRIGHT", segment.frame, "BOTTOMRIGHT", -pad, 0)
        segment:SetPoint("LEFT", rowFilters, "LEFT", x, 0)
        x = x + segment:GetWidth()
    end
    rowFilters:SetWidth(x)
    timelineWindow.showEveryone = showEveryone
    timelineWindow.showMineButton = showMine
    timelineWindow.rowsButton = rowsButton
    timelineWindow.compactButton = compactButton

    -- Zoom lives on the mouse wheel; the slider stays as the zoom state FitTimelineScale clamps.
    if timelineFrame.scaleSlider then
        timelineFrame.scaleSlider:Hide()
        timelineFrame.scaleSlider:HookScript("OnValueChanged", function(slider)
            -- The library steps the scale up to 0.01; at the fitted minimum use the exact fit instead.
            local sliderMin = slider:GetMinMaxValues()
            if slider:GetValue() <= sliderMin and timelineFrame.currentScale ~= sliderMin then
                timelineFrame.currentScale = sliderMin
                timelineFrame:RefreshTimeLine()
            end
            NSI:UpdatePhaseMarkers()
            NSI:SaveTimelineWindowState()
        end)
    end

    local horizontalSlider, verticalSlider = timelineFrame.horizontalSlider, timelineFrame.verticalSlider
    if horizontalSlider then
        horizontalSlider:ClearAllPoints()
        horizontalSlider:SetPoint("TOPLEFT", timelineFrame, "BOTTOMLEFT", 0, -STYLE.scrollBarGap)
        horizontalSlider:SetPoint("TOPRIGHT", timelineFrame, "BOTTOMRIGHT", 0, -STYLE.scrollBarGap)
        horizontalSlider:SetHeight(STYLE.scrollBarSize)
        StyleScrollBar(horizontalSlider, T("Scroll through the fight. Mouse wheel zooms."))
    end
    if verticalSlider then
        verticalSlider:ClearAllPoints()
        verticalSlider:SetPoint("TOPLEFT", timelineFrame, "TOPRIGHT", STYLE.scrollBarGap, 0)
        verticalSlider:SetPoint("BOTTOMLEFT", timelineFrame, "BOTTOMRIGHT", STYLE.scrollBarGap, 0)
        verticalSlider:SetWidth(STYLE.scrollBarSize)
        StyleScrollBar(verticalSlider, T("Scroll through the rows. Ctrl + mouse wheel also scrolls."))
    end
    hooksecurefunc(timelineFrame, "RefreshTimeLine", function()
        UpdateScrollThumbs(timelineFrame)
        PlaceRowFilters(timelineFrame, rowFilters)
        local compact = timelineFrame.data and timelineFrame.data.compact
        if timelineWindow.compactRows and compact and CompactIconSeconds(timelineFrame) ~= compact.width then
            timelineWindow.compactRepack = true
        end
    end)

    local emptyState = CreateFrame("Frame", nil, timelineWindow)
    emptyState:SetFrameLevel(timelineFrame:GetFrameLevel() + 400)
    emptyState:SetPoint("CENTER", timelineFrame, "CENTER", 0, -(STYLE.rulerHeight + STYLE.phaseLaneHeight) / 2)
    emptyState:EnableMouse(false)
    local emptyBg = emptyState:CreateTexture(nil, "BACKGROUND")
    emptyBg:SetAllPoints()
    Paint(emptyBg, STYLE.emptyBg)
    local emptyText = NewFontString(emptyState, STYLE.emptyTextSize, STYLE.labelText)
    emptyText:SetWordWrap(true)
    emptyText:SetJustifyH("CENTER")
    emptyText:SetWidth(STYLE.emptyWidth)
    emptyText:SetPoint("CENTER", emptyState, "CENTER", 0, 0)
    emptyState:Hide()

    function timelineWindow:SetEmptyText(text)
        if not text then
            emptyState:Hide()
            return
        end
        emptyText:SetText(text)
        emptyState:SetSize(STYLE.emptyWidth + 24, emptyText:GetStringHeight() + 18)
        emptyState:Show()
    end

    local fitButton = C.CreateButton(timelineWindow, T("Fit"), function()
        self:FitTimelineView()
    end, nil, STYLE.footerButtonHeight, nil, nil, STYLE.helpTextSize + 1, T("Zoom out to show the whole fight"))
    fitButton:SetPoint("BOTTOMLEFT", timelineWindow, "BOTTOMLEFT", STYLE.windowPad, STYLE.footerY - 3)
    timelineWindow.fitButton = fitButton

    local helpLabel = NewFontString(timelineWindow, STYLE.helpTextSize, STYLE.helpText)
    helpLabel:SetText(T("Scroll: zoom | Ctrl+scroll: vertical | Right-drag: pan | Right-click: add | Drag a reminder to move it"))
    helpLabel:SetPoint("LEFT", fitButton.frame, "RIGHT", STYLE.controlGap, 0)

    local statusText = NewFontString(timelineWindow, STYLE.statusTextSize, STYLE.statusInfo)
    statusText:SetJustifyH("RIGHT")
    timelineWindow.statusText = statusText

    -- A status takes the help line's place, so long messages get the full footer width.
    local function ShowStatusText(text)
        local shown = text and text ~= ""
        statusText:SetText(text or "")
        statusText:ClearAllPoints()
        statusText:SetPoint("BOTTOMRIGHT", timelineWindow, "BOTTOMRIGHT", -24, STYLE.footerY)
        statusText:SetPoint("BOTTOMLEFT", helpLabel, shown and "BOTTOMLEFT" or "BOTTOMRIGHT", shown and 0 or 20, 0)
        helpLabel:SetShown(not shown)
    end
    ShowStatusText(nil)

    local STATUS_COLORS = {info = STYLE.statusInfo, success = STYLE.success, error = STYLE.danger}
    local statusTimer
    -- kind: "info", "success" or "error". Clears itself after a few seconds.
    function timelineWindow:SetStatus(text, kind)
        if statusTimer then
            statusTimer:Cancel()
            statusTimer = nil
        end
        Tint(statusText, STATUS_COLORS[kind] or STATUS_COLORS.info)
        ShowStatusText(text)
        if text and text ~= "" then
            statusTimer = C_Timer.NewTimer(8, function()
                statusTimer = nil
                ShowStatusText(nil)
            end)
        end
    end

    timelineWindow:HookScript("OnHide", function()
        legend:Hide()
        NSI:SaveTimelineWindowState()
        isDraggingTimeline = false
        NSI:CancelTimelineDrag()
        NSI:StopTimelinePreview()
        if timelineWindow.phaseDrag then
            timelineWindow.phaseDrag = nil
            NSI:UpdatePhaseMarkers()
        end
    end)
    -- A pull or another preview took over the reminder frames; only the preview state needs resetting.
    NSI.RegisterCallback("NSRT_TimelinePreview", "NSRT_STOP_PREVIEWS", function()
        NSI:StopTimelinePreview(true)
    end)
    -- Anything else that clears the reminder frames (a pull timer, an options test) also ends the preview.
    hooksecurefunc(NSI, "HideAllReminders", function()
        if timelineWindow.previewSkipping then return end
        xpcall(function() NSI:StopTimelinePreview(true) end, geterrorhandler())
    end)

    -- Handle window resize to update timeline dimensions
    local resizeTimer = nil
    timelineWindow:SetScript("OnSizeChanged", function(self, width, height)
        local newWidth, newHeight = TimelineCanvasSize(width, height)
        timelineFrame:SetSize(newWidth, newHeight)
        timelineFrame.body:SetSize(newWidth, newHeight)
        if headerFrame then
            headerFrame:SetHeight(newHeight)
        end
        timelineWindow:LayoutTopBar()

        -- Debounce the refresh - only refresh after resizing stops
        if resizeTimer then
            resizeTimer:Cancel()
        end
        resizeTimer = C_Timer.NewTimer(0.1, function()
            NSI:RefreshTimelineForMode()
            resizeTimer = nil
        end)
    end)

    local saved = self:ReadTimelineWindowState(NSRT.TimelineWindowState,
        {personal = NSRT.PersonalReminders, shared = NSRT.Reminders}, self.BossTimelines)
    if saved.width and saved.height then timelineWindow:SetSize(saved.width, saved.height) end
    if saved.left then
        timelineWindow:ClearAllPoints()
        timelineWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.left, saved.top)
    end
    timelineWindow.savedBoss = saved.boss
    timelineWindow.lastPersonal = saved.lastPersonal
    if saved.showMine ~= nil then timelineWindow.showMine = saved.showMine end
    timelineWindow.compactRows = saved.compactRows or false
    timelineWindow.showBossIcons = saved.showBossIcons ~= false
    if saved.bossMode ~= nil then timelineWindow:SetBossMode(saved.bossMode) end
    for key, scale in pairs(saved.zoom) do
        timelineWindow.viewStates[key] = {scale = scale, h = 0, v = 0}
    end
    timelineWindow:LayoutTopBar()

    timelineWindow:Hide()
    return timelineWindow
end

function NSI:ToggleTimelineWindow()
    if not NSI.UI.Components and not self:LoadUI() then return end
    if not self.TimelineWindow then
        self.TimelineWindow = self:CreateTimelineWindow()
    end

    if self.TimelineWindow:IsShown() then
        self.TimelineWindow:Hide()
    else
        self.TimelineWindow:Show()
        self:ResetTimelineToLoadedNotes()
        if not self.ProcessedReminder then
            self:ProcessReminder() -- also calls RefreshTimelineForMode at its end
        else
            self:RefreshTimelineForMode()
        end
    end
end

-- The "View in Timeline" buttons: shows the note's first boss. A personal note is loaded (guarded); a stored
-- shared note that isn't the loaded one is shown view only. An unknown name just opens the window.
function NSI:ViewNoteInTimeline(name, personal)
    if not NSI.UI.Components and not self:LoadUI() then return end
    if not self.TimelineWindow then
        self.TimelineWindow = self:CreateTimelineWindow()
    end
    local window = self.TimelineWindow
    if not window:IsShown() then
        window:Show()
        self:ResetTimelineToLoadedNotes()
    end
    local source = personal and NSRT.PersonalReminders or NSRT.Reminders
    local text = name and name ~= "" and source[name]
    local encID, difficulty = self:NoteFirstBoss(text)
    if encID then
        local dialog = self.ReminderDialogPopup
        if dialog and dialog:IsShown() then dialog:Hide() end
        window.boss = self:TimelineBoss(encID, difficulty or (window.boss and window.boss.difficulty))
        if window.sharedView and not self:NoteHasBossSection(NSRT.Reminders[window.sharedView], encID) then
            window.sharedView = nil
        end
    end
    if text and not personal then
        if encID then
            window.sharedView = not self:IsTimelineNoteLoaded({name = name, personal = false}) and name or nil
        else
            window:SetStatus(T("That note has no boss section, so there is nothing to show."), "error")
        end
    end
    if text and personal and name ~= self.LoadedPersonalReminder and self:LoadTimelinePersonalNote(name, encID) then
        return
    end
    if not self.ProcessedReminder then
        self:ProcessReminder()
    else
        self:RefreshTimelineForMode()
    end
end

function NSI:GetTimelineEncounterLabel(encID)
    return T(self.BossNames[encID]) or (T("Encounter") .. " " .. encID)
end

-- Whether note is the one the runtime uses for its kind. A shared note only counts while
-- the processed text is still its saved text, so a note received from the raid never does.
function NSI:IsTimelineNoteLoaded(note)
    if not note then return false end
    if note.personal then
        return self.LoadedPersonalReminder == note.name and NSRT.PersonalReminders[note.name] ~= nil
    end
    local text = NSRT.Reminders[note.name]
    return text ~= nil and NSRT.ActiveReminder == note.name and self.Reminder == text
end

-- Whether a note text has a section for encID.
function NSI:NoteHasBossSection(text, encID)
    if type(text) ~= "string" or not encID then return false end
    for id in text:gmatch("EncounterID:(%d+)") do
        if tonumber(id) == encID then return true end
    end
    return false
end

-- encID and header Difficulty of a note text's first boss section, or nil.
function NSI:NoteFirstBoss(text)
    if type(text) ~= "string" then return nil end
    local header = text:match("[^\r\n]*EncounterID:%d+[^\r\n]*")
    if not header then return nil end
    return tonumber(header:match("EncounterID:(%d+)")), NoteHeaderValue(header, "Difficulty")
end

-- Name and text of the shared note the runtime uses, or nil when none is loaded. A note received from the
-- raid that isn't the stored note of NSRT.ActiveReminder goes by its header's Name.
function NSI:ActiveSharedNote()
    local text = self.Reminder
    if type(text) ~= "string" or text == "" then return nil end
    local active = NSRT.ActiveReminder
    if active and NSRT.Reminders[active] == text then return active, text end
    local header = text:match("[^\r\n]*EncounterID:%d+[^\r\n]*")
    return header and NoteHeaderValue(header, "Name") or active or T("Received note"), text
end

-- Names of the personal notes with a section for encID, sorted.
function NSI:PersonalNotesForBoss(encID)
    local names = {}
    for name, text in pairs(NSRT.PersonalReminders) do
        if self:NoteHasBossSection(text, encID) then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

-- The loaded personal note when it has a section for encID: the timeline's editable layer.
function NSI:ShownPersonalNote(encID)
    local name = self.LoadedPersonalReminder
    if name and self:NoteHasBossSection(NSRT.PersonalReminders[name], encID) then return name end
end

-- The personal note to load for encID: the one the core loads on a pull of it, then the one last used for it
-- on the timeline, then the first by name. nil when none has a section for it.
function NSI:PreferredPersonalNote(encID, lastUsed)
    local candidates = {self:GetPersonalReminderForEncounter(encID) or false, lastUsed and lastUsed[encID] or false}
    for _, name in ipairs(candidates) do
        if name and self:NoteHasBossSection(NSRT.PersonalReminders[name], encID) then return name end
    end
    return self:PersonalNotesForBoss(encID)[1]
end

-- The personal note a boss switch (SetTimelineBoss) shows for encID: the one the core loads on a pull of it, else
-- the one last used for it here, else the loaded note when it has a section for encID. nil shows none.
function NSI:StepPersonalNote(encID, lastUsed)
    local mapped = self:GetPersonalReminderForEncounter(encID)
    if mapped then return mapped end
    local last = lastUsed and lastUsed[encID]
    if last and self:NoteHasBossSection(NSRT.PersonalReminders[last], encID) then return last end
    return self:ShownPersonalNote(encID)
end

-- {encID, difficulty} with the difficulty resolved to one the boss data has, or nil without encID.
function NSI:TimelineBoss(encID, difficulty)
    if not encID then return nil end
    difficulty = difficulty or self:GetCurrentDifficultyName()
    if self.BossTimelines and self.BossTimelines[encID] then
        local _, resolved = self:GetBossTimeline(encID, difficulty)
        difficulty = resolved or difficulty
    end
    return {encID = encID, difficulty = difficulty}
end

-- The boss the window opens on: the loaded shared note's first boss, else the loaded personal note's,
-- else last (the boss viewed last), else the first boss of the current season.
function NSI:TimelineOpenBoss(last)
    local _, sharedText = self:ActiveSharedNote()
    local encID, difficulty = self:NoteFirstBoss(sharedText)
    if not encID then encID, difficulty = self:NoteFirstBoss(self.PersonalReminder) end
    if not encID and last then encID, difficulty = last.encID, last.difficulty end
    if not encID then
        local bosses = self:BrowsableBosses()
        for _, boss in ipairs(bosses) do
            if self.CurrentEncounterIDs and self.CurrentEncounterIDs[boss.encID] then
                encID = boss.encID
                break
            end
        end
        encID = encID or (bosses[1] and bosses[1].encID)
    end
    return self:TimelineBoss(encID, difficulty)
end

-- Header Difficulty of a note text's section for encID, or nil.
local function NoteSectionDifficulty(text, encID)
    if type(text) ~= "string" then return nil end
    for header in text:gmatch("[^\r\n]*EncounterID:%d+[^\r\n]*") do
        if tonumber(header:match("EncounterID:(%d+)")) == encID then return NoteHeaderValue(header, "Difficulty") end
    end
    return nil
end

-- {encID, difficulty} of the loaded shared note's first boss when it has no section for encID, else nil.
local function SharedNoteElsewhere(self, encID)
    local _, text = self:ActiveSharedNote()
    if not text or self:NoteHasBossSection(text, encID) then return nil end
    return self:TimelineBoss(self:NoteFirstBoss(text))
end

-- What the Shared notice says, as one decision so the display, the warning and its click agree:
-- "previewMismatch" (a preview while the loaded personal note is for another boss; personalBoss = its boss),
-- "preview", "elsewhere" (the loaded shared note is for another boss; boss = its boss), or nil.
local function SharedNoticeState(self, window)
    local encID = window.boss and window.boss.encID
    local pick = window.sharedView
    if pick and encID then
        local personalText = self.LoadedPersonalReminder and NSRT.PersonalReminders[self.LoadedPersonalReminder]
        local personalBoss = personalText and not self:NoteHasBossSection(personalText, encID)
            and self:TimelineBoss(self:NoteFirstBoss(personalText))
        if personalBoss then return {kind = "previewMismatch", pick = pick, personalBoss = personalBoss} end
        return {kind = "preview", pick = pick}
    end
    local elsewhere = SharedNoteElsewhere(self, encID)
    if elsewhere then return {kind = "elsewhere", boss = elsewhere} end
end

local function InlineIcon(texture, size, tint)
    if not tint then return string.format("|T%s:%d:%d|t", tostring(texture), size, size) end
    return string.format("|T%s:%d:%d:0:0:64:64:0:64:0:64:%d:%d:%d|t", tostring(texture), size, size,
        math.floor(tint[1] * 255 + 0.5), math.floor(tint[2] * 255 + 0.5), math.floor(tint[3] * 255 + 0.5))
end

-- The boss icon the Personal menu shows, then the difficulty when there is one.
local function BossBadge(encID, difficulty, tint)
    local icons = NSI.UI and NSI.UI.BossData and NSI.UI.BossData.BossIcons
    local badge = InlineIcon(icons and icons[encID] or "Interface\\ICONS\\INV_Misc_QuestionMark", STYLE.barIconSize, tint)
    return difficulty and (badge .. " " .. T(difficulty)) or badge
end

function NSI:UpdateTimelineControls()
    local window = self.TimelineWindow
    if not window or not window.personalPicker then return end
    local boss = window.boss
    local encID = boss and boss.encID

    local activeName, activeText = self:ActiveSharedNote()
    local pick = window.sharedView
    local elsewhere = SharedNoteElsewhere(self, encID)
    local sharedMenu = window.sharedMenu
    sharedMenu.menuArrow:SetShown(elsewhere ~= nil or pick ~= nil)
    local info = {name = activeName}
    if not activeText then
        sharedMenu:SetText(T("none"))
        info.hint = T("No shared note is loaded. Use Preview to view a stored one.")
    elseif elsewhere then
        sharedMenu:SetText(BossBadge(elsewhere.encID, elsewhere.difficulty))
        info.hint = string.format(T("This note is for %s (%s). None of its reminders show on the boss you are viewing."),
            self:GetTimelineEncounterLabel(elsewhere.encID), T(elsewhere.difficulty))
    elseif self:NoteHasBossSection(activeText, encID) then
        sharedMenu:SetText(BossBadge(encID, NoteSectionDifficulty(activeText, encID)))
        info.hint = T("The shared note loaded now. Its reminders are read-only here.")
    else
        sharedMenu:SetText(activeName)
        info.hint = T("This note has no boss section, so none of its reminders show here.")
    end
    local state = SharedNoticeState(self, window)
    local warn = InlineIcon([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\triangle-alert.png]], 12, STYLE.warningText)
    if state and state.kind == "previewMismatch" then
        local other = state.personalBoss
        local otherName = self:GetTimelineEncounterLabel(other.encID)
        info.viewing = string.format(T("Viewing %s. It is not loaded and will not fire on a pull."), pick)
        info.mismatch = string.format(T("Your personal note %s is for %s."), self.LoadedPersonalReminder, otherName)
        info.action = string.format(T("Click to stop the preview and show %s."), otherName)
        window:SetSharedNotice({
            warn .. " " .. string.format(T("Previewing %s. Personal note is for %s"),
                BossBadge(encID) .. " " .. self:GetTimelineEncounterLabel(encID), BossBadge(other.encID) .. " " .. otherName),
            warn .. " " .. string.format(T("Previewing %s, personal note %s"), BossBadge(encID), BossBadge(other.encID)),
            warn .. " " .. string.format(T("Personal: %s"), BossBadge(other.encID)),
        }, true)
    elseif state and state.kind == "preview" then
        local c = STYLE.viewOnlyText
        local eye = InlineIcon([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\eye.png]], 12, c) .. " "
        local short = eye .. string.format(T("viewing %s"), BossBadge(encID, NoteSectionDifficulty(NSRT.Reminders[pick], encID), c))
        info.viewing = string.format(T("Viewing %s. It is not loaded and will not fire on a pull."), pick)
        window:SetSharedNotice({short .. "  " .. pick, short, eye .. string.format(T("viewing %s"), BossBadge(encID, nil, c))}, false)
    elseif state and state.kind == "elsewhere" then
        local bossName = self:GetTimelineEncounterLabel(state.boss.encID)
        info.action = string.format(T("Click to show %s."), bossName)
        window:SetSharedNotice({
            warn .. " " .. string.format(T("Shared note is for %s"), BossBadge(state.boss.encID) .. " " .. bossName),
            warn .. " " .. BossBadge(state.boss.encID) .. " " .. T("other boss"),
            warn .. " " .. T("other boss"),
        }, true)
    else
        window:SetSharedNotice(nil)
    end
    window.sharedInfo = info
    local previewText = pick and STYLE.accent or STYLE.text
    window.previewButton:SetTextColor(previewText[1], previewText[2], previewText[3], previewText[4])

    local personal = encID and self:ShownPersonalNote(encID)
    local bossNotes = encID and self:PersonalNotesForBoss(encID) or {}
    local picker = window.personalPicker
    local bossName = encID and self:GetTimelineEncounterLabel(encID) or ""
    local difficultyName = boss and T(boss.difficulty) or ""
    if personal then
        picker:SetText(BossBadge(encID) .. " " .. personal)
    elseif encID then
        picker:SetText(BossBadge(encID) .. " " .. string.format(#bossNotes > 0 and T("%s - %s (not loaded)")
            or T("%s - %s (no note)"), bossName, difficultyName))
    else
        picker:SetText("")
    end
    local pickerColor = personal and STYLE.text or STYLE.textDim
    picker:SetTextColor(pickerColor[1], pickerColor[2], pickerColor[3], pickerColor[4] or 1)
    picker.tooltip.title = bossName
    picker.tooltip.desc = difficultyName .. (personal and "\n" .. string.format(T("%s (loaded)"), personal) or "")
        .. "\n" .. T("Right-click a note in the list to rename or delete it.")
    for delta, arrow in pairs({[-1] = window.prevBoss, [1] = window.nextBoss}) do
        if encID and self:AdjacentTimelineBoss(encID, delta) then arrow:Enable() else arrow:Disable() end
    end

    local loadNote = window.loadNoteButton
    local loadShown = encID ~= nil and not personal
    local loadTarget = loadShown and #bossNotes > 0 and self:PreferredPersonalNote(encID, window.lastPersonal)
    if loadTarget then
        loadNote:SetText(T("Load my personal note"))
        loadNote.tooltip.title = T("Load my personal note")
        loadNote.tooltip.desc = loadTarget .. (#bossNotes > 1 and "\n" .. T("Pick another from the Personal dropdown.") or "")
    elseif loadShown then
        loadNote:SetText(T("Create my personal note"))
        loadNote.tooltip.title = T("Create my personal note")
        loadNote.tooltip.desc = T("Creates an empty personal note for this boss and loads it.")
    end
    if loadNote.frame:IsShown() ~= loadShown then
        loadNote.frame:SetShown(loadShown)
        window:LayoutTopBar()
    end

    if window.showMine then
        window.showMineButton:Select()
        window.showEveryone:Deselect()
    else
        window.showEveryone:Select()
        window.showMineButton:Deselect()
    end
    if window.compactRows then
        window.compactButton:Select()
        window.rowsButton:Deselect()
    else
        window.rowsButton:Select()
        window.compactButton:Deselect()
    end
    if window.previewActive or not self:RemindersOwnedByPull() then
        window.playButton:Enable()
    else
        window.playButton:Disable()
    end
    window:SetPreviewButtonState(window.previewActive)
    if #self.TimelineUndoStack > 0 then window.undoButton:Enable() else window.undoButton:Disable() end
end

local function QuantiseScale(scale)
    return math.floor(scale * 100 + 0.5) / 100
end

-- The scale slider owns currentScale; this mirrors its step so a refresh only happens on a real change.
-- The slider ceils to 0.01, so setting the scale it already has would creep it up a step.
-- The slider's minimum is the exact fit, kept unstepped so the fight ends on the canvas's right edge.
local function SetTimelineScale(timeline, scale)
    local slider = timeline.scaleSlider
    local step = scale
    if slider then
        local sliderMin = slider:GetMinMaxValues()
        local wanted = scale <= sliderMin and sliderMin or QuantiseScale(ClampToSlider(slider, scale))
        if timeline.currentScale and QuantiseScale(timeline.currentScale) == wanted then return end
        slider:SetValue(wanted)
        local value = slider:GetValue()
        step = value <= sliderMin and sliderMin or math.ceil(value * 100) / 100
    end
    if timeline.currentScale ~= step then
        timeline.currentScale = step
        timeline:RefreshTimeLine()
    end
end

-- Scale at which the whole fight fills the canvas width; also the slider's minimum.
-- Rounded up, so the content is at most a pixel wider than the canvas, never short of it.
local function FitTimelineScale(timeline, dataLength)
    local options = timeline.options
    local scaleMin, scaleMax = options.scale_min or STYLE.minZoom, options.scale_max or 2
    local duration = math.max(dataLength or 300, 1)
    local fit = math.ceil((timeline:GetWidth() or 880) / (duration * (options.pixels_per_second or 15)) * 10000) / 10000
    fit = math.max(scaleMin, math.min(scaleMax, fit))
    if timeline.scaleSlider then
        timeline.scaleSlider:SetMinMaxValues(fit, scaleMax)
    end
    return fit
end

local function CaptureTimelineView(timeline)
    return {
        scale = timeline.currentScale,
        h = timeline.horizontalSlider and timeline.horizontalSlider:GetValue() or 0,
        v = timeline.verticalSlider and timeline.verticalSlider:GetValue() or 0,
    }
end

local function RestoreTimelineView(timeline, view)
    SetTimelineScale(timeline, view.scale)
    if timeline.horizontalSlider then
        timeline.horizontalSlider:SetValue(ClampToSlider(timeline.horizontalSlider, view.h))
    end
    if timeline.verticalSlider then
        timeline.verticalSlider:SetValue(ClampToSlider(timeline.verticalSlider, view.v))
    end
end

-- Keeps zoom and scroll per view; a boss or note shown for the first time is fitted.
local function ApplyTimelineData(self, window, data, viewKey)
    local timeline = window.timeline
    local previousKey = window.viewKey
    local view
    if previousKey == viewKey then
        view = CaptureTimelineView(timeline)
    else
        if previousKey then
            window.viewStates[previousKey] = CaptureTimelineView(timeline)
            self:StopTimelinePreview()
        end
        view = window.viewStates[viewKey]
    end
    window.viewKey = viewKey
    timeline:SetData(data)
    local fit = FitTimelineScale(timeline, data.length)
    if view then
        RestoreTimelineView(timeline, view)
    else
        RestoreTimelineView(timeline, {scale = fit, h = 0, v = 0})
    end
end

-- Zooms out to the whole fight and scrolls to the pull.
function NSI:FitTimelineView()
    local timeline = self.TimelineWindow and self.TimelineWindow.timeline
    if not timeline or not timeline.data then return end
    RestoreTimelineView(timeline, {
        scale = FitTimelineScale(timeline, timeline.data.length),
        h = 0,
        v = timeline.verticalSlider and timeline.verticalSlider:GetValue() or 0,
    })
end

-- Remembers size, position, view, filters and per-view zoom in NSRT.TimelineWindowState.
function NSI:SaveTimelineWindowState()
    local window = self.TimelineWindow
    if not window then return end
    if type(NSRT.TimelineWindowState) ~= "table" then NSRT.TimelineWindowState = {} end
    local state = NSRT.TimelineWindowState
    state.width, state.height = window:GetWidth(), window:GetHeight()
    local left, top = window:GetLeft(), window:GetTop()
    if left and top then state.left, state.top = left, top end
    state.view, state.noteName, state.notePersonal, state.browseEncID, state.browseDifficulty = nil, nil, nil, nil, nil
    local boss = window.boss
    state.bossEncID = boss and boss.encID or nil
    state.bossDifficulty = boss and boss.difficulty or nil
    local lastPersonal = {}
    for encID, name in pairs(window.lastPersonal or {}) do
        if NSRT.PersonalReminders[name] then lastPersonal[encID] = name end
    end
    state.lastPersonal = lastPersonal
    state.showMine = window.showMine and true or false
    state.compactRows = window.compactRows and true or false
    state.showBossIcons = window.showBossIcons ~= false
    state.bossMode = window.showBossAbilities and window.bossDisplayMode or "off"
    local zoom = {}
    for key, view in pairs(window.viewStates or {}) do
        zoom[key] = view.scale
    end
    if window.viewKey and window.timeline and window.timeline.currentScale then
        zoom[window.viewKey] = window.timeline.currentScale
    end
    for key in pairs(zoom) do
        if not key:match("^b:") then zoom[key] = nil end
    end
    state.zoom = zoom
end

-- One boss's hidden abilities from a TimelineWindowState ({[abilityKey] = true}); empty when absent or malformed.
function NSI:ReadHiddenBossAbilities(state, encID)
    local all = type(state) == "table" and state.hiddenAbilities
    local set = type(all) == "table" and encID ~= nil and all[encID]
    return type(set) == "table" and set or {}
end

-- Hides or shows abilities of a boss in NSRT.TimelineWindowState.hiddenAbilities[encID].
function NSI:SetBossAbilitiesHidden(encID, keys, hidden)
    if encID == nil then return end
    if type(NSRT.TimelineWindowState) ~= "table" then NSRT.TimelineWindowState = {} end
    local state = NSRT.TimelineWindowState
    if type(state.hiddenAbilities) ~= "table" then state.hiddenAbilities = {} end
    local set = state.hiddenAbilities[encID]
    if type(set) ~= "table" then
        set = {}
        state.hiddenAbilities[encID] = set
    end
    for _, key in ipairs(keys) do
        set[key] = hidden and true or nil
    end
    if next(set) == nil then state.hiddenAbilities[encID] = nil end
end

-- The shown boss's ability filter ({encounterID, choices, hiddenCount}); built for the last display mode while
-- abilities are off, so the menu can still list them. nil when there is no boss.
function NSI:BossAbilityFilter()
    local window = self.TimelineWindow
    if not window then return nil end
    if window.bossFilter then return window.bossFilter end
    local boss = window.boss
    if window.showBossAbilities or not boss then return nil end
    local _, _, _, _, filter = self:GetBossAbilityLines(boss.encID, window.bossDisplayMode, boss.difficulty)
    return filter
end

-- Scrolls so time sits just right of the canvas's left edge.
function NSI:ScrollTimelineToTime(time)
    local timeline = self.TimelineWindow and self.TimelineWindow.timeline
    local slider = timeline and timeline.horizontalSlider
    if not slider then return end
    local pps = (timeline.options.pixels_per_second or 15) * (timeline.currentScale or 1)
    slider:SetValue(ClampToSlider(slider, time * pps - STYLE.scrollToMargin))
end

local reprocessingLive = false

-- What identifies the loaded shared note. The same text received again (every ready check and pull timer) is no change.
local function SharedNoteSignature(self)
    return {text = self.Reminder, name = NSRT.ActiveReminder}
end

local function SameSharedNote(a, b)
    return a.text == b.text and a.name == b.name
end

-- The loaded shared note's text or name changed since the last refresh: drop the view-only pick and, when the
-- new note has no section for the boss on screen, show its first boss unless the reminder dialog is open or a
-- drag is in progress.
local function FollowSharedNoteChange(self, window)
    local seen = SharedNoteSignature(self)
    local before = window.sharedSeen
    window.sharedSeen = seen
    if not before or SameSharedNote(before, seen) then return end
    local name, text = self:ActiveSharedNote()
    if not text then return end
    window.sharedView = nil
    local dialog = self.ReminderDialogPopup
    local busy = (dialog and dialog:IsShown()) or window.press or window.phaseDrag
    local encID, difficulty = self:NoteFirstBoss(text)
    local covered = window.boss and self:NoteHasBossSection(text, window.boss.encID)
    if not busy and encID and not covered then
        window.boss = self:TimelineBoss(encID, difficulty or (window.boss and window.boss.difficulty))
    end
    if window.boss and self:NoteHasBossSection(text, window.boss.encID) then
        window:SetStatus(string.format(T("Now showing shared note: %s"), name), "info")
    end
end

local function RefreshTimeline(self)
    local window = self.TimelineWindow
    if not window or not window.timeline then return end

    -- A wipe or kill clears ProcessedReminder, which the preview plays; ProcessReminder rebuilds it and
    -- refreshes the window itself.
    if not self.ProcessedReminder and not self.EncounterID and not reprocessingLive then
        reprocessingLive = true
        local ok = xpcall(function() self:ProcessReminder() end, geterrorhandler())
        reprocessingLive = false
        if ok then return end
    end

    FollowSharedNoteChange(self, window)
    window.boss = window.boss or self:TimelineOpenBoss(window.savedBoss)
    local boss = window.boss
    if not boss then
        window:SetEmptyText(T("No boss data available."))
        self:UpdateTimelineControls()
        return
    end
    local encID, difficulty = boss.encID, boss.difficulty
    local pick = window.sharedView
    if pick and (not NSRT.Reminders[pick] or self:IsTimelineNoteLoaded({name = pick, personal = false})) then
        pick = nil
        window.sharedView = nil
    end

    local layers = {}
    if pick then
        layers[1] = {text = NSRT.Reminders[pick], layer = "view"}
    else
        local _, sharedText = self:ActiveSharedNote()
        layers[1] = {text = sharedText, layer = "shared"}
    end
    local personal = self:ShownPersonalNote(encID)
    if personal then
        layers[2] = {text = NSRT.PersonalReminders[personal], layer = "personal", note = {name = personal, personal = true}}
    end

    local bossDisplayMode = window.bossDisplayMode or self.BossDisplayModes.SHOW_ALL
    local ownContext = self:GetPlayerTagContext()
    local mine = window.showMine and ownContext or nil
    local options = {filterRow = true, compactWidth = window.compactRows and CompactIconSeconds(window.timeline) or nil}
    local data, phases = self:GetLayeredTimelineData(encID, difficulty, layers, window.showBossAbilities, bossDisplayMode,
        mine, ownContext, options)
    local viewKey = "b:" .. tostring(encID) .. "@" .. tostring(difficulty)
    local emptyText
    if mine and data.reminderLines == 0 then
        emptyText = T("No reminders on screen are for you. Click All to see the rest.")
    elseif data.reminderLines == 0 then
        emptyText = T("No reminders for this boss yet. Right-click the timeline to add one.")
    end

    window:SetEmptyText(emptyText)
    window.timeline:Show()
    window.currentEncounterID = encID
    window.bossFilter = data.bossFilter
    if window.SetBossHeading then window:SetBossHeading(data.bossHeading) end
    if window.UpdateBossPickerText then window:UpdateBossPickerText() end
    window.currentPhases = phases
    window.currentDifficulty = difficulty
    ApplyTimelineData(self, window, data, viewKey)
    window.compactRepack = nil
    RepackCompactRows(self, window)
    self:UpdatePhaseMarkers()
    self:UpdateTimelineTitle()
    self:UpdateTimelineControls()
    self:SaveTimelineWindowState()
end

-- Runs from ProcessReminder, so an error here must not abort the caller (an encounter start, a pull timer).
function NSI:RefreshTimelineForMode()
    if not self.TimelineWindow then return end
    xpcall(function() RefreshTimeline(self) end, geterrorhandler())
end

-- Applies the open rule and drops a view-only pick; the loaded shared note as of now counts as seen.
function NSI:ResetTimelineToLoadedNotes()
    local window = self.TimelineWindow
    if not window then return end
    window.boss = self:TimelineOpenBoss(window.boss or window.savedBoss)
    window.sharedView = nil
    window.sharedSeen = SharedNoteSignature(self)
end

-- Error text when the personal note on screen can't be switched now, else nil.
function NSI:PersonalSwitchBlocked()
    if self:RemindersOwnedByPull() then return T("Can't change the loaded note during an encounter.") end
end

-- Maps personal note name to encID the way SetReminder maps a note's first boss, so LoadPersReminder loads it
-- for a pull of encID.
local function MapPersonalNoteToBoss(self, name, encID)
    if encID and self:NoteHasBossSection(NSRT.PersonalReminders[name], encID) then
        self:GetActivePersonalReminders(NSRT.PersonalReminderSpecs[name])[encID] = name
    end
end

-- Loads personal note name (the options' Load) and maps it to encID in the core's per-boss table, so a pull of
-- that boss keeps it. Refused over unsaved editor text, which SyncNoteEditor would replace.
function NSI:LoadTimelinePersonalNote(name, encID)
    local window = self.TimelineWindow
    if not NSRT.PersonalReminders[name] then
        window:SetStatus(T("That note no longer exists."), "error")
        return false
    end
    local blocked = self:TimelineWriteBlocked({name = name, personal = true}, true)
    if blocked then
        window:SetStatus(blocked, "error")
        return false
    end
    if encID then window.lastPersonal[encID] = name end
    -- Reprocessing refreshes the window.
    self:SetReminder(name, true)
    MapPersonalNoteToBoss(self, name, encID)
    self:SyncNoteEditor({name = name, personal = true}, name, true)
    window:SetStatus(string.format(T("Loaded %s."), name), "success")
    return true
end

-- Unloads the loaded personal note (the options' Unload); refused like a load.
function NSI:UnloadTimelinePersonalNote()
    local window = self.TimelineWindow
    local name = self.LoadedPersonalReminder
    if not name then return false end
    local blocked = self:TimelineWriteBlocked({name = name, personal = true}, true)
    if blocked then
        window:SetStatus(blocked, "error")
        return false
    end
    -- Reprocessing refreshes the window.
    self:SetReminder(nil, true)
    self:SyncNoteEditor({name = name, personal = true}, nil, true)
    window:SetStatus(string.format(T("No personal note for this boss. Unloaded %s."), name), "info")
    return true
end

-- Shows boss ({encID, difficulty}), then loads personal note load or, with unload, unloads the loaded one; a
-- view-only pick with nothing for the boss is dropped. Returns whether load was loaded.
local function SwitchTimelineBoss(self, boss, load, unload)
    local window = self.TimelineWindow
    local dialog = self.ReminderDialogPopup
    if dialog and dialog:IsShown() then dialog:Hide() end
    window.boss = boss
    if window.sharedView and not self:NoteHasBossSection(NSRT.Reminders[window.sharedView], boss.encID) then
        window.sharedView = nil
    end
    local changed
    if load then
        changed = self:LoadTimelinePersonalNote(load, boss.encID)
    elseif unload then
        changed = self:UnloadTimelinePersonalNote()
    end
    if not changed then self:RefreshTimelineForMode() end
    return load ~= nil and changed
end

-- Shows another boss (the arrows, the Shared menu's jump). Refused during a pull. While personal notes are enabled
-- it loads StepPersonalNote's pick, or unloads the loaded note when there is none. dropPick ends a view-only pick.
function NSI:SetTimelineBoss(encID, difficulty, dropPick)
    local window = self.TimelineWindow
    local boss = window and self:TimelineBoss(encID, difficulty)
    if not boss then return end
    local blocked = self:PersonalSwitchBlocked()
    if blocked then
        window:SetStatus(blocked, "error")
        return
    end
    if dropPick then window.sharedView = nil end
    local load, unload
    if NSRT.ReminderSettings.PersNote then
        load = self:StepPersonalNote(boss.encID, window.lastPersonal)
        unload = not load and self.LoadedPersonalReminder ~= nil
        if load == self.LoadedPersonalReminder then load = nil end
    end
    SwitchTimelineBoss(self, boss, load, unload)
end

-- Shows a boss and difficulty with personal note name loaded (a note picked in the Personal menu). Refused
-- during a pull.
function NSI:ShowTimelinePersonalNote(encID, difficulty, name)
    local window = self.TimelineWindow
    local boss = window and self:TimelineBoss(encID, difficulty)
    if not boss then return end
    local blocked = self:PersonalSwitchBlocked()
    if blocked then
        window:SetStatus(blocked, "error")
        return
    end
    SwitchTimelineBoss(self, boss, name ~= self.LoadedPersonalReminder and name or nil)
end

-- Creates a personal note for a boss and difficulty, loads it and shows it. reuse takes an existing note made
-- for that boss and difficulty instead (GetOrCreatePersonalBossNote, as the first add does). Refused during a pull.
function NSI:CreateTimelinePersonalNote(encID, difficulty, reuse)
    local window = self.TimelineWindow
    local boss = window and self:TimelineBoss(encID, difficulty)
    if not boss then return end
    local blocked = self:PersonalSwitchBlocked()
    if blocked then
        window:SetStatus(blocked, "error")
        return
    end
    local note
    if reuse then
        note = self:GetOrCreatePersonalBossNote(boss.encID, boss.difficulty)
    else
        note = self:CreateNewPersonalBossNote(boss.encID, boss.difficulty)
    end
    if SwitchTimelineBoss(self, boss, note.name) then
        window:SetStatus(string.format(T("Created %s."), note.name), "success")
    end
end

-- The neighbouring boss in Personal menu order within the shown boss's season, or nil at the ends.
function NSI:AdjacentTimelineBoss(encID, delta)
    local current = self.CurrentEncounterIDs and self.CurrentEncounterIDs[encID] and true or false
    local list = {}
    for _, boss in ipairs(self:BrowsableBosses()) do
        local inCurrent = self.CurrentEncounterIDs and self.CurrentEncounterIDs[boss.encID] and true or false
        if inCurrent == current then list[#list + 1] = boss end
    end
    for i, boss in ipairs(list) do
        if boss.encID == encID then return list[i + delta] end
    end
end

-- Arrow step: keeps the difficulty when the next boss has it, else takes its first.
function NSI:StepTimelineBoss(delta)
    local window = self.TimelineWindow
    local boss = window and window.boss
    local nextBoss = boss and self:AdjacentTimelineBoss(boss.encID, delta)
    if not nextBoss then return end
    local difficulty = nextBoss.difficulties[1]
    for _, d in ipairs(nextBoss.difficulties) do
        if d == boss.difficulty then difficulty = d end
    end
    self:SetTimelineBoss(nextBoss.encID, difficulty)
end

local SEASON_HEADERS = {[3379] = "Season 2 (Midnight) ", [3176] = "Season 1 (Midnight) "}

-- Personal notes with a section for encID, keyed by the difficulty the boss data resolves their section's
-- Difficulty to (TimelineBoss). A note without one, or with one outside difficulties, goes under the default.
local function PersonalNotesByDifficulty(self, encID, difficulties)
    local known = {}
    for _, difficulty in ipairs(difficulties) do known[difficulty] = true end
    local default = self:TimelineBoss(encID).difficulty
    if not known[default] then default = difficulties[1] end
    local byDifficulty = {}
    for _, name in ipairs(self:PersonalNotesForBoss(encID)) do
        local difficulty = self:TimelineBoss(encID, NoteSectionDifficulty(NSRT.PersonalReminders[name], encID)).difficulty
        if not known[difficulty] then difficulty = default end
        byDifficulty[difficulty] = byDifficulty[difficulty] or {}
        table.insert(byDifficulty[difficulty], name)
    end
    return byDifficulty
end

-- Personal menu: every boss by season, muted when it has no personal note, highlighted when on screen. Its
-- flyout lists per difficulty the boss's notes (right-click to rename or delete) and "+ New note". A note
-- assigned to another spec is muted and names that spec: the core doesn't pick it for a pull on this spec.
function NSI:TimelinePersonalMenuItems()
    local window = self.TimelineWindow
    if not window then return {} end
    local shown = window.boss
    local loaded = self.LoadedPersonalReminder
    local mySpec = self:GetMySpecID()
    local icons = NSI.UI.BossData and NSI.UI.BossData.BossIcons
    local items = {}
    for _, boss in ipairs(self:BrowsableBosses()) do
        if SEASON_HEADERS[boss.encID] then
            items[#items + 1] = {type = "separator", label = T(SEASON_HEADERS[boss.encID])}
        end
        local encID = boss.encID
        local byDifficulty = PersonalNotesByDifficulty(self, encID, boss.difficulties)
        local sub, noteCount = {}, 0
        for i, difficulty in ipairs(boss.difficulties) do
            if i > 1 then sub[#sub + 1] = {type = "separator"} end
            sub[#sub + 1] = {type = "label", text = T(difficulty)}
            for _, name in ipairs(byDifficulty[difficulty] or {}) do
                noteCount = noteCount + 1
                local label = name == loaded and string.format(T("%s (loaded)"), name) or name
                local specID = NSRT.PersonalReminderSpecs[name]
                if specID and specID ~= mySpec then
                    local _, specName = GetSpecializationInfoByID(specID)
                    label = Colored(string.format(T("%s (%s only)"), label, specName or tostring(specID)), STYLE.textDim)
                end
                sub[#sub + 1] = {
                    type = "button",
                    label = label,
                    fnc = function() self:ShowTimelinePersonalNote(encID, difficulty, name) end,
                    contextItems = {
                        {type = "button", label = T("Rename"), fnc = function() self:ShowRenameNoteDialog(window, name) end},
                        {type = "button", label = T("Delete"), fnc = function() self:ShowDeleteNoteConfirm(window, name) end},
                    },
                }
            end
            sub[#sub + 1] = {type = "button", label = T("+ New note"), fnc = function()
                self:CreateTimelinePersonalNote(encID, difficulty)
            end}
        end
        local label = boss.label
        if shown and shown.encID == encID then
            label = Colored(label, STYLE.accent)
        elseif noteCount == 0 then
            label = Colored(label, STYLE.textDim)
        end
        items[#items + 1] = {type = "submenu", label = label, items = sub, icon = icons and icons[encID]}
    end
    return items
end

local function StopTimelinePreview(self)
    self.TimelineWindow.sharedView = nil
    self:RefreshTimelineForMode()
end

-- Shared display menu: a jump to the loaded shared note's boss when it is another one, and "Stop viewing"
-- during a preview. Empty otherwise.
function NSI:TimelineSharedMenuItems()
    local window = self.TimelineWindow
    local boss = window and window.boss
    if not boss then return {} end
    local items = {}
    local elsewhere = SharedNoteElsewhere(self, boss.encID)
    if elsewhere then
        items[#items + 1] = {type = "button",
            label = string.format(T("Show %s"), self:GetTimelineEncounterLabel(elsewhere.encID)),
            fnc = function() self:SetTimelineBoss(elsewhere.encID, elsewhere.difficulty, true) end}
    end
    if window.sharedView then
        items[#items + 1] = {type = "button", label = T("Stop viewing"), fnc = function() StopTimelinePreview(self) end}
    end
    return items
end

-- Shows stored shared note name view only: no note is loaded, unloaded, mapped, sent or saved. A note without a
-- section for the boss on screen switches the view to its first boss (refused during a pull); the loaded
-- personal note stays loaded. Picking the loaded shared note ends the preview.
function NSI:PreviewTimelineSharedNote(name)
    local window = self.TimelineWindow
    local text = window and NSRT.Reminders[name]
    if not text then return end
    if self:IsTimelineNoteLoaded({name = name, personal = false}) then
        StopTimelinePreview(self)
        return
    end
    if window.boss and self:NoteHasBossSection(text, window.boss.encID) then
        window.sharedView = name
        self:RefreshTimelineForMode()
        return
    end
    local boss = self:TimelineBoss(self:NoteFirstBoss(text))
    if not boss then return end
    local blocked = self:PersonalSwitchBlocked()
    if blocked then
        window:SetStatus(blocked, "error")
        return
    end
    window.sharedView = name
    SwitchTimelineBoss(self, boss)
end

-- The Shared warning's click: back to the personal note's boss during a mismatched preview, else to the
-- loaded shared note's boss.
function NSI:FollowSharedWarning()
    local window = self.TimelineWindow
    local state = window and SharedNoticeState(self, window)
    if not state then return end
    if state.kind == "previewMismatch" then
        local blocked = self:PersonalSwitchBlocked()
        if blocked then
            window:SetStatus(blocked, "error")
            return
        end
        window.sharedView = nil
        SwitchTimelineBoss(self, state.personalBoss)
    elseif state.kind == "elsewhere" then
        self:SetTimelineBoss(state.boss.encID, state.boss.difficulty, true)
    end
end

-- Who may load and send a shared note: the rule that gates the Shared Notes tab's Load & Send.
local function CanSendSharedNotes()
    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or NSRT.Settings["Debug"] or not IsInGroup()
end

-- Loads and sends stored shared note name as the Shared Notes tab's Load & Send does, refused during a pull and
-- over unsaved editor text. Ends a preview and shows the note's first boss when it has nothing for the boss on
-- screen; the personal note is untouched.
function NSI:LoadAndSendTimelineSharedNote(name)
    local window = self.TimelineWindow
    local text = NSRT.Reminders[name]
    if not text then
        window:SetStatus(T("That note no longer exists."), "error")
        return
    end
    if not CanSendSharedNotes() then
        window:SetStatus(T("Only the raid leader or an assist can load and send shared notes."), "error")
        return
    end
    local blocked = self:TimelineWriteBlocked({name = name, personal = false}, true)
    if blocked then
        window:SetStatus(blocked, "error")
        return
    end
    window.sharedView = nil
    if not (window.boss and self:NoteHasBossSection(text, window.boss.encID)) then
        local boss = self:TimelineBoss(self:NoteFirstBoss(text))
        if boss then
            local dialog = self.ReminderDialogPopup
            if dialog and dialog:IsShown() then dialog:Hide() end
            window.boss = boss
        end
    end
    -- Reprocessing refreshes the window.
    self:SetReminder(name)
    self:Broadcast("NSI_REM_SHARE", "RAID", self.Reminder, nil, true)
    self:SyncNoteEditor({name = name, personal = false}, name, true)
    window:SetStatus(string.format(IsInGroup() and T("Loaded and sent %s.") or T("Loaded %s."), name), "success")
end

-- Shared notes menu: every stored shared note, those for the boss on screen first, then the rest under their
-- first boss. A click previews; who may send also gets Preview and Load and send on right-click. Notes without
-- a boss section can't be previewed.
function NSI:TimelinePreviewMenuItems()
    local window = self.TimelineWindow
    if not window then return {} end
    local encID = window.boss and window.boss.encID
    local icons = NSI.UI.BossData and NSI.UI.BossData.BossIcons
    local canSend = CanSendSharedNotes()
    local onScreen, byBoss, noBoss = {}, {}, {}
    for name, text in pairs(NSRT.Reminders) do
        local first = self:NoteFirstBoss(text)
        if encID and self:NoteHasBossSection(text, encID) then
            onScreen[#onScreen + 1] = name
        elseif first then
            byBoss[first] = byBoss[first] or {}
            table.insert(byBoss[first], name)
        else
            noBoss[#noBoss + 1] = name
        end
    end
    local items = {
        {type = "label", text = canSend and T("Click to preview.") or T("Click to preview a shared note.")},
        {type = "label", text = canSend and T("Right-click to load and send.") or T("A preview is not loaded.")},
    }
    if window.sharedView then
        items[#items + 1] = {type = "button", label = T("Stop preview"), fnc = function() StopTimelinePreview(self) end}
    end
    local function LoadAndSendItem(name)
        return {type = "button", label = T("Load and send"), fnc = function() self:LoadAndSendTimelineSharedNote(name) end}
    end
    local function AddNotes(names, icon)
        table.sort(names)
        for _, name in ipairs(names) do
            local label = name
            if self:IsTimelineNoteLoaded({name = name, personal = false}) then
                label = string.format(T("%s (loaded)"), name)
            elseif name == window.sharedView then
                label = Colored(name, STYLE.accent)
            end
            local function Preview() self:PreviewTimelineSharedNote(name) end
            items[#items + 1] = {type = "button", label = label, icon = icon, fnc = Preview, contextItems = canSend and {
                {type = "button", label = T("Preview"), fnc = Preview},
                LoadAndSendItem(name),
            } or nil}
        end
    end
    if #onScreen > 0 then
        items[#items + 1] = {type = "separator"}
        AddNotes(onScreen, icons and icons[encID])
    end
    local order, seen = {}, {}
    for _, boss in ipairs(self:BrowsableBosses()) do
        if byBoss[boss.encID] then
            order[#order + 1] = boss.encID
            seen[boss.encID] = true
        end
    end
    local rest = {}
    for id in pairs(byBoss) do
        if not seen[id] then rest[#rest + 1] = id end
    end
    table.sort(rest)
    for _, id in ipairs(rest) do order[#order + 1] = id end
    for _, id in ipairs(order) do
        items[#items + 1] = {type = "separator"}
        items[#items + 1] = {type = "label", text = self:GetTimelineEncounterLabel(id)}
        AddNotes(byBoss[id], icons and icons[id])
    end
    if #noBoss > 0 then
        items[#items + 1] = {type = "separator"}
        items[#items + 1] = {type = "label", text = T("No boss section")}
        table.sort(noBoss)
        for _, name in ipairs(noBoss) do
            items[#items + 1] = canSend and {type = "button", label = Colored(name, STYLE.textDim),
                contextItems = {LoadAndSendItem(name)}} or {type = "label", text = name}
        end
    end
    if next(NSRT.Reminders) == nil then
        items[#items + 1] = {type = "separator"}
        items[#items + 1] = {type = "label", text = T("No stored shared notes")}
    end
    return items
end

function NSI:PersonalBossNoteName(encID, difficulty)
    return self:GetTimelineEncounterLabel(encID) .. " - " .. T(difficulty)
end

local function PersonalBossNoteHeader(self, encID, difficulty)
    return string.format("EncounterID:%d;Name:%s;Difficulty:%s\n", encID, self:GetTimelineEncounterLabel(encID), difficulty)
end

-- Name of an existing personal note whose header is for this boss and difficulty: the auto-named one
-- if it qualifies, else the first by name. nil when there is none.
local function FindPersonalBossNote(self, encID, difficulty)
    local function Matches(text)
        return tonumber(NoteHeaderValue(text, "EncounterID") or "") == encID and NoteHeaderValue(text, "Difficulty") == difficulty
    end
    local autoName = self:PersonalBossNoteName(encID, difficulty)
    if NSRT.PersonalReminders[autoName] and Matches(NSRT.PersonalReminders[autoName]) then return autoName end
    local best
    for name, text in pairs(NSRT.PersonalReminders) do
        if Matches(text) and (not best or name < best) then best = name end
    end
    return best
end

-- First unused of "<Boss> - Heroic", "<Boss> - Heroic 2", ..., like "+ Create Note" in the Personal Notes tab.
local function FreePersonalBossNoteName(self, encID, difficulty)
    local baseName = self:PersonalBossNoteName(encID, difficulty)
    local name = baseName
    local n = 2
    while NSRT.PersonalReminders[name] do
        name = baseName .. " " .. n
        n = n + 1
    end
    return name
end

-- The personal note for a boss and difficulty, created when missing. Never loads it.
-- Returns the note and whether it was created.
function NSI:GetOrCreatePersonalBossNote(encID, difficulty)
    difficulty = difficulty or self:GetCurrentDifficultyName()
    local existing = FindPersonalBossNote(self, encID, difficulty)
    if existing then return {name = existing, personal = true}, false end
    local name = FreePersonalBossNoteName(self, encID, difficulty)
    NSRT.PersonalReminders[name] = PersonalBossNoteHeader(self, encID, difficulty)
    return {name = name, personal = true}, true
end

function NSI:CreateNewPersonalBossNote(encID, difficulty)
    difficulty = difficulty or self:GetCurrentDifficultyName()
    local name = FreePersonalBossNoteName(self, encID, difficulty)
    NSRT.PersonalReminders[name] = PersonalBossNoteHeader(self, encID, difficulty)
    return {name = name, personal = true}
end

-- Where adds for encID go: the personal note shown, else the one PreferredPersonalNote picks, else a new one.
-- Returns the note, whether it must be created and whether it must be loaded.
function NSI:TimelineAddTarget(encID, difficulty)
    local shown = self:ShownPersonalNote(encID)
    if shown then return {name = shown, personal = true}, false, false end
    local window = self.TimelineWindow
    local preferred = self:PreferredPersonalNote(encID, window and window.lastPersonal)
    if preferred then return {name = preferred, personal = true}, false, true end
    return {name = FreePersonalBossNoteName(self, encID, difficulty), personal = true}, true, true
end

-- Adds line to the TimelineAddTarget note's section for encID, creating and loading the note as needed.
-- successText(name) is the status shown after the write.
function NSI:AddLineToPersonalNote(encID, difficulty, line, successText)
    local window = self.TimelineWindow
    local note, create, load = self:TimelineAddTarget(encID, difficulty)
    local blocked = self:TimelineWriteBlocked(note, true)
    if blocked then
        window:SetStatus(blocked, "error")
        return false
    end
    local created = false
    if create then note, created = self:GetOrCreatePersonalBossNote(encID, difficulty) end
    local written = self:CommitTimelineWrite(note, function()
        return self:AddTimelineNoteLine(note.name, true, line, encID)
    end, successText(note.name), created, load)
    if written and load then MapPersonalNoteToBoss(self, note.name, encID) end
    if written and window.lastPersonal then window.lastPersonal[encID] = note.name end
    return written
end

-- Runs write() on a personal note, reloads the note if it was loaded (or load is set) and reports the outcome.
-- created: write() goes to a note made for it, which the options list doesn't show yet. Shared notes are refused.
function NSI:CommitTimelineWrite(note, write, successText, created, load)
    local window = self.TimelineWindow
    if not note or not note.personal then
        window:SetStatus(T("Shared note reminders are read-only. Edit them from the Shared Notes tab."), "error")
        return false
    end
    local reloads = self:IsTimelineNoteLoaded(note) or load
    local blocked = self:TimelineWriteBlocked(note, reloads)
    if blocked then
        window:SetStatus(blocked, "error")
        return false
    end
    if not write() then
        window:SetStatus(T("That reminder or its note changed. Nothing was saved."), "error")
        self:RefreshTimelineForMode()
        return false
    end
    if reloads then
        -- Reprocessing refreshes the open window as well.
        self:SetReminder(note.name, true)
    else
        self:RefreshTimelineForMode()
    end
    self:SyncNoteEditor(note, note.name, created or load)
    window:SetStatus(successText, "success")
    return true
end

function NSI:UndoTimelineEdit()
    local window = self.TimelineWindow
    if not window then return end
    local entry = self:TimelineUndoPeek()
    local note = entry and {name = entry.name, personal = true}
    local wasLoaded = note and self:IsTimelineNoteLoaded(note)
    -- A stale entry is only dropped, which is safe at any time.
    local blocked = entry and NSRT.PersonalReminders[entry.name] == entry.after and self:TimelineWriteBlocked(note, wasLoaded)
    if blocked then
        window:SetStatus(blocked, "error")
        return
    end
    local restored = self:TimelineUndo()
    if not restored then
        window:SetStatus(T("Nothing to undo."), "info")
        self:UpdateTimelineControls()
        return
    end
    if restored.stale then
        window:SetStatus(T("Note changed elsewhere. Undo history cleared."), "error")
        self:UpdateTimelineControls()
        return
    end
    if wasLoaded then
        self:SetReminder(restored.name, true)
    else
        self:RefreshTimelineForMode()
    end
    self:SyncNoteEditor(note, note.name, false)
    window:SetStatus(string.format(T("Undid the last change to %s."), restored.name), "success")
end

local function ReminderDisplayName(payload, spellID)
    local info = spellID and C_Spell.GetSpellInfo(spellID)
    if info and info.name then return info.name end
    if payload and payload.text and payload.text ~= "" then return payload.text end
    return T("reminder")
end

-- A personal reminder is copied next to itself; a shared one into the personal note for boss ({encID, difficulty},
-- the boss on screen when the menu opened; defaults to the one on screen now).
function NSI:DuplicateTimelineReminder(blockData, boss)
    local window = self.TimelineWindow
    local payload = blockData and blockData.payload
    if not window or not payload or not payload.srcRaw then return end
    boss = boss or ShownBoss(window)
    local note = payload.srcNote
    local copy = self:DuplicateReminderLine(payload.srcRaw)
    local prePull = (self:NoteGetNumber(copy, "time", true) or 0) < 0
    if not note then
        if not boss.encID then return end
        self:AddLineToPersonalNote(boss.encID, boss.difficulty, copy, function(name)
            return string.format(prePull and T("Copied to %s. Click the copy to change its time.")
                or T("Copied to %s. Drag the copy to place it."), name)
        end)
        return
    end
    self:CommitTimelineWrite(note, function()
        return self:InsertNoteLine(note.name, note.personal, payload.srcLineIndex, payload.srcRaw, copy, boss.encID)
    end, prePull and T("Duplicated. Click the copy to change its time.") or T("Duplicated. Drag the copy to place it."))
end

-- encID: the boss the reminder was shown for (see LocateNoteLine).
function NSI:DeleteTimelineReminder(blockData, encID)
    local payload = blockData and blockData.payload
    if not payload or not payload.srcRaw or not payload.srcNote then return end
    local note = payload.srcNote
    self:CommitTimelineWrite(note, function()
        return self:DeleteNoteLine(note.name, note.personal, payload.srcLineIndex, payload.srcRaw, encID)
    end, string.format(T("Deleted %s from %s."), ReminderDisplayName(payload, blockData[5]), note.name))
end

-- "Add reminder here" for a boss cast: a reminder at the cast's start, named after it, for boss (ShownBoss).
function NSI:BossCastMenuItem(castData, lineData, boss)
    local window = self.TimelineWindow
    boss = boss or ShownBoss(window)
    local payload = castData.payload or {}
    local name = payload.abilityName or (lineData and not lineData.isCombined and lineData.text) or ""
    local castTime = tonumber(castData[1]) or 0
    return {type = "button", label = T("Add reminder here"), fnc = function()
        self:ShowReminderDialog(window, castTime, nil, {text = name, exactTime = true}, boss)
    end}
end

-- Edit/view and delete for a reminder, or adding at a boss cast; captures the block's data and the boss on
-- screen now, since blocks are pooled and a refresh can change the boss before the click.
function NSI:ShowTimelineBlockMenu(blockData)
    local window = self.TimelineWindow
    local payload = blockData and blockData.payload
    if not window or not payload then return end
    local boss = ShownBoss(window)
    if payload.isBossAbility then
        NSI.UI.Components.ShowContextMenu({self:BossCastMenuItem(blockData, nil, boss)})
        return
    end
    local editable = payload.srcRaw and payload.srcNote
    local items = {
        {type = "button", label = editable and T("Edit Reminder") or T("View Reminder"), fnc = function()
            self:ShowReminderDialog(window, nil, blockData, nil, boss)
        end},
    }
    if payload.srcRaw and not payload.srcNote then
        items[#items + 1] = {type = "button", label = T("Copy to my personal note"), fnc = function()
            self:DuplicateTimelineReminder(blockData, boss)
        end}
    elseif editable then
        items[#items + 1] = {type = "button", label = T("Duplicate"), fnc = function()
            self:DuplicateTimelineReminder(blockData, boss)
        end}
        items[#items + 1] = {type = "separator"}
        items[#items + 1] = {type = "button", label = T("Delete Reminder"), fnc = function()
            self:DeleteTimelineReminder(blockData, boss.encID)
        end}
    end
    NSI.UI.Components.ShowContextMenu(items)
end

local DRAG_THRESHOLD = 3

local function CursorTimeInBody(timeline)
    local body = timeline.body
    local cursorX = GetCursorPosition() / body:GetEffectiveScale()
    local pps = (timeline.options.pixels_per_second or 15) * (timeline.currentScale or 1)
    return (cursorX - (body:GetLeft() or 0)) / pps
end

local function HideDragGhost(window)
    local timeline = window.timeline
    if timeline and timeline.dragGhostIcon then
        timeline.dragGhostIcon:Hide()
    end
end

-- Where the pressed reminder would land: the time under the cursor, in whole seconds into its phase.
-- Returns newRaw, phase, relTime and absTime.
local function DragTarget(self, window, press)
    local payload = press.payload
    local encID, difficulty = press.boss.encID, payload.srcDifficulty
    local absTime = math.max(0, CursorTimeInBody(window.timeline))
    local _, phaseStart = self:MovedLinePhase(payload.srcRaw, encID, difficulty, absTime)
    local target = phaseStart + math.floor(absTime - phaseStart + 0.5)
    local newRaw, phase, relTime = self:ComputeMovedLine(payload.srcRaw, encID, difficulty, target)
    local start = encID and self:GetPhaseStart(encID, phase, difficulty) or 0
    return newRaw, phase, relTime, start + relTime
end

function NSI:TimelineBlockMouseDown(block, button)
    local window = self.TimelineWindow
    if not window then return end
    local blockData = block.blockData
    local payload = blockData and blockData.payload
    if button == "RightButton" then
        -- A right-click while the left button is held cancels a move instead of opening the menu.
        if window.press or IsMouseButtonDown("LeftButton") then
            self:CancelTimelineDrag()
            return
        end
        local x, y = GetCursorPosition()
        window.blockRightPress = {block = block, blockData = blockData, x = x, y = y}
        return
    end
    if button ~= "LeftButton" or not payload or payload.isBossAbility then return end
    local x, y = GetCursorPosition()
    window.press = {
        block = block, blockData = blockData, payload = payload,
        boss = ShownBoss(window),
        startX = x, startY = y,
        canMove = (payload.srcRaw and payload.srcNote and not payload.prePull) and true or false,
    }
end

function NSI:TimelineBlockMouseUp(block, button)
    local window = self.TimelineWindow
    if not window then return end
    if button == "LeftButton" then
        if window.press and window.press.block == block then
            self:FinishTimelinePress()
        end
    elseif button == "RightButton" then
        local rightPress = window.blockRightPress
        window.blockRightPress = nil
        if rightPress and rightPress.block == block then
            local x, y = GetCursorPosition()
            local dx, dy = x - rightPress.x, y - rightPress.y
            if dx * dx + dy * dy < 16 then
                self:ShowTimelineBlockMenu(rightPress.blockData)
            end
        end
    end
end

function NSI:CancelTimelineDrag()
    local window = self.TimelineWindow
    if not window then return end
    window.blockRightPress = nil
    local press = window.press
    if not press then return end
    window.press = nil
    HideDragGhost(window)
    if press.moved and press.canMove then
        window:SetStatus(T("Move cancelled."), "info")
    end
end

-- Release of a left press on a reminder: a click opens the dialog, a drag moves the reminder.
function NSI:FinishTimelinePress()
    local window = self.TimelineWindow
    local press = window and window.press
    if not press then return end
    window.press = nil
    HideDragGhost(window)
    if not press.moved then
        self:ShowReminderDialog(window, nil, press.blockData, nil, press.boss)
        return
    end
    local payload = press.payload
    if not press.canMove then
        if payload.readOnly then
            window:SetStatus(T("Shared note reminders are read-only. Right-click one to copy it into your personal note."), "error")
        elseif payload.prePull then
            window:SetStatus(T("Pre-pull reminders can't be dragged. Click one to change its time."), "error")
        end
        return
    end
    local newRaw, phase, relTime, absTime = DragTarget(self, window, press)
    if newRaw == payload.srcRaw then
        window:SetStatus(T("Reminder not moved."), "info")
        return
    end
    local note = payload.srcNote
    self:CommitTimelineWrite(note, function()
        return self:RewriteNoteLine(note.name, note.personal, payload.srcLineIndex, payload.srcRaw, newRaw, press.boss.encID)
    end, string.format(T("Moved %s to %s."), ReminderDisplayName(payload, press.blockData[5]), self:FormatMoveLabel(phase, relTime, absTime)))
end

-- Called every frame from the timeline body: tracks the pressed reminder and draws the ghost.
function NSI:UpdateTimelineDrag()
    local window = self.TimelineWindow
    local press = window and window.press
    if not press then return end
    if IsMouseButtonDown("RightButton") then
        self:CancelTimelineDrag()
        return
    end
    -- The block can be recycled under the cursor by a refresh, so its OnMouseUp may never come.
    if not IsMouseButtonDown("LeftButton") then
        self:FinishTimelinePress()
        return
    end
    if not press.moved then
        local x, y = GetCursorPosition()
        local dx, dy = x - press.startX, y - press.startY
        if dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD then return end
        press.moved = true
        GameTooltip:Hide()
    end
    if not press.canMove then return end

    local timeline = window.timeline
    local _, phase, relTime, absTime = DragTarget(self, window, press)
    if press.dropTime ~= absTime then
        press.dropTime = absTime
        press.dropLabel = self:FormatMoveLabel(phase, relTime, absTime)
    end
    local x = math.max(0, CursorTimeInBody(timeline)) * (timeline.options.pixels_per_second or 15) * (timeline.currentScale or 1)

    local icon = timeline.dragGhostIcon
    local lineFrame = press.block:GetParent()
    local spellInfo = press.blockData[5] and C_Spell.GetSpellInfo(press.blockData[5])
    icon:ClearAllPoints()
    if lineFrame then
        icon:SetPoint("LEFT", lineFrame, "LEFT", x, 0)
        icon:SetTexture(press.blockData.customIcon or spellInfo and spellInfo.iconID or "Interface\\ICONS\\INV_Misc_Note_01")
        icon:Show()
    else
        icon:Hide()
    end
end

-- Whether a pull, or a pull timer counting down, owns the reminder frames.
function NSI:RemindersOwnedByPull()
    return self.EncounterID ~= nil or (self.PrePullTimerEndTime ~= nil and self.PrePullTimerEndTime > GetTime())
end

-- The preview at clock (seconds from the pull) over windows {start, finish}: indexes to show now,
-- {index, delay} to schedule, whether anything is left, and seconds until the last window ends.
-- A window ending exactly at clock is over unless it has zero length.
function NSI:TimelinePreviewPlan(windows, clock)
    local show, pending, lastFinish = {}, {}, nil
    for i, w in ipairs(windows) do
        local live = true
        if clock < w.start then
            pending[#pending + 1] = {index = i, delay = w.start - clock}
        elseif clock < w.finish or clock == w.start then
            show[#show + 1] = i
        else
            live = false
        end
        if live and (not lastFinish or w.finish > lastFinish) then lastFinish = w.finish end
    end
    return {
        show = show,
        pending = pending,
        left = lastFinish ~= nil,
        endsIn = lastFinish and math.max(lastFinish - clock, 0) or nil,
    }
end

-- What ProcessReminder would file for this character from one note's text under encID, by phase.
-- Builds into store (a new table when nil); NSI.ProcessedReminder is never touched.
function NSI:BuildNotePreviewReminders(str, encID, store)
    store = store or {}
    if not str or not encID then return store end
    local ctx = self:GetPlayerTagContext()
    local showAll = NSRT.ReminderSettings.ShowAllReminders
    local added = {}
    local sectionEncID = 0
    if not str:match("\n$") then str = str .. "\n" end
    for line in str:gmatch("([^\n]*)\n") do
        local skip = line:match("assign:([^;]+)") ~= nil
        if line:find("EncounterID:") then
            local id = line:match("EncounterID:(%d+)")
            sectionEncID = id and tonumber(id)
            skip = skip or id ~= nil
        end
        if not skip and sectionEncID == encID then
            local f = self:ParseReminderLine(line)
            if f.time and f.tag and (f.text or f.spellID) then
                local timeNum = tonumber(f.time)
                local phase = f.phase and tonumber(f.phase) or 1
                if timeNum < 0 then phase = 1 end
                local key = encID .. phase .. f.time .. f.tag .. (f.text or f.spellID)
                if (showAll or self:TagMatchesContext(f.tag, ctx)) and not added[key] then
                    added[key] = true
                    if timeNum >= 0 then
                        self:AddToReminder({DisplayType = f.DisplayType, text = f.text, phase = phase, textColors = f.colors,
                            countdown = f.countdown, glowunit = f.glowunit, sound = f.sound, time = f.time, spellID = f.spellID,
                            dur = f.dur, TTS = f.TTS, TTSTimer = f.TTSTimer, encID = encID}, store)
                    end
                end
            end
        end
    end
    return store
end

local function CopyPreviewInfo(info)
    local copy = {}
    for key, value in pairs(info) do
        copy[key] = value
    end
    return copy
end

-- Reminders the layers on screen play for this character, by phase, and the status when there are none.
-- Without a view-only pick that is what is loaded; with one, the picked note's text stands in for the loaded shared note.
local function PreviewReminders(self, window, encID)
    local empty = T("No reminders fire for you on this boss.")
    local pick = window.sharedView and NSRT.Reminders[window.sharedView]
    if pick then
        local store = self:BuildNotePreviewReminders(pick, encID)
        local personal = self:ShownPersonalNote(encID)
        if personal then self:BuildNotePreviewReminders(NSRT.PersonalReminders[personal], encID, store) end
        return store[encID] or {}, empty
    end
    if not self.ProcessedReminder then self:ProcessReminder() end
    return encID and self.ProcessedReminder and self.ProcessedReminder[encID] or {}, empty
end

-- One {info, start, finish} per reminder, in seconds from the pull. info is a copy, so the loaded reminders stay as they are.
local function PreviewWindows(self, byPhase, encID, difficulty)
    local windows = {}
    for phase, reminders in pairs(byPhase) do
        -- Bucket 0 holds lines before any encounter header; the runtime never fires it.
        if phase ~= 0 then
            local phaseStart = self:GetPhaseStart(encID, phase, difficulty) or 0
            for _, info in ipairs(reminders) do
                local time = info.time or 0
                local copy = CopyPreviewInfo(info)
                copy.encID = encID
                windows[#windows + 1] = {info = copy, start = phaseStart + math.max(time - (info.dur or 0), 0), finish = phaseStart + time}
            end
        end
    end
    return windows
end

-- Bumping the generation turns every callback scheduled before it into a no-op.
local function CancelPreviewTimers(window)
    for _, timer in ipairs(window.previewTimers or {}) do
        timer:Cancel()
    end
    window.previewTimers = {}
    window.previewGeneration = (window.previewGeneration or 0) + 1
end

-- Shows a fresh copy, since DisplayReminder writes its timing into the info. remaining shortens a
-- reminder the clock skipped into.
local function ShowPreviewReminder(self, window, generation, info, remaining)
    if not window.previewActive or window.previewGeneration ~= generation or self:RemindersOwnedByPull() then return end
    info = CopyPreviewInfo(info)
    if remaining then
        info.totalDuration = info.dur
        info.dur = remaining
        info.expires = GetTime() + remaining
    end
    self:DisplayReminder(info)
end

-- Schedules the preview from its clock; false when nothing is left to play.
local function SchedulePreview(self, window)
    local clock = GetTime() - window.previewStartTime
    local windows = window.previewWindows
    local plan = self:TimelinePreviewPlan(windows, clock)
    if not plan.left then return false end
    local generation = window.previewGeneration
    local timers = window.previewTimers
    for _, index in ipairs(plan.show) do
        local w = windows[index]
        local remaining = clock > w.start and w.finish - clock or nil
        xpcall(function() ShowPreviewReminder(self, window, generation, w.info, remaining) end, geterrorhandler())
    end
    for _, item in ipairs(plan.pending) do
        local info = windows[item.index].info
        timers[#timers + 1] = C_Timer.NewTimer(item.delay, function()
            xpcall(function() ShowPreviewReminder(self, window, generation, info) end, geterrorhandler())
        end)
    end
    timers[#timers + 1] = C_Timer.NewTimer(plan.endsIn, function()
        xpcall(function()
            if not window.previewActive or window.previewGeneration ~= generation then return end
            -- The last reminder runs out on its own.
            self:StopTimelinePreview(true)
            window:SetStatus(T("Preview finished."), "info")
        end, geterrorhandler())
    end)
    return true
end

-- Plays the view on screen for this character, every phase at its timeline start.
function NSI:StartTimelinePreview()
    local window = self.TimelineWindow
    if not window or window.previewActive then return end
    if self:RemindersOwnedByPull() then
        window:SetStatus(T("Preview is unavailable during a pull."), "error")
        return
    end
    if self:IsUsingTLReminders() then
        window:SetStatus(T("Preview is off while reminders display through TimelineReminders."), "error")
        return
    end
    local encID = window.currentEncounterID
    local byPhase, emptyText = PreviewReminders(self, window, encID)
    local windows = PreviewWindows(self, byPhase, encID, window.currentDifficulty)
    if #windows == 0 then
        window:SetStatus(emptyText, "error")
        return
    end
    self:HideAllReminders()
    self.AllGlows = {}
    CancelPreviewTimers(window)
    window.previewWindows = windows
    window.previewActive = true
    window.previewStartTime = GetTime()
    SchedulePreview(self, window)
    window:SetPreviewButtonState(true)
    self:UpdateTimelineControls()
end

-- Moves the preview clock forward. The HideAllReminders hook ignores the clear made here.
function NSI:SkipTimelinePreview(seconds)
    local window = self.TimelineWindow
    if not window or not window.previewActive or not window.previewStartTime then return end
    if self:RemindersOwnedByPull() then
        self:StopTimelinePreview(true)
        return
    end
    CancelPreviewTimers(window)
    window.previewSkipping = true
    local cleared = xpcall(function() self:HideAllReminders() end, geterrorhandler())
    window.previewSkipping = false
    if not cleared then
        self:StopTimelinePreview(true)
        return
    end
    window.previewStartTime = window.previewStartTime - seconds
    if not SchedulePreview(self, window) then
        self:StopTimelinePreview()
        window:SetStatus(T("Preview finished."), "info")
    end
end

-- keepReminders leaves the reminder frames alone (a pull or another preview owns them now).
function NSI:StopTimelinePreview(keepReminders)
    local window = self.TimelineWindow
    if not window or not window.previewActive then return end
    window.previewActive = false
    window.previewStartTime = nil
    window.previewWindows = nil
    CancelPreviewTimers(window)
    if window.timeline and window.timeline.previewLine then
        window.timeline.previewLine:Hide()
        if window.timeline.previewChip then window.timeline.previewChip:Hide() end
    end
    window:SetPreviewButtonState(false)
    if not keepReminders and not self:RemindersOwnedByPull() then
        self:HideAllReminders()
    end
    self:UpdateTimelineControls()
end

-- Update timeline window title with boss name and difficulty
function NSI:UpdateTimelineTitle()
    local window = self.TimelineWindow
    if not window then return end

    local title = T("Timeline")

    local encID = window.currentEncounterID
    if encID then
        local bossName = self:GetEncounterName(encID)
        local difficulty = window.currentDifficulty

        if difficulty then
            title = string.format(T("Timeline - %s (%s)"), T(bossName), T(difficulty))
        else
            title = string.format(T("Timeline - %s"), T(bossName))
        end
    end
    title = Colored("Northern Sky", STYLE.accent) .. " " .. title

    -- Update the title text
    if window.TitleBar and window.TitleBar.Text then
        window.TitleBar.Text:SetText(title)
    elseif window.Title then
        window.Title:SetText(title)
    end
end

local function PhaseMarkerTooltip(owner, marker, onChip)
    local window = NSI.TimelineWindow
    if not window or window.phaseDrag then return end
    local phases = window.currentPhases
    local title
    if marker.isEnd then
        title = T("End of fight")
    else
        title = phases and phases[marker.phaseNum] and phases[marker.phaseNum].name
            or string.format(T("Phase %s"), NSI:FormatPhaseNumber(marker.phaseNum))
    end
    TooltipTitle(owner, title)
    TooltipLine(NSI:FormatTimelineClock(NSI:GetPhaseStart(marker.encID, marker.phaseNum, window.currentDifficulty) or 0), STYLE.textDim)
    if marker.draggable then
        TooltipLine(onChip and T("Click to scroll to it. Drag to move it. Right-click for reset options.")
            or T("Drag to move it."), STYLE.textDim)
    elseif onChip and not marker.isEnd then
        TooltipLine(T("Click to scroll to it. Right-click for reset options."), STYLE.textDim)
    end
    GameTooltip:Show()
end

local function ShowPhaseMarkerMenu(window, marker)
    local items = {}
    if marker.draggable then
        items[1] = {type = "button", label = T("Reset this phase timing"), fnc = function()
            NSI:ResetPhaseStart(marker.encID, marker.phaseNum)
            NSI:RefreshTimelineForMode()
            window:SetStatus(string.format(T("Phase %s timing reset."), NSI:FormatPhaseNumber(marker.phaseNum))
                .. " " .. T("Phase timing changed for all difficulties."), "success")
        end}
    end
    items[#items + 1] = {type = "button", label = T("Reset all phase timings for this boss"), fnc = function()
        NSI:ShowResetPhaseTimingsConfirm(window, marker.encID)
    end}
    NSI.UI.Components.ShowContextMenu(items)
end

-- Left press on a marker: a drag moves a draggable phase, a click on the chip scrolls to it.
local function PhaseMarkerMouseDown(marker, button, onChip)
    local window = NSI.TimelineWindow
    if not window or marker.isEnd then return end
    if button == "LeftButton" and not window.phaseDrag then
        marker.pressX, marker.pressY = GetCursorPosition()
        marker.moved = false
        marker.pressOnChip = onChip
        window.phaseDrag = marker
        GameTooltip:Hide()
        if marker.draggable then
            local start = NSI:GetPhaseStart(marker.encID, marker.phaseNum, window.currentDifficulty) or 0
            marker.grabOffset = CursorTimeInBody(window.timeline) - start
            marker.dragTime = start
            Paint(marker.chip.bg, STYLE.phaseChipDrag)
        end
    end
end

local function PlacePhaseMarker(window, marker, time)
    local timeline = window.timeline
    local x = time * (timeline.options.pixels_per_second or 15) * (timeline.currentScale or 1)
    local top = -(STYLE.rulerHeight + STYLE.phaseLaneHeight)
    local line, hit, chip = marker.line, marker.hit, marker.chip
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", timeline.body, "TOPLEFT", x, top)
    line:SetPoint("BOTTOMLEFT", timeline.body, "BOTTOMLEFT", x, 0)
    hit:ClearAllPoints()
    hit:SetPoint("TOPLEFT", timeline.body, "TOPLEFT", x - STYLE.phaseGrabWidth / 2, top)
    hit:SetPoint("BOTTOMLEFT", timeline.body, "BOTTOMLEFT", x - STYLE.phaseGrabWidth / 2, 0)
    chip:ClearAllPoints()
    if marker.isEnd then
        chip:SetPoint("TOPRIGHT", timeline.rulerStrip, "TOPLEFT", x, -STYLE.rulerHeight)
    else
        chip:SetPoint("TOPLEFT", timeline.rulerStrip, "TOPLEFT", x, -STYLE.rulerHeight)
    end
end

-- One marker per phase number: a 1 px line and a grab strip on the canvas, a chip in the phase lane.
local function CreatePhaseMarker(window, phaseNum)
    local timeline = window.timeline
    local body = timeline.body
    local marker = {phaseNum = phaseNum}

    marker.line = body:CreateTexture(nil, "OVERLAY")
    marker.line:SetWidth(1)
    NSI.UI.PP.NoSnap(marker.line)

    local hit = CreateFrame("Frame", nil, body)
    hit:SetWidth(STYLE.phaseGrabWidth)
    hit:SetFrameLevel(body:GetFrameLevel() + 8)
    marker.hit = hit

    local chip = CreateFrame("Frame", nil, timeline.rulerStrip)
    chip:SetHeight(STYLE.chipHeight)
    chip:SetFrameLevel(timeline.rulerStrip:GetFrameLevel() + 4)
    chip.bg = chip:CreateTexture(nil, "BACKGROUND")
    chip.bg:SetAllPoints()
    chip.text = NewFontString(chip, STYLE.chipTextSize)
    chip.text:SetPoint("CENTER", chip, "CENTER", 0, 0)
    marker.chip = chip

    for _, frame in ipairs({hit, chip}) do
        local onChip = frame == chip
        frame:SetScript("OnEnter", function(self) PhaseMarkerTooltip(self, marker, onChip) end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        frame:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                if onChip then
                    marker.rightX, marker.rightY = GetCursorPosition()
                elseif window.CanvasRightDown then
                    window.CanvasRightDown()
                end
                return
            end
            PhaseMarkerMouseDown(marker, button, onChip)
        end)
        frame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                if window.phaseDrag == marker then NSI:FinishPhaseDrag() end
            elseif button == "RightButton" then
                if not onChip then
                    if window.CanvasRightUp then window.CanvasRightUp() end
                    return
                end
                local x, y = GetCursorPosition()
                local pressX, pressY = marker.rightX, marker.rightY
                marker.rightX, marker.rightY = nil, nil
                if pressX and not marker.isEnd and not window.phaseDrag
                    and (x - pressX) ^ 2 + (y - pressY) ^ 2 < DRAG_THRESHOLD * DRAG_THRESHOLD then
                    ShowPhaseMarkerMenu(window, marker)
                end
            end
        end)
    end

    window.phaseMarkers[phaseNum] = marker
    return marker
end

local function HidePhaseMarker(marker)
    marker.line:Hide()
    marker.hit:Hide()
    marker.chip:Hide()
end

-- Called every frame from the timeline body while a phase marker is held.
function NSI:UpdatePhaseDrag()
    local window = self.TimelineWindow
    local marker = window and window.phaseDrag
    if not marker then return end
    if not IsMouseButtonDown("LeftButton") then
        self:FinishPhaseDrag()
        return
    end
    if not marker.moved then
        local x, y = GetCursorPosition()
        local dx, dy = x - marker.pressX, y - marker.pressY
        if dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD then return end
        marker.moved = true
    end
    if not marker.draggable then return end
    local time = math.max(0, math.floor(CursorTimeInBody(window.timeline) - marker.grabOffset + 0.5))
    if time ~= marker.dragTime then
        marker.dragTime = time
        PlacePhaseMarker(window, marker, time)
        SetChipText(marker.chip, marker.label .. " " .. self:FormatTimelineClock(time))
    end
end

function NSI:FinishPhaseDrag()
    local window = self.TimelineWindow
    local marker = window and window.phaseDrag
    if not marker then return end
    window.phaseDrag = nil
    local difficulty = window.currentDifficulty
    local before = self:GetPhaseStart(marker.encID, marker.phaseNum, difficulty)
    if not marker.moved then
        self:UpdatePhaseMarkers()
        if marker.pressOnChip then self:ScrollTimelineToTime(before or 0) end
        return
    end
    local newTime = marker.dragTime or before
    if not marker.draggable or newTime == before then
        self:UpdatePhaseMarkers()
        return
    end
    self:SetPhaseStart(marker.encID, marker.phaseNum, newTime, difficulty)
    local after = self:GetPhaseStart(marker.encID, marker.phaseNum, difficulty)
    self:RefreshTimelineForMode()
    local label = self:FormatPhaseNumber(marker.phaseNum)
    if after == before then
        window:SetStatus(string.format(T("Phase %s can't start before the phase ahead of it."), label), "error")
    else
        window:SetStatus(string.format(T("Phase %s now starts at %s."), label, self:FormatTimelineClock(after))
            .. " " .. T("Phase timing changed for all difficulties."), "success")
    end
end

function NSI:UpdatePhaseMarkers()
    local window = self.TimelineWindow
    if not window then return end
    window.phaseMarkers = window.phaseMarkers or {}
    window.phaseKeys = window.phaseKeys or {}
    window.phaseStartTimes = window.phaseStartTimes or {}
    for _, marker in pairs(window.phaseMarkers) do
        HidePhaseMarker(marker)
    end
    local keys, starts = window.phaseKeys, window.phaseStartTimes
    for i = #keys, 1, -1 do
        keys[i], starts[i] = nil, nil
    end
    -- Tells the cursor chip, which caches its text per second, that phase starts may have moved.
    window.phaseStamp = (window.phaseStamp or 0) + 1

    window.phaseDrag = nil

    local phases = window.currentPhases
    local encID = window.currentEncounterID
    local timeline = window.timeline
    if not phases or not encID or not timeline or not timeline.body or not timeline.rulerStrip then return end

    local difficulty = window.currentDifficulty
    local endPhase = self:GetEndOfFightPhase(self:GetBossTimeline(encID, difficulty))

    for _, phaseNum in ipairs(self:SortedPhaseKeys(phases)) do
        local start = self:GetPhaseStart(encID, phaseNum, difficulty) or 0
        local isEnd = phaseNum == endPhase
        if not isEnd then
            keys[#keys + 1], starts[#starts + 1] = phaseNum, start
        end
        local marker = window.phaseMarkers[phaseNum] or CreatePhaseMarker(window, phaseNum)
        marker.encID = encID
        marker.isEnd = isEnd
        marker.draggable = phaseNum > 1 and not isEnd
        marker.label = isEnd and T("End") or ("P" .. self:FormatPhaseNumber(phaseNum))
        marker.dragTime = nil
        PlacePhaseMarker(window, marker, start)
        Paint(marker.line, isEnd and STYLE.endLine or STYLE.phaseLine)
        Paint(marker.chip.bg, isEnd and STYLE.endChip or STYLE.phaseChip)
        Tint(marker.chip.text, isEnd and STYLE.endChipText or STYLE.phaseChipText)
        SetChipText(marker.chip, marker.label)
        marker.chip:EnableMouse(not isEnd)
        marker.hit:EnableMouse(marker.draggable)
        marker.chip:Show()
        if phaseNum > 1 then
            marker.line:Show()
            marker.hit:SetShown(marker.draggable)
        end
    end
end

--------------------------------------------------------------------------------
-- ADD / EDIT REMINDER DIALOG
--------------------------------------------------------------------------------

local DIALOG_FIELDS = {"ph", "time", "spellid", "text", "dur", "TTSTimer", "glowunit"}
-- Set by the dialog's Display type and Color controls; nil while the user hasn't touched them.
local DIALOG_PICKED_FIELDS = {"DisplayType", "colors"}

-- Tag written on reminders added from the timeline.
local function NewReminderTag()
    return UnitName("player") or ""
end

local function ColoredByClass(text, classFile)
    local hex = ClassFileColorHex(classFile)
    return hex and ("|c" .. hex .. text .. "|r") or text
end

-- Classes and current group members for the For field.
local function ReminderTagSources()
    local classes = {}
    -- Class IDs have gaps in some clients; GetClassInfo returns nil for unused ones.
    for id = 1, 20 do
        local info = C_CreatureInfo.GetClassInfo(id)
        if info and info.className then
            classes[#classes + 1] = {id = id, name = info.className, classFile = info.classFile}
        end
    end
    table.sort(classes, function(a, b) return a.name < b.name end)
    local members, seen = {}, {}
    local function Add(unit)
        local name = UnitName(unit)
        if name and name ~= "" and not seen[strlower(name)] then
            seen[strlower(name)] = true
            members[#members + 1] = {name = name, classFile = select(2, UnitClass(unit))}
        end
    end
    -- Names may be unreadable in some restricted states; the list is a convenience.
    pcall(function()
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do Add("raid" .. i) end
        else
            Add("player")
            for i = 1, GetNumGroupMembers() - 1 do Add("party" .. i) end
        end
    end)
    table.sort(members, function(a, b) return strlower(a.name) < strlower(b.name) end)
    return classes, members
end

local function TagChoiceLabel(choice)
    if not choice then return T("Custom") end
    return choice.classFile and ColoredByClass(choice.label, choice.classFile) or choice.label
end

-- Sets the For field to a choice, or to Custom (choice nil) with customText in the box.
local function SetDialogTag(popup, choice, tagValue, customText)
    popup.tagChoice = choice
    popup.tagValue = choice and tagValue or nil
    popup.forBtn:SetText(TagChoiceLabel(choice))
    if choice then
        popup.tagEntry.frame:Hide()
    else
        popup.tagEntry:SetValue(customText or "")
        popup.tagEntry.frame:Show()
    end
end

local function ShowTagMenu(self, popup)
    local classes, members = ReminderTagSources()
    local choices = self:ReminderTagChoices(classes, members)
    local function Item(choice)
        return {type = "button", label = TagChoiceLabel(choice), fnc = function()
            SetDialogTag(popup, choice, choice.tag)
        end}
    end
    local items, byKind = {}, {}
    for _, choice in ipairs(choices) do
        byKind[choice.kind] = byKind[choice.kind] or {}
        table.insert(byKind[choice.kind], Item(choice))
    end
    local function Append(list)
        for _, item in ipairs(list or {}) do items[#items + 1] = item end
    end
    Append(byKind.everyone)
    items[#items + 1] = {type = "separator"}
    Append(byKind.role)
    items[#items + 1] = {type = "separator"}
    Append(byKind.position)
    items[#items + 1] = {type = "separator"}
    items[#items + 1] = {type = "submenu", label = T("Class"), items = byKind.class or {}}
    items[#items + 1] = {type = "submenu", label = T("Group"), items = byKind.group or {}}
    if byKind.player then
        items[#items + 1] = {type = "submenu", label = T("Players"), items = byKind.player}
    end
    items[#items + 1] = {type = "separator"}
    items[#items + 1] = {type = "button", label = T("Custom"), fnc = function()
        local current = popup.tagChoice and popup.tagValue or popup.tagEntry.editBox:GetText()
        SetDialogTag(popup, nil, nil, current)
        popup.tagEntry.editBox:SetFocus()
    end}
    NSI.UI.Components.ShowContextMenuAtFrame(items, popup.forBtn.frame, 180, 16, popup)
end

-- The For value to save: the picked choice's tag, or the trimmed Custom text.
local function DialogTagValue(popup)
    if popup.tagChoice then return popup.tagValue end
    return strtrim(popup.tagEntry.editBox:GetText())
end

local function FightTimeText(self, encID, difficulty, ph, time)
    ph, time = tonumber(ph), tonumber(time)
    if not ph or not time then return "" end
    if time < 0 then
        return string.format(T("= %s before the pull"), self:FormatTimelineClock(-time))
    end
    local phaseStart = encID and self:GetPhaseStart(encID, ph, difficulty) or 0
    return string.format(T("= %s into the fight"), self:FormatTimelineClock(phaseStart + time))
end

-- The boss data's phases for the dialog's phase buttons, without the end-of-fight marker. Empty for one phase.
function NSI:ReminderDialogPhases(encID, difficulty)
    local timeline = encID and self:GetBossTimeline(encID, difficulty)
    if not timeline or not timeline.phases then return {} end
    local endPhase = self:GetEndOfFightPhase(timeline)
    local list = {}
    for _, phase in ipairs(self:SortedPhaseKeys(timeline.phases)) do
        if phase ~= endPhase then
            list[#list + 1] = {phase = phase, label = self:FormatPhaseNumber(phase), name = timeline.phases[phase].name}
        end
    end
    if #list <= 1 then return {} end
    return list
end

-- Shows the phase buttons that fit right of the Phase entry; the rest go behind the "..." menu button.
local function LayoutPhaseButtons(popup, choices, editable)
    local gap, buttons, more = STYLE.dialogPhaseButtonGap, popup.phaseButtons, popup.phaseMore
    local widths, total = {}, 0
    for i, choice in ipairs(choices) do
        local button = buttons[i] or popup.NewPhaseButton()
        buttons[i] = button
        button.nsChoice = choice
        button:SetText(choice.label)
        widths[i] = math.max(STYLE.dialogPhaseButtonMinWidth, math.ceil(button.label:GetStringWidth()) + 12)
        total = total + widths[i] + (i > 1 and gap or 0)
    end
    local fit = #choices
    if total > popup.phaseRowWidth then
        local room = popup.phaseRowWidth - more:GetWidth() - gap
        fit, total = 0, 0
        while fit < #choices and total + widths[fit + 1] + (fit > 0 and gap or 0) <= room do
            total = total + widths[fit + 1] + (fit > 0 and gap or 0)
            fit = fit + 1
        end
    end
    local x = STYLE.controlGap
    for i, button in ipairs(buttons) do
        button.frame:ClearAllPoints()
        if i <= fit then
            button:SetSize(widths[i], 22)
            button:SetPoint("LEFT", popup.entries.ph.frame, "RIGHT", x, 0)
            x = x + widths[i] + gap
            if editable then button:Enable() else button:Disable() end
            button.frame:Show()
        else
            button.frame:Hide()
        end
    end
    popup.phaseChoices, popup.phaseFit = choices, fit
    more.frame:ClearAllPoints()
    more:SetPoint("LEFT", popup.entries.ph.frame, "RIGHT", x, 0)
    if editable then more:Enable() else more:Disable() end
    more.frame:SetShown(fit < #choices)
end

local function CreateReminderDialog(self)
    local C = NSI.UI.Components
    local W = STYLE.dialogWidth
    local fieldX = STYLE.dialogFieldX
    local fullWidth = W - fieldX - STYLE.dialogLabelX
    local popup = C.CreateFrame(UIParent, W, STYLE.dialogHeight, "NSRTReminderDialogPopup")
    popup:SetFrameStrata("TOOLTIP")
    popup:HookScript("OnHide", C.HideContextMenu)

    local titleFS = NewFontString(popup, STYLE.dialogTitleSize, STYLE.accent)
    titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", STYLE.dialogLabelX, -10)
    popup.titleFS = titleFS

    local sep = popup:CreateTexture(nil, "ARTWORK")
    Paint(sep, STYLE.dialogRule)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  popup, "TOPLEFT",  1, -28)
    sep:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -1, -28)

    local function RowY(row)
        return STYLE.dialogFirstRowY - (row - 1) * STYLE.dialogRowPitch
    end

    local function Label(text, row, x, width)
        local labelFS = NewFontString(popup, STYLE.dialogLabelSize, STYLE.textDim)
        labelFS:SetWidth(width or STYLE.dialogLabelWidth)
        labelFS:SetText(text)
        labelFS:SetPoint("LEFT", popup, "TOPLEFT", x or STYLE.dialogLabelX, RowY(row) - 11)
        return labelFS
    end

    -- column2: the field sits in the second column of a two-field row.
    local entries = {}
    local function Entry(key, label, row, width, name, column2)
        if column2 then
            Label(label, row, STYLE.dialogColumn2LabelX, STYLE.dialogColumn2FieldX - STYLE.dialogColumn2LabelX - 4)
        else
            Label(label, row)
        end
        local entry = C.CreateTextEntry(popup, nil, function() return "" end, function() end,
            width, 22, false, nil, nil, name)
        entry.editBox:SetMaxLetters(0)
        entry:SetPoint("TOPLEFT", popup, "TOPLEFT", column2 and STYLE.dialogColumn2FieldX or fieldX, RowY(row))
        entries[key] = entry
        return entry
    end

    local function HintTooltip(frame, title, hint)
        frame:HookScript("OnEnter", function(owner)
            TooltipTitle(owner, title)
            TooltipLine(hint)
            GameTooltip:Show()
        end)
        frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local function Hint(anchor, xOffset)
        local fs = NewFontString(popup, STYLE.dialogHintSize, STYLE.textDim)
        fs:SetPoint("LEFT", anchor, "RIGHT", xOffset or 8, 0)
        return fs
    end

    local forLabel = NewFontString(popup, STYLE.dialogLabelSize, STYLE.textDim)
    forLabel:SetWidth(STYLE.dialogLabelWidth)
    forLabel:SetText(T("For"))
    forLabel:SetPoint("LEFT", popup, "TOPLEFT", STYLE.dialogLabelX, RowY(1) - 11)
    popup.forLabel = forLabel
    local forBtn = C.CreateButton(popup, "", function()
        ShowTagMenu(self, popup)
    end, STYLE.dialogForWidth, 22, nil, nil, STYLE.controlTextSize)
    forBtn:SetPoint("TOPLEFT", popup, "TOPLEFT", fieldX, RowY(1))
    MakeMenuButton(forBtn)
    popup.forBtn = forBtn
    local tagEntry = C.CreateTextEntry(popup, nil, function() return "" end, function() end,
        fullWidth - STYLE.dialogForWidth - STYLE.controlGap, 22, false, nil, nil, "NSRTReminderTagCustom")
    tagEntry.editBox:SetMaxLetters(0)
    tagEntry:SetPoint("LEFT", forBtn.frame, "RIGHT", STYLE.controlGap, 0)
    popup.tagEntry = tagEntry

    local phaseEntryWidth = 60
    Entry("ph", T("Phase"), 2, phaseEntryWidth, "NSRTReminderPhase")
    popup.phaseRowWidth = W - STYLE.dialogLabelX - fieldX - phaseEntryWidth - STYLE.controlGap
    popup.phaseButtons = {}
    local function SetPhase(choice)
        entries.ph:SetValue(choice.label)
    end
    function popup.NewPhaseButton()
        local button
        button = C.CreateButton(popup, "", function() SetPhase(button.nsChoice) end, STYLE.dialogPhaseButtonMinWidth, 22,
            nil, nil, STYLE.controlTextSize)
        button.labelFrame:ClearAllPoints()
        button.labelFrame:SetAllPoints(button.frame)
        button.frame:HookScript("OnEnter", function(frame)
            local choice, ctx = button.nsChoice, popup._ctx
            if not choice or not ctx then return end
            TooltipTitle(frame, choice.name or string.format(T("Phase %s"), choice.label))
            TooltipLine(string.format(T("= %s into the fight"),
                self:FormatTimelineClock(self:GetPhaseStart(ctx.encID, choice.phase, ctx.difficulty) or 0)), STYLE.textDim)
            GameTooltip:Show()
        end)
        button.frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
        return button
    end
    local phaseMore
    phaseMore = C.CreateButton(popup, "...", function()
        local items = {}
        for i = (popup.phaseFit or 0) + 1, #(popup.phaseChoices or {}) do
            local choice = popup.phaseChoices[i]
            items[#items + 1] = {type = "button", label = choice.name or string.format(T("Phase %s"), choice.label),
                fnc = function() SetPhase(choice) end}
        end
        C.ShowContextMenuAtFrame(items, phaseMore.frame, 140, 16, popup)
    end, nil, 22, nil, nil, STYLE.controlTextSize)
    phaseMore.frame:Hide()
    popup.phaseMore = phaseMore

    -- The button for the phase in the entry is selected; "..." is when that phase is in its menu.
    local function UpdatePhaseSelection()
        local current = tonumber(strtrim(entries.ph.editBox:GetText()))
        local overflowSelected = false
        for i, button in ipairs(popup.phaseButtons) do
            local selected = current ~= nil and button.nsChoice ~= nil and button.nsChoice.phase == current
            if i > (popup.phaseFit or 0) then
                overflowSelected = overflowSelected or (selected and i <= #(popup.phaseChoices or {}))
                selected = false
            end
            if selected then button:Select() elseif button:IsSelected() then button:Deselect() end
        end
        if overflowSelected then phaseMore:Select() elseif phaseMore:IsSelected() then phaseMore:Deselect() end
    end
    popup.UpdatePhaseSelection = UpdatePhaseSelection
    entries.ph.editBox:HookScript("OnTextChanged", UpdatePhaseSelection)

    Entry("time", T("Time"), 3, 80, "NSRTReminderTime")
    popup.fightTimeFS = Hint(entries.time.frame)

    Entry("spellid", T("Spell ID"), 4, 100, "NSRTReminderSpellID")
    -- ShowSpellbookPicker writes its pick into target.spellEntry.
    popup.spellEntry = entries.spellid

    local spellIcon = popup:CreateTexture(nil, "OVERLAY")
    spellIcon:SetSize(20, 20)
    spellIcon:SetPoint("LEFT", entries.spellid.frame, "RIGHT", 6, 0)
    spellIcon:Hide()
    popup.spellIcon = spellIcon

    local pickBtn = C.CreateButton(popup, T("Pick a spell"), function()
        NSI:ShowSpellbookPicker(popup)
    end, 100, 22, nil, nil, STYLE.controlTextSize)
    pickBtn:SetPoint("LEFT", entries.spellid.frame, "RIGHT", 32, 0)
    popup.pickBtn = pickBtn

    entries.spellid.editBox:HookScript("OnTextChanged", function(eb)
        local info = tonumber(eb:GetText()) and C_Spell.GetSpellInfo(tonumber(eb:GetText()))
        if info and info.iconID then
            spellIcon:SetTexture(info.iconID)
            spellIcon:Show()
        else
            spellIcon:Hide()
        end
    end)

    Entry("text", T("Text"), 5, fullWidth, "NSRTReminderText")
    Entry("dur", T("Duration"), 6, STYLE.dialogShortFieldWidth, "NSRTReminderDur")
    HintTooltip(entries.dur.editBox, T("Duration"), T("Seconds shown before it fires"))
    Entry("TTSTimer", T("TTS timer"), 6, STYLE.dialogShortFieldWidth, "NSRTReminderTTSTimer", true)
    HintTooltip(entries.TTSTimer.editBox, T("TTS timer"),
        T("Seconds before the time that TTS is spoken. Empty uses the duration."))

    -- popup.DisplayTypePicked and colorsPicked: nil keeps the reminder's field, "" removes it, else the value to write.
    local function Current(key)
        local value = popup[key .. "Picked"]
        if value ~= nil then return value end
        return popup._ctx and popup._ctx.prefill[key] or ""
    end
    local function Editable()
        return popup._ctx ~= nil and popup._ctx.mode ~= "view"
    end

    Label(T("Display type"), 7)
    local displayBtn
    local function RefreshDisplayType()
        local shown = self:ReminderDisplayType(Current("DisplayType"))
        displayBtn:SetText(shown and T(shown) or T("Default"))
        if Editable() then displayBtn:Enable() else displayBtn:Disable() end
    end
    displayBtn = C.CreateButton(popup, "", function()
        local function Item(label, value)
            return {type = "button", label = label, fnc = function()
                popup.DisplayTypePicked = value
                RefreshDisplayType()
            end}
        end
        local items = {Item(T("Default"), "")}
        for _, displayType in ipairs(REMINDER_DISPLAY_TYPES) do
            items[#items + 1] = Item(T(displayType), displayType)
        end
        C.ShowContextMenuAtFrame(items, displayBtn.frame, 120, 16, popup)
    end, STYLE.dialogColumn2LabelX - fieldX - 6, 22, nil, nil, STYLE.controlTextSize)
    displayBtn:SetPoint("TOPLEFT", popup, "TOPLEFT", fieldX, RowY(7))
    MakeMenuButton(displayBtn)
    popup.RefreshDisplayType = RefreshDisplayType

    Label(T("Color"), 7, STYLE.dialogColumn2LabelX, STYLE.dialogColumn2FieldX - STYLE.dialogColumn2LabelX - 4)
    local swatch, colorDefaultBtn
    local swatchColor
    local function RefreshColor()
        local value = Current("colors")
        local r, g, b = self:ParseReminderColor(value)
        swatchColor:SetShown(r ~= nil)
        if r then swatchColor:SetColorTexture(r, g, b, 1) end
        if Editable() then swatch:Enable() else swatch:Disable() end
        if Editable() and value ~= "" then colorDefaultBtn:Enable() else colorDefaultBtn:Disable() end
    end
    swatch = C.CreateButton(popup, "", function()
        local ctx = popup._ctx
        if not Editable() then return end
        local before = popup.colorsPicked
        local r, g, b = self:ParseReminderColor(Current("colors"))
        r, g, b = r or 1, g or 1, b or 1
        DF:ColorPick(swatch.frame, r, g, b, nil, function(_, nr, ng, nb, na)
            if popup._ctx ~= ctx or not popup:IsShown() then return end
            -- Cancel hands back the starting colour without an alpha.
            if na == nil and nr == r and ng == g and nb == b then
                popup.colorsPicked = before
            else
                popup.colorsPicked = self:FormatReminderColor(nr, ng, nb)
            end
            RefreshColor()
        end)
    end, STYLE.dialogSwatchWidth, 22)
    swatch:SetPoint("TOPLEFT", popup, "TOPLEFT", STYLE.dialogColumn2FieldX, RowY(7))
    swatchColor = swatch.frame:CreateTexture(nil, "OVERLAY")
    swatchColor:SetPoint("TOPLEFT", swatch.frame, "TOPLEFT", 3, -3)
    swatchColor:SetPoint("BOTTOMRIGHT", swatch.frame, "BOTTOMRIGHT", -3, 3)
    HintTooltip(swatch.frame, T("Color"), T("Text color, or the bar or ring color for those display types."))
    colorDefaultBtn = C.CreateButton(popup, T("Default"), function()
        popup.colorsPicked = ""
        RefreshColor()
    end, nil, 22, nil, nil, STYLE.controlTextSize)
    colorDefaultBtn:SetPoint("LEFT", swatch.frame, "RIGHT", STYLE.controlGap, 0)
    popup.RefreshColor = RefreshColor

    Entry("glowunit", T("Glow"), 8, fullWidth, "NSRTReminderGlow")

    local glowHint = NewFontString(popup, STYLE.dialogHintSize, STYLE.textDim)
    glowHint:SetPoint("TOPLEFT", entries.glowunit.frame, "BOTTOMLEFT", 0, -4)
    glowHint:SetText(T("Player names, separated by spaces"))

    local infoFS = NewFontString(popup, STYLE.dialogHintSize, STYLE.labelText)
    infoFS:SetPoint("TOPLEFT", popup, "TOPLEFT", STYLE.dialogLabelX, RowY(9) - 18)
    infoFS:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -STYLE.dialogLabelX, RowY(9) - 18)
    infoFS:SetWordWrap(true)
    infoFS:SetJustifyV("TOP")
    popup.infoFS = infoFS

    local errorFS = NewFontString(popup, STYLE.dialogHintSize, STYLE.danger)
    errorFS:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", STYLE.dialogLabelX, 44)
    errorFS:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -STYLE.dialogLabelX, 44)
    errorFS:SetWordWrap(true)
    errorFS:SetJustifyV("BOTTOM")
    popup.errorFS = errorFS

    local confirmBtn = C.CreateButton(popup, T("Add"), function()
        if popup._confirmAction then popup._confirmAction() end
    end, 90, 24, nil, nil, STYLE.controlTextSize)
    confirmBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -STYLE.dialogLabelX, 12)
    confirmBtn:Select()
    popup.confirmBtn = confirmBtn

    local cancelBtn = C.CreateButton(popup, T("Cancel"), function()
        popup:Hide()
    end, 90, 24, nil, nil, STYLE.controlTextSize)
    cancelBtn:SetPoint("RIGHT", confirmBtn.frame, "LEFT", -STYLE.controlGap, 0)
    popup.cancelBtn = cancelBtn

    local deleteBtn = C.CreateButton(popup, T("Delete"), function()
        if popup._deleteAction then popup._deleteAction() end
    end, 90, 24, nil, nil, STYLE.controlTextSize)
    deleteBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", STYLE.dialogLabelX, 12)
    deleteBtn:SetTextColor(STYLE.danger[1], STYLE.danger[2], STYLE.danger[3])
    popup.deleteBtn = deleteBtn

    local function UpdateFightTime()
        local ctx = popup._ctx
        if not ctx then return end
        popup.fightTimeFS:SetText(FightTimeText(self, ctx.encID, ctx.difficulty,
            strtrim(entries.ph.editBox:GetText()), strtrim(entries.time.editBox:GetText())))
    end
    entries.ph.editBox:HookScript("OnTextChanged", UpdateFightTime)
    entries.time.editBox:HookScript("OnTextChanged", UpdateFightTime)

    for i, key in ipairs(DIALOG_FIELDS) do
        local editBox = entries[key].editBox
        editBox:SetScript("OnEnterPressed", function()
            if popup._confirmAction then popup._confirmAction() else popup:Hide() end
        end)
        -- Replaces the component's reset-to-default, which would wipe the field.
        editBox:SetScript("OnEscapePressed", function(eb)
            eb:ClearFocus()
            popup:Hide()
        end)
        editBox:SetScript("OnTabPressed", function()
            local step = IsShiftKeyDown() and -1 or 1
            local nextKey = DIALOG_FIELDS[(i - 1 + step) % #DIALOG_FIELDS + 1]
            entries[nextKey].editBox:SetFocus()
        end)
    end
    tagEntry.editBox:SetScript("OnEnterPressed", function()
        if popup._confirmAction then popup._confirmAction() else popup:Hide() end
    end)
    tagEntry.editBox:SetScript("OnEscapePressed", function(eb)
        eb:ClearFocus()
        popup:Hide()
    end)
    tagEntry.editBox:SetScript("OnTabPressed", function()
        entries[DIALOG_FIELDS[1]].editBox:SetFocus()
    end)

    popup.entries = entries
    popup:Hide()
    return popup
end

-- Changed fields only: false removes a field, a string sets it. values.tag nil leaves the tag alone, and so
-- does nil for DisplayType and colors ("" removes them).
function NSI:CollectReminderEdits(values, prefill)
    local edits, changed = {}, false
    for _, key in ipairs(DIALOG_FIELDS) do
        local new = self:NoteSanitizeValue(values[key])
        local old = self:NoteSanitizeValue(key == "text" and prefill[key] or strtrim(prefill[key] or ""))
        if new ~= old then
            changed = true
            edits[key] = new == "" and false or new
        end
    end
    for _, key in ipairs(DIALOG_PICKED_FIELDS) do
        if values[key] ~= nil and values[key] ~= (prefill[key] or "") then
            changed = true
            edits[key] = values[key] == "" and false or values[key]
        end
    end
    if values.tag ~= nil and values.tag ~= "" and values.tag ~= strtrim(prefill.tag or "") then
        changed = true
        edits.tag = values.tag
    end
    return edits, changed
end

function NSI:NewReminderLine(values)
    local edits = {time = values.time}
    if tonumber(values.ph) ~= 1 then edits.ph = values.ph end
    for _, key in ipairs({"spellid", "dur", "TTSTimer", "DisplayType", "colors", "glowunit"}) do
        if values[key] and values[key] ~= "" then edits[key] = values[key] end
    end
    if strtrim(values.text) ~= "" then edits.text = values.text end
    return self:ApplyReminderEdits("tag:" .. self:NoteSanitizeValue(values.tag or NewReminderTag()) .. ";", edits)
end

-- blockData: a reminder block's data (edit a personal reminder, view a shared one); nil adds a
-- reminder at absoluteTime to the personal note for the boss on screen (TimelineAddTarget).
-- addValues: starting field values when adding (text), and exactTime to keep absoluteTime's fraction.
-- boss: the ShownBoss the dialog is for, taken when its menu opened; defaults to the boss on screen now.
function NSI:ShowReminderDialog(window, absoluteTime, blockData, addValues, boss)
    local payload = blockData and blockData.payload
    boss = boss or ShownBoss(window)
    local ctx = {
        encID = boss.encID,
        difficulty = payload and payload.srcDifficulty or boss.difficulty,
    }
    local infoText
    if payload and payload.srcRaw and payload.srcNote and payload.srcNote.personal then
        local raw = payload.srcRaw
        ctx.mode, ctx.note, ctx.srcRaw, ctx.srcLineIndex = "edit", payload.srcNote, raw, payload.srcLineIndex
        ctx.prefill = {
            tag = self:NoteGetField(raw, "tag") or "",
            ph = self:NoteGetField(raw, "ph") or "1",
            time = self:NoteGetField(raw, "time") or tostring(payload.relTime or 0),
            spellid = self:NoteGetField(raw, "spellid") or "",
            text = self:NoteGetField(raw, "text") or "",
            dur = self:NoteGetField(raw, "dur") or "",
            glowunit = self:NoteGetField(raw, "glowunit") or "",
            TTSTimer = self:NoteGetField(raw, "TTSTimer") or "",
            DisplayType = self:NoteGetField(raw, "DisplayType") or "",
            colors = self:NoteGetField(raw, "colors") or "",
        }
        infoText = string.format(T("Saves to %s."), ctx.note.name)
    elseif payload and payload.readOnly then
        ctx.mode, ctx.prefill = "view", payload.readOnly
        infoText = payload.layer == "view" and T("From a shared note you are viewing. It is not loaded.")
            or T("From the shared note. Edit it from the Shared Notes tab.")
    elseif not blockData then
        ctx.mode = "add"
        if not ctx.encID then return end
        local createNote
        ctx.note, createNote = self:TimelineAddTarget(ctx.encID, ctx.difficulty)
        infoText = createNote and string.format(T("Adds to %s, a new personal note."), ctx.note.name)
            or string.format(T("Adds to %s."), ctx.note.name)
        absoluteTime = math.max(0, absoluteTime or 0)
        local phase, phaseStart = self:PhaseFromTime(ctx.encID, absoluteTime, ctx.difficulty)
        ctx.prefill = {
            tag = NewReminderTag(),
            ph = self:FormatPhaseNumber(phase),
            time = self:FormatNoteNumber(addValues and addValues.exactTime and absoluteTime - phaseStart
                or math.floor(absoluteTime - phaseStart + 0.5)),
            spellid = "", text = self:NoteSanitizeValue(addValues and addValues.text or ""), dur = "", glowunit = "",
            TTSTimer = "", DisplayType = "", colors = "",
        }
    else
        return
    end

    self.ReminderDialogPopup = self.ReminderDialogPopup or CreateReminderDialog(self)
    local popup = self.ReminderDialogPopup
    popup._ctx = ctx
    local editable = ctx.mode ~= "view"

    popup.titleFS:SetText((ctx.mode == "add" and T("Add reminder"))
        or (ctx.mode == "edit" and T("Edit reminder")) or T("Reminder"))
    for _, key in ipairs(DIALOG_FIELDS) do
        local entry = popup.entries[key]
        entry:SetValue(ctx.prefill[key] or "")
        if editable then entry:Enable() else entry:Disable() end
    end
    if editable then popup.pickBtn:Enable() else popup.pickBtn:Disable() end
    popup.DisplayTypePicked, popup.colorsPicked = nil, nil
    popup.RefreshDisplayType()
    popup.RefreshColor()
    LayoutPhaseButtons(popup, self:ReminderDialogPhases(ctx.encID, ctx.difficulty), editable)
    popup.UpdatePhaseSelection()
    popup.forLabel:SetShown(editable)
    if editable then
        local prefillTag = strtrim(ctx.prefill.tag or "")
        local choice = self:FindReminderTagChoice(self:ReminderTagChoices(ReminderTagSources()), prefillTag)
        SetDialogTag(popup, choice, prefillTag, prefillTag)
        popup.forBtn.frame:Show()
    else
        popup.forBtn.frame:Hide()
        popup.tagEntry.frame:Hide()
    end
    popup.infoFS:SetText(infoText or "")
    popup.errorFS:SetText("")
    popup.confirmBtn:SetText(ctx.mode == "add" and T("Add") or T("Save"))
    popup.confirmBtn.frame:SetShown(editable)
    popup.deleteBtn.frame:SetShown(ctx.mode == "edit")
    popup.cancelBtn:SetText(editable and T("Cancel") or T("Close"))

    popup._confirmAction = editable and function()
        local values = {}
        for _, key in ipairs(DIALOG_FIELDS) do
            local text = popup.entries[key].editBox:GetText()
            values[key] = key == "text" and text or strtrim(text)
        end
        values.DisplayType, values.colors = popup.DisplayTypePicked, popup.colorsPicked
        local tag = DialogTagValue(popup)
        if ctx.mode == "add" or tag ~= strtrim(ctx.prefill.tag or "") then
            values.tag = tag
        end
        local err = self:ValidateReminderFields(values, ctx.encID, ctx.difficulty)
        -- Checked here as well so a refused save keeps the dialog and what was typed. An add always reloads.
        if not err then
            err = self:TimelineWriteBlocked(ctx.note, ctx.mode == "add" or self:IsTimelineNoteLoaded(ctx.note))
        end
        if err then
            popup.errorFS:SetText(err)
            return
        end
        local label = ReminderDisplayName({text = values.text}, tonumber(values.spellid))
        if ctx.mode == "edit" then
            local edits, changed = self:CollectReminderEdits(values, ctx.prefill)
            popup:Hide()
            if not changed then
                window:SetStatus(T("No changes to save."), "info")
                return
            end
            local newRaw = self:ApplyReminderEdits(ctx.srcRaw, edits)
            self:CommitTimelineWrite(ctx.note, function()
                return self:RewriteNoteLine(ctx.note.name, ctx.note.personal, ctx.srcLineIndex, ctx.srcRaw, newRaw, ctx.encID)
            end, string.format(T("Saved %s in %s."), label, ctx.note.name))
        else
            local line = self:NewReminderLine(values)
            popup:Hide()
            self:AddLineToPersonalNote(ctx.encID, ctx.difficulty, line, function(name)
                return string.format(T("Added %s to %s."), label, name)
            end)
        end
    end or nil

    popup._deleteAction = ctx.mode == "edit" and function()
        popup:Hide()
        self:DeleteTimelineReminder(blockData, ctx.encID)
    end or nil

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "CENTER")
    popup:Show()
    popup.fightTimeFS:SetText(FightTimeText(self, ctx.encID, ctx.difficulty, ctx.prefill.ph, ctx.prefill.time))
    if editable then
        popup.entries.spellid.editBox:SetFocus()
    end
end

--------------------------------------------------------------------------------
-- SPELLBOOK PICKER
--------------------------------------------------------------------------------

-- TWW removed the classic spellbook globals in favor of C_SpellBook; shim them
-- the same way LibDFramework does (see Libs/LibDFramework-1.0/fw.lua) so this
-- keeps working on both API generations.
local GetNumSpellTabs = GetNumSpellTabs or C_SpellBook.GetNumSpellBookSkillLines
local GetSpellTabInfo = GetSpellTabInfo or function(tabLine)
    local skillLine = C_SpellBook.GetSpellBookSkillLineInfo(tabLine)
    if skillLine then
        return skillLine.name, skillLine.iconID, skillLine.itemIndexOffset, skillLine.numSpellBookItems,
            skillLine.isGuild, skillLine.offSpecID
    end
end
local SpellBookItemTypeMap = Enum.SpellBookItemType and {
    [Enum.SpellBookItemType.Spell] = "SPELL",
    [Enum.SpellBookItemType.None] = "NONE",
    [Enum.SpellBookItemType.Flyout] = "FLYOUT",
    [Enum.SpellBookItemType.FutureSpell] = "FUTURESPELL",
    [Enum.SpellBookItemType.PetAction] = "PETACTION",
} or {}
local GetSpellBookItemInfo = GetSpellBookItemInfo or function(...)
    local si = C_SpellBook.GetSpellBookItemInfo(...)
    if si then
        return SpellBookItemTypeMap[si.itemType] or "NONE",
            (si.itemType == Enum.SpellBookItemType.Flyout or si.itemType == Enum.SpellBookItemType.PetAction) and si.actionID or si.spellID or si.actionID,
            si
    end
end
local BOOKTYPE_SPELL = BOOKTYPE_SPELL or (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or "player"

function NSI:ShowSpellbookPicker(targetPopup)
    if not self.SpellbookPickerPopup then
        local picker = NSI.UI.Pixel.CreateBoxFrame("Frame", "NSRTSpellbookPicker", UIParent)
        picker:SetSize(300, 400)
        picker:SetFrameStrata("TOOLTIP")
        picker:SetMovable(true)
        picker:SetClampedToScreen(true)
        picker:EnableMouse(true)
        picker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        picker:SetBackdropColor(unpack(STYLE.panel))
        picker:SetBackdropBorderColor(unpack(STYLE.panelBorder))

        -- Title bar / drag handle
        local titleBar = CreateFrame("Frame", nil, picker)
        titleBar:SetHeight(22)
        titleBar:SetPoint("TOPLEFT", picker, "TOPLEFT", 1, -1)
        titleBar:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -1, -1)
        titleBar:EnableMouse(true)
        titleBar:SetScript("OnMouseDown", function(_, b) if b == "LeftButton" then picker:StartMoving() end end)
        titleBar:SetScript("OnMouseUp", function() picker:StopMovingOrSizing() end)
        local titleFS = NewFontString(titleBar, STYLE.dialogTitleSize, STYLE.accent)
        titleFS:SetText(T("Pick a spell"))
        titleFS:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
        local xBtn = CreateFrame("Button", nil, picker)
        xBtn:SetSize(16, 16)
        xBtn:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -4, -4)
        xBtn:SetFrameLevel(picker:GetFrameLevel() + 3)
        xBtn:SetNormalFontObject("GameFontNormal")
        xBtn:SetText("×")
        xBtn:SetScript("OnClick", function() picker:Hide() end)

        -- Filter box
        local filterBox = DF:CreateTextEntry(picker, function() end, 250, 20, nil, "NSRTSpellPickerFilter")
        filterBox:SetPoint("TOPLEFT", picker, "TOPLEFT", 10, -30)
        picker.filterBox = filterBox

        -- Scroll frame for spell list.
        -- Anchored to picker with a fixed offset rather than to filterBox (a DF wrapper
        -- table) because native SetPoint only accepts real WoW frame objects.
        -- filterBox top = -30, height = 20, so its bottom is at y=-50; add 4px gap → -54.
        local scrollFrame = CreateFrame("ScrollFrame", "NSRTSpellPickerScroll", picker, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", picker, "TOPLEFT", 10, -54)
        scrollFrame:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -26, 10)
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(260)
        scrollChild:SetHeight(1)
        scrollFrame:SetScrollChild(scrollChild)
        picker.scrollChild = scrollChild
        picker.scrollFrame = scrollFrame

        -- Pool of row buttons (created lazily)
        picker.rowPool = {}
        picker.rows = {}

        local function refreshList()
            local filter = strlower(filterBox:GetText() or filterBox.editbox:GetText() or "")
            -- Gather spells
            local spells = {}
            local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
            for t = 1, numTabs do
                local _, _, offset, numSlots = GetSpellTabInfo(t)
                for s = offset + 1, offset + numSlots do
                    local sType, id = GetSpellBookItemInfo(s, BOOKTYPE_SPELL)
                    if sType == "SPELL" and id then
                        local info = C_Spell.GetSpellInfo(id)
                        if info and info.name then
                            if filter == "" or info.name:lower():find(filter, 1, true) then
                                table.insert(spells, {name = info.name, id = id, icon = info.iconID})
                            end
                        end
                    end
                end
            end
            table.sort(spells, function(a, b) return a.name < b.name end)

            -- Recycle rows
            for _, row in ipairs(picker.rows) do row:Hide() end
            picker.rows = {}

            local rowHeight = 24
            local y = 0
            for i, spell in ipairs(spells) do
                local row = picker.rowPool[i]
                if not row then
                    row = CreateFrame("Button", nil, scrollChild)
                    row:SetHeight(rowHeight)
                    row:EnableMouse(true)
                    row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
                    -- Icon
                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(18, 18)
                    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
                    row.icon = icon
                    -- Name
                    local nameFS = NewFontString(row, STYLE.labelTextSize, STYLE.labelText)
                    nameFS:SetPoint("LEFT", icon, "RIGHT", 4, 0)
                    nameFS:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                    nameFS:SetJustifyH("LEFT")
                    row.nameFS = nameFS
                    picker.rowPool[i] = row
                end
                row:SetWidth(scrollChild:GetWidth())
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
                row.icon:SetTexture(spell.icon)
                row.nameFS:SetText(Colored("[" .. spell.id .. "]", STYLE.textDim) .. " " .. spell.name)
                local spellID = spell.id
                row:SetScript("OnClick", function()
                    if picker._target then
                        local target = picker._target
                        -- Support Components textentry (.spellEntry / .editBox)
                        -- and legacy DF textentry (.spellIDBox / .editbox)
                        local entry = target.spellEntry or target.spellIDBox
                        if entry then
                            if entry.SetValue then
                                entry:SetValue(tostring(spellID))
                            elseif entry.SetText then
                                entry:SetText(tostring(spellID))
                            end
                            local eb = entry.editBox or entry.editbox
                            if eb then
                                local fn = eb:GetScript("OnTextChanged")
                                if fn then fn(eb) end
                            end
                        end
                    end
                    picker:Hide()
                end)
                row:Show()
                table.insert(picker.rows, row)
                y = y + rowHeight
            end
            scrollChild:SetHeight(math.max(1, y))
        end

        filterBox.editbox:SetScript("OnTextChanged", function() refreshList() end)
        picker.refreshList = refreshList

        picker:Hide()
        self.SpellbookPickerPopup = picker
    end

    local picker = self.SpellbookPickerPopup
    picker._target = targetPopup
    picker.filterBox:SetText("")
    picker.refreshList()
    -- Dragging the picker re-anchors it, so a second point would stretch it.
    picker:ClearAllPoints()
    picker:SetPoint("LEFT", targetPopup, "RIGHT", 4, 0)
    picker:Show()
    picker.filterBox.editbox:SetFocus()
end

--------------------------------------------------------------------------------
-- RENAME / DELETE NOTE DIALOGS (right-click a note in the Personal menu)
--------------------------------------------------------------------------------

-- Points the window away from personal note `name`, which was deleted or renamed to newName.
local function ClearWindowNoteReferences(window, name, newName)
    NSI:TimelineUndoForget(name, true)
    if not window or not window.lastPersonal then return end
    for encID, last in pairs(window.lastPersonal) do
        if last == name then window.lastPersonal[encID] = newName end
    end
end

-- Error text when a personal note can't be renamed here, else nil. RenamePersonalNote rebuilds the
-- first line as a header, so a note without one would lose that line.
function NSI:RenameNoteBlocked(name)
    local text = NSRT.PersonalReminders[name]
    if not text then return T("That note no longer exists.") end
    local first = text:match("^[^\n]*")
    if first:find("%S") and not first:find("EncounterID:", 1, true) and not first:find("Name:", 1, true) then
        return T("This note has no header line, so renaming it would delete its first line.")
    end
    return self:TimelineWriteBlocked({name = name, personal = true}, false)
end

function NSI:ShowRenameNoteDialog(window, oldName)
    local blocked = self:RenameNoteBlocked(oldName)
    if blocked then
        if window then window:SetStatus(blocked, "error") end
        return
    end
    local C = NSI.UI.Components
    if not self.RenameNotePopup then
        local W = 300
        local popup = C.CreateFrame(UIParent, W, 116, "NSRTRenameNotePopup")
        popup:SetFrameStrata("TOOLTIP")

        local titleFS = NewFontString(popup, STYLE.dialogTitleSize, STYLE.accent)
        titleFS:SetText(T("Rename note"))
        titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -10)

        local nameEntry = C.CreateTextEntry(popup, nil,
            function() return "" end, function() end,
            W - 24, 22, false, nil, nil, "NSRTRenameNoteEntry")
        nameEntry:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -34)
        popup.nameEntry = nameEntry

        local errorFS = NewFontString(popup, STYLE.dialogHintSize, STYLE.danger)
        errorFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -62)
        errorFS:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -12, -62)
        errorFS:SetWordWrap(true)
        errorFS:SetJustifyV("TOP")
        popup.errorFS = errorFS

        local confirmBtn = C.CreateButton(popup, T("Rename"), function()
            if popup._confirmAction then popup._confirmAction() end
        end, 90, 24)
        confirmBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 10)

        local cancelBtn = C.CreateButton(popup, T("Cancel"), function()
            popup:Hide()
        end, 80, 24)
        cancelBtn:SetPoint("RIGHT", confirmBtn.frame, "LEFT", -6, 0)

        nameEntry.editBox:SetScript("OnEnterPressed", function()
            if popup._confirmAction then popup._confirmAction() end
        end)

        popup:Hide()
        self.RenameNotePopup = popup
    end

    local popup = self.RenameNotePopup
    popup.nameEntry:SetValue(oldName)
    popup.errorFS:SetText("")

    popup._confirmAction = function()
        local blockedNow = NSI:RenameNoteBlocked(oldName)
        if blockedNow then
            popup.errorFS:SetText(blockedNow)
            return
        end
        local newName = popup.nameEntry:GetValue()
        local ok, resultOrErr = NSI:RenamePersonalNote(oldName, newName)
        if not ok then
            local messages = {
                empty   = "Enter a different name.",
                exists  = "A note with that name already exists.",
                missing = "Note no longer exists.",
            }
            popup.errorFS:SetText(T(messages[resultOrErr] or "Rename failed."))
            return
        end
        ClearWindowNoteReferences(window, oldName, resultOrErr)
        NSI:SyncNoteEditor({name = oldName, personal = true}, resultOrErr, true)
        if window then
            NSI:RefreshTimelineForMode()
            window:SetStatus(string.format(T("Renamed %s to %s."), oldName, resultOrErr), "success")
        end
        popup:Hide()
    end

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "CENTER")
    popup:Show()
    popup.nameEntry.editBox:SetFocus()
    popup.nameEntry.editBox:HighlightText()
end

function NSI:ShowDeleteNoteConfirm(window, name)
    local note = {name = name, personal = true}
    local blocked = self:TimelineWriteBlocked(note, self:IsTimelineNoteLoaded(note))
    if blocked then
        if window then window:SetStatus(blocked, "error") end
        return
    end
    local C = NSI.UI.Components
    if not self.DeleteNotePopup then
        local W = 320
        local popup = C.CreateFrame(UIParent, W, 110, "NSRTDeleteNotePopup")
        popup:SetFrameStrata("TOOLTIP")

        local titleFS = NewFontString(popup, STYLE.dialogTitleSize, STYLE.danger)
        titleFS:SetText(T("Delete note"))
        titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -10)

        local msgFS = NewFontString(popup, STYLE.dialogLabelSize, STYLE.textDim)
        msgFS:SetWordWrap(true)
        msgFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -34)
        msgFS:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -12, -34)
        msgFS:SetJustifyH("LEFT")
        msgFS:SetJustifyV("TOP")
        popup.msgFS = msgFS

        local confirmBtn = C.CreateButton(popup, T("Delete"), function()
            if popup._confirmAction then popup._confirmAction() end
        end, 90, 24)
        confirmBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 10)

        local cancelBtn = C.CreateButton(popup, T("Cancel"), function()
            popup:Hide()
        end, 80, 24)
        cancelBtn:SetPoint("RIGHT", confirmBtn.frame, "LEFT", -6, 0)

        popup:Hide()
        self.DeleteNotePopup = popup
    end

    local popup = self.DeleteNotePopup
    popup.msgFS:SetText(Colored(string.format(T("Delete \"%s\"?"), name), STYLE.text) .. "\n" .. T("This can't be undone."))

    popup._confirmAction = function()
        popup:Hide()
        if not NSRT.PersonalReminders[name] then
            if window then window:SetStatus(T("That note no longer exists."), "error") end
            return
        end
        -- Deleting the loaded note unloads it, which reprocesses.
        local blockedNow = NSI:TimelineWriteBlocked(note, NSI:IsTimelineNoteLoaded(note))
        if blockedNow then
            if window then window:SetStatus(blockedNow, "error") end
            return
        end
        NSI:RemoveReminder(name, true)
        ClearWindowNoteReferences(window, name, nil)
        NSI:SyncNoteEditor(note, nil, true)
        if window then
            NSI:RefreshTimelineForMode()
            window:SetStatus(string.format(T("Deleted %s."), name), "success")
        end
    end

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "CENTER")
    popup:Show()
end

function NSI:ShowResetPhaseTimingsConfirm(window, encID)
    if not encID then return end
    local C = NSI.UI.Components
    if not self.ResetPhaseTimingsPopup then
        local popup = C.CreateFrame(UIParent, 320, 110, "NSRTResetPhaseTimingsPopup")
        popup:SetFrameStrata("TOOLTIP")

        local titleFS = NewFontString(popup, STYLE.dialogTitleSize, STYLE.danger)
        titleFS:SetText(T("Reset phase timings"))
        titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -10)

        local msgFS = NewFontString(popup, STYLE.dialogLabelSize, STYLE.textDim)
        msgFS:SetWordWrap(true)
        msgFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -34)
        msgFS:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -12, -34)
        msgFS:SetJustifyH("LEFT")
        msgFS:SetJustifyV("TOP")
        popup.msgFS = msgFS

        local confirmBtn = C.CreateButton(popup, T("Reset"), function()
            if popup._confirmAction then popup._confirmAction() end
        end, 90, 24)
        confirmBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 10)

        local cancelBtn = C.CreateButton(popup, T("Cancel"), function()
            popup:Hide()
        end, 80, 24)
        cancelBtn:SetPoint("RIGHT", confirmBtn.frame, "LEFT", -6, 0)

        popup:Hide()
        self.ResetPhaseTimingsPopup = popup
    end

    local popup = self.ResetPhaseTimingsPopup
    popup.msgFS:SetText(Colored(string.format(T("Reset all phase timings for %s?"), self:GetTimelineEncounterLabel(encID)), STYLE.text)
        .. "\n" .. T("Every phase goes back to its default start, on all difficulties."))
    popup._confirmAction = function()
        popup:Hide()
        if NSRT.PhaseTimings then NSRT.PhaseTimings[encID] = nil end
        NSI:RefreshTimelineForMode()
        if window then window:SetStatus(T("All phase timings for this boss reset."), "success") end
        NSI:UpdatePhaseMarkers()
    end

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "CENTER")
    popup:Show()
end
