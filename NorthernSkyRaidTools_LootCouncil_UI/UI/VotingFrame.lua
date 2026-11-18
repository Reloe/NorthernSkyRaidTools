-- ============================================================
--  UI/VotingFrame.lua - council window: drops on the left, candidates on the right (V-1..V-5, A-1)
--  Built on first Open(). Candidate rows come from the session state; the table is virtualised.
--  Hover a candidate to see what they have equipped in that slot. Award uses the response the player
--  submitted as the reason; right click offers "Award for..." with every response button as the reason.
--  Council only; non-council clients never load this folder.
-- ============================================================
local ADDON, _ = ...
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
local C = NSI.UI.Components

local VF = {}
LC.UI.VotingFrame = VF
local frame, candTable, selectedDrop, awardBtn, idle
local HEADER_H = 22          -- the DataTable header row (its default headerHeight)
local strip, stripBox = {}, nil
local info = {}
local STRIP_BTN = 40
local STRIP_W = STRIP_BTN + 20          -- item button + native scrollbar
local stripCard, mainCard, actionCard
local ACT_H, WIN_W, WIN_H = 44, 1200, 560   -- action card height; window size
local ICONS = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\]]
local TIER_OF = { bis = "best", major = "major", minor = "minor", offspec = "offspec", xmog = "xmog", pass = "pass" }

local TIER_BTN = 26
local TIER_ICONS_W = 12 + 5 * (TIER_BTN + 3)
local TIER_W = TIER_ICONS_W + 40                   -- icons, then the tier count
local DIFF_HEX = { LFR = "ff1eff00", N = "ff0070dd", H = "ffa335ee", M = "ffff8000" }   -- same colours as the history
local GEAR_W = 16 + 2 * (TIER_BTN + 4)
local function Propagate(f)
    if f.SetPropagateMouseClicks then f:SetPropagateMouseClicks(true) end
    if f.SetPropagateMouseMotion then f:SetPropagateMouseMotion(true) end
end
-- A table cell that shows a tooltip on hover (tip adds the lines, or returns false for none) while clicks
-- and hover still reach the row behind it.
local function HoverCell(cell, tip)
    cell:EnableMouse(true)
    Propagate(cell)
    cell:SetScript("OnEnter", function(self)
        local d = self.rowData
        if not d then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if tip(d) == false then GameTooltip:Hide() return end
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function ResponseText(id)
    local r = id and LC.Ruleset.ResponseById(id)
    local text = r and LC.Loc(r.text) or (id and tostring(id) or "-")
    local tier = id and TIER_OF[id]
    if tier then text = C.ColorText(text, tier) end
    return text
end

-- Everyone who responded, plus everyone in the kill roster who has not: "Waiting" until the response
-- time is up, then "No response". Every row carries what the columns need: class, spec, guild rank, the tier
-- slots, who voted for them and whether I did.
local function Candidates(dropID)
    local state = LC.Session.state
    local out = {}
    if not state then return out end
    local rs = LC.Ruleset.Get()
    local left = rs and LC.Session.TimeLeft(state, rs.timeout, GetServerTime())
    local over = left ~= nil and left <= 0
    local me = LC.Roster.MyKey()
    local drop = state.drops[dropID]
    local tierSlot = drop and LC.Items.TierSlotOfDrop(dropID, drop.item, drop.itemID)
    local voters = {}                     -- candidate -> { voter keys }
    for voter, v in pairs(state.votes[dropID] or {}) do
        if v.c then
            voters[v.c] = voters[v.c] or {}
            table.insert(voters[v.c], voter)
        end
    end
    local dropLink = drop and LC.Items.ToLink(drop.item)
    local dropIlvl = dropLink and LC.Items.ItemLevel(dropLink) or nil
    local snaps = state.snapshots and state.snapshots[dropID] or {}
    -- r = the player's response (nil when they have not answered); the snapshot they sent at session open
    -- fills in the gear, tier and sim columns so a non-responder or a timed-out player is still judged on facts.
    local function Row(key, r)
        local snap = snaps[key]
        local src = r or snap
        local row = {
            key = key, name = LC.Roster.Display(key) or key, class = LC.Roster.ClassOf(key), spec = src and src.spec,
            rank = LC.Roster.GuildRankName(key), rankIndex = LC.Roster.GuildRank(key),
            tg = src and src.tg, tierSlot = tierSlot, note = r and r.note or "", tier = src and src.tier or 0,
            votes = LC.Session.VoteCount(state, dropID, key), voters = voters[key] or {},
        }
        for _, voter in ipairs(row.voters) do if voter == me then row.myVote = true end end
        table.sort(row.voters)
        if src then
            local weakest                       -- an upgrade replaces the weaker of two slots (rings, trinkets)
            for _, g in ipairs(src.gear or {}) do
                if g.ilvl and (not weakest or g.ilvl < weakest) then weakest = g.ilvl end
            end
            row.gear, row.sim = src.gear, src.sim
            row.ilvls = {}
            for _, g in ipairs(src.gear or {}) do if g.ilvl then row.ilvls[#row.ilvls + 1] = g.ilvl end end
            row.equipped = weakest              -- the slot with the biggest gap: what the iLvl and Diff columns use
            local dropLvl = (r and r.ilvl) or dropIlvl
            row.delta = (dropLvl and weakest) and (dropLvl - weakest) or nil
        else
            row.ilvls = {}
        end
        if r then
            row.responseID, row.response = r.response, r.auto and C.ColorText(LC.Loc("Auto pass"), "pass") or ResponseText(r.response)
        else
            row.response = over and C.ColorText(LC.Loc("No response"), "alert") or C.ColorText(LC.Loc("Waiting"), "text_muted")
            row.none = true
        end
        return row
    end
    for key, r in pairs(state.responses[dropID] or {}) do out[#out + 1] = Row(key, r) end
    for key in pairs(state.killRoster or {}) do
        if not (state.responses[dropID] and state.responses[dropID][key]) then out[#out + 1] = Row(key, nil) end
    end
    return out
end

-- ---- hover tooltips for the row cells ---------------------------------------
local function ClassTip(d)
    local class = d.class
    if not class then return false end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local className = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
    local specName = d.spec and select(2, GetSpecializationInfoByID(d.spec))
    local text = specName and (specName .. " " .. className) or className
    if c then GameTooltip:AddLine(text, c.r, c.g, c.b) else GameTooltip:AddLine(text) end
end

local function NoteTip(d)
    if d.note == "" then return false end
    GameTooltip:AddLine(LC.Loc("Note:"), 0, 1, 1)
    GameTooltip:AddLine(d.note, 1, 1, 1, true)
end

local function VotesTip(d)
    if #d.voters == 0 then return false end
    GameTooltip:AddLine(LC.Loc("Voted by"), 0.7, 0.7, 0.7)
    for _, voter in ipairs(d.voters) do GameTooltip:AddLine(LC.Roster.Display(voter) or voter) end
end

-- ---- actions ---------------------------------------------------------------
local function Award(row, reason)
    if not (row and selectedDrop) then return end
    local ok, why = LC.Awards.Award(selectedDrop, row.key, reason)
    if not ok and why then LC.Print(LC.Loc(why)) end
end

local function ReasonItems(row)
    local items = {}
    for _, r in ipairs(LC.Awards.Reasons()) do
        items[#items + 1] = { type = "button", label = LC.Loc(r.text), fnc = function() Award(row, r.id) end }
    end
    return items
end

-- Vote for a candidate; voting for the same one again takes the vote back.
local function Vote(row)
    if not (row and selectedDrop) then return end
    local me = LC.Roster.MyKey()
    local ev = { id = selectedDrop, voter = me, candidate = (not row.myVote) and row.key or nil, seq = LC.Session.NextSeq() }
    LC.Comms.Send("VOTE", ev, "RAID", nil, nil, { a = "c" })
    LC.Session.AddVote(ev, me)
end

local function Menu(row)
    local items = {}
    if LC.Ruleset.IAmML() then
        local awarded = LC.Session.state and selectedDrop and LC.Session.state.awards[selectedDrop]
        items[#items + 1] = { type = "button", label = LC.Loc(awarded and "Reassign" or "Award") .. (row.responseID and (" (" .. row.response .. ")") or ""),
            fnc = function() if row.responseID then Award(row, nil) else C.ShowContextMenu(ReasonItems(row)) end end }
        items[#items + 1] = { type = "submenu", label = LC.Loc("Award for..."), items = ReasonItems(row) }
        items[#items + 1] = { type = "separator" }
    end
    items[#items + 1] = { type = "button", label = LC.Loc("Vote"), fnc = function() Vote(row) end }
    C.ShowContextMenu(items)
end

-- ---- item strip (left) ---------------------------------------------------
local function BuildStripButton(i)
    local item = C.CreateItemButton(stripBox.scrollChild, STRIP_BTN)
    local b = item.frame
    b.item = item
    b:SetPoint("TOPLEFT", stripBox.scrollChild, "TOPLEFT", 0, -(i - 1) * (STRIP_BTN + 4))
    b.sel = b:CreateTexture(nil, "OVERLAY")
    b.sel:SetAllPoints()
    b.sel:SetColorTexture(1, 1, 1, 0.2)
    -- The "awarded" mark lives on its own frame above the icon and its border so nothing covers it.
    local mark = CreateFrame("Frame", nil, b)
    mark:SetAllPoints()
    mark:SetFrameLevel(b:GetFrameLevel() + 10)
    local back = mark:CreateTexture(nil, "ARTWORK")          -- dims the item so the mark reads clearly
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.45)
    local check = mark:CreateTexture(nil, "OVERLAY")
    check:SetPoint("TOPLEFT", 3, -3)                         -- the mark fills the whole item
    check:SetPoint("BOTTOMRIGHT", -3, 3)
    check:SetTexture(ICONS .. "check.png")
    check:SetVertexColor(0.2, 1, 0.4, 1)
    b.done = mark
    b:HookScript("OnClick", function(self) if self.dropID then selectedDrop = self.dropID; VF.Refresh(); LC.UI.PlayerHistory.Refresh() end end)
    -- Not the item tooltip (the header shows the item): what a click does, and whether it is already awarded.
    b:SetScript("OnEnter", function(self)
        if not self.dropID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(string.format(LC.Loc("Click to switch to %s"), self.link or ("item:" .. tostring(self.itemID))), 1, 1, 1)
        if self.awarded then GameTooltip:AddLine(LC.Loc("This item has been awarded"), 1, 1, 1) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function RefreshHeader(state)
    local d = selectedDrop and state and state.drops[selectedDrop]
    info.root:SetShown(d ~= nil)
    if not d then return end
    local link = LC.Items.ToLink(d.item)
    info.item:SetItem(link or d.itemID)
    info.name:SetText(link or C_Item.GetItemNameByID(d.itemID) or tostring(d.itemID))
    local _, itemType, itemSub, equipLoc = C_Item.GetItemInfoInstant(d.itemID)
    local ilvl = link and LC.Items.ItemLevel(link)
    local slot = equipLoc and equipLoc ~= "" and _G[equipLoc] or ""
    -- difficulty first, in its colour, so the awarder sees at a glance which version of the item this is
    local diff = LC.Items.RaidDifficulties[d.difficulty] and d.difficulty or LC.Items.DifficultyFromLink(d.item)
    local short = diff and LC.Items.DifficultyShort[diff]
    local diffText = short and ("|c" .. (DIFF_HEX[short] or "ffffffff") .. LC.Items.DifficultyName[diff] .. "|r") or ""
    info.detail:SetText(table.concat({ diffText, ilvl and ("iLvl: " .. ilvl) or "", slot, itemSub or "", LC.Items.ExtrasText(link or d.item) or "" }, "   "))
    local a = state.awards[selectedDrop]
    local responded, total = 0, 0
    for _ in pairs(state.responses[selectedDrop] or {}) do responded = responded + 1 end
    for _ in pairs(state.killRoster or {}) do total = total + 1 end
    local parts = {}
    parts[#parts + 1] = string.format(LC.Loc("%d of %d responded"), responded, math.max(total, responded))
    if d.holder then parts[#parts + 1] = "|cffffd100" .. LC.Loc("held by") .. "|r " .. (LC.Roster.Display(d.holder) or d.holder) end
    if a then parts[#parts + 1] = "|cff33ff66" .. LC.Loc("awarded to") .. "|r " .. (LC.Roster.Display(a.winner) or a.winner) end
    info.sub:SetText(table.concat(parts, "   "))
end

function VF.Refresh()
    if not frame or not frame:IsShown() then return end
    local state = LC.Session.state
    if idle then
        local live = state and state.guid and not state.closed
        idle:SetShown(not live)
        if not live then
            idle.start.frame:SetShown(LC.Ruleset.IAmML() and true or false)
            idle.sub:SetText(LC.Ruleset.IAmML() and LC.Loc("Start one to put items up for the council.")
                or LC.Loc("Waiting for the loot master to start one."))
        end
    end
    local order = state and state.order or {}
    if state and (not selectedDrop or not state.drops[selectedDrop]) then selectedDrop = order[1] end
    if not state then selectedDrop = nil end
    for i = 1, #order do
        local b = strip[i] or BuildStripButton(i)
        strip[i] = b
        local id = order[i]
        local d = state.drops[id]
        b.dropID, b.itemID, b.link, b.awarded = id, d.itemID, LC.Items.ToLink(d.item), state.awards[id] ~= nil
        b.item:SetItem(LC.Items.ToLink(d.item) or d.itemID)
        b.done:SetShown(state.awards[id] ~= nil)
        b.sel:SetShown(id == selectedDrop)
        b:Show()
    end
    for i = #order + 1, #strip do
        strip[i].dropID = nil
        strip[i]:Hide()
    end
    stripBox.scrollChild:SetHeight(math.max(1, #order * (STRIP_BTN + 4)))
    stripBox:UpdateScrollBar()
    RefreshHeader(state)
    if awardBtn then awardBtn:SetText(LC.Loc(state and selectedDrop and state.awards[selectedDrop] and "Reassign" or "Award")) end
    -- New row tables every refresh: keep the same player selected.
    local prev = candTable:GetSelected()
    local rows = selectedDrop and Candidates(selectedDrop) or {}
    candTable:SetData(rows)
    if prev then
        for _, r in ipairs(rows) do
            if r.key == prev.key then candTable:SetSelected(r) break end
        end
    end
end

function VF.Build()
    if frame then return end
    frame = LC.Frames.Shell.Create({ name = "NSLCVotingFrame", title = LC.Loc("Loot Council"), width = WIN_W, height = WIN_H,
        minWidth = WIN_W, minHeight = WIN_H,               -- never smaller than the starting size; larger up to the screen
        point = { "CENTER", 120, -60 } })
    frame:HookScript("OnShow", function() VF.Refresh() end)

    -- Player loot history: a flyout docked to this window, toggled from a button at the right edge of the title bar
    -- (the close button moves one place left).
    local PH = LC.UI.PlayerHistory
    PH.Build(frame)
    PH.SetDropSource(function() return selectedDrop end)
    do
        local close = frame.Close
        local p, rel, rp, x, y = close:GetPoint(1)
        local tip = { title = "Show player loot history",
            desc = "Shows what the hovered candidate was given in the last 30 days, newest first, with a divider for each week. "
                .. "Starts with the slot of the selected item and includes bonus rolls." }
        local btn = C.CreateButton(frame.TitleBar, "", function() PH.Toggle(); PH.UpdateButton() end, close:GetWidth(), close:GetHeight(),
            nil, ICONS .. "chevron-right.png", nil, tip)
        C.StyleBareIconButton(btn, 16)
        PH.SetButton(btn, tip)
        btn.frame:ClearAllPoints()
        btn.frame:SetPoint(p, rel, rp, x, y)
        close:ClearAllPoints()
        close:SetPoint("RIGHT", btn.frame, "LEFT", -2, 0)
        table.insert(frame.headerButtons, 1, btn.frame)
        frame:HookScript("OnShow", function() PH.UpdateButton() end)   -- the side it docks to is known once the window has a position
    end

    -- Three section cards, like the main window: the drops on the left, the selected drop with its candidates
    -- on the right, and the actions along the bottom.
    local Shell = LC.Frames.Shell
    local top = frame.contentTop - 6
    stripCard = Shell.Card(frame, nil)
    stripCard:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, top)
    stripCard:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, ACT_H + 16)
    stripCard:SetWidth(STRIP_W + stripCard.pad * 2)
    mainCard = Shell.Card(frame, nil)
    mainCard:SetPoint("TOPLEFT", stripCard, "TOPRIGHT", 8, 0)
    mainCard:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, ACT_H + 16)
    actionCard = Shell.Card(frame, nil)
    actionCard:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    actionCard:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    actionCard:SetHeight(Shell.CardHeight(actionCard, 24))
    local body, actions = mainCard.content, actionCard.content

    -- the drops: a scroll box, so any number of items fits
    stripBox = C.CreateScrollBox(stripCard.content, STRIP_W, 100)
    stripBox.frame:ClearAllPoints()
    stripBox.frame:SetPoint("TOPLEFT", stripCard.content, "TOPLEFT", 0, 0)
    stripBox.frame:SetPoint("BOTTOMLEFT", stripCard.content, "BOTTOMLEFT", 0, 0)
    stripBox.frame:SetWidth(STRIP_W)

    -- selected item header
    info.root = CreateFrame("Frame", nil, body)
    info.root:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    info.root:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    info.root:SetHeight(52)
    info.item = C.CreateItemButton(info.root, 48)
    info.item.frame:SetPoint("TOPLEFT", 0, 0)
    info.name = info.root:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(info.name, 15)
    info.name:SetPoint("TOPLEFT", info.root, "TOPLEFT", 58, -2)
    info.name:SetJustifyH("LEFT")
    info.detail = info.root:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(info.detail, "small")
    info.detail:SetTextColor(0.7, 0.85, 1)
    info.detail:SetPoint("TOPLEFT", info.name, "BOTTOMLEFT", 0, -4)
    info.sub = info.root:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(info.sub, "small")
    info.sub:SetTextColor(0.65, 0.65, 0.65)
    info.sub:SetPoint("TOPLEFT", info.detail, "BOTTOMLEFT", 0, -4)

    candTable = C.CreateDataTable(body, {
        { key = "class", title = " ", width = 44, sortValue = function(r) return r.class or "~" end,
          init = function(cell)
              cell.icon = cell:CreateTexture(nil, "ARTWORK")
              cell.icon:SetSize(20, 20)
              cell.icon:SetPoint("CENTER")
              HoverCell(cell, ClassTip)
          end,
          render = function(cell, d)
              cell.rowData = d
              if d.class then cell.icon:SetAtlas("classicon-" .. d.class:lower()) else cell.icon:SetTexture(nil) end
          end },
        { key = "name", title = "Name", flex = 1, sortValue = function(r) return (r.key or ""):lower() end },
        { key = "rank", title = "Rank", width = 100, sortValue = function(r) return r.rankIndex or 99 end,
          text = function(r) return r.rank or "-" end },
        { key = "response", title = "Response", width = 130, sortValue = function(r) return r.responseID or "~" end },
        { key = "gearicons", title = "Equipped", width = GEAR_W, sortable = false,
          init = function(cell)
              cell.gear = {}
              for i = 1, 2 do
                  local ib = C.CreateItemButton(cell, TIER_BTN)
                  ib.frame:SetPoint("LEFT", cell, "LEFT", 8 + (i - 1) * (TIER_BTN + 4), 0)
                  cell.gear[i] = ib
              end
          end,
          render = function(cell, d)
              for i = 1, 2 do
                  local g = d.gear and d.gear[i]
                  local ib = cell.gear[i]
                  if g then ib:SetItem(g.item, g.ilvl); ib.frame:Show() else ib:Clear(); ib.frame:Hide() end
              end
          end },
        { key = "equipped", title = "iLvl", width = 60, align = "CENTER", sortValue = function(r) return r.equipped or 0 end,
          text = function(r) return r.equipped and tostring(r.equipped) or "-" end },
        { key = "delta", title = "Diff", width = 56, align = "RIGHT", text = function(r)
            if not r.delta then return "-" end
            local c = r.delta > 0 and "best" or (r.delta < 0 and "alert" or "text_muted")
            return C.ColorText((r.delta > 0 and "+" or "") .. r.delta, c)
        end, sortValue = function(r) return r.delta or -999 end },
        { key = "tiers", title = "Tier", width = TIER_W, sortable = false,
          init = function(cell)
              cell.slots = {}
              for i = 1, #LC.Items.TierSlots do
                  local ib = C.CreateItemButton(cell, TIER_BTN)
                  ib.frame:SetPoint("LEFT", cell, "LEFT", 8 + (i - 1) * (TIER_BTN + 3), 0)
                  ib.frame.ilvl:Hide()
                  -- the difficulty letters cover the whole item
                  ib.frame.diff = ib.frame:CreateFontString(nil, "OVERLAY")
                  NSI:SetUIFont(ib.frame.diff, 24, "OUTLINE")
                  ib.frame.diff.size = 24
                  ib.frame.diff:SetAllPoints(ib.frame)
                  ib.frame.diff:SetJustifyH("CENTER")
                  ib.frame.diff:SetJustifyV("MIDDLE")
                  cell.slots[i] = ib
              end
              cell.count = cell:CreateFontString(nil, "OVERLAY")
              NSI:SetUIFont(cell.count, "small")
              cell.count:SetPoint("LEFT", cell, "LEFT", TIER_ICONS_W + 4, 0)
          end,
          render = function(cell, d)
              local count = 0
              for i, t in ipairs(LC.Items.TierSlots) do
                  local ib = cell.slots[i]
                  local item = d.tg and d.tg[t.key]
                  local rolled = d.tierSlot == t.key or d.tierSlot == "ANY"
                  local isTier = item and LC.Items.IsTier(item)
                  if item then
                      ib:SetItem(item)
                      ib.frame:SetAlpha(1)
                  else
                      ib:Clear()
                      ib.frame:SetAlpha(0.35)
                  end
                  -- tier pieces in colour with their difficulty over them; anything else greyed out
                  ib.frame.icon:SetDesaturated(item ~= nil and not isTier)
                  local label = isTier and LC.Items.DifficultyLabel(item)
                  -- one letter fills the icon; "LFR" is three letters, so it gets a smaller size to still fit
                  local size = (label == "LFR") and 14 or 24
                  if ib.frame.diff.size ~= size then
                      ib.frame.diff.size = size
                      NSI:SetUIFont(ib.frame.diff, size, "OUTLINE")
                  end
                  ib.frame.diff:SetText(label and ("|c" .. (DIFF_HEX[label] or "ffffffff") .. label .. "|r") or "")
                  if isTier then count = count + 1 end
                  ib.frame.ilvl:SetText("")
                  if rolled then ib.frame.border:SetBorderColor(0, 1, 1, 1)         -- the slot this drop is for
                  elseif not item then ib.frame.border:SetBorderColor(0.25, 0.25, 0.25, 1) end
                  ib.frame:Show()
              end
              cell.count:SetText(string.format("%s%d/%d|r", count >= 4 and "|cff1eff00" or "|cffffffff", count, #LC.Items.TierSlots))
          end },
        { key = "hasnote", title = "Note", width = 56, align = "CENTER", sortValue = function(r) return r.note ~= "" and 1 or 0 end,
          init = function(cell)
              cell.icon = cell:CreateTexture(nil, "ARTWORK")
              cell.icon:SetSize(16, 16)
              cell.icon:SetPoint("CENTER")
              cell.icon:SetTexture(ICONS .. "notebook-pen.png")
              cell.icon:SetVertexColor(0, 1, 1, 1)
              HoverCell(cell, NoteTip)
          end,
          render = function(cell, d)
              cell.rowData = d
              cell.icon:SetShown(d.note ~= "")
          end },
        { key = "sim", title = "Sim %", width = 64, align = "RIGHT", text = function(r) return r.sim and string.format("%.1f", r.sim) or "-" end,
          sortValue = function(r) return r.sim or -1 end },
        { key = "votes", title = "Votes", width = 64, align = "CENTER",
          init = function(cell)
              cell.fs = cell:CreateFontString(nil, "OVERLAY")
              NSI:SetUIFont(cell.fs, "small")
              cell.fs:SetPoint("CENTER")
              HoverCell(cell, VotesTip)
          end,
          render = function(cell, d)
              cell.rowData = d
              cell.fs:SetText(tostring(d.votes))
          end },
        { key = "vote", title = " ", width = 92, sortable = false,
          init = function(cell)
              cell.btn = C.CreateButton(cell, LC.Loc("Vote"), function()
                  if cell.rowData then Vote(cell.rowData) end
              end, 64, 20)
              cell.btn:SetPoint("CENTER", cell, "CENTER", -6, 0)
          end,
          render = function(cell, d)
              cell.rowData = d
              cell.btn.frame:SetShown(true)           -- council members can vote before a player has responded
              cell.btn:SetText(LC.Loc(d.myVote and "Voted" or "Vote"))
          end },
    }, { onContext = Menu, rowHeight = 34,
         onEnter = function(d) LC.UI.PlayerHistory.SetPlayer(d.key) end,
         onSelect = function(d) LC.UI.PlayerHistory.SetPlayer(d.key) end,
         -- the player the selected item was awarded to: a quiet green row
         getRowColor = function(r)
             local st = LC.Session.state
             local a = st and selectedDrop and st.awards[selectedDrop]
             if a and a.winner == r.key then return { 0.10, 0.34, 0.17, 1 } end
         end,
         defaultSort = { key = "votes", asc = false } })
    candTable.frame:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -60)
    -- window width - strip card - gaps - card padding; window height - title, header, action card
    -- anchored on both sides, so the table (and its scroll bar) follows every resize of the window
    candTable.frame:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -12, 0)

    -- An accent border around the rows and scroll bar, starting just below the column headers.
    local listBorder = NSI.UI.Pixel.CreateBoxFrame("Frame", nil, body)
    listBorder:SetPoint("TOPLEFT", candTable.frame, "TOPLEFT", -4, -HEADER_H)
    listBorder:SetPoint("BOTTOMRIGHT", candTable.frame, "BOTTOMRIGHT", 4, -4)
    listBorder:SetFrameLevel(math.max(0, body:GetFrameLevel()))
    listBorder:SetBackdrop({ edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    C.STYLE.PaintAccent(listBorder, "SetBackdropBorderColor", 1)
    listBorder:EnableMouse(false)

    local award = C.CreateButton(actions, LC.Loc("Award"), function()
        local row = candTable:GetSelected()
        if not row then return end
        if row.responseID then Award(row, nil) else C.ShowContextMenu(ReasonItems(row)) end
    end, 90, 24, nil, nil, nil, nil, nil, function() return LC.Ruleset.IAmML() end)
    award:SetPoint("LEFT", actions, "LEFT", 0, 0)
    awardBtn = award

    local hist = C.CreateButton(actions, LC.Loc("History"), function() LC.UI.HistoryFrame.Open() end, 80, 24)
    hist:SetPoint("LEFT", award.frame, "RIGHT", 8, 0)

    local close = C.CreateButton(actions, LC.Loc("End session"), function() LC.Session.RequestClose() end, 110, 24,
        nil, nil, nil, nil, nil, function() return LC.Session.CanClose() end)
    close:SetPoint("RIGHT", actions, "RIGHT", 0, 0)

    -- the response timer decides Waiting vs No response: re-evaluate while open
    local acc, wasOver = 0, false
    frame:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 1 then return end
        acc = 0
        local rs, state = LC.Ruleset.Get(), LC.Session.state
        local left = rs and state and LC.Session.TimeLeft(state, rs.timeout, GetServerTime())
        local over = left ~= nil and left <= 0
        if over ~= wasOver then wasOver = over; VF.Refresh() end
    end)

    -- No session: a dim cover over everything under the title bar (WoW has no real blur), with a way to
    -- start an impromptu session. It eats the mouse so nothing underneath can be clicked.
    local STYLE = NSI.UI.Style
    idle = CreateFrame("Frame", nil, frame)
    idle:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, frame.contentTop)
    idle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    idle:SetFrameLevel(frame:GetFrameLevel() + 50)
    idle:EnableMouse(true)
    local fill = idle:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    local pr, pg, pb = unpack(STYLE.surface_panel)
    fill:SetColorTexture(pr, pg, pb, 0.93)
    idle.msg = idle:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    idle.msg:SetPoint("CENTER", idle, "CENTER", 0, 34)
    idle.msg:SetText(LC.Loc("No session in progress."))
    STYLE.PaintAccent(idle.msg, "SetTextColor", 1)
    idle.sub = idle:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    idle.sub:SetPoint("TOP", idle.msg, "BOTTOM", 0, -8)
    idle.sub:SetTextColor(0.7, 0.7, 0.7, 1)
    idle.start = C.CreateButton(idle, LC.Loc("Start a session"), function()
        LC.Frames.SetupFrame.Open(true)
    end, 170, 30)
    idle.start.frame:SetPoint("TOP", idle.sub, "BOTTOM", 0, -16)
    idle:Hide()
end

-- Open on purpose (the Council button, /ns lc loot).
function VF.Open()
    VF.Build()
    if not frame then return end
    LC.Frames.Shell.Reopen(frame)
    VF.Refresh()
end

-- Hide the council window because the session was ended (not dismissed by the user, so the next session shows it again).
function VF.Close()
    if frame then LC.Frames.Shell.Hide(frame) end
end

LC.On("NSRT_LC_SESSION_CLOSED", function() VF.Refresh() end)
