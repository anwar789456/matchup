# Breadcrumbs

The desktop path to the current page — « Tableau de bord / Réservations / #MU-20481 » — with deep middles folded into a « … » menu.

## When to use
- In dashboards (owner, coach, organizer, admin) from the second level down, in the TopBar’s start slot instead of the page title.
- Not on mobile — the back button does that job. Not on top-level pages.

## Anatomy & specs
| Part | Spec |
|---|---|
| Link | `body` in `text-secondary`, padding `space-1`, `radius-xs`; max 200 then ellipsis (full label in the tooltip) |
| Separator | caret-right 16 in `border-strong`, gap `space-1`; mirrors in RTL |
| Current page | `label` in `text`, plain text, max 280; truncates first when space runs out |
| « … » | IconButton S (dots-three) in `text-secondary` |
| Menu | `surface-elevated`, `elevation-2`, `radius-lg`, padding `space-2`, items 40 (`body`, `radius-sm`) listing the hidden levels in order |
| Folding | `maxItems` 4 → first level, « … », last two |

## States
- **Hover**: `text` + 1.5px underline. **Focus**: `focus-ring`. Hit areas grow to 44 high.
- **« … » open**: pressed wash (`opacity-pressed`); the menu enters over `duration-base` `ease-enter`.

## Content
- Use page names exactly as in the Sidebar (« Réservations », not « Liste des réservations »).
- Name records by reference or name: « #MU-20481 », « Arena Five », « sam. 18 oct. ».
- Labels are isolated with `<bdi>` so references stay LTR in Arabic.

## Accessibility
- `nav aria-label="Fil d’Ariane"` > `ol`; the current item has `aria-current="page"`.
- Separators are decorative icons (`aria-hidden`).
- « … » is labelled « Afficher 3 niveaux masqués » with `aria-haspopup="menu"` and `aria-expanded`; ↑ ↓ move in the menu, Esc closes it and returns focus.

## Do / Don't
- Do keep the root visible at every depth.
- Do let the current page truncate before its parents.
- Don’t make the current page a link.
- Don’t type slashes as separators — use the caret icon so RTL mirrors it.

## Props (web preview)
`items` (`label`, `href`, `onClick`, `icon`, `id`) · `maxItems` · `label` · `menuOpen` · `defaultMenuOpen` · `onMenuOpenChange` · `states`. See `index.d.ts`.

## Flutter
`MuBreadcrumbs(items: [MuCrumb('Tableau de bord', onTap: …), …], maxItems: 4)` — a `Row` of `TextButton`s (`body`, `text-secondary`) and `Icon(PhosphorIcons.caretRight, size: 16)` inside `Directionality` (mirror with `Transform.flip` in RTL); the current page is a `Flexible` `Text` with `TextOverflow.ellipsis`, parents are not flexible; the « … » menu is a `MenuAnchor`.
