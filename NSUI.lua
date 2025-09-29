local _, NSI = ... -- Internal namespace
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")
local WA = _G["WeakAuras"]

local window_width = 900
local window_height = 515
local expressway = [[Interface\AddOns\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]]

local TABS_LIST = {
    { name = "General",   text = "General" },
    { name = "Nicknames", text = "Nicknames" },
    { name = "Externals", text = "Externals" },
    { name = "Versions",  text = "Versions" },
    { name = "WeakAuras", text = "WeakAuras" },
    { name = "SetupManager", text = "Setup Manager"},
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
    ["externals"] = {},
    ["versions"] = {},
}

-- need to run this code on settings change
local function PASelfPingChanged()
    if C_AddOns.IsAddOnLoaded("MegaMacro") then return end -- don't mess with macros if user has MegaMacro as it will spam create macros
    local macrocount = 0
    local pafound = false
    for i = 1, 120 do
        local macroname = C_Macro.GetMacroName(i)
        if not macroname then break end
        macrocount = i
        if macroname == "NS PA Macro" then
            pafound = true
            local macrotext = "/run NSAPI:PrivateAura();"
            if NSRT.Settings["PASelfPing"] then
                 macrotext = macrotext.."\n/ping [@player] Warning;"
             end
            if NSRT.Settings["PAExtraAction"] then
                macrotext = macrotext.."\n/click ExtraActionButton1"
            end            
            if NSRT.Settings["LIQUID_MACRO"] then
                macrotext = macrotext.."\n/run WeakAuras.ScanEvents(\"LIQUID_PRIVATE_AURA_MACRO\", true)"
            end
             EditMacro(i, "NS PA Macro", 132288, macrotext, false)
            return
        end
    end
    if macrocount >= 120 then
        print("You reached the global Macro cap so the Private Aura Macro could not be created")
    elseif not pafound then
        macrocount = macrocount+1
        local macrotext = "/run NSAPI:PrivateAura();"
        if NSRT.Settings["PASelfPing"] then
             macrotext = macrotext.."\n/ping [@player] Warning;"
         end
        if NSRT.Settings["PAExtraAction"] then
            macrotext = macrotext.."\n/click ExtraActionButton1"
        end
        CreateMacro("NS PA Macro", 132288, macrotext, false)
    end
end

-- need to run this code on settings change
local function ExternalSelfPingChanged()
    if C_AddOns.IsAddOnLoaded("MegaMacro") then return end -- don't mess with macros if user has MegaMacro as it will spam create macros
    local macrocount = 0
    local extfound = false
    for i = 1, 120 do
        local macroname = C_Macro.GetMacroName(i)
        if not macroname then break end
        macrocount = i
        if macroname == "NS Ext Macro" then
            extfound = true
            local macrotext = NSRT.Settings["ExternalSelfPing"] and "/run NSAPI:ExternalRequest();\n/ping [@player] Assist;" or
                "/run NSAPI:ExternalRequest();"
            EditMacro(i, "NS Ext Macro", 135966, macrotext, false)
            extfound = true
            return
        end
    end
    if macrocount >= 120 then 
        print("You reached the global Macro cap so the External Macro could not be created")
    elseif not extfound then
        macrocount = macrocount+1
        local macrotext = NSRT.Settings["ExternalSelfPing"] and "/run NSAPI:ExternalRequest();\n/ping [@player] Assist;" or "/run NSAPI:ExternalRequest();"
        CreateMacro("NS Ext Macro", 135966, macrotext, false)
    end
end

-- suf setup guide popup
local function BuildSUFSetupGuidePopup()
    local popup = DF:CreateSimplePanel(UIParent, 300, 130, "SUF Setup Guide", "SUFSetupGuidePopup")
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameLevel(100)

    popup.text_entry_label = DF:CreateLabel(popup, "Copy this code and create a new SUF tag with it:", 9.5, "white")
    popup.text_entry_label:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    
    popup.text_entry = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "$parentTextEntry", true, true, false)
    popup.text_entry:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -45)
    popup.text_entry:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 10)
    DF:ApplyStandardBackdrop(popup.text_entry)
    DF:ReskinSlider(popup.text_entry.scroll)
    
    local tag_code = [[function(unit)
    local name = UnitName(unit)
    return name and NSAPI and NSAPI:GetName(name, "SuF") or name
end]]
    popup:SetScript("OnShow", function(self)
        popup.text_entry:SetText(tag_code)
        popup.text_entry.editbox:HighlightText()
        popup.text_entry:SetFocus()
    end)

    return popup
end

-- version check ui
local component_type = "WA"
local checkable_components = { "WA", "Addon", "Note" }
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
        "Hides Version Check Responses of Users that are on the correct version and do not have any duplicates")
    local hide_version_response_label = DF:CreateLabel(parent, "Hide Version Check Responses", 10, "white", "", nil,
        "VersionCheckResponseLabel", "overlay")
    hide_version_response_label:SetTemplate(options_text_template)
    hide_version_response_label:SetPoint("LEFT", hide_version_response_button, "RIGHT", 2, 0)
    local component_type_label = DF:CreateLabel(parent, "Component Type", 9.5, "white")
    component_type_label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -130)
    
    local component_type_dropdown = DF:CreateDropDown(parent, function() return build_checkable_components_options() end, checkable_components[1])
    component_type_dropdown:SetTemplate(options_dropdown_template)
    component_type_dropdown:SetPoint("LEFT", component_type_label, "RIGHT", 5, 0)

    local component_name_label = DF:CreateLabel(parent, "WeakAura/Addon Name", 9.5, "white")
    component_name_label:SetPoint("LEFT", component_type_dropdown, "RIGHT", 10, 0)

    local component_name_entry = DF:CreateTextEntry(parent, function(_, _, value) component_name = value end, 250, 18)
    component_name_entry:SetTemplate(options_button_template)
    component_name_entry:SetPoint("LEFT", component_name_label, "RIGHT", 5, 0)
    component_name_entry:SetHook("OnEditFocusGained", function(self)
        component_name_entry.WAAutoCompleteList = NSRT.NSUI.AutoComplete["WA"] or {}
        component_name_entry.AddonAutoCompleteList = NSRT.NSUI.AutoComplete["Addon"] or {}
        local component_type = component_type_dropdown:GetValue()
        if component_type == "WA" then
            component_name_entry:SetAsAutoComplete("WAAutoCompleteList", _, true)
        elseif component_type == "Addon" then
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

    local duplicate_header = DF:CreateLabel(parent, "Duplicate", 11)
    duplicate_header:SetPoint("LEFT", version_number_header, "RIGHT", 50, 0)

    local ignore_header = DF:CreateLabel(parent, "Ignore Check", 11)
    ignore_header:SetPoint("LEFT", duplicate_header, "RIGHT", 50, 0)

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local thisData = data[index] -- thisData = {{name = "Ravxd", version = 1.0, duplicate = true}}
            if thisData then
                local line = self:GetLine(i)

                local name = thisData.name
                local version = thisData.version
                local duplicate = thisData.duplicate
                local ignore = thisData.ignoreCheck
                local nickname = NSAPI:Shorten(name)

                line.name:SetText(nickname)
                line.version:SetText(version)
                line.duplicates:SetText(duplicate and "Yes" or "No")
                line.ignorelist:SetText(ignore and "Yes" or "No")

                -- version number color                
                if version and version == "Offline" then
                    line.version:SetTextColor(0.5, 0.5, 0.5, 1)
                elseif version and data[1] and data[1].version and version == data[1].version then
                    line.version:SetTextColor(0, 1, 0, 1)
                else
                    line.version:SetTextColor(1, 0, 0, 1)
                end

                -- duplicates color
                if duplicate then
                    line.duplicates:SetTextColor(1, 0, 0, 1)
                else
                    line.duplicates:SetTextColor(0, 1, 0, 1)
                end

                if ignore then
                    line.ignorelist:SetTextColor(1, 0, 0, 1)
                else
                    line.ignorelist:SetTextColor(0, 1, 0, 1)
                end
                
                line:SetScript("OnClick", function(self)
                    local message = ""
                    local now = GetTime()
                    if (NSI.VersionCheckData.lastclick[name] and now < NSI.VersionCheckData.lastclick[name] + 5) or (thisData.version == NSI.VersionCheckData.version and (not thisData.duplicate) and (not thisData.ignoreCheck)) or thisData.version == "No Response" then return end                    
                    NSI.VersionCheckData.lastclick[name] = now
                    if NSI.VersionCheckData.type == "WA" then
                        local url = NSI.VersionCheckData.url ~= "" and NSI.VersionCheckData.url or NSI.VersionCheckData.name
                        if thisData.version == "WA Missing" then message = "Please install the WeakAura: "..url
                        elseif thisData.version ~= NSI.VersionCheckData.version then message = "Please update your WeakAura: "..url end
                        if thisData.duplicate then
                            if message == "" then 
                                message = "Please delete the duplicate WeakAura of: '"..NSI.VersionCheckData.name.."'"
                            else 
                                message = message.." Please also delete the duplicate WeakAura"
                            end
                        end                        
                    elseif NSI.VersionCheckData.type == "Addon" then
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

        local duplicates = line:CreateFontString(nil, "OVERLAY")
        duplicates:SetWidth(100)
        duplicates:SetJustifyH("LEFT")
        duplicates:SetFont(expressway, 12, "OUTLINE")
        duplicates:SetPoint("LEFT", version, "RIGHT", 45, 0)
        line.duplicates = duplicates

        
        local ignorelist = line:CreateFontString(nil, "OVERLAY")
        ignorelist:SetWidth(100)
        ignorelist:SetJustifyH("LEFT")
        ignorelist:SetFont(expressway, 12, "OUTLINE")
        ignorelist:SetPoint("LEFT", duplicates, "RIGHT", 5, 0)
        line.ignorelist = ignorelist

        return line
    end

    local scrollLines = 19
    -- sample data for testing
    local sample_data = {
        { name = "Player1",  version = "1.0.0",         duplicate = false },
        { name = "Player2",  version = "WA Missing",    duplicate = false },
        { name = "Player3",  version = "1.0.1",         duplicate = true },
        { name = "Player4",  version = "0.9.9",         duplicate = false },
        { name = "Player5",  version = "1.0.0",         duplicate = false },
        { name = "Player6",  version = "Addon Missing", duplicate = false },
        { name = "Player7",  version = "1.0.0",         duplicate = true },
        { name = "Player8",  version = "0.9.8",         duplicate = false },
        { name = "Player9",  version = "1.0.0",         duplicate = false },
        { name = "Player10", version = "Note Missing",  duplicate = false },
        { name = "Player11", version = "1.0.0",         duplicate = false },
        { name = "Player12", version = "0.9.9",         duplicate = true },
        { name = "Player13", version = "1.0.0",         duplicate = false },
        { name = "Player14", version = "WA Missing",    duplicate = false },
        { name = "Player15", version = "1.0.0",         duplicate = false },
        { name = "Player16", version = "0.9.7",         duplicate = false },
        { name = "Player17", version = "1.0.0",         duplicate = true },
        { name = "Player18", version = "Addon Missing", duplicate = false },
        { name = "Player19", version = "1.0.0",         duplicate = false },
        { name = "Player20", version = "0.9.9",         duplicate = false }
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
        local currentData = self:GetData() -- currentData = {{name, version, duplicate}...}
        if self.name_map[data.name] then
            if NSRT.Settings["VersionCheckRemoveResponse"] and currentData[1] and currentData[1].version and data.version and data.version == currentData[1].version and data.version ~= "WA Missing" and data.version ~= "Addon Missing" and data.version ~= "Note Missing" and (not data.duplicate) and (not data.ignoreCheck) then
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
        if text and text ~= ""  and component_type ~= "Note" and not tContains(NSRT.NSUI.AutoComplete[component_type], text) then
            tinsert(NSRT.NSUI.AutoComplete[component_type], text)
        end

        if not text or text == "" and component_type ~= "Note" then return end
        
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
        { "WA: Northern Sky Liberation of Undermine", { "WA", "Northern Sky Liberation of Undermine" } },
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
            NSI:Print("new value selected: " .. newType)
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
    local externals_tab = tabContainer:GetTabFrameByName("Externals")
    local cooldowns_tab = tabContainer:GetTabFrameByName("Cooldowns")
    local versions_tab = tabContainer:GetTabFrameByName("Versions")
    local weakaura_tab = tabContainer:GetTabFrameByName("WeakAuras")
    local setupmanager_tab = tabContainer:GetTabFrameByName("SetupManager")

    -- generic text display
    local generic_display = CreateFrame("Frame", "NSUIGenericDisplay", UIParent, "BackdropTemplate")
    generic_display:SetPoint("CENTER", UIParent, "CENTER", 0, 350)
    generic_display:SetSize(300, 100)
    generic_display.text = generic_display:CreateFontString(nil, "OVERLAY")
    generic_display.text:SetFont(expressway, 20, "OUTLINE")
    generic_display.text:SetPoint("CENTER", generic_display, "CENTER", 0, 0)
    generic_display:Hide()
    NSUI.generic_display = generic_display
    -- externals anchor frame
    local externals_anchor_panel_options = {
        NoCloseButton = true,
        NoTitleBar = true,
        DontRightClickClose = true
    }
    local externals_anchor = CreateFrame("Frame", "ExternalsAnchor", UIParent, "BackdropTemplate")
    NSUI.externals_anchor = externals_anchor
    externals_anchor:SetClampedToScreen(true)
    externals_anchor:SetMovable(true)
    externals_anchor:SetBackdrop({
        bgFile = "interface/editmode/editmodeuihighlightbackground",
        edgeFile = "interface/buttons/white8x8",
        edgeSize = 2,
        tile = true,
        tileSize = 16,
        insets = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0
        }
    })
    externals_anchor:SetBackdropBorderColor(1, 0, 0, 1)
    NSUI:LoadExternalsAnchorPosition()

    local externals_anchor_text = externals_anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    externals_anchor_text:SetPoint("CENTER", externals_anchor, "CENTER", 0, 0)
    externals_anchor_text:SetText("NS_EXT")
    externals_anchor.text = externals_anchor_text

    externals_anchor:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        elseif button == "RightButton" then
            NSUI:ResetExternalsAnchorPosition()
        end
    end)
    externals_anchor:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        NSUI:SaveExternalsAnchorPosition()
    end)
    externals_anchor:Hide()

    local external_frame = CreateFrame("Frame", "ExternalsFrame", UIParent)
    external_frame:SetPoint("BOTTOMLEFT", NSUI.externals_anchor, "BOTTOMLEFT", 0, 0)
    external_frame:SetPoint("TOPRIGHT", NSUI.externals_anchor, "TOPRIGHT", 0, 0)
    local external_frame_text = external_frame:CreateFontString(nil, "OVERLAY")
    external_frame_text:SetFont([[Interface\AddOns\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]], 20, "OUTLINE")
    external_frame_text:SetTextColor(1, 1, 1, 1)
    external_frame_text:SetPoint("CENTER", external_frame, "TOP", 0, 10)
    external_frame_text:SetText("NS_EXT")
    external_frame.text = external_frame_text
    local external_frame_texture = external_frame:CreateTexture("ExternalsFrameTexture", "OVERLAY")
    external_frame_texture:SetPoint("TOPLEFT", external_frame, "TOPLEFT", 0, 0)
    external_frame_texture:SetPoint("BOTTOMRIGHT", external_frame, "BOTTOMRIGHT", 0, 0)
    external_frame_texture:SetColorTexture(1, 0, 1, 0.5)
    external_frame.texture = external_frame_texture
    external_frame:Hide()
    NSUI.external_frame = external_frame

    -- dummy default variables until cvars are implemented
    local enableSUFNicknames = false
    -- TTS voice preview
    local tts_text_preview = ""

    -- keybinding logic
    local function getMacroKeybind(macroName)
        local binding = GetBindingKey(macroName)
        if binding then
            return binding
        else
            return "Unbound"
        end
    end

    local function bindKeybind(keyCombo, macroName)
        keyCombo = keyCombo:gsub("LeftButton", "BUTTON1")
            :gsub("RightButton", "BUTTON2")
            :gsub("MiddleButton", "BUTTON3")
            :gsub("Button4", "BUTTON4")
            :gsub("Button5", "BUTTON5")

        local existingBinding = GetBindingAction(keyCombo)
        if existingBinding and existingBinding ~= macroName and existingBinding ~= "" then
            SetBinding(keyCombo, nil)
            print("|cFF00FFFFNSRT:|r Overriding existing binding for " .. existingBinding .. " to " .. macroName)
        end

        local existingKeybind = GetBindingKey(macroName)
        if existingKeybind and existingKeybind ~= keyCombo then
            SetBinding(existingKeybind, nil)
        end

        local ok = SetBinding(keyCombo, macroName)
        if ok then
            SaveBindings(GetCurrentBindingSet())
            return true
        else
            return false
        end
    end

    local listening = false

    local function GetModifiedKeyString(key)
        local modifier = ""
        if IsControlKeyDown() then modifier = modifier .. "CTRL-" end
        if IsShiftKeyDown() then modifier = modifier .. "SHIFT-" end
        if IsAltKeyDown() then modifier = modifier .. "ALT-" end

        return modifier .. key
    end

    local clearKeybinding = function(self, _, macroName)
        SetBinding(GetBindingKey(macroName), nil)
        SaveBindings(GetCurrentBindingSet())
        self:SetText("Unbound")
        print("|cFF00FFFFNSRT:|r Keybinding cleared for " .. macroName)
    end

    local registerKeybinding = function(self, macroName, keybindName)
        if not listening then
            listening = true
        else
            return
        end

        local displayName = (macroName == "MACRO NS Ext Macro" and "External Macro") or (macroName == "MACRO NS PA Macro" and "Private Aura Macro") or (macroName == "MACRO NS Innervate" and "Innervate Macro") or "Macro"
        local keybindingFrame = DF:CreateSimplePanel(NSUI, 300, 75, "Keybinding: " .. displayName, "KeybindingFrame", {
            DontRightClickClose = true
        })
        keybindingFrame:SetPoint("CENTER", NSUI, "CENTER", 0, 0)
        keybindingFrame:SetFrameStrata("DIALOG")
        local keybindingFrame_text = keybindingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        keybindingFrame_text:SetPoint("CENTER", keybindingFrame, "CENTER", 0, 0)
        keybindingFrame_text:SetText([[Press a key or click here
    (with optional modifiers) to bind the]].."\n"..displayName)


        local function OnKeyDown(self, key)
            if listening then
                if key == "ESCAPE" then
                    listening = false
                    self:SetScript("OnKeyDown", nil)
                    self:SetPropagateKeyboardInput(false)
                    self:Hide()
                    NSUI:Show()
                    return
                end

                key = key:gsub("^LCTRL$", "CTRL")
                    :gsub("^RCTRL$", "CTRL")
                    :gsub("^LSHIFT$", "SHIFT")
                    :gsub("^RSHIFT$", "SHIFT")
                    :gsub("^LALT$", "ALT")
                    :gsub("^RALT$", "ALT")

                if key == "CTRL" or key == "SHIFT" or key == "ALT" then
                    return nil -- Don't register this as a full keybind yet
                end
                local keyCombo = GetModifiedKeyString(key)
                if keyCombo == "LeftButton" or keyCombo == "RightButton" then
                    return nil -- dont register pure mouse buttons as keybinds, only with modifier
                end

                -- Bind keybind
                bindKeybind(keyCombo, macroName)

                listening = false
                self:SetScript("OnKeyDown", nil)
                self:SetPropagateKeyboardInput(false)
                self:Hide()
                NSUI:Show()

                if general_tab:GetWidgetById(macroName) ~= nil then
                    general_tab:GetWidgetById(macroName):SetText(keyCombo)
                elseif externals_tab:GetWidgetById(macroName) ~= nil then
                    externals_tab:GetWidgetById(macroName):SetText(keyCombo)
                end
            end
        end

        keybindingFrame:SetScript("OnKeyDown", OnKeyDown)
        keybindingFrame:SetScript("OnMouseDown", OnKeyDown)
        keybindingFrame:SetScript("OnHide", function()
            listening = false
        end)
    end
    -- end of keybinding logic

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

    
    local weakauras_importaccept_options = {"Guild only", "Anyone", "None"}    
    local build_weakauras_importaccept_options = function()
        local t = {}
        for i = 1, #weakauras_importaccept_options do
            tinsert(t, {
                label = weakauras_importaccept_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["WeakAurasImportAccept"] = value
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

    -- WeakAuras imports
    local function ImportWeakAura(name)
        if WA and WA.Import then
            WA.Import(NSI:GetWeakAura(name))
        else
            print("Error:WeakAuras not found")
        end
    end

    local function SendWeakAuras()
        local popup = DF:CreateSimplePanel(NSUI, 300, 150, "Send WeakAura", "NSUISendWeakAurasPopup", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameLevel(100)

        popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "SendWATextEdit", true, false, true)
        popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.test_string_text_box)
        DF:ReskinSlider(popup.test_string_text_box.scroll)
        popup.test_string_text_box:SetFocus()

        popup.import_confirm_button = DF:CreateButton(popup, function()
            local import_string = popup.test_string_text_box:GetText()
            NSI:SendWAString(import_string)
            popup.test_string_text_box:SetText("")
            popup:Hide()
        end, 280, 20, "Send")
        popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
        popup.import_confirm_button:SetTemplate(options_button_template)

        return popup
    end

    -- WeakAuras whitelist popup
    local function WhitelistPopup()
        local parent = NSUI
        local whitelisted_wa_edit_frame = DF:CreateSimplePanel(parent, 400, window_height / 2,
            "WeakAuras Update Whitelist",
            "WhitelistWAEditFrame", {
                DontRightClickClose = true,
                NoScripts = true
            })
        whitelisted_wa_edit_frame:ClearAllPoints()
        whitelisted_wa_edit_frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 2)
        whitelisted_wa_edit_frame:Hide()


        local function PrepareData()
            local data = {}
            for _, v in pairs(NSRT.Settings['UpdateWhitelist']) do
                tinsert(data, { url = v.url, name = v.name })
            end
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
                local whitelistData = data[index]
                if whitelistData then
                    local line = self:GetLine(i)

                    line.name = whitelistData.name
                    line.url = whitelistData.url

                    line.nameText:SetText(line.name)
                    line.urlTextEntry:SetText(line.url)
                end
            end
        end

        local function createLineFunc(self, index)
            local parent = self
            local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
            line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
            line:SetSize(self:GetWidth() - 2, self.LineHeight)
            DF:ApplyStandardBackdrop(line)

            -- Name text
            line.nameText = DF:CreateLabel(line, "", 9.5, "white")
            line.nameText:SetWidth(120)
            line.nameText:SetTemplate(options_text_template)
            line.nameText:SetPoint("LEFT", line, "LEFT", 5, 0)

            line.urlTextEntry = DF:CreateTextEntry(line, function() end, 200, 20)
            line.urlTextEntry:SetAutoSelectTextOnFocus(true)
            line.urlTextEntry:SetTemplate(options_dropdown_template)
            line.urlTextEntry:SetPoint("LEFT", line.nameText, "RIGHT", 5, 0)

            -- Delete button
            line.deleteButton = DF:CreateButton(line, function()
                NSI:RemoveWhitelistURL(line.url, line.name)
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

        local presetScrollLines = 9
        local whitelisted_wa_edit_scrollbox = DF:CreateScrollBox(whitelisted_wa_edit_frame,
            "$parentWhitelistedWAEditScrollBox", refresh, {}, 360,
            window_height / 2 - 75, presetScrollLines, 20, createLineFunc)
        whitelisted_wa_edit_scrollbox:SetPoint("TOPLEFT", whitelisted_wa_edit_frame, "TOPLEFT", 10, -30)
        -- version_presets_edit_scrollbox:SetPoint("BOTTOMRIGHT", version_presets_edit_frame, "BOTTOMRIGHT", -25, 30)
        whitelisted_wa_edit_scrollbox.MasterRefresh = MasterRefresh
        DF:ReskinSlider(whitelisted_wa_edit_scrollbox)

        for i = 1, presetScrollLines do
            whitelisted_wa_edit_scrollbox:CreateLine(createLineFunc)
        end

        whitelisted_wa_edit_scrollbox:SetScript("OnShow", function(self)
            self:MasterRefresh()
        end)

        -- Add new preset
        local new_name_label = DF:CreateLabel(whitelisted_wa_edit_frame, "Name:", 11)
        new_name_label:SetWidth(35)
        new_name_label:SetPoint("TOPLEFT", whitelisted_wa_edit_scrollbox, "BOTTOMLEFT", 0, -20)

        local new_name_entry = DF:CreateTextEntry(whitelisted_wa_edit_frame, function() end, 100, 20)
        new_name_entry:SetPoint("LEFT", new_name_label, "RIGHT", 5, 0)
        new_name_entry:SetTemplate(options_dropdown_template)

        local new_url_label = DF:CreateLabel(whitelisted_wa_edit_frame, "URL:", 11)
        new_url_label:SetWidth(30)
        new_url_label:SetPoint("LEFT", new_name_entry, "RIGHT", 10, 0)

        local new_url_entry = DF:CreateTextEntry(whitelisted_wa_edit_frame, function() end, 120, 20)
        new_url_entry:SetPoint("LEFT", new_url_label, "RIGHT", 5, 0)
        new_url_entry:SetTemplate(options_dropdown_template)

        local add_button = DF:CreateButton(whitelisted_wa_edit_frame, function()
            local name = new_name_entry:GetText()
            local url = new_url_entry:GetText()
            NSI:AddWhitelistURL(url, name)
            whitelisted_wa_edit_scrollbox:MasterRefresh()
            new_name_entry:SetText("")
            new_url_entry:SetText("")
        end, 60, 20, "New")
        add_button:SetPoint("BOTTOMRIGHT", whitelisted_wa_edit_frame, "BOTTOMRIGHT", -10, 10)
        add_button:SetTemplate(options_button_template)

        return whitelisted_wa_edit_frame
    end
    NSUI.whitelisted_wa_edit_frame = WhitelistPopup()
    -- when any setting is changed, call these respective callback function
    local general_callback = function()

        if NSUI.OptionsChanged.general["PA_MACRO"] then
            PASelfPingChanged()
        end        
        if NSUI.OptionsChanged.general["DEBUGLOGS"] then
            if NSRT.Settings["DebugLogs"] then -- Add this data if enables this after a wipe as the data exists anyway
                NSI:Print("Macro Data", NSI.MacroPresses)
                NSI:Print("Assigned Externals", NSI.AssignedExternals)
                NSI.AssignedExternals = {}
                NSI.MacroPresses = {}
            end
        end
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

        if NSUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] then
            NSI:Grid2NickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] then
            NSI:UnhaltedNickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["MRT_NICKNAMES"] then
            NSI:MRTNickNameUpdated(true)
        end

        if NSUI.OptionsChanged.nicknames["WA_NICKNAMES"] then
            NSI:WeakAurasNickNameUpdated()
        end

        wipe(NSUI.OptionsChanged["nicknames"])
    end

    local externals_callback = function()
        if NSUI.OptionsChanged.externals["EXTERNAL_MACRO"] then
            ExternalSelfPingChanged()
        end

        wipe(NSUI.OptionsChanged["externals"])
    end

    local versions_callback = function()
        wipe(NSUI.OptionsChanged["versions"])
    end

    local weakauras_callback = function()
        wipe(NSUI.OptionsChanged["WeakAuras"])
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
            desc = "Enables Debug Logging, which prints a bunch of information and adds it to DevTool. This might Error if you do not have the DevTool Addon installed.\nIf enabled after a wipe, it will still add External and Macro data to DevTool",
            get = function() return NSRT.Settings["DebugLogs"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["DEBUGLOGS"] = true
                NSRT.Settings["DebugLogs"] = value
            end,
        },

        {
            type = "blank",
        },

        {
            type = "label",
            get = function() return "MRT Options" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable MRT Note Comparison",
            desc = "Enables MRT note comparison on ready check.",
            get = function() return NSRT.Settings["MRTNoteComparison"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.general["MRT_NOTE_COMPARISON"] = true
                NSRT.Settings["MRTNoteComparison"] = value
            end,
            nocombat = true
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
        {
            type = "breakline"
        },   
        {
            type = "label",
            get = function() return "Private Aura Macro" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable @player Ping",
            desc = "Enable a @player ping when the private aura macro is used.",
            get = function() return NSRT.Settings["PASelfPing"] end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.general["PA_MACRO"] = true
                NSRT.Settings["PASelfPing"] = value 
            end,
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Combine Extra Action Button",
            desc = "Combine the extra action button with the private aura macro.",
            get = function() return NSRT.Settings["PAExtraAction"] end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.general["PA_MACRO"] = true
                NSRT.Settings["PAExtraAction"] = value 
            end,
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Add Liquid Private Aura Macro",
            desc = "Add Scan Event for Liquid Private Aura Macro",
            get = function() return NSRT.Settings["LIQUID_MACRO"] end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.general["PA_MACRO"] = true
                NSRT.Settings["LIQUID_MACRO"] = value 
            end,
            nocombat = true
        },
        {
            type = "label",
            get = function() return "Private Aura Keybind:" end,
        },
        {
            type = "button",
            name = getMacroKeybind("MACRO NS PA Macro"),
            desc = "Set the keybind for the private aura macro",
            param1 = "MACRO NS PA Macro",
            param2 = "Private Aura Keybind", -- whatever reloe names the keybind to be in Bindings.xml
            func = function(self, _, param1, param2)
                registerKeybinding(self, param1, param2)
            end,
            id = "MACRO NS PA Macro",
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

    local nicknames_options1_table = {
        
        { type = "label", get = function() return "Nicknames Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "textentry",
            name = "Nickname",
            desc = "Set your nickname to be seen by others and used in assignments",
            get = function() return NSRT.Settings["MyNickName"] or "" end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.nicknames["NICKNAME"] = true
                NSRT.Settings["MyNickName"] = WeakAuras.WA_Utf8Sub(value, 12)
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
            name = "Enable Blizzard Nicknames",
            desc = "Enable Nicknames to be used with Blizzard unit frames.",
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
            get = function() return NSRT.Settings["SuF"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["SUF_NICKNAMES"] = true
                NSRT.Settings["SuF"] = value
            end,
            name = "Enable SUF Nicknames",
            desc = "Enable Nicknames to be used with SUF unit frames. This requires adding your own Tag to the addon. You can copy the required code by clicking on the small 'i'",
            nocombat = true,
            id = "SUF-Toggle"
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["WA"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["WA_NICKNAMES"] = true
                NSRT.Settings["WA"] = value
            end,
            name = "Enable WeakAuras Nicknames",
            desc = "Enable Nicknames to be used with WeakAuras. This only works if name formatting is used in Display or for any assignment aura.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["MRT"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["MRT_NICKNAMES"] = true
                NSRT.Settings["MRT"] = value
            end,
            name = "Enable MRT Nicknames",
            desc = "Enable Nicknames to be used with MRT. This affects the Cooldown Tracking and Note Display. Nicknames in Assignments will still work with this disabled as long as you have the character data.",
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
            desc = "Enable Nicknames to be used with Unhalted Unit Frames. This requires editing your Tags. Available options are [NSNickName] and [NSNickName:1-12]",
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

    local externals_options1_table = {
        { type = "label", get = function() return "Externals Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable @player Ping",
            desc = "Enable a @player ping when the external macro is used.",
            get = function() return NSRT.Settings["ExternalSelfPing"] end,
            set = function(self, fixedparam, value) 
                NSUI.OptionsChanged.externals["EXTERNAL_MACRO"] = true
                NSRT.Settings["ExternalSelfPing"] = value 
            end,
            nocombat = true
        },
        {
            type = "label",
            get = function() return "External Macro Keybind:" end,
        },
        {
            type = "button",
            name = getMacroKeybind("MACRO NS Ext Macro"),
            desc = "Set the keybind for the external macro",
            param1 = "MACRO NS Ext Macro",
            param2 = "External Macro Keybind",
            func = function(self, _, param1, param2) -- this only ever registers leftclick need to manually set right click
                registerKeybinding(self, param1, param2)
            end,
            id = "MACRO NS Ext Macro",
        },
        
        
        {
            type = "blank",
        },

        {
        type = "label",
        get = function() return "Innervate Request Keybind:" end,
        },
        
        {
            type = "button",
            name = getMacroKeybind("MACRO NS Innervate"),
            desc = "Set the keybind for the Innervate Request macro",
            param1 = "MACRO NS Innervate",
            param2 = "Innervate Request Macro Keybind",
            func = function(self, _, param1, param2) -- this only ever registers leftclick need to manually set right click
                registerKeybinding(self, param1, param2)
            end,
            id = "MACRO NS Innervate",
        },

        {
            type = "breakline"
        },
        {
            type = "button",
            name = "Test External",
            desc = "Simulate recieving an external.",
            func = function(self)
                NSI:DisplayExternal(237554, GetUnitName("player"))
            end,
            nocombat = true
        },
        {
            type = "blank",
        },
        {
            type = "button",
            name = "Toggle External Anchor",
            desc = "Toggle the external anchor frame.",
            func = function(self)
                if NSUI.externals_anchor:IsShown() then
                    NSUI.externals_anchor:Hide()
                else
                    NSUI.externals_anchor:Show()
                end
            end,
            nocombat = true
        },
    }

    local weakaura_options1_table = {
        
        {
            type = "label",
            get = function() return "Permanent Auras" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Anchor Auras 1440p",
            desc = "Import WeakAura Anchors required for all Northern Sky WeakAuras, scaled for a 1440p Monitor",
            func = function(self)
                ImportWeakAura("anchor_weakaura")
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "button",
            name = "Anchor Auras 1080p",
            desc = "Import WeakAura Anchors required for all Northern Sky WeakAuras, scaled for a 1080p Monitor",
            func = function(self)
                ImportWeakAura("anchor_weakaura_1080")
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "button",
            name = "External Alert",
            desc = "Import WeakAura External Alert required for the external macro.",
            func = function(self)
                ImportWeakAura("external_weakaura")
            end,
            nocombat = true,
            spacement = true
        },


        {
            type = "button",
            name = "Interrupt WA",
            desc = "Import Interrupt Anchor WeakAura",
            func = function(self)
                ImportWeakAura("interrupt_weakaura")
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return "Raid Auras" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = "Manaforge Raid WA",
            desc = "Import Manaforge Omega WeakAuras",            
            func = function(self)
                ImportWeakAura("raid_weakaura_manaforge")
            end,
            nocombat = true,
            spacement = true,
        },
        
        
        {
            type = "button",
            name = "Liberation Raid WA",
            desc = "Import Liberation of Undermine Raid WeakAuras",
            func = function(self)
                ImportWeakAura("raid_weakaura_undermine")
            end,
            nocombat = true,
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Other Misc Auras" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Manaforge Pace WA",
            desc = "Import Manaforge Omega Pace WA",            
            func = function(self)
                ImportWeakAura("pace_weakaura_manaforge")
            end,
            nocombat = true,
            spacement = true,
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return "WeakAura Updates" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Auto Update WL WA",
            desc = "Automatically update whitelisted WeakAuras. (Requires WeakAuras Companion Desktop Application)",
            get = function() return NSRT.Settings["AutoUpdateWA"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["AutoUpdateWA"] = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto Update Raid WA",
            desc = "Automatically updates or imports the current season's raid Northern Sky WeakAuras.",
            get = function() return NSRT.Settings["AutoUpdateRaidWA"] end,
            set = function(self, fixedparam, value)
                NSRT.Settings["AutoUpdateRaidWA"] = value
            end,
        },

        {
            type = "blank",
        },

        {
            type = "button",
            name = "Whitelist WeakAuras",
            desc = "Whitelist WeakAura URLs for auto updating.",
            func = function(self)
                if not NSUI.whitelisted_wa_edit_frame:IsShown() then
                    NSUI.whitelisted_wa_edit_frame:Show()
                else
                    NSUI.whitelisted_wa_edit_frame:Hide()
                end
            end,
            spacement = true
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "WeakAuras Sharing" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Send WeakAura to Raid",
            desc = "Send an individual WeakAura string to the raid.",
            func = function(self)
                SendWeakAuras()
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "select",
            get = function() return NSRT.Settings["WeakAurasImportAccept"] end,
            values = function() return build_weakauras_importaccept_options() end,
            name = "Import Accept",
            desc = "Choose who you are accepting WeakAuras imports to come from. Note that even if guild is selected here this still only works when in the same raid as them",
            nocombat = true
        },
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
        

    }

    -- Build options menu for each tab
    DF:BuildMenu(general_tab, general_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        general_callback)
    DF:BuildMenu(nicknames_tab, nicknames_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nicknames_callback)
    DF:BuildMenu(externals_tab, externals_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        externals_callback)
    DF:BuildMenu(weakaura_tab, weakaura_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        weakaura_callback)
    DF:BuildMenu(setupmanager_tab, setupmanager_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        setupmanager_callback)

    -- Add SUF Setup guide tooltip button thingy

    NSUI.suf_setup_guide_popup = BuildSUFSetupGuidePopup()

    local help_i_texture = [[Interface\common\help-i]]
    local SUF_Toggle = nicknames_tab:GetWidgetById("SUF-Toggle")
    local suf_help_button = DF:CreateButton(nicknames_tab, function()
        if NSUI.suf_setup_guide_popup and not NSUI.suf_setup_guide_popup:IsShown() then
            NSUI.suf_setup_guide_popup:Show()
        else
            NSUI.suf_setup_guide_popup:Hide()
        end
    end, 20, 20, "")
    suf_help_button:SetIcon(help_i_texture)
    suf_help_button:SetPoint("LEFT", SUF_Toggle.hasLabel, "RIGHT", 0, 0)

    -- Set right click functions for clearing keybinding on keybind buttons
    local PAMacroButton = general_tab:GetWidgetById("MACRO NS PA Macro")
    local ExternalMacroButton = externals_tab:GetWidgetById("MACRO NS Ext Macro")
    local InnervateMacroButton = externals_tab:GetWidgetById("MACRO NS Innervate")
    if PAMacroButton then
        PAMacroButton:SetClickFunction(clearKeybinding, PAMacroButton.param1, PAMacroButton.param2, "RightButton")
    end
    if ExternalMacroButton then
        ExternalMacroButton:SetClickFunction(clearKeybinding, ExternalMacroButton.param1, ExternalMacroButton.param2, "RightButton")
    end
    if InnervateMacroButton then
        InnervateMacroButton:SetClickFunction(clearKeybinding, InnervateMacroButton.param1, InnervateMacroButton.param2, "RightButton")
    end

    -- Build version check UI
    NSUI.version_scrollbox = BuildVersionCheckUI(versions_tab)
    NSUI.nickname_frame = BuildNicknameEditUI()
    NSUI.cooldowns_frame = BuildCooldownsEditUI()

    -- Version Number in status bar
    local versionTitle = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Title")
    local verisonNumber = C_AddOns.GetAddOnMetadata("NorthernSkyRaidTools", "Version")
    local statusBarText = versionTitle .. " v" .. verisonNumber .. " | |cFFFFFFFF" .. (authorsString) .. "|r"
    NSUI.StatusBar.authorName:SetText(statusBarText)
end

function NSI:DisplayExternal(spellId, unit)
    local text = ""
    if spellId == "NoInnervate" then        
        local spellIcon = C_Spell.GetSpellInfo(29166).iconID
        NSUI.external_frame.texture:SetTexture(spellIcon)
        text = "|cffff0000NO INNERVATE|r"
    elseif spellId then
        local spellIcon = C_Spell.GetSpellInfo(spellId).iconID
        NSUI.external_frame.texture:SetTexture(spellIcon)
        local giver = NSAPI:Shorten(unit, 8)
        text = "From: " .. giver
    else
        NSUI.external_frame.texture:SetTexture(237555)
        text = "|cffff0000NO EXTERNAL|r"
    end

    NSUI.external_frame.text:SetText(text)
    NSUI.external_frame:Show()

    C_Timer.After(4, function()
        NSUI.external_frame:Hide()
    end)
end

function NSUI:LoadExternalsAnchorPosition()
    NSRT.NSUI.externals_anchor.settings = NSRT.NSUI.externals_anchor.settings or {
        anchorPoint = {
            "CENTER", "UIParent", "CENTER", 0, 150
        },
        width = 70,
        height = 70
    }
    if not NSRT.NSUI.externals_anchor.settings.anchorPoint or not NSRT.NSUI.externals_anchor.settings.width or not NSRT.NSUI.externals_anchor.settings.height then
        NSI:Print("No externals anchor settings found.... THIS SHOULD NOT HAPPEN")
        return
    end
    NSUI.externals_anchor:SetPoint(unpack(NSRT.NSUI.externals_anchor.settings.anchorPoint))
    NSUI.externals_anchor:SetSize(NSRT.NSUI.externals_anchor.settings.width, NSRT.NSUI.externals_anchor.settings.height)
end

function NSUI:SaveExternalsAnchorPosition()
    local anchorPoint = { NSUI.externals_anchor:GetPoint() }
    anchorPoint[2] = "UIParent"

    local width, height = NSUI.externals_anchor:GetSize()
    NSRT.NSUI.externals_anchor.settings = {
        anchorPoint = anchorPoint,
        width = width,
        height = height
    }
end

function NSUI:ResetExternalsAnchorPosition()
    NSUI.externals_anchor:ClearAllPoints()
    NSUI.externals_anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    NSUI.externals_anchor:SetSize(70, 70)
    NSRT.NSUI.externals_anchor.settings.anchorPoint = { "CENTER", UIParent, "CENTER", 0, 150 }
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

function NSI:WAImportPopup(unit, str) 
    local popup = DF:CreateSimplePanel(UIParent, 300, 120, "WA Import", "WAImportPopup", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 150)

    local label = DF:CreateLabel(popup, NSAPI:Shorten(unit) .. " is attempting to send you a WeakAura.", 11)

    label:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    label:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    label:SetJustifyH("CENTER")

    local cancel_button = DF:CreateButton(popup, function() popup:Hide() end, 130, 20, "Cancel")
    cancel_button:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, 10)
    cancel_button:SetTemplate(options_button_template)

    local accept_button = DF:CreateButton(popup, function() 
        WA.Import(str)
        popup:Hide() 
    end, 130, 20, "Accept")
    accept_button:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    accept_button:SetTemplate(options_button_template)

    return popup
end

function NSAPI:DisplayText(text, duration)
    if NSUI and NSUI.generic_display then
        NSUI.generic_display.text:SetText(text)
        NSUI.generic_display:Show()
        C_Timer.After(duration or 4, function() NSUI.generic_display:Hide() end)
    end
end

NSI.NSUI = NSUI