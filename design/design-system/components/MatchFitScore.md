# MatchFitScore

« 92 % compatible » — how well a game, a partner or a team fits the person, as a pill or a gradient ring, always with the why behind the number.

## When to use
- **pill** on game cards, suggestion cards, player rows and search results — small, tappable for the why.
- **ring** on a game or partner detail page, with the factors listed beside it.
- Only for AI-computed fit. Plain facts (distance, level range) stay plain text.

## Anatomy & specs
| Size | Height / diameter | Value | Label | Sparkle |
|---|---|---|---|---|
| Pill S | 24, padding 6 / 10 | `num-xs` | `label-s` | 14 |
| Pill M | 28, padding 8 / 12 | `num-s` | `label-s` | 16 |
| Ring M | 64, stroke 6 | `num-m` + `num-xs` « % » | `label-s` | 12 |
| Ring L | 96, stroke 8 | `num-l` + `num-s` « % » | `label-s` | 12 |

- Pill: `ai-soft` fill, 1px `--ai-gradient` border, sparkle + value in `ai-text`, label in `ai-text`, `radius-full`. With factors it becomes a button with a 14px caret (rotates 180° when open), hit area 44.
- Ring: `ai-soft` track, the arc stroked with `--ai-gradient`, round caps, from 12 o'clock clockwise; fills from 0 over `duration-counter` on `ease-move`. Value centred in `text`, « % » in `text-secondary`; « compatible » under it with a sparkle in `ai-text`.
- Why list: rows gap `space-3`; a 32px icon disc (`ai-soft` / `ai-text`) + factor in `label` + evidence in `caption` `text-secondary`. Then a 1px `border` rule and the provenance note in `caption`.
- Popover: `surface-elevated`, `radius-lg`, `elevation-2`, padding `space-4`, 312 wide, `space-2` under the pill, `z-popover`; header « Pourquoi 92 % ? » (`label`) + AiLabel S.

## States
- **Default** (≥ 60): AI colours, filled sparkle.
- **Low** (< `lowThreshold`, 60): neutral — `surface-muted` pill with a `border-strong` outline, value in `text`, regular sparkle in `text-secondary`; the ring arc in `text-secondary` on a `border` track. No gradient, no celebration.
- Factors against the fit: transparent disc with a 1.5px `border-strong` ring, icon in `text-secondary`, wording that states the gap (« Niveau plus élevé »).
- Pill button: hover wash `opacity-hover`, press 0.98, `focus-ring`; open = caret up.

## Content
- Always « 92 % compatible » (narrow space before %). Round to whole numbers.
- Factors are evidence: « Niveau proche · Toi 3,5 · partie 3,0–4,5 », « Dispo jeudi soir », « À 2,4 km », « A déjà joué avec Mariem K. ».
- Low scores say what doesn't fit, kindly and factually: « Niveau plus élevé · Partie 4,5–5,5 · toi 3,5 ».

## Accessibility
- The pill text reads « 92 % compatible »; as a button it adds « voir pourquoi », has `aria-expanded` and controls the popover (a `dialog` labelled by its header). Esc and outside taps close it; focus returns to the pill.
- The ring is an `img` named « 92 % compatible ». Factors carry a hidden « En faveur : » / « En défaveur : ».
- Level of fit is never colour alone: number + words + factor list.

## Do / Don't
- Do show the factors wherever the score drives a decision.
- Do keep the low state honest and quiet — still worth showing.
- Don't sort a list by fit without saying so (« Triées par compatibilité »).
- Don't show a fit for people who haven't shared their level or availability — ask instead.

## Props (web preview)
`value` · `variant` · `size` · `label` · `factors` · `breakdown` · `open` / `defaultOpen` · `onOpenChange` · `lowThreshold` · `note`. See `index.d.ts`.

## Flutter
`MuMatchFitScore.pill(value: 92, factors: [...])` and `.ring(value: 92, size: MuFitSize.l, factors: [...])`. Ring: a `CustomPainter` drawing the track and an arc with a `SweepGradient` (ai-500 → info), animated by a `TweenAnimationBuilder` (600 ms). Popover: `MenuAnchor`/`OverlayPortal`; on phones open the why in a bottom sheet.
