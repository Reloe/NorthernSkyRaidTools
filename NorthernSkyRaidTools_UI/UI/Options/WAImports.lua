local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

local wa_popup

local function WAButton(Text, Name, URL)
    if not wa_popup then
        wa_popup = DF:CreateSimplePanel(UIParent, 300, 60, "", "NSRTWAImportPopup")
        wa_popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        wa_popup:SetFrameLevel(100)

        wa_popup.text_entry = DF:CreateTextEntry(wa_popup, function() end, 280, 20)
        wa_popup.text_entry:SetTemplate(options_button_template)
        wa_popup.text_entry:SetPoint("TOP", wa_popup, "TOP", 0, -30)
        wa_popup.text_entry.editbox:SetJustifyH("CENTER")

        wa_popup.text_entry:SetScript("OnEditFocusGained", function(self)
            wa_popup.text_entry.editbox:HighlightText()
        end)
    end

    wa_popup:SetTitle(NSI:Loc(Text))

    local currentURL = URL
    wa_popup.text_entry:SetText(currentURL)
    wa_popup.text_entry:SetScript("OnTextChanged", function(self)
        wa_popup.text_entry:SetText(currentURL)
        wa_popup.text_entry.editbox:HighlightText()
    end)

    wa_popup:Show()
    wa_popup.text_entry:SetFocus()
end

local function BuildWAImportsOptions()
    return {}
end

local function BuildWACallback()
    return function(_, _, _, optionTable)
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.WAImports = {
    BuildOptions = BuildWAImportsOptions,
    BuildCallback = BuildWACallback,
}
