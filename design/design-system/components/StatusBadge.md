# StatusBadge

Where a booking, game, payment or account stands, shown as colour + icon + label — « Confirmé », « En attente », « Complet », « EN DIRECT » — never colour alone.

## When to use
- On cards, rows and tables: booking and game state, payment state, coach and venue verification, drafts.
- Not for categories (sport Chip), counts (Counter) or anything that needs a sentence (Banner).

## Anatomy & specs
| Size | Height | Padding (inline start / end) | Icon | Label |
|---|---|---|---|---|
| M (default) | 24 | `space-2` / 10 | 16, Fill | `label-s` |
| S | 20 | 6 / `space-2` | 14, Fill | `label-s` |

- `radius-full`, icon-to-label gap `space-1`.
- `live` replaces the icon with the pulsing 8 px `live` dot, sets the label in `overline` capitals, and pads 10 on both sides with a 6 gap.
- `iconOnly`: a 24 circle; the label is visually hidden and shown as a tooltip.

## Variants
| Status | Label | Icon | Fill / text |
|---|---|---|---|
| confirmed | Confirmé | `check-circle` | `success-soft` / `success-text` |
| paid | Payé | `check-circle` | `success-soft` / `success-text` |
| pending | En attente | `clock` | `warning-soft` / `warning-text` |
| failed | Échec | `warning-circle` | `error-soft` / `error-text` |
| live | EN DIRECT | live dot | `error-soft` / `error-text` |
| refunded | Remboursé | `arrow-u-up-left` | `info-soft` / `info-text` |
| full | Complet | `users-three` | `surface-inverse` / `text-inverse` |
| verified | Vérifié | `seal-check` | `accent` / `on-accent` |
| cancelled | Annulé | `x-circle` | `surface-muted` / `text-secondary`, 1px `border` ring |
| draft | Brouillon | `note-pencil` | `surface-muted` / `text-secondary`, 1px `border` ring |

## States
Static. The `live` dot pulses over `duration-pulse`; under reduced motion it stops and the word still says it. Change the status; don't animate the badge.

## Content
- Default labels are masculine; pass `label` to agree with the noun: « Annulée » (partie, réservation), « Complète » (équipe).
- Use `label` for a more precise state in the same tone: « À payer » (pending), « Vérification en cours » (pending), « Terminé » (confirmed), « En cours » (live).
- One to three words, no punctuation. Only live labels are capitals (`overline`).

## Accessibility
- The icon is decorative; the label is the text. `iconOnly` keeps the label for screen readers and as a `title` tooltip.
- Label contrast ≥ 4.6:1 on every soft fill in Light and ≥ 6:1 in Night match; `text-secondary` on `surface-muted` ≥ 5.1:1; `text-inverse` on `surface-inverse` 17.2:1; `on-accent` on `accent` 13.2:1.
- `arrow-u-up-left` (Remboursé) mirrors in RTL.

## Do / Don't
- Do use S in dense rows, tables and compact cards; M on cards.
- Do keep `iconOnly` for tight spots with an obvious meaning, like the verified seal next to a name.
- Don't invent colours: map a new state onto an existing tone (success, warning, error, info, neutral).
- Don't use `verified` (Volt) for anything but verification.

## Props (web preview)
`status` · `label` · `size` · `iconOnly`. See `index.d.ts`.

## Flutter
`MuStatusBadge(status: MuStatus.confirmed, label:, size: MuBadgeSize.m, iconOnly: false)` — a `DecoratedBox(ShapeDecoration(shape: StadiumBorder(), color:))` around a `Row(mainAxisSize: MainAxisSize.min)` of the Phosphor Fill icon and a `Text` in `MuType.labelS`, colours from one `switch` on the status. Live: a `MuLiveDot` pulsed by an `AnimationController` (stopped when `MediaQuery.disableAnimations`). `iconOnly`: `Tooltip(message: label)` + `Semantics(label: label)`.
