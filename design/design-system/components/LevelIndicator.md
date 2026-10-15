# LevelIndicator

The player level on the 1,0–7,0 scale with its band — « 3,5 Intermédiaire » — shown inline, as a 6-segment bar, or as a compact badge for cards.

## When to use
- **Inline** wherever a player is named: lists, lineups, join requests, chat headers. Size S in dense rows.
- **Bar** on the profile and after onboarding, where players want to see how far the next band is.
- **Badge** on game and player cards where space is tight — its four bars encode the band without colour.
- Add a **trend** to show progress over a period; add **ai + confidence + reason** when the value is an AI estimate.
- Not for a game's level range (« Niveau 3,0–4,5 ») — that is a Chip.

## Anatomy & specs
| Part | Spec |
|---|---|
| Value | `formatLevel` « 3,5 »; `num-s` (inline M) · `num-xs` (inline S, badge) · `num-l` (bar M) · `num-xl` (bar L); `text` |
| Band | Débutant < 2,5 ≤ Intermédiaire < 4,0 ≤ Avancé < 5,5 ≤ Expert (`levelLabel`); inline `body`/`caption` `text-secondary`, bar `label` `text` |
| Track | 6 segments (1→2 … 6→7), 8px high, 2px gaps, each `radius-xs`; ground `border`, fill `primary` (ink · Volt in Night match) |
| Marker | 4 × 20px, `radius-full`, `primary`, 2px `surface` ring, centred on the exact level |
| Bands row | 4 equal columns (each band spans 1,5 points = 25 %), `caption` `text-secondary`, current band `label-s` `text`; 1 × 6px `border-strong` ticks at 2,5 · 4,0 · 5,5 |
| Badge | 24px (S 20px) pill, `surface-muted` + 1px `border` ring; 14 × 12 glyph of 4 rising bars (filled up to the band, others `border-strong`) + `num-xs` |
| Trend | `trend-up` 16 + « +0,2 » `num-xs` in `success-text` · `trend-down` + « −0,1 » in `error-text` · `minus` + « Stable » `text-secondary`; period `caption` |
| AI | « Estimation IA » pill (`ai-soft`, `ai-text`, `sparkle` fill 14); confidence = 3 dots 6px (`text` / `border-strong`) + `caption`; reason `caption` `text-secondary`, above it a 1px `border` rule |

Gaps: value → band `space-2` (S `space-1`); bar sections `space-3`.

## Variants
`inline` (default, S / M) · `bar` (M / L) · `badge` (S / M; `showBand` adds the word).

## States
- Bands are never coloured with sport or status colours — only ink / `primary` and neutrals.
- A new value slides the fill and marker over `duration-counter`, `ease-move` (static under reduced motion).
- Trend: up · down · stable. AI estimate: confidence low · medium · high.

## Content
- One decimal with a comma: « 3,5 » — never « 3.5 » or « 3,50 ». Band words are capitalised: Débutant, Intermédiaire, Avancé, Expert.
- Trends use a real minus and a period: « −0,1 sur 30 jours ».
- AI copy says why and stays editable: « Basé sur tes 12 derniers matchs et 9 avis de coéquipiers. » + « Ajuster ».

## Accessibility
- Inline and badge read « Niveau 3,5 sur 7, Intermédiaire » (visually hidden words); the badge's glyph and digits are hidden from AT.
- The bar track is `role="meter"` (1–7, `aria-valuetext` « 3,5 sur 7, Intermédiaire »), named by `label`.
- Trends are announced in words (« en hausse de 0,2 »), never by colour or arrow alone.
- RTL: the bar fills from the start side; signed numbers keep their order (`unicode-bidi: plaintext`).

## Do / Don't
- Do show the band word next to the number — « 3,5 » alone means nothing to a newcomer.
- Do pair every AI estimate with a reason and « Ajuster ».
- Don't colour bands green / orange / red, and don't use Volt as the fill on a light ground (use `primary`).
- Don't round on the bar — the marker sits at the exact level.

## Props (web preview)
`level` · `variant` · `size` · `label` · `showBand` · `trend` · `trendLabel` · `ai` · `confidence` · `reason`. See `index.d.ts`.

## Flutter
`MuLevelIndicator(level: 3.5, variant: MuLevelVariant.bar, label: 'Niveau football', trend: 0.2, trendLabel: 'sur 30 jours', ai: false, confidence: MuConfidence.high, reason: …)` — inline is a `Text.rich` (`MuType.numS` + `MuType.body`); the bar is a `Stack` of a `Row` of 6 `Expanded` `ClipRRect` segments with `FractionallySizedBox` fills and an `AnimatedAlign` marker (`MuMotion.counter`), wrapped in `Semantics(value: '3,5 sur 7, Intermédiaire')`; the badge is a `StadiumBorder` `DecoratedBox` with a `CustomPaint` 4-bar glyph.
