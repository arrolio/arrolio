---
priority: P2
phase: 4
depends_on: [11, 12, 14]
layer: knuth
est: 2d
status: pending
---

## Problem

Greedy and KnuthPlass line breakers were built independently and
duplicate the line-assembly logic. Once the universal `Breaker`
exists (TODO 14), refactor both algorithms to produce Knuth
element sequences from InlineRuns, then break them with the universal
Breaker. Same output, less code, easier to extend.

## Approach

Files to modify:

- `lib/arrolio/text_layout/knuth_sequence_builder.rb` — new class.
  Takes `InlineRun[]` + `GlyphMeasurer`, produces a `Knuth::Element[]`
  sequence:
  - Each character → `Box(width: char_width)`.
  - Each space → `Glue(width: space_width, stretch:, shrink:)` plus a
    `Penalty(width: 0, penalty: 0, flagged: false)` before the glue
    (Knuth's standard space-break pattern).
  - Each hyphenation point → `Penalty(width: hyphen_width, penalty:
    50, flagged: true)`.
  - Each newline → `Penalty(width: 0, penalty: -Infinity, flagged: true)`.

- `lib/arrolio/text_layout/greedy.rb` and `knuth_plass.rb` — refactor
  to use `KnuthSequenceBuilder` + `Breaker` with different parameters:
  - Greedy: `tolerance: Infinity` (always accept first fit).
  - KnuthPlass: `tolerance: 1.0` (standard).

- A `LineAssembler` reconstitutes `Line[]` from the breaker's output
  and the original run list.

## Done-When

- [ ] All TODOs 11 and 12 specs still pass after refactor.
- [ ] Both breakers use the same `KnuthSequenceBuilder`.
- [ ] Both use the same `Breaker` (different params).
- [ ] The shared `LineAssembler` produces identical Lines to before.
- [ ] Code size shrinks (no duplicate line-assembly logic).
