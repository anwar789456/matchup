# Sparkline
A 12-point trend glyph: a 2px line ending in a dot, the past de-emphasised and the current period in the series accent.

## When to use
- Inside a KpiCard, a list row or a profile stat, next to the number it explains (« Niveau padel 3,5 ▲ » over 10 matches).
- Only as a supplement: the figure beside it carries the value. When people must read values, use LineChart.

## Anatomy & specs
| Size | Use |
|---|---|
| 64 × 20 | inline in a row |
| 96 × 32 | KPI card (default) |
| 160 × 48 | wide card |

- Line 2px, round caps and joins, straight segments (no smoothing). End dot r 4 (8px) with a 2px `surface` ring; on another ground set `--mu-ring`.
- Insets: 2px at the start, 6px at the end, top and bottom, so the dot and its ring never clip.
- Wash (optional): the series colour at 10 % (muted tone: `text-secondary` at 8 %).
- Domain: data min → max; pass `min` / `max` for a fixed scale (levels 1,0–7,0).

## Variants
- **muted** (default): the past in `text-secondary`, the last segment and the dot in the series colour (`chart-1`).
- **accent**: the whole line in the series colour; use a sport (`football`, `padel`, `basketball`) when the trend belongs to one.
- **area**: adds the wash.

## States
- **Missing values** (`null`) break the line. A **flat** series draws a centred line.
- **Not enough data** (< 2 values): a `chart-axis` hairline labelled « Pas encore assez de données pour une tendance ».
- **Loading**: a core `Skeleton` block of the same size.

## Content
- Feed about 12 points, oldest → current (12 days, 12 weeks, 10 matches); name the window in the label or next to it.
- Pair it with a signed delta: `caret-up` / `caret-down` + « +0,4 » in `num-xs`, `success-text` / `error-text`.

## Accessibility
- `role="img"` + `aria-label`; the default reads « Tendance sur 12 points : de 4 380 DT à 5 130 DT ». Pass `label` to name the window.
- Validator on `surface` (#FFFFFF / #0F1B2E): `chart-1` PASS (4.42 / 4.74:1); `text-secondary` line 5.43 / 8.23:1. Football (3.49 / 4.94:1) and padel (3.87 / 4.46:1) PASS. Basketball 2.94:1 in Light = contrast WARN → relief: the level and its delta are printed beside it. In Night match basketball sits at OKLCH L 0.692, above the 0.67 band (brand colour, fixed in both themes): louder, never ambiguous.
- No hover layer by design: it is a glyph; the value it supports is always visible text.

## Do / Don't
- Do keep one grammar across the product: muted past, accent present.
- Don't add axes, labels or tooltips — promote it to a LineChart.
- Don't set text in the sparkline's colour.

## Props (web preview)
`values` · `width` · `height` · `tone` · `color` · `area` · `min` · `max` · `format` · `label` · `skeleton`. See `index.d.ts`.

## Flutter
`MuSparkline(values: [...], tone: MuSparkTone.muted, color: MuChartColor.chart1, area: false, size: const Size(96, 32), semanticLabel: 'Tendance sur 12 jours : de 4 380 DT à 5 130 DT')` — a `CustomPainter` (one `Path`, `StrokeCap.round`, `StrokeJoin.round`; the ring is a surface-coloured circle painted under the dot) inside `Semantics(image: true)`.
