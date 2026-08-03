---
priority: P1
phase: 9
depends_on: [31, 18]
layer: list
est: 2d
status: pending
---

## Problem

A list flowable must:
- Render items as a two-column layout (label gutter + body).
- Auto-size the gutter to the widest marker.
- Apply hanging indent so wrapped lines align with the first line.
- Support nested lists (deeper indent).
- Be splittable between items (one item per page minimum).

## Approach

File: `lib/arrolio/flowables/list_flowable.rb`.

```ruby
class Arrolio::Flowables::ListFlowable < Arrolio::Flowable
  def initialize(list, level: 0)
  def height(width, context)
  def render(canvas, x, y, width, context)
  def splittable?; true; end
  def do_split(width, remaining_height, context)
end
```

Layout algorithm:
1. For each item, compute the marker text (from scheme or explicit).
2. Label column width = max marker width + small gap (e.g. 6pt).
3. Body column width = `width - label_column - indent`.
4. Render item:
   - Place marker in label column (right-aligned to body column).
   - Place content flowable in body column.
   - Hanging indent: if content wraps, subsequent paragraphs in the
     item align with the body column's left edge.
5. Nested lists: render as a sub-ListFlowable indented further.

Splitting: between items only. If first item doesn't fit on the
current frame, advance page.

## Done-When

- [ ] A 3-item bullet list renders with "•" markers in the left gutter.
- [ ] Decimal-numbered list auto-sizes gutter to "12." or wider.
- [ ] Wrapped content lines align with the first line (hanging indent).
- [ ] Nested list indents further and uses different marker scheme.
- [ ] A list longer than the page splits between items.
- [ ] Specs cover all of the above.
