local _, NSI = ...
local DF = _G["DetailsFramework"]
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")
local function build_anchor_options(SettingsName)
    local list = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183][SettingsName] = list[value]
                if NSI.IsLuraPreview then
                    NSI.EncounterAlertStart[3183](NSI, 15, true)
                end
            end
        })
    end
    return t
end

local function build_P3Side_options(SettingsName)
    local list = {"OFF", "LEFT", "RIGHT", "BOTH"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183].P3Side = list[value]
            end
        })
    end
    return t
end

local ShowLinkPopup
local function ShowLink(Text, Name, URL)
    if not ShowLinkPopup then
        ShowLinkPopup = DF:CreateSimplePanel(UIParent, 300, 60, "", "NSRTWAImportPopup")
        ShowLinkPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        ShowLinkPopup:SetFrameLevel(100)

        ShowLinkPopup.text_entry = DF:CreateTextEntry(ShowLinkPopup, function() end, 280, 20)
        ShowLinkPopup.text_entry:SetTemplate(options_button_template)
        ShowLinkPopup.text_entry:SetPoint("TOP", ShowLinkPopup, "TOP", 0, -30)
        ShowLinkPopup.text_entry.editbox:SetJustifyH("CENTER")

        ShowLinkPopup.text_entry:SetScript("OnEditFocusGained", function(self)
            ShowLinkPopup.text_entry.editbox:HighlightText()
        end)
    end

    ShowLinkPopup:SetTitle(Text)
    local currentURL = URL
    ShowLinkPopup.text_entry:SetText(currentURL)
    ShowLinkPopup.text_entry:SetScript("OnTextChanged", function(self)
        ShowLinkPopup.text_entry:SetText(currentURL)
        ShowLinkPopup.text_entry.editbox:HighlightText()
    end)

    ShowLinkPopup:Show()
    ShowLinkPopup.text_entry:SetFocus()
end

local function BuildEncounterAlertsOptions()
    return {
    }
end

local function BuildEncounterAlertsCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.EncounterAlerts = {
    BuildOptions = BuildEncounterAlertsOptions,
    BuildCallback = BuildEncounterAlertsCallback,
}
