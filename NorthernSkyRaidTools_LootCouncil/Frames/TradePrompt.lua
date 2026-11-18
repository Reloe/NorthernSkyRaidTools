-- ============================================================
--  Frames/TradePrompt.lua - tells a holder who to trade what (T-5)
--  A one-line prompt when an award names you as holder: "Trade <item> to <player>". The addon
--  places the item when the trade window opens; the holder clicks Accept (needs a hardware event).
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Prompt = {}
LC.Frames.TradePrompt = Prompt
local frame, text

function Prompt.Build()
    if frame or not (NSI.UI and NSI.UI.Window) then return end
    frame = LC.Frames.Shell.Create({ name = "NSLCTradePrompt", title = LC.Loc("Loot Trade"), width = 340, height = 90,
        point = { "TOP", 0, -130 } })
    local card = LC.Frames.Shell.Card(frame, nil)
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, frame.contentTop - 6)
    card:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    card:SetHeight(LC.Frames.Shell.CardHeight(card, 16))
    frame:SetHeight(-frame.contentTop + 6 + card:GetHeight() + 8)
    text = card.content:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(text, 12)
    text:SetPoint("LEFT", card.content, "LEFT", 0, 0)
    text:SetPoint("RIGHT", card.content, "RIGHT", 0, 0)
    text:SetJustifyH("LEFT")
end

function Prompt.Refresh()
    if not frame or LC.dead then return end
    local nextQ
    for _, q in ipairs(LC.Trade.queue) do
        if q.state == "waiting" then nextQ = q break end
    end
    if not nextQ then LC.Frames.Shell.Hide(frame) return end
    local name = C_Item.GetItemNameByID(nextQ.itemID) or tostring(nextQ.itemID)
    text:SetText(string.format(LC.Loc("Trade %s to %s"), name, LC.Roster.Display(nextQ.player) or nextQ.player))
    frame:SetWidth(math.max(280, text:GetStringWidth() + 56))
    LC.Frames.Shell.Show(frame)
end

LC.On("NSRT_LC_TRADES_CHANGED", function() if frame then frame.dismissed = false end Prompt.Refresh() end)
LC.On("NSRT_LC_ENCOUNTER", function(starting) if starting and frame then LC.Frames.Shell.Hide(frame) else Prompt.Refresh() end end)
function Prompt.Shutdown() if frame then LC.Frames.Shell.Hide(frame) end end
LC.RegisterShutdown("TradePrompt", Prompt.Shutdown)
