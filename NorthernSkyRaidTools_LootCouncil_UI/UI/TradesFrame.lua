-- ============================================================
--  UI/TradesFrame.lua - items you hold that still have to be traded (T-1, T-6)
--  Rows come from LC.Trade.queue. Import accepts a bird-compatible trade string.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
local C = NSI.UI.Components

local TF = {}
LC.UI.TradesFrame = TF
local frame, tbl, importBox
local W, H, ACT_H = 520, 340, 44

local STATE_TEXT = { waiting = "Waiting", placed = "In trade", done = "Done", failed = "Not found" }
-- Trade link colours: green = in range, orange = in range but you are in combat, red = out of range.
local TRADE_HEX = { ready = "ff33ff66", combat = "ffff9933", far = "ffff4040" }
local TRADE_TIP = {
    ready = "Click to open a trade with %s",
    combat = "%s is in range, but you cannot open a trade while in combat",
    far = "%s is out of trade range (or not in your group)",
}

local function ItemLink(q)
    local link = q.item and LC.Items.ToLink(q.item) or LC.Items.ToLink("item:" .. q.itemID)
    if not link and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(q.itemID) end
    return link
end

-- A cell whose hover and clicks still reach the row behind it.
local function Passthrough(f)
    if f.SetPropagateMouseClicks then f:SetPropagateMouseClicks(true) end
    if f.SetPropagateMouseMotion then f:SetPropagateMouseMotion(true) end
end

function TF.Refresh()
    if not frame or not frame:IsShown() then return end
    local rows = {}
    for _, q in ipairs(LC.Trade.queue) do
        -- a finished trade leaves the list (the entry stays in the queue so it is not offered again)
        if q.state ~= "done" then rows[#rows + 1] = { q = q, itemID = q.itemID, diff = q.difficulty } end
    end
    tbl:SetData(rows)
end

-- Click anywhere on a row: try to open the trade. Combat or range blocks it with a chat line saying why.
local function TryTrade(row, button)
    local q = row and row.q
    if not q or (q.state ~= "waiting" and q.state ~= "failed") then return end
    local ok, why = LC.Trade.Open(q)
    if not ok and why then LC.Print(string.format("%s: %s.", LC.Roster.Display(q.player) or tostring(q.player), LC.Loc(why))) end
end

function TF.Build()
    if frame then return end
    frame = LC.Frames.Shell.Create({ name = "NSLCTradesFrame", title = LC.Loc("Trades"), width = W, height = H,
        point = { "CENTER", 0, -40 } })

    local Shell = LC.Frames.Shell
    local card = Shell.Card(frame, LC.Loc("Trade queue"))
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, frame.contentTop - 6)
    card:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, ACT_H + 16)
    local actions = Shell.Card(frame, nil)
    actions:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    actions:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    actions:SetHeight(Shell.CardHeight(actions, 24))
    tbl = C.CreateDataTable(card.content, {
        { key = "itemID", title = "Item", flex = 1, sortValue = function(r) return C_Item.GetItemNameByID(r.itemID) or "" end,
          init = function(cell)
              cell.fs = cell:CreateFontString(nil, "OVERLAY")
              NSI:SetUIFont(cell.fs, "small")
              cell.fs:SetPoint("LEFT", 4, 0)
              cell.fs:SetPoint("RIGHT", -4, 0)
              cell.fs:SetJustifyH("LEFT")
              cell.fs:SetWordWrap(false)
              cell.fs:SetMaxLines(1)
              -- the item's own tooltip on hover
              cell:EnableMouse(true)
              Passthrough(cell)
              cell:SetScript("OnEnter", function(self)
                  local q = self.rowData and self.rowData.q
                  if not q then return end
                  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                  GameTooltip:SetHyperlink(ItemLink(q) or ("item:" .. q.itemID))
                  GameTooltip:Show()
              end)
              cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
          end,
          render = function(cell, d)
              cell.rowData = d
              cell.fs:SetText(ItemLink(d.q) or C_Item.GetItemNameByID(d.itemID) or tostring(d.itemID))
          end },
        -- read from the queue entry on every redraw, so a finished trade shows at once
        { key = "player", title = "To", width = 110, text = function(r) return LC.Roster.Display(r.q.player) or tostring(r.q.player) end },
        { key = "state", title = "Status", width = 80, text = function(r)
            local st = r.q.state
            return LC.Loc(STATE_TEXT[st] or st)
        end },
        { key = "trade", title = "Trade", width = 60, align = "CENTER", sortable = false,
          init = function(cell)
              local b = CreateFrame("Button", nil, cell)
              b:SetAllPoints(cell)
              b.fs = b:CreateFontString(nil, "OVERLAY")
              NSI:SetUIFont(b.fs, "small")
              b.fs:SetPoint("CENTER")
              -- the click itself is handled by the row (TryTrade below); this button only shows the tooltip
              if b.SetPropagateMouseClicks then b:SetPropagateMouseClicks(true) end
              b:SetScript("OnEnter", function(self)
                  if not self.q then return end
                  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                  GameTooltip:AddLine(string.format(LC.Loc(TRADE_TIP[self.tradeState] or TRADE_TIP.far), LC.Roster.Display(self.q.player) or "?"), 1, 1, 1, true)
                  GameTooltip:Show()
              end)
              b:SetScript("OnLeave", function() GameTooltip:Hide() end)
              cell.btn = b
          end,
          render = function(cell, d)
              local b, q = cell.btn, d.q
              -- only entries that still have to be traded get the link
              if q.state == "waiting" or q.state == "failed" then
                  local state = LC.Trade.RangeState(q)
                  b.q, b.tradeState = q, state
                  b.fs:SetText("|c" .. TRADE_HEX[state] .. LC.Loc("Trade") .. "|r")
                  b:Show()
              else
                  b.q = nil
                  b:Hide()
              end
          end },
    }, { emptyText = LC.Loc("Nothing to trade."), selectable = true, onClick = TryTrade })
    tbl.frame:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, 0)
    tbl:SetSize(W - 16 - card.pad * 2, H + frame.contentTop - 6 - (ACT_H + 16) - card.inset - card.pad)

    local imp = C.CreateButton(actions.content, LC.Loc("Import"), function()
        importBox = importBox or C.CreateTextBoxDialog("NSLCTradeImport", LC.Loc("Import trade string"), {
            width = 600, height = 260, okText = LC.Loc("Import"), cancelText = LC.Loc("Cancel"),
            onOk = function(text, dlg)
                local n, errors = LC.Trade.Import(text)
                if #errors > 0 then
                    dlg:SetStatus(string.format(LC.Loc("%d added, %d entries skipped."), n, #errors), true)
                    return false
                end
            end })
        importBox:Open("", LC.Loc("Paste a trade string: itemID/difficulty:Player;"))
    end, 90, 24)
    imp:SetPoint("LEFT", actions.content, "LEFT", 0, 0)

    local clear = C.CreateButton(actions.content, LC.Loc("Clear"), function() LC.Trade.Clear() end, 90, 24)
    clear:SetPoint("LEFT", imp.frame, "RIGHT", 8, 0)

    local retry = C.CreateButton(actions.content, LC.Loc("Retry"), function()
        for _, q in ipairs(LC.Trade.queue) do if q.state == "failed" then q.state = "waiting" end end
        TF.Refresh()
    end, 90, 24)
    retry:SetPoint("LEFT", clear.frame, "RIGHT", 8, 0)
end

-- Range and combat change by the moment: redraw the rows twice a second while the window is open.
local ticker
local function KeepFresh()
    if ticker then return end
    ticker = C_Timer.NewTicker(0.5, function()
        if LC.dead then ticker:Cancel(); ticker = nil return end
        if frame and frame:IsShown() and tbl then TF.Refresh() end
    end)
end

LC.On("NSRT_LC_TRADES_CHANGED", function() TF.Refresh() end)

function TF.Open()
    TF.Build()
    KeepFresh()
    LC.Frames.Shell.Reopen(frame)
    TF.Refresh()
end
