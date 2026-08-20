# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::TextFlowable do
  let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 11) }

  # Inline math with relational operators lays out stacked: the
  # reference (JEuclid geometry) gives such formula boxes roughly
  # two text lines of vertical extent. Plain sub/superscripts stay
  # compact.
  describe 'math line height' do
    it 'reserves extra height for lines containing math operators' do
      plain = described_class.new(
        [Arrolio::InlineRun.new('ordinary words only', style: style)], style: style
      )
      math = described_class.new(
        [Arrolio::InlineRun.new("range 0.3 \u2264 p \u2264 0.8 given", style: style)], style: style
      )
      expect(math.height(400)).to be > plain.height(400)
      expect(math.height(400) - plain.height(400)).to be_between(8.0, 12.0)
    end

    it 'keeps compact height for plain subscript runs' do
      compact = described_class.new(
        [Arrolio::InlineRun.new('E', style: style),
         Arrolio::InlineRun.new('min', style: style, baseline_shift: :sub,
                                       font_size_scale: 0.7),
         Arrolio::InlineRun.new(' value here', style: style)], style: style
      )
      baseline = described_class.new(
        [Arrolio::InlineRun.new('Emin value here', style: style)], style: style
      )
      expect(compact.height(400)).to eq(baseline.height(400))
    end

    it 'carries per-line heights on the placed box' do
      tf = described_class.new(
        [Arrolio::InlineRun.new("see 0.3 \u2264 p and more text follows here", style: style)],
        style: style
      )
      boxes, = tf.emit(72.0, 700.0, 120.0, nil)
      heights = boxes.first.data[:line_heights]
      expect(heights).not_to be_nil
      expect(heights.length).to eq(boxes.first.data[:lines].length)
      expect(heights.max).to be > heights.min
    end
  end
end
