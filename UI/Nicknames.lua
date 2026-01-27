local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template

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
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index-1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.playerText = DF:CreateLabel(line, "")
        line.playerText:SetPoint("LEFT", line, "LEFT", 5, 0)

        line.nicknameEntry = DF:CreateTextEntry(line, function(self, _, value)
            NSI:AddNickName(line.player, line.realm, string.sub(value, 1, 12))
            line.nicknameEntry.text = string.sub(value, 1, 12)
            parent:MasterRefresh()
        end, 120, 20)
        line.nicknameEntry:SetTemplate(options_dropdown_template)
        line.nicknameEntry:SetPoint("LEFT", line, "LEFT", 185, 0)

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

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Nicknames = {
    BuildNicknameEditUI = BuildNicknameEditUI,
}
