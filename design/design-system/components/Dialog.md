# Dialog

A modal decision — a question, what happens next and two clear actions — for confirmations and destructive steps that state their consequence: « Annuler la réservation ? 45 DT seront remboursés sur ton solde MatchUp. »

## When to use
- Confirm destructive or costly actions: cancel a booking, leave a game, suspend a user, delete content.
- A short task that must finish before anything else: pay my share from a summary, choose a suspension reason (M with the content slot).
- Use a **BottomSheet** for choices and forms on mobile, a **Drawer** for record details on desktop, a **Toast** for feedback. One dialog at a time.

## Anatomy & specs
| Size | Width | Use |
|---|---|---|
| S (default) | `modal-s` 400 | confirmations |
| M | `modal-m` 560 | forms, details, the content slot |
| L | `modal-l` 720 | rich dialogs (plan comparison, image crop) |

- **Panel**: `surface-elevated`, `radius-lg`, `elevation-3` (Night match: the lighter surface and a hairline, no shadow); full width up to its size, `space-4` from the viewport edges; the body scrolls when it is taller than the screen.
- **Body**: padding `space-6` (`space-5` at the bottom placement). Tone icon in a 48 circle (icon 24), `space-4` below it; title `h3`; description `body-l` `text-secondary`, `space-2` below the title.
- **Consequence line**: `space-4` below, `bg` fill, 1px `border`, `radius-md`, padding `space-3` `space-4`; icon 20 in `text-secondary` + `body` in `text`. Content slot `space-5` below.
- **Tone circle**: neutral `bg` + hairline · destructive `error-soft` / `error-text` · warning, success, info on their `-soft` / `-text`. Default icons: `warning`, `warning-circle`, `check-circle`, `info`.
- **Close**: IconButton M « Fermer », `space-3` from the top and inline end; without an icon the title keeps `space-8` clear of it.
- **Actions**: a ButtonGroup with `space-6` padding (`space-5` at the bottom placement), `space-3` gap, secondary first, primary last. **inline** (desktop): end-aligned, primary on the right; in S the pair shares the row and wraps into a full-width stack when the labels don't fit. **stack** (mobile): full width, primary at the bottom.
- **bottom** placement: a mobile card `space-2` from the screen edges and above the safe area, actions in the thumb zone.
- **Layer** `z-modal` (400) over `scrim` — ink-900 at 40 % (64 % near-black in Night match).

## States
- **Enter**: the scrim fades in and the panel scales 0.96 → 1 with a fade over `duration-slow`, `ease-enter`; the bottom placement rises 24px instead. **Exit**: the reverse over `duration-base`, `ease-exit`.
- **Dismiss**: X, scrim tap or Esc call `onClose`. `dismissible={false}` removes all three — the person has to choose an action.
- **Busy** (a payment or save is running): X hidden, Esc and scrim ignored, `aria-busy`. Put `loading` on the primary and disable the secondary.
- A `destructive` tone makes it an `alertdialog`.

## Content
- Title = the question, with « tu »: « Annuler la réservation ? », « Quitter la partie ? », « Suspendre Hamza R. ? ».
- Description = what and when: « Arena Five · Terrain 2 · sam. 18 oct. · 20h00. Tes deux invités seront prévenus. »
- Consequence = money or access, with the amount: « 45 DT seront remboursés sur ton solde MatchUp. », « Annulation gratuite jusqu’à 24 h avant : 15 DT remboursés sur ton solde. »
- Buttons reuse the title's verb: « Garder ma réservation » / « Annuler la réservation »; « Rester dans la partie » / « Quitter la partie ». Never « OK », « Oui » or « Non ».

## Accessibility
- `role="dialog"` (`alertdialog` when destructive), `aria-modal`, labelled by the title, described by the description.
- On open, focus moves inside (`data-autofocus`, else the first control that isn't the X) and Tab cycles within the panel; on close it returns to the trigger. Esc never reaches an overlay underneath.
- Page scroll is locked while open. A dialog opened from a sheet takes over the focus trap until it closes.
- Icons are decorative; the tone is always carried by the words.

## Do / Don't
- Do state the consequence, with the amount, before the destructive button.
- Do keep the safe action first and the destructive one last.
- Don't open a dialog from a dialog, or use one for information the page can show.
- Don't let a payment be dismissed half-way: set `busy`.

## Props (web preview)
`open` · `onClose` · `size` · `placement` · `tone` · `icon` · `title` · `description` · `consequence` · `consequenceIcon` · `children` · `actions` · `actionsLayout` · `dismissible` · `busy` · `closeLabel` · `role` · `safeArea` · `inline` · `autoFocus`. See `index.d.ts`.

## Flutter
`MuDialog.show(context, size: MuDialogSize.s, tone: MuTone.destructive, title: 'Annuler la réservation ?', description: …, consequence: '45 DT seront remboursés sur ton solde MatchUp.', actions: [...], dismissible: true, busy: false)` → `showGeneralDialog(barrierColor: colors.scrim, barrierDismissible: dismissible && !busy, transitionDuration: 250 ms, reverseTransitionDuration: 200 ms)` with `FadeTransition` + `ScaleTransition` (0.96 → 1). The route's `FocusScope` keeps focus inside and restores it on pop; `PopScope(canPop: !busy)` blocks Back during a payment. Bottom placement: `Align(alignment: Alignment.bottomCenter)` inside a `SafeArea`.
