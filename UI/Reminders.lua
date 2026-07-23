local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local L = DF.Language.GetLanguageTable(addonId)

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local window_width = Core.window_width
local window_height = Core.window_height
local tab_content_height = Core.tab_content_height
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template
local CreateButton = NSI.UI.Components.CreateButton
local CreateLocalizedButton = NSI.UI.Components.CreateLocalizedButton

-- ============================================================================
-- Preview Mode Functions
-- ============================================================================

function NSI:SpawnPreviewReminders()
    self:HideAllReminders()
    self.AllGlows = self.AllGlows or {}
    self.PlayedSound = {}
    self.StartedCountdown = {}
    self.GlowStarted = {}
    self.LGF.GetUnitFrame("player")
    local info1 = {
        text = NSI:Loc("Personals"),
        DisplayType = "Text",
        dur = 8,
        spellID = 22812,
        TTS = false,
        countdown = false,
    }
    local info2 = {
        text = NSI:Loc("Stack on").. " |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
        DisplayType = "Text",
        dur = 8,
        TTS = false,
        countdown = false,
    }
    local info3 = {
        text = NSI:Loc("Give Ironbark"),
        DisplayType = "Icon",
        dur = 8,
        spellID = 102342,
        glowunit = "player",
        TTS = false,
        countdown = false,
    }
    local spellInfo = NSRT.ReminderSettings.SpellName and C_Spell.GetSpellInfo(115203)
    local info4 = {
        text = spellInfo and spellInfo.name or "",
        DisplayType = "Icon",
        dur = 8,
        spellID = 115203,
        TTS = false,
        countdown = false,
    }
    local info5 = {
        text = NSI:Loc("Breath"),
        DisplayType = "Bar",
        dur = 8,
        spellID = 1256855,
        TTS = false,
    }
    local info6 = {
        text = NSI:Loc("Dodge"),
        DisplayType = "Bar",
        dur = 8,
        TTS = false,
    }
    local info7 = {
        text = NSI:Loc("Dispel"),
        DisplayType = "Circle",
        dur = 8,
        spellID = 528,
        TTS = false,
    }
    self:DisplayReminder(self:CreateReminder(info1, true))
    self:DisplayReminder(self:CreateReminder(info2, true))
    self:DisplayReminder(self:CreateReminder(info3, true))
    self:DisplayReminder(self:CreateReminder(info4, true))
    self:DisplayReminder(self:CreateReminder(info5, true))
    self:DisplayReminder(self:CreateReminder(info6, true))
    self:DisplayReminder(self:CreateReminder(info7, true))
    local loopInterval = 8
    if self.PreviewTicker then self.PreviewTicker:Cancel() end
    self.PreviewTicker = C_Timer.NewTicker(loopInterval, function()
        if self.IsInPreview then
            self:HideAllReminders()
            self:SpawnPreviewReminders()
        end
    end)
    self:UpdateExistingFrames()
end

function NSI:TogglePreviewMode()
    -- If already in preview, stop it
    if self.IsInPreview then
        if self.PreviewTicker then
            self.PreviewTicker:Cancel()
            self.PreviewTicker = nil
        end
        self.IsInPreview = false
        self:HideAllReminders()
        for _, v in ipairs({"IconMover", "BarMover", "TextMover", "CircleMover"}) do
            if self[v] then
                self[v]:StopMovingOrSizing()
            end
            self:MakeDraggable(self[v], nil, false)
        end
        if self.PreviewBar then self.PreviewBar:Hide() end
        NSUI:Show()
        return
    end

    local allMovers = {"IconMover", "BarMover", "TextMover", "CircleMover"}
    local allSettings = {
        IconMover = NSRT.ReminderSettings.IconSettings,
        BarMover = NSRT.ReminderSettings.BarSettings,
        TextMover = NSRT.ReminderSettings.TextSettings,
        CircleMover = NSRT.ReminderSettings.CircleSettings,
    }

    -- Build the floating preview bar once
    if not self.PreviewBar then
        local bar = CreateFrame("Frame", "NSRTPreviewBar", UIParent, "BackdropTemplate")
        bar:SetSize(230, 30)
        bar:SetPoint("TOP", UIParent, "TOP", 0, -150)
        bar:SetFrameStrata("DIALOG")
        bar:SetFrameLevel(100)
        bar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        bar:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
        bar:SetBackdropBorderColor(1, 0.55, 0, 1)

        local lbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", bar, "LEFT", 10, 0)
        lbl:SetText(NSI:Loc("Preview Mode"))
        lbl:SetTextColor(1, 0.75, 0.2, 1)

        local exitBtn = CreateFrame("Button", nil, bar)
        exitBtn:SetSize(70, 22)
        exitBtn:SetPoint("RIGHT", bar, "RIGHT", -10, 0)
        exitBtn:SetNormalFontObject("GameFontNormalSmall")
        exitBtn:SetText(NSI:Loc("Exit Preview"))
        exitBtn:GetFontString():SetTextColor(0.9, 0.3, 0.3)
        exitBtn:SetScript("OnEnter", function(b) b:GetFontString():SetTextColor(1, 0.1, 0.1) end)
        exitBtn:SetScript("OnLeave", function(b) b:GetFontString():SetTextColor(0.9, 0.3, 0.3) end)
        exitBtn:SetScript("OnClick", function() NSI:TogglePreviewMode() end)

        bar:Hide()
        self.PreviewBar = bar
    end

    -- Start preview
    self.IsInPreview = true
    for _, v in ipairs(allMovers) do
        self:MakeDraggable(self[v], allSettings[v], true)
    end

    self:SpawnPreviewReminders()
    self.PreviewBar:Show()
    NSUI:Hide()
end

-- ============================================================================
-- Import Popups
-- ============================================================================
local ImportReminderStringFrame
local function ImportReminderString(name, IsUpdate)
    local popup = ImportReminderStringFrame
    if not popup then
        popup = DF:CreateSimplePanel(NSUI, 800, 800, NSI:Loc("Import Reminder String"), "NSUIReminderImport", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameLevel(100)
        ImportReminderStringFrame = popup
    end

    if not popup.test_string_text_box then
        popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "ReminderTextEdit", true, false, true)
        popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.test_string_text_box)
        DF:ReskinSlider(popup.test_string_text_box.scroll)
        popup.test_string_text_box:SetScript("OnMouseDown", function(self)
            self:SetFocus()
        end)
    end
    NSI:SetUIFont(popup.test_string_text_box.editbox, 13, "OUTLINE")
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
        popup = DF:CreateSimplePanel(NSUI, 800, 800, NSI:Loc("Import Personal Reminder String"), "NSUIPersonalReminderImport", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameLevel(100)
        ImportPersonalReminderStringFrame = popup
    end

    if not popup.test_string_text_box then
        popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "PersonalReminderTextEdit", true, false, true)
        popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.test_string_text_box)
        DF:ReskinSlider(popup.test_string_text_box.scroll)
        popup.test_string_text_box:SetScript("OnMouseDown", function(self)
            self:SetFocus()
        end)
    end
    NSI:SetUIFont(popup.test_string_text_box.editbox, 13, "OUTLINE")
    popup.test_string_text_box:SetText(name and NSRT.PersonalReminders[name] or "")
    popup.test_string_text_box:SetFocus()
    local importtext = IsUpdate and NSI:Loc("Update") or NSI:Loc("Import")
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
            local encID = NSI:EncIDFromReminder(popup._name, true)
            if popup._isUpdate and NSI:GetActivePersonalReminders()[encID] then
                NSI:SetReminder(NSI:GetActivePersonalReminders()[encID], true)
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
    local titleText = personal and NSI:Loc("|cFF00FFFFPersonal|r Reminders") or NSI:Loc("|cFF00FFFFShared|r Reminders")

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
    NSI:SetUIFont(title, 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText(titleText)


    -- Forward-declared so the recvBtn callback (defined before the controls exist) can call them
    local ParseFirstLine
    local SetMetaReadOnly
    -- Received note bar (shared screen only) – sits between the title and the list controls
    if not personal then
        -- Forward-declare so the callback closure can reference recvBtn
        local recvBtn
        recvBtn = CreateButton(screen, "|cFF00FFFF" .. NSI:Loc("Received:") .. "|r |cFF888888" .. NSI:Loc("None") .. "|r", function()
            if screen.RefreshReceivedNote then screen.RefreshReceivedNote(true) end
        end, leftWidth - pad * 2, 22)
        recvBtn:SetLocaleKey("Received:", function()
            local content = NSI.Reminder
            if content and content ~= "" and content ~= " " then
                local name = NSRT.ActiveReminder
                if name and name ~= "" then
                    return "|cFF00FFFF" .. NSI:Loc("Received:") .. "|r |cFFFFFFFF" .. name .. "|r"
                end
                return "|cFF00FFFF" .. NSI:Loc("Received:") .. "|r |cFFFFFFFF" .. NSI:Loc("Active Note") .. "|r"
            end
            return "|cFF00FFFF" .. NSI:Loc("Received:") .. "|r |cFF888888" .. NSI:Loc("None") .. "|r"
        end)
        recvBtn:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 46)
        recvBtn.labelFrame:ClearAllPoints()
        recvBtn.labelFrame:SetPoint("LEFT", recvBtn.frame, "LEFT", 8, 0)
        recvBtn.labelFrame:SetPoint("RIGHT", recvBtn.frame, "RIGHT", -20, 0)
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

        -- Unload icon — clears the received note locally without broadcasting
        local recvUnloadBtn = CreateFrame("Button", nil, recvBtn.frame)
        recvUnloadBtn:SetSize(14, 14)
        recvUnloadBtn:SetPoint("RIGHT", recvBtn.frame, "RIGHT", -3, 0)
        recvUnloadBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
        recvUnloadBtn:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
        recvUnloadBtn:GetNormalTexture():SetDesaturated(true)
        recvUnloadBtn:SetScript("OnClick", function()
            NSI:SetReminder(nil)
            screen.viewingReceivedNote = false
            if screen.editor then screen.editor:SetText("") end
            if SetMetaReadOnly then SetMetaReadOnly(false) end
            if screen.scrollbox then screen.scrollbox:MasterRefresh() end
            if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
        end)
        function screen.UpdateReceivedBar()
            local content = NSI.Reminder
            local hasNote = content and content ~= "" and content ~= " "
            if hasNote then
                local name = NSRT.ActiveReminder
                if name and name ~= "" then
                    recvBtn:SetText("|cFF00FFFF" .. NSI:Loc("Received:") .. "|r |cFFFFFFFF" .. name .. "|r")
                else
                    recvBtn:SetText("|cFF00FFFF" .. NSI:Loc("Received:") .. "|r |cFFFFFFFF" .. NSI:Loc("Active Note") .. "|r")
                end
                -- Green border always when a note is loaded; fill only when viewing
                recvBtn.frame:SetBackdropBorderColor(0, 1, 0, 1)
                if not screen.viewingReceivedNote then
                    recvBtn.frame:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
                end
            else
                recvBtn:SetText("|cFF00FFFF" .. NSI:Loc("Received:") .. "|r |cFF888888" .. NSI:Loc("None") .. "|r")
                screen.viewingReceivedNote = false
                recvBtn.frame:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
                recvBtn.frame:SetBackdropBorderColor(0, 0, 0, 0)
            end
        end

        function screen.RefreshReceivedNote(selectReceived)
            local content = NSI.Reminder
            if not content or content == "" or content == " " then
                if screen.UpdateReceivedBar then screen.UpdateReceivedBar() end
                return
            end
            if selectReceived then
                screen.viewingReceivedNote = true
                screen.selectedName = nil
            elseif not screen.viewingReceivedNote then
                if screen.UpdateReceivedBar then screen.UpdateReceivedBar() end
                return
            end

            if screen.editor then screen.editor:SetText(content) end
            recvBtn.frame:SetBackdropColor(0, 1, 0, 1)
            local encID, name, diff = ParseFirstLine(content)
            screen._metaBossEncID = encID
            screen._metaDiff = diff
            if screen.nameEntry then screen.nameEntry:SetText(name or "") end
            if screen.diffDropdown and diff then screen.diffDropdown:Select(diff) end
            if screen.bossDropdown then screen.bossDropdown:Select(encID or 0) end
            if SetMetaReadOnly then SetMetaReadOnly(true) end
            if screen.UpdateReceivedBar then screen.UpdateReceivedBar() end
            if screen.scrollbox then screen.scrollbox:Refresh() end
        end

        -- Auto-refresh whenever the addon receives a broadcast reminder
        hooksecurefunc(NSI, "UpdateReminderFrame", function()
            if screen:IsShown() then
                if screen.RefreshReceivedNote then
                    screen.RefreshReceivedNote(false)
                elseif screen.UpdateReceivedBar then
                    screen.UpdateReceivedBar()
                end
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

    ParseFirstLine = function(text)
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

    -- Forward-declared so dropdown onclick closures can reference them before they are defined below
    local SaveCurrentNote
    local SaveReceivedNote

    local metaGap         = 4
    local bossDropW       = 180
    local diffDropW       = 110
    local timelineBtnSize = 22
    local nameEntryW      = 396 - (timelineBtnSize + metaGap)

    local function BuildBossMetaOptions()
        local options = {
            { label = NSI:Loc("No Boss"), value = 0, onclick = function(_, _, _)
                screen._metaBossEncID = nil
                if SaveCurrentNote and screen.selectedName then SaveCurrentNote(true) end
                    if SaveReceivedNote and screen.viewingReceivedNote then SaveReceivedNote(true) end
            end },
        }
        local sorted = {}
        for encID, order in pairs(NSI.EncounterOrder) do
            table.insert(sorted, { encID = encID, order = order })
        end
        table.sort(sorted, function(a, b) return a.order < b.order end)
        for _, entry in ipairs(sorted) do
            local encID = entry.encID
            table.insert(options, {
                label = NSI:Loc(NSI.BossNames[encID] or ("Encounter " .. encID)),
                value = encID,
                icon = NSI.UI.BossData.BossIcons[encID],
                iconsize = { 16, 16 },
                texcoord = { 0.05, 0.95, 0.05, 0.95 },
                onclick = function(_, _, v)
                    screen._metaBossEncID = v
                    if SaveCurrentNote and screen.selectedName then SaveCurrentNote(true) end
                    if SaveReceivedNote and screen.viewingReceivedNote then SaveReceivedNote(true) end
                end,
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
            { label = NSI:Loc("Normal"), value = "Normal", onclick = function(_, _, v)
                screen._metaDiff = v
                if SaveCurrentNote and screen.selectedName then SaveCurrentNote(true) end
                    if SaveReceivedNote and screen.viewingReceivedNote then SaveReceivedNote(true) end
            end },
            { label = NSI:Loc("Heroic"), value = "Heroic", onclick = function(_, _, v)
                screen._metaDiff = v
                if SaveCurrentNote and screen.selectedName then SaveCurrentNote(true) end
                    if SaveReceivedNote and screen.viewingReceivedNote then SaveReceivedNote(true) end
            end },
            { label = NSI:Loc("Mythic"), value = "Mythic", onclick = function(_, _, v)
                screen._metaDiff = v
                if SaveCurrentNote and screen.selectedName then SaveCurrentNote(true) end
                    if SaveReceivedNote and screen.viewingReceivedNote then SaveReceivedNote(true) end
            end },
        }
    end

    local diffDropdown = DF:CreateDropDown(screen, BuildDifficultyOptions, nil, diffDropW, 22, nil,
        screenName .. "DiffDropdown", options_dropdown_template)
    diffDropdown:SetPoint("TOPLEFT", bossDropdown.widget, "TOPRIGHT", metaGap, 0)
    screen.diffDropdown = diffDropdown

    local nameEntry = DF:CreateTextEntry(screen, function() end, nameEntryW, 22, nil, screenName .. "NameEntry", nil,
        options_dropdown_template)
    nameEntry:SetPoint("TOPLEFT", diffDropdown.widget, "TOPRIGHT", metaGap, 0)
    NSI:SetUIFont(nameEntry.editbox, 14, "OUTLINE")
    screen.nameEntry = nameEntry

    -- Jumps straight to this note in the Timeline (opening it if needed) — mirrors
    -- the icon-only Timeline button at the top of the NSUI window.
    local timelineBtn = CreateButton(screen, "",
        function()
            if screen.selectedName then
                NSI:ViewNoteInTimeline(screen.selectedName, personal)
            end
        end,
        timelineBtnSize, timelineBtnSize, screenName .. "TimelineBtn",
        [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\clock.png]], nil,
        { title = NSI:Loc("Timeline"), desc = NSI:Loc("View this note in the Timeline") }
    )
    timelineBtn:SetPoint("LEFT", nameEntry.widget, "RIGHT", metaGap, 0)
    screen.timelineBtn = timelineBtn

    local function SaveNameEntryRename(editBox)
        -- When viewing a received note, update its first line in place without touching stored notes
        if screen.viewingReceivedNote then
            editBox:ClearFocus()
            if SaveReceivedNote then SaveReceivedNote() end
            return
        end
        local oldname = screen.selectedName
        local newname = editBox:GetText()
        if not oldname or newname == "" or newname == oldname then
            editBox:ClearFocus()
            nameEntry:SetText(oldname or "")
            return
        end
        local store = NSRT[storeKey]
        if store[newname] then
            editBox:ClearFocus()
            nameEntry:SetText(oldname)
            return
        end
        local oldContent = store[oldname] or ""
        local encID, _, diff = ParseFirstLine(oldContent)
        local newFirstLine = BuildFirstLine(encID, newname, diff)
        local newContent = newFirstLine and (newFirstLine .. "\n" .. StripFirstLine(oldContent)) or oldContent
        store[newname] = newContent
        store[oldname] = nil
        if screen.editor then screen.editor:SetText(newContent) end
        if not personal and NSRT.InviteList then
            NSRT.InviteList[newname] = NSRT.InviteList[oldname]
            NSRT.InviteList[oldname] = nil
        end
        if personal then
            for _, charTable in pairs(NSRT.ActivePersonalReminder or {}) do
                for encID, name in pairs(charTable) do
                    if name == oldname then charTable[encID] = newname end
                end
            end
            if NSI.LoadedPersonalReminder == oldname then NSI.LoadedPersonalReminder = newname end
        else
            if NSRT[activeKey] == oldname then NSRT[activeKey] = newname end
        end
        local renameEncID = encID  -- encID was already parsed from oldContent above
        if renameEncID and NSRT.AutoLoadNote and NSRT.AutoLoadNote[renameEncID] == oldname then
            NSRT.AutoLoadNote[renameEncID] = newname
        end
        screen.selectedName = newname
        -- ClearFocus is intentionally called after selectedName is updated. Calling it
        -- earlier would trigger OnEditFocusLost synchronously, re-entering this function
        -- before the rename is done and causing it to treat the new name as a conflict.
        editBox:ClearFocus()
        screen.scrollbox:MasterRefresh()
    end
    nameEntry.editbox:SetScript("OnEnterPressed", SaveNameEntryRename)
    nameEntry.editbox:SetScript("OnEditFocusLost", SaveNameEntryRename)
    nameEntry.editbox:SetScript("OnEscapePressed", function(self)
        if screen.viewingReceivedNote then
            local _, parsedName = ParseFirstLine(NSI.Reminder or "")
            self:SetText(parsedName or "")
        else
            self:SetText(screen.selectedName or "")
        end
        self:ClearFocus()
    end)

    SetMetaReadOnly = function(readOnly)
        local canEdit = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or
            NSRT.Settings["Debug"] or not IsInGroup()
        local locked = readOnly and not canEdit
        if locked then
            bossDropdown:Disable()
            diffDropdown:Disable()
            nameEntry.editbox:SetEnabled(false)
        else
            bossDropdown:Enable()
            diffDropdown:Enable()
            nameEntry.editbox:SetEnabled(true)
        end
    end
    local editor = DF:NewSpecialLuaEditorEntry(screen, 600, 400, nil, screenName .. "Editor", true, true, true)
    editor:SetPoint("TOPLEFT", screen, "TOPLEFT", editorLeft, topY - 26)
    editor:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -25, 45)
    DF:ApplyStandardBackdrop(editor)
    editor.__background:SetVertexColor(63/255, 63/255, 63/255)
    editor.__background:SetAlpha(0)
    DF:ReskinSlider(editor.scroll)
    editor:SetText("")
    screen.editor = editor

    local function UpdateEditorFont()
        NSI:SetUIFont(editor.editbox, 14, "OUTLINE")
    end

    -- ====================================================================
    -- Action Buttons (below editor)
    -- ====================================================================

    SaveCurrentNote = function(useCurrentControls)
        if not screen.selectedName then return end
        local editorText = editor:GetText()
        if not useCurrentControls then
            local pastedEncID, _, pastedDiff = ParseFirstLine(editorText)
            if pastedEncID then
                screen._metaBossEncID = pastedEncID
                if screen.bossDropdown then screen.bossDropdown:Select(pastedEncID) end
            end
            if pastedDiff and pastedDiff ~= "" then
                screen._metaDiff = pastedDiff
                if screen.diffDropdown then screen.diffDropdown:Select(pastedDiff) end
            end
        end
        -- Strip any existing metadata first line from the editor, then rebuild from controls
        local bodyText = StripFirstLine(editorText)
        local newName = screen.nameEntry and screen.nameEntry:GetText()
        if not newName or newName == "" then newName = screen.selectedName end
        -- Capture the old encID before we overwrite the stored note, so we can clear
        -- the ActivePersonalReminder slot if the boss assignment changes.
        local store = NSRT[storeKey]
        local oldEncID = ParseFirstLine((store and store[screen.selectedName]) or "")
        local firstLine = BuildFirstLine(screen._metaBossEncID, newName, screen._metaDiff)
        local fullText = firstLine and (firstLine .. "\n" .. bodyText) or bodyText
        -- Update the editor so the new first line is visible
        editor:SetText(fullText)
        local oldName = screen.selectedName
        if newName ~= oldName then
            if not store[newName] then
                store[newName] = fullText
                store[oldName] = nil
                if not personal and NSRT.InviteList then
                    NSRT.InviteList[newName] = NSI:InviteListFromReminder(fullText)
                    NSRT.InviteList[oldName] = nil
                end
                if personal then
                    for _, charTable in pairs(NSRT.ActivePersonalReminder or {}) do
                        for encID, name in pairs(charTable) do
                            if name == oldName then charTable[encID] = newName end
                        end
                    end
                    if NSI.LoadedPersonalReminder == oldName then NSI.LoadedPersonalReminder = newName end
                else
                    if NSRT[activeKey] == oldName then NSRT[activeKey] = newName end
                end
                screen.selectedName = newName
            else
                NSI:ImportReminder(oldName, fullText, false, personal, true)
            end
        else
            NSI:ImportReminder(oldName, fullText, false, personal, true)
        end
        local isCurrentlyActive
        if personal then
            local newEncID = NSI:EncIDFromReminder(screen.selectedName, true)
            local activeTable = NSI:GetActivePersonalReminders()
            -- If the boss changed and this note was active under the old encID, migrate it
            -- to the new encID (unless the new encID already has a different active note).
            if oldEncID and oldEncID ~= newEncID and activeTable[oldEncID] == screen.selectedName then
                activeTable[oldEncID] = nil
                if newEncID and not activeTable[newEncID] then
                    activeTable[newEncID] = screen.selectedName
                end
            end
            isCurrentlyActive = newEncID and activeTable[newEncID] == screen.selectedName
        else
            local newEncID = NSI:EncIDFromReminder(screen.selectedName, false)
            if oldEncID and NSRT.AutoLoadNote and NSRT.AutoLoadNote[oldEncID] == oldName then
                NSRT.AutoLoadNote[oldEncID] = nil
                if newEncID then
                    NSRT.AutoLoadNote[newEncID] = screen.selectedName
                end
            end
            isCurrentlyActive = NSRT[activeKey] == screen.selectedName
        end
        if isCurrentlyActive then
            NSI:SetReminder(screen.selectedName, personal)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end

    -- Updates NSI.Reminder in place from the current meta controls + editor body.
    -- Does NOT touch NSRT.Reminders — this is only for iterating on a received note.
    SaveReceivedNote = function(useCurrentControls)
        if not screen.viewingReceivedNote then return end
        local editorText = editor:GetText()
        if not useCurrentControls then
            local pastedEncID, _, pastedDiff = ParseFirstLine(editorText)
            if pastedEncID then
                screen._metaBossEncID = pastedEncID
                if screen.bossDropdown then screen.bossDropdown:Select(pastedEncID) end
            end
            if pastedDiff and pastedDiff ~= "" then
                screen._metaDiff = pastedDiff
                if screen.diffDropdown then screen.diffDropdown:Select(pastedDiff) end
            end
        end
        local bodyText = StripFirstLine(editorText)
        local name = screen.nameEntry and screen.nameEntry:GetText() or ""
        if name == "" then
            local _, parsedName = ParseFirstLine(NSI.Reminder or "")
            name = parsedName or ""
        end
        local firstLine = BuildFirstLine(screen._metaBossEncID, name ~= "" and name or nil, screen._metaDiff)
        local fullText = firstLine and (firstLine .. "\n" .. bodyText) or bodyText
        NSI.Reminder = fullText
        editor:SetText(fullText)
    end
    local ActivateButton = CreateLocalizedButton(screen, personal and "Load" or "Load & Send", function()
        if screen.viewingReceivedNote and not personal then
            SaveReceivedNote()
            NSI:Broadcast("NSI_REM_SHARE", "RAID", NSI.Reminder, nil, true)
            screen.scrollbox:MasterRefresh()
            if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
            return
        end
        if not screen.selectedName then return end
        SaveCurrentNote()
        NSI:SetReminder(screen.selectedName, personal)
        if not personal then
            NSI:Broadcast("NSI_REM_SHARE", "RAID", NSI.Reminder, nil, true)
        end
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, personal and 80 or 120, 24)
    ActivateButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", editorLeft, 10)
    table.insert(roleGatedButtons, ActivateButton)

    local UpdateButton = CreateLocalizedButton(screen, "Save", function()
        if screen.viewingReceivedNote then
            SaveReceivedNote()
            return
        end
        SaveCurrentNote()
    end, 80, 24)
    UpdateButton:SetPoint("LEFT", ActivateButton.frame, "RIGHT", 5, 0)
    table.insert(roleGatedButtons, UpdateButton)

    local function ShowDeleteConfirm(toDelete)
        if not toDelete then return end
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, NSI:Loc("Confirm Deletion"), "NSRTDeleteReminderConfirm")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER")
        local label = DF:CreateLabel(popup, string.format(NSI:Loc("Delete \"%s\"?"), toDelete), 12, "orange")
        label:SetPoint("TOP", popup, "TOP", 0, -40)
        label:SetJustifyH("CENTER")
        local confirmBtn = CreateLocalizedButton(popup, "Confirm", function()
            NSI:RemoveReminder(toDelete, personal)
            if screen.selectedName == toDelete then
                screen.selectedName = nil
                editor:SetText("")
            end
            screen.scrollbox:MasterRefresh()
            if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
            popup:Hide()
        end, 100, 30)
        confirmBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        local cancelBtn = CreateLocalizedButton(popup, "Cancel", function() popup:Hide() end, 100, 30)
        cancelBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        popup:Show()
    end

    local DeleteButton = CreateLocalizedButton(screen, "Delete", function()
        ShowDeleteConfirm(screen.selectedName)
    end, 80, 24)
    DeleteButton:SetPoint("LEFT", UpdateButton.frame, "RIGHT", 5, 0)
    table.insert(roleGatedButtons, DeleteButton)

    if not personal then
        local function GetInviteReminderInput()
            if screen.viewingReceivedNote then
                SaveReceivedNote()
                return NSI.Reminder
            end
            return screen.selectedName
        end

        local InviteButton = CreateLocalizedButton(screen, "Invite", function()
            local reminderInput = GetInviteReminderInput()
            if reminderInput then
                NSI:InviteFromReminder(reminderInput, true)
            end
        end, 80, 24)
        InviteButton:SetPoint("LEFT", DeleteButton.frame, "RIGHT", 5, 0)
        table.insert(roleGatedButtons, InviteButton)

        local ArrangeButton = CreateLocalizedButton(screen, "Arrange", function()
            local reminderInput = GetInviteReminderInput()
            if reminderInput then
                NSI:ArrangeFromReminder(reminderInput)
            end
        end, 80, 24)
        ArrangeButton:SetPoint("LEFT", InviteButton.frame, "RIGHT", 5, 0)
        table.insert(roleGatedButtons, ArrangeButton)

        -- "Received X ago" label – bottom-right of editor, visible only while viewing received note
        local recvTimeLabel = screen:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(recvTimeLabel, 11, "")
        recvTimeLabel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -25, 14)
        recvTimeLabel:SetTextColor(0.55, 0.55, 0.55, 1)
        recvTimeLabel:Hide()

        local function UpdateRecvTimeLabel()
            if screen.viewingReceivedNote and NSI.ReminderReceivedTime then
                local elapsed = GetTime() - NSI.ReminderReceivedTime
                local txt
                if elapsed < 60 then
                    txt = string.format(NSI:Loc("|cFF00FFFFReceived|r %ds ago"), math.floor(elapsed))
                else
                    txt = string.format(NSI:Loc("|cFF00FFFFReceived|r %dm ago"), math.floor(elapsed / 60))
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

    local listButtonGap = 3
    local listButtonWidth = (leftWidth - pad * 2 - listButtonGap * 2) / 3

    local ImportButton = CreateLocalizedButton(screen, "Import", function()
        if personal then
            ImportPersonalReminderString(nil, false)
        else
            ImportReminderString(nil, false)
        end
    end, listButtonWidth, 22)
    ImportButton:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 22)

    local ClearButton = CreateLocalizedButton(screen, "Unload", function()
        if not personal then
            NSI:SetReminder(nil)
            NSI:Broadcast("NSI_REM_SHARE", "RAID", " ", nil, true)
        else
            local encID = screen.selectedName and NSI:EncIDFromReminder(screen.selectedName, true)
            NSI:SetReminder(nil, true, nil, encID)
        end
        screen.selectedName = nil
        editor:SetText("")
        screen.scrollbox:MasterRefresh()
        if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
    end, listButtonWidth, 22)
    ClearButton:SetPoint("LEFT", ImportButton.frame, "RIGHT", listButtonGap, 0)

    local DeleteAllButton = CreateLocalizedButton(screen, "Delete All", function()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, NSI:Loc("Confirm Clear All"), "NSRTClearAllConfirm")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER")
        local label = DF:CreateLabel(popup, NSI:Loc("Delete ALL reminders?"), 12, "orange")
        label:SetPoint("TOP", popup, "TOP", 0, -40)
        label:SetJustifyH("CENTER")
        local confirmBtn = CreateLocalizedButton(popup, "Confirm", function()
            for _, reminder in ipairs(NSI:GetAllReminderNames(personal)) do
                NSI:RemoveReminder(reminder.name, personal)
            end
            NSI:SetReminder(nil, personal)
            screen.selectedName = nil
            editor:SetText("")
            screen.scrollbox:MasterRefresh()
            if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
            popup:Hide()
        end, 100, 30)
        confirmBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        local cancelBtn = CreateLocalizedButton(popup, "Cancel", function() popup:Hide() end, 100, 30)
        cancelBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        popup:Show()
    end, listButtonWidth, 22)
    DeleteAllButton:SetPoint("LEFT", ClearButton.frame, "RIGHT", listButtonGap, 0)

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
                label = NSI:Loc("All Bosses"),
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
                local bossName = NSI:Loc(NSI.BossNames[encID] or ("Encounter " .. encIDStr))
                table.insert(options, {
                    label = bossName,
                    value = encID,
                    icon = NSI.UI.BossData.BossIcons[encID],
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
        SetMetaReadOnly(false)
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

        if screen.nameEntry then screen.nameEntry:SetText(type(name) == "string" and name or "") end
        if screen.diffDropdown and diff then screen.diffDropdown:Select(diff) end
        if screen.bossDropdown then screen.bossDropdown:Select(encID or 0) end

        -- Show full content including the metadata first line
        editor:SetText(rawContent)
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
            line.nameLabel:SetText(reminderData.hasencID and reminderData.name or (reminderData.name .. " " .. NSI:Loc("(No Enc)")))

            local encID = tonumber(reminderData.hasencID)
            if not screen.filterEncID and encID and NSI.UI.BossData.BossIcons[encID] then
                line.bossIcon:SetTexture(NSI.UI.BossData.BossIcons[encID])
                line.bossIcon:Show()
                line.nameLabel:SetPoint("LEFT", line, "LEFT", 24, 0)
            else
                line.bossIcon:Hide()
                line.nameLabel:SetPoint("LEFT", line, "LEFT", 4, 0)
            end

            local isActive = false
            local isLoaded = false
            if personal then
                local activeTable = NSI:GetActivePersonalReminders()
                if activeTable then
                    for _, activeName in pairs(activeTable) do
                        if activeName == line.name then
                            isActive = true
                            break
                        end
                    end
                end
                isLoaded = (line.name == NSI.LoadedPersonalReminder)
            else
                isActive = (line.name == NSRT.ActiveReminder)
            end

            if isLoaded or (isActive and not personal) then
                line:SetBackdropBorderColor(0, 1, 0, 1)
                line.__background:SetVertexColor(0, 1, 0)
                line.__background:SetAlpha(1)
                line.nameLabel:SetTextColor(1, 1, 1)
            elseif isActive then
                line:SetBackdropBorderColor(1, 0.8, 0, 1)
                line.__background:SetVertexColor(1, 0.8, 0)
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

        -- Boss icon (shown only when "All Bosses" filter is active)
        line.bossIcon = line:CreateTexture(nil, "OVERLAY")
        line.bossIcon:SetSize(16, 16)
        line.bossIcon:SetPoint("LEFT", line, "LEFT", 4, 0)
        line.bossIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        line.bossIcon:Hide()

        -- Name label (click line to select)
        line.nameLabel = line:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(line.nameLabel, 14, "")
        line.nameLabel:SetPoint("LEFT", line, "LEFT", 4, 0)
        line.nameLabel:SetPoint("RIGHT", line, "RIGHT", -38, 0)
        line.nameLabel:SetJustifyH("LEFT")
        line.nameLabel:SetWordWrap(false)

        line:SetScript("OnClick", function()
            local now = GetTime()
            if personal and line._lastClick and (now - line._lastClick) < 0.4 then
                -- Double-click: select and load the note
                line._lastClick = nil
                SelectReminder(line.name)
                SaveCurrentNote()
                NSI:SetReminder(line.name, true)
                screen.scrollbox:MasterRefresh()
                if NSUI.Sidebar then NSUI.Sidebar:UpdateIcons() end
            else
                line._lastClick = now
                SelectReminder(line.name)
            end
        end)

        -- Delete button (trash icon, rightmost)
        line.deleteButton = CreateFrame("Button", nil, line)
        line.deleteButton:SetSize(14, 14)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -3, 0)
        line.deleteButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        line.deleteButton:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
        line.deleteButton:SetScript("OnClick", function()
            ShowDeleteConfirm(line.name)
        end)

        -- Edit button (pencil icon, left of trash)
        line.editButton = CreateFrame("Button", nil, line)
        line.editButton:SetSize(14, 14)
        line.editButton:SetPoint("RIGHT", line.deleteButton, "LEFT", -3, 0)
        line.editButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\pencil.png]])
        line.editButton:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\pencil.png]])
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
            line.deleteButton:Show()
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
            if personal then
                for _, charTable in pairs(NSRT.ActivePersonalReminder or {}) do
                    for eid, name in pairs(charTable) do
                        if name == oldname then charTable[eid] = newname end
                    end
                end
                if NSI.LoadedPersonalReminder == oldname then NSI.LoadedPersonalReminder = newname end
            else
                if NSRT[activeKey] == oldname then NSRT[activeKey] = newname end
            end
            local encID = ParseFirstLine(store[oldname] or "")  -- read before nil-ing
            if encID and NSRT.AutoLoadNote and NSRT.AutoLoadNote[encID] == oldname then
                NSRT.AutoLoadNote[encID] = newname
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
            line.deleteButton:Hide()
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

    local CreateNoteButton = CreateLocalizedButton(screen, "+ Create Note", function()
        local noteName = NSI:Loc("New Note")
        local store = NSRT[storeKey]
        local n = 2
        while store[noteName] do
            noteName = NSI:Loc("New Note") .. " " .. n
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
        -- Auto-select the received note on the shared screen if one is loaded
        if not personal then
            local content = NSI.Reminder
            if content and content ~= "" and content ~= " " then
                self.viewingReceivedNote = true
                self.selectedName = nil
                if self.editor then self.editor:SetText(content) end
                if self._recvBtn then self._recvBtn.frame:SetBackdropColor(0, 1, 0, 1) end
                local encID, name, diff = ParseFirstLine(content)
                self._metaBossEncID = encID
                self._metaDiff = diff
                if self.nameEntry then self.nameEntry:SetText(name or "") end
                if self.diffDropdown and diff then self.diffDropdown:Select(diff) end
                if self.bossDropdown then self.bossDropdown:Select(encID or 0) end
                if SetMetaReadOnly then SetMetaReadOnly(true) end
                if self.scrollbox then self.scrollbox:MasterRefresh() end
                return
            end
        end
        local activeName = NSRT[activeKey]
        if personal and type(activeName) == "table" then
            activeName = next(activeName) and (select(2, next(activeName))) or nil
        end
        if activeName and type(activeName) == "string" and activeName ~= "" then
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
