local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Accent = STYLE.Accent
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
local CreateLabel         = NSI.UI.Components.CreateLabel
local ReskinScrollbar     = NSI.UI.Components.ReskinScrollbar
local ShowContextMenu     = NSI.UI.Components.ShowContextMenu
local CreateStyledFrame   = NSI.UI.Components.CreateFrame
local BossData          = NSI.UI.BossData

local function SetLocalizedText(object, key)
    NSI.UI.Components.RegisterLocalizedText(object, key)
end

local Parts = NSI.UI.EncounterAlertParts
local Helpers = Parts.Helpers
local CIRCLE_TEXTURES                = Helpers.CIRCLE_TEXTURES
local GetCircleTextureLabel          = Helpers.GetCircleTextureLabel
local GetDefaultCircleTextureLabel   = Helpers.GetDefaultCircleTextureLabel
local FormatPhaseValue               = Helpers.FormatPhaseValue
local ParsePhaseValue                = Helpers.ParsePhaseValue
local GetPhaseList                   = Helpers.GetPhaseList
local InsertSortedTimer              = Helpers.InsertSortedTimer
local FlattenPhaseTimers             = Helpers.FlattenPhaseTimers
local BuildPhaseTimersFromFlatTimers = Helpers.BuildPhaseTimersFromFlatTimers
local ShowExportPopup                = Parts.Popups.ShowExportPopup
local ShowImportPopup                = Parts.Popups.ShowImportPopup

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
    -- forward declarations
    local rightPanel, SelectAlert, PreviewAlert, enabledCB, groupDD
    local copySectionBtn, applySectionBtn, previewBtn, tabSep, conditionHint
    local RebuildList, CanCopySection, ApplyCopiedSectionTo, SECTION_COPY_FIELDS, CopyValue

    -- ================================================================
    -- Left Panel ── title, filter, list, create button
    -- ================================================================
    local title = screen:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, "title")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText(NSI.UI.Style.Tint(NSI:Loc("|cFF00FFFFEncounter|r Alerts")))
    NSI.UI.Style.TrackAccentText(title)

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
        bossDDWidth, 22, "NSUIEncAlertFilter", nil, 10)
    filterDD:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 20)

    local function BuildDiffOptions()
        local function switchDiff(id)
            filterDiffID = id
            if rightPanel then rightPanel:Hide() end
            if screen.RebuildList then screen.RebuildList() end
        end
        return {
            { label = NSI:Loc("Mythic"), value = 16, onclick = function() switchDiff(16) end },
            { label = NSI:Loc("Heroic"), value = 15, onclick = function() switchDiff(15) end },
            { label = NSI:Loc("Normal"), value = 14, onclick = function() switchDiff(14) end },
        }
    end

    local function getDiffSelected()
        local names = { [16] = "Mythic", [15] = "Heroic", [14] = "Normal" }
        return NSI:Loc(names[filterDiffID]) or tostring(filterDiffID)
    end

    local diffDD = CreateDropdown(screen, nil, BuildDiffOptions, getDiffSelected,
        diffDDWidth, 22, "NSUIEncAlertDiffFilter")
    diffDD:SetPoint("TOPLEFT", filterDD.frame, "TOPRIGHT", 6, 0)

    -- ── List filter: narrows the alerts you can select from ─────────────────
    local searchEntry = NSI.UI.Components.CreateSearchBox(screen, leftWidth - pad * 2, 22, "NSUIEncAlertSearch", function(text)
        searchText = text
        if screen.RebuildList then screen.RebuildList() end
    end)
    searchEntry:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 20 - 22 - 4)

    local reloeImportCB = CreateCheckButton(screen, NSI:Loc("Automatically Enable New Alerts"),
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
        leftWidth - pad * 2, 22, "NSUIEncAlertReloeImportCB")
    reloeImportCB:SetLocaleKey("Automatically Enable New Alerts")
    reloeImportCB:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 20 - 22 - 4 - 22 - 6)
    NSI:SetUIFont(reloeImportCB.label, "tiny", "")

    -- ── Native ScrollFrame list ─────────────────────────────────────────────
    local scrollTop    = topY - 20 - 22 - 4 - 22 - 6 - 26
    local scrollHeight = tab_content_height + scrollTop - 18 - pad * 2 - 20 - 20 - 2  -- extra rows: import/export(18+2), additional-options(18+2)
    local listW        = leftWidth - pad * 2   -- 220

    local listScroll = CreateFrame("ScrollFrame", "NSUIEncAlertListScroll", screen,
        "UIPanelScrollFrameTemplate")
    NSI.UI.Components.EnableSmoothScroll(listScroll)
    listScroll:SetWidth(listW)
    listScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, scrollTop)
    -- bottom edge sits above the Create / Import / Export rows, so it follows the window
    listScroll:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, tab_content_height + scrollTop - scrollHeight - 0)
    ReskinScrollbar(listScroll)

    local listChild = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, listScroll)
    listChild:SetSize(listW, 1)   -- 18px for the native scrollbar
    listChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    listChild:SetBackdropColor(unpack(STYLE.surface_inset_soft))
    listScroll:SetScrollChild(listChild)

    -- Dynamic row pools — rows are created on demand and reused across rebuilds
    local listRows        = {}
    local groupHeaderRows = {}

    local function CreateListRow()
        local row = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, listChild)
        row:SetSize(listChild:GetWidth(), lineHeight)
        NSI.UI.Components.StyleRow(row)

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
        row.bossIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        row.nameLabel = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.nameLabel, "label", "")
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
        row.deleteBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.danger))

        -- Ungroup button: replaces delete/lock slot when the row is inside a group
        row.ungroupBtn = CreateFrame("Button", nil, row)
        row.ungroupBtn:SetSize(14, 14)
        row.ungroupBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.ungroupBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\minus.png]])
        row.ungroupBtn:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\minus.png]])
        NSI.UI.Style.PaintAccent(row.ungroupBtn:GetNormalTexture(), "SetVertexColor", 1)
        row.ungroupBtn:GetHighlightTexture():SetVertexColor(0.7, 1, 1, 1)
        row.ungroupBtn:Hide()

        -- Pin indicator (shown when alert is pinned to top)
        row.pinIcon = row:CreateTexture(nil, "OVERLAY")
        row.pinIcon:SetSize(12, 12)
        row.pinIcon:SetTexture([[Interface\Addons\NorthernSkyRaidTools\Media\Icons\pin.png]])
        row.pinIcon:SetVertexColor(189/255, 142/255, 69/255, 1)
        row.pinIcon:Hide()

        row:EnableMouse(true)
        row:Hide()
        return row
    end

    local function CreateGroupHeaderRow()
        local row = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, listChild)
        row:SetSize(listChild:GetWidth(), lineHeight)
        NSI.UI.Components.StyleRow(row, STYLE.selected_fill)

        local arrow = row:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(12, 12)
        arrow:SetPoint("LEFT", row, "LEFT", 4, 0)
        arrow:SetTexture([[Interface\Buttons\Arrow-Down-Up]])
        NSI.UI.Style.PaintAccent(arrow, "SetVertexColor", 1)
        row.collapseArrow = arrow

        local bossIcon = row:CreateTexture(nil, "ARTWORK")
        bossIcon:SetSize(16, 16)
        bossIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        bossIcon:SetPoint("LEFT", row, "LEFT", 18, 0)
        bossIcon:Hide()
        row.bossIcon = bossIcon

        local nameLabel = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(nameLabel, "label")
        NSI.UI.Style.PaintAccent(nameLabel, "SetTextColor", 1)
        nameLabel:SetPoint("LEFT", row, "LEFT", 18, 0)  -- repositioned dynamically
        nameLabel:SetPoint("RIGHT", row, "RIGHT", -36, 0)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetWordWrap(false)
        row.nameLabel = nameLabel

        local countLabel = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(countLabel, "small")
        countLabel:SetTextColor(unpack(STYLE.text_hint))
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
                    if type(alert) == "table" and alert.group == name then
                        alert.group = nil
                        if alert.ReloeReminder == true then alert.UserModifiedGroup = true end
                    end
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
                    if entry.alert.ReloeReminder == true then entry.alert.UserModifiedGroup = true end
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
            if a._pinned ~= b._pinned then return a._pinned end
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
                                    _phase          = tonumber(NSI:GetPrimaryPhase(entry.phase)) or 1,
                                    _sortName       = displayName,
                                    _orderID        = isReloe and entry.id or nil,
                                    _group          = entry.group,
                                    _pinned         = entry.pinned == true,
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
                NSI.UI.Style.PaintAccent(row.collapseArrow, "SetVertexColor", 1)
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
                                ShowExportPopup(str, NSI:Loc("Group") .. ": " .. gname)
                            end },
                            { type = "separator" },
                            { type = "button", label = NSI:Loc("Enable All"), fnc = function()
                                local diffTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[gencID]
                                              and NSRT.EncounterAlerts[gencID][filterDiffID]
                                if diffTable then
                                    for akey, alert in pairs(diffTable) do
                                        if type(alert) == "table" and alert.group == gname then
                                            NSI:SaveAlertData(alert, "enabled", true, gencID, filterDiffID, akey)
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
                                            NSI:SaveAlertData(alert, "enabled", false, gencID, filterDiffID, akey)
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

                isEnabled = entry.data.enabled
                name      = isReloe and ReloeAlertName(entry.data) or (entry.data.name or NSI:Loc("Unnamed"))

                local willLoad = NSI:EvaluateLoad(entry.data)

                -- Selected highlight
                local isSelected = isReloe
                    and (selectedEncID == entry.encID and selectedDiffID == entry.diffID and selectedKey == entry.alertKey)
                    or  (not isReloe and selectedKey == entry.alertKey and selectedEncID == entry.encID)
                if isSelected then
                    row.__background:SetVertexColor(Accent())
                    row.__background:SetAlpha(STYLE.selected_row_alpha)
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
                            NSI:SaveAlertData(e, "enabled", v, eid, did, akey)
                            if selectedEncID == eid and selectedDiffID == did and selectedKey == akey then
                                enabledCB:SetValue(v)
                            end
                        end
                    end)
                else
                    local alert   = entry.data
                    local akey    = entry.alertKey
                    local aencID  = entry.encID
                    local adid    = entry.diffID
                    row.enabledCB:SetOnChange(function(nsi, v)
                        NSI:SaveAlertData(alert, "enabled", v, aencID, adid, akey)
                        if selectedKey == akey and selectedEncID == aencID then
                            enabledCB:SetValue(v)
                        end
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
                            if diffTable[akey_ug].ReloeReminder == true then diffTable[akey_ug].UserModifiedGroup = true end
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

                local pinAnchor = canDelete and row.deleteBtn or row.lockIcon
                row.pinIcon:ClearAllPoints()
                row.pinIcon:SetPoint("RIGHT", pinAnchor, "LEFT", -4, 0)
                row.nameLabel:ClearAllPoints()
                row.nameLabel:SetPoint("LEFT", row.bossIcon, "RIGHT", 4, 0)
                row.nameLabel:SetPoint("RIGHT", entry._pinned and row.pinIcon or pinAnchor, "LEFT", -4, 0)

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
                                    if alert then
                                        alert.group = gn
                                        if alert.ReloeReminder == true then alert.UserModifiedGroup = true end
                                        EnsureGroup(eid, gn)
                                        RebuildList()
                                    end
                                end })
                            end
                            table.insert(groupSubItems, { type = "button", label = NSI:Loc("New Group..."), fnc = function()
                                NSI.UI.Components.CreateInputDialog("NewEncounterGroup", NSI:Loc("New Group"), NSI:Loc("Enter new group name:"), {
                                    onAccept = function(newName)
                                        if newName == "" then return end
                                        if alert then
                                            alert.group = newName
                                            if alert.ReloeReminder == true then alert.UserModifiedGroup = true end
                                        end
                                        EnsureGroup(eid, newName)
                                        RebuildList()
                                    end,
                                })
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

                            if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
                                table.insert(menuItems, { type = "button", label = NSI:Loc("Raid Version Check"), fnc = function()
                                    if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then return end
                                    NSUI.MenuFrame:SelectTabByName("Versions")
                                    NSUI.version_scrollbox:CheckEncounterAlert(eid, did, alert.internalID or akey)
                                end })
                            end

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
                                    newData.internalID = newKey
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
                                            payload.entries[#payload.entries + 1] = { key = "phaseTimers", value = CopyValue(alert.phaseTimers) }
                                            payload.entries[#payload.entries + 1] = { key = "isConditional", value = CopyValue(alert.isConditional) }
                                            for fieldIndex, key in ipairs({ "castDuration", "bossID", "bossEvent", "timerVariance", "onEncounterStart", "onEncounterEnd", "onPhaseChange" }) do
                                                payload.entries[#payload.entries + 1] = { key = key, value = CopyValue(alert[key]) }
                                            end
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
                                    if alert.ReloeReminder == true then alert.UserModifiedGroup = true end
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

    NSI.RefreshEncounterAlertsUIHandler = function()
        if screen:IsShown() then
            RebuildList()
            screen.RefreshSelected()
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
            internalID    = newKey,
            IsAlert       = true,
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
    local ADDOPT_H   = 270
    local addOptFrame = CreateStyledFrame(NSUI, ADDOPT_W, ADDOPT_H, "NSRTEncAlertAddOptFrame")
    addOptFrame:SetPoint("TOPLEFT", NSUI, "TOPRIGHT", 4, 0)
    addOptFrame:Hide()

    local importSelectedBossBtn = CreateLocalizedButton(addOptFrame, "Import Selected Boss Alerts", function()
        if not filterEncID or filterEncID == 0 then
            print(NSI.UI.Style.AccentCode() .. "NSRT:|r " .. NSI:Loc("Select a boss first."))
            return
        end
        NSI:ImportReloeReminders(filterEncID, true)
        RebuildList()
        if selectedEncID and selectedKey then
            SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
        end
    end, ADDOPT_INNER_W, 22)
    importSelectedBossBtn:SetPoint("TOPLEFT", addOptFrame, "TOPLEFT", ADDOPT_PAD, -30)

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
                            NSI:SaveAlertData(alert, "enabled", enabled, encID, filterDiffID, akey)
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

    -- Language dropdown for alert translation
    do
        local languagesAvailable = {
            enUS = { text = "English (US)", font = "Fonts\\FRIZQT__.TTF" },
            deDE = { text = "Deutsch",       font = "Fonts\\FRIZQT__.TTF" },
            koKR = { text = "한국어",         font = "Fonts\\2002.TTF" },
            ruRU = { text = "Русский",       font = "Fonts\\FRIZQT___CYR.TTF" },
            zhCN = { text = "简体中文",       font = "Fonts\\ARHei.ttf" },
            zhTW = { text = "繁體中文",       font = "Fonts\\ARHei.ttf" },
        }

        local languageLabel = CreateLabel(addOptFrame, NSI:Loc("Alerts Language"), ADDOPT_INNER_W, 16)
        languageLabel:SetPoint("TOPLEFT", disableAllBtn.frame, "BOTTOMLEFT", 0, -8)

        local function BuildLanguageOptions()
            local opts = {}
            local languageOrder = { "enUS", "deDE", "koKR", "ruRU", "zhCN", "zhTW" }
            for languageIndex in ipairs(languageOrder) do
                local locale = languageOrder[languageIndex]
                local info = languagesAvailable[locale]
                local loc = locale
                table.insert(opts, { label = info.text, font = info.font, value = loc, onclick = function()
                    NSRT.Alerts.Language = loc
                    NSI:TranslateAllEncounterAlerts(loc)
                    RebuildList()
                    if selectedEncID and selectedKey then
                        SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
                    end
                end })
            end
            return opts
        end
        local function getLanguageSelected()
            local lang = NSI:GetEncounterAlertLanguage()
            return languagesAvailable[lang] and languagesAvailable[lang].text or languagesAvailable.enUS.text
        end
        local languageDD = CreateDropdown(addOptFrame, nil, BuildLanguageOptions, getLanguageSelected,
            ADDOPT_INNER_W, 22, "NSUIEncAlertLanguageDD")
        languageDD:SetPoint("TOPLEFT", languageLabel.frame, "BOTTOMLEFT", 0, -4)
    end

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
    NSI:SetUIFont(nameLbl, "tiny", "")
    nameLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(nameLbl, "Alert Name")
    nameLbl:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)

    local nameEntry = CreateTextEntry(rightPanel, nil, nil, nil, rightW - 240, 22,
        nil, nil, nil, "NSUIEncAlertNameEntry")
    nameEntry:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -14)

    local groupLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(groupLbl, "tiny", "")
    groupLbl:SetTextColor(unpack(STYLE.text_muted))
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
        table.insert(items, { label = NSI:Loc("\226\128\148 No Group \226\128\148"), onclick = function()
            if alert then
                alert.group = nil
                if alert.ReloeReminder == true then alert.UserModifiedGroup = true end
                RebuildList()
                groupDD:Refresh()
            end
        end })
        for _, gname in ipairs(GetGroupsForEnc(eid or 0)) do
            local gn = gname
            table.insert(items, { label = gn, onclick = function()
                if alert then
                    alert.group = gn
                    if alert.ReloeReminder == true then alert.UserModifiedGroup = true end
                    EnsureGroup(eid, gn)
                    RebuildList()
                    groupDD:Refresh()
                end
            end })
        end
        table.insert(items, { label = NSI:Loc("New Group..."), onclick = function()
            NSI.UI.Components.CreateInputDialog("NewEncounterGroup", NSI:Loc("New Group"), NSI:Loc("Enter new group name:"), {
                onAccept = function(newName)
                    if newName == "" then return end
                    if alert then
                        alert.group = newName
                        if alert.ReloeReminder == true then alert.UserModifiedGroup = true end
                    end
                    EnsureGroup(eid, newName)
                    RebuildList()
                    groupDD:Refresh()
                end,
            })
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
        return (alert and alert.group) or NSI:Loc("\226\128\148 No Group \226\128\148")
    end

    groupDD = CreateDropdown(rightPanel, nil, BuildGroupItems, GetGroupSelected,
        120, 22, "NSUIEncAlertGroupDD")
    groupDD:SetPoint("LEFT", nameEntry.frame, "RIGHT", 12, 0)

    enabledCB = CreateCheckButton(rightPanel, NSI:Loc("Enabled"),
        function() return false end, nil, 90, 22, "NSUIEncAlertEnabled")
    enabledCB:SetLocaleKey("Enabled")
    enabledCB:SetPoint("LEFT", groupDD.frame, "RIGHT", 8, 0)

    conditionHint = rightPanel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(conditionHint, "small", "")
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

    -- Settings registry for the header search (ScopedSearch): every labelled control of
    -- the selected alert. types limits an entry to the display types that show it.
    local searchables, searchScroll = {}, {}
    local searchOptions   -- set by the Options tab: returns entry, definitions fn, host, scroll
    local function Reg(tab, crumb, key, target, types)
        local set
        if types then set = {}; for _, v in ipairs(types) do set[v] = true end end
        searchables[#searchables + 1] = { tab = tab, crumb = crumb, key = key, target = target, types = set }
    end

    local function PositionInnerTabLayout(conditionText)
        local hasCondition = type(conditionText) == "string" and conditionText ~= ""

        if hasCondition then
            conditionHint:SetText("|cFFFFD100" .. NSI:Loc("Condition") .. ":|r " .. NSI:EncounterAlertLoc(conditionText))
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

    -- Lua code-editor popups live in EncounterAlerts/CodeEditors.lua; they reach this
    -- screen's state only through these callbacks (resolved at call time).
    local Editors = Parts.CodeEditors.Create({
        GetTrigF = function() return trigF end,
        PositionInnerTabLayout = function(...) return PositionInnerTabLayout(...) end,
        RebuildList = function() return RebuildList() end,
        RebuildOptionsContent = function(...) return RebuildOptionsContent(...) end,
    })
    local GetConditionText             = Editors.GetConditionText
    local OpenConditionEditor          = Editors.OpenConditionEditor
    local RefreshEncounterHookDisplay  = Editors.RefreshEncounterHookDisplay
    local OpenEncounterHookEditor      = Editors.OpenEncounterHookEditor
    local DEFAULT_ENCOUNTER_START_CODE = Editors.DEFAULT_ENCOUNTER_START_CODE
    local DEFAULT_ENCOUNTER_END_CODE   = Editors.DEFAULT_ENCOUNTER_END_CODE
    local DEFAULT_PHASE_CHANGE_CODE    = Editors.DEFAULT_PHASE_CHANGE_CODE
    local OpenCustomPreviewEditor      = Editors.OpenCustomPreviewEditor
    local OpenCustomOptionEditor       = Editors.OpenCustomOptionEditor

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
        if alert.NoEdit and (sectionName == "Display" or sectionName == "Sound") then return false end
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
            payload.entries[#payload.entries + 1] = { key = "phaseTimers", value = CopyValue(alert.phaseTimers) }
            payload.entries[#payload.entries + 1] = { key = "isConditional", value = CopyValue(alert.isConditional) }
            for fieldIndex, key in ipairs({ "castDuration", "bossID", "bossEvent", "timerVariance", "onEncounterStart", "onEncounterEnd", "onPhaseChange" }) do
                payload.entries[#payload.entries + 1] = { key = key, value = CopyValue(alert[key]) }
            end
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

        if sectionName == "Trigger" then
            RefreshEncounterHookDisplay(alert)
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
    NSI.UI.Style.PaintAccent(tabSep, "SetColorTexture", 0.20)
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
        local ov = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, parent)
        ov:SetAllPoints(parent)
        ov:SetFrameLevel(parent:GetFrameLevel() + 10)
        ov:EnableMouse(true)

        if transparent then
            -- No background; just intercept mouse. Show a small read-only badge top-right.
            local badge = ov:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(badge, "tiny", "")
            badge:SetTextColor(0.9, 0.75, 0.2, 0.85)
            NSI.UI.Components.RegisterLocalizedText(badge, "Read-only", function()
                return "|TInterface\\PetBattles\\PetBattle-LockIcon:12:12:0:-1|t " .. NSI:Loc("Read-only")
            end)
            badge:SetPoint("TOPRIGHT", ov, "TOPRIGHT", 0, 0)
        else
            NSI.UI.Components.StyleRow(ov, STYLE.row_dark)

            local lbl = ov:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(lbl, "label", "")
            lbl:SetTextColor(unpack(STYLE.text_muted))
            SetLocalizedText(lbl, messageKey)
            lbl:SetPoint("CENTER", ov, "CENTER", 0, 0)
            lbl:SetJustifyH("CENTER")
        end

        ov:Hide()
        return ov
    end

    -- ================================================================
    -- Card stack helpers for the Display / Sound tabs
    --   CreateCardStack(tabFrame): a scroll box holding a vertical stack of section cards.
    --     stack:Add(titleKey, contentH) -> content frame, card
    --     stack:SetContentHeight(card, h), card.hidden = true/false, stack:Layout()
    --   StyleListBox(scrollFrame): keep a list's own scrollbar inside the box and draw a
    --     border, so it is clear the wheel scrolls the list and not the window.
    -- ================================================================
    local function CreateCardStack(tabFrame)
        local Components = NSI.UI.Components
        local pad, gap = Components.CardPad, Components.CardGap
        local scroll = Components.CreateScrollBox(tabFrame, rightW, 100)
        scroll.frame:ClearAllPoints()
        scroll.frame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, 0)
        scroll.frame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", 0, 0)
        scroll.frame:HookScript("OnSizeChanged", function() scroll:UpdateScrollBar() end)
        tabFrame:HookScript("OnShow", function() scroll:UpdateScrollBar() end)
        local child = scroll.scrollChild
        local stack = { scroll = scroll, child = child, width = child:GetWidth(),
                        innerW = child:GetWidth() - pad * 2, cards = {} }
        function stack:Layout()
            local y = 0
            for _, card in ipairs(self.cards) do
                if card.hidden then
                    card:Hide()
                else
                    card.content:SetHeight(card.contentH)
                    card:SetHeight(card.headerH + pad * 2 + card.contentH)
                    card:ClearAllPoints()
                    card:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
                    card:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
                    card:Show()
                    y = y + card:GetHeight() + gap
                end
            end
            child:SetHeight(math.max(y - gap, 1))
            scroll:UpdateScrollBar()
        end
        function stack:Add(titleKey, contentH)
            local card = Components.CreateSectionCard(child, self.width, true)
            if titleKey then
                SetLocalizedText(card.title, titleKey)
            else
                card.title:SetText("")
                card.title:Hide()
            end
            card.contentH = contentH
            card.content:SetPoint("TOPRIGHT", card, "TOPRIGHT", -pad, -(card.headerH + pad))
            self.cards[#self.cards + 1] = card
            self:Layout()
            return card.content, card
        end
        return stack
    end

    local function StyleListBox(scrollFrame)
        local bar = _G[scrollFrame:GetName() .. "ScrollBar"]
        if bar then
            bar:ClearAllPoints()
            bar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -16)
            bar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 16)
        end
        local borderFrame = CreateFrame("Frame", nil, scrollFrame)
        borderFrame:SetAllPoints(scrollFrame)
        borderFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 5)
        borderFrame:EnableMouse(false)
        NSI.UI.Style.PaintAccent(NSI.UI.Pixel.Border(borderFrame, { NSI.UI.Style.Accent(0.55) }), "SetBorderColor", 0.55)
    end

    -- ================================================================
    -- DISPLAY TAB
    -- ================================================================
    do
    dispF = innerTabFrames["Display"]

    local dispStack = CreateCardStack(dispF)
    local dispInnerW = dispStack.innerW
    -- Display type card: header row = Text/Bar/Icon/Circle buttons, body = only the
    -- settings of the selected type.
    local typeC, typeCard = dispStack:Add("Display", 22)
    -- keep the title short so the type buttons sit right after it in the header row
    local TYPE_TITLE_W = 62
    typeCard.title:ClearAllPoints()
    typeCard.title:SetPoint("TOPLEFT", typeCard, "TOPLEFT", NSI.UI.Components.CardPad, -NSI.UI.Components.CardPad)
    typeCard.title:SetWidth(TYPE_TITLE_W)
    local alertC          = dispStack:Add("Alert", 82)
    local timingC         = dispStack:Add("Timing", 38)
    local colorC          = dispStack:Add("Glow", 38)
    dispStack:Layout()

    dispHint = dispF:CreateFontString(nil, "OVERLAY")
    dispHint:Hide()

    local TYPES    = { "Text", "Bar", "Icon", "Circle" }
    local typeBtns = {}
    local typeBtnW = 70

    local function SetDisplayType(t)
        dispF._displayType = t
        for _, tn in ipairs(TYPES) do
            if tn == t then typeBtns[tn]:Select() else typeBtns[tn]:Deselect() end
        end
    end
    dispF.SetDisplayType = SetDisplayType

    for i, tn in ipairs(TYPES) do
        local tb = CreateLocalizedSubButton(typeCard, tn, function()
            if dispF._alert then NSI:SaveAlertData(dispF._alert, "DisplayType", tn) end
            SetDisplayType(tn)
        end, typeBtnW, "NSUIEncAlertType_" .. tn)
        tb:SetPoint("TOPLEFT", typeCard, "TOPLEFT", NSI.UI.Components.CardPad + TYPE_TITLE_W + 8 + (i - 1) * (typeBtnW + 3), -NSI.UI.Components.CardPad)
        typeBtns[tn] = tb
    end

    local textLbl = alertC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(textLbl, "small", "")
    textLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(textLbl, "Display Text")
    textLbl:SetPoint("TOPLEFT", alertC, "TOPLEFT", 0, 0)

    local textEntry = CreateTextEntry(alertC, nil, nil, nil, dispInnerW, 22,
        nil, nil, nil, "NSUIEncAlertDisplayText")
    textEntry:SetPoint("TOPLEFT", alertC, "TOPLEFT", 0, -16)
    local function SaveDispText(self)
        local v = self:GetText()
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "text", v) end
    end
    textEntry.editBox:SetScript("OnEditFocusLost", SaveDispText)
    dispF.textEntry = textEntry

    local spellLbl = alertC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(spellLbl, "small", "")
    spellLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(spellLbl, "Spell ID")
    spellLbl:SetPoint("TOPLEFT", alertC, "TOPLEFT", 0, -44)

    local spellEntry = CreateTextEntry(alertC, nil, nil, nil, 130, 22,
        nil, nil, nil, "NSUIEncAlertSpellID",
        { title = "Spell ID", desc = "The icon of this spellid will be used for the in-combat display" })
    spellEntry:SetPoint("TOPLEFT", alertC, "TOPLEFT", 0, -60)

    -- Spell icon preview: shown immediately to the right of the entry
    local spellIconFrame = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, alertC)
    spellIconFrame:SetSize(22, 22)
    spellIconFrame:SetPoint("LEFT", spellEntry.frame, "RIGHT", 4, 0)
    NSI.UI.Components.StyleRow(spellIconFrame, STYLE.row_plain)
    local spellIconTex = spellIconFrame:CreateTexture(nil, "ARTWORK")
    spellIconTex:SetPoint("TOPLEFT",     spellIconFrame, "TOPLEFT",     1,  -1)
    spellIconTex:SetPoint("BOTTOMRIGHT", spellIconFrame, "BOTTOMRIGHT", -1,  1)
    spellIconTex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
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

    local useTauntCB = CreateCheckButton(alertC, NSI:Loc("Use Taunt spellid"),
        function()
            return dispF._alert and dispF._alert.isTaunt == true or false
        end,
        function(_, v)
            if dispF._alert then
                NSI:SaveAlertData(dispF._alert, "isTaunt", v or nil)
                RebuildList()
            end
        end,
        150, 22, "NSUIEncAlertUseTauntSpellID", {
            title = "Use Taunt spellid",
            desc = "Automatically uses the spellid for the taunt of your current class."
        })
    useTauntCB:SetLocaleKey("Use Taunt spellid")
    useTauntCB:SetPoint("TOPLEFT", alertC, "TOPLEFT", 164, -60)
    dispF.useTauntCB = useTauntCB

    local customIconLbl = alertC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(customIconLbl, "small", "")
    customIconLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(customIconLbl, "Custom Icon (overrides icon in list)")
    customIconLbl:SetPoint("TOPLEFT", alertC, "TOPLEFT", 330, -44)

    local customIconEntry = CreateTextEntry(alertC, nil, nil, nil, 180, 22,
        nil, nil, nil, "NSUIEncAlertCustomIcon",
        { title = "Custom Icon", desc = "Uses the spellid's icon for display in the alert-list. Does NOT change the in-combat display" })
    customIconEntry:SetPoint("TOPLEFT", alertC, "TOPLEFT", 330, -60)
    local function SaveCustomIcon(self)
        local v = tonumber(self:GetText()) or nil
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "customIcon", v) end
        RebuildList()
    end
    customIconEntry.editBox:SetScript("OnEditFocusLost", SaveCustomIcon)
    dispF.customIconEntry = customIconEntry

    local durLbl = timingC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(durLbl, "small", "")
    durLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(durLbl, "Duration")
    durLbl:SetPoint("TOPLEFT", timingC, "TOPLEFT", 0, 0)

    local durEntry = CreateTextEntry(timingC, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertDuration",
        { title = "Duration", desc = "How long before the specified time this alert should start showing up" })
    durEntry:SetPoint("TOPLEFT", timingC, "TOPLEFT", 0, -16)
    local function SaveDur(self)
        local v = tonumber(self:GetText())
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "dur", v or 8) end
    end
    durEntry.editBox:SetScript("OnEditFocusLost", SaveDur)
    dispF.durEntry = durEntry

    local stickyLbl = timingC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(stickyLbl, "small", "")
    stickyLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(stickyLbl, "Sticky duration (0 to disable)")
    stickyLbl:SetPoint("TOPLEFT", durLbl, "TOPRIGHT", 55, 0)

    local stickyEntry = CreateTextEntry(timingC, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertSticky",
        { title = "Sticky duration", desc = "How long the alert should remain on screen when duration hits 0" })
    stickyEntry:SetPoint("TOPLEFT", durEntry.frame, "TOPRIGHT", 20, 0)
    local function SaveSticky(self)
        local v = tonumber(self:GetText())
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "sticky", v) end
    end
    stickyEntry.editBox:SetScript("OnEditFocusLost", SaveSticky)
    dispF.stickyEntry = stickyEntry

    local hideTimerCB = CreateCheckButton(timingC, NSI:Loc("Hide Timer Text"),
        function()
            if not dispF._alert then return false end
            if dispF._alert.HideTimer ~= nil then return dispF._alert.HideTimer end
            return false
        end,
        function(_, v) if dispF._alert then NSI:SaveAlertData(dispF._alert, "HideTimer", v or nil) end end,
        135, 22, "NSUIEncAlertHideTimer",
        { title = "Hide Timer Text", desc = "Hides the remaining duration text of this alert" })
    hideTimerCB:SetLocaleKey("Hide Timer Text")
    hideTimerCB:SetPoint("LEFT", stickyEntry.frame, "RIGHT", 14, 0)
    dispF.hideTimerCB = hideTimerCB

    local hideSwipeCB = CreateCheckButton(typeC, NSI:Loc("Hide Swipe"),
        function()
            if not dispF._alert then return false end
            if dispF._alert.HideSwipe ~= nil then return dispF._alert.HideSwipe end
            return NSRT.ReminderSettings.IconSettings.HideSwipe or false
        end,
        function(_, v) if dispF._alert then NSI:SaveAlertData(dispF._alert, "HideSwipe", v) end end,
        110, 22, "NSUIEncAlertHideSwipe")
    hideSwipeCB:SetLocaleKey("Hide Swipe")
    hideSwipeCB:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, -30)
    hideSwipeCB.frame:Hide()   -- only shown for Icon type
    dispF.hideSwipeCB = hideSwipeCB

    -- ── glowunit ────────────────────────────────────────────────────────
    local glowunitLbl = colorC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(glowunitLbl, "small", "")
    glowunitLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(glowunitLbl, "Glow Unit (player names, space seperated)")
    glowunitLbl:SetPoint("TOPLEFT", colorC, "TOPLEFT", 0, 0)

    local glowunitEntry = CreateTextEntry(colorC, nil, nil, nil, 200, 22,
        nil, nil, nil, "NSUIEncAlertGlowUnit",
        { title = "Glow unit", desc = "Creates a glow on these player's Raidframes" })
    glowunitEntry:SetPoint("TOPLEFT", colorC, "TOPLEFT", 0, -16)
    local function SaveGlowUnit(self)
        local v = self:GetText()
        if dispF._alert then NSI:SaveAlertData(dispF._alert, "glowunit", (v ~= "") and v or nil) end
    end
    glowunitEntry.editBox:SetScript("OnEditFocusLost", SaveGlowUnit)
    dispF.glowunitEntry = glowunitEntry

    local glowcolorlbl = colorC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(glowcolorlbl, "small", "")
    glowcolorlbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(glowcolorlbl, "Glow Color")
    glowcolorlbl:SetPoint("TOPLEFT", colorC, "TOPLEFT", 265, -20)
    dispF.glowcolorlbl = glowcolorlbl

    local glowunitColor = CreateColorPicker(colorC, nil,
        function()
            local c = dispF._alert and dispF._alert.glowColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return unpack(NSRT.ReminderSettings.GlowSettings.colors)
        end,
        function(_, r, g, b, a)
            if dispF._alert then NSI:SaveAlertData(dispF._alert, "glowColors", {r, g, b, a}) end
        end,
        200, 22, "NSUIEncAlertGlowColors")
    glowunitColor:SetPoint("TOPLEFT", colorC, "TOPLEFT", 60, -16)
    dispF.glowunitColor = glowunitColor

    -- ── colors ──────────────────────────────────────────────────────────
    local colorsLbl = typeC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(colorsLbl, "small", "")
    colorsLbl:SetTextColor(unpack(STYLE.text_muted))
    NSI.UI.Components.RegisterLocalizedText(colorsLbl, "Color", function()
        local t = dispF._alert and (dispF._alert.DisplayType or "Text")
        if t == "Text" or t == "Icon" or t == "Circle" then
            return NSI:Loc("Text Color")
        end
        return NSI:Loc("Color")
    end)
    colorsLbl:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, 0)
    dispF.colorsLbl = colorsLbl

    local colorsPicker = CreateColorPicker(typeC, nil,
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
    colorsPicker:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, 0)
    dispF.colorsPicker = colorsPicker

    -- ── Circle section (shown only when display type = "Circle") ────────
    local circleSection = CreateFrame("Frame", nil, typeC)
    circleSection:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, -30)
    circleSection:SetSize(dispInnerW, 96)
    circleSection:Hide()

    local circleTextureLbl = circleSection:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(circleTextureLbl, "small", "")
    circleTextureLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(circleTextureLbl, "Texture")
    circleTextureLbl:SetPoint("TOPLEFT", circleSection, "TOPLEFT", 0, 0)

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
    circleTextureDD:SetPoint("TOPLEFT", circleSection, "TOPLEFT", 0, -16)
    dispF.circleTextureDD = circleTextureDD

    local ringColorsLbl = circleSection:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ringColorsLbl, "small", "")
    ringColorsLbl:SetTextColor(unpack(STYLE.text_muted))
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
    ringColorsPicker:SetPoint("TOPLEFT", ringColorsLbl, "BOTTOMLEFT", 0, 12)
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
    local barsSection = CreateFrame("Frame", nil, typeC)
    barsSection:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, -56)
    barsSection:SetSize(dispInnerW, 158)
    barsSection:Hide()

    local ticksLbl = barsSection:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ticksLbl, "small", "")
    ticksLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(ticksLbl, "Ticks (seconds into the display where ticks should appear)")
    ticksLbl:SetPoint("TOPLEFT", barsSection, "TOPLEFT", 0, 0)

    local ticksListH = 100
    local ticksListW = dispInnerW

    local ticksScroll = CreateFrame("ScrollFrame", "NSUIEncAlertTicksScroll", barsSection,
        "UIPanelScrollFrameTemplate")
    NSI.UI.Components.EnableSmoothScroll(ticksScroll)
    ticksScroll:SetSize(ticksListW, ticksListH)
    ticksScroll:SetPoint("TOPLEFT", barsSection, "TOPLEFT", 0, -16)
    ReskinScrollbar(ticksScroll)
    StyleListBox(ticksScroll)
    local ticksBg = ticksScroll:CreateTexture(nil, "BACKGROUND")
    ticksBg:SetAllPoints(ticksScroll)
    ticksBg:SetColorTexture(unpack(STYLE.surface_inset))

    local ticksChild = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, ticksScroll)
    ticksChild:SetSize(ticksListW - 18, 1)
    ticksChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    ticksChild:SetBackdropColor(unpack(STYLE.surface_inset))
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
                tickRows[i].tLbl:SetTextColor(unpack(STYLE.text_color))
                tickRows[i].tLbl:SetPoint("LEFT", tickRows[i], "LEFT", 8, 0)
                tickRows[i].bg:SetAllPoints(tickRows[i])
                tickRows[i]:SetSize(ticksChild:GetWidth(), tickRowH)
                tickRows[i]:SetPoint("TOPLEFT", ticksChild, "TOPLEFT", 0, -(i - 1) * tickRowH)
                tickRows[i].delBtn:SetSize(14, 14)
                tickRows[i].delBtn:SetPoint("RIGHT", tickRows[i], "RIGHT", -6, 0)
                tickRows[i].delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                tickRows[i].delBtn:GetNormalTexture():SetDesaturated(true)
                tickRows[i].delBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.danger))
            end
            if i % 2 == 0 then
                tickRows[i].bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
            else
                tickRows[i].bg:SetColorTexture(0, 0, 0, 0)
            end
            NSI:SetUIFont(tickRows[i].tLbl, "label", "")
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
    NSI:SetUIFont(addTickLbl, "tiny", "")
    addTickLbl:SetTextColor(unpack(STYLE.text_muted))
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
            NSI:SaveAlertData(dispF._alert, "Ticks", dispF._alert.Ticks)
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
    local barTextColorsLbl = typeC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(barTextColorsLbl, "small", "")
    barTextColorsLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(barTextColorsLbl, "Bar Text Color")
    barTextColorsLbl:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, 0)
    barTextColorsLbl:Hide()

    local barTextColorsPicker = CreateColorPicker(typeC, nil,
        function()
            local c = dispF._alert and dispF._alert.textColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return unpack(NSRT.ReminderSettings.BarSettings.textColors)
        end,
        function(_, r, g, b, a) if dispF._alert then NSI:SaveAlertData(dispF._alert, "textColors", {r, g, b, a}) end end,
        200, 22, "NSUIEncAlertBarTextColors")
    barTextColorsPicker:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, 0)
    barTextColorsPicker.frame:Hide()
    dispF.barTextColorsPicker = barTextColorsPicker
    dispF.barTextColorsLbl    = barTextColorsLbl

    -- Bar fill color picker — shown below text color for Bar type
    local barFillColorsLbl = typeC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(barFillColorsLbl, "small", "")
    barFillColorsLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(barFillColorsLbl, "Bar Fill Color")
    barFillColorsLbl:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, -24)
    barFillColorsLbl:Hide()

    local barFillColorsPicker = CreateColorPicker(typeC, nil,
        function()
            local c = dispF._alert and dispF._alert.barColors
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
            return unpack(NSRT.ReminderSettings.BarSettings.barColors)
        end,
        function(_, r, g, b, a) if dispF._alert then NSI:SaveAlertData(dispF._alert, "barColors", {r, g, b, a}) end end,
        200, 22, "NSUIEncAlertBarFillColors")
    barFillColorsPicker:SetPoint("TOPLEFT", typeC, "TOPLEFT", 0, -24)
    barFillColorsPicker.frame:Hide()
    dispF.barFillColorsPicker = barFillColorsPicker
    dispF.barFillColorsLbl    = barFillColorsLbl

    -- Patch SetDisplayType to toggle type-specific sections and relabel the color picker
    local previousSetDisplayType = SetDisplayType
    SetDisplayType = function(t)
        previousSetDisplayType(t)
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
        typeCard.contentH = (isBar and 214) or (isCircle and 126) or (t == "Icon" and 52) or 22
        dispStack:Layout()
        -- HideSwipe only relevant for Icon type
        dispF.hideSwipeCB.frame:SetShown(t == "Icon")
        -- Label for the shared picker (used for non-Bar types)
        local COLOR_LABELS = { Text=NSI:Loc("Text Color"), Icon=NSI:Loc("Text Color"), Circle=NSI:Loc("Text Color") }
        dispF.colorsLbl:SetText(COLOR_LABELS[t] or NSI:Loc("Color"))
        if dispF.colorsPicker then dispF.colorsPicker:Refresh() end
    end
    dispF.SetDisplayType = SetDisplayType
    dispF.lockOverlay = MakeLockOverlay(dispF,
        "Display settings are fixed\nfor this alert.")

    searchScroll.Display = dispStack.scroll
    Reg("Display", "Alert", "Display Text", textLbl)
    Reg("Display", "Alert", "Spell ID", spellLbl)
    Reg("Display", "Alert", "Use Taunt spellid", useTauntCB)
    Reg("Display", "Alert", "Custom Icon (overrides icon in list)", customIconLbl)
    Reg("Display", "Timing", "Duration", durLbl)
    Reg("Display", "Timing", "Sticky duration (0 to disable)", stickyLbl)
    Reg("Display", "Timing", "Hide Timer Text", hideTimerCB)
    Reg("Display", "Glow", "Glow Unit (player names, space seperated)", glowunitLbl)
    Reg("Display", "Glow", "Glow Color", glowcolorlbl)
    Reg("Display", "Display", "Text Color", colorsLbl, { "Text", "Icon", "Circle" })
    Reg("Display", "Display", "Hide Swipe", hideSwipeCB, { "Icon" })
    Reg("Display", "Display", "Bar Text Color", barTextColorsLbl, { "Bar" })
    Reg("Display", "Display", "Bar Fill Color", barFillColorsLbl, { "Bar" })
    Reg("Display", "Display", "Ticks (seconds into the display where ticks should appear)", ticksLbl, { "Bar" })
    Reg("Display", "Display", "Add tick", addTickLbl, { "Bar" })
    Reg("Display", "Display", "Texture", circleTextureLbl, { "Circle" })
    Reg("Display", "Display", "Ring Color", ringColorsLbl, { "Circle" })
    Reg("Display", "Display", "Show Background Ring", showBgCB, { "Circle" })
    end -- DISPLAY TAB

    -- ================================================================
    -- TRIGGER TAB
    -- ================================================================
    do
    trigF = innerTabFrames["Trigger"]

    -- Cards: the tab is a scrollable stack of section cards, the same look as the rest of
    -- the addon. Every widget keeps its trigF.<name> handle; only parents/anchors moved.
    local trigScroll = NSI.UI.Components.CreateScrollBox(trigF, rightW, 100)
    trigScroll.frame:ClearAllPoints()
    trigScroll.frame:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, 0)
    trigScroll.frame:SetPoint("BOTTOMRIGHT", trigF, "BOTTOMRIGHT", 0, 0)
    trigScroll.frame:HookScript("OnSizeChanged", function() trigScroll:UpdateScrollBar() end)
    trigF:HookScript("OnShow", function() trigScroll:UpdateScrollBar() end)
    local trigChild  = trigScroll.scrollChild
    local trigCardW  = trigChild:GetWidth()
    local trigInnerW = trigCardW - NSI.UI.Components.CardPad * 2
    local trigStackH = 0
    local function NewTrigCard(titleKey, contentH)
        local Components = NSI.UI.Components
        local card = Components.CreateSectionCard(trigChild, trigCardW, true)
        SetLocalizedText(card.title, titleKey)
        card.content:SetHeight(contentH)
        card:SetHeight(card.headerH + Components.CardPad * 2 + contentH)
        card:SetPoint("TOPLEFT", trigChild, "TOPLEFT", 0, -trigStackH)
        card:SetPoint("TOPRIGHT", trigChild, "TOPRIGHT", 0, -trigStackH)
        card.content:SetPoint("TOPRIGHT", card, "TOPRIGHT", -Components.CardPad, -(card.headerH + Components.CardPad))
        trigStackH = trigStackH + card:GetHeight() + Components.CardGap
        trigChild:SetHeight(trigStackH - Components.CardGap)
        return card.content
    end
    local encC  = NewTrigCard("Encounter", 38)
    local timeC = NewTrigCard("Timing", 256)
    local codeC = NewTrigCard("Conditions & Code", 46)
    local castC = NewTrigCard("Boss Cast Sync", 90)
    trigScroll:UpdateScrollBar()

    local trigBossLbl = encC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(trigBossLbl, "small", "")
    trigBossLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(trigBossLbl, "Boss")
    trigBossLbl:SetPoint("TOPLEFT", encC, "TOPLEFT", 0, 0)

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

    local trigBossDD = CreateDropdown(encC, nil, BuildTrigBossOptions, getTrigBossSelected,
        200, 22, "NSUIEncAlertTrigBoss", nil, 9)
    trigBossDD:SetPoint("TOPLEFT", encC, "TOPLEFT", 0, -16)
    trigF.bossDD = trigBossDD

    -- Difficulty dropdown — moves the alert to a different diff table on change
    local TRIG_DIFF_NAMES = { [14] = NSI:Loc("Normal"), [15] = NSI:Loc("Heroic"), [16] = NSI:Loc("Mythic") }

    local trigDiffLbl = encC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(trigDiffLbl, "small", "")
    trigDiffLbl:SetTextColor(unpack(STYLE.text_muted))
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

    local trigDiffDD = CreateDropdown(encC, nil, BuildTrigDiffOptions, getTrigDiffSelected,
        90, 22, "NSUIEncAlertTrigDiff")
    trigDiffDD:SetPoint("TOPLEFT", trigBossDD.frame, "TOPRIGHT", 6, 0)
    trigF.trigDiffDD = trigDiffDD

    local RebuildTimeRows

    local phaseLbl = timeC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(phaseLbl, "small", "")
    phaseLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(phaseLbl, "Phase")
    phaseLbl:SetPoint("TOPLEFT", timeC, "TOPLEFT", 0, 0)

    local phaseEntry = CreateTextEntry(timeC, nil, nil, nil, 60, 22,
        nil, nil, nil, "NSUIEncAlertPhase",
        { title = "Phase", desc = "The phase number will often not be equal to what you see in the Dungeon Journal or what WCL shows. Use a comma-separated list, like 1,2,3, when one alert should work in multiple phases." })
    phaseEntry:SetPoint("TOPLEFT", timeC, "TOPLEFT", 0, -16)
    phaseEntry.editBox:SetScript("OnEditFocusLost", function(self)
        if trigF._alert then
            local phase = ParsePhaseValue(self:GetText())
            self:SetText(FormatPhaseValue(phase))
            NSI:SaveAlertData(trigF._alert, "phase", phase)
            RebuildList()
        end
    end)
    trigF.phaseEntry = phaseEntry

    local timesLbl = timeC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(timesLbl, "small", "")
    timesLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(timesLbl, "Trigger Times (seconds into phase)")
    timesLbl:SetPoint("TOPLEFT", timeC, "TOPLEFT", 0, -48)

    -- Times list: native ScrollFrame
    local timesListH = 150
    local timesListW = trigInnerW

    local timesScroll = CreateFrame("ScrollFrame", "NSUIEncAlertTimesScroll", timeC,
        "UIPanelScrollFrameTemplate")
    NSI.UI.Components.EnableSmoothScroll(timesScroll)
    timesScroll:SetSize(timesListW, timesListH)
    timesScroll:SetPoint("TOPLEFT", timeC, "TOPLEFT", 0, -64)
    ReskinScrollbar(timesScroll)
    -- Keep the list's own scrollbar inside the box. The template parks it outside the
    -- right edge, where it collided with the window scrollbar.
    local timesBar = _G["NSUIEncAlertTimesScrollScrollBar"]
    if timesBar then
        timesBar:ClearAllPoints()
        timesBar:SetPoint("TOPRIGHT", timesScroll, "TOPRIGHT", 0, -16)
        timesBar:SetPoint("BOTTOMRIGHT", timesScroll, "BOTTOMRIGHT", 0, 16)
    end
    -- Border so it is clear the wheel scrolls this list rather than the window. It sits
    -- on its own frame above the rows so the stripes never cover it.
    local timesBorderFrame = CreateFrame("Frame", nil, timesScroll)
    timesBorderFrame:SetAllPoints(timesScroll)
    timesBorderFrame:SetFrameLevel(timesScroll:GetFrameLevel() + 5)
    timesBorderFrame:EnableMouse(false)
    NSI.UI.Style.PaintAccent(NSI.UI.Pixel.Border(timesBorderFrame, { NSI.UI.Style.Accent(0.55) }), "SetBorderColor", 0.55)
    local timesBg = timesScroll:CreateTexture(nil, "BACKGROUND")
    timesBg:SetAllPoints(timesScroll)
    timesBg:SetColorTexture(unpack(STYLE.surface_inset))

    local timesChild = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, timesScroll)
    timesChild:SetSize(timesListW - 18, 1)
    timesChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    timesChild:SetBackdropColor(unpack(STYLE.surface_inset))
    timesScroll:SetScrollChild(timesChild)

    local timeRowH  = 22
    local timeRows  = {}

    RebuildTimeRows = function(alert)
        for _, row in ipairs(timeRows) do row:Hide() end
        if not alert then return end
        local rows = {}
        if alert.phaseTimers then
            for _, phase in ipairs(NSI:GetSortedPhaseKeys(alert.phaseTimers)) do
                for timeIndex, time in ipairs(alert.phaseTimers[phase] or {}) do
                    rows[#rows + 1] = {phase = phase, timeIndex = timeIndex, time = time}
                end
            end
        else
            for timeIndex, time in ipairs(alert.timers or {}) do
                rows[#rows + 1] = {timeIndex = timeIndex, time = time}
            end
        end
        for i, rowData in ipairs(rows) do
            local t = rowData.time
            if not timeRows[i] then
                timeRows[i] = CreateFrame("Frame", nil, timesChild)
                timeRows[i]:SetSize(timesChild:GetWidth(), timeRowH)
                timeRows[i]:SetPoint("TOPLEFT", timesChild, "TOPLEFT", 0, -(i - 1) * timeRowH)
                timeRows[i].bg = timeRows[i]:CreateTexture(nil, "BACKGROUND")
                timeRows[i].bg:SetAllPoints(timeRows[i])
                timeRows[i].tLbl = timeRows[i]:CreateFontString(nil, "OVERLAY")
                timeRows[i].tLbl:SetPoint("LEFT", timeRows[i], "LEFT", 8, 0)
                timeRows[i].tLbl:SetTextColor(unpack(STYLE.text_color))
                timeRows[i].delBtn = CreateFrame("Button", nil, timeRows[i])
                timeRows[i].delBtn:SetSize(14, 14)
                timeRows[i].delBtn:SetPoint("RIGHT", timeRows[i], "RIGHT", -6, 0)
                timeRows[i].delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                timeRows[i].delBtn:GetNormalTexture():SetDesaturated(true)
                timeRows[i].delBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.danger))
            end

            if i % 2 == 0 then
                timeRows[i].bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
            else
                timeRows[i].bg:SetColorTexture(0, 0, 0, 0)
            end

            NSI:SetUIFont(timeRows[i].tLbl, "label", "")
            if rowData.phase ~= nil then
                timeRows[i].tLbl:SetText(string.format("P%s: %.2f s", tostring(rowData.phase), t))
            else
                timeRows[i].tLbl:SetText(string.format("%.2f s", t))
            end

            timeRows[i].delBtn:SetScript("OnClick", function()
                if trigF._alert then
                    if trigF._alert.phaseTimers and rowData.phase ~= nil then
                        local phaseTimers = trigF._alert.phaseTimers[rowData.phase]
                        if phaseTimers then
                            table.remove(phaseTimers, rowData.timeIndex)
                        end
                        NSI:SaveAlertData(trigF._alert, "phaseTimers", trigF._alert.phaseTimers)
                    else
                        table.remove(trigF._alert.timers, rowData.timeIndex)
                        NSI:SaveAlertData(trigF._alert, "timers", trigF._alert.timers)
                    end
                    RebuildTimeRows(trigF._alert)
                end
            end)

            timeRows[i]:Show()
        end

        local totalH = math.max(#rows * timeRowH, 1)
        timesChild:SetHeight(totalH)
        local bar = _G["NSUIEncAlertTimesScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, totalH - timesListH)
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end
    end
    trigF.RebuildTimeRows = RebuildTimeRows

    local addTimeLbl = timeC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(addTimeLbl, "tiny", "")
    addTimeLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(addTimeLbl, "Add time (s)")
    addTimeLbl:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -4)

    local addTimeEntry = CreateTextEntry(timeC, nil, nil, nil, 90, 22,
        nil, nil, nil, "NSUIEncAlertAddTime")
    addTimeEntry:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -20)
    trigF.addTimeEntry = addTimeEntry

    local phaseSpecificCB
    local phaseSpecificEntry
    local function RefreshPhaseSpecificControls()
        if phaseSpecificEntry then
            phaseSpecificEntry.frame:SetShown(phaseSpecificCB and phaseSpecificCB:GetValue())
        end
    end
    trigF.RefreshPhaseSpecificControls = RefreshPhaseSpecificControls

    local function DoAddTime()
        local v = tonumber(addTimeEntry:GetValue())
        if v and trigF._alert then
            if trigF._alert.phaseTimers then
                trigF._alert.phaseTimers = trigF._alert.phaseTimers or {}
                local phaseValue = phaseSpecificEntry and phaseSpecificEntry:GetValue() or trigF.phaseEntry:GetValue()
                for _, phase in ipairs(GetPhaseList(ParsePhaseValue(phaseValue))) do
                    trigF._alert.phaseTimers[phase] = InsertSortedTimer(trigF._alert.phaseTimers[phase], v)
                end
                NSI:SaveAlertData(trigF._alert, "phaseTimers", trigF._alert.phaseTimers)
            else
                trigF._alert.timers = InsertSortedTimer(trigF._alert.timers, v)
                NSI:SaveAlertData(trigF._alert, "timers", trigF._alert.timers)
            end
            addTimeEntry:SetValue("")
            RebuildTimeRows(trigF._alert)
        end
    end

    addTimeEntry.editBox:SetScript("OnEnterPressed", function(self)
        DoAddTime()
        self:ClearFocus()
    end)

    local addTimeBtn = CreateLocalizedSubButton(timeC, "Add", DoAddTime, 54,
        "NSUIEncAlertAddTimeBtn")
    addTimeBtn:SetPoint("LEFT", addTimeEntry.frame, "RIGHT", 6, 0)

    phaseSpecificCB = CreateCheckButton(timeC, NSI:Loc("Phase-specific timers"), nil, function(_, value)
        if not trigF._alert then return end
        if value then
            local phaseValue = phaseSpecificEntry and phaseSpecificEntry:GetValue() or trigF.phaseEntry:GetValue()
            local phases = GetPhaseList(ParsePhaseValue(phaseValue))
            trigF._alert.phaseTimers = BuildPhaseTimersFromFlatTimers(trigF._alert.timers or {}, phases)
            trigF._alert.timers = nil
            NSI:SaveAlertData(trigF._alert, "phaseTimers", trigF._alert.phaseTimers)
            NSI:SaveAlertData(trigF._alert, "timers", nil)
        else
            trigF._alert.timers = FlattenPhaseTimers(trigF._alert.phaseTimers)
            trigF._alert.phaseTimers = nil
            NSI:SaveAlertData(trigF._alert, "timers", trigF._alert.timers)
            NSI:SaveAlertData(trigF._alert, "phaseTimers", nil)
        end
        RefreshPhaseSpecificControls()
        RebuildTimeRows(trigF._alert)
    end, 190, 22, "NSUIEncAlertPhaseSpecificTimers",
        { title = "Phase-specific timers", desc = "When enabled, adding new timers will add them for the specified phase on the right." })
    phaseSpecificCB:SetPoint("LEFT", addTimeBtn.frame, "RIGHT", 8, 0)
    trigF.phaseSpecificCB = phaseSpecificCB

    phaseSpecificEntry = CreateTextEntry(timeC, nil, nil, nil, 48, 22,
        nil, nil, nil, "NSUIEncAlertPhaseSpecificTimerPhase")
    phaseSpecificEntry:SetPoint("LEFT", phaseSpecificCB.frame, "RIGHT", 6, 0)
    phaseSpecificEntry:SetValue("1")
    phaseSpecificEntry.frame:Hide()
    trigF.phaseSpecificEntry = phaseSpecificEntry

    local conditionBtn = CreateLocalizedSubButton(codeC, "Add Condition", OpenConditionEditor, 130,
        "NSUIEncAlertConditionBtn",
        { title = "Add/Edit Condition", desc = "Add/Edit the condition that needs to be fullfilled for this alert to show. This is only evaluated once at the time of the alert popping up" })
    conditionBtn:SetPoint("TOPLEFT", codeC, "TOPLEFT", 0, 0)
    trigF.conditionBtn = conditionBtn

    local encounterStartCodeBtn = CreateLocalizedSubButton(codeC, "Add Encounter Start Code", function()
        OpenEncounterHookEditor("onEncounterStart", "Encounter Start Function", DEFAULT_ENCOUNTER_START_CODE)
    end, 170, "NSUIEncAlertStartHookBtn",
        { title = "Encounter Start Code", desc = "Run custom code when this encounter starts. Alerts with encounter hooks are excluded from TimelineReminders." })
    encounterStartCodeBtn:SetPoint("TOPLEFT", conditionBtn.frame, "BOTTOMLEFT", 0, -8)
    trigF.encounterStartCodeBtn = encounterStartCodeBtn

    local encounterEndCodeBtn = CreateLocalizedSubButton(codeC, "Add Encounter End Code", function()
        OpenEncounterHookEditor("onEncounterEnd", "Encounter End Function", DEFAULT_ENCOUNTER_END_CODE)
    end, 170, "NSUIEncAlertEndHookBtn",
        { title = "Encounter End Code", desc = "Run custom code when this encounter ends. Alerts with encounter hooks are excluded from TimelineReminders." })
    encounterEndCodeBtn:SetPoint("LEFT", encounterStartCodeBtn.frame, "RIGHT", 8, 0)
    trigF.encounterEndCodeBtn = encounterEndCodeBtn

    local phaseChangeCodeBtn = CreateLocalizedSubButton(codeC, "Add Phase Change Code", function()
        OpenEncounterHookEditor("onPhaseChange", "Phase Change Function", DEFAULT_PHASE_CHANGE_CODE)
    end, 170, "NSUIEncAlertPhaseChangeHookBtn",
        { title = "Phase Change Code", desc = "Run custom code when this encounter changes phase. Alerts with encounter hooks are excluded from TimelineReminders." })
    phaseChangeCodeBtn:SetPoint("LEFT", encounterEndCodeBtn.frame, "RIGHT", 8, 0)
    trigF.phaseChangeCodeBtn = phaseChangeCodeBtn

    local function SaveTriggerSetting(editBox, key, isNumber)
        local value = editBox:GetText()
        if isNumber then
            value = tonumber(value)
        elseif key == "bossID" and value ~= "" then
            local units = {}
            for unit in value:gmatch("[^,]+") do
                local unitToken = unit:gsub("^%s+", ""):gsub("%s+$", "")
                if unitToken ~= "" then units[#units + 1] = unitToken end
            end
            if #units == 1 then
                value = units[1]
            elseif #units > 1 then
                value = units
            else
                value = nil
            end
        elseif value == "" then
            value = nil
        end
        if trigF._alert then NSI:SaveAlertData(trigF._alert, key, value) end
    end

    local castDurationLbl = castC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(castDurationLbl, "small", "")
    castDurationLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(castDurationLbl, "Cast Duration (seconds)")
    castDurationLbl:SetPoint("TOPLEFT", castC, "TOPLEFT", 0, 0)

    local bossIDLbl = castC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(bossIDLbl, "small", "")
    bossIDLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(bossIDLbl, "Boss ID (unit token)")
    bossIDLbl:SetPoint("LEFT", castC, "LEFT", math.floor(trigInnerW / 2), 0)
    bossIDLbl:SetPoint("TOP", castDurationLbl, "TOP")

    local castDurationEntry = CreateTextEntry(castC, nil, nil, nil, 120, 22,
        nil, nil, nil, "NSUIEncAlertCastDuration")
    castDurationEntry:SetPoint("TOPLEFT", castDurationLbl, "BOTTOMLEFT", 0, -3)
    castDurationEntry.editBox:SetScript("OnEditFocusLost", function(self)
        SaveTriggerSetting(self, "castDuration", true)
    end)
    trigF.castDurationEntry = castDurationEntry

    local bossIDEntry = CreateTextEntry(castC, nil, nil, nil, 150, 22,
        nil, nil, nil, "NSUIEncAlertBossID")
    bossIDEntry:SetPoint("TOPLEFT", bossIDLbl, "BOTTOMLEFT", 0, -3)
    bossIDEntry.editBox:SetScript("OnEditFocusLost", function(self)
        SaveTriggerSetting(self, "bossID")
    end)
    trigF.bossIDEntry = bossIDEntry

    local bossEventLbl = castC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(bossEventLbl, "small", "")
    bossEventLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(bossEventLbl, "Boss Event")
    bossEventLbl:SetPoint("TOPLEFT", castDurationEntry.frame, "BOTTOMLEFT", 0, -10)

    local timerVarianceLbl = castC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(timerVarianceLbl, "small", "")
    timerVarianceLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(timerVarianceLbl, "Timer Variance (seconds)")
    timerVarianceLbl:SetPoint("LEFT", castC, "LEFT", math.floor(trigInnerW / 2), 0)
    timerVarianceLbl:SetPoint("TOP", bossEventLbl, "TOP")

    local bossEventEntry = CreateTextEntry(castC, nil, nil, nil, 150, 22,
        nil, nil, nil, "NSUIEncAlertBossEvent")
    bossEventEntry:SetPoint("TOPLEFT", bossEventLbl, "BOTTOMLEFT", 0, -3)
    bossEventEntry.editBox:SetScript("OnEditFocusLost", function(self)
        SaveTriggerSetting(self, "bossEvent")
    end)
    trigF.bossEventEntry = bossEventEntry

    local timerVarianceEntry = CreateTextEntry(castC, nil, nil, nil, 120, 22,
        nil, nil, nil, "NSUIEncAlertTimerVariance")
    timerVarianceEntry:SetPoint("TOPLEFT", timerVarianceLbl, "BOTTOMLEFT", 0, -3)
    timerVarianceEntry.editBox:SetScript("OnEditFocusLost", function(self)
        SaveTriggerSetting(self, "timerVariance", true)
    end)
    trigF.timerVarianceEntry = timerVarianceEntry

    -- Lock overlay for Trigger tab (shown when ReloeReminder is selected)
    -- transparent=true so the triggers are still visible, just not interactable
    trigF.lockOverlay = MakeLockOverlay(trigF, nil, true)

    searchScroll.Trigger = trigScroll
    Reg("Trigger", "Encounter", "Boss", trigBossLbl)
    Reg("Trigger", "Encounter", "Difficulty", trigDiffLbl)
    Reg("Trigger", "Timing", "Phase", phaseLbl)
    Reg("Trigger", "Timing", "Trigger Times (seconds into phase)", timesLbl)
    Reg("Trigger", "Timing", "Add time (s)", addTimeLbl)
    Reg("Trigger", "Timing", "Phase-specific timers", phaseSpecificCB)
    Reg("Trigger", "Conditions & Code", "Add Condition", conditionBtn)
    Reg("Trigger", "Conditions & Code", "Add Encounter Start Code", encounterStartCodeBtn)
    Reg("Trigger", "Conditions & Code", "Add Encounter End Code", encounterEndCodeBtn)
    Reg("Trigger", "Conditions & Code", "Add Phase Change Code", phaseChangeCodeBtn)
    Reg("Trigger", "Boss Cast Sync", "Cast Duration (seconds)", castDurationLbl)
    Reg("Trigger", "Boss Cast Sync", "Boss ID (unit token)", bossIDLbl)
    Reg("Trigger", "Boss Cast Sync", "Boss Event", bossEventLbl)
    Reg("Trigger", "Boss Cast Sync", "Timer Variance (seconds)", timerVarianceLbl)
    end -- TRIGGER TAB

    -- ================================================================
    -- SOUND TAB
    -- ================================================================
    do
    sndF = innerTabFrames["Sound"]
    local sndStack = CreateCardStack(sndF)
    local sndInnerW = sndStack.innerW
    local ttsC   = sndStack:Add("Text-to-Speech", 156)
    local soundC = sndStack:Add("Sound File", 38)

    sndHint = sndF:CreateFontString(nil, "OVERLAY")
    sndHint:Hide()

    local ttsCB = CreateCheckButton(ttsC, NSI:Loc("Enable Text-to-Speech"),
        function() return false end,
        function(_, v)
            if not sndF._alert then return end
            local txt = sndF.ttsTextEntry and sndF.ttsTextEntry:GetValue() or ""
            NSI:SaveAlertData(sndF._alert, "TTS", v and ((txt ~= "") and txt or true) or false)
        end,
        sndInnerW, 22, "NSUIEncAlertTTSCB")
    ttsCB:SetLocaleKey("Enable Text-to-Speech")
    ttsCB:SetPoint("TOPLEFT", ttsC, "TOPLEFT", 0, 0)
    sndF.ttsCB = ttsCB

    local ttsTextLbl = ttsC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ttsTextLbl, "small", "")
    ttsTextLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(ttsTextLbl, "TTS Text (leave blank to speak the Display Text)")
    ttsTextLbl:SetPoint("TOPLEFT", ttsC, "TOPLEFT", 0, -30)

    local ttsTextEntry = CreateTextEntry(ttsC, nil, nil, nil, sndInnerW, 22,
        nil, nil, nil, "NSUIEncAlertTTSText")
    ttsTextEntry:SetPoint("TOPLEFT", ttsC, "TOPLEFT", 0, -46)
    local function SaveTTSText(self)
        local v = self:GetText()
        if not sndF._alert then return end
        if sndF._alert.TTS ~= false then
            NSI:SaveAlertData(sndF._alert, "TTS", (v ~= "") and v or true)
        end
    end
    ttsTextEntry.editBox:SetScript("OnEditFocusLost", SaveTTSText)
    sndF.ttsTextEntry = ttsTextEntry

    local ttsTimerLbl = ttsC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(ttsTimerLbl, "small", "")
    ttsTimerLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(ttsTimerLbl, "TTS Timer (seconds before the Alert expires)")
    ttsTimerLbl:SetPoint("TOPLEFT", ttsC, "TOPLEFT", 0, -78)

    local ttsTimerEntry = CreateTextEntry(ttsC, nil, nil, nil, 80, 22,
        nil, nil, nil, "NSUIEncAlertTTSTimer",
        { title = "TTS Timer", desc = "Remaining duration at which the TTS or Sound should play" })
    ttsTimerEntry:SetPoint("TOPLEFT", ttsC, "TOPLEFT", 0, -94)
    local function SaveTTSTimer(self)
        local v = tonumber(self:GetText())
        if sndF._alert then NSI:SaveAlertData(sndF._alert, "TTSTimer", v or 8) end
    end
    ttsTimerEntry.editBox:SetScript("OnEditFocusLost", SaveTTSTimer)
    sndF.ttsTimerEntry = ttsTimerEntry

    local cdLbl = ttsC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(cdLbl, "small", "")
    cdLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(cdLbl, "Countdown for")
    cdLbl:SetPoint("TOPLEFT", ttsC, "TOPLEFT", 0, -134)
    sndF.cdLbl = cdLbl

    local cdEntry = CreateTextEntry(ttsC, nil, nil, nil, 60, 22,
        nil, nil, nil, "NSUIEncAlertCountdown",
        { title = "Countdown", desc = "At how many seconds remaining you would like to hear a TTS countdown" })
    cdEntry:SetPoint("LEFT", cdLbl, "RIGHT", 6, 0)
    cdEntry:SetPoint("TOP",  cdLbl, "TOP", 0, 6)
    local function SaveCountdown(self)
        local v = tonumber(self:GetText())
        if sndF._alert then NSI:SaveAlertData(sndF._alert, "countdown", (v and v > 0) and v or false) end
    end
    cdEntry.editBox:SetScript("OnEditFocusLost", SaveCountdown)
    sndF.cdEntry = cdEntry

    local cdSecLbl = ttsC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(cdSecLbl, "small", "")
    cdSecLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(cdSecLbl, "seconds")
    cdSecLbl:SetPoint("LEFT", cdEntry.frame, "RIGHT", 5, 0)

    local sndFileLbl = soundC:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(sndFileLbl, "small", "")
    sndFileLbl:SetTextColor(unpack(STYLE.text_muted))
    SetLocalizedText(sndFileLbl, "Sound File")
    sndFileLbl:SetPoint("TOPLEFT", soundC, "TOPLEFT", 0, 0)

    local soundGetItems, soundGetSelected = NSI:BuildSoundDropdown(
        function() return sndF._alert and sndF._alert.sound end,
        function(v) if sndF._alert then NSI:SaveAlertData(sndF._alert, "sound", v) end end
    )
    local soundDD = CreateDropdown(soundC, nil, soundGetItems, soundGetSelected,
        sndInnerW, 22, "NSUIEncAlertSound",
        { title = "Sound File", desc = "If you select a sound here it will take priority over any configured TTS. It will still use the TTS-Timer field to determine when to play" },
        nil, nil, true)
    soundDD:SetPoint("TOPLEFT", soundC, "TOPLEFT", 0, -16)
    sndF.soundDD = soundDD

    searchScroll.Sound = sndStack.scroll
    Reg("Sound", "Text-to-Speech", "Enable Text-to-Speech", ttsCB)
    Reg("Sound", "Text-to-Speech", "TTS Text (leave blank to speak the Display Text)", ttsTextLbl)
    Reg("Sound", "Text-to-Speech", "TTS Timer (seconds before the Alert expires)", ttsTimerLbl)
    Reg("Sound", "Text-to-Speech", "Countdown for", cdLbl)
    Reg("Sound", "Sound File", "Sound File", sndFileLbl)
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
    local namesListH     = 90    -- height of the names scroll list
    local Components     = NSI.UI.Components
    local CARD_PAD, CARD_GAP = Components.CardPad, Components.CardGap
    local namesContentH  = 22 + 8 + namesListH
    local namesCard = Components.CreateSectionCard(loadF, rightW, true)
    SetLocalizedText(namesCard.title, "Character Names (no server name)")
    namesCard.content:SetHeight(namesContentH)
    namesCard:SetHeight(namesCard.headerH + CARD_PAD * 2 + namesContentH)
    namesCard:SetPoint("BOTTOMLEFT", loadF, "BOTTOMLEFT", 0, 0)
    namesCard:SetPoint("BOTTOMRIGHT", loadF, "BOTTOMRIGHT", 0, 0)
    namesCard.content:SetPoint("TOPRIGHT", namesCard, "TOPRIGHT", -CARD_PAD, -(namesCard.headerH + CARD_PAD))
    local NAMES_SEC_H = namesCard:GetHeight() + CARD_GAP   -- reserved at the bottom

    -- ── Main scroll (classes + specs), fills loadF above the names section ───
    -- Height = panel height - rightPanel margins(20) - inner-tab header(68) - names section(NAMES_SEC_H+4)
    local rolesCard = Components.CreateSectionCard(loadF, rightW, true)
    SetLocalizedText(rolesCard.title, "Roles, Classes & Specs")
    rolesCard:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, 0)
    rolesCard:SetPoint("BOTTOMRIGHT", loadF, "BOTTOMRIGHT", 0, NAMES_SEC_H)   -- fills the space above the names card
    rolesCard.content:SetPoint("BOTTOMRIGHT", rolesCard, "BOTTOMRIGHT", -CARD_PAD, CARD_PAD)
    local loadScrollH = tab_content_height - 20 - 68 - NAMES_SEC_H - rolesCard.headerH - CARD_PAD * 2
    rolesCard.content:SetHeight(loadScrollH)
    rolesCard:SetHeight(rolesCard.headerH + CARD_PAD * 2 + loadScrollH)
    local loadScroll = CreateFrame("ScrollFrame", "NSUIEncAlertLoadScroll", rolesCard.content,
        "UIPanelScrollFrameTemplate")
    NSI.UI.Components.EnableSmoothScroll(loadScroll)
    loadScroll:SetPoint("TOPLEFT", rolesCard.content, "TOPLEFT", 0, 0)
    loadScroll:SetPoint("BOTTOMRIGHT", rolesCard.content, "BOTTOMRIGHT", 0, 0)
    loadScroll:EnableMouseWheel(true)
    ReskinScrollbar(loadScroll)
    StyleListBox(loadScroll)

    local loadScrollChild = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, loadScroll)
    loadScrollChild:SetSize(loadListW - 18, loadListH)
    loadScrollChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    loadScrollChild:SetBackdropColor(unpack(STYLE.surface_inset))
    loadScroll:SetScrollChild(loadScrollChild)

    -- Collapse state per section (persists across Rebuild calls)
    local sectionCollapsed = { Roles = true, Classes = true, Specs = true }
    local RebuildLoadTab  -- forward declaration

    local function MakeSectionHdr(label, sectionKey)
        local btn = NSI.UI.Pixel.CreateBoxFrame("Button", nil, loadScrollChild)
        btn:SetBackdrop({
            bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
            tile     = true,
            tileSize = 64,
        })
        btn:SetBackdropColor(unpack(STYLE.selected_fill))
        btn:SetSize(loadListW - 18, 18)
        btn.arrowTex = btn:CreateTexture(nil, "OVERLAY")
        btn.arrowTex:SetSize(10, 10)
        btn.arrowTex:SetPoint("LEFT", btn, "LEFT", 2, 0)
        btn.arrowTex:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]])
        btn.arrowTex:SetVertexColor(unpack(STYLE.text_muted))
        btn.textLbl = btn:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(btn.textLbl, "tiny", "")
        btn.textLbl:SetTextColor(unpack(STYLE.text_muted))
        btn.textLbl:SetPoint("LEFT", btn, "LEFT", 16, 0)
        btn.textLbl:SetText(label)
        btn:SetScript("OnClick", function()
            sectionCollapsed[sectionKey] = not sectionCollapsed[sectionKey]
            if RebuildLoadTab then RebuildLoadTab() end
        end)
        btn:SetScript("OnEnter", function() btn.textLbl:SetTextColor(unpack(STYLE.text_soft)) end)
        btn:SetScript("OnLeave", function() btn.textLbl:SetTextColor(unpack(STYLE.text_muted)) end)
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
        NSI.UI.Style.PaintAccent(hoverTex, "SetColorTexture", 0.13)
        hoverBg:SetAlpha(0)
        row.hoverBg = hoverBg

        -- Checkbox box (styled like Components.lua CreateCheckButton)
        local checkBox = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, row)
        checkBox:SetSize(BOX, BOX)
        checkBox:SetPoint("LEFT", row, "LEFT", 4, 0)
        checkBox:SetFrameLevel(baseLevel + 2)
        checkBox:SetBackdrop({
            bgFile   = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        })
        checkBox:SetBackdropColor(unpack(STYLE.input_bg_color))
        checkBox:SetBackdropBorderColor(unpack(STYLE.border_subtle))
        row.checkBox = checkBox

        -- Cyan fill shown when selected
        local checkFill = checkBox:CreateTexture(nil, "ARTWORK")
        checkFill:SetPoint("TOPLEFT", checkBox, "TOPLEFT", 2, -2)
        checkFill:SetPoint("BOTTOMRIGHT", checkBox, "BOTTOMRIGHT", -2, 2)
        NSI.UI.Style.PaintAccent(checkFill, "SetColorTexture", 0.85)
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
        NSI:SetUIFont(row.nameLbl, "small", "")
        row.nameLbl:SetAllPoints(lblFrame)
        row.nameLbl:SetJustifyH("LEFT")
        row.nameLbl:SetJustifyV("MIDDLE")

        row:SetScript("OnEnter", function()
            NSI.UI.Components.FadeTo(hoverBg, 1, 0.12)
        end)
        row:SetScript("OnLeave", function()
            NSI.UI.Components.FadeTo(hoverBg, 0, 0.2)
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
        else        row.nameLbl:SetTextColor(unpack(STYLE.text_color)) end
        row.nameLbl:SetText(NSI:Loc(cd.label))
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
        else       row.nameLbl:SetTextColor(unpack(STYLE.text_soft)) end
        row.nameLbl:SetText(NSI:Loc(sd.label))
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
        row.nameLbl:SetText(NSI:Loc(rd.label))
        row._roleKey = rd.key
        roleRowFrames[i] = row
        row:Hide()
    end

    -- ── Names section (fixed at bottom of loadF) ──────────────────────────────

    local nameAddEntry = CreateTextEntry(namesCard.content, nil, nil, nil, 180, 22,
        nil, nil, nil, "NSUIEncAlertNameAdd")
    nameAddEntry:SetPoint("TOPLEFT", namesCard.content, "TOPLEFT", 0, 0)

    local DoAddName  -- forward declaration so nameAddBtn closure can reference it
    local nameAddBtn = CreateLocalizedSubButton(namesCard.content, "Add", function() if DoAddName then DoAddName() end end,
        54, "NSUIEncAlertNameAddBtn")
    nameAddBtn:SetPoint("LEFT", nameAddEntry.frame, "RIGHT", 6, 0)

    local namesScroll = CreateFrame("ScrollFrame", "NSUIEncAlertNamesScroll", namesCard.content,
        "UIPanelScrollFrameTemplate")
    NSI.UI.Components.EnableSmoothScroll(namesScroll)
    namesScroll:SetHeight(namesListH)
    namesScroll:SetPoint("TOPLEFT", namesCard.content, "TOPLEFT", 0, -30)
    namesScroll:SetPoint("TOPRIGHT", namesCard.content, "TOPRIGHT", 0, -30)
    namesScroll:EnableMouseWheel(true)
    ReskinScrollbar(namesScroll)
    StyleListBox(namesScroll)
    local namesBg = namesScroll:CreateTexture(nil, "BACKGROUND")
    namesBg:SetAllPoints(namesScroll)
    namesBg:SetColorTexture(unpack(STYLE.surface_inset))

    local namesChild = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, namesScroll)
    namesChild:SetSize(loadListW - 18, 1)
    namesChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    namesChild:SetBackdropColor(unpack(STYLE.surface_inset))
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
                NSI:SetUIFont(nameRows[i].nLbl, "small", "")
                nameRows[i].nLbl:SetPoint("LEFT", nameRows[i], "LEFT", 8, 0)
                nameRows[i].nLbl:SetTextColor(unpack(STYLE.text_color))
                nameRows[i].delBtn = CreateFrame("Button", nil, nameRows[i])
                nameRows[i].delBtn:SetSize(14, 14)
                nameRows[i].delBtn:SetPoint("RIGHT", nameRows[i], "RIGHT", -6, 0)
                nameRows[i].delBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                nameRows[i].delBtn:GetNormalTexture():SetDesaturated(true)
                nameRows[i].delBtn:GetNormalTexture():SetVertexColor(unpack(STYLE.danger))
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
                            row.checkBox:SetBackdropBorderColor(Accent(0.9))
                    else
                        row.bg:SetColorTexture(
                            i % 2 == 0 and 0.12 or 0,
                            i % 2 == 0 and 0.12 or 0,
                            i % 2 == 0 and 0.12 or 0,
                            i % 2 == 0 and 0.5 or 0)
                            row.checkFill:Hide()
                            row.checkBox:SetBackdropBorderColor(unpack(STYLE.border_subtle))
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

    -- Window resize: the Load tab's rows follow the scroll box's new width.
    NSI.UI.Components.RegisterRelayout(loadF, function()
        local w = loadScroll:GetWidth()
        if not w or w < 100 then return end
        loadListW = w
        loadScrollChild:SetWidth(w - 18)
        namesChild:SetWidth(w - 18)
        classSecHdr:SetWidth(w - 18); specSecHdr:SetWidth(w - 18); rolesSecHdr:SetWidth(w - 18)
        for _, set in ipairs({ roleRowFrames, classRowFrames, specRowFrames }) do
            for _, r in ipairs(set) do r:SetWidth(w - 18) end
        end
        for _, r in ipairs(nameRows) do r:SetWidth(w - 18) end
    end)

    -- Lock overlay for Load tab (reloeCreated alerts use built-in role field)
    loadF.lockOverlay = MakeLockOverlay(loadF,
        "Class / spec filters do not apply\nto addon-created alerts.")

    -- Lock overlay for Sound tab (reloeCreated alerts — sound is managed by the addon)
    sndF.lockOverlay = MakeLockOverlay(sndF,
        "Sound settings are fixed\nfor this alert.")

    Reg("Load", "Load", "Roles, Classes & Specs", rolesCard)
    Reg("Load", "Load", "Character Names (no server name)", namesCard)
    end -- LOAD TAB

    -- ================================================================
    -- OPTIONS TAB
    -- ================================================================
    do
    local optF = innerTabFrames["Options"]

    local authorMode = false
    local authorModeAlert

    -- The Options tab is built once. Its scroll box, buttons and widget hosts are
    -- created on first use and re-dressed for each entry; building them per
    -- selection leaked a scroll box and every widget on each click.
    local optScroll, optReloeHost, optCustomHost, optCustomFrame, optAuthorCard
    local optAuthorButton, optPreviewButton, optAddOptionButton
    local optAuthorRows = {}
    local optEntry, optScrollEntry
    local optContentWidth = 0

    -- extraOptions are written in the boss files (code-owned tables shared by every
    -- load). A short first Label is the card title, like the other tabs. The
    -- definitions are copied so card splitting never mutates the boss data.
    local TITLE_LABEL_MAX = 40
    local function ReloeOptionDefinitions(extraOptions)
        local defs = {}
        for index, def in ipairs(extraOptions or {}) do
            local copy = {}
            for key, value in pairs(def) do copy[key] = value end
            if index == 1 and copy.Type == "Label" and copy.highlight == nil then
                if #NSI:Loc(copy.text or "") <= TITLE_LABEL_MAX then
                    copy.highlight = true
                    copy.height = 22
                end
            end
            defs[index] = copy
        end
        return defs
    end

    local function OptionsAuthorRowRemove(self)
        local row = self.authorRow
        local entry, definition = optEntry, row.definition
        if not entry or not definition then return end
        for index, savedDefinition in ipairs(entry.customOptionDefinitions) do
            if savedDefinition.id == definition.id then
                table.remove(entry.customOptionDefinitions, index)
                break
            end
        end
        if entry.customOptionValues then entry.customOptionValues[definition.id] = nil end
        NSI:SaveAlertData(entry, "customOptionDefinitions", entry.customOptionDefinitions)
        NSI:SaveAlertData(entry, "customOptionValues", entry.customOptionValues or {})
        RebuildOptionsContent(entry)
    end

    local function NewOptionsAuthorRow(parent)
        local row = {}
        row.label = CreateLabel(parent, "", optContentWidth - NSI.UI.Components.CardPad * 2 - 76, 20)
        row.edit = CreateLocalizedSubButton(parent, "Edit", function()
            if optEntry and row.definition then OpenCustomOptionEditor(optEntry, row.definition) end
        end, 48)
        local removeButton = CreateFrame("Button", nil, parent)
        removeButton:SetSize(14, 14)
        removeButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        removeButton:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        removeButton:GetNormalTexture():SetDesaturated(true)
        removeButton:GetNormalTexture():SetVertexColor(unpack(STYLE.danger))
        removeButton:SetScript("OnEnter", function(self)
            NSI.UI.Tooltip.Show(self, "Remove", "ANCHOR_RIGHT")
        end)
        removeButton:SetScript("OnLeave", NSI.UI.Tooltip.Hide)
        removeButton.authorRow = row
        removeButton:SetScript("OnClick", OptionsAuthorRowRemove)
        row.remove = removeButton
        return row
    end

    local function EnsureOptionsUI()
        if optScroll then return end
        optScroll = NSI.UI.Components.CreateScrollBox(optF, rightW - 11, optF:GetHeight())
        optScroll.frame:SetPoint("TOPLEFT", optF, "TOPLEFT", 0, 0)
        optScroll.frame:SetPoint("BOTTOMRIGHT", optF, "BOTTOMRIGHT", -11, 0)
        local scrollChild = optScroll.scrollChild
        optContentWidth = scrollChild:GetWidth()
        optReloeHost = NSI.UI.Components.CreateCardHost(scrollChild, optContentWidth)

        -- Author tools (custom alerts only) sit in their own card.
        optAuthorCard = NSI.UI.Components.CreateSectionCard(scrollChild, optContentWidth, true)
        SetLocalizedText(optAuthorCard.title, "Author Mode")
        optAuthorCard:Hide()
        local authorContent = optAuthorCard.content

        optAuthorButton = CreateLocalizedSubButton(authorContent, "Enable Author Mode", function()
            authorMode = not authorMode
            if optEntry then RebuildOptionsContent(optEntry) end
        end, 160)
        optAuthorButton:SetPoint("TOPLEFT", authorContent, "TOPLEFT", 0, 0)

        optPreviewButton = CreateLocalizedSubButton(authorContent, "Add Custom Preview Code", function()
            if optEntry then OpenCustomPreviewEditor(optEntry) end
        end, 190)
        optPreviewButton:SetPoint("TOPLEFT", authorContent, "TOPLEFT", 0, -26)

        optAddOptionButton = CreateLocalizedSubButton(authorContent, "Add Custom Option", function()
            if optEntry then OpenCustomOptionEditor(optEntry) end
        end, 150)
        optAddOptionButton:SetPoint("LEFT", optPreviewButton.frame, "RIGHT", 8, 0)

        -- The user's custom options are drawn as a card too (a host parent frame that
        -- CardHost stacks its cards in).
        optCustomFrame = CreateFrame("Frame", nil, scrollChild)
        optCustomFrame:SetWidth(optContentWidth)
        optCustomHost = NSI.UI.Components.CreateCardHost(optCustomFrame, optContentWidth)
    end

    -- Everything the custom-alert layout shows, hidden for built-in alerts.
    local function HideCustomOptionsUI()
        optAuthorCard:Hide()
        optAuthorButton.frame:Hide()
        optPreviewButton.frame:Hide()
        optAddOptionButton.frame:Hide()
        optCustomHost:Hide()
        optCustomFrame:Hide()
        for _, row in ipairs(optAuthorRows) do
            row.label.frame:Hide(); row.edit.frame:Hide(); row.remove:Hide()
        end
    end

    RebuildOptionsContent = function(entry)
        if not entry then
            if optScroll then optScroll.frame:Hide() end
            return
        end
        if authorModeAlert ~= entry then
            authorModeAlert = entry
            authorMode = false
        end
        EnsureOptionsUI()
        optEntry = entry
        optScroll.frame:Show()
        local scrollChild = optScroll.scrollChild
        local contentWidth = optContentWidth
        local totalH = 0

        if entry.ReloeReminder then
            HideCustomOptionsUI()
            totalH = optReloeHost:Apply(ReloeOptionDefinitions(entry.extraOptions))
        else
            optReloeHost:Hide()
            local authorContent = optAuthorCard.content
            optAuthorCard:Show()
            optAuthorButton:SetLocaleKey(authorMode and "Disable Author Mode" or "Enable Author Mode")
            optAuthorButton.frame:Show()

            local y = 26   -- card-local y below the author-mode button
            if authorMode then
                optPreviewButton:SetLocaleKey(entry.customPreview and "Edit Custom Preview Code" or "Add Custom Preview Code")
                optPreviewButton.frame:Show()
                optAddOptionButton.frame:Show()
                y = y + 26
            else
                optPreviewButton.frame:Hide()
                optAddOptionButton.frame:Hide()
            end

            entry.customOptionDefinitions = entry.customOptionDefinitions or {}
            local authorRowCount = 0
            if authorMode then
                for _, definition in ipairs(entry.customOptionDefinitions) do
                    authorRowCount = authorRowCount + 1
                    local row = optAuthorRows[authorRowCount]
                    if not row then
                        row = NewOptionsAuthorRow(authorContent)
                        optAuthorRows[authorRowCount] = row
                    end
                    row.definition = definition
                    row.label:SetText((definition.name or NSI:Loc("Unnamed Option")) .. " (" .. NSI:Loc(definition.type or "Text") .. ")")
                    row.label.frame:ClearAllPoints()
                    row.label:SetPoint("TOPLEFT", authorContent, "TOPLEFT", 0, -y)
                    row.edit.frame:ClearAllPoints()
                    row.edit:SetPoint("TOPRIGHT", authorContent, "TOPRIGHT", -24, -y)
                    row.remove:ClearAllPoints()
                    row.remove:SetPoint("TOPRIGHT", authorContent, "TOPRIGHT", -2, -y - 3)
                    row.label.frame:Show(); row.edit.frame:Show(); row.remove:Show()
                    y = y + 24
                end
            end
            for i = authorRowCount + 1, #optAuthorRows do
                local row = optAuthorRows[i]
                row.definition = nil
                row.label.frame:Hide(); row.edit.frame:Hide(); row.remove:Hide()
            end

            -- Size and place the author card; the custom options card goes below it.
            local authorH = math.max(y - 4, 22)
            authorContent:SetHeight(authorH)
            optAuthorCard:SetHeight(optAuthorCard.headerH + NSI.UI.Components.CardPad * 2 + authorH)
            optAuthorCard:ClearAllPoints()
            optAuthorCard:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
            y = optAuthorCard:GetHeight() + NSI.UI.Components.CardGap

            local widgetDefinitions = {}
            entry.customOptionValues = entry.customOptionValues or {}
            local customOptionDefaultsAdded = false
            for definitionIndex, definition in ipairs(entry.customOptionDefinitions) do
                local optionID = definition.id
                local optionType = definition.type
                local defaultValue = definition.defaultValue
                local choices = definition.choices or {}
                if entry.customOptionValues[optionID] == nil then
                    if optionType == "Color" and type(defaultValue) == "table" then
                        entry.customOptionValues[optionID] = {defaultValue[1], defaultValue[2], defaultValue[3], defaultValue[4]}
                    else
                        entry.customOptionValues[optionID] = defaultValue
                    end
                    customOptionDefaultsAdded = true
                end

                local function GetCustomOptionValue()
                    local value = entry.customOptionValues[optionID]
                    if value == nil then return defaultValue end
                    return value
                end
                local function SetCustomOptionValue(nsi, value, green, blue, alpha)
                    if optionType == "Color" then
                        value = {value, green, blue, alpha}
                    end
                    entry.customOptionValues[optionID] = value
                    NSI:SaveAlertData(entry, "customOptionValues", entry.customOptionValues)
                end

                if optionType == "Number" then
                    widgetDefinitions[#widgetDefinitions + 1] = {
                        Type = "Slider", label = definition.name, min = definition.min, max = definition.max,
                        step = definition.step, decimals = definition.decimals,
                        get = GetCustomOptionValue, set = SetCustomOptionValue,
                    }
                elseif optionType == "Color" then
                    widgetDefinitions[#widgetDefinitions + 1] = {
                        Type = "Color", label = definition.name,
                        get = function()
                            local color = GetCustomOptionValue()
                            if type(color) ~= "table" then return 1, 1, 1, 1 end
                            return color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
                        end,
                        set = SetCustomOptionValue,
                    }
                elseif optionType == "Dropdown" then
                    local optionChoices = {}
                    for choiceIndex, choice in ipairs(choices) do
                        optionChoices[#optionChoices + 1] = { label = choice, value = choice }
                    end
                    widgetDefinitions[#widgetDefinitions + 1] = {
                        Type = "Dropdown", label = definition.name, get = GetCustomOptionValue,
                        set = SetCustomOptionValue, values = optionChoices,
                    }
                elseif optionType == "Checkbox" then
                    widgetDefinitions[#widgetDefinitions + 1] = {
                        Type = "Checkbox", label = definition.name,
                        get = GetCustomOptionValue, set = SetCustomOptionValue,
                    }
                else
                    widgetDefinitions[#widgetDefinitions + 1] = {
                        Type = "TextEntry", label = definition.name,
                        get = GetCustomOptionValue, set = SetCustomOptionValue, inputWidth = 180,
                    }
                end
            end

            if #widgetDefinitions > 0 then
                table.insert(widgetDefinitions, 1, { Type = "Label", text = "Custom Options", highlight = true, height = 22 })
            end
            optCustomFrame:ClearAllPoints()
            optCustomFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
            optCustomFrame:Show()
            local optionWidgetsHeight = optCustomHost:Apply(widgetDefinitions)
            optCustomFrame:SetHeight(math.max(optionWidgetsHeight, 1))
            totalH = optionWidgetsHeight > 0 and (y + optionWidgetsHeight) or (y - NSI.UI.Components.CardGap)
            if customOptionDefaultsAdded then
                NSI:SaveAlertData(entry, "customOptionValues", entry.customOptionValues)
            end
        end

        scrollChild:SetHeight(math.max(totalH, 1))
        -- Another alert starts at the top; edits to the same alert keep the scroll position.
        if optScrollEntry ~= entry then
            optScrollEntry = entry
            optScroll.frame:SetVerticalScroll(0)
        end
        optScroll:UpdateScrollBar()
    end
    searchOptions = function() return optEntry, ReloeOptionDefinitions, optReloeHost, optScroll end
    NSI.UI.Components.RegisterRelayout(optF, function()
        if optScroll then optScroll:UpdateScrollBar() end
    end)
    end -- OPTIONS TAB

    -- ================================================================
    -- Helper: set panel into custom-alert mode vs reloeCreated mode
    -- ================================================================
    local function SetTriggerEntriesEnabled(enabled)
        for _, entry in ipairs({
            trigF.phaseEntry,
            trigF.addTimeEntry,
            trigF.phaseSpecificEntry,
            trigF.castDurationEntry,
            trigF.bossIDEntry,
            trigF.bossEventEntry,
            trigF.timerVarianceEntry,
        }) do
            if enabled then
                entry:Enable()
            else
                entry:Disable()
            end
        end
    end

    local function SetCustomMode()
        trigF.lockOverlay:Hide()
        SetTriggerEntriesEnabled(true)
        loadF.lockOverlay:Hide()
        dispF.lockOverlay:Hide()
        sndF.lockOverlay:Hide()
        dispHint:Hide()
        sndHint:Hide()
        nameEntry.editBox:SetEnabled(true)
        nameEntry.editBox:SetAlpha(1)
        if activeInnerTab == "Options" then activeInnerTab = "Display" end
    end

    local function SetReloeCreatedMode(alert)
        trigF.lockOverlay:Show()
        SetTriggerEntriesEnabled(false)
        loadF.lockOverlay:Hide()
        dispF.lockOverlay:SetShown(alert and alert.NoEdit == true)
        sndF.lockOverlay:SetShown(alert and alert.NoEdit == true)
        dispHint:SetShown(false)
        sndHint:Hide()
        nameEntry.editBox:SetEnabled(false)
        nameEntry.editBox:SetAlpha(0.45)
    end

    -- ================================================================
    -- PreviewAlert ── fire the current alert visually without a trigger
    -- ================================================================
    PreviewAlert = function()
        if not dispF._alert then return end
        if NSI:RunCustomAlertPreview(dispF._alert, selectedEncID, selectedKey) then return end
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
        local info = NSI:CreateReminder(dispF._alert, true)
        NSI:HideAllReminders()
        NSI:DisplayReminder(info, true)
    end

    -- ================================================================
    -- ================================================================
    -- SelectAlert ── load any alert (Reloe or user-created) into the right panel
    -- ================================================================
    SelectAlert = function(key, diffID, encID)
        SetTriggerEntriesEnabled(false)
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
        if isReloe then SetReloeCreatedMode(entry) else SetCustomMode() end
        PositionInnerTabLayout(GetConditionText(entry.isConditional))

        dispF._alert = entry; dispF._hardcodedEncID = nil
        trigF._alert = not isReloe and entry or nil; trigF._hardcodedEncID = nil
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
            NSI:SaveAlertData(entry, "enabled", v, selectedEncID, selectedDiffID, selectedKey)
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
        dispF.hideTimerCB:SetValue(entry.HideTimer ~= nil and entry.HideTimer or false)
        local hideSwipe = entry.HideSwipe
        if hideSwipe == nil then hideSwipe = NSRT.ReminderSettings.IconSettings.HideSwipe end
        dispF.hideSwipeCB:SetValue(hideSwipe)
        local showBg = entry.showBackground
        if showBg == nil then showBg = NSRT.ReminderSettings.CircleSettings.showBackground end
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
        trigF.phaseEntry:SetValue(FormatPhaseValue(entry.phase))
        trigF.phaseSpecificCB:SetValue(entry.phaseTimers ~= nil)
        trigF.phaseSpecificEntry:SetValue(tostring(NSI:GetPrimaryPhase(entry.phase) or 1))
        if trigF.RefreshPhaseSpecificControls then trigF.RefreshPhaseSpecificControls() end
        trigF.RebuildTimeRows(entry)
        trigF.conditionBtn:SetText(NSI:Loc(entry.isConditional and "Edit Condition" or "Add Condition"))
        trigF.encounterStartCodeBtn:SetText(NSI:Loc(entry.onEncounterStart and "Edit Encounter Start Code" or "Add Encounter Start Code"))
        trigF.encounterEndCodeBtn:SetText(NSI:Loc(entry.onEncounterEnd and "Edit Encounter End Code" or "Add Encounter End Code"))
        trigF.phaseChangeCodeBtn:SetText(NSI:Loc(entry.onPhaseChange and "Edit Phase Change Code" or "Add Phase Change Code"))
        trigF.castDurationEntry:SetValue(entry.castDuration ~= nil and tostring(entry.castDuration) or "")
        trigF.bossIDEntry:SetValue(type(entry.bossID) == "table" and table.concat(entry.bossID, ", ") or (entry.bossID and tostring(entry.bossID) or ""))
        trigF.bossEventEntry:SetValue(entry.bossEvent or "")
        trigF.timerVarianceEntry:SetValue(entry.timerVariance ~= nil and tostring(entry.timerVariance) or "")

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

        -- Custom alerts always expose their editable preview and option definitions.
        local hasOptions = not isReloe or entry.extraOptions ~= nil
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

    screen.OpenAlert = function(screenFrame, encID, diffID, internalID)
        if not encID or not diffID or not internalID then return false end
        local difficultyAlerts = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][diffID]
        if not difficultyAlerts then return false end

        local alertKey
        local selectedAlert
        for key, alert in pairs(difficultyAlerts) do
            if type(alert) == "table" and alert.internalID == internalID then
                alertKey = key
                selectedAlert = alert
                break
            end
        end
        if not alertKey then return false end

        filterEncID = encID
        filterDiffID = diffID
        if selectedAlert.group and selectedAlert.group ~= "" then
            EnsureGroup(encID, selectedAlert.group)
            NSRT.Alerts.Groups[GroupKey(encID, selectedAlert.group)].collapsed = false
        end
        filterDD:Refresh()
        RebuildList()
        SelectAlert(alertKey, diffID, encID)
        return true
    end

    SelectInnerTab("Display")
    RefreshSectionCopyButtons()

    screen:SetScript("OnShow", function()
        RebuildList()
        if selectedEncID and selectedKey then
            SelectAlert(selectedKey, selectedDiffID or filterDiffID, selectedEncID)
        end
    end)

    -- Addon-wide search (Search.lua): index the selected alert's boss-specific options.
    -- Display/Trigger/Sound/Load are hand-placed widgets and stay with the scoped search below.
    screen.SearchPanels = function()
        local optEntry, ReloeOptionDefinitions = searchOptions()
        if not (optEntry and optEntry.extraOptions) then return nil end
        return { { id = "Options", title = "Options", defs = ReloeOptionDefinitions(optEntry.extraOptions) } }
    end
    screen.SearchReveal = function(id)
        SelectInnerTab("Options")
        local _, _, host, scroll = searchOptions()
        return host, scroll
    end

    -- Header search: settings of the selected alert (all five inner tabs, plus the
    -- boss-specific options Reloe defines in extraOptions).
    do
        local I = NSI.UI.Search.Internals
        local function Reveal(tab, getItem, getScroll)
            SelectInnerTab(tab)
            -- the inner tab was just shown: measure on the next frame
            C_Timer.After(0, function()
                local item = getItem()
                if not item or not item:IsShown() then return end
                local scroll = getScroll and getScroll()
                if scroll then scroll:ScrollToFrame(item) end
                I.Pulse(item)
            end)
        end

        NSI.UI.ScopedSearch.Create(screen, "NSUIEncAlertSettingsSearch", {
            collect = function(add)
                if not dispF._alert then return end
                local displayType = dispF._displayType
                for _, r in ipairs(searchables) do
                    if not r.types or (displayType and r.types[displayType]) then
                        local target = r.target.frame or r.target
                        add(r.key, NSI:Loc(r.tab) .. "  >  " .. NSI:Loc(r.crumb), nil, function()
                            Reveal(r.tab, function() return target end, function() return searchScroll[r.tab] end)
                        end)
                    end
                end
                -- Reloe's boss-specific options
                local optEntry, ReloeOptionDefinitions = searchOptions()
                local hasOptions = optEntry and optEntry.extraOptions and innerTabBtns["Options"].frame:IsShown()
                if hasOptions then
                    for index, def in ipairs(ReloeOptionDefinitions(optEntry.extraOptions)) do
                        local label = def.label or def.text
                        if def.Type ~= "Label" and def.Type ~= "Breakline" and label then
                            add(label, NSI:Loc("Options"), def.tooltip, function()
                                Reveal("Options", function()
                                    local _, _, host = searchOptions()
                                    local set = host and host.current
                                    local item = set and set.byIndex[index]
                                    return item and item.frame
                                end, function() local _, _, _, scroll = searchOptions(); return scroll end)
                            end)
                        end
                    end
                end
            end,
        })
    end

    return screen
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.EncounterAlerts = {
    BuildEncounterAlertsUI = BuildEncounterAlertsUI,
}
