---
priority: P1
impact: med
depends_on: [10]
layer: render
status: done
est: 2d
---

## Problem

Arroolio renders hyperlinks as plain text with no clickable URI.
mn2pdf has a full annotation system (`Annotation.java`,
`PDAnnotationMarkup`, `LinkQuadPoints`) that emits PDF `/Annots`
with `/S /URI`, `/S /GoTo`, and `/Dest` actions.

## mn2pdf reference

mn2pdf's `Annotation.java` hierarchy:
- `Annotation` — base class
- `LinkAnnotation` — `/Subtype /Link`
- `FileAttachmentAnnotation` — embedded files
- `PDFTextAnnotation` — sticky notes
- `PDAnnotationMarkup` — markup (highlights, underlines)

Annotations are attached to the page's `/Annots` array with
a bounding rectangle (`/Rect`) and an action (`/A`).

## Approach

1. `Content::Hyperlink` — wraps inline runs + a URI (from TODO 37).
2. `Output::PlacedBox` gains an optional `:annotation` data field.
3. The FlowBuilder emits hyperlink boxes with the URI.
4. `Renderer::Pdf` collects all annotation boxes per page and
   emits the `/Annots` array on each page dictionary.

For internal links (xref to sections):
- The engine records heading → page_number mappings (already done
  via `FlowContext#heading_entries`).
- The renderer emits `/Dest [page_ref /XYZ x y null]` for internal
  links.

## Done-When

- [ ] External links (`<link href="...">`) produce clickable URIs.
- [ ] Internal cross-references (`<xref target="...">`) jump to
      the correct page.
- [ ] Link styling (underline, color) matches the style.
- [ ] Specs cover: external link, internal link, broken link.

## Implementation

Merged into TODO 10. `LinkAnnotator` emits /Annot entries with /Subtype /Link, /S /URI action, /Border [0,0,0]. External links produce clickable PDF annotations.
