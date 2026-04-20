local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core                      = NSI.UI.Core
local NSUI                      = Core.NSUI
local content_width             = Core.content_width
local tab_content_height        = Core.tab_content_height
local options_dropdown_template = Core.options_dropdown_template

local CreateButton    = NSI.UI.Components.CreateButton
local CreateSubButton = NSI.UI.Components.CreateSubButton
local BossData        = NSI.UI.BossData

-- ============================================================================
-- WoW class constants
-- ============================================================================
local CLASS_NAMES = {
    "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER",
    "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST",
    "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR",
}
local CLASS_DISPLAY = {
    DEATHKNIGHT = "Death Knight", DEMONHUNTER = "Demon Hunter",
    DRUID   = "Druid",   EVOKER   = "Evoker",  HUNTER  = "Hunter",
    MAGE    = "Mage",    MONK     = "Monk",     PALADIN = "Paladin",
    PRIEST  = "Priest",  ROGUE    = "Rogue",    SHAMAN  = "Shaman",
    WARLOCK = "Warlock", WARRIOR  = "Warrior",
}

local MAX_LIST_ROWS = 80   -- hard cap; more than any reasonable alert count

-- ============================================================================
-- BuildBossRemindersUI
-- ============================================================================
local function BuildBossRemindersUI(parentFrame)
    local screen = parentFrame

    -- ── Layout constants ────────────────────────────────────────────────────
    local leftWidth  = 240
    local pad        = 10
    local topY       = -10
    local lineHeight = 22
    local rightX     = leftWidth + pad * 2   -- 260
    local rightW     = content_width - rightX - pad  -- ~766

    -- ── Mutable state ───────────────────────────────────────────────────────
    local selectedIndex      = nil   -- index into NSRT.CustomBossAlerts (custom mode)
    local selectedReloeEncID = nil   -- encID of selected reloeReminder alert
    local selectedReloeDiffID = nil  -- diffID of selected reloeReminder alert
    local selectedReloeKey   = nil   -- key of selected reloeReminder alert
    local filterEncID        = nil

    -- forward declarations
    local rightPanel, SelectAlert, SelectReloeCreatedAlert, PreviewAlert

    -- ================================================================
    -- Left Panel ── title, filter, list, create button
    -- ================================================================
    local title = screen:CreateFontString(nil, "OVERLAY")
    title:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 16, "OUTLINE")
    title:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY)
    title:SetText("|cFF00FFFFEncounter|r Alerts")

    -- ── Filter dropdown ─────────────────────────────────────────────────────
    local function BuildFilterOptions()
        local opts = {{ label = "All Bosses", value = 0, onclick = function()
            filterEncID = nil
            if screen.RebuildList then screen.RebuildList() end
        end }}
        for _, opt in ipairs(BossData.BuildBossDropdownOptions(nil, false)) do
            local enc = opt.value
            opt.onclick = function()
                filterEncID = enc
                if screen.RebuildList then screen.RebuildList() end
            end
            table.insert(opts, opt)
        end
        return opts
    end

    local filterDD = DF:CreateDropDown(screen, BuildFilterOptions, nil, leftWidth - pad * 2, 22, nil,
        "NSUIEncAlertFilter", options_dropdown_template)
    filterDD:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, topY - 20)

    -- ── Native ScrollFrame list ─────────────────────────────────────────────
    local scrollTop    = topY - 20 - 22 - 6   -- below title + filter + gap = -58
    local scrollHeight = tab_content_height + scrollTop - 22 - pad * 2  -- ~450
    local listW        = leftWidth - pad * 2   -- 220

    local listScroll = CreateFrame("ScrollFrame", "NSUIEncAlertListScroll", screen,
        "UIPanelScrollFrameTemplate")
    listScroll:SetSize(listW, scrollHeight)
    listScroll:SetPoint("TOPLEFT", screen, "TOPLEFT", pad, scrollTop)

    local listChild = CreateFrame("Frame", nil, listScroll, "BackdropTemplate")
    listChild:SetSize(listW - 18, 1)   -- 18px for the native scrollbar
    listChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    listChild:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
    listScroll:SetScrollChild(listChild)

    -- Pre-allocate the row pool ──────────────────────────────────────────────
    local listRows = {}

    for i = 1, MAX_LIST_ROWS do
        local row = CreateFrame("Frame", nil, listChild, "BackdropTemplate")
        row:SetSize(listChild:GetWidth(), lineHeight)
        row:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -(i - 1) * lineHeight)
        DF:ApplyStandardBackdrop(row)
        row.__background:SetVertexColor(0.4, 0.4, 0.4)
        row.__background:SetAlpha(0.5)

        row.bossIcon = row:CreateTexture(nil, "ARTWORK")
        row.bossIcon:SetSize(16, 16)
        row.bossIcon:SetPoint("LEFT", row, "LEFT", 3, 0)
        row.bossIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

        -- Lock icon for hardcoded rows
        row.lockIcon = row:CreateTexture(nil, "ARTWORK")
        row.lockIcon:SetSize(10, 10)
        row.lockIcon:SetPoint("LEFT", row, "LEFT", 3, 0)
        row.lockIcon:SetTexture([[Interface\PetBattles\PetBattle-LockIcon]])
        row.lockIcon:SetVertexColor(0.7, 0.7, 0.7, 0.9)
        row.lockIcon:Hide()

        row.nameLabel = row:CreateFontString(nil, "OVERLAY")
        row.nameLabel:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "")
        row.nameLabel:SetPoint("LEFT", row.bossIcon, "RIGHT", 4, 0)
        row.nameLabel:SetPoint("RIGHT", row, "RIGHT", -22, 0)
        row.nameLabel:SetJustifyH("LEFT")
        row.nameLabel:SetWordWrap(false)

        row.deleteBtn = CreateFrame("Button", nil, row)
        row.deleteBtn:SetSize(14, 14)
        row.deleteBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.deleteBtn:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        row.deleteBtn:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        row.deleteBtn:GetNormalTexture():SetDesaturated(true)
        row.deleteBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)

        row:EnableMouse(true)
        row:Hide()
        listRows[i] = row
    end

    -- Returns a display name for a reloeReminder alert entry.
    local function ReloeAlertName(entry)
        local base = (entry.name and entry.name ~= "") and entry.name
                  or (entry.text and entry.text ~= "") and entry.text
                  or "?"
        local minPhase = math.huge
        for phase in pairs(entry.timers or {}) do
            if phase < minPhase then minPhase = phase end
        end
        local phase = minPhase == math.huge and 1 or minPhase
        return (phase > 1) and (base .. " (P" .. phase .. ")") or base
    end

    -- RebuildList ─────────────────────────────────────────────────────────────
    local function RebuildScrollData()
        local t = {}

        -- One row per reloeReminder alert (deduplicated by alertKey, prefer higher diffID)
        local sortedEnc = {}
        for encID in pairs(NSRT.EncounterAlerts or {}) do
            if not filterEncID or filterEncID == encID then
                table.insert(sortedEnc, encID)
            end
        end
        table.sort(sortedEnc, function(a, b)
            return (NSI.EncounterOrder[a] or 99) < (NSI.EncounterOrder[b] or 99)
        end)
        for _, encID in ipairs(sortedEnc) do
            local encTable = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
            if encTable then
                -- Sort diffIDs descending so we prefer mythic as representative
                local diffIDs = {}
                for diffID in pairs(encTable) do
                    if type(diffID) == "number" then
                        table.insert(diffIDs, diffID)
                    end
                end
                table.sort(diffIDs, function(a, b) return a > b end)

                local seenNames = {}
                local alerts = {}
                for _, diffID in ipairs(diffIDs) do
                    local diffTable = encTable[diffID]
                    if type(diffTable) == "table" then
                        for key, entry in pairs(diffTable) do
                            local entryName = entry.name or entry.text or key
                            if type(entry) == "table" and entry.reloeReminder and not seenNames[entryName] then
                                seenNames[entryName] = true
                                local minPhase = math.huge
                                for phase in pairs(entry.timers or {}) do
                                    if phase < minPhase then minPhase = phase end
                                end
                                table.insert(alerts, {
                                    key    = key,
                                    entry  = entry,
                                    diffID = diffID,
                                    phase  = minPhase == math.huge and 1 or minPhase,
                                })
                            end
                        end
                    end
                end
                table.sort(alerts, function(a, b)
                    if a.phase ~= b.phase then return a.phase < b.phase end
                    local an = a.entry.name or a.entry.text or a.key
                    local bn = b.entry.name or b.entry.text or b.key
                    return an < bn
                end)
                for _, item in ipairs(alerts) do
                    table.insert(t, {
                        encID           = encID,
                        diffID          = item.diffID,
                        alertKey        = item.key,
                        entry           = item.entry,
                        _isReloeCreated = true,
                    })
                end
            end
        end

        -- Custom alerts below
        for i, alert in ipairs(NSRT.CustomBossAlerts or {}) do
            if not filterEncID or alert.encID == filterEncID then
                table.insert(t, { alert = alert, realIndex = i })
            end
        end
        return t
    end

    local function RebuildList()
        local data = RebuildScrollData()

        for i = 1, MAX_LIST_ROWS do
            local row   = listRows[i]
            local entry = data[i]

            if not entry then
                row:Hide()
            else
                row:Show()

                local isReloe   = entry._isReloeCreated
                local isEnabled, icon, name

                if isReloe then
                    isEnabled = entry.entry.enabled
                    icon      = BossData.BossIcons[entry.encID]
                    name      = ReloeAlertName(entry.entry)
                else
                    local alert = entry.alert
                    isEnabled   = alert.enabled
                    icon        = BossData.BossIcons[alert.encID]
                    name        = alert.name or "Unnamed"
                end

                -- Selected highlight
                local isSelected = isReloe
                    and (selectedReloeEncID == entry.encID and selectedReloeDiffID == entry.diffID and selectedReloeKey == entry.alertKey)
                    or  (not isReloe and selectedIndex == entry.realIndex)
                if isSelected then
                    row.__background:SetVertexColor(0, 1, 1)
                    row.__background:SetAlpha(1)
                else
                    row.__background:SetVertexColor(0.4, 0.4, 0.4)
                    row.__background:SetAlpha(0.5)
                end

                -- Lock icon for reloe rows; boss icon for custom rows
                if isReloe then
                    row.bossIcon:Hide()
                    row.lockIcon:Show()
                    row.nameLabel:SetPoint("LEFT", row.lockIcon, "RIGHT", 4, 0)
                else
                    row.lockIcon:Hide()
                    if icon then
                        row.bossIcon:SetTexture(icon)
                        row.bossIcon:Show()
                    else
                        row.bossIcon:SetTexture(nil)
                        row.bossIcon:Hide()
                    end
                    row.nameLabel:SetPoint("LEFT", row.bossIcon, "RIGHT", 4, 0)
                end

                row.nameLabel:SetText(name)
                row.nameLabel:SetTextColor(1, 1, 1, isEnabled and 1 or 0.45)

                -- Delete button: hidden for reloeCreated rows
                if isReloe then
                    row.deleteBtn:Hide()
                    row.deleteBtn:SetScript("OnClick", nil)
                else
                    row.deleteBtn:Show()
                    local ri = entry.realIndex
                    row.deleteBtn:SetScript("OnClick", function()
                        table.remove(NSRT.CustomBossAlerts, ri)
                        if selectedIndex == ri then
                            selectedIndex = nil
                            if rightPanel then rightPanel:Hide() end
                        elseif selectedIndex and selectedIndex > ri then
                            selectedIndex = selectedIndex - 1
                        end
                        RebuildList()
                    end)
                end

                -- Click to select
                if isReloe then
                    local eid, did, akey = entry.encID, entry.diffID, entry.alertKey
                    row:SetScript("OnMouseDown", function()
                        SelectReloeCreatedAlert(eid, did, akey)
                    end)
                else
                    local ri = entry.realIndex
                    row:SetScript("OnMouseDown", function()
                        SelectAlert(ri)
                    end)
                end
            end
        end

        local totalH = math.max(#data * lineHeight, 1)
        listChild:SetHeight(totalH)
        local bar = _G["NSUIEncAlertListScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, totalH - listScroll:GetHeight())
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end
    end

    screen.RebuildList = RebuildList

    -- Create Alert button
    local createBtn = CreateButton(screen, "+ Create Alert", function()
        NSRT.CustomBossAlerts = NSRT.CustomBossAlerts or {}
        table.insert(NSRT.CustomBossAlerts, {
            name          = "New Alert",
            enabled       = true,
            encID         = 0,
            phase         = 1,
            times         = {},
            Type          = "Text",
            text          = "",
            spellID       = nil,
            dur           = 8,
            TTSEnabled    = false,
            TTSText       = "",
            TTSTimer      = 8,
            countdown     = false,
            loadClass     = nil,
            loadSpec      = nil,
            loadCharacter = nil,
        })
        RebuildList()
        SelectAlert(#NSRT.CustomBossAlerts)
    end, listW, 22)
    createBtn:SetPoint("BOTTOMLEFT", screen, "BOTTOMLEFT", pad, pad)

    -- ================================================================
    -- Right Panel
    -- ================================================================
    rightPanel = CreateFrame("Frame", nil, screen)
    rightPanel:SetPoint("TOPLEFT",     screen, "TOPLEFT",     rightX, topY)
    rightPanel:SetPoint("BOTTOMRIGHT", screen, "BOTTOMRIGHT", -pad,   pad)
    rightPanel:Hide()

    -- ── Header: name entry + enabled checkbox ────────────────────────────────
    local nameLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    nameLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 11, "")
    nameLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    nameLbl:SetText("Alert Name")
    nameLbl:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)

    local nameEntry = DF:CreateTextEntry(rightPanel, function() end, rightW - 110, 22, nil,
        "NSUIEncAlertNameEntry", nil, options_dropdown_template)
    nameEntry:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -14)

    local enabledCB = CreateFrame("CheckButton", "NSUIEncAlertEnabled", rightPanel,
        "UICheckButtonTemplate")
    enabledCB:SetSize(22, 22)
    enabledCB:SetPoint("LEFT", nameEntry.widget, "RIGHT", 8, 0)

    local enabledLbl = rightPanel:CreateFontString(nil, "OVERLAY")
    enabledLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    enabledLbl:SetTextColor(0.7, 0.7, 0.7, 1)
    enabledLbl:SetText("Enabled")
    enabledLbl:SetPoint("LEFT", enabledCB, "RIGHT", 2, 0)

    -- ── Inner tab bar ────────────────────────────────────────────────────────
    local INNER_TABS     = { "Display", "Trigger", "Sound", "Load" }
    local innerTabBtns   = {}
    local innerTabFrames = {}
    local activeInnerTab = "Display"

    local function SelectInnerTab(name)
        activeInnerTab = name
        for _, tn in ipairs(INNER_TABS) do
            innerTabFrames[tn]:SetShown(tn == name)
            if tn == name then innerTabBtns[tn]:Select()
            else               innerTabBtns[tn]:Deselect() end
        end
    end

    local tabBtnW   = 84
    local tabBtnGap = 3
    local tabRowY   = -42

    for i, tabName in ipairs(INNER_TABS) do
        local btn = CreateSubButton(rightPanel, tabName, function()
            SelectInnerTab(tabName)
        end, tabBtnW, "NSUIEncAlertInnerTab_" .. tabName)
        btn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", (i - 1) * (tabBtnW + tabBtnGap), tabRowY)
        innerTabBtns[tabName] = btn
    end

    -- ── Preview button — right-aligned on the tab row ────────────────────────
    -- (PreviewAlert body defined below, after dispF / sndF are in scope)
    local previewBtn = CreateButton(rightPanel, "Preview", function() PreviewAlert() end, 80, 18,
        "NSUIEncAlertPreview")
    previewBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY)

    -- Separator below tabs
    local tabSep = rightPanel:CreateTexture(nil, "ARTWORK")
    tabSep:SetColorTexture(0, 1, 1, 0.20)
    tabSep:SetHeight(1)
    tabSep:SetPoint("TOPLEFT",  rightPanel, "TOPLEFT",  0, tabRowY - 20)
    tabSep:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, tabRowY - 20)

    local contentY = tabRowY - 26   -- -68

    for _, tabName in ipairs(INNER_TABS) do
        local f = CreateFrame("Frame", nil, rightPanel)
        f:SetPoint("TOPLEFT",     rightPanel, "TOPLEFT",     0, contentY)
        f:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)
        f:Hide()
        innerTabFrames[tabName] = f
    end

    -- ================================================================
    -- Helper: build a lock overlay for a tab frame
    -- ================================================================
    local function MakeLockOverlay(parent, message)
        local ov = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        ov:SetAllPoints(parent)
        ov:SetFrameLevel(parent:GetFrameLevel() + 10)
        DF:ApplyStandardBackdrop(ov)
        ov.__background:SetVertexColor(0.02, 0.02, 0.02)
        ov.__background:SetAlpha(0.82)

        local lbl = ov:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "")
        lbl:SetTextColor(0.55, 0.55, 0.55, 1)
        lbl:SetText(message)
        lbl:SetPoint("CENTER", ov, "CENTER", 0, 0)
        lbl:SetJustifyH("CENTER")

        ov:Hide()
        return ov
    end

    -- ================================================================
    -- DISPLAY TAB
    -- ================================================================
    local dispF = innerTabFrames["Display"]

    -- (dispHint kept as a local so SetCustomMode/SetReloeCreatedMode can reference it)
    local dispHint = dispF:CreateFontString(nil, "OVERLAY")
    dispHint:Hide()

    local typeLbl = dispF:CreateFontString(nil, "OVERLAY")
    typeLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    typeLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    typeLbl:SetText("Type")
    typeLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -2)

    local TYPES    = { "Text", "Bar", "Icon" }
    local typeBtns = {}
    local typeBtnW = 70

    local function SetDisplayType(t)
        for _, tn in ipairs(TYPES) do
            if tn == t then typeBtns[tn]:Select() else typeBtns[tn]:Deselect() end
        end
    end
    dispF.SetDisplayType = SetDisplayType

    for i, tn in ipairs(TYPES) do
        local tb = CreateSubButton(dispF, tn, function()
            SetDisplayType(tn)
            if dispF._alert then dispF._alert.Type = tn end
        end, typeBtnW, "NSUIEncAlertType_" .. tn)
        tb:SetPoint("TOPLEFT", dispF, "TOPLEFT", (i - 1) * (typeBtnW + 3), -18)
        typeBtns[tn] = tb
    end

    local textLbl = dispF:CreateFontString(nil, "OVERLAY")
    textLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    textLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    textLbl:SetText("Display Text")
    textLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -46)

    local textEntry = DF:CreateTextEntry(dispF, function() end, rightW, 22, nil,
        "NSUIEncAlertDisplayText", nil, options_dropdown_template)
    textEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -62)
    local function SaveDispText(self)
        local v = self:GetText()
        if dispF._alert then dispF._alert.text = v end
    end
    textEntry.editbox:SetScript("OnEnterPressed", function(self) SaveDispText(self); self:ClearFocus() end)
    textEntry.editbox:SetScript("OnEditFocusLost", SaveDispText)
    dispF.textEntry = textEntry

    local spellLbl = dispF:CreateFontString(nil, "OVERLAY")
    spellLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    spellLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    spellLbl:SetText("Spell ID  (optional — drives bar / icon texture)")
    spellLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -94)

    local spellEntry = DF:CreateTextEntry(dispF, function() end, 130, 22, nil,
        "NSUIEncAlertSpellID", nil, options_dropdown_template)
    spellEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -110)
    local function SaveSpellID(self)
        local v = tonumber(self:GetText()) or nil
        if dispF._alert then dispF._alert.spellID = v end
    end
    spellEntry.editbox:SetScript("OnEnterPressed", function(self) SaveSpellID(self); self:ClearFocus() end)
    spellEntry.editbox:SetScript("OnEditFocusLost", SaveSpellID)
    dispF.spellEntry = spellEntry

    local durLbl = dispF:CreateFontString(nil, "OVERLAY")
    durLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    durLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    durLbl:SetText("Duration  (seconds the alert is visible)")
    durLbl:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -142)

    local durEntry = DF:CreateTextEntry(dispF, function() end, 80, 22, nil,
        "NSUIEncAlertDuration", nil, options_dropdown_template)
    durEntry:SetPoint("TOPLEFT", dispF, "TOPLEFT", 0, -158)
    local function SaveDur(self)
        local v = tonumber(self:GetText())
        if dispF._alert then dispF._alert.dur = v or 8 end
    end
    durEntry.editbox:SetScript("OnEnterPressed", function(self) SaveDur(self); self:ClearFocus() end)
    durEntry.editbox:SetScript("OnEditFocusLost", SaveDur)
    dispF.durEntry = durEntry

    -- ================================================================
    -- TRIGGER TAB
    -- ================================================================
    local trigF = innerTabFrames["Trigger"]

    local trigBossLbl = trigF:CreateFontString(nil, "OVERLAY")
    trigBossLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    trigBossLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    trigBossLbl:SetText("Boss")
    trigBossLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -2)

    local function BuildTrigBossOptions()
        return BossData.BuildBossDropdownOptions(function(v)
            if trigF._alert then
                trigF._alert.encID = v
                RebuildList()
            end
        end, "Any Boss")
    end

    local trigBossDD = DF:CreateDropDown(trigF, BuildTrigBossOptions, nil, 200, 22, nil,
        "NSUIEncAlertTrigBoss", options_dropdown_template)
    trigBossDD:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -18)
    trigF.bossDD = trigBossDD

    local phaseLbl = trigF:CreateFontString(nil, "OVERLAY")
    phaseLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    phaseLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    phaseLbl:SetText("Phase")
    phaseLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -50)

    local phaseEntry = DF:CreateTextEntry(trigF, function() end, 60, 22, nil,
        "NSUIEncAlertPhase", nil, options_dropdown_template)
    phaseEntry:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -66)
    phaseEntry.editbox:SetScript("OnEnterPressed", function(self)
        if trigF._alert then
            trigF._alert.phase = math.max(1, math.floor(tonumber(self:GetText()) or 1))
        end
        self:ClearFocus()
    end)
    phaseEntry.editbox:SetScript("OnEditFocusLost", function(self)
        if trigF._alert then
            trigF._alert.phase = math.max(1, math.floor(tonumber(self:GetText()) or 1))
        end
    end)
    trigF.phaseEntry = phaseEntry

    local timesLbl = trigF:CreateFontString(nil, "OVERLAY")
    timesLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    timesLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    timesLbl:SetText("Trigger Times  (seconds into phase)")
    timesLbl:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -98)

    -- Times list: native ScrollFrame
    local timesListH = 150
    local timesListW = rightW - 20

    local timesScroll = CreateFrame("ScrollFrame", "NSUIEncAlertTimesScroll", trigF,
        "UIPanelScrollFrameTemplate")
    timesScroll:SetSize(timesListW, timesListH)
    timesScroll:SetPoint("TOPLEFT", trigF, "TOPLEFT", 0, -114)

    local timesChild = CreateFrame("Frame", nil, timesScroll, "BackdropTemplate")
    timesChild:SetSize(timesListW - 18, 1)
    timesChild:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        tile = true, tileSize = 64 })
    timesChild:SetBackdropColor(0.04, 0.04, 0.04, 0.85)
    timesScroll:SetScrollChild(timesChild)

    local timeRowH  = 22
    local timeRows  = {}

    local function RebuildTimeRows()
        for _, row in ipairs(timeRows) do row:Hide() end
        timeRows = {}
        if not trigF._alert then return end
        local times = trigF._alert.times or {}
        for i, t in ipairs(times) do
            local row = CreateFrame("Frame", nil, timesChild)
            row:SetSize(timesChild:GetWidth(), timeRowH)
            row:SetPoint("TOPLEFT", timesChild, "TOPLEFT", 0, -(i - 1) * timeRowH)

            if i % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, 0.03)
            end

            local tLbl = row:CreateFontString(nil, "OVERLAY")
            tLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 13, "")
            tLbl:SetTextColor(1, 1, 1, 1)
            tLbl:SetPoint("LEFT", row, "LEFT", 8, 0)
            tLbl:SetText(string.format("%.2f s", t))

            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetSize(14, 14)
            delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            delBtn:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
            delBtn:GetNormalTexture():SetDesaturated(true)
            delBtn:GetNormalTexture():SetVertexColor(0.9, 0.3, 0.3)
            local ri = i
            delBtn:SetScript("OnClick", function()
                if trigF._alert then
                    table.remove(trigF._alert.times, ri)
                    RebuildTimeRows()
                end
            end)

            timeRows[i] = row
        end

        local totalH = math.max(#times * timeRowH, 1)
        timesChild:SetHeight(totalH)
        local bar = _G["NSUIEncAlertTimesScrollScrollBar"]
        if bar then
            local maxScroll = math.max(0, totalH - timesListH)
            bar:SetMinMaxValues(0, maxScroll)
            if bar:GetValue() > maxScroll then bar:SetValue(0) end
        end
    end
    trigF.RebuildTimeRows = RebuildTimeRows

    local addTimeLbl = trigF:CreateFontString(nil, "OVERLAY")
    addTimeLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 11, "")
    addTimeLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    addTimeLbl:SetText("Add time (s)")
    addTimeLbl:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -4)

    local addTimeEntry = DF:CreateTextEntry(trigF, function() end, 90, 22, nil,
        "NSUIEncAlertAddTime", nil, options_dropdown_template)
    addTimeEntry:SetPoint("TOPLEFT", timesScroll, "BOTTOMLEFT", 0, -20)
    trigF.addTimeEntry = addTimeEntry

    local function DoAddTime()
        local v = tonumber(addTimeEntry:GetText())
        if v and trigF._alert then
            trigF._alert.times = trigF._alert.times or {}
            local inserted = false
            for i2, existing in ipairs(trigF._alert.times) do
                if v < existing then
                    table.insert(trigF._alert.times, i2, v)
                    inserted = true
                    break
                end
            end
            if not inserted then table.insert(trigF._alert.times, v) end
            addTimeEntry:SetText("")
            RebuildTimeRows()
        end
    end

    addTimeEntry.editbox:SetScript("OnEnterPressed", function(self)
        DoAddTime()
        self:ClearFocus()
    end)

    local addTimeBtn = CreateSubButton(trigF, "Add", DoAddTime, 54,
        "NSUIEncAlertAddTimeBtn")
    addTimeBtn:SetPoint("LEFT", addTimeEntry.widget, "RIGHT", 6, 0)

    -- Lock overlay for Trigger tab (shown when hardcoded boss is selected)
    trigF.lockOverlay = MakeLockOverlay(trigF,
        "Trigger timing is defined in code\nand cannot be edited here.")

    -- ================================================================
    -- SOUND TAB
    -- ================================================================
    local sndF = innerTabFrames["Sound"]

    -- (sndHint kept as a local so SetCustomMode/SetReloeCreatedMode can reference it)
    local sndHint = sndF:CreateFontString(nil, "OVERLAY")
    sndHint:Hide()

    local ttsCB = CreateFrame("CheckButton", "NSUIEncAlertTTSCB", sndF, "UICheckButtonTemplate")
    ttsCB:SetSize(22, 22)
    ttsCB:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -4)
    ttsCB:SetScript("OnClick", function(self)
        if not sndF._alert then return end
        if sndF._reloeMode then
            local v = sndF.ttsTextEntry:GetText()
            sndF._alert.TTS = self:GetChecked() and ((v ~= "") and v or true) or false
        else
            sndF._alert.TTSEnabled = self:GetChecked()
        end
    end)
    sndF.ttsCB = ttsCB

    local ttsToggleLbl = sndF:CreateFontString(nil, "OVERLAY")
    ttsToggleLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    ttsToggleLbl:SetTextColor(0.7, 0.7, 0.7, 1)
    ttsToggleLbl:SetText("Enable Text-to-Speech")
    ttsToggleLbl:SetPoint("LEFT", ttsCB, "RIGHT", 4, 0)

    local ttsTextLbl = sndF:CreateFontString(nil, "OVERLAY")
    ttsTextLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    ttsTextLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    ttsTextLbl:SetText("TTS Text  (leave blank to speak the Display Text)")
    ttsTextLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -34)

    local ttsTextEntry = DF:CreateTextEntry(sndF, function() end, rightW, 22, nil,
        "NSUIEncAlertTTSText", nil, options_dropdown_template)
    ttsTextEntry:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -50)
    local function SaveTTSText(self)
        local v = self:GetText()
        if not sndF._alert then return end
        if sndF._reloeMode then
            if sndF._alert.TTS ~= false then
                sndF._alert.TTS = (v ~= "") and v or true
            end
        else
            sndF._alert.TTSText = v
        end
    end
    ttsTextEntry.editbox:SetScript("OnEnterPressed", function(self) SaveTTSText(self); self:ClearFocus() end)
    ttsTextEntry.editbox:SetScript("OnEditFocusLost", SaveTTSText)
    sndF.ttsTextEntry = ttsTextEntry

    local ttsTimerLbl = sndF:CreateFontString(nil, "OVERLAY")
    ttsTimerLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    ttsTimerLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    ttsTimerLbl:SetText("TTS Timer  (seconds — when TTS fires, on the same timeline as trigger time)")
    ttsTimerLbl:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -82)

    local ttsTimerEntry = DF:CreateTextEntry(sndF, function() end, 80, 22, nil,
        "NSUIEncAlertTTSTimer", nil, options_dropdown_template)
    ttsTimerEntry:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -98)
    local function SaveTTSTimer(self)
        local v = tonumber(self:GetText())
        if sndF._alert then sndF._alert.TTSTimer = v or 8 end
    end
    ttsTimerEntry.editbox:SetScript("OnEnterPressed", function(self) SaveTTSTimer(self); self:ClearFocus() end)
    ttsTimerEntry.editbox:SetScript("OnEditFocusLost", SaveTTSTimer)
    sndF.ttsTimerEntry = ttsTimerEntry

    local cdCB = CreateFrame("CheckButton", "NSUIEncAlertCDCB", sndF, "UICheckButtonTemplate")
    cdCB:SetSize(22, 22)
    cdCB:SetPoint("TOPLEFT", sndF, "TOPLEFT", 0, -130)
    sndF.cdCB = cdCB

    local cdToggleLbl = sndF:CreateFontString(nil, "OVERLAY")
    cdToggleLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    cdToggleLbl:SetTextColor(0.7, 0.7, 0.7, 1)
    cdToggleLbl:SetText("Countdown for")
    cdToggleLbl:SetPoint("LEFT", cdCB, "RIGHT", 4, 0)

    local cdEntry = DF:CreateTextEntry(sndF, function() end, 60, 22, nil,
        "NSUIEncAlertCountdown", nil, options_dropdown_template)
    cdEntry:SetPoint("LEFT", cdToggleLbl, "RIGHT", 6, 0)
    cdEntry:SetPoint("TOP",  cdCB, "TOP", 0, 0)
    local function SaveCountdown(self)
        local v = tonumber(self:GetText())
        if sndF._alert then sndF._alert.countdown = (v and v > 0) and v or false end
    end
    cdEntry.editbox:SetScript("OnEnterPressed", function(self) SaveCountdown(self); self:ClearFocus() end)
    cdEntry.editbox:SetScript("OnEditFocusLost", SaveCountdown)
    sndF.cdEntry = cdEntry

    local cdSecLbl = sndF:CreateFontString(nil, "OVERLAY")
    cdSecLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    cdSecLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    cdSecLbl:SetText("seconds")
    cdSecLbl:SetPoint("LEFT", cdEntry.widget, "RIGHT", 5, 0)

    cdCB:SetScript("OnClick", function(self)
        if sndF._alert then
            sndF._alert.countdown = self:GetChecked() and (tonumber(cdEntry:GetText()) or 5) or false
        end
    end)

    -- ================================================================
    -- LOAD TAB
    -- ================================================================
    local loadF = innerTabFrames["Load"]

    local classLbl = loadF:CreateFontString(nil, "OVERLAY")
    classLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    classLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    classLbl:SetText("Class")
    classLbl:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -2)

    local function BuildClassOptions()
        local opts = {{ label = "All Classes", value = "", onclick = function()
            if loadF._alert then loadF._alert.loadClass = nil end
        end }}
        for _, cls in ipairs(CLASS_NAMES) do
            local c = cls
            table.insert(opts, {
                label   = CLASS_DISPLAY[c],
                value   = c,
                onclick = function(_, _, v)
                    if loadF._alert then loadF._alert.loadClass = v end
                end,
            })
        end
        return opts
    end

    local classDD = DF:CreateDropDown(loadF, BuildClassOptions, nil, 180, 22, nil,
        "NSUIEncAlertClass", options_dropdown_template)
    classDD:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -18)
    loadF.classDD = classDD

    local specLbl = loadF:CreateFontString(nil, "OVERLAY")
    specLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    specLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    specLbl:SetText("Spec  (1–4 based on the class spec order)")
    specLbl:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -50)

    local function BuildSpecOptions()
        local opts = {{ label = "All Specs", value = 0, onclick = function()
            if loadF._alert then loadF._alert.loadSpec = nil end
        end }}
        for i = 1, 4 do
            local idx = i
            table.insert(opts, {
                label   = "Spec " .. i,
                value   = i,
                onclick = function(_, _, v)
                    if loadF._alert then loadF._alert.loadSpec = v end
                end,
            })
        end
        return opts
    end

    local specDD = DF:CreateDropDown(loadF, BuildSpecOptions, nil, 120, 22, nil,
        "NSUIEncAlertSpec", options_dropdown_template)
    specDD:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -66)
    loadF.specDD = specDD

    local charLbl = loadF:CreateFontString(nil, "OVERLAY")
    charLbl:SetFont(NSI.LSM:Fetch("font", NSRT.Settings.GlobalFont), 12, "")
    charLbl:SetTextColor(0.6, 0.6, 0.6, 1)
    charLbl:SetText("Character Name  (exact match — leave blank for all)")
    charLbl:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -98)

    local charEntry = DF:CreateTextEntry(loadF, function() end, 200, 22, nil,
        "NSUIEncAlertChar", nil, options_dropdown_template)
    charEntry:SetPoint("TOPLEFT", loadF, "TOPLEFT", 0, -114)
    charEntry.editbox:SetScript("OnEnterPressed", function(self)
        if loadF._alert then
            local v = self:GetText()
            loadF._alert.loadCharacter = (v ~= "") and v or nil
        end
        self:ClearFocus()
    end)
    charEntry.editbox:SetScript("OnEditFocusLost", function(self)
        if loadF._alert then
            local v = self:GetText()
            loadF._alert.loadCharacter = (v ~= "") and v or nil
        end
    end)
    loadF.charEntry = charEntry

    -- Lock overlay for Load tab (reloeCreated alerts use built-in role field)
    loadF.lockOverlay = MakeLockOverlay(loadF,
        "Class / spec filters do not apply\nto addon-created alerts.")

    -- Lock overlay for Sound tab (reloeCreated alerts — sound is managed by the addon)
    sndF.lockOverlay = MakeLockOverlay(sndF,
        "Sound settings are fixed\nfor addon-created alerts.")

    -- ================================================================
    -- Helper: set panel into custom-alert mode vs reloeCreated mode
    -- ================================================================
    local function SetCustomMode()
        trigF.lockOverlay:Hide()
        loadF.lockOverlay:Hide()
        sndF.lockOverlay:Hide()
        dispHint:Hide()
        sndHint:Hide()
        sndF._reloeMode = false
        nameEntry.editbox:SetEnabled(true)
        nameEntry.editbox:SetAlpha(1)
    end

    local function SetReloeCreatedMode()
        trigF.lockOverlay:Show()
        loadF.lockOverlay:Hide()
        sndF.lockOverlay:Hide()
        dispHint:Hide()
        sndHint:Hide()
        sndF._reloeMode = true
        nameEntry.editbox:SetEnabled(false)
        nameEntry.editbox:SetAlpha(0.45)
    end

    -- ================================================================
    -- PreviewAlert ── fire the current alert visually without a trigger
    -- ================================================================
    PreviewAlert = function()
        local text, spellID, dur, Type, ttsEnabled, ttsText, ttsTimer, countdown

        if not dispF._alert then return end
        local a    = dispF._alert
        text       = a.text or ""
        spellID    = a.spellID
        dur        = a.dur or 8
        Type       = a.Type or "Text"
        ttsEnabled = a.TTSEnabled
        ttsText    = a.TTSText
        ttsTimer   = a.TTSTimer
        countdown  = a.countdown

        -- These tables are normally created by HideAllReminders; ensure they exist
        NSI.PlayedSound      = NSI.PlayedSound      or {}
        NSI.StartedCountdown = NSI.StartedCountdown or {}

        local info     = NSI:CreateDefaultAlert(text, Type, spellID, dur, 99, 0)
        info.TTS       = ttsEnabled and ((ttsText and ttsText ~= "") and ttsText or text) or false
        info.TTSTimer  = ttsTimer or dur
        info.countdown = countdown or false
        NSI:DisplayReminder(info)
    end

    -- ================================================================
    -- SelectAlert ── load a custom alert into all right-panel controls
    -- ================================================================
    SelectAlert = function(index)
        selectedIndex        = index
        selectedReloeEncID   = nil
        selectedReloeKey     = nil
        local alert = NSRT.CustomBossAlerts and NSRT.CustomBossAlerts[index]
        if not alert then
            rightPanel:Hide()
            RebuildList()
            return
        end

        rightPanel:Show()
        SetCustomMode()

        dispF._alert = alert; dispF._hardcodedEncID = nil
        trigF._alert = alert; trigF._hardcodedEncID = nil
        sndF._alert  = alert; sndF._hardcodedEncID  = nil
        loadF._alert = alert; loadF._hardcodedEncID = nil

        -- Header
        nameEntry:SetText(alert.name or "")
        enabledCB:SetChecked(alert.enabled and true or false)

        nameEntry.editbox:SetScript("OnEnterPressed", function(self)
            alert.name = self:GetText()
            self:ClearFocus()
            RebuildList()
        end)
        nameEntry.editbox:SetScript("OnEditFocusLost", function(self)
            alert.name = self:GetText()
            RebuildList()
        end)
        enabledCB:SetScript("OnClick", function(self)
            alert.enabled = self:GetChecked()
            RebuildList()
        end)

        -- Display tab
        dispF.SetDisplayType(alert.Type or "Text")
        dispF.textEntry:SetText(alert.text or "")
        dispF.spellEntry:SetText(alert.spellID and tostring(alert.spellID) or "")
        dispF.durEntry:SetText(tostring(alert.dur or 8))

        -- Trigger tab
        trigF.bossDD:Select(alert.encID or 0)
        trigF.phaseEntry:SetText(tostring(alert.phase or 1))
        trigF.RebuildTimeRows()

        -- Sound tab
        sndF.ttsCB:SetChecked(alert.TTSEnabled and true or false)
        sndF.ttsTextEntry:SetText(alert.TTSText or "")
        sndF.ttsTimerEntry:SetText(tostring(alert.TTSTimer or 8))
        local hasCD = alert.countdown and alert.countdown ~= false
        sndF.cdCB:SetChecked(hasCD)
        sndF.cdEntry:SetText(hasCD and tostring(alert.countdown) or "")

        -- Load tab
        loadF.classDD:Select(alert.loadClass or "")
        loadF.specDD:Select(alert.loadSpec or 0)
        loadF.charEntry:SetText(alert.loadCharacter or "")

        RebuildList()
        SelectInnerTab(activeInnerTab)
    end

    -- ================================================================
    -- SelectReloeCreatedAlert ── load an addon-created alert into the panel
    -- ================================================================
    SelectReloeCreatedAlert = function(encID, diffID, alertKey)
        selectedReloeEncID  = encID
        selectedReloeDiffID = diffID
        selectedReloeKey    = alertKey
        selectedIndex       = nil

        local entry = NSRT.EncounterAlerts and NSRT.EncounterAlerts[encID]
                      and NSRT.EncounterAlerts[encID][diffID]
                      and NSRT.EncounterAlerts[encID][diffID][alertKey]
        if not entry then
            rightPanel:Hide()
            RebuildList()
            return
        end

        rightPanel:Show()
        SetReloeCreatedMode()

        dispF._alert = nil;   dispF._hardcodedEncID = nil
        trigF._alert = nil;   trigF._hardcodedEncID = nil
        sndF._alert  = entry; sndF._hardcodedEncID  = nil
        loadF._alert = nil;   loadF._hardcodedEncID = nil

        -- Header: alert name (read-only)
        nameEntry:SetText(ReloeAlertName(entry))
        nameEntry.editbox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        nameEntry.editbox:SetScript("OnEditFocusLost", function() end)

        local alertName = entry.name or entry.text
        enabledCB:SetChecked(entry.enabled and true or false)
        enabledCB:SetScript("OnClick", function(self)
            local val = self:GetChecked()
            -- Toggle all diffID entries with matching name
            for did, diffTable in pairs(NSRT.EncounterAlerts[encID] or {}) do
                if type(did) == "number" and type(diffTable) == "table" then
                    for _, e in pairs(diffTable) do
                        if type(e) == "table" and (e.name == alertName or e.text == alertName) then
                            e.enabled = val
                        end
                    end
                end
            end
            RebuildList()
        end)

        -- Display tab: show stored values (editing locked by lock overlay)
        local dispType = (entry.BarOverwrite and "Bar") or (entry.IconOverwrite and "Icon") or (entry.CircleOverwrite and "Circle") or "Text"
        dispF.SetDisplayType(dispType)
        dispF.textEntry:SetText(entry.text or "")
        dispF.spellEntry:SetText(entry.spellID and tostring(entry.spellID) or "")
        dispF.durEntry:SetText(tostring(entry.dur or 8))

        -- Trigger tab: inert (lock overlay shown)
        trigF.RebuildTimeRows()

        -- Sound tab
        local ttsActive = entry.TTS ~= false and entry.TTS ~= nil
        sndF.ttsCB:SetChecked(ttsActive)
        sndF.ttsTextEntry:SetText(type(entry.TTS) == "string" and entry.TTS or "")
        sndF.ttsTimerEntry:SetText(tostring(entry.TTSTimer or entry.dur or 8))
        local hasCD = entry.countdown and entry.countdown ~= false
        sndF.cdCB:SetChecked(hasCD and true or false)
        sndF.cdEntry:SetText(hasCD and tostring(entry.countdown) or "")

        RebuildList()
        SelectInnerTab(activeInnerTab)
    end

    SelectInnerTab("Display")

    screen:SetScript("OnShow", function()
        RebuildList()
        if selectedReloeEncID and selectedReloeDiffID and selectedReloeKey then
            SelectReloeCreatedAlert(selectedReloeEncID, selectedReloeDiffID, selectedReloeKey)
        elseif selectedIndex then
            SelectAlert(selectedIndex)
        end
    end)

    return screen
end

-- ============================================================================
-- Export
-- ============================================================================
NSI.UI = NSI.UI or {}
NSI.UI.BossReminders = {
    BuildBossRemindersUI = BuildBossRemindersUI,
}
