-- ============================================================
--  The main options window (NSUI), built from UI/Window.lua.
--
--  Created at load time because the tab screens grab it through
--  NSI.UI.Core.NSUI while their own files load. Tabs, sidebar, header
--  buttons and the scale slider are added by NSUI.lua (NSUI:Init).
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local Core = NSI.UI.Core

local MEDIA = [[Interface\AddOns\NorthernSkyRaidTools\Media\]]

-- The user's accent colour is applied before any frame is built, so everything drawn from
-- here on already uses it (see Options/General.lua for the picker).
do
    local saved = NSRT and NSRT.Settings and NSRT.Settings.AccentColor
    if type(saved) == "table" and tonumber(saved[1]) and tonumber(saved[2]) and tonumber(saved[3]) then
        NSI.UI.Style.SetAccent(saved[1], saved[2], saved[3])
    end
end

local NSUI = NSI.UI.Window.Create({
    name         = "NSUI",
    width        = Core.window_width,
    minWidth     = Core.window_width,   -- never smaller than the original fixed size
    minHeight    = Core.window_height,
    height       = Core.window_height,
    headerHeight = Core.header_height,
    footerHeight = Core.footer_height,
    strata       = "HIGH",
    title        = NSI.UI.Style.AccentCode() .. "Northern Sky|r Raid Tools",
    titleIcons   = {
        left  = { texture = MEDIA .. "NSLogo", size = 20 },
        right = { texture = MEDIA .. [[Icons\VelocityLogo.png]], size = 16 },
    },
    discordUrl   = "https://discord.gg/3B6QHURmBy",
    -- Pixel-space scale x the user's own window scale (NSUI:SetScale drives the user part).
    userScale    = function()
        return NSRT and NSRT.NSUI and tonumber(NSRT.NSUI.scale) or 1
    end,
})
NSUI:Hide()

NSUI.OptionsChanged = {
    ["general"] = {},
    ["nicknames"] = {},
    ["versions"] = {},
}

Core.NSUI = NSUI
NSI.NSUI = NSUI
if NSI.UIBootstrap then
    NSI.UIBootstrap.NSUI = NSUI
end
