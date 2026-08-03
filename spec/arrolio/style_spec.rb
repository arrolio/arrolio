# frozen_string_literal: true

require 'arrolio'

RSpec.describe Arrolio::Style::Definition do
  it 'applies defaults to every property so callers can branch without respond_to?' do
    style = described_class.new
    expect(style.font_name).to eq('Helvetica')
    expect(style.font_size).to eq(12.0)
    expect(style.keep_together).to be(false)
    expect(style.page_break_before).to be(false)
    expect(style.align).to eq(:left)
  end

  it 'merges overrides into a new instance via #with' do
    base = described_class.new(font_name: 'Times-Roman', font_size: 11)
    bigger = base.with(font_size: 18)
    expect(bigger.font_size).to eq(18.0)
    expect(bigger.font_name).to eq('Times-Roman')
    expect(base.font_size).to eq(11.0)
  end

  it 'compares by value' do
    a = described_class.new(font_name: 'Helvetica', font_size: 12)
    b = described_class.new(font_name: 'Helvetica', font_size: 12)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new).to be_frozen
  end

  it "accepts string 'true'/'always' as truthy for boolean fields" do
    style = described_class.new(keep_together: 'always', page_break_before: 'true')
    expect(style.keep_together).to be(true)
    expect(style.page_break_before).to be(true)
  end
end

RSpec.describe Arrolio::Style::Registry do
  it 'resolves a registered name to its Definition' do
    registry = described_class.new(
      'body' => { 'font_name' => 'Times-Roman', 'font_size' => 11 }
    )
    resolved = registry.resolve(:body)
    expect(resolved.font_name).to eq('Times-Roman')
    expect(resolved.font_size).to eq(11.0)
  end

  it 'inherits parent properties when a child omits them' do
    registry = described_class.new(
      'body' => { 'font_name' => 'Times-Roman', 'font_size' => 11, 'align' => 'justify' },
      'heading_1' => { 'parent' => 'body', 'font_name' => 'Times-Bold', 'font_size' => 18 }
    )
    h1 = registry.resolve(:heading_1)
    expect(h1.font_name).to eq('Times-Bold')
    expect(h1.font_size).to eq(18.0)
    expect(h1.align).to eq(:justify) # inherited
  end

  it 'returns the fallback for unknown names' do
    registry = described_class.new
    expect(registry.resolve(:nonexistent, fallback: Arrolio::Style::Definition.new(font_name: 'Courier'))).to be_frozen
  end
end

RSpec.describe Arrolio::Style::Loader do
  it 'loads from a YAML string' do
    registry = described_class.load(<<~YAML)
      body:
        font_name: Times-Roman
        font_size: 11
      heading_1:
        parent: body
        font_name: Times-Bold
        font_size: 18
    YAML
    expect(registry.resolve(:heading_1).font_name).to eq('Times-Bold')
    expect(registry.resolve(:heading_1).font_size).to eq(18.0)
    expect(registry.resolve(:heading_1).align).to eq(registry.resolve(:body).align)
  end
end
