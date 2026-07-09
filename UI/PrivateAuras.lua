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

-- Sound dropdown builder
local soundlist = NSI.LSM:List("sound")
local function build_sound_dropdown()
    local t = {}
    for i, sound in ipairs(soundlist) do
        tinsert(t, {
            label = sound,
            value = i,
            onclick = function(_, _, value)
                local toplay = NSI.LSM:Fetch("sound", sound)
                PlaySoundFile(toplay, "Master")
                return value
            end
        })
    end
    return t
end

local function BuildPASoundEditUI()
    local PASound_edit_frame = DF:CreateSimplePanel(UIParent, 485, 420, T("Private Aura Sounds"), "PASoundEditFrame", {
        DontRightClickClose = true
    })
    ApplyUIFont(PASound_edit_frame.Title, 12)
    PASound_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local function PrepareData(data)
        local data = {}
        for spellID, info in pairs(NSRT.PASounds) do
            if spellID and type(info) == "table" and info.sound then
                local spell = C_Spell.GetSpellInfo(spellID)
                if spell then
                    tinsert(data, {sound = info.sound, spellID = spellID, name = spell.name})
                end
            end
        end
        table.sort(data, function(a, b)
            return a.name < b.name
        end)
        return data
    end

    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    function NSI:RefreshPASoundEditUI()
        PASound_edit_frame.scrollbox:MasterRefresh()
    end

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local Data = data[index]
            if Data and Data.sound then
                local line = self:GetLine(i)

                line.name.text = Data.name
                line.spellID = Data.spellID
                line.spellIDText.text = Data.spellID
                line.sound = Data.sound
                line.texture = C_Spell.GetSpellTexture(line.spellID)
                line.sounddropdown:Select(line.sound)
                line.spellIcon:SetTexture(line.texture)
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.spellIcon = DF:CreateTexture(line, 134400, 18, 18)
        line.spellIcon:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.spellIcon:SetScript("OnEnter", function(self)
            local parent = self:GetParent()
            if parent.spellID then
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
                GameTooltip:SetSpellByID(parent.spellID)
                GameTooltip:Show()
            end
        end)
        line.spellIcon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line.spellIcon, "RIGHT", 5, 0)
        line.name:SetWidth(150)

        line.spellIDText = DF:CreateLabel(line, "")
        line.spellIDText:SetPoint("LEFT", line.name, "RIGHT", 5, 0)
        line.spellIDText:SetWidth(60)

        line.sounddropdown = DF:CreateDropDown(line, function() return build_sound_dropdown() end,
            nil, 170)
        line.sounddropdown:SetTemplate(options_dropdown_template)
        line.sounddropdown:SetPoint("LEFT", line.spellIDText, "RIGHT", 5, 0)
        line.sounddropdown:SetHook("OnOptionSelected", function(self, _, value)
            local newValue = soundlist[value]
            local oldValue = line.sound

            if oldValue == newValue or not NSI:IsValidPASoundSpell(line.spellID) then return end
            NSI:SavePASound(tonumber(line.spellID), newValue)

            line.sound = newValue
            parent:MasterRefresh()
        end)

        line.deleteButton = DF:CreateButton(line, function()
            NSI:SavePASound(tonumber(line.spellID), nil)
            self:SetData(NSRT.PASounds)
            self:MasterRefresh()
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])

        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        return line
    end

    local scrollLines = 15
    local PASound_edit_scrollbox = DF:CreateScrollBox(PASound_edit_frame, "$parentPASoundsEditScrollBox", refresh,
        {},
        445, 300, scrollLines, 20, createLineFunc)
    PASound_edit_frame.scrollbox = PASound_edit_scrollbox
    PASound_edit_scrollbox:SetPoint("TOPLEFT", PASound_edit_frame, "TOPLEFT", 10, -50)
    PASound_edit_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(PASound_edit_scrollbox)

    for i = 1, scrollLines do
        PASound_edit_scrollbox:CreateLine(createLineFunc)
    end

    local SpellName = DF:CreateLabel(PASound_edit_frame, T("Spell Name"), 11)
    ApplyUIFont(SpellName, 11)
    SpellName:SetPoint("TOPLEFT", PASound_edit_frame, "TOPLEFT", 40, -30)
    SpellName:SetWidth(100)

    local SpellID = DF:CreateLabel(PASound_edit_frame, T("Spell-ID"), 11)
    ApplyUIFont(SpellID, 11)
    SpellID:SetPoint("LEFT", SpellName, "RIGHT", 55, 0)
    SpellID:SetWidth(70)

    local Sound = DF:CreateLabel(PASound_edit_frame, T("Sound"), 11)
    ApplyUIFont(Sound, 11)
    Sound:SetWidth(120)
    Sound:SetPoint("LEFT", SpellID, "RIGHT", 0, 0)

    PASound_edit_scrollbox:SetScript("OnShow", function(self)
        PASound_edit_frame:SetTitle(T("Private Aura Sounds"))
        self:MasterRefresh()
    end)

    local label_width = 80
    local NewSpellID = DF:CreateLabel(PASound_edit_frame, T("SpellID:"), 11)
    ApplyUIFont(NewSpellID, 11)
    NewSpellID:SetPoint("BOTTOMLEFT", PASound_edit_frame, "BOTTOMLEFT", 10, 50)
    NewSpellID:SetWidth(label_width)

    local NewSpellIDTextEntry = DF:CreateTextEntry(PASound_edit_frame, function() end, 120, 20)
    NewSpellIDTextEntry:SetPoint("LEFT", NewSpellID, "RIGHT", -10, 0)
    NewSpellIDTextEntry:SetTemplate(options_dropdown_template)

    local NewSound = DF:CreateLabel(PASound_edit_frame, T("Sound:"), 11)
    ApplyUIFont(NewSound, 11)
    NewSound:SetPoint("LEFT", NewSpellIDTextEntry, "RIGHT", 10, 0)
    NewSound:SetWidth(label_width)

    local NewSoundDropdown = DF:CreateDropDown(PASound_edit_frame, function() return build_sound_dropdown() end,
        nil, 120)
    NewSoundDropdown:SetPoint("LEFT", NewSound, "RIGHT", -10, 0)
    NewSoundDropdown:SetTemplate(options_dropdown_template)

    local add_button = DF:CreateButton(PASound_edit_frame, function()
        local spellID = NewSpellIDTextEntry:GetText()
        local sound = soundlist[NewSoundDropdown:GetValue()]
        if spellID and sound ~= "" then
            NewSpellIDTextEntry:SetText("")
            NewSoundDropdown:SetValue(nil)
            spellID = tonumber(spellID)
            if NSI:IsValidPASoundSpell(spellID) then
                NSI:SavePASound(spellID, sound)
            else
                print(T("Your entered spellID does not appear to be a Private Aura."))
            end
            PASound_edit_scrollbox:MasterRefresh()

        end
    end, 60, 20, T("Add"))
    ApplyUIFont(add_button, 12)
    add_button:SetPoint("LEFT", NewSoundDropdown, "RIGHT", 10, 0)
    add_button:SetTemplate(options_button_template)

    local function DeleteAllPASounds(self)
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, T("Confirm Deleting ALL Private Aura Sounds"), "NSRTDeleteALLPASoundsPopup")
        ApplyUIFont(popup.Title, 12)
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup,
            T("Are you sure you want to delete all \nPrivate Aura Sounds?"), 12, "orange")
        ApplyUIFont(text, 12)
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            for spellID, info in pairs(NSRT.PASounds) do
                if info and type(info) == "table" and info.sound then
                    NSI:AddPASound(spellID, nil)
                end
            end
            NSRT.PASounds = {
                UseDefaultPASounds = NSRT.PASounds.UseDefaultPASounds,
                UseDefaultMPlusPASounds = NSRT.PASounds.UseDefaultMPlusPASounds
            }
            PASound_edit_scrollbox:MasterRefresh()
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

    local delete_all_button = DF:CreateButton(PASound_edit_frame, function()
        DeleteAllPASounds(self)
        PASound_edit_scrollbox:MasterRefresh()
    end, 60, 20, T("Delete ALL"))
    ApplyUIFont(delete_all_button, 12)
    delete_all_button:SetPoint("BOTTOMRIGHT", PASound_edit_frame, "BOTTOMRIGHT", -10, 10)
    delete_all_button:SetTemplate(options_button_template)

    PASound_edit_frame:Hide()
    return PASound_edit_frame
end

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
    end
end

local midnightS2AuraSoundOrder = {
    [3379] = 1,
    [3470] = 2,
    [3445] = 3,
    [3455] = 4,
    [3497] = 5,
    [3420] = 6,
    [3421] = 7,
    [3429] = 8,
    [3492] = 9,
}

local function GetAuraSoundCategories(categoryType)
    local categories = {}
    for _, category in ipairs((NSI.AuraSoundCategories and NSI.AuraSoundCategories[categoryType]) or {}) do
        categories[#categories + 1] = category
    end
    if categoryType == "Raid" then
        table.sort(categories, function(a, b)
            local aOrder = NSI:IsMidnightS2() and midnightS2AuraSoundOrder[a.key] or nil
            local bOrder = NSI:IsMidnightS2() and midnightS2AuraSoundOrder[b.key] or nil
            return (aOrder or 1000 + (NSI.EncounterOrder[a.key] or 9999)) < (bOrder or 1000 + (NSI.EncounterOrder[b.key] or 9999))
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
            local spellID = type(entry) == "table" and entry.spellID or entry
            local saved = NSRT.PASounds[spellID]
            local defaultSound = type(entry) == "table" and entry.sound or NSI:GetAuraSoundDefault(spellID)
            local useDefaultSounds = screen.categoryType == "Dungeons" and NSRT.PASounds.UseDefaultMPlusPASounds or NSRT.PASounds.UseDefaultPASounds
            local sound = useDefaultSounds and defaultSound or nil
            if type(saved) == "table" then
                sound = saved.edited and saved.sound or sound
            end
            local spell = C_Spell.GetSpellInfo(spellID)
            data[#data + 1] = {
                spellID = spellID,
                name = spell and spell.name or ("Spell " .. spellID),
                sound = StripSoundColor(sound),
                defaultSound = StripSoundColor(defaultSound),
                isDefault = defaultSound ~= nil,
                edited = type(saved) == "table" and saved.edited,
                deleted = type(saved) == "table" and saved.edited and not saved.sound,
            }
            seen[spellID] = true
        end
    end

    for spellID, info in pairs(NSRT.PASounds) do
        if type(info) == "table" then
            local uncategorizedCustom = screen.categoryType == "Custom" and screen.categoryKey == "custom" and not info.categoryType and not NSI:GetAuraSoundDefault(spellID)
            local matchesCategory = info.categoryType == screen.categoryType and info.categoryKey == screen.categoryKey
            if (matchesCategory or uncategorizedCustom) and not seen[spellID] then
                local spell = C_Spell.GetSpellInfo(spellID)
                data[#data + 1] = {
                    spellID = spellID,
                    name = spell and spell.name or ("Spell " .. spellID),
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

    local function ResetSpellToDefault(spellID, defaultSound)
        if not spellID then return end
        NSRT.PASounds[spellID] = nil
        local enabled = screen.categoryType == "Dungeons" and NSRT.PASounds.UseDefaultMPlusPASounds or NSRT.PASounds.UseDefaultPASounds
        NSI:AddPASound(spellID, enabled and defaultSound or nil)
    end

    local function DeleteAuraSound(spellID, defaultSound)
        if not spellID then return end
        if defaultSound then
            NSI:SavePASound(spellID, nil, screen.categoryType, screen.categoryKey)
        else
            NSRT.PASounds[spellID] = nil
            NSI:AddPASound(spellID, nil)
        end
    end

    local function ResetCategory()
        local category = FindAuraSoundCategory(screen.categoryType, screen.categoryKey)
        local categoryDefaults = {}

        if category then
            for _, entry in ipairs(category.entries or {}) do
                local spellID = type(entry) == "table" and entry.spellID or entry
                local defaultSound = type(entry) == "table" and entry.sound or NSI:GetAuraSoundDefault(spellID)
                if spellID then
                    categoryDefaults[spellID] = true
                    ResetSpellToDefault(spellID, defaultSound)
                end
            end
        end

        for spellID, info in pairs(NSRT.PASounds) do
            if type(info) == "table" then
                local uncategorizedCustom = screen.categoryType == "Custom" and screen.categoryKey == "custom" and not info.categoryType and not NSI:GetAuraSoundDefault(spellID)
                local matchesCategory = info.categoryType == screen.categoryType and info.categoryKey == screen.categoryKey
                if (matchesCategory or uncategorizedCustom) and not categoryDefaults[spellID] then
                    NSRT.PASounds[spellID] = nil
                    NSI:AddPASound(spellID, nil)
                end
            end
        end

        screen.scrollbox:MasterRefresh()
    end

    local function ResetAllAuraSounds()
        for spellID, info in pairs(NSRT.PASounds) do
            if type(info) == "table" then
                NSRT.PASounds[spellID] = nil
                NSI:AddPASound(spellID, nil)
            end
        end
        NSI:ApplyDefaultPASounds(true, false, NSRT.PASounds.UseDefaultPASounds)
        NSI:ApplyDefaultPASounds(true, true, NSRT.PASounds.UseDefaultMPlusPASounds)
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
    screen.categoryDropdown:SetPoint("LEFT", GetUIObject(categoryLabel), "RIGHT", 10, 0)
    screen.categoryDropdown:Select(GetAuraSoundSelectionLabel(screen))

    local raidDefaultsCB = CreateCheckButton(screen, T("Use Default Raid Aura Sounds"), function()
        return NSRT.PASounds.UseDefaultPASounds
    end, function(_, value)
        NSRT.PASounds.UseDefaultPASounds = value
        NSI:ApplyDefaultPASounds(true, false, value)
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
        return NSRT.PASounds.UseDefaultMPlusPASounds
    end, function(_, value)
        NSRT.PASounds.UseDefaultMPlusPASounds = value
        NSI:ApplyDefaultPASounds(true, true, value)
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

    local function refresh(scrollbox, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local rowData = data[index]
            if rowData then
                local line = scrollbox:GetLine(i)
                line:Show()
                line.spellID = rowData.spellID
                line.defaultSound = rowData.defaultSound
                line.isDefault = rowData.isDefault
                line.name.text = rowData.name
                line.spellIDText.text = rowData.spellID
                line.defaultText.text = rowData.deleted and T("Deleted") or (rowData.edited and T("Edited") or T("Default"))
                line.icon:SetTexture(C_Spell.GetSpellTexture(rowData.spellID) or 134400)
                line.sound = rowData.sound
                line.soundDropdown:Select(rowData.deleted and "__NONE__" or (rowData.sound or "__NONE__"))
                GetUIObject(line.resetButton):SetShown(rowData.edited or not rowData.isDefault)
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

        line.soundDropdown = DF:CreateDropDown(line, BuildAuraSoundDropdown, nil, 170, 20, nil, "$parentSoundDropdown", options_dropdown_template)
        line.soundDropdown:SetPoint("LEFT", GetUIObject(line.defaultText), "RIGHT", 5, 0)
        line.soundDropdown:SetHook("OnOptionSelected", function(_, _, value)
            local sound = value ~= "__NONE__" and value or nil
            NSI:SavePASound(line.spellID, sound, screen.categoryType, screen.categoryKey)
            scrollbox:MasterRefresh()
        end)

        line.resetButton = DF:CreateButton(line, function()
            ResetSpellToDefault(line.spellID, line.defaultSound)
            scrollbox:MasterRefresh()
        end, 48, 18, T("Reset"))
        ApplyUIFont(line.resetButton, 11)
        line.resetButton:SetPoint("RIGHT", line, "RIGHT", -62, 0)
        line.resetButton:SetTemplate(options_button_template)

        line.deleteButton = DF:CreateButton(line, function()
            DeleteAuraSound(line.spellID, line.defaultSound)
            scrollbox:MasterRefresh()
        end, 52, 18, T("Delete"))
        ApplyUIFont(line.deleteButton, 11)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)
        line.deleteButton:SetTemplate(options_button_template)

        return line
    end

    local scrollLines = 18
    local scrollbox = DF:CreateScrollBox(screen, "$parentAuraSoundScrollBox", refresh, {}, 820, 360, scrollLines, 20, createLine)
    screen.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", GetUIObject(typeLabel), "BOTTOMLEFT", 0, -36)
    DF:ReskinSlider(scrollbox)
    scrollbox.MasterRefresh = function(self)
        self:SetData(PrepareAuraSoundData(screen))
        self:Refresh()
    end
    for i = 1, scrollLines do
        scrollbox:CreateLine(createLine)
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

    local addButton = DF:CreateButton(screen, function()
        local spellID = tonumber(newSpellEntry:GetText())
        local value = newSoundDropdown:GetValue()
        local sound = value ~= "__NONE__" and value or nil
        if not spellID or not sound then return end
        NSI:SavePASound(spellID, sound, screen.categoryType, screen.categoryKey)
        newSpellEntry:SetText("")
        newSoundDropdown:SetValue(nil)
        scrollbox:MasterRefresh()
    end, 70, 20, T("Add"))
    ApplyUIFont(addButton, 11)
    addButton:SetPoint("LEFT", GetUIObject(newSoundDropdown), "RIGHT", 10, 0)
    addButton:SetTemplate(options_button_template)

    scrollbox:MasterRefresh()
    return screen
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.PrivateAuras = {
    BuildPASoundEditUI = BuildPASoundEditUI,
    BuildAuraSoundsUI = BuildAuraSoundsUI,
}
