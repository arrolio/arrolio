# TODO.complete — Path to 100% mn2pdf parity

## Current baseline (2026-08-08)

`bundle exec rake parity:check` reports **48.94%** overall similarity
on the OIML r060/1 fixture, 29 pages vs 28 reference.

375 specs pass, 0 failures, 0 rubocop offenses across 174 files.

## Status snapshot

| TODO | Status | Layer | Impact | What shipped |
|------|--------|-------|--------|-------------|
| 60 | done | adapter | med | Footnote extraction, inline markers, page-bottom rendering |
| 61 | done | engine | high | Typed errors with metadata, strict mode |
| 62 | done | font | low | FontScanner + FontMetrics::Registry auto-resolution |
| 63 | done | adapter | med | Zero flavor artifacts in lib/ (grep-enforced) |
| 64 | done | adapter | med | Selector-driven adapter specs |
| 66 | done | content | high | Content::Note, Example, TermEntry, FigureGroup, BibliographyItem |
| 70 | done | metrics | critical | TTF metrics via Fontisan, font embedding, subsetting |
| 71 | in progress | flowable | high | PositionedBlock, RotatedText, Style#text_transform shipped |
| 72 | in progress | flowable | high | colspan, bold headers, continuation caption, row min_height |
| 73 | done | flowable | med | Right-aligned page numbers, bold level-1, sub-indent |
| 74 | in progress | render | high | rsvg-convert rasterization wired, source dir resolution |
| 75 | in progress | flowable | med | mml integration, 10 specs, ELEMENT_HANDLERS registry |
| 76 | in progress | engine | med | Odd/even header alignment shipped |
| 77 | done | adapter | low | Sub/sup baseline, note label suffix, hyperlink underline |
| 78 | done | adapter | low | Bibliography as paragraph, hanging indent |
| 79 | in progress | text | high | KP badness, emergency stretch, Glue merge, TOLERANCE |
| 80 | done | harness | critical | rake parity:check CI task |

## Architectural quality (audited 2026-08-08)

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
70 (done) → 79 (hyphenation) → 72 (rowspan) → 71 (cover) → 75 (mfrac)
```

## Verification

`bundle exec rake` (rspec + rubocop) must be green.
`bundle exec rake parity:check` similarity must not regress.
