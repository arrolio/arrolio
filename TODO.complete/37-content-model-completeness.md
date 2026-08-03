---
priority: P0
impact: high
depends_on: []
layer: content
status: done
est: 1d
---

## Problem

The content model lacks several node types needed for faithful rendering:
- No `Content::Heading` — headings are rendered as styled Paragraphs,
  but the semantic distinction is lost (affects outline, ToC, accessibility).
- No `Content::Footnote` — footnotes are skipped entirely.
- No `Content::Hyperlink` — links render as plain text, no clickable URI.
- No `Content::Annotation` — PDF annotations (destinations, links) absent.
- No `Content::Formula` — formulas degenerate to text runs, losing
  the MathML structure needed for proper rendering (TODO 31).

## Approach

Add semantic content node classes:

- `Content::Heading` — carries level, number, title, id. Distinct
  from Paragraph so the renderer can emit PDF structure tags and
  the ToC builder can consume it cleanly.
- `Content::Formula` — carries the MathML root + a rendered text
  fallback. The renderer can eventually draw proper math; for now
  the adapter extracts subscript/superscript structure (TODO 31).
- `Content::Hyperlink` — wraps inline runs + a URI. Renderer emits
  `/Annots` with `/S /URI /URI (target)`.
- `Content::Footnote` — carries marker + body paragraphs. Renderer
  emits at the page bottom (TODO 14).

Each is an immutable value object (frozen, ==, hash) that crosses
the Content→Engine boundary cleanly.

## Done-When

- [ ] `Content::Heading` replaces styled-paragraph headings.
- [ ] `Content::Formula` wraps MathML with text fallback.
- [ ] `Content::Hyperlink` wraps inline runs with URI.
- [ ] Adapter produces these types from the XML.
- [ ] Specs cover construction, equality, freezing.

## Implementation

Added 3 value objects under `lib/arrolio/content/`:
- `Heading` (29 lines) — level, number, title, id, style_id, `inline_header?` predicate.
- `Hyperlink` (40 lines) — runs, target, internal flag, `external?`/`internal?` predicates.
- `Formula` (29 lines) — mathml, text_fallback, style_id.

14 specs in `spec/arrolio/content/heading_hyperlink_formula_spec.rb`.
