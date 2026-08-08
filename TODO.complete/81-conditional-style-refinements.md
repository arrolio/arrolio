---
priority: P1
impact: high
depends_on: [70]
layer: adapter
status: in_progress
est: 2d
---

## Problem

The XSL has many conditional style refinements (`refine_*` templates)
that apply margin/space properties only in specific contexts (annex
headings, list-item paragraphs, term definitions). The converter
captures these as unconditional properties in `layout_spec.yml`,
causing spacing to be wrong for most content.

## Bugs found (2026-08-08)

- [x] **heading_1 margin_bottom: 30pt applied unconditionally.** The
      XSL `refine_title-style` only sets `margin-bottom: 30pt` when
      `ancestor::mn:annex`. Our YAML applied it to ALL level-1
      headings, adding 30pt × ~8 headings = 240pt of dead space.
      Fixed: removed from heading_1; needs separate `heading_1_annex`
      style.
- [x] **edition_label always included year.** XSL `get_edition` uses
      `version/revision-date` (child element), which is empty when
      `<version>` has text content. Our profile mapped
      `revision_date: version` (text), always extracting the year.
      Fixed: profile now uses `version/revision-date`, and
      `derive_metadata_fields` falls back to label without year.
- [x] **Doc title block missing.** XSL renders zzSTDTitle1 paragraphs
      as "Part N - title-part" from bibdata. Our adapter extracted the
      paragraph text instead of constructing from metadata. Fixed:
      `extract_title_block` now constructs from `part_number` and
      `title_part` metadata.
- [ ] **Term entry spacing is 3× too tall.** Each term entry component
      (number, preferred, definition) inherits `term` style with
      margin_bottom: 12pt. The XSL applies it once per entry (on the
      outer block). Fix needs either a container flowable or
      per-component style override.
- [ ] **heading_2 space-after: 12pt may be unconditional.** XSL
      `refine_title-style` level 2 adds `space-after: 12pt`
      unconditionally. Verify against reference.
- [ ] **clause-style space-before/space-after.** XSL
      `refine_clause_style` adds space properties conditionally.

## Approach

1. **Audit all `refine_*` templates** in the XSL for conditional
   attributes. Map each condition to a style selector.

2. **Extend the converter** to emit context-specific styles (e.g.,
   `heading_1_annex`, `p_in_list`, `term_definition`) when the
   XSL condition applies.

3. **Or:** model FO space-resolution rules (space-after of previous
   vs space-before of next → take the max, not the sum).

## Done-When

- [ ] All conditional margins match the reference PDF on pages 5-15
- [ ] Term entries use 12pt spacing per entry, not per component
- [ ] Annex headings have 30pt margin; body headings don't
- [ ] Overall parity > 55% on OIML r060/1 fixture

## Measurement

`bundle exec rake parity:check` — current baseline 53.53%.
Last measured: 2026-08-08.
