local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Accent = STYLE.Accent
local DF = _G["DetailsFramework"]

local function GetLocalizedText(key)
    return NSI:Loc(key)
end

-- Get references from Core module
local Core = NSI.UI.Core
local NSUI = Core.NSUI
local window_width                 = Core.window_width
local window_height                = Core.window_height
local content_width                = Core.content_width
local content_height               = Core.content_height
local header_height                = Core.header_height
local footer_height                = Core.footer_height
local TAB_HEADER_HEIGHT            = Core.TAB_HEADER_HEIGHT
local tab_content_height           = Core.tab_content_height
local authorsString                = Core.authorsString
local options_text_template        = Core.options_text_template
local options_dropdown_template    = Core.options_dropdown_template
local options_switch_template      = Core.options_switch_template
local options_slider_template      = Core.options_slider_template
local options_button_template      = Core.options_button_template

-- Get UI builder functions from modules
local BuildEncounterAlertsUI       = NSI.UI.EncounterAlerts.BuildEncounterAlertsUI
local BuildVersionCheckUI          = NSI.UI.VersionCheck.BuildVersionCheckUI
local BuildNicknameEditUI          = NSI.UI.Nicknames.BuildNicknameEditUI
local BuildRemindersEditUI         = NSI.UI.Reminders.BuildRemindersEditUI
local BuildPersonalRemindersEditUI = NSI.UI.Reminders.BuildPersonalRemindersEditUI
local BuildCooldownsEditUI         = NSI.UI.Cooldowns.BuildCooldownsEditUI
local BuildExportStringUI          = NSI.UI.General.BuildExportStringUI
local BuildImportStringUI          = NSI.UI.General.BuildImportStringUI
local BuildGroupExportUI           = NSI.UI.General.BuildGroupExportUI
local BuildAuraSoundsUI            = NSI.UI.AuraSounds.BuildAuraSoundsUI

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
local BuildInterruptDisplayOptions = NSI.UI.Options.InterruptDisplay.BuildOptions
local BuildInterruptDisplayCallback= NSI.UI.Options.InterruptDisplay.BuildCallback
local BuildReadyCheckOptions       = NSI.UI.Options.ReadyCheck.BuildOptions
local BuildRaidBuffMenu            = NSI.UI.Options.ReadyCheck.BuildRaidBuffMenu
local BuildReadyCheckCallback      = NSI.UI.Options.ReadyCheck.BuildCallback
local BuildAuraTrackingUI          = NSI.UI.Options.AuraTracking.BuildUI
local BuildAuraGlowsUI             = NSI.UI.Options.AuraGlows.BuildUI
local BuildPaceComparisonEditorUI  = NSI.UI.Options.PaceComparison.BuildEditorUI
local BuildQoLOptions              = NSI.UI.Options.QoL and NSI.UI.Options.QoL.BuildOptions
local BuildQoLCallback             = NSI.UI.Options.QoL and NSI.UI.Options.QoL.BuildCallback
local BuildRaidManagerOptions      = NSI.UI.Options.QoL and NSI.UI.Options.QoL.BuildRaidManagerOptions
-- ============================================================
-- Vertical tab sidebar layout
-- ============================================================

-- Tab groups: each group is a titled section of the sidebar with a separator above it.
-- Retail-only tabs are skipped on other clients; a group with no visible tab is skipped.
local TABS_GROUPS                  = {
    {
        title = "Core",
        { name = "General",    textKey = "General" },
        { name = "ReadyCheck", textKey = "Ready Check", retailOnly = true },
        { name = "Reminders",        textKey = "Reminders", retailOnly = true },
        { name = "Reminders-Note",   textKey = "Note-Display", retailOnly = true },
    },
    {
        title = "Combat",
        { name = "EncounterAlerts",  textKey = "Encounter Alerts", retailOnly = true },
        { name = "PaceComparison", textKey = "Pace-Comparison", retailOnly = true },
        { name = "InterruptDisplay", textKey = "Interrupt Display", retailOnly = true },
    },
    {
        title = "Auras",
        { name = "AuraSounds", textKey = "Aura Sounds" },
        { name = "AuraTracking", textKey = "Aura Tracking" },
        { name = "AuraGlows", textKey = "Aura Glows" },
    },
    {
        title = "Tools",
        { name = "Assignments", textKey = "Assignments", retailOnly = true },
        { name = "Nicknames", textKey = "Nicknames" },
        { name = "Versions",  textKey = "Version Check" },
    },
}
if BuildQoLOptions then
    table.insert(TABS_GROUPS[1], 2, { name = "QoL", textKey = "Quality of Life" })
end
if BuildRaidManagerOptions then
    table.insert(TABS_GROUPS[4], 2, { name = "RaidManager", textKey = "Raid Manager" })
end

-- Sidebar visual constants
local SIDEBAR_BTN_WIDTH            = 148
local SIDEBAR_BTN_HEIGHT           = 26
local SIDEBAR_BTN_GAP              = 0  -- px between consecutive buttons
local SIDEBAR_GROUP_GAP            = 14 -- extra px between groups
local SIDEBAR_HEADER_H             = 18 -- section title row above each group

-- Derived from Core: tab frames start below the shared header strip
local tab_content_y                = -header_height - TAB_HEADER_HEIGHT  -- -80

local CreateButton                 = NSI.UI.Components.CreateButton
local BuildMenu                    = NSI.UI.Components.BuildMenu

function NSUI:Init()
    if self.Initialized or self.Initializing then
        return
    end

    self.Initializing = true
    self.PendingShow = false
    NSUI:Hide()
    NSI.IsBuilding = true
    local initCoroutine
    initCoroutine = coroutine.create(function()
    -- Scale slider (left of the header)
    NSRT.NSUI.scale = tonumber(NSRT.NSUI.scale) or 1
    NSUI:CreateScaleControl(NSRT.NSUI)
    NSUI:SetScale(NSRT.NSUI.scale)
    -- Resizable window: restore the saved size; menus re-flow when the grip is released.
    NSUI:BindSize(NSRT.NSUI)
    NSUI:OnResizeDone(function() NSI.UI.Components.RelayoutMenus() end)

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

    function tabSystem:RefreshTabLabels()
        if self.GroupHeaders then
            for _, header in ipairs(self.GroupHeaders) do
                header:SetText(GetLocalizedText(header._titleKey))
            end
        end
        for _, btn in ipairs(self.AllButtons) do
            if btn._textKey then
                btn:SetText(GetLocalizedText(btn._textKey))
                NSI:SetUIFont(btn, nil)
            end
        end
    end

    -- --------------------------------------------------------
    -- Sidebar background
    -- --------------------------------------------------------
    local sidebarBg = NSI.UI.Pixel.CreateBoxFrame("frame", "NSUISidebar", NSUI)
    sidebarBg:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 2, -header_height)
    sidebarBg:SetPoint("BOTTOMLEFT", NSUI, "BOTTOMLEFT", 2, footer_height)
    sidebarBg:SetWidth(158)
    sidebarBg:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    sidebarBg:SetBackdropColor(0, 0, 0, 0.18)

    -- Thin cyan vertical separator between sidebar and content area
    local sidebarSep = NSUI:CreateTexture(nil, "artwork")
    NSI.UI.Style.PaintAccent(sidebarSep, "SetColorTexture", 0.25)
    sidebarSep:SetWidth(1)
    sidebarSep:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 160, -header_height)
    sidebarSep:SetPoint("BOTTOMLEFT", NSUI, "BOTTOMLEFT", 160, footer_height + 2)

    -- --------------------------------------------------------
    -- Create one content frame + one sidebar button per tab
    -- --------------------------------------------------------
    local btnY = -5 -- running y cursor inside sidebarBg
    local isForever = NSI:IsForever()
    local groupHeaders = {}   -- section title font strings, relocalised with the tab labels
    tabSystem.GroupHeaders = groupHeaders

    for groupIndex, group in ipairs(TABS_GROUPS) do
        local groupHasButtons = false
        for _, tab in ipairs(group) do
            -- Content frame – occupies the right portion below the shared header, hidden by default
            local contentFrame = NSI.UI.Pixel.CreateBoxFrame("frame", "NSUI_TabFrame_" .. tab.name, NSUI)
            contentFrame:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 162, tab_content_y)
            contentFrame:SetPoint("BOTTOMRIGHT", NSUI, "BOTTOMRIGHT", -2, footer_height)
            contentFrame:Hide()
            contentFrame:EnableMouse(false)

            -- Register by name; textKey is resolved lazily so locale switches are picked up
            tabSystem.AllFramesByName[tab.name] = contentFrame
            table.insert(tabSystem.AllFrames, contentFrame)

            if not (isForever and tab.retailOnly) then
                -- Add spacing only when a group has a visible sidebar button.
                if not groupHasButtons and #tabSystem.AllButtons > 0 then
                    btnY = btnY - math.floor(SIDEBAR_GROUP_GAP / 2)
                end
                if not groupHasButtons and group.title then
                    -- section header:  ------ Title ------
                    local row = CreateFrame("Frame", nil, sidebarBg)
                    row:SetSize(SIDEBAR_BTN_WIDTH, SIDEBAR_HEADER_H)
                    row:SetPoint("TOPLEFT", sidebarBg, "TOPLEFT", 5, btnY)

                    local header = row:CreateFontString(nil, "OVERLAY")
                    NSI:SetUIFont(header, "tiny", "")
                    NSI.UI.Style.PaintAccent(header, "SetTextColor", 0.9)
                    header:SetPoint("CENTER", row, "CENTER", 0, 0)
                    header._titleKey = group.title
                    header:SetText(GetLocalizedText(group.title))
                    groupHeaders[#groupHeaders + 1] = header

                    local leftLine = row:CreateTexture(nil, "ARTWORK")
                    NSI.UI.Style.PaintAccent(leftLine, "SetColorTexture", 0.30)
                    leftLine:SetHeight(1)
                    leftLine:SetPoint("LEFT", row, "LEFT", 3, 0)
                    leftLine:SetPoint("RIGHT", header, "LEFT", -6, 0)
                    local rightLine = row:CreateTexture(nil, "ARTWORK")
                    NSI.UI.Style.PaintAccent(rightLine, "SetColorTexture", 0.30)
                    rightLine:SetHeight(1)
                    rightLine:SetPoint("LEFT", header, "RIGHT", 6, 0)
                    rightLine:SetPoint("RIGHT", row, "RIGHT", -3, 0)

                    btnY = btnY - SIDEBAR_HEADER_H
                end
                groupHasButtons = true

                local btn = CreateButton(
                    sidebarBg,
                    GetLocalizedText(tab.textKey),
                    function() SelectTab(tab.name) end,
                    SIDEBAR_BTN_WIDTH, SIDEBAR_BTN_HEIGHT,
                    "NSUITabBtn_" .. tab.name
                )
                btn:SetPoint("TOPLEFT", sidebarBg, "TOPLEFT", 5, btnY)
                btn._textKey = tab.textKey

                tabSystem.AllButtonsByName[tab.name] = btn
                table.insert(tabSystem.AllButtons, btn)

                btnY = btnY - SIDEBAR_BTN_HEIGHT - SIDEBAR_BTN_GAP
            end
        end
    end

    -- --------------------------------------------------------
    -- Notes tabs – content frames registered in tabSystem but
    -- opened exclusively via the persistent header buttons below,
    -- so no sidebar button is created for them.
    -- --------------------------------------------------------
    local NOTES_HEADER_BTN_W = 190
    local NOTES_HEADER_BTN_H = 26
    -- Vertically centred in the strip between the header and the tab content
    local NOTES_HEADER_BTN_Y = -(header_height + (TAB_HEADER_HEIGHT - NOTES_HEADER_BTN_H) / 2)

    local notesTabs = {
        { name = "SharedNotes",   textKey = "Shared Notes",   icon = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\users-round.png]] },
        { name = "PersonalNotes", textKey = "Personal Notes", icon = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\user-round.png]] },
    }

    for i, nt in ipairs(notesTabs) do
        -- Content frame (same geometry as every other tab)
        local notesFrame = NSI.UI.Pixel.CreateBoxFrame("frame", "NSUI_TabFrame_" .. nt.name, NSUI)
        notesFrame:SetPoint("TOPLEFT", NSUI, "TOPLEFT", 162, tab_content_y)
        notesFrame:SetPoint("BOTTOMRIGHT", NSUI, "BOTTOMRIGHT", -2, footer_height)
        notesFrame:Hide()
        notesFrame:EnableMouse(false)

        tabSystem.AllFramesByName[nt.name] = notesFrame
        table.insert(tabSystem.AllFrames, notesFrame)

        if not isForever then
            local hdrBtn = CreateButton(
                NSUI,
                GetLocalizedText(nt.textKey),
                function() SelectTab(nt.name) end,
                NOTES_HEADER_BTN_W, NOTES_HEADER_BTN_H,
                "NSUIHeaderBtn_" .. nt.name,
                nt.icon,
                18
            )
            hdrBtn:SetPoint(
                "TOPLEFT", NSUI, "TOPLEFT",
                162 + 10 + (i - 1) * (NOTES_HEADER_BTN_W + 6),
                NOTES_HEADER_BTN_Y
            )
            hdrBtn._textKey = nt.textKey

            tabSystem.AllButtonsByName[nt.name] = hdrBtn
            table.insert(tabSystem.AllButtons, hdrBtn)
        end
    end

    -- --------------------------------------------------------
    -- Header buttons (icon-only), in the title bar next to the close button.
    -- AddHeaderButton chains them leftwards from the close button, so the order
    -- added here is the order from the right: anchor, export group, timeline.
    -- --------------------------------------------------------
    local HEADER_BTN_SIZE = 26
    if not isForever then
        local anchorBtn = CreateButton(
            NSUI.TitleBar,
            "",  -- icon-only, no text
            function() NSI:TogglePreviewMode() end,
            HEADER_BTN_SIZE, HEADER_BTN_SIZE,
            "NSUIAnchorBtn",
            [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\anchor.png]],
            nil,  -- textSize
            { title = GetLocalizedText("Edit Layout"), desc = GetLocalizedText("Move and resize reminders, notes and other displays in one place") }
        )
        NSI.UI.Components.StyleBareIconButton(anchorBtn, 16)
        NSUI:AddHeaderButton(anchorBtn)
    end

    if NSI.GetGroupExportString then
        local exportGroupBtn = CreateButton(
            NSUI.TitleBar,
            "",  -- icon-only, no text
            function()
                if NSUI.group_export_popup then
                    NSUI.group_export_popup:Show()
                end
            end,
            HEADER_BTN_SIZE, HEADER_BTN_SIZE,
            "NSUIExportGroupBtn",
            [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\external-link.png]],
            nil,  -- textSize
            { title = GetLocalizedText("Export Group"), desc = GetLocalizedText("Export your current raid composition to use with wowutils.com") },
            function() return not InCombatLockdown() and IsInGroup() end
        )
        NSI.UI.Components.StyleBareIconButton(exportGroupBtn, 16)
        NSUI:AddHeaderButton(exportGroupBtn)
    end

    if not isForever then
        local timelineBtn = CreateButton(
            NSUI.TitleBar,
            "",  -- icon-only, no text
            function() NSI:ToggleTimelineWindow() end,
            HEADER_BTN_SIZE, HEADER_BTN_SIZE,
            "NSUITimelineBtn",
            [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\clock.png]],
            nil,  -- textSize
            { title = GetLocalizedText("Timeline"), desc = GetLocalizedText("Open the Timeline window") }
        )
        NSI.UI.Components.StyleBareIconButton(timelineBtn, 16)
        NSUI:AddHeaderButton(timelineBtn)
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
    NSI.UI.Search.Create(NSUI, tabSystem)

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
    local interruptdisplay_tab    = tabSystem:GetTabFrameByName("InterruptDisplay")
    local readycheck_tab          = tabSystem:GetTabFrameByName("ReadyCheck")
    local aurasounds_tab          = tabSystem:GetTabFrameByName("AuraSounds")
    local auratracking_tab        = tabSystem:GetTabFrameByName("AuraTracking")
    local auraglows_tab           = tabSystem:GetTabFrameByName("AuraGlows")
    local pacecomparison_tab      = tabSystem:GetTabFrameByName("PaceComparison")
    local QoL_tab                 = BuildQoLOptions and tabSystem:GetTabFrameByName("QoL")
    local RaidManager_tab         = BuildRaidManagerOptions and tabSystem:GetTabFrameByName("RaidManager")

    -- --------------------------------------------------------
    -- Build options tables
    -- --------------------------------------------------------
    local general_options1_table         = BuildGeneralOptions()
    local nicknames_options1_table       = BuildNicknamesOptions()
    local reminder_options1_table        = BuildReminderOptions()
    local reminder_note_options1_table   = BuildReminderNoteOptions()
    local assignments_options1_table     = BuildAssignmentsOptions()
    local interruptdisplay_options1_table= BuildInterruptDisplayOptions()
    local readycheck_options1_table      = BuildReadyCheckOptions()
    local RaidBuffMenu                   = NSI.RaidBuffCheck and BuildRaidBuffMenu()
    local QoL_options1_table             = BuildQoLOptions and BuildQoLOptions()
    local RaidManager_options1_table     = BuildRaidManagerOptions and BuildRaidManagerOptions()
    local option_tables = {
        general_options1_table,
        nicknames_options1_table,
        reminder_options1_table,
        reminder_note_options1_table,
        assignments_options1_table,
        interruptdisplay_options1_table,
        readycheck_options1_table,
    }
    if RaidBuffMenu then option_tables[#option_tables + 1] = RaidBuffMenu end
    if QoL_options1_table then option_tables[#option_tables + 1] = QoL_options1_table end
    if RaidManager_options1_table then option_tables[#option_tables + 1] = RaidManager_options1_table end
    for _, options in ipairs(option_tables) do
        options.language_addonId = addonId
    end

    -- --------------------------------------------------------
    -- Build callbacks
    -- --------------------------------------------------------
    local general_callback               = BuildGeneralCallback()
    local nicknames_callback             = BuildNicknamesCallback()
    local reminder_callback              = BuildReminderCallback()
    local reminder_note_callback         = BuildReminderNoteCallback()
    local assignments_callback           = BuildAssignmentsCallback()
    local interruptdisplay_callback      = BuildInterruptDisplayCallback()
    local readycheck_callback            = BuildReadyCheckCallback()
    local QoL_callback                   = BuildQoLCallback and BuildQoLCallback()

    -- --------------------------------------------------------
    -- Build options menus into each content frame
    -- startX=10 : left margin within the content frame
    -- startY=-10 : just below the top of the content frame (no tab bar to skip)
    -- --------------------------------------------------------
    BuildMenu(general_tab, general_options1_table, general_callback)
    coroutine.yield()
    BuildMenu(nicknames_tab, nicknames_options1_table, nicknames_callback)
    coroutine.yield()
    BuildMenu(reminder_tab, reminder_options1_table, reminder_callback)
    coroutine.yield()
    BuildMenu(reminder_note_tab, reminder_note_options1_table, reminder_note_callback)
    coroutine.yield()
    BuildMenu(assignments_tab, assignments_options1_table, assignments_callback)
    coroutine.yield()
    BuildMenu(interruptdisplay_tab, interruptdisplay_options1_table, interruptdisplay_callback)
    coroutine.yield()
    BuildMenu(readycheck_tab, readycheck_options1_table, readycheck_callback)
    coroutine.yield()
    if RaidBuffMenu then
        DF:BuildMenu(NSI.RaidBuffCheck, RaidBuffMenu, 2, -30, 40, false, options_text_template, options_dropdown_template,
            options_switch_template, true, options_slider_template, options_button_template, nil)
    end
    coroutine.yield()
    NSUI.auratracking_frame = BuildAuraTrackingUI(auratracking_tab)
    coroutine.yield()
    NSUI.auraglows_frame = BuildAuraGlowsUI(auraglows_tab)
    coroutine.yield()
    NSUI.pacecomparison_frame = BuildPaceComparisonEditorUI(pacecomparison_tab)
    if QoL_options1_table then
        BuildMenu(QoL_tab, QoL_options1_table, QoL_callback)
        coroutine.yield()
    end
    if RaidManager_options1_table then
        BuildMenu(RaidManager_tab, RaidManager_options1_table, QoL_callback)
        coroutine.yield()
    end
    C_Timer.After(0.1, function()
        NSI:ApplySelectedLanguage()
    end)
    if NSI.RaidBuffCheck then
        NSI.RaidBuffCheck:SetMovable(false)
        NSI.RaidBuffCheck:EnableMouse(false)
    end

    -- --------------------------------------------------------
    -- Build custom UI components
    -- --------------------------------------------------------
    NSUI.encounters_frame         = BuildEncounterAlertsUI(encounteralerts_tab)
    coroutine.yield()
    NSUI.version_scrollbox        = BuildVersionCheckUI(versions_tab)
    coroutine.yield()
    NSUI.nickname_frame           = BuildNicknameEditUI()
    coroutine.yield()
    NSUI.cooldowns_frame          = BuildCooldownsEditUI()
    coroutine.yield()
    NSUI.reminders_frame          = BuildRemindersEditUI(tabSystem:GetTabFrameByName("SharedNotes"))
    coroutine.yield()
    NSUI.aurasounds_frame         = BuildAuraSoundsUI(aurasounds_tab)
    coroutine.yield()
    NSUI.personal_reminders_frame = BuildPersonalRemindersEditUI(tabSystem:GetTabFrameByName("PersonalNotes"))
    coroutine.yield()
    -- Accent colour changed: everything registered with PaintAccent has already re-tinted;
    -- what is painted from state (selected list rows, rebuilt menus) is rebuilt here, once the
    -- colour picker has been still for a moment.
    do
        local pending = false
        local function Call(obj, key, ...)
            local fn = obj and obj[key]
            if type(fn) == "function" then pcall(fn, ...) end
        end
        NSI.UI.Style.OnAccentChanged(function()
            if pending then return end
            pending = true
            C_Timer.After(0.15, function()
                pending = false
                NSI.UI.Components.RelayoutMenus()
                Call(NSUI.encounters_frame, "RebuildList")
                Call(NSUI.aurasounds_frame, "RefreshCategoryList")
                for _, frame in ipairs({ NSUI.aurasounds_frame, NSUI.reminders_frame,
                                         NSUI.personal_reminders_frame, NSUI.pacecomparison_frame }) do
                    local box = frame and frame.scrollbox
                    if box then Call(box, "MasterRefresh", box) end
                end
                local at = NSUI.auratracking_frame
                Call(at, "RebuildList")
                Call(NSUI.auraglows_frame, "RebuildList")
            end)
        end)
    end
    NSUI.export_string_popup      = BuildExportStringUI()
    NSUI.import_string_popup      = BuildImportStringUI()
    if NSI.GetGroupExportString then
        NSUI.group_export_popup = BuildGroupExportUI()
    end

    -- --------------------------------------------------------
    -- Footer text (version | author; the Discord link is part of the window)
    -- --------------------------------------------------------
    local versionNumber           = " v" .. C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Version")
    --@debug@
        if versionNumber == " v@project-version@" then
            versionNumber = " Dev Build"
        end
    --@end-debug@
    local versionTitle = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Title")
    local statusBarText = versionTitle .. versionNumber .. " | |cFFFFFFFF" .. (authorsString) .. "|r"
    NSUI:SetFooterText(statusBarText)
    -- --------------------------------------------------------
    -- Select the default tab
    -- --------------------------------------------------------
    SelectTab(self.PendingTabName or "General")
    self.PendingTabName = nil
    NSI.IsBuilding = false
    self.Initialized = true
    C_Timer.After(0, function()
        if not self.Initialized then return end
        NSUI:SetScale(NSRT.NSUI.scale)
        SelectTab(tabSystem.CurrentName or "General")
        self.Initializing = false
        if self.PendingShow then
            self.PendingShow = false
            NSUI:Show()
        end
        local pendingOpenAlert = NSI.PendingOpenAlert
        if pendingOpenAlert then
            NSI.PendingOpenAlert = nil
            self.MenuFrame:SelectTabByName("EncounterAlerts")
            self.encounters_frame:OpenAlert(pendingOpenAlert.encID, pendingOpenAlert.diffID, pendingOpenAlert.internalID)
        end
        local pendingProfileImport = NSI.PendingProfileImport
        if pendingProfileImport then
            NSI.PendingProfileImport = nil
            self.import_string_popup:ImportProfileFromAPI(pendingProfileImport.string, pendingProfileImport.profileKey)
        end
    end)
    end)

    local initFrame = CreateFrame("Frame")
    initFrame:SetScript("OnUpdate", function(frame)
        local ok, errorMessage = coroutine.resume(initCoroutine)
        if not ok then
            frame:SetScript("OnUpdate", nil)
            -- The coroutine's stack is still intact after an error: include it so the
            -- failing widget can be found (a bare C-function error has no location).
            local haveStack, stack = pcall(debugstack, initCoroutine, 0, 12, 0)
            error(tostring(errorMessage) .. (haveStack and ("\n" .. stack) or ""), 0)
        elseif coroutine.status(initCoroutine) == "dead" then
            frame:SetScript("OnUpdate", nil)
            self.InitCoroutine = nil
        end
    end)
    self.InitCoroutine = initCoroutine
end

function NSUI:ToggleOptions()
    if self.Initializing then
        self.PendingShow = true
        return
    end
    if NSUI:IsShown() then
        NSUI:Hide()
    else
        NSUI:Show()
    end
end

