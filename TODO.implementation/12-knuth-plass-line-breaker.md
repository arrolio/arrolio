---
priority: P1
phase: 3
depends_on: [10]
layer: text
est: 2d
status: in_progress
---

## Problem

Greedy line breaking produces uneven right margins and unbalanced
justify. Knuth-Plass (TeX, Pango) minimises the sum of squared
shrink/stretch ratios across the paragraph, producing visually
balanced text. Opt-in via `style.line_break: :knuth_plass`.

## Approach

File: `lib/arrolio/text_layout/knuth_plass.rb`.

Same I/O as Greedy: `(runs, measurer, width, align)` → `[Line]`.

Algorithm (simplified — TODO 14 generalises):
1. Enumerate break opportunities.
2. `best[i]` = optimal cost to reach opportunity i. `best[0] = 0`.
3. For each pair `(i, j)` with `i < j`:
   - Compute `line_width = opps[j].width_before - opps[i].width_before`.
   - If `:forced` at j, treat as zero-cost break.
   - If `line_width > target`, allow but with very high badness.
   - Otherwise badness = `((target - line_width) / target) ** 2 * 100`.
   - `candidate_cost = best[i] + badness`. Keep the minimum.
4. Walk back from end to recover the chosen break sequence.
5. Skip empty segments (would produce empty trailing lines).

Knuth's full algorithm has penalties, fitness classes, and demerits.
This TODO uses the simplified version. TODO 14 lifts it to a general
`Breaker` with full Knuth semantics.

## Done-When

- [ ] Single short word → 1 line.
- [ ] Long paragraph wraps to multiple lines without empty trailing line.
- [ ] For a sample paragraph, KnuthPlass produces line widths whose
      variance is ≤ Greedy's variance on the same paragraph (i.e. more
      balanced).
- [ ] Output interface is identical to Greedy (swappable).
