local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template
local BossData = NSI.UI.BossData
local CreateCheckButton = NSI.UI.Components.CreateCheckButton

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
                    PlaySoundFile(toplay, "Master")
                end
                return value
            end,
        })
    end
    return t
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

local function GetAuraSoundCategoryLabel(categoryType, category)
    if categoryType == "Raid" then
        return NSI:Loc(NSI.BossNames[category.key] or ("Encounter " .. tostring(category.key)))
    end
    return NSI:Loc(category.label or tostring(category.key))
end

local function GetAuraSoundCategoryIcon(categoryType, category)
    if categoryType == "Raid" and BossData and BossData.BossIcons then
        return BossData.BossIcons[category.key]
    elseif categoryType == "Dungeons" and NSI.AuraSoundDungeonIcons then
        return NSI.AuraSoundDungeonIcons[category.key]
    end
end

local function GetAuraSoundCategories(categoryType)
    local categories = {}
    for _, category in ipairs((NSI.AuraSoundCategories and NSI.AuraSoundCategories[categoryType]) or {}) do
        categories[#categories + 1] = category
    end
    if categoryType == "Raid" then
        table.sort(categories, function(a, b)
            return (NSI.EncounterOrder[a.key] or 9999) < (NSI.EncounterOrder[b.key] or 9999)
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
    local entryKey = type(entry) == "table" and entry.key or NSI:GetAuraSoundKey(spellID, unit)
    local defaultSound = type(entry) == "table" and entry.sound or NSI:GetAuraSoundDefault(spellID)
    return entryKey, spellID, defaultSound, unit
end

local function BuildAuraSoundCategoryOptions(screen)
    local options = {}
    local categoryType = screen.categoryType or "Raid"
    for _, category in ipairs(GetAuraSoundCategories(categoryType)) do
        local label = GetAuraSoundCategoryLabel(categoryType, category)
        options[#options + 1] = {
            label = label,
            value = category.key,
            icon = GetAuraSoundCategoryIcon(categoryType, category),
            iconsize = {16, 16},
            texcoord = {0.05, 0.95, 0.05, 0.95},
            onclick = function(_, _, value)
                screen.categoryKey = value
                screen.categoryDropdown:Select(label)
                screen.scrollbox:MasterRefresh()
            end,
        }
    end
    return options
end

local function GetAuraSoundSelectionLabel(screen)
    local category = FindAuraSoundCategory(screen.categoryType, screen.categoryKey)
    if category then
        return GetAuraSoundCategoryLabel(screen.categoryType, category)
    end
    return T("Select Category")
end

local function PrepareAuraSoundData(screen)
    local data = {}
    local seen = {}
    local category = FindAuraSoundCategory(screen.categoryType, screen.categoryKey)

    if category then
        for _, entry in ipairs(category.entries or {}) do
            local rawSpellID = tonumber(type(entry) == "table" and entry.spellID or entry)
            if rawSpellID then
                local entryKey, spellID, defaultSound, defaultUnit = GetAuraSoundEntryInfo(entry)
                if entryKey then
                    local saved = NSRT.AuraSounds[entryKey]
                    local unit = type(saved) == "table" and saved.unit or defaultUnit or "player"
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
            local uncategorizedCustom = screen.categoryType == "Custom" and screen.categoryKey == "custom" and not info.categoryType and not NSI:GetAuraSoundDefault(spellID)
            local matchesCategory = info.categoryType == screen.categoryType and info.categoryKey == screen.categoryKey
            if spellID and (matchesCategory or uncategorizedCustom) and not seen[key] then
                local spell = C_Spell.GetSpellInfo(spellID)
                data[#data + 1] = {
                    key = key,
                    spellID = spellID,
                    name = spell and spell.name or ("Spell " .. spellID),
                    unit = info.unit or "player",
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

    local function ResetSpellToDefault(entryKey, spellID, defaultSound)
        if not spellID then return end
        NSRT.AuraSounds[entryKey] = nil
        local enabled = screen.categoryType == "Dungeons" and NSRT.AuraSounds.UseDefaultDungeonAuraSounds or NSRT.AuraSounds.UseDefaultRaidAuraSounds
        NSI:AddAuraSound(spellID, enabled and defaultSound or nil, entryKey, "player")
    end

    local function DeleteAuraSound(entryKey, spellID, defaultSound)
        if not spellID then return end
        if defaultSound then
            NSI:SaveAuraSound(entryKey, spellID, nil, screen.categoryType, screen.categoryKey, "player")
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
                    local entryKey, spellID, defaultSound = GetAuraSoundEntryInfo(entry)
                    if spellID then
                        categoryDefaults[entryKey] = true
                        ResetSpellToDefault(entryKey, spellID, defaultSound)
                    end
                end
            end
        end

        for key, info in pairs(NSRT.AuraSounds) do
            if type(info) == "table" then
                local spellID = info.spellID
                local uncategorizedCustom = screen.categoryType == "Custom" and screen.categoryKey == "custom" and not info.categoryType and not NSI:GetAuraSoundDefault(spellID)
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
            if type(info) == "table" then
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

    local title = DF:CreateLabel(screen, T("Aura Sounds"), 14, "orange")
    ApplyUIFont(title, 14)
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", 10, -8)

    local typeLabel = DF:CreateLabel(screen, T("Category"), 11)
    ApplyUIFont(typeLabel, 11)
    typeLabel:SetPoint("TOPLEFT", GetUIObject(title), "BOTTOMLEFT", 0, -14)

    local function BuildTypeOptions()
        return {
            {
                label = T("Raid Bosses"),
                value = "Raid",
                onclick = function()
                    screen.categoryType = "Raid"
                    local first = GetAuraSoundCategories("Raid")[1]
                    screen.categoryKey = first and first.key
                    screen.typeDropdown:Select(T("Raid Bosses"))
                    screen.categoryDropdown:Refresh()
                    screen.categoryDropdown:Select(GetAuraSoundSelectionLabel(screen))
                    screen.scrollbox:MasterRefresh()
                end,
            },
            {
                label = T("Dungeons"),
                value = "Dungeons",
                onclick = function()
                    screen.categoryType = "Dungeons"
                    local first = GetAuraSoundCategories("Dungeons")[1]
                    screen.categoryKey = first and first.key
                    screen.typeDropdown:Select(T("Dungeons"))
                    screen.categoryDropdown:Refresh()
                    screen.categoryDropdown:Select(GetAuraSoundSelectionLabel(screen))
                    screen.scrollbox:MasterRefresh()
                end,
            },
            {
                label = T("Custom"),
                value = "Custom",
                onclick = function()
                    screen.categoryType = "Custom"
                    local first = GetAuraSoundCategories("Custom")[1]
                    screen.categoryKey = first and first.key
                    screen.typeDropdown:Select(T("Custom"))
                    screen.categoryDropdown:Refresh()
                    screen.categoryDropdown:Select(GetAuraSoundSelectionLabel(screen))
                    screen.scrollbox:MasterRefresh()
                end,
            },
        }
    end

    screen.typeDropdown = DF:CreateDropDown(screen, BuildTypeOptions, nil, 135, 22, nil, "$parentTypeDropdown", options_dropdown_template)
    screen.typeDropdown:SetPoint("LEFT", GetUIObject(typeLabel), "RIGHT", 10, 0)
    screen.typeDropdown:Select(T("Raid Bosses"))

    local categoryLabel = DF:CreateLabel(screen, T("Boss / Dungeon"), 11)
    ApplyUIFont(categoryLabel, 11)
    categoryLabel:SetPoint("LEFT", GetUIObject(screen.typeDropdown), "RIGHT", 18, 0)

    screen.categoryDropdown = DF:CreateDropDown(screen, function() return BuildAuraSoundCategoryOptions(screen) end, nil, 230, 22, nil, "$parentCategoryDropdown", options_dropdown_template)
    screen.categoryDropdown.realsizeH = 160
    screen.categoryDropdown:SetPoint("LEFT", GetUIObject(categoryLabel), "RIGHT", 10, 0)
    screen.categoryDropdown:Select(GetAuraSoundSelectionLabel(screen))

    local raidDefaultsCB = CreateCheckButton(screen, T("Use Default Raid Aura Sounds"), function()
        return NSRT.AuraSounds.UseDefaultRaidAuraSounds
    end, function(_, value)
        NSRT.AuraSounds.UseDefaultRaidAuraSounds = value
        NSI:ApplyDefaultAuraSounds(true, false, value)
        if screen.scrollbox then
            screen.scrollbox:MasterRefresh()
        end
    end, 230, 18, "$parentRaidDefaults", {
        title = T("Use Default Raid Aura Sounds"),
        desc = T("This applies sounds to all raid auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spell IDs yourself previously this option will NOT overwrite that."),
    })
    raidDefaultsCB:SetPoint("TOPLEFT", GetUIObject(typeLabel), "BOTTOMLEFT", 0, -8)
    NSI:SetUIFont(raidDefaultsCB.label, 11, "")

    local dungeonDefaultsCB = CreateCheckButton(screen, T("Use Default Dungeon Aura Sounds"), function()
        return NSRT.AuraSounds.UseDefaultDungeonAuraSounds
    end, function(_, value)
        NSRT.AuraSounds.UseDefaultDungeonAuraSounds = value
        NSI:ApplyDefaultAuraSounds(true, true, value)
        if screen.scrollbox then
            screen.scrollbox:MasterRefresh()
        end
    end, 250, 18, "$parentDungeonDefaults", {
        title = T("Use Default Dungeon Aura Sounds"),
        desc = T("This applies sounds to all dungeon auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spell IDs yourself previously this option will NOT overwrite that."),
    })
    dungeonDefaultsCB:SetPoint("LEFT", raidDefaultsCB.frame, "RIGHT", 18, 0)
    NSI:SetUIFont(dungeonDefaultsCB.label, 11, "")

    local resetCategoryButton = DF:CreateButton(screen, ResetCategory, 105, 20, T("Reset Category"))
    ApplyUIFont(resetCategoryButton, 11)
    resetCategoryButton:SetPoint("LEFT", dungeonDefaultsCB.frame, "RIGHT", 18, 0)
    resetCategoryButton:SetTemplate(options_button_template)

    local resetAllButton = DF:CreateButton(screen, ConfirmResetAllAuraSounds, 85, 20, T("Reset All"))
    ApplyUIFont(resetAllButton, 11)
    resetAllButton:SetPoint("LEFT", GetUIObject(resetCategoryButton), "RIGHT", 8, 0)
    resetAllButton:SetTemplate(options_button_template)

    local scrollLines = 18

    local function ClearLine(line)
        if not line then return end
        line.entryKey = nil
        line.spellID = nil
        line.defaultSound = nil
        line.isDefault = nil
        line.isActive = false
        if line.name then line.name.text = "" end
        if line.spellIDText then line.spellIDText.text = "" end
        if line.defaultText then line.defaultText.text = "" end
        if line.icon then line.icon:SetTexture(nil) end
        line:Hide()
    end

    local function ShowLine(line)
        line:Show()
        line.isActive = true
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
                ShowLine(line)
                line.entryKey = rowData.key
                line.spellID = rowData.spellID
                line.defaultSound = rowData.defaultSound
                line.isDefault = rowData.isDefault
                line.unit = rowData.unit or "player"
                line.name.text = rowData.name
                line.spellIDText.text = rowData.spellID
                line.defaultText.text = rowData.deleted and T("Deleted") or (rowData.edited and T("Edited") or T("Default"))
                line.unitEntry:SetText(line.unit)
                if rowData.isDefault then
                    line.unitEntry:Disable()
                else
                    line.unitEntry:Enable()
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
        line:SetPoint("TOPLEFT", GetUIObject(scrollbox), "TOPLEFT", 1, -((index - 1) * scrollbox.LineHeight) - 1)
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
        line.name:SetWidth(260)

        line.spellIDText = DF:CreateLabel(line, "")
        ApplyUIFont(line.spellIDText, 11)
        line.spellIDText:SetPoint("LEFT", GetUIObject(line.name), "RIGHT", 5, 0)
        line.spellIDText:SetWidth(58)

        line.defaultText = DF:CreateLabel(line, "")
        ApplyUIFont(line.defaultText, 11)
        line.defaultText:SetPoint("LEFT", GetUIObject(line.spellIDText), "RIGHT", 5, 0)
        line.defaultText:SetWidth(60)

        line.unitEntry = DF:CreateTextEntry(line, function(_, _, value)
            if not line.isActive or not line.entryKey or not line.spellID then return end
            if line.isDefault then
                line.unitEntry:SetText(line.unit or "player")
                return
            end
            line.unit = value ~= "" and value or "player"
            local sound = line.soundDropdown:GetValue()
            sound = sound ~= "__NONE__" and sound or nil
            NSI:SaveAuraSound(line.entryKey, line.spellID, sound, screen.categoryType, screen.categoryKey, line.unit)
            scrollbox:MasterRefresh()
        end, 80, 20)
        line.unitEntry:SetTemplate(options_dropdown_template)
        line.unitEntry:SetPoint("LEFT", GetUIObject(line.defaultText), "RIGHT", 5, 0)

        line.soundDropdown = DF:CreateDropDown(line, BuildAuraSoundDropdown, nil, 170, 20, nil, "$parentSoundDropdown", options_dropdown_template)
        line.soundDropdown:SetPoint("LEFT", GetUIObject(line.unitEntry), "RIGHT", -1, 0)
        line.soundDropdown:SetHook("OnOptionSelected", function(_, _, value)
            if not line.isActive or not line.entryKey or not line.spellID then return end
            local sound = value ~= "__NONE__" and value or nil
            NSI:SaveAuraSound(line.entryKey, line.spellID, sound, screen.categoryType, screen.categoryKey, line.unit)
            scrollbox:MasterRefresh()
        end)

        line.resetButton = DF:CreateButton(line, function()
            if not line.isActive or not line.entryKey or not line.spellID then return end
            ResetSpellToDefault(line.entryKey, line.spellID, line.defaultSound)
            scrollbox:MasterRefresh()
        end, 48, 18, T("Reset"))
        ApplyUIFont(line.resetButton, 11)
        line.resetButton:SetPoint("RIGHT", line, "RIGHT", -62, 0)
        line.resetButton:SetTemplate(options_button_template)

        line.deleteButton = DF:CreateButton(line, function()
            if not line.isActive or not line.entryKey or not line.spellID then return end
            DeleteAuraSound(line.entryKey, line.spellID, line.defaultSound)
            scrollbox:MasterRefresh()
        end, 52, 18, T("Delete"))
        ApplyUIFont(line.deleteButton, 11)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)
        line.deleteButton:SetTemplate(options_button_template)

        return line
    end

    local scrollbox = DF:CreateScrollBox(screen, "$parentAuraSoundScrollBox", refresh, {}, 820, 360, scrollLines, 20, createLine)
    screen.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", GetUIObject(typeLabel), "BOTTOMLEFT", 0, -36)
    DF:ReskinSlider(scrollbox)
    scrollbox.MasterRefresh = function(self)
        self:SetData(PrepareAuraSoundData(screen))
        self:Refresh()
    end
    for i = 1, scrollLines do
        ClearLine(scrollbox:CreateLine(createLine))
    end

    local newSpellLabel = DF:CreateLabel(screen, T("SpellID:"), 11)
    ApplyUIFont(newSpellLabel, 11)
    newSpellLabel:SetPoint("TOPLEFT", GetUIObject(scrollbox), "BOTTOMLEFT", 0, -18)

    local newSpellEntry = DF:CreateTextEntry(screen, function() end, 105, 20)
    newSpellEntry:SetPoint("LEFT", GetUIObject(newSpellLabel), "RIGHT", 8, 0)
    newSpellEntry:SetTemplate(options_dropdown_template)

    local newSoundLabel = DF:CreateLabel(screen, T("Sound:"), 11)
    ApplyUIFont(newSoundLabel, 11)
    newSoundLabel:SetPoint("LEFT", GetUIObject(newSpellEntry), "RIGHT", 12, 0)

    local newSoundDropdown = DF:CreateDropDown(screen, BuildAuraSoundDropdown, nil, 170, 20, nil, "$parentNewSoundDropdown", options_dropdown_template)
    newSoundDropdown:SetPoint("LEFT", GetUIObject(newSoundLabel), "RIGHT", 8, 0)

    local newUnitLabel = DF:CreateLabel(screen, T("Unit"), 11)
    ApplyUIFont(newUnitLabel, 11)
    newUnitLabel:SetPoint("LEFT", GetUIObject(newSoundDropdown), "RIGHT", 12, 0)

    local newUnitEntry = DF:CreateTextEntry(screen, function() end, 90, 20)
    newUnitEntry:SetPoint("LEFT", GetUIObject(newUnitLabel), "RIGHT", 8, 0)
    newUnitEntry:SetTemplate(options_dropdown_template)
    newUnitEntry:SetText("player")

    local addButton = DF:CreateButton(screen, function()
        local spellID = tonumber(newSpellEntry:GetText())
        local value = newSoundDropdown:GetValue()
        local sound = value ~= "__NONE__" and value or nil
        local unit = newUnitEntry:GetText()
        unit = unit ~= "" and unit or "player"
        if not spellID or not sound then return end
        local entryKey = NSI:GetAuraSoundKey(spellID, unit)
        NSI:SaveAuraSound(entryKey, spellID, sound, screen.categoryType, screen.categoryKey, unit)
        newSpellEntry:SetText("")
        newUnitEntry:SetText("player")
        newSoundDropdown:SetValue(nil)
        scrollbox:MasterRefresh()
    end, 70, 20, T("Add"))
    ApplyUIFont(addButton, 11)
    addButton:SetPoint("LEFT", GetUIObject(newUnitEntry), "RIGHT", 10, 0)
    addButton:SetTemplate(options_button_template)

    scrollbox:MasterRefresh()
    return screen
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.AuraSounds = {
    BuildAuraSoundsUI = BuildAuraSoundsUI,
}
