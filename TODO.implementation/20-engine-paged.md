---
priority: P0
phase: 5
depends_on: [17, 18, 19]
layer: flowable
est: 3d
status: in_progress
---

## Problem

The driver that walks a Flowable list, places each into a Frame,
advances pages when the frame is full, honours keep-together and
page-break directives, and runs two passes for citation resolution.
This is the heart of the engine.

## Approach

File: `lib/arrolio/engine/paged.rb`.

```ruby
class Arrolio::Engine::Paged
  attr_reader :layout_spec, :flowables, :context, :pages

  def initialize(layout_spec:, flowables:, context: nil)
  def layout -> [Arrolio::Output::Page]
end
```

Algorithm:
1. Initialise `pending = flowables.dup`, `current_page = new_page`,
   `current_frame = current_page.body_frame`.
2. Loop:
   - Shift next flowable.
   - `PageBreak` → new page; continue.
   - `page_break_before?` and not first flowable → new page.
   - `keep_together?` and `height > remaining_height` and `height <=
     frame.height` → new page first.
   - If frame full → new page.
   - `render_on_page(flowable, current_page, current_frame)` →
     `[consumed, remainder]`.
   - `frame.consume!(consumed)`.
   - If remainder and consumed == 0 and frame not full → new page;
     unshift remainder.
   - Else unshift remainder.
3. After all flowables placed: `context.page_count = pages.length`.
4. Pass 2: for each page, render its static-content regions
   (running headers/footers) with resolved citation values.

Each page is created from the layout_spec's PageSequenceMaster
selection (TODO 24, 25). For now (Phase 5), use a single body
template.

## Done-When

- [ ] A single-paragraph document produces 1 page.
- [ ] 50 long paragraphs across multiple pages.
- [ ] `PageBreak` forces a new page.
- [ ] `keep_together: true` flowable that doesn't fit moves to next
      page whole.
- [ ] 100-paragraph doc lays out in < 5 seconds.
- [ ] No infinite loops on over-large content (TODO 19's split
      contract prevents this).
