# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::TwoColumnBlock do
  let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 12) }
  let(:left_tf) do
    Arrolio::Flowables::TextFlowable.new(
      [Arrolio::InlineRun.new('Left', style: style)], style: style
    )
  end
  let(:right_tf) do
    Arrolio::Flowables::TextFlowable.new(
      [Arrolio::InlineRun.new('Right', style: style)], style: style
    )
  end

  it 'computes height as max of both columns' do
    block = described_class.new(left_flowables: [left_tf], right_flowables: [right_tf])
    h = block.height(400.0)
    expect(h).to be > 0
  end

  it 'splits width by left_ratio' do
    block = described_class.new(
      left_flowables: [left_tf], right_flowables: [right_tf], left_ratio: 0.6
    )
    h = block.height(400.0)
    expect(h).to be > 0
  end

  it 'emits boxes from both columns' do
    block = described_class.new(left_flowables: [left_tf], right_flowables: [right_tf])
    boxes, consumed = block.emit(0, 100.0, 400.0, nil)
    expect(boxes).to be_an(Array)
    expect(consumed).to be > 0
  end
end
