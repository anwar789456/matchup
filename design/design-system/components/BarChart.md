# BarChart
Compare magnitudes: thin columns or horizontal bars, grouped or stacked series with 2px surface gaps, selective value labels, a per-category tooltip and a table twin.

## When to use
- Counts per day or hour (« Réservations · 14 derniers jours »), rankings (« Revenus par terrain », horizontal), a breakdown by sport — stacked when the day's total matters, grouped to compare sports side by side.
- Use LineChart for continuous trends, DonutChart for one part-to-whole at a glance, KpiCard for a single number.

## Anatomy & specs
- Card, title, subtitle, table toggle and legend as LineChart; legend keys are 10 × 10 rects, plus the sport icon for sport series.
- Columns ≤ 24px thick (62 % of the band, the rest is air), 4px rounded data end (`radius-xs`), square at the baseline; one baseline in `chart-axis`, gridlines 1px `chart-grid`, ticks `num-xs`.
- Grouped: bars side by side with 2px gaps; a sport icon (14px, `ink-900` glyph) sits inside each data end when the bar is ≥ 18 × 22.
- Stacked: 2px `surface` gap between segments, rounded end on the top segment only; series names (+ icon, `caption` `text-secondary`) beside the last stack when its segment is ≥ 16px tall (`directLabels`).
- Horizontal: 44px rows, 22px bars, category `body` `text` at the start, value at the tip; the value axis disappears when every bar is labelled. Height grows with the rows.
- Value labels `num-xs` `text`, selective: peak + latest (columns), every bar (horizontal), totals (stacked), none (grouped).
- Hover band `surface-muted` behind the category. Tooltip above the tallest mark (beside it when there is no room above): every series, then « au total ».

## Variants
`orientation` vertical | horizontal · `mode` grouped | stacked. A single series is one colour (`chart-1`) for every bar — never colour nominal bars by their value.

## States
Hover (band + tooltip) · keyboard focus (`focus-ring` around the category band) · table view (one column per series + Total) · loading (shimmering columns or rows) · refreshing · empty · error — as LineChart.

## Content
- Give a single series its unit word: `unitLabel="réservations"` → « 39 réservations ». Dates « 13 oct. » / « mar. 13 oct. »; money « 25 160 DT ».
- Rank largest first. Keep the sport order football → padel → basketball everywhere.

## Accessibility
- One tab stop; ← → move between categories; each category is `role="img"` with every value and the total; Esc hides the tooltip.
- Validator, sports in stack order (football → padel → basketball, adjacent pairs) on `surface`: Light PASS — CVD ΔE 25.2 (deutan), normal-vision 26.4; basketball 2.94:1 = contrast WARN → relief by direct labels, icons, tooltip and table. Night match: CVD / normal PASS, contrast PASS (4.94 / 4.46 / 5.88:1); lightness band FAIL for basketball (L 0.692 > 0.67, brand-fixed) — louder, not ambiguous.
- Green and orange never touch in a stack (padel sits between them); in grouped bars the icon inside each column is the second channel. `ink-900` glyphs on sport fills: 4.93 / 4.46 / 5.87:1.
- Single series `chart-1` PASS (4.42 / 4.74:1).

## Do / Don't
- Do keep 2px gaps and rounded data ends; don't outline bars or dim the others on hover.
- Don't label every bar of a dense chart; the axis, tooltip and table carry the rest.
- Don't pass more than 8 series; fold the tail into « Autres ».

## Props (web preview)
`title` · `subtitle` · `categories` · `series` · `orientation` · `mode` · `format` · `height` · `valueLabels` · `directLabels` · `unitLabel` · `categoryLabel` · `skeleton` · `refreshing` · `error` · `onRetry` · `emptyTitle` · `emptyDescription` · `emptyAction` · `view` · `defaultView` · `onViewChange` · `activeIndex` · `footer`. See `index.d.ts`.

## Flutter
`MuBarChart(title:, categories: [...], series: [MuSeries.sport(MuSport.football, data: [...]), ...], orientation: Axis.vertical, mode: MuBarMode.stacked, valueLabels: MuValueLabels.auto)` — a `CustomPainter` drawing `RRect.fromLTRBAndCorners(topLeft: 4, topRight: 4)` per data end; sport glyphs painted from `MuIcon` paths; one `Focus` + `Semantics` per category; table twin = `DataTable`.
