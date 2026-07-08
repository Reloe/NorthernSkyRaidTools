local addonId, NSI = ...
local DF = _G["DetailsFramework"]

local FONT_FLAGS = {
    "",
    "OUTLINE",
    "THICKOUTLINE",
    "MONOCHROME",
    "OUTLINE, MONOCHROME",
    "THICKOUTLINE, MONOCHROME",
    "SLUG",
    "SLUG, OUTLINE",
    "SLUG, THICKOUTLINE",
    "SLUG, MONOCHROME",
    "SLUG, OUTLINE, MONOCHROME",
    "SLUG, THICKOUTLINE, MONOCHROME",
}

local function RebuildAuraTrackingOptionsMenu()
    if NSI.RebuildAuraTrackingOptionsMenu then
        C_Timer.After(0, function()
            NSI:RebuildAuraTrackingOptionsMenu()
        end)
    end
end

local function build_growdirection_options(settingsKey)
    local t = {}
    for _, direction in ipairs({"LEFT", "RIGHT", "UP", "DOWN"}) do
        t[#t + 1] = {
            value = direction,
            label = NSI:Loc(direction),
            phraseId = direction,
            onclick = function()
                NSI:GetAuraTrackingSettings(settingsKey).GrowDirection = direction
                NSI:UpdateAuraTrackingDisplay(settingsKey)
            end,
        }
    end
    return t
end

local function build_font_options(settingsKey)
    local t = {}
    for _, name in ipairs(NSI.LSM:List("font")) do
        t[#t + 1] = {
            label = name,
            value = name,
            onclick = function()
                NSI:GetAuraTrackingSettings(settingsKey).TextFont = name
                NSI:UpdateAuraTrackingDisplay(settingsKey)
            end,
        }
    end
    return t
end

local function build_font_flag_options(settingsKey)
    local t = {}
    for _, flags in ipairs(FONT_FLAGS) do
        t[#t + 1] = {
            label = flags == "" and NSI:Loc("None") or flags,
            value = flags,
            onclick = function()
                NSI:GetAuraTrackingSettings(settingsKey).TextFontFlags = flags
                NSI:UpdateAuraTrackingDisplay(settingsKey)
            end,
        }
    end
    return t
end

local function build_name_position_options(settingsKey)
    local t = {}
    for _, position in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        t[#t + 1] = {
            value = position,
            label = NSI:Loc(position),
            phraseId = position,
            onclick = function()
                NSI:GetAuraTrackingSettings(settingsKey).NamePosition = position
                NSI:UpdateAuraTrackingDisplay(settingsKey)
            end,
        }
    end
    return t
end

local AddAuraTrackingTopControls
local GetAuraTrackingSelectionOptions

local function AddAuraTrackingSection(options, settingsKey, label, previewFlag, iconTexture)
    local settings = NSI:GetAuraTrackingSettings(settingsKey)
    if not settings then return end
    local isCustom = tostring(settingsKey):match("^Custom:")
    local displayIconTexture = (isCustom and settings.PreviewSpellID and C_Spell.GetSpellTexture(settings.PreviewSpellID)) or iconTexture

    options[#options + 1] = {
        type = "select",
        name = "Aura Tracking Display",
        desc = "Select which Aura Tracking display you want to edit.",
        get = function() return NSRT.AuraTrackingSelected or "Player" end,
        values = GetAuraTrackingSelectionOptions,
        nocombat = true,
    }
    options[#options + 1] = { type = "label", get = function() return label end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") }
    options[#options + 1] = {
        type = "toggle",
        boxfirst = true,
        name = "Enabled",
        desc = "Whether this Aura Tracking display is enabled",
        get = function() return settings.enabled end,
        set = function(_, _, value)
            settings.enabled = value
            NSI:InitAuraTracking()
        end,
        icontexture = displayIconTexture,
        iconsize = {16, 16},
        nocombat = true,
    }
    options[#options + 1] = {
        type = "button",
        name = "Preview/Unlock",
        desc = "Preview this Aura Tracking display and move it around.",
        func = function()
            NSI[previewFlag] = not NSI[previewFlag]
            NSI:PreviewAuraTracking(settingsKey, NSI[previewFlag])
        end,
        nocombat = true,
        spacement = true,
    }
    options[#options + 1] = {
        type = "button",
        name = "Stop All Previews",
        desc = "Hide all active Aura Tracking previews.",
        func = function()
            NSI:StopAllAuraTrackingPreviews()
        end,
        nocombat = true,
        spacement = true,
    }
    options[#options + 1] = { type = "label", get = function() return "Custom Anchor Frame" end }
    options[#options + 1] = {
        type = "textentry",
        name = "",
        desc = "Name of the frame this Aura Tracking display should anchor to. Leave empty to anchor to the default NSRT frame. You can use /fstack to find frame names.",
        get = function() return settings.CustomAnchorFrame or "" end,
        set = function(_, _, value)
            if value ~= "" and not NSI:IsValidAuraTrackingAnchorFrame(value) then
                print("|cFF00FFFFNSRT:|r " .. NSI:Loc("Anchor frame not found."))
                return
            end
            settings.CustomAnchorFrame = value ~= "" and value or ""
            NSI:UpdateAuraTrackingDisplay(settingsKey)
        end,
        width = 200,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "select",
        name = "Grow Direction",
        desc = "Grow Direction",
        get = function() return settings.GrowDirection end,
        values = function() return build_growdirection_options(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Spacing",
        desc = "Spacing between Aura Tracking icons",
        get = function() return settings.Spacing end,
        set = function(_, _, value) settings.Spacing = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = -5, max = 20, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Width",
        desc = "Width of the Aura Tracking icons",
        get = function() return settings.Width end,
        set = function(_, _, value) settings.Width = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = 10, max = 500, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Height",
        desc = "Height of the Aura Tracking icons",
        get = function() return settings.Height end,
        set = function(_, _, value) settings.Height = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = 10, max = 500, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Zoom",
        desc = "Zooms the icon texture inwards",
        get = function() return settings.Zoom end,
        set = function(_, _, value) settings.Zoom = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = 0, max = 100, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "X-Offset",
        desc = "Horizontal offset of the Aura Tracking display",
        get = function() return settings.xOffset end,
        set = function(_, _, value) settings.xOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = -3000, max = 3000, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Y-Offset",
        desc = "Vertical offset of the Aura Tracking display",
        get = function() return settings.yOffset end,
        set = function(_, _, value) settings.yOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = -3000, max = 3000, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Max-Icons",
        desc = "Maximum number of auras to display",
        get = function() return settings.Limit end,
        set = function(_, _, value) settings.Limit = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = 1, max = 10, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "toggle",
        boxfirst = true,
        name = "Disable Tooltip",
        desc = "Hide tooltips on mouseover. The frame will be clickthrough regardless.",
        get = function() return settings.HideTooltip end,
        set = function(_, _, value) settings.HideTooltip = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "toggle",
        boxfirst = true,
        name = "Hide Border",
        desc = "Hide the 1 pixel black border around tracked aura icons.",
        get = function() return settings.HideBorder end,
        set = function(_, _, value) settings.HideBorder = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Border Size",
        desc = "Size of the black border around tracked aura icons.",
        get = function() return settings.BorderSize end,
        set = function(_, _, value) settings.BorderSize = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = 1, max = 10, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "toggle",
        boxfirst = true,
        name = "Hide Duration Text",
        desc = "Hide the duration text on tracked auras.",
        get = function() return settings.HideDurationText end,
        set = function(_, _, value) settings.HideDurationText = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "toggle",
        boxfirst = true,
        name = "Hide Stack Text",
        desc = "Hide the stack count text on tracked auras.",
        get = function() return settings.HideStackText end,
        set = function(_, _, value) settings.HideStackText = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "toggle",
        boxfirst = true,
        name = "Enable Cooldown Swipe",
        desc = "Shows a cooldown swipe on tracked aura icons.",
        get = function() return settings.EnableCooldownSwipe end,
        set = function(_, _, value) settings.EnableCooldownSwipe = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "toggle",
        boxfirst = true,
        name = "Inverse Cooldown Swipe",
        desc = "Reverses the cooldown swipe direction on tracked aura icons.",
        get = function() return settings.InverseCooldownSwipe end,
        set = function(_, _, value) settings.InverseCooldownSwipe = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        nocombat = true,
    }

    options[#options + 1] = { type = "breakline" }
    AddAuraTrackingTopControls(options, settingsKey)
    options[#options + 1] = { type = "label", get = function() return "Aura Tracking Text Settings" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") }
    options[#options + 1] = {
        type = "select",
        name = "Text Font",
        desc = "Font used for duration and stack text",
        get = function() return settings.TextFont end,
        values = function() return build_font_options(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "select",
        name = "Text Outline",
        desc = "Outline style used for duration and stack text",
        get = function() return settings.TextFontFlags end,
        values = function() return build_font_flag_options(settingsKey) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "color",
        name = "Duration Color",
        desc = "Color of the duration text",
        get = function() return unpack(settings.DurationColor) end,
        set = function(_, r, g, b, a) settings.DurationColor = {r, g, b, a}; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        hasAlpha = true,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "color",
        name = "Stack Color",
        desc = "Color of the stack text",
        get = function() return unpack(settings.StackColor) end,
        set = function(_, r, g, b, a) settings.StackColor = {r, g, b, a}; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        hasAlpha = true,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Duration Font Size",
        desc = "Font size of the duration text",
        get = function() return settings.DurationFontSize end,
        set = function(_, _, value) settings.DurationFontSize = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = 6, max = 80, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Stack Font Size",
        desc = "Font size of the stack text",
        get = function() return settings.StackFontSize end,
        set = function(_, _, value) settings.StackFontSize = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = 6, max = 80, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Duration X-Offset",
        desc = "Horizontal offset of the duration text",
        get = function() return settings.DurationXOffset end,
        set = function(_, _, value) settings.DurationXOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = -200, max = 200, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Duration Y-Offset",
        desc = "Vertical offset of the duration text",
        get = function() return settings.DurationYOffset end,
        set = function(_, _, value) settings.DurationYOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = -200, max = 200, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Stack X-Offset",
        desc = "Horizontal offset of the stack text",
        get = function() return settings.StackXOffset end,
        set = function(_, _, value) settings.StackXOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = -200, max = 200, step = 1, nocombat = true,
    }
    options[#options + 1] = {
        type = "range",
        name = "Stack Y-Offset",
        desc = "Vertical offset of the stack text",
        get = function() return settings.StackYOffset end,
        set = function(_, _, value) settings.StackYOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
        min = -200, max = 200, step = 1, nocombat = true,
    }

    if settingsKey == "Tank" then
        options[#options + 1] = { type = "label", get = function() return "Co-Tank Name Settings" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") }
        options[#options + 1] = {
            type = "toggle",
            boxfirst = true,
            name = "Show Co-Tank Name",
            desc = "Shows the co-tank name attached to visible aura icons.",
            get = function() return settings.NameEnabled end,
            set = function(_, _, value) settings.NameEnabled = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
            nocombat = true,
        }
        options[#options + 1] = {
            type = "select",
            name = "Name Position",
            desc = "Position of the co-tank name relative to the aura icon.",
            get = function() return settings.NamePosition end,
            values = function() return build_name_position_options(settingsKey) end,
            nocombat = true,
        }
        options[#options + 1] = {
            type = "range",
            name = "Name X-Offset",
            desc = "Horizontal offset of the co-tank name.",
            get = function() return settings.NameXOffset end,
            set = function(_, _, value) settings.NameXOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
            min = -200, max = 200, step = 1, nocombat = true,
        }
        options[#options + 1] = {
            type = "range",
            name = "Name Y-Offset",
            desc = "Vertical offset of the co-tank name.",
            get = function() return settings.NameYOffset end,
            set = function(_, _, value) settings.NameYOffset = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
            min = -200, max = 200, step = 1, nocombat = true,
        }
        options[#options + 1] = {
            type = "range",
            name = "Name Font Size",
            desc = "Font size of the co-tank name.",
            get = function() return settings.NameFontSize end,
            set = function(_, _, value) settings.NameFontSize = value; NSI:UpdateAuraTrackingDisplay(settingsKey) end,
            min = 6, max = 80, step = 1, nocombat = true,
        }
    end

    if isCustom then
        local customIndex = tostring(settingsKey):match("^Custom:(%d+)$") or "1"
        options[#options + 1] = { type = "label", get = function() return "Custom Tracking Settings" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") }
        options[#options + 1] = {
            type = "textentry",
            name = "Name",
            desc = "Name shown in the Aura Tracking selector.",
            get = function() return settings.Name or ("Custom Aura Tracking " .. customIndex) end,
            set = function(_, _, value)
                NSI:SetAuraTrackingCustomName(settingsKey, value)
            end,
            width = 220,
            nocombat = true,
        }
        options[#options + 1] = { type = "label", get = function() return "Tracked Spell IDs" end }
        options[#options + 1] = {
            type = "textentry",
            name = "",
            desc = "Comma or space separated list of helpful spell IDs to track on the player.",
            get = function() return NSI:GetAuraTrackingSpellIDString(settingsKey) end,
            set = function(_, _, value)
                NSI:SetAuraTrackingSpellIDString(settingsKey, value)
            end,
            width = 220,
            nocombat = true,
        }
        options[#options + 1] = {
            type = "textentry",
            name = "Preview Spell ID",
            desc = "Spell ID used for the custom Aura Tracking preview icon.",
            get = function() return settings.PreviewSpellID and tostring(settings.PreviewSpellID) or "" end,
            set = function(_, _, value)
                NSI:SetAuraTrackingPreviewSpellID(settingsKey, value)
            end,
            width = 120,
            nocombat = true,
        }
        options[#options + 1] = {
            type = "button",
            name = "Delete Custom Tracking",
            desc = "Delete this custom Aura Tracking display.",
            func = function()
                NSI:DeleteCustomAuraTracking(settingsKey)
            end,
            nocombat = true,
            spacement = true,
        }
    end
end

GetAuraTrackingSelectionOptions = function()
    local options = {
        {
            label = "Player Aura Tracking",
            value = "Player",
            onclick = function()
                NSRT.AuraTrackingSelected = "Player"
                RebuildAuraTrackingOptionsMenu()
            end,
        },
        {
            label = "Co-Tank Aura Tracking",
            value = "Tank",
            onclick = function()
                NSRT.AuraTrackingSelected = "Tank"
                RebuildAuraTrackingOptionsMenu()
            end,
        },
        {
            label = "External Buff Aura Tracking",
            value = "External",
            onclick = function()
                NSRT.AuraTrackingSelected = "External"
                RebuildAuraTrackingOptionsMenu()
            end,
        },
    }

    for index in ipairs(NSRT.AuraTrackingSettings.Custom or {}) do
        local settingsKey = "Custom:" .. index
        local settings = NSI:GetAuraTrackingSettings(settingsKey)
        local label = (settings and settings.Name) or ("Custom Aura Tracking " .. index)
        options[#options + 1] = {
            label = label,
            value = settingsKey,
            onclick = function()
                NSRT.AuraTrackingSelected = settingsKey
                RebuildAuraTrackingOptionsMenu()
            end,
        }
    end

    return options
end

local function GetAuraTrackingCopySourceOptions(selected)
    local options = {}
    for _, entry in ipairs(GetAuraTrackingSelectionOptions()) do
        if entry.value ~= selected then
            options[#options + 1] = {
                label = entry.label,
                value = entry.value,
                onclick = function()
                    NSRT.AuraTrackingStyleCopySource = entry.value
                end,
            }
        end
    end
    return options
end

AddAuraTrackingTopControls = function(options, selected)
    options[#options + 1] = {
        type = "button",
        name = "Add Custom Tracking",
        desc = "Create a custom Aura Tracking display with its own helpful spell ID filter.",
        func = function()
            NSI:AddCustomAuraTracking()
        end,
        nocombat = true,
        spacement = true,
    }
    if NSRT.AuraTrackingStyleCopySource == selected or not NSI:GetAuraTrackingSettings(NSRT.AuraTrackingStyleCopySource) then
        NSRT.AuraTrackingStyleCopySource = selected == "Player" and "Tank" or "Player"
    end
    options[#options + 1] = {
        type = "select",
        name = "Copy Style From",
        desc = "Select another Aura Tracking display to copy visual settings from.",
        get = function() return NSRT.AuraTrackingStyleCopySource end,
        values = function() return GetAuraTrackingCopySourceOptions(selected) end,
        nocombat = true,
    }
    options[#options + 1] = {
        type = "button",
        name = "Copy Style",
        desc = "Copies visual settings from the selected Aura Tracking display. This does not copy name, enabled state, spell IDs, or preview spell ID.",
        func = function()
            NSI:CopyAuraTrackingStyle(NSRT.AuraTrackingStyleCopySource, selected)
        end,
        nocombat = true,
        spacement = true,
    }
end

local function BuildAuraTrackingOptions()
    local options = {}
    local selected = NSRT.AuraTrackingSelected or "Player"
    if not NSI:GetAuraTrackingSettings(selected) then
        selected = "Player"
        NSRT.AuraTrackingSelected = selected
    end

    if selected == "Player" then
        AddAuraTrackingSection(options, selected, "Player Aura Tracking", "IsAuraTrackingPlayerPreview", 237555)
    elseif selected == "Tank" then
        AddAuraTrackingSection(options, selected, "Co-Tank Aura Tracking", "IsAuraTrackingTankPreview", 236318)
    elseif selected == "External" then
        AddAuraTrackingSection(options, selected, "External Buff Aura Tracking", "IsAuraTrackingExternalPreview", C_Spell.GetSpellTexture(6940) or 135966)
    else
        local customIndex = tostring(selected):match("^Custom:(%d+)$") or "1"
        local settings = NSI:GetAuraTrackingSettings(selected)
        AddAuraTrackingSection(options, selected, (settings and settings.Name) or ("Custom Aura Tracking " .. customIndex), "IsAuraTrackingCustom" .. customIndex .. "Preview", 136076)
    end
    return options
end

local function BuildAuraTrackingCallback()
    return function() end
end

NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.AuraTracking = {
    BuildOptions = BuildAuraTrackingOptions,
    BuildCallback = BuildAuraTrackingCallback,
}
