# BookingCard
A booking in « Mes réservations » — tear-off calendar tile, status, a strip with the time range and your share, players, and the actions you need at the venue.

## When to use
- **Default** for the next bookings at the top of « Mes réservations » and on the home screen.
- **Compact** for the rest of the list and the history.
- For a game you joined but did not book, use GameCard (joined).

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`, padding `space-4`, rows `space-3` apart |
| Calendar tile | 60 × 72 (compact 52 × 64), `radius-sm`, `<sport>-soft`: weekday and month `overline` `<sport>-text`, day `num-l` (compact `num-m`) `text`; muted (`surface-muted` + `border`) when past or cancelled |
| Identity | title `label-l` « Arena Five · Terrain 2 »; sport icon + « Football · La Marsa » `body` `text-secondary`; StatusBadge below |
| Scoreboard strip | two cells: HORAIRE « 20h00 – 21h30 » `num-m` / duration « 1 h 30 » · TA PART « 15 DT » `num-m` + `num-s` unit / payment line |
| Payment line | « Payé » `success-text` + check · « À payer avant 17h00 » `warning-text` + warning icon |
| Footer | AvatarStack XS (4 + « +N ») · actions: Button S secondary « Itinéraire » (`navigation-arrow`), IconButton « Plus d’actions », IconButton inverse « Afficher le QR code » last |
| Compact | min-height 88, padding `space-3`; title `label`; time range `num-xs` + place `caption`; one status line; QR IconButton or Button S « Payer · 15 DT » at the end |

## Variants
`default` · `compact`, each in four statuses.

## States
- **Upcoming** — StatusBadge « Confirmé », « Payé », QR code at hand.
- **Pending payment** — StatusBadge « En attente », « À payer avant 17h00 », primary « Payer ma part · 15 DT » replaces the QR (no QR before payment).
- **Past** — neutral badge « Terminé » (flag), muted tile, secondary « Noter les joueurs » (star).
- **Cancelled** — StatusBadge « Annulé », time struck through, the second cell becomes REMBOURSÉ « 45 DT » / « sur ton solde » (`info-text`, `arrow-u-up-left`), tertiary « Réserver à nouveau ».
- **Focus** `focus-ring` around the card · **Skeleton** same layout.

## Content
- Time range with an en dash and spaces: « 20h00 – 21h30 »; duration « 1 h 30 ».
- Money: always your share, « Ta part 15 DT »; refunds say where the money went: « sur ton solde ».
- Deadlines are explicit: « À payer avant 17h00 », never « Bientôt ».

## Accessibility
- The calendar tile is decorative; the full date is read before the time (« sam. 18 oct., 20h00 – 21h30 »).
- Icon-only actions have labels: « Afficher le QR code », « Plus d’actions ».
- Status is colour + icon + label everywhere (badge and payment line).

## Do / Don't
- Do put the QR code last (it is the action used at the venue's door).
- Do keep one primary action per card — « Payer ma part » only when payment is pending.
- Don't show a QR code for unpaid or cancelled bookings.
- Don't hide the refund amount in the badge; it gets the strip cell.

## Props (web preview)
`variant` · `status` · `sport` · `venue` · `court` · `place` · `start` · `end` · `share` · `payBefore` · `refund` · `players` · `onShowQr` · `onDirections` · `onMore` · `onPay` · `onRate` · `onRebook` · `href` · `onOpen` · `skeleton` · `state`. See `index.d.ts`.

## Dark mode
The QR shortcut button uses the dark primary (Volt fill, ink icon), never a white disc.

## Flutter
`MuBookingCard(booking: MuBooking, variant: MuBookingCardVariant.standard, onShowQr:, onDirections:, onMore:, onPay:, onRate:, onRebook:, onTap:, loading:)` — `MuCardSurface` with a `Row(MuCalendarTile, Expanded(Column))` header, the shared `MuScoreboardStrip` and a footer `Row` of `MuAvatarStack` + `MuButton`/`MuIconButton`. Status drives the badge, strip cell and actions from one `switch`.
