local _, NSI = ...

local CLASS_ORDER = {
    "DEATHKNIGHT", "DEMONHUNTER", "DRUID",  "EVOKER",
    "HUNTER",      "MAGE",        "MONK",   "PALADIN",
    "PRIEST",      "ROGUE",       "SHAMAN", "WARLOCK",
    "WARRIOR",
}

local CLASS_DISPLAY = {
    DEATHKNIGHT = "Death Knight", DEMONHUNTER = "Demon Hunter",
    DRUID       = "Druid",        EVOKER      = "Evoker",
    HUNTER      = "Hunter",       MAGE        = "Mage",
    MONK        = "Monk",         PALADIN     = "Paladin",
    PRIEST      = "Priest",       ROGUE       = "Rogue",
    SHAMAN      = "Shaman",       WARLOCK     = "Warlock",
    WARRIOR     = "Warrior",
}

local CLASS_ICONS = {
    DEATHKNIGHT = 135771,  DEMONHUNTER = 1260827,
    DRUID       = 625999,  EVOKER      = 4574311,
    HUNTER      = 626000,  MAGE        = 626001,
    MONK        = 626002,  PALADIN     = 626003,
    PRIEST      = 626004,  ROGUE       = 626005,
    SHAMAN      = 626006,  WARLOCK     = 626007,
    WARRIOR     = 626008,
}

-- specID → { name, class, icon }
local SPEC_DATA = {
    -- Death Knight
    [250]  = { name = "Blood",         class = "DEATHKNIGHT", icon = 135770  },
    [251]  = { name = "Frost",         class = "DEATHKNIGHT", icon = 135773  },
    [252]  = { name = "Unholy",        class = "DEATHKNIGHT", icon = 135775  },
    -- Demon Hunter
    [577]  = { name = "Havoc",         class = "DEMONHUNTER", icon = 1247264 },
    [581]  = { name = "Vengeance",     class = "DEMONHUNTER", icon = 1247265 },
    [1480] = { name = "Devourer",      class = "DEMONHUNTER", icon = 7455385 },
    -- Druid
    [102]  = { name = "Balance",       class = "DRUID",       icon = 136096  },
    [103]  = { name = "Feral",         class = "DRUID",       icon = 132115  },
    [104]  = { name = "Guardian",      class = "DRUID",       icon = 132276  },
    [105]  = { name = "Restoration",   class = "DRUID",       icon = 136041  },
    -- Evoker
    [1467] = { name = "Devastation",   class = "EVOKER",      icon = 4511811 },
    [1468] = { name = "Preservation",  class = "EVOKER",      icon = 4511812 },
    [1473] = { name = "Augmentation",  class = "EVOKER",      icon = 5198700 },
    -- Hunter
    [253]  = { name = "Beast Mastery", class = "HUNTER",      icon = 461112  },
    [254]  = { name = "Marksmanship",  class = "HUNTER",      icon = 236179  },
    [255]  = { name = "Survival",      class = "HUNTER",      icon = 461113   },
    -- Mage
    [62]   = { name = "Arcane",        class = "MAGE",        icon = 135932  },
    [63]   = { name = "Fire",          class = "MAGE",        icon = 135810  },
    [64]   = { name = "Frost",         class = "MAGE",        icon = 135846  },
    -- Monk
    [268]  = { name = "Brewmaster",    class = "MONK",        icon = 608951  },
    [270]  = { name = "Mistweaver",    class = "MONK",        icon = 608952  },
    [269]  = { name = "Windwalker",    class = "MONK",        icon = 608953  },
    -- Paladin
    [65]   = { name = "Holy",          class = "PALADIN",     icon = 135920  },
    [66]   = { name = "Protection",    class = "PALADIN",     icon = 236264  },
    [70]   = { name = "Retribution",   class = "PALADIN",     icon = 535595  },
    -- Priest
    [256]  = { name = "Discipline",    class = "PRIEST",      icon = 135940  },
    [257]  = { name = "Holy",          class = "PRIEST",      icon = 237542  },
    [258]  = { name = "Shadow",        class = "PRIEST",      icon = 136207  },
    -- Rogue
    [259]  = { name = "Assassination", class = "ROGUE",       icon = 236270  },
    [260]  = { name = "Outlaw",        class = "ROGUE",       icon = 236286  },
    [261]  = { name = "Subtlety",      class = "ROGUE",       icon = 132320  },
    -- Shaman
    [262]  = { name = "Elemental",     class = "SHAMAN",      icon = 136048  },
    [263]  = { name = "Enhancement",   class = "SHAMAN",      icon = 237581  },
    [264]  = { name = "Restoration",   class = "SHAMAN",      icon = 136043  },
    -- Warlock
    [265]  = { name = "Affliction",    class = "WARLOCK",     icon = 136145  },
    [266]  = { name = "Demonology",    class = "WARLOCK",     icon = 136172  },
    [267]  = { name = "Destruction",   class = "WARLOCK",     icon = 136186  },
    -- Warrior
    [71]   = { name = "Arms",          class = "WARRIOR",     icon = 132355  },
    [72]   = { name = "Fury",          class = "WARRIOR",     icon = 132347  },
    [73]   = { name = "Protection",    class = "WARRIOR",     icon = 132341  },
}

-- class → ordered spec IDs
local CLASS_SPECS = {
    DEATHKNIGHT = { 250, 251, 252 },
    DEMONHUNTER = { 577, 581, 1480 },
    DRUID       = { 102, 103, 104, 105 },
    EVOKER      = { 1467, 1468, 1473 },
    HUNTER      = { 253, 254, 255 },
    MAGE        = { 62, 63, 64 },
    MONK        = { 268, 270, 269 },
    PALADIN     = { 65, 66, 70 },
    PRIEST      = { 256, 257, 258 },
    ROGUE       = { 259, 260, 261 },
    SHAMAN      = { 262, 263, 264 },
    WARLOCK     = { 265, 266, 267 },
    WARRIOR     = { 71, 72, 73 },
}

-- Returns getItems, getSelected for use with CreateDropdown.
-- getValue – function() → class string (e.g. "WARRIOR") or nil
-- setValue – function(classString|nil)
function NSI:BuildClassDropdown(getValue, setValue)
    local function getItems()
        local t = {
            {
                label   = "All Classes",
                value   = nil,
                onclick = function() if setValue then setValue(nil) end end,
            }
        }
        for _, cls in ipairs(CLASS_ORDER) do
            local c = cls
            t[#t + 1] = {
                label   = CLASS_DISPLAY[c],
                value   = c,
                icon    = CLASS_ICONS[c],
                onclick = function(_, _, val)
                    if setValue then setValue(val) end
                end,
            }
        end
        return t
    end

    local function getSelected()
        local v = getValue and getValue()
        if not v or v == "" then return "All Classes" end
        return CLASS_DISPLAY[v] or v
    end

    return getItems, getSelected
end

-- Returns getItems, getSelected for use with CreateDropdown.
-- getClass – function() → class string or nil (nil = show all specs)
-- getValue – function() → specID (number) or nil
-- setValue – function(specID|nil)
function NSI:BuildSpecDropdown(getClass, getValue, setValue)
    local function getItems()
        local cls     = getClass and getClass()
        local specIDs = cls and CLASS_SPECS[cls]

        if not specIDs then
            specIDs = {}
            for _, c in ipairs(CLASS_ORDER) do
                for _, id in ipairs(CLASS_SPECS[c]) do
                    specIDs[#specIDs + 1] = id
                end
            end
        end

        local t = {
            {
                label   = "All Specs",
                value   = nil,
                onclick = function() if setValue then setValue(nil) end end,
            }
        }
        for _, id in ipairs(specIDs) do
            local specID = id
            local data   = SPEC_DATA[id]
            if data then
                t[#t + 1] = {
                    label   = data.name,
                    value   = specID,
                    icon    = data.icon,
                    onclick = function(_, _, val)
                        if setValue then setValue(val) end
                    end,
                }
            end
        end
        return t
    end

    local function getSelected()
        local v    = getValue and getValue()
        local data = v and SPEC_DATA[v]
        return data and data.name or "All Specs"
    end

    return getItems, getSelected
end

NSI.UI = NSI.UI or {}
NSI.UI.ClassData = {
    CLASS_ORDER   = CLASS_ORDER,
    CLASS_DISPLAY = CLASS_DISPLAY,
    CLASS_ICONS   = CLASS_ICONS,
    SPEC_DATA     = SPEC_DATA,
    CLASS_SPECS   = CLASS_SPECS,
}
