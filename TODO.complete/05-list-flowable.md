---
priority: P0
impact: med
depends_on: []
layer: flowable
status: done
est: 2d
---

## Problem

Lists in the OIML doc render as flat text with "■ " prefix on the
same line as the body. Reference uses fo:list-block with hanging
indent: marker column at fixed width, body column indented and
wraps to body width without going under the marker.

## Approach

File: `lib/arrolio/flowables/list_flowable.rb`

```ruby
class ListFlowable < Flowable
  def initialize(items, kind: :bullet, marker_width: 18, ...)
  def height(width, context)  # sum of item heights
  def emit(x, y, width, context)  # emit each item with hanging indent
  def splittable?; true; end
  def do_split(width, remaining_height, context)
end
```

Each item is `[marker_text, body_flowables]`. The body flowables
re-flow at `width - marker_width` and start at `x + marker_width`.
Wrapping lines align with the body column (not under the marker).

Markers:
- `:bullet` → "■" (square, matching oiml.xsl) or "●" inside `<term>`
- `:ordered` → "1." "2." etc.
- Custom marker from `<fmt-name>` (e.g. "—")

## Done-When

- [ ] Two-line body wraps under the body column, not the marker.
- [ ] Ordered list markers auto-increment per item.
- [ ] Nested lists indent further (4mm per level per oiml.xsl).
- [ ] Specs cover: bullet, ordered, nested, multi-paragraph item,
      list splitting across pages.

## Implementation

`lib/arrolio/flowables/list_flowable.rb` — bullet/ordered markers, list item body, proper indentation.
