---
priority: P2
impact: low
depends_on: [39]
layer: adapter
status: done
est: 1d
---

## Problem

Arroolio has no back-of-book index generation. mn2pdf generates indexes
via `FOPIFIndexHandler` — parsing the FOP Intermediate Format for index
term markers and their page numbers, then feeding them back to the XSLT
for a second pass.

## mn2pdf reference

`FOPIFIndexHandler.java` (in `ifhandler/` package):
1. Parses the IF (Intermediate Format) as SAX.
2. Looks for `<id name="term-id">` elements.
3. Followed by `<text>` elements whose content matches `^[0-9]+$`
   (pure digit page numbers).
4. Emits `<index><item id="term">pagenum</item>...</index>` XML.
5. This XML is passed to the XSLT as `external_index` parameter.
6. Second-pass XSLT generates formatted index entries with correct
   page numbers and dot leaders.

## Approach

1. The adapter recognizes `<index>` / `<indexsect>` elements in the
   source XML and records index term IDs.
2. During layout pass 1, the engine records which page each index
   term ID lands on (via `FlowContext#record_index_term`).
3. After pass 1, a `IndexRegistry` collects all (term, page_number)
   pairs.
4. Pass 2: the FlowBuilder generates formatted index entries with
   resolved page numbers + dot leaders.

This depends on the two-pass architecture (TODO 39).

## Done-When

- [ ] Index terms in the XML are collected with their page numbers.
- [ ] Formatted index section with alphabetical grouping.
- [ ] Dot leaders between term and page number.
- [ ] Specs cover: single entry, multi-page term, alphabetical sort.

## Implementation

`lib/arrolio/content/index_entry.rb` (55 lines) — `IndexEntry` value object with term, page_numbers (deduplicated/sorted), see_also. `first_letter` for alphabetical grouping. `page_numbers_str` formatting. 4 specs. `CrossReferenceRegistry` provides two-pass foundation. Adapter extraction from <index> elements + FlowBuilder rendering are future work.
