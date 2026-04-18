local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template


local function BuildExportStringUI()
    local popup = DF:CreateSimplePanel(NSUI, 800, 400, "Export Profile", "NSUIExportString", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    local profileLabel = DF:CreateLabel(popup, "", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    profileLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ExportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -50)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    popup.test_string_text_box.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")

    popup.export_confirm_button = DF:CreateButton(popup, function()
        popup:Hide()
    end, 280, 20, "Done")
    popup.export_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.export_confirm_button:SetTemplate(options_button_template)

    popup:HookScript("OnShow", function()
        profileLabel:SetText("Exporting profile: |cFF00FFFF" .. (NSRT.CurrentProfile or "default") .. "|r")
        local exportString = NSI:ExportProfileString()
        popup.test_string_text_box:SetText(exportString or "")
        popup.test_string_text_box:SetFocus()
    end)

    popup:Hide()
    return popup
end

local function BuildImportStringUI()
    local popup = DF:CreateSimplePanel(NSUI, 800, 400, "Import Profile", "NSUIImportString", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    local statusLabel = DF:CreateLabel(popup, "Paste a profile string below and click Import.", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    statusLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ImportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -50)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    popup.test_string_text_box.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")

    popup.import_confirm_button = DF:CreateButton(popup, function()
        local importString = popup.test_string_text_box:GetText()
        local importedName = NSI:ImportProfileString(importString)
        if importedName then
            print("|cFF00FFFFNSRT:|r Imported profile '|cFFFFFFFF" .. importedName .. "|r'.")
            popup:Hide()
            NSUI.MenuFrame:SelectTabByName("General")
        else
            statusLabel:SetText("|cFFFF0000Invalid import string. Please check and try again.|r")
        end
    end, 280, 20, "Import")
    popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.import_confirm_button:SetTemplate(options_button_template)

    popup:HookScript("OnShow", function()
        statusLabel:SetText("Paste a profile string below and click Import.")
        popup.test_string_text_box:SetText("")
        popup.test_string_text_box:SetFocus()
    end)

    popup:Hide()
    return popup
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.General= {
    BuildExportStringUI = BuildExportStringUI,
    BuildImportStringUI = BuildImportStringUI,
}