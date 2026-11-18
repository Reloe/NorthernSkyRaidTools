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
        -- TODO: 3513 "Kith'ix" is in the NSRT boss list but its raid is not confirmed.
    },

    -- ---- 2. Tier sets ------------------------------------------------------------------------------------
    -- The item set IDs of this season's class tier sets, as [setID] = true (one per class, 13 of them).
    -- Find them with: /dump select(16, C_Item.GetItemInfo(<link of any piece of the set>))
    -- TODO: not filled in. While this is empty, ANY item that belongs to an item set and sits in a tier slot
    -- (head, shoulders, chest, hands, legs) is treated as a tier piece. Fill it in to exclude older sets.
    tierSetIDs = {},

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
    -- Exact tokens by item ID, only needed if the rules above ever get one wrong: [itemID] = "HEAD" | "SHOULDER" |
    -- "CHEST" | "HANDS" | "LEGS" | "ANY".
    tierTokens = {},

    -- ---- 3. Upgrade tracks (optional) -------------------------------------------------------------------
    -- Not used yet: the council window shows plain item level differences.
    tracks = {},
}
