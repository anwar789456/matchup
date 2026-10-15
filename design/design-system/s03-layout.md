# Layout, space and shape

A 4 px grid, two frames (mobile 390 × 844, desktop 1440 × 900), four radii and three elevation levels.

## Spacing

| Token | px | Typical use |
|---|---|---|
| `space-1` | 4 | Icon-to-label gap in chips and badges |
| `space-2` | 8 | Icon-to-label gap in buttons; between chips |
| `space-3` | 12 | Compact card and row padding; between related lines |
| `space-4` | 16 | Mobile side margins, card padding, gap between cards |
| `space-5` | 20 | Large-button padding; between form fields |
| `space-6` | 24 | Sheet and modal padding; between card groups |
| `space-8` | 32 | Between page sections; desktop page margins |
| `space-10` | 40 | Above a section title on desktop |
| `space-12` | 48 | Hero and empty-state breathing room |
| `space-16` | 64 | Around illustrations, between landing-style blocks |

Lay out siblings with `gap`, not margins. Nothing outside this scale, except 1–2 px borders and rings.

## Grids and frames

- **Mobile (player app)**: 390 wide, 4 columns, `space-4` margins and gutters. The sticky bottom bar and tab bar sit above the device safe area. The main action is an XL button in that bar.
- **Desktop (player pages)**: 12 columns, `grid-desktop-gutter` 24, content up to `content-max` 1200, centred. Explorer becomes a map + list split view from `bp-expanded`.
- **Dashboards (owner, coach, organiser, admin)**: 1440 × 900 frame, `sidebar` 248 (collapses to `sidebar-collapsed` 72), `top-bar` 64, fluid content with `grid-desktop-margin` 32. Details open in a `drawer` 480 from the trailing edge so the table stays in view.
- **Breakpoints**: `bp-medium` 600 (two-column lists, side sheets), `bp-expanded` 840 (desktop layouts, side-panel assistant), `bp-large` 1200 (sidebar expanded by default). They match Flutter's Material window classes.
- **Email**: 600 wide. **Invoice**: A4.

## Sizes

| Token | px | Use |
|---|---|---|
| `control-s` / `-m` / `-l` / `-xl` | 32 / 40 / 48 / 56 | Buttons S–XL; inputs are `control-l` on mobile, `control-m` on desktop |
| `touch-target` | 44 | Minimum hit area; smaller visuals grow an invisible one |
| `icon-xs` / `-s` / `-m` / `-l` | 16 / 20 / 24 / 32 | Icons in badges / buttons and inputs / bars and lists / tiles |
| `avatar-xs` … `avatar-xl` | 24 / 32 / 40 / 56 / 96 | Stacks / rows / default / lineup / profile header |
| `app-bar` / `app-bar-large` | 56 / 112 | Mobile top app bar, compact and large-title |
| `tab-bar` | 64 | Mobile bottom tab bar, plus safe area |
| `modal-s` / `-m` / `-l` | 400 / 560 / 720 | Confirmation / form / rich dialogs |
| `toast` | 360 | Desktop toast width |
| `notification-panel` | 400 | Desktop notification dropdown |
| `sheet-peek` / `-half` / `-full` | 30 % / 55 % / 92 % | Bottom-sheet heights |

## Radius

| Token | px | Use |
|---|---|---|
| `radius-xs` | 4 | ADDITION: checkboxes, slot-grid cells, bar ends |
| `radius-sm` | 8 | Inputs, S buttons, tooltips, menu items, small tiles |
| `radius-md` | 12 | Cards, M–XL buttons, toasts, banners |
| `radius-lg` | 16 | Bottom sheets (top corners), modals, drawers, popovers |
| `radius-full` | 9999 | Chips, badges, avatars, pills, the FAB, switches |

Nest radii: an element inside a padded container takes the next radius down, so curves stay concentric.

## Elevation

| Level | Token | Light | Night match | For |
|---|---|---|---|---|
| 1 | `elevation-1` | soft 2–8 px shadow | 1 px hairline ring | Cards at rest |
| 2 | `elevation-2` (`elevation-2-up` for bars at the bottom) | 8–24 px shadow | hairline ring | Sticky bars, popovers, menus, the FAB, toasts |
| 3 | `elevation-3` | 24–56 px shadow | hairline ring | Modals, sheets, drawers |

In Night match the surface carries the height: cards on `surface`, floating things on `surface-elevated`. Cards rise from level 1 to level 2 on hover. Don't stack shadows on top of borders, and don't use elevation to decorate.
