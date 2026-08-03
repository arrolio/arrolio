---
priority: P2
phase: 13
depends_on: [26, 39]
layer: page
est: 2d
status: pending
---

## Problem

Two related features:

1. **Page numbering schemes**: front matter uses roman numerals (i,
   ii, iii); body uses arabic (1, 2, 3) restarting at 1. Currently
   Arrolio has only one global counter.
2. **Section title in running header**: every body page's header
   shows the current top-level section's title. Requires tracking
   which section is "current" as content flows.

## Approach

Files:

- `lib/arrolio/page_numbering_scheme.rb` — value object: `format`
  (`:arabic`, `:roman_lower`, `:roman_upper`, `:alpha_lower`,
  `:alpha_upper`), `start` (Integer, default 1), `prefix`, `suffix`.
  Method `render(n)` → String.

- Extend `PageSequenceMaster` (TODO 25) with `:page_numbering`
  attribute. Each sequence can have its own scheme; restarting at
  sequence start.

- Extend `FlowContext` with `current_section` attribute. When the
  engine places a Section heading flowable, it updates
  `context.current_section = section`. Static content with
  `{ text: context.current_section.title }` then resolves correctly.

- Add `SectionTitleField < FieldRun` that returns
  `context.current_section.title`.

## Done-When

- [ ] Front matter pages show roman numerals (i, ii, iii).
- [ ] Body pages show arabic numerals starting from 1.
- [ ] Section title in header changes as content crosses section
      boundaries.
- [ ] Multi-level section: header shows "Chapter 3" while body is in
      Chapter 3, regardless of subsection depth.
- [ ] Spec coverage for each scheme + section tracking.
