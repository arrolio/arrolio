---
priority: P0
phase: 7
depends_on: [24]
layer: template
est: 2d
status: pending
---

## Problem

The engine needs to know which PageTemplate to use for each output
page. FOP's `fo:page-sequence-master` solves this with rules: first,
odd, even, blank, last. Same model in Ruby.

## Approach

File: `lib/arrolio/layout_spec/page_sequence_master.rb`.

```ruby
class Arrolio::LayoutSpec::PageSequenceMaster
  attr_reader :rules, :fallback

  def initialize(rules: {}, fallback: nil)
    # rules: { first: template_name, odd: ..., even: ..., blank: ..., last: ... }
    # All values are Symbol template names.
  end

  def template_name_for(page_number:, total: nil, blank: false)
    # Returns a Symbol template name. Selection order:
    #   1. first page (page_number == 1) && rules[:first]
    #   2. blank page && rules[:blank]
    #   3. last page (page_number == total) && rules[:last]
    #   4. odd/even by parity
    #   5. fallback or rules[:default]
  end
end
```

Engine integration:
- Track page_number, total (set in pass 1), and "is this a blank page"
  (page with no body content, only static).
- On each new page, query the master for the template name.
- Look up the actual PageTemplate in the LayoutSpec.

## Done-When

- [ ] `template_name_for(page_number: 1)` returns `rules[:first]` if set.
- [ ] `template_name_for(page_number: 4, total: 4)` returns
      `rules[:last]` if set.
- [ ] `template_name_for(page_number: 2)` returns `rules[:even]`.
- [ ] `template_name_for(page_number: 3)` returns `rules[:odd]`.
- [ ] Falls through to fallback when no rule matches.
- [ ] Engine uses the selected template to size each new page.
