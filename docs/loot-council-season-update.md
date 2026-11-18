# Loot Council: what to update each season

The loot council module (`NorthernSkyRaidTools_LootCouncil` and `NorthernSkyRaidTools_LootCouncil_UI`) keeps everything that changes from season to season in one data file:

**`NorthernSkyRaidTools_LootCouncil/Data/Season.lua`** (`LC.Season`)

Nothing else in the module hard-codes a season. Class armor and weapon proficiencies live in `Data/ItemRules.lua`, which only changes with an expansion or a class rework. This page lists what to touch, in the order to do it, and what breaks if you skip it.

Rule of thumb: the module never crashes on stale or empty season data. It degrades. Wrong tier slots, blank tier columns, tokens that are not auto-passed, boss names shown as "Encounter 1234". Nothing is lost, but the council window stops being trustworthy.

---

## Checklist at a glance

| # | What | File / section | Needed every season? |
|---|------|----------------|----------------------|
| 1 | Encounters (boss names) | `Season.lua` `encounters` | Yes, new raid |
| 2 | Tier set IDs | `Season.lua` `tierSetIDs` | Yes |
| 3 | Tier token to slot, by boss | `Season.lua` `tokenSlotByBoss`, `omniTokenBosses` | Yes, new raid |
| 4 | Exact tier token IDs | `Season.lua` `tierTokens` | Yes |
| 5 | Tier token armor type | `Season.lua` `tokenArmor` | Yes, or tokens stop auto-passing |
| 6 | Upgrade track bonus IDs | `Season.lua` `trackBonus`, `difficultyTagBonus` | Yes |
| 7 | Weapon stat overrides | `Season.lua` `weaponStatOverrides` | Only if a weapon can convert main stat |
| 8 | History season key | `Season.lua` `key`, `name` | Your choice, see below |
| 9 | Interface version | both loot council `.toc` files | Every patch |
| 10 | Boss names in core | `NorthernSkyRaidTools/BossData.lua` | When NSRT itself adds the raid |
| 11 | Preview / test data | `Core/Preview.lua` | Optional |
| 12 | Armor / weapon proficiencies | `Data/ItemRules.lua` | Only on expansion or class changes |

---

## 1. Encounters

`encounters = { [encounterID] = "Boss name" }`

Used for history headings and boss labels. `History.BossName` reads this first, then NSRT's `NSI.BossNames` (core `BossData.lua`), then falls back to "Encounter 1234".

- Find encounter IDs from the `ENCOUNTER_END` event or `NSI.BossNames`.
- Keep the lair or bonus boss if the raid has one.
- Not updated: history headings read "Encounter 3470" for new bosses, and old entries keep their stored boss name.

## 2. Tier set IDs

`tierSetIDs = { [setID] = true }`, one per class (13).

Only items from these sets count as tier. Get an ID by linking any piece of the set and running:

```
/dump select(16, C_Item.GetItemInfo(<link>))
```

- If the table is **empty**, any item-set piece in a tier slot counts as tier (works, but also matches non-tier sets).
- If it still lists **last season's** sets, this season's pieces are not recognized as tier. The tier columns, 2pc/4pc counts and tier-slot highlights in the council window go wrong.
- Replace the old IDs outright; do not keep both seasons.

## 3. Tier tokens by boss

```lua
tokenSlotByBoss = { [encounterID] = "HEAD" | "SHOULDER" | "CHEST" | "HANDS" | "LEGS" }
omniTokenBosses = { [encounterID] = true }
```

A non-equippable Miscellaneous drop from one of these bosses is treated as that slot's token. An omni token (converts to any slot) goes in `omniTokenBosses`. Bosses that drop no regular token are simply left out.

This is the fallback. An exact entry in `tierTokens` (next section) wins.

## 4. Exact tier token IDs

`tierTokens = { [itemID] = "HEAD" | "SHOULDER" | "CHEST" | "HANDS" | "LEGS" | "ANY" }`

Checked before the boss rules. List every token item ID: this season there are 4 per slot (woven, cured, cast, forged). RCLootCouncil's `Utils/tokenData.lua` is a good source for the IDs, or the Wowhead item pages.

## 5. Tier token armor type (do not skip)

`tokenArmor = { [itemID] = armorSubclass }` with `1` cloth, `2` leather, `3` mail, `4` plate.

A token is a Miscellaneous item with no armor type in the game data, and the loot frame only auto-passes what the rules can prove unusable. Without this table, a priest is asked to respond on the leather, mail and plate tokens. With it, a token is judged like the armor it turns into.

- Add every token that is tied to an armor type. Same item IDs as `tierTokens`.
- Omni tokens and anything not listed here are never judged, so they stay usable by everyone (the safe default).
- If a season's tokens are class-locked instead (the tooltip shows a "Classes:" line), the module reads that line from the tooltip and needs no data here.

## 6. Upgrade track bonus IDs

```lua
trackBonus         = { [bonusID] = difficultyID }   -- Veteran 17, Champion 14, Hero 15, Myth 16
difficultyTagBonus = { [bonusID] = difficultyID }   -- Heroic 15, Mythic 16
```

Catalyst, upgraded and crafted pieces do not carry a raid item context, so the difficulty letter (LFR / N / H / M) in the tier column is read from these bonus IDs. Source: Raidbots `bonuses.json`, upgrade groups (6 ranks per track).

Not updated: tier pieces from the Catalyst and upgrades show no difficulty letter. Raid drops are unaffected, they use the item context.

## 7. Weapon stat overrides

`weaponStatOverrides = { [itemID] = { "ITEM_MOD_INTELLECT_SHORT", ... } }`

Only for the odd weapon that can be converted to another main stat after it drops, which the stats on the dropped item cannot show. Usually empty. Without an entry, the weapon is judged by the stats it drops with (an agility dagger is auto-passed by a priest).

## 8. History season key

`key = "current"`, `name = "Midnight Season 2"`

History is filed per key and the old list is kept. Leave `key` alone to keep one running history across seasons, or change it to start a fresh list. Changing it hides the previous season's entries from the history window (they stay in the saved variables). Update `name` either way.

## 9. Interface version

Bump `## Interface:` in both loot council `.toc` files (`NorthernSkyRaidTools_LootCouncil.toc` and `NorthernSkyRaidTools_LootCouncil_UI.toc`) when a patch changes it, so the module is not flagged "out of date". The core addon and Kit have their own lines; keep them in step.

## 10. Core boss names

When NSRT itself gets the new raid, `NorthernSkyRaidTools/BossData.lua` (`NSI.BossNames`) gets it too. The loot council falls back to it when a boss is missing from `Season.lua`, but keep `encounters` filled so the module does not depend on it.

## 11. Preview and test data (optional)

`Core/Preview.lua` uses fixed item IDs and old raid bosses for the `/ns lc test` sample data. It works as is. Refresh the IDs if you want the preview to show current-tier items, and keep one item your own class cannot use so the auto-pass can be tried.

## 12. Armor and weapon proficiencies

`Data/ItemRules.lua` holds which class wears which armor, wields which weapon type, and wants which main stat. These are game rules, not season data. Touch them only when Blizzard changes class proficiencies (a new expansion, a new class, a rework). Trinkets are asked of the game (`C_Item.DoesItemContainSpec`), so there is no trinket list to keep.

---

## Do not need updating

- Raid difficulty mapping (`Items.ContextToDifficulty`, `Items.DifficultyName`): stable game IDs (14 Normal, 15 Heroic, 16 Mythic, 17 LFR).
- The five tier slots (`Items.TierSlots`).
- Class restrictions printed on an item ("Classes: ..."): read from the tooltip.
- Rulesets, response buttons, council settings: configured in game by the raid leader.

---

## Verify after updating

1. `/reload`, then run `/ns lc test` to check nothing errors on load.
2. In a real or test session, link the new tier pieces and tokens and check the council window: tier slot highlights, 2pc/4pc counts, difficulty letters.
3. With a character of each armor type, check tokens are auto-passed only when that class cannot use them. Omni tokens must never be auto-passed.
4. Kill a boss and open the history window: the boss name and difficulty should be right, not "Encounter ####".
5. Run the pure specs (`tools/lc-tests/run.lua`) if you have a Lua interpreter.
6. Add a bullet to `CHANGELOG.md` for user-visible changes.

## Where to look things up

| Need | Source |
|------|--------|
| Encounter IDs | `ENCOUNTER_END` event, `NSI.BossNames` |
| Tier set ID | `/dump select(16, C_Item.GetItemInfo(<link>))` |
| Token item IDs | RCLootCouncil `Utils/tokenData.lua`, Wowhead |
| Track bonus IDs | Raidbots `bonuses.json` |
| Item class / subclass | `/dump C_Item.GetItemInfoInstant(<link>)` |
