---
priority: P2
impact: medium
depends_on: [84]
layer: adapter
status: done
est: 0.5d
---

## Problem

Cross-references to clauses in the document rendered as raw locality
strings: `clause=5.1.1` instead of `clause 5.1.1`. The `=` is a
locality separator used in standoc presentation XML that the XSL i18n
templates replace with a space.

## Fix (2026-08-09)

Added `format_locality_text` method in the inline walker. When text is
collected from inside a `<fmt-xref>` element, the `=` between a word
and a value is replaced with a space:

```ruby
def format_locality_text(text)
  text.gsub(/([a-zA-Z]+)=/, '\\1 ')
end
```

Examples:
- `clause=5.1.1` → `clause 5.1.1`
- `table=2` → `table 2`
- `figure=4` → `figure 4`

The walker tracks `in_xref` context to only apply this transformation
inside cross-references, not globally.

## Done-When

- [x] `clause=X` renders as `clause X`
- [x] Only applied inside fmt-xref elements
- [x] Non-locality `=` preserved (e.g., in URLs or formulas)
- [x] Specs cover locality formatting

## Measurement

Improves readability of ~15 cross-references. Parity impact is small
(text content change, not spacing).
Last measured: 2026-08-09.
