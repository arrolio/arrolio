---
priority: P1
impact: high
depends_on: [50, 52]
layer: architecture
status: done
est: 1d
---

## Problem

There was no documented convention for how third parties should package,
install, and distribute Arroolio flavors. Without one, "flavors are
external" is an aspiration, not a deliverable.

## Approach

1. **Wrote `flavors/PACKAGING.md`**: the canonical guide describing
   the anatomy of a flavor gem, the selector/layout_spec/flow_rules
   contracts, the `Flavor::Registry` opt-in registration, the
   `xsl_to_config.rb` workflow, and a verification checklist.
2. **Documented the selector contract**: every XML element/attribute
   name the generic adapter touches is named in
   `adapter_rules.yml`'s `selectors:` block (36 keys). A flavor with a
   non-Metanorma vocabulary overrides these.
3. **Documented the layout_spec contract**: `header_footer:` and
   `cover_logo:` blocks drive the renderer; `page_templates:`,
   `styles:`, `flows:` drive the engine.
4. **Documented the flow_rules contract**: `page_sequences:[]`,
   `cover_content:[]`, `section:`, `content_to_flowable:`, `toc:`.

## Done-When

- [x] `flavors/PACKAGING.md` exists with the full packaging contract
- [x] Selector contract documented (every key explained)
- [x] Layout_spec contract documented (every block explained)
- [x] Flow_rules contract documented (every block explained)
- [x] Registration-via-Registry pattern documented
- [x] Verification checklist for flavor encapsulation

## Verification

- `flavors/PACKAGING.md` is the single source of truth for flavor
  authors
- The gem itself ships zero flavor artifacts (gemspec excludes
  `flavors/`)
- The gem's own specs run without any real flavor installed
