---
priority: P0
impact: med
depends_on: [05]
layer: flowable
status: done
est: 1d
---

## Problem

Notes ("NOTE:") and examples ("EXAMPLE:") in OIML currently render
as inline paragraphs with the label prefixed to the body. Reference
uses fo:list-block with italic label in the marker column and body
indented.

## Approach

Reuse `ListFlowable` infrastructure (TODO 05) with:

- Marker = label ("NOTE 1:" or "EXAMPLE:") in italic
- Body = note content paragraphs

Different style presets via Style::Registry:
- `note_label` — italic, 11pt
- `note_body` — regular, 11pt, margin-bottom 8pt
- `example_label` — italic, 11pt
- `example_body` — same as note_body but margin-left 12.5mm

## Done-When

- [ ] "NOTE 1 — The error envelope..." renders with italic "NOTE 1 —"
      prefix and indented body matching reference.
- [ ] Same for EXAMPLE.
- [ ] termnote variant (smaller, inside <term>).
- [ ] Specs cover: label extraction from <fmt-name>, body inline
      runs, indentation.

## Implementation

`lib/arrolio/flowables/note_flowable.rb` + adapter `convert_note`/`convert_example` — label + body paragraphs.
