# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'Inline <fn> extraction through full pipeline' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }
  let(:adapter_rules_path) { File.join(flavor_dir, 'adapter_rules.yml') }
  let(:adapter) { Arrolio::GenericAdapter.new(rules: adapter_rules_path) }

  let(:xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <doc xmlns="https://www.metanorma.org/ns/standoc">
        <bibdata><docidentifier>FN-001</docidentifier></bibdata>
        <sections>
          <clause>
            <fmt-title depth="1"><semx element="autonum">1</semx><tab/><semx element="title">Body</semx></fmt-title>
            <p>See note<fn id="fn1">1</fn> for details.</p>
          </clause>
        </sections>
        <fmt-footnote-container id="fn1">
          <fmt-fn-body><p>First footnote body.</p></fmt-fn-body>
        </fmt-footnote-container>
      </doc>
    XML
  end

  it 'extracts <fn> references into Paragraph#footnote_refs' do
    document = adapter.convert(xml)
    expect(document.footnotes.length).to eq(1)
    body_paragraph = document.sections.first.children.first
    expect(body_paragraph).to be_a(Arrolio::Content::Paragraph)
    expect(body_paragraph.footnote_refs).to include('fn1')
  end

  it 'flow builder emits FootnoteMarkerFlowable at the paragraph site' do
    document = adapter.convert(xml)
    layout_spec = Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml'))
    rules = YAML.safe_load_file(File.join(flavor_dir, 'flow_rules.yml'))
    rules['page_bottom_footnotes'] = true
    builder = Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules)

    flowables = builder.build(document)
    markers = flowables.grep(Arrolio::Flowables::FootnoteMarkerFlowable)
    expect(markers.length).to eq(1)
    expect(markers.first.footnote.id).to eq('fn1')
  end

  it 'engine collects the footnote onto the same page as the paragraph' do
    document = adapter.convert(xml)
    layout_spec = Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml'))
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

  it 'Content::Paragraph value equality includes footnote_refs' do
    a = Arrolio::Content::Paragraph.new(
      [Arrolio::Content::InlineRun.new('x')],
      footnote_refs: ['fn1']
    )
    b = Arrolio::Content::Paragraph.new(
      [Arrolio::Content::InlineRun.new('x')],
      footnote_refs: ['fn1']
    )
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'Paragraph defaults footnote_refs to empty array' do
    paragraph = Arrolio::Content::Paragraph.new([])
    expect(paragraph.footnote_refs).to eq([])
  end

  it 'produces no footnote_refs when XML has no <fn> elements' do
    plain_xml = <<~XML
      <doc xmlns="https://www.metanorma.org/ns/standoc">
        <bibdata/><sections><clause><p>no fn here</p></clause></sections>
      </doc>
    XML
    document = adapter.convert(plain_xml)
    paragraph = document.sections.first.children.first
    expect(paragraph.footnote_refs).to eq([])
  end
end
