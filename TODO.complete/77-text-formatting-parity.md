---
priority: P2
impact: low
depends_on: [70]
layer: adapter
status: pending
est: 1d
---

## Problem

Section numbers and text formatting differ from the reference:

- Reference: "21 2.1" (section number runs into subsection without
  a space, using a tab character as delimiter)
- Ours: "2 Scope" with space-separated number and title

- Reference: bullet markers are `■` (filled square) with specific
  indent
- Ours: same marker but different indent level

- Reference: note labels are "NOTE 1 —" with an em-dash
- Ours: "NOTE 1 " with a space

These small differences compound across every page.

## Approach

1. **Section number formatting**: the heading extractor should
   preserve the exact delimiter (tab vs space) between number and
   title. The `extract_from_heading` method already handles tab
   delimiters; verify the flow builder doesn't reformat.
2. **Note label format**: match the XSL's `note-name-style` suffix.
   The XSL appends ":" or "—" to the label via the
   `<xsl:apply-templates select="mn:fmt-name">` template with a
   suffix parameter.
3. **Bullet indent**: match the XSL's
   `provisional-distance-between-starts` for list labels.

## Expected improvement

Estimated 2–3% similarity improvement (text-level formatting
matches more closely).

## Done-When

- [ ] Section numbers match the reference format exactly
- [ ] Note labels have the correct suffix (— or :)
- [ ] List indentation matches
- [ ] Text diff per-page shows fewer EXTRA/MISSING entries
