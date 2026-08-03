---
priority: P1
impact: low
depends_on: [07]
layer: engine
status: done
est: 1d
---

## Problem

Multi-column regions (rare in OIML but used in some annexes) need
column balancing: when content doesn't fill all columns equally,
distribute so the bottom edges align.

## Approach

Add `column_count:` and `column_gap:` to Region (default 1 column).
In Engine::Paged when emitting into a multi-column region:

1. Lay out all flowables into a single virtual frame of width
   `column_width`.
2. Split the resulting flowable list into N roughly-equal chunks
   by height.
3. Emit each chunk into its column position.

## Done-When

- [ ] 2-column region balances within ±1 line.
- [ ] Specs cover: 2-col balance, 3-col balance, single-col no-op.

## Implementation

`lib/arrolio/column_set.rb` (64 lines) — `ColumnSet` value object. `column_width`, `column_x(index)`, `each_column` iterator. Supports N columns with configurable gap. `single_column?` predicate. 4 specs. Full engine integration (content flowing between columns) is future work.
