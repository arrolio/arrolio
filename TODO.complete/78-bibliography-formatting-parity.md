---
priority: P2
impact: low
depends_on: [70]
layer: adapter
status: in_progress
est: 1d
---

## Problem

Bibliography page (28 in OIML r060/1) renders content but with
wrong formatting. The reference uses numbered references `[1]`,
`[2]` followed by the citation text on the same line. We were
wrapping each entry in a `NoteFlowable` that clipped the tag to
`marker_width=36pt`, producing broken wraps like
`[1] OIML V\nInternational\n1:2013`.

A separate bug in `extract_bibliography` compounded this: the
`each_child` loop pushed `convert_bibitem` results (Arrays) into
`items` without flattening, so the `Section#children` ended up as
Arrays-of-BibliographyItem instead of BibliographyItem. The flow
builder's `case child when Content::BibliographyItem` never
matched, and the items silently disappeared.

## Status (2026-08-05)

- [x] **`extract_bibliography` now flattens** — uses `items.concat`
      instead of `items <<`, since `convert_bibitem` returns an
      Array (empty or single-element).
- [x] **`bibliography_item_flowable` emits a single TextFlowable**
      combining the tag and formattedref into one paragraph. No
      more column clipping.

## Verification

Page 28 now renders the bibliography correctly:

```
[1] OIML V 1:2013, International Vocabulary of Terms in Legal Metrology (VIML)
[2] OIML V 2-200:2012, International Vocabulary of Metrology — Basic
and General Concepts and Associated Terms (VIM)
[3] OIML D 9:2004, Principles of metrological supervision
...
```

## Still pending

- **Hanging indent**: numbered references should have a hanging
  indent so the second line aligns with the start of the citation
  text, not the number. Currently the entry is a single
  left-aligned paragraph.
- **`space-after: 4pt` per entry**: reference has a small gap
  between entries. Our paragraphs have `margin_bottom: 0` from
  the body style inheritance.
- **Bibliography section heading style**: the heading renders but
  may not use the exact level-1 style the reference uses.

## Done-When

- [x] Bibliography entries render as single paragraphs (not column-clipped)
- [x] All 12 entries appear in the output (previously 0 due to concat bug)
- [ ] Hanging indent so wrap lines align with text start
- [ ] 4pt gap between entries
- [ ] Page 28 similarity > 85% (currently ~50% due to other body drift)

## Measurement

`bundle exec rake parity:check` — page 28 bibliography page
now renders content; previously empty.
