local _, NSI = ...
local DF = _G["DetailsFramework"]
local function build_raidframeicon_options(Anchor)
    local list = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                if Anchor then
                    NSRT.Settings.LuraAnchor = list[value]
                else
                    NSRT.Settings.LuraRelativePoint = list[value]
                end
            end
        })
    end
    return t
end

local function BuildEncounterAlertsOptions()
    return {
        {
            type = "label",
            get = function() return "Enabling these adds some generic premade Reminders to some of the bosses. Think of these like the text-reminders for an upcoming ability from previous WA packs.\nIn some rare cases special stuff might be included in here. A recent example that would've fallen under this would've been the line on Nexus King to look at ghosts." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true
        },
        {
            type = "label",
            get = function() return "Imperator Averzian" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Imperator Averzian.",
            get = function() return NSRT.EncounterAlerts[3176] and NSRT.EncounterAlerts[3176].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3176] = NSRT.EncounterAlerts[3176] or {}
                NSRT.EncounterAlerts[3176].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3176)
            end,
            nocombat = true,
            icontexture = 7448209,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Vorasius" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Vorasius.",
            get = function() return NSRT.EncounterAlerts[3177] and NSRT.EncounterAlerts[3177].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3177] = NSRT.EncounterAlerts[3177] or {}
                NSRT.EncounterAlerts[3177].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3177)
            end,
            nocombat = true,
            icontexture = 7448210,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Fallen King Salhadaar" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Fallen King Salhadaar.",
            get = function() return NSRT.EncounterAlerts[3179] and NSRT.EncounterAlerts[3179].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3179] = NSRT.EncounterAlerts[3179] or {}
                NSRT.EncounterAlerts[3179].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3179)
            end,
            nocombat = true,
            icontexture = 7448212,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "CC Adds Display",
            desc = "This specifally only toggles the CC Display above the nameplate of the adds on&off so you can choose to only one of them.",
            get = function() return NSRT.EncounterAlerts[3179] and NSRT.EncounterAlerts[3179].CCAddsDisplay end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3179] = NSRT.EncounterAlerts[3179] or {}
                NSRT.EncounterAlerts[3179].CCAddsDisplay = value
            end,
            nocombat = true,
            icontexture = 7448212,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Vaelgor & Ezzorak" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Vaelgor & Ezzorak.",
            get = function() return NSRT.EncounterAlerts[3178] and NSRT.EncounterAlerts[3178].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3178] = NSRT.EncounterAlerts[3178] or {}
                NSRT.EncounterAlerts[3178].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3178)
            end,
            nocombat = true,
            icontexture = 7448207,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Health Display",
            desc = "Enables Health Display for Vaelgor & Ezzorak to show their health next to each other. This is the text display from the General-Tab.",
            get = function() return NSRT.EncounterAlerts[3178] and NSRT.EncounterAlerts[3178].HealthDisplay end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3178] = NSRT.EncounterAlerts[3178] or {}
                NSRT.EncounterAlerts[3178].HealthDisplay = value
            end,
            nocombat = true,
            icontexture = 7448207,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Lightblinded Vanguard" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Lightblinded Vanguard.",
            get = function() return NSRT.EncounterAlerts[3180] and NSRT.EncounterAlerts[3180].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3180] = NSRT.EncounterAlerts[3180] or {}
                NSRT.EncounterAlerts[3180].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3180)
            end,
            nocombat = true,
            icontexture = 7448211,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Nameplate Taunt Alerts",
            desc = "This will display a Taunt under the nameplate of the Boss you should be taunting during the Judgment cast. The text will go away after you press taunt or after 3 seconds. It is possible that there could be some false positives triggering from the caster boss. It requires having the nameplate visible on screen at the moment of the cast start.",
            get = function() return NSRT.EncounterAlerts[3180] and NSRT.EncounterAlerts[3180].TauntAlerts end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3180] = NSRT.EncounterAlerts[3180] or {}
                NSRT.EncounterAlerts[3180].TauntAlerts = value
            end,
            nocombat = true,
            icontexture = 7448211,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Heal Absorb Ticks",
            desc = "This will display a Heal Absorb Tick-Bar to properly track when a new healabsorb is being applied.",
            get = function() return NSRT.EncounterAlerts[3180] and NSRT.EncounterAlerts[3180].HealAbsorbTicks end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3180] = NSRT.EncounterAlerts[3180] or {}
                NSRT.EncounterAlerts[3180].HealAbsorbTicks = value
            end,
            nocombat = true,
            icontexture = 5764904,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Crown of the Cosmos" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Crown of the Cosmos.",
            get = function() return NSRT.EncounterAlerts[3181] and NSRT.EncounterAlerts[3181].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3181] = NSRT.EncounterAlerts[3181] or {}
                NSRT.EncounterAlerts[3181].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3181)
            end,
            nocombat = true,
            icontexture = 7448205,
            iconsize = {16, 16},
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Chimaerus" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Chimaerus.",
            get = function() return NSRT.EncounterAlerts[3306] and NSRT.EncounterAlerts[3306].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3306] = NSRT.EncounterAlerts[3306] or {}
                NSRT.EncounterAlerts[3306].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3306)
            end,
            nocombat = true,
            icontexture = 7448202,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Belo'ren" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Beloren.",
            get = function() return NSRT.EncounterAlerts[3182] and NSRT.EncounterAlerts[3182].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3182] = NSRT.EncounterAlerts[3182] or {}
                NSRT.EncounterAlerts[3182].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3182)
            end,
            nocombat = true,
            icontexture = 7448203,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return "Midnight Falls" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Generic Alerts",
            desc = "Enables Alerts for Midnight Falls.",
            get = function() return NSRT.EncounterAlerts[3183] and NSRT.EncounterAlerts[3183].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183].enabled = value
                NSI:FireCallback("NSRT_ALERT_TOGGLE", 3183)
            end,
            nocombat = true,
            icontexture = 7448204,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Runes Display",
            desc = "Enables the Map-Display for where each rune should be going. This requires other people to input the correct numbers into chat either via a macro or the click-option below. It also requires no one else to type anything else in raidchat during the encounter.",
            get = function() return NSRT.EncounterAlerts[3183] and NSRT.EncounterAlerts[3183].RunesDisplay end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183].RunesDisplay = value
            end,
            nocombat = true,
            icontexture = 7448204,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Clickable Runes",
            desc = "Enables Clickable Runes for Midnight Falls. To receive this information players will need to get the WeakAura from the WA-tab",
            get = function() return NSRT.EncounterAlerts[3183] and NSRT.EncounterAlerts[3183].ClickableRunes end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183].ClickableRunes = value
            end,
            nocombat = true,
            icontexture = 7448204,
            iconsize = {16, 16},
        },
        {
            type = "select",
            name = "Anchor of Clickable Runes",
            desc = "Defines the Anchor of the Clickable Runes. They will grow right from there.",
            get = function() return NSRT.Settings.LuraAnchor or "LEFT" end,
            values = function() return build_raidframeicon_options() end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Relative Point of Clickable Runes",
            desc = "Defines the Relative Point of the Clickable Runes. They will grow right from there.",
            get = function() return NSRT.Settings.LuraRelativePoint or "LEFT" end,
            values = function() return build_raidframeicon_options() end,
            nocombat = true,
        },
        {
            type = "range",
            name = "X-Offset of Clickable Runes",
            desc = "X-Offset of the Clickable Runes",
            get = function() return NSRT.Settings.LuraOffsetX or 300 end,
            set = function(self, fixedparam, value)
                NSRT.Settings.LuraOffsetX = value
            end,
            min = -2000,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Y-Offset of Clickable Runes",
            desc = "Y-Offset of the Clickable Runes",
            get = function() return NSRT.Settings.LuraOffsetY or 0 end,
            set = function(self, fixedparam, value)
                NSRT.Settings.LuraOffsetY = value
            end,
            min = -2000,
            max = 2000,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range",
            name = "Encounter Text Font-Size",
            desc = "Some encounters might display static text(for example on the dragons boss). In that case the position of the text in the General-Tab is used but you can individually change the font-size here.",
            get = function() return NSRT.Settings["GlobalEncounterFontSize"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["GlobalEncounterFontSize"] = value
                NSI.NSRTFrame.SecretDisplay.Text:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings.GlobalEncounterFontSize, "OUTLINE")
            end,
            min = 1,
            max = 100,
        },
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
