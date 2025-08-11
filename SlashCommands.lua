local _, NSI = ... -- Internal namespace

SLASH_NSUI1 = "/ns"
SlashCmdList["NSUI"] = function(msg)
    if msg == "anchor" then
        if NSI.NSUI.externals_anchor:IsShown() then
            NSI.NSUI.externals_anchor:Hide()
        else
            NSI.NSUI.externals_anchor:Show()
        end
    elseif msg == "test" then
        NSI:DisplayExternal(nil, GetUnitName("player"))
    elseif msg == "wipe" then
        wipe(NSRT)
        ReloadUI()
    elseif msg == "sync" then
        NSI:NickNamesSyncPopup(GetUnitName("player"), "yayayaya")
    elseif msg == "display" then
        NSAPI:DisplayText("Display text", 8)
    elseif msg == "debug" then
        if NSRT.Settings["Debug"] then
            NSRT.Settings["Debug"] = false
            print("|cFF00FFFFNSRT|r Debug mode is now disabled")
        else
            NSRT.Settings["Debug"] = true
            print("|cFF00FFFFNSRT|r Debug mode is now enabled, please disable it when you are done testing.")
        end
    elseif msg == "cd" then
        if NSI.NSUI.cooldowns_frame:IsShown() then
            NSI.NSUI.cooldowns_frame:Hide()
        else
            NSI.NSUI.cooldowns_frame:Show()
        end
    else
        NSI.NSUI:ToggleOptions()
    end
end