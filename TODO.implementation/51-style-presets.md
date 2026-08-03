---
priority: P2
phase: 16
depends_on: [04]
layer: composer
est: 1d
status: pending
---

## Problem

Composer needs default LayoutSpecs that look professional without
requiring the user to specify everything. Built-in presets: technical
report, book, article, manual. Each preset is a LayoutSpec factory.

## Approach

File: `lib/arrolio/presets.rb` (namespace) + files under
`lib/arrolio/presets/`:

- `technical_report.rb` — A4, 25mm margins, single column, Times body,
  Helvetica headings, page number bottom-center, section title in
  header. Reads like an ISO/IEC standard.

- `book.rb` — Letter, 1in margins, single column with optional
  header, running header with chapter title, page number outside
  (left on even, right on odd). Two-page sequence (odd/even templates).

- `article.rb` — A4, 20mm margins, single column, no headers, simple
  footer. Compact.

- `manual.rb` — Letter, 0.75in margins, two-column body, sidebar
  notes. Uses multi-column (TODO 44).

Each preset is a `LayoutSpec.build { ... }` block, returned by
`Presets.load(:technical_report, page_size:, margins:)`.

## Done-When

- [ ] `Presets.load(:technical_report)` returns a valid LayoutSpec.
- [ ] Each preset has documented font + page geometry choices.
- [ ] Each preset renders a sample document end-to-end.
- [ ] Presets can be subclassed/extended.
- [ ] Specs cover loading + structure of each preset.
