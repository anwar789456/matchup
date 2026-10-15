# DataTable

The desktop dashboard table for bookings, users and payouts — toolbar, sortable sticky header, selection with a floating bulk-action bar, row actions, pagination and loading / empty / error states.

## When to use
- Owner, coach, organiser and admin dashboards from `bp-expanded` (840px): Réservations, Utilisateurs, Versements.
- For a handful of items with nothing to compare, use a list of cards instead.

## Anatomy & specs
| Part | Spec |
|---|---|
| Container | `mu-card` (`surface`, `radius-md`, `elevation-1`), corners clipped |
| Toolbar | `space-4` padding, `space-3` gaps, 1px `border` under it: pill search (`control-m`, ~300px), filter Chips with `caret-down` (count, or « Date : Aujourd'hui » for single choice), actions (« Exporter » secondary), density SegmentedControl (`rows` · `list`) |
| Header | sticky — inside the scroll area when `maxHeight` is set (e.g. the remaining viewport height), otherwise to the page under `--mu-dt-sticky-top` (set it to `var(--top-bar)` below a sticky top bar); `surface-muted`, `label` `text-secondary`, 44px (compact 36); sorted column in `text` with `caret-up` / `caret-down`; other sortable columns show `caret-up-down` in `border-strong`; numeric headers align end with the caret before the label |
| Rows | 52px comfortable · 40px compact, cells `space-4` inline; 1px `border` hairlines, no zebra; hover `surface-muted`; selected = `accent` 14 % over `surface` (22 % on hover) |
| Cells | person: Avatar S (compact XS) + name `label` + sub `caption`; amount `num-s` end-aligned « 150 DT »; date `body` « mar. 13 oct. » · time `num-s` « 20h00 »; status StatusBadge (compact S); text `body` |
| Checkbox | 20px, 1.5px `border-control`, `radius-xs`; checked `primary` + `on-primary` tick; mixed = dash; 44px hit area |
| Row actions | IconButtons S in `text-secondary` (`text` on row hover) + « … » menu: `surface-elevated`, `radius-lg`, `elevation-2`, items `control-m` with 20px icons; destructive last, after a separator, in `error-text` |
| Bulk bar | floats `space-4` above the bottom of the scroll area: `surface-elevated`, `radius-lg`, `elevation-3`; ✕ · Volt count pill `num-s` + « sélectionnées » · separator · primary · tertiary · destructive-outline last |
| Footer | 56px, 1px `border` on top: « Lignes par page » + select (`control-s`) · range « 1–20 sur 248 » · previous / next IconButtons S |

## Variants
Comfortable or compact density; toolbar, selection and row actions are each optional.

## States
- **Sorted**: header click → ascending, then descending; only one column is sorted.
- **Loading**: skeleton rows shaped like the columns (box, avatar + two lines, pills); header and toolbar stay; the pager says « Chargement… ».
- **Empty**: EmptyState compact « Aucune réservation pour ces filtres » + « Effacer les filtres »; the body keeps 320px.
- **Error**: `warning-circle` in a 56px `error-soft` circle, « Impossible de charger les réservations. », what to do, « Réessayer » (secondary, `arrows-clockwise`).
- **Menu open**: the « … » keeps its hover wash and focus moves into the menu.

## Content
- Headers are nouns: Joueur, Terrain, Créneau, Montant, Statut. Statuses: Confirmé · En attente · Annulé · Remboursé.
- Amounts with `formatDT` (« 1 250 DT »); dates « mar. 13 oct. · 20h00 ».
- The bulk count agrees with the noun: « 3 sélectionnées » (réservations), « 2 sélectionnés » (utilisateurs).
- Destructive actions name their object (« Annuler la réservation », « Suspendre le compte ») and open a confirmation dialog.

## Responsive
Under `bp-medium` (600px) each row becomes a `mu-card`: avatar + name + StatusBadge on the first line, « mar. 13 oct. · 20h00 · Terrain 2 » on the second, the amount in `num-m` at the end, every action in the « … » menu; filters move into a « Filtres » sheet and selection starts with a long-press. From 600 to 840px drop secondary columns (Terrain) and scroll horizontally with the first column kept visible.

## Accessibility
- A real `<table>` with a visually hidden caption, `th scope="col"`, `aria-sort` on the sorted column and buttons inside sortable headers.
- Checkboxes are named (« Sélectionner la réservation de Yassine B. », « Tout sélectionner sur cette page », mixed state); a polite live region says « 3 sélectionnées ».
- Menus: `role="menu"`, arrows / Home / End, Esc returns focus to the trigger; filter menus use `menuitemcheckbox` / `menuitemradio`.
- Pagination is a `<nav aria-label="Pagination">`; numbers keep their order in RTL.

## Do / Don't
- Do right-align amounts in Barlow so digits line up.
- Do keep row actions visible (quiet, not hidden until hover).
- Don't zebra-stripe — hairlines and hover are enough.
- Don't put the destructive bulk action anywhere but last.

## Props (web preview)
`columns` · `rows` · `rowKey` · `caption` · `rowLabel` · `searchable` · `filters` · `actions` · `densityToggle` · `selectable` · `bulkActions` · `rowActions` · `density` · `sort` · `pageSizeOptions` · `loading` · `error` · `onRetry` · `empty` · `maxHeight`. See `index.d.ts`.

## Flutter
`MuDataTable<Booking>(columns: [MuColumn.person('player', 'Joueur'), MuColumn.money('amount', 'Montant'), …], rows: bookings, selectable: true, bulkActions: […], rowActions: (b) => […], density: MuDensity.comfortable, pageSize: 20)` — build it on `CustomScrollView` with a pinned `SliverPersistentHeader` (or `TableView` from `two_dimensional_scrollables`) rather than `DataTable`, which has no density, sticky header or floating bar; the bulk bar is an `AnimatedSlide` in a `Stack`, menus are `MenuAnchor`s, and under 600px it switches to a `ListView` of `MuCard`s.
