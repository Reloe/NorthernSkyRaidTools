local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local NSUI = Core.NSUI
local CreateLocalizedButton = NSI.UI.Components.CreateLocalizedButton

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
                local generalTab = NSUI.MenuFrame:GetTabFrameByName("General")
                generalTab:RefreshOptions()
            end
        end,
        T("Cancel")
    )
end

local function CreateLabel(parent, text, size, flags)
    local label = parent:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(label, size or 12, flags or "")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    return label
end

local function CreateProfilePopup(width, height, name, title)
    local popup = DF:CreateSimplePanel(UIParent, width, height, "|cFF00FFFF" .. title .. "|r", name, { UseScaleBar = false })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)
    return popup
end

local function BuildExportStringUI()
    local popup = CreateProfilePopup(800, 400, "NSUIExportString", T("Export Profile"))
    popup.IncludeSharedData = false

    local profileLabel = CreateLabel(popup, "", 13)
    profileLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    profileLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    profileLabel:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    profileLabel:SetWordWrap(true)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "ExportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -75)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -25, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    NSI:SetUIFont(popup.test_string_text_box.editbox, 13, "OUTLINE")

    popup.export_confirm_button = CreateLocalizedButton(popup, "Done", function()
        popup:Hide()
    end, 280, 20, "NSUIExportStringDone")
    popup.export_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)

    popup:HookScript("OnShow", function()
        local title = popup.IncludeSharedData and T("Export Profile + Shared Data") or T("Export Profile")
        popup:SetTitle("|cFF00FFFF" .. title .. "|r")
        local label = format(T("Exporting profile: |cFF00FFFF%s|r"), NSRT.CurrentProfile or "default")
        if popup.IncludeSharedData then
            label = label .. "\n" .. T("Includes Encounter Alerts, Aura Sounds, Aura Tracking and Aura Glows. Nicknames are never included.")
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
    local popup = CreateProfilePopup(800, 400, "NSUIImportString", T("Import Profile"))

    local statusLabel = CreateLabel(popup, T("Paste a profile string below and click Import."), 13)
    statusLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    statusLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "ImportStringTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -50)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -25, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    NSI:SetUIFont(popup.test_string_text_box.editbox, 13, "OUTLINE")

    local pendingSharedImport
    local pendingConflictImport
    local CompleteImport
    local sharedImportPopup = CreateProfilePopup(430, 170, "NSUISharedImportConfirm", T("Import Profile"))
    sharedImportPopup:SetFrameLevel(110)

    local sharedImportLabel = CreateLabel(sharedImportPopup, T("This import will overwrite your settings for Encounter Alerts, Aura Sounds, Aura Tracking and Aura Glows, proceed?"), 13)
    sharedImportLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    sharedImportLabel:SetPoint("TOPLEFT", sharedImportPopup, "TOPLEFT", 15, -35)
    sharedImportLabel:SetPoint("RIGHT", sharedImportPopup, "RIGHT", -15, 0)
    sharedImportLabel:SetJustifyH("LEFT")
    sharedImportLabel:SetWordWrap(true)

    local sharedImportCancelButton = CreateLocalizedButton(sharedImportPopup, "Cancel", function()
        pendingSharedImport = nil
        sharedImportPopup:Hide()
    end, 120, 24, "NSUISharedImportCancel")
    sharedImportCancelButton:SetPoint("BOTTOMLEFT", sharedImportPopup, "BOTTOMLEFT", 55, 15)

    local sharedImportConfirmButton = CreateLocalizedButton(sharedImportPopup, "Proceed", function()
        local import = pendingSharedImport
        pendingSharedImport = nil
        sharedImportPopup:Hide()
        if import then CompleteImport(import.string, true, import.overwrite, import.profileName) end
    end, 120, 24, "NSUISharedImportProceed")
    sharedImportConfirmButton:SetPoint("BOTTOMRIGHT", sharedImportPopup, "BOTTOMRIGHT", -55, 15)
    sharedImportPopup:Hide()

    local conflictImportPopup = CreateProfilePopup(430, 170, "NSUIProfileImportConflict", T("Profile Already Exists"))
    conflictImportPopup:SetFrameLevel(110)

    local conflictImportLabel = CreateLabel(conflictImportPopup, "", 13)
    conflictImportLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    conflictImportLabel:SetPoint("TOPLEFT", conflictImportPopup, "TOPLEFT", 15, -35)
    conflictImportLabel:SetPoint("RIGHT", conflictImportPopup, "RIGHT", -15, 0)
    conflictImportLabel:SetJustifyH("LEFT")
    conflictImportLabel:SetWordWrap(true)

    local conflictImportCancelButton = CreateLocalizedButton(conflictImportPopup, "Cancel", function()
        pendingConflictImport = nil
        conflictImportPopup:Hide()
    end, 110, 24, "NSUIProfileImportConflictCancel")
    conflictImportCancelButton:SetPoint("BOTTOMLEFT", conflictImportPopup, "BOTTOMLEFT", 15, 15)

    local conflictImportCopyButton = CreateLocalizedButton(conflictImportPopup, "Create Copy", function()
        local import = pendingConflictImport
        pendingConflictImport = nil
        conflictImportPopup:Hide()
        if import then CompleteImport(import.string, false, false, import.profileName) end
    end, 110, 24, "NSUIProfileImportConflictCopy")
    conflictImportCopyButton:SetPoint("BOTTOM", conflictImportPopup, "BOTTOM", 0, 15)

    local conflictImportOverwriteButton = CreateLocalizedButton(conflictImportPopup, "Overwrite", function()
        local import = pendingConflictImport
        pendingConflictImport = nil
        conflictImportPopup:Hide()
        if import then CompleteImport(import.string, false, true, import.profileName) end
    end, 110, 24, "NSUIProfileImportConflictOverwrite")
    conflictImportOverwriteButton:SetPoint("BOTTOMRIGHT", conflictImportPopup, "BOTTOMRIGHT", -15, 15)
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

    popup.import_confirm_button = CreateLocalizedButton(popup, "Import", function()
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
    end, 280, 20, "NSUIImportStringConfirm")
    popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)

    popup:HookScript("OnShow", function()
        popup:SetTitle("|cFF00FFFF" .. T("Import Profile") .. "|r")
        statusLabel:SetText(T("Paste a profile string below and click Import."))
        popup.test_string_text_box:SetText("")
        popup.test_string_text_box:SetFocus()
    end)

    popup:Hide()
    return popup
end

local function BuildGroupExportUI()
    local popup = CreateProfilePopup(800, 250, "NSUIGroupExport", T("Export Group Composition"))

    popup.text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "GroupExportTextEdit", true, false, true)
    popup.text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    popup.text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -25, 40)
    DF:ApplyStandardBackdrop(popup.text_box)
    DF:ReskinSlider(popup.text_box.scroll)
    popup.text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    NSI:SetUIFont(popup.text_box.editbox, 13, "OUTLINE")

    popup.done_button = CreateLocalizedButton(popup, "Done", function()
        popup:Hide()
    end, 280, 20, "NSUIGroupExportDone")
    popup.done_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)

    popup:HookScript("OnShow", function()
        popup:SetTitle("|cFF00FFFF" .. T("Export Group Composition") .. "|r")
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
