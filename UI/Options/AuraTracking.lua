local addonId, NSI = ...
local DF = _G["DetailsFramework"]

local Core                     = NSI.UI.Core
local NSUI                     = Core.NSUI
local content_width            = Core.content_width
local tab_content_height       = Core.tab_content_height

local CreateLocalizedSubButton = NSI.UI.Components.CreateLocalizedSubButton
local CreateLocalizedButton    = NSI.UI.Components.CreateLocalizedButton
local CreateButton             = NSI.UI.Components.CreateButton
local CreateDropdown           = NSI.UI.Components.CreateDropdown
local CreateTextEntry          = NSI.UI.Components.CreateTextEntry
local CreateCheckButton        = NSI.UI.Components.CreateCheckButton
local CreateScrollBox          = NSI.UI.Components.CreateScrollBox
local BuildWidgets             = NSI.UI.Components.BuildWidgets
local ReskinScrollbar          = NSI.UI.Components.ReskinScrollbar
local ShowContextMenu          = NSI.UI.Components.ShowContextMenu

-- ============================================================================
-- Static option data
-- ============================================================================
local FONT_FLAGS = {
    { label = "None", value = "" },
    { label = "OUTLINE", value = "OUTLINE" },
    { label = "THICKOUTLINE", value = "THICKOUTLINE" },
    { label = "MONOCHROME", value = "MONOCHROME" },
    { label = "OUTLINE, MONOCHROME", value = "OUTLINE, MONOCHROME" },
    { label = "THICKOUTLINE, MONOCHROME", value = "THICKOUTLINE, MONOCHROME" },
}

local GROW_DIRECTIONS = {
    { label = "LEFT", value = "LEFT" }, { label = "RIGHT", value = "RIGHT" },
    { label = "UP", value = "UP" }, { label = "DOWN", value = "DOWN" },
}

local NAME_POSITIONS = {
    { label = "TOP", value = "TOP" }, { label = "BOTTOM", value = "BOTTOM" },
    { label = "LEFT", value = "LEFT" }, { label = "RIGHT", value = "RIGHT" },
}

local ANCHOR_POINTS = {
    { label = "TOPLEFT", value = "TOPLEFT" }, { label = "TOP", value = "TOP" }, { label = "TOPRIGHT", value = "TOPRIGHT" },
    { label = "LEFT", value = "LEFT" }, { label = "CENTER", value = "CENTER" }, { label = "RIGHT", value = "RIGHT" },
    { label = "BOTTOMLEFT", value = "BOTTOMLEFT" }, { label = "BOTTOM", value = "BOTTOM" }, { label = "BOTTOMRIGHT", value = "BOTTOMRIGHT" },
}

local ROLE_DATA = {
    { key = "TANK", label = "Tank" }, { key = "HEALER", label = "Healer" },
    { key = "DAMAGER", label = "DPS" }, { key = "MELEE", label = "Melee" }, { key = "RANGED", label = "Ranged" },
}
local ROLE_COLORS = {
    TANK = { 0.3, 0.5, 1.0 }, HEALER = { 0.3, 0.9, 0.3 }, DAMAGER = { 0.9, 0.2, 0.2 },
    MELEE = { 0.95, 0.55, 0.2 }, RANGED = { 0.9, 0.8, 0.2 },
}

local CLASS_DATA = {
    { key = "WARRIOR", label = "Warrior" }, { key = "PALADIN", label = "Paladin" },
    { key = "HUNTER", label = "Hunter" }, { key = "ROGUE", label = "Rogue" },
    { key = "PRIEST", label = "Priest" }, { key = "DEATHKNIGHT", label = "Death Knight" },
    { key = "SHAMAN", label = "Shaman" }, { key = "MAGE", label = "Mage" },
    { key = "WARLOCK", label = "Warlock" }, { key = "MONK", label = "Monk" },
    { key = "DRUID", label = "Druid" }, { key = "DEMONHUNTER", label = "Demon Hunter" },
    { key = "EVOKER", label = "Evoker" },
}

local SPEC_DATA = {
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

local SECTIONS = { "Display", "Trigger", "Load" }
local DEFAULT_ICON = 136076
local CHEVRON_DOWN = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-down.png]]
local CHEVRON_UP   = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\chevron-up.png]]

local function BuildFontValues()
    local t = {}
    for _, name in ipairs(NSI.LSM:List("font")) do t[#t + 1] = { label = name, value = name } end
    return t
end

local function PreviewFlag(settingsKey)
    return "IsAuraTracking" .. tostring(settingsKey):gsub(":", "") .. "Preview"
end

local function EntryIcon(settingsKey, settings)
    if settingsKey == "Player" then return 237555 end
    if settingsKey == "Tank" then return 236318 end
    if settingsKey == "External" then return C_Spell.GetSpellTexture(6940) or 135966 end
    if settings.PreviewSpellID then return C_Spell.GetSpellTexture(settings.PreviewSpellID) or DEFAULT_ICON end
    local first = settings.SpellIDs and settings.SpellIDs[1]
    if first then return C_Spell.GetSpellTexture(first) or DEFAULT_ICON end
    return DEFAULT_ICON
end

local function ClassColor(class)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.6, 0.6, 0.6
end

-- ============================================================================
-- BuildAuraTrackingUI
-- ============================================================================
local function BuildAuraTrackingUI(screen)
    local pad         = 10
    local topY        = -10
    local leftWidth   = 240
    local lineHeight  = 22
    local rightX      = leftWidth + pad * 2
    local rightW      = content_width - rightX - pad
    local tabContentH = tab_content_height - 20 - 68 - 6
    local DISPLAY_TOP = 46   -- fixed anchor row height at top of Display tab
    -- Scroll frames inside each inner tab are narrower than the panel so the
    -- native UIPanelScrollFrameTemplate scrollbar (anchored just outside the
    -- frame's right edge) stays inside the NSUI window instead of spilling past it.
    local tabScrollW  = rightW - 14

    local selectedKey = nil
    local searchText  = ""

    -- forward declarations
    local rightPanel, RebuildList, SelectEntry, RebuildCurrentTab
    local nameEntry, groupDD, enabledCB, anchorEntry
    local StartFramePicker

    -- ── Left: title / search ────────────────────────────────────────────────
    local title = screen:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(title, 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText(NSI:Loc("|cFF00FFFFAura|r Tracking"))

    local searchEntry = CreateTextEntry(screen, nil, nil, nil, leftWidth - pad * 2, 22, nil, nil, nil, "NSUIAuraTrackSearch")
    searchEntry:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 24)
    local searchHint = searchEntry.editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetText("|TInterface\\Common\\UI-Searchbox-Icon:16:16:0:-2|t  " .. NSI:Loc("Search..."))
    searchHint:SetPoint("LEFT", searchEntry.editBox, "LEFT", 2, 0)
    searchHint:SetTextColor(0.5, 0.5, 0.5, 0.6)
    NSI:SetUIFont(searchHint, 14, "")
    local function UpdateSearchHint(eb) searchHint:SetShown(eb:GetText() == "" and not eb:HasFocus()) end
    searchEntry.editBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText(); UpdateSearchHint(self); RebuildList()
    end)
    searchEntry.editBox:HookScript("OnEditFocusGained", function(self) UpdateSearchHint(self) end)
    searchEntry.editBox:HookScript("OnEditFocusLost",   function(self) UpdateSearchHint(self) end)

    -- ── Left: bottom buttons ────────────────────────────────────────────────
    local createBtn = CreateLocalizedButton(screen, "Create Aura", function()
        local key = NSI:AddCustomAuraTracking()
        RebuildList(); SelectEntry(key)
    end, leftWidth - pad * 2, 22, "NSUIAuraTrackCreate")
    createBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, pad + 24)

    local stopBtn = CreateLocalizedButton(screen, "Stop All Previews", function()
        NSI:StopAllAuraTrackingPreviews()
    end, leftWidth - pad * 2, 22, "NSUIAuraTrackStopPreview")
    stopBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, pad)

    -- ── Left: scroll list ───────────────────────────────────────────────────
    local scrollTop    = topY - 24 - 22 - 6
    local scrollHeight = tab_content_height + scrollTop - pad - 48 - 6
    local listW        = leftWidth - pad * 2

    local listScroll = CreateFrame("ScrollFrame", "NSUIAuraTrackListScroll", screen, "UIPanelScrollFrameTemplate")
    listScroll:SetSize(listW, scrollHeight)
    listScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, scrollTop)
    ReskinScrollbar(listScroll)

    local listChild = CreateFrame("Frame", nil, listScroll, "BackdropTemplate")
    listChild:SetSize(listW, 1)
    listChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    listChild:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
    listScroll:SetScrollChild(listChild)

    local entryRows, headerRows = {}, {}

    local function CreateEntryRow()
        local row = CreateFrame("Button", nil, listChild, "BackdropTemplate")
        row:SetSize(listChild:GetWidth(), lineHeight)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.4, 0.4, 0.4)
        row.__background:SetAlpha(0.5)

        local cb = CreateCheckButton(row, "", nil, nil, 14, 14)
        cb:SetPoint("LEFT", row, "LEFT", 3, 0)
        row.enabledCB = cb

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", cb.frame, "RIGHT", 4, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, 13, "")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)

        row.pinIcon = row:CreateTexture(nil, "OVERLAY")
        row.pinIcon:SetSize(12, 12)
        row.pinIcon:SetTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\pin.png]])
        row.pinIcon:SetVertexColor(189/255, 142/255, 69/255, 1)
        row.pinIcon:SetPoint("RIGHT", row, "RIGHT", -20, 0)
        row.pinIcon:Hide()

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
        row.deleteBtn:Hide()

        row:EnableMouse(true)
        row:Hide()
        return row
    end

    local function CreateHeaderRow()
        local row = CreateFrame("Button", nil, listChild, "BackdropTemplate")
        row:SetSize(listChild:GetWidth(), lineHeight)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.05, 0.30, 0.40)
        row.__background:SetAlpha(0.90)

        row.arrow = row:CreateTexture(nil, "OVERLAY")
        row.arrow:SetSize(12, 12)
        row.arrow:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.arrow:SetVertexColor(0.4, 0.85, 1, 1)

        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, 13, NSI:GetUIFontFlags())
        row.name:SetTextColor(0.2, 0.85, 1, 1)
        row.name:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)

        row.count = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.count, 12, NSI:GetUIFontFlags())
        row.count:SetTextColor(0.5, 0.5, 0.5, 1)
        row.count:SetPoint("RIGHT", row, "RIGHT", -4, 0)

        row:EnableMouse(true)
        row:Hide()
        return row
    end

    -- Build the ordered display model: pinned first, then Built-in group, then
    -- user groups, then ungrouped.
    local function BuildListModel()
        local all = NSI:IterateAuraTrackingEntries()
        local search = string.lower(searchText or "")
        local function passes(item)
            if search == "" then return true end
            return string.find(string.lower(item.settings.Name or ""), search, 1, true) ~= nil
        end

        local pinned, ungrouped = {}, {}
        local groups, groupOrder = {}, {}
        local function pushGroup(name)
            if not groups[name] then groups[name] = {}; groupOrder[#groupOrder + 1] = name end
            return groups[name]
        end

        for _, item in ipairs(all) do
            if passes(item) then
                if item.settings.pinned then
                    pinned[#pinned + 1] = item
                elseif item.group and item.group ~= "" then
                    table.insert(pushGroup(item.group), item)
                else
                    ungrouped[#ungrouped + 1] = item
                end
            end
        end

        table.sort(groupOrder, function(a, b)
            if a == NSI.AuraTrackingBuiltinGroup then return true end
            if b == NSI.AuraTrackingBuiltinGroup then return false end
            return a < b
        end)

        local model = {}
        for _, item in ipairs(pinned) do model[#model + 1] = { kind = "entry", item = item, indent = false } end
        for _, name in ipairs(groupOrder) do
            local isCollapsed = NSI:GetAuraTrackingGroupCollapsed(name)
            model[#model + 1] = { kind = "header", group = name, count = #groups[name], collapsed = isCollapsed }
            if not isCollapsed then
                for _, item in ipairs(groups[name]) do model[#model + 1] = { kind = "entry", item = item, indent = true } end
            end
        end
        for _, item in ipairs(ungrouped) do model[#model + 1] = { kind = "entry", item = item, indent = false } end
        return model
    end

    -- ── Context menus ────────────────────────────────────────────────────────
    local function PromptNewGroup(onCreate)
        StaticPopupDialogs["NSRT_AURATRACK_NEW_GROUP"] = {
            text = NSI:Loc("Enter new group name:"), button1 = NSI:Loc("OK"), button2 = NSI:Loc("Cancel"),
            hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
            OnAccept = function(self)
                local newName = self.EditBox:GetText()
                if newName and newName ~= "" then NSI:AddAuraTrackingGroup(newName); if onCreate then onCreate(newName) end end
            end,
            EditBoxOnEnterPressed = function(self)
                local parent = self:GetParent()
                StaticPopupDialogs["NSRT_AURATRACK_NEW_GROUP"].OnAccept(parent); parent:Hide()
            end,
        }
        StaticPopup_Show("NSRT_AURATRACK_NEW_GROUP")
    end

    local function GroupContextMenu(groupName)
        local items = {
            { type = "button", label = NSI:Loc("Enable All"), fnc = function() NSI:SetAuraTrackingGroupEnabled(groupName, true) end },
            { type = "button", label = NSI:Loc("Disable All"), fnc = function() NSI:SetAuraTrackingGroupEnabled(groupName, false) end },
        }
        if groupName ~= NSI.AuraTrackingBuiltinGroup then
            items[#items + 1] = { type = "separator" }
            items[#items + 1] = { type = "button", label = NSI:Loc("Delete Group (keep auras)"), fnc = function()
                NSI:DeleteAuraTrackingGroup(groupName, true)
            end }
            items[#items + 1] = { type = "button", label = NSI:Loc("Delete Group with Auras"), fnc = function()
                local dlg = NSI.UI.Components.CreateDialog("NSRTAuraTrackDeleteGroup" .. tostring(groupName):gsub("%W", "_"),
                    NSI:Loc("Delete Group with Auras"),
                    string.format(NSI:Loc("Delete group '%s' and all its auras?"), groupName),
                    NSI:Loc("Cancel"), nil, NSI:Loc("Delete"), function()
                        selectedKey = nil; rightPanel:Hide()
                        NSI:DeleteAuraTrackingGroup(groupName, false)
                    end)
                dlg:Show()
            end }
        end
        ShowContextMenu(items)
    end

    local function ConfirmDelete(settingsKey, name)
        local dlg = NSI.UI.Components.CreateDialog("NSRTAuraTrackDelete" .. tostring(settingsKey):gsub("%W", "_"),
            NSI:Loc("Delete Aura"), string.format(NSI:Loc("Delete '%s'?"), name or "?"),
            NSI:Loc("Cancel"), nil, NSI:Loc("Delete"), function()
                NSI:DeleteCustomAuraTracking(settingsKey)
                -- Custom entries are index-keyed; a delete reindexes later ones,
                -- so drop the selection to avoid editing a stale entry.
                selectedKey = nil; rightPanel:Hide(); RebuildList()
            end)
        dlg:Show()
    end

    local function EntryContextMenu(item)
        local sk = item.settingsKey
        local s  = item.settings
        local items = {}

        items[#items + 1] = { type = "button", label = s.pinned and NSI:Loc("Unpin") or NSI:Loc("Pin to Top"),
            fnc = function() NSI:SetAuraTrackingPinned(sk, not s.pinned) end }

        if not item.builtin then
            items[#items + 1] = { type = "button", label = NSI:Loc("Duplicate"), fnc = function()
                local newKey = NSI:DuplicateCustomAuraTracking(sk)
                RebuildList(); if newKey then SelectEntry(newKey) end
            end }
            local groupSub = {
                { type = "button", label = NSI:Loc("— No Group —"), fnc = function() NSI:SetAuraTrackingEntryGroup(sk, "") end },
            }
            for _, gname in ipairs(NSI:GetAuraTrackingGroups()) do
                local gn = gname
                groupSub[#groupSub + 1] = { type = "button", label = gn, fnc = function() NSI:SetAuraTrackingEntryGroup(sk, gn) end }
            end
            groupSub[#groupSub + 1] = { type = "button", label = NSI:Loc("New Group..."), fnc = function()
                PromptNewGroup(function(newName) NSI:SetAuraTrackingEntryGroup(sk, newName) end)
            end }
            items[#items + 1] = { type = "submenu", label = NSI:Loc("Add to Group") .. "...", items = groupSub }
        end

        local copySub = {}
        for _, section in ipairs(SECTIONS) do
            local sec = section
            copySub[#copySub + 1] = { type = "button", label = NSI:Loc(sec), fnc = function()
                NSI:CopyAuraTrackingSection(sk, sec)
                print("|cFF00FFFFNSRT:|r " .. string.format(NSI:Loc("Copied %s settings from '%s'."), NSI:Loc(sec), s.Name or NSI:Loc("Unnamed")))
            end }
        end
        items[#items + 1] = { type = "submenu", label = NSI:Loc("Copy") .. "...", items = copySub }

        local pasteSub = {}
        for _, section in ipairs(SECTIONS) do
            if NSI:CanPasteAuraTrackingSection(section) then
                local sec = section
                pasteSub[#pasteSub + 1] = { type = "button", label = NSI:Loc(sec), fnc = function()
                    NSI:PasteAuraTrackingSection(sk, sec)
                    -- Jump to the pasted-into entry so the result is visible even
                    -- when it wasn't the one already open in the right panel.
                    SelectEntry(sk)
                    print("|cFF00FFFFNSRT:|r " .. string.format(NSI:Loc("Pasted %s settings onto '%s'."), NSI:Loc(sec), s.Name or NSI:Loc("Unnamed")))
                end }
            end
        end
        if #pasteSub > 0 then
            items[#items + 1] = { type = "submenu", label = NSI:Loc("Paste") .. "...", items = pasteSub }
        end

        if not item.builtin then
            items[#items + 1] = { type = "separator" }
            items[#items + 1] = { type = "button", label = NSI:Loc("Delete"), fnc = function() ConfirmDelete(sk, s.Name) end }
        end
        ShowContextMenu(items)
    end

    RebuildList = function()
        local model = BuildListModel()
        local entryIdx, headerIdx, slot = 0, 0, 0
        for _, node in ipairs(model) do
            slot = slot + 1
            if node.kind == "header" then
                headerIdx = headerIdx + 1
                if not headerRows[headerIdx] then headerRows[headerIdx] = CreateHeaderRow() end
                local row = headerRows[headerIdx]
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -(slot - 1) * lineHeight)
                row:SetWidth(listChild:GetWidth())
                row.arrow:SetTexture(node.collapsed and CHEVRON_DOWN or CHEVRON_UP)
                row.name:SetText(node.group)
                row.count:SetText("(" .. node.count .. ")")
                row:Show()
                local gname = node.group
                row:SetScript("OnMouseDown", function(_, button)
                    if button == "RightButton" then GroupContextMenu(gname)
                    else NSI:SetAuraTrackingGroupCollapsed(gname, not NSI:GetAuraTrackingGroupCollapsed(gname)); RebuildList() end
                end)
            else
                entryIdx = entryIdx + 1
                if not entryRows[entryIdx] then entryRows[entryIdx] = CreateEntryRow() end
                local row    = entryRows[entryIdx]
                local item   = node.item
                local indent = node.indent and 14 or 0
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", listChild, "TOPLEFT", indent, -(slot - 1) * lineHeight)
                row:SetWidth(listChild:GetWidth() - indent)
                row:Show()

                local settings = item.settings
                local willLoad = NSI:EvaluateLoad(settings)
                if selectedKey == item.settingsKey then
                    row.__background:SetVertexColor(0, 1, 1); row.__background:SetAlpha(1)
                else
                    row.__background:SetVertexColor(0.4, 0.4, 0.4); row.__background:SetAlpha(willLoad and 0.5 or 0.2)
                end

                row.icon:SetTexture(EntryIcon(item.settingsKey, settings))
                row.icon:SetAlpha(willLoad and 1 or 0.35)
                row.name:SetText(settings.Name or NSI:Loc("Unnamed"))
                row.name:SetTextColor(1, 1, 1, willLoad and (settings.enabled and 1 or 0.45) or 0.35)
                row.pinIcon:SetShown(settings.pinned == true)

                row.enabledCB.frame:SetAlpha(willLoad and 1 or 0.4)
                row.enabledCB:SetValue(settings.enabled)
                local sk = item.settingsKey
                row.enabledCB:SetOnChange(function(_, v)
                    local es = NSI:GetAuraTrackingSettings(sk)
                    if es then
                        es.enabled = v; NSI:InitAuraTracking()
                        if selectedKey == sk and enabledCB then enabledCB:SetValue(v) end
                        RebuildList()
                    end
                end)

                if item.builtin then
                    row.deleteBtn:Hide(); row.deleteBtn:SetScript("OnClick", nil); row.lockIcon:Show()
                else
                    row.lockIcon:Hide(); row.deleteBtn:Show()
                    row.deleteBtn:SetScript("OnClick", function() ConfirmDelete(sk, settings.Name) end)
                end

                row:SetScript("OnMouseDown", function(_, button)
                    if row.enabledCB.frame:IsMouseOver() then return end
                    if button == "RightButton" then EntryContextMenu(item); return end
                    SelectEntry(sk)
                end)
            end
        end
        for i = entryIdx + 1, #entryRows do entryRows[i]:Hide() end
        for i = headerIdx + 1, #headerRows do headerRows[i]:Hide() end
        listChild:SetHeight(math.max(slot * lineHeight, 1))
    end

    -- ========================================================================
    -- Right panel
    -- ========================================================================
    rightPanel = CreateFrame("Frame", nil, screen)
    rightPanel:SetPoint("TOPLEFT",     screen, "TOPLEFT",     rightX, topY)
    rightPanel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -pad,   pad)
    rightPanel:Hide()

    local nameLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(nameLbl, 11, "")
    nameLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    nameLbl:SetText(NSI:Loc("Aura Name"))
    nameLbl:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)

    nameEntry = CreateTextEntry(rightPanel, nil,
        function() local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey); return s and s.Name or "" end,
        function(_, v) if selectedKey then NSI:SetAuraTrackingCustomName(selectedKey, v); RebuildList() end end,
        rightW - 340, 22, nil, nil, nil, "NSUIAuraTrackNameEntry")
    nameEntry:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -14)

    local groupLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(groupLbl, 11, "")
    groupLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    groupLbl:SetText(NSI:Loc("Group"))
    groupLbl:SetPoint("BOTTOMLEFT", nameEntry.frame, "BOTTOMRIGHT", 12, 22)

    local function BuildGroupItems()
        local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey)
        if not s or s.builtin then return {} end
        local items = { { label = NSI:Loc("— No Group —"), value = "", onclick = function()
            NSI:SetAuraTrackingEntryGroup(selectedKey, ""); groupDD:Refresh(); RebuildList()
        end } }
        for _, name in ipairs(NSI:GetAuraTrackingGroups()) do
            local gn = name
            items[#items + 1] = { label = gn, value = gn, onclick = function()
                NSI:SetAuraTrackingEntryGroup(selectedKey, gn); groupDD:Refresh(); RebuildList()
            end }
        end
        items[#items + 1] = { label = NSI:Loc("New Group..."), value = "__new__", onclick = function()
            PromptNewGroup(function(newName) NSI:SetAuraTrackingEntryGroup(selectedKey, newName); groupDD:Refresh(); RebuildList() end)
        end }
        return items
    end
    local function GetGroupSelected()
        local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey)
        if not s then return "" end
        if s.builtin then return NSI.AuraTrackingBuiltinGroup end
        return (s.group and s.group ~= "") and s.group or NSI:Loc("— No Group —")
    end
    groupDD = CreateDropdown(rightPanel, nil, BuildGroupItems, GetGroupSelected, 130, 22, "NSUIAuraTrackGroupDD")
    groupDD:SetPoint("LEFT", nameEntry.frame, "RIGHT", 12, 0)

    enabledCB = CreateCheckButton(rightPanel, NSI:Loc("Enabled"),
        function() local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey); return s and s.enabled or false end,
        function(_, v)
            local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey)
            if s then s.enabled = v; NSI:InitAuraTracking(); RebuildList() end
        end, 90, 22, "NSUIAuraTrackEnabled")
    enabledCB:SetPoint("LEFT", groupDD.frame, "RIGHT", 8, 0)

    local previewBtn = CreateLocalizedButton(rightPanel, "Preview", function()
        if not selectedKey then return end
        local flag = PreviewFlag(selectedKey)
        NSI[flag] = not NSI[flag]
        NSI:PreviewAuraTracking(selectedKey, NSI[flag])
    end, 80, 22, "NSUIAuraTrackPreview")
    previewBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, 0)

    -- ── Inner tab bar ────────────────────────────────────────────────────────
    local tabBtns, tabFrames, tabScroll = {}, {}, {}
    local activeTab = "Display"
    local tabRowY   = -44
    local contentY  = tabRowY - 24

    local sep = rightPanel:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  rightPanel, "TOPLEFT",  0, tabRowY - 20)
    sep:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY - 20)

    for _, name in ipairs(SECTIONS) do
        local f = CreateFrame("Frame", nil, rightPanel)
        f:SetPoint("TOPLEFT",     rightPanel, "TOPLEFT",     0, contentY)
        f:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)
        f:Hide()
        tabFrames[name] = f
    end

    local function apply(key) NSI:UpdateAuraTrackingDisplay(key) end

    -- ── Fixed anchor row at the top of the Display tab ───────────────────────
    local displayF = tabFrames["Display"]
    local anchorLbl = displayF:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(anchorLbl, 11, "")
    anchorLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    anchorLbl:SetText(NSI:Loc("Anchor Frame"))
    anchorLbl:SetPoint("TOPLEFT", displayF, "TOPLEFT", 0, 0)

    anchorEntry = CreateTextEntry(displayF, nil,
        function() local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey); return s and s.CustomAnchorFrame or "UIParent" end,
        function(_, v)
            local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey)
            if not s then return end
            v = strtrim(tostring(v or ""))
            if v == "" then v = "UIParent" end
            if not NSI:IsValidAuraTrackingAnchorFrame(v) then
                print("|cFF00FFFFNSRT:|r " .. NSI:Loc("Anchor frame not found."))
                anchorEntry:SetValue(s.CustomAnchorFrame or "UIParent")
                return
            end
            s.CustomAnchorFrame = v; apply(selectedKey)
        end,
        rightW - 120, 22, nil, nil, nil, "NSUIAuraTrackAnchorEntry")
    anchorEntry:SetPoint("TOPLEFT", displayF, "TOPLEFT", 0, -18)

    local pickBtn = CreateLocalizedButton(displayF, "Pick", function() StartFramePicker() end, 100, 22, "NSUIAuraTrackPick")
    pickBtn:SetPoint("LEFT", anchorEntry.frame, "RIGHT", 8, 0)

    -- ── Definition builders (Display / Trigger via BuildWidgets) ─────
    local function BuildDisplayDefs(s, key)
        local defs = {}
        local function add(d) defs[#defs + 1] = d end
        local function tip(title, desc)
            return { title = title, desc = desc }
        end
        add({ Type = "Label", text = "Anchor Point" })
        add({ Type = "Dropdown", label = "Anchor Point", values = ANCHOR_POINTS,
            tooltip = tip("Anchor Point", "Point on this Aura Tracking display that should be anchored."),
            get = function() return s.Anchor or "CENTER" end, set = function(_, v) s.Anchor = v; apply(key) end })
        add({ Type = "Dropdown", label = "Relative Point", values = ANCHOR_POINTS,
            tooltip = tip("Relative Point", "Point on the anchor frame that this Aura Tracking display should attach to."),
            get = function() return s.relativeTo or "CENTER" end, set = function(_, v) s.relativeTo = v; apply(key) end })
        -- While a live preview is active, reposition it directly instead of
        -- going through apply()/PreviewAuraTracking on every slider tick —
        -- that full rebuild resets the preview icons' randomized durations
        -- and restarts their timer, which flickers when scrubbed rapidly.
        -- When not previewing there's nothing visible to keep in sync, so
        -- the (heavier) real re-init is throttled rather than fired per-pixel.
        local lastFullApplyPositionTime = 0
        local function applyPosition(k)
            if NSI[PreviewFlag(k)] then
                NSI:RepositionAuraTrackingPreview(k)
                return
            end
            local now = GetTime()
            if now - lastFullApplyPositionTime >= 0.1 then
                lastFullApplyPositionTime = now
                apply(k)
            end
        end
        add({ Type = "Slider", label = "X-Offset", min = -3000, max = 3000, step = 1, liveDrag = true,
            tooltip = tip("X-Offset", "Horizontal offset of the Aura Tracking display"),
            get = function() return s.xOffset end, set = function(_, v) s.xOffset = v; applyPosition(key) end })
        add({ Type = "Slider", label = "Y-Offset", min = -3000, max = 3000, step = 1, liveDrag = true,
            tooltip = tip("Y-Offset", "Vertical offset of the Aura Tracking display"),
            get = function() return s.yOffset end, set = function(_, v) s.yOffset = v; applyPosition(key) end })

        add({ Type = "Label", text = "Layout" })
        add({ Type = "Dropdown", label = "Grow Direction", values = GROW_DIRECTIONS,
            tooltip = tip("Grow Direction", "Grow Direction"),
            get = function() return s.GrowDirection end, set = function(_, v) s.GrowDirection = v; apply(key) end })
        add({ Type = "Slider", label = "Spacing", min = -5, max = 20, step = 1,
            tooltip = tip("Spacing", "Spacing between Aura Tracking icons"),
            get = function() return s.Spacing end, set = function(_, v) s.Spacing = v; apply(key) end })
        add({ Type = "Slider", label = "Width", min = 10, max = 500, step = 1,
            tooltip = tip("Width", "Width of the Aura Tracking icons"),
            get = function() return s.Width end, set = function(_, v) s.Width = v; apply(key) end })
        add({ Type = "Slider", label = "Height", min = 10, max = 500, step = 1,
            tooltip = tip("Height", "Height of the Aura Tracking icons"),
            get = function() return s.Height end, set = function(_, v) s.Height = v; apply(key) end })
        add({ Type = "Slider", label = "Zoom", min = 0, max = 100, step = 1,
            tooltip = tip("Zoom", "Zooms the icon texture inwards"),
            get = function() return s.Zoom end, set = function(_, v) s.Zoom = v; apply(key) end })
        add({ Type = "Slider", label = "Max Icons", min = 1, max = 20, step = 1,
            tooltip = tip("Max Icons", "Maximum number of auras to display"),
            get = function() return s.Limit end, set = function(_, v) s.Limit = v; apply(key) end })
        add({ Type = "Checkbox", label = "Reverse Sort",
            tooltip = tip("Reverse Sort", "Show auras with the longest remaining duration first."),
            get = function() return s.ReverseSort end, set = function(_, v) s.ReverseSort = v; apply(key) end })

        add({ Type = "Label", text = "Icon" })
        add({ Type = "Slider", label = "Border Size", min = 0, max = 10, step = 1,
            tooltip = tip("Border Size", "Size of the black border around tracked aura icons. Set to 0 to disable it."),
            get = function() return s.BorderSize end, set = function(_, v) s.BorderSize = v; apply(key) end })
        add({ Type = "Checkbox", label = "Show Dispel Border",
            tooltip = tip("Show Dispel Border", "Show Blizzard's dispel-type border and icon on tracked auras."),
            get = function() return s.ShowDispelBorder end, set = function(_, v) s.ShowDispelBorder = v; apply(key) end })
        add({ Type = "Checkbox", label = "Enable Cooldown Swipe",
            tooltip = tip("Enable Cooldown Swipe", "Shows a cooldown swipe on tracked aura icons."),
            get = function() return s.EnableCooldownSwipe end, set = function(_, v) s.EnableCooldownSwipe = v; apply(key) end })
        add({ Type = "Checkbox", label = "Inverse Cooldown Swipe",
            tooltip = tip("Inverse Cooldown Swipe", "Reverses the cooldown swipe direction on tracked aura icons."),
            get = function() return s.InverseCooldownSwipe end, set = function(_, v) s.InverseCooldownSwipe = v; apply(key) end })
        add({ Type = "Checkbox", label = "Disable Tooltip",
            tooltip = tip("Disable Tooltip", "Hide tooltips on mouseover. The frame will be clickthrough regardless."),
            get = function() return s.HideTooltip end, set = function(_, v) s.HideTooltip = v; apply(key) end })
        if key == "Player" or key == "Tank" then
            add({ Type = "Checkbox", label = "Hide Long Duration Auras",
                tooltip = tip("Hide Long Duration Auras", "Hide auras with no duration or a duration longer than 3 minutes."),
                get = function() return s.HideLongDurationAuras end, set = function(_, v) s.HideLongDurationAuras = v; apply(key) end })
        end

        add({ Type = "Label", text = "Text Style" })
        add({ Type = "Dropdown", label = "Text Font", values = BuildFontValues,
            tooltip = tip("Text Font", "Font used for duration and stack text"),
            get = function() return s.TextFont end, set = function(_, v) s.TextFont = v; apply(key) end })
        add({ Type = "Dropdown", label = "Text Outline", values = FONT_FLAGS,
            tooltip = tip("Text Outline", "Outline style used for duration and stack text"),
            get = function() return s.TextFontFlags end, set = function(_, v) s.TextFontFlags = v; apply(key) end })

        add({ Type = "Label", text = "Duration Text" })
        add({ Type = "Checkbox", label = "Hide Duration Text",
            tooltip = tip("Hide Duration Text", "Hide the duration text on tracked auras."),
            get = function() return s.HideDurationText end, set = function(_, v) s.HideDurationText = v; apply(key) end })
        add({ Type = "Color", label = "Duration Color",
            tooltip = tip("Duration Color", "Color of the duration text"),
            get = function() return unpack(s.DurationColor) end, set = function(_, r, g, b, a) s.DurationColor = {r, g, b, a}; apply(key) end })
        add({ Type = "Slider", label = "Duration Font Size", min = 6, max = 80, step = 1,
            tooltip = tip("Duration Font Size", "Font size of the duration text"),
            get = function() return s.DurationFontSize end, set = function(_, v) s.DurationFontSize = v; apply(key) end })
        add({ Type = "Slider", label = "Duration X-Offset", min = -200, max = 200, step = 1,
            tooltip = tip("Duration X-Offset", "Horizontal offset of the duration text"),
            get = function() return s.DurationXOffset end, set = function(_, v) s.DurationXOffset = v; apply(key) end })
        add({ Type = "Slider", label = "Duration Y-Offset", min = -200, max = 200, step = 1,
            tooltip = tip("Duration Y-Offset", "Vertical offset of the duration text"),
            get = function() return s.DurationYOffset end, set = function(_, v) s.DurationYOffset = v; apply(key) end })

        add({ Type = "Label", text = "Stack Text" })
        add({ Type = "Checkbox", label = "Hide Stack Text",
            tooltip = tip("Hide Stack Text", "Hide the stack count text on tracked auras."),
            get = function() return s.HideStackText end, set = function(_, v) s.HideStackText = v; apply(key) end })
        add({ Type = "Color", label = "Stack Color",
            tooltip = tip("Stack Color", "Color of the stack text"),
            get = function() return unpack(s.StackColor) end, set = function(_, r, g, b, a) s.StackColor = {r, g, b, a}; apply(key) end })
        add({ Type = "Slider", label = "Stack Font Size", min = 6, max = 80, step = 1,
            tooltip = tip("Stack Font Size", "Font size of the stack text"),
            get = function() return s.StackFontSize end, set = function(_, v) s.StackFontSize = v; apply(key) end })
        add({ Type = "Slider", label = "Stack X-Offset", min = -200, max = 200, step = 1,
            tooltip = tip("Stack X-Offset", "Horizontal offset of the stack text"),
            get = function() return s.StackXOffset end, set = function(_, v) s.StackXOffset = v; apply(key) end })
        add({ Type = "Slider", label = "Stack Y-Offset", min = -200, max = 200, step = 1,
            tooltip = tip("Stack Y-Offset", "Vertical offset of the stack text"),
            get = function() return s.StackYOffset end, set = function(_, v) s.StackYOffset = v; apply(key) end })

        if key == "Tank" then
            add({ Type = "Label", text = "Co-Tank Name Settings" })
            add({ Type = "Checkbox", label = "Show Co-Tank Name",
                tooltip = tip("Show Co-Tank Name", "Shows the co-tank name attached to visible aura icons."),
                get = function() return s.NameEnabled end, set = function(_, v) s.NameEnabled = v; apply(key) end })
            add({ Type = "Dropdown", label = "Name Position", values = NAME_POSITIONS,
                tooltip = tip("Name Position", "Position of the co-tank name relative to the aura icon."),
                get = function() return s.NamePosition end, set = function(_, v) s.NamePosition = v; apply(key) end })
            add({ Type = "Slider", label = "Name X-Offset", min = -200, max = 200, step = 1,
                tooltip = tip("Name X-Offset", "Horizontal offset of the co-tank name."),
                get = function() return s.NameXOffset end, set = function(_, v) s.NameXOffset = v; apply(key) end })
            add({ Type = "Slider", label = "Name Y-Offset", min = -200, max = 200, step = 1,
                tooltip = tip("Name Y-Offset", "Vertical offset of the co-tank name."),
                get = function() return s.NameYOffset end, set = function(_, v) s.NameYOffset = v; apply(key) end })
            add({ Type = "Slider", label = "Name Font Size", min = 6, max = 80, step = 1,
                tooltip = tip("Name Font Size", "Font size of the co-tank name."),
                get = function() return s.NameFontSize end, set = function(_, v) s.NameFontSize = v; apply(key) end })
        end
        return defs
    end

    local function BuildTriggerDefs(s, key)
        if tostring(key):match("^Custom:") == nil then
            return { { Type = "Label", text = (key == "External")
                and "This built-in display tracks a curated list of external/immunity buffs."
                or  "This built-in display tracks all boss & role debuffs automatically." } }
        end
        local friendly = NSI:IsAuraTrackingUnitFriendly(s.Unit)
        return {
            -- No inline `label` on these TextEntries: CreateTextEntry only
            -- reserves a fixed 60px input box when given a label (the rest of
            -- the width goes to the label text), so a preceding standalone
            -- Label caption + a label-less full-width TextEntry is used instead.
            { Type = "Label", text = "Spell IDs (comma or space separated)" },
            { Type = "TextEntry",
                get = function() return NSI:GetAuraTrackingSpellIDString(key) end,
                set = function(_, v) NSI:SetAuraTrackingSpellIDString(key, v); RebuildList() end },
            { Type = "Label", text = "Unit" },
            { Type = "TextEntry",
                get = function() return s.Unit or "player" end,
                set = function(_, v)
                    v = strtrim(tostring(v or ""))
                    s.Unit = (v ~= "") and v or "player"
                    apply(key); RebuildCurrentTab()
                end },
            { Type = "Label", text = "e.g. player, cotank, target, focus, boss1-boss8, party1-4, raid1-40" },
            { Type = "Label", text = friendly
                and "|cFF88FF88Friendly unit:|r tracks matching |cFFFFFFFFbuffs|r."
                or  "|cFFFF8888Enemy unit:|r tracks matching |cFFFFFFFFdebuffs|r." },
            { Type = "Label", text = "Blizzard only allows spell-ID filtering for buffs on friendly units and debuffs on enemy units." },
            { Type = "Label", text = "Preview Spell ID" },
            { Type = "TextEntry",
                tooltip = { title = "Preview Spell ID", desc = "Spell ID used for the custom Aura Tracking list icon." },
                get = function() return s.PreviewSpellID and tostring(s.PreviewSpellID) or "" end,
                set = function(_, v) NSI:SetAuraTrackingPreviewSpellID(key, v); RebuildList() end },
        }
    end

    local DEF_BUILDERS = { Display = BuildDisplayDefs, Trigger = BuildTriggerDefs }

    local function RebuildWidgetTab()
        if not selectedKey then return end
        local settings = NSI:GetAuraTrackingSettings(selectedKey)
        if not settings then return end
        local container = tabFrames[activeTab]
        if tabScroll[activeTab] then tabScroll[activeTab].frame:Hide(); tabScroll[activeTab] = nil end
        local topPad = (activeTab == "Display") and DISPLAY_TOP or 0
        local defs = DEF_BUILDERS[activeTab](settings, selectedKey)
        local scrollObj = CreateScrollBox(container, tabScrollW, tabContentH - topPad)
        scrollObj.frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -topPad)
        local totalH = BuildWidgets(scrollObj.scrollChild, defs, scrollObj.scrollChild:GetWidth(), "NSRTAuraTrack" .. activeTab)
        scrollObj.scrollChild:SetHeight(math.max(totalH, 1))
        scrollObj:UpdateScrollBar()
        tabScroll[activeTab] = scrollObj
    end

    -- ========================================================================
    -- Load tab (hand-rolled, EncounterAlerts-style collapsible sections)
    -- ========================================================================
    local loadF = tabFrames["Load"]
    local loadScroll = CreateFrame("ScrollFrame", "NSUIAuraTrackLoadScroll", loadF, "UIPanelScrollFrameTemplate")
    loadScroll:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, 0)
    loadScroll:SetSize(tabScrollW, tabContentH)
    loadScroll:EnableMouseWheel(true)
    loadScroll:SetScript("OnMouseWheel", function(_, delta)
        local bar = _G["NSUIAuraTrackLoadScrollScrollBar"]
        if bar then local cur = bar:GetValue(); local mn, mx = bar:GetMinMaxValues(); bar:SetValue(math.max(mn, math.min(mx, cur - delta * 24))) end
    end)
    ReskinScrollbar(loadScroll)
    local loadChild = CreateFrame("Frame", nil, loadScroll, "BackdropTemplate")
    loadChild:SetSize(tabScrollW - 18, 1)
    loadScroll:SetScrollChild(loadChild)

    local loadCollapsed = { Roles = false, Classes = true, Specs = true, Names = false }
    local loadRowW = tabScrollW - 22
    local hdrPool, chkPool, nameRowPool = {}, {}, {}
    local nameInput  -- created lazily

    local function MakeLoadHeader()
        local btn = CreateFrame("Button", nil, loadChild, "BackdropTemplate")
        btn:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
        btn:SetBackdropColor(0.05, 0.30, 0.40, 0.9)
        btn:SetSize(loadRowW, 18)
        btn.arrow = btn:CreateTexture(nil, "OVERLAY")
        btn.arrow:SetSize(10, 10)
        btn.arrow:SetPoint("LEFT", btn, "LEFT", 3, 0)
        btn.arrow:SetVertexColor(0.4, 0.85, 1, 1)
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(btn.text, 12, "")
        btn.text:SetTextColor(0.2, 0.85, 1, 1)
        btn.text:SetPoint("LEFT", btn, "LEFT", 18, 0)
        btn:Hide()
        return btn
    end

    local function MakeCheckRow()
        local row = CreateFrame("Button", nil, loadChild, "BackdropTemplate")
        row:SetSize(loadRowW, 20)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.box = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.box:SetSize(12, 12)
        row.box:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.box:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
        row.box:SetBackdropColor(0.05, 0.05, 0.05, 1)
        row.box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        row.fill = row.box:CreateTexture(nil, "ARTWORK")
        row.fill:SetPoint("TOPLEFT", row.box, "TOPLEFT", 2, -2)
        row.fill:SetPoint("BOTTOMRIGHT", row.box, "BOTTOMRIGHT", -2, 2)
        row.fill:SetColorTexture(0, 1, 1, 0.9)
        row.fill:Hide()
        row.label = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.label, 12, "")
        row.label:SetPoint("LEFT", row.box, "RIGHT", 8, 0)
        row.label:SetJustifyH("LEFT")
        row:Hide()
        return row
    end

    local function MakeNameRow()
        local row = CreateFrame("Frame", nil, loadChild)
        row:SetSize(loadRowW, 20)
        row.label = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.label, 12, "")
        row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.label:SetJustifyH("LEFT")
        row.removeBtn = CreateFrame("Button", nil, row)
        row.removeBtn:SetSize(14, 14)
        row.removeBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.removeBtn:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        row.removeBtn:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        row.removeBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
        row:Hide()
        return row
    end

    local RebuildLoadTab
    local function LoadSection(y, sectionKey, label, count)
        local idx = #hdrPool + 1
        for i, h in ipairs(hdrPool) do if not h:IsShown() then idx = i; break end end
        hdrPool[idx] = hdrPool[idx] or MakeLoadHeader()
        local hdr = hdrPool[idx]
        hdr:ClearAllPoints()
        hdr:SetPoint("TOPLEFT", loadChild, "TOPLEFT", 0, -y)
        hdr:SetWidth(loadRowW)
        hdr.arrow:SetTexture(loadCollapsed[sectionKey] and CHEVRON_DOWN or CHEVRON_UP)
        hdr.text:SetText(count and (label .. "  |cFF808080(" .. count .. ")|r") or label)
        hdr:SetScript("OnClick", function() loadCollapsed[sectionKey] = not loadCollapsed[sectionKey]; RebuildLoadTab() end)
        hdr:Show()
        return y + 20
    end

    RebuildLoadTab = function()
        for _, h in ipairs(hdrPool) do h:Hide() end
        for _, r in ipairs(chkPool) do r:Hide() end
        for _, r in ipairs(nameRowPool) do r:Hide() end
        if nameInput then nameInput.frame:Hide(); nameInput.addBtn.frame:Hide() end
        if not selectedKey then return end
        local s = NSI:GetAuraTrackingSettings(selectedKey)
        if not s then return end
        s.loadConditions = s.loadConditions or {}
        local cond = s.loadConditions
        cond.Roles = cond.Roles or {}; cond.Classes = cond.Classes or {}; cond.SpecIDs = cond.SpecIDs or {}; cond.Names = cond.Names or {}

        local chkIdx = 0
        local function CountSel(tbl) local n = 0; for _ in pairs(tbl) do n = n + 1 end; return n end
        local function AddCheck(y, label, checked, onToggle, r, g, b)
            chkIdx = chkIdx + 1
            chkPool[chkIdx] = chkPool[chkIdx] or MakeCheckRow()
            local row = chkPool[chkIdx]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", loadChild, "TOPLEFT", 0, -y)
            row:SetWidth(loadRowW)
            row.label:SetText(label)
            if checked then
                row.fill:Show(); row.box:SetBackdropBorderColor(0, 1, 1, 0.9)
                row.bg:SetColorTexture((r or 0) * 0.35, (g or 0) * 0.35, (b or 0) * 0.35, 0.85)
            else
                row.fill:Hide(); row.box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
                row.bg:SetColorTexture(0.1, 0.1, 0.1, (chkIdx % 2 == 0) and 0.4 or 0)
            end
            row:SetScript("OnClick", function() onToggle(); NSI:InitAuraTracking(); RebuildList(); RebuildLoadTab() end)
            row:Show()
            return y + 20
        end

        local y = 0
        -- Roles
        y = LoadSection(y, "Roles", NSI:Loc("Roles (leave all unchecked for any role)"), CountSel(cond.Roles))
        if not loadCollapsed.Roles then
            for _, rd in ipairs(ROLE_DATA) do
                local k = rd.key; local c = ROLE_COLORS[k]
                y = AddCheck(y, rd.label, cond.Roles[k], function() cond.Roles[k] = (not cond.Roles[k]) or nil end, c[1], c[2], c[3])
            end
        end
        -- Classes
        y = y + 4
        y = LoadSection(y, "Classes", NSI:Loc("Classes"), CountSel(cond.Classes))
        if not loadCollapsed.Classes then
            for _, cd in ipairs(CLASS_DATA) do
                local k = cd.key; local cr, cg, cb = ClassColor(k)
                y = AddCheck(y, cd.label, cond.Classes[k], function() cond.Classes[k] = (not cond.Classes[k]) or nil end, cr, cg, cb)
            end
        end
        -- Specs
        y = y + 4
        y = LoadSection(y, "Specs", NSI:Loc("Specializations"), CountSel(cond.SpecIDs))
        if not loadCollapsed.Specs then
            for _, sd in ipairs(SPEC_DATA) do
                local id = sd.id; local cr, cg, cb = ClassColor(sd.class)
                y = AddCheck(y, sd.label .. " |cFF808080(" .. sd.class:sub(1, 3) .. ")|r", cond.SpecIDs[id],
                    function() cond.SpecIDs[id] = (not cond.SpecIDs[id]) or nil end, cr, cg, cb)
            end
        end
        -- Names
        y = y + 4
        local nameCount = 0; for _ in pairs(cond.Names) do nameCount = nameCount + 1 end
        y = LoadSection(y, "Names", NSI:Loc("Player Names"), nameCount)
        if not loadCollapsed.Names then
            if not nameInput then
                nameInput = CreateTextEntry(loadChild, nil, nil, nil, loadRowW - 60, 20, nil, nil, nil, "NSUIAuraTrackNameInput")
                nameInput.addBtn = CreateButton(loadChild, "+", function()
                    local nm = strtrim(nameInput.editBox:GetText() or "")
                    if nm ~= "" and selectedKey then
                        local cs = NSI:GetAuraTrackingSettings(selectedKey)
                        if cs then cs.loadConditions.Names = cs.loadConditions.Names or {}; cs.loadConditions.Names[nm] = true
                            nameInput.editBox:SetText(""); NSI:InitAuraTracking(); RebuildList(); RebuildLoadTab() end
                    end
                end, 44, 20, "NSUIAuraTrackNameAdd")
            end
            nameInput.frame:ClearAllPoints(); nameInput:SetPoint("TOPLEFT", loadChild, "TOPLEFT", 0, -y)
            nameInput.frame:Show()
            nameInput.addBtn.frame:ClearAllPoints(); nameInput.addBtn:SetPoint("LEFT", nameInput.frame, "RIGHT", 8, 0)
            nameInput.addBtn.frame:Show()
            y = y + 24
            local sortedNames = {}
            for nm in pairs(cond.Names) do sortedNames[#sortedNames + 1] = nm end
            table.sort(sortedNames)
            local nIdx = 0
            for _, nm in ipairs(sortedNames) do
                nIdx = nIdx + 1
                nameRowPool[nIdx] = nameRowPool[nIdx] or MakeNameRow()
                local row = nameRowPool[nIdx]
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", loadChild, "TOPLEFT", 0, -y)
                row:SetWidth(loadRowW)
                row.label:SetText(nm)
                local nmCap = nm
                row.removeBtn:SetScript("OnClick", function()
                    local cs = NSI:GetAuraTrackingSettings(selectedKey)
                    if cs and cs.loadConditions.Names then cs.loadConditions.Names[nmCap] = nil
                        NSI:InitAuraTracking(); RebuildList(); RebuildLoadTab() end
                end)
                row:Show()
                y = y + 20
            end
        end

        loadChild:SetHeight(math.max(y, 1))
        local bar = _G["NSUIAuraTrackLoadScrollScrollBar"]
        if bar then local maxScroll = math.max(0, y - loadScroll:GetHeight()); bar:SetMinMaxValues(0, maxScroll); if bar:GetValue() > maxScroll then bar:SetValue(0) end end
    end

    -- ── Tab dispatch ─────────────────────────────────────────────────────────
    RebuildCurrentTab = function()
        if activeTab == "Load" then RebuildLoadTab() else RebuildWidgetTab() end
    end

    local function SelectInnerTab(name)
        activeTab = name
        for _, tn in ipairs(SECTIONS) do
            tabFrames[tn]:SetShown(tn == name)
            if tn == name then tabBtns[tn]:Select() else tabBtns[tn]:Deselect() end
        end
        RebuildCurrentTab()
    end

    local tabBtnW, tabBtnGap = 84, 3
    for i, name in ipairs(SECTIONS) do
        local tn = name
        local btn = CreateLocalizedSubButton(rightPanel, name, function() SelectInnerTab(tn) end, tabBtnW, "NSUIAuraTrackTab" .. name)
        btn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", (i - 1) * (tabBtnW + tabBtnGap), tabRowY)
        tabBtns[name] = btn
    end

    -- ── SelectEntry ─────────────────────────────────────────────────────────
    SelectEntry = function(key)
        selectedKey = key
        local settings = key and NSI:GetAuraTrackingSettings(key)
        if not settings then rightPanel:Hide(); RebuildList(); return end
        rightPanel:Show()
        nameEntry:SetValue(settings.Name or "")
        nameEntry.editBox:SetEnabled(not settings.builtin)
        nameEntry.editBox:SetAlpha(settings.builtin and 0.5 or 1)
        anchorEntry:SetValue(settings.CustomAnchorFrame or "UIParent")
        groupDD:Refresh()
        enabledCB:SetValue(settings.enabled)
        SelectInnerTab(activeTab)
        RebuildList()
    end

    -- ========================================================================
    -- Frame picker — live-updates the anchor text as you hover; click confirms.
    -- ========================================================================
    local pickerOverlay, pickerOriginal, pickerLastName
    local function IsNSUIDescendant(f)
        local cur = f
        while cur do if cur == NSUI then return true end cur = cur:GetParent() end
        return false
    end
    local function FrameUnderMouse()
        local foci
        if GetMouseFoci then foci = GetMouseFoci()
        elseif GetMouseFocus then local f = GetMouseFocus(); foci = f and { f } or nil end
        for _, f in ipairs(foci or {}) do
            if f ~= pickerOverlay and f.GetName and f:GetName() and not IsNSUIDescendant(f) then
                return f
            end
        end
    end

    StartFramePicker = function()
        if not selectedKey then return end
        local settings = NSI:GetAuraTrackingSettings(selectedKey)
        if not settings then return end
        pickerOriginal = settings.CustomAnchorFrame or "UIParent"
        pickerLastName = nil

        if not pickerOverlay then
            pickerOverlay = CreateFrame("Button", "NSUIAuraTrackFramePicker", UIParent)
            pickerOverlay:SetAllPoints(UIParent)
            pickerOverlay:SetFrameStrata("FULLSCREEN_DIALOG")
            pickerOverlay:EnableMouse(true)
            pickerOverlay:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            local bg = pickerOverlay:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(); bg:SetColorTexture(0, 0.6, 1, 0.06)
            pickerOverlay.label = pickerOverlay:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(pickerOverlay.label, 16, "OUTLINE")
            pickerOverlay.label:SetPoint("CENTER", UIParent, "CENTER", 0, 220)
            pickerOverlay.hint = pickerOverlay:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(pickerOverlay.hint, 13, "OUTLINE")
            pickerOverlay.hint:SetTextColor(0.8, 0.8, 0.8, 1)
            pickerOverlay.hint:SetPoint("TOP", pickerOverlay.label, "BOTTOM", 0, -6)
            pickerOverlay.hint:SetText(NSI:Loc("Left-click to confirm, right-click or Escape to cancel."))
        end

        local function Finish() pickerOverlay:SetScript("OnUpdate", nil); pickerOverlay:EnableKeyboard(false); pickerOverlay:Hide() end
        local function ApplyName(name)
            local s = selectedKey and NSI:GetAuraTrackingSettings(selectedKey)
            if not s then return end
            s.CustomAnchorFrame = name
            anchorEntry:SetValue(name)
            apply(selectedKey)
        end

        pickerOverlay:SetScript("OnUpdate", function()
            local f = FrameUnderMouse()
            local n = f and f:GetName()
            if n and n ~= pickerLastName then
                pickerLastName = n
                ApplyName(n)
                pickerOverlay.label:SetText("|cFF00FFFF" .. n .. "|r")
            elseif not n then
                pickerOverlay.label:SetText(NSI:Loc("Hover over a frame..."))
            end
        end)
        pickerOverlay:SetScript("OnClick", function(_, button)
            if button == "RightButton" then ApplyName(pickerOriginal) end
            Finish()
        end)
        pickerOverlay:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:SetPropagateKeyboardInput(false); ApplyName(pickerOriginal); Finish()
            else self:SetPropagateKeyboardInput(true) end
        end)
        pickerOverlay:EnableKeyboard(true)
        pickerOverlay:SetPropagateKeyboardInput(true)
        pickerOverlay:Show()
    end

    -- ========================================================================
    -- Refresh hook + first build
    -- ========================================================================
    NSI._RefreshAuraTrackingUI = function()
        RebuildList()
        if selectedKey and NSI:GetAuraTrackingSettings(selectedKey) then
            if anchorEntry then anchorEntry:SetValue(NSI:GetAuraTrackingSettings(selectedKey).CustomAnchorFrame or "UIParent") end
            RebuildCurrentTab()
        elseif rightPanel then
            selectedKey = nil; rightPanel:Hide()
        end
    end

    -- Fired (throttled) by the backend while the live preview mover is being
    -- dragged, so the Display tab's Anchor/X-Offset/Y-Offset controls track
    -- the drag instead of only updating once the mouse is released.
    NSI._OnAuraTrackingPreviewDragged = function(key)
        if key ~= selectedKey then return end
        if not rightPanel:IsShown() then return end
        if activeTab ~= "Display" then return end
        anchorEntry:SetValue(NSI:GetAuraTrackingSettings(selectedKey).CustomAnchorFrame or "UIParent")
        RebuildWidgetTab()
    end

    RebuildList()
    return { screen = screen, RebuildList = RebuildList, SelectEntry = SelectEntry }
end

NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.AuraTracking = { BuildUI = BuildAuraTrackingUI }
