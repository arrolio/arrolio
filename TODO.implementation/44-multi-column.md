---
priority: P2
phase: 13
depends_on: [20]
layer: page
est: 3d
status: pending
---

## Problem

Magazines, newspapers, and some technical docs use multi-column body
layout. Body content flows column-by-column; when one column fills,
the next column on the same page begins; only when all columns are
full does the engine advance to the next page.

## Approach

Files:

- `lib/arrolio/layout_spec/columns.rb` — `Columns = Struct.new(:count,
  :gap, :balance, keyword_init: true)`. `count` = number of columns;
  `gap` = gutter width; `balance` = bool (balance last page's columns).

- `lib/arrolio/engine/column_layout.rb` — manages N parallel Frames
  on a page. Body flowables fill column 1 first; when column 1's
  frame is full, advance to column 2; etc.

- `lib/arrolio/engine/column_balancer.rb` — for `balance: true` on
  the last page, distribute content evenly across columns (uses
  Breaker from TODO 14 with the column height as target).

PageTemplate gains a `columns:` attribute that the engine consults
when constructing the body frame.

## Done-When

- [ ] A 2-column layout places body content in left column first,
      then right column on the same page.
- [ ] Content overflows to next page only when both columns are full.
- [ ] Column gap is respected.
- [ ] `balance: true` produces roughly equal column heights on the
      last page.
- [ ] Footnotes (TODO 43) integrate: footnote region spans full
      page width below the columns.
