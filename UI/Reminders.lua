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
    local pad = 15
    local topY = -10
    local headerOffset = not personal and 24 or 0
    local roleGatedButtons = {}

    -- Title
    local title = screen:CreateFontString(nil, "OVERLAY")
    title:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText(titleText)


    -- Received note bar (shared screen only) – sits between the title and the list controls
    if not personal then
        -- Forward-declare so the callback closure can reference recvBtn
        local recvBtn
        recvBtn = CreateButton(screen, "|cFF00FFFFReceived:|r |cFF888888None|r", function()
            local content = NSI.Reminder
            if content and content ~= "" and content ~= " " then
                screen.viewingReceivedNote = true
                screen.selectedName = nil
                if screen.editor then screen.editor:SetText(content) end
                recvBtn.frame:SetBackdropColor(0, 1, 0, 1)
                if screen.scrollbox then screen.scrollbox:Refresh() end
            end
        end, leftWidth - pad * 2, 22)
        recvBtn:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 46)
        recvBtn.labelFrame:ClearAllPoints()
        recvBtn.labelFrame:SetPoint("LEFT", recvBtn.frame, "LEFT", 8, 0)
        recvBtn.labelFrame:SetPoint("RIGHT", recvBtn.frame, "RIGHT", -4, 0)
        recvBtn.labelFrame:SetHeight(22)
        recvBtn.label:SetJustifyH("LEFT")
        -- Give recvBtn its own backdrop with a 1px edge for the green border state
        recvBtn.frame:SetBackdrop({
            bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
            edgeFile = [[Interface\Buttons\WHITE8X8]],
            edgeSize = 1,
            tile     = true,
            tileSize = 64,
        })
        recvBtn.frame:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
        recvBtn.frame:SetBackdropBorderColor(0, 0, 0, 0)
        screen._recvBtn = recvBtn

        function screen.UpdateReceivedBar()
            local content = NSI.Reminder
            local hasNote = content and content ~= "" and content ~= " "
            if hasNote then
                local name = NSRT.ActiveReminder
                if name and name ~= "" then
                    recvBtn:SetText("|cFF00FFFFReceived:|r |cFFFFFFFF" .. name .. "|r")
                else
                    recvBtn:SetText("|cFF00FFFFReceived:|r |cFFFFFFFFActive Note|r")
                end
                -- Green border always when a note is loaded; fill only when viewing
                recvBtn.frame:SetBackdropBorderColor(0, 1, 0, 1)
                if not screen.viewingReceivedNote then
                    recvBtn.frame:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
                end
            else
                recvBtn:SetText("|cFF00FFFFReceived:|r |cFF888888None|r")
                screen.viewingReceivedNote = false
                recvBtn.frame:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
                recvBtn.frame:SetBackdropBorderColor(0, 0, 0, 0)
            end
        end

        -- Auto-refresh whenever the addon receives a broadcast reminder
        hooksecurefunc(NSI, "UpdateReminderFrame", function()
            if screen.UpdateReceivedBar and screen:IsShown() then
                screen.UpdateReceivedBar()
            end
        end)
    end

    -- ====================================================================
    -- Right Panel: Text Editor
    -- ====================================================================

    local editorLeft = leftWidth + pad

    -- ====================================================================
    -- Metadata bar: Boss, Difficulty, Name — replaces the "Reminder Content" label
    -- ====================================================================

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

    local function ParseFirstLine(text)
        local firstLine = text:match("^([^\n]+)")
        if not firstLine or not firstLine:find("Name:") then return nil, nil, nil end
        return tonumber(firstLine:match("EncounterID:(%d+)")),
            firstLine:match("Name:([^;\n]+)"),
            firstLine:match("Difficulty:([^;\n]+)")
    end

    local function StripFirstLine(text)
        if text:find("^[^\n]*Name:") then
            return text:match("^[^\n]*\n(.*)") or ""
        end
        return text
    end

    local function BuildFirstLine(encID, name, diff)
        if not name or name == "" then return nil end
        local line = ""
        if encID and encID ~= 0 then
            line = "EncounterID:" .. encID .. ";"
        end
        line = line .. "Name:" .. name
        if diff and diff ~= "" then line = line .. ";Difficulty:" .. diff end
        return line
    end

    screen._metaBossEncID = nil
    screen._metaDiff      = nil

    local metaGap         = 4
    local bossDropW       = 180
    local diffDropW       = 110
    local nameEntryW      = 396

    local function BuildBossMetaOptions()
        local options = {
            { label = "No Boss", value = 0, onclick = function(_, _, _) screen._metaBossEncID = nil end },
        }
        local sorted = {}
        for encID, order in pairs(NSI.EncounterOrder) do
            table.insert(sorted, { encID = encID, order = order })
        end
        table.sort(sorted, function(a, b) return a.order < b.order end)
        for _, entry in ipairs(sorted) do
            local encID = entry.encID
            table.insert(options, {
                label = NSI.BossTimelineNames[encID] or ("Encounter " .. encID),
                value = encID,
                icon = encounterIcons[encID],
                iconsize = { 16, 16 },
                texcoord = { 0.05, 0.95, 0.05, 0.95 },
                onclick = function(_, _, v) screen._metaBossEncID = v end,
            })
        end
        return options
    end

    local bossDropdown = DF:CreateDropDown(screen, BuildBossMetaOptions, nil, bossDropW, 22, nil,
        screenName .. "BossDropdown", options_dropdown_template)
    bossDropdown:SetPoint("TOPLEFT", screen, "TOPLEFT", editorLeft, topY)
    screen.bossDropdown = bossDropdown

    local function BuildDifficultyOptions()
        return {
            { label = "Normal", value = "Normal", onclick = function(_, _, v) screen._metaDiff = v end },
            { label = "Heroic", value = "Heroic", onclick = function(_, _, v) screen._metaDiff = v end },
            { label = "Mythic", value = "Mythic", onclick = function(_, _, v) screen._metaDiff = v end },
        }
    end

    local diffDropdown = DF:CreateDropDown(screen, BuildDifficultyOptions, nil, diffDropW, 22, nil,
        screenName .. "DiffDropdown", options_dropdown_template)
    diffDropdown:SetPoint("TOPLEFT", bossDropdown.widget, "TOPRIGHT", metaGap, 0)
    screen.diffDropdown = diffDropdown

    local nameEntry = DF:CreateTextEntry(screen, function() end, nameEntryW, 22, nil, screenName .. "NameEntry", nil,
        options_dropdown_template)
    nameEntry:SetPoint("TOPLEFT", diffDropdown.widget, "TOPRIGHT", metaGap, 0)
    nameEntry.editbox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "OUTLINE")
    screen.nameEntry = nameEntry

    local function SaveNameEntryRename(editBox)
        local oldname = screen.selectedName
        local newname = editBox:GetText()
        editBox:ClearFocus()
        if not oldname or newname == "" or newname == oldname then
            nameEntry:SetText(oldname or "")
            return
        end
        local store = NSRT[storeKey]
        if store[newname] then
            nameEntry:SetText(oldname)
            return
        end
        store[newname] = store[oldname]
        store[oldname] = nil
        if not personal and NSRT.InviteList then
            NSRT.InviteList[newname] = NSRT.InviteList[oldname]
            NSRT.InviteList[oldname] = nil
        end
        if NSRT[activeKey] == oldname then NSRT[activeKey] = newname end
        screen.selectedName = newname
        screen.scrollbox:MasterRefresh()
    end
    nameEntry.editbox:SetScript("OnEnterPressed", SaveNameEntryRename)
    nameEntry.editbox:SetScript("OnEditFocusLost", SaveNameEntryRename)
    nameEntry.editbox:SetScript("OnEscapePressed", function(self)
        self:SetText(screen.selectedName or "")
        self:ClearFocus()
    end)

    local editor = DF:NewSpecialLuaEditorEntry(screen, 600, 400, _, screenName .. "Editor", true, true, true)
    editor:SetPoint("TOPLEFT", screen, "TOPLEFT", editorLeft, topY - 26)
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

    local function SaveCurrentNote()
        if not screen.selectedName then return end
        local editorText = editor:GetText()
        local newName = screen.nameEntry and screen.nameEntry:GetText()
        if not newName or newName == "" then newName = screen.selectedName end
        local firstLine = BuildFirstLine(screen._metaBossEncID, newName, screen._metaDiff)
        local fullText = firstLine and (firstLine .. "\n" .. editorText) or editorText
        local oldName = screen.selectedName
        if newName ~= oldName then
            local store = NSRT[storeKey]
            if not store[newName] then
                store[newName] = fullText
                store[oldName] = nil
                if not personal and NSRT.InviteList then
                    NSRT.InviteList[newName] = NSI:InviteListFromReminder(fullText)
                    NSRT.InviteList[oldName] = nil
                end
                if NSRT[activeKey] == oldName then NSRT[activeKey] = newName end
                screen.selectedName = newName
            else
                NSI:ImportReminder(oldName, fullText, false, personal, true)
            end
        else
            NSI:ImportReminder(oldName, fullText, false, personal, true)
        end
        local currentActive = NSRT[activeKey]
        if currentActive == screen.selectedName then
            NSI:SetReminder(screen.selectedName, personal)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end

    local activateLabel = personal and "Load" or "Activate & Send"
    local ActivateButton = CreateButton(screen, activateLabel, function()
        if not screen.selectedName then return end
        if not personal then SaveCurrentNote() end
        NSI:SetReminder(screen.selectedName, personal)
        if not personal then
            NSI:Broadcast("NSI_REM_SHARE", "RAID", NSI.Reminder, nil, true)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, personal and 80 or 120, 24)
    ActivateButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", editorLeft, 10)
    table.insert(roleGatedButtons, ActivateButton)

    local UpdateButton = CreateButton(screen, "Update", function()
        SaveCurrentNote()
    end, 80, 24)
    UpdateButton:SetPoint("LEFT", ActivateButton.frame, "RIGHT", 5, 0)
    table.insert(roleGatedButtons, UpdateButton)

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
    table.insert(roleGatedButtons, DeleteButton)

    if not personal then
        local InviteButton = CreateButton(screen, "Invite", function()
            if screen.selectedName and NSRT.InviteList and NSRT.InviteList[screen.selectedName] then
                NSI:InviteFromReminder(screen.selectedName, true)
            end
        end, 80, 24)
        InviteButton:SetPoint("LEFT", DeleteButton.frame, "RIGHT", 5, 0)
        table.insert(roleGatedButtons, InviteButton)

        local ArrangeButton = CreateButton(screen, "Arrange", function()
            if screen.selectedName and NSRT.InviteList and NSRT.InviteList[screen.selectedName] then
                NSI:ArrangeFromReminder(screen.selectedName)
            end
        end, 80, 24)
        ArrangeButton:SetPoint("LEFT", InviteButton.frame, "RIGHT", 5, 0)
        table.insert(roleGatedButtons, ArrangeButton)

        -- "Received X ago" label – bottom-right of editor, visible only while viewing received note
        local recvTimeLabel = screen:CreateFontString(nil, "OVERLAY")
        recvTimeLabel:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 11, "")
        recvTimeLabel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -25, 14)
        recvTimeLabel:SetTextColor(0.55, 0.55, 0.55, 1)
        recvTimeLabel:Hide()

        local function UpdateRecvTimeLabel()
            if screen.viewingReceivedNote and NSI.ReminderReceivedTime then
                local elapsed = GetTime() - NSI.ReminderReceivedTime
                local txt
                if elapsed < 60 then
                    txt = string.format("Received %ds ago", math.floor(elapsed))
                else
                    txt = string.format("Received %dm ago", math.floor(elapsed / 60))
                end
                recvTimeLabel:SetText(txt)
                recvTimeLabel:Show()
            else
                recvTimeLabel:Hide()
            end
        end

        local recvTimeTick = 0
        screen:HookScript("OnUpdate", function(self, dt)
            recvTimeTick = recvTimeTick + dt
            if recvTimeTick >= 1 then
                recvTimeTick = 0
                UpdateRecvTimeLabel()
            end
        end)
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

    local ClearButton = CreateButton(screen, "Unload", function()
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

    local function UpdateButtonAccess()
        local canEdit = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or NSRT.Settings["Debug"] or
        not IsInGroup()
        for _, btn in ipairs(roleGatedButtons) do
            if canEdit then btn:Enable() else btn:Disable() end
        end
    end
    screen.UpdateButtonAccess = UpdateButtonAccess

    -- Boss filter dropdown
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
    bossFilter:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 46 - headerOffset)
    screen.bossFilter = bossFilter

    -- Selection handler
    local function SelectReminder(name)
        screen.viewingReceivedNote = false
        if screen._recvBtn then
            local content = NSI.Reminder
            local hasNote = content and content ~= "" and content ~= " "
            screen._recvBtn.frame:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
            screen._recvBtn.frame:SetBackdropBorderColor(hasNote and 0 or 0, hasNote and 1 or 0, 0, hasNote and 1 or 0)
        end
        screen.selectedName = name
        local store = NSRT[storeKey]
        local rawContent = (name and store and store[name]) or ""

        -- Parse metadata from the first line and populate controls
        local encID, _, diff = ParseFirstLine(rawContent)
        screen._metaBossEncID = encID
        screen._metaDiff = diff

        if screen.nameEntry then screen.nameEntry:SetText(name or "") end
        if screen.diffDropdown and diff then screen.diffDropdown:Select(diff) end
        if screen.bossDropdown then screen.bossDropdown:Select(encID or 0) end

        -- Strip the hidden first line before showing in the editor
        editor:SetText(StripFirstLine(rawContent))
        if screen.scrollbox then screen.scrollbox:Refresh() end
    end
    screen.SelectReminder = SelectReminder

    -- ScrollBox
    local listTop = topY - 70 - headerOffset
    local scrollHeight = contentHeight - math.abs(listTop) - 40
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
        if screen.UpdateReceivedBar then screen.UpdateReceivedBar() end
        if not personal and screen.UpdateButtonAccess then screen.UpdateButtonAccess() end
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
            end
            store[oldname] = nil
            if screen.selectedName == oldname then
                screen.selectedName = newname
                if screen.nameEntry then screen.nameEntry:SetText(newname) end
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

    local CreateNoteButton = CreateButton(screen, "+ Create Note", function()
        local noteName = "New Note"
        local store = NSRT[storeKey]
        local n = 2
        while store[noteName] do
            noteName = "New Note " .. n
            n = n + 1
        end
        local content = "EncounterID:3176;Name:" .. noteName .. ";Difficulty:Mythic\n"
        store[noteName] = content
        if not personal and NSRT.InviteList then
            NSRT.InviteList[noteName] = {}
        end
        screen.scrollbox:MasterRefresh()
        SelectReminder(noteName)
    end, leftWidth - (pad * 2), 22)
    CreateNoteButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, 10)

    -- OnShow: reset filter, select active reminder, refresh
    screen:SetScript("OnShow", function(self)
        self.filterEncID = nil
        UpdateEditorFont()
        if self.UpdateReceivedBar then self.UpdateReceivedBar() end
        if not personal and self.UpdateButtonAccess then self.UpdateButtonAccess() end
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
