# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Color do
  describe '.parse' do
    it 'parses hex #RRGGBB' do
      c = described_class.parse('#ff8800')
      expect(c.red).to be_within(0.01).of(1.0)
      expect(c.green).to be_within(0.01).of(0.533)
      expect(c.blue).to be_within(0.01).of(0.0)
    end

    it 'parses short hex #RGB' do
      c = described_class.parse('#f80')
      expect(c.red).to be_within(0.01).of(1.0)
      expect(c.green).to be_within(0.01).of(0.533)
      expect(c.blue).to be_within(0.01).of(0.0)
    end

    it 'parses rgb(r,g,b) with integers' do
      c = described_class.parse('rgb(255, 128, 0)')
      expect(c.red).to be_within(0.01).of(1.0)
      expect(c.green).to be_within(0.01).of(0.502)
      expect(c.blue).to be_within(0.01).of(0.0)
    end

    it 'parses rgb(r%,g%,b%)' do
      c = described_class.parse('rgb(100%, 50%, 0%)')
      expect(c.red).to be_within(0.01).of(1.0)
      expect(c.green).to be_within(0.01).of(0.5)
      expect(c.blue).to be_within(0.01).of(0.0)
    end

    it 'parses named colors' do
      c = described_class.parse('red')
      expect(c.red).to eq(1.0)
      expect(c.green).to eq(0.0)
      expect(c.blue).to eq(0.0)
    end

    it 'parses "white" as full white' do
      c = described_class.parse('white')
      expect(c.red).to eq(1.0)
      expect(c.green).to eq(1.0)
      expect(c.blue).to eq(1.0)
    end

    it 'returns nil for nil input' do
      expect(described_class.parse(nil)).to be_nil
    end

    it 'returns nil for empty string' do
      expect(described_class.parse('')).to be_nil
    end

    it 'is case-insensitive' do
      c = described_class.parse('RED')
      expect(c.red).to eq(1.0)
    end
  end

  describe '#to_render' do
    it 'returns [:rgb, r, g, b] for color values' do
      c = described_class.parse('rgb(255, 0, 0)')
      expect(c.to_render).to eq([:rgb, 1.0, 0.0, 0.0])
    end
  end

  describe '#grayscale?' do
    it 'returns true for gray colors' do
      expect(described_class.parse('#808080')).to be_grayscale
    end

    it 'returns false for colored colors' do
      expect(described_class.parse('#ff0000')).not_to be_grayscale
    end
  end

  describe '#to_grayscale_float' do
    it 'converts RGB to luminance using BT.601 weights' do
      c = described_class.parse('white')
      expect(c.to_grayscale_float).to be_within(0.01).of(1.0)
    end
  end

  it 'is frozen' do
    expect(described_class.parse('black')).to be_frozen
  end

  it 'compares by value' do
    a = described_class.parse('#ff0000')
    b = described_class.parse('rgb(255, 0, 0)')
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end
end
