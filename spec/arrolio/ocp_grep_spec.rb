# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OCP: generic core has zero flavor-specific literals' do
  let(:gem_root) { File.expand_path('../..', __dir__) }

  let(:generic_core_files) do
    [
      'lib/arrolio/generic_adapter.rb',
      'lib/arrolio/generic_flow_builder.rb',
      'lib/arrolio/config_driven_pipeline.rb',
      'lib/arrolio/asset_resolver.rb',
      'lib/arrolio/toc_builder.rb',
      'exe/arrolio2pdf'
    ]
  end

  def core_source
    generic_core_files.map { |path| File.read(File.join(gem_root, path)) }.join("\n")
  end

  it 'has no flavor names (oiml/iso/iec/bsi)' do
    expect(core_source).not_to match(/OIML|iso_|iec_|bsi_/i)
  end

  it 'has no zzSTDTitle reference' do
    expect(core_source).not_to include('zzSTDTitle')
  end

  it 'has no flavor-specific font names' do
    expect(core_source).not_to match(/["']Arial["']/)
    expect(core_source).not_to match(/["']Jost["']/)
    expect(core_source).not_to match(/["']Times New Roman["']/)
  end

  it 'references fmt-* only in DEFAULT_SELECTORS (clearly labelled convention)' do
    generic_adapter = File.read(File.join(gem_root, 'lib/arrolio/generic_adapter.rb'))
    defaults_match = generic_adapter.match(/DEFAULT_SELECTORS\s*=.*?\}\.freeze/mx)
    outside_defaults = defaults_match ? generic_adapter.sub(defaults_match[0], '') : generic_adapter
    outside_defaults = outside_defaults.lines.reject { |line| line.strip.start_with?('#') }.join
    expect(outside_defaults).not_to include('fmt-title')
    expect(outside_defaults).not_to include('fmt-name')
    expect(outside_defaults).not_to include('fmt-preferred')
    expect(outside_defaults).not_to include('fmt-definition')
    expect(outside_defaults).not_to include('fmt-termsource')
    expect(outside_defaults).not_to include('biblio-tag')
  end
end

RSpec.describe 'OCP: GenericAdapter honors a non-Metanorma vocabulary' do
  let(:custom_rules) do
    {
      'metadata' => { 'root' => 'meta', 'fields' => { 'docidentifier' => 'id' } },
      'sections' => { 'container' => 'body' },
      'element_mapping' => {
        'sec' => { 'content_type' => 'section' },
        'para' => { 'content_type' => 'paragraph' },
        'tbl' => { 'content_type' => 'table' }
      },
      'selectors' => {
        'heading' => 'head',
        'heading_depth_attribute' => 'level',
        'paragraph' => 'para',
        'table_header' => 'thead',
        'table_body' => 'tbody',
        'table_row' => 'row',
        'table_cell' => ['cell', 'headcell'],
        'id_attribute' => 'id'
      }
    }
  end

  it 'parses a non-Metanorma XML document using only selectors' do
    adapter = Arrolio::GenericAdapter.new(rules: custom_rules)
    xml = <<~XML
      <doc>
        <meta><id>CUSTOM-001</id></meta>
        <body>
          <sec id="s1">
            <head level="1">Introduction</head>
            <para>Hello from the custom vocabulary.</para>
          </sec>
        </body>
      </doc>
    XML
    document = adapter.convert(xml)
    expect(document.metadata[:docidentifier]).to eq('CUSTOM-001')
    expect(document.sections.length).to eq(1)
    section = document.sections.first
    expect(section.title).to eq('Introduction')
    expect(section.level).to eq(1)
    paragraph = section.children.first
    expect(paragraph).to be_a(Arrolio::Content::Paragraph)
    expect(paragraph.text).to eq('Hello from the custom vocabulary.')
  end
end
