---
priority: P2
impact: low
depends_on: [70, 79]
layer: adapter
status: in_progress
est: 1d
---

## Problem

Section number formatting and several inline-formatting details
differ from the reference.

## Status (2026-08-05)

- [x] **Section number "2.1" extracts as "2.1" not "21"** —
      delimiter included via `autonum-delim` + `caption-label`
      class match in `extract_from_heading`.
- [x] **`<sub>` produces baseline_shift=:sub, scale=0.7** —
      `baseline_for_style` in `collect_inline_runs` checks the
      inline_styles mapping; elements mapping to `:subscript` or
      `:superscript` set the baseline state carried through the
      walker.
- [x] **`<sup>` produces baseline_shift=:sup, scale=0.7** — same
      path as `<sub>`.
- [x] **Note labels have em-dash suffix** —
      `formatted_note_label(label)` appends the configured suffix
      (default "—") from `flow_rules.note.label_suffix`.

## Still pending

- [ ] **List bullet indent**: match the XSL's
      `provisional-distance-between-starts` for list labels.
- [ ] **Hyperlink underline**: extend `Style::Definition` with an
      `underline` boolean; renderer emits `/UL true` before
      drawing underlined runs.
- [ ] **`<strong>` weight via Bold variant**: the `:strong` style
      currently inherits the body font. Renderer should pick the
      Bold variant automatically based on style name (similar to
      how table headers do it in TODO 72).

## Done-When

- [x] Section number "2.1" extracts as "2.1" not "21"
- [x] Note labels have the em-dash suffix
- [x] `<sub>` / `<sup>` get baseline_shift + scale
- [ ] List bullet indent matches reference
- [ ] Hyperlinks render underlined
- [ ] `<strong>` uses the Bold font variant

## Expected improvement

Estimated 2-3% overall similarity once the remaining items land
(primarily from list indent matching and strong/bold rendering).
