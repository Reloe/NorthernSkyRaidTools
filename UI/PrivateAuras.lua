local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template

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
    local PASound_edit_frame = DF:CreateSimplePanel(UIParent, 485, 420, "Private Aura Sounds", "PASoundEditFrame", {
        DontRightClickClose = true
    })
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

            if oldValue == newValue or not (C_UnitAuras.AuraIsPrivate(line.spellID)) then return end
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

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.PrivateAuras = {
    BuildPASoundEditUI = BuildPASoundEditUI,
}
