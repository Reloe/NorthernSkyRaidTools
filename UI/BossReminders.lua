local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core                      = NSI.UI.Core
local NSUI                      = Core.NSUI
local content_width             = Core.content_width
local tab_content_height        = Core.tab_content_height

local CreateButton      = NSI.UI.Components.CreateButton
local CreateSubButton   = NSI.UI.Components.CreateSubButton
local CreateDropdown    = NSI.UI.Components.CreateDropdown
local CreateTextEntry   = NSI.UI.Components.CreateTextEntry
local CreateCheckButton = NSI.UI.Components.CreateCheckButton
local CreateColorPicker = NSI.UI.Components.CreateColorPicker
local ReskinScrollbar   = NSI.UI.Components.ReskinScrollbar
local ShowContextMenu   = NSI.UI.Components.ShowContextMenu
local BossData          = NSI.UI.BossData


local MAX_LIST_ROWS = 80   -- hard cap; more than any reasonable alert count

-- ============================================================================
-- Alert Export / Import popups
-- ============================================================================
local alertsExportPopup
local alertsImportPopup

local function ShowExportPopup(str, label)
    if not alertsExportPopup then
        alertsExportPopup = DF:CreateSimplePanel(NSUI, 800, 400, "Export Alerts",
            "NSUIEncAlertExportString", { DontRightClickClose = true })
        alertsExportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        alertsExportPopup:SetFrameLevel(100)

        alertsExportPopup.infoLabel = DF:CreateLabel(alertsExportPopup, "",
            DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        alertsExportPopup.infoLabel:SetPoint("TOPLEFT", alertsExportPopup, "TOPLEFT", 10, -30)

        alertsExportPopup.textbox = DF:NewSpecialLuaEditorEntry(alertsExportPopup, 280, 80, _,
            "EncAlertExportTextEdit", true, false, true)
        alertsExportPopup.textbox:SetPoint("TOPLEFT", alertsExportPopup, "TOPLEFT", 10, -50)
        alertsExportPopup.textbox:SetPoint("BOTTOMRIGHT", alertsExportPopup, "BOTTOMRIGHT", -10, 40)
        DF:ApplyStandardBackdrop(alertsExportPopup.textbox)
        DF:ReskinSlider(alertsExportPopup.textbox.scroll)
        alertsExportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        alertsExportPopup.textbox.editbox:SetFont(
            NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")

        local doneBtn = DF:CreateButton(alertsExportPopup, function()
            alertsExportPopup:Hide()
        end, 280, 20, "Done")
        doneBtn:SetPoint("BOTTOM", alertsExportPopup, "BOTTOM", 0, 10)
        doneBtn:SetTemplate(Core.options_button_template)
    end

    alertsExportPopup.infoLabel:SetText(label or "")
    alertsExportPopup.textbox:SetText(str or "")
    alertsExportPopup.textbox:SetFocus()
    alertsExportPopup:Show()
end

local function ShowImportPopup()
    if not alertsImportPopup then
        alertsImportPopup = DF:CreateSimplePanel(NSUI, 800, 400, "Import Alerts",
            "NSUIEncAlertImportString", { DontRightClickClose = true })
        alertsImportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        alertsImportPopup:SetFrameLevel(100)

        local statusLabel = DF:CreateLabel(alertsImportPopup,
            "Paste an alerts export string below and click Import.",
            DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        statusLabel:SetPoint("TOPLEFT", alertsImportPopup, "TOPLEFT", 10, -30)

        alertsImportPopup.textbox = DF:NewSpecialLuaEditorEntry(alertsImportPopup, 280, 80, _,
            "EncAlertImportTextEdit", true, false, true)
        alertsImportPopup.textbox:SetPoint("TOPLEFT", alertsImportPopup, "TOPLEFT", 10, -50)
        alertsImportPopup.textbox:SetPoint("BOTTOMRIGHT", alertsImportPopup, "BOTTOMRIGHT", -10, 40)
        DF:ApplyStandardBackdrop(alertsImportPopup.textbox)
        DF:ReskinSlider(alertsImportPopup.textbox.scroll)
        alertsImportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        alertsImportPopup.textbox.editbox:SetFont(
            NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "OUTLINE")

        local importBtn = DF:CreateButton(alertsImportPopup, function()
            local str = alertsImportPopup.textbox:GetText()
            local count = NSAPI:ImportAlertsString(str)
            if count then
                print("|cFF00FFFFNSRT:|r Imported " .. count .. " alert(s).")
                alertsImportPopup:Hide()
                local enc = NSUI.encounters_frame
                if enc and enc.RebuildList then enc.RebuildList() end
            else
                statusLabel:SetText(
                    "|cFFFF0000Invalid import string. Please check and try again.|r")
            end
        end, 280, 20, "Import")
        importBtn:SetPoint("BOTTOM", alertsImportPopup, "BOTTOM", 0, 10)
        importBtn:SetTemplate(Core.options_button_template)

        alertsImportPopup:HookScript("OnShow", function()
            statusLabel:SetText("Paste an alerts export string below and click Import.")
            alertsImportPopup.textbox:SetText("")
            alertsImportPopup.textbox:SetFocus()
        end)
    end

    alertsImportPopup:Show()
end

-- ============================================================================
-- BuildBossRemindersUI
-- ============================================================================
local function BuildBossRemindersUI(parentFrame)
    local screen = parentFrame

    -- ── Layout constants ────────────────────────────────────────────────────
    local leftWidth  = 240
    local pad        = 10
    local topY       = -10
    local lineHeight = 22
    local rightX     = leftWidth + pad * 2   -- 260
    local rightW     = content_width - rightX - pad  -- ~766

    -- ── Mutable state ───────────────────────────────────────────────────────
    local selectedIndex      = nil   -- index into NSRT.CustomBossAlerts[filterDiffID] (custom mode)
    local selectedReloeEncID = nil   -- encID of selected ReloeReminder alert
    local selectedReloeDiffID = nil  -- diffID of selected ReloeReminder alert
    local selectedReloeKey   = nil   -- key of selected ReloeReminder alert
    local filterEncID        = nil
    local filterDiffID       = 16    -- default Mythic
    local searchText         = ""

    -- forward declarations
    local rightPanel, SelectAlert, SelectReloeCreatedAlert, PreviewAlert, enabledCB

    -- ================================================================
    -- Left Panel ── title, filter, list, create button
    -- ================================================================
    local title = screen:CreateFontString(nil, "OVERLAY")
    title:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText("|cFF00FFFFEncounter|r Alerts")

    -- ── Filter dropdown ─────────────────────────────────────────────────────
    local function BuildFilterOptions()
        local opts = {{ label = "All Bosses", value = 0, onclick = function()
            filterEncID = nil
            if screen.RebuildList then screen.RebuildList() end
        end }}
        for _, opt in ipairs(BossData.BuildBossDropdownOptions(nil, false)) do
            local enc = opt.value
            opt.onclick = function()
                filterEncID = enc
                if screen.RebuildList then screen.RebuildList() end
            end
            table.insert(opts, opt)
        end
        return opts
    end

    local bossDDWidth = 134
    local diffDDWidth = leftWidth - pad * 2 - bossDDWidth - 6   -- 80

    local function getFilterBossSelected()
        if not filterEncID then return "All Bosses" end
        for _, opt in ipairs(BossData.BuildBossDropdownOptions(nil, false)) do
            if opt.value == filterEncID then return opt.label end
        end
        return tostring(filterEncID)
    end

    local filterDD = CreateDropdown(screen, nil, BuildFilterOptions, getFilterBossSelected,
        bossDDWidth, 22, "NSUIEncAlertFilter")
    filterDD:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 20)

    local function BuildDiffOptions()
        local function switchDiff(id)
            filterDiffID = id
            selectedIndex = nil
            if rightPanel then rightPanel:Hide() end
            if screen.RebuildList then screen.RebuildList() end
        end
        return {
            { label = "M", value = 16, onclick = function() switchDiff(16) end },
            { label = "H", value = 15, onclick = function() switchDiff(15) end },
            { label = "N", value = 14, onclick = function() switchDiff(14) end },
        }
    end

    local function getDiffSelected()
        local names = { [16] = "M", [15] = "H", [14] = "N" }
        return names[filterDiffID] or tostring(filterDiffID)
    end

    local diffDD = CreateDropdown(screen, nil, BuildDiffOptions, getDiffSelected,
        diffDDWidth, 22, "NSUIEncAlertDiffFilter")
    diffDD:SetPoint("TOPLEFT", filterDD.frame, "TOPRIGHT", 6, 0)

    -- ── Search bar ──────────────────────────────────────────────────────────
    local searchEntry = CreateTextEntry(screen, nil, nil, nil, leftWidth - pad * 2, 22,
        nil, nil, nil, "NSUIEncAlertSearch")
    searchEntry:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 20 - 22 - 4)
    searchEntry.editBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText()
        if screen.RebuildList then screen.RebuildList() end
    end)

    -- ── Native ScrollFrame list ─────────────────────────────────────────────
    local scrollTop    = topY - 20 - 22 - 4 - 22 - 6   -- below title + filter row + search + gaps = -84
    local scrollHeight = tab_content_height + scrollTop - 22 - pad * 2 - 26  -- extra 26 for import/export row
    local listW        = leftWidth - pad * 2   -- 220

    local listScroll = CreateFrame("ScrollFrame", "NSUIEncAlertListScroll", screen,
        "UIPanelScrollFrameTemplate")
    listScroll:SetSize(listW, scrollHeight)
    listScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, scrollTop)
    ReskinScrollbar(listScroll)

    local listChild = CreateFrame("Frame", nil, listScroll, "BackdropTemplate")
    listChild:SetSize(listW, 1)   -- 18px for the native scrollbar
    listChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    listChild:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
    listScroll:SetScrollChild(listChild)

    -- Pre-allocate the row pool ──────────────────────────────────────────────
    local listRows = {}

    for i = 1, MAX_LIST_ROWS do
        local row = CreateFrame("Frame", nil, listChild, "BackdropTemplate")
        row:SetSize(listChild:GetWidth(), lineHeight)
        row:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -(i - 1) * lineHeight)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.4, 0.4, 0.4)
        row.__background:SetAlpha(0.5)

        -- Enabled toggle checkbox using the shared component
        local cb = CreateCheckButton(row, "", nil, nil, 14, 14)
        cb:SetPoint("LEFT", row, "LEFT", 3, 0)
        cb.frame:HookScript("OnClick", function()
            if screen.RebuildList then screen.RebuildList() end
        end)
        row.enabledCB = cb

        row.bossIcon = row:CreateTexture(nil, "ARTWORK")
        row.bossIcon:SetSize(16, 16)
        row.bossIcon:SetPoint("LEFT", cb.frame, "RIGHT", 4, 0)
        row.bossIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)


        row.nameLabel = row:CreateFontString(nil, "OVERLAY")
        row.nameLabel:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "")
        row.nameLabel:SetPoint("LEFT", row.bossIcon, "RIGHT", 4, 0)
        row.nameLabel:SetPoint("RIGHT", row, "RIGHT", -22, 0)
        row.nameLabel:SetJustifyH("LEFT")
        row.nameLabel:SetWordWrap(false)

        -- Lock icon for hardcoded rows
        row.lockIcon = row:CreateTexture(nil, "ARTWORK")
        row.lockIcon:SetSize(14, 14)
        row.lockIcon:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.lockIcon:SetTexture([[Interface\PetBattles\PetBattle-LockIcon]])
        row.lockIcon:SetVertexColor(0.7, 0.7, 0.7, 0.9)
        row.lockIcon:Hide()
        row.deleteBtn = CreateFrame("Button", nil, row)
        row.deleteBtn:SetSize(14, 14)
        row.deleteBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.deleteBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        row.deleteBtn:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        row.deleteBtn:GetNormalTexture():SetDesaturated(true)
        row.deleteBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)

        row:EnableMouse(true)
        row:Hide()
        listRows[i] = row
    end

    -- Returns a display name for a ReloeReminder alert entry.
    local function ReloeAlertName(entry)
        local base = (entry.name and entry.name ~= "") and entry.name
                  or (entry.text and entry.text ~= "") and entry.text
                  or "?"
        local phase = entry.phase
        return phase and entry.name.." (P"..phase..")" or entry.name
    end

    -- RebuildList ─────────────────────────────────────────────────────────────
    local function RebuildScrollData()
        local t = {}

        -- One row per ReloeReminder alert (deduplicated by alertKey, prefer higher diffID)
        local sortedEnc = {}
        for encID in pairs(NSRT.EncounterAlerts or {}) do
            if not filterEncID or filterEncID == encID then
                table.insert(sortedEnc, encID)
            end
        end
        table.sort(sortedEnc, function(a, b)
            return (NSI.EncounterOrder[a] or 99) < (NSI.EncounterOrder[b] or 99)
        end)
        for _, encID in ipairs(sortedEnc) do
            local encTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
            if encTable then
                local diffTable = encTable[filterDiffID]
                local alerts = {}
                if type(diffTable) == "table" then
                    for key, entry in pairs(diffTable) do
                        local phase = entry.phase
                        local ReloeReminder = entry.ReloeReminder
                        if type(entry) == "table" and ReloeReminder then
                            table.insert(alerts, {
                                key           = key,
                                entry         = entry,
                                diffID        = filterDiffID,
                                phase         = phase or 1,
                                enabled       = entry.enabled,
                                ReloeReminder = ReloeReminder,
                                id            = entry.id,
                            })
                        end
                    end
                end
                table.sort(alerts, function(a, b)
                    if a.enabled ~= b.enabled then return a.enabled end -- display disabled at the bottom
                    if a.ReloeReminder ~= b.ReloeReminder then return b.ReloeReminder end -- display self-created reminders first
                    if a.phase ~= b.phase then return a.phase < b.phase end
                    local aID = a.entry.id
                    local bID = b.entry.id
                    if aID and bID then return aID < bID end
                    if aID or bID then return aID ~= nil end
                    local an = a.entry.name or a.entry.text or a.key
                    local bn = b.entry.name or b.entry.text or b.key
                    return an < bn
                end)
                for _, item in ipairs(alerts) do
                    local displayName = ReloeAlertName(item.entry)
                    if searchText == "" or string.find(string.lower(displayName), string.lower(searchText), 1, true) then
                        table.insert(t, {
                            encID           = encID,
                            diffID          = item.diffID,
                            alertKey        = item.key,
                            entry           = item.entry,
                            _isReloeCreated = true,
                        })
                    end
                end
            end
        end

        -- Custom alerts below
        local diffAlerts = NSRT.CustomBossAlerts and NSRT.CustomBossAlerts[filterDiffID] or {}
        for i, alert in ipairs(diffAlerts) do
            if not filterEncID or alert.encID == filterEncID then
                local name = alert.name or "Unnamed"
                if searchText == "" or string.find(string.lower(name), string.lower(searchText), 1, true) then
                    table.insert(t, { alert = alert, realIndex = i })
                end
            end
        end
        return t
    end

    local function RebuildList()
        local data = RebuildScrollData()

        for i = 1, MAX_LIST_ROWS do
            local row   = listRows[i]
            local entry = data[i]

            if not entry then
                row:Hide()
            else
                row:Show()

                local isReloe   = entry._isReloeCreated
                local isEnabled, icon, name

                if filterEncID == nil or filterEncID == 0 then
                    icon = BossData.BossIcons[entry.encID]
                else
                    local spell = entry.entry.spellID and C_Spell.GetSpellInfo(entry.entry.spellID)
                    if entry.entry.customIcon then
                        icon = entry.entry.customIcon
                    elseif spell then
                        icon = spell.iconID
                    else
                        icon = BossData.BossIcons[entry.encID]
                    end
                end

                if isReloe then
                    isEnabled = entry.entry.enabled
                    name      = ReloeAlertName(entry.entry)
                else
                    local alert = entry.alert
                    isEnabled   = alert.enabled
                    name        = alert.name or "Unnamed"
                end

                -- Selected highlight
                local isSelected = isReloe
                    and (selectedReloeEncID == entry.encID and selectedReloeDiffID == entry.diffID and selectedReloeKey == entry.alertKey)
                    or  (not isReloe and selectedIndex == entry.realIndex)
                if isSelected then
                    row.__background:SetVertexColor(0, 1, 1)
                    row.__background:SetAlpha(1)
                else
                    row.__background:SetVertexColor(0.4, 0.4, 0.4)
                    row.__background:SetAlpha(0.5)
                end
                if icon then
                    row.bossIcon:SetTexture(icon)
                    row.bossIcon:Show()
                else
                    row.bossIcon:SetTexture(nil)
                    row.bossIcon:Hide()
                end
                row.nameLabel:SetPoint("LEFT", row.bossIcon, "RIGHT", 4, 0)

                row.nameLabel:SetText(name)
                row.nameLabel:SetTextColor(1, 1, 1, isEnabled and 1 or 0.45)

                -- Enabled checkbox: sync state then wire handler
                row.enabledCB:SetValue(isEnabled)

                if isReloe then
                    local eid, did, akey = entry.encID, entry.diffID, entry.alertKey
                    row.enabledCB:SetOnChange(function(v)
                        local e = NSRT.EncounterAlerts and NSRT.EncounterAlerts[eid]
                                   and NSRT.EncounterAlerts[eid][did]
                                   and NSRT.EncounterAlerts[eid][did][akey]
                        if e then
                            e.enabled = v
                            if selectedReloeEncID == eid and selectedReloeDiffID == did and selectedReloeKey == akey then
                                enabledCB:SetValue(v)
                            end
                        end
                    end)
                else
                    local alert = entry.alert
                    local ri    = entry.realIndex
                    row.enabledCB:SetOnChange(function(v)
                        alert.enabled = v
                        if selectedIndex == ri then
                            enabledCB:SetValue(v)
                        end
                    end)
                end

                -- Delete button: hidden for reloeCreated rows
                if isReloe then
                    row.deleteBtn:Hide()
                    row.deleteBtn:SetScript("OnClick", nil)
                    row.lockIcon:Show()
                else
                    row.lockIcon:Hide()
                    row.deleteBtn:Show()
                    local ri = entry.realIndex
                    row.deleteBtn:SetScript("OnClick", function()
                        local deleteFunc = function()
                            local alerts = NSRT.CustomBossAlerts and NSRT.CustomBossAlerts[filterDiffID]
                            if alerts then table.remove(alerts, ri) end
                            if selectedIndex == ri then
                                selectedIndex = nil
                                if rightPanel then rightPanel:Hide() end
                            elseif selectedIndex and selectedIndex > ri then
                                selectedIndex = selectedIndex - 1
                            end
                            RebuildList()
                        end

                        local deleteDialog = NSI.UI.Components.CreateDialog("NSRTDeleteAlertConfirm" .. ri,
                            "Delete Alert", "Are you sure you want to delete this alert?", "Cancel", nil, "Delete", deleteFunc,
                            nil)
                        deleteDialog:Show()
                    end)
                end

                -- Click to select (skip when clicking the enabled checkbox)
                if isReloe then
                    local eid, did, akey = entry.encID, entry.diffID, entry.alertKey
                    row:SetScript("OnMouseDown", function(self, button)
                        if row.enabledCB.frame:IsMouseOver() then return end
                        if button == "RightButton" then
                            local data = NSRT.EncounterAlerts and NSRT.EncounterAlerts[eid]
                                     and NSRT.EncounterAlerts[eid][did]
                                     and NSRT.EncounterAlerts[eid][did][akey]
                            local name = data and (data.name or data.text or akey) or akey
                            ShowContextMenu({
                                { type = "button", label = "Export Alert", fnc = function()
                                    local str = NSI:ExportSingleAlertString("encounter", eid, did, akey, data)
                                    ShowExportPopup(str, name)
                                end },
                            })
                        else
                            SelectReloeCreatedAlert(eid, did, akey)
                        end
                    end)
                else
                    local ri = entry.realIndex
                    row:SetScript("OnMouseDown", function(self, button)
                        if row.enabledCB.frame:IsMouseOver() then return end
                        if button == "RightButton" then
                            local alert = NSRT.CustomBossAlerts and NSRT.CustomBossAlerts[filterDiffID]
                                      and NSRT.CustomBossAlerts[filterDiffID][ri]
                            local name = alert and (alert.name or "Unnamed") or "Unnamed"
                            ShowContextMenu({
                                { type = "button", label = "Export Alert", fnc = function()
                                    local str = NSI:ExportSingleAlertString("custom", nil, filterDiffID, nil, alert)
                                    ShowExportPopup(str, name)
                                end },
                            })
                        else
                            SelectAlert(ri)
                        end
                    end)
                end
            end
        end

        local totalH = math.max(#data * lineHeight, 1)
        listChild:SetHeight(totalH)
        local bar = _G["NSUIEncAlertListScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, totalH - listScroll:GetHeight())
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end
    end

    screen.RebuildList = RebuildList

    -- Create Alert button
    local createBtn = CreateButton(screen, "+ Create Alert", function()
        NSRT.CustomBossAlerts = NSRT.CustomBossAlerts or {}
        NSRT.CustomBossAlerts[filterDiffID] = NSRT.CustomBossAlerts[filterDiffID] or {}
        local diffAlerts = NSRT.CustomBossAlerts[filterDiffID]
        table.insert(diffAlerts, {
            name          = "New Alert",
            enabled       = true,
            encID         = filterEncID,
            phase         = 1,
            times         = {},
            Type          = "Text",
            text          = "",
            spellID       = nil,
            dur           = 8,
            TTSEnabled    = false,
            TTSText       = "",
            TTSTimer      = 8,
            countdown     = false,
            loadClass     = nil,
            loadSpec      = nil,
            loadCharacter = nil,
        })
        RebuildList()
        SelectAlert(#diffAlerts)
    end, listW, 22)
    createBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, pad)

    -- Import / Export buttons (row above create)
    local halfW = math.floor((listW - 4) / 2)
    local ioY   = pad + 22 + 4

    local importAlertsBtn = CreateButton(screen, "Import", function()
        ShowImportPopup()
    end, halfW, 22)
    importAlertsBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, ioY)

    local exportAlertsBtn = CreateButton(screen, "Export", function()
        local str = NSI:ExportAlertsString()
        ShowExportPopup(str, "All encounter alerts")
    end, halfW, 22)
    exportAlertsBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad + halfW + 4, ioY)

    -- ================================================================
    -- Right Panel
    -- ================================================================
    rightPanel = CreateFrame("Frame", nil, screen)
    rightPanel:SetPoint("TOPLEFT",     screen, "TOPLEFT",     rightX, topY)
    rightPanel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -pad,   pad)
    rightPanel:Hide()

    -- ── Header: name entry + enabled checkbox ────────────────────────────────
    local nameLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    nameLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 11, "")
    nameLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    nameLbl:SetText("Alert Name")
    nameLbl:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)

    local nameEntry = CreateTextEntry(rightPanel, nil, nil, nil, rightW - 110, 22,
        nil, nil, nil, "NSUIEncAlertNameEntry")
    nameEntry:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -14)

    enabledCB = CreateCheckButton(rightPanel, "Enabled",
        function() return false end, nil, 90, 22, "NSUIEncAlertEnabled")
    enabledCB:SetPoint("LEFT", nameEntry.frame, "RIGHT", 8, 0)

    -- ── Inner tab bar ────────────────────────────────────────────────────────
    local INNER_TABS     = { "Display", "Trigger", "Sound", "Load", "Options" }
    local innerTabBtns   = {}
    local innerTabFrames = {}
    local activeInnerTab = "Display"

    local function SelectInnerTab(name)
        activeInnerTab = name
        for _, tn in ipairs(INNER_TABS) do
            innerTabFrames[tn]:SetShown(tn == name)
            if tn == name then innerTabBtns[tn]:Select()
            else               innerTabBtns[tn]:Deselect() end
        end
    end

    local tabBtnW   = 84
    local tabBtnGap = 3
    local tabRowY   = -42

    for i, tabName in ipairs(INNER_TABS) do
        local btn = CreateSubButton(rightPanel, tabName, function()
            SelectInnerTab(tabName)
        end, tabBtnW, "NSUIEncAlertInnerTab_" .. tabName)
        btn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", (i - 1) * (tabBtnW + tabBtnGap), tabRowY)
        innerTabBtns[tabName] = btn
    end
    innerTabBtns["Options"].frame:Hide()

    -- ── Preview button — right-aligned on the tab row ────────────────────────
    local previewBtn = CreateButton(rightPanel, "Preview", function() PreviewAlert() end, 80, 18,
        "NSUIEncAlertPreview")
    previewBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY)

    -- Separator below tabs
    local tabSep = rightPanel:CreateTexture(nil, "ARTWORK")
    tabSep:SetColorTexture(0, 1, 1, 0.20)
    tabSep:SetHeight(1)
    tabSep:SetPoint("TOPLEFT",  rightPanel, "TOPLEFT",  0, tabRowY - 20)
    tabSep:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY - 20)

    local contentY = tabRowY - 26   -- -68

    for _, tabName in ipairs(INNER_TABS) do
        local f = CreateFrame("Frame", nil, rightPanel)
        f:SetPoint("TOPLEFT",     rightPanel, "TOPLEFT",     0, contentY)
        f:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)
        f:Hide()
        innerTabFrames[tabName] = f
    end

    -- ================================================================
    -- Helper: build a lock overlay for a tab frame
    -- ================================================================
    local function MakeLockOverlay(parent, message)
        local ov = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        ov:SetAllPoints(parent)
        ov:SetFrameLevel(parent:GetFrameLevel() + 10)
        DF:ApplyStandardBackdrop(ov)
        ov.__background:SetVertexColor(0.02, 0.02, 0.02)
        ov.__background:SetAlpha(0.82)

        local lbl = ov:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "")
        lbl:SetTextColor(0.55, 0.55, 0.55, 1)
        lbl:SetText(message)
        lbl:SetPoint("CENTER", ov, "CENTER", 0, 0)
        lbl:SetJustifyH("CENTER")

        ov:Hide()
        return ov
    end

    -- ================================================================
    -- DISPLAY TAB
    -- ================================================================
    local dispF = innerTabFrames["Display"]

    local dispHint = dispF:CreateFontString(nil, "OVERLAY")
    dispHint:Hide()

    local typeLbl = dispF:CreateFontString(nil, "OVERLAY")
    typeLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    typeLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    typeLbl:SetText("Type")
    typeLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -2)

    local TYPES    = { "Text", "Bar", "Icon", "Circle" }
    local typeBtns = {}
    local typeBtnW = 70

    local function SetDisplayType(t)
        for _, tn in ipairs(TYPES) do
            if tn == t then typeBtns[tn]:Select() else typeBtns[tn]:Deselect() end
        end
    end
    dispF.SetDisplayType = SetDisplayType

    for i, tn in ipairs(TYPES) do
        local tb = CreateSubButton(dispF, tn, function()
            SetDisplayType(tn)
            if dispF._alert then dispF._alert.DisplayType = tn end
        end, typeBtnW, "NSUIEncAlertType_" .. tn)
        tb:SetPoint("TOPLEFT", dispF, "TOPLEFT", (i - 1) * (typeBtnW + 3), -18)
        typeBtns[tn] = tb
    end

    local textLbl = dispF:CreateFontString(nil, "OVERLAY")
    textLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    textLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    textLbl:SetText("Display Text")
    textLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -46)

    local textEntry = CreateTextEntry(dispF, nil, nil, nil, rightW, 22,
        nil, nil, nil, "NSUIEncAlertDisplayText")
    textEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -62)
    local function SaveDispText(self)
        local v = self:GetText()
        if dispF._alert then dispF._alert.text = v end
    end
    textEntry.editBox:SetScript("OnEnterPressed", function(self) SaveDispText(self); self:ClearFocus() end)
    textEntry.editBox:SetScript("OnEditFocusLost", SaveDispText)
    dispF.textEntry = textEntry

    local spellLbl = dispF:CreateFontString(nil, "OVERLAY")
    spellLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    spellLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    spellLbl:SetText("Spell ID  (optional — drives bar / icon texture)")
    spellLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -94)

    local spellEntry = CreateTextEntry(dispF, nil, nil, nil, 130, 22,
        nil, nil, nil, "NSUIEncAlertSpellID")
    spellEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -110)
    local function SaveSpellID(self)
        local v = tonumber(self:GetText()) or nil
        if dispF._alert then dispF._alert.spellID = v end
    end
    spellEntry.editBox:SetScript("OnEnterPressed", function(self) SaveSpellID(self); self:ClearFocus() end)
    spellEntry.editBox:SetScript("OnEditFocusLost", SaveSpellID)
    dispF.spellEntry = spellEntry

    local durLbl = dispF:CreateFontString(nil, "OVERLAY")
    durLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    durLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    durLbl:SetText("Duration  (seconds the alert is visible)")
    durLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -142)

    local durEntry = CreateTextEntry(dispF, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertDuration")
    durEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -158)
    local function SaveDur(self)
        local v = tonumber(self:GetText())
        if dispF._alert then dispF._alert.dur = v or 8 end
    end
    durEntry.editBox:SetScript("OnEnterPressed", function(self) SaveDur(self); self:ClearFocus() end)
    durEntry.editBox:SetScript("OnEditFocusLost", SaveDur)
    dispF.durEntry = durEntry

    -- ── glowunit ────────────────────────────────────────────────────────
    local glowunitLbl = dispF:CreateFontString(nil, "OVERLAY")
    glowunitLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    glowunitLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    glowunitLbl:SetText("Glow Unit  (unit token, e.g. player, focus)")
    glowunitLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -190)

    local glowunitEntry = CreateTextEntry(dispF, nil, nil, nil, 200, 22,
        nil, nil, nil, "NSUIEncAlertGlowUnit")
    glowunitEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -206)
    local function SaveGlowUnit(self)
        local v = self:GetText()
        if dispF._alert then dispF._alert.glowunit = (v ~= "") and v or nil end
    end
    glowunitEntry.editBox:SetScript("OnEnterPressed", function(self) SaveGlowUnit(self); self:ClearFocus() end)
    glowunitEntry.editBox:SetScript("OnEditFocusLost", SaveGlowUnit)
    dispF.glowunitEntry = glowunitEntry

    -- ── colors ──────────────────────────────────────────────────────────
    local colorsPicker = CreateColorPicker(dispF, "Color",
        function()
            local c = dispF._alert and dispF._alert.colors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return 1, 1, 1, 1
        end,
        function(r, g, b, a)
            if dispF._alert then dispF._alert.colors = {r, g, b, a} end
        end,
        200, 22, "NSUIEncAlertColors")
    colorsPicker:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -240)
    dispF.colorsPicker = colorsPicker

    -- ── Bars section: Ticks (shown only when display type = "Bar") ───────
    local barsSection = CreateFrame("Frame", nil, dispF)
    barsSection:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -278)
    barsSection:SetSize(rightW, 200)
    barsSection:Hide()

    local ticksLbl = barsSection:CreateFontString(nil, "OVERLAY")
    ticksLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    ticksLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    ticksLbl:SetText("Ticks  (bar percentage markers)")
    ticksLbl:SetPoint("TOPLEFT", barsSection, "TOPLEFT", 0, 0)

    local ticksListH = 120
    local ticksListW = rightW - 20

    local ticksScroll = CreateFrame("ScrollFrame", "NSUIEncAlertTicksScroll", barsSection,
        "UIPanelScrollFrameTemplate")
    ticksScroll:SetSize(ticksListW, ticksListH)
    ticksScroll:SetPoint("TOPLEFT", barsSection, "TOPLEFT", 0, -16)
    ReskinScrollbar(ticksScroll)

    local ticksChild = CreateFrame("Frame", nil, ticksScroll, "BackdropTemplate")
    ticksChild:SetSize(ticksListW - 18, 1)
    ticksChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    ticksChild:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
    ticksScroll:SetScrollChild(ticksChild)

    local tickRowH = 22
    local tickRows = {}

    local function RebuildTickRows()
        for _, row in ipairs(tickRows) do row:Hide() end
        tickRows = {}
        if not dispF._alert then return end
        local ticks = dispF._alert.Ticks or {}
        for i, v in ipairs(ticks) do
            local row = CreateFrame("Frame", nil, ticksChild)
            row:SetSize(ticksChild:GetWidth(), tickRowH)
            row:SetPoint("TOPLEFT", ticksChild, "TOPLEFT", 0, -(i - 1) * tickRowH)

            if i % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, 0.03)
            end

            local tLbl = row:CreateFontString(nil, "OVERLAY")
            tLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "")
            tLbl:SetTextColor(1, 1, 1, 1)
            tLbl:SetPoint("LEFT", row, "LEFT", 8, 0)
            tLbl:SetText(tostring(v))

            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetSize(14, 14)
            delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
            delBtn:GetNormalTexture():SetDesaturated(true)
            delBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
            local ri = i
            delBtn:SetScript("OnClick", function()
                if dispF._alert then
                    table.remove(dispF._alert.Ticks, ri)
                    RebuildTickRows()
                end
            end)

            tickRows[i] = row
        end

        local totalH = math.max(#ticks * tickRowH, 1)
        ticksChild:SetHeight(totalH)
        local bar = _G["NSUIEncAlertTicksScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, totalH - ticksListH)
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end
    end
    dispF.RebuildTickRows = RebuildTickRows

    local addTickLbl = barsSection:CreateFontString(nil, "OVERLAY")
    addTickLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 11, "")
    addTickLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    addTickLbl:SetText("Add tick")
    addTickLbl:SetPoint("TOPLEFT", ticksScroll, "BOTTOMLEFT", 0, -4)

    local addTickEntry = CreateTextEntry(barsSection, nil, nil, nil, 90, 22,
        nil, nil, nil, "NSUIEncAlertAddTick")
    addTickEntry:SetPoint("TOPLEFT", ticksScroll, "BOTTOMLEFT", 0, -20)

    local function DoAddTick()
        local v = tonumber(addTickEntry:GetValue())
        if v and dispF._alert then
            dispF._alert.Ticks = dispF._alert.Ticks or {}
            local inserted = false
            for i2, existing in ipairs(dispF._alert.Ticks) do
                if v < existing then
                    table.insert(dispF._alert.Ticks, i2, v)
                    inserted = true
                    break
                end
            end
            if not inserted then table.insert(dispF._alert.Ticks, v) end
            addTickEntry:SetValue("")
            RebuildTickRows()
        end
    end

    addTickEntry.editBox:SetScript("OnEnterPressed", function(self)
        DoAddTick()
        self:ClearFocus()
    end)

    local addTickBtn = CreateSubButton(barsSection, "Add", DoAddTick, 54,
        "NSUIEncAlertAddTickBtn")
    addTickBtn:SetPoint("LEFT", addTickEntry.frame, "RIGHT", 6, 0)

    -- Patch SetDisplayType to also toggle barsSection visibility
    local _prevSetDisplayType = SetDisplayType
    SetDisplayType = function(t)
        _prevSetDisplayType(t)
        barsSection:SetShown(t == "Bar")
    end
    dispF.SetDisplayType = SetDisplayType

    -- ================================================================
    -- TRIGGER TAB
    -- ================================================================
    local trigF = innerTabFrames["Trigger"]

    local trigBossLbl = trigF:CreateFontString(nil, "OVERLAY")
    trigBossLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    trigBossLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    trigBossLbl:SetText("Boss")
    trigBossLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -2)

    local function BuildTrigBossOptions()
        return BossData.BuildBossDropdownOptions(function(v)
            if trigF._alert then
                trigF._alert.encID = v
                RebuildList()
            end
        end, "Any Boss")
    end

    local function getTrigBossSelected()
        if not trigF._alert or not trigF._alert.encID then return "Any Boss" end
        for _, opt in ipairs(BossData.BuildBossDropdownOptions(nil, false)) do
            if opt.value == trigF._alert.encID then return opt.label end
        end
        return tostring(trigF._alert.encID)
    end

    local trigBossDD = CreateDropdown(trigF, nil, BuildTrigBossOptions, getTrigBossSelected,
        200, 22, "NSUIEncAlertTrigBoss")
    trigBossDD:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -18)
    trigF.bossDD = trigBossDD

    -- Difficulty dropdown — moves the alert to a different diff table on change
    local TRIG_DIFF_NAMES = { [14] = "Normal", [15] = "Heroic", [16] = "Mythic" }

    local trigDiffLbl = trigF:CreateFontString(nil, "OVERLAY")
    trigDiffLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    trigDiffLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    trigDiffLbl:SetText("Difficulty")
    trigDiffLbl:SetPoint("TOPLEFT", trigBossDD.frame, "TOPRIGHT", 6, 16)

    local function BuildTrigDiffOptions()
        local opts = {}
        for _, diffID in ipairs({ 14, 15, 16 }) do
            local id = diffID
            opts[#opts + 1] = {
                label = TRIG_DIFF_NAMES[id],
                value = id,
                onclick = function(_, _, val)
                    if not trigF._alert or val == filterDiffID then return end
                    local alerts = NSRT.CustomBossAlerts and NSRT.CustomBossAlerts[filterDiffID]
                    if not alerts then return end
                    local alertToMove = trigF._alert
                    local foundIdx
                    for i, a in ipairs(alerts) do
                        if a == alertToMove then foundIdx = i; break end
                    end
                    if not foundIdx then return end
                    table.remove(alerts, foundIdx)
                    alertToMove.id = NSI.EncounterAlerts:GenerateAlertID()
                    NSRT.CustomBossAlerts[val] = NSRT.CustomBossAlerts[val] or {}
                    table.insert(NSRT.CustomBossAlerts[val], alertToMove)
                    filterDiffID = val
                    selectedIndex = #NSRT.CustomBossAlerts[val]
                    diffDD:Refresh()
                    RebuildList()
                end,
            }
        end
        return opts
    end

    local function getTrigDiffSelected()
        return TRIG_DIFF_NAMES[filterDiffID] or tostring(filterDiffID)
    end

    local trigDiffDD = CreateDropdown(trigF, nil, BuildTrigDiffOptions, getTrigDiffSelected,
        90, 22, "NSUIEncAlertTrigDiff")
    trigDiffDD:SetPoint("TOPLEFT", trigBossDD.frame, "TOPRIGHT", 6, 0)
    trigF.trigDiffDD = trigDiffDD

    local phaseLbl = trigF:CreateFontString(nil, "OVERLAY")
    phaseLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    phaseLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    phaseLbl:SetText("Phase")
    phaseLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -50)

    local phaseEntry = CreateTextEntry(trigF, nil, nil, nil, 60, 22,
        nil, nil, nil, "NSUIEncAlertPhase")
    phaseEntry:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -66)
    phaseEntry.editBox:SetScript("OnEnterPressed", function(self)
        if trigF._alert then
            trigF._alert.phase = math.max(1, math.floor(tonumber(self:GetText()) or 1))
        end
        self:ClearFocus()
    end)
    phaseEntry.editBox:SetScript("OnEditFocusLost", function(self)
        if trigF._alert then
            trigF._alert.phase = math.max(1, math.floor(tonumber(self:GetText()) or 1))
        end
    end)
    trigF.phaseEntry = phaseEntry

    local timesLbl = trigF:CreateFontString(nil, "OVERLAY")
    timesLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    timesLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    timesLbl:SetText("Trigger Times  (seconds into phase)")
    timesLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -98)

    -- Times list: native ScrollFrame
    local timesListH = 150
    local timesListW = rightW - 20

    local timesScroll = CreateFrame("ScrollFrame", "NSUIEncAlertTimesScroll", trigF,
        "UIPanelScrollFrameTemplate")
    timesScroll:SetSize(timesListW, timesListH)
    timesScroll:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -114)
    ReskinScrollbar(timesScroll)

    local timesChild = CreateFrame("Frame", nil, timesScroll, "BackdropTemplate")
    timesChild:SetSize(timesListW - 18, 1)
    timesChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    timesChild:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
    timesScroll:SetScrollChild(timesChild)

    local timeRowH  = 22
    local timeRows  = {}

    local function RebuildTimeRows()
        for _, row in ipairs(timeRows) do row:Hide() end
        timeRows = {}
        if not trigF._alert then return end
        local times = trigF._alert.times or {}
        for i, t in ipairs(times) do
            local row = CreateFrame("Frame", nil, timesChild)
            row:SetSize(timesChild:GetWidth(), timeRowH)
            row:SetPoint("TOPLEFT", timesChild, "TOPLEFT", 0, -(i - 1) * timeRowH)

            if i % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, 0.03)
            end

            local tLbl = row:CreateFontString(nil, "OVERLAY")
            tLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "")
            tLbl:SetTextColor(1, 1, 1, 1)
            tLbl:SetPoint("LEFT", row, "LEFT", 8, 0)
            tLbl:SetText(string.format("%.2f s", t))

            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetSize(14, 14)
            delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
            delBtn:GetNormalTexture():SetDesaturated(true)
            delBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
            local ri = i
            delBtn:SetScript("OnClick", function()
                if trigF._alert then
                    table.remove(trigF._alert.times, ri)
                    RebuildTimeRows()
                end
            end)

            timeRows[i] = row
        end

        local totalH = math.max(#times * timeRowH, 1)
        timesChild:SetHeight(totalH)
        local bar = _G["NSUIEncAlertTimesScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, totalH - timesListH)
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end
    end
    trigF.RebuildTimeRows = RebuildTimeRows

    local addTimeLbl = trigF:CreateFontString(nil, "OVERLAY")
    addTimeLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 11, "")
    addTimeLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    addTimeLbl:SetText("Add time (s)")
    addTimeLbl:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -4)

    local addTimeEntry = CreateTextEntry(trigF, nil, nil, nil, 90, 22,
        nil, nil, nil, "NSUIEncAlertAddTime")
    addTimeEntry:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -20)
    trigF.addTimeEntry = addTimeEntry

    local function DoAddTime()
        local v = tonumber(addTimeEntry:GetValue())
        if v and trigF._alert then
            trigF._alert.times = trigF._alert.times or {}
            local inserted = false
            for i2, existing in ipairs(trigF._alert.times) do
                if v < existing then
                    table.insert(trigF._alert.times, i2, v)
                    inserted = true
                    break
                end
            end
            if not inserted then table.insert(trigF._alert.times, v) end
            addTimeEntry:SetValue("")
            RebuildTimeRows()
        end
    end

    addTimeEntry.editBox:SetScript("OnEnterPressed", function(self)
        DoAddTime()
        self:ClearFocus()
    end)

    local addTimeBtn = CreateSubButton(trigF, "Add", DoAddTime, 54,
        "NSUIEncAlertAddTimeBtn")
    addTimeBtn:SetPoint("LEFT", addTimeEntry.frame, "RIGHT", 6, 0)

    -- Lock overlay for Trigger tab (shown when hardcoded boss is selected)
    trigF.lockOverlay = MakeLockOverlay(trigF,
        "Trigger timing is defined in code\nand cannot be edited here.")

    -- ================================================================
    -- SOUND TAB
    -- ================================================================
    local sndF = innerTabFrames["Sound"]

    local sndHint = sndF:CreateFontString(nil, "OVERLAY")
    sndHint:Hide()

    local ttsCB = CreateCheckButton(sndF, "Enable Text-to-Speech",
        function() return false end,
        function(v)
            if not sndF._alert then return end
            if sndF._reloeMode then
                local txt = sndF.ttsTextEntry and sndF.ttsTextEntry:GetValue() or ""
                sndF._alert.TTS = v and ((txt ~= "") and txt or true) or false
            else
                sndF._alert.TTSEnabled = v
            end
        end,
        rightW, 22, "NSUIEncAlertTTSCB")
    ttsCB:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -4)
    sndF.ttsCB = ttsCB

    local ttsTextLbl = sndF:CreateFontString(nil, "OVERLAY")
    ttsTextLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    ttsTextLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    ttsTextLbl:SetText("TTS Text  (leave blank to speak the Display Text)")
    ttsTextLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -34)

    local ttsTextEntry = CreateTextEntry(sndF, nil, nil, nil, rightW, 22,
        nil, nil, nil, "NSUIEncAlertTTSText")
    ttsTextEntry:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -50)
    local function SaveTTSText(self)
        local v = self:GetText()
        if not sndF._alert then return end
        if sndF._reloeMode then
            if sndF._alert.TTS ~= false then
                sndF._alert.TTS = (v ~= "") and v or true
            end
        else
            sndF._alert.TTSText = v
        end
    end
    ttsTextEntry.editBox:SetScript("OnEnterPressed", function(self) SaveTTSText(self); self:ClearFocus() end)
    ttsTextEntry.editBox:SetScript("OnEditFocusLost", SaveTTSText)
    sndF.ttsTextEntry = ttsTextEntry

    local ttsTimerLbl = sndF:CreateFontString(nil, "OVERLAY")
    ttsTimerLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    ttsTimerLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    ttsTimerLbl:SetText("TTS Timer  (seconds — when TTS fires, on the same timeline as trigger time)")
    ttsTimerLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -82)

    local ttsTimerEntry = CreateTextEntry(sndF, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertTTSTimer")
    ttsTimerEntry:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -98)
    local function SaveTTSTimer(self)
        local v = tonumber(self:GetText())
        if sndF._alert then sndF._alert.TTSTimer = v or 8 end
    end
    ttsTimerEntry.editBox:SetScript("OnEnterPressed", function(self) SaveTTSTimer(self); self:ClearFocus() end)
    ttsTimerEntry.editBox:SetScript("OnEditFocusLost", SaveTTSTimer)
    sndF.ttsTimerEntry = ttsTimerEntry

    local cdCB = CreateCheckButton(sndF, "Countdown for",
        function() return false end,
        function(v)
            if sndF._alert then
                local n = sndF.cdEntry and tonumber(sndF.cdEntry:GetValue()) or 5
                sndF._alert.countdown = v and (n or 5) or false
            end
        end,
        130, 22, "NSUIEncAlertCDCB")
    cdCB:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -130)
    sndF.cdCB = cdCB

    local cdEntry = CreateTextEntry(sndF, nil, nil, nil, 60, 22,
        nil, nil, nil, "NSUIEncAlertCountdown")
    cdEntry:SetPoint("LEFT", cdCB.frame, "RIGHT", 6, 0)
    cdEntry:SetPoint("TOP",  cdCB.frame, "TOP", 0, 0)
    local function SaveCountdown(self)
        local v = tonumber(self:GetText())
        if sndF._alert then sndF._alert.countdown = (v and v > 0) and v or false end
    end
    cdEntry.editBox:SetScript("OnEnterPressed", function(self) SaveCountdown(self); self:ClearFocus() end)
    cdEntry.editBox:SetScript("OnEditFocusLost", SaveCountdown)
    sndF.cdEntry = cdEntry

    local cdSecLbl = sndF:CreateFontString(nil, "OVERLAY")
    cdSecLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    cdSecLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    cdSecLbl:SetText("seconds")
    cdSecLbl:SetPoint("LEFT", cdEntry.frame, "RIGHT", 5, 0)

    local sndFileLbl = sndF:CreateFontString(nil, "OVERLAY")
    sndFileLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    sndFileLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    sndFileLbl:SetText("Sound File")
    sndFileLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -162)

    local soundGetItems, soundGetSelected = NSI:BuildSoundDropdown(
        function() return sndF._alert and sndF._alert.sound end,
        function(v) if sndF._alert then sndF._alert.sound = v end end
    )
    local soundDD = CreateDropdown(sndF, nil, soundGetItems, soundGetSelected,
        rightW, 22, "NSUIEncAlertSound")
    soundDD:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -178)
    sndF.soundDD = soundDD

    -- ================================================================
    -- LOAD TAB
    -- ================================================================
    local loadF = innerTabFrames["Load"]

    local classLbl = loadF:CreateFontString(nil, "OVERLAY")
    classLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    classLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    classLbl:SetText("Class")
    classLbl:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -2)

    local classGetItems, classGetSelected = NSI:BuildClassDropdown(
        function() return loadF._alert and loadF._alert.loadClass end,
        function(v)
            if loadF._alert then loadF._alert.loadClass = v end
            loadF.specDD:Refresh()
        end
    )
    local classDD = CreateDropdown(loadF, nil, classGetItems, classGetSelected,
        180, 22, "NSUIEncAlertClass")
    classDD:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -18)
    loadF.classDD = classDD

    local specLbl = loadF:CreateFontString(nil, "OVERLAY")
    specLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    specLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    specLbl:SetText("Spec")
    specLbl:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -50)

    local specGetItems, specGetSelected = NSI:BuildSpecDropdown(
        function() return loadF._alert and loadF._alert.loadClass end,
        function() return loadF._alert and loadF._alert.loadSpec end,
        function(v) if loadF._alert then loadF._alert.loadSpec = v end end
    )
    local specDD = CreateDropdown(loadF, nil, specGetItems, specGetSelected,
        180, 22, "NSUIEncAlertSpec")
    specDD:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -66)
    loadF.specDD = specDD

    local charLbl = loadF:CreateFontString(nil, "OVERLAY")
    charLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    charLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    charLbl:SetText("Character Name  (exact match — leave blank for all)")
    charLbl:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -98)

    local charEntry = CreateTextEntry(loadF, nil, nil, nil, 200, 22,
        nil, nil, nil, "NSUIEncAlertChar")
    charEntry:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -114)
    charEntry.editBox:SetScript("OnEnterPressed", function(self)
        if loadF._alert then
            local v = self:GetText()
            loadF._alert.loadCharacter = (v ~= "") and v or nil
        end
        self:ClearFocus()
    end)
    charEntry.editBox:SetScript("OnEditFocusLost", function(self)
        if loadF._alert then
            local v = self:GetText()
            loadF._alert.loadCharacter = (v ~= "") and v or nil
        end
    end)
    loadF.charEntry = charEntry

    -- Lock overlay for Load tab (reloeCreated alerts use built-in role field)
    loadF.lockOverlay = MakeLockOverlay(loadF,
        "Class / spec filters do not apply\nto addon-created alerts.")

    -- Lock overlay for Sound tab (reloeCreated alerts — sound is managed by the addon)
    sndF.lockOverlay = MakeLockOverlay(sndF,
        "Sound settings are fixed\nfor addon-created alerts.")

    -- ================================================================
    -- OPTIONS TAB
    -- ================================================================
    local optF = innerTabFrames["Options"]
    local optionsContentFrame = nil

    local function RebuildOptionsContent(entry)
        if optionsContentFrame then
            optionsContentFrame:Hide()
            optionsContentFrame = nil
        end
        if not (entry and entry.extraOptions) then return end
        local scrollObj = NSI.UI.Components.CreateScrollBox(optF, rightW - 11, optF:GetHeight())
        scrollObj.frame:SetPoint("TOPLEFT", optF, "TOPLEFT", 0, 0)
        local totalH = NSI.UI.Components.BuildWidgets(
            scrollObj.scrollChild, entry.extraOptions,
            scrollObj.scrollChild:GetWidth(), "NSRTEncOptContent")
        scrollObj.scrollChild:SetHeight(totalH)
        scrollObj:UpdateScrollBar()
        optionsContentFrame = scrollObj.frame
    end

    -- ================================================================
    -- Helper: set panel into custom-alert mode vs reloeCreated mode
    -- ================================================================
    local function SetCustomMode()
        trigF.lockOverlay:Hide()
        loadF.lockOverlay:Hide()
        sndF.lockOverlay:Hide()
        dispHint:Hide()
        sndHint:Hide()
        sndF._reloeMode = false
        nameEntry.editBox:SetEnabled(true)
        nameEntry.editBox:SetAlpha(1)
        innerTabBtns["Options"].frame:Hide()
        if activeInnerTab == "Options" then activeInnerTab = "Display" end
    end

    local function SetReloeCreatedMode()
        trigF.lockOverlay:Show()
        loadF.lockOverlay:Hide()
        sndF.lockOverlay:Hide()
        dispHint:Hide()
        sndHint:Hide()
        sndF._reloeMode = true
        nameEntry.editBox:SetEnabled(false)
        nameEntry.editBox:SetAlpha(0.45)
    end

    -- ================================================================
    -- PreviewAlert ── fire the current alert visually without a trigger
    -- ================================================================
    PreviewAlert = function()
        if not dispF._alert then return end
        if dispF._alert.Preview then -- allow custom preview functions
            dispF._alert:Preview()
            return
        end
        local info = NSI:CreateReminder(dispF._alert, true)
        NSI:HideAllReminders()
        NSI:DisplayReminder(info)
    end

    -- ================================================================
    -- SelectAlert ── load a custom alert into all right-panel controls
    -- ================================================================
    SelectAlert = function(index)
        selectedIndex        = index
        selectedReloeEncID   = nil
        selectedReloeKey     = nil
        local alert = NSRT.CustomBossAlerts and NSRT.CustomBossAlerts[filterDiffID] and NSRT.CustomBossAlerts[filterDiffID][index]
        if not alert then
            rightPanel:Hide()
            RebuildList()
            return
        end

        rightPanel:Show()
        SetCustomMode()

        dispF._alert = alert; dispF._hardcodedEncID = nil
        trigF._alert = alert; trigF._hardcodedEncID = nil
        sndF._alert  = alert; sndF._hardcodedEncID  = nil
        loadF._alert = alert; loadF._hardcodedEncID = nil

        -- Header
        nameEntry:SetValue(alert.name or "")
        enabledCB:SetValue(alert.enabled and true or false)

        nameEntry.editBox:SetScript("OnEnterPressed", function(self)
            alert.name = self:GetText()
            self:ClearFocus()
            RebuildList()
        end)
        nameEntry.editBox:SetScript("OnEditFocusLost", function(self)
            alert.name = self:GetText()
            RebuildList()
        end)
        enabledCB:SetOnChange(function(v)
            alert.enabled = v
            RebuildList()
        end)

        -- Display tab
        dispF.SetDisplayType(alert.DisplayType or "Text")
        dispF.textEntry:SetValue(alert.text or "")
        dispF.spellEntry:SetValue(alert.spellID and tostring(alert.spellID) or "")
        dispF.durEntry:SetValue(tostring(alert.dur or 8))
        dispF.glowunitEntry:SetValue(alert.glowunit or "")
        dispF.colorsPicker:Refresh()
        dispF.RebuildTickRows()

        -- Trigger tab
        trigF.bossDD:Refresh()
        trigF.trigDiffDD:Refresh()
        trigF.phaseEntry:SetValue(tostring(alert.phase or 1))
        trigF.RebuildTimeRows()

        -- Sound tab
        sndF.ttsCB:SetValue(alert.TTSEnabled and true or false)
        sndF.ttsTextEntry:SetValue(alert.TTSText or "")
        sndF.ttsTimerEntry:SetValue(tostring(alert.TTSTimer or 8))
        local hasCD = alert.countdown and alert.countdown ~= false
        sndF.cdCB:SetValue(hasCD and true or false)
        sndF.cdEntry:SetValue(hasCD and tostring(alert.countdown) or "")
        sndF.soundDD:Refresh()

        -- Load tab
        loadF.classDD:Refresh()
        loadF.specDD:Refresh()
        loadF.charEntry:SetValue(alert.loadCharacter or "")

        RebuildList()
        SelectInnerTab(activeInnerTab)
    end

    -- ================================================================
    -- SelectReloeCreatedAlert ── load an addon-created alert into the panel
    -- ================================================================
    SelectReloeCreatedAlert = function(encID, diffID, alertKey)
        selectedReloeEncID  = encID
        selectedReloeDiffID = diffID
        selectedReloeKey    = alertKey
        selectedIndex       = nil

        local entry = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
                      and NSRT.EncounterAlerts[encID][diffID]
                      and NSRT.EncounterAlerts[encID][diffID][alertKey]
        if not entry then
            rightPanel:Hide()
            RebuildList()
            return
        end

        rightPanel:Show()
        SetReloeCreatedMode()

        dispF._alert = entry; dispF._hardcodedEncID = nil
        trigF._alert = nil;   trigF._hardcodedEncID = nil
        sndF._alert  = entry; sndF._hardcodedEncID  = nil
        loadF._alert = nil;   loadF._hardcodedEncID = nil

        -- Header: alert name (read-only)
        nameEntry:SetValue(ReloeAlertName(entry))
        nameEntry.editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        nameEntry.editBox:SetScript("OnEditFocusLost", function() end)

        enabledCB:SetValue(entry.enabled and true or false)
        enabledCB:SetOnChange(function(v)
            entry.enabled = v
            RebuildList()
        end)

        -- Display tab: show stored values (editing locked by lock overlay)
        local dispType = entry.DisplayType
        dispF.SetDisplayType(dispType)
        dispF.textEntry:SetValue(entry.text or "")
        dispF.spellEntry:SetValue(entry.spellID and tostring(entry.spellID) or "")
        dispF.durEntry:SetValue(tostring(entry.dur or 8))
        dispF.glowunitEntry:SetValue(entry.glowunit or "")
        dispF.colorsPicker:Refresh()
        dispF.RebuildTickRows()

        -- Trigger tab: inert (lock overlay shown)
        trigF.trigDiffDD:Refresh()
        trigF.RebuildTimeRows()

        -- Sound tab
        local ttsActive = entry.TTS ~= false and entry.TTS ~= nil
        sndF.ttsCB:SetValue(ttsActive)
        sndF.ttsTextEntry:SetValue(type(entry.TTS) == "string" and entry.TTS or "")
        sndF.ttsTimerEntry:SetValue(tostring(entry.TTSTimer or entry.dur or 8))
        local hasCD = entry.countdown and entry.countdown ~= false
        sndF.cdCB:SetValue(hasCD and true or false)
        sndF.cdEntry:SetValue(hasCD and tostring(entry.countdown) or "")
        sndF.soundDD:Refresh()

        -- Options tab: show only when the entry defines extraOptions
        local hasOptions = entry.extraOptions ~= nil
        innerTabBtns["Options"].frame:SetShown(hasOptions)
        if hasOptions then
            RebuildOptionsContent(entry)
        else
            if activeInnerTab == "Options" then activeInnerTab = "Display" end
        end
        RebuildList()
        SelectInnerTab(activeInnerTab)
    end

    SelectInnerTab("Display")

    screen:SetScript("OnShow", function()
        RebuildList()
        if selectedReloeEncID and selectedReloeDiffID and selectedReloeKey then
            SelectReloeCreatedAlert(selectedReloeEncID, selectedReloeDiffID, selectedReloeKey)
        elseif selectedIndex then
            SelectAlert(selectedIndex)
        end
    end)

    return screen
end

-- ============================================================================
-- Export
-- ============================================================================
NSI.UI = NSI.UI or {}
NSI.UI.BossReminders = {
    BuildBossRemindersUI = BuildBossRemindersUI,
}
