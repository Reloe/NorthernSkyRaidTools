local _, NSI = ... -- Internal namespace

local encID = 3180
-- /run NSAPI:DebugEncounter(3180)
NSI.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    if not NSRT.EncounterAlerts[encID] then
        NSRT.EncounterAlerts[encID] = {enabled = false}
    end
    if NSRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Peace Aura", "Text", nil, 10, 1, encID) -- Peace Aura

        -- same timer on all difficulties for now
        Alert.TTS = false
        local id = self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [14] = {137.4, 313.3},
            [15] = {137.4, 313.3},
            [16] = {137.4, 313.3},
        }
        local timers = self:DifficultyCheck(14) and {137.4, 313.3} or {}
        for _, time in ipairs(timers[id]) do
            Alert.time = time
            self:AddToReminder(Alert)
        end
    end
end

NSI.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
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
    local pos = (mygroup == 1 and "Star") or (mygroup == 2 and "Orange") or (mygroup == 3 and "Purple") or (mygroup == 4 and "Green") or "Flex Spot"
    local text = (IsHealer and "Go to {rt"..mygroup.."}") or "Soak {rt"..mygroup.."}"
    local TTS = (IsHealer and "Go to "..pos) or "Soak "..pos
    Alert.TTS, Alert.TTSTimer, Alert.text = 92, TTS, 10, text
    local phaselength = 162.7 -- guess based on Zealous Spirit in logs

    for phase = 0, 2 do
        Alert.time = 92 + (phase * phaselength)
        self:AddToReminder(Alert)
        if self:DifficultyCheck(16) then -- second cast is mythic only in case I want to support Heroic as well
            Alert.time = 149.2 + (phase * phaselength)
            self:AddToReminder(Alert)
        end
    end

    if NSRT.AssignmentSettings.OnPull then
        local text = mygroup == 1 and "|cFFFFFF00Star|r" or mygroup == 2 and "|cFFFFA500Orange|r" or mygroup == 3 and "|cFF9400D3Purple|r" or mygroup == 4 and "|cFF00FF00Green|r" or ""
        self:DisplayText("You are assigned to soak |cFF00FF00Execution Sentence|r in the "..text.." Group", 5)
    end
end