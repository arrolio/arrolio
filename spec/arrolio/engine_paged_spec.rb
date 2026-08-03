# frozen_string_literal: true

require 'arrolio'
require 'stringio'

RSpec.describe Arrolio::Engine::Paged do
  let(:layout) do
    Arrolio::LayoutSpec::Loader.load(<<~YAML)
      default_page_template: body
      page_templates:
        body: { page_size: A4, margins: { all: 50 } }
      styles:
        body: { font_name: Times-Roman, font_size: 11 }
    YAML
  end

  let(:style) { layout.resolve_style(:body) }

  it 'renders a single-paragraph document into one page' do
    runs = [Arrolio::InlineRun.new('Hello, world.', style: style)]
    flowables = [Arrolio::Flowables::TextFlowable.new(runs, style: style)]
    pages = described_class.new(layout_spec: layout, flowables: flowables).layout
    expect(pages.length).to eq(1)
    expect(pages.first.body_region.placed_boxes.length).to eq(1)
  end

  it 'splits long content across pages' do
    runs = [Arrolio::InlineRun.new('word ' * 5000, style: style)]
    flowables = [Arrolio::Flowables::TextFlowable.new(runs, style: style)]
    pages = described_class.new(layout_spec: layout, flowables: flowables).layout
    expect(pages.length).to be > 1
  end

  it 'advances pages on PageBreak' do
    runs = [Arrolio::InlineRun.new('Hello.', style: style)]
    flowables = [
      Arrolio::Flowables::TextFlowable.new(runs, style: style),
      Arrolio::Flowables::PageBreak.new,
      Arrolio::Flowables::TextFlowable.new(runs, style: style)
    ]
    pages = described_class.new(layout_spec: layout, flowables: flowables).layout
    expect(pages.length).to eq(2)
  end
end

RSpec.describe Arrolio::Renderer::Pdf do
  let(:layout) do
    Arrolio::LayoutSpec::Loader.load(<<~YAML)
      default_page_template: body
      page_templates:
        body: { page_size: A4, margins: { all: 50 } }
      styles:
        body: { font_name: Times-Roman, font_size: 11 }
    YAML
  end

  it 'produces bytes that start with %PDF' do
    style = layout.resolve_style(:body)
    runs = [Arrolio::InlineRun.new('Hello, world.', style: style)]
    flowables = [Arrolio::Flowables::TextFlowable.new(runs, style: style)]
    pages = Arrolio::Engine::Paged.new(layout_spec: layout, flowables: flowables).layout
    io = StringIO.new
    described_class.new.render(pages, io: io)
    bytes = io.string
    expect(bytes).to start_with('%PDF-')
  end
end
