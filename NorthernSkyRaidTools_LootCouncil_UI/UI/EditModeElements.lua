-- ============================================================
--  UI/EditModeElements.lua - lets the layout editor move the loot council windows
--  Registers only when the NSRT UI addon's EditMode exists. Positions are stored in the
--  module's own settings (lootFramePos). The window is a plain frame; the editor re-anchors it.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
local EM = NSI.UI and NSI.UI.EditMode

function LC.UI.RegisterEditMode()
    if not EM or not EM.Register or LC.UI.editModeRegistered then return end
    local frame = _G.NSLCLootFrame
    if not frame then return end
    LC.UI.editModeRegistered = true
    EM.Register({
        key = "NSLCLootFrame", label = LC.Loc("Loot Council Window"), group = "Other Displays", frame = frame,
        getPos = function()
            local p = LC.DB.Settings().lootFramePos
            if p then return p[1], p[2], p[3], p[4] end
            return "CENTER", "CENTER", 0, 150
        end,
        setPos = function(point, rel, x, y)
            LC.DB.Settings().lootFramePos = { point, rel, x, y }
            frame:ClearAllPoints()
            frame:SetPoint(point, UIParent, rel, x, y)
        end,
    })
end
