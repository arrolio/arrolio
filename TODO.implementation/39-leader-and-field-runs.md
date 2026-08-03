---
priority: P1
phase: 12
depends_on: [13, 17]
layer: xref
est: 2d
status: in_progress
---

## Problem

Two cross-reference primitives:

1. **Leader**: stretchy dot/rule that fills the space between two
   runs on a line (for TOC entries: "Chapter 1 ........... 12").
2. **FieldRun**: page-number fields resolved at render time via
   FlowContext (`page_number`, `page_number_citation`,
   `page_count`).

Both must integrate with TextLayout: a Leader takes the residual
space after the line's other runs; a FieldRun produces text after
context lookup.

## Approach

Files:

- `lib/arrolio/leader.rb` — `Leader < InlineRun` with
  `leader_pattern` (`:dots`, `:rule`, `:space`), `leader_length_min`,
  `leader_length_max`. Method `fill_text(available_width, measurer)`
  returns the dot string that fits.

- `lib/arrolio/field_run.rb` — base `FieldRun < InlineRun` with
  `resolve(context) -> String`.

- Under `lib/arrolio/field_run/`:
  - `page_number.rb` — `PageNumberField` returns
    `context.page_number.to_s`.
  - `page_number_citation.rb` — `PageNumberCitationField` returns
    `context.citation_for(ref_id).to_s` (empty if unresolved).
  - `page_count.rb` — `PageCountField` returns
    `context.total_pages.to_s` (empty in pass 1).

TextLayout integration:
- Leaders are width=0 during line breaking (they take residual space).
- After all other runs on a line are placed, compute the slack;
  Leader fills it with dots.
- FieldRuns are width=estimated ("000") in pass 1; in pass 2 they
  have resolved text and re-flow if necessary (rare).

## Done-When

- [ ] TOC line `"Chapter 1" + leader + "12"` renders as
      `"Chapter 1 ........... 12"`.
- [ ] `leader_pattern: :rule` renders a horizontal line.
- [ ] `PageNumberField` in footer renders "3" on page 3.
- [ ] `PageCountField` renders "7" on every page of a 7-page doc.
- [ ] `PageNumberCitationField` referencing a section on page 5
      renders "5".
- [ ] Spec coverage for each.
