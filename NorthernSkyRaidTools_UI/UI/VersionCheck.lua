local addonId = "NorthernSkyRaidTools"
local NSI = _G.NorthernSkyRaidTools
local STYLE = NSI.UI.Style
local Accent = STYLE.Accent
local C = NSI.UI.Components

local Core = NSI.UI.Core
local window_height = Core.window_height

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
                value = checkable_components[i],
                onclick = function(_, _, value)
                    if onSelect then onSelect(value) end
                end
            })
        end
    end
    return t
end

local ROW_H   = 22      -- one row of controls / one result row
local ROW_GAP = 8       -- between control rows inside a card
local COLUMNS = { 0.30, 0.40, 0.30 }   -- character, version, ignore: shares of the row width

local function BuildVersionCheckUI(parent)
    local PAD, CARD_PAD, CARD_GAP = 10, C.CardPad, C.CardGap
    local componentType = checkable_components[1]
    local selectedEncID, selectedAlertID
    local selectedDiffID = 16
    local UpdateComponentType, RefreshAlertSelection, RunVersionCheck, SelectEncounterAlert
    local typeDropdown, encounterDropdown, difficultyDropdown, alertDropdown, presetDropdown
    local nameEntry

    -- ------------------------------------------------------------------
    --  Card 1: what to check
    -- ------------------------------------------------------------------
    local cardCheck = C.CreateSectionCard(parent, 400, true)
    cardCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, -PAD)
    cardCheck:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD, -PAD)
    cardCheck.content:SetPoint("TOPRIGHT", cardCheck, "TOPRIGHT", -CARD_PAD, -(cardCheck.headerH + CARD_PAD))
    cardCheck.title:SetText(T("Version Check"))
    local content = cardCheck.content

    -- Row 1: component type, addon name (or the encounter pickers on row 2), Check Versions
    typeDropdown = C.CreateDropdown(content, T("Component Type"), function()
        return build_checkable_components_options(function(value)
            componentType = value
            typeDropdown:Refresh()
            UpdateComponentType()
        end)
    end, function() return T(componentType) end, 270, ROW_H, "NSRTVersionCheckType", nil, nil, nil, nil, 120)
    typeDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

    -- Known addon names are suggested while typing in the Addon Name box.
    nameEntry = C.CreateTextEntry(content, T("Addon Name"), nil, nil, 360, ROW_H, false, nil, nil,
        "NSRTVersionCheckName", nil, 250)
    nameEntry:SetPoint("LEFT", typeDropdown.frame, "RIGHT", 16, 0)

    local suggestions = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, UIParent)
    suggestions:SetFrameStrata("TOOLTIP")
    suggestions:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    suggestions:SetBackdropColor(unpack(STYLE.surface_panel))
    STYLE.PaintAccent(suggestions, "SetBackdropBorderColor", 0.7)
    suggestions:Hide()
    local SUGGEST_MAX = 8
    local suggestRows = {}
    local function HideSuggestions() suggestions:Hide() end
    local function ShowSuggestions()
        if componentType ~= "Addon" then return HideSuggestions() end
        local text = (nameEntry.editBox:GetText() or ""):lower()
        local known = NSRT.NSUI.AutoComplete["Addon"] or {}
        local shown = 0
        for _, name in ipairs(known) do
            if text == "" or name:lower():find(text, 1, true) then
                if name:lower() ~= text then
                    shown = shown + 1
                    if shown > SUGGEST_MAX then shown = SUGGEST_MAX; break end
                    local row = suggestRows[shown]
                    if not row then
                        row = CreateFrame("Button", nil, suggestions)
                        row:SetHeight(ROW_H)
                        row:SetPoint("TOPLEFT", suggestions, "TOPLEFT", 1, -((shown - 1) * ROW_H) - 1)
                        row:SetPoint("TOPRIGHT", suggestions, "TOPRIGHT", -1, -((shown - 1) * ROW_H) - 1)
                        row.text = row:CreateFontString(nil, "OVERLAY")
                        NSI:SetUIFont(row.text, "small", "")
                        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
                        row.hover = row:CreateTexture(nil, "BACKGROUND")
                        row.hover:SetAllPoints()
                        NSI.UI.Style.PaintAccent(row.hover, "SetColorTexture", 0.25)
                        row.hover:Hide()
                        row:SetScript("OnEnter", function(self) self.hover:Show() end)
                        row:SetScript("OnLeave", function(self) self.hover:Hide() end)
                        row:SetScript("OnClick", function(self)
                            nameEntry:SetValue(self.value)
                            suggestions:Hide()
                        end)
                        suggestRows[shown] = row
                    end
                    row.value = name
                    row.text:SetText(name)
                    row:Show()
                end
            end
        end
        for i = shown + 1, #suggestRows do suggestRows[i]:Hide() end
        if shown == 0 then return HideSuggestions() end
        suggestions:SetSize(nameEntry.frame:GetWidth() - 8, shown * ROW_H + 2)
        suggestions:ClearAllPoints()
        suggestions:SetPoint("TOPRIGHT", nameEntry.frame, "BOTTOMRIGHT", 0, -2)
        suggestions:Show()
    end
    nameEntry.editBox:HookScript("OnEditFocusGained", ShowSuggestions)
    nameEntry.editBox:HookScript("OnTextChanged", function(_, userInput) if userInput then ShowSuggestions() end end)
    nameEntry.editBox:HookScript("OnEditFocusLost", function() C_Timer.After(0.15, HideSuggestions) end)
    nameEntry.editBox:HookScript("OnEnterPressed", HideSuggestions)
    parent:HookScript("OnHide", HideSuggestions)

    local checkButton = C.CreateButton(content, T("Check Versions"), function() RunVersionCheck() end, 140, ROW_H,
        nil, nil, nil, nil, function()
            return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or NSRT.Settings["Debug"] and true or false
        end)
    checkButton:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

    -- Row 2 (Encounter Alert only): encounter, difficulty, alert
    local encounterRow = CreateFrame("Frame", nil, content)
    encounterRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(ROW_H + ROW_GAP))
    encounterRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(ROW_H + ROW_GAP))
    encounterRow:SetHeight(ROW_H)
    encounterRow:Hide()

    local function BuildAlertOptions()
        local options = {}
        local alerts = NSRT.EncounterAlerts[selectedEncID] and NSRT.EncounterAlerts[selectedEncID][selectedDiffID]
        for alertKey, alert in pairs(alerts or {}) do
            local name = alert.name or T("Unnamed")
            options[#options + 1] = {
                label = alert.group and (alert.group .. " - " .. name) or name,
                value = alert.internalID or alertKey,
                onclick = function(_, _, value)
                    selectedAlertID = value
                    alertDropdown:Refresh()
                end,
            }
        end
        table.sort(options, function(a, b)
            if a.label == b.label then return tostring(a.value) < tostring(b.value) end
            return a.label < b.label
        end)
        return options
    end

    RefreshAlertSelection = function(internalID)
        local options = BuildAlertOptions()
        selectedAlertID = nil
        if internalID then
            for _, option in ipairs(options) do
                if option.value == internalID then selectedAlertID = internalID break end
            end
        end
        selectedAlertID = selectedAlertID or (options[1] and options[1].value)
        alertDropdown:Refresh()
    end

    encounterDropdown = C.CreateDropdown(encounterRow, T("Encounter"), function()
        return NSI.UI.BossData.BuildBossDropdownOptions(function(value)
            selectedEncID = value
            encounterDropdown:Refresh()
            RefreshAlertSelection()
        end, false)
    end, function()
        if not selectedEncID then return "" end
        for _, option in ipairs(NSI.UI.BossData.BuildBossDropdownOptions(nil, false)) do
            if option.value == selectedEncID then return option.label end
        end
        return tostring(selectedEncID)
    end, 320, ROW_H, "NSRTVersionCheckEncounter", nil, 9, nil, nil, 80)
    encounterDropdown:SetPoint("TOPLEFT", encounterRow, "TOPLEFT", 0, 0)

    local DIFFICULTIES = { {16, "Mythic"}, {15, "Heroic"}, {14, "Normal"} }
    difficultyDropdown = C.CreateDropdown(encounterRow, T("Difficulty"), function()
        local options = {}
        for index, difficulty in ipairs(DIFFICULTIES) do
            options[index] = {
                label = T(difficulty[2]), value = difficulty[1],
                onclick = function(_, _, value)
                    selectedDiffID = value
                    difficultyDropdown:Refresh()
                    RefreshAlertSelection()
                end,
            }
        end
        return options
    end, function()
        for _, difficulty in ipairs(DIFFICULTIES) do
            if difficulty[1] == selectedDiffID then return T(difficulty[2]) end
        end
        return ""
    end, 210, ROW_H, "NSRTVersionCheckDifficulty", nil, nil, nil, nil, 80)
    difficultyDropdown:SetPoint("LEFT", encounterDropdown.frame, "RIGHT", 16, 0)

    alertDropdown = C.CreateDropdown(encounterRow, T("Alert"), BuildAlertOptions, function()
        for _, option in ipairs(BuildAlertOptions()) do
            if option.value == selectedAlertID then return option.label end
        end
        return T("No alerts available")
    end, 340, ROW_H, "NSRTVersionCheckAlert", nil, 12, nil, nil, 50)
    alertDropdown:SetPoint("LEFT", difficultyDropdown.frame, "RIGHT", 16, 0)

    -- Row 3: hide responses, presets
    local optionRow = CreateFrame("Frame", nil, content)
    optionRow:SetHeight(ROW_H)
    optionRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(ROW_H + ROW_GAP))

    local hideResponses = C.CreateCheckButton(optionRow, T("Hide Version Check Responses"),
        function() return NSRT.Settings["VersionCheckRemoveResponse"] end,
        function(_, value) NSRT.Settings["VersionCheckRemoveResponse"] = value end,
        300, ROW_H, "VersionCheckResponseToggle",
        { title = "Hide Version Check Responses", desc = "Hides Version Check Responses of Users that are on the correct version" })
    hideResponses:SetPoint("LEFT", optionRow, "LEFT", 0, 0)

    local presetsEditButton = C.CreateButton(optionRow, T("Edit Version Presets"), nil, 150, ROW_H)
    presetsEditButton:SetPoint("RIGHT", optionRow, "RIGHT", 0, 0)

    local function BuildPresetOptions()
        NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or {}
        local t = {}
        for i = 1, #NSRT.Settings["VersionCheckPresets"] do
            local v = NSRT.Settings["VersionCheckPresets"][i]
            tinsert(t, {
                label = v[1],
                value = v[2],
                onclick = function(_, _, value)
                    if value[1] == "Encounter Alert" then
                        SelectEncounterAlert(value[3], value[4], value[2])
                    else
                        componentType = value[1]
                        typeDropdown:Refresh()
                        nameEntry:SetValue(value[2])
                        UpdateComponentType()
                    end
                end
            })
        end
        return t
    end
    presetDropdown = C.CreateDropdown(optionRow, T("Preset:"), BuildPresetOptions, function() return "" end,
        330, ROW_H, "NSRTVersionCheckPreset", nil, 10, nil, nil, 60)
    presetDropdown:SetPoint("RIGHT", presetsEditButton.frame, "LEFT", -12, 0)

    -- ------------------------------------------------------------------
    --  Card 2: responses
    -- ------------------------------------------------------------------
    local cardList = C.CreateSectionCard(parent, 400, true)
    cardList:SetPoint("TOPLEFT", cardCheck, "BOTTOMLEFT", 0, -CARD_GAP)
    cardList:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -PAD, PAD)
    cardList.title:SetText(T("Responses"))
    local listContent = cardList.content
    listContent:SetPoint("TOPRIGHT", cardList, "TOPRIGHT", -CARD_PAD, -(cardList.headerH + CARD_PAD))
    listContent:SetPoint("BOTTOMLEFT", cardList, "BOTTOMLEFT", CARD_PAD, CARD_PAD)

    local header = CreateFrame("Frame", nil, listContent)
    header:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", listContent, "TOPRIGHT", 0, 0)
    header:SetHeight(18)
    local headerLabels = {}
    for i = 1, 3 do
        local label = header:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(label, "tiny", "")
        label:SetJustifyH("LEFT")
        NSI.UI.Style.PaintAccent(label, "SetTextColor", 1)
        headerLabels[i] = label
    end
    headerLabels[1]:SetText(T("Character Name"))
    headerLabels[2]:SetText(T("Version Number"))
    headerLabels[3]:SetText(T("Ignore Check"))
    local function LayoutColumns(width, fontStrings, inset)
        local x = inset
        for i, share in ipairs(COLUMNS) do
            local fs = fontStrings[i]
            local w = math.floor((width - inset) * share)
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", fs:GetParent(), "LEFT", x, 0)
            fs:SetWidth(w - 8)
            x = x + w
        end
    end
    header:SetScript("OnSizeChanged", function(_, width) LayoutColumns(width, headerLabels, 8) end)

    local scroll = C.CreateScrollBox(listContent, 400, 300)
    scroll.frame:ClearAllPoints()
    scroll.frame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    scroll.frame:SetPoint("BOTTOMRIGHT", listContent, "BOTTOMRIGHT", 0, 0)
    scroll.frame:SetScript("OnSizeChanged", function(_, width)
        scroll.scrollChild:SetWidth(math.max(1, width - 18))
        scroll:UpdateScrollBar()
    end)

    local emptyHint = listContent:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(emptyHint, "small", "")
    emptyHint:SetTextColor(unpack(STYLE.text_hint))
    emptyHint:SetText(T("Run a check to see who is on the right version."))
    emptyHint:SetPoint("CENTER", scroll.frame, "CENTER", 0, 0)

    -- ------------------------------------------------------------------
    --  Results data + rows
    -- ------------------------------------------------------------------
    local data, nameMap, lines = {}, {}, {}

    local function WhisperMissing(row)
        local info = NSI.VersionCheckData
        if not info or not row then return end
        local name = row.name
        local now = GetTime()
        if (info.lastclick[name] and now < info.lastclick[name] + 5)
            or (row.version == info.version and (not row.ignoreCheck)) or row.version == "No Response" then return end
        info.lastclick[name] = now
        local message = ""
        if info.type == "Addon" then
            if row.version == "Addon not enabled" then message = "Please enable the Addon: '" .. info.name .. "'"
            elseif row.version == "Addon Missing" then message = "Please install the Addon: '" .. info.name .. "'"
            else message = "Please update the Addon: '" .. info.name .. "'" end
        elseif info.type == "Note" then
            if row.version == "MRT not enabled" then message = "Please enable MRT"
            elseif row.version == "MRT not installed" then message = "Please install MRT"
            else return end
        end
        if row.ignoreCheck then
            if message == "" then
                message = "You have someone from the raid on your ignore list. Please remove them fron the list."
            else
                message = message .. " You also have someone from the raid on your ignore list."
            end
        end
        if message ~= "" then SendChatMessage(message, "WHISPER", nil, name) end
    end

    local function CreateLine(index)
        local line = NSI.UI.Pixel.CreateBoxFrame("Button", nil, scroll.scrollChild)
        line:SetPoint("TOPLEFT", scroll.scrollChild, "TOPLEFT", 0, -(index - 1) * ROW_H)
        line:SetPoint("TOPRIGHT", scroll.scrollChild, "TOPRIGHT", 0, -(index - 1) * ROW_H)
        line:SetHeight(ROW_H)
        line:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] })
        line:SetBackdropColor(unpack(index % 2 == 0 and STYLE.row_stripe_light or STYLE.row_stripe_dark))

        local hover = line:CreateTexture(nil, "ARTWORK")
        hover:SetAllPoints()
        NSI.UI.Style.PaintAccent(hover, "SetColorTexture", 0.13)
        hover:SetAlpha(0)
        line:SetScript("OnEnter", function() C.FadeTo(hover, 1, STYLE.hover_in) end)
        line:SetScript("OnLeave", function() C.FadeTo(hover, 0, STYLE.hover_out) end)
        line:HookScript("OnHide", function() hover:SetAlpha(0) end)

        line.fields = {}
        for i = 1, 3 do
            local fs = line:CreateFontString(nil, "OVERLAY")
            NSI:SetUIFont(fs, "small", "")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            line.fields[i] = fs
        end
        line.name, line.version, line.ignorelist = line.fields[1], line.fields[2], line.fields[3]
        line:SetScript("OnSizeChanged", function(_, width) LayoutColumns(width, line.fields, 8) end)
        line:SetScript("OnClick", function(self) WhisperMissing(self.row) end)
        return line
    end

    local function RefreshList()
        for i, row in ipairs(data) do
            local line = lines[i]
            if not line then line = CreateLine(i); lines[i] = line end
            line.row = row
            line:Show()
            line.name:SetText(NSAPI:Shorten(row.name))
            line.version:SetText(row.version and T(row.version) or "")
            line.ignorelist:SetText(row.ignoreCheck and T("Yes") or T("No"))

            local version = row.version
            if version == "Offline" then
                line.version:SetTextColor(unpack(STYLE.text_hint))
            elseif version == "Alert Missing" then
                line.version:SetTextColor(unpack(STYLE.warning))
            elseif version and NSI.VersionCheckData and version == NSI.VersionCheckData.version then
                line.version:SetTextColor(unpack(STYLE.success))
            else
                line.version:SetTextColor(unpack(STYLE.text_danger))
            end
            line.ignorelist:SetTextColor(unpack(row.ignoreCheck and STYLE.text_danger or STYLE.success))
        end
        for i = #data + 1, #lines do
            lines[i].row = nil
            lines[i]:Hide()
        end
        emptyHint:SetShown(#data == 0)
        scroll.scrollChild:SetHeight(math.max(1, #data * ROW_H))
        scroll:UpdateScrollBar()
    end

    local function RebuildNameMap()
        wipe(nameMap)
        for index, row in ipairs(data) do
            if row.name then nameMap[row.name] = index end
        end
    end

    -- The object NSUI.version_scrollbox points at; the core calls AddData / the
    -- Encounter Alerts list calls CheckEncounterAlert.
    local box = { frame = parent }

    function box:AddData(row)
        local index = nameMap[row.name]
        local matches = NSI.VersionCheckData and row.version == NSI.VersionCheckData.version
        if NSRT.Settings["VersionCheckRemoveResponse"] and matches and row.name ~= UnitName("player")
            and row.version ~= "Addon Missing" and row.version ~= "Note Missing" and row.version ~= "Reminder Missing"
            and row.version ~= "Alert Missing" and not row.ignoreCheck then
            if index then table.remove(data, index) end
        elseif index then
            data[index] = row
        else
            tinsert(data, row)
        end
        RebuildNameMap()
        RefreshList()
    end

    function box:WipeData()
        wipe(data)
        wipe(nameMap)
        RefreshList()
    end

    -- ------------------------------------------------------------------
    --  Behaviour
    -- ------------------------------------------------------------------
    local function SizeCheckCard(isEncounterAlert)
        local rows = isEncounterAlert and 3 or 2
        local height = rows * ROW_H + (rows - 1) * ROW_GAP
        content:SetHeight(height)
        cardCheck:SetHeight(cardCheck.headerH + CARD_PAD * 2 + height)
        optionRow:ClearAllPoints()
        optionRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rows - 1) * (ROW_H + ROW_GAP)))
        optionRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rows - 1) * (ROW_H + ROW_GAP)))
    end

    UpdateComponentType = function()
        local isEncounterAlert = componentType == "Encounter Alert"
        nameEntry.frame:SetShown(not isEncounterAlert)
        encounterRow:SetShown(isEncounterAlert)
        headerLabels[2]:SetText(T(isEncounterAlert and "Enabled Status" or "Version Number"))
        if not isEncounterAlert then HideSuggestions() end
        SizeCheckCard(isEncounterAlert)
        if isEncounterAlert then
            if not selectedEncID then
                local encounters = NSI.UI.BossData.BuildBossDropdownOptions(nil, false)
                selectedEncID = encounters[1] and encounters[1].value
            end
            encounterDropdown:Refresh()
            difficultyDropdown:Refresh()
            RefreshAlertSelection(selectedAlertID)
        end
    end

    SelectEncounterAlert = function(encID, diffID, internalID)
        selectedEncID, selectedDiffID, selectedAlertID = encID, diffID, internalID
        componentType = "Encounter Alert"
        typeDropdown:Refresh()
        UpdateComponentType()
    end

    RunVersionCheck = function()
        local text = nameEntry.editBox:GetText()
        if componentType == "Encounter Alert" then
            if not selectedEncID or not selectedDiffID or not selectedAlertID then return end
            text = selectedAlertID
        elseif text and text ~= "" and componentType == "Addon" and not tContains(NSRT.NSUI.AutoComplete[componentType], text) then
            tinsert(NSRT.NSUI.AutoComplete[componentType], text)
        end

        if not text or text == "" and componentType ~= "Note" and componentType ~= "Reminder" then return end

        local now = GetTime()
        if NSI.LastVersionCheck and NSI.LastVersionCheck > now - 2 then return end
        NSI.LastVersionCheck = now
        box:WipeData()
        local userData = NSI:RequestVersionNumber(componentType, text, selectedEncID, selectedDiffID)
        if userData then box:AddData(userData) end
    end

    function box:CheckEncounterAlert(encID, diffID, internalID)
        if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then return end
        SelectEncounterAlert(encID, diffID, internalID)
        RunVersionCheck()
    end

    -- ------------------------------------------------------------------
    --  Preset manager
    -- ------------------------------------------------------------------
    local presetsFrame = C.CreateFrame(parent, 440, math.floor(window_height / 2), "NSRTVersionPresetsFrame")
    presetsFrame:SetFrameStrata("DIALOG")
    presetsFrame:ClearAllPoints()
    presetsFrame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 2)
    presetsFrame:Hide()
    local presetsTitle = presetsFrame:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(presetsTitle, "body", "")
    NSI.UI.Style.PaintAccent(presetsTitle, "SetTextColor", 1)
    presetsTitle:SetText(T("Version Preset Management"))
    presetsTitle:SetPoint("TOPLEFT", presetsFrame, "TOPLEFT", 12, -10)

    presetsEditButton.frame:SetScript("OnClick", function()
        presetsFrame:SetShown(not presetsFrame:IsShown())
    end)

    local presetList = C.CreateScrollBox(presetsFrame, 416, 300)
    presetList.frame:SetPoint("TOPLEFT", presetsFrame, "TOPLEFT", 12, -38)
    presetList.frame:SetPoint("BOTTOMRIGHT", presetsFrame, "BOTTOMRIGHT", -12, 52)
    presetList.frame:SetScript("OnSizeChanged", function(_, width)
        presetList.scrollChild:SetWidth(math.max(1, width - 18))
        presetList:UpdateScrollBar()
    end)
    local presetLines = {}
    local RefreshPresetList

    local function CreatePresetLine(index)
        local line = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, presetList.scrollChild)
        line:SetPoint("TOPLEFT", presetList.scrollChild, "TOPLEFT", 0, -(index - 1) * ROW_H)
        line:SetPoint("TOPRIGHT", presetList.scrollChild, "TOPRIGHT", 0, -(index - 1) * ROW_H)
        line:SetHeight(ROW_H)
        line:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] })
        line:SetBackdropColor(unpack(index % 2 == 0 and STYLE.row_stripe_light or STYLE.row_stripe_dark))

        line.type = line:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(line.type, "small", "")
        line.type:SetTextColor(unpack(STYLE.text_muted))
        line.type:SetPoint("LEFT", line, "LEFT", 6, 0)
        line.type:SetWidth(96)
        line.type:SetJustifyH("LEFT")

        line.name = line:CreateFontString(nil, "OVERLAY")
        NSI:SetUIFont(line.name, "small", "")
        line.name:SetPoint("LEFT", line.type, "RIGHT", 6, 0)
        line.name:SetPoint("RIGHT", line, "RIGHT", -28, 0)
        line.name:SetJustifyH("LEFT")
        line.name:SetWordWrap(false)

        line.deleteButton = CreateFrame("Button", nil, line)
        line.deleteButton:SetSize(14, 14)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -6, 0)
        line.deleteButton:SetNormalTexture([[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\trash-2.png]])
        line.deleteButton:GetNormalTexture():SetVertexColor(unpack(STYLE.danger))
        line.deleteButton:SetScript("OnClick", function()
            tremove(NSRT.Settings["VersionCheckPresets"], line.index)
            RefreshPresetList()
            presetDropdown:Refresh()
        end)
        line.deleteButton:SetScript("OnEnter", function(self) NSI.UI.Tooltip.Show(self, "Delete", "ANCHOR_TOP") end)
        line.deleteButton:SetScript("OnLeave", NSI.UI.Tooltip.Hide)
        return line
    end

    RefreshPresetList = function()
        NSRT.Settings["VersionCheckPresets"] = NSRT.Settings["VersionCheckPresets"] or {}
        local presets = NSRT.Settings["VersionCheckPresets"]
        for i, preset in ipairs(presets) do
            local line = presetLines[i]
            if not line then line = CreatePresetLine(i); presetLines[i] = line end
            local value = preset[2]
            line.index = i
            line.type:SetText(T(value[1]))
            line.name:SetText(value[1] == "Encounter Alert" and preset[1] or value[2])
            line:Show()
        end
        for i = #presets + 1, #presetLines do presetLines[i]:Hide() end
        presetList.scrollChild:SetHeight(math.max(1, #presets * ROW_H))
        presetList:UpdateScrollBar()
    end

    local newType = checkable_components[1]
    local newTypeDropdown = C.CreateDropdown(presetsFrame, nil, function()
        return build_checkable_components_options(function(value)
            newType = value
            presetsFrame.newTypeDropdown:Refresh()
        end, true)
    end, function() return T(newType) end, 110, ROW_H, "NSRTVersionPresetType")
    presetsFrame.newTypeDropdown = newTypeDropdown
    newTypeDropdown:SetPoint("BOTTOMLEFT", presetsFrame, "BOTTOMLEFT", 12, 14)

    local newName = C.CreateTextEntry(presetsFrame, nil, nil, nil, 200, ROW_H, false, nil, nil, "NSRTVersionPresetName")
    newName:SetPoint("LEFT", newTypeDropdown.frame, "RIGHT", 8, 0)

    local addButton = C.CreateButton(presetsFrame, T("New"), function()
        local name = newName.editBox:GetText()
        if name == "" then return end
        tinsert(NSRT.Settings["VersionCheckPresets"], { T(newType) .. ": " .. name, {newType, name} })
        RefreshPresetList()
        presetDropdown:Refresh()
        newName:SetValue("")
        newType = checkable_components[1]
        newTypeDropdown:Refresh()
    end, 70, ROW_H)
    addButton:SetPoint("LEFT", newName.frame, "RIGHT", 8, 0)
    presetsFrame:HookScript("OnShow", RefreshPresetList)

    UpdateComponentType()
    RefreshList()
    return box
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.VersionCheck = {
    BuildVersionCheckUI = BuildVersionCheckUI,
}
