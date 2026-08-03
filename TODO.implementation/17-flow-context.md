---
priority: P0
phase: 5
depends_on: [16]
layer: flowable
est: 1d
status: in_progress
---

## Problem

Every `render` call gets a `FlowContext`. It carries page-level state
flowables need: current page number, total page count (for "Page X of
Y"), resolved citation targets, bookmark targets, the float registry,
and a reference to the document (for emitting indirect objects like
hyperlink annotations).

## Approach

File: `lib/arrolio/flow_context.rb`.

```ruby
class Arrolio::FlowContext
  attr_reader :document, :citations, :bookmarks, :float_registry
  attr_accessor :page_number, :page_count

  def initialize(document: nil, page_number: 1, page_count: nil)
    ...
  end

  def citation_for(ref_id)        # filled in pass 1, read in pass 2
  def record_citation(ref_id, page_number)
  def record_bookmark(ref_id, page_number, y)
  def total_pages                 # nil until pass 1 completes
end
```

The context is passed by reference, so mutating it during layout is
intentional. Pass 2 (after the document is fully laid out) reads the
recorded citations/bookmarks to render static content with resolved
field values.

## Done-When

- [ ] `FlowContext.new(page_number: 5)` exposes `page_number == 5`.
- [ ] `record_citation("ch1", 7)` then `citation_for("ch1") == 7`.
- [ ] `total_pages` returns nil until `page_count = N` is set.
- [ ] Document reference is propagated to children that need to emit
      indirect objects (TODO 37 hyperlinks).
- [ ] Specs cover recording, lookup, two-pass resolution.
