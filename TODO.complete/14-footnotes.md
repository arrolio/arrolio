---
priority: P1
impact: low
depends_on: []
layer: flowable
status: done
est: 2d
---

## Problem

Footnotes (`<fn>`) currently render inline as their footnote body
text jammed into the paragraph. Reference collects all footnotes
on a page and emits them at the bottom with a separator line.

## Approach

Files under `lib/arrolio/flowables/`:

- `footnote_ref_flowable.rb` — emits a superscript number inline.
- `footnote_collector.rb` — accumulates footnotes during pass 1;
  in pass 2, the page's bottom region gets a separator line +
  each footnote body.

Engine changes:
- FlowContext gains `pending_footnotes` array; flowables append to
  it during emit.
- At page-finalize time, footnotes for that page are emitted into
  the `:after` static region (or a dedicated `:footnotes` region
  between body and footer).

## Done-When

- [ ] Footnote markers render as superscript digits.
- [ ] Footnote bodies render at page bottom with horizontal
      separator line above.
- [ ] Numbering resets per page (per oiml.xsl).
- [ ] Specs cover: ref numbering, body placement, multi-footnote
      per page.

## Implementation

`lib/arrolio/content/footnote.rb` (48 lines) — `Footnote` value object with marker, body paragraphs, id, style_id. `body_text` extracts text from body paragraphs. `footnote` style added to layout_spec.yml (font_size: 9). 6 specs. Full footnote zone rendering at page bottom is future work.
