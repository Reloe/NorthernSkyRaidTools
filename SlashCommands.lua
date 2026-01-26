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
        NSRT.ReminderSettings.ShowReminderFrame = not NSRT.ReminderSettings.ShowReminderFrame
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(false)
    elseif msg == "pnote" or msg == "pn" then
        NSRT.ReminderSettings.ShowPersonalReminderFrame = not NSRT.ReminderSettings.ShowPersonalReminderFrame
        NSI:ProcessReminder()
        NSI:UpdateReminderFrame(true)
    elseif msg == "clear" or msg == "c" then
        NSRT.ActiveReminder = nil
        NSI.Reminder = ""
        NSI:ProcessReminder()

        NSI:UpdateReminderFrame(false, true)
    elseif msg == "timeline" or msg == "tl"then
        NSI:ToggleTimelineWindow()
    elseif msg == "help" then
        print("|cFF00FFFFNSRT|r Available commands:")
        print("  |cFFFFFF00/ns anchor|r - Toggle externals anchor visibility")
        print("  |cFFFFFF00/ns test|r - Display external test")
        print("  |cFFFFFF00/ns wipe|r - Wipe NSRT settings and reload UI")
        print("  |cFFFFFF00/ns sync|r - Show nickname sync popup (test)")
        print("  |cFFFFFF00/ns display|r - Display test text")
        print("  |cFFFFFF00/ns debug|r - Toggle debug mode")
        print("  |cFFFFFF00/ns cd|r - Toggle cooldowns frame")
        print("  |cFFFFFF00/ns reminders|r or |cFFFFFF00/ns r|r - Toggle reminders frame")
        print("  |cFFFFFF00/ns preminders|r or |cFFFFFF00/ns pr|r - Toggle personal reminders frame")
        print("  |cFFFFFF00/ns note|r or |cFFFFFF00/ns n|r - Toggle reminder frame display")
        print("  |cFFFFFF00/ns pnote|r or |cFFFFFF00/ns pn|r - Toggle personal reminder frame display")
        print("  |cFFFFFF00/ns clear|r or |cFFFFFF00/ns c|r - Clear active reminder")
        print("  |cFFFFFF00/ns timeline|r or |cFFFFFF00/ns tl|r - Toggle timeline window")
        print("  |cFFFFFF00/ns help|r or |cFFFFFF00/ns h|r - Show this help message")
        print("  |cFFFFFF00/ns|r (no command) - Toggle options window")
    else
        NSI.NSUI:ToggleOptions()
    end
end
