local _, NSI = ...
local DF = _G["DetailsFramework"]

-- Get references from Core module
local Core = NSI.UI.Core
local NSUI = Core.NSUI
local window_width = Core.window_width
local window_height = Core.window_height
local expressway = Core.expressway
local TABS_LIST = Core.TABS_LIST
local authorsString = Core.authorsString
local options_text_template = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template = Core.options_switch_template
local options_slider_template = Core.options_slider_template
local options_button_template = Core.options_button_template

-- Get UI builder functions from modules
local BuildVersionCheckUI = NSI.UI.VersionCheck.BuildVersionCheckUI
local BuildNicknameEditUI = NSI.UI.Nicknames.BuildNicknameEditUI
local BuildRemindersEditUI = NSI.UI.Reminders.BuildRemindersEditUI
local BuildPersonalRemindersEditUI = NSI.UI.Reminders.BuildPersonalRemindersEditUI
local BuildCooldownsEditUI = NSI.UI.Cooldowns.BuildCooldownsEditUI
local BuildPASoundEditUI = NSI.UI.PrivateAuras.BuildPASoundEditUI

-- Get options builders from modules
local BuildGeneralOptions = NSI.UI.Options.General.BuildOptions
local BuildGeneralCallback = NSI.UI.Options.General.BuildCallback
local BuildNicknamesOptions = NSI.UI.Options.Nicknames.BuildOptions
local BuildNicknamesCallback = NSI.UI.Options.Nicknames.BuildCallback
local BuildSetupManagerOptions = NSI.UI.Options.SetupManager.BuildOptions
local BuildSetupManagerCallback = NSI.UI.Options.SetupManager.BuildCallback
local BuildReminderOptions = NSI.UI.Options.Reminders.BuildOptions
local BuildReminderNoteOptions = NSI.UI.Options.Reminders.BuildNoteOptions
local BuildReminderCallback = NSI.UI.Options.Reminders.BuildCallback
local BuildReminderNoteCallback = NSI.UI.Options.Reminders.BuildNoteCallback
local BuildAssignmentsOptions = NSI.UI.Options.Assignments.BuildOptions
local BuildAssignmentsCallback = NSI.UI.Options.Assignments.BuildCallback
local BuildEncounterAlertsOptions = NSI.UI.Options.EncounterAlerts.BuildOptions
local BuildEncounterAlertsCallback = NSI.UI.Options.EncounterAlerts.BuildCallback
local BuildReadyCheckOptions = NSI.UI.Options.ReadyCheck.BuildOptions
local BuildRaidBuffMenu = NSI.UI.Options.ReadyCheck.BuildRaidBuffMenu
local BuildReadyCheckCallback = NSI.UI.Options.ReadyCheck.BuildCallback
local BuildPrivateAurasOptions = NSI.UI.Options.PrivateAuras.BuildOptions
local BuildPrivateAurasCallback = NSI.UI.Options.PrivateAuras.BuildCallback

function NSUI:Init()
    -- Create the scale bar
    DF:CreateScaleBar(NSUI, NSRT.NSUI)
    NSUI:SetScale(NSRT.NSUI.scale)

    -- Create the tab container
    local tabContainer = DF:CreateTabContainer(NSUI, "Northern Sky", "NSUI_TabsTemplate", TABS_LIST, {
        width = window_width,
        height = window_height - 5,
        backdrop_color = { 0, 0, 0, 0.2 },
        backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 }
    })
    tabContainer:SetPoint("CENTER", NSUI, "CENTER", 0, 0)

    -- Get tab frames
    local general_tab = tabContainer:GetTabFrameByName("General")
    local nicknames_tab = tabContainer:GetTabFrameByName("Nicknames")
    local cooldowns_tab = tabContainer:GetTabFrameByName("Cooldowns")
    local versions_tab = tabContainer:GetTabFrameByName("Versions")
    local setupmanager_tab = tabContainer:GetTabFrameByName("SetupManager")
    local reminder_tab = tabContainer:GetTabFrameByName("Reminders")
    local reminder_note_tab = tabContainer:GetTabFrameByName("Reminders-Note")
    local assignments_tab = tabContainer:GetTabFrameByName("Assignments")
    local encounteralerts_tab = tabContainer:GetTabFrameByName("EncounterAlerts")
    local readycheck_tab = tabContainer:GetTabFrameByName("ReadyCheck")
    local privateaura_tab = tabContainer:GetTabFrameByName("PrivateAura")

    -- Generic text display
    NSI.NSRTFrame.generic_display = NSI.NSRTFrame:CreateFontString(nil, "OVERLAY")
    NSI.NSRTFrame.generic_display:SetFont(expressway, 20, "OUTLINE")
    NSI.NSRTFrame.generic_display:SetPoint("CENTER", NSI.NSRTFrame, "CENTER", -200, 400)
    NSI.NSRTFrame.generic_display:SetJustifyH("LEFT")
    NSI.NSRTFrame.generic_display:Hide()

    -- Build options tables from modules
    local general_options1_table = BuildGeneralOptions()
    local nicknames_options1_table = BuildNicknamesOptions()
    local setupmanager_options1_table = BuildSetupManagerOptions()
    local reminder_options1_table = BuildReminderOptions()
    local reminder_note_options1_table = BuildReminderNoteOptions()
    local assignments_options1_table = BuildAssignmentsOptions()
    local encounteralerts_options1_table = BuildEncounterAlertsOptions()
    local readycheck_options1_table = BuildReadyCheckOptions()
    local RaidBuffMenu = BuildRaidBuffMenu()
    local privateaura_options1_table = BuildPrivateAurasOptions()

    -- Build callbacks
    local general_callback = BuildGeneralCallback()
    local nicknames_callback = BuildNicknamesCallback()
    local setupmanager_callback = BuildSetupManagerCallback()
    local reminder_callback = BuildReminderCallback()
    local reminder_note_callback = BuildReminderNoteCallback()
    local assignments_callback = BuildAssignmentsCallback()
    local encounteralerts_callback = BuildEncounterAlertsCallback()
    local readycheck_callback = BuildReadyCheckCallback()
    local privateaura_callback = BuildPrivateAurasCallback()

    -- Build options menu for each tab
    DF:BuildMenu(general_tab, general_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        general_callback)
    DF:BuildMenu(nicknames_tab, nicknames_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nicknames_callback)
    DF:BuildMenu(setupmanager_tab, setupmanager_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        setupmanager_callback)
    DF:BuildMenu(reminder_tab, reminder_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_callback)
    DF:BuildMenu(reminder_note_tab, reminder_note_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_note_callback)
    DF:BuildMenu(assignments_tab, assignments_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        assignments_callback)
    DF:BuildMenu(encounteralerts_tab, encounteralerts_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        encounteralerts_callback)
    DF:BuildMenu(readycheck_tab, readycheck_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        readycheck_callback)
    DF:BuildMenu(NSI.RaidBuffCheck, RaidBuffMenu, 2, -30, 40, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
    DF:BuildMenu(privateaura_tab, privateaura_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        privateaura_callback)
    NSI.RaidBuffCheck:SetMovable(false)
    NSI.RaidBuffCheck:EnableMouse(false)

    -- Build UI components from modules
    NSUI.version_scrollbox = BuildVersionCheckUI(versions_tab)
    NSUI.nickname_frame = BuildNicknameEditUI()
    NSUI.cooldowns_frame = BuildCooldownsEditUI()
    NSUI.reminders_frame = BuildRemindersEditUI()
    NSUI.pasound_frame = BuildPASoundEditUI()
    NSUI.personal_reminders_frame = BuildPersonalRemindersEditUI()

    -- Version Number in status bar
    local versionTitle = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Title")
    local verisonNumber = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Version")
    local statusBarText = versionTitle .. " v" .. verisonNumber .. " | |cFFFFFFFF" .. (authorsString) .. "|r"
    NSUI.StatusBar.authorName:SetText(statusBarText)
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
        self.NSRTFrame.generic_display:SetText(text)
        self.NSRTFrame.generic_display:Show()
        if self.TextHideTimer then
            self.TextHideTimer:Cancel()
            self.TextHideTimer = nil
        end
        self.TextHideTimer = C_Timer.NewTimer(duration or 10, function() self.NSRTFrame.generic_display:Hide() end)
    end
end
