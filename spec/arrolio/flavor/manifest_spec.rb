# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Arrolio::Flavor::Manifest do
  let(:sample_flavor_dir) { File.expand_path('../../fixtures/flavors/sample', __dir__) }

  describe '.load' do
    it 'loads the sample fixture manifest' do
      manifest = described_class.load(sample_flavor_dir)
      expect(manifest.name).to eq('sample')
      expect(manifest.version).to eq('0.1.0')
      expect(manifest.doctypes).to eq(['article'])
    end

    it 'exposes config_path_for resolving to absolute paths' do
      manifest = described_class.load(sample_flavor_dir)
      expect(manifest.config_path_for(:layout_spec)).to eq(File.join(sample_flavor_dir, 'layout_spec.yml'))
      expect(manifest.config_path_for(:adapter_rules)).to eq(File.join(sample_flavor_dir, 'adapter_rules.yml'))
    end

    it 'returns nil for unknown config roles' do
      manifest = described_class.load(sample_flavor_dir)
      expect(manifest.config_path_for(:nonexistent)).to be_nil
    end

    it 'raises FlavorError when manifest.yml is missing' do
      Dir.mktmpdir do |dir|
        expect { described_class.load(dir) }.to raise_error(Arrolio::FlavorError, /manifest\.yml not found/)
      end
    end

    it 'raises FlavorError when manifest.yml is not a mapping' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'manifest.yml'), '- just\n- a\n- list')
        expect { described_class.load(dir) }.to raise_error(Arrolio::FlavorError, /not a YAML mapping/)
      end
    end

    it 'raises FlavorError when required fields are missing' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'manifest.yml'), "name: incomplete\n")
        error = begin
                  described_class.load(dir)
                rescue Arrolio::FlavorError => e
                  e
                end
        expect(error.missing_fields).to include('version', 'config_files')
      end
    end

    it 'raises FlavorError when a declared config file does not exist' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'manifest.yml'), <<~YAML)
          name: broken
          version: 1.0.0
          config_files:
            layout_spec: missing.yml
            adapter_rules: missing.yml
            flow_rules: missing.yml
        YAML
        expect { described_class.load(dir) }.to raise_error(Arrolio::FlavorError, /does not exist/)
      end
    end

    it 'is frozen after construction' do
      expect(described_class.load(sample_flavor_dir)).to be_frozen
    end
  end

  describe 'value equality' do
    it 'compares equal to another manifest loaded from the same path' do
      a = described_class.load(sample_flavor_dir)
      b = described_class.load(sample_flavor_dir)
      expect(a).to eq(b)
      expect(a.hash).to eq(b.hash)
    end
  end
end

RSpec.describe Arrolio::ConfigDrivenPipeline do
  it 'exposes a manifest when the flavor directory has one' do
    flavor_dir = File.expand_path('../../fixtures/flavors/sample', __dir__)
    pipeline = described_class.new(flavor_dir: flavor_dir)
    expect(pipeline.manifest).to be_a(Arrolio::Flavor::Manifest)
    expect(pipeline.manifest.name).to eq('sample')
  end

  it 'exposes nil manifest when the flavor directory lacks one' do
    bare_layout = <<~YAML
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
    Dir.mktmpdir do |dir|
      ['layout_spec', 'adapter_rules', 'flow_rules'].each do |role|
        File.write(File.join(dir, "#{role}.yml"), bare_layout)
      end
      pipeline = described_class.new(flavor_dir: dir)
      expect(pipeline.manifest).to be_nil
    end
  end
end
