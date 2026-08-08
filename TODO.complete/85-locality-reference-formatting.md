---
priority: P2
impact: medium
depends_on: [82]
layer: adapter
status: pending
est: 1d
---

## Problem

Cross-references to clauses within the document render as raw locality
strings: `clause=5.1.1` instead of `clause 5.1.1` or `5.1.1`.

The raw text comes from the presentation XML's `<fmt-xref>` content.
The `=` is a locality separator that the XSL i18n templates replace
with a space and proper locality label.

## Example

Current output:
```
The exception described in clause=5.1.1 for an imprint of the software
identification is allowed.
```

Reference:
```
The exception described in clause 5.1.1 for an imprint of the software
identification is allowed.
```

## Approach

1. **Detect locality references in fmt-xref text.** When `<fmt-xref>`
   content matches `(\w+)=(.+)`, parse as locality + value.

2. **Apply i18n formatting.** Map locality keys to display labels:
   - `clause` → "clause"
   - `table` → "Table"
   - `figure` → "Figure"
   - `note` → "Note"
   - etc.

3. **Render as "locality value".** Join with a space: "clause 5.1.1".

4. **Handle multiple localities.** Some xrefs contain
   `clause=5.1.1;table=2` — semicolon-separated list.

## Done-When

- [ ] `clause=X` renders as "clause X"
- [ ] `table=X` renders as "Table X"
- [ ] Multiple localities render correctly
- [ ] Specs cover locality parsing edge cases

## Measurement

Affects ~15 cross-references in OIML r060/1 body text.
Last measured: 2026-08-08.
