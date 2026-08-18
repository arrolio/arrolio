# TODO.complete — Path to 100% mn2pdf parity

## Current baseline (2026-08-09)

`bundle exec rake parity:check` reports **62.7%** overall similarity
on the OIML r060/1 fixture, **28 pages vs 28 reference** (all pages PARTIAL+).

376 specs pass, 0 failures, 0 rubocop offenses across 174 files.

## Status snapshot

| TODO | Status | Layer | Impact | What shipped |
|------|--------|-------|--------|-------------|
| 60 | in progress | adapter | med | Per-page footnote area (FOP semantics) — extraction/markers shipped |
| 61 | done | engine | high | Typed errors with metadata, strict mode |
| 62 | done | font | low | FontScanner + FontMetrics::Registry auto-resolution |
| 63 | done | adapter | med | Zero flavor artifacts in lib/ (grep-enforced) |
| 64 | done | adapter | med | Selector-driven adapter specs |
| 66 | done | content | high | Content::Note, Example, TermEntry, FigureGroup, BibliographyItem |
| 70 | done | metrics | critical | TTF metrics via Fontisan, font embedding, subsetting |
| 71 | in progress | flowable | high | PositionedBlock, RotatedText, Style#text_transform shipped |
| 72 | in progress | flowable | high | colspan, bold headers, continuation caption, row min_height |
| 73 | done | flowable | med | Right-aligned page numbers, bold level-1, sub-indent |
| 74 | done | render | high | SVG rendering via rsvg-convert (covered by TODO 84) |
| 75 | done | adapter | high | MathML extraction from fmt-stem (recursive math element search) |
| 76 | in progress | engine | med | Odd/even header alignment shipped |
| 77 | done | adapter | low | Sub/sup baseline, note label suffix, hyperlink underline |
| 78 | done | adapter | low | Bibliography hanging indent + tag formatting |
| 79 | in progress | text | high | KP badness, emergency stretch, Glue merge, TOLERANCE |
| 80 | done | harness | critical | rake parity:check CI task |
| 81 | in progress | adapter | high | Conditional XSL style refinements (heading margins, term spacing) |
| 82 | done | adapter | high | Semantic/presentation element deduplication (xref, eref, identifier) || 83 | done | adapter | high | Nested list support (adapter + flow builder) |
| 84 | done | render | critical | Inline SVG extraction + rsvg-convert rasterization (parity 53→57%) |
| 85 | done | adapter | medium | Locality reference formatting (clause=X → clause X) |
| 86 | done | text | high | KP emergency pass, run-group styles, word-level justify (text loss fixed) |
| 87 | pending | engine | medium | Odd/even page template variants |
| 88 | pending | text | medium | Hyphenation support for long words |
| 89 | done | flowable | high | Rowspan via Table::Grid (welded groups, valign) |
| 90 | pending | flowable | medium | MathML stacked layout (mfrac, msqrt) |
| 91 | done | harness | high | Parity diff diagnostics (rake parity:diff PAGE=N) |
| 92 | done | flowable | high | Table geometry config, footnotes, px→pt SVG, caption-in-table |
| 93 | pending | render | medium | Figure text searchability (SVG text overlay for pdftotext) |
| 94 | done | engine | critical | FO space resolution (max of consecutive spaces) — 28 pages! |
| 95 | done | engine | high | Title block as header static content |
| 96 | pending | layout | high | Pagination drift per region (drift map in TODO 96) |

## Architectural quality (audited 2026-08-10)

- Zero `require_relative` in lib/
- Zero internal `require 'arrolio/...'` in lib/ (autoload only)
- Zero `respond_to?` in lib/
- Zero `instance_variable_set/get` in lib/
- Zero `send` to private methods in lib/
- OCP: `CONVERTER_REGISTRY` (adapter), `ELEMENT_HANDLERS` (MathML)
- All value objects frozen with `==`/`eql?`/`hash`
- All internal code uses autoload (no require_relative)
- `public_send` only for dynamic dispatch on EXTERNAL Mml objects

## Critical path to 90%+

```
96 (drift map, region by region) → 71 (cover) → 88 (hyphenation) → 90 (mfrac)
```

## Verification

`bundle exec rake` (rspec + rubocop) must be green.
`bundle exec rake parity:check` similarity must not regress.
