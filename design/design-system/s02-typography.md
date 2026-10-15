# Typography

Words in Plus Jakarta Sans, numbers in Barlow Condensed, Arabic in IBM Plex Sans Arabic. All three are Google Fonts (SIL Open Font License); the woff2 files in `fonts/` are wired into `tokens.css`.

## Families

| Token | Stack | For |
|---|---|---|
| `--font-sans` | "Plus Jakarta Sans", system-ui, sans-serif | Every interface word |
| `--font-numeric` | "Barlow Condensed", "Plus Jakarta Sans", sans-serif | Scores, stats, prices, times, countdowns, levels |
| `--font-arabic` | "IBM Plex Sans Arabic", "Plus Jakarta Sans", sans-serif | The Arabic locale |

## Interface scale

| Style | Size / line | Weight | Use |
|---|---|---|---|
| `display` | 40 / 48 | 700, −0.02em | One per screen at most: celebrations, onboarding, marketing headers |
| `h1` | 32 / 40 | 700, −0.01em | Large app-bar titles, dashboard page titles |
| `h2` | 24 / 32 | 600, −0.01em | Section, sheet and modal titles; venue names on detail pages |
| `h3` | 20 / 28 | 600 | Card titles on detail screens, compact app-bar titles |
| `body-l` | 16 / 24 | 400 | Long text, mobile input values, dialog bodies |
| `body` | 14 / 20 | 400 | Default UI text: card details, table cells, helper text |
| `caption` | 12 / 16 | 400 | Timestamps, metadata, chart axes |
| `overline` | 11 / 16 | 700, 0.08em, uppercase | Eyebrows, stat labels, « EN DIRECT » |
| `label-l` | 16 / 24 | 600 | ADDITION: L and XL button labels, selected rows |
| `label` | 14 / 20 | 600 | ADDITION: S and M buttons, chips, tabs, input labels, table headers |
| `label-s` | 12 / 16 | 600 | ADDITION: status badges, tab-bar labels, counters |

The `label-*` styles are the body sizes at semibold, so buttons and chips never need a custom weight.

## Numerals

Set every number a person compares or watches change in Barlow Condensed with tabular figures, so digits never jump while a score rolls or a countdown ticks.

| Style | Size / line | Use |
|---|---|---|
| `score` | 48 / 48 | Live and final scores (BRIEF) |
| `num-hero` | 72 / 72 | Full-screen countdowns (« 14:59 ») and celebration counters |
| `num-xl` | 36 / 40 | Dashboard KPI values, wallet balance |
| `num-l` | 28 / 32 | Game time and price on featured cards, checkout total |
| `num-m` | 20 / 24 | Price per person and spots left on cards, padel sets |
| `num-s` | 16 / 20 | Countdowns inside buttons, table amounts, level values |
| `num-xs` | 13 / 16 | Level badges on avatars, axis numbers, compact set scores |

All numeral styles are semibold (600). Pair a big numeral with a small unit in the same family one step down: « 15 » in `num-l`, « DT » in `num-m`.

## Arabic

In the Arabic locale, swap `--font-sans` text for the `ar-*` styles: the same sizes with taller lines for Arabic ascenders and descenders (`ar-body` 14 / 24, `ar-h1` 32 / 48). Keep Western digits (0–9) and keep numbers in Barlow Condensed. Never letter-space Arabic and never set it in capitals.

## Rules

- Sentence case everywhere. Only `overline` is uppercase, and it gets its capitals from CSS (`text-transform`), not from the copy.
- Keep running text near 65 characters per line; long text uses `body-l`.
- Use one weight change per element: a semibold label beside regular metadata, never bold inside bold.
- In French, put a narrow no-break space before « : ; ! ? % » and inside « guillemets », a no-break space before « DT » and narrow spaces as thousands separators (« 1 250 DT »). The `formatDT`, `formatPercent` and `formatDate` helpers do it for you.
- Truncate single-line titles with an ellipsis and show the full text in a tooltip; never clip a price, a time or a count.
