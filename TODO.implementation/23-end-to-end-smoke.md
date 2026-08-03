---
priority: P0
phase: 6
depends_on: [22]
layer: output
est: 1d
status: in_progress
---

## Problem

Need a single test that proves the full pipeline works end-to-end:
Content → LayoutSpec → Engine → Output → Renderer → PDF bytes that
read back correctly. This is the MVP milestone.

## Approach

File: `spec/arrolio/end_to_end_smoke_spec.rb`.

Build the simplest non-trivial document:
- A4 page, 25mm margins.
- One section with a heading and two paragraphs of body text.
- Use the standard 14 Type1 fonts (Helvetica + Times).

Run it through the pipeline:
```ruby
content = Arrolio::Content::Document.build { ... }
layout  = Arrolio::LayoutSpec.build { ... }
pages   = Arrolio::Engine::Paged.new(layout_spec: layout,
                                       flowables: FlowBuilder.(content, layout)).layout
out     = StringIO.new
Arrolio::Renderer::Pdf.new.render(pages, io: out)

# Assertions
reopened = Pdfrb::Document.new(io: StringIO.new(out.string))
expect(reopened.pages.count).to eq(1)
extracted = Pdfrb::Task::ExtractText.(reopened).first
expect(extracted).to include("Hello, World!")
```

Also a multi-page variant: 50 paragraphs that overflow to 2+ pages.

This spec becomes the regression canary — any breaking change in
any layer fails it.

## Done-When

- [ ] Single-page smoke spec passes.
- [ ] Multi-page overflow spec passes (≥ 2 pages, text extractable).
- [ ] Round-trip: write → read → re-write → re-read produces same
      text extraction.
- [ ] The spec runs in < 2 seconds.
- [ ] Spec is marked `:e2e` so it can be excluded from fast unit runs.
