---
priority: P0
impact: high
depends_on: []
layer: adapter
status: done
est: 2d
---

## Problem

`Arroolio::Oiml::Adapter` is 887 lines and handles 15+ responsibilities:
XML parsing, metadata extraction, clause/section structure, heading
extraction, paragraph/list/table/note/figure/term/bibliography/bibitem
conversion, inline run collection (complex walker), text normalization,
stem/math handling, image element handling.

This violates SRP, OCP, and MECE. The class is hard to test in
isolation (each method depends on private helpers), hard to extend
(adding a new element type means editing the central dispatch), and
the 665-line class-length rubocop offense is a direct symptom.

## Approach

Split into focused converter classes under `Arroolio::Oiml::Adapter::*`:

- `InlineRunCollector` — the complex walker (block-level skip, stem
  handling, style resolution). ~150 lines, the hardest piece.
- `TextNormalizer` — whitespace normalization heuristics.
- `MetadataExtractor` — bibdata → Content::Document metadata.
- `ClauseConverter` — clause/section/terms/definitions elements.
- `HeadingExtractor` — fmt-title → number + title.
- `ParagraphConverter` — `<p>` → Content::Paragraph.
- `ListConverter` — ul/ol/dl → Content::List.
- `TableConverter` — table/thead/tbody/tr/td → Content::Table.
- `NoteConverter` — note/termnote/example → paragraphs.
- `FigureConverter` — figure + image → Content::Image + caption.
- `TermConverter` — term → number + name + def + notes + source.
- `BibliographyConverter` — references/bibitem → paragraphs.
- `ElementNavigator` — shared XPath/direct-child helpers.

`Adapter` becomes a thin orchestrator that delegates to these.
Each converter receives the elements it should process + shared
helpers (InlineRunCollector, TextNormalizer, ElementNavigator).

Autoloads declared in `lib/arrolio/oiml/adapter.rb` (the parent
namespace file for `Adapter::*`).

## Done-When

- [ ] `Adapter` is under 150 lines (orchestrator only).
- [ ] Each converter is under 150 lines with a single responsibility.
- [ ] `InlineRunCollector` is independently testable.
- [ ] No method longer than 25 lines.
- [ ] All existing specs still pass.
- [ ] New specs cover each converter's public interface.
- [ ] Rubocop Metrics/ClassLength is green for all classes.

## Implementation

13 focused classes under `lib/arrolio/oiml/adapter/`:
- `element_navigator.rb` (92 lines) — pure REXML traversal helpers
- `text_normalizer.rb` (37 lines) — whitespace normalization
- `inline_run_collector.rb` (159 lines) — the complex walker
- `metadata_extractor.rb` (97 lines) — bibdata extraction
- `heading_extractor.rb` (76 lines) — fmt-title → number + title
- `paragraph_converter.rb` (35 lines) — <p> conversion
- `clause_converter.rb` (66 lines) — clause/terms/definitions
- `term_converter.rb` (128 lines) — term entries
- `note_converter.rb` (48 lines) — note/termnote/example
- `list_converter.rb` (64 lines) — ul/ol/dl
- `table_converter.rb` (51 lines) — table/thead/tbody
- `figure_converter.rb` (79 lines) — figure + image
- `bibliography_converter.rb` (59 lines) — bibitems

Main `adapter.rb` is now 168 lines (thin orchestrator). All autoloads declared in adapter.rb (parent namespace). Each converter receives its dependencies via constructor injection.
