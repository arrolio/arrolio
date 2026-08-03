# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::TextDirection do
  describe '.detect' do
    it 'returns :ltr for English text' do
      expect(described_class.detect('Hello World')).to eq(:ltr)
    end

    it 'returns :ltr for empty string' do
      expect(described_class.detect('')).to eq(:ltr)
    end

    it 'returns :ltr for nil' do
      expect(described_class.detect(nil)).to eq(:ltr)
    end

    it 'returns :rtl for Arabic text' do
      expect(described_class.detect('مرحبا بالعالم')).to eq(:rtl)
    end

    it 'returns :rtl for Hebrew text' do
      expect(described_class.detect('שלום עולם')).to eq(:rtl)
    end

    it 'returns :mixed for mixed LTR/RTL text' do
      expect(described_class.detect('Hello مرحبا')).to eq(:mixed)
    end

    it 'returns :ltr for CJK text' do
      expect(described_class.detect('こんにちは世界')).to eq(:ltr)
    end
  end

  describe '.rtl?' do
    it 'returns true for Arabic characters' do
      expect(described_class.rtl?('ا')).to be(true)
    end

    it 'returns true for Hebrew characters' do
      expect(described_class.rtl?('ש')).to be(true)
    end

    it 'returns false for Latin characters' do
      expect(described_class.rtl?('A')).to be(false)
    end
  end

  describe '.reverse_for_rtl' do
    it 'reverses a string' do
      expect(described_class.reverse_for_rtl('abc')).to eq('cba')
    end
  end
end
