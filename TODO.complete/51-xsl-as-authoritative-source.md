---
priority: P0
impact: high
depends_on: [50]
layer: architecture
status: done
est: 3d
---

## Problem

The OIML XSL stylesheet at
`~/src/mn/metanorma-taste/data/oiml/oiml.xsl` is the AUTHORITATIVE
reference for how OIML documents are rendered. The reference PDF at
`~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.pdf` is the
output of running this XSL through FOP (via mn2pdf).

Until now, Arroolio IMITATED the XSL behavior with hand-written Ruby.
The XSL must be the source of truth.

## Approach

`scripts/xsl_to_config.rb` parses the XSL ONCE (development time, not
runtime) and generates:

- `layout_spec.yml` — page geometry, attribute-set-derived styles
- `adapter_rules.yml` — element mapping with XSL match-pattern provenance
- `flow_rules.yml` — page sequences, cover content, ToC rules

Each generated file carries `generated_from: oiml.xsl` plus embedded
`xsl_variables`, `xsl_attribute_sets`, and `xsl_templates` blocks so a
reviewer can see what the XSL contributed. The runtime (GenericAdapter,
GenericFlowBuilder, ConfigDrivenPipeline) consumes the generated YAML
and never opens the XSL itself.

## What is XSL-derivable vs. not

| Concern | Derivable from this XSL? | Where it lives |
|---------|--------------------------|----------------|
| Page geometry (`marginTop`, `marginLeftRight1`) | yes | XSL variables |
| Per-style typography (font-family, font-size, color) | yes | attribute-sets |
| Conditional refinements (`refine_*` templates) | yes | XSL templates |
| Element → Content type mapping | no (semantic) | converter constants |
| Inline element styles | no (semantic) | converter constants |
| Cover content literals | no | converter constants |
| Page sequence structure | partially | generator + constants |

Items not encoded as data in the XSL (because they are downstream
concerns: the XSL emits formatting objects, Arroolio emits layout
nodes) are encoded as converter constants. They are clearly separated
from the XSL-derived sections.

## Done-When

- [x] `scripts/xsl_to_config.rb` parses the OIML XSL
- [x] Generates `layout_spec.yml` from XSL attribute-sets + variables
- [x] Generates `adapter_rules.yml` with XSL match patterns as provenance
- [x] Generates `flow_rules.yml` from XSL page-sequence + cover templates
- [x] Real OIML fixture renders via the XSL-generated config
- [x] Generic pipeline has zero OIML knowledge
- [x] OIML flavor = XSL + 3 generated YAML files (0 hand-written Ruby)

## Verification

- `bundle exec ruby scripts/xsl_to_config.rb <oiml.xsl> flavors/oiml`
  regenerates all three config files
- `spec/scripts/xsl_to_config_spec.rb` verifies the generation contract
- `bundle exec rake` is green
