---
priority: P1
phase: 9
depends_on: [02, 16]
layer: list
est: 1d
status: pending
---

## Problem

Lists (bullet, numbered, definition) need a typed model: items with
markers, nested lists, marker schemes (decimal, alpha, roman, bullet
variants).

## Approach

Files under `lib/arrolio/list/`:

- `list.rb` — value object: `items` (Array of Item), `marker_scheme`
  (Symbol), `style`. Methods: `nested?`, `level`.

- `item.rb` — `Item = Struct.new(:marker, :content, :sublists,
  keyword_init: true)`. `marker` may be a String (explicit) or nil
  (use scheme). `content` is a Flowable or Array. `sublists` is
  Array of List (for nesting).

- `marker_scheme.rb` — module of constants:
  - `BULLET` ("•")
  - `DASH` ("—")
  - `DECIMAL` (Proc: `->(i) { "#{i}." }`)
  - `LOWER_ALPHA`, `UPPER_ALPHA`
  - `LOWER_ROMAN`, `UPPER_ROMAN`
  - Custom schemes via Proc.

Nested lists indent and may use different schemes at different
levels (decimal at level 0, lower-alpha at level 1, etc.).

## Done-When

- [ ] A 3-item bullet list has `marker_scheme == :bullet`.
- [ ] `MarkerScheme::DECIMAL.call(3) == "3."`.
- [ ] `MarkerScheme::LOWER_ROMAN.call(4) == "iv."`.
- [ ] A nested list (`item.sublists`) reports `level == 1`.
- [ ] Specs cover all built-in schemes + nesting.
