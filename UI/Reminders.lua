local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local window_width = Core.window_width
local window_height = Core.window_height
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template

-- ============================================================================
-- Import Popups (unchanged except refresh method)
-- ============================================================================

local ImportReminderStringFrame
local function ImportReminderString(name, IsUpdate)
    local popup = ImportReminderStringFrame
    if not popup then
        popup = DF:CreateSimplePanel(NSUI, 800, 800, "Import Reminder String", "NSUIReminderImport", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameLevel(100)
        ImportReminderStringFrame = popup
    end

    if not popup.test_string_text_box then
        popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ReminderTextEdit", true, false, true)
        popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.test_string_text_box)
        DF:ReskinSlider(popup.test_string_text_box.scroll)
        popup.test_string_text_box:SetScript("OnMouseDown", function(self)
            self:SetFocus()
        end)
    end
    popup.test_string_text_box.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")
    popup.test_string_text_box:SetText(name and NSRT.Reminders[name] or "")
    popup.test_string_text_box:SetFocus()
    local importtext = IsUpdate and "Update" or "Import"
    if not popup.import_confirm_button then
        popup.import_confirm_button = DF:CreateButton(popup, function()
            local import_string = popup.test_string_text_box:GetText()
            if popup._isUpdate then
                NSI:ImportReminder(popup._name, import_string, false, false, true)
            else
                NSI:ImportFullReminderString(import_string, false, false, popup._name)
            end
            if popup._isUpdate and NSRT.ActiveReminder then
                NSI:SetReminder(NSRT.ActiveReminder) -- refresh active reminder
            end
            popup.test_string_text_box:SetText("")
            if NSUI.reminders_frame and NSUI.reminders_frame.scrollbox then
                NSUI.reminders_frame.scrollbox:MasterRefresh()
            end
            popup:Hide()
        end, 280, 20, importtext)
        popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
        popup.import_confirm_button:SetTemplate(options_button_template)
    end
    popup.import_confirm_button:SetText(importtext)
    popup._name = name
    popup._isUpdate = IsUpdate
    popup:Show()
    return popup
end

local ImportPersonalReminderStringFrame
local function ImportPersonalReminderString(name, IsUpdate)
    local popup = ImportPersonalReminderStringFrame
    if not popup then
        popup = DF:CreateSimplePanel(NSUI, 800, 800, "Import Personal Reminder String", "NSUIPersonalReminderImport", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameLevel(100)
        ImportPersonalReminderStringFrame = popup
    end

    if not popup.test_string_text_box then
        popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "PersonalReminderTextEdit", true, false, true)
        popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.test_string_text_box)
        DF:ReskinSlider(popup.test_string_text_box.scroll)
        popup.test_string_text_box:SetScript("OnMouseDown", function(self)
            self:SetFocus()
        end)
    end
    popup.test_string_text_box.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")
    popup.test_string_text_box:SetText(name and NSRT.PersonalReminders[name] or "")
    popup.test_string_text_box:SetFocus()
    local importtext = IsUpdate and "Update" or "Import"
    if not popup.import_confirm_button then
        popup.import_confirm_button = DF:CreateButton(popup, function()
            local import_string = popup.test_string_text_box:GetText()
            if popup._isUpdate then
                NSI:ImportReminder(popup._name, import_string, false, true, true)
            else
                NSI:ImportFullReminderString(import_string, true, false, popup._name)
            end
            if popup._isUpdate and NSRT.ActivePersonalReminder then
                NSI:SetReminder(NSRT.ActivePersonalReminder, true)
            end
            popup.test_string_text_box:SetText("")
            if NSUI.personal_reminders_frame and NSUI.personal_reminders_frame.scrollbox then
                NSUI.personal_reminders_frame.scrollbox:MasterRefresh()
            end
            popup:Hide()
        end, 280, 20, importtext)
        popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
        popup.import_confirm_button:SetTemplate(options_button_template)
    end
    popup.import_confirm_button:SetText(importtext)
    popup._name = name
    popup._isUpdate = IsUpdate
    popup:Show()
    return popup
end

-- ============================================================================
-- Master-Detail Reminder Screen
-- ============================================================================

local function BuildReminderScreen(personal)
    local activeKey = personal and "ActivePersonalReminder" or "ActiveReminder"
    local storeKey = personal and "PersonalReminders" or "Reminders"
    local screenName = personal and "NSUIPersonalReminderScreen" or "NSUISharedReminderScreen"
    local titleText = personal and "|cFF00FFFFPersonal|r Reminders" or "|cFF00FFFFShared|r Reminders"

    -- Main container (fills safe content area between title bar and status bar)
    local contentArea = NSUI.ContentArea

    local screen = CreateFrame("Frame", screenName, NSUI, "BackdropTemplate")
    screen:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    screen:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    screen:SetFrameLevel(NSUI:GetFrameLevel() + 20)
    DF:ApplyStandardBackdrop(screen)
    screen:Hide()

    screen.selectedName = nil

    -- Layout
    local leftWidth = 300
    local pad = 10
    local topY = -10
    local contentHeight = contentArea:GetHeight() or (window_height - 54)

    -- Title
    local title = screen:CreateFontString(nil, "OVERLAY")
    title:SetFont(NSI.LSM:Fetch("font", "Friz Quadrata TT"), 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText(titleText)

    -- Active reminder label
    local Active_Text = DF:CreateLabel(screen, "Active: None", 11)
    Active_Text:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, 10)
    Active_Text:SetWidth(leftWidth - pad)

    local function UpdateActiveText()
        local activeName = NSRT[activeKey]
        if activeName and activeName ~= "" then
            Active_Text.text = "Active: |cFFFFFFFF" .. activeName
        else
            Active_Text.text = "Active: |cFFFFFFFFNone"
        end
    end

    -- ====================================================================
    -- Right Panel: Text Editor
    -- ====================================================================

    local editorLeft = leftWidth + pad

    local editorTitle = screen:CreateFontString(nil, "OVERLAY")
    editorTitle:SetFont(NSI.LSM:Fetch("font", "Friz Quadrata TT"), 12, "OUTLINE")
    editorTitle:SetPoint("TOPLEFT", screen, "TOPLEFT", editorLeft, topY)
    editorTitle:SetText("|cFFFF8800Reminder Content|r")

    local editor = DF:NewSpecialLuaEditorEntry(screen, 600, 400, _, screenName .. "Editor", true, false, true)
    editor:SetPoint("TOPLEFT", screen, "TOPLEFT", editorLeft, topY - 18)
    editor:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -25, 45)
    DF:ApplyStandardBackdrop(editor)
    DF:ReskinSlider(editor.scroll)
    editor:SetText("")
    screen.editor = editor

    local function UpdateEditorFont()
        editor.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")
    end

    -- ====================================================================
    -- Action Buttons (below editor)
    -- ====================================================================

    local activateLabel = personal and "Load" or "Activate & Send"
    local ActivateButton = DF:CreateButton(screen, function()
        if not screen.selectedName then return end
        NSI:SetReminder(screen.selectedName, personal)
        UpdateActiveText()
        if not personal then
            NSI:Broadcast("NSI_REM_SHARE", "RAID", NSI.Reminder, nil, true)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, personal and 80 or 120, 24, activateLabel)
    ActivateButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", editorLeft, 10)
    ActivateButton:SetTemplate(options_button_template)

    local UpdateButton = DF:CreateButton(screen, function()
        if not screen.selectedName then return end
        local text = editor:GetText()
        NSI:ImportReminder(screen.selectedName, text, false, personal, true)
        local currentActive = NSRT[activeKey]
        if currentActive == screen.selectedName then
            NSI:SetReminder(screen.selectedName, personal)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, 80, 24, "Update")
    UpdateButton:SetPoint("LEFT", ActivateButton, "RIGHT", 5, 0)
    UpdateButton:SetTemplate(options_button_template)

    local DeleteButton = DF:CreateButton(screen, function()
        if not screen.selectedName then return end
        local toDelete = screen.selectedName
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Deletion", "NSRTDeleteReminderConfirm")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER")
        local label = DF:CreateLabel(popup, "Delete this reminder?", 12, "orange")
        label:SetPoint("TOP", popup, "TOP", 0, -40)
        label:SetJustifyH("CENTER")
        local confirmBtn = DF:CreateButton(popup, function()
            NSI:RemoveReminder(toDelete, personal)
            if screen.selectedName == toDelete then
                screen.selectedName = nil
                editor:SetText("")
            end
            screen.scrollbox:MasterRefresh()
            UpdateActiveText()
            if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmBtn:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        local cancelBtn = DF:CreateButton(popup, function() popup:Hide() end, 100, 30, "Cancel")
        cancelBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelBtn:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end, 80, 24, "Delete")
    DeleteButton:SetPoint("LEFT", UpdateButton, "RIGHT", 5, 0)
    DeleteButton:SetTemplate(options_button_template)

    if not personal then
        local InviteButton = DF:CreateButton(screen, function()
            if screen.selectedName and NSRT.InviteList and NSRT.InviteList[screen.selectedName] then
                NSI:InviteFromReminder(screen.selectedName, true)
            end
        end, 80, 24, "Invite")
        InviteButton:SetPoint("LEFT", DeleteButton, "RIGHT", 5, 0)
        InviteButton:SetTemplate(options_button_template)

        local ArrangeButton = DF:CreateButton(screen, function()
            if screen.selectedName and NSRT.InviteList and NSRT.InviteList[screen.selectedName] then
                NSI:ArrangeFromReminder(screen.selectedName)
            end
        end, 80, 24, "Arrange")
        ArrangeButton:SetPoint("LEFT", InviteButton, "RIGHT", 5, 0)
        ArrangeButton:SetTemplate(options_button_template)
    end

    -- ====================================================================
    -- Left Panel: Reminder List
    -- ====================================================================

    local ImportButton = DF:CreateButton(screen, function()
        if personal then
            ImportPersonalReminderString(nil, false)
        else
            ImportReminderString(nil, false)
        end
    end, 80, 22, "Import")
    ImportButton:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 22)
    ImportButton:SetTemplate(options_button_template)

    local ClearButton = DF:CreateButton(screen, function()
        if not personal then
            NSRT.StoredSharedReminder = nil
            NSI:SetReminder(nil)
            NSI:Broadcast("NSI_REM_SHARE", "RAID", " ", nil, true)
        else
            NSI:SetReminder(nil, true)
        end
        screen.selectedName = nil
        editor:SetText("")
        screen.scrollbox:MasterRefresh()
        UpdateActiveText()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, 60, 22, "Clear")
    ClearButton:SetPoint("LEFT", ImportButton, "RIGHT", 3, 0)
    ClearButton:SetTemplate(options_button_template)

    local DeleteAllButton = DF:CreateButton(screen, function()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Clear All", "NSRTClearAllConfirm")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER")
        local label = DF:CreateLabel(popup, "Delete ALL reminders?", 12, "orange")
        label:SetPoint("TOP", popup, "TOP", 0, -40)
        label:SetJustifyH("CENTER")
        local confirmBtn = DF:CreateButton(popup, function()
            for _, reminder in ipairs(NSI:GetAllReminderNames(personal)) do
                NSI:RemoveReminder(reminder.name, personal)
            end
            NSI:SetReminder(nil, personal)
            screen.selectedName = nil
            editor:SetText("")
            screen.scrollbox:MasterRefresh()
            UpdateActiveText()
            if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmBtn:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        local cancelBtn = DF:CreateButton(popup, function() popup:Hide() end, 100, 30, "Cancel")
        cancelBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelBtn:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end, 80, 22, "Delete All")
    DeleteAllButton:SetPoint("LEFT", ClearButton, "RIGHT", 3, 0)
    DeleteAllButton:SetTemplate(options_button_template)

    -- Selection handler
    local function SelectReminder(name)
        screen.selectedName = name
        local store = NSRT[storeKey]
        if name and store and store[name] then
            editor:SetText(store[name])
        else
            editor:SetText("")
        end
        screen.scrollbox:Refresh()
    end

    -- ScrollBox
    local listTop = topY - 48
    local scrollHeight = contentHeight - math.abs(listTop) - 35
    local lineHeight = 22
    local scrollLines = math.floor(scrollHeight / lineHeight)

    local function MasterRefresh(self)
        local data = NSI:GetAllReminderNames(personal)
        self:SetData(data)
        self:Refresh()
        UpdateActiveText()
    end

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local line = self:GetLine(i)
            local reminderData = data[index]
            if reminderData then
                line:Show()
                line.name = reminderData.name
                line.nameTextEntry.text = reminderData.hasencID and reminderData.name or (reminderData.name .. " (No Enc)")

                local activeName = NSRT[activeKey]
                if line.name == activeName then
                    local colors = reminderData.hasencID and {0, 1, 0, 1} or {1, 0, 0, 1}
                    line.nameTextEntry:SetBackdropBorderColor(unpack(colors))
                    line.nameTextEntry.BorderColorR = colors[1]
                    line.nameTextEntry.BorderColorG = colors[2]
                    line.nameTextEntry.BorderColorB = 0
                elseif line.name == screen.selectedName then
                    line.nameTextEntry:SetBackdropBorderColor(0.3, 0.5, 1, 1)
                    line.nameTextEntry.BorderColorR = 0.3
                    line.nameTextEntry.BorderColorG = 0.5
                    line.nameTextEntry.BorderColorB = 1
                else
                    line.nameTextEntry:SetBackdropBorderColor(0, 0, 0, 1)
                    line.nameTextEntry.BorderColorR = 0
                    line.nameTextEntry.BorderColorG = 0
                    line.nameTextEntry.BorderColorB = 0
                end
                line.nameTextEntry.BorderColorA = 1
            else
                line:Hide()
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * self.LineHeight) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.nameTextEntry = DF:CreateTextEntry(line, function() end, line:GetWidth() - 2, line:GetHeight())
        line.nameTextEntry:SetTemplate(options_dropdown_template)
        line.nameTextEntry:SetPoint("LEFT", line, "LEFT", 0, 0)

        -- Click to select and show content
        line.nameTextEntry:SetScript("OnMouseDown", function(self)
            SelectReminder(line.name)
            self:SetFocus()
        end)

        -- Rename on enter/focus lost
        local saveNewName = function(self)
            local oldname = line.name
            if not oldname then return end
            local newname = self:GetText()
            if oldname == newname then return end
            local store = NSRT[storeKey]
            if store[newname] then return end
            store[newname] = store[oldname]
            if not personal and NSRT.InviteList then
                NSRT.InviteList[newname] = NSRT.InviteList[oldname]
                NSRT.InviteList[oldname] = nil
            end
            if NSRT[activeKey] == oldname then
                NSRT[activeKey] = newname
                UpdateActiveText()
            end
            store[oldname] = nil
            if screen.selectedName == oldname then
                screen.selectedName = newname
            end
            line.name = newname
            parent:MasterRefresh()
        end
        line.nameTextEntry:SetScript("OnEnterPressed", saveNewName)
        line.nameTextEntry:SetScript("OnEditFocusLost", saveNewName)

        line.nameTextEntry:SetScript("OnEnter", function(self)
            if self.BorderColorR then
                self:SetBackdropBorderColor(self.BorderColorR, self.BorderColorG, self.BorderColorB, self.BorderColorA)
            end
        end)
        line.nameTextEntry:SetScript("OnLeave", function(self)
            if self.BorderColorR then
                self:SetBackdropBorderColor(self.BorderColorR, self.BorderColorG, self.BorderColorB, self.BorderColorA)
            end
        end)

        return line
    end

    local scrollbox = DF:CreateScrollBox(screen, "$parentReminderScrollBox", refresh, {},
        leftWidth - (pad * 2), scrollHeight, scrollLines, lineHeight, createLineFunc)
    screen.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, listTop)
    scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(scrollbox)
    scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    for i = 1, scrollLines do
        scrollbox:CreateLine(createLineFunc)
    end

    -- OnShow: refresh list, select active reminder, update editor font
    screen:SetScript("OnShow", function(self)
        UpdateActiveText()
        UpdateEditorFont()
        local activeName = NSRT[activeKey]
        if activeName and activeName ~= "" then
            SelectReminder(activeName)
        end
        if self.scrollbox then
            self.scrollbox:MasterRefresh()
        end
    end)

    return screen
end

-- ============================================================================
-- Public Builders (called from NSUI.lua)
-- ============================================================================

local function BuildRemindersEditUI()
    return BuildReminderScreen(false)
end

local function BuildPersonalRemindersEditUI()
    return BuildReminderScreen(true)
end

-- ============================================================================
-- Exports
-- ============================================================================

NSI.UI = NSI.UI or {}
NSI.UI.Reminders = {
    ImportReminderString = ImportReminderString,
    ImportPersonalReminderString = ImportPersonalReminderString,
    BuildRemindersEditUI = BuildRemindersEditUI,
    BuildPersonalRemindersEditUI = BuildPersonalRemindersEditUI,
}
