local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local build_PAgrowdirection_options = Core.build_PAgrowdirection_options

local function BuildPrivateAurasOptions()
    return {
        {
            type = "label",
            get = function() return "Personal Private Aura Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura Display is enabled",
            get = function() return NSRT.PASettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.enabled = value
                NSI:InitPA()
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Private Auras to move them around.",
            func = function(self)
                NSI.IsPAPreview = not NSI.IsPAPreview
                NSI:UpdatePADisplay(true)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.PASettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PASettings", "GrowDirection") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return NSRT.PASettings.Spacing end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Spacing = value
                NSI:UpdatePADisplay(true)
            end,
            min = -5,
            max = 20,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return NSRT.PASettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Width = value
                NSI:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return NSRT.PASettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Height = value
                NSI:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return NSRT.PASettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.xOffset = value
                NSI:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return NSRT.PASettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.yOffset = value
                NSI:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return NSRT.PASettings.Limit end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Limit = value
                NSI:UpdatePADisplay(true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "This will scale the Stack Display",
            get = function() return NSRT.PASettings.StackScale or 4 end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.StackScale = value
                NSI:UpdatePADisplay(true)
            end,
            min = 1,
            max = 10,
            step = 0.1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Upscale Duration Text",
            desc = "This will upscale the Duration Text(uses same scale as stack text). Unfortunately using this means you will see '6 s' instead of just '6' as this is how Blizzard displays it.",
            get = function() return NSRT.PASettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.UpscaleDuration = value
                NSI:UpdatePADisplay(true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Player Private Auras. This includes stuff like the dispel icon.",
            get = function() return NSRT.PASettings.HideBorder end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.HideBorder = value
                NSI:UpdatePADisplay(true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Tooltip",
            desc = "Hide tooltips on mouseover. The frame will be clickthrough regardless.",
            get = function() return NSRT.PASettings.HideTooltip end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.HideTooltip = value
                NSI:UpdatePADisplay(true)
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Personal Private Aura Text-Warning" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura Text-Warning is enabled",
            get = function() return NSRT.PATextSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PATextSettings.enabled = value
                NSI:InitTextPA()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Scale",
            desc = "Scale of the Private Aura Text-Warning Anchor",
            get = function() return NSRT.PATextSettings.Scale end,
            set = function(self, fixedparam, value)
                NSRT.PATextSettings.Scale = value
                NSI:UpdatePADisplay(true)
            end,
            min = 0.1,
            max = 5,
            step = 0.1,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "RaidFrame Private Aura Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura on Raidframes are enabled",
            get = function() return NSRT.PARaidSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.enabled = value
                if NSRT.PARaidSettings.enabled then
                    NSI:InitRaidPA(not UnitInRaid("player"))
                else
                    NSI:InitRaidPA(true)
                    NSI:InitRaidPA(false)
                end
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Preview",
            desc = "Preview Private Auras on your own Raidframe. This only works if you actually have a frame for yourself and you can't drag this one around, use the x/y offset instead.",
            func = function(self)
                NSI.IsRaidPAPreview = not NSI.IsRaidPAPreview
                NSI:UpdatePADisplay(false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.PARaidSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "GrowDirection") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.Spacing end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Spacing = value
                NSI:UpdatePADisplay(false)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Width = value
                NSI:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Height = value
                NSI:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.xOffset = value
                NSI:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.yOffset = value
                NSI:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return NSRT.PARaidSettings.Limit end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Limit = value
                NSI:UpdatePADisplay(false)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "This will scale the Stack Display",
            get = function() return NSRT.PARaidSettings.StackScale or 1 end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.StackScale = value
                NSI:UpdatePADisplay(false)
            end,
            min = 0.1,
            max = 5,
            step = 0.1,
        },
        
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Raidframe Private Auras. This includes stuff like the dispel icon. (Tooltip is always disabled for Raidframes)",
            get = function() return NSRT.PARaidSettings.HideBorder end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.HideBorder = value
                NSI:UpdatePADisplay(false)
            end,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Private Aura Sounds" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Edit Sounds",
            desc = "Open the Private Aura Sounds Editor",
            func = function()
                if not NSUI.pasound_frame:IsShown() then
                    NSUI.pasound_frame:Show()
                end
            end,
            nocombat = true,
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Default RAID Private Aura Sounds",
            desc = "This applies Sounds to all Raid Private Auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spellid's yourself previously this button will NOT overwrite that.",
            get = function() return NSRT.UseDefaultPASounds end,
            set = function(self, fixedparam, value)
                NSRT.UseDefaultPASounds = value
                if NSRT.UseDefaultPASounds then
                    NSI:ApplyDefaultPASounds(true)
                    NSI:RefreshPASoundEditUI()
                end
            end,
            nocombat = true,
        },
        
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Default M+ Private Aura Sounds",
            desc = "This will likely be less maintained than the Raid ones, otherwise it works the same as that one.",
            get = function() return NSRT.PASounds.UseDefaultMPlusPASounds end,
            set = function(self, fixedparam, value)
                NSRT.PASounds.UseDefaultMPlusPASounds = value
                if NSRT.PASounds.UseDefaultMPlusPASounds then
                    NSI:ApplyDefaultPASounds(true, true)
                    NSI:RefreshPASoundEditUI()
                end
            end,
            nocombat = true,
        },
        {
            type = "breakline",
        },

        {
            type = "label",
            get = function() return "Co-Tank Private Auras" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Auras for Co-Tanks are enabled",
            get = function() return NSRT.PATankSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.enabled = value
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Co-Tank Private Auras.",
            func = function(self)
                NSI.IsTankPAPreview = not NSI.IsTankPAPreview
                NSI:UpdatePADisplay(false, true)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "GrowDirection") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return NSRT.PATankSettings.Spacing end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Spacing = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return NSRT.PATankSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Width = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return NSRT.PATankSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Height = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return NSRT.PATankSettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.xOffset = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return NSRT.PATankSettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.yOffset = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return NSRT.PATankSettings.Limit end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Limit = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "This will scale the Stack Display",
            get = function() return NSRT.PATankSettings.StackScale or 4 end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.StackScale = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = 1,
            max = 10,
            step = 0.1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Upscale Duration Text",
            desc = "This will upscale the Duration Text(uses same scale as stack text). Unfortunately using this means you will see '6 s' instead of just '6' as this is how Blizzard displays it.",
            get = function() return NSRT.PATankSettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.UpscaleDuration = value
                NSI:UpdatePADisplay(false, true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Co-Tank Private Auras. This includes stuff like the dispel icon.",
            get = function() return NSRT.PATankSettings.HideBorder end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.HideBorder = value
                NSI:UpdatePADisplay(false, true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Tooltip",
            desc = "Hide tooltips on mouseover. The frame will be clickthrough regardless.",
            get = function() return NSRT.PATankSettings.HideTooltip end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.HideTooltip = value
                NSI:UpdatePADisplay(false, true)
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "This is the Grow-Direction used if there are more than 2 tanks. Rarely ever happens these days but has to be included.",
            get = function() return NSRT.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "MultiTankGrowDirection") end,
            nocombat = true,
        },
    }
end

local function BuildPrivateAurasCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.PrivateAuras = {
    BuildOptions = BuildPrivateAurasOptions,
    BuildCallback = BuildPrivateAurasCallback,
}
