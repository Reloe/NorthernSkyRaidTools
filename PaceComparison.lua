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

local function GetPaceComparisonColor(key)
    local color = NSRT.PaceComparison.Display[key]
    return CreateColor(color[1], color[2], color[3], color[4])
end

local function GetPaceComparisonColorCurve(expected)
    expected = tonumber(expected) or 100
    expected = math.max(0, math.min(expected, 100))
    local normalizedExpected = expected / 100
    local closeBehind = math.min(normalizedExpected + 0.005, 1)
    local behind = math.min(normalizedExpected + 0.015, 1)
    local epsilon = 0.00001
    local curve = C_CurveUtil.CreateColorCurve()
    if normalizedExpected > 0 then
        curve:AddPoint(0, GetPaceComparisonColor("AheadColor"))
        curve:AddPoint(math.max(normalizedExpected - epsilon, 0), GetPaceComparisonColor("AheadColor"))
    end
    curve:AddPoint(normalizedExpected, GetPaceComparisonColor("CloseBehindColor"))
    if closeBehind > normalizedExpected then
        curve:AddPoint(closeBehind, GetPaceComparisonColor("CloseBehindColor"))
    end
    if closeBehind < 1 then
        curve:AddPoint(math.min(closeBehind + epsilon, 1), GetPaceComparisonColor("BehindColor"))
    end
    if behind > closeBehind then
        curve:AddPoint(behind, GetPaceComparisonColor("BehindColor"))
    end
    if behind < 1 then
        curve:AddPoint(math.min(behind + epsilon, 1), GetPaceComparisonColor("FarBehindColor"))
        curve:AddPoint(1, GetPaceComparisonColor("FarBehindColor"))
    end
    return curve
end

local function SetPaceComparisonPreviewColor(sample, current, expected)
    local colorKey
    if current < expected then
        colorKey = "AheadColor"
    elseif current <= expected + 0.5 then
        colorKey = "CloseBehindColor"
    elseif current <= expected + 1.5 then
        colorKey = "BehindColor"
    else
        colorKey = "FarBehindColor"
    end
    local color = NSRT.PaceComparison.Display[colorKey]
    sample.r, sample.g, sample.b, sample.a = color[1], color[2], color[3], color[4]
end

local function CreatePaceComparisonSample(unit, expected)
    local sample = {
        expected = tonumber(expected) or 100,
    }

    if UnitExists(unit) then
        sample.current = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
        local color = UnitHealthPercent(unit, true, GetPaceComparisonColorCurve(sample.expected))
        if type(color) == "table" and color.GetRGBA then
            sample.r, sample.g, sample.b, sample.a = color:GetRGBA()
        else
            sample.r, sample.g, sample.b, sample.a = UnitHealthPercent(unit, true, GetPaceComparisonColorCurve(sample.expected))
        end
    else
        local current = unit == "boss1" and 78.5 or 66.0
        sample.current = secretwrap(current)
        sample.previewCurrent = current
        SetPaceComparisonPreviewColor(sample, current, sample.expected)
    end

    return sample
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
        line.Label:SetFont(fontPath, fontSize, fontFlags)
        line.Current:SetFont(fontPath, fontSize, fontFlags)
        line.Expected:SetFont(fontPath, fontSize, fontFlags)
        line.Label:SetTextColor(1, 1, 1, 1)
        line.Expected:SetTextColor(1, 1, 1, 1)
    end
end

function NSI:AcquirePaceComparisonLine(index)
    local frame = self:CreatePaceComparisonFrame()
    if frame.lines[index] then return frame.lines[index] end

    local line = CreateFrame("Frame", nil, frame)
    line:SetHeight(30)
    line.Label = line:CreateFontString(nil, "OVERLAY")
    line.Current = line:CreateFontString(nil, "OVERLAY")
    line.Expected = line:CreateFontString(nil, "OVERLAY")

    line.Label:SetPoint("LEFT", line, "LEFT", 0, 0)
    line.Current:SetPoint("LEFT", line.Label, "RIGHT", 8, 0)
    line.Expected:SetPoint("LEFT", line.Current, "RIGHT", 8, 0)

    frame.lines[index] = line
    return line
end

function NSI:RefreshPaceComparisonDisplay()
    if not self.PaceComparisonActive or not NSRT or not NSRT.PaceComparison then
        return
    end
    local frame = self:CreatePaceComparisonFrame()
    local state = self.PaceComparisonState
    if not state then return end

    self:UpdatePaceComparisonFrameStyle()

    local display = NSRT.PaceComparison.Display
    local fontPath = GetPaceComparisonFontPath(display)
    local fontSize = display.FontSize
    local fontFlags = display.FontFlags
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
            line:SetWidth(360)
            line.Label:SetFont(fontPath, fontSize, fontFlags)
            line.Current:SetFont(fontPath, fontSize, fontFlags)
            line.Expected:SetFont(fontPath, fontSize, fontFlags)
            line.Current:ClearAllPoints()
            if showUnitLabels then
                line.Current:SetPoint("LEFT", line.Label, "RIGHT", 8, 0)
            else
                line.Current:SetPoint("LEFT", line, "LEFT", 0, 0)
            end

            local expected = state.activeExpected[unit]
            local sample = state.samples[unit]
            line.Label:SetText(showUnitLabels and (unit .. ":") or "")
            if sample then
                if self.PaceComparisonPreview and sample.previewCurrent then
                    SetPaceComparisonPreviewColor(sample, sample.previewCurrent, sample.expected)
                end
                line.Current:SetFormattedText("%.1f%%", sample.current)
                line.Current:SetTextColor(sample.r or 1, sample.g or 1, sample.b or 0, sample.a or 1)
                line.Expected:SetText(string.format("/ %.1f%%", sample.expected))
            else
                line.Current:SetTextColor(1, 1, 0, 1)
                line.Current:SetText("--")
                line.Expected:SetText(expected and string.format("/ %.1f%%", expected) or "/ --")
            end
            line:Show()
        end
    end

    for i = shown + 1, #frame.lines do
        frame.lines[i]:Hide()
    end

    frame:SetSize(360, math.max(30, shown * (fontSize + lineSpacing)))
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
    state.activeExpected = {}
    state.samples = {}
    phase = tonumber(phase) or 1
    local now = GetTime()
    local phaseStart = self.PhaseSwapTime or now
    local elapsed = now - phaseStart

    local function ApplyThresholdSample(entry)
        if self.PaceComparisonState ~= state then return end
        local unit = entry.unit or "boss1"
        if UnitExists(unit) or self.PaceComparisonPreview then
            state.activeExpected[unit] = tonumber(entry.expected) or 100
            state.samples[unit] = CreatePaceComparisonSample(unit, entry.expected)
            self:RefreshPaceComparisonDisplay()
            return
        end
    end

    for _, entry in ipairs(state.thresholds) do
        if (tonumber(entry.phase) or 1) == phase then
            local entryTime = tonumber(entry.time) or 0
            local delay = entryTime - elapsed
            if delay <= 0 then
                ApplyThresholdSample(entry)
            else
                self.PaceComparisonTimers[#self.PaceComparisonTimers + 1] = C_Timer.NewTimer(delay, function()
                    ApplyThresholdSample(entry)
                end)
            end
        end
    end

    self:RefreshPaceComparisonDisplay()
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
        activeExpected = {},
        samples = {},
    }

    self:CreatePaceComparisonFrame():Show()
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
        self.PaceComparisonState = {
            encID = NSRT.PaceComparison.SelectedBoss or 0,
            thresholds = {
                { phase = 1, time = 0, unit = "boss1", expected = 80 },
                { phase = 1, time = 0, unit = "boss2", expected = 65 },
            },
            activeExpected = {
                boss1 = 80,
                boss2 = 65,
            },
            samples = {
                boss1 = CreatePaceComparisonSample("boss1", 80),
                boss2 = CreatePaceComparisonSample("boss2", 65),
            },
        }
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
