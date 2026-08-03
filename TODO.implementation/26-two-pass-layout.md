---
priority: P0
phase: 7
depends_on: [25]
layer: template
est: 2d
status: pending
---

## Problem

Cross-references (`fo:page-number-citation`, "Page X of Y") need to
know page numbers that aren't decided until layout completes. The
engine runs two passes:

1. **Pass 1**: lay out everything with placeholder field values.
   Record which page each citation target lands on.
2. **Pass 2**: re-render the static-content regions (headers/footers)
   with resolved citation values.

Body content is NOT re-rendered in pass 2 — its layout is stable.
Only the static regions need field resolution.

## Approach

Modify `Arrolio::Engine::Paged` (TODO 20):

```ruby
def layout
  pass1_result = layout_pass1
  context.page_count = pass1_result.pages.length
  pass2(pass1_result.pages)
end

def pass2(pages)
  pages.each_with_index do |page, i|
    context.page_number = i + 1
    page.render_static_content(context)
  end
  pages
end
```

The `Output::Page#render_static_content(context)` method:
- For each `StaticContent` entry, resolve its flowables' field runs.
- Rebuild the placed boxes for the static region only.
- Replace the region's `placed_boxes` with the new ones.

Field runs (TODO 39) implement `resolve(context)` returning a String.
The static-content flow is built once during pass 1, but its field
runs are evaluated against `context` each time the region is
re-rendered.

Citation recording: when the engine places a flowable that has a
`citation_target_id`, it records
`context.record_citation(target_id, current_page_number)`.

## Done-When

- [ ] A document with "Page X of Y" in the footer renders correctly
      (X = current page, Y = total).
- [ ] A `page-number-citation` to a section heading on page 5
      resolves to "5" in static content.
- [ ] Body layout is identical between pass 1 and pass 2 (no relayout).
- [ ] Pass 2 only re-evaluates field runs; no other work.
- [ ] 100-page document: pass 2 completes in < 1 second.
