# Plan: Restructure Aura Tracking into an Encounter-Alerts-style manager

## Goal
Reformat the Aura Tracking page (`UI/Options/AuraTracking.lua`) and its backend
(`AuraTracking.lua`) from the flat DetailsFramework options-menu paradigm into a
hand-rolled create/delete/edit manager modeled on `UI/EncounterAlerts.lua`.
Each tracked aura becomes an editable entry with **Display / Trigger / Sound / Load**
tabs. The trigger is a spell ID (+ unit); all tracking logic stays inside
`AuraTracking.lua`. New headline feature: anchor a display to an arbitrary frame
for precise positioning, including a click-to-pick frame picker.

## Confirmed decisions
- **Built-ins:** Keep Player / Tank / External as locked, non-deletable entries,
  grouped in a collapsible **"Built-in"** section (like boss groups in Encounter
  Alerts). Also add a full user-group system for bulk enable/disable.
- **Trigger scope:** Spell ID(s) + unit only.
- **Anchoring:** Manual frame-name entry + anchor point/offset, **plus** an optional
  click-to-pick button that auto-populates the anchor name.

## Blizzard filtering constraint (shapes the Trigger design)
`includeSpellIDs` candidate filtering only works for **buffs on friendly units**
and **debuffs on enemy units**. Therefore, for user spellID entries, buff-vs-debuff
is decided by the chosen unit — no separate toggle needed:
- **Friendly unit** (player, co-tank, party/raid) -> tracks matching **buffs** (HELPFUL).
- **Enemy unit** (target, focus, boss1-5) -> tracks matching **debuffs** (HARMFUL).

The three built-in trackers are unaffected: Player/Tank use Blizzard's
`isBossOrRoleAura` candidate filter (track-all boss/role debuffs) and External uses a
helpful-aura group, none of which spellID-filter. A short inline hint in the Trigger
tab will explain the friendly=buff / enemy=debuff rule.

## 1. Data model + migration (`AuraTracking.lua`)
Extend the existing structure rather than replacing it:
- `NSRT.AuraTrackingSettings.Player / Tank / External` stay as the three **built-in,
  non-deletable** entries (add a `builtin` marker + `Name`).
- `NSRT.AuraTrackingSettings.Custom[]` remains the array of **user-created** entries
  (what Create/Delete operates on).
- Add `NSRT.AuraTrackingSettings.Groups = { [groupName] = { collapsed = bool } }`, and a
  `.group` field on each entry (built-ins default into a locked "Built-in" group).
- Extend each entry with:
  - `Trigger = { SpellIDs = {...}, Unit = "player" }`
  - `Sound = { enabled, sound, channel }`
  - `loadConditions = { Roles, Classes, SpecIDs, Names }`
  - anchor fields `Anchor` / `relativeTo` / `xOffset` / `yOffset` / `CustomAnchorFrame`
    (most already exist).
- One-time migration keyed on a schema-version flag: seed built-ins if absent, keep
  existing Custom entries as ungrouped, preserve all current style settings.

## 2. Backend logic (`AuraTracking.lua`, kept internal)
- `InitAuraTrackingContainer` learns per-entry **Unit** and picks the filter by unit
  friendliness: friendly -> `HELPFUL` + `includeSpellIDs`; enemy -> `HARMFUL` +
  `includeSpellIDs`. Built-ins keep their current `isBossOrRoleAura` / immunity-list paths.
- **Load gating:** before enabling a container, evaluate `loadConditions` via the
  existing `NSI:EvaluateLoad` (already used by the alert list at EncounterAlerts.lua:914)
  plus the current difficulty/role checks. Verify field compatibility during impl.
- **Sound:** when a matching aura instance newly appears, play the configured LSM sound
  on the chosen channel (guarded against preview/reload spam; fire on appear, not on
  refresh/stack change).
- Replace the `RebuildAuraTrackingOptionsMenu` calls (add/delete/rename) with a new
  `NSI:RefreshAuraTrackingUI()` that refreshes the list + selected editor.

## 3. UI rewrite (`UI/Options/AuraTracking.lua`) — modeled on `BuildEncounterAlertsUI`
Replace `DF:BuildMenu` options table with a hand-rolled `BuildAuraTrackingUI(parentFrame)`
using shared `NSI.UI.Components` widgets and the same list/group/tab patterns.

**Left panel:** title, search bar, scrollable entry list (enabled checkbox, spell/preview
icon, name, delete button — locked for built-ins), collapsible **group headers** with
right-click **Enable All / Disable All / Delete Group**, a locked "Built-in" group up top,
a **Create Aura** button, and **Preview / Stop All Previews** controls.

**Right panel (per selected entry):** header with Name entry + Group dropdown + Enabled
checkbox, then inner tabs:
- **Display** — all existing styling controls + an **Anchor** section: frame-name entry,
  anchor-point & relative-point dropdowns, X/Y offsets, and a **Pick** button (§4). Plus a
  Preview button.
- **Trigger** — Spell ID list, **Unit** dropdown (player / co-tank / target / focus /
  boss1-5), preview-icon spellID, and the friendly=buff / enemy=debuff hint.
- **Sound** — enable toggle, LSM sound dropdown with a test button, channel.
- **Load** — reuse the Role/Class/Spec/(difficulty) collapsible condition sections from
  the alerts Load tab (extract the shared builder where practical, adapt otherwise);
  built-ins lock parts that don't apply.

## 4. Frame picker + anchor precision (headline feature)
- Manual entry stays; add a **Pick** button that enters a targeting mode: a full-screen
  overlay + `OnUpdate` reading the frame under the cursor (`GetMouseFoci()`, fallback
  `GetMouseFocus()`), showing its name live, and on left-click auto-populating
  `CustomAnchorFrame` (right-click/Esc cancels). Validated via the existing
  `IsValidAuraTrackingAnchorFrame`.
- Expose anchor-point + relative-point dropdowns and X/Y offsets (backend
  `SetAuraTrackingPoint` already consumes these) for precise placement.

## 5. Registration (`NSUI.lua`)
Swap the `RebuildAuraTrackingOptionsMenu` DF-menu block (NSUI.lua:471-488) for a single
`BuildAuraTrackingUI(auratracking_tab)` call (mirroring
`BuildEncounterAlertsUI(encounteralerts_tab)` at NSUI.lua:524), storing the frame on
`NSUI` and repointing refresh hooks.

## Files touched
- `AuraTracking.lua` — model, migration, per-entry unit/sound/load, refresh hooks, group helpers.
- `UI/Options/AuraTracking.lua` — full UI rewrite (list + tabbed editor).
- `NSUI.lua` — registration.
- Localization strings as needed.

## Sequencing
1. Data model + migration (non-breaking; backend keeps working).
2. Backend unit/sound/load/filter logic.
3. New list + tab UI wired to backend.
4. Frame picker + anchor precision.
5. In-game verification (preview, enable/disable, groups, built-in locks, friendly/enemy filtering).

## Open confirmations
- Sound fires once on aura appear (not on refresh/stack change) — assumed yes.
- Per-entry/group Import/Export (as Encounter Alerts has) — out of scope for this pass
  unless requested.
