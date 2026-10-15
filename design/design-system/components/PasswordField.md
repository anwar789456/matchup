# PasswordField

A TextField for passwords with a show/hide button, an optional 4-segment strength meter and a live checklist of requirements.

## When to use
- **Sign-in** (« Content de te revoir »): the field and the show/hide button only, with « Mot de passe oublié ? » as `labelAside`.
- **Create or change a password**: add `strength` and `rules` so the player sees what is missing while typing.
- Confirmation fields reuse it without meter or rules, and show `success` once both match.

## Anatomy & specs
- The TextField chrome (L 48 / M 40, `radius-sm`, `surface`, 1px `border-control`) with a trailing IconButton S: `eye` « Afficher le mot de passe » ↔ `eye-slash` « Masquer le mot de passe ».
- Under the message, `space-3` below the box: the meter, then the checklist, `space-3` apart.
- **Meter**: 4 segments of 4px, `radius-full`, `space-1` gaps, track `border`; the level label (`label-s`) sits at the end in a 64px slot so the bars never jump.
- **Checklist**: `caption` rows `space-1` apart, icon 16 + label `space-2` apart.

| Level | Segments | Fill | Label |
|---|---|---|---|
| Faible | 1 | `error` | `error-text` |
| Moyen | 2 | `warning` | `warning-text` |
| Bon | 3 | `info` | `info-text` |
| Excellent | 4 | `success` | `success-text` |

Score = one point each for 8+ characters, upper + lower case, a digit, a symbol or 12+ characters; under 8 characters the level is always Faible.

## States
- Default, hover, focus, disabled and error follow TextField. The toggle keeps the caret where it was.
- Rules: unmet → `circle` (regular) in `text-secondary`; met → `check-circle` (fill) in `success-text` with the label in `text`; after a failed submit, unmet rules turn `x-circle` + `error-text`.
- Empty meter shows grey bars and « Sécurité » in `text-secondary`.

## Content
- Rules are short, positive and countable: « 8 caractères minimum », « Une majuscule », « Un chiffre ».
- Sign-in error never says which part is wrong: « Mot de passe incorrect. Réessaie ou réinitialise-le. »
- Sign-up error points to the list: « Ton mot de passe doit respecter les 3 règles. »

## Accessibility
- `autoComplete`: `current-password` for sign-in, `new-password` when the meter or rules are on, so password managers can help.
- The meter level is a polite live region (« Sécurité du mot de passe : Bon »); meter and checklist are linked with `aria-describedby`; each rule says « fait » or « à faire » to screen readers.
- The level is never colour alone: number of segments + word.
- The toggle has a changing name instead of `aria-pressed`; `spellCheck`, `autoCapitalize` and `autoCorrect` are off.

## Do / Don't
- Do let players paste and show the password — it reduces typos more than a second field does.
- Do keep the rules visible from the first keystroke on sign-up.
- Don't show the meter or rules on sign-in.
- Don't block weak passwords silently: say which rule is missing.

## Props (web preview)
All TextField props except `prefix`/`suffix`/`multiline` · `strength` · `rules` (`true` or `{ label, test }[]`) · `visible` / `defaultVisible` / `onVisibleChange`. See `index.d.ts`.

## Flutter
`MuPasswordField(controller:, strength: true, rules: MuPasswordRules.standard, labelAside:, error:)` — wraps `MuTextField` with `obscureText` bound to a local `ValueNotifier<bool>` and a `MuIconButton` as `suffixIcon`. Compute the score in a pure `passwordScore(String)`; the meter is a `Row` of 4 `Expanded` bars with `AnimatedContainer(duration: 200ms)`. Set `autofillHints: [AutofillHints.newPassword]` or `password` and wrap sign-in in an `AutofillGroup`.
