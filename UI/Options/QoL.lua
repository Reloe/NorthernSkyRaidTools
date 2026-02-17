local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildQoLOptions()
    return {
        {
            type = "label",
            get = function() return "Text Display Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview and Move the Text Display.",
            func = function(self)
                NSI.IsQoLTextPreview = not NSI.IsQoLTextPreview
                NSI:ToggleQoLTextPreview()
            end,
            spacement = true
        },
        {
            type = "range",
            name = "Font Size",
            desc = "Font Size for Text Display",
            get = function() return NSRT.QoL.TextDisplay.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.QoL.TextDisplay.FontSize = value
                NSI:UpdateQoLTextDisplay()
            end,
            min = 5,
            max = 40,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Gateway Useable Display",
            desc = "Whether you want to see a display when you are able to use the gateway.",
            get = function() return NSRT.QoL.GatewayUseableDisplay end,
            set = function(self, fixedparam, value)
                NSRT.QoL.GatewayUseableDisplay = value
                NSI:UpdateQoLTextDisplay()
                NSI:ToggleQoLEvent("ACTIONBAR_UPDATE_USABLE", value)
            end,
        },
        {
            type = "breakline",
        },
    }
end

local function BuildQoLCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.QoL = {
    BuildOptions = BuildQoLOptions,
    BuildCallback = BuildQoLCallback,
}
