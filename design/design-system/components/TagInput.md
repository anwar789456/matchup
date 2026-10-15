# TagInput

A field that turns typed words into removable tags — Enter or comma to add, a « 3/5 » counter, a suggestions dropdown, and an optional row of AI-suggested tags the player taps to add.

## When to use
- Forum post tags, coach specialities, interests on a profile: short free labels that help others find content.
- For a fixed list of values use MultiSelect; for one value use TextField or Select.

## Anatomy & specs
- **Box**: the TextField box (`radius-sm`, `surface`, 1px `border-control`) that wraps onto more lines; padding-block 7px so one row of chips keeps it at 48 (L) / 40 (M); gaps `space-2`.
- **Tags**: Chip `input` — M (32) in L fields, S (24) in M fields — with a remove ✕; the text input fills the rest of the line (min 48 px).
- **Counter**: « 2/5 » (`caption`, tabular) at the end of the message row.
- **Dropdown**: `space-1` below, `surface-elevated`, `elevation-2`, `radius-lg`; header « Tags populaires » (empty input) or « Suggestions »; rows ≥ 44 with `hash` 20, the match in a Volt marker, and a « Créer … » row with `plus` when the typed tag is new.
- **AI row** (`aiSuggestions`), `space-3` under the field:
  - header: `sparkle` (fill, 16) + « Suggérés par l’IA » (`label-s`, `ai-text`), the reason (`caption`, `text-secondary`), and ✕ « Masquer les suggestions de l’IA »;
  - proposals: 32 high pills, `radius-full`, `ai-soft` fill, 1px dashed `ai-500` border (solid on hover), `plus` 16 + `label` in `ai-text`, `space-2` apart.

## States
- Default, hover, focus, error (« Ajoute au moins un tag pour publier. »), disabled (chips dimmed, no ✕).
- **Max reached**: the input stops accepting text and the message says « 5 tags maximum. Retire un tag pour en ajouter un autre. »
- **Duplicate**: nothing is added and the message reads: « Padel » est déjà ajouté.
- **AI**: a proposal tapped becomes a normal tag and leaves the row; the row disappears when empty or dismissed. AI never adds a tag on its own.

## Content
- Tags are 1–3 words, sentence case, no « # » typed: « Padel », « Lac 2 », « Débutants bienvenus ». Commas split pasted lists.
- The AI reason is specific: « D’après le titre de ton post ».
- Helper explains the value: « Les tags aident les joueurs à trouver ton post. »

## Accessibility
- The text input is a `combobox` with a `listbox` of suggestions (`aria-activedescendant`); the counter and message are in `aria-describedby`.
- Keys: Entrée or virgule adds, ↑ ↓ pick a suggestion, Retour arrière on an empty input removes the last tag, Échap closes the list.
- Each ✕ is named « Retirer le tag Padel »; each AI proposal « Ajouter le tag Padel, suggéré par l’IA ».
- AI colour is never the only cue: the sparkle and the words « Suggérés par l’IA » carry it.

## Do / Don't
- Do show AI suggestions as proposals with their reason, and let the player dismiss them.
- Do accept a pasted list « padel, lac 2, débutants ».
- Don't auto-add AI tags or pre-fill the field with them.
- Don't allow more than 5 tags on a post — they stop helping search.

## Props (web preview)
`label` · `optional` · `helper` · `error` · `size` · `value` / `defaultValue` / `onChange(tags)` · `max` · `placeholder` · `suggestions` · `aiSuggestions` · `aiReason` · `onDismissAi` · `disabled` · `open` · `activeIndex` · `defaultInput` · `state`. See `index.d.ts`.

## Flutter
`MuTagInput(tags:, onChanged:, max: 5, suggestions:, aiSuggestions:, aiReason:, onDismissAi:)` — an `InputDecorator` styled like `MuTextField` containing a `Wrap` of `MuChip.input`s and a borderless `TextField` (`onSubmitted` and a comma listener add the tag; a `RawKeyboardListener` handles Backspace). Use `RawAutocomplete<String>` for the dropdown and a `Wrap` of `MuAiChip`s (dashed border via `DottedBorder` or a `CustomPainter`) for the AI row.
