# frozen_string_literal: true

require 'arrolio'
require 'stringio'

RSpec.describe 'Arrolio end-to-end smoke', :e2e do
  let(:layout) do
    Arrolio::LayoutSpec::Loader.load(<<~YAML)
      default_page_template: body
      page_templates:
        body: { page_size: A4, margins: { all: 50 } }
      styles:
        body: { font_name: Times-Roman, font_size: 11 }
        heading_1: { parent: body, font_name: Times-Bold, font_size: 16 }
    YAML
  end

  it 'renders a heading + paragraph to a re-readable single-page PDF' do
    body_style = layout.resolve_style(:body)
    heading_style = layout.resolve_style(:heading_1)
    flowables = [
      Arrolio::Flowables::HeadingFlowable.new('Intro', level: 1, style: heading_style),
      Arrolio::Flowables::TextFlowable.new(
        [Arrolio::InlineRun.new('Hello, world.', style: body_style)],
        style: body_style
      )
    ]
    pages = Arrolio::Engine::Paged.new(layout_spec: layout, flowables: flowables).layout
    io = StringIO.new
    Arrolio::Renderer::Pdf.new.render(pages, io: io)

    reopened = Pdfrb::Document.new(io: StringIO.new(io.string))
    expect(reopened.pages.count).to eq(1)
  end
end
