# Snackbar

One short message with one action — « Partie quittée · Annuler », « Joueur retiré · Annuler », « Impossible de rejoindre la partie. Réessayer » — on the same dark surface as Toast.

## When to use
- To offer an undo right after a reversible action, or a retry after an optimistic update failed.
- To report a connection state while it lasts: « Hors ligne. Reconnexion… ».
- Use a **Toast** when the message needs a title and detail, a **Banner** when the problem blocks the page.

## Anatomy & specs
- Surface `toast-bg`, text `toast-text`, `radius-md`, `elevation-2`, min height 48, padding `space-3` / `space-2` / `space-3` / `space-4`, gap `space-3`.
- Message in `body`; optional leading icon 20 (regular weight) in the tone colour (`warning` for offline, `error` for a failed action).
- One action: text button in `label`, `toast-action`, 32 high, hit area 44, pushed to the end. No close button and no title.
- Line: 2px at the bottom in the tone colour (neutral: `toast-action`) emptying over `duration-toast`; while `busy`, a 32 % segment slides across every `duration-shimmer` instead.

| Platform | Placement | Width | Lines |
|---|---|---|---|
| Mobile | same region as toasts: `space-4` above the tab bar or the sticky action bar | screen − 2 × `space-4` | the message can wrap to 2 lines; the action stays at the end |
| Desktop | bottom centre of the content area, `space-6` from the bottom | fits the text, 360 (`toast`) to 560 (`modal-m`) | one line |

## States
- **Enter / exit**: fade + 8px slide over `duration-base` (`ease-enter` / `ease-exit`).
- **Timed** (default): leaves after `duration-toast`; hover and focus pause it. Pressing the action runs it and closes the snackbar.
- **Busy / persistent**: « Hors ligne. Reconnexion… » stays with the moving line until the connection is back, then gives way to « De nouveau en ligne » (timed).
- **Optimistic rollback**: the UI shows the result at once (« Inscrit »); if the server refuses, the UI returns to its previous state and an error snackbar says so with « Réessayer ».
- Reduced motion: no slide; the busy line stands still at 60 %.

## Content
- Past participle + object, ≤ 40 characters so it fits one desktop line: « Partie quittée », « Joueur retiré », « Lien copié ».
- Failures say what didn't happen: « Impossible de rejoindre la partie. » — the action says what to do: « Réessayer ».
- Action labels: « Annuler » (undo), « Réessayer », « Voir ». One word if possible.

## Accessibility
- `role="status"` + `aria-live="polite"`; error snackbars are `role="alert"`.
- The undo stays reachable by keyboard while the timer is paused by focus; give undo snackbars the full 4 s at least.
- Never rely on the line or the colour: the words carry the meaning.

## Do / Don't
- Do roll the UI back before showing the error snackbar — the screen must tell the truth.
- Do keep optimistic updates for low-risk actions (join a free or pay-on-site game, follow, like); payments are never optimistic.
- Don't show a snackbar and a toast for the same event.
- Don't put a second action or a close button in a snackbar.

## Props (web preview)
`message` · `action` · `onAction` · `icon` · `tone` · `busy` · `duration` · `persistent` · `paused` · `elapsed` · `onDismiss`. See `index.d.ts`.

## Flutter
`MuSnackbar.show(context, message: 'Partie quittée', action: MuAction('Annuler', onUndo))` — `ScaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: toastBg, width: isDesktop ? null : …))` with `MuTheme` text styles; the busy line is a `LinearProgressIndicator(minHeight: 2)` without a value. Use the same `MuToaster` queue as toasts on mobile.
