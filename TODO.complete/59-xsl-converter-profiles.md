---
priority: P2
impact: med
depends_on: [50, 51]
layer: architecture
status: done
est: 1d
---

## Problem

`scripts/xsl_to_config.rb` hardcoded constants that were not derivable
from the XSL but were OIML/Metanorma-specific:

- 6× `'oiml.xsl'` literal strings (claimed to be derived but were hardcoded)
- "Times New Roman Italic", "Times New Roman Bold" inline-style defaults
- "Jost SemiBold", "Jost", "Jost Light" cover-style defaults
- "Organisation Internationale de Métrologie Légale" + "International Organization of Legal Metrology" literals
- Standoc element vocabulary (`clause`, `p`, `fmt-title`, `biblio-tag`, ...)
- Hardcoded default XSL path pointing to OIML

Running the converter against an ISO/IEC/DITA XSL would have produced
YAML claiming OIML provenance with OIML font defaults — silently wrong.

## Approach

1. **Created `scripts/xsl_profiles/standoc.yml`** — the single file
   where Metanorma standoc vocabulary lives. Carries:
   - `element_mapping`, `inline_styles`, `span_class_styles`
   - `block_level_elements`, `skip_metadata_elements`, `skip_elements`
   - `selectors` (37 keys)
   - `metadata_fields` (XPath mapping)
   - `cover_fields`, `style_overrides`, `cover_content`
   - `header_template`

2. **Refactored `xsl_to_config.rb`** to read everything from the
   profile. The converter has ZERO hardcoded element names, font
   names, or OIML literals.

3. **`generated_from` and `stylesheet`** are now derived from the XSL
   filename via `File.basename(@xsl_path)`. A new `profile:` field
   records which profile was used.

4. **Profile is a constructor argument** with a sensible default
   (`scripts/xsl_profiles/standoc.yml`). A future DITA profile can be
   added without touching the converter.

5. **Removed the OIML-default XSL path** from the CLI. The script now
   requires explicit `<xsl-path> <output-dir> [profile-path]` args.

## Done-When

- [x] `scripts/xsl_profiles/standoc.yml` exists with the constants
- [x] Generator accepts `profile:` argument, defaults to standoc
- [x] No OIML-specific literals (`oiml`, `Times New Roman`, `Jost`,
      `Organisation Internationale`) in the generator
- [x] Generated YAML carries `generated_from: <actual-xsl-filename>`
      and `profile: standoc.yml`
- [x] Regenerating OIML config produces correct output
- [x] Real OIML fixture still renders 28 pages via the regenerated config
- [x] All specs pass

## Verification

- `grep 'oiml\|Times New Roman\|Jost' scripts/xsl_to_config.rb` → empty
- `head flavors/oiml/layout_spec.yml` shows
  `generated_from: oiml.xsl`, `profile: standoc.yml`
- `bundle exec rake` is green
- `bundle exec ruby exe/arrolio2pdf <fixture.xml> out.pdf flavors/oiml`
  produces a 28-page PDF

## Outcome

The converter is now truly generic. Adding a new vocabulary family
(DITA, DocBook, JATS) means adding `scripts/xsl_profiles/<family>.yml`
— no converter changes needed.
