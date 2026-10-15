# VenueCard
A venue in search results and favourites — photo with « Vérifié » and a heart, rating and prices on the scoreboard strip, amenities and the next free slots.

## When to use
- **Default** in « Terrains » lists and desktop grids (3-up), and on a sport's landing page.
- **Compact** in map bottom sheets, favourites and « Récemment vus ».
- To book a precise slot, the time chips go straight to the booking sheet; the card itself opens the venue page.

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card` (`surface`, `radius-md`, `elevation-1`); body padding `space-4`, rows `space-3` apart |
| Photo | CourtArt photo 16:10, top corners `radius-md`; overlay padding `space-3`: StatusBadge « Vérifié » (Volt) at the start, IconButton M `on-media` heart at the end |
| Identity | name `h3`, place `body` `text-secondary` + pin « La Marsa · 2,4 km » |
| Tags | sport Chips S + amenities row: 20 px icons `text-secondary`, `space-3` apart (éclairage, vestiaires, douches, parking, couvert, cafétéria) |
| Scoreboard strip | NOTE ★ « 4,7 » / « 128 avis » · PAR JOUEUR « dès 12 DT » (`caption` prefix) · TERRAIN « 60 DT/h »; same strip specs as GameCard (`num-l` + `num-m` unit) |
| Slots | `overline` « Prochains créneaux » + Chips M (interactive, `num-s` time), `space-2` gap |
| Compact | grid: 72 px thumb (`radius-sm`, hairline ring) · name `label-l` + Vérifié seal · heart on row 1; rating `num-xs` + place `caption` on row 2; sport icons · « dès 12 DT /pers. » `num-s` on row 3, under the heart; padding `space-3` (96 high) |

## Variants
`default` · `compact`.

## States
- **Open** — next slots today.
- **Closed now** — photo desaturated (`grayscale`) under `scrim`, inverse badge « Fermé · ouvre à 8h00 » on the photo, slots labelled « Prochains créneaux · Demain ».
- **Fully booked today** — inverse badge « Complet aujourd’hui » on the photo, tomorrow's slots.
- **Favourite** — heart IconButton pressed: Volt fill, filled heart (`aria-pressed`).
- **Hover** `elevation-2` · **Pressed** `scale-press` · **Focus** `focus-ring` · **Skeleton** same layout.

## Content
- Prices: « dès 12 DT » is the lowest price per player; the court price « 60 DT/h » is secondary.
- Rating with one decimal, comma: « 4,7 »; reviews « 128 avis ».
- Slot chips show start times only: « 18h00 », « 19h30 », « 21h00 » (3 on mobile, up to 5 on desktop).

## Accessibility
- Amenities are a list named « Équipements »; each icon has a label and a tooltip.
- The heart keeps one label « Mettre Arena Five en favori » and toggles `aria-pressed`.
- Slot chips are buttons: « Réserver à 19h30 », « Réserver demain à 9h30 ».
- The photo is `role="img"` « Photo de Arena Five »; the « Fermé » badge text is real text, not part of the image.

## Do / Don't
- Do show the price per player first; the court price is supporting information.
- Do keep Vérifié on the photo where it is seen first.
- Don't use the warning colour for stars — the star is `text`.
- Don't hide the closed state in the slots only; say it on the photo.

## Props (web preview)
`variant` · `name` · `sports` · `place` · `distance` · `rating` · `reviews` · `verified` · `amenities` · `slots` · `slotsDay` · `pricePerPerson` · `courtPrice` · `favourite` · `defaultFavourite` · `onFavouriteChange` · `status` · `opensAt` · `onSlotSelect` · `href` · `onOpen` · `skeleton` · `state`. See `index.d.ts`.

## Flutter
`MuVenueCard(venue: MuVenue, variant: MuVenueCardVariant.standard, favourite:, onFavouriteChanged:, onSlotTap:, onTap:, loading:)` — `MuCardSurface` with an `AspectRatio(16 / 10)` `Stack` (photo, `ColorFiltered` greyscale when closed, `Positioned` badge and `MuIconButton.onMedia`). Compact uses a `Row` with a 72 px `ClipRRect` thumb and a three-row `Column`.
