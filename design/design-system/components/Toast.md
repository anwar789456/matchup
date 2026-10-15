# Toast

Non-blocking feedback after an action — « Réservation confirmée », « Paiement refusé par ta banque », « Lien copié » — that leaves on its own after 4 s, with at most one action.

## When to use
- To confirm or report the result of something the person just did, without stopping them.
- Use a **Snackbar** for an undo (« Partie quittée · Annuler »), a **Banner** for anything that must stay until it is fixed, a dialog for decisions.
- Never put the only copy of important information in a toast: a refused payment is also shown on the payment screen.

## Anatomy & specs
- Surface `toast-bg` (dark in both themes), text `toast-text`, `radius-md`, `elevation-2`, padding `space-3` / `space-2` / `space-3` / `space-4`.
- Grid: icon 20 (fill) · title `label` · action · close on the first line; description in `caption` (`toast-text` at 74 %) on the second line, running under the action. Gaps `space-3` / 2px.
- Icon in the base status colour: `success`, `error`, `warning`, `info` (≥ 3.3:1 on `toast-bg`). Neutral: no icon by default, or a regular icon in `toast-text` (`link` for « Lien copié »).
- Action: text button in `label`, `toast-action` (Volt — allowed because the ground is always dark), 32 high, padding `space-2`, hit area 44.
- Close: IconButton S `x` in `toast-text` at 80 %, « Fermer ».
- Progress line: 2px at the bottom edge in the tone colour (neutral: `toast-action`), shrinking toward the start over `duration-toast`.

| Placement | Where | Width | Order |
|---|---|---|---|
| Mobile (`bottom`) | `space-4` above the tab bar (or the sticky action bar) | screen − 2 × `space-4` | newest in front |
| Desktop (`top-end`) | `space-4` under the top bar, `space-6` from the edge | `toast` 360 | newest on top |

## States
- **Enter**: fade + 8px slide toward its edge over `duration-base`, `ease-enter`. **Exit**: the reverse on `ease-exit`.
- **Auto-dismiss**: after `duration-toast` (4 s). Hover or keyboard focus pauses the timer and the line; so does an expanded stack.
- **Stack**: max 3 (`z-toast`). Collapsed, older toasts peek 10px behind the newest at scale 0.95 / 0.90 with their content hidden; hover, focus or a tap expands the stack (gap `space-2`, `ease-move`). The 4th waits in the queue.
- **Persistent**: no line, stays until closed — only for an error that offers « Réessayer ».
- Reduced motion: no slide, no line; the timer is unchanged.

## Content
- Title = what happened, in 2–5 words: « Réservation confirmée », « Lien copié », « Profil mis à jour ».
- Errors say what happened, then what to do: « Paiement refusé par ta banque » + « Aucun montant débité. Essaie une autre carte. »
- One verb action: « Voir », « Réessayer », « Payer ». Never « OK ».

## Accessibility
- `role="status"` + `aria-live="polite"` (`aria-atomic`); error toasts are `role="alert"`. The region is a labelled `section` (« Notifications »).
- Pausing on hover and focus gives time to read and act (WCAG 2.2.1); every toast can be closed by keyboard.
- Focus rings inside the toast are 2px `toast-action`, visible in both themes.

## Do / Don't
- Do keep one toast per event and replace a toast that repeats.
- Do lift the AI FAB above the toast while it shows.
- Don't use a toast for form errors — show them on the field.
- Don't stack more than 3 or put two actions in one toast.

## Props (web preview)
`tone` · `title` · `description` · `icon` · `action` · `onAction` · `onClose` · `dismissible` · `duration` · `persistent` · `paused` · `elapsed` · `onDismiss`; `Toast.Stack`: `placement` · `max` · `expanded` · `offset` · `contained`. See `index.d.ts`.

## Flutter
`MuToast.show(context, tone: MuTone.success, title: 'Réservation confirmée', description: …, action: MuAction('Voir', onTap))` → a `MuToaster` overlay (one `OverlayEntry` per region) keeping a queue of 3. Each toast is an `AnimatedSlide` + `FadeTransition` over a `DecoratedBox(toastBg)`, with a `LinearProgressIndicator`-style line driven by the timer's `AnimationController`; wrap in `MouseRegion`/`Focus` to pause, and `Dismissible` for swipe on mobile. Announce with `SemanticsService.announce`.
