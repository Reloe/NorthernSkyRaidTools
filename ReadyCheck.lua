local _, NSI = ... -- Internal namespace

local buffs = {
    [1] = 6673, -- Battle Shout
    [5] = 21562, -- Stamina
    [7] = 462854, -- Skyfury
    [8] = 1459, -- Intellect
    [11] = 1126, -- Mark of the Wild
   -- [13] = 0, -- Evoker Buff. need some other solution for this because it has 13 different spellid's
}

local buffrequired = {
    [1] = {1, 2, 3, 4, 6, 7, 10, 11, 12, 250, 251, 252, 577, 581, 103, 104, 253, 254, 255, 268, 269, 66, 70, 259, 260, 261, 263, 71, 72, 73}, -- Battle Shout
    [8] = {2, 5, 7, 8, 9, 10, 11, 12, 13, 1480, 102, 105, 1467, 1468, 1473, 62, 63, 64, 270, 65, 256, 257, 258, 262, 264, 265, 266, 267}, -- Intellect
}


function NSI:BuffCheck()
    local class = select(3, UnitClass("player"))
    local spellID = buffs[class]
    if spellID then
        for unit in NSI:IterateGroupMembers() do
            local specID = NSI.specs and NSI.specs[unit] or select(3, UnitClass(unit)) -- if specdata exists we use that, otherwise class which means maybe some useless buffs are being done.
            if specID and (class == 5 or class == 13 or class == 11 or class == 7 or tContains(buffrequired[class], specID)) then
                local buffed = NSI:UnitAura(unit, spellID)
                if (not buffed) or buffed == "" then
                    NSAPI:TTS("Rebuff")
                    break
                    -- add display for rebuff
                end     
            end       
        end
    end
end