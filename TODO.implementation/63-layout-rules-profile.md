---
priority: P1
phase: 19
depends_on: [62]
layer: conformance
est: 2d
status: pending
---

## Problem

A baseline ruleset for "did Arrolio itself produce a clean layout?"
This is the **render-time self-check**: catch Arrolio's own
regressions, not the source document's. Includes rules every
production publisher expects:

- No orphan headings (heading at very bottom of page).
- No widow/orphan lines (single line of paragraph alone on a page).
- Every page has the running header.
- Tables don't break mid-row.
- List items don't break mid-item.
- Footnote and reference on the same page.
- TOC entries resolve (no broken citations).
- Page numbering is contiguous.

These rules complement semantic-diff (TODO 55): diff catches
"output changed", layout-rules catch "output is wrong even if it
matches yesterday's output".

## Approach

File: `lib/arrolio/conformance/profiles/layout_rules.rb`.

```ruby
module Arrolio::Conformance::Profiles
  module LayoutRules
    def self.profile
      Arrolio::Conformance::Profile.new(
        name: "layout-baseline",
        version: "1.0.0",
        spec_reference: "Arrolio baseline layout expectations",
        rules: [
          # Headings
          Rule.new(id: "no-orphan-heading",
                   applies_to: :flowable,
                   severity: :warning,
                   test: ->(t, ctx) { !(t.heading? && t.last_on_page?) }),
          Rule.new(id: "heading-keep-with-next",
                   applies_to: :flowable,
                   severity: :error,
                   test: ->(t, ctx) { !t.heading? || t.kept_with_next? }),

          # Paragraphs
          Rule.new(id: "no-widow",
                   applies_to: :paragraph,
                   severity: :warning,
                   test: ->(t, ctx) { t.line_count > 1 || t.first_on_page? }),

          # Tables
          Rule.new(id: "table-no-mid-row-break",
                   applies_to: :table_row,
                   severity: :error,
                   test: ->(t, ctx) { !t.split_mid_row? }),

          # Pagination
          Rule.new(id: "page-numbering-contiguous",
                   applies_to: :document,
                   severity: :error,
                   test: ->(t, ctx) { t.page_numbers_contiguous? }),
          Rule.new(id: "every-page-has-footer",
                   applies_to: :page,
                   severity: :warning,
                   test: ->(t, ctx) { t.region(:after).placed_boxes.any? }),

          # Cross-references
          Rule.new(id: "citations-resolved",
                   applies_to: :field_run,
                   severity: :error,
                   test: ->(t, ctx) { !t.citation? || ctx.citation_for(t.ref_id) }),
        ]
      )
    end
  end
end
```

Plus an OIML-specific extension profile that adds rules particular
to OIML house style (e.g. "every clause has a number", "running
header shows current top-level section title").

### Engine integration

Engine emits an `Output::Page[]` with enough metadata for the rules
to evaluate: `heading?`, `last_on_page?`, `kept_with_next?`,
`line_count`, `first_on_page?`, `split_mid_row?`,
`page_numbers_contiguous?`, etc.

Run the layout-rules profile automatically after layout (configurable).
Failed `:error` rules raise `LayoutError`; `:warning` rules log.

## Done-When

- [ ] LayoutRules.profile has at least 8 rules covering the
      categories above.
- [ ] A document with an orphan heading fails `no-orphan-heading`.
- [ ] A document with a mid-row table break fails
      `table-no-mid-row-break`.
- [ ] A document with broken citations fails `citations-resolved`.
- [ ] Engine integration: rules run automatically unless disabled.
- [ ] OIML extension profile applies on top of baseline.
