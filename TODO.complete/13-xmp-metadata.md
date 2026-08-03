---
priority: P2
impact: low
depends_on: [12]
layer: render
status: done
est: 1d
---

## Problem

mn2pdf emits an XMP packet with PDF/A-1b or PDF/A-2 metadata
embedded as a stream. Required for long-term archival and some
workflow tools.

## Approach

File: `lib/arrolio/renderer/xmp.rb`

Build the XMP XML packet from document metadata:

```xml
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description xmlns:dc="..." dc:title="..."/>
    <rdf:Description xmlns:pdf="..." pdf:Producer="..."/>
    <rdf:Description xmlns:xmp="..." xmp:CreatorTool="..."/>
  </rdf:RDF>
</x:xmpmeta>
```

Embed as an uncompressed stream, referenced from `/Metadata` on
the catalog dict.

## Done-When

- [ ] `exiftool out.pdf` shows XMP tags.
- [ ] Title, Author, Producer match Info dict.
- [ ] Specs cover: XML well-formedness, namespace correctness.

## Implementation

`lib/arrolio/renderer/xmp_builder.rb` (95 lines) — `XmpBuilder` generates RDF/XML XMP packet with dc:title, dc:creator, pdf:Producer, xmp:CreatorTool. `Renderer::Pdf#attach_xmp_metadata` emits it as /Metadata stream on catalog. PDF now shows "Metadata Stream: yes". 9 specs.
