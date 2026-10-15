# TopBar

The desktop dashboard bar: where you are, global search (⌘K), the AI assistant, notifications and your account.

## When to use
- At the top of every dashboard page, right of the Sidebar, sticky (`z-sticky`).
- Page title on top-level pages; Breadcrumbs from the second level down.

## Anatomy & specs
| Part | Spec |
|---|---|
| Bar | `top-bar` 64, `surface`, 1px `border` hairline at the bottom, padding-inline `space-8` (the page margin), gap `space-4` |
| Title | `h3`, one line |
| Search | a 40 (`control-m`) trigger, `radius-sm`, `surface-muted` + 1px `border`; magnifying-glass 20, placeholder `body` `text-secondary`; key hint `label-s` on a `surface` key cap — « ⌘ K » on macOS, « Ctrl K » elsewhere. Takes the leftover width up to 480, never under 200 |
| Assistant | 40 pill, 1.5px `ai-gradient` edge on `surface`, sparkle (Fill) + `label` in `ai-text` |
| Bell | IconButton M, Counter badge capped at « 99+ » |
| Account | Avatar S + `label` name + `caption` role + caret-down 16, 48 high, `radius-full` |
| Menu | ≥ 280, `surface-elevated`, `elevation-2`, `radius-lg`, padding `space-2`; header Avatar M + name + email; items 40 (`radius-sm`, icon 20 in `text-secondary`, `body`); the wallet shows its balance in `num-s` (« 1 250 DT ») |

## States
- **Search**: hover → `border-strong`; focus → `border-control`, `surface` and `focus-ring`.
- **Assistant**: hover fills `ai-soft`; pressed 0.98.
- **Account**: hover wash at `opacity-hover`; open wash at `opacity-pressed`, caret turns 180° (`ease-move`).
- **Menu**: enters over `duration-base` `ease-enter`; items wash on hover, ring on focus.

## Content
- Placeholder names what you can find: « Rechercher un joueur, un terrain, une réservation… ».
- Menu: « Mon profil · Portefeuille · Paramètres · Changer de rôle · Se déconnecter » — sign-out last, after a separator, in `text` (it is not destructive).

## Accessibility
- The search is a button that opens the command palette (`aria-haspopup="dialog"`, `aria-keyshortcuts="Meta+K"`), so no unlabeled input lives in the bar.
- The bell label carries the count (« Notifications, 128 non lues »).
- Account trigger: `aria-haspopup="menu"`, `aria-expanded`; in the menu ↑ ↓ Home End move, Esc closes and refocuses the trigger, an outside press closes.
- « Assistant » is a visible label; the gradient is decoration only.

## Do / Don't
- Do keep one AI entry point per screen: this button on desktop, the Fab on mobile.
- Do let the search shrink before the breadcrumbs do.
- Don’t add icon buttons to the bar; new tools go in the Sidebar or the page.

## Props (web preview)
`title` · `breadcrumbs` · `searchPlaceholder` · `shortcut` · `onSearch` · `assistant` · `assistantLabel` · `onAssistant` · `notifications` · `onNotifications` · `user` · `menuItems` · `menuOpen` · `defaultMenuOpen` · `onMenuOpenChange` · `states`. See `index.d.ts`.

## Flutter
`MuTopBar(title:, breadcrumbs:, onSearch:, shortcut: '⌘K', notifications:, user:, menuItems:)` — a 64 `Container` with `Border(bottom: BorderSide(color: border))` and a `Row`: start, `Flexible(child: ConstrainedBox(maxWidth: 480))` search, `Spacer`, end cluster. ⌘K / Ctrl K through `CallbackShortcuts`; the account menu is a `MenuAnchor` with `MenuItemButton`s.
