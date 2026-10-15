# TimeSlotPicker

The bookable start times of a court for one day: each chip shows the time, the court price and the price per person (« 60 DT · 15 DT/pers. »), with peak, discount, few-left and unavailable states.

## When to use
- Venue page and booking flow, under the day strip: choose a duration (60 / 90 min), then a start time.
- Group lessons with limited places reuse the same chips (« 1 place »).
- Not for a free time entry (time field) or occupancy reporting (owner heatmap).

## Anatomy & specs
| Part | Spec |
|---|---|
| Header | label (`label`) + duration SegmentedControl S (« 60 min · 90 min ») at the end |
| Period | « APRÈS-MIDI », « SOIR » in `overline`, `text-secondary`; `space-5` between periods |
| Grid | auto-fill, min 148px (2 columns on a phone); gaps `space-4` rows · `space-2` columns |
| Chip | min-height 64, padding `space-2` `space-3`, `radius-md`, 1px `border-strong`, `surface` |
| Time | `num-m`, `text`; peak adds a 16px `lightning` (fill) in `warning-text` |
| Prices | `num-xs`: court price `text-secondary` · price per person `text` |
| Tag | straddles the top edge at the inline end: « −20 % » success badge or hourglass + « 1 place » warning badge (20 tall) |
| Legend | `caption` items after a `border` hairline: Ta sélection · Heure de pointe · Prix réduit · Dernières places · Complet |

## States
- **Available**: hover border `text`, pressed `scale-press`, focus `focus-ring`.
- **Selected**: `accent` (Volt) fill, `on-accent` text and icons, leading check.
- **Peak**: lightning + higher price. **Discounted**: « −20 % » + reduced price. **Few left**: « 1 place ». One tag per chip; the discount wins.
- **Unavailable**: `surface-muted`, `border` hairline, time struck through, « Complet », skipped by the arrow keys.
- **Loading**: eight skeleton chips in a `SkeletonGroup` (« Chargement des créneaux… »).
- **Empty day**: EmptyState « Plus de créneau libre ce jour-là » with one action (« M’alerter si ça se libère »).

## Content
- Times « 18h00 »; money with `formatDT`; price per person = court price ÷ players (padel 4, football 10).
- Durations change prices, not the grid — Smash Padel Club: 60 min 60 DT (peak 80), 90 min 80 DT (peak 108), off-peak −20 %.
- The sticky bar repeats the choice with the per-person price: « 27 DT par pers. · 108 DT le terrain » + « Réserver 19h00 ».

## Accessibility
- The grid is a `radiogroup`; each chip is a `radio` named « 19h00, 80 DT, soit 20 DT par personne, heure de pointe ».
- Arrows move and select (mirrored in RTL), skipping unavailable slots; Home/End; one Tab stop.
- States never rely on colour: icon, tag text, strike-through and the legend explain them.

## Do / Don't
- Do keep unavailable slots visible (struck) so the rhythm of the day stays readable.
- Do recompute every price when the duration changes and keep the selection if that time still exists.
- Don't show only the court price.

## Props (web preview)
`slots` (array or `duration => slots`) · `value` · `onChange(key, slot)` · `duration` · `defaultDuration` · `durations` · `onDurationChange` · `players` · `label` · `showDuration` · `legend` · `minColumnWidth` · `loading` · `emptyTitle` · `emptyDescription` · `emptyAction`. See `index.d.ts`.

## Flutter
`MuTimeSlotPicker(slots:, selected:, onSelected:, duration:, durations: [60, 90], players: 4)` — `MuSegmentedControl` above a `GridView` with `SliverGridDelegateWithMaxCrossAxisExtent`; each chip is an `InkWell` card in a `Stack` (tag in `PositionedDirectional(top: -10, end: 8)`) wrapped in `Semantics(inMutuallyExclusiveGroup: true, selected:)`; loading uses `MuSkeleton`.
