---
priority: P1
impact: low
depends_on: []
layer: render
status: done
est: 1d
---

## Problem

Reference PDF /Info dict has Title, Author, Creator, Producer,
CreationDate. Arrolio emits none of these. Some PDF readers show
"Untitled" in document properties.

## Approach

Update `Renderer::Pdf#render` to populate `@document.catalog`
(or its /Info dict) before write:

```ruby
info.value[:Title] = document.metadata[:title]
info.value[:Author] = "International Organization of Legal Metrology"
info.value[:Creator] = "Arrolio + Pdfrb"
info.value[:Producer] = "Arrolio + Pdfrb"
info.value[:CreationDate] = "D:YYYYMMDDHHmmSS+00'00'"
```

Source data: from `<bibdata>` in the XML — already extracted into
`Content::Document#metadata`. Author from `<contributor>` where
role = author.

## Done-When

- [ ] `pdfinfo out.pdf` shows Title = full English title.
- [ ] Author = "International Organization of Legal Metrology".
- [ ] CreationDate format matches PDF spec.
- [ ] Specs cover: Info dict construction, missing-field handling.

## Implementation

`Renderer::Pdf#apply_metadata` sets Title, Author, Creator, Producer on the /Info dict.
