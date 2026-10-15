# RoleSwitcher

One account, several hats: switch between Joueur, Propriétaire de terrain, Coach and Organisateur without signing out.

## When to use
- Desktop: the dropdown under the Sidebar’s role trigger. Mobile: a bottom sheet opened from the account menu (« Changer de rôle »).
- Only for accounts with two roles or more; with one role, offer « Ajouter un rôle » in the account menu.

## Anatomy & specs
| Part | Menu — desktop | Sheet — mobile |
|---|---|---|
| Surface | 320 wide, `surface-elevated`, `radius-lg`, `elevation-2` (+ 1px `border` ring over the rail), padding `space-2` | `surface-elevated`, top corners `radius-lg`, `elevation-3`, padding `space-4` + safe area, over the `scrim` |
| Header | `overline` « Changer de rôle » in `text-secondary` | handle 36 × 4 `border-strong`, `h2` title, close IconButton |
| Row | 56 high, `radius-md`, padding `space-2` / `space-3`, gap `space-3` | 64 high |
| Tile | 40, `radius-sm`, `surface-muted` + `border` ring, icon 20 | 44 (`touch-target`), `radius-md` |
| Text | `label` role + `caption` context in `text-secondary`, one line each | same |
| Count | Counter (alert): unread notifications of that role | same |
| Current | `accent` tile with `on-accent` icon + check 20 at the end | same |
| Add | dashed 1.5px `border-strong` tile with plus, `label` « Ajouter un rôle » + `caption` hint | same, after a hairline |

Icons: Joueur person-simple-run · Propriétaire sport-court · Coach sport-whistle · Organisateur trophy · Admin shield-check.

## Variants
`menu` (desktop dropdown, `role="menu"`) · `sheet` (mobile bottom sheet, `role="dialog"`).

## States
- Rows: hover wash at `opacity-hover`, pressed `opacity-pressed` + 0.98, focus `focus-ring`.
- Choosing a role closes the menu and reloads the workspace for that role (skeletons, not spinners).
- The menu enters over `duration-base` `ease-enter`; the sheet slides up over `duration-slow`.

## Content
- Role names as nouns: « Joueur », « Propriétaire de terrain », « Coach », « Organisateur ».
- The context line answers “which one?”: « Arena Five · 4 terrains », « 3 programmes actifs », « Padel Cup Lac 2 · 16 équipes », « Niveau 3,5 · La Marsa ».

## Accessibility
- Menu: `role="menu"`; roles are `menuitemradio` with `aria-checked`; ↑ ↓ Home End move, Enter switches, Esc closes and refocuses the trigger.
- Sheet: `role="dialog"` with `aria-modal`, named by its `h2`; rows are buttons and the current one has `aria-current` + « rôle actuel ».
- Counts are spoken: « Organisateur, 1 notification ».

## Do / Don't
- Do show the current role in the trigger and check it in the list.
- Do keep roles with notifications visible — the count is why people switch.
- Don’t switch roles on hover or on arrow keys; only on Enter or a tap.

## Props (web preview)
`roles` (`id`, `role`, `label`, `context`, `count`, `icon`) · `value` · `defaultValue` · `onChange` · `variant` · `title` · `onAddRole` · `addLabel` · `addHint` · `onClose` · `states`. See `index.d.ts`.

## Flutter
`MuRoleSwitcher(roles: […], current:, onChanged:, onAddRole:, variant: MuRoleSwitcherVariant.menu)` — the menu is a `MenuAnchor` of `MenuItemButton` rows anchored to the sidebar trigger; the sheet uses `showModalBottomSheet(showDragHandle: true, backgroundColor: surfaceElevated)` with a `ListView` of `InkWell` rows and `Semantics(selected: true)` on the current role.
