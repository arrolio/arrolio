# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe Arrolio::ConfigDrivenPipeline do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }

  let(:minimal_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="presentation">
        <bibdata type="standard">
          <title language="en" type="main">Pipeline test</title>
          <docidentifier>TEST 1</docidentifier>
          <edition>1</edition>
        </bibdata>
        <sections>
          <clause id="c1">
            <fmt-title depth="1">
              <span class="fmt-caption-label"><semx element="autonum">1</semx></span>
              <span class="fmt-caption-delim"><tab/></span>
              <semx element="title">Introduction</semx>
            </fmt-title>
            <p>Hello, world.</p>
          </clause>
        </sections>
      </metanorma>
    XML
  end

  it 'renders a flavor directory to a readable multi-page PDF' do
    io = StringIO.new
    described_class.render(minimal_xml, io: io, flavor_dir: flavor_dir)
    expect(io.string).to start_with('%PDF-')
    reopened = Pdfrb::Document.new(io: StringIO.new(io.string))
    expect(reopened.pages.count).to be >= 1
  end

  it 'exposes the loaded layout_spec, adapter_rules, and flow_rules' do
    pipeline = described_class.new(flavor_dir: flavor_dir)
    expect(pipeline.layout_spec).to be_a(Arrolio::LayoutSpec)
    expect(pipeline.adapter_rules).to be_a(Hash)
    expect(pipeline.flow_rules).to be_a(Hash)
    expect(pipeline.layout_spec.page_template.page_size)
      .to eq(Arrolio::LayoutSpec::PageTemplate::A4)
  end

  it 'reads style definitions from the flavor layout_spec' do
    pipeline = described_class.new(flavor_dir: flavor_dir)
    body = pipeline.layout_spec.resolve_style(:body)
    expect(body.font_name).to eq('Helvetica')
    expect(pipeline.adapter_rules['element_mapping']).to include('clause')
  end
end
