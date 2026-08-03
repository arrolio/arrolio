---
priority: P1
impact: high
depends_on: [50, 52, 63]
layer: architecture
status: done
est: 1d
---

## Problem

The generic adapter still hardcoded Metanorma standoc vocabulary
throughout (`preface`, `bibliography`, `references`, `bibitem`,
`clause`, `foreword`, `title`, `span`, `tab`, `br`). A flavor with a
different vocabulary (DITA, DocBook, JATS) would not work without
modifying core — violating OCP.

## Approach

1. **Extended `selectors` block** in `adapter_rules.yml`: added keys
   for `preface_container`, `preface_children`, `bibliography_container`,
   `bibliography_reference`, `bibliography_item`, `fallback_title`,
   `span`, `tab_inline`, `break_inline`.
2. **`GenericAdapter` reads selectors** for every element it touches —
   no hardcoded element names outside the clearly-labelled
   `DEFAULT_SELECTORS` constant.
3. **`DEFAULT_SELECTORS` documents the standoc convention** as a
   fallback so flavors that omit selectors still work, but every
   real flavor (OIML + sample fixture) declares its full selector set.
4. **`scripts/xsl_to_config.rb`** emits the full `selectors` block
   (27 keys) in generated `adapter_rules.yml`.
5. **Bug fix**: `extract_bibliography` had referenced `preface_elem`
   in the bibliography scope — fixed to `biblio_elem`.
6. **Strict typing in constructor**: `Content::Document.new` now
   validates that `sections`, `preface`, and `bibliography` arrays
   contain only `Content::Section` instances, raising `ContentError`
   at the construction site rather than deep in the pipeline.

## Done-When

- [x] `GenericAdapter` has no Metanorma element names outside
      `DEFAULT_SELECTORS`
- [x] `DEFAULT_SELECTORS` includes the 9 new document-structure keys
- [x] OCP grep spec enforces no `fmt-*`, no flavor literals, no OIML
      references in the generic core
- [x] Non-Metanorma vocabulary spec proves the adapter parses
      custom XML using only selectors
- [x] `Content::Document` constructor validates Section typing
- [x] Real OIML pipeline still renders 28 pages via the generic
      pipeline

## Verification

- `spec/arrolio/ocp_grep_spec.rb` — 5 OCP guard specs
- `bundle exec rake` is green (244 examples)
- OIML render: 28 pages, ~258 KB
