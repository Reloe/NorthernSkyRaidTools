-- ============================================================
--  Data/ItemRules.lua - which class can use which armor, weapon type and weapon main stat
--
--  Static game rules, not season data: they change only when Blizzard changes class proficiencies, so unlike
--  Data/Season.lua this file is normally left alone. Core/Items.lua turns these tables into "can this class use
--  this drop?" (armor and weapon type, weapon main stat). Class restrictions printed on the item ("Classes: ...")
--  are read from the tooltip instead, so they need no data here.
--
--  Everything is keyed by the numeric Enum.ItemArmorSubclass / Enum.ItemWeaponSubclass value (plain numbers so
--  the pure specs can load this file without the game). A subclass that is not listed (rings, cloaks, thrown,
--  fishing poles, ...) is not judged, so such an item counts as usable.
-- ============================================================
local ADDON, LC = ...

LC.ItemRules = {
    -- ---- armor: Enum.ItemArmorSubclass -> classes that can wear / carry it -----------------------------------
    -- A shield is listed for every class that can ever use one; whether the spec can is left to the council.
    armorUsers = {
        [1] = { PRIEST = true, MAGE = true, WARLOCK = true }, -- Cloth
        [2] = { ROGUE = true, MONK = true, DRUID = true, DEMONHUNTER = true }, -- Leather
        [3] = { HUNTER = true, SHAMAN = true, EVOKER = true }, -- Mail
        [4] = { WARRIOR = true, PALADIN = true, DEATHKNIGHT = true }, -- Plate
        [6] = { WARRIOR = true, PALADIN = true, SHAMAN = true }, -- Shield
    },

    -- ---- weapons: Enum.ItemWeaponSubclass -> classes that can equip it -------------------------------------
    weaponUsers = {
        [0] = { WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, DEATHKNIGHT = true, SHAMAN = true, MONK = true, DEMONHUNTER = true, EVOKER = true }, -- Axe1H
        [1] = { WARRIOR = true, PALADIN = true, HUNTER = true, DEATHKNIGHT = true, SHAMAN = true }, -- Axe2H
        [2] = { HUNTER = true, ROGUE = true }, -- Bows
        [3] = { HUNTER = true, ROGUE = true }, -- Guns
        [4] = { WARRIOR = true, PALADIN = true, ROGUE = true, PRIEST = true, DEATHKNIGHT = true, SHAMAN = true, MONK = true, DRUID = true, EVOKER = true }, -- Mace1H
        [5] = { WARRIOR = true, PALADIN = true, DEATHKNIGHT = true, SHAMAN = true, DRUID = true, EVOKER = true }, -- Mace2H
        [6] = { WARRIOR = true, PALADIN = true, HUNTER = true, DEATHKNIGHT = true, MONK = true, DRUID = true }, -- Polearm
        [7] = { WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, DEATHKNIGHT = true, MAGE = true, WARLOCK = true, MONK = true, DEMONHUNTER = true, EVOKER = true }, -- Sword1H
        [8] = { WARRIOR = true, PALADIN = true, HUNTER = true, DEATHKNIGHT = true }, -- Sword2H
        [9] = { DEMONHUNTER = true }, -- Warglaive
        [10] = { WARRIOR = true, HUNTER = true, PRIEST = true, SHAMAN = true, MAGE = true, WARLOCK = true, MONK = true, DRUID = true, EVOKER = true }, -- Staff
        [13] = { WARRIOR = true, HUNTER = true, ROGUE = true, SHAMAN = true, MONK = true, DRUID = true, DEMONHUNTER = true, EVOKER = true }, -- Unarmed
        [15] = { WARRIOR = true, HUNTER = true, ROGUE = true, PRIEST = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true, DEMONHUNTER = true, EVOKER = true }, -- Dagger
        [18] = { HUNTER = true, ROGUE = true }, -- Crossbow
        [19] = { PRIEST = true, MAGE = true, WARLOCK = true }, -- Wand
    },

    -- ---- class IDs --------------------------------------------------------------------------------------------
    -- Class token -> numeric class ID, for the game calls that take a class ID (trinkets are asked of the game with
    -- C_Item.DoesItemContainSpec, so there is no trinket list to keep).
    classIDs = {
        WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, DEATHKNIGHT = 6, SHAMAN = 7,
        MAGE = 8, WARLOCK = 9, MONK = 10, DRUID = 11, DEMONHUNTER = 12, EVOKER = 13,
    },

    -- ---- weapon main stat: the stats a weapon can carry for a class to want it ------------------------------
    -- A weapon with a main stat but none of these is useless to the class (an agility dagger for a priest). A weapon
    -- with no main stat at all is never judged by this rule. Keys are the stat names C_Item.GetItemStats returns.
    weaponMainStats = {
        WARRIOR = { "ITEM_MOD_STRENGTH_SHORT" },
        PALADIN = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_INTELLECT_SHORT" },
        HUNTER = { "ITEM_MOD_AGILITY_SHORT" },
        ROGUE = { "ITEM_MOD_AGILITY_SHORT" },
        PRIEST = { "ITEM_MOD_INTELLECT_SHORT" },
        DEATHKNIGHT = { "ITEM_MOD_STRENGTH_SHORT" },
        SHAMAN = { "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_AGILITY_SHORT" },
        MAGE = { "ITEM_MOD_INTELLECT_SHORT" },
        WARLOCK = { "ITEM_MOD_INTELLECT_SHORT" },
        MONK = { "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_AGILITY_SHORT" },
        DRUID = { "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_AGILITY_SHORT" },
        DEMONHUNTER = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_INTELLECT_SHORT" },
        EVOKER = { "ITEM_MOD_INTELLECT_SHORT" },
    },
}
