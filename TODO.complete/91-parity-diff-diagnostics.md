---
priority: P1
impact: high
depends_on: [80]
layer: harness
status: in_progress
est: 1d
---

## Problem

The parity check reports overall similarity but doesn't show
per-element breakdowns. When a page has low similarity, we can't tell
if the issue is spacing, text content, image absence, or table layout.

## Current state

- `rake parity:check` renders and diffs — SHIPPED
- Per-page similarity: SHIPPED
- Per-element diff: NOT implemented

## Approach

1. **Visual diff overlay.** Generate a side-by-side PNG comparison
   of each page (reference vs ours) with differences highlighted.

2. **Text diff per page.** Extract text from both PDFs per page and
   show unified diff (added/removed lines).

3. **Element classification.** Tag each difference:
   - `spacing` — same text, different position
   - `content` — different text
   - `missing` — element in reference but not in ours
   - `extra` — element in ours but not in reference

4. **Parity leaderboard.** Track parity % per commit so we can see
   which changes helped or hurt.

## Done-When

- [ ] `rake parity:diff PAGE=5` shows detailed diff for page 5
- [ ] Visual overlay PNGs generated to `tmp/parity_overlays/`
- [ ] Text diff shows exact added/removed words
- [ ] Element classification helps identify root cause
- [ ] CI reports parity delta on each PR

## Measurement

Critical for iterating on parity. Without this, fixes are guesswork.
Last measured: 2026-08-08.
