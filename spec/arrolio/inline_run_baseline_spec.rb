# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::InlineRun do
  describe 'baseline shift attributes' do
    it 'defaults to normal baseline and 1.0 scale' do
      run = described_class.new('hi')
      expect(run.baseline_shift).to be_nil
      expect(run.font_size_scale).to eq(1.0)
      expect(run.subscript?).to be(false)
      expect(run.superscript?).to be(false)
    end

    it 'accepts :sub baseline shift' do
      run = described_class.new('min', baseline_shift: :sub)
      expect(run.baseline_shift).to eq(:sub)
      expect(run.subscript?).to be(true)
    end

    it 'accepts :sup baseline shift' do
      run = described_class.new('2', baseline_shift: :sup)
      expect(run.baseline_shift).to eq(:sup)
      expect(run.superscript?).to be(true)
    end

    it 'accepts custom font_size_scale' do
      run = described_class.new('min', baseline_shift: :sub, font_size_scale: 0.7)
      expect(run.font_size_scale).to eq(0.7)
    end
  end

  describe 'equality' do
    it 'compares by text + style_id + baseline_shift + font_size_scale' do
      a = described_class.new('min', style_id: :strong, baseline_shift: :sub, font_size_scale: 0.7)
      b = described_class.new('min', style_id: :strong, baseline_shift: :sub, font_size_scale: 0.7)
      expect(a).to eq(b)
      expect(a.hash).to eq(b.hash)
    end

    it 'distinguishes different baseline shifts' do
      sub = described_class.new('min', baseline_shift: :sub)
      sup = described_class.new('min', baseline_shift: :sup)
      expect(sub).not_to eq(sup)
    end
  end

  it 'is frozen' do
    expect(described_class.new('hi')).to be_frozen
  end
end

# Lightweight measurer substitute: returns the font_size passed to it.
FontSizeMeasurer = Struct.new(:width_of_run_calls, keyword_init: true) do
  def width_of_run(text, font_size:, **_opts)
    (self.width_of_run_calls ||= []) << { text: text, font_size: font_size }
    font_size
  end
end

RSpec.describe Arrolio::InlineRun do
  describe 'baseline shift for layout-level runs' do
    let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 12) }

    it 'defaults to normal baseline and 1.0 scale' do
      run = described_class.new('hi', style: style)
      expect(run.baseline_shift).to be_nil
      expect(run.font_size_scale).to eq(1.0)
    end

    it 'scales width by font_size_scale' do
      measurer = FontSizeMeasurer.new

      normal = described_class.new('D', style: style)
      sub = described_class.new('min', style: style, baseline_shift: :sub, font_size_scale: 0.7)

      expect(normal.width(measurer)).to eq(12.0)
      expect(sub.width(measurer)).to be_within(0.001).of(8.4) # 12 * 0.7
    end
  end
end
