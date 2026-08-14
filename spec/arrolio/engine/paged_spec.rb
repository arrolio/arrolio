# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Engine::Paged do
  let(:layout_spec_path) { File.expand_path('../../fixtures/flavors/sample/layout_spec.yml', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(layout_spec_path) }

  def text_flowable(margin_top: 0, margin_bottom: 0, text: 'Hello')
    style = Arrolio::Style::Definition.new(
      margin_top: margin_top, margin_bottom: margin_bottom
    )
    Arrolio::Flowables::TextFlowable.new(
      [Arrolio::InlineRun.new(text, style: style)],
      style: style
    )
  end

  it 'places two flowables on a page' do
    flowables = [text_flowable(text: 'A'), text_flowable(text: 'B')]
    engine = described_class.new(layout_spec: layout_spec, flowables: flowables)
    pages = engine.layout
    expect(pages.first.regions[:body].placed_boxes.length).to eq(2)
  end

  it 'resolves consecutive margins via max (FO space resolution)' do
    a = text_flowable(margin_bottom: 20, text: 'A')
    b = text_flowable(margin_top: 10, text: 'B')
    engine = described_class.new(layout_spec: layout_spec, flowables: [a, b])
    pages = engine.layout
    boxes = pages.first.regions[:body].placed_boxes
    gap = boxes[0].y - (boxes[1].y + boxes[1].height)
    expect(gap).to be_within(2.0).of(20.0)
  end

  it 'resets space resolution across page breaks' do
    tall = text_flowable(margin_bottom: 30, text: 'Tall')
    pb = Arrolio::Flowables::PageBreak.new
    c = text_flowable(margin_top: 15, text: 'NewPage')
    engine = described_class.new(layout_spec: layout_spec, flowables: [tall, pb, c])
    pages = engine.layout
    expect(pages.length).to eq(2)
    expect(pages.last.regions[:body].placed_boxes).not_to be_empty
  end
end
