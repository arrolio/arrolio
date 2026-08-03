# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe 'Second flavor spike: altvocab (non-Metanorma vocabulary)' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/altvocab', __dir__) }

  let(:xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <article>
        <meta>
          <id>ART-001</id>
          <lang>en</lang>
          <h1>Synthetic Article</h1>
        </meta>
        <body>
          <sec id="s1">
            <h2 level="1">First Section</h2>
            <para>This is a paragraph in the altvocab synthetic vocabulary.</para>
            <note>
              <label>NOTE</label>
              <para>This is a note.</para>
            </note>
            <ulist>
              <li><para>First item</para></li>
              <li><para>Second item</para></li>
            </ulist>
            <olist>
              <li><marker>1)</marker><para>Ordered first</para></li>
            </olist>
            <code>def hello; puts "hi"; end</code>
          </sec>
          <sec id="s2">
            <h2 level="2">Nested Section</h2>
            <para>Nested content.</para>
          </sec>
        </body>
        <refs>
          <list>
            <entry><citekey>Smith2020</citekey><formatted>Smith, J. (2020).</formatted></entry>
          </list>
        </refs>
      </article>
    XML
  end

  it 'parses the document via the non-Metanorma vocabulary' do
    pipeline = Arrolio::ConfigDrivenPipeline.new(flavor_dir: flavor_dir)
    document = Arrolio::GenericAdapter.new(rules: pipeline.adapter_rules).convert(xml)

    expect(document.metadata[:docidentifier]).to eq('ART-001')
    expect(document.metadata[:language]).to eq('en')
    expect(document.metadata[:title]).to eq('Synthetic Article')
    expect(document.sections.length).to eq(2)
    expect(document.sections.first.title).to eq('First Section')
    expect(document.sections.first.level).to eq(1)
    expect(document.bibliography.length).to eq(1)
  end

  it 'renders to a re-readable PDF via the generic pipeline' do
    io = StringIO.new
    Arrolio::ConfigDrivenPipeline.render(xml, io: io, flavor_dir: flavor_dir)
    expect(io.string).to start_with('%PDF-')
    reopened = Pdfrb::Document.new(io: StringIO.new(io.string))
    expect(reopened.pages.count).to be >= 1
  end

  it 'exposes the altvocab manifest' do
    pipeline = Arrolio::ConfigDrivenPipeline.new(flavor_dir: flavor_dir)
    expect(pipeline.manifest.name).to eq('altvocab')
    expect(pipeline.manifest.doctypes).to eq(['article'])
  end
end
