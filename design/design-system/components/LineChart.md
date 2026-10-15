# LineChart
Change over time on one y-axis: 2px lines, a 10 % area wash, end labels, a crosshair tooltip on hover and keyboard focus, and a table twin.

## When to use
- Trends over time: « Revenus · 30 derniers jours », month-to-date « Ce mois vs mois dernier ».
- One measure per chart. Two measures of different scale (revenue and bookings) are two charts — never a second y-axis.
- Up to 4 series side by side; past that, small multiples. A single current value is a KpiCard.

## Anatomy & specs
- Card: `mu-card`, padding `space-5`, gap `space-4`. Title `h3`, subtitle `caption` `text-secondary`. « Voir le tableau » is a tertiary S button top-right; under 520px of card width it shows its icon only and keeps its label for assistive tech.
- Legend (≥ 2 series): line keys 18 × 2 (dashed for the previous period), `label-s` `text`, gap `space-5`.
- Plot: `height` includes the x band (default 280). Y ticks: clean steps (1 / 2 / 2,5 / 4 / 5 × 10ⁿ) from 0, compact `num-xs` `text-secondary` (« 0 », « 2,5 k DT », « 7,5 k DT »). Gridlines 1px solid `chart-grid`; baseline 1px `chart-axis`.
- X labels `caption` `text-secondary`, thinned automatically and anchored on the latest point (weekly for daily dates); `xTicks` picks them.
- Lines 2px, round. Area = the series colour at 10 % (single series). End dot r 4 with a 2px `surface` ring; end label `num-xs` `text` with a surface halo. Room is reserved on the right; colliding end labels are dropped, never stacked.
- Crosshair 1px `chart-axis`; active dots r 4 + ring. Tooltip: `surface-elevated`, `radius-sm`, `elevation-2`, padding `space-2` `space-3`; date `label-s` `text-secondary`; rows = key 12 × 3 · value `num-s` · series `caption`. It sits on the emptier side of the point (above it in the lower half).

## Variants
- **Single series** — `chart-1`, area wash, no legend (the title names it).
- **Comparison** — `style: 'previous'`: dashed 6/4 in `chart-axis`, no area. The only dashed style in charts; gridlines are never dashed.
- **Multi-series** — `chart-1…8` in fixed order, or sport colours when the series are sports (icons join the legend).

## States
Hover (crosshair + tooltip; the latest input wins) · keyboard focus (a focus ring around the focused dots: 2px `surface` gap + 2px `focus`) · table view · loading (shimmering area silhouette + tick placeholders) · refreshing (previous render at 45 % opacity, `aria-busy`) · empty (ghost grid + one sentence + one action) · error (`warning-circle` on `error-soft` + « Réessayer »).

## Content
- Title = what + window (« Revenus · 30 derniers jours »); subtitle = scope and unit (« Arena Five · 3 terrains · en DT »).
- Dates « 13 oct. » on the axis, « mar. 13 oct. » in tooltips and the table; money « 5 130 DT »; a missing value prints « — ».

## Accessibility
- One tab stop per plot; ← → step, Home / End jump, Esc hides the tooltip. Each point is `role="img"` (« mar. 6 oct. : 4 580 DT »); the tooltip is `aria-hidden` because the point says the same.
- The table view is the WCAG-clean twin: `<table>` with caption and scoped headers in a focusable scroll region.
- Validator on `surface` #FFFFFF / #0F1B2E: `chart-1` PASS (4.42 / 4.74:1). Comparison pair `chart-1` + `chart-axis`: CVD ΔE 20.8 (protan, Light) / 15.2 (deutan, Night), normal-vision ΔE 23.5 / 15.5 — PASS. `chart-axis` is 2.10:1 in Light = contrast WARN, relieved by the dash, legend, tooltip and table. `text-secondary` was rejected for this role: normal-vision ΔE 13.2 < 15 beside `chart-1` in Light. (The grey fails the chroma floor by design: it is de-emphasis, not a categorical slot.)
- The plot stays left-to-right in RTL (time and numbers never mirror); header, legend and table follow the reading direction.

## Do / Don't
- Do start amounts at 0 and label the end, not every point.
- Don't add a second y-axis, dashed gridlines, or smoothing that invents values.
- Don't put filters in the card; one filter row above scopes every chart.

## Props (web preview)
`title` · `subtitle` · `x` · `xTicks` · `series` (`id`, `label`, `data`, `color`, `style`, `area`) · `format` · `height` · `area` · `endLabels` · `yMax` · `skeleton` · `refreshing` · `error` · `onRetry` · `emptyTitle` · `emptyDescription` · `emptyAction` · `view` · `defaultView` · `onViewChange` · `activeIndex` · `tableLabel` · `footer`. See `index.d.ts`.

## Flutter
`MuLineChart(title:, subtitle:, x: [...], series: [MuSeries(label: 'Ce mois · oct.', data: [...]), MuSeries(label: 'Mois dernier · sept.', data: [...], style: MuSeriesStyle.previous)], format: MuChartFormat.dt, height: 280)` — a `CustomPainter` inside `MuChartCard`. Pointer via `MouseRegion` + `GestureDetector` snapping to the nearest x; keyboard via `Focus` + `Shortcuts` (arrows, Home, End, Esc); one `Semantics` node per point; the table twin is a `DataTable` in a `SingleChildScrollView`.
