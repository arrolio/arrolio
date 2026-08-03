---
priority: P0
impact: high
depends_on: [50, 63]
layer: adapter
status: done
est: 1d
---

## Problem

`Content::Document#sections` returned a mixed Array that, despite
earlier fixes, had no constructor-level guarantee of being
`Section[]`. A flavor whose adapter mistakenly pushed a Paragraph
into the array would fail deep in the pipeline with `NoMethodError:
undefined method 'heading?'` rather than at the construction site.

This is a typing failure: `sections` should be `Section[]` by
contract. Validation belongs in the constructor.

## Approach

1. **Constructor validation**: `Content::Document.new` raises
   `ContentError` if any element of `sections` (or `preface`,
   `bibliography`) is not a `Content::Section`.
2. **Adapter guarantee**: `GenericAdapter#extract_sections` returns
   only Section instances — non-section children of `<sections>` are
   skipped (the previous behavior pushed zzSTDTitle paragraphs,
   which is now handled by the cover extraction).
3. **Specs** cover the validation: a real Section passes; a
   Paragraph raises with structured metadata.

## Done-When

- [x] `Content::Document#sections` is guaranteed `Section[]` by
      constructor validation
- [x] `Content::Document#preface` and `#bibliography` are likewise
      validated as `Section[]`
- [x] `GenericAdapter#extract_sections` returns `Section[]` only
- [x] Specs cover: valid sections pass; non-section raises
      ContentError
- [x] Real OIML pipeline renders (25+ pages) without typing failures

## Verification

- `spec/arrolio/content/document_spec.rb` (or similar) covers the
  constructor validation
- `bundle exec rake` is green
- OIML r060/1 fixture renders via the generic pipeline
