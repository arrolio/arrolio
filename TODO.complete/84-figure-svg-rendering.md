---
priority: P2
impact: high
depends_on: [74]
layer: render
status: pending
est: 3d
---

## Problem

The OIML fixture XML contains `<figure>` elements with `<name>`
(caption) but NO `<image>` child. The actual figure content is an
inline SVG embedded directly in the XSL stylesheet or referenced from
a generated resource.

Our adapter's `convert_figure` requires an `<image>` element — without
it, only the caption renders. The reference PDF shows full vector
illustrations (Figure 1: weighing instrument components, Figure 2:
load cell characterisation, Figure 3: definition illustrations,
Figure 4: classification symbol).

This is the **single biggest source of pagination drift**. Each
missing figure shifts body content by ~half a page, cascading through
the document.

## Current impact (2026-08-08)

- Page count: 26 vs 28 reference (2-page delta partly from missing
  figure bodies)
- Content alignment: body text starts ~1 page ahead of reference by
  page 9
- Overall parity stuck at ~53% partly due to figure absence

## Approach

1. **Identify figure sources.** The mn2pdf XSL has
   `<fo:instream-foreign-object>` for SVG embedded in the stylesheet.
   Other figures may come from `<image src="...">` pointing to
   generated SVG files.

2. **Extract SVG from XSL templates.** Parse the XSL to find
   `<svg:svg>` blocks inside figure-rendering templates. Store as
   standalone `.svg` files in the flavor's assets directory.

3. **Render SVG via rsvg-convert.** Already wired in TODO 74
   (`ImageFlowable` calls rsvg-convert for `.svg` files). Need to
   connect the extracted SVG to the figure content.

4. **Handle standalone figure illustrations.** Some figures (Figure 1
   in OIML) are complex multi-box illustrations with numbered labels.
   These are hand-authored SVG, not auto-generated.

## Done-When

- [ ] Figure 1-4 render with visible illustrations (not just captions)
- [ ] Page count within ±1 of reference
- [ ] Body content alignment matches reference on pages 5-18
- [ ] Overall parity > 65% on OIML r060/1 fixture

## Measurement

`bundle exec rake parity:check` — current 53.53%.
Last measured: 2026-08-08.
