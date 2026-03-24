local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template


local buttonmapping = {
    {DefaultDisabled = false, name = "PASettings", label = L["GEN_EXP_PLAYER_PA_SETTINGS"], desc = L["GEN_EXP_PLAYER_PA_SETTINGS_DESC"]},
    {DefaultDisabled = false, name = "PATextSettings", label = L["GEN_EXP_PA_TEXT_SETTINGS"], desc = L["GEN_EXP_PA_TEXT_SETTINGS_DESC"]},
    {DefaultDisabled = false, name = "PATankSettings", label = L["GEN_EXP_COTANK_PA_SETTINGS"], desc = L["GEN_EXP_COTANK_PA_SETTINGS_DESC"]},
    {DefaultDisabled = false, name = "PARaidSettings", label = L["GEN_EXP_RAIDFRAME_PA_SETTINGS"], desc = L["GEN_EXP_RAIDFRAME_PA_SETTINGS_DESC"]},
    {DefaultDisabled = false, name = "PASounds", label = L["GEN_EXP_PA_SOUND_SETTINGS"], desc = L["GEN_EXP_PA_SOUND_SETTINGS_DESC"]},
    {DefaultDisabled = false, name = "ReminderSettings", label = L["GEN_EXP_REMINDER_DISPLAY_SETTINGS"], desc = L["GEN_EXP_REMINDER_DISPLAY_SETTINGS_DESC"]},
    {DefaultDisabled = false, name = "ReadyCheckSettings", label = L["GEN_EXP_READYCHECK_SETTINGS"], desc = L["GEN_EXP_READYCHECK_SETTINGS_DESC"]},
    {DefaultDisabled = true, name = "CooldownList", label = L["GEN_EXP_COOLDOWN_SETTINGS"], desc = L["GEN_EXP_COOLDOWN_SETTINGS_DESC"]},
    {DefaultDisabled = true, name = "EncounterAlerts", label = L["GEN_EXP_ENCOUNTER_ALERTS_SETTINGS"], desc = L["GEN_EXP_ENCOUNTER_ALERTS_SETTINGS_DESC"]},
    {DefaultDisabled = true, name = "Reminders", label = L["GEN_EXP_REMINDER_STRINGS"], desc = L["GEN_EXP_REMINDER_STRINGS_DESC"]},
    {DefaultDisabled = true, name = "PersonalReminders", label = L["GEN_EXP_PERSONAL_REMINDER_STRINGS"], desc = L["GEN_EXP_PERSONAL_REMINDER_STRINGS_DESC"]},
    {DefaultDisabled = true, name = "NickNames", label = L["GEN_EXP_NICKNAMES"], desc = L["GEN_EXP_NICKNAMES_DESC"]},
    {DefaultDisabled = true, name = "Settings", label = L["GEN_EXP_GENERAL_SETTINGS"], desc = L["GEN_EXP_GENERAL_SETTINGS_DESC"]},
    {DefaultDisabled = true, name = "QoL", label = L["GEN_EXP_QOL_SETTINGS"], desc = L["GEN_EXP_QOL_SETTINGS_DESC"]}
}

local function BuildExportStringUI()
    local popup = DF:CreateSimplePanel(NSUI, 800, 800, L["GEN_EXPORT_TITLE"], "NSUIExportString", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ExportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -200, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetFocus()
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    popup.test_string_text_box.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")
    popup.export_confirm_button = DF:CreateButton(popup, function()
        popup:Hide()
    end, 280, 20, L["COMMON_DONE"])
    popup.export_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.export_confirm_button:SetTemplate(options_button_template)

    local ExportTable = {}
    for i, v in ipairs(buttonmapping) do
        ExportTable[v.name] = {data = NSRT[v.name], enabled = true}
        local checkbox = DF:CreateSwitch(popup, function(self, fixedValue, value)
            ExportTable[v.name].enabled = value
            popup.test_string_text_box:SetText(NSI:CreateExportString(ExportTable) or "")
        end, true, 20, 20)
        checkbox:SetAsCheckBox()
        checkbox:SetPoint("TOPLEFT", popup, "TOPRIGHT", -180, -30 - (25 * (i -1)))
        checkbox.tooltip = v.desc
        local label = DF:CreateLabel(popup, v.label, DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        if v.DefaultDisabled then
            checkbox:SetValue(false)
            ExportTable[v.name].enabled = false
        end
    end
    popup.test_string_text_box:SetText(NSI:CreateExportString(ExportTable) or "")
    popup:Hide()

    return popup
end

local function BuildImportStringUI()
    local popup = DF:CreateSimplePanel(NSUI, 800, 800, L["GEN_IMPORT_TITLE"], "NSUIImportString", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ImportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -200, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetFocus()
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    local SettingsTable = {}
    popup.test_string_text_box.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")
    popup.import_confirm_button = DF:CreateButton(popup, function()
        local ImportString = popup.test_string_text_box:GetText()
        local ImportTable = NSI:ImportSettingsFromString(ImportString)
        if not ImportTable then return end
        for k, v in pairs(ImportTable) do
            if SettingsTable[k] then
                if not SettingsTable[k].enabled then
                    ImportTable[k].enabled = false
                end
            end
        end
        NSI:ImportFromTable(ImportTable)
        popup:Hide()
    end, 280, 20, L["COMMON_IMPORT"])
    popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.import_confirm_button:SetTemplate(options_button_template)

    local checkboxes = {}
    for i, v in ipairs(buttonmapping) do
        checkboxes[i] = DF:CreateSwitch(popup, function(self, fixedValue, value)
            SettingsTable[v.name].enabled = value
        end, true, 20, 20)
        checkboxes[i]:SetAsCheckBox()
        checkboxes[i]:SetPoint("TOPLEFT", popup, "TOPRIGHT", -180, -30 - (25 * (i -1)))
        checkboxes[i].tooltip = v.desc
        local label = DF:CreateLabel(checkboxes[i], v.label, DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        label:SetPoint("LEFT", checkboxes[i], "RIGHT", 5, 0)
        checkboxes[i]:Hide()
    end


    popup.test_string_text_box.editbox:SetScript("OnTextChanged", function(self)
        local ImportTable = NSI:ImportSettingsFromString(popup.test_string_text_box:GetText())
        if not ImportTable then return end
        SettingsTable = {}
        local num = 1
        for i, v in ipairs(buttonmapping) do
            SettingsTable[v.name] = {enabled = true}
            checkboxes[i]:SetPoint("TOPLEFT", popup, "TOPRIGHT", -180, -30 - (25 * (num -1)))
            if not ImportTable[v.name] then
                checkboxes[i]:Hide()
            else
                checkboxes[i]:Show()
                checkboxes[i]:SetValue(true)
                num = num + 1
            end
        end
    end)

    popup.test_string_text_box:SetText("")
    popup:Hide()

    return popup
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.General= {
    BuildExportStringUI = BuildExportStringUI,
    BuildImportStringUI = BuildImportStringUI,
}