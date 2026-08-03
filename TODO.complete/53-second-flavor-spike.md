---
priority: P0
impact: high
depends_on: [52]
layer: architecture
status: done
est: 2d
---

## Problem

The generic pipeline handled only one real flavor (OIML). Without a
second flavor implemented using only XSL + 3 generated YAML files, the
"any flavor is pure configuration" claim was unverified.

## Approach

Created a synthetic second flavor at
`spec/fixtures/flavors/altvocab/` with a deliberately non-Metanorma
vocabulary:

| Role | sample (standoc) | altvocab |
|------|------------------|----------|
| Container | `metanorma` | `article` |
| Metadata | `bibdata` | `meta` |
| Sections container | `sections` | `body` |
| Section | `clause` | `sec` |
| Heading | `fmt-title` (depth) | `h2` (level) |
| Paragraph | `p` | `para` |
| List item | `li` | `li` (same) |
| Marker | `fmt-name` | `marker` |
| Note label | `fmt-name` | `label` |
| Figure image | `image` | `img` |
| Figure caption | `fmt-name` | `caption` |
| Table row/cell | `tr`/`td,th` | `row`/`cell,header` |
| Bibliography | `bibliography` | `refs` |
| References | `references` | `list` |
| Item | `bibitem` | `entry` |
| Inline strong | `strong` | `b` |
| Inline italic | `em` | `i` |
| Stem | `stem`/`fmt-stem` | `math`/`mathfmt` |

This is a genuinely different vocabulary — not just renamed standoc.
The fact that the generic adapter parses it correctly proves there is
no hidden Metanorma dependency.

The flavor is rendered through the same `ConfigDrivenPipeline` with
zero core code changes. All element selectors come from the flavor's
`adapter_rules.yml`. All flow rules come from its `flow_rules.yml`.
All styles come from its `layout_spec.yml`. It declares its own
`manifest.yml`.

## Done-When

- [x] Second flavor directory exists at `spec/fixtures/flavors/altvocab/`
- [x] Uses a deliberately non-Metanorma vocabulary (article/sec/para/h2)
- [x] Renders a fixture via the generic pipeline with zero core changes
- [x] All selectors come from `adapter_rules.yml`
- [x] Manifest is loadable via `Flavor::Manifest.load`
- [x] Specs verify parse correctness + PDF render + manifest exposure
- [x] All 267+ specs still pass

## Verification

- `spec/arrolio/second_flavor_spike_spec.rb` (3 specs)
- `bundle exec rake` is green
- `bundle exec ruby exe/arrolio2pdf <fixture.xml> out.pdf spec/fixtures/flavors/altvocab`

## Outcome

The generic design is now proven across two distinct vocabularies
(Metanorma standoc + synthetic altvocab). Adding a third real-world
flavor (ISO, IEC, BSI, DITA, DocBook) is a configuration exercise, not
a code change.
