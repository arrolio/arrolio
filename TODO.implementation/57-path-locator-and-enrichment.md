---
priority: P1
phase: 17
depends_on: [55]
layer: harness
est: 2d
status: pending
---

## Problem

Every `DiffNode` should carry a **canonical path** so users can
pinpoint exactly where the difference is. Modeled on canon's
`PathBuilder`, `SourceLocator`, `DiffNodeEnricher`, `DiffCharRange`,
`DiffLine`, `DiffContext`.

A canonical path looks like:
```
page[2].region[:body].flowable[3].line[1].run[0].text_content
```

Plus enrichment: each DiffNode should carry `serialized_before` /
`serialized_after` snippets, `line_range_before` / `line_range_after`
(line ranges in the source PDFs' content streams), and `char_ranges`
(character-level diff within a changed text run).

## Approach

Files under `lib/arrolio/harness/`:

- `path_builder.rb` — constructs canonical paths. Walks the DiffNode's
  source location chain (page → region → flowable → line → run →
  property) and builds the dotted path. Each segment includes an
  ordinal index for stable ordering.

- `source_locator.rb` — given a `Pdfrb::Model::Object` reference,
  returns its source location: `(page_number, oid, gen,
  content_stream_offset)`.

- `diff_node_enricher.rb` — post-processing pass over a `DiffNode[]`:
  1. Compute canonical path via `PathBuilder`.
  2. Serialize before/after content (text run, font dict, image
     stream).
  3. Compute line ranges in the source PDFs.
  4. For text differences, run `Diff::LCS` on character level →
     `DiffCharRange[]`.

- `diff_char_range.rb` — value object: `start_before`, `end_before`,
  `start_after`, `end_after`, `kind` (`:insert`, `:delete`,
  `:replace`). Used by PrettyFormatter to highlight just the changed
  characters within a run.

- `diff_line.rb`, `diff_block.rb`, `diff_context.rb` — line-level
  diff artifacts (same as canon's). Used by line-diff formatters.

- `diff_classifier.rb` — refines the basic normative/informative
  classification from TODO 55 with heuristics:
  - Position drift under 1pt → informative.
  - Font size drift under 0.1pt → informative.
  - Colour drift under ΔE 2.0 (perceptual) → informative.
  - Text content change of any kind → normative.
  - Image phash distance ≤ 5 → informative.

## Done-When

- [ ] Every DiffNode has a non-nil `path` after enrichment.
- [ ] Paths are stable across runs (same input → same paths).
- [ ] `serialized_before` / `serialized_after` are non-nil for text
      diffs; truncation is consistent (60 chars + ellipsis).
- [ ] Character ranges highlight exactly the changed characters in a
      text run.
- [ ] Classifier correctly labels a 0.05pt font size drift as
      informative.
- [ ] Specs cover path building, enrichment, classifier thresholds.
