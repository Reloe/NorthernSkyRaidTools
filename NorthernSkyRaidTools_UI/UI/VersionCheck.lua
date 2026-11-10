local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Accent = STYLE.Accent
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local window_height        = Core.window_height
local content_width        = Core.content_width
local content_height       = Core.content_height
local tab_content_height   = Core.tab_content_height
local options_text_template     = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template   = Core.options_switch_template
local options_button_template   = Core.options_button_template

local function T(key)
    return NSI:Loc(key)
end

local checkable_components = {"Addon", "Note", "Reminder", "Encounter Alert"}

local function build_checkable_components_options(onSelect, forPresets)
    local t = {}
    for i = 1, #checkable_components do
        if not forPresets or checkable_components[i] ~= "Encounter Alert" then
            tinsert(t, {
                label = T(checkable_components[i]),
                phraseId = checkable_components[i],
                value = checkable_components[i],
                onclick = function(dropdown, fixedValue, value)
                    if onSelect then onSelect(value) end
                end
            })
        end
    end
    return t
end

local function BuildVersionCheckUI(parent)
    local UpdateComponentType
    local selectedEncID, selectedAlertID
    local selectedDiffID = 16

    local hide_version_response_button = DF:CreateSwitch(parent,
        function(self, _, value) NSRT.Settings["VersionCheckRemoveResponse"] = value end,
        NSRT.Settings["VersionCheckRemoveResponse"], 20, 20, nil, nil, nil, "VersionCheckResponseToggle", nil, nil, nil,
        T("Hide Version Check Responses"), options_switch_template, options_text_template)
    hide_version_response_button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    hide_version_response_button:SetAsCheckBox()
    hide_version_response_button:SetTooltip(
        T("Hides Version Check Responses of Users that are on the correct version"))
    local hide_version_response_label = DF:CreateLabel(parent, T("Hide Version Check Responses"), 10, "white", "", nil,
        "VersionCheckResponseLabel", "overlay")
    hide_version_response_label:SetTemplate(options_text_template)
    hide_version_response_label:SetPoint("LEFT", hide_version_response_button, "RIGHT", 2, 0)
    local component_type_label = DF:CreateLabel(parent, T("Component Type"), 9.5, "white")
    component_type_label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -40)

    local component_type_dropdown = DF:CreateDropDown(parent, function()
        return build_checkable_components_options(function() UpdateComponentType() end)
    end, checkable_components[1], 140)
    component_type_dropdown.addonId = addonId
    component_type_dropdown:Select(checkable_components[1])
    component_type_dropdown:SetTemplate(options_dropdown_template)
    component_type_dropdown:SetPoint("LEFT", component_type_label, "RIGHT", 5, 0)

    local component_name_label = DF:CreateLabel(parent, T("Addon Name"), 9.5, "white")
    component_name_label:SetPoint("LEFT", component_type_dropdown, "RIGHT", 10, 0)

    local component_name_entry = DF:CreateTextEntry(parent, function() end, 250, 18)
    component_name_entry:SetTemplate(options_button_template)
    component_name_entry:SetPoint("LEFT", component_name_label, "RIGHT", 5, 0)
    component_name_entry:SetHook("OnEditFocusGained", function(self)
        component_name_entry.AddonAutoCompleteList = NSRT.NSUI.AutoComplete["Addon"] or {}
        local component_type = component_type_dropdown:GetValue()
        if component_type == "Addon" then
            component_name_entry:SetAsAutoComplete("AddonAutoCompleteList", nil, true)
        end
    end)

    local version_check_button = DF:CreateButton(parent, function()
    end, 120, 18, T("Check Versions"))
    version_check_button:SetTemplate(options_button_template)
    version_check_button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -40)
    version_check_button:SetHook("OnShow", function(self)
        if (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or NSRT.Settings["Debug"]) then
            self:Enable()
        else
            self:Disable()
        end
    end)

    local encounterSelectors = CreateFrame("Frame", nil, parent)
    encounterSelectors:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -68)
    encounterSelectors:SetSize(content_width - 40, 22)
    encounterSelectors:Hide()

    local encounterLabel = DF:CreateLabel(encounterSelectors, T("Encounter"), 9.5, "white")
    encounterLabel:SetPoint("LEFT", encounterSelectors, "LEFT", 0, 0)
    local alertDropdown
    local function BuildAlertOptions()
        local options = {}
        local alerts = NSRT.EncounterAlerts[selectedEncID] and NSRT.EncounterAlerts[selectedEncID][selectedDiffID]
        for alertKey, alert in pairs(alerts or {}) do
            local name = alert.name or T("Unnamed")
            options[#options + 1] = {
                label = alert.group and (alert.group .. " - " .. name) or name,
                value = alert.internalID or alertKey,
                onclick = function(dropdown, fixedValue, value) selectedAlertID = value end,
            }
        end
        table.sort(options, function(a, b)
            if a.label == b.label then return a.value < b.value end
            return a.label < b.label
        end)
        return options
    end

    local function RefreshAlertSelection(internalID)
        local options = BuildAlertOptions()
        selectedAlertID = internalID or (options[1] and options[1].value)
        local selectedIndex
        for index, option in ipairs(options) do
            if option.value == selectedAlertID then
                selectedIndex = index
                break
            end
        end
        alertDropdown:Refresh()
        alertDropdown:Select(selectedIndex or false, true)
    end

    local encounterDropdown = DF:CreateDropDown(encounterSelectors, function()
        return NSI.UI.BossData.BuildBossDropdownOptions(function(value)
            selectedEncID = value
            RefreshAlertSelection()
        end, false)
    end, nil, 230)
    encounterDropdown:SetTemplate(options_dropdown_template)
    encounterDropdown:SetPoint("LEFT", encounterLabel, "RIGHT", 5, 0)

    local difficultyLabel = DF:CreateLabel(encounterSelectors, T("Difficulty"), 9.5, "white")
    difficultyLabel:SetPoint("LEFT", encounterDropdown, "RIGHT", 10, 0)
    local difficultyDropdown = DF:CreateDropDown(encounterSelectors, function()
        local options = {}
        for index, difficulty in ipairs({{16, "Mythic"}, {15, "Heroic"}, {14, "Normal"}}) do
            options[index] = {
                label = T(difficulty[2]), value = difficulty[1],
                onclick = function(dropdown, fixedValue, value)
                    selectedDiffID = value
                    RefreshAlertSelection()
                end,
            }
        end
        return options
    end, selectedDiffID, 100)
    difficultyDropdown:SetTemplate(options_dropdown_template)
    difficultyDropdown:SetPoint("LEFT", difficultyLabel, "RIGHT", 5, 0)

    local alertLabel = DF:CreateLabel(encounterSelectors, T("Alert"), 9.5, "white")
    alertLabel:SetPoint("LEFT", difficultyDropdown, "RIGHT", 10, 0)
    alertDropdown = DF:CreateDropDown(encounterSelectors, BuildAlertOptions, nil, 300)
    alertDropdown:SetTemplate(options_dropdown_template)
    alertDropdown:SetNoOptionsText(T("No alerts available"))
    alertDropdown:SetEmptyTextAndIcon(T("Alert Missing"))
    alertDropdown:SetPoint("LEFT", alertLabel, "RIGHT", 5, 0)

    local character_name_header = DF:CreateLabel(parent, T("Character Name"), 11)
    character_name_header:SetPoint("TOPLEFT", component_type_label, "BOTTOMLEFT", 10, -20)

    local version_number_header = DF:CreateLabel(parent, T("Version Number"), 11)
    version_number_header:SetPoint("LEFT", character_name_header, "RIGHT", 120, 0)

    local ignore_header = DF:CreateLabel(parent, T("Ignore Check"), 11)
    ignore_header:SetPoint("LEFT", version_number_header, "RIGHT", 50, 0)

    local function RebuildNameMap(scrollbox)
        wipe(scrollbox.name_map)
        for index, data in ipairs(scrollbox:GetData()) do
            if data.name then
                scrollbox.name_map[data.name] = index
            end
        end
    end

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local thisData = data[index]
            local line = self:GetLine(i)
            if thisData then
                local name = thisData.name
                local version = thisData.version
                local ignore = thisData.ignoreCheck
                local nickname = NSAPI:Shorten(name)

                line.name:SetText(nickname)
                line.version:SetText(version and T(version) or "")
                line.ignorelist:SetText(ignore and T("Yes") or T("No"))

                if version and version == "Offline" then
                    line.version:SetTextColor(unpack(STYLE.text_hint))
                elseif version == "Alert Missing" then
                    line.version:SetTextColor(1, 0.65, 0, 1)
                elseif version and NSI.VersionCheckData and version == NSI.VersionCheckData.version then
                    line.version:SetTextColor(0, 1, 0, 1)
                else
                    line.version:SetTextColor(1, 0, 0, 1)
                end

                if ignore then
                    line.ignorelist:SetTextColor(1, 0, 0, 1)
                else
                    line.ignorelist:SetTextColor(0, 1, 0, 1)
                end

                line:SetScript("OnClick", function(self)
                    local message = ""
                    local now = GetTime()
                    if (NSI.VersionCheckData.lastclick[name] and now < NSI.VersionCheckData.lastclick[name] + 5) or (thisData.version == NSI.VersionCheckData.version and (not thisData.ignoreCheck)) or thisData.version == "No Response" then return end
                    NSI.VersionCheckData.lastclick[name] = now
                    if NSI.VersionCheckData.type == "Addon" then
                        if thisData.version == "Addon not enabled" then message = "Please enable the Addon: '"..NSI.VersionCheckData.name.."'"
                        elseif thisData.version == "Addon Missing" then message = "Please install the Addon: '"..NSI.VersionCheckData.name.."'"
                        else message = "Please update the Addon: '"..NSI.VersionCheckData.name.."'" end
                    elseif NSI.VersionCheckData.type == "Note" then
                        if thisData.version == "MRT not enabled" then message = "Please enable MRT"
                        elseif thisData.version == "MRT not installed" then message = "Please install MRT"
                        else return end
                    end
                    if thisData.ignoreCheck then
                        if message == "" then
                            message = "You have someone from the raid on your ignore list. Please remove them fron the list."
                        else
                            message = message.." You also have someone from the raid on your ignore list."
                        end
                    end
                    NSI.VersionCheckData.lastclick[name] = GetTime()
                    if message ~= "" then SendChatMessage(message, "WHISPER", nil, name) end
                end)
            elseif line then
                line.name:SetText("")
                line.version:SetText("")
                line.ignorelist:SetText("")
                line.version:SetTextColor(unpack(STYLE.text_color))
                line.ignorelist:SetTextColor(unpack(STYLE.text_color))
                line:SetScript("OnClick", nil)
            end
        end
    end

    local function createLineFunc(self, index)
        local line = NSI.UI.Pixel.CreateBoxFrame("button", "$parentLine" .. index, self)
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index-1) * self.LineHeight) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)
        DF:CreateHighlightTexture(line)
        line.index = index

        local name = line:CreateFontString(nil, "OVERLAY")
        name:SetWidth(100)
        name:SetJustifyH("LEFT")
        NSI:SetUIFont(name, "small")
        name:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.name = name

        local version = line:CreateFontString(nil, "OVERLAY")
        version:SetWidth(100)
        version:SetJustifyH("LEFT")
        NSI:SetUIFont(version, "small")
        version:SetPoint("LEFT", name, "RIGHT", 115, 0)
        line.version = version

        local ignorelist = line:CreateFontString(nil, "OVERLAY")
        ignorelist:SetWidth(100)
        ignorelist:SetJustifyH("LEFT")
        NSI:SetUIFont(ignorelist, "small")
        ignorelist:SetPoint("LEFT", version, "RIGHT", 50, 0)
        line.ignorelist = ignorelist

        return line
    end

    local scrollLines = 22
    local sample_data = {
        { name = "Player1",  version = "1.0.0" },
        { name = "Player2",  version = "1.0.5" },
        { name = "Player3",  version = "1.0.1" },
        { name = "Player4",  version = "0.9.9" },
        { name = "Player5",  version = "1.0.0" },
        { name = "Player6",  version = "Addon Missing" },
        { name = "Player7",  version = "1.0.0" },
        { name = "Player8",  version = "0.9.8" },
        { name = "Player9",  version = "1.0.0" },
        { name = "Player10", version = "Note Missing" },
        { name = "Player11", version = "1.0.0" },
        { name = "Player12", version = "0.9.9" },
        { name = "Player13", version = "1.0.0" },
        { name = "Player14", version = "Note Missing" },
        { name = "Player15", version = "1.0.0" },
        { name = "Player16", version = "0.9.7" },
        { name = "Player17", version = "1.0.0" },
        { name = "Player18", version = "Addon Missing" },
        { name = "Player19", version = "1.0.0" },
        { name = "Player20", version = "0.9.9" }
    }
    local version_check_scrollbox = DF:CreateScrollBox(parent, "VersionCheckScrollBox", refresh, {},
        content_width - 36,
        tab_content_height - 90, scrollLines, 20, createLineFunc)
    DF:ReskinSlider(version_check_scrollbox)
    version_check_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -80)
    for i = 1, scrollLines do
        version_check_scrollbox:CreateLine(createLineFunc)
    end
    version_check_scrollbox:Refresh()

    version_check_scrollbox.name_map = {}
    local addData = function(self, data, url)
        local currentData = self:GetData()
        local index = self.name_map[data.name]
        local matches = NSI.VersionCheckData and data.version == NSI.VersionCheckData.version
        if NSRT.Settings["VersionCheckRemoveResponse"] and matches and data.name ~= UnitName("player")
            and data.version ~= "Addon Missing" and data.version ~= "Note Missing" and data.version ~= "Reminder Missing"
            and data.version ~= "Alert Missing" and not data.ignoreCheck then
            if index then table.remove(currentData, index) end
        elseif index then
            currentData[index] = data
        else
            tinsert(currentData, data)
        end
        RebuildNameMap(self)
        self:Refresh()
    end

    local wipeData = function(self)
        self:SetData({})
        wipe(self.name_map)
        self:Refresh()
    end

    version_check_scrollbox.AddData = addData
    version_check_scrollbox.WipeData = wipeData

    UpdateComponentType = function()
        local isEncounterAlert = component_type_dropdown:GetValue() == "Encounter Alert"
        component_name_label:SetShown(not isEncounterAlert)
        component_name_entry:SetShown(not isEncounterAlert)
        encounterSelectors:SetShown(isEncounterAlert)
        version_number_header:SetText(T(isEncounterAlert and "Enabled Status" or "Version Number"))
        local extraHeight = isEncounterAlert and 30 or 0
        character_name_header:ClearAllPoints()
        character_name_header:SetPoint("TOPLEFT", component_type_label, "BOTTOMLEFT", 10, -20 - extraHeight)
        version_check_scrollbox:ClearAllPoints()
        version_check_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -80 - extraHeight)
        version_check_scrollbox:SetHeight(tab_content_height - 90 - extraHeight)
        version_check_scrollbox:SetNumFramesShown(isEncounterAlert and 20 or scrollLines)
        version_check_scrollbox:Refresh()
        if isEncounterAlert then
            if not selectedEncID then
                local encounters = NSI.UI.BossData.BuildBossDropdownOptions(nil, false)
                selectedEncID = encounters[1] and encounters[1].value
            end
            encounterDropdown:Select(selectedEncID or false)
            difficultyDropdown:Select(selectedDiffID)
            RefreshAlertSelection(selectedAlertID)
        end
    end

    local function SelectEncounterAlert(encID, diffID, internalID)
        selectedEncID, selectedDiffID, selectedAlertID = encID, diffID, internalID
        component_type_dropdown:Select("Encounter Alert")
        UpdateComponentType()
    end

    local function RunVersionCheck()
        local text = component_name_entry:GetText()
        local component_type = component_type_dropdown:GetValue()
        if component_type == "Encounter Alert" then
            if not selectedEncID or not selectedDiffID or not selectedAlertID then return end
            text = selectedAlertID
        elseif text and text ~= "" and component_type == "Addon" and not tContains(NSRT.NSUI.AutoComplete[component_type], text) then
            tinsert(NSRT.NSUI.AutoComplete[component_type], text)
        end

        if not text or text == "" and component_type ~= "Note" and component_type ~= "Reminder" then return end

        local now = GetTime()
        if NSI.LastVersionCheck and NSI.LastVersionCheck > now-2 then return end
        NSI.LastVersionCheck = now
        version_check_scrollbox:WipeData()
        local userData, url = NSI:RequestVersionNumber(component_type, text, selectedEncID, selectedDiffID)
        if userData then
            version_check_scrollbox:AddData(userData, url)
        end
    end

    version_check_button:SetScript("OnClick", RunVersionCheck)
    version_check_scrollbox.CheckEncounterAlert = function(self, encID, diffID, internalID)
        if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then return end
        SelectEncounterAlert(encID, diffID, internalID)
        RunVersionCheck()
    end

    -- version check presets
    local preset_label = DF:CreateLabel(parent, T("Preset:"), 9.5, "white")

    local sample_presets = {
        { "Addon: Plater",                            { "Addon", "Plater" } }
    }

    local function build_version_check_presets_options()
        NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or {}
        local t = {}
        for i = 1, #NSRT.Settings["VersionCheckPresets"] do
            local v = NSRT.Settings["VersionCheckPresets"][i]
            tinsert(t, {
                label = v[1],
                value = v[2],
                onclick = function(dropdown, fixedValue, value)
                    if value[1] == "Encounter Alert" then
                        SelectEncounterAlert(value[3], value[4], value[2])
                    else
                        component_type_dropdown:Select(value[1])
                        component_name_entry:SetText(value[2])
                        UpdateComponentType()
                    end
                end
            })
        end
        return t
    end
    local version_check_preset_dropdown = DF:CreateDropDown(parent,
        function() return build_version_check_presets_options() end)
    version_check_preset_dropdown:SetTemplate(options_dropdown_template)

    local version_presets_edit_frame = DF:CreateSimplePanel(parent, 400, window_height / 2, T("Version Preset Management"),
        "VersionPresetsEditFrame", {
            DontRightClickClose = true,
            NoScripts = true
        })
    version_presets_edit_frame:ClearAllPoints()
    version_presets_edit_frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 2)
    version_presets_edit_frame:Hide()

    local version_presets_edit_button = DF:CreateButton(parent, function()
        if version_presets_edit_frame:IsShown() then
            version_presets_edit_frame:Hide()
        else
            version_presets_edit_frame:Show()
        end
    end, 120, 18, T("Edit Version Presets"))
    version_presets_edit_button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -10)
    version_presets_edit_button:SetTemplate(options_button_template)
    version_check_preset_dropdown:SetPoint("RIGHT", version_presets_edit_button, "LEFT", -10, 0)
    preset_label:SetPoint("RIGHT", version_check_preset_dropdown, "LEFT", -5, 0)

    local function refreshPresets(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local presetData = data[index]
            if presetData then
                local line = self:GetLine(i)

                local label = presetData[1]
                local value = presetData[2]
                local component_type = value[1]
                local component_name = value[2]

                line.index = index

                line.value = value
                line.component_type = component_type
                line.component_name = component_name

                line.type:SetText(T(component_type))
                line.name:SetText(component_type == "Encounter Alert" and label or component_name)
            end
        end
    end

    local function createPresetLineFunc(self, index)
        local parent = self
        local line = NSI.UI.Pixel.CreateBoxFrame("Frame", "$parentLine" .. index, self)
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.type = DF:CreateLabel(line, "", 9.5, "white")
        line.type:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.type:SetTemplate(options_text_template)

        line.name = DF:CreateLabel(line, "", 9.5, "white")
        line.name:SetTemplate(options_text_template)
        line.name:SetPoint("LEFT", line, "LEFT", 110, 0)
        line.name:SetWidth(225)

        line.deleteButton = DF:CreateButton(line, function()
            tremove(NSRT.Settings["VersionCheckPresets"], line.index)
            self:SetData(NSRT.Settings["VersionCheckPresets"])
            self:Refresh()
            version_check_preset_dropdown:Refresh()
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

    local presetScrollLines = 9
    local version_presets_edit_scrollbox = DF:CreateScrollBox(version_presets_edit_frame,
        "$parentVersionPresetsEditScrollBox", refreshPresets, NSRT.Settings["VersionCheckPresets"], 360,
        window_height / 2 - 75, presetScrollLines, 20, createPresetLineFunc)
    version_presets_edit_scrollbox:SetPoint("TOPLEFT", version_presets_edit_frame, "TOPLEFT", 10, -30)
    DF:ReskinSlider(version_presets_edit_scrollbox)

    for i = 1, presetScrollLines do
        version_presets_edit_scrollbox:CreateLine(createPresetLineFunc)
    end

    version_presets_edit_scrollbox:Refresh()

    local new_preset_type_label = DF:CreateLabel(version_presets_edit_frame, T("Type:"), 11)
    new_preset_type_label:SetPoint("TOPLEFT", version_presets_edit_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_preset_type_dropdown = DF:CreateDropDown(version_presets_edit_frame,
        function() return build_checkable_components_options(nil, true) end, checkable_components[1], 65)
    new_preset_type_dropdown.addonId = addonId
    new_preset_type_dropdown:Select(checkable_components[1])
    new_preset_type_dropdown:SetPoint("LEFT", new_preset_type_label, "RIGHT", 5, 0)
    new_preset_type_dropdown:SetTemplate(options_dropdown_template)

    local new_preset_name_label = DF:CreateLabel(version_presets_edit_frame, T("Name:"), 11)
    new_preset_name_label:SetPoint("LEFT", new_preset_type_dropdown, "RIGHT", 10, 0)

    local new_preset_name_entry = DF:CreateTextEntry(version_presets_edit_frame, function() end, 165, 20)
    new_preset_name_entry:SetPoint("LEFT", new_preset_name_label, "RIGHT", 5, 0)
    new_preset_name_entry:SetTemplate(options_dropdown_template)

    local add_button = DF:CreateButton(version_presets_edit_frame, function()
        local name = new_preset_name_entry:GetText()
        local type = new_preset_type_dropdown:GetValue()
        tinsert(NSRT.Settings["VersionCheckPresets"], { T(type) .. ": " .. name, {type, name} })
        version_presets_edit_scrollbox:SetData(NSRT.Settings["VersionCheckPresets"])
        version_presets_edit_scrollbox:Refresh()
        version_check_preset_dropdown:Refresh()
        new_preset_name_entry:SetText("")
        new_preset_type_dropdown:Select(checkable_components[1])
    end, 60, 20, T("New"))
    add_button:SetPoint("LEFT", new_preset_name_entry, "RIGHT", 10, 0)
    add_button:SetTemplate(options_button_template)
    UpdateComponentType()
    return version_check_scrollbox
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.VersionCheck = {
    BuildVersionCheckUI = BuildVersionCheckUI,
}
