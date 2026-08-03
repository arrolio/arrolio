---
priority: P2
phase: 19
depends_on: [62, 64]
layer: conformance
est: 3d
status: pending
---

## Problem

Modeled on `veraPDF/metadata/fixer/`, Arrolio needs an auto-fixer
that takes the failed assertions from a conformance profile and
applies known-safe fixes:

- Missing `/CreationDate` → fill in `Time.now`.
- Missing `/Producer` → `"Arrolio #{Arrolio::VERSION} + Pdfrb"`.
- Missing `/MarkInfo /true` → add (when StructTree exists).
- Missing `/Tabs /S` on pages → add.
- Missing font `/ToUnicode` → generate from font encoding (best effort).
- XMP packet missing → emit one from `/Info` fields.

The fixer is **opt-in**: it never modifies without being asked. It
also reports what it changed.

## Approach

Files under `lib/arrolio/conformance/fixer/`:

- `base_fixer.rb` — abstract; takes a `Pdfrb::Document` + a
  `ValidationResult`, returns a `FixResult`.

- `fix_result.rb` — value object: applied_fixes (`Array<AppliedFix>`),
  skipped_fixes (`Array<SkippedFix>`), unchanged.

- `applied_fix.rb` — value object: rule_id, fix_kind, before, after,
  location.

- Per-rule fixers (one file each, loaded only when the rule failed):
  - `creation_date_fixer.rb`
  - `producer_fixer.rb`
  - `mark_info_fixer.rb`
  - `tabs_fixer.rb`
  - `to_unicode_fixer.rb`
  - `xmp_packet_fixer.rb`

Each fixer is **conservative**: if it can't be sure the fix is
correct, it skips (records the reason) rather than guessing.

### Pipeline integration

```ruby
# After render:
doc = render_to_pdfrb_doc(content, layout_spec)
report = Arrolio::Conformance::Validator.(
  Arrolio::Conformance::Profiles::Pdfa1b.profile,
  doc
)
fixed_doc, fix_result = Arrolio::Conformance::Fixer.(doc, report)
fixed_doc.write(io: output_io)
```

`Fixer` is opt-in via a render option `fix_conformance: true`.

## Done-When

- [ ] A PDF missing `/Producer` gets it added.
- [ ] A PDF missing `/CreationDate` gets it added.
- [ ] A PDF missing `/MarkInfo /true` (but with StructTree) gets it
      added.
- [ ] Each applied fix is recorded with before/after evidence.
- [ ] Fixer skips fixes it's not sure about (no guessing).
- [ ] Round-trip: fixed PDF re-validated passes the rules it failed
      before.
- [ ] `render(fix_conformance: true)` flag wires it in.
