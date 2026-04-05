local _, NSI = ...
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

    wa_popup:SetTitle(Text)

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
    return {
        {
            type = "label",
            get = function() return "You will need to get a compatible WA fork for this yourself. The buttons provide you the wago link to each of the auras." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true
        },
        {
            type = "button",
            name = "Heal Absorb WA",
            desc = "Link to a WA that shows the Heal Absorb on Raidframes.",
            func = function(self)
                WAButton("Heal Absorb WA", "PaladinsHealAbsorb", "https://wago.io/lylBMpoMB")
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Paladins Dispel Assign",
            desc = "Link to a WA that assigns avenger's shield dispels - All healers, warlocks and dwarfs should have this. Dwarfs get the lowest priority on getting assigned. They will be told to use their racial if there are more debuffs than dispellers available.",
            func = function(self)
                WAButton("Paladins Dispel Assign", "PaladinsDispelAssign", "https://wago.io/NspRXIk6n")
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Alleria P1 Dmg Amp",
            desc = "Displays the stacks of the dmg amp debuff on the nameplate of the 3 big adds. It is not perfect and might not display at all in some instances but it's better than nothing.",
            func = function(self)
                WAButton("Alleria P1 Dmg Amp", "AlleriaP1DmgAmp", "https://wago.io/yh2rnY4_8")
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Belo'ren Feather Color",
            desc = "Displays your Feather-Color on Belo'ren.",
            func = function(self)
                WAButton("Belo'ren Feather Color", "BelorenFeatherColor", "https://wago.io/dHBF7wW34")
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Lura Interrupts",
            desc = "Interrupt WA for Lura P1.",
            func = function(self)
                WAButton("Lura Interrupts", "LuraInterrupts", "https://wago.io/ymoJBMQF0")
            end,
            nocombat = true
        },
    }
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
