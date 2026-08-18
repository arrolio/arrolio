---
priority: P2
impact: med
depends_on: [50, 66]
layer: adapter
status: done
est: 2d
---

## Status: done (per-page footnote model completed 2026-08-18, PR #74)

The shipped page-bottom rendering collects footnotes onto the page
where their markers are EMITTED — which, for the OIML flavor, is the
last body page (markers are appended after all sections). The
reference (FOP) implements the real footnote model: the body of a
footnote referenced on page N renders at the BOTTOM OF PAGE N, the
body text shrinks above the footnote area, and a separator rule
divides them. Visible in the 5.3.2 region: the reference pins the
"1) Associated with apportionment..." body to page 19's bottom
(freeing 115pt of body flow that our output fills with the inline
text), which is a −212pt pagination span (TODO 96).

### Remaining work

- ~~Footnote bodies inline in paragraphs~~ — fixed 2026-08-18:
  `convert_paragraph` excludes the `<fn>` subtree from runs;
  `extract_footnotes` registers raw `<fn>` elements recursively
  (REXML `each_element` only visits direct children, so deeply
  nested footnotes never registered); OIML enables
  `page_bottom_footnotes`, so the 5.3.2 footnote body now renders
  at the bottom of page 19 like the reference.
- ~~Inline superscript marker~~ — shipped PR #74: the run walker
  emits the marker run in document order at the <fn> site.
- ~~Footnote-zone reservation~~ — shipped PR #74:
  FootnoteMarkerFlowable#height equals the laid-out body block
  (shared `body_flowable` policy) and is consumed from the body
  flow; the renderer draws through the same policy.
- Known approximation: when a footnote body does not fit the page
  remainder, FOP moves the REFERENCE to the next page; we reserve
  and possibly overflow. Acceptable until a two-pass engine.

### Shipped pieces (previous sessions):

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
