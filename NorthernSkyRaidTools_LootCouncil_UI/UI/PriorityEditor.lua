-- ============================================================
--  UI/PriorityEditor.lua - item priority lists (P-1, P-2), kept deliberately simple
--  Pick an item by id, edit its ordered list of names as text (one per line, best first).
--  The list is shown to the council as a hint; it does not decide awards.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
local C = NSI.UI.Components

local PE = {}
LC.UI.PriorityEditor = PE
local box

function PE.Open()
    local ask = C.CreateInputDialog("NSLCPriorityItem", LC.Loc("Item priority"), LC.Loc("Item ID:"), {
        okText = LC.Loc("Edit"), cancelText = LC.Loc("Cancel"),
        onAccept = function(text)
            local itemID = tonumber(text)
            if not itemID then LC.Print(LC.Loc("That is not an item ID.")) return end
            local list = LC.Priority.ListFor(itemID, nil, nil) or {}
            box = box or C.CreateTextBoxDialog("NSLCPriorityList", LC.Loc("Priority list"), { width = 480, height = 320,
                okText = LC.Loc("Save"), cancelText = LC.Loc("Cancel") })
            box:Open(table.concat(list, "\n"), string.format(LC.Loc("One name per line, best first. Item %d."), itemID),
                function(newText)
                    local out = {}
                    for line in tostring(newText):gmatch("[^\n]+") do
                        line = line:gsub("^%s+", ""):gsub("%s+$", "")
                        if line ~= "" then out[#out + 1] = LC.Roster.Key(line) or line end
                    end
                    LC.Priority.SetList(itemID, {}, out)
                end)
        end,
    })
    return ask
end
