local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core                    = NSI.UI.Core
local NSUI                    = Core.NSUI
local content_width           = Core.content_width       -- 1036
local tab_content_height      = Core.tab_content_height  -- 540
local options_button_template = Core.options_button_template

local LIST_W  = 260  -- width of the left note-list panel
local PAD     = 8    -- inner padding
local ROW_H   = 24   -- height of each note-list row
local ROW_GAP = 1

-- ─────────────────────────────────────────────────────────────────────────────
-- BuildNotesTabUI
-- Populates `parent` (a tab content frame) with a Details-style split layout:
--   left  – scrollable list of note names  (260 px)
--   right – title edit-box + multiline body editor
-- `notesTable` is the live SavedVariables array ( {name, text} entries ).
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildNotesTabUI(parent, notesTable)
    local panelH = tab_content_height - 14

    -- Forward-declare frame references so closures defined early can use them
    local listScroll, listScrollBar, listChild
    local nameBox, textBox, edScroll

    -- ── State ─────────────────────────────────────────────────────────────────
    local selectedIdx = nil
    local rowObjects  = {}

    -- ── Logic ─────────────────────────────────────────────────────────────────

    local function flushCurrent()
        if not selectedIdx then return end
        local note = notesTable[selectedIdx]
        if not note then return end
        note.name = nameBox:GetText()
        note.text = textBox:GetText()
    end

    local function refreshHighlights()
        for i, ro in ipairs(rowObjects) do
            if i == selectedIdx then
                ro.sel:SetAlpha(1)
                ro.lbl:SetTextColor(0, 1, 1, 1)
            else
                ro.sel:SetAlpha(0)
                ro.lbl:SetTextColor(1, 1, 1, 0.85)
            end
        end
    end

    local function selectNote(idx)
        selectedIdx = idx
        local note = notesTable[idx]
        if note then
            nameBox:SetText(note.name or "")
            textBox:SetText(note.text or "")
            textBox:SetWidth(edScroll:GetWidth() > 0 and edScroll:GetWidth() or (content_width - LIST_W - 20 - PAD * 2 - 18))
        else
            nameBox:SetText("")
            textBox:SetText("")
        end
        refreshHighlights()
    end

    local function rebuildList()
        for _, ro in ipairs(rowObjects) do ro.btn:Hide() end
        rowObjects = {}

        local rowW   = LIST_W - PAD * 2 - 14
        local totalH = 0

        for i, note in ipairs(notesTable) do
            local btn = CreateFrame("Button", nil, listChild)
            btn:SetSize(rowW, ROW_H)
            btn:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -totalH)

            -- Hover texture (Blizzard list-highlight, ADD blend keeps it subtle)
            btn:SetHighlightTexture([[Interface\Buttons\UI-Listbox-Highlight2]])
            local hlt = btn:GetHighlightTexture()
            if hlt then
                hlt:SetBlendMode("ADD")
                hlt:SetAlpha(0.3)
            end

            -- Selected background (cyan tint, manually toggled)
            local sel = btn:CreateTexture(nil, "background")
            sel:SetAllPoints()
            sel:SetColorTexture(0, 1, 1, 0.22)
            sel:SetAlpha(i == selectedIdx and 1 or 0)

            -- Row label
            local lbl = btn:CreateFontString(nil, "overlay")
            lbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "")
            lbl:SetPoint("LEFT",  btn, "LEFT",  8,  0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetJustifyV("MIDDLE")
            lbl:SetText((note.name and note.name ~= "") and note.name or ("Note " .. i))
            lbl:SetTextColor(i == selectedIdx and 0 or 1, 1, 1, 0.85)

            local ci = i
            btn:SetScript("OnClick", function()
                flushCurrent()
                selectNote(ci)
            end)

            rowObjects[i] = { btn = btn, sel = sel, lbl = lbl }
            totalH = totalH + ROW_H + ROW_GAP
        end

        listChild:SetHeight(math.max(totalH, 1))
        local maxScroll = math.max(0, totalH - listScroll:GetHeight())
        listScrollBar:SetMinMaxValues(0, maxScroll)
        if listScrollBar:GetValue() > maxScroll then
            listScrollBar:SetValue(maxScroll)
        end
    end

    -- ── Left panel: note list ─────────────────────────────────────────────────
    local listBg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    listBg:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -8)
    listBg:SetSize(LIST_W, panelH)
    listBg:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    listBg:SetBackdropColor(0.286, 0.275, 0.286, 1)

    -- Thin cyan right-edge divider matching the sidebar separator style
    local listDivider = listBg:CreateTexture(nil, "overlay")
    listDivider:SetColorTexture(0, 1, 1, 0.25)
    listDivider:SetWidth(1)
    listDivider:SetPoint("TOPRIGHT",    listBg, "TOPRIGHT",    0, 0)
    listDivider:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", 0, 0)

    -- Header label
    local hdr = listBg:CreateFontString(nil, "overlay")
    hdr:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "")
    hdr:SetTextColor(0, 1, 1, 1)
    hdr:SetText("Notes")
    hdr:SetPoint("TOPLEFT", listBg, "TOPLEFT", PAD, -PAD)

    local hdrSep = listBg:CreateTexture(nil, "artwork")
    hdrSep:SetColorTexture(0, 1, 1, 0.20)
    hdrSep:SetHeight(1)
    hdrSep:SetPoint("TOPLEFT",  listBg, "TOPLEFT",  PAD,  -(PAD + 12 + 4))
    hdrSep:SetPoint("TOPRIGHT", listBg, "TOPRIGHT", -PAD, -(PAD + 12 + 4))

    -- Bottom action buttons
    local btnW = math.floor((LIST_W - PAD * 2 - 4) / 2)

    local newBtn = DF:CreateButton(listBg, function()
        flushCurrent()
        table.insert(notesTable, { name = "New Note", text = "" })
        rebuildList()
        selectNote(#notesTable)
    end, btnW, 22, "New Note")
    newBtn:SetTemplate(options_button_template)
    newBtn:SetPoint("BOTTOMLEFT", listBg, "BOTTOMLEFT", PAD, PAD)

    local delBtn = DF:CreateButton(listBg, function()
        if not selectedIdx then return end
        table.remove(notesTable, selectedIdx)
        selectedIdx = nil
        nameBox:SetText("")
        textBox:SetText("")
        rebuildList()
    end, btnW, 22, "Delete")
    delBtn:SetTemplate(options_button_template)
    delBtn:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -PAD, PAD)

    -- ScrollFrame for note rows
    local scrollTop    = PAD + 12 + 4 + 4   -- header text + separator + gap
    local scrollBottom = 22 + PAD * 2        -- buttons + margins
    local scrollH      = panelH - scrollTop - scrollBottom

    listScroll = CreateFrame("ScrollFrame", nil, listBg)
    listScroll:SetPoint("TOPLEFT", listBg, "TOPLEFT", PAD, -scrollTop)
    listScroll:SetSize(LIST_W - PAD * 2 - 14, scrollH)

    listScrollBar = CreateFrame("Slider", nil, listBg, "UIPanelScrollBarTemplate")
    listScrollBar:SetPoint("TOPLEFT",    listScroll, "TOPRIGHT",    2, -16)
    listScrollBar:SetPoint("BOTTOMLEFT", listScroll, "BOTTOMRIGHT", 2, 16)
    listScrollBar:SetMinMaxValues(0, 0)
    listScrollBar:SetValueStep(ROW_H)
    -- Override the template's built-in OnValueChanged BEFORE calling SetValue,
    -- otherwise the template fires first and tries GetParent():SetVerticalScroll
    -- on listBg (a plain Frame, not a ScrollFrame) → error.
    listScrollBar:SetScript("OnValueChanged", function(self, val)
        listScroll:SetVerticalScroll(val)
    end)
    listScrollBar:SetValue(0)
    listScroll:EnableMouseWheel(true)
    listScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur    = listScrollBar:GetValue()
        local lo, hi = listScrollBar:GetMinMaxValues()
        listScrollBar:SetValue(math.max(lo, math.min(hi, cur - delta * ROW_H * 3)))
    end)

    listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetSize(LIST_W - PAD * 2 - 14, 1)
    listScroll:SetScrollChild(listChild)

    -- ── Right panel: editor ───────────────────────────────────────────────────
    local edX = LIST_W + 10
    local edW = content_width - LIST_W - 20

    local editorBg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    editorBg:SetPoint("TOPLEFT", parent, "TOPLEFT", edX, -8)
    editorBg:SetSize(edW, panelH)
    editorBg:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 64 })
    editorBg:SetBackdropColor(0.286, 0.275, 0.286, 1)

    -- Note title (editable)
    nameBox = CreateFrame("EditBox", nil, editorBg, "InputBoxTemplate")
    nameBox:SetPoint("TOPLEFT", editorBg, "TOPLEFT", PAD, -PAD)
    nameBox:SetSize(edW - PAD * 2, 22)
    nameBox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "")
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(128)
    nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameBox:SetScript("OnEditFocusLost", function(self)
        local note = notesTable[selectedIdx]
        if note then
            note.name = self:GetText()
            rebuildList()
        end
    end)

    local edSep = editorBg:CreateTexture(nil, "artwork")
    edSep:SetColorTexture(0, 1, 1, 0.20)
    edSep:SetHeight(1)
    edSep:SetPoint("TOPLEFT",  editorBg, "TOPLEFT",  PAD,  -(PAD + 22 + 4))
    edSep:SetPoint("TOPRIGHT", editorBg, "TOPRIGHT", -PAD, -(PAD + 22 + 4))

    -- Scrollable multiline body
    edScroll = CreateFrame("ScrollFrame", nil, editorBg, "UIPanelScrollFrameTemplate")
    edScroll:SetPoint("TOPLEFT",     editorBg, "TOPLEFT",     PAD,       -(PAD + 22 + 8))
    edScroll:SetPoint("BOTTOMRIGHT", editorBg, "BOTTOMRIGHT", -(PAD + 18), (PAD + 22 + 4))

    textBox = CreateFrame("EditBox", nil, edScroll)
    textBox:SetMultiLine(true)
    textBox:SetAutoFocus(false)
    textBox:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 14, "")
    textBox:SetMaxLetters(0)
    textBox:SetWidth(edW - PAD * 2 - 18)  -- initial safe width; corrected by OnSizeChanged
    textBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    textBox:SetScript("OnTextChanged", function(self)
        local w = edScroll:GetWidth()
        if w > 0 then self:SetWidth(w) end
    end)
    edScroll:SetScrollChild(textBox)
    edScroll:SetScript("OnSizeChanged", function(self, w)
        if w > 0 then textBox:SetWidth(w) end
    end)

    -- Save button
    local saveBtn = DF:CreateButton(editorBg, function()
        flushCurrent()
        rebuildList()
    end, 120, 22, "Save Note")
    saveBtn:SetTemplate(options_button_template)
    saveBtn:SetPoint("BOTTOMRIGHT", editorBg, "BOTTOMRIGHT", -PAD, PAD)

    -- ── Frame lifetime hooks ──────────────────────────────────────────────────
    parent:HookScript("OnShow", function() rebuildList() end)
    parent:HookScript("OnHide", function() flushCurrent() end)

    -- Initial population
    rebuildList()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public entry-point called from NSUI.lua
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildNotesUI(sharedTab, personalTab)
    BuildNotesTabUI(sharedTab,   NSRT.SharedNotes)
    BuildNotesTabUI(personalTab, NSRT.PersonalNotes)
end

NSI.UI = NSI.UI or {}
NSI.UI.Notes = {
    BuildNotesUI = BuildNotesUI,
}
