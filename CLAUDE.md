# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Arrolio is

Arrolio is the middle layer of a three-library stack for paged-media PDF generation in pure Ruby:

- **`pdfrb`** (sibling gem, `~/src/claricle/pdfrb`) — pure-Ruby PDF byte format (streams, fonts, xref, encryption). No layout knowledge.
- **`arrolio`** (this gem) — FOP-like paged layout: page templates, threaded flows, line/page breaking, tables, lists, SVG, page-model selection, running headers/footers. **Flavor-agnostic**: the gem knows nothing about any specific document format.
- **`loom`** (separate gem, not yet built) — multi-target layout compiler (DSL → Arrolio IR, CSS, XSL-FO, IDML).

Arrolio deliberately does NOT own: PDF byte format (Pdfrb), DSL authoring (Loom), multi-target compilation (Loom), the semantic content model (`metanorma-document` and friends — Arrolio defines a *contract*, not a parser), or **any flavor-specific artifact** (no OIML/ISO/IEC/BSI code, data, XSL, or YAML inside the gem).

## The flavor-encapsulation invariant (non-negotiable)

**Flavors live OUTSIDE the gem.** A flavor is a directory containing XSL-derived YAML configuration (and the upstream XSL itself). The gem ships zero flavor artifacts:

- `lib/` contains no flavor-named files (`oiml`, `iso`, `iec`, `bsi`, …).
- `lib/arrolio.rb` has no flavor autoloads and no flavor-specific Ruby anywhere.
- `lib/arrolio/generic_adapter.rb` has zero hardcoded XML element names outside a clearly-labelled `DEFAULT_SELECTORS` constant (Metanorma standoc convention).
- `lib/arrolio/renderer/pdf.rb` reads header/footer and cover-logo values from `layout_spec.yml`, not hardcoded constants (the only literals are engine-safe fallback defaults).
- `lib/arrolio/content/document.rb` constructor validates that `sections`, `preface`, `bibliography` are `Content::Section[]` — non-Section items raise `ContentError` at the construction site.
- `flavors/` (sibling of `lib/`) is excluded from the gemspec's `spec.files`.
- `spec/fixtures/flavors/sample/` is a synthetic, flavor-neutral fixture used by the gem's own tests.
- `flavors/PACKAGING.md` documents the flavor gem convention for external authors.

A flavor is rendered by pointing `Arroolio::ConfigDrivenPipeline` at the flavor directory:

```ruby
Arroolio::ConfigDrivenPipeline.render(xml, io: io, flavor_dir: '/path/to/flavor')
```

Or via CLI: `exe/arrolio2pdf input.xml output.pdf /path/to/flavor`.

The user's principle: **"OIML FLAVOR SHOULD ONLY BE CONFIGURATION — like how the XSL is PURE CONFIGURATION!! NO CODE!"** A flavor is XSL + 3 generated YAML files. Zero Ruby.

## Two-pass model — the central architectural invariant

```
Content tree + LayoutSpec
        ↓  (layout pass)
Engine::Paged
        ↓
Output::Page[]   ← medium-neutral contract between Engine and Renderer
        ↓  (render pass)
Renderer::Pdf
        ↓
PDF bytes (via Pdfrb)
```

**Output::Page[] is the only contract between Engine and Renderer.** The renderer must never make layout decisions — every coordinate, style, and content reference comes from the Output tree. Future renderers (PostScript, PPML, in-memory test canvas) walk the same tree.

Each layer is independently testable. Keep layer boundaries airtight: Content knows nothing about pages or PDF; Engine knows nothing about PDF bytes; Renderer knows nothing about layout algorithms.

## Project state (as of 2026-09-01)

The generic config-driven pipeline renders the OIML r060/1 fixture to a 28-page A4 PDF matching the mn2pdf v2.55 reference at **68.92% text parity, 28/28 pages** (`bundle exec rake parity:check`). 452 specs, 0 rubocop offenses, 214 files.

What's in the gem (core, flavor-agnostic):
- `lib/arrolio/{content,style,layout_spec,font,font_metrics,glyph_measurer,inline_run,text_layout,flowable,flowables,frame,flow_context,engine,output,renderer,harness,flavor}/`
- `lib/arroolio/generic_adapter.rb` — dispatch + document glue; per-concern conversion lives in included seams under `lib/arroolio/generic_adapter/` (FootnoteExtraction, TableConversion, InlineRunCollection, HeadingExtraction, ListConversion, MetadataExtraction, DocumentExtraction). Adding an element family = a module + one include.
- `lib/arroolio/generic_flow_builder.rb` — `build()` + dispatch; per-family emission seams under `lib/arroolio/generic_flow_builder/` (Sequences, Terms, Notes, Figures, Lists, Bibliography, Tables).
- `lib/arroolio/config_driven_pipeline.rb` — orchestrates adapter + flow builder + engine + renderer + ToC; resolves fonts via fontist (`FontScanner`).
- `lib/arroolio/renderer/pdf.rb` — page emission; Pdfrb coupling points in `lib/arroolio/renderer/pdf/` (FontEmbedding, Assets, Metadata). The renderer never measures glyph widths — `Line::PlacedRun` carries `chunk_widths` from the breakers.
- `lib/arroolio/asset_resolver.rb`, `lib/arroolio/toc_builder.rb` — generic helpers (both with direct specs).
- `exe/arrolio2pdf` — generic CLI taking a flavor directory argument.
- `scripts/xsl_to_config.rb` — generates all three flavor YAML files from an XSL stylesheet.
- `data/arrolio/` — AFM metrics + glyphlist for the 14 PDF standard fonts (core data, not flavor data).

What's outside the gem (flavor artifacts):
- `flavors/oiml/{layout_spec,adapter_rules,flow_rules}.yml` — generated by `xsl_to_config.rb` from the authoritative XSL at `~/src/mn/metanorma-taste/data/oiml/oiml.xsl`.
- `spec/fixtures/flavors/sample/` — synthetic flavor-neutral fixture for the gem's tests.

What's open (intentionally — see `TODO.complete/`, frontmatter `status:` is authoritative):
- TODO 87: odd/even page templates beyond header parity (headers mirror; templates don't).
- TODO 88: hyphenation support.
- TODO 90: MathML mfrac true stacking (the open piece).
- TODO 93: figure text searchability (figures render as images; the reference's figure text extracts).
- TODO 96: pagination drift parity — the master ledger: remaining region deficits, keep-rules negative results (the reference does NOT enforce widows; term entries are NOT atomic), the heading-gap coupled-landing recipe, and the C2 margin-unification decode (a dedicated re-tuning session, not a release-day change).
- TODOs 53-62 are DONE (second flavor spike, manifest contract, header/footer config, adapter MECE, strict typing, packaging docs, XSL profiles, footnote fidelity, typed errors, fontist).

The TODO files in `TODO.complete/` and `TODO.implementation/` are the roadmap. `TODO.complete/README.md` covers the parity roadmap; `TODO.implementation/README.md` covers the foundation phase plan.

**Naming:** the code uses `Arroolio` (one r); the gemspec/gem name is also `arrolio`. Some TODO files use `Arroolio` (two r's) — the code is authoritative.

## Commands

```bash
bundle exec rake            # rspec + rubocop (the default task)
bundle exec rspec           # full suite
bundle exec rspec spec/arrolio/style_spec.rb                  # one file
bundle exec rspec spec/arrolio/style_spec.rb:42               # one example by line
bundle exec rspec -t ~e2e   # skip slow end-to-end specs
bundle exec rubocop
bundle exec rubocop -A      # auto-correct safe offences

# Render any flavor via the generic CLI:
bundle exec ruby exe/arrolio2pdf input.xml out.pdf flavors/oiml

# Regenerate a flavor's YAML from its XSL (development time, not runtime):
bundle exec rake flavor:generate XSL=path/to/flavor.xsl OUT=flavors/name
# Or directly:
bundle exec ruby scripts/xsl_to_config.rb path/to/flavor.xsl flavors/name
```

The OIML reference PDF for r060/1 is at `~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.pdf` (mn2pdf v2.55, 28 pages). The OIML fixture XML is at `~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.presentation.xml`.

`pdfrb` is pinned to a local path (`/Users/mulgogi/src/claricle/pdfrb`) in the Gemfile until it ships to RubyGems.

## Architectural conventions (non-negotiable)

- **`autoload` only — never `require_relative`, never `require` for internal code.** Autoloads live in the immediate parent namespace's file (create that file if it doesn't exist yet). Example: classes under `Arroolio::Content::*` are autoloaded from `lib/arrolio/content.rb`, which itself is autoloaded from `lib/arrolio.rb`.
- **Nested module/class style, NOT compact.** Always write `module Arroolio; class Foo; end; end`, never `class Arroolio::Foo`. Compact style breaks Ruby's lexical constant lookup — sibling constants resolved by short name (e.g. `FontMetrics::Registry` inside `class Arroolio::GlyphMeasurer`) won't autoload.
- **`# frozen_string_literal: true` at the top of every Ruby file.**
- **Immutable value objects.** Models that cross a layer boundary freeze in their constructor and define `==`, `eql?`, `hash` by value. Builders accumulate into Arrays; the immutable node is constructed in one shot.
- **Dispatch by `is_a?` and `role` Symbols, not by `respond_to?`.** Each content/layout node carries a `style_id` Symbol used for style registry lookup.
- **No `send` to private methods, no `instance_variable_set`/`instance_variable_get`, no `respond_to?` type checks.** Redesign the boundary instead of bypassing encapsulation.
- **No `double()` in specs.** Use real model instances, or `Struct.new(...)` stand-ins for plain data.
- **No hand-rolled `to_h`/`from_h`/`to_json`/`serialize` on model classes.** (Style::Definition#to_h is allowed: Definition is a value object whose Hash form is internal config shape, not a persisted wire contract.)
- **Validation in constructors.** Bad input raises typed errors from `Arroolio::Error` (`ContentError`, `LayoutSpecError`, `LayoutError`, `RenderError`) carrying structured metadata, not generic `RuntimeError`.
- **No flavor artifacts in the gem.** No OIML/ISO/IEC/BSI Ruby, YAML, or XSL under `lib/` or `data/`. Flavors live in `flavors/` (excluded from the gemspec).

## Design principles for new code

When extending any layer, apply OCP/DRY/MECE strictly:

- **Open/Closed:** adding a new flavor = adding a `flavors/<name>/` directory with XSL + 3 generated YAML files. Zero core changes. Adding a new flowable, content node, renderer, or visitor = *registering* a new class — not editing a switch statement.
- **MECE per layer:** Content describes *what*, LayoutSpec describes *how*, Engine produces *where*, Output freezes the result, Renderer emits bytes. Flavor describes *what the source format looks like* (adapter_rules.yml) and *how to lay it out* (flow_rules.yml + layout_spec.yml). If a class reaches across these boundaries, the responsibility is in the wrong place.
- **Greedy line breaking** is the only breaker today. When Knuth-Plass lands (TODO 12), it plugs into `TextLayout::*` without touching flowables or the engine.
- **Specs follow layer boundaries.** Each layer has its own spec directory; the `:e2e` tag is reserved for full-pipeline specs. The gem's own specs use the synthetic `spec/fixtures/flavors/sample/` flavor — they never depend on OIML.

## Renderer/Pdfrb coupling notes

- `Renderer::Pdf#render_page` deliberately points each pdfrb page's `Resources` Hash at the catalog's. Pdfrb's `Fonts#add` attaches fonts to the *catalog* Resources, but each Page shadows with its own empty Hash — without this workaround, fonts are invisible to readers.
- Margin contract (see `Flowable`'s doc): TextFlowable (and HeadingFlowable) count `space_before/after` inside height/emit; List/Image/Table-based flowables do not — spacing around them travels as explicit Spacers. The engine collapses via `Engine::MarginCollapse`; do NOT unify without a dedicated re-tuning session (decoded in TODO 96).
- Header/footer styling comes from `layout_spec.yml` (`header_footer:` block); font resolution goes through fontist (`FontScanner`) with AFM fallback for the 14 standard fonts.
- Parity workflow: `bundle exec rake parity:check` / `parity:diff PAGE=N`; drift-map tooling and diagnostic cautions live in TODO 96.

## Key files to read first

- `lib/arrolio.rb` — the autoload tree; this is the map of every module.
- `lib/arrolio/error.rb` — the typed error hierarchy; raise these, never `RuntimeError`.
- `lib/arrolio/config_driven_pipeline.rb` — the end-to-end orchestration: adapter → flow builder → engine → ToC → renderer.
- `lib/arrolio/generic_adapter.rb` — XML → `Content::Document`, driven by `adapter_rules.yml`.
- `lib/arrolio/generic_flow_builder.rb` — `Content::Document` → flowables, driven by `flow_rules.yml`.
- `scripts/xsl_to_config.rb` — generates all three flavor YAML files from an XSL stylesheet.
- `spec/fixtures/flavors/sample/` — the synthetic flavor-neutral fixture used by the gem's specs.
- `flavors/oiml/` — the real OIML flavor (generated YAML + upstream XSL); lives outside the gem package.
- `TODO.complete/README.md` — parity roadmap and critical path.
- `TODO.implementation/README.md` — foundation phase plan.
