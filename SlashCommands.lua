local _, NSI = ... -- Internal namespace
local L = NSI.L

SLASH_NSUI1 = "/ns"
SLASH_NSUI2 = "/nsrt"
SlashCmdList["NSUI"] = function(msg)
    if msg == "wipe" then
        wipe(NSRT)
        ReloadUI()
    elseif msg == "debug" then
        if NSRT.Settings["Debug"] then
            NSRT.Settings["Debug"] = false
            print(L["SLASH_DEBUG_DISABLED"])
        else
            NSRT.Settings["Debug"] = true
            print(L["SLASH_DEBUG_ENABLED"])
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
    elseif msg == "note" or msg == "n" then -- Toggle Showing/Hiding ALL Notes
        local ShouldShow = not (NSRT.ReminderSettings.ReminderFrame.enabled or NSRT.ReminderSettings.PersonalReminderFrame.enabled or NSRT.ReminderSettings.ExtraReminderFrame.enabled)
        NSRT.ReminderSettings.ReminderFrame.enabled = ShouldShow
        NSRT.ReminderSettings.PersonalReminderFrame.enabled = ShouldShow
        NSRT.ReminderSettings.ExtraReminderFrame.enabled = ShouldShow
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(true)
    elseif msg == "anote" or msg == "an" or msg == "snote" or msg == "sn" then -- Toggle the "All Reminders Note"
        NSRT.ReminderSettings.ReminderFrame.enabled = not NSRT.ReminderSettings.ReminderFrame.enabled
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(false, true)
    elseif msg == "pnote" or msg == "pn" then -- Toggle the "Personal Reminders Note"
        NSRT.ReminderSettings.PersonalReminderFrame.enabled = not NSRT.ReminderSettings.PersonalReminderFrame.enabled
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(false, false, true)
    elseif msg == "tnote" or msg == "tn" then -- Toggle the "Text Note"
        NSRT.ReminderSettings.ExtraReminderFrame.enabled = not NSRT.ReminderSettings.ExtraReminderFrame.enabled
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(false, false, false, true)
    elseif msg == "clear" or msg == "c" then -- Clear Active Reminder
        NSI:SetReminder(nil)
        NSI:Broadcast("NSI_REM_SHARE", "RAID", " ", nil, true)
    elseif msg == "pclear" or msg == "pc" then -- Clear Active Personal Reminder
        NSI:SetReminder(nil, true)
    elseif msg == "timeline" or msg == "tl" then
        NSI:ToggleTimelineWindow()
    elseif msg == "invite" then
        NSI:InviteFromReminder(NSRT.ActiveReminder, true)
    elseif msg == "arrange" then
        NSI:ArrangeFromReminder(NSRT.ActiveReminder, true)
    elseif msg == "help" then
        print(L["SLASH_HELP_TITLE"])
        print(L["SLASH_HELP_1"])
        print(L["SLASH_HELP_2"])
        print(L["SLASH_HELP_3"])
        print(L["SLASH_HELP_4"])
        print(L["SLASH_HELP_5"])
        print(L["SLASH_HELP_6"])
        print(L["SLASH_HELP_7"])
        print(L["SLASH_HELP_8"])
        print(L["SLASH_HELP_9"])
        print(L["SLASH_HELP_10"])
        print(L["SLASH_HELP_11"])
        print(L["SLASH_HELP_12"])
        print(L["SLASH_HELP_13"])
        print(L["SLASH_HELP_14"])
    elseif msg == "" then
        NSI.NSUI:ToggleOptions()
    elseif msg then
        print(L["SLASH_UNKNOWN"])
    else
        NSI.NSUI:ToggleOptions()
    end
end