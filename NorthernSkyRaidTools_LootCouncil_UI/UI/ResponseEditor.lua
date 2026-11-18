-- ============================================================
--  UI/ResponseEditor.lua - edit the response buttons raiders see (V-4)
--  The raid leader decides the labels, the order, and which buttons need a note. Edits are saved to the
--  ruleset and re-sent to the raid when you lead. At most 7 buttons. These buttons are also the reasons
--  offered when awarding.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
local C = NSI.UI.Components

local RE = {}
LC.UI.ResponseEditor = RE
local frame, rows, preview = nil, {}, {}
local MAX = 7
local PREVIEW_BTN_W, PREVIEW_BTN_GAP = 76, 4     -- keep in step with BTN_W / BTN_GAP in Frames/LootFrame.lua
local ICONS = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]

local function List()
    local rs = LC.DB.G().ruleset
    return rs.responses
end

local function Changed()
    RE.Refresh()
    LC.Ruleset.Reapply()
    LC.Fire("NSRT_LC_RULESET_CHANGED", LC.Ruleset.IsActive())
end

local function Move(i, d)
    local l = List()
    local j = i + d
    if j < 1 or j > #l then return end
    l[i], l[j] = l[j], l[i]
    Changed()
end

function RE.Refresh()
    if not frame then return end
    local l = List()
    -- the preview: the same buttons, same width and same text rule as the raider's rolling window
    for i = 1, MAX do
        local pb, r = preview[i], l[i]
        if r then
            pb:SetText(LC.Loc(r.text) .. (r.needsNote and "*" or ""))
            pb.frame:Show()
        else
            pb.frame:Hide()
        end
    end
    for i = 1, MAX do
        local row, r = rows[i], l[i]
        if r then
            row.entry:SetValue(r.text or "")
            row.note:SetValue(r.needsNote == true)
            row.frame:Show()
        else
            row.frame:Hide()
        end
    end
    frame.add.frame:SetShown(#l < MAX)
    frame.add.frame:ClearAllPoints()
    frame.add.frame:SetPoint("TOPLEFT", frame.body, "TOPLEFT", 0, -22 - #l * 30 - 2)
end

function RE.Build()
    if frame then return end
    frame = LC.Frames.Shell.Create({ name = "NSLCResponseEditor", title = LC.Loc("Response buttons"), width = 600, height = 512,
        point = { "CENTER", -60, 20 } })
    local Shell = LC.Frames.Shell
    -- what raiders will see, at true size, so a label that gets cut off shows up here
    local pcard = Shell.Card(frame, LC.Loc("Preview"))
    pcard:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, frame.contentTop - 6)
    pcard:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, frame.contentTop - 6)
    pcard:SetHeight(Shell.CardHeight(pcard, 24))
    for i = 1, MAX do
        local pb = C.CreateButton(pcard.content, " ", function() end, PREVIEW_BTN_W, 24)
        pb:SetPoint("TOPLEFT", pcard.content, "TOPLEFT", (i - 1) * (PREVIEW_BTN_W + PREVIEW_BTN_GAP), 0)
        pb.frame:EnableMouse(false)          -- a picture of the buttons, not buttons
        pb.frame:Hide()
        preview[i] = pb
    end
    local card = Shell.Card(frame, LC.Loc("Buttons"))
    card:SetPoint("TOPLEFT", pcard, "BOTTOMLEFT", 0, -6)
    card:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 60)
    local actions = Shell.Card(frame, nil)
    actions:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    actions:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    actions:SetHeight(Shell.CardHeight(actions, 24))
    frame.body = card.content
    local hint = card.content:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(hint, 11)
    hint:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, 0)
    hint:SetText(LC.Loc("Label, then tick Note if the raider must write a note to use that button."))

    for i = 1, MAX do
        local f = CreateFrame("Frame", nil, card.content)
        f:SetSize(464, 26)
        f:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, -22 - (i - 1) * 30)
        local entry = C.CreateTextEntry(f, nil, function() local r = List()[i]; return r and r.text or "" end,
            function(_, value)
                local r = List()[i]
                if r and value and value ~= "" and value ~= r.text then r.text = value; Changed() end
            end, 190, 22)
        entry:SetPoint("LEFT", f, "LEFT", 6, 0)
        entry.editBox:SetMaxLetters(24)
        local note = C.CreateCheckButton(f, LC.Loc("Note"), function() local r = List()[i]; return r ~= nil and r.needsNote == true end,
            function(_, v) local r = List()[i]; if r then r.needsNote = v and true or nil; Changed() end end,
            70, 22, nil, LC.Loc("The raider must write a note to use this button."))
        note:SetPoint("LEFT", f, "LEFT", 204, 0)
        local up = C.CreateButton(f, "", function() Move(i, -1) end, 26, 22, nil, ICONS .. "arrow-up.png", nil, LC.Loc("Move up"))
        up:SetPoint("LEFT", f, "LEFT", 290, 0)
        local dn = C.CreateButton(f, "", function() Move(i, 1) end, 26, 22, nil, ICONS .. "arrow-down.png", nil, LC.Loc("Move down"))
        dn:SetPoint("LEFT", f, "LEFT", 320, 0)
        local del = C.CreateButton(f, LC.Loc("Remove"), function()
            local l = List()
            if #l <= 1 then return end
            table.remove(l, i)
            Changed()
        end, 100, 22, nil, ICONS .. "trash-2.png")
        del:SetPoint("LEFT", f, "LEFT", 354, 0)
        rows[i] = { frame = f, entry = entry, note = note }
    end

    frame.add = C.CreateButton(card.content, LC.Loc("Add button"), function()
        local l = List()
        if #l >= MAX then return end
        l[#l + 1] = { id = string.format("r%d%d", GetServerTime() % 100000, #l), text = LC.Loc("New"), color = "pass" }
        Changed()
    end, 120, 24, nil, ICONS .. "plus.png")
    local reset = C.CreateButton(actions.content, LC.Loc("Reset to defaults"), function()
        local rs = LC.DB.G().ruleset
        rs.responses = LC.DB.Copy(LC.Ruleset.defaults.responses)
        Changed()
    end, 150, 24, nil, ICONS .. "rotate-ccw.png")
    reset:SetPoint("LEFT", actions.content, "LEFT", 0, 0)
end

function RE.Open()
    RE.Build()
    LC.Frames.Shell.Reopen(frame)
    RE.Refresh()
end
