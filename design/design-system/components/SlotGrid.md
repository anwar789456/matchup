# SlotGrid

A venue's planning — one row per court, one column per 30- or 60-minute slot — where you pick a run of free slots on one court and the summary bar prices it per person.

## When to use
- Venue page and booking flow when a club has several courts (« Arena Five · 3 terrains »): compare courts and times at a glance, then book.
- Desktop: inside a card. Mobile: full bleed (`flush`) with the summary pinned to the bottom (`sticky`).
- Use **TimeSlotPicker** for one court's start times, and the owner **Heatmap** for occupancy reporting.

## Anatomy & specs
| Part | Spec |
|---|---|
| Card | `mu-card`, padding `space-5` (`space-4` under 560 wide); legend, grid and summary `space-4` apart; `flush` drops radius and shadow |
| Legend | `caption` `text-secondary` keys with 24 × 16 swatches (`radius-xs`): Disponible · Ta sélection · Réservé · Bloqué · Heure de pointe · Promo · Ta réservation |
| Court column | 148 wide (128 narrow), sticky at the inline start; name `label` + optional 14 icon (`umbrella` for « Couvert ») · detail `caption` `text-secondary`; once scrolled, a `border` rule and `elevation-1` |
| Time row | corner « Tarifs à l’heure » in `caption`; times `num-xs` « 20h00 », half hours in `text-secondary` |
| Cell | 56 high, `radius-xs`, `space-1` gaps; hourly court price in `num-s` |
| Summary | `border` hairline, `space-4` above; « Terrain 2 · 20h00–21h30 » `label-l` · « 1 h 30 · 90 DT · 15 DT/pers. pour 6 joueurs » `body` `text-secondary` with the per-person price in `label` `text`; Button L « Réserver » (narrow: XL, full width, under the text) |

| Step | Cell width | Narrow (< 560) |
|---|---|---|
| 30 min (default) | 68 | 64 |
| 60 min | 96 | 80 |

- The grid scrolls horizontally; while more slots follow, the end edge fades over `space-10`. It opens scrolled to the selection.
- `sticky` pins the summary to the bottom of the page: `surface`, `elevation-2-up`, `z-sticky`.

## States
- **Available**: `surface`, 1px `border-strong`. Hover: 1px `text` + `opacity-hover` wash; pressed: scale 0.96; focus: `focus-ring` — `duration-fast`, `ease-enter`.
- **Selected**: `accent` fill, `on-accent` ink, `check` 16 on the first cell; a run reads as one bar (inner corners square, gaps bridged).
- **Booked**: `surface-muted`, 1px `border`, « Réservé » `label-s` `text-secondary`, one block across its run.
- **Blocked**: 135° hatching in `border-strong` over `surface`, a `lock-simple` chip « Bloqué » (or the run's label, « Tournoi »).
- **Peak**: `lightning` 14 (fill) in `warning-text` before the price. **Discounted**: « −20 % » pill (`success-soft`, `success-text`, `label-s`) over the new price and the old one struck in `caption`.
- **Mine**: `surface-inverse` fill, `text-inverse`, Avatar XS + « Toi ».
- **Picking**: tap a free slot to start a run, tap the next one to lengthen it, an end to shorten it, a lone cell to clear it. A slot on another court, or past a taken one, starts a new run; `maxSlots` caps the length.
- **Idle summary**: « Choisis un créneau » + « Touche un créneau libre, puis le suivant pour allonger. », button disabled.
- **Empty day**: EmptyState « Aucun créneau ce jour-là » + « Voir demain » (secondary M). **Loading**: a skeleton grid.

## Content
- Cells show the court's hourly price, as the corner says; the summary always adds the share per person: total ÷ `players` (default 10).
- Times « 20h00 », durations « 1 h 30 » / « 30 min », money with `formatDT`, promo with a true minus « −20 % ».
- **Data**: `courts` = `{ id, name, detail, icon, price, slots }`; `slots` is the court's timeline from `start` to `end` as segments `{ status: 'available' | 'booked' | 'blocked' | 'mine', span, price, peak, discount, label }` — time left unfilled is available.
- The selection is `{ court, from: '20:00', to: '21:30' }` (`value` / `onChange`); `onBook(value)` fires on « Réserver ».

## Accessibility
- `role="grid"` named by `label`; court names are row headers, times column headers. One Tab stop: ← / → move between blocks (swapped in RTL), ↑ / ↓ change court, Home / End (with Ctrl: first / last court), Enter or Space picks.
- Cells read « Terrain 2, 20h00, disponible, heure de pointe, 80 DT de l’heure »; free cells carry `aria-selected`, the others `aria-disabled`. The summary is `aria-live="polite"`.
- Every state has a word or icon beside its colour, and the legend spells them out. Cells are at least 64 × 56.
- In RTL the court column sticks to the right and time runs right to left; digits never mirror.

## Do / Don't
- Do keep booked and blocked runs on the grid — the rhythm of the day helps people choose.
- Do show the per-person price before « Réserver »; never only the court total.
- Don't use Volt for anything but the selection — « Ta réservation » is ink.
- Don't drop the legend on the first screen where the grid appears.

## Props (web preview)
`courts` · `start` · `end` · `step` · `value` · `defaultValue` · `onChange` · `players` · `onBook` · `bookLabel` · `you` · `maxSlots` · `legend` · `summary` · `sticky` · `flush` · `label` · `priceNote` · `skeleton` · `emptyTitle` · `emptyDescription` · `onNextDay` · `cellState` (preview only). See `index.d.ts`.

## Flutter
`MuSlotGrid(courts: [...], start: '17:00', end: '23:00', step: 30, value:, onChanged:, players: 10, onBook:, sticky: true)` — a pinned court column beside a horizontal `SingleChildScrollView` whose time header shares its `ScrollController`; each row is a `Row` of fixed-width blocks (span × cell + gaps). Free cells are `InkWell`s in `Semantics(button: true, selected:, label: …)`, with arrow keys through `Shortcuts` + `FocusTraversalGroup`. On mobile the summary lives in the screen's sticky bottom bar.
