# Menu

Dropdown and « … » context menus — a short list of actions with icons, shortcut hints, checks, section labels, submenus and the destructive action last — or the same items as a mobile action sheet.

## When to use
- « … » on a card or a row: « Partager la partie », « Copier le lien », « Supprimer la partie ».
- Dropdowns: sorting (« Trier par » radio items), the account menu, display options as checkbox items.
- Mobile: `presentation="sheet"` shows the same items in a BottomSheet.
- Use a **Select** for a form value, a **Popover** for content, a **SegmentedControl** for 2–4 views.

## Anatomy & specs
| Part | Dropdown (desktop) | Sheet (mobile) |
|---|---|---|
| Panel | `surface-elevated`, `radius-lg`, `elevation-2`, padding `space-2`; 224–320 wide, or `width` | BottomSheet `auto` with a title; body inset `space-2` |
| Row | min `control-m` 40, padding `space-2` `space-3`, `radius-sm`, gap `space-3` | min `control-xl` 56, padding inline `space-2`, gap `space-4` |
| Icon · label | 20 in `text-secondary` · `body` | 24 · `body-l` |
| Extras | shortcut hint `caption` in a 1px `border` box (`radius-xs`) · `check` 16 · `caret-right` 16 for submenus | `check` 16 only |

- Rows without an icon keep an empty 20 slot when others have one, so labels align. A `hint` (why it's disabled) sits under the label in `caption` `text-secondary`.
- **Separator**: 1px `border`, full bleed, `space-2` above and below. **Section label**: `overline` `text-secondary`, padding `space-2` `space-3` `space-1`.
- **Submenu**: a second panel `space-3` beyond the first, aligned with its row.
- **Placement** as Popover (default `bottom-start`, logical), `space-2` from the trigger. **Layer** `z-popover` (200); no scrim — the sheet presentation uses the BottomSheet's `z-sheet` and `scrim`.

## States
- **Hover / keyboard-active**: a wash at `opacity-hover`; **pressed** `opacity-pressed`; **focus** an inset 2px `focus` ring.
- **Checked** (checkbox, radio): `check` 16 at the end. **Disabled**: `text-disabled`, no wash, with its hint. **Destructive**: label and icon in `error-text`, last, after a separator.
- **Enter**: fade + 4px slide + scale 0.98 → 1 over `duration-base`, `ease-enter`; submenus scale in. **Exit**: fade over `duration-fast`, `ease-exit`.
- **Choosing** an item closes the menu and returns focus to the trigger; checkbox items, `keepOpen` items and `closeOnSelect={false}` keep it open. A click outside closes it.
- The « … » trigger can show its pressed state (`pressed`) while the menu is open.

## Content
- Labels are verb + object, sentence case: « Inviter des joueurs », « Ajouter au calendrier », « Dupliquer la partie ».
- Disabled items say why: « Modifier la partie » · « Seul l’organisateur peut la modifier ».
- Shortcuts as shown on the keyboard, with a spoken form: « ⌘C » / « Commande C ».
- At most one destructive item, last: « Supprimer la partie ».

## Accessibility
- `role="menu"` with `menuitem`, `menuitemcheckbox` and `menuitemradio` (`aria-checked`); sections are labelled groups; submenu rows carry `aria-haspopup` and `aria-expanded`. The trigger gets `aria-haspopup="menu"`, `aria-expanded` and `aria-controls`.
- On the trigger, ↓ / ↑ open on the first / last item. In the menu: ↓ / ↑ (wrapping), Home / End, type-ahead, Enter / Space to choose, → opens a submenu and ← closes it (swapped in RTL), Esc closes and returns focus to the trigger, Tab closes and moves on.
- The dropdown doesn't trap focus; the sheet does, like any modal BottomSheet.
- Dropdown rows are 40 for pointer use; the sheet's 56 rows meet the 44 touch target. The « … » IconButton is labelled « Plus d’actions ».

## Do / Don't
- Do keep menus short and grouped with separators and section labels.
- Do show an unavailable action disabled with its reason when people expect to find it there.
- Don't put the destructive action anywhere but last; when it can't be undone it opens a Dialog.
- Don't nest more than one submenu level, and flatten submenus for the sheet — it shows them as plain items.

## Props (web preview)
`trigger` · `items` · `open` · `defaultOpen` · `onOpenChange` · `onSelect` · `placement` · `label` · `title` · `presentation` · `width` · `closeOnSelect` · `inline` · `autoFocus` · `safeArea`; each item: `type` · `label` · `icon` · `shortcut` · `shortcutLabel` · `hint` · `checked` · `disabled` · `destructive` · `items` · `defaultOpen` · `keepOpen` · `onSelect` · `state` (preview only). See `index.d.ts`.

## Flutter
`MuMenu(trigger: MuIconButton(icon: 'dots-three', label: 'Plus d’actions'), items: [MuMenuItem(...), MuMenuItem.separator(), MuMenuItem.checkbox(...), MuMenuItem.submenu(...)])` → `MenuAnchor` with `MenuItemButton` (`leadingIcon`, `shortcut: SingleActivator(...)`), `CheckboxMenuButton`, `RadioMenuButton` and `SubmenuButton`, styled through a `MenuStyle` from `MuTheme` (`surfaceElevated`, 16 radius, 8 padding). Mobile: `MuBottomSheet` with 56-high rows built from the same item list.
