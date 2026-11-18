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

function TF.Refresh()
    if not frame or not frame:IsShown() then return end
    local rows = {}
    for _, q in ipairs(LC.Trade.queue) do
        rows[#rows + 1] = { q = q, itemID = q.itemID, player = LC.Roster.Display(q.player) or q.player, state = LC.Loc(STATE_TEXT[q.state] or q.state),
            diff = q.difficulty }
    end
    tbl:SetData(rows)
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
        { key = "itemID", title = "Item", flex = 1, text = function(r)
            local n = C_Item.GetItemNameByID(r.itemID); return n or tostring(r.itemID) end },
        { key = "player", title = "To", width = 130 },
        { key = "state", title = "Status", width = 90 },
    }, { emptyText = LC.Loc("Nothing to trade."), selectable = true })
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

function TF.Open()
    TF.Build()
    LC.Frames.Shell.Reopen(frame)
    TF.Refresh()
end
