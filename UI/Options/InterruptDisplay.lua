local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = LibStub("AceLocale-3.0"):GetLocale("NorthernSkyRaidTools")

local anchors   = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local fontflags = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "OUTLINE, MONOCHROME", "THICKOUTLINE, MONOCHROME" }

local function refreshPreview()
    if not (NSI.InterruptDisplay and NSI.InterruptDisplay:IsShown()) then return end
    NSI:CreateInterruptDisplay()
end

local function buildAnchorOptions(key)
    local t = {}
    for _, v in ipairs(anchors) do
        tinsert(t, {
            label = v,
            value = v,
            onclick = function()
                NSRT.InterruptSettings[key] = v
                refreshPreview()
            end,
        })
    end
    return t
end

local function buildFontFlagOptions(key)
    local t = {}
    for _, v in ipairs(fontflags) do
        tinsert(t, {
            label = v == "" and L["None"] or v,
            value = v,
            onclick = function()
                NSRT.InterruptSettings[key] = v
                refreshPreview()
            end,
        })
    end
    return t
end

local function buildFontOptions(key)
    local t = {}
    for _, name in ipairs(NSI.LSM:List("font")) do
        tinsert(t, {
            label = name,
            value = name,
            onclick = function()
                NSRT.InterruptSettings[key] = name
                refreshPreview()
            end,
        })
    end
    return t
end

local function buildSoundOptions()
    local t = {}
    for _, name in ipairs(NSI.LSM:List("sound")) do
        tinsert(t, {
            label = name,
            value = name,
            onclick = function()
                NSRT.InterruptSettings.InterruptSound = name
                PlaySoundFile(NSI.LSM:Fetch("sound", name), "Master")
            end,
        })
    end
    return t
end

local function BuildInterruptDisplayOptions()
    return {
        { type = "label", get = function() return L["Size & Position"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "button",
            name = L["Preview / Move"],
            desc = L["Toggle a live preview of the Interrupt Display. While shown, drag it to reposition."],
            func = function()
                if NSI.InterruptDisplay and NSI.InterruptDisplay:IsShown() then
                    NSI:MakeDraggable(NSI.InterruptDisplay, NSRT.InterruptSettings, false)
                    NSI:HideInterrupt()
                else
                    NSI:CreateInterruptDisplay()
                    NSI.InterruptDisplay.Number:SetText("3")
                    NSI.InterruptDisplay.Name:SetText(NSAPI:Shorten("player", 8, false, "GlobalNickNames", false, false))
                    NSI.InterruptDisplay.Box:SetColorTexture(0, 1, 0, 1)
                    NSI:MakeDraggable(NSI.InterruptDisplay, NSRT.InterruptSettings, true)
                end
            end,
            nocombat = true,
            spacement = true,
        },

        {
            type = "range",
            name = L["Width"],
            desc = L["Width of the interrupt display box"],
            get = function() return NSRT.InterruptSettings.Width end,
            set = function(_, _, value) NSRT.InterruptSettings.Width = value; refreshPreview() end,
            min = 20, max = 400, step = 1,
        },
        {
            type = "range",
            name = L["Height"],
            desc = L["Height of the interrupt display box"],
            get = function() return NSRT.InterruptSettings.Height end,
            set = function(_, _, value) NSRT.InterruptSettings.Height = value; refreshPreview() end,
            min = 20, max = 400, step = 1,
        },
        {
            type = "range",
            name = L["X Offset"],
            desc = L["Horizontal offset from anchor"],
            get = function() return NSRT.InterruptSettings.xOffset end,
            set = function(_, _, value) NSRT.InterruptSettings.xOffset = value; refreshPreview() end,
            min = -2000, max = 2000, step = 1,
        },
        {
            type = "range",
            name = L["Y Offset"],
            desc = L["Vertical offset from anchor"],
            get = function() return NSRT.InterruptSettings.yOffset end,
            set = function(_, _, value) NSRT.InterruptSettings.yOffset = value; refreshPreview() end,
            min = -1200, max = 1200, step = 1,
        },
        {
            type = "select",
            name = L["Anchor Point"],
            desc = L["Which corner/edge of the display to anchor from"],
            get = function() return NSRT.InterruptSettings.Anchor end,
            set = function() end,
            values = function() return buildAnchorOptions("Anchor") end,
        },
        {
            type = "select",
            name = L["Relative Point"],
            desc = L["Which corner/edge of the parent frame to anchor to"],
            get = function() return NSRT.InterruptSettings.relativeTo end,
            set = function() end,
            values = function() return buildAnchorOptions("relativeTo") end,
        },
        {
            type = "select",
            name = L["Interrupt Sound"],
            desc = L["Sound played when it is your turn to interrupt"],
            get = function() return NSRT.InterruptSettings.InterruptSound end,
            set = function() end,
            values = function() return buildSoundOptions() end,
        },

        { type = "breakline" },
        { type = "label", get = function() return L["Number Settings"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type = "select",
            name = L["Number Font"],
            get = function() return NSRT.InterruptSettings.NumberFont end,
            set = function() end,
            values = function() return buildFontOptions("NumberFont") end,
        },
        {
            type = "select",
            name = L["Number Font Flags"],
            desc = L["Outline style for the number"],
            get = function() return NSRT.InterruptSettings.NumberFontFlags end,
            set = function() end,
            values = function() return buildFontFlagOptions("NumberFontFlags") end,
        },
        {
            type = "range",
            name = L["Number Font Size"],
            desc = L["Size of the interrupt count number"],
            get = function() return NSRT.InterruptSettings.NumberFontSize end,
            set = function(_, _, value) NSRT.InterruptSettings.NumberFontSize = value; refreshPreview() end,
            min = 8, max = 120, step = 1,
        },
        {
            type = "range",
            name = L["Number X Offset"],
            get = function() return NSRT.InterruptSettings.NumberxOffset end,
            set = function(_, _, value) NSRT.InterruptSettings.NumberxOffset = value; refreshPreview() end,
            min = -200, max = 200, step = 1,
        },
        {
            type = "range",
            name = L["Number Y Offset"],
            get = function() return NSRT.InterruptSettings.NumberyOffset end,
            set = function(_, _, value) NSRT.InterruptSettings.NumberyOffset = value; refreshPreview() end,
            min = -200, max = 200, step = 1,
        },
        {
            type = "select",
            name = L["Number Anchor Point"],
            desc = L["Which corner/edge of the box the number anchors from"],
            get = function() return NSRT.InterruptSettings.NumberAnchor end,
            set = function() end,
            values = function() return buildAnchorOptions("NumberAnchor") end,
        },
        {
            type = "select",
            name = L["Number Relative Point"],
            desc = L["Which corner/edge of the box the number anchors to"],
            get = function() return NSRT.InterruptSettings.NumberRelativeTo end,
            set = function() end,
            values = function() return buildAnchorOptions("NumberRelativeTo") end,
        },

        { type = "breakline" },
        { type = "label", get = function() return L["Name Settings"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type = "select",
            name = L["Name Font"],
            get = function() return NSRT.InterruptSettings.NameFont end,
            set = function() end,
            values = function() return buildFontOptions("NameFont") end,
        },
        {
            type = "select",
            name = L["Name Font Flags"],
            desc = L["Outline style for the name"],
            get = function() return NSRT.InterruptSettings.NameFontFlags end,
            set = function() end,
            values = function() return buildFontFlagOptions("NameFontFlags") end,
        },
        {
            type = "range",
            name = L["Name Font Size"],
            desc = L["Size of the player name text"],
            get = function() return NSRT.InterruptSettings.NameFontSize end,
            set = function(_, _, value) NSRT.InterruptSettings.NameFontSize = value; refreshPreview() end,
            min = 8, max = 120, step = 1,
        },
        {
            type = "range",
            name = L["Name X Offset"],
            get = function() return NSRT.InterruptSettings.NamexOffset end,
            set = function(_, _, value) NSRT.InterruptSettings.NamexOffset = value; refreshPreview() end,
            min = -200, max = 200, step = 1,
        },
        {
            type = "range",
            name = L["Name Y Offset"],
            get = function() return NSRT.InterruptSettings.NameyOffset end,
            set = function(_, _, value) NSRT.InterruptSettings.NameyOffset = value; refreshPreview() end,
            min = -200, max = 200, step = 1,
        },
        {
            type = "select",
            name = L["Name Anchor Point"],
            desc = L["Which corner/edge of the box the name anchors from"],
            get = function() return NSRT.InterruptSettings.NameAnchor end,
            set = function() end,
            values = function() return buildAnchorOptions("NameAnchor") end,
        },
        {
            type = "select",
            name = L["Name Relative Point"],
            desc = L["Which corner/edge of the box the name anchors to"],
            get = function() return NSRT.InterruptSettings.NameRelativeTo end,
            set = function() end,
            values = function() return buildAnchorOptions("NameRelativeTo") end,
        },
    }
end

local function BuildInterruptDisplayCallback()
    return function() end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.InterruptDisplay = {
    BuildOptions  = BuildInterruptDisplayOptions,
    BuildCallback = BuildInterruptDisplayCallback,
}
