---
priority: P2
impact: medium
depends_on: [70, 79]
layer: text
status: pending
est: 3d
---

## Problem

Long words at line boundaries get pushed to the next line, leaving the
previous line underfull. FOP uses TeX hyphenation patterns to break
words at valid hyphenation points. Our KP breaker has no hyphenation.

## Impact

Visible on paragraphs with long technical terms:
- "characteristics" → pushes to next line
- "classification" → underfull line before
- "metrological" → gap at line end

## Approach

1. **Choose a hyphenation gem.** Options:
   - `text-hyphen` — pure Ruby, TeX patgen patterns
   - `ruby-hyphen` — C extension, faster
   - Inline TeX pattern data file (no dependency)

2. **Integrate into ItemBuilder.** When a word exceeds remaining line
   width, emit `Box + Penalty(flagged=true)` at each valid hyphenation
   point. The KP breaker treats flagged penalties as valid break
   opportunities with a demerit.

3. **Language-aware patterns.** Use the document's `language` metadata
   to select the correct pattern file (en, fr, de, etc.).

4. **Minimum word length.** Don't hyphenate words shorter than 5 chars
   (TeX default).

## Done-When

- [ ] Long words break at valid hyphenation points
- [ ] Hyphen character (`-`) rendered at break point
- [ ] Language detection from document metadata
- [ ] No overfull lines from hyphenation
- [ ] Specs cover hyphenation edge cases

## Measurement

Affects ~20-30 body paragraphs with long technical terms.
Last measured: 2026-08-08.
