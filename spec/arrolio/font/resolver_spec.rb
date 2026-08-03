# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'arrolio/error'

RSpec.describe Arrolio::Font::Resolver do
  let(:sample_manifest_data) do
    {
      'Body' => { 'regular' => '/fonts/body.ttf', 'bold' => '/fonts/body-bold.ttf' },
      'Heading' => { 'regular' => '/fonts/heading.ttf' }
    }
  end

  let(:manifest) { Arrolio::Font::FontManifest.new(sample_manifest_data, ['Body']) }

  describe '#resolve' do
    it 'returns the explicit font_paths entry when the file exists' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'real.ttf')
        File.write(path, 'fake ttf bytes')
        resolver = described_class.new(font_paths: { 'X' => path })
        expect(resolver.resolve('X')).to eq(path)
      end
    end

    it 'returns the family name as-is for PDF standard 14 fonts' do
      resolver = described_class.new
      expect(resolver.resolve('Helvetica')).to eq('Helvetica')
      expect(resolver.resolve('Times-Roman')).to eq('Times-Roman')
    end

    it 'returns nil for an unknown family in lenient mode' do
      resolver = described_class.new
      expect(resolver.resolve('BogoFont')).to be_nil
    end

    it 'returns nil when font_paths entry points to a non-existent file' do
      resolver = described_class.new(font_paths: { 'X' => '/nope/x.ttf' })
      expect(resolver.resolve('X')).to be_nil
    end

    it 'uses manifest path when available and the file exists' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'manifest.ttf')
        File.write(path, 'fake')
        data = { 'M' => { 'regular' => path } }
        m = Arrolio::Font::FontManifest.new(data, [])
        resolver = described_class.new(manifest: m)
        expect(resolver.resolve('M')).to eq(path)
      end
    end

    it 'returns nil when the manifest path does not exist on disk' do
      data = { 'M' => { 'regular' => '/nope/m.ttf' } }
      m = Arrolio::Font::FontManifest.new(data, [])
      resolver = described_class.new(manifest: m)
      expect(resolver.resolve('M')).to be_nil
    end
  end

  describe '#resolve_all!' do
    it 'returns a Hash of resolved paths in lenient mode' do
      resolver = described_class.new(font_paths: {})
      resolver.resolve('Helvetica')
      result = resolver.resolve_all!
      expect(result['Helvetica']).to eq('Helvetica')
    end

    it 'raises RenderError in strict mode when a required font is unresolved' do
      resolver = described_class.new(
        manifest: Arrolio::Font::FontManifest.new({ 'Bogo' => { 'regular' => '/nope/b.ttf' } }, []),
        strict: true
      )
      expect { resolver.resolve_all! }.to raise_error(
        Arrolio::RenderError, /unresolved required fonts: Bogo/
      )
    end

    it 'attaches missing_fonts to the RenderError' do
      resolver = described_class.new(
        manifest: Arrolio::Font::FontManifest.new({ 'BogoA' => { 'regular' => '/nope/a.ttf' } }, []),
        strict: true
      )
      error = begin
                resolver.resolve_all!
              rescue Arrolio::RenderError => e
                e
              end
      expect(error.missing_fonts).to include(['BogoA', nil])
    end

    it 'does not raise for unresolved PDF standard 14 fonts in strict mode' do
      resolver = described_class.new(strict: true)
      expect { resolver.resolve_all! }.not_to raise_error
    end
  end

  describe '.standard_14?' do
    it 'recognizes the 14 standard PDF fonts' do
      expect(described_class.standard_14?('Helvetica')).to be true
      expect(described_class.standard_14?('Courier-Bold')).to be true
      expect(described_class.standard_14?('Symbol')).to be true
    end

    it 'rejects non-standard names' do
      expect(described_class.standard_14?('Bogo')).to be false
      expect(described_class.standard_14?('Arial')).to be false
    end
  end

  describe 'fontist integration (skipped when fontist is not installed)' do
    it 'does not raise when fontist is not available' do
      resolver = described_class.new(use_fontist: true)
      # fontist is not in arroolio's Gemfile; lookup falls through silently
      expect { resolver.resolve('SomeUnlikelyFont') }.not_to raise_error
    end
  end
end

RSpec.describe Arrolio::Font::FontManifest do
  it 'exposes required_families as the keys of families' do
    m = described_class.new({ 'A' => {}, 'B' => {} }, [])
    expect(m.required_families).to contain_exactly('A', 'B')
  end

  it 'is frozen after construction' do
    expect(described_class.new({}, [])).to be_frozen
  end

  it 'returns nil path for an unknown family' do
    expect(described_class.new({}, []).path_for('X')).to be_nil
  end
end
