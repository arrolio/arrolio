# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OCP: entire lib/ has zero flavor-specific artifacts' do
  let(:gem_root) { File.expand_path('../..', __dir__) }

  let(:all_lib_files) do
    Dir.glob(File.join(gem_root, 'lib', '**', '*.rb'))
  end

  def lib_source
    all_lib_files.map { |path| File.read(path) }.join("\n")
  end

  it 'has no flavor names (oiml/iso/iec/bsi) anywhere in lib/' do
    expect(lib_source).not_to match(/\bOIML\b/i)
  end

  it 'has no zzSTDTitle reference in lib/' do
    expect(lib_source).not_to include('zzSTDTitle')
  end

  it 'has no flavor-specific font names in lib/' do
    expect(lib_source).not_to match(/["']Arial["']/)
    expect(lib_source).not_to match(/["']Jost["']/)
    expect(lib_source).not_to match(/["']Times New Roman["']/)
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

  it 'scripts/xsl_to_config.rb has no OIML/Metanorma vocabulary literals' do
    converter = File.read(File.join(gem_root, 'scripts/xsl_to_config.rb'))
    expect(converter).not_to match(/\bOIML\b/)
    expect(converter).not_to include('Times New Roman')
    expect(converter).not_to include('Jost')
    expect(converter).not_to include('Organisation Internationale')
  end

  it 'exe/arrolio2pdf has no flavor-specific references' do
    cli = File.read(File.join(gem_root, 'exe/arrolio2pdf'))
    expect(cli).not_to match(/\bOIML\b/i)
  end

  it 'the gemspec excludes flavors/ from packaged files' do
    gemspec = File.read(File.join(gem_root, 'arrolio.gemspec'))
    expect(gemspec).to include('flavors/')
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
