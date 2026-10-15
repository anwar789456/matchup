# OtpInput

Six boxes for the SMS verification code, with auto-advance, paste-to-fill, error and success states and a resend countdown.

## When to use
- Phone verification after sign-up, and confirming sensitive changes (new phone number, payout details).
- Not for PINs the player chooses; use PasswordField.

## Anatomy & specs
| Part | Spec |
|---|---|
| Box | 48 × 56 (`control-l` × `control-xl`), `radius-sm`, `surface`, 1px `border-control`, `space-2` gaps (328 total) |
| Digit | `num-l` (Barlow Condensed 28/32, tabular), centred, `text` |
| Active box | 2px `focus` border + a 2 × 28 blinking caret in `focus` |
| Label | `label` above, `space-2` |
| Message | `caption` with icon, `space-2` below the boxes |
| Resend | `body` in `text-secondary` + countdown in `num-s` `text`, `space-4` below |

- Boxes stay left-to-right in every language.

## States
- **Empty**, **active** (focus border and caret), **filled**.
- **Error**: all boxes `error` border, a short shake (`duration-slow`, skipped with reduced motion) and « Code incorrect. Il te reste 2 essais. »
- **Success**: `success` border, `success-soft` fill, digits in `success-text`, « Numéro vérifié. »
- **Verifying**: boxes locked, Spinner 16 + « Vérification du code… » (`role="status"`).
- **Disabled**: `disabled-fill`; say why and when it comes back: « Trop d’essais. Réessaie dans 10 minutes. »
- **Resend**: « Renvoyer le code dans 0:45 » ticks every second, then becomes the link « Renvoyer le code »; it hides after success.

## Content
- Above: « Entre le code envoyé au +216 20 123 456. » — always show where the code went.
- Helper: « Le code expire dans 10 minutes. »
- Errors count remaining tries; never blame (« Code incorrect », not « Tu t’es trompé »).

## Accessibility
- The boxes form a `role="group"` named by the label; each input is « Chiffre 1 sur 6 ».
- `inputMode="numeric"`, `pattern="[0-9]*"`, and `autoComplete="one-time-code"` on the first box so iOS and Android offer the SMS code; autofill or paste fills every box.
- Keyboard: digits advance, Backspace clears then moves back, ← → move between boxes.
- Verify automatically on the 6th digit (`onComplete`), but keep a visible « Vérifier » button.

## Do / Don't
- Do keep the entered digits after an error so the player sees what they typed.
- Do let them correct one box without retyping all six.
- Don't clear the boxes on resend until the new code arrives.
- Don't make the countdown longer than 60 s.

## Props (web preview)
`length` · `value` / `defaultValue` / `onChange(code)` · `onComplete(code)` · `label` · `helper` · `error` · `success` · `verifying` · `disabled` · `resendIn` + `onResend` · `autoFocus` · `focusIndex`. See `index.d.ts`.

## Flutter
`MuOtpInput(length: 6, onCompleted: (code) {}, errorText:, success:, verifying:, resendIn: Duration(seconds: 45), onResend:)` — build it on ONE hidden `TextField` (`keyboardType: number`, `autofillHints: [AutofillHints.oneTimeCode]`, `maxLength: 6`, digits-only formatter) that drives six painted boxes in a `Row`; tapping a box focuses the field. Auto-advance, backspace and paste then come for free and SMS autofill works on both platforms. Shake with a `TweenSequence` on `Transform.translate`; tick the countdown with a `Timer.periodic`.
