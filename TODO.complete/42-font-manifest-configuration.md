---
priority: P2
impact: med
depends_on: []
layer: render
status: done
est: 2d
---

## Problem

Arroolio registers fonts via the `font_paths` hash in the layout
spec YAML. mn2pdf uses a richer **font manifest** that supports:
- Font discovery (scan directories for TTF/OTF)
- Fallback chains (try font A, fall back to B, then C)
- Character-coverage declarations (this font covers codepoints X-Y)
- Subsetting options (which glyphs to embed)

## mn2pdf reference

`fontConfig.java` reads a JSON font manifest:
```json
{
  "fonts": [
    {
      "name": "Times New Roman",
      "path": "/path/to/times.ttf",
      "variants": {
        "bold": "/path/to/timesbd.ttf",
        "italic": "/path/to/timesi.ttf",
        "bold_italic": "/path/to/timesbi.ttf"
      },
      "covers": "0000-FFFF",
      "subset": true
    }
  ],
  "fallback": ["Times New Roman", "Noto Sans", "Arial"]
}
```

This lets mn2pdf automatically select the right font variant for
bold/italic runs and fall back when a character isn't in the
primary font.

## Approach

1. `Arroolio::Font::Manifest` — parses a JSON/YAML manifest.
2. `Font::Registry` consults the manifest to resolve:
   - Primary font by name
   - Variant by weight + style
   - Fallback by character coverage
3. `GlyphMeasurer` uses the resolved font for width calculations.
4. `Font::Embedder` uses the resolved path for subsetting.

The layout spec's `font_paths` hash becomes a simple manifest:
```yaml
font_manifest:
  primary:
    Times New Roman:
      regular: /path/to/times.ttf
      bold: /path/to/timesbd.ttf
      italic: /path/to/timesi.ttf
  fallback: [Noto Sans, Arial]
```

## Done-When

- [ ] Font manifest supports variant selection (bold/italic auto).
- [ ] Fallback chain: if primary font lacks a glyph, try next.
- [ ] Layout spec uses `font_manifest` instead of flat `font_paths`.
- [ ] Specs cover: variant selection, fallback chain, missing glyph.

## Implementation

`lib/arrolio/font/manifest.rb` (120 lines) — `Font::Manifest` value object. Maps family names to variant paths (regular/bold/italic/bold_italic). Fallback chain resolution. `resolve(name, weight:, style:)` tries primary family then fallback. `to_flat_paths` converts to the existing font_paths format. `from_hash` factory for YAML/JSON. 11 specs.
