local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local DF = _G["DetailsFramework"]

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

local soundlist = NSI:GetOrderedSoundList()

local function StripSoundColor(sound)
    if type(sound) ~= "string" then return sound end
    return sound:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function GetSoundDisplayLabel(sound)
    if not sound then return T("None") end
    for _, s in ipairs(soundlist) do
        if StripSoundColor(s) == sound then return s end
    end
    return sound
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

    C_Spell.RequestLoadSpellData(spellID)

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

local auraSoundsExportPopup
local auraSoundsImportPopup

local function ShowAuraSoundsExportPopup(text, label)
    if not auraSoundsExportPopup then
        auraSoundsExportPopup = DF:CreateSimplePanel(UIParent, 800, 400, "|cFF00FFFF" .. T("Export Aura Sounds") .. "|r",
            "NSRTAuraSoundsExportPopup", { UseScaleBar = false })
        auraSoundsExportPopup:SetPoint("CENTER", UIParent, "CENTER")
        auraSoundsExportPopup:SetFrameLevel(100)

        auraSoundsExportPopup.infoLabel = CreateLabel(auraSoundsExportPopup, "", 13)
        auraSoundsExportPopup.infoLabel:SetTextColor(0.8, 0.8, 0.8, 1)
        auraSoundsExportPopup.infoLabel:SetPoint("TOPLEFT", auraSoundsExportPopup, "TOPLEFT", 10, -30)
        auraSoundsExportPopup.textbox = DF:NewSpecialLuaEditorEntry(auraSoundsExportPopup, 280, 80, nil,
            "NSRTAuraSoundsExportTextBox", true, false, true)
        auraSoundsExportPopup.textbox:SetPoint("TOPLEFT", auraSoundsExportPopup, "TOPLEFT", 10, -50)
        auraSoundsExportPopup.textbox:SetPoint("BOTTOMRIGHT", auraSoundsExportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(auraSoundsExportPopup.textbox)
        DF:ReskinSlider(auraSoundsExportPopup.textbox.scroll)
        auraSoundsExportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        NSI:SetUIFont(auraSoundsExportPopup.textbox.editbox, 13, "OUTLINE")

        local doneButton = CreateLocalizedButton(auraSoundsExportPopup, "Done", function() auraSoundsExportPopup:Hide() end, 280, 20)
        doneButton:SetPoint("BOTTOM", auraSoundsExportPopup, "BOTTOM", 0, 10)
    end
    auraSoundsExportPopup.infoLabel:SetText(label or "")
    auraSoundsExportPopup.textbox:SetText(text or "")
    auraSoundsExportPopup:Show()
    auraSoundsExportPopup.textbox:SetFocus()
end

local function ShowAuraSoundsImportPopup(onImport)
    if not auraSoundsImportPopup then
        auraSoundsImportPopup = DF:CreateSimplePanel(UIParent, 800, 400, "|cFF00FFFF" .. T("Import Aura Sounds") .. "|r",
            "NSRTAuraSoundsImportPopup", { UseScaleBar = false })
        auraSoundsImportPopup:SetPoint("CENTER", UIParent, "CENTER")
        auraSoundsImportPopup:SetFrameLevel(100)

        auraSoundsImportPopup.statusLabel = CreateLabel(auraSoundsImportPopup, T("Paste an Aura Sounds export string below and click Import."), 13)
        auraSoundsImportPopup.statusLabel:SetTextColor(0.8, 0.8, 0.8, 1)
        auraSoundsImportPopup.statusLabel:SetPoint("TOPLEFT", auraSoundsImportPopup, "TOPLEFT", 10, -30)
        auraSoundsImportPopup.textbox = DF:NewSpecialLuaEditorEntry(auraSoundsImportPopup, 280, 80, nil,
            "NSRTAuraSoundsImportTextBox", true, false, true)
        auraSoundsImportPopup.textbox:SetPoint("TOPLEFT", auraSoundsImportPopup, "TOPLEFT", 10, -50)
        auraSoundsImportPopup.textbox:SetPoint("BOTTOMRIGHT", auraSoundsImportPopup, "BOTTOMRIGHT", -25, 40)
        DF:ApplyStandardBackdrop(auraSoundsImportPopup.textbox)
        DF:ReskinSlider(auraSoundsImportPopup.textbox.scroll)
        auraSoundsImportPopup.textbox:SetScript("OnMouseDown", function(self) self:SetFocus() end)
        NSI:SetUIFont(auraSoundsImportPopup.textbox.editbox, 13, "OUTLINE")

        local importButton = CreateLocalizedButton(auraSoundsImportPopup, "Import", function()
            local success, count = NSI:ImportAuraSoundString(auraSoundsImportPopup.textbox:GetText())
            if success then
                auraSoundsImportPopup:Hide()
                print("|cFF00FFFFNSRT:|r " .. string.format(T("Imported %d Aura Sound(s)."), count or 0))
                if auraSoundsImportPopup.onImport then auraSoundsImportPopup.onImport() end
            else
                auraSoundsImportPopup.statusLabel:SetText("|cFFFF0000" .. T("Invalid Aura Sounds import string.") .. "|r")
            end
        end, 280, 20)
        importButton:SetPoint("BOTTOM", auraSoundsImportPopup, "BOTTOM", 0, 10)
    end
    auraSoundsImportPopup.onImport = onImport
    auraSoundsImportPopup.statusLabel:SetText(T("Paste an Aura Sounds export string below and click Import."))
    auraSoundsImportPopup.textbox:SetText("")
    auraSoundsImportPopup:Show()
    auraSoundsImportPopup.textbox:SetFocus()
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

    local title = CreateLabel(screen, T("|cFF00FFFFAura|r Sounds"), 14)
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -8)

    local leftScroll = CreateFrame("ScrollFrame", "$parentAuraSoundCategoryScroll", screen, "UIPanelScrollFrameTemplate")
    leftScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -62)
    leftScroll:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 78)
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

    local function ExportCategories(categoryType, categories, label, group)
        local keys = {}
        for _, category in ipairs(categories or {}) do
            keys[#keys + 1] = category.key
        end
        local text = NSI:ExportAuraSoundCategories(categoryType, keys, group)
        if text then ShowAuraSoundsExportPopup(text, label) end
    end

    local function CreateCategoryRow()
        local row = CreateFrame("Button", nil, leftChild, "BackdropTemplate")
        row:SetHeight(23)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.4, 0.4, 0.4)
        row.__background:SetAlpha(0.5)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
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
                    if button == "RightButton" then
                        if group then
                            ShowCustomGroupMenu(group)
                        else
                            ShowContextMenu({
                                {type = "button", label = T("Export Group"), fnc = function()
                                    ExportCategories(screen.categoryType, section.categories, section.label)
                                end},
                            })
                        end
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
                        if button == "RightButton" then
                            if screen.categoryType == "Custom" then
                                ShowCustomCategoryMenu(category)
                            else
                                ShowContextMenu({
                                    {type = "button", label = T("Export"), fnc = function()
                                        ExportCategories(screen.categoryType, {category}, row.name:GetText())
                                    end},
                                })
                            end
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

    local function AddTypeExport(button, categoryType, label)
        button.frame:RegisterForClicks("LeftButtonUp")
        button.frame:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "RightButton" then
                ExportCategories(categoryType, GetAuraSoundCategories(categoryType), T(label))
            end
        end)
    end
    AddTypeExport(raidTypeButton, "Raid", "Raid Bosses")
    AddTypeExport(dungeonTypeButton, "Dungeons", "Dungeons")
    AddTypeExport(customTypeButton, "Custom", "Custom")

    RefreshCategorySelection = function()
        RefreshCategoryList()
        if screen.scrollbox then screen.scrollbox:MasterRefresh() end
        if screen.RefreshCategoryControls then screen:RefreshCategoryControls() end
    end

    local function ShowCategoryEditor(title, initialName, onConfirm, fieldLabel)
        local POPUP_W, POPUP_H, TITLE_H = 300, 150, 30

        local popup = NSI.UI.Components.CreateFrame(UIParent, POPUP_W, POPUP_H)
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local titleFS = CreateLabel(popup, title, 13)
        titleFS:SetTextColor(1, 0.82, 0, 1)
        titleFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -10)
        titleFS:SetPoint("RIGHT", popup, "RIGHT", -24, 0)

        local titleSep = popup:CreateTexture(nil, "ARTWORK")
        titleSep:SetColorTexture(0, 1, 1, 0.20)
        titleSep:SetHeight(1)
        titleSep:SetPoint("TOPLEFT", popup, "TOPLEFT", 1, -TITLE_H)
        titleSep:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -1, -TITLE_H)

        local nameLabel = CreateLabel(popup, fieldLabel or T("Sub-Category Name"), 11)
        nameLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -(TITLE_H + 12))

        local nameEntry = NSI.UI.Components.CreateTextEntry(popup, nil, function()
            return initialName or ""
        end, nil, 268, 22)
        nameEntry:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -6)
        nameEntry.editBox:HighlightText()
        nameEntry.editBox:SetFocus()

        local function Confirm()
            local name = strtrim(nameEntry:GetValue() or "")
            if name ~= "" then
                onConfirm(name)
                popup:Hide()
            end
        end

        nameEntry.editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            Confirm()
        end)
        nameEntry.editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            popup:Hide()
        end)

        local confirmButton = NSI.UI.Components.CreateButton(popup, T("Confirm"), Confirm, 100, 24, nil, nil, 11)
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 6, 12)

        local cancelButton = NSI.UI.Components.CreateButton(popup, T("Cancel"), function() popup:Hide() end, 100, 24, nil, nil, 11)
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -6, 12)

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
    newCategoryButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 54)
    newSubCategoryButton = CreateLocalizedButton(screen, "New Sub-Category", function() CreateCustomCategory() end,
        175, 20, "NSRTAuraSoundNewSubCategory")
    newSubCategoryButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 30)
    local importButton = CreateLocalizedButton(screen, "Import", function()
        ShowAuraSoundsImportPopup(function() RefreshCategorySelection() end)
    end, 175, 20, "NSRTAuraSoundImport")
    importButton:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", 10, 6)

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
            {type = "button", label = T("Export Group"), fnc = function()
                local categories = {}
                for _, category in ipairs(GetAuraSoundCategories("Custom")) do
                    if category.groupKey == group.key then categories[#categories + 1] = category end
                end
                ExportCategories("Custom", categories, group.label, group)
            end},
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
            {type = "button", label = T("Export"), fnc = function()
                ExportCategories("Custom", {category}, category.label)
            end},
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

    local defaultSoundsTooltip = {
        title = T("Use Reloe Aura Sounds"),
        desc = T("This applies my selected aura sounds to the selected category. You can still edit them later. If you made changes, added or deleted one of these spell IDs yourself previously this option will NOT overwrite that."),
    }

    function screen:RefreshCategoryControls()
        local isCustom = self.categoryType == "Custom"
        newCategoryButton.frame:SetShown(isCustom)
        newSubCategoryButton.frame:SetShown(isCustom)
        defaultSoundsCB.frame:SetShown(not isCustom)
        if self.categoryType == "Raid" then
            defaultSoundsTooltip.desc = T("This applies my selected aura sounds to all raid auras. You can still edit them later. If you made changes, added or deleted one of these spell IDs yourself previously this option will NOT overwrite that.")
            defaultSoundsCB:SetValue(NSRT.AuraSounds.UseDefaultRaidAuraSounds)
        elseif self.categoryType == "Dungeons" then
            defaultSoundsTooltip.desc = T("This applies my selected aura sounds to all dungeon auras. You can still edit them later. If you made changes, added or deleted one of these spell IDs yourself previously this option will NOT overwrite that.")
            defaultSoundsCB:SetValue(NSRT.AuraSounds.UseDefaultDungeonAuraSounds)
        end
        if resetCategoryButton then
            resetCategoryButton:SetText(T(self.categoryType == "Dungeons" and "Reset This Dungeon" or "Reset This Boss"))
            resetCategoryButton.frame:SetShown(self.categoryType ~= "Custom")
        end
    end

    defaultSoundsCB = CreateCheckButton(screen, T("Use Reloe Aura Sounds"), function()
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
    end, 250, 18, "$parentDefaultSounds", defaultSoundsTooltip)
    defaultSoundsCB:SetPoint("LEFT", customTypeButton.frame, "RIGHT", 14, 0)
    NSI:SetUIFont(defaultSoundsCB.label, 11, "")

    resetCategoryButton = NSI.UI.Components.CreateButton(rightPanel, T("Reset This Boss"), ResetCategory, 115, 20, nil, nil, 11)
    resetCategoryButton:SetPoint("LEFT", defaultSoundsCB.frame, "RIGHT", 18, 0)

    local resetAllButton = NSI.UI.Components.CreateButton(rightPanel, T("Reset All Sounds"), ConfirmResetAllAuraSounds, 110, 20, nil, nil, 11)
    resetAllButton:SetPoint("LEFT", resetCategoryButton.frame, "RIGHT", 8, 0)

    local soundChannelLabel = CreateLabel(rightPanel, T("Sound Channel"), 11)
    soundChannelLabel:SetPoint("LEFT", resetAllButton.frame, "RIGHT", 18, 0)

    local soundChannelDropdown = NSI.UI.Components.CreateDropdown(rightPanel, nil, BuildAuraSoundChannelDropdown, function()
        return T(NSRT.AuraSounds.SoundChannel or "Master")
    end, 105, 20)
    soundChannelDropdown:SetPoint("LEFT", soundChannelLabel, "RIGHT", 8, 0)

    local columnHeaders = CreateFrame("Frame", nil, rightPanel)
    columnHeaders:SetSize(760, 18)
    columnHeaders:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -56)
    local function AddColumnHeader(text, x, width)
        local header = CreateLabel(columnHeaders, T(text), 10)
        header:SetPoint("LEFT", columnHeaders, "LEFT", x, 0)
        header:SetWidth(width)
        header:SetTextColor(0, 1, 1, 1)
        return header
    end
    AddColumnHeader("Spell Name", 28, 175)
    AddColumnHeader("SpellID", 201, 58)
    AddColumnHeader("Edit State", 264, 50)
    AddColumnHeader("UnitID", 321, 60)
    AddColumnHeader("Event Type", 380, 92)
    AddColumnHeader("Sound", 470, 130)

    local ROW_HEIGHT = 20
    local auraRows = {}

    local scrollbox = NSI.UI.Components.CreateScrollBox(rightPanel, 760, 340)
    screen.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -76)

    local RefreshAuraScrollbox

    local function CreateAuraRow(index)
        local rowWidth = scrollbox.scrollChild:GetWidth()
        local row = CreateFrame("Frame", nil, scrollbox.scrollChild, "BackdropTemplate")
        row:SetSize(rowWidth, ROW_HEIGHT)
        row:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
        row:SetBackdropColor(unpack(NSI.UI.Components.STYLE.bg_color))

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.icon:SetTexCoord(0.025, 0.975, 0.025, 0.975)
        row.icon:SetScript("OnEnter", function(self)
            ShowAuraSoundSpellTooltip(self, row.entry and row.entry.spellID)
        end)
        row.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.name = CreateLabel(row, "", 11)
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
        row.name:SetWidth(175)

        row.spellIDText = CreateLabel(row, "", 11)
        row.spellIDText:SetPoint("LEFT", row.name, "RIGHT", -2, 0)
        row.spellIDText:SetWidth(58)

        row.defaultText = CreateLabel(row, "", 11)
        row.defaultText:SetPoint("LEFT", row.spellIDText, "RIGHT", 5, 0)
        row.defaultText:SetWidth(50)

        row.unitEntry = NSI.UI.Components.CreateTextEntry(row, nil, function()
            return row.entry and row.entry.unit or "player"
        end, function(_, value)
            local entry = row.entry
            if not entry then return end
            if entry.isDefault then
                row.unitEntry:SetValue(entry.unit or "player")
                return
            end
            entry.unit = value ~= "" and value or "player"
            local sound = entry.deleted and nil or entry.sound
            NSI:SaveAuraSound(entry.key, entry.spellID, sound, screen.categoryType, screen.categoryKey, entry.unit, entry.eventType)
            RefreshAuraScrollbox()
        end, 60, 20)
        row.unitEntry:SetPoint("LEFT", row.defaultText, "RIGHT", 5, 0)

        row.eventDropdown = NSI.UI.Components.CreateDropdown(row, nil, function()
            local items = BuildAuraSoundEventDropdown()
            for _, item in ipairs(items) do
                local baseOnclick = item.onclick
                item.onclick = function(a, b, value)
                    if baseOnclick then baseOnclick(a, b, value) end
                    local entry = row.entry
                    if not entry or entry.isDefault then return end
                    entry.eventType = value or "applied"
                    local sound = entry.deleted and nil or entry.sound
                    NSI:SaveAuraSound(entry.key, entry.spellID, sound, screen.categoryType, screen.categoryKey, entry.unit, entry.eventType)
                    RefreshAuraScrollbox()
                end
            end
            return items
        end, function()
            return GetAuraSoundEventLabel(row.entry and row.entry.eventType)
        end, 92, 20)
        row.eventDropdown:SetPoint("LEFT", row.unitEntry.frame, "RIGHT", -1, 0)

        row.soundDropdown = NSI.UI.Components.CreateDropdown(row, nil, function()
            local items = BuildAuraSoundDropdown()
            for _, item in ipairs(items) do
                local baseOnclick = item.onclick
                item.onclick = function(a, b, value)
                    if baseOnclick then baseOnclick(a, b, value) end
                    local entry = row.entry
                    if not entry then return end
                    local sound = value ~= "__NONE__" and value or nil
                    NSI:SaveAuraSound(entry.key, entry.spellID, sound, screen.categoryType, screen.categoryKey, entry.unit, entry.eventType)
                    RefreshAuraScrollbox()
                end
            end
            return items
        end, function()
            return GetSoundDisplayLabel(row.entry and not row.entry.deleted and row.entry.sound or nil)
        end, 130, 20, nil, nil, nil, nil, true)
        row.soundDropdown:SetPoint("LEFT", row.eventDropdown.frame, "RIGHT", -1, 0)

        row.deleteButton = CreateFrame("Button", nil, row)
        row.deleteButton:SetSize(16, 16)
        row.deleteButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.deleteButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        row.deleteButton:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        row.deleteButton:GetNormalTexture():SetVertexColor(0.9, 0.25, 0.25)
        row.deleteButton:GetHighlightTexture():SetVertexColor(1, 0.4, 0.4)
        row.deleteButton:SetScript("OnClick", function()
            local entry = row.entry
            if not entry then return end
            DeleteAuraSound(entry.key, entry.spellID, entry.defaultSound, entry.unit, entry.eventType)
            RefreshAuraScrollbox()
        end)
        row.deleteButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(T("Delete"))
            GameTooltip:Show()
        end)
        row.deleteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.resetButton = CreateFrame("Button", nil, row)
        row.resetButton:SetSize(16, 16)
        row.resetButton:SetPoint("RIGHT", row.deleteButton, "LEFT", -8, 0)
        row.resetButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\rotate-ccw.png]])
        row.resetButton:SetHighlightTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\rotate-ccw.png]])
        row.resetButton:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.7)
        row.resetButton:SetScript("OnClick", function()
            local entry = row.entry
            if not entry then return end
            ResetSpellToDefault(entry.key, entry.spellID, entry.defaultSound, entry.unit, entry.eventType)
            RefreshAuraScrollbox()
        end)
        row.resetButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(T("Reset"))
            GameTooltip:Show()
        end)
        row.resetButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

        return row
    end

    local function UpdateAuraRow(row, entry)
        row.entry = entry
        row.name:SetText(entry.name)
        row.spellIDText:SetText(entry.spellID)
        row.defaultText:SetText(entry.deleted and T("Deleted") or (entry.edited and T("Edited") or T("Default")))
        row.icon:SetTexture(C_Spell.GetSpellTexture(entry.spellID) or 134400)
        row.unitEntry:SetValue(entry.unit or "player")
        if entry.isDefault then
            row.unitEntry:Disable()
            row.eventDropdown:Disable()
        else
            row.unitEntry:Enable()
            row.eventDropdown:Enable()
        end
        row.eventDropdown:Refresh()
        row.soundDropdown:Refresh()
        row.resetButton:SetShown(entry.isDefault and entry.edited)
    end

    RefreshAuraScrollbox = function()
        local data = PrepareAuraSoundData(screen)
        for i = #auraRows + 1, #data do
            auraRows[i] = CreateAuraRow(i)
        end
        for i, entry in ipairs(data) do
            local row = auraRows[i]
            row:SetPoint("TOPLEFT", scrollbox.scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
            UpdateAuraRow(row, entry)
            row:Show()
        end
        for i = #data + 1, #auraRows do
            auraRows[i]:Hide()
        end
        scrollbox.scrollChild:SetHeight(math.max(1, #data * ROW_HEIGHT))
        scrollbox:UpdateScrollBar()
    end
    scrollbox.MasterRefresh = function(self) RefreshAuraScrollbox() end

    local newSpellLabel = CreateLabel(rightPanel, T("SpellID:"), 11)
    newSpellLabel:SetPoint("TOPLEFT", scrollbox.frame, "BOTTOMLEFT", 0, -18)

    local newSpellEntry = NSI.UI.Components.CreateTextEntry(rightPanel, nil, nil, nil, 90, 20)
    newSpellEntry:SetPoint("LEFT", newSpellLabel, "RIGHT", 8, 0)

    local newSoundLabel = CreateLabel(rightPanel, T("Sound:"), 11)
    newSoundLabel:SetPoint("LEFT", newSpellEntry.frame, "RIGHT", 12, 0)

    local newSoundValue = "__NONE__"
    local newSoundDropdown = NSI.UI.Components.CreateDropdown(rightPanel, nil, function()
        local items = BuildAuraSoundDropdown()
        for _, item in ipairs(items) do
            local baseOnclick = item.onclick
            item.onclick = function(a, b, value)
                if baseOnclick then baseOnclick(a, b, value) end
                newSoundValue = value
            end
        end
        return items
    end, function()
        return GetSoundDisplayLabel(newSoundValue ~= "__NONE__" and newSoundValue or nil)
    end, 135, 20, nil, nil, nil, nil, true)
    newSoundDropdown:SetPoint("LEFT", newSoundLabel, "RIGHT", 8, 0)

    local newUnitLabel = CreateLabel(rightPanel, T("Unit"), 11)
    newUnitLabel:SetPoint("LEFT", newSoundDropdown.frame, "RIGHT", 12, 0)

    local newUnitEntry = NSI.UI.Components.CreateTextEntry(rightPanel, nil, function() return "player" end, nil, 65, 20)
    newUnitEntry:SetPoint("LEFT", newUnitLabel, "RIGHT", 8, 0)

    local newEventLabel = CreateLabel(rightPanel, T("Event"), 11)
    newEventLabel:SetPoint("LEFT", newUnitEntry.frame, "RIGHT", 12, 0)

    local newEventValue = "applied"
    local newEventDropdown = NSI.UI.Components.CreateDropdown(rightPanel, nil, function()
        local items = BuildAuraSoundEventDropdown()
        for _, item in ipairs(items) do
            local baseOnclick = item.onclick
            item.onclick = function(a, b, value)
                if baseOnclick then baseOnclick(a, b, value) end
                newEventValue = value
            end
        end
        return items
    end, function()
        return GetAuraSoundEventLabel(newEventValue)
    end, 92, 20)
    newEventDropdown:SetPoint("LEFT", newEventLabel, "RIGHT", 8, 0)

    local addButton = NSI.UI.Components.CreateButton(rightPanel, T("Add"), function()
        if screen.categoryType == "Custom" and not screen.categoryKey then return end
        local spellID = tonumber(newSpellEntry:GetValue())
        local sound = newSoundValue ~= "__NONE__" and newSoundValue or nil
        local unit = newUnitEntry:GetValue()
        unit = unit ~= "" and unit or "player"
        local eventType = newEventValue or "applied"
        if not spellID or not sound then return end
        local entryKey = NSI:GetNextAuraSoundKey(spellID, unit, eventType)
        NSI:SaveAuraSound(entryKey, spellID, sound, screen.categoryType, screen.categoryKey, unit, eventType)
        RefreshAuraScrollbox()
        newSpellEntry:SetValue("")
        newUnitEntry:SetValue("player")
        newSoundValue = "__NONE__"
        newSoundDropdown:Refresh()
        newEventValue = "applied"
        newEventDropdown:Refresh()
    end, 70, 20, nil, nil, 11)
    addButton:SetPoint("LEFT", newEventDropdown.frame, "RIGHT", 10, 0)

    SelectCategoryType("Raid")
    return screen
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.AuraSounds = {
    BuildAuraSoundsUI = BuildAuraSoundsUI,
}
