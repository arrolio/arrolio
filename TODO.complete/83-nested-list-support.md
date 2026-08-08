---
priority: P1
impact: high
depends_on: [66]
layer: adapter
status: done
est: 0.5d
---

## Problem

The adapter's `convert_list` only collected `<p>` paragraph children
of `<li>` elements, silently dropping nested `<ol>`/`<ul>` lists.
Similarly, `list_flowable` in the flow builder only converted
`Content::Paragraph` items, skipping `Content::List`.

This caused entire sub-lists to disappear from the output. For
example, item b) in section 6.1:

```
b) For legally relevant software... shall be applied.
   1) The exception described in clause 5.1.1...
   2) The level of conformity...
   3) Updating the legally relevant software...
   4) The software documentation shall include...
```

Items 1-4 were completely absent from our output.

## Fix (2026-08-08)

### Adapter (`convert_list`)

```ruby
content = []
each_element(li) do |child|
  next if child.parent && child.parent != li  # direct children only

  if child.name == para_name
    content << convert_paragraph(child)
  elsif list_mapping.key?(child.name)
    nested_kind = list_mapping[child.name]['kind']&.to_sym || :bullet
    content << convert_list(child, kind: nested_kind)
  end
end
```

### Flow builder (`list_flowable`)

```ruby
def flowable_for_list_content(content)
  case content
  when Content::Paragraph then [paragraph_flowable(content)]
  when Content::List then [list_flowable(content)]
  else []
  end
end
```

The `ListFlowable` already handles arbitrary body flowables via
`f.emit`, so nested `ListFlowable` renders correctly at increased
indent.

## Done-When

- [x] Nested `<ol>`/`<ul>` inside `<li>` are collected by adapter
- [x] `Content::List` inside list item content is converted by flow builder
- [x] Nested list markers render at increased indent
- [x] Item b) sub-items 1-4 visible in output

## Measurement

Verified on OIML r060/1 page 26: items 1-4 now visible.
Last measured: 2026-08-08.
