---
priority: P1
impact: low
depends_on: []
layer: adapter
status: done
est: 0.5d
---

## Problem

`FlowBuilder#resolve_image_path` hardcodes two base directories:
```ruby
bases = [
  File.expand_path('~/src/mn/mn-samples-oiml/sources/r060/1'),
  File.expand_path('~/src/mn/mn-samples-oiml/_site/documents/r060/1')
]
```
This is environment-specific and won't work on other machines or
for other OIML documents (r129, etc.).

## Approach

Introduce `Arroolio::Oiml::AssetResolver`:

```ruby
class AssetResolver
  def initialize(base_dirs:)
    @base_dirs = base_dirs.map { |d| File.expand_path(d) }
  end

  def resolve(src)
    return src if absolute?(src)
    @base_dirs.each do |base|
      candidate = File.join(base, src)
      return candidate if File.exist?(candidate)
    end
    src
  end

  def absolute?(src)
    src.start_with?('/', 'http://', 'https://')
  end
end
```

Pipeline creates it from configuration:
```ruby
AssetResolver.new(base_dirs: [
  File.dirname(input_path),         # XML's own directory
  File.join(File.dirname(input_path), '..', 'sources', doc_id)
])
```

Pass through FlowBuilder constructor. No hardcoding.

## Done-When

- [ ] No hardcoded paths in FlowBuilder.
- [ ] AssetResolver tests cover: relative, absolute, http, not-found.
- [ ] Pipeline passes resolver from input XML's location.
- [ ] Same code works for r060/1, r129/1, or any OIML document.

## Implementation

`lib/arrolio/oiml/asset_resolver.rb` — `AssetResolver` class with base_dirs search. `Pipeline` accepts optional `input_path` to derive resolver. `FlowBuilder` accepts `asset_resolver:` kwarg. No more hardcoded paths in FlowBuilder. 9 specs.
