-- ============================================================
--  Frames/LeadPrompt.lua - the one prompt a new raid leader sees (D-13)
--  Uses the kit dialog (never StaticPopup). Built lazily on first show.
-- ============================================================
local ADDON, LC = ...
local NSI = LC.NSI
local Prompt = {}
LC.Frames.LeadPrompt = Prompt

function Prompt.Show(onYes, onNo)
    local C = NSI.UI and NSI.UI.Components
    if not (C and C.CreateDialog) then return end
    local f = C.CreateDialog("NSLCLeadPrompt", LC.Loc("Loot Council"),
        LC.Loc("You are now the raid leader. Use the loot council for this raid?"),
        LC.Loc("Yes"), onYes, LC.Loc("No"), onNo)
    -- The dialog caches its buttons' callbacks on first creation; keep the latest ones.
    Prompt.onYes, Prompt.onNo = onYes, onNo
    return f
end
