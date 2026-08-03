---
priority: P1
impact: high
depends_on: [50, 63]
layer: content
status: pending
est: 3d
---

## Problem

The generic adapter currently emits `Content::Paragraph[]` for every
flowable-bearing element type: notes, examples, terms, bibliography
items, figure captions. The semantic distinction is encoded only in
the Paragraph's `style_id:` (`:note`, `:term`, `:bibitem`, etc.).

This has three downstream costs:

1. **Lost structure**: a `<note><p>...</p><p>...</p></note>` becomes
   two unrelated Paragraphs. The flow builder cannot tell they belong
   to the same note (so cannot apply hanging-indent rendering via
   `NoteFlowable`).
2. **No grouping**: the renderer cannot collect footnotes/notes by
   page (TODO 60's blocker — there's no `Content::Footnote` emission
   from the adapter).
3. **Fragile style dispatch**: the flow builder keys off `style_id`
   to decide what to do. Adding a new style requires touching the
   builder, violating OCP.

## Root cause

`Content` knows about generic inline-block containers (Paragraph,
Table, List) but not about the semantic groupings those containers
appear in (Note, Example, TermEntry, BibliographyItem, FigureGroup).
That semantic layer was implicit in the legacy OIML adapter and was
flattened into Paragraphs during the generic-adapter extraction.

## Approach

Add semantic content types that wrap their inner Paragraphs:

```
Content::Note            # <note> — label + body Paragraphs
Content::Example         # <example> — label + body Paragraphs
Content::TermEntry       # <term> — number + preferred + definition + source
Content::FigureGroup     # <figure> — Image + caption Paragraphs
Content::BibliographyItem # <bibitem> — tag + formattedref Paragraphs
```

Each is a frozen value object with `children` (Array of Paragraph or
other Content nodes) plus type-specific fields (`label`, `number`,
`marker`, `caption`).

### Migration plan

1. **Phase 1**: add the new types alongside `Content::Paragraph`. They
   carry the same `style_id` mechanism. Adapter begins emitting the
   new types when the `selectors:` block identifies them.
2. **Phase 2**: `GenericFlowBuilder` recognizes the new types and
   emits `NoteFlowable`, `ImageFlowable + TextFlowable` (figures),
   etc. with proper grouping.
3. **Phase 3**: footnote support. `Content::Footnote` is already
   defined (autoloaded from `content/footnote.rb`). Add adapter
   extraction from `<fmt-footnote-container>` / `<fmt-fn-body>`.
4. **Phase 4**: page-bottom footnote collection in `Engine::Paged`.
   Add a `footnotes` Array to `FlowContext` and a `footnote_zone`
   region in `Output::Page`.

### Selector additions (Phase 1)

```yaml
selectors:
  note_container: note         # already implicit in element_mapping
  note_label: fmt-name         # already present
  example_container: example
  term_container: term
  figure_container: figure
  bibitem_container: bibitem
  footnote_container: fmt-footnote-container
  footnote_body: fmt-fn-body
  footnote_marker: fn
```

### Backward compatibility

The generic adapter continues to emit `Content::Paragraph` for any
flavor that doesn't opt in to the new selector keys. Old flavors'
behavior is unchanged.

## Done-When (Phase 1 — content types)

- [ ] `Content::Note`, `Content::Example`, `Content::TermEntry`,
      `Content::FigureGroup`, `Content::BibliographyItem` classes exist
- [ ] Each is a frozen value object with `==`/`eql?`/`hash`
- [ ] `Content::Document#sections` accepts the new types (or wraps them
      in Sections transparently)
- [ ] Adapter emits the new types when selectors identify them
- [ ] Specs cover each new type's equality + freezing

## Done-When (Phase 2 — flow builder recognition)

- [ ] `GenericFlowBuilder` dispatches on the new types via `is_a?`
- [ ] Notes emit `Flowables::NoteFlowable` (already exists) with
      hanging indent
- [ ] Examples emit a styled block with `example_body` margins
- [ ] Figure groups emit `ImageFlowable` + caption TextFlowable as a
      keep-together unit
- [ ] Bibliography items emit as a single hanging-indent flowable

## Done-When (Phase 3 — footnote extraction)

- [ ] Adapter emits `Content::Footnote` from `<fmt-footnote-container>`
- [ ] Selector keys `footnote_container`, `footnote_body`,
      `footnote_marker` defined
- [ ] Footnotes appear in `Content::Document#footnotes`

## Done-When (Phase 4 — page-bottom rendering)

- [ ] `FlowContext` carries a per-page `footnotes` Array
- [ ] `Engine::Paged` collects footnotes during the layout pass
- [ ] `Output::Page` carries a `footnote_zone` region
- [ ] `Renderer::Pdf` renders footnote lines at the page bottom
- [ ] A real fixture exercises the full path

## Why this unblocks TODO 60

TODO 60 is currently blocked because the architecture has no
mechanism for grouped content types or per-page footnote collection.
This TODO is the architectural work that *enables* TODO 60. Once the
content types exist and the flow builder recognizes them, the
remaining TODO 60 work is a small follow-up.

## Related

- [[50-delete-oiml-ruby-code]] — established generic adapter; this
  TODO extends it with semantic grouping
- [[63-purge-hardcoded-vocabulary-from-generic-core]] — selectors
  mechanism this TODO extends
- [[60-adapter-fidelity-footnotes-notes-examples]] — blocked on this
