---
priority: P0
phase: 7
depends_on: [03, 20]
layer: template
est: 2d
status: in_progress
---

## Problem

Documents need more than one page geometry: cover pages differ from
body pages, running headers/footers vary, odd/even pages mirror each
other. The PageTemplate + Region types define static geometry; the
engine instantiates them per output page.

## Approach

Files under `lib/arrolio/layout_spec/`:

- `page_template.rb` (extended from TODO 03):
  - `name` (Symbol).
  - `page_size` (`[w, h]` or named like `:A4`, `:Letter`).
  - `margins` (Hash with `:top`, `:right`, `:bottom`, `:left`).
  - `region_extents` (Hash `:before => 15mm`, etc.).
  - Computed `regions` (Hash of name → Region with absolute geometry).

- `region.rb`:
  - `name`, `x`, `y`, `width`, `height`.
  - `flow_ref` (optional — names the Flow that fills this region).
  - `to_frame` → returns a fresh `Frame` for runtime use.

Helper: `PageSizes` constant mapping `:A4` → `[595, 842]`, `:Letter`
→ `[612, 792]`, `:Legal` → `[612, 1008]`, etc.

Region geometry computed from page size + margins + region extents:
```
body = Region(x: left_margin, y: bottom_margin,
              width: page_w - L - R,
              height: page_h - T - B - before_extent - after_extent)
```

## Done-When

- [ ] `PageTemplate.new(page_size: :A4, margins: 25)` produces a
      template with body region of 545×743pt.
- [ ] Asymmetric margins honoured.
- [ ] `Region#to_frame` returns a Frame with `remaining_height ==
      height`.
- [ ] All 14 standard page sizes supported.
- [ ] Specs cover A4, Letter, asymmetric margins, with-header-footer.
