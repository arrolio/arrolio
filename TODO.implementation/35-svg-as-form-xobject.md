---
priority: P2
phase: 10
depends_on: [34]
layer: media
est: 1d
status: pending
---

## Problem

SVG diagrams that repeat on every page (logos, watermarks) currently
re-render each time. Better: render once into a Form XObject, then
`canvas.draw_xobject(name, at:, scale:)` on every page. Cuts render
time and PDF size.

## Approach

Files:

- `lib/arrolio/svg/form_xobject_builder.rb` — takes an SVG Document,
  renders it once into a `Pdfrb::Model::Cos::Stream` with
  `/Type /XObject`, `/Subtype /Form`, `/BBox`. Returns the OID.

- Modify `Arrolio::SVG::Renderer` to optionally emit into a Form
  XObject stream instead of directly into a page's canvas.

- ImageFlowable and other consumers gain an option to wrap their
  rendering in a Form XObject when the same image is placed > N times
  (heuristic for "this repeats").

## Done-When

- [ ] SVG rendered as Form XObject appears identical to inline render.
- [ ] Form XObject reused across 10 pages produces a PDF smaller than
      rendering inline 10 times.
- [ ] Form XObject can be scaled/positioned per page.
- [ ] Round-trip: rendered PDF re-read has /XObject /Form.
