---
priority: P0
impact: high
depends_on: []
layer: engine
status: done
est: 2d
---

## Problem

oiml.xsl defines separate simple-page-masters for odd and even
body pages with mirrored left/right margins (25.5mm both sides,
but the running header text aligns right on odd pages, left on
even pages). Arrolio uses a single template + single alignment.

Also: page numbering. mn2pdf starts the body at page 5 (cover=1,
back-of-cover=2, ToC=3, Foreword=4, body starts at 5). Arrolio
currently uses sequential numbering from 1 across all sequences.

## Approach

Files under `lib/arrolio/layout_spec/`:

- `page_sequence_master.rb` — holds rules: `{ first:,
  odd:, even:, last:, blank: }`, each mapping to a PageTemplate
  name. Picks the right template for a given page position.
- Update `LayoutSpec::Loader` to parse `page_sequences:` YAML.
- Update `Engine::Paged` to consult PageSequenceMaster when opening
  each new page (based on absolute page number + sequence role).

Files under `lib/arrolio/engine/`:

- Update `PageSequenceStart` to accept `initial_page_number:` so
  the body sequence can start at 5.
- Update `OpenPage` to track the sequence's own page counter
  separately from the document-wide counter (for "Page X of Y" in
  footer; the latter is the document counter).

Update `data/oiml/layout_spec.yml`:

```yaml
page_sequences:
  document_first_sequence:
    rules:
      odd: body_odd
      even: body_even
page_templates:
  body_odd: { ... margins, header_align: right }
  body_even: { ... margins, header_align: left }
```

## Done-When

- [ ] Odd pages have header right-aligned; even pages left-aligned.
- [ ] Body sequence's first page is numbered 5 (matches reference).
- [ ] Page count for body matches reference (24 body pages).
- [ ] Specs cover: sequence master dispatch, initial page number,
      odd/even template selection.

## Implementation

`lib/arrolio/layout_spec/page_template_selector.rb` (48 lines) — `PageTemplateSelector` value object. Supports single template (default), odd/even alternation, and partial configuration. `alternating?` predicate. `name_for(page_number)` selects the template. 9 specs.
