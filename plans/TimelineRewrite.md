# Plan: Replace the DetailsFramework timeline with a custom NSRT timeline component

> **Status:** investigated, scoped, not started.
> **Line references are anchored to commit `c110470`** (branch `feature/timeline-features`).
> Re-verify offsets with `grep -n "^function NSI:" Timeline.lua` before editing — this file
> moves a lot.

## Goal
Replace `DF:CreateTimeLineFrame` and all remaining DetailsFramework usage inside
`Timeline.lua` with a hand-rolled timeline widget that matches the NSRT visual system
(`UI/Components.lua` + its `STYLE` table). Reuse existing shared components where they
fit; add new shared components only where a real gap exists.

**This is a UI overhaul. No backend behaviour changes.** Notes, reminders, phases, boss
ability data, comms and saved variables all keep working exactly as they do today.

## Confirmed scope

**In scope**
- Custom timeline widget — no DF timeline, no reaching into DF internals.
- Shared window chrome component (title bar, scale bar, resize grip) to replace
  `DF:CreateSimplePanel`.
- Swap the remaining 15 trivial DF widget calls to `NSI.UI.Components` equivalents.
- Both surfaces: the standalone window **and** the embedded tab.

**Out of scope**
- The note editor (`UI/Reminders.lua:680`) and all import/export text boxes.
- Any other module's DF usage — DF stays in the `.toc` and is still used ~327 times
  elsewhere. This is one step in a longer migration, not the end of it.
- Comms, serialization, reminder processing, boss timeline data.

## Findings from the investigation pass

### DF surface inside `Timeline.lua` is narrow — 19 call sites

| Call | Count | Replacement |
|---|---|---|
| `DF:CreateTimeLineFrame` | 2 | **the new component** (standalone + embedded) |
| `DF:CreateLabel` | 7 | `NSI.UI.Components.CreateLabel` |
| `DF:GetTemplate` | 3 | vanishes with the widgets it styled |
| `DF:CreateDropDown` | 3 | `CreateDropdown` (option-table shape differs — needs an adapter) |
| `DF:CreateSimplePanel` | 1 | **new window chrome component** |
| `DF:CreateTextEntry` | 1 | `CreateTextEntry` |
| `DF:CreateSwitch` | 1 | `CreateCheckButton` |
| `DF:CreateButton` | 1 | `CreateButton` |

`DF:NewSpecialLuaEditorEntry` is **not** used in `Timeline.lua` — it lives in the
note/import/export UIs, which we are not touching.

### But the coupling to the timeline widget is deep

The code reaches into DF internals rather than using an API:

```
timelineFrame.body            33 refs
timelineFrame.options          9
timelineFrame.verticalSlider   7
timelineFrame.horizontalSlider 7
timelineFrame.headerFrame      6
timelineFrame.gridLines        6
timelineFrame.elapsedTimeFrame 5
timelineFrame.currentScale     5
timelineFrame.scaleSlider      4
```

`NSI:SetupTimelineHooks` (`Timeline.lua:7-145`) is 145 lines of pure monkey-patching:
overriding `OnMouseWheel` for zoom-to-cursor, reparenting `elapsedTimeFrame` into a
hand-made clipping container to fake a sticky ruler, and hiding DF's own gridlines so a
custom `gridOverlay` can render with correct z-order. We are already fighting the library
and losing — this whole function **disappears** in the rewrite.

### Composition of `CreateTimelineWindow` (`Timeline.lua:899-2322`, 1,424 lines)

Read in full. It is **not** densely DF-interleaved — the coupling is concentrated.

| Category | Lines | Notes |
|---|---|---|
| Ports near-verbatim (widget-agnostic logic) | ~700 | menu builders, row/header rendering, tooltips, category borders |
| Needs coordinate math re-derived | ~380 | drag hooks, the big `OnUpdate`, panning |
| Deleted — becomes native widget behaviour | ~180 | ruler override, slider poking, resize plumbing, `SetupTimelineHooks` |
| DF widget instantiation to swap | ~165 | panel, dropdowns, button, switch, labels |

Most of the file is either pure data construction or raw WoW frame code that merely
happens to be parented to DF frames. `on_create_line` (~90 lines) is all
`CreateTexture`/`CreateFontString` with zero DF. `BuildEditNoteMenuItems` (~105 lines)
already targets our own context-menu component.

## Contracts that must be preserved

### 1. Block data shape — this is what makes notes "just work"

`NSI:ShowReminderDialog` (`Timeline.lua:3105`) is the only place the widget crosses into
note-writing, and it is one field wide:

```lua
local bd      = isEdit and block.blockData or nil
local payload = bd and bd.payload or nil
local srcRaw  = payload and payload.srcRaw or ""
local existingSpellID = (bd and bd[5]) and tostring(bd[5]) or ""
```

Everything downstream is `string.match` against the raw note line (`text:`, `dur:`,
`ph:`, `time:`, `glowunit:`) feeding `RewriteNoteLine` / `AppendNoteLine` /
`DeleteNoteLine`.

**So: new block objects must expose `.blockData` holding the same tuple —
`{time, length, isAura, auraDuration, spellId, payload = {srcRaw = …}}`.** Honour that and
`ShowReminderDialog` and the whole notes path need zero edits.

Note this is a plain Lua table shape, *not* a DF type. Keeping it is not a lingering DF
dependency — it just avoids rewriting the data layer. Rename fields later if desired.

### 2. Mirror DF's callback hook names — worth several days

`timelineOptions` (`Timeline.lua:1352-1833`, 485 lines) is written entirely as lifecycle
callbacks: `on_enter`, `on_leave`, `on_create_line`, `on_refresh_line`, `block_on_enter`,
`block_on_leave`, `block_on_set_data`.

**Design the new widget to expose those same hook names and signatures**, plus `.body`,
`.options.pixels_per_second` and `.currentScale`. Then ~700 lines port with near-zero
edits and the geometry sections only need anchor references swapped.

This also lets you build the widget and drop it in behind an unchanged options table
first, then clean up hook naming as a separate cosmetic pass — instead of rewriting the
widget and its 485-line config at the same time.

### 3. Window position and scale are persisted

`Timeline.lua:903-909` passes `NSRT.NSUI.timeline_window` as the last argument to
`DF:CreateSimplePanel` — that is DF's panel-config table, and it persists **window
position and scale**. `UseScaleBar = true` in the same options table is where the scale
bar comes from.

The new window chrome must reimplement position/scale persistence against that same table
(or migrate it), or users silently lose their placement and zoom. ~20 lines, but it ships
broken if missed.

Separately: `NSRTTimelineData` (the saved variable) is written only by `EventHandler.lua:47`,
`Functions.lua:525` and `SlashCommands.lua:68`. **`Timeline.lua` never touches it** — no
migration work there.

## Components to build

### New: timeline widget (~1,400–1,850 lines total for this section)
DF's `Libs/LibDFramework-1.0/timeline.lua` is 1,446 lines. Functional equivalents needed:

| Piece | DF lines | Est. new |
|---|---|---|
| Block/row renderer (`TimeLine_LineMixin`) | ~443 | 450–600 |
| Viewport: scroll/zoom/refresh (`TimeLineMixin`) | ~534 | 350–450 |
| Construction + sliders + ruler | ~243 | 250–350 |
| Frozen header / track gutter | — | ~120 |
| Block widget pooling | — | ~100 |

**Do not skip pooling.** DF's is battle-tested; a naive renderer will stutter on a
10-minute fight × 40 tracks.

Expose a `TimeToX` / `XToTime` pair on the widget and delete the ambiguity described in
"Risk areas" below — do not reimplement the footgun.

### New: shared window chrome (~150–250 lines)
`CreateStyledFrame` (`UI/Components.lua:1902`) already gives movable, clamped, backdrop,
close button and `UISpecialFrames` registration — but **no title bar and no resize grip**.
`DF:CreateSimplePanel` has 27 call sites addon-wide, so build this generically; you will
want it again.

Evidence it is already missed: `ShowReminderDialog` hand-rolls a title with the comment
`-- CreateStyledFrame doesn't add one`, and `CreateTimelineWindow:919-975` hand-rolls a
resize grip with custom resize math (that grip code ports over as-is).

### Existing components that already fit
`UI/Components.lua` exports 26 components and is used 43× across the UI. `CreateButton`,
`CreateDropdown`, `CreateCheckButton`, `CreateLabel`, `CreateTextEntry`, `CreateScrollBox`,
`ShowContextMenu`, `ShowContextMenuAtFrame`, `CreateDialog` all apply directly.

## Risk areas — precise locations

**`Timeline.lua:2097-2251` — the throttled `OnUpdate`.** Gnarliest code in the file and
load-bearing:

- **Orphaned-drag recovery** (`2125-2167`) exists *because* a zoom refresh re-pools blocks
  mid-drag, so `OnMouseUp` never fires on the original block. Different pooling changes
  this behaviour — keep or redesign it deliberately, do not let it fall out by accident.
- **The `preserveZoom` dance** (`1708`, `2163`) must be set *before* `SetReminder`, because
  `SetReminder` → `ProcessReminder` → immediate timeline refresh would otherwise reset
  zoom. Easy to reintroduce as a bug.
- **Scroll-child vs viewport ambiguity.** Four separate places carry the comment
  *"body is the scroll CHILD, not the viewport — its GetLeft() already shifts with scroll."*
  This is exactly what `TimeToX`/`XToTime` should make impossible.

**Phase marker drag** (`UpdatePhaseMarkers` / `UpdateEmbeddedPhaseMarkers`) calls
`NSI:SetPhaseStart(encID, phaseNum, newTime)` where `newTime` derives from
`(markerLeft - bodyLeft) / (pixels_per_second × currentScale)`. `SetPhaseStart` itself does
not change; the inverse transform feeding it does. Same shape for edit-mode drag-retime.
This is where the last round of scaling bugs lived — regression-test carefully.

**Performance at scale** is the top overall risk, ahead of correctness.

## Files touched
- `Timeline.lua` — the port. ~800–1,200 of 3,687 lines touched.
- `UI/Components.lua` — add window chrome; add the timeline widget here or in a new
  `UI/TimelineWidget.lua` (prefer a new file — it is large enough to stand alone).
- `NorthernSkyRaidTools.toc` — register the new file if split out.

**Not touched:** the data layer (`Timeline.lua:146-898` — `GetBossAbilityLines`,
`GetMyTimelineData`, `PhaseFromTime`, `RewriteNoteLine`, `DeleteNoteLine`,
`AppendNoteLine`, `GetAllTimelineData`, ~750 lines) provided the block data shape is kept.

## Sequencing
1. **Component core** — viewport, scroll/zoom, ruler, row pooling, block rendering. Build
   against the existing `timelineOptions` table so it can be swapped in behind it.
2. **Window chrome** — title bar, scale bar, resize, position/scale persistence into
   `NSRT.NSUI.timeline_window`.
3. **Theming + interaction parity** — hover, tooltips, context menus, cursor line, drag ghost.
4. **Port the standalone window** — `CreateTimelineWindow`.
5. **Port the embedded tab** — plus phase markers and edit mode (drag retime, right-click add).
6. **Polish** — perf at scale, edge cases, regression.

## Estimate

| | Range |
|---|---|
| New component code | 1,400–1,850 lines |
| Developer days | 12–17 |
| Input tokens (raw) | 3.5–5.5M |
| Output tokens | 290–430k |

Prompt caching should cut effective billed input to roughly 30–40% of raw — `Timeline.lua`
(~55k tokens) and `UI/Components.lua` (~37k) get re-read constantly. The polish phase is
the token sink: many cheap turns, each dragging full file context.

The floor on wall-clock is in-game visual verification, which cannot be automated. There
is no test harness for this code.

## Open confirmations
- Whether the timeline widget lives in `UI/Components.lua` or its own file — plan assumes
  its own file.
- Whether to keep DF's hook names permanently or rename them in a follow-up cosmetic pass.
- Whether the resize min-bounds (currently 1100×550, equal to the default size — see
  `Timeline.lua:969`) are intentional or a leftover.
- Refresh/sync between the timeline and the Reminders note editor: both mutate the same
  note strings. This works today; verify it still fires after the rewrite. Regression
  check, not a code change.
