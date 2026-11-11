local NSI = _G.NorthernSkyRaidTools
local Core = NSI.UI.Core

-- Import / export dialogs for the Encounter Alerts screen.
-- ShowExportPopup / ShowImportPopup are exported on NSI.UI.EncounterAlertParts.Popups;
-- NSI:PromptReloeReminderImport is a public method used by the Reminders options.

-- ============================================================================
-- Alert Export / Import popups
-- ============================================================================

function NSI:PromptReloeReminderImport(onImport)
    local function DoImport()
        self:ImportReloeReminders(nil, true)
        local NSUI = Core.NSUI
        local enc = NSUI and NSUI.encounters_frame
        if enc and enc.RebuildList then enc.RebuildList() end
        if enc and enc.RefreshSelected then enc.RefreshSelected() end
        if onImport then onImport() end
    end
    local dialog = self.UI.Components.CreateDialog(
        "NSRTReloeReminderImport",
        NSI:Loc("Enable Reloe-Alerts"),
        NSI:Loc("Do you want to enable Reloe-Alerts now? If you made manual changes to an alert already this won't overwrite that."),
        NSI:Loc("Enable"), DoImport, NSI:Loc("Not Now"), nil)
    dialog:Show()
end

local function ShowExportPopup(str, label)
    NSI.UI.Components.CreateTextBoxDialog("AlertsExport", NSI.UI.Style.AccentCode() .. NSI:Loc("Export Alerts") .. "|r", { readOnly = true }):Open(str or "", label)
end

local function ShowImportPopup()
    local dialog = NSI.UI.Components.CreateTextBoxDialog("AlertsImport", NSI.UI.Style.AccentCode() .. NSI:Loc("Import Alerts") .. "|r",
        { okText = NSI:Loc("Import"), cancelText = NSI:Loc("Cancel") })
    dialog:Open("", NSI:Loc("Paste an alerts export string below and click Import."), function(text, d)
        local count, overwriteCount = NSAPI:ImportAlertsString(text)
        if not count then
            d:SetStatus(NSI:Loc("Invalid import string. Please check and try again."), true)
            return false
        end
        print(NSI.UI.Style.AccentCode() .. "NSRT:|r " .. string.format(NSI:Loc("Imported %d alert(s)."), count))
        if overwriteCount and overwriteCount > 0 then
            print("|cFFFFFF00NSRT:|r " .. string.format(NSI:Loc("Overwritten %d alert(s)."), overwriteCount))
        end
        local NSUI = Core.NSUI
        local enc = NSUI and NSUI.encounters_frame
        if enc and enc.RebuildList then enc.RebuildList() end
        if enc and enc.RefreshSelected then enc.RefreshSelected() end
        return true
    end)
end

NSI.UI = NSI.UI or {}
NSI.UI.EncounterAlertParts = NSI.UI.EncounterAlertParts or {}
NSI.UI.EncounterAlertParts.Popups = {
    ShowExportPopup = ShowExportPopup,
    ShowImportPopup = ShowImportPopup,
}
