local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local contentWidth = Core.content_width
local tabContentHeight = Core.tab_content_height
local CreateLocalizedButton = NSI.UI.Components.CreateLocalizedButton
local CreateLocalizedSubButton = NSI.UI.Components.CreateLocalizedSubButton
local CreateCheckButton = NSI.UI.Components.CreateCheckButton
local CreateScrollBox = NSI.UI.Components.CreateScrollBox
local CreateTextEntry = NSI.UI.Components.CreateTextEntry
local BuildWidgets = NSI.UI.Components.BuildWidgets
local ShowContextMenu = NSI.UI.Components.ShowContextMenu
local ReskinScrollbar = NSI.UI.Components.ReskinScrollbar
local BossData = NSI.UI.BossData
local ChevronDown = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]]
local ChevronUp = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-up.png]]

local auraGlowExportPopup
local auraGlowImportPopup

local function ShowAuraGlowExportPopup(text)
    if not auraGlowExportPopup then
        auraGlowExportPopup = DF:CreateSimplePanel(UIParent, 800, 400, "|cFF00FFFF" .. NSI:Loc("Export Aura Glows") .. "|r", "NSRTAuraGlowExportPopup", { UseScaleBar = false })
        auraGlowExportPopup:SetPoint("CENTER")
        auraGlowExportPopup.textbox = DF:NewSpecialLuaEditorEntry(auraGlowExportPopup, 280, 80, nil, "NSRTAuraGlowExportTextBox", "$parentTextBox")
        auraGlowExportPopup.textbox:SetPoint("TOPLEFT", auraGlowExportPopup, "TOPLEFT", 10, -35)
        auraGlowExportPopup.textbox:SetPoint("BOTTOMRIGHT", auraGlowExportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(auraGlowExportPopup.textbox)
        local done = DF:CreateButton(auraGlowExportPopup, function() auraGlowExportPopup:Hide() end, 100, 20, NSI:Loc("Done"))
        done:SetPoint("BOTTOM", auraGlowExportPopup, "BOTTOM", 0, 10)
    end
    auraGlowExportPopup.textbox:SetText(text)
    auraGlowExportPopup.textbox:SetFocus()
    auraGlowExportPopup:Show()
end

local function ShowAuraGlowImportPopup(onImport)
    if not auraGlowImportPopup then
        auraGlowImportPopup = DF:CreateSimplePanel(UIParent, 800, 400, "|cFF00FFFF" .. NSI:Loc("Import Aura Glows") .. "|r", "NSRTAuraGlowImportPopup", { UseScaleBar = false })
        auraGlowImportPopup:SetPoint("CENTER")
        auraGlowImportPopup.status = auraGlowImportPopup:CreateFontString(nil, "OVERLAY")
        auraGlowImportPopup.status:SetPoint("TOPLEFT", auraGlowImportPopup, "TOPLEFT", 10, -30)
        auraGlowImportPopup.textbox = DF:NewSpecialLuaEditorEntry(auraGlowImportPopup, 280, 80, nil, "NSRTAuraGlowImportTextBox", "$parentTextBox")
        auraGlowImportPopup.textbox:SetPoint("TOPLEFT", auraGlowImportPopup, "TOPLEFT", 10, -50)
        auraGlowImportPopup.textbox:SetPoint("BOTTOMRIGHT", auraGlowImportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(auraGlowImportPopup.textbox)
        local import = DF:CreateButton(auraGlowImportPopup, function()
            local success = NSI:ImportAuraGlowString(auraGlowImportPopup.textbox:GetText())
            if success then
                auraGlowImportPopup:Hide()
                if auraGlowImportPopup.onImport then auraGlowImportPopup.onImport() end
            else
                auraGlowImportPopup.status:SetText("|cFFFF0000" .. NSI:Loc("Invalid Aura Glow import string.") .. "|r")
            end
        end, 100, 20, NSI:Loc("Import"))
        import:SetPoint("BOTTOM", auraGlowImportPopup, "BOTTOM", 0, 10)
    end
    auraGlowImportPopup.onImport = onImport
    auraGlowImportPopup.status:SetText(NSI:Loc("Paste an Aura Glow export string below and click Import."))
    auraGlowImportPopup.textbox:SetText("")
    auraGlowImportPopup.textbox:SetFocus()
    auraGlowImportPopup:Show()
end

local FilterStates = {
    { label = "Disabled", value = "Disabled" },
    { label = "Enabled", value = "Enabled" },
    { label = "Inverted", value = "Inverted" },
}

local AuraTypes = {
    { label = "Debuffs", value = "Debuffs" },
    { label = "Buffs", value = "Buffs" },
}

local BuffFilteringModes = {
    { label = "Spell IDs", value = "SpellIDs" },
    { label = "Aura Filters", value = "Filters" },
}

local DefaultIcon = 134400

local ProcessedAuraTypes = {
    { label = "Disabled", value = "Disabled" },
    { label = "Buff", value = "Buff" },
    { label = "Debuff", value = "Debuff" },
    { label = "Dispel", value = "Dispel" },
}

local RoleData = {
    { key = "TANK", label = "Tank" }, { key = "HEALER", label = "Healer" },
    { key = "DAMAGER", label = "DPS" }, { key = "MELEE", label = "Melee" }, { key = "RANGED", label = "Ranged" },
}
local RoleColors = {
    TANK = { 0.3, 0.5, 1.0 }, HEALER = { 0.3, 0.9, 0.3 }, DAMAGER = { 0.9, 0.2, 0.2 },
    MELEE = { 0.95, 0.55, 0.2 }, RANGED = { 0.9, 0.8, 0.2 },
}

local ClassData = {
    { key = "WARRIOR", label = "Warrior" }, { key = "PALADIN", label = "Paladin" },
    { key = "HUNTER", label = "Hunter" }, { key = "ROGUE", label = "Rogue" },
    { key = "PRIEST", label = "Priest" }, { key = "DEATHKNIGHT", label = "Death Knight" },
    { key = "SHAMAN", label = "Shaman" }, { key = "MAGE", label = "Mage" },
    { key = "WARLOCK", label = "Warlock" }, { key = "MONK", label = "Monk" },
    { key = "DRUID", label = "Druid" }, { key = "DEMONHUNTER", label = "Demon Hunter" },
    { key = "EVOKER", label = "Evoker" },
}

local SpecData = {
    { class="WARRIOR", id=71, label="Arms" }, { class="WARRIOR", id=72, label="Fury" }, { class="WARRIOR", id=73, label="Protection" },
    { class="PALADIN", id=65, label="Holy" }, { class="PALADIN", id=66, label="Protection" }, { class="PALADIN", id=70, label="Retribution" },
    { class="HUNTER", id=253, label="Beast Mastery" }, { class="HUNTER", id=254, label="Marksmanship" }, { class="HUNTER", id=255, label="Survival" },
    { class="ROGUE", id=259, label="Assassination" }, { class="ROGUE", id=260, label="Outlaw" }, { class="ROGUE", id=261, label="Subtlety" },
    { class="PRIEST", id=256, label="Discipline" }, { class="PRIEST", id=257, label="Holy" }, { class="PRIEST", id=258, label="Shadow" },
    { class="DEATHKNIGHT", id=250, label="Blood" }, { class="DEATHKNIGHT", id=251, label="Frost" }, { class="DEATHKNIGHT", id=252, label="Unholy" },
    { class="SHAMAN", id=262, label="Elemental" }, { class="SHAMAN", id=263, label="Enhancement" }, { class="SHAMAN", id=264, label="Restoration" },
    { class="MAGE", id=62, label="Arcane" }, { class="MAGE", id=63, label="Fire" }, { class="MAGE", id=64, label="Frost" },
    { class="WARLOCK", id=265, label="Affliction" }, { class="WARLOCK", id=266, label="Demonology" }, { class="WARLOCK", id=267, label="Destruction" },
    { class="MONK", id=268, label="Brewmaster" }, { class="MONK", id=269, label="Windwalker" }, { class="MONK", id=270, label="Mistweaver" },
    { class="DRUID", id=102, label="Balance" }, { class="DRUID", id=103, label="Feral" }, { class="DRUID", id=104, label="Guardian" }, { class="DRUID", id=105, label="Restoration" },
    { class="DEMONHUNTER", id=577, label="Havoc" }, { class="DEMONHUNTER", id=581, label="Vengeance" }, { class="DEMONHUNTER", id=1480, label="Devourer" },
    { class="EVOKER", id=1467, label="Devastation" }, { class="EVOKER", id=1468, label="Preservation" }, { class="EVOKER", id=1473, label="Augmentation" },
}

local function ClassColor(class)
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.6, 0.6, 0.6
end

local function BuildAuraGlowsUI(screen)
    local pad, leftWidth = 10, 240
    local rightX = leftWidth + pad * 2
    local rightWidth = contentWidth - rightX - pad
    local tabContentH = tabContentHeight - 62
    local tabScrollW = rightWidth - 14
    local selectedKey = NSRT.AuraGlows.UI.Selected
    local searchText = ""
    local activeTab = "Display"
    local listRows, headerRows = {}, {}
    local tabScroll = {}
    local RebuildList, RebuildTab, RebuildLoadTab, SelectEntry

    local title = screen:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, -10)
    title:SetText(NSI:Loc("|cFF00FFFFAura|r Glows"))

    local useBuiltinsCheckbox = CreateCheckButton(screen, NSI:Loc("Enable All Built-in Aura Glows"), function()
        return NSRT.AuraGlows.UseBuiltinAuraGlows
    end, function(_, enabled)
        NSI:SetUseBuiltinAuraGlows(enabled)
    end, leftWidth - pad * 2, 22, "NSUIAuraGlowUseBuiltins", NSI:Loc("Automatically enables all current and future built-in Aura Glows. Manual enabled-state changes are kept."))
    useBuiltinsCheckbox:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, -60)
    NSI:SetUIFont(useBuiltinsCheckbox.label, 11, "")

    local searchEntry = CreateTextEntry(screen, nil, nil, nil, leftWidth - pad * 2, 22, nil, nil, nil, "NSUIAuraGlowSearch")
    searchEntry:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, -34)
    local searchHint = searchEntry.editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", searchEntry.editBox, "LEFT", 2, 0)
    searchHint:SetText("|TInterface\\Common\\UI-Searchbox-Icon:16:16:0:-2|t  " .. NSI:Loc("Search..."))
    searchEntry.editBox:SetScript("OnTextChanged", function(editBox) searchText = editBox:GetText(); searchHint:SetShown(searchText == ""); RebuildList() end)

    local createButton = CreateLocalizedButton(screen, "Create Aura Glow", function()
        local key = NSI:AddCustomAuraGlow()
        RebuildList()
        SelectEntry(key)
    end, leftWidth - pad * 2, 22, "NSUIAuraGlowCreate")
    createButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, pad + 24)
    local importButton = CreateLocalizedButton(screen, "Import", function()
        ShowAuraGlowImportPopup(function() RebuildList(); RebuildTab() end)
    end, leftWidth - pad * 2, 22, "NSUIAuraGlowImport")
    importButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, pad)

    local listScroll = CreateFrame("ScrollFrame", "NSUIAuraGlowListScroll", screen, "UIPanelScrollFrameTemplate")
    listScroll:SetSize(leftWidth - pad * 2, tabContentHeight - 114)
    listScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, -86)
    ReskinScrollbar(listScroll)
    local listChild = CreateFrame("Frame", nil, listScroll, "BackdropTemplate")
    listChild:SetSize(leftWidth - pad * 2, 1)
    listChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    listChild:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
    listScroll:SetScrollChild(listChild)

    local rightPanel = CreateFrame("Frame", nil, screen)
    rightPanel:SetPoint("TOPLEFT", screen, "TOPLEFT", rightX, -10)
    rightPanel:SetSize(rightWidth, tabContentHeight - 10)

    local nameEntry = CreateTextEntry(rightPanel, nil, nil, nil, rightWidth - 180, 22, nil, nil, nil, "NSUIAuraGlowName")
    nameEntry:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)
    local previewButton = CreateLocalizedSubButton(rightPanel, "Preview", function()
        if selectedKey then NSI:ToggleAuraGlowPreview(selectedKey) end
    end, 76, "NSUIAuraGlowPreview")
    previewButton:SetPoint("LEFT", nameEntry.frame, "RIGHT", 8, 0)
    local deleteButton = CreateLocalizedSubButton(rightPanel, "Delete", function()
        NSI:DeleteCustomAuraGlow(selectedKey)
        selectedKey = nil
        NSRT.AuraGlows.UI.Selected = nil
        RebuildList()
        RebuildTab()
    end, 76, "NSUIAuraGlowDelete")
    deleteButton:SetPoint("LEFT", previewButton.frame, "RIGHT", 8, 0)

    local tabButtons, tabFrames = {}, {}
    for index, name in ipairs({"Display", "Trigger", "Load"}) do
        local frame = CreateFrame("Frame", nil, rightPanel)
        frame:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -52)
        frame:SetSize(rightWidth, tabContentH)
        tabFrames[name] = frame
        local tabName = name
        tabButtons[name] = CreateLocalizedSubButton(rightPanel, name, function()
            activeTab = tabName
            RebuildTab()
        end, 84, "NSUIAuraGlowTab" .. name)
        tabButtons[name]:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", (index - 1) * 87, -28)
    end

    local function ApplySettings()
        NSI:RebuildAuraGlows()
        if selectedKey then NSI:RefreshAuraGlowPreview(selectedKey) end
        RebuildList()
    end

    local function GetSelectedSettings()
        return selectedKey and NSI:GetAuraGlowSettings(selectedKey)
    end

    local function ConfirmDelete(key, name)
        local dialog = NSI.UI.Components.CreateDialog("NSRTAuraGlowDelete" .. key:gsub("%W", "_"), NSI:Loc("Delete Aura Glow"), string.format(NSI:Loc("Delete '%s'?"), name or "?"), NSI:Loc("Cancel"), nil, NSI:Loc("Delete"), function()
            NSI:DeleteCustomAuraGlow(key)
            selectedKey = nil
            NSRT.AuraGlows.UI.Selected = nil
            RebuildList()
            RebuildTab()
        end)
        dialog:Show()
    end

    local function PromptNewGroup(onCreate)
        StaticPopupDialogs["NSRT_AURA_GLOW_NEW_GROUP"] = {
            text = NSI:Loc("Enter new group name:"), button1 = NSI:Loc("OK"), button2 = NSI:Loc("Cancel"), hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
            OnAccept = function(dialog)
                local name = strtrim(dialog.EditBox:GetText())
                if name ~= "" and onCreate then onCreate(name) end
            end,
        }
        StaticPopup_Show("NSRT_AURA_GLOW_NEW_GROUP")
    end

    local function EntryContextMenu(entry)
        local key, settings = entry.key, entry.settings
        local items = {
            { type = "button", label = NSI:Loc("Export"), fnc = function() ShowAuraGlowExportPopup(NSI:ExportAuraGlowEntry(key)) end },
        }
        if entry.builtin then
            items[#items + 1] = { type = "button", label = NSI:Loc("Reset"), fnc = function()
                NSI:ResetBuiltinAuraGlow(key)
                RebuildList()
                RebuildTab()
            end }
        else
            items[#items + 1] = { type = "button", label = NSI:Loc("Duplicate"), fnc = function()
                local newKey = NSI:DuplicateCustomAuraGlow(key)
                RebuildList()
                if newKey then SelectEntry(newKey) end
            end }
            local groups = { { type = "button", label = NSI:Loc("— No Group —"), fnc = function() NSI:SetAuraGlowEntryGroup(key, ""); RebuildList() end } }
            for _, group in ipairs(NSI:GetAuraGlowGroups()) do
                local groupName = group
                groups[#groups + 1] = { type = "button", label = groupName, fnc = function() NSI:SetAuraGlowEntryGroup(key, groupName); RebuildList() end }
            end
            groups[#groups + 1] = { type = "button", label = NSI:Loc("New Group..."), fnc = function()
                PromptNewGroup(function(groupName) NSI:SetAuraGlowEntryGroup(key, groupName); RebuildList() end)
            end }
            items[#items + 1] = { type = "submenu", label = NSI:Loc("Add to Group") .. "...", items = groups }
            items[#items + 1] = { type = "separator" }
            items[#items + 1] = { type = "button", label = NSI:Loc("Delete"), fnc = function() ConfirmDelete(key, settings.Name) end }
        end
        ShowContextMenu(items)
    end

    RebuildList = function()
        local entries = NSI:IterateAuraGlowEntries()
        local grouped, groupOrder = {}, {}
        local search = string.lower(searchText)
        for _, entry in ipairs(entries) do
            if search == "" or string.find(string.lower(entry.settings.Name or ""), search, 1, true) then
                local group = entry.group or ""
                if not grouped[group] then grouped[group] = {}; groupOrder[#groupOrder + 1] = group end
                grouped[group][#grouped[group] + 1] = entry
            end
        end
        table.sort(groupOrder, function(a, b)
            if a == NSI.AuraGlowBuiltinGroup then return true end
            if b == NSI.AuraGlowBuiltinGroup then return false end
            if a == "" then return false end
            if b == "" then return true end
            return a < b
        end)
        for _, row in ipairs(listRows) do row:Hide() end
        for _, row in ipairs(headerRows) do row:Hide() end
        local rowIndex, headerIndex, offset = 0, 0, 0
        for _, group in ipairs(groupOrder) do
            if group ~= "" then
                headerIndex = headerIndex + 1
                local header = headerRows[headerIndex]
                if not header then
                    header = CreateFrame("Button", nil, listChild, "BackdropTemplate")
                    header:SetSize(listChild:GetWidth(), 22)
                    DF:ApplyStandardBackdrop(header)
                    header.__background:SetVertexColor(0.05, 0.30, 0.40)
                    header.__background:SetAlpha(0.90)
                    header.arrow = header:CreateTexture(nil, "OVERLAY")
                    header.arrow:SetSize(12, 12)
                    header.arrow:SetPoint("LEFT", header, "LEFT", 4, 0)
                    header.arrow:SetVertexColor(0.4, 0.85, 1, 1)
                    header.label = header:CreateFontString(nil, "OVERLAY")
                    NSI:SetUIFont(header.label, 12, "OUTLINE")
                    header.label:SetTextColor(0.2, 0.85, 1, 1)
                    header.label:SetPoint("LEFT", header, "LEFT", 20, 0)
                    header.count = header:CreateFontString(nil, "OVERLAY")
                    NSI:SetUIFont(header.count, 12, "")
                    header.count:SetPoint("RIGHT", header, "RIGHT", -4, 0)
                    headerRows[headerIndex] = header
                end
                local collapsed = NSI:GetAuraGlowGroupCollapsed(group)
                header:ClearAllPoints(); header:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -offset); header.label:SetText(group); header.count:SetText("(" .. #grouped[group] .. ")"); header.arrow:SetTexture(collapsed and ChevronDown or ChevronUp); header:Show(); offset = offset + 22
                local groupName = group
                header:SetScript("OnMouseDown", function(_, button)
                    if button == "RightButton" and groupName ~= NSI.AuraGlowBuiltinGroup then
                        ShowContextMenu({ { type = "button", label = NSI:Loc("Export Group"), fnc = function() ShowAuraGlowExportPopup(NSI:ExportAuraGlowGroup(groupName)) end } })
                    elseif button ~= "RightButton" then
                        NSI:SetAuraGlowGroupCollapsed(groupName, not NSI:GetAuraGlowGroupCollapsed(groupName))
                        RebuildList()
                    end
                end)
            end
            if not NSI:GetAuraGlowGroupCollapsed(group) then for _, entry in ipairs(grouped[group]) do
                rowIndex = rowIndex + 1
                local row = listRows[rowIndex]
            if not row then
                row = CreateFrame("Button", nil, listChild, "BackdropTemplate")
                row:SetSize(listChild:GetWidth(), 22)
                DF:ApplyStandardBackdrop(row)
                row.__background:SetVertexColor(0.4, 0.4, 0.4)
                row.__background:SetAlpha(0.5)
                row.check = CreateCheckButton(row, "", nil, nil, 14, 14)
                row.check:SetPoint("LEFT", row, "LEFT", 3, 0)
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(16, 16)
                row.icon:SetPoint("LEFT", row.check.frame, "RIGHT", 5, 0)
                row.label = row:CreateFontString(nil, "OVERLAY")
                NSI:SetUIFont(row.label, 12, "")
                row.label:SetPoint("LEFT", row.check.frame, "RIGHT", 5, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -24, 0)
                row.label:SetJustifyH("LEFT")
                row.lock = row:CreateTexture(nil, "OVERLAY")
                row.lock:SetSize(14, 14)
                row.lock:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.lock:SetTexture([[Interface\PetBattles\PetBattle-LockIcon]])
                row.trash = CreateFrame("Button", nil, row)
                row.trash:SetSize(14, 14)
                row.trash:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.trash:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
                row.trash:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
                row.trash:GetNormalTexture():SetDesaturated(true)
                row.trash:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
                listRows[rowIndex] = row
            end
            row:ClearAllPoints()
            local indent = group ~= "" and 14 or 0
            row:SetPoint("TOPLEFT", listChild, "TOPLEFT", indent, -offset)
            row:SetWidth(listChild:GetWidth() - indent)
            row.entry = entry
            row.label:SetText(entry.settings.Name)
            local spellIDs = entry.settings.AuraType == "Buffs" and entry.settings.BuffFiltering == "SpellIDs"
                and NSI:GetAuraGlowSpellIDList(entry.key) or nil
            if spellIDs and spellIDs[1] then
                local spell = C_Spell.GetSpellInfo(spellIDs[1])
                row.icon:SetTexture(spell and spell.iconID or DefaultIcon)
                row.icon:Show()
                row.label:ClearAllPoints()
                row.label:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -24, 0)
            else
                row.icon:Hide()
                row.label:ClearAllPoints()
                row.label:SetPoint("LEFT", row.check.frame, "RIGHT", 5, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -24, 0)
            end
            local willLoad = NSI:EvaluateLoad(entry.settings, true)
            row.check:SetValue(entry.settings.enabled)
            row.check.frame:SetAlpha(willLoad and 1 or 0.4)
            row.lock:SetShown(entry.builtin)
            row.trash:SetShown(not entry.builtin)
            row.label:SetTextColor(1, 1, 1, willLoad and (entry.settings.enabled and 1 or 0.45) or 0.35)
            row.lock:SetAlpha(willLoad and 1 or 0.35)
            row.trash:SetAlpha(willLoad and 1 or 0.35)
            row.__background:SetVertexColor(selectedKey == entry.key and 0 or 0.4, selectedKey == entry.key and 1 or 0.4, selectedKey == entry.key and 1 or 0.4)
            row.__background:SetAlpha(selectedKey == entry.key and 1 or willLoad and 0.5 or 0.2)
            row:SetScript("OnMouseDown", function(_, button)
                if row.check.frame:IsMouseOver() or row.trash:IsMouseOver() then return end
                if button == "RightButton" then EntryContextMenu(row.entry) else SelectEntry(row.entry.key) end
            end)
            row.check:SetOnChange(function(_, enabled)
                row.entry.settings.enabled = enabled
                if row.entry.builtin then
                    row.entry.settings.enabledEdited = true
                end
                ApplySettings()
            end)
            row.trash:SetScript("OnClick", function() ConfirmDelete(row.entry.key, row.entry.settings.Name) end)
            row:Show()
            offset = offset + 22
            end
            end
        end
        listChild:SetHeight(math.max(1, offset))
    end

    local function BuildDisplayDefs(settings)
        local defs = {
            { Type = "Label", text = "Glow Appearance", highlight = true },
            { Type = "Slider", label = "Glow Size", min = 1, max = 20, step = 1,
                get = function() return settings.Size end,
                set = function(_, value) settings.Size = value; ApplySettings() end },
            { Type = "Slider", label = "Number of Lines", min = 1, max = 20, step = 1,
                get = function() return settings.NumberOfLines end,
                set = function(_, value) settings.NumberOfLines = value; ApplySettings() end },
            { Type = "Slider", label = "Line Size", min = 0, max = 100, step = 1,
                get = function() return settings.LineSize end,
                set = function(_, value) settings.LineSize = value; ApplySettings() end },
            { Type = "Label", text = "Set Line Size to 0 to use the automatic size." },
            { Type = "Slider", label = "Frequency", min = 0.05, max = 1, step = 0.05,
                get = function() return settings.Frequency end,
                set = function(_, value) settings.Frequency = value; ApplySettings() end },
            { Type = "Checkbox", label = "Show Background",
                get = function() return settings.ShowBackground end,
                set = function(_, value) settings.ShowBackground = value; ApplySettings() end },
            { Type = "Color", label = "Glow Color",
                get = function() return unpack(settings.Color) end,
                set = function(_, red, green, blue, alpha)
                    settings.Color = { red, green, blue, alpha or 1 }
                    ApplySettings()
                end },
            { Type = "Checkbox", label = "Show Icon",
                get = function() return settings.ShowIcon end,
                set = function(_, value) settings.ShowIcon = value; ApplySettings(); RebuildTab() end },
        }
        if settings.ShowIcon then
            defs[#defs + 1] = { Type = "Slider", label = "Icon Size", min = 1, max = 100, step = 1,
                get = function() return settings.IconSize or 20 end,
                set = function(_, value) settings.IconSize = value; ApplySettings() end }
        end
        return defs
    end

    local function BuildAuraGlowSpellIDListWidget(key)
        return { Type = "Custom", build = function(parent, width, widgetName)
            local frame = CreateFrame("Frame", widgetName, parent)
            frame:SetWidth(width)

            local input = CreateTextEntry(frame, nil, nil, nil, width - 70, 22, nil, nil, nil, widgetName and (widgetName .. "Input") or nil)
            input:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

            local function AddFromInput()
                local value = strtrim(input.editBox:GetText() or "")
                if value == "" then return end
                NSI:AddAuraGlowSpellIDs(key, value)
                input.editBox:SetText("")
                RebuildList()
                RebuildTab()
            end
            input.editBox:SetScript("OnEnterPressed", function(self) AddFromInput(); self:ClearFocus() end)

            local addButton = CreateLocalizedSubButton(frame, "Add", AddFromInput, 54, widgetName and (widgetName .. "Add") or nil)
            addButton:SetPoint("LEFT", input.frame, "RIGHT", 6, 0)

            local spellIDs = NSI:GetAuraGlowSpellIDList(key)
            local y = 30
            for _, spellID in ipairs(spellIDs) do
                local row = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                row:SetSize(width, 20)
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -y)
                row:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
                row:SetBackdropColor(0.04, 0.04, 0.04, 0.6)

                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(16, 16)
                icon:SetPoint("LEFT", row, "LEFT", 3, 0)
                icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)

                local label = row:CreateFontString(nil, "OVERLAY")
                NSI:SetUIFont(label, 12, "")
                label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                label:SetPoint("RIGHT", row, "RIGHT", -24, 0)
                label:SetJustifyH("LEFT")
                label:SetWordWrap(false)

                local spell = C_Spell.GetSpellInfo(spellID)
                if spell then
                    icon:SetTexture(spell.iconID or DefaultIcon)
                    label:SetText(spell.name .. "  |cFF808080(" .. spellID .. ")|r")
                else
                    icon:SetTexture(DefaultIcon)
                    label:SetText(NSI:Loc("|cFFFF4040Unknown spell|r") .. "  |cFF808080(" .. spellID .. ")|r")
                end

                local removeButton = CreateFrame("Button", nil, row)
                removeButton:SetSize(14, 14)
                removeButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                removeButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                removeButton:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
                removeButton:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
                removeButton:SetScript("OnClick", function()
                    NSI:RemoveAuraGlowSpellID(key, spellID)
                    RebuildList()
                    RebuildTab()
                end)

                y = y + 20
            end

            if #spellIDs == 0 then
                local empty = frame:CreateFontString(nil, "OVERLAY")
                NSI:SetUIFont(empty, 12, "")
                empty:SetTextColor(0.5, 0.5, 0.5, 1)
                empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -y - 2)
                empty:SetText(NSI:Loc("No spell IDs added yet."))
                y = y + 20
            end

            frame:SetHeight(y)
            return frame, y
        end }
    end

    local function BuildTriggerDefs(settings, builtin, key)
        if builtin then
            return { { Type = "Label", text = "This built-in glow uses a fixed aura filter and cannot be edited.", height = 36 } }
        end
        settings.AuraType = settings.AuraType or "Debuffs"
        settings.BuffFiltering = settings.BuffFiltering or "SpellIDs"
        settings.AuraFilters = settings.AuraFilters or {}
        local defs = {
            { Type = "Dropdown", label = "Aura Type", values = AuraTypes,
                get = function() return settings.AuraType end,
                set = function(_, value) settings.AuraType = value or "Debuffs"; ApplySettings(); RebuildTab() end },
        }
        if settings.AuraType == "Buffs" then
            defs[#defs + 1] = { Type = "Dropdown", label = "Buff Filtering", values = BuffFilteringModes,
                get = function() return settings.BuffFiltering end,
                set = function(_, value) settings.BuffFiltering = value or "SpellIDs"; ApplySettings(); RebuildTab() end }
            if settings.BuffFiltering == "SpellIDs" then
                defs[#defs + 1] = { Type = "Label", text = "Spell IDs", highlight = true }
                defs[#defs + 1] = BuildAuraGlowSpellIDListWidget(key)
                defs[#defs + 1] = { Type = "Label", text = "Blizzard only allows spell-ID filtering for buffs on friendly units and debuffs on enemy units." }
                return defs
            end
        end
        settings.CandidateFilters = settings.CandidateFilters or {}
        defs[#defs + 1] = { Type = "Label", text = "Aura Filters", highlight = true }
        defs[#defs + 1] = { Type = "Label", text = settings.AuraType == "Buffs"
            and "All raid units are always tracked. These filters decide which helpful auras trigger the glow."
            or "All raid units are always tracked. These filters decide which harmful auras trigger the glow.", height = 36 }
        for _, filter in ipairs(NSI.AuraTrackingFilterDefinitions or {}) do
            if filter.key ~= "Helpful" and filter.key ~= "Harmful" then
                local filterKey = filter.key
                defs[#defs + 1] = { Type = "Dropdown", label = filterKey, values = FilterStates,
                    get = function() return settings.AuraFilters[filterKey] or "Disabled" end,
                    set = function(_, value)
                        if value == "Enabled" or value == "Inverted" then
                            settings.AuraFilters[filterKey] = value
                        else
                            settings.AuraFilters[filterKey] = nil
                        end
                        ApplySettings()
                    end }
            end
        end
        defs[#defs + 1] = { Type = "Label", text = "Candidate Filters", highlight = true }
        defs[#defs + 1] = { Type = "Checkbox", label = "Maximum Duration",
            get = function() return type(settings.CandidateFilters.MaxDuration) == "number" end,
            set = function(_, value)
                settings.CandidateFilters.MaxDuration = value and (settings.CandidateFilters.MaxDuration or 300) or nil
                ApplySettings()
                RebuildTab()
            end }
        if type(settings.CandidateFilters.MaxDuration) == "number" then
            defs[#defs + 1] = { Type = "Slider", label = "Maximum Duration Seconds", min = 1, max = 3600, step = 1,
                get = function() return settings.CandidateFilters.MaxDuration end,
                set = function(_, value) settings.CandidateFilters.MaxDuration = value; ApplySettings() end }
        end
        defs[#defs + 1] = { Type = "Dropdown", label = "Processed Aura Type", values = ProcessedAuraTypes,
            get = function() return settings.CandidateFilters.ProcessedAuraType or "Disabled" end,
            set = function(_, value) settings.CandidateFilters.ProcessedAuraType = value; ApplySettings() end }
        defs[#defs + 1] = { Type = "Label", text = "Dispel Types", highlight = true }
        settings.CandidateFilters.DispelTypes = settings.CandidateFilters.DispelTypes or {}
        for _, dispelType in ipairs(NSI.AuraTrackingCandidateDispelTypes or {}) do
            local typeName = dispelType
            defs[#defs + 1] = { Type = "Dropdown", label = typeName, values = FilterStates,
                get = function() return settings.CandidateFilters.DispelTypes[typeName] or "Disabled" end,
                set = function(_, value)
                    if value == "Enabled" or value == "Inverted" then
                        settings.CandidateFilters.DispelTypes[typeName] = value
                    else
                        settings.CandidateFilters.DispelTypes[typeName] = nil
                    end
                    ApplySettings()
                end }
        end
        defs[#defs + 1] = { Type = "Label", text = "Aura Properties", highlight = true }
        for _, filter in ipairs(NSI.AuraTrackingCandidateFilterDefinitions or {}) do
            local filterKey = filter.key
            defs[#defs + 1] = { Type = "Dropdown", label = filter.label, values = FilterStates,
                get = function()
                    local value = settings.CandidateFilters[filterKey]
                    if value == true or value == "Enabled" then return "Enabled" end
                    if value == false or value == "Inverted" then return "Inverted" end
                    return "Disabled"
                end,
                set = function(_, value)
                    settings.CandidateFilters[filterKey] = value == "Enabled" and true or value == "Inverted" and false or nil
                    ApplySettings()
                end }
        end
        return defs
    end

    local loadF = tabFrames["Load"]
    local namesSectionHeight = 180
    local namesListHeight = 112
    local loadScrollHeight = tabContentH - namesSectionHeight - 4
    local loadScroll = CreateFrame("ScrollFrame", "NSUIAuraGlowLoadScroll", loadF, "UIPanelScrollFrameTemplate")
    loadScroll:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, 0)
    loadScroll:SetSize(tabScrollW, loadScrollHeight)
    loadScroll:EnableMouseWheel(true)
    loadScroll:SetScript("OnMouseWheel", function(_, delta)
        local bar = _G["NSUIAuraGlowLoadScrollScrollBar"]
        if bar then local cur = bar:GetValue(); local mn, mx = bar:GetMinMaxValues(); bar:SetValue(math.max(mn, math.min(mx, cur - delta * 24))) end
    end)
    ReskinScrollbar(loadScroll)
    local loadChild = CreateFrame("Frame", nil, loadScroll, "BackdropTemplate")
    loadChild:SetSize(tabScrollW - 18, 1)
    loadChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    loadChild:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
    loadScroll:SetScrollChild(loadChild)

    local loadCollapsed = { Roles = true, Classes = true, Specs = true, Encounters = true }
    local loadRowWidth = tabScrollW - 22
    local headerPool, checkPool = {}, {}

    local function MakeLoadHeader()
        local button = CreateFrame("Button", nil, loadChild, "BackdropTemplate")
        button:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
        button:SetBackdropColor(0.05, 0.30, 0.40, 0.9)
        button:SetSize(loadRowWidth, 18)
        button.arrow = button:CreateTexture(nil, "OVERLAY")
        button.arrow:SetSize(10, 10)
        button.arrow:SetPoint("LEFT", button, "LEFT", 2, 0)
        button.arrow:SetVertexColor(0.6, 0.6, 0.6, 1)
        button.text = button:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(button.text, 11, "")
        button.text:SetTextColor(0.55, 0.55, 0.55, 1)
        button.text:SetPoint("LEFT", button, "LEFT", 16, 0)
        button:SetScript("OnEnter", function() button.text:SetTextColor(0.85, 0.85, 0.85, 1) end)
        button:SetScript("OnLeave", function() button.text:SetTextColor(0.55, 0.55, 0.55, 1) end)
        button:Hide()
        return button
    end

    local function MakeCheckRow()
        local row = CreateFrame("Button", nil, loadChild)
        row:SetSize(loadRowWidth, 20)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        local hoverBackground = CreateFrame("Frame", nil, row)
        hoverBackground:SetAllPoints(row)
        hoverBackground:EnableMouse(false)
        local hoverTexture = hoverBackground:CreateTexture(nil, "BACKGROUND")
        hoverTexture:SetAllPoints()
        hoverTexture:SetColorTexture(0, 1, 1, 0.13)
        hoverBackground:SetAlpha(0)
        row.hoverBackground = hoverBackground
        row.box = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.box:SetSize(12, 12)
        row.box:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.box:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
        row.box:SetBackdropColor(0.10, 0.10, 0.10, 0.9)
        row.box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        row.fill = row.box:CreateTexture(nil, "ARTWORK")
        row.fill:SetPoint("TOPLEFT", row.box, "TOPLEFT", 2, -2)
        row.fill:SetPoint("BOTTOMRIGHT", row.box, "BOTTOMRIGHT", -2, 2)
        row.fill:SetColorTexture(0, 1, 1, 0.85)
        row.fill:Hide()
        local labelFrame = CreateFrame("Frame", nil, row)
        row.labelFrame = labelFrame
        labelFrame:EnableMouse(false)
        labelFrame:SetPoint("LEFT", row, "LEFT", 22, 0)
        labelFrame:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        labelFrame:SetHeight(20)
        row.label = labelFrame:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.label, 12, "")
        row.label:SetAllPoints(labelFrame)
        row.label:SetJustifyH("LEFT")
        row.label:SetJustifyV("MIDDLE")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", row, "LEFT", 22, 0)
        row.icon:Hide()
        row:SetScript("OnEnter", function()
            UIFrameFadeIn(hoverBackground, 0.12, hoverBackground:GetAlpha(), 1)
        end)
        row:SetScript("OnLeave", function()
            UIFrameFadeOut(hoverBackground, 0.20, hoverBackground:GetAlpha(), 0)
        end)
        row:Hide()
        return row
    end

    local function LoadSection(y, sectionKey, label, count)
        local index = #headerPool + 1
        for i, header in ipairs(headerPool) do if not header:IsShown() then index = i; break end end
        headerPool[index] = headerPool[index] or MakeLoadHeader()
        local header = headerPool[index]
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", loadChild, "TOPLEFT", 0, -y)
        header:SetWidth(loadRowWidth)
        header.arrow:SetTexture(loadCollapsed[sectionKey] and ChevronDown or ChevronUp)
        header.text:SetText(label)
        header:SetScript("OnClick", function() loadCollapsed[sectionKey] = not loadCollapsed[sectionKey]; RebuildLoadTab() end)
        header:Show()
        return y + 20
    end

    local namesLabel = loadF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(namesLabel, 11, "")
    namesLabel:SetTextColor(0.55, 0.55, 0.55, 1)
    namesLabel:SetText(NSI:Loc("Character Names (no server name)"))
    namesLabel:SetPoint("BOTTOMLEFT", loadF, "BOTTOMLEFT", 0, namesSectionHeight - 14)

    local nameInput = CreateTextEntry(loadF, nil, nil, nil, loadRowWidth - 70, 20, nil, nil, nil, "NSUIAuraGlowNameInput")
    nameInput:SetPoint("BOTTOMLEFT", loadF, "BOTTOMLEFT", 0, namesSectionHeight - 40)

    local AddLoadName
    local nameAddButton = CreateLocalizedSubButton(loadF, "Add", function()
        if AddLoadName then
            AddLoadName()
        end
    end, 54, "NSUIAuraGlowNameAdd")
    nameAddButton:SetPoint("LEFT", nameInput.frame, "RIGHT", 6, 0)

    local namesScroll = CreateFrame("ScrollFrame", "NSUIAuraGlowNamesScroll", loadF, "UIPanelScrollFrameTemplate")
    namesScroll:SetPoint("BOTTOMLEFT", loadF, "BOTTOMLEFT", 0, 0)
    namesScroll:SetSize(loadRowWidth, namesListHeight)
    namesScroll:EnableMouseWheel(true)
    namesScroll:SetScript("OnMouseWheel", function(_, delta)
        local bar = _G["NSUIAuraGlowNamesScrollScrollBar"]
        if bar then
            local cur = bar:GetValue()
            local mn, mx = bar:GetMinMaxValues()
            bar:SetValue(math.max(mn, math.min(mx, cur - delta * 24)))
        end
    end)
    ReskinScrollbar(namesScroll)

    local namesChild = CreateFrame("Frame", nil, namesScroll, "BackdropTemplate")
    namesChild:SetSize(loadRowWidth - 18, 1)
    namesChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    namesChild:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
    namesScroll:SetScrollChild(namesChild)

    local nameRowPool = {}
    local function MakeNameRow()
        local row = CreateFrame("Frame", nil, namesChild)
        row:SetSize(loadRowWidth - 18, 20)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.label = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.label, 12, "")
        row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.label:SetPoint("RIGHT", row, "RIGHT", -24, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetTextColor(1, 1, 1, 1)
        row.removeButton = CreateFrame("Button", nil, row)
        row.removeButton:SetSize(14, 14)
        row.removeButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.removeButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
        row.removeButton:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]])
        row.removeButton:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
        row:Hide()
        return row
    end

    local function RebuildNameRows()
        for _, row in ipairs(nameRowPool) do
            row:Hide()
        end

        local settings = GetSelectedSettings()
        if not settings then
            namesChild:SetHeight(1)
            return
        end

        settings.loadConditions = settings.loadConditions or {}
        settings.loadConditions.Names = settings.loadConditions.Names or {}

        local sortedNames = {}
        for name in pairs(settings.loadConditions.Names) do
            sortedNames[#sortedNames + 1] = name
        end
        table.sort(sortedNames)

        for i, name in ipairs(sortedNames) do
            nameRowPool[i] = nameRowPool[i] or MakeNameRow()
            local row = nameRowPool[i]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", namesChild, "TOPLEFT", 0, -((i - 1) * 20))
            row:SetWidth(loadRowWidth - 18)
            row.bg:SetColorTexture(i % 2 == 0 and 0.12 or 0, i % 2 == 0 and 0.12 or 0, i % 2 == 0 and 0.12 or 0, i % 2 == 0 and 0.5 or 0)
            row.label:SetText(name)
            local rowName = name
            row.removeButton:SetScript("OnClick", function()
                local currentSettings = GetSelectedSettings()
                if currentSettings and currentSettings.loadConditions and currentSettings.loadConditions.Names then
                    currentSettings.loadConditions.Names[rowName] = nil
                    NSI:InitAuraGlows()
                    RebuildList()
                    RebuildNameRows()
                end
            end)
            row:Show()
        end

        local height = math.max(#sortedNames * 20, 1)
        namesChild:SetHeight(height)
        local bar = _G["NSUIAuraGlowNamesScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, height - namesScroll:GetHeight())
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then
                bar:SetValue(0)
            end
        end
    end

    AddLoadName = function()
        local name = strtrim(nameInput.editBox:GetText() or "")
        if name == "" or not selectedKey then
            return
        end

        local settings = GetSelectedSettings()
        if not settings then
            return
        end

        settings.loadConditions = settings.loadConditions or {}
        settings.loadConditions.Names = settings.loadConditions.Names or {}
        settings.loadConditions.Names[name] = true
        nameInput.editBox:SetText("")
        NSI:InitAuraGlows()
        RebuildList()
        RebuildNameRows()
    end

    nameInput.editBox:SetScript("OnEnterPressed", function(self)
        AddLoadName()
        self:ClearFocus()
    end)

    RebuildLoadTab = function()
        for _, header in ipairs(headerPool) do header:Hide() end
        for _, row in ipairs(checkPool) do row:Hide() end
        local settings = GetSelectedSettings()
        if not settings then
            RebuildNameRows()
            return
        end
        settings.loadConditions = settings.loadConditions or {}
        local conditions = settings.loadConditions
        conditions.Roles = conditions.Roles or {}; conditions.Classes = conditions.Classes or {}; conditions.SpecIDs = conditions.SpecIDs or {}; conditions.Names = conditions.Names or {}; conditions.EncounterIDs = conditions.EncounterIDs or {}

        local checkIndex = 0
        local function CountSelected(values) local count = 0; for _ in pairs(values) do count = count + 1 end; return count end
        local function AddCheck(y, label, checked, onToggle, red, green, blue, icon, texcoord)
            checkIndex = checkIndex + 1
            checkPool[checkIndex] = checkPool[checkIndex] or MakeCheckRow()
            local row = checkPool[checkIndex]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", loadChild, "TOPLEFT", 0, -y)
            row:SetWidth(loadRowWidth)
            row.label:SetText(label)
            row.label:SetTextColor(red or 1, green or 1, blue or 1, 1)
            row.labelFrame:ClearAllPoints()
            row.labelFrame:SetPoint("LEFT", row, "LEFT", icon and 42 or 22, 0)
            row.labelFrame:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            if icon then
                row.icon:SetTexture(icon)
                if texcoord then row.icon:SetTexCoord(unpack(texcoord)) else row.icon:SetTexCoord(0, 1, 0, 1) end
                row.icon:Show()
            else
                row.icon:Hide()
            end
            if checked then
                row.fill:Show(); row.box:SetBackdropBorderColor(0, 1, 1, 0.9)
                row.bg:SetColorTexture((red or 0) * 0.3, (green or 0) * 0.3, (blue or 0) * 0.3, 0.85)
            else
                row.fill:Hide(); row.box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
                row.bg:SetColorTexture(
                    checkIndex % 2 == 0 and 0.12 or 0,
                    checkIndex % 2 == 0 and 0.12 or 0,
                    checkIndex % 2 == 0 and 0.12 or 0,
                    checkIndex % 2 == 0 and 0.5 or 0)
            end
            row:SetScript("OnClick", function() onToggle(); NSI:InitAuraGlows(); RebuildList(); RebuildLoadTab() end)
            row:Show()
            return y + 20
        end

        local y = 0
        if not NSI.AuraGlowBuiltins[selectedKey] then
            local encounterData = BossData.BuildBossDropdownOptions(nil, false)
            y = LoadSection(y, "Encounters", NSI:Loc("Encounters (leave all unchecked for any encounter)"), CountSelected(conditions.EncounterIDs))
            if not loadCollapsed.Encounters then
                for _, encounter in ipairs(encounterData) do
                    local encounterID = encounter.value
                    y = AddCheck(y, encounter.label, conditions.EncounterIDs[encounterID],
                        function() conditions.EncounterIDs[encounterID] = (not conditions.EncounterIDs[encounterID]) or nil end,
                        0.2, 0.8, 1, encounter.icon, encounter.texcoord)
                end
            end
            y = y + 4
        end
        y = LoadSection(y, "Roles", NSI:Loc("Roles (leave all unchecked for any role)"), CountSelected(conditions.Roles))
        if not loadCollapsed.Roles then
            for _, role in ipairs(RoleData) do
                local key = role.key; local color = RoleColors[key]
                y = AddCheck(y, NSI:Loc(role.label), conditions.Roles[key], function() conditions.Roles[key] = (not conditions.Roles[key]) or nil end, color[1], color[2], color[3])
            end
        end
        y = y + 4
        y = LoadSection(y, "Classes", NSI:Loc("Classes (leave all unchecked for any class)"), CountSelected(conditions.Classes))
        if not loadCollapsed.Classes then
            for _, class in ipairs(ClassData) do
                local key = class.key; local red, green, blue = ClassColor(key)
                y = AddCheck(y, NSI:Loc(class.label), conditions.Classes[key], function() conditions.Classes[key] = (not conditions.Classes[key]) or nil end, red, green, blue)
            end
        end
        y = y + 4
        y = LoadSection(y, "Specs", NSI:Loc("Specializations (leave all unchecked for any spec)"), CountSelected(conditions.SpecIDs))
        if not loadCollapsed.Specs then
            for _, spec in ipairs(SpecData) do
                local id = spec.id; local red, green, blue = ClassColor(spec.class)
                y = AddCheck(y, NSI:Loc(spec.label), conditions.SpecIDs[id],
                    function() conditions.SpecIDs[id] = (not conditions.SpecIDs[id]) or nil end, red * 0.8 + 0.2, green * 0.8 + 0.2, blue * 0.8 + 0.2)
            end
        end

        loadChild:SetHeight(math.max(y, 1))
        local bar = _G["NSUIAuraGlowLoadScrollScrollBar"]
        if bar then local maxScroll = math.max(0, y - loadScroll:GetHeight()); bar:SetMinMaxValues(0, maxScroll); if bar:GetValue() > maxScroll then bar:SetValue(0) end end
        RebuildNameRows()
    end

    RebuildTab = function()
        local settings = GetSelectedSettings()
        rightPanel:SetShown(settings ~= nil)
        if not settings then return end
        local builtin = NSI.AuraGlowBuiltins[selectedKey] ~= nil
        nameEntry:SetValue(settings.Name)
        nameEntry.editBox:SetEnabled(not builtin)
        deleteButton.frame:SetShown(not builtin)
        nameEntry.editBox:SetScript("OnEnterPressed", function(editBox)
            if not builtin then
                local value = editBox:GetText()
                if value ~= "" then settings.Name = value; RebuildList() end
            end
            editBox:ClearFocus()
        end)
        for name, frame in pairs(tabFrames) do
            frame:SetShown(name == activeTab)
            if name == activeTab then tabButtons[name]:Select() else tabButtons[name]:Deselect() end
        end
        if activeTab == "Load" then
            RebuildLoadTab()
            return
        end
        local defs = activeTab == "Display" and BuildDisplayDefs(settings) or BuildTriggerDefs(settings, builtin, selectedKey)
        local scroll = tabScroll[activeTab]
        if not scroll then
            scroll = CreateScrollBox(tabFrames[activeTab], rightWidth - 16, tabFrames[activeTab]:GetHeight())
            scroll:SetPoint("TOPLEFT", tabFrames[activeTab], "TOPLEFT", 0, 0)
            tabScroll[activeTab] = scroll
        end
        scroll.scrollChild:Hide()
        local child = CreateFrame("Frame", nil, scroll.frame)
        child:SetWidth(rightWidth - 34)
        child:SetHeight(1)
        scroll.frame:SetScrollChild(child)
        scroll.scrollChild = child
        local height = BuildWidgets(child, defs, child:GetWidth(), "NSUIAuraGlow" .. activeTab)
        child:SetHeight(math.max(1, height))
        scroll.frame:Show()
        scroll:UpdateScrollBar()
    end

    SelectEntry = function(key)
        selectedKey = key
        NSRT.AuraGlows.UI.Selected = key
        RebuildList()
        RebuildTab()
    end

    NSI._RefreshAuraGlowsUI = function()
        RebuildList()
        RebuildTab()
    end
    RebuildList()
    if selectedKey and NSI:GetAuraGlowSettings(selectedKey) then RebuildTab() else rightPanel:Hide() end
    return screen
end

NSI.UI.Options.AuraGlows = { BuildUI = BuildAuraGlowsUI }
