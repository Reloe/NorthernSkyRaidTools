-- Marks the UI folder as loaded and exposes the single entry point the logic folder calls.
local NSI = _G.NorthernSkyRaidTools
local LC = NSI.LootCouncil
LC.UI.Open = function() LC.UI.VotingFrame.Open() end
LC.UI.Loaded = true
for _, ev in ipairs({ "NSRT_LC_SESSION_UPDATED", "NSRT_LC_SESSION_OPENED" }) do
    LC.On(ev, function() LC.UI.VotingFrame.Refresh() end)
end
LC.On("NSRT_LC_SESSION_OPENED", function()
    if LC.Ruleset.IAmCouncil() or LC.Ruleset.IAmML() then LC.UI.VotingFrame.Open() end
end)
LC.UI.RegisterEditMode()
