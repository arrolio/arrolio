---
priority: P2
impact: med
depends_on: [50]
layer: adapter
status: blocked
est: 2d
---

## Status: blocked

Requires:
1. A fixture document that uses `<fmt-footnote-container>` /
   `<fmt-fn-body>` with realistic content (the OIML r060/1 fixture
   has none).
2. A reference PDF that renders these elements so we can measure
   fidelity.
3. Page-bottom footnote-line rendering support in the engine (Engine
   currently has no mechanism for per-page footnotes that collect
   from the body and render at the bottom).

The foundation is in place — `Content::Footnote` is already defined
(autoloaded from `lib/arrolio/content/footnote.rb`), and the skip list
in `adapter_rules.yml` can drop `fmt-footnote-container`/`fmt-fn-body`
once the flow builder knows how to render them. But without fixtures
and an engine-side page-bottom collection mechanism, the implementation
cannot be validated.

## Problem (when unblocked)

The generic pipeline currently loses some information that the legacy
OIML adapter preserved:

- `fmt-footnote-container` / `fmt-fn-body` are in the `skip_elements`
  list, so footnotes are dropped from the body and never rendered.
- `fmt-xref-label` is skipped, so cross-references to notes/examples
  lose their visual prefix.
- The `example-body-style` margin-left and `note` list-block indent
  from the XSL are not translated into Arroolio layout (notes/examples
  render as plain paragraphs without the XSL's hanging indent).

## Approach (when unblocked)

1. **Footnote flowable** (`Arroolio::Flowables::FootnoteFlowable`):
   carries a marker + body, renders as superscript marker in the body
   text and a footnote line at the page bottom.
2. **Note hanging indent**: the XSL renders notes as `fo:list-block`
   with `provisional-distance-between-starts: 14.5mm`. The
   `GenericFlowBuilder` should emit a `NoteFlowable` (already exists)
   with the configured indent.
3. **Example body margin**: `example-body-style` margin-left 12.5mm
   should come from the layout_spec's `example_body` style.
4. **Cross-reference label**: `fmt-xref-label` should become a styled
   inline run (caption_label).

## Done-When (when unblocked)

- [ ] Footnotes render with superscript markers + page-bottom lines
- [ ] Notes render with a hanging indent matching the XSL
- [ ] Examples render with the inner-paragraph left margin
- [ ] Cross-reference labels appear with the correct style
- [ ] Diff against the reference PDF improves for these features
