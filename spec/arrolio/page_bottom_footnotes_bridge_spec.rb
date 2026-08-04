# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'Page-bottom footnotes opt-in (Phase 4 bridge from flow builder)' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml')) }

  let(:document) do
    footnote = Arrolio::Content::Footnote.new(
      marker: '1',
      body: [Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('Footnote body.')],
        style_id: :footnote
      )],
      id: 'fn1'
    )
    section = Arrolio::Content::Section.new(
      title: 'S', level: 1, children: [],
      style_id: :section_body_1, title_style_id: :heading_1
    )
    Arrolio::Content::Document.new(
      metadata: { docidentifier: 'X' },
      sections: [section],
      footnotes: [footnote]
    )
  end

  it 'emits FootnoteMarkerFlowable per footnote when page_bottom_footnotes is truthy' do
    rules = YAML.safe_load_file(File.join(flavor_dir, 'flow_rules.yml'))
    rules['page_bottom_footnotes'] = true
    builder = Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules)

    flowables = builder.build(document)
    markers = flowables.grep(Arrolio::Flowables::FootnoteMarkerFlowable)
    expect(markers.length).to eq(1)
    expect(markers.first.footnote.id).to eq('fn1')
  end

  it 'does not emit markers by default (opt-in)' do
    rules = YAML.safe_load_file(File.join(flavor_dir, 'flow_rules.yml'))
    rules.delete('page_bottom_footnotes')
    builder = Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules)

    flowables = builder.build(document)
    markers = flowables.grep(Arrolio::Flowables::FootnoteMarkerFlowable)
    expect(markers.length).to eq(0)
  end

  it 'does not emit markers when document has no footnotes' do
    rules = YAML.safe_load_file(File.join(flavor_dir, 'flow_rules.yml'))
    rules['page_bottom_footnotes'] = true
    builder = Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules)

    empty_doc = Arrolio::Content::Document.new(
      metadata: { docidentifier: 'X' },
      sections: [Arrolio::Content::Section.new(title: 'S', level: 1)]
    )
    flowables = builder.build(empty_doc)
    markers = flowables.grep(Arrolio::Flowables::FootnoteMarkerFlowable)
    expect(markers.length).to eq(0)
  end

  it 'renders the full pipeline: flow builder -> engine -> Output::Page.footnotes' do
    rules = YAML.safe_load_file(File.join(flavor_dir, 'flow_rules.yml'))
    rules['page_bottom_footnotes'] = true
    builder = Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules)

    flowables = builder.build(document)
    engine = Arrolio::Engine::Paged.new(layout_spec: layout_spec, flowables: flowables)
    pages = engine.layout
    footnoted_pages = pages.reject { |p| p.footnotes.empty? }
    expect(footnoted_pages.length).to eq(1)
    expect(footnoted_pages.first.footnotes.first.id).to eq('fn1')
  end
end
