# MapView

Venues on MatchUp's muted map — sport-coloured pins with the sport glyph, clusters that count and show their sport mix, your position, and a mini card when a pin is selected.

## When to use
- Explorer « Carte », with the Carte / Liste switch, full screen on mobile and in the desktop split view.
- **Static** (`interactive={false}`) on a venue page: its pin, no pan or card, an « Itinéraire » action.
- Not for directions themselves (hand off to the maps app) or for places that can't be booked.

## Anatomy & specs
| Part | Spec |
|---|---|
| Frame | `height` (default 480), `radius-md`, `elevation-1`, ground `map-land` |
| Style | `map-land` · `map-water` · `map-park` · `map-road` (main roads cased in `border`); labels in `map-label` — districts `overline`, water and streets `caption` (streets from zoom 0,8) |
| Pin | 36 disc in `<sport>`, 2px `white` ring, `elevation-2`; sport icon 18 in `ink-900`; 44 hit area |
| Selected pin | scale 1.22, icon 22, a 3px `accent` ring outside the white one, drawn above the others |
| Cluster | 48 `surface` disc, `elevation-2`; 4px ring split by the sport mix (`football` · `padel` · `basketball`; `border-strong` without a mix); count `num-s` in a 34 `surface-inverse` disc |
| You | 16 `info` dot, 3px `white` ring; 56 `info` halo at 16 % pulsing every 1.5 × `duration-pulse` |
| Mini card | 288 wide, `mu-card` on `surface-elevated`, `elevation-2`, padding and gaps `space-3`, its edge 34 above the pin's centre with a 12px arrow pointing at it; CourtArt 56 (`radius-sm`) · name `label-l` · sport icon + name in `<sport>-text` and « Lac 2 · 1,2 km » `caption` · `star` (fill, `warning`) « 4,7 » `num-xs` « (128 avis) » · « dès 12 DT /pers. » (`num-m`) · up to 3 slot Chips S · Button S « Voir »; IconButton S « Fermer » |
| Controls | top end, `space-3` in: zoom pill (IconButton M + / −, `surface`, `elevation-2`) over « Me localiser » (`gps-fix`); top centre after a pan: Button S « Rechercher dans cette zone » (pill, `elevation-2`); bottom centre, `space-4` up: SegmentedControl S « Carte · Liste »; bottom end: `action` |

## States
- **Pin**: hover scale 1.1 over `duration-fast`, `ease-pop`; focus `focus-ring`; selected as above. Tapping it again, or tapping the map, deselects.
- **Camera**: selecting a pin (it pans so the card fits), tapping a cluster (zoom × 1.6) and « Me localiser » fly over `duration-slow` on `ease-move` — instantly under reduced motion. Zoom 0,6–2,4: buttons × 1.25, Ctrl/⌘ + wheel × 1.1.
- **Moved**: after a drag or zoom, « Rechercher dans cette zone » fades up (`duration-base`, `ease-enter`); searching or locating hides it.
- **Mini card**: fades up over `duration-base`, `ease-enter`; the slot chip picked is passed to `onOpen(venue, slot)`.
- **No result**: a floating card above the switch — `map-pin-area` + « Aucun terrain dans cette zone » `label` · « Dézoome ou déplace la carte pour voir plus de terrains. » `caption` + Button S « Dézoomer ».
- **Loading**: one Skeleton fills the frame. **Static**: no pan, zoom, card or controls; pins aren't focusable.

## Content
- Distances « 1,2 km », ratings « 4,7 », slots « 19h00 »; the price is the lowest per person: « dès 12 DT /pers. ».
- **Data**: `venues` = `{ id, name, sport, lat, lng (or x, y on the drawing), area, distance, rating, reviews, priceFrom, slots }`.
- `clusters` = `{ id, count, label, mix: { football, padel, basketball }, lat, lng }` — clustering is done by the consumer; `user` = `{ lat, lng }` or `null`.
- Selection is controlled with `selectedId` / `onSelect` (or `defaultSelectedId`); the switch with `view` / `onViewChange`.

## Accessibility
- The map is a focusable `region` (« carte ») named « Carte des terrains — glisse ou utilise les flèches pour te déplacer, + et − pour zoomer »; arrows pan 48px, + / − zoom, Esc closes the card and puts focus back on the map.
- Pins are buttons with `aria-expanded`: « Smash Padel Club, Padel, Lac 2, dès 12 DT par personne »; clusters « 12 terrains à Tunis centre : 7 football, 2 padel, 3 basket — zoomer »; your dot is an `img` « Ta position ».
- The mini card is a non-modal `dialog` named after the venue; its slot chips are a `radiogroup` « Prochains créneaux ».
- Sport is never colour alone: a glyph on every pin, the sport's name on the card. The ink glyph holds 5.9:1 even on basketball orange.
- The map, pins and labels never mirror in RTL; the floating controls follow logical edges.

## Do / Don't
- Do show « Rechercher dans cette zone » rather than reloading on every pan.
- Do keep the card to one venue, three slots and one action.
- Don't put Volt anywhere but the selected pin's ring and the active switch segment.
- Don't drop the sport glyph from a pin, even at small sizes.

## Props (web preview)
`venues` · `clusters` · `user` · `selectedId` · `defaultSelectedId` · `onSelect` · `center` · `zoom` · `height` · `onOpen` · `onSearchArea` · `onLocate` · `view` · `defaultView` · `onViewChange` · `viewToggle` · `interactive` · `action` · `emptyMessage` · `onZoomOut` · `label` · `skeleton` · `searchVisible` · `pinState` (preview only). See `index.d.ts`.

## Flutter
`MuMapView(venues: [...], clusters: [...], user:, selectedId:, onSelect:, onOpen: (venue, slot) => …, onSearchArea:, onLocate:, interactive: true)` — on `GoogleMap` (or Mapbox) with a style JSON generated from the `map-*` tokens; pins and clusters as widget-rendered marker bitmaps, the mini card in an `OverlayPortal` placed from the marker's screen coordinate, camera moves with `animateCamera`. `interactive: false` turns gestures and controls off.
