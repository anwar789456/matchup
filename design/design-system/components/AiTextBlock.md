# AiTextBlock

AI-written text — a match recap, a training-plan summary, a post draft — on an `ai-soft` block the person can regenerate, edit, copy and rate.

## When to use
- Any paragraph the AI writes for the person: « Résumé du match », « Ton plan de la semaine », « Brouillon de post », a venue description draft for an owner.
- Not for the assistant's chat bubbles (conversation) or for short AI facts (use MatchFitScore or an AiSuggestionCard reason).

## Anatomy & specs
- Block: `ai-soft` fill, `radius-md`, padding `space-4`, gap `space-3`, no shadow — it is content, not a card.
- Header: AiLabel S (chip turns `surface` on `ai-soft`) + title in `label` + meta in `caption` `text-secondary` (« Généré à 22h14 », then « modifié par toi »).
- Body: `body-l` in `text`; paragraphs split by a blank line, `space-3` apart; single line breaks kept (plan days).
- Footer: tools on the start — tertiary S « Régénérer » (`arrows-clockwise`), « Modifier » (`pencil-simple`), « Copier » (`copy`), padding `space-2`; thumbs (IconButton S) on the end.
- Under 420px of block width the tools are icon-only (32 × 32, names kept on `aria-label` and tooltip).
- Footnote: info icon 16 + « L’IA peut se tromper. Vérifie les infos importantes. » in `caption` `text-secondary`, above it a 1px rule of `ai-text` at 18 %.

## States
- **Editing**: the body becomes a textarea (`surface`, 1px `border-control`, `radius-sm`, `body-l`, grows with its content) labelled by the title; « Annuler » (tertiary S) and « Enregistrer » (primary S, check) under it. Esc cancels, Ctrl/⌘ + Entrée saves, focus returns to « Modifier ».
- **Saved edit**: the meta adds « modifié par toi »; the « IA » chip stays.
- **Regenerating**: the text drops to `text-secondary` at 60 % and a soft `--ai-gradient` glow (26 %) sweeps over it every `duration-shimmer`; the tools are replaced by AiShimmer `status` (« L’IA réécrit le résumé… ») on `surface`. `aria-busy="true"`. The new text fades up over `duration-base`.
- **Copied**: « Copier » turns « Copié » with a check in `success-text` for `duration-success`, announced « Texte copié ».
- **Rated**: as in AiSuggestionCard — the pressed thumb stays with « Merci pour ton retour ».
- **First generation**: no text yet → AiShimmer `lines` in the same block.
- Reduced motion: the glow stands still; nothing else changes.

## Content
- Write in the « tu » voice, concrete and short: 2–4 sentences, scores in digits (« 6–4 »), levels with a comma (« 3,5 »).
- Never invent facts the app doesn't have; recaps only use recorded scores and stats.
- Keep the footnote — it is the honest default for generated text.

## Accessibility
- `section` labelled by the title; the textarea reuses that label.
- Icon-only tools keep their names (« Régénérer », « Modifier », « Copier »); thumbs are toggle buttons in a named group.
- `text` on `ai-soft` 15:1 Light, 13:1 Night; `text-secondary` 4.7:1 / 6.9:1.

## Do / Don't
- Do let the person edit before anything leaves the app — publishing is their own tap on « Publier ».
- Do keep the previous text visible while regenerating so nothing jumps.
- Don't auto-replace text the person edited when they press « Régénérer » without warning.
- Don't hide the footnote to save space.

## Props (web preview)
`title` · `meta` · `value` / `defaultValue` · `onChange` · `editing` · `onEditingChange` · `regenerating` · `regeneratingLabel` · `onRegenerate` · `onCopy` · `edited` · `feedback` · `onFeedback` · `footnote`. See `index.d.ts`.

## Flutter
`MuAiTextBlock(title:, meta:, text:, onChanged:, onRegenerate:, regenerating:, onFeedback:)` — a `StatefulWidget` (editing, draft, copied). Body ↔ `TextField(maxLines: null)` in an `AnimatedSwitcher`; the glow is an animated `ShaderMask`/`LinearGradient` overlay driven by an `AnimationController` (1.4 s, repeat); tools collapse to icons below 420 with a `LayoutBuilder`. Copy with `Clipboard.setData`.
