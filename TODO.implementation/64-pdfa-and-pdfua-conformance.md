---
priority: P2
phase: 19
depends_on: [62, 48]
layer: conformance
est: 5d
status: pending
---

## Problem

veraPDF ships rule profiles for ISO 19005 (PDF/A) and ISO 14289
(PDF/UA). Arrolio should be able to validate its own output against
these standards — without requiring veraPDF itself.

This is a pragmatic subset, not full veraPDF parity. Goal: catch
the common 80% of conformance failures before users hit them, then
let veraPDF do the authoritative check.

## Approach

Files under `lib/arrolio/conformance/profiles/`:

- `pdfa_1b.rb` — PDF/A-1b baseline rules:
  - `/MarkInfo` not required (Level B).
  - All fonts embedded (no standard-14 references).
  - No unembedded JPG2000 in /JBIG2Decode without /DecodeParms.
  - No JavaScript actions.
  - No encrypted streams.
  - `/ColorSpace` does not reference /DeviceN or /DevRGB without ICC.

- `pdfa_2b.rb` — PDF/A-2b additions:
  - JPEG2000 allowed (with restrictions).
  - Transparency allowed (with restrictions).
  - Object-level XMP metadata.

- `pdfua_1.rb` — PDF/UA-1 rules:
  - `/MarkInfo /true` on Catalog.
  - `/StructTreeRoot` present.
  - Every page has `/Tabs /S` (structured reading order).
  - Every image has `/Alt` text.
  - Every heading maps to the right `<Hn>` element.
  - No nested marked-content sequences beyond depth limit.
  - Font has `/ToUnicode` CMap (text extractable).

- `pdfua_2.rb` — PDF/UA-2 (when standard is final).

Each profile is a Ruby module with `.profile` returning a
`Conformance::Profile`. Rules are written in the same DSL as TODO 63.

### veraPDF cross-validation

- A spec under `spec/conformance/veraPDF_cross_check_spec.rb` runs
  both Arrolio's profiles and veraPDF (via shell) on the same
  fixture PDFs; expected disagreements are catalogued.
- Rake task `rake conformance:cross_check` runs the suite.

## Approach for partial-coverage

Be honest in the docs: "Arrolio catches N% of PDF/A-1b rules.
Run veraPDF for authoritative validation." List the rules NOT
implemented so users know what's missing.

## Done-When

- [ ] `pdfa_1b` profile covers ≥ 30 of the most common rules.
- [ ] `pdfua_1` profile covers ≥ 20 of the most common rules.
- [ ] An Arrolio-rendered PDF (without fonts embedded) fails
      `pdfa_1b` with a useful error.
- [ ] An Arrolio-rendered PDF (without StructTree) fails
      `pdfua_1`.
- [ ] veraPDF cross-check spec runs (when veraPDF is installed) and
      documents the disagreements.
- [ ] README documents the partial-coverage scope clearly.
