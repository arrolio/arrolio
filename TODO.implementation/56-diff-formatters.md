---
priority: P0
phase: 17
depends_on: [55]
layer: harness
est: 3d
status: pending
---

## Problem

`DiffReport` is data; users need it rendered. Different audiences
need different views:

- **CI / regression test**: machine-readable JSON + pass/fail summary.
- **Developer local**: pretty terminal output with colour and context.
- **Designer review**: HTML report with side-by-side pages and
  highlighted diff regions (paired with pixel-diff images from
  TODO 59 when available).
- **Audit log**: by-element dump with canonical paths.

Modeled on `Canon::DiffFormatter::*` (by_line, by_object,
pretty_diff_formatter, diff_detail_formatter).

## Approach

Files under `lib/arrolio/harness/formatters/`:

- `base_formatter.rb` — abstract: takes `DiffReport`, returns String
  (or writes to IO).

- `summary_formatter.rb` — one-line pass/fail + similarity %.
  Example: `✓ equivalent (97.3% similarity, 4 informative diffs)`.
  Used as the first line of every other format.

- `pretty_formatter.rb` — coloured terminal output. Groups diffs by
  severity (normative first), then by page. Each diff shows:
  - Dimension icon (📝 text, 🔤 font, 📍 position, 🎨 colour, 🖼 image).
  - Canonical path (TODO 57).
  - Before/after snippet (truncated to 60 chars).
  - Reason phrase.

- `by_page_formatter.rb` — per-page section; lists every diff on
  that page. Good for "what's wrong with page 7?".

- `by_element_formatter.rb` — per-element-namespace section. Lists
  every diff affecting e.g. all tables, all headings.

- `json_formatter.rb` — machine-readable JSON for CI integration.
  Schema:
  ```json
  {
    "equivalent": false,
    "similarity": 0.873,
    "profile": "oiml_regression",
    "normative_diffs": [...],
    "informative_diffs": [...]
  }
  ```

- `html_formatter.rb` — standalone HTML report. Embeds:
  - Page thumbnails (left: reference, right: ours) with diff regions
    boxed.
  - Per-diff detail panel.
  - Filter controls (hide informative, hide by dimension).
  - Uses pixel-diff images (TODO 59) when available.

- `junit_formatter.rb` — JUnit XML for CI systems that consume it
  (Jenkins, GitLab CI).

- `legend.rb` — explains icons, colours, dimension names. Shared
  across formatters.

- `theme.rb` — ANSI colour palette + HTML CSS variables.

## Approach for diffs within a diff

Use `Diff::LCS.sdiff` on the relevant extracted text (per page or
per element) to produce line-level hunks. Wrap each hunk as a
`DiffBlock` (modeled on `Canon::Diff::DiffBlock`). The formatter
renders DiffBlocks with `+`/`-`/` ` prefixes and optional colour.

## Done-When

- [ ] `SummaryFormatter.(report)` returns a one-line pass/fail.
- [ ] `PrettyFormatter.(report)` produces coloured terminal output
      that fits in 80 columns.
- [ ] `JsonFormatter.(report)` produces valid JSON parseable by
      `JSON.parse`.
- [ ] `HtmlFormatter.(report)` produces a valid HTML file openable
      in a browser.
- [ ] `JUnitFormatter.(report)` produces valid JUnit XML.
- [ ] Each formatter has at least one fixture-based spec.
- [ ] A CLI flag (`--format pretty|json|html|junit|summary`) selects
      the formatter.
