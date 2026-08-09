---
priority: P1
impact: high
depends_on: [66]
layer: adapter
status: done
est: 1d
---

## Problem

The standoc presentation XML contains paired semantic + format
elements for cross-references, terms, and identifiers:

```xml
<xref target="X" id="id123">clause=5.1.1</xref>
<semx element="xref" source="id123">
  <fmt-xref target="X">clause=5.1.1</fmt-xref>
</semx>
```

Both the semantic `<xref>` and presentation `<fmt-xref>` carry the
same text. Our inline walker was collecting text from BOTH, producing
doubled output: `clause=5.1.1clause=5.1.1`.

## Fix (2026-08-08)

Added semantic elements to `skip_metadata_elements` in the standoc
profile:

```yaml
skip_metadata_elements:
  ...
  - xref
  - eref
  - identifier
```

The presentation equivalents (`fmt-xref`, `fmt-identifier`,
`fmt-preferred`) remain in `inline_styles` and provide the display
text.

## Remaining gaps

- [ ] **`clause=5.1.1` should render as "clause 5.1.1" or "5.1.1".**
      The `=` in the raw text is a locality separator. The XSL has
      i18n templates for locality rendering. Needs locality parsing
      in the inline walker.
- [ ] **Some fmt-* elements may also be doubled** when their semantic
      counterpart has no `id` attribute (can't match via `source`).
      Audit all element pairs.
- [ ] **`fmt-name` in skip_elements vs inline.** The block-level
      `convert_children` skips `fmt-name`, but the inline
      `collect_inline_runs` doesn't. Verify consistency.

## Done-When

- [x] No doubled xref/eref/identifier text in output
- [ ] Locality references render as "clause X.Y.Z" not "clause=X.Y.Z"
- [ ] All semantic/presentation pairs deduplicated

## Measurement

Parity improved from 50.52% → 53.53% after deduplication.
Last measured: 2026-08-08.
