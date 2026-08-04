---
priority: P2
impact: low
depends_on: [70]
layer: adapter
status: pending
est: 1d
---

## Problem

Bibliography page (28) renders content but with different formatting.
The reference uses numbered references `[1]`, `[2]` with hanging
indent and specific spacing. Ours renders them as a flat list.

## Approach

1. The adapter already emits `Content::BibliographyItem` with `tag`
   and `formattedref`. The flow builder already emits
   `NoteFlowable` with the tag as marker. Verify the marker width
   and indent match the reference's hanging indent.
2. Match the reference's bibliography entry spacing
   (`space-after: 4pt` per entry).
3. Ensure bibliography section starts on a new page with its own
   heading "Bibliography" in the correct style.

## Expected improvement

Fixes page 28 from 72% to ~90%.

## Done-When

- [ ] Bibliography entries render with hanging indent
- [ ] Entry numbers match the reference
- [ ] Section heading "Bibliography" in correct style
- [ ] Page 28 similarity > 85%
