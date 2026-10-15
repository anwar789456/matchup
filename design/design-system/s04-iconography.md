# Iconography and imagery

## Icons

- **One set**: Phosphor Icons (MIT), **Regular** weight. Its stroke is 16 on a 256 grid, which is 1.5 px at 24 px, with round caps and joins: the brief's rounded line style. Use **Fill** only for the selected tab-bar destination and for filled status glyphs inside badges.
- **Sizes**: `icon-m` 24 in bars, lists and the tab bar; `icon-s` 20 in buttons, chips and inputs; `icon-xs` 16 in badges and S chips; `icon-l` 32 in tiles. Never scale an icon to an in-between size.
- **Colour**: icons take the text colour of their context (`text`, `text-secondary`, `on-primary`, `on-accent`). Status icons use `<status>-text`; sport icons use `<sport>-text` or white on a sport fill.
- **MatchUp sport icons**: six custom icons drawn on the same 256 grid and stroke: `sport-football` (ball), `sport-padel` (racket), `sport-basketball`, `sport-whistle`, `sport-trophy`, `sport-court`. Use them wherever a sport, a coach, a tournament or a court is named. The SVGs are in the Icons asset group.
- **Direction**: arrows, carets, « send », « sign out » and list icons are directional and mirror in Arabic (the `Icon` component does it). Play, pause, the clock, numbers and map controls never mirror.
- **Names**: every icon-only control has an accessible name (« Notifications », « Fermer », « Partager la partie »). Decorative icons are hidden from screen readers.
- No emoji anywhere in the product UI.

In Flutter, use the `phosphor_flutter` package for Phosphor (Regular, and Fill for the selected tab) and `flutter_svg` for the six sport icons.

## Imagery

- **Photography direction**: diverse Tunisian amateur players, women and men, mid-game on real local courts under evening floodlights; candid, warm, slightly grainy, never stock poses. Faces lit, not posed; the court lines and the lights visible. Lay text on a photo only over `photo-scrim`.
- **Until real photos exist, use `CourtArt`**: a night-lit court in the sport colour (pitch, padel court, basketball half-court) under two floodlights. Variants `photo` (venue galleries, game headers), `poster` (tournaments, programs) and `pattern` (small thumbnails). Never a grey placeholder box.
- **Avatars**: a photo when there is one; otherwise initials on `avatar-bg`. Never a generic silhouette.

## Illustrations

Flat empty-state illustrations: solid shapes in the sport colours, Volt and ink, one soft ground shadow, no outlines, no gradients, on a 200 × 160 canvas. Four are drawn (no upcoming matches, no notifications, no programs, no results) and live in the Illustrations asset group and in `EmptyState`. New ones follow the same rules: one object, one sport hint (a ball, a cone, a court), one Volt accent.

## Logo

The wordmark « MatchUp » is set in bold geometric letterforms in which the « a » is a ball: a disc with a curved seam. On light grounds the letters and ball are ink with a Volt seam; on dark grounds the letters are white and the ball Volt with an ink seam. The app icon is that ball-and-stem « a » on an ink rounded square; the monochrome version (Android themed icons, single-ink prints) knocks the seam out of the ball. Keep clear space equal to the ball's diameter on every side and never set the wordmark under 18 px high. Never recolour, stretch, outline or rebuild it from type; use the files in the Logos asset group or the `Logo` component.
