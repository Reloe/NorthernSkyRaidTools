local _, NSI = ... -- Internal namespace

SLASH_NSUI1 = "/ns"
SLASH_NSUI2 = "/nsrt"
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
        NSI:DisplayText("Display text", 8)
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
    elseif msg == "reminders" or msg == "r" then
        if not NSUI.reminders_frame:IsShown() then
            NSUI.reminders_frame:Show()
        else
            NSUI.reminders_frame:Hide()
        end
    elseif msg == "preminders" or msg == "pr" then
        if not NSUI.personal_reminders_frame:IsShown() then
            NSUI.personal_reminders_frame:Show()
        else
            NSUI.personal_reminders_frame:Hide()
        end
    elseif msg == "note" or msg == "n" then
        -- Toggle every note's frame

        -- If they are out of sync, hide any that are visible to sync the frames first.
        local visibility = not (NSRT.ReminderSettings.ShowReminderFrame or
                                NSRT.ReminderSettings.ShowPersonalReminderFrame or
                                NSRT.ReminderSettings.ShowExtraReminderFrame)

        NSRT.ReminderSettings.ShowReminderFrame = visibility
        NSRT.ReminderSettings.ShowPersonalReminderFrame = visibility
        NSRT.ReminderSettings.ShowExtraReminderFrame = visibility
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(true, true, true)
    elseif msg == "rnote" or msg == "rn" or msg == "anote" or msg == "an" then
        -- Toggle the "Reminders Note" or "All Note"
        NSRT.ReminderSettings.ShowReminderFrame = not NSRT.ReminderSettings.ShowReminderFrame
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(false, true, false)
    elseif msg == "pnote" or msg == "pn" then
        -- Toggle the "Personal Note"
        NSRT.ReminderSettings.ShowPersonalReminderFrame = not NSRT.ReminderSettings.ShowPersonalReminderFrame
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(true, false, false)
    elseif msg == "tnote" or msg == "tn" or msg == "enote" or msg == "en" then
        -- Toggle the "Text Note" or "Extra Note"
        NSRT.ReminderSettings.ShowExtraReminderFrame = not NSRT.ReminderSettings.ShowExtraReminderFrame
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(false, false, true)
    else
        NSI.NSUI:ToggleOptions()
    end
end