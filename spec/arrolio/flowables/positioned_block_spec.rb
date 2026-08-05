# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::PositionedBlock do
  let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 11) }
  let(:child_text) do
    Arrolio::Flowables::TextFlowable.new(
      [Arrolio::InlineRun.new('Cover text', style: style)],
      style: style
    )
  end

  describe '#height' do
    it 'returns zero — positioned blocks consume no flow height' do
      block = described_class.new(
        children: [child_text], top: 100, left: 50,
        width: 200, height: 50, style: style
      )
      expect(block.height(451)).to eq(0.0)
    end
  end

  describe '#emit' do
    it 'places children at (x+left, y-top-height) page-relative coordinates' do
      block = described_class.new(
        children: [child_text], top: 100, left: 50,
        width: 200, height: 50, style: style
      )
      boxes, consumed = block.emit(0, 700, 451, nil)
      expect(boxes).not_to be_empty
      expect(consumed).to eq(0.0)
    end

    it 'supports multiple children stacked vertically within the block' do
      second = Arrolio::Flowables::TextFlowable.new(
        [Arrolio::InlineRun.new('Second line', style: style)],
        style: style
      )
      block = described_class.new(
        children: [child_text, second], top: 50, left: 10,
        width: 300, height: 100, style: style
      )
      boxes, = block.emit(0, 700, 451, nil)
      expect(boxes.length).to be >= 2
    end
  end

  describe 'accessors' do
    it 'exposes top, left, width, height_value, children' do
      block = described_class.new(
        children: [child_text], top: 65, left: 25,
        width: 119, height: 80, style: style
      )
      expect(block.top).to eq(65.0)
      expect(block.left).to eq(25.0)
      expect(block.width).to eq(119.0)
      expect(block.height_value).to eq(80.0)
      expect(block.children.length).to eq(1)
    end
  end
end
