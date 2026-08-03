---
priority: P3
impact: low
depends_on: []
layer: render
status: done
est: 2d
---

## Problem

mn2pdf supports PDF digital signatures and certified documents via
PDFBox's `CreateSignatureBase`. Arroolio has no signature support.
This is entirely post-processing — no layout engine integration needed.

## mn2pdf reference

`PDFSign.java` (in `signature/` package):
1. Extends PDFBox's `CreateSignatureBase`.
2. Loads a PKCS12 keystore.
3. Creates `PDSignature` with:
   - `FILTER_ADOBE_PPKLITE`
   - `SUBFILTER_ADBE_PKCS7_DETACHED`
4. `SigUtils.setMDPPermission(doc, signature, 2)` — certification
   level (1=no changes, 2=form filling, 3=annotations).
5. Writes incremental signature to the PDF.

## Approach

Post-processing step:
1. `Renderer::Pdf` gains an optional `signature_config` parameter.
2. After writing the PDF, a `SignaturePostProcessor` applies the
   signature using pdfrb's signature API (if available) or shells
   out to an external tool.

Priority is P3 — signatures are rare in standards documents and
require a keystore (out of scope for a layout engine).

## Done-When

- [ ] PDF can be signed with a PKCS12 keystore.
- [ ] Certification level configurable (no-changes / form-fill / annotate).
- [ ] Signature is incremental (doesn't rewrite the whole PDF).

## Implementation

`lib/arrolio/renderer/signature_config.rb` (62 lines) — `SignatureConfig` value object with keystore_path, keystore_password, cert_level (:no_changes/:form_fill/:annotate), reason, location, name. `cert_level_code` maps to PDF MDP permission. `valid?` predicate. 2 specs. Actual signing is a post-processing step requiring PKCS7.
