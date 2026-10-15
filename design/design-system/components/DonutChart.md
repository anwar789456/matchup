# DonutChart
Part-to-whole at a glance: up to 6 segments with 2px surface gaps, the total in the hole, a legend with values and shares, and a highlighted segment on hover or focus.

## When to use
- One whole split into ≤ 6 parts compared roughly: « Réservations par sport », « Moyens de paiement ».
- Use a stacked BarChart when parts must be compared precisely or over time; never a donut for 2 parts (use a KpiCard) or for close values.

## Anatomy & specs
| Size | Ring | Use |
|---|---|---|
| 200 | 32 | dashboard card (default) |
| 168 | 28 | half-width card |

- Segments run clockwise from 12 o’clock, largest first, separated by a 2px `surface` gap. Colours: `chart-1…6` in order, or the sport colours.
- Sport segments carry their icon at mid-ring (18px, `ink-900` glyph) when the arc fits.
- Centre: total `num-xl` `text` + `caption` `text-secondary` (« réservations », « DT encaissés »).
- Legend rows 44px, `radius-sm`, padding `space-3`: key 10 × 10 · sport icon · label `body` · value `num-s` · « · » · share `num-s` `text-secondary` (« 412 · 61 % »). Beside the ring, max 400px wide; below it when the card is under 460px.

## States
- **Hover / focus**: the segment lifts 4px, the others drop to 45 % opacity, its legend row gets `surface-muted`, and the hole becomes the readout — value `num-xl`, name `label-s`, « 29 % du total » `caption`. This is the donut’s tooltip: it never covers a segment or the legend. Esc restores the total.
- **Table view** (label · value · part, with a total row) · **loading** (shimmering ring + rows) · **refreshing** · **empty** (message and action only) · **error**.

## Content
- Shares are whole percentages that add up to 100 % (largest remainder). Past 6 segments the tail folds into « Autres » in `chart-axis` grey.
- Money in the hole drops its unit (« 48 920 ») and puts it in the caption (« DT encaissés »).

## Accessibility
- The legend rows are the focus path: one tab stop, ↑ ↓ to move; each row reads « Padel 198 · 29 % ».
- Validator, ring order including the wrap pair (last ↔ first): `chart-1…4` Light PASS — CVD ΔE 9.1 (protan), normal-vision 22.9; aqua 2.82:1 and yellow 2.17:1 = contrast WARN → relief: every value and share is printed in the legend and the table. Night match PASS — CVD 8.4, normal 19.8, all ≥ 3:1.
- Sports: in a 3-segment ring football and basketball always touch — CVD ΔE 5.5 (protan) FAIL, as the brief warns. Shipped mitigation: an icon on every segment (`ink-900` glyph 4.93 / 4.46 / 5.87:1), 2px gaps, legend icons + values, table view. Prefer a stacked bar (green and orange never touch there) when sport identity must survive at a glance.

## Do / Don't
- Do keep each colour with its entity when the data is filtered.
- Don't add a 7th colour, labels around the ring, or a 3D / exploded look.

## Props (web preview)
`title` · `subtitle` · `data` (`label`, `value`, `color`, `icon`) · `format` · `total` · `totalLabel` · `size` · `thickness` · `categoryLabel` · `valueLabel` · `skeleton` · `refreshing` · `error` · `onRetry` · `emptyTitle` · `emptyDescription` · `emptyAction` · `view` · `defaultView` · `onViewChange` · `activeIndex` · `footer`. See `index.d.ts`.

## Flutter
`MuDonutChart(title:, data: [MuSlice.sport(MuSport.football, 412), ...], totalLabel: 'réservations', size: 200, thickness: 32)` — a `CustomPainter` with `Path.arcTo` segments and 2px surface separators; an `AnimatedSwitcher` (`duration-fast`) in the centre swaps total ↔ readout; the legend is a `Column` of `FocusableActionDetector` rows that drive the highlighted index.
