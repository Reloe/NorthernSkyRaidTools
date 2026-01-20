local _, NSI = ... -- Internal namespace
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

local window_width = 1050
local window_height = 620
local expressway = [[Interface\AddOns\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]

local TABS_LIST = {
    { name = "General",   text = "General" },
    { name = "Nicknames", text = "Nicknames" },
    { name = "Versions",  text = "Versions" },
    { name = "SetupManager", text = "Setup Manager"},
    { name = "ReadyCheck", text = "Ready Check"},
    { name = "Reminders", text = "Reminders"},
    { name = "Reminders-Note", text = "Reminders-Note"},
    { name = "Assignments", text = "Assignments"},
    { name = "EncounterAlerts", text = "Encounter Alerts"},
    { name = "PrivateAura", text = "Private Auras"},
    { name = "Timeline", text = "Timeline"},
}
local authorsString = "By Reloe & Rav"

local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

local NSUI_panel_options = {
    UseStatusBar = true
}
local NSUI = DF:CreateSimplePanel(UIParent, window_width, window_height, "|cFF00FFFFNorthern Sky|r Raid Tools", "NSUI",
    NSUI_panel_options)
NSUI:SetPoint("CENTER")
NSUI:SetFrameStrata("HIGH")
-- local statusbar_text = DF:CreateLabel(NSUI.StatusBar, "Northern Sky x |cFF00FFFFbird|r")
-- statusbar_text:SetPoint("left", NSUI.StatusBar, "left", 2, 0)
DF:BuildStatusbarAuthorInfo(NSUI.StatusBar, _, "x |cFF00FFFFbird|r")
NSUI.StatusBar.discordTextEntry:SetText("https://discord.gg/3B6QHURmBy")

NSUI.OptionsChanged = {
    ["general"] = {},
    ["nicknames"] = {},
    ["versions"] = {},
}

-- version check ui
local component_type = "Addon"
local checkable_components = {"Addon", "Note", "Reminder"}
local function build_checkable_components_options()
    local t = {}
    for i = 1, #checkable_components do
        tinsert(t, {
            label = checkable_components[i],
            value = checkable_components[i],
            onclick = function(_, _, value)
                component_type = value
            end
        })
    end
    return t
end



local component_name = ""
local function BuildVersionCheckUI(parent)

    local hide_version_response_button = DF:CreateSwitch(parent,
        function(self, _, value) NSRT.Settings["VersionCheckRemoveResponse"] = value end,
        NSRT.Settings["VersionCheckRemoveResponse"], 20, 20, nil, nil, nil, "VersionCheckResponseToggle", nil, nil, nil,
        "Hide Version Check Responses", options_switch_template, options_text_template)
    hide_version_response_button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -100)
    hide_version_response_button:SetAsCheckBox()
    hide_version_response_button:SetTooltip(
        "Hides Version Check Responses of Users that are on the correct version")
    local hide_version_response_label = DF:CreateLabel(parent, "Hide Version Check Responses", 10, "white", "", nil,
        "VersionCheckResponseLabel", "overlay")
    hide_version_response_label:SetTemplate(options_text_template)
    hide_version_response_label:SetPoint("LEFT", hide_version_response_button, "RIGHT", 2, 0)
    local component_type_label = DF:CreateLabel(parent, "Component Type", 9.5, "white")
    component_type_label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -130)
    
    local component_type_dropdown = DF:CreateDropDown(parent, function() return build_checkable_components_options() end, checkable_components[1])
    component_type_dropdown:SetTemplate(options_dropdown_template)
    component_type_dropdown:SetPoint("LEFT", component_type_label, "RIGHT", 5, 0)

    local component_name_label = DF:CreateLabel(parent, "Addon Name", 9.5, "white")
    component_name_label:SetPoint("LEFT", component_type_dropdown, "RIGHT", 10, 0)

    local component_name_entry = DF:CreateTextEntry(parent, function(_, _, value) component_name = value end, 250, 18)
    component_name_entry:SetTemplate(options_button_template)
    component_name_entry:SetPoint("LEFT", component_name_label, "RIGHT", 5, 0)
    component_name_entry:SetHook("OnEditFocusGained", function(self)
        component_name_entry.AddonAutoCompleteList = NSRT.NSUI.AutoComplete["Addon"] or {}
        local component_type = component_type_dropdown:GetValue()
        if component_type == "Addon" then
            component_name_entry:SetAsAutoComplete("AddonAutoCompleteList", _, true)
        end
    end)

    local version_check_button = DF:CreateButton(parent, function()
    end, 120, 18, "Check Versions")
    version_check_button:SetTemplate(options_button_template)
    version_check_button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -130)
    version_check_button:SetHook("OnShow", function(self)
        if (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or NSRT.Settings["Debug"]) then
            self:Enable()
        else
            self:Disable()
        end
    end)

    local character_name_header = DF:CreateLabel(parent, "Character Name", 11)
    character_name_header:SetPoint("TOPLEFT", component_type_label, "BOTTOMLEFT", 10, -20)

    local version_number_header = DF:CreateLabel(parent, "Version Number", 11)
    version_number_header:SetPoint("LEFT", character_name_header, "RIGHT", 120, 0)

    local ignore_header = DF:CreateLabel(parent, "Ignore Check", 11)
    ignore_header:SetPoint("LEFT", version_number_header, "RIGHT", 50, 0)

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local thisData = data[index] -- thisData = {{name = "Ravxd", version = 1.0}}
            if thisData then
                local line = self:GetLine(i)

                local name = thisData.name
                local version = thisData.version
                local ignore = thisData.ignoreCheck
                local nickname = NSAPI:Shorten(name)

                line.name:SetText(nickname)
                line.version:SetText(version)
                line.ignorelist:SetText(ignore and "Yes" or "No")

                -- version number color                
                if version and version == "Offline" then
                    line.version:SetTextColor(0.5, 0.5, 0.5, 1)
                elseif version and data[1] and data[1].version and version == data[1].version then
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
                    SendChatMessage(message, "WHISPER", nil, name)
                end)
            end
        end
    end

    local function createLineFunc(self, index)
        local line = CreateFrame("button", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index-1) * (self.LineHeight+1)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)
        DF:CreateHighlightTexture(line)
        line.index = index

        local name = line:CreateFontString(nil, "OVERLAY")
        name:SetWidth(100)
        name:SetJustifyH("LEFT")
        name:SetFont(expressway, 12, "OUTLINE")
        name:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.name = name

        local version = line:CreateFontString(nil, "OVERLAY")
        version:SetWidth(100)
        version:SetJustifyH("LEFT")
        version:SetFont(expressway, 12, "OUTLINE")
        version:SetPoint("LEFT", name, "RIGHT", 115, 0)
        line.version = version
        
        local ignorelist = line:CreateFontString(nil, "OVERLAY")
        ignorelist:SetWidth(100)
        ignorelist:SetJustifyH("LEFT")
        ignorelist:SetFont(expressway, 12, "OUTLINE")
        ignorelist:SetPoint("LEFT", version, "RIGHT", 50, 0)
        line.ignorelist = ignorelist

        return line
    end

    local scrollLines = 19
    -- sample data for testing
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
        window_width - 40,
        window_height - 200, scrollLines, 20, createLineFunc)
    DF:ReskinSlider(version_check_scrollbox)
    version_check_scrollbox.ReajustNumFrames = true
    version_check_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -170)
    for i = 1, scrollLines do
        version_check_scrollbox:CreateLine(createLineFunc)
    end
    version_check_scrollbox:Refresh()

    version_check_scrollbox.name_map = {}
    local addData = function(self, data, url)
        local currentData = self:GetData() -- currentData = {{name, version}...}
        if self.name_map[data.name] then
            if NSRT.Settings["VersionCheckRemoveResponse"] and currentData[1] and currentData[1].version and data.version and data.version == currentData[1].version and data.version ~= "Addon Missing" and data.version ~= "Note Missing" and data.version ~= "Reminder Missing" and (not data.ignoreCheck) then
                table.remove(currentData, self.name_map[data.name])
                for k, v in pairs(self.name_map) do
                    if v > self.name_map[data.name] then
                        self.name_map[k] = v - 1
                    end
                end
            else
                currentData[self.name_map[data.name]] = data
            end
        else
            self.name_map[data.name] = #currentData + 1
            tinsert(currentData, data)
        end
        self:Refresh()
    end

    local wipeData = function(self)
        self:SetData({})
        wipe(self.name_map)
        self:Refresh()
    end

    version_check_scrollbox.AddData = addData
    version_check_scrollbox.WipeData = wipeData

    version_check_button:SetScript("OnClick", function(self)
        
        local text = component_name_entry:GetText()
        local component_type = component_type_dropdown:GetValue()
        if text and text ~= ""  and component_type ~= "Note" and component_type ~= "Reminder" and not tContains(NSRT.NSUI.AutoComplete[component_type], text) then
            tinsert(NSRT.NSUI.AutoComplete[component_type], text)
        end

        if not text or text == "" and component_type ~= "Note" and component_type ~= "Reminder" then return end
        
        local now = GetTime()
        if NSI.LastVersionCheck and NSI.LastVersionCheck > now-2 then return end -- don't let user spam requests
        NSI.LastVersionCheck = now
        version_check_scrollbox:WipeData()
        local userData, url = NSI:RequestVersionNumber(component_type, text)
        if userData then
            NSI.VersionCheckData = { version = userData.version, type = component_type, name = text, url = url, lastclick = {} }
            version_check_scrollbox:AddData(userData, url)
        end
    end)

    -- version check presets
    local preset_label = DF:CreateLabel(parent, "Preset:", 9.5, "white")

    local sample_presets = {
        { "Addon: Plater",                            { "Addon", "Plater" } }
    }

    local function build_version_check_presets_options()
        NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or
            {} -- structure will be {{label, {type, name}}}
        local t = {}
        for i = 1, #NSRT.Settings["VersionCheckPresets"] do
            local v = NSRT.Settings["VersionCheckPresets"][i]
            tinsert(t, {
                label = v[1], -- label
                value = v[2], -- {type, name}
                onclick = function(_, _, value)
                    component_type_dropdown:Select(value[1])
                    component_name_entry:SetText(value[2])
                end
            })
        end
        return t
    end
    local version_check_preset_dropdown = DF:CreateDropDown(parent,
        function() return build_version_check_presets_options() end)
    version_check_preset_dropdown:SetTemplate(options_dropdown_template)

    local version_presets_edit_frame = DF:CreateSimplePanel(parent, 400, window_height / 2, "Version Preset Management",
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
    end, 120, 18, "Edit Version Presets")
    version_presets_edit_button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -100)
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

                line.type:SetText(component_type)
                line.name:SetText(component_name)
            end
        end
    end

    local function createPresetLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        -- Type Dropdown
        line.type = DF:CreateLabel(line, "", 9.5, "white")
        line.type:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.type:SetTemplate(options_text_template)

        -- Name text
        line.name = DF:CreateLabel(line, "", 9.5, "white")
        line.name:SetTemplate(options_text_template)
        line.name:SetPoint("LEFT", line, "LEFT", 50, 0)

        -- Delete button
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
        -- line.deleteButton:SetFontFace(expressway)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        return line
    end

    local presetScrollLines = 9
    local version_presets_edit_scrollbox = DF:CreateScrollBox(version_presets_edit_frame,
        "$parentVersionPresetsEditScrollBox", refreshPresets, NSRT.Settings["VersionCheckPresets"], 360,
        window_height / 2 - 75, presetScrollLines, 20, createPresetLineFunc)
    version_presets_edit_scrollbox:SetPoint("TOPLEFT", version_presets_edit_frame, "TOPLEFT", 10, -30)
    -- version_presets_edit_scrollbox:SetPoint("BOTTOMRIGHT", version_presets_edit_frame, "BOTTOMRIGHT", -25, 30)
    DF:ReskinSlider(version_presets_edit_scrollbox)

    for i = 1, presetScrollLines do
        version_presets_edit_scrollbox:CreateLine(createPresetLineFunc)
    end

    version_presets_edit_scrollbox:Refresh()

    -- Add new preset
    local new_preset_type_label = DF:CreateLabel(version_presets_edit_frame, "Type:", 11)
    new_preset_type_label:SetPoint("TOPLEFT", version_presets_edit_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_preset_type_dropdown = DF:CreateDropDown(version_presets_edit_frame,
        function() return build_checkable_components_options() end, checkable_components[1], 65)
    new_preset_type_dropdown:SetPoint("LEFT", new_preset_type_label, "RIGHT", 5, 0)
    new_preset_type_dropdown:SetTemplate(options_dropdown_template)

    local new_preset_name_label = DF:CreateLabel(version_presets_edit_frame, "Name:", 11)
    new_preset_name_label:SetPoint("LEFT", new_preset_type_dropdown, "RIGHT", 10, 0)

    local new_preset_name_entry = DF:CreateTextEntry(version_presets_edit_frame, function() end, 165, 20)
    new_preset_name_entry:SetPoint("LEFT", new_preset_name_label, "RIGHT", 5, 0)
    new_preset_name_entry:SetTemplate(options_dropdown_template)

    local add_button = DF:CreateButton(version_presets_edit_frame, function()
        local name = new_preset_name_entry:GetText()
        local type = new_preset_type_dropdown:GetValue()
        tinsert(NSRT.Settings["VersionCheckPresets"], { type .. ": " .. name, { type, name } })
        version_presets_edit_scrollbox:SetData(NSRT.Settings["VersionCheckPresets"])
        version_presets_edit_scrollbox:Refresh()
        version_check_preset_dropdown:Refresh()
        new_preset_name_entry:SetText("")
        new_preset_type_dropdown:Select(checkable_components[1])
    end, 60, 20, "New")
    add_button:SetPoint("LEFT", new_preset_name_entry, "RIGHT", 10, 0)
    add_button:SetTemplate(options_button_template)
    return version_check_scrollbox
end

local function BuildNicknameEditUI()
    local nicknames_edit_frame = DF:CreateSimplePanel(UIParent, 485, 420, "Nicknames Management", "NicknamesEditFrame", {
        DontRightClickClose = true
    })
    nicknames_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local refresh_count = 0

    local function PrepareData(data)
        local data = {}
        for player, nickname in pairs(NSRT.NickNames) do
            tinsert(data, {player = player, nickname = nickname})
        end
        table.sort(data, function(a, b)
            return a.nickname < b.nickname
        end)
        return data
    end

    local function MasterRefresh(self) 
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end
    
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local nickData = data[index]
            if nickData then
                local line = self:GetLine(i)

                local player, realm = strsplit("-", nickData.player)
        
                line.fullName = nickData.player
                line.player = player
                line.realm = realm
                line.playerText.text = nickData.player
                line.nicknameEntry.text = nickData.nickname
                -- line:Show()
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index-1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        -- Player name text
        line.playerText = DF:CreateLabel(line, "")
        line.playerText:SetPoint("LEFT", line, "LEFT", 5, 0)
        
        -- Nickname text
        line.nicknameEntry = DF:CreateTextEntry(line, function(self, _, value) 
            NSI:AddNickName(line.player, line.realm, string.sub(value, 1, 12)) 
            line.nicknameEntry.text = string.sub(value, 1, 12)
            parent:MasterRefresh()
        end, 120, 20)
        line.nicknameEntry:SetTemplate(options_dropdown_template)
        line.nicknameEntry:SetPoint("LEFT", line, "LEFT", 185, 0)
        
        -- Delete button
        line.deleteButton = DF:CreateButton(line, function()
            NSI:AddNickName(line.player, line.realm, "")
            self:SetData(NSRT.NickNames)
            self:MasterRefresh()
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])

        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        -- line.deleteButton:SetFontFace(expressway)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)



        return line
    end

    local scrollLines = 15
    local nicknames_edit_scrollbox = DF:CreateScrollBox(nicknames_edit_frame, "$parentNicknameEditScrollBox", refresh, {}, 445, 300, scrollLines, 20, createLineFunc)
    nicknames_edit_frame.scrollbox = nicknames_edit_scrollbox
    nicknames_edit_scrollbox:SetPoint("TOPLEFT", nicknames_edit_frame, "TOPLEFT", 10, -50)
    nicknames_edit_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(nicknames_edit_scrollbox)

    for i = 1, scrollLines do
        nicknames_edit_scrollbox:CreateLine(createLineFunc)
    end

    local player_name_header = DF:CreateLabel(nicknames_edit_frame, "Player Name", 11)
    player_name_header:SetPoint("TOPLEFT", nicknames_edit_frame, "TOPLEFT", 20, -30)

    local nickname_header = DF:CreateLabel(nicknames_edit_frame, "Nickname", 11)
    nickname_header:SetPoint("TOPLEFT", nicknames_edit_frame, "TOPLEFT", 200, -30)


    nicknames_edit_scrollbox:SetScript("OnShow", function(self) 
        self:MasterRefresh() 
    end)

    -- Add new nickname section
    local new_player_label = DF:CreateLabel(nicknames_edit_frame, "New Player:", 11)
    new_player_label:SetPoint("TOPLEFT", nicknames_edit_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_player_entry = DF:CreateTextEntry(nicknames_edit_frame, function() end, 120, 20)
    new_player_entry:SetPoint("LEFT", new_player_label, "RIGHT", 10, 0)
    new_player_entry:SetTemplate(options_dropdown_template)

    local new_nickname_label = DF:CreateLabel(nicknames_edit_frame, "Nickname:", 11)
    new_nickname_label:SetPoint("LEFT", new_player_entry, "RIGHT", 10, 0)

    local new_nickname_entry = DF:CreateTextEntry(nicknames_edit_frame, function() end, 120, 20)
    new_nickname_entry:SetPoint("LEFT", new_nickname_label, "RIGHT", 10, 0)
    new_nickname_entry:SetTemplate(options_dropdown_template)

    local add_button = DF:CreateButton(nicknames_edit_frame, function()
        local name = new_player_entry:GetText()
        local nickname = new_nickname_entry:GetText()
        if player ~= "" and nickname ~= "" then
            local player, realm = strsplit("-", name)
            if not realm then
                realm = GetNormalizedRealmName()
            end
            NSI:AddNickName(player, realm, nickname)
            new_player_entry:SetText("")
            new_nickname_entry:SetText("")
            nicknames_edit_scrollbox:MasterRefresh()
        end
    end, 60, 20, "Add")
    add_button:SetPoint("LEFT", new_nickname_entry, "RIGHT", 10, 0)
    add_button:SetTemplate(options_button_template)

    local sync_button = DF:CreateButton(nicknames_edit_frame, function() NSI:SyncNickNames() end, 225, 20, "Sync Nicknames")
    sync_button:SetPoint("BOTTOMLEFT", nicknames_edit_frame, "BOTTOMLEFT", 10, 10)
    sync_button:SetTemplate(options_button_template)

    local function createImportPopup()
        local popup = DF:CreateSimplePanel(nicknames_edit_frame, 300, 150, "Import Nicknames", "ImportPopup", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", nicknames_edit_frame, "CENTER", 0, 0)
        popup:SetFrameLevel(100)

        popup.import_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ImportTextBox", true, false, true)
        popup.import_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.import_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.import_text_box)
        DF:ReskinSlider(popup.import_text_box.scroll)
        popup.import_text_box:SetFocus()

        popup.import_confirm_button = DF:CreateButton(popup, function()
            local import_string = popup.import_text_box:GetText()
            NSI:ImportNickNames(import_string)
            popup.import_text_box:SetText("")
            popup:Hide()
            nicknames_edit_scrollbox:MasterRefresh()
        end, 280, 20, "Import")
        popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
        popup.import_confirm_button:SetTemplate(options_button_template)

        popup:Hide()
        return popup
    end

    local import_popup = createImportPopup()
    local import_button = DF:CreateButton(nicknames_edit_frame, function() 
        if not import_popup:IsShown() then 
            import_popup:Show() 
        end 
    end, 225, 20, "Import Nicknames")
    import_button:SetPoint("BOTTOMRIGHT", nicknames_edit_frame, "BOTTOMRIGHT", -10, 10)
    import_button:SetTemplate(options_button_template)

    nicknames_edit_frame:Hide()
    return nicknames_edit_frame
end

-- build cooldown type options
local cooldown_types = { "Spell", "Item" }
local function build_cooldown_type_options()
    local t = {}
    for i = 1, #cooldown_types do
        tinsert(t, {
            label = cooldown_types[i],
            value = cooldown_types[i],
            onclick = function(_, _, value)
                cooldown_type = value
            end
        })
    end
    return t
end
local selected_spec = 268 -- Default to Brewmaster i guess
local function build_spec_options()
    local t = {}
    -- Group specs by class
    local classSpecs = NSI.CLASS_SPECIALIZATION_MAP

    -- Add specs sorted by class
    for className, specs in pairs(classSpecs) do
        for _, specId in pairs(specs) do
            tinsert(t, {
                label = NSI:SpecToName(specId),
                value = specId,
                className = className,
            })
        end
    end
    table.sort(t, 
                function(a, b) return a.className < b.className                               
            end)
    return t
end

local function ImportReminderString(name, IsUpdate)
    local popup = DF:CreateSimplePanel(NSUI, 800, 800, "Import Reminder String", "NSUIReminderImport", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ReminderTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetFocus()
    popup.test_string_text_box:SetText(name and NSRT.Reminders[name] or "")
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    popup.test_string_text_box.editbox:SetFont(expressway, 13, "OUTLINE")
    local importtext = IsUpdate and "Update" or "Import"
    popup.import_confirm_button = DF:CreateButton(popup, function()
        local import_string = popup.test_string_text_box:GetText()        
        if IsUpdate then
            NSI:ImportReminder(name, import_string, false, false, true)
        else
            NSI:ImportFullReminderString(import_string, false, false, name)
        end
        if IsUpdate and NSRT.ActiveReminder then
            NSI:SetReminder(NSRT.ActiveReminder) -- refresh active reminder
        end
        popup.test_string_text_box:SetText("")
        NSUI.reminders_frame:Hide()
        NSUI.reminders_frame:Show()
        popup:Hide()
    end, 280, 20, importtext)
    popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.import_confirm_button:SetTemplate(options_button_template)

    return popup
end

local function ImportPersonalReminderString(name, IsUpdate)
    local popup = DF:CreateSimplePanel(NSUI, 800, 800, "Import Personal Reminder String", "NSUIPersonalReminderImport", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "PersonalReminderTextEdit", true, false, true)
    popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
    DF:ApplyStandardBackdrop(popup.test_string_text_box)
    DF:ReskinSlider(popup.test_string_text_box.scroll)
    popup.test_string_text_box:SetFocus()
    popup.test_string_text_box:SetText(name and NSRT.PersonalReminders[name] or "")
    popup.test_string_text_box:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    popup.test_string_text_box.editbox:SetFont(expressway, 13, "OUTLINE")
    local importtext = IsUpdate and "Update" or "Import"
    popup.import_confirm_button = DF:CreateButton(popup, function()
        local import_string = popup.test_string_text_box:GetText()
        if IsUpdate then
            NSI:ImportReminder(name, import_string, false, true, true)
        else
            NSI:ImportFullReminderString(import_string, true, false, name)
        end
        if IsUpdate and NSRT.ActivePersonalReminder then
            NSI:SetReminder(NSRT.ActivePersonalReminder, true) -- refresh active personal reminder
        end
        popup.test_string_text_box:SetText("")
        NSUI.personal_reminders_frame:Hide()
        NSUI.personal_reminders_frame:Show()
        popup:Hide()
    end, 280, 20, importtext)
    popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
    popup.import_confirm_button:SetTemplate(options_button_template)

    return popup
end

local function BuildRemindersEditUI()
    local reminders_edit_frame = DF:CreateSimplePanel(UIParent, 460, 410, "Reminders Management", "RemindersEditFrame", {
        DontRightClickClose = true
    })
    reminders_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local function MasterRefresh(self)
        local data = NSI:GetAllReminderNames()
        self:SetData(data)
        self:Refresh()
    end
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local reminderData = data[index]
            if reminderData then
                local line = self:GetLine(i)
                line.name = reminderData.name
                line.nameTextEntry.text = reminderData.name
                if NSRT.InviteList[reminderData.name] then
                    line.InviteButton:Show()
                    line.ArrangeButton:Show()
                else
                    line.InviteButton:Hide()
                    line.ArrangeButton:Hide()
                end
            end
        end
    end
    
    local Active_Text = DF:CreateLabel(reminders_edit_frame, "Active Reminder", 11)
    Active_Text:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 50)
    Active_Text:SetWidth(380)
    if NSRT.ActiveReminder and NSRT.ActiveReminder ~= "" then
        Active_Text.text = "Active Reminder: |cFFFFFFFF" .. NSRT.ActiveReminder
    else
        Active_Text.text = "Active Reminder: |cFFFFFFFFNone"
    end

    -- Import Button
    local ImportButton = DF:CreateButton(reminders_edit_frame, function()
        ImportReminderString(nil, false)
        end, 100, 24, "Import Reminder"
    )
    ImportButton:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 10)
    ImportButton:SetTemplate(options_button_template)

    -- Clear Button
    local ClearButton = DF:CreateButton(reminders_edit_frame, function()       
        NSI:SetReminder(nil) 
        NSI:UpdateReminderFrame(false, true)
        Active_Text.text = "Active Reminder: |cFFFFFFFFNone"
        end, 100, 24, "Clear Reminder"
    )
    ClearButton:SetPoint("LEFT", ImportButton, "RIGHT", 5, 0)
    ClearButton:SetTemplate(options_button_template)

    -- Share Button
    local ShareButton = DF:CreateButton(reminders_edit_frame, function()
        NSI:Broadcast("NSI_REM_SHARE", "RAID", NSI.Reminder, NSRT.AssignmentSettings, true)
        NSI.LastBroadcast = GetTime()
    end, 100, 24, "Share Reminder"
    )
    ShareButton:SetPoint("LEFT", ClearButton, "RIGHT", 5, 0)
    ShareButton:SetTemplate(options_button_template)    

    local function DeleteBossReminder(self, line, all)
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Reminder Deletion", "NSRTDeleteReminderPopup")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = all and DF:CreateLabel(popup, "Are you sure you want to \ndelete ALL reminders?", 12, "orange") or DF:CreateLabel(popup,
            "Are you sure you want to \ndelete this reminder?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            if line and NSRT.ActiveReminder and NSRT.ActiveReminder == line.name then
                Active_Text.text = "Active Reminder: |cFFFFFFFFNone"
            end
            if all then
                for _, reminder in ipairs(NSI:GetAllReminderNames()) do
                    NSI:RemoveReminder(reminder.name)
                end
            else
                NSI:RemoveReminder(line.name)
            end
            self:SetData(NSI:GetAllReminderNames())
            self:MasterRefresh()
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, "Cancel")
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end
    
    local alldeletecreated = false
    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)
        
        if not alldeletecreated then
            alldeletecreated = true
            -- Delete All Button
            local DeleteAllButton = DF:CreateButton(reminders_edit_frame, function()
                DeleteBossReminder(self, line, true)
                end, 100, 24, "Delete ALL Reminders"
            )
            DeleteAllButton:SetPoint("LEFT", ShareButton, "RIGHT", 5, 0)
            DeleteAllButton:SetTemplate(options_button_template)
        end       

        line.nameTextEntry = DF:CreateTextEntry(line, function() end, line:GetWidth()-210, line:GetHeight())
        line.nameTextEntry:SetTemplate(options_dropdown_template)
        line.nameTextEntry:SetPoint("LEFT", line, "LEFT", 0, 0)
        line.nameTextEntry:SetScript("OnEnterPressed", function(self)
            local oldname = line.name
            if not oldname then return end
            local newname = self:GetText()
            if oldname == newname then return end
            if NSRT.Reminders[newname] then return end -- if name already exists, do nothing
            NSRT.Reminders[newname] = NSRT.Reminders[oldname]
            NSRT.InviteList[newname] = NSRT.InviteList[oldname]
            if NSRT.ActiveReminder == oldname then
                Active_Text.text = "Active Reminder: |cFFFFFFFF" .. newname
                NSRT.ActiveReminder = newname
            end
            NSRT.Reminders[oldname] = nil
            NSRT.InviteList[oldname] = nil
            line.name = newname
            parent:MasterRefresh()
        end)
        
        -- Delete button
        line.deleteButton = DF:CreateButton(line, function()
            DeleteBossReminder(self, line, false)
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        -- Load Button
        line.LoadButton = DF:CreateButton(line, function()
            local name = line.nameTextEntry:GetText()
            if name ~= "" then
                NSI:SetReminder(name)
                Active_Text.text = "Active Reminder: |cFFFFFFFF" .. name
                NSI:UpdateReminderFrame(false, true)
            end
        end, 40, 20, "Load")
        line.LoadButton:SetPoint("RIGHT", line.deleteButton, "LEFT", 0, 0)
        line.LoadButton:SetTemplate(options_button_template)

        -- Show Button
        line.ShowButton = DF:CreateButton(line, function()
            local name = line.nameTextEntry:GetText()
            ImportReminderString(name, true)
        end, 40, 20, "Show")
        line.ShowButton:SetPoint("RIGHT", line.LoadButton, "LEFT", 0, 0)
        line.ShowButton:SetTemplate(options_button_template)
        -- Invite Button
        line.InviteButton = DF:CreateButton(line, function(self)
            NSI:InviteFromReminder(line.name, true)
        end, 40, 20, "Invite")
        line.InviteButton:SetPoint("RIGHT", line.ShowButton, "LEFT", 0, 0)
        line.InviteButton:SetTemplate(options_button_template)

        -- Group Arrange Button
        line.ArrangeButton = DF:CreateButton(line, function(self)
            NSI:ArrangeFromReminder(line.name)     
        end, 40, 20, "Arrange")
        line.ArrangeButton:SetPoint("RIGHT", line.InviteButton, "LEFT", 0, 0)
        line.ArrangeButton:SetTemplate(options_button_template)
        return line
    end

    local scrollLines = 15
    local reminders_edit_scrollbox = DF:CreateScrollBox(reminders_edit_frame, "$parentRemindersEditScrollBox", refresh,
        {},
        420, 300, scrollLines, 20, createLineFunc)
    reminders_edit_frame.scrollbox = reminders_edit_scrollbox
    reminders_edit_scrollbox:SetPoint("TOPLEFT", reminders_edit_frame, "TOPLEFT", 10, -40)
    reminders_edit_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(reminders_edit_scrollbox)
    reminders_edit_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    for i = 1, scrollLines do
        reminders_edit_scrollbox:CreateLine(createLineFunc)
    end

    reminders_edit_frame:Hide()
    return reminders_edit_frame
end

local function BuildPersonalRemindersEditUI()
    local reminders_edit_frame = DF:CreateSimplePanel(UIParent, 460, 410, "Personal Reminders Management", "RemindersEditFrame", {
        DontRightClickClose = true
    })
    reminders_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local function MasterRefresh(self)
        local data = NSI:GetAllReminderNames(true)
        self:SetData(data)
        self:Refresh()
    end
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local reminderData = data[index]
            if reminderData then
                local line = self:GetLine(i)
                line.name = reminderData.name
                line.nameTextEntry.text = reminderData.name
            end
        end
    end
    
    local Active_Text = DF:CreateLabel(reminders_edit_frame, "Active Personal Reminder", 11)
    Active_Text:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 50)
    Active_Text:SetWidth(380)
    if NSRT.ActivePersonalReminder and NSRT.ActivePersonalReminder ~= "" then
        Active_Text.text = "Active Personal Reminder: |cFFFFFFFF" .. NSRT.ActivePersonalReminder
    else
        Active_Text.text = "Active Personal Reminder: |cFFFFFFFFNone"
    end

    -- Import Button
    local ImportButton = DF:CreateButton(reminders_edit_frame, function()
        ImportPersonalReminderString(nil, false)
        end, 100, 24, "Import Personal Reminder"
    )
    ImportButton:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 10)
    ImportButton:SetTemplate(options_button_template)

    -- Clear Button
    local ClearButton = DF:CreateButton(reminders_edit_frame, function()
        NSI:SetReminder(nil, true)
        NSI:UpdateReminderFrame(false, true)
        Active_Text.text = "Active Personal Reminder: |cFFFFFFFFNone"
        end, 100, 24, "Clear Reminder"
    )
    ClearButton:SetPoint("LEFT", ImportButton, "RIGHT", 5, 0)
    ClearButton:SetTemplate(options_button_template)

    local function DeleteBossReminder(self, line, all)
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Personal Reminder Deletion", "NSRTDeletePersonalReminderPopup")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = all and DF:CreateLabel(popup,
            "Are you sure you want to \ndelete ALL reminders?", 12, "orange") or DF:CreateLabel(popup,
            "Are you sure you want to \ndelete this Personal Reminder?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            if NSRT.ActivePersonalReminder and NSRT.ActivePersonalReminder == line.name then
                Active_Text.text = "Active Personal Reminder: |cFFFFFFFFNone"
            end
            if all then
                for _, reminder in ipairs(NSI:GetAllReminderNames(true)) do
                    NSI:RemoveReminder(reminder.name, true)
                end
            else
                NSI:RemoveReminder(line.name, true)
            end
            self:SetData(NSI:GetAllReminderNames(true))
            self:MasterRefresh()
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, "Cancel")
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end
    local alldeletecreated
    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.nameTextEntry = DF:CreateTextEntry(line, function() end, line:GetWidth()-129, line:GetHeight())
        line.nameTextEntry:SetTemplate(options_dropdown_template)
        line.nameTextEntry:SetPoint("LEFT", line, "LEFT", 0, 0)
        line.nameTextEntry:SetScript("OnEnterPressed", function(self)
            local oldname = line.name
            if not oldname then return end
            local newname = self:GetText()
            if oldname == newname then return end
            if NSRT.PersonalReminders[newname] then return end -- if name already exists, do nothing
            NSRT.PersonalReminders[newname] = NSRT.PersonalReminders[oldname]
            if NSRT.ActivePersonalReminder == oldname then
                Active_Text.text = "Active Personal Reminder: |cFFFFFFFF" .. newname
                NSRT.ActivePersonalReminder = newname
            end
            NSRT.PersonalReminders[oldname] = nil
            line.name = newname
            parent:MasterRefresh()
        end)

        if not alldeletecreated then
            alldeletecreated = true
            -- Delete All Button
            local DeleteAllButton = DF:CreateButton(reminders_edit_frame, function()
                DeleteBossReminder(self, line, true)
                end, 100, 24, "Delete ALL Reminders"
            )
            DeleteAllButton:SetPoint("LEFT", ClearButton, "RIGHT", 5, 0)
            DeleteAllButton:SetTemplate(options_button_template)
        end
        
        -- Delete button
        line.deleteButton = DF:CreateButton(line, function()
            DeleteBossReminder(self, line, false)
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        -- Load Button
        line.LoadButton = DF:CreateButton(line, function()
            local name = line.nameTextEntry:GetText()
            if name ~= "" then
                NSI:SetReminder(name, true)
                Active_Text.text = "Active Personal Reminder: |cFFFFFFFF" .. name
                NSI:UpdateReminderFrame(false, true)
            end
        end, 55, 20, "Load")
        line.LoadButton:SetPoint("RIGHT", line.deleteButton, "LEFT", 0, 0)
        line.LoadButton:SetTemplate(options_button_template)

        -- Show Button
        line.ShowButton = DF:CreateButton(line, function()
            local name = line.nameTextEntry:GetText()
            ImportPersonalReminderString(name, true)
        end, 55, 20, "Show")
        line.ShowButton:SetPoint("RIGHT", line.LoadButton, "LEFT", 0, 0)
        line.ShowButton:SetTemplate(options_button_template)
        return line
    end

    local scrollLines = 15
    local reminders_edit_scrollbox = DF:CreateScrollBox(reminders_edit_frame, "$parentRemindersEditScrollBox", refresh,
        {},
        420, 300, scrollLines, 20, createLineFunc)
    reminders_edit_frame.scrollbox = reminders_edit_scrollbox
    reminders_edit_scrollbox:SetPoint("TOPLEFT", reminders_edit_frame, "TOPLEFT", 10, -40)
    reminders_edit_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(reminders_edit_scrollbox)
    reminders_edit_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    for i = 1, scrollLines do
        reminders_edit_scrollbox:CreateLine(createLineFunc)
    end

    reminders_edit_frame:Hide()
    return reminders_edit_frame
end

local function BuildCooldownsEditUI()
    local cooldowns_edit_frame = DF:CreateSimplePanel(UIParent, 485, 420, "Cooldowns Management", "CooldownsEditFrame", {
        DontRightClickClose = true
    })
    cooldowns_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local function PrepareData(data)
        local data = {}
        for specId, cooldowns in pairs(NSRT.CooldownList) do
            if cooldowns.spell then
                for id, cooldown in pairs(cooldowns.spell) do
                    tinsert(data,
                        { spec = specId, id = id, offset = cooldown.offset, type = "Spell", name = cooldown.name })
                end
            end
            if cooldowns.item then
                for id, cooldown in pairs(cooldowns.item) do
                    tinsert(data,
                        { spec = specId, id = id, offset = cooldown.offset, type = "Item", name = cooldown.name })
                end
            end
        end
        table.sort(data, function(a, b)
            if a.spec ~= b.spec then
                return a.spec < b.spec
            end
            return a.type > b.type
        end)
        return data
    end

    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()

        -- NSI:Print(DevTools_Dump(NSRT.CooldownList))
    end

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local cooldownData = data[index]
            if cooldownData then
                local line = self:GetLine(i)

                line.spec = cooldownData.spec
                line.name = cooldownData.name
                line.id = cooldownData.id
                line.offset = cooldownData.offset
                line.type = cooldownData.type

                line.specText.text = NSI:SpecToName(line.spec)
                line.typeDropdown:Select(line.type)
                line.idTextEntry.text = line.id
                line.offsetSlider:SetValue(line.offset)
                if line.name == "ERROR" then
                    line.spellIcon:SetTexture(134400)
                    line.__background:SetVertexColor(1, 0, 0, 1)
                elseif cooldownData.type == "Spell" then
                    line.spellIcon:SetTexture(C_Spell.GetSpellTexture(line.id))
                    line.__background:SetVertexColor(1, 1, 1, 0.7608)
                else
                    line.spellIcon:SetTexture(C_Item.GetItemIconByID(line.id))
                    line.__background:SetVertexColor(1, 1, 1, 0.7608)
                end
                -- line:Show()
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        -- Specialization text
        line.specText = DF:CreateLabel(line, "")
        line.specText:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.specText:SetWidth(100)

        line.typeDropdown = DF:CreateDropDown(line, function() return build_cooldown_type_options() end,
            nil, 70)
        line.typeDropdown:SetTemplate(options_dropdown_template)
        line.typeDropdown:SetPoint("LEFT", line.specText, "RIGHT", 5, 0)
        line.typeDropdown:SetHook("OnOptionSelected", function(self, _, value)
            local newType = value
            local oldType = line.type
            if oldType == newType then return end

            if newType == "Spell" then
                NSI:RemoveTrackedCooldown(line.spec, line.id, string.lower(oldType))
                NSI:AddTrackedCooldown(line.spec, line.id, "spell", line.offset)
            else
                NSI:RemoveTrackedCooldown(line.spec, line.id, string.lower(oldType))
                NSI:AddTrackedCooldown(line.spec, line.id, "item", line.offset)
            end

            line.type = newType
            parent:MasterRefresh()
        end)

        line.spellIcon = DF:CreateTexture(line, 134400, 18, 18)
        line.spellIcon:SetPoint("LEFT", line.typeDropdown, "RIGHT", 5, 0)
        line.spellIcon:SetScript("OnEnter", function(self)
            local parent = self:GetParent()
            if parent.id then
                if parent.type == "Spell" then
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
                    GameTooltip:SetSpellByID(parent.id)
                else
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
                    GameTooltip:SetItemByID(parent.id)
                end
                GameTooltip:Show()
            end
        end)
        line.spellIcon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Spell ID text
        line.idTextEntry = DF:CreateTextEntry(line, function(self, _, value)
            if line.type == "Spell" then
                line.spellIcon:SetTexture(C_Spell.GetSpellTexture(value))
            else
                line.spellIcon:SetTexture(C_Item.GetItemIconByID(value))
            end
        end, 120, 20)
        line.idTextEntry:SetTemplate(options_dropdown_template)
        -- line.idTextEntry:SetPoint("LEFT", line, "LEFT", 130, 0)
        line.idTextEntry:SetPoint("LEFT", line.spellIcon, "RIGHT", 5, 0)
        line.idTextEntry:SetScript("OnEnterPressed", function(self)
            local oldId = line.id
            local newId = self:GetText()
            if oldId == newId then return end

            if line.type == "Spell" then
                NSI:RemoveTrackedCooldown(line.spec, oldId, "spell")
                NSI:AddTrackedCooldown(line.spec, newId, "spell", line.offset)
            else
                NSI:RemoveTrackedCooldown(line.spec, oldId, "item")
                NSI:AddTrackedCooldown(line.spec, newId, "item", line.offset)
            end

            line.id = newId
            parent:MasterRefresh()
        end)

        line.offsetSlider = DF:CreateSlider(line, 50, 20, -10, 10, 1, 0, false)
        line.offsetSlider:SetTemplate(options_slider_template)
        line.offsetSlider:SetPoint("LEFT", line.idTextEntry, "RIGHT", 5, 0)
        line.offsetSlider:SetHook("OnValueChanged", function(self, fixedValue, value)
            NSI:RemoveTrackedCooldown(line.spec, line.id, line.type)
            NSI:AddTrackedCooldown(line.spec, line.id, line.type, value)
            line.offset = value
            parent:MasterRefresh()
        end)
        line.offsetSlider:SetTooltip("When you use the cooldown relative to the start of the encounter.")

        -- Delete button
        line.deleteButton = DF:CreateButton(line, function()
            NSI:RemoveTrackedCooldown(line.spec, line.id, line.type)
            self:SetData(NSRT.CooldownList)
            self:MasterRefresh()
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])

        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        -- line.deleteButton:SetFontFace(expressway)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        return line
    end

    local scrollLines = 15
    local cooldowns_edit_scrollbox = DF:CreateScrollBox(cooldowns_edit_frame, "$parentCooldownsEditScrollBox", refresh,
        {},
        445, 300, scrollLines, 20, createLineFunc)
    cooldowns_edit_frame.scrollbox = cooldowns_edit_scrollbox
    cooldowns_edit_scrollbox:SetPoint("TOPLEFT", cooldowns_edit_frame, "TOPLEFT", 10, -50)
    cooldowns_edit_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(cooldowns_edit_scrollbox)

    for i = 1, scrollLines do
        cooldowns_edit_scrollbox:CreateLine(createLineFunc)
    end

    local spec_header = DF:CreateLabel(cooldowns_edit_frame, "Specialization", 11)
    spec_header:SetPoint("TOPLEFT", cooldowns_edit_frame, "TOPLEFT", 15, -30)
    spec_header:SetWidth(100)

    local type_header = DF:CreateLabel(cooldowns_edit_frame, "Type", 11)
    type_header:SetPoint("LEFT", spec_header, "RIGHT", 5, 0)
    type_header:SetWidth(70)

    local id_header = DF:CreateLabel(cooldowns_edit_frame, "Spell/Item ID", 11)
    id_header:SetWidth(120)
    id_header:SetPoint("LEFT", type_header, "RIGHT", 28, 0)

    local offset_header = DF:CreateLabel(cooldowns_edit_frame, "Offset", 11)
    offset_header:SetPoint("LEFT", id_header, "RIGHT", 5, 0)


    cooldowns_edit_scrollbox:SetScript("OnShow", function(self)
        selected_spec = GetSpecializationInfo(GetSpecialization())
        self:MasterRefresh()
    end)

    local label_width = 80
    -- Add new tracked cooldown section
    local new_spec_label = DF:CreateLabel(cooldowns_edit_frame, "Specialization:", 11)
    new_spec_label:SetPoint("TOPLEFT", cooldowns_edit_scrollbox, "BOTTOMLEFT", 0, -20)
    new_spec_label:SetWidth(label_width)

    local new_spec_dropdown = DF:CreateDropDown(cooldowns_edit_frame, function() return build_spec_options() end,
        GetSpecializationInfo(GetSpecialization()), 120)
    new_spec_dropdown:SetPoint("LEFT", new_spec_label, "RIGHT", 10, 0)
    new_spec_dropdown:SetTemplate(options_dropdown_template)

    local new_type_label = DF:CreateLabel(cooldowns_edit_frame, "Type:", 11)
    new_type_label:SetPoint("LEFT", new_spec_dropdown, "RIGHT", 10, 0)
    new_type_label:SetWidth(label_width / 2)

    local new_type_dropdown = DF:CreateDropDown(cooldowns_edit_frame, function() return build_cooldown_type_options() end,
        cooldown_types[1], 120)
    new_type_dropdown:SetPoint("LEFT", new_type_label, "RIGHT", 10, 0)
    new_type_dropdown:SetTemplate(options_dropdown_template)

    local new_id_label = DF:CreateLabel(cooldowns_edit_frame, "Spell/Item ID:", 11)
    new_id_label:SetPoint("BOTTOMLEFT", cooldowns_edit_frame, "BOTTOMLEFT", 10, 10)
    new_id_label:SetWidth(label_width)

    local new_id_text_entry = DF:CreateTextEntry(cooldowns_edit_frame, function() end, 120, 20)
    new_id_text_entry:SetPoint("LEFT", new_id_label, "RIGHT", 10, 0)
    new_id_text_entry:SetTemplate(options_dropdown_template)

    local new_offset_label = DF:CreateLabel(cooldowns_edit_frame, "Offset:", 11)
    new_offset_label:SetPoint("LEFT", new_id_text_entry, "RIGHT", 10, 0)
    new_offset_label:SetWidth(label_width / 2)

    local new_offset_slider = DF:CreateSlider(cooldowns_edit_frame, 120, 20, -10, 10, 1, 0, false)
    new_offset_slider:SetPoint("LEFT", new_offset_label, "RIGHT", 10, 0)
    new_offset_slider:SetTemplate(options_slider_template)

    local add_button = DF:CreateButton(cooldowns_edit_frame, function()
        local spec = new_spec_dropdown:GetValue()
        local type = new_type_dropdown:GetValue()
        local id = new_id_text_entry:GetText()
        local offset = new_offset_slider:GetValue()
        if spec and id ~= "" then
            NSI:AddTrackedCooldown(spec, id, type, offset)
            new_id_text_entry:SetText("")
            new_offset_slider:SetValue(0)
            cooldowns_edit_scrollbox:MasterRefresh()
        end
    end, 60, 20, "Add")
    add_button:SetPoint("LEFT", new_type_dropdown, "RIGHT", 10, 0)
    add_button:SetTemplate(options_button_template)

    cooldowns_edit_frame:Hide()
    return cooldowns_edit_frame
end

local soundlist = NSI.LSM:List("sound")
local build_sound_dropdown = function()
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
    local PASound_edit_frame = DF:CreateSimplePanel(UIParent, 485, 420, "Private Aura Sounds", "PASoundEditFrame", {
        DontRightClickClose = true
    })
    PASound_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local function PrepareData(data)
        local data = {}
        for spellID, info in pairs(NSRT.PASounds) do
            if spellID and info.sound then
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
            if Data then
                local line = self:GetLine(i)

                line.name.text = Data.name
                line.spellID = Data.spellID
                line.spellIDText.text = Data.spellID
                line.sound = Data.sound
                line.texture = C_Spell.GetSpellTexture(line.spellID)
                line.sounddropdown:Select(line.sound)
                line.spellIcon:SetTexture(line.texture)
                -- line:Show()
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        -- SpellIcon
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

        -- SpellName
        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line.spellIcon, "RIGHT", 5, 0)
        line.name:SetWidth(150)

        -- SpellID
        line.spellIDText = DF:CreateLabel(line, "")
        line.spellIDText:SetPoint("LEFT", line.name, "RIGHT", 5, 0)
        line.spellIDText:SetWidth(60)

        -- Sound Dropdown
        line.sounddropdown = DF:CreateDropDown(line, function() return build_sound_dropdown() end,
            nil, 170)
        --line.sounddropdown:Select(line.sound)
        line.sounddropdown:SetTemplate(options_dropdown_template)
        line.sounddropdown:SetPoint("LEFT", line.spellIDText, "RIGHT", 5, 0)
        line.sounddropdown:SetHook("OnOptionSelected", function(self, _, value)
            local newValue = soundlist[value]
            local oldValue = line.sound

            if oldValue == newValue or not (C_UnitAuras.AuraIsPrivate(line.spellID)) then return end
            NSI:SavePASound(tonumber(line.spellID), newValue)

            line.sound = newValue
            parent:MasterRefresh()
        end)

        -- Delete button
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
        -- line.deleteButton:SetFontFace(expressway)
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

    local SpellName = DF:CreateLabel(PASound_edit_frame, "Spell Name", 11)
    SpellName:SetPoint("TOPLEFT", PASound_edit_frame, "TOPLEFT", 40, -30)
    SpellName:SetWidth(100)

    local SpellID = DF:CreateLabel(PASound_edit_frame, "Spell-ID", 11)
    SpellID:SetPoint("LEFT", SpellName, "RIGHT", 55, 0)
    SpellID:SetWidth(70)

    local Sound = DF:CreateLabel(PASound_edit_frame, "Sound", 11)
    Sound:SetWidth(120)
    Sound:SetPoint("LEFT", SpellID, "RIGHT", 0, 0)


    PASound_edit_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    local label_width = 80
    local NewSpellID = DF:CreateLabel(PASound_edit_frame, "SpellID:", 11)
    NewSpellID:SetPoint("BOTTOMLEFT", PASound_edit_frame, "BOTTOMLEFT", 10, 50)
    NewSpellID:SetWidth(label_width)
    
    local NewSpellIDTextEntry = DF:CreateTextEntry(PASound_edit_frame, function() end, 120, 20)
    NewSpellIDTextEntry:SetPoint("LEFT", NewSpellID, "RIGHT", -10, 0)
    NewSpellIDTextEntry:SetTemplate(options_dropdown_template)


    local NewSound = DF:CreateLabel(PASound_edit_frame, "Sound:", 11)
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
            if C_UnitAuras.AuraIsPrivate(spellID) then
                NSI:SavePASound(spellID, sound)
            else
                print("Your entered spellID does not appear to be a Private Aura.")
            end
            PASound_edit_scrollbox:MasterRefresh()

        end
    end, 60, 20, "Add")
    add_button:SetPoint("LEFT", NewSoundDropdown, "RIGHT", 10, 0)
    add_button:SetTemplate(options_button_template)

    local function DeleteAllPASounds(self)
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Deleting ALL Private Aura Sounds", "NSRTDeleteALLPASoundsPopup")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup,
            "Are you sure you want to delete all \nPrivate Aura Sounds?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            for spellID, info in pairs(NSRT.PASounds) do
                NSI:AddPASound(spellID, nil)
            end
            NSRT.PASounds = {}
            PASound_edit_scrollbox:MasterRefresh()
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, "Cancel")
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end

    local delete_all_button = DF:CreateButton(PASound_edit_frame, function()
        DeleteAllPASounds(self)
        PASound_edit_scrollbox:MasterRefresh()
    end, 60, 20, "Delete ALL")
    delete_all_button:SetPoint("BOTTOMRIGHT", PASound_edit_frame, "BOTTOMRIGHT", -10, 10)
    delete_all_button:SetTemplate(options_button_template)

    PASound_edit_frame:Hide()
    return PASound_edit_frame
end

-- Build embedded timeline UI for the Timeline tab
local function BuildTimelineTabUI(parent)
    local header_width = 180
    local timeline_width = window_width - 40 - header_width
    local timeline_height = window_height - 250  -- Account for tab bar, controls, title, zoom slider, and status bar
    local top_offset = -100  -- Standard offset for tab content (below tab buttons)

    -- Mode: "my" = My Reminders, "all" = All Reminders
    parent.timelineMode = "my"
    parent.showBossAbilities = true

    -- Mode dropdown
    local function BuildModeDropdownOptions()
        return {
            {
                label = "My Reminders",
                value = "my",
                onclick = function(_, _, value)
                    parent.timelineMode = value
                    parent.reminderLabel:Hide()
                    parent.reminderDropdown:Hide()
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
            {
                label = "All Reminders (Raid Leader)",
                value = "all",
                onclick = function(_, _, value)
                    parent.timelineMode = value
                    parent.reminderLabel:Show()
                    parent.reminderDropdown:Show()
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            },
        }
    end

    local modeLabel = DF:CreateLabel(parent, "View:", 11, "white")
    modeLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, top_offset)

    local modeDropdown = DF:CreateDropDown(parent, BuildModeDropdownOptions, "my", 200)
    modeDropdown:SetTemplate(options_dropdown_template)
    modeDropdown:SetPoint("LEFT", modeLabel, "RIGHT", 10, 0)
    parent.modeDropdown = modeDropdown

    -- Reminder selection dropdown (for All mode)
    local function BuildReminderDropdownOptions()
        local options = {}
        local sharedList = NSI:GetAllReminderNames(false)
        for _, data in ipairs(sharedList) do
            table.insert(options, {
                label = data.name,
                value = {name = data.name, personal = false},
                onclick = function(_, _, value)
                    parent.currentReminder = value
                    NSI:RefreshEmbeddedTimeline(parent)
                end
            })
        end
        local personalList = NSI:GetAllReminderNames(true)
        if #personalList > 0 then
            table.insert(options, { label = "--- Personal ---", value = nil })
            for _, data in ipairs(personalList) do
                table.insert(options, {
                    label = data.name .. " (Personal)",
                    value = {name = data.name, personal = true},
                    onclick = function(_, _, value)
                        parent.currentReminder = value
                        NSI:RefreshEmbeddedTimeline(parent)
                    end
                })
            end
        end
        return options
    end

    local reminderLabel = DF:CreateLabel(parent, "Reminder Set:", 11, "white")
    reminderLabel:SetPoint("LEFT", modeDropdown, "RIGHT", 20, 0)
    parent.reminderLabel = reminderLabel
    reminderLabel:Hide()

    local reminderDropdown = DF:CreateDropDown(parent, BuildReminderDropdownOptions, nil, 300)
    reminderDropdown:SetTemplate(options_dropdown_template)
    reminderDropdown:SetPoint("LEFT", reminderLabel, "RIGHT", 10, 0)
    parent.reminderDropdown = reminderDropdown
    reminderDropdown:Hide()

    -- Boss abilities toggle
    local bossAbilitiesToggle = DF:CreateSwitch(parent,
        function(self, _, value)
            parent.showBossAbilities = value
            NSI:RefreshEmbeddedTimeline(parent)
        end,
        true, 20, 20, nil, nil, nil, "TimelineBossAbilitiesToggle", nil, nil, nil, nil, options_switch_template)
    bossAbilitiesToggle:SetAsCheckBox()
    bossAbilitiesToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, top_offset + 2)
    parent.bossAbilitiesToggle = bossAbilitiesToggle

    local bossAbilitiesLabel = DF:CreateLabel(parent, "Show Boss Abilities", 11, "white")
    bossAbilitiesLabel:SetPoint("RIGHT", bossAbilitiesToggle, "LEFT", -5, 0)

    -- No data label
    local noDataLabel = DF:CreateLabel(parent, "No reminders to display. Load a reminder set first with /ns", 14, "gray")
    noDataLabel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    parent.noDataLabel = noDataLabel
    noDataLabel:Hide()

    -- Title label (shows boss name and difficulty) - positioned on second row
    local titleLabel = DF:CreateLabel(parent, "", 12, "white")
    titleLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, top_offset - 25)
    parent.titleLabel = titleLabel

    -- Timeline component
    local timelineOptions = {
        width = timeline_width,
        height = timeline_height,
        header_width = header_width,
        header_detached = true,
        line_height = 22,
        line_padding = 1,
        pixels_per_second = 15,
        scale_min = 0.1,
        scale_max = 2.0,
        show_elapsed_timeline = true,
        elapsed_timeline_height = 20,
        can_resize = false,
        use_perpixel_buttons = false,
        backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
        backdrop_color = {0.1, 0.1, 0.1, 0.8},
        backdrop_color_highlight = {0.2, 0.2, 0.3, 0.9},
        backdrop_border_color = {0.1, 0.1, 0.1, 0.3},

        on_enter = function(line)
            line:SetBackdropColor(unpack(line.backdrop_color_highlight))
        end,
        on_leave = function(line)
            line:SetBackdropColor(unpack(line.backdrop_color))
        end,

        on_create_line = function(line)
            if line.lineHeader then
                line.lineHeader:EnableMouse(true)
                line.lineHeader:SetScript("OnEnter", function(self)
                    line:SetBackdropColor(unpack(line.backdrop_color_highlight))
                    if line.lineData and line.lineData.spellId then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetSpellByID(line.lineData.spellId)
                        GameTooltip:Show()
                    end
                end)
                line.lineHeader:SetScript("OnLeave", function(self)
                    line:SetBackdropColor(unpack(line.backdrop_color))
                    GameTooltip:Hide()
                end)
            end
            if line.text then
                line.text:SetWordWrap(false)
                line.text:SetWidth(150)
            end
        end,

        block_on_enter = function(block)
            if block.info and block.info.time then
                GameTooltip:SetOwner(block, "ANCHOR_RIGHT")
                local minutes = math.floor(block.info.time / 60)
                local seconds = math.floor(block.info.time % 60)
                local timeStr = string.format("%d:%02d", minutes, seconds)

                local spellName = ""
                if block.info.spellId then
                    local spellInfo = C_Spell.GetSpellInfo(block.info.spellId)
                    if spellInfo then
                        spellName = spellInfo.name or ""
                    end
                end

                GameTooltip:AddLine(spellName ~= "" and spellName or "Reminder", 1, 1, 1)
                GameTooltip:AddLine("Time: " .. timeStr, 0.7, 0.7, 0.7)
                local duration = tonumber(block.info.duration) or 0
                if duration > 0 then
                    GameTooltip:AddLine("Duration: " .. duration .. "s", 0.7, 0.7, 0.7)
                end

                if block.blockData and block.blockData.payload then
                    local payload = block.blockData.payload
                    if payload.isBossAbility and payload.category then
                        local categoryColors = {
                            damage = "|cffe64c4c",
                            tank = "|cff4c80e6",
                            movement = "|cffe6b333",
                            soak = "|cff80e680",
                            intermission = "|cffb366e6",
                        }
                        local colorCode = categoryColors[payload.category] or "|cffb3b3b3"
                        GameTooltip:AddLine("Category: " .. colorCode .. payload.category .. "|r", 0.7, 0.7, 0.7)
                        if payload.important then
                            GameTooltip:AddLine("|cffff9900Use Healing CDs!|r", 1, 0.6, 0)
                        end
                    elseif payload.phase then
                        GameTooltip:AddLine("Phase: " .. payload.phase, 0.7, 0.7, 0.7)
                    end
                    if payload.text then
                        GameTooltip:AddLine("Text: " .. payload.text, 0.5, 0.8, 0.5)
                    end
                end
                GameTooltip:Show()
            end
        end,
        block_on_leave = function(block)
            GameTooltip:Hide()
        end,
    }

    local timelineFrame = DF:CreateTimeLineFrame(parent, "$parentTimeLine", timelineOptions)
    parent.timeline = timelineFrame

    -- Setup zoom-to-cursor and sticky ruler hooks
    NSI:SetupTimelineHooks(timelineFrame)

    -- Position the timeline (below the title row)
    local timeline_top = top_offset - 45
    if timelineFrame.headerFrame then
        timelineFrame.headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, timeline_top)
        timelineFrame.headerFrame:SetHeight(timeline_height)
        timelineFrame:SetPoint("TOPLEFT", timelineFrame.headerFrame, "TOPRIGHT", 0, 0)
    else
        timelineFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, timeline_top)
    end

    -- Hook scale slider to update phase markers
    if timelineFrame.scaleSlider then
        timelineFrame.scaleSlider:HookScript("OnValueChanged", function()
            NSI:UpdateEmbeddedPhaseMarkers(parent)
        end)

        -- Help text positioned below the zoom slider
        local helpLabel = DF:CreateLabel(parent, "Scroll: Navigate | Ctrl+Scroll: Zoom | Shift+Scroll: Vertical", 10, "gray")
        helpLabel:SetPoint("TOPLEFT", timelineFrame.scaleSlider, "BOTTOMLEFT", 0, -5)
    end

    -- Phase markers container
    parent.phaseMarkers = {}

    -- Refresh timeline when tab becomes visible
    parent:SetScript("OnShow", function(self)
        NSI:RefreshEmbeddedTimeline(self)
    end)

    return parent
end

function NSUI:Init()
    -- Create the scale bar
    DF:CreateScaleBar(NSUI, NSRT.NSUI)
    NSUI:SetScale(NSRT.NSUI.scale)
    -- Create the tab container
    local tabContainer = DF:CreateTabContainer(NSUI, "Northern Sky", "NSUI_TabsTemplate", TABS_LIST, {
        width = window_width,
        height = window_height - 5,
        backdrop_color = { 0, 0, 0, 0.2 },
        backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 }
    })
    -- Position the tab container within the main frame
    -- tabContainer:SetPoint("TOP", NSUI, "TOP", 0, 0)
    tabContainer:SetPoint("CENTER", NSUI, "CENTER", 0, 0)

    local general_tab = tabContainer:GetTabFrameByName("General")
    local nicknames_tab = tabContainer:GetTabFrameByName("Nicknames")
    local cooldowns_tab = tabContainer:GetTabFrameByName("Cooldowns")
    local versions_tab = tabContainer:GetTabFrameByName("Versions")
    local setupmanager_tab = tabContainer:GetTabFrameByName("SetupManager")
    local reminder_tab = tabContainer:GetTabFrameByName("Reminders")
    local reminder_note_tab = tabContainer:GetTabFrameByName("Reminders-Note")
    local assignments_tab = tabContainer:GetTabFrameByName("Assignments")
    local encounteralerts_tab = tabContainer:GetTabFrameByName("EncounterAlerts")
    local readycheck_tab = tabContainer:GetTabFrameByName("ReadyCheck")
    local privateaura_tab = tabContainer:GetTabFrameByName("PrivateAura")
    local timeline_tab = tabContainer:GetTabFrameByName("Timeline")

    -- generic text display
    local generic_display = CreateFrame("Frame", "NSUIGenericDisplay", UIParent, "BackdropTemplate")
    generic_display:SetPoint("CENTER", UIParent, "CENTER", -200, 400)
    generic_display:SetSize(300, 100)
    generic_display.text = generic_display:CreateFontString(nil, "OVERLAY")
    generic_display.text:SetFont(expressway, 20, "OUTLINE")
    generic_display.text:SetPoint("TOPLEFT", generic_display, "TOPLEFT", 0, 0)
    generic_display.text:SetJustifyH("LEFT")
    generic_display:Hide()
    NSUI.generic_display = generic_display

    -- TTS voice preview
    local tts_text_preview = "" 
    -- nickname logic
    local nickname_share_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_share_options = function()
        local t = {}
        for i = 1, #nickname_share_options do
            tinsert(t, {
                label = nickname_share_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["ShareNickNames"] = value
                end

            })
        end
        return t
    end

    local nickname_accept_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_accept_options = function()
        local t = {}
        for i = 1, #nickname_accept_options do
            tinsert(t, {
                label = nickname_accept_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["AcceptNickNames"] = value
                end

            })
        end
        return t
    end

    
    local nickname_syncaccept_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_syncaccept_options = function()
        local t = {}
        for i = 1, #nickname_syncaccept_options do
            tinsert(t, {
                label = nickname_syncaccept_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["NickNamesSyncAccept"] = value
                end

            })
        end
        return t
    end

    local nickname_syncsend_options = { "Raid", "Guild", "None"}
    local build_nickname_syncsend_options = function()
        local t = {}
        for i = 1, #nickname_syncsend_options do
            tinsert(t, {
                label = nickname_syncsend_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["NickNamesSyncSend"] = value
                end

            })
        end
        return t
    end

    local build_media_options = function(typename, settingname, isTexture, isReminder, Personal)
        local list = NSI.LSM:List(isTexture and "statusbar" or "font")
        local t = {}
        for i, font in ipairs(list) do
            tinsert(t, {
                label = font,
                value = i,
                onclick = function(_, _, value)
                    NSRT.ReminderSettings[typename][settingname] = list[value]
                    if isReminder then
                        NSI:UpdateReminderFrame(false, true)
                    else
                        NSI:UpdateExistingFrames()
                    end
                end
            })
        end
        return t
    end

    local build_raidframeicon_options = function()
        local list = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
        local t = {}
        for i, v in ipairs(list) do
            tinsert(t, {
                label = v,
                value = i,
                onclick = function(_, _, value)
                    NSRT.ReminderSettings.UnitIconSettings.Position = list[value]        
                    NSI:UpdateExistingFrames()
                end
            })
        end
        return t
    end

    local build_growdirection_options = function(SettingName, Icons)
        local list = Icons and {"Up", "Down", "Left", "Right"} or {"Up", "Down"}
        local t = {}
        for i, v in ipairs(list) do
            tinsert(t, {
                label = v,
                value = i,
                onclick = function(_, _, value)
                    NSRT.ReminderSettings[SettingName]["GrowDirection"] = list[value]
                    NSI:UpdateExistingFrames()
                end
            })
        end
        return t
    end

    local build_PAgrowdirection_options = function(SettingName, SecondaryName)
        local list = {"LEFT", "RIGHT", "UP", "DOWN"}
        local t = {}
        for i, v in ipairs(list) do
            tinsert(t, {
                label = v,
                value = i,
                onclick = function(_, _, value)
                    NSRT[SettingName][SecondaryName] = list[value]
                    NSI:UpdatePADisplay(SettingName == "PASettings", SettingName == "PATankSettings")
                end
            })
        end
        return t
    end

    local function WipeNickNames()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Wipe Nicknames", "NSRTWipeNicknamesPopup")
        popup:SetFrameStrata("DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup,
            "Are you sure you want to wipe all nicknames?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            NSI:WipeNickNames()
            NSUI.nickname_frame.scrollbox:MasterRefresh()
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, "Cancel")
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end
    -- end of nickname logic

    -- when any setting is changed, call these respective callback function
    local general_callback = function()
        wipe(NSUI.OptionsChanged["general"])
    end
    local nicknames_callback = function()

        if NSUI.OptionsChanged.nicknames["NICKNAME"] then
            NSI:NickNameUpdated(NSRT.Settings["MyNickName"])
        end

        if NSUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] then
            NSI:GlobalNickNameUpdate()
        end

        if NSUI.OptionsChanged.nicknames["TRANSLIT"] then
            NSI:UpdateNickNameDisplay(true)
        end

        if NSUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] then
            NSI:BlizzardNickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["CELL_NICKNAMES"] then
            NSI:CellNickNameUpdated(true)
        end

        if NSUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] then
            NSI:ElvUINickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] then
            NSI:VuhDoNickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] then
            NSI:Grid2NickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] then
            NSI:DandersFramesNickNameUpdated(true)
        end

        if NSUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] then
            NSI:UnhaltedNickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["MRT_NICKNAMES"] then
            NSI:MRTNickNameUpdated(true)
        end

        wipe(NSUI.OptionsChanged["nicknames"])
    end    

    local versions_callback = function()
        wipe(NSUI.OptionsChanged["versions"])
    end

    -- options
    local client = IsWindowsClient()
    local general_options1_table = {
        { type = "label", get = function() return "General Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Minimap Button",
            desc = "Hide the minimap button.",
            get = function() return NSRT.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                NSRT.Settings["Minimap"].hide = value                
                LDBIcon:Refresh("NSRT", NSRT.Settings["Minimap"])
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Debug Logging",
            desc = "Enables Debug Logging, which prints a bunch of information and adds it to DevTool. This might Error if you do not have the DevTool Addon installed.",
            get = function() return NSRT.Settings["DebugLogs"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["DEBUGLOGS"] = true
                NSRT.Settings["DebugLogs"] = value
            end,
        },

        {
            type = "breakline"
        },   
        { type = "label", get = function() return "TTS Options" end,     text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "range",
            name = "TTS Voice",
            desc = "Voice to use for TTS. Most users will only have ~2 different voices. These voices depend on your installed language packs.",
            get = function() return NSRT.Settings["TTSVoice"] end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.general["TTS_VOICE"] = true
                NSRT.Settings["TTSVoice"] = value 
            end,
            min = 1,
            max = client and 20 or 100, -- up to 20 TTS voices for windows users, otherwise go to 100 for Mac users
        },
        {
            type = "range",
            name = "TTS Volume",
            desc = "Volume of the TTS",
            get = function() return NSRT.Settings["TTSVolume"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["TTSVolume"] = value
            end,
            min = 0,
            max = 100,
        },
        {
            type = "textentry",
            name = "TTS Preview",
            desc = [[Enter any text to preview TTS

Press 'Enter' to hear the TTS]],
            get = function() return tts_text_preview end,
            set = function(self, fixedparam, value)
                tts_text_preview = value
            end,
            hooks = {
                OnEnterPressed = function(self)
                    NSAPI:TTS(tts_text_preview, NSRT.Settings["TTSVoice"])
                end
            }
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable TTS",
            desc = "Enable TTS",
            get = function() return NSRT.Settings["TTS"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["TTS_ENABLED"] = true
                NSRT.Settings["TTS"] = value
            end,
        },    
    }

    local nicknames_options1_table = {
        
        { type = "label", get = function() return "Nicknames Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "textentry",
            name = "Nickname",
            desc = "Set your nickname to be seen by others and used in assignments",
            get = function() return NSRT.Settings["MyNickName"] or "" end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.nicknames["NICKNAME"] = true
                NSRT.Settings["MyNickName"] = NSI:Utf8Sub(value, 1, 12)
            end,
            hooks = {
                OnEditFocusLost = function(self)
                    self:SetText(NSRT.Settings["MyNickName"])
                end,
                OnEnterPressed = function(self) return end
            },
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Nicknames",
            desc = "Globaly enable nicknames.",
            get = function() return NSRT.Settings["GlobalNickNames"] end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] = true
                NSRT.Settings["GlobalNickNames"] = value 
            end,
            nocombat = true
        },
        
        {
            type = "toggle",
            boxfirst = true,
            name = "Translit Names",
            desc = "Translit Russian Names",
            get = function() return NSRT.Settings["Translit"] end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.nicknames["TRANSLIT"] = true
                NSRT.Settings["Translit"] = value 
            end,
            nocombat = true
        },

        
        { type = "label", get = function() return "Automated Nickname Share Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "select",
            get = function() return NSRT.Settings["ShareNickNames"] end,
            values = function() return build_nickname_share_options() end,
            name = "Nickname Sharing",
            desc = "Choose who you share your nickname with.",
            nocombat = true
        },        
        {
            type = "select",
            get = function() return NSRT.Settings["AcceptNickNames"] end,
            values = function() return build_nickname_accept_options() end,
            name = "Nickname Accept",
            desc = "Choose who you are accepting Nicknames from",
            nocombat = true
        },        
        
        { type = "label", get = function() return "Manual Nickname Sync Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type = "select",
            get = function() return NSRT.Settings["NickNamesSyncSend"] end,
            values = function() return build_nickname_syncsend_options() end,
            name = "Nickname Sync Send",
            desc = "Choose who you are synching nicknames to when pressing on the sync button",
            nocombat = true
        },

        
        {
            type = "select",
            get = function() return NSRT.Settings["NickNamesSyncAccept"] end,
            values = function() return build_nickname_syncaccept_options() end,
            name = "Nickname Sync Accept",
            desc = "Choose who you are accepting Nicknames sync requests to come from",
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Unit Frame compatibility" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Blizzard"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] = true
                NSRT.Settings["Blizzard"] = value
            end,
            name = "Enable Blizzard/Reskin Addons Nicknames",
            desc = "Enable Nicknames to be used with Blizzard unit frames. This should automatically work for any Addon that reskins Blizzard Frames instead of creating their own frames. This for example includes RaidFrameSettings.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Cell"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["CELL_NICKNAMES"] = true
                NSRT.Settings["Cell"] = value
            end,
            name = "Enable Cell Nicknames",
            desc = "Enable Nicknames to be used with Cell unit frames. This requires enabling nicknames within Cell.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Grid2"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] = true
                NSRT.Settings["Grid2"] = value
            end,
            name = "Enable Grid2 Nicknames",
            desc = "Enable Nicknames to be used with Grid2 unit frames. This requires selecting the 'NSNickName' indicator within Grid2.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["DandersFrames"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] = true
                NSRT.Settings["DandersFrames"] = value
            end,
            name = "Enable DandersFrames Nicknames",
            desc = "Enable Nicknames to be used with DandersFrames unit frames.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["ElvUI"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] = true
                NSRT.Settings["ElvUI"] = value
            end,
            name = "Enable ElvUI Nicknames",
            desc = "Enable Nicknames to be used with ElvUI unit frames. This requires editing your Tags. Available options are [NSNickName] and [NSNickName:1-12]",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["VuhDo"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] = true
                NSRT.Settings["VuhDo"] = value
            end,
            name = "Enable VuhDo Nicknames",
            desc = "Enable Nicknames to be used with VuhDo unit frames.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Unhalted"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] = true
                NSRT.Settings["Unhalted"] = value
            end,
            name = "Enable Unhalted UF Nicknames",
            desc = "Enable Nicknames to be used with Unhalted Unit Frames. You can choose 'NSNickName' as a tag within UUF.",
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "button",
            name = "Wipe Nicknames",
            desc = "Wipe all nicknames from the database.",
            func = function(self)
                WipeNickNames()
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Edit Nicknames",
            desc = "Edit the nicknames database stored locally.",
            func = function(self)
                if not NSUI.nickname_frame:IsShown() then
                    NSUI.nickname_frame:Show()
                end
            end,
            nocombat = true
        }
    }

    
    local setupmanager_options1_table = {
        
        {
            type = "button",
            name = "Default Arrangement",
            desc = "Sorts groups into a default order (tanks - melee - ranged - healer)",
            func = function(self)
                NSI:SplitGroupInit(false, true, false)
            end,
            nocombat = true,
            spacement = true
        },
        
        {
            type = "button",
            name = "Split Groups",
            desc = "Splits the group evenly into 2 groups. It will even out tanks, melee, ranged and healers, as well as trying to balance the groups by class and specs",
            func = function(self)
                NSI:SplitGroupInit(false, false, false)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "button",
            name = "Split Evens/Odds",
            desc = "Same as the button above but using groups 1/3/5 and 2/4/6.",
            func = function(self)
                NSI:SplitGroupInit(false, false, true)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "breakline"
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Show Missing Raidbuffs in Raid-Tab",
            desc = "Show a list of missing raidbuffs in your comp in the raid tab. In there you can swap between Mythic and Flex, which will then only consider players up to group 4/6 respectively.",
            get = function() return NSRT.Settings.MissingRaidBuffs end,
            set = function(self, fixedparam, value)
                NSRT.Settings.MissingRaidBuffs = value
                NSI:UpdateRaidBuffFrame()
            end,
            nocombat = true,
        }, 
    }

    local reminder_options1_table = {
        
        {
            type = "label",
            get = function() return "Spell Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS",
            desc = "Whether a TTS sound should be played",
            get = function() return NSRT.ReminderSettings["SpellTTS"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellTTS"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "TTSTimer",
            desc = "At how much remaining Time the TTS should be played",
            get = function() return NSRT.ReminderSettings["SpellTTSTimer"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellTTSTimer"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = "Duration",
            desc = "How long a reminder should be shown for",
            get = function() return NSRT.ReminderSettings["SpellDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellDuration"] = value
                NSI:ProcessReminder()
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return NSRT.ReminderSettings["SpellCountdown"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellCountdown"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Duration",
            desc = "When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'SpellName in 10'",
            get = function() return NSRT.ReminderSettings["AnnounceSpellDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["AnnounceSpellDuration"] = value
                NSI:ProcessReminder()

            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "SpellName",
            desc = "Display the SpellName if no text is provided",
            get = function() return NSRT.ReminderSettings["SpellName"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["SpellName"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Bars",
            desc = "Show Progress Bars instead of icons",
            get = function() return NSRT.ReminderSettings["Bars"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["Bars"] = value
            end,
            nocombat = true,
        },               
        {
            type = "range",
            boxfirst = true,
            name = "Sticky",
            desc = "Keep Reminders shown for X seconds if the spell hasn't been pressed yet",
            get = function() return NSRT.ReminderSettings["Sticky"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["Sticky"] = value
            end,
            nocombat = true,
            min = 0,
            max = 10,
        },        
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Timer Text",
            desc = "Hides the Timer Text shown on the Icon",
            get = function() return NSRT.ReminderSettings["HideTimerText"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["HideTimerText"] = value
                NSI:UpdateExistingFrames()
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Text Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.ReminderSettings.TextSettings.GrowDirection end,
            values = function() return build_growdirection_options("TextSettings") end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS",
            desc = "Whether a TTS sound should be played",
            get = function() return NSRT.ReminderSettings["TextTTS"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextTTS"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "TTSTimer",
            desc = "At how much remaining Time the TTS should be played",
            get = function() return NSRT.ReminderSettings["TextTTSTimer"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextTTSTimer"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = "Duration",
            desc = "How long a reminder should be shown for",
            get = function() return NSRT.ReminderSettings["TextDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextDuration"] = value
                NSI:ProcessReminder()
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return NSRT.ReminderSettings["TextCountdown"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["TextCountdown"] = value
                NSI:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Duration",
            desc = "When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'Spread in 10'",
            get = function() return NSRT.ReminderSettings["AnnounceTextDuration"] end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings["AnnounceTextDuration"] = value
                NSI:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return NSRT.ReminderSettings.TextSettings.Font end,
            values = function() return build_media_options("TextSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return NSRT.ReminderSettings.TextSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        
        {
            type = "color",
            name = "Text-Color",
            desc = "Color of Text-Reminders",
            get = function() return NSRT.ReminderSettings.TextSettings.colors end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.TextSettings.colors = {r, g, b, a}
                NSI:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Text reminders",
            get = function() return NSRT.ReminderSettings.TextSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.TextSettings["Spacing"] = value
                NSI:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Icon Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.ReminderSettings.IconSettings.GrowDirection end,
            values = function() return build_growdirection_options("IconSettings", true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Width",
            desc = "Width of the Icon",
            get = function() return NSRT.ReminderSettings.IconSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.Width = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Height",
            desc = "Height of the Icon",
            get = function() return NSRT.ReminderSettings.IconSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.Height = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },

        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return NSRT.ReminderSettings.IconSettings.Font end,
            values = function() return build_media_options("IconSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return NSRT.ReminderSettings.IconSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Timer-Text Font-Size",
            desc = "Font Size of the Timer-Text",
            get = function() return NSRT.ReminderSettings.IconSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings.TimerFontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },     
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Icon reminders",
            get = function() return NSRT.ReminderSettings.IconSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.IconSettings["Spacing"] = value
                NSI:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },  

        {
            type = "label",
            get = function() return "Bar Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.ReminderSettings.BarSettings.GrowDirection end,
            values = function() return build_growdirection_options("BarSettings") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Bar-Width",
            desc = "Width of the Bar",
            get = function() return NSRT.ReminderSettings.BarSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.Width = value
                NSI:UpdateExistingFrames()
            end,
            min = 80,
            max = 500,
            nocombat = true,
        },
        {
            type = "range",
            name = "Bar-Height",
            desc = "Height of the Bar",
            get = function() return NSRT.ReminderSettings.BarSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.Height = value
                NSI:UpdateExistingFrames()
            end,
            min = 10,
            max = 100,
            nocombat = true,
        },
        {
            type = "select",
            name = "Texture",
            desc = "Texture",
            get = function() return NSRT.ReminderSettings.BarSettings.Texture end,
            values = function() return build_media_options("BarSettings", "Texture", true) end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return NSRT.ReminderSettings.BarSettings.Font end,
            values = function() return build_media_options("BarSettings", "Font") end,            
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return NSRT.ReminderSettings.BarSettings.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.FontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 15,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Timer-Text Font-Size",
            desc = "Font Size of the Timer-Text",
            get = function() return NSRT.ReminderSettings.BarSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings.TimerFontSize = value
                NSI:UpdateExistingFrames()
            end,
            min = 15,
            max = 200,
            nocombat = true,
        },
        {
            type = "color",
            name = "Bar-Color",
            desc = "Color of the Bars",
            get = function() return NSRT.ReminderSettings.BarSettings.colors end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.BarSettings.colors = {r, g, b, a}
                NSI:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Bar reminders",
            get = function() return NSRT.ReminderSettings.BarSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.BarSettings["Spacing"] = value
                NSI:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Raidframe Icon Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range",
            name = "Icon-Width",
            desc = "Width of the Icon",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.Width = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Height",
            desc = "Height of the Icon",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.Height = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "select",
            name = "Position",
            desc = "position on the raidframe",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.Position end,
            values = function() return build_raidframeicon_options() end,
            nocombat = true,
        },
        {
            type = "range",
            name = "x-Offset",
            desc = "",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.xOffset= value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = "y-Offset",
            desc = "",
            get = function() return NSRT.ReminderSettings.UnitIconSettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UnitIconSettings.yOffset = value
                NSI:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        
        {
            type = "color",
            name = "Glow-Color",
            desc = "Color of Raidframe Glows",
            get = function() return NSRT.ReminderSettings.GlowSettings.colors end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.GlowSettings.colors = {r, g, b, a}
            end,
            hasAlpha = true,
            nocombat = true

        },
                 
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Manage Reminders" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),            
        },
        {
            type = "button",
            name = "Preview Alerts",
            desc = "Preview Reminders and unlock their anchors to move them around",
            func = function(self)
                if NSI.PreviewTimer then
                    NSI.PreviewTimer:Cancel()
                    NSI.PreviewTimer = nil
                end
                if NSI.IsInPreview then
                    NSI.IsInPreview = false
                    NSI:HideAllReminders()
                    for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                        if NSI[v] then
                            NSI[v]:StopMovingOrSizing()
                        end
                        NSI:ToggleMoveFrames(NSI[v], false)
                    end
                    return
                end
                NSI.PreviewTimer = C_Timer.NewTimer(12, function()
                    if NSI.IsInPreview then
                        NSI.IsInPreview = false
                        NSI:HideAllReminders()
                        for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                            if NSI[v] then
                                NSI[v]:StopMovingOrSizing()
                            end
                            NSI:ToggleMoveFrames(NSI[v], false)
                        end
                    end
                end)
                NSI.IsInPreview = true
                for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                    NSI:ToggleMoveFrames(NSI[v], true)
                end
                NSI:UpdateExistingFrames()
                NSI.AllGlows = NSI.AllGlows or {}
                local MyFrame = NSI.LGF.GetUnitFrame("player")
                NSI.PlayedSound = {}
                NSI.StartedCountdown = {}
                local info1 = {
                    text = "Personals", 
                    phase = 1, 
                    id = 1, 
                    TTS = NSRT.ReminderSettings.TextTTS and "Personals", 
                    TTSTimer = NSRT.ReminderSettings.TextTTSTimer, 
                    countdown = NSRT.ReminderSettings.TextCountdown,
                    dur = NSRT.ReminderSettings.TextDuration,
                }
                NSI:DisplayReminder(info1)
                local info2 = {
                    text = "Stack on |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t", 
                    phase = 1, 
                    id = 2, 
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.TextTTSTimer, 
                    countdown = false,
                    dur = NSRT.ReminderSettings.TextDuration,
                }
                NSI:DisplayReminder(info2)
                local info3 = {
                    text = "Give Ironbark", 
                    IconOverwrite = true,
                    spellID = 102342,
                    phase = 1, 
                    id = 3, 
                    TTS = NSRT.ReminderSettings.SpellTTS and "Give Ironbark",
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer, 
                    countdown = NSRT.ReminderSettings.SpellCountdown,
                    dur = NSRT.ReminderSettings.SpellDuration,
                    glowunit = {"player"},
                }
                NSI:DisplayReminder(info3)
                local info4 = {
                    text = NSRT.ReminderSettings.SpellName and C_Spell.GetSpellInfo(115203).name,
                    IconOverwrite = true,
                    spellID = 115203,
                    phase = 1, 
                    id = 4, 
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer, 
                    countdown = false,
                    dur = NSRT.ReminderSettings.SpellDuration,
                }
                NSI:DisplayReminder(info4)
                local info5 = {
                    text = "Breath", 
                    BarOverwrite = true,
                    spellID = 1256855,
                    phase = 1, 
                    id = 5, 
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer, 
                    countdown = false,
                    dur = NSRT.ReminderSettings.SpellDuration,
                    glowunit = {"player"},
                }
                NSI:DisplayReminder(info5)
                local info6 = {
                    text = "Dodge", 
                    BarOverwrite = true,
                    spellID = 193171,
                    phase = 1, 
                    id = 6, 
                    TTS = false,
                    TTSTimer = NSRT.ReminderSettings.SpellTTSTimer, 
                    countdown = false,
                    dur = NSRT.ReminderSettings.SpellDuration,
                }
                NSI:DisplayReminder(info6)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Shared Reminders",
            desc = "Enables reminders set by the raidleader or shared by an assist",
            get = function() return NSRT.ReminderSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.enabled = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },
        
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Personal Reminders",
            desc = "Enables reminders set into your personal reminder",
            get = function() return NSRT.ReminderSettings.PersNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersNote = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use MRT Note Reminders",
            desc = "Enables reminders entered into MRT note",
            get = function() return NSRT.ReminderSettings.MRTNote end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.MRTNote = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },               
        

        {
            type = "button",
            name = "Shared Reminders",
            desc = "Shows a list of all Reminders",
            func = function(self)
                if not NSUI.reminders_frame:IsShown() then
                    NSUI.reminders_frame:Show()
                else
                    NSUI.reminders_frame:Hide()
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = "Personal Reminders",
            desc = "Shows a list of all Personal Reminders",
            func = function(self)
                if not NSUI.personal_reminders_frame:IsShown() then
                    NSUI.personal_reminders_frame:Show()
                else
                    NSUI.personal_reminders_frame:Hide()
                end
            end,
            nocombat = true,
            spacement = true
        },
        
        {
            type = "toggle",
            boxfirst = true,
            name = "Share on Ready Check",
            desc = "Automatically share the current active reminder on ready check if you are the raidleader.",
            get = function() return NSRT.ReminderSettings.AutoShare end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.AutoShare = value
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Use TimelineReminders",
            desc = "Toggling this on will make NSRT not display any reminders, but still allow TimelineReminders to read any shared or personal reminder you have and also allow the Note-Display to work.",
            get = function() return NSRT.ReminderSettings.UseTimelineReminders end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.UseTimelineReminders = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
                NSI:FireCallback("NSRT_REMINDER_CHANGED", NSI.PersonalReminder, NSI.Reminder)
            end,
            nocombat = true,
        },
    }
    
    local reminder_note_options1_table = {
        {
            type = "label",
            get = function() return "This tab is purely for Settings to display Reminders as a Note on-screen. They have no effect on how the in-combat alerts work.\nThere are 3 types of displays. The first one shows all reminders, the second one shows only those that will activate for you. And the third shows all text that is not a reminder." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Shared Reminder-Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        
        {
            type = "button",
            name = "Unlock Shared Reminder",
            desc = "Locks/Unlocks the Reminder-Note to be moved around",
            func = function(self)
                if NSI.ReminderFrameMover and NSI.ReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame()
                    NSI:ToggleMoveFrames(NSI.ReminderFrameMover, false)
                    NSI.ReminderFrameMover.Resizer:Hide()
                    NSI.ReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ReminderFrameMoveable = false
                else
                    NSI:UpdateReminderFrame()
                    NSI:ToggleMoveFrames(NSI.ReminderFrameMover, true)
                    NSI.ReminderFrameMover.Resizer:Show()
                    NSI.ReminderFrameMover:SetResizable(true)
                    NSI.ReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.ReminderFrameMoveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },   
        {
            type = "toggle",
            boxfirst = true,
            name = "Show All Reminders-Note",
            desc = "Whether you want to show the Shared Reminder-Note on screen permanently",
            get = function() return NSRT.ReminderSettings.ShowReminderFrame end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowReminderFrame = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame()
            end,
            nocombat = true,
        },        
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the Shared Reminder-Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ReminderFrame.FontSize = value
                NSI:UpdateReminderFrame()
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the Shared Reminder-Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.Font end,
            values = function() 
                return build_media_options("ReminderFrame", "Font", false, true, false) 
            end, 
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the Shared Reminder-Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ReminderFrame.Width = value
                NSI:UpdateReminderFrame()
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Shared Reminder-Note",
            get = function() return NSRT.ReminderSettings.ReminderFrame.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ReminderFrame.Height = value
                NSI:UpdateReminderFrame()
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },  

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the Shared Reminder-Note when unlocked",
            get = function() return NSRT.ReminderSettings.ReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.ReminderFrame.BGcolor = {r, g, b, a}
                NSI:UpdateReminderFrame()
            end,
            hasAlpha = true,
            nocombat = true,
            spacement = true,

        },        
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Only Spell-Reminders",
            desc = "By default only Spell-Reminders will be shown. Disabling this will also show you Text-Reminders",
            get = function() return NSRT.ReminderSettings.OnlySpellReminders end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.OnlySpellReminders = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },
        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Personal Reminder-Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),         
        },
        
        {
            type = "button",
            name = "Unlock Pers Reminder",
            desc = "Locks/Unlocks the Personal Reminder-Note to be moved around",
            func = function(self)
                if NSI.PersonalReminderFrameMover and NSI.PersonalReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(true)
                    NSI:ToggleMoveFrames(NSI.PersonalReminderFrameMover, false)
                    NSI.PersonalReminderFrameMover.Resizer:Hide()
                    NSI.PersonalReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.PersonalReminderFrameMoveable = false
                else
                    NSI:UpdateReminderFrame(true)
                    NSI:ToggleMoveFrames(NSI.PersonalReminderFrameMover, true)
                    NSI.PersonalReminderFrameMover.Resizer:Show()
                    NSI.PersonalReminderFrameMover:SetResizable(true)
                    NSI.PersonalReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.PersonalReminderFrameMoveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },  
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Personal Reminders-Note",
            desc = "Whether you want to display the Note for Reminders only relevant to you",
            get = function() return NSRT.ReminderSettings.ShowPersonalReminderFrame end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowPersonalReminderFrame = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the Personal Reminder-Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersonalReminderFrame.FontSize = value
                NSI:UpdateReminderFrame(true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the Personal Reminder-Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.Font end,
            values = function() 
                return build_media_options("PersonalReminderFrame", "Font", false, true, true) 
            end, 
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the Personal Reminder-Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersonalReminderFrame.Width = value
                NSI:UpdateReminderFrame(true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Personal Reminder-Note",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.PersonalReminderFrame.Height = value
                NSI:UpdateReminderFrame(true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the Personal Reminder-Note when unlocked",
            get = function() return NSRT.ReminderSettings.PersonalReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.PersonalReminderFrame.BGcolor = {r, g, b, a}
                NSI:UpdateReminderFrame(true)
            end,
            hasAlpha = true,
            nocombat = true

        }, 

        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Text-Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),         
        },
        
        {
            type = "button",
            name = "Unlock Text Note",
            desc = "Locks/Unlocks the Text Note to be moved around. This Note shows anything from the reminders that it is not an actual reminder string. So you can put any text in there to be displayed.",
            func = function(self)
                if NSI.ExtraReminderFrameMover and NSI.ExtraReminderFrameMover:IsMovable() then
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:ToggleMoveFrames(NSI.ExtraReminderFrameMover, false)
                    NSI.ExtraReminderFrameMover.Resizer:Hide()
                    NSI.ExtraReminderFrameMover:SetResizable(false)
                    NSRT.ReminderSettings.ExtraReminderFrameMoveable = false
                else
                    NSI:UpdateReminderFrame(false, false, true)
                    NSI:ToggleMoveFrames(NSI.ExtraReminderFrameMover, true)
                    NSI.ExtraReminderFrameMover.Resizer:Show()
                    NSI.ExtraReminderFrameMover:SetResizable(true)
                    NSI.ExtraReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    NSRT.ReminderSettings.ExtraReminderFrameMoveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },  
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Text Note",
            desc = "Whether you want to display the Text-Note",
            get = function() return NSRT.ReminderSettings.ShowExtraReminderFrame end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ShowExtraReminderFrame = value
                NSI:ProcessReminder()
                NSI:UpdateReminderFrame(false, false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ExtraReminderFrame.FontSize = value
                NSI:UpdateReminderFrame(false, false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.Font end,
            values = function() 
                return build_media_options("ExtraReminderFrame", "Font", false, true, true) 
            end, 
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.Width end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ExtraReminderFrame.Width = value
                NSI:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Text-Note",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.Height end,
            set = function(self, fixedparam, value)
                NSRT.ReminderSettings.ExtraReminderFrame.Height = value
                NSI:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the Text-Note when unlocked",
            get = function() return NSRT.ReminderSettings.ExtraReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                NSRT.ReminderSettings.ExtraReminderFrame.BGcolor = {r, g, b, a}
                NSI:UpdateReminderFrame(false, false, true)
            end,
            hasAlpha = true,
            nocombat = true

        }, 

    }
    local assignments_options1_table = {        
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Assignment on Pull",
            desc = "Shows your Assignment on Pull",
            get = function() return NSRT.AssignmentSettings.OnPull end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings.OnPull = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "For the following Boxes only the Settings of the Raidleader matter." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "label",
            get = function() return "Vaelgor & Ezzorak" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Gloom Soaks",
            desc = "Automatically tells Group 2 to soak the first Cast of Gloom and Group 3 to soak the second cast",
            get = function() return NSRT.AssignmentSettings[3178] and NSRT.AssignmentSettings[3178].Soaks end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3178] = NSRT.AssignmentSettings[3178] or {}
                NSRT.AssignmentSettings[3178].Soaks = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Lightblinded Vanguard" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Execution Sentence",
            desc = "Automatically assigns players to Star, Orange, Triangle and Purple for Execution Sentence. Melee are preferred for Star/Orange, Ranged for Triangle/Purple. You should be putting down World Markers for this.",
            get = function() return NSRT.AssignmentSettings[3180] and NSRT.AssignmentSettings[3180].Soaks end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3180] = NSRT.AssignmentSettings[3180] or {}
                NSRT.AssignmentSettings[3180].Soaks = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Chimaerus" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Alndust Upheaval",
            desc = "Automatically tells Groups 1&2 to soak the first Cast of Alndust Upheaval and Group 3&4 to soak the second cast",
            get = function() return NSRT.AssignmentSettings[3306] and NSRT.AssignmentSettings[3306].Soaks end,
            set = function(self, fixedparam, value)
                NSRT.AssignmentSettings[3306] = NSRT.AssignmentSettings[3306] or {}
                NSRT.AssignmentSettings[3306].Soaks = value
            end,
            nocombat = true,
        },
    }

    local encounteralerts_options1_table = {     
        {
            type = "label",
            get = function() return "Midnight S1" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },   
        {
            type = "toggle",
            boxfirst = true,
            name = "Imperator Averzian",
            desc = "Enables Alerts for Imperator Averzian.",
            get = function() return NSRT.EncounterAlerts[3176] and NSRT.EncounterAlerts[3176].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3176] = NSRT.EncounterAlerts[3176] or {}
                NSRT.EncounterAlerts[3176].enabled = value
            end,
            nocombat = true,
        }, 
        {
            type = "toggle",
            boxfirst = true,
            name = "Vorasius",
            desc = "Enables Alerts for Vorasius.",
            get = function() return NSRT.EncounterAlerts[3177] and NSRT.EncounterAlerts[3177].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3177] = NSRT.EncounterAlerts[3177] or {}
                NSRT.EncounterAlerts[3177].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Fallen King Salhadaar",
            desc = "Enables Alerts for Fallen King Salhadaar.",
            get = function() return NSRT.EncounterAlerts[3179] and NSRT.EncounterAlerts[3179].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3179] = NSRT.EncounterAlerts[3179] or {}
                NSRT.EncounterAlerts[3179].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Vaelgor & Ezzorak",
            desc = "Enables Alerts for Vaelgor & Ezzorak.",
            get = function() return NSRT.EncounterAlerts[3178] and NSRT.EncounterAlerts[3178].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3178] = NSRT.EncounterAlerts[3178] or {}
                NSRT.EncounterAlerts[3178].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Lightblinded Vanguard",
            desc = "Enables Alerts for Lightblinded Vanguard.",
            get = function() return NSRT.EncounterAlerts[3180] and NSRT.EncounterAlerts[3180].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3180] = NSRT.EncounterAlerts[3180] or {}
                NSRT.EncounterAlerts[3180].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Crown of the Cosmos",
            desc = "Enables Alerts for Crown of the Cosmos.",
            get = function() return NSRT.EncounterAlerts[3181] and NSRT.EncounterAlerts[3181].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3181] = NSRT.EncounterAlerts[3181] or {}
                NSRT.EncounterAlerts[3181].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Chimaerus",
            desc = "Enables Alerts for Chimaerus.",
            get = function() return NSRT.EncounterAlerts[3306] and NSRT.EncounterAlerts[3306].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3306] = NSRT.EncounterAlerts[3306] or {}
                NSRT.EncounterAlerts[3306].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Beloren",
            desc = "Enables Alerts for Beloren.",
            get = function() return NSRT.EncounterAlerts[3182] and NSRT.EncounterAlerts[3182].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3182] = NSRT.EncounterAlerts[3182] or {}
                NSRT.EncounterAlerts[3182].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Midnight Falls",
            desc = "Enables Alerts for Midnight Falls.",
            get = function() return NSRT.EncounterAlerts[3183] and NSRT.EncounterAlerts[3183].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3183] = NSRT.EncounterAlerts[3183] or {}
                NSRT.EncounterAlerts[3183].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "Manaforge Omega" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Nexus King",
            desc = "Probably a bit rough in 1st week of pre-patch, use at own risk.",
            get = function() return NSRT.EncounterAlerts[3134] and NSRT.EncounterAlerts[3134].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3134] = NSRT.EncounterAlerts[3134] or {}
                NSRT.EncounterAlerts[3134].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Dimensius",
            desc = "Probably a bit rough in 1st week of pre-patch, use at own risk.",
            get = function() return NSRT.EncounterAlerts[3135] and NSRT.EncounterAlerts[3135].enabled end,
            set = function(self, fixedparam, value)
                NSRT.EncounterAlerts[3135] = NSRT.EncounterAlerts[3135] or {}
                NSRT.EncounterAlerts[3135].enabled = value
            end,
            nocombat = true,
        },
    }

    local readycheck_options1_table = {        
        
        {
            type = "label",
            get = function() return "Gear/Misc Checks" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Missing Item Check",
            desc = "Checks if any slots are empty",
            get = function() return NSRT.ReadyCheckSettings.MissingItemCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.MissingItemCheck = value
            end,
            nocombat = true,
        }, 
        {
            type = "toggle",
            boxfirst = true,
            name = "Item Level Check",
            desc = "Checks if you have any slot equipped below the minimum item level",
            get = function() return NSRT.ReadyCheckSettings.ItemLevelCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.ItemLevelCheck = value
            end,
            nocombat = true,
        }, 
        {
            type = "toggle",
            boxfirst = true,
            name = "Embellishment Check",
            desc = "Checks if you have 2 Embellishments equipped",
            get = function() return NSRT.ReadyCheckSettings.CraftedCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.CraftedCheck = value
            end,
            nocombat = true,
        }, 
        {
            type = "toggle",
            boxfirst = true,
            name = "4pc Check",
            desc = "Checks if you have 4pc of the current raid-tier equipped.",
            get = function() return NSRT.ReadyCheckSettings.TierCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.TierCheck = value
            end,
            nocombat = true,
        }, 
        {
            type = "toggle",
            boxfirst = true,
            name = "Enchant Check",
            desc = "Checks if you have all slots enchanted",
            get = function() return NSRT.ReadyCheckSettings.EnchantCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.EnchantCheck = value
            end,
            nocombat = true,
        }, 
        {
            type = "toggle",
            boxfirst = true,
            name = "Gem Check",
            desc = "Checks if you have all slots gemmed",
            get = function() return NSRT.ReadyCheckSettings.GemCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.GemCheck = value
            end,
            nocombat = true,
        }, 
        {
            type = "toggle",
            boxfirst = true,
            name = "Repair Check",
            desc = "Checks if any piece needs repair",
            get = function() return NSRT.ReadyCheckSettings.RepairCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.RepairCheck = value
            end,
            nocombat = true,
        },         
        {
            type = "toggle",
            boxfirst = true,
            name = "Gateway Control Shard Check",
            desc = "Checks if you have a Gateway Control Shard and whether or not it is located on your actionbars",
            get = function() return NSRT.ReadyCheckSettings.GatewayShardCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.GatewayShardCheck = value
            end,
            nocombat = true,
        }, 

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return "Buff Checks" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Raid-Buff Check",
            desc = "Checks if any relevant class needs your buff",
            get = function() return NSRT.ReadyCheckSettings.RaidBuffCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.RaidBuffCheck = value
            end,
            nocombat = true,
        }, 

        {
            type = "toggle",
            boxfirst = true,
            name = "Healer Soulstone Check",
            desc = "Checks for Warlocks whether they have soulstoned a healer and it has at least 5m duration left. It will only check this if Soulstone is ready or has less than 30s CD left.",
            get = function() return NSRT.ReadyCheckSettings.SoulstoneCheck end,
            set = function(self, fixedparam, value)
                NSRT.ReadyCheckSettings.SoulstoneCheck = value
            end,
            nocombat = true,
        }, 

        
        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return "Cooldowns Options" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Cooldown Checking",
            desc = "Enable cooldown checking for your cooldowns on ready check. This is only active in Heroic and Mythic Raids.",
            get = function() return NSRT.Settings["CheckCooldowns"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["CHECK_COOLDOWNS"] = true
                NSRT.Settings["CheckCooldowns"] = value
            end,
            nocombat = true
        },
        {
            type = "range",
            name = "Pull Timer",
            desc = "Pull timer used for cooldown checking.",
            get = function() return NSRT.Settings["CooldownThreshold"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["CooldownThreshold"] = value
            end,
            min = 10,
            max = 60,
            step = 1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Unready on Cooldown",
            desc = "Automatically unready if a tracked spell is on cooldown.",
            get = function() return NSRT.Settings["UnreadyOnCooldown"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["UNREADY_ON_COOLDOWN"] = true
                NSRT.Settings["UnreadyOnCooldown"] = value
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Edit Cooldowns",
            desc = "Edit the cooldowns checked on the ready check.",
            func = function(self)
                if not NSUI.cooldowns_frame:IsShown() then
                    NSUI.cooldowns_frame:Show()
                end
            end,
            nocombat = true
        }
    }

    local RaidBuffMenu = 
    {
        {
            type = "toggle",
            boxfirst = true,
            name = "Flex Raid",
            desc = "Check raid buffs up to Group 6 instead of only Group 4.",
            get = function() return NSRT.Settings.FlexRaid end,
            set = function(self, fixedparam, value)
                NSRT.Settings.FlexRaid = value
                NSI:UpdateRaidBuffFrame()
            end,
        },
        {
            type = "button",
            name = "Disable this Feature",
            desc = "Disable the Missing Raid Buffs Feature. You can re-enable it in the Setup Manager Settings.",
            func = function(self)
                NSRT.Settings.MissingRaidBuffs = false
                NSI:UpdateRaidBuffFrame()
            end,
        }
    }
    
    local privateaura_options1_table = {    
        {
            type = "label",
            get = function() return "Personal Private Aura Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura Display is enabled",
            get = function() return NSRT.PASettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.enabled = value
                NSI:InitPA()
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Private Auras to move them around.",
            func = function(self)
                NSI.IsPAPreview = not NSI.IsPAPreview
                NSI:UpdatePADisplay(true)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.PASettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PASettings", "GrowDirection") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return NSRT.PASettings.Spacing end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Spacing = value
                NSI:UpdatePADisplay(true)
            end,
            min = -5,
            max = 20,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return NSRT.PASettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Width = value
                NSI:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return NSRT.PASettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Height = value
                NSI:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return NSRT.PASettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.xOffset = value
                NSI:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return NSRT.PASettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.yOffset = value
                NSI:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return NSRT.PASettings.Limit end,
            set = function(self, fixedparam, value)
                NSRT.PASettings.Limit = value
                NSI:UpdatePADisplay(true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "RaidFrame Private Aura Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura on Raidframes are enabled",
            get = function() return NSRT.PARaidSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.enabled = value
                if NSRT.PARaidSettings.enabled then
                    NSI:InitRaidPA(UnitInRaid("player"))
                else -- clean up both PA frames in case they exist
                    NSI:InitRaidPA(true)
                    NSI:InitRaidPA(false)
                end
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Preview",
            desc = "Preview Private Auras on your own Raidframe. This only works if you actually have a frame for yourself and you can't drag this one around, use the x/y offset instead.",
            func = function(self)
                NSI.IsRaidPAPreview = not NSI.IsRaidPAPreview
                NSI:UpdatePADisplay(false)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.PARaidSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "GrowDirection") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.Spacing end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Spacing = value
                NSI:UpdatePADisplay(false)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Width = value
                NSI:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Height = value
                NSI:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.xOffset = value
                NSI:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return NSRT.PARaidSettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.yOffset = value
                NSI:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return NSRT.PARaidSettings.Limit end,
            set = function(self, fixedparam, value)
                NSRT.PARaidSettings.Limit = value
                NSI:UpdatePADisplay(false)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Private Aura Sounds" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Edit Sounds",
            desc = "Open the Private Aura Sounds Editor",
            func = function()
                if not NSUI.pasound_frame:IsShown() then
                    NSUI.pasound_frame:Show()
                end
            end,
            nocombat = true,
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Default Private Aura Sounds",
            desc = "This applies Sounds to all Raid Private Auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spellid's yourself previously this button will NOT overwrite that.",
            get = function() return NSRT.UseDefaultPASounds end,
            set = function(self, fixedparam, value)
                NSRT.UseDefaultPASounds = value
                if NSRT.UseDefaultPASounds then
                    NSI:ApplyDefaultPASounds()
                    NSI:RefreshPASoundEditUI()
                end
            end,
            nocombat = true,
        },
        {
            type = "breakline",
        },
        
        {
            type = "label",
            get = function() return "Co-Tank Private Auras" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Auras for Co-Tanks are enabled",
            get = function() return NSRT.PATankSettings.enabled end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.enabled = value
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Co-Tank Private Auras.",
            func = function(self)
                NSI.IsTankPAPreview = not NSI.IsTankPAPreview
                NSI:UpdatePADisplay(false, true)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return NSRT.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "GrowDirection") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return NSRT.PATankSettings.Spacing end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Spacing = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return NSRT.PATankSettings.Width end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Width = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return NSRT.PATankSettings.Height end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Height = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return NSRT.PATankSettings.xOffset end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.xOffset = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return NSRT.PATankSettings.yOffset end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.yOffset = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return NSRT.PATankSettings.Limit end,
            set = function(self, fixedparam, value)
                NSRT.PATankSettings.Limit = value
                NSI:UpdatePADisplay(false, true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "This is the Grow-Direction used if there are more than 2 tanks. Rarely ever happens these days but has to be included.",
            get = function() return NSRT.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "MultiTankGrowDirection") end,
            nocombat = true,
        },
    }

    


    -- Build options menu for each tab
    DF:BuildMenu(general_tab, general_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        general_callback)
    DF:BuildMenu(nicknames_tab, nicknames_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nicknames_callback)
    DF:BuildMenu(setupmanager_tab, setupmanager_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        setupmanager_callback)
    DF:BuildMenu(reminder_tab, reminder_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_callback)
    DF:BuildMenu(reminder_note_tab, reminder_note_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_note_callback)
    DF:BuildMenu(assignments_tab, assignments_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        assignments_callback)
    DF:BuildMenu(encounteralerts_tab, encounteralerts_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        encounteralerts_callback)
    DF:BuildMenu(readycheck_tab, readycheck_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        readycheck_callback)
    DF:BuildMenu(NSI.RaidBuffCheck, RaidBuffMenu, 2, -30, 40, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
    DF:BuildMenu(privateaura_tab, privateaura_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        privateaura_callback)
    NSI.RaidBuffCheck:SetMovable(true)
    NSI.RaidBuffCheck:EnableMouse(true)

    -- Build UI
    NSUI.version_scrollbox = BuildVersionCheckUI(versions_tab)
    NSUI.nickname_frame = BuildNicknameEditUI()
    NSUI.cooldowns_frame = BuildCooldownsEditUI()
    NSUI.reminders_frame = BuildRemindersEditUI()
    NSUI.pasound_frame = BuildPASoundEditUI()
    NSUI.personal_reminders_frame = BuildPersonalRemindersEditUI()
    NSUI.timeline_tab = BuildTimelineTabUI(timeline_tab)

    -- Version Number in status bar
    local versionTitle = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Title")
    local verisonNumber = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Version")
    local statusBarText = versionTitle .. " v" .. verisonNumber .. " | |cFFFFFFFF" .. (authorsString) .. "|r"
    NSUI.StatusBar.authorName:SetText(statusBarText)
end

function NSUI:ToggleOptions()
    if NSUI:IsShown() then
        NSUI:Hide()
    else
        NSUI:Show()
    end
end

function NSI:NickNamesSyncPopup(unit, nicknametable) 
    local popup = DF:CreateSimplePanel(UIParent, 300, 120, "Sync Nicknames", "SyncNicknamesPopup", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local label = DF:CreateLabel(popup, NSAPI:Shorten(unit) .. " is attempting to sync their nicknames with you.", 11)

    label:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    label:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    label:SetJustifyH("CENTER")

    local cancel_button = DF:CreateButton(popup, function() popup:Hide() end, 130, 20, "Cancel")
    cancel_button:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, 10)
    cancel_button:SetTemplate(options_button_template)

    local accept_button = DF:CreateButton(popup, function() 
        NSI:SyncNickNamesAccept(nicknametable)
        popup:Hide() 
    end, 130, 20, "Accept")
    accept_button:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    accept_button:SetTemplate(options_button_template)

    return popup
end

function NSI:DisplayText(text, duration)
    if self:Restricted() then return end
    if NSUI and NSUI.generic_display then
        NSUI.generic_display.text:SetText(text)
        NSUI.generic_display:Show()
        if self.TextHideTimer then
            self.TextHideTimer:Cancel()
            self.TextHideTimer = nil
        end
        self.TextHideTimer = C_Timer.NewTimer(duration or 10, function() NSUI.generic_display:Hide() end)
    end
end

NSI.NSUI = NSUI
