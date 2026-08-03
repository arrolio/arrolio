---
priority: P0
phase: 17
depends_on: [55, 56, 57]
layer: harness
est: 2d
status: pending
---

## Problem

For tests and CI, users need a fluent RSpec API. Two matchers cover
the common cases:

```ruby
expect(our_pdf_bytes).to match_pdf(ref_path)              # strict
expect(our_pdf_bytes).to be_equivalent_to_pdf(ref_path)   # ignores informative
```

Plus a programmatic `Arrolio::Harness.diff` for non-RSpec use.

## Approach

### RSpec matchers

File: `lib/arrolio/harness/rspec.rb` (auto-registered into RSpec
when required from `spec_helper.rb`).

```ruby
RSpec::Matchers.define :match_pdf do |reference_path|
  match do |actual_bytes|
    report = Arrolio::Harness.diff(
      ours: actual_bytes,
      reference: File.binread(reference_path),
      profile: @profile || :strict
    )
    report.equivalent?(profile: @profile || :strict).tap do
      @failure_report = report
    end
  end

  chain :with_profile do |profile|
    @profile = profile
  end

  failure_message do
    Arrolio::Harness::Formatters::PrettyFormatter.(@failure_report)
  end
end

RSpec::Matchers.define :be_equivalent_to_pdf do |reference_path|
  # Same as match_pdf but profile: :content_only by default —
  # ignores font-size drift, position drift under 1pt, etc.
end
```

### Programmatic API

File: `lib/arrolio/harness.rb`.

```ruby
module Arrolio::Harness
  module_function

  def diff(ours:, reference:, profile: :strict)
    ours_doc    = Pdfrb::Document.new(io: StringIO.new(ours))
    ref_doc     = Pdfrb::Document.new(io: StringIO.new(reference))
    comparator  = Comparator::PdfComparator.new(profile:)
    report      = comparator.compare(ours_doc, ref_doc)
    DiffNodeEnricher.enrich(report)
    report
  end

  def equivalent?(ours:, reference:, profile: :strict)
    diff(ours:, reference:, profile:).equivalent?(profile:)
  end

  def format(report, format: :pretty)
    Formatters.from_name(format).(report)
  end
end
```

### CLI integration

Extend `exe/arrolio-oiml` (TODO 54):

```sh
# Diff our rendering of OIML XML against FOP's:
arrolio-oiml diff document.presentation.xml \
              --reference=document.fop.pdf \
              --profile=oiml_regression \
              --format=pretty|json|html|junit

# Diff two pre-rendered PDFs:
arrolio-harness diff ours.pdf ref.pdf --profile=strict
```

### Spec wiring

In `spec/spec_helper.rb`:
```ruby
require "arrolio/harness/rspec"
```

Then `spec/arrolio/oiml/e2e_spec.rb` becomes:
```ruby
it "#{base} matches FOP reference" do
  out = StringIO.new
  Arrolio::Oiml::Pipeline.(xml, io: out)
  expect(out.string).to be_equivalent_to_pdf(ref_pdf)
    .with_profile(:oiml_regression)
end
```

## Done-When

- [ ] `require "arrolio/harness/rspec"` registers both matchers.
- [ ] `match_pdf` fails with a useful pretty-formatted message.
- [ ] `be_equivalent_to_pdf` ignores informative diffs by default.
- [ ] `Arrolio::Harness.diff(...)` returns a `DiffReport`.
- [ ] `Arrolio::Harness.equivalent?(...)` returns a bool.
- [ ] CLI `arrolio-oiml diff ...` exits 0 on equivalent, 1 on diff.
- [ ] CI-friendly: JSON formatter output stable across runs.
