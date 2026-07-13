local _, NSI = ...

NSI.PaceComparisonDefaults = {
    -- Add default entries here. User-edited boss tables are not overwritten.
    -- [3470] = { -- Nek'zali the Soulcoiler
    --     thresholds = {
    --         { phase = 1, time = 30, unit = "boss1", expected = 85 },
    --     },
    -- },
}

local function SortThresholds(a, b)
    local phaseA = tonumber(a.phase) or 1
    local phaseB = tonumber(b.phase) or 1
    if phaseA ~= phaseB then return phaseA < phaseB end

    local timeA = tonumber(a.time) or 0
    local timeB = tonumber(b.time) or 0
    if timeA ~= timeB then return timeA < timeB end

    return tostring(a.unit or "") < tostring(b.unit or "")
end

local function GetPaceComparisonBossSettings(encID)
    if not NSRT or not NSRT.PaceComparison then return end
    NSRT.PaceComparison.Bosses = NSRT.PaceComparison.Bosses or {}
    NSRT.PaceComparison.Bosses[encID] = NSRT.PaceComparison.Bosses[encID] or {
        enabled = false,
        userModified = false,
        thresholds = {},
    }
    return NSRT.PaceComparison.Bosses[encID]
end

local function CopyThresholds(thresholds)
    local copy = {}
    for index, entry in ipairs(thresholds or {}) do
        local expected = tonumber(entry.expected) or 100
        copy[index] = {
            phase = tonumber(entry.phase) or 1,
            time = tonumber(entry.time) or 0,
            unit = entry.unit or "boss1",
            expected = math.max(0, math.min(expected, 100)),
        }
    end
    table.sort(copy, SortThresholds)
    return copy
end

local function FormatPaceComparisonNumber(value, decimals)
    value = tonumber(value) or 0
    local formatted = string.format("%." .. decimals .. "f", value)
    formatted = formatted:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
    return formatted
end

function NSI:ExportPaceComparisonString(encID)
    if not NSRT or not NSRT.PaceComparison then return "" end
    encID = tonumber(encID)
    local bossSettings = encID and NSRT.PaceComparison.Bosses and NSRT.PaceComparison.Bosses[encID]
    if not encID or not bossSettings then return "" end

    local lines = {"EncounterID:" .. encID}
    for _, entry in ipairs(CopyThresholds(bossSettings.thresholds)) do
        local line = "phase:" .. FormatPaceComparisonNumber(entry.phase, 1)
            .. ";time:" .. FormatPaceComparisonNumber(entry.time, 1)
            .. ";hp:" .. FormatPaceComparisonNumber(entry.expected, 1)
        if entry.unit and entry.unit ~= "" and entry.unit ~= "boss1" then
            line = line .. ";unit:" .. entry.unit
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

function NSI:ExportAllPaceComparisonString()
    if not NSRT or not NSRT.PaceComparison then return "" end
    local encIDs = {}
    for encID, bossSettings in pairs(NSRT.PaceComparison.Bosses or {}) do
        if bossSettings.thresholds and #bossSettings.thresholds > 0 then
            encIDs[#encIDs + 1] = tonumber(encID) or encID
        end
    end
    table.sort(encIDs)

    local exports = {}
    for _, encID in ipairs(encIDs) do
        exports[#exports + 1] = self:ExportPaceComparisonString(encID)
    end
    return table.concat(exports, "\n\n")
end

function NSI:ImportPaceComparisonString(text)
    if not NSRT or not NSRT.PaceComparison then return end
    local imported = {}
    local currentEncID

    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            local encID = tonumber(line:lower():match("^encounterid%s*:%s*(%d+)"))
            if encID then
                if self.BossNames and self.BossNames[encID] then
                    currentEncID = encID
                    imported[currentEncID] = imported[currentEncID] or {}
                else
                    currentEncID = nil
                end
            elseif currentEncID then
                local lowerLine = line:lower()
                local phase = tonumber(lowerLine:match("phase%s*:%s*([%d%.]+)"))
                local time = tonumber(lowerLine:match("time%s*:%s*([%d%.]+)"))
                local expected = tonumber(lowerLine:match("hp%s*:%s*([%d%.]+)"))
                if phase and time and expected then
                    local unit = line:match("[Uu][Nn][Ii][Tt]%s*:%s*([^;]+)")
                    unit = unit and strtrim(unit) or "boss1"
                    imported[currentEncID][#imported[currentEncID] + 1] = {
                        phase = phase,
                        time = time,
                        unit = unit ~= "" and unit or "boss1",
                        expected = math.max(0, math.min(expected, 100)),
                    }
                end
            end
        end
    end

    local bossCount, thresholdCount = 0, 0
    for encID, thresholds in pairs(imported) do
        if #thresholds > 0 then
            local settings = GetPaceComparisonBossSettings(encID)
            settings.enabled = true
            settings.userModified = true
            settings.thresholds = CopyThresholds(thresholds)
            bossCount = bossCount + 1
            thresholdCount = thresholdCount + #settings.thresholds
        end
    end

    if bossCount == 0 then
        return false, 0, 0
    end
    return true, bossCount, thresholdCount
end

function NSI:ApplyDefaultPaceComparisonData()
    if not NSRT or not NSRT.PaceComparison then
        return
    end
    NSRT.PaceComparison.Bosses = NSRT.PaceComparison.Bosses or {}

    for encID, defaults in pairs(self.PaceComparisonDefaults) do
        local settings = GetPaceComparisonBossSettings(encID)
        if settings and not settings.userModified then
            if defaults.enabled ~= nil then
                settings.enabled = defaults.enabled
            end
            settings.thresholds = CopyThresholds(defaults.thresholds)
        end
    end
end

function NSI:GetPaceComparisonBossSettings(encID)
    return GetPaceComparisonBossSettings(tonumber(encID) or 0)
end

function NSI:SetPaceComparisonBossModified(encID)
    local settings = GetPaceComparisonBossSettings(tonumber(encID) or 0)
    if settings then
        settings.userModified = true
        table.sort(settings.thresholds, SortThresholds)
    end
end

function NSI:AddPaceComparisonThreshold(encID, data)
    local settings = GetPaceComparisonBossSettings(tonumber(encID) or 0)
    if not settings then return end
    settings.thresholds = settings.thresholds or {}
    local expected = tonumber(data.expected) or 100
    settings.thresholds[#settings.thresholds + 1] = {
        phase = tonumber(data.phase) or 1,
        time = tonumber(data.time) or 0,
        unit = data.unit and data.unit ~= "" and data.unit or "boss1",
        expected = math.max(0, math.min(expected, 100)),
    }
    self:SetPaceComparisonBossModified(encID)
end

function NSI:DeletePaceComparisonThreshold(encID, index)
    local settings = GetPaceComparisonBossSettings(tonumber(encID) or 0)
    if not settings or not settings.thresholds then return end
    table.remove(settings.thresholds, index)
    self:SetPaceComparisonBossModified(encID)
end

function NSI:ResetPaceComparisonBoss(encID)
    encID = tonumber(encID) or 0
    local settings = GetPaceComparisonBossSettings(encID)
    if not settings then return end
    settings.userModified = false
    settings.thresholds = CopyThresholds(self.PaceComparisonDefaults[encID] and self.PaceComparisonDefaults[encID].thresholds or {})
end

function NSI:ResetAllPaceComparisonBosses()
    if not NSRT or not NSRT.PaceComparison then return end
    for encID in pairs(NSRT.PaceComparison.Bosses) do
        self:ResetPaceComparisonBoss(encID)
    end
    self:ApplyDefaultPaceComparisonData()
end

local function GetPaceComparisonFontPath(settings)
    local font = settings.Font
    if NSI.LSM then
        font = NSI.LSM:Fetch("font", font, true) or font
    end
    return NSI:ValidateFontPath(font)
end

function NSI:CreatePaceComparisonFrame()
    if self.PaceComparisonFrame then return self.PaceComparisonFrame end

    local frame = CreateFrame("Frame", "NSRTPaceComparisonFrame", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("HIGH")
    frame:SetSize(260, 30)
    frame.lines = {}
    frame:Hide()

    self.PaceComparisonFrame = frame
    return frame
end

local function BuildPaceComparisonColorCache()
    local display = NSRT.PaceComparison.Display
    local cache = {}
    for _, key in ipairs({"AheadColor", "CloseBehindColor", "BehindColor", "FarBehindColor"}) do
        local color = display[key]
        cache[key] = {
            r = color[1],
            g = color[2],
            b = color[3],
            hidden = CreateColor(color[1], color[2], color[3], 0),
            shown = CreateColor(color[1], color[2], color[3], 1),
        }
    end
    return cache
end

function NSI:RefreshPaceComparisonColorCache()
    self.PaceComparisonColorCache = BuildPaceComparisonColorCache()
end

local function GetPaceComparisonDeltaColorKey(delta)
    if delta < 0 then
        return "AheadColor"
    elseif delta <= 0.5 then
        return "CloseBehindColor"
    elseif delta <= 1.5 then
        return "BehindColor"
    end
    return "FarBehindColor"
end

local function FormatPaceComparisonDeltaLabel(tenth)
    if tenth == 0 then return "0%" end
    local sign = tenth > 0 and "+" or "-"
    local absoluteTenth = math.abs(tenth)
    if absoluteTenth % 10 == 0 then
        return sign .. (absoluteTenth / 10) .. "%"
    end
    return sign .. string.format("%.1f%%", absoluteTenth / 10)
end

local function GetPaceComparisonDeltaAlphaCurve(expected, tenth)
    expected = tonumber(expected) or 100
    expected = math.max(0, math.min(expected, 100))
    local delta = tenth / 10
    local lower = (expected + delta - 0.05) / 100
    local upper = (expected + delta + 0.05) / 100
    local colorKey = GetPaceComparisonDeltaColorKey(delta)
    local epsilon = 0.00001
    local color = NSI.PaceComparisonColorCache[colorKey]
    local hidden = color.hidden
    local shown = color.shown
    local curve = C_CurveUtil.CreateColorCurve()

    if upper <= 0 or lower >= 1 then
        curve:AddPoint(0, hidden)
        curve:AddPoint(1, hidden)
        return curve
    end

    lower = math.max(lower, 0)
    upper = math.min(upper, 1)

    if lower > 0 then
        curve:AddPoint(0, hidden)
        curve:AddPoint(math.max(lower - epsilon, 0), hidden)
        curve:AddPoint(lower, shown)
    else
        curve:AddPoint(0, shown)
    end

    curve:AddPoint(upper, shown)

    if upper < 1 then
        curve:AddPoint(math.min(upper + epsilon, 1), hidden)
        curve:AddPoint(1, hidden)
    end

    return curve
end

local function GetPaceComparisonOverflowAlphaCurve(expected, isBehind)
    expected = tonumber(expected) or 100
    expected = math.max(0, math.min(expected, 100))
    local epsilon = 0.00001
    local colorKey = isBehind and "FarBehindColor" or "AheadColor"
    local color = NSI.PaceComparisonColorCache[colorKey]
    local hidden = color.hidden
    local shown = color.shown
    local curve = C_CurveUtil.CreateColorCurve()

    if isBehind then
        local lower = (expected + 5.05) / 100
        if lower >= 1 then
            curve:AddPoint(0, hidden)
            curve:AddPoint(1, hidden)
            return curve
        end

        curve:AddPoint(0, hidden)
        if lower > 0 then
            curve:AddPoint(math.max(lower - epsilon, 0), hidden)
        end
        curve:AddPoint(math.max(lower, 0), shown)
        curve:AddPoint(1, shown)
    else
        local upper = (expected - 5.05) / 100
        if upper <= 0 then
            curve:AddPoint(0, hidden)
            curve:AddPoint(1, hidden)
            return curve
        end

        curve:AddPoint(0, shown)
        curve:AddPoint(math.min(upper, 1), shown)
        if upper < 1 then
            curve:AddPoint(math.min(upper + epsilon, 1), hidden)
        end
        curve:AddPoint(1, hidden)
    end

    return curve
end

local function CreatePaceComparisonSample(unit, expected)
    local sample = {
        expected = tonumber(expected) or 100,
    }

    if not UnitExists(unit) then
        local current = unit == "boss1" and 78.5 or 66.0
        sample.previewCurrent = current
    end

    return sample
end

local function UpdatePaceComparisonDeltaLabels(line, unit, sample, isPreview)
    if not line.Deltas then return end
    local current = sample and sample.previewCurrent
    local roundedTenth = current and math.floor(((current - sample.expected) * 10) + 0.5)
    local unitExists = sample and UnitExists(unit)

    for tenth = -50, 50 do
        local label = line.Deltas[tenth]
        if sample then
            if isPreview and roundedTenth then
                local delta = tenth / 10
                local color = NSI.PaceComparisonColorCache[GetPaceComparisonDeltaColorKey(delta)]
                label:SetTextColor(color.r, color.g, color.b, roundedTenth == tenth and 1 or 0)
            elseif unitExists then
                local r, g, b, a = UnitHealthPercent(unit, true, GetPaceComparisonDeltaAlphaCurve(sample.expected, tenth))
                if type(r) == "table" and r.GetRGBA then
                    label:SetTextColor(r:GetRGBA())
                else
                    label:SetTextColor(r, g, b, a)
                end
            else
                label:SetTextColor(1, 1, 1, 0)
            end
        else
            label:SetTextColor(1, 1, 1, 0)
        end
    end

    if not line.OverflowDeltas then return end
    for _, data in ipairs(line.OverflowDeltas) do
        local label = data.Label
        if sample then
            local color = NSI.PaceComparisonColorCache[data.ColorKey]
            if isPreview and roundedTenth then
                local visible = (data.IsBehind and roundedTenth > 50) or (not data.IsBehind and roundedTenth < -50)
                label:SetTextColor(color.r, color.g, color.b, visible and 1 or 0)
            elseif unitExists then
                local r, g, b, a = UnitHealthPercent(unit, true, GetPaceComparisonOverflowAlphaCurve(sample.expected, data.IsBehind))
                if type(r) == "table" and r.GetRGBA then
                    label:SetTextColor(r:GetRGBA())
                else
                    label:SetTextColor(r, g, b, a)
                end
            else
                label:SetTextColor(color.r, color.g, color.b, 0)
            end
        else
            label:SetTextColor(1, 1, 1, 0)
        end
    end
end

local function ApplyPaceComparisonLineStyle(line, fontPath, fontSize, fontFlags)
    line.Label:SetFont(fontPath, fontSize, fontFlags)
    for tenth = -50, 50 do
        if line.Deltas and line.Deltas[tenth] then
            line.Deltas[tenth]:SetFont(fontPath, fontSize, fontFlags)
            line.Deltas[tenth]:SetText(FormatPaceComparisonDeltaLabel(tenth))
        end
    end
    if line.OverflowDeltas then
        for _, data in ipairs(line.OverflowDeltas) do
            data.Label:SetFont(fontPath, fontSize, fontFlags)
            data.Label:SetText(data.Text)
        end
    end
    line.Label:SetTextColor(1, 1, 1, 1)
end

function NSI:UpdatePaceComparisonFrameStyle()
    if not NSRT or not NSRT.PaceComparison then return end
    local frame = self:CreatePaceComparisonFrame()
    local settings = NSRT.PaceComparison.Display
    local fontPath = GetPaceComparisonFontPath(settings)
    local fontSize = settings.FontSize
    local fontFlags = settings.FontFlags

    frame:ClearAllPoints()
    frame:SetPoint(settings.Anchor, UIParent, settings.relativeTo, settings.xOffset, settings.yOffset)

    for _, line in ipairs(frame.lines) do
        ApplyPaceComparisonLineStyle(line, fontPath, fontSize, fontFlags)
    end
end

function NSI:AcquirePaceComparisonLine(index)
    local frame = self:CreatePaceComparisonFrame()
    if frame.lines[index] then return frame.lines[index] end

    local line = CreateFrame("Frame", nil, frame)
    line:SetHeight(30)
    line.Label = line:CreateFontString(nil, "OVERLAY")
    line.Deltas = {}
    line.OverflowDeltas = {}

    line.Label:SetPoint("LEFT", line, "LEFT", 0, 0)
    for tenth = -50, 50 do
        local label = line:CreateFontString(nil, "OVERLAY")
        label:SetPoint("LEFT", line.Label, "RIGHT", 8, 0)
        label:SetTextColor(1, 1, 1, 0)
        line.Deltas[tenth] = label
    end
    local aheadOverflow = line:CreateFontString(nil, "OVERLAY")
    aheadOverflow:SetPoint("LEFT", line.Label, "RIGHT", 8, 0)
    aheadOverflow:SetTextColor(1, 1, 1, 0)
    line.OverflowDeltas[1] = { Label = aheadOverflow, Text = "> -5%", ColorKey = "AheadColor", IsBehind = false }

    local behindOverflow = line:CreateFontString(nil, "OVERLAY")
    behindOverflow:SetPoint("LEFT", line.Label, "RIGHT", 8, 0)
    behindOverflow:SetTextColor(1, 1, 1, 0)
    line.OverflowDeltas[2] = { Label = behindOverflow, Text = "> +5%", ColorKey = "FarBehindColor", IsBehind = true }

    if NSRT and NSRT.PaceComparison then
        local settings = NSRT.PaceComparison.Display
        ApplyPaceComparisonLineStyle(line, GetPaceComparisonFontPath(settings), settings.FontSize, settings.FontFlags)
    end

    frame.lines[index] = line
    return line
end

function NSI:RefreshPaceComparisonDisplay()
    if not self.PaceComparisonActive then
        return
    end
    local frame = self:CreatePaceComparisonFrame()
    local state = self.PaceComparisonState
    if not state then return end

    local display = NSRT.PaceComparison.Display
    local fontSize = display.FontSize
    local lineSpacing = display.LineSpacing
    local units = {}
    for unit in pairs(state.samples) do
        units[#units + 1] = unit
    end
    table.sort(units)
    local showUnitLabels = #units > 1
    local shown = 0

    for _, unit in ipairs(units) do
        if UnitExists(unit) or self.PaceComparisonPreview then
            shown = shown + 1
            local line = self:AcquirePaceComparisonLine(shown)
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -((shown - 1) * (fontSize + lineSpacing)))
            line:SetWidth(showUnitLabels and 240 or 180)

            local sample = state.samples[unit]
            line.Label:SetText(showUnitLabels and (unit .. ":") or "")
            line.Label:Show()
            if sample then
                UpdatePaceComparisonDeltaLabels(line, unit, sample, self.PaceComparisonPreview)
            else
                UpdatePaceComparisonDeltaLabels(line)
            end
            line:Show()
        end
    end

    for i = shown + 1, #frame.lines do
        frame.lines[i]:Hide()
    end

    frame:SetSize(showUnitLabels and 240 or 180, math.max(30, shown * (fontSize + lineSpacing)))
    frame:SetShown(shown > 0 or self.PaceComparisonPreview)
end

function NSI:CancelPaceComparisonTimers()
    if self.PaceComparisonTimers then
        for _, timer in ipairs(self.PaceComparisonTimers) do
            timer:Cancel()
        end
    end
    self.PaceComparisonTimers = {}

    if self.PaceComparisonTicker then
        self.PaceComparisonTicker:Cancel()
        self.PaceComparisonTicker = nil
    end
end

function NSI:SchedulePaceComparisonPhase(phase, encID)
    if not self.PaceComparisonActive or not self.PaceComparisonState then
        return
    end
    self:CancelPaceComparisonTimers()
    local state = self.PaceComparisonState
    phase = tonumber(phase) or 1
    state.samples = {}

    local function RefreshPhaseSamples()
        if self.PaceComparisonState ~= state then return end
        local now = GetTime()
        local phaseStart = self.PhaseSwapTime or now
        local elapsed = now - phaseStart
        local expectedByUnit = {}

        for _, entry in ipairs(state.thresholds) do
            if (tonumber(entry.phase) or 1) == phase then
                local unit = entry.unit or "boss1"
                local entryTime = tonumber(entry.time) or 0
                local expected = tonumber(entry.expected) or 100
                local data = expectedByUnit[unit]
                if not data then
                    data = {}
                    expectedByUnit[unit] = data
                end

                if entryTime <= elapsed then
                    if not data.previous or entryTime >= data.previous.time then
                        data.previous = { time = entryTime, expected = expected }
                    end
                elseif not data.next or entryTime < data.next.time then
                    data.next = { time = entryTime, expected = expected }
                end
            end
        end

        state.samples = {}
        for unit, data in pairs(expectedByUnit) do
            local expected
            if data.previous and data.next and data.next.time ~= data.previous.time then
                local progress = (elapsed - data.previous.time) / (data.next.time - data.previous.time)
                expected = data.previous.expected + ((data.next.expected - data.previous.expected) * progress)
            elseif data.previous then
                expected = data.previous.expected
            elseif data.next then
                expected = data.next.expected
            end

            if expected and (UnitExists(unit) or self.PaceComparisonPreview) then
                expected = math.max(0, math.min(expected, 100))
                state.samples[unit] = CreatePaceComparisonSample(unit, expected)
            end
        end

        self:RefreshPaceComparisonDisplay()
    end

    RefreshPhaseSamples()
    self.PaceComparisonTicker = C_Timer.NewTicker(NSRT.PaceComparison.Display.RefreshInterval, RefreshPhaseSamples)
end

function NSI:StartPaceComparison(encID, diff)
    encID = tonumber(encID) or self.EncounterID
    local allowedDifficulty = 16
    local _, _, instanceDifficultyID = GetInstanceInfo()
    diff = instanceDifficultyID or diff or self:DifficultyCheck({allowedDifficulty})
    if diff ~= allowedDifficulty then
        self:StopPaceComparison()
        return
    end

    local bossSettings = GetPaceComparisonBossSettings(encID)
    if not bossSettings or not bossSettings.enabled then
        self:StopPaceComparison()
        return
    end

    local thresholds = CopyThresholds(bossSettings.thresholds)
    if #thresholds == 0 then
        self:StopPaceComparison()
        return
    end

    self.PaceComparisonActive = true
    self.PaceComparisonState = {
        encID = encID,
        thresholds = thresholds,
        samples = {},
    }
    self:RefreshPaceComparisonColorCache()

    self:CreatePaceComparisonFrame():Show()
    self:UpdatePaceComparisonFrameStyle()
    self:SchedulePaceComparisonPhase(self.Phase or 1, encID)
end

function NSI:StopPaceComparison()
    self.PaceComparisonActive = false
    self.PaceComparisonState = nil
    self:CancelPaceComparisonTimers()
    if self.PaceComparisonFrame then
        self.PaceComparisonFrame:Hide()
    end
end

function NSI:OnPaceComparisonPhase(phase, encID, testrun)
    if testrun or not self.PaceComparisonActive then return end
    if encID ~= (self.PaceComparisonState and self.PaceComparisonState.encID) then return end
    C_Timer.After(0, function()
        if self.PaceComparisonActive and self.PaceComparisonState and self.PaceComparisonState.encID == encID then
            self:SchedulePaceComparisonPhase(phase, encID)
        end
    end)
end

function NSI:PreviewPaceComparison()
    self.PaceComparisonPreview = not self.PaceComparisonPreview
    local frame = self:CreatePaceComparisonFrame()
    if self.PaceComparisonPreview then
        self.PaceComparisonActive = true
        self:RefreshPaceComparisonColorCache()
        self.PaceComparisonState = {
            encID = NSRT.PaceComparison.SelectedBoss or 0,
            thresholds = {
                { phase = 1, time = 0, unit = "boss1", expected = 80 },
                { phase = 1, time = 0, unit = "boss2", expected = 65 },
            },
            samples = {
                boss1 = CreatePaceComparisonSample("boss1", 80),
                boss2 = CreatePaceComparisonSample("boss2", 65),
            },
        }
        self:UpdatePaceComparisonFrameStyle()
        self:RefreshPaceComparisonDisplay()
        self:MakeDraggable(frame, NSRT.PaceComparison.Display, true)
    else
        self:MakeDraggable(frame, NSRT.PaceComparison.Display, false)
        self.PaceComparisonActive = false
        self.PaceComparisonState = nil
        frame:Hide()
    end
end

NSI.RegisterCallback("NSRT_PaceComparison", "NSRT_PHASE", function(_, phase, encID, testrun)
    NSI:OnPaceComparisonPhase(phase, encID, testrun)
end)
