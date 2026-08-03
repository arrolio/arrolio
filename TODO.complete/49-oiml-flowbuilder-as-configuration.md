---
priority: P0
impact: high
depends_on: [48]
layer: engine
status: done
est: 2d
---

## Problem

OIML still has ~1700 lines of Ruby code in `lib/arrolio/oiml/`:
- `flow_builder.rb` (~280 lines) — builds flowables from Content
- `pipeline.rb` (~80 lines) — orchestrates the OIML pipeline
- `adapter/` (1218 lines) — 13 converter classes

The user's principle: "OIML FLAVOR SHOULD ONLY BE CONFIGURATION".
The adapter is now configuration-driven (TODO 48). The flow builder
and pipeline also need to be configuration-driven.

## Approach

1. **`data/oiml/flow_rules.yml`** (87 lines) — pure configuration for
   building flowables. Replaces `flow_builder.rb` logic.
2. **`Arroolio::GenericFlowBuilder`** — reads flow_rules.yml, builds
   flowables for any flavor.
3. **`Arroolio::ConfigDrivenPipeline`** — uses GenericAdapter +
   GenericFlowBuilder + LayoutSpec. No flavor-specific code.
4. **Delete** `lib/arrolio/oiml/flow_builder.rb` and `pipeline.rb`.
5. The old `lib/arrolio/oiml/adapter/` is now superseded by the
   GenericAdapter + adapter_rules.yml.

## Done-When

- [x] `data/oiml/flow_rules.yml` captures cover + page sequence rules
- [x] `Arroolio::GenericFlowBuilder` reads flow_rules
- [x] `Arroolio::ConfigDrivenPipeline` uses GenericAdapter + GenericFlowBuilder
- [x] OIML flavor has zero Ruby code (3 YAML files only)
- [x] Specs verify the config-driven pipeline
