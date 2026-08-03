---
priority: P1
phase: 12
depends_on: [39, 41]
layer: xref
est: 2d
status: pending
---

## Problem

Authoring a TOC by hand is tedious. The TOC builder walks the
Content tree's sections, produces a flowable list of TOC entries —
each is `"section_title" + Leader + "page_number_citation"` — and
inserts it where the author marked a TOC placeholder.

## Approach

File: `lib/arrolio/toc_builder.rb`.

```ruby
class Arrolio::TocBuilder
  def initialize(content_document, levels: 1..3, style: :toc_entry)
  def build -> [TextFlowable, TextFlowable, ...]
end
```

Algorithm:
1. Walk `content_document.sections`; collect headings up to `levels`.
2. For each heading, build a `TextFlowable` containing:
   - `[InlineRun.new(section.title, style: indent_style(level)),
      Leader.new,
      PageNumberCitationField.new(ref_id: section.id)]`
3. Indent per level (level 1 = no indent, level 2 = 12pt, level 3 = 24pt).

Engine integration: the author places a `TocPlaceholder` flowable in
the content stream. The engine replaces it with `TocBuilder.build`'s
output at the start of pass 1.

Two-pass effect: TOC entries need their cited page numbers, which
aren't known until pass 1 completes. The TOC must be laid out in
pass 1 with estimated widths; in pass 2 the field runs resolve and
the TOC text is final.

## Done-When

- [ ] A 3-section document produces a TOC with 3 entries.
- [ ] Each entry has the section title left, dot leader filling
      middle, page number right.
- [ ] Multi-page TOC flows correctly across pages.
- [ ] Nested sections (level 2, 3) indent visibly.
- [ ] Page numbers in TOC match actual page numbers from pass 1.
