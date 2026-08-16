---
priority: P1
impact: high
depends_on: [79]
layer: text
status: done
est: 2d
---

## Problem

List item body paragraphs sometimes lose text after cross-references.
The placed box correctly contains 2 lines of text (verified via debug),
but the renderer only outputs line 1 — line 2 is silently dropped.

## Example

Input paragraph:
```
For legally relevant software of digital load cells the following
statements according to [OIML_D_31_2008] shall be applied.
```

Rendered PDF (before fix): the line ran to x=597 on a 595pt page —
"be applied." was drawn off-page and clipped by readers.

## Root cause (found 2026-08-17)

NOT a font-metrics mismatch — TTF advance widths match the embedded
render exactly. The Knuth-Plass breaker rejected every intermediate
break of the paragraph (best candidate ratio 2.68 > TOLERANCE 2.5),
so the only surviving path was the FORCED final break, which bypasses
the ratio check: the whole paragraph rendered as one 552.6pt line on
a 426.7pt measure.

## Fix

- `KnuthPlass::Breaker`: TeX-style emergency-stretch pass. When the
  first pass yields no feasible solution, re-solve with
  EMERGENCY_STRETCH added to every line's stretchability — the
  paragraph breaks properly instead of overflowing.
- `KnuthPlass::Breaker`: removed the `prune?` cap that disabled
  active nodes beyond `line_widths.length + 10` lines — any
  paragraph or table cell longer than 11 lines got its tail crammed
  into one overfull line (visible as overlapping table-cell text).
- `KnuthPlass::Breaker#build_placed_runs`: style-preserving run
  grouping. A line is merged into one text operation per rendering
  signature; bold/italic/sub/superscript runs keep their formatting
  (previously the whole line took the first run's style). Trailing
  glue at the break is dropped so justify counts real word gaps.
- `TextFlowable#collect_runs`: re-inserts the word separator that a
  line break consumed when a split paragraph is rebuilt — otherwise
  re-layout glues boundary words ("…increasing anddecreasing").
  Hyphen breaks gain no space ("analogue-active" stays joined).
- `Renderer::Pdf#render_line_runs`: justified lines are drawn as one
  positioned text operation per word (FOP's model) with the stretch
  accumulated in each word's x. PDF word spacing (Tw) does not apply
  to two-byte CID-encoded embedded fonts, so justification cannot
  rely on it; the old boundary-shift approach concentrated the whole
  line's stretch at run boundaries (34pt holes around math runs).
- `GenericFlowBuilder`: `require 'tmpdir'` (was a transitive-require
  accident).
- Prefix sums for item widths/stretch/shrink make width queries O(1).

## Done-When

- [x] "be applied." renders after "shall" in list item b)
- [x] Text never overflows body width in list items
- [x] GlyphMeasurer widths match rendered widths (verified: measured
      501.6pt vs rendered 501.2pt for the failing line)
- [x] Specs cover list item with long inline tokens

## Measurement

Overall similarity 62.7% → 59.9% (2026-08-17). Text pages unchanged;
the drop is pages 23–27, where previously-overlapping table cells now
occupy their true height. Our table rows are taller than FOP's
(column-width debt — TODO 72/92); the old render accidentally matched
page boundaries while its cell text overlapped. Recovering the metric
requires table layout parity, not reverting these fixes.
