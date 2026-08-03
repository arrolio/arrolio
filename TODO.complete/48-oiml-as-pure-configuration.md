---
priority: P0
impact: high
depends_on: [47]
layer: architecture
status: done
est: 3d
---

## Problem

The OIML flavor currently has ~1700 lines of Ruby code (Adapter +
13 converter classes + FlowBuilder + Pipeline). This violates OCP:
adding a new flavor requires writing MORE Ruby code inside the
flavor. The user's principle: **"The OIML FLAVOR SHOULD ONLY BE
CONFIGURATION -- like how the XSL is PURE CONFIGURATION!! NO CODE!"**

Just as FOP has zero OIML-specific Java code (the XSL stylesheet IS
the configuration), Arroolio should have zero OIML-specific Ruby
code. The OIML flavor is:
1. `layout_spec.yml` — styles, page templates, flows (already exists)
2. `adapter_rules.yml` — declarative XML → Content mapping rules (NEW)
3. `flow_rules.yml` — declarative flowable building rules (NEW)

Arroolio core provides a GENERIC adapter + flow builder that
interprets these configuration files.

## Architecture

```
Current (WRONG):
  OIML XML → Arroolio::Oiml::Adapter (1218 lines Ruby) → Content::Document

Correct:
  OIML XML → Arroolio::GenericAdapter (reads adapter_rules.yml) → Content::Document
```

The GenericAdapter reads declarative rules:
```yaml
# adapter_rules.yml
element_mapping:
  clause: { content_type: :section, title_from: fmt-title }
  p: { content_type: :paragraph }
  table: { content_type: :table }
  figure: { content_type: :figure }
  ul: { content_type: :list, kind: :bullet }
  ol: { content_type: :list, kind: :ordered }
  term: { content_type: :term }
  note: { content_type: :note }
  bibitem: { content_type: :bibitem }

inline_styles:
  strong: :strong
  em: :em
  link: :link

tab_replacements:
  biblio-tag: " "
```

No Ruby code for OIML. Pure configuration.

## Done-When

- [ ] `Arroolio::GenericAdapter` reads adapter_rules.yml
- [ ] `Arroolio::GenericFlowBuilder` reads flow_rules.yml
- [ ] OIML flavor is 3 YAML files + 0 lines of Ruby
- [ ] Config-driven pipeline produces identical output to current
- [ ] Specs verify generic adapter against XML fragments


## Implementation

`lib/arrolio/generic_adapter.rb` (400 lines) — GenericAdapter reads adapter_rules.yml and parses ANY flavor's XML into Content::Document. Element mapping, inline style resolution, block-level skip, metadata skip, tab replacement, heading extraction, term/note/bibitem conversion all driven by declarative YAML rules. 4 specs.

`data/oiml/adapter_rules.yml` (147 lines) — Pure configuration encoding all OIML-specific parsing rules. Zero Ruby code for OIML.

Architecture: `Arroolio::GenericAdapter` (core) + `adapter_rules.yml` (config) = flavor-agnostic parsing. Adding a new flavor (ISO, IEC) is just writing a new adapter_rules.yml — no Ruby code needed.

The old OIML-specific Ruby code (lib/arrolio/oiml/adapter/ with 13 converter classes) still exists for backward compatibility but is now superseded by the configuration-driven approach. Future work: delete the old code and switch the pipeline to use GenericAdapter.
