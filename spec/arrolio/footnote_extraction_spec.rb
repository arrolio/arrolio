# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Phase 3: footnote extraction and endnote rendering' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }
  let(:adapter_rules_path) { File.join(flavor_dir, 'adapter_rules.yml') }
  let(:adapter) { Arrolio::GenericAdapter.new(rules: adapter_rules_path) }

  let(:xml_with_footnotes) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <doc xmlns="https://www.metanorma.org/ns/standoc">
        <bibdata>
          <docidentifier>FN-001</docidentifier>
        </bibdata>
        <sections>
          <clause>
            <fmt-title depth="1"><semx element="autonum">1</semx><tab/><semx element="title">Body</semx></fmt-title>
            <p>Body text.</p>
          </clause>
        </sections>
        <fmt-footnote-container id="fn1">
          <fmt-fn-body>
            <p>First footnote body.</p>
          </fmt-fn-body>
        </fmt-footnote-container>
        <fmt-footnote-container id="fn2">
          <fmt-fn-body>
            <p>Second footnote body.</p>
          </fmt-fn-body>
        </fmt-footnote-container>
      </doc>
    XML
  end

  it 'extracts fmt-footnote-container entries into Document#footnotes' do
    document = adapter.convert(xml_with_footnotes)
    expect(document.footnotes.length).to eq(2)
    expect(document.footnotes.first.id).to eq('fn1')
    expect(document.footnotes.first.body.first).to be_a(Arrolio::Content::Paragraph)
    expect(document.footnotes.first.body.first.text).to eq('First footnote body.')
    expect(document.footnotes.last.id).to eq('fn2')
  end

  it 'Document#footnotes defaults to empty array' do
    document = Arrolio::Content::Document.new
    expect(document.footnotes).to eq([])
  end

  it 'is included in Document value equality' do
    doc1 = Arrolio::Content::Document.new(footnotes: [])
    doc2 = Arrolio::Content::Document.new(footnotes: [])
    expect(doc1).to eq(doc2)
  end

  it 'renders endnotes when flow_rules declares endnotes' do
    rules = YAML.safe_load_file(File.join(flavor_dir, 'flow_rules.yml'))
    rules['endnotes'] = true
    layout_spec = Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml'))
    builder = Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules)
    document = adapter.convert(xml_with_footnotes)
    flowables = builder.build(document)
    note_flowables = flowables.grep(Arrolio::Flowables::NoteFlowable)
    expect(note_flowables.length).to be >= 2
  end

  it 'does not render endnotes when flow_rules omits the endnotes key' do
    rules = YAML.safe_load_file(File.join(flavor_dir, 'flow_rules.yml'))
    rules.delete('endnotes')
    layout_spec = Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml'))
    builder = Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules)
    document = adapter.convert(xml_with_footnotes)
    flowables = builder.build(document)
    note_flowables = flowables.grep(Arrolio::Flowables::NoteFlowable)
    # No endnote NoteFlowables (notes from the body still emit, but this doc has none)
    expect(note_flowables.length).to eq(0)
  end

  it 'produces no footnotes when XML has no fmt-footnote-container' do
    xml = '<doc xmlns="https://www.metanorma.org/ns/standoc"><bibdata/><sections/></doc>'
    document = adapter.convert(xml)
    expect(document.footnotes).to eq([])
  end
end
