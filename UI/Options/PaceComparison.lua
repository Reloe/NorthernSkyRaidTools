local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local BossData = NSI.UI.BossData
local C = NSI.UI.Components
local CreateTextEntry = C.CreateTextEntry
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template = Core.options_switch_template
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

local function BuildFontOptions()
    local options = {}
    for _, name in ipairs(NSI.LSM:List("font")) do
        options[#options + 1] = {
            label = name,
            value = name,
            onclick = function()
                NSRT.PaceComparison.Display.Font = name
                NSI:UpdatePaceComparisonFrameStyle()
            end,
        }
    end
    return options
end

local function BuildFontFlagOptions()
    local options = {}
    for _, option in ipairs(Core.build_fontflag_options()) do
        local value = option.value
        options[#options + 1] = {
            label = option.label == "None" and NSI:Loc("None") or option.label,
            value = value,
            onclick = function()
                NSRT.PaceComparison.Display.FontFlags = value
                NSI:UpdatePaceComparisonFrameStyle()
            end,
        }
    end
    return options
end

local function AddDisplayOptions(options)
    local display = NSRT.PaceComparison.Display
    options[#options + 1] = { type = "label", get = function() return "Pace Comparison Display" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") }
    options[#options + 1] = {
        type = "button",
        name = "Preview/Unlock",
        desc = "Preview and move the Pace Comparison display.",
        func = function()
            NSI:PreviewPaceComparison()
        end,
        spacement = true,
    }
    options[#options + 1] = {
        type = "select",
        name = "Font",
        desc = "Font used for the Pace Comparison display.",
        get = function() return display.Font end,
        values = BuildFontOptions,
    }
    options[#options + 1] = {
        type = "select",
        name = "Font Outline",
        desc = "Font outline flags for the Pace Comparison display.",
        get = function() return display.FontFlags end,
        values = BuildFontFlagOptions,
    }
    options[#options + 1] = {
        type = "range",
        name = "Font Size",
        desc = "Font size of the Pace Comparison display.",
        get = function() return display.FontSize end,
        set = function(_, _, value)
            display.FontSize = value
            NSI:UpdatePaceComparisonFrameStyle()
        end,
        min = 8,
        max = 80,
        step = 1,
    }
    options[#options + 1] = {
        type = "range",
        name = "Line Spacing",
        desc = "Spacing between boss HP lines.",
        get = function() return display.LineSpacing end,
        set = function(_, _, value)
            display.LineSpacing = value
            NSI:RefreshPaceComparisonDisplay()
        end,
        min = 0,
        max = 30,
        step = 1,
    }
    options[#options + 1] = {
        type = "range",
        name = "Update Interval",
        desc = "How often the Pace Comparison display updates, in seconds. Lower values update faster but have a higher performance cost.",
        get = function() return display.RefreshInterval end,
        set = function(_, _, value)
            display.RefreshInterval = math.max(0.1, math.min(value, 1))
            if NSI.PaceComparisonActive then
                NSI:SchedulePaceComparisonPhase(NSI.Phase or 1, NSI.PaceComparisonState and NSI.PaceComparisonState.encID)
            end
        end,
        min = 0.1,
        max = 1,
        step = 0.1,
        usedecimals = true,
    }
    options[#options + 1] = {
        type = "color",
        name = "Ahead Color",
        desc = "Color used when the boss HP is lower than expected.",
        get = function() return unpack(display.AheadColor) end,
        set = function(_, r, g, b, a)
            display.AheadColor = {r, g, b, a}
            NSI:RefreshPaceComparisonColorCache()
            NSI:RefreshPaceComparisonDisplay()
        end,
        hasAlpha = true,
    }
    options[#options + 1] = {
        type = "color",
        name = "Close Behind Color",
        desc = "Color used when the boss HP is at most 0.5% higher than expected.",
        get = function() return unpack(display.CloseBehindColor) end,
        set = function(_, r, g, b, a)
            display.CloseBehindColor = {r, g, b, a}
            NSI:RefreshPaceComparisonColorCache()
            NSI:RefreshPaceComparisonDisplay()
        end,
        hasAlpha = true,
    }
    options[#options + 1] = {
        type = "color",
        name = "Behind Color",
        desc = "Color used when the boss HP is between 0.5% and 1.5% higher than expected.",
        get = function() return unpack(display.BehindColor) end,
        set = function(_, r, g, b, a)
            display.BehindColor = {r, g, b, a}
            NSI:RefreshPaceComparisonColorCache()
            NSI:RefreshPaceComparisonDisplay()
        end,
        hasAlpha = true,
    }
    options[#options + 1] = {
        type = "color",
        name = "Far Behind Color",
        desc = "Color used when the boss HP is more than 1.5% higher than expected.",
        get = function() return unpack(display.FarBehindColor) end,
        set = function(_, r, g, b, a)
            display.FarBehindColor = {r, g, b, a}
            NSI:RefreshPaceComparisonColorCache()
            NSI:RefreshPaceComparisonDisplay()
        end,
        hasAlpha = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "X-Offset",
        desc = "Horizontal offset of the Pace Comparison display.",
        get = function() return display.xOffset end,
        set = function(_, _, value)
            display.xOffset = value
            NSI:UpdatePaceComparisonFrameStyle()
        end,
        min = -3000,
        max = 3000,
        step = 1,
    }
    options[#options + 1] = {
        type = "range",
        name = "Y-Offset",
        desc = "Vertical offset of the Pace Comparison display.",
        get = function() return display.yOffset end,
        set = function(_, _, value)
            display.yOffset = value
            NSI:UpdatePaceComparisonFrameStyle()
        end,
        min = -3000,
        max = 3000,
        step = 1,
    }
end

local function BuildOptions()
    local options = {}

    AddDisplayOptions(options)

    return options
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
    local label = DF:CreateLabel(parent, NSI:Loc(text), size or 11, color)
    ApplyUIFont(label, size or 11)
    return label
end

local function BuildEditorBossOptions(screen)
    return BossData.BuildBossDropdownOptions(function(encID)
        NSRT.PaceComparison.SelectedBoss = encID
        screen.selectedBoss = encID
        screen.bossDropdown:Select(NSI:Loc(NSI.BossNames[encID] or ("Encounter " .. encID)))
        screen:Refresh()
    end, false)
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
    screen:SetPoint("TOPLEFT", parent, "TOPLEFT", 360, -10)
    screen:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    screen:SetFrameLevel(parent:GetFrameLevel() + 20)
    screen.selectedBoss = GetSelectedBoss()

    local title = CreateEditorLabel(screen, "Expected HP Thresholds", 14, "orange")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", 0, 0)

    local bossLabel = CreateEditorLabel(screen, "Boss", 11)
    bossLabel:SetPoint("TOPLEFT", GetUIObject(title), "BOTTOMLEFT", 0, -12)

    screen.bossDropdown = DF:CreateDropDown(screen, function() return BuildEditorBossOptions(screen) end, nil, 240, 22, nil, "NSUIPaceComparisonBossDropdown", options_dropdown_template)
    screen.bossDropdown:SetPoint("LEFT", GetUIObject(bossLabel), "RIGHT", 10, 0)
    screen.bossDropdown:Select(NSI:Loc(NSI.BossNames[screen.selectedBoss] or ("Encounter " .. screen.selectedBoss)))

    screen.enabledCheck = DF:CreateSwitch(screen, function(_, _, value)
        local bossSettings = NSI:GetPaceComparisonBossSettings(screen.selectedBoss)
        bossSettings.enabled = value
    end, false, 20, 20, nil, nil, nil, "NSUIPaceComparisonEnabled", nil, nil, nil, nil, options_switch_template)
    screen.enabledCheck:SetAsCheckBox()
    screen.enabledCheck:SetPoint("LEFT", GetUIObject(screen.bossDropdown), "RIGHT", 45, 0)
    screen.enabledLabel = DF:CreateLabel(screen, NSI:Loc("Enabled"), 11, "white")
    ApplyUIFont(screen.enabledLabel, 11)
    screen.enabledLabel:SetPoint("LEFT", screen.enabledCheck, "RIGHT", 2, 0)

    local resetButton = DF:CreateButton(screen, function()
        NSI:ResetPaceComparisonBoss(screen.selectedBoss)
        screen:Refresh()
    end, 125, 20, NSI:Loc("Reset Boss Defaults"))
    resetButton:SetPoint("TOPLEFT", GetUIObject(bossLabel), "BOTTOMLEFT", 0, -10)
    resetButton:SetTemplate(options_button_template)
    ApplyUIFont(resetButton, 11)

    local importButton = DF:CreateButton(screen, function()
        ShowPaceComparisonImportPopup(function()
            screen.selectedBoss = GetSelectedBoss()
            screen:Refresh()
        end)
    end, 70, 20, NSI:Loc("Import"))
    importButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)
    importButton:SetTemplate(options_button_template)
    ApplyUIFont(importButton, 11)

    local exportBossButton = DF:CreateButton(screen, function()
        local export = NSI:ExportPaceComparisonString(screen.selectedBoss)
        ShowPaceComparisonExportPopup(export, NSI:Loc("Selected Boss"))
    end, 95, 20, NSI:Loc("Export Boss"))
    exportBossButton:SetPoint("LEFT", importButton, "RIGHT", 8, 0)
    exportBossButton:SetTemplate(options_button_template)
    ApplyUIFont(exportBossButton, 11)

    local exportAllButton = DF:CreateButton(screen, function()
        ShowPaceComparisonExportPopup(NSI:ExportAllPaceComparisonString(), NSI:Loc("All Bosses"))
    end, 80, 20, NSI:Loc("Export All"))
    exportAllButton:SetPoint("LEFT", exportBossButton, "RIGHT", 8, 0)
    exportAllButton:SetTemplate(options_button_template)
    ApplyUIFont(exportAllButton, 11)

    local addLabel = CreateEditorLabel(screen, "Add Threshold", 12, "orange")
    addLabel:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -16)

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
        self:SetData(GetEditorData(screen))
        self:Refresh()
    end
    for i = 1, scrollLines do
        scrollbox:CreateLine(createLine)
    end

    function screen:Refresh()
        local bossSettings = NSI:GetPaceComparisonBossSettings(self.selectedBoss)
        self.enabledCheck:SetChecked(bossSettings.enabled)
        self.bossDropdown:Select(NSI:Loc(NSI.BossNames[self.selectedBoss] or ("Encounter " .. self.selectedBoss)))
        self.scrollbox:MasterRefresh()
    end

    screen:Refresh()
    return screen
end

NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.PaceComparison = {
    BuildOptions = BuildOptions,
    BuildEditorUI = BuildPaceComparisonEditorUI,
}
