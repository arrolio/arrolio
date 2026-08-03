---
priority: P0
impact: high
depends_on: [52]
layer: adapter
status: done
est: 1d
---

## Problem

The "generic" adapter, flow builder, and pipeline still had Metanorma
standoc vocabulary hardcoded throughout:

- `fmt-title`, `fmt-name`, `fmt-stem`, `fmt-preferred`, `fmt-definition`,
  `fmt-termsource`, `biblio-tag`, `formattedref` — all element names
  baked into Ruby.
- The `depth` attribute name hardcoded.
- `zzSTDTitle` paragraph routing dropped silently.
- Figure display width hardcoded to 106pt.
- List bullet marker hardcoded to `■ `.
- ToC top offset hardcoded to 40pt.

These are Metanorma/OIML conventions. A flavor with a different
vocabulary (DITA, DocBook, JATS) would not work without modifying
core — violating OCP.

## Approach

1. **`adapter_rules.yml` selectors block**: declares every XML
   element/attribute name the adapter touches. 27 keys covering
   heading source, list items, table cells, bibliography tags, stem
   elements, image attributes, autonum classes, etc.
2. **`GenericAdapter#selectors`**: reads the block, falls back to
   `DEFAULT_SELECTORS` (clearly labelled as Metanorma standoc
   convention) for backward compatibility.
3. **`GenericFlowBuilder#default_marker`**: reads
   `flow_rules.yml[list.defaults.ordered_marker]` and
   `[bullet_marker]`.
4. **`GenericFlowBuilder#image_flowable`**: reads
   `flow_rules.yml[image.default_natural_width]`,
   `[default_natural_height]`, `[max_display_width]`.
5. **`ConfigDrivenPipeline#populate_toc`**: reads
   `flow_rules.yml[toc.top_offset]`.
6. **`scripts/xsl_to_config.rb`**: emits the `selectors` block in
   generated `adapter_rules.yml` from a `SELECTORS` constant.

## Done-When

- [x] No flavor literals (`oiml`, `zzSTDTitle`, `Arial`, `Jost`,
      `Times New Roman`) in `lib/arrolio/generic_*.rb`,
      `lib/arrolio/config_driven_pipeline.rb`,
      `lib/arrolio/asset_resolver.rb`, `lib/arrolio/toc_builder.rb`,
      `exe/arrolio2pdf`
- [x] No `fmt-*` references in `GenericAdapter` outside the clearly
      labelled `DEFAULT_SELECTORS` constant
- [x] Figure width, list markers, ToC offset all driven by config
- [x] OIML pipeline still renders (25 pages, ~218KB)
- [x] Sample fixture renders
- [x] All 232 specs pass

## Verification

- `grep -rn -i 'oiml\|zzSTDTitle\|"Arial"\|"Jost"' lib/arrolio/generic_*.rb
  lib/arrolio/config_driven_pipeline.rb lib/arrolio/asset_resolver.rb
  lib/arrolio/toc_builder.rb exe/arrolio2pdf` → empty
- `bundle exec rake` → green
- Real OIML render via `exe/arrolio2pdf` → 25-page PDF
