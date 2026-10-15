# TextField

The base text field — visible label, helper or error, counter, prefix/suffix, leading icon and clear button — that every MatchUp input reuses.

## When to use
- Any free text or number the player types: names, e-mail, prices (suffix « DT »), distances (« km »), bios and messages (`multiline`).
- Use **PasswordField**, **PhoneField**, **OtpInput** and **SearchField** for those jobs; **Select** when the answer is one of a short list.
- **L** is the mobile default; **M** is for dense desktop dashboards (owner, coach, admin). Never mix sizes in one form.

## Anatomy & specs
| Size | Height | Padding (inline) | Value style | Icons |
|---|---|---|---|---|
| L | `control-l` 48 | `space-4` (`space-2` before a trailing button) | `body-l` | 20 |
| M | `control-m` 40 | `space-3` (`space-1` before a trailing button) | `body` | 20 |

- Label `label` in `text` → `space-2` → box → `space-1` → message (`caption`) with the counter (`caption`, tabular) at the end.
- Box: `radius-sm` (8), `surface` fill, 1px `border-control`; icon, affix and value `space-2` apart; leading icon and affixes in `text-secondary`.
- Clear button: IconButton S `x-circle` (fill) in `text-secondary`, label « Effacer », shown only when there is a value.
- Multiline: padding-block `space-3`, grows from `rows` (3) to `maxRows` (8) lines, then scrolls.
- In a form, fields sit `space-5` apart; side-by-side pairs `space-3`.

## Colours
| State | Fill | Border | Text |
|---|---|---|---|
| Default | `surface` | 1px `border-control` | `text`; placeholder `text-secondary` |
| Hover | `surface` | 1px `text-secondary` | — |
| Focus | `surface` | 2px `focus` + `focus-ring` | — |
| Error | `surface` | 1px `error` (2px + ring when focused) | message `error-text` |
| Disabled | `disabled-fill` | 1px `border` | `text-disabled`; label `text-secondary` |
| Read-only | `surface-muted` | 1px `border` | `text` |

## States
- **Focus** thickens the border to 2px `focus` (ink in Light, Volt in Night match) and adds the `focus-ring`, over `duration-fast` `ease-enter`.
- **Error** keeps the value, sets `aria-invalid` and shows `warning-circle` (fill, 16) + `error-text` message. **Success** shows `check-circle` + `success-text`.
- **Counter** « 42/280 » turns `error-text` past the limit and the field explains « 21 caractères en trop — raccourcis un peu ton texte. ». The limit is soft: pasted text is never cut.
- **Read-only** is a quiet well with an optional action (« Copier le lien »); **disabled** dims everything but the label.

## Content
- Label: a noun in sentence case, no colon — « Nom de l’équipe », « Prix par joueur ». Only optional fields say « (facultatif) »; required fields carry no asterisk.
- Placeholder is an example, never the label: « Ex. Les Requins de Lac 2 », « toi@exemple.tn ».
- Helper says why or how: « Pour te proposer des parties à moins de 10 km. »
- Error says what to fix: « Ajoute la fin de ton adresse, par exemple @gmail.com. » Validate on blur or submit, not on every keystroke.
- Units go in the suffix with a no-break space: « 15 DT », « 10 km », « 90 min ».

## Accessibility
- The visible label is a `<label for>`; `aria-describedby` points to the message and the counter.
- On submit, move focus to the first invalid field so its error is read.
- L values use `body-l` (16px): no iOS zoom. `border-control` meets 3:1 on every surface (3.3:1 Light, 3.6:1 Night).
- Set `type`, `inputMode` and `autoComplete` (`email`, `given-name`, `decimal`…). Trailing buttons have names and 44px hit areas.

## Do / Don't
- Do keep the label visible above the field at all times.
- Do keep what the player typed when you show an error.
- Don't use the placeholder as the label or for information they need after typing.
- Don't turn the border red without the icon and the message.

## Props (web preview)
`label` · `optional` · `labelAside` · `helper` · `error` · `success` · `size` · `value` / `defaultValue` / `onChange(value)` · `leadingIcon` · `prefix` · `suffix` · `clearable` · `trailing` · `maxLength` + `counter` · `multiline` / `rows` / `maxRows` · `disabled` · `readOnly` · `state`; other attributes go to the `<input>`. See `index.d.ts`.

## Flutter
`MuTextField(label:, controller:, size: MuFieldSize.l, helper:, error:, success:, optional:, leadingIcon:, prefixText:, suffixText:, clearable:, maxLength:, multiline:)` — a `StatelessWidget` returning `Column(label, field, message row)`. Build the box with `TextField` + `InputDecoration(isDense: true, floatingLabelBehavior: FloatingLabelBehavior.never, counterText: '')` and `OutlineInputBorder(borderRadius: 8)` for `enabledBorder` (1px borderControl), `focusedBorder` (2px focus) and `errorBorder`; paint the focus ring with an outer `DecoratedBox` driven by the `FocusNode`. Render label, message and counter yourself so they match this spec.
