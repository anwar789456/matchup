# Arabic and RTL

French is the default, then Arabic (right to left) and English from the language switcher. Every component is built with logical properties (`margin-inline-start`, `padding-inline`, `inset-inline-end`, `text-align: start`), so setting `dir="rtl"` and `lang="ar"` on the root mirrors the layout without per-component work.

## Mirror

- Layout and reading order: the leading edge is on the right.
- Navigation: the back arrow points right, the drawer slides from the left, the tab bar and sidebar order flip, breadcrumbs run right to left.
- Progress: progress bars, step indicators, wizard steppers and sliders fill from the right.
- Directional icons: arrows, carets, « send », « sign out », list bullets (the `Icon` component mirrors them automatically).
- Swipe actions, carousels and the slot-grid time axis.

## Never mirror

- Numbers, prices, scores and times: « 15 DT », « 3 – 2 », « 20h00 », « 14:59 » keep left-to-right digits. Keep Western digits (0–9).
- Scoreboards keep the home side in the first position of the reading order, but the digits themselves never flip.
- Media controls: play, pause, seek and the video timeline.
- Maps, courts and lineups: the pitch, the padel court and pin positions are geography, not text.
- Logos, the QR code, card numbers, phone numbers (+216 20 123 456) and booking codes (MU-20481).
- The clock and timer icons.

## Type

Set Arabic text in IBM Plex Sans Arabic with the `ar-*` styles (same sizes, taller lines). No letter-spacing and no capitals in Arabic; `overline` drops its uppercase. Numbers stay in Barlow Condensed.
