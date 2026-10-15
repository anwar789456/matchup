# NotificationItem

One entry of the notification centre — category circle, title, two-line body, time, optional avatar, people or thumbnail, inline actions, three priority levels and swipe to read or delete.

## When to use
- **Default** in the mobile Notifications screen (390): full-bleed rows on `surface`, grouped under « Aujourd’hui » / « Cette semaine ».
- **Compact** in the desktop bell panel (`notification-panel` 400, `surface-elevated`, `radius-lg`, `elevation-3`).

## Anatomy & specs
| Part | Default (mobile) | Compact (desktop panel) |
|---|---|---|
| Row | padding `space-4`, gap `space-3`, `surface` | padding `space-3` `space-4`, transparent on the panel |
| Lead circle | 40px, icon 20 | 32px (`icon-l`), icon 16 |
| Avatar lead | Avatar M + 18px category badge, 2px `surface` ring | Avatar S + 16px badge |
| Title | `label` (unread) / `body` (read), `text`, 2 lines | same |
| Time | `caption` `text-secondary`, end of the title line | same |
| Body | `body` `text-secondary`, 2 lines | same |
| Extras | AvatarStack XS (`space-2` above) · actions: Buttons S, gap `space-2`, `space-3` above · thumbnail 48, `radius-sm` | actions `space-2` above · thumbnail 40 |
| Unread dot | 8px `primary` (ink in Light, Volt in Night match) in the start padding, centred on the title line | same |
| Divider | 1px `border`, inset to the text column; none after the last row | same |

Category icons: Matchs (sport icon on `<sport>-soft`, else whistle) · Réservations (calendar-check) · Paiements (wallet) · Tournois (sport-trophy) · Entraînement (barbell) · Communauté (chats-circle). Other circles are neutral (`surface-muted` + `border` ring); a status tint (`success-soft`…) only when the notification reports a status.

## Variants
- **normal** — as above.
- **important** — whole row on `warning-soft`, body in `text`, the circle becomes a `surface` disc with the warning icon (`warning-text`).
- **urgent** — title in `error-text`, solid `error` circle with a white glyph and a 4px `error-soft` halo; no tint, no coloured border.
- **grouped** — « Yassine et 3 autres ont rejoint ta partie » + AvatarStack XS.

## States
- Read: no dot, title in `body`. Hover → `text` wash `opacity-hover`; pressed `opacity-pressed`; focus → inset 2px `focus` ring.
- Swiped (default only): the row slides `144` toward the start (`duration-base`, `ease-move`) to reveal « Lu » (`primary`/`on-primary`, envelope-open) and « Supprimer » (`destructive`, trash), 72 each. Drag past half to open; tap the row to close.
- Loading: `skeleton` keeps circle, title, time and two body lines.

## Content
- Title states the news, body gives time, place, price: « Mariem K. t’invite à jouer » / « Padel 2 vs 2 · dim. 19 oct. · 18h30 · Smash Padel Club · 15 DT par personne ».
- Actions are verbs, with price or countdown inside: « Accepter » / « Refuser », « Payer ma part · 15 DT », « Noter les joueurs », « Réclamer la place · 14:59 ».
- Times: « 1 min », « 2 h », then the day « lun. ».

## Accessibility
- Items are list items; the title is the link. Unread and priority are announced (« Non lu · Urgent · … »).
- Swipe actions are real buttons, reachable by keyboard: focusing one opens the row.
- Priority is never colour alone: important has the warning icon, urgent the solid circle and the wording.

## Do / Don't
- Do keep at most two inline actions, primary first.
- Do reserve urgent for things that expire within the hour.
- Don't add a coloured left border or a tinted background for urgent.
- Don't swipe in the desktop panel — mark read on open instead.

## Props (web preview)
`category` · `sport` · `status` · `priority` · `icon` · `title` · `body` · `time` · `unread` · `avatar` · `people` · `thumbnail` · `actions` · `swipeable` · `swiped` · `onSwipedChange` · `onMarkRead` · `onDelete` · `variant` · `skeleton` · `href` / `onClick` · `as`. See `index.d.ts`.

## Flutter
`MuNotificationItem(notification:, priority: MuPriority.urgent, variant: MuRowVariant.regular, onTap:, onMarkRead:, onDelete:)` — a `Stack` with the two action buttons under the content, which slides with `GestureDetector(onHorizontalDragUpdate)` + `AnimatedSlide` and snaps open past half; content `Row(lead, Expanded(Column(...)), thumbnail)`. Countdown buttons tick with a `Timer.periodic` and `MuButton(countdown:)`.
