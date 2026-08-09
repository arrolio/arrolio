---
priority: P1
impact: high
depends_on: [89]
layer: flowable
status: pending
est: 2d
---

## Problem

Tables render with incorrect cell heights and padding, causing tables
to take more or fewer pages than the reference. The OIML fixture has
6 tables (Table 1-6) spanning ~6 pages. Our rendering shifts content
on pages 19-21 by 1-2 pages.

## Specific issues

1. **Row min-height not enforced.** The XSL specifies
   `table-row-style: min-height: 8.3mm`. Our table rows may not
   enforce this minimum.

2. **Cell padding mismatch.** The XSL uses default FO cell padding
   (typically 1pt). Our `table_cell` style has `margin_top: 2,
   margin_bottom: 2` — may differ from reference.

3. **Header row height.** Bold header cells should match reference
   height. The bold font has different metrics.

4. **Table caption spacing.** "Table N — Description" caption may have
   different space-before/space-after than body paragraphs.

5. **Continuation pages.** Tables that span pages should show
   "Table N (continued)" on the continuation page. Currently wired
   but may not trigger correctly.

## Approach

1. **Enforce row min-height.** Check `Row#min_height` is applied in
   `TableFlowable#render_row`. Ensure the height is at least
   `[natural, row.min_height].max`.

2. **Match cell padding.** Compare reference cell padding (via bbox
   measurement) and adjust `table_cell` margins.

3. **Table caption style.** Verify `table_name_style` has correct
   space-before and font-weight.

4. **Continuation trigger.** Verify the engine correctly splits tables
   across pages and emits continuation captions.

## Done-When

- [ ] Table 1 renders at correct height with row min-height enforced
- [ ] Cell padding matches reference within 1pt
- [ ] Continuation caption appears when table spans pages
- [ ] Table pages 19-21 align with reference content
- [ ] Overall parity > 60%

## Measurement

`bundle exec rake parity:check` — pages 19-21 currently 8-25%.
Last measured: 2026-08-09.
