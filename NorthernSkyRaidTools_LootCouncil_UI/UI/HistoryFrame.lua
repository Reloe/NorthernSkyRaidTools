-- ============================================================
--  UI/HistoryFrame.lua - the loot history, organised for auditing (H-2, H-4)
--
--  Day -> difficulty -> boss -> items. Every item row shows the exact item (icon and name, with the bonus IDs
--  of the drop: hover for its tooltip), who it was awarded to, the reason, who it was actually traded to and
--  who traded it. Hovering the rest of the row shows the full audit trail. Days, difficulties and bosses fold;
--  the newest day starts open. A raid night that runs past midnight stays under one day (History.DAY_START_HOUR).
--
--  The list is virtualised (a fixed pool of row frames is recycled while scrolling), like the kit DataTable,
--  because the tree has rows of four kinds and a whole tier can be thousands of rows.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
local C = NSI.UI.Components
local STYLE = NSI.UI.Style

local HF = {}
LC.UI.HistoryFrame = HF

local W, H, ACT_H = 960, 620, 44
local ROW_H, SCROLL_W, WHEEL_ROWS, HEAD_H = 26, 6, 3, 20
local ICON_PATH = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]
local INDENT = { day = 8, diff = 26, boss = 44, item = 62 }
local COL = { time = 52, by = 104, to = 132, reason = 92, who = 124 }       -- fixed widths, laid out from the right

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local DIFF_COLOR = { [16] = "ffff8000", [15] = "ffa335ee", [14] = "ff0070dd", [17] = "ff1eff00" }

local frame, card, search, view, track, thumb, headStrip, summary, textBox, deleteTarget
local filterText, showUndone, unresolvedOnly = "", true, false
local masterFilter = nil                     -- nil = every loot master's awards; a character key = only what that character awarded
local masterDrop
local days, flat, openState, pool = {}, {}, {}, {}
local offset = 0
local dirty, scheduled = false, false
local requested = {}
local x = {}                                  -- column x positions, set by Layout

-- ---- small helpers -----------------------------------------------------------------------------
local function SetFont(fs, size) NSI:SetUIFont(fs, size) end

local function Hex(c)
    return string.format("|cff%02x%02x%02x", floor((c[1] or 1) * 255 + 0.5), floor((c[2] or 1) * 255 + 0.5), floor((c[3] or 1) * 255 + 0.5))
end
local function Paint(text, c) return Hex(c) .. text .. "|r" end

local function Name(key) return key and LC.Roster.Display(key) or "" end      -- class-coloured character name
local function Plain(key) return key and LC.Roster.Plain(key) or "" end       -- same without colour
local function When(t) return t and date("%Y-%m-%d %H:%M:%S", t) or "?" end
local function Clock(t) return t and date("%H:%M", t) or "" end
local function DiffName(d) return LC.Loc(LC.Items.DifficultyName[d] or ("Difficulty " .. tostring(d))) end

local function ClassName(e, key)
    return LC.Roster.Display(key, key == e.winner and e.class or nil)
end

local function ReasonText(e)
    if e.reasonText then return e.reasonText end
    local r = e.reason and LC.Ruleset.ResponseById(e.reason)
    if r then return LC.Loc(r.text) end
    return e.reason or ""
end

local function ItemSource(e) return e.item or ("item:" .. e.itemID) end

-- name, link, quality of the exact item; asks the client to load it when it is not cached yet.
local function ItemInfo(e)
    local name, link, quality = C_Item.GetItemInfo(ItemSource(e))
    if not name and not requested[e.itemID] then
        requested[e.itemID] = true
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(e.itemID) end
    end
    return name, link, quality
end

local function ShowText(title, text)
    textBox = textBox or C.CreateTextBoxDialog("NSLCHistoryText", LC.Loc("Loot Council history"), { width = 700, height = 320 })
    textBox:Open(text or "", title)
end

-- ---- audit text ----------------------------------------------------------------------------------
local STATUS_LABEL = { traded = "Traded", mismatch = "Traded to someone else", pending = "Pending", expired = "Not traded",
    self = "Looted by the winner", void = "Undone" }

local function BonusText(itemString)
    local d = itemString and LC.Items.Decode(itemString)
    if not d then return nil end
    return #d.bonusIDs > 0 and table.concat(d.bonusIDs, ", ") or LC.Loc("none")
end

-- The full story of one entry as a list of lines (tooltip and the details window).
function HF.Details(e, now)
    now = now or GetServerTime()
    local status = LC.History.Status(e, now)
    local t = e.trade
    local L = {}
    L[#L + 1] = string.format("%s · %s · %s", DiffName(e.difficulty), LC.History.BossName(e.encounterID, e.boss), When(e.kill))
    L[#L + 1] = string.format(LC.Loc("Awarded to %s for %s by %s at %s"), Name(e.winner), ReasonText(e), Name(e.by), When(e.time))
    if e.votes and e.votes.total > 0 then
        L[#L + 1] = string.format(LC.Loc("Council votes: %d of %d for the winner"), e.votes["for"], e.votes.total)
    end
    if e.holder then L[#L + 1] = string.format(LC.Loc("Looted by %s"), Name(e.holder)) end
    if status == "traded" then
        L[#L + 1] = string.format(LC.Loc("Traded to %s by %s at %s"), Name(t.to), Name(t.by or e.holder), When(t.at))
    elseif status == "mismatch" then
        L[#L + 1] = Paint(string.format(LC.Loc("TRADED TO %s, but awarded to %s. By %s at %s"), Name(t.to), Name(e.winner), Name(t.by or e.holder), When(t.at)), STYLE.danger)
    elseif status == "pending" then
        L[#L + 1] = Paint(string.format(LC.Loc("Not traded yet. The trade window closes at %s"), When((e.kill or e.time or 0) + 4 * 3600)), STYLE.warning)
    elseif status == "expired" then
        L[#L + 1] = Paint(string.format(LC.Loc("Never traded. The trade window closed at %s"), When((e.kill or e.time or 0) + 4 * 3600)), STYLE.danger)
    elseif status == "self" then
        L[#L + 1] = LC.Loc("Looted by the winner, no trade needed")
    elseif status == "void" then
        L[#L + 1] = Paint(string.format(LC.Loc("Undone by %s at %s"), Name(e.void.who), When(e.void.when)) .. (e.void.why and (": " .. e.void.why) or ""), STYLE.text_muted)
    end
    local dropBonus, tradeBonus = BonusText(e.item), t and BonusText(t.item)
    if dropBonus then L[#L + 1] = string.format(LC.Loc("Bonus IDs: %s"), dropBonus) end
    if tradeBonus and e.item and LC.Items.BonusScore(t.item, e.item) < 2 then
        L[#L + 1] = Paint(string.format(LC.Loc("The traded copy has different bonus IDs: %s"), tradeBonus), STYLE.warning)
    end
    if e.audit and #e.audit > 0 then
        L[#L + 1] = LC.Loc("Audit trail:")
        for _, a in ipairs(e.audit) do
            local line = When(a.when) .. "  " .. LC.Loc(a.action == "reassign" and "Reassigned" or (a.action == "undo" and "Undone" or "Awarded"))
            if a.from or a.to then line = line .. "  " .. Name(a.from) .. " > " .. Name(a.to) end
            line = line .. "  " .. LC.Loc("by") .. " " .. Name(a.who)
            if a.why then line = line .. "  (" .. a.why .. ")" end
            L[#L + 1] = line
        end
    end
    L[#L + 1] = "Drop ID: " .. e.id
    return L
end

-- ---- rows of one kind of status ----------------------------------------------------------------
local function ToCell(e, status)
    local t = e.trade
    if status == "traded" then return Name(t.to)
    elseif status == "mismatch" then return Name(t.to) .. Paint(" !", STYLE.danger)
    elseif status == "pending" then return Paint(LC.Loc("Pending"), STYLE.warning)
    elseif status == "expired" then return Paint(LC.Loc("Not traded"), STYLE.danger)
    elseif status == "self" then return Paint(LC.Loc("Kept"), STYLE.text_muted)
    end
    return Paint(LC.Loc("Undone"), STYLE.text_muted)
end

local function ByCell(e, status)
    if status == "traded" or status == "mismatch" then return Name(e.trade.by or e.holder) end
    if status == "pending" or status == "expired" then return Paint(Plain(e.holder), STYLE.text_muted) end
    return ""
end

local function CountsText(c)
    local parts = { Paint(string.format(LC.Loc("%d items"), c.items), STYLE.text_soft or STYLE.text_muted) }
    if c.pending > 0 then parts[#parts + 1] = Paint(string.format(LC.Loc("%d pending"), c.pending), STYLE.warning) end
    if c.issues > 0 then parts[#parts + 1] = Paint(string.format(LC.Loc("%d to check"), c.issues), STYLE.danger) end
    if c.undone > 0 then parts[#parts + 1] = Paint(string.format(LC.Loc("%d undone"), c.undone), STYLE.text_muted) end
    return table.concat(parts, "   ")
end

-- ---- tree state ------------------------------------------------------------------------------------
local function IsOpen(key)
    if filterText ~= "" then return true end              -- a search shows everything it found
    local v = openState[key]
    if v ~= nil then return v end
    local newest = days[1] and days[1].key
    return newest ~= nil and (key == newest or key:sub(1, #newest + 1) == newest .. "|")
end

local function Flatten()
    wipe(flat)
    for _, day in ipairs(days) do
        flat[#flat + 1] = { kind = "day", node = day }
        if IsOpen(day.key) then
            for _, diff in ipairs(day.diffs) do
                flat[#flat + 1] = { kind = "diff", node = diff }
                if IsOpen(diff.key) then
                    for _, boss in ipairs(diff.bosses) do
                        flat[#flat + 1] = { kind = "boss", node = boss }
                        if IsOpen(boss.key) then
                            for _, e in ipairs(boss.items) do flat[#flat + 1] = { kind = "item", e = e, node = boss } end
                        end
                    end
                end
            end
        end
    end
end

local function SetAllOpen(value)
    for _, day in ipairs(days) do
        openState[day.key] = value
        for _, diff in ipairs(day.diffs) do
            openState[diff.key] = value
            for _, boss in ipairs(diff.bosses) do openState[boss.key] = value end
        end
    end
    Flatten()
    HF.Paint()
end

local function EntriesOf(node)
    local out = {}
    if node.items then for _, e in ipairs(node.items) do out[#out + 1] = e end return out end
    for _, child in ipairs(node.diffs or node.bosses or {}) do
        for _, e in ipairs(EntriesOf(child)) do out[#out + 1] = e end
    end
    return out
end

-- ---- menus -----------------------------------------------------------------------------------------
local function ItemMenu(e)
    C.ShowContextMenu({
        { type = "button", label = LC.Loc("Show details"), fnc = function()
            local lines = HF.Details(e)
            for i, line in ipairs(lines) do lines[i] = (line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
            ShowText(LC.Loc("Details"), table.concat(lines, "\n"))
        end },
        { type = "button", label = LC.Loc("Delete entry"), fnc = function()
            deleteTarget = e.id
            C.CreateDialog("NSLCHistoryDelete", LC.Loc("Delete history entry"),
                LC.Loc("Delete this entry from the history? This cannot be undone."), LC.Loc("Delete"),
                function() if deleteTarget then LC.History.Remove(deleteTarget); deleteTarget = nil; HF.Refresh() end end,
                LC.Loc("Cancel"), nil)
        end },
    })
end

local function SectionMenu(node)
    local list = EntriesOf(node)
    C.ShowContextMenu({
        { type = "button", label = LC.Loc("Export this section (CSV)"), fnc = function() ShowText(LC.Loc("CSV export"), LC.History.ToCSV(list, GetServerTime())) end },
        { type = "button", label = LC.Loc("Export this section (JSON)"), fnc = function() ShowText(LC.Loc("JSON export"), LC.History.ToJSON(list, GetServerTime())) end },
    })
end

-- ---- rows ------------------------------------------------------------------------------------------
local function Label(parent, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    SetFont(fs, size or "small")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    fs:SetMaxLines(1)
    return fs
end

local function RowEnter(row)
    C.FadeTo(row.hover, 1, STYLE.hover_in)
end
local function RowLeave(row)
    C.FadeTo(row.hover, 0, STYLE.hover_out)
    NSI.UI.Tooltip.Hide()
end

local function Toggle(node)
    openState[node.key] = not IsOpen(node.key)
    Flatten()
    HF.Paint()
end

local function BuildRow()
    local row = CreateFrame("Button", nil, view)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    C.StyleRow(row, STYLE.row_stripe_dark)
    row.hover = row:CreateTexture(nil, "BACKGROUND", nil, -5)
    row.hover:SetAllPoints()
    STYLE.PaintAccent(row.hover, "SetColorTexture", STYLE.hover_color[4])
    row.hover:SetAlpha(0)
    -- bonus rolls get a faint gold wash over the row stripe (same as the player history flyout)
    row.tint = row:CreateTexture(nil, "ARTWORK", nil, -8)
    row.tint:SetAllPoints()
    row.tint:SetColorTexture(1, 0.82, 0, 0.12)
    row.tint:Hide()

    row.chev = row:CreateTexture(nil, "ARTWORK")
    row.chev:SetSize(12, 12)
    row.chev:SetTexture(ICON_PATH .. "chevron-down.png")
    row.label = Label(row)
    row.counts = Label(row, "small", "RIGHT")
    row.counts:SetPoint("RIGHT", row, "RIGHT", -8, 0)

    row.icon = C.CreateItemButton(row, ROW_H - 4)
    row.icon.frame:EnableMouse(false)
    row.name = Label(row)
    row.who, row.reason = Label(row), Label(row)
    row.to, row.by, row.time = Label(row), Label(row), Label(row, "small", "RIGHT")

    -- the exact item: icon and name share one hover area that shows the real item tooltip
    row.hit = CreateFrame("Button", nil, row)
    row.hit:SetFrameLevel(row:GetFrameLevel() + 3)
    row.hit:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.hit:SetScript("OnEnter", function(h)
        local r = h:GetParent()
        RowEnter(r)
        NSI.UI.Tooltip.Hide()
        if r.desc and r.desc.kind == "item" then
            GameTooltip:SetOwner(h, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(ItemSource(r.desc.e))
            GameTooltip:Show()
        end
    end)
    row.hit:SetScript("OnLeave", function(h) GameTooltip:Hide(); RowLeave(h:GetParent()) end)
    row.hit:SetScript("OnClick", function(h, button)
        local r = h:GetParent()
        if not (r.desc and r.desc.kind == "item") then return end
        if button == "RightButton" then ItemMenu(r.desc.e) return end
        local _, link = ItemInfo(r.desc.e)
        if link and IsModifiedClick("CHATLINK") then HandleModifiedItemClick(link) end
    end)

    row:SetScript("OnEnter", function(r)
        RowEnter(r)
        local d = r.desc
        if d and d.kind == "item" then
            local name = ItemInfo(d.e)
            NSI.UI.Tooltip.Show(r, { title = name or ("Item " .. d.e.itemID), desc = table.concat(HF.Details(d.e), "\n") }, "ANCHOR_BOTTOM")
        end
    end)
    row:SetScript("OnLeave", RowLeave)
    row:SetScript("OnClick", function(r, button)
        local d = r.desc
        if not d then return end
        if d.kind == "item" then
            if button == "RightButton" then ItemMenu(d.e) end
        elseif button == "RightButton" then SectionMenu(d.node)
        else Toggle(d.node) end
    end)
    return row
end

local function LayoutRow(row)
    local function place(fs, left, width)
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", row, "LEFT", left + 4, 0)
        fs:SetWidth(max(10, width - 8))
    end
    place(row.who, x.who, COL.who)
    place(row.reason, x.reason, COL.reason)
    place(row.to, x.to, COL.to)
    place(row.by, x.by, COL.by)
    place(row.time, x.time, COL.time)
    row.icon.frame:ClearAllPoints()
    row.icon.frame:SetPoint("LEFT", row, "LEFT", INDENT.item, 0)
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.icon.frame, "RIGHT", 6, 0)
    row.name:SetWidth(max(10, x.who - INDENT.item - ROW_H - 6))
    row.hit:ClearAllPoints()
    row.hit:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT.item, 0)
    row.hit:SetPoint("BOTTOMRIGHT", row, "BOTTOMLEFT", x.who - 4, 0)
end

local function Header(strip)
    local function title(text, left, width, justify)
        local fs = strip.titles and strip.titles[text] or Label(strip, "small", justify)
        strip.titles = strip.titles or {}
        strip.titles[text] = fs
        fs:SetTextColor(unpack(STYLE.text_soft or STYLE.text_muted))
        fs:SetText(LC.Loc(text))
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", strip, "LEFT", left + 4, 0)
        fs:SetWidth(max(10, width - 8))
    end
    title("Item", INDENT.item, x.who - INDENT.item)
    title("Awarded to", x.who, COL.who)
    title("Reason", x.reason, COL.reason)
    title("Traded to", x.to, COL.to)
    title("From", x.by, COL.by)
    title("Time", x.time, COL.time, "RIGHT")
end

local function Layout()
    local w = view:GetWidth() or 0
    if w <= 0 then w = (frame:GetWidth() or W) - 40 end
    x.time = w - COL.time
    x.by = x.time - COL.by
    x.to = x.by - COL.to
    x.reason = x.to - COL.reason
    x.who = x.reason - COL.who
    for _, row in ipairs(pool) do LayoutRow(row) end
    Header(headStrip)
end

local function MaxOffset() return max(0, #flat * ROW_H - (view:GetHeight() or 0)) end

local function UpdateThumb()
    local vh, total = view:GetHeight() or 0, #flat * ROW_H
    if total <= vh or vh <= 0 then thumb:Hide() return end
    local h = max(20, floor(vh * vh / total + 0.5))
    local y = floor((vh - h) * offset / (total - vh) + 0.5)
    thumb:SetHeight(h)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, -y)
    thumb:Show()
end

local KIND_FILL = { day = { 0.20, 0.20, 0.20, 0.96 }, diff = { 0.15, 0.15, 0.15, 0.96 }, boss = { 0.115, 0.115, 0.115, 0.96 } }

local function PaintRow(row, desc, idx, now)
    row.desc = desc
    local kind = desc.kind
    local fill = KIND_FILL[kind] or (idx % 2 == 1 and STYLE.row_stripe_dark or STYLE.row_stripe_light)
    row.__background:SetVertexColor(fill[1], fill[2], fill[3])
    row.__background:SetAlpha(fill[4] or 1)
    if kind == "item" then
        local e = desc.e
        local status = LC.History.Status(e, now)
        row.chev:Hide(); row.label:Hide(); row.counts:Hide()
        row.tint:SetShown(e.source == "bonus" and status ~= "void")
        local name, _, quality = ItemInfo(e)
        row.icon:SetItem(ItemSource(e))
        row.icon.frame:SetAlpha(status == "void" and 0.45 or 1)
        row.icon.frame:Show()
        local q = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        local text = name or ("Item " .. e.itemID)
        if status == "void" then text = Paint(text, STYLE.text_muted)
        elseif q then text = (q.hex or "|cffffffff") .. text .. "|r" end
        row.name:SetText(text)
        row.who:SetText(status == "void" and Paint(Plain(e.winner), STYLE.text_muted) or ClassName(e, e.winner))
        row.reason:SetText(ReasonText(e))
        row.to:SetText(ToCell(e, status))
        row.by:SetText(ByCell(e, status))
        row.time:SetText(Clock(e.time))
        row.name:Show(); row.who:Show(); row.reason:Show(); row.to:Show(); row.by:Show(); row.time:Show()
        row.hit:Show()
    else
        local node = desc.node
        row.icon.frame:Hide(); row.hit:Hide(); row.tint:Hide()
        row.name:Hide(); row.who:Hide(); row.reason:Hide(); row.to:Hide(); row.by:Hide(); row.time:Hide()
        local left = INDENT[kind]
        row.chev:ClearAllPoints()
        row.chev:SetPoint("LEFT", row, "LEFT", left, 0)
        row.chev:SetRotation(IsOpen(node.key) and 0 or math.pi / 2)      -- the chevron points down; turned a quarter it points right
        row.chev:Show()
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", row, "LEFT", left + 18, 0)
        row.label:SetPoint("RIGHT", row.counts, "LEFT", -10, 0)
        if kind == "day" then
            row.label:SetText(date("%A, %d %B %Y", node.stamp - LC.History.DAY_START_HOUR * 3600))
        elseif kind == "diff" then
            row.label:SetText("|c" .. (DIFF_COLOR[node.difficulty] or "ffffffff") .. DiffName(node.difficulty) .. "|r")
        else
            local kills = (node.killCount or 1) > 1 and string.format(LC.Loc("%d kills"), node.killCount) or (LC.Loc("kill") .. " " .. Clock(node.firstKill))
            row.label:SetText(node.name .. "   " .. Paint(kills, STYLE.text_muted))
        end
        row.counts:SetText(CountsText(node.counts))
        row.label:Show(); row.counts:Show()
    end
    row:Show()
end

function HF.Paint()
    if not frame or not frame:IsShown() then return end
    local vh = view:GetHeight() or 0
    if vh <= 0 then return end
    local need = ceil(vh / ROW_H) + 2
    for i = #pool + 1, need do
        local row = BuildRow()
        LayoutRow(row)
        pool[i] = row
    end
    offset = max(0, min(offset, MaxOffset()))
    local first = floor(offset / ROW_H)
    local shift = offset - first * ROW_H
    local now = GetServerTime()
    for i, row in ipairs(pool) do
        local idx = first + i
        local desc = flat[idx]
        local top = (i - 1) * ROW_H - shift
        if desc and top < vh then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -top)
            row:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, -top)
            PaintRow(row, desc, idx, now)
        else
            row.desc = nil
            row:Hide()
        end
    end
    view.empty:SetShown(#flat == 0)
    UpdateThumb()
end

local function SetOffset(v)
    v = max(0, min(MaxOffset(), v))
    if v == offset then return end
    offset = v
    HF.Paint()
end

-- ---- data --------------------------------------------------------------------------------------------
local function Haystack(e, status)
    local t = e.trade or {}
    return table.concat({ C_Item.GetItemNameByID(e.itemID) or "", Plain(e.winner), ReasonText(e), Plain(t.to), Plain(t.by), Plain(e.holder),
        LC.History.BossName(e.encounterID, e.boss), DiffName(e.difficulty), LC.Loc(STATUS_LABEL[status] or "") }, " "):lower()
end

-- Loot master filter. The history is stored account-wide, so every character sees the awards of every run; this only
-- narrows the list to one character's sessions: what they awarded, plus the bonus rolls made in their session.
-- A bonus roll carries its loot master (lm). Older ones do not, so they borrow the loot master of an award from the
-- same kill.
local ALL = "__all"
local function KillMasters(list)
    local map = {}
    for _, e in ipairs(list) do
        if e.by and e.kill then map[e.kill] = map[e.kill] or e.by end
    end
    return map
end
local function MasterOf(e, killMap)
    if e.source == "bonus" then return e.lm or (e.kill and killMap[e.kill]) end
    return e.by
end

local function MasterItems()
    local seen, keys = {}, {}
    local me = LC.Roster.MyKey()
    local all = LC.History.Query()
    local killMap = KillMasters(all)
    for _, e in ipairs(all) do
        local m = MasterOf(e, killMap)
        if m and not seen[m] then seen[m] = true; keys[#keys + 1] = m end
    end
    if masterFilter and not seen[masterFilter] then keys[#keys + 1] = masterFilter end
    table.sort(keys, function(a, b)
        if (a == me) ~= (b == me) then return a == me end
        return Plain(a):lower() < Plain(b):lower()
    end)
    local function pick(_, _, v)
        masterFilter = (v ~= ALL) and v or nil
        offset = 0
        if masterDrop then masterDrop:Refresh() end
        HF.Refresh()
    end
    local items = { { label = LC.Loc("All characters"), value = ALL, onclick = pick } }
    for _, key in ipairs(keys) do
        items[#items + 1] = { label = Plain(key) .. (key == me and (" " .. LC.Loc("(this character)")) or ""), value = key, onclick = pick }
    end
    return items
end

local function MasterSelected()
    if not masterFilter then return LC.Loc("Loot master: All characters") end
    return LC.Loc("Loot master:") .. " " .. Plain(masterFilter)
end

function HF.Refresh()
    if not frame or not frame:IsShown() then dirty = true return end
    dirty = false
    local now = GetServerTime()
    local needle = filterText:lower()
    local list = {}
    local all = LC.History.Query()
    local killMap = masterFilter and KillMasters(all) or nil
    for _, e in ipairs(all) do
        LC.Roster.NoteClass(e.winner, e.class)
        local status = LC.History.Status(e, now)
        local keep = true
        if status == "void" and not showUndone then keep = false end
        if unresolvedOnly and not (status == "pending" or status == "mismatch" or status == "expired") then keep = false end
        if masterFilter and MasterOf(e, killMap) ~= masterFilter then keep = false end
        if keep and needle ~= "" and not Haystack(e, status):find(needle, 1, true) then keep = false end
        if keep then list[#list + 1] = e end
    end
    days = LC.History.Tree(list, now)
    local total = { items = 0, undone = 0, pending = 0, issues = 0 }
    for _, day in ipairs(days) do
        for k in pairs(total) do total[k] = total[k] + day.counts[k] end
    end
    summary:SetText(CountsText(total))
    Flatten()
    HF.Paint()
end

function HF.RefreshSoon()
    if not frame or not frame:IsShown() then dirty = true return end
    if scheduled then return end
    scheduled = true
    C_Timer.After(0.15, function() scheduled = false; HF.Refresh() end)
end

LC.On("NSRT_LC_HISTORY_CHANGED", function() HF.RefreshSoon() end)

-- Item names and icons that were not cached when a row was drawn arrive later.
local itemEvents = CreateFrame("Frame")
itemEvents:SetScript("OnEvent", function(_, _, itemID)
    if requested[itemID] then requested[itemID] = nil; HF.RefreshSoon() end
end)

-- ---- clear history -----------------------------------------------------------------------------------------
-- Destructive, so it always asks first and says what it will do. The dialog is cached by name; its body is
-- rewritten on every open so the count is current.
local function ClearHistory()
    local n = #LC.History.Query()
    if n == 0 then LC.Print(LC.Loc("The history is already empty.")) return end
    local dlg = C.CreateDialog("NSLCHistoryClear", LC.Loc("Clear history"), "", LC.Loc("Clear history"),
        function()
            local removed = LC.History.Clear()
            LC.Print(string.format(LC.Loc("Cleared %d history entries."), removed))
            HF.Refresh()
        end, LC.Loc("Cancel"), nil)
    if dlg and dlg.bodyFS then
        dlg.bodyFS:SetText(Paint(string.format(LC.Loc("This permanently deletes all %d awards, with their trade records and audit trails."), n), STYLE.text_danger)
            .. "\n\n" .. LC.Loc("It cannot be undone. Other council members keep their own copy. Use Export first if you may need this record."))
    end
end

-- ---- window ---------------------------------------------------------------------------------------------
function HF.Build()
    if frame then return end
    local Shell = LC.Frames.Shell
    frame = Shell.Create({ name = "NSLCHistoryFrame", title = LC.Loc("Loot history"), width = W, height = H, point = { "CENTER", 40, 0 } })

    card = Shell.Card(frame, LC.Loc("Awards"))
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, frame.contentTop - 6)
    card:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, ACT_H + 16)
    local actions = Shell.Card(frame, nil)
    actions:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    actions:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    actions:SetHeight(Shell.CardHeight(actions, 24))

    search = C.CreateSearchBox(card, 240, 22, nil, function(text) filterText = text or ""; offset = 0; HF.Refresh() end,
        LC.Loc("Search..."))
    search.frame:SetPoint("TOPRIGHT", card, "TOPRIGHT", -card.pad, -6)
    summary = card:CreateFontString(nil, "OVERLAY")
    SetFont(summary, "small")
    summary:SetPoint("RIGHT", search.frame, "LEFT", -14, 0)
    masterDrop = C.CreateDropdown(card, nil, MasterItems, MasterSelected, 230, 22)
    masterDrop:SetPoint("RIGHT", summary, "LEFT", -14, 0)

    -- column titles, then the list
    headStrip = CreateFrame("Frame", nil, card.content)
    headStrip:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, 0)
    headStrip:SetPoint("TOPRIGHT", card.content, "TOPRIGHT", 0, 0)
    headStrip:SetHeight(HEAD_H)
    local headBg = headStrip:CreateTexture(nil, "BACKGROUND")
    headBg:SetAllPoints()
    headBg:SetColorTexture(unpack(STYLE.surface_inset))

    view = CreateFrame("Frame", nil, card.content)
    view:SetPoint("TOPLEFT", headStrip, "BOTTOMLEFT", 0, -1)
    view:SetPoint("BOTTOMRIGHT", card.content, "BOTTOMRIGHT", -(SCROLL_W + 2), 0)
    view:SetClipsChildren(true)
    view:EnableMouseWheel(true)
    view.empty = view:CreateFontString(nil, "OVERLAY")
    SetFont(view.empty, "small")
    view.empty:SetTextColor(unpack(STYLE.text_muted))
    view.empty:SetPoint("CENTER")
    view.empty:SetText(LC.Loc("No awards yet."))

    track = card.content:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(unpack(STYLE.surface_inset))
    track:SetWidth(SCROLL_W)
    track:SetPoint("TOPRIGHT", headStrip, "BOTTOMRIGHT", 0, -1)
    track:SetPoint("BOTTOMRIGHT", card.content, "BOTTOMRIGHT", 0, 0)
    thumb = CreateFrame("Button", nil, card.content)
    thumb:SetWidth(SCROLL_W)
    thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
    thumb.tex:SetAllPoints()
    STYLE.PaintAccent(thumb.tex, "SetColorTexture", 0.6)
    thumb:Hide()

    view:SetScript("OnMouseWheel", function(_, delta) SetOffset(offset - delta * WHEEL_ROWS * ROW_H) end)
    local dragY, dragOffset
    thumb:SetScript("OnMouseDown", function(btn)
        dragY, dragOffset = select(2, GetCursorPosition()) / btn:GetEffectiveScale(), offset
        btn:SetScript("OnUpdate", function(b)
            if not IsMouseButtonDown("LeftButton") then b:SetScript("OnUpdate", nil) return end
            local y = select(2, GetCursorPosition()) / b:GetEffectiveScale()
            local vh, total = view:GetHeight() or 0, #flat * ROW_H
            SetOffset(dragOffset + (dragY - y) * (total - vh) / max(1, vh - b:GetHeight()))
        end)
    end)
    thumb:SetScript("OnMouseUp", function(btn) btn:SetScript("OnUpdate", nil) end)
    thumb:SetScript("OnHide", function(btn) btn:SetScript("OnUpdate", nil) end)
    view:SetScript("OnSizeChanged", function() Layout(); HF.Paint() end)

    frame:HookScript("OnShow", function()
        itemEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        if dirty then HF.Refresh() end
    end)
    frame:HookScript("OnHide", function()
        itemEvents:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
        NSI.UI.Tooltip.Hide()
    end)

    -- toolbar
    local left = 0
    local function button(text, width, fn)
        local b = C.CreateButton(actions.content, LC.Loc(text), fn, width, 24)
        b:SetPoint("LEFT", actions.content, "LEFT", left, 0)
        left = left + width + 8
    end
    button("Export", 76, function() ShowText(LC.Loc("Copy this string to share the history."), LC.History.ToString(LC.History.Query())) end)
    button("CSV", 60, function() ShowText(LC.Loc("CSV export"), LC.History.ToCSV(LC.History.Query(), GetServerTime())) end)
    button("JSON", 60, function() ShowText(LC.Loc("JSON export"), LC.History.ToJSON(LC.History.Query(), GetServerTime())) end)
    button("Import", 76, function()
        local box = C.CreateTextBoxDialog("NSLCHistoryImport", LC.Loc("Import history"), { width = 600, height = 260,
            okText = LC.Loc("Import"), cancelText = LC.Loc("Cancel"),
            onOk = function(text, dlg)
                local n, why = LC.History.FromString(text)
                if not n then dlg:SetStatus(LC.Loc(why or "unreadable"), true) return false end
                HF.Refresh()
            end })
        box:Open("", LC.Loc("Paste a history string."))
    end)
    button("Expand all", 96, function() SetAllOpen(true) end)
    button("Collapse all", 96, function() SetAllOpen(false) end)
    local c1 = C.CreateCheckButton(actions.content, LC.Loc("Show undone"), function() return showUndone end,
        function(v) showUndone = v and true or false; HF.Refresh() end, 118, 22)
    c1:SetPoint("LEFT", actions.content, "LEFT", left + 8, 0)
    local c2 = C.CreateCheckButton(actions.content, LC.Loc("Unresolved only"), function() return unresolvedOnly end,
        function(v) unresolvedOnly = v and true or false; HF.Refresh() end, 140, 22)
    c2:SetPoint("LEFT", actions.content, "LEFT", left + 8 + 126, 0)
    -- the destructive one sits alone at the far right, in the danger colour
    local clear = C.CreateButton(actions.content, LC.Loc("Clear history"), ClearHistory, 120, 24)
    clear:SetPoint("RIGHT", actions.content, "RIGHT", 0, 0)
    clear.label:SetTextColor(unpack(STYLE.text_danger))
    Layout()
end

function HF.Open()
    HF.Build()
    LC.Frames.Shell.Reopen(frame)
    Layout()
    HF.Refresh()
end
