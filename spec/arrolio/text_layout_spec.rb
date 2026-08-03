# frozen_string_literal: true

require 'arrolio'

RSpec.describe Arrolio::TextLayout::Greedy do
  let(:measurer) { Arrolio::GlyphMeasurer.new(font_name: 'Helvetica') }
  let(:style) { Arrolio::Style::Definition.new(font_name: 'Helvetica', font_size: 12) }

  it 'emits one line when text fits' do
    runs = [Arrolio::InlineRun.new('Hello', style: style)]
    lines = described_class.new(runs, measurer: measurer, width: 500).layout
    expect(lines.length).to eq(1)
    expect(lines.first.placed_runs.map { |pr| pr.run.text }.join).to eq('Hello')
  end

  it 'wraps long text into multiple lines' do
    runs = [Arrolio::InlineRun.new('The quick brown fox jumps over the lazy dog', style: style)]
    lines = described_class.new(runs, measurer: measurer, width: 100).layout
    expect(lines.length).to be > 1
  end

  it 'does not split multibyte UTF-8 characters' do
    runs = [Arrolio::InlineRun.new('café — résumé naïve', style: style)]
    lines = described_class.new(runs, measurer: measurer, width: 80).layout
    lines.each do |line|
      text = line.placed_runs.map { |pr| pr.run.text }.join
      expect(text).to eq(text.scrub)
      expect(text.valid_encoding?).to be(true)
    end
  end

  it 'honours explicit newlines as forced breaks' do
    runs = [Arrolio::InlineRun.new("line one\nline two", style: style)]
    lines = described_class.new(runs, measurer: measurer, width: 500).layout
    expect(lines.length).to eq(2)
  end
end

RSpec.describe Arrolio::TextLayout::Line do
  it 'computes x_offset for center alignment' do
    line = described_class.new([], width: 100, max_width: 300, align: :center)
    expect(line.x_offset).to eq(100.0)
  end

  it 'computes x_offset for right alignment' do
    line = described_class.new([], width: 100, max_width: 300, align: :right)
    expect(line.x_offset).to eq(200.0)
  end
end
