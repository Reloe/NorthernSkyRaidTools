local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local NSUI = Core.NSUI
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template

local function T(key)
    return NSI:Loc(key)
end

function NSI:ConfirmApplyProfileToAllCharacters(name)
    NSI.UI.Components.CreateDialog(
        "NSRTApplyProfileToAllCharacters" .. name:gsub("%W", "_"),
        T("Apply Profile to All Characters?"),
        format(T("Apply profile '|cFFFFFFFF%s|r' to all characters? This replaces every existing character profile assignment."), name),
        T("Apply to All"),
        function()
            if NSI:SetMainProfile(name, true) then
                print("|cFF00FFFFNSRT:|r " .. format(T("Profile '|cFFFFFFFF%s|r' is now the main profile for all characters."), name))
            end
        end,
        T("Cancel")
    )
end

local function ApplyUIFont(object, size, flags)
    if not object then return end
    if object.GetFontString then
        object = object:GetFontString()
    end
    NSI:SetUIFont(object, size or 12, flags or "")
end


local function BuildExportStringUI()
    local popup = DF:CreateSimplePanel(NSUI, 800, 400, T("Export Profile"), "NSUIExportString", {
        DontRightClickClose = true
    })
    ApplyUIFont(popup.Title, 12)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)
    popup.IncludeSharedData = false

    local profileLabel = DF:CreateLabel(popup, "", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    ApplyUIFont(profileLabel, 12)
    profileLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    profileLabel:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    profileLabel:SetWordWrap(true)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "ExportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -75)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    NSI:SetUIFont(popup.test_string_text_box.editbox, 13, "OUTLINE")

    popup.export_confirm_button = DF:CreateButton(popup, function()
        popup:Hide()
    end, 280, 20, T("Done"))
    ApplyUIFont(popup.export_confirm_button, 12)
    popup.export_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.export_confirm_button:SetTemplate(options_button_template)

    popup:HookScript("OnShow", function()
        local title = popup.IncludeSharedData and T("Export Profile + Shared Data") or T("Export Profile")
        popup:SetTitle(title)
        local label = format(T("Exporting profile: |cFF00FFFF%s|r"), NSRT.CurrentProfile or "default")
        if popup.IncludeSharedData then
            label = label .. "\n" .. T("Includes Encounter Alerts, Aura Sounds and Aura Tracking. Nicknames are never included.")
        end
        profileLabel:SetText(label)
        local exportString = NSI:ExportProfileString(popup.IncludeSharedData)
        popup.test_string_text_box:SetText(exportString or "")
        popup.test_string_text_box:SetFocus()
    end)

    popup:Hide()
    return popup
end

local function BuildImportStringUI()
    local popup = DF:CreateSimplePanel(NSUI, 800, 400, T("Import Profile"), "NSUIImportString", {
        DontRightClickClose = true
    })
    ApplyUIFont(popup.Title, 12)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    local statusLabel = DF:CreateLabel(popup, T("Paste a profile string below and click Import."), DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    ApplyUIFont(statusLabel, 12)
    statusLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "ImportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -50)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    NSI:SetUIFont(popup.test_string_text_box.editbox, 13, "OUTLINE")

    local pendingSharedImport
    local pendingConflictImport
    local CompleteImport
    local sharedImportPopup = DF:CreateSimplePanel(NSUI, 430, 170, T("Import Profile"), "NSUISharedImportConfirm", {
        DontRightClickClose = true
    })
    ApplyUIFont(sharedImportPopup.Title, 12)
    sharedImportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    sharedImportPopup:SetFrameLevel(110)

    local sharedImportLabel = DF:CreateLabel(sharedImportPopup, T("This import will overwrite your settings for Encounter Alerts, Aura Sounds and Aura Tracking, proceed?"), DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    ApplyUIFont(sharedImportLabel, 12)
    sharedImportLabel:SetPoint("TOPLEFT", sharedImportPopup, "TOPLEFT", 15, -35)
    sharedImportLabel:SetPoint("RIGHT", sharedImportPopup, "RIGHT", -15, 0)
    sharedImportLabel:SetJustifyH("LEFT")
    sharedImportLabel:SetWordWrap(true)

    local sharedImportCancelButton = DF:CreateButton(sharedImportPopup, function()
        pendingSharedImport = nil
        sharedImportPopup:Hide()
    end, 120, 24, T("Cancel"))
    ApplyUIFont(sharedImportCancelButton, 12)
    sharedImportCancelButton:SetPoint("BOTTOMLEFT", sharedImportPopup, "BOTTOMLEFT", 55, 15)
    sharedImportCancelButton:SetTemplate(options_button_template)

    local sharedImportConfirmButton = DF:CreateButton(sharedImportPopup, function()
        local import = pendingSharedImport
        pendingSharedImport = nil
        sharedImportPopup:Hide()
        if import then CompleteImport(import.string, true, import.overwrite, import.profileName) end
    end, 120, 24, T("Proceed"))
    ApplyUIFont(sharedImportConfirmButton, 12)
    sharedImportConfirmButton:SetPoint("BOTTOMRIGHT", sharedImportPopup, "BOTTOMRIGHT", -55, 15)
    sharedImportConfirmButton:SetTemplate(options_button_template)
    sharedImportPopup:Hide()

    local conflictImportPopup = DF:CreateSimplePanel(NSUI, 430, 170, T("Profile Already Exists"), "NSUIProfileImportConflict", {
        DontRightClickClose = true
    })
    ApplyUIFont(conflictImportPopup.Title, 12)
    conflictImportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    conflictImportPopup:SetFrameLevel(110)

    local conflictImportLabel = DF:CreateLabel(conflictImportPopup, "", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    ApplyUIFont(conflictImportLabel, 12)
    conflictImportLabel:SetPoint("TOPLEFT", conflictImportPopup, "TOPLEFT", 15, -35)
    conflictImportLabel:SetPoint("RIGHT", conflictImportPopup, "RIGHT", -15, 0)
    conflictImportLabel:SetJustifyH("LEFT")
    conflictImportLabel:SetWordWrap(true)

    local conflictImportCancelButton = DF:CreateButton(conflictImportPopup, function()
        pendingConflictImport = nil
        conflictImportPopup:Hide()
    end, 110, 24, T("Cancel"))
    ApplyUIFont(conflictImportCancelButton, 12)
    conflictImportCancelButton:SetPoint("BOTTOMLEFT", conflictImportPopup, "BOTTOMLEFT", 15, 15)
    conflictImportCancelButton:SetTemplate(options_button_template)

    local conflictImportCopyButton = DF:CreateButton(conflictImportPopup, function()
        local import = pendingConflictImport
        pendingConflictImport = nil
        conflictImportPopup:Hide()
        if import then CompleteImport(import.string, false, false, import.profileName) end
    end, 110, 24, T("Create Copy"))
    ApplyUIFont(conflictImportCopyButton, 12)
    conflictImportCopyButton:SetPoint("BOTTOM", conflictImportPopup, "BOTTOM", 0, 15)
    conflictImportCopyButton:SetTemplate(options_button_template)

    local conflictImportOverwriteButton = DF:CreateButton(conflictImportPopup, function()
        local import = pendingConflictImport
        pendingConflictImport = nil
        conflictImportPopup:Hide()
        if import then CompleteImport(import.string, false, true, import.profileName) end
    end, 110, 24, T("Overwrite"))
    ApplyUIFont(conflictImportOverwriteButton, 12)
    conflictImportOverwriteButton:SetPoint("BOTTOMRIGHT", conflictImportPopup, "BOTTOMRIGHT", -15, 15)
    conflictImportOverwriteButton:SetTemplate(options_button_template)
    conflictImportPopup:Hide()

    CompleteImport = function(importString, allowSharedData, overwrite, profileName)
        local importedName, importError
        if overwrite then
            importedName, importError = NSAPI:OverrideProfile(importString, profileName, {allowSharedData = allowSharedData})
        else
            importedName, importError = NSAPI:ImportProfileString(importString, profileName, allowSharedData)
        end
        if importError == "shared_data" then
            pendingSharedImport = { string = importString, overwrite = overwrite, profileName = profileName }
            sharedImportPopup:Show()
        elseif importedName then
            print("|cFF00FFFFNSRT:|r " .. format(T("Imported profile '|cFFFFFFFF%s|r'."), importedName))
            popup:Hide()
            NSUI.MenuFrame:SelectTabByName("General")
            NSI:ConfirmApplyProfileToAllCharacters(importedName)
        else
            statusLabel:SetText("|cFFFF0000" .. T("Invalid import string. Please check and try again.") .. "|r")
        end
    end

    popup.import_confirm_button = DF:CreateButton(popup, function()
        local importString = popup.test_string_text_box:GetText()
        local exportTable = NSI:DecodeExportData(importString, "Profile")
        if type(exportTable) ~= "table" then
            statusLabel:SetText("|cFFFF0000" .. T("Invalid import string. Please check and try again.") .. "|r")
            return
        end

        local profileName = exportTable.profileName or "Imported"
        if NSAPI:ProfileExists(profileName) then
            pendingConflictImport = { string = importString, profileName = profileName }
            conflictImportLabel:SetText(format(T("A profile named '|cFFFFFFFF%s|r' already exists. Overwrite it or create a copy?"), profileName))
            conflictImportPopup:Show()
        else
            CompleteImport(importString, false, false, profileName)
        end
    end, 280, 20, T("Import"))
    ApplyUIFont(popup.import_confirm_button, 12)
    popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.import_confirm_button:SetTemplate(options_button_template)

    popup:HookScript("OnShow", function()
        popup:SetTitle(T("Import Profile"))
        statusLabel:SetText(T("Paste a profile string below and click Import."))
        popup.test_string_text_box:SetText("")
        popup.test_string_text_box:SetFocus()
    end)

    popup:Hide()
    return popup
end

local function BuildGroupExportUI()
    local popup = DF:CreateSimplePanel(NSUI, 800, 250, T("Export Group Composition"), "NSUIGroupExport", {
        DontRightClickClose = true
    })
    ApplyUIFont(popup.Title, 12)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    popup.text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "GroupExportTextEdit", true, false, true)
    popup.text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    popup.text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -20, 40)
    DF:ApplyStandardBackdrop(popup.text_box)
    DF:ReskinSlider(popup.text_box.scroll)
    popup.text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    NSI:SetUIFont(popup.text_box.editbox, 13, "OUTLINE")

    popup.done_button = DF:CreateButton(popup, function()
        popup:Hide()
    end, 280, 20, T("Done"))
    ApplyUIFont(popup.done_button, 12)
    popup.done_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.done_button:SetTemplate(options_button_template)

    popup:HookScript("OnShow", function()
        popup:SetTitle(T("Export Group Composition"))
        local exportString = NSI:GetGroupExportString()
        popup.text_box:SetText(exportString or "")
        popup.text_box:SetFocus()
        popup.text_box:HighlightText()
    end)

    popup:Hide()
    return popup
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.General= {
    BuildExportStringUI  = BuildExportStringUI,
    BuildImportStringUI  = BuildImportStringUI,
    BuildGroupExportUI   = BuildGroupExportUI,
}
