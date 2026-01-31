local _, NSI = ... -- Internal namespace

SLASH_NSUI1 = "/ns"
SLASH_NSUI2 = "/nsrt"
SlashCmdList["NSUI"] = function(msg)
    if msg == "wipe" then
        wipe(NSRT)
        ReloadUI()
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
        NSRT.ActiveReminder = nil
        NSI.Reminder = ""
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(true)
    elseif msg == "pclear" or msg == "pc" then -- Clear Active Personal Reminder
        NSRT.ActivePersonalReminder = nil
        NSI.PersonalReminder = ""
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(true)
    elseif msg == "timeline" or msg == "tl" then
        NSI:ToggleTimelineWindow()
    elseif msg == "help" then
        print("|cFF00FFFFNSRT|r Available commands: (either '/ns' or '/nsrt' work)\n")
        print("  |cFF00FFFF/ns debug|r - Toggle debug mode - mainly used for development")
        print("  |cFF00FFFF/ns wipe|r - Wipe ALL NSRT settings and reload UI")
        print("  |cFF00FFFF/ns cd|r - Toggle cooldowns frame")
        print("  |cFF00FFFF/ns clear|r or |cFF00FFFF/ns c|r - Clear active reminder")
        print("  |cFF00FFFF/ns pclear|r or |cFF00FFFF/ns pc|r - Clear active personal reminder")
        print("  |cFF00FFFF/ns reminders|r or |cFF00FFFF/ns r|r - Shortcut to shared reminders list")
        print("  |cFF00FFFF/ns preminders|r or |cFF00FFFF/ns pr|r - Shortcut to personal reminders list")
        print("  |cFF00FFFF/ns note|r or |cFF00FFFF/ns n|r - Toggle all notes (all reminders, personal reminders, and text note)")
        print("  |cFF00FFFF/ns anote|r or |cFF00FFFF/ns an|r or |cFF00FFFF/ns snote|r or |cFF00FFFF/ns sn|r - Toggle shared reminders note")
        print("  |cFF00FFFF/ns pnote|r or |cFF00FFFF/ns pn|r - Toggle personal reminders note")
        print("  |cFF00FFFF/ns tnote|r or |cFF00FFFF/ns tn|r - Toggle text note")
        print("  |cFF00FFFF/ns timeline|r or |cFF00FFFF/ns tl|r - Toggle timeline window")
    elseif msg == "" then
        NSI.NSUI:ToggleOptions()
    elseif msg then
        print("|cFF00FFFFNSRT|r Unknown command. Type |cFF00FFFF/ns help|r for a list of commands.")
    else
        NSI.NSUI:ToggleOptions()
    end
end
