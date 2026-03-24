local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local build_PAgrowdirection_options = Core.build_PAgrowdirection_options

local function BuildPrivateAurasOptions()
    return {
        {
            type = "label",
            get = function() return L["OPT_PA_PERSONAL_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_ENABLED"],
            desc = L["OPT_PA_DESC_ENABLED"],
            get = function() return NSRT.PASettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.enabled = value
                NSI:InitPA()
            end,
        },
        {
            type = "button",
            name = L["OPT_PA_PREVIEW_UNLOCK"],
            desc = L["OPT_PA_DESC_PREVIEW_UNLOCK"],
            func = function(self)
                NSI.IsPAPreview = not NSI.IsPAPreview
                NSI:UpdatePADisplay(true)
            end,
            spacement = true
        },
        {
            type = "select",
            name = L["OPT_COMMON_GROW_DIRECTION"],
            desc = L["OPT_COMMON_GROW_DIRECTION"],
            get = function() return NSRT.PASettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PASettings", "GrowDirection") end,
        },
        {
            type = "range",
            name = L["OPT_PA_SPACING"],
            desc = L["OPT_PA_DESC_SPACING"],
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
            name = L["OPT_COMMON_WIDTH"],
            desc = L["OPT_PA_DESC_WIDTH"],
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
            name = L["OPT_COMMON_HEIGHT"],
            desc = L["OPT_PA_DESC_HEIGHT"],
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
            name = L["OPT_PA_X_OFFSET"],
            desc = L["OPT_PA_DESC_X_OFFSET"],
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
            name = L["OPT_PA_Y_OFFSET"],
            desc = L["OPT_PA_DESC_Y_OFFSET"],
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
            name = L["OPT_PA_MAX_ICONS"],
            desc = L["OPT_PA_DESC_MAX_ICONS"],
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
            name = L["OPT_PA_STACK_SCALE"],
            desc = L["OPT_PA_DESC_STACK_SCALE"],
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
            name = L["OPT_PA_UPSCALE_DURATION_TEXT"],
            desc = L["OPT_PA_DESC_UPSCALE_DURATION_TEXT"],
            get = function() return NSRT.PASettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.UpscaleDuration = value
                NSI:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_HIDE_BORDER"],
            desc = L["OPT_PA_DESC_HIDE_BORDER_PLAYER"],
            get = function() return NSRT.PASettings.HideBorder end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.HideBorder = value
                NSI:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_DISABLE_TOOLTIP"],
            desc = L["OPT_PA_DESC_DISABLE_TOOLTIP"],
            get = function() return NSRT.PASettings.HideTooltip end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.HideTooltip = value
                NSI:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_ALTERNATE_DISPLAY"],
            desc = L["OPT_PA_DESC_ALTERNATE_DISPLAY"],
            get = function() return NSRT.PASettings.AlternateDisplay end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.AlternateDisplay = value
                NSI:UpdatePADisplay(true)
            end,
        },
        {
            type = "label",
            get = function() return L["OPT_PA_PERSONAL_TEXT_WARNING"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_ENABLED"],
            desc = L["OPT_PA_DESC_TEXT_WARNING_ENABLED"],
            get = function() return NSRT.PATextSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PATextSettings.enabled = value
                NSI:InitTextPA()
            end,
        },
        {
            type = "range",
            name = L["OPT_PA_SCALE"],
            desc = L["OPT_PA_DESC_TEXT_WARNING_SCALE"],
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
            get = function() return L["OPT_PA_RAIDFRAME_SETTINGS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_ENABLED"],
            desc = L["OPT_PA_DESC_RAIDFRAME_ENABLED"],
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
        },
        {
            type = "button",
            name = L["OPT_PA_PREVIEW"],
            desc = L["OPT_PA_DESC_RAIDFRAME_PREVIEW"],
            func = function(self)
                NSI.IsRaidPAPreview = not NSI.IsRaidPAPreview
                NSI:UpdatePADisplay(false)
            end,
            spacement = true
        },
        {
            type = "select",
            name = L["OPT_COMMON_GROW_DIRECTION"],
            desc = L["OPT_PA_DESC_GROW_DIRECTION_CONFLICT"],
            get = function() return NSRT.PARaidSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "GrowDirection") end,
        },
        {
            type = "select",
            name = L["OPT_PA_ROW_GROW_DIRECTION"],
            desc = L["OPT_PA_DESC_ROW_GROW_DIRECTION"],
            get = function() return NSRT.PARaidSettings.RowGrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "RowGrowDirection") end,
        },
        {
            type = "range",
            name = L["OPT_PA_ICONS_PER_ROW"],
            desc = L["OPT_PA_DESC_ICONS_PER_ROW"],
            get = function() return NSRT.PARaidSettings.PerRow end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.PerRow = value
                NSI:UpdatePADisplay(false)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = L["OPT_PA_SPACING"],
            desc = L["OPT_PA_DESC_SPACING"],
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
            name = L["OPT_COMMON_WIDTH"],
            desc = L["OPT_PA_DESC_WIDTH"],
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
            name = L["OPT_COMMON_HEIGHT"],
            desc = L["OPT_PA_DESC_HEIGHT"],
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
            name = L["OPT_PA_X_OFFSET"],
            desc = L["OPT_PA_DESC_X_OFFSET"],
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
            name = L["OPT_PA_Y_OFFSET"],
            desc = L["OPT_PA_DESC_Y_OFFSET"],
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
            name = L["OPT_PA_MAX_ICONS"],
            desc = L["OPT_PA_DESC_MAX_ICONS"],
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
            name = L["OPT_PA_STACK_SCALE"],
            desc = L["OPT_PA_DESC_RAIDFRAME_STACK_SCALE"],
            get = function() return NSRT.PARaidSettings.StackScale or 1.1 end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.StackScale = value
                NSI:UpdatePADisplay(false)
            end,
            min = 1,
            max = 5,
            step = 0.1,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_HIDE_BORDER"],
            desc = L["OPT_PA_DESC_HIDE_BORDER_RAIDFRAME"],
            get = function() return NSRT.PARaidSettings.HideBorder end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.HideBorder = value
                NSI:UpdatePADisplay(false)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_HIDE_DURATION_TEXT"],
            desc = L["OPT_PA_DESC_HIDE_DURATION_TEXT"],
            get = function() return NSRT.PARaidSettings.HideDurationText end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.HideDurationText = value
                NSI:UpdatePADisplay(false)
            end,
        },
        {
            type = "breakline"
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_SHOW_DEBUFF_TYPE_INDICATOR"],
            desc = L["OPT_PA_DESC_SHOW_DEBUFF_TYPE_INDICATOR"],
            get = function() return NSRT.PARaidSettings.DebuffTypeBorder end,
            set = function(self, fixedparam, value)
                if NSI.IsBuilding then return end
                NSRT.PARaidSettings.DebuffTypeBorder = value
                C_UnitAuras.TriggerPrivateAuraShowDispelType(value)
            end,
        },
        {
            type = "label",
            get = function() return L["PA_SOUND_TITLE"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = L["OPT_PA_EDIT_SOUNDS"],
            desc = L["OPT_PA_DESC_EDIT_SOUNDS"],
            func = function()
                if not NSUI.pasound_frame:IsShown() then
                    NSUI.pasound_frame:Show()
                end
            end,
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_USE_DEFAULT_RAID_SOUNDS"],
            desc = L["OPT_PA_DESC_USE_DEFAULT_RAID_SOUNDS"],
            get = function() return NSRT.PASounds.UseDefaultPASounds end,
            set = function(self, fixedparam, value)
                NSRT.PASounds.UseDefaultPASounds = value
                if NSRT.PASounds.UseDefaultPASounds then
                    NSI:ApplyDefaultPASounds(true)
                    NSI:RefreshPASoundEditUI()
                end
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_USE_DEFAULT_MPLUS_SOUNDS"],
            desc = L["OPT_PA_DESC_USE_DEFAULT_MPLUS_SOUNDS"],
            get = function() return NSRT.PASounds.UseDefaultMPlusPASounds end,
            set = function(self, fixedparam, value)
                NSRT.PASounds.UseDefaultMPlusPASounds = value
                if NSRT.PASounds.UseDefaultMPlusPASounds then
                    NSI:ApplyDefaultPASounds(true, true)
                    NSI:RefreshPASoundEditUI()
                end
            end,
        },
        {
            type = "breakline",
        },

        {
            type = "label",
            get = function() return L["OPT_PA_COTANK_PRIVATE_AURAS"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_ENABLED"],
            desc = L["OPT_PA_DESC_COTANK_ENABLED"],
            get = function() return NSRT.PATankSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.enabled = value
            end,
        },
        {
            type = "button",
            name = L["OPT_PA_PREVIEW_UNLOCK"],
            desc = L["OPT_PA_DESC_COTANK_PREVIEW_UNLOCK"],
            func = function(self)
                NSI.IsTankPAPreview = not NSI.IsTankPAPreview
                NSI:UpdatePADisplay(false, true)
            end,
            spacement = true
        },
        {
            type = "select",
            name = L["OPT_COMMON_GROW_DIRECTION"],
            desc = L["OPT_COMMON_GROW_DIRECTION"],
            get = function() return NSRT.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "GrowDirection") end,
        },
        {
            type = "range",
            name = L["OPT_PA_SPACING"],
            desc = L["OPT_PA_DESC_SPACING"],
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
            name = L["OPT_COMMON_WIDTH"],
            desc = L["OPT_PA_DESC_WIDTH"],
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
            name = L["OPT_COMMON_HEIGHT"],
            desc = L["OPT_PA_DESC_HEIGHT"],
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
            name = L["OPT_PA_X_OFFSET"],
            desc = L["OPT_PA_DESC_X_OFFSET"],
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
            name = L["OPT_PA_Y_OFFSET"],
            desc = L["OPT_PA_DESC_Y_OFFSET"],
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
            name = L["OPT_PA_MAX_ICONS"],
            desc = L["OPT_PA_DESC_MAX_ICONS"],
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
            name = L["OPT_PA_STACK_SCALE"],
            desc = L["OPT_PA_DESC_STACK_SCALE"],
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
            name = L["OPT_PA_UPSCALE_DURATION_TEXT"],
            desc = L["OPT_PA_DESC_UPSCALE_DURATION_TEXT"],
            get = function() return NSRT.PATankSettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.UpscaleDuration = value
                NSI:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_HIDE_BORDER"],
            desc = L["OPT_PA_DESC_HIDE_BORDER_COTANK"],
            get = function() return NSRT.PATankSettings.HideBorder end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.HideBorder = value
                NSI:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_DISABLE_TOOLTIP"],
            desc = L["OPT_PA_DESC_DISABLE_TOOLTIP"],
            get = function() return NSRT.PATankSettings.HideTooltip end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.HideTooltip = value
                NSI:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["OPT_PA_ALTERNATE_DISPLAY"],
            desc = L["OPT_PA_DESC_ALTERNATE_DISPLAY"],
            get = function() return NSRT.PATankSettings.AlternateDisplay end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.AlternateDisplay = value
                NSI:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "select",
            name = L["OPT_COMMON_GROW_DIRECTION"],
            desc = L["OPT_PA_DESC_MULTITANK_GROW_DIRECTION"],
            get = function() return NSRT.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "MultiTankGrowDirection") end,
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
