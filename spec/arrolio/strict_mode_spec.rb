# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'
require 'arrolio/error'

RSpec.describe 'Strict mode and typed errors' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }

  it 'raises RenderError in strict mode when a font file is missing' do
    yaml = <<~YAML
      default_page_template: body
      page_templates:
        body:
          page_size: A4
      font_paths:
        BogoFont: /nonexistent/path/to/bogo.ttf
      styles:
        body:
          font_name: BogoFont
      flows:
        main:
          region: body
    YAML
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'layout_spec.yml'), yaml)
      File.write(File.join(dir, 'adapter_rules.yml'), "metadata:\n  root: bibdata\nsections:\n  container: sections\n")
      File.write(File.join(dir, 'flow_rules.yml'), "page_sequences: []\n")
      xml = '<doc><bibdata><id>X</id></bibdata><sections/></doc>'
      expect do
        Arrolio::ConfigDrivenPipeline.render(xml, io: StringIO.new,
                                                  flavor_dir: dir, strict: true)
      end.to raise_error(Arrolio::RenderError, /missing required font files/)
    end
  end

  it 'does not raise in non-strict mode for the same missing font' do
    yaml = <<~YAML
      default_page_template: body
      page_templates:
        body:
          page_size: A4
      font_paths:
        BogoFont: /nonexistent/path/to/bogo.ttf
      styles:
        body:
          font_name: BogoFont
      flows:
        main:
          region: body
    YAML
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'layout_spec.yml'), yaml)
      File.write(File.join(dir, 'adapter_rules.yml'), "metadata:\n  root: bibdata\nsections:\n  container: sections\n")
      File.write(File.join(dir, 'flow_rules.yml'), "page_sequences: []\n")
      xml = '<doc><bibdata><id>X</id></bibdata><sections/></doc>'
      io = StringIO.new
      expect do
        Arrolio::ConfigDrivenPipeline.render(xml, io: io, flavor_dir: dir)
      end.not_to raise_error
    end
  end

  it 'exposes missing_fonts on the RenderError' do
    yaml = <<~YAML
      default_page_template: body
      page_templates:
        body:
          page_size: A4
      font_paths:
        MissingA: /nope/a.ttf
        MissingB: /nope/b.ttf
      styles:
        body:
          font_name: MissingA
      flows:
        main:
          region: body
    YAML
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'layout_spec.yml'), yaml)
      File.write(File.join(dir, 'adapter_rules.yml'), "metadata:\n  root: bibdata\nsections:\n  container: sections\n")
      File.write(File.join(dir, 'flow_rules.yml'), "page_sequences: []\n")
      xml = '<doc><bibdata><id>X</id></bibdata><sections/></doc>'
      error = begin
                Arrolio::ConfigDrivenPipeline.render(xml, io: StringIO.new,
                                                          flavor_dir: dir, strict: true)
              rescue Arrolio::RenderError => e
                e
              end
      expect(error).to be_a(Arrolio::RenderError)
      expect(error.missing_fonts.map(&:first)).to contain_exactly('MissingA', 'MissingB')
    end
  end

  it 'ConfigDrivenPipeline exposes the strict flag' do
    pipeline = Arrolio::ConfigDrivenPipeline.new(flavor_dir: flavor_dir, strict: true)
    expect(pipeline.strict).to be(true)
  end
end
