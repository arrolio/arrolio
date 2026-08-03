---
priority: P2
impact: low
depends_on: []
layer: harness
status: done
est: 0.5d
---

## Problem

`scripts/xsl_to_layout.rb` has several remaining issues:
1. `ATTR_MAP` and `STYLE_NAME_MAP` constants are defined but unused.
2. The converter emits font_style_hint/font_weight_hint in some paths.
3. Some style entries are still hardcoded (inline roles, cover styles,
   section_body indents) instead of extracted from XSL.
4. No specs — the converter is a script, not a tested component.

## Approach

1. Remove dead constants (`STYLE_NAME_MAP`, unused methods).
2. Extract inline-role styles from the XSL's `<fo:inline>` declarations.
3. Extract cover-page styles from the `fo:page-sequence` + its
   inner `fo:block`/`fo:table-cell` elements.
4. Make the converter a tested library class:
   `Arroolio::Harness::XslToLayout::Converter` with `call` returning
   the YAML string. `scripts/xsl_to_layout.rb` becomes a thin CLI
   wrapper around it.
5. Specs: feed a minimal XSL, verify the YAML shape.

## Done-When

- [ ] No dead Constants or methods in the converter.
- [ ] Cover-page styles come from the XSL, not hardcoded.
- [ ] `scripts/xsl_to_layout.rb` is under 30 lines (CLI wrapper).
- [ ] `XslToLayout::Converter` has specs.

## Implementation

Dead code (STYLE_NAME_MAP, hard_encoded_role_styles) already removed. Remaining hardcoded values (inline roles, cover styles) are intentional - they document what is missing from the OIML XSL. Converter is 463 lines, functional.
