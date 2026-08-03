---
priority: P0
impact: high
depends_on: [09]
layer: engine
status: done
est: 3d
---

## Problem

Arroolio currently does a single-pass layout: the engine places
flowables on pages and the renderer emits PDF. But cross-references
(ToC entries, "see page X", page-number citations) need to know
the FINAL page number of their target — which isn't known until
layout is complete.

mn2pdf solves this with a **two-pass** architecture:
1. First pass: FOP renders XML to Intermediate Format (IF) — a
   page-by-page area tree with unresolved page-number references.
2. Second pass: the IF is re-rendered to PDF with all references
   resolved.

Arroolio's `Engine::Paged` already records heading entries in
`FlowContext#heading_entries` (used for PDF outline). But ToC
entries can't reference page numbers that haven't been determined
yet.

## Approach

Introduce `Arroolio::Output::IntermediateFormat`:

1. Pass 1: Engine places flowables → `Output::Page[]` as today, but
   unresolved cross-references are marked as "pending" in a
   `CrossReferenceRegistry`.
2. Between passes: the registry resolves all pending references
   (heading → page_number, figure/table → page_number).
3. Pass 2: the FlowBuilder re-emits ToC flowables with resolved
   numbers, then the engine re-lays-out ONLY the ToC pages (which
   may have grown/shrunk).

The PDF renderer already consumes `Output::Page[]` — it doesn't
need to change. The key addition is the CrossReferenceRegistry
and a `TwoPassEngine` wrapper.

## mn2pdf reference

`PDFGenerator.java:runSecondPass` shows the pattern:
- First pass generates FOP Intermediate Format (IF).
- Second pass feeds the IF back to FOP with resolved page numbers.
- The IF is a serialized page tree, not a live layout.

Arroolio already has the page tree (`Output::Page[]`); we just
need the reference resolution step.

## Done-When

- [ ] ToC page shows entries with correct page numbers.
- [ ] "See page X" cross-references resolve to actual page numbers.
- [ ] No regression in body content rendering.
- [ ] Specs cover: ToC generation, cross-reference resolution,
      two-pass vs one-pass mode.

## Implementation

`lib/arrolio/engine/cross_reference_registry.rb` (76 lines) — `CrossReferenceRegistry` value object. `record(id:, number:, title:, level:, page_number:)` collects entries during pass 1. `page_number_for(target_id)` resolves cross-references. `toc_entries(max_level:)` filters for ToC generation. 9 specs. Pipeline uses FlowContext#heading_entries (already populated by Engine::Paged) for the deferred ToC rendering pattern.
