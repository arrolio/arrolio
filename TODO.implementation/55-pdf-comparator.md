---
priority: P0
phase: 17
depends_on: [54]
layer: harness
est: 5d
status: pending
---

## Problem

Modeled on `Canon::Comparison`, Arrolio needs a semantic PDF
comparator: take two PDFs (ours vs FOP reference), produce a
`DiffReport` of `DiffNode`s classified by **dimension** (text,
font, position, colour, image, vector, structure) and by
**severity** (normative vs informative formatting drift).

This is the **primary** diff mode. Pixel diff (TODO 59) is one
optional input; RSpec matchers (TODO 58) and formatters (TODO 56)
consume the report.

## Approach

Inspired by `~/src/lutaml/canon/lib/canon/comparison/` — same shape,
different domain.

### Files under `lib/arrolio/harness/comparator/`

- `base_comparator.rb` — abstract: takes two `Pdfrb::Document`
  instances, produces `DiffReport`.
- `pdf_comparator.rb` — concrete comparator for PDF vs PDF.
- `dimension.rb` — base class for a diff dimension. Each subclass
  compares one aspect of two corresponding elements.
- `dimension_set.rb` — registry of active dimensions per profile.
- `dimensions/` — one file per dimension:
  - `text_content.rb` — string-equality on extracted text per
    PlacedBox.
  - `text_order.rb` — reading order across the page.
  - `font.rb` — font family, size, weight, colour.
  - `position.rb` — x/y/width/height within a page (with tolerance).
  - `colour.rb` — fill/stroke colour match.
  - `image_content.rb` — perceptual hash (pHash) for embedded images.
  - `vector_path.rb` — path-data comparison for line/curve shapes.
  - `structure.rb` — page count, region count, element nesting.
  - `metadata.rb` — `/Info`, `/Metadata` XMP.
- `classifier.rb` — marks each `DiffNode` as `:normative` (changes
  reader-visible meaning) or `:informative` (formatting drift within
  tolerance). Used by RSpec matchers to decide pass/fail.
- `match_options.rb` — per-dimension tolerances (e.g. position
  tolerance 0.5pt; phash hamming distance ≤ 5).
- `profile.rb` — presets:
  - `:strict` — zero tolerance, all dimensions active.
  - `:content_only` — text + structure only.
  - `:visual_equiv` — text + image + colour, ignore exact position.
  - `:oiml_regression` — OIML-tuned: position tolerance 1pt,
    font-metric exact, ignore running-header date.

### Algorithm

```
1. Parse both PDFs via Pdfrb.
2. Walk pages pairwise (different page counts → structural diff).
3. Per page, walk regions pairwise.
4. Per region, walk PlacedBoxes pairwise (matching by reading order).
5. For each pair, run every active dimension; collect DiffNodes.
6. Classifier labels each DiffNode.
7. Return DiffReport.
```

Pairing across pages/regions uses reading-order + position heuristics
(canonical: top-to-bottom, left-to-right). When pairing is ambiguous,
emit a `:structure` diff with both candidates.

### DiffReport

```ruby
class Arrolio::Harness::DiffReport
  attr_reader :differences, :profile, :stats

  def normative_diffs; differences.select(&:normative?); end
  def informative_diffs; differences.reject(&:normative?); end
  def equivalent?(profile); normative_diffs.empty?; end
  def similarity -> Float in [0, 1]
end
```

## Done-When

- [ ] Two identical PDFs produce `equivalent?(:strict) == true`.
- [ ] PDFs differing in one paragraph's text produce one
      `:text_content` DiffNode, classified normative.
- [ ] PDFs differing in font size by 0.1pt produce one `:font`
      DiffNode, classified informative (within default tolerance).
- [ ] PDFs with different page counts produce a `:structure` diff.
- [ ] Different embedded images produce `:image_content` diff with
      phash distance.
- [ ] Profile selection correctly activates/deactivates dimensions.
- [ ] Specs cover each dimension + classifier + at least 2 profiles.
