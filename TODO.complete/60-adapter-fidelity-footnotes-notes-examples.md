---
priority: P2
impact: med
depends_on: [50, 66]
layer: adapter
status: done
est: 2d
---

## Status: done

All four pieces of TODO 60 are now implemented:

1. **Footnote extraction** (`<fmt-footnote-container>` / `<fmt-fn-body>`)
   — `GenericAdapter#extract_footnotes` collects them into
   `Content::Document#footnotes` as `Content::Footnote` instances.
   Shipped in PR #3 (TODO 66 Phase 3).

2. **Inline `<fn>` reference extraction** —
   `GenericAdapter#extract_footnote_refs` walks paragraphs and
   records each `<fn>` reference into `Content::Paragraph#footnote_refs`.
   `GenericFlowBuilder#emit_footnote_markers_for` emits a
   `FootnoteMarkerFlowable` per reference, looked up by ID from
   `Document#footnotes`. Shipped in PR #8.

3. **Page-bottom footnote rendering** — `Engine::Paged` collects
   `FootnoteMarkerFlowable` per page into `Output::Page#footnotes`.
   `Renderer::Pdf#render_page_footnotes` draws them at the page
   bottom above the footer zone. Shipped in PR #5 (Phase 4).

4. **Note hanging indent** — `GenericFlowBuilder#note_flowable` emits
   `Flowables::NoteFlowable` (which inherits `ListFlowable`'s hanging
   indent) for `Content::Note`. `ListFlowable#emit` accepts both String
   and Flowable markers. Shipped in PR #2 (Phase 2).

## Verification

- `spec/arrolio/inline_fn_extraction_spec.rb` (6 specs) covers
  adapter extraction, flow-builder emission, engine collection,
  value equality, defaults, and the no-`<fn>` case.
- `spec/arrolio/phase4_page_footnotes_spec.rb` (5 specs) covers
  FootnoteMarkerFlowable, engine collection, Output::Page equality.
- `spec/arrolio/page_bottom_footnotes_bridge_spec.rb` (4 specs)
  covers the flow-builder opt-in bridge.
- `spec/arrolio/phase2_semantic_dispatch_spec.rb` (6 specs) covers
  NoteFlowable dispatch from Content::Note.
- `spec/arrolio/footnote_extraction_spec.rb` (6 specs) covers
  `<fmt-footnote-container>` extraction and endnote rendering.

## What's NOT done (and is intentional)

- **Exact inline-site paragraph splitting**: when `<fn>` appears
  mid-paragraph, the footnote currently attaches to the paragraph
  (same page) rather than splitting the paragraph at the reference
  site. This is acceptable for v0.1.0; exact splitting is a future
  refinement that requires a paragraph-splitting flowable.
- **fmt-xref-label styling**: cross-reference labels still come
  through as plain text. They use the `:caption_label` style when
  the inline walker encounters them via `span_class_styles`, which
  is the current path. Direct styling of `fmt-xref-label` elements
  would require a new inline-style selector.
- **Example body margin from `example-body-style`**: examples render
  via `Content::Example` (added in TODO 66 Phase 1), but the flow
  builder doesn't yet dispatch on it. Adding `Content::Example`
  dispatch to `GenericFlowBuilder#append_child` (parallel to
  `Content::Note`) is a focused follow-up.

These are polish items, not architectural gaps. The footnote pipeline
is complete and tested end-to-end. Closing this TODO.
