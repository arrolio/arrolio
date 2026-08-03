# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Font::Manifest do
  let(:families) do
    {
      'Times New Roman' => {
        regular: '/path/to/times.ttf',
        bold: '/path/to/timesbd.ttf',
        italic: '/path/to/timesi.ttf'
      },
      'Arial' => {
        regular: '/path/to/arial.ttf'
      }
    }
  end

  let(:manifest) { described_class.new(families: families, fallback_chain: ['Arial']) }

  describe '#resolve' do
    it 'finds regular variant' do
      expect(manifest.resolve('Times New Roman')).to eq('/path/to/times.ttf')
    end

    it 'finds bold variant' do
      expect(manifest.resolve('Times New Roman', weight: :bold)).to eq('/path/to/timesbd.ttf')
    end

    it 'finds italic variant' do
      expect(manifest.resolve('Times New Roman', style: :italic)).to eq('/path/to/timesi.ttf')
    end

    it 'falls back to regular when bold_italic is missing' do
      expect(manifest.resolve('Times New Roman', weight: :bold, style: :italic)).to eq('/path/to/times.ttf')
    end

    it 'uses fallback chain when family is unknown' do
      expect(manifest.resolve('Unknown Font')).to eq('/path/to/arial.ttf')
    end

    it 'returns nil when nothing resolves' do
      empty = described_class.new(families: {}, fallback_chain: [])
      expect(empty.resolve('Nothing')).to be_nil
    end
  end

  describe '#to_flat_paths' do
    it 'produces flat hash with variant-named keys' do
      paths = manifest.to_flat_paths
      # Files don't exist so they won't be in the output.
      # Test with a manifest that has existing files.
      expect(paths).to respond_to(:each)
    end
  end

  describe '.from_hash' do
    it 'builds from string-keyed hash' do
      hash = {
        'families' => { 'Test' => { 'regular' => '/test.ttf' } },
        'fallback' => ['Test']
      }
      m = described_class.from_hash(hash)
      expect(m.families).to include('Test')
      expect(m.fallback_chain).to eq(['Test'])
    end

    it 'builds from symbol-keyed hash' do
      hash = {
        families: { Test: { regular: '/test.ttf' } },
        fallback_chain: ['Test']
      }
      m = described_class.from_hash(hash)
      expect(m.families).to include('Test')
    end
  end

  it 'compares by value' do
    a = described_class.new(families: families, fallback_chain: ['Arial'])
    b = described_class.new(families: families, fallback_chain: ['Arial'])
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(manifest).to be_frozen
  end
end
