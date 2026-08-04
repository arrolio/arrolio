---
priority: P2
impact: low
depends_on: [70, 72]
layer: text
status: in_progress
est: 3d
---

## Problem

The engine uses a greedy line-breaking algorithm. The reference (FOP)
uses Knuth-Plass optimal fitting. Even with correct font metrics,
line breaks may differ at the margin, causing text to wrap
differently and shift content between pages.

The Knuth-Plass breaker exists (`TextLayout::KnuthPlass`) but is
not used by default — `TextFlowable` falls back to greedy.

## Approach

1. **Enable Knuth-Plass** as the default breaker for body text:
   set `line_break: :knuth_plass` in the body style of
   `layout_spec.yml`.
2. **Verify break points match FOP**: FOP uses a specific
   badness/penalty model. Our Knuth-Plass implementation may use
   different constants. Tune the demerit weights to match.
3. **Handle hyphenation**: FOP hyphenates long words at line
   boundaries using TeX-style hyphenation patterns. Our breaker
   doesn't hyphenate. Adding hyphenation support will match FOP's
   break opportunities.

## Expected improvement

After TTF metrics (TODO 70), this should raise similarity from
~30–50% to ~60–70% by matching line-level wrapping.

## Done-When

- [ ] Knuth-Plass is the default line breaker for body text
- [ ] Line break positions match FOP on >80% of body paragraphs
- [ ] Hyphenation is supported for long words at line boundaries
- [ ] Overall similarity > 60%
