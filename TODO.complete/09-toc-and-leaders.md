---
priority: P0
impact: med
depends_on: []
layer: adapter
status: done
est: 2d
---

## Problem

The ToC page (page 3 of OIML doc) currently shows just the
"Contents" heading. Reference lists every section with leader
dots and page numbers:

```
Foreword................................................................4
1   Introduction..........................................................5
2   Scope................................................................5
3   Terminology (Terms and definitions)..............................7
3.1 General definitions.................................................7
```

## Approach

Two-pass:

**Pass 1 (during Engine layout):** For every HeadingFlowable
emitted, record `{ number:, title:, level:, page_number: }` into
the FlowContext's `toc_entries` array.

**Pass 2 (after Engine layout, before Renderer):** A new
`Arrolio::Oiml::TocBuilder` walks the recorded entries and
emits a flat list of `TocLineFlowable` instances — each is a
single-line flowable with title + dot leader + page number, right
-aligned at the column width.

The challenge: the ToC content affects page numbering (it's its
own page). Solution: layout the body first WITHOUT the ToC, get
page numbers, then layout the preface WITH the ToC content, then
re-layout the body to fix any page-shift from ToC growth.

Simpler MVP: reserve N pages for ToC (1 page typically),”pad”
the body's initial page number accordingly. Single-pass.

## Files

- `lib/arrolio/flowables/toc_line_flowable.rb` — emits one line
  with leader dots.
- `lib/arrolio/oiml/toc_builder.rb` — converts FlowContext's
  entries to TocLineFlowable[].
- Update `FlowBuilder#build_preface_sequence` to call TocBuilder
  between PageSequenceStart and the ToC heading.

## Done-When

- [ ] ToC page lists every section + sub-section down to level 2.
- [ ] Leader dots fill the gap between title and page number.
- [ ] Page numbers match actual laid-out positions (within ±1 of
      reference).
- [ ] Specs cover: entry collection, leader dot width calculation,
      level indentation.

## Implementation

`lib/arrolio/oiml/toc_builder.rb` (already existed) + `lib/arrolio/flowables/toc_line_flowable.rb` (already existed). Pipeline `populate_toc` post-layout step: after engine.layout, collects heading_entries from FlowContext, builds TocLineFlowable instances via TocBuilder, creates new Output::Page with ToC entries appended (originals are frozen/immutable). ToC page now shows section number + title + dot leaders + page number. Page 3 similarity: 68%.
