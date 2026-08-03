---
priority: P0
phase: 8
depends_on: [29, 16]
layer: table
est: 2d
status: in_progress
---

## Problem

Tables longer than a single page must split between rows (never
mid-cell). Header rows repeat on every fragment. The TableFlowable
wraps a Table so it integrates with the page-flow engine like any
other Flowable.

## Approach

File: `lib/arrolio/flowables/table_flowable.rb`.

```ruby
class Arrolio::Flowables::TableFlowable < Arrolio::Flowable
  def initialize(table, algorithm: :auto)
  def height(width, context)
  def render(canvas, x, y, width, context)
  def splittable?; true; end
  def do_split(width, remaining_height, context) -> [head, tail]
end
```

`do_split` algorithm:
1. Layout the table at `width` to get the resolved grid.
2. Walk rows; cumulate heights.
3. Header rows always go in the head.
4. Body rows: include in head if `cum_height + row_h <= remaining_height`;
   otherwise include in tail.
5. If no body rows fit (`head_rows == header_rows`), return
   `[nil, self]` so the engine advances to a new page.
6. Build two tables: `head_table` (header + first N body rows),
   `tail_table` (header + remaining body rows — header repeats!).
7. Return `[TableFlowable.new(head_table), TableFlowable.new(tail_table)]`.

`render` uses TableRenderer.

## Done-When

- [ ] A short table (fits on one page) renders without splitting.
- [ ] A 30-row table on a single-page frame splits into multiple
      pages, header row repeated on each.
- [ ] Split is between rows, never mid-cell.
- [ ] `do_split` with insufficient remaining returns `[nil, self]`.
- [ ] Engine then advances and renders the table on the next page.
- [ ] Colspan/rowspan preserved across splits.
