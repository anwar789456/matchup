# KpiCard
A dashboard figure tile: a label, one big number in `num-xl`, its change against a named period, an optional 12-point sparkline and an optional AI insight.

## When to use
- For the 3–5 numbers a dashboard leads with. The venue-owner row is Taux d’occupation · Revenus du jour · Réservations · No-shows, 4-up at desktop width (4 columns, `grid-desktop-gutter` 24).
- One figure per tile. When the reader must compare values or see a shape, use LineChart or BarChart.
- Never a bare number: give a delta vs a named period, a sparkline, or a `note` saying why there is none.

## Anatomy & specs
| Part | Spec |
|---|---|
| Card | `mu-card` (`surface`, `radius-md`, `elevation-1`), padding `space-5`, gap `space-2` |
| Label | `label`, `text-secondary`, sentence case, no colon |
| Value | `num-xl` 36/40 (Barlow Condensed, tabular), `text`; optional unit in `num-m` `text-secondary` (« 5 130 DT ») |
| Sparkline | 96 × 32 at the end of the value row, bottom-aligned (see Sparkline) |
| Delta | trend icon 16 + signed value `num-s` + period `caption` `text-secondary`; gaps `space-1` / `space-2` |
| AI insight | `ai-soft` block, `radius-sm`, padding `space-2` `space-3`; « IA » `label-s` `ai-text` + sparkle; text `caption`; dismiss 24 (44 hit area) |

## Colours
| Delta | Colour | Icon |
|---|---|---|
| Up and good · down and good | `success-text` | `trend-up` / `trend-down` |
| Up and bad · down and bad | `error-text` | `trend-up` / `trend-down` |
| Flat | `text-secondary` | `minus` |

## States
- **Default** with delta, sparkline optional. Set `upIsGood={false}` for no-shows, cancellations and refunds: a rise turns `error-text`.
- **No comparison**: a `caption` note replaces the delta (« 1er mois sur MatchUp — comparaison dès novembre »).
- **Loading**: the label stays; value, sparkline and delta shimmer as core `Skeleton` blocks inside a `SkeletonGroup`.
- **Error**: « — » in `text-disabled` keeps the height; `warning-circle` + `caption` in `error-text` + link « Réessayer ».
- **Refreshing** (a filter changed): keep the last figure on screen; never flash a skeleton.

## Content
- Values: « 81 % », « 5 130 DT » (or « 5 130 » + unit « DT »), « 39 ». Deltas: percent « +12 % », points for rates « +8 pts », counts « +4 », money « +620 DT »; the minus is « − ».
- Always name the period: « vs mar. dernier », « vs sem. dernière », « vs sept. ».
- An insight is one sentence: observation + lever (« 4 sur 7 à 22h : un acompte de 5 DT les réduirait. »).

## Accessibility
- Direction is never colour alone: trend icon + sign + a visually hidden « (en hausse, défavorable) ».
- Text on `surface`, Light / Night match: `success-text` 5.20 / 7.62:1, `error-text` 5.35 / 7.15:1, `text-secondary` 5.43 / 8.23:1.
- The sparkline is `role="img"` with a summary; the value and delta carry the meaning (its validator results are in Sparkline).
- « IA » `ai-text` on `ai-soft` 4.63 / 6.03:1; the dismiss is named « Masquer la suggestion ».

## Do / Don't
- Do keep the value in tabular `num-xl`: the brand's scoreboard rule overrides the dataviz default of proportional figures.
- Do say against what you compare; a delta without a period is noise.
- Don't colour the value itself; only the delta carries success or error.
- Don't put filters inside a tile; one filter row scopes the whole dashboard.

## Props (web preview)
`label` · `value` · `unit` · `delta` · `deltaFormat` · `deltaText` · `period` · `upIsGood` · `trend` · `trendTone` · `trendColor` · `trendFormat` · `trendLabel` · `note` · `insight` · `insightWhy` · `onDismissInsight` · `skeleton` · `error` · `onRetry`. See `index.d.ts`.

## Flutter
`MuKpiCard(label: 'Revenus du jour', value: '5 130', unit: 'DT', delta: 12, deltaFormat: MuDeltaFormat.percent, period: 'vs mar. dernier', upIsGood: true, trend: [...], insight:, onDismissInsight:, loading:, error:, onRetry:)` — a `StatelessWidget` over `MuCard` with a `Column`; the value row is a `Row(crossAxisAlignment: CrossAxisAlignment.end)` holding `MuSparkline`. Switch skeleton ↔ content with `AnimatedSwitcher` (`duration-base`); wrap in `Semantics(label:)` that merges label, value and delta into one announcement.
