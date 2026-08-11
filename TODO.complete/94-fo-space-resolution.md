---
priority: P0
impact: critical
depends_on: [81]
layer: engine
status: done
est: 2d
---

## Problem

Our engine ADDS consecutive flowable margins (space_after of previous
+ space_before of current). FOP/FO uses space RESOLUTION: takes the
MAX of the two, not the sum. This causes every spacing change to
cascade incorrectly.

## Evidence

The reference PDF has ~8pt paragraph spacing between consecutive body
paragraphs (measured from bbox: consecutive paragraph lines are 21.2pt
apart vs 13.2pt normal line height = 8pt extra).

Adding margin_bottom: 8 to the body style caused page explosion (27 →
33 pages) because the margin cascaded to ALL child styles and ALL
paragraphs (including those inside notes, lists, terms).

## Approach

1. **Implement FO space resolution in Engine::Paged.** When placing
   flowable B after flowable A, the gap should be:
   ```
   gap = max(A.space_after, B.space_before)
   ```
   Not `A.space_after + B.space_before`.

2. **Track previous flowable's space_after.** The engine needs to know
   the previous flowable's margin_bottom to resolve the space.

3. **Apply to section-level flowables only.** Flowables inside
   containers (NoteFlowable, ListFlowable) handle their own internal
   spacing. Space resolution applies between sibling flowables in the
   main flow.

## Impact

With FO space resolution + body margin_bottom: 8:
- Standalone body paragraphs get 8pt gap (correct)
- Note body paragraphs still get 0 gap (correct — notes have their
  own margin_bottom on the container)
- Heading-to-body gap: max(heading.space_after, body.space_before) =
  max(12, 0) = 12pt (correct, no double-counting)

## Done-When

- [ ] Engine resolves consecutive flowable spaces via max()
- [ ] body margin_bottom: 8 produces correct inter-paragraph spacing
- [ ] No cascade to note/list/term internal paragraphs
- [ ] Overall parity > 58%

## Measurement

`bundle exec rake parity:check` — currently 53.99%.
Last measured: 2026-08-10.
