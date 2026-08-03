---
priority: P1
impact: low
depends_on: []
layer: flowable
status: done
est: 1d
---

## Problem

`<pre>`, `<source>`, source-highlighted code blocks render as body
text. Reference uses a monospace font (Courier/Liberation Mono)
with no reflow.

## Approach

File: `lib/arrolio/flowables/preformatted_flowable.rb`

Honour newlines literally — break only on `\n`, never on width.
Render in `:monospace` style. Optional: source highlighting via
Rouge (CSS classes mapped to colors in style registry).

## Done-When

- [ ] Code blocks preserve line breaks and indentation.
- [ ] Specs cover: line preservation, no wrap, monospace style.

## Implementation

`lib/arrolio/content/preformatted.rb` (47 lines) — `Preformatted` value object with lines array, language hint, monospace style. Adapter recognizes <pre>, <sourcecode>, <blockquote>. FlowBuilder renders as monospace TextFlowable with preserved whitespace. 8 specs.
