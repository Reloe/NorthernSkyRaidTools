local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local window_width = Core.window_width
local window_height = Core.window_height
local tab_content_height = Core.tab_content_height
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template
local CreateButton = NSI.UI.Components.CreateButton

-- ============================================================================
-- Import Popups
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
            local before = {}
            for k in pairs(NSRT.Reminders) do before[k] = true end
            if popup._isUpdate then
                NSI:ImportReminder(popup._name, import_string, false, false, true)
            else
                NSI:ImportFullReminderString(import_string, false, false, popup._name)
            end
            if popup._isUpdate and NSRT.ActiveReminder then
                NSI:SetReminder(NSRT.ActiveReminder)
            end
            popup.test_string_text_box:SetText("")
            if NSUI.reminders_frame then
                if NSUI.reminders_frame.scrollbox then
                    NSUI.reminders_frame.scrollbox:MasterRefresh()
                end
                local newName = popup._isUpdate and popup._name or nil
                if not newName then
                    for k in pairs(NSRT.Reminders) do
                        if not before[k] then
                            newName = k; break
                        end
                    end
                end
                if newName and NSUI.reminders_frame.SelectReminder then
                    NSUI.reminders_frame.SelectReminder(newName)
                end
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
            local before = {}
            for k in pairs(NSRT.PersonalReminders) do before[k] = true end
            if popup._isUpdate then
                NSI:ImportReminder(popup._name, import_string, false, true, true)
            else
                NSI:ImportFullReminderString(import_string, true, false, popup._name)
            end
            if popup._isUpdate and NSRT.ActivePersonalReminder then
                NSI:SetReminder(NSRT.ActivePersonalReminder, true)
            end
            popup.test_string_text_box:SetText("")
            if NSUI.personal_reminders_frame then
                if NSUI.personal_reminders_frame.scrollbox then
                    NSUI.personal_reminders_frame.scrollbox:MasterRefresh()
                end
                local newName = popup._isUpdate and popup._name or nil
                if not newName then
                    for k in pairs(NSRT.PersonalReminders) do
                        if not before[k] then
                            newName = k; break
                        end
                    end
                end
                if newName and NSUI.personal_reminders_frame.SelectReminder then
                    NSUI.personal_reminders_frame.SelectReminder(newName)
                end
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

local function BuildReminderScreen(personal, parentFrame)
    local activeKey = personal and "ActivePersonalReminder" or "ActiveReminder"
    local storeKey = personal and "PersonalReminders" or "Reminders"
    local screenName = personal and "NSUIPersonalReminderScreen" or "NSUISharedReminderScreen"
    local titleText = personal and "|cFF00FFFFPersonal|r Reminders" or "|cFF00FFFFShared|r Reminders"

    -- Main container: use the provided tab frame, or create a standalone floating frame
    local screen
    local contentHeight
    if parentFrame then
        screen = parentFrame
        contentHeight = parentFrame:GetHeight()
        if contentHeight == 0 then contentHeight = tab_content_height end
    else
        local contentArea = NSUI.ContentArea
        screen = CreateFrame("Frame", screenName, NSUI, "BackdropTemplate")
        screen:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
        screen:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
        screen:SetFrameLevel(NSUI:GetFrameLevel() + 20)
        DF:ApplyStandardBackdrop(screen)
        screen:Hide()
        contentHeight = contentArea:GetHeight() or (window_height - 54)
    end

    screen.selectedName = nil
    screen.filterEncID = nil

    -- Layout
    local leftWidth = 300
    local pad = 10
    local topY = -10

    -- Title
    local title = screen:CreateFontString(nil, "OVERLAY")
    title:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText(titleText)

    -- Active reminder label
    local Active_Text = DF:CreateLabel(screen, "Active: None", 11)
    Active_Text:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, 10)
    Active_Text:SetWidth(leftWidth - pad)

    local function UpdateActiveText()
        local activeName = NSRT[activeKey]
        if activeName and activeName ~= "" then
            Active_Text.text = "|cFF00FFFFActive: |cFFFFFFFF" .. activeName
        else
            Active_Text.text = "|cFF00FFFFActive: |cFFFFFFFFNone"
        end
    end

    -- ====================================================================
    -- Right Panel: Text Editor
    -- ====================================================================

    local editorLeft = leftWidth + pad

    local editorTitle = screen:CreateFontString(nil, "OVERLAY")
    editorTitle:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "OUTLINE")
    editorTitle:SetPoint("TOPLEFT", screen, "TOPLEFT", editorLeft, topY)
    editorTitle:SetText("|cFFFF8800Reminder Content|r")

    local editor = DF:NewSpecialLuaEditorEntry(screen, 600, 400, _, screenName .. "Editor", true, true, true)
    editor:SetPoint("TOPLEFT", screen, "TOPLEFT", editorLeft, topY - 18)
    editor:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -25, 45)
    DF:ApplyStandardBackdrop(editor)
    editor.__background:SetVertexColor(63/255, 63/255, 63/255)
    editor.__background:SetAlpha(0)
    DF:ReskinSlider(editor.scroll)
    editor:SetText("")
    screen.editor = editor

    local function UpdateEditorFont()
        editor.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "OUTLINE")
    end

    -- ====================================================================
    -- Action Buttons (below editor)
    -- ====================================================================

    local activateLabel = personal and "Load" or "Activate & Send"
    local ActivateButton = CreateButton(screen, activateLabel, function()
        if not screen.selectedName then return end
        NSI:SetReminder(screen.selectedName, personal)
        UpdateActiveText()
        if not personal then
            NSI:Broadcast("NSI_REM_SHARE", "RAID", NSI.Reminder, nil, true)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, personal and 80 or 120, 24)
    ActivateButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", editorLeft, 10)

    local UpdateButton = CreateButton(screen, "Update", function()
        if not screen.selectedName then return end
        local text = editor:GetText()
        NSI:ImportReminder(screen.selectedName, text, false, personal, true)
        local currentActive = NSRT[activeKey]
        if currentActive == screen.selectedName then
            NSI:SetReminder(screen.selectedName, personal)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, 80, 24)
    UpdateButton:SetPoint("LEFT", ActivateButton.frame, "RIGHT", 5, 0)

    local DeleteButton = CreateButton(screen, "Delete", function()
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
    end, 80, 24)
    DeleteButton:SetPoint("LEFT", UpdateButton.frame, "RIGHT", 5, 0)

    if not personal then
        local InviteButton = CreateButton(screen, "Invite", function()
            if screen.selectedName and NSRT.InviteList and NSRT.InviteList[screen.selectedName] then
                NSI:InviteFromReminder(screen.selectedName, true)
            end
        end, 80, 24)
        InviteButton:SetPoint("LEFT", DeleteButton.frame, "RIGHT", 5, 0)

        local ArrangeButton = CreateButton(screen, "Arrange", function()
            if screen.selectedName and NSRT.InviteList and NSRT.InviteList[screen.selectedName] then
                NSI:ArrangeFromReminder(screen.selectedName)
            end
        end, 80, 24)
        ArrangeButton:SetPoint("LEFT", InviteButton.frame, "RIGHT", 5, 0)
    end

    -- ====================================================================
    -- Left Panel: Reminder List
    -- ====================================================================

    local ImportButton = CreateButton(screen, "Import", function()
        if personal then
            ImportPersonalReminderString(nil, false)
        else
            ImportReminderString(nil, false)
        end
    end, 80, 22)
    ImportButton:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 22)

    local ClearButton = CreateButton(screen, "Clear", function()
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
    end, 60, 22)
    ClearButton:SetPoint("LEFT", ImportButton.frame, "RIGHT", 3, 0)

    local DeleteAllButton = CreateButton(screen, "Delete All", function()
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
    end, 80, 22)
    DeleteAllButton:SetPoint("LEFT", ClearButton.frame, "RIGHT", 3, 0)

    -- Boss filter dropdown with encounter icons
    local encounterIcons = {
        [3176] = 7448209, -- Imperator Averzian
        [3177] = 7448210, -- Vorasius
        [3179] = 7448212, -- Fallen King Salhadaar
        [3178] = 7448207, -- Vaelgor & Ezzorak
        [3180] = 7448211, -- Lightblinded Vanguard
        [3181] = 5764904, -- Crown of the Cosmos
        [3306] = 7448205, -- Chimaerus
        [3182] = 7448202, -- Belo'ren
        [3183] = 7448204, -- Midnight Falls
    }

    local function ApplyBossFilter()
        if not screen.scrollbox then return end
        local allData = NSI:GetAllReminderNames(personal)
        if screen.filterEncID then
            local filtered = {}
            for _, entry in ipairs(allData) do
                if entry.hasencID == screen.filterEncID then
                    table.insert(filtered, entry)
                end
            end
            title:SetText(titleText .. " |cFFAAAAAA(" .. #filtered .. " notes)|r")
            screen.scrollbox:SetData(filtered)
        else
            title:SetText(titleText)
            screen.scrollbox:SetData(allData)
        end
        screen.scrollbox:Refresh()
    end

    local function BuildBossFilterOptions()
        local options = {
            {
                label = "All Bosses",
                value = 1,
                onclick = function()
                    screen.filterEncID = nil
                    ApplyBossFilter()
                end
            }
        }
        local seen = {}
        for _, reminderData in ipairs(NSI:GetAllReminderNames(personal)) do
            if reminderData.hasencID and not seen[reminderData.hasencID] then
                seen[reminderData.hasencID] = true
                local encIDStr = reminderData.hasencID
                local encID = tonumber(encIDStr)
                local bossName = NSI.BossTimelineNames[encID] or ("Encounter " .. encIDStr)
                table.insert(options, {
                    label = bossName,
                    value = encID,
                    icon = encounterIcons[encID],
                    iconsize = { 16, 16 },
                    texcoord = { 0.05, 0.95, 0.05, 0.95 },
                    onclick = function()
                        screen.filterEncID = encIDStr
                        ApplyBossFilter()
                    end
                })
            end
        end
        return options
    end

    local bossFilter = DF:CreateDropDown(screen, BuildBossFilterOptions, nil, leftWidth - (pad * 2))
    bossFilter:SetTemplate(options_dropdown_template)
    bossFilter:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 46)
    screen.bossFilter = bossFilter

    -- Selection handler
    local function SelectReminder(name)
        screen.selectedName = name
        local store = NSRT[storeKey]
        if name and store and store[name] then
            editor:SetText(store[name])
        else
            editor:SetText("")
        end
        if screen.scrollbox then screen.scrollbox:Refresh() end
    end
    screen.SelectReminder = SelectReminder

    -- ScrollBox
    local listTop = topY - 70
    local scrollHeight = contentHeight - math.abs(listTop) - 35
    local lineHeight = 22
    local scrollLines = math.floor(scrollHeight / lineHeight)

    local function MasterRefresh(self)
        local allData = NSI:GetAllReminderNames(personal)
        local data = allData
        if screen.filterEncID then
            data = {}
            for _, entry in ipairs(allData) do
                if entry.hasencID == screen.filterEncID then
                    table.insert(data, entry)
                end
            end
        end
        self:SetData(data)
        self:Refresh()
        UpdateActiveText()
    end

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local reminderData = data[index]
            if not reminderData then break end
            local line = self:GetLine(i)
            line.name = reminderData.name
            line.nameLabel:SetText(reminderData.hasencID and reminderData.name or (reminderData.name .. " (No Enc)"))

            local activeName = NSRT[activeKey]
            if line.name == activeName then
                line:SetBackdropBorderColor(0, 1, 0, 1)
                line.__background:SetVertexColor(0, 1, 0)
                line.__background:SetAlpha(1)
                line.nameLabel:SetTextColor(1, 1, 1)
            elseif line.name == screen.selectedName then
                line:SetBackdropBorderColor(0.3, 0.5, 1, 1)
                line.__background:SetVertexColor(100/255, 100/255, 100/255)
                line.__background:SetAlpha(0.60)
                line.nameLabel:SetTextColor(1, 1, 1)
            else
                line:SetBackdropBorderColor(0, 0, 0, 1)
                line.__background:SetVertexColor(100/255, 100/255, 100/255)
                line.__background:SetAlpha(0.60)
                line.nameLabel:SetTextColor(0.85, 0.85, 0.85)
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Button", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * self.LineHeight) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)
        line.__background:SetVertexColor(100/255, 100/255, 100/255)
        line.__background:SetAlpha(0.60)

        -- Name label (click line to select)
        line.nameLabel = line:CreateFontString(nil, "OVERLAY")
        line.nameLabel:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "")
        line.nameLabel:SetPoint("LEFT", line, "LEFT", 4, 0)
        line.nameLabel:SetPoint("RIGHT", line, "RIGHT", -20, 0)
        line.nameLabel:SetJustifyH("LEFT")
        line.nameLabel:SetWordWrap(false)

        line:SetScript("OnClick", function()
            SelectReminder(line.name)
        end)

        -- Edit button (pencil icon, click to rename)
        line.editButton = CreateFrame("Button", nil, line)
        line.editButton:SetSize(14, 14)
        line.editButton:SetPoint("RIGHT", line, "RIGHT", -3, 0)
        line.editButton:SetNormalTexture([[Interface\Buttons\UI-GuildButton-PublicNote-Up]])
        line.editButton:SetHighlightTexture([[Interface\Buttons\UI-GuildButton-PublicNote-Up]])
        line.editButton:GetNormalTexture():SetDesaturated(true)

        -- Hidden text entry for renaming
        line.renameEntry = DF:CreateTextEntry(line, function() end, line:GetWidth() - 2, line:GetHeight())
        line.renameEntry:SetTemplate(options_dropdown_template)
        line.renameEntry:SetPoint("TOPLEFT", line, "TOPLEFT", 0, 0)
        line.renameEntry:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 0, 0)
        line.renameEntry:Hide()

        local function ExitRename()
            line.renameEntry:ClearFocus()
            line.renameEntry:Hide()
            line.nameLabel:Show()
            line.editButton:Show()
            line:Enable()
        end

        local function SaveNewName(editBox)
            local oldname = line.name
            local newname = editBox:GetText()
            ExitRename()
            if not oldname or oldname == newname then return end
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
        line.renameEntry:SetScript("OnEnterPressed", SaveNewName)
        line.renameEntry:SetScript("OnEditFocusLost", SaveNewName)
        line.renameEntry:SetScript("OnEscapePressed", function(self)
            self:SetText(line.name or "")
            ExitRename()
        end)

        line.editButton:SetScript("OnClick", function()
            line.nameLabel:Hide()
            line.editButton:Hide()
            line:Disable()
            line.renameEntry:SetText(line.name or "")
            line.renameEntry:Show()
            line.renameEntry:SetFocus()
        end)
        return line
    end

    local scrollbox = DF:CreateScrollBox(screen, "$parentReminderScrollBox", refresh, {},
        leftWidth - (pad * 2), scrollHeight, scrollLines, lineHeight, createLineFunc)
    screen.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, listTop)
    scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(scrollbox)
    scrollbox.__background:SetVertexColor(63/255, 63/255, 63/255)
    scrollbox.__background:SetAlpha(0)
    scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    for i = 1, scrollLines do
        scrollbox:CreateLine(createLineFunc)
    end

    -- OnShow: reset filter, select active reminder, refresh
    screen:SetScript("OnShow", function(self)
        self.filterEncID = nil
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

local function BuildRemindersEditUI(parentFrame)
    return BuildReminderScreen(false, parentFrame)
end

local function BuildPersonalRemindersEditUI(parentFrame)
    return BuildReminderScreen(true, parentFrame)
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
