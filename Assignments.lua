local _, NSI = ... -- Internal namespace

function NSI:AddAssignments(encID)
    local subgroup = self:GetSubGroup("player")
    local text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, TTSTimer
    if encID == 3306 and self:DifficultyCheck(16) then -- Chimaerus
        -- debuff is 5s, display starts 5s before debuff application but sound is played on application
        dur = 10
        TTSTimer = 5
        text = subgroup <= 2 and "SOAK" or "DON'T SOAK"
        time = 19.4
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        text = subgroup >= 3 and "SOAK" or "DON'T SOAK"
        time = 72.1
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        text = subgroup <= 2 and "SOAK" or "DON'T SOAK"
        time = 237.8
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        text = subgroup >= 3 and "SOAK" or "DON'T SOAK"
        time = 290.5
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        return
    elseif encID == 3178 and self:DifficultyCheck(16) then -- Dragons
        -- breath cast is 4s, display starts earlier and sound is played at start of the cast
        dur = 10
        TTSTimer = 4
        text = subgroup == 2 and "SOAK" or "DON'T SOAK"
        time = 54.4
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        text = subgroup == 3 and "SOAK" or "DON'T SOAK"
        time = 156.1
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        text = subgroup == 2 and "SOAK" or "DON'T SOAK"
        time = 201.2
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        text = subgroup == 3 and "SOAK" or "DON'T SOAK"
        time = 246.1
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        return
    elseif encID == 3180 and self:DifficultyCheck(16) then -- Council
        -- debuff duration is 10s so we start display&sound at the same time
        dur = 10
        TTSTimer = 10
        local group = {}
        local healer = {}
        for unit in self:IterateGroupMembers() do
            local specID = NSAPI:GetSpecs(unit) or 0
            local prio = self.spectable[specID]
            local G = self.GUIDS[unit]
            if UnitGroupRolesAssigned(unit) == "HEALER" then
                table.insert(healer, {unit = unit, prio = prio, GUID = G})
            else
                table.insert(group, {unit = unit, prio = prio, GUID = G})
            end
        end
        self:SortTable(group)
        self:SortTable(healer)
        local mygroup
        local IsHealer = UnitGroupRolesAssigned("player") == "HEALER"
        if IsHealer then
            for i, v in ipairs(healer) do
                if UnitIsUnit("player", v.unit) then
                    mygroup = i
                    mygroup = math.min(4, mygroup) -- if there are more than 4 healers, put any extra healer in the 4th group                    
                end
            end
        else
            for i, v in ipairs(group) do
                if UnitIsUnit("player", v.unit) then
                    mygroup = math.ceil(i/4)
                    mygroup = math.min(4, mygroup) -- if there are less than 4healers dps would overflow so put any extra in 4th
                    break
                end
            end
        end
        if not mygroup then return end
        local pos = (mygroup == 1 and "Star") or (mygroup == 2 and "Orange") or (mygroup == 3 and "Purple") or (mygroup == 4 and "Green") or ""
        text = (IsHealer and "Go to {rt"..mygroup.."}") or "Soak {rt"..mygroup.."}"
        TTS = (IsHealer and "Go to "..pos) or "Soak "..pos
        time = 96.1
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        time = 271.2
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        time = 446.3
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        return
    end
    if not NSRT.Settings["Debug"] then return end
    -- debug stuff only
    if encID == 3182 then
        local phase, countdown, glowunit, sound, time, spellID, dur, TTS = 1, 3, "Reloe", false, 10, 115203, 8
        local text = false
        self.ProcessedAssigns[phase] = self.ProcessedAssigns[phase] or {}
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)

        local phase, countdown, glowunit, sound, time, spellID, dur, TTS = 1, false, false, "Soak", 20, false, 8
        local text = "Soak"
        self.ProcessedAssigns[phase] = self.ProcessedAssigns[phase] or {}
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)

        local phase, countdown, glowunit, sound, time, spellID, dur, TTS = 1, false, false, false, 25, false, 8
        local text = "Balls"
        self.ProcessedAssigns[phase] = self.ProcessedAssigns[phase] or {}
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        
    elseif (encID == 2900 or encID == 3306 or encID == 3176 or encID == 3177 or encID == 3179 or encID == 3178 or encID == 3180) then -- all raid tests debug & 1st Boss Cinderbrew
        local phase, countdown, glowunit, sound, time, spellID, dur = 1, 3, false, false, 20, false, 10
        local subgroup = math.random(1, 4)
        local text = subgroup <= 2 and "|cFF00FF00SOAK|r" or "|cFFFF0000DON'T SOAK|r"
        local TTS = subgroup <= 2 and "Soak" or "Don't Soak"   
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
        phase = 1
        time = 30
        text = subgroup <= 2 and "|cFF00FF00Go Left" or "|cFFFF0000Go Right"
        spellID = 774
        TTS = subgroup <= 2 and "Go Left" or "Go Right"
        self:AddToReminder(text, phase, countdown, glowunit, sound, time, spellID, dur, TTS, encID, TTSTimer)
    end
end

function NSAPI:DebugAssignments(encID)
    NSI:EventHandler("READY_CHECK", true)
    C_Timer.After(2, function()
        NSI:EventHandler("ENCOUNTER_START", true, false, encID) -- will also trigger reminders but don't have a great way to do only assignments
    end)
end