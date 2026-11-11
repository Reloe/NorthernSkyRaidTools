local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local Components = NSI.UI.Components
local CreateLocalizedButton = Components.CreateLocalizedButton
local CreateDropdown        = Components.CreateDropdown
local CreateTextEntry       = Components.CreateTextEntry
local CreateColorPicker     = Components.CreateColorPicker

-- Lua code-editor popups for Encounter Alerts (condition, encounter hooks, custom
-- preview, custom option). They own their popup frames and read screen state only
-- through the ctx callbacks supplied by EncounterAlerts.lua:
--   ctx.GetTrigF()                     -> the Trigger tab frame (fields conditionBtn, ...)
--   ctx.PositionInnerTabLayout(text)   -> re-lay the tab row for the condition hint
--   ctx.RebuildList()                  -> refresh the alert list
--   ctx.RebuildOptionsContent(alert)   -> refresh the Options tab
-- Create(ctx) returns the open/refresh functions and the default code templates.

local function SetLocalizedText(object, key)
    Components.RegisterLocalizedText(object, key)
end

local function Create(ctx)
    local function GetConditionText(condition)
        if type(condition) == "table" and type(condition.func) == "string" and condition.func ~= "" then
            return (type(condition.text) == "string" and condition.text ~= "" and condition.text) or NSI:Loc("Custom Condition")
        elseif type(condition) == "string" and condition ~= "" then
            return NSI:Loc("Custom Condition")
        end
        return nil
    end

    local DEFAULT_CONDITION_FUNC = "return function()\n    return true\nend"
    local conditionEditPopup
    local function OpenConditionEditor()
        if not ctx.GetTrigF() or not ctx.GetTrigF()._alert then return end

        if not conditionEditPopup then
            conditionEditPopup = DF:CreateSimplePanel(Core.NSUI, 820, 520,
                NSI.UI.Style.AccentCode() .. NSI:Loc("Custom Condition") .. "|r",
                "NSUIEncAlertConditionEditor", { DontRightClickClose = true })
            conditionEditPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            conditionEditPopup:SetFrameLevel(100)

            conditionEditPopup.nameLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.nameLabel, "small", "")
            conditionEditPopup.nameLabel:SetTextColor(unpack(STYLE.text_soft))
            SetLocalizedText(conditionEditPopup.nameLabel, "Condition Name")
            conditionEditPopup.nameLabel:SetPoint("TOPLEFT", conditionEditPopup, "TOPLEFT", 10, -32)

            conditionEditPopup.nameEntry = CreateTextEntry(conditionEditPopup, nil, nil, nil, 360, 22,
                nil, nil, nil, "NSUIEncAlertConditionName")
            conditionEditPopup.nameEntry:SetPoint("TOPLEFT", conditionEditPopup, "TOPLEFT", 10, -48)

            conditionEditPopup.codeLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.codeLabel, "small", "")
            conditionEditPopup.codeLabel:SetTextColor(unpack(STYLE.text_soft))
            SetLocalizedText(conditionEditPopup.codeLabel, "Condition Function")
            conditionEditPopup.codeLabel:SetPoint("TOPLEFT", conditionEditPopup.nameEntry.frame, "BOTTOMLEFT", 0, -12)

            conditionEditPopup.helpLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.helpLabel, "tiny", "")
            conditionEditPopup.helpLabel:SetTextColor(unpack(STYLE.text_muted))
            conditionEditPopup.helpLabel:SetJustifyH("LEFT")
            conditionEditPopup.helpLabel:SetPoint("TOPLEFT", conditionEditPopup.codeLabel, "BOTTOMLEFT", 0, -2)
            SetLocalizedText(conditionEditPopup.helpLabel, "Return a function which should return true when the alert should show.")

            conditionEditPopup.editor = DF:NewSpecialLuaEditorEntry(conditionEditPopup, 280, 80, nil,
                "NSUIEncAlertConditionEditorBox", false, true, true)
            conditionEditPopup.editor:SetPoint("TOPLEFT", conditionEditPopup, "TOPLEFT", 10, -112)
            conditionEditPopup.editor:SetPoint("BOTTOMRIGHT", conditionEditPopup, "BOTTOMRIGHT", -25, 48)
            DF:ApplyStandardBackdrop(conditionEditPopup.editor)
            DF:ReskinSlider(conditionEditPopup.editor.scroll)
            conditionEditPopup.editor:SetScript("OnMouseDown", function(self) self:SetFocus() end)
            NSI:SetUIFont(conditionEditPopup.editor.editbox, "label")

            conditionEditPopup.statusLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.statusLabel, "tiny", "")
            conditionEditPopup.statusLabel:SetTextColor(unpack(STYLE.text_danger))
            conditionEditPopup.statusLabel:SetPoint("BOTTOMLEFT", conditionEditPopup, "BOTTOMLEFT", 10, 14)
            conditionEditPopup.statusLabel:SetWidth(430)
            conditionEditPopup.statusLabel:SetJustifyH("LEFT")

            conditionEditPopup.saveBtn = CreateLocalizedButton(conditionEditPopup, "Save", function()
                local alert = conditionEditPopup._alert
                if not alert then return end
                local conditionName = conditionEditPopup.nameEntry:GetValue() or ""
                local conditionFunc = conditionEditPopup.editor:GetText() or ""
                conditionName = strtrim(conditionName)
                conditionFunc = strtrim(conditionFunc)

                if conditionName == "" and conditionFunc == "" then
                    NSI:SaveAlertData(alert, "isConditional", nil)
                    conditionEditPopup:Hide()
                    ctx.PositionInnerTabLayout(nil)
                    if ctx.GetTrigF().conditionBtn then ctx.GetTrigF().conditionBtn:SetText(NSI:Loc("Add Condition")) end
                    ctx.RebuildList()
                    return
                end

                if conditionFunc == "" then
                    conditionEditPopup.statusLabel:SetText(NSI:Loc("Condition Function is required."))
                    return
                end

                local chunk, err = loadstring(conditionFunc)
                if not chunk then
                    conditionEditPopup.statusLabel:SetText(err or NSI:Loc("Invalid condition function."))
                    return
                end

                local condition = {
                    text = conditionName ~= "" and conditionName or NSI:Loc("Custom Condition"),
                    func = conditionFunc,
                }
                NSI:SaveAlertData(alert, "isConditional", condition)
                conditionEditPopup:Hide()
                ctx.PositionInnerTabLayout(condition.text)
                if ctx.GetTrigF().conditionBtn then ctx.GetTrigF().conditionBtn:SetText(NSI:Loc("Edit Condition")) end
                ctx.RebuildList()
            end, 120, 22)
            conditionEditPopup.saveBtn:SetPoint("BOTTOMRIGHT", conditionEditPopup, "BOTTOMRIGHT", -138, 12)

            conditionEditPopup.clearBtn = CreateLocalizedButton(conditionEditPopup, "Clear", function()
                conditionEditPopup.nameEntry:SetValue("")
                conditionEditPopup.editor:SetText("")
                conditionEditPopup.statusLabel:SetText("")
            end, 120, 22)
            conditionEditPopup.clearBtn:SetPoint("RIGHT", conditionEditPopup.saveBtn.frame, "LEFT", -8, 0)

            conditionEditPopup.cancelBtn = CreateLocalizedButton(conditionEditPopup, "Cancel", function()
                conditionEditPopup:Hide()
            end, 120, 22)
            conditionEditPopup.cancelBtn:SetPoint("LEFT", conditionEditPopup.saveBtn.frame, "RIGHT", 8, 0)
        end

        local condition = ctx.GetTrigF()._alert.isConditional
        conditionEditPopup._alert = ctx.GetTrigF()._alert
        conditionEditPopup.statusLabel:SetText("")
        conditionEditPopup.nameEntry:SetValue(type(condition) == "table" and condition.text or "")
        conditionEditPopup.editor:SetText(type(condition) == "table" and condition.func or DEFAULT_CONDITION_FUNC)
        conditionEditPopup:Show()
        conditionEditPopup.editor:SetFocus()
    end

    local function RefreshEncounterHookDisplay(alert)
        local hasHook = (type(alert.onEncounterStart) == "string" and alert.onEncounterStart ~= "")
            or (type(alert.onEncounterEnd) == "string" and alert.onEncounterEnd ~= "")
            or (type(alert.onPhaseChange) == "string" and alert.onPhaseChange ~= "")
        if hasHook and alert.isSpecialDisplay ~= true then
            alert.EncounterHookSpecialDisplay = true
            NSI:SaveAlertData(alert, "isSpecialDisplay", true)
        elseif not hasHook and alert.EncounterHookSpecialDisplay then
            alert.EncounterHookSpecialDisplay = nil
            NSI:SaveAlertData(alert, "isSpecialDisplay", nil)
        end
    end

    local DEFAULT_ENCOUNTER_START_CODE = [[return function(self, alertData, alertTable, encounterID, encounterName, difficultyID, groupSize)
-- This is an example of how to create and display a standard reminder using the existing alert data
-- local alert = self:CreateReminder(alertData)
-- self:DisplayReminder(alert)
-- self is the internal NSI table so you have access to all internal addon functions here
-- alertData is the data of the alert as written in the savedvariables. Editing this would be the same as editing the alert in the UI, you should probably never do that but you can read and use it's values.
-- alertTable is an internal table that is only accessible within this alert's code, you can think of this like aura_env from WeakAuras
end]]
    local DEFAULT_ENCOUNTER_END_CODE = [[return function(self, alertData, alertTable, encounterID, encounterName, difficultyID, groupSize, success)
-- This is an example of how to create and display a standard reminder using the existing alert data
-- local alert = self:CreateReminder(alertData)
-- self:DisplayReminder(alert)
-- self is the internal NSI table so you have access to all internal addon functions here
-- alertData is the data of the alert as written in the savedvariables. Editing this would be the same as editing the alert in the UI, you should probably never do that but you can read and use it's values.
-- alertTable is an internal table that is only accessible within this alert's code, you can think of this like aura_env from WeakAuras
end]]
    local DEFAULT_PHASE_CHANGE_CODE = [[return function(self, alertData, alertTable, oldPhase, newPhase)
-- oldPhase is the phase the encounter is leaving; newPhase is the phase it is entering
-- This is an example of how to create and display a standard reminder using the existing alert data
-- local alert = self:CreateReminder(alertData)
-- self:DisplayReminder(alert)
-- self is the internal NSI table so you have access to all internal addon functions here
-- alertData is the data of the alert as written in the savedvariables. Editing this would be the same as editing the alert in the UI, you should probably never do that but you can read and use it's values.
-- alertTable is an internal table that is only accessible within this alert's code, you can think of this like aura_env from WeakAuras
end]]
    local encounterHookEditPopup
    local function OpenEncounterHookEditor(hookKey, labelKey, defaultCode)
        if not ctx.GetTrigF() or not ctx.GetTrigF()._alert then return end

        if not encounterHookEditPopup then
            encounterHookEditPopup = DF:CreateSimplePanel(Core.NSUI, 820, 520,
                NSI.UI.Style.AccentCode() .. NSI:Loc("Encounter Hook Editor") .. "|r",
                "NSUIEncAlertHookEditor", { DontRightClickClose = true })
            encounterHookEditPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            encounterHookEditPopup:SetFrameLevel(100)

            encounterHookEditPopup.codeLabel = encounterHookEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(encounterHookEditPopup.codeLabel, "small", "")
            encounterHookEditPopup.codeLabel:SetTextColor(unpack(STYLE.text_soft))
            encounterHookEditPopup.codeLabel:SetPoint("TOPLEFT", encounterHookEditPopup, "TOPLEFT", 10, -32)

            encounterHookEditPopup.helpLabel = encounterHookEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(encounterHookEditPopup.helpLabel, "tiny", "")
            encounterHookEditPopup.helpLabel:SetTextColor(unpack(STYLE.text_muted))
            encounterHookEditPopup.helpLabel:SetJustifyH("LEFT")
            encounterHookEditPopup.helpLabel:SetPoint("TOPLEFT", encounterHookEditPopup.codeLabel, "BOTTOMLEFT", 0, -2)

            encounterHookEditPopup.editor = DF:NewSpecialLuaEditorEntry(encounterHookEditPopup, 280, 80, nil,
                "NSUIEncAlertHookEditorBox", false, true, true)
            encounterHookEditPopup.editor:SetPoint("TOPLEFT", encounterHookEditPopup, "TOPLEFT", 10, -72)
            encounterHookEditPopup.editor:SetPoint("BOTTOMRIGHT", encounterHookEditPopup, "BOTTOMRIGHT", -25, 48)
            DF:ApplyStandardBackdrop(encounterHookEditPopup.editor)
            DF:ReskinSlider(encounterHookEditPopup.editor.scroll)
            encounterHookEditPopup.editor:SetScript("OnMouseDown", function(self) self:SetFocus() end)
            NSI:SetUIFont(encounterHookEditPopup.editor.editbox, "label")

            encounterHookEditPopup.statusLabel = encounterHookEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(encounterHookEditPopup.statusLabel, "tiny", "")
            encounterHookEditPopup.statusLabel:SetTextColor(unpack(STYLE.text_danger))
            encounterHookEditPopup.statusLabel:SetPoint("BOTTOMLEFT", encounterHookEditPopup, "BOTTOMLEFT", 10, 14)
            encounterHookEditPopup.statusLabel:SetWidth(430)
            encounterHookEditPopup.statusLabel:SetJustifyH("LEFT")

            encounterHookEditPopup.saveBtn = CreateLocalizedButton(encounterHookEditPopup, "Save", function()
                local alert = encounterHookEditPopup._alert
                if not alert then return end
                local hookCode = strtrim(encounterHookEditPopup.editor:GetText() or "")
                if hookCode ~= "" then
                    local chunk, err = loadstring(hookCode)
                    if not chunk then
                        encounterHookEditPopup.statusLabel:SetText(err or NSI:Loc("Invalid encounter hook function."))
                        return
                    end
                end

                NSI:SaveAlertData(alert, encounterHookEditPopup._hookKey, hookCode ~= "" and hookCode or nil)
                RefreshEncounterHookDisplay(alert)
                encounterHookEditPopup:Hide()
                ctx.GetTrigF().encounterStartCodeBtn:SetText(NSI:Loc(alert.onEncounterStart and "Edit Encounter Start Code" or "Add Encounter Start Code"))
                ctx.GetTrigF().encounterEndCodeBtn:SetText(NSI:Loc(alert.onEncounterEnd and "Edit Encounter End Code" or "Add Encounter End Code"))
                ctx.GetTrigF().phaseChangeCodeBtn:SetText(NSI:Loc(alert.onPhaseChange and "Edit Phase Change Code" or "Add Phase Change Code"))
            end, 120, 22)
            encounterHookEditPopup.saveBtn:SetPoint("BOTTOMRIGHT", encounterHookEditPopup, "BOTTOMRIGHT", -138, 12)

            encounterHookEditPopup.cancelBtn = CreateLocalizedButton(encounterHookEditPopup, "Cancel", function()
                encounterHookEditPopup:Hide()
            end, 120, 22)
            encounterHookEditPopup.cancelBtn:SetPoint("LEFT", encounterHookEditPopup.saveBtn.frame, "RIGHT", 8, 0)
        end

        encounterHookEditPopup._alert = ctx.GetTrigF()._alert
        encounterHookEditPopup._hookKey = hookKey
        encounterHookEditPopup.codeLabel:SetText(NSI:Loc(labelKey))
        encounterHookEditPopup.helpLabel:SetText(NSI:Loc("Return a function. It receives self (NSI), the alert data, an alertTable shared by this alert's code, and event-specific arguments."))
        encounterHookEditPopup.statusLabel:SetText("")
        encounterHookEditPopup.editor:SetText(ctx.GetTrigF()._alert[hookKey] or defaultCode)
        encounterHookEditPopup:Show()
        encounterHookEditPopup.editor:SetFocus()
    end

    local CUSTOM_PREVIEW_DEFAULT = [[return function(self, alertData, alertTable)
-- local alert = self:CreateReminder(alertData)
-- self:DisplayReminder(alert)
-- alertTable is an internal table that is only accessible within this alert's code, you can think of this like aura_env from WeakAuras
end]]
    local customPreviewPopup
    local function OpenCustomPreviewEditor(alert)
        if not customPreviewPopup then
            customPreviewPopup = DF:CreateSimplePanel(Core.NSUI, 820, 520,
                NSI.UI.Style.AccentCode() .. NSI:Loc("Custom Preview Code") .. "|r",
                "NSUIEncAlertCustomPreviewEditor", { DontRightClickClose = true })
            customPreviewPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            customPreviewPopup:SetFrameLevel(100)

            customPreviewPopup.helpLabel = customPreviewPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(customPreviewPopup.helpLabel, "tiny", "")
            customPreviewPopup.helpLabel:SetTextColor(unpack(STYLE.text_muted))
            customPreviewPopup.helpLabel:SetPoint("TOPLEFT", customPreviewPopup, "TOPLEFT", 10, -32)
            SetLocalizedText(customPreviewPopup.helpLabel, "Return a function(self, alertData, alertTable).")

            customPreviewPopup.editor = DF:NewSpecialLuaEditorEntry(customPreviewPopup, 280, 80, nil,
                "NSUIEncAlertCustomPreviewEditorBox", false, true, true)
            customPreviewPopup.editor:SetPoint("TOPLEFT", customPreviewPopup, "TOPLEFT", 10, -56)
            customPreviewPopup.editor:SetPoint("BOTTOMRIGHT", customPreviewPopup, "BOTTOMRIGHT", -25, 48)
            DF:ApplyStandardBackdrop(customPreviewPopup.editor)
            DF:ReskinSlider(customPreviewPopup.editor.scroll)
            customPreviewPopup.editor:SetScript("OnMouseDown", function(self) self:SetFocus() end)
            NSI:SetUIFont(customPreviewPopup.editor.editbox, "label")

            customPreviewPopup.statusLabel = customPreviewPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(customPreviewPopup.statusLabel, "tiny", "")
            customPreviewPopup.statusLabel:SetTextColor(unpack(STYLE.text_danger))
            customPreviewPopup.statusLabel:SetPoint("BOTTOMLEFT", customPreviewPopup, "BOTTOMLEFT", 10, 14)
            customPreviewPopup.statusLabel:SetWidth(430)
            customPreviewPopup.statusLabel:SetJustifyH("LEFT")

            customPreviewPopup.saveBtn = CreateLocalizedButton(customPreviewPopup, "Save", function()
                local selectedAlert = customPreviewPopup._alert
                if not selectedAlert then return end
                local previewCode = strtrim(customPreviewPopup.editor:GetText() or "")
                if previewCode ~= "" then
                    local chunk, err = loadstring(previewCode)
                    if not chunk then
                        customPreviewPopup.statusLabel:SetText(err or NSI:Loc("Invalid custom preview function."))
                        return
                    end
                end
                NSI:SaveAlertData(selectedAlert, "customPreview", previewCode ~= "" and previewCode or nil)
                customPreviewPopup:Hide()
                ctx.RebuildOptionsContent(selectedAlert)
            end, 120, 22)
            customPreviewPopup.saveBtn:SetPoint("BOTTOMRIGHT", customPreviewPopup, "BOTTOMRIGHT", -138, 12)

            customPreviewPopup.cancelBtn = CreateLocalizedButton(customPreviewPopup, "Cancel", function()
                customPreviewPopup:Hide()
            end, 120, 22)
            customPreviewPopup.cancelBtn:SetPoint("LEFT", customPreviewPopup.saveBtn.frame, "RIGHT", 8, 0)
        end

        customPreviewPopup._alert = alert
        customPreviewPopup.statusLabel:SetText("")
        customPreviewPopup.editor:SetText(alert.customPreview or CUSTOM_PREVIEW_DEFAULT)
        customPreviewPopup:Show()
        customPreviewPopup.editor:SetFocus()
    end

    local customOptionEditorPopup

    local function GetNextCustomOptionID(alert)
        local maxID = 0
        for definitionIndex, definition in ipairs(alert.customOptionDefinitions or {}) do
            local number = type(definition.id) == "string" and tonumber(definition.id:match("^option(%d+)$"))
            if number and number > maxID then maxID = number end
        end
        return "option" .. (maxID + 1)
    end

    local function OpenCustomOptionEditor(alert, existingDefinition)
        if not customOptionEditorPopup then
            customOptionEditorPopup = DF:CreateSimplePanel(Core.NSUI, 720, 430,
                NSI.UI.Style.AccentCode() .. NSI:Loc("Custom Alert Option") .. "|r",
                "NSUIEncAlertCustomOptionEditor", { DontRightClickClose = true })
            customOptionEditorPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            customOptionEditorPopup:SetFrameLevel(100)

            customOptionEditorPopup.nameEntry = CreateTextEntry(customOptionEditorPopup, NSI:Loc("Option Name"), nil, nil, 390, 22,
                nil, nil, nil, "NSUIEncAlertCustomOptionName", nil, 230)
            customOptionEditorPopup.nameEntry:SetPoint("TOPLEFT", customOptionEditorPopup, "TOPLEFT", 10, -42)
            customOptionEditorPopup.keyEntry = CreateTextEntry(customOptionEditorPopup, NSI:Loc("Option Key"), nil, nil, 280, 22,
                nil, nil, nil, "NSUIEncAlertCustomOptionKey", nil, 160)
            customOptionEditorPopup.keyEntry:SetPoint("LEFT", customOptionEditorPopup.nameEntry.frame, "RIGHT", 10, 0)

            customOptionEditorPopup.selectedType = "Text"
            customOptionEditorPopup.typeDropdown = CreateDropdown(customOptionEditorPopup, NSI:Loc("Option Type"), function()
                local types = { "Text", "Number", "Dropdown", "Checkbox", "Color" }
                local items = {}
                for typeIndex, optionType in ipairs(types) do
                    local value = optionType
                    items[#items + 1] = { label = NSI:Loc(value), value = value, onclick = function()
                        customOptionEditorPopup.selectedType = value
                        customOptionEditorPopup.RefreshTypeControls()
                    end }
                end
                return items
            end, function()
                return NSI:Loc(customOptionEditorPopup.selectedType)
            end, 300, 22, "NSUIEncAlertCustomOptionType")
            customOptionEditorPopup.typeDropdown:SetPoint("TOPLEFT", customOptionEditorPopup.nameEntry.frame, "BOTTOMLEFT", 0, -14)

            customOptionEditorPopup.defaultEntry = CreateTextEntry(customOptionEditorPopup, NSI:Loc("Default Value"), nil, nil, 680, 22,
                nil, nil, nil, "NSUIEncAlertCustomOptionDefault", nil, 400)
            customOptionEditorPopup.defaultEntry:SetPoint("TOPLEFT", customOptionEditorPopup.typeDropdown.frame, "BOTTOMLEFT", 0, -14)
            customOptionEditorPopup.defaultColor = {1, 1, 1, 1}
            customOptionEditorPopup.defaultColorPicker = CreateColorPicker(customOptionEditorPopup, NSI:Loc("Default Color"),
                function() return unpack(customOptionEditorPopup.defaultColor) end,
                function(_, r, g, b, a)
                    customOptionEditorPopup.defaultColor = {r, g, b, a}
                end,
                680, 22, "NSUIEncAlertCustomOptionDefaultColor")
            customOptionEditorPopup.defaultColorPicker:SetPoint("TOPLEFT", customOptionEditorPopup.defaultEntry.frame, "TOPLEFT", 0, 0)

            customOptionEditorPopup.minimumEntry = CreateTextEntry(customOptionEditorPopup, NSI:Loc("Minimum"), nil, nil, 210, 22,
                nil, nil, nil, "NSUIEncAlertCustomOptionMinimum", nil, 100)
            customOptionEditorPopup.minimumEntry:SetPoint("TOPLEFT", customOptionEditorPopup.defaultEntry.frame, "BOTTOMLEFT", 0, -14)
            customOptionEditorPopup.maximumEntry = CreateTextEntry(customOptionEditorPopup, NSI:Loc("Maximum"), nil, nil, 210, 22,
                nil, nil, nil, "NSUIEncAlertCustomOptionMaximum", nil, 100)
            customOptionEditorPopup.maximumEntry:SetPoint("LEFT", customOptionEditorPopup.minimumEntry.frame, "RIGHT", 12, 0)
            customOptionEditorPopup.stepEntry = CreateTextEntry(customOptionEditorPopup, NSI:Loc("Step Size"), nil, nil, 210, 22,
                nil, nil, nil, "NSUIEncAlertCustomOptionStep", nil, 100)
            customOptionEditorPopup.stepEntry:SetPoint("LEFT", customOptionEditorPopup.maximumEntry.frame, "RIGHT", 12, 0)

            customOptionEditorPopup.choicesEntry = CreateTextEntry(customOptionEditorPopup, NSI:Loc("Dropdown Choices (comma separated)"), nil, nil, 680, 22,
                nil, nil, nil, "NSUIEncAlertCustomOptionChoices", nil, 500)
            customOptionEditorPopup.choicesEntry:SetPoint("TOPLEFT", customOptionEditorPopup.minimumEntry.frame, "BOTTOMLEFT", 0, -14)

            customOptionEditorPopup.helpLabel = customOptionEditorPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(customOptionEditorPopup.helpLabel, "tiny", "")
            customOptionEditorPopup.helpLabel:SetTextColor(unpack(STYLE.text_muted))
            customOptionEditorPopup.helpLabel:SetPoint("TOPLEFT", customOptionEditorPopup.choicesEntry.frame, "BOTTOMLEFT", 0, -8)
            customOptionEditorPopup.helpLabel:SetWidth(680)
            customOptionEditorPopup.helpLabel:SetJustifyH("LEFT")

            customOptionEditorPopup.statusLabel = customOptionEditorPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(customOptionEditorPopup.statusLabel, "tiny", "")
            customOptionEditorPopup.statusLabel:SetTextColor(unpack(STYLE.text_danger))
            customOptionEditorPopup.statusLabel:SetPoint("BOTTOMLEFT", customOptionEditorPopup, "BOTTOMLEFT", 10, 14)
            customOptionEditorPopup.statusLabel:SetWidth(430)
            customOptionEditorPopup.statusLabel:SetJustifyH("LEFT")

            customOptionEditorPopup.RefreshTypeControls = function()
                local optionType = customOptionEditorPopup.selectedType
                customOptionEditorPopup.defaultEntry.frame:SetShown(optionType ~= "Color")
                customOptionEditorPopup.defaultColorPicker.frame:SetShown(optionType == "Color")
                customOptionEditorPopup.minimumEntry.frame:SetShown(optionType == "Number")
                customOptionEditorPopup.maximumEntry.frame:SetShown(optionType == "Number")
                customOptionEditorPopup.stepEntry.frame:SetShown(optionType == "Number")
                customOptionEditorPopup.choicesEntry.frame:SetShown(optionType == "Dropdown")
                customOptionEditorPopup.helpLabel:SetText(NSI:Loc(optionType == "Number" and "Number options use a stepped slider." or optionType == "Dropdown" and "Enter the choices in display order, separated by commas." or optionType == "Checkbox" and "Use true or false as the default value." or optionType == "Color" and "Choose the default color for this option." or "Text options accept any text value."))
            end

            customOptionEditorPopup.saveBtn = CreateLocalizedButton(customOptionEditorPopup, "Save", function()
                local selectedAlert = customOptionEditorPopup._alert
                if not selectedAlert then return end
                local optionName = strtrim(customOptionEditorPopup.nameEntry:GetValue() or "")
                local optionKey = strtrim(customOptionEditorPopup.keyEntry:GetValue() or "")
                local optionType = customOptionEditorPopup.selectedType
                if optionName == "" then
                    customOptionEditorPopup.statusLabel:SetText(NSI:Loc("Option Name is required."))
                    return
                end
                if optionKey == "" then
                    customOptionEditorPopup.statusLabel:SetText(NSI:Loc("Option Key is required."))
                    return
                end

                selectedAlert.customOptionDefinitions = selectedAlert.customOptionDefinitions or {}
                for _, currentDefinition in ipairs(selectedAlert.customOptionDefinitions) do
                    if currentDefinition.id == optionKey and currentDefinition.id ~= customOptionEditorPopup._definitionID then
                        customOptionEditorPopup.statusLabel:SetText(NSI:Loc("Option Key is already in use."))
                        return
                    end
                end

                local definition = {
                    id = optionKey,
                    name = optionName,
                    type = optionType,
                }
                local defaultValue = customOptionEditorPopup.defaultEntry:GetValue() or ""
                if optionType == "Number" then
                    definition.min = tonumber(customOptionEditorPopup.minimumEntry:GetValue())
                    definition.max = tonumber(customOptionEditorPopup.maximumEntry:GetValue())
                    definition.step = tonumber(customOptionEditorPopup.stepEntry:GetValue()) or 1
                    definition.defaultValue = tonumber(defaultValue)
                    if not definition.min or not definition.max or definition.min >= definition.max or not definition.defaultValue or definition.step <= 0 then
                        customOptionEditorPopup.statusLabel:SetText(NSI:Loc("Enter a valid number default, minimum, maximum, and positive step size."))
                        return
                    end
                    if definition.defaultValue < definition.min or definition.defaultValue > definition.max then
                        customOptionEditorPopup.statusLabel:SetText(NSI:Loc("The default value must be between the minimum and maximum."))
                        return
                    end
                elseif optionType == "Checkbox" then
                    local normalizedDefault = strlower(strtrim(defaultValue))
                    if normalizedDefault ~= "true" and normalizedDefault ~= "false" then
                        customOptionEditorPopup.statusLabel:SetText(NSI:Loc("Checkbox default must be true or false."))
                        return
                    end
                    definition.defaultValue = normalizedDefault == "true"
                elseif optionType == "Color" then
                    local defaultColor = customOptionEditorPopup.defaultColor
                    definition.defaultValue = {defaultColor[1], defaultColor[2], defaultColor[3], defaultColor[4]}
                elseif optionType == "Dropdown" then
                    definition.choices = {}
                    for choiceValue in (customOptionEditorPopup.choicesEntry:GetValue() or ""):gmatch("[^,]+") do
                        local normalizedChoice = strtrim(choiceValue)
                        if normalizedChoice ~= "" then definition.choices[#definition.choices + 1] = normalizedChoice end
                    end
                    if #definition.choices == 0 then
                        customOptionEditorPopup.statusLabel:SetText(NSI:Loc("Add at least one dropdown choice."))
                        return
                    end
                    definition.defaultValue = defaultValue ~= "" and defaultValue or definition.choices[1]
                    if not tContains(definition.choices, definition.defaultValue) then
                        customOptionEditorPopup.statusLabel:SetText(NSI:Loc("The default value must match one of the dropdown choices."))
                        return
                    end
                else
                    definition.defaultValue = defaultValue
                end

                selectedAlert.customOptionValues = selectedAlert.customOptionValues or {}
                local previousDefinitionID = customOptionEditorPopup._definitionID
                local previousValue = previousDefinitionID and selectedAlert.customOptionValues[previousDefinitionID]
                local previousType
                local foundDefinition
                for index, currentDefinition in ipairs(selectedAlert.customOptionDefinitions) do
                    if currentDefinition.id == previousDefinitionID then
                        previousType = currentDefinition.type
                        selectedAlert.customOptionDefinitions[index] = definition
                        foundDefinition = true
                        break
                    end
                end
                if not foundDefinition then
                    selectedAlert.customOptionDefinitions[#selectedAlert.customOptionDefinitions + 1] = definition
                end
                local keepPreviousValue = previousType == definition.type and previousValue ~= nil
                if optionType == "Number" and keepPreviousValue then
                    keepPreviousValue = type(previousValue) == "number" and previousValue >= definition.min and previousValue <= definition.max
                elseif optionType == "Dropdown" and keepPreviousValue then
                    keepPreviousValue = tContains(definition.choices, previousValue)
                elseif optionType == "Checkbox" and keepPreviousValue then
                    keepPreviousValue = type(previousValue) == "boolean"
                elseif optionType == "Text" and keepPreviousValue then
                    keepPreviousValue = type(previousValue) == "string"
                elseif optionType == "Color" and keepPreviousValue then
                    keepPreviousValue = type(previousValue) == "table" and #previousValue >= 4
                    if keepPreviousValue then
                        for colorIndex = 1, 4 do
                            local channel = previousValue[colorIndex]
                            if type(channel) ~= "number" or channel < 0 or channel > 1 then
                                keepPreviousValue = false
                                break
                            end
                        end
                    end
                end
                if previousDefinitionID and previousDefinitionID ~= definition.id then
                    selectedAlert.customOptionValues[previousDefinitionID] = nil
                end
                if keepPreviousValue then
                    selectedAlert.customOptionValues[definition.id] = previousValue
                else
                    selectedAlert.customOptionValues[definition.id] = definition.defaultValue
                end
                NSI:SaveAlertData(selectedAlert, "customOptionDefinitions", selectedAlert.customOptionDefinitions)
                NSI:SaveAlertData(selectedAlert, "customOptionValues", selectedAlert.customOptionValues)
                customOptionEditorPopup:Hide()
                ctx.RebuildOptionsContent(selectedAlert)
            end, 120, 22)
            customOptionEditorPopup.saveBtn:SetPoint("BOTTOMRIGHT", customOptionEditorPopup, "BOTTOMRIGHT", -138, 12)

            customOptionEditorPopup.cancelBtn = CreateLocalizedButton(customOptionEditorPopup, "Cancel", function()
                customOptionEditorPopup:Hide()
            end, 120, 22)
            customOptionEditorPopup.cancelBtn:SetPoint("LEFT", customOptionEditorPopup.saveBtn.frame, "RIGHT", 8, 0)
        end

        customOptionEditorPopup._alert = alert
        customOptionEditorPopup._definitionID = existingDefinition and existingDefinition.id
        customOptionEditorPopup.selectedType = existingDefinition and existingDefinition.type or "Text"
        customOptionEditorPopup.nameEntry:SetValue(existingDefinition and existingDefinition.name or "")
        customOptionEditorPopup.keyEntry:SetValue(existingDefinition and tostring(existingDefinition.id) or GetNextCustomOptionID(alert))
        customOptionEditorPopup.defaultEntry:SetValue(existingDefinition and existingDefinition.type ~= "Color" and tostring(existingDefinition.defaultValue) or "")
        local defaultColor = existingDefinition and existingDefinition.type == "Color" and existingDefinition.defaultValue
        local fallbackColor = NSRT.ReminderSettings.DebuffOverviewSettings.barColors
        customOptionEditorPopup.defaultColor = defaultColor and {defaultColor[1], defaultColor[2], defaultColor[3], defaultColor[4]}
            or {fallbackColor[1], fallbackColor[2], fallbackColor[3], fallbackColor[4]}
        customOptionEditorPopup.defaultColorPicker:Refresh()
        customOptionEditorPopup.minimumEntry:SetValue(existingDefinition and tostring(existingDefinition.min or "") or "")
        customOptionEditorPopup.maximumEntry:SetValue(existingDefinition and tostring(existingDefinition.max or "") or "")
        customOptionEditorPopup.stepEntry:SetValue(existingDefinition and tostring(existingDefinition.step or "") or "")
        customOptionEditorPopup.choicesEntry:SetValue(existingDefinition and table.concat(existingDefinition.choices or {}, ", ") or "")
        customOptionEditorPopup.statusLabel:SetText("")
        customOptionEditorPopup.RefreshTypeControls()
        customOptionEditorPopup.typeDropdown:Refresh()
        customOptionEditorPopup:Show()
    end

    return {
        GetConditionText = GetConditionText,
        OpenConditionEditor = OpenConditionEditor,
        RefreshEncounterHookDisplay = RefreshEncounterHookDisplay,
        OpenEncounterHookEditor = OpenEncounterHookEditor,
        DEFAULT_ENCOUNTER_START_CODE = DEFAULT_ENCOUNTER_START_CODE,
        DEFAULT_ENCOUNTER_END_CODE = DEFAULT_ENCOUNTER_END_CODE,
        DEFAULT_PHASE_CHANGE_CODE = DEFAULT_PHASE_CHANGE_CODE,
        OpenCustomPreviewEditor = OpenCustomPreviewEditor,
        OpenCustomOptionEditor = OpenCustomOptionEditor,
    }
end

NSI.UI = NSI.UI or {}
NSI.UI.EncounterAlertParts = NSI.UI.EncounterAlertParts or {}
NSI.UI.EncounterAlertParts.CodeEditors = { Create = Create }
