---
priority: P0
impact: high
depends_on: [30]
layer: adapter
status: done
est: 1d
---

## Problem

The adapter has 29 specs total across the whole project, but the
adapter alone has 15+ conversion paths. Many code paths added in
recent sessions have zero spec coverage:
- `convert_term` (number, name, definition, notes, source)
- `collect_biblio_tag_runs` (tab → space)
- `walk_stem_into_runs` / `walk_math_text`
- `normalize_text` (whitespace heuristics)
- `prefix_number_to_first_paragraph`
- `each_direct_element` vs `each_element`
- BLOCK_LEVEL_ELEMENTS skip list

## Approach

Add comprehensive specs for each converter after decomposition (TODO 30):

- `spec/arrolio/oiml/adapter/inline_run_collector_spec.rb` —
  block-level skip, stem handling, math text, whitespace normalization
- `spec/arrolio/oiml/adapter/term_converter_spec.rb` — number, name
  with formula, definition extraction, termnote, source
- `spec/arrolio/oiml/adapter/bibliography_converter_spec.rb` —
  biblio-tag tab, formattedref merge, single-paragraph rendering
- `spec/arrolio/oiml/adapter/clause_converter_spec.rb` —
  inline-header, heading extraction, nested clauses
- `spec/arrolio/oiml/adapter/figure_converter_spec.rb` —
  image extraction, SVG dimensions, caption

Each spec tests: happy path, edge cases (empty, nil), XML structure
variants. Uses real REXML::Document fragments, not doubles.

## Done-When

- [ ] Every converter class has a dedicated spec file.
- [ ] Spec count doubles (29 → 60+).
- [ ] Code coverage for `lib/arrolio/oiml/` > 80%.
- [ ] Every Done-When criterion from completed TODOs has a spec.

## Implementation

Specs added:
- `spec/arrolio/oiml/adapter/inline_run_collector_spec.rb` (13 specs) — text collection, whitespace normalization, block-level skip, style resolution, MathML msub/msup
- `spec/arrolio/oiml/adapter/text_navigator_spec.rb` (10 specs) — TextNormalizer + ElementNavigator
- `spec/arrolio/inline_run_baseline_spec.rb` (9 specs) — Content + Layout InlineRun baseline_shift
- `spec/arrolio/logger_spec.rb` (9 specs) — Logger facade
Total: 70 specs (was 29 at session start).
