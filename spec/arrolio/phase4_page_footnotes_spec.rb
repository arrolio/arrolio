# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Phase 4: per-page footnote collection and rendering' do
  let(:footnote) do
    body = [Arrolio::Content::Paragraph.new(
      [Arrolio::Content::InlineRun.new('Footnote body text.')],
      style_id: :footnote
    )]
    Arrolio::Content::Footnote.new(marker: '1', body: body, id: 'fn1')
  end

  it 'FootnoteMarkerFlowable has zero height and emits nothing' do
    marker = Arrolio::Flowables::FootnoteMarkerFlowable.new(footnote)
    expect(marker.height(200)).to eq(0.0)
    boxes, consumed = marker.emit(0, 100, 200)
    expect(boxes).to eq([])
    expect(consumed).to eq(0.0)
  end

  it 'FootnoteMarkerFlowable carries the footnote reference' do
    marker = Arrolio::Flowables::FootnoteMarkerFlowable.new(footnote)
    expect(marker.footnote).to eq(footnote)
  end

  it 'Engine::Paged collects footnotes onto the page where the marker appears' do
    layout_yaml = <<~YAML
      default_page_template: body
      page_templates:
        body:
          page_size: A4
      styles:
        body:
          font_name: Helvetica
      flows:
        main:
          region: body
    YAML
    layout_spec = Arrolio::LayoutSpec::Loader.load(layout_yaml)
    paragraph = Arrolio::Flowables::TextFlowable.new(
      [Arrolio::InlineRun.new('Body text', style: Arrolio::Style::Definition.new)],
      style: Arrolio::Style::Definition.new
    )
    marker = Arrolio::Flowables::FootnoteMarkerFlowable.new(footnote)
    engine = Arrolio::Engine::Paged.new(layout_spec: layout_spec, flowables: [paragraph, marker])
    pages = engine.layout
    expect(pages.length).to be >= 1
    expect(pages.last.footnotes).to include(footnote)
  end

  it 'Output::Page carries footnotes and participates in value equality' do
    region = Arrolio::Output::Region.new(name: :body, x: 0, y: 0, width: 100, height: 100)
    page = Arrolio::Output::Page.new(
      number: 1, template_name: :body, page_size: [100, 100],
      regions: { body: region }, footnotes: [footnote]
    )
    expect(page.footnotes).to eq([footnote])
    page2 = Arrolio::Output::Page.new(
      number: 1, template_name: :body, page_size: [100, 100],
      regions: { body: region }, footnotes: [footnote]
    )
    expect(page).to eq(page2)
  end

  it 'Output::Page defaults footnotes to empty array' do
    region = Arrolio::Output::Region.new(name: :body, x: 0, y: 0, width: 100, height: 100)
    page = Arrolio::Output::Page.new(
      number: 1, template_name: :body, page_size: [100, 100],
      regions: { body: region }
    )
    expect(page.footnotes).to eq([])
  end
end
