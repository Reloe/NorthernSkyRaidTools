local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template
local BossData = NSI.UI.BossData
local CreateCheckButton = NSI.UI.Components.CreateCheckButton
local CreateLocalizedButton = NSI.UI.Components.CreateLocalizedButton
local CreateLocalizedSubButton = NSI.UI.Components.CreateLocalizedSubButton
local ShowContextMenu = NSI.UI.Components.ShowContextMenu

local function T(key)
    return NSI:Loc(key)
end

local function ApplyUIFont(object, size, flags)
    if not object then return end
    if object.GetFontString then
        object = object:GetFontString()
    end
    NSI:SetUIFont(object, size or 11, flags or "")
end

local function CreateLabel(parent, text, size, flags)
    local label = parent:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(label, size or 12, flags or "")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    return label
end

local function GetUIObject(object)
    return object and (object.widget or object.label or object)
end

local soundlist = NSI.LSM:List("sound")

local function StripSoundColor(sound)
    if type(sound) ~= "string" then return sound end
    return sound:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function BuildAuraSoundDropdown()
    local t = {
        {
            label = T("None"),
            value = "__NONE__",
            onclick = function(_, _, value)
                return value
            end,
        },
    }
    for _, sound in ipairs(soundlist) do
        local value = StripSoundColor(sound)
        tinsert(t, {
            label = sound,
            value = value,
            onclick = function(_, _, value)
                local toplay = NSI.LSM:Fetch("sound", sound)
                if toplay then
                    PlaySoundFile(toplay, NSRT.AuraSounds.SoundChannel or "Master")
                end
                return value
            end,
        })
    end
    return t
end

local AuraSoundEventTypes = {
    { label = "Applied", value = "applied" },
    { label = "Removed", value = "removed" },
    { label = "Stack Gain", value = "stackGain" },
}

local AuraSoundChannels = {
    "Master",
    "SFX",
    "Music",
    "Ambience",
    "Dialog",
}

local function BuildAuraSoundChannelDropdown()
    local options = {}
    for _, channel in ipairs(AuraSoundChannels) do
        options[#options + 1] = {
            label = T(channel),
            value = channel,
            onclick = function(_, _, value)
                NSRT.AuraSounds.SoundChannel = value
                NSI:RebuildAuraSounds()
                return value
            end,
        }
    end
    return options
end

local function BuildAuraSoundEventDropdown()
    local options = {}
    for _, eventInfo in ipairs(AuraSoundEventTypes) do
        options[#options + 1] = {
            label = T(eventInfo.label),
            value = eventInfo.value,
            onclick = function(_, _, value)
                return value
            end,
        }
    end
    return options
end

local function GetAuraSoundEventLabel(eventType)
    eventType = eventType or "applied"
    for _, eventInfo in ipairs(AuraSoundEventTypes) do
        if eventInfo.value == eventType then
            return T(eventInfo.label)
        end
    end
    return T("Applied")
end

local function ShowAuraSoundSpellTooltip(icon, spellID)
    if not spellID then return end
    GameTooltip:SetOwner(icon, "ANCHOR_CURSOR_RIGHT")
    GameTooltip:SetSpellByID(spellID)
    GameTooltip:Show()

    if C_Spell and C_Spell.RequestLoadSpellData then
        C_Spell.RequestLoadSpellData(spellID)
    end

    C_Timer.After(0.1, function()
        if icon:IsMouseOver() and icon:GetParent() and icon:GetParent().spellID == spellID then
            GameTooltip:SetOwner(icon, "ANCHOR_CURSOR_RIGHT")
            GameTooltip:SetSpellByID(spellID)
            GameTooltip:Show()
        end
    end)
    C_Timer.After(0.5, function()
        if icon:IsMouseOver() and icon:GetParent() and icon:GetParent().spellID == spellID then
            GameTooltip:SetOwner(icon, "ANCHOR_CURSOR_RIGHT")
            GameTooltip:SetSpellByID(spellID)
            GameTooltip:Show()
        end
    end)
end

local function GetAuraSoundCategories(categoryType)
    local categories = {}
    for _, category in ipairs((NSI.AuraSoundCategories and NSI.AuraSoundCategories[categoryType]) or {}) do
        categories[#categories + 1] = category
    end
    if categoryType == "Custom" then
        for _, category in ipairs(NSRT.AuraSounds.CustomCategories or {}) do
            if type(category) == "table" and category.key and category.label then
                categories[#categories + 1] = category
            end
        end
    end
    if categoryType == "Raid" then
        table.sort(categories, function(a, b)
            return (NSI.EncounterOrder[a.key] or 9999) < (NSI.EncounterOrder[b.key] or 9999)
        end)
    elseif categoryType == "Custom" then
        table.sort(categories, function(a, b)
            return strlower(a.label) < strlower(b.label)
        end)
    end
    return categories
end

local function FindAuraSoundCategory(categoryType, categoryKey)
    for _, category in ipairs(GetAuraSoundCategories(categoryType)) do
        if category.key == categoryKey then
            return category
        end
    end
end

local function GetAuraSoundEntryInfo(entry)
    local spellID = tonumber(type(entry) == "table" and entry.spellID or entry)
    if not spellID then return end
    local unit = type(entry) == "table" and entry.unit or "player"
    local eventType = type(entry) == "table" and entry.eventType or "applied"
    local entryKey = type(entry) == "table" and entry.key or NSI:GetAuraSoundKey(spellID, unit, eventType)
    local defaultSound = type(entry) == "table" and entry.sound or NSI:GetAuraSoundDefault(spellID)
    return entryKey, spellID, defaultSound, unit, eventType
end

local function PrepareAuraSoundData(screen)
    local data = {}
    local seen = {}
    local category = FindAuraSoundCategory(screen.categoryType, screen.categoryKey)

    if category then
        for _, entry in ipairs(category.entries or {}) do
            local rawSpellID = tonumber(type(entry) == "table" and entry.spellID or entry)
            if rawSpellID then
                local entryKey, spellID, defaultSound, defaultUnit, defaultEventType = GetAuraSoundEntryInfo(entry)
                if entryKey then
                    local saved = NSRT.AuraSounds[entryKey]
                    local unit = type(saved) == "table" and saved.unit or defaultUnit or "player"
                    local eventType = type(saved) == "table" and saved.eventType or defaultEventType or "applied"
                    local useDefaultSounds = screen.categoryType == "Dungeons" and NSRT.AuraSounds.UseDefaultDungeonAuraSounds or NSRT.AuraSounds.UseDefaultRaidAuraSounds
                    local sound = useDefaultSounds and defaultSound or nil
                    if type(saved) == "table" and saved.edited then
                        sound = saved.sound
                    end
                    local spell = C_Spell.GetSpellInfo(spellID)
                    data[#data + 1] = {
                        key = entryKey,
                        spellID = spellID,
                        name = spell and spell.name or ("Spell " .. spellID),
                        unit = unit,
                        eventType = eventType,
                        sound = StripSoundColor(sound),
                        defaultSound = StripSoundColor(defaultSound),
                        isDefault = defaultSound ~= nil,
                        edited = type(saved) == "table" and saved.edited,
                        deleted = type(saved) == "table" and saved.edited and not saved.sound,
                    }
                    seen[entryKey] = true
                end
            end
        end
    end

    for key, info in pairs(NSRT.AuraSounds) do
        if type(info) == "table" then
            local spellID = tonumber(info.spellID)
            local matchesCategory = info.categoryType == screen.categoryType and info.categoryKey == screen.categoryKey
            if spellID and matchesCategory and not seen[key] then
                local spell = C_Spell.GetSpellInfo(spellID)
                data[#data + 1] = {
                    key = key,
                    spellID = spellID,
                    name = spell and spell.name or ("Spell " .. spellID),
                    unit = info.unit or "player",
                    eventType = info.eventType or "applied",
                    sound = StripSoundColor(info.sound),
                    defaultSound = nil,
                    isDefault = false,
                    edited = true,
                    deleted = not info.sound,
                }
            end
        end
    end

    table.sort(data, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    return data
end

local function BuildAuraSoundsUI(parent)
    local screen = CreateFrame("Frame", "$parentAuraSounds", parent, "BackdropTemplate")
    screen:SetAllPoints()
    screen.categoryType = "Raid"
    local firstRaidCategory = GetAuraSoundCategories("Raid")[1]
    screen.categoryKey = firstRaidCategory and firstRaidCategory.key

    local function ResetSpellToDefault(entryKey, spellID, defaultSound, unit, eventType)
        if not spellID then return end
        NSRT.AuraSounds[entryKey] = nil
        local enabled = screen.categoryType == "Dungeons" and NSRT.AuraSounds.UseDefaultDungeonAuraSounds or NSRT.AuraSounds.UseDefaultRaidAuraSounds
        NSI:AddAuraSound(spellID, enabled and defaultSound or nil, entryKey, unit or "player", eventType or "applied")
    end

    local function DeleteAuraSound(entryKey, spellID, defaultSound, unit, eventType)
        if not spellID then return end
        if defaultSound then
            NSI:SaveAuraSound(entryKey, spellID, nil, screen.categoryType, screen.categoryKey, unit or "player", eventType or "applied")
        else
            NSRT.AuraSounds[entryKey] = nil
            NSI:AddAuraSound(spellID, nil, entryKey)
        end
    end

    local function ResetCategory()
        local category = FindAuraSoundCategory(screen.categoryType, screen.categoryKey)
        local categoryDefaults = {}

        if category then
            for _, entry in ipairs(category.entries or {}) do
                local rawSpellID = tonumber(type(entry) == "table" and entry.spellID or entry)
                if rawSpellID then
                    local entryKey, spellID, defaultSound, unit, eventType = GetAuraSoundEntryInfo(entry)
                    if spellID then
                        categoryDefaults[entryKey] = true
                        ResetSpellToDefault(entryKey, spellID, defaultSound, unit, eventType)
                    end
                end
            end
        end

        for key, info in pairs(NSRT.AuraSounds) do
            if type(info) == "table" then
                local spellID = info.spellID
                local uncategorizedCustom = screen.categoryType == "Custom" and screen.categoryKey == "custom"
                    and (not info.categoryType or not info.categoryKey) and not NSI:GetAuraSoundDefault(spellID)
                local matchesCategory = info.categoryType == screen.categoryType and info.categoryKey == screen.categoryKey
                if spellID and (matchesCategory or uncategorizedCustom) and not categoryDefaults[key] then
                    NSRT.AuraSounds[key] = nil
                    NSI:AddAuraSound(spellID, nil, key)
                end
            end
        end

        screen.scrollbox:MasterRefresh()
    end

    local function ResetAllAuraSounds()
        for key, info in pairs(NSRT.AuraSounds) do
            if type(info) == "table" and info.spellID then
                NSRT.AuraSounds[key] = nil
                NSI:AddAuraSound(info.spellID, nil, key)
            end
        end
        NSI:ApplyDefaultAuraSounds(true, false, NSRT.AuraSounds.UseDefaultRaidAuraSounds)
        NSI:ApplyDefaultAuraSounds(true, true, NSRT.AuraSounds.UseDefaultDungeonAuraSounds)
        screen.scrollbox:MasterRefresh()
    end

    local function ConfirmResetAllAuraSounds()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, T("Confirm Resetting ALL Aura Sounds"), "NSRTResetALLAuraSoundsPopup")
        ApplyUIFont(popup.Title, 12)
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup, T("Are you sure you want to reset all Aura Sounds?"), 12, "orange")
        ApplyUIFont(text, 12)
        text:SetPoint("TOP", popup, "TOP", 0, -34)
        text:SetJustifyH("CENTER")
        text:SetWidth(260)

        local confirmButton = DF:CreateButton(popup, function()
            ResetAllAuraSounds()
            popup:Hide()
        end, 100, 30, T("Confirm"))
        ApplyUIFont(confirmButton, 12)
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, T("Cancel"))
        ApplyUIFont(cancelButton, 12)
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end

    local leftWidth = 190
    local rightPanel = CreateFrame("Frame", screen:GetName() .. "Editor", screen)
    rightPanel:SetPoint("TOPLEFT", screen, "TOPLEFT", leftWidth + 36, -8)
    rightPanel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -10, 8)

    local title = CreateLabel(screen, T("Aura Sounds"), 14)
    title:SetTextColor(1, 0.65, 0.1, 1)
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -8)

    local leftScroll = CreateFrame("ScrollFrame", "$parentAuraSoundCategoryScroll", screen, "UIPanelScrollFrameTemplate")
    leftScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -62)
    leftScroll:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 54)
    leftScroll:SetWidth(leftWidth)
    NSI.UI.Components.ReskinScrollbar(leftScroll)
    local leftChild = CreateFrame("Frame", nil, leftScroll, "BackdropTemplate")
    leftChild:SetWidth(leftWidth)
    leftChild:SetHeight(1)
    leftChild:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64})
    leftChild:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
    leftScroll:SetScrollChild(leftChild)

    screen.collapsedSections = {
        RaidSeason1 = true,
        RaidSeason2 = false,
        DungeonsSeason1 = true,
        DungeonsSeason2 = false,
    }

    local categoryRows, sectionRows = {}, {}
    local RefreshCategorySelection
    local defaultSoundsCB, resetCategoryButton
    local newCategoryButton, newSubCategoryButton
    local CreateCustomGroup, CreateCustomCategory
    local ShowCustomGroupMenu, ShowCustomCategoryMenu
    local raidTypeButton, dungeonTypeButton, customTypeButton

    local function CreateCategoryRow()
        local row = CreateFrame("Button", nil, leftChild, "BackdropTemplate")
        row:SetHeight(23)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.4, 0.4, 0.4)
        row.__background:SetAlpha(0.5)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, 13, "")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        return row
    end

    local function CreateSectionRow()
        local row = CreateFrame("Button", nil, leftChild, "BackdropTemplate")
        row:SetHeight(23)
        row:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64})
        row:SetBackdropColor(0.05, 0.30, 0.40, 0.9)
        row.arrow = row:CreateTexture(nil, "OVERLAY")
        row.arrow:SetSize(10, 10)
        row.arrow:SetTexture([[Interface\Buttons\Arrow-Down-Up]])
        row.arrow:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.arrow:SetVertexColor(0, 0.9, 1, 1)
        row.name = row:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(row.name, 12, "")
        row.name:SetPoint("LEFT", row.arrow, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.name:SetTextColor(0.2, 0.85, 1, 1)
        row.name:SetJustifyH("LEFT")
        return row
    end

    local function RefreshCategoryList()
        local categories = GetAuraSoundCategories(screen.categoryType)
        local sections
        if screen.categoryType == "Raid" or screen.categoryType == "Dungeons" then
            local current, previous = {}, {}
            for _, category in ipairs(categories) do
                local isCurrent = screen.categoryType == "Raid" and NSI.CurrentEncounterIDs[category.key]
                    or screen.categoryType == "Dungeons" and NSI.CurrentAuraSoundDungeonKeys[category.key]
                table.insert(isCurrent and current or previous, category)
            end
            sections = {
                {key = screen.categoryType .. "Season2", label = T("Season 2"), categories = current},
                {key = screen.categoryType .. "Season1", label = T("Season 1"), categories = previous},
            }
        elseif screen.categoryType == "Custom" then
            sections = {}
            local ungroupedCategories = {}
            for _, category in ipairs(categories) do
                if not category.groupKey then
                    ungroupedCategories[#ungroupedCategories + 1] = category
                end
            end
            if #ungroupedCategories > 0 then
                sections[#sections + 1] = {
                    key = "CustomUngrouped",
                    label = T("Ungrouped"),
                    categories = ungroupedCategories,
                }
            end
            local groups = {}
            for _, group in ipairs(NSRT.AuraSounds.CustomGroups) do
                groups[#groups + 1] = group
            end
            table.sort(groups, function(a, b)
                return strlower(a.label) < strlower(b.label)
            end)
            for _, group in ipairs(groups) do
                local groupCategories = {}
                for _, category in ipairs(categories) do
                    if category.groupKey == group.key then
                        groupCategories[#groupCategories + 1] = category
                    end
                end
                sections[#sections + 1] = {
                    key = "CustomGroup" .. group.key,
                    label = group.label,
                    categories = groupCategories,
                    group = group,
                }
            end
        else
            sections = {{categories = categories}}
        end

        local categoryIndex, sectionIndex, slot = 0, 0, 0
        for _, section in ipairs(sections) do
            local collapsed = section.key and screen.collapsedSections[section.key]
            if section.key then
                sectionIndex = sectionIndex + 1
                slot = slot + 1
                local sectionRow = sectionRows[sectionIndex] or CreateSectionRow()
                sectionRows[sectionIndex] = sectionRow
                sectionRow:ClearAllPoints()
                sectionRow:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 0, -(slot - 1) * 23)
                sectionRow:SetWidth(leftWidth)
                sectionRow.name:SetText(section.label)
                sectionRow.arrow:SetRotation(collapsed and -math.pi / 2 or 0)
                local sectionKey = section.key
                local group = section.group
                sectionRow:SetScript("OnMouseDown", function(_, button)
                    if button == "RightButton" and group then
                        ShowCustomGroupMenu(group)
                        return
                    end
                    screen.collapsedSections[sectionKey] = not screen.collapsedSections[sectionKey]
                    RefreshCategoryList()
                end)
                sectionRow:Show()
            end

            if not collapsed then
                for _, category in ipairs(section.categories) do
                    categoryIndex = categoryIndex + 1
                    slot = slot + 1
                    local row = categoryRows[categoryIndex] or CreateCategoryRow()
                    categoryRows[categoryIndex] = row
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 0, -(slot - 1) * 23)
                    row:SetWidth(leftWidth)
                    local icon
                    if screen.categoryType == "Raid" and BossData and BossData.BossIcons then
                        icon = BossData.BossIcons[category.key]
                    elseif screen.categoryType == "Dungeons" and NSI.AuraSoundDungeonIcons then
                        icon = NSI.AuraSoundDungeonIcons[category.key]
                    end
                    row.icon:SetTexture(icon)
                    row.icon:SetShown(icon ~= nil)
                    row.name:ClearAllPoints()
                    row.name:SetPoint("LEFT", icon and row.icon or row, icon and "RIGHT" or "LEFT", icon and 4 or 4, 0)
                    row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                    if screen.categoryType == "Raid" then
                        row.name:SetText(NSI:Loc(NSI.BossNames[category.key] or ("Encounter " .. tostring(category.key))))
                    else
                        row.name:SetText(NSI:Loc(category.label or tostring(category.key)))
                    end
                    if screen.categoryKey == category.key then
                        row.__background:SetVertexColor(0, 1, 1)
                        row.__background:SetAlpha(1)
                    else
                        row.__background:SetVertexColor(0.4, 0.4, 0.4)
                        row.__background:SetAlpha(0.5)
                    end
                    row:SetScript("OnMouseDown", function(_, button)
                        if button == "RightButton" and screen.categoryType == "Custom" then
                            ShowCustomCategoryMenu(category)
                            return
                        end
                        screen.categoryKey = category.key
                        RefreshCategorySelection()
                    end)
                    row:Show()
                end
            end
        end
        for index = categoryIndex + 1, #categoryRows do categoryRows[index]:Hide() end
        for index = sectionIndex + 1, #sectionRows do sectionRows[index]:Hide() end
        leftChild:SetHeight(math.max(1, slot * 23))
    end

    local function SelectCategoryType(categoryType)
        screen.categoryType = categoryType
        local first = GetAuraSoundCategories(categoryType)[1]
        screen.categoryKey = first and first.key
        raidTypeButton:Deselect()
        dungeonTypeButton:Deselect()
        customTypeButton:Deselect()
        if categoryType == "Raid" then raidTypeButton:Select()
        elseif categoryType == "Dungeons" then dungeonTypeButton:Select()
        else customTypeButton:Select() end
        RefreshCategorySelection()
    end

    raidTypeButton = CreateLocalizedSubButton(screen, "Raid Bosses", function() SelectCategoryType("Raid") end,
        100, "NSRTAuraSoundRaidType")
    raidTypeButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    dungeonTypeButton = CreateLocalizedSubButton(screen, "Dungeons", function() SelectCategoryType("Dungeons") end,
        84, "NSRTAuraSoundDungeonType")
    dungeonTypeButton:SetPoint("LEFT", raidTypeButton.frame, "RIGHT", 4, 0)
    customTypeButton = CreateLocalizedSubButton(screen, "Custom", function() SelectCategoryType("Custom") end,
        70, "NSRTAuraSoundCustomType")
    customTypeButton:SetPoint("LEFT", dungeonTypeButton.frame, "RIGHT", 4, 0)

    RefreshCategorySelection = function()
        RefreshCategoryList()
        if screen.scrollbox then screen.scrollbox:MasterRefresh() end
        if screen.RefreshCategoryControls then screen:RefreshCategoryControls() end
    end

    local function ShowCategoryEditor(title, initialName, onConfirm, fieldLabel)
        local popup = DF:CreateSimplePanel(UIParent, 300, 135, title)
        ApplyUIFont(popup.Title, 12)
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local nameLabel = DF:CreateLabel(popup, fieldLabel or T("Sub-Category Name"), 11)
        ApplyUIFont(nameLabel, 11)
        nameLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, -35)

        local nameEntry = DF:CreateTextEntry(popup, function() end, 260, 22)
        nameEntry:SetPoint("TOPLEFT", GetUIObject(nameLabel), "BOTTOMLEFT", 0, -5)
        nameEntry:SetTemplate(options_dropdown_template)
        nameEntry:SetText(initialName or "")
        nameEntry:SetFocus()
        nameEntry:HighlightText()

        local confirmButton = DF:CreateButton(popup, function()
            local name = strtrim(nameEntry:GetText() or "")
            if name ~= "" then
                onConfirm(name)
                popup:Hide()
            end
        end, 100, 24, T("Confirm"))
        ApplyUIFont(confirmButton, 11)
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(options_button_template)

        local cancelButton = DF:CreateButton(popup, function() popup:Hide() end, 100, 24, T("Cancel"))
        ApplyUIFont(cancelButton, 11)
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(options_button_template)
        popup:Show()
    end

    CreateCustomGroup = function(onCreated)
        ShowCategoryEditor(T("Create Group"), nil, function(name)
            for _, group in ipairs(NSRT.AuraSounds.CustomGroups) do
                if strlower(group.label) == strlower(name) then
                    return
                end
            end
            local nextID = tonumber(NSRT.AuraSounds.NextCustomGroupID) or 1
            local group = {key = "group_" .. nextID, label = name}
            NSRT.AuraSounds.NextCustomGroupID = nextID + 1
            NSRT.AuraSounds.CustomGroups[#NSRT.AuraSounds.CustomGroups + 1] = group
            if onCreated then onCreated(group) else RefreshCategorySelection() end
        end, T("Group Name"))
    end

    CreateCustomCategory = function(group)
        ShowCategoryEditor(T("Create Sub-Category"), nil, function(name)
            for _, category in ipairs(GetAuraSoundCategories("Custom")) do
                if strlower(category.label) == strlower(name) then
                    return
                end
            end
            local nextID = tonumber(NSRT.AuraSounds.NextCustomCategoryID) or 1
            local category = {key = "custom_" .. nextID, label = name, groupKey = group and group.key, entries = {}}
            NSRT.AuraSounds.NextCustomCategoryID = nextID + 1
            NSRT.AuraSounds.CustomCategories[#NSRT.AuraSounds.CustomCategories + 1] = category
            screen.categoryKey = category.key
            RefreshCategorySelection()
        end)
    end

    newCategoryButton = CreateLocalizedButton(screen, "New Group", function() CreateCustomGroup() end,
        175, 20, "NSRTAuraSoundNewGroup")
    newCategoryButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 30)
    newSubCategoryButton = CreateLocalizedButton(screen, "New Sub-Category", function() CreateCustomCategory() end,
        175, 20, "NSRTAuraSoundNewSubCategory")
    newSubCategoryButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 6)

    local function DeleteCustomCategory(category)
        for index, customCategory in ipairs(NSRT.AuraSounds.CustomCategories) do
            if customCategory.key == category.key then
                table.remove(NSRT.AuraSounds.CustomCategories, index)
                break
            end
        end
        for key, info in pairs(NSRT.AuraSounds) do
            if type(info) == "table" and info.categoryType == "Custom" and info.categoryKey == category.key then
                NSRT.AuraSounds[key] = nil
                NSI:AddAuraSound(info.spellID, nil, key)
            end
        end
    end

    ShowCustomGroupMenu = function(group)
        ShowContextMenu({
            {type = "button", label = T("New Sub-Category"), fnc = function() CreateCustomCategory(group) end},
            {type = "button", label = T("Rename"), fnc = function()
                ShowCategoryEditor(T("Rename"), group.label, function(name)
                    group.label = name
                    RefreshCategorySelection()
                end, T("Group Name"))
            end},
            {type = "button", label = T("Delete"), fnc = function()
                -- A group owns its nested categories and their custom sound entries.
                for index = #NSRT.AuraSounds.CustomCategories, 1, -1 do
                    local category = NSRT.AuraSounds.CustomCategories[index]
                    if category.groupKey == group.key then DeleteCustomCategory(category) end
                end
                for index, customGroup in ipairs(NSRT.AuraSounds.CustomGroups) do
                    if customGroup.key == group.key then
                        table.remove(NSRT.AuraSounds.CustomGroups, index)
                        break
                    end
                end
                screen.categoryKey = nil
                RefreshCategorySelection()
            end},
        })
    end

    ShowCustomCategoryMenu = function(category)
        local groups = {}
        for _, group in ipairs(NSRT.AuraSounds.CustomGroups) do
            groups[#groups + 1] = group
        end
        table.sort(groups, function(a, b)
            return strlower(a.label) < strlower(b.label)
        end)
        local groupMenuItems = {}
        for _, group in ipairs(groups) do
            groupMenuItems[#groupMenuItems + 1] = {type = "button", label = group.label, fnc = function()
                category.groupKey = group.key
                RefreshCategorySelection()
            end}
        end
        groupMenuItems[#groupMenuItems + 1] = {type = "separator"}
        groupMenuItems[#groupMenuItems + 1] = {type = "button", label = T("New Group"), fnc = function()
            CreateCustomGroup(function(group)
                category.groupKey = group.key
                RefreshCategorySelection()
            end)
        end}
        ShowContextMenu({
            {type = "submenu", label = T("Add to Group"), items = groupMenuItems},
            {
                type = "button",
                label = T("Rename"),
                fnc = function()
                    ShowCategoryEditor(T("Rename Sub-Category"), category.label, function(name)
                        category.label = name
                        RefreshCategorySelection()
                    end)
                end,
            },
            {
                type = "button",
                label = T("Delete"),
                fnc = function()
                    DeleteCustomCategory(category)
                    screen.categoryKey = nil
                    RefreshCategorySelection()
                end,
            },
        })
    end

    function screen:RefreshCategoryControls()
        local isCustom = self.categoryType == "Custom"
        newCategoryButton.frame:SetShown(isCustom)
        newSubCategoryButton.frame:SetShown(isCustom)
        defaultSoundsCB.frame:SetShown(not isCustom)
        if self.categoryType == "Raid" then
            defaultSoundsCB.label:SetText(T("Use Default Raid Aura Sounds"))
            defaultSoundsCB:SetValue(NSRT.AuraSounds.UseDefaultRaidAuraSounds)
        elseif self.categoryType == "Dungeons" then
            defaultSoundsCB.label:SetText(T("Use Default Dungeon Aura Sounds"))
            defaultSoundsCB:SetValue(NSRT.AuraSounds.UseDefaultDungeonAuraSounds)
        end
        if resetCategoryButton then
            resetCategoryButton:SetText(T(self.categoryType == "Dungeons" and "Reset This Dungeon" or "Reset This Boss"))
            GetUIObject(resetCategoryButton):SetShown(self.categoryType ~= "Custom")
        end
    end

    defaultSoundsCB = CreateCheckButton(screen, T("Use Default Raid Aura Sounds"), function()
        if screen.categoryType == "Dungeons" then
            return NSRT.AuraSounds.UseDefaultDungeonAuraSounds
        end
        return NSRT.AuraSounds.UseDefaultRaidAuraSounds
    end, function(_, value)
        if screen.categoryType == "Dungeons" then
            NSRT.AuraSounds.UseDefaultDungeonAuraSounds = value
            NSI:ApplyDefaultAuraSounds(true, true, value)
        else
            NSRT.AuraSounds.UseDefaultRaidAuraSounds = value
            NSI:ApplyDefaultAuraSounds(true, false, value)
        end
        if screen.scrollbox then
            screen.scrollbox:MasterRefresh()
        end
    end, 250, 18, "$parentDefaultSounds", {
        title = T("Use Default Dungeon Aura Sounds"),
        desc = T("This applies sounds to all dungeon auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spell IDs yourself previously this option will NOT overwrite that."),
    })
    defaultSoundsCB:SetPoint("LEFT", customTypeButton.frame, "RIGHT", 14, 0)
    NSI:SetUIFont(defaultSoundsCB.label, 11, "")

    resetCategoryButton = DF:CreateButton(rightPanel, ResetCategory, 115, 20, T("Reset This Boss"))
    ApplyUIFont(resetCategoryButton, 11)
    resetCategoryButton:SetPoint("LEFT", defaultSoundsCB.frame, "RIGHT", 18, 0)
    resetCategoryButton:SetTemplate(options_button_template)

    local resetAllButton = DF:CreateButton(rightPanel, ConfirmResetAllAuraSounds, 110, 20, T("Reset All Sounds"))
    ApplyUIFont(resetAllButton, 11)
    resetAllButton:SetPoint("LEFT", GetUIObject(resetCategoryButton), "RIGHT", 8, 0)
    resetAllButton:SetTemplate(options_button_template)

    local soundChannelLabel = DF:CreateLabel(rightPanel, T("Sound Channel"), 11)
    ApplyUIFont(soundChannelLabel, 11)
    soundChannelLabel:SetPoint("LEFT", GetUIObject(resetAllButton), "RIGHT", 18, 0)

    local soundChannelDropdown = DF:CreateDropDown(rightPanel, BuildAuraSoundChannelDropdown, nil, 105, 20, nil, "$parentSoundChannelDropdown", options_dropdown_template)
    soundChannelDropdown:SetPoint("LEFT", GetUIObject(soundChannelLabel), "RIGHT", 8, 0)
    soundChannelDropdown:Select(T(NSRT.AuraSounds.SoundChannel or "Master"))

    local scrollLines = 18

    local function ClearLine(line)
        if not line then return end
        line.entryKey = nil
        line.spellID = nil
        line.defaultSound = nil
        line.isDefault = nil
        line.eventType = nil
        line.isActive = false
        if line.name then line.name.text = "" end
        if line.spellIDText then line.spellIDText.text = "" end
        if line.defaultText then line.defaultText.text = "" end
        if line.icon then line.icon:SetTexture(nil) end
        line:Hide()
    end

    local function refresh(scrollbox, data, offset)
        for _, line in ipairs(scrollbox.Frames or {}) do
            ClearLine(line)
        end
        for i = 1, scrollLines do
            local index = i + offset
            local rowData = data[index]
            if rowData then
                local line = scrollbox:GetLine(i)
                line:Show()
                line.isActive = true
                line.entryKey = rowData.key
                line.spellID = rowData.spellID
                line.defaultSound = rowData.defaultSound
                line.isDefault = rowData.isDefault
                line.unit = rowData.unit or "player"
                line.eventType = rowData.eventType or "applied"
                line.name.text = rowData.name
                line.spellIDText.text = rowData.spellID
                line.defaultText.text = rowData.deleted and T("Deleted") or (rowData.edited and T("Edited") or T("Default"))
                line.unitEntry:SetText(line.unit)
                line.eventDropdown:Select(GetAuraSoundEventLabel(line.eventType))
                if rowData.isDefault then
                    line.unitEntry:Disable()
                    line.eventDropdown:Disable()
                else
                    line.unitEntry:Enable()
                    line.eventDropdown:Enable()
                end
                line.icon:SetTexture(C_Spell.GetSpellTexture(rowData.spellID) or 134400)
                line.sound = rowData.sound
                line.soundDropdown:Select(rowData.deleted and "__NONE__" or (rowData.sound or "__NONE__"))
                GetUIObject(line.resetButton):SetShown(rowData.isDefault and rowData.edited)
            end
        end
    end

    local function createLine(scrollbox, index)
        local line = CreateFrame("Frame", "$parentAuraSoundLine" .. index, scrollbox, "BackdropTemplate")
        line:SetPoint("TOPLEFT", GetUIObject(scrollbox), "TOPLEFT", 1, -((index - 1) * scrollbox.LineHeight - 1))
        line:SetSize(scrollbox:GetWidth() - 2, scrollbox.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.icon = DF:CreateTexture(line, 134400, 18, 18)
        line.icon:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.icon:SetScript("OnEnter", function(self)
            local spellID = self:GetParent().spellID
            ShowAuraSoundSpellTooltip(self, spellID)
        end)
        line.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

        line.name = DF:CreateLabel(line, "")
        ApplyUIFont(line.name, 11)
        line.name:SetPoint("LEFT", GetUIObject(line.icon), "RIGHT", 5, 0)
        line.name:SetWidth(175)

        line.spellIDText = DF:CreateLabel(line, "")
        ApplyUIFont(line.spellIDText, 11)
        line.spellIDText:SetPoint("LEFT", GetUIObject(line.name), "RIGHT", -2, 0)
        line.spellIDText:SetWidth(58)

        line.defaultText = DF:CreateLabel(line, "")
        ApplyUIFont(line.defaultText, 11)
        line.defaultText:SetPoint("LEFT", GetUIObject(line.spellIDText), "RIGHT", 5, 0)
        line.defaultText:SetWidth(50)

        line.unitEntry = DF:CreateTextEntry(line, function(_, _, value)
            if not line.isActive or not line.entryKey or not line.spellID then return end
            if line.isDefault then
                line.unitEntry:SetText(line.unit or "player")
                return
            end
            line.unit = value ~= "" and value or "player"
            local sound = line.soundDropdown:GetValue()
            sound = sound ~= "__NONE__" and sound or nil
            NSI:SaveAuraSound(line.entryKey, line.spellID, sound, screen.categoryType, screen.categoryKey, line.unit, line.eventType)
            scrollbox:MasterRefresh()
        end, 60, 20)
        line.unitEntry:SetTemplate(options_dropdown_template)
        line.unitEntry:SetPoint("LEFT", GetUIObject(line.defaultText), "RIGHT", 5, 0)

        line.eventDropdown = DF:CreateDropDown(line, BuildAuraSoundEventDropdown, nil, 92, 20, nil, "$parentEventDropdown", options_dropdown_template)
        line.eventDropdown:SetPoint("LEFT", GetUIObject(line.unitEntry), "RIGHT", -1, 0)
        line.eventDropdown:SetHook("OnOptionSelected", function(_, _, value)
            if not line.isActive or not line.entryKey or not line.spellID then return end
            if line.isDefault then
                line.eventDropdown:Select(GetAuraSoundEventLabel(line.eventType))
                return
            end
            line.eventType = value or "applied"
            local sound = line.soundDropdown:GetValue()
            sound = sound ~= "__NONE__" and sound or nil
            NSI:SaveAuraSound(line.entryKey, line.spellID, sound, screen.categoryType, screen.categoryKey, line.unit, line.eventType)
            scrollbox:MasterRefresh()
        end)

        line.soundDropdown = DF:CreateDropDown(line, BuildAuraSoundDropdown, nil, 130, 20, nil, "$parentSoundDropdown", options_dropdown_template)
        line.soundDropdown:SetPoint("LEFT", GetUIObject(line.eventDropdown), "RIGHT", -1, 0)
        line.soundDropdown:SetHook("OnOptionSelected", function(_, _, value)
            if not line.isActive or not line.entryKey or not line.spellID then return end
            local sound = value ~= "__NONE__" and value or nil
            NSI:SaveAuraSound(line.entryKey, line.spellID, sound, screen.categoryType, screen.categoryKey, line.unit, line.eventType)
            scrollbox:MasterRefresh()
        end)

        line.resetButton = DF:CreateButton(line, function()
            if not line.isActive or not line.entryKey or not line.spellID then return end
            ResetSpellToDefault(line.entryKey, line.spellID, line.defaultSound, line.unit, line.eventType)
            scrollbox:MasterRefresh()
        end, 48, 18, T("Reset"))
        ApplyUIFont(line.resetButton, 11)
        line.resetButton:SetPoint("RIGHT", line, "RIGHT", -62, 0)
        line.resetButton:SetTemplate(options_button_template)

        line.deleteButton = DF:CreateButton(line, function()
            if not line.isActive or not line.entryKey or not line.spellID then return end
            DeleteAuraSound(line.entryKey, line.spellID, line.defaultSound, line.unit, line.eventType)
            scrollbox:MasterRefresh()
        end, 52, 18, T("Delete"))
        ApplyUIFont(line.deleteButton, 11)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)
        line.deleteButton:SetTemplate(options_button_template)

        return line
    end

    local columnHeaders = CreateFrame("Frame", nil, rightPanel)
    columnHeaders:SetSize(760, 18)
    columnHeaders:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -56)
    local function AddColumnHeader(text, x, width)
        local header = CreateLabel(columnHeaders, T(text), 10)
        header:SetPoint("LEFT", columnHeaders, "LEFT", x, 0)
        header:SetWidth(width)
        header:SetTextColor(1, 0.65, 0.1, 1)
        return header
    end
    AddColumnHeader("Spell Name", 28, 175)
    AddColumnHeader("SpellID", 201, 58)
    AddColumnHeader("Edit State", 264, 50)
    AddColumnHeader("UnitID", 321, 60)
    AddColumnHeader("Event Type", 380, 92)
    AddColumnHeader("Sound", 470, 130)

    local scrollbox = DF:CreateScrollBox(rightPanel, "$parentAuraSoundScrollBox", refresh, {}, 760, 340, scrollLines, 20, createLine)
    screen.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -76)
    DF:ReskinSlider(scrollbox)
    scrollbox.MasterRefresh = function(self)
        self:SetData(PrepareAuraSoundData(screen))
        self:Refresh()
    end
    for i = 1, scrollLines do
        ClearLine(scrollbox:CreateLine(createLine))
    end

    local newSpellLabel = DF:CreateLabel(rightPanel, T("SpellID:"), 11)
    ApplyUIFont(newSpellLabel, 11)
    newSpellLabel:SetPoint("TOPLEFT", GetUIObject(scrollbox), "BOTTOMLEFT", 0, -18)

    local newSpellEntry = DF:CreateTextEntry(rightPanel, function() end, 90, 20)
    newSpellEntry:SetPoint("LEFT", GetUIObject(newSpellLabel), "RIGHT", 8, 0)
    newSpellEntry:SetTemplate(options_dropdown_template)

    local newSoundLabel = DF:CreateLabel(rightPanel, T("Sound:"), 11)
    ApplyUIFont(newSoundLabel, 11)
    newSoundLabel:SetPoint("LEFT", GetUIObject(newSpellEntry), "RIGHT", 12, 0)

    local newSoundDropdown = DF:CreateDropDown(rightPanel, BuildAuraSoundDropdown, nil, 135, 20, nil, "$parentNewSoundDropdown", options_dropdown_template)
    newSoundDropdown:SetPoint("LEFT", GetUIObject(newSoundLabel), "RIGHT", 8, 0)

    local newUnitLabel = DF:CreateLabel(rightPanel, T("Unit"), 11)
    ApplyUIFont(newUnitLabel, 11)
    newUnitLabel:SetPoint("LEFT", GetUIObject(newSoundDropdown), "RIGHT", 12, 0)

    local newUnitEntry = DF:CreateTextEntry(rightPanel, function() end, 65, 20)
    newUnitEntry:SetPoint("LEFT", GetUIObject(newUnitLabel), "RIGHT", 8, 0)
    newUnitEntry:SetTemplate(options_dropdown_template)
    newUnitEntry:SetText("player")

    local newEventLabel = DF:CreateLabel(rightPanel, T("Event"), 11)
    ApplyUIFont(newEventLabel, 11)
    newEventLabel:SetPoint("LEFT", GetUIObject(newUnitEntry), "RIGHT", 12, 0)

    local newEventDropdown = DF:CreateDropDown(rightPanel, BuildAuraSoundEventDropdown, nil, 92, 20, nil, "$parentNewEventDropdown", options_dropdown_template)
    newEventDropdown:SetPoint("LEFT", GetUIObject(newEventLabel), "RIGHT", 8, 0)
    newEventDropdown:Select(GetAuraSoundEventLabel("applied"))

    local addButton = DF:CreateButton(rightPanel, function()
        if screen.categoryType == "Custom" and not screen.categoryKey then return end
        local spellID = tonumber(newSpellEntry:GetText())
        local value = newSoundDropdown:GetValue()
        local sound = value ~= "__NONE__" and value or nil
        local unit = newUnitEntry:GetText()
        unit = unit ~= "" and unit or "player"
        local eventType = newEventDropdown:GetValue() or "applied"
        if not spellID or not sound then return end
        local entryKey = NSI:GetNextAuraSoundKey(spellID, unit, eventType)
        NSI:SaveAuraSound(entryKey, spellID, sound, screen.categoryType, screen.categoryKey, unit, eventType)
        scrollbox:MasterRefresh()
        newSpellEntry:SetText("")
        newUnitEntry:SetText("player")
        newEventDropdown:Select(GetAuraSoundEventLabel("applied"))
    end, 70, 20, T("Add"))
    ApplyUIFont(addButton, 11)
    addButton:SetPoint("LEFT", GetUIObject(newEventDropdown), "RIGHT", 10, 0)
    addButton:SetTemplate(options_button_template)

    SelectCategoryType("Raid")
    return screen
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.AuraSounds = {
    BuildAuraSoundsUI = BuildAuraSoundsUI,
}
