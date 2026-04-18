local _, NSI = ...
local DF = _G["DetailsFramework"]

-- Get references from Core module
local Core = NSI.UI.Core
local NSUI = Core.NSUI
local window_width                 = Core.window_width
local window_height                = Core.window_height
local content_width                = Core.content_width
local content_height               = Core.content_height
local TAB_HEADER_HEIGHT            = Core.TAB_HEADER_HEIGHT
local tab_content_height           = Core.tab_content_height
local authorsString                = Core.authorsString
local options_text_template        = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template      = Core.options_switch_template
local options_slider_template      = Core.options_slider_template
local options_button_template      = Core.options_button_template

-- Get UI builder functions from modules
local BuildVersionCheckUI          = NSI.UI.VersionCheck.BuildVersionCheckUI
local BuildNicknameEditUI          = NSI.UI.Nicknames.BuildNicknameEditUI
local BuildRemindersEditUI         = NSI.UI.Reminders.BuildRemindersEditUI
local BuildPersonalRemindersEditUI = NSI.UI.Reminders.BuildPersonalRemindersEditUI
local BuildCooldownsEditUI         = NSI.UI.Cooldowns.BuildCooldownsEditUI
local BuildPASoundEditUI           = NSI.UI.PrivateAuras.BuildPASoundEditUI
local BuildExportStringUI          = NSI.UI.General.BuildExportStringUI
local BuildImportStringUI          = NSI.UI.General.BuildImportStringUI

-- Get options builders from modules
local BuildGeneralOptions          = NSI.UI.Options.General.BuildOptions
local BuildGeneralCallback         = NSI.UI.Options.General.BuildCallback
local BuildNicknamesOptions        = NSI.UI.Options.Nicknames.BuildOptions
local BuildNicknamesCallback       = NSI.UI.Options.Nicknames.BuildCallback
local BuildReminderOptions         = NSI.UI.Options.Reminders.BuildOptions
local BuildReminderNoteOptions     = NSI.UI.Options.Reminders.BuildNoteOptions
local BuildReminderCallback        = NSI.UI.Options.Reminders.BuildCallback
local BuildReminderNoteCallback    = NSI.UI.Options.Reminders.BuildNoteCallback
local BuildAssignmentsOptions      = NSI.UI.Options.Assignments.BuildOptions
local BuildAssignmentsCallback     = NSI.UI.Options.Assignments.BuildCallback
local BuildEncounterAlertsOptions = NSI.UI.Options.EncounterAlerts.BuildOptions
local BuildEncounterAlertsCallback = NSI.UI.Options.EncounterAlerts.BuildCallback
local BuildReadyCheckOptions       = NSI.UI.Options.ReadyCheck.BuildOptions
local BuildRaidBuffMenu            = NSI.UI.Options.ReadyCheck.BuildRaidBuffMenu
local BuildReadyCheckCallback      = NSI.UI.Options.ReadyCheck.BuildCallback
local BuildPrivateAurasOptions     = NSI.UI.Options.PrivateAuras.BuildOptions
local BuildPrivateAurasCallback    = NSI.UI.Options.PrivateAuras.BuildCallback
local BuildQoLOptions              = NSI.UI.Options.QoL.BuildOptions
local BuildQoLCallback             = NSI.UI.Options.QoL.BuildCallback
local BuildWAImportsOptions        = NSI.UI.Options.WAImports.BuildOptions
local BuildWACallback              = NSI.UI.Options.WAImports.BuildCallback
-- ============================================================
-- Vertical tab sidebar layout
-- ============================================================

-- Tab groups – blank strings become visual spacers between groups
local TABS_GROUPS                  = {
    {
        { name = "General",  text = "General" },
        { name = "Versions", text = "Version Check" },
        { name = "QoL",      text = "Quality of Life" },
    },
    {
        { name = "Nicknames",    text = "Nicknames" },
        { name = "ReadyCheck",   text = "Ready Check" },
    },
    {
        { name = "Reminders",       text = "Reminders" },
        { name = "Reminders-Note",  text = "Reminder Strings" },
        { name = "Assignments",     text = "Assignments" },
        { name = "EncounterAlerts", text = "Encounter Alerts" },
    },
    {
        { name = "PrivateAura", text = "Private Auras" },
        { name = "WAImports",   text = "WA Imports" },
    },
}

-- Sidebar visual constants
local SIDEBAR_BTN_WIDTH            = 148
local SIDEBAR_BTN_HEIGHT           = 22
local SIDEBAR_BTN_GAP              = 0  -- px between consecutive buttons
local SIDEBAR_GROUP_GAP            = 14 -- extra px between groups

-- Derived from Core: tab frames start below the shared header strip
local tab_content_y                = -25 - TAB_HEADER_HEIGHT  -- -80

local CreateButton                 = NSI.UI.Components.CreateButton

function NSUI:Init()
    NSI.IsBuilding = true
    -- Scale bar
    DF:CreateScaleBar(NSUI, NSRT.NSUI)
    local scale = math.max(NSRT.NSUI.scale, 0.6)
    NSUI:SetScale(scale)

    -- Forward declaration – buttons below need to call SelectTab before it is defined
    local SelectTab
    -- --------------------------------------------------------
    -- Build the tab system object
    -- (mimics the df_tabcontainer interface for backward compat)
    -- --------------------------------------------------------
    local tabSystem = {
        AllFrames        = {},
        AllButtons       = {},
        AllFramesByName  = {},
        AllButtonsByName = {},
        CurrentName      = nil,
    }

    function tabSystem:GetTabFrameByName(name)
        return self.AllFramesByName[name]
    end

    function tabSystem:SelectTabByName(name)
        SelectTab(name)
    end

    -- --------------------------------------------------------
    -- Sidebar background
    -- --------------------------------------------------------
    local sidebarBg = CreateFrame("frame", "NSUISidebar", NSUI, "BackdropTemplate")
    sidebarBg:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 2, -25)
    sidebarBg:SetSize(158, content_height)
    sidebarBg:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    sidebarBg:SetBackdropColor(0, 0, 0, 0.18)

    -- Thin cyan vertical separator between sidebar and content area
    local sidebarSep = NSUI:CreateTexture(nil, "artwork")
    sidebarSep:SetColorTexture(0, 1, 1, 0.25)
    sidebarSep:SetWidth(1)
    sidebarSep:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 160, -25)
    sidebarSep:SetPoint("BOTTOMLEFT", NSUI, "BOTTOMLEFT", 160, 22)

    -- --------------------------------------------------------
    -- Create one content frame + one sidebar button per tab
    -- --------------------------------------------------------
    local btnY = -5 -- running y cursor inside sidebarBg

    for gIdx, group in ipairs(TABS_GROUPS) do
        -- Draw a subtle horizontal rule between groups
        if gIdx > 1 then
            local rule = sidebarBg:CreateTexture(nil, "artwork")
            rule:SetColorTexture(0, 1, 1, 0.12)
            rule:SetHeight(1)
            rule:SetPoint("TOPLEFT", sidebarBg, "TOPLEFT", 8, btnY + math.floor(SIDEBAR_GROUP_GAP / 2))
            rule:SetPoint("TOPRIGHT", sidebarBg, "TOPRIGHT", -8, btnY + math.floor(SIDEBAR_GROUP_GAP / 2))
        end

        for _, tab in ipairs(group) do
            -- Content frame – occupies the right portion below the shared header, hidden by default
            local contentFrame = CreateFrame("frame", "NSUI_TabFrame_" .. tab.name, NSUI, "BackdropTemplate")
            contentFrame:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 162, tab_content_y)
            contentFrame:SetSize(content_width, tab_content_height)
            contentFrame:Hide()
            contentFrame:EnableMouse(false)

            -- Register by both name and display text for maximum compat
            tabSystem.AllFramesByName[tab.name] = contentFrame
            tabSystem.AllFramesByName[tab.text] = contentFrame
            table.insert(tabSystem.AllFrames, contentFrame)

            -- Sidebar button
            local btn = CreateButton(
                sidebarBg,
                tab.text,
                function() SelectTab(tab.name) end,
                SIDEBAR_BTN_WIDTH, SIDEBAR_BTN_HEIGHT,
                "NSUITabBtn_" .. tab.name
            )
            btn:SetPoint("TOPLEFT", sidebarBg, "TOPLEFT", 5, btnY)

            tabSystem.AllButtonsByName[tab.name] = btn
            tabSystem.AllButtonsByName[tab.text] = btn
            table.insert(tabSystem.AllButtons, btn)

            btnY = btnY - SIDEBAR_BTN_HEIGHT - SIDEBAR_BTN_GAP
        end

        -- Extra gap between groups (but not after the last group)
        if gIdx < #TABS_GROUPS then
            btnY = btnY - SIDEBAR_GROUP_GAP
        end
    end

    -- --------------------------------------------------------
    -- Notes tabs – content frames registered in tabSystem but
    -- opened exclusively via the persistent header buttons below,
    -- so no sidebar button is created for them.
    -- --------------------------------------------------------
    local NOTES_HEADER_BTN_W = 190
    local NOTES_HEADER_BTN_H = 26
    -- Vertically centred in the 55 px header strip (NSUI y=-25 to y=-80)
    local NOTES_HEADER_BTN_Y = -38

    local notesTabs = {
        { name = "SharedNotes",   text = "Shared Notes",   icon = "users_icon" },
        { name = "PersonalNotes", text = "Personal Notes", icon = "user_icon" },
    }

    for i, nt in ipairs(notesTabs) do
        -- Content frame (same geometry as every other tab)
        local notesFrame = CreateFrame("frame", "NSUI_TabFrame_" .. nt.name, NSUI, "BackdropTemplate")
        notesFrame:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 162, tab_content_y)
        notesFrame:SetSize(content_width, tab_content_height)
        notesFrame:Hide()
        notesFrame:EnableMouse(false)

        tabSystem.AllFramesByName[nt.name] = notesFrame
        tabSystem.AllFramesByName[nt.text] = notesFrame
        table.insert(tabSystem.AllFrames, notesFrame)

        -- Persistent header button (lives on NSUI, always visible)
        local hdrBtn = CreateButton(
            NSUI,
            nt.text,
            function() SelectTab(nt.name) end,
            NOTES_HEADER_BTN_W, NOTES_HEADER_BTN_H,
            "NSUIHeaderBtn_" .. nt.name,
            nt.icon
        )
        hdrBtn:SetPoint(
            "TOPLEFT", NSUI, "TOPLEFT",
            162 + 10 + (i - 1) * (NOTES_HEADER_BTN_W + 6),
            NOTES_HEADER_BTN_Y
        )

        tabSystem.AllButtonsByName[nt.name] = hdrBtn
        tabSystem.AllButtonsByName[nt.text] = hdrBtn
        table.insert(tabSystem.AllButtons, hdrBtn)
    end
    -- --------------------------------------------------------
    -- Tab selection logic (matches Details' SelectOptionsSection)
    -- --------------------------------------------------------
    SelectTab = function(name)
        -- Deselect all
        for _, f in ipairs(tabSystem.AllFrames) do
            f:Hide()
        end
        for _, b in ipairs(tabSystem.AllButtons) do
            b:Deselect()
        end

        -- Activate target
        local frame = tabSystem.AllFramesByName[name]
        if frame then
            frame:Show()
            if frame.RefreshOptions then
                frame:RefreshOptions()
            end
        end

        local btn = tabSystem.AllButtonsByName[name]
        if btn then
            btn:Select()
        end

        tabSystem.CurrentName = name
    end

    -- Re-activate the remembered tab when the panel is reshown
    NSUI:HookScript("OnShow", function()
        if tabSystem.CurrentName then
            SelectTab(tabSystem.CurrentName)
        end
    end)

    NSUI.MenuFrame                = tabSystem

    -- --------------------------------------------------------
    -- Convenience locals for the tab frames
    -- --------------------------------------------------------
    local general_tab             = tabSystem:GetTabFrameByName("General")
    local nicknames_tab           = tabSystem:GetTabFrameByName("Nicknames")
    local versions_tab            = tabSystem:GetTabFrameByName("Versions")
    local reminder_tab            = tabSystem:GetTabFrameByName("Reminders")
    local reminder_note_tab       = tabSystem:GetTabFrameByName("Reminders-Note")
    local assignments_tab         = tabSystem:GetTabFrameByName("Assignments")
    local encounteralerts_tab     = tabSystem:GetTabFrameByName("EncounterAlerts")
    local readycheck_tab          = tabSystem:GetTabFrameByName("ReadyCheck")
    local privateaura_tab         = tabSystem:GetTabFrameByName("PrivateAura")
    local QoL_tab                 = tabSystem:GetTabFrameByName("QoL")
    local WAImports_tab           = tabSystem:GetTabFrameByName("WAImports")

    -- --------------------------------------------------------
    -- Generic text display frames (unchanged)
    -- --------------------------------------------------------
    NSI.NSRTFrame.generic_display = CreateFrame("Frame", nil, NSI.NSRTFrame, "BackdropTemplate")
    NSI.NSRTFrame.generic_display:Hide()
    NSI.NSRTFrame.generic_display:SetPoint(NSRT.Settings.GenericDisplay.Anchor, NSI.NSRTFrame, NSRT.Settings.GenericDisplay.relativeTo, NSRT.Settings.GenericDisplay.xOffset, NSRT.Settings.GenericDisplay.yOffset)
    NSI.NSRTFrame.generic_display.Text = NSI.NSRTFrame.generic_display:CreateFontString(nil, "OVERLAY")
    NSI.NSRTFrame.generic_display.Text:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings.GlobalFontSize, "OUTLINE")
    NSI.NSRTFrame.generic_display.Text:SetPoint("TOPLEFT", NSI.NSRTFrame.generic_display, "TOPLEFT", 0, 0)
    NSI.NSRTFrame.generic_display.Text:SetJustifyH("LEFT")
    NSI.NSRTFrame.generic_display.Text:SetText("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
    NSI.NSRTFrame.generic_display:SetSize(NSI.NSRTFrame.generic_display.Text:GetStringWidth(), NSI.NSRTFrame.generic_display.Text:GetStringHeight())
    NSI:MoveFrameInit(NSI.NSRTFrame.generic_display, "Generic")

    NSI.NSRTFrame.SecretDisplay = CreateFrame("Frame", nil, NSI.NSRTFrame, "BackdropTemplate")
    NSI.NSRTFrame.SecretDisplay:Hide()
    NSI.NSRTFrame.SecretDisplay:SetPoint(NSRT.Settings.GenericDisplay.Anchor, NSI.NSRTFrame, NSRT.Settings.GenericDisplay.relativeTo, NSRT.Settings.GenericDisplay.xOffset, NSRT.Settings.GenericDisplay.yOffset)
    NSI.NSRTFrame.SecretDisplay.Text = NSI.NSRTFrame.SecretDisplay:CreateFontString(nil, "OVERLAY")
    NSI.NSRTFrame.SecretDisplay.Text:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), NSRT.Settings.GlobalEncounterFontSize, "OUTLINE")
    NSI.NSRTFrame.SecretDisplay.Text:SetPoint("TOPLEFT", NSI.NSRTFrame.generic_display, "TOPLEFT", 0, 0)
    NSI.NSRTFrame.SecretDisplay.Text:SetJustifyH("LEFT")
    NSI.NSRTFrame.SecretDisplay.Text:SetText("")
    NSI.NSRTFrame.SecretDisplay:SetSize(2000, 2000)

    -- --------------------------------------------------------
    -- Build options tables
    -- --------------------------------------------------------
    local general_options1_table         = BuildGeneralOptions()
    local nicknames_options1_table       = BuildNicknamesOptions()
    local reminder_options1_table        = BuildReminderOptions()
    local reminder_note_options1_table   = BuildReminderNoteOptions()
    local assignments_options1_table     = BuildAssignmentsOptions()
    local encounteralerts_options1_table = BuildEncounterAlertsOptions()
    local readycheck_options1_table      = BuildReadyCheckOptions()
    local RaidBuffMenu                   = BuildRaidBuffMenu()
    local privateaura_options1_table     = BuildPrivateAurasOptions()
    local QoL_options1_table             = BuildQoLOptions()
    local WAImports_options1_table       = BuildWAImportsOptions()

    -- --------------------------------------------------------
    -- Build callbacks
    -- --------------------------------------------------------
    local general_callback               = BuildGeneralCallback()
    local nicknames_callback             = BuildNicknamesCallback()
    local reminder_callback              = BuildReminderCallback()
    local reminder_note_callback         = BuildReminderNoteCallback()
    local assignments_callback           = BuildAssignmentsCallback()
    local encounteralerts_callback       = BuildEncounterAlertsCallback()
    local readycheck_callback            = BuildReadyCheckCallback()
    local privateaura_callback           = BuildPrivateAurasCallback()
    local QoL_callback                   = BuildQoLCallback()
    local WAImports_callback             = BuildWACallback()

    -- --------------------------------------------------------
    -- Build options menus into each content frame
    -- startX=10 : left margin within the content frame
    -- startY=-10 : just below the top of the content frame (no tab bar to skip)
    -- --------------------------------------------------------
    DF:BuildMenu(general_tab, general_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        general_callback)
    DF:BuildMenu(nicknames_tab, nicknames_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nicknames_callback)
    DF:BuildMenu(reminder_tab, reminder_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_callback)
    DF:BuildMenu(reminder_note_tab, reminder_note_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_note_callback)
    DF:BuildMenu(assignments_tab, assignments_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        assignments_callback)
    DF:BuildMenu(encounteralerts_tab, encounteralerts_options1_table, 10, -10, tab_content_height, false,
        options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template,
        options_button_template, encounteralerts_callback)
    DF:BuildMenu(readycheck_tab, readycheck_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        readycheck_callback)
    DF:BuildMenu(NSI.RaidBuffCheck, RaidBuffMenu, 2, -30, 40, false, options_text_template, options_dropdown_template,
        options_switch_template, true, options_slider_template, options_button_template, nil)
    DF:BuildMenu(privateaura_tab, privateaura_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        privateaura_callback)
    DF:BuildMenu(QoL_tab, QoL_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        QoL_callback)
    DF:BuildMenu(WAImports_tab, WAImports_options1_table, 10, -10, tab_content_height, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        WAImports_callback)
    NSI.RaidBuffCheck:SetMovable(false)
    NSI.RaidBuffCheck:EnableMouse(false)

    -- --------------------------------------------------------
    -- Build custom UI components
    -- --------------------------------------------------------
    NSUI.version_scrollbox        = BuildVersionCheckUI(versions_tab)
    NSUI.nickname_frame           = BuildNicknameEditUI()
    NSUI.cooldowns_frame          = BuildCooldownsEditUI()
    NSUI.reminders_frame          = BuildRemindersEditUI(tabSystem:GetTabFrameByName("SharedNotes"))
    NSUI.pasound_frame            = BuildPASoundEditUI()
    NSUI.personal_reminders_frame = BuildPersonalRemindersEditUI(tabSystem:GetTabFrameByName("PersonalNotes"))
    NSUI.export_string_popup      = BuildExportStringUI()
    NSUI.import_string_popup      = BuildImportStringUI()

    -- --------------------------------------------------------
    -- Status bar text
    -- --------------------------------------------------------
    local versionNumber           = " v" .. C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Version")
    --@debug@
        if versionNumber == " v@project-version@" then
            versionNumber = " Dev Build"
        end
    --@end-debug@
    local versionTitle = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Title")
    local statusBarText = versionTitle .. versionNumber .. " | |cFFFFFFFF" .. (authorsString) .. "|r"
    NSUI.StatusBar.authorName:SetText(statusBarText)
    -- --------------------------------------------------------
    -- Select the default tab
    -- --------------------------------------------------------
    SelectTab("General")
    NSI.IsBuilding = false
end

function NSUI:ToggleOptions()
    if NSUI:IsShown() then
        NSUI:Hide()
    else
        NSUI:Show()
    end
end

function NSI:NickNamesSyncPopup(unit, nicknametable)
    local popup = DF:CreateSimplePanel(UIParent, 300, 120, "Sync Nicknames", "SyncNicknamesPopup", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local label = DF:CreateLabel(popup, NSAPI:Shorten(unit) .. " is attempting to sync their nicknames with you.", 11)

    label:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    label:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    label:SetJustifyH("CENTER")

    local cancel_button = DF:CreateButton(popup, function() popup:Hide() end, 130, 20, "Cancel")
    cancel_button:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, 10)
    cancel_button:SetTemplate(options_button_template)

    local accept_button = DF:CreateButton(popup, function()
        NSI:SyncNickNamesAccept(nicknametable)
        popup:Hide()
    end, 130, 20, "Accept")
    accept_button:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    accept_button:SetTemplate(options_button_template)

    return popup
end

function NSI:DisplayText(text, duration)
    if self:Restricted() then return end
    if self.NSRTFrame and self.NSRTFrame.generic_display then
        self.NSRTFrame.generic_display.Text:SetText(text)
        self.NSRTFrame.generic_display:Show()
        self.NSRTFrame.generic_display.Text:Show()
        if self.TextHideTimer then
            self.TextHideTimer:Cancel()
            self.TextHideTimer = nil
        end
        self.TextHideTimer = C_Timer.NewTimer(duration or 10, function() self.NSRTFrame.generic_display:Hide() end)
    end
end

function NSI:DisplaySecretText(format, Hide, args)
    if self.NSRTFrame and self.NSRTFrame.SecretDisplay then
        if Hide then
            self.NSRTFrame.SecretDisplay:Hide()
            self.NSRTFrame.SecretDisplay.Text:Hide()
            return
        end
        self.NSRTFrame.SecretDisplay.Text:SetFormattedText(format or "%s", unpack(args or {}))
        self.NSRTFrame.SecretDisplay:Show()
        self.NSRTFrame.SecretDisplay.Text:Show()
    end
end
