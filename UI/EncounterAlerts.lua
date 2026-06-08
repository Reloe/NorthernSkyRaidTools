local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local Core                      = NSI.UI.Core
local NSUI                      = Core.NSUI
local content_width             = Core.content_width
local tab_content_height        = Core.tab_content_height

local CreateButton        = NSI.UI.Components.CreateButton
local CreateSubButton     = NSI.UI.Components.CreateSubButton
local CreateLocalizedButton = NSI.UI.Components.CreateLocalizedButton
local CreateLocalizedSubButton = NSI.UI.Components.CreateLocalizedSubButton
local CreateDropdown      = NSI.UI.Components.CreateDropdown
local CreateTextEntry     = NSI.UI.Components.CreateTextEntry
local CreateCheckButton   = NSI.UI.Components.CreateCheckButton
local CreateColorPicker   = NSI.UI.Components.CreateColorPicker
local ReskinScrollbar     = NSI.UI.Components.ReskinScrollbar
local ShowContextMenu     = NSI.UI.Components.ShowContextMenu
local CreateStyledFrame   = NSI.UI.Components.CreateFrame
local BossData          = NSI.UI.BossData

local function SetLocalizedText(object, key)
    NSI.UI.Components.RegisterLocalizedText(object, key)
end

local CIRCLE_TEXTURES = {
    {label="2 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_2px.png]]},
    {label="5 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_5px.png]]},
    {label="8 px",  value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_8px.png]]},
    {label="10 px", value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_10px.png]]},
    {label="15 px", value=[[Interface\AddOns\NorthernSkyRaidTools\Media\Textures\circle_15px.png]]},
}

local function GetCircleTextureLabel(texture)
    for _, option in ipairs(CIRCLE_TEXTURES) do
        if option.value == texture then return option.label end
    end
    return texture and tostring(texture) or ""
end

local function GetDefaultCircleTextureLabel()
    local texture = NSRT.ReminderSettings and NSRT.ReminderSettings.CircleSettings
        and NSRT.ReminderSettings.CircleSettings.Texture
    return NSI:Loc("Default") .. " (" .. GetCircleTextureLabel(texture) .. ")"
end




-- ============================================================================
-- Alert Export / Import popups
-- ============================================================================
local alertsExportPopup
local alertsImportPopup

function NSI:PromptReloeReminderImport(onImport)
    local function DoImport()
        self:ImportReloeReminders(nil, true)
        local enc = NSUI and NSUI.encounters_frame
        if enc and enc.RebuildList then enc.RebuildList() end
        if enc and enc.RefreshSelected then enc.RefreshSelected() end
        if onImport then onImport() end
    end
    local dialog = self.UI.Components.CreateDialog(
        "NSRTReloeReminderImport",
        NSI:Loc("Enable Reloe-Alerts"),
        NSI:Loc("Do you want to enable Reloe-Alerts now? If you made manual changes to an alert already this won't overwrite that."),
        NSI:Loc("Enable"), DoImport, NSI:Loc("Not Now"), nil)
    dialog:Show()
end

local function ShowExportPopup(str, label)
    if not alertsExportPopup then
        alertsExportPopup = DF:CreateSimplePanel(NSUI, 800, 400, "|cFF00FFFF" .. NSI:Loc("Export Alerts") .. "|r",
            "NSUIEncAlertExportString", { DontRightClickClose = true })
        alertsExportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        alertsExportPopup:SetFrameLevel(100)

        alertsExportPopup.infoLabel = alertsExportPopup:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(alertsExportPopup.infoLabel, 13, "")
        alertsExportPopup.infoLabel:SetTextColor(0.8, 0.8, 0.8, 1)
        alertsExportPopup.infoLabel:SetPoint("TOPLEFT", alertsExportPopup, "TOPLEFT", 10, -30)

        alertsExportPopup.textbox = DF:NewSpecialLuaEditorEntry(alertsExportPopup, 280, 80, nil,
            "EncAlertExportTextEdit", true, false, true)
        alertsExportPopup.textbox:SetPoint("TOPLEFT", alertsExportPopup, "TOPLEFT", 10, -50)
        alertsExportPopup.textbox:SetPoint("BOTTOMRIGHT", alertsExportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(alertsExportPopup.textbox)
        DF:ReskinSlider(alertsExportPopup.textbox.scroll)
        alertsExportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        NSI:SetUIFont(alertsExportPopup.textbox.editbox, 13, "OUTLINE")

        local doneBtn = CreateLocalizedButton(alertsExportPopup, "Done", function()
            alertsExportPopup:Hide()
        end, 280, 20)
        doneBtn:SetPoint("BOTTOM", alertsExportPopup, "BOTTOM", 0, 10)
    end

    alertsExportPopup.infoLabel:SetText(label or "")
    alertsExportPopup.textbox:SetText(str or "")
    alertsExportPopup.textbox:SetFocus()
    alertsExportPopup:Show()
end

local function ShowImportPopup()
    if not alertsImportPopup then
        alertsImportPopup = DF:CreateSimplePanel(NSUI, 800, 400, "|cFF00FFFF" .. NSI:Loc("Import Alerts") .. "|r",
            "NSUIEncAlertImportString", { DontRightClickClose = true })
        alertsImportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        alertsImportPopup:SetFrameLevel(100)

        local statusLabel = alertsImportPopup:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(statusLabel, 13, "")
        statusLabel:SetTextColor(0.8, 0.8, 0.8, 1)
        SetLocalizedText(statusLabel, "Paste an alerts export string below and click Import.")
        statusLabel:SetPoint("TOPLEFT", alertsImportPopup, "TOPLEFT", 10, -30)

        alertsImportPopup.textbox = DF:NewSpecialLuaEditorEntry(alertsImportPopup, 280, 80, nil,
            "EncAlertImportTextEdit", true, false, true)
        alertsImportPopup.textbox:SetPoint("TOPLEFT", alertsImportPopup, "TOPLEFT", 10, -50)
        alertsImportPopup.textbox:SetPoint("BOTTOMRIGHT", alertsImportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(alertsImportPopup.textbox)
        DF:ReskinSlider(alertsImportPopup.textbox.scroll)
        alertsImportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        NSI:SetUIFont(alertsImportPopup.textbox.editbox, 13, "OUTLINE")

        local importBtn = CreateLocalizedButton(alertsImportPopup, "Import", function()
            local str = alertsImportPopup.textbox:GetText()
            local count, overwriteCount = NSAPI:ImportAlertsString(str)
            if count then
                print("|cFF00FFFFNSRT:|r Imported " .. count .. " alert(s).")
                if overwriteCount and overwriteCount > 0 then
                    print("|cFFFFFF00NSRT:|r Overwritten " .. overwriteCount .. " alert(s).")
                end
                alertsImportPopup:Hide()
                local enc = NSUI.encounters_frame
                if enc and enc.RebuildList then enc.RebuildList() end
                if enc and enc.RefreshSelected then enc.RefreshSelected() end
            else
                statusLabel:SetText(
                    "|cFFFF0000" .. NSI:Loc("Invalid import string. Please check and try again.") .. "|r")
            end
        end, 280, 20)
        importBtn:SetPoint("BOTTOM", alertsImportPopup, "BOTTOM", 0, 10)

        alertsImportPopup:HookScript("OnShow", function()
            SetLocalizedText(statusLabel, "Paste an alerts export string below and click Import.")
            alertsImportPopup.textbox:SetText("")
            alertsImportPopup.textbox:SetFocus()
        end)
    end

    alertsImportPopup:Show()
    alertsImportPopup.textbox:SetFocus()
end

-- ============================================================================
-- BuildEncounterAlertsUI
-- ============================================================================
local function BuildEncounterAlertsUI(parentFrame)
    local screen = parentFrame

    -- ── Layout constants ────────────────────────────────────────────────────
    local leftWidth  = 240
    local pad        = 10
    local topY       = -10
    local lineHeight = 22
    local rightX     = leftWidth + pad * 2   -- 260
    local rightW     = content_width - rightX - pad  -- ~766

    -- ── Mutable state ───────────────────────────────────────────────────────
    local selectedEncID  = nil
    local selectedDiffID = nil
    local selectedKey   = nil
    local filterEncID        = nil
    local filterDiffID       = 16    -- default Mythic
    local searchText         = ""
    local groupsByEnc        = {}    -- [encID] = { [groupName] = true } — populated each RebuildScrollData
    local copiedAlertSection = nil

    function NSI:SaveAlertData(alert, dataKey, newData)
        if alert then
            alert[dataKey] = newData
            if selectedEncID and selectedDiffID and selectedKey then
                if not self._saveAlertDebounce then
                    self._saveAlertDebounce = true
                    local eid, did, key = selectedEncID, selectedDiffID, selectedKey
                    C_Timer.After(0, function()
                        self._saveAlertDebounce = false
                        self:FireCallback("NSRT_ALERT_CHANGED", eid, did, key)
                    end)
                end
            end
        end
    end

    -- forward declarations
    local rightPanel, SelectAlert, PreviewAlert, enabledCB, groupDD
    local copySectionBtn, applySectionBtn, previewBtn, tabSep, conditionHint
    local RebuildList, CanCopySection, ApplyCopiedSectionTo, SECTION_COPY_FIELDS, CopyValue

    -- ================================================================
    -- Left Panel ── title, filter, list, create button
    -- ================================================================
    local title = screen:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText(NSI:Loc("|cFF00FFFFEncounter|r Alerts"))

    -- ── Filter dropdown ─────────────────────────────────────────────────────
    local function BuildFilterOptions()
        local opts = {{ label = NSI:Loc("All Bosses"), value = 0, onclick = function()
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
        if not filterEncID then return NSI:Loc("All Bosses") end
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

    local searchHint = searchEntry.editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetText("|TInterface\\Common\\UI-Searchbox-Icon:16:16:0:-2|t  " .. NSI:Loc("Search..."))
    searchHint:SetPoint("LEFT", searchEntry.editBox, "LEFT", 2, 0)
    searchHint:SetTextColor(0.5, 0.5, 0.5, 0.6)
    NSI:SetUIFont(searchHint, 14, "")

    local function UpdateSearchHint(eb)
        searchHint:SetShown(eb:GetText() == "" and not eb:HasFocus())
    end

    searchEntry.editBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText()
        UpdateSearchHint(self)
        if screen.RebuildList then screen.RebuildList() end
    end)
    searchEntry.editBox:HookScript("OnEditFocusGained", function(self) UpdateSearchHint(self) end)
    searchEntry.editBox:HookScript("OnEditFocusLost",   function(self) UpdateSearchHint(self) end)

    -- ── Native ScrollFrame list ─────────────────────────────────────────────
    local scrollTop    = topY - 20 - 22 - 4 - 22 - 6   -- below title + filter row + search + gaps = -84
    local scrollHeight = tab_content_height + scrollTop - 18 - pad * 2 - 20 - 20 - 2  -- extra rows: import/export(18+2), additional-options(18+2)
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

    -- Dynamic row pools — rows are created on demand and reused across rebuilds
    local listRows        = {}
    local groupHeaderRows = {}

    local function CreateListRow()
        local row = CreateFrame("Frame", nil, listChild, "BackdropTemplate")
        row:SetSize(listChild:GetWidth(), lineHeight)
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
        NSI:SetUIFont(row.nameLabel, 13, "")
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

        -- Ungroup button: replaces delete/lock slot when the row is inside a group
        row.ungroupBtn = CreateFrame("Button", nil, row)
        row.ungroupBtn:SetSize(14, 14)
        row.ungroupBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.ungroupBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\minus.png]])
        row.ungroupBtn:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\minus.png]])
        row.ungroupBtn:GetNormalTexture():SetVertexColor(0.4, 0.85, 1, 1)
        row.ungroupBtn:GetHighlightTexture():SetVertexColor(0.7, 1, 1, 1)
        row.ungroupBtn:Hide()

        -- Pin indicator (shown when alert is pinned to top)
        row.pinIcon = row:CreateTexture(nil, "OVERLAY")
        row.pinIcon:SetSize(12, 12)
        row.pinIcon:SetTexture([[Interface\Addons\NorthernSkyRaidTools\Media\Icons\pin.png]])
        row.pinIcon:SetVertexColor(189/255, 142/255, 69/255, 1)
        row.pinIcon:SetPoint("RIGHT", row, "RIGHT", -20, 0)
        row.pinIcon:Hide()

        row:EnableMouse(true)
        row:Hide()
        return row
    end

    local function CreateGroupHeaderRow()
        local row = CreateFrame("Frame", nil, listChild, "BackdropTemplate")
        row:SetSize(listChild:GetWidth(), lineHeight)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.05, 0.30, 0.40)
        row.__background:SetAlpha(0.90)

        local arrow = row:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(12, 12)
        arrow:SetPoint("LEFT", row, "LEFT", 4, 0)
        arrow:SetTexture([[Interface\Buttons\Arrow-Down-Up]])
        arrow:SetVertexColor(0, 0.9, 1, 1)
        row.collapseArrow = arrow

        local bossIcon = row:CreateTexture(nil, "ARTWORK")
        bossIcon:SetSize(16, 16)
        bossIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        bossIcon:SetPoint("LEFT", row, "LEFT", 18, 0)
        bossIcon:Hide()
        row.bossIcon = bossIcon

        local nameLabel = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(nameLabel, 13, NSI:GetUIFontFlags())
        nameLabel:SetTextColor(0.2, 0.85, 1, 1)
        nameLabel:SetPoint("LEFT", row, "LEFT", 18, 0)  -- repositioned dynamically
        nameLabel:SetPoint("RIGHT", row, "RIGHT", -36, 0)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetWordWrap(false)
        row.nameLabel = nameLabel

        local countLabel = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(countLabel, 12, NSI:GetUIFontFlags())
        countLabel:SetTextColor(0.5, 0.5, 0.5, 1)
        countLabel:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.countLabel = countLabel

        row:EnableMouse(true)
        row:Hide()
        return row
    end

    -- Returns a display name for a ReloeReminder alert entry.
    local function ReloeAlertName(entry)
        local base = (entry.name and entry.name ~= "") and entry.name
                  or (entry.text and entry.text ~= "") and entry.text
                  or "?"
        return base
    end

    -- RebuildList ─────────────────────────────────────────────────────────────
    -- Group management helpers (groups are encounter-ID scoped)
    -- Collapse state key: tostring(encID).."|".groupName
    local function GroupKey(encID, name) return tostring(encID) .. "|" .. name end

    local function EnsureGroup(encID, name)
        NSRT.Alerts = NSRT.Alerts or {}
        NSRT.Alerts.Groups = NSRT.Alerts.Groups or {}
        local k = GroupKey(encID, name)
        if not NSRT.Alerts.Groups[k] then
            NSRT.Alerts.Groups[k] = { collapsed = true }
        end
    end

    local function DeleteGroup(encID, name)
        local enc = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
        if enc then
            for _, diffTable in pairs(enc) do
                for _, alert in pairs(type(diffTable) == "table" and diffTable or {}) do
                    if type(alert) == "table" and alert.group == name then alert.group = nil end
                end
            end
        end
        if NSRT.Alerts and NSRT.Alerts.Groups then NSRT.Alerts.Groups[GroupKey(encID, name)] = nil end
    end

    local function DeleteGroupWithAlerts(encID, name)
        local enc = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
        if enc then
            local groupAlerts = {}
            for diffID, diffTable in pairs(enc) do
                for key, alert in pairs(type(diffTable) == "table" and diffTable or {}) do
                    if type(alert) == "table" and alert.group == name then
                        table.insert(groupAlerts, { diffID = diffID, diffTable = diffTable, key = key, alert = alert })
                    end
                end
            end

            for _, entry in ipairs(groupAlerts) do
                if not NSI:CanDeleteEncounterAlert(entry.alert, encID) then
                    entry.alert.group = nil
                else
                    entry.diffTable[entry.key] = nil
                end
                NSI:FireCallback("NSRT_ALERT_CHANGED", encID, entry.diffID, entry.key)
            end
        end
        if NSRT.Alerts and NSRT.Alerts.Groups then NSRT.Alerts.Groups[GroupKey(encID, name)] = nil end
    end

    local function DeleteAlert(encID, diffID, alertKey)
        local diffTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
            and NSRT.EncounterAlerts[encID][diffID]
        if diffTable and diffTable[alertKey] and not NSI:CanDeleteEncounterAlert(diffTable[alertKey], encID) then return end
        if diffTable then
            diffTable[alertKey] = nil
            NSI:FireCallback("NSRT_ALERT_CHANGED", encID, diffID, alertKey)
        end
        if selectedKey == alertKey and selectedEncID == encID then
            selectedKey = nil
            selectedEncID = nil
            if rightPanel then rightPanel:Hide() end
        end
        RebuildList()
    end

    local function ConfirmDeleteAlert(encID, diffID, alertKey)
        local deleteDialog = NSI.UI.Components.CreateDialog("NSRTDeleteAlertConfirm" .. tostring(alertKey),
            NSI:Loc("Delete Alert"), NSI:Loc("Are you sure you want to delete this alert?"), NSI:Loc("Cancel"), nil, NSI:Loc("Delete"), function()
                DeleteAlert(encID, diffID, alertKey)
            end, nil)
        deleteDialog:Show()
    end

    local function GetGroupsForEnc(eid)
        local groups = {}
        for name in pairs(groupsByEnc[eid] or {}) do
            table.insert(groups, name)
        end
        table.sort(groups)
        return groups
    end

    local function SortAlerts(t)
        table.sort(t, function(a, b)
            local ag = (a._enabled and 0 or 2) + (a._isReloeCreated and 1 or 0)
            local bg = (b._enabled and 0 or 2) + (b._isReloeCreated and 1 or 0)
            if ag ~= bg then return ag < bg end
            local ao = NSI.EncounterOrder[a.encID] or 99
            local bo = NSI.EncounterOrder[b.encID] or 99
            if ao ~= bo then return ao < bo end
            if a._phase ~= b._phase then return a._phase < b._phase end
            if a._orderID and b._orderID and a._orderID ~= b._orderID then return a._orderID < b._orderID end
            return (a._sortName or "") < (b._sortName or "")
        end)
    end

    local function RebuildScrollData()
        local pinned       = {}
        local ungrouped    = {}
        local groupedAlerts = {}  -- { ["encID|groupName"] = { alert items } }
        groupsByEnc = {}  -- reset cache

        -- Single loop: all alerts live in NSRT.EncounterAlerts; ReloeReminder distinguishes them
        for encID, encTable in pairs(NSRT.EncounterAlerts or {}) do
            if not filterEncID or filterEncID == encID then
                local diffTable = type(encTable) == "table" and encTable[filterDiffID]
                if type(diffTable) == "table" then
                    for key, entry in pairs(diffTable) do
                        if type(entry) == "table" then
                            -- Populate group cache regardless of search filter
                            local grp = entry.group and entry.group ~= "" and entry.group
                            if grp then
                                groupsByEnc[encID] = groupsByEnc[encID] or {}
                                groupsByEnc[encID][grp] = true
                            end

                            local isReloe     = entry.ReloeReminder == true
                            local displayName = isReloe and ReloeAlertName(entry) or (entry.name or NSI:Loc("Unnamed"))
                            if searchText == "" or string.find(string.lower(displayName), string.lower(searchText), 1, true) then
                                local item = {
                                    _type           = "alert",
                                    encID           = encID,
                                    diffID          = filterDiffID,
                                    alertKey        = key,
                                    data            = entry,
                                    _isReloeCreated = isReloe,
                                    _enabled        = entry.enabled ~= false,
                                    _phase          = entry.phase or 1,
                                    _sortName       = displayName,
                                    _orderID        = isReloe and entry.id or nil,
                                    _group          = entry.group,
                                }
                                if grp then
                                    local gk = GroupKey(encID, grp)
                                    groupedAlerts[gk] = groupedAlerts[gk] or { encID = encID, groupName = grp }
                                    table.insert(groupedAlerts[gk], item)
                                elseif entry.pinned then
                                    table.insert(pinned, item)
                                else
                                    table.insert(ungrouped, item)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Collect all encounter-scoped group keys that have members
        local allGroupKeys = {}
        for gk in pairs(groupedAlerts) do allGroupKeys[gk] = true end
        -- Include explicit Groups metadata entries only if they have members too
        -- (empty groups are not shown; orphaned entries are cleaned up)
        if NSRT.Alerts and NSRT.Alerts.Groups then
            local toRemove = {}
            for gk in pairs(NSRT.Alerts.Groups) do
                if not allGroupKeys[gk] then
                    local sep = gk:find("|")
                    local eid = sep and tonumber(gk:sub(1, sep - 1))
                    if not filterEncID or eid == filterEncID then
                        table.insert(toRemove, gk)
                    end
                end
            end
            for _, gk in ipairs(toRemove) do NSRT.Alerts.Groups[gk] = nil end
        end
        local sortedGroupKeys = {}
        for gk in pairs(allGroupKeys) do table.insert(sortedGroupKeys, gk) end
        table.sort(sortedGroupKeys, function(a, b)
            -- Sort by encID order first, then group name
            local sepA, sepB = a:find("|"), b:find("|")
            local eidA = tonumber(a:sub(1, sepA - 1)) or 0
            local eidB = tonumber(b:sub(1, sepB - 1)) or 0
            local oA = NSI.EncounterOrder[eidA] or 99
            local oB = NSI.EncounterOrder[eidB] or 99
            if oA ~= oB then return oA < oB end
            return a:sub(sepA + 1) < b:sub(sepB + 1)
        end)

        local t = {}
        local currentPinned, oldPinned = {}, {}
        local currentGroups, oldGroups = {}, {}
        local currentUngrouped, oldUngrouped = {}, {}

        SortAlerts(pinned)
        for _, item in ipairs(pinned) do
            item._pinned = true
            if NSI.CurrentEncounterIDs[item.encID] then
                table.insert(currentPinned, item)
            else
                table.insert(oldPinned, item)
            end
        end

        for _, gk in ipairs(sortedGroupKeys) do
            local gdata = groupedAlerts[gk] or {}
            local encID = gdata.encID or (function()
                local sep = gk:find("|")
                return sep and tonumber(gk:sub(1, sep - 1)) or 0
            end)()
            if NSI.CurrentEncounterIDs[encID] then
                table.insert(currentGroups, gk)
            else
                table.insert(oldGroups, gk)
            end
        end

        SortAlerts(ungrouped)
        for _, item in ipairs(ungrouped) do
            if NSI.CurrentEncounterIDs[item.encID] then
                table.insert(currentUngrouped, item)
            else
                table.insert(oldUngrouped, item)
            end
        end

        local function AppendAlerts(list)
            for _, item in ipairs(list) do table.insert(t, item) end
        end

        local function AppendGroups(groupKeys)
            for _, gk in ipairs(groupKeys) do
                local gdata    = groupedAlerts[gk] or {}
                local encID    = gdata.encID or (function()
                    local sep = gk:find("|")
                    return sep and tonumber(gk:sub(1, sep - 1)) or 0
                end)()
                local groupName = gdata.groupName or gk:sub((gk:find("|") or 0) + 1)
                -- Gather members (skip the encID/groupName fields)
                local members = {}
                for _, item in ipairs(gdata) do table.insert(members, item) end
                SortAlerts(members)
                local gEntry = NSRT.Alerts and NSRT.Alerts.Groups and NSRT.Alerts.Groups[gk]
                local collapsed = gEntry == nil or gEntry.collapsed
                table.insert(t, {
                    _type      = "group_header",
                    groupKey   = gk,
                    groupName  = groupName,
                    groupEncID = encID,
                    _count     = #members,
                    _collapsed = collapsed,
                })
                if not collapsed then
                    for _, item in ipairs(members) do
                        item._inGroup = true
                        table.insert(t, item)
                    end
                end
            end
        end

        AppendAlerts(currentPinned)
        AppendGroups(currentGroups)
        AppendAlerts(currentUngrouped)
        AppendAlerts(oldPinned)
        AppendGroups(oldGroups)
        AppendAlerts(oldUngrouped)

        return t
    end

    RebuildList = function()
        local savedScroll = listScroll:GetVerticalScroll()
        local data = RebuildScrollData()

        local alertIdx = 0
        local groupIdx = 0
        local slot     = 0   -- total visual rows rendered (drives y positioning)

        for _, entry in ipairs(data) do
            slot = slot + 1

            -- ── Group header row ─────────────────────────────────────────────
            if entry._type == "group_header" then
                groupIdx = groupIdx + 1
                if not groupHeaderRows[groupIdx] then
                    groupHeaderRows[groupIdx] = CreateGroupHeaderRow()
                end
                local row   = groupHeaderRows[groupIdx]
                local gname = entry.groupName
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -(slot - 1) * lineHeight)
                row:SetWidth(listChild:GetWidth())
                row.collapseArrow:SetTexture(entry._collapsed and
                    [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]] or
                    [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-up.png]])
                row.collapseArrow:SetVertexColor(0.4, 0.85, 1, 1)
                row.nameLabel:SetText(gname)
                row.countLabel:SetText("(" .. entry._count .. ")")

                -- Boss icon: only shown when viewing all bosses
                local showBossIcon = not filterEncID or filterEncID == 0
                local bossIconTex = showBossIcon and BossData.BossIcons[entry.groupEncID]
                if row.bossIcon then
                    if bossIconTex then
                        row.bossIcon:SetTexture(bossIconTex)
                        row.bossIcon:Show()
                        row.nameLabel:SetPoint("LEFT", row.bossIcon, "RIGHT", 4, 0)
                    else
                        row.bossIcon:Hide()
                        row.nameLabel:SetPoint("LEFT", row, "LEFT", 18, 0)
                    end
                end

                row:Show()

                row:SetScript("OnMouseDown", function(self, button)
                    local gname   = entry.groupName
                    local gencID  = entry.groupEncID
                    local gk      = entry.groupKey
                    if button == "RightButton" then
                        ShowContextMenu({
                            { type = "button", label = NSI:Loc("Export Group"), fnc = function()
                                local str = NSI:ExportGroupString(gencID, gname, filterDiffID)
                                ShowExportPopup(str, "Group: " .. gname)
                            end },
                            { type = "separator" },
                            { type = "button", label = NSI:Loc("Enable All"), fnc = function()
                                local diffTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[gencID]
                                              and NSRT.EncounterAlerts[gencID][filterDiffID]
                                if diffTable then
                                    for akey, alert in pairs(diffTable) do
                                        if type(alert) == "table" and alert.group == gname then
                                            alert.enabled = true
                                            NSI:FireCallback("NSRT_ALERT_CHANGED", gencID, filterDiffID, akey)
                                        end
                                    end
                                end
                                RebuildList()
                            end },
                            { type = "button", label = NSI:Loc("Disable All"), fnc = function()
                                local diffTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[gencID]
                                              and NSRT.EncounterAlerts[gencID][filterDiffID]
                                if diffTable then
                                    for akey, alert in pairs(diffTable) do
                                        if type(alert) == "table" and alert.group == gname then
                                            alert.enabled = false
                                            NSI:FireCallback("NSRT_ALERT_CHANGED", gencID, filterDiffID, akey)
                                        end
                                    end
                                end
                                RebuildList()
                            end },
                            { type = "separator" },
                            { type = "button", label = NSI:Loc("Delete Group (keep alerts)"), fnc = function()
                                DeleteGroup(gencID, gname)
                                RebuildList()
                            end },
                            { type = "button", label = NSI:Loc("Delete Group with Alerts"), fnc = function()
                                local dialogGroupName = tostring(gname):gsub("%W", "_")
                                local dlg = NSI.UI.Components.CreateDialog(
                                    "NSRTDeleteGroupAlerts" .. tostring(gencID) .. "_" .. dialogGroupName,
                                    NSI:Loc("Delete Group with Alerts"),
                                    string.format(NSI:Loc("Delete group '%s' and all deletable alerts?"), gname),
                                    NSI:Loc("Cancel"), nil, NSI:Loc("Delete"), function()
                                        DeleteGroupWithAlerts(gencID, gname)
                                        local still = selectedKey and NSRT.EncounterAlerts
                                            and NSRT.EncounterAlerts[selectedEncID]
                                            and NSRT.EncounterAlerts[selectedEncID][selectedDiffID or filterDiffID]
                                            and NSRT.EncounterAlerts[selectedEncID][selectedDiffID or filterDiffID][selectedKey]
                                        if not still then
                                            selectedKey = nil; selectedEncID = nil
                                            if rightPanel then rightPanel:Hide() end
                                        end
                                        RebuildList()
                                    end, nil)
                                dlg:Show()
                            end },
                        })
                    else
                        EnsureGroup(gencID, gname)
                        NSRT.Alerts.Groups[gk].collapsed = not NSRT.Alerts.Groups[gk].collapsed
                        RebuildList()
                    end
                end)

            -- ── Alert row ────────────────────────────────────────────────────
            else
                alertIdx = alertIdx + 1
                if not listRows[alertIdx] then
                    listRows[alertIdx] = CreateListRow()
                end
                local row    = listRows[alertIdx]
                local indent = entry._inGroup and 14 or 0
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", listChild, "TOPLEFT", indent, -(slot - 1) * lineHeight)
                row:SetWidth(listChild:GetWidth() - indent)
                row:Show()

                local isReloe   = entry._isReloeCreated
                local canDelete = NSI:CanDeleteEncounterAlert(entry.data, entry.encID)
                local isEnabled, icon, name

                if filterEncID == nil or filterEncID == 0 then
                    icon = BossData.BossIcons[entry.encID]
                else
                    local alertData = entry.data
                    local customIcon = alertData and alertData.customIcon and C_Spell.GetSpellInfo(alertData.customIcon)
                    if customIcon then
                        icon = customIcon.iconID
                    else
                        local spell = alertData and alertData.spellID and C_Spell.GetSpellInfo(alertData.spellID)
                        if spell then
                            icon = spell.iconID
                        else
                            icon = BossData.BossIcons[entry.encID]
                        end
                    end
                end

                isEnabled = entry.data.enabled
                name      = isReloe and ReloeAlertName(entry.data) or (entry.data.name or NSI:Loc("Unnamed"))

                local willLoad = NSI:EvaluateLoad(entry.data)

                -- Selected highlight
                local isSelected = isReloe
                    and (selectedEncID == entry.encID and selectedDiffID == entry.diffID and selectedKey == entry.alertKey)
                    or  (not isReloe and selectedKey == entry.alertKey and selectedEncID == entry.encID)
                if isSelected then
                    row.__background:SetVertexColor(0, 1, 1)
                    row.__background:SetAlpha(1)
                else
                    row.__background:SetVertexColor(0.4, 0.4, 0.4)
                    row.__background:SetAlpha(willLoad and 0.5 or 0.2)
                end
                if icon then
                    row.bossIcon:SetTexture(icon)
                    row.bossIcon:Show()
                    row.bossIcon:SetAlpha(willLoad and 1 or 0.35)
                else
                    row.bossIcon:SetTexture(nil)
                    row.bossIcon:Hide()
                end
                row.nameLabel:SetPoint("LEFT", row.bossIcon, "RIGHT", 4, 0)

                row.nameLabel:SetText(name)
                local alpha = willLoad and (isEnabled and 1 or 0.45) or 0.35
                row.nameLabel:SetTextColor(1, 1, 1, alpha)
                row.enabledCB.frame:SetAlpha(willLoad and 1 or 0.4)

                if row.pinIcon then
                    row.pinIcon:SetShown(entry._pinned == true)
                end

                -- Enabled checkbox: sync state then wire handler
                row.enabledCB:SetValue(isEnabled)

                if isReloe then
                    local eid, did, akey = entry.encID, entry.diffID, entry.alertKey
                    row.enabledCB:SetOnChange(function(nsi, v)
                        local e = NSRT.EncounterAlerts and NSRT.EncounterAlerts[eid]
                                   and NSRT.EncounterAlerts[eid][did]
                                   and NSRT.EncounterAlerts[eid][did][akey]
                        if e then
                            e.enabled = v
                            e.UserModifiedEnabled = true
                            if selectedEncID == eid and selectedDiffID == did and selectedKey == akey then
                                enabledCB:SetValue(v)
                            end
                            NSI:FireCallback("NSRT_ALERT_CHANGED", eid, did, akey)
                        end
                    end)
                else
                    local alert   = entry.data
                    local akey    = entry.alertKey
                    local aencID  = entry.encID
                    local adid    = entry.diffID
                    row.enabledCB:SetOnChange(function(nsi, v)
                        alert.enabled = v
                        if selectedKey == akey and selectedEncID == aencID then
                            enabledCB:SetValue(v)
                        end
                        NSI:FireCallback("NSRT_ALERT_CHANGED", aencID, adid, akey)
                    end)
                end

                -- Right-side button: ungroup (if grouped) > delete
                if entry._inGroup then
                    -- Ungroup always sits at far right when grouped
                    row.ungroupBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                    row.ungroupBtn:Show()
                    local akey_ug, eid_ug = entry.alertKey, entry.encID
                    row.ungroupBtn:SetScript("OnClick", function()
                        local diffTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[eid_ug]
                                      and NSRT.EncounterAlerts[eid_ug][filterDiffID]
                        if diffTable and diffTable[akey_ug] then
                            diffTable[akey_ug].group = nil
                        end
                        RebuildList()
                    end)
                    if not canDelete then
                        row.deleteBtn:Hide()
                        row.deleteBtn:SetScript("OnClick", nil)
                        row.lockIcon:ClearAllPoints()
                        row.lockIcon:SetPoint("RIGHT", row.ungroupBtn, "LEFT", -4, 0)
                        row.lockIcon:Show()
                    else
                        row.lockIcon:Hide()
                        local akey = entry.alertKey
                        local ri_encID = entry.encID
                        local ri_diffID = entry.diffID
                        row.deleteBtn:Show()
                        row.deleteBtn:SetPoint("RIGHT", row.ungroupBtn, "LEFT", -4, 0)
                        row.deleteBtn:SetScript("OnClick", function()
                            ConfirmDeleteAlert(ri_encID, ri_diffID, akey)
                        end)
                    end
                else
                    row.ungroupBtn:Hide()
                    row.ungroupBtn:SetScript("OnClick", nil)
                    row.ungroupBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)  -- reset anchor
                    row.deleteBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)   -- reset anchor
                    row.lockIcon:ClearAllPoints()
                    row.lockIcon:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                    if not canDelete then
                        row.deleteBtn:Hide()
                        row.deleteBtn:SetScript("OnClick", nil)
                        row.lockIcon:Show()
                    else
                        row.lockIcon:Hide()
                        row.deleteBtn:Show()
                        local akey = entry.alertKey
                        local ri_encID = entry.encID
                        local ri_diffID = entry.diffID
                        row.deleteBtn:SetScript("OnClick", function()
                            ConfirmDeleteAlert(ri_encID, ri_diffID, akey)
                        end)
                    end
                end

                -- Click to select (skip when clicking the enabled checkbox)
                do
                    local eid, did, akey = entry.encID, entry.diffID, entry.alertKey
                    local isReloeRow = isReloe
                    row:SetScript("OnMouseDown", function(self, button)
                        if row.enabledCB.frame:IsMouseOver() then return end
                        if button == "RightButton" then
                            local alert = NSRT.EncounterAlerts and NSRT.EncounterAlerts[eid]
                                      and NSRT.EncounterAlerts[eid][did]
                                      and NSRT.EncounterAlerts[eid][did][akey]
                            local name = alert and (alert.name or alert.text or NSI:Loc("Unnamed")) or NSI:Loc("Unnamed")

                            -- Group submenu (shared for all alert types)
                            local groupSubItems = {}
                            for _, gname in ipairs(GetGroupsForEnc(eid)) do
                                local gn = gname
                                table.insert(groupSubItems, { type = "button", label = gn, fnc = function()
                                    if alert then alert.group = gn; EnsureGroup(eid, gn); RebuildList() end
                                end })
                            end
                            table.insert(groupSubItems, { type = "button", label = NSI:Loc("New Group..."), fnc = function()
                                StaticPopupDialogs["NSRT_NEW_GROUP_INPUT"] = {
                                    text = NSI:Loc("Enter new group name:"),
                                    button1 = NSI:Loc("OK"),
                                    button2 = NSI:Loc("Cancel"),
                                    hasEditBox = true,
                                    timeout = 0,
                                    whileDead = true,
                                    hideOnEscape = true,
                                    OnAccept = function(self)
                                        local newName = self.EditBox:GetText()
                                        if newName and newName ~= "" then
                                            if alert then alert.group = newName end
                                            EnsureGroup(eid, newName)
                                            RebuildList()
                                        end
                                    end,
                                    EditBoxOnEnterPressed = function(self)
                                        local parent = self:GetParent()
                                        StaticPopupDialogs["NSRT_NEW_GROUP_INPUT"].OnAccept(parent)
                                        parent:Hide()
                                    end,
                                }
                                StaticPopup_Show("NSRT_NEW_GROUP_INPUT")
                            end })

                            -- Build menu conditionally
                            local menuItems = {
                                { type = "button", label = NSI:Loc("Export Alert"), fnc = function()
                                    local str = NSI:ExportSingleAlertString("encounter", eid, did, akey, alert)
                                    ShowExportPopup(str, name)
                                end },
                                { type = "submenu", label = alert and alert.group and NSI:Loc("Move to Group") or NSI:Loc("Add to Group"),
                                  items = groupSubItems },
                            }

                            if isReloeRow then
                                table.insert(menuItems, { type = "button", label = NSI:Loc("Reset"), fnc = function()
                                    local diffTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[eid] and NSRT.EncounterAlerts[eid][did]
                                    if diffTable then diffTable[akey] = nil end
                                    NSI:ImportReloeReminders(eid)
                                    RebuildList()
                                    local stillExists = NSRT.EncounterAlerts and NSRT.EncounterAlerts[eid]
                                                    and NSRT.EncounterAlerts[eid][did]
                                                    and NSRT.EncounterAlerts[eid][did][akey]
                                    if stillExists then
                                        SelectAlert(akey, did, eid)
                                    else
                                        selectedKey = nil; selectedEncID = nil
                                        if rightPanel then rightPanel:Hide() end
                                    end
                                end })
                            end

                            if not (isReloeRow and entry.data.BlockCopy) then
                                table.insert(menuItems, { type = "button", label = NSI:Loc("Duplicate"), fnc = function()
                                    NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
                                    NSRT.EncounterAlerts[eid] = NSRT.EncounterAlerts[eid] or {}
                                    NSRT.EncounterAlerts[eid][did] = NSRT.EncounterAlerts[eid][did] or {}
                                    local diffTable = NSRT.EncounterAlerts[eid][did]
                                    local newKey = NSI:UniqueAlertID(diffTable, false)
                                    local newData = CopyTable(entry.data)
                                    newData.ReloeReminder = nil
                                    diffTable[newKey] = newData
                                    RebuildList()
                                end })
                            end

                            -- Copy... submenu
                            local copySubItems = {}
                            for _, tabName in ipairs({ "Display", "Trigger", "Sound", "Load" }) do
                                local tn = tabName
                                if CanCopySection(tn, alert) then
                                    table.insert(copySubItems, { type = "button", label = NSI:Loc(tn), fnc = function()
                                        local payload = {
                                            section = tn,
                                            encID   = eid,
                                            diffID  = did,
                                            entries = {},
                                        }
                                        if tn == "Trigger" then
                                            payload.entries[#payload.entries + 1] = { key = "phase",  value = CopyValue(alert.phase) }
                                            payload.entries[#payload.entries + 1] = { key = "timers", value = CopyValue(alert.timers) }
                                            payload.entries[#payload.entries + 1] = { key = "isConditional", value = CopyValue(alert.isConditional) }
                                        else
                                            for _, k in ipairs(SECTION_COPY_FIELDS[tn] or {}) do
                                                payload.entries[#payload.entries + 1] = { key = k, value = CopyValue(alert[k]) }
                                            end
                                        end
                                        copiedAlertSection = payload
                                    end })
                                end
                            end
                            if #copySubItems > 0 then
                                table.insert(menuItems, { type = "submenu", label = NSI:Loc("Copy") .. "...", items = copySubItems })
                            end

                            -- Paste option (only shown if a section was previously copied and is compatible)
                            if copiedAlertSection then
                                local sn = copiedAlertSection.section
                                if CanCopySection(sn, alert) then
                                    local pasteEid, pasteDid, pasteAkey = eid, did, akey
                                    table.insert(menuItems, { type = "button",
                                        label = NSI:Loc("Paste") .. " (" .. NSI:Loc(sn) .. ")",
                                        fnc = function() ApplyCopiedSectionTo(pasteEid, pasteDid, pasteAkey) end })
                                end
                            end

                            if alert and alert.group then
                                table.insert(menuItems, { type = "button", label = NSI:Loc("Remove from Group"), fnc = function()
                                    alert.group = nil
                                    RebuildList()
                                end })
                            end

                            table.insert(menuItems, { type = "button",
                                label = (alert and alert.pinned) and NSI:Loc("Unpin") or NSI:Loc("Pin to Top"),
                                fnc = function()
                                    if alert then
                                        alert.pinned = not alert.pinned or nil
                                        RebuildList()
                                    end
                                end })

                            if NSI:CanDeleteEncounterAlert(alert, eid) then
                                table.insert(menuItems, { type = "separator" })
                                table.insert(menuItems, {
                                    type = "button",
                                    label = NSI:Loc("Delete"),
                                    fnc = function()
                                        ConfirmDeleteAlert(eid, did, akey)
                                    end,
                                })
                            end
                            ShowContextMenu(menuItems)
                        else
                            SelectAlert(akey, did, eid)
                        end
                    end)
                end
            end  -- alert row end
        end  -- data loop end

        -- Hide unused pool slots
        for i = alertIdx + 1, #listRows        do listRows[i]:Hide() end
        for i = groupIdx + 1, #groupHeaderRows do groupHeaderRows[i]:Hide() end

        -- Sync the group dropdown if an alert is selected
        if groupDD then groupDD:Refresh() end

        local totalH = math.max(slot * lineHeight, 1)
        listChild:SetHeight(totalH)
        local bar = _G["NSUIEncAlertListScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, totalH - listScroll:GetHeight())
            bar:SetMinMaxValues(0, maxScroll)
            local clampedScroll = math.min(savedScroll, maxScroll)
            bar:SetValue(clampedScroll)
            listScroll:SetVerticalScroll(clampedScroll)
        end
    end

    screen.RebuildList = RebuildList
    screen.RefreshSelected = function()
        if selectedEncID and selectedKey then
            SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
        end
    end

    -- Create Alert button
    local createBtn = CreateLocalizedButton(screen, "+ Create Alert", function()
        -- Resolve which encID to create under: current filter or first available boss
        local createEncID = (filterEncID and filterEncID ~= 0) and filterEncID or (function()
            local opts = BossData.BuildBossDropdownOptions(nil, false)
            return opts and opts[1] and opts[1].value or nil
        end)()
        if not createEncID then return end  -- no bosses defined
        NSRT.EncounterAlerts = NSRT.EncounterAlerts or {}
        NSRT.EncounterAlerts[createEncID] = NSRT.EncounterAlerts[createEncID] or {}
        NSRT.EncounterAlerts[createEncID][filterDiffID] = NSRT.EncounterAlerts[createEncID][filterDiffID] or {}
        local diffTable = NSRT.EncounterAlerts[createEncID][filterDiffID]
        local newKey = NSI:UniqueAlertID(diffTable, false)
        local s = NSRT.ReminderSettings
        diffTable[newKey] = {
            name          = NSI:Loc("New Alert"),
            enabled       = true,
            phase         = 1,
            timers        = {},
            DisplayType   = "Text",
            text          = "",
            spellID       = nil,
            dur           = s.TextDuration or 8,
            TTS           = s.TextTTS and true or false,
            TTSTimer      = s.TextTTSTimer or 8,
            countdown     = false,
            sticky        = 0,
            loadConditions = { Classes = {}, SpecIDs = {}, Names = {}, Roles = {}, },
        }
        RebuildList()
        SelectAlert(newKey, filterDiffID, createEncID)
        NSI:FireCallback("NSRT_ALERT_CHANGED", createEncID, filterDiffID, newKey)
    end, listW, 18)
    createBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, 8)

    -- Import / Export buttons (row above create)
    local halfW = math.floor((listW - 4) / 2)
    local ioY   = 8 + 18 + 2

    local importAlertsBtn = CreateLocalizedButton(screen, "Import", function()
        ShowImportPopup()
    end, halfW, 18)
    importAlertsBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, ioY)

    local exportAlertsBtn = CreateLocalizedButton(screen, "Export", function()
        local encFilter = filterEncID ~= 0 and filterEncID or nil
        local label = NSI:Loc("All encounter alerts")
        if encFilter then
            label = getFilterBossSelected()
        end
        local str = NSI:ExportAlertsString(encFilter, filterDiffID)
        ShowExportPopup(str, label)
    end, halfW, 18)
    exportAlertsBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad + halfW + 4, ioY)

    -- Additional Options popup — positioned to the right of the main NSUI window
    local ADDOPT_PAD = 12
    local ADDOPT_W   = listW + ADDOPT_PAD * 2 + 10
    local ADDOPT_INNER_W = ADDOPT_W - ADDOPT_PAD * 2
    local ADDOPT_H   = 250
    local addOptFrame = CreateStyledFrame(NSUI, ADDOPT_W, ADDOPT_H, "NSRTEncAlertAddOptFrame")
    addOptFrame:SetPoint("TOPLEFT", NSUI, "TOPRIGHT", 4, 0)
    addOptFrame:Hide()

    local reloeImportCB = CreateCheckButton(addOptFrame, NSI:Loc("Automatically Enable New Alerts"),
        function() return NSRT.Alerts.ReloeReminders end,
        function(_, v)
            local wasEnabled = NSRT.Alerts.ReloeReminders == true
            NSRT.Alerts.ReloeReminders = v
            if v and not wasEnabled then
                NSI:PromptReloeReminderImport(function()
                    RebuildList()
                    if selectedEncID and selectedKey then
                        SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
                    end
                end)
            end
            RebuildList()
        end,
        ADDOPT_INNER_W, 22, "NSUIEncAlertReloeImportCB")
    reloeImportCB:SetLocaleKey("Automatically Enable New Alerts")
    reloeImportCB:SetPoint("TOPLEFT", addOptFrame, "TOPLEFT", ADDOPT_PAD, -30)

    local importSelectedBossBtn = CreateLocalizedButton(addOptFrame, "Import Selected Boss Alerts", function()
        if not filterEncID or filterEncID == 0 then
            print("|cFF00FFFFNSRT:|r " .. NSI:Loc("Select a boss first."))
            return
        end
        NSI:ImportReloeReminders(filterEncID, true)
        RebuildList()
        if selectedEncID and selectedKey then
            SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
        end
    end, ADDOPT_INNER_W, 22)
    importSelectedBossBtn:SetPoint("TOPLEFT", reloeImportCB.frame, "BOTTOMLEFT", 0, -8)

    local fullResetBtn = CreateLocalizedButton(addOptFrame, "Full Reset", function()
        local function DoReset()
            -- Only wipe Reloe-created alerts; preserve user-created ones
            for encID, encTable in pairs(NSRT.EncounterAlerts or {}) do
                for diffID, diffTable in pairs(encTable) do
                    for k, a in pairs(diffTable) do
                        if type(a) == "table" and a.ReloeReminder then
                            diffTable[k] = nil
                        end
                    end
                end
            end
            NSI:ImportReloeReminders()
            RebuildList()
            if selectedEncID and selectedKey then
                SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
            end
        end
        local dialog = NSI.UI.Components.CreateDialog(
            "NSRTEncAlertFullReset",
            NSI:Loc("Full Reset"),
            NSI:Loc("This will wipe all Encounter Alert data and re-import Reloe Alerts (if enabled). Continue?"),
            NSI:Loc("Cancel"), nil, NSI:Loc("Reset"), DoReset, nil)
        dialog:Show()
    end, ADDOPT_INNER_W, 26)
    fullResetBtn:SetPoint("TOPLEFT", importSelectedBossBtn.frame, "BOTTOMLEFT", 0, -8)

    local deleteOldAlertsBtn = CreateLocalizedButton(addOptFrame, "Delete Old Alerts", function()
        local function DoDeleteOldAlerts()
            NSI:DeleteOldEncounterAlertData()
            selectedKey = nil
            selectedEncID = nil
            if rightPanel then rightPanel:Hide() end
            RebuildList()
        end
        local dialog = NSI.UI.Components.CreateDialog(
            "NSRTEncAlertDeleteSeason1",
            NSI:Loc("Delete old Alerts from previous Seasons"),
            NSI:Loc("This will delete all Alerts from previous Seasons. Continue?"),
            NSI:Loc("Cancel"), nil, NSI:Loc("Delete"), DoDeleteOldAlerts, nil)
        dialog:Show()
    end, ADDOPT_INNER_W, 22)
    deleteOldAlertsBtn:SetPoint("TOPLEFT", fullResetBtn.frame, "BOTTOMLEFT", 0, -8)

    local function SetReloeAlertsEnabled(enabled)
        for encID, encTable in pairs(NSRT.EncounterAlerts or {}) do
            if not filterEncID or filterEncID == encID then
                local diffTable = type(encTable) == "table" and encTable[filterDiffID]
                if type(diffTable) == "table" then
                    for akey, alert in pairs(diffTable) do
                        if type(alert) == "table" and alert.ReloeReminder then
                            alert.enabled = enabled
                            alert.UserModifiedEnabled = true
                            NSI:FireCallback("NSRT_ALERT_CHANGED", encID, filterDiffID, akey)
                        end
                    end
                end
            end
        end
        RebuildList()
    end

    local enableAllBtn = CreateLocalizedButton(addOptFrame, "Enable Selected Boss Alerts", function()
        SetReloeAlertsEnabled(true)
    end, ADDOPT_INNER_W, 22)
    enableAllBtn:SetPoint("TOPLEFT", deleteOldAlertsBtn.frame, "BOTTOMLEFT", 0, -8)

    local disableAllBtn = CreateLocalizedButton(addOptFrame, "Disable Selected Boss Alerts", function()
        SetReloeAlertsEnabled(false)
    end, ADDOPT_INNER_W, 22)
    disableAllBtn:SetPoint("TOPLEFT", enableAllBtn.frame, "BOTTOMLEFT", 0, -8)

    -- "Additional Options" button replaces the two rows that moved into the popup
    local addOptY = ioY + 18 + 2
    local addOptBtn = CreateLocalizedButton(screen, "Additional Options", function()
        if addOptFrame:IsShown() then
            addOptFrame:Hide()
        else
            addOptFrame:Show()
        end
    end, listW, 18)
    addOptBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, addOptY)

    -- ================================================================
    -- Right Panel
    -- ================================================================
    rightPanel = CreateFrame("Frame", nil, screen)
    rightPanel:SetPoint("TOPLEFT",     screen, "TOPLEFT",     rightX, topY)
    rightPanel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -pad,   pad)
    rightPanel:Hide()

    -- ── Header: name entry + group entry + enabled checkbox ─────────────────
    local nameLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(nameLbl, 11, "")
    nameLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    SetLocalizedText(nameLbl, "Alert Name")
    nameLbl:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)

    local nameEntry = CreateTextEntry(rightPanel, nil, nil, nil, rightW - 240, 22,
        nil, nil, nil, "NSUIEncAlertNameEntry")
    nameEntry:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -14)

    local groupLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(groupLbl, 11, "")
    groupLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    SetLocalizedText(groupLbl, "Group")
    groupLbl:SetPoint("BOTTOMLEFT", nameEntry.frame, "BOTTOMRIGHT", 12, 22)

    local function BuildGroupItems()
        local eid   = groupDD._eid
        local did   = groupDD._did
        local akey  = groupDD._akey
        local alert = eid and did and akey
                  and NSRT.EncounterAlerts
                  and NSRT.EncounterAlerts[eid]
                  and NSRT.EncounterAlerts[eid][did]
                  and NSRT.EncounterAlerts[eid][did][akey]
        local items = {}
        table.insert(items, { label = NSI:Loc("— No Group —"), onclick = function()
            if alert then alert.group = nil; RebuildList(); groupDD:Refresh() end
        end })
        for _, gname in ipairs(GetGroupsForEnc(eid or 0)) do
            local gn = gname
            table.insert(items, { label = gn, onclick = function()
                if alert then alert.group = gn; EnsureGroup(eid, gn); RebuildList(); groupDD:Refresh() end
            end })
        end
        table.insert(items, { label = NSI:Loc("New Group..."), onclick = function()
            StaticPopupDialogs["NSRT_NEW_GROUP_INPUT"] = {
                text = NSI:Loc("Enter new group name:"),
                button1 = NSI:Loc("OK"),
                button2 = NSI:Loc("Cancel"),
                hasEditBox = true,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                OnAccept = function(self)
                    local newName = self.EditBox:GetText()
                    if newName and newName ~= "" then
                        if alert then alert.group = newName end
                        EnsureGroup(eid, newName)
                        RebuildList()
                        groupDD:Refresh()
                    end
                end,
                EditBoxOnEnterPressed = function(self)
                    local parent = self:GetParent()
                    StaticPopupDialogs["NSRT_NEW_GROUP_INPUT"].OnAccept(parent)
                    parent:Hide()
                end,
            }
            StaticPopup_Show("NSRT_NEW_GROUP_INPUT")
        end })
        return items
    end

    local function GetGroupSelected()
        local eid   = groupDD and groupDD._eid
        local did   = groupDD and groupDD._did
        local akey  = groupDD and groupDD._akey
        local alert = eid and did and akey
                  and NSRT.EncounterAlerts
                  and NSRT.EncounterAlerts[eid]
                  and NSRT.EncounterAlerts[eid][did]
                  and NSRT.EncounterAlerts[eid][did][akey]
        return (alert and alert.group) or NSI:Loc("— No Group —")
    end

    groupDD = CreateDropdown(rightPanel, nil, BuildGroupItems, GetGroupSelected,
        120, 22, "NSUIEncAlertGroupDD")
    groupDD:SetPoint("LEFT", nameEntry.frame, "RIGHT", 12, 0)

    enabledCB = CreateCheckButton(rightPanel, NSI:Loc("Enabled"),
        function() return false end, nil, 90, 22, "NSUIEncAlertEnabled")
    enabledCB:SetLocaleKey("Enabled")
    enabledCB:SetPoint("LEFT", groupDD.frame, "RIGHT", 8, 0)

    conditionHint = rightPanel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(conditionHint, 12, "")
    conditionHint:SetTextColor(0.9, 0.75, 0.2, 1)
    conditionHint:SetJustifyH("LEFT")
    conditionHint:SetJustifyV("TOP")
    conditionHint:SetWidth(rightW)
    conditionHint:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -40)
    conditionHint:Hide()

    -- ── Inner tab bar ────────────────────────────────────────────────────────
    local INNER_TABS     = { "Display", "Trigger", "Sound", "Load", "Options" }
    local innerTabBtns   = {}
    local innerTabFrames = {}
    local activeInnerTab = "Display"

    local function SelectInnerTab(name)
        activeInnerTab = name
        for _, tn in ipairs(INNER_TABS) do
            local f = innerTabFrames[tn]
            f:SetShown(tn == name)
            if tn == name then
                innerTabBtns[tn]:Select()
                if f.Rebuild then f.Rebuild() end   -- e.g. RebuildLoadTab when Load is selected
            else
                innerTabBtns[tn]:Deselect()
            end
        end
    end

    local tabBtnW   = 84
    local tabBtnGap = 3
    local tabRowY   = -42
    local contentY  = tabRowY - 26

    -- Pre-declarations for cross-tab upvalue references. Keep these before
    -- helpers that need them; Lua locals are only visible after declaration.
    local dispF, trigF, sndF, loadF
    local dispHint, sndHint
    local RebuildOptionsContent

    local function GetConditionText(condition)
        if type(condition) == "table" and type(condition.func) == "string" and condition.func ~= "" then
            return (type(condition.text) == "string" and condition.text ~= "" and condition.text) or NSI:Loc("Custom Condition")
        elseif type(condition) == "string" and condition ~= "" then
            return NSI:Loc("Custom Condition")
        end
        return nil
    end

    local function PositionInnerTabLayout(conditionText)
        local hasCondition = type(conditionText) == "string" and conditionText ~= ""

        if hasCondition then
            conditionHint:SetText("|cFFFFD100" .. NSI:Loc("Condition") .. ":|r " .. conditionText)
            conditionHint:Show()
            local hintHeight = math.max(conditionHint:GetStringHeight() or 16, 16)
            conditionHint:SetHeight(hintHeight)
            tabRowY = -(42 + hintHeight + 10)
        else
            conditionHint:SetText("")
            conditionHint:Hide()
            tabRowY = -42
        end
        contentY = tabRowY - 26

        for i, tabName in ipairs(INNER_TABS) do
            local btn = innerTabBtns[tabName]
            if btn then
                btn.frame:ClearAllPoints()
                btn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", (i - 1) * (tabBtnW + tabBtnGap), tabRowY)
            end
        end
        if copySectionBtn then
            copySectionBtn.frame:ClearAllPoints()
            copySectionBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -202, tabRowY)
        end
        if applySectionBtn and copySectionBtn then
            applySectionBtn.frame:ClearAllPoints()
            applySectionBtn:SetPoint("LEFT", copySectionBtn.frame, "RIGHT", 4, 0)
        end
        if previewBtn then
            previewBtn.frame:ClearAllPoints()
            previewBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY)
        end
        if tabSep then
            tabSep:ClearAllPoints()
            tabSep:SetPoint("TOPLEFT",  rightPanel, "TOPLEFT",  0, tabRowY - 20)
            tabSep:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY - 20)
        end
        for _, f in pairs(innerTabFrames) do
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT",     rightPanel, "TOPLEFT",     0, contentY)
            f:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)
        end
    end

    local DEFAULT_CONDITION_FUNC = "return function()\n    return true\nend"
    local conditionEditPopup
    local function OpenConditionEditor()
        if not trigF or not trigF._alert then return end

        if not conditionEditPopup then
            conditionEditPopup = DF:CreateSimplePanel(NSUI, 820, 520,
                "|cFF00FFFF" .. NSI:Loc("Custom Condition") .. "|r",
                "NSUIEncAlertConditionEditor", { DontRightClickClose = true })
            conditionEditPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            conditionEditPopup:SetFrameLevel(100)

            conditionEditPopup.nameLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.nameLabel, 12, "")
            conditionEditPopup.nameLabel:SetTextColor(0.8, 0.8, 0.8, 1)
            SetLocalizedText(conditionEditPopup.nameLabel, "Condition Name")
            conditionEditPopup.nameLabel:SetPoint("TOPLEFT", conditionEditPopup, "TOPLEFT", 10, -32)

            conditionEditPopup.nameEntry = CreateTextEntry(conditionEditPopup, nil, nil, nil, 360, 22,
                nil, nil, nil, "NSUIEncAlertConditionName")
            conditionEditPopup.nameEntry:SetPoint("TOPLEFT", conditionEditPopup, "TOPLEFT", 10, -48)

            conditionEditPopup.codeLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.codeLabel, 12, "")
            conditionEditPopup.codeLabel:SetTextColor(0.8, 0.8, 0.8, 1)
            SetLocalizedText(conditionEditPopup.codeLabel, "Condition Function")
            conditionEditPopup.codeLabel:SetPoint("TOPLEFT", conditionEditPopup.nameEntry.frame, "BOTTOMLEFT", 0, -12)

            conditionEditPopup.helpLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.helpLabel, 11, "")
            conditionEditPopup.helpLabel:SetTextColor(0.55, 0.55, 0.55, 1)
            conditionEditPopup.helpLabel:SetJustifyH("LEFT")
            conditionEditPopup.helpLabel:SetPoint("TOPLEFT", conditionEditPopup.codeLabel, "BOTTOMLEFT", 0, -2)
            SetLocalizedText(conditionEditPopup.helpLabel, "Return a function which should return true when the alert should show.")

            conditionEditPopup.editor = DF:NewSpecialLuaEditorEntry(conditionEditPopup, 280, 80, nil,
                "NSUIEncAlertConditionEditorBox", false, true, true)
            conditionEditPopup.editor:SetPoint("TOPLEFT", conditionEditPopup, "TOPLEFT", 10, -112)
            conditionEditPopup.editor:SetPoint("BOTTOMRIGHT", conditionEditPopup, "BOTTOMRIGHT", -25, 48)
            DF:ApplyStandardBackdrop(conditionEditPopup.editor)
            DF:ReskinSlider(conditionEditPopup.editor.scroll)
            conditionEditPopup.editor:SetScript("OnMouseDown", function(self) self:SetFocus() end)
            NSI:SetUIFont(conditionEditPopup.editor.editbox, 13, "OUTLINE")

            conditionEditPopup.statusLabel = conditionEditPopup:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(conditionEditPopup.statusLabel, 11, "")
            conditionEditPopup.statusLabel:SetTextColor(1, 0.35, 0.35, 1)
            conditionEditPopup.statusLabel:SetPoint("BOTTOMLEFT", conditionEditPopup, "BOTTOMLEFT", 10, 14)
            conditionEditPopup.statusLabel:SetWidth(430)
            conditionEditPopup.statusLabel:SetJustifyH("LEFT")

            conditionEditPopup.saveBtn = CreateLocalizedButton(conditionEditPopup, "Save", function()
                local alert = conditionEditPopup._alert
                if not alert then return end
                local conditionName = conditionEditPopup.nameEntry:GetValue() or ""
                local conditionFunc = conditionEditPopup.editor:GetText() or ""
                conditionName = strtrim(conditionName)
                conditionFunc = strtrim(conditionFunc)

                if conditionName == "" and conditionFunc == "" then
                    NSI:SaveAlertData(alert, "isConditional", nil)
                    conditionEditPopup:Hide()
                    PositionInnerTabLayout(nil)
                    if trigF.conditionBtn then trigF.conditionBtn:SetText(NSI:Loc("Add Condition")) end
                    RebuildList()
                    return
                end

                if conditionFunc == "" then
                    conditionEditPopup.statusLabel:SetText(NSI:Loc("Condition Function is required."))
                    return
                end

                local chunk, err = loadstring(conditionFunc)
                if not chunk then
                    conditionEditPopup.statusLabel:SetText(err or NSI:Loc("Invalid condition function."))
                    return
                end

                local condition = {
                    text = conditionName ~= "" and conditionName or NSI:Loc("Custom Condition"),
                    func = conditionFunc,
                }
                NSI:SaveAlertData(alert, "isConditional", condition)
                conditionEditPopup:Hide()
                PositionInnerTabLayout(condition.text)
                if trigF.conditionBtn then trigF.conditionBtn:SetText(NSI:Loc("Edit Condition")) end
                RebuildList()
            end, 120, 22)
            conditionEditPopup.saveBtn:SetPoint("BOTTOMRIGHT", conditionEditPopup, "BOTTOMRIGHT", -138, 12)

            conditionEditPopup.clearBtn = CreateLocalizedButton(conditionEditPopup, "Clear", function()
                conditionEditPopup.nameEntry:SetValue("")
                conditionEditPopup.editor:SetText("")
                conditionEditPopup.statusLabel:SetText("")
            end, 120, 22)
            conditionEditPopup.clearBtn:SetPoint("RIGHT", conditionEditPopup.saveBtn.frame, "LEFT", -8, 0)

            conditionEditPopup.cancelBtn = CreateLocalizedButton(conditionEditPopup, "Cancel", function()
                conditionEditPopup:Hide()
            end, 120, 22)
            conditionEditPopup.cancelBtn:SetPoint("LEFT", conditionEditPopup.saveBtn.frame, "RIGHT", 8, 0)
        end

        local condition = trigF._alert.isConditional
        conditionEditPopup._alert = trigF._alert
        conditionEditPopup.statusLabel:SetText("")
        conditionEditPopup.nameEntry:SetValue(type(condition) == "table" and condition.text or "")
        conditionEditPopup.editor:SetText(type(condition) == "table" and condition.func or DEFAULT_CONDITION_FUNC)
        conditionEditPopup:Show()
        conditionEditPopup.editor:SetFocus()
    end

    CopyValue = function(v)
        return type(v) == "table" and CopyTable(v) or v
    end

    SECTION_COPY_FIELDS = {
        Display = {
            "DisplayType", "text", "spellID", "isTaunt", "customIcon", "dur", "sticky",
            "HideTimer", "HideSwipe", "glowunit", "glowColors", "textColors",
            "ringColors", "showBackground", "Texture", "Ticks", "barColors",
        },
        Sound = { "TTS", "TTSTimer", "countdown", "sound" },
        Load = { "loadConditions" },
    }

    local function GetSelectedAlert()
        return selectedEncID and selectedDiffID and selectedKey
            and NSRT.EncounterAlerts
            and NSRT.EncounterAlerts[selectedEncID]
            and NSRT.EncounterAlerts[selectedEncID][selectedDiffID]
            and NSRT.EncounterAlerts[selectedEncID][selectedDiffID][selectedKey]
    end

    CanCopySection = function(sectionName, alert)
        if not alert then return false end
        if sectionName == "Options" then return false end
        if sectionName == "Trigger" and alert.ReloeReminder then return false end
        return sectionName == "Display" or sectionName == "Trigger" or sectionName == "Sound" or sectionName == "Load"
    end

    local function CopySection(sectionName)
        local alert = GetSelectedAlert()
        if not CanCopySection(sectionName, alert) then return end

        local payload = {
            section = sectionName,
            encID = selectedEncID,
            diffID = selectedDiffID,
            entries = {},
        }

        if sectionName == "Trigger" then
            payload.entries[#payload.entries + 1] = { key = "phase", value = CopyValue(alert.phase) }
            payload.entries[#payload.entries + 1] = { key = "timers", value = CopyValue(alert.timers) }
            payload.entries[#payload.entries + 1] = { key = "isConditional", value = CopyValue(alert.isConditional) }
        else
            for _, key in ipairs(SECTION_COPY_FIELDS[sectionName] or {}) do
                payload.entries[#payload.entries + 1] = { key = key, value = CopyValue(alert[key]) }
            end
        end

        copiedAlertSection = payload
        if applySectionBtn then applySectionBtn:Enable() end
    end

    ApplyCopiedSectionTo = function(targetEid, targetDid, targetAkey)
        local alert = NSRT.EncounterAlerts and NSRT.EncounterAlerts[targetEid]
                   and NSRT.EncounterAlerts[targetEid][targetDid]
                   and NSRT.EncounterAlerts[targetEid][targetDid][targetAkey]
        if not copiedAlertSection or not alert then return end
        local sectionName = copiedAlertSection.section
        if not CanCopySection(sectionName, alert) then return end

        local oldEncID, oldDiffID, oldKey = targetEid, targetDid, targetAkey
        local curEncID, curDiffID, curKey = targetEid, targetDid, targetAkey

        if sectionName == "Trigger" then
            local newEncID = copiedAlertSection.encID or curEncID
            local newDiffID = copiedAlertSection.diffID or curDiffID
            if newEncID ~= curEncID or newDiffID ~= curDiffID then
                local oldTable = NSRT.EncounterAlerts[curEncID] and NSRT.EncounterAlerts[curEncID][curDiffID]
                if oldTable then oldTable[curKey] = nil end
                NSRT.EncounterAlerts[newEncID] = NSRT.EncounterAlerts[newEncID] or {}
                NSRT.EncounterAlerts[newEncID][newDiffID] = NSRT.EncounterAlerts[newEncID][newDiffID] or {}
                local newTable = NSRT.EncounterAlerts[newEncID][newDiffID]
                local newKey = (not newTable[curKey]) and curKey or NSI:UniqueAlertID(newTable, false)
                newTable[newKey] = alert
                if selectedEncID == targetEid and selectedDiffID == targetDid and selectedKey == targetAkey then
                    selectedEncID, selectedDiffID, selectedKey = newEncID, newDiffID, newKey
                    filterDiffID = newDiffID
                    if filterEncID then filterEncID = newEncID end
                    if diffDD then diffDD:Refresh() end
                    if filterDD then filterDD:Refresh() end
                end
                curEncID, curDiffID, curKey = newEncID, newDiffID, newKey
            end
        end

        for _, entry in ipairs(copiedAlertSection.entries or {}) do
            alert[entry.key] = CopyValue(entry.value)
        end

        if sectionName == "Load" then
            alert.loadConditions = alert.loadConditions or {}
            alert.loadConditions.Classes = alert.loadConditions.Classes or {}
            alert.loadConditions.SpecIDs = alert.loadConditions.SpecIDs or {}
            alert.loadConditions.Roles = alert.loadConditions.Roles or {}
            alert.loadConditions.Names = alert.loadConditions.Names or {}
        end

        NSI:FireCallback("NSRT_ALERT_CHANGED", oldEncID, oldDiffID, oldKey)
        if curEncID ~= oldEncID or curDiffID ~= oldDiffID or curKey ~= oldKey then
            NSI:FireCallback("NSRT_ALERT_CHANGED", curEncID, curDiffID, curKey)
        end
        RebuildList()
        if selectedEncID and selectedKey then
            SelectAlert(selectedKey, selectedDiffID, selectedEncID)
        end
    end

    local function ApplyCopiedSection()
        if not copiedAlertSection then return end
        ApplyCopiedSectionTo(selectedEncID, selectedDiffID, selectedKey)
    end

    local function RefreshSectionCopyButtons()
        if not copySectionBtn or not applySectionBtn then return end
        local alert = GetSelectedAlert()
        if CanCopySection(activeInnerTab, alert) then
            copySectionBtn:Enable()
        else
            copySectionBtn:Disable()
        end
        if copiedAlertSection and copiedAlertSection.section == activeInnerTab and CanCopySection(activeInnerTab, alert) then
            applySectionBtn:Enable()
        else
            applySectionBtn:Disable()
        end
    end

    for i, tabName in ipairs(INNER_TABS) do
        local btn = CreateLocalizedSubButton(rightPanel, tabName, function()
            SelectInnerTab(tabName)
            RefreshSectionCopyButtons()
        end, tabBtnW, "NSUIEncAlertInnerTab_" .. tabName)
        btn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", (i - 1) * (tabBtnW + tabBtnGap), tabRowY)
        innerTabBtns[tabName] = btn
    end
    innerTabBtns["Options"].frame:Hide()

    copySectionBtn = CreateLocalizedSubButton(rightPanel, "Copy", function()
        CopySection(activeInnerTab)
        RefreshSectionCopyButtons()
    end, 52, "NSUIEncAlertCopySection")
    copySectionBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -202, tabRowY)
    copySectionBtn.frame:Hide()

    applySectionBtn = CreateLocalizedSubButton(rightPanel, "Apply", function()
        ApplyCopiedSection()
    end, 58, "NSUIEncAlertApplySection")
    applySectionBtn:SetPoint("LEFT", copySectionBtn.frame, "RIGHT", 4, 0)
    applySectionBtn.frame:Hide()

    -- ── Preview button — right-aligned on the tab row ────────────────────────
    previewBtn = CreateLocalizedButton(rightPanel, "Preview", function() PreviewAlert() end, 80, 18,
        "NSUIEncAlertPreview")
    previewBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY)

    -- Separator below tabs
    tabSep = rightPanel:CreateTexture(nil, "ARTWORK")
    tabSep:SetColorTexture(0, 1, 1, 0.20)
    tabSep:SetHeight(1)
    tabSep:SetPoint("TOPLEFT",  rightPanel, "TOPLEFT",  0, tabRowY - 20)
    tabSep:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY - 20)

    for _, tabName in ipairs(INNER_TABS) do
        local f = CreateFrame("Frame", nil, rightPanel)
        f:SetPoint("TOPLEFT",     rightPanel, "TOPLEFT",     0, contentY)
        f:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)
        f:Hide()
        innerTabFrames[tabName] = f
    end

    -- ================================================================
    -- Helper: build a lock overlay for a tab frame
    -- transparent=true → invisible background (blocks clicks but content is visible)
    -- ================================================================
    local function MakeLockOverlay(parent, messageKey, transparent)
        local ov = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        ov:SetAllPoints(parent)
        ov:SetFrameLevel(parent:GetFrameLevel() + 10)
        ov:EnableMouse(true)

        if transparent then
            -- No background; just intercept mouse. Show a small read-only badge top-right.
            local badge = ov:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(badge, 11, "")
            badge:SetTextColor(0.9, 0.75, 0.2, 0.85)
            NSI.UI.Components.RegisterLocalizedText(badge, "Read-only", function()
                return "|TInterface\\PetBattles\\PetBattle-LockIcon:12:12:0:-1|t " .. NSI:Loc("Read-only")
            end)
            badge:SetPoint("TOPRIGHT", ov, "TOPRIGHT", 0, 0)
        else
            DF:ApplyStandardBackdrop(ov)
            ov.__background:SetVertexColor(0.02, 0.02, 0.02)
            ov.__background:SetAlpha(0.82)

            local lbl = ov:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(lbl, 13, "")
            lbl:SetTextColor(0.55, 0.55, 0.55, 1)
            SetLocalizedText(lbl, messageKey)
            lbl:SetPoint("CENTER", ov, "CENTER", 0, 0)
            lbl:SetJustifyH("CENTER")
        end

        ov:Hide()
        return ov
    end

    -- ================================================================
    -- DISPLAY TAB
    -- ================================================================
    do
    dispF = innerTabFrames["Display"]

    dispHint = dispF:CreateFontString(nil, "OVERLAY")
    dispHint:Hide()

    local typeLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(typeLbl, 12, "")
    typeLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(typeLbl, "Type")
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
        local tb = CreateLocalizedSubButton(dispF, tn, function()
            if dispF._alert then NSI:SaveAlertData(dispF._alert, "DisplayType", tn) end
            SetDisplayType(tn)
        end, typeBtnW, "NSUIEncAlertType_" .. tn)
        tb:SetPoint("TOPLEFT", dispF, "TOPLEFT", (i - 1) * (typeBtnW + 3), -18)
        typeBtns[tn] = tb
    end

    local textLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(textLbl, 12, "")
    textLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(textLbl, "Display Text")
    textLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -46)

    local textEntry = CreateTextEntry(dispF, nil, nil, nil, rightW, 22,
        nil, nil, nil, "NSUIEncAlertDisplayText")
    textEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -62)
    local function SaveDispText(self)
        local v = self:GetText()
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "text", v) end
    end
    textEntry.editBox:SetScript("OnEditFocusLost", SaveDispText)
    dispF.textEntry = textEntry

    local spellLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(spellLbl, 12, "")
    spellLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(spellLbl, "Spell ID")
    spellLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -90)

    local spellEntry = CreateTextEntry(dispF, nil, nil, nil, 130, 22,
        nil, nil, nil, "NSUIEncAlertSpellID")
    spellEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -106)

    -- Spell icon preview: shown immediately to the right of the entry
    local spellIconFrame = CreateFrame("Frame", nil, dispF, "BackdropTemplate")
    spellIconFrame:SetSize(22, 22)
    spellIconFrame:SetPoint("LEFT", spellEntry.frame, "RIGHT", 4, 0)
    DF:ApplyStandardBackdrop(spellIconFrame)
    local spellIconTex = spellIconFrame:CreateTexture(nil, "ARTWORK")
    spellIconTex:SetPoint("TOPLEFT",     spellIconFrame, "TOPLEFT",     1,  -1)
    spellIconTex:SetPoint("BOTTOMRIGHT", spellIconFrame, "BOTTOMRIGHT", -1,  1)
    spellIconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    spellIconFrame.texture = spellIconTex
    spellIconFrame:Hide()
    dispF.spellIconFrame = spellIconFrame

    local function UpdateSpellIcon(text)
        local id = tonumber(text)
        local spell = id and C_Spell.GetSpellInfo(id)
        if spell and spell.iconID then
            spellIconTex:SetTexture(spell.iconID)
            spellIconFrame:Show()
        else
            spellIconFrame:Hide()
        end
    end

    local function SaveSpellID(self)
        local v = tonumber(self:GetText()) or nil
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "spellID", v) end
        RebuildList()
    end
    spellEntry.editBox:SetScript("OnTextChanged", function(self) UpdateSpellIcon(self:GetText()) end)
    spellEntry.editBox:SetScript("OnEditFocusLost", SaveSpellID)
    dispF.spellEntry = spellEntry

    local useTauntCB = CreateCheckButton(dispF, NSI:Loc("Use Taunt spellid"),
        function()
            return dispF._alert and dispF._alert.isTaunt == true or false
        end,
        function(_, v)
            if dispF._alert then
                NSI:SaveAlertData(dispF._alert, "isTaunt", v or nil)
                RebuildList()
            end
        end,
        150, 22, "NSUIEncAlertUseTauntSpellID")
    useTauntCB:SetLocaleKey("Use Taunt spellid")
    useTauntCB:SetPoint("TOPLEFT", dispF, "TOPLEFT", 164, -106)
    dispF.useTauntCB = useTauntCB

    local customIconLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(customIconLbl, 12, "")
    customIconLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(customIconLbl, "Custom Icon (overrides icon in list)")
    customIconLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 330, -90)

    local customIconEntry = CreateTextEntry(dispF, nil, nil, nil, 180, 22,
        nil, nil, nil, "NSUIEncAlertCustomIcon")
    customIconEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 330, -106)
    local function SaveCustomIcon(self)
        local v = tonumber(self:GetText()) or nil
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "customIcon", v) end
        RebuildList()
    end
    customIconEntry.editBox:SetScript("OnEditFocusLost", SaveCustomIcon)
    dispF.customIconEntry = customIconEntry

    local durLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(durLbl, 12, "")
    durLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(durLbl, "Duration")
    durLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -134)

    local durEntry = CreateTextEntry(dispF, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertDuration")
    durEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -150)
    local function SaveDur(self)
        local v = tonumber(self:GetText())
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "dur", v or 8) end
    end
    durEntry.editBox:SetScript("OnEditFocusLost", SaveDur)
    dispF.durEntry = durEntry

    local stickyLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(stickyLbl, 12, "")
    stickyLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(stickyLbl, "Sticky duration (0 to disable)")
    stickyLbl:SetPoint("TOPLEFT", durLbl, "TOPRIGHT", 55, 0)

    local stickyEntry = CreateTextEntry(dispF, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertSticky")
    stickyEntry:SetPoint("TOPLEFT", durEntry.frame, "TOPRIGHT", 20, 0)
    local function SaveSticky(self)
        local v = tonumber(self:GetText())
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "sticky", v) end
    end
    stickyEntry.editBox:SetScript("OnEditFocusLost", SaveSticky)
    dispF.stickyEntry = stickyEntry

    local hideTimerCB = CreateCheckButton(dispF, NSI:Loc("Hide Timer Text"),
        function()
            if not dispF._alert then return false end
            if dispF._alert.HideTimer ~= nil then return dispF._alert.HideTimer end
            local typeMap = { Text="TextSettings", Icon="IconSettings", Circle="CircleSettings", Bar="BarSettings" }
            local s = NSRT.ReminderSettings[typeMap[dispF._alert.DisplayType or "Text"] or "TextSettings"]
            return s and s.HideTimerText or false
        end,
        function(_, v) if dispF._alert then NSI:SaveAlertData(dispF._alert, "HideTimer", v or nil) end end,
        135, 22, "NSUIEncAlertHideTimer")
    hideTimerCB:SetLocaleKey("Hide Timer Text")
    hideTimerCB:SetPoint("LEFT", stickyEntry.frame, "RIGHT", 14, 0)
    dispF.hideTimerCB = hideTimerCB

    local hideSwipeCB = CreateCheckButton(dispF, NSI:Loc("Hide Swipe"),
        function()
            if not dispF._alert then return false end
            if dispF._alert.HideSwipe ~= nil then return dispF._alert.HideSwipe end
            return NSRT.ReminderSettings.IconSettings.HideSwipe or false
        end,
        function(_, v) if dispF._alert then NSI:SaveAlertData(dispF._alert, "HideSwipe", v or nil) end end,
        110, 22, "NSUIEncAlertHideSwipe")
    hideSwipeCB:SetLocaleKey("Hide Swipe")
    hideSwipeCB:SetPoint("LEFT", hideTimerCB.frame, "RIGHT", 20, 0)
    hideSwipeCB.frame:Hide()   -- only shown for Icon type
    dispF.hideSwipeCB = hideSwipeCB

    -- ── glowunit ────────────────────────────────────────────────────────
    local glowunitLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(glowunitLbl, 12, "")
    glowunitLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(glowunitLbl, "Glow Unit (player names, space seperated)")
    glowunitLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -178)

    local glowunitEntry = CreateTextEntry(dispF, nil, nil, nil, 200, 22,
        nil, nil, nil, "NSUIEncAlertGlowUnit")
    glowunitEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -194)
    local function SaveGlowUnit(self)
        local v = self:GetText()
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "glowunit", (v ~= "") and v or nil) end
    end
    glowunitEntry.editBox:SetScript("OnEditFocusLost", SaveGlowUnit)
    dispF.glowunitEntry = glowunitEntry

    local glowcolorlbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(glowcolorlbl, 12, "")
    glowcolorlbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(glowcolorlbl, "Glow Color")
    glowcolorlbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 265, -198)
    dispF.glowcolorlbl = glowcolorlbl

    local glowunitColor = CreateColorPicker(dispF, nil,
        function()
            local c = dispF._alert and dispF._alert.glowColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return unpack(NSRT.ReminderSettings.GlowSettings.colors)
        end,
        function(_, r, g, b, a)
            if dispF._alert then NSI:SaveAlertData(dispF._alert, "glowColors", {r, g, b, a}) end
        end,
        200, 22, "NSUIEncAlertGlowColors")
    glowunitColor:SetPoint("TOPLEFT", dispF, "TOPLEFT", 60, -194)
    dispF.glowunitColor = glowunitColor

    -- ── colors ──────────────────────────────────────────────────────────
    local colorsLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(colorsLbl, 12, "")
    colorsLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    NSI.UI.Components.RegisterLocalizedText(colorsLbl, "Color", function()
        local t = dispF._alert and (dispF._alert.DisplayType or "Text")
        if t == "Text" or t == "Icon" or t == "Circle" then
            return NSI:Loc("Text Color")
        end
        return NSI:Loc("Color")
    end)
    colorsLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -216)
    dispF.colorsLbl = colorsLbl

    local colorsPicker = CreateColorPicker(dispF, nil,
        function()
            local c = dispF._alert and dispF._alert.textColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            local dt = dispF._alert and dispF._alert.DisplayType or "Text"
            local typeMap = { Text="TextSettings", Icon="IconSettings", Circle="CircleSettings", Bar="BarSettings" }
            local fc = NSRT.ReminderSettings[typeMap[dt] or "TextSettings"].textColors
            if fc then return fc[1] or 1, fc[2] or 1, fc[3] or 1, fc[4] or 1 end
            return 1, 1, 1, 1
        end,
        function(_, r, g, b, a)
            if dispF._alert then NSI:SaveAlertData(dispF._alert, "textColors", {r, g, b, a}) end
        end,
        200, 22, "NSUIEncAlertColors")
    colorsPicker:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -216)
    dispF.colorsPicker = colorsPicker

    -- ── Circle section (shown only when display type = "Circle") ────────
    local circleSection = CreateFrame("Frame", nil, dispF)
    circleSection:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -266)
    circleSection:SetSize(rightW, 88)
    circleSection:Hide()

    local circleTextureLbl = circleSection:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(circleTextureLbl, 12, "")
    circleTextureLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(circleTextureLbl, "Texture")
    circleTextureLbl:SetPoint("TOPLEFT", circleSection, "TOPLEFT", 0, 26)

    local function BuildCircleTextureOptions()
        local opts = {
            {
                label = GetDefaultCircleTextureLabel(),
                value = nil,
                onclick = function()
                    if dispF._alert then NSI:SaveAlertData(dispF._alert, "Texture", nil) end
                end,
            },
        }
        for _, option in ipairs(CIRCLE_TEXTURES) do
            local label, value = option.label, option.value
            opts[#opts + 1] = {
                label = label,
                value = value,
                onclick = function()
                    if dispF._alert then NSI:SaveAlertData(dispF._alert, "Texture", value) end
                end,
            }
        end
        return opts
    end

    local function GetSelectedCircleTexture()
        if not (dispF._alert and dispF._alert.Texture) then return GetDefaultCircleTextureLabel() end
        return GetCircleTextureLabel(dispF._alert.Texture)
    end

    local circleTextureDD = CreateDropdown(circleSection, nil, BuildCircleTextureOptions,
        GetSelectedCircleTexture, 200, 22, "NSUIEncAlertCircleTexture")
    circleTextureDD:SetPoint("TOPLEFT", circleSection, "TOPLEFT", 0, 10)
    dispF.circleTextureDD = circleTextureDD

    local ringColorsLbl = circleSection:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ringColorsLbl, 12, "")
    ringColorsLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(ringColorsLbl, "Ring Color")
    ringColorsLbl:SetPoint("TOPLEFT", circleTextureDD.frame, "BOTTOMLEFT", 0, -8)

    local ringColorsPicker = CreateColorPicker(circleSection, nil,
        function()
            local c = dispF._alert and dispF._alert.ringColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return unpack(NSRT.ReminderSettings.CircleSettings.ringColors)
        end,
        function(_, r, g, b, a) if dispF._alert then NSI:SaveAlertData(dispF._alert, "ringColors", {r, g, b, a}) end end,
        200, 22, "NSUIEncAlertRingColors")
    ringColorsPicker:SetPoint("TOPLEFT", ringColorsLbl, "BOTTOMLEFT", 0, 4)
    dispF.ringColorsPicker = ringColorsPicker

    local showBgCB = CreateCheckButton(circleSection, NSI:Loc("Show Background Ring"),
        function()
            if not dispF._alert then return NSRT.ReminderSettings.CircleSettings.showBackground end
            if dispF._alert.showBackground ~= nil then return dispF._alert.showBackground ~= false end
            return NSRT.ReminderSettings.CircleSettings.showBackground
        end,
        function(_, v) if dispF._alert then NSI:SaveAlertData(dispF._alert, "showBackground", v) end end,
        200, 22, "NSUIEncAlertShowBg")
    showBgCB:SetLocaleKey("Show Background Ring")
    showBgCB:SetPoint("TOPLEFT", ringColorsPicker.frame, "BOTTOMLEFT", 0, -4)
    dispF.showBgCB = showBgCB

    -- ── Bars section: Ticks (shown only when display type = "Bar") ───────
    local barsSection = CreateFrame("Frame", nil, dispF)
    barsSection:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -300)
    barsSection:SetSize(rightW, 130)
    barsSection:Hide()

    local ticksLbl = barsSection:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ticksLbl, 12, "")
    ticksLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(ticksLbl, "Ticks (seconds into the display where ticks should appear)")
    ticksLbl:SetPoint("TOPLEFT", barsSection, "TOPLEFT", 0, 0)

    local ticksListH = 100
    local ticksListW = rightW - 20

    local ticksScroll = CreateFrame("ScrollFrame", "NSUIEncAlertTicksScroll", barsSection,
        "UIPanelScrollFrameTemplate")
    ticksScroll:SetSize(ticksListW, ticksListH)
    ticksScroll:SetPoint("TOPLEFT", barsSection, "TOPLEFT", 0, -16)
    ReskinScrollbar(ticksScroll)
    local ticksBg = ticksScroll:CreateTexture(nil, "BACKGROUND")
    ticksBg:SetAllPoints(ticksScroll)
    ticksBg:SetColorTexture(0.04, 0.04, 0.04, 0.85)

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
        if not dispF._alert then return end
        local ticks = dispF._alert.Ticks or {}
        for i, v in ipairs(ticks) do
            if not tickRows[i] then
                tickRows[i] = CreateFrame("Frame", nil, ticksChild)
                tickRows[i].bg = tickRows[i]:CreateTexture(nil, "BACKGROUND")
                tickRows[i].tLbl = tickRows[i]:CreateFontString(nil, "OVERLAY")
                tickRows[i].delBtn = CreateFrame("Button", nil, tickRows[i])
                tickRows[i].tLbl:SetTextColor(1, 1, 1, 1)
                tickRows[i].tLbl:SetPoint("LEFT", tickRows[i], "LEFT", 8, 0)
                tickRows[i].bg:SetAllPoints(tickRows[i])
                tickRows[i]:SetSize(ticksChild:GetWidth(), tickRowH)
                tickRows[i]:SetPoint("TOPLEFT", ticksChild, "TOPLEFT", 0, -(i - 1) * tickRowH)
                tickRows[i].delBtn:SetSize(14, 14)
                tickRows[i].delBtn:SetPoint("RIGHT", tickRows[i], "RIGHT", -6, 0)
                tickRows[i].delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                tickRows[i].delBtn:GetNormalTexture():SetDesaturated(true)
                tickRows[i].delBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
            end
            if i % 2 == 0 then
                tickRows[i].bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
            else
                tickRows[i].bg:SetColorTexture(0, 0, 0, 0)
            end
            NSI:SetUIFont(tickRows[i].tLbl, 13, "")
            tickRows[i].tLbl:SetText(tostring(v))

            tickRows[i].delBtn:SetScript("OnClick", function()
                if dispF._alert then
                    table.remove(dispF._alert.Ticks, i)
                    NSI:SaveAlertData(dispF._alert, "Ticks", dispF._alert.Ticks)
                    RebuildTickRows()
                end
            end)
            tickRows[i]:Show()
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
    NSI:SetUIFont(addTickLbl, 11, "")
    addTickLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    SetLocalizedText(addTickLbl, "Add tick")
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
            NSI:FireCallback("NSRT_ALERT_CHANGED", selectedEncID, filterDiffID, selectedKey)
            RebuildTickRows()
        end
    end

    addTickEntry.editBox:SetScript("OnEnterPressed", function(self)
        DoAddTick()
        self:ClearFocus()
    end)

    local addTickBtn = CreateLocalizedSubButton(barsSection, "Add", DoAddTick, 54,
        "NSUIEncAlertAddTickBtn")
    addTickBtn:SetPoint("LEFT", addTickEntry.frame, "RIGHT", 6, 0)

    -- Bar-specific text color picker — shown at the TOP slot (y=-244) for Bar type,
    -- replacing the shared colorsPicker which is hidden when Bar is selected
    local barTextColorsLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(barTextColorsLbl, 12, "")
    barTextColorsLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(barTextColorsLbl, "Bar Text Color")
    barTextColorsLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -216)
    barTextColorsLbl:Hide()

    local barTextColorsPicker = CreateColorPicker(dispF, nil,
        function()
            local c = dispF._alert and dispF._alert.textColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return unpack(NSRT.ReminderSettings.BarSettings.textColors)
        end,
        function(_, r, g, b, a) if dispF._alert then NSI:SaveAlertData(dispF._alert, "textColors", {r, g, b, a}) end end,
        200, 22, "NSUIEncAlertBarTextColors")
    barTextColorsPicker:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -216)
    barTextColorsPicker.frame:Hide()
    dispF.barTextColorsPicker = barTextColorsPicker
    dispF.barTextColorsLbl    = barTextColorsLbl

    -- Bar fill color picker — shown below text color for Bar type
    local barFillColorsLbl = dispF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(barFillColorsLbl, 12, "")
    barFillColorsLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(barFillColorsLbl, "Bar Fill Color")
    barFillColorsLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -240)
    barFillColorsLbl:Hide()

    local barFillColorsPicker = CreateColorPicker(dispF, nil,
        function()
            local c = dispF._alert and dispF._alert.barColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return unpack(NSRT.ReminderSettings.BarSettings.barColors)
        end,
        function(_, r, g, b, a) if dispF._alert then NSI:SaveAlertData(dispF._alert, "barColors", {r, g, b, a}) end end,
        200, 22, "NSUIEncAlertBarFillColors")
    barFillColorsPicker:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -240)
    barFillColorsPicker.frame:Hide()
    dispF.barFillColorsPicker = barFillColorsPicker
    dispF.barFillColorsLbl    = barFillColorsLbl

    -- Patch SetDisplayType to toggle type-specific sections and relabel the color picker
    local _prevSetDisplayType = SetDisplayType
    SetDisplayType = function(t)
        _prevSetDisplayType(t)
        local isBar    = t == "Bar"
        local isCircle = t == "Circle"
        -- Shared color row: hide for Bar (replaced by two bar-specific rows)
        dispF.colorsLbl:SetShown(not isBar)
        dispF.colorsPicker.frame:SetShown(not isBar)
        -- Bar-specific rows
        dispF.barTextColorsLbl:SetShown(isBar)
        dispF.barTextColorsPicker.frame:SetShown(isBar)
        dispF.barFillColorsLbl:SetShown(isBar)
        dispF.barFillColorsPicker.frame:SetShown(isBar)
        -- Type sections
        barsSection:SetShown(isBar)
        circleSection:SetShown(isCircle)
        -- HideSwipe only relevant for Icon type
        dispF.hideSwipeCB.frame:SetShown(t == "Icon")
        -- Label for the shared picker (used for non-Bar types)
        local COLOR_LABELS = { Text=NSI:Loc("Text Color"), Icon=NSI:Loc("Text Color"), Circle=NSI:Loc("Text Color") }
        dispF.colorsLbl:SetText(COLOR_LABELS[t] or NSI:Loc("Color"))
        if dispF.colorsPicker then dispF.colorsPicker:Refresh() end
    end
    dispF.SetDisplayType = SetDisplayType
    end -- DISPLAY TAB

    -- ================================================================
    -- TRIGGER TAB
    -- ================================================================
    do
    trigF = innerTabFrames["Trigger"]

    local trigBossLbl = trigF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(trigBossLbl, 12, "")
    trigBossLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(trigBossLbl, "Boss")
    trigBossLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -2)

    local function BuildTrigBossOptions()
        return BossData.BuildBossDropdownOptions(function(v)
            if not trigF._alert or not selectedEncID or v == selectedEncID then return end
            -- Move the alert from the old encID bucket to the new one
            local fromAlerts = NSRT.EncounterAlerts and NSRT.EncounterAlerts[selectedEncID]
                           and NSRT.EncounterAlerts[selectedEncID][filterDiffID]
            if not fromAlerts then return end
            local foundKey
            for k, a in pairs(fromAlerts) do
                if a == trigF._alert then foundKey = k; break end
            end
            if not foundKey then return end
            local oldEncID = selectedEncID
            fromAlerts[foundKey] = nil
            NSRT.EncounterAlerts[v] = NSRT.EncounterAlerts[v] or {}
            NSRT.EncounterAlerts[v][filterDiffID] = NSRT.EncounterAlerts[v][filterDiffID] or {}
            NSRT.EncounterAlerts[v][filterDiffID][foundKey] = trigF._alert
            selectedEncID = v
            selectedKey = foundKey
            filterEncID = v
            NSI:FireCallback("NSRT_ALERT_CHANGED", oldEncID, filterDiffID, foundKey)
            NSI:FireCallback("NSRT_ALERT_CHANGED", v, filterDiffID, foundKey)
            filterDD:Refresh()
            RebuildList()
        end, false)
    end

    local function getTrigBossSelected()
        if not selectedEncID then return "?" end
        for _, opt in ipairs(BossData.BuildBossDropdownOptions(nil, false)) do
            if opt.value == selectedEncID then return opt.label end
        end
        return tostring(selectedEncID)
    end

    local trigBossDD = CreateDropdown(trigF, nil, BuildTrigBossOptions, getTrigBossSelected,
        200, 22, "NSUIEncAlertTrigBoss")
    trigBossDD:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -18)
    trigF.bossDD = trigBossDD

    -- Difficulty dropdown — moves the alert to a different diff table on change
    local TRIG_DIFF_NAMES = { [14] = NSI:Loc("Normal"), [15] = NSI:Loc("Heroic"), [16] = NSI:Loc("Mythic") }

    local trigDiffLbl = trigF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(trigDiffLbl, 12, "")
    trigDiffLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(trigDiffLbl, "Difficulty")
    trigDiffLbl:SetPoint("TOPLEFT", trigBossDD.frame, "TOPRIGHT", 6, 16)

    local function BuildTrigDiffOptions()
        local opts = {}
        for _, diffID in ipairs({ 14, 15, 16 }) do
            local id = diffID
            opts[#opts + 1] = {
                label = TRIG_DIFF_NAMES[id],
                value = id,
                onclick = function(_, _, val)
                    if not trigF._alert or not selectedEncID or val == filterDiffID then return end
                    local fromAlerts = NSRT.EncounterAlerts and NSRT.EncounterAlerts[selectedEncID]
                                   and NSRT.EncounterAlerts[selectedEncID][filterDiffID]
                    if not fromAlerts then return end
                    local alertToMove = trigF._alert
                    local foundKey
                    for k, a in pairs(fromAlerts) do
                        if a == alertToMove then foundKey = k; break end
                    end
                    if not foundKey then return end
                    local oldDiffID = filterDiffID
                    fromAlerts[foundKey] = nil
                    NSRT.EncounterAlerts[selectedEncID][val] = NSRT.EncounterAlerts[selectedEncID][val] or {}
                    local toTable = NSRT.EncounterAlerts[selectedEncID][val]
                    local newKey = NSI:UniqueAlertID(toTable, false)
                    toTable[newKey] = alertToMove
                    filterDiffID = val
                    selectedKey = newKey
                    NSI:FireCallback("NSRT_ALERT_CHANGED", selectedEncID, oldDiffID, foundKey)
                    NSI:FireCallback("NSRT_ALERT_CHANGED", selectedEncID, val, newKey)
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
    NSI:SetUIFont(phaseLbl, 12, "")
    phaseLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(phaseLbl, "Phase")
    phaseLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -50)

    local phaseEntry = CreateTextEntry(trigF, nil, nil, nil, 60, 22,
        nil, nil, nil, "NSUIEncAlertPhase")
    phaseEntry:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -66)
    phaseEntry.editBox:SetScript("OnEditFocusLost", function(self)
        if trigF._alert then
            NSI:SaveAlertData(trigF._alert, "phase", math.max(1, math.floor(tonumber(self:GetText()) or 1)))
            RebuildList()
        end
    end)
    trigF.phaseEntry = phaseEntry

    local timesLbl = trigF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(timesLbl, 12, "")
    timesLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(timesLbl, "Trigger Times (seconds into phase)")
    timesLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -98)

    -- Times list: native ScrollFrame
    local timesListH = 150
    local timesListW = rightW - 20

    local timesScroll = CreateFrame("ScrollFrame", "NSUIEncAlertTimesScroll", trigF,
        "UIPanelScrollFrameTemplate")
    timesScroll:SetSize(timesListW, timesListH)
    timesScroll:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -114)
    ReskinScrollbar(timesScroll)
    local timesBg = timesScroll:CreateTexture(nil, "BACKGROUND")
    timesBg:SetAllPoints(timesScroll)
    timesBg:SetColorTexture(0.04, 0.04, 0.04, 0.85)

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
        if not trigF._alert then return end
        local times = trigF._alert.timers or {}
        for i, t in ipairs(times) do
            if not timeRows[i] then
                timeRows[i] = CreateFrame("Frame", nil, timesChild)
                timeRows[i]:SetSize(timesChild:GetWidth(), timeRowH)
                timeRows[i]:SetPoint("TOPLEFT", timesChild, "TOPLEFT", 0, -(i - 1) * timeRowH)
                timeRows[i].bg = timeRows[i]:CreateTexture(nil, "BACKGROUND")
                timeRows[i].bg:SetAllPoints(timeRows[i])
                timeRows[i].tLbl = timeRows[i]:CreateFontString(nil, "OVERLAY")
                timeRows[i].tLbl:SetPoint("LEFT", timeRows[i], "LEFT", 8, 0)
                timeRows[i].tLbl:SetTextColor(1, 1, 1, 1)
                timeRows[i].delBtn = CreateFrame("Button", nil, timeRows[i])
                timeRows[i].delBtn:SetSize(14, 14)
                timeRows[i].delBtn:SetPoint("RIGHT", timeRows[i], "RIGHT", -6, 0)
                timeRows[i].delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                timeRows[i].delBtn:GetNormalTexture():SetDesaturated(true)
                timeRows[i].delBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
            end

            if i % 2 == 0 then
                timeRows[i].bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
            else
                timeRows[i].bg:SetColorTexture(0, 0, 0, 0)
            end

            NSI:SetUIFont(timeRows[i].tLbl, 13, "")
            timeRows[i].tLbl:SetText(string.format("%.2f s", t))

            timeRows[i].delBtn:SetScript("OnClick", function()
                if trigF._alert then
                    table.remove(trigF._alert.timers, i)
                    NSI:SaveAlertData(trigF._alert, "timers", trigF._alert.timers)
                    RebuildTimeRows()
                end
            end)

            timeRows[i]:Show()
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
    NSI:SetUIFont(addTimeLbl, 11, "")
    addTimeLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    SetLocalizedText(addTimeLbl, "Add time (s)")
    addTimeLbl:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -4)

    local addTimeEntry = CreateTextEntry(trigF, nil, nil, nil, 90, 22,
        nil, nil, nil, "NSUIEncAlertAddTime")
    addTimeEntry:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -20)
    trigF.addTimeEntry = addTimeEntry

    local function DoAddTime()
        local v = tonumber(addTimeEntry:GetValue())
        if v and trigF._alert then
            trigF._alert.timers = trigF._alert.timers or {}
            local inserted = false
            for i2, existing in ipairs(trigF._alert.timers) do
                if v < existing then
                    table.insert(trigF._alert.timers, i2, v)
                    inserted = true
                    break
                end
            end
            if not inserted then table.insert(trigF._alert.timers, v) end
            addTimeEntry:SetValue("")
            NSI:FireCallback("NSRT_ALERT_CHANGED", selectedEncID, filterDiffID, selectedKey)
            RebuildTimeRows()
        end
    end

    addTimeEntry.editBox:SetScript("OnEnterPressed", function(self)
        DoAddTime()
        self:ClearFocus()
    end)

    local addTimeBtn = CreateLocalizedSubButton(trigF, "Add", DoAddTime, 54,
        "NSUIEncAlertAddTimeBtn")
    addTimeBtn:SetPoint("LEFT", addTimeEntry.frame, "RIGHT", 6, 0)

    local conditionBtn = CreateLocalizedSubButton(trigF, "Add Condition", OpenConditionEditor, 130,
        "NSUIEncAlertConditionBtn")
    conditionBtn:SetPoint("TOPLEFT", addTimeEntry.frame, "BOTTOMLEFT", 0, -12)
    trigF.conditionBtn = conditionBtn

    -- Lock overlay for Trigger tab (shown when ReloeReminder is selected)
    -- transparent=true so the triggers are still visible, just not interactable
    trigF.lockOverlay = MakeLockOverlay(trigF, nil, true)
    end -- TRIGGER TAB

    -- ================================================================
    -- SOUND TAB
    -- ================================================================
    do
    sndF = innerTabFrames["Sound"]

    sndHint = sndF:CreateFontString(nil, "OVERLAY")
    sndHint:Hide()

    local ttsCB = CreateCheckButton(sndF, NSI:Loc("Enable Text-to-Speech"),
        function() return false end,
        function(_, v)
            if not sndF._alert then return end
            local txt = sndF.ttsTextEntry and sndF.ttsTextEntry:GetValue() or ""
            NSI:SaveAlertData(sndF._alert, "TTS", v and ((txt ~= "") and txt or true) or false)
        end,
        rightW, 22, "NSUIEncAlertTTSCB")
    ttsCB:SetLocaleKey("Enable Text-to-Speech")
    ttsCB:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -4)
    sndF.ttsCB = ttsCB

    local ttsTextLbl = sndF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ttsTextLbl, 12, "")
    ttsTextLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(ttsTextLbl, "TTS Text (leave blank to speak the Display Text)")
    ttsTextLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -34)

    local ttsTextEntry = CreateTextEntry(sndF, nil, nil, nil, rightW, 22,
        nil, nil, nil, "NSUIEncAlertTTSText")
    ttsTextEntry:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -50)
    local function SaveTTSText(self)
        local v = self:GetText()
        if not sndF._alert then return end
        if sndF._alert.TTS ~= false then
            NSI:SaveAlertData(sndF._alert, "TTS", (v ~= "") and v or true)
        end
    end
    ttsTextEntry.editBox:SetScript("OnEditFocusLost", SaveTTSText)
    sndF.ttsTextEntry = ttsTextEntry

    local ttsTimerLbl = sndF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ttsTimerLbl, 12, "")
    ttsTimerLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(ttsTimerLbl, "TTS Timer (seconds before the Alert expires)")
    ttsTimerLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -82)

    local ttsTimerEntry = CreateTextEntry(sndF, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertTTSTimer")
    ttsTimerEntry:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -98)
    local function SaveTTSTimer(self)
        local v = tonumber(self:GetText())
        if sndF._alert then NSI:SaveAlertData(sndF._alert, "TTSTimer", v or 8) end
    end
    ttsTimerEntry.editBox:SetScript("OnEditFocusLost", SaveTTSTimer)
    sndF.ttsTimerEntry = ttsTimerEntry

    local cdLbl = sndF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(cdLbl, 12, "")
    cdLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(cdLbl, "Countdown for")
    cdLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -138)
    sndF.cdLbl = cdLbl

    local cdEntry = CreateTextEntry(sndF, nil, nil, nil, 60, 22,
        nil, nil, nil, "NSUIEncAlertCountdown")
    cdEntry:SetPoint("LEFT", cdLbl, "RIGHT", 6, 0)
    cdEntry:SetPoint("TOP",  cdLbl, "TOP", 0, 6)
    local function SaveCountdown(self)
        local v = tonumber(self:GetText())
        if sndF._alert then NSI:SaveAlertData(sndF._alert, "countdown", (v and v > 0) and v or false) end
    end
    cdEntry.editBox:SetScript("OnEditFocusLost", SaveCountdown)
    sndF.cdEntry = cdEntry

    local cdSecLbl = sndF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(cdSecLbl, 12, "")
    cdSecLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(cdSecLbl, "seconds")
    cdSecLbl:SetPoint("LEFT", cdEntry.frame, "RIGHT", 5, 0)

    local sndFileLbl = sndF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(sndFileLbl, 12, "")
    sndFileLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    SetLocalizedText(sndFileLbl, "Sound File")
    sndFileLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -162)

    local soundGetItems, soundGetSelected = NSI:BuildSoundDropdown(
        function() return sndF._alert and sndF._alert.sound end,
        function(v) if sndF._alert then NSI:SaveAlertData(sndF._alert, "sound", v) end end
    )
    local soundDD = CreateDropdown(sndF, nil, soundGetItems, soundGetSelected,
        rightW, 22, "NSUIEncAlertSound")
    soundDD:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -178)
    sndF.soundDD = soundDD
    end -- SOUND TAB

    -- ================================================================
    -- LOAD TAB
    -- ================================================================
    do
    loadF = innerTabFrames["Load"]

    -- ── Static class / spec data ─────────────────────────────────────────────
    local CLASS_DATA = {
        { key = "WARRIOR",     label = "Warrior" },
        { key = "PALADIN",     label = "Paladin" },
        { key = "HUNTER",      label = "Hunter" },
        { key = "ROGUE",       label = "Rogue" },
        { key = "PRIEST",      label = "Priest" },
        { key = "DEATHKNIGHT", label = "Death Knight" },
        { key = "SHAMAN",      label = "Shaman" },
        { key = "MAGE",        label = "Mage" },
        { key = "WARLOCK",     label = "Warlock" },
        { key = "MONK",        label = "Monk" },
        { key = "DRUID",       label = "Druid" },
        { key = "DEMONHUNTER", label = "Demon Hunter" },
        { key = "EVOKER",      label = "Evoker" },
    }
    local SPEC_DATA = {
        { class="WARRIOR",     id=71,   label="Arms" },
        { class="WARRIOR",     id=72,   label="Fury" },
        { class="WARRIOR",     id=73,   label="Protection" },
        { class="PALADIN",     id=65,   label="Holy" },
        { class="PALADIN",     id=66,   label="Protection" },
        { class="PALADIN",     id=70,   label="Retribution" },
        { class="HUNTER",      id=253,  label="Beast Mastery" },
        { class="HUNTER",      id=254,  label="Marksmanship" },
        { class="HUNTER",      id=255,  label="Survival" },
        { class="ROGUE",       id=259,  label="Assassination" },
        { class="ROGUE",       id=260,  label="Outlaw" },
        { class="ROGUE",       id=261,  label="Subtlety" },
        { class="PRIEST",      id=256,  label="Discipline" },
        { class="PRIEST",      id=257,  label="Holy" },
        { class="PRIEST",      id=258,  label="Shadow" },
        { class="DEATHKNIGHT", id=250,  label="Blood" },
        { class="DEATHKNIGHT", id=251,  label="Frost" },
        { class="DEATHKNIGHT", id=252,  label="Unholy" },
        { class="SHAMAN",      id=262,  label="Elemental" },
        { class="SHAMAN",      id=263,  label="Enhancement" },
        { class="SHAMAN",      id=264,  label="Restoration" },
        { class="MAGE",        id=62,   label="Arcane" },
        { class="MAGE",        id=63,   label="Fire" },
        { class="MAGE",        id=64,   label="Frost" },
        { class="WARLOCK",     id=265,  label="Affliction" },
        { class="WARLOCK",     id=266,  label="Demonology" },
        { class="WARLOCK",     id=267,  label="Destruction" },
        { class="MONK",        id=268,  label="Brewmaster" },
        { class="MONK",        id=269,  label="Windwalker" },
        { class="MONK",        id=270,  label="Mistweaver" },
        { class="DRUID",       id=102,  label="Balance" },
        { class="DRUID",       id=103,  label="Feral" },
        { class="DRUID",       id=104,  label="Guardian" },
        { class="DRUID",       id=105,  label="Restoration" },
        { class="DEMONHUNTER", id=577,  label="Havoc" },
        { class="DEMONHUNTER", id=581,  label="Vengeance" },
        { class="DEMONHUNTER", id=1480, label="Devourer" },
        { class="EVOKER",      id=1467, label="Devastation" },
        { class="EVOKER",      id=1468, label="Preservation" },
        { class="EVOKER",      id=1473, label="Augmentation" },
    }

    local loadRowH   = 20
    local loadListW  = rightW - 20
    local loadListH = 240

    -- ── Names section constants (anchored to bottom of loadF) ────────────────
    local NAMES_SEC_H    = 180   -- total height reserved at the bottom
    local namesListH     = 112   -- height of the names scroll list

    -- ── Main scroll (classes + specs), fills loadF above the names section ───
    -- Height = panel height - rightPanel margins(20) - inner-tab header(68) - names section(NAMES_SEC_H+4)
    local loadScrollH = tab_content_height - 20 - 68 - NAMES_SEC_H - 4
    local loadScroll = CreateFrame("ScrollFrame", "NSUIEncAlertLoadScroll", loadF,
        "UIPanelScrollFrameTemplate")
    loadScroll:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, 0)
    loadScroll:SetSize(loadListW, loadScrollH)
    loadScroll:EnableMouseWheel(true)
    loadScroll:SetScript("OnMouseWheel", function(_, delta)
        local bar = _G["NSUIEncAlertLoadScrollScrollBar"]
        if bar then
            local cur = bar:GetValue()
            local mn, mx = bar:GetMinMaxValues()
            bar:SetValue(math.max(mn, math.min(mx, cur - delta * 20)))
        end
    end)
    ReskinScrollbar(loadScroll)

    local loadScrollChild = CreateFrame("Frame", nil, loadScroll, "BackdropTemplate")
    loadScrollChild:SetSize(loadListW - 18, loadListH)
    loadScrollChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    loadScrollChild:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
    loadScroll:SetScrollChild(loadScrollChild)

    -- Collapse state per section (persists across Rebuild calls)
    local sectionCollapsed = { Roles = true, Classes = true, Specs = true }
    local RebuildLoadTab  -- forward declaration

    local function MakeSectionHdr(label, sectionKey)
        local btn = CreateFrame("Button", nil, loadScrollChild, "BackdropTemplate")
        btn:SetBackdrop({
            bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
            tile     = true,
            tileSize = 64,
        })
        btn:SetBackdropColor(0.05, 0.30, 0.40, 0.9)
        btn:SetSize(loadListW - 18, 18)
        btn.arrowTex = btn:CreateTexture(nil, "OVERLAY")
        btn.arrowTex:SetSize(10, 10)
        btn.arrowTex:SetPoint("LEFT", btn, "LEFT", 2, 0)
        btn.arrowTex:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]])
        btn.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 1)
        btn.textLbl = btn:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(btn.textLbl, 11, "")
        btn.textLbl:SetTextColor(0.55, 0.55, 0.55, 1)
        btn.textLbl:SetPoint("LEFT", btn, "LEFT", 16, 0)
        btn.textLbl:SetText(label)
        btn:SetScript("OnClick", function()
            sectionCollapsed[sectionKey] = not sectionCollapsed[sectionKey]
            if RebuildLoadTab then RebuildLoadTab() end
        end)
        btn:SetScript("OnEnter", function() btn.textLbl:SetTextColor(0.85, 0.85, 0.85, 1) end)
        btn:SetScript("OnLeave", function() btn.textLbl:SetTextColor(0.55, 0.55, 0.55, 1) end)
        return btn
    end

    local function MakeCheckRow(parent)
        local BOX       = 12
        local baseLevel = parent:GetFrameLevel() + 1
        local row = CreateFrame("Button", nil, parent)
        row:SetSize(loadListW - 18, loadRowH)
            row:SetFrameLevel(baseLevel)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        row.bg:SetColorTexture(0, 0, 0, 0)
        -- Cyan hover overlay (fades in/out on mouse enter/leave)
        local hoverBg = CreateFrame("Frame", nil, row)
        hoverBg:SetAllPoints(row)
        hoverBg:SetFrameLevel(baseLevel + 1)
        hoverBg:EnableMouse(false)
        local hoverTex = hoverBg:CreateTexture(nil, "BACKGROUND")
        hoverTex:SetAllPoints()
        hoverTex:SetColorTexture(0, 1, 1, 0.13)
        hoverBg:SetAlpha(0)
        row.hoverBg = hoverBg

        -- Checkbox box (styled like Components.lua CreateCheckButton)
        local checkBox = CreateFrame("Frame", nil, row, "BackdropTemplate")
        checkBox:SetSize(BOX, BOX)
        checkBox:SetPoint("LEFT", row, "LEFT", 4, 0)
        checkBox:SetFrameLevel(baseLevel + 2)
        checkBox:SetBackdrop({
            bgFile   = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        })
        checkBox:SetBackdropColor(0.10, 0.10, 0.10, 0.9)
        checkBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        row.checkBox = checkBox

        -- Cyan fill shown when selected
        local checkFill = checkBox:CreateTexture(nil, "ARTWORK")
        checkFill:SetPoint("TOPLEFT", checkBox, "TOPLEFT", 2, -2)
        checkFill:SetPoint("BOTTOMRIGHT", checkBox, "BOTTOMRIGHT", -2, 2)
        checkFill:SetColorTexture(0, 1, 1, 0.85)
        checkFill:Hide()
        row.checkFill = checkFill

        -- Label in its own frame above the hover overlay
        local lblFrame = CreateFrame("Frame", nil, row)
        lblFrame:SetFrameLevel(baseLevel + 2)
        lblFrame:EnableMouse(false)
        lblFrame:SetPoint("LEFT", row, "LEFT", 22, 0)
        lblFrame:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        lblFrame:SetHeight(loadRowH)

        row.nameLbl = lblFrame:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.nameLbl, 12, "")
        row.nameLbl:SetAllPoints(lblFrame)
        row.nameLbl:SetJustifyH("LEFT")
        row.nameLbl:SetJustifyV("MIDDLE")

        row:SetScript("OnEnter", function()
            UIFrameFadeIn(hoverBg, 0.12, hoverBg:GetAlpha(), 1)
        end)
        row:SetScript("OnLeave", function()
            UIFrameFadeOut(hoverBg, 0.20, hoverBg:GetAlpha(), 0)
        end)
        return row
    end

    -- Section header buttons (repositioned and arrow updated in RebuildLoadTab)
    local classSecHdr = MakeSectionHdr(NSI:Loc("Classes (leave all unchecked for any class)"), "Classes")
    local specSecHdr  = MakeSectionHdr(NSI:Loc("Specializations (leave all unchecked for any spec)"), "Specs")

    -- Pre-create class rows (one per class, fixed set)
    local classRowFrames = {}
    for i, cd in ipairs(CLASS_DATA) do
        local row = MakeCheckRow(loadScrollChild)
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[cd.key]
        if cc then row.nameLbl:SetTextColor(cc.r, cc.g, cc.b, 1)
        else        row.nameLbl:SetTextColor(1, 1, 1, 1) end
        row.nameLbl:SetText(cd.label)
        row._classKey = cd.key
        classRowFrames[i] = row
        row:Hide()
    end

    -- Pre-create spec rows (one per spec, fixed set)
    local specRowFrames = {}
    for i, sd in ipairs(SPEC_DATA) do
        local row = MakeCheckRow(loadScrollChild)
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[sd.class]
        if cc then row.nameLbl:SetTextColor(cc.r * 0.8 + 0.2, cc.g * 0.8 + 0.2, cc.b * 0.8 + 0.2, 1)
        else       row.nameLbl:SetTextColor(0.85, 0.85, 0.85, 1) end
        row.nameLbl:SetText(sd.label)
        row._specID   = sd.id
        row._classKey = sd.class
        specRowFrames[i] = row
        row:Hide()
    end

    local ROLE_DATA = {
        { key = "TANK",    label = "Tank" },
        { key = "HEALER",  label = "Healer" },
        { key = "DAMAGER", label = "DPS" },
        { key = "MELEE",   label = "Melee" },
        { key = "RANGED",  label = "Ranged" },
    }
    local ROLE_COLORS = {
        TANK    = { 0.3, 0.5, 1.0 },
        HEALER  = { 0.3, 0.9, 0.3 },
        DAMAGER = { 0.9, 0.2, 0.2 },
        MELEE   = { 0.95, 0.55, 0.2 },
        RANGED  = { 0.9, 0.8, 0.2 },
    }

    local rolesSecHdr = MakeSectionHdr(NSI:Loc("Roles (leave all unchecked for any role)"), "Roles")

    local roleRowFrames = {}
    for i, rd in ipairs(ROLE_DATA) do
        local row = MakeCheckRow(loadScrollChild)
        local rc = ROLE_COLORS[rd.key]
        row.nameLbl:SetTextColor(rc[1], rc[2], rc[3], 1)
        row.nameLbl:SetText(rd.label)
        row._roleKey = rd.key
        roleRowFrames[i] = row
        row:Hide()
    end

    -- ── Names section (fixed at bottom of loadF) ──────────────────────────────
    local namesHdrLbl = loadF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(namesHdrLbl, 11, "")
    namesHdrLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    SetLocalizedText(namesHdrLbl, "Character Names (no server name)")
    namesHdrLbl:SetPoint("BOTTOMLEFT", loadF, "BOTTOMLEFT", 0, NAMES_SEC_H - 12)

    local nameAddEntry = CreateTextEntry(loadF, nil, nil, nil, 180, 22,
        nil, nil, nil, "NSUIEncAlertNameAdd")
    nameAddEntry:SetPoint("BOTTOMLEFT", loadF, "BOTTOMLEFT", 0, NAMES_SEC_H - 36)

    local DoAddName  -- forward declaration so nameAddBtn closure can reference it
    local nameAddBtn = CreateLocalizedSubButton(loadF, "Add", function() if DoAddName then DoAddName() end end,
        54, "NSUIEncAlertNameAddBtn")
    nameAddBtn:SetPoint("LEFT", nameAddEntry.frame, "RIGHT", 6, 0)

    local namesScroll = CreateFrame("ScrollFrame", "NSUIEncAlertNamesScroll", loadF,
        "UIPanelScrollFrameTemplate")
    namesScroll:SetSize(loadListW, namesListH)
    namesScroll:SetPoint("BOTTOMLEFT", loadF, "BOTTOMLEFT", 0, 4)
    namesScroll:EnableMouseWheel(true)
    namesScroll:SetScript("OnMouseWheel", function(_, delta)
        local bar = _G["NSUIEncAlertNamesScrollScrollBar"]
        if bar then
            local cur = bar:GetValue()
            local mn, mx = bar:GetMinMaxValues()
            bar:SetValue(math.max(mn, math.min(mx, cur - delta * 20)))
        end
    end)
    ReskinScrollbar(namesScroll)
    local namesBg = namesScroll:CreateTexture(nil, "BACKGROUND")
    namesBg:SetAllPoints(namesScroll)
    namesBg:SetColorTexture(0.04, 0.04, 0.04, 0.85)

    local namesChild = CreateFrame("Frame", nil, namesScroll, "BackdropTemplate")
    namesChild:SetSize(loadListW - 18, 1)
    namesChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    namesChild:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
    namesScroll:SetScrollChild(namesChild)

    local nameRowH  = 20
    local nameRows  = {}

    local function RebuildNameRows()
        for _, row in ipairs(nameRows) do row:Hide() end
        if not loadF._alert then return end
        local cond = loadF._alert.loadConditions
        if not (cond and cond.Names) then return end
        local i = 0
        for name, _ in pairs(cond.Names) do
            i = i + 1
            if not nameRows[i] then
                nameRows[i] = CreateFrame("Frame", nil, namesChild)
                nameRows[i]:SetSize(namesChild:GetWidth(), nameRowH)
                nameRows[i].bg = nameRows[i]:CreateTexture(nil, "BACKGROUND")
                nameRows[i].bg:SetAllPoints(nameRows[i])
                nameRows[i].nLbl = nameRows[i]:CreateFontString(nil, "OVERLAY")
                NSI:SetUIFont(nameRows[i].nLbl, 12, "")
                nameRows[i].nLbl:SetPoint("LEFT", nameRows[i], "LEFT", 8, 0)
                nameRows[i].nLbl:SetTextColor(1, 1, 1, 1)
                nameRows[i].delBtn = CreateFrame("Button", nil, nameRows[i])
                nameRows[i].delBtn:SetSize(14, 14)
                nameRows[i].delBtn:SetPoint("RIGHT", nameRows[i], "RIGHT", -6, 0)
                nameRows[i].delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                nameRows[i].delBtn:GetNormalTexture():SetDesaturated(true)
                nameRows[i].delBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
            end
            nameRows[i]:ClearAllPoints()
            nameRows[i]:SetPoint("TOPLEFT", namesChild, "TOPLEFT", 0, -(i - 1) * nameRowH)
            nameRows[i].bg:SetColorTexture(i % 2 == 0 and 0.2 or 0, i % 2 == 0 and 0.2 or 0,
                i % 2 == 0 and 0.2 or 0, i % 2 == 0 and 0.9 or 0)
            nameRows[i].nLbl:SetText(name)
            local capName = name
            nameRows[i].delBtn:SetScript("OnClick", function()
                if loadF._alert and loadF._alert.loadConditions
                        and loadF._alert.loadConditions.Names then
                    loadF._alert.loadConditions.Names[capName] = nil
                    NSI:SaveAlertData(loadF._alert, "loadConditions", loadF._alert.loadConditions)
                    RebuildNameRows()
                    RebuildList()
                end
            end)
            nameRows[i]:Show()
        end
        namesChild:SetHeight(math.max(i * nameRowH, 1))
        local bar = _G["NSUIEncAlertNamesScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, i * nameRowH - namesListH)
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end
    end

    DoAddName = function()
        if not loadF._alert then return end   -- no alert selected, nothing to write to
        local v = nameAddEntry:GetValue()
        if not v or v == "" then return end
        loadF._alert.loadConditions = loadF._alert.loadConditions or {}
        loadF._alert.loadConditions.Names = loadF._alert.loadConditions.Names or {}
        loadF._alert.loadConditions.Names[v] = true
        NSI:SaveAlertData(loadF._alert, "loadConditions", loadF._alert.loadConditions)
        nameAddEntry:SetValue("")
        RebuildNameRows()
        RebuildList()
    end
    nameAddEntry.editBox:SetScript("OnEnterPressed", function(self)
        DoAddName(); self:ClearFocus()
    end)

    -- ── RebuildLoadTab — main function called on SelectAlert / tab selection ──
    RebuildLoadTab = function()
        if not loadF._alert then return end
        local alert = loadF._alert
        alert.loadConditions = alert.loadConditions or {}
        alert.loadConditions.Classes = alert.loadConditions.Classes or {}
        alert.loadConditions.SpecIDs = alert.loadConditions.SpecIDs or {}
        alert.loadConditions.Roles   = alert.loadConditions.Roles   or {}
        alert.loadConditions.Names   = alert.loadConditions.Names   or {}
        local cond = alert.loadConditions

        local y    = 0
        local hdrH = 18
        local gapH = 4

        local function LayoutSection(hdrBtn, rows, dataList, collapsedKey, isSelected, onToggle, colorFn)
            hdrBtn:ClearAllPoints()
            hdrBtn:SetPoint("TOPLEFT", loadScrollChild, "TOPLEFT", 0, -y)
            local collapsed = sectionCollapsed[collapsedKey]
            -- Flip arrow chevron vertically when collapsed
            if collapsed then
                    hdrBtn.arrowTex:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]])
            else
                    hdrBtn.arrowTex:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-up.png]])
            end
            y = y + hdrH + 2

            for i, data in ipairs(dataList) do
                local row = rows[i]
                if collapsed then
                    row:Hide()
                else
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", loadScrollChild, "TOPLEFT", 0, -y)
                    local selected = isSelected(data)
                    if selected then
                        local r, g, b = colorFn(data)
                        row.bg:SetColorTexture(r * 0.3, g * 0.3, b * 0.3, 0.85)
                            row.checkFill:Show()
                            row.checkBox:SetBackdropBorderColor(0, 1, 1, 0.9)
                    else
                        row.bg:SetColorTexture(
                            i % 2 == 0 and 0.12 or 0,
                            i % 2 == 0 and 0.12 or 0,
                            i % 2 == 0 and 0.12 or 0,
                            i % 2 == 0 and 0.5 or 0)
                            row.checkFill:Hide()
                            row.checkBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
                    end
                    local d = data
                    row:SetScript("OnClick",
                    function()
                        onToggle(d, cond);
                        RebuildLoadTab()
                        RebuildList()
                    end)
                    row:Show()
                    y = y + loadRowH
                end
            end
            y = y + gapH
        end

        LayoutSection(rolesSecHdr, roleRowFrames, ROLE_DATA, "Roles",
            function(d) return cond.Roles[d.key] end,
            function(d, c)
                if c.Roles[d.key] then c.Roles[d.key] = nil else c.Roles[d.key] = true end
                NSI:SaveAlertData(alert, "loadConditions", alert.loadConditions)
            end,
            function(d) local rc = ROLE_COLORS[d.key]; return rc[1], rc[2], rc[3] end)

        LayoutSection(classSecHdr, classRowFrames, CLASS_DATA, "Classes",
            function(d) return cond.Classes[d.key] end,
            function(d, c)
                if c.Classes[d.key] then c.Classes[d.key] = nil else c.Classes[d.key] = true end
                NSI:SaveAlertData(alert, "loadConditions", alert.loadConditions)
            end,
            function(d)
                local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[d.key]
                return cc and cc.r or 0.5, cc and cc.g or 0.8, cc and cc.b or 0.5
            end)

        LayoutSection(specSecHdr, specRowFrames, SPEC_DATA, "Specs",
            function(d) return cond.SpecIDs[d.id] end,
            function(d, c)
                if c.SpecIDs[d.id] then c.SpecIDs[d.id] = nil else c.SpecIDs[d.id] = true end
                NSI:SaveAlertData(alert, "loadConditions", alert.loadConditions)
            end,
            function(d)
                local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[d.class]
                return cc and cc.r or 0.5, cc and cc.g or 0.8, cc and cc.b or 0.5
            end)

        loadScrollChild:SetHeight(math.max(y, loadListH))
        local bar = _G["NSUIEncAlertLoadScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, y - loadScroll:GetHeight())
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end

        RebuildNameRows()
    end
    loadF.Rebuild = RebuildLoadTab

    -- Lock overlay for Load tab (reloeCreated alerts use built-in role field)
    loadF.lockOverlay = MakeLockOverlay(loadF,
        "Class / spec filters do not apply\nto addon-created alerts.")

    -- Lock overlay for Sound tab (reloeCreated alerts — sound is managed by the addon)
    sndF.lockOverlay = MakeLockOverlay(sndF,
        "Sound settings are fixed\nfor addon-created alerts.")
    end -- LOAD TAB

    -- ================================================================
    -- OPTIONS TAB
    -- ================================================================
    do
    local optF = innerTabFrames["Options"]
    local optionsContentFrame = nil

    RebuildOptionsContent = function(entry)
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
    end -- OPTIONS TAB

    -- ================================================================
    -- Helper: set panel into custom-alert mode vs reloeCreated mode
    -- ================================================================
    local function SetCustomMode()
        trigF.lockOverlay:Hide()
        loadF.lockOverlay:Hide()
        sndF.lockOverlay:Hide()
        dispHint:Hide()
        sndHint:Hide()
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
        nameEntry.editBox:SetEnabled(false)
        nameEntry.editBox:SetAlpha(0.45)
    end

    -- ================================================================
    -- PreviewAlert ── fire the current alert visually without a trigger
    -- ================================================================
    PreviewAlert = function()
        if not dispF._alert then return end
        if dispF._alert.Preview then -- allow custom preview functions
            local preview = dispF._alert.Preview
            if type(preview) == "string" then
                local fn, err = loadstring(preview)
                if fn then
                    fn()(NSI)
                else
                    print("|cFFFF0000NSRT Preview error:|r", err)
                end
            else
                preview()
            end
            return
        end
        if NSI:IsUsingTLAlerts() then print("|cFFFF0000NSRT :|r Preview is disabled because you are displaying alerts through TimelineReminders.") return end
        local info = NSI:CreateReminder(dispF._alert, true)
        NSI:HideAllReminders()
        NSI:DisplayReminder(info, true)
    end

    -- ================================================================
    -- ================================================================
    -- SelectAlert ── load any alert (Reloe or user-created) into the right panel
    -- ================================================================
    SelectAlert = function(key, diffID, encID)
        selectedKey    = key
        selectedEncID  = encID or selectedEncID
        selectedDiffID = diffID or selectedDiffID

        local entry = NSRT.EncounterAlerts and NSRT.EncounterAlerts[selectedEncID]
                  and NSRT.EncounterAlerts[selectedEncID][selectedDiffID]
                  and NSRT.EncounterAlerts[selectedEncID][selectedDiffID][key]
        if not entry then
            rightPanel:Hide()
            RebuildList()
            return
        end

        local isReloe = entry.ReloeReminder == true
        rightPanel:Show()
        if isReloe then SetReloeCreatedMode() else SetCustomMode() end
        PositionInnerTabLayout(GetConditionText(entry.isConditional))

        dispF._alert = entry; dispF._hardcodedEncID = nil
        trigF._alert = isReloe and nil or entry; trigF._hardcodedEncID = nil
        sndF._alert  = entry; sndF._hardcodedEncID  = nil
        loadF._alert = entry; loadF._hardcodedEncID = nil

        -- Header
        nameEntry:SetValue(isReloe and ReloeAlertName(entry) or (entry.name or ""))
        groupDD._eid  = selectedEncID
        groupDD._did  = selectedDiffID
        groupDD._akey = selectedKey
        groupDD:Refresh()
        enabledCB:SetValue(entry.enabled ~= false)
        if not isReloe then
            nameEntry.editBox:SetScript("OnEditFocusLost", function(self)
                entry.name = self:GetText()
                RebuildList()
            end)
        end
        enabledCB:SetOnChange(function(nsi, v)
            NSI:SaveAlertData(entry, "enabled", v)
            entry.enabled = v
            if entry.ReloeReminder then
                NSI:SaveAlertData(entry, "UserModifiedEnabled", true)
                entry.UserModifiedEnabled = true
            end
            RebuildList()
        end)

        -- Display tab
        dispF.SetDisplayType(entry.DisplayType or "Text")
        dispF.textEntry:SetValue(entry.text or "")
        dispF.spellEntry:SetValue(entry.spellID and tostring(entry.spellID) or "")
        dispF.useTauntCB:SetValue(entry.isTaunt == true)
        do  -- sync spell icon preview
            local spell = entry.spellID and C_Spell.GetSpellInfo(entry.spellID)
            if spell and spell.iconID then
                dispF.spellIconFrame.texture:SetTexture(spell.iconID)
                dispF.spellIconFrame:Show()
            else
                dispF.spellIconFrame:Hide()
            end
        end
        dispF.customIconEntry:SetValue(entry.customIcon and tostring(entry.customIcon) or "")
        dispF.durEntry:SetValue(tostring(entry.dur or 8))
        dispF.stickyEntry:SetValue(entry.sticky and tostring(entry.sticky) or "")
        local typeMap = { Text="TextSettings", Icon="IconSettings", Circle="CircleSettings", Bar="BarSettings" }
        local s = NSRT.ReminderSettings[typeMap[entry.DisplayType or "Text"] or "TextSettings"]
        dispF.hideTimerCB:SetValue(entry.HideTimer ~= nil and entry.HideTimer or (s and s.HideTimerText or false))
        dispF.hideSwipeCB:SetValue(entry.HideSwipe ~= nil and entry.HideSwipe or (NSRT.ReminderSettings.IconSettings.HideSwipe or false))
        local showBg = entry.showBackground ~= nil and entry.showBackground or NSRT.ReminderSettings.CircleSettings.showBackground
        dispF.showBgCB:SetValue(showBg ~= false)
        dispF.glowunitEntry:SetValue(entry.glowunit or "")
        dispF.colorsPicker:Refresh()
        dispF.circleTextureDD:Refresh()
        dispF.ringColorsPicker:Refresh()
        dispF.barTextColorsPicker:Refresh()
        dispF.barFillColorsPicker:Refresh()
        dispF.RebuildTickRows()

        -- Trigger tab
        trigF.bossDD:Refresh()
        trigF.trigDiffDD:Refresh()
        trigF.phaseEntry:SetValue(tostring(entry.phase or 1))
        trigF.RebuildTimeRows()
        trigF.conditionBtn:SetText(NSI:Loc(entry.isConditional and "Edit Condition" or "Add Condition"))

        -- Sound tab
        local ttsActive = entry.TTS ~= false and entry.TTS ~= nil
        sndF.ttsCB:SetValue(ttsActive)
        sndF.ttsTextEntry:SetValue(type(entry.TTS) == "string" and entry.TTS or "")
        sndF.ttsTimerEntry:SetValue(tostring(entry.TTSTimer or entry.dur or 8))
        local hasCD = entry.countdown and entry.countdown ~= false
        sndF.cdEntry:SetValue(hasCD and tostring(entry.countdown) or "")
        sndF.soundDD:Refresh()

        -- Load tab
        loadF.Rebuild()

        -- Options tab: only visible for Reloe alerts that define extraOptions
        local hasOptions = isReloe and entry.extraOptions ~= nil
        innerTabBtns["Options"].frame:SetShown(hasOptions)
        if hasOptions then
            RebuildOptionsContent(entry)
        else
            if activeInnerTab == "Options" then activeInnerTab = "Display" end
        end

        RebuildList()
        SelectInnerTab(activeInnerTab)
        RefreshSectionCopyButtons()
    end

    SelectInnerTab("Display")
    RefreshSectionCopyButtons()

    screen:SetScript("OnShow", function()
        RebuildList()
        if selectedEncID and selectedKey then
            SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
        end
    end)

    return screen
end

local function BuildEncounterAlertsOptions()
    return {
    }
end

local function BuildEncounterAlertsCallback()
    return function()
        if NSRT.Alerts and NSRT.Alerts.Groups then
            for _, gdata in pairs(NSRT.Alerts.Groups) do
                if type(gdata) == "table" then
                    gdata.collapsed = true
                end
            end
        end
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.EncounterAlerts = {
    BuildEncounterAlertsUI = BuildEncounterAlertsUI,
}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.EncounterAlerts = {
    BuildOptions = BuildEncounterAlertsOptions,
    BuildCallback = BuildEncounterAlertsCallback,
}
