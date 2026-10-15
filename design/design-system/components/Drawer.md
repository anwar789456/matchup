# Drawer

A desktop side panel that slides in from the trailing edge — `drawer` 480 wide, full height — to show a record's details (a booking, a user, flagged content) without leaving the table.

## When to use
- Owner and admin dashboards: open a booking, a user or a report from its row while the table stays behind.
- Step through records with ↑ / ↓ (« 3 sur 48 ») instead of closing and reopening.
- `modal={false}` for side-by-side review with the table still usable. On phones, open a full page instead.

## Anatomy & specs
| Part | Spec |
|---|---|
| Panel | `drawer` 480 (max 100 %), full height, `surface-elevated`, `elevation-3`, `radius-lg` on the two inner corners |
| Header | padding `space-4`, inline `space-6` / `space-4`, `border` hairline below; eyebrow `overline` `text-secondary` (the tools then sit on its row and the title gets the full width); title `h3`; meta row: StatusBadge + `caption`, gap `space-2` |
| Tools | counter `caption` « 3 sur 48 » · IconButton S `caret-up` / `caret-down` · `border` divider · IconButton M « Fermer » |
| Section | padding `space-5` `space-6`, hairline between sections; head min `space-6`: `overline` title in `text-secondary` + action (link button or badge), `space-3` above the content |
| Fields | `dl` rows `space-3` apart: label `caption` `text-secondary` in a 112 column, value `body` (`num-s` when numeric), `space-4` between |
| Timeline | 28 dots with 16 icons on `bg` + hairline (tones on their `-soft` / `-text`), a 2px `border` connector; title `body` + meta `caption` |
| Footer | padding `space-4` `space-6`, `surface-elevated`, `elevation-2-up`; a ButtonGroup with the primary on the right and a destructive-outline at the start |

- **Layer** `z-sheet` (300) — over popovers and sticky bars, under dialogs and toasts; `scrim` (ink-900 at 40 %, 64 % in Night match) when modal.

## States
- **Enter**: slides from `translateX(100 %)` (from the left in RTL) over `duration-slow`, `ease-enter`; **exit** the same way over `duration-base`, `ease-exit`.
- **Dismiss**: X, scrim tap or Esc. `dismissible={false}` removes them.
- **Modal** (default): scrim, focus trapped, page scroll locked. **Non-modal**: no scrim, no trap; Esc still closes.
- **Prev / next**: the content changes in place and the counter updates; at either end the arrow is disabled (pass `null`), never hidden.
- The body scrolls between a fixed header and footer.

## Content
- Eyebrow = where it lives (« Arena Five · Terrain 2 », « Modération »); title = the record (« Réservation #MU-20481 », « Signalement #SG-3107 »); meta = when (« Créée le mar. 14 oct. à 18h32 »).
- Section titles are nouns: « Joueur », « Créneau », « Paiement », « Historique ».
- Footer verbs: « Marquer présent », « Annuler la réservation »; in moderation « Approuver », « Supprimer », « Avertir », « Suspendre ». A destructive action opens a Dialog that states the consequence.
- AI help (a toxicity score) sits in its own section with the « IA » label and « Recommandé car… »; the moderator decides.

## Accessibility
- An `aside` with `role="dialog"`, labelled by the title (`label` otherwise); `aria-modal` when modal.
- Focus moves into the panel on open; when modal, Tab cycles inside; Esc closes and focus returns to the row that opened it.
- Prev / next have record-specific names (« Réservation précédente », « Réservation suivante ») and 44 hit areas.
- Sections are `section`s with heading titles; fields are a description list; the timeline is an ordered list.

## Do / Don't
- Do keep the table's highlighted row in sync with the drawer and with prev / next.
- Do keep one drawer open at a time; the next record replaces the content.
- Don't use a drawer on phones.
- Don't put a long form in a drawer — use a page or a Dialog M.

## Props (web preview)
`open` · `onClose` · `title` · `eyebrow` · `badge` · `meta` · `onPrev` · `onNext` · `prevLabel` · `nextLabel` · `counter` · `children` · `footer` · `modal` · `dismissible` · `closeLabel` · `label` · `inline` · `autoFocus`; `Drawer.Section`: `title` · `action`; `Drawer.Fields`: `items` (`label`, `value`, `numeric`); `Drawer.Timeline`: `items` (`title`, `meta`, `icon`, `tone`). See `index.d.ts`.

## Flutter
`MuDrawer.show(context, eyebrow: 'Arena Five · Terrain 2', title: 'Réservation #MU-20481', badge: …, counter: '3 sur 48', onPrev:, onNext:, sections: [...], footer: …, modal: true)` → `showGeneralDialog(barrierColor: colors.scrim, barrierDismissible: true)` with a 480-wide panel in `Align(alignment: AlignmentDirectional.centerEnd)` and a `SlideTransition` from `Offset(1, 0)` (−1 in RTL). Non-modal: an `OverlayPortal` panel or a `Row` split so the table keeps working. Sections in a `ListView`; header and footer outside it.
