---
priority: P1
phase: 19
depends_on: [22, 21]
layer: conformance
est: 3d
status: pending
---

## Problem

Modeled on `veraPDF/pdfa/validation/profiles/`, Arrolio needs a
generic **rule-based validation framework**. A rule is `(id,
applies_to, test_expression, severity, spec_reference)`. A profile
is a collection of rules. Validation runs every rule over the
document and produces `TestAssertion[]` (pass/fail per rule per
location).

Two consumers:

1. **Self-validation** (Phase 19 layout rules, TODO 63): did
   Arrolio itself produce a document free of layout regressions?
2. **Conformance validation** (TODO 64): does the rendered PDF meet
   PDF/A or PDF/UA spec requirements?

## Approach

Files under `lib/arrolio/conformance/`:

- `rule.rb` — frozen value object:
  ```ruby
  Rule = Struct.new(:id, :applies_to, :test, :severity,
                    :spec_reference, :tags, keyword_init: true)
  ```
  - `applies_to` — Symbol naming the target type
    (`:page`, `:flowable`, `:table`, `:image`, `:document`).
  - `test` — a `Proc` or DSL expression that returns `true`/`false`
    given the target + context.
  - `severity` — `:error`, `:warning`, `:info`.

- `profile.rb` — collection of rules + metadata (name, version,
  spec_link).

- `test_assertion.rb` — frozen value object:
  ```ruby
  TestAssertion = Struct.new(:rule_id, :location, :status,
                              :message, :evidence, keyword_init: true)
  ```
  - `status` — `:passed`, `:failed`, `:skipped`.
  - `location` — `Location` (reuses TODO 57 source locator).

- `validation_result.rb` — frozen value object:
  - `profile` — the Profile applied.
  - `assertions` — Array of TestAssertion.
  - `compliant?` — true if no `:error` severity failed.
  - `summary` — counts by status + severity.

- `validator.rb` — runs a Profile over an `Output::Page[]` (or a
  Pdfrb::Document):
  ```ruby
  class Arrolio::Conformance::Validator
    def initialize(profile)
    def validate(target) -> ValidationResult
  end
  ```

- `profile_registry.rb` — name → Profile lookup. Built-in profiles
  register at load.

- `profile_loader.rb` — loads profiles from YAML or Ruby DSL.

### YAML profile format

```yaml
name: oiml-render
version: 1.0.0
spec_reference: "OIML R-series style guide v3"
rules:
  - id: no-orphan-headings
    applies_to: flowable
    severity: error
    test: |
      target.kind == :heading && target.level <= 6 && !target.last_on_page?
  - id: page-count-positive
    applies_to: document
    severity: error
    test: "target.pages.length > 0"
  - id: every-page-has-footer
    applies_to: page
    severity: warning
    test: "target.region(:after).placed_boxes.any?"
```

The `test` expression is evaluated in a sandboxed context (no
`eval`, no `send`); it's a small expression language with comparison,
boolean, and method-call operators only.

## Done-When

- [ ] A profile with 1 trivial rule (page-count-positive) passes on
      a valid doc, fails on an empty doc.
- [ ] YAML loader produces equivalent Profile to Ruby DSL.
- [ ] `Validator.validate(output_pages)` returns a ValidationResult.
- [ ] `result.compliant?` is true iff no error-severity failures.
- [ ] Each failed TestAssertion carries a Location pointing at the
      offending page/box.
- [ ] Spec coverage for happy path + every severity + YAML loading.
