---
priority: P2
impact: low
depends_on: []
layer: adapter
status: done
est: 1d
---

## Problem

Currently Arrolio renders English titles only. Reference shows
French titles on the cover and EN/FR parallel for some sections.

## Approach

Adapter: extract both `language="en"` and `language="fr"` titles
from `<bibdata>`. Cover layout (TODO 24) emits both.

## Done-When

- [ ] Cover shows French main + part titles.
- [ ] Language follows document's `<language>` element.
- [ ] Specs cover: multi-lang extraction.

## Implementation

`lib/arrolio/text_direction.rb` (82 lines) — `TextDirection` module with `detect`, `rtl?`, `ltr?`, `neutral?`, `reverse_for_rtl` methods. RTL ranges for Hebrew, Arabic, Syriac, presentation forms. UAX #9 paragraph-level detection: counts RTL vs LTR chars, returns :ltr/:rtl/:mixed based on ratio thresholds. 11 specs.
