# StepIndicator

Where you are in a flow: « Étape 2 sur 8 » over a segmented bar for onboarding, or dots for carousels.

## When to use
- **Bar** for multi-step flows of known length: onboarding (8 steps), checkout, game creation.
- **Dots** for swipeable carousels: intro slides, venue photos, tips.
- Not for continuous progress (ProgressBar) or for switching views (tabs).

## Anatomy & specs
- Label row: « Étape 2 sur 8 » `label-s` `text-secondary` + optional step name « · Tes sports » `label-s` `text`; `space-2` above the track.
- Bar: one segment per step, 4px high, `space-1` gaps, `radius-xs`. Done = `primary` (ink · Volt in Night match), current = half `primary` over `border`, upcoming = `border`.
- Dots: 8px circles, `space-2` apart, centred. Current = 24 × 8 pill `primary`, done = `text-secondary`, upcoming = `border-strong`.
- Onboarding layout: app bar with a back IconButton « Retour » (start) and « Passer » tertiary S (end); the indicator under it with `space-4` side margins; the screen title starts `space-6` below.
- Carousel layout: dots `space-4` under the slide text, buttons « Passer » (tertiary) and « Suivant » (primary) under them.

## Variants
`bar` (label visible) · `dots` (label visually hidden; `showLabel` puts « 2 sur 4 » above).

## States
Done · current · upcoming. The current half-fill grows in over `duration-slow`; dots stretch over `duration-base`, `ease-move`.

## Content
- « Étape 2 sur 8 » with digits; add the step name when it helps orientation (« · Tes sports »).
- Custom flows keep the pattern: « Paiement · 2 sur 4 ». Carousels announce « Diapo 2 sur 3 ».
- « Passer » only when every remaining step is optional — it never skips consent or payment.

## Accessibility
- The track is `role="progressbar"` (1 → total) with `aria-valuetext` « Étape 2 sur 8 : Tes sports »; the visible label is hidden from AT to avoid a double reading.
- Current vs done is shown by shape (half segment, long pill), not only by colour.
- After moving to the next step, focus goes to the new step's title.

## Do / Don't
- Do keep the total stable — « sur 8 » never becomes « sur 9 » mid-flow.
- Do keep answers when the user goes back.
- Don't use dots for more than ~6 items, and don't make dots the only way to change slides.
- Don't colour the segments with sport colours.

## Props (web preview)
`step` · `total` · `variant` · `label` · `showLabel` · `title`. See `index.d.ts`.

## Flutter
`MuStepIndicator(step: 2, total: 8, variant: MuStepVariant.bar, title: 'Tes sports')` — a `Row` of `Expanded` 4px `DecoratedBox` segments (the current one holds an animated `FractionallySizedBox(widthFactor: .5)`), or `AnimatedContainer` dots (8 → 24 wide), with `Semantics(value: 'Étape 2 sur 8')`. Put the back `MuIconButton` and « Passer » `MuButton.tertiary` in the `AppBar`, not inside the indicator.
