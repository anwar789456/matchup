# PhoneField

A Tunisian phone number field: a fixed « TN +216 » segment, digits grouped « 20 123 456 » as the player types, and an 8-digit check.

## When to use
- Sign-up (last step, before the SMS code), profile contact details, venue and emergency contacts.
- MatchUp is Tunisia-only at launch: the country code is fixed, not a picker. If other countries open, this becomes a country Select in the same segment.

## Anatomy & specs
- The TextField chrome (L 48 / M 40, `radius-sm`, `surface`, 1px `border-control`).
- Segment at the start: « TN » (`label-s`, `text-secondary`, on `surface-muted`, `radius-xs`, 20px high, inset 1px `border`) · « +216 » (`body-l` / `body`, `text`) · a 1px `border-strong` divider inset `space-3` top and bottom (`space-2` in M).
- Digits use tabular figures; the box keeps left-to-right order in Arabic (numbers never mirror).
- No flag emoji: the code is the identifier.

## States
- **Typing**: digits are regrouped 2-3-3 on every change; the caret stays after the same digit. Non-digits are ignored; a 9th digit is ignored.
- **Paste**: « +216 20 123 456 » and « 0021620123456 » both become « 20 123 456 ».
- **Error** (after blur, when 1–7 digits): « Le numéro doit contenir 8 chiffres. » with the warning icon; the digits stay.
- **Success** after the SMS check: « Numéro vérifié. »
- Hover, focus, disabled follow TextField.

## Content
- Label « Numéro de téléphone »; placeholder « 20 123 456 » (the shape, not the label).
- Say why you need it: « On t’envoie un code par SMS. Il sert aussi à confirmer tes réservations. »
- Reassure on privacy under the action: « Ton numéro reste privé : seuls les organisateurs de tes parties le voient. »
- Display saved numbers as « +216 20 123 456 » (`formatPhone`).

## Accessibility
- `type="tel"`, `inputMode="tel"` (numeric keypad), `autoComplete="tel-national"`.
- The visual « TN +216 » is hidden from screen readers and replaced by « Indicatif +216, Tunisie » in `aria-describedby`.
- Errors appear on blur, not while the player is still typing.

## Do / Don't
- Do keep the value as 8 raw digits (`onChange(digits)`); format only for display.
- Do accept pasted numbers with the country code.
- Don't reject a number for its first digit; the SMS code is the real check.
- Don't put the whole number with « +216 » in the placeholder.

## Props (web preview)
`label` · `value` / `defaultValue` / `onChange(digits)` · `validateOnBlur` · `error` · `success` · `helper` · `size` · `optional` · `disabled` · `state`. See `index.d.ts`.

## Flutter
`MuPhoneField(controller:, onChanged: (digits) {}, error:)` — `MuTextField` with `keyboardType: TextInputType.phone`, `autofillHints: [AutofillHints.telephoneNumberNational]`, a `prefix` widget for the segment, and `inputFormatters: [MuPhoneFormatter()]` — one `TextInputFormatter` that keeps digits, drops a pasted leading 216 or 00216, caps at 8, inserts the spaces and maps the selection by digit count. Wrap the field in `Directionality(textDirection: TextDirection.ltr)`.
