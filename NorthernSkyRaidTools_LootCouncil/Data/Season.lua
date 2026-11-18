-- ============================================================
--  Data/Season.lua - EVERYTHING that changes from season to season lives in this file.
--  Nothing else in the module hard-codes a season: Items, History and the council window read LC.Season.
--  At the start of a new season, update the sections below and nothing else.
--
--  Currently: Midnight Season 2 (patch 12.1), raid "The Venomous Abyss".
--  Entries marked TODO could not be confirmed and are left empty: the module still works without them
--  (it falls back as described next to each one).
-- ============================================================
local ADDON, LC = ...

LC.Season = {
    -- History is filed per key. Change it at a new season to start a fresh history list (the old list is kept).
    -- Leave it as it is to keep one running history.
    key  = "current",
    name = "Midnight Season 2",

    -- ---- 1. Encounters: encounterID -> name (history headings, boss labels) ------------------------------
    encounters = {
        [3470] = "Nek'zali the Soulcoiler",
        [3445] = "Entombed Sentinels",
        [3497] = "The Lost Explorers",
        [3455] = "Vashnik the Malignant",
        [3420] = "Sszorak",
        [3421] = "The Twin Fangs",
        [3429] = "The Coiled Altar",
        [3492] = "Ula'tek",
        [3379] = "Nymrissa Wavecaller",     -- the lair boss
        [3513] = "Kith'ix",
    },

    -- ---- 2. Tier sets ------------------------------------------------------------------------------------
    -- The item set IDs of this season's class tier sets, as [setID] = true (one per class, 13 of them).
    -- Find them with: /dump select(16, C_Item.GetItemInfo(<link of any piece of the set>))
    -- Source: the ItemSet table (build 12.1.7.70892); IDs 2055-2067, 5 pieces each. Only these sets count as tier.
    tierSetIDs = {
        [2055] = true, -- Baleful Grave-Knight's Crucible
        [2056] = true, -- Abyssal Doomhound's Pursuit
        [2057] = true, -- Bark of the Enigmatic Dreamwatcher
        [2058] = true, -- Echo of Calamity
        [2059] = true, -- Skulking Viper's Ambush
        [2060] = true, -- Primal Leywarden's Attire
        [2061] = true, -- Guile of the Monkey King
        [2062] = true, -- Radiance of the Consecrated Flame
        [2063] = true, -- Cosmic Penitent's Raiment
        [2064] = true, -- Chosen Bloodslayer's Hexweave
        [2065] = true, -- Ophidian Oracle's Prophecy
        [2066] = true, -- Damned Necrolyte's Shattered Restraints
        [2067] = true, -- Jade Warlord's Dominion
    },

    -- Tier tokens drop from specific bosses. encounterID -> the slot of the token it drops.
    -- A non-equippable "Miscellaneous" item from one of these bosses is treated as that slot's token.
    tokenSlotByBoss = {
        [3445] = "HANDS",       -- Entombed Sentinels
        [3497] = "SHOULDER",    -- The Lost Explorers
        [3455] = "CHEST",       -- Vashnik the Malignant
        [3420] = "LEGS",        -- Sszorak
        [3421] = "HEAD",        -- The Twin Fangs
    },
    -- Bosses whose non-equippable drop is an "omni" token that converts to ANY tier slot.
    omniTokenBosses = {
        [3492] = true,          -- Ula'tek
    },
    -- Exact tokens by item ID (checked before the boss rules above): [itemID] = "HEAD" | "SHOULDER" |
    -- "CHEST" | "HANDS" | "LEGS" | "ANY".
    tierTokens      = {
        -- Source: RCLootCouncil Utils/tokenData.lua (Midnight S2 tokens, 4 per slot: woven/cured/cast/forged).
        [270910] = "HANDS",    -- Venomwoven Idol
        [270911] = "HANDS",    -- Venomcured Idol
        [270912] = "HANDS",    -- Venomcast Idol
        [270913] = "HANDS",    -- Venomforged Idol
        [270914] = "HEAD",     -- Venomwoven Effigy
        [270915] = "HEAD",     -- Venomcured Effigy
        [270916] = "HEAD",     -- Venomcast Effigy
        [270917] = "HEAD",     -- Venomforged Effigy
        [270918] = "LEGS",     -- Venomwoven Relic
        [270919] = "LEGS",     -- Venomcured Relic
        [270920] = "LEGS",     -- Venomcast Relic
        [270921] = "LEGS",     -- Venomforged Relic
        [270922] = "SHOULDER", -- Venomwoven Remnant
        [270923] = "SHOULDER", -- Venomcured Remnant
        [270924] = "SHOULDER", -- Venomcast Remnant
        [270925] = "SHOULDER", -- Venomforged Remnant
        [270926] = "CHEST",    -- Venomwoven Icon
        [270927] = "CHEST",    -- Venomcured Icon
        [270928] = "CHEST",    -- Venomcast Icon
        [270929] = "CHEST",    -- Venomforged Icon
    },

    -- Armor type of each tier token (Enum.ItemArmorSubclass: 1 cloth, 2 leather, 3 mail, 4 plate). A token has no armor
    -- type of its own in the game data (it is a Miscellaneous item), so this is what lets a class that cannot wear that
    -- armor auto-pass it. Same 4 tokens per slot as above: woven = cloth, cured = leather, cast = mail, forged = plate.
    -- An omni token (Ula'tek's curio) or a token not listed here is never judged, so it stays usable by everyone.
    -- Add the new tokens here every season.
    tokenArmor = {
        [270910] = 1, -- Venomwoven Idol (cloth)
        [270911] = 2, -- Venomcured Idol (leather)
        [270912] = 3, -- Venomcast Idol (mail)
        [270913] = 4, -- Venomforged Idol (plate)
        [270914] = 1, -- Venomwoven Effigy (cloth)
        [270915] = 2, -- Venomcured Effigy (leather)
        [270916] = 3, -- Venomcast Effigy (mail)
        [270917] = 4, -- Venomforged Effigy (plate)
        [270918] = 1, -- Venomwoven Relic (cloth)
        [270919] = 2, -- Venomcured Relic (leather)
        [270920] = 3, -- Venomcast Relic (mail)
        [270921] = 4, -- Venomforged Relic (plate)
        [270922] = 1, -- Venomwoven Remnant (cloth)
        [270923] = 2, -- Venomcured Remnant (leather)
        [270924] = 3, -- Venomcast Remnant (mail)
        [270925] = 4, -- Venomforged Remnant (plate)
        [270926] = 1, -- Venomwoven Icon (cloth)
        [270927] = 2, -- Venomcured Icon (leather)
        [270928] = 3, -- Venomcast Icon (mail)
        [270929] = 4, -- Venomforged Icon (plate)
    },

    -- ---- 3. Weapons convertible to another main stat ------------------------------------------------------
    -- Only needed for the odd weapon that can be turned into a different main stat after it drops, which the stats on
    -- the dropped item cannot show: [itemID] = { "ITEM_MOD_INTELLECT_SHORT", ... } = the stat(s) it can become.
    -- Without an entry such a weapon is judged by the stats it drops with (Core/Items.lua, Items.WeaponEligible).
    weaponStatOverrides = {},

    -- ---- 4. Upgrade tracks (optional) -------------------------------------------------------------------
    -- Not used yet: the council window shows plain item level differences.
    tracks = {},

    -- ---- 5. Difficulty of items whose item string has no raid context ------------------------------------
    -- Catalyst, upgraded and crafted pieces carry another item context, so the difficulty letter in the tier
    -- column is read from their bonus IDs instead: first the upgrade track, then the Heroic/Mythic tag.
    -- Source: Raidbots bonuses.json, upgrade groups 614-618 (Midnight Season 2, 6 ranks per track).
    -- [bonusID] = DifficultyID: Veteran = LFR (17), Champion = Normal (14), Hero = Heroic (15), Myth = Mythic (16).
    trackBonus = {
        [12825] = 17, [12826] = 17, [12827] = 17, [12828] = 17, [12829] = 17, [12830] = 17,   -- Veteran 1-6/6
        [12833] = 14, [12834] = 14, [12835] = 14, [12836] = 14, [12837] = 14, [12838] = 14,   -- Champion 1-6/6
        [12841] = 15, [12842] = 15, [12843] = 15, [12844] = 15, [12845] = 15, [12846] = 15,   -- Hero 1-6/6
        [12849] = 16, [12850] = 16, [12851] = 16, [12852] = 16, [12853] = 16, [12854] = 16,   -- Myth 1-6/6
    },
    -- Fallback when no track bonus is present: the serverside difficulty tags on the item.
    difficultyTagBonus = { [13334] = 15, [13335] = 16 },   -- Heroic, Mythic
}
