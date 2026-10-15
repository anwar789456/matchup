# Countdown

Time left in Barlow numerals: « 14:59 » to claim a spot, « Dans 2 h 15 min » before kick-off, « 2 j 04 h 12 min » blocks before registration closes.

## When to use
- **Clock** (mm:ss) for short holds under an hour: a freed spot to claim, a payment window.
- **Relative** for starts: games, sessions, tournaments.
- **Blocks** for deadlines days away: tournament registration, early-bird prices.
- **Hero** for the full-screen claim takeover.

## Anatomy & specs
| Size | Clock / relative | Blocks tile | Unit | Icon | Layout |
|---|---|---|---|---|---|
| S | `num-s` | 40px, `num-m` | `caption` | 16 | inline |
| M | `num-m` | 56px, `num-l` | `caption` | 20 | inline (blocks stacked) |
| L | `num-l` | 72px, `num-xl` | `label-s` | 24 | stacked |
| Hero | `num-hero` | 104px, `num-hero` | `label` | 28 | stacked, centred |

- Inline: icon · label `label` `text-secondary` · « · » · value. Stacked: icon + label row above the value, `space-2` apart (hero `space-1`).
- Icons: `timer` (clock), `clock` (relative), none for blocks; `hourglass-simple-low` once expired.
- Tiles: `surface-muted` with a 1px `border` ring, `radius-md` (S `radius-sm`), `space-2` apart (L / hero `space-3`); unit under each tile, `space-1`.
- Digits are tabular, so nothing shifts while it ticks.

## States
- **Running**: ticks every second.
- **Urgent** (under `urgentAt`, default 5 min): digits and icon `error-text`, tiles `error-soft`, the icon pulses (`duration-pulse`). Blocks without a label show the timer before the tiles.
- **Expired**: « Temps écoulé » or a custom label (« La partie a commencé », « Inscriptions closes ») with the hourglass in `text-secondary`; `onExpire` fires once.
- Reduced motion: no pulse — colour, icon and the number still mark urgency.

## Content
- Labels are phrased to precede a duration: « Place réservée pendant », « Elle est à toi pendant », « Inscriptions closes dans ». Avoid « avant » + mm:ss — it reads as a time of day.
- Relative: « Dans 2 h 15 min », « Dans 1 j 4 h », « Dans < 1 min » (no-break spaces inside).
- Block units: jours · heures · minutes · secondes, singular at 0 and 1.

## Accessibility
- The ticking digits are hidden from assistive tech. A polite live region says a coarse sentence that changes hourly beyond a day, every 15 min beyond an hour, every 5 min, then every minute when urgent, then « moins d'une minute » — never every second.
- Urgency is colour + pulsing icon + the number; expiry is said in words.
- At 0, never act silently: disable the action and show the expired text.

## Do / Don't
- Do drive it from the server deadline (`endsAt`) so it never drifts.
- Do pair a claim countdown with the price: « Réclamer la place · 15 DT ».
- Don't show seconds for deadlines more than a day away; don't use blocks for short holds.

## Props (web preview)
`seconds` · `endsAt` · `format` · `size` · `label` · `urgentAt` · `running` · `expiredLabel` · `icon` · `align` · `onExpire`. See `index.d.ts`.

## Flutter
`MuCountdown(endsAt: deadline, format: MuCountdownFormat.clock, size: MuCountdownSize.hero, label: 'Elle est à toi pendant', urgentAfter: Duration(minutes: 5), onExpire: …)` — a `StatefulWidget` with a 1 s `Timer.periodic` that recomputes from `endsAt`; digits in `MuType.numHero` with `FontFeature.tabularFigures()`; the pulse is an `AnimationController` skipped when `MediaQuery.disableAnimations`; announce coarse changes with `SemanticsService.announce`.
