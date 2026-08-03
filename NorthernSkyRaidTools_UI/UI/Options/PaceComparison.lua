local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local BossData = NSI.UI.BossData
local C = NSI.UI.Components
local CreateTextEntry = C.CreateTextEntry
local CreateLocalizedSubButton = C.CreateLocalizedSubButton
local ReskinScrollbar = C.ReskinScrollbar
local BuildWidgets = C.BuildWidgets
local options_button_template = Core.options_button_template

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

local function ApplyUIFont(object, size, flags)
    if not object then return end
    if object.SetFont then
        NSI:SetUIFont(object, size, flags or "")
    elseif object.widget and object.widget.SetFont then
        NSI:SetUIFont(object.widget, size, flags or "")
    end
end

local paceExportPopup
local paceImportPopup

local function ShowPaceComparisonExportPopup(text, label)
    if not paceExportPopup then
        paceExportPopup = DF:CreateSimplePanel(UIParent, 800, 400, "|cFF00FFFF" .. NSI:Loc("Export Pace Comparison") .. "|r",
            "NSUIPaceComparisonExportString", { DontRightClickClose = true })
        paceExportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        paceExportPopup:SetFrameLevel(100)

        paceExportPopup.infoLabel = paceExportPopup:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(paceExportPopup.infoLabel, 13, "")
        paceExportPopup.infoLabel:SetTextColor(0.8, 0.8, 0.8, 1)
        paceExportPopup.infoLabel:SetPoint("TOPLEFT", paceExportPopup, "TOPLEFT", 10, -30)

        paceExportPopup.textbox = DF:NewSpecialLuaEditorEntry(paceExportPopup, 280, 80, nil,
            "PaceComparisonExportTextEdit", true, false, true)
        paceExportPopup.textbox:SetPoint("TOPLEFT", paceExportPopup, "TOPLEFT", 10, -50)
        paceExportPopup.textbox:SetPoint("BOTTOMRIGHT", paceExportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(paceExportPopup.textbox)
        DF:ReskinSlider(paceExportPopup.textbox.scroll)
        paceExportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        NSI:SetUIFont(paceExportPopup.textbox.editbox, 13, "OUTLINE")

        local doneBtn = DF:CreateButton(paceExportPopup, function()
            paceExportPopup:Hide()
        end, 280, 20, NSI:Loc("Done"))
        doneBtn:SetPoint("BOTTOM", paceExportPopup, "BOTTOM", 0, 10)
        doneBtn:SetTemplate(options_button_template)
        ApplyUIFont(doneBtn, 11)
    end

    paceExportPopup.infoLabel:SetText(label or "")
    paceExportPopup.textbox:SetText(text or "")
    paceExportPopup.textbox:SetFocus()
    paceExportPopup:Show()
end

local function ShowPaceComparisonImportPopup(onImport)
    if not paceImportPopup then
        paceImportPopup = DF:CreateSimplePanel(UIParent, 800, 400, "|cFF00FFFF" .. NSI:Loc("Import Pace Comparison") .. "|r",
            "NSUIPaceComparisonImportString", { DontRightClickClose = true })
        paceImportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        paceImportPopup:SetFrameLevel(100)

        paceImportPopup.statusLabel = paceImportPopup:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(paceImportPopup.statusLabel, 13, "")
        paceImportPopup.statusLabel:SetTextColor(0.8, 0.8, 0.8, 1)
        paceImportPopup.statusLabel:SetText(NSI:Loc("Paste a Pace Comparison export below and click Import."))
        paceImportPopup.statusLabel:SetPoint("TOPLEFT", paceImportPopup, "TOPLEFT", 10, -30)

        paceImportPopup.textbox = DF:NewSpecialLuaEditorEntry(paceImportPopup, 280, 80, nil,
            "PaceComparisonImportTextEdit", true, false, true)
        paceImportPopup.textbox:SetPoint("TOPLEFT", paceImportPopup, "TOPLEFT", 10, -50)
        paceImportPopup.textbox:SetPoint("BOTTOMRIGHT", paceImportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(paceImportPopup.textbox)
        DF:ReskinSlider(paceImportPopup.textbox.scroll)
        paceImportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        NSI:SetUIFont(paceImportPopup.textbox.editbox, 13, "OUTLINE")

        local importBtn = DF:CreateButton(paceImportPopup, function()
            local success, bossCount, thresholdCount = NSI:ImportPaceComparisonString(paceImportPopup.textbox:GetText())
            if success then
                paceImportPopup:Hide()
                print("|cFF00FFFFNSRT:|r " .. string.format(NSI:Loc("Imported %d Pace Comparison boss(es) with %d threshold(s)."), bossCount, thresholdCount))
                if paceImportPopup.onImport then
                    paceImportPopup.onImport()
                end
            else
                paceImportPopup.statusLabel:SetText("|cFFFF0000" .. NSI:Loc("Invalid Pace Comparison import string.") .. "|r")
            end
        end, 280, 20, NSI:Loc("Import"))
        importBtn:SetPoint("BOTTOM", paceImportPopup, "BOTTOM", 0, 10)
        importBtn:SetTemplate(options_button_template)
        ApplyUIFont(importBtn, 11)
    end

    paceImportPopup.onImport = onImport
    paceImportPopup.statusLabel:SetText(NSI:Loc("Paste a Pace Comparison export below and click Import."))
    paceImportPopup.textbox:SetText("")
    paceImportPopup.textbox:SetFocus()
    paceImportPopup:Show()
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
        label:SetTextColor(0.8, 0.8, 0.8, 1)
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
    local screen = CreateFrame("Frame", "NSUIPaceComparisonEditor", parent, "BackdropTemplate")
    screen:SetAllPoints()
    screen:SetFrameLevel(parent:GetFrameLevel() + 20)
    screen.selectedBoss = GetSelectedBoss()

    local leftWidth = 220
    local title = CreateEditorLabel(screen, "|cFF00FFFFPace|r-Comparison", 14)
    title:SetTextColor(1, 1, 1, 1)
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -8)

    local leftScroll = CreateFrame("ScrollFrame", "$parentPaceComparisonBossScroll", screen, "UIPanelScrollFrameTemplate")
    leftScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -36)
    leftScroll:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 10)
    leftScroll:SetWidth(leftWidth)
    ReskinScrollbar(leftScroll)
    local leftChild = CreateFrame("Frame", nil, leftScroll, "BackdropTemplate")
    leftChild:SetWidth(leftWidth)
    leftChild:SetHeight(1)
    leftChild:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64})
    leftChild:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
    leftScroll:SetScrollChild(leftChild)

    local rightPanel = CreateFrame("Frame", "$parentPaceComparisonEditor", screen)
    rightPanel:SetPoint("TOPLEFT", screen, "TOPLEFT", leftWidth + 42, -8)
    rightPanel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -10, 10)

    screen.collapsedSections = { Season2 = false, Season1 = true }
    local bossRows, sectionRows = {}, {}
    local RefreshBossList

    local function CreateBossRow()
        local row = CreateFrame("Button", nil, leftChild, "BackdropTemplate")
        row:SetHeight(23)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.4, 0.4, 0.4)
        row.__background:SetAlpha(0.5)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", row, "LEFT", 24, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, 13, "")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.enabled = CreateFrame("Button", nil, row, "BackdropTemplate")
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
        row.enabled.fill:SetColorTexture(0, 1, 1, 0.85)
        return row
    end

    local function CreateSeasonRow()
        local row = CreateFrame("Button", nil, leftChild, "BackdropTemplate")
        row:SetHeight(23)
        row:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64})
        row:SetBackdropColor(0.05, 0.30, 0.40, 0.9)
        row.arrow = row:CreateTexture(nil, "OVERLAY")
        row.arrow:SetSize(10, 10)
        row.arrow:SetTexture([[Interface\Buttons\Arrow-Down-Up]])
        row.arrow:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.arrow:SetVertexColor(0, 0.9, 1, 1)
        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, 12, "")
        row.name:SetPoint("LEFT", row.arrow, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.name:SetTextColor(0.2, 0.85, 1, 1)
        row.name:SetJustifyH("LEFT")
        return row
    end

    local bossLabel = CreateEditorLabel(rightPanel, "Expected HP Thresholds", 14, "orange")
    bossLabel:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)

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
                        row.__background:SetVertexColor(0, 1, 1)
                        row.__background:SetAlpha(1)
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

    local resetButton = CreateLocalizedSubButton(screen, "Reset Boss Defaults", function()
        NSI:ResetPaceComparisonBoss(screen.selectedBoss)
        screen:Refresh()
    end, 160, "NSUIPaceComparisonReset")
    resetButton:SetPoint("TOPLEFT", GetUIObject(bossLabel), "BOTTOMLEFT", 0, -10)

    local importButton = CreateLocalizedSubButton(screen, "Import", function()
        ShowPaceComparisonImportPopup(function()
            screen.selectedBoss = GetSelectedBoss()
            screen:Refresh()
        end)
    end, 70, "NSUIPaceComparisonImport")
    importButton:SetPoint("LEFT", resetButton.frame, "RIGHT", 8, 0)

    local exportBossButton = CreateLocalizedSubButton(screen, "Export Boss", function()
        local export = NSI:ExportPaceComparisonString(screen.selectedBoss)
        ShowPaceComparisonExportPopup(export, NSI:Loc("Selected Boss"))
    end, 95, "NSUIPaceComparisonExportBoss")
    exportBossButton:SetPoint("LEFT", importButton.frame, "RIGHT", 8, 0)

    local exportAllButton = CreateLocalizedSubButton(screen, "Export All", function()
        ShowPaceComparisonExportPopup(NSI:ExportAllPaceComparisonString(), NSI:Loc("All Bosses"))
    end, 80, "NSUIPaceComparisonExportAll")
    exportAllButton:SetPoint("LEFT", exportBossButton.frame, "RIGHT", 8, 0)

    local previewButton = CreateLocalizedSubButton(screen, "Preview", function()
        NSI:PreviewPaceComparison()
    end, 70, "NSUIPaceComparisonPreview")
    previewButton:SetPoint("LEFT", exportAllButton.frame, "RIGHT", 8, 0)

    local addLabel = CreateEditorLabel(screen, "Add Threshold", 12, "orange")
    addLabel:SetPoint("TOPLEFT", resetButton.frame, "BOTTOMLEFT", 0, -16)

    NSRT.PaceComparison.NewThreshold = NSRT.PaceComparison.NewThreshold or {}
    local newThreshold = NSRT.PaceComparison.NewThreshold
    local phaseEntry = CreateTextEntry(screen, NSI:Loc("Phase"), function() return newThreshold.phase or 1 end, function(_, value) newThreshold.phase = tonumber(value) or 1 end, 105, 22, true, nil, nil, "NSUIPaceComparisonNewPhase")
    phaseEntry:SetPoint("TOPLEFT", GetUIObject(addLabel), "BOTTOMLEFT", 0, -8)
    local timeEntry = CreateTextEntry(screen, NSI:Loc("Time"), function() return newThreshold.time or 0 end, function(_, value) newThreshold.time = tonumber(value) or 0 end, 110, 22, true, nil, nil, "NSUIPaceComparisonNewTime")
    timeEntry:SetPoint("LEFT", phaseEntry.frame, "RIGHT", 8, 0)
    local unitEntry = CreateTextEntry(screen, NSI:Loc("Boss Unit"), function() return newThreshold.unit or "boss1" end, function(_, value) newThreshold.unit = value ~= "" and value or "boss1" end, 145, 22, false, nil, nil, "NSUIPaceComparisonNewUnit")
    unitEntry:SetPoint("LEFT", timeEntry.frame, "RIGHT", 8, 0)
    local expectedEntry = CreateTextEntry(screen, NSI:Loc("Expected"), function() return newThreshold.expected or 100 end, function(_, value)
        local expected = tonumber(value) or 100
        newThreshold.expected = math.max(0, math.min(expected, 100))
    end, 145, 22, true, 0, 100, "NSUIPaceComparisonNewExpected")
    expectedEntry:SetPoint("LEFT", unitEntry.frame, "RIGHT", 8, 0)

    local addButton = DF:CreateButton(screen, function()
        NSI:AddPaceComparisonThreshold(screen.selectedBoss, newThreshold)
        screen:Refresh()
    end, 55, 20, NSI:Loc("Add"))
    addButton:SetPoint("LEFT", expectedEntry.frame, "RIGHT", 8, 0)
    addButton:SetTemplate(options_button_template)
    ApplyUIFont(addButton, 11)

    local header = CreateFrame("Frame", nil, screen)
    header:SetPoint("TOPLEFT", phaseEntry.frame, "BOTTOMLEFT", 0, -14)
    header:SetSize(610, 18)

    local function HeaderText(text, x, width)
        local label = header:CreateFontString(nil, "OVERLAY")
        label:SetPoint("LEFT", header, "LEFT", x, 0)
        label:SetWidth(width)
        label:SetJustifyH("LEFT")
        NSI:SetUIFont(label, 10, "")
        label:SetText(NSI:Loc(text))
    end
    HeaderText("Phase", 8, 55)
    HeaderText("Time", 98, 55)
    HeaderText("Boss Unit", 188, 80)
    HeaderText("Expected", 318, 90)

    local function refresh(scrollbox, data, offset, totalLines)
        for i = 1, totalLines do
            local rowData = data[i + offset]
            if rowData then
                local line = scrollbox:GetLine(i)
                line:Show()
                line.index = rowData.index
                line.entry = rowData.entry
                line.phaseEntry:SetValue(rowData.entry.phase or 1)
                line.timeEntry:SetValue(rowData.entry.time or 0)
                line.unitEntry:SetValue(rowData.entry.unit or "boss1")
                line.expectedEntry:SetValue(rowData.entry.expected or 100)
            else
                local line = scrollbox.Frames[i]
                line.entry = nil
                line.index = nil
                line:Hide()
            end
        end
    end

    local function createLine(scrollbox, index)
        local line = CreateFrame("Frame", "NSUIPaceComparisonThresholdLine" .. index, scrollbox, "BackdropTemplate")
        line:SetPoint("TOPLEFT", GetUIObject(scrollbox), "TOPLEFT", 1, -((index - 1) * scrollbox.LineHeight) - 1)
        line:SetSize(scrollbox:GetWidth() - 2, scrollbox.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.phaseEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.phase or 1 end, function(_, value)
            if not line.entry then return end
            line.entry.phase = tonumber(value) or 1
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            scrollbox:MasterRefresh()
        end, 70, 20, true)
        line.phaseEntry:SetPoint("LEFT", line, "LEFT", 6, 0)

        line.timeEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.time or 0 end, function(_, value)
            if not line.entry then return end
            line.entry.time = tonumber(value) or 0
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            scrollbox:MasterRefresh()
        end, 70, 20, true)
        line.timeEntry:SetPoint("LEFT", line.phaseEntry.frame, "RIGHT", 20, 0)

        line.unitEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.unit or "boss1" end, function(_, value)
            if not line.entry then return end
            line.entry.unit = value ~= "" and value or "boss1"
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            scrollbox:MasterRefresh()
        end, 105, 20, false)
        line.unitEntry:SetPoint("LEFT", line.timeEntry.frame, "RIGHT", 20, 0)

        line.expectedEntry = CreateTextEntry(line, nil, function() return line.entry and line.entry.expected or 100 end, function(_, value)
            if not line.entry then return end
            local expected = tonumber(value) or 100
            line.entry.expected = math.max(0, math.min(expected, 100))
            NSI:SetPaceComparisonBossModified(screen.selectedBoss)
            scrollbox:MasterRefresh()
        end, 90, 20, true, 0, 100)
        line.expectedEntry:SetPoint("LEFT", line.unitEntry.frame, "RIGHT", 20, 0)

        line.deleteButton = DF:CreateButton(line, function()
            NSI:DeletePaceComparisonThreshold(screen.selectedBoss, line.index)
            screen:Refresh()
        end, 55, 18, NSI:Loc("Delete"))
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -6, 0)
        line.deleteButton:SetTemplate(options_button_template)
        ApplyUIFont(line.deleteButton, 11)

        return line
    end

    local scrollLines = 15
    local scrollbox = DF:CreateScrollBox(screen, "NSUIPaceComparisonThresholdScrollBox", refresh, {}, 610, 300, scrollLines, 24, createLine)
    screen.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    DF:ReskinSlider(scrollbox)
    scrollbox.MasterRefresh = function(self)
        for _, line in ipairs(self.Frames) do
            line.entry = nil
            line.index = nil
            line:Hide()
        end
        self:SetData(GetEditorData(screen))
        self:Refresh()
    end
    for i = 1, scrollLines do
        scrollbox:CreateLine(createLine)
    end

    function screen:Refresh()
        bossLabel:SetText(NSI:Loc("Expected HP Thresholds"))
        self.scrollbox:MasterRefresh()
        RefreshBossList()
    end

    screen:Refresh()
    return screen
end

function NSI:TogglePaceComparisonSettingsWindow(frame)
    if not frame then return end
    if frame.SettingsWindow then
        frame.SettingsWindow:SetShown(not frame.SettingsWindow:IsShown())
        return
    end

    local display = NSRT.PaceComparison.Display
    local window = CreateFrame("Frame", "NSRTPaceComparisonSettings", frame, "BackdropTemplate")
    window:SetFrameStrata("DIALOG")
    window:SetFrameLevel(frame:GetFrameLevel() + 10)
    window:SetWidth(330)
    window:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    window:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    window:SetBackdropBorderColor(0, 1, 1, 0.9)
    window:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -8, -10)

    local title = window:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, 11, "")
    title:SetTextColor(0, 1, 1, 0.85)
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
