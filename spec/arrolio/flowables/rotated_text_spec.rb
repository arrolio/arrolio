# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::RotatedText do
  let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 11) }

  describe '#emit' do
    it 'emits a placed box of kind :rotated_text' do
      rt = described_class.new('vertical text', style: style, angle: 90)
      boxes, consumed = rt.emit(72.0, 700.0, 200.0, nil)
      expect(boxes.length).to eq(1)
      expect(boxes.first.kind).to eq(:rotated_text)
      expect(consumed).to eq(0.0)
    end

    it 'carries the angle and text in the box data' do
      rt = described_class.new('vertical', style: style, angle: 270)
      boxes, = rt.emit(0, 700, 200, nil)
      data = boxes.first.data
      expect(data[:text]).to eq('vertical')
      expect(data[:angle]).to eq(270.0)
    end
  end

  describe '#height' do
    it 'returns the line height of the resolved font' do
      rt = described_class.new('x', style: style, angle: 90)
      expect(rt.height(200)).to be_positive
    end
  end
end
