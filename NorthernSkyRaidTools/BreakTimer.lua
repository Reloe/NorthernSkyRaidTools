local _, NSI = ... -- Internal namespace

-- Raid break timer, started with "/ns break <minutes>". The raid leader (or an
-- assistant) broadcasts the break over the usual addon comms, everyone running
-- NSRT gets the same bar and the same countdown announcements. Same idea as the
-- BigWigs/DBM break timers.

local MAX_BREAK_MINUTES = 120

-- Remaining time (in seconds) at which the break gets announced in chat.
local ANNOUNCE_THRESHOLDS = {600, 300, 120, 60, 30, 10}
-- Only the last minute plays a sound, a 30 minute break would otherwise beep at
-- everyone half a dozen times.
local SOUND_THRESHOLD = 60
-- The raid warning (if enabled) is only sent by whoever started the break, and
-- only for this threshold, so people without the addon get one heads-up.
local RAID_WARNING_THRESHOLD = 60

local UPDATE_INTERVAL = 0.1
-- Breaks shorter than this aren't worth restoring after a /reload.
local MIN_RESTORE_SECONDS = 5

local function FormatBreakTime(seconds)
    seconds = math.max(math.ceil(seconds), 0)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function PrintBreak(text)
    print("|cFF00FFFFNSRT|r "..text)
end

local function GetPlayerDisplayName()
    return NSAPI:Shorten("player", 12, false, "GlobalNickNames") or UnitName("player")
end

function NSI:PlayBreakSound()
    local s = NSRT.BreakTimer
    if not s.PlaySound then return end
    local sound = s.Sound and self.LSM:Fetch("sound", s.Sound, true)
    if sound then PlaySoundFile(sound, "Master") end
end

local function PickBreakMeme()
    local memes = NSMedia and NSMedia.BreakMemes
    if not memes or #memes == 0 then return end
    return memes[math.random(#memes)]
end

function NSI:CreateBreakTimerDisplay()
    if self.BreakTimerFrame then return self.BreakTimerFrame end
    local F = CreateFrame("StatusBar", "NSRTBreakTimer", self.NSRTFrame, "BackdropTemplate")
    F:Hide()
    F:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tileSize = 0,
    })
    F:SetMinMaxValues(0, 1)
    F:SetValue(1)
    F.Border = CreateFrame("Frame", nil, F, "BackdropTemplate")
    F.Border:SetAllPoints(F)
    F.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    -- The meme sits on top of the bar. The BLPs got stretched to power of two
    -- dimensions when they were converted, so the size stored in
    -- NSMedia.BreakMemes is what restores the original aspect ratio.
    F.Meme = F:CreateTexture(nil, "ARTWORK")
    F.Meme:SetPoint("BOTTOM", F, "TOP", 0, 4)
    F.Text = F:CreateFontString(nil, "OVERLAY")
    F.Text:SetPoint("LEFT", F, "LEFT", 4, 0)
    F.TimerText = F:CreateFontString(nil, "OVERLAY")
    F.TimerText:SetPoint("RIGHT", F, "RIGHT", -4, 0)
    F.EndText = F:CreateFontString(nil, "OVERLAY")
    F.EndText:SetPoint("TOP", F, "BOTTOM", 0, -4)
    F:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    F:SetScript("OnDragStop", function(frame) self:StopFrameMove(frame, NSRT.BreakTimer) end)
    self.BreakTimerFrame = F
    return F
end

-- Applies position, size, texture, colors and font. Split out from the start
-- path so the options panel can restyle a running bar (or the preview) live.
function NSI:ApplyBreakTimerSettings()
    local F = self:CreateBreakTimerDisplay()
    local s = NSRT.BreakTimer
    F:ClearAllPoints()
    F:SetPoint(s.Anchor, self.NSRTFrame, s.relativeTo, s.xOffset, s.yOffset)
    F:SetSize(s.Width, s.Height)
    F:SetFrameStrata("HIGH")
    F:SetStatusBarTexture(self.LSM:Fetch("statusbar", s.Texture))
    F:SetStatusBarColor(unpack(s.barColors))
    F:SetBackdropColor(unpack(s.backgroundColors))
    F.Border:SetBackdropBorderColor(unpack(s.borderColors))
    local font = self.LSM:Fetch("font", s.Font or "Expressway")
    F.Text:SetFont(font, s.FontSize, s.FontFlags)
    F.TimerText:SetFont(font, s.FontSize, s.FontFlags)
    F.EndText:SetFont(font, s.FontSize, s.FontFlags)
    F.Text:SetTextColor(unpack(s.textColors))
    F.TimerText:SetTextColor(unpack(s.textColors))
    F.EndText:SetTextColor(unpack(s.textColors))

    local meme = s.ShowMeme and self.CurrentBreakMeme
    if meme then
        local width, height = meme[2], meme[3]
        local scale = s.MemeSize / math.max(width, height)
        F.Meme:SetTexture(meme[1])
        F.Meme:SetSize(width * scale, height * scale)
        F.Meme:Show()
    else
        F.Meme:Hide()
    end
end

local function OnBreakUpdate(F, elapsed)
    F.elapsed = (F.elapsed or 0) + elapsed
    if F.elapsed < UPDATE_INTERVAL then return end
    F.elapsed = 0
    NSI:UpdateBreakTimer()
end

function NSI:AnnounceBreak(remaining)
    local activeBreak = self.ActiveBreak
    for _, threshold in ipairs(ANNOUNCE_THRESHOLDS) do
        -- The duration check keeps a 3 minute break from immediately announcing
        -- "10:00 remaining" because it started below that threshold already.
        if remaining <= threshold and activeBreak.duration > threshold and not activeBreak.announced[threshold] then
            activeBreak.announced[threshold] = true
            if NSRT.BreakTimer.AnnounceChat then
                PrintBreak(string.format(self:Loc("Break: %s remaining"), FormatBreakTime(threshold)))
            end
            if threshold <= SOUND_THRESHOLD then self:PlayBreakSound() end
            if threshold == RAID_WARNING_THRESHOLD then
                self:SendBreakRaidWarning(string.format(self:Loc("NSRT: Break is over in %s"), FormatBreakTime(threshold)))
            end
        end
    end
end

function NSI:UpdateBreakTimer()
    local activeBreak = self.ActiveBreak
    if not activeBreak then return end
    local remaining = activeBreak.endTime - GetTime()
    if remaining <= 0 then
        self:FinishBreakTimer()
        return
    end
    self:AnnounceBreak(remaining)
    local F = self.BreakTimerFrame
    if not F then return end
    F:SetValue(remaining / activeBreak.duration)
    local shown = math.ceil(remaining)
    if shown ~= F.shownSeconds then
        F.shownSeconds = shown
        F.TimerText:SetText(FormatBreakTime(remaining))
    end
end

-- Raid warnings are only ever sent by the player who started the break, so
-- everyone else running the addon stays quiet in chat.
function NSI:SendBreakRaidWarning(text)
    if not NSRT.BreakTimer.SendRaidWarning then return end
    if not (self.ActiveBreak and self.ActiveBreak.isOwner) then return end
    if not IsInGroup() then return end
    if C_ChatInfo.InChatMessagingLockdown() then return end
    local channel = (IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))) and "RAID_WARNING" or "PARTY"
    C_ChatInfo.SendChatMessage(text, channel)
end

function NSI:HideBreakTimerFrame()
    local F = self.BreakTimerFrame
    if not F then return end
    F:SetScript("OnUpdate", nil)
    F:Hide()
end

function NSI:ShowBreakTimerFrame()
    local F = self:CreateBreakTimerDisplay()
    self:ApplyBreakTimerSettings()
    F.Text:SetText(self:Loc("Break"))
    F.EndText:SetText(string.format(self:Loc("Break ends at: %s"), date("%H:%M", math.floor(self.ActiveBreak.endServerTime))))
    F.shownSeconds = nil
    F.elapsed = 0
    F:SetScript("OnUpdate", OnBreakUpdate)
    F:Show()
    self:UpdateBreakTimer()
end

function NSI:FinishBreakTimer()
    self:SendBreakRaidWarning(self:Loc("NSRT: Break is over!")) -- needs the break to still be around to know we own it
    self.ActiveBreak = nil
    NSRT.BreakTimerState = nil
    self:HideBreakTimerFrame()
    self:PlayBreakSound()
    PrintBreak(self:Loc("Break is over!"))
end

-- senderName is the name shown in the chat announcement. It is left out when a
-- break gets restored after a /reload, so the restore stays silent.
function NSI:StartBreakTimer(seconds, senderName, duration, announcedThresholds)
    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then return end
    if self.IsBreakTimerPreview then self:SetBreakTimerPreview(false) end
    announcedThresholds = announcedThresholds or {}
    self.ActiveBreak = {
        endTime = GetTime() + seconds,
        endServerTime = GetServerTime() + seconds,
        duration = duration or seconds,
        announced = announcedThresholds,
    }
    NSRT.BreakTimerState = {endTime = self.ActiveBreak.endServerTime, duration = self.ActiveBreak.duration, announced = announcedThresholds}
    self.CurrentBreakMeme = PickBreakMeme()
    if senderName then
        PrintBreak(string.format(self:Loc("%s started a %s break."), senderName, FormatBreakTime(seconds)))
        self:PlayBreakSound()
    end
    if NSRT.BreakTimer.enabled then self:ShowBreakTimerFrame() end
end

function NSI:StopBreakTimer(senderName)
    local wasRunning = self.ActiveBreak ~= nil
    self.ActiveBreak = nil
    NSRT.BreakTimerState = nil
    self:HideBreakTimerFrame()
    if wasRunning and senderName then
        PrintBreak(string.format(self:Loc("%s cancelled the break."), senderName))
    end
    return wasRunning
end

function NSI:ReceiveBreakTimer(unit, seconds)
    if not UnitExists(unit) then return end
    if UnitIsUnit(unit, "player") then return end -- our own broadcast, already handled locally
    if not (UnitIsGroupLeader(unit) or UnitIsGroupAssistant(unit)) then return end
    local senderName = NSAPI:Shorten(unit, 12, false, "GlobalNickNames") or UnitName(unit)
    if seconds and seconds > 0 then
        self:StartBreakTimer(seconds, senderName)
    else
        self:StopBreakTimer(senderName)
    end
end

-- Restores a break that was still running when the player reloaded or relogged.
-- GetTime() doesn't survive that, so the end time is stored as server time.
function NSI:RestoreBreakTimer()
    local state = NSRT.BreakTimerState
    NSRT.BreakTimerState = nil
    if type(state) ~= "table" or not tonumber(state.endTime) then return end
    local remaining = state.endTime - GetServerTime()
    if remaining <= MIN_RESTORE_SECONDS then return end
    self:StartBreakTimer(remaining, nil, tonumber(state.duration), state.announced)
end

function NSI:BreakCommand(msg)
    local arg = strtrim(msg or ""):lower()
    if IsInGroup() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        PrintBreak(self:Loc("Only the raid leader or an assistant can start a break."))
        return
    end

    local minutes
    if arg == "stop" or arg == "cancel" or arg == "off" then
        minutes = 0
    else
        minutes = tonumber(arg)
    end
    if not minutes or minutes < 0 or minutes > MAX_BREAK_MINUTES then
        PrintBreak(string.format(self:Loc("Usage: /ns break <minutes> - use 0 to cancel a running break. The maximum is %d minutes."), MAX_BREAK_MINUTES))
        return
    end

    local seconds = math.floor(minutes * 60 + 0.5)
    local myName = GetPlayerDisplayName()
    if IsInGroup() then self:Broadcast("NSI_BREAK_TIMER", "RAID", seconds) end

    if seconds == 0 then
        self:SendBreakRaidWarning(self:Loc("NSRT: Break cancelled."))
        if not self:StopBreakTimer(myName) then
            PrintBreak(self:Loc("There is no break running."))
        end
        return
    end

    self:StartBreakTimer(seconds, myName)
    if self.ActiveBreak then
        self.ActiveBreak.isOwner = true
        self:SendBreakRaidWarning(string.format(self:Loc("NSRT: Break for %s"), FormatBreakTime(seconds)))
    end
end

-- Draggable preview used by the "Preview/Unlock" button in the options panel.
function NSI:SetBreakTimerPreview(active)
    active = active and true or false
    if self.IsBreakTimerPreview == active then return end
    self.IsBreakTimerPreview = active
    local F = self:CreateBreakTimerDisplay()
    if active then
        self.CurrentBreakMeme = PickBreakMeme()
        self:ApplyBreakTimerSettings()
        F:SetScript("OnUpdate", nil)
        F:SetValue(0.66)
        F.Text:SetText(self:Loc("Break"))
        F.TimerText:SetText(FormatBreakTime(5 * 60))
        F.EndText:SetText(string.format(self:Loc("Break ends at: %s"), date("%H:%M", math.floor(GetServerTime() + 5 * 60))))
        F:Show()
        self:MakeDraggable(F, NSRT.BreakTimer, true)
    else
        self:MakeDraggable(F, NSRT.BreakTimer, false)
        if self.ActiveBreak then
            self:ShowBreakTimerFrame()
        else
            self:HideBreakTimerFrame()
        end
    end
end

function NSI:ToggleBreakTimerPreview()
    self:SetBreakTimerPreview(not self.IsBreakTimerPreview)
end

-- Options-panel edits should restyle the preview (or a running break) right away.
function NSI:RefreshBreakTimerDisplay()
    if self.IsBreakTimerPreview or self.ActiveBreak then
        self:ApplyBreakTimerSettings()
    end
end

function NSI:ResetBreakTimerPosition()
    local s = NSRT.BreakTimer
    s.Anchor = "CENTER"
    s.relativeTo = "CENTER"
    s.xOffset = 0
    s.yOffset = 200
    self:RefreshBreakTimerDisplay()
end
