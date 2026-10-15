# Pagination

Move through long lists: numbered pages under tables, a compact pager on mobile, or « Charger plus » until « Tu as tout vu ».

## When to use
- **Pages** under dashboard tables (bookings, users, payments), where people jump around and compare.
- **Compact** on mobile lists that need stable pages (invoices, payment history).
- **More** for feeds and search results on mobile. Infinite scroll may trigger the same action, but keep the button as the visible fallback.

## Anatomy & specs
| Part | Spec |
|---|---|
| Range | « 81–100 sur 248 »: `body`, the range in `text`, the rest in `text-secondary`, tabular figures |
| Previous / next | IconButton M (caret-left / caret-right, mirrored in RTL) — ghost; secondary in compact |
| Page | 40 × 40 (`control-m`), `radius-sm`, digits in `num-s`; gap `space-1` (44 pitch). Current page: `primary` fill + `on-primary` |
| Ellipsis | « … » in `num-s`, `text-secondary`, not focusable; siblingCount 1 gives « 1 … 4 5 6 … 13 » |
| Rows per page | `body` label « Lignes par page » + native select 40, 1px `border-control`, `radius-sm`, caret-down 16 |
| Compact | previous · « Page 5 sur 13 » (`body`, current page in `num-s`) · next |
| More | secondary Button L, full width; `caption` « 40 sur 248 parties » and a 96 × 4 meter (`text-secondary` on `border`) |
| End of list | hairlines either side of a 24 `accent` dot with an ink check + `label` « Tu as tout vu »; `caption` total · « Remonter en haut » link |

## Variants
`pages` (desktop tables) · `compact` (mobile pages) · `more` (load more + end of list).

## States
- **Page**: hover wash at `opacity-hover`, pressed `opacity-pressed` + 0.98, focus `focus-ring`; the current page is not clickable.
- **Edges**: previous disabled on page 1, next on the last page.
- **Loading more**: the button shows its spinner at a fixed width; the caption updates when the batch lands.

## Content
- Range with an en dash and « sur »: « 1–20 sur 248 »; thousands with a narrow space (« 1 250 »).
- The load-more caption names the items (« parties », « réservations »).
- End of list is friendly and informal: « Tu as tout vu ».

## Accessibility
- `nav aria-label="Pagination"`; the current page has `aria-current="page"`; pages are labelled « Page 4 ».
- The select has a visible label; changing it returns to page 1.
- The load-more caption is `aria-live="polite"`; the end of list is a `status`. After loading, move focus to the first new item.

## Do / Don't
- Do keep the footer inside the table card, under the last row.
- Don’t show pagination for a single page.
- Don’t use load more under desktop tables, or numbered pages in a mobile feed.

## Props (web preview)
`variant` · `page` · `defaultPage` · `onPageChange` · `total` · `pageSize` · `defaultPageSize` · `pageSizeOptions` · `onPageSizeChange` · `siblingCount` · `loaded` · `loading` · `onLoadMore` · `loadMoreLabel` · `endLabel` · `itemLabel` · `onBackToTop` · `states`. See `index.d.ts`.

## Flutter
`MuPagination.pages(total: 248, page:, pageSize:, onPageChanged:)`, `.compact(...)`, `.more(loaded:, total:, loading:, onLoadMore:)` — a `Row` of `MuIconButton`s and 40 × 40 `TextButton`s with `FontFeature.tabularFigures()`; the select is a `DropdownMenu`; load more is `MuButton.secondary(loading:)` over a 96 × 4 `LinearProgressIndicator(value:)`.
