# TODO.implementation — Arrolio Work Breakdown

Arrolio is the **Ruby-only alternative to Apache FOP / XSL-FO**. It takes
a typed content tree plus a typed layout spec, lays out pages, and renders
to PDF via the sibling `pdfrb` gem. No XML input. No FO intermediate.
The Ruby model is the source of truth.

This directory tracks all implementation work as one file per TODO,
named `{NN}-{slug}.md`.

## Architectural layering (recap)

```
Content Tree (Ruby, typed, medium-independent)
       ↓
LayoutSpec (Ruby, typed: PageTemplate, Region, Style, Flow)
       ↓
Engine::Paged (Knuth-Plass breaking, frame threading)
       ↓
Output::Page[] (laid-out pages with placed boxes)
       ↓
Renderer::Pdf (walks Output tree, emits bytes via Pdfrb)
       ↓
PDF bytes
```

Each layer is independently testable. Output::Page[] is the contract
between Engine and Renderer.

## Primary end-to-end correctness: three subsystems

Arrolio is validated by three complementary subsystems, all
exercised against real OIML documents:

1. **OIML E2E pipeline** (TODOs 52–54) — parse real OIML XML via
   `metanorma-document`, apply an OIML LayoutSpec, render to PDF via
   Pdfrb. Proves the full pipeline works end-to-end.

2. **PDF diff subsystem** (TODOs 55–59), modeled on
   `~/src/lutaml/canon/` — semantic comparator with dimensions
   (text, font, position, colour, image, vector, structure),
   normative/informative classifier, multiple formatters, RSpec
   matchers, optional pixel diff. Catches "output changed in a way
   that matters".

3. **Conformance subsystem** (TODOs 62–66), modeled on
   `~/src/external/veraPDF-library/` — rule-based validator with
   profiles for layout baseline (TODO 63), PDF/A (TODO 64), and
   PDF/UA (TODO 64); feature extractor for debugging (TODO 65);
   auto-fixer for known-safe repairs (TODO 66). Catches "output is
   wrong even when it matches yesterday's output".

## Critical path (P0)

To reach **minimum viable PDF** (a one-page document with text), in order:

```
01 → 02 → 06 → 07 → 09 → 10 → 11 → 13
                                      ↓
21 → 22 → 23 (output)  ←── 20 (engine) ←── 16-19 (flowables)
```

After that, page templates (Phase 7) and tables (Phase 8) deliver
FOP-equivalent capability. Then the OIML E2E pipeline (Phase 17)
proves the engine on real-world documents, and the diff subsystem
makes correctness verifiable per-commit.

## Phase index

| Phase | Range | Layer | Outcome |
|---|---|---|---|
| 1 | 01–05 | foundation | Skeleton, content contract, layout spec, style system, visitors |
| 2 | 06–09 | metrics | AFM + TrueType glyph metrics + Registry + GlyphMeasurer |
| 3 | 10–13 | text | Break opportunities, Greedy + Knuth-Plass, Line + alignment |
| 4 | 14–15 | knuth | Universal Knuth elements + Breaker (refactor of Phase 3) |
| 5 | 16–20 | flowable | Flowable hierarchy + Frame + Engine::Paged driver |
| 6 | 21–23 | output | Output::Page[] + Renderer::Pdf + end-to-end smoke |
| 7 | 24–26 | template | PageTemplate, PageSequenceMaster, two-pass citations |
| 8 | 27–30 | table | Table model + Fixed/Auto layouts + TableFlowable |
| 9 | 31–32 | list | List model + ListFlowable (proper label/body columns) |
| 10 | 33–35 | media | Image loading via Pdfrb + SVG renderer + Form XObjects |
| 11 | 36–38 | inline | InlineBuilder + Hyperlink + Sub/superscript |
| 12 | 39–42 | xref | Leader + FieldRuns + Bookmark/outline + Destinations + TOC |
| 13 | 43–45 | page | Footnotes + Multi-column + Page numbering + Section tracking |
| 14 | 46–47 | color | Color management + XMP/Info metadata write |
| 15 | 48–49 | a11y | PDF/UA StructTree + marked content + alt text |
| 16 | 50–51 | composer | High-level Composer facade + style presets |
| 17 | **52–59** | **harness/diff** | **OIML E2E pipeline + canon-style diff subsystem** |
| 18 | 60–61 | polish | YARD docs + performance/stress tests |
| 19 | **62–66** | **conformance** | **veraPDF-style validator + profiles + feature extractor + fixer** |

**Total: 66 TODOs.**

## Phase 17 in detail — OIML E2E + diff subsystem

| TODO | What it builds |
|---|---|
| 52 | OIML adapter (metanorma-document → Arrolio content) + fixture corpus |
| 53 | OIML LayoutSpec — Ruby encoding of `oiml.xsl`'s visual intent |
| 54 | Pipeline (`Arrolio::Oiml::Pipeline.(xml, io:)`) + CLI + sanity spec |
| 55 | **PDF comparator** — semantic tree diff with dimensions, normative/informative classifier, profiles |
| 56 | **Diff formatters** — summary, pretty, by-page, by-element, JSON, HTML, JUnit |
| 57 | **Path locator + enrichment** — canonical paths, char-level diffs, source positions |
| 58 | **RSpec matchers + Harness API** — `match_pdf`, `be_equivalent_to_pdf`, `Arrolio::Harness.diff` |
| 59 | **Pixel diff mode** — optional raster-based diff for visual regressions |

## Phase 19 in detail — Conformance & validation (veraPDF-inspired)

| TODO | What it builds |
|---|---|
| 62 | Validation framework — Rule, Profile, TestAssertion, ValidationResult, Validator, Location |
| 63 | Layout baseline rules — no orphan headings, no widow/orphans, contiguous page numbering |
| 64 | PDF/A + PDF/UA conformance profiles — pragmatic rule subset; cross-check vs veraPDF |
| 65 | Feature extractor — fonts/images/colour/annotations dump for debugging |
| 66 | Auto-fixer — applies known-safe fixes (CreationDate, Producer, MarkInfo, XMP) |

After TODO 66 lands, Arrolio can self-validate its own output against
PDF/A and PDF/UA rules — a veraPDF in Ruby for documents Arrolio
produces.

## Front-matter shape

```yaml
---
priority: P0     # P0 blocks MVP; P1 = FOP parity; P2 = production; P3 = polish
phase: 1
depends_on: []   # TODO numbers that must be done first
layer: foundation
est: 2d          # 1d = single focused session; 5d = multi-week module
status: pending  # pending | in_progress | done
---
```

## What Arrolio deliberately does NOT do

- Parse XML input (FO or otherwise). **Loom's** job.
- Author DSLs (YAML, custom syntax). **Loom's** job.
- Compile to multiple targets (CSS, FO, IDML). **Loom's** job.
- Speak PDF byte format directly. **Pdfrb's** job.
- Own the semantic content model. **metanorma-document's** job —
  Arrolio defines a content contract, metanorma-document fills it.
- Replace veraPDF authoritatively for PDF/A. **veraPDF's** job.
  Arrolio's conformance profiles (Phase 19) are a pragmatic
  pre-check; veraPDF remains authoritative.

If a TODO crosses these boundaries, it belongs in another gem.

## Verification

Every TODO carries Done-When criteria. The global verification is:

- `bundle exec rake` — runs rspec + rubocop; must be green after every TODO.
- After TODO 23 (end-to-end smoke): a single-paragraph PDF renders correctly.
- After TODO 30 (TableFlowable): an OIML-style multi-page doc with tables
  renders.
- After TODO 54 (OIML pipeline): real OIML XML renders to PDF.
- After TODO 58 (RSpec matchers): every commit validates against FOP
  references with `be_equivalent_to_pdf`.
- After TODO 64 (PDF/A + PDF/UA): Arrolio's output passes the
  common-subset conformance rules.

## Status legend

- `pending` — not started.
- `in_progress` — actively being worked.
- `done` — complete; specs pass; ready for review.

(Initial seed: all 66 TODOs are `pending`. TODO 01 is partially done —
the gem skeleton already exists.)
