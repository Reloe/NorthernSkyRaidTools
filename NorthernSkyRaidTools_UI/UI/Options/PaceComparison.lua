local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Accent = STYLE.Accent
local Core = NSI.UI.Core
local BossData = NSI.UI.BossData
local C = NSI.UI.Components
local CreateTextEntry = C.CreateTextEntry
local CreateLocalizedSubButton = C.CreateLocalizedSubButton
local ReskinScrollbar = C.ReskinScrollbar
local BuildWidgets = C.BuildWidgets

local function GetSelectedBoss()
    local selected = tonumber(NSRT.PaceComparison.SelectedBoss) or 0
    if selected ~= 0 then return selected end

    local bestOrder
    for encID, order in pairs(NSI.EncounterOrder) do
        if not bestOrder or order < bestOrder then
            selected = encID
            bestOrder = order
        end
    end
    NSRT.PaceComparison.SelectedBoss = selected
    return selected
end

local function ShowPaceComparisonExportPopup(text, label)
    C.CreateTextBoxDialog("PaceExport", NSI.UI.Style.AccentCode() .. NSI:Loc("Export Pace Comparison") .. "|r", { readOnly = true })
        :Open(text or "", label)
end

local function ShowPaceComparisonImportPopup(onImport)
    local dialog = C.CreateTextBoxDialog("PaceImport", NSI.UI.Style.AccentCode() .. NSI:Loc("Import Pace Comparison") .. "|r",
        { okText = NSI:Loc("Import"), cancelText = NSI:Loc("Cancel") })
    dialog:Open("", NSI:Loc("Paste a Pace Comparison export below and click Import."), function(text, d)
        local success, bossCount, thresholdCount = NSI:ImportPaceComparisonString(text)
        if success then
            print(NSI.UI.Style.AccentCode() .. "NSRT:|r " .. string.format(NSI:Loc("Imported %d Pace Comparison boss(es) with %d threshold(s)."), bossCount, thresholdCount))
            if onImport then onImport() end
            return true
        end
        d:SetStatus(NSI:Loc("Invalid Pace Comparison import string."), true)
        return false
    end)
end

local function GetUIObject(object)
    return object and (object.widget or object.label or object)
end

local function CreateEditorLabel(parent, text, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(label, size or 11, "")
    label:SetText(NSI:Loc(text))
    if color == "orange" then
        label:SetTextColor(1, 0.65, 0.1, 1)
    else
        label:SetTextColor(unpack(STYLE.text_soft))
    end
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    return label
end

local function GetEditorData(screen)
    local bossSettings = NSI:GetPaceComparisonBossSettings(screen.selectedBoss)
    local thresholds = bossSettings.thresholds or {}

    local data = {}
    for index, entry in ipairs(thresholds) do
        data[#data + 1] = {
            index = index,
            entry = entry,
        }
    end
    return data
end

local function BuildPaceComparisonEditorUI(parent)
    local screen = NSI.UI.Pixel.CreateBoxFrame("Frame", "NSUIPaceComparisonEditor", parent)
    screen:SetAllPoints()
    screen:SetFrameLevel(parent:GetFrameLevel() + 20)
    screen.selectedBoss = GetSelectedBoss()

    local leftWidth = 220
    local title = CreateEditorLabel(screen, NSI.UI.Style.Tint("|cFF00FFFFPace|r-Comparison"), 14)
    NSI.UI.Style.TrackAccentText(title)
    title:SetTextColor(unpack(STYLE.text_color))
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -8)

    local leftScroll = CreateFrame("ScrollFrame", "$parentPaceComparisonBossScroll", screen, "UIPanelScrollFrameTemplate")
    NSI.UI.Components.EnableSmoothScroll(leftScroll)
    leftScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -36)
    leftScroll:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 10)
    leftScroll:SetWidth(leftWidth)
    ReskinScrollbar(leftScroll)
    local leftChild = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, leftScroll)
    leftChild:SetWidth(leftWidth)
    leftChild:SetHeight(1)
    leftChild:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64})
    leftChild:SetBackdropColor(unpack(STYLE.surface_inset_soft))
    leftScroll:SetScrollChild(leftChild)

    local rightPanel = CreateFrame("Frame", "$parentPaceComparisonEditor", screen)
    rightPanel:SetPoint("TOPLEFT", screen, "TOPLEFT", leftWidth + 42, -8)
    rightPanel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -10, 10)

    screen.collapsedSections = { Season2 = false, Season1 = true }
    local bossRows, sectionRows = {}, {}
    local RefreshBossList

    local function CreateBossRow()
        local row = NSI.UI.Pixel.CreateBoxFrame("Button", nil, leftChild)
        row:SetHeight(23)
        C.StyleRow(row)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", row, "LEFT", 24, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, "label", "")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.enabled = NSI.UI.Pixel.CreateBoxFrame("Button", nil, row)
        row.enabled:SetSize(16, 16)
        row.enabled:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.enabled:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        })
        row.enabled:SetBackdropColor(0.04, 0.04, 0.06, 1)
        row.enabled.fill = row.enabled:CreateTexture(nil, "ARTWORK")
        row.enabled.fill:SetPoint("TOPLEFT", row.enabled, "TOPLEFT", 2, -2)
        row.enabled.fill:SetPoint("BOTTOMRIGHT", row.enabled, "BOTTOMRIGHT", -2, 2)
        NSI.UI.Style.PaintAccent(row.enabled.fill, "SetColorTexture", 0.85)
        return row
    end

    local function CreateSeasonRow()
        local row = NSI.UI.Pixel.CreateBoxFrame("Button", nil, leftChild)
        row:SetHeight(23)
        row:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64})
        row:SetBackdropColor(unpack(STYLE.selected_fill))
        row.arrow = row:CreateTexture(nil, "OVERLAY")
        row.arrow:SetSize(10, 10)
        row.arrow:SetTexture([[Interface\Buttons\Arrow-Down-Up]])
        row.arrow:SetPoint("LEFT", row, "LEFT", 4, 0)
        NSI.UI.Style.PaintAccent(row.arrow, "SetVertexColor", 1)
        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, "small", "")
        row.name:SetPoint("LEFT", row.arrow, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        NSI.UI.Style.PaintAccent(row.name, "SetTextColor", 1)
        row.name:SetJustifyH("LEFT")
        return row
    end

    -- Three cards, like the other tabs: boss actions, add a threshold, the threshold list.
    local CARD_W = 628
    local CARD_PAD, CARD_GAP = C.CardPad, C.CardGap
    local cardActions = C.CreateSectionCard(rightPanel, CARD_W, true)
    local cardAdd     = C.CreateSectionCard(rightPanel, CARD_W, true)
    local cardList    = C.CreateSectionCard(rightPanel, CARD_W, true)
    -- Cards fill the right panel: full width, and the list card runs to the bottom, so
    -- nothing can spill out of the window whatever its size.
    cardActions:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)
    cardActions:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, 0)
    cardAdd:SetPoint("TOPLEFT", cardActions, "BOTTOMLEFT", 0, -CARD_GAP)
    cardAdd:SetPoint("TOPRIGHT", cardActions, "BOTTOMRIGHT", 0, -CARD_GAP)
    cardList:SetPoint("TOPLEFT", cardAdd, "BOTTOMLEFT", 0, -CARD_GAP)
    cardList:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)
    for _, card in ipairs({ cardActions, cardAdd, cardList }) do
        card.content:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -(card.headerH + CARD_PAD))
    end
    cardAdd.title:SetText(NSI:Loc("Add Threshold"))
    cardList.title:SetText(NSI:Loc("Thresholds"))
    local bossLabel = cardActions.title

    RefreshBossList = function()
        local current, previous = {}, {}
        for encID, order in pairs(NSI.EncounterOrder) do
            local list = NSI.CurrentEncounterIDs[encID] and current or previous
            list[#list + 1] = { encID = encID, order = order }
        end
        table.sort(current, function(a, b) return a.order < b.order end)
        table.sort(previous, function(a, b) return a.order < b.order end)

        local sections = {
            { key = "Season2", label = NSI:Loc("Season 2"), bosses = current },
            { key = "Season1", label = NSI:Loc("Season 1"), bosses = previous },
        }
        local slot, sectionIndex, bossIndex = 0, 0, 0
        for _, section in ipairs(sections) do
            sectionIndex = sectionIndex + 1
            slot = slot + 1
            local sectionRow = sectionRows[sectionIndex] or CreateSeasonRow()
            sectionRows[sectionIndex] = sectionRow
            sectionRow:ClearAllPoints()
            sectionRow:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 0, -(slot - 1) * 23)
            sectionRow:SetWidth(leftWidth)
            sectionRow.name:SetText(section.label)
            local sectionKey = section.key
            local collapsed = screen.collapsedSections[sectionKey]
            sectionRow.arrow:SetRotation(collapsed and -math.pi / 2 or 0)
            sectionRow:SetScript("OnClick", function()
                screen.collapsedSections[sectionKey] = not screen.collapsedSections[sectionKey]
                RefreshBossList()
            end)
            sectionRow:Show()

            if not collapsed then
                for _, data in ipairs(section.bosses) do
                    bossIndex = bossIndex + 1
                    slot = slot + 1
                    local row = bossRows[bossIndex] or CreateBossRow()
                    bossRows[bossIndex] = row
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 0, -(slot - 1) * 23)
                    row:SetWidth(leftWidth)
                    local encID = data.encID
                    local icon = BossData.BossIcons[encID]
                    row.icon:SetTexture(icon)
                    row.icon:SetShown(icon ~= nil)
                    row.name:SetText(NSI:Loc(NSI.BossNames[encID] or ("Encounter " .. encID)))
                    local enabled = NSI:GetPaceComparisonBossSettings(encID).enabled
                    row.enabled.fill:SetShown(enabled)
                    row.enabled:SetBackdropBorderColor(enabled and 0 or 0.25, enabled and 1 or 0.25, enabled and 1 or 0.25, 1)
                    row.enabled:SetScript("OnClick", function()
                        local settings = NSI:GetPaceComparisonBossSettings(encID)
                        settings.enabled = not settings.enabled
                        RefreshBossList()
                    end)
                    if screen.selectedBoss == encID then
                        row.__background:SetVertexColor(Accent())
                        row.__background:SetAlpha(STYLE.selected_row_alpha)
                    else
                        row.__background:SetVertexColor(0.4, 0.4, 0.4)
                        row.__background:SetAlpha(0.5)
                    end
                    row:SetScript("OnClick", function()
                        screen.selectedBoss = encID
                        NSRT.PaceComparison.SelectedBoss = encID
                        screen:Refresh()
                    end)
                    row:Show()
                end
            end
        end
        for i = bossIndex + 1, #bossRows do bossRows[i]:Hide() end
        for i = sectionIndex + 1, #sectionRows do sectionRows[i]:Hide() end
        leftChild:SetHeight(math.max(1, slot * 23))
    end

    local resetButton = CreateLocalizedSubButton(cardActions.content, "Reset Boss Defaults", function()
        NSI:ResetPaceComparisonBoss(screen.selectedBoss)
        screen:Refresh()
    end, 160, "NSUIPaceComparisonReset")
    resetButton:SetPoint("TOPLEFT", cardActions.content, "TOPLEFT", 0, 0)

    local importButton = CreateLocalizedSubButton(cardActions.content, "Import", function()
        ShowPaceComparisonImportPopup(function()
            screen.selectedBoss = GetSelectedBoss()
            screen:Refresh()
        end)
    end, 70, "NSUIPaceComparisonImport")
    importButton:SetPoint("LEFT", resetButton.frame, "RIGHT", 8, 0)

    local exportBossButton = CreateLocalizedSubButton(cardActions.content, "Export Boss", function()
        local export = NSI:ExportPaceComparisonString(screen.selectedBoss)
        ShowPaceComparisonExportPopup(export, NSI:Loc("Selected Boss"))
    end, 95, "NSUIPaceComparisonExportBoss")
    exportBossButton:SetPoint("LEFT", importButton.frame, "RIGHT", 8, 0)

    local exportAllButton = CreateLocalizedSubButton(cardActions.content, "Export All", function()
        ShowPaceComparisonExportPopup(NSI:ExportAllPaceComparisonString(), NSI:Loc("All Bosses"))
    end, 80, "NSUIPaceComparisonExportAll")
    exportAllButton:SetPoint("LEFT", exportBossButton.frame, "RIGHT", 8, 0)

    local previewButton = CreateLocalizedSubButton(cardActions.content, "Preview", function()
        NSI:PreviewPaceComparison()
    end, 70, "NSUIPaceComparisonPreview")
    previewButton:SetPoint("LEFT", exportAllButton.frame, "RIGHT", 8, 0)

    NSRT.PaceComparison.NewThreshold = NSRT.PaceComparison.NewThreshold or {}
    local newThreshold = NSRT.PaceComparison.NewThreshold
    local phaseEntry = CreateTextEntry(cardAdd.content, NSI:Loc("Phase"), function() return newThreshold.phase or 1 end, function(_, value) newThreshold.phase = tonumber(value) or 1 end, 105, 22, true, nil, nil, "NSUIPaceComparisonNewPhase")
    phaseEntry:SetPoint("TOPLEFT", cardAdd.content, "TOPLEFT", 0, 0)
    local timeEntry = CreateTextEntry(cardAdd.content, NSI:Loc("Time"), function() return newThreshold.time or 0 end, function(_, value) newThreshold.time = tonumber(value) or 0 end, 110, 22, true, nil, nil, "NSUIPaceComparisonNewTime")
    timeEntry:SetPoint("LEFT", phaseEntry.frame, "RIGHT", 8, 0)
    local unitEntry = CreateTextEntry(cardAdd.content, NSI:Loc("Boss Unit"), function() return newThreshold.unit or "boss1" end, function(_, value) newThreshold.unit = value ~= "" and value or "boss1" end, 145, 22, false, nil, nil, "NSUIPaceComparisonNewUnit")
    unitEntry:SetPoint("LEFT", timeEntry.frame, "RIGHT", 8, 0)
    local expectedEntry = CreateTextEntry(cardAdd.content, NSI:Loc("Expected"), function() return newThreshold.expected or 100 end, function(_, value)
        local expected = tonumber(value) or 100
        newThreshold.expected = math.max(0, math.min(expected, 100))
    end, 145, 22, true, 0, 100, "NSUIPaceComparisonNewExpected")
    expectedEntry:SetPoint("LEFT", unitEntry.frame, "RIGHT", 8, 0)

    local addButton = C.CreateButton(cardAdd.content, NSI:Loc("Add"), function()
        NSI:AddPaceComparisonThreshold(screen.selectedBoss, newThreshold)
        screen:Refresh()
    end, 55, 20, nil, nil, "tiny")
    addButton:SetPoint("LEFT", expectedEntry.frame, "RIGHT", 8, 0)

    local header = CreateFrame("Frame", nil, cardList.content)
    header:SetPoint("TOPLEFT", cardList.content, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", cardList.content, "TOPRIGHT", 0, 0)
    header:SetHeight(18)

    -- Columns share the row width: Phase, Time, Boss Unit, Expected, then Delete.
    local COL_FRACTIONS = { 0.17, 0.17, 0.30, 0.24 }
    local COL_PAD, COL_GAP, DELETE_W = 6, 12, 55
    local function ColumnLayout(width)
        local usable = width - COL_PAD * 2 - DELETE_W - COL_GAP * 4
        local xs, ws, x = {}, {}, COL_PAD
        for i, fraction in ipairs(COL_FRACTIONS) do
            ws[i] = math.max(30, math.floor(usable * fraction / 0.88))
            xs[i] = x
            x = x + ws[i] + COL_GAP
        end
        return xs, ws
    end

    local headerLabels = {}
    for i, text in ipairs({ "Phase", "Time", "Boss Unit", "Expected" }) do
        local label = header:CreateFontString(nil, "OVERLAY")
        label:SetJustifyH("LEFT")
        NSI:SetUIFont(label, 10, "")
        label:SetText(NSI:Loc(text))
        headerLabels[i] = label
    end
    header:SetScript("OnSizeChanged", function(_, width)
        local xs, ws = ColumnLayout(width)
        for i, label in ipairs(headerLabels) do
            label:ClearAllPoints()
            label:SetPoint("LEFT", header, "LEFT", xs[i] + 2, 0)
            label:SetWidth(ws[i])
        end
    end)

    local LINE_H = 24
    local LIST_H = 300   -- initial; follows the card once it is laid out
    local scrollObj = C.CreateScrollBox(cardList.content, CARD_W - CARD_PAD * 2, LIST_H)
    scrollObj.frame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    local lines = {}
    local MasterRefresh

    -- Card heights follow their content.
    local function SizeCard(card, contentH)
        card.content:SetHeight(contentH)
        card:SetHeight(card.headerH + CARD_PAD * 2 + contentH)
    end
    SizeCard(cardActions, resetButton.frame:GetHeight())
    SizeCard(cardAdd, math.max(phaseEntry.frame:GetHeight(), 22))
    -- The list card's height comes from its anchors; the scroll box takes what is left
    -- under the column header, and rows stretch to the scroll width.
    cardList.content:SetPoint("BOTTOMLEFT", cardList, "BOTTOMLEFT", CARD_PAD, CARD_PAD)
    cardList.content:SetScript("OnSizeChanged", function(_, width, height)
        if width < 1 or height < 30 then return end
        scrollObj:SetSize(width, height - 22)
        scrollObj.scrollChild:SetWidth(width - 18)
        scrollObj:UpdateScrollBar()
    end)

    local function createLine(index)
        local line = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, scrollObj.scrollChild)
        line:SetPoint("TOPLEFT", scrollObj.scrollChild, "TOPLEFT", 1, -((index - 1) * LINE_H) - 1)
        line:SetPoint("TOPRIGHT", scrollObj.scrollChild, "TOPRIGHT", -1, -((index - 1) * LINE_H) - 1)
        line:SetHeight(LINE_H)
        C.StyleRow(line, STYLE.row_plain)

        line.phaseEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.phase or 1 end, function(_, value)
            if not line.entry then return end
            line.entry.phase = tonumber(value) or 1
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            MasterRefresh()
        end, 70, 20, true)
        line.phaseEntry:SetPoint("LEFT", line, "LEFT", 6, 0)

        line.timeEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.time or 0 end, function(_, value)
            if not line.entry then return end
            line.entry.time = tonumber(value) or 0
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            MasterRefresh()
        end, 70, 20, true)
        line.timeEntry:SetPoint("LEFT", line.phaseEntry.frame, "RIGHT", 20, 0)

        line.unitEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.unit or "boss1" end, function(_, value)
            if not line.entry then return end
            line.entry.unit = value ~= "" and value or "boss1"
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            MasterRefresh()
        end, 105, 20, false)
        line.unitEntry:SetPoint("LEFT", line.timeEntry.frame, "RIGHT", 20, 0)

        line.expectedEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.expected or 100 end, function(_, value)
            if not line.entry then return end
            local expected = tonumber(value) or 100
            line.entry.expected = math.max(0, math.min(expected, 100))
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            MasterRefresh()
        end, 90, 20, true, 0, 100)
        line.expectedEntry:SetPoint("LEFT", line.unitEntry.frame, "RIGHT", 20, 0)

        line.deleteButton = C.CreateButton(line, NSI:Loc("Delete"), function()
            NSI:DeletePaceComparisonThreshold(screen.selectedBoss, line.index)
            screen:Refresh()
        end, 55, 18, nil, nil, "tiny")
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -6, 0)

        -- Columns stretch with the row (same fractions as the header).
        local columnEntries = { line.phaseEntry, line.timeEntry, line.unitEntry, line.expectedEntry }
        line:SetScript("OnSizeChanged", function(_, width)
            local xs, ws = ColumnLayout(width)
            for i, entry in ipairs(columnEntries) do
                entry.frame:ClearAllPoints()
                entry.frame:SetPoint("LEFT", line, "LEFT", xs[i], 0)
                entry.frame:SetWidth(ws[i])
            end
        end)

        return line
    end

    -- Lines are created on demand and reused; the list is short, so no virtualisation.
    MasterRefresh = function()
        local data = GetEditorData(screen)
        for i, rowData in ipairs(data) do
            local line = lines[i]
            if not line then line = createLine(i); lines[i] = line end
            line:Show()
            line.index = rowData.index
            line.entry = rowData.entry
            line.phaseEntry:SetValue(rowData.entry.phase or 1)
            line.timeEntry:SetValue(rowData.entry.time or 0)
            line.unitEntry:SetValue(rowData.entry.unit or "boss1")
            line.expectedEntry:SetValue(rowData.entry.expected or 100)
        end
        for i = #data + 1, #lines do
            local line = lines[i]
            line.entry, line.index = nil, nil
            line:Hide()
        end
        scrollObj.scrollChild:SetHeight(math.max(#data * LINE_H + 2, 1))
        scrollObj:UpdateScrollBar()
    end
    screen.scrollbox = { MasterRefresh = function() MasterRefresh() end }

    function screen:Refresh()
        bossLabel:SetText(NSI:Loc("Expected HP Thresholds"))
        MasterRefresh()
        RefreshBossList()
    end

    screen:Refresh()
    return screen
end

function NSI:TogglePaceComparisonSettingsWindow(frame)
    if not frame then return end
    if frame.SettingsWindow then
        local win = frame.SettingsWindow
        win:SetFrameStrata(NSI.LayoutEditorActive and "FULLSCREEN_DIALOG" or "DIALOG")   -- above the editor overlays
        win:SetShown(not win:IsShown())
        return
    end

    local display = NSRT.PaceComparison.Display
    local window = NSI.UI.Pixel.CreateBoxFrame("Frame", "NSRTPaceComparisonSettings", frame)
    window:SetFrameStrata(NSI.LayoutEditorActive and "FULLSCREEN_DIALOG" or "DIALOG")
    window:SetFrameLevel(frame:GetFrameLevel() + 10)
    window:SetWidth(330)
    window:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    window:SetBackdropColor(unpack(STYLE.surface_panel))
    NSI.UI.Style.PaintAccent(window, "SetBackdropBorderColor", 0.9)
    window:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -8, -10)

    local title = window:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, "tiny", "")
    NSI.UI.Style.PaintAccent(title, "SetTextColor", 0.85)
    title:SetText(NSI:Loc("Pace Comparison Display"))
    title:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -7)

    local closeButton = CreateFrame("Button", nil, window)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -3, -3)
    closeButton:SetNormalFontObject("GameFontNormalSmall")
    closeButton:SetText("x")
    closeButton:SetScript("OnClick", function() window:Hide() end)

    local function FontValues()
        local values = {}
        for _, font in ipairs(NSI.LSM:List("font")) do
            values[#values + 1] = { label = font, value = font }
        end
        return values
    end

    local function RefreshStyle()
        NSI:UpdatePaceComparisonFrameStyle()
        NSI:RefreshPaceComparisonDisplay()
    end

    local function SetColor(key, r, g, b, a)
        display[key] = {r, g, b, a}
        NSI:RefreshPaceComparisonColorCache()
        NSI:RefreshPaceComparisonDisplay()
    end

    local definitions = {
        { Type = "Dropdown", label = "Font", values = FontValues,
            get = function() return display.Font end,
            set = function(_, value) display.Font = value; RefreshStyle() end },
        { Type = "Dropdown", label = "Font Outline", values = Core.build_fontflag_options(),
            get = function() return display.FontFlags end,
            set = function(_, value) display.FontFlags = value; RefreshStyle() end },
        { Type = "Slider", label = "Font Size", min = 8, max = 80,
            get = function() return display.FontSize end,
            set = function(_, value) display.FontSize = value; RefreshStyle() end },
        { Type = "Slider", label = "Line Spacing", min = 0, max = 30,
            get = function() return display.LineSpacing end,
            set = function(_, value) display.LineSpacing = value; NSI:RefreshPaceComparisonDisplay() end },
        { Type = "Slider", label = "Update Interval", min = 0.1, max = 1,
            get = function() return display.RefreshInterval end,
            set = function(_, value)
                display.RefreshInterval = math.max(0.1, math.min(value, 1))
                if NSI.PaceComparisonActive then
                    NSI:SchedulePaceComparisonPhase(NSI.Phase or 1, NSI.PaceComparisonState and NSI.PaceComparisonState.encID)
                end
            end },
        { Type = "Slider", label = "Step Size", min = 0.1, max = 1, step = 0.1,
            get = function() return display.DeltaStep or 0.5 end,
            set = function(_, value)
                display.DeltaStep = value
                RefreshStyle()
            end },
        { Type = "Color", label = "Ahead Color",
            get = function() return unpack(display.AheadColor) end,
            set = function(_, r, g, b, a) SetColor("AheadColor", r, g, b, a) end },
        { Type = "Color", label = "Close Behind Color",
            get = function() return unpack(display.CloseBehindColor) end,
            set = function(_, r, g, b, a) SetColor("CloseBehindColor", r, g, b, a) end },
        { Type = "Color", label = "Behind Color",
            get = function() return unpack(display.BehindColor) end,
            set = function(_, r, g, b, a) SetColor("BehindColor", r, g, b, a) end },
        { Type = "Color", label = "Far Behind Color",
            get = function() return unpack(display.FarBehindColor) end,
            set = function(_, r, g, b, a) SetColor("FarBehindColor", r, g, b, a) end },
    }

    local content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -28)
    content:SetWidth(314)
    local contentHeight = BuildWidgets(content, definitions, 314, "NSRTPaceComparisonSettings")
    content:SetHeight(contentHeight)
    window:SetHeight(contentHeight + 36)
    frame.SettingsWindow = window
end

NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.PaceComparison = {
    BuildEditorUI = BuildPaceComparisonEditorUI,
}
