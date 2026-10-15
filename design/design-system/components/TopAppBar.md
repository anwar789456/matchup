# TopAppBar

The mobile top bar — where you are, the way back and up to two actions — in four forms: compact, large (collapses on scroll), over media, and the Home header.

## When to use
- **Compact** (`app-bar` 56) on detail and flow screens: back + title + at most 2 actions (« Partager », « Plus d’actions »).
- **Large** (`app-bar-large` 112) on tab roots (« Mes matchs », « Explorer », « Communauté »): the `h1` collapses into the compact row once content scrolls.
- **Media** on venue, game and tournament pages that open on a photo: transparent bar, on-media buttons; the title appears when the photo has scrolled away.
- **Home** on Accueil only: greeting, location chip, notifications, account.

## Anatomy & specs
| Part | Spec |
|---|---|
| Row | `app-bar` 56, padding-inline `space-1`; actions are IconButton L (48 target, `icon-m` 24) so icons sit on the 16px margin |
| Compact title | `h3`; with a subtitle `label-l` + `caption` in `text-secondary`; starts at `space-4` when there is no back button |
| Large title | `h1` in a 56 row, padding `space-4`, bottom `space-2`; one line, ellipsis |
| Over media | IconButton M `on-media` (40, `surface` + `elevation-2`), padding and gap `space-2` (icons keep the same centres); a flipped `photo-scrim` at 70% under the status bar |
| Home | Chip (map-pin · « La Marsa » · caret-down) · bell IconButton L with Counter badge · Avatar S (32) in a 48 button |
| Inset | `inset` = status-bar height: the bar paints behind the status bar, content starts below |

## Variants
`compact` · `large` · `media` · `home`. Large and home share the collapse; media shares the compact row.

## States
- **At rest**: transparent over the page (`bg`), no shadow.
- **Scrolled** (`scrolled`): `surface` + `elevation-2` (Night match: lighter surface + hairline) over `duration-base` `ease-enter`.
- **Collapsed** (`collapsed`): the large row folds to 0 and its title fades out while the compact title fades in (`duration-base`, `ease-move`). Drive it from the scroll offset: collapse past 64, expand under 8.
- **Media → scrolled**: on-media buttons become ghost IconButtons, the title fades in.
- Hover, pressed and focus come from IconButton and Chip.

## Content
- Titles are nouns, sentence case, about 24 characters max: « Mes matchs », « Arena Five », « Five du samedi ».
- Subtitle = when and where: « sam. 18 oct. · 20h00 · Arena Five ».
- Greeting « Salut Yassine » — first name, never an emoji; Arabic « أهلاً ياسين ».
- The location chip shows the district (« La Marsa »), not an address.

## Accessibility
- The title is the screen’s single `h1` (in large mode the compact copy is `aria-hidden`).
- Back is IconButton « Retour » (the arrow mirrors in RTL); every action has a label; the bell label carries the count (« Notifications, 3 non lues »).
- Account button « Mon compte, Yassine B. » with `aria-haspopup="menu"` and `aria-expanded`; the location chip has `aria-haspopup="dialog"` and keeps its visible text in its name.

## Do / Don't
- Do keep two actions max; the rest go behind « Plus d’actions » (dots-three-vertical).
- Do use media only when the page opens on a photo (real photography or CourtArt).
- Don’t centre titles — start-aligned stays predictable with long names and in RTL.
- Don’t put the main CTA in the bar — it lives in the sticky bottom bar.

## Props (web preview)
`variant` · `title` · `subtitle` · `onBack` · `backLabel` · `leading` · `actions` · `collapsed` · `scrolled` · `inset` · `greeting` · `location` · `locationLabel` · `onLocationClick` · `notifications` · `user` · `onAvatarClick` · `avatarExpanded`. See `index.d.ts`.

## Flutter
`MuTopAppBar.compact(title:, subtitle:, onBack:, actions:)`, `MuTopAppBar.large(title:, actions:)`, `MuTopAppBar.media(title:, onBack:, actions:)`, `MuTopAppBar.home(greeting:, location:, notifications:, user:)`. Build compact on `SliverAppBar(pinned: true)`; large and home on a `SliverPersistentHeader` (min 56, max 112) whose delegate fades the `h1` with the shrink offset; map `scrolledUnderElevation` to MuTheme `elevation-2`. Media: `extendBodyBehindAppBar` + `SystemUiOverlayStyle.light` until the header collapses.
