# RichTextEditor

A text area with a formatting toolbar — Gras, Italique, Titre, Liste, Liste numérotée, Citation, Lien, Image — for forum posts and coach programs.

## When to use
- Long, structured text that others will read: forum posts and replies, tournament announcements, coach program sessions.
- Short plain text (bio, message to players) uses TextField `multiline` — no toolbar.

## Anatomy & specs
- Label (`label`) → `space-2` → one box: `radius-sm`, `surface`, 1px `border-control`, holding the toolbar and the content.
- **Toolbar**: padding `space-2`, IconButtons S (32, 44 hit area) `space-1` apart, 1 × 20 `border` separators between Text · Blocks · Insert, 1px `border` rule underneath. It scrolls horizontally on narrow screens. Icons keep the regular weight when pressed.
- **Pressed tool**: Volt fill (`accent`) with `on-accent` icon, `aria-pressed="true"` — follows the caret (bold text → « Gras » on).
- **Content**: padding `space-3` `space-4` `space-4`; paragraphs, lists and quotes in `body-l` (16/24), headings in `h3`; blocks `space-3` apart (`space-5` before a heading); list markers `text-secondary`; quote = `space-4` indent with a 3px `border-strong` rule and `text-secondary` text; links in `link`, underlined.
- **Height**: `minRows` × 24 (default 5 lines), grows to `maxRows` (14) then scrolls.
- **Link bar**: opens under the toolbar on `surface-muted` — URL field, « Ajouter » (primary S), ✕.
- Message and counter « 380/2 000 » under the box, as in TextField.

## States
- Empty (placeholder `body-l` in `text-secondary`), hover, focus (2px `focus` + `focus-ring` around the whole box), filled, error (`error` border + message, text kept), disabled (`disabled-fill`, toolbar `text-disabled`).
- Past `maxLength` the counter turns `error-text` and the message says how many characters to remove.

## Content
- Placeholder invites: « Partage une astuce, une question ou une annonce… ».
- Headings are short and factual: « Tournoi de padel du samedi 25 octobre ». Prices in posts follow the formats: « 30 DT par équipe, soit 15 DT par joueur ».
- Errors explain the rule: « Ton post doit faire au moins 20 caractères. »

## Accessibility
- The toolbar is `role="toolbar"` (« Mise en forme ») with one tab stop; ← → Début Fin move between tools. Gras and Italique expose `aria-keyshortcuts` (Ctrl+B, Ctrl+I).
- The content is `role="textbox"` `aria-multiline="true"`, named by the label, described by the message and counter, `lang="fr"`, spell-checked.
- Pressed tools announce their state; toolbar clicks never steal the text selection.

## Do / Don't
- Do keep the formatting set this small: one heading level, two list types, quotes, links, images.
- Do strip pasted styles (fonts, colours, sizes) so posts stay on the type scale.
- Don't offer underline (it reads as a link) or text colour.
- Don't publish from the editor without a preview on long posts.

## Props (web preview)
`label` · `optional` · `helper` · `error` · `placeholder` · `defaultValue` (HTML) · `onChange(html, text)` · `maxLength` · `minRows` · `maxRows` · `tools` · `activeFormats` · `disabled` · `onInsertImage` · `state`. See `index.d.ts`.

## Flutter
`MuRichTextEditor(controller:, tools: MuRichTools.all, maxLength: 2000, placeholder:, error:)` — build on `flutter_quill` (`QuillEditor` + a custom toolbar of `MuIconButton.toggle`s bound to `controller.getSelectionStyle()`), restricted to bold, italic, header 3, bullet and ordered lists, blockquote and link; images go through `MuFileUpload`. Map the Quill styles to the `MuTheme` text styles and store posts as Delta JSON (render HTML server-side).
