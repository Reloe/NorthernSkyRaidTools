local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local options_dropdown_template = Core.options_dropdown_template
local options_slider_template = Core.options_slider_template
local options_button_template = Core.options_button_template

-- Cooldown type options
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

local selected_spec = 268
local function build_spec_options()
    local t = {}
    local classSpecs = NSI.CLASS_SPECIALIZATION_MAP

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
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

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

        line.idTextEntry = DF:CreateTextEntry(line, function(self, _, value)
            if line.type == "Spell" then
                line.spellIcon:SetTexture(C_Spell.GetSpellTexture(value))
            else
                line.spellIcon:SetTexture(C_Item.GetItemIconByID(value))
            end
        end, 120, 20)
        line.idTextEntry:SetTemplate(options_dropdown_template)
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

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Cooldowns = {
    BuildCooldownsEditUI = BuildCooldownsEditUI,
}
