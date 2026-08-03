---
priority: P0
phase: 3
depends_on: [04, 09]
layer: text
est: 1d
status: in_progress
---

## Problem

Line breaking iterates over a list of `InlineRun`s. Each run is a
contiguous span of text sharing one `Style`. The line breaker must
find break opportunities across run boundaries (the wrap algorithm
cannot force a line break just because the style changed).

## Approach

Files:

- `lib/arrolio/inline_run.rb` — frozen value object:
  `text`, `style`. Methods: `empty?`, `length`, `width(measurer)`,
  `==`, `eql?`, `hash`.
- `lib/arrolio/text_layout/break_opportunity.rb` — finds break
  points in a run list. Yields `BreakOpportunity` value objects:
  - `run_index` — index into the run list.
  - `char_offset` — position within that run.
  - `width_before` — cumulative width up to (and including) the break.
  - `type` — `:start`, `:soft`, `:forced`, `:end`.

Opportunities are created at:
- Paragraph start (always, `:start`).
- After each space (`:soft`).
- After hyphen / em-dash / soft hyphen (`:soft`).
- At zero-width space (U+200B) (`:soft`, no width consumed).
- At newline (`:forced`).
- At end of paragraph (`:end`).

## Done-When

- [ ] `InlineRun.new("Hello", style:).width(measurer)` returns a Float.
- [ ] `BreakOpportunity.each_in(runs, measurer:, font_size:)` yields
      every opportunity in order with correct cumulative widths.
- [ ] A forced newline produces a `:forced` opportunity.
- [ ] A paragraph with no spaces yields only `:start` and `:end`.
- [ ] Specs cover: ASCII, multi-run with style change at space,
      explicit newline, soft hyphen.
