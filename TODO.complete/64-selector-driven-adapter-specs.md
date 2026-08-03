---
priority: P0
impact: high
depends_on: [63]
layer: test
status: done
est: 1d
---

## Problem

After extracting Metanorma vocabulary into the `selectors` block, there
was no spec verifying that the generic adapter actually consults the
selectors (vs. silently falling back to hardcoded defaults). A future
edit could re-introduce a hardcoded element name and no test would
catch it.

## Approach

1. **Custom-selector spec**: build a synthetic flavor whose
   `adapter_rules.yml` uses NON-Metanorma element names
   (`sec` instead of `clause`, `para` instead of `p`, `tbl` instead
   of `table`, etc.) and verify the adapter parses a matching XML
   document correctly. This proves the adapter has no hardcoded
   dependency on the Metanorma vocabulary.
2. **Grep-enforced OCP spec**: assert no flavor literals appear in the
   generic core. This is a structural test that fails loudly if someone
   re-introduces `fmt-title`, `oiml`, etc. into the wrong file.
3. **Fixture path coverage**: both the sample fixture (Metanorma-style)
   and the synthetic non-Metanorma fixture pass through the same
   generic pipeline.

## Done-When

- [x] Spec renders a non-Metanorma vocabulary through the generic adapter
- [x] Spec asserts no flavor literals in `lib/arrolio/generic_*.rb`,
      `lib/arrolio/config_driven_pipeline.rb`,
      `lib/arrolio/asset_resolver.rb`, `lib/arrolio/toc_builder.rb`,
      `exe/arrolio2pdf`
- [x] All specs pass

## Why

A refactor that "extracts hardcoded values" without a test enforcing
the extraction is just a suggestion. The grep-enforced OCP spec is the
permanent guardrail — any future regression fails CI immediately.
