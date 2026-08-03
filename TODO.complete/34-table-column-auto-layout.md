---
priority: P1
impact: med
depends_on: [04]
layer: flowable
status: done
est: 1d
---

## Problem

Table columns are equal-width (`width / column_count`). Reference
uses content-based auto-layout: "Classification symbol" column is
narrow (~30mm), "Description" column is wide (~130mm). Equal-width
wastes space and causes awkward text wrapping.

## Approach

Add `Arroolio::Table::AutoLayout`:

1. For each column, measure every cell's natural width (longest
   unbreakable word + reasonable padding).
2. Compute the minimum column width = max(natural widths in column).
3. If total minimum > available width: distribute proportionally
   to natural width.
4. If total minimum < available width: give each column its natural
   width + distribute remaining space to the widest-natural column
   (or evenly).

Wire into `TableFlowable#column_widths_for`:
```ruby
def column_widths_for(width)
  return @cached_widths if @cached_widths
  @cached_widths = Table::AutoLayout.new(@table, available_width: width).compute
end
```

Also honour `<col width="...">` and `<colgroup>` from XML if present
(fixed layout takes precedence over auto when explicit widths exist).

## Done-When

- [ ] "Classification symbol" column auto-sizes to ~30mm.
- [ ] "Description" column expands to fill remaining width.
- [ ] No text wrapping in header row when natural widths fit.
- [ ] Specs cover: auto layout, fixed layout, mixed, overflow.

## Implementation

`lib/arrolio/table/auto_layout.rb` (91 lines) - AutoLayout class. Measures each cell longest token + padding, takes max per column. Distributes available_width proportionally to natural widths. Scales down when overflow (respects MIN_COLUMN_WIDTH). 5 specs in spec/arrolio/table/auto_layout_spec.rb.
