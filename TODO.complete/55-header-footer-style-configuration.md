---
priority: P1
impact: med
depends_on: [50, 63]
layer: render
status: done
est: 1d
---

## Problem

The renderer (`lib/arrolio/renderer/pdf.rb`) hardcoded OIML-specific
header/footer and cover-logo values:

- Margins: `26.5 * MM_TO_PT` / `25.5 * MM_TO_PT` (OIML values)
- Header/footer font: `'Arial'` hardcoded
- Header/footer size: `9.0` hardcoded
- Rule width: `0.5` hardcoded
- Cover logo dimensions: `35.0mm` / `1459.0/1667.0` aspect (OIML logo)
- Cover logo margin: `25.5mm`

These are all OIML conventions. A flavor with different margins,
fonts, or logo dimensions would not render correctly without
modifying core — violating OCP.

## Approach

1. **LayoutSpec carries config**: `LayoutSpec` now exposes
   `header_footer_config` and `cover_logo_config` Hashes, loaded from
   `layout_spec.yml`'s `header_footer:` and `cover_logo:` blocks.
2. **Renderer reads from layout_spec**: `Renderer::Pdf#render`
   accepts a `layout_spec:` keyword; `header_footer_style` and
   `cover_logo_style` read values from it (falling back to
   engine-safe defaults when nil).
3. **Pipeline passes layout_spec through**: `ConfigDrivenPipeline`
   forwards `layout_spec:` to `Renderer::Pdf#render`.
4. **Flavor YAML declares its values**: `flavors/oiml/layout_spec.yml`
   declares `header_footer:` (Arial 9pt + 0.5pt rule + 26.5/25.5mm
   margins) and `cover_logo:` (35mm / 0.8758 aspect / 25.5mm margin).
5. **Sample fixture also declares** its own (Helvetica-based) values.

## Done-When

- [x] `LayoutSpec` exposes `header_footer_config` and `cover_logo_config`
- [x] `Loader` reads them from `layout_spec.yml`
- [x] `Renderer::Pdf#render` accepts `layout_spec:` and reads values
- [x] No hardcoded `'Arial'` or `26.5` literals in the renderer logic
- [x] Engine-safe defaults apply when `layout_spec:` is nil
- [x] Specs verify: configured values used, defaults used, both paths
      tested
- [x] OIML r060/1 still renders 28 pages via the generic pipeline

## Verification

- `spec/arrolio/layout_spec_config_spec.rb` (7 specs)
- `bundle exec rake` is green
- OIML render via `exe/arrolio2pdf` produces a 28-page PDF
