# LoadingOverlay

The blocking overlay shown only while a payment is processed — a spinner, « Paiement en cours… », the amount and « Ne ferme pas cette page » — that turns into « Paiement confirmé ».

## When to use
- Between « Payer 15 DT » and the payment's result: paying a share, paying for a group, topping up the wallet.
- Nowhere else: content loads with skeletons, saves use the button's `loading`, the bank's own step is `Takeover.SecurePayment`.

## Anatomy & specs
| Part | Spec |
|---|---|
| Layer | `z-takeover` (600) — above toasts, so nothing covers a payment; content centred with `space-6` padding over `scrim` (ink-900 at 40 %, 64 % in Night match); `progress` cursor |
| Card | up to `modal-s` 400 wide, padding `space-8` `space-6` `space-6`, gap `space-4`, centred text; `surface-elevated`, `radius-lg`, `elevation-3` |
| Icon | 56 circle on `bg` with a 1px `border`, holding a 32 Spinner; success: `success-soft` with `check-circle` 40 (fill) in `success-text` |
| Text | title `label-l` · amount `num-xl` « 15 DT » · detail `caption` `text-secondary`, `space-1` apart |
| Message | pill, `radius-full`, `bg` + hairline, padding `space-1` `space-3`: `lock-simple` 16 + « Ne ferme pas cette page » in `label-s` `text-secondary`; hidden on success |

## States
- **Processing** (`status="processing"`): spinner, `aria-busy`.
- **Success** (`status="success"`): the icon pops to the check (scale 0.6 → 1 over `duration-base`, `ease-pop`), the title becomes « Paiement confirmé » and the message goes; the screen then closes it and moves on.
- **Enter**: the scrim fades in and the card scales 0.96 → 1 over `duration-slow`, `ease-enter`. **Exit**: the reverse over `duration-base`, `ease-exit`.
- **Never dismissible**: no X, scrim taps do nothing, Esc is swallowed.
- **Failure**: close the overlay and explain on the payment screen (field or Banner), with a Toast — never inside this card.

## Content
- « Paiement en cours… » with the ellipsis character, then « Paiement confirmé ».
- The amount is what this person pays now: « 15 DT », or « 45 DT » for toi + 2 invités.
- The detail says what for: « Padel · Smash Padel Club · mar. 21 oct. · 19h00 »; on success, the outcome: « Ta place est confirmée · reçu envoyé par e-mail ».
- The message stays « Ne ferme pas cette page ».

## Accessibility
- `role="alertdialog"`, `aria-modal`, labelled by the title and described by the message; `aria-busy` while processing.
- The texts sit in a `role="status"` polite live region, so « Paiement confirmé » is announced.
- Focus moves to the card and can't leave it; page scroll locks; focus returns to the pay button when it closes.
- Progress is said in words, never by the spinner alone.

## Do / Don't
- Do show the amount and what it pays for.
- Do keep the pay button in its loading state behind the overlay.
- Don't use it for page loads, searches or saves.
- Don't add a cancel action — a payment in flight can't be stopped from here.

## Props (web preview)
`open` · `status` · `title` · `amount` · `detail` · `message` · `inline` · `autoFocus`. See `index.d.ts`.

## Flutter
`MuLoadingOverlay.show(context, amount: '15 DT', detail: 'Padel · Smash Padel Club · mar. 21 oct.')` returns a controller with `success()` and `close()` → `showGeneralDialog(useRootNavigator: true, barrierDismissible: false, barrierColor: colors.scrim, transitionDuration: 250 ms)` wrapped in `PopScope(canPop: false)`. The icon is an `AnimatedSwitcher` between a 32 `CircularProgressIndicator` and the check; announce the result with `SemanticsService.announce`.
