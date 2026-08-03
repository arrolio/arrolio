---
priority: P0
impact: high
depends_on: [01]
layer: render
status: done
est: 3d
---

## Problem

mn2pdf embeds every used glyph as a subsetted CIDFont (Type0 +
Identity-H + CIDToGIDMap + ToUnicode CMap). Arrolio currently emits
the 14 standard Type1 fonts by name (no embedding). Visually close
on most PDF readers but the underlying bytes are completely
different, and any reader without those fonts (rare, but possible
on embedded systems) renders blank.

## Approach

Files under `lib/arrolio/renderer/`:

- `font_embedder.rb` — given a font name + the registered TTF path,
  builds the Type0/CIDFont/Descriptor object graph in Pdfrb and
  returns the resource Symbol. Subsets to only used glyphs (track
  per-render pass).
- `subsetter.rb` — given a TTF + a set of used codepoints, produces
  a new TTF containing only those glyphs, with glyph IDs renumbered
  and a corresponding /CIDToGIDMap. Use the `ttfunk` gem or roll a
  minimal subsetter focused on cmap + glyf + hmtx.
- Update `FontRegistry#resolve` to call FontEmbedder for non-standard
  fonts; standard 14 still pass through to `document.fonts.add(name)`.

The ToUnicode CMap maps CID → Unicode. For Identity-H encoding, CID
= GID. Build it from the cmap table's (gid → unicode) reverse map.

## Done-When

- [ ] After render, the PDF contains /Type0 fonts with /BaseFont
      matching the embedded TTF's PostScript name.
- [ ] /ToUnicode CMap present and decodes correctly (pdftotext
      round-trips the same text it round-trips for the reference).
- [ ] Subset percentage: embedded font size ≤ 50 KB per font for
      typical OIML doc.
- [ ] Specs: registered TTF appears in output PDF resources;
      unregistered falls back to Helvetica; ToUnicode decodes
      ASCII + accented Latin.

## Implementation

`lib/arrolio/font/embedder.rb` subsets via Fontisan, embeds as Type0/CIDFontType2 with Identity-H. `lib/arrolio/font/text_encoder.rb` converts Unicode→subset GIDs. ToUnicode CMaps generated from subset cmap.
