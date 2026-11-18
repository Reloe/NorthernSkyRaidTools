-- ============================================================
--  UI/PlayerHistory.lua - what a candidate was already given, docked to the council window
--
--  Opened with the clock button in the council window's title bar. Hovering (or selecting) a candidate row
--  fills it with that player's loot from the last 30 days, newest first, with a "x weeks ago" separator
--  between weeks. By default it lists only the slot of the selected item (rings and trinkets cover both
--  slots); the toggle in its header shows everything. Bonus rolls are entries like any other, tagged.
--  The player stays pinned when the mouse leaves the row, so the list can be scrolled.
--  Council only; built on first use.
-- ============================================================
local ADDON, _ = ...
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
local C = NSI.UI.Components

local PH = {}
LC.UI.PlayerHistory = PH

local W, DAYS = 340, 30
local ROW_H, SEP_H, HEAD_H = 42, 20, 58
local DIFF_HEX = { LFR = "ff1eff00", Normal = "ff0070dd", Heroic = "ffa335ee", Mythic = "ffff8000" }
local panel, box, rows, seps, empty
local player, slotOnly, parentFrame = nil, true, nil
local evFrame

-- ---- slot matching -------------------------------------------------------------------------
-- { [inventorySlot] = true } for a drop or an entry: equippable items by their equip location, tier tokens
-- by the tier slot they are for. nil when it cannot be told.
local function SlotSet(dropID, item, itemID)
    local loc = select(4, C_Item.GetItemInfoInstant(item or itemID))
    local slots = loc and loc ~= "" and LC.Items.EquipSlots[loc]
    if slots then
        local set = {}
        for _, s in ipairs(slots) do set[s] = true end
        return set
    end
    local tier = LC.Items.TierSlotOfDrop(dropID, item, itemID)
    if not tier then return nil end
    local set = {}
    for _, t in ipairs(LC.Items.TierSlots) do
        if tier == "ANY" or t.key == tier then set[t.slot] = true end
    end
    return set
end

local function SelectedSlots(dropID)
    local st = LC.Session.state
    local d = st and dropID and st.drops[dropID]
    return d and SlotSet(d.id, d.item, d.itemID) or nil
end

-- ---- row rendering -------------------------------------------------------------------------
local function ReasonText(e)
    if e.source == "bonus" then return "|cffffd100" .. LC.Loc("Bonus roll") .. "|r" end
    local r = e.reason and LC.Ruleset.ResponseById and LC.Ruleset.ResponseById(e.reason)
    local text = (r and r.text and LC.Loc(r.text)) or e.reasonText or e.reason or ""
    return text
end

local function DiffText(d)
    local name = d and LC.Items.DifficultyName[d]
    if not name then return "" end
    return "|c" .. (DIFF_HEX[name] or "ffffffff") .. LC.Loc(name) .. "|r"
end

local function NewRow()
    local row = CreateFrame("Frame", nil, box.scrollChild)
    row:SetHeight(ROW_H)
    C.StyleRow(row, NSI.UI.Style.row_stripe_dark)
    -- bonus rolls get a faint gold wash over the row stripe
    row.tint = row:CreateTexture(nil, "ARTWORK", nil, -8)
    row.tint:SetAllPoints()
    row.tint:SetColorTexture(1, 0.82, 0, 0.12)
    row.tint:Hide()
    row.icon = C.CreateItemButton(row, 32)
    row.icon.frame:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.name = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.name, 12)
    row.name:SetJustifyH("LEFT")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 42, -5)
    row.name:SetPoint("RIGHT", row, "RIGHT", -52, 0)
    row.name:SetWordWrap(false)
    row.sub = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.sub, "small")
    row.sub:SetJustifyH("LEFT")
    row.sub:SetTextColor(0.7, 0.7, 0.7)
    row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.sub:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.sub:SetWordWrap(false)
    row.date = row:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(row.date, "small")
    row.date:SetTextColor(0.6, 0.6, 0.6)
    row.date:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -6)
    return row
end

local function NewSep()
    local fs = box.scrollChild:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(fs, "small")
    fs:SetJustifyH("LEFT")
    NSI.UI.Style.PaintAccent(fs, "SetTextColor", 1)
    local line = box.scrollChild:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    NSI.UI.Style.PaintAccent(line, "SetColorTexture", 0.35)
    fs.line = line
    return fs
end

local requested = {}
local function Name(e)
    local src = e.item or ("item:" .. e.itemID)
    local name, _, quality = C_Item.GetItemInfo(src)
    if not name then
        if not requested[e.itemID] and C_Item.RequestLoadItemDataByID then
            requested[e.itemID] = true
            C_Item.RequestLoadItemDataByID(e.itemID)
        end
        return "Item " .. e.itemID
    end
    local q = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    return (q and q.hex or "|cffffffff") .. name .. "|r"
end

-- ---- the list --------------------------------------------------------------------------------
function PH.Entries()
    if not player then return {}, nil end
    local now = GetServerTime()
    local list = LC.History.ForPlayer(LC.History.Query(), player, now, DAYS)
    local want = slotOnly and SelectedSlots(PH.dropID and PH.dropID()) or nil
    if want then
        local kept = {}
        for _, e in ipairs(list) do
            if LC.History.SlotsOverlap(want, SlotSet(e.id, e.item, e.itemID)) then kept[#kept + 1] = e end
        end
        list = kept
    end
    return list, want ~= nil
end

function PH.Refresh()
    if not (panel and panel:IsShown()) then return end
    local list, filtered = PH.Entries()
    local now = GetServerTime()
    panel.name:SetText(player and (LC.Roster.Display(player) or player) or LC.Loc("Hover a candidate"))
    local cls = player and LC.Roster.ClassOf(player)
    local color = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if color then panel.name:SetTextColor(color.r, color.g, color.b) else panel.name:SetTextColor(1, 1, 1) end
    panel.sub:SetText(string.format(LC.Loc("Last %d days"), DAYS) .. (filtered and (" - " .. LC.Loc("this slot")) or ""))
    panel.toggle:SetText(LC.Loc(slotOnly and "Show all slots" or "This slot only"))

    local groups = LC.History.GroupByWeek(list, now)
    local y, ri, si = 0, 0, 0
    for _, g in ipairs(groups) do
        si = si + 1
        seps[si] = seps[si] or NewSep()
        local sep = seps[si]
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", box.scrollChild, "TOPLEFT", 6, -y - 3)
        sep:SetText(LC.Loc(g.weeks <= 1 and LC.History.WeekLabel(g.weeks) or "%d weeks ago"):format(g.weeks))
        sep.line:ClearAllPoints()
        sep.line:SetPoint("LEFT", sep, "RIGHT", 6, 0)
        sep.line:SetPoint("RIGHT", box.scrollChild, "RIGHT", -6, 0)
        sep:Show(); sep.line:Show()
        y = y + SEP_H
        for _, e in ipairs(g.items) do
            ri = ri + 1
            rows[ri] = rows[ri] or NewRow()
            local row = rows[ri]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", box.scrollChild, "TOPLEFT", 0, -y)
            row:SetPoint("TOPRIGHT", box.scrollChild, "TOPRIGHT", 0, -y)
            row.icon:SetItem(e.item or ("item:" .. e.itemID))
            row.name:SetText(Name(e))
            local boss = e.boss and e.boss ~= "" and e.boss or (e.encounterID and LC.History.BossName(e.encounterID, e.boss)) or nil
            local parts = {}
            local diff = DiffText(e.difficulty)
            if diff ~= "" then parts[#parts + 1] = diff end
            if boss then parts[#parts + 1] = boss end
            local reason = ReasonText(e)
            if reason ~= "" then parts[#parts + 1] = reason end
            row.sub:SetText(table.concat(parts, "  |cff666666-|r  "))
            row.date:SetText(date("%b %d", e.time or 0))
            row.tint:SetShown(e.source == "bonus")
            row:Show()
            y = y + ROW_H
        end
    end
    for i = ri + 1, #rows do rows[i]:Hide() end
    for i = si + 1, #seps do seps[i]:Hide(); seps[i].line:Hide() end
    box.scrollChild:SetHeight(math.max(1, y))
    box:UpdateScrollBar()
    empty:SetShown(#list == 0)
    if #list == 0 then
        empty:SetText(player and LC.Loc(filtered and "Nothing in this slot in the last 30 days." or "No loot in the last 30 days.")
            or LC.Loc("Hover a candidate to see what they were given."))
    end
end

-- ---- frame ---------------------------------------------------------------------------------
-- Which side of the council window the panel docks to: the right, or the left when there is no room on screen.
local function Side()
    local right = parentFrame:GetRight()
    local scale = parentFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local room = right and (UIParent:GetRight() - right * scale) or 0
    return room >= (W + 8) * scale and "right" or "left"
end

local function Place()
    panel:ClearAllPoints()
    if Side() == "right" then
        panel:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 6, 0)
        panel:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMRIGHT", 6, 0)
    else
        panel:SetPoint("TOPRIGHT", parentFrame, "TOPLEFT", -6, 0)
        panel:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMLEFT", -6, 0)
    end
end

-- The title-bar button: its arrow points the way the panel will move. Closed, toward the side it opens on;
-- open, back toward the council window. The tooltip says what the panel shows.
local button, tip
local ICONS = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]
function PH.SetButton(btn, spec)
    button, tip = btn, spec
    PH.UpdateButton()
end

function PH.UpdateButton()
    if not (button and parentFrame) then return end
    local open = panel and panel:IsShown()
    local toward = Side()
    if open then toward = (toward == "right") and "left" or "right" end
    if button.frame.icon then button.frame.icon:SetTexture(ICONS .. (toward == "right" and "chevron-right.png" or "chevron-left.png")) end
    if tip then tip.title = open and "Hide player loot history" or "Show player loot history" end
end

function PH.Build(parent)
    if panel then return end
    parentFrame = parent
    panel = C.CreateFrame(parent, W, 400)
    panel:SetMovable(false)
    panel:RegisterForDrag()
    panel:SetScript("OnDragStart", nil)
    panel:SetScript("OnDragStop", nil)
    panel:SetFrameStrata(parent:GetFrameStrata())
    panel:SetFrameLevel(parent:GetFrameLevel() + 2)
    panel:Hide()

    panel.name = panel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(panel.name, 15)
    panel.name:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)
    panel.name:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
    panel.name:SetJustifyH("LEFT")
    panel.sub = panel:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(panel.sub, "small")
    panel.sub:SetTextColor(0.7, 0.85, 1)
    panel.sub:SetPoint("TOPLEFT", panel.name, "BOTTOMLEFT", 0, -4)
    local toggle = C.CreateButton(panel, "", function() slotOnly = not slotOnly; PH.Refresh() end, 110, 20)
    toggle.frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -34)
    panel.toggle = toggle

    box = C.CreateScrollBox(panel, W - 16, 100)
    box.frame:ClearAllPoints()
    box.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -HEAD_H - 4)
    box.frame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)
    rows, seps = {}, {}

    empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetPoint("TOP", panel, "TOP", 0, -HEAD_H - 40)
    empty:SetWidth(W - 40)
    empty:SetTextColor(0.65, 0.65, 0.65)

    -- item names load late: redraw when the client has them
    evFrame = CreateFrame("Frame")
    evFrame:SetScript("OnEvent", function() PH.Refresh() end)
    panel:HookScript("OnShow", function() evFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED"); Place(); PH.Refresh(); PH.UpdateButton() end)
    panel:HookScript("OnHide", function() evFrame:UnregisterEvent("GET_ITEM_INFO_RECEIVED"); PH.UpdateButton() end)
end

-- dropID is read lazily so the panel follows the council window's selected item.
function PH.SetDropSource(fn) PH.dropID = fn end

function PH.SetPlayer(key)
    if not key or key == player then return end
    player = key
    PH.Refresh()
end

function PH.Toggle()
    if not panel then return end
    if panel:IsShown() then panel:Hide() else panel:Show() end
end

function PH.Hide() if panel then panel:Hide() end end

LC.On("NSRT_LC_HISTORY_CHANGED", function() PH.Refresh() end)
