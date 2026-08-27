# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::TextLayout::KnuthPlass::Breaker do
  let(:style) do
    Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 12)
  end
  let(:measurer) do
    Struct.new(:dummy, keyword_init: true) do
      def width_of_run(text, font_size:, **_)
        text.length * font_size * 0.5
      end

      def line_height(font_size:, line_spacing: 1.2)
        font_size * line_spacing
      end
    end.new(dummy: nil)
  end

  def breaker_for(text, width)
    runs = [Arrolio::InlineRun.new(text, style: style)]
    items = Arrolio::TextLayout::KnuthPlass::ItemBuilder.new(runs, measurer: measurer).build
    described_class.new(items: items, line_widths: [width], runs: runs,
                        measurer: measurer, align: :left)
  end

  # Words of 24pt with 6pt glue at a 70pt measure: the break after
  # two words is too loose (ratio 2.67 > TOLERANCE) and after three
  # is over-shrunk (-3.5 < -1) - a dead zone. The emergency pass
  # must accept the loose line rather than emit one overfull line
  # (the 6.2.3 regression: whole paragraphs clipped at the page
  # edge).
  it 'breaks through the dead zone instead of one overfull line' do
    lines = breaker_for('aaaa bbbb cccc dddd', 70.0).layout
    expect(lines.length).to be > 1
    lines.each { |line| expect(line.width).to be <= 70.01 }
  end
end
