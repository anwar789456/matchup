# Sidebar

The dashboard rail — `nav-bg`, dark in both themes like a scoreboard — 248 expanded or 72 collapsed, with the role switcher on top and the current page in a Volt pill.

## When to use
- Every desktop dashboard (Propriétaire, Coach, Organisateur, Admin) from `bp-expanded` 840. Expanded by default from `bp-large` 1200, collapsed below; remember the person’s choice.
- One item per destination of the role (≤ 12), grouped in 2–4 sections.

## Anatomy & specs
| Part | Expanded — `sidebar` 248 | Collapsed — `sidebar-collapsed` 72 |
|---|---|---|
| Brand row | `top-bar` 64 high (lines up with TopBar), Logo `tone="dark"` wordmark 24 | Logo icon 32, centred |
| Role trigger | ≥ 48, `radius-md`, 1px inset line; venue tile 32 (`radius-sm`, initials `label-s`), role in `caption` `nav-text-muted`, venue in `label`, caret-up-down | tile only |
| Section | `overline` heading in `nav-text-muted`, padding `space-4` / `space-1` | 1px line |
| Item | 40 high, `radius-full`, icon 20 + `body` label (`label` when active); the icon column never moves when collapsing | 48 × 40 pill, label hidden but read, tooltip |
| Count | Counter on a 14% `nav-text` fill | corner badge, `nav-text` digits on a `nav-bg` ring |
| Foot | 1px line; « Aide et support » and « Réduire le menu » in `nav-text-muted`; user row: Avatar S, `label` name, `caption` email | icons and avatar |

Rail padding `space-3`; items 2 apart; head and foot stay put, the middle scrolls when the window is short (owner set needs 840 high).

## Variants
Expanded 248 · collapsed 72 (icons, corner counts, tooltips). Same component for every role; only `sections`, `role` and `user` change.

## Colours
| State | Fill | Label and icon |
|---|---|---|
| Rest | `nav-bg` | `nav-text` (14.5:1) |
| Hover | `nav-hover` | `nav-text` |
| Active | `nav-active` (Volt) | `on-accent`, Fill icon |
| Headings, utilities | — | `nav-text-muted` (7.4:1) |
| Focus | Volt ring with a 2px `nav-bg` gap — the Light `focus` ink would vanish on the rail | — |
| Tooltip | `surface-inverse` | `text-inverse`, count in an `accent` pill |

## States
- **Collapse / expand**: width over `duration-base` `ease-move`, labels fade over `duration-fast`.
- **Collapsed tooltips**: on hover or focus, `label-s`, `space-6` from the item with an arrow, `z-popover`.
- **Role trigger open**: `nav-hover`; RoleSwitcher drops below with a `border` ring + `elevation-2`.
- Hover, pressed (0.98) and focus on every row.

## Content
- Owner: Tableau de bord · Activité (Planning, Réservations, Terrains, Tarifs) · Clientèle (Clients, Avis) · Gestion (Revenus, Abonnement, Paramètres).
- Admin: Vue d’ensemble · Comptes (Utilisateurs, Vérifications) · Activité (Terrains, Réservations, Tournois, Programmes) · Gestion (Paiements, Modération, Paramètres).
- Counts only for work waiting on this person: « 4 à confirmer », « 12 dossiers à vérifier ».

## Accessibility
- `aside` > `nav` « Navigation du tableau de bord »; sections are `role="group"` labelled by their heading; the current item has `aria-current="page"`.
- The toggle has `aria-expanded` + `aria-controls`; its label switches « Réduire le menu » / « Agrandir le menu ». Collapsed labels stay in the accessibility tree; tooltips are `aria-hidden` copies.
- Counts are spoken with the item: « Réservations, 4 à confirmer ».

## Do / Don't
- Do keep the rail dark in Light; it frames the page like a scoreboard.
- Don’t use Volt for anything but the active item (and the tooltip count).
- Don’t nest items — a second level is a page with Tabs.

## Props (web preview)
`sections` · `activeId` · `onNavigate` · `collapsed` · `defaultCollapsed` · `onCollapsedChange` · `role` · `roles` · `currentRoleId` · `onRoleChange` · `onAddRole` · `roleMenuOpen` · `user` · `helpLabel` · `collapseLabel` · `expandLabel` · `states` · `tooltipId`. See `index.d.ts`.

## Flutter
`MuSidebar(sections: […], activeId:, collapsed:, onCollapsedChanged:, role: MuRole('Propriétaire', 'Arena Five'), user:)` — an `AnimatedContainer` (248 ↔ 72, `ease-move`) holding a `Column`: header, `Expanded(ListView)` of `MuSidebarItem` (`InkWell`, `StadiumBorder`), footer. Tooltips via `Tooltip(preferBelow: false)` only when collapsed; the role dropdown via `MenuAnchor`. Colours from MuTheme `nav-*`, constant across themes.
